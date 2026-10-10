import '../../shared_kernel/dice/dice_expression.dart';
import '../../shared_kernel/dice/roll_result.dart';
import 'dice_roller.dart';
import 'dice_roller_exception.dart';

/// Contract-checked rolling for any [DiceRoller].
///
/// Application code that needs a roll calls [rollChecked] instead of
/// [DiceRoller.roll], so a roller that breaks the contract fails loudly, as a
/// typed exception, instead of feeding a wrong result into the rules.
extension DiceRollerChecked on DiceRoller {
  /// Rolls [expression] and returns the roller's result when it is for that
  /// expression.
  ///
  /// Throws a `DiceRollerException` with the reason `invalidResult` and the
  /// requested [expression] when the roller returns a result for a different
  /// expression (a different count, die or modifier). A `DiceRollerException`
  /// thrown by the roller propagates unchanged (the same instance, so the
  /// failure is recorded once, by the use case at whose boundary it leaves
  /// the package). An `Error` thrown by the roller, such as a `StateError`, is
  /// not caught.
  RollResult rollChecked(DiceExpression expression) {
    final result = roll(expression);
    if (result.expression != expression) {
      throw DiceRollerException(
        expression: expression,
        reason: DiceRollerFailureReason.invalidResult,
      );
    }
    return result;
  }
}
