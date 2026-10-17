import 'package:meta/meta.dart';

import '../../../shared_kernel/dice/dice_expression.dart';

/// How an amount grows when a spell is cast "Using a Higher-Level Spell Slot"
/// ("Using a Higher-Level Spell Slot", SRD 5.2.1, pp. 104-105), sealed with
/// exactly the three shapes (FR-016, FR-020).
///
/// The queries take plain integers — `n`, the number of slot levels above
/// `aboveLevel`, and the total character level — so `content` imports nothing
/// from `character`; the caller derives them from the cast (FR-041). Switch
/// over the family exhaustively, with no default branch.
@immutable
sealed class AmountScaling {
  const AmountScaling();
}

/// The amount does not grow with the slot level.
@immutable
final class NoAmountScaling extends AmountScaling {
  /// The single shape; no scaling carries no data.
  const NoAmountScaling();

  @override
  bool operator ==(Object other) => other is NoAmountScaling;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'NoAmountScaling()';
}

/// The amount grows by a fixed step per slot level above [aboveLevel]
/// (FR-016): Fireball's "+1d6 per level above 3", False Life's "+5 per level
/// above 1", Heal's "+10 per level above 6" (SRD 5.2.1, pp. 131, 129, 139).
@immutable
final class PerSlotLevelAmount extends AmountScaling {
  /// Creates the scaling that applies [step] [aboveLevel] slot levels up.
  const PerSlotLevelAmount(this.aboveLevel, this.step);

  /// The slot level the growth starts at. Valid against the spell's level by
  /// `SpellEffectModel.checkSpellLevel` (FR-009), not by this constructor.
  final int aboveLevel;

  /// What one slot level adds.
  final AmountStep step;

  @override
  bool operator ==(Object other) =>
      other is PerSlotLevelAmount &&
      other.aboveLevel == aboveLevel &&
      other.step == step;

  @override
  int get hashCode => Object.hash(PerSlotLevelAmount, aboveLevel, step);

  @override
  String toString() =>
      'PerSlotLevelAmount(aboveLevel: $aboveLevel, step: $step)';
}

/// The amount is replaced by the printed total for the character level
/// (FR-020): Fire Bolt's 1d10, 2d10, 3d10, 4d10 table (SRD 5.2.1, p. 132).
@immutable
final class ByCharacterLevelAmount extends AmountScaling {
  /// Creates the scaling that reads the printed [table].
  const ByCharacterLevelAmount(this.table);

  /// The printed totals as replacement values, never increments (FR-020).
  final CharacterLevelTable<SpellAmount> table;

  @override
  bool operator ==(Object other) =>
      other is ByCharacterLevelAmount && other.table == table;

  @override
  int get hashCode => Object.hash(ByCharacterLevelAmount, table);

  @override
  String toString() => 'ByCharacterLevelAmount($table)';
}

/// How a count (a target count or an instance count) grows, sealed with
/// exactly the three shapes (FR-017, FR-020).
///
/// The query takes the count's base plus the plain integers of FR-041.
@immutable
sealed class CountScaling {
  const CountScaling();

  /// The count grown from [base] by [slotLevelsAbove] slot levels or by the
  /// [characterLevel] table, per this scaling. A scaling that reads neither
  /// input returns [base] unchanged.
  int countAt(
    int base, {
    required int slotLevelsAbove,
    required int characterLevel,
  });
}

/// The count does not grow.
@immutable
final class NoCountScaling extends CountScaling {
  /// The single shape; no scaling carries no data.
  const NoCountScaling();

  @override
  int countAt(
    int base, {
    required int slotLevelsAbove,
    required int characterLevel,
  }) => base;

  @override
  bool operator ==(Object other) => other is NoCountScaling;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'NoCountScaling()';
}

/// The count grows by [extra] per slot level above [aboveLevel] (FR-017):
/// Hold Person's one additional Humanoid per level above 2, Magic Missile's
/// one more dart per level above 1 (SRD 5.2.1, pp. 141, 146).
@immutable
final class PerSlotLevelCount extends CountScaling {
  /// Creates the scaling that adds [extra] per slot level above [aboveLevel].
  ///
  /// Throws an [ArgumentError] carrying the name `extra` and the offending
  /// value when [extra] is below 1 (FR-017).
  PerSlotLevelCount(this.aboveLevel, int extra)
    : extra = _validatedExtra(extra);

  /// The slot level the growth starts at. Valid against the spell's level by
  /// `SpellEffectModel.checkSpellLevel` (FR-009), not by this constructor.
  final int aboveLevel;

  /// What one slot level adds.
  final int extra;

  static int _validatedExtra(int extra) {
    if (extra < 1) {
      throw ArgumentError.value(extra, 'extra', 'must be at least 1');
    }
    return extra;
  }

  @override
  int countAt(
    int base, {
    required int slotLevelsAbove,
    required int characterLevel,
  }) => base + _validatedN(slotLevelsAbove) * extra;

  @override
  bool operator ==(Object other) =>
      other is PerSlotLevelCount &&
      other.aboveLevel == aboveLevel &&
      other.extra == extra;

  @override
  int get hashCode => Object.hash(PerSlotLevelCount, aboveLevel, extra);

  @override
  String toString() =>
      'PerSlotLevelCount(aboveLevel: $aboveLevel, extra: $extra)';
}

/// The count is replaced by the printed count for the character level
/// (FR-020): Eldritch Blast's 1, 2, 3, 4 beams (SRD 5.2.1, p. 127).
@immutable
final class ByCharacterLevelCount extends CountScaling {
  /// Creates the scaling that reads the printed [table].
  const ByCharacterLevelCount(this.table);

  /// The printed counts as replacement values, never increments (FR-020).
  final CharacterLevelTable<int> table;

  @override
  int countAt(
    int base, {
    required int slotLevelsAbove,
    required int characterLevel,
  }) => table.valueAt(characterLevel);

  @override
  bool operator ==(Object other) =>
      other is ByCharacterLevelCount && other.table == table;

  @override
  int get hashCode => Object.hash(ByCharacterLevelCount, table);

  @override
  String toString() => 'ByCharacterLevelCount($table)';
}

/// What one slot level adds to a scaled amount (FR-016).
@immutable
final class AmountStep {
  /// Creates a step adding [extraDice] dice and [extraFlat] flat per slot
  /// level.
  ///
  /// Throws an [ArgumentError] carrying the name `extraDice` or `extraFlat`
  /// and the offending value when a part is negative, and the name
  /// `extraDice` when both parts are 0 (a step that adds nothing, FR-016).
  /// That [extraDice] is not applied to a fixed base is checked by
  /// [ScalableAmount] (FR-016, table L22).
  AmountStep({this.extraDice = 0, this.extraFlat = 0}) {
    if (extraDice < 0) {
      throw ArgumentError.value(extraDice, 'extraDice', 'must be 0 or more');
    }
    if (extraFlat < 0) {
      throw ArgumentError.value(extraFlat, 'extraFlat', 'must be 0 or more');
    }
    if (extraDice == 0 && extraFlat == 0) {
      throw ArgumentError.value(
        extraDice,
        'extraDice',
        'a step must add at least one die or one flat point',
      );
    }
  }

  /// The number of extra dice per slot level, of the base amount's die.
  final int extraDice;

  /// The flat amount added per slot level.
  final int extraFlat;

  /// Applies this step [n] times to [base] (FR-016): the dice count of a
  /// rolled base grows by [n] times [extraDice] (the base die) and the flat
  /// modifier by [n] times [extraFlat]; a fixed base grows only in the flat
  /// value.
  SpellAmount appliedTo(SpellAmount base, int n) {
    final times = _validatedN(n);
    return switch (base) {
      RolledSpellAmount(:final dice) => RolledSpellAmount(
        DiceExpression(
          dice.count + times * extraDice,
          dice.die,
          modifier: dice.modifier + times * extraFlat,
        ),
      ),
      FixedSpellAmount(:final value) => FixedSpellAmount(
        value + times * extraFlat,
      ),
    };
  }

  @override
  bool operator ==(Object other) =>
      other is AmountStep &&
      other.extraDice == extraDice &&
      other.extraFlat == extraFlat;

  @override
  int get hashCode => Object.hash(AmountStep, extraDice, extraFlat);

  @override
  String toString() =>
      'AmountStep(extraDice: $extraDice, extraFlat: $extraFlat)';
}

/// A printed table of values by total character level ("Using a
/// Higher-Level Spell Slot"; "Cantrip Upgrade", SRD 5.2.1, pp. 104-105,
/// 107) (FR-018, FR-019).
///
/// The printed tables have few entries (Fire Bolt: levels 1, 5, 11, 17), not
/// one per level: [valueAt] selects the entry with the greatest level not
/// above the character level it is given. A table starts at level 1 with a
/// valid amount, so an upgrade that only adds a new effect from a later level
/// (True Strike, p. 171) cannot be held (FR-019).
@immutable
final class CharacterLevelTable<T> {
  /// Creates a table from [entries] of level and value.
  ///
  /// Throws an [ArgumentError] carrying the name `entries` and the offending
  /// value when [entries] is empty, its first level is not 1, its levels are
  /// not strictly ascending, or a level is outside 1 to 20 inclusive
  /// (FR-019).
  CharacterLevelTable(List<(int, T)> entries)
    : entries = List.unmodifiable(_validated(entries));

  /// The lowest total character level a table level may name (FR-019).
  static const int minLevel = 1;

  /// The highest total character level a table level may name (FR-019).
  static const int maxLevel = 20;

  /// The entries, in level order; unmodifiable.
  final List<(int, T)> entries;

  /// The value of the entry with the greatest level not above
  /// [characterLevel] (FR-018).
  ///
  /// Throws an [ArgumentError] carrying the name `characterLevel` and the
  /// offending value when [characterLevel] is outside 1 to 20 (FR-041). The
  /// first entry is at level 1, so every valid level finds an entry.
  T valueAt(int characterLevel) {
    if (characterLevel < minLevel || characterLevel > maxLevel) {
      throw ArgumentError.value(
        characterLevel,
        'characterLevel',
        'must be from $minLevel to $maxLevel',
      );
    }
    // mutate4dart: ignore collection // dead seed: the first entry is at minLevel, so it always qualifies for a valid query and overwrites the seed.
    var selected = entries.first;
    for (final entry in entries) {
      if (entry.$1 <= characterLevel) {
        selected = entry;
      } else {
        break;
      }
    }
    return selected.$2;
  }

  static List<(int, T)> _validated<T>(List<(int, T)> entries) {
    if (entries.isEmpty) {
      throw ArgumentError.value(entries, 'entries', 'must have at least one');
    }
    if (entries.first.$1 != minLevel) {
      throw ArgumentError.value(
        entries.first.$1,
        'entries',
        'the first level must be $minLevel',
      );
    }
    for (final (level, _) in entries) {
      if (level < minLevel || level > maxLevel) {
        throw ArgumentError.value(
          level,
          'entries',
          'levels must be from $minLevel to $maxLevel',
        );
      }
    }
    for (var i = 1; i < entries.length; i++) {
      if (entries[i].$1 <= entries[i - 1].$1) {
        throw ArgumentError.value(
          entries[i].$1,
          'entries',
          'levels must be strictly ascending',
        );
      }
    }
    return entries;
  }

  @override
  bool operator ==(Object other) {
    if (other is! CharacterLevelTable<T> ||
        other.entries.length != entries.length) {
      return false;
    }
    for (var i = 0; i < entries.length; i++) {
      if (other.entries[i].$1 != entries[i].$1 ||
          other.entries[i].$2 != entries[i].$2) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode =>
      Object.hashAll(entries.map((entry) => Object.hash(entry.$1, entry.$2)));

  @override
  String toString() => 'CharacterLevelTable($entries)';
}

/// Validates the slot-level query input `n` (FR-041).
int _validatedN(int n) {
  if (n < 0) {
    throw ArgumentError.value(n, 'slotLevelsAbove', 'must be 0 or more');
  }
  return n;
}

/// The printed amount itself, sealed with the two printed shapes (FR-047).
@immutable
sealed class SpellAmount {
  const SpellAmount();
}

/// A printed die expression, such as 8d6 (FR-047).
///
/// The expression carries its own validation (count at least 1, FR-025).
@immutable
final class RolledSpellAmount extends SpellAmount {
  /// Wraps the printed [dice].
  const RolledSpellAmount(this.dice);

  /// The printed die expression.
  final DiceExpression dice;

  @override
  bool operator ==(Object other) =>
      other is RolledSpellAmount && other.dice == dice;

  @override
  int get hashCode => Object.hash(RolledSpellAmount, dice);

  @override
  String toString() => 'RolledSpellAmount($dice)';
}

/// A printed number, such as Heal's 70 (FR-047).
@immutable
final class FixedSpellAmount extends SpellAmount {
  /// Wraps the printed [value].
  ///
  /// Throws an [ArgumentError] carrying the name `value` and the offending
  /// value when [value] is below 1 (FR-025).
  FixedSpellAmount(int value) : value = _validatedValue(value);

  /// The printed number.
  final int value;

  static int _validatedValue(int value) {
    if (value < 1) {
      throw ArgumentError.value(value, 'value', 'must be at least 1');
    }
    return value;
  }

  @override
  bool operator ==(Object other) =>
      other is FixedSpellAmount && other.value == value;

  @override
  int get hashCode => Object.hash(FixedSpellAmount, value);

  @override
  String toString() => 'FixedSpellAmount($value)';
}

/// An amount a spell's outcome works in: printed dice or a printed number,
/// possibly scaled (FR-047).
///
/// Fireball's "8d6", Heal's "70 Hit Points" (SRD 5.2.1, pp. 131, 139). The
/// scaling, when the spell has one, is an [AmountScaling]; the scaled-value
/// query takes the plain integers of FR-041.
@immutable
final class ScalableAmount {
  /// Creates the amount of [base], scaled by [scaling].
  ///
  /// Throws an [ArgumentError] carrying the name `scaling` and the offending
  /// value when [scaling] is a [PerSlotLevelAmount] whose step adds dice
  /// ([AmountStep.extraDice]) while [base] is fixed: a fixed total grows only
  /// in flat points (FR-016, table L22).
  ScalableAmount(this.base, {this.scaling = const NoAmountScaling()}) {
    if (scaling case PerSlotLevelAmount(
      :final step,
    ) when base is FixedSpellAmount && step.extraDice > 0) {
      throw ArgumentError.value(
        scaling,
        'scaling',
        'extra dice cannot be added to a fixed amount',
      );
    }
  }

  /// The printed base amount.
  final SpellAmount base;

  /// How the amount grows; [NoAmountScaling] when it does not.
  final AmountScaling scaling;

  /// The amount after growth (FR-016, FR-018, FR-041).
  ///
  /// [slotLevelsAbove] is `n`, the number of slot levels above the scaling's
  /// `aboveLevel` (at least 0; a negative value throws), read by a per-slot
  /// scaling; [characterLevel] is the total character level (1 to 20,
  /// otherwise an [ArgumentError]), read by a character-level table. A
  /// scaling that reads neither input returns [base] unchanged.
  SpellAmount amountAt({
    required int slotLevelsAbove,
    required int characterLevel,
  }) => switch (scaling) {
    NoAmountScaling() => base,
    PerSlotLevelAmount(:final step) => step.appliedTo(
      base,
      _validatedN(slotLevelsAbove),
    ),
    ByCharacterLevelAmount(:final table) => table.valueAt(characterLevel),
  };

  @override
  bool operator ==(Object other) =>
      other is ScalableAmount && other.base == base && other.scaling == scaling;

  @override
  int get hashCode => Object.hash(ScalableAmount, base, scaling);

  @override
  String toString() => 'ScalableAmount($base, scaling: $scaling)';
}
