import 'package:srd5e/src/content/domain/damage_type.dart';
import 'package:srd5e/src/content/domain/equipment/armor.dart';
import 'package:srd5e/src/content/domain/equipment/armor_category.dart';
import 'package:srd5e/src/content/domain/equipment/armor_class_rule.dart';
import 'package:srd5e/src/content/domain/equipment/coin.dart';
import 'package:srd5e/src/content/domain/equipment/cost.dart';
import 'package:srd5e/src/content/domain/equipment/price.dart';
import 'package:srd5e/src/content/domain/equipment/weapon.dart';
import 'package:srd5e/src/content/domain/equipment/weapon_damage.dart';
import 'package:srd5e/src/content/domain/equipment/weapon_property_use.dart';
import 'package:srd5e/src/content/domain/equipment/weight_spec.dart';
import 'package:srd5e/src/content/domain/mastery_property.dart';
import 'package:srd5e/src/content/domain/typed_ids.dart';
import 'package:srd5e/src/content/domain/weapon_property.dart';
import 'package:srd5e/src/shared_kernel/dice/dice_expression.dart';
import 'package:srd5e/src/shared_kernel/dice/die.dart';
import 'package:test/test.dart';

import '../../../support/argument_error_matcher.dart';

Weapon _weapon({
  List<WeaponPropertyUse> properties = const [],
  WeightSpec weight = const NoWeight(),
}) => Weapon(
  id: ItemId('longsword'),
  name: 'Longsword',
  category: WeaponCategory.martial,
  weaponType: WeaponType.melee,
  damage: WeaponDiceDamage(DiceExpression(1, Die.d8), DamageType.slashing),
  properties: properties,
  mastery: MasteryProperty.sap,
  weight: weight,
  price: FixedCost(Cost(15, Coin.gp)),
);

/// The label a `switch` over the sealed [WeaponDamage] family returns, with
/// no default branch.
String damageLabel(WeaponDamage damage) => switch (damage) {
  WeaponDiceDamage() => 'dice',
  WeaponFixedDamage() => 'fixed',
};

/// The label a `switch` over the sealed [WeaponPropertyUse] family returns,
/// with no default branch.
String useLabel(WeaponPropertyUse use) => switch (use) {
  PlainUse() => 'plain',
  AmmunitionUse() => 'ammunition',
  ThrownUse() => 'thrown',
  VersatileUse() => 'versatile',
  TwoHandedUse() => 'two-handed',
};

void main() {
  /// Requirement: doc/specs/content-equipment.md FR-019, FR-101 - the two categories and
  ///   types; a weapon's type follows its table group (SRD 5.2.1, p. 91).
  /// Path: happy
  group('WeaponCategory and WeaponType', () {
    /// Requirement: doc/specs/content-equipment.md FR-101 - WeaponCategory
    ///   is simple or martial and WeaponType melee or ranged, both
    ///   exhaustive (SRD 5.2.1, "Weapons", p. 89).
    /// Path: happy
    test('hold their two members with wire spellings', () {
      expect(WeaponCategory.values.map((c) => c.jsonValue), [
        'Simple',
        'Martial',
      ]);
      expect(WeaponType.values.map((t) => t.jsonValue), ['Melee', 'Ranged']);
      expect(WeaponCategory.fromJson('Exotic'), isNull);
      expect(WeaponType.fromJson('Thrown'), isNull);
    });

    /// Requirement: doc/specs/content-equipment.md FR-019 - a weapon's type
    ///   follows its table group, not its properties: Dart (Thrown) is
    ///   Ranged (SRD 5.2.1, Weapons table, p. 91).
    /// Path: unhappy (rule interaction)
    test('a Thrown weapon keeps its table-group type as given', () {
      final dart = Weapon(
        id: ItemId('dart'),
        name: 'Dart',
        category: WeaponCategory.simple,
        weaponType: WeaponType.ranged,
        damage: WeaponDiceDamage(
          DiceExpression(1, Die.d4),
          DamageType.piercing,
        ),
        properties: [ThrownUse(RangePair(20, 60))],
        mastery: MasteryProperty.vex,
        weight: Weight(0.25),
        price: FixedCost(Cost(5, Coin.cp)),
      );
      expect(dart.weaponType, WeaponType.ranged);
      expect(dart.properties.single, ThrownUse(RangePair(20, 60)));
    });
  });

  /// Requirement: doc/specs/content-equipment.md FR-102 - the sealed WeaponDamage: a die
  ///   expression or the Blowgun's fixed 1 (SRD 5.2.1, Weapons table,
  ///   p. 91).
  /// Path: happy
  group('WeaponDamage', () {
    /// Requirement: doc/specs/content-equipment.md FR-102 - WeaponDamage is
    ///   sealed with WeaponDiceDamage and WeaponFixedDamage, so Blowgun's
    ///   printed "1 Piercing" is a WeaponFixedDamage of 1 (SRD 5.2.1, p. 91).
    /// Path: happy
    test('switches exhaustively and holds the Blowgun fixed damage', () {
      expect(
        damageLabel(
          WeaponDiceDamage(DiceExpression(1, Die.d8), DamageType.slashing),
        ),
        'dice',
      );
      final blowgun = WeaponFixedDamage(1, DamageType.piercing);
      expect(damageLabel(blowgun), 'fixed');
      expect(blowgun.amount, 1);
      expect(blowgun.type, DamageType.piercing);
    });

    /// Requirement: doc/specs/content-equipment.md FR-102 - a die damage
    ///   carries no modifier: the table prints bare expressions
    ///   (SRD 5.2.1, p. 89).
    /// Path: unhappy (invalid input)
    test('a die damage with a modifier is rejected', () {
      expect(
        () => WeaponDiceDamage(
          DiceExpression(1, Die.d8, modifier: 1),
          DamageType.slashing,
        ),
        throwsArgumentErrorFor('dice', DiceExpression(1, Die.d8, modifier: 1)),
      );
    });

    /// Requirement: doc/specs/content-equipment.md FR-110 - fixed below 1 is
    ///   out of range (SRD 5.2.1, Weapons table, p. 91).
    /// Path: unhappy (boundary)
    test('WeaponFixedDamage of 0 is rejected; 1 is accepted', () {
      expect(
        () => WeaponFixedDamage(0, DamageType.piercing),
        throwsArgumentErrorFor('amount', 0),
      );
      expect(WeaponFixedDamage(1, DamageType.piercing).amount, 1);
    });
  });

  /// Requirement: doc/specs/content-equipment.md FR-103 - the sealed WeaponPropertyUse
  ///   family with its RangePair and ammunition data (SRD 5.2.1,
  ///   pp. 89-90).
  /// Path: happy
  group('WeaponPropertyUse', () {
    /// Requirement: doc/specs/content-equipment.md FR-103 - PlainUse holds
    ///   only Finesse, Heavy, Light, Loading, Reach (SRD 5.2.1, pp. 89-90).
    /// Path: unhappy (invalid input)
    test('PlainUse rejects a property printed with data', () {
      expect(
        () => PlainUse(WeaponProperty.thrown),
        throwsArgumentErrorFor('property', WeaponProperty.thrown),
      );
      expect(PlainUse(WeaponProperty.finesse).property, WeaponProperty.finesse);
      expect(PlainUse.isPlain(WeaponProperty.loading), isTrue);
      expect(PlainUse.isPlain(WeaponProperty.versatile), isFalse);
    });

    /// Requirement: doc/specs/content-equipment.md FR-103 - RangePair holds
    ///   normal at least 1 and long greater than normal; the five uses are
    ///   exhaustive.
    /// Path: unhappy (boundary)
    test('RangePair bounds and the exhaustive use switch', () {
      expect(() => RangePair(0, 10), throwsArgumentErrorFor('normal', 0));
      expect(() => RangePair(20, 20), throwsArgumentErrorFor('long', 20));
      // The minimum is inclusive: a normal range of exactly 1 foot is a
      // range.
      expect(RangePair(1, 2).normal, 1);
      final uses = <WeaponPropertyUse>[
        PlainUse(WeaponProperty.light),
        AmmunitionUse(RangePair(30, 120), AmmunitionType.bullet),
        ThrownUse(RangePair(20, 60)),
        VersatileUse(DiceExpression(1, Die.d10)),
        const TwoHandedUse(TwoHandedCondition.unlessMounted),
      ];
      expect(uses.map(useLabel).toSet(), {
        'plain',
        'ammunition',
        'thrown',
        'versatile',
        'two-handed',
      });
      final sling = uses[1] as AmmunitionUse;
      expect(sling.property, WeaponProperty.ammunition);
      expect(sling.ammunition, AmmunitionType.bullet);
      expect(uses[4].property, WeaponProperty.twoHanded);
    });

    /// Requirement: doc/specs/content-equipment.md FR-111 - the Two-Handed
    ///   condition "unless mounted" is the Lance's (SRD 5.2.1, p. 91).
    /// Path: happy
    test('AmmunitionType and TwoHandedCondition wire spellings', () {
      expect(AmmunitionType.values.map((a) => a.jsonValue), [
        'Arrow',
        'Bolt',
        'Bullet',
        'Needle',
      ]);
      expect(TwoHandedCondition.unlessMounted.jsonValue, 'unless mounted');
      expect(TwoHandedCondition.always.jsonValue, 'always');
      expect(AmmunitionType.fromJson('Stone'), isNull);
      expect(TwoHandedCondition.fromJson('when mounted'), isNull);
    });
  });

  /// Requirement: doc/specs/content-equipment.md FR-007, FR-106 - the Weapon entry holds
  ///   the table's columns; its lists are unmodifiable copies
  ///   (SRD 5.2.1, Weapons table, p. 91).
  /// Path: happy
  group('Weapon', () {
    /// Requirement: doc/specs/content-equipment.md FR-106 - Weapon is an
    ///   entry type with category, weaponType, damage, properties, mastery,
    ///   weight and price; a "—" properties list is empty and the Sling's
    ///   "—" weight is NoWeight (SRD 5.2.1, Weapons table, p. 91).
    /// Path: happy
    test('holds an empty properties list and a NoWeight weapon', () {
      final weapon = _weapon();
      expect(weapon.properties, isEmpty);
      expect(weapon.weight, const NoWeight());
      expect(weapon.key.kind, same(weapon.id.key.kind));
    });

    /// Requirement: doc/specs/content-equipment.md FR-007 - decoded entries
    ///   and their lists are immutable: mutating throws UnsupportedError and
    ///   the next read is unchanged; later mutation of the input does not
    ///   change the entry.
    /// Path: unhappy (immutability)
    test('the properties list is an unmodifiable copy', () {
      final input = [PlainUse(WeaponProperty.finesse)];
      final weapon = _weapon(properties: input);
      input.add(PlainUse(WeaponProperty.heavy));
      expect(weapon.properties, hasLength(1));
      expect(
        () => weapon.properties.add(PlainUse(WeaponProperty.reach)),
        throwsUnsupportedError,
      );
      expect(weapon.properties, hasLength(1));
    });

    /// Requirement: doc/specs/content-equipment.md FR-106 - a weapon never
    ///   holds a "Varies" weight: the table prints a number or an em dash.
    /// Path: unhappy (rule interaction)
    test('WeightVaries is rejected on a weapon', () {
      expect(
        () => _weapon(weight: const WeightVaries()),
        throwsArgumentErrorFor('weight', const WeightVaries()),
      );
    });
  });

  /// Requirement: doc/specs/content-equipment.md FR-004, FR-105 - the Armor entry holds
  ///   the Armor table's columns, value-compared (SRD 5.2.1, p. 92).
  /// Path: happy
  group('Armor', () {
    /// Requirement: doc/specs/content-equipment.md FR-105 - Armor is an entry
    ///   type with category, armorClass, strengthRequirement (absent where
    ///   the table prints an em dash), stealthDisadvantage, weight (always a
    ///   Weight) and price (SRD 5.2.1, Armor table, p. 92).
    /// Path: happy
    test('holds an absent Strength requirement and the full rule', () {
      final leather = Armor(
        id: ItemId('leather_armor'),
        name: 'Leather Armor',
        category: ArmorCategory.light,
        armorClass: const BaseRule(11, FullDexterity()),
        strengthRequirement: null,
        stealthDisadvantage: false,
        weight: Weight(10),
        price: FixedCost(Cost(10, Coin.gp)),
      );
      expect(leather.strengthRequirement, isNull);
      expect(leather.armorClass, const BaseRule(11, FullDexterity()));
      expect(leather.stealthDisadvantage, isFalse);
      expect(leather.weight, Weight(10));
      expect(leather.price.cost, Cost(10, Coin.gp));
    });

    /// Requirement: doc/specs/content-equipment.md FR-026 -
    ///   stealthDisadvantage is true for exactly the seven heavy-ish armors;
    ///   the entry carries the flag as printed (SRD 5.2.1, Armor table,
    ///   p. 92).
    /// Path: happy
    test('carries the printed Stealth disadvantage flag', () {
      final plate = Armor(
        id: ItemId('plate_armor'),
        name: 'Plate Armor',
        category: ArmorCategory.heavy,
        armorClass: const BaseRule(18, NoDexterity()),
        strengthRequirement: 15,
        stealthDisadvantage: true,
        weight: Weight(65),
        price: FixedCost(Cost(1500, Coin.gp)),
      );
      expect(plate.stealthDisadvantage, isTrue);
      expect(plate.strengthRequirement, 15);
    });

    /// Requirement: doc/specs/content-equipment.md FR-004 - two entries are
    ///   equal iff every field is equal (value objects, architecture.md §3).
    /// Path: happy
    test('two Armors with equal fields are equal, with equal hash codes', () {
      Armor build() => Armor(
        id: ItemId('shield'),
        name: 'Shield',
        category: ArmorCategory.shield,
        armorClass: const BonusRule(2),
        strengthRequirement: null,
        stealthDisadvantage: false,
        weight: Weight(6),
        price: FixedCost(Cost(10, Coin.gp)),
      );
      expect(build(), build());
      expect(build().hashCode, build().hashCode);
    });
  });
}
