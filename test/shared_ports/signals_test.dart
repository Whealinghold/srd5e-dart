import 'package:srd5e/src/shared_ports/signals.dart';
import 'package:test/test.dart';

void main() {
  /// Requirement: doc/specs/observability-ports.md FR-052 - AttributeKeys
  ///   pins the two shared attribute keys and their string values, which are
  ///   part of the public contract.
  /// Path: happy
  group('AttributeKeys', () {
    /// Requirement: doc/specs/observability-ports.md FR-052 - outcome is
    ///   srd5e.outcome.
    /// Path: happy
    test('outcome is "srd5e.outcome"', () {
      expect(AttributeKeys.outcome, 'srd5e.outcome');
    });

    /// Requirement: doc/specs/observability-ports.md FR-052 - errorType is
    ///   error.type (OpenTelemetry's key).
    /// Path: happy
    test('errorType is "error.type"', () {
      expect(AttributeKeys.errorType, 'error.type');
    });
  });
}
