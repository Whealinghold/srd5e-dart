import 'package:test/test.dart';

import 'spec_ids.dart';

const _spec = '''
# Spec

## 3. Vocabulary

| Term | Type |
|---|---|
| FR-99 | not an id, section 3 |

## 4. Requirements

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-001 | First. | a | happy |
| FR-002 | Withdrawn: moved to other.md (FR-010) | b | happy |
| FR-3 | Third. | c | happy |
| `FR-004` | Backticked is not an id. | d | happy |
| FR-5a | Not an id. | e | happy |

### 4.5 Labels

| Label | Meaning |
|---|---|
| total | x |
| FR-006 | An id in a later sub-table counts. |

### 4.8 Withdrawn ids

| Id | Requirement |
|---|---|
| none | No id is withdrawn today. |

## 5. Model

| Id | Text |
|---|---|
| FR-007 | outside section 4 |
''';

void main() {
  /// Requirement: doc/specs/architecture-guardrails.md FR-071 - the
  ///   requirements are the section 4 rows whose first cell is an id.
  /// Path: happy
  group('parseSpecRequirements', () {
    /// Requirement: doc/specs/architecture-guardrails.md FR-071 - ids come
    ///   from section 4 rows only, with line numbers.
    /// Path: happy
    test('reads the ids of section 4 with their lines', () {
      final result = parseSpecRequirements(_spec);

      expect(result.ids, {'FR-001', 'FR-002', 'FR-3', 'FR-006'});
      expect(result.requirements.map((r) => r.line), [13, 14, 15, 24]);
      expect(result.hasSection4, isTrue);
      expect(result.hasRequirementsTable, isTrue);
      expect(result.duplicateIds, isEmpty);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-071 - a label
    ///   column of another section 4 table is not an id.
    /// Path: unhappy (invalid input)
    test('rows whose first cell is a label are not ids', () {
      final result = parseSpecRequirements(_spec);

      expect(result.ids, isNot(contains('total')));
      expect(result.ids, isNot(contains('none')));
      expect(result.ids, isNot(contains('FR-5a')));
      expect(result.ids, isNot(contains('FR-004')));
      expect(result.ids, isNot(contains('FR-99')));
      expect(result.ids, isNot(contains('FR-007')));
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-087 - a row whose
    ///   second cell begins `Withdrawn:` is a moved id, kept in the ids.
    /// Path: happy
    test('marks moved-id rows', () {
      final result = parseSpecRequirements(_spec);

      expect(result.movedIds, {'FR-002'});
      expect(result.activeIds, {'FR-001', 'FR-3', 'FR-006'});
      expect(result.requirements.first.moved, isFalse);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-087 - only a
    ///   second cell that begins with the word and a colon is a moved id.
    /// Path: unhappy (boundary)
    test('Withdrawn elsewhere in the cell is not a moved id', () {
      const md = '''
## 4. Requirements

| Id | Requirement |
|---|---|
| FR-1 | Withdrawn: moved to a.md (FR-2) |
| FR-2 | Text Withdrawn: not at the start |
| FR-3 | Withdrawn without colon |
| FR-4 | Withdrawn : moved to a.md (FR-1) |
| FR-5 |
''';

      final result = parseSpecRequirements(md);

      expect(result.movedIds, {'FR-1', 'FR-4'});
      expect(result.ids, {'FR-1', 'FR-2', 'FR-3', 'FR-4', 'FR-5'});
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-071 - a document
    ///   with no section 4 yields no ids and says so.
    /// Path: unhappy (missing content)
    test('no section 4 gives an empty result', () {
      final result = parseSpecRequirements('# T\n\n## 3. Vocab\n\ntext\n');

      expect(result.requirements, isEmpty);
      expect(result.hasSection4, isFalse);
      expect(result.hasRequirementsTable, isFalse);
      expect(result.ids, isEmpty);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-071 - a section 4
    ///   without a table yields no ids, but is distinguished from none.
    /// Path: unhappy (missing content)
    test('section 4 without a table gives an empty result', () {
      final result = parseSpecRequirements('## 4. Requirements\n\nTBD\n');

      expect(result.requirements, isEmpty);
      expect(result.hasSection4, isTrue);
      expect(result.hasRequirementsTable, isFalse);
      expect(parseSpecRequirements('').hasSection4, isFalse);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-071 - an id on two
    ///   rows is reported once, sorted.
    /// Path: unhappy (state error)
    test('reports duplicate ids', () {
      const md = '''
## 4. Requirements

| Id | Requirement |
|---|---|
| FR-2 | a |
| FR-1 | b |
| FR-2 | c |
| FR-1 | d |
| FR-2 | e |
''';

      expect(parseSpecRequirements(md).duplicateIds, ['FR-1', 'FR-2']);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-071 - a heading
    ///   such as `## 40.` or a table in a fenced block is not section 4.
    /// Path: unhappy (boundary)
    test('section 40 and fenced tables are not section 4', () {
      const md = '''
## 40. Other

| Id | Text |
|---|---|
| FR-1 | a |

## 4. Requirements

```
| Id | Text |
|---|---|
| FR-2 | b |
```
''';

      final result = parseSpecRequirements(md);

      expect(result.ids, isEmpty);
      expect(result.hasSection4, isTrue);
    });
  });

  /// Requirement: doc/specs/architecture-guardrails.md FR-071 - the numeric
  ///   part of an id orders ids.
  /// Path: happy
  group('frNumber', () {
    /// Requirement: doc/specs/architecture-guardrails.md FR-071 - leading
    ///   zeros are numeric padding.
    /// Path: happy
    test('reads the number of an id', () {
      expect(frNumber('FR-012'), 12);
      expect(frNumber('FR-7'), 7);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-071 - text that is
    ///   not an id is rejected.
    /// Path: unhappy (invalid input)
    test('rejects text that is not an id', () {
      expect(() => frNumber('FR-'), throwsArgumentError);
      expect(() => frNumber('fr-1'), throwsArgumentError);
      expect(() => frNumber('FR-1a'), throwsArgumentError);
    });
  });

  /// Requirement: doc/specs/architecture-guardrails.md FR-070 - the citation
  ///   grammar: spec path, then ids joined by commas, `and` or `&`.
  /// Path: happy
  group('parseCitations', () {
    /// Requirement: doc/specs/architecture-guardrails.md FR-070 - one id.
    /// Path: happy
    test('reads a single citation', () {
      final cites = parseCitations(
        'doc/specs/d20-tests.md FR-012 - a total equal',
      );

      expect(cites, hasLength(1));
      expect(cites.single.specName, 'd20-tests');
      expect(cites.single.specPath, 'doc/specs/d20-tests.md');
      expect(cites.single.ids, ['FR-012']);
      expect(cites.single.ranges, isEmpty);
      expect(cites.single.line, 1);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-070 - ids
    ///   separated by commas, `and` and `&`.
    /// Path: happy
    test('reads ids joined by comma, and, ampersand', () {
      final cites = parseCitations(
        'doc/specs/a.md FR-1, FR-2 and FR-3 & FR-4,FR-5 (note) FR-6',
      );

      expect(cites.single.ids, ['FR-1', 'FR-2', 'FR-3', 'FR-4', 'FR-5']);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-070 - the run ends
    ///   at other text.
    /// Path: happy
    test('stops at prose', () {
      final cites = parseCitations('doc/specs/a.md FR-1 for x, FR-2 for y');

      expect(cites.single.ids, ['FR-1']);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-070 - several
    ///   citations in one text, each with its own line.
    /// Path: happy
    test('reads several citations with their lines', () {
      final cites = parseCitations(
        'doc/specs/a.md FR-1\nand doc/specs/b.md FR-2, FR-3',
        firstLine: 10,
      );

      expect(cites.map((c) => c.specName), ['a', 'b']);
      expect(cites.map((c) => c.ids), [
        ['FR-1'],
        ['FR-2', 'FR-3'],
      ]);
      expect(cites.map((c) => c.line), [10, 11]);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-070 - a citation
    ///   may wrap over lines between ids.
    /// Path: happy
    test('an id list may wrap onto the next line', () {
      final cites = parseCitations('doc/specs/a.md FR-1,\nFR-2 and\nFR-3');

      expect(cites.single.ids, ['FR-1', 'FR-2', 'FR-3']);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-054 - a range in
    ///   any of the three forms is recorded so the check can flag it.
    /// Path: unhappy (invalid input)
    test('records ranges in every form', () {
      final to = parseCitations('doc/specs/a.md FR-1 to FR-3').single;
      final dash = parseCitations('doc/specs/a.md FR-1-FR-3').single;
      final dots = parseCitations('doc/specs/a.md FR-1..3').single;
      final dotsFr = parseCitations('doc/specs/a.md FR-1..FR-3').single;

      expect(to.ranges, ['FR-1 to FR-3']);
      expect(dash.ranges, ['FR-1-FR-3']);
      expect(dots.ranges, ['FR-1..3']);
      expect(dotsFr.ranges, ['FR-1..FR-3']);
      for (final c in [to, dash, dots, dotsFr]) {
        expect(c.ids, ['FR-1', 'FR-3']);
      }
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-070 - a range may
    ///   be followed by more ids.
    /// Path: unhappy (invalid input)
    test('a range may continue into a list', () {
      final cite = parseCitations('doc/specs/a.md FR-1 to FR-3, FR-9').single;

      expect(cite.ranges, ['FR-1 to FR-3']);
      expect(cite.ids, ['FR-1', 'FR-3', 'FR-9']);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-070 - a file with
    ///   no id after it is kept with no ids.
    /// Path: unhappy (missing content)
    test('a spec path with no id has empty ids', () {
      final cite = parseCitations('doc/specs/a.md - nothing').single;

      expect(cite.ids, isEmpty);
      expect(cite.ranges, isEmpty);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-070 - text with
    ///   no spec path, or a bare file name, cites nothing.
    /// Path: unhappy (missing content)
    test('text without a doc/specs path cites nothing', () {
      expect(parseCitations('FR-1 only'), isEmpty);
      expect(parseCitations('a.md FR-1'), isEmpty);
      expect(parseCitations('doc/specs/A.md FR-1'), isEmpty);
      expect(parseCitations('doc/rules/testing.md FR-1'), isEmpty);
      expect(parseCitations(''), isEmpty);
    });
  });

  /// Requirement: doc/specs/architecture-guardrails.md FR-070 - citations are
  ///   found in Requirement: comments and requirement: fields.
  /// Path: happy
  group('parseRequirementTexts', () {
    /// Requirement: doc/specs/architecture-guardrails.md FR-070 - a
    ///   Requirement: doc comment.
    /// Path: happy
    test('reads a Requirement: comment', () {
      const source = '''
void main() {
  /// Requirement: doc/specs/a.md FR-1 - one.
  /// Path: happy
  test('x', () {});
}
''';

      final texts = parseRequirementTexts(source);

      expect(texts, hasLength(1));
      expect(texts.single.source, RequirementSource.comment);
      expect(texts.single.line, 2);
      expect(texts.single.citations.single.ids, ['FR-1']);
      expect(texts.single.citations.single.line, 2);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-070 - ids on a
    ///   `///   ` continuation line count.
    /// Path: happy
    test('reads ids on continuation lines', () {
      const source = '''
/// Requirement: doc/specs/a.md FR-1,
///   FR-2 and doc/specs/b.md
///   FR-3 - paraphrase.
/// Path: happy
void f() {}
''';

      final cites = parseRequirementTexts(source).single.citations;

      expect(cites.map((c) => c.specName), ['a', 'b']);
      expect(cites[0].ids, ['FR-1', 'FR-2']);
      expect(cites[1].ids, ['FR-3']);
      expect(cites[1].line, 2);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-070 - the
    ///   continuation stops at the next field and at a gap.
    /// Path: unhappy (boundary)
    test('a continuation ends at the next field or a blank line', () {
      const source = '''
/// Requirement: doc/specs/a.md FR-1 - x
/// Path: unhappy (boundary)
///   doc/specs/b.md FR-2
void f() {}

/// Requirement: doc/specs/a.md FR-3 - y

///   doc/specs/b.md FR-4
void g() {}

/// Requirement: doc/specs/a.md FR-5 - z
///  doc/specs/b.md FR-6 (two spaces only)
void h() {}
''';

      final texts = parseRequirementTexts(source);

      expect(texts.map((t) => t.citations.map((c) => c.ids).expand((i) => i)), [
        ['FR-1'],
        ['FR-3'],
        ['FR-5'],
      ]);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-070 - ids in a
    ///   requirement: string field count like comment ids.
    /// Path: happy
    test('reads a requirement: field', () {
      const source = '''
final rows = [
  (
    label: 'a',
    requirement: 'doc/specs/ability-scores.md FR-012, FR-015 (SRD p. 6)',
    path: 'happy',
  ),
];
''';

      final texts = parseRequirementTexts(source);

      expect(texts, hasLength(1));
      expect(texts.single.source, RequirementSource.field);
      expect(texts.single.line, 4);
      expect(texts.single.citations.single.ids, ['FR-012', 'FR-015']);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-070 - adjacent
    ///   literals of a field are one string, even on a new line.
    /// Path: happy
    test('joins adjacent string literals of a field', () {
      const source = '''
final r = (
  requirement:
      'doc/specs/a.md '
      "FR-1 and FR-2",
  label: 'FR-9',
);
''';

      final texts = parseRequirementTexts(source);

      expect(texts, hasLength(1));
      expect(texts.single.citations.single.ids, ['FR-1', 'FR-2']);
      expect(texts.single.text, 'doc/specs/a.md FR-1 and FR-2');
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-070 - a field
    ///   without the grammar is returned with no citations.
    /// Path: unhappy (missing content)
    test('a field with a bare file name cites nothing', () {
      const source = "final r = (requirement: 'dice-and-rolls.md FR-002');";

      final texts = parseRequirementTexts(source);

      expect(texts.single.citations, isEmpty);
      expect(texts.single.text, 'dice-and-rolls.md FR-002');
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-070 - only the
    ///   Requirement: comment and the requirement: field are scanned.
    /// Path: unhappy (invalid input)
    test('ignores other comments, strings and similar names', () {
      const source = '''
// Requirement: doc/specs/a.md FR-1
/// Note: doc/specs/a.md FR-2
/* Requirement: doc/specs/a.md FR-3 */
final s = 'Requirement: doc/specs/a.md FR-4';
final t = (myrequirement: 'doc/specs/a.md FR-5', other: 'doc/specs/a.md FR-6');
''';

      expect(parseRequirementTexts(source), isEmpty);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-054 - a range in a
    ///   comment is recorded for the check.
    /// Path: unhappy (invalid input)
    test('records a range in a comment', () {
      const source =
          '/// Requirement: doc/specs/a.md FR-1 to FR-3\nvoid f() {}\n';

      final cite = parseRequirementTexts(source).single.citations.single;

      expect(cite.ranges, ['FR-1 to FR-3']);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-011 - results are
    ///   in source order and repeatable.
    /// Path: unhappy (determinism)
    test('returns comments and fields in source order, repeatably', () {
      const source = '''
final a = (requirement: 'doc/specs/a.md FR-1');
/// Requirement: doc/specs/a.md FR-2
void f() {}
final b = (requirement: 'doc/specs/a.md FR-3');
''';

      List<int> lines() => [
        for (final t in parseRequirementTexts(source)) t.line,
      ];

      expect(lines(), [1, 2, 4]);
      expect(lines(), lines());
    });
  });
}
