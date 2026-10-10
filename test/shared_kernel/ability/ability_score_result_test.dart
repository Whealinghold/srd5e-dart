import 'package:srd5e/src/shared_kernel/ability/ability_score.dart';
import 'package:srd5e/src/shared_kernel/ability/ability_score_result.dart';
import 'package:test/test.dart';

import '../../support/operator_equals.dart';

/// Names the variant of [result] with a switch that has no default branch: it
/// compiles only while the hierarchy is sealed and has exactly these variants.
String _variant(AbilityScoreResult result) => switch (result) {
  ValidAbilityScore() => 'valid',
  InvalidAbilityScore() => 'invalid',
};

void main() {
  /// Requirement: doc/specs/ability-scores.md FR-031 - AbilityScoreResult is
  ///   sealed with the two final variants ValidAbilityScore and
  ///   InvalidAbilityScore, so a consumer switches exhaustively
  ///   (doc/specs/errors-and-results.md FR-018).
  /// Path: happy
  group('AbilityScoreResult', () {
    /// Requirement: doc/specs/ability-scores.md FR-031 - a valid result is
    ///   matched by the ValidAbilityScore arm of an exhaustive switch.
    /// Path: happy
    test('a valid result is the valid variant', () {
      expect(_variant(AbilityScore.tryCreate(10)), 'valid');
    });

    /// Requirement: doc/specs/ability-scores.md FR-031 - an invalid result is
    ///   matched by the InvalidAbilityScore arm of an exhaustive switch.
    /// Path: unhappy (invalid input)
    test('an invalid result is the invalid variant', () {
      expect(_variant(AbilityScore.tryCreate(31)), 'invalid');
    });
  });

  /// Requirement: doc/specs/ability-scores.md section 5 - "All variants compare
  ///   by value" (doc/specs/errors-and-results.md FR-019).
  /// Path: happy
  group('ValidAbilityScore', () {
    /// Requirement: doc/specs/ability-scores.md FR-008 - `score` is the wrapped
    ///   AbilityScore.
    /// Path: happy
    test('exposes the score', () {
      expect(ValidAbilityScore(AbilityScore(18)).score, AbilityScore(18));
    });

    /// Requirement: doc/specs/ability-scores.md section 5 - equal scores give
    ///   equal results with equal hash codes.
    /// Path: happy
    test('same score is equal with an equal hash code', () {
      final a = ValidAbilityScore(AbilityScore(18));
      final b = ValidAbilityScore(AbilityScore(18));

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    /// Requirement: doc/specs/ability-scores.md section 5 - different scores
    ///   are not equal.
    /// Path: unhappy (boundary)
    test('different scores are not equal', () {
      expect(
        ValidAbilityScore(AbilityScore(18)),
        isNot(equals(ValidAbilityScore(AbilityScore(19)))),
      );
    });

    /// Requirement: none - pins the debugging form, which is not display text.
    /// Path: happy
    test('toString names the variant and score', () {
      expect(
        ValidAbilityScore(AbilityScore(18)).toString(),
        'ValidAbilityScore(AbilityScore(18))',
      );
    });
  });

  /// Requirement: doc/specs/ability-scores.md section 5 - "All variants compare
  ///   by value" (doc/specs/errors-and-results.md FR-019).
  /// Path: happy
  group('InvalidAbilityScore', () {
    /// Requirement: doc/specs/ability-scores.md FR-009 and FR-010 - `value` is
    ///   the rejected integer and `reason` the typed rejection.
    /// Path: happy
    test('exposes the rejected value and the reason', () {
      const result = InvalidAbilityScore(
        40,
        AbilityScoreRejection.aboveMaximum,
      );

      expect(result.value, 40);
      expect(result.reason, AbilityScoreRejection.aboveMaximum);
    });

    /// Requirement: doc/specs/ability-scores.md section 5 - the same value and
    ///   reason are equal with an equal hash code.
    /// Path: happy
    test('same value and reason are equal with an equal hash code', () {
      const a = InvalidAbilityScore(0, AbilityScoreRejection.belowMinimum);
      const b = InvalidAbilityScore(0, AbilityScoreRejection.belowMinimum);

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    /// Requirement: doc/specs/ability-scores.md section 5 - a different value
    ///   is not equal.
    /// Path: unhappy (boundary)
    test('a different value is not equal', () {
      expect(
        const InvalidAbilityScore(0, AbilityScoreRejection.belowMinimum),
        isNot(
          equals(
            const InvalidAbilityScore(-1, AbilityScoreRejection.belowMinimum),
          ),
        ),
      );
    });

    /// Requirement: doc/specs/ability-scores.md section 5 - a different reason
    ///   is not equal.
    /// Path: unhappy (boundary)
    test('a different reason is not equal', () {
      expect(
        const InvalidAbilityScore(0, AbilityScoreRejection.belowMinimum),
        isNot(
          equals(
            const InvalidAbilityScore(0, AbilityScoreRejection.aboveMaximum),
          ),
        ),
      );
    });

    /// Requirement: doc/specs/ability-scores.md section 5 - an invalid and a
    ///   valid result are never equal.
    /// Path: unhappy (rule conflict)
    test('is not equal to a valid result', () {
      const invalid = InvalidAbilityScore(
        0,
        AbilityScoreRejection.belowMinimum,
      );
      final valid = ValidAbilityScore(AbilityScore(1));

      expect(operatorEquals(invalid, valid), isFalse);
      expect(operatorEquals(valid, invalid), isFalse);
    });

    /// Requirement: none - pins the debugging form, which is not display text.
    /// Path: happy
    test('toString names the variant, value and reason', () {
      expect(
        const InvalidAbilityScore(
          31,
          AbilityScoreRejection.aboveMaximum,
        ).toString(),
        'InvalidAbilityScore(31, aboveMaximum)',
      );
    });
  });

  /// Requirement: doc/specs/ability-scores.md FR-026 - AbilityScoreRejection
  ///   has exactly the values belowMinimum and aboveMaximum.
  /// Path: happy
  test('AbilityScoreRejection has the two values', () {
    expect(AbilityScoreRejection.values, [
      AbilityScoreRejection.belowMinimum,
      AbilityScoreRejection.aboveMaximum,
    ]);
  });
}
