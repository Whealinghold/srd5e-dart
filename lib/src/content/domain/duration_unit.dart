/// One of the 4 units a Duration (Time Span) is counted in ("Duration" (Time
/// Span), SRD 5.2.1, p. 106), in ascending order (FR-149).
///
/// The JSON value is the package tag in lower camel case (not an SRD
/// spelling). No spell Duration prints a unit other than these four — a
/// one-year period is a toolbox constant, not a unit — so weeks, months and
/// years are not members. The type carries no fact and no conversion to a
/// Dart `Duration`.
enum DurationUnit {
  /// Rounds ("Guiding Bolt", p. 138; "Tsunami", p. 171).
  rounds('rounds'),

  /// Minutes ("Bless", p. 113).
  minutes('minutes'),

  /// Hours ("Mage Armor", p. 145).
  hours('hours'),

  /// Days ("Contagion", p. 119; "Mirage Arcane", p. 149; "Geas", p. 135).
  days('days');

  const DurationUnit(this.jsonValue);

  /// The package tag used in JSON.
  final String jsonValue;

  /// The member whose [jsonValue] is [value], or null for a non-member: the
  /// decoder turns a non-member into `invalidValue` (FR-105, FR-149).
  static DurationUnit? fromJson(String value) => switch (value) {
    'rounds' => rounds,
    'minutes' => minutes,
    'hours' => hours,
    'days' => days,
    _ => null,
  };
}
