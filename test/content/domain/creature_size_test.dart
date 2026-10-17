import 'package:srd5e/src/content/domain/creature_size.dart';
import 'package:test/test.dart';

import '../../support/operator_equals.dart';

/// Exhaustive over the sealed space family with no default branch (FR-139).
String _describeSpace(CreatureSpace space) => switch (space) {
  SharedSquareSpace() => 'shared',
  WholeSquareSpace() => 'whole',
};

/// Exhaustive over the enum with no default branch (FR-109).
String _describeSize(CreatureSize size) => switch (size) {
  CreatureSize.tiny => 'tiny',
  CreatureSize.small => 'small',
  CreatureSize.medium => 'medium',
  CreatureSize.large => 'large',
  CreatureSize.huge => 'huge',
  CreatureSize.gargantuan => 'gargantuan',
};

/// One row of the Creature Size and Space table (SRD 5.2.1, p. 14).
typedef _SpaceCase = ({
  String label,
  String requirement,
  String path,
  CreatureSize size,
  double sideFeet,
  int creaturesPerSquareOrSquaresPerSide,
  int? squares,
});

final List<_SpaceCase> _spaceCases = [
  (
    label: 'Tiny',
    requirement:
        'doc/specs/content-schema-and-decoder.md FR-139 - Tiny is '
        '2.5 feet and 4 per square (SRD 5.2.1, "Creature Size", Creature Size '
        'and Space table, p. 14)',
    path: 'happy',
    size: CreatureSize.tiny,
    sideFeet: 2.5,
    creaturesPerSquareOrSquaresPerSide: 4,
    squares: null,
  ),
  (
    label: 'Small',
    requirement:
        'doc/specs/content-schema-and-decoder.md FR-139 - Small is '
        '5 feet and 1 square (SRD 5.2.1, "Creature Size", Creature Size and '
        'Space table, p. 14)',
    path: 'happy',
    size: CreatureSize.small,
    sideFeet: 5.0,
    creaturesPerSquareOrSquaresPerSide: 1,
    squares: 1,
  ),
  (
    label: 'Medium',
    requirement:
        'doc/specs/content-schema-and-decoder.md FR-139 - Medium is '
        '5 feet and 1 square (SRD 5.2.1, "Creature Size", Creature Size and '
        'Space table, p. 14)',
    path: 'happy',
    size: CreatureSize.medium,
    sideFeet: 5.0,
    creaturesPerSquareOrSquaresPerSide: 1,
    squares: 1,
  ),
  (
    label: 'Large',
    requirement:
        'doc/specs/content-schema-and-decoder.md FR-139 - Large is '
        '10 feet and 4 squares (SRD 5.2.1, "Creature Size", Creature Size and '
        'Space table, p. 14)',
    path: 'happy',
    size: CreatureSize.large,
    sideFeet: 10.0,
    creaturesPerSquareOrSquaresPerSide: 2,
    squares: 4,
  ),
  (
    label: 'Huge',
    requirement:
        'doc/specs/content-schema-and-decoder.md FR-139 - Huge is '
        '15 feet and 9 squares (SRD 5.2.1, "Creature Size", Creature Size and '
        'Space table, p. 14)',
    path: 'happy',
    size: CreatureSize.huge,
    sideFeet: 15.0,
    creaturesPerSquareOrSquaresPerSide: 3,
    squares: 9,
  ),
  (
    label: 'Gargantuan',
    requirement:
        'doc/specs/content-schema-and-decoder.md FR-139 - Gargantuan '
        'is 20 feet and 16 squares (SRD 5.2.1, "Creature Size", Creature Size '
        'and Space table, p. 14)',
    path: 'happy',
    size: CreatureSize.gargantuan,
    sideFeet: 20.0,
    creaturesPerSquareOrSquaresPerSide: 4,
    squares: 16,
  ),
];

void main() {
  /// Requirement: doc/specs/content-schema-and-decoder.md FR-109 - exactly
  ///   six members in ascending order, JSON the printed name (SRD 5.2.1,
  ///   "Monsters", "Size", p. 254).
  /// Path: happy
  test('declares exactly six members in ascending order', () {
    expect(CreatureSize.values.map((size) => size.jsonValue), [
      'Tiny',
      'Small',
      'Medium',
      'Large',
      'Huge',
      'Gargantuan',
    ]);
  });

  /// Requirement: per case
  /// Path: per case
  for (final c in _spaceCases) {
    test('${c.label} space [per case]', () {
      final space = c.size.space;
      expect(space.sideFeet, c.sideFeet);
      switch (space) {
        case SharedSquareSpace(:final creaturesPerSquare):
          expect(creaturesPerSquare, c.creaturesPerSquareOrSquaresPerSide);
        case WholeSquareSpace(:final squaresPerSide, :final squares):
          expect(squaresPerSide, c.creaturesPerSquareOrSquaresPerSide);
          expect(squares, c.squares);
      }
    });
  }

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-139 - size
  ///   consistency: sideFeet is 5 feet times squaresPerSide for every whole-
  ///   square size.
  /// Path: unhappy (rule interaction)
  test('every whole-square size has sideFeet of 5 feet per square', () {
    for (final size in CreatureSize.values) {
      final space = size.space;
      if (space is WholeSquareSpace) {
        expect(space.sideFeet, 5.0 * space.squaresPerSide);
      }
    }
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-139 - the
  ///   family is sealed and value-equal, with no public constructor, so the
  ///   six constants are the only instances.
  /// Path: happy
  test('space constants are value-equal and switch exhaustively', () {
    expect(CreatureSpace.small, CreatureSpace.medium);
    expect(CreatureSpace.small.hashCode, CreatureSpace.medium.hashCode);
    expect(operatorEquals(CreatureSpace.tiny, CreatureSpace.small), isFalse);
    expect(operatorEquals(CreatureSpace.large, CreatureSpace.huge), isFalse);
    for (final size in CreatureSize.values) {
      expect(
        _describeSpace(size.space),
        size == CreatureSize.tiny ? 'shared' : 'whole',
      );
    }
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-105 - the
  ///   static fromJson accepts exactly the jsonValue spellings.
  /// Path: happy
  test('fromJson round-trips every member and rejects near misses', () {
    for (final size in CreatureSize.values) {
      expect(CreatureSize.fromJson(size.jsonValue), size);
    }
    expect(CreatureSize.fromJson('tiny'), isNull);
    expect(CreatureSize.fromJson(' Huge'), isNull);
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-109 - a switch
  ///   over CreatureSize is exhaustive without a default.
  /// Path: happy
  test('a switch over every member selects its case', () {
    expect(
      [for (final size in CreatureSize.values) _describeSize(size)],
      ['tiny', 'small', 'medium', 'large', 'huge', 'gargantuan'],
    );
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-139 - the space
  ///   family is value-equal, hashes by value and prints its parts.
  /// Path: happy
  test('space constants hash by value and print their parts', () {
    expect({CreatureSpace.tiny: 1}[CreatureSpace.tiny], 1);
    expect(
      CreatureSpace.tiny.toString(),
      'SharedSquareSpace(creaturesPerSquare: 4)',
    );
    expect({CreatureSpace.large: 1}[CreatureSpace.large], 1);
    expect(
      CreatureSpace.large.toString(),
      'WholeSquareSpace(squaresPerSide: 2)',
    );
  });
}
