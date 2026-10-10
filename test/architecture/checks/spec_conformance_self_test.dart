import 'package:test/test.dart';

import '../support/constants.dart';
import '../support/source_set.dart';
import '../support/violation.dart';
import 'spec_conformance.dart';

List<String> _where(List<Violation> violations) => [
  for (final v in violations) '${v.checkId} ${v.path}:${v.line}',
];

typedef _Case = ({
  String label,
  String path,
  SourceSet Function() sources,
  List<String> expected,
});

typedef _Check = List<Violation> Function(SourceSet);

/// Header lines of [specFixtureText]: Context 6, Roadmap phase 7, Depends on
/// 8, table header 3; see [specFixtureText] for the other lines.
const String _depends = ':8';

String _spec(String stem) => 'doc/specs/$stem.md';

/// A decisions spec that holds the rank table of [ranks]. The table's first
/// data row is on line 40 of the file.
String _decisions(Map<int, List<String>> ranks) =>
    specFixtureText(after: rankTableFixture(ranks));

void _run(String id, _Check check, List<_Case> cases) {
  /// Requirement: doc/specs/architecture-guardrails.md FR-005 - every check
  ///   id has a clean and a violating fixture with exact Violations.
  /// Path: happy
  group(id, () {
    /// Requirement: per case - doc/specs/architecture-guardrails.md FR-088,
    ///   FR-089, FR-090, FR-092, FR-096, FR-099, FR-100, FR-101 and FR-102 -
    ///   exact check id, path and line per fixture, clean ones included.
    /// Path: per case
    for (final c in cases) {
      test('${c.path}: ${c.label}', () {
        expect(_where(check(c.sources())), c.expected);
      });
    }
  });
}

String _headingsWithout(String heading) =>
    specFixtureText().replaceFirst('$heading\n\n', '');

void main() {
  _run('FR-088', checkSpecTemplateShape, [
    (
      label: 'a conforming spec',
      path: 'happy',
      sources: () => specFixtureSources({'a': specFixtureText()}),
      expected: [],
    ),
    (
      label: 'a missing heading is reported where the next one stands',
      path: 'unhappy (missing content)',
      sources: () =>
          specFixtureSources({'a': _headingsWithout('## 2. Source')}),
      expected: ['FR-088 ${_spec('a')}:12'],
    ),
    (
      label: 'a renamed heading is reported at the heading',
      path: 'unhappy (missing content)',
      sources: () => specFixtureSources({
        'a': specFixtureText().replaceFirst('## 5. Model', '## 5. Models'),
      }),
      expected: ['FR-088 ${_spec('a')}:22'],
    ),
    (
      label: 'swapped headings are out of order',
      path: 'unhappy (missing content)',
      sources: () => specFixtureSources({
        'a': specFixtureText()
            .replaceFirst('## 5. Model', '## TMP')
            .replaceFirst('## 6. Interface', '## 5. Model')
            .replaceFirst('## TMP', '## 6. Interface'),
      }),
      expected: ['FR-088 ${_spec('a')}:22'],
    ),
    (
      label: 'a missing last heading is reported at the last heading',
      path: 'unhappy (missing content)',
      sources: () => specFixtureSources({
        'a': _headingsWithout('## 10. Changelog impact'),
      }),
      expected: ['FR-088 ${_spec('a')}:30'],
    ),
    (
      label: 'an eleventh heading is reported at it',
      path: 'unhappy (missing content)',
      sources: () =>
          specFixtureSources({'a': specFixtureText(after: '## 11. Extra\n')}),
      expected: ['FR-088 ${_spec('a')}:34'],
    ),
    (
      label: 'a header row left out is reported at the table',
      path: 'unhappy (missing content)',
      sources: () => specFixtureSources({
        'a': specFixtureText().replaceFirst('| Roadmap phase | 0 |\n', ''),
      }),
      expected: ['FR-088 ${_spec('a')}:3'],
    ),
    (
      label: 'no header table and no headings',
      path: 'unhappy (empty and minimal)',
      sources: () => specFixtureSources({'a': '# T\n'}),
      expected: ['FR-088 ${_spec('a')}:1', 'FR-088 ${_spec('a')}:1'],
    ),
    (
      label: 'a Context that is not in the map',
      path: 'unhappy (invalid input)',
      sources: () =>
          specFixtureSources({'a': specFixtureText(context: 'nowhere')}),
      expected: ['FR-088 ${_spec('a')}:6'],
    ),
    (
      label: 'a Context without backticks',
      path: 'unhappy (invalid input)',
      sources: () => specFixtureSources({
        'a': specFixtureText().replaceFirst('`package`', 'package'),
      }),
      expected: ['FR-088 ${_spec('a')}:6'],
    ),
    (
      label: 'shared_ports and a context of the map are accepted',
      path: 'happy',
      sources: () => specFixtureSources({
        'a': specFixtureText(context: 'shared_ports'),
        'b': specFixtureText(context: 'combat'),
        'c': specFixtureText(context: 'testing'),
        'd': specFixtureText(context: 'shared_kernel'),
      }),
      expected: [],
    ),
    (
      label: 'a file whose name starts with an underscore is not a spec',
      path: 'unhappy (false positive)',
      sources: () => specFixtureSources({'_template': '# <T>\n'}),
      expected: [],
    ),
  ]);

  _run('FR-089', checkSpecDependenciesResolve, [
    (
      label: 'an acyclic chain',
      path: 'happy',
      sources: () => specFixtureSources({
        'a': specFixtureText(depends: '`b.md`'),
        'b': specFixtureText(depends: '`c.md`'),
        'c': specFixtureText(),
      }),
      expected: [],
    ),
    (
      label: 'a dependency with no file',
      path: 'unhappy (missing content)',
      sources: () =>
          specFixtureSources({'a': specFixtureText(depends: '`zzz.md`')}),
      expected: ['FR-089 ${_spec('a')}$_depends'],
    ),
    (
      label: 'a spec listing itself',
      path: 'unhappy (boundary)',
      sources: () =>
          specFixtureSources({'a': specFixtureText(depends: '`a.md`')}),
      expected: ['FR-089 ${_spec('a')}$_depends'],
    ),
    (
      label: 'a two-spec cycle is reported once',
      path: 'unhappy (rule interaction)',
      sources: () => specFixtureSources({
        'a': specFixtureText(depends: '`b.md`'),
        'b': specFixtureText(depends: '`a.md`'),
      }),
      expected: ['FR-089 ${_spec('a')}$_depends'],
    ),
    (
      label: 'a three-spec cycle is reported once',
      path: 'unhappy (rule interaction)',
      sources: () => specFixtureSources({
        'a': specFixtureText(depends: '`b.md`'),
        'b': specFixtureText(depends: '`c.md`'),
        'c': specFixtureText(depends: '`a.md`'),
        'd': specFixtureText(depends: '`a.md`'),
      }),
      expected: ['FR-089 ${_spec('a')}$_depends'],
    ),
  ]);

  _run('FR-090', checkSpecContextEdges, [
    (
      label: 'combat lists content (upstream)',
      path: 'happy',
      sources: () => specFixtureSources({
        'a': specFixtureText(context: 'combat', depends: '`b.md`'),
        'b': specFixtureText(context: 'content'),
      }),
      expected: [],
    ),
    (
      label: 'combat lists character (not upstream)',
      path: 'unhappy (rule interaction)',
      sources: () => specFixtureSources({
        'a': specFixtureText(context: 'combat', depends: '`b.md`'),
        'b': specFixtureText(context: 'character'),
      }),
      expected: ['FR-090 ${_spec('a')}$_depends'],
    ),
    (
      label: 'character lists combat (not upstream)',
      path: 'unhappy (rule interaction)',
      sources: () => specFixtureSources({
        'a': specFixtureText(context: 'character', depends: '`b.md`'),
        'b': specFixtureText(context: 'combat'),
      }),
      expected: ['FR-090 ${_spec('a')}$_depends'],
    ),
    (
      label: 'content lists combat (downstream)',
      path: 'unhappy (rule interaction)',
      sources: () => specFixtureSources({
        'a': specFixtureText(context: 'content', depends: '`b.md`'),
        'b': specFixtureText(context: 'combat'),
      }),
      expected: ['FR-090 ${_spec('a')}$_depends'],
    ),
    (
      label: 'a context spec lists a package spec',
      path: 'happy',
      sources: () => specFixtureSources({
        'a': specFixtureText(
          context: 'content',
          depends: '`shared-types-and-ownership.md`',
        ),
        'shared-types-and-ownership': specFixtureText(),
      }),
      expected: [],
    ),
    (
      label: 'a context spec lists shared_kernel, shared_ports and testing',
      path: 'happy',
      sources: () => specFixtureSources({
        'a': specFixtureText(
          context: 'combat',
          depends: '`k.md`, `p.md`, `t.md`',
        ),
        'k': specFixtureText(context: 'shared_kernel'),
        'p': specFixtureText(context: 'shared_ports'),
        't': specFixtureText(context: 'testing'),
      }),
      expected: [],
    ),
    (
      label: 'a package spec lists a context spec (not a forbidden edge)',
      path: 'unhappy (boundary)',
      sources: () => specFixtureSources({
        'a': specFixtureText(depends: '`b.md`'),
        'b': specFixtureText(context: 'combat'),
      }),
      expected: [],
    ),
    (
      label: 'a shared_kernel spec lists a context spec',
      path: 'unhappy (rule interaction)',
      sources: () => specFixtureSources({
        'a': specFixtureText(context: 'shared_kernel', depends: '`b.md`'),
        'b': specFixtureText(context: 'content'),
      }),
      expected: ['FR-090 ${_spec('a')}$_depends'],
    ),
    (
      label: 'a shared_kernel spec lists shared_kernel and package specs',
      path: 'happy',
      sources: () => specFixtureSources({
        'a': specFixtureText(
          context: 'shared_kernel',
          depends: '`b.md`, `c.md`',
        ),
        'b': specFixtureText(context: 'shared_kernel'),
        'c': specFixtureText(),
      }),
      expected: [],
    ),
    (
      label: 'a shared_ports spec lists a context spec',
      path: 'unhappy (rule interaction)',
      sources: () => specFixtureSources({
        'a': specFixtureText(context: 'shared_ports', depends: '`b.md`'),
        'b': specFixtureText(context: 'combat'),
      }),
      expected: ['FR-090 ${_spec('a')}$_depends'],
    ),
    (
      label: 'a shared_ports spec lists shared_kernel',
      path: 'happy',
      sources: () => specFixtureSources({
        'a': specFixtureText(context: 'shared_ports', depends: '`b.md`'),
        'b': specFixtureText(context: 'shared_kernel'),
      }),
      expected: [],
    ),
    (
      label: 'two specs of one context',
      path: 'happy',
      sources: () => specFixtureSources({
        'a': specFixtureText(context: 'combat', depends: '`b.md`'),
        'b': specFixtureText(context: 'combat'),
      }),
      expected: [],
    ),
  ]);

  String ranked(Map<int, List<String>> ranks) => _decisions(ranks);

  _run('FR-092', checkSpecPhases, [
    (
      label: 'phase 2 lists phase 2',
      path: 'happy',
      sources: () => specFixtureSources({
        'a': specFixtureText(phase: '2', depends: '`b.md`'),
        'b': specFixtureText(phase: '2'),
      }),
      expected: [],
    ),
    (
      label: 'phase 0 lists phase 1',
      path: 'unhappy (boundary)',
      sources: () => specFixtureSources({
        'a': specFixtureText(phase: '0', depends: '`b.md`'),
        'b': specFixtureText(phase: '1'),
      }),
      expected: ['FR-092 ${_spec('a')}$_depends'],
    ),
    (
      label: 'phase 3 lists a 3-4 spec',
      path: 'unhappy (boundary)',
      sources: () => specFixtureSources({
        'a': specFixtureText(phase: '3', depends: '`b.md`'),
        'b': specFixtureText(phase: '3-4'),
      }),
      expected: ['FR-092 ${_spec('a')}$_depends'],
    ),
    (
      label: 'phase 4 lists a 3-4 spec',
      path: 'happy',
      sources: () => specFixtureSources({
        'a': specFixtureText(phase: '4', depends: '`b.md`'),
        'b': specFixtureText(phase: '3-4'),
      }),
      expected: [],
    ),
    (
      label: 'phase 3 lists "Types 2; bulk data 5" (phase 2)',
      path: 'happy',
      sources: () => specFixtureSources({
        'a': specFixtureText(phase: '3', depends: '`b.md`'),
        'b': specFixtureText(phase: 'Types 2; bulk data 5'),
      }),
      expected: [],
    ),
    (
      label: 'a Roadmap phase cell with no integer',
      path: 'unhappy (invalid input)',
      sources: () => specFixtureSources({'a': specFixtureText(phase: 'later')}),
      expected: ['FR-092 ${_spec('a')}:7'],
    ),
    (
      label: 'a rank-90 phase-0 spec may list a phase-4 spec',
      path: 'happy',
      sources: () => specFixtureSources({
        'a': specFixtureText(phase: '0', depends: '`b.md`'),
        'b': specFixtureText(phase: '4'),
        'shared-types-and-ownership': ranked({
          0: ['shared-types-and-ownership'],
          4: ['b'],
          90: ['a'],
        }),
      }),
      expected: [],
    ),
    (
      label: 'a rank-89 phase-0 spec may not',
      path: 'unhappy (boundary)',
      sources: () => specFixtureSources({
        'a': specFixtureText(phase: '0', depends: '`b.md`'),
        'b': specFixtureText(phase: '4'),
        'shared-types-and-ownership': ranked({
          0: ['shared-types-and-ownership'],
          4: ['b'],
          89: ['a'],
        }),
      }),
      expected: ['FR-092 ${_spec('a')}$_depends'],
    ),
  ]);

  String cite(String body) => specFixtureText(after: '$body\n');
  final movedRow = specFixtureText(
    rows: '| FR-2 | Withdrawn: moved to y.md (FR-1) |\n',
  );
  final mangled = '${['doc', 'specs'].join('-')}-b-md';
  SourceSet citing(String body) =>
      specFixtureSources({'a': cite(body), 'b': movedRow});

  _run('FR-096', checkSpecCitations, [
    (
      label: 'a citation of an existing id in backticks',
      path: 'happy',
      sources: () => citing('See `b.md` FR-1.'),
      expected: [],
    ),
    (
      label: 'a citation with the doc/specs/ prefix',
      path: 'happy',
      sources: () => citing('See `doc/specs/b.md` FR-1.'),
      expected: [],
    ),
    (
      label: 'a placeholder spec name is exempt',
      path: 'unhappy (false positive)',
      sources: () => citing('See `x.md` FR-99 and `z.md` FR-1.'),
      expected: [],
    ),
    (
      label: 'a bare id is local and not checked',
      path: 'unhappy (false positive)',
      sources: () => citing('See FR-99.'),
      expected: [],
    ),
    (
      label: 'a file mentioned without an id is not a citation',
      path: 'unhappy (false positive)',
      sources: () => citing('See `missing.md` and `../roadmap.md`.'),
      expected: [],
    ),
    (
      label: 'a citation of a missing file',
      path: 'unhappy (missing content)',
      sources: () => citing('See `missing.md` FR-1.'),
      expected: ['FR-096 ${_spec('a')}:34'],
    ),
    (
      label: 'a citation of a missing id',
      path: 'unhappy (missing content)',
      sources: () => citing('See `b.md` FR-9.'),
      expected: ['FR-096 ${_spec('a')}:34'],
    ),
    (
      label: 'a citation of a moved id',
      path: 'unhappy (state error)',
      sources: () => citing('See `b.md` FR-2.'),
      expected: ['FR-096 ${_spec('a')}:34'],
    ),
    (
      label: 'a moved id followed by the suffix',
      path: 'happy',
      sources: () => citing('Was `b.md` FR-2 (withdrawn).'),
      expected: [],
    ),
    (
      label: 'the suffix on an id that is not moved',
      path: 'unhappy (state error)',
      sources: () => citing('Was `b.md` FR-1 (withdrawn).'),
      expected: ['FR-096 ${_spec('a')}:34'],
    ),
    (
      label: 'a range whose end is moved',
      path: 'unhappy (boundary)',
      sources: () => citing('See `b.md` FR-1 to FR-2.'),
      expected: ['FR-096 ${_spec('a')}:34'],
    ),
    (
      label: 'ids joined by and and & are all checked',
      path: 'unhappy (boundary)',
      sources: () => citing('See `b.md` FR-1 and FR-8, FR-1 & FR-9.'),
      expected: ['FR-096 ${_spec('a')}:34', 'FR-096 ${_spec('a')}:34'],
    ),
    (
      label: 'prose after the first id ends the run',
      path: 'unhappy (boundary)',
      sources: () => citing('See `b.md` FR-1 for a, FR-9 for b.'),
      expected: [],
    ),
    (
      label: 'a fenced block is ignored',
      path: 'unhappy (false positive)',
      sources: () => citing('```\n`missing.md` FR-1\n```'),
      expected: [],
    ),
    (
      label: 'a link target is a citation, the link text is not',
      path: 'unhappy (boundary)',
      sources: () => citing('See [b.md](b.md) FR-9.'),
      expected: ['FR-096 ${_spec('a')}:34'],
    ),
    (
      label: 'a citation wrapped over two lines',
      path: 'unhappy (boundary)',
      sources: () => citing('See `b.md`\nFR-9.'),
      expected: ['FR-096 ${_spec('a')}:34'],
    ),
    (
      label: 'a mangled spec name',
      path: 'unhappy (invalid input)',
      sources: () => citing('See $mangled for it.'),
      expected: ['FR-096 ${_spec('a')}:34'],
    ),
    (
      label: 'a moved-id row pointing at another moved id',
      path: 'unhappy (rule interaction)',
      sources: () => specFixtureSources({
        'b': movedRow,
        'c': specFixtureText(
          rows: '| FR-2 | Withdrawn: moved to b.md (FR-2) |\n',
        ),
      }),
      expected: ['FR-096 ${_spec('c')}:21'],
    ),
    (
      label: 'a moved-id row pointing at a live id',
      path: 'happy',
      sources: () => specFixtureSources({
        'b': movedRow,
        'c': specFixtureText(
          rows: '| FR-2 | Withdrawn: moved to b.md (FR-1) |\n',
        ),
      }),
      expected: [],
    ),
  ]);

  const dataBase = {
    'content-schema-and-decoder': 'content',
    'content-source-port': 'content',
    'content-spells': 'content',
    'ability-scores': 'shared_kernel',
    'observability-ports': 'shared_ports',
  };
  SourceSet dataSpec(String stem, String depends, {String? extraStem}) =>
      specFixtureSources({
        stem: specFixtureText(context: 'content', depends: depends),
        for (final e in dataBase.entries)
          if (e.key != stem) e.key: specFixtureText(context: e.value),
        'shared-types-and-ownership': specFixtureText(),
      });

  _run('FR-099', checkDataSpecDependencies, [
    (
      label: 'schema, source port and a package spec',
      path: 'happy',
      sources: () => dataSpec(
        'content-equipment',
        '`content-schema-and-decoder.md`, `content-source-port.md`, '
            '`shared-types-and-ownership.md`',
      ),
      expected: [],
    ),
    (
      label: 'another data spec',
      path: 'unhappy (rule interaction)',
      sources: () => dataSpec('content-equipment', '`content-spells.md`'),
      expected: ['FR-099 ${_spec('content-equipment')}$_depends'],
    ),
    (
      label: 'a shared_kernel spec',
      path: 'unhappy (rule interaction)',
      sources: () => dataSpec('content-equipment', '`ability-scores.md`'),
      expected: ['FR-099 ${_spec('content-equipment')}$_depends'],
    ),
    (
      label: 'a shared_ports spec',
      path: 'unhappy (rule interaction)',
      sources: () => dataSpec('content-monsters', '`observability-ports.md`'),
      expected: ['FR-099 ${_spec('content-monsters')}$_depends'],
    ),
    (
      label: 'a spec that is not a data spec may list a data spec',
      path: 'happy',
      sources: () => dataSpec('content-classes-data', '`content-spells.md`'),
      expected: [],
    ),
    (
      label: 'a missing file is FR-089, not this check',
      path: 'unhappy (false positive)',
      sources: () => dataSpec('content-equipment', '`nowhere.md`'),
      expected: [],
    ),
  ]);

  _run('FR-100', checkDependsOnTokensOnly, [
    (
      label: 'only tokens',
      path: 'happy',
      sources: () => specFixtureSources({
        'a': specFixtureText(depends: '`b.md`, `c.md`,`d.md`'),
      }),
      expected: [],
    ),
    (
      label: 'none and an empty cell',
      path: 'unhappy (empty and minimal)',
      sources: () => specFixtureSources({
        'a': specFixtureText(),
        'b': specFixtureText(depends: ''),
      }),
      expected: [],
    ),
    (
      label: 'prose',
      path: 'unhappy (invalid input)',
      sources: () => specFixtureSources({
        'a': specFixtureText(depends: '`b.md` and the rest'),
      }),
      expected: ['FR-100 ${_spec('a')}$_depends'],
    ),
    (
      label: 'a link',
      path: 'unhappy (invalid input)',
      sources: () =>
          specFixtureSources({'a': specFixtureText(depends: '[b](b.md)')}),
      expected: ['FR-100 ${_spec('a')}$_depends'],
    ),
    (
      label: 'a bare file name',
      path: 'unhappy (invalid input)',
      sources: () =>
          specFixtureSources({'a': specFixtureText(depends: 'b.md')}),
      expected: ['FR-100 ${_spec('a')}$_depends'],
    ),
    (
      label: 'an FR id',
      path: 'unhappy (invalid input)',
      sources: () =>
          specFixtureSources({'a': specFixtureText(depends: '`b.md` FR-3')}),
      expected: ['FR-100 ${_spec('a')}$_depends'],
    ),
    (
      label: 'a parenthesis',
      path: 'unhappy (invalid input)',
      sources: () =>
          specFixtureSources({'a': specFixtureText(depends: '`b.md` (for x)')}),
      expected: ['FR-100 ${_spec('a')}$_depends'],
    ),
    (
      label: 'none followed by prose and a bare name',
      path: 'unhappy (invalid input)',
      sources: () => specFixtureSources({
        'a': specFixtureText(depends: 'none. Mentions foo.md only.'),
      }),
      expected: ['FR-100 ${_spec('a')}$_depends'],
    ),
  ]);

  const shared = 'shared-types-and-ownership';
  SourceSet ranksOf(Map<int, List<String>> ranks, Map<String, String> specs) =>
      specFixtureSources({
        shared: _decisions(ranks),
        for (final e in specs.entries) e.key: e.value,
      });

  _run('FR-101', checkSpecRanks, [
    (
      label: 'rank 5 lists rank 4',
      path: 'happy',
      sources: () => ranksOf(
        {
          0: [shared],
          4: ['b'],
          5: ['a'],
        },
        {'a': specFixtureText(depends: '`b.md`'), 'b': specFixtureText()},
      ),
      expected: [],
    ),
    (
      label: 'rank 4 lists another rank 4 spec',
      path: 'unhappy (rule interaction)',
      sources: () => ranksOf(
        {
          0: [shared],
          4: ['a', 'b'],
        },
        {'a': specFixtureText(depends: '`b.md`'), 'b': specFixtureText()},
      ),
      expected: ['FR-101 ${_spec('a')}$_depends'],
    ),
    (
      label: 'rank 4 lists a rank 5 spec',
      path: 'unhappy (rule interaction)',
      sources: () => ranksOf(
        {
          0: [shared],
          4: ['a'],
          5: ['b'],
        },
        {'a': specFixtureText(depends: '`b.md`'), 'b': specFixtureText()},
      ),
      expected: ['FR-101 ${_spec('a')}$_depends'],
    ),
    (
      label: 'a spec missing from the table',
      path: 'unhappy (missing content)',
      sources: () => ranksOf(
        {
          0: [shared],
          4: ['a'],
        },
        {'a': specFixtureText(), 'b': specFixtureText()},
      ),
      expected: ['FR-101 ${_spec('b')}:1'],
    ),
    (
      label: 'a table name with no file',
      path: 'unhappy (missing content)',
      sources: () => ranksOf(
        {
          0: [shared],
          4: ['a', 'ghost'],
        },
        {'a': specFixtureText()},
      ),
      expected: ['FR-101 ${_spec(shared)}:39'],
    ),
    (
      label: 'a name listed under two ranks',
      path: 'unhappy (state error)',
      sources: () => ranksOf(
        {
          0: [shared],
          4: ['a'],
          5: ['a'],
        },
        {'a': specFixtureText()},
      ),
      expected: ['FR-101 ${_spec(shared)}:40'],
    ),
    (
      label: 'a rank-90 spec lists rank 1 and rank 60 specs',
      path: 'happy',
      sources: () => ranksOf(
        {
          0: [shared],
          1: ['b'],
          60: ['c'],
          90: ['a'],
        },
        {
          'a': specFixtureText(depends: '`b.md`, `c.md`'),
          'b': specFixtureText(),
          'c': specFixtureText(),
        },
      ),
      expected: [],
    ),
    (
      label: 'the decisions spec is always allowed',
      path: 'happy',
      sources: () => ranksOf(
        {
          0: [shared],
          1: ['a'],
        },
        {'a': specFixtureText(depends: '`$shared.md`')},
      ),
      expected: [],
    ),
    (
      label: 'a Consumed by row naming a higher rank is ignored',
      path: 'unhappy (false positive)',
      sources: () => ranksOf(
        {
          0: [shared],
          1: ['a'],
          9: ['b'],
        },
        {
          'a': specFixtureText().replaceFirst(
            '| Depends on | none |\n',
            '| Depends on | none |\n| Consumed by | `b.md` |\n',
          ),
          'b': specFixtureText(),
        },
      ),
      expected: [],
    ),
    (
      label: 'gaps and several names per rank order only',
      path: 'unhappy (boundary)',
      sources: () => ranksOf(
        {
          0: [shared],
          7: ['a', 'b'],
          9: ['c'],
          17: ['d'],
          18: ['e'],
        },
        {
          'a': specFixtureText(),
          'b': specFixtureText(),
          'c': specFixtureText(depends: '`a.md`'),
          'd': specFixtureText(depends: '`c.md`'),
          'e': specFixtureText(depends: '`d.md`'),
        },
      ),
      expected: [],
    ),
    (
      label: 'no rank table while specs exist',
      path: 'unhappy (missing content)',
      sources: () => specFixtureSources({'a': specFixtureText()}),
      expected: ['FR-101 ${_spec(shared)}:1'],
    ),
    (
      label: 'no rank table and no spec is vacuous',
      path: 'unhappy (empty and minimal)',
      sources: () => SourceSet({}),
      expected: [],
    ),
  ]);

  /// Requirement: doc/specs/architecture-guardrails.md FR-091 - in-context
  ///   order is the rank table: two specs of one context need a strictly
  ///   lower rank to list each other, so same-rank peers cannot, and the
  ///   higher-ranked evoker spec may list the wizard spec.
  /// Path: unhappy (rule interaction)
  group('FR-091 in-context order is the rank table', () {
    final ranks = {
      0: [shared],
      17: ['class-a', 'class-b'],
      18: ['class-evoker'],
    };

    /// Requirement: doc/specs/architecture-guardrails.md FR-091 - two specs of
    ///   the same rank cannot list each other, and the Violation is reported
    ///   as FR-101.
    /// Path: unhappy (rule interaction)
    test('a same-rank peer in the same context is flagged as FR-101', () {
      final found = checkSpecRanks(
        ranksOf(ranks, {
          'class-a': specFixtureText(depends: '`class-b.md`'),
          'class-b': specFixtureText(),
          'class-evoker': specFixtureText(),
        }),
      );

      expect(_where(found), ['FR-101 ${_spec('class-a')}$_depends']);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-091 - a spec of a
    ///   higher rank in the same context may list one of a lower rank.
    /// Path: happy
    test('a higher-ranked spec of the same context may list a lower one', () {
      final found = checkSpecRanks(
        ranksOf(ranks, {
          'class-a': specFixtureText(),
          'class-b': specFixtureText(),
          'class-evoker': specFixtureText(depends: '`class-a.md`'),
        }),
      );

      expect(found, isEmpty);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-091 - the lower
    ///   rank may not list the higher one.
    /// Path: unhappy (boundary)
    test('a lower-ranked spec may not list a higher one', () {
      final found = checkSpecRanks(
        ranksOf(ranks, {
          'class-a': specFixtureText(depends: '`class-evoker.md`'),
          'class-b': specFixtureText(),
          'class-evoker': specFixtureText(),
        }),
      );

      expect(_where(found), ['FR-101 ${_spec('class-a')}$_depends']);
    });
  });

  const index = documentationIndexPath;
  _run('FR-102', checkDocumentationIndex, [
    (
      label: 'every spec file has a row',
      path: 'happy',
      sources: () => specFixtureSources(
        {'a': specFixtureText(), '_template': '# T\n'},
        extra: {
          index: indexFixture(['specs/a.md', 'specs/_template.md']),
        },
      ),
      expected: [],
    ),
    (
      label: 'a row for an existing non-spec file',
      path: 'unhappy (false positive)',
      sources: () => specFixtureSources(
        {'a': specFixtureText()},
        extra: {
          index: indexFixture(['specs/a.md', 'rules/testing.md']),
          'doc/rules/testing.md': 'x\n',
        },
      ),
      expected: [],
    ),
    (
      label: 'a spec file with no row is reported at the table header',
      path: 'unhappy (missing content)',
      sources: () => specFixtureSources(
        {'a': specFixtureText(), 'b': specFixtureText()},
        extra: {
          index: indexFixture(['specs/a.md']),
        },
      ),
      expected: ['FR-102 $index:3'],
    ),
    (
      label: 'the template needs a row too',
      path: 'unhappy (missing content)',
      sources: () => specFixtureSources(
        {'a': specFixtureText(), '_template': '# T\n'},
        extra: {
          index: indexFixture(['specs/a.md']),
        },
      ),
      expected: ['FR-102 $index:3'],
    ),
    (
      label: 'a row for a missing file is reported at the row',
      path: 'unhappy (missing content)',
      sources: () => specFixtureSources(
        {'a': specFixtureText()},
        extra: {
          index: indexFixture(['specs/a.md', 'specs/gone.md']),
        },
      ),
      expected: ['FR-102 $index:6'],
    ),
    (
      label: 'a duplicate path',
      path: 'unhappy (state error)',
      sources: () => specFixtureSources(
        {'a': specFixtureText()},
        extra: {
          index: indexFixture(['specs/a.md', 'specs/a.md']),
        },
      ),
      expected: ['FR-102 $index:6'],
    ),
    (
      label: 'another header',
      path: 'unhappy (invalid input)',
      sources: () => specFixtureSources(
        {'a': specFixtureText()},
        extra: {
          index: indexFixture(['specs/a.md']).replaceFirst('File', 'Path'),
        },
      ),
      expected: ['FR-102 $index:3'],
    ),
    (
      label: 'a first cell without backticks',
      path: 'unhappy (invalid input)',
      sources: () => specFixtureSources(
        {'a': specFixtureText()},
        extra: {
          index: indexFixture(['specs/a.md']).replaceAll('`', ''),
        },
      ),
      expected: ['FR-102 $index:3', 'FR-102 $index:5'],
    ),
    (
      label: 'no index at all',
      path: 'unhappy (missing content)',
      sources: () => specFixtureSources({'a': specFixtureText()}),
      expected: ['FR-102 $index:1'],
    ),
    (
      label: 'an index without a table and no spec',
      path: 'unhappy (empty and minimal)',
      sources: () => SourceSet({index: '# Index\n'}),
      expected: [],
    ),
    (
      label: 'an index without a table next to a spec',
      path: 'unhappy (empty and minimal)',
      sources: () => specFixtureSources(
        {'a': specFixtureText()},
        extra: {index: '# Index\n'},
      ),
      expected: ['FR-102 $index:1'],
    ),
  ]);

  /// Requirement: doc/specs/architecture-guardrails.md FR-005 - each id the
  ///   file implements has a violating fixture that yields that id and no
  ///   other.
  /// Path: unhappy (state error)
  group('violating fixtures', () {
    /// Requirement: per case - doc/specs/architecture-guardrails.md FR-005 -
    ///   the registered fixture of each id yields only that id.
    /// Path: per case
    for (final id in specConformanceChecks.keys) {
      test('$id fixture violates', () {
        final fixture = specConformanceViolatingFixtures[id]!();
        final found = specConformanceChecks[id]!(fixture);

        expect(found, isNotEmpty);
        expect(found.map((v) => v.checkId).toSet(), {id});
      });
    }

    /// Requirement: doc/specs/architecture-guardrails.md FR-005 - the checks
    ///   and the fixtures cover the same ids, FR-091 and FR-094 excluded.
    /// Path: unhappy (missing content)
    test('checks and fixtures have the same keys', () {
      expect(
        specConformanceViolatingFixtures.keys.toSet(),
        specConformanceChecks.keys.toSet(),
      );
      expect(specConformanceChecks.keys, [
        'FR-088',
        'FR-089',
        'FR-090',
        'FR-092',
        'FR-096',
        'FR-099',
        'FR-100',
        'FR-101',
        'FR-102',
      ]);
    });
  });

  /// Requirement: doc/specs/architecture-guardrails.md FR-011 - a check gives
  ///   the same output on any order of the files.
  /// Path: unhappy (state error)
  group('determinism', () {
    /// Requirement: doc/specs/architecture-guardrails.md FR-011 - the
    ///   violating fixtures give equal output on a reversed file order.
    /// Path: unhappy (state error)
    test('a reversed SourceSet gives the same violations', () {
      for (final entry in specConformanceChecks.entries) {
        final fixture = specConformanceViolatingFixtures[entry.key]!();
        final reversed = SourceSet({
          for (final key in fixture.files.keys.toList().reversed)
            key: fixture.files[key]!,
        });

        expect(
          entry.value(reversed).map((v) => v.toString()).toList(),
          entry.value(fixture).map((v) => v.toString()).toList(),
          reason: entry.key,
        );
      }
    });
  });
}
