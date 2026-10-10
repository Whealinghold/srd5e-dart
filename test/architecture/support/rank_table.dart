import 'markdown_tables.dart';
import 'source_set.dart';

/// The spec that holds the rank table (section 4.11).
const String rankTableSpecPath = 'doc/specs/shared-types-and-ownership.md';

/// One name listed in the rank table.
final class RankEntry {
  /// Creates an entry.
  const RankEntry({required this.name, required this.rank, required this.line});

  /// The spec stem (`class-wizard`).
  final String name;

  /// The rank of the row it was listed in.
  final int rank;

  /// The 1-based line of the row in the decisions spec.
  final int line;
}

/// The rank table of `shared-types-and-ownership.md` section 4.11, parsed
/// from the document and never copied (FR-101 of
/// `doc/specs/architecture-guardrails.md`).
///
/// Ranks are arbitrary integers; only their order counts. Parsing never
/// throws: a missing table shows as [tableFound] false.
final class RankTable {
  const RankTable._({required this.entries, required this.tableFound});

  /// Parses the table from the spec text [markdown] (null when the file is
  /// absent).
  ///
  /// The table is the one under the section 4.11 heading whose first header
  /// cell is `Rank`. Rows whose first cell is not an integer are skipped; the
  /// second cell lists specs as backticked stems.
  factory RankTable.parse(String? markdown) {
    if (markdown == null) {
      return const RankTable._(entries: [], tableFound: false);
    }
    final entries = <RankEntry>[];
    var found = false;
    for (final table in parseMarkdownTables(markdown)) {
      if (table.sectionNumber != '4.11') continue;
      if (table.header.isEmpty || table.header.first != 'Rank') continue;
      found = true;
      for (final row in table.rows) {
        final first = row.cell(0);
        final rank = first == null ? null : int.tryParse(first);
        if (rank == null) continue;
        for (final m in _stem.allMatches(row.cell(1) ?? '')) {
          entries.add(RankEntry(name: m.group(1)!, rank: rank, line: row.line));
        }
      }
      break;
    }
    return RankTable._(entries: List.unmodifiable(entries), tableFound: found);
  }

  /// Parses the table from the decisions spec in [sources].
  factory RankTable.fromSources(SourceSet sources) =>
      RankTable.parse(sources.files[rankTableSpecPath]);

  /// Every listed name, in document order, duplicates included.
  final List<RankEntry> entries;

  /// Whether a section 4.11 table with a `Rank` header was found.
  final bool tableFound;

  /// The rank of each name; for a name listed twice, the first row wins.
  Map<String, int> get ranks {
    final result = <String, int>{};
    for (final entry in entries) {
      result.putIfAbsent(entry.name, () => entry.rank);
    }
    return result;
  }

  /// The rank of [name], or null when it is not listed.
  int? rankOf(String name) => ranks[name];

  /// The entries whose name was already listed on an earlier row.
  List<RankEntry> get duplicates {
    final seen = <String>{};
    return [
      for (final entry in entries)
        if (!seen.add(entry.name)) entry,
    ];
  }
}

final RegExp _stem = RegExp(r'`([a-z0-9-]+)`');
