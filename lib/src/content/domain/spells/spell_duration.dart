import 'package:meta/meta.dart';

import '../duration_unit.dart';

/// How a Time Span duration is capped, as the Duration entry prints it
/// ("Duration", SRD 5.2.1, p. 106) (FR-052, FR-119).
///
/// The limit replaces two flags, so "Concentration without a cap" is
/// unrepresentable by type (FR-052): `concentrationUpTo` is always printed
/// with a cap. Printed "Concentration, up to N unit" is [concentrationUpTo];
/// the other caps are [fixed] ("1 hour") and [upTo] ("Up to 1 hour", FR-054).
enum DurationLimit {
  /// A fixed Time Span: "1 hour".
  fixed('fixed'),

  /// A capped Time Span without Concentration: "Up to 1 hour" (FR-054).
  upTo('upTo'),

  /// Concentration, up to the capped Time Span (FR-052).
  concentrationUpTo('concentrationUpTo');

  const DurationLimit(this.jsonValue);

  /// The package tag used in JSON.
  final String jsonValue;

  /// The member whose [jsonValue] is [value], or null for a non-member: the
  /// decoder turns a non-member into `invalidValue` (FR-105, FR-108).
  static DurationLimit? fromJson(String value) => switch (value) {
    'fixed' => fixed,
    'upTo' => upTo,
    'concentrationUpTo' => concentrationUpTo,
    _ => null,
  };
}

/// One printed Duration form, sealed with exactly the five exported variants
/// ("Duration", SRD 5.2.1, p. 106) (FR-050).
///
/// The factories on this class give the short names of the case tables and
/// return the variant. Switch over the family exhaustively, with no default
/// branch.
@immutable
sealed class SpellDuration {
  const SpellDuration();

  /// The lowest amount a [SpellDurationTimed] may hold (FR-051, FR-111).
  static const int minAmount = 1;

  /// Whether [amount] is a valid Time Span amount: at least [minAmount]
  /// (FR-051, FR-111). The predicate the decoder reuses instead of
  /// repeating the bound.
  static bool isValidAmount(int amount) => amount >= minAmount;

  /// The spell's effects last an instant (FR-050).
  static SpellDurationInstantaneous instantaneous() =>
      const SpellDurationInstantaneous();

  /// The spell's effects last a Time Span under [limit] (FR-050, FR-051).
  static SpellDurationTimed timed(
    int amount,
    DurationUnit unit,
    DurationLimit limit,
  ) => SpellDurationTimed(amount, unit, limit);

  /// The spell's effects last until the spell is dispelled (FR-050).
  static SpellDurationUntilDispelled untilDispelled() =>
      const SpellDurationUntilDispelled();

  /// The spell's effects last until dispelled or triggered (FR-050).
  static SpellDurationUntilDispelledOrTriggered untilDispelledOrTriggered() =>
      const SpellDurationUntilDispelledOrTriggered();

  /// The spell's duration is Special, defined in the description (FR-050,
  /// FR-056).
  static SpellDurationSpecial special() => const SpellDurationSpecial();
}

/// The spell's effects last an instant (FR-050).
@immutable
final class SpellDurationInstantaneous extends SpellDuration {
  /// The single form; the printed "Instantaneous" carries no data.
  const SpellDurationInstantaneous();

  @override
  bool operator ==(Object other) => other is SpellDurationInstantaneous;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'SpellDurationInstantaneous()';
}

/// A Time Span: an [amount] of a unit, under a [DurationLimit] (FR-050,
/// FR-051, FR-052).
@immutable
final class SpellDurationTimed extends SpellDuration {
  /// Creates the Time Span of [amount] [unit] under [limit].
  ///
  /// Throws an [ArgumentError] carrying the name `amount` and the offending
  /// value when [amount] is below [SpellDuration.minAmount] (FR-051).
  /// [limit] carries whether the spell requires Concentration, so a
  /// Concentration duration without a cap cannot be expressed (FR-052).
  SpellDurationTimed(int amount, this.unit, this.limit)
    : amount = _validatedAmount(amount);

  /// The length of the Time Span.
  final int amount;

  /// The unit the length is counted in ("Duration" (Time Span),
  /// SRD 5.2.1, p. 106).
  final DurationUnit unit;

  /// How the Time Span is capped, and whether it requires Concentration
  /// (FR-052).
  final DurationLimit limit;

  static int _validatedAmount(int amount) {
    if (!SpellDuration.isValidAmount(amount)) {
      throw ArgumentError.value(
        amount,
        'amount',
        'must be at least ${SpellDuration.minAmount}',
      );
    }
    return amount;
  }

  @override
  bool operator ==(Object other) =>
      other is SpellDurationTimed &&
      other.amount == amount &&
      other.unit == unit &&
      other.limit == limit;

  @override
  int get hashCode => Object.hash(SpellDurationTimed, amount, unit, limit);

  @override
  String toString() => 'SpellDurationTimed($amount ${unit.jsonValue}, $limit)';
}

/// The spell's effects last until the spell is dispelled (FR-050).
@immutable
final class SpellDurationUntilDispelled extends SpellDuration {
  /// The single form; the printed words carry no data.
  const SpellDurationUntilDispelled();

  @override
  bool operator ==(Object other) => other is SpellDurationUntilDispelled;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'SpellDurationUntilDispelled()';
}

/// The spell's effects last until dispelled or triggered (FR-050).
@immutable
final class SpellDurationUntilDispelledOrTriggered extends SpellDuration {
  /// The single form; the printed words carry no data.
  const SpellDurationUntilDispelledOrTriggered();

  @override
  bool operator ==(Object other) =>
      other is SpellDurationUntilDispelledOrTriggered;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'SpellDurationUntilDispelledOrTriggered()';
}

/// The spell's duration is Special, defined in its description (FR-050,
/// FR-056): Creation (SRD 5.2.1, p. 121), whose details stay in the
/// description.
@immutable
final class SpellDurationSpecial extends SpellDuration {
  /// The single form; the printed "Special" carries no data.
  const SpellDurationSpecial();

  @override
  bool operator ==(Object other) => other is SpellDurationSpecial;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'SpellDurationSpecial()';
}
