import 'package:srd5e/srd5e.dart';
import 'package:test/test.dart';

import '../../../fixtures/srd/thin_slice/species_facts.dart';
import 'oracle.dart';

/// The trait of [species] named [name]; fails when absent.
NamedText _trait(Species species, String name) => species.traits.singleWhere(
  (trait) => trait.name == name,
  orElse: () => throw StateError('${species.id.id.value} has no trait "$name"'),
);

/// The [Species] of a pin, loaded from the source.
Future<Species> _load(SpeciesPin pin) => speciesOf(pin.id);

/// The pinned phrases of the trait [name] in a fixture pin.
List<String> _phrases(SpeciesPin pin, String name) =>
    pin.traits.singleWhere((trait) => trait.name == name).phrases;

/// The one choice a species holds, named by its trait; fails otherwise.
SpeciesChoice _onlyChoice(Species species, String traitName) {
  final choices = [
    for (final choice in species.choices)
      if (choice.traitName == traitName) choice,
  ];
  if (choices.length != 1) {
    throw StateError(
      '${species.id.id.value} holds ${choices.length} choices for '
      '"$traitName"',
    );
  }
  return choices.single;
}

/// The one option of [choice] named [name]; fails when absent.
ChoiceOption _option(SpeciesChoice choice, String name) =>
    choice.options.singleWhere(
      (option) => option.name == name,
      orElse: () => throw StateError('no option "$name"'),
    );

void main() {
  /// Requirement: doc/specs/content-thin-slice.md FR-009, FR-010, FR-011, FR-012, FR-013 - the species pins
  ///   and phrases (SRD 5.2.1, "Dwarf", p. 84).
  /// Path: happy
  group('dwarf', () {
    /// Requirement: doc/specs/content-thin-slice.md FR-009 - the dwarf has
    ///   Creature Type Humanoid, Size Medium and Speed 30 feet (SRD 5.2.1,
    ///   "Dwarf", p. 84).
    /// Path: happy
    test('the dwarf has Humanoid, Medium and speed 30', () async {
      final species = await _load(dwarf);

      expect(species.creatureType, CreatureType.humanoid);
      expect(species.sizes, [CreatureSize.medium]);
      expect(species.speed, 30);
    });

    /// Requirement: doc/specs/content-thin-slice.md FR-010 - the dwarf has
    ///   exactly four traits named Darkvision, Dwarven Resilience, Dwarven
    ///   Toughness and Stonecunning, and the Darkvision text states a
    ///   range of 120 feet (SRD 5.2.1, "Dwarf", p. 84).
    /// Path: happy
    test(
      'the dwarf has exactly its four traits; Darkvision 120 feet',
      () async {
        final species = await _load(dwarf);

        expect(
          [for (final trait in species.traits) trait.name],
          [for (final pin in dwarf.traits) pin.name],
        );
        expect(
          containsAllPhrases(
            _trait(species, 'Darkvision').text,
            _phrases(dwarf, 'Darkvision'),
          ),
          isTrue,
        );
      },
    );

    /// Requirement: doc/specs/content-thin-slice.md FR-011 - the Dwarven
    ///   Resilience text states Resistance to Poison damage and Advantage
    ///   on saving throws to avoid or end the Poisoned condition
    ///   (SRD 5.2.1, "Dwarf", p. 84).
    /// Path: happy
    test('Dwarven Resilience states its resistance and advantage', () async {
      final species = await _load(dwarf);
      final resilience = _trait(species, 'Dwarven Resilience');

      expect(
        containsAllPhrases(
          resilience.text,
          _phrases(dwarf, 'Dwarven Resilience'),
        ),
        isTrue,
      );
    });

    /// Requirement: doc/specs/content-thin-slice.md FR-012 - the Dwarven
    ///   Toughness text states a Hit Point maximum increase of 1 and a
    ///   further increase of 1 for each level gained (SRD 5.2.1, "Dwarf",
    ///   p. 84).
    /// Path: happy
    test('Dwarven Toughness states its hit point increases', () async {
      final species = await _load(dwarf);
      final toughness = _trait(species, 'Dwarven Toughness');

      expect(
        containsAllPhrases(
          toughness.text,
          _phrases(dwarf, 'Dwarven Toughness'),
        ),
        isTrue,
      );
    });

    /// Requirement: doc/specs/content-thin-slice.md FR-013 - the
    ///   Stonecunning text states Bonus Action, Tremorsense range 60 feet,
    ///   duration 10 minutes, uses equal to Proficiency Bonus, expended
    ///   uses regained on a Long Rest, and the stone-surface condition
    ///   (natural or worked); a copy without the condition fails
    ///   (SRD 5.2.1, "Dwarf", p. 84).
    /// Path: happy
    test(
      'Stonecunning states its action, sense, duration, uses and surface',
      () async {
        final species = await _load(dwarf);
        final stonecunning = _trait(species, 'Stonecunning');

        expect(
          containsAllPhrases(
            stonecunning.text,
            _phrases(dwarf, 'Stonecunning'),
          ),
          isTrue,
        );
        // The stone-surface condition is pinned specifically: a copy of
        // the text without it must fail.
        for (final phrase in stonecunningSurfaceCondition) {
          expect(containsPhrase(stonecunning.text, phrase), isTrue);
        }
      },
    );
  });

  /// Requirement: doc/specs/content-thin-slice.md FR-014, FR-015, FR-016, FR-017, FR-018, FR-019, FR-020 - the species pins
  ///   and phrases (SRD 5.2.1, "Dragonborn", p. 84).
  /// Path: happy
  group('dragonborn', () {
    /// Requirement: doc/specs/content-thin-slice.md FR-014 - the dragonborn
    ///   has Creature Type Humanoid, Size Medium, Speed 30 feet and exactly
    ///   five traits named Draconic Ancestry, Breath Weapon, Damage
    ///   Resistance, Darkvision and Draconic Flight; the Darkvision text
    ///   states a range of 60 feet (SRD 5.2.1, "Dragonborn", p. 84).
    /// Path: happy
    test('the dragonborn has its core fields and five traits', () async {
      final species = await _load(dragonborn);

      expect(species.creatureType, CreatureType.humanoid);
      expect(species.sizes, [CreatureSize.medium]);
      expect(species.speed, 30);
      expect(
        [for (final trait in species.traits) trait.name],
        [for (final pin in dragonborn.traits) pin.name],
      );
      expect(
        containsAllPhrases(
          _trait(species, 'Darkvision').text,
          _phrases(dragonborn, 'Darkvision'),
        ),
        isTrue,
      );
    });

    /// Requirement: per case - doc/specs/content-thin-slice.md FR-015 -
    ///   the dragonborn holds one choices element whose traitName is
    ///   Draconic Ancestry and whose options are exactly the ten dragon
    ///   kinds of T1, each a DamageTypeOption with its damage type
    ///   (SRD 5.2.1, "Draconic Ancestors", p. 84).
    /// Path: per case
    for (final row in draconicAncestors) {
      test('Draconic Ancestry option ${row.label} is ${row.dragon} dealing '
          '${row.damageType}', () async {
        final species = await _load(dragonborn);
        final choice = _onlyChoice(species, 'Draconic Ancestry');

        final option = _option(choice, row.dragon);

        expect(option, isA<DamageTypeOption>());
        expect(
          (option as DamageTypeOption).damageType.jsonValue,
          row.damageType,
        );
      });
    }

    /// Requirement: doc/specs/content-thin-slice.md FR-015 - the option
    ///   set is exactly the ten of T1: none missing, none extra.
    /// Path: unhappy (boundary: none missing, none extra)
    test('Draconic Ancestry holds exactly the ten ancestors of T1', () async {
      final species = await _load(dragonborn);
      final choice = _onlyChoice(species, 'Draconic Ancestry');

      expect([
        for (final option in choice.options) option.name,
      ], unorderedEquals([for (final row in draconicAncestors) row.dragon]));
      expect(choice.options, hasLength(draconicAncestors.length));
      expect(
        choice.options,
        everyElement(isA<DamageTypeOption>()),
        reason: 'every option of the choice is a DamageTypeOption',
      );
    });

    /// Requirement: doc/specs/content-thin-slice.md FR-016 - the Breath
    ///   Weapon text states: usable when taking the Attack action,
    ///   replacing one attack; a 15-foot Cone or a 30-foot Line 5 feet
    ///   wide, chosen each use; a Dexterity saving throw with DC 8 plus
    ///   Constitution modifier plus Proficiency Bonus; damage of the
    ///   chosen type on a failed save and half on a success
    ///   (SRD 5.2.1, "Dragonborn", p. 84).
    /// Path: happy
    test(
      'the Breath Weapon text states its attack, area, save and damage',
      () async {
        final species = await _load(dragonborn);
        final breathWeapon = _trait(species, 'Breath Weapon');

        expect(
          containsAllPhrases(
            breathWeapon.text,
            _phrases(dragonborn, 'Breath Weapon'),
          ),
          isTrue,
        );
      },
    );

    /// Requirement: per case - doc/specs/content-thin-slice.md FR-017 -
    ///   the Breath Weapon text states the damage by character level of
    ///   T2: 1d10 at level 1, 2d10 at 5, 3d10 at 11, 4d10 at 17; the
    ///   thresholds stay in the text (SRD 5.2.1, "Dragonborn", p. 84).
    /// Path: per case
    for (final row in breathWeaponDamage) {
      test(
        'Breath Weapon damage at level ${row.level} states ${row.phrase}',
        () async {
          final species = await _load(dragonborn);

          expect(
            containsPhrase(_trait(species, 'Breath Weapon').text, row.phrase),
            isTrue,
          );
        },
      );
    }

    /// Requirement: doc/specs/content-thin-slice.md FR-017 - exactly three
    ///   upgrade thresholds above level 1: none missing, none extra.
    /// Path: unhappy (boundary: none missing, none extra)
    test('the Breath Weapon states exactly three upgrade thresholds', () async {
      final species = await _load(dragonborn);
      final text = _trait(species, 'Breath Weapon').text;

      expect(containsPhrase(text, breathWeaponUpgradesSentence), isTrue);
      expect(
        RegExp(r'\(\d+d10\)').allMatches(text),
        hasLength(3),
        reason: 'the sentence carries exactly the three upgrades',
      );
    });

    /// Requirement: doc/specs/content-thin-slice.md FR-018 - the Breath
    ///   Weapon text states uses equal to Proficiency Bonus, with all
    ///   expended uses regained on a Long Rest (SRD 5.2.1, "Dragonborn",
    ///   p. 84).
    /// Path: happy
    test('the Breath Weapon states its uses and their regain', () async {
      final species = await _load(dragonborn);
      final text = _trait(species, 'Breath Weapon').text;

      expect(
        containsPhrase(
          text,
          'a number of times equal to your Proficiency Bonus',
        ),
        isTrue,
      );
      expect(
        containsPhrase(
          text,
          'regain all expended uses when you finish a Long Rest',
        ),
        isTrue,
      );
    });

    /// Requirement: doc/specs/content-thin-slice.md FR-019 - the Damage
    ///   Resistance text states Resistance to the damage type chosen for
    ///   Draconic Ancestry, and names no fixed damage type (SRD 5.2.1,
    ///   "Dragonborn", p. 84).
    /// Path: unhappy (rule interaction: depends on a choice)
    test('Damage Resistance names the chosen type and no fixed type', () async {
      final species = await _load(dragonborn);
      final text = _trait(species, 'Damage Resistance').text;

      expect(
        containsAllPhrases(text, _phrases(dragonborn, 'Damage Resistance')),
        isTrue,
      );
      for (final damageType in damageTypes) {
        expect(
          containsPhrase(text, damageType),
          isFalse,
          reason: 'the text names no fixed damage type ($damageType)',
        );
      }
    });

    /// Requirement: doc/specs/content-thin-slice.md FR-020 - the Draconic
    ///   Flight text states: available from character level 5, Bonus
    ///   Action, 10 minutes or until retracted or the Incapacitated
    ///   condition, Fly Speed equal to Speed, usable once per Long Rest
    ///   (SRD 5.2.1, "Dragonborn", p. 84).
    /// Path: happy
    test(
      'Draconic Flight states its gate, action, duration and speed',
      () async {
        final species = await _load(dragonborn);
        final flight = _trait(species, 'Draconic Flight');

        expect(
          containsAllPhrases(
            flight.text,
            _phrases(dragonborn, 'Draconic Flight'),
          ),
          isTrue,
        );
      },
    );
  });

  /// Requirement: doc/specs/content-thin-slice.md FR-021, FR-022, FR-023, FR-024, FR-025, FR-026, FR-027, FR-028 - the species pins
  ///   and phrases (SRD 5.2.1, "Elf", pp. 84-85).
  /// Path: happy
  group('elf', () {
    /// Requirement: doc/specs/content-thin-slice.md FR-021 - the elf has
    ///   Creature Type Humanoid, Size Medium and Speed 30 feet
    ///   (SRD 5.2.1, "Elf", p. 84).
    /// Path: happy
    test('the elf has Humanoid, Medium and speed 30', () async {
      final species = await _load(elf);

      expect(species.creatureType, CreatureType.humanoid);
      expect(species.sizes, [CreatureSize.medium]);
      expect(species.speed, 30);
    });

    /// Requirement: doc/specs/content-thin-slice.md FR-022 - the elf has
    ///   exactly five traits named Darkvision, Elven Lineage, Fey
    ///   Ancestry, Keen Senses and Trance; the Darkvision text states a
    ///   range of 60 feet (SRD 5.2.1, "Elf", pp. 84-85).
    /// Path: happy
    test('the elf has exactly its five traits; Darkvision 60 feet', () async {
      final species = await _load(elf);

      expect(
        [for (final trait in species.traits) trait.name],
        [for (final pin in elf.traits) pin.name],
      );
      expect(
        containsAllPhrases(
          _trait(species, 'Darkvision').text,
          _phrases(elf, 'Darkvision'),
        ),
        isTrue,
      );
    });

    /// Requirement: per case - doc/specs/content-thin-slice.md FR-023 -
    ///   the elf holds one choices element whose traitName is Elven
    ///   Lineage and whose options are exactly the three LineageOptions of
    ///   T3, each with levelBenefits for levels 1, 3 and 5: the verbatim
    ///   Level 1 text and the spellId of its cantrip, then the level 3 and
    ///   level 5 spellId (SRD 5.2.1, "Elven Lineages", p. 85).
    /// Path: per case
    for (final row in elvenLineages) {
      test('${row.label} lineage holds its benefits and spells', () async {
        final species = await _load(elf);
        final choice = _onlyChoice(species, 'Elven Lineage');

        final option = _option(choice, row.lineage);

        expect(option, isA<LineageOption>());
        final benefits = (option as LineageOption).levelBenefits;
        expect([
          for (final benefit in benefits) benefit.level,
        ], LevelBenefit.lineageLevels);
        expect(containsAllPhrases(benefits[0].text, row.level1Phrases), isTrue);
        expect(benefits[0].spellId.id.value, row.level1SpellId);
        expect(benefits[1].spellId.id.value, row.level3SpellId);
        expect(benefits[2].spellId.id.value, row.level5SpellId);
      });
    }

    /// Requirement: doc/specs/content-thin-slice.md FR-023 - the option
    ///   set is exactly the three of T3: none missing, none extra.
    /// Path: unhappy (boundary)
    test('Elven Lineage holds exactly the three lineages of T3', () async {
      final species = await _load(elf);
      final choice = _onlyChoice(species, 'Elven Lineage');

      expect([
        for (final option in choice.options) option.name,
      ], unorderedEquals([for (final row in elvenLineages) row.lineage]));
      expect(choice.options, hasLength(elvenLineages.length));
      expect(
        choice.options,
        everyElement(isA<LineageOption>()),
        reason: 'every option of the choice is a LineageOption',
      );
    });

    /// Requirement: doc/specs/content-thin-slice.md FR-024 - the level 3
    ///   and level 5 spellId of each lineage are the T3 spells, and the
    ///   grant semantics (always prepared, the free cast and its Long Rest
    ///   regain, casting with a slot, and the chosen spellcasting ability)
    ///   are stated in the Elven Lineage trait text and are not structured
    ///   data (SRD 5.2.1, "Elf", pp. 84-85).
    /// Path: happy
    test(
      'the lineage spells are the T3 spells; the semantics are text',
      () async {
        final species = await _load(elf);
        final choice = _onlyChoice(species, 'Elven Lineage');
        final traitText = _trait(species, 'Elven Lineage').text;

        for (final row in elvenLineages) {
          final benefits =
              (_option(choice, row.lineage) as LineageOption).levelBenefits;
          expect(benefits[1].spellId.id.value, row.level3SpellId);
          expect(benefits[2].spellId.id.value, row.level5SpellId);
        }
        expect(
          containsAllPhrases(traitText, _phrases(elf, 'Elven Lineage')),
          isTrue,
        );
      },
    );

    /// Requirement: doc/specs/content-thin-slice.md FR-025 - a lineage's
    ///   Level 1 benefit is stored as that option's text and does not
    ///   alter the elf entry's base speed (30 feet) or Darkvision text (60
    ///   feet); the Drow text states Darkvision 120 feet and the Wood Elf
    ///   text Speed 35 feet (SRD 5.2.1, "Elf", pp. 84-85).
    /// Path: unhappy (rule interaction: override versus base)
    test(
      'the base elf is unchanged; the overrides stay in option text',
      () async {
        final species = await _load(elf);
        final choice = _onlyChoice(species, 'Elven Lineage');
        String optionText(String name) =>
            (_option(choice, name) as LineageOption).levelBenefits[0].text;

        final overrides = {
          for (final row in elvenLineages) row.lineage: row.level1Phrases,
        };
        expect(species.speed, 30);
        expect(
          containsAllPhrases(
            _trait(species, 'Darkvision').text,
            _phrases(elf, 'Darkvision'),
          ),
          isTrue,
        );
        expect(
          containsAllPhrases(optionText('Drow'), overrides['Drow']!),
          isTrue,
          reason: 'the Drow text states Darkvision 120 feet',
        );
        expect(
          containsAllPhrases(optionText('Wood Elf'), overrides['Wood Elf']!),
          isTrue,
          reason: 'the Wood Elf text states Speed 35 feet',
        );
      },
    );

    /// Requirement: doc/specs/content-thin-slice.md FR-026 - the Fey
    ///   Ancestry text states Advantage on saving throws to avoid or end
    ///   the Charmed condition (SRD 5.2.1, "Elf", p. 85).
    /// Path: happy
    test('Fey Ancestry states its advantage on saves', () async {
      final species = await _load(elf);
      final feyAncestry = _trait(species, 'Fey Ancestry');

      expect(
        containsAllPhrases(feyAncestry.text, _phrases(elf, 'Fey Ancestry')),
        isTrue,
      );
    });

    /// Requirement: doc/specs/content-thin-slice.md FR-027 - the Keen
    ///   Senses text states proficiency in one skill chosen from Insight,
    ///   Perception or Survival (SRD 5.2.1, "Elf", p. 85).
    /// Path: happy
    test('Keen Senses states its three-skill choice', () async {
      final species = await _load(elf);
      final keenSenses = _trait(species, 'Keen Senses');

      expect(
        containsAllPhrases(keenSenses.text, _phrases(elf, 'Keen Senses')),
        isTrue,
      );
    });

    /// Requirement: doc/specs/content-thin-slice.md FR-028 - the Trance
    ///   text states: no need to sleep, magic cannot put the Elf to sleep,
    ///   and a Long Rest can be finished in 4 hours (SRD 5.2.1, "Elf",
    ///   p. 85).
    /// Path: happy
    test('Trance states sleep, magic sleep and the 4-hour Long Rest', () async {
      final species = await _load(elf);
      final trance = _trait(species, 'Trance');

      expect(containsAllPhrases(trance.text, _phrases(elf, 'Trance')), isTrue);
    });
  });

  /// Requirement: doc/specs/content-thin-slice.md FR-029, FR-030, FR-031 - the species pins
  ///   and phrases (SRD 5.2.1, "Human", p. 86).
  /// Path: happy
  group('human', () {
    /// Requirement: doc/specs/content-thin-slice.md FR-029 - the human has
    ///   Creature Type Humanoid and Speed 30 feet; its sizes are the set
    ///   {Medium, Small}, a choice made when the species is selected, and
    ///   its sizeText carries the printed heights (about 4 to 7 feet tall
    ///   for Medium, about 2 to 4 feet tall for Small) (SRD 5.2.1,
    ///   "Human", p. 86).
    /// Path: unhappy (boundary: size is a set)
    test(
      'the human has two sizes as a set and both heights in sizeText',
      () async {
        final species = await _load(human);

        expect(species.creatureType, CreatureType.humanoid);
        expect(species.speed, 30);
        expect(species.sizes.toSet(), {
          CreatureSize.medium,
          CreatureSize.small,
        });
        expect(
          containsAllPhrases(species.sizeText!, human.sizeTextPhrases),
          isTrue,
        );
      },
    );

    /// Requirement: doc/specs/content-thin-slice.md FR-030 - the human has
    ///   exactly three traits: Resourceful (Heroic Inspiration whenever a
    ///   Long Rest is finished), Skillful (proficiency in one skill of the
    ///   player's choice) and Versatile (an Origin feat of the player's
    ///   choice, Skilled recommended), each in its verbatim text
    ///   (SRD 5.2.1, "Human", p. 86).
    /// Path: happy
    test('the human has exactly its three traits with their phrases', () async {
      final species = await _load(human);

      expect(
        [for (final trait in species.traits) trait.name],
        [for (final pin in human.traits) pin.name],
      );
      for (final pin in human.traits) {
        expect(
          containsAllPhrases(_trait(species, pin.name).text, pin.phrases),
          isTrue,
          reason: '${pin.name} states its phrases',
        );
      }
    });

    /// Requirement: doc/specs/content-thin-slice.md FR-031 - a trait that
    ///   asks for a pick from a kind absent from the slice (Versatile's
    ///   Origin feat, Skillful's skill) stays verbatim text with no
    ///   reference, so it does not make the slice fail to build or decode
    ///   (SRD 5.2.1, "Human", p. 86).
    /// Path: unhappy (missing content: choice target not bundled)
    test(
      'the human traits hold no reference for their absent-kind picks',
      () async {
        final species = await _load(human);

        expect(species.choices, isEmpty);
        expect(species.references, isEmpty);
      },
    );
  });

  /// Requirement: per case - doc/specs/content-thin-slice.md FR-032 -
  ///   the T4 selections: two structured, the rest verbatim text or sizes.
  /// Path: per case
  group('choices across the slice', () {
    /// Requirement: per case - doc/specs/content-thin-slice.md FR-032 -
    ///   only Draconic Ancestry and Elven Lineage are structured choices;
    ///   every other selection of table T4 is present in the verbatim
    ///   trait text, or in sizes for the Human size, and is not a second
    ///   structured copy (SRD 5.2.1, pp. 84-86).
    /// Path: per case
    for (final row in choicesInTheSpecies) {
      test('T4 ${row.label} is held as ${row.heldAs}', () async {
        final species = await speciesOf(row.speciesId);
        switch (row.heldAs) {
          case 'choices':
            final choice = _onlyChoice(species, row.ownerTraitName);
            expect(choice.traitName, row.ownerTraitName);
          case 'trait text':
            expect(
              containsAllPhrases(
                _trait(species, row.ownerTraitName).text,
                row.facts,
              ),
              isTrue,
            );
            if (row.label == 'lineage spellcasting ability') {
              // The owner trait itself holds the one structured choice (the
              // lineage); the ability selection gains no structured copy of
              // its own: every option is a LineageOption, which carries no
              // ability.
              final choice = _onlyChoice(species, row.ownerTraitName);
              expect(choice.options, everyElement(isA<LineageOption>()));
            } else {
              expect(
                species.choices.where(
                  (choice) => choice.traitName == row.ownerTraitName,
                ),
                isEmpty,
                reason: 'the selection is not a second structured copy',
              );
            }
          case 'option text':
            final choice = _onlyChoice(species, row.ownerTraitName);
            final option = _option(choice, 'High Elf') as LineageOption;
            expect(
              containsAllPhrases(option.levelBenefits[0].text, row.facts),
              isTrue,
            );
          case 'sizes':
            expect([
              for (final size in species.sizes) size.jsonValue,
            ], unorderedEquals(row.facts));
          default:
            fail('unknown heldAs ${row.heldAs}');
        }
      });
    }

    /// Requirement: doc/specs/content-thin-slice.md FR-032 - exactly two
    ///   structured choices exist across the slice, Draconic Ancestry and
    ///   Elven Lineage (SRD 5.2.1, pp. 84-86).
    /// Path: happy
    test('exactly the two SX-1 choices are structured', () async {
      final dwarfSpecies = await _load(dwarf);
      final dragonbornSpecies = await _load(dragonborn);
      final elfSpecies = await _load(elf);
      final humanSpecies = await _load(human);

      expect(dwarfSpecies.choices, isEmpty);
      expect(humanSpecies.choices, isEmpty);
      expect(dragonbornSpecies.choices, hasLength(1));
      expect(dragonbornSpecies.choices.single.traitName, 'Draconic Ancestry');
      expect(elfSpecies.choices, hasLength(1));
      expect(elfSpecies.choices.single.traitName, 'Elven Lineage');
    });
  });
}
