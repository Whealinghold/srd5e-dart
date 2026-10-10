import '../../shared_kernel/dice/dice_expression.dart';
import '../../shared_kernel/dice/roll_result.dart';

/// The driven port through which all randomness enters the package.
///
/// The domain never rolls. A use case that needs dice calls a [DiceRoller]
/// (through `rollChecked`, see `DiceRollerChecked`) and hands the resulting
/// [RollResult] to pure domain code as a value.
///
/// The port is synchronous: rolling dice is computational and has no expected
/// absence, so there is no `Future` and no sealed result. A roller backed by
/// I/O is outside this contract; a consumer resolves the roll first, validates
/// host-supplied faces with `DieRoll.tryCreate` and `RollResult.tryCreate`,
/// and serves the result through its own adapter.
///
/// ## Contract for every implementation
///
/// * [roll] returns a [RollResult] whose `expression` equals the requested
///   expression (same count, die and modifier).
/// * It rolls exactly `expression.count` dice, each showing a face from 1 to
///   its sides, so the `total` lies between `expression.minimum` and
///   `expression.maximum`.
/// * An implementation whose backend can fail wraps that failure with
///   `wrapPortFailure`, so a backend `Exception` surfaces as a
///   `DiceRollerException` with the reason `unavailable`, the requested
///   expression and the original exception as `cause`. It never returns a
///   partial or default result, and never lets the raw backend exception
///   escape. An `Error` from the backend propagates unchanged.
///
/// The shared contract suite lives in `test/contract/dice_roller_contract.dart`
/// of the srd5e repository. It is not exported (it needs `package:test`), but a
/// consumer can copy it to run against their own adapter.
abstract interface class DiceRoller {
  /// Rolls [expression] and returns the faces and totals.
  ///
  /// Throws a `DiceRollerException` when the roller cannot roll.
  RollResult roll(DiceExpression expression);
}
