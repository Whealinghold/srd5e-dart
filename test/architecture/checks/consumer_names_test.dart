import 'package:test/test.dart';

import '../support/real_repository.dart';
import '../support/source_set.dart';
import '../support/violation.dart';
import 'consumer_names.dart';

/// The repository, loaded once per test file and never mutated.
final SourceSet _repository = realRepository;

const Timeout _budget = Timeout(Duration(seconds: 10));

void _expectNone(List<Violation> violations) {
  expect(violations, isEmpty, reason: '\n${formatViolations(violations)}');
}

void main() {
  /// Requirement: doc/specs/architecture-guardrails.md FR-012 - a check must
  ///   not pass vacuously: the files it scans must exist.
  /// Path: unhappy (empty and minimal)
  test('the consumer-name scopes find files on the real repository', () {
    expect(_repository.paths(prefix: 'lib/'), isNotEmpty);
    expect(_repository.paths(prefix: 'test/'), isNotEmpty);
    expect(_repository.files.keys, containsAll(denylistSourcePaths));
  }, timeout: _budget);

  /// Requirement: doc/specs/architecture-guardrails.md FR-025 - no file
  ///   under
  ///   lib/ names a consuming project or the hosting organisation, in its
  ///   path, comments or code (architecture.md section 9, bullet 11); the
  ///   same scan is doc/specs/content-source-port.md FR-034's mechanical
  ///   consumer-name scan over `lib/`.
  /// Path: happy
  test(
    'FR-025: no file under lib/ names a consumer',
    () => _expectNone(checkNoConsumerNamesInLib(_repository)),
    timeout: _budget,
  );

  /// Requirement: doc/specs/architecture-guardrails.md FR-026 - no file
  ///   outside lib/ names a consumer, except AGENTS.md, CLAUDE.md and the
  ///   pubspec.yaml repository: line (AGENTS.md "Hard constraints").
  /// Path: happy
  test(
    'FR-026: no file outside lib/ names a consumer',
    () => _expectNone(checkNoConsumerNamesOutsideLib(_repository)),
    timeout: _budget,
  );

  /// Requirement: doc/specs/architecture-guardrails.md FR-068 - the denylist
  ///   source files hold no denylist name in plain text.
  /// Path: happy
  test(
    'FR-068: the denylist source names no denylist entry',
    () => _expectNone(checkDenylistSourceHoldsNoNames(_repository)),
    timeout: _budget,
  );
}
