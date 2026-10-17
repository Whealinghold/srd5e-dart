import 'package:srd5e/src/content/domain/obscurement.dart';
import 'package:test/test.dart';

/// Exhaustive over the enum with no default branch (FR-135).
String _describe(Obscurement obscurement) => switch (obscurement) {
  Obscurement.none => 'none',
  Obscurement.lightly => 'lightly',
  Obscurement.heavily => 'heavily',
};

void main() {
  /// Requirement: doc/specs/content-schema-and-decoder.md FR-135 - exactly
  ///   three members ordered by severity, JSON the printed name (SRD 5.2.1,
  ///   "Obscured Areas", p. 11).
  /// Path: happy
  test('declares exactly three obscurement values in severity order', () {
    expect(Obscurement.values.map((value) => value.jsonValue), [
      'None',
      'Lightly Obscured',
      'Heavily Obscured',
    ]);
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-135 - the order
  ///   is load-bearing (consumers compare by index): it rises with severity.
  /// Path: happy
  test('the index rises with severity', () {
    expect(Obscurement.none.index, lessThan(Obscurement.lightly.index));
    expect(Obscurement.lightly.index, lessThan(Obscurement.heavily.index));
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-135 - fromJson
  ///   gives null for a non-member; the decoder turns it into invalidValue
  ///   (FR-025) and never case-folds or trims.
  /// Path: unhappy (invalid input)
  test('fromJson gives null for near-miss spellings', () {
    expect(Obscurement.fromJson('Lightly'), isNull);
    expect(Obscurement.fromJson('Heavily'), isNull);
    expect(Obscurement.fromJson(' None'), isNull);
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-105 - the
  ///   static fromJson accepts exactly the jsonValue spellings.
  /// Path: happy
  test('fromJson round-trips every member', () {
    for (final value in Obscurement.values) {
      expect(Obscurement.fromJson(value.jsonValue), value);
    }
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-135 - a switch
  ///   over Obscurement is exhaustive without a default.
  /// Path: happy
  test('a switch over every member selects its case', () {
    expect(
      [for (final value in Obscurement.values) _describe(value)],
      ['none', 'lightly', 'heavily'],
    );
  });
}
