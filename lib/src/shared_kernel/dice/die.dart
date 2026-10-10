import 'package:meta/meta.dart';

/// Why a [Die] could not be created from a number of sides.
enum DieRejection {
  /// The number of sides is below [Die.minSides] or above [Die.maxSides].
  sidesOutOfRange,
}

/// A die: a fair die with a number of sides, whose faces are numbered from 1
/// to that number.
///
/// SRD 5.2.1 prints the dice d3, d4, d6, d8, d10, d12, d20 and d100 (for
/// example "Hit Points", p. 255), available as named constants. The
/// constructor also accepts any other number of sides from [minSides] to
/// [maxSides], so content and house rules can use a die the SRD does not print.
///
/// The face range of a die (1 to its sides) is a package-design reading of
/// "Roll 1d20" (SRD 5.2.1, "D20 Tests", p. 6).
@immutable
final class Die {
  /// Creates a die with [sides] sides.
  ///
  /// Throws an [ArgumentError] carrying the name `sides` and the offending
  /// value when [sides] is below [minSides] or above [maxSides]. Use
  /// [tryCreate] for untrusted input.
  Die(int sides) : sides = _validated(sides);

  const Die._(this.sides);

  /// The fewest sides a die can have: a one-sided die cannot be rolled
  /// meaningfully.
  static const int minSides = 2;

  /// The most sides a die can have. This is a package-design limit that keeps
  /// arithmetic within safe integers on every platform.
  static const int maxSides = 1000;

  /// A die with 3 sides ("1d3", SRD 5.2.1, "Traps", p. 200).
  static const Die d3 = Die._(3);

  /// A die with 4 sides.
  static const Die d4 = Die._(4);

  /// A die with 6 sides.
  static const Die d6 = Die._(6);

  /// A die with 8 sides.
  static const Die d8 = Die._(8);

  /// A die with 10 sides.
  static const Die d10 = Die._(10);

  /// A die with 12 sides.
  static const Die d12 = Die._(12);

  /// A die with 20 sides ("D20 Tests", SRD 5.2.1, p. 6).
  static const Die d20 = Die._(20);

  /// A die with 100 sides ("Trinkets", SRD 5.2.1, p. 26).
  static const Die d100 = Die._(100);

  /// The number of sides, which is also the highest face.
  final int sides;

  /// Creates a die from untrusted input without throwing.
  ///
  /// Returns [CreatedDie] exactly when the [Die] constructor would accept
  /// [sides], and [RejectedDie] with [DieRejection.sidesOutOfRange] otherwise.
  static DieCreation tryCreate(int sides) {
    final reason = _rejection(sides);
    return reason == null ? CreatedDie(Die._(sides)) : RejectedDie(reason);
  }

  static DieRejection? _rejection(int sides) =>
      sides < minSides || sides > maxSides
      ? DieRejection.sidesOutOfRange
      : null;

  static int _validated(int sides) {
    if (_rejection(sides) != null) {
      throw ArgumentError.value(
        sides,
        'sides',
        'must be from $minSides to $maxSides',
      );
    }
    return sides;
  }

  @override
  bool operator ==(Object other) => other is Die && other.sides == sides;

  @override
  int get hashCode => sides.hashCode;

  /// The debugging form, `d<sides>`. Not display text.
  @override
  String toString() => 'd$sides';
}

/// The result of [Die.tryCreate]: a created die or a typed rejection.
@immutable
sealed class DieCreation {
  const DieCreation();
}

/// [Die.tryCreate] accepted the number of sides.
final class CreatedDie extends DieCreation {
  /// Wraps the created [value].
  const CreatedDie(this.value);

  /// The die that was created.
  final Die value;

  @override
  bool operator ==(Object other) => other is CreatedDie && other.value == value;

  @override
  int get hashCode => Object.hash(CreatedDie, value);

  @override
  String toString() => 'CreatedDie($value)';
}

/// [Die.tryCreate] rejected the number of sides.
final class RejectedDie extends DieCreation {
  /// Carries the typed [reason].
  const RejectedDie(this.reason);

  /// Why the die was rejected.
  final DieRejection reason;

  @override
  bool operator ==(Object other) =>
      other is RejectedDie && other.reason == reason;

  @override
  int get hashCode => Object.hash(RejectedDie, reason);

  @override
  String toString() => 'RejectedDie(${reason.name})';
}
