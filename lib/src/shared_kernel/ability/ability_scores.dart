import 'package:meta/meta.dart';

import 'ability.dart';
import 'ability_score.dart';

/// The six ability scores of one creature: exactly one [AbilityScore] for each
/// [Ability].
///
/// "A creature has six ability scores—Strength, Dexterity, Constitution,
/// Intelligence, Wisdom, and Charisma—each of which has a corresponding
/// modifier" ("Ability Score and Modifier", SRD 5.2.1, p. 176). The set
/// exposes no collection: read a score with [scoreOf] and iterate
/// [Ability.values].
@immutable
final class AbilityScores {
  /// Creates a set from [scores], which must hold a score for each of the six
  /// abilities.
  ///
  /// The set keeps its own copy, so changing [scores] afterwards does not
  /// change it. Throws an [ArgumentError] carrying the name `scores` and the
  /// map when any ability has no score, including for an empty map.
  factory AbilityScores.fromMap(Map<Ability, AbilityScore> scores) {
    final held = <AbilityScore>[];
    for (final ability in Ability.values) {
      final score = scores[ability];
      if (score == null) {
        throw ArgumentError.value(
          scores,
          'scores',
          'must hold a score for every ability, but has none for '
              '${ability.name}',
        );
      }
      held.add(score);
    }
    return AbilityScores._(List.unmodifiable(held));
  }

  const AbilityScores._(this._held);

  /// The scores in [Ability.values] order; always six and never changed.
  final List<AbilityScore> _held;

  /// The score held for [ability].
  AbilityScore scoreOf(Ability ability) => _held[ability.index];

  /// The modifier of the score held for [ability], equal to
  /// `scoreOf(ability).modifier` ("Ability Score and Modifier", SRD 5.2.1,
  /// p. 176).
  AbilityModifier modifierOf(Ability ability) => scoreOf(ability).modifier;

  /// A new set that has [score] for [ability] and the other five scores of
  /// this set unchanged. This set is not altered.
  AbilityScores withScore(Ability ability, AbilityScore score) {
    final held = List<AbilityScore>.of(_held);
    held[ability.index] = score;
    return AbilityScores._(List.unmodifiable(held));
  }

  @override
  bool operator ==(Object other) {
    if (other is! AbilityScores) return false;
    for (final ability in Ability.values) {
      if (other.scoreOf(ability) != scoreOf(ability)) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(_held);

  /// The debugging form, listing each ability with its score. Not display text.
  @override
  String toString() {
    final entries = [
      for (final ability in Ability.values)
        '${ability.name}: ${scoreOf(ability).value}',
    ];
    return 'AbilityScores(${entries.join(', ')})';
  }
}
