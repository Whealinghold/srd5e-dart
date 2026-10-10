import 'package:meta/meta.dart';

import 'ability_score_result.dart';

/// An ability score: the whole number from 1 to 30 that measures one ability
/// of a creature.
///
/// "Each ability has a score from 1 to 20, although some monsters have a score
/// as high as 30" ("Ability Scores", SRD 5.2.1, p. 5). The package checks only
/// the outer range of [minimum] to [maximum]. The adventurer's cap of 20
/// "unless a feature says otherwise" is a character rule, and a score of 0 is
/// not valid: the SRD says only that an effect which reduces a score to 0
/// "explains what happens".
///
/// The [modifier] of a score is read from the Ability Modifiers table
/// ("Ability Modifiers", SRD 5.2.1, p. 6).
@immutable
final class AbilityScore {
  /// Creates the score [value].
  ///
  /// Throws an [ArgumentError] carrying the name `value` and the rejected
  /// integer when [value] is below [minimum] or above [maximum]. The check
  /// holds in release mode too. Use [tryCreate] for untrusted input.
  AbilityScore(int value) : value = _validated(value);

  const AbilityScore._(this.value);

  /// The lowest score: "the lowest a score can normally go" ("Ability Scores",
  /// SRD 5.2.1, p. 5).
  static const int minimum = 1;

  /// The highest score: "the highest a score can go" ("Ability Scores", SRD
  /// 5.2.1, p. 5).
  static const int maximum = 30;

  /// The Ability Modifiers table, SRD 5.2.1, p. 6, one entry per score from
  /// [minimum] (index 0) to [maximum] (index 29).
  static const List<int> _modifierTable = [
    -5, // 1
    -4, -4, // 2-3
    -3, -3, // 4-5
    -2, -2, // 6-7
    -1, -1, // 8-9
    0, 0, // 10-11
    1, 1, // 12-13
    2, 2, // 14-15
    3, 3, // 16-17
    4, 4, // 18-19
    5, 5, // 20-21
    6, 6, // 22-23
    7, 7, // 24-25
    8, 8, // 26-27
    9, 9, // 28-29
    10, // 30
  ];

  /// The score, from [minimum] to [maximum].
  final int value;

  /// The modifier of this score, from the Ability Modifiers table ("Ability
  /// Modifiers", SRD 5.2.1, p. 6).
  ///
  /// The table rounds down, so an odd score below 10 gives the lower value:
  /// score 1 gives -5, score 3 gives -4 and score 9 gives -1.
  AbilityModifier get modifier =>
      AbilityModifier._(_modifierTable[value - minimum]);

  /// Creates a score from untrusted input without throwing.
  ///
  /// Returns [ValidAbilityScore] exactly when the [AbilityScore] constructor
  /// would accept [value], and [InvalidAbilityScore] with the rejected integer
  /// and its [AbilityScoreRejection] otherwise. It accepts every [int].
  static AbilityScoreResult tryCreate(int value) {
    final reason = _rejection(value);
    return reason == null
        ? ValidAbilityScore(AbilityScore._(value))
        : InvalidAbilityScore(value, reason);
  }

  static AbilityScoreRejection? _rejection(int value) {
    if (value < minimum) return AbilityScoreRejection.belowMinimum;
    if (value > maximum) return AbilityScoreRejection.aboveMaximum;
    return null;
  }

  static int _validated(int value) {
    if (_rejection(value) != null) {
      throw ArgumentError.value(
        value,
        'value',
        'must be from $minimum to $maximum',
      );
    }
    return value;
  }

  @override
  bool operator ==(Object other) =>
      other is AbilityScore && other.value == value;

  @override
  int get hashCode => value.hashCode;

  /// The debugging form, `AbilityScore(<value>)`. Not display text.
  @override
  String toString() => 'AbilityScore($value)';
}

/// An ability modifier: the signed whole number, from -5 to +10, that you
/// apply whenever you make a D20 Test with an ability.
///
/// "Each ability has a modifier that you apply whenever you make a D20 Test
/// with that ability" ("Ability Modifiers", SRD 5.2.1, p. 5). A modifier is
/// derived from a score with [AbilityScore.modifier]; no code outside this
/// library can build one, so an out-of-range modifier cannot exist.
///
/// It is independent of the kernel `Modifier`. A caller that adds it to a roll
/// converts it with `Modifier(abilityModifier.value)`.
@immutable
final class AbilityModifier {
  const AbilityModifier._(this.value);

  /// The signed whole number to apply to a D20 Test, from -5 to +10.
  final int value;

  @override
  bool operator ==(Object other) =>
      other is AbilityModifier && other.value == value;

  @override
  int get hashCode => value.hashCode;

  /// The debugging form, `AbilityModifier(<value>)`. Not display text.
  @override
  String toString() => 'AbilityModifier($value)';
}
