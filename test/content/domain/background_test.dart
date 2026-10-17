import 'package:srd5e/src/content/domain/background.dart';
import 'package:srd5e/src/content/domain/background_feat_reference.dart';
import 'package:srd5e/src/content/domain/content_id.dart';
import 'package:srd5e/src/content/domain/content_key.dart';
import 'package:srd5e/src/content/domain/content_kind.dart';
import 'package:srd5e/src/content/domain/content_reference.dart';
import 'package:srd5e/src/content/domain/equipment_options.dart';
import 'package:srd5e/src/content/domain/feat_category.dart';
import 'package:srd5e/src/content/domain/skill.dart';
import 'package:srd5e/src/content/domain/tool_proficiency.dart';
import 'package:srd5e/src/content/domain/typed_ids.dart';
import 'package:srd5e/src/shared_kernel/ability/ability.dart';
import 'package:test/test.dart';

import '../../support/argument_error_matcher.dart';
import '../../support/operator_equals.dart';

final _acolyteItems = [
  EquipmentItem('Calligrapher’s Supplies', 1),
  EquipmentItem('Book (prayers)', 1),
  EquipmentItem('Holy Symbol', 1),
  EquipmentItem('Parchment (10 sheets)', 1),
  EquipmentItem('Robe', 1),
];

Background _background({
  BackgroundId? id,
  String name = 'Acolyte',
  List<Ability>? abilityScores,
  BackgroundFeatReference? feat,
  List<Skill>? skillProficiencies,
  ToolProficiency? toolProficiency,
  EquipmentOptions? equipmentOptions,
}) => Background(
  id: id ?? BackgroundId('acolyte'),
  name: name,
  abilityScores:
      abilityScores ??
      const [Ability.intelligence, Ability.wisdom, Ability.charisma],
  feat: feat ?? BackgroundFeatReference(FeatId('magic_initiate'), 'Cleric'),
  skillProficiencies:
      skillProficiencies ?? const [Skill.insight, Skill.religion],
  toolProficiency:
      toolProficiency ?? SpecificToolProficiency('Calligrapher’s Supplies'),
  equipmentOptions:
      equipmentOptions ??
      EquipmentOptions(
        a: EquipmentOption(_acolyteItems, 8),
        b: EquipmentOption([], 50),
      ),
);

void main() {
  /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-024,
  ///   FR-025, FR-026, FR-027, FR-028, FR-029, FR-031 - the four bundled
  ///   backgrounds construct field for field ("Background cases",
  ///   SRD 5.2.1, p. 83); each row carries its own path.
  /// Path: happy
  group('Background cases (the four SRD shapes construct)', () {
    /// Requirement: per case
    /// Path: per case
    for (final c in [
      (
        label: 'acolyte',
        requirement:
            'doc/specs/content-species-backgrounds-feats.md FR-024, FR-025, '
            'FR-026, FR-027, FR-028, FR-029, FR-031 - Acolyte: Intelligence, '
            'Wisdom, Charisma; magic_initiate (Cleric); Insight, Religion; '
            'specific Calligrapher’s Supplies; option A with its items and '
            '8 GP, option B 50 GP (SRD 5.2.1, p. 83)',
        id: 'acolyte',
        name: 'Acolyte',
        abilities: [Ability.intelligence, Ability.wisdom, Ability.charisma],
        featId: 'magic_initiate',
        choice: 'Cleric',
        skills: [Skill.insight, Skill.religion],
        tool: SpecificToolProficiency('Calligrapher’s Supplies'),
        items: _acolyteItems,
        goldA: 8,
      ),
      (
        label: 'criminal',
        requirement:
            'doc/specs/content-species-backgrounds-feats.md FR-024, FR-025, '
            'FR-026, FR-027, FR-028, FR-029, FR-031 - Criminal: Dexterity, '
            'Constitution, Intelligence; alert; Sleight of Hand, Stealth; '
            'specific Thieves’ Tools; option A with its items and 16 GP '
            '(SRD 5.2.1, p. 83)',
        id: 'criminal',
        name: 'Criminal',
        abilities: [
          Ability.dexterity,
          Ability.constitution,
          Ability.intelligence,
        ],
        featId: 'alert',
        choice: null,
        skills: [Skill.sleightOfHand, Skill.stealth],
        tool: SpecificToolProficiency('Thieves’ Tools'),
        items: [
          EquipmentItem('Daggers', 2),
          EquipmentItem('Thieves’ Tools', 1),
          EquipmentItem('Crowbar', 1),
          EquipmentItem('Pouches', 2),
          EquipmentItem('Traveler’s Clothes', 1),
        ],
        goldA: 16,
      ),
      (
        label: 'sage',
        requirement:
            'doc/specs/content-species-backgrounds-feats.md FR-024, FR-025, '
            'FR-026, FR-027, FR-028, FR-029, FR-031 - Sage: Constitution, '
            'Intelligence, Wisdom; magic_initiate (Wizard); Arcana, History; '
            'specific Calligrapher’s Supplies; option A with its items and '
            '8 GP (SRD 5.2.1, p. 83)',
        id: 'sage',
        name: 'Sage',
        abilities: [Ability.constitution, Ability.intelligence, Ability.wisdom],
        featId: 'magic_initiate',
        choice: 'Wizard',
        skills: [Skill.arcana, Skill.history],
        tool: SpecificToolProficiency('Calligrapher’s Supplies'),
        items: [
          EquipmentItem('Quarterstaff', 1),
          EquipmentItem('Calligrapher’s Supplies', 1),
          EquipmentItem('Book (history)', 1),
          EquipmentItem('Parchment (8 sheets)', 1),
          EquipmentItem('Robe', 1),
        ],
        goldA: 8,
      ),
      (
        label: 'soldier',
        requirement:
            'doc/specs/content-species-backgrounds-feats.md FR-024, FR-025, '
            'FR-026, FR-027, FR-028, FR-029, FR-031 - Soldier: Strength, '
            'Dexterity, Constitution; savage_attacker; Athletics, '
            'Intimidation; choice Gaming Set; option A with its items (the '
            'leading numeral of "20 Arrows" is the quantity) and 14 GP '
            '(SRD 5.2.1, p. 83)',
        id: 'soldier',
        name: 'Soldier',
        abilities: [Ability.strength, Ability.dexterity, Ability.constitution],
        featId: 'savage_attacker',
        choice: null,
        skills: [Skill.athletics, Skill.intimidation],
        tool: ChoiceToolProficiency('Gaming Set'),
        items: [
          EquipmentItem('Spear', 1),
          EquipmentItem('Shortbow', 1),
          EquipmentItem('Arrows', 20),
          EquipmentItem('Gaming Set (same as above)', 1),
          EquipmentItem('Healer’s Kit', 1),
          EquipmentItem('Quiver', 1),
          EquipmentItem('Traveler’s Clothes', 1),
        ],
        goldA: 14,
      ),
    ]) {
      test('Background ${c.label} constructs field for field [happy]', () {
        final background = _background(
          id: BackgroundId(c.id),
          name: c.name,
          abilityScores: c.abilities,
          feat: BackgroundFeatReference(FeatId(c.featId), c.choice),
          skillProficiencies: c.skills,
          toolProficiency: c.tool,
          equipmentOptions: EquipmentOptions(
            a: EquipmentOption(c.items, c.goldA),
            b: EquipmentOption([], 50),
          ),
        );

        expect(background.id, BackgroundId(c.id));
        expect(background.name, c.name);
        expect(background.abilityScores, c.abilities);
        expect(background.feat.featId, FeatId(c.featId));
        expect(background.feat.choice, c.choice);
        expect(background.skillProficiencies, c.skills);
        expect(background.toolProficiency, c.tool);
        expect(background.equipmentOptions.a.items, c.items);
        expect(background.equipmentOptions.a.gold, c.goldA);
        expect(background.equipmentOptions.b.items, isEmpty);
        expect(background.equipmentOptions.b.gold, 50);
      });
    }
  });

  /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-024,
  ///   FR-027, FR-069 - two or four abilities, a repeat, one or three
  ///   skills, a repeated skill and a blank name are rejected, and the
  ///   required counts are public constants.
  /// Path: unhappy (boundary)
  group('Background constructor rows (FR-024, FR-027)', () {
    /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-024 -
    ///   two or four abilities are outOfRange ("abilities and skills" row).
    /// Path: unhappy (boundary)
    test('rejects two or four abilities', () {
      expect(
        () => _background(abilityScores: [Ability.strength, Ability.dexterity]),
        throwsArgumentErrorFor('abilityScores', [
          Ability.strength,
          Ability.dexterity,
        ]),
      );
      expect(
        () => _background(
          abilityScores: [
            Ability.strength,
            Ability.dexterity,
            Ability.constitution,
            Ability.intelligence,
          ],
        ),
        throwsArgumentErrorFor('abilityScores', isA<List<Ability>>()),
      );
    });

    /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-024 -
    ///   a repeated ability is duplicate ("Strength twice").
    /// Path: unhappy (invalid input)
    test('rejects a repeated ability', () {
      expect(
        () => _background(
          abilityScores: [
            Ability.strength,
            Ability.dexterity,
            Ability.strength,
          ],
        ),
        throwsArgumentErrorFor('abilityScores', Ability.strength),
      );
    });

    /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-027 -
    ///   one or three skills are outOfRange ("one or three skills").
    /// Path: unhappy (boundary)
    test('rejects one or three skills', () {
      expect(
        () => _background(skillProficiencies: [Skill.stealth]),
        throwsArgumentErrorFor('skillProficiencies', [Skill.stealth]),
      );
      expect(
        () => _background(
          skillProficiencies: [Skill.stealth, Skill.arcana, Skill.history],
        ),
        throwsArgumentErrorFor('skillProficiencies', isA<List<Skill>>()),
      );
    });

    /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-027 -
    ///   a repeated skill is duplicate ("Stealth twice").
    /// Path: unhappy (invalid input)
    test('rejects a repeated skill', () {
      expect(
        () => _background(skillProficiencies: [Skill.stealth, Skill.stealth]),
        throwsArgumentErrorFor('skillProficiencies', Skill.stealth),
      );
    });

    /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-027 -
    ///   the name rule (schema FR-027).
    /// Path: unhappy (invalid input)
    test('rejects a blank name', () {
      expect(() => _background(name: ' '), throwsArgumentErrorFor('name', ' '));
    });

    /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-069 -
    ///   the required counts are public constants the decoder reuses.
    /// Path: happy
    test('exposes the required ability and skill counts', () {
      expect(Background.requiredAbilityScores, 3);
      expect(Background.requiredSkillProficiencies, 2);
    });
  });

  /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-025,
  ///   FR-072, schema FR-146 - the feat reference site with its Origin
  ///   constraint, step 2 not a constructor rule, and the entry key.
  /// Path: happy
  group('Background feat reference (FR-025, FR-072)', () {
    /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-025 -
    ///   Background.references lists exactly the feat/featId site with
    ///   TargetHasFeatCategory(Origin) and the feat key as target.
    /// Path: happy
    test(
      'lists exactly one feat reference site with the Origin constraint',
      () {
        final background = _background(
          feat: BackgroundFeatReference(FeatId('magic_initiate'), 'Cleric'),
        );

        final sites = background.references.toList();
        expect(sites, hasLength(1));
        expect(sites.single.field, 'feat/featId');
        expect(
          sites.single.target,
          ContentKey(ContentKind.feat, ContentId('magic_initiate')),
        );
        expect(
          sites.single.constraint,
          const TargetHasFeatCategory(FeatCategory.origin),
        );
      },
    );

    /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-072 -
    ///   step 2 (a feat of the Origin category) is enforced by the decoder
    ///   and whole-set validation, not construction: a host-built
    ///   Background referencing a General feat is representable.
    /// Path: unhappy (rule interaction)
    test('accepts a reference to a non-Origin feat at construction', () {
      final background = _background(
        feat: BackgroundFeatReference(FeatId('grappler')),
      );

      expect(background.feat.featId, FeatId('grappler'));
    });

    /// Requirement: doc/specs/content-schema-and-decoder.md FR-146 - the
    ///   entry key carries the background kind and id.
    /// Path: happy
    test('the key is the background kind and id', () {
      final background = _background(id: BackgroundId('acolyte'));

      expect(
        background.key,
        ContentKey(ContentKind.background, ContentId('acolyte')),
      );
    });
  });

  /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-056,
  ///   FR-071 - decoded entries compare by value and their collections are
  ///   unmodifiable; toString is a debugging form.
  /// Path: happy
  group('Background value shape', () {
    /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-056 -
    ///   decoded entries compare by value, and the collections are
    ///   unmodifiable (schema FR-071, FR-072).
    /// Path: happy
    test('backgrounds compare by value and their lists are unmodifiable', () {
      final background = _background();
      final same = _background();

      expect(background, same);
      expect(background.hashCode, same.hashCode);
      expect(
        operatorEquals(background, _background(name: 'Criminal')),
        isFalse,
      );
      expect(
        operatorEquals(
          background,
          _background(skillProficiencies: [Skill.religion, Skill.insight]),
        ),
        isFalse,
      );
      expect(operatorEquals(background, 'Acolyte'), isFalse);
      expect(
        () => background.abilityScores.add(Ability.strength),
        throwsUnsupportedError,
      );
      expect(
        () => background.skillProficiencies.add(Skill.arcana),
        throwsUnsupportedError,
      );
    });

    /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-071 -
    ///   toString is a debugging form.
    /// Path: happy
    test('a background prints its id', () {
      expect(_background().toString(), 'Background(acolyte)');
    });
  });
}
