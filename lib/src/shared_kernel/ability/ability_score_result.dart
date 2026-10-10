import 'package:meta/meta.dart';

import 'ability_score.dart';

/// Why an integer is not an [AbilityScore].
///
/// Only the whole-package range of 1 to 30 is checked here ("Ability Scores",
/// SRD 5.2.1, p. 5). A character's own cap, such as 20, is a character rule
/// with its own type.
enum AbilityScoreRejection {
  /// The integer is below [AbilityScore.minimum].
  belowMinimum,

  /// The integer is above [AbilityScore.maximum].
  aboveMaximum,
}

/// The result of [AbilityScore.tryCreate]: a valid score or a typed rejection.
///
/// Switch over it exhaustively, with no default branch.
@immutable
sealed class AbilityScoreResult {
  const AbilityScoreResult();
}

/// [AbilityScore.tryCreate] accepted the integer.
final class ValidAbilityScore extends AbilityScoreResult {
  /// Wraps the created [score].
  const ValidAbilityScore(this.score);

  /// The score that was created.
  final AbilityScore score;

  @override
  bool operator ==(Object other) =>
      other is ValidAbilityScore && other.score == score;

  @override
  int get hashCode => Object.hash(ValidAbilityScore, score);

  @override
  String toString() => 'ValidAbilityScore($score)';
}

/// [AbilityScore.tryCreate] rejected the integer.
final class InvalidAbilityScore extends AbilityScoreResult {
  /// Carries the rejected [value] and the typed [reason].
  const InvalidAbilityScore(this.value, this.reason);

  /// The integer that was rejected.
  final int value;

  /// Why the integer was rejected.
  final AbilityScoreRejection reason;

  @override
  bool operator ==(Object other) =>
      other is InvalidAbilityScore &&
      other.value == value &&
      other.reason == reason;

  @override
  int get hashCode => Object.hash(InvalidAbilityScore, value, reason);

  @override
  String toString() => 'InvalidAbilityScore($value, ${reason.name})';
}
