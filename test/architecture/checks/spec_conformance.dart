import '../support/constants.dart';
import '../support/context_map.dart';
import '../support/markdown_tables.dart';
import '../support/rank_table.dart';
import '../support/source_set.dart';
import '../support/spec_header.dart';
import '../support/spec_ids.dart';
import '../support/violation.dart';
import 'context_map.dart'
    show contextMapFixtureAgents, contextMapFixtureArchitecture;
import 'test_citations.dart' show specFilePaths;

/// Specification checks FR-088 to FR-092, FR-096 and FR-099 to FR-102 of
/// `doc/specs/architecture-guardrails.md` (section 4.7).
///
/// Every function is pure: it reads a [SourceSet] and returns [Violation]s.
/// FR-091 restates FR-101 and reports as FR-101; FR-094 is the header parse
/// of `support/spec_header.dart`, a support rule that yields no Violation of
/// its own.

const String _specsPrefix = 'doc/specs/';

/// The ten level-2 headings of the spec template, in order (FR-088).
const List<String> templateHeadings = [
  '1. Purpose and scope',
  '2. Source',
  '3. Vocabulary',
  '4. Requirements',
  '5. Model',
  '6. Interface',
  '7. Observability',
  '8. Test plan',
  '9. Open questions and decisions',
  '10. Changelog impact',
];

/// The rows every spec header table must have (FR-088).
const List<String> requiredHeaderRows = [
  'Status',
  'Context',
  'Roadmap phase',
  'Depends on',
];

/// The Context values that are not bounded contexts (FR-088).
const Set<String> nonContextSpecContexts = {
  'package',
  'shared_kernel',
  'shared_ports',
  'testing',
};

/// The only specs outside `package` that a content data spec may list
/// (FR-099). File stems.
const Set<String> dataSpecAllowedDependencies = {
  'content-schema-and-decoder',
  'content-source-port',
};

/// The spec every spec may list without naming it, at rank 0 (FR-101).
const String decisionsSpecFile = 'shared-types-and-ownership.md';

final class _Spec {
  _Spec(this.path, this.text)
    : name = path.substring(_specsPrefix.length, path.length - 3),
      header = SpecHeader.parse(text);

  final String path;
  final String name;
  final String text;
  final SpecHeader header;
}

final Expando<List<_Spec>> _specCache = Expando<List<_Spec>>();

List<_Spec> _specsOf(SourceSet sources) => _specCache[sources] ??= [
  for (final path in specFilePaths(sources)) _Spec(path, sources.files[path]!),
];

Map<String, _Spec> _byName(SourceSet sources) => {
  for (final spec in _specsOf(sources)) spec.name: spec,
};

/// The requirement ids of a spec: every id row of a table that sits in
/// section 4, that is, between the `## 4.` heading and the next level-2
/// heading, whatever its sub-heading is called (FR-071).
final class _Requirements {
  _Requirements(this.ids, this.movedIds);

  factory _Requirements.parse(String markdown) {
    final headings = level2Headings(markdown);
    var start = -1;
    var end = 1 << 30;
    for (var i = 0; i < headings.length; i++) {
      if (RegExp(r'^4\.?(\s|$)').hasMatch(headings[i].text)) {
        start = headings[i].line;
        end = i + 1 < headings.length ? headings[i + 1].line : end;
        break;
      }
    }
    final ids = <String>{};
    final moved = <String>{};
    for (final table in parseMarkdownTables(markdown)) {
      if (table.headerLine <= start || table.headerLine >= end) continue;
      for (final row in table.rows) {
        final first = row.cell(0);
        if (first == null || !requirementIdPattern.hasMatch(first)) continue;
        ids.add(first);
        if (isMovedIdRow(row)) moved.add(first);
      }
    }
    // An id is moved when any of its rows says so and no live row defines it.
    return _Requirements(ids, moved);
  }

  final Set<String> ids;
  final Set<String> movedIds;
}

String _stem(String file) => file.substring(0, file.length - 3);

/// FR-088: a spec has the ten template headings in order, a header table with
/// the four rows, and a valid Context.
List<Violation> checkSpecTemplateShape(SourceSet sources) {
  const id = 'FR-088';
  final violations = <Violation>[];
  final contexts = {
    ...nonContextSpecContexts,
    ...ContextMap.parse(sources).contexts,
  };
  for (final spec in _specsOf(sources)) {
    void add(int line, String detail) => violations.add(
      Violation(checkId: id, path: spec.path, line: line, detail: detail),
    );

    final headings = level2Headings(spec.text);
    var reported = false;
    for (var i = 0; i < headings.length && !reported; i++) {
      if (i >= templateHeadings.length) {
        add(
          headings[i].line,
          'Unexpected level-2 heading "${headings[i].text}"; a spec has '
          'exactly the ten template headings.',
        );
        reported = true;
      } else if (headings[i].text != templateHeadings[i]) {
        add(
          headings[i].line,
          'Level-2 heading "${headings[i].text}" where '
          '"${templateHeadings[i]}" is required, in order.',
        );
        reported = true;
      }
    }
    if (!reported && headings.length < templateHeadings.length) {
      add(
        headings.isEmpty ? 1 : headings.last.line,
        'Missing level-2 heading "${templateHeadings[headings.length]}".',
      );
    }

    final header = spec.header;
    if (!header.tableFound) {
      add(1, 'No header table with ${requiredHeaderRows.join(', ')}.');
      continue;
    }
    for (final row in requiredHeaderRows) {
      if (!header.rows.containsKey(row)) {
        add(header.tableLine, 'The header table has no "$row" row.');
      }
    }
    if (header.rows.containsKey('Context')) {
      final context = header.context;
      if (context == null) {
        add(header.contextLine, 'Context must be one backticked token.');
      } else if (!contexts.contains(context)) {
        add(
          header.contextLine,
          'Context `$context` is not package, shared_kernel, shared_ports, '
          'testing or a context of the map.',
        );
      }
    }
  }
  return sortedViolations(violations);
}

/// FR-089: every dependency exists, is not the spec itself, and the graph of
/// dependencies is acyclic.
List<Violation> checkSpecDependenciesResolve(SourceSet sources) {
  const id = 'FR-089';
  final violations = <Violation>[];
  final specs = _byName(sources);
  final edges = <String, List<String>>{};
  for (final spec in specs.values) {
    final line = spec.header.dependsLine;
    final targets = <String>[];
    for (final file in spec.header.dependsOn) {
      final target = _stem(file);
      if (target == spec.name) {
        violations.add(
          Violation(
            checkId: id,
            path: spec.path,
            line: line,
            detail: 'Depends on lists the spec itself ($file).',
          ),
        );
      } else if (!specs.containsKey(target)) {
        violations.add(
          Violation(
            checkId: id,
            path: spec.path,
            line: line,
            detail: 'Depends on lists $file, which is not in doc/specs/.',
          ),
        );
      } else if (!targets.contains(target)) {
        targets.add(target);
      }
    }
    edges[spec.name] = targets;
  }

  // Tarjan's algorithm over the existing, non-self edges.
  final names = edges.keys.toList()..sort();
  final index = <String, int>{};
  final low = <String, int>{};
  final onStack = <String>{};
  final stack = <String>[];
  var counter = 0;
  void visit(String name) {
    index[name] = low[name] = counter++;
    stack.add(name);
    onStack.add(name);
    for (final next in edges[name]!) {
      if (!index.containsKey(next)) {
        visit(next);
        low[name] = low[name]! < low[next]! ? low[name]! : low[next]!;
      } else if (onStack.contains(next)) {
        low[name] = low[name]! < index[next]! ? low[name]! : index[next]!;
      }
    }
    if (low[name] != index[name]) return;
    final component = <String>[];
    String member;
    do {
      member = stack.removeLast();
      onStack.remove(member);
      component.add(member);
    } while (member != name);
    if (component.length < 2) return;
    component.sort();
    final first = specs[component.first]!;
    violations.add(
      Violation(
        checkId: id,
        path: first.path,
        line: first.header.dependsLine,
        detail: 'Dependency cycle among: ${component.join(', ')}.',
      ),
    );
  }

  for (final name in names) {
    if (!index.containsKey(name)) visit(name);
  }
  return sortedViolations(violations);
}

/// FR-090: a dependency crosses contexts only along the context map, and the
/// kernel and ports specs list only their own layer.
List<Violation> checkSpecContextEdges(SourceSet sources) {
  const id = 'FR-090';
  final violations = <Violation>[];
  final specs = _byName(sources);
  final map = ContextMap.parse(sources);
  for (final spec in specs.values) {
    final from = spec.header.context;
    if (from == null) continue;
    for (final file in spec.header.dependsOn) {
      final target = specs[_stem(file)];
      final to = target?.header.context;
      if (target == null || to == null || target == spec) continue;
      final problem = _contextEdgeProblem(map, from, to);
      if (problem == null) continue;
      violations.add(
        Violation(
          checkId: id,
          path: spec.path,
          line: spec.header.dependsLine,
          detail:
              'Forbidden edge: $from spec ${spec.name} lists $file '
              '($to): $problem.',
        ),
      );
    }
  }
  return sortedViolations(violations);
}

String? _contextEdgeProblem(ContextMap map, String from, String to) {
  if (to == 'package') return null;
  if (from == 'package' || from == 'testing') return null;
  if (from == 'shared_kernel') {
    return to == 'shared_kernel'
        ? null
        : 'a shared_kernel spec lists only shared_kernel specs';
  }
  if (from == 'shared_ports') {
    return to == 'shared_kernel' || to == 'shared_ports'
        ? null
        : 'a shared_ports spec lists only shared_kernel and shared_ports specs';
  }
  if (!map.hasContext(from)) return null;
  if (to == 'shared_kernel' || to == 'shared_ports' || to == 'testing') {
    return null;
  }
  if (to == from || !map.hasContext(to)) return null;
  return map.mayDependOn(from, to)
      ? null
      : '$to is not upstream of $from in the context map';
}

/// FR-092: a spec lists only specs whose type phase ends at or before its own
/// lowest type phase; a rank-90-or-higher spec is exempt.
List<Violation> checkSpecPhases(SourceSet sources) {
  const id = 'FR-092';
  final violations = <Violation>[];
  final specs = _byName(sources);
  final ranks = RankTable.fromSources(sources).ranks;
  for (final spec in specs.values) {
    final phase = spec.header.phase;
    if (phase == null) {
      violations.add(
        Violation(
          checkId: id,
          path: spec.path,
          line: spec.header.phaseLine,
          detail: 'The Roadmap phase cell has no integer.',
        ),
      );
      continue;
    }
    final rank = ranks[spec.name];
    if (rank != null && rank >= highRankThreshold) continue;
    for (final file in spec.header.dependsOn) {
      final dependencyPhase = specs[_stem(file)]?.header.phase;
      if (dependencyPhase == null || dependencyPhase.high <= phase.low) {
        continue;
      }
      violations.add(
        Violation(
          checkId: id,
          path: spec.path,
          line: spec.header.dependsLine,
          detail:
              '${spec.name} (phase $phase) lists $file (phase '
              '$dependencyPhase), which ships later.',
        ),
      );
    }
  }
  return sortedViolations(violations);
}

final RegExp _citationToken = RegExp(
  r'(?<![A-Za-z0-9_./-])(?:doc/specs/)?([a-z0-9_-]+)\.md(?![A-Za-z0-9_-])',
);
final RegExp _citationId = RegExp(r'FR-(\d+)');
final RegExp _citationSeparator = RegExp(
  r'(?:\s*[,/&]\s*(?:and\s+)?|\s+(?:and|to)\s+)(?=FR-\d)',
);
final RegExp _withdrawnSuffix = RegExp(r'\s*\(withdrawn\)');

/// The mangled-name pattern of FR-096, assembled at run time so no source
/// file spells a mangled name.
final RegExp _mangledName = RegExp(
  '\\b(${['doc', 'specs'].join('-')}|${['tool', 'box'].join()})'
  '-[a-z0-9-]+-md\\b',
);

String _blankFencedBlocks(String text) {
  final out = StringBuffer();
  final lines = text.split('\n');
  final fence = RegExp(r'^ {0,3}(```|~~~)');
  String? open;
  for (var i = 0; i < lines.length; i++) {
    final match = fence.firstMatch(lines[i]);
    final blank = open != null || match != null;
    if (open != null) {
      if (match != null && match.group(1) == open) open = null;
    } else if (match != null) {
      open = match.group(1);
    }
    out.write(blank ? '' : lines[i]);
    if (i < lines.length - 1) out.write('\n');
  }
  return out.toString();
}

int _lineAt(String text, int offset) =>
    1 + '\n'.allMatches(text.substring(0, offset)).length;

bool _isCitationGap(int unit) =>
    unit == 0x60 || // `
    unit == 0x29 || // )
    unit == 0x5D || // ]
    unit == 0x28 || // (
    unit == 0x20 ||
    unit == 0x09 ||
    unit == 0x0A ||
    unit == 0x0D;

/// FR-096: every spec citation names an existing spec and ids of its
/// requirements table, moved ids carry the suffix, mangled names are errors.
List<Violation> checkSpecCitations(SourceSet sources) {
  const id = 'FR-096';
  final violations = <Violation>[];
  final requirements = <String, _Requirements?>{};
  _Requirements? requirementsOf(String name) =>
      requirements.putIfAbsent(name, () {
        final text = sources.files['$_specsPrefix$name.md'];
        return text == null ? null : _Requirements.parse(text);
      });

  for (final spec in _specsOf(sources)) {
    final text = _blankFencedBlocks(spec.text);
    void add(int offset, String detail) => violations.add(
      Violation(
        checkId: id,
        path: spec.path,
        line: _lineAt(text, offset),
        detail: detail,
      ),
    );

    for (final mangled in _mangledName.allMatches(text)) {
      add(
        mangled.start,
        'Mangled spec name "${mangled.group(0)}"; write the file name.',
      );
    }

    for (final token in _citationToken.allMatches(text)) {
      // Inside backticks, as link text or target, or the pointer of a
      // moved-id row (`Withdrawn: moved to <spec>.md (<id>)`).
      final before = text.substring(0, token.start);
      if (!before.endsWith('moved to ') &&
          (token.start == 0 || !'`[('.contains(text[token.start - 1]))) {
        continue;
      }
      var pos = token.end;
      while (pos < text.length && _isCitationGap(text.codeUnitAt(pos))) {
        pos++;
      }
      final first = _citationId.matchAsPrefix(text, pos);
      if (first == null) continue;
      final name = token.group(1)!;
      final ids = [first.group(0)!];
      pos = first.end;
      while (true) {
        final separator = _citationSeparator.matchAsPrefix(text, pos);
        if (separator == null) break;
        final next = _citationId.matchAsPrefix(text, separator.end)!;
        ids.add(next.group(0)!);
        pos = next.end;
      }
      final suffix = _withdrawnSuffix.matchAsPrefix(text, pos) != null;
      if (placeholderSpecNames.contains(name)) continue;
      final target = requirementsOf(name);
      if (target == null) {
        add(token.start, 'Cites $name.md, which is not in doc/specs/.');
        continue;
      }
      for (final cited in ids) {
        if (!target.ids.contains(cited)) {
          add(
            token.start,
            'Cites $cited, which is not in the requirements table of '
            '$name.md.',
          );
        } else if (target.movedIds.contains(cited) && !suffix) {
          add(
            token.start,
            'Cites $cited of $name.md, which moved; follow the citation '
            'with "(withdrawn)" or cite its new home.',
          );
        } else if (suffix && !target.movedIds.contains(cited)) {
          add(
            token.start,
            'Marks $cited of $name.md as "(withdrawn)", but it is not moved.',
          );
        }
      }
    }
  }
  return sortedViolations(violations);
}

/// FR-099: a content data spec lists only the schema, the source port and
/// `package` specs.
List<Violation> checkDataSpecDependencies(SourceSet sources) {
  const id = 'FR-099';
  final violations = <Violation>[];
  final specs = _byName(sources);
  for (final spec in specs.values) {
    if (!dataSpecs.contains(spec.name)) continue;
    for (final file in spec.header.dependsOn) {
      final target = specs[_stem(file)];
      if (target == null) continue;
      if (dataSpecAllowedDependencies.contains(target.name) ||
          target.header.context == 'package') {
        continue;
      }
      violations.add(
        Violation(
          checkId: id,
          path: spec.path,
          line: spec.header.dependsLine,
          detail:
              'Data spec ${spec.name} lists $file, which is neither the '
              'schema, the source port nor a package spec.',
        ),
      );
    }
  }
  return sortedViolations(violations);
}

/// FR-100: the Depends on cell holds only `name.md` tokens, or `none`.
List<Violation> checkDependsOnTokensOnly(SourceSet sources) {
  const id = 'FR-100';
  final violations = <Violation>[];
  for (final spec in _specsOf(sources)) {
    final leftover = spec.header.dependsLeftover;
    if (leftover == null || leftover.isEmpty) continue;
    violations.add(
      Violation(
        checkId: id,
        path: spec.path,
        line: spec.header.dependsLine,
        detail:
            'Depends on holds text that is not a `name.md` token: '
            '"$leftover".',
      ),
    );
  }
  return sortedViolations(violations);
}

/// FR-101 (and FR-091): every spec has a rank, every dependency of a spec
/// below the high-rank threshold has a strictly lower rank.
List<Violation> checkSpecRanks(SourceSet sources) {
  const id = 'FR-101';
  final violations = <Violation>[];
  final specs = _byName(sources);
  final table = RankTable.fromSources(sources);
  if (!table.tableFound) {
    if (specs.isNotEmpty) {
      violations.add(
        const Violation(
          checkId: id,
          path: rankTableSpecPath,
          line: 1,
          detail:
              'No table with a "Rank" header under section 4.11; ranks '
              'cannot be checked.',
        ),
      );
    }
    return violations;
  }
  final ranks = table.ranks;
  for (final entry in table.duplicates) {
    violations.add(
      Violation(
        checkId: id,
        path: rankTableSpecPath,
        line: entry.line,
        detail:
            '${entry.name} is listed under two ranks (${ranks[entry.name]} '
            'and ${entry.rank}).',
      ),
    );
  }
  for (final entry in table.entries) {
    if (specs.containsKey(entry.name)) continue;
    violations.add(
      Violation(
        checkId: id,
        path: rankTableSpecPath,
        line: entry.line,
        detail: 'The rank table lists ${entry.name}, which has no spec file.',
      ),
    );
  }
  for (final spec in specs.values) {
    final rank = ranks[spec.name];
    if (rank == null) {
      violations.add(
        Violation(
          checkId: id,
          path: spec.path,
          line: 1,
          detail:
              '${spec.name} has no rank; add it to the table in section 4.11 '
              'of $rankTableSpecPath.',
        ),
      );
      continue;
    }
    if (rank >= highRankThreshold) continue;
    for (final file in spec.header.dependsOn) {
      if (file == decisionsSpecFile) continue;
      final dependencyRank = ranks[_stem(file)];
      if (dependencyRank == null || dependencyRank < rank) continue;
      violations.add(
        Violation(
          checkId: id,
          path: spec.path,
          line: spec.header.dependsLine,
          detail:
              '${spec.name} (rank $rank) lists $file (rank $dependencyRank); '
              'a dependency needs a strictly lower rank.',
        ),
      );
    }
  }
  return sortedViolations(violations);
}

const List<String> _indexHeader = ['File', 'Summary', 'Read when'];
final RegExp _indexPathCell = RegExp(r'^`([^`\s]+)`$');

/// FR-102: the documentation index has a valid row for every spec and no row
/// for a file that does not exist.
List<Violation> checkDocumentationIndex(SourceSet sources) {
  const id = 'FR-102';
  const path = documentationIndexPath;
  Violation at(int line, String detail) =>
      Violation(checkId: id, path: path, line: line, detail: detail);

  final text = sources.files[path];
  if (text == null) {
    return [at(1, 'The documentation index is missing.')];
  }
  final specFiles = sources.paths(prefix: _specsPrefix, suffix: '.md')
    ..removeWhere((p) => p.substring(_specsPrefix.length).contains('/'));
  final tables = parseMarkdownTables(text);
  if (tables.isEmpty) {
    // An index with no table is only a defect once there is a file to list.
    return specFiles.isEmpty
        ? const []
        : [
            at(
              1,
              'The index has no table with the File, Summary, Read when '
              'header.',
            ),
          ];
  }
  final table = tables.first;
  if (table.header.length != _indexHeader.length ||
      [
        for (var i = 0; i < _indexHeader.length; i++)
          if (table.header[i] != _indexHeader[i]) i,
      ].isNotEmpty) {
    return [
      at(
        table.headerLine,
        'The index header is "${table.header.join(' | ')}"; it must be '
        '${_indexHeader.join(' | ')}.',
      ),
    ];
  }
  final violations = <Violation>[];
  final listed = <String>{};
  final existing = {...sources.files.keys, ...sources.binaryPaths};
  for (final row in table.rows) {
    final match = _indexPathCell.firstMatch(row.cell(0) ?? '');
    if (match == null) {
      violations.add(
        at(row.line, 'The first cell must be one backticked path.'),
      );
      continue;
    }
    final relative = match.group(1)!;
    if (!listed.add(relative)) {
      violations.add(at(row.line, 'The path $relative is listed twice.'));
      continue;
    }
    if (!existing.contains('doc/$relative')) {
      violations.add(
        at(row.line, 'The row names doc/$relative, which does not exist.'),
      );
    }
  }
  for (final file in specFiles) {
    final relative = file.substring('doc/'.length);
    if (listed.contains(relative)) continue;
    violations.add(
      at(table.headerLine, 'The index has no row for `$relative`.'),
    );
  }
  return sortedViolations(violations);
}

/// The check function per id, for the registry (`registry.dart`, FR-005).
/// FR-091 reports as FR-101 and FR-094 is a support rule: neither is a key.
const Map<String, List<Violation> Function(SourceSet)> specConformanceChecks = {
  'FR-088': checkSpecTemplateShape,
  'FR-089': checkSpecDependenciesResolve,
  'FR-090': checkSpecContextEdges,
  'FR-092': checkSpecPhases,
  'FR-096': checkSpecCitations,
  'FR-099': checkDataSpecDependencies,
  'FR-100': checkDependsOnTokensOnly,
  'FR-101': checkSpecRanks,
  'FR-102': checkDocumentationIndex,
};

// ---------------------------------------------------------------------------
// Fixture builders, shared with the self-test and the registry fixtures.
// ---------------------------------------------------------------------------

/// A spec text that passes FR-088. The header table is on lines 3 to 8:
/// Status line 5, Context 6, Roadmap phase 7, Depends on 8 (table header on
/// line 3). The requirements table sits in section 4: its FR-1 row is on line
/// 20 and [rows] (extra requirement rows, one line each) follow it. [after]
/// starts on line 34 when [rows] is empty.
String specFixtureText({
  String context = 'package',
  String phase = '0',
  String depends = 'none',
  String rows = '',
  String after = '',
}) {
  final buffer = StringBuffer(
    '# T\n\n| | |\n|---|---|\n| Status | draft |\n'
    '| Context | `$context` |\n| Roadmap phase | $phase |\n'
    '| Depends on | $depends |\n\n',
  );
  for (final heading in templateHeadings) {
    buffer.write('## $heading\n\n');
    if (heading.startsWith('4.')) {
      buffer.write('| Id | Requirement |\n|---|---|\n| FR-1 | a |\n$rows\n');
    }
  }
  buffer.write(after);
  return buffer.toString();
}

/// The rank table of [ranksByRank] as section 4.11 markdown.
String rankTableFixture(Map<int, List<String>> ranksByRank) =>
    '### 4.11 Spec rank table\n\n| Rank | Specs |\n|---|---|\n'
    '${ranksByRank.entries.map((e) => '| ${e.key} | ${e.value.map((n) => '`$n`').join(', ')} |').join('\n')}\n';

/// A valid documentation index listing [paths] (relative to `doc/`).
String indexFixture(Iterable<String> paths) =>
    '# Index\n\n| File | Summary | Read when |\n|---|---|---|\n'
    '${paths.map((p) => '| `$p` | s | w |').join('\n')}\n';

/// A source set holding [specs] (stem to text) under `doc/specs/`, the
/// context map of [contexts] and any [extra] files.
SourceSet specFixtureSources(
  Map<String, String> specs, {
  Map<String, List<String>> contexts = const {
    'content': [],
    'combat': ['content'],
    'character': ['content'],
  },
  Map<String, String> extra = const {},
}) => SourceSet({
  architectureRulesPath: contextMapFixtureArchitecture(contexts),
  agentsPath: contextMapFixtureAgents(contexts.keys),
  for (final entry in specs.entries)
    '$_specsPrefix${entry.key}.md': entry.value,
  ...extra,
});

/// One minimal violating fixture per check id (FR-005).
final Map<String, SourceSet Function()> specConformanceViolatingFixtures = {
  'FR-088': () => specFixtureSources({
    'a': specFixtureText().replaceFirst('## 2. Source\n', ''),
  }),
  'FR-089': () => specFixtureSources({
    'a': specFixtureText(depends: '`b.md`'),
    'b': specFixtureText(depends: '`a.md`'),
  }),
  'FR-090': () => specFixtureSources({
    'a': specFixtureText(context: 'content', depends: '`b.md`'),
    'b': specFixtureText(context: 'combat'),
  }),
  'FR-092': () => specFixtureSources({
    'a': specFixtureText(phase: '1', depends: '`b.md`'),
    'b': specFixtureText(phase: '2'),
  }),
  'FR-096': () => specFixtureSources({
    'a': specFixtureText(after: '\nSee `missing.md` FR-1.\n'),
  }),
  'FR-099': () => specFixtureSources({
    'content-equipment': specFixtureText(
      context: 'content',
      depends: '`ability-scores.md`',
    ),
    'ability-scores': specFixtureText(context: 'shared_kernel'),
  }),
  'FR-100': () =>
      specFixtureSources({'a': specFixtureText(depends: 'see b.md')}),
  'FR-101': () => specFixtureSources({
    'a': specFixtureText(depends: '`b.md`'),
    'b': specFixtureText(),
    'shared-types-and-ownership': specFixtureText(
      after: rankTableFixture({
        0: ['shared-types-and-ownership'],
        4: ['a', 'b'],
      }),
    ),
  }),
  'FR-102': () => specFixtureSources(
    {'a': specFixtureText()},
    extra: {documentationIndexPath: indexFixture([])},
  ),
};
