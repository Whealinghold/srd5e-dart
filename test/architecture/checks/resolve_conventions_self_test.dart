import 'package:test/test.dart';

import '../support/source_set.dart';
import '../support/violation.dart';
import 'resolve_conventions.dart';

const String _resultFile =
    'lib/src/d20_test/application/resolve_d20_test_result.dart';
const String _appFile = 'lib/src/d20_test/application/resolve_d20_test.dart';
const String _domainFile = 'lib/src/d20_test/domain/check_result.dart';

SourceSet _sources(Map<String, String> files) => SourceSet(files);

List<String> _where(List<Violation> violations) => [
  for (final v in violations) '${v.checkId} ${v.path}:${v.line}',
];

typedef _Case = ({
  String label,
  String requirement,
  String path,
  Map<String, String> files,
  List<String> expected,
});

/// Fixtures for R1 (FR-044): a String field or getter on a result class under
/// `lib/src/d20_test/` is flagged; typed fields, methods, other folders and
/// text in comments are not.
final List<_Case> _r1 = [
  (
    label: 'a String field on a result variant',
    requirement: 'doc/specs/resolve-d20-test-use-case.md FR-044',
    path: 'unhappy (invalid input)',
    files: {
      _resultFile:
          'final class ResolveD20TestRolledCheck {\n'
          '  final String label = "x";\n'
          '}\n',
    },
    expected: ['R1 $_resultFile:2'],
  ),
  (
    label: 'a String getter on a result variant',
    requirement: 'doc/specs/resolve-d20-test-use-case.md FR-044',
    path: 'unhappy (invalid input)',
    files: {
      _resultFile:
          'final class ResolveD20TestRolledAttack {\n'
          '  String get summary => "hit";\n'
          '}\n',
    },
    expected: ['R1 $_resultFile:2'],
  ),
  (
    label: 'a String field on a domain result',
    requirement: 'doc/specs/resolve-d20-test-use-case.md FR-044',
    path: 'unhappy (invalid input)',
    files: {
      _domainFile:
          'final class CheckResult {\n'
          '  final String note;\n'
          '  CheckResult(this.note);\n'
          '}\n',
    },
    expected: ['R1 $_domainFile:2'],
  ),
  (
    label: 'a nullable String field',
    requirement: 'doc/specs/resolve-d20-test-use-case.md FR-044',
    path: 'unhappy (boundary)',
    files: {
      _resultFile:
          'final class ResolveD20TestForcedFailure {\n'
          '  final String? reasonText;\n'
          '}\n',
    },
    expected: ['R1 $_resultFile:2'],
  ),
  (
    label: 'a String method is not a field or getter',
    requirement: 'doc/specs/resolve-d20-test-use-case.md FR-044',
    path: 'unhappy (boundary)',
    files: {
      _resultFile:
          'final class ResolveD20TestResult {\n'
          "  String toString() => 'debug';\n"
          '}\n',
    },
    expected: [],
  ),
  (
    label: 'typed fields and getters are clean',
    requirement: 'doc/specs/resolve-d20-test-use-case.md FR-044',
    path: 'happy',
    files: {
      _resultFile:
          'final class ResolveD20TestRolledCheck {\n'
          '  final int total;\n'
          '  bool get hit => true;\n'
          '  ResolveD20TestRolledCheck(this.total);\n'
          '}\n',
    },
    expected: [],
  ),
  (
    label: 'a String in a comment and a string literal is not a declaration',
    requirement: 'doc/specs/resolve-d20-test-use-case.md FR-044',
    path: 'unhappy (false positive)',
    files: {
      _resultFile:
          '// final String commented = "x";\n'
          'final class ResolveD20TestRolledCheck {\n'
          "  // final String alsoCommented;\n"
          '  final int total;\n'
          '}\n',
    },
    expected: [],
  ),
  (
    label: 'a String field outside the context is out of scope',
    requirement: 'doc/specs/resolve-d20-test-use-case.md FR-044',
    path: 'unhappy (boundary)',
    files: {
      'lib/src/combat/application/result.dart':
          'final class HitResult {\n  final String text;\n}\n',
    },
    expected: [],
  ),
  (
    label: 'a String field on a non-result class in the context',
    requirement: 'doc/specs/resolve-d20-test-use-case.md FR-044',
    path: 'unhappy (boundary)',
    files: {
      _resultFile: 'final class OtherHolder {\n  final String text;\n}\n',
    },
    expected: [],
  ),
];

/// Fixtures for R2 (FR-045): mutable top-level or static state in
/// `application/` is flagged; const, static final and the same text in
/// comments are not.
final List<_Case> _r2 = [
  (
    label: 'a mutable static field',
    requirement: 'doc/specs/resolve-d20-test-use-case.md FR-045',
    path: 'unhappy (determinism)',
    files: {
      _appFile:
          'final class ResolveD20Test {\n'
          '  static int resolvedCount = 0;\n'
          '}\n',
    },
    expected: ['R2 $_appFile:2'],
  ),
  (
    label: 'a non-const top-level variable',
    requirement: 'doc/specs/resolve-d20-test-use-case.md FR-045',
    path: 'unhappy (determinism)',
    files: {_appFile: "final now = 'clock';\n"},
    expected: ['R2 $_appFile:1'],
  ),
  (
    label: 'a typed non-const top-level variable',
    requirement: 'doc/specs/resolve-d20-test-use-case.md FR-045',
    path: 'unhappy (determinism)',
    files: {_appFile: 'int counter = 0;\n'},
    expected: ['R2 $_appFile:1'],
  ),
  (
    label: 'a const top-level variable is allowed',
    requirement: 'doc/specs/resolve-d20-test-use-case.md FR-045',
    path: 'happy',
    files: {_appFile: 'const String spanName = "srd5e.d20_test.resolve";\n'},
    expected: [],
  ),
  (
    label: 'static const and static final are allowed',
    requirement: 'doc/specs/resolve-d20-test-use-case.md FR-045',
    path: 'happy',
    files: {
      _appFile:
          'final class ResolveD20Test {\n'
          '  static const String spanName = "srd5e.d20_test.resolve";\n'
          '  static final Object lock = Object();\n'
          '}\n',
    },
    expected: [],
  ),
  (
    label: 'a static method is not a field',
    requirement: 'doc/specs/resolve-d20-test-use-case.md FR-045',
    path: 'unhappy (false positive)',
    files: {
      _appFile:
          'final class ResolveD20Test {\n'
          '  static int kindOf() => 1;\n'
          '}\n',
    },
    expected: [],
  ),
  (
    label: 'mutable state in a comment is not a violation',
    requirement: 'doc/specs/resolve-d20-test-use-case.md FR-045',
    path: 'unhappy (false positive)',
    files: {_appFile: '// static int count = 0;\n// final now = 1;\n'},
    expected: [],
  ),
  (
    label: 'mutable state outside application/ is out of scope',
    requirement: 'doc/specs/resolve-d20-test-use-case.md FR-045',
    path: 'unhappy (boundary)',
    files: {'lib/src/d20_test/domain/other.dart': 'int counter = 0;\n'},
    expected: [],
  ),
];

void main() {
  for (final entry in {'R1': _r1, 'R2': _r2}.entries) {
    /// Requirement: per case - the resolve-spec checks flag a violation in a
    ///   clean-vs-violating fixture pair and nothing else.
    /// Path: per case
    group('resolve conventions (${entry.key})', () {
      /// Requirement: per case
      /// Path: per case
      for (final c in entry.value) {
        test('${c.label} [${c.path}]', () {
          final violations = [
            ...checkResultsCarryNoStrings(_sources(c.files)),
            ...checkApplicationFolderPurity(_sources(c.files)),
          ];

          expect(_where(violations), c.expected);
        });
      }
    });
  }

  /// Requirement: doc/specs/resolve-d20-test-use-case.md FR-044 and FR-045 -
  ///   an empty repository has nothing to flag.
  /// Path: unhappy (empty and minimal)
  test('both checks accept an empty repository', () {
    final sources = _sources({});

    expect(checkResultsCarryNoStrings(sources), isEmpty);
    expect(checkApplicationFolderPurity(sources), isEmpty);
  });
}
