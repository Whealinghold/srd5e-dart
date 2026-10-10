import 'package:srd5e/src/shared_ports/observability/attributes.dart';
import 'package:srd5e/src/shared_ports/observability/tracer.dart';
import 'package:test/test.dart';

import 'tracer_contract.dart';

const Span _span = _InertSpan();

final class _InertSpan implements Span {
  const _InertSpan();

  @override
  void setAttribute(String key, Object value) {}

  @override
  void setStatus(SpanStatus status) {}

  @override
  void recordError(Object error, StackTrace stackTrace) {}
}

/// A tracer that gets every behaviour right; the broken ones override one.
base class _GoodTracer implements Tracer {
  const _GoodTracer();

  @override
  T trace<T>(
    String name,
    T Function(Span span) body, {
    Attributes attributes = const {},
  }) => body(_span);

  @override
  Future<T> traceAsync<T>(
    String name,
    Future<T> Function(Span span) body, {
    Attributes attributes = const {},
  }) async => body(_span);
}

/// Swallows the body's error and returns nothing.
final class _Swallowing extends _GoodTracer {
  const _Swallowing();

  @override
  T trace<T>(
    String name,
    T Function(Span span) body, {
    Attributes attributes = const {},
  }) {
    try {
      return body(_span);
    } catch (_) {
      return null as T;
    }
  }
}

/// Wraps the body's error in another object.
final class _Wrapping extends _GoodTracer {
  const _Wrapping();

  @override
  T trace<T>(
    String name,
    T Function(Span span) body, {
    Attributes attributes = const {},
  }) {
    try {
      return body(_span);
    } catch (error) {
      throw StateError('wrapped: $error');
    }
  }
}

/// Rethrows the same object but with a new stack trace.
final class _ReplacingStackTrace extends _GoodTracer {
  const _ReplacingStackTrace();

  @override
  T trace<T>(
    String name,
    T Function(Span span) body, {
    Attributes attributes = const {},
  }) {
    try {
      return body(_span);
    } catch (error) {
      Error.throwWithStackTrace(error, StackTrace.current);
    }
  }
}

/// Runs the body twice.
final class _RunsTwice extends _GoodTracer {
  const _RunsTwice();

  @override
  T trace<T>(
    String name,
    T Function(Span span) body, {
    Attributes attributes = const {},
  }) {
    body(_span);
    return body(_span);
  }
}

/// Throws synchronously from traceAsync instead of returning a failed future.
final class _ThrowsSynchronously extends _GoodTracer {
  const _ThrowsSynchronously();

  @override
  Future<T> traceAsync<T>(
    String name,
    Future<T> Function(Span span) body, {
    Attributes attributes = const {},
  }) => body(_span);
}

/// Completes before the body's future does.
final class _CompletesEarly extends _GoodTracer {
  const _CompletesEarly();

  @override
  Future<T> traceAsync<T>(
    String name,
    Future<T> Function(Span span) body, {
    Attributes attributes = const {},
  }) {
    body(_span);
    return Future<T>.value(null as T);
  }
}

TracerHarness _reporting(
  Tracer tracer, {
  SpanStatus status = SpanStatus.error,
  bool ended = true,
  int errors = 1,
  String name = contractSpanName,
  Object? recorded,
}) => (
  tracer: tracer,
  spans: () => [
    (
      name: name,
      status: status,
      errors: List<Object>.filled(errors, recorded ?? Object()),
      ended: ended,
    ),
  ],
);

void main() {
  final boom = StateError('boom');

  /// Requirement: doc/specs/observability-ports.md FR-063 - the Tracer
  ///   contract suite must be able to fail: each tracer that breaks one
  ///   behaviour makes the matching check fail.
  /// Path: unhappy (failure of collaborator)
  group('the Tracer contract rejects a bad tracer', () {
    /// Requirement: doc/specs/observability-ports.md FR-011 and FR-012 - the
    ///   synchronous checks catch a tracer that swallows, wraps, re-stamps the
    ///   stack trace of, or reruns the body.
    /// Path: unhappy (failure)
    test('synchronous breaches are caught', () {
      expect(
        () => expectTraceRethrowsUnchanged(const _Swallowing(), boom),
        throwsA(isA<TestFailure>()),
        reason: 'swallowed error',
      );
      expect(
        () => expectTraceRethrowsUnchanged(const _Wrapping(), boom),
        throwsA(isA<TestFailure>()),
        reason: 'wrapped error',
      );
      expect(
        () => expectTraceRethrowsUnchanged(const _ReplacingStackTrace(), boom),
        throwsA(isA<TestFailure>()),
        reason: 'replaced stack trace',
      );
      expect(
        () => expectTraceRunsBodyOnce(const _RunsTwice()),
        throwsA(isA<TestFailure>()),
        reason: 'body run twice',
      );
    });

    /// Requirement: doc/specs/observability-ports.md FR-013, FR-014 and
    ///   FR-054 - the asynchronous checks catch a tracer that throws
    ///   synchronously from traceAsync or completes before the future.
    /// Path: unhappy (failure)
    test('asynchronous breaches are caught', () async {
      await expectLater(
        expectTraceAsyncSyncThrowIsAFailedFuture(
          const _ThrowsSynchronously(),
          boom,
        ),
        throwsA(isA<TestFailure>()),
      );
      await expectLater(
        expectTraceAsyncReturnsValue(const _CompletesEarly()),
        throwsA(isA<TestFailure>()),
      );
    });

    /// Requirement: doc/specs/observability-ports.md FR-011, FR-012, FR-013 - the
    ///   span checks catch a tracer whose spans are never ended, never marked
    ///   as failed, never given the error, or named wrongly.
    /// Path: unhappy (failure)
    test('span bookkeeping breaches are caught', () async {
      const tracer = _GoodTracer();
      expect(
        () => expectSpanNamedAndEnded(
          _reporting(tracer, status: SpanStatus.unset, ended: false),
        ),
        throwsA(isA<TestFailure>()),
        reason: 'never ended',
      );
      expect(
        () => expectSpanNamedAndEnded(
          _reporting(tracer, status: SpanStatus.unset, name: 'other'),
        ),
        throwsA(isA<TestFailure>()),
        reason: 'wrong name',
      );
      expect(
        () => expectFailureRecordedOnSpan(
          _reporting(tracer, status: SpanStatus.unset, recorded: boom),
          boom,
        ),
        throwsA(isA<TestFailure>()),
        reason: 'status left unset',
      );
      expect(
        () => expectFailureRecordedOnSpan(
          _reporting(tracer, ended: false, recorded: boom),
          boom,
        ),
        throwsA(isA<TestFailure>()),
        reason: 'not ended after a failure',
      );
      expect(
        () => expectFailureRecordedOnSpan(_reporting(tracer), boom),
        throwsA(isA<TestFailure>()),
        reason: 'a different object recorded',
      );
      expect(
        () => expectFailureRecordedOnSpan(_reporting(tracer, errors: 0), boom),
        throwsA(isA<TestFailure>()),
        reason: 'error not recorded',
      );
      await expectLater(
        expectAsyncSpanEndsOnCompletion(_reporting(tracer, ended: true)),
        throwsA(isA<TestFailure>()),
        reason: 'ended before the future completes',
      );
      await expectLater(
        expectAsyncFailureRecordedOnSpan(
          _reporting(tracer, ended: false, recorded: boom),
          boom,
          throwsBeforeReturning: true,
        ),
        throwsA(isA<TestFailure>()),
        reason: 'not ended after a failure',
      );
    });

    /// Requirement: doc/specs/observability-ports.md FR-011, FR-012, FR-013, FR-014 - the
    ///   same checks pass for a correct tracer, so the cases above fail for
    ///   the right reason.
    /// Path: happy
    test('a correct tracer passes the same checks', () async {
      const tracer = _GoodTracer();

      expectTraceRunsBodyOnce(tracer);
      expectTraceRethrowsUnchanged(tracer, boom);
      await expectTraceAsyncReturnsValue(tracer);
      await expectTraceAsyncPropagates(tracer, boom);
      await expectTraceAsyncSyncThrowIsAFailedFuture(tracer, boom);
      expectFailureRecordedOnSpan(_reporting(tracer, recorded: boom), boom);
      await expectAsyncFailureRecordedOnSpan(
        _reporting(tracer, recorded: boom),
        boom,
        throwsBeforeReturning: true,
      );
    });
  });
}
