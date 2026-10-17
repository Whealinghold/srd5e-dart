import 'package:srd5e/src/content/domain/content_text_block.dart';
import 'package:srd5e/src/content/domain/duration_unit.dart';
import 'package:srd5e/src/content/domain/spells/class_spell_list.dart';
import 'package:srd5e/src/content/domain/spells/spell.dart';
import 'package:srd5e/src/content/domain/spells/spell_casting_time.dart';
import 'package:srd5e/src/content/domain/spells/spell_components.dart';
import 'package:srd5e/src/content/domain/spells/spell_duration.dart';
import 'package:srd5e/src/content/domain/spells/spell_level.dart';
import 'package:srd5e/src/content/domain/spells/spell_range.dart';
import 'package:srd5e/src/content/domain/spells/spell_school.dart';
import 'package:srd5e/src/content/domain/typed_ids.dart';
import 'package:test/test.dart';

Spell _spell({String id = 'test_spark', int level = 0}) => Spell(
  id: SpellId(id),
  name: 'Test Spark',
  level: SpellLevel(level),
  school: SpellSchool.evocation,
  classes: {ClassId('wizard')},
  castingTimes: SpellCastingTimesSingle(CastingTime.magicAction()),
  ritual: false,
  range: SpellRange.distance(30, DistanceUnit.feet),
  components: SpellComponents(verbal: true, somatic: true),
  duration: SpellDuration.instantaneous(),
  description: [ContentTextBlock.paragraph('A synthetic spark for the test.')],
);

void main() {
  /// Requirement: doc/specs/content-spells.md FR-087 - two spells are equal
  ///   iff all fields are equal; the printed form is the entry's debugging
  ///   view (architecture.md §6).
  /// Path: happy
  group('Spell value forms', () {
    /// Requirement: doc/specs/content-spells.md FR-087 - a spell prints its
    ///   id as its debugging form.
    /// Path: happy
    test('a spell prints its id', () {
      expect(_spell(id: 'acid_arrow').toString(), 'Spell(acid_arrow)');
    });
  });

  /// Requirement: doc/specs/content-spells.md FR-009, FR-010 - a spell
  ///   level and its parse results are value objects that print their
  ///   parts (SRD 5.2.1, "Spell Level", p. 104).
  /// Path: happy
  group('SpellLevel value forms', () {
    /// Requirement: doc/specs/content-spells.md FR-009 - a level prints
    ///   itself.
    /// Path: happy
    test('a spell level prints its level', () {
      expect(SpellLevel(2).toString(), 'SpellLevel(2)');
    });

    /// Requirement: doc/specs/content-spells.md FR-010 - the accepted
    ///   result compares by value, hashes consistently and prints the
    ///   created level.
    /// Path: happy
    test('the parsed result compares, hashes and prints', () {
      final parsed = SpellLevel.tryCreate(0);
      expect(parsed, SpellLevel.tryCreate(0));
      expect(parsed.hashCode, SpellLevel.tryCreate(0).hashCode);
      expect(parsed.toString(), 'SpellLevelParsed(SpellLevel(0))');
    });

    /// Requirement: doc/specs/content-spells.md FR-010 - the rejected
    ///   result compares by value, hashes consistently and prints the
    ///   rejected integer.
    /// Path: happy
    test('the rejected result compares, hashes and prints', () {
      final rejected = SpellLevel.tryCreate(10);
      expect(rejected, SpellLevel.tryCreate(10));
      expect(rejected.hashCode, SpellLevel.tryCreate(10).hashCode);
      expect(rejected, isNot(SpellLevel.tryCreate(11)));
      expect(rejected.toString(), 'SpellLevelRejected(10)');
    });
  });

  /// Requirement: doc/specs/content-spells.md FR-120, FR-121 - a derived
  ///   class spell list hashes consistently with its groups and prints its
  ///   class and group sizes.
  /// Path: happy
  group('ClassSpellList value forms', () {
    /// Requirement: doc/specs/content-spells.md FR-120, FR-121 - two lists
    ///   over the same spells hash equally and the list prints its class
    ///   and per-level counts.
    /// Path: happy
    test('a derived list hashes with its groups and prints its counts', () {
      final a = classSpellList(ClassId('wizard'), [
        _spell(),
        _spell(level: 2, id: 'test_bolt'),
      ]);
      final b = classSpellList(ClassId('wizard'), [
        _spell(level: 2, id: 'test_bolt'),
        _spell(),
      ]);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a.toString(), 'ClassSpellList(wizard, 1/0/1/0/0/0/0/0/0/0)');
    });
  });

  /// Requirement: doc/specs/content-spells.md FR-026 - the five Casting
  ///   Time forms, their labelled options and the two option shapes are
  ///   value objects that print their parts (SRD 5.2.1, "Casting Time",
  ///   p. 105).
  /// Path: happy
  group('casting time value forms', () {
    /// Requirement: doc/specs/content-spells.md FR-026 - the Magic action
    ///   form is single and prints its form.
    /// Path: happy
    test('the Magic action form is single and prints', () {
      const time = CastingTimeMagicAction();
      expect(time, const CastingTimeMagicAction());
      expect(time.hashCode, const CastingTimeMagicAction().hashCode);
      expect(time, isNot(CastingTime.bonusAction()));
      expect(time.toString(), 'CastingTimeMagicAction()');
    });

    /// Requirement: doc/specs/content-spells.md FR-028 - a Bonus Action
    ///   compares by value over its optional trigger and prints both
    ///   shapes.
    /// Path: happy
    test(
      'the Bonus Action forms compare and print with and without trigger',
      () {
        final plain = CastingTime.bonusAction();
        expect(plain, CastingTimeBonusAction(null));
        expect(plain.hashCode, CastingTimeBonusAction(null).hashCode);
        expect(plain, isNot(CastingTimeBonusAction('when the bell tolls')));
        expect(plain.toString(), 'CastingTimeBonusAction()');

        final triggered = CastingTimeBonusAction('when the bell tolls');
        expect(triggered, CastingTimeBonusAction('when the bell tolls'));
        expect(
          triggered.hashCode,
          CastingTimeBonusAction('when the bell tolls').hashCode,
        );
        expect(
          triggered.toString(),
          'CastingTimeBonusAction(when the bell tolls)',
        );
      },
    );

    /// Requirement: doc/specs/content-spells.md FR-027 - a Reaction
    ///   compares by value over its trigger and prints it.
    /// Path: happy
    test('the Reaction form compares and prints its trigger', () {
      final time = CastingTime.reaction('when the bell tolls');
      expect(time, CastingTime.reaction('when the bell tolls'));
      expect(
        time.hashCode,
        CastingTime.reaction('when the bell tolls').hashCode,
      );
      expect(time, isNot(CastingTime.reaction('when the drum beats')));
      expect(time, isNot(CastingTimeBonusAction('when the bell tolls')));
      expect(time.toString(), 'CastingTimeReaction(when the bell tolls)');
    });

    /// Requirement: doc/specs/content-spells.md FR-029 - the Minutes and
    ///   Hours forms compare by value over their amount and print it.
    /// Path: happy
    test('the Minutes and Hours forms compare and print their amount', () {
      final minutes = CastingTime.minutes(1);
      expect(minutes, CastingTime.minutes(1));
      expect(minutes.hashCode, CastingTime.minutes(1).hashCode);
      expect(minutes, isNot(CastingTime.minutes(2)));
      expect(minutes, isNot(CastingTime.hours(1)));
      expect(minutes.toString(), 'CastingTimeMinutes(1)');

      final hours = CastingTime.hours(12);
      expect(hours, CastingTime.hours(12));
      expect(hours.hashCode, CastingTime.hours(12).hashCode);
      expect(hours, isNot(CastingTime.hours(24)));
      expect(hours.toString(), 'CastingTimeHours(12)');
    });

    /// Requirement: doc/specs/content-spells.md FR-030 - a labelled option
    ///   compares by value over label and time.
    /// Path: happy
    test('a labelled mode compares and prints its label', () {
      final mode = CastingTimeMode('Overgrowth', CastingTime.magicAction());
      expect(mode, CastingTimeMode('Overgrowth', CastingTime.magicAction()));
      expect(
        mode.hashCode,
        CastingTimeMode('Overgrowth', CastingTime.magicAction()).hashCode,
      );
      expect(
        mode,
        isNot(CastingTimeMode('Enrichment', CastingTime.magicAction())),
      );
      expect(mode.toString(), 'CastingTimeMode(Overgrowth)');
    });

    /// Requirement: doc/specs/content-spells.md FR-030 - the single and
    ///   multi-option shapes compare by value and print their options.
    /// Path: happy
    test('the option shapes compare and print their options', () {
      final single = SpellCastingTimesSingle(CastingTime.magicAction());
      expect(single, SpellCastingTimesSingle(CastingTime.magicAction()));
      expect(
        single.hashCode,
        SpellCastingTimesSingle(CastingTime.magicAction()).hashCode,
      );
      expect(single, isNot(SpellCastingTimesSingle(CastingTime.minutes(1))));
      expect(
        single.toString(),
        'SpellCastingTimesSingle(CastingTimeMagicAction())',
      );

      List<CastingTimeMode> modes() => [
        CastingTimeMode('Overgrowth', CastingTime.magicAction()),
        CastingTimeMode('Enrichment', CastingTime.hours(8)),
      ];
      final multi = SpellCastingTimesModes(modes());
      expect(multi, SpellCastingTimesModes(modes()));
      expect(multi.hashCode, SpellCastingTimesModes(modes()).hashCode);
      expect(
        multi,
        isNot(
          SpellCastingTimesModes([
            CastingTimeMode('Enrichment', CastingTime.hours(8)),
            CastingTimeMode('Overgrowth', CastingTime.magicAction()),
          ]),
        ),
        reason: 'the options are an ordered list',
      );
      expect(
        multi.toString(),
        'SpellCastingTimesModes([CastingTimeMode(Overgrowth), '
        'CastingTimeMode(Enrichment)])',
      );
    });
  });

  /// Requirement: doc/specs/content-spells.md FR-041, FR-043, FR-049 - the
  ///   Material component and the Components entry are value objects that
  ///   print their parts (SRD 5.2.1, "Components", p. 105).
  /// Path: happy
  group('component value forms', () {
    /// Requirement: doc/specs/content-spells.md FR-041, FR-043 - a
    ///   Material component hashes over its fields and prints its
    ///   description.
    /// Path: happy
    test('a Material component hashes over its fields and prints', () {
      MaterialComponent build() => MaterialComponent('a diamond worth 50+ GP', [
        50,
      ], consumesMaterial: true);
      final component = build();
      expect(component, build());
      expect(component.hashCode, build().hashCode);
      expect(component.toString(), 'MaterialComponent(a diamond worth 50+ GP)');
    });

    /// Requirement: doc/specs/content-spells.md FR-049 - the Components
    ///   entry prints which letters it carries.
    /// Path: happy
    test('the Components entry prints its letters', () {
      final components = SpellComponents(
        verbal: true,
        somatic: true,
        material: MaterialComponent('a diamond worth 50+ GP', [
          50,
        ], consumesMaterial: true),
      );
      expect(
        components.toString(),
        'SpellComponents(v: true, s: true, m: true)',
      );
      expect(
        SpellComponents(verbal: false, somatic: true).toString(),
        'SpellComponents(v: false, s: true, m: false)',
      );
    });
  });

  /// Requirement: doc/specs/content-spells.md FR-050 - the five Duration
  ///   forms are value objects that print their parts (SRD 5.2.1,
  ///   "Duration", p. 106).
  /// Path: happy
  group('duration value forms', () {
    /// Requirement: doc/specs/content-spells.md FR-050 - the five forms
    ///   compare by value and print their parts.
    /// Path: happy
    test('the five duration forms compare and print their parts', () {
      const instant = SpellDurationInstantaneous();
      expect(instant, const SpellDurationInstantaneous());
      expect(instant.hashCode, const SpellDurationInstantaneous().hashCode);
      expect(instant, isNot(SpellDuration.untilDispelled()));
      expect(instant.toString(), 'SpellDurationInstantaneous()');

      final timed = SpellDuration.timed(
        1,
        DurationUnit.rounds,
        DurationLimit.fixed,
      );
      expect(
        timed,
        SpellDuration.timed(1, DurationUnit.rounds, DurationLimit.fixed),
      );
      expect(
        timed.hashCode,
        SpellDuration.timed(
          1,
          DurationUnit.rounds,
          DurationLimit.fixed,
        ).hashCode,
      );
      expect(
        timed,
        isNot(SpellDuration.timed(1, DurationUnit.rounds, DurationLimit.upTo)),
      );
      expect(
        timed,
        isNot(SpellDuration.timed(2, DurationUnit.rounds, DurationLimit.fixed)),
      );
      expect(timed, isNot(instant));
      expect(
        timed.toString(),
        'SpellDurationTimed(1 rounds, DurationLimit.fixed)',
      );

      final dispelled = SpellDuration.untilDispelled();
      expect(dispelled, SpellDuration.untilDispelled());
      expect(dispelled.hashCode, SpellDuration.untilDispelled().hashCode);
      expect(dispelled, isNot(SpellDuration.untilDispelledOrTriggered()));
      expect(dispelled.toString(), 'SpellDurationUntilDispelled()');

      final triggered = SpellDuration.untilDispelledOrTriggered();
      expect(triggered, SpellDuration.untilDispelledOrTriggered());
      expect(
        triggered.hashCode,
        SpellDuration.untilDispelledOrTriggered().hashCode,
      );
      expect(triggered, isNot(dispelled));
      expect(triggered.toString(), 'SpellDurationUntilDispelledOrTriggered()');

      final special = SpellDuration.special();
      expect(special, SpellDuration.special());
      expect(special.hashCode, SpellDuration.special().hashCode);
      expect(special, isNot(triggered));
      expect(special.toString(), 'SpellDurationSpecial()');
    });
  });

  /// Requirement: doc/specs/content-spells.md FR-036 - the six Range forms
  ///   are value objects that print their parts (SRD 5.2.1, "Range",
  ///   p. 105).
  /// Path: happy
  group('range value forms', () {
    /// Requirement: doc/specs/content-spells.md FR-036 - the six forms
    ///   compare by value and print their parts.
    /// Path: happy
    test('the six range forms compare and print their parts', () {
      const self = SpellRangeSelf();
      expect(self, const SpellRangeSelf());
      expect(self.hashCode, const SpellRangeSelf().hashCode);
      expect(self, isNot(SpellRange.touch()));
      expect(self.toString(), 'SpellRangeSelf()');

      const touch = SpellRangeTouch();
      expect(touch, const SpellRangeTouch());
      expect(touch.hashCode, const SpellRangeTouch().hashCode);
      expect(touch, isNot(self));
      expect(touch.toString(), 'SpellRangeTouch()');

      final distance = SpellRange.distance(90, DistanceUnit.feet);
      expect(distance, SpellRange.distance(90, DistanceUnit.feet));
      expect(
        distance.hashCode,
        SpellRange.distance(90, DistanceUnit.feet).hashCode,
      );
      expect(distance, isNot(SpellRange.distance(150, DistanceUnit.feet)));
      expect(distance, isNot(SpellRange.distance(90, DistanceUnit.miles)));
      expect(distance, isNot(touch));
      expect(distance.toString(), 'SpellRangeDistance(90, feet)');

      final sight = SpellRange.sight();
      expect(sight, SpellRange.sight());
      expect(sight.hashCode, SpellRange.sight().hashCode);
      expect(sight, isNot(SpellRange.unlimited()));
      expect(sight.toString(), 'SpellRangeSight()');

      final unlimited = SpellRange.unlimited();
      expect(unlimited, SpellRange.unlimited());
      expect(unlimited.hashCode, SpellRange.unlimited().hashCode);
      expect(unlimited, isNot(SpellRange.special()));
      expect(unlimited.toString(), 'SpellRangeUnlimited()');

      final special = SpellRange.special();
      expect(special, SpellRange.special());
      expect(special.hashCode, SpellRange.special().hashCode);
      expect(special, isNot(sight));
      expect(special.toString(), 'SpellRangeSpecial()');
    });
  });
}
