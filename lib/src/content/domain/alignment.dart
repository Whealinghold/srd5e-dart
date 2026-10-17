/// One of the 10 alignments stat blocks print ("The Nine Alignments", SRD
/// 5.2.1, p. 21; "Unaligned Creatures", p. 22; "Alignment", p. 254), in the
/// order of FR-137 (FR-137).
///
/// The JSON spelling is the printed full name, never the abbreviation, and
/// no stat block prints "Any Alignment", so `LG` and `Any Alignment` are
/// non-members. It carries no rules: in a stat block an alignment is a
/// default suggestion, and a player character's alignment (and the refusal
/// of [unaligned]) is the character-creation rules' concern.
enum Alignment {
  /// Lawful Good.
  lawfulGood('Lawful Good'),

  /// Neutral Good.
  neutralGood('Neutral Good'),

  /// Chaotic Good.
  chaoticGood('Chaotic Good'),

  /// Lawful Neutral.
  lawfulNeutral('Lawful Neutral'),

  /// Neutral.
  neutral('Neutral'),

  /// Chaotic Neutral.
  chaoticNeutral('Chaotic Neutral'),

  /// Lawful Evil.
  lawfulEvil('Lawful Evil'),

  /// Neutral Evil.
  neutralEvil('Neutral Evil'),

  /// Chaotic Evil.
  chaoticEvil('Chaotic Evil'),

  /// Unaligned ("Unaligned Creatures", SRD 5.2.1, p. 22).
  unaligned('Unaligned');

  const Alignment(this.jsonValue);

  /// The printed name used in JSON.
  final String jsonValue;

  /// The member whose [jsonValue] is [value], or null for a non-member: the
  /// decoder turns a non-member into `invalidValue` (FR-105, FR-025).
  static Alignment? fromJson(String value) => switch (value) {
    'Lawful Good' => lawfulGood,
    'Neutral Good' => neutralGood,
    'Chaotic Good' => chaoticGood,
    'Lawful Neutral' => lawfulNeutral,
    'Neutral' => neutral,
    'Chaotic Neutral' => chaoticNeutral,
    'Lawful Evil' => lawfulEvil,
    'Neutral Evil' => neutralEvil,
    'Chaotic Evil' => chaoticEvil,
    'Unaligned' => unaligned,
    _ => null,
  };
}
