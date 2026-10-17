import 'package:srd5e/src/content/domain/classes/ability_requirement.dart';
import 'package:srd5e/src/content/domain/classes/armor_training_category.dart';
import 'package:srd5e/src/content/domain/classes/class_column.dart';
import 'package:srd5e/src/content/domain/classes/class_definition.dart';
import 'package:srd5e/src/content/domain/classes/class_spellcasting_trait.dart';
import 'package:srd5e/src/content/domain/classes/class_starting_equipment.dart';
import 'package:srd5e/src/content/domain/classes/class_tool_proficiency.dart';
import 'package:srd5e/src/content/domain/classes/column_value.dart';
import 'package:srd5e/src/content/domain/classes/feature_entry.dart';
import 'package:srd5e/src/content/domain/classes/feature_fact.dart';
import 'package:srd5e/src/content/domain/classes/multiclass_grants.dart';
import 'package:srd5e/src/content/domain/classes/progression_row.dart';
import 'package:srd5e/src/content/domain/classes/skill_choice.dart';
import 'package:srd5e/src/content/domain/classes/subclass_definition.dart';
import 'package:srd5e/src/content/domain/classes/weapon_proficiency.dart';
import 'package:srd5e/src/content/domain/feat_category.dart';
import 'package:srd5e/src/content/domain/hit_point_die.dart';
import 'package:srd5e/src/content/domain/skill.dart';
import 'package:srd5e/src/content/domain/typed_ids.dart';
import 'package:srd5e/src/shared_kernel/ability/ability.dart';

/// The Proficiency Bonus of the Features tables: +2 at levels 1 to 4, +3 at
/// 5 to 8, +4 at 9 to 12, +5 at 13 to 16 and +6 at 17 to 20 (FR-038;
/// SRD 5.2.1, "Proficiency Bonus", p. 8).
int fixtureProficiencyBonus(int level) {
  if (level <= 4) return 2;
  if (level <= 8) return 3;
  if (level <= 12) return 4;
  if (level <= 16) return 5;
  return 6;
}

/// A default cell value that suits the column's kind, so a fixture with
/// declared columns builds valid rows (FR-040).
ColumnValue _defaultValue(ClassColumn column) => switch (column.kind) {
  ClassColumnKind.count => ColumnCount(0),
  ClassColumnKind.dice => ColumnDice(1, 4),
  ClassColumnKind.bonus => ColumnBonus(0),
  ClassColumnKind.feetBonus => const ColumnFeetBonus(0),
};

SpellcastingRow? _defaultRowSpellcasting(ClassSpellcastingTrait? trait) {
  if (trait == null) return null;
  return switch (trait) {
    SlotSpellcastingTrait(:final cantrips) => SlotSpellcastingRow(
      cantrips: cantrips ? 2 : null,
      preparedSpells: 4,
      spellSlots: [2, 0, 0, 0, 0, 0, 0, 0, 0],
    ),
    PactSpellcastingTrait() => PactSpellcastingRow(
      cantrips: 2,
      preparedSpells: 1,
      spellSlots: 2,
      slotLevel: 1,
    ),
  };
}

/// Builds a minimal valid Barbarian-shaped [ClassDefinition] for the unit
/// tests, overridable per field. The default rows reference the default
/// features (Rage at 1, the subclass entry at 3, Ability Score Improvement
/// at [asiLevels] — 4, 8, 12 and 16 unless overridden, as the Fighter and
/// Rogue rows need) and carry the FR-038 Proficiency Bonus.
ClassDefinition buildTestClass({
  ClassId? id,
  String name = 'Barbarian',
  AbilityRequirement? primaryAbility,
  HitPointDie? hitPointDie,
  List<Ability>? savingThrowProficiencies,
  SkillChoice? skillChoice,
  List<WeaponProficiency>? weaponProficiencies,
  List<ClassToolProficiency>? toolProficiencies,
  List<ArmorTrainingCategory>? armorTraining,
  ClassStartingEquipment? startingEquipment,
  MulticlassGrants? multiclassGrants,
  ClassSpellcastingTrait? spellcasting,
  SpellcastingRow? Function(int level)? rowSpellcasting,
  List<ClassColumn>? columns,
  ColumnValue? Function(ClassColumn column, int level)? columnValue,
  List<RowFeature>? Function(int level)? rowFeatures,
  List<int>? asiLevels,
  List<FeatureEntry>? features,
  List<SubclassDefinition>? subclasses,
}) {
  final classId = id ?? ClassId('barbarian');
  final prefix = '${classId.id.value}_';
  final classColumns = columns ?? const [];
  final classAsiLevels = asiLevels ?? const [4, 8, 12, 16];
  // The Ability Score Improvement entries live once at the first ASI level
  // and at each extra level the Fighter (6, 14) and Rogue (10) rows need;
  // every ASI row cites the latest such entry at or below itself (D15).
  const standardAsiLevels = [4, 8, 12, 16];
  final asiEntryLevels = <int>{
    classAsiLevels.first,
    for (final level in classAsiLevels)
      if (!standardAsiLevels.contains(level)) level,
  }.toList()..sort();
  final classFeatures =
      features ??
      [
        FeatureEntry(
          id: FeatureId('${prefix}rage'),
          name: 'Rage',
          level: 1,
          text: 'In battle, you fight with primal ferocity.',
        ),
        FeatureEntry(
          id: FeatureId('${prefix}subclass'),
          name: 'Subclass',
          level: 3,
          text: 'You choose a subclass.',
          facts: [const GrantsSubclass()],
        ),
        for (final level in asiEntryLevels)
          FeatureEntry(
            id: FeatureId(
              '${prefix}ability_score_improvement'
              '${level == asiEntryLevels.first ? '' : '_$level'}',
            ),
            name: 'Ability Score Improvement',
            level: level,
            text: 'You gain the Ability Score Improvement feat.',
            facts: [const GrantsFeat(FeatCategory.general)],
          ),
      ];
  final rowFeaturesById = {
    for (final feature in classFeatures) feature.level: feature.id,
  };
  // Whether the default feature set is in use, so the default rows can cite
  // the entries again at later levels (D15) and carry the subclass marker
  // at 3.
  final usingDefaultFeatures = features == null;
  // The latest Ability Score Improvement entry at or below each row level
  // the class gains a feat at (table FA).
  FeatureId? latestAsiId;
  final asiIdByRowLevel = <int, FeatureId?>{};
  for (var level = 1; level <= ProgressionRow.maxLevel; level++) {
    if (rowFeaturesById.containsKey(level) &&
        classFeatures
            .firstWhere((feature) => feature.level == level)
            .facts
            .any((fact) => fact is GrantsFeat)) {
      latestAsiId = rowFeaturesById[level];
    }
    if (standardAsiLevels.contains(level) || classAsiLevels.contains(level)) {
      asiIdByRowLevel[level] = latestAsiId;
    }
  }
  final rows = [
    for (var level = 1; level <= ProgressionRow.maxLevel; level++)
      ProgressionRow(
        level: level,
        proficiencyBonus: fixtureProficiencyBonus(level),
        features:
            rowFeatures?.call(level) ??
            [
              if (rowFeaturesById.containsKey(level))
                RowClassFeature(rowFeaturesById[level]!),
              if (usingDefaultFeatures &&
                  asiIdByRowLevel.containsKey(level) &&
                  !rowFeaturesById.containsKey(level) &&
                  asiIdByRowLevel[level] != null)
                RowClassFeature(asiIdByRowLevel[level]!),
              if (usingDefaultFeatures && level == 3)
                const RowSubclassFeature(),
            ],
        spellcasting:
            rowSpellcasting?.call(level) ??
            _defaultRowSpellcasting(spellcasting),
        values: {
          for (final column in classColumns)
            column.id:
                columnValue?.call(column, level) ?? _defaultValue(column),
        },
      ),
  ];
  return ClassDefinition(
    id: classId,
    name: name,
    primaryAbility: primaryAbility ?? AllOf([Ability.strength]),
    hitPointDie: hitPointDie ?? HitPointDie.d12,
    savingThrowProficiencies:
        savingThrowProficiencies ?? [Ability.strength, Ability.constitution],
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
    weaponProficiencies:
        weaponProficiencies ??
        [
          WeaponProficiency(WeaponTrainingCategory.simple),
          WeaponProficiency(WeaponTrainingCategory.martial),
        ],
    toolProficiencies: toolProficiencies ?? const [],
    armorTraining: armorTraining ?? const [],
    startingEquipment:
        startingEquipment ??
        ClassStartingEquipment(
          a: ClassEquipmentOption([ClassEquipmentItem('Greataxe', 1)], 0),
          b: ClassEquipmentOption([], 50),
        ),
    multiclassGrants: multiclassGrants ?? MulticlassGrants(),
    spellcasting: spellcasting,
    columns: classColumns,
    progression: rows,
    features: classFeatures,
    subclasses: subclasses ?? const [],
  );
}
