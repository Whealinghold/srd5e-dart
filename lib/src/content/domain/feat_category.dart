/// One of the 4 feat categories ("Parts of a Feat: Category", SRD 5.2.1,
/// p. 87), in SRD order (FR-117).
///
/// The JSON spelling is the printed name with its space.
enum FeatCategory {
  /// Origin ("Parts of a Feat: Category", SRD 5.2.1, p. 87).
  origin('Origin'),

  /// General.
  general('General'),

  /// Fighting Style.
  fightingStyle('Fighting Style'),

  /// Epic Boon.
  epicBoon('Epic Boon');

  const FeatCategory(this.jsonValue);

  /// The printed name used in JSON.
  final String jsonValue;

  /// The member whose [jsonValue] is [value], or null for a non-member: the
  /// decoder turns a non-member into `invalidValue` (FR-105, FR-025).
  static FeatCategory? fromJson(String value) => switch (value) {
    'Origin' => origin,
    'General' => general,
    'Fighting Style' => fightingStyle,
    'Epic Boon' => epicBoon,
    _ => null,
  };
}
