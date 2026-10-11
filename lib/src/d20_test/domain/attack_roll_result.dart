import 'package:meta/meta.dart';

import '../../shared_kernel/modifier.dart';
import 'armor_class.dart';
import 'd20_roll.dart';
import 'd20_test_outcome.dart';
import 'd20_test_resolver.dart';
import 'roll_modifiers.dart';

/// The outcome of one attack roll ("Attack Rolls", SRD 5.2.1, p. 7): the roll
/// it was made with, the modifiers added, the total and the Armor Class it
/// was compared with, whether it hit, and whether it was a Critical Hit.
///
/// It is an immutable value compared field by field. It carries everything a
/// consumer needs to render its own breakdown, and no separate roll-mode
/// field: the mode is `D20Roll.mode`. A Critical Hit is reported by
/// [isCriticalHit]; there is no basis enum and no separate critical-hit
/// outcome, and [outcome] is the shared `D20TestOutcome` of every kind.
@immutable
final class AttackRollResult {
  /// Resolves the attack [roll] with [modifiers] against the Armor Class
  /// [target], with the natural 20 and natural 1 rules of "Rolling 20 or 1"
  /// (SRD 5.2.1, p. 7) judged on the roll's current natural value.
  ///
  /// Published static delegate of `D20TestResolver.resolveAttackRoll` (the
  /// behaviour is identical): any `D20Roll` is accepted, including a rerolled
  /// or replaced one. [criticalRange] defaults to 20 and must be 18, 19 or
  /// 20 (SRD 5.2.1, p. 49), else an [ArgumentError] (name `criticalRange`).
  static AttackRollResult resolve(
    D20Roll roll,
    RollModifiers modifiers,
    ArmorClass target, {
    int criticalRange = 20,
  }) => const D20TestResolver().resolveAttackRoll(
    roll,
    modifiers,
    target,
    criticalRange: criticalRange,
  );

  /// Creates a result from its parts. Prefer [resolve], which derives the
  /// [total], [outcome] and [isCriticalHit] from the rules.
  const AttackRollResult({
    required this.roll,
    required this.modifiers,
    required this.total,
    required this.target,
    required this.outcome,
    required this.isCriticalHit,
    this.criticalRange = 20,
  });

  /// The roll the attack was made with, including its mode, dice and the
  /// natural value used.
  final D20Roll roll;

  /// The modifiers added to the natural value.
  final RollModifiers modifiers;

  /// The total the attack compared with the target: the roll's natural value
  /// plus the modifiers' kernel sum, with no clamping.
  final int total;

  /// The Armor Class the total was compared with.
  final ArmorClass target;

  /// Whether the attack hit (`success`) or missed (`failure`).
  final D20TestOutcome outcome;

  /// Whether the attack was a Critical Hit: a natural 20, or a natural value
  /// at or above [criticalRange], whatever the total ("Rolling 20 or 1",
  /// SRD 5.2.1, p. 7; "Critical Hit", p. 179). A Critical Hit always hits.
  final bool isCriticalHit;

  /// The range above which a natural value is a Critical Hit: a natural value
  /// at or above it hits regardless of modifiers or the AC. Defaults to 20
  /// ("Rolling 20 or 1", SRD 5.2.1, p. 7); the SRD widens it to 19 or 18
  /// ("Level 3: Improved Critical" and "Level 15: Superior Critical", p. 49).
  final int criticalRange;

  /// Whether the attack hit: `outcome == D20TestOutcome.success`. A
  /// Critical Hit is always a hit; a natural 1 never is.
  bool get hit => outcome == D20TestOutcome.success;

  /// The result of the same attack with the adjustment [delta] applied after
  /// the roll (an effect that adds or subtracts, "Add Modifiers",
  /// SRD 5.2.1, p. 6): a new result for the same [roll] and [target] with
  /// `Modifier(delta)` appended to the modifiers' others, the total
  /// re-derived and the outcome re-resolved by the rules of [resolve] with
  /// this result's [criticalRange] — so a natural 20 stays a hit and a
  /// Critical Hit and a natural 1 stays a miss at any total.
  ///
  /// A delta of 0 is allowed and yields a result whose others carry one 0
  /// modifier. The original result is unchanged.
  AttackRollResult adjustedBy(int delta) {
    final adjusted = RollModifiers(
      ability: modifiers.ability,
      proficiencyBonus: modifiers.proficiencyBonus,
      others: [...modifiers.others, Modifier(delta)],
    );
    return resolve(roll, adjusted, target, criticalRange: criticalRange);
  }

  @override
  bool operator ==(Object other) =>
      other is AttackRollResult &&
      other.roll == roll &&
      other.modifiers == modifiers &&
      other.total == total &&
      other.target == target &&
      other.outcome == outcome &&
      other.isCriticalHit == isCriticalHit &&
      other.criticalRange == criticalRange;

  @override
  int get hashCode => Object.hash(
    roll,
    modifiers,
    total,
    target,
    outcome,
    isCriticalHit,
    criticalRange,
  );
}
