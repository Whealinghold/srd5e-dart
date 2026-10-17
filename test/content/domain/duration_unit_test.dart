import 'package:srd5e/src/content/domain/duration_unit.dart';
import 'package:test/test.dart';

/// Exhaustive over the enum with no default branch (FR-149).
String _describe(DurationUnit unit) => switch (unit) {
  DurationUnit.rounds => 'rounds',
  DurationUnit.minutes => 'minutes',
  DurationUnit.hours => 'hours',
  DurationUnit.days => 'days',
};

void main() {
  /// Requirement: doc/specs/content-schema-and-decoder.md FR-149 - exactly
  ///   four members in ascending order, JSON the Dart name (a package tag in
  ///   lower camel case; SRD 5.2.1, "Duration" (Time Span), p. 106).
  /// Path: happy
  test('declares exactly four members in ascending order', () {
    expect(DurationUnit.values.map((unit) => unit.jsonValue), [
      'rounds',
      'minutes',
      'hours',
      'days',
    ]);
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-149 - the JSON
  ///   value is the package tag, so Rounds, hour and years are non-members
  ///   and the decoder reports invalidValue for them (FR-025).
  /// Path: unhappy (invalid input)
  test('fromJson gives null for wrong case, singular and years', () {
    expect(DurationUnit.fromJson('Rounds'), isNull);
    expect(DurationUnit.fromJson('hour'), isNull);
    expect(DurationUnit.fromJson('years'), isNull);
    expect(DurationUnit.fromJson(' Hours'), isNull);
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-105 - the
  ///   static fromJson accepts exactly the jsonValue spellings.
  /// Path: happy
  test('fromJson round-trips every member', () {
    for (final unit in DurationUnit.values) {
      expect(DurationUnit.fromJson(unit.jsonValue), unit);
    }
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-149 - the type
  ///   carries no fact and no conversion to a Dart Duration; a switch over
  ///   it is exhaustive without a default.
  /// Path: happy
  test('a switch over every member selects its case', () {
    expect(
      [for (final unit in DurationUnit.values) _describe(unit)],
      ['rounds', 'minutes', 'hours', 'days'],
    );
  });
}
