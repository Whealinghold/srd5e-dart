import 'package:test/test.dart';

import '../support/source_set.dart';
import '../support/violation.dart';
import 'timeout_budget.dart';

/// A test file named `test/a_test.dart` holding [body] inside `main`, with a
/// top-level alias of the real repository and the 10 second constant.
SourceSet _file(String body, {String path = 'test/a_test.dart'}) => SourceSet({
  path:
      "import 'support/real_repository.dart';\n"
      'final SourceSet _repository = realRepository;\n'
      'const Timeout _budget = Timeout(Duration(seconds: 10));\n'
      'void main() {\n$body\n}\n',
});

List<String> _where(List<Violation> violations) => [
  for (final v in violations) '${v.checkId} ${v.path}:${v.line}',
];

void main() {
  /// Requirement: doc/specs/architecture-guardrails.md FR-073 - a group that
  ///   reads the real repository without the Timeout is a Violation.
  /// Path: unhappy (missing content)
  group('FR-073 missing declaration', () {
    /// Requirement: doc/specs/architecture-guardrails.md FR-073 - a test using
    ///   the alias of the real repository and no timeout: argument fails, at
    ///   the line of the call.
    /// Path: unhappy (missing content)
    test('a test using the alias without a timeout is one Violation', () {
      final found = checkRealRepositoryTimeouts(
        _file("test('t', () => expect(_repository, isNotNull));"),
      );

      expect(_where(found), ['FR-073 test/a_test.dart:5']);
      expect(found.single.detail, contains('declares no timeout'));
      expect(found.single.detail, contains('test'));
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-073 - a group
    ///   without the Timeout is one Violation at the group, not one per
    ///   nested test.
    /// Path: unhappy (missing content)
    test('a group without a timeout is reported once at the group', () {
      final found = checkRealRepositoryTimeouts(
        _file('''
group('g', () {
  test('a', () => expect(_repository, isNotNull));
  test('b', () => expect(_repository, isNotNull));
});'''),
      );

      expect(_where(found), ['FR-073 test/a_test.dart:5']);
      expect(found.single.detail, startsWith('A group'));
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-073 - direct use
    ///   of realRepository, with no alias, is real-repository use too.
    /// Path: unhappy (missing content)
    test('a direct realRepository use is checked', () {
      final found = checkRealRepositoryTimeouts(
        _file("test('t', () => expect(realRepository.files, isNotEmpty));"),
      );

      expect(_where(found), ['FR-073 test/a_test.dart:5']);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-073 - a call of
    ///   findPackageRoot with no argument reads the real repository.
    /// Path: unhappy (missing content)
    test('findPackageRoot() with no argument is checked', () {
      final found = checkRealRepositoryTimeouts(
        _file("test('t', () => findPackageRoot());"),
      );

      expect(_where(found), ['FR-073 test/a_test.dart:5']);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-073 - use through
    ///   a helper function of the file, however deep the chain, is checked.
    /// Path: unhappy (rule interaction)
    test('a helper that reads the repository taints its callers', () {
      final sources = SourceSet({
        'test/a_test.dart': '''
String _read() => realRepository.files.keys.first;
String _readAgain() => _read();
void main() {
  test('t', () => expect(_readAgain(), isNotEmpty));
}
''',
      });

      expect(_where(checkRealRepositoryTimeouts(sources)), [
        'FR-073 test/a_test.dart:4',
      ]);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-073 - several
    ///   files and several calls are all reported, sorted by path and line.
    /// Path: unhappy (multiple violations)
    test('every offending call in every file is reported, sorted', () {
      const call = "test('t', () => expect(_repository, isNotNull));";
      final first = _file(call, path: 'test/b_test.dart').files.entries.single;
      final second = _file(
        '$call\n$call',
        path: 'test/a_test.dart',
      ).files.entries.single;
      final found = checkRealRepositoryTimeouts(
        SourceSet({first.key: first.value, second.key: second.value}),
      );

      expect(_where(found), [
        'FR-073 test/a_test.dart:5',
        'FR-073 test/a_test.dart:6',
        'FR-073 test/b_test.dart:5',
      ]);
    });
  });

  /// Requirement: doc/specs/architecture-guardrails.md FR-073 - only the 10
  ///   second Timeout satisfies the budget.
  /// Path: unhappy (boundary)
  group('FR-073 wrong value', () {
    for (final wrong in const [
      'const Timeout(Duration(seconds: 11))',
      'const Timeout(Duration(seconds: 9))',
      'const Timeout(Duration(seconds: 100))',
      'const Timeout(Duration(minutes: 10))',
      'Timeout.none',
      'null',
      '_unknown',
    ]) {
      /// Requirement: doc/specs/architecture-guardrails.md FR-073 - a value
      ///   other than 10 seconds is a Violation naming it.
      /// Path: unhappy (boundary)
      test('timeout: $wrong is a Violation', () {
        final found = checkRealRepositoryTimeouts(
          _file(
            "test('t', () => expect(_repository, isNotNull), timeout: $wrong);",
          ),
        );

        expect(_where(found), ['FR-073 test/a_test.dart:5']);
        expect(found.single.detail, contains('declares timeout:'));
      });
    }

    /// Requirement: doc/specs/architecture-guardrails.md FR-073 - a named
    ///   constant counts only when it holds the 10 second Timeout.
    /// Path: unhappy (boundary)
    test('a constant holding another duration is a Violation', () {
      final sources = SourceSet({
        'test/a_test.dart': '''
const Timeout _slow = Timeout(Duration(seconds: 30));
void main() {
  test('t', () => expect(realRepository, isNotNull), timeout: _slow);
}
''',
      });

      expect(_where(checkRealRepositoryTimeouts(sources)), [
        'FR-073 test/a_test.dart:3',
      ]);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-073 - a timeout:
    ///   inside a nested call does not stand for the call's own argument.
    /// Path: unhappy (rule interaction)
    test('a timeout: in a nested closure does not count', () {
      final found = checkRealRepositoryTimeouts(
        _file('''
group('g', () {
  test('a', () => expect(_repository, isNotNull), timeout: _budget);
});'''),
      );

      expect(_where(found), ['FR-073 test/a_test.dart:5']);
    });
  });

  /// Requirement: doc/specs/architecture-guardrails.md FR-073 - the Timeout in
  ///   any of its accepted spellings, and calls that do not read the real
  ///   repository, give no Violation.
  /// Path: happy
  group('FR-073 clean fixtures', () {
    /// Requirement: doc/specs/architecture-guardrails.md FR-073 - the budget
    ///   through a top-level constant is accepted.
    /// Path: happy
    test('timeout: through the constant is accepted', () {
      final found = checkRealRepositoryTimeouts(
        _file(
          "test('t', () => expect(_repository, isNotNull), timeout: _budget);",
        ),
      );

      expect(found, isEmpty);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-073 - the literal,
    ///   with or without const and spacing, is accepted.
    /// Path: happy
    test('a literal Timeout is accepted in each spelling', () {
      final found = checkRealRepositoryTimeouts(
        _file('''
test('a', () => expect(_repository, isNotNull),
    timeout: const Timeout(Duration(seconds: 10)));
test('b', () => expect(_repository, isNotNull),
    timeout: Timeout(Duration(seconds:10)));
test(
  'c',
  () => expect(_repository, isNotNull),
  timeout: const Timeout(
    Duration(seconds: 10),
  ),
);'''),
      );

      expect(found, isEmpty);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-073 - the group's
    ///   budget covers the tests inside it.
    /// Path: happy
    test('a group with the timeout covers its nested tests', () {
      final found = checkRealRepositoryTimeouts(
        _file('''
group('g', () {
  test('a', () => expect(_repository, isNotNull));
  group('inner', () {
    test('b', () => expect(_repository, isNotNull));
  });
}, timeout: _budget);'''),
      );

      expect(found, isEmpty);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-073 - the budget
    ///   is for groups that read the real repository; fixture groups are not
    ///   asked for it.
    /// Path: happy
    test('a group that does not read the repository needs no timeout', () {
      final found = checkRealRepositoryTimeouts(
        _file('''
group('fixtures', () {
  test('a', () => expect(SourceSet({'lib/a.dart': ''}).files, isNotEmpty));
});
test('b', () => expect(findPackageRoot(Directory('x')), isNotNull));'''),
      );

      expect(found, isEmpty);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-073 - names in
    ///   comments and string literals are not code.
    /// Path: unhappy (invalid input)
    test('realRepository in a string or comment is not a use', () {
      final found = checkRealRepositoryTimeouts(
        _file('''
// realRepository
test('t', () => expect('realRepository findPackageRoot()', isNotNull));'''),
      );

      expect(found, isEmpty);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-073 - only test
    ///   files are scanned; a support file or a file outside test/ is not.
    /// Path: unhappy (boundary)
    test('files that are not *_test.dart under test/ are ignored', () {
      const call = "test('t', () => expect(_repository, isNotNull));";

      expect(
        checkRealRepositoryTimeouts(_file(call, path: 'test/helper.dart')),
        isEmpty,
      );
      expect(
        checkRealRepositoryTimeouts(_file(call, path: 'lib/a_test.dart')),
        isEmpty,
      );
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-073 - an empty
    ///   source set has nothing to check.
    /// Path: unhappy (empty and minimal)
    test('an empty source set yields no Violation', () {
      expect(checkRealRepositoryTimeouts(SourceSet(const {})), isEmpty);
    });
  });
}
