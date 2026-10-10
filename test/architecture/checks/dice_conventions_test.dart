import 'package:test/test.dart';

import '../support/real_repository.dart';
import '../support/source_set.dart';
import '../support/violation.dart';
import 'dice_conventions.dart';

/// The repository, loaded once per test file and never mutated.
final SourceSet _repository = realRepository;

const Timeout _budget = Timeout(Duration(seconds: 10));

void _expectNone(List<Violation> violations) {
  expect(violations, isEmpty, reason: '\n${formatViolations(violations)}');
}

void main() {
  /// Requirement: doc/specs/architecture-guardrails.md FR-012 - a check must
  ///   not pass vacuously: the dice files it scans must exist.
  /// Path: unhappy (empty and minimal)
  test('the dice scope finds the kernel, port, adapter and double files', () {
    final files = diceFiles(_repository);

    expect(files, contains('lib/src/shared_kernel/dice/die.dart'));
    expect(files, contains('lib/src/shared_kernel/dice/dice_expression.dart'));
    expect(files, contains('lib/src/shared_kernel/dice/die_roll.dart'));
    expect(files, contains('lib/src/shared_kernel/dice/roll_result.dart'));
    expect(
      files,
      contains('lib/src/shared_ports/dice_roller/dice_roller.dart'),
    );
    expect(files, contains(seededRollerPath));
    expect(files, containsAll(diceDoublePaths));
  }, timeout: _budget);

  /// Requirement: doc/specs/dice-and-rolls.md FR-064 and FR-066 - D1 on the
  ///   real repository: the dice files contain no `Random(`, `DateTime.now(`
  ///   or `Stopwatch(` call.
  /// Path: happy
  test(
    'D1: no Random(, DateTime.now( or Stopwatch( in the dice files',
    () => _expectNone(checkNoHiddenNonDeterminism(_repository)),
    timeout: _budget,
  );

  /// Requirement: doc/specs/dice-and-rolls.md FR-066 - D2 on the real
  ///   repository: only the seeded roller imports dart:math, and it does.
  /// Path: happy
  test('D2: only seeded_dice_roller.dart imports dart:math', () {
    _expectNone(checkOnlySeededRollerImportsMath(_repository));
    expect(
      _repository.files[seededRollerPath],
      contains("import 'dart:math'"),
      reason: 'the adapter needs the Random type',
    );
  }, timeout: _budget);

  /// Requirement: doc/specs/dice-and-rolls.md FR-087 - D3 on the real
  ///   repository: the dice files name no logger, tracer, meter or
  ///   Observability.
  /// Path: happy
  test(
    'D3: the dice files are silent',
    () => _expectNone(checkDiceFilesAreSilent(_repository)),
    timeout: _budget,
  );

  /// Requirement: doc/specs/dice-and-rolls.md FR-067 - D4 on the real
  ///   repository: the entry points export exactly the dice names of the
  ///   single list, and the barrel names no generic variant name (FR-085).
  /// Path: happy
  test(
    'D4: the entry points export exactly the FR-067 names',
    () => _expectNone(checkDiceEntryPoints(_repository)),
    timeout: _budget,
  );
}
