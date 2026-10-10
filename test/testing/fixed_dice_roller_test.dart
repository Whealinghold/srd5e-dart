import 'package:srd5e/src/shared_kernel/dice/dice_expression.dart';
import 'package:srd5e/src/shared_kernel/dice/die.dart';
import 'package:srd5e/src/shared_kernel/dice/die_roll.dart';
import 'package:srd5e/src/shared_ports/dice_roller/dice_roller.dart';
import 'package:srd5e/src/testing/fixed_dice_roller.dart';
import 'package:test/test.dart';

import '../support/argument_error_matcher.dart';

typedef _ExtremeCase = ({
  String label,
  String requirement,
  String path,
  DiceExpression expression,
  List<int> minimumFaces,
  List<int> maximumFaces,
});

final List<_ExtremeCase> _extremes = [
  (
    label: 'one d20',
    requirement:
        'doc/specs/dice-and-rolls.md FR-055 (SRD 5.2.1, "D20 Tests", p. 6)',
    path: 'unhappy (boundary)',
    expression: DiceExpression(1, Die.d20),
    minimumFaces: [1],
    maximumFaces: [20],
  ),
  (
    label: 'four d6 with a modifier',
    requirement:
        'doc/specs/dice-and-rolls.md FR-055 (SRD 5.2.1, "Rogue Features", p. 62)',
    path: 'unhappy (boundary)',
    expression: DiceExpression(4, Die.d6, modifier: -3),
    minimumFaces: [1, 1, 1, 1],
    maximumFaces: [6, 6, 6, 6],
  ),
  (
    label: 'two dice the SRD does not print',
    requirement: 'doc/specs/dice-and-rolls.md FR-055 (package design)',
    path: 'unhappy (boundary)',
    expression: DiceExpression(2, Die(7)),
    minimumFaces: [1, 1],
    maximumFaces: [7, 7],
  ),
];

void main() {
  final d20 = DiceExpression(1, Die.d20);
  final twoD20 = DiceExpression(2, Die.d20);

  /// Requirement: doc/specs/dice-and-rolls.md FR-054 - the next unused values
  ///   are served in order, across dice and across calls (SRD 5.2.1, "Roll Two
  ///   D20s", p. 8).
  /// Path: happy
  group('FixedDiceRoller serves values in order', () {
    /// Requirement: doc/specs/dice-and-rolls.md FR-054 - [18, 3] serves one
    ///   2d20 (SRD 5.2.1, "Roll Two D20s", p. 8: an 18 and a 3).
    /// Path: happy
    test('[18, 3] serves one 2d20', () {
      final roller = FixedDiceRoller([18, 3]);

      final result = roller.roll(twoD20);

      expect(result.expression, twoD20);
      expect(result.rolls, [DieRoll(Die.d20, 18), DieRoll(Die.d20, 3)]);
    });

    /// Requirement: doc/specs/dice-and-rolls.md FR-054 - [18, 3] serves two
    ///   1d20 calls.
    /// Path: happy
    test('[18, 3] serves two 1d20 calls', () {
      final roller = FixedDiceRoller([18, 3]);

      final first = roller.roll(d20);
      final second = roller.roll(d20);

      expect(first.rolls, [DieRoll(Die.d20, 18)]);
      expect(second.rolls, [DieRoll(Die.d20, 3)]);
    });

    /// Requirement: doc/specs/dice-and-rolls.md FR-054 - values continue
    ///   across calls with different expressions, and the modifier is kept.
    /// Path: happy
    test('values continue across calls and expressions', () {
      final roller = FixedDiceRoller([1, 2, 3, 4, 5]);
      final twoD6 = DiceExpression(2, Die.d6);
      final oneD6Plus2 = DiceExpression(1, Die.d6, modifier: 2);

      final first = roller.roll(twoD6);
      final second = roller.roll(oneD6Plus2);
      final third = roller.roll(twoD6);

      expect(first.rolls.map((r) => r.value), [1, 2]);
      expect(second.rolls.map((r) => r.value), [3]);
      expect(second.total, 5);
      expect(third.rolls.map((r) => r.value), [4, 5]);
    });
  });

  /// Requirement: doc/specs/dice-and-rolls.md FR-058 - requests and remaining
  ///   report what the double was asked and what is left.
  /// Path: happy
  group('FixedDiceRoller bookkeeping', () {
    /// Requirement: doc/specs/dice-and-rolls.md FR-058 - requests lists the
    ///   requested expressions in call order.
    /// Path: happy
    test('requests lists the expressions in call order', () {
      final roller = FixedDiceRoller([5, 6, 7]);
      final oneD8 = DiceExpression(1, Die.d8);
      final twoD8 = DiceExpression(2, Die.d8, modifier: 1);

      roller.roll(oneD8);
      roller.roll(twoD8);

      expect(roller.requests, [oneD8, twoD8]);
    });

    /// Requirement: doc/specs/dice-and-rolls.md FR-058 - requests is an
    ///   unmodifiable view; mutating it throws.
    /// Path: unhappy (immutability)
    test('requests cannot be mutated', () {
      final roller = FixedDiceRoller([5]);
      roller.roll(d20);

      expect(() => roller.requests.add(d20), throwsUnsupportedError);
      expect(() => roller.requests.clear(), throwsUnsupportedError);
      expect(roller.requests, [d20]);
    });

    /// Requirement: doc/specs/dice-and-rolls.md FR-058 - remaining counts down
    ///   after each roll.
    /// Path: happy
    test('remaining counts down after each roll', () {
      final roller = FixedDiceRoller([1, 2, 3, 4, 5]);
      expect(roller.remaining, 5);

      roller.roll(DiceExpression(2, Die.d6));
      expect(roller.remaining, 3);

      roller.roll(DiceExpression(1, Die.d6));
      expect(roller.remaining, 2);

      roller.roll(DiceExpression(2, Die.d6));
      expect(roller.remaining, 0);
    });

    /// Requirement: doc/specs/dice-and-rolls.md FR-058 - nothing has been
    ///   requested before the first call.
    /// Path: unhappy (empty and minimal)
    test('requests is empty before any roll', () {
      expect(FixedDiceRoller([1]).requests, isEmpty);
    });

    /// Requirement: doc/specs/dice-and-rolls.md FR-045 - a FixedDiceRoller is a
    ///   DiceRoller.
    /// Path: happy
    test('is a DiceRoller', () {
      expect(FixedDiceRoller([1]), isA<DiceRoller>());
    });
  });

  /// Requirement: doc/specs/dice-and-rolls.md FR-056 - asking for more dice
  ///   than remain is a test set-up bug (StateError) that consumes nothing and
  ///   records nothing (FR-054).
  /// Path: unhappy (state error)
  group('FixedDiceRoller running out of values', () {
    /// Requirement: doc/specs/dice-and-rolls.md FR-056 - a call needing more
    ///   dice than remain throws StateError.
    /// Path: unhappy (state error)
    test('throws StateError when asked for more dice than remain', () {
      final roller = FixedDiceRoller([18]);

      expect(() => roller.roll(twoD20), throwsStateError);
    });

    /// Requirement: doc/specs/dice-and-rolls.md FR-054 and FR-056 - the failed
    ///   call consumes nothing and is not recorded, so a smaller call still
    ///   gets the first value.
    /// Path: unhappy (state error)
    test('a failed call consumes nothing and is not recorded', () {
      final roller = FixedDiceRoller([18]);
      expect(() => roller.roll(twoD20), throwsStateError);

      expect(roller.remaining, 1);
      expect(roller.requests, isEmpty);
      expect(roller.roll(d20).rolls.single.value, 18);
      expect(roller.requests, [d20]);
    });

    /// Requirement: doc/specs/dice-and-rolls.md FR-056 - all values used then
    ///   one more die throws StateError.
    /// Path: unhappy (state error)
    test('throws once every value has been used', () {
      final roller = FixedDiceRoller([18]);
      roller.roll(d20);

      expect(() => roller.roll(d20), throwsStateError);
      expect(roller.remaining, 0);
    });

    /// Requirement: doc/specs/dice-and-rolls.md FR-082 - an empty supply is
    ///   valid, serves nothing and reports 0 remaining.
    /// Path: unhappy (empty and minimal)
    test('an empty list is valid and serves nothing', () {
      final roller = FixedDiceRoller(const []);

      expect(roller.remaining, 0);
      expect(() => roller.roll(d20), throwsStateError);
      expect(roller.requests, isEmpty);
    });
  });

  /// Requirement: doc/specs/dice-and-rolls.md FR-057 - a value outside 1 to
  ///   the die's sides is an ArgumentError naming `values`, found when it is
  ///   consumed, and consumes nothing.
  /// Path: unhappy (invalid input)
  group('FixedDiceRoller invalid values', () {
    /// Requirement: doc/specs/dice-and-rolls.md FR-057 and FR-077 - 21 on a d20
    ///   is rejected with name and the offending value.
    /// Path: unhappy (invalid input)
    test('21 on a d20 is rejected', () {
      final roller = FixedDiceRoller([21]);

      expect(() => roller.roll(d20), throwsArgumentErrorFor('values', 21));
    });

    /// Requirement: doc/specs/dice-and-rolls.md FR-057 - zero and a negative
    ///   value are rejected.
    /// Path: unhappy (boundary)
    test('0 and -1 are rejected', () {
      expect(
        () => FixedDiceRoller([0]).roll(d20),
        throwsArgumentErrorFor('values', 0),
      );
      expect(
        () => FixedDiceRoller([-1]).roll(d20),
        throwsArgumentErrorFor('values', -1),
      );
    });

    /// Requirement: doc/specs/dice-and-rolls.md FR-057 - the bounds 1 and the
    ///   die's sides are accepted.
    /// Path: unhappy (boundary)
    test('1 and the highest face are accepted', () {
      final roller = FixedDiceRoller([1, 20]);

      expect(roller.roll(twoD20).total, 21);
    });

    /// Requirement: doc/specs/dice-and-rolls.md FR-057 and FR-054 - the
    ///   offending value is the one reported even when it is not the first,
    ///   and the failed call consumes nothing and is not recorded.
    /// Path: unhappy (invalid input)
    test('an offending later value is reported and nothing is consumed', () {
      final roller = FixedDiceRoller([5, 21, 7]);

      expect(() => roller.roll(twoD20), throwsArgumentErrorFor('values', 21));
      expect(roller.remaining, 3);
      expect(roller.requests, isEmpty);
    });

    /// Requirement: doc/specs/dice-and-rolls.md FR-057 - validity is judged
    ///   against the requested die, so the same value can be right for one
    ///   expression and wrong for another.
    /// Path: unhappy (rule interaction)
    test('the same value is judged against the requested die', () {
      expect(FixedDiceRoller([7]).roll(DiceExpression(1, Die.d8)).total, 7);
      expect(
        () => FixedDiceRoller([7]).roll(DiceExpression(1, Die.d6)),
        throwsArgumentErrorFor('values', 7),
      );
    });
  });

  /// Requirement: doc/specs/dice-and-rolls.md FR-082 - the values are copied;
  ///   the constructor does not validate them.
  /// Path: unhappy (immutability)
  group('FixedDiceRoller copies its values', () {
    /// Requirement: doc/specs/dice-and-rolls.md FR-082 - mutating the original
    ///   list after construction does not change later rolls.
    /// Path: unhappy (immutability)
    test('editing the source list does not change later rolls', () {
      final source = [18, 3];
      final roller = FixedDiceRoller(source);

      source[0] = 1;
      source.add(7);

      expect(roller.remaining, 2);
      expect(roller.roll(twoD20).rolls.map((r) => r.value), [18, 3]);
    });

    /// Requirement: doc/specs/dice-and-rolls.md FR-082 - the constructor does
    ///   not validate; roll validates each value it consumes.
    /// Path: unhappy (invalid input)
    test('an out-of-range value is accepted by the constructor', () {
      final roller = FixedDiceRoller([99, 3]);

      expect(roller.remaining, 2);
      expect(() => roller.roll(d20), throwsArgumentErrorFor('values', 99));
    });
  });

  /// Requirement: per case - doc/specs/dice-and-rolls.md FR-055 and FR-083 - minimum()
  ///   and maximum() roll the extremes with an unbounded supply.
  /// Path: per case
  group('FixedDiceRoller extremes', () {
    /// Requirement: per case
    /// Path: per case
    for (final c in _extremes) {
      test('minimum() rolls 1 on every die: ${c.label} [${c.path}]', () {
        final roller = FixedDiceRoller.minimum();

        final result = roller.roll(c.expression);

        expect(result.expression, c.expression);
        expect(result.rolls.map((r) => r.value), c.minimumFaces);
        expect(result.total, c.expression.minimum);
      });

      test('maximum() rolls the highest face: ${c.label} [${c.path}]', () {
        final roller = FixedDiceRoller.maximum();

        final result = roller.roll(c.expression);

        expect(result.expression, c.expression);
        expect(result.rolls.map((r) => r.value), c.maximumFaces);
        expect(result.total, c.expression.maximum);
      });
    }

    /// Requirement: doc/specs/dice-and-rolls.md FR-083 - remaining is null for
    ///   both, they never throw StateError, and requests lists every call.
    /// Path: unhappy (boundary)
    test('supply is unbounded and every request is recorded', () {
      for (final roller in [
        FixedDiceRoller.minimum(),
        FixedDiceRoller.maximum(),
      ]) {
        expect(roller.remaining, isNull);

        for (var i = 0; i < 50; i++) {
          roller.roll(twoD20);
        }

        expect(roller.remaining, isNull);
        expect(roller.requests, List.filled(50, twoD20));
      }
    });
  });
}
