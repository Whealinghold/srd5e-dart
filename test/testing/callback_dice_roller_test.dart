import 'package:srd5e/src/shared_kernel/dice/dice_expression.dart';
import 'package:srd5e/src/shared_kernel/dice/die.dart';
import 'package:srd5e/src/shared_kernel/dice/die_roll.dart';
import 'package:srd5e/src/shared_kernel/dice/roll_result.dart';
import 'package:srd5e/src/shared_ports/dice_roller/dice_roller.dart';
import 'package:srd5e/src/shared_ports/dice_roller/dice_roller_exception.dart';
import 'package:srd5e/src/testing/callback_dice_roller.dart';
import 'package:test/test.dart';

void main() {
  final expression = DiceExpression(1, Die.d20);
  final other = DiceExpression(2, Die.d6);

  RollResult resultOf(DiceExpression e, List<int> faces) =>
      RollResult(e, [for (final f in faces) DieRoll(e.die, f)]);

  /// Requirement: doc/specs/dice-and-rolls.md FR-059 - CallbackDiceRoller
  ///   returns whatever its callback returns.
  /// Path: happy
  group('CallbackDiceRoller returns', () {
    /// Requirement: doc/specs/dice-and-rolls.md FR-059 - the callback gets the
    ///   requested expression and its result is returned as it is.
    /// Path: happy
    test('the callback result for the requested expression', () {
      DiceExpression? received;
      final expected = resultOf(expression, [17]);
      final roller = CallbackDiceRoller((e) {
        received = e;
        return expected;
      });

      final result = roller.roll(expression);

      expect(received, expression);
      expect(result, same(expected));
    });

    /// Requirement: doc/specs/dice-and-rolls.md FR-059 - a result for another
    ///   expression is returned unchanged, so tests can simulate a roller that
    ///   breaks its contract.
    /// Path: unhappy (failure)
    test('a result for a different expression, unchanged', () {
      final wrong = resultOf(other, [3, 4]);
      final roller = CallbackDiceRoller((_) => wrong);

      expect(roller.roll(expression), same(wrong));
    });

    /// Requirement: doc/specs/dice-and-rolls.md FR-045 - a CallbackDiceRoller
    ///   is a DiceRoller.
    /// Path: happy
    test('is a DiceRoller', () {
      expect(CallbackDiceRoller((e) => resultOf(e, [1])), isA<DiceRoller>());
    });

    /// Requirement: doc/specs/dice-and-rolls.md FR-059 - the callback runs once
    ///   per roll, so a test can script a different result each time.
    /// Path: happy
    test('the callback runs once per roll', () {
      var calls = 0;
      final roller = CallbackDiceRoller((e) => resultOf(e, [++calls]));

      expect(roller.roll(expression).total, 1);
      expect(roller.roll(expression).total, 2);
      expect(calls, 2);
    });
  });

  /// Requirement: doc/specs/dice-and-rolls.md FR-059 - anything the callback
  ///   throws propagates unchanged, so tests can simulate failures.
  /// Path: unhappy (failure)
  group('CallbackDiceRoller propagates', () {
    /// Requirement: doc/specs/dice-and-rolls.md FR-059 - a DiceRollerException
    ///   is the same instance.
    /// Path: unhappy (failure)
    test('a DiceRollerException as the same instance', () {
      final failure = DiceRollerException(
        expression: expression,
        reason: DiceRollerFailureReason.unavailable,
      );
      final roller = CallbackDiceRoller((_) => throw failure);

      Object? caught;
      try {
        roller.roll(expression);
      } on Object catch (e) {
        caught = e;
      }

      expect(caught, same(failure));
    });

    /// Requirement: doc/specs/dice-and-rolls.md FR-059 - a raw Exception and an
    ///   Error are not wrapped or changed.
    /// Path: unhappy (failure)
    test('a raw Exception and an Error unchanged', () {
      const raw = FormatException('backend');
      final bug = StateError('bug');

      expect(
        () => CallbackDiceRoller((_) => throw raw).roll(expression),
        throwsA(same(raw)),
      );
      expect(
        () => CallbackDiceRoller((_) => throw bug).roll(expression),
        throwsA(same(bug)),
      );
    });
  });
}
