import 'package:srd5e/src/shared_kernel/dice/dice_expression.dart';
import 'package:srd5e/src/shared_kernel/dice/die.dart';
import 'package:srd5e/src/shared_kernel/dice/die_roll.dart';
import 'package:srd5e/src/shared_kernel/dice/roll_result.dart';
import 'package:test/test.dart';

import '../../support/argument_error_matcher.dart';

/// Builds the rolls of [expression] showing [faces], in order.
List<DieRoll> _rolls(DiceExpression expression, List<int> faces) => [
  for (final face in faces) DieRoll(expression.die, face),
];

/// Builds a result for [expression] showing [faces].
RollResult _result(DiceExpression expression, List<int> faces) =>
    RollResult(expression, _rolls(expression, faces));

typedef _TotalCase = ({
  String label,
  String requirement,
  String path,
  DiceExpression expression,
  List<int> faces,
  int diceTotal,
  int total,
});

/// Case table for FR-036 and FR-038.
final List<_TotalCase> _totals = [
  (
    label: 'two d8 plus 2',
    requirement: 'SRD 5.2.1, "Hit Points", p. 255',
    path: 'happy',
    expression: DiceExpression(2, Die.d8, modifier: 2),
    faces: [3, 6],
    diceTotal: 9,
    total: 11,
  ),
  (
    label: 'natural 20',
    requirement: 'SRD 5.2.1, "D20 Tests", p. 6',
    path: 'happy',
    expression: DiceExpression(1, Die.d20),
    faces: [20],
    diceTotal: 20,
    total: 20,
  ),
  (
    label: 'natural 1',
    requirement: 'SRD 5.2.1, "D20 Tests", p. 6',
    path: 'unhappy (boundary)',
    expression: DiceExpression(1, Die.d20),
    faces: [1],
    diceTotal: 1,
    total: 1,
  ),
  (
    label: 'd4 plus 2 high',
    requirement: 'SRD 5.2.1, "Damage Notation", p. 257',
    path: 'happy',
    expression: DiceExpression(1, Die.d4, modifier: 2),
    faces: [4],
    diceTotal: 4,
    total: 6,
  ),
  (
    label: 'four d6',
    requirement: 'arithmetic; SRD 5.2.1, "Random Generation", p. 21',
    path: 'happy',
    expression: DiceExpression(4, Die.d6),
    faces: [6, 5, 4, 1],
    diceTotal: 16,
    total: 16,
  ),
  (
    label: 'negative total',
    requirement: 'SRD 5.2.1, "Damage Rolls", p. 16 (no clamp here)',
    path: 'unhappy (boundary)',
    expression: DiceExpression(1, Die.d4, modifier: -5),
    faces: [1],
    diceTotal: 1,
    total: -4,
  ),
  (
    label: 'zero total',
    requirement: 'SRD 5.2.1, "Damage Rolls", p. 16 (no clamp here)',
    path: 'unhappy (boundary)',
    expression: DiceExpression(1, Die.d4, modifier: -3),
    faces: [3],
    diceTotal: 3,
    total: 0,
  ),
];

typedef _SelectCase = ({
  String label,
  String requirement,
  String path,
  DiceExpression expression,
  List<int> faces,
  bool highest,
  int n,
  int? result,
});

/// Case table for FR-041, FR-042 and FR-043. A null result means ArgumentError.
final List<_SelectCase> _selections = [
  (
    label: 'keep the higher of two d20s',
    requirement: 'SRD 5.2.1, "Roll Two D20s", p. 8',
    path: 'happy',
    expression: DiceExpression(2, Die.d20),
    faces: [18, 3],
    highest: true,
    n: 1,
    result: 18,
  ),
  (
    label: 'keep the lower of two d20s',
    requirement: 'SRD 5.2.1, "Roll Two D20s", p. 8',
    path: 'happy',
    expression: DiceExpression(2, Die.d20),
    faces: [18, 3],
    highest: false,
    n: 1,
    result: 3,
  ),
  (
    label: 'highest three of four d6',
    requirement: 'SRD 5.2.1, "Random Generation", p. 21',
    path: 'happy',
    expression: DiceExpression(4, Die.d6),
    faces: [6, 5, 4, 1],
    highest: true,
    n: 3,
    result: 15,
  ),
  (
    label: 'order does not matter',
    requirement: 'SRD 5.2.1, "Random Generation", p. 21',
    path: 'happy',
    expression: DiceExpression(4, Die.d6),
    faces: [1, 4, 6, 5],
    highest: true,
    n: 3,
    result: 15,
  ),
  (
    label: 'all dice equal',
    requirement: 'SRD 5.2.1, "Random Generation", p. 21',
    path: 'unhappy (boundary)',
    expression: DiceExpression(4, Die.d6),
    faces: [1, 1, 1, 1],
    highest: true,
    n: 3,
    result: 3,
  ),
  (
    label: 'ties at the cut',
    requirement: 'SRD 5.2.1, "Random Generation", p. 21',
    path: 'unhappy (boundary)',
    expression: DiceExpression(4, Die.d6),
    faces: [3, 3, 3, 2],
    highest: true,
    n: 3,
    result: 9,
  ),
  (
    label: 'two lowest',
    requirement: 'package design (pp. 6 and 8 cover the lower of two d20s)',
    path: 'happy',
    expression: DiceExpression(4, Die.d6),
    faces: [6, 1, 6, 1],
    highest: false,
    n: 2,
    result: 2,
  ),
  (
    label: 'modifier ignored',
    requirement: 'SRD 5.2.1, "Roll Two D20s", p. 8',
    path: 'unhappy (rule interaction)',
    expression: DiceExpression(2, Die.d20, modifier: 5),
    faces: [18, 3],
    highest: true,
    n: 1,
    result: 18,
  ),
  (
    label: 'modifier ignored for the lowest',
    requirement: 'SRD 5.2.1, "Roll Two D20s", p. 8',
    path: 'unhappy (rule interaction)',
    expression: DiceExpression(2, Die.d20, modifier: -5),
    faces: [18, 3],
    highest: false,
    n: 1,
    result: 3,
  ),
  (
    label: 'n equals count for the highest',
    requirement: 'SRD 5.2.1, "Random Generation", p. 21',
    path: 'unhappy (boundary)',
    expression: DiceExpression(4, Die.d6),
    faces: [6, 5, 4, 1],
    highest: true,
    n: 4,
    result: 16,
  ),
  (
    label: 'n equals count for the lowest',
    requirement: 'doc/specs/dice-and-rolls.md FR-043 (package design)',
    path: 'unhappy (boundary)',
    expression: DiceExpression(4, Die.d6),
    faces: [6, 5, 4, 1],
    highest: false,
    n: 4,
    result: 16,
  ),
  (
    label: 'n is zero',
    requirement: 'doc/specs/dice-and-rolls.md FR-043 (invalid input)',
    path: 'unhappy (boundary)',
    expression: DiceExpression(4, Die.d6),
    faces: [6, 5, 4, 1],
    highest: true,
    n: 0,
    result: null,
  ),
  (
    label: 'n above count for the lowest',
    requirement: 'doc/specs/dice-and-rolls.md FR-043 (invalid input)',
    path: 'unhappy (boundary)',
    expression: DiceExpression(4, Die.d6),
    faces: [6, 5, 4, 1],
    highest: false,
    n: 5,
    result: null,
  ),
  (
    label: 'n above count for the highest',
    requirement: 'doc/specs/dice-and-rolls.md FR-043 (invalid input)',
    path: 'unhappy (boundary)',
    expression: DiceExpression(4, Die.d6),
    faces: [6, 5, 4, 1],
    highest: true,
    n: 5,
    result: null,
  ),
  (
    label: 'n negative',
    requirement: 'doc/specs/dice-and-rolls.md FR-043 (invalid input)',
    path: 'unhappy (invalid input)',
    expression: DiceExpression(4, Die.d6),
    faces: [6, 5, 4, 1],
    highest: false,
    n: -1,
    result: null,
  ),
  (
    label: 'n negative for the highest',
    requirement: 'doc/specs/dice-and-rolls.md FR-043 (invalid input)',
    path: 'unhappy (invalid input)',
    expression: DiceExpression(4, Die.d6),
    faces: [6, 5, 4, 1],
    highest: true,
    n: -1,
    result: null,
  ),
];

void main() {
  /// Requirement: doc/specs/dice-and-rolls.md FR-033 - a RollResult is the
  ///   expression and one roll per die (SRD 5.2.1, "Damage Rolls", p. 16).
  /// Path: happy
  group('RollResult construction', () {
    /// Requirement: doc/specs/dice-and-rolls.md FR-033 - exactly count rolls of
    ///   the expression's die are accepted, in the order given, with the
    ///   expression's modifier exposed.
    /// Path: happy
    test('exposes expression, rolls in order and modifier', () {
      final expression = DiceExpression(2, Die.d8, modifier: 2);
      final rolls = _rolls(expression, [3, 6]);

      final result = RollResult(expression, rolls);

      expect(result.expression, expression);
      expect(result.rolls, [DieRoll(Die.d8, 3), DieRoll(Die.d8, 6)]);
      expect(result.modifier, 2);
    });

    /// Requirement: doc/specs/dice-and-rolls.md FR-034 and FR-077 - no rolls,
    ///   one fewer and one more than the count are rejected with name and
    ///   value.
    /// Path: unhappy (invalid input)
    test('a wrong number of rolls is rejected', () {
      final expression = DiceExpression(3, Die.d6);
      final none = <DieRoll>[];
      final oneFewer = _rolls(expression, [1, 2]);
      final oneMore = _rolls(expression, [1, 2, 3, 4]);

      expect(
        () => RollResult(expression, none),
        throwsArgumentErrorFor('rolls', none),
      );
      expect(
        () => RollResult(expression, oneFewer),
        throwsArgumentErrorFor('rolls', oneFewer),
      );
      expect(
        () => RollResult(expression, oneMore),
        throwsArgumentErrorFor('rolls', oneMore),
      );
    });

    /// Requirement: doc/specs/dice-and-rolls.md FR-035 and FR-077 - a roll of
    ///   a different die is rejected with name and value.
    /// Path: unhappy (invalid input)
    test('a roll of another die is rejected', () {
      final expression = DiceExpression(2, Die.d6);
      final mixed = [DieRoll(Die.d6, 2), DieRoll(Die.d8, 2)];

      expect(
        () => RollResult(expression, mixed),
        throwsArgumentErrorFor('rolls', mixed),
      );
    });
  });

  /// Requirement: per case - doc/specs/dice-and-rolls.md FR-036 and FR-038
  ///   (diceTotal and total, including negative and zero totals unclamped).
  /// Path: per case
  group('totals', () {
    for (final c in _totals) {
      test('${c.label} [${c.path}]', () {
        final result = _result(c.expression, c.faces);

        expect(result.diceTotal, c.diceTotal, reason: 'diceTotal');
        expect(result.total, c.total, reason: 'total');
      });
    }
  });

  /// Requirement: doc/specs/dice-and-rolls.md FR-037 - every die at 1 gives
  ///   the expression's minimum, every die at its highest face gives its
  ///   maximum (consistency of FR-010, FR-011 and FR-036).
  /// Path: unhappy (boundary)
  group('extremes', () {
    final expressions = [
      DiceExpression(1, Die.d20),
      DiceExpression(2, Die.d8, modifier: 2),
      DiceExpression(4, Die.d6),
      DiceExpression(3, Die.d6, modifier: -3),
      DiceExpression(1, Die(2), modifier: -1000000),
    ];

    /// Requirement: per case
    /// Path: per case
    for (final expression in expressions) {
      test('${expression.notation} at its extremes [unhappy (boundary)]', () {
        final lowest = _result(expression, List.filled(expression.count, 1));
        final highest = _result(
          expression,
          List.filled(expression.count, expression.die.sides),
        );

        expect(lowest.total, expression.minimum);
        expect(highest.total, expression.maximum);
      });
    }
  });

  /// Requirement: doc/specs/dice-and-rolls.md FR-039 and FR-040 - a result is
  ///   immutable and copies the list it is given (`architecture.md` §4).
  /// Path: unhappy (immutability)
  group('immutability', () {
    /// Requirement: doc/specs/dice-and-rolls.md FR-039 - rolls is an
    ///   unmodifiable view; adding, removing and replacing throw.
    /// Path: unhappy (immutability)
    test('rolls cannot be mutated', () {
      final expression = DiceExpression(2, Die.d6);
      final result = _result(expression, [1, 2]);

      expect(
        () => result.rolls.add(DieRoll(Die.d6, 3)),
        throwsUnsupportedError,
      );
      expect(() => result.rolls.removeLast(), throwsUnsupportedError);
      expect(
        () => result.rolls[0] = DieRoll(Die.d6, 6),
        throwsUnsupportedError,
      );
      expect(() => result.rolls.clear(), throwsUnsupportedError);
      expect(result.rolls, [DieRoll(Die.d6, 1), DieRoll(Die.d6, 2)]);
    });

    /// Requirement: doc/specs/dice-and-rolls.md FR-040 - editing the source
    ///   list after construction does not change the result.
    /// Path: unhappy (immutability)
    test('the list given is copied', () {
      final expression = DiceExpression(2, Die.d6);
      final source = _rolls(expression, [1, 2]);
      final result = RollResult(expression, source);

      source[0] = DieRoll(Die.d6, 6);
      source.add(DieRoll(Die.d6, 6));

      expect(result.rolls, [DieRoll(Die.d6, 1), DieRoll(Die.d6, 2)]);
      expect(result.total, 3);
    });
  });

  /// Requirement: per case - doc/specs/dice-and-rolls.md FR-041, FR-042 and
  ///   FR-043 (selection sums, and ArgumentError for n out of range).
  /// Path: per case
  group('sumOfHighest and sumOfLowest', () {
    for (final c in _selections) {
      test('${c.label}: ${c.highest ? 'sumOfHighest' : 'sumOfLowest'}(${c.n}) '
          '[${c.path}]', () {
        final result = _result(c.expression, c.faces);
        final before = List<DieRoll>.of(result.rolls);

        int select() =>
            c.highest ? result.sumOfHighest(c.n) : result.sumOfLowest(c.n);

        final expected = c.result;
        if (expected == null) {
          expect(select, throwsArgumentErrorFor('n', c.n));
        } else {
          expect(select(), expected);
        }
        expect(result.rolls, before, reason: 'rolls are left unchanged');
      });
    }

    /// Requirement: doc/specs/dice-and-rolls.md FR-043 - with n equal to the
    ///   count both selections equal diceTotal.
    /// Path: unhappy (boundary)
    test('n equal to the count equals diceTotal', () {
      final result = _result(DiceExpression(4, Die.d6, modifier: 3), [
        6,
        5,
        4,
        1,
      ]);

      expect(result.sumOfHighest(4), result.diceTotal);
      expect(result.sumOfLowest(4), result.diceTotal);
    });
  });

  /// Requirement: doc/specs/dice-and-rolls.md FR-044 - a value object compared
  ///   by expression and rolls in the same order.
  /// Path: happy
  group('RollResult equality', () {
    /// Requirement: doc/specs/dice-and-rolls.md FR-044 - equal expression and
    ///   rolls in order give equal results with equal hash codes.
    /// Path: happy
    test('same expression and rolls are equal with equal hash codes', () {
      final expression = DiceExpression(2, Die.d6, modifier: 1);

      final first = _result(expression, [2, 5]);
      final second = _result(expression, [2, 5]);

      expect(identical(first, second), isFalse);
      expect(first, second);
      expect(first.hashCode, second.hashCode);
    });

    /// Requirement: doc/specs/dice-and-rolls.md FR-044 - a different order,
    ///   face or expression makes results unequal.
    /// Path: unhappy (boundary)
    test('a different order, face or expression is unequal', () {
      final expression = DiceExpression(2, Die.d6, modifier: 1);
      final base = _result(expression, [2, 5]);

      expect(base == _result(expression, [5, 2]), isFalse);
      expect(base == _result(expression, [2, 4]), isFalse);
      expect(
        base == _result(DiceExpression(2, Die.d6, modifier: 2), [2, 5]),
        isFalse,
      );
      const Object notAResult = 7;
      expect(base == notAResult, isFalse);
    });

    /// Requirement: doc/specs/dice-and-rolls.md FR-044 - the debugging form
    ///   lists the expression and the faces (not display text).
    /// Path: happy
    test('toString lists the expression and faces', () {
      final result = _result(DiceExpression(2, Die.d8, modifier: 2), [3, 6]);

      expect(result.toString(), '2d8+2 [d8=3, d8=6]');
    });
  });

  /// Requirement: doc/specs/dice-and-rolls.md FR-073 - tryCreate returns a
  ///   created result or a typed rejection, agreeing with the constructor.
  /// Path: unhappy (invalid input)
  group('RollResult.tryCreate', () {
    final expression = DiceExpression(2, Die.d6);

    /// Requirement: doc/specs/dice-and-rolls.md FR-073 - an input the
    ///   constructor accepts is created.
    /// Path: happy
    test('creates a result for valid rolls', () {
      final rolls = _rolls(expression, [1, 6]);

      final creation = RollResult.tryCreate(expression, rolls);

      expect(creation, CreatedRollResult(RollResult(expression, rolls)));
    });

    /// Requirement: doc/specs/dice-and-rolls.md FR-073 - the wrong number of
    ///   rolls is rollCountMismatch.
    /// Path: unhappy (invalid input)
    test('rejects a wrong number of rolls', () {
      final creation = RollResult.tryCreate(
        expression,
        _rolls(expression, [1]),
      );

      expect(
        creation,
        const RejectedRollResult(RollResultRejection.rollCountMismatch),
      );
    });

    /// Requirement: doc/specs/dice-and-rolls.md FR-073 - a roll of another die
    ///   is dieMismatch.
    /// Path: unhappy (invalid input)
    test('rejects a roll of another die', () {
      final creation = RollResult.tryCreate(expression, [
        DieRoll(Die.d6, 1),
        DieRoll(Die.d4, 1),
      ]);

      expect(
        creation,
        const RejectedRollResult(RollResultRejection.dieMismatch),
      );
    });

    /// Requirement: doc/specs/dice-and-rolls.md FR-073 - the count is checked
    ///   before the die.
    /// Path: unhappy (rule conflict)
    test('reports the count before the die when both are wrong', () {
      final creation = RollResult.tryCreate(expression, [DieRoll(Die.d4, 1)]);

      expect(
        creation,
        const RejectedRollResult(RollResultRejection.rollCountMismatch),
      );
    });

    /// Requirement: doc/specs/dice-and-rolls.md FR-073 and FR-040 - the list is
    ///   copied and the input is not mutated.
    /// Path: unhappy (immutability)
    test('copies the list and leaves the input unchanged', () {
      final source = _rolls(expression, [1, 2]);
      final creation = RollResult.tryCreate(expression, source);

      source[0] = DieRoll(Die.d6, 6);

      final result = (creation as CreatedRollResult).value;
      expect(result.rolls, [DieRoll(Die.d6, 1), DieRoll(Die.d6, 2)]);
      expect(source, [DieRoll(Die.d6, 6), DieRoll(Die.d6, 2)]);
      expect(
        () => result.rolls.add(DieRoll(Die.d6, 1)),
        throwsUnsupportedError,
      );
    });

    /// Requirement: doc/specs/dice-and-rolls.md FR-074 - tryCreate rejects if
    ///   and only if the constructor throws ArgumentError.
    /// Path: unhappy (rule conflict)
    test('rejects exactly the inputs the constructor throws for', () {
      final inputs = <List<DieRoll>>[
        _rolls(expression, [1, 2]),
        _rolls(expression, [6, 6]),
        <DieRoll>[],
        _rolls(expression, [1]),
        [DieRoll(Die.d6, 1), DieRoll(Die.d4, 1)],
        [DieRoll(Die.d6, 1), DieRoll(Die.d6, 2), DieRoll(Die.d6, 3)],
      ];

      for (final rolls in inputs) {
        final rejected =
            RollResult.tryCreate(expression, rolls) is RejectedRollResult;
        var thrown = false;
        try {
          RollResult(expression, rolls);
        } on ArgumentError {
          thrown = true;
        }

        expect(rejected, thrown, reason: '$rolls');
      }
    });

    /// Requirement: doc/specs/dice-and-rolls.md FR-075 - the result is sealed
    ///   with final variants carrying the value or the typed reason.
    /// Path: unhappy (invalid input)
    test('the result is switched over exhaustively', () {
      String describe(RollResultCreation creation) => switch (creation) {
        CreatedRollResult(:final value) => 'created ${value.total}',
        RejectedRollResult(:final reason) => 'rejected ${reason.name}',
      };

      expect(
        describe(RollResult.tryCreate(expression, _rolls(expression, [2, 3]))),
        'created 5',
      );
      expect(
        describe(RollResult.tryCreate(expression, const [])),
        'rejected rollCountMismatch',
      );
    });

    /// Requirement: doc/specs/dice-and-rolls.md FR-073 - the variants compare
    ///   by value.
    /// Path: unhappy (boundary)
    test('variants compare by value', () {
      final created = RollResult.tryCreate(
        expression,
        _rolls(expression, [2, 3]),
      );
      final createdAgain = RollResult.tryCreate(
        expression,
        _rolls(expression, [2, 3]),
      );
      final createdOther = RollResult.tryCreate(
        expression,
        _rolls(expression, [3, 2]),
      );
      final rejected = RollResult.tryCreate(expression, const []);
      final rejectedAgain = RollResult.tryCreate(expression, const []);
      final rejectedOther = RollResult.tryCreate(expression, [
        DieRoll(Die.d6, 1),
        DieRoll(Die.d4, 1),
      ]);

      expect(created, createdAgain);
      expect(created.hashCode, createdAgain.hashCode);
      expect(created == createdOther, isFalse);
      expect(rejected, rejectedAgain);
      expect(rejected.hashCode, rejectedAgain.hashCode);
      expect(rejected == rejectedOther, isFalse);
      expect(created == rejected, isFalse);
    });
  });

  /// Requirement: doc/specs/dice-and-rolls.md FR-073 and FR-075 - the creation
  ///   variants have a debugging form that names the value or the typed reason.
  /// Path: happy
  test('the creation variants have a debugging form', () {
    final expression = DiceExpression(2, Die.d6);

    expect(
      RollResult.tryCreate(expression, _rolls(expression, [2, 3])).toString(),
      'CreatedRollResult(2d6 [d6=2, d6=3])',
    );
    expect(
      RollResult.tryCreate(expression, const []).toString(),
      'RejectedRollResult(rollCountMismatch)',
    );
  });
}
