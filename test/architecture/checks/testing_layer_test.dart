import 'package:test/test.dart';

import '../support/real_repository.dart';
import '../support/source_set.dart';
import '../support/violation.dart';
import 'testing_layer.dart';

/// The repository, loaded once per test file and never mutated.
final SourceSet _repository = realRepository;

const Timeout _budget = Timeout(Duration(seconds: 10));

void _expectNone(List<Violation> violations) {
  expect(violations, isEmpty, reason: '\n${formatViolations(violations)}');
}

void main() {
  /// Requirement: doc/specs/architecture-guardrails.md FR-012, FR-081,
  ///   FR-082 - a check must not pass vacuously: the real run finds doubles,
  ///   the entry point and the driven ports, and not the port handles.
  /// Path: unhappy (empty and minimal)
  test('the real repository has doubles, an entry point and ports', () {
    final names = {for (final port in drivenPorts(_repository)) port.name};

    expect(_repository.dartPaths(testingPrefix), isNotEmpty);
    expect(_repository.files, contains(testingEntryPoint));
    expect(names, containsAll(['DiceRoller', 'Logger', 'Tracer', 'Meter']));
    expect(names, isNot(contains('Span')));
  }, timeout: _budget);

  /// Requirement: doc/specs/architecture-guardrails.md FR-074 - only
  ///   lib/testing.dart imports or exports a file under lib/src/testing/.
  /// Path: happy
  test(
    'FR-074: only lib/testing.dart reaches the doubles',
    () => _expectNone(checkTestingImportedOnlyByEntryPoint(_repository)),
    timeout: _budget,
  );

  /// Requirement: doc/specs/architecture-guardrails.md FR-075 - a double
  ///   imports only the SDK, meta, collection, other doubles, the shared
  ///   modules and context barrels.
  /// Path: happy
  test(
    'FR-075: doubles import only what a double may',
    () => _expectNone(checkTestingImports(_repository)),
    timeout: _budget,
  );

  /// Requirement: doc/specs/architecture-guardrails.md FR-081 - a class that
  ///   implements a port under a double prefix is declared under
  ///   lib/src/testing/.
  /// Path: happy
  test(
    'FR-081: every double lives in lib/src/testing/',
    () => _expectNone(checkDoublesLiveInTesting(_repository)),
    timeout: _budget,
  );

  /// Requirement: doc/specs/architecture-guardrails.md FR-082 and
  ///   doc/specs/observability-ports.md FR-065 - every driven port has an
  ///   exported double and a contract suite; the four handles are not ports.
  /// Path: happy
  test(
    'FR-082: every port has a double and a contract suite',
    () => _expectNone(checkPortsHaveDoublesAndContracts(_repository)),
    timeout: _budget,
  );
}
