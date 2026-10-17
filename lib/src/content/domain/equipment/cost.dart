import 'package:meta/meta.dart';

import 'coin.dart';

/// How often a cost recurs, when the table prints a rate ("per Day", "per
/// Mile") (FR-012).
///
/// The wire spelling is the printed word after "per". Absent means the cost
/// is for the item itself; no other rate is printed in the Equipment chapter.
enum CostRate {
  /// "per Day" ("Lifestyle Expenses", SRD 5.2.1, p. 101; "Hirelings", p. 102).
  day('Day'),

  /// "per Mile" ("Hirelings", Messenger, SRD 5.2.1, p. 102).
  mile('Mile');

  const CostRate(this.jsonValue);

  /// The printed word used in JSON.
  final String jsonValue;

  /// The member whose [jsonValue] is [value], or null for a non-member: the
  /// decoder turns a non-member into `invalidValue` (FR-105, FR-012).
  static CostRate? fromJson(String value) => switch (value) {
    'Day' => day,
    'Mile' => mile,
    _ => null,
  };
}

/// A printed price: an amount of one coin, optionally recurring at a rate
/// (FR-098).
///
/// A value object, compared by value over [amount], [coin] and [per]: 5 SP is
/// not 50 CP, so the printed form round-trips (FR-011). Ordering is the
/// static [compareByValue], by [valueInCopper]; the class deliberately does
/// not implement `Comparable`, so a caller cannot order accidentally by the
/// printed form. Rates occur on Lifestyle Expenses, hirelings and Feed and
/// Stabling per day (FR-012); every other cost is per item.
@immutable
final class Cost {
  /// Creates a cost of [amount] [coin], optionally recurring [per].
  ///
  /// Throws an [ArgumentError] carrying the name `amount` and the offending
  /// value when [amount] is negative (FR-098); the SRD prints 0 (Wretched,
  /// "Lifestyle Expenses", p. 101), so 0 is accepted.
  Cost(int amount, this.coin, {this.per}) : amount = _validatedAmount(amount);

  /// The number of coins, 0 or more (FR-080).
  final int amount;

  /// The coin the amount is counted in.
  final Coin coin;

  /// The recurrence rate, or null for a per-item cost (FR-012).
  final CostRate? per;

  /// The worth of the amount in Copper Pieces: [amount] times the coin's
  /// Copper value ("Coin Values", SRD 5.2.1, p. 89) (FR-010).
  int get valueInCopper => amount * coin.copperValue;

  /// Orders [a] and [b] by their [valueInCopper], so 5 SP and 50 CP compare
  /// equal (FR-011).
  ///
  /// Throws an [ArgumentError] when the rates differ: 5 SP per Day against
  /// 5 SP are not quantities of the same thing. Equal-rate comparisons
  /// (including both null) are ordered by value only.
  static int compareByValue(Cost a, Cost b) {
    if (a.per != b.per) {
      throw ArgumentError.value(
        b.per,
        'per',
        'costs with different rates cannot be compared by value',
      );
    }
    return a.valueInCopper.compareTo(b.valueInCopper);
  }

  static int _validatedAmount(int amount) {
    if (amount < 0) {
      throw ArgumentError.value(amount, 'amount', 'must be 0 or more');
    }
    return amount;
  }

  @override
  bool operator ==(Object other) =>
      other is Cost &&
      other.amount == amount &&
      other.coin == coin &&
      other.per == per;

  @override
  int get hashCode => Object.hash(Cost, amount, coin, per);

  @override
  String toString() =>
      'Cost($amount ${coin.jsonValue}${per == null ? '' : ' per ${per!.jsonValue}'})';
}
