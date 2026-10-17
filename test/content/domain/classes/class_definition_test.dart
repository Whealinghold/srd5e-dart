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
import 'package:srd5e/src/content/domain/content_id.dart';
import 'package:srd5e/src/content/domain/content_kind.dart';
import 'package:srd5e/src/content/domain/feat_category.dart';
import 'package:srd5e/src/content/domain/hit_point_die.dart';
import 'package:srd5e/src/content/domain/skill.dart';
import 'package:srd5e/src/content/domain/typed_ids.dart';
import 'package:srd5e/src/shared_kernel/ability/ability.dart';
import 'package:test/test.dart';

import '../../../support/argument_error_matcher.dart';
import '../../../support/operator_equals.dart';
import 'class_fixture.dart';

FeatureEntry _feature(
  String id,
  int level, {
  List<FeatureFact> facts = const [],
}) => FeatureEntry(
  id: FeatureId(id),
  name: 'A feature',
  level: level,
  text: 'The printed text of the feature.',
  facts: facts,
);

SubclassDefinition _subclass(int subclassLevel) => SubclassDefinition(
  id: SubclassId('berserker'),
  name: 'Path of the Berserker',
  features: [_feature('berserker_frenzy', subclassLevel)],
);

/// A minimal valid class with the default fixture features, for the
/// cross-entry rows that must assemble a `ClassDefinition` by hand.
ClassDefinition _assemble({
  required List<ProgressionRow> progression,
  List<ClassColumn> columns = const [],
  List<FeatureEntry>? features,
  List<SubclassDefinition> subclasses = const [],
  List<Ability>? savingThrowProficiencies,
  SkillChoice? skillChoice,
  List<WeaponProficiency>? weaponProficiencies,
  List<ClassToolProficiency>? toolProficiencies,
  List<ArmorTrainingCategory>? armorTraining,
  MulticlassGrants? multiclassGrants,
  ClassSpellcastingTrait? spellcasting,
}) => ClassDefinition(
  id: ClassId('barbarian'),
  name: 'Barbarian',
  primaryAbility: AllOf([Ability.strength]),
  hitPointDie: HitPointDie.d12,
  savingThrowProficiencies:
      savingThrowProficiencies ?? [Ability.strength, Ability.constitution],
  skillChoice:
      skillChoice ?? SkillChoiceListed(2, [Skill.survival, Skill.athletics]),
  weaponProficiencies: weaponProficiencies ?? const [],
  toolProficiencies: toolProficiencies ?? const [],
  armorTraining: armorTraining ?? const [],
  startingEquipment: ClassStartingEquipment(
    a: ClassEquipmentOption(const [], 0),
    b: ClassEquipmentOption(const [], 0),
  ),
  multiclassGrants: multiclassGrants ?? MulticlassGrants(),
  spellcasting: spellcasting,
  columns: columns,
  progression: progression,
  features:
      features ??
      [
        _feature('barbarian_rage', 1),
        _feature('barbarian_subclass', 3, facts: [const GrantsSubclass()]),
        _feature(
          'barbarian_ability_score_improvement',
          4,
          facts: [const GrantsFeat(FeatCategory.general)],
        ),
      ],
  subclasses: subclasses,
);

List<ProgressionRow> _rowsReferencingDefaultFeatures({
  Map<int, Map<ClassColumnId, ColumnValue>>? valuesByLevel,
  Map<int, List<RowFeature>>? featuresByLevel,
}) => [
  for (var level = 1; level <= ProgressionRow.maxLevel; level++)
    ProgressionRow(
      level: level,
      proficiencyBonus: fixtureProficiencyBonus(level),
      features:
          featuresByLevel?[level] ??
          [
            if (level == 1) RowClassFeature(FeatureId('barbarian_rage')),
            if (level == 3) RowClassFeature(FeatureId('barbarian_subclass')),
            if (level == 4 || level == 8 || level == 12 || level == 16)
              RowClassFeature(FeatureId('barbarian_ability_score_improvement')),
          ],
      spellcasting: null,
      values: valuesByLevel?[level] ?? const {},
    ),
];

void main() {
  /// Requirement: doc/specs/content-classes.md FR-001 - `ClassDefinition`
  ///   is an immutable `ContentEntry` whose key is
  ///   (`ContentKind.characterClass`, its `ClassId`).
  /// Path: happy
  test('the key is the characterClass kind and the class id', () {
    final definition = buildTestClass();
    expect(definition.key.kind, ContentKind.characterClass);
    expect(definition.key.id, ContentId('barbarian'));
    expect(definition.key, equals(ClassId('barbarian').key));
  });

  /// Requirement: doc/specs/content-classes.md FR-047 - `rowAt` returns the
  ///   row of that level and throws `ArgumentError` for 0, 21 and any value
  ///   outside 1 to 20.
  /// Path: happy
  group('rowAt boundaries', () {
    final definition = buildTestClass();

    /// Requirement: per case
    /// Path: per case
    for (final c in [
      (
        label: 'level 1',
        requirement:
            'doc/specs/content-classes.md FR-047 - level 1 returns the '
            'first row',
        path: 'happy',
        level: 1,
        valid: true,
      ),
      (
        label: 'level 20',
        requirement:
            'doc/specs/content-classes.md FR-047 - level 20 returns the '
            'last row',
        path: 'unhappy (boundary)',
        level: 20,
        valid: true,
      ),
      (
        label: 'level 0',
        requirement: 'doc/specs/content-classes.md FR-047 - level 0 throws',
        path: 'unhappy (boundary)',
        level: 0,
        valid: false,
      ),
      (
        label: 'level 21',
        requirement: 'doc/specs/content-classes.md FR-047 - level 21 throws',
        path: 'unhappy (boundary)',
        level: 21,
        valid: false,
      ),
      (
        label: 'level -1',
        requirement:
            'doc/specs/content-classes.md FR-047 - a negative level throws',
        path: 'unhappy (boundary)',
        level: -1,
        valid: false,
      ),
    ]) {
      test('${c.label} [${c.path}]', () {
        if (c.valid) {
          expect(definition.rowAt(c.level).level, c.level);
        } else {
          expect(
            () => definition.rowAt(c.level),
            throwsArgumentErrorFor('level', c.level),
          );
        }
      });
    }
  });

  /// Requirement: doc/specs/content-classes.md FR-048 - `entriesGainedAt`
  ///   returns the class feature entries whose level equals the argument,
  ///   in printed order, and [] for a level with none (the Barbarian's
  ///   level 6); it throws outside 1 to 20.
  /// Path: happy
  group('entriesGainedAt rows (table RR)', () {
    final definition = buildTestClass();

    /// Requirement: per case
    /// Path: per case
    for (final c in [
      (
        label: 'level 1 gains Rage',
        requirement:
            'doc/specs/content-classes.md FR-048 - level 1 gains the Rage '
            'entry',
        path: 'happy',
        level: 1,
        expected: ['barbarian_rage'],
      ),
      (
        label: 'level 6 gains none',
        requirement:
            'doc/specs/content-classes.md FR-048 - a level with no entry '
            'gains [] (the Barbarian\'s level 6)',
        path: 'unhappy (boundary)',
        level: 6,
        expected: <String>[],
      ),
      (
        label: 'level 17 gains none',
        requirement:
            'doc/specs/content-classes.md FR-048 - a level with no entry '
            'gains [] (the Barbarian\'s level 17)',
        path: 'unhappy (boundary)',
        level: 17,
        expected: <String>[],
      ),
    ]) {
      test('${c.label} [${c.path}]', () {
        final gained = definition.entriesGainedAt(c.level);
        expect(gained.map((e) => e.id.id.value), c.expected);
      });
    }

    /// Requirement: doc/specs/content-classes.md FR-048 - the accessors
    ///   throw for 0.
    /// Path: unhappy (boundary)
    test('level 0 throws for every accessor', () {
      expect(
        () => definition.entriesGainedAt(0),
        throwsArgumentErrorFor('level', 0),
      );
      expect(
        () => definition.rowFeatures(0),
        throwsArgumentErrorFor('level', 0),
      );
      expect(
        () => definition.featGrantsAt(0),
        throwsArgumentErrorFor('level', 0),
      );
    });

    /// Requirement: doc/specs/content-classes.md FR-048 - the accessors
    ///   throw for 21.
    /// Path: unhappy (boundary)
    test('level 21 throws for every accessor', () {
      expect(
        () => definition.entriesGainedAt(21),
        throwsArgumentErrorFor('level', 21),
      );
      expect(
        () => definition.rowFeatures(21),
        throwsArgumentErrorFor('level', 21),
      );
      expect(
        () => definition.featGrantsAt(21),
        throwsArgumentErrorFor('level', 21),
      );
    });
  });

  /// Requirement: doc/specs/content-classes.md FR-048 - `rowFeatures`
  ///   returns a `ResolvedRow` whose entries are the row's class features
  ///   resolved in printed order, an entry possibly older than the row
  ///   (Ability Score Improvement at level 8), and the subclass-marker flag.
  /// Path: happy
  group('rowFeatures rows (table RR)', () {
    final definition = buildTestClass(subclasses: [_subclass(3)]);

    /// Requirement: doc/specs/content-classes.md FR-048 - an entry is
    ///   possibly older than the row: Ability Score Improvement at level 8
    ///   resolves to the level 4 entry (D15).
    /// Path: happy
    test('level 8 resolves the level 4 Ability Score Improvement entry', () {
      final resolved = definition.rowFeatures(8);
      expect(resolved.entries.map((e) => e.id.id.value), [
        'barbarian_ability_score_improvement',
      ]);
      expect(resolved.hasSubclassFeature, isFalse);
    });

    /// Requirement: doc/specs/content-classes.md FR-048 - `rowFeatures`
    ///   sets `hasSubclassFeature` on marker rows.
    /// Path: happy
    test('level 3 carries the subclass marker', () {
      final resolved = definition.rowFeatures(3);
      expect(resolved.hasSubclassFeature, isTrue);
      expect(resolved.entries.map((e) => e.id.id.value), [
        'barbarian_subclass',
      ]);
    });

    /// Requirement: doc/specs/content-classes.md FR-048 - the row's class
    ///   features resolve to their entries in printed order.
    /// Path: happy
    test('level 1 resolves Rage and no marker', () {
      final resolved = definition.rowFeatures(1);
      expect(resolved.hasSubclassFeature, isFalse);
      expect(resolved.entries.single.id.id.value, 'barbarian_rage');
    });

    /// Requirement: doc/specs/content-classes.md FR-008 - the resolved
    ///   entries are unmodifiable and the row compares by value.
    /// Path: happy
    test('the resolved row is unmodifiable and equal by value', () {
      final resolved = definition.rowFeatures(1);
      expect(() => resolved.entries.clear(), throwsUnsupportedError);
      expect(resolved, equals(definition.rowFeatures(1)));
      expect(resolved.hashCode, definition.rowFeatures(1).hashCode);
      expect(resolved.toString(), startsWith('ResolvedRow('));
    });
  });

  /// Requirement: doc/specs/content-classes.md FR-049 - `featGrantsAt`
  ///   returns the category of every `GrantsFeat` fact among the row's
  ///   resolved features (table FA).
  /// Path: happy
  group('featGrantsAt rows (table FA)', () {
    /// Requirement: doc/specs/content-classes.md FR-049 - Ability Score
    ///   Improvement (General) at 4, 8, 12 and 16 for most classes, none
    ///   elsewhere (table FA).
    /// Path: happy
    test('the Barbarian gains General at 4, 8, 12 and 16', () {
      final definition = buildTestClass();
      for (final level in [4, 8, 12, 16]) {
        expect(definition.featGrantsAt(level), [FeatCategory.general]);
      }
      expect(definition.featGrantsAt(5), isEmpty);
      expect(definition.featGrantsAt(19), isEmpty);
    });
  });

  /// Requirement: doc/specs/content-classes.md FR-049 - the Fighter gains
  ///   Ability Score Improvement at 6 and 14 as well (table FA).
  /// Path: happy
  test('the Fighter gains General at 6 and 14 as well', () {
    final fighter = buildTestClass(
      id: ClassId('fighter'),
      name: 'Fighter',
      asiLevels: const [4, 6, 8, 12, 14, 16],
    );
    expect(fighter.featGrantsAt(6), [FeatCategory.general]);
    expect(fighter.featGrantsAt(14), [FeatCategory.general]);
    expect(fighter.featGrantsAt(7), isEmpty);
    expect(fighter.featGrantsAt(15), isEmpty);
  });

  /// Requirement: doc/specs/content-classes.md FR-049 - the Rogue gains
  ///   Ability Score Improvement at 10 as well (table FA).
  /// Path: happy
  test('the Rogue gains General at 10 as well', () {
    final rogue = buildTestClass(
      id: ClassId('rogue'),
      name: 'Rogue',
      asiLevels: const [4, 8, 10, 12, 16],
    );
    expect(rogue.featGrantsAt(10), [FeatCategory.general]);
    expect(rogue.featGrantsAt(9), isEmpty);
    expect(rogue.featGrantsAt(11), isEmpty);
  });

  /// Requirement: doc/specs/content-classes.md FR-050 - `column` returns
  ///   the declared column and throws for an undeclared id.
  /// Path: unhappy (invalid input)
  test('column returns the declared column and rejects an undeclared id', () {
    final id = ClassColumnId('rages');
    final definition = buildTestClass(
      columns: [
        ClassColumn(id: id, header: 'Rages', kind: ClassColumnKind.count),
      ],
    );
    expect(definition.column(id).header, 'Rages');
    expect(
      () => definition.column(ClassColumnId('luck')),
      throwsArgumentErrorFor('id', ClassColumnId('luck')),
    );
  });

  /// Requirement: doc/specs/content-classes.md FR-099 - `entry` returns the
  ///   sealed `FeatureEntryLookup`: found for a class feature, not found for
  ///   an unknown id and for a subclass feature id.
  /// Path: happy
  group('entry lookups', () {
    final definition = buildTestClass(subclasses: [_subclass(3)]);

    /// Requirement: doc/specs/content-classes.md FR-099 - a class feature
    ///   of this class is `FeatureEntryFound(entry)`.
    /// Path: happy
    test('a class feature id is found', () {
      final lookup = definition.entry(FeatureId('barbarian_rage'));
      expect(lookup, isA<FeatureEntryFound>());
      expect((lookup as FeatureEntryFound).entry.name, 'Rage');
      expect(lookup, equals(FeatureEntryFound(definition.features.first)));
      expect(
        lookup.hashCode,
        definition.entry(FeatureId('barbarian_rage')).hashCode,
      );
      expect(lookup.toString(), 'FeatureEntryFound(barbarian_rage)');
    });

    /// Requirement: doc/specs/content-classes.md FR-099 - an unknown id
    ///   is `FeatureEntryNotFound(id)`.
    /// Path: unhappy (missing content)
    test('an unknown id is not found', () {
      expect(
        definition.entry(FeatureId('barbarian_nothing')),
        equals(FeatureEntryNotFound(FeatureId('barbarian_nothing'))),
      );
      expect(
        definition.entry(FeatureId('barbarian_nothing')).hashCode,
        FeatureEntryNotFound(FeatureId('barbarian_nothing')).hashCode,
      );
      expect(
        definition.entry(FeatureId('barbarian_nothing')).toString(),
        'FeatureEntryNotFound(barbarian_nothing)',
      );
    });

    /// Requirement: doc/specs/content-classes.md FR-099 - a subclass
    ///   feature id is `FeatureEntryNotFound`; subclass features are
    ///   reached through `subclass`.
    /// Path: unhappy (missing content)
    test('a subclass feature id is not found', () {
      expect(
        definition.entry(FeatureId('berserker_frenzy')),
        equals(FeatureEntryNotFound(FeatureId('berserker_frenzy'))),
      );
    });

    /// Requirement: doc/specs/content-classes.md FR-099 - the lookup is
    ///   sealed with exactly the two variants, exhaustive in a `switch`.
    /// Path: happy
    test('the lookups switch exhaustively', () {
      String describe(FeatureEntryLookup lookup) => switch (lookup) {
        FeatureEntryFound() => 'found',
        FeatureEntryNotFound() => 'not found',
      };
      expect(describe(definition.entry(FeatureId('barbarian_rage'))), 'found');
      expect(
        describe(definition.entry(FeatureId('barbarian_nothing'))),
        'not found',
      );
    });
  });

  /// Requirement: doc/specs/content-classes.md FR-074 - `subclass` returns
  ///   the sealed `SubclassLookup`: found for a subclass of this class,
  ///   not found otherwise.
  /// Path: happy
  group('subclass lookups', () {
    final definition = buildTestClass(subclasses: [_subclass(3)]);

    /// Requirement: doc/specs/content-classes.md FR-074 - a subclass of
    ///   this class is `SubclassFound(subclass)`.
    /// Path: happy
    test('a subclass of this class is found', () {
      final lookup = definition.subclass(SubclassId('berserker'));
      expect(lookup, isA<SubclassFound>());
      expect((lookup as SubclassFound).subclass.name, 'Path of the Berserker');
      expect(lookup, equals(definition.subclass(SubclassId('berserker'))));
      expect(
        lookup.hashCode,
        definition.subclass(SubclassId('berserker')).hashCode,
      );
      expect(lookup.toString(), startsWith('SubclassFound('));
    });

    /// Requirement: doc/specs/content-classes.md FR-074 - another id is
    ///   `SubclassNotFound(id)`.
    /// Path: unhappy (missing content)
    test('another subclass id is not found', () {
      expect(
        definition.subclass(SubclassId('champion')),
        equals(SubclassNotFound(SubclassId('champion'))),
      );
      expect(
        definition.subclass(SubclassId('champion')).hashCode,
        SubclassNotFound(SubclassId('champion')).hashCode,
      );
      expect(
        definition.subclass(SubclassId('champion')).toString(),
        'SubclassNotFound(champion)',
      );
    });

    /// Requirement: doc/specs/content-classes.md FR-074 - the lookup is
    ///   sealed with exactly the two variants, exhaustive in a `switch`.
    /// Path: happy
    test('the lookups switch exhaustively', () {
      String describe(SubclassLookup lookup) => switch (lookup) {
        SubclassFound() => 'found',
        SubclassNotFound() => 'not found',
      };
      expect(describe(definition.subclass(SubclassId('berserker'))), 'found');
      expect(
        describe(definition.subclass(SubclassId('champion'))),
        'not found',
      );
    });
  });

  /// Requirement: doc/specs/content-classes.md FR-056 - `subclassLevel` is
  ///   the level of the entry carrying `GrantsSubclass`.
  /// Path: happy
  test('subclassLevel is the GrantsSubclass entry level', () {
    expect(buildTestClass().subclassLevel, 3);
  });

  /// Requirement: doc/specs/content-classes.md FR-037 - progression holds
  ///   exactly 20 rows whose levels are their positions plus one (Cases PR
  ///   rows "exactly 20", "19 rows", "21 rows", "level out of order").
  /// Path: happy
  group('progression structure rows (Cases PR)', () {
    /// Requirement: per case
    /// Path: per case
    for (final c in [
      (
        label: '19 rows',
        requirement:
            'doc/specs/content-classes.md FR-037 - 19 rows are rejected '
            '(Cases PR: "19 rows")',
        path: 'unhappy (boundary)',
        rows: 19,
      ),
      (
        label: '21 rows',
        requirement:
            'doc/specs/content-classes.md FR-037 - 21 rows are rejected '
            '(Cases PR: "21 rows")',
        path: 'unhappy (boundary)',
        rows: 21,
      ),
    ]) {
      test('${c.label} [${c.path}]', () {
        final definition = buildTestClass();
        final rows = c.rows <= ProgressionRow.maxLevel
            ? definition.progression.sublist(0, c.rows)
            : [...definition.progression, definition.progression.last];
        expect(
          () => _assemble(progression: rows, features: definition.features),
          throwsArgumentErrorFor('progression', rows),
        );
      });
    }

    /// Requirement: doc/specs/content-classes.md FR-037 - a row whose level
    ///   is not its position plus one is rejected (Cases PR: "level out of
    ///   order").
    /// Path: unhappy (invalid input)
    test('a row out of level order is rejected', () {
      final rows = [
        for (var level = 1; level <= ProgressionRow.maxLevel; level++)
          ProgressionRow(
            level: level == 5 ? 6 : level,
            proficiencyBonus: fixtureProficiencyBonus(level),
            features: [
              if (level == 3) RowClassFeature(FeatureId('barbarian_subclass')),
            ],
            values: const {},
          ),
      ];
      expect(
        () => _assemble(progression: rows),
        throwsArgumentErrorFor('progression', 6),
      );
    });
  });

  /// Requirement: doc/specs/content-classes.md FR-039 - a row's values hold
  ///   exactly one entry per declared column (Cases PR rows "missing
  ///   column", "undeclared column").
  /// Path: happy
  group('values versus declared columns (Cases PR)', () {
    final rages = ClassColumn(
      id: ClassColumnId('rages'),
      header: 'Rages',
      kind: ClassColumnKind.count,
    );

    /// Requirement: doc/specs/content-classes.md FR-039 - a row's values
    ///   hold exactly one entry per declared column; a missing declared
    ///   column is rejected (Cases PR: "missing column").
    /// Path: unhappy (missing content)
    test('a row missing a declared column is rejected', () {
      final rows = _rowsReferencingDefaultFeatures(
        valuesByLevel: {
          for (var level = 2; level <= 20; level++)
            level: {ClassColumnId('rages'): ColumnCount(2)},
        },
      );
      expect(
        () => _assemble(progression: rows, columns: [rages]),
        throwsArgumentErrorFor('progression', ClassColumnId('rages')),
      );
    });

    /// Requirement: doc/specs/content-classes.md FR-039 - an undeclared key
    ///   is rejected (Cases PR: "undeclared column").
    /// Path: unhappy (invalid input)
    test('a row with an undeclared column is rejected', () {
      final rows = _rowsReferencingDefaultFeatures(
        valuesByLevel: {
          for (var level = 1; level <= 20; level++)
            level: {
              ClassColumnId('rages'): ColumnCount(2),
              if (level == 1) ClassColumnId('luck'): ColumnCount(1),
            },
        },
      );
      expect(
        () => _assemble(progression: rows, columns: [rages]),
        throwsArgumentErrorFor('progression', ClassColumnId('luck')),
      );
    });

    /// Requirement: doc/specs/content-classes.md FR-039 - a class with no
    ///   columns has empty values.
    /// Path: happy
    test('a class with no columns has empty row values', () {
      final definition = buildTestClass();
      for (final row in definition.progression) {
        expect(row.values, isEmpty);
      }
    });
  });

  /// Requirement: doc/specs/content-classes.md FR-040 - a column value must
  ///   suit the declared kind; `ColumnNone` is allowed for every kind.
  /// Path: happy
  group('column value versus kind (FR-040)', () {
    /// Requirement: doc/specs/content-classes.md FR-040 - the value must
    ///   suit the declared kind.
    /// Path: unhappy (invalid input)
    test('a value of the wrong kind is rejected', () {
      final dice = ClassColumn(
        id: ClassColumnId('martial_arts'),
        header: 'Martial Arts',
        kind: ClassColumnKind.dice,
      );
      expect(
        () => buildTestClass(
          columns: [dice],
          columnValue: (column, level) => ColumnCount(2),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    /// Requirement: doc/specs/content-classes.md FR-040 - `ColumnNone` is
    ///   allowed for every kind.
    /// Path: happy
    test('the em dash suits every kind', () {
      const none = ColumnNone();
      final matching = {
        ClassColumnKind.count: ColumnCount(2),
        ClassColumnKind.dice: ColumnDice(1, 6),
        ClassColumnKind.bonus: ColumnBonus(0),
        ClassColumnKind.feetBonus: const ColumnFeetBonus(10),
      };
      for (final kind in ClassColumnKind.values) {
        final column = ClassColumn(
          id: ClassColumnId('column_${kind.name.toLowerCase()}'),
          header: 'Column',
          kind: kind,
        );
        final dashed = buildTestClass(
          columns: [column],
          columnValue: (c, level) => none,
        );
        expect(dashed.rowAt(1).value(column.id), none);
        final suited = buildTestClass(
          columns: [column],
          columnValue: (c, level) => matching[kind]!,
        );
        expect(suited.rowAt(1).value(column.id), matching[kind]);
      }
    });
  });

  /// Requirement: doc/specs/content-classes.md FR-030, FR-031 - every row
  ///   carries the spellcasting part that matches the class, and a slot row
  ///   carries cantrips exactly when the class's flag is true (Cases SP
  ///   rows).
  /// Path: happy
  group('spellcasting row consistency (Cases SP)', () {
    SpellcastingRow pactPart(int level) => PactSpellcastingRow(
      cantrips: 2,
      preparedSpells: 1,
      spellSlots: 2,
      slotLevel: 1,
    );
    SpellcastingRow slotPartNoCantrips(int level) => SlotSpellcastingRow(
      preparedSpells: 4,
      spellSlots: [2, 0, 0, 0, 0, 0, 0, 0, 0],
    );
    SpellcastingRow slotPartCantrips(int level) => SlotSpellcastingRow(
      cantrips: 2,
      preparedSpells: 4,
      spellSlots: [2, 0, 0, 0, 0, 0, 0, 0, 0],
    );

    /// Requirement: per case
    /// Path: per case
    for (final c in [
      (
        label: 'pact row on slot class',
        requirement:
            'doc/specs/content-classes.md FR-030 - a Pact row on a slots '
            'class is rejected (Cases SP: "pact row on slot class")',
        path: 'unhappy (rule interaction)',
        spellcasting: const SlotSpellcastingTrait(
          Ability.intelligence,
          cantrips: true,
        ),
        rowPart: pactPart,
      ),
      (
        label: 'row part on a non-caster',
        requirement:
            'doc/specs/content-classes.md FR-030 - a row part on a class '
            'with no spellcasting is rejected (Cases SP: "row part on a '
            'non-caster")',
        path: 'unhappy (rule interaction)',
        spellcasting: null,
        rowPart: slotPartCantrips,
      ),
      (
        label: 'cantrips missing',
        requirement:
            'doc/specs/content-classes.md FR-031 - a row without cantrips '
            'on a class whose flag is true is rejected (Cases SP: "cantrips '
            'missing")',
        path: 'unhappy (missing content)',
        spellcasting: const SlotSpellcastingTrait(
          Ability.intelligence,
          cantrips: true,
        ),
        rowPart: slotPartNoCantrips,
      ),
      (
        label: 'cantrips on Paladin',
        requirement:
            'doc/specs/content-classes.md FR-031 - a row with cantrips on a '
            'class whose flag is false is rejected (Cases SP: "cantrips on '
            'Paladin")',
        path: 'unhappy (rule interaction)',
        spellcasting: const SlotSpellcastingTrait(
          Ability.charisma,
          cantrips: false,
        ),
        rowPart: slotPartCantrips,
      ),
    ]) {
      test('${c.label} [${c.path}]', () {
        expect(
          () => buildTestClass(
            spellcasting: c.spellcasting,
            rowSpellcasting: c.rowPart,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });
    }

    /// Requirement: doc/specs/content-classes.md FR-030 - a slots class
    ///   with matching rows constructs.
    /// Path: happy
    /// Requirement: doc/specs/content-classes.md FR-030 - a slots class's
    ///   rows carry slot spellcasting parts.
    /// Path: happy
    test('a slots class with matching rows constructs', () {
      final definition = buildTestClass(
        spellcasting: const SlotSpellcastingTrait(
          Ability.intelligence,
          cantrips: true,
        ),
      );
      expect(definition.rowAt(1).spellcasting, isA<SlotSpellcastingRow>());
    });

    /// Requirement: doc/specs/content-classes.md FR-030 - a slot row on a
    ///   pact class is rejected (the mirror of "pact row on slot class").
    /// Path: unhappy (rule interaction)
    test('a slot row on a pact class is rejected', () {
      expect(
        () => buildTestClass(
          spellcasting: const PactSpellcastingTrait(Ability.charisma),
          rowSpellcasting: (int level) => SlotSpellcastingRow(
            preparedSpells: 4,
            spellSlots: [2, 0, 0, 0, 0, 0, 0, 0, 0],
          ),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    /// Requirement: doc/specs/content-classes.md FR-030 - a pact class's
    ///   rows carry Pact spellcasting parts.
    /// Path: happy
    test('a pact class with matching rows constructs', () {
      final definition = buildTestClass(
        spellcasting: const PactSpellcastingTrait(Ability.charisma),
      );
      expect(definition.rowAt(1).spellcasting, isA<PactSpellcastingRow>());
    });
  });

  /// Requirement: doc/specs/content-classes.md FR-044 - every featureId of
  ///   a row names a feature entry of the same class, whose level does not
  ///   exceed the row's (Cases PR rows "unresolved feature", "entry later
  ///   than row").
  /// Path: happy
  group('row references (Cases PR)', () {
    /// Requirement: doc/specs/content-classes.md FR-044 - every featureId
    ///   of a row names a feature entry of the same class (Cases PR:
    ///   "unresolved feature").
    /// Path: unhappy (missing content)
    test('an unresolved feature id is rejected', () {
      expect(
        () => buildTestClass(
          rowFeatures: (level) => level == 1
              ? [RowClassFeature(FeatureId('barbarian_nothing'))]
              : null,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    /// Requirement: doc/specs/content-classes.md FR-044 - a cited entry
    ///   later than the row is rejected (Cases PR: "entry later than row").
    /// Path: unhappy (boundary)
    test('a cited entry later than the row is rejected', () {
      final rows = _rowsReferencingDefaultFeatures(
        featuresByLevel: {
          1: [
            RowClassFeature(FeatureId('barbarian_rage')),
            RowClassFeature(FeatureId('barbarian_late')),
          ],
        },
      );
      expect(
        () => _assemble(
          progression: rows,
          features: [
            _feature('barbarian_rage', 1),
            _feature('barbarian_late', 5),
            _feature('barbarian_subclass', 3, facts: [const GrantsSubclass()]),
            _feature(
              'barbarian_ability_score_improvement',
              4,
              facts: [const GrantsFeat(FeatCategory.general)],
            ),
          ],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    /// Requirement: doc/specs/content-classes.md FR-045 - every class
    ///   feature entry is referenced by the row at its own level (Cases PR:
    ///   "entry never listed").
    /// Path: unhappy (rule interaction)
    test('an entry never listed by its own row is rejected', () {
      final rows = _rowsReferencingDefaultFeatures();
      expect(
        () => _assemble(
          progression: rows,
          features: [
            _feature('barbarian_rage', 1),
            _feature('barbarian_unlisted', 2),
            _feature('barbarian_subclass', 3, facts: [const GrantsSubclass()]),
            _feature(
              'barbarian_ability_score_improvement',
              4,
              facts: [const GrantsFeat(FeatCategory.general)],
            ),
          ],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  /// Requirement: doc/specs/content-classes.md FR-052, FR-056 - a class
  ///   feature id is prefixed with the class id, and exactly one class
  ///   feature carries `GrantsSubclass` (Cases FT rows "two subclass
  ///   facts", "no subclass fact").
  /// Path: happy
  group('subclass-fact structure (Cases FT)', () {
    /// Requirement: doc/specs/content-classes.md FR-052 - a class feature
    ///   id is prefixed with the class's id.
    /// Path: unhappy (invalid input)
    test('a wrong feature id prefix is rejected', () {
      expect(
        () => buildTestClass(
          features: [
            _feature('fighter_rage', 1),
            _feature('barbarian_subclass', 3, facts: [const GrantsSubclass()]),
            _feature(
              'barbarian_ability_score_improvement',
              4,
              facts: [const GrantsFeat(FeatCategory.general)],
            ),
          ],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    /// Requirement: doc/specs/content-classes.md FR-056 - zero carriers are
    ///   rejected (Cases FT: "no subclass fact").
    /// Path: unhappy (missing content)
    test('no feature carrying GrantsSubclass is rejected', () {
      expect(
        () => buildTestClass(
          features: [
            _feature('barbarian_rage', 1),
            _feature(
              'barbarian_ability_score_improvement',
              4,
              facts: [const GrantsFeat(FeatCategory.general)],
            ),
          ],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    /// Requirement: doc/specs/content-classes.md FR-056 - two carriers are
    ///   rejected (Cases FT: "two subclass facts").
    /// Path: unhappy (rule interaction)
    test('two features carrying GrantsSubclass are rejected', () {
      expect(
        () => buildTestClass(
          features: [
            _feature('barbarian_rage', 1),
            _feature('barbarian_subclass', 3, facts: [const GrantsSubclass()]),
            _feature(
              'barbarian_second_subclass',
              5,
              facts: [const GrantsSubclass()],
            ),
            _feature(
              'barbarian_ability_score_improvement',
              4,
              facts: [const GrantsFeat(FeatCategory.general)],
            ),
          ],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  /// Requirement: doc/specs/content-classes.md FR-071, FR-072, FR-073 - a
  ///   subclass feature starts at the subclass level, one sits exactly
  ///   there, and its id is prefixed with the subclass id.
  /// Path: happy
  group('subclass validation rows', () {
    /// Requirement: doc/specs/content-classes.md FR-071 - a subclass
    ///   feature starts at the subclass level.
    /// Path: unhappy (boundary)
    test('a subclass feature below the subclass level is rejected', () {
      expect(
        () => buildTestClass(
          subclasses: [
            SubclassDefinition(
              id: SubclassId('berserker'),
              name: 'Path of the Berserker',
              features: [_feature('berserker_frenzy', 2)],
            ),
          ],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    /// Requirement: doc/specs/content-classes.md FR-071 - a subclass with
    ///   no feature at the subclass level is rejected.
    /// Path: unhappy (boundary)
    test('a subclass with no feature at the subclass level is rejected', () {
      expect(
        () => buildTestClass(
          subclasses: [
            SubclassDefinition(
              id: SubclassId('berserker'),
              name: 'Path of the Berserker',
              features: [_feature('berserker_frenzy', 6)],
            ),
          ],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    /// Requirement: doc/specs/content-classes.md FR-052, FR-072 - a
    ///   subclass feature id is prefixed with the subclass id.
    /// Path: unhappy (invalid input)
    test('a subclass feature id without the subclass prefix is rejected', () {
      expect(
        () => buildTestClass(
          subclasses: [
            SubclassDefinition(
              id: SubclassId('berserker'),
              name: 'Path of the Berserker',
              features: [_feature('barbarian_frenzy', 3)],
            ),
          ],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    /// Requirement: doc/specs/content-classes.md FR-070, FR-073 - a class
    ///   with no subclasses constructs (`"subclasses": []`).
    /// Path: happy
    test('a class with no subclasses constructs', () {
      expect(buildTestClass(subclasses: const []), isA<ClassDefinition>());
    });
  });

  /// Requirement: doc/specs/content-classes.md FR-026 - the multiclass
  ///   grants MUST NOT exceed the class's core traits (Cases FT rows
  ///   "multiclass exceeds core", "any-skill grant on a listed core").
  /// Path: happy
  group('multiclass subset rows (Cases FT)', () {
    /// Requirement: doc/specs/content-classes.md FR-026 - the multiclass
    ///   armor training is a subset of the class's own (Cases FT: "multiclass
    ///   exceeds core").
    /// Path: unhappy (rule interaction)
    test('armor training beyond the core is rejected', () {
      expect(
        () => buildTestClass(
          armorTraining: [ArmorTrainingCategory.light],
          multiclassGrants: MulticlassGrants(
            armorTraining: [ArmorTrainingCategory.heavy],
          ),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    /// Requirement: doc/specs/content-classes.md FR-026 - weapon training
    ///   beyond the core is rejected.
    /// Path: unhappy (rule interaction)
    test('weapon training beyond the core is rejected', () {
      expect(
        () => buildTestClass(
          weaponProficiencies: [
            WeaponProficiency(WeaponTrainingCategory.simple),
          ],
          multiclassGrants: MulticlassGrants(
            weaponProficiencies: [
              WeaponProficiency(WeaponTrainingCategory.martial),
            ],
          ),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    /// Requirement: doc/specs/content-classes.md FR-026 - an any-skill
    ///   grant needs an any-skill core (Cases FT: "any-skill grant on a
    ///   listed core").
    /// Path: unhappy (rule interaction)
    test('an any-skill grant on a listed core is rejected', () {
      expect(
        () => buildTestClass(
          skillChoice: SkillChoiceListed(2, [Skill.survival, Skill.athletics]),
          multiclassGrants: MulticlassGrants(skillChoice: SkillChoiceAny(2)),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    /// Requirement: doc/specs/content-classes.md FR-026 - listed skills
    ///   beyond the core's list are rejected.
    /// Path: unhappy (rule interaction)
    test('a listed skill beyond the core is rejected', () {
      expect(
        () => buildTestClass(
          skillChoice: SkillChoiceListed(2, [Skill.survival, Skill.athletics]),
          multiclassGrants: MulticlassGrants(
            skillChoice: SkillChoiceListed(1, [Skill.arcana]),
          ),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    /// Requirement: doc/specs/content-classes.md FR-026 - a tool choice
    ///   naming a category the core does not cover is rejected.
    /// Path: unhappy (rule interaction)
    test('a tool choice beyond the core is rejected', () {
      expect(
        () => buildTestClass(
          toolProficiencies: [
            ClassToolProficiencyChoice(['Musical Instrument'], 3),
          ],
          multiclassGrants: MulticlassGrants(
            toolProficiencies: [
              ClassToolProficiencyChoice(["Artisan's Tools"], 1),
            ],
          ),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    /// Requirement: doc/specs/content-classes.md FR-026 - picks beyond the
    ///   core picks are rejected.
    /// Path: unhappy (boundary)
    test('picks beyond the core picks are rejected', () {
      expect(
        () => buildTestClass(
          toolProficiencies: [
            ClassToolProficiencyChoice(['Musical Instrument'], 3),
          ],
          multiclassGrants: MulticlassGrants(
            toolProficiencies: [
              ClassToolProficiencyChoice(['Musical Instrument'], 4),
            ],
          ),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    /// Requirement: doc/specs/content-classes.md FR-026 - grants within the
    ///   core traits are accepted.
    /// Path: happy
    /// Requirement: doc/specs/content-classes.md FR-026 - grants within
    ///   the core traits are accepted.
    /// Path: happy
    test('grants within the core traits are accepted', () {
      final definition = buildTestClass(
        skillChoice: SkillChoiceListed(2, [Skill.survival, Skill.athletics]),
        armorTraining: [ArmorTrainingCategory.light],
        toolProficiencies: [
          ClassToolProficiencyChoice(['Musical Instrument'], 3),
        ],
        multiclassGrants: MulticlassGrants(
          weaponProficiencies: [
            WeaponProficiency(WeaponTrainingCategory.martial),
          ],
          armorTraining: [ArmorTrainingCategory.light],
          toolProficiencies: [
            ClassToolProficiencyChoice(['Musical Instrument'], 2),
          ],
          skillChoice: SkillChoiceListed(1, [Skill.survival]),
        ),
      );
      expect(definition.multiclassGrants.skillChoice, isNotNull);
    });

    /// Requirement: doc/specs/content-classes.md FR-026 - a listed grant on
    ///   an any-skill core is accepted; a specific tool grant covered by a
    ///   core choice is accepted.
    /// Path: happy
    /// Requirement: doc/specs/content-classes.md FR-026 - a listed grant
    ///   on an any-skill core is a subset, and a specific tool grant covered
    ///   by a core choice is accepted.
    /// Path: happy
    test(
      'a listed grant on an any core and a covered tool grant construct',
      () {
        final definition = buildTestClass(
          skillChoice: SkillChoiceAny(2),
          toolProficiencies: [
            ClassToolProficiencyChoice(['Musical Instrument'], 3),
          ],
          multiclassGrants: MulticlassGrants(
            skillChoice: SkillChoiceListed(1, [Skill.survival]),
            toolProficiencies: [
              ClassToolProficiencySpecific('Musical Instrument'),
            ],
          ),
        );
        expect(
          definition.multiclassGrants.skillChoice,
          isA<SkillChoiceListed>(),
        );
      },
    );
  });

  /// Requirement: doc/specs/content-classes.md FR-018 - saving throw
  ///   proficiencies hold from one to six distinct abilities.
  /// Path: happy
  group('saving throw rows', () {
    /// Requirement: per case
    /// Path: per case
    for (final c in [
      (
        label: 'seven saves',
        requirement:
            'doc/specs/content-classes.md FR-018 - seven saves are rejected',
        path: 'unhappy (boundary)',
        count: 7,
      ),
      (
        label: 'zero saves',
        requirement:
            'doc/specs/content-classes.md FR-018 - no saves are rejected',
        path: 'unhappy (boundary)',
        count: 0,
      ),
      (
        label: 'one save',
        requirement:
            'doc/specs/content-classes.md FR-018 - one save is accepted',
        path: 'unhappy (boundary)',
        count: 1,
      ),
      (
        label: 'six saves',
        requirement:
            'doc/specs/content-classes.md FR-018 - six saves are accepted',
        path: 'unhappy (boundary)',
        count: 6,
      ),
    ]) {
      test('${c.label} [${c.path}]', () {
        final abilities = [
          for (var i = 0; i < c.count; i++) Ability.values[i % 6],
        ];
        if (c.count < 1 || c.count > 6) {
          expect(
            () => buildTestClass(savingThrowProficiencies: abilities),
            throwsArgumentErrorFor('savingThrowProficiencies', abilities),
          );
        } else {
          expect(
            buildTestClass(savingThrowProficiencies: abilities),
            isA<ClassDefinition>(),
          );
        }
      });
    }

    /// Requirement: doc/specs/content-classes.md FR-018 - a repeated save is
    ///   rejected.
    /// Path: unhappy (boundary)
    test('a repeated save is rejected', () {
      expect(
        () => buildTestClass(
          savingThrowProficiencies: [Ability.strength, Ability.strength],
        ),
        throwsArgumentErrorFor('savingThrowProficiencies', Ability.strength),
      );
    });
  });

  /// Requirement: doc/specs/content-classes.md FR-022 - `armorTraining` is
  ///   an array of distinct `ArmorTrainingCategory` values; the class core
  ///   rejects a repeat.
  /// Path: unhappy (boundary)
  test('a repeated core armor training is rejected', () {
    expect(
      () => buildTestClass(
        armorTraining: [
          ArmorTrainingCategory.light,
          ArmorTrainingCategory.light,
        ],
      ),
      throwsArgumentErrorFor('armorTraining', ArmorTrainingCategory.light),
    );
    // A repeat is caught wherever it sits in the array.
    expect(
      () => buildTestClass(
        armorTraining: [
          ArmorTrainingCategory.light,
          ArmorTrainingCategory.medium,
          ArmorTrainingCategory.light,
        ],
      ),
      throwsArgumentErrorFor('armorTraining', ArmorTrainingCategory.light),
    );
  });

  /// Requirement: doc/specs/content-classes.md FR-021, FR-026 - the core
  ///   weapon proficiencies hold at most one per category; the class core
  ///   rejects a repeat.
  /// Path: unhappy (boundary)
  test('a repeated core weapon category is rejected', () {
    expect(
      () => buildTestClass(
        weaponProficiencies: [
          WeaponProficiency(WeaponTrainingCategory.martial),
          WeaponProficiency(WeaponTrainingCategory.martial),
        ],
      ),
      throwsA(
        isA<ArgumentError>().having(
          (e) => e.name,
          'name',
          'weaponProficiencies',
        ),
      ),
    );
  });

  /// Requirement: doc/specs/content-classes.md FR-022, FR-026 - the
  ///   multiclass grants use the FR-022 shape, so a repeated category is
  ///   rejected there too.
  /// Path: unhappy (boundary)
  test('a repeated multiclass armor training is rejected', () {
    expect(
      () => buildTestClass(
        armorTraining: [ArmorTrainingCategory.light],
        multiclassGrants: MulticlassGrants(
          armorTraining: [
            ArmorTrainingCategory.light,
            ArmorTrainingCategory.light,
          ],
        ),
      ),
      throwsA(isA<ArgumentError>()),
    );
  });

  /// Requirement: doc/specs/content-classes.md FR-026 - a specific tool
  ///   grant naming neither a core choice's category nor a core specific
  ///   tool exceeds the core.
  /// Path: unhappy (rule interaction)
  test('a specific tool grant beyond the core is rejected', () {
    expect(
      () => buildTestClass(
        toolProficiencies: [
          ClassToolProficiencyChoice(['Musical Instrument'], 3),
        ],
        multiclassGrants: MulticlassGrants(
          toolProficiencies: [ClassToolProficiencySpecific("Navigator's Pack")],
        ),
      ),
      throwsA(isA<ArgumentError>()),
    );
  });

  /// Requirement: doc/specs/content-classes.md FR-036 - two columns sharing
  ///   an id are rejected.
  /// Path: unhappy (boundary)
  test('duplicate column ids are rejected', () {
    final rages = ClassColumn(
      id: ClassColumnId('rages'),
      header: 'Rages',
      kind: ClassColumnKind.count,
    );
    final ragesAgain = ClassColumn(
      id: ClassColumnId('rages'),
      header: 'Rages per day',
      kind: ClassColumnKind.count,
    );
    expect(
      () => buildTestClass(columns: [rages, ragesAgain]),
      throwsArgumentErrorFor('columns', ClassColumnId('rages')),
    );
    // A repeat is caught wherever it sits in the list.
    final levels = ClassColumn(
      id: ClassColumnId('levels'),
      header: 'Levels',
      kind: ClassColumnKind.count,
    );
    expect(
      () => buildTestClass(columns: [rages, levels, ragesAgain]),
      throwsArgumentErrorFor('columns', ClassColumnId('rages')),
    );
    // Distinct columns are accepted, and every row carries a value for
    // each of them.
    expect(buildTestClass(columns: [rages, levels]), isA<ClassDefinition>());
  });

  /// Requirement: doc/specs/content-classes.md FR-038 - the bundled
  ///   Proficiency Bonus changes exactly at levels 5, 9, 13 and 17; the
  ///   fixture rows carry that shape and the row level is the position plus
  ///   one (FR-037).
  /// Path: happy
  test('fixture rows carry the Proficiency Bonus table and level order', () {
    final definition = buildTestClass();
    for (var level = 1; level <= 20; level++) {
      final row = definition.rowAt(level);
      expect(row.level, level);
      expect(row.proficiencyBonus, fixtureProficiencyBonus(level));
    }
    expect(definition.rowAt(4).proficiencyBonus, 2);
    expect(definition.rowAt(5).proficiencyBonus, 3);
    expect(definition.rowAt(8).proficiencyBonus, 3);
    expect(definition.rowAt(9).proficiencyBonus, 4);
    expect(definition.rowAt(12).proficiencyBonus, 4);
    expect(definition.rowAt(13).proficiencyBonus, 5);
    expect(definition.rowAt(16).proficiencyBonus, 5);
    expect(definition.rowAt(17).proficiencyBonus, 6);
  });

  /// Requirement: doc/specs/content-classes.md FR-002, FR-007 - the class
  ///   name field is validated like every name.
  /// Path: unhappy (invalid input)
  test('a blank class name is rejected', () {
    expect(
      () => buildTestClass(name: ' '),
      throwsArgumentErrorFor('name', ' '),
    );
  });

  /// Requirement: doc/specs/content-classes.md FR-026 - a specific-tool
  ///   core covers a grant naming the same tool.
  /// Path: happy
  test('a specific-tool core covers a naming grant', () {
    final definition = buildTestClass(
      toolProficiencies: [ClassToolProficiencySpecific('Thieves’ Tools')],
      multiclassGrants: MulticlassGrants(
        toolProficiencies: [
          ClassToolProficiencyChoice(['Thieves’ Tools'], 1),
        ],
      ),
    );
    expect(definition.multiclassGrants.toolProficiencies, hasLength(1));
  });

  /// Requirement: doc/specs/content-classes.md FR-008 - two instances built
  ///   from the same data are equal; the exposed collections are
  ///   unmodifiable and later mutation of the caller's input lists does not
  ///   change an instance.
  /// Path: unhappy (immutability)
  group('equality and immutability', () {
    /// Requirement: doc/specs/content-classes.md FR-008 - two instances
    ///   built from the same data are equal.
    /// Path: happy
    test('two instances from the same data are equal', () {
      final a = buildTestClass();
      final b = buildTestClass();
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a.toString(), 'ClassDefinition(barbarian)');
      expect(operatorEquals(a, Object()), isFalse);
    });

    /// Requirement: doc/specs/content-classes.md FR-008 - every exposed
    ///   collection is unmodifiable.
    /// Path: unhappy (immutability)
    test('exposed collections are unmodifiable', () {
      final definition = buildTestClass();
      expect(() => definition.progression.clear(), throwsUnsupportedError);
      expect(() => definition.features.clear(), throwsUnsupportedError);
      expect(
        () => definition.savingThrowProficiencies.clear(),
        throwsUnsupportedError,
      );
      expect(
        () => definition.weaponProficiencies.clear(),
        throwsUnsupportedError,
      );
      expect(
        () => definition.toolProficiencies.clear(),
        throwsUnsupportedError,
      );
      expect(() => definition.armorTraining.clear(), throwsUnsupportedError);
      expect(() => definition.columns.clear(), throwsUnsupportedError);
      expect(() => definition.subclasses.clear(), throwsUnsupportedError);
    });

    /// Requirement: doc/specs/content-classes.md FR-008 - later mutation
    ///   of a caller's input list does not change an instance.
    /// Path: unhappy (immutability)
    test('a mutated input list does not change the instance', () {
      final savingThrows = [Ability.strength, Ability.constitution];
      final definition = buildTestClass(savingThrowProficiencies: savingThrows);
      savingThrows.clear();
      expect(definition.savingThrowProficiencies.length, 2);
    });

    /// Requirement: doc/specs/content-classes.md FR-008 - instances built
    ///   from different data are not equal.
    /// Path: unhappy (immutability)
    test('an instance is not equal to one with a different core trait', () {
      expect(
        buildTestClass(),
        isNot(equals(buildTestClass(hitPointDie: HitPointDie.d10))),
      );
      expect(
        buildTestClass(),
        isNot(equals(buildTestClass(name: 'Berserker'))),
      );
    });
  });
}
