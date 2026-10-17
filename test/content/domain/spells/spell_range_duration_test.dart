import 'package:srd5e/src/content/domain/duration_unit.dart';
import 'package:srd5e/src/content/domain/spells/spell_duration.dart';
import 'package:srd5e/src/content/domain/spells/spell_range.dart';
import 'package:test/test.dart';

import '../../../support/argument_error_matcher.dart';

/// The label a `switch` over the sealed [SpellRange] family returns, with no
/// default branch.
String rangeLabel(SpellRange range) => switch (range) {
  SpellRangeSelf() => 'self',
  SpellRangeTouch() => 'touch',
  SpellRangeDistance() => 'distance',
  SpellRangeSight() => 'sight',
  SpellRangeUnlimited() => 'unlimited',
  SpellRangeSpecial() => 'special',
};

/// The label a `switch` over the sealed [SpellDuration] family returns, with
/// no default branch.
String durationLabel(SpellDuration duration) => switch (duration) {
  SpellDurationInstantaneous() => 'instantaneous',
  SpellDurationTimed() => 'timed',
  SpellDurationUntilDispelled() => 'untilDispelled',
  SpellDurationUntilDispelledOrTriggered() => 'untilDispelledOrTriggered',
  SpellDurationSpecial() => 'special',
};

void main() {
  /// Requirement: doc/specs/content-spells.md FR-036, FR-037, FR-119 - the six sealed
  ///   range variants; distance requires 1 or more feet or miles
  ///   (SRD 5.2.1, "Range", p. 105).
  /// Path: unhappy (boundary)
  group('SpellRange', () {
    /// Requirement: doc/specs/content-spells.md FR-036, FR-114 - SpellRange
    ///   is sealed with exactly six exported variants and the factories
    ///   return them (SRD 5.2.1, "Range", p. 105).
    /// Path: happy
    test('the factories return the six variants, exhaustively labelled', () {
      final ranges = [
        SpellRange.self(),
        SpellRange.touch(),
        SpellRange.distance(30, DistanceUnit.feet),
        SpellRange.sight(),
        SpellRange.unlimited(),
        SpellRange.special(),
      ];
      expect(ranges.map(rangeLabel).toSet(), {
        'self',
        'touch',
        'distance',
        'sight',
        'unlimited',
        'special',
      });
    });

    /// Requirement: doc/specs/content-spells.md FR-037 - distance requires
    ///   an amount of at least 1 and a unit of feet or miles; 0 and negative
    ///   throw (SRD 5.2.1, p. 105; Clairvoyance p. 115, Project Image
    ///   p. 156).
    /// Path: unhappy (boundary)
    test('distance rejects 0 and negative, accepts feet and miles', () {
      expect(
        () => SpellRange.distance(0, DistanceUnit.feet),
        throwsArgumentErrorFor('amount', 0),
      );
      expect(
        () => SpellRange.distance(-5, DistanceUnit.miles),
        throwsArgumentErrorFor('amount', -5),
      );
      expect(
        SpellRange.distance(1, DistanceUnit.miles).unit,
        DistanceUnit.miles,
      );
      expect(SpellRange.isValidDistance(0), isFalse);
      expect(SpellRange.isValidDistance(1), isTrue);
    });

    /// Requirement: doc/specs/content-spells.md FR-119 - DistanceUnit has
    ///   exactly feet and miles, with the package spellings.
    /// Path: happy
    test('DistanceUnit holds feet and miles', () {
      expect(DistanceUnit.values.map((u) => u.jsonValue), ['feet', 'miles']);
      expect(DistanceUnit.fromJson('furlongs'), isNull);
    });
  });

  /// Requirement: doc/specs/content-spells.md FR-050, FR-051, FR-052 - the five sealed
  ///   duration
  ///   variants; the DurationLimit replaces the two flags (SRD 5.2.1,
  ///   "Duration", p. 106).
  /// Path: unhappy (boundary)
  group('SpellDuration', () {
    /// Requirement: doc/specs/content-spells.md FR-050, FR-114 - SpellDuration
    ///   is sealed with exactly five exported variants and the factories
    ///   return them (SRD 5.2.1, "Duration", p. 106).
    /// Path: happy
    test('the factories return the five variants, exhaustively labelled', () {
      final durations = [
        SpellDuration.instantaneous(),
        SpellDuration.timed(1, DurationUnit.hours, DurationLimit.fixed),
        SpellDuration.untilDispelled(),
        SpellDuration.untilDispelledOrTriggered(),
        SpellDuration.special(),
      ];
      expect(durations.map(durationLabel).toSet(), {
        'instantaneous',
        'timed',
        'untilDispelled',
        'untilDispelledOrTriggered',
        'special',
      });
    });

    /// Requirement: doc/specs/content-spells.md FR-051 - timed requires an
    ///   amount of at least 1 and a DurationUnit of rounds, minutes, hours
    ///   or days; 0 and negative throw (SRD 5.2.1, p. 106; Mirage Arcane
    ///   p. 149, Geas p. 135).
    /// Path: unhappy (boundary)
    test('timed rejects 0 and negative, accepts each unit', () {
      expect(
        () => SpellDuration.timed(0, DurationUnit.rounds, DurationLimit.fixed),
        throwsArgumentErrorFor('amount', 0),
      );
      expect(
        () => SpellDuration.timed(
          -1,
          DurationUnit.days,
          DurationLimit.concentrationUpTo,
        ),
        throwsArgumentErrorFor('amount', -1),
      );
      for (final unit in DurationUnit.values) {
        expect(SpellDuration.timed(1, unit, DurationLimit.fixed).unit, unit);
      }
      expect(SpellDuration.isValidAmount(0), isFalse);
      expect(SpellDuration.isValidAmount(1), isTrue);
    });

    /// Requirement: doc/specs/content-spells.md FR-052 - a Time Span carries
    ///   a DurationLimit in place of two flags, so Concentration without a
    ///   cap cannot be expressed (SRD 5.2.1, p. 106).
    /// Path: happy
    test('the limit is carried, and the enum has the three values', () {
      final concentration = SpellDuration.timed(
        10,
        DurationUnit.minutes,
        DurationLimit.concentrationUpTo,
      );
      expect(concentration.limit, DurationLimit.concentrationUpTo);
      expect(concentration.amount, 10);
      expect(DurationLimit.values.map((l) => l.jsonValue), [
        'fixed',
        'upTo',
        'concentrationUpTo',
      ]);
      expect(DurationLimit.fromJson('concentration'), isNull);
    });
  });
}
