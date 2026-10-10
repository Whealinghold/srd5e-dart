import 'package:test/test.dart';

import '../support/real_repository.dart';
import '../support/source_set.dart';
import '../support/violation.dart';
import 'noop_classes.dart';

/// The repository, loaded once per test file and never mutated.
final SourceSet _repository = realRepository;

const Timeout _budget = Timeout(Duration(seconds: 10));

void _expectNone(List<Violation> violations) {
  expect(violations, isEmpty, reason: '\n${formatViolations(violations)}');
}

void main() {
  /// Requirement: doc/specs/architecture-guardrails.md FR-012, FR-084,
  ///   FR-104 - a check must not pass vacuously: the real run finds the
  ///   no-op classes and the observability bundle.
  /// Path: unhappy (empty and minimal)
  test('the real repository declares the no-ops and the bundle', () {
    final text = _repository.files['${observabilityPrefix}observability.dart']!;

    expect(text, contains('final class Observability'));
    expect(text, contains('final class NoopObservability'));
    expect(
      _repository.files['${observabilityPrefix}logger.dart'],
      contains('class NoopLogger'),
    );
  }, timeout: _budget);

  /// Requirement: doc/specs/architecture-guardrails.md FR-035 and
  ///   doc/specs/observability-ports.md FR-051, FR-059 - no top-level or static
  ///   logger, tracer, meter or observability bundle unless const
  ///   (observability.md section 10, bullet 4).
  /// Path: happy
  test(
    'FR-035: no global logger, tracer or meter',
    () => _expectNone(checkNoGlobalObservability(_repository)),
    timeout: _budget,
  );

  /// Requirement: doc/specs/architecture-guardrails.md FR-084 and
  ///   doc/specs/observability-ports.md FR-051 - every Noop class lives in
  ///   shared_ports/, outside adapters/, with only const constructors
  ///   (observability.md section 10).
  /// Path: happy
  test(
    'FR-084: every Noop class is a const class in shared_ports',
    () => _expectNone(checkNoopClasses(_repository)),
    timeout: _budget,
  );

  /// Requirement: doc/specs/architecture-guardrails.md FR-104 - Observability
  ///   and NoopObservability are final classes in one file, Observability is
  ///   @immutable, NoopObservability extends it with const constructors.
  /// Path: happy
  test(
    'FR-104: Observability and NoopObservability are sealed by final',
    () => _expectNone(checkObservabilityClasses(_repository)),
    timeout: _budget,
  );
}
