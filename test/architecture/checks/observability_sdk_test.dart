import 'package:test/test.dart';

import '../support/real_repository.dart';
import '../support/source_set.dart';
import '../support/violation.dart';
import 'observability_sdk.dart';

/// The repository, loaded once per test file and never mutated.
final SourceSet _repository = realRepository;

const Timeout _budget = Timeout(Duration(seconds: 10));

void _expectNone(List<Violation> violations) {
  expect(violations, isEmpty, reason: '\n${formatViolations(violations)}');
}

void main() {
  /// Requirement: doc/specs/architecture-guardrails.md FR-032 - no file under
  ///   lib/ imports an observability or error-tracking SDK or dart:developer
  ///   (observability.md section 10, bullet 1).
  /// Path: happy
  test(
    'FR-032: no file under lib/ imports an observability SDK',
    () => _expectNone(checkNoObservabilitySdkImports(_repository)),
    timeout: _budget,
  );
}
