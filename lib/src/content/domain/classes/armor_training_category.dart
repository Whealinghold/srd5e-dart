/// One of the four armor training categories of the Core Traits tables
/// ("Armor Training" rows, SRD 5.2.1, pp. 28, 31, 36, 41, 47, 49, 53, 57,
/// 61, 64, 70, 77), in the SRD's light-to-shield order (FR-022).
///
/// The JSON spelling is the SRD's own word. A class with no armor training
/// carries an empty set, the printed "None" — never an absent field (FR-022,
/// FR-002). The type deliberately mirrors content-equipment.md's
/// `ArmorCategory` under shared-types-and-ownership.md FR-047 (D10); the
/// consumer maps them by name.
enum ArmorTrainingCategory {
  /// Light armor.
  light('Light'),

  /// Medium armor.
  medium('Medium'),

  /// Heavy armor.
  heavy('Heavy'),

  /// Shields.
  shield('Shield');

  const ArmorTrainingCategory(this.jsonValue);

  /// The printed word used in JSON.
  final String jsonValue;

  /// The member whose [jsonValue] is [value], or null for a non-member: the
  /// decoder turns a non-member into `invalidValue` (FR-105, FR-025).
  static ArmorTrainingCategory? fromJson(String value) => switch (value) {
    'Light' => light,
    'Medium' => medium,
    'Heavy' => heavy,
    'Shield' => shield,
    _ => null,
  };
}
