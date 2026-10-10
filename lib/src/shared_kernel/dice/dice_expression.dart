import 'package:meta/meta.dart';

import 'dice_notation_scanner.dart';
import 'die.dart';

/// Why text or numbers could not become a [DiceExpression].
enum DiceExpressionRejection {
  /// The text was the zero-length string. Whitespace-only text is
  /// [malformed], not empty.
  empty,

  /// The text is not of the form `<count>d<sides>` with an optional modifier
  /// (see [DiceExpression.tryParse]).
  malformed,

  /// The count is below 1 or above [DiceExpression.maxCount].
  countOutOfRange,

  /// The number of sides is below [Die.minSides] or above [Die.maxSides].
  sidesOutOfRange,

  /// The modifier's magnitude is above [DiceExpression.maxModifier].
  modifierOutOfRange,
}

/// A die expression: a count of identical dice plus a flat modifier, such as
/// `1d20` or `2d8 + 2`.
///
/// SRD 5.2.1 calls this a "die expression" ("Hit Points", p. 255, and "Damage
/// Notation", p. 257). The [modifier] is the plain integer printed in the
/// expression, not a roll-time bonus.
///
/// Only single-term expressions exist. Keep-highest, exploding or rerolled
/// dice, `d%`, multiplied dice (`1d4 x 10`) and several terms (`1d6 + 2d4`)
/// are not defined by the SRD and are not modelled.
@immutable
final class DiceExpression {
  /// Creates an expression of [count] dice of [die] plus [modifier].
  ///
  /// Throws an [ArgumentError] carrying the argument name (`count` or
  /// `modifier`) and the offending value when [count] is outside 1 to
  /// [maxCount] or [modifier]'s magnitude is above [maxModifier]. The count is
  /// checked first. Use [tryCreate] or [tryParse] for untrusted input.
  DiceExpression(int count, Die die, {int modifier = 0})
    : this._(_validatedCount(count), die, _validatedModifier(modifier));

  const DiceExpression._(this.count, this.die, this.modifier);

  /// The most dice an expression may have. A package-design limit that bounds
  /// the work a roller may be asked to do.
  static const int maxCount = 1000;

  /// The largest magnitude of a modifier. A package-design limit that keeps
  /// arithmetic within safe integers on every platform.
  static const int maxModifier = 1000000;

  /// How many dice are rolled; from 1 to [maxCount].
  final int count;

  /// The die that is rolled [count] times.
  final Die die;

  /// The flat number added to the total of the dice (negative to subtract).
  final int modifier;

  /// Creates an expression from untrusted numbers without throwing.
  ///
  /// Returns [CreatedDiceExpression] exactly when the [DiceExpression]
  /// constructor would accept the arguments, and otherwise
  /// [RejectedDiceExpressionInput] with
  /// [DiceExpressionRejection.countOutOfRange] or
  /// [DiceExpressionRejection.modifierOutOfRange], checking the count first.
  static DiceExpressionCreation tryCreate(
    int count,
    Die die, {
    int modifier = 0,
  }) {
    final reason = _rejection(count, modifier);
    return reason == null
        ? CreatedDiceExpression(DiceExpression._(count, die, modifier))
        : RejectedDiceExpressionInput(reason);
  }

  /// Reads an expression from untrusted text without throwing.
  ///
  /// Accepted text is `<count>d<sides>` with the count optional (`d20` is
  /// `1d20`), a lower- or upper-case `d`, and an optional modifier. The
  /// modifier sign is `+`, `-` or U+2212, followed by digits, with no spaces
  /// (`1d4+2`) or exactly one space on each side of the sign (`2d8 + 2`).
  /// Digits are ASCII only and leading zeros are read as decimal (`01d6` is
  /// `1d6`). Surrounding whitespace, other spacing, other dashes (U+2013) and
  /// non-ASCII digits are [DiceExpressionRejection.malformed].
  ///
  /// Returns [ParsedDiceExpression], or [RejectedDiceExpression] with exactly
  /// one reason: the shape is judged first, then the count, the sides and the
  /// modifier in that order. Numbers too large to represent are out of range.
  static DiceExpressionParse tryParse(String text) {
    if (text.isEmpty) {
      return const RejectedDiceExpression(DiceExpressionRejection.empty);
    }
    final tokens = scanDiceNotation(text);
    if (tokens == null) {
      return const RejectedDiceExpression(DiceExpressionRejection.malformed);
    }

    final count = tokens.countDigits.isEmpty
        ? 1
        : _readNumber(tokens.countDigits);
    final sides = _readNumber(tokens.sidesDigits);
    final magnitude = tokens.modifierDigits.isEmpty
        ? 0
        : _readNumber(tokens.modifierDigits);

    if (count < 1 || count > maxCount) {
      return const RejectedDiceExpression(
        DiceExpressionRejection.countOutOfRange,
      );
    }
    if (sides < Die.minSides || sides > Die.maxSides) {
      return const RejectedDiceExpression(
        DiceExpressionRejection.sidesOutOfRange,
      );
    }
    if (magnitude > maxModifier) {
      return const RejectedDiceExpression(
        DiceExpressionRejection.modifierOutOfRange,
      );
    }
    return ParsedDiceExpression(
      DiceExpression._(
        count,
        Die(sides),
        tokens.isNegative ? -magnitude : magnitude,
      ),
    );
  }

  /// The lowest total: every die shows 1, so `count + modifier`.
  int get minimum => count + modifier;

  /// The highest total: every die shows its highest face, so
  /// `count * sides + modifier`.
  int get maximum => count * die.sides + modifier;

  /// The average total, `count * (sides + 1) / 2 + modifier`, rounded down
  /// (towards negative infinity) as "Round Down" (SRD 5.2.1, p. 5) says
  /// ("2d8 + 2" averages 11, "1d20" averages 10, "1d4 - 5" averages -3).
  int get average => ((count * (die.sides + 1) + 2 * modifier) / 2).floor();

  /// Whether [doubleDice] is allowed: exactly when `count * 2` is at most
  /// [maxCount].
  bool get canDoubleDice => count * 2 <= maxCount;

  /// The expression with the count doubled and the same die and modifier,
  /// as for a Critical Hit: "Roll the attack's damage dice twice, add them
  /// together" and the modifiers are added as normal (SRD 5.2.1, "Critical
  /// Hits", p. 16). `1d4 + 3` gives `2d4 + 3`.
  ///
  /// Throws an [ArgumentError] carrying the name `count` and this
  /// expression's count when [canDoubleDice] is `false`. This expression is
  /// not changed.
  DiceExpression doubleDice() {
    if (!canDoubleDice) {
      throw ArgumentError.value(
        count,
        'count',
        'doubling must not exceed $maxCount dice',
      );
    }
    return DiceExpression._(count * 2, die, modifier);
  }

  /// The canonical machine form: the count always present, a lower-case `d`,
  /// no spaces, an ASCII sign, and the modifier omitted when it is 0 (`1d20`,
  /// `2d8+2`, `1d4-5`).
  ///
  /// It is an identifier for content and logs, not display text.
  /// `DiceExpression.tryParse(expression.notation)` returns an expression
  /// equal to this one.
  String get notation {
    final tail = switch (modifier) {
      0 => '',
      > 0 => '+$modifier',
      _ => '$modifier',
    };
    return '${count}d${die.sides}$tail';
  }

  /// Reads ASCII [digits] as a decimal number; leading zeros are read as
  /// decimal. A number too large to represent as an integer is read as
  /// [_tooLarge], which is above every limit, so it is out of range and never
  /// throws.
  static int _readNumber(String digits) => int.tryParse(digits) ?? _tooLarge;

  /// A value above every limit, standing in for a number too large to read.
  static const int _tooLarge = 2000000000;

  static DiceExpressionRejection? _rejection(int count, int modifier) {
    if (count < 1 || count > maxCount) {
      return DiceExpressionRejection.countOutOfRange;
    }
    if (modifier.abs() > maxModifier) {
      return DiceExpressionRejection.modifierOutOfRange;
    }
    return null;
  }

  static int _validatedCount(int count) {
    if (count < 1 || count > maxCount) {
      throw ArgumentError.value(count, 'count', 'must be from 1 to $maxCount');
    }
    return count;
  }

  static int _validatedModifier(int modifier) {
    if (modifier.abs() > maxModifier) {
      throw ArgumentError.value(
        modifier,
        'modifier',
        'must have a magnitude of at most $maxModifier',
      );
    }
    return modifier;
  }

  @override
  bool operator ==(Object other) =>
      other is DiceExpression &&
      other.count == count &&
      other.die == die &&
      other.modifier == modifier;

  @override
  int get hashCode => Object.hash(count, die, modifier);

  /// The debugging form, the same as [notation]. Not display text.
  @override
  String toString() => notation;
}

/// The result of [DiceExpression.tryCreate]: a created expression or a typed
/// rejection.
@immutable
sealed class DiceExpressionCreation {
  const DiceExpressionCreation();
}

/// [DiceExpression.tryCreate] accepted the arguments.
final class CreatedDiceExpression extends DiceExpressionCreation {
  /// Wraps the created [value].
  const CreatedDiceExpression(this.value);

  /// The expression that was created.
  final DiceExpression value;

  @override
  bool operator ==(Object other) =>
      other is CreatedDiceExpression && other.value == value;

  @override
  int get hashCode => Object.hash(CreatedDiceExpression, value);

  @override
  String toString() => 'CreatedDiceExpression($value)';
}

/// [DiceExpression.tryCreate] rejected the arguments.
final class RejectedDiceExpressionInput extends DiceExpressionCreation {
  /// Carries the typed [reason].
  const RejectedDiceExpressionInput(this.reason);

  /// Why the expression was rejected: [DiceExpressionRejection.countOutOfRange]
  /// or [DiceExpressionRejection.modifierOutOfRange].
  final DiceExpressionRejection reason;

  @override
  bool operator ==(Object other) =>
      other is RejectedDiceExpressionInput && other.reason == reason;

  @override
  int get hashCode => Object.hash(RejectedDiceExpressionInput, reason);

  @override
  String toString() => 'RejectedDiceExpressionInput(${reason.name})';
}

/// The result of [DiceExpression.tryParse]: a parsed expression or a typed
/// rejection.
@immutable
sealed class DiceExpressionParse {
  const DiceExpressionParse();
}

/// [DiceExpression.tryParse] read the text.
final class ParsedDiceExpression extends DiceExpressionParse {
  /// Wraps the parsed [expression].
  const ParsedDiceExpression(this.expression);

  /// The expression that was read.
  final DiceExpression expression;

  @override
  bool operator ==(Object other) =>
      other is ParsedDiceExpression && other.expression == expression;

  @override
  int get hashCode => Object.hash(ParsedDiceExpression, expression);

  @override
  String toString() => 'ParsedDiceExpression($expression)';
}

/// [DiceExpression.tryParse] rejected the text.
final class RejectedDiceExpression extends DiceExpressionParse {
  /// Carries the typed [reason].
  const RejectedDiceExpression(this.reason);

  /// Why the text was rejected; exactly one reason per parse.
  final DiceExpressionRejection reason;

  @override
  bool operator ==(Object other) =>
      other is RejectedDiceExpression && other.reason == reason;

  @override
  int get hashCode => Object.hash(RejectedDiceExpression, reason);

  @override
  String toString() => 'RejectedDiceExpression(${reason.name})';
}
