import 'package:srd5e/src/shared_kernel/dice/dice_expression.dart';
import 'package:srd5e/src/shared_kernel/dice/die.dart';
import 'package:srd5e/src/shared_kernel/dice/die_roll.dart';
import 'package:srd5e/src/shared_kernel/dice/roll_result.dart';
import 'package:srd5e/src/shared_ports/dice_roller/dice_roller_checked.dart';
import 'package:srd5e/src/shared_ports/dice_roller/dice_roller_exception.dart';
import 'package:srd5e/src/testing/callback_dice_roller.dart';
import 'package:srd5e/src/testing/fixed_dice_roller.dart';
import 'package:test/test.dart';

typedef _MismatchCase = ({
  String label,
  String requirement,
  String path,
  DiceExpression returned,
});

final DiceExpression _requested = DiceExpression(2, Die.d8, modifier: 2);

/// One case per differing field of the expression (FR-051).
final List<_MismatchCase> _mismatches = [
  (
    label: 'a different count',
    requirement: 'doc/specs/dice-and-rolls.md FR-051',
    path: 'unhappy (failure)',
    returned: DiceExpression(3, Die.d8, modifier: 2),
  ),
  (
    label: 'a different die',
    requirement: 'doc/specs/dice-and-rolls.md FR-051',
    path: 'unhappy (failure)',
    returned: DiceExpression(2, Die.d6, modifier: 2),
  ),
  (
    label: 'a different modifier',
    requirement: 'doc/specs/dice-and-rolls.md FR-051',
    path: 'unhappy (failure)',
    returned: DiceExpression(2, Die.d8, modifier: 3),
  ),
];

RollResult _resultFor(DiceExpression e) =>
    RollResult(e, [for (var i = 0; i < e.count; i++) DieRoll(e.die, 1)]);

void main() {
  /// Requirement: doc/specs/dice-and-rolls.md FR-050 - rollChecked returns the
  ///   roller's result when it is for the requested expression.
  /// Path: happy
  group('rollChecked returns', () {
    /// Requirement: doc/specs/dice-and-rolls.md FR-050 - the same result
    ///   instance the roller returned.
    /// Path: happy
    test('the roller result for the requested expression', () {
      final expected = _resultFor(_requested);
      final roller = CallbackDiceRoller((_) => expected);

      expect(roller.rollChecked(_requested), same(expected));
    });

    /// Requirement: doc/specs/dice-and-rolls.md FR-050 and FR-054 - it works
    ///   through a real double and passes the expression on.
    /// Path: happy
    test('the faces served by a FixedDiceRoller', () {
      final roller = FixedDiceRoller([5, 7]);

      final result = roller.rollChecked(_requested);

      expect(result.rolls.map((r) => r.value), [5, 7]);
      expect(result.total, 14);
      expect(roller.requests, [_requested]);
    });
  });

  /// Requirement: per case - doc/specs/dice-and-rolls.md FR-051 - a result for a
  ///   different expression is a contract breach by the roller
  ///   (`doc/specs/errors-and-results.md` FR-036).
  /// Path: per case
  group('rollChecked rejects a result for another expression', () {
    /// Requirement: per case
    /// Path: per case
    for (final c in _mismatches) {
      test('${c.label} [${c.path}]', () {
        final roller = CallbackDiceRoller((_) => _resultFor(c.returned));

        Object? caught;
        try {
          roller.rollChecked(_requested);
        } on Object catch (e) {
          caught = e;
        }

        expect(caught, isA<DiceRollerException>());
        final failure = caught! as DiceRollerException;
        expect(failure.reason, DiceRollerFailureReason.invalidResult);
        expect(failure.expression, _requested);
        expect(failure.cause, isNull);
        expect(failure.errorType, 'dice_roller_exception');
      });
    }
  });

  /// Requirement: doc/specs/dice-and-rolls.md FR-052 and FR-053 - exceptions
  ///   thrown by the roller pass through rollChecked untouched.
  /// Path: unhappy (failure)
  group('rollChecked propagates', () {
    /// Requirement: doc/specs/dice-and-rolls.md FR-052 - a DiceRollerException
    ///   from the roller is the same instance, not wrapped again.
    /// Path: unhappy (failure)
    test('a DiceRollerException as the same instance', () {
      final failure = DiceRollerException(
        expression: _requested,
        reason: DiceRollerFailureReason.unavailable,
        cause: const FormatException('backend'),
      );
      final roller = CallbackDiceRoller((_) => throw failure);

      Object? caught;
      try {
        roller.rollChecked(_requested);
      } on Object catch (e) {
        caught = e;
      }

      expect(caught, same(failure));
      expect((caught! as DiceRollerException).reason, failure.reason);
    });

    /// Requirement: doc/specs/dice-and-rolls.md FR-053 - a StateError from the
    ///   roller is not caught.
    /// Path: unhappy (state error)
    test('a StateError', () {
      final bug = StateError('no more values');
      final roller = CallbackDiceRoller((_) => throw bug);

      expect(() => roller.rollChecked(_requested), throwsA(same(bug)));
    });

    /// Requirement: doc/specs/dice-and-rolls.md FR-053 - an ArgumentError from
    ///   the roller is not caught.
    /// Path: unhappy (state error)
    test('an ArgumentError', () {
      final bug = ArgumentError.value(21, 'values');
      final roller = CallbackDiceRoller((_) => throw bug);

      expect(() => roller.rollChecked(_requested), throwsA(same(bug)));
    });

    /// Requirement: doc/specs/dice-and-rolls.md FR-053 - a FixedDiceRoller that
    ///   runs out of values surfaces its StateError.
    /// Path: unhappy (state error)
    test('the StateError of a FixedDiceRoller with no values left', () {
      final roller = FixedDiceRoller(const []);

      expect(() => roller.rollChecked(_requested), throwsStateError);
    });
  });
}
