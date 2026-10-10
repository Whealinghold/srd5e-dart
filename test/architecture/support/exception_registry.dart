import 'package:srd5e/src/shared_kernel/dice/dice_expression.dart';
import 'package:srd5e/src/shared_kernel/dice/die.dart';
import 'package:srd5e/src/shared_ports/dice_roller/dice_roller_exception.dart';
import 'package:srd5e/src/shared_ports/errors/srd5e_exception.dart';

/// One concrete [Srd5eException] subtype in the registry that check E1 uses.
///
/// A new subtype fails check E1 until an entry for it is added to
/// [registeredExceptions], and a row for its `errorType` is added to section 7
/// of `doc/specs/errors-and-results.md`.
final class RegisteredException {
  /// Creates an entry for the subtype [className].
  const RegisteredException({
    required this.className,
    required this.errorType,
    required this.create,
  });

  /// The subtype's class name, as declared under `lib/src`.
  final String className;

  /// The value of `errorType` the subtype must return (section 7 of the spec).
  final String errorType;

  /// Builds a sample instance carrying [cause] and [causeStackTrace], with any
  /// other field set to a valid sample value.
  final Srd5eException Function({Object? cause, StackTrace? causeStackTrace})
  create;
}

/// The concrete subtypes that exist under `lib/src` today.
///
/// `ContentSourceException` ships with `content-source-port.md`. The stage that
/// adds a subtype appends its entry here, and removes its name from
/// [pendingSubtypes].
final List<RegisteredException> registeredExceptions = [
  RegisteredException(
    className: 'DiceRollerException',
    errorType: 'dice_roller_exception',
    create: ({cause, causeStackTrace}) => DiceRollerException(
      expression: DiceExpression(1, Die.d20),
      reason: DiceRollerFailureReason.unavailable,
      cause: cause,
      causeStackTrace: causeStackTrace,
    ),
  ),
];

/// Subtypes listed in section 7 of `errors-and-results.md` whose owning stage
/// has not shipped yet (a forward registration). A name here must not be
/// declared under `lib/` and a name in [registeredExceptions] must not be here.
const Set<String> pendingSubtypes = {'ContentSourceException'};
