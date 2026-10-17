import 'package:srd5e/src/content/domain/recharge_trigger.dart';
import 'package:test/test.dart';

/// Exhaustive over the enum with no default branch (FR-112).
String _describe(RechargeTrigger trigger) => switch (trigger) {
  RechargeTrigger.shortRest => 'shortRest',
  RechargeTrigger.longRest => 'longRest',
  RechargeTrigger.shortOrLongRest => 'shortOrLongRest',
};

void main() {
  /// Requirement: doc/specs/content-schema-and-decoder.md FR-112 - exactly
  ///   three members with the SRD wordings (SRD 5.2.1, "Limited Usage",
  ///   p. 257).
  /// Path: happy
  test('declares exactly three members with the SRD wordings', () {
    expect(RechargeTrigger.values.map((trigger) => trigger.jsonValue), [
      'Short Rest',
      'Long Rest',
      'Short or Long Rest',
    ]);
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-112 - a Long
  ///   Rest is not a Short Rest: a feature lists both with
  ///   shortOrLongRest.
  /// Path: happy
  test('shortOrLongRest is its own member, not either rest alone', () {
    expect(RechargeTrigger.shortOrLongRest, isNot(RechargeTrigger.shortRest));
    expect(RechargeTrigger.shortOrLongRest, isNot(RechargeTrigger.longRest));
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-105 - the
  ///   static fromJson accepts exactly the jsonValue spellings.
  /// Path: happy
  test('fromJson round-trips every member', () {
    for (final trigger in RechargeTrigger.values) {
      expect(RechargeTrigger.fromJson(trigger.jsonValue), trigger);
    }
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-105 - fromJson
  ///   gives null for a non-member; the decoder turns it into invalidValue
  ///   (FR-025) and never case-folds or trims.
  /// Path: unhappy (invalid input)
  test('fromJson gives null for wrong case and padded spellings', () {
    expect(RechargeTrigger.fromJson('short rest'), isNull);
    expect(RechargeTrigger.fromJson(' Long Rest'), isNull);
    expect(RechargeTrigger.fromJson('Recharge 5-6'), isNull);
    expect(RechargeTrigger.fromJson('1/Day'), isNull);
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-112 - a switch
  ///   over RechargeTrigger is exhaustive without a default.
  /// Path: happy
  test('a switch over every member selects its case', () {
    expect(
      [for (final trigger in RechargeTrigger.values) _describe(trigger)],
      ['shortRest', 'longRest', 'shortOrLongRest'],
    );
  });
}
