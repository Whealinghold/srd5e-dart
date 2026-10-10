import 'package:srd5e/src/shared_ports/observability/log_level.dart';
import 'package:test/test.dart';

void main() {
  /// Requirement: doc/specs/observability-ports.md FR-001 - LogLevel has
  ///   exactly finest, fine, info, warning and severe, in ascending severity,
  ///   and no shout or fatal value.
  /// Path: happy
  group('LogLevel', () {
    /// Requirement: doc/specs/observability-ports.md FR-001 - the five values
    ///   in ascending severity.
    /// Path: happy
    test('has finest, fine, info, warning, severe in that order', () {
      expect(LogLevel.values, [
        LogLevel.finest,
        LogLevel.fine,
        LogLevel.info,
        LogLevel.warning,
        LogLevel.severe,
      ]);
    });

    /// Requirement: doc/specs/observability-ports.md FR-001 - no shout or
    ///   fatal value; the set is closed at five.
    /// Path: unhappy (boundary)
    test('has no level above severe', () {
      expect(LogLevel.values, hasLength(5));
      expect(
        LogLevel.values.map((level) => level.name),
        isNot(contains('shout')),
      );
      expect(
        LogLevel.values.map((level) => level.name),
        isNot(contains('fatal')),
      );
    });

    /// Requirement: doc/specs/observability-ports.md FR-001 - ascending
    ///   severity is the declaration order, so index comparison is level
    ///   comparison.
    /// Path: unhappy (boundary)
    test('each level is more severe than the one before', () {
      for (var i = 1; i < LogLevel.values.length; i++) {
        expect(
          LogLevel.values[i].index,
          greaterThan(LogLevel.values[i - 1].index),
        );
      }
    });
  });
}
