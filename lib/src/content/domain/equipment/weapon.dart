import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import '../content_entry.dart';
import '../content_key.dart';
import '../mastery_property.dart';
import '../source_citation.dart';
import '../typed_ids.dart';
import 'price.dart';
import 'weapon_damage.dart';
import 'weapon_property_use.dart';
import 'weight_spec.dart';

/// One of the two weapon categories of the Weapons table ("Weapons",
/// SRD 5.2.1, p. 89), exhaustive in a `switch` (FR-101).
enum WeaponCategory {
  /// Simple weapons.
  simple('Simple'),

  /// Martial weapons.
  martial('Martial');

  const WeaponCategory(this.jsonValue);

  /// The printed word used in JSON.
  final String jsonValue;

  /// The member whose [jsonValue] is [value], or null for a non-member: the
  /// decoder turns a non-member into `invalidValue` (FR-105, FR-109).
  static WeaponCategory? fromJson(String value) => switch (value) {
    'Simple' => simple,
    'Martial' => martial,
    _ => null,
  };
}

/// One of the two weapon types, Melee or Ranged, as the Weapons table
/// groups them ("Weapons", SRD 5.2.1, p. 91), exhaustive in a `switch`
/// (FR-101).
///
/// A weapon's type follows its table group, not its properties: the Thrown
/// Dagger is Melee, the Thrown Dart is Ranged (FR-019).
enum WeaponType {
  /// Melee weapons.
  melee('Melee'),

  /// Ranged weapons.
  ranged('Ranged');

  const WeaponType(this.jsonValue);

  /// The printed word used in JSON.
  final String jsonValue;

  /// The member whose [jsonValue] is [value], or null for a non-member: the
  /// decoder turns a non-member into `invalidValue` (FR-105, FR-109).
  static WeaponType? fromJson(String value) => switch (value) {
    'Melee' => melee,
    'Ranged' => ranged,
    _ => null,
  };
}

/// One weapon row of the Weapons table ("Weapons", SRD 5.2.1, p. 91) as one
/// content entry of kind [ContentKind.equipment] (FR-106).
///
/// The entry holds the table's columns: category, type, damage, the property
/// uses in printed order, the one mastery property, weight and cost. The
/// properties list is an unmodifiable copy; a weapon printed "—" has an empty
/// list, and the Sling's "—" weight is [NoWeight] — a weapon never holds
/// [WeightVaries] (FR-106).
@immutable
final class Weapon implements ContentEntry {
  /// Creates a weapon from a defensive copy of [properties].
  ///
  /// Throws an [ArgumentError] carrying the name `weight` and the offending
  /// value when [weight] is [WeightVaries]: the Weapons table prints a number
  /// or an em dash, never "Varies" (FR-106).
  Weapon({
    required this.id,
    required this.name,
    this.source,
    required this.category,
    required this.weaponType,
    required this.damage,
    required List<WeaponPropertyUse> properties,
    required this.mastery,
    required this.weight,
    required this.price,
  }) : properties = List.unmodifiable(properties) {
    if (weight is WeightVaries) {
      throw ArgumentError.value(
        weight,
        'weight',
        'a weapon never has a "Varies" weight',
      );
    }
  }

  /// The weapon's id, as a typed id.
  final ItemId id;

  /// The weapon's printed name ("Longsword"), verbatim (FR-005).
  final String name;

  /// Where the entry comes from, or null when the supplying document omits
  /// it (schema FR-034).
  final SourceCitation? source;

  /// The weapon's category: Simple or Martial (FR-101).
  final WeaponCategory category;

  /// The weapon's type: Melee or Ranged, by its table group (FR-019, FR-101).
  final WeaponType weaponType;

  /// The damage the weapon deals (FR-102).
  final WeaponDamage damage;

  /// The property uses, in printed order; unmodifiable, possibly empty
  /// (FR-103, FR-106).
  final List<WeaponPropertyUse> properties;

  /// The weapon's one mastery property ("Mastery Properties",
  /// SRD 5.2.1, p. 90).
  final MasteryProperty mastery;

  /// The weight, a [Weight] or [NoWeight]; never [WeightVaries] (FR-106).
  final WeightSpec weight;

  /// The printed cost (FR-106); the type is [FixedCost], so a weapon cannot
  /// carry a "Varies" price (FR-014).
  final FixedCost price;

  @override
  ContentKey get key => id.key;

  @override
  bool operator ==(Object other) =>
      other is Weapon &&
      other.id == id &&
      other.name == name &&
      other.source == source &&
      other.category == category &&
      other.weaponType == weaponType &&
      other.damage == damage &&
      const ListEquality<WeaponPropertyUse>().equals(
        other.properties,
        properties,
      ) &&
      other.mastery == mastery &&
      other.weight == weight &&
      other.price == price;

  @override
  int get hashCode => Object.hash(
    Weapon,
    id,
    name,
    source,
    category,
    weaponType,
    damage,
    const ListEquality<WeaponPropertyUse>().hash(properties),
    mastery,
    weight,
    price,
  );

  @override
  String toString() => 'Weapon(${id.id.value})';
}
