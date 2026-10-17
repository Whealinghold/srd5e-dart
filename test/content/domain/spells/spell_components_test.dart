import 'package:srd5e/src/content/domain/spells/spell_components.dart';
import 'package:test/test.dart';

import '../../../support/argument_error_matcher.dart';

void main() {
  /// Requirement: doc/specs/content-spells.md FR-041, FR-042, FR-043, FR-044, FR-045,
  ///   FR-101 - the material
  ///   description, its "N+ GP" figures and the consumption flag
  ///   (SRD 5.2.1, "Material (M)", pp. 105-106).
  /// Path: unhappy (invalid input)
  group('MaterialComponent', () {
    /// Requirement: doc/specs/content-spells.md FR-041 - a Material
    ///   component has a non-empty description; an empty one throws
    ///   ArgumentError (SRD 5.2.1, "Material (M)", pp. 105-106).
    /// Path: unhappy (invalid input)
    test(
      'an empty description is rejected; a printed one is kept verbatim',
      () {
        expect(
          () => MaterialComponent('', const [], consumesMaterial: false),
          throwsArgumentErrorFor('description', ''),
        );
        final component = MaterialComponent('a diamond worth 50+ GP', const [
          50,
        ], consumesMaterial: false);
        expect(component.description, 'a diamond worth 50+ GP');
      },
    );

    const costCases = [
      (
        label: 'no cost',
        costs: <int>[],
        valid: true,
        requirement:
            'doc/specs/content-spells.md FR-043 - a description with '
            'no "N+ GP" figure has an empty list (SRD 5.2.1, p. 106)',
        path: 'happy',
      ),
      (
        label: 'cost of one',
        costs: <int>[50],
        valid: true,
        requirement:
            'doc/specs/content-spells.md FR-043 - the figure is kept '
            'without its GP suffix (Chromatic Orb, SRD 5.2.1, p. 115)',
        path: 'happy',
      ),
      (
        label: 'cost zero',
        costs: <int>[0],
        valid: false,
        requirement:
            'doc/specs/content-spells.md FR-101 - a costsGp entry is '
            'at least 1 (SRD 5.2.1, pp. 105-106)',
        path: 'unhappy (boundary)',
      ),
      (
        label: 'cost negative',
        costs: <int>[-1],
        valid: false,
        requirement:
            'doc/specs/content-spells.md FR-101 - a costsGp entry is '
            'at least 1 (SRD 5.2.1, pp. 105-106)',
        path: 'unhappy (boundary)',
      ),
    ];

    /// Requirement: per case
    /// Path: per case
    for (final c in costCases) {
      test('${c.label} [${c.path}]', () {
        if (c.valid) {
          final component = MaterialComponent(
            'a printed description',
            c.costs,
            consumesMaterial: false,
          );
          expect(component.costsGp, c.costs);
        } else {
          expect(
            () => MaterialComponent(
              'a printed description',
              c.costs,
              consumesMaterial: false,
            ),
            throwsArgumentErrorFor('costsGp', c.costs.single),
          );
        }
      });
    }

    /// Requirement: doc/specs/content-spells.md FR-044, FR-045 -
    ///   consumesMaterial is true iff the description states consumption,
    ///   and a non-GP cost (Gentle Repose's Copper Pieces) keeps costsGp
    ///   empty (SRD 5.2.1, pp. 105-106, Gentle Repose p. 135).
    /// Path: unhappy (rule interaction)
    test('Gentle Repose consumes with an empty costsGp list', () {
      final gentleRepose = MaterialComponent(
        '2 Copper Pieces, which the spell consumes',
        const [],
        consumesMaterial: true,
      );
      expect(gentleRepose.consumesMaterial, isTrue);
      expect(gentleRepose.costsGp, isEmpty);
    });

    /// Requirement: doc/specs/content-spells.md FR-086 - the costsGp list is
    ///   an unmodifiable copy.
    /// Path: unhappy (immutability)
    test('the costs list is unmodifiable and copied', () {
      final input = [50];
      final component = MaterialComponent(
        'costly',
        input,
        consumesMaterial: false,
      );
      input.add(100);
      expect(component.costsGp, [50]);
      expect(() => component.costsGp.add(100), throwsUnsupportedError);
      expect(component.costsGp, hasLength(1));
    });

    /// Requirement: doc/specs/content-spells.md FR-111 - isValidCostGp is
    ///   the predicate the decoder reuses.
    /// Path: happy
    test('MaterialComponent.isValidCostGp pins the boundary', () {
      expect(MaterialComponent.isValidCostGp(0), isFalse);
      expect(MaterialComponent.isValidCostGp(1), isTrue);
      expect(MaterialComponent.minCostGp, 1);
    });
  });

  /// Requirement: doc/specs/content-spells.md FR-049 - verbal, somatic and material such
  ///   that M gives a non-null material (SRD 5.2.1, "Components",
  ///   p. 105).
  /// Path: happy
  group('SpellComponents', () {
    /// Requirement: doc/specs/content-spells.md FR-049 - verbal, somatic and
    ///   material such that a spell with M has a non-null material and a
    ///   spell without M has null (SRD 5.2.1, "Components", p. 105).
    /// Path: happy
    test('V, S, M and V, S are both representable', () {
      final withMaterial = SpellComponents(
        verbal: true,
        somatic: true,
        material: MaterialComponent(
          'powdered rhubarb leaf',
          const [],
          consumesMaterial: false,
        ),
      );
      final without = SpellComponents(verbal: true, somatic: true);
      expect(withMaterial.material, isNotNull);
      expect(without.material, isNull);
      expect(withMaterial.verbal, isTrue);
      expect(withMaterial.somatic, isTrue);
    });

    /// Requirement: doc/specs/content-spells.md FR-047 - V alone and S alone
    ///   are representable (SRD 5.2.1, Adventuring Gear table counts,
    ///   "Spell Descriptions", pp. 107-175).
    /// Path: happy
    test('V alone and S alone are representable', () {
      expect(SpellComponents(verbal: true, somatic: false).material, isNull);
      expect(SpellComponents(verbal: false, somatic: true).material, isNull);
    });
  });
}
