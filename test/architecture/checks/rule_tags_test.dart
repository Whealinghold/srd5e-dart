import 'package:test/test.dart';

import '../support/real_repository.dart';
import '../support/source_set.dart';
import '../support/violation.dart';
import 'rule_tags.dart';

/// The repository, loaded once per test file and never mutated.
final SourceSet _repository = realRepository;

const Timeout _budget = Timeout(Duration(seconds: 10));

void _expectNone(List<Violation> violations) {
  expect(violations, isEmpty, reason: '\n${formatViolations(violations)}');
}

void main() {
  /// Requirement: doc/specs/architecture-guardrails.md FR-029 - a check must
  ///   not pass vacuously: the real repository has rule files.
  /// Path: unhappy (empty and minimal)
  test('the real repository has rule files', () {
    expect(ruleFilePaths(_repository), isNotEmpty);
  }, timeout: _budget);

  /// Requirement: doc/specs/architecture-guardrails.md FR-029 - each rule
  ///   file has exactly one well-formed tag line.
  /// Path: happy
  test(
    'FR-029: each doc/rules file has exactly one well-formed tag line',
    () => _expectNone(checkRuleTagShape(_repository)),
    timeout: _budget,
  );

  /// Requirement: doc/specs/architecture-guardrails.md FR-030 - a rule tag
  ///   value appears nowhere but on its own tag line.
  /// Path: happy
  test(
    'FR-030: no rule tag value is copied elsewhere',
    () => _expectNone(checkRuleTagsNotCopied(_repository)),
    timeout: _budget,
  );

  /// Requirement: doc/specs/architecture-guardrails.md FR-031 - every rule
  ///   file is listed in AGENTS.md and every listed path exists.
  /// Path: happy
  test(
    'FR-031: AGENTS.md lists exactly the existing rule files',
    () => _expectNone(checkRuleFilesListed(_repository)),
    timeout: _budget,
  );
}
