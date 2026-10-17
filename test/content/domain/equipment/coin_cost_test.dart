import 'package:srd5e/src/content/domain/equipment/coin.dart';
import 'package:srd5e/src/content/domain/equipment/cost.dart';
import 'package:test/test.dart';

import '../../../support/argument_error_matcher.dart';

void main() {
  /// Requirement: doc/specs/content-equipment.md FR-009, FR-098 - the Coin enum with its
  ///   Copper values and wire spellings (SRD 5.2.1, "Coins", p. 89).
  /// Path: happy
  group('Coin', () {
    /// Requirement: doc/specs/content-equipment.md FR-009 - Coin has exactly
    ///   CP, SP, EP, GP, PP, worth 1, 10, 50, 100 and 1,000 CP (SRD 5.2.1,
    ///   "Coins", Coin Values table, p. 89).
    /// Path: happy
    test('holds the five coins in printed order with their Copper values', () {
      expect(Coin.values, hasLength(5));
      expect(Coin.values.map((c) => c.jsonValue), [
        'CP',
        'SP',
        'EP',
        'GP',
        'PP',
      ]);
      expect(Coin.values.map((c) => c.copperValue), [1, 10, 50, 100, 1000]);
    });

    /// Requirement: doc/specs/content-equipment.md FR-009 - the wire
    ///   spellings are the printed abbreviations (SRD 5.2.1, p. 89).
    /// Path: happy
    test('fromJson accepts each wire spelling and rejects a non-member', () {
      expect(Coin.fromJson('CP'), Coin.cp);
      expect(Coin.fromJson('SP'), Coin.sp);
      expect(Coin.fromJson('EP'), Coin.ep);
      expect(Coin.fromJson('GP'), Coin.gp);
      expect(Coin.fromJson('PP'), Coin.pp);
      expect(Coin.fromJson('GC'), isNull);
      expect(Coin.fromJson('cp'), isNull);
    });
  });

  /// Requirement: doc/specs/content-equipment.md FR-010, FR-098 - valueInCopper is amount
  ///   times the Coin's Copper value; negative amounts are rejected
  ///   (SRD 5.2.1, "Coins", p. 89).
  /// Path: happy
  group('Cost valueInCopper', () {
    const cases = [
      (label: '1 CP', coin: Coin.cp, amount: 1, copper: 1),
      (label: '1 SP', coin: Coin.sp, amount: 1, copper: 10),
      (label: '1 EP', coin: Coin.ep, amount: 1, copper: 50),
      (label: '1 GP', coin: Coin.gp, amount: 1, copper: 100),
      (label: '1 PP', coin: Coin.pp, amount: 1, copper: 1000),
    ];

    /// Requirement: per case
    /// Path: per case
    for (final c in cases) {
      test('${c.label} is worth ${c.copper} Copper Pieces', () {
        final cost = Cost(c.amount, c.coin);
        expect(cost.valueInCopper, c.copper);
      });
    }

    /// Requirement: doc/specs/content-equipment.md FR-010 - 100 CP equals
    ///   1 GP in value (SRD 5.2.1, "Coins", p. 89).
    /// Path: happy
    test('100 CP is worth 100 Copper, the value of 1 GP', () {
      expect(Cost(100, Coin.cp).valueInCopper, 100);
      expect(Cost(1, Coin.gp).valueInCopper, 100);
    });

    /// Requirement: doc/specs/content-equipment.md FR-010 - 0 GP is worth 0
    ///   (Wretched (Free), SRD 5.2.1, "Lifestyle Expenses", p. 101).
    /// Path: unhappy (boundary)
    test('0 GP is worth 0', () {
      expect(Cost(0, Coin.gp).valueInCopper, 0);
    });

    /// Requirement: doc/specs/content-equipment.md FR-010 - 100,000 GP is
    ///   worth 10,000,000 (SRD 5.2.1, "Spellcasting Services", p. 102).
    /// Path: unhappy (boundary)
    test('100,000 GP is worth 10,000,000 Copper', () {
      expect(Cost(100000, Coin.gp).valueInCopper, 10000000);
    });

    /// Requirement: doc/specs/content-equipment.md FR-098 - a negative
    ///   amount throws ArgumentError (architecture.md §6).
    /// Path: unhappy (invalid input)
    test('-1 GP is rejected with the amount as invalidValue', () {
      expect(() => Cost(-1, Coin.gp), throwsArgumentErrorFor('amount', -1));
    });
  });

  /// Requirement: doc/specs/content-equipment.md FR-011 - two Costs are equal iff amount,
  ///   coin and rate are equal; 5 SP is not 50 CP (architecture.md §3).
  /// Path: unhappy (rule interaction)
  group('Cost equality', () {
    /// Requirement: doc/specs/content-equipment.md FR-011 - 5 SP is not
    ///   50 CP, so the printed form round-trips, though the values agree
    ///   (architecture.md §3).
    /// Path: unhappy (rule interaction)
    test('5 SP is not 50 CP, but both are worth 50 Copper', () {
      final sp = Cost(5, Coin.sp);
      final cp = Cost(50, Coin.cp);
      expect(sp.valueInCopper, cp.valueInCopper);
      expect(sp == cp, isFalse);
      expect(cp == sp, isFalse);
    });

    /// Requirement: doc/specs/content-equipment.md FR-011 - two Costs are
    ///   equal iff amount, coin and rate are equal (FR-098).
    /// Path: happy
    test('equal fields are equal; a differing rate is not equal', () {
      final day = Cost(2, Coin.sp, per: CostRate.day);
      expect(Cost(2, Coin.sp), Cost(2, Coin.sp));
      expect(day == Cost(2, Coin.sp), isFalse);
      expect(day, Cost(2, Coin.sp, per: CostRate.day));
      expect(day.hashCode, Cost(2, Coin.sp, per: CostRate.day).hashCode);
    });
  });

  /// Requirement: doc/specs/content-equipment.md FR-011 - compareByValue orders by
  ///   valueInCopper and rejects differing rates.
  /// Path: unhappy (rule interaction)
  group('Cost.compareByValue', () {
    /// Requirement: doc/specs/content-equipment.md FR-011 - compareByValue
    ///   orders by valueInCopper; 5 SP and 50 CP give 0.
    /// Path: unhappy (rule interaction)
    test('5 SP and 50 CP compare equal', () {
      final result = Cost.compareByValue(Cost(5, Coin.sp), Cost(50, Coin.cp));
      expect(result, 0);
    });

    /// Requirement: doc/specs/content-equipment.md FR-011 - compareByValue
    ///   orders 1 CP before 1 SP.
    /// Path: happy
    test('1 CP orders before 1 SP', () {
      expect(
        Cost.compareByValue(Cost(1, Coin.cp), Cost(1, Coin.sp)),
        isNegative,
      );
    });

    /// Requirement: doc/specs/content-equipment.md FR-011 - comparing costs
    ///   with different rates throws ArgumentError (5 SP per Day against
    ///   5 SP).
    /// Path: unhappy (invalid input)
    test('different rates are rejected', () {
      final perDay = Cost(5, Coin.sp, per: CostRate.day);
      final perItem = Cost(5, Coin.sp);
      expect(
        () => Cost.compareByValue(perDay, perItem),
        throwsArgumentErrorFor('per', null),
      );
    });

    /// Requirement: doc/specs/content-equipment.md FR-011 - equal rates
    ///   compare by value: 2 SP per Day orders before 1 GP per Day.
    /// Path: unhappy (boundary)
    test('2 SP per Day orders before 1 GP per Day', () {
      final result = Cost.compareByValue(
        Cost(2, Coin.sp, per: CostRate.day),
        Cost(1, Coin.gp, per: CostRate.day),
      );
      expect(result, isNegative);
    });
  });
}
