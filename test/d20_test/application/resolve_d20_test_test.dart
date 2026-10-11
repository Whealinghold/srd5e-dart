import 'package:srd5e/src/d20_test/application/d20_test_attempts.dart';
import 'package:srd5e/src/d20_test/application/d20_test_command.dart';
import 'package:srd5e/src/d20_test/application/d20_test_signals.dart';
import 'package:srd5e/src/d20_test/application/resolve_d20_test.dart';
import 'package:srd5e/src/d20_test/application/resolve_d20_test_result.dart';
import 'package:srd5e/src/d20_test/domain/armor_class.dart';
import 'package:srd5e/src/d20_test/domain/attack_roll_result.dart';
import 'package:srd5e/src/d20_test/domain/check_result.dart';
import 'package:srd5e/src/d20_test/domain/d20_roll.dart';
import 'package:srd5e/src/d20_test/domain/d20_test_kind.dart';
import 'package:srd5e/src/d20_test/domain/d20_test_outcome.dart';
import 'package:srd5e/src/d20_test/domain/difficulty_class.dart';
import 'package:srd5e/src/d20_test/domain/forced_failure_reason.dart';
import 'package:srd5e/src/d20_test/domain/forced_failure_result.dart';
import 'package:srd5e/src/d20_test/domain/roll_modifiers.dart';
import 'package:srd5e/src/shared_kernel/ability/ability.dart';
import 'package:srd5e/src/shared_kernel/dice/dice_expression.dart';
import 'package:srd5e/src/shared_kernel/dice/die.dart';
import 'package:srd5e/src/shared_kernel/dice/die_roll.dart';
import 'package:srd5e/src/shared_kernel/dice/roll_result.dart';
import 'package:srd5e/src/shared_kernel/modifier.dart';
import 'package:srd5e/src/shared_kernel/roll_circumstance.dart';
import 'package:srd5e/src/shared_kernel/roll_mode.dart';
import 'package:srd5e/src/shared_ports/dice_roller/dice_roller_exception.dart';
import 'package:srd5e/src/shared_ports/observability/observability.dart';
import 'package:srd5e/src/shared_ports/observability/tracer.dart';
import 'package:srd5e/src/shared_ports/signals.dart';
import 'package:srd5e/testing.dart';
import 'package:test/test.dart';

/// Which kind of D20 Test a case-table row commands.
enum _Kind { check, save, attack }

/// How a case-table row attempts its test.
enum _Attempt { roll, chosenToFail, automatic }

/// Which result variant a case-table row expects.
enum _Variant { rolledCheck, rolledAttack, forcedFailure }

/// One row of the section 4.3 end-to-end case table, with the modifiers,
/// circumstances, fixed rolls and target of the command, and the expected
/// variant, total, outcome and critical-hit flag.
typedef _Row = ({
  String label,
  String requirement,
  String path,
  _Kind kind,
  Ability ability,
  int abilityModifier,
  int? proficiencyBonus,
  List<int> others,
  List<RollCircumstance> circumstances,
  _Attempt attempt,
  List<int> rolls,
  int target,
  int? total,
  D20TestOutcome outcome,
  bool? critical,
  ForcedFailureReason? reason,
});

/// The 17 rows of resolve-d20-test-use-case.md section 4.3, as written there:
/// rolls in request order, every row carrying the mandatory ability modifier,
/// "Crit" null for a check or save, a forced failure naming its reason.
final List<_Row> _caseRows = [
  (
    label: 'check meets DC',
    requirement:
        'doc/specs/resolve-d20-test-use-case.md FR-007, FR-010, FR-011, '
        'FR-043, FR-058',
    path: 'happy',
    kind: _Kind.check,
    ability: Ability.strength,
    abilityModifier: 5,
    proficiencyBonus: null,
    others: const [],
    circumstances: const [],
    attempt: _Attempt.roll,
    rolls: const [10],
    target: 15,
    total: 15,
    outcome: D20TestOutcome.success,
    critical: null,
    reason: null,
  ),
  (
    label: 'save fails',
    requirement:
        'doc/specs/resolve-d20-test-use-case.md FR-007, FR-010, FR-011',
    path: 'happy',
    kind: _Kind.save,
    ability: Ability.dexterity,
    abilityModifier: 1,
    proficiencyBonus: null,
    others: const [],
    circumstances: const [],
    attempt: _Attempt.roll,
    rolls: const [8],
    target: 10,
    total: 9,
    outcome: D20TestOutcome.failure,
    critical: null,
    reason: null,
  ),
  (
    label: 'attack hits',
    requirement:
        'doc/specs/resolve-d20-test-use-case.md FR-007, FR-010, FR-012, '
        'FR-016',
    path: 'happy',
    kind: _Kind.attack,
    ability: Ability.strength,
    abilityModifier: 3,
    proficiencyBonus: null,
    others: const [],
    circumstances: const [],
    attempt: _Attempt.roll,
    rolls: const [12],
    target: 15,
    total: 15,
    outcome: D20TestOutcome.success,
    critical: false,
    reason: null,
  ),
  (
    label: 'total above 30',
    requirement:
        'doc/specs/resolve-d20-test-use-case.md FR-010, FR-015, FR-028',
    path: 'unhappy (boundary)',
    kind: _Kind.check,
    ability: Ability.strength,
    abilityModifier: 15,
    proficiencyBonus: null,
    others: const [],
    circumstances: const [],
    attempt: _Attempt.roll,
    rolls: const [20],
    target: 30,
    total: 35,
    outcome: D20TestOutcome.success,
    critical: null,
    reason: null,
  ),
  (
    label: 'total below zero',
    requirement:
        'doc/specs/resolve-d20-test-use-case.md FR-010, FR-015, FR-028',
    path: 'unhappy (boundary)',
    kind: _Kind.check,
    ability: Ability.strength,
    abilityModifier: -5,
    proficiencyBonus: null,
    others: const [-2],
    circumstances: const [],
    attempt: _Attempt.roll,
    rolls: const [1],
    target: 5,
    total: -6,
    outcome: D20TestOutcome.failure,
    critical: null,
    reason: null,
  ),
  (
    label: 'extreme low, normal',
    requirement: 'doc/specs/resolve-d20-test-use-case.md FR-028',
    path: 'unhappy (boundary)',
    kind: _Kind.check,
    ability: Ability.strength,
    abilityModifier: 0,
    proficiencyBonus: null,
    others: const [],
    circumstances: const [],
    attempt: _Attempt.roll,
    rolls: const [1],
    target: 5,
    total: 1,
    outcome: D20TestOutcome.failure,
    critical: null,
    reason: null,
  ),
  (
    label: 'extreme high, normal',
    requirement: 'doc/specs/resolve-d20-test-use-case.md FR-013, FR-028',
    path: 'unhappy (boundary)',
    kind: _Kind.attack,
    ability: Ability.strength,
    abilityModifier: 0,
    proficiencyBonus: null,
    others: const [],
    circumstances: const [],
    attempt: _Attempt.roll,
    rolls: const [20],
    target: 30,
    total: 20,
    outcome: D20TestOutcome.success,
    critical: true,
    reason: null,
  ),
  (
    label: 'Advantage uses the higher die',
    requirement:
        'doc/specs/resolve-d20-test-use-case.md FR-006, FR-007, FR-008',
    path: 'happy',
    kind: _Kind.check,
    ability: Ability.strength,
    abilityModifier: 0,
    proficiencyBonus: null,
    others: const [],
    circumstances: const [Advantage()],
    attempt: _Attempt.roll,
    rolls: const [18, 3],
    target: 15,
    total: 18,
    outcome: D20TestOutcome.success,
    critical: null,
    reason: null,
  ),
  (
    label: 'Disadvantage uses the lower die',
    requirement:
        'doc/specs/resolve-d20-test-use-case.md FR-006, FR-007, FR-008',
    path: 'happy',
    kind: _Kind.check,
    ability: Ability.strength,
    abilityModifier: 0,
    proficiencyBonus: null,
    others: const [],
    circumstances: const [Disadvantage()],
    attempt: _Attempt.roll,
    rolls: const [18, 3],
    target: 15,
    total: 3,
    outcome: D20TestOutcome.failure,
    critical: null,
    reason: null,
  ),
  (
    label: 'Advantage, both dice 1',
    requirement:
        'doc/specs/resolve-d20-test-use-case.md FR-009, FR-010, FR-028',
    path: 'unhappy (boundary)',
    kind: _Kind.attack,
    ability: Ability.strength,
    abilityModifier: 20,
    proficiencyBonus: null,
    others: const [],
    circumstances: const [Advantage()],
    attempt: _Attempt.roll,
    rolls: const [1, 1],
    target: 5,
    total: 21,
    outcome: D20TestOutcome.failure,
    critical: false,
    reason: null,
  ),
  (
    label: 'Disadvantage, both dice 20',
    requirement:
        'doc/specs/resolve-d20-test-use-case.md FR-009, FR-010, FR-028',
    path: 'unhappy (boundary)',
    kind: _Kind.attack,
    ability: Ability.strength,
    abilityModifier: -3,
    proficiencyBonus: null,
    others: const [],
    circumstances: const [Disadvantage()],
    attempt: _Attempt.roll,
    rolls: const [20, 20],
    target: 30,
    total: 17,
    outcome: D20TestOutcome.success,
    critical: true,
    reason: null,
  ),
  (
    label: 'Advantage, both dice 20',
    requirement:
        'doc/specs/resolve-d20-test-use-case.md FR-009, FR-010, FR-028',
    path: 'unhappy (boundary)',
    kind: _Kind.attack,
    ability: Ability.strength,
    abilityModifier: -3,
    proficiencyBonus: null,
    others: const [],
    circumstances: const [Advantage()],
    attempt: _Attempt.roll,
    rolls: const [20, 20],
    target: 30,
    total: 17,
    outcome: D20TestOutcome.success,
    critical: true,
    reason: null,
  ),
  (
    label: 'Disadvantage, both dice 1',
    requirement:
        'doc/specs/resolve-d20-test-use-case.md FR-009, FR-010, FR-028',
    path: 'unhappy (boundary)',
    kind: _Kind.attack,
    ability: Ability.strength,
    abilityModifier: 20,
    proficiencyBonus: null,
    others: const [],
    circumstances: const [Disadvantage()],
    attempt: _Attempt.roll,
    rolls: const [1, 1],
    target: 5,
    total: 21,
    outcome: D20TestOutcome.failure,
    critical: false,
    reason: null,
  ),
  (
    label: 'Disadvantage, natural 1 used',
    requirement:
        'doc/specs/resolve-d20-test-use-case.md FR-007, FR-014, FR-017, '
        'FR-028',
    path: 'unhappy (rule interaction)',
    kind: _Kind.attack,
    ability: Ability.strength,
    abilityModifier: 10,
    proficiencyBonus: null,
    others: const [],
    circumstances: const [Disadvantage()],
    attempt: _Attempt.roll,
    rolls: const [20, 1],
    target: 5,
    total: 11,
    outcome: D20TestOutcome.failure,
    critical: false,
    reason: null,
  ),
  (
    label: 'Advantage and Disadvantage cancel',
    requirement: 'doc/specs/resolve-d20-test-use-case.md FR-006, FR-007',
    path: 'unhappy (rule interaction)',
    kind: _Kind.check,
    ability: Ability.strength,
    abilityModifier: 0,
    proficiencyBonus: null,
    others: const [],
    circumstances: const [Advantage(), Disadvantage()],
    attempt: _Attempt.roll,
    rolls: const [14],
    target: 15,
    total: 14,
    outcome: D20TestOutcome.failure,
    critical: null,
    reason: null,
  ),
  (
    label: 'chosen to fail a save',
    requirement: 'doc/specs/resolve-d20-test-use-case.md FR-007, FR-058',
    path: 'happy',
    kind: _Kind.save,
    ability: Ability.dexterity,
    abilityModifier: 0,
    proficiencyBonus: null,
    others: const [],
    circumstances: const [],
    attempt: _Attempt.chosenToFail,
    rolls: const [],
    target: 10,
    total: null,
    outcome: D20TestOutcome.failure,
    critical: null,
    reason: ForcedFailureReason.chosenToFail,
  ),
  (
    label: 'automatic failure on a check',
    requirement: 'doc/specs/resolve-d20-test-use-case.md FR-007, FR-058',
    path: 'happy',
    kind: _Kind.check,
    ability: Ability.wisdom,
    abilityModifier: 0,
    proficiencyBonus: null,
    others: const [],
    circumstances: const [],
    attempt: _Attempt.automatic,
    rolls: const [],
    target: 10,
    total: null,
    outcome: D20TestOutcome.failure,
    critical: null,
    reason: ForcedFailureReason.automatic,
  ),
];

/// Which variant a row resolves to, from the row's kind and attempt.
_Variant _variantOf(_Row row) => switch ((row.kind, row.attempt)) {
  (_Kind.attack, _) => _Variant.rolledAttack,
  (_, _Attempt.roll) => _Variant.rolledCheck,
  (_, _) => _Variant.forcedFailure,
};

/// The [RollModifiers] of a row.
RollModifiers _modifiersOf(_Row row) => RollModifiers(
  ability: Modifier(row.abilityModifier),
  proficiencyBonus: row.proficiencyBonus == null
      ? null
      : Modifier(row.proficiencyBonus!),
  others: [for (final value in row.others) Modifier(value)],
);

/// The [D20TestCommand] of a row.
D20TestCommand _commandOf(_Row row) {
  final modifiers = _modifiersOf(row);
  return switch (row.kind) {
    _Kind.attack => AttackRollCommand(
      row.ability,
      target: ArmorClass(row.target),
      attempt: RollAttempt(
        modifiers: modifiers,
        circumstances: row.circumstances,
      ),
    ),
    _Kind.check => AbilityCheckCommand(
      row.ability,
      target: DifficultyClass(row.target),
      attempt: switch (row.attempt) {
        _Attempt.roll => RollAttempt(
          modifiers: modifiers,
          circumstances: row.circumstances,
        ),
        _Attempt.chosenToFail =>
          // The case table never chooses to fail a check.
          throw StateError('chosenToFail is a save attempt'),
        _Attempt.automatic => const AutomaticFailure(),
      },
    ),
    _Kind.save => SavingThrowCommand(
      row.ability,
      target: DifficultyClass(row.target),
      attempt: switch (row.attempt) {
        _Attempt.roll => RollAttempt(
          modifiers: modifiers,
          circumstances: row.circumstances,
        ),
        _Attempt.chosenToFail => const ChooseToFail(),
        _Attempt.automatic => const AutomaticFailure(),
      },
    ),
  };
}

/// The resolved result of a row and the expressions the roller was asked for.
typedef _Run = ({ResolveD20TestResult result, List<DiceExpression> requests});

/// Resolves one row against a fresh fixed roller, under [observability].
_Run _run(_Row row, {Observability observability = Observability.none}) {
  final roller = FixedDiceRoller(row.rolls);
  final resolve = ResolveD20Test(roller, observability: observability);
  final result = resolve(_commandOf(row));
  return (result: result, requests: List.of(roller.requests));
}

/// Every attribute value of every row must sit in its closed set, or be a
/// bool for the critical-hit flag (FR-038); `error.type` is the one constant
/// of the thrown subtype (FR-036, errors-and-results.md FR-034).
void _expectClosedSets(Map<String, Object> attributes) {
  for (final MapEntry(:key, :value) in attributes.entries) {
    if (key == D20TestSignals.kindAttribute) {
      expect(
        value,
        anyOf('ability_check', 'saving_throw', 'attack_roll'),
        reason: '$key closed set',
      );
    } else if (key == D20TestSignals.abilityAttribute) {
      expect(
        value,
        anyOf(
          'strength',
          'dexterity',
          'constitution',
          'intelligence',
          'wisdom',
          'charisma',
        ),
        reason: '$key closed set',
      );
    } else if (key == D20TestSignals.rollModeAttribute) {
      expect(
        value,
        anyOf('normal', 'advantage', 'disadvantage'),
        reason: '$key closed set',
      );
    } else if (key == AttributeKeys.outcome) {
      expect(value, anyOf('success', 'failure'), reason: '$key closed set');
    } else if (key == D20TestSignals.criticalHitAttribute) {
      expect(value, isA<bool>(), reason: '$key is a bool, never a string');
    } else if (key == AttributeKeys.errorType) {
      expect(value, 'dice_roller_exception', reason: '$key closed set');
    } else if (key == D20TestSignals.rollerFailureAttribute) {
      expect(
        value,
        anyOf('unavailable', 'invalid_result'),
        reason: '$key closed set',
      );
    } else if (key == D20TestSignals.forcedFailureReasonAttribute) {
      expect(
        value,
        anyOf('chosen_to_fail', 'automatic'),
        reason: '$key closed set',
      );
    } else {
      fail('unexpected attribute key $key');
    }
  }
}

void main() {
  /// Requirement: per case
  /// Path: per case
  group('the section 4.3 case table resolves end to end', () {
    /// Requirement: per case
    /// Path: per case
    for (final row in _caseRows) {
      test('${row.label} [${row.path}]', () {
        final (:result, :requests) = _run(row);
        final mode = RollMode.resolve(row.circumstances);

        // Exactly one request, sized by the resolved mode; none for a
        // forced failure.
        if (row.rolls.isEmpty) {
          expect(requests, isEmpty);
        } else {
          expect(requests, [DiceExpression(mode.diceCount, Die.d20)]);
        }

        switch (_variantOf(row)) {
          case _Variant.rolledCheck:
            final ResolveD20TestRolledCheck(:ability, result: check) =
                result as ResolveD20TestRolledCheck;
            expect(ability, row.ability);
            expect(
              check.kind,
              row.kind == _Kind.check
                  ? D20TestKind.abilityCheck
                  : D20TestKind.savingThrow,
            );
            expect(check.roll, D20Roll(mode: mode, dice: row.rolls));
            expect(check.roll.mode, mode);
            expect(check.modifiers, _modifiersOf(row));
            expect(check.total, row.total);
            expect(check.target, DifficultyClass(row.target));
            expect(check.outcome, row.outcome);
          case _Variant.rolledAttack:
            final ResolveD20TestRolledAttack(:ability, result: attack) =
                result as ResolveD20TestRolledAttack;
            expect(ability, row.ability);
            expect(attack.roll, D20Roll(mode: mode, dice: row.rolls));
            expect(attack.modifiers, _modifiersOf(row));
            expect(attack.total, row.total);
            expect(attack.target, ArmorClass(row.target));
            expect(attack.outcome, row.outcome);
            expect(attack.isCriticalHit, row.critical);
          case _Variant.forcedFailure:
            final ResolveD20TestForcedFailure(
              :ability,
              result: forced,
              :target,
            ) = result as ResolveD20TestForcedFailure;
            expect(ability, row.ability);
            expect(
              forced.kind,
              row.kind == _Kind.check
                  ? D20TestKind.abilityCheck
                  : D20TestKind.savingThrow,
            );
            expect(forced.reason, row.reason);
            expect(target, DifficultyClass(row.target));
        }
      });
    }
  });

  /// Requirement: doc/specs/resolve-d20-test-use-case.md FR-002 - a minimal
  ///   command (a RollAttempt whose RollModifiers holds only the mandatory
  ///   ability modifier and whose circumstances is empty, so
  ///   RollMode.normal) resolves with one d20 requested and a total equal to
  ///   the d20 used plus the ability modifier (SRD 5.2.1, "D20 Tests", p. 6).
  /// Path: unhappy (empty and minimal)
  test('a minimal command requests one d20 and adds the ability modifier', () {
    final roller = FixedDiceRoller(const [14]);
    final resolve = ResolveD20Test(roller);
    final command = AbilityCheckCommand(
      Ability.charisma,
      target: const DifficultyClass(10),
      attempt: RollAttempt(
        modifiers: RollModifiers(ability: const Modifier(3)),
      ),
    );

    final result = resolve(command);

    expect(roller.requests, [DiceExpression(1, Die.d20)]);
    final ResolveD20TestRolledCheck(result: check) =
        result as ResolveD20TestRolledCheck;
    expect(check.roll.natural, 14);
    expect(check.total, 17);
  });

  /// Requirement: doc/specs/resolve-d20-test-use-case.md FR-007 - exactly one
  ///   rollChecked request for DiceExpression(mode.diceCount, Die.d20) with
  ///   modifier 0, and no request at all for ChooseToFail or AutomaticFailure
  ///   (SRD 5.2.1, "Roll 1d20", p. 6; "Roll Two D20s", p. 8).
  /// Path: happy
  group('the dice requested follow the resolved mode', () {
    /// Requirement: per case
    /// Path: per case
    for (final row in _caseRows) {
      test('${row.label} asks for '
          '${row.rolls.isEmpty ? 'nothing' : '${RollMode.resolve(row.circumstances).diceCount}d20'} '
          '[${row.path}]', () {
        final (:result, :requests) = _run(row);
        final mode = RollMode.resolve(row.circumstances);

        if (row.rolls.isEmpty) {
          expect(requests, isEmpty);
          expect(result, isA<ResolveD20TestForcedFailure>());
        } else {
          expect(requests, hasLength(1));
          expect(requests.single.count, mode.diceCount);
          expect(requests.single.die, Die.d20);
          expect(requests.single.modifier, 0);
        }
      });
    }
  });

  /// Requirement: doc/specs/resolve-d20-test-use-case.md FR-018 - a rolled
  ///   result carries the breakdown needed to explain it without
  ///   recomputation, populated from what the use case requested and the
  ///   domain returned (doc/rules/architecture.md §6).
  /// Path: happy
  group('each result variant carries its whole breakdown', () {
    /// Requirement: doc/specs/resolve-d20-test-use-case.md FR-018 and FR-043
    ///   - a ResolveD20TestRolledCheck carries the ability, and the domain
    ///   result's kind (the variant itself has no kind field), roll, mode,
    ///   dice in request order, natural value, modifiers, total, DC and
    ///   outcome.
    /// Path: happy
    test(
      'a rolled check carries kind, roll, modifiers, total, target, outcome',
      () {
        final (:result, :requests) = _run(_caseRows[0]);

        expect(result, isA<ResolveD20TestRolledCheck>());
        final ResolveD20TestRolledCheck(:ability, result: check) =
            result as ResolveD20TestRolledCheck;
        expect(ability, Ability.strength);
        expect(check.kind, D20TestKind.abilityCheck);
        expect(check.roll.mode, RollMode.normal);
        expect(check.roll.dice, [10]);
        expect(check.roll.natural, 10);
        expect(check.roll.keptIndex, 0);
        expect(check.modifiers, RollModifiers(ability: const Modifier(5)));
        expect(check.total, 15);
        expect(check.target, const DifficultyClass(15));
        expect(check.outcome, D20TestOutcome.success);
        expect(requests, hasLength(1));
      },
    );

    /// Requirement: doc/specs/resolve-d20-test-use-case.md FR-018 - a
    ///   ResolveD20TestRolledAttack carries the same with an ArmorClass and
    ///   isCriticalHit.
    /// Path: happy
    test(
      'a rolled attack carries roll, modifiers, total, AC, outcome, crit',
      () {
        final ResolveD20TestRolledAttack(:ability, result: attack) =
            _run(_caseRows[2]).result as ResolveD20TestRolledAttack;

        expect(ability, Ability.strength);
        expect(attack.roll.mode, RollMode.normal);
        expect(attack.roll.dice, [12]);
        expect(attack.roll.natural, 12);
        expect(attack.modifiers, RollModifiers(ability: const Modifier(3)));
        expect(attack.total, 15);
        expect(attack.target, const ArmorClass(15));
        expect(attack.outcome, D20TestOutcome.success);
        expect(attack.isCriticalHit, isFalse);
      },
    );

    /// Requirement: doc/specs/resolve-d20-test-use-case.md FR-018 - a
    ///   ResolveD20TestForcedFailure carries the kind and reason, plus the
    ///   target the variant adds.
    /// Path: happy
    test('a forced failure carries kind, reason and the DC', () {
      final ResolveD20TestForcedFailure(:ability, result: forced, :target) =
          _run(_caseRows[16]).result as ResolveD20TestForcedFailure;

      expect(ability, Ability.wisdom);
      expect(forced.kind, D20TestKind.abilityCheck);
      expect(forced.reason, ForcedFailureReason.automatic);
      expect(target, const DifficultyClass(10));
    });
  });

  /// Requirement: doc/specs/resolve-d20-test-use-case.md FR-049 - the target
  ///   in a result is typed by variant: a DifficultyClass for the check and
  ///   forced-failure variants, an ArmorClass for the attack variant; no
  ///   union or num target type exists (SRD 5.2.1, "D20 Tests", p. 6;
  ///   "Armor Class", p. 7).
  /// Path: happy
  test('the target is typed by variant', () {
    final check = _run(_caseRows[0]).result;
    final attack = _run(_caseRows[2]).result;
    final forced = _run(_caseRows[16]).result;

    final ResolveD20TestRolledCheck(result: checkResult) =
        check as ResolveD20TestRolledCheck;
    expect(checkResult.target.runtimeType, DifficultyClass);
    final ResolveD20TestRolledAttack(result: attackResult) =
        attack as ResolveD20TestRolledAttack;
    expect(attackResult.target.runtimeType, ArmorClass);
    final ResolveD20TestForcedFailure(:target) =
        forced as ResolveD20TestForcedFailure;
    expect(target.runtimeType, DifficultyClass);
  });

  /// Requirement: doc/specs/resolve-d20-test-use-case.md FR-020 and FR-053 -
  ///   ResolveD20TestResult is a closed set of the three operation-prefixed
  ///   variants, so a switch without a default is exhaustive and compiles
  ///   only while no variant is missing (doc/rules/architecture.md §3, §4).
  /// Path: happy
  test('a marker switch over the result variants covers all three', () {
    String marker(ResolveD20TestResult result) => switch (result) {
      ResolveD20TestRolledCheck() => 'ResolveD20TestRolledCheck',
      ResolveD20TestRolledAttack() => 'ResolveD20TestRolledAttack',
      ResolveD20TestForcedFailure() => 'ResolveD20TestForcedFailure',
    };

    expect(marker(_run(_caseRows[0]).result), 'ResolveD20TestRolledCheck');
    expect(marker(_run(_caseRows[2]).result), 'ResolveD20TestRolledAttack');
    expect(marker(_run(_caseRows[16]).result), 'ResolveD20TestForcedFailure');
  });

  /// Requirement: doc/specs/resolve-d20-test-use-case.md FR-021 - a result is
  ///   a value object: equal when every field is equal, with equal hash codes
  ///   (doc/rules/architecture.md §3).
  /// Path: happy
  group('results are value objects', () {
    /// Requirement: doc/specs/resolve-d20-test-use-case.md FR-021 - two runs
    ///   of the same command and the same roller values give equal results.
    /// Path: happy
    test('two identical runs give equal results', () {
      for (final row in _caseRows) {
        expect(_run(row).result, _run(row).result, reason: row.label);
      }
    });

    /// Requirement: doc/specs/resolve-d20-test-use-case.md FR-021 - results
    ///   differing in one field are unequal.
    /// Path: unhappy (any differing field)
    test('results differing in one field are unequal', () {
      final roll = D20Roll(mode: RollMode.normal, dice: const [10]);
      final modifiers = RollModifiers(ability: const Modifier(5));
      const dc = DifficultyClass(15);
      final check = CheckResult.resolve(
        D20TestKind.abilityCheck,
        roll,
        modifiers,
        dc,
      );
      final base = ResolveD20TestRolledCheck(Ability.strength, result: check);

      expect(base, ResolveD20TestRolledCheck(Ability.strength, result: check));
      expect(
        base.hashCode,
        ResolveD20TestRolledCheck(Ability.strength, result: check).hashCode,
      );
      expect(
        base,
        isNot(ResolveD20TestRolledCheck(Ability.dexterity, result: check)),
      );
      expect(
        base,
        isNot(
          ResolveD20TestRolledCheck(
            Ability.strength,
            result: CheckResult.resolve(
              D20TestKind.abilityCheck,
              D20Roll(mode: RollMode.normal, dice: const [11]),
              modifiers,
              dc,
            ),
          ),
        ),
      );

      final attack = AttackRollResult.resolve(
        roll,
        modifiers,
        const ArmorClass(15),
      );
      final attackBase = ResolveD20TestRolledAttack(
        Ability.strength,
        result: attack,
      );
      expect(
        attackBase,
        ResolveD20TestRolledAttack(Ability.strength, result: attack),
      );
      expect(
        attackBase.hashCode,
        ResolveD20TestRolledAttack(Ability.strength, result: attack).hashCode,
      );
      expect(
        attackBase,
        isNot(
          ResolveD20TestRolledAttack(
            Ability.strength,
            result: AttackRollResult.resolve(
              D20Roll(mode: RollMode.normal, dice: const [20]),
              modifiers,
              const ArmorClass(15),
            ),
          ),
        ),
      );

      const forced = ResolveD20TestForcedFailure(
        Ability.wisdom,
        result: ForcedFailureResult(
          kind: D20TestKind.abilityCheck,
          reason: ForcedFailureReason.automatic,
        ),
        target: DifficultyClass(10),
      );
      expect(
        forced,
        const ResolveD20TestForcedFailure(
          Ability.wisdom,
          result: ForcedFailureResult(
            kind: D20TestKind.abilityCheck,
            reason: ForcedFailureReason.automatic,
          ),
          target: DifficultyClass(10),
        ),
      );
      expect(
        forced.hashCode,
        const ResolveD20TestForcedFailure(
          Ability.wisdom,
          result: ForcedFailureResult(
            kind: D20TestKind.abilityCheck,
            reason: ForcedFailureReason.automatic,
          ),
          target: DifficultyClass(10),
        ).hashCode,
      );
      expect(
        forced,
        isNot(
          const ResolveD20TestForcedFailure(
            Ability.wisdom,
            result: ForcedFailureResult(
              kind: D20TestKind.abilityCheck,
              reason: ForcedFailureReason.chosenToFail,
            ),
            target: DifficultyClass(10),
          ),
        ),
      );
      expect(
        forced,
        isNot(
          const ResolveD20TestForcedFailure(
            Ability.wisdom,
            result: ForcedFailureResult(
              kind: D20TestKind.abilityCheck,
              reason: ForcedFailureReason.automatic,
            ),
            target: DifficultyClass(12),
          ),
        ),
      );
    });
  });

  /// Requirement: doc/specs/resolve-d20-test-use-case.md FR-022 - the use
  ///   case must not modify its command: after call returns, the command and
  ///   the collections it was built from equal what they were before
  ///   (doc/rules/testing.md §4).
  /// Path: unhappy (immutability)
  test('call leaves the command and its source collections untouched', () {
    final source = [const Advantage()];
    final others = [const Modifier(2)];
    final modifiers = RollModifiers(ability: const Modifier(3), others: others);
    final attempt = RollAttempt(modifiers: modifiers, circumstances: source);
    final command = AbilityCheckCommand(
      Ability.strength,
      target: const DifficultyClass(15),
      attempt: attempt,
    );
    final beforeCircumstances = List.of(attempt.circumstances);
    final beforeOthers = List.of(attempt.modifiers.others);
    // The circumstances hold Advantage, so the mode is advantage: two dice,
    // the higher kept; total 10 + 3 + 2 = 15.
    final resolve = ResolveD20Test(FixedDiceRoller(const [10, 8]));

    final result = resolve(command);

    // The command itself, compared field by field against a fresh equal
    // command, so any changed field fails.
    expect(
      command,
      AbilityCheckCommand(
        Ability.strength,
        target: const DifficultyClass(15),
        attempt: RollAttempt(
          modifiers: RollModifiers(
            ability: const Modifier(3),
            others: [const Modifier(2)],
          ),
          circumstances: [const Advantage()],
        ),
      ),
    );
    expect(command.attempt, same(attempt));
    expect(attempt.circumstances, beforeCircumstances);
    expect(attempt.modifiers.others, beforeOthers);
    expect(
      attempt.modifiers,
      RollModifiers(ability: const Modifier(3), others: [const Modifier(2)]),
    );
    expect(source, [const Advantage()]);
    expect(others, [const Modifier(2)]);
    // The call ran with this command and resolved it normally.
    expect(result, isA<ResolveD20TestRolledCheck>());
  });

  /// Requirement: doc/specs/resolve-d20-test-use-case.md FR-055 - ability on
  ///   a command is a label for telemetry and the result only; the modifier
  ///   summed is the one inside RollModifiers, and the caller keeps the two
  ///   consistent (d20-tests.md D-06).
  /// Path: unhappy (rule interaction)
  test('the total uses the modifier and the attribute uses the label', () {
    final recording = RecordingObservability();
    // A command labelled strength whose modifier slot holds what a dexterity
    // modifier would be; Modifier carries no ability tag, so the use case
    // cannot tell.
    final command = AbilityCheckCommand(
      Ability.strength,
      target: const DifficultyClass(15),
      attempt: RollAttempt(
        modifiers: RollModifiers(ability: const Modifier(4)),
      ),
    );
    final roller = FixedDiceRoller(const [10]);

    final ResolveD20TestRolledCheck(result: check) =
        ResolveD20Test(roller, observability: recording.observability)(command)
            as ResolveD20TestRolledCheck;

    expect(check.total, 14);
    final span = recording.tracer.spans.single;
    expect(span.attributes[D20TestSignals.abilityAttribute], 'strength');
    expect(
      span.attributes[D20TestSignals.kindAttribute],
      D20TestSignals.abilityCheckKindValue,
    );
  });

  /// Requirement: doc/specs/resolve-d20-test-use-case.md FR-058 - the
  ///   orchestration: the kind derives from the command variant, ChooseToFail
  ///   maps to chosenToFail and AutomaticFailure to automatic, a RollAttempt
  ///   calls resolveCheck or resolveAttackRoll, a forced attempt calls
  ///   forcedFailure, and the domain result is wrapped with the ability and
  ///   the target.
  /// Path: happy
  group('the kind and reason mapping follows the command', () {
    /// Requirement: doc/specs/resolve-d20-test-use-case.md FR-058 (a) and
    ///   (c) - each command variant resolves the matching kind, a check and
    ///   save through resolveCheck, an attack roll through
    ///   resolveAttackRoll.
    /// Path: happy
    test('each command variant resolves its kind', () {
      final ResolveD20TestRolledCheck(result: check) =
          _run(_caseRows[0]).result as ResolveD20TestRolledCheck;
      expect(check.kind, D20TestKind.abilityCheck);
      final ResolveD20TestRolledCheck(result: save) =
          _run(_caseRows[1]).result as ResolveD20TestRolledCheck;
      expect(save.kind, D20TestKind.savingThrow);
      expect(_run(_caseRows[2]).result, isA<ResolveD20TestRolledAttack>());
    });

    /// Requirement: doc/specs/resolve-d20-test-use-case.md FR-058 (b) and
    ///   (c) - ChooseToFail maps to chosenToFail and AutomaticFailure to
    ///   automatic, on a save and on a check, so a swapped reason fails.
    /// Path: unhappy (rule interaction)
    test('each forced attempt maps to its reason', () {
      final chosen = _run(_caseRows[15]).result;
      final ResolveD20TestForcedFailure(result: chosenResult) =
          chosen as ResolveD20TestForcedFailure;
      expect(chosenResult.reason, ForcedFailureReason.chosenToFail);
      expect(chosenResult.kind, D20TestKind.savingThrow);

      final automaticOnCheck = _run(_caseRows[16]).result;
      final ResolveD20TestForcedFailure(result: automaticCheckResult) =
          automaticOnCheck as ResolveD20TestForcedFailure;
      expect(automaticCheckResult.reason, ForcedFailureReason.automatic);
      expect(automaticCheckResult.kind, D20TestKind.abilityCheck);

      // AutomaticFailure on a save stays automatic: a swapped mapping to
      // chosenToFail would still be a valid forced failure and must fail
      // this assertion.
      final automaticOnSave = ResolveD20Test(FixedDiceRoller(const <int>[]))(
        const SavingThrowCommand(
          Ability.dexterity,
          target: DifficultyClass(10),
          attempt: AutomaticFailure(),
        ),
      );
      final ResolveD20TestForcedFailure(result: automaticSaveResult) =
          automaticOnSave as ResolveD20TestForcedFailure;
      expect(automaticSaveResult.reason, ForcedFailureReason.automatic);
      expect(automaticSaveResult.kind, D20TestKind.savingThrow);
    });
  });

  /// Requirement: doc/specs/resolve-d20-test-use-case.md FR-023, FR-024 and
  ///   FR-025 - the DiceRoller comes through the constructor typed as the
  ///   port, Observability may be omitted, call is synchronous, and equal
  ///   commands with the same roller values return equal results on every
  ///   invocation (doc/rules/architecture.md §4; doc/rules/testing.md §4).
  /// Path: happy
  group('constructor, synchronous call and determinism', () {
    /// Requirement: doc/specs/resolve-d20-test-use-case.md FR-023 and
    ///   FR-024 - omitting Observability works and the result comes back
    ///   directly, not as a Future (the static type is analyzer-enforced;
    ///   this is its runtime companion).
    /// Path: happy
    test('omitting Observability works and call returns directly', () {
      final resolve = ResolveD20Test(FixedDiceRoller(const [9]));

      final result = resolve(
        AbilityCheckCommand(
          Ability.strength,
          target: const DifficultyClass(10),
          attempt: RollAttempt(
            modifiers: RollModifiers(ability: const Modifier(2)),
          ),
        ),
      );

      expect(result, isA<ResolveD20TestResult>());
      expect(result, isA<ResolveD20TestRolledCheck>());
    });

    /// Requirement: doc/specs/resolve-d20-test-use-case.md FR-025 - two calls
    ///   with the same scripted roller return equal results, in any test
    ///   order.
    /// Path: happy
    test('the same scripted values give equal results on every call', () {
      final roller = FixedDiceRoller(const [11, 11, 20, 20, 20, 20]);
      final resolve = ResolveD20Test(roller);

      final first = resolve(_commandOf(_caseRows[0]));
      final second = resolve(_commandOf(_caseRows[0]));
      final third = resolve(_commandOf(_caseRows[11]));
      final fourth = resolve(_commandOf(_caseRows[11]));

      expect(first, second);
      expect(third, fourth);
      expect(roller.requests, hasLength(4));
    });
  });

  /// Requirement: doc/specs/resolve-d20-test-use-case.md FR-026, FR-027,
  ///   FR-051 and FR-037 - a DiceRollerException propagates unchanged with
  ///   exactly one request on record, a wrong expression raises
  ///   invalidResult from rollChecked, and an Error from a defective adapter
  ///   propagates too (doc/rules/architecture.md §4, §6).
  /// Path: unhappy (collaborator failure)
  group('roller failures', () {
    /// Requirement: doc/specs/resolve-d20-test-use-case.md FR-026 and
    ///   FR-051 - the same DiceRollerException instance propagates, no
    ///   partial result is returned, and after the throw no further request
    ///   is made.
    /// Path: unhappy (collaborator failure)
    test('an unavailable roller propagates its exception, once requested', () {
      final failure = DiceRollerException(
        expression: DiceExpression(1, Die.d20),
        reason: DiceRollerFailureReason.unavailable,
      );
      var calls = 0;
      final roller = CallbackDiceRoller((expression) {
        calls++;
        throw failure;
      });
      final resolve = ResolveD20Test(roller);

      expect(() => resolve(_commandOf(_caseRows[0])), throwsA(same(failure)));
      expect(calls, 1);
    });

    /// Requirement: doc/specs/resolve-d20-test-use-case.md FR-051 - a failing
    ///   call leaves exactly one request on record and does not retry.
    /// Path: unhappy (collaborator failure)
    test('a failing call leaves exactly one request on record', () {
      final failure = DiceRollerException(
        expression: DiceExpression(2, Die.d20),
        reason: DiceRollerFailureReason.unavailable,
      );
      var requests = 0;
      final roller = CallbackDiceRoller((expression) {
        requests++;
        throw failure;
      });
      final resolve = ResolveD20Test(roller);

      expect(() => resolve(_commandOf(_caseRows[7])), throwsA(same(failure)));
      expect(requests, 1);
    });

    /// Requirement: doc/specs/errors-and-results.md FR-051 (the row of
    ///   errors-and-results.md FR-053) - an Exception from the port that is
    ///   not an Srd5eException propagates unchanged, is recorded on the span
    ///   as it passes through the tracer, and gets no errors increment, no
    ///   error.type and no resolved increment.
    /// Path: unhappy (collaborator failure)
    test('a raw Exception from the port propagates uncounted', () {
      final failure = Exception('backend down');
      final recording = RecordingObservability();
      final resolve = ResolveD20Test(
        CallbackDiceRoller((expression) => throw failure),
        observability: recording.observability,
      );

      expect(() => resolve(_commandOf(_caseRows[0])), throwsA(same(failure)));

      final span = recording.tracer.spans.single;
      expect(span.status, SpanStatus.error);
      expect(span.errors, hasLength(1));
      expect(span.errors.single.$1, same(failure));
      expect(
        recording.meter.measurementsNamed(D20TestSignals.errorsMetric),
        isEmpty,
      );
      expect(
        recording.meter.measurementsNamed(D20TestSignals.resolvedMetric),
        isEmpty,
      );
    });

    /// Requirement: doc/specs/resolve-d20-test-use-case.md FR-027 - a roller
    ///   answering a different expression raises DiceRollerException with
    ///   reason invalidResult, one case per differing field (count, die,
    ///   modifier).
    /// Path: unhappy (collaborator returns invalid data)
    for (final (label, answered) in [
      (
        'a different count',
        RollResult(DiceExpression(2, Die.d20), [
          DieRoll(Die.d20, 10),
          DieRoll(Die.d20, 12),
        ]),
      ),
      (
        'a different die',
        RollResult(DiceExpression(1, Die.d6), [DieRoll(Die.d6, 4)]),
      ),
      (
        'a different modifier',
        RollResult(DiceExpression(1, Die.d20, modifier: 2), [
          DieRoll(Die.d20, 10),
        ]),
      ),
    ]) {
      /// Requirement: doc/specs/resolve-d20-test-use-case.md FR-027 - a roller
      ///   answering a different expression raises DiceRollerException with
      ///   reason invalidResult.
      /// Path: unhappy (collaborator returns invalid data)
      test('a roller answering $label raises invalidResult', () {
        final roller = CallbackDiceRoller((expression) => answered);
        final resolve = ResolveD20Test(roller);

        expect(
          () => resolve(_commandOf(_caseRows[0])),
          throwsA(
            isA<DiceRollerException>().having(
              (error) => error.reason,
              'reason',
              DiceRollerFailureReason.invalidResult,
            ),
          ),
        );
      });
    }

    /// Requirement: doc/specs/resolve-d20-test-use-case.md FR-037 - an Error
    ///   thrown by the roller propagates unchanged; the use case must not
    ///   count it in errors, increment resolved or log.
    /// Path: unhappy (state error)
    test('a StateError from a defective adapter propagates unchanged', () {
      final error = StateError('defective adapter');
      final roller = CallbackDiceRoller((expression) => throw error);
      final resolve = ResolveD20Test(roller);

      expect(() => resolve(_commandOf(_caseRows[0])), throwsA(same(error)));
    });
  });

  /// Requirement: doc/specs/resolve-d20-test-use-case.md FR-029, FR-030,
  ///   FR-041, FR-052 and FR-016 - one span per call, named by the signals
  ///   constant, with kind and ability at start and roll_mode, outcome and
  ///   the critical-hit flag once the result is known; exactly one resolved
  ///   increment with the span's attributes (doc/rules/observability.md §5,
  ///   §6).
  /// Path: happy
  group('the span and the resolved counter', () {
    /// Requirement: doc/specs/resolve-d20-test-use-case.md FR-029 and FR-041
    ///   - the span starts with kind and ability, gains roll_mode and
    ///   outcome, and no child span is opened.
    /// Path: happy
    test('a rolled check spans once with the lifecycle attributes', () {
      final recording = RecordingObservability();
      final fixed = FixedDiceRoller(const [10]);
      Map<String, Object>? startAttributes;
      final roller = CallbackDiceRoller((expression) {
        startAttributes = Map.of(recording.tracer.spans.single.attributes);
        return fixed.roll(expression);
      });

      ResolveD20Test(roller, observability: recording.observability)(
        _commandOf(_caseRows[0]),
      );

      expect(recording.tracer.spans, hasLength(1));
      final span = recording.tracer.spans.single;
      expect(span.name, D20TestSignals.resolveSpan);
      expect(startAttributes, {
        D20TestSignals.kindAttribute: D20TestSignals.abilityCheckKindValue,
        D20TestSignals.abilityAttribute: 'strength',
      });
      expect(span.attributes, {
        D20TestSignals.kindAttribute: D20TestSignals.abilityCheckKindValue,
        D20TestSignals.abilityAttribute: 'strength',
        D20TestSignals.rollModeAttribute: 'normal',
        AttributeKeys.outcome: 'success',
      });
    });

    /// Requirement: doc/specs/resolve-d20-test-use-case.md FR-029 and FR-052
    ///   - an attack roll's span carries roll_mode (from D20Roll.mode) and
    ///   critical_hit as a bool, beside kind, ability and outcome.
    /// Path: happy
    test('a rolled attack spans once with the lifecycle attributes', () {
      final recording = RecordingObservability();

      ResolveD20Test(
        FixedDiceRoller(_caseRows[2].rolls),
        observability: recording.observability,
      )(_commandOf(_caseRows[2]));

      expect(recording.tracer.spans, hasLength(1));
      expect(recording.tracer.spans.single.attributes, {
        D20TestSignals.kindAttribute: D20TestSignals.attackRollKindValue,
        D20TestSignals.abilityAttribute: 'strength',
        D20TestSignals.rollModeAttribute: 'normal',
        AttributeKeys.outcome: 'success',
        D20TestSignals.criticalHitAttribute: false,
      });
    });

    /// Requirement: doc/specs/resolve-d20-test-use-case.md FR-030 - each
    ///   successful call increments resolved exactly once with the span's
    ///   attributes, whatever the outcome.
    /// Path: happy
    test('resolved is incremented once with the span attributes', () {
      for (final row in _caseRows) {
        final recording = RecordingObservability();
        ResolveD20Test(
          FixedDiceRoller(row.rolls),
          observability: recording.observability,
        )(_commandOf(row));

        final counts = recording.meter.measurementsNamed(
          D20TestSignals.resolvedMetric,
        );
        expect(counts, hasLength(1), reason: row.label);
        expect(counts.single.value, 1, reason: row.label);
        expect(counts.single.unit, '{test}');
        expect(
          counts.single.attributes,
          recording.tracer.spans.single.attributes,
          reason: row.label,
        );
      }
    });

    /// Requirement: doc/specs/resolve-d20-test-use-case.md FR-052 and
    ///   FR-016 - critical_hit is present as a bool on the span and on
    ///   resolved for an attack roll that rolled (equal to isCriticalHit),
    ///   and absent for a check, a save and any forced failure; the former
    ///   basis attribute and the miss/hit/critical_hit outcome values no
    ///   longer exist.
    /// Path: unhappy (boundary: attribute presence)
    test('critical_hit is present only on rolled attack rows', () {
      for (final row in _caseRows) {
        final recording = RecordingObservability();
        final rolled = _run(row, observability: recording.observability);

        final span = recording.tracer.spans.single;
        final counts = recording.meter.measurementsNamed(
          D20TestSignals.resolvedMetric,
        );
        if (_variantOf(row) == _Variant.rolledAttack) {
          final ResolveD20TestRolledAttack(result: attack) =
              rolled.result as ResolveD20TestRolledAttack;
          expect(
            span.attributes,
            contains(D20TestSignals.criticalHitAttribute),
            reason: row.label,
          );
          expect(
            span.attributes[D20TestSignals.criticalHitAttribute],
            isA<bool>(),
            reason: row.label,
          );
          expect(
            span.attributes[D20TestSignals.criticalHitAttribute],
            attack.isCriticalHit,
            reason: row.label,
          );
          expect(
            counts.single.attributes[D20TestSignals.criticalHitAttribute],
            attack.isCriticalHit,
            reason: row.label,
          );
        } else {
          expect(
            span.attributes.containsKey(D20TestSignals.criticalHitAttribute),
            isFalse,
            reason: row.label,
          );
          expect(
            counts.single.attributes.containsKey(
              D20TestSignals.criticalHitAttribute,
            ),
            isFalse,
            reason: row.label,
          );
        }
        expect(
          span.attributes.containsKey('srd5e.d20_test.basis'),
          isFalse,
          reason: row.label,
        );
        expect(
          span.attributes[AttributeKeys.outcome],
          anyOf('success', 'failure'),
          reason: row.label,
        );
      }
    });

    /// Requirement: doc/specs/resolve-d20-test-use-case.md FR-029 and FR-060
    ///   - a chosen forced failure has no roll mode and no critical-hit flag,
    ///   its outcome is failure and it carries reason chosen_to_fail.
    /// Path: happy
    test('a forced failure carries outcome failure and no roll mode', () {
      final recording = RecordingObservability();
      final roller = FixedDiceRoller(const <int>[]);
      ResolveD20Test(roller, observability: recording.observability)(
        _commandOf(_caseRows[15]),
      );

      expect(roller.requests, isEmpty);
      final span = recording.tracer.spans.single;
      expect(span.attributes, {
        D20TestSignals.kindAttribute: D20TestSignals.savingThrowKindValue,
        D20TestSignals.abilityAttribute: 'dexterity',
        D20TestSignals.forcedFailureReasonAttribute:
            D20TestSignals.forcedFailureChosenToFailValue,
        AttributeKeys.outcome: 'failure',
      });
    });

    /// Requirement: doc/specs/resolve-d20-test-use-case.md FR-060 - an
    ///   automatic failure carries reason automatic on the span and on
    ///   resolved; a rolled row never carries the key.
    /// Path: happy
    test('an automatic failure carries reason automatic', () {
      final recording = RecordingObservability();
      final rolled = _run(
        _caseRows[16],
        observability: recording.observability,
      );
      final forced = rolled.result as ResolveD20TestForcedFailure;
      final span = recording.tracer.spans.single;

      expect(
        span.attributes[D20TestSignals.forcedFailureReasonAttribute],
        D20TestSignals.forcedFailureAutomaticValue,
      );
      expect(
        span.attributes.containsKey(D20TestSignals.rollModeAttribute),
        isFalse,
      );
      final counts = recording.meter.measurementsNamed(
        D20TestSignals.resolvedMetric,
      );
      expect(
        counts.single.attributes[D20TestSignals.forcedFailureReasonAttribute],
        D20TestSignals.forcedFailureAutomaticValue,
      );
      expect(forced.result.reason, ForcedFailureReason.automatic);
    });
  });

  /// Requirement: doc/specs/resolve-d20-test-use-case.md FR-031 and FR-046 -
  ///   the duration is recorded exactly once per call, in seconds with the
  ///   kind attribute, including a call whose body throws, and Meter.time
  ///   runs inside the Tracer.trace body (doc/rules/observability.md §4, §5).
  /// Path: happy
  group('the duration histogram', () {
    /// Requirement: doc/specs/resolve-d20-test-use-case.md FR-031 - the
    ///   recording meter's timedDuration of 250 ms proves the recorded 0.25
    ///   comes from the meter.
    /// Path: happy
    test('a 250 ms timed duration is recorded once as 0.25 seconds', () {
      final recording = RecordingObservability(timedDuration: _timed250);

      ResolveD20Test(
        FixedDiceRoller(const [10]),
        observability: recording.observability,
      )(_commandOf(_caseRows[0]));

      final records = recording.meter.measurementsNamed(
        D20TestSignals.durationMetric,
      );
      expect(records, hasLength(1));
      expect(records.single.value, 0.25);
      expect(records.single.unit, 's');
      expect(records.single.attributes, {
        D20TestSignals.kindAttribute: D20TestSignals.abilityCheckKindValue,
      });
    });

    /// Requirement: doc/specs/resolve-d20-test-use-case.md FR-031 - a call
    ///   whose body throws still records its duration, and the same
    ///   exception is rethrown.
    /// Path: unhappy (collaborator failure)
    test('a throwing call still records its duration once', () {
      final recording = RecordingObservability(timedDuration: _timed250);
      final failure = DiceRollerException(
        expression: DiceExpression(1, Die.d20),
        reason: DiceRollerFailureReason.unavailable,
      );

      expect(
        () => ResolveD20Test(
          CallbackDiceRoller((expression) => throw failure),
          observability: recording.observability,
        )(_commandOf(_caseRows[0])),
        throwsA(same(failure)),
      );

      final records = recording.meter.measurementsNamed(
        D20TestSignals.durationMetric,
      );
      expect(records, hasLength(1));
      expect(records.single.value, 0.25);
    });

    /// Requirement: doc/specs/resolve-d20-test-use-case.md FR-046 -
    ///   Meter.time runs inside the Tracer.trace body: the timed work runs
    ///   while the span is open, and a failure reaches the span after the
    ///   duration is recorded.
    /// Path: happy
    test('the span encloses the timed work', () {
      final recording = RecordingObservability(timedDuration: _timed250);
      var spanOpenDuringWork = false;
      final roller = CallbackDiceRoller((expression) {
        spanOpenDuringWork = !recording.tracer.spans.single.ended;
        throw DiceRollerException(
          expression: DiceExpression(1, Die.d20),
          reason: DiceRollerFailureReason.unavailable,
        );
      });

      expect(
        () => ResolveD20Test(roller, observability: recording.observability)(
          _commandOf(_caseRows[0]),
        ),
        throwsA(isA<DiceRollerException>()),
      );

      expect(spanOpenDuringWork, isTrue);
      expect(
        recording.meter.measurementsNamed(D20TestSignals.durationMetric),
        hasLength(1),
      );
      expect(recording.tracer.spans.single.status, SpanStatus.error);
    });
  });

  /// Requirement: doc/specs/resolve-d20-test-use-case.md FR-032 - each
  ///   successful call that rolled records the number of modifiers (ability,
  ///   Proficiency Bonus when present, each other modifier; minimum 1) into
  ///   the modifiers histogram with the kind attribute; a forced failure
  ///   records nothing there.
  /// Path: unhappy (empty and minimal)
  group('the modifiers histogram', () {
    /// Requirement: per case
    /// Path: per case
    for (final (label, proficiency, others, expected) in const [
      ('an ability modifier only', null, <int>[], 1),
      ('a Proficiency Bonus', 2, <int>[], 2),
      ('ability, Proficiency Bonus and two others', 2, [1, -2], 4),
    ]) {
      test('$label records $expected', () {
        final recording = RecordingObservability();
        final command = AbilityCheckCommand(
          Ability.strength,
          target: const DifficultyClass(15),
          attempt: RollAttempt(
            modifiers: RollModifiers(
              ability: const Modifier(3),
              proficiencyBonus: proficiency == null
                  ? null
                  : Modifier(proficiency),
              others: [for (final value in others) Modifier(value)],
            ),
          ),
        );

        ResolveD20Test(
          FixedDiceRoller(const [10]),
          observability: recording.observability,
        )(command);

        final records = recording.meter.measurementsNamed(
          D20TestSignals.modifiersMetric,
        );
        expect(records, hasLength(1));
        expect(records.single.value, expected);
        expect(records.single.unit, '{modifier}');
        expect(records.single.attributes, {
          D20TestSignals.kindAttribute: D20TestSignals.abilityCheckKindValue,
        });
      });
    }

    /// Requirement: doc/specs/resolve-d20-test-use-case.md FR-032 - an
    ///   attack roll records the number of modifiers in its RollModifiers
    ///   with the attack_roll kind.
    /// Path: happy
    test('an attack roll records its modifier count', () {
      final recording = RecordingObservability();

      ResolveD20Test(
        FixedDiceRoller(_caseRows[2].rolls),
        observability: recording.observability,
      )(_commandOf(_caseRows[2]));

      final records = recording.meter.measurementsNamed(
        D20TestSignals.modifiersMetric,
      );
      expect(records, hasLength(1));
      expect(records.single.value, 1);
      expect(records.single.unit, '{modifier}');
      expect(records.single.attributes, {
        D20TestSignals.kindAttribute: D20TestSignals.attackRollKindValue,
      });
    });

    /// Requirement: doc/specs/resolve-d20-test-use-case.md FR-032 - a forced
    ///   failure records nothing in the modifiers histogram.
    /// Path: unhappy (empty and minimal)
    test('a forced failure records nothing', () {
      final recording = RecordingObservability();

      ResolveD20Test(
        FixedDiceRoller(const <int>[]),
        observability: recording.observability,
      )(_commandOf(_caseRows[15]));

      expect(
        recording.meter.measurementsNamed(D20TestSignals.modifiersMetric),
        isEmpty,
      );
    });
  });

  /// Requirement: doc/specs/resolve-d20-test-use-case.md FR-059 - every
  ///   rolled case-table row records the d20 face it used exactly once, with
  ///   the kind attribute and unit {face}, and a forced failure records
  ///   nothing there.
  /// Path: happy
  group('the natural histogram', () {
    /// Requirement: doc/specs/resolve-d20-test-use-case.md FR-059 - each
    ///   rolled row records the face the domain result carries, so a
    ///   mis-recorded face fails on that row.
    /// Path: happy
    test('each rolled row records the d20 face it used', () {
      for (final row in _caseRows) {
        if (row.attempt != _Attempt.roll) {
          continue;
        }
        final recording = RecordingObservability();
        final rolled = _run(row, observability: recording.observability);
        final natural = switch (rolled.result) {
          ResolveD20TestRolledCheck(result: final check) => check.roll.natural,
          ResolveD20TestRolledAttack(result: final attack) =>
            attack.roll.natural,
          ResolveD20TestForcedFailure() => null,
        };
        final records = recording.meter.measurementsNamed(
          D20TestSignals.naturalMetric,
        );
        expect(records, hasLength(1), reason: row.label);
        expect(records.single.value, natural, reason: row.label);
        expect(records.single.unit, '{face}', reason: row.label);
        expect(records.single.attributes, {
          D20TestSignals.kindAttribute: switch (row.kind) {
            _Kind.check => D20TestSignals.abilityCheckKindValue,
            _Kind.save => D20TestSignals.savingThrowKindValue,
            _Kind.attack => D20TestSignals.attackRollKindValue,
          },
        }, reason: row.label);
      }
    });

    /// Requirement: doc/specs/resolve-d20-test-use-case.md FR-059 - a forced
    ///   failure records nothing in the natural histogram.
    /// Path: unhappy (empty and minimal)
    test('a forced failure records nothing', () {
      final recording = RecordingObservability();

      ResolveD20Test(
        FixedDiceRoller(const <int>[]),
        observability: recording.observability,
      )(_commandOf(_caseRows[15]));

      expect(
        recording.meter.measurementsNamed(D20TestSignals.naturalMetric),
        isEmpty,
      );
    });
  });

  /// Requirement: doc/specs/resolve-d20-test-use-case.md FR-035, FR-036 and
  ///   FR-037 - a failed check or a miss is a normal outcome; a thrown
  ///   DiceRollerException is recorded exactly once with error.type; an
  ///   Error is spanned but not counted (doc/rules/observability.md §6, §7).
  /// Path: unhappy (rule interaction)
  group('failure recording', () {
    /// Requirement: doc/specs/resolve-d20-test-use-case.md FR-035 - a failed
    ///   check, a missed attack and a forced failure set no span error status
    ///   and do not touch the errors counter.
    /// Path: unhappy (rule interaction)
    test('a failed check, a miss and a forced failure are not errors', () {
      for (final row in _caseRows) {
        if (row.outcome != D20TestOutcome.failure) {
          continue;
        }
        final recording = RecordingObservability();
        ResolveD20Test(
          FixedDiceRoller(row.rolls),
          observability: recording.observability,
        )(_commandOf(row));

        expect(
          recording.tracer.spans.single.status,
          isNot(SpanStatus.error),
          reason: row.label,
        );
        expect(
          recording.tracer.spans.single.errors,
          isEmpty,
          reason: row.label,
        );
        expect(
          recording.meter.measurementsNamed(D20TestSignals.errorsMetric),
          isEmpty,
          reason: row.label,
        );
      }
    });

    /// Requirement: doc/specs/resolve-d20-test-use-case.md FR-036 and FR-061
    ///   - an unavailable roller records the failure exactly once: span error
    ///   status with the exception and roller_failure unavailable, one errors
    ///   increment with kind, error.type and roller_failure, and resolved
    ///   untouched.
    /// Path: unhappy (collaborator failure)
    test('an unavailable roller is recorded exactly once', () {
      final failure = DiceRollerException(
        expression: DiceExpression(1, Die.d20),
        reason: DiceRollerFailureReason.unavailable,
      );
      final recording = RecordingObservability();

      expect(
        () => ResolveD20Test(
          CallbackDiceRoller((expression) => throw failure),
          observability: recording.observability,
        )(_commandOf(_caseRows[0])),
        throwsA(same(failure)),
      );

      final span = recording.tracer.spans.single;
      expect(span.status, SpanStatus.error);
      expect(span.errors, hasLength(1));
      expect(span.errors.single.$1, same(failure));
      expect(
        span.attributes[D20TestSignals.rollerFailureAttribute],
        D20TestSignals.rollerFailureUnavailableValue,
      );

      final errors = recording.meter.measurementsNamed(
        D20TestSignals.errorsMetric,
      );
      expect(errors, hasLength(1));
      expect(errors.single.value, 1);
      expect(errors.single.unit, '{error}');
      expect(errors.single.attributes, {
        D20TestSignals.kindAttribute: D20TestSignals.abilityCheckKindValue,
        AttributeKeys.errorType: 'dice_roller_exception',
        D20TestSignals.rollerFailureAttribute:
            D20TestSignals.rollerFailureUnavailableValue,
      });
      expect(
        recording.meter.measurementsNamed(D20TestSignals.resolvedMetric),
        isEmpty,
      );
    });

    /// Requirement: doc/specs/resolve-d20-test-use-case.md FR-036 and FR-061
    ///   - an invalid-result roller is recorded the same way, with
    ///   roller_failure invalid_result.
    /// Path: unhappy (collaborator returns invalid data)
    test('an invalid result is recorded exactly once', () {
      final recording = RecordingObservability();
      final answered = RollResult(DiceExpression(1, Die.d20, modifier: 2), [
        DieRoll(Die.d20, 10),
      ]);

      expect(
        () => ResolveD20Test(
          CallbackDiceRoller((expression) => answered),
          observability: recording.observability,
        )(_commandOf(_caseRows[0])),
        throwsA(isA<DiceRollerException>()),
      );

      final span = recording.tracer.spans.single;
      expect(span.status, SpanStatus.error);
      expect(span.errors, hasLength(1));
      expect(
        span.attributes[D20TestSignals.rollerFailureAttribute],
        D20TestSignals.rollerFailureInvalidResultValue,
      );
      final errors = recording.meter.measurementsNamed(
        D20TestSignals.errorsMetric,
      );
      expect(errors.single.attributes, {
        D20TestSignals.kindAttribute: D20TestSignals.abilityCheckKindValue,
        AttributeKeys.errorType: 'dice_roller_exception',
        D20TestSignals.rollerFailureAttribute:
            D20TestSignals.rollerFailureInvalidResultValue,
      });
      expect(
        recording.meter.measurementsNamed(D20TestSignals.resolvedMetric),
        isEmpty,
      );
    });

    /// Requirement: doc/specs/resolve-d20-test-use-case.md FR-037 - an Error
    ///   from the roller is recorded on the span as it propagates, and is
    ///   not counted in errors or resolved.
    /// Path: unhappy (state error)
    test('a StateError reaches the span and is not counted', () {
      final recording = RecordingObservability();
      final error = StateError('defective adapter');

      expect(
        () => ResolveD20Test(
          CallbackDiceRoller((expression) => throw error),
          observability: recording.observability,
        )(_commandOf(_caseRows[0])),
        throwsA(same(error)),
      );

      final span = recording.tracer.spans.single;
      expect(span.status, SpanStatus.error);
      expect(span.errors.single.$1, same(error));
      expect(
        recording.meter.measurementsNamed(D20TestSignals.errorsMetric),
        isEmpty,
      );
      expect(
        recording.meter.measurementsNamed(D20TestSignals.resolvedMetric),
        isEmpty,
      );
    });
  });

  /// Requirement: doc/specs/resolve-d20-test-use-case.md FR-047 and FR-034 -
  ///   the use case emits no log event at any level, on success or failure
  ///   (FR-034 is the withdrawn row that dropped the FINE log and the lazy
  ///   attribute closure; this test pins its surviving rule).
  /// Path: happy
  test('nothing is logged at any level', () {
    final recording = RecordingObservability();

    ResolveD20Test(
      FixedDiceRoller(const [10]),
      observability: recording.observability,
    )(_commandOf(_caseRows[0]));
    ResolveD20Test(
      FixedDiceRoller(const <int>[]),
      observability: recording.observability,
    )(_commandOf(_caseRows[16]));
    expect(
      () => ResolveD20Test(
        CallbackDiceRoller(
          (expression) => throw DiceRollerException(
            expression: DiceExpression(1, Die.d20),
            reason: DiceRollerFailureReason.unavailable,
          ),
        ),
        observability: recording.observability,
      )(_commandOf(_caseRows[0])),
      throwsA(isA<DiceRollerException>()),
    );

    expect(recording.logger.records, isEmpty);
  });

  /// Requirement: doc/specs/resolve-d20-test-use-case.md FR-038 - every
  ///   attribute value comes from its closed set, all six abilities map to
  ///   their lower-case names, and critical_hit is a bool, never a string
  ///   (doc/rules/observability.md §5).
  /// Path: unhappy (boundary: closed value sets)
  group('the attribute closed sets', () {
    /// Requirement: doc/specs/resolve-d20-test-use-case.md FR-038 - every
    ///   attribute of every case-table row, span and measurement alike, is in
    ///   its closed set.
    /// Path: unhappy (boundary: closed value sets)
    test('every row carries only closed-set attributes', () {
      for (final row in _caseRows) {
        final recording = RecordingObservability();
        ResolveD20Test(
          FixedDiceRoller(row.rolls),
          observability: recording.observability,
        )(_commandOf(row));

        _expectClosedSets(recording.tracer.spans.single.attributes);
        for (final measurement in recording.meter.measurements) {
          _expectClosedSets(measurement.attributes);
        }
      }
    });

    /// Requirement: doc/specs/resolve-d20-test-use-case.md FR-038 -
    ///   attributes of a thrown port failure are in their closed sets too:
    ///   the span and the errors measurement of an unavailable and of an
    ///   invalid-result roller go through the same sweep, so the `error.type`
    ///   value `dice_roller_exception` is validated here as well.
    /// Path: unhappy (boundary: closed value sets)
    test('a thrown port failure carries only closed-set attributes', () {
      for (final roller in [
        CallbackDiceRoller(
          (expression) => throw DiceRollerException(
            expression: DiceExpression(1, Die.d20),
            reason: DiceRollerFailureReason.unavailable,
          ),
        ),
        CallbackDiceRoller(
          (expression) =>
              RollResult(DiceExpression(1, Die.d6), [DieRoll(Die.d6, 4)]),
        ),
      ]) {
        final recording = RecordingObservability();
        expect(
          () => ResolveD20Test(roller, observability: recording.observability)(
            _commandOf(_caseRows[0]),
          ),
          throwsA(isA<DiceRollerException>()),
        );

        _expectClosedSets(recording.tracer.spans.single.attributes);
        for (final measurement in recording.meter.measurements) {
          _expectClosedSets(measurement.attributes);
        }
      }
    });

    /// Requirement: doc/specs/resolve-d20-test-use-case.md FR-038 - the six
    ///   abilities map to their lower-case enum names.
    /// Path: unhappy (boundary: closed value sets)
    test('all six abilities appear as their lower-case names', () {
      const names = {
        Ability.strength: 'strength',
        Ability.dexterity: 'dexterity',
        Ability.constitution: 'constitution',
        Ability.intelligence: 'intelligence',
        Ability.wisdom: 'wisdom',
        Ability.charisma: 'charisma',
      };

      for (final MapEntry(key: ability, :value) in names.entries) {
        final recording = RecordingObservability();
        final command = AbilityCheckCommand(
          ability,
          target: const DifficultyClass(10),
          attempt: RollAttempt(
            modifiers: RollModifiers(ability: const Modifier(0)),
          ),
        );
        ResolveD20Test(
          FixedDiceRoller(const [10]),
          observability: recording.observability,
        )(command);

        expect(
          recording.tracer.spans.single.attributes[D20TestSignals
              .abilityAttribute],
          value,
        );
      }
    });
  });

  /// Requirement: doc/specs/resolve-d20-test-use-case.md FR-039 - with no
  ///   Observability and with a recording one, call returns equal results,
  ///   makes the same request and throws the same exception type for the
  ///   same failing roller (doc/rules/observability.md §9).
  /// Path: happy
  group('no-op versus recording identity', () {
    /// Requirement: doc/specs/resolve-d20-test-use-case.md FR-039 - the whole
    ///   case table behaves identically under both.
    /// Path: happy
    test('the case table is identical under both', () {
      for (final row in _caseRows) {
        final silent = _run(row);
        final recording = RecordingObservability();
        final rolled = _run(row, observability: recording.observability);

        expect(rolled.result, silent.result, reason: row.label);
        expect(rolled.requests, silent.requests, reason: row.label);
      }
    });

    /// Requirement: doc/specs/resolve-d20-test-use-case.md FR-039 - the same
    ///   failing roller throws the same exception type under both.
    /// Path: unhappy (collaborator failure)
    test('a failing roller throws the same exception type under both', () {
      final failure = DiceRollerException(
        expression: DiceExpression(1, Die.d20),
        reason: DiceRollerFailureReason.unavailable,
      );
      final thrown = <Type>[];

      for (var run = 0; run < 2; run++) {
        final recording = RecordingObservability();
        final roller = CallbackDiceRoller((expression) => throw failure);
        try {
          ResolveD20Test(
            roller,
            observability: run == 0
                ? Observability.none
                : recording.observability,
          )(_commandOf(_caseRows[0]));
          fail('the failing roller must throw');
        } on DiceRollerException {
          thrown.add(DiceRollerException);
        }
      }

      expect(thrown, [DiceRollerException, DiceRollerException]);
    });
  });

  /// Requirement: doc/specs/resolve-d20-test-use-case.md FR-040 - the metric
  ///   names, span name and attribute keys are defined once as constants in
  ///   D20TestSignals, pinned here by their literal values
  ///   (doc/rules/observability.md §5, §9).
  /// Path: happy
  test('the signal constants are pinned', () {
    expect(D20TestSignals.resolveSpan, 'srd5e.d20_test.resolve');
    expect(D20TestSignals.resolvedMetric, 'srd5e.d20_test.resolved');
    expect(D20TestSignals.durationMetric, 'srd5e.d20_test.duration');
    expect(D20TestSignals.modifiersMetric, 'srd5e.d20_test.modifiers');
    expect(D20TestSignals.errorsMetric, 'srd5e.d20_test.errors');
    expect(D20TestSignals.kindAttribute, 'srd5e.d20_test.kind');
    expect(D20TestSignals.abilityAttribute, 'srd5e.ability');
    expect(D20TestSignals.rollModeAttribute, 'srd5e.d20_test.roll_mode');
    expect(D20TestSignals.criticalHitAttribute, 'srd5e.d20_test.critical_hit');
    expect(D20TestSignals.abilityCheckKindValue, 'ability_check');
    expect(D20TestSignals.savingThrowKindValue, 'saving_throw');
    expect(D20TestSignals.attackRollKindValue, 'attack_roll');
    expect(D20TestSignals.naturalMetric, 'srd5e.d20_test.natural');
    expect(
      D20TestSignals.rollerFailureAttribute,
      'srd5e.d20_test.roller_failure',
    );
    expect(D20TestSignals.rollerFailureUnavailableValue, 'unavailable');
    expect(D20TestSignals.rollerFailureInvalidResultValue, 'invalid_result');
    expect(
      D20TestSignals.forcedFailureReasonAttribute,
      'srd5e.d20_test.forced_failure_reason',
    );
    expect(D20TestSignals.forcedFailureChosenToFailValue, 'chosen_to_fail');
    expect(D20TestSignals.forcedFailureAutomaticValue, 'automatic');
    expect(AttributeKeys.outcome, 'srd5e.outcome');
    expect(AttributeKeys.errorType, 'error.type');
  });
}

/// The duration the recording meter reports, so the recorded 0.25 s is
/// deterministic (FR-031).
const Duration _timed250 = Duration(milliseconds: 250);
