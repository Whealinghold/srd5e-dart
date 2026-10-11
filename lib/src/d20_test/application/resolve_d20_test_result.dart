import 'package:meta/meta.dart';

import '../../shared_kernel/ability/ability.dart';
import '../domain/attack_roll_result.dart';
import '../domain/check_result.dart';
import '../domain/difficulty_class.dart';
import '../domain/forced_failure_result.dart';

/// The output of `ResolveD20Test`: the resolved outcome of one D20 Test,
/// carrying the whole breakdown without recomputation ("D20 Tests",
/// SRD 5.2.1, p. 6).
///
/// The class is sealed with exactly the three operation-prefixed variants, so
/// a consumer's exhaustive `switch` fails to compile when a variant is added.
/// Each variant is an immutable value object holding the command's [ability]
/// label and the domain result of the kind it rolled: a [CheckResult] for a
/// rolled check or save, an `AttackRollResult` for a rolled attack roll, and a
/// [ForcedFailureResult] for a failure without a roll. The target number is
/// typed by variant (no union type): the check and forced-failure variants
/// carry the `DifficultyClass` the command carried, the attack variant the
/// `ArmorClass` — read it from the domain result's `target` field.
@immutable
sealed class ResolveD20TestResult {
  /// Creates a result for [ability].
  const ResolveD20TestResult(this.ability);

  /// The command's ability label, carried through unchanged.
  final Ability ability;
}

/// The outcome of a rolled ability check or saving throw: the [result] holds
/// the kind, the `D20Roll` (mode, dice in request order, natural, kept index),
/// the `RollModifiers`, the total, the `DifficultyClass` and the outcome.
@immutable
final class ResolveD20TestRolledCheck extends ResolveD20TestResult {
  /// Creates a rolled check or save result.
  const ResolveD20TestRolledCheck(super.ability, {required this.result});

  /// The resolved check or save, with the whole breakdown.
  final CheckResult result;

  @override
  bool operator ==(Object other) =>
      other is ResolveD20TestRolledCheck &&
      other.ability == ability &&
      other.result == result;

  @override
  int get hashCode => Object.hash(ResolveD20TestRolledCheck, ability, result);
}

/// The outcome of a rolled attack roll: the [result] holds the `D20Roll`, the
/// `RollModifiers`, the total, the `ArmorClass`, the outcome,
/// `isCriticalHit` and `criticalRange`, and reads `hit` as
/// `outcome == success`.
@immutable
final class ResolveD20TestRolledAttack extends ResolveD20TestResult {
  /// Creates a rolled attack roll result.
  const ResolveD20TestRolledAttack(super.ability, {required this.result});

  /// The resolved attack roll, with the whole breakdown.
  final AttackRollResult result;

  @override
  bool operator ==(Object other) =>
      other is ResolveD20TestRolledAttack &&
      other.ability == ability &&
      other.result == result;

  @override
  int get hashCode => Object.hash(ResolveD20TestRolledAttack, ability, result);
}

/// The outcome of a check or saving throw failed without a roll: the [result]
/// holds the kind and the `ForcedFailureReason`, and the [target] is the
/// `DifficultyClass` the command carried (a test failed on purpose still
/// names what it would have been compared with).
@immutable
final class ResolveD20TestForcedFailure extends ResolveD20TestResult {
  /// Creates a forced-failure result.
  const ResolveD20TestForcedFailure(
    super.ability, {
    required this.result,
    required this.target,
  });

  /// The forced failure, with its kind and reason.
  final ForcedFailureResult result;

  /// The Difficulty Class the test would have been compared with.
  final DifficultyClass target;

  @override
  bool operator ==(Object other) =>
      other is ResolveD20TestForcedFailure &&
      other.ability == ability &&
      other.result == result &&
      other.target == target;

  @override
  int get hashCode =>
      Object.hash(ResolveD20TestForcedFailure, ability, result, target);
}
