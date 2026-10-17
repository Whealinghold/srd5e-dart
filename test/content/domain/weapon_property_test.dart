import 'package:srd5e/src/content/domain/mastery_property.dart';
import 'package:srd5e/src/content/domain/weapon_property.dart';
import 'package:test/test.dart';

/// Exhaustive over the enum with no default branch (FR-113).
String _describeWeaponProperty(WeaponProperty property) => switch (property) {
  WeaponProperty.ammunition => 'ammunition',
  WeaponProperty.finesse => 'finesse',
  WeaponProperty.heavy => 'heavy',
  WeaponProperty.light => 'light',
  WeaponProperty.loading => 'loading',
  WeaponProperty.reach => 'reach',
  WeaponProperty.thrown => 'thrown',
  WeaponProperty.twoHanded => 'twoHanded',
  WeaponProperty.versatile => 'versatile',
};

/// Exhaustive over the enum with no default branch (FR-113).
String _describeMasteryProperty(MasteryProperty property) => switch (property) {
  MasteryProperty.cleave => 'cleave',
  MasteryProperty.graze => 'graze',
  MasteryProperty.nick => 'nick',
  MasteryProperty.push => 'push',
  MasteryProperty.sap => 'sap',
  MasteryProperty.slow => 'slow',
  MasteryProperty.topple => 'topple',
  MasteryProperty.vex => 'vex',
};

void main() {
  /// Requirement: doc/specs/content-schema-and-decoder.md FR-113 - exactly
  ///   these 9 members in Properties-section order, JSON the printed name
  ///   ("Properties", SRD 5.2.1, pp. 89-90).
  /// Path: happy
  test('declares exactly 9 weapon properties in section order', () {
    expect(WeaponProperty.values.map((property) => property.jsonValue), [
      'Ammunition',
      'Finesse',
      'Heavy',
      'Light',
      'Loading',
      'Reach',
      'Thrown',
      'Two-Handed',
      'Versatile',
    ]);
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-113 - "Range"
  ///   is a notation qualifying Ammunition and Thrown, not a property, so it
  ///   is not a member.
  /// Path: unhappy (invalid input)
  test('Range is not a weapon property', () {
    expect(WeaponProperty.fromJson('Range'), isNull);
    expect(
      WeaponProperty.values.map((p) => p.jsonValue),
      isNot(contains('Range')),
    );
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-113 - exactly
  ///   these 8 mastery properties in order ("Mastery Properties", SRD 5.2.1,
  ///   p. 90).
  /// Path: happy
  test('declares exactly 8 mastery properties in order', () {
    expect(MasteryProperty.values.map((property) => property.jsonValue), [
      'Cleave',
      'Graze',
      'Nick',
      'Push',
      'Sap',
      'Slow',
      'Topple',
      'Vex',
    ]);
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-105 - the
  ///   static fromJson accepts exactly the jsonValue spellings.
  /// Path: happy
  test('fromJson round-trips every member of both enums', () {
    for (final property in WeaponProperty.values) {
      expect(WeaponProperty.fromJson(property.jsonValue), property);
    }
    for (final property in MasteryProperty.values) {
      expect(MasteryProperty.fromJson(property.jsonValue), property);
    }
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-105 - fromJson
  ///   gives null for a non-member; the decoder turns it into invalidValue
  ///   (FR-025) and never case-folds or trims.
  /// Path: unhappy (invalid input)
  test('fromJson gives null for wrong case and padded spellings', () {
    expect(WeaponProperty.fromJson('ammunition'), isNull);
    expect(WeaponProperty.fromJson(' Heavy'), isNull);
    expect(WeaponProperty.fromJson('Two Handed'), isNull);
    expect(MasteryProperty.fromJson('cleave'), isNull);
    expect(MasteryProperty.fromJson(' Vex'), isNull);
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-113 - a switch
  ///   over each enum is exhaustive without a default.
  /// Path: happy
  test('a switch over every member selects its case', () {
    expect(
      [
        for (final property in WeaponProperty.values)
          _describeWeaponProperty(property),
      ],
      [
        'ammunition',
        'finesse',
        'heavy',
        'light',
        'loading',
        'reach',
        'thrown',
        'twoHanded',
        'versatile',
      ],
    );
    expect(
      [
        for (final property in MasteryProperty.values)
          _describeMasteryProperty(property),
      ],
      ['cleave', 'graze', 'nick', 'push', 'sap', 'slow', 'topple', 'vex'],
    );
  });
}
