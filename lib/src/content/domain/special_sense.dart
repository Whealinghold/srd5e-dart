/// One of the 4 special senses ("Special Senses", SRD 5.2.1, p. 11;
/// "Blindsight", p. 177; "Darkvision", p. 180; "Tremorsense", "Truesight",
/// p. 190), in SRD order (FR-136).
///
/// The JSON spelling is the printed name. Identity only: sense ranges and
/// the sight rules belong to the hiding-searching-and-senses and monster
/// rules.
enum SpecialSense {
  /// Blindsight.
  blindsight('Blindsight'),

  /// Darkvision.
  darkvision('Darkvision'),

  /// Tremorsense.
  tremorsense('Tremorsense'),

  /// Truesight.
  truesight('Truesight');

  const SpecialSense(this.jsonValue);

  /// The printed name used in JSON.
  final String jsonValue;

  /// The member whose [jsonValue] is [value], or null for a non-member: the
  /// decoder turns a non-member into `invalidValue` (FR-105, FR-025).
  static SpecialSense? fromJson(String value) => switch (value) {
    'Blindsight' => blindsight,
    'Darkvision' => darkvision,
    'Tremorsense' => tremorsense,
    'Truesight' => truesight,
    _ => null,
  };
}
