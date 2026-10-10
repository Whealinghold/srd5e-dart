import 'dart:async';

import 'package:srd5e/src/shared_ports/errors/port_failure_guards.dart';
import 'package:srd5e/src/shared_ports/errors/srd5e_exception.dart';
import 'package:test/test.dart';

/// A test-local concrete subtype, so these unit tests import nothing from a
/// port folder or a context.
final class _TestException extends Srd5eException {
  const _TestException({super.cause});

  @override
  String get errorType => 'test_exception';
}

/// A custom `Exception` that is not an `Srd5eException`.
final class _BackendException implements Exception {
  const _BackendException();
}

/// One recorded call of the `wrap` argument.
typedef _WrapCall = ({Object cause, StackTrace stackTrace});

/// A `wrap` function that records its calls and returns [result], or throws
/// [throwing] instead when that is given.
final class _WrapSpy {
  _WrapSpy({Srd5eException? result, this.throwing})
    : result = result ?? const _TestException();

  final Srd5eException result;
  final Object? throwing;
  final List<_WrapCall> calls = [];

  Srd5eException call(Object cause, StackTrace stackTrace) {
    calls.add((cause: cause, stackTrace: stackTrace));
    final failure = throwing;
    if (failure != null) {
      throw failure;
    }
    return result;
  }
}

/// Throws [value] with [stackTrace], whatever its type.
Never _throwWith(Object value, StackTrace stackTrace) =>
    Error.throwWithStackTrace(value, stackTrace);

/// Runs [action] and returns the stack trace its failure carried.
StackTrace _stackTraceOfSyncFailure(void Function() action) {
  try {
    action();
  } on Object catch (_, stackTrace) {
    return stackTrace;
  }
  throw StateError('The action did not throw.');
}

/// Awaits [future] and returns the stack trace its failure carried.
Future<StackTrace> _stackTraceOfAsyncFailure(Future<Object?> future) async {
  try {
    await future;
  } on Object catch (_, stackTrace) {
    return stackTrace;
  }
  throw StateError('The future did not fail.');
}

typedef _ValueCase = ({
  String label,
  String requirement,
  String path,
  Object? value,
});

typedef _PropagationCase = ({
  String label,
  String requirement,
  String path,
  Object value,
});

void main() {
  /// Requirement: per case
  /// Path: per case
  group('wrapPortFailure returns a value', () {
    final cases = <_ValueCase>[
      (
        label: 'an int',
        requirement:
            'doc/specs/errors-and-results.md FR-008 - the value is returned '
            'unchanged and wrap is not called',
        path: 'happy',
        value: 42,
      ),
      (
        label: 'null',
        requirement:
            'doc/specs/errors-and-results.md FR-008 - a null value is '
            'returned unchanged',
        path: 'unhappy (empty and minimal)',
        value: null,
      ),
      (
        label: 'an empty list',
        requirement:
            'doc/specs/errors-and-results.md FR-008 - an empty collection is '
            'returned as the same instance',
        path: 'unhappy (empty and minimal)',
        value: <int>[],
      ),
    ];

    /// Requirement: per case
    /// Path: per case
    for (final c in cases) {
      test('${c.label} [${c.path}]', () {
        final spy = _WrapSpy();

        final result = wrapPortFailure<Object?>(() => c.value, spy.call);

        expect(result, same(c.value));
        expect(spy.calls, isEmpty);
      });
    }
  });

  /// Requirement: doc/specs/errors-and-results.md FR-009 and FR-039 - an
  ///   `Exception` that is not an `Srd5eException` is passed to wrap with its
  ///   stack trace, and the wrapper is thrown with that stack trace.
  /// Path: unhappy (failure of collaborator)
  group('wrapPortFailure wraps an Exception', () {
    /// Requirement: doc/specs/errors-and-results.md FR-009 - a
    ///   `FormatException` is replaced by the object wrap returns.
    /// Path: unhappy (failure of collaborator)
    test('throws the object wrap returned for a FormatException', () {
      const cause = FormatException('backend failed');
      final spy = _WrapSpy();

      expect(
        () => wrapPortFailure<int>(() => throw cause, spy.call),
        throwsA(same(spy.result)),
      );
      expect(spy.calls, hasLength(1));
      expect(spy.calls.single.cause, same(cause));
    });

    /// Requirement: doc/specs/errors-and-results.md FR-009 - a custom
    ///   `Exception` is replaced by the object wrap returns.
    /// Path: unhappy (failure of collaborator)
    test('throws the object wrap returned for a custom Exception', () {
      const cause = _BackendException();
      final spy = _WrapSpy();

      expect(
        () => wrapPortFailure<int>(() => throw cause, spy.call),
        throwsA(same(spy.result)),
      );
      expect(spy.calls.single.cause, same(cause));
    });

    /// Requirement: doc/specs/errors-and-results.md FR-039 - wrap receives the
    ///   original stack trace and the thrown wrapper carries the same one.
    /// Path: unhappy (failure of collaborator)
    test('wrap and the thrown wrapper use the original stack trace', () {
      final original = StackTrace.fromString('original backend trace');
      final spy = _WrapSpy();

      final thrown = _stackTraceOfSyncFailure(
        () => wrapPortFailure<int>(
          () => _throwWith(const _BackendException(), original),
          spy.call,
        ),
      );

      expect(spy.calls.single.stackTrace, same(original));
      expect(thrown.toString(), original.toString());
    });
  });

  /// Requirement: doc/specs/errors-and-results.md FR-010 - an
  ///   `Srd5eException` thrown by the body is rethrown as the same instance
  ///   and wrap is not called (no double wrapping).
  /// Path: unhappy (rule interaction)
  test('wrapPortFailure rethrows an Srd5eException unchanged', () {
    const existing = _TestException(cause: 'inner');
    final spy = _WrapSpy();

    expect(
      () => wrapPortFailure<int>(() => throw existing, spy.call),
      throwsA(same(existing)),
    );
    expect(spy.calls, isEmpty);
  });

  /// Requirement: per case
  /// Path: per case
  group('wrapPortFailure lets non-Exception objects propagate', () {
    final cases = <_PropagationCase>[
      (
        label: 'ArgumentError',
        requirement:
            'doc/specs/errors-and-results.md FR-011 - an Error propagates '
            'unchanged and wrap is not called',
        path: 'unhappy (state error)',
        value: ArgumentError.value(7, 'sides', 'invalid'),
      ),
      (
        label: 'StateError',
        requirement:
            'doc/specs/errors-and-results.md FR-011 - an Error propagates '
            'unchanged and wrap is not called',
        path: 'unhappy (state error)',
        value: StateError('broken invariant'),
      ),
      (
        label: 'RangeError',
        requirement:
            'doc/specs/errors-and-results.md FR-011 - an ArgumentError '
            'subtype propagates unchanged',
        path: 'unhappy (state error)',
        value: RangeError.range(9, 0, 5),
      ),
      (
        label: 'String',
        requirement:
            'doc/specs/errors-and-results.md FR-012 and FR-040 - a thrown '
            'object that is not an Exception propagates unchanged',
        path: 'unhappy (failure of collaborator)',
        value: 'a thrown string',
      ),
      (
        label: 'int',
        requirement:
            'doc/specs/errors-and-results.md FR-012 and FR-040 - a thrown int '
            'propagates unchanged',
        path: 'unhappy (failure of collaborator)',
        value: 42,
      ),
    ];

    /// Requirement: per case
    /// Path: per case
    for (final c in cases) {
      test('${c.label} [${c.path}]', () {
        final spy = _WrapSpy();

        expect(
          () => wrapPortFailure<int>(
            () => Error.throwWithStackTrace(c.value, StackTrace.empty),
            spy.call,
          ),
          throwsA(same(c.value)),
        );
        expect(spy.calls, isEmpty);
      });
    }
  });

  /// Requirement: doc/specs/errors-and-results.md FR-013 - when wrap itself
  ///   throws, that error propagates, is not caught and wrap is called once.
  /// Path: unhappy (failure of collaborator)
  test('wrapPortFailure propagates an error thrown by wrap', () {
    final wrapFailure = StateError('wrap is broken');
    final spy = _WrapSpy(throwing: wrapFailure);

    expect(
      () =>
          wrapPortFailure<int>(() => throw const _BackendException(), spy.call),
      throwsA(same(wrapFailure)),
    );
    expect(spy.calls, hasLength(1));
  });

  /// Requirement: doc/specs/errors-and-results.md FR-014 - the value the body's
  ///   future completes with is returned unchanged and wrap is not called.
  /// Path: happy
  group('wrapPortFailureAsync completes with a value', () {
    /// Requirement: doc/specs/errors-and-results.md FR-014 - an already
    ///   completed future.
    /// Path: happy
    test('completes with the value of an immediate future', () async {
      final spy = _WrapSpy();

      final result = await wrapPortFailureAsync<int>(() async => 42, spy.call);

      expect(result, 42);
      expect(spy.calls, isEmpty);
    });

    /// Requirement: doc/specs/errors-and-results.md FR-014 - a future that
    ///   completes later (driven by a completer, no real time).
    /// Path: happy
    test('completes with the value of a future that completes later', () async {
      final spy = _WrapSpy();
      final completer = Completer<int>();

      final future = wrapPortFailureAsync<int>(
        () => completer.future,
        spy.call,
      );
      completer.complete(7);

      expect(await future, 7);
      expect(spy.calls, isEmpty);
    });

    /// Requirement: doc/specs/errors-and-results.md FR-014 - a null value is
    ///   completed unchanged.
    /// Path: unhappy (empty and minimal)
    test('completes with null unchanged', () async {
      final spy = _WrapSpy();

      final result = await wrapPortFailureAsync<int?>(
        () async => null,
        spy.call,
      );

      expect(result, isNull);
      expect(spy.calls, isEmpty);
    });
  });

  /// Requirement: doc/specs/errors-and-results.md FR-015, FR-016 and FR-037 -
  ///   an `Exception` that is not an `Srd5eException` is wrapped whether the
  ///   body throws before returning a future or returns a failed future, and
  ///   the call itself never throws synchronously.
  /// Path: unhappy (failure of collaborator)
  group('wrapPortFailureAsync wraps an Exception', () {
    /// Requirement: doc/specs/errors-and-results.md FR-015 - the future
    ///   returned by the body fails with a FormatException.
    /// Path: unhappy (failure of collaborator)
    test('wraps an Exception from a failed future', () async {
      const cause = FormatException('backend failed');
      final spy = _WrapSpy();

      final future = wrapPortFailureAsync<int>(
        () => Future<int>.error(cause),
        spy.call,
      );

      await expectLater(future, throwsA(same(spy.result)));
      expect(spy.calls, hasLength(1));
      expect(spy.calls.single.cause, same(cause));
    });

    /// Requirement: doc/specs/errors-and-results.md FR-015 - a custom
    ///   Exception completes the body's future as an error.
    /// Path: unhappy (failure of collaborator)
    test('wraps a custom Exception from an async body', () async {
      const cause = _BackendException();
      final spy = _WrapSpy();

      final future = wrapPortFailureAsync<int>(
        () async => throw cause,
        spy.call,
      );

      await expectLater(future, throwsA(same(spy.result)));
      expect(spy.calls.single.cause, same(cause));
    });

    /// Requirement: doc/specs/errors-and-results.md FR-016 and FR-037 - a body
    ///   that throws before returning a future yields a failed future and the
    ///   call does not throw synchronously.
    /// Path: unhappy (failure of collaborator)
    test('a synchronous throw becomes a failed future', () async {
      const cause = FormatException('thrown before any future');
      final spy = _WrapSpy();

      final Future<int> future = wrapPortFailureAsync<int>(
        () => throw cause,
        spy.call,
      );

      await expectLater(future, throwsA(same(spy.result)));
      expect(spy.calls.single.cause, same(cause));
    });

    /// Requirement: doc/specs/errors-and-results.md FR-039 - wrap receives the
    ///   original stack trace of a failed future and the wrapper carries it.
    /// Path: unhappy (failure of collaborator)
    test('wrap and the failed future use the original stack trace', () async {
      final original = StackTrace.fromString('original async trace');
      final spy = _WrapSpy();

      final thrown = await _stackTraceOfAsyncFailure(
        wrapPortFailureAsync<int>(
          () => Future<int>.error(const _BackendException(), original),
          spy.call,
        ),
      );

      expect(spy.calls.single.stackTrace, same(original));
      expect(thrown.toString(), original.toString());
    });

    /// Requirement: doc/specs/errors-and-results.md FR-039 - the same holds
    ///   when the body throws before returning a future.
    /// Path: unhappy (failure of collaborator)
    test('a synchronous throw keeps the original stack trace', () async {
      final original = StackTrace.fromString('original sync trace');
      final spy = _WrapSpy();

      final thrown = await _stackTraceOfAsyncFailure(
        wrapPortFailureAsync<int>(
          () => _throwWith(const _BackendException(), original),
          spy.call,
        ),
      );

      expect(spy.calls.single.stackTrace, same(original));
      expect(thrown.toString(), original.toString());
    });
  });

  /// Requirement: per case
  /// Path: per case
  group('wrapPortFailureAsync leaves other objects unchanged', () {
    final cases = <_PropagationCase>[
      (
        label: 'Srd5eException',
        requirement:
            'doc/specs/errors-and-results.md FR-017 and FR-037 - an '
            'Srd5eException keeps its identity and wrap is not called',
        path: 'unhappy (rule interaction)',
        value: const _TestException(cause: 'inner'),
      ),
      (
        label: 'Error',
        requirement:
            'doc/specs/errors-and-results.md FR-017 and FR-037 - an Error '
            'keeps its identity and wrap is not called',
        path: 'unhappy (failure of collaborator)',
        value: StateError('broken invariant'),
      ),
      (
        label: 'String',
        requirement:
            'doc/specs/errors-and-results.md FR-017, FR-037 and FR-040 - a '
            'thrown object that is not an Exception keeps its identity',
        path: 'unhappy (failure of collaborator)',
        value: 'a thrown string',
      ),
    ];

    /// Requirement: per case
    /// Path: per case
    for (final c in cases) {
      test('${c.label} thrown synchronously [${c.path}]', () async {
        final spy = _WrapSpy();

        final Future<int> future = wrapPortFailureAsync<int>(
          () => Error.throwWithStackTrace(c.value, StackTrace.empty),
          spy.call,
        );

        await expectLater(future, throwsA(same(c.value)));
        expect(spy.calls, isEmpty);
      });

      test('${c.label} as a failed future [${c.path}]', () async {
        final spy = _WrapSpy();

        final future = wrapPortFailureAsync<int>(
          () => Future<int>.error(c.value),
          spy.call,
        );

        await expectLater(future, throwsA(same(c.value)));
        expect(spy.calls, isEmpty);
      });
    }
  });

  /// Requirement: doc/specs/errors-and-results.md FR-038 - when wrap itself
  ///   throws inside the async guard, the returned future fails with that
  ///   error, and wrap is called once.
  /// Path: unhappy (failure of collaborator)
  group('wrapPortFailureAsync propagates an error thrown by wrap', () {
    /// Requirement: doc/specs/errors-and-results.md FR-038 - failed-future
    ///   path.
    /// Path: unhappy (failure of collaborator)
    test('when the body returns a failed future', () async {
      final wrapFailure = StateError('wrap is broken');
      final spy = _WrapSpy(throwing: wrapFailure);

      final future = wrapPortFailureAsync<int>(
        () => Future<int>.error(const _BackendException()),
        spy.call,
      );

      await expectLater(future, throwsA(same(wrapFailure)));
      expect(spy.calls, hasLength(1));
    });

    /// Requirement: doc/specs/errors-and-results.md FR-038 - synchronous-throw
    ///   path.
    /// Path: unhappy (failure of collaborator)
    test('when the body throws before returning a future', () async {
      final wrapFailure = StateError('wrap is broken');
      final spy = _WrapSpy(throwing: wrapFailure);

      final Future<int> future = wrapPortFailureAsync<int>(
        () => throw const _BackendException(),
        spy.call,
      );

      await expectLater(future, throwsA(same(wrapFailure)));
      expect(spy.calls, hasLength(1));
    });
  });
}
