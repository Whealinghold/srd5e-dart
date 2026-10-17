import 'package:srd5e/src/content/domain/content_id.dart';
import 'package:srd5e/src/content/domain/content_key.dart';
import 'package:srd5e/src/content/domain/content_kind.dart';
import 'package:srd5e/src/content/domain/feat.dart';
import 'package:srd5e/src/content/domain/feat_benefit.dart';
import 'package:srd5e/src/content/domain/feat_category.dart';
import 'package:srd5e/src/content/domain/prerequisite.dart';
import 'package:srd5e/src/content/domain/typed_ids.dart';
import 'package:srd5e/src/shared_kernel/ability/ability.dart';
import 'package:test/test.dart';

import '../../support/argument_error_matcher.dart';
import '../../support/operator_equals.dart';

const String _repeatableSentence = 'The printed Repeatable sentence.';

FeatBenefit _benefit([String? name]) =>
    FeatBenefit(name: name, text: 'The benefit text.');

Feat _feat({
  required String id,
  required String name,
  required FeatCategory category,
  List<Prerequisite>? prerequisites,
  List<FeatBenefit>? benefits,
  required bool repeatable,
  String? repeatableText,
}) => Feat(
  id: FeatId(id),
  name: name,
  category: category,
  prerequisites: prerequisites,
  benefits: benefits ?? [_benefit()],
  repeatable: repeatable,
  repeatableText: repeatableText,
);

/// The "Feat cases" table, one row per feat: category, prerequisites,
/// repeatable (SRD 5.2.1, pp. 87-88). A row naming several feats is one test
/// per feat.
final List<
  ({
    String label,
    String id,
    String name,
    FeatCategory category,
    String requirement,
    List<Prerequisite>? prerequisites,
    bool repeatable,
  })
>
_cases = [
  (
    label: 'Alert',
    id: 'alert',
    name: 'Alert',
    category: FeatCategory.origin,
    requirement:
        'doc/specs/content-species-backgrounds-feats.md FR-034, FR-038, '
        'FR-039 - Alert: Origin, no prerequisites, not repeatable '
        '(SRD 5.2.1, p. 87)',
    prerequisites: null,
    repeatable: false,
  ),
  (
    label: 'Savage Attacker',
    id: 'savage_attacker',
    name: 'Savage Attacker',
    category: FeatCategory.origin,
    requirement:
        'doc/specs/content-species-backgrounds-feats.md FR-034, FR-038, '
        'FR-039 - Savage Attacker: Origin, no prerequisites, not repeatable '
        '(SRD 5.2.1, p. 87)',
    prerequisites: null,
    repeatable: false,
  ),
  (
    label: 'Magic Initiate',
    id: 'magic_initiate',
    name: 'Magic Initiate',
    category: FeatCategory.origin,
    requirement:
        'doc/specs/content-species-backgrounds-feats.md FR-034, FR-039 - '
        'Magic Initiate: Origin, no prerequisites, repeatable (SRD 5.2.1, '
        'p. 87)',
    prerequisites: null,
    repeatable: true,
  ),
  (
    label: 'Skilled',
    id: 'skilled',
    name: 'Skilled',
    category: FeatCategory.origin,
    requirement:
        'doc/specs/content-species-backgrounds-feats.md FR-034, FR-039 - '
        'Skilled: Origin, no prerequisites, repeatable (SRD 5.2.1, p. 87)',
    prerequisites: null,
    repeatable: true,
  ),
  (
    label: 'Ability Score Improvement',
    id: 'ability_score_improvement',
    name: 'Ability Score Improvement',
    category: FeatCategory.general,
    requirement:
        'doc/specs/content-species-backgrounds-feats.md FR-038, FR-039 - '
        'Ability Score Improvement: General, level 4, repeatable '
        '(SRD 5.2.1, p. 87)',
    prerequisites: [LevelPrerequisite(4)],
    repeatable: true,
  ),
  (
    label: 'Grappler',
    id: 'grappler',
    name: 'Grappler',
    category: FeatCategory.general,
    requirement:
        'doc/specs/content-species-backgrounds-feats.md FR-038 - Grappler: '
        'General, level 4 and Strength or Dexterity 13, not repeatable '
        '(SRD 5.2.1, p. 87)',
    prerequisites: [
      LevelPrerequisite(4),
      AbilityScorePrerequisite({Ability.strength, Ability.dexterity}, 13),
    ],
    repeatable: false,
  ),
  (
    label: 'Archery',
    id: 'archery',
    name: 'Archery',
    category: FeatCategory.fightingStyle,
    requirement:
        'doc/specs/content-species-backgrounds-feats.md FR-038 - Archery: '
        'Fighting Style, feature Fighting Style Feature, not repeatable '
        '(SRD 5.2.1, p. 87)',
    prerequisites: [FeaturePrerequisite('Fighting Style Feature')],
    repeatable: false,
  ),
  (
    label: 'Defense',
    id: 'defense',
    name: 'Defense',
    category: FeatCategory.fightingStyle,
    requirement:
        'doc/specs/content-species-backgrounds-feats.md FR-038 - Defense: '
        'Fighting Style, feature Fighting Style Feature, not repeatable '
        '(SRD 5.2.1, p. 88)',
    prerequisites: [FeaturePrerequisite('Fighting Style Feature')],
    repeatable: false,
  ),
  (
    label: 'Great Weapon Fighting',
    id: 'great_weapon_fighting',
    name: 'Great Weapon Fighting',
    category: FeatCategory.fightingStyle,
    requirement:
        'doc/specs/content-species-backgrounds-feats.md FR-038 - Great '
        'Weapon Fighting: Fighting Style, feature Fighting Style Feature, '
        'not repeatable (SRD 5.2.1, p. 88)',
    prerequisites: [FeaturePrerequisite('Fighting Style Feature')],
    repeatable: false,
  ),
  (
    label: 'Two-Weapon Fighting',
    id: 'two_weapon_fighting',
    name: 'Two-Weapon Fighting',
    category: FeatCategory.fightingStyle,
    requirement:
        'doc/specs/content-species-backgrounds-feats.md FR-038 - '
        'Two-Weapon Fighting: Fighting Style, feature Fighting Style '
        'Feature, not repeatable (SRD 5.2.1, p. 88)',
    prerequisites: [FeaturePrerequisite('Fighting Style Feature')],
    repeatable: false,
  ),
  (
    label: 'Boon of Combat Prowess',
    id: 'boon_of_combat_prowess',
    name: 'Boon of Combat Prowess',
    category: FeatCategory.epicBoon,
    requirement:
        'doc/specs/content-species-backgrounds-feats.md FR-038 - Boon of '
        'Combat Prowess: Epic Boon, level 19, not repeatable (SRD 5.2.1, '
        'p. 88)',
    prerequisites: [LevelPrerequisite(19)],
    repeatable: false,
  ),
  (
    label: 'Boon of Dimensional Travel',
    id: 'boon_of_dimensional_travel',
    name: 'Boon of Dimensional Travel',
    category: FeatCategory.epicBoon,
    requirement:
        'doc/specs/content-species-backgrounds-feats.md FR-038 - Boon of '
        'Dimensional Travel: Epic Boon, level 19, not repeatable '
        '(SRD 5.2.1, p. 88)',
    prerequisites: [LevelPrerequisite(19)],
    repeatable: false,
  ),
  (
    label: 'Boon of Fate',
    id: 'boon_of_fate',
    name: 'Boon of Fate',
    category: FeatCategory.epicBoon,
    requirement:
        'doc/specs/content-species-backgrounds-feats.md FR-038 - Boon of '
        'Fate: Epic Boon, level 19, not repeatable (SRD 5.2.1, p. 88)',
    prerequisites: [LevelPrerequisite(19)],
    repeatable: false,
  ),
  (
    label: 'Boon of Irresistible Offense',
    id: 'boon_of_irresistible_offense',
    name: 'Boon of Irresistible Offense',
    category: FeatCategory.epicBoon,
    requirement:
        'doc/specs/content-species-backgrounds-feats.md FR-038 - Boon of '
        'Irresistible Offense: Epic Boon, level 19, not repeatable '
        '(SRD 5.2.1, p. 88)',
    prerequisites: [LevelPrerequisite(19)],
    repeatable: false,
  ),
  (
    label: 'Boon of the Night Spirit',
    id: 'boon_of_the_night_spirit',
    name: 'Boon of the Night Spirit',
    category: FeatCategory.epicBoon,
    requirement:
        'doc/specs/content-species-backgrounds-feats.md FR-038 - Boon of '
        'the Night Spirit: Epic Boon, level 19, not repeatable (SRD 5.2.1, '
        'p. 88)',
    prerequisites: [LevelPrerequisite(19)],
    repeatable: false,
  ),
  (
    label: 'Boon of Truesight',
    id: 'boon_of_truesight',
    name: 'Boon of Truesight',
    category: FeatCategory.epicBoon,
    requirement:
        'doc/specs/content-species-backgrounds-feats.md FR-038 - Boon of '
        'Truesight: Epic Boon, level 19, not repeatable (SRD 5.2.1, p. 88)',
    prerequisites: [LevelPrerequisite(19)],
    repeatable: false,
  ),
  (
    label: 'Boon of Spell Recall',
    id: 'boon_of_spell_recall',
    name: 'Boon of Spell Recall',
    category: FeatCategory.epicBoon,
    requirement:
        'doc/specs/content-species-backgrounds-feats.md FR-038 - Boon of '
        'Spell Recall: Epic Boon, level 19 and feature Spellcasting '
        'Feature, not repeatable (SRD 5.2.1, p. 88)',
    prerequisites: [
      LevelPrerequisite(19),
      FeaturePrerequisite('Spellcasting Feature'),
    ],
    repeatable: false,
  ),
];

void main() {
  /// Requirement: per case
  /// Path: per case
  for (final c in _cases) {
    test('Feat ${c.label} constructs with its case row [happy]', () {
      final feat = _feat(
        id: c.id,
        name: c.name,
        category: c.category,
        prerequisites: c.prerequisites,
        repeatable: c.repeatable,
        repeatableText: c.repeatable ? _repeatableSentence : null,
      );

      expect(feat.id, FeatId(c.id));
      expect(feat.name, c.name);
      expect(feat.category, c.category);
      expect(feat.featCategory, c.category);
      expect(feat.prerequisites, c.prerequisites);
      expect(feat.repeatable, c.repeatable);
      if (c.repeatable) {
        expect(feat.repeatableText, _repeatableSentence);
      } else {
        expect(feat.repeatableText, isNull);
      }
    });
  }

  /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-033,
  ///   FR-035, FR-039, SX-2, SX-4 - the unhappy constructor rows: empty
  ///   prerequisites, no benefits, and the repeatable/repeatableText pair
  ///   disagreeing.
  /// Path: unhappy (invalid input)
  group('Feat constructor rows', () {
    /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-033 -
    ///   prerequisites is optional: a feat with none omits the field.
    /// Path: happy
    test('a feat without prerequisites omits them', () {
      final feat = _feat(
        id: 'alert',
        name: 'Alert',
        category: FeatCategory.origin,
        repeatable: false,
      );

      expect(feat.prerequisites, isNull);
    });

    /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-035,
    ///   SX-4 - an empty prerequisites list is outOfRange ("empty
    ///   prerequisites" row).
    /// Path: unhappy (invalid input)
    test('rejects an empty prerequisites list', () {
      expect(
        () => _feat(
          id: 'alert',
          name: 'Alert',
          category: FeatCategory.origin,
          prerequisites: [],
          repeatable: false,
        ),
        throwsArgumentErrorFor('prerequisites', isEmpty),
      );
    });

    /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-033 -
    ///   benefits is one or more; an empty list is outOfRange ("no
    ///   benefits" row).
    /// Path: unhappy (empty case)
    test('rejects an empty benefits list', () {
      expect(
        () => _feat(
          id: 'alert',
          name: 'Alert',
          category: FeatCategory.origin,
          benefits: [],
          repeatable: false,
        ),
        throwsArgumentErrorFor('benefits', isEmpty),
      );
    });

    /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-039,
    ///   SX-2 - repeatableText with repeatable: false is a
    ///   constraintViolation ("repeatable text without repeatable" row).
    /// Path: unhappy (rule interaction)
    test('rejects repeatable text on a non-repeatable feat', () {
      expect(
        () => _feat(
          id: 'alert',
          name: 'Alert',
          category: FeatCategory.origin,
          repeatable: false,
          repeatableText: _repeatableSentence,
        ),
        throwsArgumentErrorFor('repeatableText', _repeatableSentence),
      );
    });

    /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-039,
    ///   SX-2 - repeatable without repeatableText is missingField
    ///   ("repeatable without text" row).
    /// Path: unhappy (missing content)
    test('rejects a repeatable feat without repeatable text', () {
      expect(
        () => _feat(
          id: 'magic_initiate',
          name: 'Magic Initiate',
          category: FeatCategory.origin,
          repeatable: true,
        ),
        throwsArgumentErrorFor('repeatableText', isNull),
      );
    });

    /// Requirement: doc/specs/content-species-backgrounds-feats.md SX-2 -
    ///   a present repeatableText is a non-blank string (schema FR-028).
    /// Path: unhappy (invalid input)
    test('rejects a blank repeatable text', () {
      expect(
        () => _feat(
          id: 'magic_initiate',
          name: 'Magic Initiate',
          category: FeatCategory.origin,
          repeatable: true,
          repeatableText: ' ',
        ),
        throwsArgumentErrorFor('repeatableText', ' '),
      );
    });

    /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-027 -
    ///   the feat name follows the name rule.
    /// Path: unhappy (invalid input)
    test('rejects a blank name', () {
      expect(
        () => _feat(
          id: 'alert',
          name: ' ',
          category: FeatCategory.origin,
          repeatable: false,
        ),
        throwsArgumentErrorFor('name', ' '),
      );
    });
  });

  /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-025,
  ///   FR-056, FR-069, FR-071, schema FR-146 - the feat reports its category
  ///   through HasFeatCategory, carries the feat key, compares by value,
  ///   holds unmodifiable collections and the public limit.
  /// Path: happy
  group('Feat shape', () {
    /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-025 -
    ///   Feat implements HasFeatCategory, featCategory is the category, so a
    ///   reference constraint can check it.
    /// Path: happy
    test('reports its category through HasFeatCategory', () {
      final feat = _feat(
        id: 'magic_initiate',
        name: 'Magic Initiate',
        category: FeatCategory.origin,
        repeatable: true,
        repeatableText: _repeatableSentence,
      );

      expect(feat.featCategory, FeatCategory.origin);
    });

    /// Requirement: doc/specs/content-schema-and-decoder.md FR-146 - the
    ///   entry key carries the feat kind and id.
    /// Path: happy
    test('the key is the feat kind and id', () {
      final feat = _feat(
        id: 'alert',
        name: 'Alert',
        category: FeatCategory.origin,
        repeatable: false,
      );

      expect(feat.key, ContentKey(ContentKind.feat, ContentId('alert')));
    });

    /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-069 -
    ///   the minimum benefit count is a public constant the decoder reuses.
    /// Path: happy
    test('exposes the minimum benefit count', () {
      expect(Feat.minBenefits, 1);
    });

    /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-056 -
    ///   feats compare by value and the collections are unmodifiable
    ///   (schema FR-071, FR-072).
    /// Path: happy
    test('feats compare by value; collections are unmodifiable', () {
      final feat = _feat(
        id: 'grappler',
        name: 'Grappler',
        category: FeatCategory.general,
        prerequisites: [LevelPrerequisite(4)],
        benefits: [_benefit('Punch and Grab')],
        repeatable: false,
      );
      final same = _feat(
        id: 'grappler',
        name: 'Grappler',
        category: FeatCategory.general,
        prerequisites: [LevelPrerequisite(4)],
        benefits: [_benefit('Punch and Grab')],
        repeatable: false,
      );

      expect(feat, same);
      expect(feat.hashCode, same.hashCode);
      expect(
        operatorEquals(
          feat,
          _feat(
            id: 'grappler',
            name: 'Grappler',
            category: FeatCategory.general,
            prerequisites: [LevelPrerequisite(4)],
            benefits: [_benefit('Fast Wrestler')],
            repeatable: false,
          ),
        ),
        isFalse,
      );
      expect(
        operatorEquals(
          feat,
          _feat(
            id: 'grappler',
            name: 'Grappler',
            category: FeatCategory.general,
            prerequisites: [LevelPrerequisite(5)],
            benefits: [_benefit('Punch and Grab')],
            repeatable: false,
          ),
        ),
        isFalse,
      );
      expect(
        operatorEquals(
          feat,
          _feat(
            id: 'grappler',
            name: 'Grappler',
            category: FeatCategory.general,
            // A different prerequisite-list length: the length guard of the
            // element-wise comparison must reject it before the loop runs.
            prerequisites: [
              LevelPrerequisite(4),
              FeaturePrerequisite('Fighting Style Feature'),
            ],
            benefits: [_benefit('Punch and Grab')],
            repeatable: false,
          ),
        ),
        isFalse,
      );
      expect(operatorEquals(feat, 'Grappler'), isFalse);
      expect(() => feat.benefits.add(_benefit()), throwsUnsupportedError);
      expect(
        () => feat.prerequisites!.add(LevelPrerequisite(20)),
        throwsUnsupportedError,
      );
    });

    /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-056,
    ///   FR-035 - feats without prerequisites (the field omitted) compare
    ///   by value too: two such feats are equal, and one without them is
    ///   never equal to one holding a prerequisite.
    /// Path: happy
    test('feats without prerequisites compare by value', () {
      final alert = _feat(
        id: 'alert',
        name: 'Alert',
        category: FeatCategory.origin,
        repeatable: false,
      );
      final same = _feat(
        id: 'alert',
        name: 'Alert',
        category: FeatCategory.origin,
        repeatable: false,
      );
      final otherFeat = _feat(
        id: 'savage_attacker',
        name: 'Savage Attacker',
        category: FeatCategory.origin,
        repeatable: false,
      );
      final withPrerequisite = _feat(
        id: 'alert',
        name: 'Alert',
        category: FeatCategory.origin,
        prerequisites: [LevelPrerequisite(4)],
        repeatable: false,
      );

      expect(alert.prerequisites, isNull);
      expect(alert, same);
      expect(alert.hashCode, same.hashCode);
      expect(operatorEquals(alert, otherFeat), isFalse);
      expect(operatorEquals(alert, withPrerequisite), isFalse);
      expect(operatorEquals(withPrerequisite, alert), isFalse);
    });

    /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-071 -
    ///   toString is a debugging form.
    /// Path: happy
    test('a feat prints its id', () {
      expect(
        _feat(
          id: 'alert',
          name: 'Alert',
          category: FeatCategory.origin,
          repeatable: false,
        ).toString(),
        'Feat(alert)',
      );
    });
  });
}
