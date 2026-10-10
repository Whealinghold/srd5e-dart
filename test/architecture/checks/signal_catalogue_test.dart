import 'package:test/test.dart';

import '../support/real_repository.dart';
import '../support/source_set.dart';
import '../support/violation.dart';
import 'signal_catalogue.dart';

/// The repository, loaded once per test file and never mutated.
final SourceSet _repository = realRepository;

const Timeout _budget = Timeout(Duration(seconds: 10));

void _expectNone(List<Violation> violations) {
  expect(violations, isEmpty, reason: '\n${formatViolations(violations)}');
}

void main() {
  /// Requirement: doc/specs/architecture-guardrails.md FR-041 - the signal
  ///   catalogue has a table with the seven required header cells and
  ///   well-formed rows (observability.md section 2).
  /// Path: happy
  test(
    'FR-041: the catalogue table has the required header and rows',
    () => _expectNone(checkCatalogueTable(_repository)),
    timeout: _budget,
  );

  /// Requirement: doc/specs/architecture-guardrails.md FR-042 - every signal
  ///   constant in lib/ is a Name in the catalogue (observability.md
  ///   section 10, bullet 6).
  /// Path: happy
  test(
    'FR-042: every signal constant is in the catalogue',
    () => _expectNone(checkSignalsInCatalogue(_repository)),
    timeout: _budget,
  );

  /// Requirement: doc/specs/architecture-guardrails.md FR-043 - every
  ///   catalogue Name is a signal constant's value.
  /// Path: happy
  test(
    'FR-043: every catalogue Name is defined in code',
    () => _expectNone(checkCatalogueNamesInCode(_repository)),
    timeout: _budget,
  );

  /// Requirement: doc/specs/architecture-guardrails.md FR-044 - catalogue
  ///   Names are unique.
  /// Path: happy
  test(
    'FR-044: catalogue Names are unique',
    () => _expectNone(checkCatalogueNamesUnique(_repository)),
    timeout: _budget,
  );

  /// Requirement: doc/specs/architecture-guardrails.md FR-045 - no row has an
  ///   empty or placeholder Purpose.
  /// Path: happy
  test(
    'FR-045: every Purpose is filled in',
    () => _expectNone(checkCataloguePurpose(_repository)),
    timeout: _budget,
  );

  /// Requirement: doc/specs/architecture-guardrails.md FR-046 - no row has an
  ///   empty or placeholder Suggested monitoring.
  /// Path: happy
  test(
    'FR-046: every Suggested monitoring is filled in',
    () => _expectNone(checkCatalogueMonitoring(_repository)),
    timeout: _budget,
  );

  /// Requirement: doc/specs/architecture-guardrails.md FR-047 - every Type
  ///   starts with a known word and agrees with its constant's suffix.
  /// Path: happy
  test(
    'FR-047: every Type is valid and agrees with the code',
    () => _expectNone(checkCatalogueTypes(_repository)),
    timeout: _budget,
  );

  /// Requirement: doc/specs/architecture-guardrails.md FR-048 - attribute
  ///   constants and the catalogue's Attributes cells list the same keys.
  /// Path: happy
  test(
    'FR-048: attribute constants and catalogue attributes agree',
    () => _expectNone(checkCatalogueAttributes(_repository)),
    timeout: _budget,
  );
}
