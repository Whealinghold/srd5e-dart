import 'package:srd5e/src/d20_test/domain/d20_test_kind.dart';
import 'package:srd5e/src/d20_test/domain/forced_failure_reason.dart';
import 'package:srd5e/src/d20_test/domain/forced_failure_result.dart';
import 'package:test/test.dart';

/// What a forced-failure case expects to happen.
sealed class _Expectation {
  const _Expectation();
}

/// The result carries exactly this kind and reason: a `ForcedFailureResult`
/// has no roll and no other data (FR-041), so these two fields alone compare
/// equal, with an equal hash code.
final class _Carries extends _Expectation {
  const _Carries(this.kind, this.reason);

  final D20TestKind kind;
  final ForcedFailureReason reason;
}

/// The resolution throws an ArgumentError with this name and invalidValue.
final class _Rejects extends _Expectation {
  const _Rejects(this.argumentName, this.invalidValue);

  final String argumentName;
  final Object? invalidValue;
}

typedef _ForcedFailureCase = ({
  String label,
  String requirement,
  String path,
  D20TestKind kind,
  ForcedFailureReason reason,
  _Expectation expectation,
});

/// The 6-row forced failure table of `doc/specs/d20-tests.md` section 4.5,
/// in the order written there.
const List<_ForcedFailureCase> _forcedFailureCases = [
  (
    label: 'chosen to fail a save',
    requirement:
        'doc/specs/d20-tests.md FR-035 (SRD 5.2.1, "Saving Throws", p. 7, '
        '"you can choose to fail the save without rolling")',
    path: 'happy',
    kind: D20TestKind.savingThrow,
    reason: ForcedFailureReason.chosenToFail,
    expectation: _Carries(
      D20TestKind.savingThrow,
      ForcedFailureReason.chosenToFail,
    ),
  ),
  (
    label: 'automatic failure of a save',
    requirement: 'doc/specs/d20-tests.md FR-036 (SRD 5.2.1, "Object", p. 178)',
    path: 'happy',
    kind: D20TestKind.savingThrow,
    reason: ForcedFailureReason.automatic,
    expectation: _Carries(
      D20TestKind.savingThrow,
      ForcedFailureReason.automatic,
    ),
  ),
  (
    label: 'automatic failure of a check',
    requirement:
        'doc/specs/d20-tests.md FR-036 (SRD 5.2.1, "Blinded", p. 177; '
        '"Deafened", p. 181)',
    path: 'happy',
    kind: D20TestKind.abilityCheck,
    reason: ForcedFailureReason.automatic,
    expectation: _Carries(
      D20TestKind.abilityCheck,
      ForcedFailureReason.automatic,
    ),
  ),
  (
    label: 'chosen to fail a check',
    requirement:
        'doc/specs/d20-tests.md FR-052 (doc/rules/testing.md §4; SRD 5.2.1, '
        'p. 6: no rule for choosing to fail an ability check)',
    path: 'unhappy (invalid input)',
    kind: D20TestKind.abilityCheck,
    reason: ForcedFailureReason.chosenToFail,
    expectation: _Rejects('reason', ForcedFailureReason.chosenToFail),
  ),
  (
    label: 'forced failure of an attack roll',
    requirement:
        'doc/specs/d20-tests.md FR-052 (SRD 5.2.1, "Attack Rolls", p. 7: no '
        'rule for failing an attack roll without rolling)',
    path: 'unhappy (invalid input)',
    kind: D20TestKind.attackRoll,
    reason: ForcedFailureReason.automatic,
    expectation: _Rejects('kind', D20TestKind.attackRoll),
  ),
  (
    label: 'forced failure of an attack roll, chosen',
    requirement:
        'doc/specs/d20-tests.md FR-052 (SRD 5.2.1, "Attack Rolls", p. 7: no '
        'rule for failing an attack roll without rolling)',
    path: 'unhappy (invalid input)',
    kind: D20TestKind.attackRoll,
    reason: ForcedFailureReason.chosenToFail,
    expectation: _Rejects('kind', D20TestKind.attackRoll),
  ),
];

void main() {
  /// Requirement: per case - the 6-row forced failure table of
  ///   doc/specs/d20-tests.md section 4.5; each row cites its own ids and
  ///   path. The rows go through the published delegate
  ///   ForcedFailureResult.of, which behaves identically to
  ///   D20TestResolver.forcedFailure. A ForcedFailureResult is always a
  ///   failure and carries no roll and no outcome field: the "no roll" half
  ///   of FR-041 is the type's shape, pinned here by equality over kind and
  ///   reason alone.
  /// Path: per case
  group('ForcedFailureResult.of forced failure table', () {
    for (final c in _forcedFailureCases) {
      test('${c.label} [${c.path}] (${c.requirement})', () {
        final expectation = c.expectation;
        switch (expectation) {
          case _Carries(:final kind, :final reason):
            final result = ForcedFailureResult.of(c.kind, c.reason);
            expect(result.kind, kind);
            expect(result.reason, reason);
            final expected = ForcedFailureResult(kind: kind, reason: reason);
            expect(result, expected);
            expect(result.hashCode, expected.hashCode);
          case _Rejects(:final argumentName, :final invalidValue):
            // The exact runtime type is pinned: the guards throw ArgumentError
            // itself, never a subtype.
            expect(
              () => ForcedFailureResult.of(c.kind, c.reason),
              throwsA(
                isA<ArgumentError>()
                    .having((e) => e.runtimeType, 'runtimeType', ArgumentError)
                    .having((e) => e.name, 'name', argumentName)
                    .having(
                      (e) => e.invalidValue,
                      'invalidValue',
                      invalidValue,
                    ),
              ),
            );
        }
      });
    }
  });
}
