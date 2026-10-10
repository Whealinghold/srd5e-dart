import 'dart:math';

import 'package:srd5e/src/shared_ports/adapters/seeded_dice_roller.dart';
import 'package:srd5e/src/testing/callback_dice_roller.dart';
import 'package:srd5e/src/testing/fixed_dice_roller.dart';

import 'dice_roller_contract.dart';

/// A [Random] whose `nextInt` throws [cause] with [stackTrace], the failing
/// backend for the `SeededDiceRoller` variant of FR-048.
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

SeededDiceRoller _failingSeeded(Exception cause, StackTrace stackTrace) =>
    SeededDiceRoller(_FailingRandom(cause, stackTrace));

void main() {
  diceRollerContract(
    'FixedDiceRoller with listed values',
    // 1, 2, 1, 2, ... is a valid face for every die of two or more sides.
    () => FixedDiceRoller([for (var i = 0; i < 2000; i++) (i % 2) + 1]),
  );

  diceRollerContract('FixedDiceRoller.minimum', FixedDiceRoller.minimum);

  diceRollerContract('FixedDiceRoller.maximum', FixedDiceRoller.maximum);

  diceRollerContract(
    'SeededDiceRoller over Random(7)',
    () => SeededDiceRoller(Random(7)),
    failingVariant: _failingSeeded,
  );

  diceRollerContract(
    'CallbackDiceRoller wrapping SeededDiceRoller',
    () {
      final inner = SeededDiceRoller(Random(7));
      return CallbackDiceRoller(inner.roll);
    },
    failingVariant: (cause, stackTrace) {
      final inner = _failingSeeded(cause, stackTrace);
      return CallbackDiceRoller(inner.roll);
    },
  );
}
