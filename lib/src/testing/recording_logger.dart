import 'dart:collection' show UnmodifiableListView, UnmodifiableMapView;

import 'package:meta/meta.dart';

import '../shared_ports/observability/attributes.dart';
import '../shared_ports/observability/log_level.dart';
import '../shared_ports/observability/logger.dart';
import 'recording_support.dart';

/// One log event stored by a [RecordingLogger].
///
/// Immutable: [attributes] is an unmodifiable copy of what the logger's
/// attributes closure returned.
@immutable
final class LogRecord {
  /// Creates a record. Used by [RecordingLogger].
  LogRecord({
    required this.level,
    required this.message,
    required Attributes attributes,
    required this.error,
    required this.stackTrace,
  }) : attributes = UnmodifiableMapView(Map<String, Object>.of(attributes));

  /// The level the event was logged at.
  final LogLevel level;

  /// The constant message.
  final String message;

  /// The attributes the closure produced; empty when none was given.
  final Attributes attributes;

  /// The error passed to the call, if any.
  final Object? error;

  /// The stack trace passed to the call, if any.
  final StackTrace? stackTrace;
}

/// A test double [Logger] that stores every enabled log event.
///
/// Events below [minLevel] are not recorded and [isEnabled] says so. For each
/// recorded event the `attributes` closure is called exactly once and its map
/// is checked and copied; for a disabled event it is never called.
///
/// Throws an [ArgumentError] naming the key when an attribute value is not a
/// `String`, `bool`, `int` or `double`, so a bad attribute in a use case shows
/// up in its tests. The double is mutable: it accumulates records.
final class RecordingLogger implements Logger {
  /// Creates a logger that records events at [minLevel] and above.
  RecordingLogger({this.minLevel = LogLevel.finest});

  /// The lowest level that is recorded. Change it to simulate a configured
  /// log level.
  LogLevel minLevel;

  final List<LogRecord> _records = [];

  /// The recorded events, in call order. Unmodifiable.
  List<LogRecord> get records => UnmodifiableListView(_records);

  /// The recorded events at exactly [level], in call order. Unmodifiable.
  List<LogRecord> recordsAt(LogLevel level) => UnmodifiableListView([
    for (final record in _records)
      if (record.level == level) record,
  ]);

  /// Forgets the recorded events. [minLevel] is kept.
  void clear() => _records.clear();

  @override
  bool isEnabled(LogLevel level) => level.index >= minLevel.index;

  @override
  void log(
    LogLevel level,
    String message, {
    Attributes Function()? attributes,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!isEnabled(level)) return;
    final details = attributes == null
        ? const <String, Object>{}
        : copyAttributes(attributes());
    _records.add(
      LogRecord(
        level: level,
        message: message,
        attributes: details,
        error: error,
        stackTrace: stackTrace,
      ),
    );
  }
}
