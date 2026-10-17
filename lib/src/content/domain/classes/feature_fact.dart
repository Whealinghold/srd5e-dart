import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import '../feat_category.dart';
import '../typed_ids.dart';

/// A structured fact a feature entry or a feature option carries — the three
/// machine-readable mechanics other contexts read as data (FR-055, D3;
/// shared-types-and-ownership.md FR-022, FR-023).
///
/// The family is sealed with exactly the three variants, exhaustive in a
/// `switch` without a default (FR-055). Everything else about a feature is
/// its verbatim text, keyed by the feature's id. The facts on one entry are
/// distinct, which the [FeatureEntry] constructor checks.
@immutable
sealed class FeatureFact {
  const FeatureFact();
}

/// The fact that names a class's subclass choice: the "Level 3: Barbarian
/// Subclass" feature carries it, and the class's `subclassLevel` is that
/// entry's level (FR-056; SRD 5.2.1, "Level 3: Barbarian Subclass", p. 29).
@immutable
final class GrantsSubclass extends FeatureFact {
  /// Creates the fact; every instance equals every other.
  const GrantsSubclass();

  @override
  bool operator ==(Object other) => other is GrantsSubclass;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'GrantsSubclass';
}

/// The fact that the feature grants a feat of a category: Ability Score
/// Improvement (General), Epic Boon, Fighting Style (FR-057; SRD 5.2.1,
/// "Level 4: Ability Score Improvement", p. 29, "Level 1: Fighting Style",
/// p. 47).
@immutable
final class GrantsFeat extends FeatureFact {
  /// Creates the fact.
  const GrantsFeat(this.category);

  /// The category of feat the feature grants (FR-057).
  final FeatCategory category;

  @override
  bool operator ==(Object other) =>
      other is GrantsFeat && other.category == category;

  @override
  int get hashCode => Object.hash(GrantsFeat, category);

  @override
  String toString() => 'GrantsFeat(${category.jsonValue})';
}

/// The fact that a feature grants spells that are always prepared: Divine
/// Smite, or a subclass's "Life Domain Spells" table (FR-058; SRD 5.2.1,
/// "Level 3: Life Domain Spells", p. 40, "Level 2: Paladin's Smite", p. 54).
@immutable
final class AlwaysPreparedSpells extends FeatureFact {
  /// Creates the fact from a defensive copy of [grants].
  ///
  /// Throws an [ArgumentError] carrying the name `grants` and the offending
  /// value when [grants] is empty or holds grants whose levels are not
  /// strictly ascending (FR-058). The other grant rules — the spell ids
  /// being resolvable spell entries — are the whole-set validation's
  /// concern (FR-059).
  AlwaysPreparedSpells(List<SpellGrant> grants)
    : grants = List.unmodifiable(_validatedGrants(grants));

  /// The fewest grants the fact may hold: one (FR-058). The constant the
  /// decoder reuses instead of repeating the literal (FR-007).
  static const int minGrants = 1;

  /// The grants, in strictly ascending level order; unmodifiable, never
  /// empty (FR-058).
  final List<SpellGrant> grants;

  static List<SpellGrant> _validatedGrants(List<SpellGrant> grants) {
    if (grants.length < minGrants) {
      throw ArgumentError.value(
        grants,
        'grants',
        'must hold at least $minGrants grant',
      );
    }
    for (var i = 1; i < grants.length; i++) {
      if (grants[i].level <= grants[i - 1].level) {
        throw ArgumentError.value(
          grants[i].level,
          'grants',
          'must hold grants with strictly ascending levels (FR-058)',
        );
      }
    }
    return grants;
  }

  @override
  bool operator ==(Object other) =>
      other is AlwaysPreparedSpells &&
      const ListEquality<SpellGrant>().equals(other.grants, grants);

  @override
  int get hashCode => Object.hash(
    AlwaysPreparedSpells,
    const ListEquality<SpellGrant>().hash(grants),
  );

  @override
  String toString() => 'AlwaysPreparedSpells($grants)';
}

/// One grant of an [AlwaysPreparedSpells] fact: the spell level and the ids
/// of the spells at that level that are always prepared (FR-058).
@immutable
final class SpellGrant {
  /// Creates the grant from a defensive copy of [spellIds].
  ///
  /// Throws an [ArgumentError] carrying the name `level` or `spellIds` and
  /// the offending value when [level] is outside [minLevel] to [maxLevel]
  /// or [spellIds] is empty or holds a spell id twice (FR-058). That a
  /// grant's level is at least the owning feature's level is the
  /// [FeatureEntry] constructor's check.
  SpellGrant(int level, List<SpellId> spellIds)
    : level = _validatedLevel(level),
      spellIds = List.unmodifiable(_validatedSpellIds(spellIds));

  /// The lowest level a grant may carry: 1 (FR-058). The constant the
  /// decoder reuses instead of repeating the literal (FR-007).
  static const int minLevel = 1;

  /// The highest level a grant may carry: 20 (FR-058). The constant the
  /// decoder reuses instead of repeating the literal (FR-007).
  static const int maxLevel = 20;

  /// The level of the granted spells (FR-058); from [minLevel] to
  /// [maxLevel], and at least the owning feature's level.
  final int level;

  /// The ids of the spells granted at [level], in printed order;
  /// unmodifiable, never empty, all distinct (FR-058). Their targets are
  /// whole-set reference sites (FR-059).
  final List<SpellId> spellIds;

  /// Whether [level] is a level a grant may carry: [minLevel] to [maxLevel]
  /// (FR-058). The predicate the decoder reuses (FR-007).
  static bool isValidLevel(int level) => level >= minLevel && level <= maxLevel;

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

  static List<SpellId> _validatedSpellIds(List<SpellId> spellIds) {
    if (spellIds.isEmpty) {
      throw ArgumentError.value(spellIds, 'spellIds', 'must not be empty');
    }
    for (var i = 1; i < spellIds.length; i++) {
      if (spellIds.indexOf(spellIds[i]) != i) {
        throw ArgumentError.value(spellIds[i], 'spellIds', 'must be distinct');
      }
    }
    return spellIds;
  }

  @override
  bool operator ==(Object other) =>
      other is SpellGrant &&
      other.level == level &&
      const ListEquality<SpellId>().equals(other.spellIds, spellIds);

  @override
  int get hashCode => Object.hash(
    SpellGrant,
    level,
    const ListEquality<SpellId>().hash(spellIds),
  );

  @override
  String toString() => 'SpellGrant(level $level: $spellIds)';
}
