/// The kind of a D20 Test: "ability checks, attack rolls, and saving throws"
/// ("D20 Test", SRD 5.2.1, p. 180).
enum D20TestKind {
  /// An ability check ("Ability Checks", SRD 5.2.1, p. 6): a total compared
  /// with a Difficulty Class.
  abilityCheck,

  /// A saving throw ("Saving Throws", SRD 5.2.1, p. 7): a total compared with
  /// a Difficulty Class.
  savingThrow,

  /// An attack roll ("Attack Rolls", SRD 5.2.1, p. 7): a total compared with
  /// an Armor Class, with the natural 20 and natural 1 rules of p. 7.
  attackRoll,
}
