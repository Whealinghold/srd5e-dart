import '../shared_kernel/dice/dice_expression.dart';
import '../shared_kernel/dice/roll_result.dart';
import '../shared_ports/dice_roller/dice_roller.dart';

/// A test double [DiceRoller] that answers every roll with a function you
/// supply.
///
/// It returns whatever the callback returns and lets anything the callback
/// throws propagate unchanged, so a test can simulate a `DiceRollerException`,
/// a raw backend exception, a `StateError`, or a result for the wrong
/// expression (a roller that breaks the port contract).
final class CallbackDiceRoller implements DiceRoller {
  /// Creates a double that calls [callback] for every roll.
  const CallbackDiceRoller(this._callback);

  final RollResult Function(DiceExpression expression) _callback;

  @override
  RollResult roll(DiceExpression expression) => _callback(expression);
}
