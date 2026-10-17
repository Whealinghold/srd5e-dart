import 'package:srd5e/src/content/domain/spells/spell_casting_time.dart';
import 'package:test/test.dart';

import '../../../support/argument_error_matcher.dart';

/// The label a `switch` over the sealed [CastingTime] family returns, with
/// no default branch.
String castingTimeLabel(CastingTime time) => switch (time) {
  CastingTimeMagicAction() => 'magicAction',
  CastingTimeBonusAction() => 'bonusAction',
  CastingTimeReaction() => 'reaction',
  CastingTimeMinutes() => 'minutes',
  CastingTimeHours() => 'hours',
};

/// The label a `switch` over the sealed [SpellCastingTimes] family returns,
/// with no default branch.
String timesLabel(SpellCastingTimes times) => switch (times) {
  SpellCastingTimesSingle() => 'single',
  SpellCastingTimesModes() => 'modes',
};

void main() {
  /// Requirement: doc/specs/content-spells.md FR-026, FR-027, FR-028, FR-029, FR-114 - the
  ///   five sealed
  ///   CastingTime variants and their trigger and amount rules
  ///   (SRD 5.2.1, "Casting Time", p. 105).
  /// Path: happy
  group('CastingTime variants', () {
    /// Requirement: doc/specs/content-spells.md FR-026, FR-114 - CastingTime
    ///   is sealed with exactly five exported variants and the factories
    ///   return them; a switch is exhaustive (SRD 5.2.1, "Casting Time",
    ///   p. 105).
    /// Path: happy
    test('the factories return the five variants, exhaustively labelled', () {
      final times = [
        CastingTime.magicAction(),
        CastingTime.bonusAction(),
        CastingTime.reaction('when a creature you can see casts a spell'),
        CastingTime.minutes(1),
        CastingTime.hours(8),
      ];
      expect(times.map(castingTimeLabel).toSet(), {
        'magicAction',
        'bonusAction',
        'reaction',
        'minutes',
        'hours',
      });
    });

    /// Requirement: doc/specs/content-spells.md FR-027 - reaction requires a
    ///   non-empty trigger; empty or whitespace-only throws (SRD 5.2.1,
    ///   "Reaction and Bonus Action Triggers", p. 105).
    /// Path: unhappy (invalid input)
    test('reaction rejects empty and whitespace-only triggers', () {
      expect(
        () => CastingTime.reaction(''),
        throwsArgumentErrorFor('trigger', ''),
      );
      expect(
        () => CastingTime.reaction(' '),
        throwsArgumentErrorFor('trigger', ' '),
      );
      expect(
        CastingTime.reaction(
          'which a creature you can see casts a spell',
        ).trigger,
        'which a creature you can see casts a spell',
      );
    });

    /// Requirement: doc/specs/content-spells.md FR-028 - bonusAction accepts
    ///   no trigger and a non-empty trigger; an empty trigger string throws
    ///   (SRD 5.2.1, p. 105).
    /// Path: unhappy (boundary)
    test('bonusAction takes no trigger, a real one, and rejects empty', () {
      expect(CastingTime.bonusAction().trigger, isNull);
      expect(
        CastingTime.bonusAction(
          'immediately after you hit a creature with a '
          'melee weapon',
        ).trigger,
        isNotNull,
      );
      expect(
        () => CastingTime.bonusAction(''),
        throwsArgumentErrorFor('trigger', ''),
      );
    });

    /// Requirement: doc/specs/content-spells.md FR-029 - minutes(n) and
    ///   hours(n) require n of at least 1; 0 and negative throw (SRD 5.2.1,
    ///   "Longer Casting Times", p. 105).
    /// Path: unhappy (boundary)
    test('minutes and hours reject 0 and negative, accept 1', () {
      expect(() => CastingTime.minutes(0), throwsArgumentErrorFor('amount', 0));
      expect(() => CastingTime.hours(-1), throwsArgumentErrorFor('amount', -1));
      expect(CastingTime.minutes(1).amount, 1);
      expect(CastingTime.hours(1).amount, 1);
      expect(CastingTime.isValidAmount(0), isFalse);
      expect(CastingTime.isValidAmount(1), isTrue);
    });
  });

  /// Requirement: doc/specs/content-spells.md FR-030, FR-086 - one time, or at least two
  ///   labelled modes; the label rule is carried by the type (SRD 5.2.1,
  ///   "Plant Growth", p. 153).
  /// Path: unhappy (invalid input)
  group('SpellCastingTimes', () {
    /// Requirement: doc/specs/content-spells.md FR-030 - one time, or at
    ///   least two labelled modes; a switch is exhaustive (architecture.md
    ///   §3).
    /// Path: happy
    test('a single time and two labelled modes are the two variants', () {
      final single = SpellCastingTimesSingle(CastingTime.magicAction());
      final modes = SpellCastingTimesModes([
        CastingTimeMode('Overgrowth', CastingTime.magicAction()),
        CastingTimeMode('Enrichment', CastingTime.hours(8)),
      ]);
      expect(timesLabel(single), 'single');
      expect(timesLabel(modes), 'modes');
      expect(modes.modes, hasLength(2));
      expect(modes.modes.first.label, 'Overgrowth');
    });

    /// Requirement: doc/specs/content-spells.md FR-030 - fewer than two
    ///   modes throws; minModes is 2 (FR-111).
    /// Path: unhappy (invalid input)
    test('zero and one mode are rejected', () {
      expect(
        () => SpellCastingTimesModes([]),
        throwsArgumentErrorFor('modes', const <CastingTimeMode>[]),
      );
      final one = [CastingTimeMode('Solo', CastingTime.magicAction())];
      expect(
        () => SpellCastingTimesModes(one),
        throwsArgumentErrorFor('modes', one),
      );
      expect(SpellCastingTimes.minModes, 2);
    });

    /// Requirement: doc/specs/content-spells.md FR-030 - a blank label
    ///   throws (SRD 5.2.1, "Plant Growth", p. 153, has the only two
    ///   options).
    /// Path: unhappy (invalid input)
    test('a blank mode label is rejected', () {
      expect(
        () => CastingTimeMode('', CastingTime.magicAction()),
        throwsArgumentErrorFor('label', ''),
      );
    });

    /// Requirement: doc/specs/content-spells.md FR-086 - the modes list is
    ///   an unmodifiable copy; later mutation of the input does not change
    ///   it.
    /// Path: unhappy (immutability)
    test('the modes list is unmodifiable and copied', () {
      final input = [
        CastingTimeMode('Overgrowth', CastingTime.magicAction()),
        CastingTimeMode('Enrichment', CastingTime.hours(8)),
      ];
      final modes = SpellCastingTimesModes(input);
      input.removeLast();
      expect(modes.modes, hasLength(2));
      expect(() => modes.modes.removeLast(), throwsUnsupportedError);
    });
  });
}
