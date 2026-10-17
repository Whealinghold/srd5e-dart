import 'package:srd5e/src/content/domain/classes/armor_training_category.dart';
import 'package:srd5e/src/content/domain/classes/class_tool_proficiency.dart';
import 'package:srd5e/src/content/domain/classes/multiclass_grants.dart';
import 'package:srd5e/src/content/domain/classes/skill_choice.dart';
import 'package:srd5e/src/content/domain/classes/weapon_proficiency.dart';
import 'package:srd5e/src/content/domain/skill.dart';
import 'package:test/test.dart';

import '../../../support/argument_error_matcher.dart';

MulticlassGrants _grants() => MulticlassGrants(
  weaponProficiencies: [WeaponProficiency(WeaponTrainingCategory.martial)],
  armorTraining: [ArmorTrainingCategory.light],
  toolProficiencies: [
    ClassToolProficiencyChoice(['Musical Instrument'], 1),
  ],
  skillChoice: SkillChoiceListed(1, [Skill.survival]),
);

void main() {
  /// Requirement: doc/specs/content-classes.md FR-026, FR-008 - the grants
  ///   carry their arrays possibly empty and compare by value, with a
  ///   consistent hash code and the debug form.
  /// Path: happy
  test('value equality, hash code and debug form hold', () {
    expect(_grants(), equals(_grants()));
    expect(_grants().hashCode, _grants().hashCode);
    expect(_grants(), isNot(equals(MulticlassGrants())));
    expect(_grants().toString(), startsWith('MulticlassGrants('));
    expect(MulticlassGrants().skillChoice, isNull);
    expect(MulticlassGrants().weaponProficiencies, isEmpty);
    expect(MulticlassGrants().armorTraining, isEmpty);
    expect(MulticlassGrants().toolProficiencies, isEmpty);
  });

  /// Requirement: doc/specs/content-classes.md FR-026, FR-008 - the arrays
  ///   are defensively copied and unmodifiable.
  /// Path: unhappy (immutability)
  test('the arrays are defensively copied and unmodifiable', () {
    final weaponProficiencies = [
      WeaponProficiency(WeaponTrainingCategory.simple),
    ];
    final toolProficiencies = [
      ClassToolProficiencyChoice(['Musical Instrument'], 1),
    ];
    final grants = MulticlassGrants(
      weaponProficiencies: weaponProficiencies,
      toolProficiencies: toolProficiencies,
    );
    weaponProficiencies.clear();
    toolProficiencies.clear();
    expect(grants.weaponProficiencies.length, 1);
    expect(grants.toolProficiencies.length, 1);
    expect(() => grants.weaponProficiencies.clear(), throwsUnsupportedError);
    expect(() => grants.toolProficiencies.clear(), throwsUnsupportedError);
    expect(() => grants.armorTraining.clear(), throwsUnsupportedError);
  });

  /// Requirement: doc/specs/content-classes.md FR-021, FR-022, FR-026 - the
  ///   grants reject a repeated weapon-proficiency category and repeated
  ///   armor training, wherever the repeat sits in the array.
  /// Path: unhappy (boundary)
  test('a repeated weapon category or armor training is rejected', () {
    expect(
      () => MulticlassGrants(
        weaponProficiencies: [
          WeaponProficiency(WeaponTrainingCategory.martial),
          WeaponProficiency(WeaponTrainingCategory.martial),
        ],
      ),
      throwsA(
        isA<ArgumentError>().having(
          (e) => e.name,
          'name',
          'weaponProficiencies',
        ),
      ),
    );
    expect(
      () => MulticlassGrants(
        armorTraining: [
          ArmorTrainingCategory.light,
          ArmorTrainingCategory.medium,
          ArmorTrainingCategory.light,
        ],
      ),
      throwsArgumentErrorFor('armorTraining', ArmorTrainingCategory.light),
    );
  });
}
