import 'package:srd5e/srd5e.dart';
import 'package:test/test.dart';

import '../../../fixtures/srd/thin_slice/citations.dart' show spellIds;
import '../../../fixtures/srd/thin_slice/species_facts.dart'
    show breathWeaponDamage;
import '../../../fixtures/srd/thin_slice/spell_facts.dart';
import 'oracle.dart';

/// The spell [id], loaded from the source.
Future<Spell> _load(String id) => spellOf(id);

/// The description text of [spell]: every block's printed text, plus the
/// optional scaling texts, in printed order.
List<String> _descriptionTexts(Spell spell) => [
  for (final block in [
    ...spell.description,
    ...?spell.higherLevel,
    ...?spell.cantripUpgrade,
  ])
    ..._blockTexts(block),
];

List<String> _blockTexts(ContentTextBlock block) => switch (block) {
  ContentTextParagraph(:final text) => [text],
  ContentTextEntry(:final name, :final text) => [name, text],
  ContentTextBulletList(:final items) => items,
  ContentTextTable(:final title, :final header, :final rows) => [
    ?title,
    ...header,
    for (final row in rows) ...row,
  ],
  ContentTextEmbeddedStatBlock(:final lines) => lines,
};

/// The run-in effects of [spell]: the names of its entry blocks.
Set<String> _entryNames(Spell spell) => {
  for (final block in spell.description)
    if (block is ContentTextEntry) block.name,
};

void main() {
  /// Requirement: per case - doc/specs/content-thin-slice.md FR-048 -
  ///   each of the 12 slice spells has exactly the level, School of Magic,
  ///   class list, Casting Time, Range, Components and Duration of table
  ///   T6 (SRD 5.2.1, "Spell Descriptions", pp. 121-154).
  /// Path: per case
  for (final row in spellHeaders) {
    test('T6 ${row.label} header matches the printed values', () async {
      final spell = await _load(row.id);

      expect(spell.name, row.name);
      expect(spell.level.level, row.level);
      expect(spell.school.jsonValue, row.school);
      expect(
        {for (final classId in spell.classes) classId.id.value},
        {for (final name in row.classes) name.toLowerCase()},
        reason: 'the class list equals the T6 set, order not asserted',
      );
      expect(printedCastingTime(spell), row.castingTime);
      expect(printedRange(spell), row.range);
      expect(printedComponents(spell), row.components);
      expect(printedDuration(spell), row.duration);
    });
  }

  /// Requirement: doc/specs/content-thin-slice.md FR-048 - the spell
  ///   levels of the slice run 0 to 3: every slice spell is covered by a
  ///   T6 row and none is missing one.
  /// Path: unhappy (boundary)
  test('every slice spell has exactly its T6 row', () async {
    final spells = await entriesOf(ContentKind.spell);

    expect(spells, hasLength(spellHeaders.length));
    for (final entry in spells) {
      expect(spellHeaders.map((row) => row.id), contains(entry.key.id.value));
    }
  });

  /// Requirement: per case - doc/specs/content-thin-slice.md FR-050 - the
  ///   Ritual tag is the flag beside the Casting Time.
  /// Path: per case
  group('ritual tag', () {
    /// Requirement: per case - doc/specs/content-thin-slice.md FR-050 -
    ///   the Ritual tag is the flag beside castingTimes: Detect Magic has
    ///   a single Magic action and ritual true, Fire Bolt the Magic action
    ///   and ritual false, Misty Step the Bonus Action and ritual false
    ///   (SRD 5.2.1, "Casting without Slots", p. 104).
    /// Path: per case
    for (final row in ritualTags) {
      test('${row.id} ritual is ${row.ritual}', () async {
        final spell = await _load(row.id);

        expect(spell.ritual, row.ritual);
        expect(
          spell.castingTimes,
          isA<SpellCastingTimesSingle>(),
          reason: 'each pinned spell prints one casting time',
        );
      });
    }

    /// Requirement: doc/specs/content-thin-slice.md FR-050 - no other
    ///   slice spell carries the Ritual tag (SRD 5.2.1, "Detect Magic",
    ///   p. 123).
    /// Path: unhappy (rule interaction: action plus Ritual)
    test('only Detect Magic is a ritual', () async {
      final spells = await entriesOf(ContentKind.spell);

      final rituals = [
        for (final spell in spells)
          if (spell is Spell && spell.ritual) spell.id.id.value,
      ];
      expect(rituals, ['detect_magic']);
    });
  });

  /// Requirement: doc/specs/content-thin-slice.md FR-051 - a Duration
  ///   distinguishes Instantaneous, Concentration up to a span, and a time
  ///   span: Detect Magic is Concentration up to 10 minutes,
  ///   Prestidigitation is Up to 1 hour, Fire Bolt, Fireball, Magic
  ///   Missile, Misty Step and Druidcraft are Instantaneous, Longstrider
  ///   is a 1-hour span without Concentration, and the lineage spells
  ///   follow T6 (SRD 5.2.1, "Duration", p. 106).
  /// Path: happy
  test('the durations distinguish the three forms', () async {
    final instantaneous = {
      'fire_bolt',
      'magic_missile',
      'misty_step',
      'fireball',
      'druidcraft',
    };
    final concentration = {
      'detect_magic',
      'dancing_lights',
      'darkness',
      'faerie_fire',
      'pass_without_trace',
    };

    for (final id in spellIds) {
      final spell = await _load(id);
      if (instantaneous.contains(id)) {
        expect(spell.duration, isA<SpellDurationInstantaneous>(), reason: id);
        expect(spell.requiresConcentration, isFalse, reason: id);
      } else if (concentration.contains(id)) {
        final timed = spell.duration as SpellDurationTimed;
        expect(timed.limit, DurationLimit.concentrationUpTo, reason: id);
        expect(spell.requiresConcentration, isTrue, reason: id);
      } else if (id == 'prestidigitation') {
        final timed = spell.duration as SpellDurationTimed;
        expect(timed.limit, DurationLimit.upTo, reason: id);
        expect(timed.amount, 1);
        expect(timed.unit, DurationUnit.hours);
        expect(spell.requiresConcentration, isFalse, reason: id);
      } else {
        // Longstrider: a time span without Concentration.
        final timed = spell.duration as SpellDurationTimed;
        expect(timed.limit, DurationLimit.fixed, reason: id);
        expect(timed.amount, 1);
        expect(timed.unit, DurationUnit.hours);
        expect(spell.requiresConcentration, isFalse, reason: id);
      }
    }
  });

  /// Requirement: doc/specs/content-thin-slice.md FR-052 - Components
  ///   record Verbal, Somatic and Material separately, and a Material
  ///   component carries its text: Fireball carries a ball of bat guano
  ///   and sulfur; Misty Step and Faerie Fire are Verbal only; Druidcraft
  ///   is Verbal and Somatic without Material; the Material text of the
  ///   lineage spells is as in T6 (SRD 5.2.1, "Components", p. 105).
  /// Path: unhappy (boundary: optional Material text)
  test(
    'the components split V, S and M, with the printed material texts',
    () async {
      const materials = materialComponents;
      final somatic = {
        'misty_step': false,
        'darkness': false,
        'faerie_fire': false,
      };

      for (final id in spellIds) {
        final spell = await _load(id);
        expect(spell.components.verbal, isTrue, reason: 'every spell has V');
        expect(
          spell.components.somatic,
          somatic[id] ?? true,
          reason: '$id somatic per T6',
        );
        final material = spell.components.material;
        if (materials.containsKey(id)) {
          expect(material, isNotNull, reason: '$id has M');
          expect(material!.description, materials[id]);
        } else {
          expect(material, isNull, reason: '$id has no M');
        }
      }
      // Misty Step and Faerie Fire are Verbal only: no S, no M.
      expect((await _load('misty_step')).components.somatic, isFalse);
      expect((await _load('misty_step')).components.material, isNull);
      expect((await _load('faerie_fire')).components.somatic, isFalse);
      expect((await _load('faerie_fire')).components.material, isNull);
      // Druidcraft is Verbal and Somatic without Material.
      expect((await _load('druidcraft')).components.somatic, isTrue);
      expect((await _load('druidcraft')).components.material, isNull);
    },
  );

  /// Requirement: doc/specs/content-thin-slice.md FR-053 - a Range
  ///   distinguishes Self from a distance in feet: Self for Detect Magic
  ///   and Misty Step (and Pass without Trace); 10, 120, 120 and 150 feet
  ///   for Prestidigitation, Fire Bolt, Magic Missile and Fireball;
  ///   Touch for Longstrider (SRD 5.2.1, "Range", p. 105).
  /// Path: happy
  test('the ranges distinguish Self, Touch and distances', () async {
    for (final row in spellHeaders) {
      final spell = await _load(row.id);
      expect(printedRange(spell), row.range, reason: row.id);
    }
    expect((await _load('detect_magic')).range, isA<SpellRangeSelf>());
    expect((await _load('misty_step')).range, isA<SpellRangeSelf>());
    expect((await _load('longstrider')).range, isA<SpellRangeTouch>());
    final fireBolt = await _load('fire_bolt');
    expect(fireBolt.range, isA<SpellRangeDistance>());
    expect((fireBolt.range as SpellRangeDistance).amount, 120);
  });

  /// Requirement: doc/specs/content-thin-slice.md FR-054, FR-055,
  ///   FR-056, FR-057, FR-058, FR-059, FR-083 - the effect phrases and
  ///   named effects of the twelve spells.
  /// Path: happy
  group('spell effect text', () {
    /// Requirement: per case - doc/specs/content-thin-slice.md FR-054,
    ///   FR-055, FR-056, FR-057, FR-058 - Fire Bolt carries its ranged
    ///   spell attack, 1d10 Fire
    ///   damage and burning objects; Magic Missile its three darts, 1d4 +
    ///   1 Force damage and simultaneous strikes; Fireball its Sphere,
    ///   save, 8d6 damage and burning objects; Misty Step its teleport;
    ///   Detect Magic its sensing, Magic action aura and barriers
    ///   (SRD 5.2.1, "Spell Descriptions", cited per phrase).
    /// Path: per case
    for (final id in [
      'fire_bolt',
      'magic_missile',
      'fireball',
      'misty_step',
      'detect_magic',
    ]) {
      test('$id states its pinned effect phrases', () async {
        final spell = await _load(id);
        final text = _descriptionTexts(spell).join('\n');

        expect(
          containsAllPhrases(text, effectPhrases[id]!),
          isTrue,
          reason: '$id states every phrase of FR-054 to FR-058',
        );
      });
    }

    /// Requirement: doc/specs/content-thin-slice.md FR-059 -
    ///   Prestidigitation carries six named effects (Sensory Effect, Fire
    ///   Play, Clean or Soil, Minor Sensation, Magic Mark, Minor Creation)
    ///   and the limit of three non-instantaneous effects active at a time
    ///   (SRD 5.2.1, "Prestidigitation", p. 154).
    /// Path: happy
    test(
      'Prestidigitation carries its six effects and the limit of three',
      () async {
        final spell = await _load('prestidigitation');

        expect(_entryNames(spell), namedEffects['prestidigitation']!.toSet());
        expect(
          containsAllPhrases(
            _descriptionTexts(spell).join('\n'),
            effectPhrases['prestidigitation']!,
          ),
          isTrue,
        );
      },
    );

    // Druidcraft's FR-083 pin is its four named effects, tested below; the
    // five spells here have pinned phrases.

    /// Requirement: per case - doc/specs/content-thin-slice.md FR-083 -
    ///   the six lineage spells carry their facts in their text: Dancing
    ///   Lights, Darkness, Druidcraft (four named effects), Faerie Fire,
    ///   Longstrider and Pass without Trace (SRD 5.2.1, "Spell
    ///   Descriptions", cited per phrase).
    /// Path: per case
    for (final id in [
      'dancing_lights',
      'darkness',
      'faerie_fire',
      'longstrider',
      'pass_without_trace',
    ]) {
      test('$id states its pinned lineage facts', () async {
        final spell = await _load(id);
        final text = _descriptionTexts(spell).join('\n');

        expect(
          containsAllPhrases(text, effectPhrases[id]!),
          isTrue,
          reason: '$id states every phrase of FR-083',
        );
      });
    }

    /// Requirement: doc/specs/content-thin-slice.md FR-083 - Druidcraft
    ///   carries its four named effects (Weather Sensor, Bloom, Sensory
    ///   Effect, Fire Play) (SRD 5.2.1, "Druidcraft", p. 126).
    /// Path: happy
    test('Druidcraft carries its four named effects', () async {
      final spell = await _load('druidcraft');

      expect(_entryNames(spell), namedEffects['druidcraft']!.toSet());
    });
  });

  /// Requirement: per case - doc/specs/content-thin-slice.md FR-060 -
  ///   spell scaling is recorded per T7 as text only: Fire Bolt has
  ///   cantripUpgrade and no higherLevel; Magic Missile, Fireball and
  ///   Longstrider have higherLevel and no cantripUpgrade; Detect Magic,
  ///   Misty Step, Prestidigitation and the other lineage spells have
  ///   neither field, absent rather than empty
  ///   (SRD 5.2.1, cited per row).
  /// Path: per case
  for (final row in spellScaling) {
    test('T7 ${row.label} scales as ${row.scaling}', () async {
      for (final id in row.ids) {
        final spell = await _load(id);
        switch (row.scaling) {
          case 'cantripUpgrade':
            expect(spell.cantripUpgrade, isNotNull, reason: id);
            expect(spell.higherLevel, isNull, reason: id);
            expect(spell.cantripUpgrade, isNotEmpty, reason: id);
          case 'higherLevel':
            expect(spell.higherLevel, isNotNull, reason: id);
            expect(spell.cantripUpgrade, isNull, reason: id);
            expect(spell.higherLevel, isNotEmpty, reason: id);
          default:
            expect(spell.cantripUpgrade, isNull, reason: id);
            expect(spell.higherLevel, isNull, reason: id);
        }
      }
    });
  }

  /// Requirement: doc/specs/content-thin-slice.md FR-060 - the Fire Bolt
  ///   cantrip upgrade states the character-level thresholds of T7, which
  ///   equal the Breath Weapon thresholds of T2 (SRD 5.2.1, "Multiclassing",
  ///   p. 25; "Fire Bolt", p. 132).
  /// Path: unhappy (rule interaction: one scaling shape for two kinds)
  test(
    'the Fire Bolt upgrade carries the 5, 11, 17 character thresholds',
    () async {
      final spell = await _load('fire_bolt');
      final text = [
        for (final block in spell.cantripUpgrade!) ..._blockTexts(block),
      ].join('\n');

      expect(containsPhrase(text, fireBoltUpgradeSentence), isTrue);
      // The thresholds are T2's own rows: one table drives both pins, so a
      // threshold changed in either place fails here.
      for (final row in breathWeaponDamage) {
        if (row.level == 1) continue;
        expect(containsPhrase(text, row.phrase), isTrue, reason: row.label);
      }
    },
  );

  /// Requirement: doc/specs/content-thin-slice.md FR-061 - the class
  ///   lists equal T6, in sizes 1, 2, 3, 4 and 8.
  /// Path: unhappy (boundary: lists of 1, 2, 3, 4 and 8 classes)
  group('class lists', () {
    /// Requirement: doc/specs/content-thin-slice.md FR-061 - for every
    ///   slice spell the class list equals the set of T6 (order not
    ///   asserted), and the slice holds lists of sizes 1, 2, 3, 4 and 8,
    ///   each non-empty (SRD 5.2.1, "Class Spell Lists", p. 105).
    /// Path: unhappy (boundary: lists of 1, 2, 3, 4 and 8 classes)
    test('each class list equals its T6 set, in five sizes', () async {
      final sizes = <int>{};

      for (final row in spellHeaders) {
        final spell = await _load(row.id);
        final ids = {for (final classId in spell.classes) classId.id.value};
        expect(ids, {
          for (final name in row.classes) name.toLowerCase(),
        }, reason: '${row.id} class list equals T6');
        expect(ids, isNotEmpty, reason: 'no list is empty');
        expect(spell.classes.length, row.classes.length);
        sizes.add(spell.classes.length);
      }

      expect(sizes, {1, 2, 3, 4, 8});
    });
  });
}
