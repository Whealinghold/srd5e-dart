import 'package:test/test.dart';

import 'rank_table.dart';
import 'real_repository.dart';
import 'source_set.dart';

const Timeout _budget = Timeout(Duration(seconds: 10));

const String _table =
    '# T\n\n### 4.11 Spec rank table\n\nIntro.\n\n'
    '| Rank | Specs |\n|---|---|\n'
    '| 0 | `shared-types-and-ownership` |\n'
    '| 2 | `a`, `b`, `c` |\n'
    '| x | `skipped` |\n'
    '| 9 | `d` |\n'
    '| 4 | `a` |\n';

void main() {
  /// Requirement: doc/specs/architecture-guardrails.md FR-101 - the rank
  ///   table is parsed from section 4.11, never copied.
  /// Path: happy
  group('RankTable.parse', () {
    /// Requirement: doc/specs/architecture-guardrails.md FR-101 - multi-name
    ///   cells and gaps parse; the header and non-integer rows are skipped.
    /// Path: happy
    test('reads ranks, gaps, several names per cell and lines', () {
      final table = RankTable.parse(_table);

      expect(table.tableFound, isTrue);
      expect(table.ranks, {
        'shared-types-and-ownership': 0,
        'a': 2,
        'b': 2,
        'c': 2,
        'd': 9,
      });
      expect(table.rankOf('d'), 9);
      expect(table.rankOf('skipped'), isNull);
      expect(table.entries.first.line, 9);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-101 - a name
    ///   listed under two ranks is reported by [RankTable.duplicates], the
    ///   first rank wins for lookups.
    /// Path: unhappy (state error)
    test('reports a name under two ranks', () {
      final table = RankTable.parse(_table);

      expect(table.duplicates.map((e) => (e.name, e.rank, e.line)), [
        ('a', 4, 13),
      ]);
      expect(table.rankOf('a'), 2);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-101 - a document
    ///   without the table, or with another header, is not found.
    /// Path: unhappy (missing content)
    test('a missing file, section or Rank header is not found', () {
      expect(RankTable.parse(null).tableFound, isFalse);
      expect(RankTable.parse('# T\n').tableFound, isFalse);
      expect(
        RankTable.parse(
          '### 4.11 R\n\n| Level | Specs |\n|---|---|\n| 1 | `a` |\n',
        ).tableFound,
        isFalse,
      );
      expect(
        RankTable.parse(
          '### 4.10 R\n\n| Rank | Specs |\n|---|---|\n| 1 | `a` |\n',
        ).tableFound,
        isFalse,
      );
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-101 - the table
    ///   is read from the decisions spec of a source set.
    /// Path: happy
    test('fromSources reads the decisions spec', () {
      final table = RankTable.fromSources(
        SourceSet({rankTableSpecPath: _table}),
      );

      expect(table.rankOf('d'), 9);
      expect(RankTable.fromSources(SourceSet({})).tableFound, isFalse);
    });
  });

  /// Requirement: doc/specs/architecture-guardrails.md FR-101 - the decisions
  ///   spec still has a Rank table that parses as the requirement lists.
  /// Path: unhappy (state error)
  group('the real rank table', () {
    final table = RankTable.fromSources(realRepository);

    /// Requirement: doc/specs/architecture-guardrails.md FR-101 - the
    ///   decisions spec has a table with a Rank header under section 4.11.
    /// Path: unhappy (state error)
    test('exists', () {
      expect(table.tableFound, isTrue);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-101 - the parse
    ///   gives the ranks the requirement names (multi-name cells and gaps).
    /// Path: unhappy (state error)
    test('gives the ranks named in the requirement', () {
      expect(table.rankOf('spell-effect-data'), 7);
      expect(table.rankOf('equipment-rules'), 9);
      expect(table.rankOf('higher-level-start-equipment-and-trinkets'), 15);
      expect(table.rankOf('class-wizard'), 17);
      expect(table.rankOf('class-wizard-evoker'), 18);
      expect(table.rankOf('telepathy'), 23);
      expect(table.rankOf('returning-to-life'), 27);
    });
  }, timeout: _budget);
}
