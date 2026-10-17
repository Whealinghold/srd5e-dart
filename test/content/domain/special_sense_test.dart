import 'package:srd5e/src/content/domain/special_sense.dart';
import 'package:test/test.dart';

/// Exhaustive over the enum with no default branch (FR-136).
String _describe(SpecialSense sense) => switch (sense) {
  SpecialSense.blindsight => 'blindsight',
  SpecialSense.darkvision => 'darkvision',
  SpecialSense.tremorsense => 'tremorsense',
  SpecialSense.truesight => 'truesight',
};

void main() {
  /// Requirement: doc/specs/content-schema-and-decoder.md FR-136 - exactly
  ///   four members in SRD order, JSON the printed name (SRD 5.2.1,
  ///   "Special Senses", p. 11).
  /// Path: happy
  test('declares exactly four special senses in SRD order', () {
    expect(SpecialSense.values.map((sense) => sense.jsonValue), [
      'Blindsight',
      'Darkvision',
      'Tremorsense',
      'Truesight',
    ]);
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-136 - fromJson
  ///   gives null for a non-member: a sense the SRD's glossary does not
  ///   define as a special sense is rejected.
  /// Path: unhappy (invalid input)
  test('fromJson gives null for non-SRD senses and near-miss spellings', () {
    expect(SpecialSense.fromJson("Devil's Sight"), isNull);
    expect(SpecialSense.fromJson('Telepathy'), isNull);
    expect(SpecialSense.fromJson('darkvision'), isNull);
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-105 - the
  ///   static fromJson accepts exactly the jsonValue spellings.
  /// Path: happy
  test('fromJson round-trips every member', () {
    for (final sense in SpecialSense.values) {
      expect(SpecialSense.fromJson(sense.jsonValue), sense);
    }
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-136 - a switch
  ///   over SpecialSense is exhaustive without a default.
  /// Path: happy
  test('a switch over every member selects its case', () {
    expect(
      [for (final sense in SpecialSense.values) _describe(sense)],
      ['blindsight', 'darkvision', 'tremorsense', 'truesight'],
    );
  });
}
