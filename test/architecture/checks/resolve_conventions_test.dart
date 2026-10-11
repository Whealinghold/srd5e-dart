import 'package:test/test.dart';

import '../support/declarations.dart';
import '../support/real_repository.dart';
import '../support/source_set.dart';
import '../support/violation.dart';
import 'resolve_conventions.dart';
import 'use_case_calls.dart';

/// The repository, loaded once per test file and never mutated.
final SourceSet _repository = realRepository;

const Timeout _budget = Timeout(Duration(seconds: 10));

void _expectNone(List<Violation> violations) {
  expect(violations, isEmpty, reason: '\n${formatViolations(violations)}');
}

void main() {
  /// Requirement: doc/specs/resolve-d20-test-use-case.md FR-044 - a check
  ///   must not pass vacuously: the real repository holds result
  ///   declarations under lib/src/d20_test/ for the scan to read.
  /// Path: unhappy (empty and minimal)
  test('the scan is not vacuous: result declarations exist', () {
    final resultClasses = [
      for (final path in _repository.dartPaths('lib/src/d20_test/'))
        for (final declaration in declarationsIn(path, _repository.lexed(path)))
          if (isResultDeclaration(declaration.name)) declaration.name,
    ];

    expect(
      resultClasses,
      containsAll(<String>[
        'CheckResult',
        'AttackRollResult',
        'ForcedFailureResult',
        'ResolveD20TestResult',
        'ResolveD20TestRolledCheck',
        'ResolveD20TestRolledAttack',
        'ResolveD20TestForcedFailure',
      ]),
    );
  }, timeout: _budget);

  /// Requirement: doc/specs/resolve-d20-test-use-case.md FR-044 - R1 on the
  ///   real repository: no result declaration under lib/src/d20_test/ has a
  ///   String field or getter.
  /// Path: happy
  test(
    'R1: no String field or getter in the result declarations',
    () => _expectNone(checkResultsCarryNoStrings(_repository)),
    timeout: _budget,
  );

  /// Requirement: doc/specs/resolve-d20-test-use-case.md FR-045 - R2 on the
  ///   real repository: the application folder holds no mutable top-level or
  ///   static state. The Random, DateTime and Stopwatch claims are enforced
  ///   by the FR-027 check, adapter construction by FR-017, a recording
  ///   Observability by FR-074, and observability-typed statics by FR-035;
  ///   their own tests run in this suite.
  /// Path: happy
  test(
    'R2: no hidden mutable state in the application folder',
    () => _expectNone(checkApplicationFolderPurity(_repository)),
    timeout: _budget,
  );

  /// Requirement: doc/specs/resolve-d20-test-use-case.md FR-057 - no use case
  ///   calls another use case, and ResolveD20Test composes the pure
  ///   D20TestResolver (architecture-guardrails.md FR-097). The scan is not
  ///   vacuous: the repository now declares a use case, and the scan over it
  ///   is clean.
  /// Path: happy
  test('FR-097: the use-case scan sees ResolveD20Test and stays clean', () {
    final useCases = useCaseClasses(_repository);

    expect(useCases.map((useCase) => useCase.name), contains('ResolveD20Test'));
    _expectNone(checkNoUseCaseCalls(_repository));
  }, timeout: _budget);
}
