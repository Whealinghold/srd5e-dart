/// One of the 13 damage types of the Damage Types table ("Damage Types",
/// SRD 5.2.1, p. 180), in table order (FR-107).
///
/// The JSON spelling is the printed name. The type is identity only; damage
/// handling is the hit-points-and-damage rules' concern.
enum DamageType {
  /// Acid.
  acid('Acid'),

  /// Bludgeoning.
  bludgeoning('Bludgeoning'),

  /// Cold.
  cold('Cold'),

  /// Fire.
  fire('Fire'),

  /// Force.
  force('Force'),

  /// Lightning.
  lightning('Lightning'),

  /// Necrotic.
  necrotic('Necrotic'),

  /// Piercing.
  piercing('Piercing'),

  /// Poison.
  poison('Poison'),

  /// Psychic.
  psychic('Psychic'),

  /// Radiant.
  radiant('Radiant'),

  /// Slashing.
  slashing('Slashing'),

  /// Thunder.
  thunder('Thunder');

  const DamageType(this.jsonValue);

  /// The printed name used in JSON.
  final String jsonValue;

  /// The member whose [jsonValue] is [value], or null for a non-member: the
  /// decoder turns a non-member into `invalidValue` (FR-105, FR-025).
  static DamageType? fromJson(String value) => switch (value) {
    'Acid' => acid,
    'Bludgeoning' => bludgeoning,
    'Cold' => cold,
    'Fire' => fire,
    'Force' => force,
    'Lightning' => lightning,
    'Necrotic' => necrotic,
    'Piercing' => piercing,
    'Poison' => poison,
    'Psychic' => psychic,
    'Radiant' => radiant,
    'Slashing' => slashing,
    'Thunder' => thunder,
    _ => null,
  };
}
