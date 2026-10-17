import '../../shared_kernel/ability/ability.dart';

/// One of the 18 skills of the Skills table ("Skills", SRD 5.2.1, p. 9), in
/// table order, with the ability each one uses (FR-106).
///
/// The JSON spelling is the printed name. A skill carries this one static
/// fact and no behaviour; applying it is the using context's rule.
enum Skill {
  /// Acrobatics (Dexterity).
  acrobatics('Acrobatics', Ability.dexterity),

  /// Animal Handling (Wisdom).
  animalHandling('Animal Handling', Ability.wisdom),

  /// Arcana (Intelligence).
  arcana('Arcana', Ability.intelligence),

  /// Athletics (Strength).
  athletics('Athletics', Ability.strength),

  /// Deception (Charisma).
  deception('Deception', Ability.charisma),

  /// History (Intelligence).
  history('History', Ability.intelligence),

  /// Insight (Wisdom).
  insight('Insight', Ability.wisdom),

  /// Intimidation (Charisma).
  intimidation('Intimidation', Ability.charisma),

  /// Investigation (Intelligence).
  investigation('Investigation', Ability.intelligence),

  /// Medicine (Wisdom).
  medicine('Medicine', Ability.wisdom),

  /// Nature (Intelligence).
  nature('Nature', Ability.intelligence),

  /// Perception (Wisdom).
  perception('Perception', Ability.wisdom),

  /// Performance (Charisma).
  performance('Performance', Ability.charisma),

  /// Persuasion (Charisma).
  persuasion('Persuasion', Ability.charisma),

  /// Religion (Intelligence).
  religion('Religion', Ability.intelligence),

  /// Sleight of Hand (Dexterity).
  sleightOfHand('Sleight of Hand', Ability.dexterity),

  /// Stealth (Dexterity).
  stealth('Stealth', Ability.dexterity),

  /// Survival (Wisdom).
  survival('Survival', Ability.wisdom);

  const Skill(this.jsonValue, this.ability);

  /// The printed name used in JSON.
  final String jsonValue;

  /// The printed Ability the skill uses ("Skills", SRD 5.2.1, p. 9).
  final Ability ability;

  /// The member whose [jsonValue] is [value], or null for a non-member: the
  /// decoder turns a non-member into `invalidValue` (FR-105, FR-025).
  static Skill? fromJson(String value) => switch (value) {
    'Acrobatics' => acrobatics,
    'Animal Handling' => animalHandling,
    'Arcana' => arcana,
    'Athletics' => athletics,
    'Deception' => deception,
    'History' => history,
    'Insight' => insight,
    'Intimidation' => intimidation,
    'Investigation' => investigation,
    'Medicine' => medicine,
    'Nature' => nature,
    'Perception' => perception,
    'Performance' => performance,
    'Persuasion' => persuasion,
    'Religion' => religion,
    'Sleight of Hand' => sleightOfHand,
    'Stealth' => stealth,
    'Survival' => survival,
    _ => null,
  };
}
