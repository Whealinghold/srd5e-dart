import 'package:srd5e/src/content/domain/alignment.dart';
import 'package:test/test.dart';

/// Exhaustive over the enum with no default branch (FR-137).
String _describe(Alignment alignment) => switch (alignment) {
  Alignment.lawfulGood => 'lawfulGood',
  Alignment.neutralGood => 'neutralGood',
  Alignment.chaoticGood => 'chaoticGood',
  Alignment.lawfulNeutral => 'lawfulNeutral',
  Alignment.neutral => 'neutral',
  Alignment.chaoticNeutral => 'chaoticNeutral',
  Alignment.lawfulEvil => 'lawfulEvil',
  Alignment.neutralEvil => 'neutralEvil',
  Alignment.chaoticEvil => 'chaoticEvil',
  Alignment.unaligned => 'unaligned',
};

void main() {
  /// Requirement: doc/specs/content-schema-and-decoder.md FR-137 - exactly
  ///   ten members in this order, JSON the printed full name (SRD 5.2.1,
  ///   "The Nine Alignments", p. 21; "Unaligned Creatures", p. 22).
  /// Path: happy
  test('declares exactly ten members in FR-137 order', () {
    expect(Alignment.values.map((alignment) => alignment.jsonValue), [
      'Lawful Good',
      'Neutral Good',
      'Chaotic Good',
      'Lawful Neutral',
      'Neutral',
      'Chaotic Neutral',
      'Lawful Evil',
      'Neutral Evil',
      'Chaotic Evil',
      'Unaligned',
    ]);
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-137 - the
  ///   abbreviation is invalidValue: the JSON spelling is the printed full
  ///   name, never `LG`, and the wrong case is a non-member.
  /// Path: unhappy (boundary)
  test('fromJson gives null for the abbreviation and wrong case', () {
    expect(Alignment.fromJson('LG'), isNull);
    expect(Alignment.fromJson('Lawful good'), isNull);
    expect(Alignment.fromJson(' Lawful Good'), isNull);
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-137 - they are
  ///   exactly the values stat blocks print; none prints "Any Alignment".
  /// Path: unhappy (boundary)
  test('fromJson gives null for Any Alignment', () {
    expect(Alignment.fromJson('Any Alignment'), isNull);
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-105 - the
  ///   static fromJson accepts exactly the jsonValue spellings.
  /// Path: happy
  test('fromJson round-trips every member', () {
    for (final alignment in Alignment.values) {
      expect(Alignment.fromJson(alignment.jsonValue), alignment);
    }
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-137 - a switch
  ///   over Alignment is exhaustive without a default.
  /// Path: happy
  test('a switch over every member selects its case', () {
    expect(
      [for (final alignment in Alignment.values) _describe(alignment)],
      [
        'lawfulGood',
        'neutralGood',
        'chaoticGood',
        'lawfulNeutral',
        'neutral',
        'chaoticNeutral',
        'lawfulEvil',
        'neutralEvil',
        'chaoticEvil',
        'unaligned',
      ],
    );
  });
}
