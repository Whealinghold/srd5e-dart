import 'package:srd5e/src/shared_ports/errors/srd5e_exception.dart';
import 'package:test/test.dart';

/// A test-local concrete subtype, so these unit tests import nothing from a
/// port folder or a context.
final class _TestException extends Srd5eException {
  const _TestException({super.cause, super.causeStackTrace});

  @override
  String get errorType => 'test_exception';
}

void main() {
  /// Requirement: doc/specs/errors-and-results.md FR-001 - the root is an
  ///   `Exception`, not an `Error`, so a consumer can catch it with
  ///   `on Srd5eException` (architecture.md §4, §6; package design, no SRD
  ///   rule).
  /// Path: happy
  group('Srd5eException root', () {
    /// Requirement: doc/specs/errors-and-results.md FR-001 - a subtype is an
    ///   `Exception` and is not an `Error`.
    /// Path: happy
    test('a subtype is an Exception and not an Error', () {
      const exception = _TestException();

      expect(exception, isA<Exception>());
      expect(exception, isNot(isA<Error>()));
    });

    /// Requirement: doc/specs/errors-and-results.md FR-001 and FR-049 - a
    ///   subtype declared in another library is thrown and caught through the
    ///   root type, and the consumer reads its `errorType`.
    /// Path: happy
    test('a subtype is caught with on Srd5eException', () {
      String? caughtErrorType;

      try {
        throw const _TestException();
      } on Srd5eException catch (e) {
        caughtErrorType = e.errorType;
      }

      expect(caughtErrorType, 'test_exception');
    });

    /// Requirement: doc/specs/errors-and-results.md FR-002 - cause and
    ///   causeStackTrace are exposed unchanged (same instances) through the
    ///   const constructor and `super.cause, super.causeStackTrace`.
    /// Path: happy
    test('cause and causeStackTrace are the same instances passed in', () {
      const cause = FormatException('backend failed');
      final stackTrace = StackTrace.fromString('original trace');

      final exception = _TestException(
        cause: cause,
        causeStackTrace: stackTrace,
      );

      expect(exception.cause, same(cause));
      expect(exception.causeStackTrace, same(stackTrace));
    });

    /// Requirement: doc/specs/errors-and-results.md FR-002 and OQ-8 - the cause
    ///   is an `Object?`, so a non-`Exception` object is kept as is.
    /// Path: happy
    test('cause may be any object, not only an Exception', () {
      const cause = 'a thrown string';

      const exception = _TestException(cause: cause);

      expect(exception.cause, same(cause));
    });

    /// Requirement: doc/specs/errors-and-results.md FR-002 - a subtype is
    ///   `const`-constructible, so equal const expressions are canonical.
    /// Path: happy
    test('a subtype can be created as a compile-time constant', () {
      const first = _TestException();
      const second = _TestException();

      expect(identical(first, second), isTrue);
    });

    /// Requirement: doc/specs/errors-and-results.md FR-003 - cause and
    ///   causeStackTrace are optional and report null when omitted.
    /// Path: unhappy (empty and minimal)
    test('cause and causeStackTrace are null when omitted', () {
      const exception = _TestException();

      expect(exception.cause, isNull);
      expect(exception.causeStackTrace, isNull);
    });

    /// Requirement: doc/specs/errors-and-results.md FR-003 - the two fields
    ///   are independent: a cause without a stack trace keeps the stack trace
    ///   null.
    /// Path: unhappy (empty and minimal)
    test('a cause without a stack trace leaves the stack trace null', () {
      final cause = StateError('backend broke its contract');

      final exception = _TestException(cause: cause);

      expect(exception.cause, same(cause));
      expect(exception.causeStackTrace, isNull);
    });
  });
}
