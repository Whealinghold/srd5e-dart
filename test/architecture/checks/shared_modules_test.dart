import 'package:test/test.dart';

import '../support/real_repository.dart';
import '../support/source_set.dart';
import '../support/violation.dart';
import 'shared_modules.dart';

/// The repository, loaded once per test file and never mutated.
final SourceSet _repository = realRepository;

const Timeout _budget = Timeout(Duration(seconds: 10));

void _expectNone(List<Violation> violations) {
  expect(violations, isEmpty, reason: '\n${formatViolations(violations)}');
}

void main() {
  /// Requirement: doc/specs/architecture-guardrails.md FR-012, FR-023, FR-024
  ///   - a check must not pass vacuously: the real run finds files in both
  ///   shared modules.
  /// Path: unhappy (empty and minimal)
  test('the real repository has shared_kernel and shared_ports files', () {
    expect(_repository.dartPaths(sharedKernelPrefix), isNotEmpty);
    expect(_repository.dartPaths(sharedPortsPrefix), isNotEmpty);
  }, timeout: _budget);

  /// Requirement: doc/specs/architecture-guardrails.md FR-023 - a
  ///   shared_kernel file imports nothing in the package outside
  ///   shared_kernel.
  /// Path: happy
  test(
    'FR-023: shared_kernel imports nothing outside shared_kernel',
    () => _expectNone(checkSharedKernelImports(_repository)),
    timeout: _budget,
  );

  /// Requirement: doc/specs/architecture-guardrails.md FR-024 and
  ///   doc/specs/observability-ports.md FR-051 - a shared_ports file, adapters
  ///   included, imports only shared_kernel and shared_ports.
  /// Path: happy
  test(
    'FR-024: shared_ports imports only shared_kernel and itself',
    () => _expectNone(checkSharedPortsImports(_repository)),
    timeout: _budget,
  );
}
