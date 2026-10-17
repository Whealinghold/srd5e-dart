import 'dart:convert';
import 'dart:io';

import 'lexer.dart';

/// An immutable snapshot of the repository's text files, keyed by
/// repository-relative path with `/` separators.
///
/// A check is a pure function over a [SourceSet]; only [SourceSet.load] does
/// I/O. The set also records files the loader could not decode
/// ([unreadable]) and binary files ([binaryPaths], path only).
final class SourceSet {
  /// Creates a snapshot from [files], with optional [unreadable] and
  /// [binaryPaths].
  SourceSet(
    Map<String, String> files, {
    Map<String, String> unreadable = const {},
    List<String> binaryPaths = const [],
  }) : files = Map.unmodifiable(files),
       unreadable = Map.unmodifiable(unreadable),
       binaryPaths = List.unmodifiable(binaryPaths);

  /// Directories at the repository root that are never part of a snapshot
  /// (ignored or per-machine). A nested folder of the same name is kept.
  static const Set<String> excludedDirectories = {
    '.git',
    '.dart_tool',
    'build',
    'coverage',
    '.mutate4dart',
    '.idea',
    '.vscode',
    '.zcode', // FR-105: machine-owned agent/workflow tooling state, not repository source
  };

  /// File names that are never part of a snapshot.
  static const Set<String> excludedFiles = {
    'pubspec.lock',
    '.packages',
    '.DS_Store',
  };

  /// Loads every non-ignored text file under [root].
  ///
  /// Symlinks are resolved: a symlinked directory is walked (with a loop
  /// guard) and a symlinked file is read through, each listed under the
  /// link's own relative path. A mutation-testing shadow workspace mirrors
  /// every unmutated file and directory as a symlink
  /// (`mutate4dart`'s `ShadowWorkspace`), so a snapshot that skipped links
  /// would make the architecture checks pass vacuously there. A dangling
  /// link has no file behind it and is skipped (FR-002).
  factory SourceSet.load(Directory root) {
    final files = <String, String>{};
    final unreadable = <String, String>{};
    final binary = <String>[];
    _collect(
      root.absolute.path,
      '',
      files,
      unreadable,
      binary,
      visited: <String>{},
    );
    // Directory listing order is platform-dependent; sort so the snapshot is
    // deterministic (FR-011).
    return SourceSet(
      {for (final key in files.keys.toList()..sort()) key: files[key]!},
      unreadable: {
        for (final key in unreadable.keys.toList()..sort())
          key: unreadable[key]!,
      },
      binaryPaths: binary..sort(),
    );
  }

  /// Walks [directoryPath], adding every kept file under the relative
  /// prefix [prefix]. [visited] holds the canonical paths of the directories
  /// on the current walk path only, so a symlink loop terminates while the
  /// same directory reached twice through two links is still walked twice.
  static void _collect(
    String directoryPath,
    String prefix,
    Map<String, String> files,
    Map<String, String> unreadable,
    List<String> binary, {
    required Set<String> visited,
  }) {
    for (final entity in Directory(
      directoryPath,
    ).listSync(followLinks: false)) {
      final name = entity.path
          .substring(directoryPath.length + 1)
          .replaceAll(r'\', '/');
      final relative = prefix.isEmpty ? name : '$prefix/$name';
      if (entity is Link) {
        final String resolved;
        try {
          resolved = entity.resolveSymbolicLinksSync();
        } on FileSystemException {
          continue; // Dangling link: no file behind it (FR-002).
        }
        switch (FileSystemEntity.typeSync(resolved)) {
          case FileSystemEntityType.directory:
            // Root only (FR-002): a nested `build/` or `coverage/` is
            // checked, and so is a nested one behind a link.
            if (prefix.isEmpty && excludedDirectories.contains(name)) {
              continue;
            }
            final canonical = Directory(resolved).absolute.path;
            if (visited.add(canonical)) {
              _collect(
                resolved,
                relative,
                files,
                unreadable,
                binary,
                visited: visited,
              );
              visited.remove(canonical);
            }
          case FileSystemEntityType.file:
            _addFile(entity.path, relative, files, unreadable, binary);
          default:
          // A dangling or special link: no regular file behind it.
        }
        continue;
      }
      if (entity is Directory) {
        if (prefix.isEmpty && excludedDirectories.contains(name)) {
          continue;
        }
        _collect(
          entity.path,
          relative,
          files,
          unreadable,
          binary,
          visited: visited,
        );
        continue;
      }
      if (entity is File) {
        _addFile(entity.path, relative, files, unreadable, binary);
      }
    }
  }

  /// Reads one file, keeping its text, or its path in [binary] or
  /// [unreadable] (FR-002, FR-010).
  static void _addFile(
    String path,
    String relative,
    Map<String, String> files,
    Map<String, String> unreadable,
    List<String> binary,
  ) {
    final name = relative.split('/').last;
    if (excludedFiles.contains(name) ||
        name.endsWith('.swp') ||
        name.endsWith('.swo') ||
        name.endsWith('~')) {
      return;
    }
    final bytes = File(path).readAsBytesSync();
    final head = bytes.length > 8192 ? bytes.sublist(0, 8192) : bytes;
    if (head.contains(0)) {
      binary.add(relative);
      return;
    }
    try {
      files[relative] = utf8.decode(bytes);
    } on FormatException catch (e) {
      unreadable[relative] = 'not valid UTF-8 (offset ${e.offset})';
    }
  }

  /// Text content by repository-relative path.
  final Map<String, String> files;

  /// Files that could not be read, by path, with the reason.
  final Map<String, String> unreadable;

  /// Paths of binary files (content is not kept).
  final List<String> binaryPaths;

  final Map<String, LexResult> _lexed = {};

  /// The paths with the given [prefix] (and the given [suffix]), sorted.
  List<String> paths({String prefix = '', String suffix = ''}) =>
      files.keys
          .where((p) => p.startsWith(prefix) && p.endsWith(suffix))
          .toList()
        ..sort();

  /// The `.dart` paths with the given [prefix], sorted.
  List<String> dartPaths(String prefix) =>
      paths(prefix: prefix, suffix: '.dart');

  /// The lexer output for [path], computed once per snapshot.
  LexResult lexed(String path) {
    final text = files[path];
    if (text == null) {
      throw ArgumentError.value(path, 'path', 'is not in the source set');
    }
    return _lexed.putIfAbsent(path, () => lex(text));
  }
}
