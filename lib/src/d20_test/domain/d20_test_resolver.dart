import 'package:meta/meta.dart';

import 'armor_class.dart';
import 'attack_roll_result.dart';
import 'check_result.dart';
import 'd20_roll.dart';
import 'd20_test_kind.dart';
import 'd20_test_outcome.dart';
import 'difficulty_class.dart';
import 'forced_failure_reason.dart';
import 'forced_failure_result.dart';
import 'roll_modifiers.dart';

/// The pure domain service that resolves a D20 Test ("D20 Tests",
/// SRD 5.2.1, p. 6): the d20 number the roll keeps plus the modifiers is
/// compared with the target number, and the test succeeds or fails.
///
/// It is stateless and takes no port, no observability and no dice: every
/// call depends only on its arguments, so one `const` instance serves every
/// call. Use cases compose it and record their own signals from its results;
/// the results' published static members (`CheckResult.resolve`,
/// `AttackRollResult.resolve`, `ForcedFailureResult.of`) delegate to it and
/// behave identically.
///
/// The natural 20 and natural 1 rules of "Rolling 20 or 1" (SRD 5.2.1, p. 7)
/// apply to attack rolls only: `resolveAttackRoll` judges them on the roll's
/// current natural value, whatever a reroll or adjustment did, and
/// `resolveCheck` compares the total with the Difficulty Class alone.
@immutable
final class D20TestResolver {
  /// The natural d20 number that hits regardless of modifiers and is a
  /// Critical Hit ("Rolling 20 or 1", SRD 5.2.1, p. 7).
  static const int _naturalTwenty = 20;

  /// The natural d20 number that misses regardless of modifiers ("Rolling
  /// 20 or 1", SRD 5.2.1, p. 7).
  static const int _naturalOne = 1;

  /// The lowest critical range the SRD grants ("Level 3: Improved Critical",
  /// SRD 5.2.1, p. 49: a Critical Hit on a 18-20), so a wider range is a
  /// caller bug.
  static const int _lowestCriticalRange = 18;

  /// The highest critical range: the default, a natural 20 only (p. 7).
  static const int _highestCriticalRange = 20;

  /// Creates the resolver.
  const D20TestResolver();

  /// Resolves an ability check or a saving throw ([kind]) of [roll] with
  /// [modifiers] against the Difficulty Class [target].
  ///
  /// The outcome is `success` when the total (the roll's natural value plus
  /// the modifiers' kernel sum, with no clamping) equals or exceeds the DC,
  /// and `failure` otherwise — whatever the natural value, since the natural
  /// 20 and natural 1 rules hold "for an attack roll" only (SRD 5.2.1,
  /// p. 7).
  ///
  /// Throws an [ArgumentError] carrying the name `kind` and the kind when
  /// [kind] is `attackRoll`: an attack roll is resolved against an
  /// `ArmorClass` by [resolveAttackRoll], and a DC cannot be paired with it.
  CheckResult resolveCheck(
    D20TestKind kind,
    D20Roll roll,
    RollModifiers modifiers,
    DifficultyClass target,
  ) {
    if (kind == D20TestKind.attackRoll) {
      throw ArgumentError.value(kind, 'kind');
    }
    final total = modifiers.total.applyTo(roll.natural);
    final outcome = total >= target.value
        ? D20TestOutcome.success
        : D20TestOutcome.failure;
    return CheckResult(
      kind: kind,
      roll: roll,
      modifiers: modifiers,
      total: total,
      target: target,
      outcome: outcome,
    );
  }

  /// Resolves an attack roll of [roll] with [modifiers] against the Armor
  /// Class [target].
  ///
  /// A natural 20 hits and is a Critical Hit regardless of modifiers or the
  /// AC, and a natural 1 misses regardless of them ("Rolling 20 or 1",
  /// SRD 5.2.1, p. 7) — both judged on the roll's natural value, the die the
  /// mode keeps. Any other natural value at or above [criticalRange] is a
  /// Critical Hit that hits regardless of modifiers or the AC; below it, the
  /// total is compared with the AC (`success` when it equals or exceeds the
  /// AC, `failure` otherwise), never a Critical Hit.
  ///
  /// [criticalRange] defaults to 20 (a natural 20 only). It must be 18, 19
  /// or 20 — 18-20 is the lowest range the SRD grants ("Level 3: Improved
  /// Critical", SRD 5.2.1, p. 49) — and any other value throws an
  /// [ArgumentError] carrying the name `criticalRange` and the value.
  AttackRollResult resolveAttackRoll(
    D20Roll roll,
    RollModifiers modifiers,
    ArmorClass target, {
    int criticalRange = _highestCriticalRange,
  }) {
    if (criticalRange < _lowestCriticalRange ||
        criticalRange > _highestCriticalRange) {
      throw ArgumentError.value(criticalRange, 'criticalRange');
    }
    final total = modifiers.total.applyTo(roll.natural);
    final bool isCriticalHit;
    final D20TestOutcome outcome;
    if (roll.natural == _naturalTwenty) {
      isCriticalHit = true;
      outcome = D20TestOutcome.success;
    } else if (roll.natural == _naturalOne) {
      isCriticalHit = false;
      outcome = D20TestOutcome.failure;
    } else if (roll.natural >= criticalRange) {
      isCriticalHit = true;
      outcome = D20TestOutcome.success;
    } else {
      isCriticalHit = false;
      outcome = total >= target.value
          ? D20TestOutcome.success
          : D20TestOutcome.failure;
    }
    return AttackRollResult(
      roll: roll,
      modifiers: modifiers,
      total: total,
      target: target,
      outcome: outcome,
      isCriticalHit: isCriticalHit,
      criticalRange: criticalRange,
    );
  }

  /// Resolves the failure of a check or saving throw without a roll: a
  /// saving throw the creature chooses to fail ([ForcedFailureReason.chosenToFail])
  /// or an automatic failure the caller declares
  /// ([ForcedFailureReason.automatic]).
  ///
  /// Throws an [ArgumentError] carrying the name `kind` and the kind when
  /// [kind] is `attackRoll` — the SRD gives no rule for failing an attack
  /// roll without rolling — and the name `reason` and the reason when an
  /// ability check is given [ForcedFailureReason.chosenToFail]: the choice
  /// rule is stated for saving throws only ("Saving Throws",
  /// SRD 5.2.1, p. 7).
  ForcedFailureResult forcedFailure(
    D20TestKind kind,
    ForcedFailureReason reason,
  ) {
    if (kind == D20TestKind.attackRoll) {
      throw ArgumentError.value(kind, 'kind');
    }
    if (kind == D20TestKind.abilityCheck &&
        reason == ForcedFailureReason.chosenToFail) {
      throw ArgumentError.value(reason, 'reason');
    }
    return ForcedFailureResult(kind: kind, reason: reason);
  }
}
