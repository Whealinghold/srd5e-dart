import 'package:srd5e/srd5e.dart';
import 'package:test/test.dart';

void main() {
  /// Requirement: doc/specs/ability-scores.md section 6 - srd5e.dart exports
  ///   Ability, AbilityScore, AbilityModifier, AbilityScores,
  ///   AbilityScoreResult, ValidAbilityScore, InvalidAbilityScore and
  ///   AbilityScoreRejection. A name that is not exported does not compile.
  /// Path: happy
  test('srd5e.dart exports the ability types', () {
    final names = <Type>[
      Ability,
      AbilityScore,
      AbilityModifier,
      AbilityScores,
      AbilityScoreResult,
      ValidAbilityScore,
      InvalidAbilityScore,
      AbilityScoreRejection,
    ].map((type) => type.toString());

    expect(names, [
      'Ability',
      'AbilityScore',
      'AbilityModifier',
      'AbilityScores',
      'AbilityScoreResult',
      'ValidAbilityScore',
      'InvalidAbilityScore',
      'AbilityScoreRejection',
    ]);
  });

  /// Requirement: doc/specs/ability-scores.md sections 1 and 6 - untrusted
  ///   integers are parsed with tryCreate, a complete set is built and a
  ///   modifier is converted for a roll, all through the public entry point
  ///   (SRD 5.2.1, "Ability Scores", p. 5; "Ability Modifiers", p. 6).
  /// Path: happy
  test('parse scores, build a set and convert a modifier publicly', () {
    final parsed = [10, 14, 12, 8, 16, 20].map(AbilityScore.tryCreate);
    final scores = AbilityScores.fromMap({
      for (final (index, result) in parsed.indexed)
        Ability.values[index]: switch (result) {
          ValidAbilityScore(:final score) => score,
          InvalidAbilityScore() => throw StateError('unexpected rejection'),
        },
    });

    final strength = Modifier(scores.modifierOf(Ability.strength).value);
    final charisma = Modifier(scores.modifierOf(Ability.charisma).value);

    expect(strength, Modifier.zero);
    expect(charisma, const Modifier(5));
    expect((strength + charisma).applyTo(11), 16);
  });

  /// Requirement: doc/specs/ability-scores.md FR-009 and FR-010, and
  ///   doc/specs/errors-and-results.md FR-045 - a consumer switches over the result with no default
  ///   branch and reads the typed rejection (SRD 5.2.1, "Ability Scores",
  ///   p. 5).
  /// Path: unhappy (invalid input)
  test('an out-of-range integer is a typed rejection, not an exception', () {
    final result = AbilityScore.tryCreate(31);

    final reason = switch (result) {
      ValidAbilityScore() => null,
      InvalidAbilityScore(:final reason) => reason,
    };

    expect(reason, AbilityScoreRejection.aboveMaximum);
  });
}
