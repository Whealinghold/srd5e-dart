import 'package:srd5e/src/d20_test/application/d20_test_attempts.dart';
import 'package:srd5e/src/d20_test/application/d20_test_command.dart';
import 'package:srd5e/src/d20_test/domain/armor_class.dart';
import 'package:srd5e/src/d20_test/domain/difficulty_class.dart';
import 'package:srd5e/src/d20_test/domain/roll_modifiers.dart';
import 'package:srd5e/src/shared_kernel/ability/ability.dart';
import 'package:srd5e/src/shared_kernel/modifier.dart';
import 'package:srd5e/src/shared_kernel/roll_circumstance.dart';
import 'package:test/test.dart';

/// Builds the default rolling attempt: an ability modifier and two
/// circumstances, both overridable so a case differs in exactly one field.
RollAttempt _roll({
  int ability = 3,
  List<RollCircumstance> circumstances = const [Advantage()],
}) => RollAttempt(
  modifiers: RollModifiers(ability: Modifier(ability)),
  circumstances: circumstances,
);

void main() {
  /// Requirement: doc/specs/resolve-d20-test-use-case.md FR-001 - the
  ///   command is a sealed D20TestCommand whose variants pair a kind with its
  ///   target and attempt: an AbilityCheckCommand carries a DifficultyClass
  ///   and a CheckAttempt (SRD 5.2.1, "D20 Tests", p. 6). The pairings
  ///   themselves are analyzer-enforced.
  /// Path: happy
  group('FR-001 an AbilityCheckCommand builds and keeps its fields', () {
    /// Requirement: doc/specs/resolve-d20-test-use-case.md FR-001 - an
    ///   ability check carries a DC and a CheckAttempt.
    /// Path: happy
    test('with a RollAttempt', () {
      const target = DifficultyClass(15);
      final attempt = _roll();

      final command = AbilityCheckCommand(
        Ability.strength,
        target: target,
        attempt: attempt,
      );

      expect(command.ability, Ability.strength);
      expect(command.target, target);
      expect(command.attempt, same(attempt));
    });

    /// Requirement: doc/specs/resolve-d20-test-use-case.md FR-001 - a check
    ///   may be attempted as an automatic failure.
    /// Path: happy
    test('with an AutomaticFailure', () {
      const command = AbilityCheckCommand(
        Ability.wisdom,
        target: DifficultyClass(10),
        attempt: AutomaticFailure(),
      );

      expect(command.attempt, isA<AutomaticFailure>());
    });
  });

  /// Requirement: doc/specs/resolve-d20-test-use-case.md FR-001 - a
  ///   SavingThrowCommand carries a DC and a SaveAttempt: a RollAttempt, a
  ///   ChooseToFail or an AutomaticFailure (SRD 5.2.1, "Saving Throws",
  ///   p. 7).
  /// Path: happy
  test('a SavingThrowCommand builds and keeps its fields', () {
    const target = DifficultyClass(12);

    const chosen = SavingThrowCommand(
      Ability.dexterity,
      target: target,
      attempt: ChooseToFail(),
    );

    expect(chosen.ability, Ability.dexterity);
    expect(chosen.target, target);
    expect(chosen.attempt, isA<ChooseToFail>());
  });

  /// Requirement: doc/specs/resolve-d20-test-use-case.md FR-001 - an
  ///   AttackRollCommand carries an ArmorClass and always rolls
  ///   (SRD 5.2.1, "Attack Rolls", p. 7).
  /// Path: happy
  test('an AttackRollCommand builds and keeps its fields', () {
    const target = ArmorClass(17);
    final attempt = _roll();

    final command = AttackRollCommand(
      Ability.strength,
      target: target,
      attempt: attempt,
    );

    expect(command.ability, Ability.strength);
    expect(command.target, target);
    expect(command.attempt, same(attempt));
  });

  /// Requirement: doc/specs/resolve-d20-test-use-case.md FR-005 - a command
  ///   is a value object: equal inputs give equal commands and hash codes
  ///   (doc/rules/architecture.md §3).
  /// Path: happy
  group('FR-005 equal commands are equal with equal hash codes', () {
    /// Requirement: doc/specs/resolve-d20-test-use-case.md FR-005 - equal
    ///   inputs give equal commands, per variant.
    /// Path: happy
    test('checks, saves and attacks', () {
      final check = AbilityCheckCommand(
        Ability.strength,
        target: const DifficultyClass(15),
        attempt: _roll(),
      );
      final sameCheck = AbilityCheckCommand(
        Ability.strength,
        target: const DifficultyClass(15),
        attempt: _roll(),
      );
      final save = SavingThrowCommand(
        Ability.dexterity,
        target: const DifficultyClass(12),
        attempt: _roll(circumstances: const []),
      );
      final sameSave = SavingThrowCommand(
        Ability.dexterity,
        target: const DifficultyClass(12),
        attempt: _roll(circumstances: const []),
      );
      final attack = AttackRollCommand(
        Ability.strength,
        target: const ArmorClass(16),
        attempt: _roll(),
      );
      final sameAttack = AttackRollCommand(
        Ability.strength,
        target: const ArmorClass(16),
        attempt: _roll(),
      );

      expect(check, sameCheck);
      expect(check.hashCode, sameCheck.hashCode);
      expect(save, sameSave);
      expect(save.hashCode, sameSave.hashCode);
      expect(attack, sameAttack);
      expect(attack.hashCode, sameAttack.hashCode);
    });

    /// Requirement: doc/specs/resolve-d20-test-use-case.md FR-005 - two
    ///   ChooseToFail values are equal, as are two AutomaticFailure values.
    /// Path: happy
    test('field-less attempts are equal to one another', () {
      expect(const ChooseToFail(), const ChooseToFail());
      expect((const ChooseToFail()).hashCode, (const ChooseToFail()).hashCode);
      expect(const AutomaticFailure(), const AutomaticFailure());
      expect(
        (const AutomaticFailure()).hashCode,
        (const AutomaticFailure()).hashCode,
      );
    });
  });

  /// Requirement: doc/specs/resolve-d20-test-use-case.md FR-005 - any
  ///   differing input differs: the ability, the target, the attempt's type,
  ///   and for a RollAttempt its modifiers and circumstances.
  /// Path: unhappy (any differing field)
  test('commands differing in one input are unequal', () {
    final base = AbilityCheckCommand(
      Ability.strength,
      target: const DifficultyClass(15),
      attempt: _roll(),
    );

    expect(
      base,
      isNot(
        AbilityCheckCommand(
          Ability.dexterity,
          target: const DifficultyClass(15),
          attempt: _roll(),
        ),
      ),
    );
    expect(
      base,
      isNot(
        AbilityCheckCommand(
          Ability.strength,
          target: const DifficultyClass(16),
          attempt: _roll(),
        ),
      ),
    );
    expect(
      base,
      isNot(
        AbilityCheckCommand(
          Ability.strength,
          target: const DifficultyClass(15),
          attempt: _roll(ability: 4),
        ),
      ),
    );
    expect(
      base,
      isNot(
        AbilityCheckCommand(
          Ability.strength,
          target: const DifficultyClass(15),
          // Order matters: the circumstances compare in order.
          attempt: _roll(circumstances: const [Disadvantage(), Advantage()]),
        ),
      ),
    );
    expect(
      base,
      isNot(
        AbilityCheckCommand(
          Ability.strength,
          target: const DifficultyClass(15),
          attempt: _roll(circumstances: const [Disadvantage()]),
        ),
      ),
    );
    expect(
      base,
      isNot(
        AbilityCheckCommand(
          Ability.strength,
          target: const DifficultyClass(15),
          attempt: _roll(circumstances: const []),
        ),
      ),
    );
    expect(
      base,
      isNot(
        const AbilityCheckCommand(
          Ability.strength,
          target: DifficultyClass(15),
          attempt: AutomaticFailure(),
        ),
      ),
    );
    // A save attempt of a different type differs, whatever its fields.
    const chosen = SavingThrowCommand(
      Ability.dexterity,
      target: DifficultyClass(12),
      attempt: ChooseToFail(),
    );
    expect(
      chosen,
      isNot(
        const SavingThrowCommand(
          Ability.dexterity,
          target: DifficultyClass(12),
          attempt: AutomaticFailure(),
        ),
      ),
    );
  });

  /// Requirement: doc/specs/resolve-d20-test-use-case.md FR-056 - a command
  ///   copies its collections: mutating the caller's list afterwards changes
  ///   nothing and mutating the command's own view throws UnsupportedError
  ///   (doc/rules/architecture.md §3, §4).
  /// Path: unhappy (immutability)
  test('a RollAttempt copies its circumstances', () {
    final source = <RollCircumstance>[const Advantage()];
    final attempt = RollAttempt(
      modifiers: RollModifiers(ability: const Modifier(1)),
      circumstances: source,
    );

    source.add(const Disadvantage());

    expect(attempt.circumstances, hasLength(1));
    // The declared member type is Iterable<RollCircumstance> (FR-056), so a
    // caller sees no mutation members; the held value is an unmodifiable
    // list copy, and mutating it throws.
    expect(
      () => (attempt.circumstances as List<RollCircumstance>).add(
        const Disadvantage(),
      ),
      throwsUnsupportedError,
    );
  });

  /// Requirement: doc/specs/resolve-d20-test-use-case.md FR-056 - a command
  ///   holds its RollModifiers as built: the source of the others is copied
  ///   by RollModifiers itself, so later changes change nothing.
  /// Path: unhappy (immutability)
  test('the modifiers of a command are as built', () {
    final others = [const Modifier(2)];
    final attempt = RollAttempt(
      modifiers: RollModifiers(ability: const Modifier(1), others: others),
    );
    final command = AbilityCheckCommand(
      Ability.strength,
      target: const DifficultyClass(15),
      attempt: attempt,
    );
    expect(command.attempt, same(attempt));

    others.add(const Modifier(5));

    expect(attempt.modifiers.others, hasLength(1));
    expect(
      () => attempt.modifiers.others.add(const Modifier(7)),
      throwsUnsupportedError,
    );
  });
}
