import 'package:meta/meta.dart';

import '../content_entry.dart';
import '../content_key.dart';
import '../source_citation.dart';
import '../typed_ids.dart';
import 'armor_category.dart';
import 'armor_class_rule.dart';
import 'price.dart';
import 'weight_spec.dart';

/// One armor row of the Armor table ("Armor", SRD 5.2.1, p. 92) as one
/// content entry of kind [ContentKind.equipment] (FR-105).
///
/// The entry holds the table's columns: category, the Armor Class rule
/// ([BaseRule] for every body armor, [BonusRule] +2 for the Shield, FR-024),
/// the optional Strength requirement where the table prints one, the Stealth
/// disadvantage flag, the weight — always a [Weight], the Armor table prints
/// no "—" or "Varies" — and the cost. Donning and doffing times are static
/// facts of the [ArmorCategory] and are not repeated here (FR-022). Computing
/// an Armor Class is the equipment rules' concern; this entry is data.
@immutable
final class Armor implements ContentEntry {
  /// Creates an armor entry.
  ///
  /// [strengthRequirement] is absent where the table prints "—" (FR-105);
  /// its 1-to-30 range is a decoder rule (FR-109), not a constructor rule.
  Armor({
    required this.id,
    required this.name,
    this.source,
    required this.category,
    required this.armorClass,
    required this.strengthRequirement,
    required this.stealthDisadvantage,
    required this.weight,
    required this.price,
  });

  /// The armor's id, as a typed id.
  final ItemId id;

  /// The armor's printed name ("Plate Armor"), verbatim (FR-005).
  final String name;

  /// Where the entry comes from, or null when the supplying document omits
  /// it (schema FR-034).
  final SourceCitation? source;

  /// The armor's category, which carries its don and doff times (FR-104,
  /// FR-022).
  final ArmorCategory category;

  /// The Armor Class rule (FR-093).
  final ArmorClassRule armorClass;

  /// The Strength requirement, or null where the table prints "—" (FR-105).
  final int? strengthRequirement;

  /// Whether the armor gives disadvantage on Stealth ("Stealth" column,
  /// SRD 5.2.1, p. 92) (FR-026).
  final bool stealthDisadvantage;

  /// The weight, always a [Weight] (FR-105).
  final Weight weight;

  /// The printed cost (FR-105); the type is [FixedCost], so an armor cannot
  /// carry a "Varies" price (FR-014).
  final FixedCost price;

  @override
  ContentKey get key => id.key;

  @override
  bool operator ==(Object other) =>
      other is Armor &&
      other.id == id &&
      other.name == name &&
      other.source == source &&
      other.category == category &&
      other.armorClass == armorClass &&
      other.strengthRequirement == strengthRequirement &&
      other.stealthDisadvantage == stealthDisadvantage &&
      other.weight == weight &&
      other.price == price;

  @override
  int get hashCode => Object.hash(
    Armor,
    id,
    name,
    source,
    category,
    armorClass,
    strengthRequirement,
    stealthDisadvantage,
    weight,
    price,
  );

  @override
  String toString() => 'Armor(${id.id.value})';
}
