import 'package:srd5e/src/content/domain/classes/multiclass_grants.dart';
import 'package:srd5e/src/content/domain/classes/weapon_proficiency.dart';
import 'package:srd5e/src/content/domain/weapon_property.dart';
import 'package:test/test.dart';

import '../../../support/argument_error_matcher.dart';
import 'class_fixture.dart';

final _martialAnyLight = WeaponProficiency(
  WeaponTrainingCategory.martial,
  requiresAnyProperty: [WeaponProperty.light],
);
final _martialAnyTwo = WeaponProficiency(
  WeaponTrainingCategory.martial,
  requiresAnyProperty: [WeaponProperty.finesse, WeaponProperty.finesse],
);
final _martialEmptyFilter = WeaponProficiency(
  WeaponTrainingCategory.martial,
  requiresAnyProperty: const [],
);

void main() {
  /// Requirement: doc/specs/content-classes.md FR-021 - a weapon
  ///   proficiency is a `WeaponTrainingCategory` with an optional non-empty,
  ///   distinct `requiresAnyProperty` filter (SRD 5.2.1, "Core Monk Traits",
  ///   p. 49, "Core Rogue Traits", p. 61).
  /// Path: happy
  group('WeaponProficiency constructor rows', () {
    /// Requirement: per case
    /// Path: per case
    for (final c in [
      (
        label: 'whole category',
        requirement:
            'doc/specs/content-classes.md FR-021 - absent filter means '
            'every weapon of the category',
        path: 'happy',
        build: () => WeaponProficiency(WeaponTrainingCategory.martial),
        throwsFor: null,
      ),
      (
        label: 'property filter',
        requirement:
            'doc/specs/content-classes.md FR-021 - the Monk\'s "Martial '
            'weapons that have the Light property" is a martial proficiency '
            'filtered on Light',
        path: 'happy',
        build: () => _martialAnyLight,
        throwsFor: null,
      ),
      (
        label: 'empty filter',
        requirement:
            'doc/specs/content-classes.md FR-021 - a present '
            'requiresAnyProperty is non-empty',
        path: 'unhappy (boundary)',
        build: () => _martialEmptyFilter,
        throwsFor: throwsArgumentErrorFor('requiresAnyProperty', const []),
      ),
      (
        label: 'duplicate filter',
        requirement:
            'doc/specs/content-classes.md FR-021 - the filter holds '
            'distinct properties',
        path: 'unhappy (boundary)',
        build: () => _martialAnyTwo,
        throwsFor: throwsArgumentErrorFor(
          'requiresAnyProperty',
          WeaponProperty.finesse,
        ),
      ),
    ]) {
      test('${c.label} [${c.path}]', () {
        if (c.throwsFor != null) {
          expect(c.build, c.throwsFor);
        } else {
          expect(c.build(), isA<WeaponProficiency>());
        }
      });
    }
  });

  /// Requirement: doc/specs/content-classes.md FR-021 - at most one element
  ///   per category in a list of weapon proficiencies.
  /// Path: unhappy (boundary)
  test('a repeated category is rejected through the shared rule', () {
    final proficiencies = [
      WeaponProficiency(WeaponTrainingCategory.simple),
      WeaponProficiency(WeaponTrainingCategory.martial),
      WeaponProficiency(WeaponTrainingCategory.simple),
    ];
    expect(WeaponProficiency.hasUniqueCategories(proficiencies), isFalse);
    expect(
      () => WeaponProficiency.requireUniqueCategories(proficiencies),
      throwsArgumentErrorFor('weaponProficiencies', proficiencies),
    );
    expect(
      WeaponProficiency.hasUniqueCategories([
        WeaponProficiency(WeaponTrainingCategory.simple),
        WeaponProficiency(WeaponTrainingCategory.martial),
      ]),
      isTrue,
    );
  });

  /// Requirement: doc/specs/content-classes.md FR-026, FR-021 - a
  ///   multiclass weapon grant is within the core when a core proficiency
  ///   of the same category covers every weapon the grant covers, filter
  ///   included.
  /// Path: happy
  group('covers rows (the FR-026 weapon subset predicate)', () {
    /// Requirement: per case
    /// Path: per case
    for (final c in [
      (
        label: 'equal filters',
        requirement:
            'doc/specs/content-classes.md FR-026 - a grant with the core\'s '
            'own filter is covered',
        path: 'happy',
        core: () => _martialAnyLight,
        grant: () => WeaponProficiency(
          WeaponTrainingCategory.martial,
          requiresAnyProperty: [WeaponProperty.light],
        ),
        expected: true,
      ),
      (
        label: 'grant filter within the core filter',
        requirement:
            'doc/specs/content-classes.md FR-026 - a grant needing Finesse '
            'or Light is covered by a core needing Finesse, Light and '
            'Reach',
        path: 'happy',
        core: () => WeaponProficiency(
          WeaponTrainingCategory.martial,
          requiresAnyProperty: [
            WeaponProperty.finesse,
            WeaponProperty.light,
            WeaponProperty.reach,
          ],
        ),
        grant: () => WeaponProficiency(
          WeaponTrainingCategory.martial,
          requiresAnyProperty: [WeaponProperty.finesse, WeaponProperty.light],
        ),
        expected: true,
      ),
      (
        label: 'filtered grant under a whole category',
        requirement:
            'doc/specs/content-classes.md FR-026 - a filtered grant is '
            'covered by an unfiltered core of the same category',
        path: 'happy',
        core: () => WeaponProficiency(WeaponTrainingCategory.simple),
        grant: () => WeaponProficiency(
          WeaponTrainingCategory.simple,
          requiresAnyProperty: [WeaponProperty.finesse],
        ),
        expected: true,
      ),
      (
        label: 'whole-category grant under a filtered core',
        requirement:
            'doc/specs/content-classes.md FR-026 - a grant of every martial '
            'weapon exceeds a core holding only the Light ones',
        path: 'unhappy (boundary)',
        core: () => _martialAnyLight,
        grant: () => WeaponProficiency(WeaponTrainingCategory.martial),
        expected: false,
      ),
      (
        label: 'grant filter beyond the core filter',
        requirement:
            'doc/specs/content-classes.md FR-026 - a grant needing Finesse '
            'exceeds a core holding only the Light ones',
        path: 'unhappy (boundary)',
        core: () => _martialAnyLight,
        grant: () => WeaponProficiency(
          WeaponTrainingCategory.martial,
          requiresAnyProperty: [WeaponProperty.finesse],
        ),
        expected: false,
      ),
      (
        label: 'grant filter partly beyond the core filter',
        requirement:
            'doc/specs/content-classes.md FR-026 - a grant needing Finesse '
            'or Light exceeds a core holding only the Light ones: every '
            'grant property must be covered, not merely one of them',
        path: 'unhappy (boundary)',
        core: () => _martialAnyLight,
        grant: () => WeaponProficiency(
          WeaponTrainingCategory.martial,
          requiresAnyProperty: [WeaponProperty.finesse, WeaponProperty.light],
        ),
        expected: false,
      ),
      (
        label: 'another category',
        requirement:
            'doc/specs/content-classes.md FR-026 - a grant of another '
            'category is never covered',
        path: 'unhappy (boundary)',
        core: () => _martialAnyLight,
        grant: () => WeaponProficiency(WeaponTrainingCategory.simple),
        expected: false,
      ),
    ]) {
      test('${c.label} [${c.path}]', () {
        expect(WeaponProficiency.covers(c.core(), c.grant()), c.expected);
      });
    }

    /// Requirement: doc/specs/content-classes.md FR-026 - a whole-category
    ///   grant on a filtered core is rejected by the ClassDefinition
    ///   constructor.
    /// Path: unhappy (rule interaction)
    test('the class constructor rejects a grant beyond a filtered core', () {
      expect(
        () => buildTestClass(
          weaponProficiencies: [_martialAnyLight],
          multiclassGrants: MulticlassGrants(
            weaponProficiencies: [
              WeaponProficiency(WeaponTrainingCategory.martial),
            ],
          ),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  /// Requirement: doc/specs/content-classes.md FR-021 - the category
  ///   spelling is the SRD's own word, and the filter is unmodifiable.
  /// Path: happy
  test('category JSON spellings and list immutability hold', () {
    expect(WeaponTrainingCategory.simple.jsonValue, 'Simple');
    expect(WeaponTrainingCategory.martial.jsonValue, 'Martial');
    expect(
      WeaponTrainingCategory.fromJson('Simple'),
      WeaponTrainingCategory.simple,
    );
    expect(
      WeaponTrainingCategory.fromJson('Martial'),
      WeaponTrainingCategory.martial,
    );
    expect(WeaponTrainingCategory.fromJson('simple'), isNull);
    expect(WeaponTrainingCategory.fromJson('None'), isNull);

    final proficiency = WeaponProficiency(
      WeaponTrainingCategory.simple,
      requiresAnyProperty: [WeaponProperty.light, WeaponProperty.finesse],
    );
    expect(
      () => proficiency.requiresAnyProperty!.add(WeaponProperty.heavy),
      throwsUnsupportedError,
    );
  });

  /// Requirement: doc/specs/content-classes.md FR-008 - value equality, a
  ///   consistent hash code and the debug form.
  /// Path: happy
  test('value equality, hash code and toString hold', () {
    final a = WeaponProficiency(
      WeaponTrainingCategory.martial,
      requiresAnyProperty: [WeaponProperty.light],
    );
    final b = WeaponProficiency(
      WeaponTrainingCategory.martial,
      requiresAnyProperty: [WeaponProperty.light],
    );
    expect(a, equals(b));
    expect(a.hashCode, b.hashCode);
    expect(a, isNot(equals(WeaponProficiency(WeaponTrainingCategory.martial))));
    expect(a.toString(), startsWith('WeaponProficiency('));
    expect(
      WeaponTrainingCategory.martial.toString(),
      'WeaponTrainingCategory.martial',
    );
  });
}
