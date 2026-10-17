import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import '../skill.dart';

/// The skill proficiencies a class grants at level 1 ("Skill Proficiencies"
/// rows of the Core Traits tables, SRD 5.2.1, pp. 28, 31, 36, 41, 47, 49,
/// 53, 57, 61, 64, 70, 77) (FR-019).
///
/// The SRD prints two shapes: "Choose 2: ..." from a closed list of skills,
/// and "Choose any 3 skills" (the Bard) from every skill. The type is sealed
/// with exactly the two variants, exhaustive in a `switch` without a default.
@immutable
sealed class SkillChoice {
  SkillChoice(this.picks);

  /// The fewest skills a choice may ask the player to pick: one (FR-019).
  /// The constant the decoder reuses instead of repeating the literal
  /// (FR-007).
  static const int minPicks = 1;

  /// Whether [picks] is a number of picks a choice may ask for: at least
  /// [minPicks] (FR-019). The predicate the decoder reuses (FR-007).
  static bool isValidPicks(int picks) => picks >= minPicks;

  /// How many skills the player picks (FR-019); at least [minPicks].
  final int picks;

  static int _validatedPicks(int picks) {
    if (!isValidPicks(picks)) {
      throw ArgumentError.value(picks, 'picks', 'must be $minPicks or more');
    }
    return picks;
  }
}

/// A choice from a closed, printed list of skills: "Choose 2 from the
/// following list of skills: Animal Handling, Athletics, ...". (FR-019;
/// SRD 5.2.1, "Core Barbarian Traits", p. 28.)
@immutable
final class SkillChoiceListed extends SkillChoice {
  /// Creates the choice from a defensive copy of [skills].
  ///
  /// Throws an [ArgumentError] carrying the name `skills` and the offending
  /// value when [skills] is empty, holds a skill twice, or holds fewer than
  /// [picks] skills.
  SkillChoiceListed(int picks, List<Skill> skills)
    : skills = List.unmodifiable(_validated(picks, skills)),
      super(SkillChoice._validatedPicks(picks));

  /// The skills the player picks from, in printed order; unmodifiable,
  /// never empty, at least [picks] of them (FR-019).
  final List<Skill> skills;

  static List<Skill> _validated(int picks, List<Skill> skills) {
    if (skills.isEmpty) {
      throw ArgumentError.value(skills, 'skills', 'must not be empty');
    }
    for (var i = 1; i < skills.length; i++) {
      if (skills.indexOf(skills[i]) != i) {
        throw ArgumentError.value(skills[i], 'skills', 'must be distinct');
      }
    }
    if (skills.length < picks) {
      throw ArgumentError.value(
        skills,
        'skills',
        'must hold at least $picks skills',
      );
    }
    return skills;
  }

  @override
  bool operator ==(Object other) =>
      other is SkillChoiceListed &&
      other.picks == picks &&
      const ListEquality<Skill>().equals(other.skills, skills);

  @override
  int get hashCode => Object.hash(
    SkillChoiceListed,
    picks,
    const ListEquality<Skill>().hash(skills),
  );

  @override
  String toString() => 'SkillChoiceListed($picks from $skills)';
}

/// A choice of any skills: the Bard's "Choose any 3 skills" (FR-019;
/// SRD 5.2.1, "Core Bard Traits", p. 31).
@immutable
final class SkillChoiceAny extends SkillChoice {
  /// Creates the choice.
  ///
  /// Throws an [ArgumentError] carrying the name `picks` and the offending
  /// value when [picks] is below [SkillChoice.minPicks].
  SkillChoiceAny(int picks) : super(SkillChoice._validatedPicks(picks));

  @override
  bool operator ==(Object other) =>
      other is SkillChoiceAny && other.picks == picks;

  @override
  int get hashCode => Object.hash(SkillChoiceAny, picks);

  @override
  String toString() => 'SkillChoiceAny($picks)';
}
