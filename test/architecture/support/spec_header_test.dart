import 'package:test/test.dart';

import 'spec_header.dart';

String _spec({
  String context = '`combat`',
  String phase = '3',
  String depends = '`a.md`, `b.md`',
  String extraRow = '',
}) =>
    '# T\n\n| | |\n|---|---|\n| Status | draft |\n| Context | $context |\n'
    '| Roadmap phase | $phase |\n| Depends on | $depends |\n$extraRow\n'
    '## 1. Purpose and scope\n';

void main() {
  /// Requirement: doc/specs/architecture-guardrails.md FR-094 - the support
  ///   code parses the first table of a spec into Status, Context, Roadmap
  ///   phase and Depends on.
  /// Path: happy
  group('SpecHeader.parse', () {
    /// Requirement: doc/specs/architecture-guardrails.md FR-094 - the four
    ///   rows are read with their lines.
    /// Path: happy
    test('reads status, context, phase, dependencies and lines', () {
      final header = SpecHeader.parse(_spec());

      expect(header.tableFound, isTrue);
      expect(header.tableLine, 3);
      expect(header.status, 'draft');
      expect(header.context, 'combat');
      expect(header.contextLine, 6);
      expect(header.phase, const SpecPhase(3, 3));
      expect(header.phaseLine, 7);
      expect(header.dependsOn, ['a.md', 'b.md']);
      expect(header.dependsOnStems, ['a', 'b']);
      expect(header.dependsLine, 8);
      expect(header.dependsLeftover, '');
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-094 - Context is
    ///   the first backticked token of its cell.
    /// Path: unhappy (boundary)
    test('takes the first backticked token of Context', () {
      expect(
        SpecHeader.parse(_spec(context: '`package` (and `combat`)')).context,
        'package',
      );
      expect(SpecHeader.parse(_spec(context: 'combat')).context, isNull);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-094 - a row other
    ///   than the four, such as Consumed by, is ignored for dependencies.
    /// Path: unhappy (rule interaction)
    test('ignores a Consumed by row', () {
      final header = SpecHeader.parse(
        _spec(extraRow: '| Consumed by | `z.md` |'),
      );

      expect(header.dependsOn, ['a.md', 'b.md']);
      expect(header.rows.keys, contains('Consumed by'));
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-094 - `none` or
    ///   an empty cell is an empty set; anything else is left over.
    /// Path: unhappy (invalid input)
    test('none and empty are empty sets, other text is left over', () {
      expect(SpecHeader.parse(_spec(depends: 'none')).dependsLeftover, '');
      expect(SpecHeader.parse(_spec(depends: '')).dependsLeftover, '');
      expect(SpecHeader.parse(_spec(depends: 'none')).dependsOn, isEmpty);

      final prose = SpecHeader.parse(_spec(depends: '`a.md` and b.md'));
      expect(prose.dependsOn, ['a.md']);
      expect(prose.dependsLeftover, 'andb.md');

      final lead = SpecHeader.parse(
        _spec(depends: 'none. Mentions foo.md only.'),
      );
      expect(lead.dependsOn, isEmpty);
      expect(lead.dependsLeftover, isNotEmpty);

      final link = SpecHeader.parse(_spec(depends: '[a](a.md)'));
      expect(link.dependsLeftover, isNotEmpty);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-094 - a document
    ///   without a table, or a table without a row, never throws.
    /// Path: unhappy (empty and minimal)
    test('a missing table or row gives null fields', () {
      final none = SpecHeader.parse('# T\n\ntext\n');
      expect(none.tableFound, isFalse);
      expect(none.context, isNull);
      expect(none.phase, isNull);
      expect(none.dependsLeftover, isNull);
      expect(none.dependsLine, 1);

      final partial = SpecHeader.parse(
        '# T\n\n| | |\n|---|---|\n| Status | x |\n',
      );
      expect(partial.tableFound, isTrue);
      expect(partial.rows.keys, ['Status']);
      expect(partial.dependsLine, partial.tableLine);
    });
  });

  /// Requirement: doc/specs/architecture-guardrails.md FR-094 - the type
  ///   phase is the first integer or the first range, the rest is ignored.
  /// Path: happy
  group('parseSpecPhase', () {
    /// Requirement: per case - doc/specs/architecture-guardrails.md FR-094 -
    ///   the examples of the requirement and range forms.
    /// Path: per case
    for (final c in <(String, int?, int?)>[
      ('0', 0, 0),
      ('0 (see ../roadmap.md)', 0, 0),
      ('3-4', 3, 4),
      ('3 – 4', 3, 4),
      ('3–4', 3, 4),
      ('Types 2; bulk data 5', 2, 2),
      ('3 for the Armor...; 5 for the rest', 3, 3),
      ('Phase 5', 5, 5),
      ('later', null, null),
      ('', null, null),
    ]) {
      test('"${c.$1}"', () {
        final phase = parseSpecPhase(c.$1);

        expect(phase?.low, c.$2);
        expect(phase?.high, c.$3);
      });
    }

    /// Requirement: doc/specs/architecture-guardrails.md FR-094 - a reversed
    ///   range keeps the lowest phase as its low end.
    /// Path: unhappy (boundary)
    test('a reversed range does not invert', () {
      expect(parseSpecPhase('4-2'), const SpecPhase(4, 4));
      expect(const SpecPhase(2, 3).toString(), '2-3');
    });
  });

  /// Requirement: doc/specs/architecture-guardrails.md FR-088 - the level-2
  ///   headings are read outside fenced code.
  /// Path: happy
  group('level2Headings', () {
    /// Requirement: doc/specs/architecture-guardrails.md FR-088 - level 2
    ///   only, with lines, skipping fences and deeper levels.
    /// Path: unhappy (false positive)
    test('skips fenced code and other levels', () {
      final headings = level2Headings(
        '# T\n## One\n### Deep\n```\n## Fenced\n```\n## Two ##\n',
      );

      expect(headings.map((h) => h.text), ['One', 'Two']);
      expect(headings.map((h) => h.line), [2, 7]);
    });
  });
}
