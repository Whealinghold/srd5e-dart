import 'package:test/test.dart';

import '../support/real_repository.dart';
import '../support/source_set.dart';
import '../support/violation.dart';
import 'ability_conventions.dart';

/// The repository, loaded once per test file and never mutated.
final SourceSet _repository = realRepository;

const Timeout _budget = Timeout(Duration(seconds: 10));

void main() {
  /// Requirement: doc/specs/architecture-guardrails.md FR-012 - a check must
  ///   not pass vacuously: the ability files it scans must exist.
  /// Path: unhappy (empty and minimal)
  test('the ability scope finds the four ability files', () {
    expect(
      _repository.files.keys,
      containsAll([
        'lib/src/shared_kernel/ability/ability.dart',
        'lib/src/shared_kernel/ability/ability_score.dart',
        'lib/src/shared_kernel/ability/ability_score_result.dart',
        'lib/src/shared_kernel/ability/ability_scores.dart',
      ]),
    );
  }, timeout: _budget);

  /// Requirement: doc/specs/ability-scores.md FR-026 - A1 on the real
  ///   repository: AbilityScoreRejection and the other ability names are
  ///   exported exactly once from lib/srd5e.dart, and no generic
  ///   BelowMinimum or AboveMaximum is exported.
  /// Path: happy
  test('A1: the ability names are exported once, with no generic names', () {
    final violations = checkAbilityEntryPoints(_repository);

    expect(violations, isEmpty, reason: '\n${formatViolations(violations)}');
  }, timeout: _budget);
}
