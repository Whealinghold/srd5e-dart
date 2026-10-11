import 'package:srd5e/src/d20_test/domain/d20_test_kind.dart';
import 'package:srd5e/src/d20_test/domain/d20_test_outcome.dart';
import 'package:srd5e/src/d20_test/domain/forced_failure_reason.dart';
import 'package:test/test.dart';

void main() {
  /// Requirement: doc/specs/d20-tests.md FR-060 - D20TestOutcome is exactly
  ///   success and failure, for every kind (SRD 5.2.1, "Rolling 20 or 1",
  ///   p. 7; doc/specs/shared-types-and-ownership.md FR-004).
  /// Path: happy
  test('D20TestOutcome is exactly success and failure', () {
    expect(D20TestOutcome.values, [
      D20TestOutcome.success,
      D20TestOutcome.failure,
    ]);
  });

  /// Requirement: doc/specs/d20-tests.md FR-060 - a switch over
  ///   D20TestOutcome is exhaustive with exactly the two cases and no default
  ///   (SRD 5.2.1, "Rolling 20 or 1", p. 7); the compiler enforces it, this
  ///   switch expression would not otherwise compile.
  /// Path: happy
  test('a switch over D20TestOutcome is exhaustive over its two cases', () {
    String name(D20TestOutcome outcome) => switch (outcome) {
      D20TestOutcome.success => 'success',
      D20TestOutcome.failure => 'failure',
    };

    expect(name(D20TestOutcome.success), 'success');
    expect(name(D20TestOutcome.failure), 'failure');
  });

  /// Requirement: doc/specs/d20-tests.md section 5 - D20TestKind is exactly
  ///   abilityCheck, savingThrow and attackRoll ("D20 Test", SRD 5.2.1,
  ///   p. 180).
  /// Path: happy
  test('D20TestKind is exactly the three kinds', () {
    expect(D20TestKind.values, [
      D20TestKind.abilityCheck,
      D20TestKind.savingThrow,
      D20TestKind.attackRoll,
    ]);
  });

  /// Requirement: doc/specs/d20-tests.md section 5 - ForcedFailureReason is
  ///   exactly chosenToFail and automatic ("Saving Throws", SRD 5.2.1, p. 7;
  ///   "Blinded", p. 177).
  /// Path: happy
  test('ForcedFailureReason is exactly the two reasons', () {
    expect(ForcedFailureReason.values, [
      ForcedFailureReason.chosenToFail,
      ForcedFailureReason.automatic,
    ]);
  });
}
