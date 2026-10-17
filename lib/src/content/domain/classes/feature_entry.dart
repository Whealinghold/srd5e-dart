import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import '../named_text.dart';
import '../typed_ids.dart';
import 'feature_fact.dart';
import 'feature_option.dart';
import 'feature_table.dart';
import 'progression_row.dart' show ProgressionRow;

/// One feature of a class or subclass, stored under its "Level N: Name"
/// heading: a stable id, the three structured facts other contexts read as
/// data, structured options and tables, and the faithful SRD text (FR-051,
/// FR-052; SRD 5.2.1, "Barbarian Class Features", pp. 28-30).
///
/// The [id] of a bundled entry is `deriveFeatureId(owner, name)` — the
/// owner's id, an underscore, then the slug of the name, with a
/// `_level_<n>` suffix only when one owner prints two features with the
/// same name (FR-052, FR-053). That the id is prefixed with its owner's id
/// is checked by the [ClassDefinition] constructor, which holds the owner
/// (FR-052); the text rules are the extraction's concern, stored verbatim
/// (FR-054).
@immutable
final class FeatureEntry {
  /// Creates the entry from defensive copies of the collection fields.
  ///
  /// Throws an [ArgumentError] carrying the name of the offending field and
  /// the offending value when [name] or [text] breaks the text rules,
  /// [level] is outside [minLevel] to [maxLevel] (FR-051), [facts] holds the
  /// same fact twice (FR-055), a grant of a fact is below [level] (FR-058),
  /// two [options] share an id (FR-061), an option carries a fact kind other
  /// than [AlwaysPreparedSpells] (FR-064), or an option's prerequisite names
  /// no other option of this feature, names itself, or the references form a
  /// cycle (FR-062).
  FeatureEntry({
    required this.id,
    required String name,
    required int level,
    required String text,
    List<FeatureFact> facts = const [],
    List<FeatureOption> options = const [],
    List<FeatureTable> tables = const [],
  }) : name = _validatedName(name),
       level = _validatedLevel(level),
       text = _validatedText(text),
       facts = List.unmodifiable(facts),
       options = List.unmodifiable(options),
       tables = List.unmodifiable(tables) {
    _validateFacts();
    _validateOptions();
  }

  /// The lowest level a feature entry may carry: 1 (FR-051). The constant
  /// the decoder reuses instead of repeating the literal (FR-007).
  static const int minLevel = ProgressionRow.minLevel;

  /// The highest level a feature entry may carry: 20 (FR-051). The constant
  /// the decoder reuses instead of repeating the literal (FR-007).
  static const int maxLevel = ProgressionRow.maxLevel;

  /// The entry's id: the owner's id, an underscore, then the slug of the
  /// [name], with a `_level_<n>` suffix for a repeated name (FR-052,
  /// FR-053). The prefix rule is the [ClassDefinition] constructor's check.
  final FeatureId id;

  /// The feature's printed SRD name, exactly ("Rage", "Fighting Style") —
  /// no level, `_level_<n>` suffix or annotation; two features may share a
  /// name (FR-053, FR-102).
  final String name;

  /// The level of the "Level N" heading the feature is stored under, from
  /// [minLevel] to [maxLevel] (FR-051).
  final int level;

  /// The faithful SRD text of the feature, verbatim: without the heading,
  /// with bold lead-in words as plain text, paragraphs separated by one line
  /// feed, and without any embedded table or option list (FR-054).
  final String text;

  /// The structured facts; unmodifiable, possibly empty, all distinct
  /// (FR-055).
  final List<FeatureFact> facts;

  /// The options of the feature's option list, in printed order;
  /// unmodifiable, possibly empty, ids unique within the feature (FR-061).
  final List<FeatureOption> options;

  /// The embedded tables; unmodifiable, possibly empty (FR-066).
  final List<FeatureTable> tables;

  /// Whether [level] is a level a feature entry may carry: [minLevel] to
  /// [maxLevel] (FR-051). The predicate the decoder reuses (FR-007).
  static bool isValidLevel(int level) => level >= minLevel && level <= maxLevel;

  void _validateFacts() {
    // FR-055: facts on one entry are distinct.
    for (var i = 1; i < facts.length; i++) {
      if (facts.indexOf(facts[i]) != i) {
        throw ArgumentError.value(facts[i], 'facts', 'must be distinct');
      }
    }
    // FR-058: a grant's level is at least the owning feature's level.
    _checkGrantLevels(facts);
    for (final option in options) {
      _checkGrantLevels(option.facts);
    }
  }

  void _checkGrantLevels(List<FeatureFact> facts) {
    for (final fact in facts) {
      if (fact is AlwaysPreparedSpells) {
        for (final grant in fact.grants) {
          if (grant.level < level) {
            throw ArgumentError.value(
              grant.level,
              'facts',
              'a grant level must be at least the owning feature\'s level '
                  '$level (FR-058)',
            );
          }
        }
      }
    }
  }

  void _validateOptions() {
    // FR-061: option ids are unique within the feature.
    for (var i = 1; i < options.length; i++) {
      final id = options[i].id;
      if (options.sublist(0, i).any((option) => option.id == id)) {
        throw ArgumentError.value(
          id,
          'options',
          'must not repeat an option id (FR-061)',
        );
      }
    }
    // FR-062: prerequisites name other options of this feature, and the
    // references do not form a cycle.
    final idsById = <FeatureOptionId, int>{};
    for (var i = 0; i < options.length; i++) {
      idsById[options[i].id] = i;
    }
    for (final option in options) {
      final prerequisite = option.prerequisite;
      if (prerequisite == null) continue;
      for (var i = 0; i < prerequisite.requiresOptionIds.length; i++) {
        final required = prerequisite.requiresOptionIds[i];
        if (required == option.id) {
          throw ArgumentError.value(
            required,
            'options',
            'must not require itself (FR-062)',
          );
        }
        if (!idsById.containsKey(required)) {
          throw ArgumentError.value(
            required,
            'options',
            'must name an option of the same feature (FR-062)',
          );
        }
      }
    }
    _requireNoPrerequisiteCycle(idsById);
  }

  /// Depth-first search over the options' `requiresOptionIds` edges; a cycle
  /// is FR-062's constraintViolation.
  void _requireNoPrerequisiteCycle(Map<FeatureOptionId, int> idsByIndex) {
    final edges = <FeatureOptionId, List<FeatureOptionId>>{
      for (final option in options)
        option.id: option.prerequisite?.requiresOptionIds ?? const [],
    };
    final visiting = <FeatureOptionId>{};
    final visited = <FeatureOptionId>{};

    void visit(FeatureOptionId id) {
      if (visited.contains(id)) return;
      if (!visiting.add(id)) {
        throw ArgumentError.value(
          id,
          'options',
          'must not form a prerequisite cycle (FR-062)',
        );
      }
      for (final required in edges[id] ?? const <FeatureOptionId>[]) {
        visit(required);
      }
      // mutate4dart: ignore remove_call // masked: a completed id is always in visited, so its re-visit returns before touching visiting.
      visiting.remove(id);
      // mutate4dart: ignore remove_call // memoization only: a re-visit revalidates identically, so removing this cannot change any outcome.
      visited.add(id);
    }

    for (final id in idsByIndex.keys) {
      visit(id);
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

  static String _validatedText(String text) {
    if (!NamedText.isValidText(text)) {
      throw ArgumentError.value(
        text,
        'text',
        'must contain at least one non-whitespace character',
      );
    }
    return text;
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

  @override
  bool operator ==(Object other) =>
      other is FeatureEntry &&
      other.id == id &&
      other.name == name &&
      other.level == level &&
      other.text == text &&
      const ListEquality<FeatureFact>().equals(other.facts, facts) &&
      const ListEquality<FeatureOption>().equals(other.options, options) &&
      const ListEquality<FeatureTable>().equals(other.tables, tables);

  @override
  int get hashCode => Object.hash(
    FeatureEntry,
    id,
    name,
    level,
    text,
    const ListEquality<FeatureFact>().hash(facts),
    const ListEquality<FeatureOption>().hash(options),
    const ListEquality<FeatureTable>().hash(tables),
  );

  @override
  String toString() => 'FeatureEntry(${id.id.value}, level $level)';
}
