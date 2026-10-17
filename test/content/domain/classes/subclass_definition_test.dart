import 'package:srd5e/src/content/domain/classes/feature_entry.dart';
import 'package:srd5e/src/content/domain/classes/feature_fact.dart';
import 'package:srd5e/src/content/domain/classes/subclass_definition.dart';
import 'package:srd5e/src/content/domain/typed_ids.dart';
import 'package:test/test.dart';

import '../../../support/argument_error_matcher.dart';
import 'class_fixture.dart';

FeatureEntry _subclassFeature(String id, int level) => FeatureEntry(
  id: FeatureId(id),
  name: 'Berserker feature',
  level: level,
  text: 'A feature of the subclass.',
);

SubclassDefinition _subclass() => SubclassDefinition(
  id: SubclassId('berserker'),
  name: 'Path of the Berserker',
  features: [_subclassFeature('berserker_frenzy', 3)],
);

SubclassDefinition _emptySubclass() => SubclassDefinition(
  id: SubclassId('berserker'),
  name: 'Path of the Berserker',
  features: const [],
);

SubclassDefinition _blankNameSubclass() => SubclassDefinition(
  id: SubclassId('berserker'),
  name: ' ',
  features: [_subclassFeature('berserker_frenzy', 3)],
);

SubclassDefinition _threeFeatureSubclass() => SubclassDefinition(
  id: SubclassId('berserker'),
  name: 'Path of the Berserker',
  features: [
    _subclassFeature('berserker_frenzy', 3),
    _subclassFeature('berserker_mindless_rage', 6),
    _subclassFeature('berserker_intimidating_presence', 10),
  ],
);

SubclassDefinition _factSubclass() => SubclassDefinition(
  id: SubclassId('berserker'),
  name: 'Path of the Berserker',
  features: [
    FeatureEntry(
      id: FeatureId('berserker_frenzy'),
      name: 'Frenzy',
      level: 3,
      text: 'A feature of the subclass.',
      facts: [const GrantsSubclass()],
    ),
  ],
);

void main() {
  /// Requirement: doc/specs/content-classes.md FR-070 - a
  ///   `SubclassDefinition` has a `SubclassId`, a non-blank name and a
  ///   non-empty feature list; a class may have no subclasses (SRD 5.2.1,
  ///   "Barbarian Subclass: Path of the Berserker", p. 30).
  /// Path: happy
  group('SubclassDefinition constructor rows', () {
    /// Requirement: per case
    /// Path: per case
    for (final c in [
      (
        label: 'a subclass',
        requirement:
            'doc/specs/content-classes.md FR-070 - a subclass of id, name '
            'and one feature constructs',
        path: 'happy',
        build: _subclass,
        throwsFor: null,
        throwsForName: null,
      ),
      (
        label: 'empty features',
        requirement:
            'doc/specs/content-classes.md FR-070 - an empty feature list is '
            'rejected',
        path: 'unhappy (empty case)',
        build: _emptySubclass,
        throwsFor: null,
        throwsForName: 'features',
      ),
      (
        label: 'blank name',
        requirement:
            'doc/specs/content-classes.md FR-070 - a blank name is rejected',
        path: 'unhappy (invalid input)',
        build: _blankNameSubclass,
        throwsFor: throwsArgumentErrorFor('name', ' '),
        throwsForName: null,
      ),
    ]) {
      test('${c.label} [${c.path}]', () {
        if (c.throwsFor != null) {
          expect(c.build, c.throwsFor);
        } else if (c.throwsForName != null) {
          expect(
            c.build,
            throwsA(
              isA<ArgumentError>().having(
                (e) => e.name,
                'name',
                c.throwsForName,
              ),
            ),
          );
        } else {
          expect(c.build(), isA<SubclassDefinition>());
        }
      });
    }
  });

  /// Requirement: doc/specs/content-classes.md FR-075 - `featuresAtOrBelow`
  ///   returns the features whose level does not exceed the argument, in
  ///   printed order, and [] below the subclass level; it throws outside 1
  ///   to 20 (SRD 5.2.1, "Level 3: Barbarian Subclass", p. 29).
  /// Path: happy
  group('featuresAtOrBelow rows', () {
    final subclass = _threeFeatureSubclass();

    /// Requirement: per case
    /// Path: per case
    for (final c in [
      (
        label: 'at level 1',
        requirement:
            'doc/specs/content-classes.md FR-075 - level 1, the lowest '
            'valid level, is accepted and empty below the subclass level',
        path: 'unhappy (boundary)',
        level: 1,
        expected: 0,
      ),
      (
        label: 'below the subclass level',
        requirement:
            'doc/specs/content-classes.md FR-075 - level 2, below the '
            'subclass level 3, is empty',
        path: 'unhappy (boundary)',
        level: 2,
        expected: 0,
      ),
      (
        label: 'at the subclass level',
        requirement:
            'doc/specs/content-classes.md FR-075 - level 3 returns the '
            'level 3 feature',
        path: 'happy',
        level: 3,
        expected: 1,
      ),
      (
        label: 'between features',
        requirement:
            'doc/specs/content-classes.md FR-075 - level 5 returns only the '
            'level 3 feature',
        path: 'happy',
        level: 5,
        expected: 1,
      ),
      (
        label: 'at level 20',
        requirement:
            'doc/specs/content-classes.md FR-075 - level 20 returns every '
            'feature in printed order',
        path: 'unhappy (boundary)',
        level: 20,
        expected: 3,
      ),
    ]) {
      test('${c.label} [${c.path}]', () {
        final features = subclass.featuresAtOrBelow(c.level);
        expect(features.length, c.expected);
        if (c.level >= 10) {
          expect(features.map((f) => f.level), [3, 6, 10]);
        }
      });
    }

    /// Requirement: doc/specs/content-classes.md FR-075 - level 0 throws.
    /// Path: unhappy (boundary)
    test('level 0 throws', () {
      expect(
        () => subclass.featuresAtOrBelow(0),
        throwsArgumentErrorFor('level', 0),
      );
    });

    /// Requirement: doc/specs/content-classes.md FR-075 - level 21 throws.
    /// Path: unhappy (boundary)
    test('level 21 throws', () {
      expect(
        () => subclass.featuresAtOrBelow(21),
        throwsArgumentErrorFor('level', 21),
      );
    });
  });

  /// Requirement: doc/specs/content-classes.md FR-073, FR-008 - a subclass
  ///   is validated against the class when added; value equality holds; the
  ///   feature list is unmodifiable.
  /// Path: happy
  test('value equality and unmodifiability hold', () {
    final subclass = _subclass();
    expect(subclass, equals(_subclass()));
    expect(subclass.hashCode, _subclass().hashCode);
    expect(subclass.toString(), 'SubclassDefinition(berserker)');
    expect(() => subclass.features.clear(), throwsUnsupportedError);
  });

  /// Requirement: doc/specs/content-classes.md FR-056 - a subclass feature
  ///   MUST NOT carry GrantsSubclass; the `ClassDefinition` constructor
  ///   enforces it.
  /// Path: unhappy (rule interaction)
  test('the class constructor rejects a subclass feature with the fact', () {
    expect(
      () => buildTestClass(subclasses: [_factSubclass()]),
      throwsA(isA<ArgumentError>()),
    );
  });
}
