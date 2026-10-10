import 'package:srd5e/src/shared_ports/observability/attributes.dart';
import 'package:srd5e/src/shared_ports/observability/log_level.dart';
import 'package:srd5e/src/shared_ports/observability/logger.dart';
import 'package:test/test.dart';

import 'logger_contract.dart';

/// A logger that says a level is disabled but still builds the attributes.
final class _BuildsWhenDisabled implements Logger {
  @override
  bool isEnabled(LogLevel level) => false;

  @override
  void log(
    LogLevel level,
    String message, {
    Attributes Function()? attributes,
    Object? error,
    StackTrace? stackTrace,
  }) {
    attributes?.call();
  }
}

/// A logger that builds the attributes twice for an enabled event.
final class _BuildsTwice implements Logger {
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
    attributes?.call();
    attributes?.call();
  }
}

/// A logger that claims a level the harness said is disabled is enabled.
final class _AlwaysEnabled implements Logger {
  @override
  bool isEnabled(LogLevel level) => true;

  @override
  void log(
    LogLevel level,
    String message, {
    Attributes Function()? attributes,
    Object? error,
    StackTrace? stackTrace,
  }) {}
}

void main() {
  /// Requirement: doc/specs/observability-ports.md FR-006 and FR-063 - the
  ///   Logger contract suite must be able to fail: a logger that builds
  ///   attributes for a disabled event, or twice for an enabled one, makes its
  ///   checks fail.
  /// Path: unhappy (failure of collaborator)
  group('the Logger contract rejects a bad logger', () {
    /// Requirement: doc/specs/observability-ports.md FR-006 - building the
    ///   attributes of a disabled event is caught, with and without an error.
    /// Path: unhappy (collaborator: disabled level)
    test('a logger that builds attributes when disabled fails', () {
      for (final withError in [false, true]) {
        expect(
          () => expectSkipsAttributesWhenDisabled(
            _BuildsWhenDisabled(),
            LogLevel.fine,
            withError: withError,
          ),
          throwsA(isA<TestFailure>()),
        );
      }
    });

    /// Requirement: doc/specs/observability-ports.md FR-006 - a logger that
    ///   builds the attributes twice is caught.
    /// Path: unhappy (collaborator: enabled level)
    test('a logger that builds attributes twice fails', () {
      expect(
        () => expectBuildsAttributesAtMostOnce(_BuildsTwice(), LogLevel.fine),
        throwsA(isA<TestFailure>()),
      );
    });

    /// Requirement: doc/specs/observability-ports.md FR-006 - a harness whose
    ///   "disabled" level is in fact enabled is caught, so the check cannot
    ///   pass vacuously.
    /// Path: unhappy (invalid input)
    test('a logger for which the disabled level is enabled fails', () {
      expect(
        () => expectSkipsAttributesWhenDisabled(
          _AlwaysEnabled(),
          LogLevel.fine,
          withError: false,
        ),
        throwsA(isA<TestFailure>()),
      );
    });

    /// Requirement: doc/specs/observability-ports.md FR-006 - the same checks
    ///   pass for the real NoopLogger, so the cases above fail for the right
    ///   reason.
    /// Path: happy
    test('the real NoopLogger passes the same checks', () {
      expectSkipsAttributesWhenDisabled(
        const NoopLogger(),
        LogLevel.severe,
        withError: true,
      );
    });
  });
}
