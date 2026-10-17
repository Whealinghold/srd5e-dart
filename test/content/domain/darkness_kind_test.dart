import 'package:srd5e/src/content/domain/darkness_kind.dart';
import 'package:test/test.dart';

/// Exhaustive over the enum with no default branch (FR-134).
String _describe(DarknessKind kind) => switch (kind) {
  DarknessKind.nonmagical => 'nonmagical',
  DarknessKind.magical => 'magical',
};

void main() {
  /// Requirement: doc/specs/content-schema-and-decoder.md FR-134 - exactly
  ///   two members, JSON Nonmagical and Magical (SRD 5.2.1, "Light",
  ///   "Special Senses", p. 11).
  /// Path: happy
  test('declares exactly two darkness kinds', () {
    expect(DarknessKind.values.map((kind) => kind.jsonValue), [
      'Nonmagical',
      'Magical',
    ]);
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-134 - fromJson
  ///   gives null for a non-member; "Normal" is not a member (the SRD says
  ///   "normal and magical Darkness", p. 190).
  /// Path: unhappy (invalid input)
  test('fromJson gives null for Normal and near-miss spellings', () {
    expect(DarknessKind.fromJson('Normal'), isNull);
    expect(DarknessKind.fromJson('nonmagical'), isNull);
    expect(DarknessKind.fromJson(' Magical'), isNull);
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-105 - the
  ///   static fromJson accepts exactly the jsonValue spellings.
  /// Path: happy
  test('fromJson round-trips every member', () {
    for (final kind in DarknessKind.values) {
      expect(DarknessKind.fromJson(kind.jsonValue), kind);
    }
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-134 - a switch
  ///   over DarknessKind is exhaustive without a default.
  /// Path: happy
  test('a switch over every member selects its case', () {
    expect(
      [for (final kind in DarknessKind.values) _describe(kind)],
      ['nonmagical', 'magical'],
    );
  });
}
