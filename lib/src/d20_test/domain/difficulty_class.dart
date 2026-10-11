import 'package:meta/meta.dart';

/// The target number of an ability check or a saving throw ("Difficulty
/// Class", SRD 5.2.1, p. 6): the total of the test is compared with it.
///
/// A DC is a value object wrapping a whole number. The SRD gives no minimum
/// or maximum, so the constructor accepts any [int] and never throws.
@immutable
final class DifficultyClass {
  /// Very easy (Typical Difficulty Classes table, SRD 5.2.1, p. 6).
  static const DifficultyClass veryEasy = DifficultyClass(5);

  /// Easy (Typical Difficulty Classes table, SRD 5.2.1, p. 6).
  static const DifficultyClass easy = DifficultyClass(10);

  /// Medium (Typical Difficulty Classes table, SRD 5.2.1, p. 6).
  static const DifficultyClass medium = DifficultyClass(15);

  /// Hard (Typical Difficulty Classes table, SRD 5.2.1, p. 6).
  static const DifficultyClass hard = DifficultyClass(20);

  /// Very hard (Typical Difficulty Classes table, SRD 5.2.1, p. 6).
  static const DifficultyClass veryHard = DifficultyClass(25);

  /// Nearly impossible (Typical Difficulty Classes table, SRD 5.2.1, p. 6).
  static const DifficultyClass nearlyImpossible = DifficultyClass(30);

  /// Creates a Difficulty Class of [value]. Any [int] is valid.
  const DifficultyClass(this.value);

  /// The whole number a test total is compared with.
  final int value;

  @override
  bool operator ==(Object other) =>
      other is DifficultyClass && other.value == value;

  @override
  int get hashCode => value.hashCode;
}
