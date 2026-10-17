import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import 'armor_training_category.dart';
import 'class_tool_proficiency.dart';
import 'skill_choice.dart';
import 'weapon_proficiency.dart';

/// What a first level in the class grants beyond the level 1 features —
/// the SRD's "Becoming a `<Class>` As a Multiclass Character" list (FR-026;
/// SRD 5.2.1, pp. 28, 31, 36, 41, 47, 49, 53, 57, 61, 64, 70, 77).
///
/// The Hit Point Die and the level 1 features are always granted and are
/// not stored here (FR-026). The list MUST NOT exceed the class's core
/// traits; that subset rule needs the class's own traits, so the
/// [ClassDefinition] constructor enforces it (FR-026, FR-073) — this type
/// validates only its own shape.
@immutable
final class MulticlassGrants {
  /// Creates the grants from defensive copies of the collection fields.
  ///
  /// Throws an [ArgumentError] carrying the name of the offending field and
  /// the offending value when [weaponProficiencies] holds more than one
  /// proficiency per category (FR-021) or [armorTraining] repeats a
  /// category (FR-022). The tool proficiencies and the skill choice
  /// validate themselves; every array may be empty.
  MulticlassGrants({
    List<WeaponProficiency> weaponProficiencies = const [],
    List<ArmorTrainingCategory> armorTraining = const [],
    List<ClassToolProficiency> toolProficiencies = const [],
    this.skillChoice,
  }) : weaponProficiencies = List.unmodifiable(weaponProficiencies),
       armorTraining = Set.unmodifiable(_validatedArmorTraining(armorTraining)),
       toolProficiencies = List.unmodifiable(toolProficiencies) {
    WeaponProficiency.requireUniqueCategories(this.weaponProficiencies);
  }

  /// The weapon proficiencies the first level grants; unmodifiable, possibly
  /// empty, at most one per category (FR-021, FR-026).
  final List<WeaponProficiency> weaponProficiencies;

  /// The armor training the first level grants; unmodifiable, possibly
  /// empty, all distinct (FR-022, FR-026).
  final Set<ArmorTrainingCategory> armorTraining;

  /// The tool proficiencies the first level grants; unmodifiable, possibly
  /// empty (FR-023, FR-026).
  final List<ClassToolProficiency> toolProficiencies;

  /// The skill proficiency choice the first level grants, or null when the
  /// class's multiclass list grants no skills (FR-019, FR-026).
  final SkillChoice? skillChoice;

  static List<ArmorTrainingCategory> _validatedArmorTraining(
    List<ArmorTrainingCategory> armorTraining,
  ) {
    for (var i = 1; i < armorTraining.length; i++) {
      if (armorTraining.indexOf(armorTraining[i]) != i) {
        throw ArgumentError.value(
          armorTraining[i],
          'armorTraining',
          'must be distinct',
        );
      }
    }
    return armorTraining;
  }

  @override
  bool operator ==(Object other) =>
      other is MulticlassGrants &&
      const ListEquality<WeaponProficiency>().equals(
        other.weaponProficiencies,
        weaponProficiencies,
      ) &&
      const SetEquality<ArmorTrainingCategory>().equals(
        other.armorTraining,
        armorTraining,
      ) &&
      const ListEquality<ClassToolProficiency>().equals(
        other.toolProficiencies,
        toolProficiencies,
      ) &&
      other.skillChoice == skillChoice;

  @override
  int get hashCode => Object.hash(
    MulticlassGrants,
    const ListEquality<WeaponProficiency>().hash(weaponProficiencies),
    const SetEquality<ArmorTrainingCategory>().hash(armorTraining),
    const ListEquality<ClassToolProficiency>().hash(toolProficiencies),
    skillChoice,
  );

  @override
  String toString() =>
      'MulticlassGrants(${weaponProficiencies.length} weapons, '
      '${armorTraining.length} armor, ${toolProficiencies.length} tools)';
}
