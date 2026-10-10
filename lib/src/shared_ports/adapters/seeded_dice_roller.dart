import 'dart:math' show Random;

import '../../shared_kernel/dice/dice_expression.dart';
import '../../shared_kernel/dice/die_roll.dart';
import '../../shared_kernel/dice/roll_result.dart';
import '../dice_roller/dice_roller.dart';
import '../dice_roller/dice_roller_exception.dart';
import '../errors/port_failure_guards.dart';

/// A generic [DiceRoller] that draws every die from a `Random` the caller
/// supplies.
///
/// Pass a seeded `Random` for reproducible rolls (the same seed gives the same
/// results for the same sequence of expressions), or an unseeded one to roll
/// for real. The choice is always the caller's: this class never creates a
/// `Random` of its own.
///
/// For each die, in order, it calls `nextInt(sides)` exactly once and maps the
/// returned `v` to the face `v + 1`, so a `Random` returning 0 gives face 1 and
/// one returning `sides - 1` gives the highest face.
///
/// The roller is silent: it emits no log, span or metric.
///
/// An `Exception` thrown by the `Random` surfaces as a [DiceRollerException]
/// with the reason [DiceRollerFailureReason.unavailable], the requested
/// expression and the original exception as `cause`. An `Error` propagates
/// unchanged.
final class SeededDiceRoller implements DiceRoller {
  /// Creates a roller that draws its dice from [random].
  SeededDiceRoller(Random random) : _random = random;

  final Random _random;

  @override
  RollResult roll(DiceExpression expression) {
    final sides = expression.die.sides;
    final rolls = wrapPortFailure(
      () => [
        for (var i = 0; i < expression.count; i++)
          DieRoll(expression.die, _random.nextInt(sides) + 1),
      ],
      (cause, stackTrace) => DiceRollerException(
        expression: expression,
        reason: DiceRollerFailureReason.unavailable,
        cause: cause,
        causeStackTrace: stackTrace,
      ),
    );
    return RollResult(expression, rolls);
  }
}
