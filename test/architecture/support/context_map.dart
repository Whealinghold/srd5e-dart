import 'constants.dart' as constants;
import 'markdown_tables.dart';
import 'source_set.dart';

/// The file holding the context map table (`architecture.md` §2).
const String architectureRulesPath = 'doc/rules/architecture.md';

/// The file whose "Current contexts" list must agree with the map (FR-022).
const String agentsPath = 'AGENTS.md';

/// The folders directly under `lib/src/` that are not bounded contexts.
const Set<String> nonContextFolders = {
  'shared_kernel',
  'shared_ports',
  'testing',
};

/// The header cells of the context map table (FR-022).
const List<String> contextMapHeader = [
  'Context',
  'Purpose',
  'May depend on (upstream)',
];

const String _libSrd = 'lib/src/';

/// The first folder under `lib/src/` that holds [path], or null when [path]
/// is not inside a folder of `lib/src/` (for example a loose
/// `lib/src/x.dart`, or a path outside `lib/src/`).
String? moduleOf(String path) {
  if (!path.startsWith(_libSrd)) return null;
  final segments = path.substring(_libSrd.length).split('/');
  return segments.length >= 2 && segments.first.isNotEmpty
      ? segments.first
      : null;
}

/// Whether [folder] is one of [nonContextFolders].
bool isNonContextFolder(String folder) => nonContextFolders.contains(folder);

/// The bounded context that owns the file [path]: the folder directly under
/// `lib/src/`, unless it is `shared_kernel`, `shared_ports` or `testing`.
/// Null for those, for a loose file in `lib/src/` and for any other path.
///
/// This is structural. It does not consult the map, so a folder missing from
/// the map still has a context name here (FR-021 reports it).
String? contextOf(String path) {
  final folder = moduleOf(path);
  return folder == null || isNonContextFolder(folder) ? null : folder;
}

/// The context whose barrel is the file [path] (`lib/src/X/X.dart` gives
/// `X`), or null when [path] is not a barrel.
String? barrelContextOf(String path) {
  final context = contextOf(path);
  return context != null && path == '$_libSrd$context/$context.dart'
      ? context
      : null;
}

/// The barrel path of [context].
String barrelPathOf(String context) => '$_libSrd$context/$context.dart';

/// One row of the context map table.
final class ContextMapRow {
  /// Creates a row.
  const ContextMapRow({
    required this.name,
    required this.line,
    required this.upstream,
  });

  /// The context name.
  final String name;

  /// The 1-based line of the row in `architecture.md`.
  final int line;

  /// The upstream contexts named by the row, in written order. Empty for
  /// `none`. A malformed cell keeps the names that were well formed.
  final List<String> upstream;
}

/// A finding of the parser: the map or `AGENTS.md` is not in the format FR-022
/// fixes, or the two disagree.
final class ContextMapProblem {
  /// Creates a problem at [path]:[line].
  const ContextMapProblem({
    required this.path,
    required this.line,
    required this.detail,
  });

  /// The repository-relative path of the file with the problem.
  final String path;

  /// The 1-based line.
  final int line;

  /// What is wrong.
  final String detail;

  @override
  String toString() => '$path:$line $detail';
}

/// One entry of the `AGENTS.md` "Current contexts" list.
final class AgentsContext {
  /// Creates an entry.
  const AgentsContext({required this.name, required this.line});

  /// The folder name written as `` `name/` ``.
  final String name;

  /// The 1-based line of the list item in `AGENTS.md`.
  final int line;
}

final RegExp _nameCell = RegExp(r'^`([a-z][a-z0-9_]*)`$');
final RegExp _agentsItem = RegExp(r'^\s*-\s+`([a-z][a-z0-9_]*)/`');
final RegExp _agentsBullet = RegExp(r'^\s*-\s');

/// The context map of `architecture.md` §2, parsed from the table (FR-022).
///
/// Parsing never throws: a table that is missing or malformed shows up in
/// [problems] and the rows that could be read are still available, so
/// downstream checks can run on what exists.
final class ContextMap {
  const ContextMap._({
    required this.rows,
    required this.problems,
    required this.tableFound,
    required this.agentsContexts,
    required this.agentsListLine,
  });

  /// Parses the map from the files of [sources].
  factory ContextMap.parse(SourceSet sources) => ContextMap.fromTexts(
    architecture: sources.files[architectureRulesPath],
    agents: sources.files[agentsPath],
  );

  /// Parses the map from the text of `architecture.md` and `AGENTS.md`; a
  /// null text means the file is absent.
  factory ContextMap.fromTexts({String? architecture, String? agents}) {
    final problems = <ContextMapProblem>[];
    final rows = <ContextMapRow>[];
    var tableFound = false;
    if (architecture == null) {
      problems.add(
        const ContextMapProblem(
          path: architectureRulesPath,
          line: 1,
          detail: 'the file is missing, so there is no context map to parse',
        ),
      );
    } else {
      tableFound = _parseTable(architecture, rows, problems);
    }
    final agentsContexts = <AgentsContext>[];
    int? agentsListLine;
    if (agents == null) {
      problems.add(
        const ContextMapProblem(
          path: agentsPath,
          line: 1,
          detail: 'the file is missing, so there is no "Current contexts" list',
        ),
      );
    } else {
      agentsListLine = _parseAgents(agents, agentsContexts, problems);
    }
    return ContextMap._(
      rows: List.unmodifiable(rows),
      problems: List.unmodifiable(problems),
      tableFound: tableFound,
      agentsContexts: List.unmodifiable(agentsContexts),
      agentsListLine: agentsListLine,
    );
  }

  /// The rows of the table, in document order.
  final List<ContextMapRow> rows;

  /// Format problems of the table and of the `AGENTS.md` list, not yet
  /// including a disagreement between the two (see [agentsContexts]).
  final List<ContextMapProblem> problems;

  /// Whether a table with the header of [contextMapHeader] was found.
  final bool tableFound;

  /// The entries of the `AGENTS.md` "Current contexts" list.
  final List<AgentsContext> agentsContexts;

  /// The 1-based line of the "Current contexts" paragraph in `AGENTS.md`, or
  /// null when the file or the paragraph is missing.
  final int? agentsListLine;

  /// The context names of the map, in table order.
  List<String> get contexts => [for (final row in rows) row.name];

  /// Whether [context] has a row.
  bool hasContext(String context) => rows.any((row) => row.name == context);

  /// The row of [context], or null.
  ContextMapRow? rowOf(String context) {
    for (final row in rows) {
      if (row.name == context) return row;
    }
    return null;
  }

  /// The upstream set of [context]: the contexts its row lists. Empty for an
  /// unknown context.
  Set<String> upstreamOf(String context) =>
      Set.unmodifiable(rowOf(context)?.upstream ?? const <String>[]);

  /// Whether [from] may import the barrel of [to] (FR-019): [to] is in the
  /// upstream set of [from].
  bool mayDependOn(String from, String to) => upstreamOf(from).contains(to);

  /// Every context reachable from [context] through upstream edges, [context]
  /// itself only when it sits on a cycle.
  Set<String> transitiveUpstreamOf(String context) {
    final seen = <String>{};
    final pending = [...upstreamOf(context)];
    while (pending.isNotEmpty) {
      final next = pending.removeLast();
      if (seen.add(next)) pending.addAll(upstreamOf(next));
    }
    return Set.unmodifiable(seen);
  }

  /// The contexts that list [context] as upstream, in table order.
  List<String> dependantsOf(String context) => [
    for (final row in rows)
      if (row.upstream.contains(context)) row.name,
  ];

  /// The leaf contexts (FR-098): the named `leafContexts` constant, limited
  /// to the ones the map holds.
  Set<String> get leaves => {
    for (final row in rows)
      if (constants.leafContexts.contains(row.name)) row.name,
  };

  /// Whether [context] is a leaf context of the map.
  bool isLeaf(String context) => leaves.contains(context);

  /// The cycles of the map (FR-020), one per strongly connected component
  /// that has a cycle, as a closed path (`[a, b, a]`; a self-edge is
  /// `[a, a]`). Components and starting points follow table order, so the
  /// result is deterministic. Edges to a name with no row are ignored.
  List<List<String>> cycles() {
    final names = contexts;
    final known = names.toSet();
    List<String> successors(String name) => [
      for (final up in upstreamOf(name))
        if (known.contains(up)) up,
    ];

    // Tarjan's algorithm.
    final index = <String, int>{};
    final low = <String, int>{};
    final onStack = <String>{};
    final stack = <String>[];
    final components = <List<String>>[];
    var counter = 0;

    void visit(String name) {
      index[name] = low[name] = counter++;
      stack.add(name);
      onStack.add(name);
      for (final next in successors(name)) {
        if (!index.containsKey(next)) {
          visit(next);
          low[name] = low[name]! < low[next]! ? low[name]! : low[next]!;
        } else if (onStack.contains(next)) {
          low[name] = low[name]! < index[next]! ? low[name]! : index[next]!;
        }
      }
      if (low[name] == index[name]) {
        final component = <String>[];
        String member;
        do {
          member = stack.removeLast();
          onStack.remove(member);
          component.add(member);
        } while (member != name);
        components.add(component);
      }
    }

    for (final name in names) {
      if (!index.containsKey(name)) visit(name);
    }

    final found = <List<String>>[];
    for (final component in components) {
      final members = component.toSet();
      final start = names.firstWhere(members.contains);
      final hasCycle = members.length > 1 || successors(start).contains(start);
      if (!hasCycle) continue;
      found.add(_closedPath(start, members, successors));
    }
    found.sort((a, b) => names.indexOf(a.first) - names.indexOf(b.first));
    return found;
  }
}

List<String> _closedPath(
  String start,
  Set<String> members,
  List<String> Function(String) successors,
) {
  final path = <String>[start];
  final visited = <String>{};
  bool walk(String at) {
    for (final next in successors(at)) {
      if (!members.contains(next)) continue;
      if (next == start) {
        path.add(start);
        return true;
      }
      if (!visited.add(next)) continue;
      path.add(next);
      if (walk(next)) return true;
      path.removeLast();
    }
    return false;
  }

  walk(start);
  return path;
}

bool _parseTable(
  String markdown,
  List<ContextMapRow> rows,
  List<ContextMapProblem> problems,
) {
  final tables = parseMarkdownTables(markdown);
  final matching = [
    for (final table in tables)
      if (_sameHeader(table.header)) table,
  ];
  if (matching.isEmpty) {
    final underHeading = tables
        .where((t) => (t.heading ?? '').toLowerCase() == 'context map')
        .toList();
    problems.add(
      ContextMapProblem(
        path: architectureRulesPath,
        line: underHeading.isEmpty ? 1 : underHeading.first.headerLine,
        detail:
            'no table with the header cells ${contextMapHeader.join(' | ')}; '
            'the context map cannot be parsed',
      ),
    );
    return false;
  }
  final seen = <String>{};
  for (final row in matching.first.rows) {
    if (row.cells.length != contextMapHeader.length) {
      problems.add(
        ContextMapProblem(
          path: architectureRulesPath,
          line: row.line,
          detail:
              'the row has ${row.cells.length} cells, expected '
              '${contextMapHeader.length}',
        ),
      );
      continue;
    }
    final nameMatch = _nameCell.firstMatch(row.cells[0]);
    if (nameMatch == null) {
      problems.add(
        ContextMapProblem(
          path: architectureRulesPath,
          line: row.line,
          detail:
              'the Context cell "${row.cells[0]}" is not one backticked '
              'context name',
        ),
      );
      continue;
    }
    final name = nameMatch.group(1)!;
    if (!seen.add(name)) {
      problems.add(
        ContextMapProblem(
          path: architectureRulesPath,
          line: row.line,
          detail: 'the context `$name` has more than one row',
        ),
      );
      continue;
    }
    rows.add(
      ContextMapRow(
        name: name,
        line: row.line,
        upstream: _parseUpstream(name, row, problems),
      ),
    );
  }
  for (final extra in matching.skip(1)) {
    problems.add(
      ContextMapProblem(
        path: architectureRulesPath,
        line: extra.headerLine,
        detail:
            'a second table with the context map header; the map must be '
            'one table',
      ),
    );
  }
  return true;
}

bool _sameHeader(List<String> header) {
  if (header.length != contextMapHeader.length) return false;
  for (var i = 0; i < header.length; i++) {
    if (header[i] != contextMapHeader[i]) return false;
  }
  return true;
}

List<String> _parseUpstream(
  String context,
  TableRow row,
  List<ContextMapProblem> problems,
) {
  final cell = row.cells[2];
  if (cell == 'none') return const [];
  final names = <String>[];
  for (final piece in cell.split(',')) {
    final match = _nameCell.firstMatch(piece.trim());
    if (match == null) {
      problems.add(
        ContextMapProblem(
          path: architectureRulesPath,
          line: row.line,
          detail:
              'the upstream cell of `$context` ("$cell") is neither none nor '
              'backticked names separated by commas',
        ),
      );
      continue;
    }
    names.add(match.group(1)!);
  }
  return names;
}

int? _parseAgents(
  String markdown,
  List<AgentsContext> contexts,
  List<ContextMapProblem> problems,
) {
  final lines = markdown.split('\n');
  final header = lines.indexWhere((l) => l.startsWith('Current contexts'));
  if (header < 0) {
    problems.add(
      const ContextMapProblem(
        path: agentsPath,
        line: 1,
        detail:
            'no paragraph starting "Current contexts", so the contexts list '
            'cannot be compared with the map',
      ),
    );
    return null;
  }
  var inList = false;
  for (var i = header + 1; i < lines.length; i++) {
    final line = lines[i].replaceAll('\r', '');
    if (line.trim().isEmpty) continue;
    if (line.startsWith('#')) break;
    final item = _agentsItem.firstMatch(line);
    if (item != null) {
      inList = true;
      contexts.add(AgentsContext(name: item.group(1)!, line: i + 1));
    } else if (_agentsBullet.hasMatch(line)) {
      inList = true;
      problems.add(
        ContextMapProblem(
          path: agentsPath,
          line: i + 1,
          detail: 'a list item that does not start with a backticked `name/`',
        ),
      );
    } else if (inList && !line.startsWith(' ') && !line.startsWith('\t')) {
      break;
    }
  }
  return header + 1;
}
