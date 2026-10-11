/// Why a check or a saving throw fails without a roll.
///
/// There is no reason for an attack roll: the SRD gives no rule for failing
/// one without rolling.
enum ForcedFailureReason {
  /// The creature chooses to fail a saving throw ("you can choose to fail the
  /// save without rolling", "Saving Throws", SRD 5.2.1, p. 7).
  chosenToFail,

  /// The caller declares an automatic failure from the situation: a check
  /// that requires sight while Blinded ("Blinded", SRD 5.2.1, p. 177) or
  /// hearing while Deafened ("Deafened", p. 181), or, for saving throws
  /// only, an object with no ability scores ("Object", p. 178).
  automatic,
}
