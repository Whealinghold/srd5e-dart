import 'package:srd5e/src/content/domain/creature_type.dart';
import 'package:srd5e/src/content/domain/spells/spell_targeting.dart';
import 'package:test/test.dart';

import '../../../support/argument_error_matcher.dart';

/// The label a `switch` over the sealed [AreaShape] family returns, with no
/// default branch.
String shapeLabel(AreaShape shape) => switch (shape) {
  ConeArea() => 'cone',
  CubeArea() => 'cube',
  CylinderArea() => 'cylinder',
  EmanationArea() => 'emanation',
  LineArea() => 'line',
  SphereArea() => 'sphere',
};

/// The label a `switch` over the sealed [SpellTargeting] family returns,
/// with no default branch.
String targetingLabel(SpellTargeting targeting) => switch (targeting) {
  TargetsSelf() => 'self',
  TargetsChosen() => 'chosen',
  TargetsInArea() => 'inArea',
};

/// The label a `switch` over the sealed [TargetCount] family returns, with
/// no default branch.
String countLabel(TargetCount count) => switch (count) {
  ExactlyTargets() => 'exactly',
  UpToTargets() => 'upTo',
  TargetsByInstance() => 'byInstance',
};

/// The label a `switch` over the sealed [CreatureTypeRestriction] family
/// returns, with no default branch.
String restrictionLabel(CreatureTypeRestriction restriction) =>
    switch (restriction) {
      AnyCreatureType() => 'any',
      OnlyCreatureTypes() => 'only',
    };

void main() {
  /// Requirement: doc/specs/spell-effect-data.md FR-013, FR-014 - the six shapes with
  ///   their dimensions and includesOrigin ("Area of Effect",
  ///   SRD 5.2.1, p. 177).
  /// Path: happy
  group('AreaShape (Table A)', () {
    final shapeCases = [
      (
        label: 'A1 ConeArea',
        shape: ConeArea(15),
        includesOrigin: false,
        requirement:
            'doc/specs/spell-effect-data.md FR-013, FR-014 - a cone '
            'of lengthFeet, origin excluded (SRD 5.2.1, "Cone", p. 179)',
        path: 'happy',
      ),
      (
        label: 'A2 CubeArea',
        shape: CubeArea(10),
        includesOrigin: false,
        requirement:
            'doc/specs/spell-effect-data.md FR-013, FR-014 - a cube '
            'of sideFeet, origin excluded (SRD 5.2.1, "Cube", p. 179)',
        path: 'happy',
      ),
      (
        label: 'A3 CylinderArea',
        shape: CylinderArea(10, 40),
        includesOrigin: true,
        requirement:
            'doc/specs/spell-effect-data.md FR-013, FR-014 - a '
            'cylinder of radiusFeet and heightFeet, origin included '
            '(SRD 5.2.1, "Cylinder", p. 180)',
        path: 'happy',
      ),
      (
        label: 'A4 EmanationArea',
        shape: EmanationArea(15),
        includesOrigin: false,
        requirement:
            'doc/specs/spell-effect-data.md FR-013, FR-014 - an '
            'emanation of distanceFeet, origin excluded (SRD 5.2.1, '
            '"Emanation", p. 181)',
        path: 'happy',
      ),
      (
        label: 'A5 LineArea',
        shape: LineArea(100, 5),
        includesOrigin: false,
        requirement:
            'doc/specs/spell-effect-data.md FR-013, FR-014 - a line '
            'of lengthFeet and widthFeet, origin excluded (SRD 5.2.1, '
            '"Line", p. 184)',
        path: 'happy',
      ),
      (
        label: 'A6 SphereArea',
        shape: SphereArea(20),
        includesOrigin: true,
        requirement:
            'doc/specs/spell-effect-data.md FR-013, FR-014 - a '
            'sphere of radiusFeet, origin included (SRD 5.2.1, "Sphere", '
            'p. 188)',
        path: 'happy',
      ),
    ];

    /// Requirement: per case
    /// Path: per case
    for (final c in shapeCases) {
      test('${c.label} includesOrigin ${c.includesOrigin} [${c.path}]', () {
        expect(c.shape.includesOrigin, c.includesOrigin);
        expect(shapeLabel(c.shape), isNotEmpty);
      });
    }

    final boundaryCases = [
      (
        label: 'A7 SphereArea(0)',
        build: () => SphereArea(0),
        name: 'radiusFeet',
        value: 0,
        requirement:
            'doc/specs/spell-effect-data.md FR-013 - every dimension '
            'is at least 1 (SRD 5.2.1, "Area of Effect", p. 177)',
        path: 'unhappy (boundary)',
      ),
      (
        label: 'A8 SphereArea(1)',
        build: () => SphereArea(1),
        name: null,
        value: null,
        requirement:
            'doc/specs/spell-effect-data.md FR-013 - a radius of 1 '
            'is the smallest sphere (SRD 5.2.1, p. 177)',
        path: 'unhappy (boundary)',
      ),
      (
        label: 'A9 LineArea(100, 0)',
        build: () => LineArea(100, 0),
        name: 'widthFeet',
        value: 0,
        requirement:
            'doc/specs/spell-effect-data.md FR-013 - every dimension '
            'is at least 1 (SRD 5.2.1, "Line", p. 184)',
        path: 'unhappy (boundary)',
      ),
      (
        label: 'A10 CylinderArea(10, -40)',
        build: () => CylinderArea(10, -40),
        name: 'heightFeet',
        value: -40,
        requirement:
            'doc/specs/spell-effect-data.md FR-013 - every dimension '
            'is at least 1 (SRD 5.2.1, "Cylinder", p. 180)',
        path: 'unhappy (invalid input)',
      ),
    ];

    /// Requirement: per case
    /// Path: per case
    for (final c in boundaryCases) {
      test('${c.label} [${c.path}]', () {
        if (c.name == null) {
          expect((c.build() as SphereArea).radiusFeet, 1);
        } else {
          expect(c.build, throwsArgumentErrorFor(c.name!, c.value));
        }
      });
    }
  });

  /// Requirement: doc/specs/spell-effect-data.md FR-015 - the restriction is any creature
  ///   or a non-empty set, and creatures only (SRD 5.2.1, p. 106;
  ///   "Hold Person", p. 141).
  /// Path: unhappy (invalid input)
  group('CreatureTypeRestriction (Table T)', () {
    /// Requirement: doc/specs/spell-effect-data.md FR-015 - an empty
    ///   creature type set throws (SRD 5.2.1, "Invalid Targets", p. 106).
    /// Path: unhappy (invalid input)
    test('T1 OnlyCreatureTypes({}) throws', () {
      expect(
        () => OnlyCreatureTypes(const {}),
        throwsArgumentErrorFor('types', const <CreatureType>{}),
      );
    });

    /// Requirement: doc/specs/spell-effect-data.md FR-015 - a creature
    ///   restriction with an object subject is rejected where both are held
    ///   (SRD 5.2.1, p. 106).
    /// Path: unhappy (invalid input)
    test('T2 OnlyCreatureTypes({Humanoid}) with subject object throws', () {
      expect(
        () => TargetsChosen(
          TargetSubject.object,
          ExactlyTargets(1),
          OnlyCreatureTypes(const {CreatureType.humanoid}),
        ),
        throwsArgumentErrorFor(
          'restriction',
          OnlyCreatureTypes(const {CreatureType.humanoid}),
        ),
      );
      // The same rule binds an in-area targeting.
      expect(
        () => TargetsInArea(
          SphereArea(20),
          TargetSubject.object,
          OnlyCreatureTypes(const {CreatureType.humanoid}),
        ),
        throwsArgumentErrorFor(
          'restriction',
          OnlyCreatureTypes(const {CreatureType.humanoid}),
        ),
      );
    });

    /// Requirement: doc/specs/spell-effect-data.md FR-015 - Hold Person
    ///   targets a Humanoid creature (SRD 5.2.1, "Hold Person", p. 141).
    /// Path: happy
    test('T3 OnlyCreatureTypes({Humanoid}) with subject creature is valid', () {
      final targeting = TargetsChosen(
        TargetSubject.creature,
        ExactlyTargets(1),
        OnlyCreatureTypes(const {CreatureType.humanoid}),
      );
      expect(restrictionLabel(targeting.restriction), 'only');
      expect(
        targeting.restriction,
        OnlyCreatureTypes(const {CreatureType.humanoid}),
      );
    });
  });

  /// Requirement: doc/specs/spell-effect-data.md FR-012 - the three count shapes, n at
  ///   least 1 (SRD 5.2.1, "Targets", p. 106).
  /// Path: unhappy (boundary)
  group('TargetCount', () {
    /// Requirement: doc/specs/spell-effect-data.md FR-012 - n at least 1; 0
    ///   and negative throw (SRD 5.2.1, "Targets", p. 106).
    /// Path: unhappy (boundary)
    test('ExactlyTargets and UpToTargets reject 0 and negative', () {
      expect(() => ExactlyTargets(0), throwsArgumentErrorFor('n', 0));
      expect(() => UpToTargets(-1), throwsArgumentErrorFor('n', -1));
      expect(ExactlyTargets(1).n, 1);
      expect(UpToTargets(3).n, 3);
    });

    /// Requirement: doc/specs/spell-effect-data.md FR-012 - the three count
    ///   shapes are exhaustive, with TargetsByInstance for instance-assigned
    ///   targets ("Magic Missile", SRD 5.2.1, p. 146).
    /// Path: happy
    test('the three counts are exhaustive and distinct', () {
      final counts = [
        ExactlyTargets(1),
        UpToTargets(3),
        const TargetsByInstance(),
      ];
      expect(counts.map(countLabel).toSet(), {'exactly', 'upTo', 'byInstance'});
      expect(counts[0], isNot(counts[1]));
      expect(const TargetsByInstance(), const TargetsByInstance());
    });
  });

  /// Requirement: doc/specs/spell-effect-data.md FR-010, FR-011, FR-040 - the three
  ///   targeting shapes; only chosen targets carry a self policy
  ///   (SRD 5.2.1, p. 106).
  /// Path: happy
  group('SpellTargeting', () {
    /// Requirement: doc/specs/spell-effect-data.md FR-010, FR-040 - the
    ///   three targeting shapes; only TargetsChosen carries a
    ///   SelfTargetPolicy ("Targeting Yourself", SRD 5.2.1, p. 106).
    /// Path: happy
    test('self, chosen and inArea are exhaustive and distinct', () {
      final targetings = <SpellTargeting>[
        const TargetsSelf(),
        TargetsChosen(
          TargetSubject.creature,
          ExactlyTargets(1),
          const AnyCreatureType(),
          selfPolicy: SelfTargetPolicy.excludesCaster,
        ),
        TargetsInArea(
          SphereArea(20),
          TargetSubject.creature,
          const AnyCreatureType(),
        ),
      ];
      expect(targetings.map(targetingLabel).toSet(), {
        'self',
        'chosen',
        'inArea',
      });
      expect(
        (targetings[1] as TargetsChosen).selfPolicy,
        SelfTargetPolicy.excludesCaster,
      );
    });

    /// Requirement: doc/specs/spell-effect-data.md FR-040 - mayIncludeCaster
    ///   is the default (SRD 5.2.1, p. 106).
    /// Path: happy
    test('the self policy defaults to mayIncludeCaster', () {
      final targeting = TargetsChosen(
        TargetSubject.creatureOrObject,
        ExactlyTargets(1),
        const AnyCreatureType(),
      );
      expect(targeting.selfPolicy, SelfTargetPolicy.mayIncludeCaster);
    });

    /// Requirement: doc/specs/spell-effect-data.md FR-011 - the three
    ///   subjects ("creatures, objects, or something else", SRD 5.2.1,
    ///   p. 106).
    /// Path: happy
    test('TargetSubject has exactly the three members', () {
      expect(TargetSubject.values, hasLength(3));
      expect(TargetSubject.values, contains(TargetSubject.creatureOrObject));
    });
  });
}
