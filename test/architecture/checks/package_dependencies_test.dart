import 'package:test/test.dart';

import '../support/real_repository.dart';
import '../support/source_set.dart';
import '../support/violation.dart';
import 'package_dependencies.dart';

/// The repository, loaded once per test file and never mutated.
final SourceSet _repository = realRepository;

const Timeout _budget = Timeout(Duration(seconds: 10));

void _expectNone(List<Violation> violations) {
  expect(violations, isEmpty, reason: '\n${formatViolations(violations)}');
}

void main() {
  /// Requirement: doc/specs/architecture-guardrails.md FR-012, FR-083 - a
  ///   check must not pass vacuously: the real pubspec.yaml lists its
  ///   dependencies.
  /// Path: unhappy (empty and minimal)
  test('the real pubspec.yaml has a dependencies block', () {
    final names = {
      for (final d in dependenciesIn(_repository.files[pubspecPath]!)) d.name,
    };

    expect(names, containsAll(['collection', 'meta']));
  }, timeout: _budget);

  /// Requirement: doc/specs/architecture-guardrails.md FR-033 - dependencies
  ///   lists no observability or error-tracking package (observability.md
  ///   section 10, bullet 1).
  /// Path: happy
  test(
    'FR-033: no observability SDK in dependencies',
    () => _expectNone(checkNoObservabilitySdkDependency(_repository)),
    timeout: _budget,
  );

  /// Requirement: doc/specs/architecture-guardrails.md FR-083 - dependencies
  ///   lists only collection and meta (AGENTS.md "Hard constraints").
  /// Path: happy
  test(
    'FR-083: dependencies are only the allowlist',
    () => _expectNone(checkDependencyAllowlist(_repository)),
    timeout: _budget,
  );
}
