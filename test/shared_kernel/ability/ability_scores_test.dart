import 'package:srd5e/src/shared_kernel/ability/ability.dart';
import 'package:srd5e/src/shared_kernel/ability/ability_score.dart';
import 'package:srd5e/src/shared_kernel/ability/ability_scores.dart';
import 'package:test/test.dart';

import '../../support/argument_error_matcher.dart';
import '../../support/operator_equals.dart';

/// A fresh, complete map in which every ability has a different modifier
/// (-1, +2, +1, +0, +3, +5), so a mix-up between abilities changes a result.
Map<Ability, AbilityScore> _map() => {
  Ability.strength: AbilityScore(8),
  Ability.dexterity: AbilityScore(14),
  Ability.constitution: AbilityScore(12),
  Ability.intelligence: AbilityScore(10),
  Ability.wisdom: AbilityScore(16),
  Ability.charisma: AbilityScore(20),
};

/// The score of each ability in [_map], in [Ability.values] order.
const List<int> _baseValues = [8, 14, 12, 10, 16, 20];

/// The modifier of each ability in [_map], in [Ability.values] order.
const List<int> _baseModifiers = [-1, 2, 1, 0, 3, 5];

AbilityScores _scores() => AbilityScores.fromMap(_map());

/// The scores of [scores] as integers, in [Ability.values] order.
List<int> _values(AbilityScores scores) => [
  for (final ability in Ability.values) scores.scoreOf(ability).value,
];

typedef _AbilityCase = ({
  String label,
  String requirement,
  String path,
  Ability ability,
});

_AbilityCase _forAbility(
  Ability ability, {
  required String requirement,
  required String path,
}) => (
  label: ability.name,
  requirement: requirement,
  path: path,
  ability: ability,
);

void main() {
  /// Requirement: doc/specs/ability-scores.md FR-018 and FR-020 - a map with a
  ///   score for each of the six abilities builds an AbilityScores and
  ///   `scoreOf` returns the score held for each ability (SRD 5.2.1, "Ability
  ///   Score and Modifier", p. 176).
  /// Path: happy
  group('AbilityScores.fromMap and scoreOf', () {
    /// Requirement: doc/specs/ability-scores.md FR-018 and FR-020 - the six
    ///   scores come back in the abilities they were given for.
    /// Path: happy
    test('scoreOf returns the score given for each of the six abilities', () {
      expect(_values(_scores()), _baseValues);
    });

    /// Requirement: per case
    /// Path: per case
    for (final c in [
      for (final ability in Ability.values)
        _forAbility(
          ability,
          requirement: 'doc/specs/ability-scores.md FR-020 (SRD 5.2.1, p. 176)',
          path: 'happy',
        ),
    ]) {
      test('scoreOf ${c.label} returns that ability\'s score [${c.path}]', () {
        expect(_scores().scoreOf(c.ability), _map()[c.ability]);
      });
    }
  });

  /// Requirement: doc/specs/ability-scores.md FR-019 - a map missing any
  ///   ability, including an empty map, is a programmer error (SRD 5.2.1,
  ///   "Ability Score and Modifier", p. 176: "A creature has six ability
  ///   scores").
  /// Path: unhappy (invalid input)
  group('AbilityScores.fromMap rejects', () {
    /// Requirement: doc/specs/ability-scores.md FR-019 - an empty map has no
    ///   score for any ability.
    /// Path: unhappy (empty and minimal)
    test('an empty map', () {
      final empty = <Ability, AbilityScore>{};

      expect(
        () => AbilityScores.fromMap(empty),
        throwsArgumentErrorFor('scores', empty),
      );
    });

    /// Requirement: per case
    /// Path: per case
    for (final c in [
      for (final ability in Ability.values)
        _forAbility(
          ability,
          requirement: 'doc/specs/ability-scores.md FR-019 (SRD 5.2.1, p. 176)',
          path: 'unhappy (invalid input)',
        ),
    ]) {
      test('a map with no ${c.label} score [${c.path}]', () {
        final incomplete = _map()..remove(c.ability);

        expect(
          () => AbilityScores.fromMap(incomplete),
          throwsArgumentErrorFor('scores', incomplete),
        );
      });
    }

    /// Requirement: doc/specs/ability-scores.md FR-019 - a map with five of the
    ///   six abilities is incomplete however the five are chosen; one map
    ///   holding only a single ability is also rejected.
    /// Path: unhappy (empty and minimal)
    test('a map holding one ability only', () {
      final single = {Ability.strength: AbilityScore(10)};

      expect(
        () => AbilityScores.fromMap(single),
        throwsArgumentErrorFor('scores', single),
      );
    });
  });

  /// Requirement: doc/specs/ability-scores.md FR-022 - AbilityScores does not
  ///   change when the map passed to fromMap is mutated afterwards
  ///   (doc/rules/testing.md section 4, immutability).
  /// Path: unhappy (immutability)
  group('AbilityScores keeps its own copy', () {
    /// Requirement: doc/specs/ability-scores.md FR-022 - replacing a score in
    ///   the source map does not change the AbilityScores.
    /// Path: unhappy (immutability)
    test('replacing a score in the source map changes nothing', () {
      final source = _map();
      final scores = AbilityScores.fromMap(source);

      source[Ability.strength] = AbilityScore(1);

      expect(_values(scores), _baseValues);
    });

    /// Requirement: doc/specs/ability-scores.md FR-022 - removing a score from
    ///   the source map does not change the AbilityScores.
    /// Path: unhappy (immutability)
    test('removing a score from the source map changes nothing', () {
      final source = _map();
      final scores = AbilityScores.fromMap(source);

      source.remove(Ability.charisma);
      source.clear();

      expect(_values(scores), _baseValues);
    });
  });

  /// Requirement: doc/specs/ability-scores.md FR-021 - withScore returns a new
  ///   AbilityScores with the new score for that ability and the other five
  ///   unchanged, and does not alter the original (doc/rules/architecture.md
  ///   section 3, immutability).
  /// Path: unhappy (immutability)
  group('AbilityScores.withScore', () {
    /// Requirement: per case
    /// Path: per case
    for (final c in [
      for (final ability in Ability.values)
        _forAbility(
          ability,
          requirement: 'doc/specs/ability-scores.md FR-021 (immutability)',
          path: 'unhappy (immutability)',
        ),
    ]) {
      test('replacing ${c.label} leaves the other five and the original '
          'unchanged [${c.path}]', () {
        final original = _scores();
        final newScore = AbilityScore(30);
        final expected = [
          for (final ability in Ability.values)
            ability == c.ability ? 30 : _baseValues[ability.index],
        ];

        final changed = original.withScore(c.ability, newScore);

        expect(_values(changed), expected);
        expect(changed.scoreOf(c.ability), newScore);
        expect(_values(original), _baseValues);
      });
    }

    /// Requirement: doc/specs/ability-scores.md FR-021 - the returned value is a
    ///   different object from the original.
    /// Path: unhappy (immutability)
    test('returns a new object, not the original', () {
      final original = _scores();

      final changed = original.withScore(Ability.wisdom, AbilityScore(18));

      expect(identical(changed, original), isFalse);
    });

    /// Requirement: doc/specs/ability-scores.md FR-021 and FR-022 - the new
    ///   AbilityScores is independent of the original, so a chain of
    ///   replacements keeps each step.
    /// Path: unhappy (rule interaction)
    test('two replacements keep both new scores', () {
      final changed = _scores()
          .withScore(Ability.strength, AbilityScore(18))
          .withScore(Ability.charisma, AbilityScore(3));

      expect(_values(changed), [18, 14, 12, 10, 16, 3]);
    });
  });

  /// Requirement: doc/specs/ability-scores.md FR-023 - AbilityScores is a value
  ///   object: the same score for every ability is equal with an equal hash
  ///   code, any one differing ability is not equal (doc/rules/architecture.md
  ///   section 3).
  /// Path: happy
  group('AbilityScores equality', () {
    /// Requirement: doc/specs/ability-scores.md FR-023 - two sets built
    ///   separately from equal maps are equal with equal hash codes.
    /// Path: happy
    test('the same six scores are equal with an equal hash code', () {
      final a = _scores();
      final b = _scores();

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    /// Requirement: doc/specs/ability-scores.md FR-023 - a set equals the set
    ///   rebuilt after withScore replaced a score with the same value.
    /// Path: happy
    test('a replacement with the same score is equal', () {
      final a = _scores();
      final b = a.withScore(Ability.dexterity, AbilityScore(14));

      expect(b, a);
      expect(b.hashCode, a.hashCode);
    });

    /// Requirement: per case
    /// Path: per case
    for (final c in [
      for (final ability in Ability.values)
        _forAbility(
          ability,
          requirement: 'doc/specs/ability-scores.md FR-023 (value object)',
          path: 'unhappy (boundary)',
        ),
    ]) {
      test('differing in ${c.label} only is not equal [${c.path}]', () {
        final other = _scores().withScore(c.ability, AbilityScore(9));

        expect(_scores(), isNot(equals(other)));
      });
    }

    /// Requirement: doc/specs/ability-scores.md FR-023 - a set is not equal to
    ///   an object of another type, such as the list of its six scores.
    /// Path: unhappy (invalid input)
    test('is not equal to a list of the same six scores', () {
      final scores = _scores();
      final asList = [
        for (final ability in Ability.values) scores.scoreOf(ability),
      ];

      expect(operatorEquals(scores, asList), isFalse);
      expect(operatorEquals(scores, _map()), isFalse);
      expect(operatorEquals(scores, 6), isFalse);
    });

    /// Requirement: doc/specs/ability-scores.md FR-023 - the same six values
    ///   given to different abilities are not equal (order matters).
    /// Path: unhappy (rule interaction)
    test('the same values swapped between two abilities are not equal', () {
      final swapped = _scores()
          .withScore(Ability.strength, AbilityScore(14))
          .withScore(Ability.dexterity, AbilityScore(8));

      expect(swapped, isNot(equals(_scores())));
    });
  });

  /// Requirement: doc/specs/ability-scores.md FR-024 - modifierOf(ability)
  ///   returns the modifier of the score held for that ability, equal to
  ///   scoreOf(ability).modifier (SRD 5.2.1, "Ability Score and Modifier",
  ///   p. 176).
  /// Path: happy
  group('AbilityScores.modifierOf', () {
    /// Requirement: doc/specs/ability-scores.md FR-024 - the six modifiers, with
    ///   a different value for each ability, in ability order.
    /// Path: happy
    test('returns the modifier of each ability\'s own score', () {
      final scores = _scores();

      expect([
        for (final ability in Ability.values) scores.modifierOf(ability).value,
      ], _baseModifiers);
    });

    /// Requirement: per case
    /// Path: per case
    for (final c in [
      for (final ability in Ability.values)
        _forAbility(
          ability,
          requirement: 'doc/specs/ability-scores.md FR-024 (SRD 5.2.1, p. 176)',
          path: 'happy',
        ),
    ]) {
      test('${c.label} equals scoreOf(${c.label}).modifier [${c.path}]', () {
        final scores = _scores();

        expect(
          scores.modifierOf(c.ability),
          scores.scoreOf(c.ability).modifier,
        );
      });
    }

    /// Requirement: doc/specs/ability-scores.md FR-024 and FR-021 - after
    ///   withScore the modifier follows the new score for that ability only.
    /// Path: unhappy (rule interaction)
    test('follows a replaced score', () {
      final changed = _scores().withScore(Ability.strength, AbilityScore(20));

      expect(changed.modifierOf(Ability.strength).value, 5);
      expect(changed.modifierOf(Ability.dexterity).value, 2);
    });
  });

  /// Requirement: none - pins the debugging form, which is not display text
  ///   and is not part of the specification.
  /// Path: happy
  test('toString lists each ability with its score', () {
    expect(
      _scores().toString(),
      'AbilityScores(strength: 8, dexterity: 14, constitution: 12, '
      'intelligence: 10, wisdom: 16, charisma: 20)',
    );
  });
}
