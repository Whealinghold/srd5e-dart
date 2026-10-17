import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import '../../../shared_kernel/ability/ability.dart';
import '../content_entry.dart';
import '../content_key.dart';
import '../content_reference.dart';
import '../feat_category.dart';
import '../hit_point_die.dart';
import '../named_text.dart';
import '../source_citation.dart';
import '../typed_ids.dart';
import 'ability_requirement.dart';
import 'armor_training_category.dart';
import 'class_column.dart';
import 'class_spellcasting_trait.dart';
import 'class_starting_equipment.dart';
import 'class_tool_proficiency.dart';
import 'column_value.dart';
import 'feature_entry.dart';
import 'feature_fact.dart';
import 'multiclass_grants.dart';
import 'progression_row.dart';
import 'skill_choice.dart';
import 'subclass_definition.dart';
import 'weapon_proficiency.dart';

/// The resolved view of one Features-table row: the row's class features
/// resolved to their entries, in printed order, and whether the row holds a
/// subclass marker (FR-048).
///
/// An entry may be older than the row: the Ability Score Improvement entry
/// lives once at level 4 and the level 8 row references it (D15).
@immutable
final class ResolvedRow {
  /// Creates the resolved row from a defensive copy of [entries].
  ResolvedRow({
    required List<FeatureEntry> entries,
    required this.hasSubclassFeature,
  }) : entries = List.unmodifiable(entries);

  /// The row's class features resolved to their entries, in printed order;
  /// unmodifiable (FR-048).
  final List<FeatureEntry> entries;

  /// Whether the row holds a [RowSubclassFeature] marker (FR-048).
  final bool hasSubclassFeature;

  @override
  bool operator ==(Object other) =>
      other is ResolvedRow &&
      other.hasSubclassFeature == hasSubclassFeature &&
      const ListEquality<FeatureEntry>().equals(other.entries, entries);

  @override
  int get hashCode => Object.hash(
    ResolvedRow,
    hasSubclassFeature,
    const ListEquality<FeatureEntry>().hash(entries),
  );

  @override
  String toString() =>
      'ResolvedRow(${entries.length} entries, '
      'subclass: $hasSubclassFeature)';
}

/// The lookup result of [ClassDefinition.entry]: the class feature of this
/// class, or the not-found detail (FR-099).
///
/// Sealed, exhaustive in a `switch` without a default. The variants carry
/// their data and are not generic names (shared-types-and-ownership.md
/// FR-017).
@immutable
sealed class FeatureEntryLookup {
  const FeatureEntryLookup();
}

/// [ClassDefinition.entry] found the class feature (FR-099).
@immutable
final class FeatureEntryFound extends FeatureEntryLookup {
  /// Wraps the found [entry].
  const FeatureEntryFound(this.entry);

  /// The class feature entry of this class.
  final FeatureEntry entry;

  @override
  bool operator ==(Object other) =>
      other is FeatureEntryFound && other.entry == entry;

  @override
  int get hashCode => Object.hash(FeatureEntryFound, entry);

  @override
  String toString() => 'FeatureEntryFound(${entry.id.id.value})';
}

/// [ClassDefinition.entry] found no class feature of this class under the
/// id — an unknown id, or a subclass feature id (subclass features are
/// reached through [ClassDefinition.subclass]) (FR-099).
@immutable
final class FeatureEntryNotFound extends FeatureEntryLookup {
  /// Carries the [id] that was not found.
  const FeatureEntryNotFound(this.id);

  /// The id that was not found.
  final FeatureId id;

  @override
  bool operator ==(Object other) =>
      other is FeatureEntryNotFound && other.id == id;

  @override
  int get hashCode => Object.hash(FeatureEntryNotFound, id);

  @override
  String toString() => 'FeatureEntryNotFound(${id.id.value})';
}

/// The lookup result of [ClassDefinition.subclass]: the subclass of this
/// class, or the not-found detail (FR-074).
///
/// Sealed, exhaustive in a `switch` without a default. The variants carry
/// their data and are not generic names (shared-types-and-ownership.md
/// FR-017).
@immutable
sealed class SubclassLookup {
  const SubclassLookup();
}

/// [ClassDefinition.subclass] found the subclass (FR-074).
@immutable
final class SubclassFound extends SubclassLookup {
  /// Wraps the found [subclass].
  const SubclassFound(this.subclass);

  /// The subclass of this class.
  final SubclassDefinition subclass;

  @override
  bool operator ==(Object other) =>
      other is SubclassFound && other.subclass == subclass;

  @override
  int get hashCode => Object.hash(SubclassFound, subclass);

  @override
  String toString() => 'SubclassFound(${subclass.id.id.value})';
}

/// [ClassDefinition.subclass] found no subclass of this class under the id
/// (FR-074).
@immutable
final class SubclassNotFound extends SubclassLookup {
  /// Carries the [id] that was not found.
  const SubclassNotFound(this.id);

  /// The id that was not found.
  final SubclassId id;

  @override
  bool operator ==(Object other) => other is SubclassNotFound && other.id == id;

  @override
  int get hashCode => Object.hash(SubclassNotFound, id);

  @override
  String toString() => 'SubclassNotFound(${id.id.value})';
}

/// A character class ("Classes", SRD 5.2.1, pp. 28-82) as one content entry
/// of kind `ContentKind.characterClass` (FR-001, FR-002).
///
/// A class carries its core traits (primary ability, Hit Point Die, saving
/// throws, skill choice, weapon, tool and armor training, starting
/// equipment, multiclass grants, optional spellcasting trait), the
/// class-specific columns it declares, the 20 rows of its Features table and
/// its feature entries, and its nested subclasses. The spell ids of its
/// `AlwaysPreparedSpells` facts are the whole-set reference sites of
/// R1-classes-spell-sites. The constructor enforces
/// the cross-entry rules the single types cannot see: the row and reference
/// structure (FR-037, FR-039, FR-044, FR-045), the spellcasting rule
/// (FR-030, FR-031), the subclass feature (FR-056, FR-071, FR-072, FR-073),
/// the owner prefixes (FR-052) and the multiclass subset rule (FR-026).
@immutable
final class ClassDefinition implements ContentEntry, ContentReferences {
  /// Creates a class from defensive copies of the collection fields.
  ///
  /// Throws an [ArgumentError] carrying the name of the offending field and
  /// the offending value when a field breaks its own type's rules, when
  /// [name] breaks the name rule, [savingThrowProficiencies] does not hold
  /// [minSavingThrowProficiencies] to [maxSavingThrowProficiencies] distinct
  /// abilities (FR-018), [armorTraining] repeats a category (FR-022), two
  /// [columns] share an id (FR-036), [progression] does not hold exactly
  /// [rowCount] rows whose levels are their positions plus one (FR-037), a
  /// row's values do not match the declared columns (FR-039) or their kind
  /// (FR-040), the cross-entry rules named above fail, or a subclass breaks
  /// the subclass rules (FR-071, FR-072, FR-073).
  ClassDefinition({
    required this.id,
    required String name,
    this.source,
    required this.primaryAbility,
    required this.hitPointDie,
    required List<Ability> savingThrowProficiencies,
    required this.skillChoice,
    required List<WeaponProficiency> weaponProficiencies,
    required List<ClassToolProficiency> toolProficiencies,
    required List<ArmorTrainingCategory> armorTraining,
    required this.startingEquipment,
    required this.multiclassGrants,
    this.spellcasting,
    required List<ClassColumn> columns,
    required List<ProgressionRow> progression,
    required List<FeatureEntry> features,
    required List<SubclassDefinition> subclasses,
  }) : name = _validatedName(name),
       savingThrowProficiencies = List.unmodifiable(
         _validatedSavingThrowProficiencies(savingThrowProficiencies),
       ),
       weaponProficiencies = List.unmodifiable(weaponProficiencies),
       toolProficiencies = List.unmodifiable(toolProficiencies),
       armorTraining = Set.unmodifiable(_validatedArmorTraining(armorTraining)),
       columns = List.unmodifiable(columns),
       progression = List.unmodifiable(progression),
       features = List.unmodifiable(features),
       subclasses = List.unmodifiable(subclasses) {
    WeaponProficiency.requireUniqueCategories(weaponProficiencies);
    _featuresById = {for (final feature in features) feature.id: feature};
    _columnsById = {for (final column in columns) column.id: column};
    _validateColumns(this.columns);
    _validateRows(progression, columns);
    _validateFeatures();
    _validateSpellcasting();
    _validateMulticlassGrants();
    _validateSubclasses();
  }

  /// The fewest saving throw proficiencies a class may hold: one (FR-018).
  /// The constant the decoder reuses instead of repeating the literal
  /// (FR-007).
  static const int minSavingThrowProficiencies = 1;

  /// The most saving throw proficiencies a class may hold: six (FR-018).
  /// The constant the decoder reuses instead of repeating the literal
  /// (FR-007).
  static const int maxSavingThrowProficiencies = 6;

  /// How many rows a Features table holds: one per level 1 to 20 (FR-037).
  /// The constant the decoder reuses instead of repeating the literal
  /// (FR-007).
  static const int rowCount = 20;

  /// The class's id, as a typed id.
  final ClassId id;

  /// The class's printed name, verbatim ("Barbarian", "Wizard").
  final String name;

  /// Where the entry comes from, or null when the supplying document omits
  /// it (schema FR-034).
  final SourceCitation? source;

  /// The Primary Ability: all of the listed abilities, or any one of them
  /// (FR-011 to FR-015).
  final AbilityRequirement primaryAbility;

  /// The class's Hit Point Die (FR-017).
  final HitPointDie hitPointDie;

  /// The saving throw proficiencies, in printed order; unmodifiable, one to
  /// six distinct abilities (FR-018).
  final List<Ability> savingThrowProficiencies;

  /// The skill proficiency choice (FR-019).
  final SkillChoice skillChoice;

  /// The weapon proficiencies, at most one per category (FR-021);
  /// unmodifiable, possibly empty.
  final List<WeaponProficiency> weaponProficiencies;

  /// The tool proficiencies; unmodifiable, possibly empty (FR-023).
  final List<ClassToolProficiency> toolProficiencies;

  /// The armor training, the printed "None" being an explicit empty set;
  /// unmodifiable, all distinct (FR-022).
  final Set<ArmorTrainingCategory> armorTraining;

  /// The starting-equipment options (FR-024).
  final ClassStartingEquipment startingEquipment;

  /// The multiclass grants; MUST NOT exceed the core traits, which the
  /// constructor checks (FR-026).
  final MulticlassGrants multiclassGrants;

  /// The spellcasting trait, or null when the class has none (FR-028).
  final ClassSpellcastingTrait? spellcasting;

  /// The class-specific columns, in printed left-to-right order;
  /// unmodifiable, possibly empty, ids unique (FR-036).
  final List<ClassColumn> columns;

  /// The Features-table rows, one per level [ProgressionRow.minLevel] to
  /// [ProgressionRow.maxLevel] in order; unmodifiable (FR-037).
  final List<ProgressionRow> progression;

  /// The class feature entries, in document order (ascending level, then
  /// printed order, as FR-051 describes); unmodifiable.
  final List<FeatureEntry> features;

  /// The subclasses, possibly empty; unmodifiable (FR-070, FR-073).
  final List<SubclassDefinition> subclasses;

  late final int _subclassLevel;
  late final Map<FeatureId, FeatureEntry> _featuresById;
  late final Map<ClassColumnId, ClassColumn> _columnsById;

  @override
  ContentKey get key => id.key;

  /// The level of the feature entry carrying [GrantsSubclass] — the level
  /// every subclass feature starts at (FR-056).
  int get subclassLevel => _subclassLevel;

  /// Whether [level] is a level the accessors accept: from
  /// [ProgressionRow.minLevel] to [ProgressionRow.maxLevel] (FR-047,
  /// FR-048). The predicate the decoder reuses (FR-007).
  static bool isValidLevel(int level) =>
      level >= ProgressionRow.minLevel && level <= ProgressionRow.maxLevel;

  void _requireLevel(int level) {
    if (!isValidLevel(level)) {
      throw ArgumentError.value(
        level,
        'level',
        'must be from ${ProgressionRow.minLevel} to '
            '${ProgressionRow.maxLevel}',
      );
    }
  }

  /// The Features-table row of [level] (FR-047).
  ///
  /// Throws an [ArgumentError] carrying the name `level` and the offending
  /// value for 0, 21 and any value outside
  /// [ProgressionRow.minLevel] to [ProgressionRow.maxLevel].
  ProgressionRow rowAt(int level) {
    _requireLevel(level);
    return progression[level - 1];
  }

  /// The class feature entries gained at [level], in printed order — an
  /// empty list for a level with none, the Barbarian's level 6 for example
  /// (FR-048; SRD 5.2.1, "Becoming a ...", p. 28).
  ///
  /// Throws an [ArgumentError] carrying the name `level` and the offending
  /// value outside [ProgressionRow.minLevel] to [ProgressionRow.maxLevel].
  List<FeatureEntry> entriesGainedAt(int level) {
    _requireLevel(level);
    return List.unmodifiable([
      for (final feature in features)
        if (feature.level == level) feature,
    ]);
  }

  /// The resolved view of the row of [level] (FR-048): the row's class
  /// features resolved to their entries in printed order — an entry
  /// possibly older than the row, Ability Score Improvement at level 8 —
  /// and whether the row holds a subclass marker.
  ///
  /// Throws an [ArgumentError] carrying the name `level` and the offending
  /// value outside [ProgressionRow.minLevel] to [ProgressionRow.maxLevel].
  ResolvedRow rowFeatures(int level) {
    _requireLevel(level);
    final row = progression[level - 1];
    final entries = <FeatureEntry>[];
    var hasSubclassFeature = false;
    for (final rowFeature in row.features) {
      switch (rowFeature) {
        case RowClassFeature(:final featureId):
          entries.add(_featuresById[featureId]!);
        case RowSubclassFeature():
          hasSubclassFeature = true;
      }
    }
    return ResolvedRow(
      entries: entries,
      hasSubclassFeature: hasSubclassFeature,
    );
  }

  /// The [FeatCategory] of every [GrantsFeat] fact among the row's resolved
  /// features: Ability Score Improvement (General) at 4, 8, 12 and 16 for
  /// most classes, at 6 and 14 as well for Fighter and at 10 for Rogue
  /// (FR-049).
  ///
  /// Throws an [ArgumentError] carrying the name `level` and the offending
  /// value outside [ProgressionRow.minLevel] to [ProgressionRow.maxLevel].
  List<FeatCategory> featGrantsAt(int level) {
    // mutate4dart: ignore remove_call // masked: rowFeatures re-checks the level, so the same error still throws.
    _requireLevel(level);
    final resolved = rowFeatures(level);
    return List.unmodifiable([
      for (final entry in resolved.entries)
        for (final fact in entry.facts)
          if (fact is GrantsFeat) fact.category,
    ]);
  }

  /// The declared column named [id] (FR-050).
  ///
  /// Throws an [ArgumentError] carrying the name `id` and the offending id
  /// when the class declares no column under it.
  ClassColumn column(ClassColumnId id) {
    final column = _columnsById[id];
    if (column == null) {
      throw ArgumentError.value(id, 'id', 'is not a declared column');
    }
    return column;
  }

  /// The class feature of this class named [id], or the not-found detail —
  /// a subclass feature id is not found; subclass features are reached
  /// through [subclass] (FR-099).
  FeatureEntryLookup entry(FeatureId id) {
    final entry = _featuresById[id];
    return entry == null ? FeatureEntryNotFound(id) : FeatureEntryFound(entry);
  }

  /// The subclass of this class named [id], or the not-found detail
  /// (FR-074).
  SubclassLookup subclass(SubclassId id) {
    for (final subclass in subclasses) {
      if (subclass.id == id) return SubclassFound(subclass);
    }
    return SubclassNotFound(id);
  }

  /// The reference sites the revision row R1-classes-spell-sites registers
  /// (content-classes.md FR-059; schema FR-126): every spell id of an
  /// `AlwaysPreparedSpells` fact on a class feature, a subclass feature or
  /// a feature option, a whole-set site with no constraint. The field is
  /// the site's path inside the class entry; the order is document order —
  /// class features, then subclass features (FR-127).
  @override
  Iterable<ContentReference> get references => [
    for (var fi = 0; fi < features.length; fi++)
      ..._factSites('features/$fi', features[fi]),
    for (var s = 0; s < subclasses.length; s++)
      for (var fi = 0; fi < subclasses[s].features.length; fi++)
        ..._factSites('subclasses/$s/features/$fi', subclasses[s].features[fi]),
  ];

  /// The spell-id sites of one feature entry's facts and option facts.
  static Iterable<ContentReference> _factSites(
    String path,
    FeatureEntry feature,
  ) sync* {
    for (var k = 0; k < feature.facts.length; k++) {
      final fact = feature.facts[k];
      if (fact is! AlwaysPreparedSpells) continue;
      for (var g = 0; g < fact.grants.length; g++) {
        for (var n = 0; n < fact.grants[g].spellIds.length; n++) {
          yield ContentReference(
            '$path/facts/$k/grants/$g/spellIds/$n',
            fact.grants[g].spellIds[n].key,
          );
        }
      }
    }
    for (var o = 0; o < feature.options.length; o++) {
      final option = feature.options[o];
      for (var k = 0; k < option.facts.length; k++) {
        final fact = option.facts[k];
        if (fact is! AlwaysPreparedSpells) continue;
        for (var g = 0; g < fact.grants.length; g++) {
          for (var n = 0; n < fact.grants[g].spellIds.length; n++) {
            yield ContentReference(
              '$path/options/$o/facts/$k/grants/$g/spellIds/$n',
              fact.grants[g].spellIds[n].key,
            );
          }
        }
      }
    }
  }

  static String _validatedName(String name) {
    if (!NamedText.isValidName(name)) {
      throw ArgumentError.value(
        name,
        'name',
        'must be non-empty with no leading or trailing whitespace',
      );
    }
    return name;
  }

  static List<Ability> _validatedSavingThrowProficiencies(
    List<Ability> savingThrowProficiencies,
  ) {
    if (savingThrowProficiencies.length < minSavingThrowProficiencies ||
        savingThrowProficiencies.length > maxSavingThrowProficiencies) {
      throw ArgumentError.value(
        savingThrowProficiencies,
        'savingThrowProficiencies',
        'must hold from $minSavingThrowProficiencies to '
            '$maxSavingThrowProficiencies abilities',
      );
    }
    for (var i = 1; i < savingThrowProficiencies.length; i++) {
      if (savingThrowProficiencies.indexOf(savingThrowProficiencies[i]) != i) {
        throw ArgumentError.value(
          savingThrowProficiencies[i],
          'savingThrowProficiencies',
          'must be distinct',
        );
      }
    }
    return savingThrowProficiencies;
  }

  static List<ArmorTrainingCategory> _validatedArmorTraining(
    List<ArmorTrainingCategory> armorTraining,
  ) {
    for (var i = 1; i < armorTraining.length; i++) {
      if (armorTraining.indexOf(armorTraining[i]) != i) {
        throw ArgumentError.value(
          armorTraining[i],
          'armorTraining',
          'must be distinct',
        );
      }
    }
    return armorTraining;
  }

  static void _validateColumns(List<ClassColumn> columns) {
    for (var i = 1; i < columns.length; i++) {
      final id = columns[i].id;
      if (columns.sublist(0, i).any((column) => column.id == id)) {
        throw ArgumentError.value(
          id,
          'columns',
          'must hold at most one column per id (FR-036)',
        );
      }
    }
  }

  void _validateRows(
    List<ProgressionRow> progression,
    List<ClassColumn> columns,
  ) {
    if (progression.length != rowCount) {
      throw ArgumentError.value(
        progression,
        'progression',
        'must hold exactly $rowCount rows, one per level (FR-037)',
      );
    }
    for (var i = 0; i < progression.length; i++) {
      final row = progression[i];
      if (row.level != i + 1) {
        throw ArgumentError.value(
          row.level,
          'progression',
          // mutate4dart: ignore arithmetic // debug message text only: architecture.md §6, tests assert name and value, never message text.
          'row $i must carry level ${i + 1} (FR-037)',
        );
      }
      for (final column in columns) {
        if (!row.values.containsKey(column.id)) {
          throw ArgumentError.value(
            column.id,
            'progression',
            'row ${row.level} holds no value for the declared column '
                '${column.id.value} (FR-039)',
          );
        }
      }
      for (final entry in row.values.entries) {
        if (!columns.any((column) => column.id == entry.key)) {
          throw ArgumentError.value(
            entry.key,
            'progression',
            'row ${row.level} holds a value for the undeclared column '
                '${entry.key.value} (FR-039)',
          );
        }
        if (!_valueSuitsKind(entry.value, _columnsById[entry.key]!.kind)) {
          throw ArgumentError.value(
            entry.value,
            'progression',
            'the value does not suit the ${_columnsById[entry.key]!.kind.name} '
                'column (FR-040)',
          );
        }
      }
    }
  }

  static bool _valueSuitsKind(ColumnValue value, ClassColumnKind kind) =>
      switch (value) {
        ColumnNone() => true,
        ColumnCount() => kind == ClassColumnKind.count,
        ColumnDice() => kind == ClassColumnKind.dice,
        ColumnBonus() => kind == ClassColumnKind.bonus,
        ColumnFeetBonus() => kind == ClassColumnKind.feetBonus,
      };

  void _validateFeatures() {
    // FR-052: a class feature id is prefixed with the class's id.
    final prefix = '${id.id.value}_';
    for (final feature in features) {
      if (!feature.id.id.value.startsWith(prefix)) {
        throw ArgumentError.value(
          feature.id,
          'features',
          'a class feature id must be prefixed with `$prefix` (FR-052)',
        );
      }
    }
    // FR-056: exactly one class feature carries GrantsSubclass.
    final carriers = [
      for (final feature in features)
        if (feature.facts.any((fact) => fact is GrantsSubclass)) feature,
    ];
    if (carriers.length != 1) {
      throw ArgumentError.value(
        features,
        'features',
        'must hold exactly one feature carrying GrantsSubclass, found '
            '${carriers.length} (FR-056)',
      );
    }
    _subclassLevel = carriers.single.level;
    // FR-044: every row's featureId names a feature entry of this class,
    // whose level does not exceed the row's.
    for (final row in progression) {
      for (final rowFeature in row.features) {
        if (rowFeature is! RowClassFeature) continue;
        final entry = _featuresById[rowFeature.featureId];
        if (entry == null) {
          throw ArgumentError.value(
            rowFeature.featureId,
            'progression',
            'the row of level ${row.level} cites an unknown feature id '
                '(FR-044)',
          );
        }
        if (entry.level > row.level) {
          throw ArgumentError.value(
            rowFeature.featureId,
            'progression',
            'the cited feature entry is of level ${entry.level}, above the '
                'row\'s ${row.level} (FR-044)',
          );
        }
      }
    }
    // FR-045: every class feature entry is referenced by the row at its own
    // level.
    for (final feature in features) {
      final row = progression[feature.level - 1];
      final referenced = row.features.any(
        (rowFeature) =>
            rowFeature is RowClassFeature && rowFeature.featureId == feature.id,
      );
      if (!referenced) {
        throw ArgumentError.value(
          feature.id,
          'features',
          'the feature entry of level ${feature.level} is not referenced by '
              'the row at its own level (FR-045)',
        );
      }
    }
  }

  void _validateSpellcasting() {
    // FR-030: every row carries the spellcasting part that matches the
    // class; FR-031: a slot row carries cantrips exactly when the class's
    // cantrips flag is true.
    if (spellcasting == null) {
      for (final row in progression) {
        if (row.spellcasting != null) {
          throw ArgumentError.value(
            row.spellcasting,
            'progression',
            'the row of level ${row.level} carries a spellcasting part on a '
                'class with no spellcasting (FR-030)',
          );
        }
      }
      return;
    }
    switch (spellcasting!) {
      case SlotSpellcastingTrait(:final cantrips):
        for (final row in progression) {
          final part = row.spellcasting;
          if (part is! SlotSpellcastingRow) {
            throw ArgumentError.value(
              part,
              'progression',
              'the row of level ${row.level} must carry a slot spellcasting '
                  'row on a slots class (FR-030)',
            );
          }
          if (cantrips && part.cantrips == null) {
            throw ArgumentError.value(
              row,
              'progression',
              'the row of level ${row.level} carries no cantrips on a class '
                  'whose cantrips flag is true (FR-031)',
            );
          }
          if (!cantrips && part.cantrips != null) {
            throw ArgumentError.value(
              part.cantrips,
              'progression',
              'the row of level ${row.level} carries cantrips on a class '
                  'whose cantrips flag is false (FR-031)',
            );
          }
        }
      case PactSpellcastingTrait():
        for (final row in progression) {
          if (row.spellcasting is! PactSpellcastingRow) {
            throw ArgumentError.value(
              row.spellcasting,
              'progression',
              'the row of level ${row.level} must carry a Pact spellcasting '
                  'row on a pact class (FR-030)',
            );
          }
        }
    }
  }

  void _validateMulticlassGrants() {
    // FR-026: the grants MUST NOT exceed the class's core traits. A weapon
    // grant is within the core when a core proficiency of the same category
    // covers every weapon the grant covers, filter included.
    for (final proficiency in multiclassGrants.weaponProficiencies) {
      final covered = weaponProficiencies.any(
        (core) => WeaponProficiency.covers(core, proficiency),
      );
      if (!covered) {
        throw ArgumentError.value(
          proficiency,
          'multiclassGrants',
          'the weapon training must be a subset of the class\'s own '
              '(FR-026)',
        );
      }
    }
    for (final training in multiclassGrants.armorTraining) {
      if (!armorTraining.contains(training)) {
        throw ArgumentError.value(
          training,
          'multiclassGrants',
          'the armor training must be a subset of the class\'s own (FR-026)',
        );
      }
    }
    final grantsSkillChoice = multiclassGrants.skillChoice;
    if (grantsSkillChoice != null) {
      switch (grantsSkillChoice) {
        case SkillChoiceAny():
          if (skillChoice is! SkillChoiceAny) {
            throw ArgumentError.value(
              grantsSkillChoice,
              'multiclassGrants',
              'an any-skill grant needs an any-skill core (FR-026)',
            );
          }
        case SkillChoiceListed(:final skills):
          final core = skillChoice;
          if (core is SkillChoiceListed) {
            for (final skill in skills) {
              if (!core.skills.contains(skill)) {
                throw ArgumentError.value(
                  skill,
                  'multiclassGrants',
                  'the listed skills must be a subset of the class\'s own '
                      '(FR-026)',
                );
              }
            }
          }
      }
    }
    final coreCategoriesOfChoices = <String>{
      for (final proficiency in toolProficiencies)
        if (proficiency is ClassToolProficiencyChoice)
          ...proficiency.categories,
    };
    final coreSpecificTools = <String>{
      for (final proficiency in toolProficiencies)
        if (proficiency is ClassToolProficiencySpecific) proficiency.name,
    };
    var coreMaxPicks = 0;
    for (final proficiency in toolProficiencies) {
      final picks = switch (proficiency) {
        ClassToolProficiencyChoice() => proficiency.picks,
        ClassToolProficiencySpecific() => 1,
      };
      // mutate4dart: ignore relational_boundary // equivalent maximum: re-assigning on equality yields the same maximum.
      if (picks > coreMaxPicks) coreMaxPicks = picks;
    }
    for (final proficiency in multiclassGrants.toolProficiencies) {
      switch (proficiency) {
        case ClassToolProficiencySpecific(:final name):
          if (!coreCategoriesOfChoices.contains(name) &&
              !coreSpecificTools.contains(name)) {
            throw ArgumentError.value(
              proficiency,
              'multiclassGrants',
              'the tool proficiency must name a category of a core choice or '
                  'a core specific tool (FR-026)',
            );
          }
        case ClassToolProficiencyChoice(:final categories, :final picks):
          for (final category in categories) {
            if (!coreCategoriesOfChoices.contains(category) &&
                !coreSpecificTools.contains(category)) {
              throw ArgumentError.value(
                category,
                'multiclassGrants',
                'the tool choice must name only categories of a core choice '
                    'or a core specific tool (FR-026)',
              );
            }
          }
          if (picks > coreMaxPicks) {
            throw ArgumentError.value(
              proficiency,
              'multiclassGrants',
              'the picks must not exceed the core picks (FR-026)',
            );
          }
      }
    }
  }

  void _validateSubclasses() {
    // FR-056: a subclass feature MUST NOT carry GrantsSubclass; FR-071: the
    // subclass features start at the class's subclassLevel; FR-052, FR-072:
    // a subclass feature id is prefixed with its subclass's id.
    for (final subclass in subclasses) {
      final subclassPrefix = '${subclass.id.id.value}_';
      var atSubclassLevel = false;
      for (final feature in subclass.features) {
        if (!feature.id.id.value.startsWith(subclassPrefix)) {
          throw ArgumentError.value(
            feature.id,
            'subclasses',
            'a subclass feature id must be prefixed with '
                '`$subclassPrefix` (FR-052, FR-072)',
          );
        }
        if (feature.facts.any((fact) => fact is GrantsSubclass)) {
          throw ArgumentError.value(
            feature.id,
            'subclasses',
            'a subclass feature must not carry GrantsSubclass (FR-056)',
          );
        }
        if (feature.level < subclassLevel) {
          throw ArgumentError.value(
            feature.id,
            'subclasses',
            'a subclass feature of level ${feature.level} is below the '
                'subclass level $subclassLevel (FR-071)',
          );
        }
        if (feature.level == subclassLevel) atSubclassLevel = true;
      }
      if (subclass.features.isNotEmpty && !atSubclassLevel) {
        throw ArgumentError.value(
          subclass.id,
          'subclasses',
          'the subclass must have at least one feature at the subclass '
              'level $subclassLevel (FR-071)',
        );
      }
    }
  }

  @override
  bool operator ==(Object other) =>
      other is ClassDefinition &&
      other.id == id &&
      other.name == name &&
      other.source == source &&
      other.primaryAbility == primaryAbility &&
      other.hitPointDie == hitPointDie &&
      const ListEquality<Ability>().equals(
        other.savingThrowProficiencies,
        savingThrowProficiencies,
      ) &&
      other.skillChoice == skillChoice &&
      const ListEquality<WeaponProficiency>().equals(
        other.weaponProficiencies,
        weaponProficiencies,
      ) &&
      const ListEquality<ClassToolProficiency>().equals(
        other.toolProficiencies,
        toolProficiencies,
      ) &&
      const SetEquality<ArmorTrainingCategory>().equals(
        other.armorTraining,
        armorTraining,
      ) &&
      other.startingEquipment == startingEquipment &&
      other.multiclassGrants == multiclassGrants &&
      other.spellcasting == spellcasting &&
      const ListEquality<ClassColumn>().equals(other.columns, columns) &&
      const ListEquality<ProgressionRow>().equals(
        other.progression,
        progression,
      ) &&
      const ListEquality<FeatureEntry>().equals(other.features, features) &&
      const ListEquality<SubclassDefinition>().equals(
        other.subclasses,
        subclasses,
      );

  @override
  int get hashCode => Object.hash(
    ClassDefinition,
    id,
    name,
    source,
    primaryAbility,
    hitPointDie,
    const ListEquality<Ability>().hash(savingThrowProficiencies),
    skillChoice,
    const ListEquality<WeaponProficiency>().hash(weaponProficiencies),
    const ListEquality<ClassToolProficiency>().hash(toolProficiencies),
    const SetEquality<ArmorTrainingCategory>().hash(armorTraining),
    startingEquipment,
    multiclassGrants,
    spellcasting,
    const ListEquality<ClassColumn>().hash(columns),
    const ListEquality<ProgressionRow>().hash(progression),
    const ListEquality<FeatureEntry>().hash(features),
    const ListEquality<SubclassDefinition>().hash(subclasses),
  );

  @override
  String toString() => 'ClassDefinition(${id.id.value})';
}
