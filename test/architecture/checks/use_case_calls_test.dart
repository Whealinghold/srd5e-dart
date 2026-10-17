import 'package:test/test.dart';

import '../support/real_repository.dart';
import '../support/source_set.dart';
import '../support/violation.dart';
import 'use_case_calls.dart';

/// The repository, loaded once per test file and never mutated.
final SourceSet _repository = realRepository;

const Timeout _budget = Timeout(Duration(seconds: 10));

void _expectNone(List<Violation> violations) {
  expect(violations, isEmpty, reason: '\n${formatViolations(violations)}');
}

void main() {
  /// Requirement: doc/specs/architecture-guardrails.md FR-012, FR-097 - the
  ///   scan reads real source: lib/src/ holds Dart files. No context has an
  ///   application/ folder with code yet, so the use case set may be empty;
  ///   the self-test fixtures prove the check fires.
  /// Path: unhappy (empty and minimal)
  test('the real repository has Dart source for the scan to read', () {
    expect(_repository.dartPaths('lib/src/'), isNotEmpty);
    expect(useCaseClasses(_repository), isA<List<UseCaseClass>>());
  }, timeout: _budget);

  /// Requirement: doc/specs/architecture-guardrails.md FR-097 - no file
  ///   under
  ///   application/ or domain/ mentions a use case declared in another
  ///   file; the same scan enforces doc/specs/content-schema-and-decoder.md
  ///   FR-131 - LoadContentSet calls no other use case.
  /// Path: happy
  test(
    'FR-097: no use case calls another use case',
    () => _expectNone(checkNoUseCaseCalls(_repository)),
    timeout: _budget,
  );
}
