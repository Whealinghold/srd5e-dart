import 'package:meta/meta.dart';

import '../../../shared_kernel/dice/dice_expression.dart';
import '../damage_type.dart';

/// The damage a weapon deals, as the Weapons table prints it (FR-102).
///
/// The sealed family holds the two printed shapes: a die expression
/// ([WeaponDiceDamage]) and, for the Blowgun's printed "1 Piercing", a fixed
/// number ([WeaponFixedDamage]). The `Weapon` prefix avoids the names
/// `DiceDamage` and `FixedDamage` exported elsewhere. Switch over it
/// exhaustively, with no default branch.
@immutable
sealed class WeaponDamage {
  const WeaponDamage();
}

/// A weapon that deals a die expression of damage, such as "1d8 Piercing"
/// (FR-102).
@immutable
final class WeaponDiceDamage extends WeaponDamage {
  /// Creates the damage of [dice] of [type].
  ///
  /// Throws an [ArgumentError] carrying the name `dice` and the offending
  /// expression when [dice] carries a modifier: the Weapons table prints
  /// bare die expressions, so a modifier is not representable here.
  WeaponDiceDamage(DiceExpression dice, this.type)
    : dice = _validatedDice(dice);

  /// The printed die expression, with no modifier.
  final DiceExpression dice;

  /// The damage type ("Damage Types", SRD 5.2.1, p. 180).
  final DamageType type;

  static DiceExpression _validatedDice(DiceExpression dice) {
    if (dice.modifier != 0) {
      throw ArgumentError.value(
        dice,
        'dice',
        'a weapon damage die expression has no modifier',
      );
    }
    return dice;
  }

  @override
  bool operator ==(Object other) =>
      other is WeaponDiceDamage && other.dice == dice && other.type == type;

  @override
  int get hashCode => Object.hash(WeaponDiceDamage, dice, type);

  @override
  String toString() => 'WeaponDiceDamage($dice, ${type.jsonValue})';
}

/// A weapon whose damage is a printed number, such as the Blowgun's
/// "1 Piercing" (FR-102).
@immutable
final class WeaponFixedDamage extends WeaponDamage {
  /// Creates the fixed damage of [amount] of [type].
  ///
  /// Throws an [ArgumentError] carrying the name `amount` and the offending
  /// value when [amount] is below 1.
  WeaponFixedDamage(int amount, this.type) : amount = _validatedAmount(amount);

  /// The printed fixed damage.
  final int amount;

  /// The damage type ("Damage Types", SRD 5.2.1, p. 180).
  final DamageType type;

  static int _validatedAmount(int amount) {
    if (amount < 1) {
      throw ArgumentError.value(amount, 'amount', 'must be at least 1');
    }
    return amount;
  }

  @override
  bool operator ==(Object other) =>
      other is WeaponFixedDamage &&
      other.amount == amount &&
      other.type == type;

  @override
  int get hashCode => Object.hash(WeaponFixedDamage, amount, type);

  @override
  String toString() => 'WeaponFixedDamage($amount, ${type.jsonValue})';
}
