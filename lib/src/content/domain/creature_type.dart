/// One of the 14 creature types of the Glossary ("Creature Type", SRD 5.2.1,
/// p. 179), in Glossary order (FR-108).
///
/// The JSON spelling is the printed name. The type is identity only; what a
/// type does is the using context's rule.
enum CreatureType {
  /// Aberration.
  aberration('Aberration'),

  /// Beast.
  beast('Beast'),

  /// Celestial.
  celestial('Celestial'),

  /// Construct.
  construct('Construct'),

  /// Dragon.
  dragon('Dragon'),

  /// Elemental.
  elemental('Elemental'),

  /// Fey.
  fey('Fey'),

  /// Fiend.
  fiend('Fiend'),

  /// Giant.
  giant('Giant'),

  /// Humanoid.
  humanoid('Humanoid'),

  /// Monstrosity.
  monstrosity('Monstrosity'),

  /// Ooze.
  ooze('Ooze'),

  /// Plant.
  plant('Plant'),

  /// Undead.
  undead('Undead');

  const CreatureType(this.jsonValue);

  /// The printed name used in JSON.
  final String jsonValue;

  /// The member whose [jsonValue] is [value], or null for a non-member: the
  /// decoder turns a non-member into `invalidValue` (FR-105, FR-025).
  static CreatureType? fromJson(String value) => switch (value) {
    'Aberration' => aberration,
    'Beast' => beast,
    'Celestial' => celestial,
    'Construct' => construct,
    'Dragon' => dragon,
    'Elemental' => elemental,
    'Fey' => fey,
    'Fiend' => fiend,
    'Giant' => giant,
    'Humanoid' => humanoid,
    'Monstrosity' => monstrosity,
    'Ooze' => ooze,
    'Plant' => plant,
    'Undead' => undead,
    _ => null,
  };
}
