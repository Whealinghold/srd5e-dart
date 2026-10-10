import 'package:test/test.dart';

import '../support/source_set.dart';
import '../support/violation.dart';
import 'test_citations.dart';

const String _spec = 'doc/specs/architecture-guardrails.md';
const String _testFile = 'test/a_test.dart';

/// The placeholder spec the fixtures cite: FR-1 and FR-2 exist, FR-3 moved.
const String _xSpec =
    '# X\n\n| | |\n|---|---|\n| Status | draft |\n\n'
    '## 4. Requirements\n\n| Id | Requirement |\n|---|---|\n'
    '| FR-1 | a |\n| FR-2 | b |\n| FR-3 | Withdrawn: moved to y.md (FR-1) |\n';

String _lines(List<String> lines) => '${lines.join('\n')}\n';

/// Every check of the file, merged and sorted, as `<id> <path>:<line>`.
List<String> _where(SourceSet sources) => [
  for (final v in sortedViolations([
    for (final check in testCitationChecks.values) ...check(sources),
  ]))
    '${v.checkId} ${v.path}:${v.line}',
];

SourceSet _fixture(List<String> lines, {String path = _testFile}) =>
    SourceSet({path: _lines(lines), 'doc/specs/x.md': _xSpec});

const String _cites = '/// Requirement: doc/specs/x.md FR-1 - a';

typedef _Case = ({
  String label,
  String requirement,
  String path,
  List<String> source,
  List<String> expected,
});

/// The cases table of section 8 for FR-049 to FR-053, plus the cases for
/// FR-054, each as a test file next to the placeholder spec.
final List<_Case> _cases = [
  (
    label: 'comment directly above',
    requirement: '$_spec FR-049',
    path: 'happy',
    source: [_cites, '/// Path: happy', 'test("t", () {});'],
    expected: [],
  ),
  (
    label: 'blank line between',
    requirement: '$_spec FR-049',
    path: 'unhappy (boundary)',
    source: [_cites, '/// Path: happy', '', 'test("t", () {});'],
    expected: ['FR-049 $_testFile:4'],
  ),
  (
    label: 'no comment at all above a group',
    requirement: '$_spec FR-049',
    path: 'unhappy (invalid input)',
    source: ['group("g", () {});'],
    expected: ['FR-049 $_testFile:1'],
  ),
  (
    label: 'Rule instead of Requirement',
    requirement: '$_spec FR-049',
    path: 'happy',
    source: ['/// Rule: the rule', '/// Path: happy', 'test("t", () {});'],
    expected: [],
  ),
  (
    label: 'Rule alone needs no Path',
    requirement: '$_spec FR-053',
    path: 'happy',
    source: ['/// Rule: the rule', 'test("t", () {});'],
    expected: [],
  ),
  (
    label: 'none with reason',
    requirement: '$_spec FR-050',
    path: 'happy',
    source: [
      '/// Requirement: none - pins current behaviour',
      '/// Path: happy',
      'test("t", () {});',
    ],
    expected: [],
  ),
  (
    label: 'none bare',
    requirement: '$_spec FR-050',
    path: 'unhappy (boundary)',
    source: ['/// Requirement: none', '/// Path: happy', 'test("t", () {});'],
    expected: ['FR-050 $_testFile:1'],
  ),
  (
    label: 'none with a dash and no reason',
    requirement: '$_spec FR-050',
    path: 'unhappy (boundary)',
    source: ['/// Requirement: none -', '/// Path: happy', 'test("t", () {});'],
    expected: ['FR-050 $_testFile:1'],
  ),
  (
    label: 'none with the reason on a continuation line',
    requirement: '$_spec FR-050',
    path: 'happy',
    source: [
      '/// Requirement: none -',
      '///   pins current behaviour',
      '/// Path: happy',
      'test("t", () {});',
    ],
    expected: [],
  ),
  (
    label: 'empty Requirement',
    requirement: '$_spec FR-050',
    path: 'unhappy (invalid input)',
    source: ['/// Requirement:', '/// Path: happy', 'test("t", () {});'],
    expected: ['FR-050 $_testFile:1'],
  ),
  (
    label: 'test in loop, loop commented',
    requirement: '$_spec FR-051',
    path: 'happy',
    source: [
      '/// Requirement: per case',
      '/// Path: per case',
      'for (final c in cases) {',
      '  test("t", () {});',
      '}',
    ],
    expected: [],
  ),
  (
    label: 'test in loop, loop uncommented',
    requirement: '$_spec FR-049',
    path: 'unhappy (invalid input)',
    source: ['for (final c in cases) {', '  test("t", () {});', '}'],
    expected: ['FR-049 $_testFile:2'],
  ),
  (
    label: 'loop comment not per case',
    requirement: '$_spec FR-051',
    path: 'unhappy (rule interaction)',
    source: [
      _cites,
      '/// Path: happy',
      'for (final c in cases) {',
      '  test("t", () {});',
      '}',
    ],
    expected: ['FR-051 $_testFile:4'],
  ),
  (
    label: 'loop comment with Rule only',
    requirement: '$_spec FR-051',
    path: 'unhappy (rule interaction)',
    source: [
      '/// Rule: the rule',
      'for (final c in cases) {',
      '  test("t", () {});',
      '}',
    ],
    expected: ['FR-051 $_testFile:3'],
  ),
  (
    label: 'test in loop with its own comment',
    requirement: '$_spec FR-051',
    path: 'happy',
    source: [
      'for (final c in cases) {',
      '  $_cites',
      '  /// Path: happy',
      '  test("t", () {});',
      '}',
    ],
    expected: [],
  ),
  (
    label: 'per case on a plain test',
    requirement: '$_spec FR-052',
    path: 'unhappy (state error)',
    source: [
      '/// Requirement: per case',
      '/// Path: per case',
      'test("t", () {});',
    ],
    expected: ['FR-052 $_testFile:1'],
  ),
  (
    label: 'per case above a loop with no test inside',
    requirement: '$_spec FR-052',
    path: 'unhappy (state error)',
    source: [
      '/// Requirement: per case',
      '/// Path: per case',
      'for (final c in cases) {',
      '  use(c);',
      '}',
    ],
    expected: ['FR-052 $_testFile:1'],
  ),
  (
    label: 'per case on a declaration',
    requirement: '$_spec FR-052',
    path: 'unhappy (state error)',
    source: ['/// Requirement: per case', '/// Path: per case', 'final x = 1;'],
    expected: ['FR-052 $_testFile:1'],
  ),
  (
    label: 'per case on a group',
    requirement: '$_spec FR-052',
    path: 'happy',
    source: [
      '/// Requirement: per case',
      '/// Path: per case',
      'group("g", () {',
      '  for (final c in cases) {',
      '    test("t", () {});',
      '  }',
      '});',
    ],
    expected: [],
  ),
  (
    label: 'per case on a group without a loop',
    requirement: '$_spec FR-052',
    path: 'unhappy (state error)',
    source: [
      '/// Requirement: per case',
      '/// Path: per case',
      'group("g", () {',
      '  /// Requirement: none - reason',
      '  /// Path: happy',
      '  test("t", () {});',
      '});',
    ],
    expected: ['FR-052 $_testFile:1'],
  ),
  (
    label: 'forEach loop',
    requirement: '$_spec FR-052',
    path: 'happy',
    source: [
      '/// Requirement: per case',
      '/// Path: per case',
      'cases.forEach((c) {',
      '  test("t", () {});',
      '});',
    ],
    expected: [],
  ),
  (
    label: 'map loop',
    requirement: '$_spec FR-052',
    path: 'happy',
    source: [
      '/// Requirement: per case',
      '/// Path: per case',
      'cases.map((c) => test("t", () {}));',
    ],
    expected: [],
  ),
  (
    label: 'unsupported generator',
    requirement: '$_spec FR-049',
    path: 'unhappy (invalid input)',
    source: [
      '/// Requirement: none - reason',
      '/// Path: happy',
      'List.generate(3, (i) => test("t", () {}));',
    ],
    expected: ['FR-049 $_testFile:3'],
  ),
  (
    label: 'tooling method',
    requirement: '$_spec FR-057',
    path: 'unhappy (false positive)',
    source: ['helper.test("t", () {});'],
    expected: [],
  ),
  (
    label: 'per case path mismatch',
    requirement: '$_spec FR-053',
    path: 'unhappy (invalid input)',
    source: ['/// Requirement: x', '/// Path: per case', 'test("t", () {});'],
    expected: ['FR-053 $_testFile:2'],
  ),
  (
    label: 'empty unhappy kind',
    requirement: '$_spec FR-053',
    path: 'unhappy (invalid input)',
    source: [_cites, '/// Path: unhappy ()', 'test("t", () {});'],
    expected: ['FR-053 $_testFile:2'],
  ),
  (
    label: 'unknown path word',
    requirement: '$_spec FR-053',
    path: 'unhappy (invalid input)',
    source: [_cites, '/// Path: sad', 'test("t", () {});'],
    expected: ['FR-053 $_testFile:2'],
  ),
  (
    label: 'unhappy with a kind',
    requirement: '$_spec FR-053',
    path: 'happy',
    source: [_cites, '/// Path: unhappy (boundary)', 'test("t", () {});'],
    expected: [],
  ),
  (
    label: 'none without Path',
    requirement: '$_spec FR-053',
    path: 'unhappy (missing content)',
    source: ['/// Requirement: none - reason', 'test("t", () {});'],
    expected: ['FR-053 $_testFile:1'],
  ),
  (
    label: 'architecture test needs no comment',
    requirement: '$_spec FR-049',
    path: 'happy',
    source: ['test("t", () {});'],
    expected: [],
  ),
  (
    label: 'table-row citation',
    requirement: '$_spec FR-054',
    path: 'happy',
    source: [
      'const cases = [',
      '  (label: "a", requirement: "doc/specs/x.md FR-2", path: "happy"),',
      '];',
      '/// Requirement: per case',
      '/// Path: per case',
      'for (final c in cases) {',
      '  test(c.label, () {});',
      '}',
    ],
    expected: [],
  ),
  (
    label: 'table-row unknown id',
    requirement: '$_spec FR-054',
    path: 'unhappy (missing content)',
    source: [
      'const cases = [',
      '  (label: "a", requirement: "doc/specs/x.md FR-99", path: "happy"),',
      '];',
      '/// Requirement: per case',
      '/// Path: per case',
      'for (final c in cases) {',
      '  test(c.label, () {});',
      '}',
    ],
    expected: ['FR-054 $_testFile:2'],
  ),
  (
    label: 'several ids',
    requirement: '$_spec FR-054',
    path: 'happy',
    source: [
      '/// Requirement: doc/specs/x.md FR-1, FR-2 - both',
      '/// Path: happy',
      'test("t", () {});',
    ],
    expected: [],
  ),
  (
    label: 'ids joined by and and an ampersand',
    requirement: '$_spec FR-054',
    path: 'happy',
    source: [
      '/// Requirement: doc/specs/x.md FR-1 and FR-2 & FR-1',
      '/// Path: happy',
      'test("t", () {});',
    ],
    expected: [],
  ),
  (
    label: 'range',
    requirement: '$_spec FR-054',
    path: 'unhappy (invalid input)',
    source: [
      '/// Requirement: doc/specs/x.md FR-1 to FR-3 - a range',
      '/// Path: happy',
      'test("t", () {});',
    ],
    expected: ['FR-054 $_testFile:1'],
  ),
  (
    label: 'continuation line',
    requirement: '$_spec FR-054',
    path: 'happy',
    source: [
      '/// Requirement: see',
      '///   doc/specs/x.md FR-1 - a',
      '/// Path: happy',
      'test("t", () {});',
    ],
    expected: [],
  ),
  (
    label: 'unknown id on a continuation line',
    requirement: '$_spec FR-054',
    path: 'unhappy (missing content)',
    source: [
      '/// Requirement: see',
      '///   doc/specs/x.md FR-99 - a',
      '/// Path: happy',
      'test("t", () {});',
    ],
    expected: ['FR-054 $_testFile:2'],
  ),
  (
    label: 'a spec that does not exist',
    requirement: '$_spec FR-054',
    path: 'unhappy (missing content)',
    source: [
      '/// Requirement: doc/specs/nope.md FR-1 - a',
      '/// Path: happy',
      'test("t", () {});',
    ],
    expected: ['FR-054 $_testFile:1'],
  ),
  (
    label: 'a moved id',
    requirement: '$_spec FR-087',
    path: 'unhappy (state error)',
    source: [
      '/// Requirement: doc/specs/x.md FR-3 - moved',
      '/// Path: happy',
      'test("t", () {});',
    ],
    expected: ['FR-054 $_testFile:1'],
  ),
  (
    label: 'a section citation names only the file',
    requirement: '$_spec FR-054',
    path: 'happy',
    source: [
      '/// Requirement: doc/specs/x.md section 6 - a',
      '/// Path: happy',
      'test("t", () {});',
    ],
    expected: [],
  ),
  (
    label: 'a citation in a comment inside a string literal',
    requirement: '$_spec FR-054',
    path: 'unhappy (false positive)',
    source: [
      'final s = "/// Requirement: doc/specs/nope.md FR-1";',
      '/// Requirement: none - reason',
      '/// Path: happy',
      'test("t", () {});',
    ],
    expected: [],
  ),
];

/// A spec with Status `implemented` and the given section 8 text, rows
/// FR-1 (line 11), FR-2 (line 12) and a moved FR-3 (line 13).
String _implemented({
  String status = 'implemented',
  String section8 = 'Deliberately not covered: none.',
  String after = '',
}) =>
    '# A\n\n| | |\n|---|---|\n| Status | $status |\n\n'
    '## 4. Requirements\n\n| Id | Requirement |\n|---|---|\n'
    '| FR-1 | a |\n| FR-2 | b |\n| FR-3 | Withdrawn: moved to y.md (FR-1) |\n\n'
    '## 8. Test plan\n\n$section8\n$after';

typedef _CoverageCase = ({
  String label,
  String requirement,
  String path,
  String spec,
  List<String> tests,
  List<String> expected,
});

const String _a = 'doc/specs/a.md';

final List<_CoverageCase> _coverage = [
  (
    label: 'implemented, one id uncited (the moved id is skipped)',
    requirement: '$_spec FR-055',
    path: 'unhappy (missing content)',
    spec: _implemented(),
    tests: ['/// Requirement: doc/specs/a.md FR-1 - a', '/// Path: happy'],
    expected: ['FR-055 $_a:12'],
  ),
  (
    label: 'implemented, nothing cited',
    requirement: '$_spec FR-055',
    path: 'unhappy (missing content)',
    spec: _implemented(),
    tests: [],
    expected: ['FR-055 $_a:11', 'FR-055 $_a:12'],
  ),
  (
    label: 'both ids cited by two comments',
    requirement: '$_spec FR-055',
    path: 'happy',
    spec: _implemented(),
    tests: [
      '/// Requirement: doc/specs/a.md FR-1 - a',
      '/// Path: happy',
      'test("t", () {});',
      '/// Requirement: doc/specs/a.md FR-2 - b',
      '/// Path: happy',
      'test("u", () {});',
    ],
    expected: [],
  ),
  (
    label: 'several ids in one citation',
    requirement: '$_spec FR-070',
    path: 'happy',
    spec: _implemented(),
    tests: ['/// Requirement: doc/specs/a.md FR-1 and FR-2 - both'],
    expected: [],
  ),
  (
    label: 'an id cited only in a table row field',
    requirement: '$_spec FR-070',
    path: 'happy',
    spec: _implemented(),
    tests: [
      '/// Requirement: doc/specs/a.md FR-1 - a',
      'const c = (requirement: "doc/specs/a.md FR-2", path: "happy");',
    ],
    expected: [],
  ),
  (
    label: 'an id cited on a continuation line',
    requirement: '$_spec FR-070',
    path: 'happy',
    spec: _implemented(),
    tests: [
      '/// Requirement: doc/specs/a.md FR-1 - a',
      '///   and doc/specs/a.md FR-2 - b',
    ],
    expected: [],
  ),
  (
    label: 'an id listed as deliberately not covered',
    requirement: '$_spec FR-055',
    path: 'happy',
    spec: _implemented(
      section8: 'Deliberately not covered: FR-2 - no runtime behaviour',
    ),
    tests: ['/// Requirement: doc/specs/a.md FR-1 - a'],
    expected: [],
  ),
  (
    label: 'deliberately not covered with an empty reason',
    requirement: '$_spec FR-055',
    path: 'unhappy (boundary)',
    spec: _implemented(section8: 'Deliberately not covered: FR-2 -'),
    tests: ['/// Requirement: doc/specs/a.md FR-1 - a'],
    expected: ['FR-055 $_a:12'],
  ),
  (
    label: 'deliberately not covered outside section 8',
    requirement: '$_spec FR-055',
    path: 'unhappy (boundary)',
    spec: _implemented(
      after:
          '\n## 9. Open questions and decisions\n\n'
          'Deliberately not covered: FR-2 - elsewhere\n',
    ),
    tests: ['/// Requirement: doc/specs/a.md FR-1 - a'],
    expected: ['FR-055 $_a:12'],
  ),
  (
    label: 'a draft spec need not be covered',
    requirement: '$_spec FR-055',
    path: 'unhappy (boundary)',
    spec: _implemented(status: 'draft'),
    tests: [],
    expected: [],
  ),
  (
    label: 'a table whose first cell is a label is not an id',
    requirement: '$_spec FR-071',
    path: 'unhappy (false positive)',
    spec: _implemented(after: '', section8: 'Deliberately not covered: none.')
        .replaceFirst(
          '\n## 8. Test plan',
          '\n| Label | Fixture |\n|---|---|\n| blank line between | x |\n'
              '\n## 8. Test plan',
        ),
    tests: ['/// Requirement: doc/specs/a.md FR-1 and FR-2 - both'],
    expected: [],
  ),
];

typedef _StatusCase = ({
  String label,
  String requirement,
  String path,
  String status,
  List<String> expected,
});

final List<_StatusCase> _statuses = [
  for (final status in ['draft', 'accepted', 'implemented'])
    (
      label: 'Status $status',
      requirement: '$_spec FR-056',
      path: 'happy',
      status: status,
      expected: <String>[],
    ),
  (
    label: 'Status in backticks',
    requirement: '$_spec FR-056',
    path: 'happy',
    status: '`draft`',
    expected: [],
  ),
  (
    label: 'Status with a capital',
    requirement: '$_spec FR-056',
    path: 'unhappy (invalid input)',
    status: 'Draft',
    expected: ['FR-056 $_a:5'],
  ),
  (
    label: 'Status finished',
    requirement: '$_spec FR-056',
    path: 'unhappy (invalid input)',
    status: 'finished',
    expected: ['FR-056 $_a:5'],
  ),
  (
    label: 'Status empty',
    requirement: '$_spec FR-056',
    path: 'unhappy (boundary)',
    status: '',
    expected: ['FR-056 $_a:5'],
  ),
];

void main() {
  /// Requirement: per case
  /// Path: per case
  group('citation comment cases', () {
    /// Requirement: per case
    /// Path: per case
    for (final c in _cases) {
      test('${c.label} [${c.path}]', () {
        final path = c.label == 'architecture test needs no comment'
            ? 'test/architecture/a_test.dart'
            : _testFile;
        final expectedPath = [
          for (final e in c.expected) e.replaceFirst(_testFile, path),
        ];

        expect(_where(_fixture(c.source, path: path)), expectedPath);
      });
    }
  });

  /// Requirement: per case
  /// Path: per case
  group('implemented spec coverage cases', () {
    /// Requirement: per case
    /// Path: per case
    for (final c in _coverage) {
      test('${c.label} [${c.path}]', () {
        final sources = SourceSet({
          _a: c.spec,
          if (c.tests.isNotEmpty)
            'test/b_test.dart': '${c.tests.join('\n')}\ntest("t", () {});\n',
        });

        final found = [
          for (final v in sortedViolations(
            checkImplementedSpecsAreCovered(sources),
          ))
            '${v.checkId} ${v.path}:${v.line}',
        ];

        expect(found, c.expected);
      });
    }
  });

  /// Requirement: per case
  /// Path: per case
  group('spec status cases', () {
    /// Requirement: per case
    /// Path: per case
    for (final c in _statuses) {
      test('${c.label} [${c.path}]', () {
        final sources = SourceSet({_a: _implemented(status: c.status)});

        final found = [
          for (final v in checkSpecStatusValue(sources))
            '${v.checkId} ${v.path}:${v.line}',
        ];

        expect(found, c.expected);
      });
    }
  });

  /// Requirement: doc/specs/architecture-guardrails.md FR-056 - only
  ///   doc/specs files outside the underscore-prefixed templates and nested
  ///   folders are specs.
  /// Path: unhappy (boundary)
  group('which files are specs', () {
    /// Requirement: doc/specs/architecture-guardrails.md FR-056 - the
    ///   template and nested files are skipped.
    /// Path: unhappy (boundary)
    test('underscore files and nested files are not specs', () {
      final sources = SourceSet({
        'doc/specs/_template.md': _implemented(status: 'bad'),
        'doc/specs/sub/b.md': _implemented(status: 'bad'),
        'doc/other/c.md': _implemented(status: 'bad'),
        _a: _implemented(status: 'bad'),
      });

      expect(specFilePaths(sources), [_a]);
      expect(checkSpecStatusValue(sources), hasLength(1));
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-056 - a file
    ///   with no header table has no Status to check.
    /// Path: unhappy (empty and minimal)
    test('a spec without a header table yields nothing', () {
      final sources = SourceSet({_a: '# A\n\ntext\n'});

      expect(checkSpecStatusValue(sources), isEmpty);
    });
  });

  /// Requirement: doc/specs/architecture-guardrails.md FR-049 - files that
  ///   are not Dart sources are not scanned.
  /// Path: unhappy (boundary)
  group('scope', () {
    /// Requirement: doc/specs/architecture-guardrails.md FR-049 - a non-Dart
    ///   file under test/ holding a test call is ignored.
    /// Path: unhappy (boundary)
    test('only Dart files under test are scanned', () {
      final sources = SourceSet({
        'test/fixtures/a.txt': 'test("t", () {});\n',
        'lib/a.dart': 'test("t", () {});\n',
        'doc/specs/x.md': _xSpec,
      });

      expect(_where(sources), isEmpty);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-053 - the
    ///   architecture folder is exempt from FR-049 only, so a bare none
    ///   there is still reported.
    /// Path: unhappy (rule interaction)
    test('test/architecture is exempt from FR-049 only', () {
      final sources = _fixture([
        '/// Requirement: none',
        '/// Path: happy',
        'test("t", () {});',
      ], path: 'test/architecture/a_test.dart');

      expect(_where(sources), ['FR-050 test/architecture/a_test.dart:1']);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-009 - an ignore
    ///   comment changes no result.
    /// Path: unhappy (rule interaction)
    test('an ignore comment suppresses nothing', () {
      final sources = _fixture([
        '// ignore: missing_requirement',
        'test("t", () {});',
      ]);

      expect(_where(sources), ['FR-049 $_testFile:2']);
    });
  });

  /// Requirement: per case
  /// Path: per case
  group('violating fixtures', () {
    /// Requirement: per case
    /// Path: per case
    for (final id in testCitationChecks.keys) {
      test(
        '$id: the fixture yields a Violation of $id [unhappy (failure)]',
        () {
          final sources = testCitationViolatingFixtures[id]!();

          final found = testCitationChecks[id]!(sources);

          expect(found, isNotEmpty);
          expect(found.map((v) => v.checkId).toSet(), {id});
        },
      );
    }

    /// Requirement: doc/specs/architecture-guardrails.md FR-005 - the fixture
    ///   map and the check map name the same ids.
    /// Path: unhappy (missing content)
    test('the fixture map and the check map have the same ids', () {
      expect(
        testCitationViolatingFixtures.keys.toSet(),
        testCitationChecks.keys.toSet(),
      );
    });
  });
}
