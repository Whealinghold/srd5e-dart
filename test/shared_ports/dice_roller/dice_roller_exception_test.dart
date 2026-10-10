import 'package:srd5e/src/shared_kernel/dice/dice_expression.dart';
import 'package:srd5e/src/shared_kernel/dice/die.dart';
import 'package:srd5e/src/shared_ports/dice_roller/dice_roller_exception.dart';
import 'package:srd5e/src/shared_ports/errors/srd5e_exception.dart';
import 'package:test/test.dart';

void main() {
  final expression = DiceExpression(2, Die.d8, modifier: 2);

  /// Requirement: doc/specs/dice-and-rolls.md FR-049 - DiceRollerException is a
  ///   final subtype of Srd5eException that carries data, not display text
  ///   (`architecture.md` §6; `doc/specs/errors-and-results.md` FR-002, FR-005).
  /// Path: unhappy (failure)
  group('DiceRollerException', () {
    /// Requirement: doc/specs/dice-and-rolls.md FR-049 - it is an Srd5eException
    ///   and an Exception, and not an Error.
    /// Path: unhappy (failure)
    test('is an Srd5eException and an Exception, not an Error', () {
      final exception = DiceRollerException(
        expression: expression,
        reason: DiceRollerFailureReason.unavailable,
      );

      expect(exception, isA<Srd5eException>());
      expect(exception, isA<Exception>());
      expect(exception, isNot(isA<Error>()));
    });

    /// Requirement: doc/specs/dice-and-rolls.md FR-049 - it exposes the
    ///   expression, the reason, and the cause and stack trace as the same
    ///   instances.
    /// Path: unhappy (failure)
    test('carries expression, reason, cause and causeStackTrace unchanged', () {
      const cause = FormatException('backend down');
      final trace = StackTrace.fromString('backend trace');

      final exception = DiceRollerException(
        expression: expression,
        reason: DiceRollerFailureReason.unavailable,
        cause: cause,
        causeStackTrace: trace,
      );

      expect(exception.expression, expression);
      expect(exception.reason, DiceRollerFailureReason.unavailable);
      expect(exception.cause, same(cause));
      expect(exception.causeStackTrace, same(trace));
    });

    /// Requirement: doc/specs/dice-and-rolls.md FR-049 - cause and
    ///   causeStackTrace are optional and default to null (the invalidResult
    ///   case has no underlying error).
    /// Path: unhappy (failure)
    test('cause and causeStackTrace default to null', () {
      final exception = DiceRollerException(
        expression: expression,
        reason: DiceRollerFailureReason.invalidResult,
      );

      expect(exception.reason, DiceRollerFailureReason.invalidResult);
      expect(exception.cause, isNull);
      expect(exception.causeStackTrace, isNull);
    });

    /// Requirement: doc/specs/dice-and-rolls.md FR-049 and FR-086 - errorType is
    ///   the constant dice_roller_exception for every instance and reason.
    /// Path: unhappy (failure)
    test('errorType is dice_roller_exception for every reason', () {
      for (final reason in DiceRollerFailureReason.values) {
        final exception = DiceRollerException(
          expression: expression,
          reason: reason,
        );

        expect(exception.errorType, 'dice_roller_exception');
      }
    });

    /// Requirement: doc/specs/dice-and-rolls.md FR-049 - the reason enum is
    ///   closed at unavailable and invalidResult, so a switch is exhaustive.
    /// Path: unhappy (failure)
    test('the reason is switched over exhaustively', () {
      String describe(DiceRollerFailureReason reason) => switch (reason) {
        DiceRollerFailureReason.unavailable => 'backend failed',
        DiceRollerFailureReason.invalidResult => 'result broke the contract',
      };

      expect(describe(DiceRollerFailureReason.unavailable), 'backend failed');
      expect(
        describe(DiceRollerFailureReason.invalidResult),
        'result broke the contract',
      );
      expect(DiceRollerFailureReason.values, hasLength(2));
    });

    /// Requirement: doc/specs/dice-and-rolls.md FR-049 - it is thrown and
    ///   caught through the root type, and the consumer reads its data.
    /// Path: unhappy (failure)
    test('is caught with on Srd5eException', () {
      Object? caught;

      try {
        throw DiceRollerException(
          expression: expression,
          reason: DiceRollerFailureReason.unavailable,
        );
      } on Srd5eException catch (e) {
        caught = e;
      }

      expect(
        caught,
        isA<DiceRollerException>().having(
          (e) => e.errorType,
          'errorType',
          'dice_roller_exception',
        ),
      );
    });

    /// Requirement: doc/specs/dice-and-rolls.md FR-049 - the debugging form
    ///   names the reason and the expression's canonical notation; it is not
    ///   display text.
    /// Path: happy
    test('toString names the reason and the notation', () {
      final exception = DiceRollerException(
        expression: expression,
        reason: DiceRollerFailureReason.invalidResult,
      );

      expect(exception.toString(), 'DiceRollerException(invalidResult, 2d8+2)');
    });
  });
}
