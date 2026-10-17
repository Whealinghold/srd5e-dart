import 'package:meta/meta.dart';

/// The level of a spell, from 0 (a cantrip) to 9 ("Spell Level",
/// SRD 5.2.1, p. 104) (FR-009).
///
/// A value object validated in the constructor; [tryCreate] is the
/// non-throwing form for untrusted input (FR-010). A cantrip is printed
/// "`<School> Cantrip`" instead of "Level N `<School>`", and is cast without a
/// spell slot ("Casting without Slots", p. 104).
@immutable
final class SpellLevel {
  /// Creates the spell level [level].
  ///
  /// Throws an [ArgumentError] carrying the name `level` and the offending
  /// value when [level] is outside [min] to [max] (FR-009). Use [tryCreate]
  /// for untrusted input.
  SpellLevel(int level) : level = _validated(level);

  /// The lowest spell level: a cantrip (FR-009).
  static const int min = 0;

  /// The highest spell level (FR-009).
  static const int max = 9;

  /// The level, from [min] to [max].
  final int level;

  /// Whether this is a cantrip: level [min] (FR-011).
  bool get isCantrip => level == min;

  /// Whether [level] is a spell level: from [min] to [max] inclusive
  /// (FR-009). The predicate the decoder reuses instead of repeating the
  /// range (FR-111).
  static bool isValid(int level) => level >= min && level <= max;

  /// Creates a spell level from untrusted input without throwing (FR-010).
  ///
  /// Returns [SpellLevelParsed] exactly when the constructor would accept
  /// the value, and [SpellLevelRejected] otherwise.
  static SpellLevelParse tryCreate(int value) => isValid(value)
      ? SpellLevelParsed(SpellLevel(value))
      : SpellLevelRejected(value);

  static int _validated(int level) {
    if (!isValid(level)) {
      throw ArgumentError.value(level, 'level', 'must be from $min to $max');
    }
    return level;
  }

  @override
  bool operator ==(Object other) => other is SpellLevel && other.level == level;

  @override
  int get hashCode => Object.hash(SpellLevel, level);

  @override
  String toString() => 'SpellLevel($level)';
}

/// The result of [SpellLevel.tryCreate]: a created level or the rejected
/// integer (FR-010).
///
/// Switch over it exhaustively, with no default branch.
@immutable
sealed class SpellLevelParse {
  const SpellLevelParse();
}

/// [SpellLevel.tryCreate] accepted the value (FR-010).
@immutable
final class SpellLevelParsed extends SpellLevelParse {
  /// Wraps the created [level].
  const SpellLevelParsed(this.level);

  /// The spell level that was created.
  final SpellLevel level;

  @override
  bool operator ==(Object other) =>
      other is SpellLevelParsed && other.level == level;

  @override
  int get hashCode => Object.hash(SpellLevelParsed, level);

  @override
  String toString() => 'SpellLevelParsed($level)';
}

/// [SpellLevel.tryCreate] rejected the value (FR-010).
@immutable
final class SpellLevelRejected extends SpellLevelParse {
  /// Carries the rejected [value].
  const SpellLevelRejected(this.value);

  /// The integer that was rejected.
  final int value;

  @override
  bool operator ==(Object other) =>
      other is SpellLevelRejected && other.value == value;

  @override
  int get hashCode => Object.hash(SpellLevelRejected, value);

  @override
  String toString() => 'SpellLevelRejected($value)';
}
