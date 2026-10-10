import 'package:test/test.dart';

import '../support/real_repository.dart';
import '../support/source_set.dart';
import '../support/violation.dart';
import 'domain_observability.dart';

/// The repository, loaded once per test file and never mutated.
final SourceSet _repository = realRepository;

const Timeout _budget = Timeout(Duration(seconds: 10));

void _expectNone(List<Violation> violations) {
  expect(violations, isEmpty, reason: '\n${formatViolations(violations)}');
}

void main() {
  /// Requirement: doc/specs/architecture-guardrails.md FR-034 - no domain/
  ///   file mentions a logger, tracer, meter or observability identifier
  ///   (observability.md section 10, bullet 2).
  /// Path: happy
  test(
    'FR-034: no domain file mentions telemetry',
    () => _expectNone(checkDomainHasNoObservability(_repository)),
    timeout: _budget,
  );
}
