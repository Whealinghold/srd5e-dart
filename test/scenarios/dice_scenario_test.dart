import 'dart:math';

import 'package:srd5e/adapters.dart';
import 'package:srd5e/srd5e.dart';
import 'package:srd5e/testing.dart';
import 'package:test/test.dart';

void main() {
  /// Requirement: doc/specs/dice-and-rolls.md FR-068 - importing only the
  ///   public entry points, a FixedDiceRoller serving [18, 3] for 2d20 yields
  ///   a RollResult through rollChecked (SRD 5.2.1, "Roll Two D20s", p. 8). A
  ///   wiring smoke test; the selection arithmetic is proven by FR-041/FR-042.
  /// Path: happy
  test('a FixedDiceRoller serves 18 and 3 for 2d20 through rollChecked', () {
    final DiceRoller roller = FixedDiceRoller([18, 3]);
    final expression = DiceExpression(2, Die.d20);

    final RollResult result = roller.rollChecked(expression);

    expect(result.expression, expression);
    expect(result.rolls.map((r) => r.value), [18, 3]);
    expect(result.total, 21);
  });

  /// Requirement: doc/specs/dice-and-rolls.md FR-017, FR-020, FR-060 and
  ///   FR-050 - text parsed with tryParse is rolled by the bundled
  ///   SeededDiceRoller through the public entry points (SRD 5.2.1, "Hit
  ///   Points", p. 255: "2d8 + 2").
  /// Path: happy
  test('parsed text is rolled by a SeededDiceRoller', () {
    final parsed = DiceExpression.tryParse('2d8 + 2');
    final expression = (parsed as ParsedDiceExpression).expression;
    final DiceRoller roller = SeededDiceRoller(Random(7));

    final result = roller.rollChecked(expression);

    expect(result.expression, expression);
    expect(result.total, inInclusiveRange(4, 18));
    expect(result.total, result.diceTotal + 2);
  });

  /// Requirement: doc/specs/dice-and-rolls.md FR-048, FR-049 and FR-086 - a
  ///   consumer catches a roller failure through the exported root type and
  ///   reads its data, using only the public entry points.
  /// Path: unhappy (failure)
  test('a roller failure is caught as an Srd5eException', () {
    final expression = DiceExpression(1, Die.d20);
    final DiceRoller roller = CallbackDiceRoller(
      (e) => throw DiceRollerException(
        expression: e,
        reason: DiceRollerFailureReason.unavailable,
        cause: const FormatException('backend down'),
      ),
    );

    Srd5eException? caught;
    try {
      roller.rollChecked(expression);
    } on Srd5eException catch (e) {
      caught = e;
    }

    expect(caught, isA<DiceRollerException>());
    final failure = caught! as DiceRollerException;
    expect(failure.errorType, 'dice_roller_exception');
    expect(failure.reason, DiceRollerFailureReason.unavailable);
    expect(failure.expression, expression);
    expect(failure.cause, isA<FormatException>());
  });

  /// Requirement: doc/specs/dice-and-rolls.md FR-051 - through the public API
  ///   a roller that answers another expression is reported as invalidResult.
  /// Path: unhappy (failure)
  test('a roller answering another expression is invalidResult', () {
    final requested = DiceExpression(1, Die.d20);
    final DiceRoller roller = CallbackDiceRoller(
      (_) => FixedDiceRoller([3]).roll(DiceExpression(1, Die.d20, modifier: 1)),
    );

    expect(
      () => roller.rollChecked(requested),
      throwsA(
        isA<DiceRollerException>()
            .having(
              (e) => e.reason,
              'reason',
              DiceRollerFailureReason.invalidResult,
            )
            .having((e) => e.expression, 'expression', requested),
      ),
    );
  });
}
