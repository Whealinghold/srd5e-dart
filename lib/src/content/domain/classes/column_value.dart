import 'package:meta/meta.dart';

import '../../../shared_kernel/dice/die.dart';
import 'class_column.dart';

/// One cell of a class-specific column of a Features table, under its
/// declared [ClassColumnKind] (FR-040).
///
/// The family is sealed with exactly the five variants, exhaustive in a
/// `switch` without a default. `ColumnNone` — the printed em dash — is
/// allowed for every kind (FR-040); the other variants are accepted only
/// under their own kind, which the [ClassDefinition] constructor checks.
@immutable
sealed class ColumnValue {
  const ColumnValue();
}

/// A cell that is a whole-number count, 0 or more (FR-040).
@immutable
final class ColumnCount extends ColumnValue {
  /// Creates the cell.
  ///
  /// Throws an [ArgumentError] carrying the name `value` and the offending
  /// input when [value] is below [minValue] (FR-040).
  ColumnCount(this.value) {
    if (value < minValue) {
      throw ArgumentError.value(value, 'value', 'must be $minValue or more');
    }
  }

  /// The lowest count a cell may hold: 0 (FR-040). The constant the decoder
  /// reuses instead of repeating the literal (FR-007).
  static const int minValue = 0;

  /// The count.
  final int value;

  /// Whether [value] is a count a cell may hold: [minValue] or more
  /// (FR-040). The predicate the decoder reuses (FR-007).
  static bool isValid(int value) => value >= minValue;

  @override
  bool operator ==(Object other) =>
      other is ColumnCount && other.value == value;

  @override
  int get hashCode => Object.hash(ColumnCount, value);

  @override
  String toString() => 'ColumnCount($value)';
}

/// A cell that is a dice expression: [count] dice with [sides] sides each
/// (FR-040; SRD 5.2.1, "Monk Features", Martial Arts column, p. 50).
@immutable
final class ColumnDice extends ColumnValue {
  /// Creates the cell with the die of [sides] sides.
  ///
  /// Throws an [ArgumentError] carrying the name `count` or `sides` and the
  /// offending input when [count] is below [minCount] or [sides] is not a
  /// valid [Die] (FR-040).
  ColumnDice(int count, int sides)
    : count = _validatedCount(count),
      sides = Die(sides);

  /// The fewest dice a cell may hold: one (FR-040). The constant the decoder
  /// reuses instead of repeating the literal (FR-007).
  static const int minCount = 1;

  /// How many dice the column's roll uses; at least [minCount] (FR-040).
  final int count;

  /// The die the column's roll uses.
  final Die sides;

  /// Whether [count] is a number of dice a cell may hold: [minCount] or more
  /// (FR-040). The predicate the decoder reuses (FR-007).
  static bool isValidCount(int count) => count >= minCount;

  static int _validatedCount(int count) {
    if (!isValidCount(count)) {
      throw ArgumentError.value(count, 'count', 'must be $minCount or more');
    }
    return count;
  }

  @override
  bool operator ==(Object other) =>
      other is ColumnDice && other.count == count && other.sides == sides;

  @override
  int get hashCode => Object.hash(ColumnDice, count, sides);

  @override
  String toString() => 'ColumnDice($count, $sides)';
}

/// A cell that is a flat bonus, 0 or more (FR-040).
@immutable
final class ColumnBonus extends ColumnValue {
  /// Creates the cell.
  ///
  /// Throws an [ArgumentError] carrying the name `value` and the offending
  /// input when [value] is below [minValue] (FR-040).
  ColumnBonus(this.value) {
    if (value < minValue) {
      throw ArgumentError.value(value, 'value', 'must be $minValue or more');
    }
  }

  /// The lowest bonus a cell may hold: 0 (FR-040). The constant the decoder
  /// reuses instead of repeating the literal (FR-007).
  static const int minValue = 0;

  /// The bonus.
  final int value;

  /// Whether [value] is a bonus a cell may hold: [minValue] or more
  /// (FR-040). The predicate the decoder reuses (FR-007).
  static bool isValid(int value) => value >= minValue;

  @override
  bool operator ==(Object other) =>
      other is ColumnBonus && other.value == value;

  @override
  int get hashCode => Object.hash(ColumnBonus, value);

  @override
  String toString() => 'ColumnBonus($value)';
}

/// A cell that is a bonus in feet (FR-040).
@immutable
final class ColumnFeetBonus extends ColumnValue {
  /// Creates the cell. The SRD states no range for a feet bonus, so no
  /// constructor rule rejects one (FR-040).
  const ColumnFeetBonus(this.value);

  /// The bonus, in feet.
  final int value;

  @override
  bool operator ==(Object other) =>
      other is ColumnFeetBonus && other.value == value;

  @override
  int get hashCode => Object.hash(ColumnFeetBonus, value);

  @override
  String toString() => 'ColumnFeetBonus($value)';
}

/// A cell the SRD prints as an em dash: "—" (U+2014) (FR-040, D7; SRD 5.2.1,
/// "Monk Features" (Focus Points "—"), p. 50).
@immutable
final class ColumnNone extends ColumnValue {
  /// Creates the cell; every instance equals every other.
  const ColumnNone();

  @override
  bool operator ==(Object other) => other is ColumnNone;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'ColumnNone';
}
