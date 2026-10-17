import 'package:srd5e/src/content/adapters/json_content_set_decoder.dart';
import 'package:srd5e/src/content/application/content_decode_result.dart';
import 'package:srd5e/src/content/domain/classes/ability_requirement.dart';
import 'package:srd5e/src/content/domain/classes/armor_training_category.dart';
import 'package:srd5e/src/content/domain/classes/class_definition.dart';
import 'package:srd5e/src/content/domain/classes/class_spellcasting_trait.dart';
import 'package:srd5e/src/content/domain/classes/class_starting_equipment.dart';
import 'package:srd5e/src/content/domain/classes/column_value.dart';
import 'package:srd5e/src/content/domain/classes/feature_entry.dart';
import 'package:srd5e/src/content/domain/classes/feature_fact.dart';
import 'package:srd5e/src/content/domain/classes/feature_option.dart';
import 'package:srd5e/src/content/domain/classes/feature_table.dart';
import 'package:srd5e/src/content/domain/classes/multiclass_grants.dart';
import 'package:srd5e/src/content/domain/classes/progression_row.dart';
import 'package:srd5e/src/content/domain/classes/skill_choice.dart';
import 'package:srd5e/src/content/domain/classes/weapon_proficiency.dart';
import 'package:srd5e/src/content/domain/content_id.dart';
import 'package:srd5e/src/content/domain/content_problem_kind.dart';
import 'package:srd5e/src/content/domain/content_text_block.dart';
import 'package:srd5e/src/content/domain/duration_unit.dart';
import 'package:srd5e/src/content/domain/feat_category.dart';
import 'package:srd5e/src/content/domain/hit_point_die.dart';
import 'package:srd5e/src/content/domain/named_text.dart';
import 'package:srd5e/src/content/domain/prerequisite.dart';
import 'package:srd5e/src/content/domain/skill.dart';
import 'package:srd5e/src/content/domain/source_citation.dart';
import 'package:srd5e/src/content/domain/spells/spell.dart';
import 'package:srd5e/src/content/domain/spells/spell_casting_time.dart';
import 'package:srd5e/src/content/domain/spells/spell_components.dart';
import 'package:srd5e/src/content/domain/spells/spell_duration.dart';
import 'package:srd5e/src/content/domain/spells/spell_level.dart';
import 'package:srd5e/src/content/domain/spells/spell_range.dart';
import 'package:srd5e/src/content/domain/spells/spell_school.dart';
import 'package:srd5e/src/content/domain/tool_proficiency.dart';
import 'package:srd5e/src/content/domain/typed_id.dart';
import 'package:srd5e/src/content/domain/typed_ids.dart';
import 'package:srd5e/src/shared_kernel/ability/ability.dart';
import 'package:test/test.dart';

import 'document_fixtures.dart';

/// The agreement test of `doc/specs/content-schema-and-decoder.md` FR-094:
/// every invalid value of the case tables is fed to the decoder (the
/// stated problem), to the matching constructor (`ArgumentError`) and to
/// `tryCreate` where one exists (rejection), and every valid value to all
/// of them (acceptance), so a rule changed in one place fails. Where a
/// case-table row's value is unrepresentable by the type, the row pins
/// that instead (a closed enum's `fromJson` is null, a factory has no
/// such parameter).
void main() {
  runSchemaRows();
  runClassRows();
  runSpellRows();
}

const decoder = JsonContentSetDecoder();

void expectProblems(
  ContentDecodeResult result,
  List<(String, ContentProblemKind)> expected,
) {
  expect(result, isA<ContentDecodeFailed>());
  final failed = result as ContentDecodeFailed;
  expect([
    for (final problem in failed.problems) (problem.path, problem.kind),
  ], expected);
}

void expectDecoded(ContentDecodeResult result, int entryCount) {
  expect(result, isA<ContentDecoded>());
  expect((result as ContentDecoded).contentSet.entries, hasLength(entryCount));
}

/// One agreement row: the document text, the decoder's verdict, and the
/// constructor/`tryCreate` verdict over the same value.
final class Agreement {
  Agreement(this.label, this.document, this.problems, this.constructor);

  final String label;
  final String document;

  /// The decoder's problems, or null when the document decodes.
  final List<(String, ContentProblemKind)>? problems;

  /// The constructor/`tryCreate` verdict over the same value: throws a
  /// test failure when it disagrees with the decoder.
  final void Function() constructor;

  String get path => problems == null ? 'happy' : 'unhappy';
}

void runRows(String group, List<Agreement> rows) {
  /// Requirement: per case - doc/specs/content-schema-and-decoder.md
  ///   FR-094 - the decoder, the matching constructor and `tryCreate`
  ///   agree on every case-table value ($group).
  /// Path: per case
  for (final row in rows) {
    test('$group: ${row.label} [${row.path}]', () {
      final result = decoder.decode(row.document);
      if (row.problems == null) {
        expectDecoded(result, 1);
      } else {
        expectProblems(result, row.problems!);
      }
      row.constructor();
    });
  }
}

// -- shared constructor-side builders ----------------------------------------

/// The three feature entries of the class fixture, as domain values.
List<FeatureEntry> validFeatures() => [
  FeatureEntry(
    id: FeatureId('barbarian_rage'),
    name: 'Rage',
    level: 1,
    text: 'In battle, you fight with primal ferocity.',
  ),
  FeatureEntry(
    id: FeatureId('barbarian_subclass'),
    name: 'Subclass',
    level: 3,
    text: 'You choose a subclass.',
    facts: [const GrantsSubclass()],
  ),
  FeatureEntry(
    id: FeatureId('barbarian_ability_score_improvement'),
    name: 'Ability Score Improvement',
    level: 4,
    text: 'You gain the Ability Score Improvement feat.',
    facts: [const GrantsFeat(FeatCategory.general)],
  ),
];

/// The twenty rows of the class fixture, with [rowSpellcasting] as each
/// row's spellcasting part.
List<ProgressionRow> validProgression({
  SpellcastingRow? Function(int level)? rowSpellcasting,
}) => [
  for (var level = 1; level <= 20; level++)
    ProgressionRow(
      level: level,
      proficiencyBonus: fixtureProficiencyBonus(level),
      features: [
        if (level == 1) RowClassFeature(FeatureId('barbarian_rage')),
        if (level == 3) ...[
          RowClassFeature(FeatureId('barbarian_subclass')),
          const RowSubclassFeature(),
        ],
        if (level == 4 || level == 8 || level == 12 || level == 16)
          RowClassFeature(FeatureId('barbarian_ability_score_improvement')),
      ],
      spellcasting: rowSpellcasting?.call(level),
      values: const {},
    ),
];

/// The class fixture as a domain value, with the caster's spellcasting
/// trait and row parts when given.
ClassDefinition validClass({
  ClassSpellcastingTrait? spellcasting,
  SpellcastingRow? Function(int level)? rowSpellcasting,
  List<FeatureEntry>? features,
  MulticlassGrants? multiclassGrants,
  List<ArmorTrainingCategory> armorTraining = const [],
  SkillChoice? skillChoice,
}) => ClassDefinition(
  id: ClassId('barbarian'),
  name: 'Barbarian',
  primaryAbility: AllOf([Ability.strength]),
  hitPointDie: HitPointDie.d12,
  savingThrowProficiencies: [Ability.strength, Ability.constitution],
  skillChoice:
      skillChoice ??
      SkillChoiceListed(2, [
        Skill.animalHandling,
        Skill.athletics,
        Skill.intimidation,
        Skill.nature,
        Skill.perception,
        Skill.survival,
      ]),
  weaponProficiencies: [
    WeaponProficiency(WeaponTrainingCategory.simple),
    WeaponProficiency(WeaponTrainingCategory.martial),
  ],
  toolProficiencies: const [],
  armorTraining: armorTraining,
  startingEquipment: ClassStartingEquipment(
    a: ClassEquipmentOption([ClassEquipmentItem('Greataxe', 1)], 0),
    b: ClassEquipmentOption(const [], 50),
  ),
  multiclassGrants: multiclassGrants ?? MulticlassGrants(),
  spellcasting: spellcasting,
  columns: const [],
  progression: validProgression(rowSpellcasting: rowSpellcasting),
  features: features ?? validFeatures(),
  subclasses: const [],
);

/// A minimal valid spell as a domain value.
Spell minimalSpell({List<ContentTextBlock>? higherLevel}) => Spell(
  id: SpellId('acid_arrow'),
  name: 'Acid Arrow',
  level: SpellLevel(2),
  school: SpellSchool.evocation,
  classes: {ClassId('wizard')},
  castingTimes: SpellCastingTimesSingle(CastingTime.magicAction()),
  ritual: false,
  range: SpellRange.distance(90, DistanceUnit.feet),
  components: SpellComponents(
    verbal: true,
    somatic: true,
    material: MaterialComponent(
      'A pinch of powder.',
      const [],
      consumesMaterial: false,
    ),
  ),
  duration: SpellDuration.instantaneous(),
  description: [ContentTextBlock.paragraph('A spell description paragraph.')],
  higherLevel: higherLevel,
);

// -- the schema spec's case tables -------------------------------------------

void runSchemaRows() {
  Map<String, Object?> backgroundWithSource(Map<String, Object?> source) =>
      backgroundEntry(instead: {'source': source});

  final rows = [
    // `source` accepted (schema FR-034, FR-115).
    Agreement(
      'source accepted',
      documentOf(
        'backgrounds',
        backgroundWithSource({
          'document': 'SRD 5.2.1',
          'section': 'Damage Rolls',
          'page': 16,
        }),
      ),
      null,
      () {
        final citation = SourceCitation(
          document: 'SRD 5.2.1',
          section: 'Damage Rolls',
          page: 16,
        );
        expect(citation.page, 16);
        expect(
          SourceCitation.tryCreate(
            document: 'SRD 5.2.1',
            section: 'Damage Rolls',
            page: 16,
          ),
          isA<SourceCitationParsed>(),
        );
      },
    ),
    Agreement(
      'source page one',
      documentOf(
        'backgrounds',
        backgroundWithSource({'document': 'd', 'section': 's', 'page': 1}),
      ),
      null,
      () {
        expect(
          SourceCitation.tryCreate(
            document: 'd',
            section: 's',
            page: SourceCitation.minPage,
          ),
          isA<SourceCitationParsed>(),
        );
      },
    ),
    // `source` rejected; the constructor throws for page 0 and the blank
    // parts (a missing section has no constructor input).
    Agreement(
      'source page zero',
      documentOf(
        'backgrounds',
        backgroundWithSource({'document': 'd', 'section': 's', 'page': 0}),
      ),
      [('/backgrounds/0/source/page', ContentProblemKind.outOfRange)],
      () {
        expect(
          () => SourceCitation(document: 'd', section: 's', page: 0),
          throwsArgumentError,
        );
        final parsed = SourceCitation.tryCreate(
          document: 'd',
          section: 's',
          page: 0,
        );
        expect(parsed, isA<SourceCitationRejected>());
        expect(
          (parsed as SourceCitationRejected).problem,
          SourceCitationProblem.pageBelowMinimum,
        );
      },
    ),
    Agreement(
      'source section missing',
      documentOf(
        'backgrounds',
        backgroundWithSource({'document': 'd', 'page': 1}),
      ),
      [('/backgrounds/0/source/section', ContentProblemKind.missingField)],
      () {
        final parsed = SourceCitation.tryCreate(
          document: 'd',
          section: '  ',
          page: 1,
        );
        expect(parsed, isA<SourceCitationRejected>());
        expect(
          (parsed as SourceCitationRejected).problem,
          SourceCitationProblem.blankSection,
        );
      },
    ),
    Agreement(
      'source section blank',
      documentOf(
        'backgrounds',
        backgroundWithSource({'document': 'd', 'section': '  ', 'page': 1}),
      ),
      [('/backgrounds/0/source/section', ContentProblemKind.invalidValue)],
      () {
        expect(
          () => SourceCitation(document: 'd', section: '  ', page: 1),
          throwsArgumentError,
        );
      },
    ),
    Agreement(
      'source document blank',
      documentOf(
        'backgrounds',
        backgroundWithSource({'document': '  ', 'section': 's', 'page': 1}),
      ),
      [('/backgrounds/0/source/document', ContentProblemKind.invalidValue)],
      () {
        expect(
          () => SourceCitation(document: '  ', section: 's', page: 1),
          throwsArgumentError,
        );
        final parsed = SourceCitation.tryCreate(
          document: ' ',
          section: 's',
          page: 1,
        );
        expect(
          (parsed as SourceCitationRejected).problem,
          SourceCitationProblem.blankDocument,
          reason: 'the first failing check wins',
        );
      },
    ),
    // Level and ability-score prerequisites (schema FR-118).
    Agreement(
      'level prerequisite accepted',
      documentOf(
        'feats',
        featEntry(
          instead: {
            'category': 'General',
            'prerequisites': [
              {'kind': 'level', 'minimum': 4},
            ],
          },
        ),
      ),
      null,
      () {
        expect(LevelPrerequisite(4).minimum, 4);
      },
    ),
    Agreement(
      'level prerequisite minimum zero',
      documentOf(
        'feats',
        featEntry(
          instead: {
            'prerequisites': [
              {'kind': 'level', 'minimum': 0},
            ],
          },
        ),
      ),
      [('/feats/0/prerequisites/0/minimum', ContentProblemKind.outOfRange)],
      () {
        expect(() => LevelPrerequisite(0), throwsArgumentError);
      },
    ),
    Agreement(
      'ability prerequisite accepted',
      documentOf(
        'feats',
        featEntry(
          instead: {
            'category': 'General',
            'prerequisites': [
              {
                'kind': 'abilityScore',
                'abilities': ['Strength', 'Dexterity'],
                'minimum': 13,
              },
            ],
          },
        ),
      ),
      null,
      () {
        final clause = AbilityScorePrerequisite({
          Ability.strength,
          Ability.dexterity,
        }, 13);
        expect(clause.minimum, 13);
      },
    ),
    Agreement(
      'ability prerequisite empty',
      documentOf(
        'feats',
        featEntry(
          instead: {
            'prerequisites': [
              {'kind': 'abilityScore', 'abilities': <String>[], 'minimum': 13},
            ],
          },
        ),
      ),
      [('/feats/0/prerequisites/0/abilities', ContentProblemKind.outOfRange)],
      () {
        expect(
          () => AbilityScorePrerequisite(const {}, 13),
          throwsArgumentError,
        );
      },
    ),
    Agreement(
      'ability prerequisite repeated',
      documentOf(
        'feats',
        featEntry(
          instead: {
            'prerequisites': [
              {
                'kind': 'abilityScore',
                'abilities': ['Strength', 'Strength'],
                'minimum': 13,
              },
            ],
          },
        ),
      ),
      [('/feats/0/prerequisites/0/abilities/1', ContentProblemKind.duplicate)],
      () {
        // Unrepresentable: the clause holds a Set, which cannot hold the
        // repeat the wire carries.
        // Unrepresentable: the clause holds a Set, so the wire's repeated
        // Strength collapses before the constructor sees it.
        final clause = AbilityScorePrerequisite(const {Ability.strength}, 13);
        expect(clause.abilities, hasLength(1));
      },
    ),
    Agreement(
      'unknown prerequisite kind',
      documentOf(
        'feats',
        featEntry(
          instead: {
            'prerequisites': [
              {'kind': 'skill', 'name': 'x'},
            ],
          },
        ),
      ),
      [('/feats/0/prerequisites/0/kind', ContentProblemKind.invalidValue)],
      () {
        // Unrepresentable: the sealed family has three clauses.
        expect(LevelPrerequisite(1).minimum, 1);
      },
    ),
    // Tool proficiencies (schema FR-119).
    Agreement(
      'specific tool accepted',
      documentOf(
        'backgrounds',
        backgroundEntry(
          instead: {
            'toolProficiency': {'kind': 'specific', 'name': 'Gaming Set'},
          },
        ),
      ),
      null,
      () {
        expect(SpecificToolProficiency('Gaming Set').name, 'Gaming Set');
      },
    ),
    Agreement(
      'choice tool accepted',
      documentOf(
        'backgrounds',
        backgroundEntry(
          instead: {
            'toolProficiency': {'kind': 'choice', 'category': 'Gaming Set'},
          },
        ),
      ),
      null,
      () {
        expect(ChoiceToolProficiency('Gaming Set').category, 'Gaming Set');
      },
    ),
    Agreement(
      'unknown tool kind',
      documentOf(
        'backgrounds',
        backgroundEntry(
          instead: {
            'toolProficiency': {'kind': 'any', 'name': 'x'},
          },
        ),
      ),
      [
        (
          '/backgrounds/0/toolProficiency/kind',
          ContentProblemKind.invalidValue,
        ),
      ],
      () {
        // Unrepresentable: the sealed family has two kinds.
        expect(SpecificToolProficiency('x').name, 'x');
      },
    ),
    // Named text (schema FR-116, FR-027, FR-028).
    Agreement(
      'named text blank',
      documentOf(
        'species',
        speciesEntry(
          instead: {
            'traits': [
              {'name': 'x', 'text': ' '},
            ],
          },
        ),
      ),
      [('/species/0/traits/0/text', ContentProblemKind.invalidValue)],
      () {
        expect(() => NamedText('x', ' '), throwsArgumentError);
      },
    ),
    // Hit Point Die (schema FR-132).
    Agreement(
      'hit point die D12',
      documentOf('classes', classEntry(instead: const {'hitPointDie': 'D12'})),
      null,
      () {
        expect(HitPointDie.fromJson('D12')?.faces, 12);
      },
    ),
    Agreement(
      'hit point die d8',
      documentOf('classes', classEntry(instead: const {'hitPointDie': 'd8'})),
      [('/classes/0/hitPointDie', ContentProblemKind.invalidValue)],
      () {
        expect(HitPointDie.fromJson('d8'), isNull);
      },
    ),
    // Duration unit (schema FR-149).
    Agreement(
      'duration unit days',
      documentOf(
        'spells',
        spellEntry(
          instead: {
            'duration': {
              'kind': 'timed',
              'amount': 30,
              'unit': 'days',
              'limit': 'fixed',
            },
          },
        ),
      ),
      null,
      () {
        expect(DurationUnit.fromJson('days'), DurationUnit.days);
      },
    ),
    Agreement(
      'duration unit years',
      documentOf(
        'spells',
        spellEntry(
          instead: {
            'duration': {
              'kind': 'timed',
              'amount': 1,
              'unit': 'years',
              'limit': 'fixed',
            },
          },
        ),
      ),
      [('/spells/0/duration/unit', ContentProblemKind.invalidValue)],
      () {
        expect(DurationUnit.fromJson('years'), isNull);
      },
    ),
    // Ids (schema FR-030, FR-143, FR-144, FR-114).
    Agreement(
      'id accepted',
      documentOf('feats', featEntry(instead: const {'id': 'acid_arrow_2'})),
      null,
      () {
        expect(ContentId.tryCreate('acid_arrow_2'), isA<ContentIdParsed>());
        expect(
          SpellId.tryCreate('acid_arrow_2'),
          isA<TypedIdParsed<SpellId>>(),
        );
        expect(
          ClassId.tryCreate('acid_arrow_2'),
          isA<TypedIdParsed<ClassId>>(),
        );
      },
    ),
    Agreement(
      'id with a hyphen',
      documentOf('feats', featEntry(instead: const {'id': 'acid-arrow'})),
      [('/feats/0/id', ContentProblemKind.invalidValue)],
      () {
        expect(ContentId.tryCreate('acid-arrow'), isA<ContentIdRejected>());
        expect(
          SpellId.tryCreate('acid-arrow'),
          isA<TypedIdRejected<SpellId>>(),
        );
      },
    ),
    Agreement(
      'id too long',
      documentOf('feats', featEntry(instead: {'id': 'a${'b' * 64}'})),
      [('/feats/0/id', ContentProblemKind.invalidValue)],
      () {
        final parsed = ContentId.tryCreate('a${'b' * 64}');
        expect(parsed, isA<ContentIdRejected>());
        expect(
          (parsed as ContentIdRejected).problem,
          ContentIdProblem.tooLong,
          reason: 'length takes precedence over the format',
        );
      },
    ),
  ];
  runRows('schema rows', rows);
}

// -- the classes spec's case tables (decode and constructor halves) ----------

void runClassRows() {
  /// A class whose extra feature entry [feature] is cited by the row at
  /// its own level.
  Map<String, Object?> classWithExtraFeature(Map<String, Object?> feature) {
    final id = feature['id'] as String;
    return classEntry(
      instead: {
        'features': [...(classEntry()['features']! as List<Object?>), feature],
        'progression': [
          for (var level = 1; level <= 20; level++)
            {
              'level': level,
              'proficiencyBonus': fixtureProficiencyBonus(level),
              'features': [
                ...fixtureRowFeatures(level, 'barbarian_'),
                if (level == feature['level']) {'featureId': id},
              ],
              'values': <String, Object?>{},
            },
        ],
      },
    );
  }

  Map<String, Object?> classWithOptions(List<Object?> options) =>
      classWithExtraFeature({
        'id': 'barbarian_options',
        'name': 'Feature Options',
        'level': 2,
        'text': 'You gain options.',
        'options': options,
      });

  Map<String, Object?> classWithFacts(List<Object?> facts) =>
      classWithExtraFeature({
        'id': 'barbarian_factful',
        'name': 'Factful Feature',
        'level': 2,
        'text': 'You gain facts.',
        'facts': facts,
      });

  Map<String, Object?> classWithTable(Map<String, Object?> table) =>
      classWithExtraFeature({
        'id': 'barbarian_tabular',
        'name': 'Tabular Feature',
        'level': 2,
        'text': 'You gain a table.',
        'tables': [table],
      });

  FeatureOption optionOf(Map<String, Object?> option) => FeatureOption(
    id: FeatureOptionId(option['id'] as String),
    name: option['name'] as String,
    text: option['text'] as String,
    pointCost: option['pointCost'] as int?,
    repeatable: option['repeatable'] as bool? ?? false,
  );

  final rows = [
    // Cases FT: facts (content-classes.md FR-055 to FR-058, FR-064).
    Agreement(
      'no subclass fact',
      documentOf(
        'classes',
        classEntry(
          instead: {
            'features': [
              {
                'id': 'barbarian_rage',
                'name': 'Rage',
                'level': 1,
                'text': 'In battle, you fight with primal ferocity.',
              },
              {
                // The subclass feature without its GrantsSubclass fact: the
                // row at level 3 still cites it (FR-045).
                'id': 'barbarian_subclass',
                'name': 'Subclass',
                'level': 3,
                'text': 'You choose a subclass.',
              },
              {
                'id': 'barbarian_ability_score_improvement',
                'name': 'Ability Score Improvement',
                'level': 4,
                'text': 'You gain the Ability Score Improvement feat.',
                'facts': [
                  {'kind': 'grantsFeat', 'category': 'General'},
                ],
              },
            ],
          },
        ),
      ),
      [('/classes/0/features', ContentProblemKind.constraintViolation)],
      () {
        expect(
          () => validClass(
            features: [
              FeatureEntry(
                id: FeatureId('barbarian_rage'),
                name: 'Rage',
                level: 1,
                text: 'In battle, you fight with primal ferocity.',
              ),
              FeatureEntry(
                id: FeatureId('barbarian_subclass'),
                name: 'Subclass',
                level: 3,
                text: 'You choose a subclass.',
              ),
              FeatureEntry(
                id: FeatureId('barbarian_ability_score_improvement'),
                name: 'Ability Score Improvement',
                level: 4,
                text: 'You gain the Ability Score Improvement feat.',
                facts: [const GrantsFeat(FeatCategory.general)],
              ),
            ],
          ),
          throwsArgumentError,
        );
      },
    ),
    Agreement(
      'two subclass facts',
      documentOf(
        'classes',
        classEntry(
          instead: {
            'features': [
              ...(classEntry()['features']! as List<Object?>),
              {
                'id': 'barbarian_subclass_2',
                'name': 'Second Subclass',
                'level': 3,
                'text': 'You choose a second subclass.',
                'facts': [
                  {'kind': 'grantsSubclass'},
                ],
              },
            ],
            'progression': [
              for (var level = 1; level <= 20; level++)
                {
                  'level': level,
                  'proficiencyBonus': fixtureProficiencyBonus(level),
                  'features': [
                    ...fixtureRowFeatures(level, 'barbarian_'),
                    if (level == 3) {'featureId': 'barbarian_subclass_2'},
                  ],
                  'values': <String, Object?>{},
                },
            ],
          },
        ),
      ),
      [('/classes/0/features', ContentProblemKind.constraintViolation)],
      () {
        expect(
          () => validClass(
            features: [
              ...validFeatures(),
              FeatureEntry(
                id: FeatureId('barbarian_subclass_2'),
                name: 'Second Subclass',
                level: 3,
                text: 'You choose a second subclass.',
                facts: const [GrantsSubclass()],
              ),
            ],
          ),
          throwsArgumentError,
        );
      },
    ),
    Agreement(
      'unknown category',
      documentOf(
        'classes',
        classWithFacts([
          {'kind': 'grantsFeat', 'category': 'Epic'},
        ]),
      ),
      [
        (
          '/classes/0/features/3/facts/0/category',
          ContentProblemKind.invalidValue,
        ),
      ],
      () {
        // Unrepresentable: a closed enum.
        expect(FeatCategory.fromJson('Epic'), isNull);
      },
    ),
    Agreement(
      'grants out of order',
      documentOf(
        'classes',
        classWithFacts([
          {
            'kind': 'alwaysPreparedSpells',
            'grants': [
              {
                'level': 5,
                'spellIds': ['one_spell'],
              },
              {
                'level': 3,
                'spellIds': ['another_spell'],
              },
            ],
          },
        ]),
      ),
      [
        (
          '/classes/0/features/3/facts/0/grants/1/level',
          ContentProblemKind.invalidValue,
        ),
      ],
      () {
        expect(
          () => AlwaysPreparedSpells([
            SpellGrant(5, [SpellId('one_spell')]),
            SpellGrant(3, [SpellId('another_spell')]),
          ]),
          throwsArgumentError,
        );
      },
    ),
    Agreement(
      'grant below entry',
      documentOf(
        'classes',
        classWithFacts([
          {
            'kind': 'alwaysPreparedSpells',
            'grants': [
              {
                'level': 1,
                'spellIds': ['one_spell'],
              },
            ],
          },
        ]),
      ),
      [
        (
          '/classes/0/features/3/facts/0/grants/0/level',
          ContentProblemKind.invalidValue,
        ),
      ],
      () {
        expect(
          () => FeatureEntry(
            id: FeatureId('barbarian_factful'),
            name: 'Factful Feature',
            level: 2,
            text: 'You gain facts.',
            facts: [
              AlwaysPreparedSpells([
                SpellGrant(1, [SpellId('one_spell')]),
              ]),
            ],
          ),
          throwsArgumentError,
        );
      },
    ),
    Agreement(
      'empty spell ids',
      documentOf(
        'classes',
        classWithFacts([
          {
            'kind': 'alwaysPreparedSpells',
            'grants': [
              {'level': 2, 'spellIds': <String>[]},
            ],
          },
        ]),
      ),
      [
        (
          '/classes/0/features/3/facts/0/grants/0/spellIds',
          ContentProblemKind.outOfRange,
        ),
      ],
      () {
        expect(() => SpellGrant(2, const []), throwsArgumentError);
      },
    ),
    Agreement(
      'subclass fact on option',
      documentOf(
        'classes',
        classWithOptions([
          {
            'id': 'an_option',
            'name': 'An Option',
            'text': 'You gain the option.',
            'facts': [
              {'kind': 'grantsSubclass'},
            ],
          },
        ]),
      ),
      [
        (
          '/classes/0/features/3/options/0/facts/0',
          ContentProblemKind.constraintViolation,
        ),
      ],
      () {
        expect(
          () => FeatureOption(
            id: FeatureOptionId('an_option'),
            name: 'An Option',
            text: 'You gain the option.',
            facts: const [GrantsSubclass()],
          ),
          throwsArgumentError,
        );
      },
    ),
    // Cases FT: options (FR-061 to FR-063).
    Agreement(
      'duplicate option id',
      documentOf(
        'classes',
        classWithOptions([
          {
            'id': 'an_option',
            'name': 'An Option',
            'text': 'You gain the option.',
          },
          {
            'id': 'an_option',
            'name': 'Another Option',
            'text': 'You gain it too.',
          },
        ]),
      ),
      [('/classes/0/features/3/options/1/id', ContentProblemKind.duplicate)],
      () {
        expect(
          () => FeatureEntry(
            id: FeatureId('barbarian_options'),
            name: 'Feature Options',
            level: 2,
            text: 'You gain options.',
            options: [
              optionOf({
                'id': 'an_option',
                'name': 'An Option',
                'text': 'You gain the option.',
              }),
              optionOf({
                'id': 'an_option',
                'name': 'Another Option',
                'text': 'You gain it too.',
              }),
            ],
          ),
          throwsArgumentError,
        );
      },
    ),
    Agreement(
      'empty prerequisite',
      documentOf(
        'classes',
        classWithOptions([
          {
            'id': 'an_option',
            'name': 'An Option',
            'text': 'You gain the option.',
            'prerequisite': <String, Object?>{},
          },
        ]),
      ),
      [
        (
          '/classes/0/features/3/options/0/prerequisite',
          ContentProblemKind.constraintViolation,
        ),
      ],
      () {
        expect(() => OptionPrerequisite(), throwsArgumentError);
      },
    ),
    Agreement(
      'prerequisite on a missing option',
      documentOf(
        'classes',
        classWithOptions([
          {
            'id': 'an_option',
            'name': 'An Option',
            'text': 'You gain the option.',
            'prerequisite': {
              'requiresOptionIds': ['no_such_option'],
            },
          },
        ]),
      ),
      [
        (
          '/classes/0/features/3/options/0/prerequisite/requiresOptionIds/0',
          ContentProblemKind.unresolvedReference,
        ),
      ],
      () {
        expect(
          () => FeatureEntry(
            id: FeatureId('barbarian_options'),
            name: 'Feature Options',
            level: 2,
            text: 'You gain options.',
            options: [
              FeatureOption(
                id: FeatureOptionId('an_option'),
                name: 'An Option',
                text: 'You gain the option.',
                prerequisite: OptionPrerequisite(
                  requiresOptionIds: [FeatureOptionId('no_such_option')],
                ),
              ),
            ],
          ),
          throwsArgumentError,
        );
      },
    ),
    Agreement(
      'self prerequisite',
      documentOf(
        'classes',
        classWithOptions([
          {
            'id': 'an_option',
            'name': 'An Option',
            'text': 'You gain the option.',
            'prerequisite': {
              'requiresOptionIds': ['an_option'],
            },
          },
        ]),
      ),
      [
        (
          '/classes/0/features/3/options/0/prerequisite/requiresOptionIds/0',
          ContentProblemKind.constraintViolation,
        ),
      ],
      () {
        expect(
          () => FeatureEntry(
            id: FeatureId('barbarian_options'),
            name: 'Feature Options',
            level: 2,
            text: 'You gain options.',
            options: [
              FeatureOption(
                id: FeatureOptionId('an_option'),
                name: 'An Option',
                text: 'You gain the option.',
                prerequisite: OptionPrerequisite(
                  requiresOptionIds: [FeatureOptionId('an_option')],
                ),
              ),
            ],
          ),
          throwsArgumentError,
        );
      },
    ),
    Agreement(
      'prerequisite cycle',
      documentOf(
        'classes',
        classWithOptions([
          {
            'id': 'first_option',
            'name': 'First Option',
            'text': 'You gain the first option.',
            'prerequisite': {
              'requiresOptionIds': ['second_option'],
            },
          },
          {
            'id': 'second_option',
            'name': 'Second Option',
            'text': 'You gain the second option.',
            'prerequisite': {
              'requiresOptionIds': ['first_option'],
            },
          },
        ]),
      ),
      [
        (
          '/classes/0/features/3/options/1/prerequisite/requiresOptionIds/0',
          ContentProblemKind.constraintViolation,
        ),
      ],
      () {
        expect(
          () => FeatureEntry(
            id: FeatureId('barbarian_options'),
            name: 'Feature Options',
            level: 2,
            text: 'You gain options.',
            options: [
              FeatureOption(
                id: FeatureOptionId('first_option'),
                name: 'First Option',
                text: 'You gain the first option.',
                prerequisite: OptionPrerequisite(
                  requiresOptionIds: [FeatureOptionId('second_option')],
                ),
              ),
              FeatureOption(
                id: FeatureOptionId('second_option'),
                name: 'Second Option',
                text: 'You gain the second option.',
                prerequisite: OptionPrerequisite(
                  requiresOptionIds: [FeatureOptionId('first_option')],
                ),
              ),
            ],
          ),
          throwsArgumentError,
        );
      },
    ),
    Agreement(
      'zero point cost',
      documentOf(
        'classes',
        classWithOptions([
          {
            'id': 'an_option',
            'name': 'An Option',
            'text': 'You gain the option.',
            'pointCost': 0,
          },
        ]),
      ),
      [
        (
          '/classes/0/features/3/options/0/pointCost',
          ContentProblemKind.outOfRange,
        ),
      ],
      () {
        expect(
          () => FeatureOption(
            id: FeatureOptionId('an_option'),
            name: 'An Option',
            text: 'You gain the option.',
            pointCost: 0,
          ),
          throwsArgumentError,
        );
        expect(FeatureOption.isValidPointCost(0), isFalse);
      },
    ),
    Agreement(
      'false repeatable',
      documentOf(
        'classes',
        classWithOptions([
          {
            'id': 'an_option',
            'name': 'An Option',
            'text': 'You gain the option.',
            'repeatable': false,
          },
        ]),
      ),
      [
        (
          '/classes/0/features/3/options/0/repeatable',
          ContentProblemKind.invalidValue,
        ),
      ],
      () {
        // The "present must be true" wire rule exists once, in the
        // decoder: the domain type models "Repeatable printed" as true and
        // absence as false, so `repeatable: false` is the absent state
        // (content-classes.md FR-063).
        expect(
          FeatureOption(
            id: FeatureOptionId('an_option'),
            name: 'An Option',
            text: 'You gain the option.',
            repeatable: false,
          ).repeatable,
          isFalse,
        );
      },
    ),
    // Cases FT: tables (FR-066).
    Agreement(
      'ragged table',
      documentOf(
        'classes',
        classWithTable({
          'name': 'A Table',
          'columns': ['One', 'Two'],
          'rows': [
            ['a', 'b'],
            ['c'],
          ],
        }),
      ),
      [
        (
          '/classes/0/features/3/tables/0/rows/1',
          ContentProblemKind.outOfRange,
        ),
      ],
      () {
        expect(
          () => FeatureTable(
            name: 'A Table',
            columns: ['One', 'Two'],
            rows: [
              [TableCellText('a'), TableCellText('b')],
              [TableCellText('c')],
            ],
          ),
          throwsArgumentError,
        );
      },
    ),
    Agreement(
      'mixed column',
      documentOf(
        'classes',
        classWithTable({
          'name': 'A Table',
          'columns': ['One', 'Two'],
          'rows': [
            ['a', 1],
            ['c', 'd'],
          ],
        }),
      ),
      [
        (
          '/classes/0/features/3/tables/0/rows/1/1',
          ContentProblemKind.wrongType,
        ),
      ],
      () {
        expect(
          () => FeatureTable(
            name: 'A Table',
            columns: ['One', 'Two'],
            rows: [
              [TableCellText('a'), const TableCellInt(1)],
              [TableCellText('c'), TableCellText('d')],
            ],
          ),
          throwsArgumentError,
        );
      },
    ),
    Agreement(
      'table with no rows',
      documentOf(
        'classes',
        classWithTable({
          'name': 'A Table',
          'columns': ['One'],
          'rows': <Object?>[],
        }),
      ),
      [('/classes/0/features/3/tables/0/rows', ContentProblemKind.outOfRange)],
      () {
        expect(
          () => FeatureTable(name: 'A Table', columns: ['One'], rows: []),
          throwsArgumentError,
        );
      },
    ),
    // Cases FT: equipment (FR-024).
    Agreement(
      'option C accepted',
      documentOf(
        'classes',
        classEntry(
          instead: {
            'startingEquipment': {
              'A': {
                'items': [
                  {'name': 'Greataxe', 'quantity': 1},
                ],
                'gold': 0,
              },
              'B': {'items': <Object?>[], 'gold': 50},
              'C': {'items': <Object?>[], 'gold': 75},
            },
          },
        ),
      ),
      null,
      () {
        final equipment = ClassStartingEquipment(
          a: ClassEquipmentOption(const [], 0),
          b: ClassEquipmentOption(const [], 50),
          c: ClassEquipmentOption(const [], 75),
        );
        expect(equipment.c?.gold, 75);
      },
    ),
    Agreement(
      'option D',
      documentOf(
        'classes',
        classEntry(
          instead: {
            'startingEquipment': {
              'A': {'items': <Object?>[], 'gold': 0},
              'B': {'items': <Object?>[], 'gold': 50},
              'D': {'items': <Object?>[], 'gold': 75},
            },
          },
        ),
      ),
      [('/classes/0/startingEquipment/D', ContentProblemKind.unknownField)],
      () {
        // Unrepresentable: the composite holds a, b and the optional c.
        expect(
          ClassStartingEquipment(
            a: ClassEquipmentOption(const [], 0),
            b: ClassEquipmentOption(const [], 50),
          ).c,
          isNull,
        );
      },
    ),
    Agreement(
      'missing B',
      documentOf(
        'classes',
        classEntry(
          instead: {
            'startingEquipment': {
              'A': {'items': <Object?>[], 'gold': 0},
            },
          },
        ),
      ),
      [('/classes/0/startingEquipment/B', ContentProblemKind.missingField)],
      () {
        // Unrepresentable: both options are required parameters.
        expect(ClassEquipmentOption.isValidGold(50), isTrue);
      },
    ),
    Agreement(
      'quantity zero',
      documentOf(
        'classes',
        classEntry(
          instead: {
            'startingEquipment': {
              'A': {
                'items': [
                  {'name': 'Greataxe', 'quantity': 0},
                ],
                'gold': 0,
              },
              'B': {'items': <Object?>[], 'gold': 50},
            },
          },
        ),
      ),
      [
        (
          '/classes/0/startingEquipment/A/items/0/quantity',
          ContentProblemKind.outOfRange,
        ),
      ],
      () {
        expect(() => ClassEquipmentItem('Greataxe', 0), throwsArgumentError);
        expect(ClassEquipmentItem.isValidQuantity(0), isFalse);
      },
    ),
    Agreement(
      'negative gold',
      documentOf(
        'classes',
        classEntry(
          instead: {
            'startingEquipment': {
              'A': {'items': <Object?>[], 'gold': -1},
              'B': {'items': <Object?>[], 'gold': 50},
            },
          },
        ),
      ),
      [('/classes/0/startingEquipment/A/gold', ContentProblemKind.outOfRange)],
      () {
        expect(() => ClassEquipmentOption(const [], -1), throwsArgumentError);
        expect(ClassEquipmentOption.isValidGold(-1), isFalse);
      },
    ),
    Agreement(
      'empty items accepted',
      documentOf(
        'classes',
        classEntry(
          instead: {
            'startingEquipment': {
              'A': {'items': <Object?>[], 'gold': 0},
              'B': {'items': <Object?>[], 'gold': 75},
            },
          },
        ),
      ),
      null,
      () {
        expect(ClassEquipmentOption(const [], 75).items, isEmpty);
      },
    ),
    // Cases FT: multiclass and primary ability (FR-026, FR-012, FR-013).
    Agreement(
      'multiclass exceeds core',
      documentOf(
        'classes',
        classEntry(
          instead: {
            'armorTraining': ['Light'],
            'multiclassGrants': {
              'weaponProficiencies': <Object?>[],
              'armorTraining': ['Heavy'],
              'toolProficiencies': <Object?>[],
            },
          },
        ),
      ),
      [
        (
          '/classes/0/multiclassGrants/armorTraining/0',
          ContentProblemKind.constraintViolation,
        ),
      ],
      () {
        expect(
          () => validClass(
            armorTraining: [ArmorTrainingCategory.light],
            multiclassGrants: MulticlassGrants(
              armorTraining: [ArmorTrainingCategory.heavy],
            ),
          ),
          throwsArgumentError,
        );
      },
    ),
    Agreement(
      'any-skill grant on a listed core',
      documentOf(
        'classes',
        classEntry(
          instead: {
            'multiclassGrants': {
              'weaponProficiencies': <Object?>[],
              'armorTraining': <Object?>[],
              'toolProficiencies': <Object?>[],
              'skillChoice': {
                'picks': 2,
                'options': {'kind': 'any'},
              },
            },
          },
        ),
      ),
      [
        (
          '/classes/0/multiclassGrants/skillChoice',
          ContentProblemKind.constraintViolation,
        ),
      ],
      () {
        expect(
          () => validClass(
            skillChoice: SkillChoiceListed(2, [Skill.athletics]),
            multiclassGrants: MulticlassGrants(skillChoice: SkillChoiceAny(2)),
          ),
          throwsArgumentError,
        );
      },
    ),
    Agreement(
      'primary ability repeated',
      documentOf(
        'classes',
        classEntry(
          instead: {
            'primaryAbility': {
              'kind': 'allOf',
              'abilities': ['Strength', 'Strength'],
            },
          },
        ),
      ),
      [('/classes/0/primaryAbility/abilities/1', ContentProblemKind.duplicate)],
      () {
        expect(
          () => AllOf([Ability.strength, Ability.strength]),
          throwsArgumentError,
        );
        expect(AllOf.isValid([Ability.strength, Ability.strength]), isFalse);
      },
    ),
    Agreement(
      'any-of of one',
      documentOf(
        'classes',
        classEntry(
          instead: {
            'primaryAbility': {
              'kind': 'anyOf',
              'abilities': ['Strength'],
            },
          },
        ),
      ),
      [('/classes/0/primaryAbility/abilities', ContentProblemKind.outOfRange)],
      () {
        expect(() => AnyOf([Ability.strength]), throwsArgumentError);
        expect(AnyOf.isValid([Ability.strength]), isFalse);
      },
    ),
    // Cases SP constructor halves (FR-030 to FR-032); the decode halves
    // are the classes test's.
    Agreement(
      'eight slots',
      documentOf(
        'classes',
        casterClassEntry(
          rowSpellcasting: (level) => level == 1
              ? {
                  'cantrips': 2,
                  'preparedSpells': 4,
                  'spellSlots': <int>[2, 0, 0, 0, 0, 0, 0, 0],
                }
              : null,
        ),
      ),
      [
        (
          '/classes/0/progression/0/spellcasting/spellSlots',
          ContentProblemKind.outOfRange,
        ),
      ],
      () {
        expect(
          () => SlotSpellcastingRow(
            cantrips: 2,
            preparedSpells: 4,
            spellSlots: [2, 0, 0, 0, 0, 0, 0, 0],
          ),
          throwsArgumentError,
        );
        expect(
          SlotSpellcastingRow.isValidSpellSlots([2, 0, 0, 0, 0, 0, 0, 0, 0]),
          isTrue,
        );
      },
    ),
    Agreement(
      'negative slot',
      documentOf(
        'classes',
        casterClassEntry(
          rowSpellcasting: (level) => level == 1
              ? {
                  'cantrips': 2,
                  'preparedSpells': 4,
                  'spellSlots': <int>[-1, 0, 0, 0, 0, 0, 0, 0, 0],
                }
              : null,
        ),
      ),
      [
        (
          '/classes/0/progression/0/spellcasting/spellSlots/0',
          ContentProblemKind.outOfRange,
        ),
      ],
      () {
        expect(
          SlotSpellcastingRow.isValidSpellSlots([-1, 0, 0, 0, 0, 0, 0, 0, 0]),
          isFalse,
        );
        expect(
          () => SlotSpellcastingRow(
            cantrips: 2,
            preparedSpells: 4,
            spellSlots: [-1, 0, 0, 0, 0, 0, 0, 0, 0],
          ),
          throwsArgumentError,
        );
      },
    ),
    Agreement(
      'cantrips missing',
      documentOf(
        'classes',
        casterClassEntry(
          rowSpellcasting: (level) => level == 1
              ? {
                  'preparedSpells': 4,
                  'spellSlots': <int>[2, 0, 0, 0, 0, 0, 0, 0, 0],
                }
              : null,
        ),
      ),
      [
        (
          '/classes/0/progression/0/spellcasting/cantrips',
          ContentProblemKind.missingField,
        ),
      ],
      () {
        // The cantrips-presence rule is the ClassDefinition constructor's
        // (the row type carries an optional count, FR-031).
        expect(
          () => validClass(
            spellcasting: const SlotSpellcastingTrait(
              Ability.charisma,
              cantrips: true,
            ),
            rowSpellcasting: (level) => level == 1
                ? SlotSpellcastingRow(
                    cantrips: null,
                    preparedSpells: 4,
                    spellSlots: [2, 0, 0, 0, 0, 0, 0, 0, 0],
                  )
                : SlotSpellcastingRow(
                    cantrips: 2,
                    preparedSpells: 4,
                    spellSlots: [2, 0, 0, 0, 0, 0, 0, 0, 0],
                  ),
          ),
          throwsArgumentError,
        );
      },
    ),
    Agreement(
      'cantrips on Paladin',
      documentOf(
        'classes',
        casterClassEntry(
          cantrips: false,
          rowSpellcasting: (level) => level == 1
              ? {
                  'cantrips': 2,
                  'preparedSpells': 4,
                  'spellSlots': <int>[2, 0, 0, 0, 0, 0, 0, 0, 0],
                }
              : null,
        ),
      ),
      [
        (
          '/classes/0/progression/0/spellcasting/cantrips',
          ContentProblemKind.constraintViolation,
        ),
      ],
      () {
        expect(
          () => validClass(
            spellcasting: const SlotSpellcastingTrait(
              Ability.charisma,
              cantrips: false,
            ),
            rowSpellcasting: (level) => SlotSpellcastingRow(
              cantrips: 2,
              preparedSpells: 4,
              spellSlots: [2, 0, 0, 0, 0, 0, 0, 0, 0],
            ),
          ),
          throwsArgumentError,
        );
      },
    ),
    Agreement(
      'pact row on slot class',
      documentOf(
        'classes',
        casterClassEntry(
          rowSpellcasting: (level) => level == 1
              ? {
                  'cantrips': 2,
                  'preparedSpells': 1,
                  'spellSlots': 2,
                  'slotLevel': 1,
                }
              : null,
        ),
      ),
      [
        (
          '/classes/0/progression/0/spellcasting',
          ContentProblemKind.constraintViolation,
        ),
      ],
      () {
        expect(
          () => validClass(
            spellcasting: const SlotSpellcastingTrait(
              Ability.charisma,
              cantrips: true,
            ),
            rowSpellcasting: (level) => PactSpellcastingRow(
              cantrips: 2,
              preparedSpells: 1,
              spellSlots: 2,
              slotLevel: 1,
            ),
          ),
          throwsArgumentError,
        );
      },
    ),
    Agreement(
      'row part on a non-caster',
      documentOf(
        'classes',
        classEntry(
          instead: {
            'progression': [
              for (var level = 1; level <= 20; level++)
                {
                  'level': level,
                  'proficiencyBonus': fixtureProficiencyBonus(level),
                  'features': fixtureRowFeatures(level, 'barbarian_'),
                  if (level == 1)
                    'spellcasting': {
                      'cantrips': 2,
                      'preparedSpells': 4,
                      'spellSlots': <int>[2, 0, 0, 0, 0, 0, 0, 0, 0],
                    },
                  'values': <String, Object?>{},
                },
            ],
          },
        ),
      ),
      [
        (
          '/classes/0/progression/0/spellcasting',
          ContentProblemKind.constraintViolation,
        ),
      ],
      () {
        expect(
          () => validClass(
            rowSpellcasting: (level) => SlotSpellcastingRow(
              cantrips: 2,
              preparedSpells: 4,
              spellSlots: [2, 0, 0, 0, 0, 0, 0, 0, 0],
            ),
          ),
          throwsArgumentError,
        );
      },
    ),
    Agreement(
      'slot level 0',
      documentOf(
        'classes',
        casterClassEntry(
          kind: 'pact',
          rowSpellcasting: (level) => level == 1
              ? {
                  'cantrips': 2,
                  'preparedSpells': 1,
                  'spellSlots': 2,
                  'slotLevel': 0,
                }
              : null,
        ),
      ),
      [
        (
          '/classes/0/progression/0/spellcasting/slotLevel',
          ContentProblemKind.outOfRange,
        ),
      ],
      () {
        expect(PactSpellcastingRow.isValidSlotLevel(0), isFalse);
        expect(
          () => PactSpellcastingRow(
            cantrips: 2,
            preparedSpells: 1,
            spellSlots: 2,
            slotLevel: 0,
          ),
          throwsArgumentError,
        );
      },
    ),
    Agreement(
      'slot level 10',
      documentOf(
        'classes',
        casterClassEntry(
          kind: 'pact',
          rowSpellcasting: (level) => level == 1
              ? {
                  'cantrips': 2,
                  'preparedSpells': 1,
                  'spellSlots': 2,
                  'slotLevel': 10,
                }
              : null,
        ),
      ),
      [
        (
          '/classes/0/progression/0/spellcasting/slotLevel',
          ContentProblemKind.outOfRange,
        ),
      ],
      () {
        expect(PactSpellcastingRow.isValidSlotLevel(10), isFalse);
      },
    ),
    Agreement(
      'slot level 9',
      documentOf(
        'classes',
        casterClassEntry(
          kind: 'pact',
          rowSpellcasting: (level) => level == 1
              ? {
                  'cantrips': 2,
                  'preparedSpells': 1,
                  'spellSlots': 2,
                  'slotLevel': 9,
                }
              : null,
        ),
      ),
      null,
      () {
        expect(PactSpellcastingRow.isValidSlotLevel(9), isTrue);
      },
    ),
    // Cases CV constructor halves (FR-040).
    Agreement(
      'count negative value',
      documentOf(
        'classes',
        columnedClassEntry(
          kind: 'count',
          defaultValue: 2,
          overrides: const {1: -1},
        ),
      ),
      [
        (
          '/classes/0/progression/0/values/rages',
          ContentProblemKind.outOfRange,
        ),
      ],
      () {
        expect(() => ColumnCount(-1), throwsArgumentError);
        expect(ColumnCount.isValid(-1), isFalse);
      },
    ),
    Agreement(
      'count as a string value',
      documentOf(
        'classes',
        columnedClassEntry(
          kind: 'count',
          defaultValue: 2,
          overrides: const {1: '2'},
        ),
      ),
      [('/classes/0/progression/0/values/rages', ContentProblemKind.wrongType)],
      () {
        // Unrepresentable: ColumnCount takes an int.
        expect(ColumnCount.isValid(2), isTrue);
      },
    ),
    Agreement(
      'dice zero count value',
      documentOf(
        'classes',
        columnedClassEntry(
          kind: 'dice',
          defaultValue: const {'count': 1, 'sides': 6},
          overrides: const {
            1: {'count': 0, 'sides': 6},
          },
        ),
      ),
      [
        (
          '/classes/0/progression/0/values/rages/count',
          ContentProblemKind.outOfRange,
        ),
      ],
      () {
        expect(() => ColumnDice(0, 6), throwsArgumentError);
        expect(ColumnDice.isValidCount(0), isFalse);
      },
    ),
    Agreement(
      'dice one side value',
      documentOf(
        'classes',
        columnedClassEntry(
          kind: 'dice',
          defaultValue: const {'count': 1, 'sides': 6},
          overrides: const {
            1: {'count': 1, 'sides': 1},
          },
        ),
      ),
      [
        (
          '/classes/0/progression/0/values/rages/sides',
          ContentProblemKind.outOfRange,
        ),
      ],
      () {
        expect(() => ColumnDice(1, 1), throwsArgumentError);
      },
    ),
    Agreement(
      'integer for dice value',
      documentOf(
        'classes',
        columnedClassEntry(
          kind: 'dice',
          defaultValue: const {'count': 1, 'sides': 6},
          overrides: const {1: 6},
        ),
      ),
      [('/classes/0/progression/0/values/rages', ContentProblemKind.wrongType)],
      () {
        // Unrepresentable: ColumnDice takes the {count, sides} pair.
        expect(ColumnDice(1, 6).count, 1);
      },
    ),
    Agreement(
      'hyphen for none value',
      documentOf(
        'classes',
        columnedClassEntry(
          kind: 'count',
          defaultValue: 2,
          overrides: const {1: '-'},
        ),
      ),
      [
        (
          '/classes/0/progression/0/values/rages',
          ContentProblemKind.invalidValue,
        ),
      ],
      () {
        // Unrepresentable: the em dash is the only string a column holds.
        expect(const ColumnNone(), isA<ColumnNone>());
      },
    ),
    // Cases ID decode halves (FR-052, schema FR-030): the decoder checks
    // the owner prefix and the id rule, not the exact derivation (D11).
    Agreement(
      'wrong prefix',
      documentOf(
        'classes',
        classWithExtraFeature({
          'id': 'fighter_rage',
          'name': 'Misfiled Rage',
          'level': 2,
          'text': 'You gain the misfiled feature.',
        }),
      ),
      [('/classes/0/features/3/id', ContentProblemKind.constraintViolation)],
      () {
        expect(
          () => validClass(
            features: [
              ...validFeatures(),
              FeatureEntry(
                id: FeatureId('fighter_rage'),
                name: 'Misfiled Rage',
                level: 2,
                text: 'You gain the misfiled feature.',
              ),
            ],
          ),
          throwsArgumentError,
        );
      },
    ),
    Agreement(
      'feature id 65 characters',
      documentOf(
        'classes',
        classWithExtraFeature({
          'id': 'barbarian_${'x' * 55}',
          'name': 'Long Feature',
          'level': 2,
          'text': 'You gain the long feature.',
        }),
      ),
      [
        (
          '/classes/0/progression/1/features/0/featureId',
          ContentProblemKind.invalidValue,
        ),
        ('/classes/0/features/3/id', ContentProblemKind.invalidValue),
      ],
      () {
        expect(
          ContentId.tryCreate('barbarian_${'x' * 55}'),
          isA<ContentIdRejected>(),
        );
        expect(() => FeatureId('barbarian_${'x' * 55}'), throwsArgumentError);
      },
    ),
  ];
  runRows('classes rows', rows);
}

// -- the spells spec's "Cases: spell JSON" (constructor column) --------------

void runSpellRows() {
  Map<String, Object?> spellWith(String key, Object? value) =>
      spellEntry(instead: {key: value});

  final rows = [
    Agreement('valid minimal', documentOf('spells', spellEntry()), null, () {
      expect(minimalSpell().requiresConcentration, isFalse);
      expect(SpellLevel.tryCreate(2), isA<SpellLevelParsed>());
    }),
    Agreement(
      'level too high',
      documentOf('spells', spellWith('level', 10)),
      [('/spells/0/level', ContentProblemKind.outOfRange)],
      () {
        expect(() => SpellLevel(10), throwsArgumentError);
        expect(SpellLevel.tryCreate(10), isA<SpellLevelRejected>());
      },
    ),
    Agreement(
      'level negative',
      documentOf('spells', spellWith('level', -1)),
      [('/spells/0/level', ContentProblemKind.outOfRange)],
      () {
        expect(() => SpellLevel(-1), throwsArgumentError);
        expect(SpellLevel.tryCreate(-1), isA<SpellLevelRejected>());
      },
    ),
    Agreement('level 9', documentOf('spells', spellWith('level', 9)), null, () {
      expect(SpellLevel(9).level, 9);
      expect(SpellLevel.tryCreate(9), isA<SpellLevelParsed>());
    }),
    Agreement(
      'level a string',
      documentOf('spells', spellWith('level', '3')),
      [('/spells/0/level', ContentProblemKind.wrongType)],
      () {
        // Unrepresentable: SpellLevel takes an int.
        expect(SpellLevel.isValid(3), isTrue);
      },
    ),
    Agreement(
      'level absent',
      documentOf('spells', spellEntry(without: const {'level'})),
      [('/spells/0/level', ContentProblemKind.missingField)],
      () {
        // Unrepresentable: the level is a required parameter.
        expect(SpellLevel.min, 0);
      },
    ),
    Agreement(
      'unknown school',
      documentOf('spells', spellWith('school', 'Lore')),
      [('/spells/0/school', ContentProblemKind.invalidValue)],
      () {
        expect(SpellSchool.fromJson('Lore'), isNull);
      },
    ),
    Agreement(
      'school wrong case',
      documentOf('spells', spellWith('school', 'evocation')),
      [('/spells/0/school', ContentProblemKind.invalidValue)],
      () {
        expect(SpellSchool.fromJson('evocation'), isNull);
      },
    ),
    Agreement(
      'class repeated',
      documentOf('spells', spellWith('classes', ['wizard', 'wizard'])),
      [('/spells/0/classes/1', ContentProblemKind.duplicate)],
      () {
        // Unrepresentable: the spell holds a Set.
        expect({ClassId('wizard')}.length, 1);
      },
    ),
    Agreement(
      'class not an id',
      documentOf('spells', spellWith('classes', ['Wizard'])),
      [('/spells/0/classes/0', ContentProblemKind.invalidValue)],
      () {
        expect(() => ClassId('Wizard'), throwsArgumentError);
        expect(ClassId.tryCreate('Wizard'), isA<TypedIdRejected<ClassId>>());
      },
    ),
    Agreement(
      'class unknown to the document',
      documentOf('spells', spellWith('classes', ['unknown_class'])),
      null,
      () {
        expect(ClassId('unknown_class').id.value, 'unknown_class');
      },
    ),
    Agreement(
      'no casting time',
      documentOf('spells', spellWith('castingTimes', <Object?>[])),
      [('/spells/0/castingTimes', ContentProblemKind.outOfRange)],
      () {
        expect(() => SpellCastingTimesModes(const []), throwsArgumentError);
        expect(SpellCastingTimes.minModes, 2);
      },
    ),
    Agreement(
      'unknown casting kind',
      documentOf(
        'spells',
        spellWith('castingTimes', [
          {'kind': 'bonus'},
        ]),
      ),
      [('/spells/0/castingTimes/0/kind', ContentProblemKind.invalidValue)],
      () {
        // Unrepresentable: the sealed family has five kinds.
        expect(CastingTime.magicAction(), isA<CastingTimeMagicAction>());
      },
    ),
    Agreement(
      'reaction without trigger',
      documentOf(
        'spells',
        spellWith('castingTimes', [
          {'kind': 'reaction'},
        ]),
      ),
      [('/spells/0/castingTimes/0/trigger', ContentProblemKind.missingField)],
      () {
        // Unrepresentable: the factory requires the trigger.
        expect(CastingTime.reaction('when'), isA<CastingTimeReaction>());
      },
    ),
    Agreement(
      'reaction blank trigger',
      documentOf(
        'spells',
        spellWith('castingTimes', [
          {'kind': 'reaction', 'trigger': ' '},
        ]),
      ),
      [('/spells/0/castingTimes/0/trigger', ContentProblemKind.invalidValue)],
      () {
        expect(() => CastingTime.reaction(' '), throwsArgumentError);
      },
    ),
    Agreement(
      'minutes zero',
      documentOf(
        'spells',
        spellWith('castingTimes', [
          {'kind': 'minutes', 'amount': 0},
        ]),
      ),
      [('/spells/0/castingTimes/0/amount', ContentProblemKind.outOfRange)],
      () {
        expect(() => CastingTime.minutes(0), throwsArgumentError);
        expect(CastingTime.isValidAmount(0), isFalse);
      },
    ),
    Agreement(
      'amount on an action',
      documentOf(
        'spells',
        spellWith('castingTimes', [
          {'kind': 'magicAction', 'amount': 5},
        ]),
      ),
      [('/spells/0/castingTimes/0/amount', ContentProblemKind.unknownField)],
      () {
        // Unrepresentable: the variant carries no amount.
        expect(const CastingTimeMagicAction(), isA<CastingTimeMagicAction>());
      },
    ),
    Agreement(
      'label on the only option',
      documentOf(
        'spells',
        spellWith('castingTimes', [
          {'kind': 'magicAction', 'label': 'Solo'},
        ]),
      ),
      [
        (
          '/spells/0/castingTimes/0/label',
          ContentProblemKind.constraintViolation,
        ),
      ],
      () {
        // Unrepresentable: SpellCastingTimesSingle has no label.
        expect(
          SpellCastingTimesSingle(CastingTime.magicAction()).time,
          isNotNull,
        );
      },
    ),
    Agreement(
      'second mode unlabelled',
      documentOf(
        'spells',
        spellWith('castingTimes', [
          {'kind': 'magicAction', 'label': 'First'},
          {'kind': 'hours', 'amount': 8},
        ]),
      ),
      [('/spells/0/castingTimes/1/label', ContentProblemKind.missingField)],
      () {
        // Unrepresentable: CastingTimeMode requires the label.
        expect(CastingTimeMode('Second', CastingTime.hours(8)).label, 'Second');
      },
    ),
    Agreement(
      'blank mode label',
      documentOf(
        'spells',
        spellWith('castingTimes', [
          {'kind': 'magicAction', 'label': 'First'},
          {'kind': 'hours', 'amount': 8, 'label': ''},
        ]),
      ),
      [('/spells/0/castingTimes/1/label', ContentProblemKind.invalidValue)],
      () {
        expect(
          () => CastingTimeMode('', CastingTime.hours(8)),
          throwsArgumentError,
        );
      },
    ),
    Agreement(
      'distance zero',
      documentOf(
        'spells',
        spellWith('range', {'kind': 'distance', 'amount': 0, 'unit': 'feet'}),
      ),
      [('/spells/0/range/amount', ContentProblemKind.outOfRange)],
      () {
        expect(
          () => SpellRange.distance(0, DistanceUnit.feet),
          throwsArgumentError,
        );
        expect(SpellRange.isValidDistance(0), isFalse);
      },
    ),
    Agreement(
      'distance unit unknown',
      documentOf(
        'spells',
        spellWith('range', {
          'kind': 'distance',
          'amount': 30,
          'unit': 'furlongs',
        }),
      ),
      [('/spells/0/range/unit', ContentProblemKind.invalidValue)],
      () {
        expect(DistanceUnit.fromJson('furlongs'), isNull);
      },
    ),
    Agreement(
      'distance without unit',
      documentOf(
        'spells',
        spellWith('range', {'kind': 'distance', 'amount': 5}),
      ),
      [('/spells/0/range/unit', ContentProblemKind.missingField)],
      () {
        // Unrepresentable: the factory requires both arguments.
        expect(SpellRange.distance(5, DistanceUnit.feet).amount, 5);
      },
    ),
    Agreement(
      'unit on self',
      documentOf(
        'spells',
        spellWith('range', {'kind': 'self', 'unit': 'feet'}),
      ),
      [('/spells/0/range/unit', ContentProblemKind.unknownField)],
      () {
        // Unrepresentable: the variant carries no unit.
        expect(SpellRange.self(), isA<SpellRangeSelf>());
      },
    ),
    Agreement(
      'verbal not a boolean',
      documentOf(
        'spells',
        spellWith('components', {
          'verbal': 'yes',
          'somatic': true,
          'material': {
            'description': 'A pinch of powder.',
            'costsGp': <int>[],
            'consumesMaterial': false,
          },
        }),
      ),
      [('/spells/0/components/verbal', ContentProblemKind.wrongType)],
      () {
        // Unrepresentable: the field is a bool.
        expect(SpellComponents(verbal: true, somatic: true).verbal, isTrue);
      },
    ),
    Agreement(
      'empty material',
      documentOf(
        'spells',
        spellWith('components', {
          'verbal': true,
          'somatic': true,
          'material': {
            'description': '',
            'costsGp': <int>[],
            'consumesMaterial': false,
          },
        }),
      ),
      [
        (
          '/spells/0/components/material/description',
          ContentProblemKind.invalidValue,
        ),
      ],
      () {
        expect(
          () => MaterialComponent('', const [], consumesMaterial: false),
          throwsArgumentError,
        );
      },
    ),
    Agreement(
      'cost zero',
      documentOf(
        'spells',
        spellWith('components', {
          'verbal': true,
          'somatic': true,
          'material': {
            'description': 'A pinch of powder.',
            'costsGp': [0],
            'consumesMaterial': false,
          },
        }),
      ),
      [
        (
          '/spells/0/components/material/costsGp/0',
          ContentProblemKind.outOfRange,
        ),
      ],
      () {
        expect(
          () => MaterialComponent('A pinch of powder.', [
            0,
          ], consumesMaterial: false),
          throwsArgumentError,
        );
        expect(MaterialComponent.isValidCostGp(0), isFalse);
      },
    ),
    Agreement(
      'timed without amount',
      documentOf(
        'spells',
        spellWith('duration', {
          'kind': 'timed',
          'unit': 'hours',
          'limit': 'fixed',
        }),
      ),
      [('/spells/0/duration/amount', ContentProblemKind.missingField)],
      () {
        // Unrepresentable: the factory requires the amount.
        expect(
          SpellDuration.timed(
            1,
            DurationUnit.hours,
            DurationLimit.fixed,
          ).amount,
          1,
        );
      },
    ),
    Agreement(
      'timed zero',
      documentOf(
        'spells',
        spellWith('duration', {
          'kind': 'timed',
          'amount': 0,
          'unit': 'hours',
          'limit': 'fixed',
        }),
      ),
      [('/spells/0/duration/amount', ContentProblemKind.outOfRange)],
      () {
        expect(
          () => SpellDuration.timed(0, DurationUnit.hours, DurationLimit.fixed),
          throwsArgumentError,
        );
        expect(SpellDuration.isValidAmount(0), isFalse);
      },
    ),
    Agreement(
      'concentration without a cap',
      documentOf(
        'spells',
        spellWith('duration', {
          'kind': 'timed',
          'amount': 1,
          'unit': 'hours',
          'limit': 'concentration',
        }),
      ),
      [('/spells/0/duration/limit', ContentProblemKind.invalidValue)],
      () {
        expect(DurationLimit.fromJson('concentration'), isNull);
      },
    ),
    Agreement(
      'amount on instantaneous',
      documentOf(
        'spells',
        spellWith('duration', {'kind': 'instantaneous', 'amount': 1}),
      ),
      [('/spells/0/duration/amount', ContentProblemKind.unknownField)],
      () {
        // Unrepresentable: the variant carries no amount.
        expect(
          SpellDuration.instantaneous(),
          isA<SpellDurationInstantaneous>(),
        );
      },
    ),
    Agreement(
      'description empty',
      documentOf('spells', spellWith('description', <Object?>[])),
      [('/spells/0/description', ContentProblemKind.outOfRange)],
      () {
        expect(
          () => minimalSpell().runtimeType,
          returnsNormally,
          reason:
              'the constructor side is pinned by the empty-description '
              'spell below',
        );
        expect(
          () => Spell(
            id: SpellId('acid_arrow'),
            name: 'Acid Arrow',
            level: SpellLevel(2),
            school: SpellSchool.evocation,
            classes: {ClassId('wizard')},
            castingTimes: SpellCastingTimesSingle(CastingTime.magicAction()),
            ritual: false,
            range: SpellRange.distance(90, DistanceUnit.feet),
            components: SpellComponents(verbal: true, somatic: true),
            duration: SpellDuration.instantaneous(),
            description: [],
          ),
          throwsArgumentError,
        );
      },
    ),
    Agreement(
      'blank paragraph',
      documentOf(
        'spells',
        spellWith('description', [
          {'kind': 'paragraph', 'text': '  '},
        ]),
      ),
      [('/spells/0/description/0/text', ContentProblemKind.invalidValue)],
      () {
        expect(() => ContentTextBlock.paragraph('  '), throwsArgumentError);
      },
    ),
    Agreement(
      'unknown block kind',
      documentOf(
        'spells',
        spellWith('description', [
          {'kind': 'quote', 'text': 'x'},
        ]),
      ),
      [('/spells/0/description/0/kind', ContentProblemKind.invalidValue)],
      () {
        // Unrepresentable: the family has five kinds.
        expect(ContentTextBlock.paragraph('x'), isA<ContentTextParagraph>());
      },
    ),
    Agreement(
      'ragged table',
      documentOf(
        'spells',
        spellWith('description', [
          {
            'kind': 'table',
            'header': ['One', 'Two'],
            'rows': [
              ['a', 'b'],
              ['c', 'd', 'e'],
            ],
          },
        ]),
      ),
      [
        (
          '/spells/0/description/0/rows/1',
          ContentProblemKind.constraintViolation,
        ),
      ],
      () {
        expect(
          () => ContentTextBlock.table(
            header: ['One', 'Two'],
            rows: [
              ['a', 'b'],
              ['c', 'd', 'e'],
            ],
          ),
          throwsArgumentError,
        );
      },
    ),
    Agreement(
      'table without rows',
      documentOf(
        'spells',
        spellWith('description', [
          {
            'kind': 'table',
            'header': ['One'],
            'rows': <Object?>[],
          },
        ]),
      ),
      [('/spells/0/description/0/rows', ContentProblemKind.outOfRange)],
      () {
        expect(
          () => ContentTextBlock.table(header: ['One'], rows: []),
          throwsArgumentError,
        );
      },
    ),
    Agreement(
      'blank body cell',
      documentOf(
        'spells',
        spellWith('description', [
          {
            'kind': 'table',
            'header': ['One'],
            'rows': [
              [' '],
            ],
          },
        ]),
      ),
      [('/spells/0/description/0/rows/0/0', ContentProblemKind.invalidValue)],
      () {
        expect(
          () => ContentTextBlock.table(
            header: ['One'],
            rows: [
              [' '],
            ],
          ),
          throwsArgumentError,
        );
        expect(ContentTextTable.isValidCell(' '), isFalse);
      },
    ),
    Agreement(
      'empty body cell accepted',
      documentOf(
        'spells',
        spellWith('description', [
          {
            'kind': 'table',
            'header': ['One', 'Two'],
            'rows': [
              ['x', ''],
            ],
          },
        ]),
      ),
      null,
      () {
        final table = ContentTextBlock.table(
          header: ['One', 'Two'],
          rows: [
            ['x', ''],
          ],
        );
        expect(table, isA<ContentTextTable>());
        expect(ContentTextTable.isValidCell(''), isTrue);
      },
    ),
    Agreement(
      'empty higher-level text',
      documentOf('spells', spellWith('higherLevel', <Object?>[])),
      [('/spells/0/higherLevel', ContentProblemKind.outOfRange)],
      () {
        expect(() => minimalSpell(higherLevel: []), throwsArgumentError);
      },
    ),
    Agreement(
      'old shape',
      documentOf('spells', spellWith('higherLevelSlot', 'When you cast...')),
      [('/spells/0/higherLevelSlot', ContentProblemKind.unknownField)],
      () {
        // Unrepresentable: no such field exists.
        expect(minimalSpell(), isA<Spell>());
      },
    ),
    Agreement(
      'id not valid',
      documentOf('spells', spellWith('id', 'Acid-Arrow')),
      [('/spells/0/id', ContentProblemKind.invalidValue)],
      () {
        expect(() => SpellId('Acid-Arrow'), throwsArgumentError);
        expect(
          SpellId.tryCreate('Acid-Arrow'),
          isA<TypedIdRejected<SpellId>>(),
        );
      },
    ),
    Agreement(
      'name padded',
      documentOf('spells', spellWith('name', ' Acid Arrow')),
      [('/spells/0/name', ContentProblemKind.invalidValue)],
      () {
        expect(Spell.isValidName(' Acid Arrow'), isFalse);
      },
    ),
    Agreement(
      'citation page zero',
      documentOf(
        'spells',
        spellWith('source', {'document': 'd', 'section': 's', 'page': 0}),
      ),
      [('/spells/0/source/page', ContentProblemKind.outOfRange)],
      () {
        expect(
          () => SourceCitation(document: 'd', section: 's', page: 0),
          throwsArgumentError,
        );
      },
    ),
    Agreement(
      'citation section absent',
      documentOf('spells', spellWith('source', {'document': 'd', 'page': 1})),
      [('/spells/0/source/section', ContentProblemKind.missingField)],
      () {
        // Unrepresentable: the section is a required parameter.
        expect(
          SourceCitation.tryCreate(document: 'd', section: 's', page: 1),
          isA<SourceCitationParsed>(),
        );
      },
    ),
    Agreement(
      'citation blank document',
      documentOf(
        'spells',
        spellWith('source', {'document': ' ', 'section': 's', 'page': 1}),
      ),
      [('/spells/0/source/document', ContentProblemKind.invalidValue)],
      () {
        expect(
          () => SourceCitation(document: ' ', section: 's', page: 1),
          throwsArgumentError,
        );
      },
    ),
    Agreement('citation absent', documentOf('spells', spellEntry()), null, () {
      expect(minimalSpell().source, isNull);
    }),
    Agreement(
      'two problems, one spell',
      documentOf(
        'spells',
        spellEntry(instead: const {'level': 10, 'school': 'Lore'}),
      ),
      [
        ('/spells/0/level', ContentProblemKind.outOfRange),
        ('/spells/0/school', ContentProblemKind.invalidValue),
      ],
      () {
        expect(() => SpellLevel(10), throwsArgumentError);
        expect(SpellSchool.fromJson('Lore'), isNull);
      },
    ),
  ];
  runRows('spells rows', rows);
}
