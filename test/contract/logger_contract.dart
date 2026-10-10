import 'package:srd5e/src/shared_ports/observability/attributes.dart';
import 'package:srd5e/src/shared_ports/observability/log_level.dart';
import 'package:srd5e/src/shared_ports/observability/logger.dart';
import 'package:test/test.dart';

/// Asserts that [logger] does not call the `attributes` closure for an event
/// at [disabledLevel], a level for which `isEnabled` is `false`
/// (`doc/specs/observability-ports.md` FR-006), with or without an error.
void expectSkipsAttributesWhenDisabled(
  Logger logger,
  LogLevel disabledLevel, {
  required bool withError,
}) {
  var calls = 0;
  Attributes probe() {
    calls++;
    return {'probe': 'called'};
  }

  expect(
    logger.isEnabled(disabledLevel),
    isFalse,
    reason: 'the harness must give a level that is disabled',
  );
  logger.log(
    disabledLevel,
    'event',
    attributes: probe,
    error: withError ? StateError('boom') : null,
    stackTrace: withError ? StackTrace.current : null,
  );

  expect(calls, 0, reason: 'FR-006: a disabled event builds no attributes');
}

/// Asserts that [logger] calls the `attributes` closure at most once for an
/// event at [enabledLevel], a level for which `isEnabled` is `true`.
void expectBuildsAttributesAtMostOnce(Logger logger, LogLevel enabledLevel) {
  var calls = 0;
  Attributes probe() {
    calls++;
    return {'probe': 'called'};
  }

  expect(logger.isEnabled(enabledLevel), isTrue);
  logger.log(enabledLevel, 'event', attributes: probe);

  expect(calls, lessThanOrEqualTo(1), reason: 'FR-006: closure called once');
}

/// Registers the shared `Logger` contract suite
/// (`doc/specs/observability-ports.md` FR-006 and FR-063) against the
/// implementation that [create] builds.
///
/// [create] must return a fresh logger each time. [disabledLevel] is a level
/// for which the logger's `isEnabled` is `false`. Pass [enabledLevel], a level
/// for which it is `true`, for an implementation that has one.
///
/// The suite is not exported by the package (it needs `package:test`); copy it
/// to run against your own adapter.
void loggerContract(
  String name,
  Logger Function() create, {
  required LogLevel disabledLevel,
  LogLevel? enabledLevel,
}) {
  /// Requirement: doc/specs/observability-ports.md FR-006 - the Logger port
  ///   contract holds for this implementation.
  /// Path: unhappy (collaborator: disabled level)
  group('Logger contract: $name', () {
    /// Requirement: doc/specs/observability-ports.md FR-006 - a disabled
    ///   event never calls the attributes closure.
    /// Path: unhappy (collaborator: disabled level)
    test('FR-006: a disabled level does not call the attributes closure', () {
      expectSkipsAttributesWhenDisabled(
        create(),
        disabledLevel,
        withError: false,
      );
    });

    /// Requirement: doc/specs/observability-ports.md FR-006 - a disabled
    ///   event with an error and stack trace does not call the closure either.
    /// Path: unhappy (collaborator: disabled level)
    test('FR-006: a disabled level with an error skips the closure too', () {
      expectSkipsAttributesWhenDisabled(
        create(),
        disabledLevel,
        withError: true,
      );
    });

    /// Requirement: doc/specs/observability-ports.md FR-006 - an event
    ///   without a closure is accepted at a disabled level.
    /// Path: unhappy (empty and minimal)
    test('FR-006: an event with no attributes is accepted when disabled', () {
      final logger = create();

      expect(() => logger.log(disabledLevel, 'event'), returnsNormally);
    });

    final enabled = enabledLevel;
    if (enabled != null) {
      /// Requirement: doc/specs/observability-ports.md FR-006 - an enabled
      ///   event calls the attributes closure at most once.
      /// Path: happy
      test('FR-006: an enabled level calls the closure at most once', () {
        expectBuildsAttributesAtMostOnce(create(), enabled);
      });
    }
  });
}
