import 'package:srd5e/src/content/domain/prerequisite.dart';
import 'package:srd5e/src/shared_kernel/ability/ability.dart';
import 'package:test/test.dart';

import '../../support/argument_error_matcher.dart';
import '../../support/operator_equals.dart';

/// Exhaustive over the sealed family with no default branch (FR-118).
String _describe(Prerequisite prerequisite) => switch (prerequisite) {
  LevelPrerequisite() => 'level',
  AbilityScorePrerequisite() => 'abilityScore',
  FeaturePrerequisite() => 'feature',
};

void main() {
  /// Requirement: doc/specs/content-schema-and-decoder.md FR-118 -
  ///   LevelPrerequisite names a minimum level of 1 to 20 (SRD
  ///   5.2.1, "Parts of a Feat: Prerequisite", p. 87).
  /// Path: happy
  group('LevelPrerequisite', () {
    /// Requirement: doc/specs/content-schema-and-decoder.md FR-118 - a
    ///   minimum of 1 to 20 (SRD 5.2.1, "Parts of a Feat: Prerequisite",
    ///   p. 87).
    /// Path: happy
    test('accepts a minimum from 1 to 20', () {
      expect(LevelPrerequisite(1).minimum, 1);
      expect(LevelPrerequisite(4).minimum, 4);
      expect(LevelPrerequisite(20).minimum, 20);
    });

    /// Requirement: doc/specs/content-schema-and-decoder.md FR-118 - a
    ///   minimum outside 1 to 20 throws ArgumentError.
    /// Path: unhappy (boundary)
    test('rejects a minimum below 1 and above 20', () {
      expect(() => LevelPrerequisite(0), throwsArgumentErrorFor('minimum', 0));
      expect(
        () => LevelPrerequisite(21),
        throwsArgumentErrorFor('minimum', 21),
      );
    });
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-118 -
  ///   AbilityScorePrerequisite names a non-empty ability set and a
  ///   minimum of 1 to 30 (SRD 5.2.1, "Grappler", p. 87).
  /// Path: happy
  group('AbilityScorePrerequisite', () {
    /// Requirement: doc/specs/content-schema-and-decoder.md FR-118 - a
    ///   non-empty set of abilities where any one suffices, a minimum of 1
    ///   to 30 (SRD 5.2.1, "Grappler", p. 87; "Boon of Spell Recall", p. 88).
    /// Path: happy
    test('accepts a non-empty ability set with a minimum of 1 to 30', () {
      final prerequisite = AbilityScorePrerequisite({
        Ability.strength,
        Ability.dexterity,
      }, 13);

      expect(prerequisite.abilities, {Ability.strength, Ability.dexterity});
      expect(prerequisite.minimum, 13);
      expect(AbilityScorePrerequisite({Ability.strength}, 1).minimum, 1);
      expect(AbilityScorePrerequisite({Ability.strength}, 30).minimum, 30);
    });

    /// Requirement: doc/specs/content-schema-and-decoder.md FR-118 - an
    ///   empty abilities set throws ArgumentError.
    /// Path: unhappy (empty case)
    test('rejects an empty ability set', () {
      expect(
        () => AbilityScorePrerequisite({}, 13),
        throwsArgumentErrorFor('abilities', <Ability>{}),
      );
    });

    /// Requirement: doc/specs/content-schema-and-decoder.md FR-118 - a
    ///   minimum outside 1 to 30 throws ArgumentError.
    /// Path: unhappy (boundary)
    test('rejects a minimum below 1 and above 30', () {
      expect(
        () => AbilityScorePrerequisite({Ability.strength}, 0),
        throwsArgumentErrorFor('minimum', 0),
      );
      expect(
        () => AbilityScorePrerequisite({Ability.strength}, 31),
        throwsArgumentErrorFor('minimum', 31),
      );
    });

    /// Requirement: doc/specs/content-schema-and-decoder.md FR-118 - the
    ///   set is stored unmodifiable, so it cannot be changed afterwards.
    /// Path: unhappy (immutability)
    test('the ability set cannot be mutated', () {
      final prerequisite = AbilityScorePrerequisite({Ability.strength}, 13);

      expect(
        () => prerequisite.abilities.add(Ability.dexterity),
        throwsUnsupportedError,
      );
    });

    /// Requirement: doc/specs/content-schema-and-decoder.md FR-118 - value
    ///   equality is by the set contents, whatever their order, and the
    ///   minimum.
    /// Path: happy
    test('compares by set contents and minimum', () {
      final prerequisite = AbilityScorePrerequisite({
        Ability.strength,
        Ability.dexterity,
      }, 13);
      final reordered = AbilityScorePrerequisite({
        Ability.dexterity,
        Ability.strength,
      }, 13);
      final otherMinimum = AbilityScorePrerequisite({
        Ability.strength,
        Ability.dexterity,
      }, 14);
      final otherAbilities = AbilityScorePrerequisite({Ability.strength}, 13);

      expect(prerequisite, reordered);
      expect(prerequisite.hashCode, reordered.hashCode);
      expect(operatorEquals(prerequisite, otherMinimum), isFalse);
      expect(operatorEquals(prerequisite, otherAbilities), isFalse);
    });
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-118 -
  ///   FeaturePrerequisite names a feature by its printed name.
  /// Path: happy
  group('FeaturePrerequisite', () {
    /// Requirement: doc/specs/content-schema-and-decoder.md FR-118 - a name
    ///   per FR-027 (SRD 5.2.1, "Parts of a Feat: Prerequisite", p. 87).
    /// Path: happy
    test('accepts a printed feature name', () {
      expect(FeaturePrerequisite('Cleave').name, 'Cleave');
    });

    /// Requirement: doc/specs/content-schema-and-decoder.md FR-118 - the
    ///   name must be non-empty with no leading or trailing whitespace.
    /// Path: unhappy (invalid input)
    test('rejects an empty or padded name', () {
      expect(() => FeaturePrerequisite(''), throwsArgumentErrorFor('name', ''));
      expect(
        () => FeaturePrerequisite(' Cleave'),
        throwsArgumentErrorFor('name', ' Cleave'),
      );
      expect(
        () => FeaturePrerequisite('Cleave '),
        throwsArgumentErrorFor('name', 'Cleave '),
      );
    });
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-118 - the
  ///   family is sealed with exactly the three variants, and a switch is
  ///   exhaustive without a default.
  /// Path: happy
  test('a switch over every variant selects its case', () {
    expect(
      [
        _describe(LevelPrerequisite(1)),
        _describe(AbilityScorePrerequisite({Ability.strength}, 13)),
        _describe(FeaturePrerequisite('Cleave')),
      ],
      ['level', 'abilityScore', 'feature'],
    );
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-118 - value
  ///   equality within each variant.
  /// Path: happy
  test('variants compare within their own type', () {
    expect(operatorEquals(LevelPrerequisite(4), LevelPrerequisite(4)), isTrue);
    expect(operatorEquals(LevelPrerequisite(4), LevelPrerequisite(5)), isFalse);
    expect(
      operatorEquals(
        FeaturePrerequisite('Cleave'),
        FeaturePrerequisite('Cleave'),
      ),
      isTrue,
    );
    expect(
      operatorEquals(LevelPrerequisite(4), FeaturePrerequisite('4')),
      isFalse,
    );
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-118 - the
  ///   variants are value objects; hashCode and toString are part of their
  ///   value semantics.
  /// Path: happy
  test('prerequisites hash by value and print their parts', () {
    final level = LevelPrerequisite(4);
    expect(level.hashCode, LevelPrerequisite(4).hashCode);
    expect(level.toString(), 'LevelPrerequisite(4)');

    final ability = AbilityScorePrerequisite({
      Ability.strength,
      Ability.dexterity,
    }, 13);
    expect(ability.toString(), contains('Ability.strength'));
    expect(ability.toString(), contains('Ability.dexterity'));
    expect(ability.toString(), contains('13'));

    final feature = FeaturePrerequisite('Cleave');
    expect(feature.hashCode, FeaturePrerequisite('Cleave').hashCode);
    expect(feature.toString(), 'FeaturePrerequisite(Cleave)');
  });
}
