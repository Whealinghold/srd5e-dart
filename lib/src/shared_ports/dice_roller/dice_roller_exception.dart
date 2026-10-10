import '../../shared_kernel/dice/dice_expression.dart';
import '../errors/srd5e_exception.dart';

/// Why a [DiceRollerException] was thrown.
enum DiceRollerFailureReason {
  /// The roller's backend failed, so it could not roll (an `Exception` from
  /// the backend, kept as the exception's `cause`).
  unavailable,

  /// The roller returned a result for a different expression than the one
  /// requested, which breaks the `DiceRoller` contract.
  invalidResult,
}

/// A `DiceRoller` could not produce a valid roll.
///
/// This is infrastructure failure, not a rule outcome: it is thrown, never
/// returned. Catch it with `on DiceRollerException` or `on Srd5eException`.
/// It carries data, not display text: read [expression], [reason], [cause] and
/// [causeStackTrace]. Its [errorType] is the value of the `error.type`
/// telemetry attribute wherever a use case records this failure.
final class DiceRollerException extends Srd5eException {
  /// Creates the failure of rolling [expression] for [reason].
  ///
  /// [cause] and [causeStackTrace] are the original backend exception and its
  /// stack trace, unchanged, and are `null` when the failure did not come from
  /// a thrown object (the `invalidResult` case).
  const DiceRollerException({
    required this.expression,
    required this.reason,
    super.cause,
    super.causeStackTrace,
  });

  /// The expression that was requested, never the one a faulty roller
  /// answered. Its canonical `notation` identifies it in logs; it is never a
  /// metric attribute (unbounded cardinality).
  final DiceExpression expression;

  /// Why the roll failed.
  final DiceRollerFailureReason reason;

  /// The constant `dice_roller_exception`: the snake_case of this class name.
  @override
  String get errorType => 'dice_roller_exception';

  /// The debugging form. Not display text, and not to be relied on.
  @override
  String toString() =>
      'DiceRollerException(${reason.name}, ${expression.notation})';
}
