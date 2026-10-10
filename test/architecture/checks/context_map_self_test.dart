import 'package:test/test.dart';

import '../support/context_map.dart';
import '../support/source_set.dart';
import '../support/violation.dart';
import 'context_map.dart';

const String _arch = architectureRulesPath;

typedef _Case = ({
  String label,
  String requirement,
  String path,
  SourceSet sources,
  List<String> expected,
});

List<String> _where(List<Violation> violations) => [
  for (final v in violations) '${v.checkId} ${v.path}:${v.line}',
];

/// The map of `architecture.md` section 2, as the fixtures spell it.
const Map<String, List<String>> _realShape = {
  'content': [],
  'd20_test': [],
  'character': ['content', 'd20_test'],
  'combat': ['character', 'd20_test', 'content'],
  'toolbox': ['content', 'd20_test', 'character', 'combat'],
};

SourceSet _map(
  Map<String, List<String>> map, {
  Map<String, String> extra = const {},
}) => contextMapFixtureSources(map, extra: extra);

SourceSet _files(Map<String, String> files) => SourceSet(files);

const String _fr020 = 'doc/specs/architecture-guardrails.md FR-020';
const String _fr021 = 'doc/specs/architecture-guardrails.md FR-021';
const String _fr022 = 'doc/specs/architecture-guardrails.md FR-022';
const String _fr098 = 'doc/specs/architecture-guardrails.md FR-098';

/// A table with the map header but another third column, under the heading.
const String _otherHeader =
    '# Rules\n\n## 2. Bounded contexts\n\n### Context map\n\n'
    '| Context | Purpose | Depends on |\n|---|---|---|\n'
    '| `a` | p | none |\n';

String _withRow(String row) =>
    '# Rules\n\n## 2. Bounded contexts\n\n### Context map\n\n'
    '| Context | Purpose | May depend on (upstream) |\n|---|---|---|\n'
    '| `a` | p | none |\n$row\n';

final List<_Case> _fr020Cases = [
  (
    label: 'A to B to A',
    requirement: _fr020,
    path: 'unhappy (invalid input)',
    sources: _map({
      'a': ['b'],
      'b': ['a'],
    }),
    expected: ['FR-020 $_arch:9'],
  ),
  (
    label: 'a self-edge',
    requirement: _fr020,
    path: 'unhappy (boundary)',
    sources: _map({
      'a': ['a'],
    }),
    expected: ['FR-020 $_arch:9'],
  ),
  (
    label: 'a three-cycle, reported once at its first context in table order',
    requirement: _fr020,
    path: 'unhappy (invalid input)',
    sources: _map({
      'z': ['a'],
      'a': ['b'],
      'b': ['c'],
      'c': ['a'],
    }),
    expected: ['FR-020 $_arch:10'],
  ),
  (
    label: 'content listing toolbox upstream, toolbox listing content',
    requirement: _fr020,
    path: 'unhappy (rule interaction)',
    sources: _map({
      'content': ['toolbox'],
      'toolbox': ['content'],
    }),
    expected: ['FR-020 $_arch:9'],
  ),
  (
    label: 'two separate cycles are two Violations',
    requirement: _fr020,
    path: 'unhappy (multiple violations)',
    sources: _map({
      'a': ['b'],
      'b': ['a'],
      'c': ['c'],
    }),
    expected: ['FR-020 $_arch:9', 'FR-020 $_arch:11'],
  ),
  (
    label: 'the map of architecture.md section 2 is acyclic',
    requirement: _fr020,
    path: 'happy',
    sources: _map(_realShape),
    expected: [],
  ),
  (
    label: 'an upstream name with no row cannot close a cycle',
    requirement: _fr020,
    path: 'unhappy (boundary)',
    sources: _map({
      'a': ['ghost'],
    }),
    expected: [],
  ),
  (
    label: 'no map at all has no cycle (FR-022 reports the missing table)',
    requirement: _fr020,
    path: 'unhappy (empty and minimal)',
    sources: _files({}),
    expected: [],
  ),
];

final List<_Case> _fr021Cases = [
  (
    label: 'a folder under lib/src/ that is not in the map',
    requirement: _fr021,
    path: 'unhappy (missing content)',
    sources: _map(
      {'a': []},
      extra: {
        'lib/src/ghost/ghost.dart': '',
        'lib/src/ghost/domain/x.dart': '',
      },
    ),
    expected: ['FR-021 lib/src/ghost/domain/x.dart:1'],
  ),
  (
    label: 'a loose .dart file directly in lib/src/',
    requirement: _fr021,
    path: 'unhappy (missing content)',
    sources: _map({'a': []}, extra: {'lib/src/loose.dart': ''}),
    expected: ['FR-021 lib/src/loose.dart:1'],
  ),
  (
    label: 'an unmapped folder and a loose file are two Violations',
    requirement: _fr021,
    path: 'unhappy (multiple violations)',
    sources: _map(
      {'a': []},
      extra: {'lib/src/ghost/x.dart': '', 'lib/src/loose.dart': ''},
    ),
    expected: ['FR-021 lib/src/ghost/x.dart:1', 'FR-021 lib/src/loose.dart:1'],
  ),
  (
    label: 'a toolbox folder with toolbox in the map',
    requirement: _fr021,
    path: 'happy',
    sources: _map(_realShape, extra: {'lib/src/toolbox/toolbox.dart': ''}),
    expected: [],
  ),
  (
    label: 'a planned context with no folder is allowed',
    requirement: _fr021,
    path: 'happy',
    sources: _map(_realShape, extra: {'lib/src/content/content.dart': ''}),
    expected: [],
  ),
  (
    label: 'testing, shared_kernel and shared_ports are not contexts',
    requirement: _fr021,
    path: 'unhappy (boundary)',
    sources: _map(
      {'a': []},
      extra: {
        'lib/src/testing/x.dart': '',
        'lib/src/shared_kernel/x.dart': '',
        'lib/src/shared_ports/adapters/x.dart': '',
      },
    ),
    expected: [],
  ),
  (
    label: 'a loose non-Dart file in lib/src/ is not flagged',
    requirement: _fr021,
    path: 'unhappy (boundary)',
    sources: _map({'a': []}, extra: {'lib/src/notes.md': ''}),
    expected: [],
  ),
  (
    label: 'folders are not reported when the map cannot be read',
    requirement: _fr021,
    path: 'unhappy (state error)',
    sources: _files({'lib/src/ghost/x.dart': ''}),
    expected: [],
  ),
  (
    label: 'a loose file is reported even when the map cannot be read',
    requirement: _fr021,
    path: 'unhappy (state error)',
    sources: _files({'lib/src/loose.dart': ''}),
    expected: ['FR-021 lib/src/loose.dart:1'],
  ),
];

final List<_Case> _fr022Cases = [
  (
    label: 'a table with another header',
    requirement: _fr022,
    path: 'unhappy (state error)',
    sources: _files({
      _arch: _otherHeader,
      agentsPath: contextMapFixtureAgents(['a']),
    }),
    expected: ['FR-022 $_arch:7'],
  ),
  (
    label: 'no table at all',
    requirement: _fr022,
    path: 'unhappy (missing content)',
    sources: _files({
      _arch: '# Rules\n',
      agentsPath: contextMapFixtureAgents(['a']),
    }),
    expected: ['FR-022 $_arch:1'],
  ),
  (
    label: 'a context cell without backticks',
    requirement: _fr022,
    path: 'unhappy (invalid input)',
    sources: _files({
      _arch: _withRow('| b | p | none |'),
      agentsPath: contextMapFixtureAgents(['a']),
    }),
    expected: ['FR-022 $_arch:10'],
  ),
  (
    label: 'an upstream cell with a name without backticks',
    requirement: _fr022,
    path: 'unhappy (invalid input)',
    sources: _files({
      _arch: _withRow('| `b` | p | a |'),
      agentsPath: contextMapFixtureAgents(['a', 'b']),
    }),
    expected: ['FR-022 $_arch:10'],
  ),
  (
    label: 'a context in AGENTS.md missing from the table',
    requirement: _fr022,
    path: 'unhappy (state error)',
    sources: _files({
      _arch: contextMapFixtureArchitecture({'a': []}),
      agentsPath: contextMapFixtureAgents(['a', 'b']),
    }),
    expected: ['FR-022 $agentsPath:7'],
  ),
  (
    label: 'a context of the table missing from AGENTS.md',
    requirement: _fr022,
    path: 'unhappy (state error)',
    sources: _files({
      _arch: contextMapFixtureArchitecture({'a': [], 'b': []}),
      agentsPath: contextMapFixtureAgents(['a']),
    }),
    expected: ['FR-022 $agentsPath:3'],
  ),
  (
    label: 'a context listed twice in AGENTS.md',
    requirement: _fr022,
    path: 'unhappy (invalid input)',
    sources: _files({
      _arch: contextMapFixtureArchitecture({'a': []}),
      agentsPath: contextMapFixtureAgents(['a', 'a']),
    }),
    expected: ['FR-022 $agentsPath:7'],
  ),
  (
    label: 'AGENTS.md without a Current contexts paragraph',
    requirement: _fr022,
    path: 'unhappy (missing content)',
    sources: _files({
      _arch: contextMapFixtureArchitecture({'a': []}),
      agentsPath: '# Rules\n',
    }),
    expected: ['FR-022 $agentsPath:1'],
  ),
  (
    label: 'both files missing',
    requirement: _fr022,
    path: 'unhappy (empty and minimal)',
    sources: _files({}),
    expected: ['FR-022 $agentsPath:1', 'FR-022 $_arch:1'],
  ),
  (
    label: 'a comment next to a row does not change the result',
    requirement: 'doc/specs/architecture-guardrails.md FR-009, FR-022',
    path: 'unhappy (rule interaction)',
    sources: _files({
      _arch: _withRow('| b | p // ignore: FR-022 | none |'),
      agentsPath: contextMapFixtureAgents(['a']),
    }),
    expected: ['FR-022 $_arch:10'],
  ),
  (
    label: 'matching table and list',
    requirement: _fr022,
    path: 'happy',
    sources: _map(_realShape),
    expected: [],
  ),
];

final List<_Case> _fr098Cases = [
  (
    label: 'toolbox with four upstreams and nobody listing it',
    requirement: _fr098,
    path: 'happy',
    sources: _map(_realShape),
    expected: [],
  ),
  (
    label: 'character lists toolbox',
    requirement: _fr098,
    path: 'unhappy (rule interaction)',
    sources: _map({
      'character': ['toolbox'],
      'toolbox': [],
    }),
    expected: ['FR-098 $_arch:9'],
  ),
  (
    label: 'toolbox lists an unknown context',
    requirement: _fr098,
    path: 'unhappy (invalid input)',
    sources: _map({
      'content': [],
      'toolbox': ['content', 'ghost'],
    }),
    expected: ['FR-098 $_arch:10'],
  ),
  (
    label: 'toolbox lists itself (FR-020 fires too)',
    requirement: _fr098,
    path: 'unhappy (rule interaction)',
    sources: _map({
      'toolbox': ['toolbox'],
    }),
    expected: ['FR-098 $_arch:9'],
  ),
  (
    label: 'two contexts list toolbox',
    requirement: _fr098,
    path: 'unhappy (multiple violations)',
    sources: _map({
      'content': ['toolbox'],
      'combat': ['toolbox'],
      'toolbox': [],
    }),
    expected: ['FR-098 $_arch:9', 'FR-098 $_arch:10'],
  ),
  (
    label: 'no toolbox in the map is vacuous',
    requirement: _fr098,
    path: 'unhappy (empty and minimal)',
    sources: _map({
      'content': [],
      'combat': ['content'],
    }),
    expected: [],
  ),
  (
    label: 'a context that is not a leaf may list an unknown name',
    requirement: _fr098,
    path: 'unhappy (boundary)',
    sources: _map({
      'combat': ['ghost'],
    }),
    expected: [],
  ),
  (
    label: 'listing a leaf that has no row is still a Violation',
    requirement: _fr098,
    path: 'unhappy (boundary)',
    sources: _map({
      'combat': ['toolbox'],
    }),
    expected: ['FR-098 $_arch:9'],
  ),
];

void _run(
  String title,
  List<_Case> cases,
  List<Violation> Function(SourceSet) check,
) {
  /// Requirement: per case
  /// Path: per case
  group(title, () {
    for (final c in cases) {
      test('${c.label} [${c.path}] (${c.requirement})', () {
        expect(_where(check(c.sources)), c.expected);
      });
    }
  });
}

void main() {
  // Requirement: doc/specs/architecture-guardrails.md FR-020 - the map is
  //   acyclic, a self-edge counts, a Violation names the contexts.
  // Path: per case
  _run('FR-020 cycles', _fr020Cases, checkContextMapAcyclic);

  // Requirement: doc/specs/architecture-guardrails.md FR-021 - every folder
  //   under lib/src/ is a context or a non-context folder, no loose file.
  // Path: per case
  _run('FR-021 context folders', _fr021Cases, checkContextFolders);

  // Requirement: doc/specs/architecture-guardrails.md FR-022 - the map is
  //   parsed from the table and AGENTS.md names the same contexts.
  // Path: per case
  _run('FR-022 map format', _fr022Cases, checkContextMapFormat);

  // Requirement: doc/specs/architecture-guardrails.md FR-098 - nothing
  //   depends on a leaf context, and a leaf lists only known contexts.
  // Path: per case
  _run('FR-098 leaf contexts', _fr098Cases, checkLeafContexts);

  /// Requirement: doc/specs/architecture-guardrails.md FR-020, FR-098 - the
  ///   combined check reports both ids for a leaf that lists itself.
  /// Path: unhappy (rule interaction)
  test('toolbox listing itself breaks FR-020 and FR-098 together', () {
    final found = checkContextMap(
      _map({
        'toolbox': ['toolbox'],
      }),
    );

    expect(_where(found), ['FR-020 $_arch:9', 'FR-098 $_arch:9']);
    expect(
      found.first.detail,
      contains('toolbox -> toolbox'),
      reason: 'the cycle names its contexts',
    );
  });

  /// Requirement: doc/specs/architecture-guardrails.md FR-004, FR-011 - every
  ///   violation is reported, sorted by path, line and id.
  /// Path: unhappy (multiple violations)
  test('the combined check reports every violation, sorted', () {
    final found = checkContextMap(
      _map(
        {
          'a': ['b'],
          'b': ['a'],
        },
        extra: {'lib/src/ghost/x.dart': '', 'lib/src/loose.dart': ''},
      ),
    );

    expect(_where(found), [
      'FR-020 $_arch:9',
      'FR-021 lib/src/ghost/x.dart:1',
      'FR-021 lib/src/loose.dart:1',
    ]);
  });

  /// Requirement: doc/specs/architecture-guardrails.md FR-005 - each id has a
  ///   violating fixture on which its registered function yields that id.
  /// Path: unhappy (failure)
  group('registry wiring', () {
    for (final id in contextMapChecks.keys) {
      /// Requirement: doc/specs/architecture-guardrails.md FR-005 - the
      ///   fixture for the id yields a Violation with that id.
      /// Path: unhappy (failure)
      test('$id has a violating fixture', () {
        final fixture = contextMapViolatingFixtures[id];

        expect(fixture, isNotNull);
        final found = contextMapChecks[id]!(fixture!());
        expect(found.map((v) => v.checkId), contains(id));
      });
    }

    /// Requirement: doc/specs/architecture-guardrails.md FR-005 - fixtures and
    ///   functions cover the same ids.
    /// Path: unhappy (failure)
    test('fixtures and checks name the same ids', () {
      expect(
        contextMapViolatingFixtures.keys.toSet(),
        contextMapChecks.keys.toSet(),
      );
      expect(contextMapChecks.keys.toSet(), {
        'FR-020',
        'FR-021',
        'FR-022',
        'FR-098',
      });
    });
  });
}
