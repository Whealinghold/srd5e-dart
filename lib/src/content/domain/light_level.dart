/// One of the 3 light levels ("Light", SRD 5.2.1, p. 11; "Bright Light",
/// p. 178; "Dim Light", p. 181; "Darkness", p. 180), in SRD order (FR-133).
///
/// The JSON spelling is the printed name. Identity only: what each level
/// does is the hiding-searching-and-senses and exploration rules' concern.
enum LightLevel {
  /// Bright Light.
  brightLight('Bright Light'),

  /// Dim Light.
  dimLight('Dim Light'),

  /// Darkness.
  darkness('Darkness');

  const LightLevel(this.jsonValue);

  /// The printed name used in JSON.
  final String jsonValue;

  /// The member whose [jsonValue] is [value], or null for a non-member: the
  /// decoder turns a non-member into `invalidValue` (FR-105, FR-025).
  static LightLevel? fromJson(String value) => switch (value) {
    'Bright Light' => brightLight,
    'Dim Light' => dimLight,
    'Darkness' => darkness,
    _ => null,
  };
}
