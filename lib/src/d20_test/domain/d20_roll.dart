import 'package:meta/meta.dart';

import '../../shared_kernel/roll_mode.dart';

import 'reroll_decision.dart';

/// The d20s rolled for one D20 Test: which [mode] they were rolled under, the
/// face values in the order rolled, and the die the mode keeps.
///
/// The roll is a value: constructing it validates the dice (the count for the
/// mode, and the 1 to 20 range) and [RollMode.select] picks the kept face;
/// [replaceDie] and [applyReroll] return new rolls and never alter the
/// original. A roll holds no "already replaced" state, so the SRD limit of one
/// replaced die per roll ("Interactions with Rerolls", SRD 5.2.1, p. 8) is
/// the caller's responsibility, not this type's.
@immutable
final class D20Roll {
  /// The lowest face of a d20 ("Rolling 20 or 1", SRD 5.2.1, p. 7).
  static const int _lowestFace = 1;

  /// The highest face of a d20.
  static const int _highestFace = 20;

  /// Whether [value] is a d20 face ("Rolling 20 or 1", SRD 5.2.1, p. 7).
  static bool _isD20Face(int value) =>
      value >= _lowestFace && value <= _highestFace;

  /// Creates a roll of the d20 faces [dice] in the order rolled, under
  /// [mode].
  ///
  /// The list is copied, so changing the caller's list afterwards does not
  /// change the roll, and the held [dice] cannot be mutated. [natural] is the
  /// number [RollMode.select] returns: the higher die under Advantage, the
  /// lower under Disadvantage, the only die under `normal`.
  ///
  /// Throws an [ArgumentError] carrying the name `dice` and the list passed
  /// in when the count of values differs from the mode's dice count or any
  /// value is outside 1 to 20. The count and range are pre-validated here —
  /// the package's guardrails forbid catching the [Error] `select` would
  /// throw — and `select` remains the sole authority for which die is kept.
  factory D20Roll({required RollMode mode, required List<int> dice}) {
    if (dice.length != mode.diceCount || !dice.every(_isD20Face)) {
      throw ArgumentError.value(dice, 'dice');
    }
    return D20Roll._(
      mode: mode,
      dice: List.unmodifiable(dice),
      natural: mode.select(dice),
    );
  }

  D20Roll._({required this.mode, required this.dice, required this.natural})
    : keptIndex = dice.indexOf(natural);

  /// The mode the d20s were rolled under.
  final RollMode mode;

  /// The d20 face values in the order rolled: one for `normal`, two for
  /// Advantage and Disadvantage. Unmodifiable.
  final List<int> dice;

  /// The d20 number this roll uses, before modifiers: the die the mode keeps
  /// (`RollMode.select`).
  final int natural;

  /// The index in [dice] of the kept die: the first index whose value equals
  /// [natural]. With equal dice that is index 0. Recomputed by [replaceDie].
  final int keptIndex;

  /// The roll with the die at [index] replaced by [value]: the same [mode],
  /// every other die unchanged in its position, and [natural] re-selected
  /// with `RollMode.select` ("Interactions with Rerolls", SRD 5.2.1, p. 8).
  ///
  /// The original roll is unchanged. Throws an [ArgumentError] carrying the
  /// name `index` and the offending index when [index] is outside `0` to
  /// `dice.length - 1`, and the name `value` and the offending value when
  /// [value] is outside 1 to 20.
  D20Roll replaceDie(int index, int value) {
    if (index < 0 || index >= dice.length) {
      throw ArgumentError.value(index, 'index');
    }
    if (value < _lowestFace || value > _highestFace) {
      throw ArgumentError.value(value, 'value');
    }
    final replaced = [...dice]..[index] = value;
    return D20Roll(mode: mode, dice: replaced);
  }

  /// The roll this decision leads to: the roll unchanged for a [KeepRoll],
  /// and [replaceDie] with the decision's die and [newValue] for a
  /// [RerollDie]. The new value is used even when it is lower than the old
  /// one ("Heroic Inspiration", SRD 5.2.1, p. 8).
  ///
  /// The original roll is unchanged. Throws an [ArgumentError] carrying the
  /// name `newValue` and the offending value when a [KeepRoll] is given a
  /// [newValue] (there is nothing to reroll) and when a [RerollDie] is given
  /// none (a reroll needs the new face). A [RerollDie] whose index or
  /// [newValue] is invalid throws the [replaceDie] error.
  D20Roll applyReroll(RerollDecision decision, {int? newValue}) {
    switch (decision) {
      case KeepRoll():
        if (newValue != null) {
          throw ArgumentError.value(newValue, 'newValue');
        }
        return this;
      case RerollDie(:final dieIndex):
        if (newValue == null) {
          throw ArgumentError.value(newValue, 'newValue');
        }
        return replaceDie(dieIndex, newValue);
    }
  }

  @override
  bool operator ==(Object other) =>
      other is D20Roll && other.mode == mode && _sameDice(other.dice, dice);

  @override
  int get hashCode => Object.hash(mode, Object.hashAll(dice));

  /// Whether [a] and [b] hold the same values in the same order. Both lists
  /// come from rolls of an equal [mode], so they have the same length: the
  /// mode's dice count.
  static bool _sameDice(List<int> a, List<int> b) {
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
