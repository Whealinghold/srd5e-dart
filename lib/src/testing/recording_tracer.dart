import 'dart:collection' show UnmodifiableListView, UnmodifiableMapView;

import '../shared_ports/observability/attributes.dart';
import '../shared_ports/observability/tracer.dart';
import 'recording_support.dart';

/// One span stored by a [RecordingTracer].
///
/// It is written only through its recording span and only while the span is
/// open; once the span has ended it no longer changes. Read it after the work
/// has returned to see the final state.
final class SpanRecord {
  SpanRecord._(this.name, this.parent, Map<String, Object> attributes)
    : _attributes = attributes;

  /// The span name.
  final String name;

  /// The span this one was started inside, or `null` for a top-level span.
  final SpanRecord? parent;

  final Map<String, Object> _attributes;
  final List<(Object, StackTrace)> _errors = [];
  SpanStatus _status = SpanStatus.unset;
  bool _ended = false;

  /// The attributes the span started with plus any set later. Unmodifiable.
  Attributes get attributes => UnmodifiableMapView(_attributes);

  /// The status: [SpanStatus.unset] until something sets it.
  SpanStatus get status => _status;

  /// The errors recorded on the span, in call order. Unmodifiable.
  List<(Object error, StackTrace stackTrace)> get errors =>
      UnmodifiableListView(_errors);

  /// Whether the span has ended.
  bool get ended => _ended;
}

/// The [Span] a [RecordingTracer] hands to its body. It writes its record
/// until the span ends, then throws a [StateError] on any further write.
final class _RecordingSpan implements Span {
  _RecordingSpan(this.record);

  final SpanRecord record;

  void _requireOpen(String operation) {
    if (record._ended) {
      throw StateError(
        '$operation was called on span ${record.name}, which has ended.',
      );
    }
  }

  @override
  void setAttribute(String key, Object value) {
    _requireOpen('setAttribute');
    requireAttributeValue(key, value);
    record._attributes[key] = value;
  }

  @override
  void setStatus(SpanStatus status) {
    _requireOpen('setStatus');
    record._status = status;
  }

  @override
  void recordError(Object error, StackTrace stackTrace) {
    _requireOpen('recordError');
    record._errors.add((error, stackTrace));
  }
}

/// A test double [Tracer] that stores one [SpanRecord] per span.
///
/// A span is writable from its start until its work finishes (or, for
/// `traceAsync`, until the future completes); after that its mutators throw a
/// [StateError]. A name that is not `srd5e.<context>.<noun>` (lowercase, at
/// least three dot-separated parts, each starting with a letter) throws an
/// [ArgumentError] before the body runs, as does an attribute value that is not
/// a `String`, `bool`, `int` or `double`. On a thrown error the span gets the
/// status [SpanStatus.error], the error and its stack trace, ends, and the same
/// error propagates.
///
/// A span started inside another records it as its [SpanRecord.parent]. That is
/// correct for nested synchronous use and sequential asynchronous use;
/// interleaved concurrent `traceAsync` calls are not supported, because real
/// context linkage is the consumer adapter's job. No duration is recorded: that
/// would need a clock.
final class RecordingTracer implements Tracer {
  /// Creates a tracer with no spans.
  RecordingTracer();

  final List<SpanRecord> _spans = [];
  final List<SpanRecord> _open = [];

  /// The spans started so far, in start order (a parent precedes its
  /// children). Unmodifiable.
  List<SpanRecord> get spans => UnmodifiableListView(_spans);

  /// The spans called [name], in start order. Unmodifiable.
  List<SpanRecord> spansNamed(String name) => UnmodifiableListView([
    for (final span in _spans)
      if (span.name == name) span,
  ]);

  /// Forgets the recorded spans.
  void clear() => _spans.clear();

  _RecordingSpan _start(String name, Attributes attributes) {
    requireSignalName(name, 'name');
    final record = SpanRecord._(
      name,
      _open.isEmpty ? null : _open.last,
      copyAttributes(attributes),
    );
    _spans.add(record);
    _open.add(record);
    return _RecordingSpan(record);
  }

  void _end(_RecordingSpan span) {
    span.record._ended = true;
    _open.remove(span.record);
  }

  @override
  T trace<T>(
    String name,
    T Function(Span span) body, {
    Attributes attributes = const {},
  }) {
    final span = _start(name, attributes);
    try {
      return body(span);
    } catch (error, stackTrace) {
      span.setStatus(SpanStatus.error);
      span.recordError(error, stackTrace);
      rethrow;
    } finally {
      _end(span);
    }
  }

  @override
  Future<T> traceAsync<T>(
    String name,
    Future<T> Function(Span span) body, {
    Attributes attributes = const {},
  }) => _traceAsync(_start(name, attributes), body);

  Future<T> _traceAsync<T>(
    _RecordingSpan span,
    Future<T> Function(Span span) body,
  ) async {
    try {
      return await body(span);
    } catch (error, stackTrace) {
      span.setStatus(SpanStatus.error);
      span.recordError(error, stackTrace);
      rethrow;
    } finally {
      _end(span);
    }
  }
}
