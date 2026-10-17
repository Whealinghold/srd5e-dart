import 'package:meta/meta.dart';

/// The Armor Class rule an armor entry carries, as the Armor table prints it
/// (FR-093).
///
/// The sealed family has exactly the two printed shapes, so a `switch` is
/// exhaustive without a default and a Shield cannot be mistaken for body
/// armor (FR-024): a body armor's AC is a base value with a Dexterity
/// treatment ([BaseRule]), the Shield's is a flat bonus ([BonusRule]). The
/// types hold immutable data with no evaluation method — computing an AC is
/// the equipment rules' concern, not the content's.
@immutable
sealed class ArmorClassRule {
  const ArmorClassRule();
}

/// How a [BaseRule] treats the wearer's Dexterity modifier, as the Armor
/// table prints it (FR-093).
///
/// The bundled treatments are Light full, Medium capped at 2, Heavy none.
@immutable
sealed class DexterityBonus {
  const DexterityBonus();
}

/// The full Dexterity modifier applies (Light armor).
@immutable
final class FullDexterity extends DexterityBonus {
  /// The single treatment; the table's dash carries no data.
  const FullDexterity();

  @override
  bool operator ==(Object other) => other is FullDexterity;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'FullDexterity()';
}

/// The Dexterity modifier applies up to a printed maximum (Medium armor:
/// 2).
@immutable
final class CappedDexterity extends DexterityBonus {
  /// The smallest [maximum] a capped treatment may print (FR-112). The
  /// constant the decoder reuses instead of repeating the literal (FR-094).
  static const int minMaximum = 0;

  /// The printed maximum ("Max Mod" column, SRD 5.2.1, p. 92).
  const CappedDexterity(this.maximum);

  /// The largest Dexterity modifier the armor benefits from.
  final int maximum;

  @override
  bool operator ==(Object other) =>
      other is CappedDexterity && other.maximum == maximum;

  @override
  int get hashCode => Object.hash(CappedDexterity, maximum);

  @override
  String toString() => 'CappedDexterity($maximum)';
}

/// The Dexterity modifier does not apply (Heavy armor).
@immutable
final class NoDexterity extends DexterityBonus {
  /// The single treatment; the table's dash carries no data.
  const NoDexterity();

  @override
  bool operator ==(Object other) => other is NoDexterity;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'NoDexterity()';
}

/// A body armor's rule: a base value and a Dexterity treatment (FR-093).
@immutable
final class BaseRule extends ArmorClassRule {
  /// The smallest [base] the Armor table's AC column prints (FR-112). The
  /// constant the decoder reuses instead of repeating the literal (FR-094).
  static const int minBase = 1;

  /// The largest [base] (FR-112).
  static const int maxBase = 30;

  /// Creates the rule of an armor with base value [base] and Dexterity
  /// treatment [dexterity].
  const BaseRule(this.base, this.dexterity);

  /// The AC the armor gives before Dexterity ("Armor Class (AC)" column,
  /// SRD 5.2.1, p. 92).
  final int base;

  /// How the wearer's Dexterity modifier combines with [base].
  final DexterityBonus dexterity;

  @override
  bool operator ==(Object other) =>
      other is BaseRule && other.base == base && other.dexterity == dexterity;

  @override
  int get hashCode => Object.hash(BaseRule, base, dexterity);

  @override
  String toString() => 'BaseRule($base, $dexterity)';
}

/// The Shield's rule: a flat +2 bonus (FR-024).
@immutable
final class BonusRule extends ArmorClassRule {
  /// The smallest [bonus] the Shield rule may carry (FR-112). The constant
  /// the decoder reuses instead of repeating the literal (FR-094).
  static const int minBonus = 1;

  /// The largest [bonus] (FR-112).
  static const int maxBonus = 10;

  /// Creates the rule of an armor that adds [bonus].
  const BonusRule(this.bonus);

  /// The bonus the Shield adds to Armor Class ("Shield", SRD 5.2.1, p. 92).
  final int bonus;

  @override
  bool operator ==(Object other) => other is BonusRule && other.bonus == bonus;

  @override
  int get hashCode => Object.hash(BonusRule, bonus);

  @override
  String toString() => 'BonusRule($bonus)';
}
