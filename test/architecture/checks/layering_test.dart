import 'package:test/test.dart';

import '../support/real_repository.dart';
import '../support/source_set.dart';
import '../support/violation.dart';
import 'layering.dart';

/// The repository, loaded once per test file and never mutated.
final SourceSet _repository = realRepository;

const Timeout _budget = Timeout(Duration(seconds: 10));

void _expectNone(List<Violation> violations) {
  expect(violations, isEmpty, reason: '\n${formatViolations(violations)}');
}

void main() {
  /// Requirement: doc/specs/architecture-guardrails.md FR-017 - only
  ///   lib/adapters.dart and adapters/ files import an adapters/ folder
  ///   (architecture.md section 9, bullet 3).
  /// Path: happy
  test(
    'FR-017: nothing outside adapters/ imports an adapters/ folder',
    () => _expectNone(checkAdaptersImports(_repository)),
    timeout: _budget,
  );

  /// Requirement: doc/specs/architecture-guardrails.md FR-018 - a context
  ///   imports another context only through its barrel (architecture.md
  ///   section 9, bullet 8).
  /// Path: happy
  test(
    'FR-018: contexts import each other only through barrels',
    () => _expectNone(checkContextBarrelsOnly(_repository)),
    timeout: _budget,
  );

  /// Requirement: doc/specs/architecture-guardrails.md FR-019 - a context
  ///   imports only the barrels of its upstream contexts in the context map.
  /// Path: happy
  test(
    'FR-019: contexts import only upstream barrels',
    () => _expectNone(checkUpstreamBarrels(_repository)),
    timeout: _budget,
  );

  /// Requirement: doc/specs/architecture-guardrails.md FR-061 - nothing
  ///   under lib/src/ imports a core or platform entry point.
  /// Path: happy
  test(
    'FR-061: nothing under lib/src/ imports an entry point',
    () => _expectNone(checkNoEntryPointImports(_repository)),
    timeout: _budget,
  );

  /// Requirement: doc/specs/architecture-guardrails.md FR-080 - no file
  ///   imports its own context barrel.
  /// Path: happy
  test(
    'FR-080: no file imports its own barrel',
    () => _expectNone(checkNoOwnBarrelImports(_repository)),
    timeout: _budget,
  );
}
