import 'package:test/test.dart';

import '../support/real_repository.dart';
import '../support/source_set.dart';
import '../support/violation.dart';
import 'banned_calls.dart';

/// The repository, loaded once per test file and never mutated.
final SourceSet _repository = realRepository;

const Timeout _budget = Timeout(Duration(seconds: 10));

void _expectNone(List<Violation> violations) {
  expect(violations, isEmpty, reason: '\n${formatViolations(violations)}');
}

void main() {
  /// Requirement: doc/specs/architecture-guardrails.md FR-012 - a check must
  ///   not pass vacuously: the folders it scans must exist. No domain/ or
  ///   application/ file exists yet, so FR-027 passes vacuously today; its
  ///   self-test pins the scope.
  /// Path: unhappy (empty and minimal)
  test('the banned-call scopes find files on the real repository', () {
    final paths = _repository.dartPaths('lib/src/');

    expect(paths.any(isSharedPortsFile), isTrue);
    expect(_repository.dartPaths('lib/'), isNotEmpty);
  }, timeout: _budget);

  /// Requirement: doc/specs/architecture-guardrails.md FR-027 - no domain/ or
  ///   application/ file calls Random(, Random.secure(, DateTime.now(,
  ///   DateTime.timestamp( or Stopwatch( (architecture.md section 9, bullet
  ///   12; section 3 Purity).
  /// Path: happy
  test(
    'FR-027: no domain or application file reads randomness or the clock',
    () => _expectNone(checkNondeterministicCalls(_repository)),
    timeout: _budget,
  );

  /// Requirement: doc/specs/architecture-guardrails.md FR-028 - no file under
  ///   lib/ calls print( (architecture.md section 9, bullet 12;
  ///   observability.md section 10).
  /// Path: happy
  test(
    'FR-028: no file under lib/ calls print',
    () => _expectNone(checkPrintCalls(_repository)),
    timeout: _budget,
  );

  /// Requirement: doc/specs/architecture-guardrails.md FR-103 and
  ///   doc/specs/observability-ports.md FR-053 - no file under
  ///   lib/src/shared_ports/, adapters and no-ops included, calls Random(,
  ///   Random.secure(, DateTime.now(, DateTime.timestamp( or Stopwatch(.
  /// Path: happy
  test(
    'FR-103: no shared_ports file reads randomness or the clock',
    () => _expectNone(checkSharedPortsNondeterminism(_repository)),
    timeout: _budget,
  );
}
