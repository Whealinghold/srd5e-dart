import 'package:srd5e/src/content/domain/classes/class_definition.dart';
import 'package:srd5e/src/content/domain/classes/feature_entry.dart';
import 'package:srd5e/src/content/domain/classes/feature_fact.dart';
import 'package:srd5e/src/content/domain/classes/feature_option.dart';
import 'package:srd5e/src/content/domain/classes/subclass_definition.dart';
import 'package:srd5e/src/content/domain/content_key.dart';
import 'package:srd5e/src/content/domain/content_reference.dart';
import 'package:srd5e/src/content/domain/feat_category.dart';
import 'package:srd5e/src/content/domain/typed_ids.dart';
import 'package:test/test.dart';

import 'class_fixture.dart';

FeatureEntry _classFeature(
  String id,
  int level, {
  List<FeatureFact> facts = const [],
  List<FeatureOption> options = const [],
}) => FeatureEntry(
  id: FeatureId(id),
  name: 'A feature',
  level: level,
  text: 'The printed text of the feature.',
  facts: facts,
  options: options,
);

ContentKey _spellKey(String id) => SpellId(id).key;

void main() {
  /// Requirement: doc/specs/content-classes.md FR-059 - every spell id
  ///   inside an `AlwaysPreparedSpells` fact on a class feature, a subclass
  ///   feature or a feature option is a whole-set reference site;
  ///   doc/specs/content-schema-and-decoder.md FR-127 - the sites are
  ///   listed in document order, class features then subclass features.
  /// Path: happy
  group('spell reference sites (R1-classes-spell-sites)', () {
    /// Requirement: doc/specs/content-classes.md FR-059 - the spell ids of
    ///   an option's `AlwaysPreparedSpells` facts and of a subclass
    ///   feature's fact are sites, after the class features' own sites,
    ///   each with its path inside the entry.
    /// Path: happy
    test('option and subclass spell ids are sites in document order', () {
      final definition = buildTestClass(
        features: [
          _classFeature(
            'barbarian_primal_spells',
            1,
            options: [
              FeatureOption(
                id: FeatureOptionId('primal_spells'),
                name: 'Primal Spells',
                text: 'You know the printed spells always prepared.',
                facts: [
                  AlwaysPreparedSpells([
                    SpellGrant(1, [SpellId('test_bless')]),
                    SpellGrant(3, [SpellId('test_shield')]),
                  ]),
                ],
              ),
            ],
          ),
          _classFeature(
            'barbarian_subclass',
            3,
            facts: [const GrantsSubclass()],
          ),
          _classFeature(
            'barbarian_ability_score_improvement',
            4,
            facts: [const GrantsFeat(FeatCategory.general)],
          ),
        ],
        subclasses: [
          SubclassDefinition(
            id: SubclassId('berserker'),
            name: 'Path of the Test',
            features: [
              _classFeature(
                'berserker_rage_spells',
                3,
                facts: [
                  AlwaysPreparedSpells([
                    SpellGrant(3, [SpellId('test_wrath')]),
                  ]),
                ],
              ),
            ],
          ),
        ],
      );

      final references = definition.references.toList();
      expect(references, [
        ContentReference(
          'features/0/options/0/facts/0/grants/0/spellIds/0',
          _spellKey('test_bless'),
        ),
        ContentReference(
          'features/0/options/0/facts/0/grants/1/spellIds/0',
          _spellKey('test_shield'),
        ),
        ContentReference(
          'subclasses/0/features/0/facts/0/grants/0/spellIds/0',
          _spellKey('test_wrath'),
        ),
      ]);
    });

    /// Requirement: doc/specs/content-schema-and-decoder.md FR-127 - the
    ///   walk visits every level of the tree: a class feature's own facts
    ///   with several grants and ids, every option and every option fact,
    ///   every subclass and every subclass feature, in document order.
    /// Path: happy
    test('the walk visits every feature, fact, option, grant and id', () {
      final ClassDefinition definition = buildTestClass(
        features: [
          _classFeature(
            'barbarian_primal_spells',
            1,
            facts: [
              AlwaysPreparedSpells([
                SpellGrant(1, [SpellId('test_a'), SpellId('test_b')]),
                SpellGrant(3, [SpellId('test_c')]),
              ]),
            ],
            options: [
              FeatureOption(
                id: FeatureOptionId('primal_spells'),
                name: 'Primal Spells',
                text: 'You know the printed spells always prepared.',
                facts: [
                  AlwaysPreparedSpells([
                    SpellGrant(1, [SpellId('test_d')]),
                  ]),
                  AlwaysPreparedSpells([
                    SpellGrant(1, [SpellId('test_e')]),
                  ]),
                ],
              ),
              FeatureOption(
                id: FeatureOptionId('primal_fury'),
                name: 'Primal Fury',
                text: 'You know the printed spells always prepared.',
                facts: [
                  AlwaysPreparedSpells([
                    SpellGrant(2, [SpellId('test_f')]),
                  ]),
                ],
              ),
            ],
          ),
          _classFeature(
            'barbarian_subclass',
            3,
            facts: [const GrantsSubclass()],
          ),
          _classFeature(
            'barbarian_ability_score_improvement',
            4,
            facts: [const GrantsFeat(FeatCategory.general)],
          ),
        ],
        subclasses: [
          SubclassDefinition(
            id: SubclassId('berserker'),
            name: 'Path of the Test',
            features: [
              _classFeature(
                'berserker_rage_spells',
                3,
                facts: [
                  AlwaysPreparedSpells([
                    SpellGrant(3, [SpellId('test_g')]),
                    SpellGrant(6, [SpellId('test_h'), SpellId('test_i')]),
                  ]),
                ],
              ),
              _classFeature('berserker_mindless_rage', 6),
            ],
          ),
          SubclassDefinition(
            id: SubclassId('wildheart'),
            name: 'Heart of the Test',
            features: [
              _classFeature(
                'wildheart_spells',
                3,
                facts: [
                  AlwaysPreparedSpells([
                    SpellGrant(3, [SpellId('test_j')]),
                  ]),
                ],
              ),
            ],
          ),
        ],
      );

      expect(definition.references.toList(), [
        ContentReference(
          'features/0/facts/0/grants/0/spellIds/0',
          _spellKey('test_a'),
        ),
        ContentReference(
          'features/0/facts/0/grants/0/spellIds/1',
          _spellKey('test_b'),
        ),
        ContentReference(
          'features/0/facts/0/grants/1/spellIds/0',
          _spellKey('test_c'),
        ),
        ContentReference(
          'features/0/options/0/facts/0/grants/0/spellIds/0',
          _spellKey('test_d'),
        ),
        ContentReference(
          'features/0/options/0/facts/1/grants/0/spellIds/0',
          _spellKey('test_e'),
        ),
        ContentReference(
          'features/0/options/1/facts/0/grants/0/spellIds/0',
          _spellKey('test_f'),
        ),
        ContentReference(
          'subclasses/0/features/0/facts/0/grants/0/spellIds/0',
          _spellKey('test_g'),
        ),
        ContentReference(
          'subclasses/0/features/0/facts/0/grants/1/spellIds/0',
          _spellKey('test_h'),
        ),
        ContentReference(
          'subclasses/0/features/0/facts/0/grants/1/spellIds/1',
          _spellKey('test_i'),
        ),
        ContentReference(
          'subclasses/1/features/0/facts/0/grants/0/spellIds/0',
          _spellKey('test_j'),
        ),
      ]);
    });
  });
}
