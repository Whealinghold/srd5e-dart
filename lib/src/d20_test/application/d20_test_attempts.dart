import 'package:meta/meta.dart';

import '../../shared_kernel/roll_circumstance.dart';
import '../domain/roll_modifiers.dart';

/// How a command attempts its D20 Test: by rolling, or by failing without a
/// roll.
///
/// The sealed [CheckAttempt] admits a [RollAttempt] and an [AutomaticFailure];
/// the sealed [SaveAttempt] admits a [RollAttempt], a [ChooseToFail] and an
/// [AutomaticFailure]. The pairing is the SRD's: a creature may choose to fail
/// a saving throw ("you can decide to fail the save without rolling", "Saving
/// Throws", SRD 5.2.1, p. 7), so choosing is a `SaveAttempt` only, while an
/// automatic failure applies to checks and saves ("Blinded", p. 177; "Object",
/// p. 178). An attack roll always rolls, so it takes a bare [RollAttempt].
///
/// The two sealed bases carry no members and declare no constructor: the
/// attempts `implements` them, so nothing can call into this file's state and
/// the variants are the whole API.
@immutable
sealed class CheckAttempt {}

/// How a saving throw is attempted: by rolling, by choosing to fail, or by an
/// automatic failure.
///
/// Sealed with exactly the three attempts above; the analyzer rejects a
/// fourth. The choice rule is stated for saving throws only ("Saving Throws",
/// SRD 5.2.1, p. 7).
@immutable
sealed class SaveAttempt {}

/// The attempt that rolls the dice: the [modifiers] added to the d20 and the
/// [circumstances] its roll mode is resolved from.
///
/// The circumstances are copied into an unmodifiable list on construction, so
/// changing the caller's collection afterwards changes nothing and the held
/// [circumstances] cannot be mutated; the [modifiers] are held as built (a
/// `RollModifiers` copies its own collections). The roll mode itself is
/// resolved by the use case, once, from [circumstances].
@immutable
final class RollAttempt implements CheckAttempt, SaveAttempt {
  /// Creates a rolling attempt. [circumstances] defaults to none, which
  /// resolves to `RollMode.normal`.
  RollAttempt({
    required this.modifiers,
    Iterable<RollCircumstance> circumstances = const [],
  }) : circumstances = List.unmodifiable(circumstances);

  /// The modifiers added to the number rolled: exactly one ability modifier,
  /// at most one Proficiency Bonus and any number of others.
  final RollModifiers modifiers;

  /// The Advantage and Disadvantage circumstances of the roll, in the order
  /// given: an unmodifiable copy of the collection given, exposed as an
  /// [Iterable]. Empty by default.
  final Iterable<RollCircumstance> circumstances;

  /// Whether [a] and [b] hold equal circumstances in the same order. The
  /// values are the attempts' own unmodifiable copies, compared elementwise.
  static bool _sameCircumstances(
    Iterable<RollCircumstance> a,
    Iterable<RollCircumstance> b,
  ) {
    if (a.length != b.length) return false;
    final other = b.iterator;
    for (final value in a) {
      other.moveNext();
      if (other.current != value) return false;
    }
    return true;
  }

  @override
  bool operator ==(Object other) =>
      other is RollAttempt &&
      other.modifiers == modifiers &&
      _sameCircumstances(other.circumstances, circumstances);

  @override
  int get hashCode => Object.hash(modifiers, Object.hashAll(circumstances));
}

/// The attempt of a saving throw the creature fails on purpose, without
/// rolling ("you can decide to fail the save without rolling", "Saving
/// Throws", SRD 5.2.1, p. 7). Carries no fields.
@immutable
final class ChooseToFail implements SaveAttempt {
  /// Creates the chosen failure of a saving throw.
  const ChooseToFail();

  @override
  bool operator ==(Object other) => other is ChooseToFail;

  @override
  int get hashCode => (ChooseToFail).hashCode;
}

/// The attempt of a check or saving throw that fails automatically, from the
/// situation ("Blinded", SRD 5.2.1, p. 177; "Object", p. 178; "Deafened",
/// p. 181). Carries no fields; the caller decides that the situation applies.
@immutable
final class AutomaticFailure implements CheckAttempt, SaveAttempt {
  /// Creates the automatic failure of a check or saving throw.
  const AutomaticFailure();

  @override
  bool operator ==(Object other) => other is AutomaticFailure;

  @override
  int get hashCode => (AutomaticFailure).hashCode;
}
