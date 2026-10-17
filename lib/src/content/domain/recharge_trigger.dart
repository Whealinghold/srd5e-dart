/// The wording a limited-use feature recharges on ("Limited Usage", SRD
/// 5.2.1, p. 257) (FR-112).
///
/// A Long Rest is not a Short Rest: a feature that recharges on both lists
/// [RechargeTrigger.shortOrLongRest]. "X/Day" is data for [longRest], and
/// "Recharge X-Y" with its amount is not a trigger.
enum RechargeTrigger {
  /// "Short Rest" (SRD 5.2.1, "Limited Usage", p. 257).
  shortRest('Short Rest'),

  /// "Long Rest".
  longRest('Long Rest'),

  /// "Short or Long Rest".
  shortOrLongRest('Short or Long Rest');

  const RechargeTrigger(this.jsonValue);

  /// The printed wording used in JSON.
  final String jsonValue;

  /// The member whose [jsonValue] is [value], or null for a non-member: the
  /// decoder turns a non-member into `invalidValue` (FR-105, FR-025).
  static RechargeTrigger? fromJson(String value) => switch (value) {
    'Short Rest' => shortRest,
    'Long Rest' => longRest,
    'Short or Long Rest' => shortOrLongRest,
    _ => null,
  };
}
