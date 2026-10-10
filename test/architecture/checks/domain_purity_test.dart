import 'package:test/test.dart';

import '../support/real_repository.dart';
import '../support/source_set.dart';
import '../support/violation.dart';
import 'domain_purity.dart';

/// The repository, loaded once per test file and never mutated.
final SourceSet _repository = realRepository;

const Timeout _budget = Timeout(Duration(seconds: 10));

void _expectNone(List<Violation> violations) {
  expect(violations, isEmpty, reason: '\n${formatViolations(violations)}');
}

void main() {
  /// Requirement: doc/specs/architecture-guardrails.md FR-015 - no domain/
  ///   file imports application/, adapters/, shared_ports/, dart:async or
  ///   dart:developer (architecture.md section 9, bullet 2).
  /// Path: happy
  test(
    'FR-015: no domain file imports an outer layer or an async library',
    () => _expectNone(checkDomainImports(_repository)),
    timeout: _budget,
  );

  /// Requirement: doc/specs/architecture-guardrails.md FR-016 - no domain/
  ///   file contains async, await, Future, Stream or their relatives
  ///   (architecture.md section 9, bullet 2).
  /// Path: happy
  test(
    'FR-016: no domain file uses async code',
    () => _expectNone(checkDomainTokens(_repository)),
    timeout: _budget,
  );
}
