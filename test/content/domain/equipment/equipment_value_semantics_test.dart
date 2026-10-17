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

Weapon _weapon({List<WeaponPropertyUse>? properties, WeaponDamage? damage}) =>
    Weapon(
      id: ItemId('test_longsword'),
      name: 'Test Longsword',
      category: WeaponCategory.martial,
      weaponType: WeaponType.melee,
      damage:
          damage ??
          WeaponDiceDamage(DiceExpression(1, Die.d8), DamageType.slashing),
      properties: properties ?? [PlainUse(WeaponProperty.finesse)],
      mastery: MasteryProperty.sap,
      weight: Weight(3.0),
      price: FixedCost(Cost(15, Coin.gp)),
    );

Armor _armor() => Armor(
  id: ItemId('test_plate'),
  name: 'Test Plate Armor',
  category: ArmorCategory.heavy,
  armorClass: const BaseRule(18, NoDexterity()),
  strengthRequirement: 15,
  stealthDisadvantage: true,
  weight: Weight(65.0),
  price: FixedCost(Cost(1500, Coin.gp)),
);

void main() {
  /// Requirement: doc/specs/content-equipment.md FR-093 - the Armor Class
  ///   rule family holds immutable data compared by value; the printed form
  ///   is its debugging view (architecture.md §6).
  /// Path: happy
  group('ArmorClassRule value forms', () {
    /// Requirement: doc/specs/content-equipment.md FR-093 - the three
    ///   Dexterity treatments compare by value and print their parts.
    /// Path: happy
    test('the Dexterity treatments compare and print their parts', () {
      const full = FullDexterity();
      expect(full, const FullDexterity());
      expect(full.hashCode, const FullDexterity().hashCode);
      expect(full, isNot(const CappedDexterity(2)));
      expect(full.toString(), 'FullDexterity()');

      const capped = CappedDexterity(2);
      expect(capped, const CappedDexterity(2));
      expect(capped.hashCode, const CappedDexterity(2).hashCode);
      expect(capped, isNot(const CappedDexterity(1)));
      expect(capped, isNot(const NoDexterity()));
      expect(capped.toString(), 'CappedDexterity(2)');

      const none = NoDexterity();
      expect(none, const NoDexterity());
      expect(none.hashCode, const NoDexterity().hashCode);
      expect(none, isNot(full));
      expect(none.toString(), 'NoDexterity()');
    });

    /// Requirement: doc/specs/content-equipment.md FR-093, FR-024 - the
    ///   base and bonus rules compare by value and print their parts.
    /// Path: happy
    test('the base and bonus rules compare and print their parts', () {
      const base = BaseRule(11, FullDexterity());
      expect(base, const BaseRule(11, FullDexterity()));
      expect(base.hashCode, const BaseRule(11, FullDexterity()).hashCode);
      expect(base, isNot(const BaseRule(12, FullDexterity())));
      expect(base, isNot(const BaseRule(11, NoDexterity())));
      expect(base, isNot(const BonusRule(2)));
      expect(base.toString(), 'BaseRule(11, FullDexterity())');

      const bonus = BonusRule(2);
      expect(bonus, const BonusRule(2));
      expect(bonus.hashCode, const BonusRule(2).hashCode);
      expect(bonus, isNot(const BonusRule(3)));
      expect(bonus.toString(), 'BonusRule(2)');
    });
  });

  /// Requirement: doc/specs/content-equipment.md FR-104 - don and doff
  ///   times are typed values compared by value; the categories carry them
  ///   as static facts (SRD 5.2.1, "Armor", p. 92).
  /// Path: happy
  group('don and doff time value forms', () {
    /// Requirement: doc/specs/content-equipment.md FR-104 - the two time
    ///   forms compare by value and print their parts.
    /// Path: happy
    test('the two time forms compare and print their parts', () {
      const minutes = DonDoffMinutes(5);
      expect(minutes, const DonDoffMinutes(5));
      expect(minutes.hashCode, const DonDoffMinutes(5).hashCode);
      expect(minutes, isNot(const DonDoffMinutes(1)));
      expect(minutes, isNot(const DonDoffByUtilize()));
      expect(minutes.toString(), 'DonDoffMinutes(5)');

      const utilize = DonDoffByUtilize();
      expect(utilize, const DonDoffByUtilize());
      expect(utilize.hashCode, const DonDoffByUtilize().hashCode);
      expect(utilize.toString(), 'DonDoffByUtilize()');
    });

    /// Requirement: doc/specs/content-equipment.md FR-022 - the four
    ///   categories expose their printed times.
    /// Path: happy
    test('the four categories carry their printed times', () {
      expect(ArmorCategory.light.donTime, const DonDoffMinutes(1));
      expect(ArmorCategory.light.doffTime, const DonDoffMinutes(1));
      expect(ArmorCategory.medium.donTime, const DonDoffMinutes(5));
      expect(ArmorCategory.medium.doffTime, const DonDoffMinutes(1));
      expect(ArmorCategory.heavy.donTime, const DonDoffMinutes(10));
      expect(ArmorCategory.heavy.doffTime, const DonDoffMinutes(5));
      expect(ArmorCategory.shield.donTime, const DonDoffByUtilize());
      expect(ArmorCategory.shield.doffTime, const DonDoffByUtilize());
      expect(const DonDoffMinutes(5).toString(), 'DonDoffMinutes(5)');
    });
  });

  /// Requirement: doc/specs/content-equipment.md FR-011, FR-098 - a Cost is
  ///   a value object over amount, coin and rate; the printed form
  ///   round-trips and is its debugging view (SRD 5.2.1, "Coins", p. 89).
  /// Path: happy
  group('Cost value forms', () {
    /// Requirement: doc/specs/content-equipment.md FR-011 - a cost prints
    ///   its amount and coin, with and without its rate.
    /// Path: happy
    test('a cost prints its printed form with and without a rate', () {
      expect(Cost(15, Coin.gp).toString(), 'Cost(15 GP)');
      expect(
        Cost(2, Coin.sp, per: CostRate.day).toString(),
        'Cost(2 SP per Day)',
      );
    });

    /// Requirement: doc/specs/content-equipment.md FR-013 - a FixedCost is
    ///   a value object over its cost and prints it; CostVaries is the
    ///   single "Varies" shape.
    /// Path: happy
    test('the price shapes compare and print their parts', () {
      final fixed = FixedCost(Cost(15, Coin.gp));
      expect(fixed, FixedCost(Cost(15, Coin.gp)));
      expect(fixed.hashCode, FixedCost(Cost(15, Coin.gp)).hashCode);
      expect(fixed, isNot(FixedCost(Cost(16, Coin.gp))));
      expect(fixed.toString(), 'FixedCost(Cost(15 GP))');

      const varies = CostVaries();
      expect(varies, const CostVaries());
      expect(varies.hashCode, const CostVaries().hashCode);
      expect(varies, isNot(fixed));
      expect(varies.toString(), 'CostVaries()');
    });
  });

  /// Requirement: doc/specs/content-equipment.md FR-013 - the weight family
  ///   holds the three printed shapes compared by value (SRD 5.2.1,
  ///   "Weapons", p. 91).
  /// Path: happy
  group('weight value forms', () {
    /// Requirement: doc/specs/content-equipment.md FR-013 - the three
    ///   shapes compare by value and print their parts.
    /// Path: happy
    test('the three weight shapes compare and print their parts', () {
      final pounds = Weight(3.0);
      expect(pounds, Weight(3.0));
      expect(pounds.hashCode, Weight(3.0).hashCode);
      expect(pounds, isNot(Weight(2.0)));
      expect(pounds, isNot(const NoWeight()));
      expect(pounds.toString(), 'Weight(3.0)');

      const varies = WeightVaries();
      expect(varies, const WeightVaries());
      expect(varies.hashCode, const WeightVaries().hashCode);
      expect(varies, isNot(const NoWeight()));
      expect(varies.toString(), 'WeightVaries()');

      const none = NoWeight();
      expect(none, const NoWeight());
      expect(none.hashCode, const NoWeight().hashCode);
      expect(none, isNot(pounds));
      expect(none.toString(), 'NoWeight()');
    });
  });

  /// Requirement: doc/specs/content-equipment.md FR-102 - the two damage
  ///   shapes compare by value and print their parts (SRD 5.2.1,
  ///   "Weapons", p. 91).
  /// Path: happy
  group('weapon damage value forms', () {
    /// Requirement: doc/specs/content-equipment.md FR-102 - the die and
    ///   fixed shapes compare by value and print their parts.
    /// Path: happy
    test('the damage shapes compare and print their parts', () {
      final dice = WeaponDiceDamage(
        DiceExpression(1, Die.d8),
        DamageType.slashing,
      );
      expect(
        dice,
        WeaponDiceDamage(DiceExpression(1, Die.d8), DamageType.slashing),
      );
      expect(
        dice.hashCode,
        WeaponDiceDamage(
          DiceExpression(1, Die.d8),
          DamageType.slashing,
        ).hashCode,
      );
      expect(
        dice,
        isNot(WeaponDiceDamage(DiceExpression(1, Die.d6), DamageType.slashing)),
      );
      expect(
        dice,
        isNot(WeaponDiceDamage(DiceExpression(1, Die.d8), DamageType.piercing)),
      );
      expect(dice, isNot(WeaponFixedDamage(1, DamageType.slashing)));
      expect(dice.toString(), 'WeaponDiceDamage(1d8, Slashing)');

      final fixed = WeaponFixedDamage(1, DamageType.piercing);
      expect(fixed, WeaponFixedDamage(1, DamageType.piercing));
      expect(
        fixed.hashCode,
        WeaponFixedDamage(1, DamageType.piercing).hashCode,
      );
      expect(fixed, isNot(WeaponFixedDamage(2, DamageType.piercing)));
      expect(fixed.toString(), 'WeaponFixedDamage(1, Piercing)');
    });
  });

  /// Requirement: doc/specs/content-equipment.md FR-103 - the property-use
  ///   family and its range pair compare by value and print their parts
  ///   (SRD 5.2.1, "Weapons", p. 91).
  /// Path: happy
  group('weapon property use value forms', () {
    /// Requirement: doc/specs/content-equipment.md FR-103 - a range pair
    ///   compares by value and prints both ranges.
    /// Path: happy
    test('a range pair compares and prints both ranges', () {
      final range = RangePair(80, 320);
      expect(range, RangePair(80, 320));
      expect(range.hashCode, RangePair(80, 320).hashCode);
      expect(range, isNot(RangePair(30, 120)));
      expect(range.toString(), 'RangePair(80, 320)');
    });

    /// Requirement: doc/specs/content-equipment.md FR-103 - the five use
    ///   shapes compare by value and print their parts.
    /// Path: happy
    test('the five use shapes compare and print their parts', () {
      final plain = PlainUse(WeaponProperty.finesse);
      expect(plain, PlainUse(WeaponProperty.finesse));
      expect(plain.hashCode, PlainUse(WeaponProperty.finesse).hashCode);
      expect(plain, isNot(PlainUse(WeaponProperty.reach)));
      expect(plain, isNot(ThrownUse(RangePair(20, 60))));
      expect(plain.toString(), 'PlainUse(Finesse)');

      final ammunition = AmmunitionUse(
        RangePair(80, 320),
        AmmunitionType.arrow,
      );
      expect(
        ammunition,
        AmmunitionUse(RangePair(80, 320), AmmunitionType.arrow),
      );
      expect(
        ammunition.hashCode,
        AmmunitionUse(RangePair(80, 320), AmmunitionType.arrow).hashCode,
      );
      expect(
        ammunition,
        isNot(AmmunitionUse(RangePair(80, 320), AmmunitionType.bolt)),
      );
      expect(
        ammunition,
        isNot(AmmunitionUse(RangePair(30, 120), AmmunitionType.arrow)),
      );
      expect(ammunition.toString(), 'AmmunitionUse(RangePair(80, 320), Arrow)');

      final thrown = ThrownUse(RangePair(20, 60));
      expect(thrown, ThrownUse(RangePair(20, 60)));
      expect(thrown.hashCode, ThrownUse(RangePair(20, 60)).hashCode);
      expect(thrown, isNot(ThrownUse(RangePair(20, 61))));
      expect(thrown.toString(), 'ThrownUse(RangePair(20, 60))');
      expect(thrown.property, WeaponProperty.thrown);

      final versatile = VersatileUse(DiceExpression(1, Die.d10));
      expect(versatile, VersatileUse(DiceExpression(1, Die.d10)));
      expect(
        versatile.hashCode,
        VersatileUse(DiceExpression(1, Die.d10)).hashCode,
      );
      expect(versatile, isNot(VersatileUse(DiceExpression(2, Die.d6))));
      expect(versatile.toString(), 'VersatileUse(1d10)');
      expect(versatile.property, WeaponProperty.versatile);

      const twoHanded = TwoHandedUse(TwoHandedCondition.always);
      expect(twoHanded, const TwoHandedUse(TwoHandedCondition.always));
      expect(
        twoHanded.hashCode,
        const TwoHandedUse(TwoHandedCondition.always).hashCode,
      );
      expect(
        twoHanded,
        isNot(const TwoHandedUse(TwoHandedCondition.unlessMounted)),
      );
      expect(twoHanded, isNot(plain));
      expect(twoHanded.toString(), 'TwoHandedUse(always)');
    });
  });

  /// Requirement: doc/specs/content-equipment.md FR-106, FR-105 - the
  ///   weapon and armor entries are value objects over their columns; the
  ///   printed form is their debugging view (SRD 5.2.1, "Weapons",
  ///   p. 91; "Armor", p. 92).
  /// Path: happy
  group('entry value forms', () {
    /// Requirement: doc/specs/content-equipment.md FR-106 - two weapons
    ///   built from the same columns are equal with equal hash codes and
    ///   print their id.
    /// Path: happy
    test('a weapon compares by value and prints its id', () {
      expect(_weapon(), _weapon());
      expect(_weapon().hashCode, _weapon().hashCode);
      expect(
        _weapon(),
        isNot(
          _weapon(
            properties: [
              PlainUse(WeaponProperty.finesse),
              PlainUse(WeaponProperty.reach),
            ],
          ),
        ),
      );
      expect(_weapon().toString(), 'Weapon(test_longsword)');
    });

    /// Requirement: doc/specs/content-equipment.md FR-105 - two armors
    ///   built from the same columns are equal with equal hash codes and
    ///   print their id.
    /// Path: happy
    test('an armor compares by value and prints its id', () {
      expect(_armor(), _armor());
      expect(_armor().hashCode, _armor().hashCode);
      expect(
        _armor(),
        isNot(
          Armor(
            id: ItemId('test_plate'),
            name: 'Test Plate Armor',
            category: ArmorCategory.heavy,
            armorClass: const BaseRule(18, NoDexterity()),
            strengthRequirement: null,
            stealthDisadvantage: true,
            weight: Weight(65.0),
            price: FixedCost(Cost(1500, Coin.gp)),
          ),
        ),
      );
      expect(_armor().toString(), 'Armor(test_plate)');
    });
  });
}
