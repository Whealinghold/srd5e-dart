import 'package:srd5e/src/content/domain/choice_option.dart';
import 'package:srd5e/src/content/domain/content_id.dart';
import 'package:srd5e/src/content/domain/content_key.dart';
import 'package:srd5e/src/content/domain/content_kind.dart';
import 'package:srd5e/src/content/domain/creature_size.dart';
import 'package:srd5e/src/content/domain/creature_type.dart';
import 'package:srd5e/src/content/domain/damage_type.dart';
import 'package:srd5e/src/content/domain/level_benefit.dart';
import 'package:srd5e/src/content/domain/named_text.dart';
import 'package:srd5e/src/content/domain/species.dart';
import 'package:srd5e/src/content/domain/species_choice.dart';
import 'package:srd5e/src/content/domain/typed_ids.dart';
import 'package:test/test.dart';

import '../../support/argument_error_matcher.dart';
import '../../support/operator_equals.dart';

final SpellId _dancingLights = SpellId('dancing_lights');
final SpellId _faerieFire = SpellId('faerie_fire');
final SpellId _darkness = SpellId('darkness');
final SpellId _prestidigitation = SpellId('prestidigitation');
final SpellId _detectMagic = SpellId('detect_magic');
final SpellId _mistyStep = SpellId('misty_step');
final SpellId _minorIllusion = SpellId('minor_illusion');
final SpellId _speakWithAnimals = SpellId('speak_with_animals');

LineageOption _lineage(String name, List<SpellId> spells) =>
    LineageOption(name, [
      for (var i = 0; i < spells.length; i++)
        LevelBenefit(LevelBenefit.lineageLevels[i], 'Level text.', spells[i]),
    ]);

Species _species({
  SpeciesId? id,
  String name = 'Elf',
  CreatureType creatureType = CreatureType.humanoid,
  List<CreatureSize>? sizes,
  String? sizeText,
  int speed = 30,
  List<NamedText>? traits,
  List<SpeciesChoice> choices = const [],
}) => Species(
  id: id ?? SpeciesId('elf'),
  name: name,
  creatureType: creatureType,
  sizes: sizes ?? const [CreatureSize.medium],
  sizeText: sizeText,
  speed: speed,
  traits:
      traits ?? [NamedText('Darkvision', 'You have Darkvision in the test.')],
  choices: choices,
);

void main() {
  /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-011,
  ///   FR-012, FR-013, FR-014, SX-3 - the "Species header" constructor rows:
  ///   sizes, speed, sizeText, traits, creature type and name; each row
  ///   carries its own path.
  /// Path: happy
  group('Species header constructor rows', () {
    /// Requirement: per case
    /// Path: per case
    for (final c in [
      (
        label: 'one size',
        requirement:
            'doc/specs/content-species-backgrounds-feats.md FR-012 - sizes '
            'has one or two distinct Small or Medium values ("Dragonborn, '
            'Dwarf, Elf: [Medium]")',
        path: 'happy',
        sizes: [CreatureSize.medium],
        accepted: true,
        rejectedValue: null,
      ),
      (
        label: 'Small and Medium',
        requirement:
            'doc/specs/content-species-backgrounds-feats.md FR-012 - two '
            'sizes ("Human, Tiefling: [Small, Medium]")',
        path: 'happy',
        sizes: [CreatureSize.small, CreatureSize.medium],
        accepted: true,
        rejectedValue: null,
      ),
      (
        label: 'no size',
        requirement:
            'doc/specs/content-species-backgrounds-feats.md FR-012 - zero '
            'entries is outOfRange',
        path: 'unhappy (boundary)',
        sizes: <CreatureSize>[],
        accepted: false,
        rejectedValue: null,
      ),
      (
        label: 'three sizes',
        requirement:
            'doc/specs/content-species-backgrounds-feats.md FR-012 - three '
            'entries is outOfRange',
        path: 'unhappy (boundary)',
        sizes: [CreatureSize.small, CreatureSize.medium, CreatureSize.small],
        accepted: false,
        rejectedValue: null,
      ),
      (
        label: 'a repeated size',
        requirement:
            'doc/specs/content-species-backgrounds-feats.md FR-012 - a '
            'repeat is duplicate',
        path: 'unhappy (invalid input)',
        sizes: [CreatureSize.medium, CreatureSize.medium],
        accepted: false,
        rejectedValue: CreatureSize.medium,
      ),
      (
        label: 'a Large size',
        requirement:
            'doc/specs/content-species-backgrounds-feats.md FR-012 - any '
            'other size is invalidValue',
        path: 'unhappy (invalid input)',
        sizes: [CreatureSize.large],
        accepted: false,
        rejectedValue: CreatureSize.large,
      ),
    ]) {
      test('Species sizes: ${c.label} [${c.path}]', () {
        if (c.accepted) {
          final species = _species(sizes: c.sizes);
          expect(species.sizes, c.sizes);
        } else {
          expect(
            () => _species(sizes: c.sizes),
            throwsArgumentErrorFor('sizes', c.rejectedValue ?? c.sizes),
          );
        }
      });
    }

    /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-013 -
    ///   speed is 0 or more: 0, 1 and 30 accepted, a negative speed
    ///   outOfRange. A non-integer speed (30.5) is a decoder row (schema
    ///   FR-021); the field is an int, so it is unrepresentable here.
    /// Path: happy
    test('Species speed accepts 0, 1 and 30 and rejects a negative', () {
      expect(_species(speed: 0).speed, 0);
      expect(_species(speed: 1).speed, 1);
      expect(_species(speed: 30).speed, 30);
      expect(() => _species(speed: -5), throwsArgumentErrorFor('speed', -5));
    });

    /// Requirement: doc/specs/content-species-backgrounds-feats.md SX-3 -
    ///   sizeText is optional and, when present, a non-blank string stored
    ///   verbatim.
    /// Path: happy
    test('Species sizeText is optional and stored verbatim', () {
      expect(_species().sizeText, isNull);
      const sizeText = 'Your character is Medium. Test height range.';
      expect(_species(sizeText: sizeText).sizeText, sizeText);
      expect(
        () => _species(sizeText: ' '),
        throwsArgumentErrorFor('sizeText', ' '),
      );
    });

    /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-014 -
    ///   traits is a non-empty list in printed order with unique names.
    /// Path: unhappy (invalid input)
    test('Species rejects an empty or name-repeating traits list', () {
      expect(
        () => _species(traits: []),
        throwsArgumentErrorFor('traits', isEmpty),
      );
      expect(
        () => _species(
          traits: [
            NamedText('Darkvision', 'first'),
            NamedText('Darkvision', 'second'),
          ],
        ),
        throwsArgumentErrorFor('traits', 'Darkvision'),
      );
      // A repeat is caught whatever sits between the repeats.
      expect(
        () => _species(
          traits: [
            NamedText('Darkvision', 'first'),
            NamedText('Brave', 'second'),
            NamedText('Darkvision', 'third'),
          ],
        ),
        throwsArgumentErrorFor('traits', 'Darkvision'),
      );
    });

    /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-014 -
    ///   the printed order is preserved.
    /// Path: happy
    test('Species keeps the printed trait order', () {
      final traits = [
        NamedText('Brave', 'first.'),
        NamedText('Luck', 'second.'),
      ];

      expect(_species(traits: traits).traits.map((t) => t.name), [
        'Brave',
        'Luck',
      ]);
    });

    /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-011 -
    ///   the creature type is carried as given (the bundled pin is Humanoid;
    ///   the constructor accepts any member).
    /// Path: happy
    test('Species carries its creature type', () {
      expect(_species().creatureType, CreatureType.humanoid);
      expect(
        _species(creatureType: CreatureType.dragon).creatureType,
        CreatureType.dragon,
      );
    });

    /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-027 -
    ///   the species name follows the name rule.
    /// Path: unhappy (invalid input)
    test('Species rejects a blank name', () {
      expect(() => _species(name: ' '), throwsArgumentErrorFor('name', ' '));
    });
  });

  /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-016,
  ///   FR-060 - a choice naming no trait is a constraintViolation, a choice
  ///   naming one is accepted, and the collections are unmodifiable.
  /// Path: happy
  group('Species choices', () {
    /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-060 -
    ///   a choice's traitName must equal the name of a trait of the same
    ///   species, else constraintViolation.
    /// Path: unhappy (rule interaction)
    test('Species rejects a choice naming no trait', () {
      expect(
        () => _species(
          choices: [
            SpeciesChoice('Elven Lineage', [
              DamageTypeOption('Black', DamageType.acid),
            ]),
          ],
        ),
        throwsArgumentErrorFor('choices', 'Elven Lineage'),
      );
    });

    /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-060 -
    ///   a choice naming a trait of the same species is accepted and the
    ///   choices are possibly empty.
    /// Path: happy
    test('Species accepts a choice naming one of its traits', () {
      final species = _species(
        traits: [NamedText('Elven Lineage', 'The intro text.')],
        choices: [
          SpeciesChoice('Elven Lineage', [
            _lineage('Drow', [_dancingLights, _faerieFire, _darkness]),
          ]),
        ],
      );

      expect(species.choices, hasLength(1));
      expect(species.choices.single.traitName, 'Elven Lineage');
      expect(_species().choices, isEmpty);
    });

    /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-016 -
    ///   the choices are an unmodifiable defensive copy.
    /// Path: unhappy (immutability)
    test('Species choices are unmodifiable', () {
      final species = _species(
        traits: [NamedText('Elven Lineage', 'The intro text.')],
        choices: [
          SpeciesChoice('Elven Lineage', [
            _lineage('Drow', [_dancingLights, _faerieFire, _darkness]),
          ]),
        ],
      );

      expect(
        () => species.choices.add(
          SpeciesChoice('Elven Lineage', [
            DamageTypeOption('Black', DamageType.acid),
          ]),
        ),
        throwsUnsupportedError,
      );
      expect(
        () => species.traits.add(NamedText('Extra', 'text.')),
        throwsUnsupportedError,
      );
      expect(
        () => species.sizes.add(CreatureSize.small),
        throwsUnsupportedError,
      );
    });
  });

  /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-023 -
  ///   Species.references lists exactly one spell site per spellId and
  ///   spellIds element, with the FR-023 field paths, and none for a
  ///   species without choices.
  /// Path: happy
  group('Species reference sites (FR-023)', () {
    /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-023 -
    ///   every lineage levelBenefits/spellId and every option spellIds
    ///   element is one site with the exact field path, in choice, option
    ///   and element order; a damage-type option contributes no site.
    /// Path: happy
    test('lists exactly one site per spell id, with the FR-023 paths', () {
      final species = _species(
        traits: [
          NamedText('Draconic Ancestry', 'intro.'),
          NamedText('Elven Lineage', 'intro.'),
          NamedText('Gnomish Lineage', 'intro.'),
        ],
        choices: [
          SpeciesChoice('Draconic Ancestry', [
            DamageTypeOption('Black', DamageType.acid),
          ]),
          SpeciesChoice('Elven Lineage', [
            _lineage('Drow', [_dancingLights, _faerieFire, _darkness]),
            _lineage('High Elf', [_prestidigitation, _detectMagic, _mistyStep]),
          ]),
          SpeciesChoice('Gnomish Lineage', [
            TextOption(
              'Forest Gnome',
              'text.',
              spellIds: [_minorIllusion, _speakWithAnimals],
            ),
          ]),
        ],
      );

      final sites = species.references.toList();
      expect(sites, hasLength(8));
      expect(sites[0].field, 'choices/1/options/0/levelBenefits/0/spellId');
      expect(sites[0].target, ContentKey(ContentKind.spell, _dancingLights.id));
      expect(sites[1].field, 'choices/1/options/0/levelBenefits/1/spellId');
      expect(sites[1].target, ContentKey(ContentKind.spell, _faerieFire.id));
      expect(sites[2].field, 'choices/1/options/0/levelBenefits/2/spellId');
      expect(sites[2].target, ContentKey(ContentKind.spell, _darkness.id));
      expect(sites[3].field, 'choices/1/options/1/levelBenefits/0/spellId');
      expect(sites[4].field, 'choices/1/options/1/levelBenefits/1/spellId');
      expect(sites[5].field, 'choices/1/options/1/levelBenefits/2/spellId');
      expect(sites[6].field, 'choices/2/options/0/spellIds/0');
      expect(sites[6].target, ContentKey(ContentKind.spell, _minorIllusion.id));
      expect(sites[7].field, 'choices/2/options/0/spellIds/1');
      for (final site in sites) {
        expect(site.constraint, isNull, reason: site.field);
      }
    });

    /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-023 -
    ///   a species without choices has no sites.
    /// Path: happy
    test('a species without choices has no reference sites', () {
      expect(_species().references, isEmpty);
    });
  });

  /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-069,
  ///   FR-056, FR-071, schema FR-146 - the public limits and predicates,
  ///   the entry key, value equality and the debugging toString.
  /// Path: happy
  group('Species identity, limits, equality', () {
    /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-069 -
    ///   the size and speed limits are public constants and predicates the
    ///   decoder reuses.
    /// Path: happy
    test('the size and speed limits are public', () {
      expect(Species.minSizes, 1);
      expect(Species.maxSizes, 2);
      expect(Species.minSpeed, 0);
      expect(Species.isPlayerCharacterSize(CreatureSize.small), isTrue);
      expect(Species.isPlayerCharacterSize(CreatureSize.medium), isTrue);
      expect(Species.isPlayerCharacterSize(CreatureSize.large), isFalse);
      expect(Species.isValidSpeed(0), isTrue);
      expect(Species.isValidSpeed(-1), isFalse);
    });

    /// Requirement: doc/specs/content-schema-and-decoder.md FR-146 - the
    ///   entry key carries the species kind and id.
    /// Path: happy
    test('the key is the species kind and id', () {
      final species = _species(id: SpeciesId('elf'));

      expect(species.key, ContentKey(ContentKind.species, ContentId('elf')));
      expect(species.key, SpeciesId('elf').key);
    });

    /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-056 -
    ///   decoded entries compare by value (schema FR-071, FR-072).
    /// Path: happy
    test('species compare by value', () {
      final species = _species(sizeText: 'Medium.');
      final same = _species(sizeText: 'Medium.');

      expect(species, same);
      expect(species.hashCode, same.hashCode);
      expect(operatorEquals(species, _species(name: 'Dwarf')), isFalse);
      expect(operatorEquals(species, _species(speed: 35)), isFalse);
      expect(operatorEquals(species, 'elf'), isFalse);
    });

    /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-071 -
    ///   toString is a debugging form.
    /// Path: happy
    test('a species prints its id', () {
      expect(_species().toString(), 'Species(elf)');
    });
  });
}
