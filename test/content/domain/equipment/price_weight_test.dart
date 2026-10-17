import 'package:srd5e/src/content/domain/equipment/coin.dart';
import 'package:srd5e/src/content/domain/equipment/cost.dart';
import 'package:srd5e/src/content/domain/equipment/price.dart';
import 'package:srd5e/src/content/domain/equipment/weight_spec.dart';
import 'package:test/test.dart';

import '../../../support/argument_error_matcher.dart';

/// The label a `switch` over the sealed [Price] family returns, with no
/// default branch.
String priceLabel(Price price) => switch (price) {
  FixedCost() => 'fixed',
  CostVaries() => 'varies',
};

/// The label a `switch` over the sealed [WeightSpec] family returns, with no
/// default branch.
String weightLabel(WeightSpec weight) => switch (weight) {
  Weight() => 'weight',
  WeightVaries() => 'varies',
  NoWeight() => 'none',
};

void main() {
  /// Requirement: doc/specs/content-equipment.md FR-013 - a printed price is a Price: a
  ///   Cost or "Varies", as sealed types (Adventuring Gear table,
  ///   SRD 5.2.1, p. 95).
  /// Path: happy
  group('Price', () {
    /// Requirement: doc/specs/content-equipment.md FR-013 - a printed price
    ///   is a Price: a Cost or the word "Varies", never a nullable cost plus
    ///   a flag (Adventuring Gear table, SRD 5.2.1, p. 95).
    /// Path: happy
    test('holds FixedCost and CostVaries, distinct and exhaustive', () {
      final fixed = FixedCost(Cost(30, Coin.gp));
      expect(priceLabel(fixed), 'fixed');
      expect(priceLabel(const CostVaries()), 'varies');
      expect(fixed.cost, Cost(30, Coin.gp));
      expect(fixed, FixedCost(Cost(30, Coin.gp)));
      expect(const CostVaries(), const CostVaries());
    });
  });

  /// Requirement: doc/specs/content-equipment.md FR-013, FR-015, FR-115 - a printed weight
  ///   is a number, "Varies" or an em dash; the parenthetical note is
  ///   kept non-blank (SRD 5.2.1, p. 95).
  /// Path: happy
  group('WeightSpec', () {
    /// Requirement: doc/specs/content-equipment.md FR-013 - a printed weight
    ///   is a number, "Varies" or an em dash, as sealed types (SRD 5.2.1,
    ///   p. 95).
    /// Path: happy
    test('holds Weight, WeightVaries and NoWeight, exhaustive', () {
      expect(weightLabel(Weight(4)), 'weight');
      expect(weightLabel(const WeightVaries()), 'varies');
      expect(weightLabel(const NoWeight()), 'none');
      expect(Weight(4), Weight(4));
      expect(const WeightVaries(), const WeightVaries());
      expect(const NoWeight(), const NoWeight());
      // The lightest weight is inclusive: 0 pounds is a weight (a vial).
      expect(Weight.isValidPounds(Weight.minPounds), isTrue);
      expect(Weight(Weight.minPounds).pounds, Weight.minPounds);
    });

    /// Requirement: doc/specs/content-equipment.md FR-013 - the weight
    ///   printed "5 lb. (full)" keeps its parenthetical as note (Waterskin,
    ///   SRD 5.2.1, Adventuring Gear table, p. 95).
    /// Path: happy
    test('a Weight carries the printed parenthetical note', () {
      final weight = Weight(5, note: 'full');
      expect(weight.pounds, 5);
      expect(weight.note, 'full');
    });

    /// Requirement: doc/specs/content-equipment.md FR-115 - weightNote must
    ///   be non-blank when present (SRD 5.2.1, p. 95).
    /// Path: unhappy (invalid input)
    test('a blank weight note is rejected', () {
      expect(() => Weight(5, note: ' '), throwsArgumentErrorFor('note', ' '));
    });
  });
}
