import 'package:meta/meta.dart';

import '../../shared_kernel/ability/ability.dart';
import '../domain/armor_class.dart';
import '../domain/difficulty_class.dart';
import 'd20_test_attempts.dart';

/// The input of `ResolveD20Test`: one D20 Test of one kind, pairing its kind
/// with the target number that kind is compared with and the attempt that
/// resolves it ("D20 Tests", SRD 5.2.1, p. 6).
///
/// The class is sealed with exactly the three variants, so the pairing of kind
/// and target is enforced by the type: an [AbilityCheckCommand] and a
/// [SavingThrowCommand] carry a `DifficultyClass`, an [AttackRollCommand] an
/// `ArmorClass` — a DC cannot be paired with an attack roll, nor an AC with a
/// check or save, and an attack roll cannot be forced to fail. The [ability]
/// is a label for telemetry and the result only; the modifier summed is the
/// one inside the attempt's `RollModifiers`, and the caller keeps the two
/// consistent.
@immutable
sealed class D20TestCommand {
  /// Creates a command for [ability].
  const D20TestCommand(this.ability);

  /// The ability the test is made with, as the caller labels it: the
  /// lower-case name is the `srd5e.ability` telemetry value and is carried
  /// into the result. It is not read to compute anything.
  final Ability ability;
}

/// The command of an ability check ("Ability Checks", SRD 5.2.1, p. 6): the
/// total is compared with the Difficulty Class [target], and the attempt is a
/// [CheckAttempt] — a [RollAttempt] or an [AutomaticFailure].
@immutable
final class AbilityCheckCommand extends D20TestCommand {
  /// Creates an ability check command.
  const AbilityCheckCommand(
    super.ability, {
    required this.target,
    required this.attempt,
  });

  /// The Difficulty Class the total is compared with.
  final DifficultyClass target;

  /// How the check is attempted: rolling, or an automatic failure.
  final CheckAttempt attempt;

  @override
  bool operator ==(Object other) =>
      other is AbilityCheckCommand &&
      other.ability == ability &&
      other.target == target &&
      other.attempt == attempt;

  @override
  int get hashCode => Object.hash(ability, target, attempt);
}

/// The command of a saving throw ("Saving Throws", SRD 5.2.1, p. 7): the
/// total is compared with the Difficulty Class [target], and the attempt is a
/// [SaveAttempt] — a [RollAttempt], a [ChooseToFail] or an [AutomaticFailure].
@immutable
final class SavingThrowCommand extends D20TestCommand {
  /// Creates a saving throw command.
  const SavingThrowCommand(
    super.ability, {
    required this.target,
    required this.attempt,
  });

  /// The Difficulty Class the total is compared with.
  final DifficultyClass target;

  /// How the save is attempted: rolling, choosing to fail, or an automatic
  /// failure.
  final SaveAttempt attempt;

  @override
  bool operator ==(Object other) =>
      other is SavingThrowCommand &&
      other.ability == ability &&
      other.target == target &&
      other.attempt == attempt;

  @override
  int get hashCode => Object.hash(ability, target, attempt);
}

/// The command of an attack roll ("Attack Rolls", SRD 5.2.1, p. 7): the total
/// is compared with the Armor Class [target] and the attempt always rolls, so
/// it is a [RollAttempt] — an attack roll cannot be forced to fail.
@immutable
final class AttackRollCommand extends D20TestCommand {
  /// Creates an attack roll command.
  const AttackRollCommand(
    super.ability, {
    required this.target,
    required this.attempt,
  });

  /// The Armor Class the total is compared with.
  final ArmorClass target;

  /// The rolling attempt of the attack.
  final RollAttempt attempt;

  @override
  bool operator ==(Object other) =>
      other is AttackRollCommand &&
      other.ability == ability &&
      other.target == target &&
      other.attempt == attempt;

  @override
  int get hashCode => Object.hash(ability, target, attempt);
}
