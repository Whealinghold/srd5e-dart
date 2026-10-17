import 'package:srd5e/src/content/domain/classes/ability_requirement.dart';
import 'package:srd5e/src/shared_kernel/ability/ability.dart';
import 'package:test/test.dart';

import '../../../support/argument_error_matcher.dart';
import '../../../support/operator_equals.dart';

void main() {
  /// Requirement: doc/specs/content-classes.md FR-014 - `isMetBy` returns
  ///   true for `AllOf` when every listed ability is in `meeting` and for
  ///   `AnyOf` when at least one is; unlisted abilities in `meeting` are
  ///   ignored (SRD 5.2.1, "Multiclassing", "Prerequisites", p. 24).
  /// Path: happy
  group('Cases AR: isMetBy', () {
    /// Requirement: per case
    /// Path: per case
    for (final c in [
      (
        label: 'single, met',
        requirement:
            'doc/specs/content-classes.md FR-014 - AllOf Strength is met '
            'by Strength alone',
        path: 'happy',
        build: () => AllOf([Ability.strength]) as AbilityRequirement,
        meeting: {Ability.strength},
        expected: true,
      ),
      (
        label: 'single, not met',
        requirement:
            'doc/specs/content-classes.md FR-014 - AllOf Strength is not '
            'met by an empty set',
        path: 'unhappy (empty case)',
        build: () => AllOf([Ability.strength]) as AbilityRequirement,
        meeting: <Ability>{},
        expected: false,
      ),
      (
        label: 'both required, one met',
        requirement:
            'doc/specs/content-classes.md FR-014 - AllOf Dexterity, '
            'Wisdom is not met by Dexterity alone',
        path: 'unhappy (boundary)',
        build: () =>
            AllOf([Ability.dexterity, Ability.wisdom]) as AbilityRequirement,
        meeting: {Ability.dexterity},
        expected: false,
      ),
      (
        label: 'both required, both met',
        requirement:
            'doc/specs/content-classes.md FR-014 - AllOf Dexterity, '
            'Wisdom is met by both',
        path: 'happy',
        build: () =>
            AllOf([Ability.dexterity, Ability.wisdom]) as AbilityRequirement,
        meeting: {Ability.dexterity, Ability.wisdom},
        expected: true,
      ),
      (
        label: 'either, first',
        requirement:
            'doc/specs/content-classes.md FR-014 - AnyOf Strength, '
            'Dexterity is met by Strength',
        path: 'happy',
        build: () =>
            AnyOf([Ability.strength, Ability.dexterity]) as AbilityRequirement,
        meeting: {Ability.strength},
        expected: true,
      ),
      (
        label: 'either, second',
        requirement:
            'doc/specs/content-classes.md FR-014 - AnyOf Strength, '
            'Dexterity is met by Dexterity',
        path: 'happy',
        build: () =>
            AnyOf([Ability.strength, Ability.dexterity]) as AbilityRequirement,
        meeting: {Ability.dexterity},
        expected: true,
      ),
      (
        label: 'either, neither',
        requirement:
            'doc/specs/content-classes.md FR-014 - AnyOf Strength, '
            'Dexterity is not met by Constitution',
        path: 'unhappy (boundary)',
        build: () =>
            AnyOf([Ability.strength, Ability.dexterity]) as AbilityRequirement,
        meeting: {Ability.constitution},
        expected: false,
      ),
      (
        label: 'either, none',
        requirement:
            'doc/specs/content-classes.md FR-014 - AnyOf Strength, '
            'Dexterity is not met by an empty set',
        path: 'unhappy (empty case)',
        build: () =>
            AnyOf([Ability.strength, Ability.dexterity]) as AbilityRequirement,
        meeting: <Ability>{},
        expected: false,
      ),
      (
        label: 'extra ignored',
        requirement:
            'doc/specs/content-classes.md FR-014 - AllOf Charisma is met '
            'by a set holding all six abilities; the unlisted ones are '
            'ignored',
        path: 'unhappy (rule interaction)',
        build: () => AllOf([Ability.charisma]) as AbilityRequirement,
        meeting: Ability.values.toSet(),
        expected: true,
      ),
    ]) {
      test('${c.label} [${c.path}]', () {
        expect(c.build().isMetBy(c.meeting), c.expected);
      });
    }
  });

  /// Requirement: doc/specs/content-classes.md FR-011 - `AbilityRequirement`
  ///   is a sealed class with exactly `AllOf` and `AnyOf`, exhaustive in a
  ///   `switch` without a default.
  /// Path: happy
  test('a switch over the family selects its case', () {
    String describe(AbilityRequirement requirement) => switch (requirement) {
      AllOf() => 'all',
      AnyOf() => 'any',
    };
    expect(describe(AllOf([Ability.strength])), 'all');
    expect(describe(AnyOf([Ability.strength, Ability.dexterity])), 'any');
  });

  /// Requirement: doc/specs/content-classes.md FR-015 - `abilities`
  ///   preserves the printed order and is unmodifiable.
  /// Path: happy
  test('abilities keep the printed order and cannot be mutated', () {
    final requirement = AllOf([Ability.dexterity, Ability.wisdom]);
    expect(requirement.abilities, [Ability.dexterity, Ability.wisdom]);
    expect(
      () => requirement.abilities.add(Ability.strength),
      throwsUnsupportedError,
    );
  });

  /// Requirement: doc/specs/content-classes.md FR-012 - an empty `AllOf`
  ///   list is rejected (SRD 5.2.1, "Core Barbarian Traits", p. 28).
  /// Path: unhappy (boundary)
  test('an AllOf of no ability is rejected', () {
    const empty = <Ability>[];
    expect(() => AllOf(empty), throwsArgumentErrorFor('abilities', empty));
  });

  /// Requirement: doc/specs/content-classes.md FR-012 - a repeated ability
  ///   is rejected (Cases FT: "primary ability repeated").
  /// Path: unhappy (boundary)
  test('an AllOf of a repeated ability is rejected', () {
    expect(
      () => AllOf([Ability.strength, Ability.strength]),
      throwsArgumentErrorFor('abilities', Ability.strength),
    );
  });

  /// Requirement: doc/specs/content-classes.md FR-013 - `AnyOf` of one is
  ///   the same fact as `AllOf` of one and is not representable (D14;
  ///   Cases FT: "any-of of one", SRD 5.2.1, "Core Fighter Traits", p. 47).
  /// Path: unhappy (boundary)
  test('an AnyOf of one ability is rejected', () {
    final single = [Ability.strength];
    expect(() => AnyOf(single), throwsArgumentErrorFor('abilities', single));
  });

  /// Requirement: doc/specs/content-classes.md FR-013 - a repeated ability
  ///   in an `AnyOf` is rejected.
  /// Path: unhappy (boundary)
  test('an AnyOf of a repeated ability is rejected', () {
    expect(
      () => AnyOf([Ability.strength, Ability.strength]),
      throwsArgumentErrorFor('abilities', Ability.strength),
    );
  });

  /// Requirement: doc/specs/content-classes.md FR-007, FR-008 - the limits
  ///   are public constants and predicates, and the variants have value
  ///   equality with a consistent hash code.
  /// Path: happy
  test('limits are exposed and value equality holds', () {
    expect(AllOf.minAbilities, 1);
    expect(AnyOf.minAbilities, 2);
    expect(AllOf.isValid([Ability.strength]), isTrue);
    expect(AllOf.isValid(const []), isFalse);
    expect(AllOf.isValid([Ability.strength, Ability.strength]), isFalse);
    // A repeat is caught whatever sits between the repeats.
    expect(
      AllOf.isValid([Ability.strength, Ability.dexterity, Ability.strength]),
      isFalse,
    );
    expect(AnyOf.isValid([Ability.strength]), isFalse);
    expect(AnyOf.isValid([Ability.strength, Ability.dexterity]), isTrue);
    expect(AnyOf.isValid([Ability.strength, Ability.strength]), isFalse);

    final a = AnyOf([Ability.strength, Ability.dexterity]);
    final b = AnyOf([Ability.strength, Ability.dexterity]);
    expect(a, equals(b));
    expect(a.hashCode, b.hashCode);
    expect(a, isNot(equals(AllOf([Ability.strength, Ability.dexterity]))));
    expect(operatorEquals(a, Object()), isFalse);
    expect(AllOf([Ability.strength]).toString(), 'AllOf([Ability.strength])');
    expect(
      AnyOf([Ability.strength, Ability.dexterity]).toString(),
      'AnyOf([Ability.strength, Ability.dexterity])',
    );
  });
}
