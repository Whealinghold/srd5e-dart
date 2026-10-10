import 'package:test/test.dart';

import '../support/exports.dart';
import '../support/real_repository.dart';
import '../support/source_set.dart';
import '../support/violation.dart';
import 'barrel_scan.dart';

/// The repository, loaded once per test file and never mutated.
final SourceSet _repository = realRepository;

const Timeout _budget = Timeout(Duration(seconds: 10));

void _expectNone(List<Violation> violations) {
  expect(violations, isEmpty, reason: '\n${formatViolations(violations)}');
}

void main() {
  /// Requirement: doc/specs/architecture-guardrails.md FR-012, FR-077, FR-093
  ///   - a check must not pass vacuously: the real scan resolves a non-empty
  ///   closure for each core entry point present.
  /// Path: unhappy (empty and minimal)
  test('the real repository has entry points with exported declarations', () {
    final entries = entryPointsIn(_repository);

    expect(entries, containsAll(coreEntryPoints));
    for (final entry in coreEntryPoints) {
      expect(
        exportClosure(_repository, entry),
        isNotEmpty,
        reason: '$entry exports nothing',
      );
    }
  }, timeout: _budget);

  /// Requirement: doc/specs/architecture-guardrails.md FR-093 - the closure
  ///   honours the `show` clauses of lib/srd5e.dart.
  /// Path: happy
  test(
    'the closure of lib/srd5e.dart names Modifier and not its private helpers',
    () {
      final names = {
        for (final e in exportClosure(_repository, 'lib/srd5e.dart')) e.name,
      };

      expect(names, containsAll(['Modifier', 'Srd5eException', 'Logger']));
      expect(names.where((n) => n.startsWith('_')), isEmpty);
    },
    timeout: _budget,
  );

  /// Requirement: doc/specs/architecture-guardrails.md FR-077 - no barrel or
  ///   core entry point exports a generic variant name, and no exported name
  ///   is declared twice.
  /// Path: happy
  test(
    'FR-077: no generic variant name and no duplicate exported name',
    () => _expectNone(checkBarrelScan(_repository)),
    timeout: _budget,
  );
}
