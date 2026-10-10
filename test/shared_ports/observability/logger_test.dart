import 'package:srd5e/src/shared_ports/observability/attributes.dart';
import 'package:srd5e/src/shared_ports/observability/log_level.dart';
import 'package:srd5e/src/shared_ports/observability/logger.dart';
import 'package:test/test.dart';

/// One call received by [_CapturingLogger].
typedef _Call = ({
  LogLevel level,
  String message,
  Attributes Function()? attributes,
  Object? error,
  StackTrace? stackTrace,
});

/// A hand-written fake that implements [Logger] and keeps what it receives.
final class _CapturingLogger implements Logger {
  final List<_Call> calls = [];

  @override
  bool isEnabled(LogLevel level) => true;

  @override
  void log(
    LogLevel level,
    String message, {
    Attributes Function()? attributes,
    Object? error,
    StackTrace? stackTrace,
  }) {
    calls.add((
      level: level,
      message: message,
      attributes: attributes,
      error: error,
      stackTrace: stackTrace,
    ));
  }
}

typedef _NoopCase = ({String label, LogLevel level, bool withError});

final List<_NoopCase> _noopCases = [
  for (final level in LogLevel.values)
    for (final withError in [false, true])
      (
        label: '${level.name} ${withError ? 'with' : 'without'} an error',
        level: level,
        withError: withError,
      ),
];

typedef _ShortcutCase = ({
  String label,
  LogLevel level,
  void Function(
    Logger logger,
    String message,
    Attributes Function() attributes,
    Object error,
    StackTrace stackTrace,
  )
  call,
});

final List<_ShortcutCase> _shortcuts = [
  (
    label: 'finest',
    level: LogLevel.finest,
    call: (l, m, a, e, s) =>
        l.finest(m, attributes: a, error: e, stackTrace: s),
  ),
  (
    label: 'fine',
    level: LogLevel.fine,
    call: (l, m, a, e, s) => l.fine(m, attributes: a, error: e, stackTrace: s),
  ),
  (
    label: 'info',
    level: LogLevel.info,
    call: (l, m, a, e, s) => l.info(m, attributes: a, error: e, stackTrace: s),
  ),
  (
    label: 'warning',
    level: LogLevel.warning,
    call: (l, m, a, e, s) =>
        l.warning(m, attributes: a, error: e, stackTrace: s),
  ),
  (
    label: 'severe',
    level: LogLevel.severe,
    call: (l, m, a, e, s) =>
        l.severe(m, attributes: a, error: e, stackTrace: s),
  ),
];

void main() {
  /// Requirement: doc/specs/observability-ports.md FR-002 - Logger exposes
  ///   isEnabled and log, and a fake that implements it receives the closure,
  ///   error and stack trace intact.
  /// Path: happy
  group('Logger', () {
    /// Requirement: doc/specs/observability-ports.md FR-002 - log passes the
    ///   level, message, the closure itself (uncalled), the error and the
    ///   stack trace to the implementation.
    /// Path: happy
    test('log hands the closure, error and stack trace over intact', () {
      final logger = _CapturingLogger();
      Attributes closure() => {'k': 'v'};
      final error = StateError('boom');
      final stackTrace = StackTrace.fromString('trace');

      logger.log(
        LogLevel.warning,
        'something',
        attributes: closure,
        error: error,
        stackTrace: stackTrace,
      );

      final call = logger.calls.single;
      expect(call.level, LogLevel.warning);
      expect(call.message, 'something');
      expect(call.attributes, same(closure));
      expect(call.error, same(error));
      expect(call.stackTrace, same(stackTrace));
    });

    /// Requirement: doc/specs/observability-ports.md FR-002 - the attributes,
    ///   error and stack trace are optional.
    /// Path: unhappy (empty and minimal)
    test('log needs only a level and a message', () {
      final logger = _CapturingLogger();

      logger.log(LogLevel.info, 'bare');

      final call = logger.calls.single;
      expect(call.attributes, isNull);
      expect(call.error, isNull);
      expect(call.stackTrace, isNull);
    });
  });

  /// Requirement: doc/specs/observability-ports.md FR-003 and FR-004 -
  ///   NoopLogger is disabled at every level and does nothing, never calling
  ///   the attributes closure.
  /// Path: happy
  group('NoopLogger', () {
    /// Requirement: per case
    /// Path: per case
    for (final c in _noopCases) {
      test('FR-003/FR-004: is disabled and silent at ${c.label} '
          '[unhappy (collaborator: disabled level)]', () {
        const logger = NoopLogger();
        var closureCalls = 0;
        Attributes closure() {
          closureCalls++;
          return {'k': 'v'};
        }

        final enabled = logger.isEnabled(c.level);
        logger.log(
          c.level,
          'event',
          attributes: closure,
          error: c.withError ? StateError('boom') : null,
          stackTrace: c.withError ? StackTrace.current : null,
        );

        expect(enabled, isFalse);
        expect(closureCalls, 0);
      });
    }

    /// Requirement: doc/specs/observability-ports.md FR-042 - the no-op is
    ///   `const` and stateless, so every instance is the same object.
    /// Path: happy
    test('FR-004: const instances are canonical', () {
      expect(identical(const NoopLogger(), const NoopLogger()), isTrue);
    });
  });

  /// Requirement: doc/specs/observability-ports.md FR-005 - each level
  ///   shortcut of LoggerLevels delegates to log with the matching level and
  ///   passes message, attributes, error and stack trace through unchanged.
  /// Path: happy
  group('LoggerLevels', () {
    /// Requirement: per case
    /// Path: per case
    for (final c in _shortcuts) {
      test('FR-005: ${c.label} delegates to log at ${c.label} [happy]', () {
        final logger = _CapturingLogger();
        Attributes closure() => {'k': 'v'};
        final error = StateError('boom');
        final stackTrace = StackTrace.fromString('trace');

        c.call(logger, 'message', closure, error, stackTrace);

        final call = logger.calls.single;
        expect(call.level, c.level);
        expect(call.message, 'message');
        expect(call.attributes, same(closure));
        expect(call.error, same(error));
        expect(call.stackTrace, same(stackTrace));
      });
    }

    /// Requirement: doc/specs/observability-ports.md FR-005 - the optional
    ///   arguments stay null when the shortcut is called without them.
    /// Path: unhappy (empty and minimal)
    test('FR-005: a shortcut with only a message passes nulls', () {
      final logger = _CapturingLogger();

      logger.fine('message');

      final call = logger.calls.single;
      expect(call.attributes, isNull);
      expect(call.error, isNull);
      expect(call.stackTrace, isNull);
    });
  });
}
