import 'package:srd5e/src/shared_kernel/dice/dice_expression.dart';
import 'package:srd5e/src/shared_kernel/dice/die.dart';
import 'package:srd5e/src/shared_kernel/dice/roll_result.dart';
import 'package:srd5e/src/shared_ports/dice_roller/dice_roller.dart';
import 'package:srd5e/src/shared_ports/dice_roller/dice_roller_exception.dart';
import 'package:test/test.dart';

/// Builds a [DiceRoller] whose backend throws [cause] with [stackTrace] when
/// asked to roll.
///
/// For `SeededDiceRoller` this is a `Random` whose `nextInt` throws the
/// exception. A consumer's adapter supplies whatever makes its own backend
/// fail with that exception.
typedef FailingDiceRollerFactory =
    DiceRoller Function(Exception cause, StackTrace stackTrace);

typedef ContractExpressionCase = ({String label, DiceExpression expression});

/// The expressions every implementation must roll within the contract.
final List<ContractExpressionCase> contractExpressions = [
  (label: 'one d20', expression: DiceExpression(1, Die.d20)),
  (label: 'two d8 plus 2', expression: DiceExpression(2, Die.d8, modifier: 2)),
  (label: 'four d6', expression: DiceExpression(4, Die.d6)),
  (label: 'one d3', expression: DiceExpression(1, Die.d3)),
  (label: 'one d100', expression: DiceExpression(1, Die.d100)),
  (
    label: 'negative total',
    expression: DiceExpression(1, Die.d4, modifier: -5),
  ),
  (label: 'smallest die', expression: DiceExpression(3, Die(2))),
  (
    label: 'largest expression',
    expression: DiceExpression(1000, Die(1000), modifier: 1000000),
  ),
];

/// Asserts that [roller] honours the roll half of the `DiceRoller` contract
/// for [expression] (`doc/specs/dice-and-rolls.md` FR-046 and FR-047): the
/// result is for the requested expression, has exactly `count` rolls of the
/// requested die, each within 1 to the sides, and a total between the
/// expression's minimum and maximum.
void expectHonoursRollContract(DiceRoller roller, DiceExpression expression) {
  final RollResult result = roller.roll(expression);

  expect(result.expression, expression, reason: 'FR-046: same expression');
  expect(result.rolls, hasLength(expression.count), reason: 'FR-047: count');
  for (final roll in result.rolls) {
    expect(roll.die, expression.die, reason: 'FR-047: the requested die');
    expect(roll.value, inInclusiveRange(1, expression.die.sides));
  }
  expect(
    result.total,
    inInclusiveRange(expression.minimum, expression.maximum),
    reason: 'FR-047: total within minimum and maximum',
  );
}

/// Asserts that the roller built by [failingVariant] wraps a backend
/// `Exception` as the port's typed failure (`doc/specs/dice-and-rolls.md`
/// FR-048): a [DiceRollerException] with the reason `unavailable`, the
/// requested expression, the identical `cause` and `causeStackTrace`, and the
/// constant `errorType`. It must throw rather than return a partial or default
/// result, and must not leak the raw backend exception.
void expectWrapsBackendFailure(
  FailingDiceRollerFactory failingVariant,
  DiceExpression expression,
) {
  const cause = FormatException('backend failure');
  final stackTrace = StackTrace.fromString('backend stack trace');
  final roller = failingVariant(cause, stackTrace);

  Object? thrown;
  RollResult? returned;
  try {
    returned = roller.roll(expression);
  } on Object catch (e) {
    thrown = e;
  }

  expect(
    returned,
    isNull,
    reason: 'FR-048: no partial or default result, got $returned',
  );
  expect(
    thrown,
    isA<DiceRollerException>(),
    reason: 'FR-048: no raw leak, got $thrown',
  );
  final failure = thrown! as DiceRollerException;
  expect(failure.reason, DiceRollerFailureReason.unavailable);
  expect(failure.expression, expression);
  expect(failure.cause, same(cause), reason: 'FR-048: the identical cause');
  expect(
    failure.causeStackTrace,
    same(stackTrace),
    reason: 'FR-048: the identical stack trace',
  );
  expect(failure.errorType, 'dice_roller_exception');
}

/// Registers the shared `DiceRoller` contract suite
/// (`doc/specs/dice-and-rolls.md` section 6) against the implementation that
/// [create] builds.
///
/// [create] must return a fresh roller each time. Pass [failingVariant] for an
/// implementation whose backend can fail; the FR-048 cases run only then.
///
/// The suite is not exported by the package (it needs `package:test`); copy it
/// to run against your own adapter.
void diceRollerContract(
  String name,
  DiceRoller Function() create, {
  FailingDiceRollerFactory? failingVariant,
}) {
  /// Requirement: doc/specs/dice-and-rolls.md FR-045, FR-046, FR-047
  ///   and FR-048 - the DiceRoller port contract holds for this
  ///   implementation.
  /// Path: happy
  group('DiceRoller contract: $name', () {
    /// Requirement: doc/specs/dice-and-rolls.md FR-045 - the port is one
    ///   synchronous method returning a RollResult (checked by the typed
    ///   assignment, which fails to compile otherwise).
    /// Path: happy
    test('roll is synchronous and returns a RollResult', () {
      final DiceRoller roller = create();
      final RollResult Function(DiceExpression) roll = roller.roll;

      final result = roll(DiceExpression(1, Die.d20));

      expect(result, isA<RollResult>());
    });

    /// Requirement: per case
    /// Path: per case
    for (final c in contractExpressions) {
      test('FR-046/FR-047: ${c.label} [happy]', () {
        expectHonoursRollContract(create(), c.expression);
      });
    }

    /// Requirement: doc/specs/dice-and-rolls.md FR-046 - a roller can be
    ///   called again and again, each result for the expression requested.
    /// Path: happy
    test('FR-046: successive calls each answer their own expression', () {
      final roller = create();
      final first = DiceExpression(2, Die.d6);
      final second = DiceExpression(1, Die.d20, modifier: 3);

      expect(roller.roll(first).expression, first);
      expect(roller.roll(second).expression, second);
      expect(roller.roll(first).expression, first);
    });

    final failing = failingVariant;
    if (failing != null) {
      /// Requirement: doc/specs/dice-and-rolls.md FR-048 - a backend Exception
      ///   surfaces as DiceRollerException(unavailable) with the identical
      ///   cause and stack trace, never a raw leak or a partial result.
      /// Path: unhappy (failure)
      group('backend failure', () {
        /// Requirement: per case
        /// Path: per case
        for (final c in contractExpressions) {
          test('FR-048: ${c.label} [unhappy (failure)]', () {
            expectWrapsBackendFailure(failing, c.expression);
          });
        }
      });
    }
  });
}
