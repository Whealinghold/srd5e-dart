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
import 'package:srd5e/src/shared_kernel/modifier.dart';
import 'package:srd5e/src/shared_kernel/roll_mode.dart';
import 'package:test/test.dart';

/// Builds a CheckResult from parts, with sensible defaults, for the value
/// semantics rows: every field overridable, so a variant differs in exactly
/// one field.
CheckResult _result({
  D20TestKind kind = D20TestKind.abilityCheck,
  int die = 10,
  int ability = 3,
  int? proficiency = 2,
  List<int> others = const [1, -2],
  int total = 15,
  int dc = 15,
  D20TestOutcome outcome = D20TestOutcome.success,
}) => CheckResult(
  kind: kind,
  roll: D20Roll(mode: RollMode.normal, dice: [die]),
  modifiers: RollModifiers(
    ability: Modifier(ability),
    proficiencyBonus: proficiency == null ? null : Modifier(proficiency),
    others: [for (final value in others) Modifier(value)],
  ),
  total: total,
  target: DifficultyClass(dc),
  outcome: outcome,
);

/// Builds a ForcedFailureResult from parts, with sensible defaults.
ForcedFailureResult _forced({
  D20TestKind kind = D20TestKind.savingThrow,
  ForcedFailureReason reason = ForcedFailureReason.automatic,
}) => ForcedFailureResult(kind: kind, reason: reason);

void main() {
  /// Requirement: doc/specs/d20-tests.md FR-041 - a rolled CheckResult
  ///   carries its kind, D20Roll, RollModifiers, total, DifficultyClass
  ///   target and D20TestOutcome, and no Ability and no separate roll-mode
  ///   field: the mode is D20Roll.mode (doc/rules/architecture.md §6, §4).
  /// Path: happy
  test('a CheckResult carries its kind, roll, modifiers, total, target and '
      'outcome', () {
    final roll = D20Roll(mode: RollMode.normal, dice: const [10]);
    final modifiers = RollModifiers(
      ability: const Modifier(3),
      proficiencyBonus: const Modifier(2),
    );
    const target = DifficultyClass(15);

    final result = CheckResult.resolve(
      D20TestKind.savingThrow,
      roll,
      modifiers,
      target,
    );

    expect(result.kind, D20TestKind.savingThrow);
    expect(result.roll, roll);
    expect(result.roll.mode, RollMode.normal);
    expect(result.modifiers, modifiers);
    expect(result.total, 15);
    expect(result.target, target);
    expect(result.outcome, D20TestOutcome.success);
  });

  /// Requirement: doc/specs/d20-tests.md FR-041 and FR-034 - an
  ///   AttackRollResult carries its roll, modifiers, total, ArmorClass
  ///   target, outcome, isCriticalHit and criticalRange, and exposes hit as
  ///   outcome == success (doc/rules/architecture.md §6; SRD 5.2.1, "Attack
  ///   Rolls", p. 7).
  /// Path: happy
  test(
    'an AttackRollResult carries its fields and hit follows the outcome',
    () {
      final hit = AttackRollResult.resolve(
        D20Roll(mode: RollMode.normal, dice: const [15]),
        RollModifiers(
          ability: const Modifier(3),
          proficiencyBonus: const Modifier(2),
        ),
        const ArmorClass(15),
      );
      final miss = AttackRollResult.resolve(
        D20Roll(mode: RollMode.normal, dice: const [10]),
        RollModifiers(ability: const Modifier(0)),
        const ArmorClass(15),
      );

      expect(hit.roll, D20Roll(mode: RollMode.normal, dice: const [15]));
      expect(
        hit.modifiers,
        RollModifiers(
          ability: const Modifier(3),
          proficiencyBonus: const Modifier(2),
        ),
      );
      expect(hit.total, 20);
      expect(hit.target, const ArmorClass(15));
      expect(hit.outcome, D20TestOutcome.success);
      expect(hit.isCriticalHit, isFalse);
      expect(hit.criticalRange, 20);
      expect(hit.hit, isTrue);

      expect(miss.outcome, D20TestOutcome.failure);
      expect(miss.hit, isFalse);
    },
  );

  /// Requirement: doc/specs/d20-tests.md FR-041 and FR-035 - a
  ///   ForcedFailureResult carries its kind and ForcedFailureReason and no
  ///   roll (doc/rules/architecture.md §6; SRD 5.2.1, "Saving Throws", p. 7).
  /// Path: happy
  test('a ForcedFailureResult carries its kind and reason and no roll', () {
    final result = ForcedFailureResult.of(
      D20TestKind.savingThrow,
      ForcedFailureReason.chosenToFail,
    );

    expect(result.kind, D20TestKind.savingThrow);
    expect(result.reason, ForcedFailureReason.chosenToFail);
    // No roll: the type has no roll member to call, whatever the access.
    expect(() => (result as dynamic).roll, throwsNoSuchMethodError);
  });

  /// Requirement: doc/specs/d20-tests.md FR-031 and FR-041 - a CheckResult
  ///   has no critical-hit field: the natural 20 and natural 1 rules hold
  ///   for attack rolls only (SRD 5.2.1, "Rolling 20 or 1", p. 7).
  /// Path: unhappy (rule interaction)
  test('a CheckResult has no critical-hit field', () {
    final result = _result();

    expect(() => (result as dynamic).isCriticalHit, throwsNoSuchMethodError);
  });

  /// Requirement: doc/specs/d20-tests.md FR-041 - collections reachable from
  ///   a result are unmodifiable (doc/rules/architecture.md §6, §4).
  /// Path: unhappy (immutability)
  test('collections reachable from a CheckResult are unmodifiable', () {
    final result = _result();

    expect(() => result.roll.dice.add(11), throwsUnsupportedError);
    expect(
      () => result.modifiers.others.add(const Modifier(2)),
      throwsUnsupportedError,
    );
  });

  /// Requirement: doc/specs/d20-tests.md FR-041 and FR-034 - collections
  ///   reachable from an AttackRollResult are unmodifiable
  ///   (doc/rules/architecture.md §6, §4).
  /// Path: unhappy (immutability)
  test('collections reachable from an AttackRollResult are unmodifiable', () {
    final result = AttackRollResult.resolve(
      D20Roll(mode: RollMode.normal, dice: const [10]),
      RollModifiers(ability: const Modifier(3), others: [const Modifier(1)]),
      const ArmorClass(15),
    );

    expect(() => result.roll.dice[0] = 11, throwsUnsupportedError);
    expect(
      () => result.modifiers.others.add(const Modifier(2)),
      throwsUnsupportedError,
    );
  });

  /// Requirement: doc/specs/d20-tests.md FR-050 - a CheckResult is equal,
  ///   with an equal hash code, when every field is equal
  ///   (doc/rules/architecture.md §3).
  /// Path: happy
  test('equal CheckResults are equal with equal hash codes', () {
    final a = _result();
    final b = _result();

    expect(a, b);
    expect(a.hashCode, b.hashCode);
  });

  /// Requirement: doc/specs/d20-tests.md FR-050 - a CheckResult is unequal
  ///   when any single field differs, including collection contents and
  ///   order (doc/rules/architecture.md §3).
  /// Path: unhappy (any differing field)
  test('CheckResults differing in one field are unequal', () {
    final base = _result();

    expect(base, isNot(_result(kind: D20TestKind.savingThrow)));
    expect(base, isNot(_result(die: 11)));
    expect(base, isNot(_result(ability: 4)));
    expect(base, isNot(_result(proficiency: null)));
    expect(base, isNot(_result(others: const [1, -1])));
    expect(base, isNot(_result(others: const [-2, 1])));
    expect(base, isNot(_result(others: const [1])));
    expect(base, isNot(_result(total: 16)));
    expect(base, isNot(_result(dc: 16)));
    expect(base, isNot(_result(outcome: D20TestOutcome.failure)));
  });

  /// Requirement: doc/specs/d20-tests.md FR-050 - a ForcedFailureResult is
  ///   equal, with an equal hash code, when every field is equal
  ///   (doc/rules/architecture.md §3).
  /// Path: happy
  test('equal ForcedFailureResults are equal with equal hash codes', () {
    final a = _forced();
    final b = _forced();

    expect(a, b);
    expect(a.hashCode, b.hashCode);
  });

  /// Requirement: doc/specs/d20-tests.md FR-050 - a ForcedFailureResult is
  ///   unequal when any single field differs (doc/rules/architecture.md §3).
  /// Path: unhappy (any differing field)
  test('ForcedFailureResults differing in one field are unequal', () {
    final base = _forced();

    expect(base, isNot(_forced(kind: D20TestKind.abilityCheck)));
    expect(base, isNot(_forced(reason: ForcedFailureReason.chosenToFail)));
  });
}
