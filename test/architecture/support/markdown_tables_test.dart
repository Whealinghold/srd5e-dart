import 'package:test/test.dart';

import 'markdown_tables.dart';

void main() {
  /// Requirement: doc/specs/architecture-guardrails.md FR-071 - the table
  ///   parser gives header cells, rows and line numbers, the base of the
  ///   requirements parse.
  /// Path: happy
  group('parseMarkdownTables', () {
    /// Requirement: doc/specs/architecture-guardrails.md FR-071 - header
    ///   cells, rows and 1-based line numbers.
    /// Path: happy
    test('reads header, rows and line numbers', () {
      const md =
          '# Title\n'
          '\n'
          '| Id | Text |\n'
          '|---|:---:|\n'
          '| FR-1 | one |\n'
          '| FR-2 | two |\n'
          '\n'
          'after\n';

      final tables = parseMarkdownTables(md);

      expect(tables, hasLength(1));
      final table = tables.single;
      expect(table.headerLine, 3);
      expect(table.header, ['Id', 'Text']);
      expect(table.rows.map((r) => r.line), [5, 6]);
      expect(table.rows.map((r) => r.cells), [
        ['FR-1', 'one'],
        ['FR-2', 'two'],
      ]);
      expect(table.heading, 'Title');
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-102 - header
    ///   cells and first-cell backticks are readable for the index table.
    /// Path: happy
    test('keeps backticks in cells and strips them on request', () {
      const md = '| File | Summary |\n|---|---|\n| `specs/a.md` | x |\n';

      final row = parseMarkdownTables(md).single.rows.single;

      expect(row.cells.first, '`specs/a.md`');
      expect(stripBackticks(row.cells.first), 'specs/a.md');
      expect(stripBackticks('no ticks'), 'no ticks');
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-071 - a pipe
    ///   escaped as `\|` stays inside its cell.
    /// Path: happy
    test('an escaped pipe does not split a cell', () {
      const md = '| A | B |\n|---|---|\n| x \\| y | z |\n';

      final row = parseMarkdownTables(md).single.rows.single;

      expect(row.cells, ['x | y', 'z']);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-071 - tables
    ///   without outer pipes and with CRLF endings still parse.
    /// Path: happy
    test('accepts missing outer pipes and CRLF line endings', () {
      const md = 'A | B\r\n--- | ---\r\n1 | 2\r\n';

      expect(parseMarkdownTables(md), isEmpty);

      const piped = '| A | B\r\n|---|---\r\n| 1 | 2\r\n';
      final table = parseMarkdownTables(piped).single;
      expect(table.header, ['A', 'B']);
      expect(table.rows.single.cells, ['1', '2']);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-071 - section
    ///   numbers come from the nearest heading.
    /// Path: happy
    test('reports the section number of the nearest heading', () {
      const md =
          '## 4. Requirements\n'
          '### 4.2 Checks\n'
          '| A |\n|---|\n| 1 |\n'
          '## Plain\n'
          '| B |\n|---|\n| 2 |\n';

      final tables = parseMarkdownTables(md);

      expect(tables[0].sectionNumber, '4.2');
      expect(tables[0].topSection, 4);
      expect(tables[1].sectionNumber, isNull);
      expect(tables[1].topSection, isNull);
      expect(headingSectionNumber('4. Requirements'), '4');
      expect(headingSectionNumber(null), isNull);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-071 - several
    ///   tables are all found, in order.
    /// Path: happy
    test('finds several tables', () {
      const md = '| A |\n|---|\n| 1 |\n\ntext\n\n| B |\n|---|\n| 2 |\n| 3 |\n';

      final tables = parseMarkdownTables(md);

      expect(tables.map((t) => t.header.single), ['A', 'B']);
      expect(tables[1].rows.map((r) => r.line), [9, 10]);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-071 - a table in
    ///   a fenced block is not a table.
    /// Path: unhappy (invalid input)
    test('ignores tables inside fenced code blocks', () {
      const md =
          '```\n| A |\n|---|\n| 1 |\n```\n~~~\n| B |\n|---|\n~~~\n'
          '| C |\n|---|\n| 3 |\n';

      final tables = parseMarkdownTables(md);

      expect(tables.map((t) => t.header.single), ['C']);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-071 - a row line
    ///   with no separator row under it is not a table.
    /// Path: unhappy (missing content)
    test('a row without a separator row is not a table', () {
      expect(parseMarkdownTables('| A | B |\n| 1 | 2 |\n'), isEmpty);
      expect(parseMarkdownTables('| A |\n'), isEmpty);
      expect(parseMarkdownTables(''), isEmpty);
      expect(parseMarkdownTables('| a |\n|--x--|\n'), isEmpty);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-071 - a short row
    ///   is kept, and `cell` answers null past its end.
    /// Path: unhappy (boundary)
    test('a short row yields null for a missing cell', () {
      const md = '| A | B |\n|---|---|\n| only |\n';

      final row = parseMarkdownTables(md).single.rows.single;

      expect(row.cell(0), 'only');
      expect(row.cell(1), isNull);
      expect(row.cell(-1), isNull);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-071 - a table under
    ///   an unnumbered sub-heading of section 4 still belongs to section 4; an
    ///   unnumbered heading of the section level ends it.
    /// Path: unhappy (boundary)
    test('unnumbered sub-headings inherit the enclosing section', () {
      const md =
          '## 4. Requirements\n'
          '### 4.1 Core\n'
          '### Extra\n'
          '| A |\n|---|\n| 1 |\n'
          '## Appendix\n'
          '| B |\n|---|\n| 2 |\n';

      final tables = parseMarkdownTables(md);

      expect(tables[0].enclosingSectionNumber, '4.1');
      expect(tables[0].enclosingTopSection, 4);
      expect(tables[1].enclosingSectionNumber, isNull);
      expect(tables[1].enclosingTopSection, isNull);
    });
  });
}
