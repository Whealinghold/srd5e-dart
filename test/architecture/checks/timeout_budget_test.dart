import 'package:test/test.dart';

import '../support/real_repository.dart';
import '../support/source_set.dart';
import '../support/violation.dart';
import 'timeout_budget.dart';

/// The repository, loaded once per test file and never mutated.
final SourceSet _repository = realRepository;

const Timeout _budget = Timeout(Duration(seconds: 10));

void main() {
  /// Requirement: doc/specs/architecture-guardrails.md FR-012 - a check must
  ///   not pass vacuously: the real repository has test files to scan, and
  ///   some of them read the real repository.
  /// Path: unhappy (empty and minimal)
  test('the real repository has real-repository test files', () {
    final readers = _repository
        .dartPaths('test/architecture/checks/')
        .where((p) => p.endsWith('_test.dart'))
        .where((p) => _repository.lexed(p).code.contains('realRepository'));

    expect(readers, isNotEmpty);
  }, timeout: _budget);

  /// Requirement: doc/specs/architecture-guardrails.md FR-073 - every
  ///   real-repository test group declares the 10 second Timeout.
  /// Path: happy
  test(
    'FR-073: every real-repository group declares the 10 second Timeout',
    () {
      final violations = checkRealRepositoryTimeouts(_repository);

      expect(violations, isEmpty, reason: '\n${formatViolations(violations)}');
    },
    timeout: _budget,
  );
}
