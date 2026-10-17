import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import '../named_text.dart';
import '../typed_ids.dart';
import 'class_column.dart';
import 'column_value.dart';

/// One element of a Features-table row's "Class Features" cell (FR-043).
///
/// The family is sealed with exactly the two variants, exhaustive in a
/// `switch` without a default: a named class feature, optionally annotated
/// with the printed parenthetical, and the marker that says the subclass
/// supplies the feature ("Subclass feature" cell).
@immutable
sealed class RowFeature {
  const RowFeature();
}

/// A row's reference to a class feature entry of the same class, optionally
/// annotated with the printed parenthetical ("Action Surge (one use)")
/// (FR-043; SRD 5.2.1, "Fighter Features", p. 47).
@immutable
final class RowClassFeature extends RowFeature {
  /// Creates the reference.
  ///
  /// Throws an [ArgumentError] carrying the name `annotation` and the
  /// offending value when [annotation] is present but blank (FR-043).
  RowClassFeature(this.featureId, {String? annotation})
    : annotation = _validatedAnnotation(annotation);

  /// The id of the class feature entry, of the same class (FR-044).
  final FeatureId featureId;

  /// The printed parenthetical without its brackets ("one use"), or null
  /// when the cell prints none; non-blank when present (FR-043).
  final String? annotation;

  /// Whether [annotation] is an annotation a row reference may carry:
  /// absent or non-blank (FR-043). The predicate the decoder reuses (FR-007).
  static bool isValidAnnotation(String? annotation) =>
      annotation == null || NamedText.isValidText(annotation);

  static String? _validatedAnnotation(String? annotation) {
    if (!isValidAnnotation(annotation)) {
      throw ArgumentError.value(
        annotation,
        'annotation',
        'must be absent or non-blank',
      );
    }
    return annotation;
  }

  @override
  bool operator ==(Object other) =>
      other is RowClassFeature &&
      other.featureId == featureId &&
      other.annotation == annotation;

  @override
  int get hashCode => Object.hash(RowClassFeature, featureId, annotation);

  @override
  String toString() =>
      'RowClassFeature(${featureId.id.value}'
      '${annotation == null ? '' : ', $annotation'})';
}

/// The marker that says the subclass supplies this row's feature ("Subclass
/// feature" cell); the subclass carries the entry (FR-043).
@immutable
final class RowSubclassFeature extends RowFeature {
  /// Creates the marker; every instance equals every other.
  const RowSubclassFeature();

  @override
  bool operator ==(Object other) => other is RowSubclassFeature;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'RowSubclassFeature';
}

/// The spellcasting part of a Features-table row (FR-030, FR-031, FR-032).
///
/// The family is sealed with exactly the two variants, exhaustive in a
/// `switch` without a default. The variant must match the class's
/// spellcasting rule (FR-030): a `SlotSpellcastingRow` on a `slots` class, a
/// `PactSpellcastingRow` on a `pact` class, and no part at all on a class
/// with no spellcasting — checked by the [ClassDefinition] constructor.
@immutable
sealed class SpellcastingRow {
  const SpellcastingRow();
}

/// The spellcasting part of a row of a class with standard spellcasting
/// (FR-031; SRD 5.2.1, Features tables, pp. 31, 36, 41, 53, 58, 65, 77).
@immutable
final class SlotSpellcastingRow extends SpellcastingRow {
  /// Creates the row from a defensive copy of [spellSlots].
  ///
  /// Throws an [ArgumentError] carrying the name of the offending field and
  /// the offending value when [preparedSpells] is below [minPreparedSpells],
  /// [spellSlots] does not hold exactly [slotCount] integers, or one of them
  /// is below [minSlots] (FR-031). A printed "—" is stored as 0 (D6).
  SlotSpellcastingRow({
    this.cantrips,
    required int preparedSpells,
    required List<int> spellSlots,
  }) : preparedSpells = _validatedPreparedSpells(preparedSpells),
       spellSlots = List.unmodifiable(_validatedSlots(spellSlots));

  /// The nine spell levels the SRD's Features tables carry (spell levels 1
  /// to 9); a half caster's columns beyond spell level 5 are 0 (FR-031, D6).
  /// The constant the decoder reuses instead of repeating the literal
  /// (FR-007).
  static const int slotCount = 9;

  /// The lowest cantrips, prepared-spell and slot count a row may hold: 0,
  /// the printed "—" (FR-031). The constant the decoder reuses (FR-007).
  static const int minSlots = 0;

  /// The cantrips count, or null when the class's `cantrips` flag is false
  /// (FR-031): present exactly when the flag is true, which the
  /// [ClassDefinition] constructor checks.
  final int? cantrips;

  /// The prepared-spells count (FR-031); at least [minSlots].
  final int preparedSpells;

  /// The spell slots of spell levels 1 to 9, in order; unmodifiable, exactly
  /// [slotCount] entries, each at least [minSlots] (FR-031).
  final List<int> spellSlots;

  /// Whether [spellSlots] is a slot list a row may hold: exactly [slotCount]
  /// entries, each at least [minSlots] (FR-031). The predicate the decoder
  /// reuses (FR-007).
  static bool isValidSpellSlots(List<int> spellSlots) =>
      spellSlots.length == slotCount && spellSlots.every((s) => s >= minSlots);

  /// Whether [count] is a cantrips or prepared-spells count a row may hold:
  /// [minSlots] or more (FR-031). The predicate the decoder reuses (FR-007).
  static bool isValidCount(int count) => count >= minSlots;

  static int _validatedPreparedSpells(int preparedSpells) {
    if (!isValidCount(preparedSpells)) {
      throw ArgumentError.value(
        preparedSpells,
        'preparedSpells',
        'must be $minSlots or more',
      );
    }
    return preparedSpells;
  }

  static List<int> _validatedSlots(List<int> spellSlots) {
    if (spellSlots.length != slotCount) {
      throw ArgumentError.value(
        spellSlots,
        'spellSlots',
        'must hold exactly $slotCount slot counts, one per spell level',
      );
    }
    for (var i = 0; i < spellSlots.length; i++) {
      if (spellSlots[i] < minSlots) {
        throw ArgumentError.value(
          spellSlots[i],
          'spellSlots',
          'must be $minSlots or more',
        );
      }
    }
    return spellSlots;
  }

  @override
  bool operator ==(Object other) =>
      other is SlotSpellcastingRow &&
      other.cantrips == cantrips &&
      other.preparedSpells == preparedSpells &&
      const ListEquality<int>().equals(other.spellSlots, spellSlots);

  @override
  int get hashCode => Object.hash(
    SlotSpellcastingRow,
    cantrips,
    preparedSpells,
    const ListEquality<int>().hash(spellSlots),
  );

  @override
  String toString() =>
      'SlotSpellcastingRow(cantrips: $cantrips, prepared: $preparedSpells, '
      'slots: $spellSlots)';
}

/// The spellcasting part of a row of the Warlock's Pact Magic (FR-032;
/// SRD 5.2.1, "Warlock Features", p. 71).
@immutable
final class PactSpellcastingRow extends SpellcastingRow {
  /// Creates the row.
  ///
  /// Throws an [ArgumentError] carrying the name of the offending field and
  /// the offending value when [cantrips] or [preparedSpells] is below
  /// [minCount], [spellSlots] is below [minSlots], or [slotLevel] is outside
  /// [minSlotLevel] to [maxSlotLevel] (FR-032).
  PactSpellcastingRow({
    required int cantrips,
    required int preparedSpells,
    required int spellSlots,
    required int slotLevel,
  }) : cantrips = _validatedCount(cantrips, 'cantrips'),
       preparedSpells = _validatedCount(preparedSpells, 'preparedSpells'),
       spellSlots = _validatedSlots(spellSlots),
       slotLevel = _validatedSlotLevel(slotLevel);

  /// The most spell slots a Pact Magic row may hold is not stated, and no
  /// rule rejects a large count (FR-032); the count is only bounded below.
  /// The lowest spell-slot count a Pact row may hold: 1 (FR-032). The
  /// constant the decoder reuses instead of repeating the literal (FR-007).
  static const int minSlots = 1;

  /// The lowest spell level a Pact slot may be: 1 (FR-032). The constant the
  /// decoder reuses instead of repeating the literal (FR-007).
  static const int minSlotLevel = 1;

  /// The highest spell level a Pact slot may be: 9 (FR-032). The constant
  /// the decoder reuses instead of repeating the literal (FR-007).
  static const int maxSlotLevel = 9;

  /// The lowest cantrips and prepared-spells count a row may hold: 0 (a
  /// count, as in FR-031; the FR-032 rule itself bounds only the slot count
  /// and slot level). The constant the decoder reuses (FR-007).
  static const int minCount = 0;

  /// The cantrips count (FR-032); at least [minCount].
  final int cantrips;

  /// The prepared-spells count (FR-032); at least [minCount].
  final int preparedSpells;

  /// How many spell slots the character has (FR-032); at least [minSlots].
  final int spellSlots;

  /// The level of the spell slots, from [minSlotLevel] to [maxSlotLevel]
  /// (FR-032).
  final int slotLevel;

  /// Whether [count] is a cantrips or prepared-spells count a row may hold:
  /// [minCount] or more (FR-032). The predicate the decoder reuses (FR-007).
  static bool isValidCount(int count) => count >= minCount;

  /// Whether [count] is a slot count a Pact row may hold: [minSlots] or more
  /// (FR-032). The predicate the decoder reuses (FR-007).
  static bool isValidSlotCount(int count) => count >= minSlots;

  /// Whether [slotLevel] is a slot level a Pact row may hold: [minSlotLevel]
  /// to [maxSlotLevel] (FR-032). The predicate the decoder reuses (FR-007).
  static bool isValidSlotLevel(int slotLevel) =>
      slotLevel >= minSlotLevel && slotLevel <= maxSlotLevel;

  static int _validatedCount(int count, String name) {
    if (!isValidCount(count)) {
      throw ArgumentError.value(count, name, 'must be $minCount or more');
    }
    return count;
  }

  static int _validatedSlots(int spellSlots) {
    if (!isValidSlotCount(spellSlots)) {
      throw ArgumentError.value(
        spellSlots,
        'spellSlots',
        'must be $minSlots or more',
      );
    }
    return spellSlots;
  }

  static int _validatedSlotLevel(int slotLevel) {
    if (!isValidSlotLevel(slotLevel)) {
      throw ArgumentError.value(
        slotLevel,
        'slotLevel',
        'must be from $minSlotLevel to $maxSlotLevel',
      );
    }
    return slotLevel;
  }

  @override
  bool operator ==(Object other) =>
      other is PactSpellcastingRow &&
      other.cantrips == cantrips &&
      other.preparedSpells == preparedSpells &&
      other.spellSlots == spellSlots &&
      other.slotLevel == slotLevel;

  @override
  int get hashCode => Object.hash(
    PactSpellcastingRow,
    cantrips,
    preparedSpells,
    spellSlots,
    slotLevel,
  );

  @override
  String toString() =>
      'PactSpellcastingRow(cantrips: $cantrips, prepared: $preparedSpells, '
      'slots: $spellSlots of level $slotLevel)';
}

/// One row of a class's Features table: the level, the Proficiency Bonus,
/// the row's feature references, its spellcasting part and its class-specific
/// column values (FR-037 to FR-039, FR-043; SRD 5.2.1, Features tables,
/// pp. 28-77).
@immutable
final class ProgressionRow {
  /// Creates the row from defensive copies of the collection fields.
  ///
  /// Throws an [ArgumentError] carrying the name of the offending field and
  /// the offending value when [level] is outside [minLevel] to [maxLevel],
  /// [proficiencyBonus] is below [minProficiencyBonus], or [features] holds
  /// more than one [RowSubclassFeature] (FR-037, FR-038, FR-043). The row's
  /// position (its `level` being the position plus one), its columns and its
  /// spellcasting variant are the [ClassDefinition] constructor's checks
  /// (FR-037, FR-039, FR-030).
  ProgressionRow({
    required int level,
    required int proficiencyBonus,
    required List<RowFeature> features,
    this.spellcasting,
    required Map<ClassColumnId, ColumnValue> values,
  }) : level = _validatedLevel(level),
       proficiencyBonus = _validatedProficiencyBonus(proficiencyBonus),
       features = List.unmodifiable(_validatedFeatures(features)),
       values = Map.unmodifiable(values);

  /// The lowest level a row may carry: 1 (FR-037). The constant the decoder
  /// reuses instead of repeating the literal (FR-007); the accessor rules
  /// (FR-047, FR-048, FR-075) reuse it as their lowest level too.
  static const int minLevel = 1;

  /// The highest level a row may carry: 20 (FR-037). The constant the
  /// decoder reuses instead of repeating the literal (FR-007); the accessor
  /// rules (FR-047, FR-048, FR-075) reuse it as their highest level too.
  static const int maxLevel = 20;

  /// The lowest Proficiency Bonus a row may carry: 1 (FR-038). The constant
  /// the decoder reuses instead of repeating the literal (FR-007).
  static const int minProficiencyBonus = 1;

  /// The row's level, from [minLevel] to [maxLevel] (FR-037); the
  /// [ClassDefinition] constructor also requires it to be the row's position
  /// plus one.
  final int level;

  /// The Proficiency Bonus at this level (FR-038); at least
  /// [minProficiencyBonus].
  final int proficiencyBonus;

  /// The row's feature references and subclass markers, in printed order;
  /// unmodifiable (FR-043).
  final List<RowFeature> features;

  /// The spellcasting part, or null on a row of a class with no spellcasting
  /// (FR-030). The variant must match the class, which the [ClassDefinition]
  /// constructor checks.
  final SpellcastingRow? spellcasting;

  /// The class-specific column values, one per declared column; unmodifiable
  /// (FR-039). A class with no columns has an empty map. That the keys are
  /// exactly the declared columns is the [ClassDefinition] constructor's
  /// check.
  final Map<ClassColumnId, ColumnValue> values;

  /// Whether [level] is a level a row may carry: [minLevel] to [maxLevel]
  /// (FR-037). The predicate the decoder reuses (FR-007).
  static bool isValidLevel(int level) => level >= minLevel && level <= maxLevel;

  /// The value of the column named [id] (FR-050).
  ///
  /// Throws an [ArgumentError] carrying the name `id` and the offending id
  /// when the row holds no value for it (an undeclared column).
  ColumnValue value(ClassColumnId id) {
    final value = values[id];
    if (value == null) {
      throw ArgumentError.value(id, 'id', 'is not a column of this row');
    }
    return value;
  }

  static int _validatedLevel(int level) {
    if (!isValidLevel(level)) {
      throw ArgumentError.value(
        level,
        'level',
        'must be from $minLevel to $maxLevel',
      );
    }
    return level;
  }

  static int _validatedProficiencyBonus(int proficiencyBonus) {
    if (proficiencyBonus < minProficiencyBonus) {
      throw ArgumentError.value(
        proficiencyBonus,
        'proficiencyBonus',
        'must be $minProficiencyBonus or more',
      );
    }
    return proficiencyBonus;
  }

  static List<RowFeature> _validatedFeatures(List<RowFeature> features) {
    var subclassMarkers = 0;
    for (final feature in features) {
      if (feature is RowSubclassFeature) subclassMarkers++;
    }
    if (subclassMarkers > 1) {
      throw ArgumentError.value(
        features,
        'features',
        'must hold at most one subclass marker (FR-043)',
      );
    }
    return features;
  }

  @override
  bool operator ==(Object other) =>
      other is ProgressionRow &&
      other.level == level &&
      other.proficiencyBonus == proficiencyBonus &&
      const ListEquality<RowFeature>().equals(other.features, features) &&
      other.spellcasting == spellcasting &&
      const MapEquality<ClassColumnId, ColumnValue>().equals(
        other.values,
        values,
      );

  @override
  int get hashCode => Object.hash(
    ProgressionRow,
    level,
    proficiencyBonus,
    const ListEquality<RowFeature>().hash(features),
    spellcasting,
    const MapEquality<ClassColumnId, ColumnValue>().hash(values),
  );

  @override
  String toString() => 'ProgressionRow(level $level)';
}
