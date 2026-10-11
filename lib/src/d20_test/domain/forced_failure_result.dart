import 'package:meta/meta.dart';

import 'd20_test_kind.dart';
import 'd20_test_resolver.dart';
import 'forced_failure_reason.dart';

/// The failure of an ability check or saving throw without a roll: a saving
/// throw the creature chooses to fail, or an automatic failure the caller
/// declares from the situation ("Saving Throws", SRD 5.2.1, p. 7; "Blinded",
/// p. 177; "Object", p. 178; "Deafened", p. 181).
///
/// It is an immutable value compared field by field. It carries no roll — the
/// test failed without one — and its [outcome] is always
/// `D20TestOutcome.failure`, so the result says why it failed through
/// [reason] and carries no separate outcome field. There is no forced failure
/// for an attack roll: the SRD gives no rule for failing one without rolling.
@immutable
final class ForcedFailureResult {
  /// Resolves the forced failure of [kind] for [reason].
  ///
  /// Published static delegate of `D20TestResolver.forcedFailure` (the
  /// behaviour is identical). Throws the same [ArgumentError]s: name `kind`
  /// when [kind] is `attackRoll`, and name `reason` when an ability check is
  /// given `chosenToFail`.
  static ForcedFailureResult of(D20TestKind kind, ForcedFailureReason reason) =>
      const D20TestResolver().forcedFailure(kind, reason);

  /// Creates a result. Prefer [of], which enforces the combinations the SRD
  /// states.
  const ForcedFailureResult({required this.kind, required this.reason});

  /// Which kind of D20 Test failed: an ability check or a saving throw.
  /// Never `attackRoll` for a result from [of].
  final D20TestKind kind;

  /// Why the test failed without a roll: the creature chose to fail (saving
  /// throws only) or the caller declared an automatic failure.
  final ForcedFailureReason reason;

  @override
  bool operator ==(Object other) =>
      other is ForcedFailureResult &&
      other.kind == kind &&
      other.reason == reason;

  @override
  int get hashCode => Object.hash(kind, reason);
}
