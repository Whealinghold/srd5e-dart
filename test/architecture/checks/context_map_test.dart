import 'package:test/test.dart';

import '../support/context_map.dart';
import '../support/real_repository.dart';
import '../support/source_set.dart';
import '../support/violation.dart';
import 'context_map.dart';

/// The repository, loaded once per test file and never mutated.
final SourceSet _repository = realRepository;

const Timeout _budget = Timeout(Duration(seconds: 10));

void _expectNone(List<Violation> violations) {
  expect(violations, isEmpty, reason: '\n${formatViolations(violations)}');
}

void main() {
  /// Requirement: doc/specs/architecture-guardrails.md FR-012, FR-022 - a
  ///   check must not pass vacuously: the real run parses a non-empty map
  ///   from architecture.md and a list from AGENTS.md.
  /// Path: unhappy (empty and minimal)
  test('the real repository yields a context map and an AGENTS.md list', () {
    final map = ContextMap.parse(_repository);

    expect(map.tableFound, isTrue);
    expect(map.contexts, isNotEmpty);
    expect(map.agentsContexts, isNotEmpty);
    expect(map.leaves, {'toolbox'});
  }, timeout: _budget);

  /// Requirement: doc/specs/architecture-guardrails.md FR-020 - the context
  ///   map of architecture.md section 2 has no cycle.
  /// Path: happy
  test(
    'FR-020: the context map is acyclic',
    () => _expectNone(checkContextMapAcyclic(_repository)),
    timeout: _budget,
  );

  /// Requirement: doc/specs/architecture-guardrails.md FR-021 - every folder
  ///   under lib/src/ is a context of the map or a non-context folder, and no
  ///   loose .dart file sits in lib/src/.
  /// Path: happy
  test(
    'FR-021: every lib/src/ folder is a mapped context',
    () => _expectNone(checkContextFolders(_repository)),
    timeout: _budget,
  );

  /// Requirement: doc/specs/architecture-guardrails.md FR-022 - the map
  ///   parses from the table and AGENTS.md names the same contexts.
  /// Path: happy
  test(
    'FR-022: the map parses and AGENTS.md agrees with it',
    () => _expectNone(checkContextMapFormat(_repository)),
    timeout: _budget,
  );

  /// Requirement: doc/specs/architecture-guardrails.md FR-098 - nothing
  ///   depends on a leaf context, and a leaf lists only mapped contexts.
  /// Path: happy
  test(
    'FR-098: nothing depends on toolbox',
    () => _expectNone(checkLeafContexts(_repository)),
    timeout: _budget,
  );
}
