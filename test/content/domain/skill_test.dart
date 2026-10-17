import 'package:srd5e/src/content/domain/skill.dart';
import 'package:srd5e/src/shared_kernel/ability/ability.dart';
import 'package:test/test.dart';

/// One skill with the printed Ability its row of the Skills table gives it.
typedef _AbilityCase = ({
  String label,
  String requirement,
  String path,
  Skill skill,
  Ability ability,
});

/// The 18 skills with their abilities, in Skills-table order ("Skills",
/// SRD 5.2.1, p. 9).
final List<_AbilityCase> _abilities = [
  (
    label: 'Acrobatics',
    requirement:
        'doc/specs/content-schema-and-decoder.md FR-106 - Dexterity '
        'for Acrobatics (SRD 5.2.1, "Skills", p. 9)',
    path: 'happy',
    skill: Skill.acrobatics,
    ability: Ability.dexterity,
  ),
  (
    label: 'Animal Handling',
    requirement:
        'doc/specs/content-schema-and-decoder.md FR-106 - Wisdom for '
        'Animal Handling (SRD 5.2.1, "Skills", p. 9)',
    path: 'happy',
    skill: Skill.animalHandling,
    ability: Ability.wisdom,
  ),
  (
    label: 'Arcana',
    requirement:
        'doc/specs/content-schema-and-decoder.md FR-106 - '
        'Intelligence for Arcana (SRD 5.2.1, "Skills", p. 9)',
    path: 'happy',
    skill: Skill.arcana,
    ability: Ability.intelligence,
  ),
  (
    label: 'Athletics',
    requirement:
        'doc/specs/content-schema-and-decoder.md FR-106 - Strength '
        'for Athletics (SRD 5.2.1, "Skills", p. 9)',
    path: 'happy',
    skill: Skill.athletics,
    ability: Ability.strength,
  ),
  (
    label: 'Deception',
    requirement:
        'doc/specs/content-schema-and-decoder.md FR-106 - Charisma '
        'for Deception (SRD 5.2.1, "Skills", p. 9)',
    path: 'happy',
    skill: Skill.deception,
    ability: Ability.charisma,
  ),
  (
    label: 'History',
    requirement:
        'doc/specs/content-schema-and-decoder.md FR-106 - '
        'Intelligence for History (SRD 5.2.1, "Skills", p. 9)',
    path: 'happy',
    skill: Skill.history,
    ability: Ability.intelligence,
  ),
  (
    label: 'Insight',
    requirement:
        'doc/specs/content-schema-and-decoder.md FR-106 - Wisdom for '
        'Insight (SRD 5.2.1, "Skills", p. 9)',
    path: 'happy',
    skill: Skill.insight,
    ability: Ability.wisdom,
  ),
  (
    label: 'Intimidation',
    requirement:
        'doc/specs/content-schema-and-decoder.md FR-106 - Charisma '
        'for Intimidation (SRD 5.2.1, "Skills", p. 9)',
    path: 'happy',
    skill: Skill.intimidation,
    ability: Ability.charisma,
  ),
  (
    label: 'Investigation',
    requirement:
        'doc/specs/content-schema-and-decoder.md FR-106 - '
        'Intelligence for Investigation (SRD 5.2.1, "Skills", p. 9)',
    path: 'happy',
    skill: Skill.investigation,
    ability: Ability.intelligence,
  ),
  (
    label: 'Medicine',
    requirement:
        'doc/specs/content-schema-and-decoder.md FR-106 - Wisdom for '
        'Medicine (SRD 5.2.1, "Skills", p. 9)',
    path: 'happy',
    skill: Skill.medicine,
    ability: Ability.wisdom,
  ),
  (
    label: 'Nature',
    requirement:
        'doc/specs/content-schema-and-decoder.md FR-106 - '
        'Intelligence for Nature (SRD 5.2.1, "Skills", p. 9)',
    path: 'happy',
    skill: Skill.nature,
    ability: Ability.intelligence,
  ),
  (
    label: 'Perception',
    requirement:
        'doc/specs/content-schema-and-decoder.md FR-106 - Wisdom for '
        'Perception (SRD 5.2.1, "Skills", p. 9)',
    path: 'happy',
    skill: Skill.perception,
    ability: Ability.wisdom,
  ),
  (
    label: 'Performance',
    requirement:
        'doc/specs/content-schema-and-decoder.md FR-106 - Charisma '
        'for Performance (SRD 5.2.1, "Skills", p. 9)',
    path: 'happy',
    skill: Skill.performance,
    ability: Ability.charisma,
  ),
  (
    label: 'Persuasion',
    requirement:
        'doc/specs/content-schema-and-decoder.md FR-106 - Charisma '
        'for Persuasion (SRD 5.2.1, "Skills", p. 9)',
    path: 'happy',
    skill: Skill.persuasion,
    ability: Ability.charisma,
  ),
  (
    label: 'Religion',
    requirement:
        'doc/specs/content-schema-and-decoder.md FR-106 - '
        'Intelligence for Religion (SRD 5.2.1, "Skills", p. 9)',
    path: 'happy',
    skill: Skill.religion,
    ability: Ability.intelligence,
  ),
  (
    label: 'Sleight of Hand',
    requirement:
        'doc/specs/content-schema-and-decoder.md FR-106 - Dexterity '
        'for Sleight of Hand (SRD 5.2.1, "Skills", p. 9)',
    path: 'happy',
    skill: Skill.sleightOfHand,
    ability: Ability.dexterity,
  ),
  (
    label: 'Stealth',
    requirement:
        'doc/specs/content-schema-and-decoder.md FR-106 - Dexterity '
        'for Stealth (SRD 5.2.1, "Skills", p. 9)',
    path: 'happy',
    skill: Skill.stealth,
    ability: Ability.dexterity,
  ),
  (
    label: 'Survival',
    requirement:
        'doc/specs/content-schema-and-decoder.md FR-106 - Wisdom for '
        'Survival (SRD 5.2.1, "Skills", p. 9)',
    path: 'happy',
    skill: Skill.survival,
    ability: Ability.wisdom,
  ),
];

/// One fromJson input with the expected member, or null for a non-member.
typedef _JsonCase = ({
  String label,
  String requirement,
  String path,
  String input,
  Skill? expected,
});

final List<_JsonCase> _jsonCases = [
  (
    label: 'printed spelling',
    requirement:
        'doc/specs/content-schema-and-decoder.md FR-105 - fromJson '
        'accepts exactly the jsonValue spellings',
    path: 'happy',
    input: 'Sleight of Hand',
    expected: Skill.sleightOfHand,
  ),
  (
    label: 'wrong case',
    requirement:
        'doc/specs/content-schema-and-decoder.md FR-105 - fromJson '
        'gives null for a non-member; the decoder turns it into '
        'invalidValue (FR-025)',
    path: 'unhappy (invalid input)',
    input: 'sleight of hand',
    expected: null,
  ),
  (
    label: 'padded spelling',
    requirement:
        'doc/specs/content-schema-and-decoder.md FR-105 - fromJson '
        'gives null for a non-member; the decoder never trims (FR-025)',
    path: 'unhappy (invalid input)',
    input: ' Acrobatics',
    expected: null,
  ),
];

/// Exhaustive over the enum with no default branch (FR-106).
String _describe(Skill skill) => switch (skill) {
  Skill.acrobatics => 'acrobatics',
  Skill.animalHandling => 'animalHandling',
  Skill.arcana => 'arcana',
  Skill.athletics => 'athletics',
  Skill.deception => 'deception',
  Skill.history => 'history',
  Skill.insight => 'insight',
  Skill.intimidation => 'intimidation',
  Skill.investigation => 'investigation',
  Skill.medicine => 'medicine',
  Skill.nature => 'nature',
  Skill.perception => 'perception',
  Skill.performance => 'performance',
  Skill.persuasion => 'persuasion',
  Skill.religion => 'religion',
  Skill.sleightOfHand => 'sleightOfHand',
  Skill.stealth => 'stealth',
  Skill.survival => 'survival',
};

void main() {
  /// Requirement: doc/specs/content-schema-and-decoder.md FR-106 - exactly
  ///   these 18 members in Skills-table order, JSON the printed name (SRD
  ///   5.2.1, "Skills", p. 9).
  /// Path: happy
  test('declares exactly 18 members in Skills-table order', () {
    expect(Skill.values.map((skill) => skill.jsonValue), [
      'Acrobatics',
      'Animal Handling',
      'Arcana',
      'Athletics',
      'Deception',
      'History',
      'Insight',
      'Intimidation',
      'Investigation',
      'Medicine',
      'Nature',
      'Perception',
      'Performance',
      'Persuasion',
      'Religion',
      'Sleight of Hand',
      'Stealth',
      'Survival',
    ]);
  });

  /// Requirement: per case
  /// Path: per case
  for (final c in _abilities) {
    test('${c.label} uses ${c.ability.name} [per case]', () {
      expect(c.skill.ability, c.ability);
    });
  }

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-105 - the
  ///   static fromJson accepts exactly the jsonValue spellings.
  /// Path: happy
  test('fromJson round-trips every member', () {
    for (final skill in Skill.values) {
      expect(Skill.fromJson(skill.jsonValue), skill);
    }
  });

  /// Requirement: per case
  /// Path: per case
  for (final c in _jsonCases) {
    test('fromJson ${c.label} [${c.path}]', () {
      expect(Skill.fromJson(c.input), c.expected);
    });
  }

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-106 - a switch
  ///   over Skill is exhaustive without a default.
  /// Path: happy
  test('a switch over every member selects its case', () {
    expect(
      [for (final skill in Skill.values) _describe(skill)],
      [
        'acrobatics',
        'animalHandling',
        'arcana',
        'athletics',
        'deception',
        'history',
        'insight',
        'intimidation',
        'investigation',
        'medicine',
        'nature',
        'perception',
        'performance',
        'persuasion',
        'religion',
        'sleightOfHand',
        'stealth',
        'survival',
      ],
    );
  });
}
