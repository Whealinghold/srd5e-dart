import 'attributes.dart';
import 'log_level.dart';

/// The driven port through which srd5e emits log events.
///
/// A log event is a [LogLevel], a constant [message], structured attributes and
/// optionally an error with its stack trace. The attributes are supplied as a
/// closure that the logger calls only when the event is enabled, so building
/// them costs nothing when the level is off. Call [isEnabled] first only when
/// the work to prepare the call is expensive in itself.
///
/// The port is synchronous. An implementation must not call the `attributes`
/// closure when [isEnabled] is `false` for that call.
///
/// Production implementations MUST NOT throw of their own accord
/// (trace/time rethrow the body's own error unchanged); srd5e does not catch.
/// The recording doubles in `testing.dart` throw `ArgumentError`/`StateError`
/// on misuse by design.
///
/// The shared contract suite lives in `test/contract/logger_contract.dart` of
/// the srd5e repository. It is not exported (it needs `package:test`), but a
/// consumer can copy it to run against their own adapter.
abstract interface class Logger {
  /// Whether an event at [level] would be recorded.
  bool isEnabled(LogLevel level);

  /// Emits a log event.
  ///
  /// [message] is a short constant. Details go in [attributes], a closure
  /// called at most once, and only when [isEnabled] is `true` for [level].
  /// [error] and [stackTrace] describe a failure that the event reports.
  void log(
    LogLevel level,
    String message, {
    Attributes Function()? attributes,
    Object? error,
    StackTrace? stackTrace,
  });
}

/// Shortcuts that call [Logger.log] at a fixed [LogLevel].
///
/// Each shortcut passes [message], `attributes`, `error` and `stackTrace`
/// through unchanged.
extension LoggerLevels on Logger {
  /// Logs [message] at [LogLevel.finest].
  void finest(
    String message, {
    Attributes Function()? attributes,
    Object? error,
    StackTrace? stackTrace,
  }) => log(
    LogLevel.finest,
    message,
    attributes: attributes,
    error: error,
    stackTrace: stackTrace,
  );

  /// Logs [message] at [LogLevel.fine].
  void fine(
    String message, {
    Attributes Function()? attributes,
    Object? error,
    StackTrace? stackTrace,
  }) => log(
    LogLevel.fine,
    message,
    attributes: attributes,
    error: error,
    stackTrace: stackTrace,
  );

  /// Logs [message] at [LogLevel.info].
  void info(
    String message, {
    Attributes Function()? attributes,
    Object? error,
    StackTrace? stackTrace,
  }) => log(
    LogLevel.info,
    message,
    attributes: attributes,
    error: error,
    stackTrace: stackTrace,
  );

  /// Logs [message] at [LogLevel.warning].
  void warning(
    String message, {
    Attributes Function()? attributes,
    Object? error,
    StackTrace? stackTrace,
  }) => log(
    LogLevel.warning,
    message,
    attributes: attributes,
    error: error,
    stackTrace: stackTrace,
  );

  /// Logs [message] at [LogLevel.severe].
  void severe(
    String message, {
    Attributes Function()? attributes,
    Object? error,
    StackTrace? stackTrace,
  }) => log(
    LogLevel.severe,
    message,
    attributes: attributes,
    error: error,
    stackTrace: stackTrace,
  );
}

/// A [Logger] that logs nothing.
///
/// The default when no observability is injected. It is stateless and `const`,
/// has no level enabled, never calls the `attributes` closure and does not
/// validate its arguments.
final class NoopLogger implements Logger {
  /// Creates the silent logger.
  const NoopLogger();

  @override
  bool isEnabled(LogLevel level) => false;

  @override
  void log(
    LogLevel level,
    String message, {
    Attributes Function()? attributes,
    Object? error,
    StackTrace? stackTrace,
  }) {}
}
