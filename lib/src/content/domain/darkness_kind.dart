/// The two kinds of Darkness ("Light", "Special Senses", SRD 5.2.1, p. 11;
/// "Truesight", p. 190; "Devil's Sight", p. 72) (FR-134).
///
/// It qualifies Darkness only; pairing a kind with a darkness is the
/// consumer's rule. The JSON spelling is the printed wording; `nonmagical`
/// is a package name for the SRD's "normal" darkness.
enum DarknessKind {
  /// Nonmagical ("normal") Darkness.
  nonmagical('Nonmagical'),

  /// Magical Darkness.
  magical('Magical');

  const DarknessKind(this.jsonValue);

  /// The printed name used in JSON.
  final String jsonValue;

  /// The member whose [jsonValue] is [value], or null for a non-member: the
  /// decoder turns a non-member into `invalidValue` (FR-105, FR-025).
  static DarknessKind? fromJson(String value) => switch (value) {
    'Nonmagical' => nonmagical,
    'Magical' => magical,
    _ => null,
  };
}
