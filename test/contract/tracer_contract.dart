import 'dart:async';

import 'package:srd5e/src/shared_ports/observability/tracer.dart';
import 'package:test/test.dart';

/// What a recording tracer reports about one span, for the checks that need to
/// see it. A consumer's tracer supplies the same facts from its own backend.
typedef SpanSnapshot = ({
  String name,
  SpanStatus status,
  List<Object> errors,
  bool ended,
});

/// A tracer under test, and, for an implementation that can show its spans,
/// the way to read them (in start order).
typedef TracerHarness = ({Tracer tracer, List<SpanSnapshot> Function()? spans});

/// A tracer harness factory; it must return a fresh harness each time.
typedef TracerHarnessFactory = TracerHarness Function();

/// The span name every contract check uses.
const String contractSpanName = 'srd5e.contract.work';

/// A failure thrown by a body under test.
final class ContractException implements Exception {
  /// Creates a failure.
  const ContractException();
}

/// One failure a body can throw: an `Exception` or an `Error`.
typedef ThrownCase = ({String label, Object Function() make});

/// The objects a body throws in the failure checks (FR-012).
final List<ThrownCase> thrownCases = [
  (label: 'an Exception', make: ContractException.new),
  (label: 'an Error', make: () => StateError('a bug')),
];

/// Runs [action] and returns what it threw with its stack trace.
({Object error, StackTrace stackTrace}) _catch(void Function() action) {
  try {
    action();
  } catch (error, stackTrace) {
    return (error: error, stackTrace: stackTrace);
  }
  fail('the action was expected to throw');
}

/// Awaits [future] and returns what it failed with and its stack trace.
Future<({Object error, StackTrace stackTrace})> _catchAsync(
  Future<Object?> future,
) async {
  try {
    await future;
  } catch (error, stackTrace) {
    return (error: error, stackTrace: stackTrace);
  }
  fail('the future was expected to fail');
}

/// FR-011: `trace` runs the body once with a span and returns its value.
void expectTraceRunsBodyOnce(Tracer tracer) {
  var calls = 0;
  Span? seen;

  final result = tracer.trace(contractSpanName, (span) {
    calls++;
    seen = span;
    return 42;
  });

  expect(result, 42);
  expect(calls, 1);
  expect(seen, isA<Span>());
}

/// FR-012: a body that throws [thrown] has it rethrown unchanged by `trace`,
/// with the stack trace the body threw it with.
void expectTraceRethrowsUnchanged(Tracer tracer, Object thrown) {
  final stackTrace = StackTrace.fromString('the body stack trace');

  final caught = _catch(
    () => tracer.trace<void>(
      contractSpanName,
      (span) => Error.throwWithStackTrace(thrown, stackTrace),
    ),
  );

  expect(caught.error, same(thrown), reason: 'FR-012: the same object');
  expect(
    caught.stackTrace.toString(),
    stackTrace.toString(),
    reason: 'FR-012: the stack trace is not replaced',
  );
}

/// FR-013: `traceAsync` returns the future's value, and only then completes.
Future<void> expectTraceAsyncReturnsValue(Tracer tracer) async {
  final gate = Completer<Object?>();
  var completed = false;

  final future = tracer.traceAsync<Object?>(
    contractSpanName,
    (span) => gate.future,
  );
  unawaited(future.then((_) => completed = true));
  await Future<void>.delayed(Duration.zero);
  expect(completed, isFalse, reason: 'FR-013: pending until the body is done');
  gate.complete(7);

  expect(await future, 7);
}

/// FR-014: a future that fails makes `traceAsync` fail with the same error.
Future<void> expectTraceAsyncPropagates(Tracer tracer, Object thrown) async {
  final stackTrace = StackTrace.fromString('the body stack trace');

  final caught = await _catchAsync(
    tracer.traceAsync<void>(
      contractSpanName,
      (span) => Future<void>.error(thrown, stackTrace),
    ),
  );

  expect(caught.error, same(thrown), reason: 'FR-014: the same object');
  expect(caught.stackTrace.toString(), stackTrace.toString());
}

/// FR-054: a body that throws before it returns a future gives a failed
/// future, not a synchronous throw.
Future<void> expectTraceAsyncSyncThrowIsAFailedFuture(
  Tracer tracer,
  Object thrown,
) async {
  late final Future<void> future;

  expect(
    () => future = tracer.traceAsync<void>(contractSpanName, (span) {
      // A non-async closure: it throws before it returns a Future.
      throw thrown;
    }),
    returnsNormally,
    reason: 'FR-054: no synchronous throw',
  );

  final caught = await _catchAsync(future);
  expect(caught.error, same(thrown));
}

/// FR-011 on a tracer that shows its spans: one span, named as asked, ended.
void expectSpanNamedAndEnded(TracerHarness harness) {
  harness.tracer.trace(contractSpanName, (span) => 1);

  final spans = harness.spans!();
  expect(spans, hasLength(1));
  expect(spans.single.name, contractSpanName);
  expect(spans.single.ended, isTrue);
  expect(spans.single.status, SpanStatus.unset);
}

/// FR-012 on a tracer that shows its spans: status `error`, the thrown object
/// recorded once, span ended.
void expectFailureRecordedOnSpan(TracerHarness harness, Object thrown) {
  _catch(
    () => harness.tracer.trace<void>(contractSpanName, (span) => throw thrown),
  );

  final span = harness.spans!().single;
  expect(span.status, SpanStatus.error);
  expect(span.errors, hasLength(1));
  expect(span.errors.single, same(thrown));
  expect(span.ended, isTrue);
}

/// FR-013 on a tracer that shows its spans: the span is open until the future
/// completes, then ended.
Future<void> expectAsyncSpanEndsOnCompletion(TracerHarness harness) async {
  final gate = Completer<int>();

  final future = harness.tracer.traceAsync(
    contractSpanName,
    (span) => gate.future,
  );
  await Future<void>.delayed(Duration.zero);
  expect(harness.spans!().single.ended, isFalse);
  gate.complete(1);
  await future;

  expect(harness.spans!().single.ended, isTrue);
}

/// FR-014 and FR-054 on a tracer that shows its spans: a failed future, or a
/// body that throws before returning one, leaves status `error`, the error
/// recorded and the span ended.
Future<void> expectAsyncFailureRecordedOnSpan(
  TracerHarness harness,
  Object thrown, {
  required bool throwsBeforeReturning,
}) async {
  final future = throwsBeforeReturning
      ? harness.tracer.traceAsync<void>(
          contractSpanName,
          (span) => throw thrown,
        )
      : harness.tracer.traceAsync<void>(
          contractSpanName,
          (span) => Future<void>.error(thrown),
        );
  await _catchAsync(future);

  final span = harness.spans!().single;
  expect(span.status, SpanStatus.error);
  expect(span.errors.single, same(thrown));
  expect(span.ended, isTrue);
}

/// Registers the shared `Tracer` contract suite
/// (`doc/specs/observability-ports.md` FR-011, FR-012, FR-013, FR-014, FR-019, FR-054 and
/// FR-063) against the implementation that [create] builds.
///
/// [create] must return a fresh harness each time. Pass `observesSpans: true`
/// when the harness can show its spans (`spans` is not null); the checks of
/// what is recorded on a span then run too.
///
/// The suite is not exported by the package (it needs `package:test`); copy it
/// to run against your own adapter.
void tracerContract(
  String name,
  TracerHarnessFactory create, {
  bool observesSpans = false,
}) {
  /// Requirement: doc/specs/observability-ports.md FR-011, FR-012, FR-013, FR-014, FR-019
  ///   and FR-054 - the Tracer port contract holds for this implementation.
  /// Path: happy
  group('Tracer contract: $name', () {
    /// Requirement: doc/specs/observability-ports.md FR-011 - the body runs
    ///   once with a span and its value is returned.
    /// Path: happy
    test('FR-011: trace runs the body once and returns its value', () {
      expectTraceRunsBodyOnce(create().tracer);
    });

    /// Requirement: doc/specs/observability-ports.md FR-013 - traceAsync
    ///   completes with the future's value, and only when it completes.
    /// Path: happy
    test('FR-013: traceAsync returns the value of the future', () async {
      await expectTraceAsyncReturnsValue(create().tracer);
    });

    /// Requirement: per case
    /// Path: per case
    for (final c in thrownCases) {
      test('FR-012/FR-019: trace rethrows ${c.label} unchanged '
          '[unhappy (failure)]', () {
        expectTraceRethrowsUnchanged(create().tracer, c.make());
      });

      test('FR-014/FR-019: traceAsync propagates ${c.label} from the future '
          '[unhappy (failure)]', () async {
        await expectTraceAsyncPropagates(create().tracer, c.make());
      });

      test('FR-054/FR-019: traceAsync turns ${c.label} thrown before a '
          'future into a failed future [unhappy (failure)]', () async {
        await expectTraceAsyncSyncThrowIsAFailedFuture(
          create().tracer,
          c.make(),
        );
      });
    }

    if (observesSpans) {
      /// Requirement: doc/specs/observability-ports.md FR-011 - one span is
      ///   started with the given name and ended, status left unset.
      /// Path: happy
      test('FR-011: the span is named, ended and left unset', () {
        expectSpanNamedAndEnded(create());
      });

      /// Requirement: doc/specs/observability-ports.md FR-013 - the span ends
      ///   only when the future completes.
      /// Path: happy
      test('FR-013: the async span ends when the future completes', () async {
        await expectAsyncSpanEndsOnCompletion(create());
      });

      /// Requirement: per case
      /// Path: per case
      for (final c in thrownCases) {
        test('FR-012: ${c.label} is recorded on the span '
            '[unhappy (failure)]', () {
          expectFailureRecordedOnSpan(create(), c.make());
        });

        test('FR-014: ${c.label} from the future is recorded on the span '
            '[unhappy (failure)]', () async {
          await expectAsyncFailureRecordedOnSpan(
            create(),
            c.make(),
            throwsBeforeReturning: false,
          );
        });

        test('FR-054: ${c.label} thrown before a future is recorded on the '
            'span [unhappy (failure)]', () async {
          await expectAsyncFailureRecordedOnSpan(
            create(),
            c.make(),
            throwsBeforeReturning: true,
          );
        });
      }
    }
  });
}
