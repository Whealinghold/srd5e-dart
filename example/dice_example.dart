// Rolls a die expression with the bundled seeded roller, using only the public
// entry points.
import 'dart:io';
import 'dart:math';

import 'package:srd5e/adapters.dart';
import 'package:srd5e/srd5e.dart';

void main() {
  // Untrusted text goes through tryParse, which returns a result.
  final parsed = DiceExpression.tryParse('2d8 + 2');
  final DiceExpression expression;
  switch (parsed) {
    case ParsedDiceExpression(expression: final e):
      expression = e;
    case RejectedDiceExpression(:final reason):
      stdout.writeln('Not a die expression: ${reason.name}');
      return;
  }

  // The caller chooses the Random: a seeded one gives reproducible rolls.
  final DiceRoller roller = SeededDiceRoller(Random(7));

  try {
    final result = roller.rollChecked(expression);
    final faces = result.rolls.map((roll) => roll.value).join(', ');
    stdout.writeln(
      '${expression.notation}: faces $faces, total ${result.total} '
      '(average ${expression.average})',
    );
  } on DiceRollerException catch (e) {
    // A roller that cannot roll is a thrown failure, not a result.
    stdout.writeln('Roller failed: ${e.reason.name} (${e.errorType})');
  }
}
