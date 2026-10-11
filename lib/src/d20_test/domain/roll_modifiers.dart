import 'package:meta/meta.dart';

import '../../shared_kernel/modifier.dart';

/// The modifiers added to a D20 Test roll ("Add Modifiers", SRD 5.2.1, p. 6):
/// exactly one ability modifier, at most one Proficiency Bonus and any number
/// of other modifiers.
///
/// The shape enforces every "at most one of X" rule, so no runtime check
/// exists: the Proficiency Bonus is a single nullable slot and cannot be
/// added twice ("The Bonus Doesn't Stack", SRD 5.2.1, p. 8). The slots hold
/// plain kernel `Modifier`s — the already-multiplied values; a caller
/// converts an ability score's modifier or a Proficiency Bonus with
/// `Modifier(value)`. No other stacking rule is applied: modifiers combine by
/// plain signed addition, positive, zero or negative in any mix.
@immutable
final class RollModifiers {
  /// Creates modifiers from the required [ability] modifier, the optional
  /// [proficiencyBonus] and the [others], which defaults to none.
  ///
  /// The others are copied into an unmodifiable list, so changing the
  /// caller's collection afterwards does not change the value and the held
  /// [others] cannot be mutated.
  RollModifiers({
    required this.ability,
    this.proficiencyBonus,
    Iterable<Modifier> others = const [],
  }) : others = List.unmodifiable(others);

  /// The ability modifier: the one modifier every rolled D20 Test carries.
  final Modifier ability;

  /// The Proficiency Bonus, when one applies; otherwise null. At most one,
  /// already multiplied for the character's proficiency.
  final Modifier? proficiencyBonus;

  /// Every other modifier: circumstantial bonuses and penalties in any mix.
  /// Unmodifiable; empty by default.
  final List<Modifier> others;

  /// The kernel sum of [ability], [proficiencyBonus] (when present) and every
  /// modifier in [others] ("Add Modifiers", SRD 5.2.1, p. 6): the amount a
  /// test's d20 number is increased by before it is compared with the target.
  ///
  /// Modifiers combine by plain signed addition with no clamping, so the
  /// rolled total may be below 1 or above 20, and may be zero or negative.
  /// The order of [others] does not matter: addition is exact, so every
  /// permutation gives the same sum.
  Modifier get total =>
      Modifier.sum(<Modifier>[ability, ?proficiencyBonus, ...others]);

  @override
  bool operator ==(Object other) =>
      other is RollModifiers &&
      other.ability == ability &&
      other.proficiencyBonus == proficiencyBonus &&
      _sameModifiers(other.others, others);

  @override
  int get hashCode =>
      Object.hash(ability, proficiencyBonus, Object.hashAll(others));

  /// Whether [a] and [b] hold equal modifiers in the same order.
  static bool _sameModifiers(List<Modifier> a, List<Modifier> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
