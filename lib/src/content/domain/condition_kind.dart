/// One of the 15 conditions of the Glossary, in Glossary order ("Condition",
/// SRD 5.2.1, p. 179) (FR-110).
///
/// The declaration order is load-bearing: the conditions rules order by it.
/// The JSON spelling is the printed name. The kind carries no effect; what a
/// condition does is the conditions rules' concern.
enum ConditionKind {
  /// Blinded.
  blinded('Blinded'),

  /// Charmed.
  charmed('Charmed'),

  /// Deafened.
  deafened('Deafened'),

  /// Exhaustion.
  exhaustion('Exhaustion'),

  /// Frightened.
  frightened('Frightened'),

  /// Grappled.
  grappled('Grappled'),

  /// Incapacitated.
  incapacitated('Incapacitated'),

  /// Invisible.
  invisible('Invisible'),

  /// Paralyzed.
  paralyzed('Paralyzed'),

  /// Petrified.
  petrified('Petrified'),

  /// Poisoned.
  poisoned('Poisoned'),

  /// Prone.
  prone('Prone'),

  /// Restrained.
  restrained('Restrained'),

  /// Stunned.
  stunned('Stunned'),

  /// Unconscious.
  unconscious('Unconscious');

  const ConditionKind(this.jsonValue);

  /// The printed name used in JSON.
  final String jsonValue;

  /// The member whose [jsonValue] is [value], or null for a non-member: the
  /// decoder turns a non-member into `invalidValue` (FR-105, FR-025).
  static ConditionKind? fromJson(String value) => switch (value) {
    'Blinded' => blinded,
    'Charmed' => charmed,
    'Deafened' => deafened,
    'Exhaustion' => exhaustion,
    'Frightened' => frightened,
    'Grappled' => grappled,
    'Incapacitated' => incapacitated,
    'Invisible' => invisible,
    'Paralyzed' => paralyzed,
    'Petrified' => petrified,
    'Poisoned' => poisoned,
    'Prone' => prone,
    'Restrained' => restrained,
    'Stunned' => stunned,
    'Unconscious' => unconscious,
    _ => null,
  };
}
