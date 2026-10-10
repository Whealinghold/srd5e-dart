import 'package:test/test.dart';

import '../support/real_repository.dart';
import '../support/source_set.dart';
import '../support/violation.dart';
import 'test_hygiene.dart';

/// The repository, loaded once per test file and never mutated.
final SourceSet _repository = realRepository;

const Timeout _budget = Timeout(Duration(seconds: 10));

void main() {
  /// Requirement: doc/specs/architecture-guardrails.md FR-012 - a check must
  ///   not pass vacuously: the real repository has Dart tests to scan.
  /// Path: unhappy (empty and minimal)
  test('the real repository has Dart tests', () {
    expect(_repository.dartPaths('test/'), isNotEmpty);
  }, timeout: _budget);

  /// Requirement: doc/specs/architecture-guardrails.md FR-086 - no
  ///   commented-out test code and no skip without an Issue line.
  /// Path: happy
  test('FR-086: no commented-out or unexplained skipped tests', () {
    final violations = checkNoCommentedOutOrSkippedTests(_repository);

    expect(violations, isEmpty, reason: '\n${formatViolations(violations)}');
  }, timeout: _budget);
}
