/// The severity of a log event, in ascending order.
///
/// The levels map onto `package:logging` (`FINEST`, `FINE`, `INFO`, `WARNING`,
/// `SEVERE`) and onto OpenTelemetry severity (trace, debug, info, warn,
/// error). There is no level above [severe]: this package never logs at
/// `SHOUT` or `fatal`.
enum LogLevel {
  /// Step-by-step detail useful only when chasing a specific bug. Off by
  /// default and cheap when off.
  finest,

  /// Normal operation details a developer wants while debugging.
  fine,

  /// A significant lifecycle event. Rare; never emitted per call.
  info,

  /// Something is wrong but handled; the result is valid but possibly not what
  /// was intended.
  warning,

  /// An operation failed and the failure is not surfaced to the caller as a
  /// thrown exception or a failure result.
  severe,
}
