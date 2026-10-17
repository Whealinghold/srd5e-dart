import 'package:meta/meta.dart';

/// The space one creature of a size occupies, from the Creature Size and
/// Space table (SRD 5.2.1, p. 14), as a sealed, value-equal, immutable
/// family whose instances are the six constants only — no public constructor
/// exists (FR-139).
///
/// A Tiny creature shares a 5-foot square with up to three others; every
/// other size occupies whole squares. Which squares a creature occupies, and
/// the rules that follow from a size, are other specs' concerns.
@immutable
sealed class CreatureSpace {
  const CreatureSpace._();

  /// The side of the space one creature occupies, in feet (Creature Size and
  /// Space table, SRD 5.2.1, p. 14).
  double get sideFeet;

  /// The space of a Tiny creature: 2.5 feet on a side, up to 4 per
  /// 5-foot square (Creature Size and Space table, SRD 5.2.1, p. 14).
  static const SharedSquareSpace tiny = SharedSquareSpace._(
    creaturesPerSquare: 4,
  );

  /// The space of a Small creature: one 5-foot square.
  static const WholeSquareSpace small = WholeSquareSpace._(squaresPerSide: 1);

  /// The space of a Medium creature: one 5-foot square.
  static const WholeSquareSpace medium = WholeSquareSpace._(squaresPerSide: 1);

  /// The space of a Large creature: a 2-by-2 square area.
  static const WholeSquareSpace large = WholeSquareSpace._(squaresPerSide: 2);

  /// The space of a Huge creature: a 3-by-3 square area.
  static const WholeSquareSpace huge = WholeSquareSpace._(squaresPerSide: 3);

  /// The space of a Gargantuan creature: a 4-by-4 square area.
  static const WholeSquareSpace gargantuan = WholeSquareSpace._(
    squaresPerSide: 4,
  );
}

/// The space of a creature that shares one 5-foot square with others: the
/// space of a Tiny creature, 2.5 feet on a side (FR-139).
@immutable
final class SharedSquareSpace extends CreatureSpace {
  const SharedSquareSpace._({required this.creaturesPerSquare}) : super._();

  /// How many creatures of this size fit in one 5-foot square.
  final int creaturesPerSquare;

  /// The side of the space one creature occupies, in feet: 2.5 for the one
  /// shared-square instance (Creature Size and Space table, SRD 5.2.1,
  /// p. 14).
  @override
  double get sideFeet => 2.5;

  @override
  bool operator ==(Object other) =>
      other is SharedSquareSpace &&
      other.creaturesPerSquare == creaturesPerSquare;

  @override
  int get hashCode => Object.hash(SharedSquareSpace, creaturesPerSquare);

  @override
  String toString() =>
      'SharedSquareSpace(creaturesPerSquare: '
      '$creaturesPerSquare)';
}

/// The space of a creature that occupies whole 5-foot squares: Small through
/// Gargantuan (FR-139).
@immutable
final class WholeSquareSpace extends CreatureSpace {
  const WholeSquareSpace._({required this.squaresPerSide}) : super._();

  /// How many 5-foot squares the space spans on each side.
  final int squaresPerSide;

  /// How many 5-foot squares the space covers: [squaresPerSide] squared.
  int get squares => squaresPerSide * squaresPerSide;

  /// The side of the space one creature occupies, in feet: 5 feet per
  /// square times [squaresPerSide] (Creature Size and Space table, SRD
  /// 5.2.1, p. 14).
  @override
  double get sideFeet => 5.0 * squaresPerSide;

  @override
  bool operator ==(Object other) =>
      other is WholeSquareSpace && other.squaresPerSide == squaresPerSide;

  @override
  int get hashCode => Object.hash(WholeSquareSpace, squaresPerSide);

  @override
  String toString() => 'WholeSquareSpace(squaresPerSide: $squaresPerSide)';
}

/// One of the 6 creature sizes, in ascending order ("Size", SRD 5.2.1,
/// p. 254; "Glossary: Size", p. 188), with the space each occupies (FR-109,
/// FR-139).
///
/// The JSON spelling is the printed name.
enum CreatureSize {
  /// Tiny.
  tiny('Tiny', CreatureSpace.tiny),

  /// Small.
  small('Small', CreatureSpace.small),

  /// Medium.
  medium('Medium', CreatureSpace.medium),

  /// Large.
  large('Large', CreatureSpace.large),

  /// Huge.
  huge('Huge', CreatureSpace.huge),

  /// Gargantuan.
  gargantuan('Gargantuan', CreatureSpace.gargantuan);

  const CreatureSize(this.jsonValue, this.space);

  /// The printed name used in JSON.
  final String jsonValue;

  /// The row of the Creature Size and Space table for this size (SRD 5.2.1,
  /// p. 14).
  final CreatureSpace space;

  /// The member whose [jsonValue] is [value], or null for a non-member: the
  /// decoder turns a non-member into `invalidValue` (FR-105, FR-025).
  static CreatureSize? fromJson(String value) => switch (value) {
    'Tiny' => tiny,
    'Small' => small,
    'Medium' => medium,
    'Large' => large,
    'Huge' => huge,
    'Gargantuan' => gargantuan,
    _ => null,
  };
}
