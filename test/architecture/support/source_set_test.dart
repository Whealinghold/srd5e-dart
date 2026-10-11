import 'dart:io';

import 'package:test/test.dart';

import 'package_root.dart';
import 'source_set.dart';

void main() {
  late Directory root;

  setUp(() {
    root = Directory.systemTemp.createTempSync('srd5e_source_set_');
  });

  tearDown(() {
    root.deleteSync(recursive: true);
  });

  void write(String path, List<int> bytes) {
    final file = File('${root.path}/$path')..createSync(recursive: true);
    file.writeAsBytesSync(bytes);
  }

  void writeText(String path, String text) => write(path, text.codeUnits);

  /// Requirement: doc/specs/architecture-guardrails.md FR-002 and FR-010 - the
  ///   loader keeps text files by relative path, leaves out ignored and
  ///   per-machine files, records binary paths and unreadable files (support
  ///   code of errors-and-results.md section 8).
  /// Path: happy
  group('SourceSet.load', () {
    /// Requirement: doc/specs/architecture-guardrails.md FR-002 - text files
    ///   are keyed by `/`-separated relative paths.
    /// Path: happy
    test('keeps text files by relative path', () {
      writeText('lib/srd5e.dart', 'library;\n');
      writeText('tool/x.dart', 'void main() {}\n');

      final sources = SourceSet.load(root);

      expect(sources.files.keys.toList()..sort(), [
        'lib/srd5e.dart',
        'tool/x.dart',
      ]);
      expect(sources.files['lib/srd5e.dart'], 'library;\n');
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-002 and FR-105 -
    ///   ignored directories and per-machine files are excluded, the
    ///   `.zcode/` repository root among them (FR-105).
    /// Path: unhappy (false positive)
    test('excludes ignored directories and per-machine files', () {
      writeText('lib/a.dart', 'a');
      writeText('coverage/lcov.info', 'x');
      writeText('.dart_tool/package_config.json', 'x');
      writeText('.git/config', 'x');
      writeText('.mutate4dart/copy.dart', 'x');
      writeText('.idea/x.xml', 'x');
      writeText('.zcode/workflow-runs/run.mjs', 'x');
      writeText('pubspec.lock', 'x');
      writeText('.DS_Store', 'x');
      writeText('lib/a.dart.swp', 'x');
      writeText('lib/a.dart~', 'x');

      final sources = SourceSet.load(root);

      expect(sources.files.keys, ['lib/a.dart']);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-002 - a binary file
    ///   keeps only its path.
    /// Path: unhappy (boundary)
    test('records a binary file by path only', () {
      write('assets/logo.bin', [1, 2, 0, 3]);

      final sources = SourceSet.load(root);

      expect(sources.files, isEmpty);
      expect(sources.binaryPaths, ['assets/logo.bin']);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-010 - a file that
    ///   is not valid UTF-8 is listed as unreadable, not skipped.
    /// Path: unhappy (failure)
    test('records a non-UTF-8 file as unreadable', () {
      write('lib/bad.dart', [0xC3, 0x28]);

      final sources = SourceSet.load(root);

      expect(sources.files, isEmpty);
      expect(sources.unreadable.keys, ['lib/bad.dart']);
    });
  });

  /// Requirement: doc/specs/architecture-guardrails.md FR-001 - the package
  ///   root is the nearest ancestor whose pubspec declares `name: srd5e`.
  /// Path: happy
  group('findPackageRoot', () {
    /// Requirement: doc/specs/architecture-guardrails.md FR-001 - the root is
    ///   found from a nested directory.
    /// Path: happy
    test('finds the root from a nested directory', () {
      writeText('pubspec.yaml', 'name: srd5e\n');
      Directory('${root.path}/lib/src').createSync(recursive: true);

      final found = findPackageRoot(Directory('${root.path}/lib/src'));

      expect(found.path, root.absolute.path);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-001 - another
    ///   package's pubspec does not count, and the failure names the
    ///   directory searched.
    /// Path: unhappy (state error)
    test('fails when no pubspec declares srd5e', () {
      writeText('pubspec.yaml', 'name: other\n');

      expect(
        () => findPackageRoot(root),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains(root.absolute.path),
          ),
        ),
      );
    });
  });

  /// Requirement: doc/specs/architecture-guardrails.md FR-002 - ignored files
  ///   are excluded wherever the rule names them, and nothing else is.
  /// Path: unhappy (boundary)
  group('SourceSet.load exclusions and binaries', () {
    /// Requirement: doc/specs/architecture-guardrails.md FR-002 - `.swo`,
    ///   `.packages` and the `.vscode/` and `build/` directories are excluded.
    /// Path: unhappy (false positive)
    test('excludes the remaining named files and directories', () {
      writeText('lib/a.dart', 'a');
      writeText('lib/a.dart.swo', 'x');
      writeText('.packages', 'x');
      writeText('.vscode/settings.json', 'x');
      writeText('build/out.txt', 'x');

      final sources = SourceSet.load(root);

      expect(sources.files.keys, ['lib/a.dart']);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-002 - the named
    ///   directories are excluded at the repository root only, so a nested
    ///   folder with the same name (a `build/` package or a `coverage/`
    ///   fixture directory) stays in the set and is checked.
    /// Path: unhappy (false positive)
    test('keeps nested directories that share an excluded name', () {
      writeText('lib/src/build/info.dart', 'a');
      writeText('test/fixtures/coverage/lcov.info', 'b');
      writeText('tool/.dart_tool/cache.txt', 'c');
      writeText('coverage/lcov.info', 'x');
      writeText('build/out.txt', 'x');

      final sources = SourceSet.load(root);

      expect(sources.files.keys.toList()..sort(), [
        'lib/src/build/info.dart',
        'test/fixtures/coverage/lcov.info',
        'tool/.dart_tool/cache.txt',
      ]);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-002 - similar
    ///   names that are not excluded stay in the set.
    /// Path: unhappy (boundary)
    test('keeps files that only resemble excluded names', () {
      writeText('lib/build_info.dart', 'a');
      writeText('lib/coverage_notes.md', 'b');
      writeText('lib/a.swp.dart', 'c');
      writeText('lib/tilde.dart', 'd');

      final sources = SourceSet.load(root);

      expect(sources.files.keys.toList()..sort(), [
        'lib/a.swp.dart',
        'lib/build_info.dart',
        'lib/coverage_notes.md',
        'lib/tilde.dart',
      ]);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-002 - a NUL in
    ///   the first 8 KiB makes a file binary: the last byte of the window
    ///   counts, the first byte after it does not.
    /// Path: unhappy (boundary)
    test('the NUL window is exactly the first 8192 bytes', () {
      write('in.txt', [...List.filled(8191, 0x61), 0]);
      write('out.txt', [...List.filled(8192, 0x61), 0]);

      final sources = SourceSet.load(root);

      expect(sources.binaryPaths, ['in.txt']);
      expect(sources.files.keys, ['out.txt']);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-002 - an empty
    ///   file is text and stays in the set.
    /// Path: unhappy (empty case)
    test('an empty file is kept as empty text', () {
      write('lib/empty.dart', []);

      final sources = SourceSet.load(root);

      expect(sources.files, {'lib/empty.dart': ''});
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-011 - the snapshot
    ///   lists files, binaries and unreadable entries in sorted order, so
    ///   the result does not depend on directory listing order.
    /// Path: unhappy (determinism)
    test('files, binaries and unreadable entries are sorted', () {
      for (final name in ['z', 'm', 'a']) {
        writeText('lib/$name.dart', name);
        write('bin/$name.bin', [0]);
        write('bad/$name.txt', [0xC3, 0x28]);
      }

      final sources = SourceSet.load(root);

      expect(sources.files.keys, ['lib/a.dart', 'lib/m.dart', 'lib/z.dart']);
      expect(sources.binaryPaths, ['bin/a.bin', 'bin/m.bin', 'bin/z.bin']);
      expect(sources.unreadable.keys, ['bad/a.txt', 'bad/m.txt', 'bad/z.txt']);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-010 - the reason
    ///   names the problem so the Violation is actionable.
    /// Path: unhappy (failure)
    test('an unreadable entry carries a reason', () {
      write('lib/bad.dart', [0xC3, 0x28]);

      final sources = SourceSet.load(root);

      expect(sources.unreadable['lib/bad.dart'], contains('UTF-8'));
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-002 - a symlink is
    ///   not a regular file and is not followed or listed.
    /// Path: unhappy (boundary)
    test('a symbolic link is not read', () {
      writeText('lib/a.dart', 'a');
      Link('${root.path}/lib/link.dart').createSync('${root.path}/lib/a.dart');

      final sources = SourceSet.load(root);

      expect(sources.files.keys, ['lib/a.dart']);
    });
  });

  /// Requirement: doc/specs/architecture-guardrails.md FR-011 - a SourceSet is
  ///   an immutable snapshot and answers path queries deterministically.
  /// Path: unhappy (determinism)
  group('SourceSet queries', () {
    /// Requirement: doc/specs/architecture-guardrails.md FR-011 - paths and
    ///   dartPaths filter by prefix and suffix and return sorted lists.
    /// Path: happy
    test('paths and dartPaths filter and sort', () {
      final sources = SourceSet({
        'lib/b.dart': '',
        'lib/a.dart': '',
        'lib/a.md': '',
        'test/c.dart': '',
      });

      expect(sources.paths(prefix: 'lib/'), [
        'lib/a.dart',
        'lib/a.md',
        'lib/b.dart',
      ]);
      expect(sources.dartPaths('lib/'), ['lib/a.dart', 'lib/b.dart']);
      expect(sources.paths(suffix: '.md'), ['lib/a.md']);
      expect(sources.dartPaths('nothing/'), isEmpty);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-011 - the maps
    ///   handed in are copied, and the snapshot cannot be mutated.
    /// Path: unhappy (immutability)
    test('the snapshot is immutable and detached from its inputs', () {
      final input = {'lib/a.dart': 'a'};
      final sources = SourceSet(input, binaryPaths: ['x.bin']);

      input['lib/b.dart'] = 'b';

      expect(sources.files.keys, ['lib/a.dart']);
      expect(() => sources.files['c'] = 'c', throwsUnsupportedError);
      expect(() => sources.binaryPaths.add('y'), throwsUnsupportedError);
      expect(() => sources.unreadable['d'] = 'e', throwsUnsupportedError);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-008 - lexed
    ///   output is computed once per path and reused.
    /// Path: happy
    test('lexed caches per path', () {
      final sources = SourceSet({'lib/a.dart': 'var a;'});

      expect(
        identical(sources.lexed('lib/a.dart'), sources.lexed('lib/a.dart')),
        isTrue,
      );
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-008 - asking for a
    ///   path outside the set is a programmer error.
    /// Path: unhappy (invalid input)
    test('lexed rejects an unknown path', () {
      final sources = SourceSet({});

      expect(
        () => sources.lexed('lib/none.dart'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  /// Requirement: doc/specs/architecture-guardrails.md FR-001 - the root
  ///   search skips other packages and fails with the directory searched.
  /// Path: unhappy (state error)
  group('findPackageRoot boundaries', () {
    /// Requirement: doc/specs/architecture-guardrails.md FR-001 - a nested
    ///   package with another name does not stop the search; the nearest
    ///   ancestor declaring srd5e wins.
    /// Path: unhappy (rule interaction)
    test('skips a nested other-named package', () {
      writeText('pubspec.yaml', 'name: srd5e\n');
      writeText('example/pubspec.yaml', 'name: example\n');

      final found = findPackageRoot(Directory('${root.path}/example'));

      expect(found.path, root.absolute.path);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-001 - a package
    ///   whose name only starts with srd5e is not the root.
    /// Path: unhappy (boundary)
    test('a prefix-named package is not the root', () {
      writeText('pubspec.yaml', 'name: srd5e_extra\n');

      expect(() => findPackageRoot(root), throwsStateError);
    });
  });
}
