/// One of the 4 Hit Point Dice of the class Core Traits tables ("Hit Point
/// Die" rows, SRD 5.2.1, pp. 28, 31, 36, 41, 47, 49, 53, 57, 61, 64, 70,
/// 77), in ascending order (FR-132).
///
/// The JSON value is the class-table spelling `D6`, `D8`, `D10`, `D12`, case
/// sensitive. The type is closed and separate from the kernel's `Die` (it
/// cannot name a d20); converting is `Die(faces)`, the consumer's concern.
/// The derived Hit Point values are other specs' concerns.
enum HitPointDie {
  /// D6; the Sorcerer's and Wizard's die ("Level 1 Hit Points by Class",
  /// SRD 5.2.1, p. 22).
  d6('D6', 6),

  /// D8; Bard, Cleric, Druid, Monk, Rogue and Warlock.
  d8('D8', 8),

  /// D10; Fighter, Paladin and Ranger.
  d10('D10', 10),

  /// D12; the Barbarian's die ("Core Barbarian Traits", SRD 5.2.1, p. 28).
  d12('D12', 12);

  const HitPointDie(this.jsonValue, this.faces);

  /// The class-table spelling used in JSON.
  final String jsonValue;

  /// The number of faces: 6, 8, 10, 12.
  final int faces;

  /// The member whose [jsonValue] is [value], or null for a non-member: the
  /// decoder turns a non-member into `invalidValue` (FR-105, FR-025).
  static HitPointDie? fromJson(String value) => switch (value) {
    'D6' => d6,
    'D8' => d8,
    'D10' => d10,
    'D12' => d12,
    _ => null,
  };
}
