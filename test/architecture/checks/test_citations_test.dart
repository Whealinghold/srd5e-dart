import 'package:test/test.dart';

import '../support/real_repository.dart';
import '../support/source_set.dart';
import '../support/violation.dart';
import 'test_citations.dart';

/// The repository, loaded once per test file and never mutated.
final SourceSet _repository = realRepository;

const Timeout _budget = Timeout(Duration(seconds: 10));

void _expectNone(List<Violation> violations) {
  expect(violations, isEmpty, reason: '\n${formatViolations(violations)}');
}

void main() {
  /// Requirement: doc/specs/architecture-guardrails.md FR-012 - a check must
  ///   not pass vacuously: the real repository has Dart tests and specs.
  /// Path: unhappy (empty and minimal)
  test('the real repository has tests and specs to scan', () {
    expect(_repository.dartPaths('test/'), isNotEmpty);
    expect(specFilePaths(_repository), isNotEmpty);
  }, timeout: _budget);

  /// Requirement: doc/specs/architecture-guardrails.md FR-049 - every group
  ///   and test outside test/architecture has a Requirement or Rule comment.
  /// Path: happy
  test(
    'FR-049: every test and group outside test/architecture is cited',
    () => _expectNone(checkTestsHaveRequirementComment(_repository)),
    timeout: _budget,
  );

  /// Requirement: doc/specs/architecture-guardrails.md FR-050 - a none
  ///   citation always states a reason, and no citation is empty.
  /// Path: happy
  test(
    'FR-050: Requirement: none always carries a reason',
    () => _expectNone(checkNoneHasReason(_repository)),
    timeout: _budget,
  );

  /// Requirement: doc/specs/architecture-guardrails.md FR-051 - tests inside
  ///   loops are covered by a per case loop comment.
  /// Path: happy
  test(
    'FR-051: a test in a loop is covered by a per case loop comment',
    () => _expectNone(checkLoopCommentIsPerCase(_repository)),
    timeout: _budget,
  );

  /// Requirement: doc/specs/architecture-guardrails.md FR-052 - per case
  ///   appears only above a loop with tests or a group holding one.
  /// Path: happy
  test(
    'FR-052: Requirement: per case sits only above loops of tests',
    () => _expectNone(checkPerCaseOnlyOnLoops(_repository)),
    timeout: _budget,
  );

  /// Requirement: doc/specs/architecture-guardrails.md FR-053 - every
  ///   Requirement comment has a valid Path line.
  /// Path: happy
  test(
    'FR-053: every Requirement comment carries a valid Path',
    () => _expectNone(checkRequirementHasPath(_repository)),
    timeout: _budget,
  );

  /// Requirement: doc/specs/architecture-guardrails.md FR-054 - every
  ///   citation names an existing spec and ids present in its table.
  /// Path: happy
  test(
    'FR-054: every citation resolves to a spec and its ids',
    () => _expectNone(checkCitationsResolve(_repository)),
    timeout: _budget,
  );

  /// Requirement: doc/specs/architecture-guardrails.md FR-055 - every id of an
  ///   implemented spec is cited by a test or deliberately not covered.
  /// Path: happy
  test(
    'FR-055: every id of an implemented spec is covered',
    () => _expectNone(checkImplementedSpecsAreCovered(_repository)),
    timeout: _budget,
  );

  /// Requirement: doc/specs/architecture-guardrails.md FR-056 - every spec has
  ///   a Status of draft, accepted or implemented.
  /// Path: happy
  test(
    'FR-056: every spec Status is draft, accepted or implemented',
    () => _expectNone(checkSpecStatusValue(_repository)),
    timeout: _budget,
  );
}
