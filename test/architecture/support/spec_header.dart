import 'markdown_tables.dart';

/// One row of a spec's header table.
final class SpecHeaderRow {
  /// Creates a row.
  const SpecHeaderRow({
    required this.key,
    required this.cell,
    required this.line,
  });

  /// The first cell without backticks, trimmed (`Roadmap phase`).
  final String key;

  /// The second cell, trimmed, backticks kept.
  final String cell;

  /// The 1-based line of the row.
  final int line;
}

/// The type phase of a spec: one integer, or a range `a-b` (FR-094).
final class SpecPhase {
  /// Creates a phase from [low] to [high] (equal for a single integer).
  const SpecPhase(this.low, this.high);

  /// The lowest type phase.
  final int low;

  /// The highest type phase.
  final int high;

  @override
  bool operator ==(Object other) =>
      other is SpecPhase && other.low == low && other.high == high;

  @override
  int get hashCode => Object.hash(low, high);

  @override
  String toString() => low == high ? '$low' : '$low-$high';
}

/// A level-2 heading of a document.
final class SpecHeading {
  /// Creates a heading.
  const SpecHeading({required this.text, required this.line});

  /// The heading text without the `##` marks.
  final String text;

  /// The 1-based line.
  final int line;
}

/// The first table of a spec parsed per FR-094 of
/// `doc/specs/architecture-guardrails.md`.
///
/// Parsing never throws: a spec without a table, or without a row, shows up
/// as null fields so the checks can name what is missing.
final class SpecHeader {
  const SpecHeader._({
    required this.tableFound,
    required this.tableLine,
    required this.rows,
    required this.context,
    required this.phase,
    required this.dependsOn,
    required this.dependsLeftover,
  });

  /// Parses the header of the spec text [markdown].
  factory SpecHeader.parse(String markdown) {
    final tables = parseMarkdownTables(markdown);
    if (tables.isEmpty) {
      return const SpecHeader._(
        tableFound: false,
        tableLine: 1,
        rows: {},
        context: null,
        phase: null,
        dependsOn: [],
        dependsLeftover: null,
      );
    }
    final table = tables.first;
    final rows = <String, SpecHeaderRow>{};
    for (final row in table.rows) {
      final first = row.cell(0);
      if (first == null) continue;
      final key = stripBackticks(first).trim();
      rows.putIfAbsent(
        key,
        () => SpecHeaderRow(key: key, cell: row.cell(1) ?? '', line: row.line),
      );
    }
    final contextCell = rows['Context']?.cell;
    final phaseCell = rows['Roadmap phase']?.cell;
    final dependsCell = rows['Depends on']?.cell;
    final tokens = <String>[];
    String? leftover;
    if (dependsCell != null) {
      for (final m in _dependencyToken.allMatches(dependsCell)) {
        tokens.add(m.group(1)!);
      }
      final rest = dependsCell
          .replaceAll(_dependencyToken, '')
          .replaceAll(RegExp(r'[,\s]'), '');
      leftover = rest.isEmpty || rest == 'none' ? '' : rest;
    }
    return SpecHeader._(
      tableFound: true,
      tableLine: table.headerLine,
      rows: Map.unmodifiable(rows),
      context: contextCell == null ? null : _firstBacktickedToken(contextCell),
      phase: phaseCell == null ? null : parseSpecPhase(phaseCell),
      dependsOn: List.unmodifiable(tokens),
      dependsLeftover: leftover,
    );
  }

  /// Whether the document has any table.
  final bool tableFound;

  /// The 1-based line of the first table's header row (1 when none).
  final int tableLine;

  /// The rows of the first table by key.
  final Map<String, SpecHeaderRow> rows;

  /// The first backticked token of the Context cell, or null.
  final String? context;

  /// The type phase, or null when the cell has no integer or is missing.
  final SpecPhase? phase;

  /// The `name.md` tokens of the Depends on cell, in order, as file names.
  final List<String> dependsOn;

  /// The text left in the Depends on cell once tokens, commas, spaces and a
  /// bare `none` are removed; empty when the cell is clean, null when there
  /// is no Depends on row.
  final String? dependsLeftover;

  /// The Status cell with backticks removed, or null.
  String? get status {
    final cell = rows['Status']?.cell;
    return cell == null ? null : stripBackticks(cell).trim();
  }

  /// The line of the Depends on row, or [tableLine] when missing.
  int get dependsLine => rows['Depends on']?.line ?? tableLine;

  /// The line of the Context row, or [tableLine] when missing.
  int get contextLine => rows['Context']?.line ?? tableLine;

  /// The line of the Roadmap phase row, or [tableLine] when missing.
  int get phaseLine => rows['Roadmap phase']?.line ?? tableLine;

  /// The dependencies as spec stems (`d20-tests` for `d20-tests.md`).
  List<String> get dependsOnStems => [
    for (final file in dependsOn) file.substring(0, file.length - 3),
  ];
}

final RegExp _dependencyToken = RegExp(r'`([a-z0-9-]+\.md)`');
final RegExp _backticked = RegExp(r'`([^`]+)`');
final RegExp _firstInteger = RegExp(r'\d+');

String? _firstBacktickedToken(String cell) =>
    _backticked.firstMatch(cell)?.group(1);

/// Parses the type phase from a Roadmap phase [cell] (FR-094): the first
/// integer, or the first range `a-b` or `a–b`; everything after it is
/// ignored. Null when the cell has no integer.
SpecPhase? parseSpecPhase(String cell) {
  final first = _firstInteger.firstMatch(cell);
  if (first == null) return null;
  final low = int.parse(first.group(0)!);
  final range = RegExp(r'\s*[-–]\s*(\d+)').matchAsPrefix(cell, first.end);
  final high = range == null ? low : int.parse(range.group(1)!);
  return SpecPhase(low, high < low ? low : high);
}

final RegExp _level2 = RegExp(r'^##\s+(.*?)\s*#*\s*$');
final RegExp _fence = RegExp(r'^ {0,3}(```|~~~)');

/// The level-2 headings of [markdown] in order, outside fenced code blocks.
List<SpecHeading> level2Headings(String markdown) {
  final headings = <SpecHeading>[];
  String? fence;
  final lines = markdown.split('\n');
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i].endsWith('\r')
        ? lines[i].substring(0, lines[i].length - 1)
        : lines[i];
    final fenceMatch = _fence.firstMatch(line);
    if (fence != null) {
      if (fenceMatch != null && fenceMatch.group(1) == fence) fence = null;
      continue;
    }
    if (fenceMatch != null) {
      fence = fenceMatch.group(1);
      continue;
    }
    final match = _level2.firstMatch(line);
    if (match != null) {
      headings.add(SpecHeading(text: match.group(1)!, line: i + 1));
    }
  }
  return headings;
}
