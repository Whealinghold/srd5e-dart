import 'dart:math';

import 'package:srd5e/adapters.dart';
import 'package:srd5e/srd5e.dart';
import 'package:srd5e/testing.dart';
import 'package:test/test.dart';

/// Every type exported by `doc/specs/dice-and-rolls.md` FR-067 from
/// `package:srd5e/srd5e.dart`, referenced by name. A name that is not exported
/// does not compile; a renamed type fails the key comparison.
final Map<String, Type> _coreTypes = {
  'Die': Die,
  'DiceExpression': DiceExpression,
  'DieRoll': DieRoll,
  'RollResult': RollResult,
  'DiceExpressionParse': DiceExpressionParse,
  'ParsedDiceExpression': ParsedDiceExpression,
  'RejectedDiceExpression': RejectedDiceExpression,
  'DieCreation': DieCreation,
  'DiceExpressionCreation': DiceExpressionCreation,
  'DieRollCreation': DieRollCreation,
  'RollResultCreation': RollResultCreation,
  'CreatedDie': CreatedDie,
  'RejectedDie': RejectedDie,
  'CreatedDiceExpression': CreatedDiceExpression,
  'RejectedDiceExpressionInput': RejectedDiceExpressionInput,
  'CreatedDieRoll': CreatedDieRoll,
  'RejectedDieRoll': RejectedDieRoll,
  'CreatedRollResult': CreatedRollResult,
  'RejectedRollResult': RejectedRollResult,
  'DiceExpressionRejection': DiceExpressionRejection,
  'DieRejection': DieRejection,
  'DieRollRejection': DieRollRejection,
  'RollResultRejection': RollResultRejection,
  'DiceRoller': DiceRoller,
  'DiceRollerException': DiceRollerException,
  'DiceRollerFailureReason': DiceRollerFailureReason,
};

void main() {
  /// Requirement: doc/specs/dice-and-rolls.md FR-067 and FR-076 - srd5e.dart
  ///   exports every name of the single export list (26 types here; the
  ///   extension `DiceRollerChecked` is exercised separately).
  /// Path: happy
  test('srd5e.dart exports every type on the FR-067 list', () {
    for (final entry in _coreTypes.entries) {
      expect(entry.value.toString(), entry.key);
    }
    expect(_coreTypes, hasLength(26));
  });

  /// Requirement: doc/specs/dice-and-rolls.md FR-067 - the extension
  ///   DiceRollerChecked is exported: rollChecked is callable on any
  ///   DiceRoller using only the public entry points.
  /// Path: happy
  test('srd5e.dart exports the extension DiceRollerChecked', () {
    final DiceRoller roller = FixedDiceRoller([4]);

    final result = roller.rollChecked(DiceExpression(1, Die.d6));

    expect(result.total, 4);
  });

  /// Requirement: doc/specs/dice-and-rolls.md FR-067 - adapters.dart exports
  ///   SeededDiceRoller and testing.dart exports both doubles; each is a
  ///   DiceRoller.
  /// Path: happy
  test('adapters.dart and testing.dart export the roller and doubles', () {
    final rollers = <String, DiceRoller>{
      'SeededDiceRoller': SeededDiceRoller(Random(7)),
      'FixedDiceRoller': FixedDiceRoller([1]),
      'CallbackDiceRoller': CallbackDiceRoller(
        (e) => FixedDiceRoller.minimum().roll(e),
      ),
    };

    for (final entry in rollers.entries) {
      expect(entry.value.runtimeType.toString(), entry.key);
    }
  });

  /// Requirement: doc/specs/dice-and-rolls.md FR-085 - no generic variant name
  ///   is exported by this spec; every sealed variant is prefixed with its
  ///   type or operation.
  /// Path: unhappy (name collision)
  test('no generic variant name is exported', () {
    const generic = {'Created', 'Rejected', 'Parsed', 'Applied', 'Succeeded'};

    expect(_coreTypes.keys.toSet().intersection(generic), isEmpty);
  });

  /// Requirement: doc/specs/dice-and-rolls.md FR-075 and FR-076 - the three
  ///   creation results and the parse result are sealed, so a consumer's
  ///   switch needs no default branch (checked by the analyzer).
  /// Path: unhappy (invalid input)
  test('the sealed results are switched over exhaustively', () {
    String die(DieCreation c) => switch (c) {
      CreatedDie() => 'created',
      RejectedDie() => 'rejected',
    };
    String expression(DiceExpressionCreation c) => switch (c) {
      CreatedDiceExpression() => 'created',
      RejectedDiceExpressionInput() => 'rejected',
    };
    String parse(DiceExpressionParse c) => switch (c) {
      ParsedDiceExpression() => 'parsed',
      RejectedDiceExpression() => 'rejected',
    };
    String roll(DieRollCreation c) => switch (c) {
      CreatedDieRoll() => 'created',
      RejectedDieRoll() => 'rejected',
    };
    String result(RollResultCreation c) => switch (c) {
      CreatedRollResult() => 'created',
      RejectedRollResult() => 'rejected',
    };

    expect(die(Die.tryCreate(6)), 'created');
    expect(expression(DiceExpression.tryCreate(0, Die.d6)), 'rejected');
    expect(parse(DiceExpression.tryParse('2d6')), 'parsed');
    expect(roll(DieRoll.tryCreate(Die.d6, 7)), 'rejected');
    expect(
      result(RollResult.tryCreate(DiceExpression(1, Die.d6), const [])),
      'rejected',
    );
  });
}
