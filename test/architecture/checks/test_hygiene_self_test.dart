import 'package:test/test.dart';

import '../support/source_set.dart';
import 'test_hygiene.dart';

const String _spec = 'doc/specs/architecture-guardrails.md';
const String _file = 'test/a_test.dart';

typedef _Case = ({
  String label,
  String requirement,
  String path,
  List<String> source,
  List<int> expectedLines,
});

/// Each fixture is one test file; the expected lines are the 1-based lines of
/// the FR-086 Violations.
final List<_Case> _cases = [
  (
    label: 'commented-out test',
    requirement: '$_spec FR-086',
    path: 'unhappy (invalid input)',
    source: ['// test("t", () {});'],
    expectedLines: [1],
  ),
  (
    label: 'commented-out group',
    requirement: '$_spec FR-086',
    path: 'unhappy (invalid input)',
    source: ['//group("g", () {});'],
    expectedLines: [1],
  ),
  (
    label: 'commented-out setUp',
    requirement: '$_spec FR-086',
    path: 'unhappy (invalid input)',
    source: ['', '  // setUp(() {});'],
    expectedLines: [2],
  ),
  (
    label: 'commented-out tearDown',
    requirement: '$_spec FR-086',
    path: 'unhappy (invalid input)',
    source: ['// tearDown(() {});'],
    expectedLines: [1],
  ),
  (
    label: 'commented-out test in a doc comment',
    requirement: '$_spec FR-086',
    path: 'unhappy (invalid input)',
    source: ['/// test("t", () {});', 'final x = 1;'],
    expectedLines: [1],
  ),
  (
    label: 'commented-out test inside a block comment',
    requirement: '$_spec FR-086',
    path: 'unhappy (invalid input)',
    source: ['/*', ' * test("t", () {});', ' */'],
    expectedLines: [2],
  ),
  (
    label: 'prose that mentions a test',
    requirement: '$_spec FR-086',
    path: 'happy',
    source: ['// the test(s) run in order', '// testing helpers'],
    expectedLines: [],
  ),
  (
    label: 'a commented setUpAll is not in the list',
    requirement: '$_spec FR-086',
    path: 'unhappy (boundary)',
    source: ['// setUpAll(() {});'],
    expectedLines: [],
  ),
  (
    label: 'a live test next to a comment',
    requirement: '$_spec FR-086',
    path: 'happy',
    source: ['// helper for the cases', 'test("t", () {});'],
    expectedLines: [],
  ),
  (
    label: 'skip with no Issue',
    requirement: '$_spec FR-086',
    path: 'unhappy (invalid input)',
    source: [
      '/// Requirement: none - reason',
      '/// Path: happy',
      'test("t", () {}, skip: true);',
    ],
    expectedLines: [3],
  ),
  (
    label: 'skip with an Issue',
    requirement: '$_spec FR-086',
    path: 'happy',
    source: [
      '/// Requirement: none - reason',
      '/// Path: happy',
      '/// Issue: #12 flaky on the CI runner',
      'test("t", () {}, skip: true);',
    ],
    expectedLines: [],
  ),
  (
    label: 'skip with an empty Issue',
    requirement: '$_spec FR-086',
    path: 'unhappy (boundary)',
    source: [
      '/// Requirement: none - reason',
      '/// Path: happy',
      '/// Issue:',
      'test("t", () {}, skip: "reason");',
    ],
    expectedLines: [4],
  ),
  (
    label: 'skip with the Issue on a continuation line',
    requirement: '$_spec FR-086',
    path: 'happy',
    source: [
      '/// Requirement: none - reason',
      '/// Path: happy',
      '/// Issue:',
      '///   #12 flaky on the CI runner',
      'test("t", () {}, skip: "reason");',
    ],
    expectedLines: [],
  ),
  (
    label: 'skip with an Issue on the loop comment',
    requirement: '$_spec FR-086',
    path: 'happy',
    source: [
      '/// Requirement: per case',
      '/// Path: per case',
      '/// Issue: #12 all cases wait for the fix',
      'for (final c in cases) {',
      '  test(c, () {}, skip: true);',
      '}',
    ],
    expectedLines: [],
  ),
  (
    label: 'skip on a group with no Issue',
    requirement: '$_spec FR-086',
    path: 'unhappy (invalid input)',
    source: [
      '/// Requirement: none - reason',
      '/// Path: happy',
      'group("g", () {',
      '  test("t", () {});',
      '}, skip: true);',
    ],
    expectedLines: [5],
  ),
  (
    label: 'skip call inside a test body',
    requirement: '$_spec FR-086',
    path: 'unhappy (invalid input)',
    source: [
      '/// Requirement: none - reason',
      '/// Path: happy',
      'test("t", () {',
      '  skip("later");',
      '});',
    ],
    expectedLines: [4],
  ),
  (
    label: 'skip outside any test',
    requirement: '$_spec FR-086',
    path: 'unhappy (state error)',
    source: ['final x = Foo(skip: true);'],
    expectedLines: [1],
  ),
  (
    label: 'Iterable.skip',
    requirement: '$_spec FR-086',
    path: 'unhappy (false positive)',
    source: ['final x = list.skip(2).toList();'],
    expectedLines: [],
  ),
  (
    label: 'a function declared as skip',
    requirement: '$_spec FR-086',
    path: 'unhappy (false positive)',
    source: ['void skip(String reason) {}'],
    expectedLines: [],
  ),
  (
    label: 'skip inside a string or comment',
    requirement: '$_spec FR-086',
    path: 'unhappy (false positive)',
    source: ['final s = "skip: true";', '// skip: true'],
    expectedLines: [],
  ),
];

void main() {
  /// Requirement: per case
  /// Path: per case
  for (final c in _cases) {
    test('${c.label} [${c.path}]', () {
      final sources = SourceSet({_file: '${c.source.join('\n')}\n'});

      final found = checkNoCommentedOutOrSkippedTests(sources);

      expect(
        [for (final v in found) (v.checkId, v.path, v.line)],
        [for (final line in c.expectedLines) ('FR-086', _file, line)],
      );
    });
  }

  /// Requirement: doc/specs/architecture-guardrails.md FR-086 - the check
  ///   reads only Dart files under test/.
  /// Path: unhappy (boundary)
  test('Dart files outside test are not scanned', () {
    final sources = SourceSet({
      'lib/a.dart': '// test("t", () {});\nfinal x = Foo(skip: true);\n',
      'test/notes.md': '// test("t", () {});\n',
    });

    expect(checkNoCommentedOutOrSkippedTests(sources), isEmpty);
  });

  /// Requirement: doc/specs/architecture-guardrails.md FR-009 - an ignore
  ///   comment does not suppress a skip.
  /// Path: unhappy (rule interaction)
  test('an ignore comment suppresses nothing', () {
    final sources = SourceSet({
      _file: '// ignore: skipped_test\ntest("t", () {}, skip: true);\n',
    });

    final found = checkNoCommentedOutOrSkippedTests(sources);

    expect([for (final v in found) v.line], [2]);
  });

  /// Requirement: doc/specs/architecture-guardrails.md FR-005 - the fixture
  ///   of FR-086 yields a Violation of exactly that id.
  /// Path: unhappy (failure)
  test('the FR-086 fixture yields a Violation of FR-086', () {
    final found = testHygieneChecks['FR-086']!(
      testHygieneViolatingFixtures['FR-086']!(),
    );

    expect(found.map((v) => v.checkId).toSet(), {'FR-086'});
    expect(testHygieneViolatingFixtures.keys, testHygieneChecks.keys);
  });
}
