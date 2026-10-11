import 'package:srd5e/src/d20_test/domain/armor_class.dart';
import 'package:srd5e/src/d20_test/domain/attack_roll_result.dart';
import 'package:srd5e/src/d20_test/domain/check_result.dart';
import 'package:srd5e/src/d20_test/domain/d20_roll.dart';
import 'package:srd5e/src/d20_test/domain/d20_test_kind.dart';
import 'package:srd5e/src/d20_test/domain/d20_test_outcome.dart';
import 'package:srd5e/src/d20_test/domain/difficulty_class.dart';
import 'package:srd5e/src/d20_test/domain/roll_modifiers.dart';
import 'package:srd5e/src/shared_kernel/modifier.dart';
import 'package:srd5e/src/shared_kernel/roll_mode.dart';
import 'package:test/test.dart';

/// Where a re-resolution case starts: the inputs of the original rolled test.
sealed class _Start {
  const _Start();
}

/// A check or save, resolved through `CheckResult.resolve`.
final class _CheckStart extends _Start {
  const _CheckStart(this.kind, this.mode, this.dice, this.ability, this.dc);

  final D20TestKind kind;
  final RollMode mode;
  final List<int> dice;
  final int ability;
  final int dc;

  D20Roll roll() => D20Roll(mode: mode, dice: dice);
  RollModifiers modifiers() => RollModifiers(ability: Modifier(ability));
  DifficultyClass target() => DifficultyClass(dc);

  /// The original result, resolved from these inputs.
  CheckResult resolve() =>
      CheckResult.resolve(kind, roll(), modifiers(), target());

  /// The original result and the result of re-resolving the roll with the die
  /// at [index] replaced by [value], same modifiers and target.
  (CheckResult, CheckResult) resolveReplaced(int index, int value) => (
    resolve(),
    CheckResult.resolve(
      kind,
      roll().replaceDie(index, value),
      modifiers(),
      target(),
    ),
  );

  /// The original result and its `adjustedBy(delta)` result.
  (CheckResult, CheckResult) adjusted(int delta) {
    final original = resolve();
    return (original, original.adjustedBy(delta));
  }
}

/// An attack roll, resolved through `AttackRollResult.resolve`.
final class _AttackStart extends _Start {
  const _AttackStart(this.mode, this.dice, this.ability, this.ac);

  final RollMode mode;
  final List<int> dice;
  final int ability;
  final int ac;

  D20Roll roll() => D20Roll(mode: mode, dice: dice);
  RollModifiers modifiers() => RollModifiers(ability: Modifier(ability));
  ArmorClass target() => ArmorClass(ac);

  /// The original result, resolved from these inputs.
  AttackRollResult resolve() =>
      AttackRollResult.resolve(roll(), modifiers(), target());

  /// The original result and the result of re-resolving the roll with the die
  /// at [index] replaced by [value], same modifiers and target.
  (AttackRollResult, AttackRollResult) resolveReplaced(int index, int value) =>
      (
        resolve(),
        AttackRollResult.resolve(
          roll().replaceDie(index, value),
          modifiers(),
          target(),
        ),
      );

  /// The original result and its `adjustedBy(delta)` result.
  (AttackRollResult, AttackRollResult) adjusted(int delta) {
    final original = resolve();
    return (original, original.adjustedBy(delta));
  }
}

/// What a re-resolution case does after building its original result.
sealed class _Operation {
  const _Operation();
}

/// Re-resolves through the published static member with the die at `index`
/// replaced by `value`.
final class _ResolveReplaced extends _Operation {
  const _ResolveReplaced(this.index, this.value);

  final int index;
  final int value;
}

/// `adjustedBy(delta)` on the original result.
final class _Adjust extends _Operation {
  const _Adjust(this.delta);

  final int delta;
}

/// `CheckResult.resolve` with a kind of `attackRoll`.
final class _ResolveAttackRollKind extends _Operation {
  const _ResolveAttackRollKind();
}

/// What a re-resolution case expects to happen.
sealed class _Expected {
  const _Expected();
}

/// The new result is a check holding this natural, total, outcome and
/// appended others; the original resolved to [originalOutcome].
final class _CheckIs extends _Expected {
  const _CheckIs(
    this.originalOutcome,
    this.natural,
    this.total,
    this.outcome,
    this.others,
  );

  final D20TestOutcome originalOutcome;
  final int natural;
  final int total;
  final D20TestOutcome outcome;
  final List<int> others;
}

/// The new result is an attack holding this natural, total, outcome and
/// appended others, at the default critical range; the original resolved to
/// [originalOutcome].
final class _AttackIs extends _Expected {
  const _AttackIs(
    this.originalOutcome,
    this.natural,
    this.total,
    this.outcome,
    this.isCriticalHit,
    this.others,
  );

  final D20TestOutcome originalOutcome;
  final int natural;
  final int total;
  final D20TestOutcome outcome;
  final bool isCriticalHit;
  final List<int> others;
}

/// The adjustment leaves the original result unchanged (an equal fresh
/// resolve), with this total and outcome, and the adjusted result differs.
final class _OriginalKept extends _Expected {
  const _OriginalKept(this.total, this.outcome);

  final int total;
  final D20TestOutcome outcome;
}

/// The operation throws an ArgumentError with this name and invalidValue.
final class _Rejects extends _Expected {
  const _Rejects(this.argumentName, this.invalidValue);

  final String argumentName;
  final Object? invalidValue;
}

typedef _ReresolutionCase = ({
  String label,
  String requirement,
  String path,
  _Start start,
  _Operation operation,
  _Expected expected,
});

/// The 14-row re-resolution table of `doc/specs/d20-tests.md` section 4.5,
/// in the order written there.
const List<_ReresolutionCase> _cases = [
  (
    label: 'attack rerolled from a miss to a hit',
    requirement:
        'doc/specs/d20-tests.md FR-064 and FR-012 (SRD 5.2.1, "Interactions '
        'with Rerolls", p. 8; "Attack Rolls", p. 7)',
    path: 'happy',
    start: _AttackStart(RollMode.advantage, [4, 3], 3, 15),
    operation: _ResolveReplaced(0, 14),
    expected: _AttackIs(
      D20TestOutcome.failure,
      14,
      17,
      D20TestOutcome.success,
      false,
      [],
    ),
  ),
  (
    label: 'attack replaced to a natural 20',
    requirement:
        'doc/specs/d20-tests.md FR-064, FR-029 and FR-051 (SRD 5.2.1, '
        '"Rolling 20 or 1", p. 7)',
    path: 'unhappy (rule interaction)',
    start: _AttackStart(RollMode.normal, [5], 0, 30),
    operation: _ResolveReplaced(0, 20),
    expected: _AttackIs(
      D20TestOutcome.failure,
      20,
      20,
      D20TestOutcome.success,
      true,
      [],
    ),
  ),
  (
    label: 'attack replaced to a natural 1',
    requirement:
        'doc/specs/d20-tests.md FR-064, FR-030 and FR-051 (SRD 5.2.1, '
        '"Rolling 20 or 1", p. 7)',
    path: 'unhappy (rule interaction)',
    start: _AttackStart(RollMode.normal, [18], 10, 10),
    operation: _ResolveReplaced(0, 1),
    expected: _AttackIs(
      D20TestOutcome.success,
      1,
      11,
      D20TestOutcome.failure,
      false,
      [],
    ),
  ),
  (
    label: 'check rerolled',
    requirement:
        'doc/specs/d20-tests.md FR-063 and FR-012 (SRD 5.2.1, "Interactions '
        'with Rerolls", p. 8; "D20 Tests", p. 6)',
    path: 'happy',
    start: _CheckStart(D20TestKind.abilityCheck, RollMode.normal, [3], 2, 10),
    operation: _ResolveReplaced(0, 19),
    expected: _CheckIs(
      D20TestOutcome.failure,
      19,
      21,
      D20TestOutcome.success,
      [],
    ),
  ),
  (
    label: 'adjusted check up to the DC',
    requirement:
        'doc/specs/d20-tests.md FR-065 (SRD 5.2.1, "Add Modifiers", p. 6)',
    path: 'unhappy (boundary)',
    start: _CheckStart(D20TestKind.abilityCheck, RollMode.normal, [8], 1, 15),
    operation: _Adjust(6),
    expected: _CheckIs(D20TestOutcome.failure, 8, 15, D20TestOutcome.success, [
      6,
    ]),
  ),
  (
    label: 'adjusted check down one below',
    requirement:
        'doc/specs/d20-tests.md FR-065 (SRD 5.2.1, "Add Modifiers", p. 6)',
    path: 'unhappy (boundary)',
    start: _CheckStart(D20TestKind.abilityCheck, RollMode.normal, [10], 5, 15),
    operation: _Adjust(-1),
    expected: _CheckIs(D20TestOutcome.success, 10, 14, D20TestOutcome.failure, [
      -1,
    ]),
  ),
  (
    label: 'adjusted by zero',
    requirement:
        'doc/specs/d20-tests.md FR-065 (SRD 5.2.1, "Add Modifiers", p. 6)',
    path: 'unhappy (empty and minimal)',
    start: _CheckStart(D20TestKind.abilityCheck, RollMode.normal, [10], 5, 15),
    operation: _Adjust(0),
    expected: _CheckIs(D20TestOutcome.success, 10, 15, D20TestOutcome.success, [
      0,
    ]),
  ),
  (
    label: 'natural 20 attack adjusted far down',
    requirement:
        'doc/specs/d20-tests.md FR-065, FR-066 and FR-051 (SRD 5.2.1, '
        '"Rolling 20 or 1", p. 7)',
    path: 'unhappy (boundary)',
    start: _AttackStart(RollMode.normal, [20], 0, 15),
    operation: _Adjust(-100),
    expected: _AttackIs(
      D20TestOutcome.success,
      20,
      -80,
      D20TestOutcome.success,
      true,
      [-100],
    ),
  ),
  (
    label: 'natural 1 attack adjusted far up',
    requirement:
        'doc/specs/d20-tests.md FR-065, FR-066 and FR-051 (SRD 5.2.1, '
        '"Rolling 20 or 1", p. 7)',
    path: 'unhappy (boundary)',
    start: _AttackStart(RollMode.normal, [1], 0, 5),
    operation: _Adjust(100),
    expected: _AttackIs(
      D20TestOutcome.failure,
      1,
      101,
      D20TestOutcome.failure,
      false,
      [100],
    ),
  ),
  (
    label: 'natural 19 attack adjusted onto the AC',
    requirement:
        'doc/specs/d20-tests.md FR-065, FR-066 and FR-033 (SRD 5.2.1, '
        '"Rolling 20 or 1", p. 7)',
    path: 'unhappy (boundary)',
    start: _AttackStart(RollMode.normal, [19], 0, 25),
    operation: _Adjust(6),
    expected: _AttackIs(
      D20TestOutcome.failure,
      19,
      25,
      D20TestOutcome.success,
      false,
      [6],
    ),
  ),
  (
    label: 'natural 20 check adjusted below the DC',
    requirement:
        'doc/specs/d20-tests.md FR-065, FR-066 and FR-031 (SRD 5.2.1, '
        '"Rolling 20 or 1", p. 7)',
    path: 'unhappy (rule interaction)',
    start: _CheckStart(D20TestKind.abilityCheck, RollMode.normal, [20], 0, 15),
    operation: _Adjust(-6),
    expected: _CheckIs(D20TestOutcome.success, 20, 14, D20TestOutcome.failure, [
      -6,
    ]),
  ),
  (
    label: 'adjustment leaves the original',
    requirement: 'doc/specs/d20-tests.md FR-065 (doc/rules/architecture.md §3)',
    path: 'unhappy (immutability)',
    start: _CheckStart(D20TestKind.abilityCheck, RollMode.normal, [8], 1, 15),
    operation: _Adjust(6),
    expected: _OriginalKept(9, D20TestOutcome.failure),
  ),
  (
    label: 'rerolled roll for a save',
    requirement:
        'doc/specs/d20-tests.md FR-063, FR-012 and FR-011 (SRD 5.2.1, '
        '"Interactions with Rerolls", p. 8; "D20 Tests", p. 6)',
    path: 'unhappy (rule interaction)',
    start: _CheckStart(
      D20TestKind.savingThrow,
      RollMode.advantage,
      [18, 3],
      0,
      15,
    ),
    operation: _ResolveReplaced(0, 2),
    expected: _CheckIs(
      D20TestOutcome.success,
      3,
      3,
      D20TestOutcome.failure,
      [],
    ),
  ),
  (
    label: 'CheckResult.resolve with attackRoll',
    requirement:
        'doc/specs/d20-tests.md FR-063 and FR-062 (SRD 5.2.1, "Ability '
        'Checks", p. 6; "Attack Rolls", p. 7)',
    path: 'unhappy (invalid input)',
    start: _CheckStart(D20TestKind.attackRoll, RollMode.normal, [10], 0, 15),
    operation: _ResolveAttackRollKind(),
    expected: _Rejects('kind', D20TestKind.attackRoll),
  ),
];

/// Runs a case: the original result and the result of its operation. The
/// rejection row throws before returning.
(Object, Object) _performed(_ReresolutionCase c) => switch (c.operation) {
  _ResolveReplaced(:final index, :final value) => _performedReplaced(
    c.start,
    index,
    value,
  ),
  _Adjust(:final delta) => _performedAdjust(c.start, delta),
  _ResolveAttackRollKind() => _performedAttackRollKind(c.start),
};

(Object, Object) _performedReplaced(_Start start, int index, int value) =>
    switch (start) {
      final _CheckStart s => s.resolveReplaced(index, value),
      final _AttackStart s => s.resolveReplaced(index, value),
    };

(Object, Object) _performedAdjust(_Start start, int delta) => switch (start) {
  final _CheckStart s => s.adjusted(delta),
  final _AttackStart s => s.adjusted(delta),
};

(Object, Object) _performedAttackRollKind(_Start start) => switch (start) {
  final _CheckStart s => (s.resolve(), s.resolve()),
  _AttackStart() => throw StateError(
    'the attackRoll rejection row starts '
    'from a check start, never from an attack start',
  ),
};

/// Matches the ArgumentError the guards throw: the exact runtime type (never
/// a subtype such as RangeError), the argument name and the invalid value.
/// Never the message text.
Matcher _argumentError(String name, Object? invalidValue) => throwsA(
  isA<ArgumentError>()
      .having((e) => e.runtimeType, 'runtimeType', ArgumentError)
      .having((e) => e.name, 'name', name)
      .having((e) => e.invalidValue, 'invalidValue', invalidValue),
);

void main() {
  /// Requirement: per case - the 14-row re-resolution table of
  ///   doc/specs/d20-tests.md FR-063, FR-064, FR-065 and FR-066: each row
  ///   builds the original result, applies the operation and asserts the
  ///   expected new result; each row cites its own ids and path.
  /// Path: per case
  group('re-resolution after a reroll or adjustment', () {
    for (final c in _cases) {
      test('${c.label} [${c.path}] (${c.requirement})', () {
        final expected = c.expected;
        switch (expected) {
          case _CheckIs(
            :final originalOutcome,
            :final natural,
            :final total,
            :final outcome,
            :final others,
          ):
            final (original, result) = _performed(c);
            final start = c.start as _CheckStart;
            expect((original as CheckResult).outcome, originalOutcome);
            expect(result.runtimeType, CheckResult);
            expect((result as CheckResult).kind, start.kind);
            expect(result.roll.natural, natural);
            expect(result.total, total);
            expect(result.outcome, outcome);
            expect(result.modifiers.others, [
              for (final value in others) Modifier(value),
            ]);
          case _AttackIs(
            :final originalOutcome,
            :final natural,
            :final total,
            :final outcome,
            :final isCriticalHit,
            :final others,
          ):
            final (original, result) = _performed(c);
            expect((original as AttackRollResult).outcome, originalOutcome);
            expect(result.runtimeType, AttackRollResult);
            final attack = result as AttackRollResult;
            expect(attack.roll.natural, natural);
            expect(attack.total, total);
            expect(attack.outcome, outcome);
            expect(attack.isCriticalHit, isCriticalHit);
            expect(attack.criticalRange, 20);
            expect(attack.hit, outcome == D20TestOutcome.success);
            expect(attack.modifiers.others, [
              for (final value in others) Modifier(value),
            ]);
          case _OriginalKept(:final total, :final outcome):
            final (original, adjusted) = _performed(c);
            final start = c.start as _CheckStart;
            final kept = original as CheckResult;
            expect(kept, start.resolve());
            expect(kept.total, total);
            expect(kept.outcome, outcome);
            expect(kept.modifiers.others, isEmpty);
            expect((adjusted as CheckResult).total, isNot(total));
            expect(adjusted.outcome, isNot(outcome));
            expect(kept, isNot(adjusted));
          case _Rejects(:final argumentName, :final invalidValue):
            expect(
              () => _performed(c),
              _argumentError(argumentName, invalidValue),
            );
        }
      });
    }
  });
}
