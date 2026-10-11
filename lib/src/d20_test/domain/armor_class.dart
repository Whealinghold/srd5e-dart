import 'package:meta/meta.dart';

/// The target number of an attack roll ("Armor Class", SRD 5.2.1, p. 7): the
/// attack total is compared with it.
///
/// An AC is a value object wrapping a whole number, owned by this context.
/// The SRD gives no minimum or maximum, so the constructor accepts any [int]
/// and never throws. An `ArmorClass` never compares equal to a
/// `DifficultyClass` for the same number: they are different target numbers.
@immutable
final class ArmorClass {
  /// Creates an Armor Class of [value]. Any [int] is valid.
  const ArmorClass(this.value);

  /// The whole number an attack total is compared with.
  final int value;

  @override
  bool operator ==(Object other) => other is ArmorClass && other.value == value;

  @override
  int get hashCode => value.hashCode;
}
