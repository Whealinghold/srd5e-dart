import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import '../../shared_kernel/ability/ability.dart';

/// What a feat requires before it can be taken ("Parts of a Feat:
/// Prerequisite", SRD 5.2.1, p. 87), as a sealed family with exactly the
/// three variants the SRD prints (FR-118).
///
/// Switch over it exhaustively, with no default branch. Whether a feat may
/// carry an empty prerequisite list is the species-backgrounds-feats rules'
/// concern (SX-4).
@immutable
sealed class Prerequisite {
  const Prerequisite();
}

/// A minimum level the character must have reached (FR-118).
@immutable
final class LevelPrerequisite extends Prerequisite {
  /// The smallest [minimum] a level prerequisite may name.
  static const int minLevel = 1;

  /// The largest [minimum] a level prerequisite may name.
  static const int maxLevel = 20;

  /// Creates a level prerequisite.
  ///
  /// Throws an [ArgumentError] carrying the name `minimum` and the offending
  /// value when [minimum] is outside [minLevel] to [maxLevel].
  LevelPrerequisite(int minimum)
    : minimum = _validated(minimum, 'minimum', minLevel, maxLevel);

  /// The level the character must have reached, 1 to 20.
  final int minimum;

  @override
  bool operator ==(Object other) =>
      other is LevelPrerequisite && other.minimum == minimum;

  @override
  int get hashCode => Object.hash(LevelPrerequisite, minimum);

  @override
  String toString() => 'LevelPrerequisite($minimum)';
}

/// One ability of a set that must be at least [minimum]: any one of them
/// suffices ("Grappler", SRD 5.2.1, p. 87; "Boon of Spell Recall", p. 88)
/// (FR-118).
@immutable
final class AbilityScorePrerequisite extends Prerequisite {
  /// The smallest [minimum] an ability prerequisite may name.
  static const int minMinimum = 1;

  /// The largest [minimum] an ability prerequisite may name.
  static const int maxMinimum = 30;

  /// Creates an ability-score prerequisite.
  ///
  /// Throws an [ArgumentError] carrying the name `abilities` when [abilities]
  /// is empty, or `minimum` when [minimum] is outside [minMinimum] to
  /// [maxMinimum]. The set is copied and cannot be changed afterwards.
  AbilityScorePrerequisite(Set<Ability> abilities, int minimum)
    : abilities = UnmodifiableSetView(Set.of(abilities)),
      minimum = _validated(minimum, 'minimum', minMinimum, maxMinimum) {
    if (abilities.isEmpty) {
      throw ArgumentError.value(abilities, 'abilities', 'must not be empty');
    }
  }

  /// The abilities, any one of which suffices; unmodifiable.
  final Set<Ability> abilities;

  /// The score each of [abilities] is compared with, 1 to 30.
  final int minimum;

  @override
  bool operator ==(Object other) =>
      other is AbilityScorePrerequisite &&
      other.minimum == minimum &&
      other.abilities.length == abilities.length &&
      other.abilities.containsAll(abilities);

  @override
  int get hashCode => Object.hashAllUnordered([...abilities, minimum]);

  @override
  String toString() => 'AbilityScorePrerequisite($abilities, $minimum)';
}

/// A named feature the character must have ("Parts of a Feat: Prerequisite",
/// SRD 5.2.1, p. 87) (FR-118).
@immutable
final class FeaturePrerequisite extends Prerequisite {
  /// Creates a feature prerequisite.
  ///
  /// Throws an [ArgumentError] carrying the name `name` and the offending
  /// value when [name] is empty or has leading or trailing whitespace.
  FeaturePrerequisite(String name) : name = _validatedName(name);

  /// The name of the feature the character must have, verbatim.
  final String name;

  @override
  bool operator ==(Object other) =>
      other is FeaturePrerequisite && other.name == name;

  @override
  int get hashCode => Object.hash(FeaturePrerequisite, name);

  @override
  String toString() => 'FeaturePrerequisite($name)';
}

int _validated(int value, String name, int min, int max) {
  if (value < min || value > max) {
    throw ArgumentError.value(value, name, 'must be from $min to $max');
  }
  return value;
}

String _validatedName(String name) {
  if (name.isEmpty || name.trim() != name) {
    throw ArgumentError.value(
      name,
      'name',
      'must be non-empty with no leading or trailing whitespace',
    );
  }
  return name;
}
