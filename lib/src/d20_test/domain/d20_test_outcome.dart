/// The outcome of a D20 Test of every kind ("D20 Tests", "Compare the Total
/// to a Target Number", SRD 5.2.1, p. 6).
///
/// There is no third value and no parallel outcome enum for attack rolls: a
/// Critical Hit is reported by the attack result's critical-hit field, not by
/// an outcome.
enum D20TestOutcome {
  /// The total equals or exceeds the target number.
  success,

  /// The total is below the target number (or the test fails without a roll).
  failure,
}
