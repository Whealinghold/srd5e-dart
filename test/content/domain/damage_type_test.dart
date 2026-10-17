import 'package:srd5e/src/content/domain/damage_type.dart';
import 'package:test/test.dart';

/// Exhaustive over the enum with no default branch (FR-107).
String _describe(DamageType type) => switch (type) {
  DamageType.acid => 'acid',
  DamageType.bludgeoning => 'bludgeoning',
  DamageType.cold => 'cold',
  DamageType.fire => 'fire',
  DamageType.force => 'force',
  DamageType.lightning => 'lightning',
  DamageType.necrotic => 'necrotic',
  DamageType.piercing => 'piercing',
  DamageType.poison => 'poison',
  DamageType.psychic => 'psychic',
  DamageType.radiant => 'radiant',
  DamageType.slashing => 'slashing',
  DamageType.thunder => 'thunder',
};

void main() {
  /// Requirement: doc/specs/content-schema-and-decoder.md FR-107 - exactly
  ///   these 13 members in Damage Types table order, JSON the printed name
  ///   (SRD 5.2.1, "Damage Types", p. 180).
  /// Path: happy
  test('declares exactly 13 members in table order', () {
    expect(DamageType.values.map((type) => type.jsonValue), [
      'Acid',
      'Bludgeoning',
      'Cold',
      'Fire',
      'Force',
      'Lightning',
      'Necrotic',
      'Piercing',
      'Poison',
      'Psychic',
      'Radiant',
      'Slashing',
      'Thunder',
    ]);
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-105 - the
  ///   static fromJson accepts exactly the jsonValue spellings.
  /// Path: happy
  test('fromJson round-trips every member', () {
    for (final type in DamageType.values) {
      expect(DamageType.fromJson(type.jsonValue), type);
    }
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-105 - fromJson
  ///   gives null for a non-member; the decoder turns it into invalidValue
  ///   (FR-025) and never case-folds or trims.
  /// Path: unhappy (invalid input)
  test('fromJson gives null for wrong case and padded spellings', () {
    expect(DamageType.fromJson('acid'), isNull);
    expect(DamageType.fromJson(' Fire'), isNull);
    expect(DamageType.fromJson('Poison '), isNull);
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-107 - a switch
  ///   over DamageType is exhaustive without a default.
  /// Path: happy
  test('a switch over every member selects its case', () {
    expect(
      [for (final type in DamageType.values) _describe(type)],
      [
        'acid',
        'bludgeoning',
        'cold',
        'fire',
        'force',
        'lightning',
        'necrotic',
        'piercing',
        'poison',
        'psychic',
        'radiant',
        'slashing',
        'thunder',
      ],
    );
  });
}
