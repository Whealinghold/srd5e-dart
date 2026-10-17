import 'package:srd5e/src/content/domain/creature_type.dart';
import 'package:test/test.dart';

/// Exhaustive over the enum with no default branch (FR-108).
String _describe(CreatureType type) => switch (type) {
  CreatureType.aberration => 'aberration',
  CreatureType.beast => 'beast',
  CreatureType.celestial => 'celestial',
  CreatureType.construct => 'construct',
  CreatureType.dragon => 'dragon',
  CreatureType.elemental => 'elemental',
  CreatureType.fey => 'fey',
  CreatureType.fiend => 'fiend',
  CreatureType.giant => 'giant',
  CreatureType.humanoid => 'humanoid',
  CreatureType.monstrosity => 'monstrosity',
  CreatureType.ooze => 'ooze',
  CreatureType.plant => 'plant',
  CreatureType.undead => 'undead',
};

void main() {
  /// Requirement: doc/specs/content-schema-and-decoder.md FR-108 - exactly
  ///   these 14 members in Glossary order, JSON the printed name (SRD 5.2.1,
  ///   "Creature Type", p. 179).
  /// Path: happy
  test('declares exactly 14 members in Glossary order', () {
    expect(CreatureType.values.map((type) => type.jsonValue), [
      'Aberration',
      'Beast',
      'Celestial',
      'Construct',
      'Dragon',
      'Elemental',
      'Fey',
      'Fiend',
      'Giant',
      'Humanoid',
      'Monstrosity',
      'Ooze',
      'Plant',
      'Undead',
    ]);
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-105 - the
  ///   static fromJson accepts exactly the jsonValue spellings.
  /// Path: happy
  test('fromJson round-trips every member', () {
    for (final type in CreatureType.values) {
      expect(CreatureType.fromJson(type.jsonValue), type);
    }
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-105 - fromJson
  ///   gives null for a non-member; the decoder turns it into invalidValue
  ///   (FR-025) and never case-folds or trims.
  /// Path: unhappy (invalid input)
  test('fromJson gives null for wrong case and padded spellings', () {
    expect(CreatureType.fromJson('beast'), isNull);
    expect(CreatureType.fromJson(' Dragon'), isNull);
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-108 - a switch
  ///   over CreatureType is exhaustive without a default.
  /// Path: happy
  test('a switch over every member selects its case', () {
    expect(
      [for (final type in CreatureType.values) _describe(type)],
      [
        'aberration',
        'beast',
        'celestial',
        'construct',
        'dragon',
        'elemental',
        'fey',
        'fiend',
        'giant',
        'humanoid',
        'monstrosity',
        'ooze',
        'plant',
        'undead',
      ],
    );
  });
}
