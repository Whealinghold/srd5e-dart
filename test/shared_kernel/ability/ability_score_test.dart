import 'package:srd5e/src/shared_kernel/ability/ability_score.dart';
import 'package:srd5e/src/shared_kernel/ability/ability_score_result.dart';
import 'package:test/test.dart';

import '../../support/argument_error_matcher.dart';
import '../../support/operator_equals.dart';

/// The largest integer that is exact on every platform.
const int _safeInteger = 9007199254740991;

typedef _Case = ({
  String label,
  String requirement,
  String path,
  int value,
  AbilityScoreRejection? rejection,
});

/// Every input of the construction table: accepted when [_Case.rejection] is
/// null, rejected with that reason otherwise.
const List<_Case> _inputs = [
  (
    label: 'zero',
    requirement: 'doc/specs/ability-scores.md FR-005, FR-009 (SRD 5.2.1, p. 5)',
    path: 'unhappy (boundary)',
    value: 0,
    rejection: AbilityScoreRejection.belowMinimum,
  ),
  (
    label: 'one, the lowest score',
    requirement: 'doc/specs/ability-scores.md FR-003 (SRD 5.2.1, p. 5)',
    path: 'unhappy (boundary)',
    value: 1,
    rejection: null,
  ),
  (
    label: 'thirty, the highest score',
    requirement: 'doc/specs/ability-scores.md FR-004 (SRD 5.2.1, p. 5)',
    path: 'unhappy (boundary)',
    value: 30,
    rejection: null,
  ),
  (
    label: 'thirty-one',
    requirement: 'doc/specs/ability-scores.md FR-006, FR-010 (SRD 5.2.1, p. 5)',
    path: 'unhappy (boundary)',
    value: 31,
    rejection: AbilityScoreRejection.aboveMaximum,
  ),
  (
    label: 'minus one',
    requirement: 'doc/specs/ability-scores.md FR-007, FR-009 (SRD 5.2.1, p. 5)',
    path: 'unhappy (invalid input)',
    value: -1,
    rejection: AbilityScoreRejection.belowMinimum,
  ),
  (
    label: 'the smallest safe integer',
    requirement: 'doc/specs/ability-scores.md FR-007, FR-029 (integer extreme)',
    path: 'unhappy (invalid input)',
    value: -_safeInteger,
    rejection: AbilityScoreRejection.belowMinimum,
  ),
  (
    label: 'the largest safe integer',
    requirement: 'doc/specs/ability-scores.md FR-006, FR-029 (integer extreme)',
    path: 'unhappy (invalid input)',
    value: _safeInteger,
    rejection: AbilityScoreRejection.aboveMaximum,
  ),
];

/// The inputs the constructor must reject, derived from [_inputs] so the
/// constructor table and the `tryCreate` table cannot drift apart.
final List<_Case> _rejected = [
  for (final c in _inputs)
    if (c.rejection != null) c,
];

/// The inputs the constructor must accept.
final List<_Case> _accepted = [
  for (final c in _inputs)
    if (c.rejection == null) c,
];

/// Every score the SRD allows: 1 to 30.
final List<int> _allScores = List.generate(30, (i) => i + 1);

void main() {
  /// Requirement: doc/specs/ability-scores.md FR-002, FR-003, FR-004 - every
  ///   integer from 1 to 30 is an AbilityScore and `value` round-trips; the
  ///   bounds 1 and 30 are accepted (SRD 5.2.1, "Ability Scores", p. 5).
  /// Path: happy
  group('AbilityScore accepts', () {
    /// Requirement: per case - doc/specs/ability-scores.md FR-002 - the score
    ///   is exposed as `value` (SRD 5.2.1, "Ability Scores", p. 5).
    /// Path: per case
    for (final n in _allScores) {
      test('$n is a score and value returns $n [happy]', () {
        expect(AbilityScore(n).value, n);
      });
    }

    /// Requirement: per case
    /// Path: per case
    for (final c in _accepted) {
      test('${c.label} [${c.path}]', () {
        expect(AbilityScore(c.value).value, c.value);
      });
    }
  });

  /// Requirement: doc/specs/ability-scores.md FR-005, FR-006, FR-007, FR-028
  ///   - an out-of-range score is a programmer error carrying the argument
  ///   name and the rejected integer (SRD 5.2.1, "Ability Scores",
  ///   p. 5).
  /// Path: unhappy (invalid input)
  group('AbilityScore rejects', () {
    /// Requirement: per case
    /// Path: per case
    for (final c in _rejected) {
      test('${c.label} [${c.path}]', () {
        expect(
          () => AbilityScore(c.value),
          throwsArgumentErrorFor('value', c.value),
        );
      });
    }
  });

  /// Requirement: doc/specs/ability-scores.md FR-025 - the bounds are public
  ///   constants other contexts reuse (SRD 5.2.1, "Ability Scores", p. 5).
  /// Path: happy
  group('AbilityScore bounds', () {
    /// Requirement: doc/specs/ability-scores.md FR-025 - minimum is 1.
    /// Path: happy
    test('minimum is 1', () {
      expect(AbilityScore.minimum, 1);
    });

    /// Requirement: doc/specs/ability-scores.md FR-025 - maximum is 30.
    /// Path: happy
    test('maximum is 30', () {
      expect(AbilityScore.maximum, 30);
    });
  });

  /// Requirement: doc/specs/ability-scores.md FR-008 - tryCreate returns a
  ///   ValidAbilityScore for every integer from 1 to 30 (SRD 5.2.1, "Ability
  ///   Scores", p. 5).
  /// Path: happy
  group('AbilityScore.tryCreate accepts', () {
    /// Requirement: per case - doc/specs/ability-scores.md FR-008 - the valid
    ///   result holds the same score as the constructor.
    /// Path: per case
    for (final n in _allScores) {
      test('$n gives a ValidAbilityScore holding AbilityScore($n) [happy]', () {
        expect(AbilityScore.tryCreate(n), ValidAbilityScore(AbilityScore(n)));
      });
    }
  });

  /// Requirement: doc/specs/ability-scores.md FR-009, FR-010, FR-029 and
  ///   FR-030 - tryCreate never throws and rejects exactly the inputs the
  ///   constructor rejects, with the rejected integer and a typed reason
  ///   (SRD 5.2.1, "Ability Scores", p. 5).
  /// Path: unhappy (invalid input)
  group('AbilityScore.tryCreate rejects', () {
    /// Requirement: per case
    /// Path: per case
    for (final c in _rejected) {
      test('${c.label} with ${c.rejection?.name} [${c.path}]', () {
        expect(
          AbilityScore.tryCreate(c.value),
          InvalidAbilityScore(c.value, c.rejection!),
        );
      });
    }
  });

  /// Requirement: doc/specs/ability-scores.md FR-030 - tryCreate(n) is an
  ///   InvalidAbilityScore if and only if AbilityScore(n) throws.
  /// Path: unhappy (rule conflict)
  group('AbilityScore.tryCreate agrees with the constructor', () {
    /// Requirement: per case
    /// Path: per case
    for (final c in _inputs) {
      test('${c.label} [${c.path}]', () {
        final result = AbilityScore.tryCreate(c.value);
        final constructorThrows = _throws(() => AbilityScore(c.value));

        expect(result is InvalidAbilityScore, constructorThrows);
      });
    }
  });

  /// Requirement: doc/specs/ability-scores.md FR-011 - AbilityScore is a value
  ///   object: equal values are equal with equal hash codes, different values
  ///   are not (doc/rules/architecture.md section 3).
  /// Path: happy
  group('AbilityScore equality', () {
    /// Requirement: doc/specs/ability-scores.md FR-011 - same value, equal and
    ///   same hash code, including one built by tryCreate.
    /// Path: happy
    test('same value is equal with an equal hash code', () {
      final a = AbilityScore(14);
      final b = AbilityScore(14);

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    /// Requirement: doc/specs/ability-scores.md FR-011 - different values are
    ///   not equal, including neighbours.
    /// Path: unhappy (boundary)
    test('neighbouring values are not equal', () {
      expect(AbilityScore(14), isNot(equals(AbilityScore(15))));
    });

    /// Requirement: doc/specs/ability-scores.md FR-011 - a score is not equal to
    ///   the integer it wraps.
    /// Path: unhappy (invalid input)
    test('is not equal to the bare integer', () {
      expect(operatorEquals(AbilityScore(14), 14), isFalse);
      expect(operatorEquals(14, AbilityScore(14)), isFalse);
    });
  });

  /// Requirement: none - pins the debugging form, which is not display text
  ///   and is not part of the specification.
  /// Path: happy
  test('toString names the type and value', () {
    expect(AbilityScore(14).toString(), 'AbilityScore(14)');
  });
}

bool _throws(void Function() action) {
  try {
    action();
    return false;
  } on ArgumentError {
    return true;
  }
}
