/// One of the 8 mastery properties ("Mastery Properties", SRD 5.2.1, p. 90),
/// in section order (FR-113).
///
/// The JSON spelling is the printed name. The type is identity only; the
/// mastery properties' behaviour is the weapon-properties-and-mastery
/// rules' concern.
enum MasteryProperty {
  /// Cleave.
  cleave('Cleave'),

  /// Graze.
  graze('Graze'),

  /// Nick.
  nick('Nick'),

  /// Push.
  push('Push'),

  /// Sap.
  sap('Sap'),

  /// Slow.
  slow('Slow'),

  /// Topple.
  topple('Topple'),

  /// Vex.
  vex('Vex');

  const MasteryProperty(this.jsonValue);

  /// The printed name used in JSON.
  final String jsonValue;

  /// The member whose [jsonValue] is [value], or null for a non-member: the
  /// decoder turns a non-member into `invalidValue` (FR-105, FR-025).
  static MasteryProperty? fromJson(String value) => switch (value) {
    'Cleave' => cleave,
    'Graze' => graze,
    'Nick' => nick,
    'Push' => push,
    'Sap' => sap,
    'Slow' => slow,
    'Topple' => topple,
    'Vex' => vex,
    _ => null,
  };
}
