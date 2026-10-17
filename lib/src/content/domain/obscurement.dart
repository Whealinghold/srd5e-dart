/// How obscured an area is, ordered by severity ("Obscured Areas", SRD
/// 5.2.1, p. 11; "Heavily Obscured", p. 182; "Lightly Obscured", p. 184)
/// (FR-135).
///
/// The declaration order is load-bearing: consumers compare by [index], and
/// [none] is the least severe. `none` is a package name for "not obscured"
/// (not an SRD term). Which light, fog or foliage produces which value is
/// the host's or the hiding-searching-and-senses rules' concern. The JSON
/// spelling is the printed name.
enum Obscurement {
  /// Not obscured (package name for "not obscured").
  none('None'),

  /// Lightly Obscured.
  lightly('Lightly Obscured'),

  /// Heavily Obscured.
  heavily('Heavily Obscured');

  const Obscurement(this.jsonValue);

  /// The printed name used in JSON.
  final String jsonValue;

  /// The member whose [jsonValue] is [value], or null for a non-member: the
  /// decoder turns a non-member into `invalidValue` (FR-105, FR-025).
  static Obscurement? fromJson(String value) => switch (value) {
    'None' => none,
    'Lightly Obscured' => lightly,
    'Heavily Obscured' => heavily,
    _ => null,
  };
}
