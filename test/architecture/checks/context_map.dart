import '../support/constants.dart';
import '../support/context_map.dart';
import '../support/source_set.dart';
import '../support/violation.dart';

/// Context map checks FR-020, FR-021, FR-022 and FR-098 of
/// `doc/specs/architecture-guardrails.md` (section 4.2).
///
/// Every function is pure: it reads a [SourceSet] and returns [Violation]s.
/// The map is parsed from the table in `doc/rules/architecture.md` section 2
/// and never copied (FR-022).

/// FR-022: the context map is the table of `architecture.md` section 2 in the
/// format the spec fixes, and the `AGENTS.md` "Current contexts" list names
/// exactly the same contexts.
List<Violation> checkContextMapFormat(SourceSet sources) {
  const id = 'FR-022';
  final map = ContextMap.parse(sources);
  final violations = <Violation>[
    for (final problem in map.problems)
      Violation(
        checkId: id,
        path: problem.path,
        line: problem.line,
        detail: problem.detail,
      ),
  ];
  // The two lists can only be compared when both were read.
  if (map.tableFound && map.agentsListLine != null) {
    final inAgents = {for (final c in map.agentsContexts) c.name};
    for (final row in map.rows) {
      if (!inAgents.contains(row.name)) {
        violations.add(
          Violation(
            checkId: id,
            path: agentsPath,
            line: map.agentsListLine!,
            detail:
                'the context `${row.name}` is in the table of '
                '$architectureRulesPath but not in the "Current contexts" '
                'list',
          ),
        );
      }
    }
    final inMap = map.contexts.toSet();
    final reported = <String>{};
    for (final entry in map.agentsContexts) {
      if (!inMap.contains(entry.name) || !reported.add(entry.name)) {
        violations.add(
          Violation(
            checkId: id,
            path: agentsPath,
            line: entry.line,
            detail: inMap.contains(entry.name)
                ? 'the context `${entry.name}` is listed twice'
                : 'the context `${entry.name}` is in the "Current contexts" '
                      'list but not in the table of $architectureRulesPath',
          ),
        );
      }
    }
  }
  return sortedViolations(violations);
}

/// FR-020: the context map is acyclic, and a self-edge is a cycle. One
/// Violation per cycle, naming the contexts on it.
List<Violation> checkContextMapAcyclic(SourceSet sources) {
  final map = ContextMap.parse(sources);
  return sortedViolations([
    for (final cycle in map.cycles())
      Violation(
        checkId: 'FR-020',
        path: architectureRulesPath,
        line: map.rowOf(cycle.first)!.line,
        detail: 'the context map has a cycle: ${cycle.join(' -> ')}',
      ),
  ]);
}

/// FR-021: every folder directly under `lib/src/` other than the three
/// non-context folders is a context of the map, and no loose `.dart` file
/// sits directly in `lib/src/`. A map entry with no folder is allowed.
///
/// Nothing is reported for an unmapped folder when the map itself could not
/// be read; FR-022 reports that.
List<Violation> checkContextFolders(SourceSet sources) {
  const id = 'FR-021';
  final map = ContextMap.parse(sources);
  final violations = <Violation>[];
  final mapped = map.contexts.toSet();
  final reportedFolders = <String>{};
  for (final path in sources.paths(prefix: 'lib/src/')) {
    final rest = path.substring('lib/src/'.length);
    if (!rest.contains('/')) {
      if (path.endsWith('.dart')) {
        violations.add(
          Violation(
            checkId: id,
            path: path,
            line: 1,
            detail:
                'a loose .dart file directly in lib/src/; put it in '
                'shared_kernel/, shared_ports/, testing/ or a context',
          ),
        );
      }
      continue;
    }
    final folder = rest.split('/').first;
    if (isNonContextFolder(folder) || !map.tableFound) continue;
    if (!mapped.contains(folder) && reportedFolders.add(folder)) {
      violations.add(
        Violation(
          checkId: id,
          path: path,
          line: 1,
          detail:
              'the folder lib/src/$folder/ is not a context in the map of '
              '$architectureRulesPath; add a row there or move the files',
        ),
      );
    }
  }
  return sortedViolations(violations);
}

/// FR-098: the shape of the map for the leaf contexts in [leafContexts].
/// (a) No context lists a leaf as upstream. (b) A leaf present in the map
/// lists only contexts that are in the map. Part (c), the import legality of
/// the leaf's files, is FR-018 and FR-019.
List<Violation> checkLeafContexts(SourceSet sources) {
  const id = 'FR-098';
  final map = ContextMap.parse(sources);
  final known = map.contexts.toSet();
  final violations = <Violation>[];
  for (final row in map.rows) {
    for (final up in row.upstream) {
      if (leafContexts.contains(up)) {
        violations.add(
          Violation(
            checkId: id,
            path: architectureRulesPath,
            line: row.line,
            detail:
                '`${row.name}` lists the leaf context `$up` as upstream; '
                'nothing may depend on `$up`',
          ),
        );
      }
    }
    if (leafContexts.contains(row.name)) {
      for (final up in row.upstream) {
        if (!known.contains(up)) {
          violations.add(
            Violation(
              checkId: id,
              path: architectureRulesPath,
              line: row.line,
              detail:
                  'the leaf context `${row.name}` lists `$up`, which is not '
                  'a context in the map',
            ),
          );
        }
      }
    }
  }
  return sortedViolations(violations);
}

/// FR-020, FR-021, FR-022 and FR-098 together, sorted.
List<Violation> checkContextMap(SourceSet sources) => sortedViolations([
  ...checkContextMapAcyclic(sources),
  ...checkContextFolders(sources),
  ...checkContextMapFormat(sources),
  ...checkLeafContexts(sources),
]);

/// The check function per id, for the registry (`registry.dart`).
const Map<String, List<Violation> Function(SourceSet)> contextMapChecks = {
  'FR-020': checkContextMapAcyclic,
  'FR-021': checkContextFolders,
  'FR-022': checkContextMapFormat,
  'FR-098': checkLeafContexts,
};

/// A context map table in the `architecture.md` format for fixtures: one row
/// per entry of [upstreamByContext] (an empty list is written `none`).
///
/// The header sits on line 7, so row `i` is on line `9 + i`.
String contextMapFixtureArchitecture(
  Map<String, List<String>> upstreamByContext,
) {
  final rows = [
    for (final entry in upstreamByContext.entries)
      '| `${entry.key}` | purpose | '
          '${entry.value.isEmpty ? 'none' : entry.value.map((u) => '`$u`').join(', ')}'
          ' |',
  ];
  return [
    '# Rules',
    '',
    '## 2. Bounded contexts',
    '',
    '### Context map',
    '',
    '| Context | Purpose | May depend on (upstream) |',
    '|---|---|---|',
    ...rows,
    '',
  ].join('\n');
}

/// An `AGENTS.md` "Current contexts" list for fixtures naming [contexts].
///
/// The paragraph is on line 3, so item `i` is on line `6 + i`.
String contextMapFixtureAgents(Iterable<String> contexts) => [
  '# Rules',
  '',
  'Current contexts (provisional).',
  'More text.',
  '',
  for (final c in contexts) '- `$c/`: purpose',
  '',
  'Update this section.',
  '',
].join('\n');

/// A source set holding a map of [upstreamByContext] and the matching
/// `AGENTS.md` list, plus [extra] files.
SourceSet contextMapFixtureSources(
  Map<String, List<String>> upstreamByContext, {
  Map<String, String> extra = const {},
}) => SourceSet({
  architectureRulesPath: contextMapFixtureArchitecture(upstreamByContext),
  agentsPath: contextMapFixtureAgents(upstreamByContext.keys),
  ...extra,
});

/// One minimal violating fixture per check id; the registry merges this map
/// into its own (`registry.dart`, FR-005).
final Map<String, SourceSet Function()> contextMapViolatingFixtures = {
  'FR-020': () => contextMapFixtureSources({
    'a': ['b'],
    'b': ['a'],
  }),
  'FR-021': () => contextMapFixtureSources(
    {'a': []},
    extra: {'lib/src/ghost/ghost.dart': ''},
  ),
  'FR-022': () => SourceSet({
    architectureRulesPath: '# Rules\n',
    agentsPath: contextMapFixtureAgents(['a']),
  }),
  'FR-098': () => contextMapFixtureSources({
    'character': ['toolbox'],
    'toolbox': [],
  }),
};
