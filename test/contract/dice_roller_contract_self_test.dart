import 'dart:math';

import 'package:srd5e/src/shared_kernel/dice/dice_expression.dart';
import 'package:srd5e/src/shared_kernel/dice/die.dart';
import 'package:srd5e/src/shared_kernel/dice/die_roll.dart';
import 'package:srd5e/src/shared_kernel/dice/roll_result.dart';
import 'package:srd5e/src/shared_ports/adapters/seeded_dice_roller.dart';
import 'package:srd5e/src/shared_ports/dice_roller/dice_roller.dart';
import 'package:srd5e/src/shared_ports/dice_roller/dice_roller_exception.dart';
import 'package:test/test.dart';

import 'dice_roller_contract.dart';

/// A [Random] that fails with [cause] and [stackTrace].
final class _FailingRandom implements Random {
  _FailingRandom(this.cause, this.stackTrace);

  final Exception cause;
  final StackTrace stackTrace;

  @override
  int nextInt(int max) => Error.throwWithStackTrace(cause, stackTrace);

  @override
  bool nextBool() => throw UnimplementedError('only nextInt is used');

  @override
  double nextDouble() => throw UnimplementedError('only nextInt is used');
}

RollResult _ones(DiceExpression e) =>
    RollResult(e, [for (var i = 0; i < e.count; i++) DieRoll(e.die, 1)]);

/// A roller that does not wrap its backend: the raw exception leaks.
final class _LeakingRoller implements DiceRoller {
  _LeakingRoller(this.random);

  final Random random;

  @override
  RollResult roll(DiceExpression expression) {
    random.nextInt(expression.die.sides);
    return _ones(expression);
  }
}

/// A roller that swallows the backend failure and returns a default result.
final class _SwallowingRoller implements DiceRoller {
  _SwallowingRoller(this.random);

  final Random random;

  @override
  RollResult roll(DiceExpression expression) {
    try {
      random.nextInt(expression.die.sides);
    } on Exception {
      // Deliberately wrong: hides the failure behind a default result.
    }
    return _ones(expression);
  }
}

/// A roller that wraps the failure but throws away the original cause.
final class _CauseDroppingRoller implements DiceRoller {
  _CauseDroppingRoller(this.random);

  final Random random;

  @override
  RollResult roll(DiceExpression expression) {
    try {
      random.nextInt(expression.die.sides);
    } on Exception {
      throw DiceRollerException(
        expression: expression,
        reason: DiceRollerFailureReason.unavailable,
      );
    }
    return _ones(expression);
  }
}

/// A roller that reports the wrong reason for a backend failure.
final class _WrongReasonRoller implements DiceRoller {
  _WrongReasonRoller(this.random);

  final Random random;

  @override
  RollResult roll(DiceExpression expression) {
    try {
      random.nextInt(expression.die.sides);
    } on Exception catch (cause, stackTrace) {
      throw DiceRollerException(
        expression: expression,
        reason: DiceRollerFailureReason.invalidResult,
        cause: cause,
        causeStackTrace: stackTrace,
      );
    }
    return _ones(expression);
  }
}

/// A roller that reports the wrong stack trace.
final class _TraceDroppingRoller implements DiceRoller {
  _TraceDroppingRoller(this.random);

  final Random random;

  @override
  RollResult roll(DiceExpression expression) {
    try {
      random.nextInt(expression.die.sides);
    } on Exception catch (cause) {
      throw DiceRollerException(
        expression: expression,
        reason: DiceRollerFailureReason.unavailable,
        cause: cause,
      );
    }
    return _ones(expression);
  }
}

/// A roller that answers a different expression than the one requested.
final class _WrongExpressionRoller implements DiceRoller {
  @override
  RollResult roll(DiceExpression expression) => _ones(
    DiceExpression(
      expression.count,
      expression.die,
      modifier: expression.modifier + 1,
    ),
  );
}

/// A roller that answers one die fewer than requested (as a result for a
/// different count).
final class _WrongCountRoller implements DiceRoller {
  @override
  RollResult roll(DiceExpression expression) => _ones(
    DiceExpression(
      expression.count == 1 ? 2 : expression.count - 1,
      expression.die,
      modifier: expression.modifier,
    ),
  );
}

/// A roller that answers with another die.
final class _WrongDieRoller implements DiceRoller {
  @override
  RollResult roll(DiceExpression expression) => _ones(
    DiceExpression(
      expression.count,
      expression.die == Die.d6 ? Die.d8 : Die.d6,
      modifier: expression.modifier,
    ),
  );
}

void main() {
  final expression = DiceExpression(2, Die.d6);

  /// Requirement: doc/specs/errors-and-results.md FR-032 and
  ///   doc/specs/dice-and-rolls.md FR-048 - the contract suite must be able to
  ///   fail: each adapter that breaks the failure contract makes
  ///   `expectWrapsBackendFailure` fail.
  /// Path: unhappy (failure of collaborator)
  group('the failure contract rejects a bad adapter', () {
    final bad = <String, DiceRoller Function(Exception, StackTrace)>{
      'leaks the raw backend exception': (c, t) =>
          _LeakingRoller(_FailingRandom(c, t)),
      'swallows the failure and returns a default result': (c, t) =>
          _SwallowingRoller(_FailingRandom(c, t)),
      'drops the cause': (c, t) => _CauseDroppingRoller(_FailingRandom(c, t)),
      'reports the wrong reason': (c, t) =>
          _WrongReasonRoller(_FailingRandom(c, t)),
      'drops the stack trace': (c, t) =>
          _TraceDroppingRoller(_FailingRandom(c, t)),
    };

    /// Requirement: per case
    /// Path: per case
    for (final entry in bad.entries) {
      test('an adapter that ${entry.key} [unhappy (failure)]', () {
        expect(
          () => expectWrapsBackendFailure(entry.value, expression),
          throwsA(isA<TestFailure>()),
        );
      });
    }

    /// Requirement: doc/specs/dice-and-rolls.md FR-048 - the same check passes
    ///   for the real adapter, so the cases above fail for the right reason.
    /// Path: happy
    test('the real SeededDiceRoller passes the same check', () {
      expect(
        () => expectWrapsBackendFailure(
          (c, t) => SeededDiceRoller(_FailingRandom(c, t)),
          expression,
        ),
        returnsNormally,
      );
    });
  });

  /// Requirement: doc/specs/dice-and-rolls.md FR-046 and FR-047 - the roll
  ///   contract must be able to fail: a roller that answers another
  ///   expression makes `expectHonoursRollContract` fail.
  /// Path: unhappy (failure of collaborator)
  group('the roll contract rejects a bad roller', () {
    final bad = <String, DiceRoller>{
      'answers a different modifier': _WrongExpressionRoller(),
      'answers a different count': _WrongCountRoller(),
      'answers a different die': _WrongDieRoller(),
    };

    /// Requirement: per case
    /// Path: per case
    for (final entry in bad.entries) {
      test('a roller that ${entry.key} [unhappy (failure)]', () {
        expect(
          () => expectHonoursRollContract(entry.value, expression),
          throwsA(isA<TestFailure>()),
        );
      });
    }

    /// Requirement: doc/specs/dice-and-rolls.md FR-046 - the same check passes
    ///   for a correct roller.
    /// Path: happy
    test('a correct roller passes the same check', () {
      expect(
        () =>
            expectHonoursRollContract(SeededDiceRoller(Random(7)), expression),
        returnsNormally,
      );
    });
  });
}
