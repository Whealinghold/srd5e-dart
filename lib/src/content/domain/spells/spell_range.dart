import 'package:meta/meta.dart';

/// One of the two units a Distance Range is expressed in ("Range",
/// SRD 5.2.1, p. 105) (FR-119).
///
/// The rules text says only "expressed in feet"; the entries that use miles
/// are Clairvoyance (1 mile, p. 115) and Project Image (500 miles, p. 156).
/// The JSON value is the package tag in lower camel case.
enum DistanceUnit {
  /// Feet.
  feet('feet'),

  /// Miles.
  miles('miles');

  const DistanceUnit(this.jsonValue);

  /// The package tag used in JSON.
  final String jsonValue;

  /// The member whose [jsonValue] is [value], or null for a non-member: the
  /// decoder turns a non-member into `invalidValue` (FR-105, FR-108).
  static DistanceUnit? fromJson(String value) => switch (value) {
    'feet' => feet,
    'miles' => miles,
    _ => null,
  };
}

/// One printed Range form, sealed with exactly the six exported variants
/// ("Range", SRD 5.2.1, p. 105) (FR-036).
///
/// The factories on this class give the short names of the case tables and
/// return the variant. Switch over the family exhaustively, with no default
/// branch.
@immutable
sealed class SpellRange {
  const SpellRange();

  /// The lowest amount a [SpellRangeDistance] may hold (FR-037, FR-111).
  static const int minDistance = 1;

  /// Whether [amount] is a valid Distance amount: at least [minDistance]
  /// (FR-037, FR-111). The predicate the decoder reuses instead of
  /// repeating the bound.
  static bool isValidDistance(int amount) => amount >= minDistance;

  /// The spell reaches only the caster (FR-036).
  static SpellRangeSelf self() => const SpellRangeSelf();

  /// The spell reaches a target the caster touches (FR-036).
  static SpellRangeTouch touch() => const SpellRangeTouch();

  /// The spell reaches [amount] [unit] away (FR-036, FR-037).
  static SpellRangeDistance distance(int amount, DistanceUnit unit) =>
      SpellRangeDistance(amount, unit);

  /// The spell reaches anywhere the caster can see (FR-036).
  static SpellRangeSight sight() => const SpellRangeSight();

  /// The spell reaches anywhere on the same plane (FR-036).
  static SpellRangeUnlimited unlimited() => const SpellRangeUnlimited();

  /// The spell's range is Special, its definition in the description
  /// (FR-036).
  static SpellRangeSpecial special() => const SpellRangeSpecial();
}

/// The spell reaches only the caster (FR-036).
@immutable
final class SpellRangeSelf extends SpellRange {
  /// The single form; the printed "Self" carries no data.
  const SpellRangeSelf();

  @override
  bool operator ==(Object other) => other is SpellRangeSelf;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'SpellRangeSelf()';
}

/// The spell reaches a target the caster touches (FR-036).
@immutable
final class SpellRangeTouch extends SpellRange {
  /// The single form; the printed "Touch" carries no data.
  const SpellRangeTouch();

  @override
  bool operator ==(Object other) => other is SpellRangeTouch;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'SpellRangeTouch()';
}

/// The spell reaches a distance (FR-036, FR-037).
@immutable
final class SpellRangeDistance extends SpellRange {
  /// Creates the range of [amount] [unit].
  ///
  /// Throws an [ArgumentError] carrying the name `amount` and the offending
  /// value when [amount] is below [SpellRange.minDistance] (FR-037).
  SpellRangeDistance(int amount, this.unit) : amount = _validatedAmount(amount);

  /// The distance.
  final int amount;

  /// The unit the distance is expressed in.
  final DistanceUnit unit;

  static int _validatedAmount(int amount) {
    if (!SpellRange.isValidDistance(amount)) {
      throw ArgumentError.value(
        amount,
        'amount',
        'must be at least ${SpellRange.minDistance}',
      );
    }
    return amount;
  }

  @override
  bool operator ==(Object other) =>
      other is SpellRangeDistance &&
      other.amount == amount &&
      other.unit == unit;

  @override
  int get hashCode => Object.hash(SpellRangeDistance, amount, unit);

  @override
  String toString() => 'SpellRangeDistance($amount, ${unit.jsonValue})';
}

/// The spell reaches anywhere the caster can see (FR-036).
@immutable
final class SpellRangeSight extends SpellRange {
  /// The single form; the printed "Sight" carries no data.
  const SpellRangeSight();

  @override
  bool operator ==(Object other) => other is SpellRangeSight;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'SpellRangeSight()';
}

/// The spell reaches anywhere on the same plane (FR-036).
@immutable
final class SpellRangeUnlimited extends SpellRange {
  /// The single form; the printed "Unlimited" carries no data.
  const SpellRangeUnlimited();

  @override
  bool operator ==(Object other) => other is SpellRangeUnlimited;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'SpellRangeUnlimited()';
}

/// The spell's range is Special, defined in its description (FR-036).
@immutable
final class SpellRangeSpecial extends SpellRange {
  /// The single form; the printed "Special" carries no data — the details
  /// stay in the description.
  const SpellRangeSpecial();

  @override
  bool operator ==(Object other) => other is SpellRangeSpecial;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'SpellRangeSpecial()';
}
