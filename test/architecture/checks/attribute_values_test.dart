import 'package:test/test.dart';

import '../support/real_repository.dart';
import '../support/source_set.dart';
import '../support/violation.dart';
import 'attribute_values.dart';

/// The repository, loaded once per test file and never mutated.
final SourceSet _repository = realRepository;

const Timeout _budget = Timeout(Duration(seconds: 10));

void _expectNone(List<Violation> violations) {
  expect(violations, isEmpty, reason: '\n${formatViolations(violations)}');
}

void main() {
  /// Requirement: doc/specs/architecture-guardrails.md FR-085 - shared
  ///   attribute values on the real repository: every attribute value
  ///   constant in lib/ names its key and carries an allowed value, and every
  ///   value listed after a shared key in the catalogue is allowed.
  /// Path: happy
  test(
    'FR-085: attribute values in code and catalogue are allowed',
    () => _expectNone(checkAttributeValues(_repository)),
    timeout: _budget,
  );
}
