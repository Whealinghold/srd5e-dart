import 'package:srd5e/srd5e.dart';
import 'package:test/test.dart';

import '../../support/operator_equals.dart';

typedef _Band = ({
  String label,
  String requirement,
  String path,
  List<int> scores,
  int modifier,
});

/// The Ability Modifiers table, SRD 5.2.1, p. 6, one row per band. The table
/// is the sole authority; no formula is used to build these rows.
const List<_Band> _table = [
  (
    label: 'lowest score',
    requirement: 'doc/specs/ability-scores.md FR-012, FR-015 (SRD 5.2.1, p. 6)',
    path: 'unhappy (boundary)',
    scores: [1],
    modifier: -5,
  ),
  (
    label: 'band 2-3',
    requirement: 'doc/specs/ability-scores.md FR-012 (SRD 5.2.1, p. 6)',
    path: 'happy',
    scores: [2, 3],
    modifier: -4,
  ),
  (
    label: 'band 4-5',
    requirement: 'doc/specs/ability-scores.md FR-012 (SRD 5.2.1, p. 6)',
    path: 'happy',
    scores: [4, 5],
    modifier: -3,
  ),
  (
    label: 'band 6-7',
    requirement: 'doc/specs/ability-scores.md FR-012 (SRD 5.2.1, p. 6)',
    path: 'happy',
    scores: [6, 7],
    modifier: -2,
  ),
  (
    label: 'band 8-9',
    requirement: 'doc/specs/ability-scores.md FR-012, FR-013 (SRD 5.2.1, p. 6)',
    path: 'unhappy (boundary)',
    scores: [8, 9],
    modifier: -1,
  ),
  (
    label: 'human average',
    requirement: 'doc/specs/ability-scores.md FR-012, FR-014 (SRD 5.2.1, p. 6)',
    path: 'unhappy (boundary)',
    scores: [10, 11],
    modifier: 0,
  ),
  (
    label: 'band 12-13',
    requirement: 'doc/specs/ability-scores.md FR-012 (SRD 5.2.1, p. 6)',
    path: 'happy',
    scores: [12, 13],
    modifier: 1,
  ),
  (
    label: 'band 14-15',
    requirement: 'doc/specs/ability-scores.md FR-012 (SRD 5.2.1, p. 6)',
    path: 'happy',
    scores: [14, 15],
    modifier: 2,
  ),
  (
    label: 'band 16-17',
    requirement: 'doc/specs/ability-scores.md FR-012 (SRD 5.2.1, p. 6)',
    path: 'happy',
    scores: [16, 17],
    modifier: 3,
  ),
  (
    label: 'band 18-19',
    requirement: 'doc/specs/ability-scores.md FR-012 (SRD 5.2.1, p. 6)',
    path: 'happy',
    scores: [18, 19],
    modifier: 4,
  ),
  (
    label: 'band 20-21',
    requirement: 'doc/specs/ability-scores.md FR-012 (SRD 5.2.1, p. 6)',
    path: 'happy',
    scores: [20, 21],
    modifier: 5,
  ),
  (
    label: 'band 22-23',
    requirement: 'doc/specs/ability-scores.md FR-012 (SRD 5.2.1, p. 6)',
    path: 'happy',
    scores: [22, 23],
    modifier: 6,
  ),
  (
    label: 'band 24-25',
    requirement: 'doc/specs/ability-scores.md FR-012 (SRD 5.2.1, p. 6)',
    path: 'happy',
    scores: [24, 25],
    modifier: 7,
  ),
  (
    label: 'band 26-27',
    requirement: 'doc/specs/ability-scores.md FR-012 (SRD 5.2.1, p. 6)',
    path: 'happy',
    scores: [26, 27],
    modifier: 8,
  ),
  (
    label: 'band 28-29',
    requirement: 'doc/specs/ability-scores.md FR-012 (SRD 5.2.1, p. 6)',
    path: 'happy',
    scores: [28, 29],
    modifier: 9,
  ),
  (
    label: 'highest score',
    requirement: 'doc/specs/ability-scores.md FR-012 (SRD 5.2.1, p. 6)',
    path: 'unhappy (boundary)',
    scores: [30],
    modifier: 10,
  ),
];

typedef _Pair = ({
  String label,
  String requirement,
  String path,
  int score,
  int modifier,
  int truncated,
});

/// Odd scores below 10, where truncating division would differ from the table
/// (the truncated value is what `(score - 10) ~/ 2` would give).
const List<_Pair> _roundDown = [
  (
    label: 'score 1 gives -5, not -4',
    requirement: 'doc/specs/ability-scores.md FR-013, FR-015 (SRD 5.2.1, p. 6)',
    path: 'unhappy (rule interaction)',
    score: 1,
    modifier: -5,
    truncated: -4,
  ),
  (
    label: 'score 3 gives -4, not -3',
    requirement: 'doc/specs/ability-scores.md FR-013 (SRD 5.2.1, p. 6)',
    path: 'unhappy (rule interaction)',
    score: 3,
    modifier: -4,
    truncated: -3,
  ),
  (
    label: 'score 9 gives -1, not 0',
    requirement: 'doc/specs/ability-scores.md FR-013 (SRD 5.2.1, p. 6)',
    path: 'unhappy (rule interaction)',
    score: 9,
    modifier: -1,
    truncated: 0,
  ),
];

/// The modifier values of all scores 1 to 30, in score order.
final List<int> _allModifiers = [
  for (var score = 1; score <= 30; score++) AbilityScore(score).modifier.value,
];

void main() {
  /// Requirement: doc/specs/ability-scores.md FR-012 - the modifier of every
  ///   score from 1 to 30 is the Ability Modifiers table value (SRD 5.2.1,
  ///   "Ability Modifiers", p. 5, table p. 6).
  /// Path: happy
  group('AbilityScore.modifier follows the Ability Modifiers table', () {
    /// Requirement: per case
    /// Path: per case
    for (final band in _table) {
      for (final score in band.scores) {
        test('${band.label}: score $score gives ${band.modifier} '
            '[${band.path}]', () {
          expect(AbilityScore(score).modifier.value, band.modifier);
        });
      }
    }

    /// Requirement: doc/specs/ability-scores.md FR-012 - the table cases cover
    ///   each of the 30 scores exactly once, so no band row is missing.
    /// Path: unhappy (missing content)
    test('the table rows cover scores 1 to 30 exactly once', () {
      final covered = [for (final band in _table) ...band.scores];

      expect(covered, List.generate(30, (i) => i + 1));
    });
  });

  /// Requirement: doc/specs/ability-scores.md FR-013 - odd scores below 10 use
  ///   the table value (floor division), not the truncated one (SRD 5.2.1,
  ///   Ability Modifiers table, p. 6).
  /// Path: unhappy (rule interaction)
  group('AbilityScore.modifier rounds down below 10', () {
    /// Requirement: per case
    /// Path: per case
    for (final c in _roundDown) {
      test('${c.label} [${c.path}]', () {
        final modifier = AbilityScore(c.score).modifier.value;

        expect(modifier, c.modifier);
        expect(modifier, isNot(c.truncated));
      });
    }
  });

  /// Requirement: doc/specs/ability-scores.md FR-014 - score 10 gives +0, with
  ///   neighbours 9 giving -1, 11 giving +0 and 12 giving +1 (SRD 5.2.1,
  ///   Ability Modifiers table, p. 6).
  /// Path: unhappy (boundary)
  test('the modifier changes sign around score 10', () {
    final around = [
      for (final score in [9, 10, 11, 12]) AbilityScore(score).modifier.value,
    ];

    expect(around, [-1, 0, 0, 1]);
  });

  /// Requirement: doc/specs/ability-scores.md FR-015 - score 1 gives the lowest
  ///   modifier, -5, and 30 the highest, +10; no score gives one outside
  ///   -5 to +10 (SRD 5.2.1, Ability Modifiers table, p. 6).
  /// Path: unhappy (boundary)
  test('the modifiers of all 30 scores stay within -5 and +10', () {
    expect(_allModifiers.first, -5);
    expect(_allModifiers.last, 10);
    expect(_allModifiers, everyElement(inInclusiveRange(-5, 10)));
  });

  /// Requirement: doc/specs/ability-scores.md FR-012 - the modifier never goes
  ///   down as the score goes up (SRD 5.2.1, Ability Modifiers table, p. 6).
  /// Path: unhappy (rule interaction)
  test('the modifier never decreases as the score increases', () {
    final steps = [
      for (var i = 1; i < _allModifiers.length; i++)
        _allModifiers[i] - _allModifiers[i - 1],
    ];

    expect(steps, everyElement(inInclusiveRange(0, 1)));
  });

  /// Requirement: doc/specs/ability-scores.md FR-017 - AbilityModifier exposes
  ///   its signed integer `value` (SRD 5.2.1, "Ability Modifiers", p. 5;
  ///   "Ability Score and Modifier", p. 176).
  /// Path: happy
  group('AbilityModifier.value', () {
    /// Requirement: doc/specs/ability-scores.md FR-017 - a negative modifier
    ///   keeps its sign.
    /// Path: happy
    test('is -5 for score 1', () {
      expect(AbilityScore(1).modifier.value, -5);
    });

    /// Requirement: doc/specs/ability-scores.md FR-017 - a zero modifier.
    /// Path: happy
    test('is 0 for score 10', () {
      expect(AbilityScore(10).modifier.value, 0);
    });

    /// Requirement: doc/specs/ability-scores.md FR-017 - a positive modifier.
    /// Path: happy
    test('is 10 for score 30', () {
      expect(AbilityScore(30).modifier.value, 10);
    });
  });

  /// Requirement: doc/specs/ability-scores.md FR-016 - AbilityModifier is a
  ///   value object: equal values are equal with equal hash codes, different
  ///   values are not (doc/rules/architecture.md section 3).
  /// Path: happy
  group('AbilityModifier equality', () {
    /// Requirement: doc/specs/ability-scores.md FR-016 - two scores in the same
    ///   band give equal modifiers with equal hash codes.
    /// Path: happy
    test('modifiers of the same value are equal with equal hash codes', () {
      final a = AbilityScore(12).modifier;
      final b = AbilityScore(13).modifier;

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    /// Requirement: doc/specs/ability-scores.md FR-016 - modifiers of different
    ///   values are not equal, including across the zero boundary.
    /// Path: unhappy (boundary)
    test('modifiers of different values are not equal', () {
      expect(
        AbilityScore(10).modifier,
        isNot(equals(AbilityScore(12).modifier)),
      );
      expect(
        AbilityScore(9).modifier,
        isNot(equals(AbilityScore(10).modifier)),
      );
    });

    /// Requirement: doc/specs/ability-scores.md FR-016 and FR-027 - an
    ///   AbilityModifier is not a kernel Modifier of the same number.
    /// Path: unhappy (rule conflict)
    test('is not equal to a Modifier or an integer of the same number', () {
      final modifier = AbilityScore(12).modifier;

      expect(operatorEquals(modifier, const Modifier(1)), isFalse);
      expect(operatorEquals(const Modifier(1), modifier), isFalse);
      expect(operatorEquals(modifier, 1), isFalse);
    });
  });

  /// Requirement: doc/specs/ability-scores.md FR-027 - callers convert an
  ///   AbilityModifier to a Modifier with `Modifier(abilityModifier.value)`;
  ///   the two types are independent (SRD 5.2.1, "Ability Modifiers", p. 5).
  /// Path: happy
  test('Modifier(AbilityScore(20).modifier.value) is Modifier(5)', () {
    expect(Modifier(AbilityScore(20).modifier.value), const Modifier(5));
  });

  /// Requirement: none - pins the debugging form, which is not display text
  ///   and is not part of the specification.
  /// Path: happy
  test('toString names the type and value', () {
    expect(AbilityScore(8).modifier.toString(), 'AbilityModifier(-1)');
  });
}
