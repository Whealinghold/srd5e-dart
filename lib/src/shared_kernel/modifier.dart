import 'package:meta/meta.dart';

/// A modifier: a signed whole number added to the number rolled on the d20.
///
/// A positive value is a bonus, a negative value is a penalty, and zero changes
/// nothing; they are not separate types ("D20 Tests", "Add Modifiers" and
/// "Circumstantial Bonuses and Penalties", SRD 5.2.1, p. 6). Modifiers combine
/// by plain signed addition ([+], [sum]) and the SRD states no other stacking
/// or ordering rule.
///
/// A modifier is unbounded: the SRD gives no limit, so the constructor accepts
/// any [int] and never throws. Sums and totals are exact integer arithmetic
/// with no clamping or wrapping added by the package, up to the exactness of a
/// Dart [int] on the platform (2^53 on the web), which no SRD value approaches.
///
/// A modifier carries no kind tag and no source. Deriving one from an ability
/// score or a Proficiency Bonus is the work of the types that own those; they
/// convert with `Modifier(value)`.
@immutable
final class Modifier {
  /// Creates a modifier of [value]: positive for a bonus, negative for a
  /// penalty. Any [int] is valid.
  const Modifier(this.value);

  /// The modifier that changes nothing: a value of 0 (the +0 row of the
  /// "Ability Modifiers" table, SRD 5.2.1, p. 6).
  static const Modifier zero = Modifier(0);

  /// The whole number this modifier adds to the d20 number.
  final int value;

  /// The sum of [modifiers]: their values added together ("Add Modifiers",
  /// SRD 5.2.1, p. 6).
  ///
  /// The order of the modifiers does not matter. The sum of no modifiers is
  /// [zero]. The collection is only read, never altered.
  static Modifier sum(Iterable<Modifier> modifiers) {
    var total = 0;
    for (final modifier in modifiers) {
      total += modifier.value;
    }
    return Modifier(total);
  }

  /// The sum of this modifier and [other]: a modifier whose value is the sum of
  /// the two values. A bonus and a penalty combine into their net value, which
  /// may be negative.
  Modifier operator +(Modifier other) => Modifier(value + other.value);

  /// The total of the d20 number [d20Number] and this modifier: `d20Number`
  /// plus [value] ("D20 Tests", SRD 5.2.1, p. 6).
  ///
  /// The total is not clamped: it may be below 1 or above 20. [d20Number] is
  /// not validated here (the 1 to 20 check belongs to `RollMode.select`), so
  /// any [int] is accepted.
  int applyTo(int d20Number) => d20Number + value;

  @override
  bool operator ==(Object other) => other is Modifier && other.value == value;

  @override
  int get hashCode => value.hashCode;

  /// The debugging form, `Modifier(<value>)`. Not display text.
  @override
  String toString() => 'Modifier($value)';
}
