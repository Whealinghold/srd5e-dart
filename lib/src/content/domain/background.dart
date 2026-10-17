import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import '../../shared_kernel/ability/ability.dart';
import 'background_feat_reference.dart';
import 'content_entry.dart';
import 'content_key.dart';
import 'content_reference.dart';
import 'equipment_options.dart';
import 'feat_category.dart';
import 'named_text.dart';
import 'skill.dart';
import 'source_citation.dart';
import 'tool_proficiency.dart';
import 'typed_ids.dart';

/// A character background ("Character Backgrounds", SRD 5.2.1, p. 83) as one
/// content entry of kind [ContentKind.background] (FR-024 to FR-030).
///
/// A background lists the three abilities its increases apply to, the Origin
/// feat it grants, two skill proficiencies, its tool proficiency and its two
/// equipment options. It carries no member for the ability increases
/// themselves: they are character behaviour, not data (FR-032). Its feat
/// reference is the site of FR-025, listed by [references] with the
/// `TargetHasFeatCategory(Origin)` constraint and resolved by the whole-set
/// validation.
@immutable
final class Background implements ContentEntry, ContentReferences {
  /// Creates a background from defensive copies of the collection fields.
  ///
  /// Throws an [ArgumentError] carrying the name of the offending field and
  /// value when [name] breaks the name rule (FR-027), [abilityScores] does
  /// not hold exactly [requiredAbilityScores] distinct abilities (FR-024), or
  /// [skillProficiencies] does not hold exactly
  /// [requiredSkillProficiencies] distinct skills (FR-027). The Origin rule
  /// of the feat reference is deliberately not a constructor rule (FR-025,
  /// FR-072): a constructor cannot see the referenced feat's category.
  Background({
    required this.id,
    required String name,
    this.source,
    required List<Ability> abilityScores,
    required this.feat,
    required List<Skill> skillProficiencies,
    required this.toolProficiency,
    required this.equipmentOptions,
  }) : name = _validatedName(name),
       abilityScores = List.unmodifiable(
         _validatedAbilityScores(abilityScores),
       ),
       skillProficiencies = List.unmodifiable(
         _validatedSkillProficiencies(skillProficiencies),
       );

  /// How many abilities a background's increases apply to: exactly three
  /// (FR-024). The constant the decoder reuses instead of repeating the
  /// literal (FR-069).
  static const int requiredAbilityScores = 3;

  /// How many skills a background grants: exactly two (FR-027).
  static const int requiredSkillProficiencies = 2;

  /// The background's id, as a typed id.
  final BackgroundId id;

  /// The background's printed name ("Acolyte"), verbatim.
  final String name;

  /// Where the entry comes from, or null when the supplying document omits
  /// it (schema FR-034).
  final SourceCitation? source;

  /// The three abilities the background's increases apply to, in printed
  /// order; unmodifiable (FR-024). The increases themselves are not data
  /// (FR-032).
  final List<Ability> abilityScores;

  /// The Origin feat the background grants (FR-025, FR-026).
  final BackgroundFeatReference feat;

  /// The two skill proficiencies, in printed order; unmodifiable (FR-027).
  final List<Skill> skillProficiencies;

  /// The tool proficiency, a specific tool or a category choice (FR-028).
  final ToolProficiency toolProficiency;

  /// The two equipment options, A and B (FR-029, FR-030).
  final EquipmentOptions equipmentOptions;

  @override
  ContentKey get key => id.key;

  /// The background's reference site (FR-025): exactly one, the feat
  /// reference, constrained to the `Origin` category.
  @override
  Iterable<ContentReference> get references sync* {
    yield ContentReference(
      'feat/featId',
      feat.featId.key,
      const TargetHasFeatCategory(FeatCategory.origin),
    );
  }

  static String _validatedName(String name) {
    if (!NamedText.isValidName(name)) {
      throw ArgumentError.value(
        name,
        'name',
        'must be non-empty with no leading or trailing whitespace',
      );
    }
    return name;
  }

  static List<Ability> _validatedAbilityScores(List<Ability> abilityScores) {
    if (abilityScores.length != requiredAbilityScores) {
      throw ArgumentError.value(
        abilityScores,
        'abilityScores',
        'must hold exactly $requiredAbilityScores abilities',
      );
    }
    for (var i = 1; i < abilityScores.length; i++) {
      if (abilityScores.indexOf(abilityScores[i]) != i) {
        throw ArgumentError.value(
          abilityScores[i],
          'abilityScores',
          'must be distinct',
        );
      }
    }
    return abilityScores;
  }

  static List<Skill> _validatedSkillProficiencies(List<Skill> skills) {
    if (skills.length != requiredSkillProficiencies) {
      throw ArgumentError.value(
        skills,
        'skillProficiencies',
        'must hold exactly $requiredSkillProficiencies skills',
      );
    }
    for (var i = 1; i < skills.length; i++) {
      if (skills.indexOf(skills[i]) != i) {
        throw ArgumentError.value(
          skills[i],
          'skillProficiencies',
          'must be distinct',
        );
      }
    }
    return skills;
  }

  @override
  bool operator ==(Object other) =>
      other is Background &&
      other.id == id &&
      other.name == name &&
      other.source == source &&
      const ListEquality<Ability>().equals(
        other.abilityScores,
        abilityScores,
      ) &&
      other.feat == feat &&
      const ListEquality<Skill>().equals(
        other.skillProficiencies,
        skillProficiencies,
      ) &&
      other.toolProficiency == toolProficiency &&
      other.equipmentOptions == equipmentOptions;

  @override
  int get hashCode => Object.hash(
    Background,
    id,
    name,
    source,
    const ListEquality<Ability>().hash(abilityScores),
    feat,
    const ListEquality<Skill>().hash(skillProficiencies),
    toolProficiency,
    equipmentOptions,
  );

  @override
  String toString() => 'Background(${id.id.value})';
}
