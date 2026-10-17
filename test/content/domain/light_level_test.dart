import 'package:srd5e/src/content/domain/light_level.dart';
import 'package:test/test.dart';

/// Exhaustive over the enum with no default branch (FR-133).
String _describe(LightLevel level) => switch (level) {
  LightLevel.brightLight => 'brightLight',
  LightLevel.dimLight => 'dimLight',
  LightLevel.darkness => 'darkness',
};

void main() {
  /// Requirement: doc/specs/content-schema-and-decoder.md FR-133 - exactly
  ///   three members in SRD order, JSON the printed name (SRD 5.2.1, "Light",
  ///   p. 11).
  /// Path: happy
  test('declares exactly three light levels in SRD order', () {
    expect(LightLevel.values.map((level) => level.jsonValue), [
      'Bright Light',
      'Dim Light',
      'Darkness',
    ]);
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-133 - fromJson
  ///   gives null for a non-member; the decoder turns it into invalidValue
  ///   (FR-025) and never case-folds or trims.
  /// Path: unhappy (invalid input)
  test('fromJson gives null for near-miss spellings', () {
    expect(LightLevel.fromJson('Dim light'), isNull);
    expect(LightLevel.fromJson('Bright'), isNull);
    expect(LightLevel.fromJson(' Bright Light'), isNull);
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-105 - the
  ///   static fromJson accepts exactly the jsonValue spellings.
  /// Path: happy
  test('fromJson round-trips every member', () {
    for (final level in LightLevel.values) {
      expect(LightLevel.fromJson(level.jsonValue), level);
    }
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-133 - a switch
  ///   over LightLevel is exhaustive without a default.
  /// Path: happy
  test('a switch over every member selects its case', () {
    expect(
      [for (final level in LightLevel.values) _describe(level)],
      ['brightLight', 'dimLight', 'darkness'],
    );
  });
}
