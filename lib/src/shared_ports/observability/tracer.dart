import 'attributes.dart';

/// The status of a [Span].
enum SpanStatus {
  /// No status has been set. The default, and what a normal rule outcome
  /// leaves.
  unset,

  /// The operation completed without a failure.
  ok,

  /// The operation failed: it threw, or it returned a failure result.
  error,
}

/// The handle through which the work run by a [Tracer] describes its span.
///
/// A span is not a port: a [Tracer] hands it to the body it runs. It carries
/// attributes, a [SpanStatus] and any errors recorded on it. Do not keep it
/// after the body has returned; a recording span rejects that.
abstract interface class Span {
  /// Adds the attribute [key], or replaces an earlier value for it.
  ///
  /// [value] is a `String`, `bool`, `int` or `double`.
  void setAttribute(String key, Object value);

  /// Sets the status. The last call wins.
  void setStatus(SpanStatus status);

  /// Appends [error] and [stackTrace] to the span in call order.
  ///
  /// It does not change the status and does not end the span. A failure result
  /// that is not thrown is recorded by calling [setStatus] with
  /// [SpanStatus.error].
  void recordError(Object error, StackTrace stackTrace);
}

/// The driven port through which srd5e runs a unit of work inside a named
/// span.
///
/// The span name is the use case, for example `srd5e.d20_test.resolve`. A span
/// starts before the body runs and ends after it, and the implementation
/// measures its duration with its own clock; srd5e never reads one. srd5e does
/// not manage trace context: parent and child linkage is the implementation's
/// job.
///
/// When the body throws, the span is given the status [SpanStatus.error], the
/// thrown object and its stack trace are recorded on it, the span ends, and the
/// same object is rethrown unchanged. The tracer never wraps or swallows it.
///
/// Production implementations MUST NOT throw of their own accord
/// (trace/time rethrow the body's own error unchanged); srd5e does not catch.
/// The recording doubles in `testing.dart` throw `ArgumentError`/`StateError`
/// on misuse by design.
///
/// The shared contract suite lives in `test/contract/tracer_contract.dart` of
/// the srd5e repository. It is not exported (it needs `package:test`), but a
/// consumer can copy it to run against their own adapter.
abstract interface class Tracer {
  /// Runs [body] once inside a span called [name] and returns its value.
  ///
  /// [attributes] are on the span from the start. The body MUST NOT return a
  /// `Future`: use `traceAsync`, because the span would end before the future
  /// completes.
  T trace<T>(
    String name,
    T Function(Span span) body, {
    Attributes attributes = const {},
  });

  /// Runs [body] once inside a span called [name], ends the span when the
  /// returned future completes, and returns its value.
  ///
  /// A future that completes with an error is treated like a thrown one (see
  /// [Tracer]) and the same error propagates. A body that throws before it
  /// returns a future surfaces as a failed future: this method does not throw
  /// synchronously for it.
  Future<T> traceAsync<T>(
    String name,
    Future<T> Function(Span span) body, {
    Attributes attributes = const {},
  });
}

/// A [Span] that records nothing.
///
/// Every call is accepted at any time, including after the work has returned.
final class _NoopSpan implements Span {
  const _NoopSpan();

  @override
  void setAttribute(String key, Object value) {}

  @override
  void setStatus(SpanStatus status) {}

  @override
  void recordError(Object error, StackTrace stackTrace) {}
}

const Span _noopSpan = _NoopSpan();

/// A [Tracer] that traces nothing.
///
/// The default when no observability is injected. It is stateless and `const`.
/// It runs the body once with a span that ignores everything, returns the
/// result, lets any error propagate unchanged, reads no clock and does not
/// validate its arguments.
final class NoopTracer implements Tracer {
  /// Creates the silent tracer.
  const NoopTracer();

  @override
  T trace<T>(
    String name,
    T Function(Span span) body, {
    Attributes attributes = const {},
  }) => body(_noopSpan);

  @override
  Future<T> traceAsync<T>(
    String name,
    Future<T> Function(Span span) body, {
    Attributes attributes = const {},
  }) async => body(_noopSpan);
}
