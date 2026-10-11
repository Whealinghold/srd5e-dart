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
  factory SourceSet.load(Directory root) {
    final files = <String, String>{};
    final unreadable = <String, String>{};
    final binary = <String>[];
    final rootPath = root.absolute.path;
    for (final entity in root.absolute.listSync(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is! File) continue;
      final relative = entity.path
          .substring(rootPath.length + 1)
          .replaceAll(r'\', '/');
      if (_isExcluded(relative)) continue;
      final bytes = entity.readAsBytesSync();
      final head = bytes.length > 8192 ? bytes.sublist(0, 8192) : bytes;
      if (head.contains(0)) {
        binary.add(relative);
        continue;
      }
      try {
        files[relative] = utf8.decode(bytes);
      } on FormatException catch (e) {
        unreadable[relative] = 'not valid UTF-8 (offset ${e.offset})';
      }
    }
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

  static bool _isExcluded(String relative) {
    final segments = relative.split('/');
    // Root only (FR-002): a nested `build/` or `coverage/` is checked.
    if (segments.length > 1 && excludedDirectories.contains(segments.first)) {
      return true;
    }
    final name = segments.last;
    return excludedFiles.contains(name) ||
        name.endsWith('.swp') ||
        name.endsWith('.swo') ||
        name.endsWith('~');
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
