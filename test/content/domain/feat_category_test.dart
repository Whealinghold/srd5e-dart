import 'package:srd5e/src/content/domain/feat_category.dart';
import 'package:test/test.dart';

/// Exhaustive over the enum with no default branch (FR-117).
String _describe(FeatCategory category) => switch (category) {
  FeatCategory.origin => 'origin',
  FeatCategory.general => 'general',
  FeatCategory.fightingStyle => 'fightingStyle',
  FeatCategory.epicBoon => 'epicBoon',
};

void main() {
  /// Requirement: doc/specs/content-schema-and-decoder.md FR-117 - exactly
  ///   four members in SRD order, JSON the printed name with its space (SRD
  ///   5.2.1, "Parts of a Feat: Category", p. 87).
  /// Path: happy
  test('declares exactly 4 members in SRD order', () {
    expect(FeatCategory.values.map((category) => category.jsonValue), [
      'Origin',
      'General',
      'Fighting Style',
      'Epic Boon',
    ]);
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-117 and FR-025 -
  ///   the decoder must match exactly and case sensitively: the lower-case
  ///   tag is invalidValue, so fromJson gives null for it.
  /// Path: unhappy (invalid input)
  test('fromJson gives null for the lower-case tag and wrong spellings', () {
    expect(FeatCategory.fromJson('origin'), isNull);
    expect(FeatCategory.fromJson('General '), isNull);
    expect(FeatCategory.fromJson('Fighting style'), isNull);
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-105 - the
  ///   static fromJson accepts exactly the jsonValue spellings.
  /// Path: happy
  test('fromJson round-trips every member', () {
    for (final category in FeatCategory.values) {
      expect(FeatCategory.fromJson(category.jsonValue), category);
    }
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-117 - a switch
  ///   over FeatCategory is exhaustive without a default.
  /// Path: happy
  test('a switch over every member selects its case', () {
    expect(
      [for (final category in FeatCategory.values) _describe(category)],
      ['origin', 'general', 'fightingStyle', 'epicBoon'],
    );
  });
}
