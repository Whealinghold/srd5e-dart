import 'package:meta/meta.dart';

/// The choice behind a reroll of one d20: keep the roll as it is, or reroll
/// one named die.
///
/// Under Advantage or Disadvantage a reroll or replacement applies to "only
/// one die, not both", and the roller chooses which ("Interactions with
/// Rerolls", SRD 5.2.1, p. 8); a decision names that one die by its index.
/// `D20Roll.applyReroll` takes a decision and the new face.
@immutable
sealed class RerollDecision {
  /// Creates a decision.
  const RerollDecision();
}

/// The decision to keep the roll as it is.
@immutable
final class KeepRoll extends RerollDecision {
  /// Creates the decision to keep the roll.
  const KeepRoll();

  @override
  bool operator ==(Object other) => other is KeepRoll;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// The decision to reroll the die at [dieIndex] and use the new face, even
/// when it is lower than the old one ("Heroic Inspiration", SRD 5.2.1, p. 8).
@immutable
final class RerollDie extends RerollDecision {
  /// Creates the decision to reroll the die at [dieIndex].
  const RerollDie(this.dieIndex);

  /// The index of the die to reroll: `0` for the first die rolled, `1` for
  /// the second under Advantage or Disadvantage. `D20Roll.applyReroll`
  /// validates it against the roll it is applied to.
  final int dieIndex;

  @override
  bool operator ==(Object other) =>
      other is RerollDie && other.dieIndex == dieIndex;

  @override
  int get hashCode => Object.hash(runtimeType, dieIndex);
}
