import 'package:test/test.dart';

import '../support/real_repository.dart';
import '../support/source_set.dart';
import '../support/violation.dart';
import 'spec_conformance.dart';

/// The repository, loaded once per test file and never mutated.
final SourceSet _repository = realRepository;

const Timeout _budget = Timeout(Duration(seconds: 10));

void main() {
  /// Requirement: doc/specs/architecture-guardrails.md FR-088, FR-089,
  ///   FR-090, FR-092, FR-096, FR-099, FR-100, FR-101 and FR-102 - the
  ///   specification checks on the actual doc/specs/ and documentation index.
  /// Path: happy
  group('specification checks on the real repository', () {
    /// Requirement: doc/specs/architecture-guardrails.md FR-012 - a check
    ///   must not pass vacuously: the specs and the index exist.
    /// Path: unhappy (empty and minimal)
    test('the repository holds specs, the rank table and the index', () {
      final specs = _repository.paths(prefix: 'doc/specs/', suffix: '.md');

      expect(specs.length, greaterThan(10));
      expect(specs, contains('doc/specs/shared-types-and-ownership.md'));
      expect(_repository.files.keys, contains('doc/documentation_index.md'));
    }, timeout: _budget);

    /// Requirement: per case - doc/specs/architecture-guardrails.md FR-088,
    ///   FR-089, FR-090, FR-092, FR-096, FR-099, FR-100, FR-101 and FR-102
    ///   - each check id on the real repository.
    /// Path: per case
    for (final entry in specConformanceChecks.entries) {
      test('${entry.key} holds on the real repository', () {
        final violations = entry.value(_repository);

        expect(
          violations,
          isEmpty,
          reason: '\n${formatViolations(violations)}',
        );
      }, timeout: _budget);
    }
  }, timeout: _budget);
}
