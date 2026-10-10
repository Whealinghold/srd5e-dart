import 'package:meta/meta.dart';

import 'dice_expression.dart';
import 'die_roll.dart';

/// Why a [RollResult] could not be created from an expression and rolls.
enum RollResultRejection {
  /// The number of rolls differs from the expression's count.
  rollCountMismatch,

  /// A roll is of a different die than the expression's.
  dieMismatch,
}

/// The roll made for a [DiceExpression]: the expression, every [DieRoll] and
/// the totals.
///
/// Domain code never rolls: a use case obtains a result through the
/// `DiceRoller` port and hands it to pure domain code as a value. A result
/// does not clamp its [total]: it may be zero or negative, and the rule that
/// applies it decides what to do ("Damage Rolls", SRD 5.2.1, p. 16).
@immutable
final class RollResult {
  /// Creates the result of rolling [expression], with one entry of [rolls] per
  /// die, in order.
  ///
  /// The list is copied. Throws an [ArgumentError] carrying the name `rolls`
  /// and the given list when the number of rolls differs from
  /// `expression.count`, or when a roll is of a different die than
  /// `expression.die` (the count is checked first). Use [tryCreate] for
  /// untrusted input.
  RollResult(DiceExpression expression, List<DieRoll> rolls)
    : this._(expression, _validated(expression, rolls));

  RollResult._(this.expression, this.rolls)
    : diceTotal = _sum(rolls.map((roll) => roll.value));

  /// The expression that was rolled.
  final DiceExpression expression;

  /// The roll of each die, in the order they were rolled. Unmodifiable.
  final List<DieRoll> rolls;

  /// The sum of the face values, without the modifier.
  final int diceTotal;

  /// The expression's flat modifier.
  int get modifier => expression.modifier;

  /// The result of the expression: [diceTotal] plus [modifier]. It is not
  /// clamped and may be zero or negative.
  int get total => diceTotal + modifier;

  /// The sum of the [n] highest face values, ignoring the modifier ("the
  /// highest three dice", SRD 5.2.1, "Random Generation", p. 21; "the higher
  /// one", "D20 Tests", p. 6). Ties count normally and roll order does not
  /// matter; [rolls] is left unchanged.
  ///
  /// Throws an [ArgumentError] carrying the name `n` and the value when [n] is
  /// below 1 or above the expression's count. With `n == count` the result
  /// equals [diceTotal].
  int sumOfHighest(int n) {
    final faces = _sortedFaces(n);
    return _sum(faces.skip(faces.length - n));
  }

  /// The sum of the [n] lowest face values, ignoring the modifier ("the lower
  /// one", SRD 5.2.1, "D20 Tests", p. 6; "Roll Two D20s", p. 8). Ties count
  /// normally and roll order does not matter; [rolls] is left unchanged.
  ///
  /// Throws an [ArgumentError] carrying the name `n` and the value when [n] is
  /// below 1 or above the expression's count. With `n == count` the result
  /// equals [diceTotal].
  int sumOfLowest(int n) => _sum(_sortedFaces(n).take(n));

  /// Creates a result from untrusted input without throwing.
  ///
  /// Returns [CreatedRollResult] exactly when the [RollResult] constructor
  /// would accept the arguments, and otherwise [RejectedRollResult] with
  /// [RollResultRejection.rollCountMismatch] or
  /// [RollResultRejection.dieMismatch], checking the count first. The list is
  /// copied and not mutated.
  static RollResultCreation tryCreate(
    DiceExpression expression,
    List<DieRoll> rolls,
  ) {
    final reason = _rejection(expression, rolls);
    return reason == null
        ? CreatedRollResult(
            RollResult._(expression, List<DieRoll>.unmodifiable(rolls)),
          )
        : RejectedRollResult(reason);
  }

  List<int> _sortedFaces(int n) {
    if (n < 1 || n > expression.count) {
      throw ArgumentError.value(
        n,
        'n',
        'must be from 1 to ${expression.count}',
      );
    }
    return [for (final roll in rolls) roll.value]..sort();
  }

  static int _sum(Iterable<int> values) =>
      values.fold(0, (sum, value) => sum + value);

  static RollResultRejection? _rejection(
    DiceExpression expression,
    List<DieRoll> rolls,
  ) {
    if (rolls.length != expression.count) {
      return RollResultRejection.rollCountMismatch;
    }
    if (rolls.any((roll) => roll.die != expression.die)) {
      return RollResultRejection.dieMismatch;
    }
    return null;
  }

  static List<DieRoll> _validated(
    DiceExpression expression,
    List<DieRoll> rolls,
  ) {
    if (_rejection(expression, rolls) != null) {
      throw ArgumentError.value(
        rolls,
        'rolls',
        'must hold exactly ${expression.count} rolls of ${expression.die}',
      );
    }
    return List<DieRoll>.unmodifiable(rolls);
  }

  @override
  bool operator ==(Object other) {
    // Equal expressions have equal counts, and a result holds exactly that
    // many rolls, so the two lists have the same length here.
    if (other is! RollResult || other.expression != expression) return false;
    for (var i = 0; i < rolls.length; i++) {
      if (other.rolls[i] != rolls[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(expression, Object.hashAll(rolls));

  /// The debugging form, the expression's notation and the faces. Not display
  /// text.
  @override
  String toString() => '$expression $rolls';
}

/// The result of [RollResult.tryCreate]: a created result or a typed
/// rejection.
@immutable
sealed class RollResultCreation {
  const RollResultCreation();
}

/// [RollResult.tryCreate] accepted the rolls.
final class CreatedRollResult extends RollResultCreation {
  /// Wraps the created [value].
  const CreatedRollResult(this.value);

  /// The result that was created.
  final RollResult value;

  @override
  bool operator ==(Object other) =>
      other is CreatedRollResult && other.value == value;

  @override
  int get hashCode => Object.hash(CreatedRollResult, value);

  @override
  String toString() => 'CreatedRollResult($value)';
}

/// [RollResult.tryCreate] rejected the rolls.
final class RejectedRollResult extends RollResultCreation {
  /// Carries the typed [reason].
  const RejectedRollResult(this.reason);

  /// Why the result was rejected.
  final RollResultRejection reason;

  @override
  bool operator ==(Object other) =>
      other is RejectedRollResult && other.reason == reason;

  @override
  int get hashCode => Object.hash(RejectedRollResult, reason);

  @override
  String toString() => 'RejectedRollResult(${reason.name})';
}
