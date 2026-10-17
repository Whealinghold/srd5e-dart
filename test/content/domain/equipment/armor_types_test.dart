import 'package:srd5e/src/content/domain/equipment/armor_category.dart';
import 'package:srd5e/src/content/domain/equipment/armor_class_rule.dart';
import 'package:test/test.dart';

/// The label a `switch` over the sealed [ArmorClassRule] family returns,
/// with no default branch.
String ruleLabel(ArmorClassRule rule) => switch (rule) {
  BaseRule() => 'base',
  BonusRule() => 'bonus',
};

/// The label a `switch` over the sealed [DexterityBonus] family returns,
/// with no default branch.
String dexterityLabel(DexterityBonus dexterity) => switch (dexterity) {
  FullDexterity() => 'full',
  CappedDexterity() => 'capped',
  NoDexterity() => 'none',
};

void main() {
  /// Requirement: doc/specs/content-equipment.md FR-022, FR-104 - the four armor
  ///   categories with their typed don and doff times (SRD 5.2.1,
  ///   Armor table, p. 92).
  /// Path: happy
  group('ArmorCategory', () {
    /// Requirement: doc/specs/content-equipment.md FR-104 - ArmorCategory is
    ///   light, medium, heavy, shield, exhaustive in a switch (SRD 5.2.1,
    ///   Armor table, p. 92).
    /// Path: happy
    test('holds the four categories with their wire spellings', () {
      expect(ArmorCategory.values.map((c) => c.jsonValue), [
        'Light',
        'Medium',
        'Heavy',
        'Shield',
      ]);
      expect(ArmorCategory.fromJson('Light'), ArmorCategory.light);
      expect(ArmorCategory.fromJson('Heavy Armor'), isNull);
    });

    /// Requirement: doc/specs/content-equipment.md FR-022 - donning and
    ///   doffing times are Light 1/1, Medium 5/1, Heavy 10/5, Shield
    ///   "Utilize action", as typed values, never strings (SRD 5.2.1, p. 92).
    /// Path: happy
    test('carries the printed don and doff times as typed values', () {
      expect(ArmorCategory.light.donTime, const DonDoffMinutes(1));
      expect(ArmorCategory.light.doffTime, const DonDoffMinutes(1));
      expect(ArmorCategory.medium.donTime, const DonDoffMinutes(5));
      expect(ArmorCategory.medium.doffTime, const DonDoffMinutes(1));
      expect(ArmorCategory.heavy.donTime, const DonDoffMinutes(10));
      expect(ArmorCategory.heavy.doffTime, const DonDoffMinutes(5));
      expect(ArmorCategory.shield.donTime, isA<DonDoffByUtilize>());
      expect(ArmorCategory.shield.doffTime, isA<DonDoffByUtilize>());
    });

    /// Requirement: doc/specs/content-equipment.md FR-022 - a Minutes time
    ///   carries its number and equals its equal.
    /// Path: happy
    test('DonDoffMinutes values compare by their minutes', () {
      expect(const DonDoffMinutes(5), const DonDoffMinutes(5));
      expect(
        const DonDoffMinutes(5).hashCode,
        const DonDoffMinutes(5).hashCode,
      );
      expect(const DonDoffMinutes(5) == const DonDoffMinutes(10), isFalse);
      expect(const DonDoffByUtilize(), const DonDoffByUtilize());
    });
  });

  /// Requirement: doc/specs/content-equipment.md FR-024, FR-093 - the sealed
  ///   ArmorClassRule: BaseRule with its Dexterity treatment and the
  ///   Shield's BonusRule (SRD 5.2.1, p. 92).
  /// Path: happy
  group('ArmorClassRule', () {
    /// Requirement: doc/specs/content-equipment.md FR-093 - ArmorClassRule
    ///   is sealed with exactly BaseRule and BonusRule, immutable data with
    ///   no evaluation method (SRD 5.2.1, p. 92).
    /// Path: happy
    test('switches exhaustively over BaseRule and BonusRule', () {
      expect(ruleLabel(const BaseRule(11, FullDexterity())), 'base');
      expect(ruleLabel(const BonusRule(2)), 'bonus');
    });

    /// Requirement: doc/specs/content-equipment.md FR-093 - a BaseRule holds
    ///   its base value and Dexterity treatment; the bundled treatments are
    ///   Light full, Medium capped at 2, Heavy none.
    /// Path: happy
    test('a BaseRule holds the Dexterity treatment, exhaustive', () {
      expect(dexterityLabel(const FullDexterity()), 'full');
      expect(dexterityLabel(const CappedDexterity(2)), 'capped');
      expect(dexterityLabel(const NoDexterity()), 'none');
      const rule = BaseRule(12, CappedDexterity(2));
      expect(rule.base, 12);
      expect(rule.dexterity, const CappedDexterity(2));
      expect(rule, const BaseRule(12, CappedDexterity(2)));
    });

    /// Requirement: doc/specs/content-equipment.md FR-024 - a Shield's rule
    ///   is a BonusRule of +2 (SRD 5.2.1, Armor table and "Shield", p. 92).
    /// Path: happy
    test('the Shield rule is a BonusRule of 2', () {
      const shield = BonusRule(2);
      expect(shield.bonus, 2);
      expect(shield, const BonusRule(2));
      expect(shield, isNot(const BaseRule(2, FullDexterity())));
    });
  });
}
