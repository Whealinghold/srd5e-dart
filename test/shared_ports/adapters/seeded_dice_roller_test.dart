import 'dart:math';

import 'package:srd5e/src/shared_kernel/dice/dice_expression.dart';
import 'package:srd5e/src/shared_kernel/dice/die.dart';
import 'package:srd5e/src/shared_ports/adapters/seeded_dice_roller.dart';
import 'package:srd5e/src/shared_ports/dice_roller/dice_roller.dart';
import 'package:srd5e/src/shared_ports/dice_roller/dice_roller_exception.dart';
import 'package:test/test.dart';

import '../../support/argument_error_matcher.dart';

/// A [Random] that returns scripted values and records the bound of every
/// `nextInt` call.
final class _ScriptedRandom implements Random {
  _ScriptedRandom(this._script);

  final List<int> _script;
  final List<int> bounds = [];

  @override
  int nextInt(int max) {
    bounds.add(max);
    return _script[bounds.length - 1];
  }

  @override
  bool nextBool() => throw UnimplementedError('only nextInt is used');

  @override
  double nextDouble() => throw UnimplementedError('only nextInt is used');
}

/// A [Random] whose `nextInt` throws [error] with [stackTrace].
final class _ThrowingRandom implements Random {
  _ThrowingRandom(this.error, [this.stackTrace]);

  final Object error;
  final StackTrace? stackTrace;

  @override
  int nextInt(int max) => stackTrace == null
      ? throw error
      : Error.throwWithStackTrace(error, stackTrace!);

  @override
  bool nextBool() => throw UnimplementedError('only nextInt is used');

  @override
  double nextDouble() => throw UnimplementedError('only nextInt is used');
}

void main() {
  /// Requirement: doc/specs/dice-and-rolls.md FR-061 - one nextInt(sides) call
  ///   per die, in order, mapped to the face v + 1 (package design).
  /// Path: unhappy (boundary)
  group('SeededDiceRoller maps the Random to faces', () {
    /// Requirement: doc/specs/dice-and-rolls.md FR-061 - a Random returning 0
    ///   gives face 1 and one returning sides - 1 gives the highest face.
    /// Path: unhappy (boundary)
    test('0 gives face 1 and sides - 1 gives the highest face', () {
      final random = _ScriptedRandom([0, 5, 2]);
      final roller = SeededDiceRoller(random);

      final result = roller.roll(DiceExpression(3, Die.d6));

      expect(result.rolls.map((r) => r.value), [1, 6, 3]);
    });

    /// Requirement: doc/specs/dice-and-rolls.md FR-061 - nextInt is called
    ///   exactly once per die with the die's sides as the bound.
    /// Path: happy
    test('calls nextInt once per die with the sides as the bound', () {
      final random = _ScriptedRandom([0, 0, 0, 0]);
      final roller = SeededDiceRoller(random);

      roller.roll(DiceExpression(3, Die.d20));
      roller.roll(DiceExpression(1, Die(7)));

      expect(random.bounds, [20, 20, 20, 7]);
    });

    /// Requirement: doc/specs/dice-and-rolls.md FR-061 - the faces keep the
    ///   order the Random produced them, and the modifier is added to the
    ///   total.
    /// Path: happy
    test('keeps the order and applies the modifier', () {
      final roller = SeededDiceRoller(_ScriptedRandom([7, 0]));
      final expression = DiceExpression(2, Die.d8, modifier: 2);

      final result = roller.roll(expression);

      expect(result.expression, expression);
      expect(result.rolls.map((r) => r.value), [8, 1]);
      expect(result.total, 11);
    });

    /// Requirement: doc/specs/dice-and-rolls.md FR-064 - only the injected
    ///   Random is used; two rollers over separate Randoms never touch each
    ///   other's.
    /// Path: unhappy (determinism)
    test('uses only the Random it was given', () {
      final first = _ScriptedRandom([0, 0]);
      final second = _ScriptedRandom([0, 0]);
      final roller = SeededDiceRoller(first);

      roller.roll(DiceExpression(2, Die.d6));

      expect(first.bounds, [6, 6]);
      expect(second.bounds, isEmpty);
    });
  });

  /// Requirement: doc/specs/dice-and-rolls.md FR-062 and FR-063 - the same
  ///   seed gives the same results, and the sequence advances per die, in
  ///   order. Concrete values are never pinned (testing.md §4).
  /// Path: happy
  group('SeededDiceRoller is deterministic', () {
    /// Requirement: doc/specs/dice-and-rolls.md FR-062 - two rollers over equal
    ///   Random(7) give identical results for the same sequence of
    ///   expressions.
    /// Path: happy
    test('two rollers over equal seeds agree', () {
      final first = SeededDiceRoller(Random(7));
      final second = SeededDiceRoller(Random(7));
      final expressions = [
        DiceExpression(1, Die.d20),
        DiceExpression(4, Die.d6),
        DiceExpression(2, Die.d8, modifier: 2),
        DiceExpression(1, Die.d100),
      ];

      final firstResults = [for (final e in expressions) first.roll(e)];
      final secondResults = [for (final e in expressions) second.roll(e)];

      expect(firstResults, secondResults);
    });

    /// Requirement: doc/specs/dice-and-rolls.md FR-062 - a different seed is
    ///   not required to differ, but a long run of d1000 rolls from two
    ///   different seeds is not identical, so the seed is really used.
    /// Path: unhappy (determinism)
    test('different seeds give different long runs', () {
      final expression = DiceExpression(50, Die(1000));

      final first = SeededDiceRoller(Random(7)).roll(expression);
      final second = SeededDiceRoller(Random(8)).roll(expression);

      expect(first == second, isFalse);
    });

    /// Requirement: doc/specs/dice-and-rolls.md FR-063 - one 2d6 call gives the
    ///   same faces as two successive 1d6 calls on an equal Random(7).
    /// Path: happy
    test('one 2d6 equals two 1d6 on an equal seed', () {
      final together = SeededDiceRoller(Random(7));
      final apart = SeededDiceRoller(Random(7));
      final oneD6 = DiceExpression(1, Die.d6);

      final pair = together.roll(DiceExpression(2, Die.d6));
      final first = apart.roll(oneD6);
      final second = apart.roll(oneD6);

      expect(pair.rolls, [...first.rolls, ...second.rolls]);
    });
  });

  /// Requirement: doc/specs/dice-and-rolls.md FR-060 - a result satisfying the
  ///   port contract for the largest valid expression.
  /// Path: unhappy (boundary)
  group('SeededDiceRoller at the limits', () {
    /// Requirement: doc/specs/dice-and-rolls.md FR-060 - 1000d1000 with the
    ///   largest modifier is rolled, with every face in range.
    /// Path: unhappy (boundary)
    test('1000d1000 + 1000000 is rolled within range', () {
      final expression = DiceExpression(1000, Die(1000), modifier: 1000000);

      final result = SeededDiceRoller(Random(7)).roll(expression);

      expect(result.expression, expression);
      expect(result.rolls, hasLength(1000));
      expect(
        result.total,
        inInclusiveRange(expression.minimum, expression.maximum),
      );
    });

    /// Requirement: doc/specs/dice-and-rolls.md FR-045 - it is a DiceRoller.
    /// Path: happy
    test('is a DiceRoller', () {
      expect(SeededDiceRoller(Random(7)), isA<DiceRoller>());
    });
  });

  /// Requirement: doc/specs/dice-and-rolls.md FR-084 and FR-048 - nextInt runs
  ///   inside wrapPortFailure: an Exception from the Random becomes
  ///   DiceRollerException(unavailable); an Error propagates unchanged.
  /// Path: unhappy (failure of collaborator)
  group('SeededDiceRoller when the Random fails', () {
    final expression = DiceExpression(2, Die.d6, modifier: 1);

    /// Requirement: doc/specs/dice-and-rolls.md FR-084 and FR-048 - an
    ///   Exception from nextInt surfaces as DiceRollerException(unavailable)
    ///   with the expression, the original cause and its stack trace.
    /// Path: unhappy (failure of collaborator)
    test('an Exception becomes DiceRollerException(unavailable)', () {
      const cause = FormatException('entropy source down');
      final trace = StackTrace.fromString('random trace');
      final roller = SeededDiceRoller(_ThrowingRandom(cause, trace));

      Object? caught;
      try {
        roller.roll(expression);
      } on Object catch (e) {
        caught = e;
      }

      expect(caught, isA<DiceRollerException>());
      final failure = caught! as DiceRollerException;
      expect(failure.reason, DiceRollerFailureReason.unavailable);
      expect(failure.expression, expression);
      expect(failure.cause, same(cause));
      expect(failure.causeStackTrace, same(trace));
      expect(failure.errorType, 'dice_roller_exception');
    });

    /// Requirement: doc/specs/dice-and-rolls.md FR-084 - a failure on a later
    ///   die still fails the whole roll: no partial result is returned.
    /// Path: unhappy (failure of collaborator)
    test('a failure on the second die fails the whole roll', () {
      final random = _FailsAfter(1, const FormatException('later'));
      final roller = SeededDiceRoller(random);

      expect(
        () => roller.roll(expression),
        throwsA(
          isA<DiceRollerException>().having(
            (e) => e.cause,
            'cause',
            isA<FormatException>(),
          ),
        ),
      );
      expect(random.calls, 2);
    });

    /// Requirement: doc/specs/dice-and-rolls.md FR-084 - an Error from nextInt
    ///   propagates unchanged (`doc/specs/errors-and-results.md` FR-011).
    /// Path: unhappy (state error)
    test('an Error propagates unchanged', () {
      final bug = StateError('broken Random');
      final roller = SeededDiceRoller(_ThrowingRandom(bug));

      expect(() => roller.roll(expression), throwsA(same(bug)));
    });

    /// Requirement: doc/specs/dice-and-rolls.md FR-084 - a DiceRollerException
    ///   thrown by the Random is not wrapped a second time.
    /// Path: unhappy (failure of collaborator)
    test('a DiceRollerException from the Random is not wrapped again', () {
      final failure = DiceRollerException(
        expression: expression,
        reason: DiceRollerFailureReason.unavailable,
      );
      final roller = SeededDiceRoller(_ThrowingRandom(failure));

      expect(() => roller.roll(expression), throwsA(same(failure)));
    });

    /// Requirement: doc/specs/dice-and-rolls.md FR-084 - a Random that breaks
    ///   its own contract (returns a value outside 0 to sides - 1) produces an
    ///   ArgumentError from the face check, not a typed port failure.
    /// Path: unhappy (invalid input)
    test('a Random returning the bound gives an ArgumentError', () {
      final roller = SeededDiceRoller(_ScriptedRandom([6]));

      expect(
        () => roller.roll(DiceExpression(1, Die.d6)),
        throwsArgumentErrorFor('value', 7),
      );
    });
  });
}

/// A [Random] that returns 0 for [_goodCalls] calls and then throws [_error].
final class _FailsAfter implements Random {
  _FailsAfter(this._goodCalls, this._error);

  final int _goodCalls;
  final Exception _error;
  int calls = 0;

  @override
  int nextInt(int max) {
    calls++;
    if (calls > _goodCalls) throw _error;
    return 0;
  }

  @override
  bool nextBool() => throw UnimplementedError('only nextInt is used');

  @override
  double nextDouble() => throw UnimplementedError('only nextInt is used');
}
