import 'package:test/test.dart';

import '../support/real_repository.dart';
import '../support/source_set.dart';
import '../support/violation.dart';
import 'modifier_conventions.dart';

/// The repository, loaded once per test file and never mutated.
final SourceSet _repository = realRepository;

const Timeout _budget = Timeout(Duration(seconds: 10));

void _expectNone(List<Violation> violations) {
  expect(violations, isEmpty, reason: '\n${formatViolations(violations)}');
}

void main() {
  /// Requirement: doc/specs/architecture-guardrails.md FR-012 - a check must
  ///   not pass vacuously: the modifier kernel files it scans must exist.
  /// Path: unhappy (empty and minimal)
  test('the modifier scope finds the three kernel files', () {
    expect(_repository.files.keys, containsAll(modifierKernelFiles));
  }, timeout: _budget);

  /// Requirement: doc/specs/modifiers-and-advantage.md section 6 - K1 on the
  ///   real repository: the modifier kernel files import nothing from
  ///   shared_ports or a context.
  /// Path: happy
  test(
    'K1: the modifier kernel files import only meta, math and siblings',
    () => _expectNone(checkModifierFilesImportNothingElse(_repository)),
    timeout: _budget,
  );

  /// Requirement: doc/specs/modifiers-and-advantage.md FR-043 - K2 on the real
  ///   repository: Modifier and AbilityModifier do not know each other.
  /// Path: happy
  test(
    'K2: Modifier and AbilityModifier are independent',
    () =>
        _expectNone(checkModifierAndAbilityModifierAreIndependent(_repository)),
    timeout: _budget,
  );
}
