import 'package:test/test.dart';

import '../support/real_repository.dart';
import '../support/source_set.dart';
import '../support/violation.dart';
import 'embedded_content.dart';

/// The repository, loaded once per test file and never mutated.
final SourceSet _repository = realRepository;

const Timeout _budget = Timeout(Duration(seconds: 10));

void main() {
  /// Requirement: doc/specs/architecture-guardrails.md FR-078 - the drift
  ///   check on the real repository. The generator in `tool/` does not exist
  ///   yet, so the real wiring passes `null` (plan decision D3) and the check
  ///   passes vacuously until the change that adds it imports it.
  /// Path: happy
  test(
    'FR-078: embedded libraries match the generator (null until tool/ has one)',
    () {
      final violations = checkEmbeddedContent(_repository, null);
      expect(violations, isEmpty, reason: '\n${formatViolations(violations)}');
    },
    timeout: _budget,
  );
}
