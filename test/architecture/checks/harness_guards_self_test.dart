import 'package:test/test.dart';

import '../support/source_set.dart';
import '../support/violation.dart';
import 'harness_guards.dart';

const String _fr010 = 'doc/specs/architecture-guardrails.md FR-010';
const String _fr012 = 'doc/specs/architecture-guardrails.md FR-012';

List<String> _where(List<Violation> violations) => [
  for (final v in violations) '${v.checkId} ${v.path}:${v.line}',
];

void main() {
  /// Requirement: doc/specs/architecture-guardrails.md FR-010 - one
  ///   Violation per unreadable file, naming the file.
  /// Path: unhappy (failure)
  group('FR-010 unreadable files', () {
    /// Requirement: doc/specs/architecture-guardrails.md FR-010 - a single
    ///   non-UTF-8 file gives exactly one Violation naming it and the reason.
    /// Path: unhappy (failure)
    test(
      'one unreadable file is one Violation [unhappy (failure)] ($_fr010)',
      () {
        final found = checkUnreadableFiles(
          SourceSet(
            const {},
            unreadable: {'doc/x.md': 'not valid UTF-8 (offset 3)'},
          ),
        );

        expect(_where(found), ['FR-010 doc/x.md:1']);
        expect(found.single.detail, contains('not valid UTF-8 (offset 3)'));
      },
    );

    /// Requirement: doc/specs/architecture-guardrails.md FR-010 - every
    ///   entry is reported, sorted by path.
    /// Path: unhappy (multiple violations)
    test('each entry is reported, sorted [unhappy (multiple violations)] '
        '($_fr010)', () {
      final found = checkUnreadableFiles(
        SourceSet(
          const {},
          unreadable: {'lib/b.dart': 'bad', 'doc/a.md': 'worse'},
        ),
      );

      expect(_where(found), ['FR-010 doc/a.md:1', 'FR-010 lib/b.dart:1']);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-010 - readable
    ///   and binary files are not Violations.
    /// Path: happy
    test('a clean set has no Violation [happy] ($_fr010)', () {
      final found = checkUnreadableFiles(
        SourceSet(
          {'lib/a.dart': 'library;\n'},
          binaryPaths: const ['doc/pic.png'],
        ),
      );

      expect(found, isEmpty);
    });
  });

  /// Requirement: doc/specs/architecture-guardrails.md FR-012 - the guard
  ///   fails on a wrong root.
  /// Path: unhappy (empty case)
  group('FR-012 repository roots', () {
    /// Requirement: doc/specs/architecture-guardrails.md FR-012 - no
    ///   pubspec.yaml fails and names the file.
    /// Path: unhappy (empty case)
    test('no pubspec fails [unhappy (empty case)] ($_fr012)', () {
      final sources = SourceSet({'lib/srd5e.dart': 'library;\n'});

      expect(
        () => requireRepositoryRoots(sources),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('pubspec.yaml is missing'),
          ),
        ),
      );
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-012 - a pubspec
    ///   for another package fails.
    /// Path: unhappy (invalid input)
    test('wrong package name fails [unhappy (invalid input)] ($_fr012)', () {
      final sources = SourceSet({
        'lib/srd5e.dart': 'library;\n',
        'pubspec.yaml': 'name: other\n',
      });

      expect(
        () => requireRepositoryRoots(sources),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('name: srd5e'),
          ),
        ),
      );
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-012 - a missing
    ///   lib/srd5e.dart fails and names the file.
    /// Path: unhappy (empty case)
    test('no lib/srd5e.dart fails [unhappy (empty case)] ($_fr012)', () {
      final sources = SourceSet({'pubspec.yaml': 'name: srd5e\n'});

      expect(
        () => requireRepositoryRoots(sources),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('lib/srd5e.dart is missing'),
          ),
        ),
      );
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-012 - an empty
    ///   snapshot reports both problems at once.
    /// Path: unhappy (empty case)
    test('an empty set names both problems [unhappy (empty case)] '
        '($_fr012)', () {
      expect(
        () => requireRepositoryRoots(SourceSet(const {})),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            allOf(contains('pubspec.yaml'), contains('lib/srd5e.dart')),
          ),
        ),
      );
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-012 - a correct
    ///   root passes the guard.
    /// Path: happy
    test('both files present passes [happy] ($_fr012)', () {
      final sources = SourceSet({
        'lib/srd5e.dart': 'library;\n',
        'pubspec.yaml': 'name: srd5e\nversion: 0.0.1\n',
      });

      expect(() => requireRepositoryRoots(sources), returnsNormally);
    });
  });
}
