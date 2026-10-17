import 'package:srd5e/src/content/domain/content_entry.dart';
import 'package:srd5e/src/content/domain/damage_type.dart';
import 'package:srd5e/src/content/domain/equipment/armor.dart';
import 'package:srd5e/src/content/domain/equipment/armor_category.dart';
import 'package:srd5e/src/content/domain/equipment/armor_class_rule.dart';
import 'package:srd5e/src/content/domain/equipment/coin.dart';
import 'package:srd5e/src/content/domain/equipment/cost.dart';
import 'package:srd5e/src/content/domain/equipment/equipment_category.dart';
import 'package:srd5e/src/content/domain/equipment/price.dart';
import 'package:srd5e/src/content/domain/equipment/weapon.dart';
import 'package:srd5e/src/content/domain/equipment/weapon_damage.dart';
import 'package:srd5e/src/content/domain/equipment/weight_spec.dart';
import 'package:srd5e/src/content/domain/mastery_property.dart';
import 'package:srd5e/src/content/domain/typed_ids.dart';
import 'package:srd5e/src/shared_kernel/dice/dice_expression.dart';
import 'package:srd5e/src/shared_kernel/dice/die.dart';
import 'package:test/test.dart';

/// The label a `switch` over [EquipmentCategory] returns, with no default
/// branch.
String categoryLabel(EquipmentCategory category) => switch (category) {
  EquipmentCategory.weapon => 'weapon',
  EquipmentCategory.armor => 'armor',
  EquipmentCategory.tool => 'tool',
  EquipmentCategory.adventuringGear => 'adventuringGear',
  EquipmentCategory.mount => 'mount',
  EquipmentCategory.tackHarnessOrDrawnVehicle => 'tack',
  EquipmentCategory.airborneOrWaterborneVehicle => 'vehicle',
  EquipmentCategory.lifestyleExpense => 'lifestyle',
  EquipmentCategory.foodDrinkOrLodging => 'food',
  EquipmentCategory.hireling => 'hireling',
  EquipmentCategory.spellcastingService => 'services',
  EquipmentCategory.spellScrollCost => 'scrollCosts',
};

void main() {
  /// Requirement: doc/specs/content-equipment.md FR-002 - exactly the twelve table
  ///   families, exhaustive in a switch (SRD 5.2.1, "Equipment",
  ///   pp. 89-103).
  /// Path: happy
  group('EquipmentCategory', () {
    /// Requirement: doc/specs/content-equipment.md FR-002 - exactly twelve
    ///   values named for the SRD tables; a switch over it is exhaustive
    ///   (SRD 5.2.1, "Equipment", pp. 89-103).
    /// Path: happy
    test('holds the twelve table families in chapter order', () {
      expect(EquipmentCategory.values.map((c) => c.jsonValue).toList(), [
        'weapon',
        'armor',
        'tool',
        'adventuringGear',
        'mount',
        'tackHarnessOrDrawnVehicle',
        'airborneOrWaterborneVehicle',
        'lifestyleExpense',
        'foodDrinkOrLodging',
        'hireling',
        'spellcastingService',
        'spellScrollCost',
      ]);
    });

    /// Requirement: doc/specs/content-equipment.md FR-002 - a switch over
    ///   EquipmentCategory is exhaustive without a default.
    /// Path: happy
    test('labels every member exhaustively', () {
      expect(categoryLabel(EquipmentCategory.spellScrollCost), 'scrollCosts');
      expect(categoryLabel(EquipmentCategory.weapon), 'weapon');
    });

    /// Requirement: doc/specs/content-equipment.md FR-002 - a non-member is
    ///   not a category; the decoder turns it into invalidValue (FR-105).
    /// Path: unhappy (invalid input)
    test('fromJson accepts members and rejects a non-member', () {
      expect(EquipmentCategory.fromJson('weapon'), EquipmentCategory.weapon);
      expect(
        EquipmentCategory.fromJson('spellScrollCost'),
        EquipmentCategory.spellScrollCost,
      );
      expect(EquipmentCategory.fromJson('shields'), isNull);
    });
  });

  /// Requirement: doc/specs/content-equipment.md FR-001 - every equipment entry
  ///   implements ContentEntry with key kind equipment (the port spec).
  /// Path: happy
  group('equipment entries', () {
    /// Requirement: doc/specs/content-equipment.md FR-001 - every decoded
    ///   equipment entry implements ContentEntry with key kind equipment and
    ///   the entry's id (content-source-port.md).
    /// Path: happy
    test('a Weapon and an Armor are ContentEntries of kind equipment', () {
      final ContentEntry weapon = Weapon(
        id: ItemId('club'),
        name: 'Club',
        category: WeaponCategory.simple,
        weaponType: WeaponType.melee,
        damage: WeaponDiceDamage(
          DiceExpression(1, Die.d4),
          DamageType.bludgeoning,
        ),
        properties: const [],
        mastery: MasteryProperty.sap,
        weight: Weight(2),
        price: FixedCost(Cost(1, Coin.sp)),
      );
      final ContentEntry armor = Armor(
        id: ItemId('padded_armor'),
        name: 'Padded Armor',
        category: ArmorCategory.light,
        armorClass: const BaseRule(11, FullDexterity()),
        strengthRequirement: null,
        stealthDisadvantage: true,
        weight: Weight(8),
        price: FixedCost(Cost(5, Coin.gp)),
      );
      expect(weapon.key.kind.name, 'equipment');
      expect(weapon.key.id.value, 'club');
      expect(armor.key.kind.name, 'equipment');
      expect(armor.key.id.value, 'padded_armor');
      expect((armor as Armor).price, isA<FixedCost>());
      expect((weapon as Weapon).price, isA<FixedCost>());
    });
  });
}
