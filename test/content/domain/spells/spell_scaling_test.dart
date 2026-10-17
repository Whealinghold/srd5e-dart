import 'package:srd5e/src/content/domain/spells/spell_scaling.dart';
import 'package:srd5e/src/shared_kernel/dice/dice_expression.dart';
import 'package:srd5e/src/shared_kernel/dice/die.dart';
import 'package:test/test.dart';

import '../../../support/argument_error_matcher.dart';
import '../../../support/operator_equals.dart';

RolledSpellAmount _dice(int count, Die die) =>
    RolledSpellAmount(DiceExpression(count, die));

void main() {
  /// Requirement: doc/specs/spell-effect-data.md FR-016, FR-021, FR-041 - the step applies
  ///   n times; two outcomes scale independently; the invalid steps
  ///   throw (SRD 5.2.1, pp. 104-105).
  /// Path: unhappy (boundary)
  group('AmountStep and per-slot amounts (Table L)', () {
    final slotCases =
        <
          ({
            String label,
            ScalableAmount amount,
            int n,
            String expected,
            String requirement,
            String path,
          })
        >[
          (
            label: 'L1 Fireball n=0',
            amount: ScalableAmount(
              _dice(8, Die.d6),
              scaling: PerSlotLevelAmount(3, AmountStep(extraDice: 1)),
            ),
            n: 0,
            expected: 'RolledSpellAmount(8d6)',
            requirement:
                'doc/specs/spell-effect-data.md FR-016 - zero levels '
                'above leaves the base ("Fireball", SRD 5.2.1, p. 131)',
            path: 'unhappy (boundary)',
          ),
          (
            label: 'L2 Fireball n=1',
            amount: ScalableAmount(
              _dice(8, Die.d6),
              scaling: PerSlotLevelAmount(3, AmountStep(extraDice: 1)),
            ),
            n: 1,
            expected: 'RolledSpellAmount(9d6)',
            requirement:
                'doc/specs/spell-effect-data.md FR-016 - one level above '
                'adds one die ("Fireball", SRD 5.2.1, p. 131)',
            path: 'happy',
          ),
          (
            label: 'L3 Fireball n=6',
            amount: ScalableAmount(
              _dice(8, Die.d6),
              scaling: PerSlotLevelAmount(3, AmountStep(extraDice: 1)),
            ),
            n: 6,
            expected: 'RolledSpellAmount(14d6)',
            requirement:
                'doc/specs/spell-effect-data.md FR-016 - six levels '
                'above add six dice ("Fireball", SRD 5.2.1, p. 131)',
            path: 'unhappy (boundary)',
          ),
          (
            label: 'L4 Cure Wounds n=0',
            amount: ScalableAmount(
              _dice(2, Die.d8),
              scaling: PerSlotLevelAmount(1, AmountStep(extraDice: 2)),
            ),
            n: 0,
            expected: 'RolledSpellAmount(2d8)',
            requirement:
                'doc/specs/spell-effect-data.md FR-016 - zero levels '
                'above leaves the base ("Cure Wounds", SRD 5.2.1, p. 121)',
            path: 'unhappy (boundary)',
          ),
          (
            label: 'L5 Cure Wounds n=1',
            amount: ScalableAmount(
              _dice(2, Die.d8),
              scaling: PerSlotLevelAmount(1, AmountStep(extraDice: 2)),
            ),
            n: 1,
            expected: 'RolledSpellAmount(4d8)',
            requirement:
                'doc/specs/spell-effect-data.md FR-016 - +2d8 per level '
                '("Cure Wounds", SRD 5.2.1, p. 121)',
            path: 'happy',
          ),
          (
            label: 'L6 Cure Wounds n=8',
            amount: ScalableAmount(
              _dice(2, Die.d8),
              scaling: PerSlotLevelAmount(1, AmountStep(extraDice: 2)),
            ),
            n: 8,
            expected: 'RolledSpellAmount(18d8)',
            requirement:
                'doc/specs/spell-effect-data.md FR-016 - eight levels '
                'above add sixteen dice ("Cure Wounds", SRD 5.2.1, p. 121)',
            path: 'unhappy (boundary)',
          ),
          (
            label: 'L7 False Life n=0',
            amount: ScalableAmount(
              RolledSpellAmount(DiceExpression(2, Die.d4, modifier: 4)),
              scaling: PerSlotLevelAmount(1, AmountStep(extraFlat: 5)),
            ),
            n: 0,
            expected: 'RolledSpellAmount(2d4+4)',
            requirement:
                'doc/specs/spell-effect-data.md FR-016 - zero levels '
                'above leaves the base ("False Life", SRD 5.2.1, p. 129)',
            path: 'unhappy (boundary)',
          ),
          (
            label: 'L8 False Life n=2',
            amount: ScalableAmount(
              RolledSpellAmount(DiceExpression(2, Die.d4, modifier: 4)),
              scaling: PerSlotLevelAmount(1, AmountStep(extraFlat: 5)),
            ),
            n: 2,
            expected: 'RolledSpellAmount(2d4+14)',
            requirement:
                'doc/specs/spell-effect-data.md FR-016 - +5 flat per '
                'level ("False Life", SRD 5.2.1, p. 129)',
            path: 'happy',
          ),
          (
            label: 'L9 False Life n=8',
            amount: ScalableAmount(
              RolledSpellAmount(DiceExpression(2, Die.d4, modifier: 4)),
              scaling: PerSlotLevelAmount(1, AmountStep(extraFlat: 5)),
            ),
            n: 8,
            expected: 'RolledSpellAmount(2d4+44)',
            requirement:
                'doc/specs/spell-effect-data.md FR-016 - eight levels '
                'above add forty ("False Life", SRD 5.2.1, p. 129)',
            path: 'unhappy (boundary)',
          ),
          (
            label: 'L10 Heal n=0',
            amount: ScalableAmount(
              FixedSpellAmount(70),
              scaling: PerSlotLevelAmount(6, AmountStep(extraFlat: 10)),
            ),
            n: 0,
            expected: 'FixedSpellAmount(70)',
            requirement:
                'doc/specs/spell-effect-data.md FR-016 - zero levels '
                'above leaves the base ("Heal", SRD 5.2.1, p. 139)',
            path: 'unhappy (boundary)',
          ),
          (
            label: 'L11 Heal n=1',
            amount: ScalableAmount(
              FixedSpellAmount(70),
              scaling: PerSlotLevelAmount(6, AmountStep(extraFlat: 10)),
            ),
            n: 1,
            expected: 'FixedSpellAmount(80)',
            requirement:
                'doc/specs/spell-effect-data.md FR-016 - +10 per level '
                'on a fixed base ("Heal", SRD 5.2.1, p. 139)',
            path: 'happy',
          ),
          (
            label: 'L12 Heal n=3',
            amount: ScalableAmount(
              FixedSpellAmount(70),
              scaling: PerSlotLevelAmount(6, AmountStep(extraFlat: 10)),
            ),
            n: 3,
            expected: 'FixedSpellAmount(100)',
            requirement:
                'doc/specs/spell-effect-data.md FR-016 - three levels '
                'above add thirty ("Heal", SRD 5.2.1, p. 139)',
            path: 'unhappy (boundary)',
          ),
        ];

    /// Requirement: per case
    /// Path: per case
    for (final c in slotCases) {
      test('${c.label} gives ${c.expected} [${c.path}]', () {
        final grown = c.amount.amountAt(
          slotLevelsAbove: c.n,
          characterLevel: 1,
        );
        expect(grown.toString(), c.expected);
      });
    }

    /// Requirement: doc/specs/spell-effect-data.md FR-016, FR-021 - two
    ///   outcomes scale independently, each by its own scaling ("Flame
    ///   Strike", SRD 5.2.1, p. 132).
    /// Path: happy
    test('L13 two outcomes scale independently', () {
      final fire = ScalableAmount(
        _dice(5, Die.d6),
        scaling: PerSlotLevelAmount(5, AmountStep(extraDice: 1)),
      );
      final radiant = ScalableAmount(
        _dice(5, Die.d6),
        scaling: PerSlotLevelAmount(5, AmountStep(extraDice: 1)),
      );
      const n = 2;
      expect(
        fire.amountAt(slotLevelsAbove: n, characterLevel: 1).toString(),
        'RolledSpellAmount(7d6)',
      );
      expect(
        radiant.amountAt(slotLevelsAbove: n, characterLevel: 1).toString(),
        'RolledSpellAmount(7d6)',
      );
    });

    /// Requirement: doc/specs/spell-effect-data.md FR-016 - a step with both
    ///   parts 0 throws.
    /// Path: unhappy (invalid input)
    test('L21 a step adding nothing is rejected', () {
      expect(
        () => AmountStep(extraDice: 0, extraFlat: 0),
        throwsArgumentErrorFor('extraDice', 0),
      );
    });

    /// Requirement: doc/specs/spell-effect-data.md FR-016 - extraDice on a
    ///   fixed base throws.
    /// Path: unhappy (invalid input)
    test('L22 extra dice on a fixed base is rejected', () {
      expect(
        () => ScalableAmount(
          FixedSpellAmount(70),
          scaling: PerSlotLevelAmount(6, AmountStep(extraDice: 1)),
        ),
        throwsA(isA<ArgumentError>().having((e) => e.name, 'name', 'scaling')),
      );
    });

    /// Requirement: doc/specs/spell-effect-data.md FR-041 - a negative n
    ///   throws.
    /// Path: unhappy (invalid input)
    test('L24 a negative n is rejected', () {
      final fireball = ScalableAmount(
        _dice(8, Die.d6),
        scaling: PerSlotLevelAmount(3, AmountStep(extraDice: 1)),
      );
      expect(
        () => fireball.amountAt(slotLevelsAbove: -1, characterLevel: 1),
        throwsArgumentErrorFor('slotLevelsAbove', -1),
      );
    });
  });

  /// Requirement: doc/specs/spell-effect-data.md FR-012, FR-017, FR-041 - the count grows
  ///   by extra per level above (SRD 5.2.1, pp. 141, 146).
  /// Path: unhappy (boundary)
  group('Count scaling (Table L counts)', () {
    const countCases = [
      (label: 'L14 n=0', base: 3, n: 0, expected: 3),
      (label: 'L15 n=1', base: 3, n: 1, expected: 4),
      (label: 'L16 n=8', base: 3, n: 8, expected: 11),
    ];

    /// Requirement: per case
    /// Path: per case
    for (final c in countCases) {
      test('${c.label} gives ${c.expected} darts', () {
        final scaling = PerSlotLevelCount(1, 1);
        expect(
          scaling.countAt(c.base, slotLevelsAbove: c.n, characterLevel: 1),
          c.expected,
        );
      });
    }

    const targetCases = [
      (label: 'L17 n=0', n: 0, expected: 1),
      (label: 'L18 n=1', n: 1, expected: 2),
      (label: 'L19 n=7', n: 7, expected: 8),
    ];

    /// Requirement: per case
    /// Path: per case
    for (final c in targetCases) {
      test('${c.label} gives ${c.expected} Humanoids', () {
        final scaling = PerSlotLevelCount(2, 1);
        expect(
          scaling.countAt(1, slotLevelsAbove: c.n, characterLevel: 1),
          c.expected,
        );
      });
    }

    /// Requirement: doc/specs/spell-effect-data.md FR-017 - extra below 1
    ///   throws.
    /// Path: unhappy (invalid input)
    test('a PerSlotLevelCount extra of 0 is rejected', () {
      expect(() => PerSlotLevelCount(1, 0), throwsArgumentErrorFor('extra', 0));
    });

    /// Requirement: doc/specs/spell-effect-data.md FR-041 - a negative n on
    ///   a count query throws.
    /// Path: unhappy (invalid input)
    test('a negative n on a count query is rejected', () {
      expect(
        () => PerSlotLevelCount(
          1,
          1,
        ).countAt(3, slotLevelsAbove: -1, characterLevel: 1),
        throwsArgumentErrorFor('slotLevelsAbove', -1),
      );
    });
  });

  /// Requirement: doc/specs/spell-effect-data.md FR-018, FR-019, FR-020, FR-041 - the
  ///   printed
  ///   table selects by total character level; the invalid tables
  ///   throw (SRD 5.2.1, pp. 25, 107, 127, 132, 171).
  /// Path: unhappy (boundary)
  group('CharacterLevelTable (Table C)', () {
    final fireBolt = CharacterLevelTable<SpellAmountLike>([
      (1, RolledSpellAmount(DiceExpression(1, Die.d10))),
      (5, RolledSpellAmount(DiceExpression(2, Die.d10))),
      (11, RolledSpellAmount(DiceExpression(3, Die.d10))),
      (17, RolledSpellAmount(DiceExpression(4, Die.d10))),
    ]);

    /// Requirement: doc/specs/spell-effect-data.md FR-018 - the entry with
    ///   the greatest level not above the character level ("Fire Bolt",
    ///   SRD 5.2.1, p. 132).
    /// Path: unhappy (boundary)
    test('C1-C8 Fire Bolt selects the printed total', () {
      expect(fireBolt.valueAt(1).toString(), 'RolledSpellAmount(1d10)');
      expect(fireBolt.valueAt(4).toString(), 'RolledSpellAmount(1d10)');
      expect(fireBolt.valueAt(5).toString(), 'RolledSpellAmount(2d10)');
      expect(fireBolt.valueAt(10).toString(), 'RolledSpellAmount(2d10)');
      expect(fireBolt.valueAt(11).toString(), 'RolledSpellAmount(3d10)');
      expect(fireBolt.valueAt(16).toString(), 'RolledSpellAmount(3d10)');
      expect(fireBolt.valueAt(17).toString(), 'RolledSpellAmount(4d10)');
      expect(fireBolt.valueAt(20).toString(), 'RolledSpellAmount(4d10)');
    });

    /// Requirement: doc/specs/spell-effect-data.md FR-018, FR-020 - the
    ///   printed totals ("Acid Splash", Cantrip Upgrade, SRD 5.2.1,
    ///   p. 107).
    /// Path: happy
    test('C13 Acid Splash selects 4d6 at character level 17', () {
      final acidSplash = CharacterLevelTable<RolledSpellAmount>([
        (1, RolledSpellAmount(DiceExpression(1, Die.d6))),
        (5, RolledSpellAmount(DiceExpression(2, Die.d6))),
        (11, RolledSpellAmount(DiceExpression(3, Die.d6))),
        (17, RolledSpellAmount(DiceExpression(4, Die.d6))),
      ]);
      expect(acidSplash.valueAt(17).toString(), 'RolledSpellAmount(4d6)');
    });

    /// Requirement: doc/specs/spell-effect-data.md FR-018, FR-020 - the
    ///   printed counts, not increments ("Eldritch Blast", SRD 5.2.1,
    ///   p. 127).
    /// Path: unhappy (boundary)
    test('C9-C12 Eldritch Blast selects the printed beam count', () {
      final beams = CharacterLevelTable<int>([
        (1, 1),
        (5, 2),
        (11, 3),
        (17, 4),
      ]);
      expect(beams.valueAt(4), 1);
      expect(beams.valueAt(5), 2);
      expect(beams.valueAt(11), 3);
      expect(beams.valueAt(17), 4);
    });

    /// Requirement: doc/specs/spell-effect-data.md FR-041 - the character
    ///   level is the total character level ("Cantrips", SRD 5.2.1, p. 25).
    /// Path: unhappy (rule interaction)
    test('C14 a multiclass character level 5 selects the level-5 entry', () {
      expect(fireBolt.valueAt(5).toString(), 'RolledSpellAmount(2d10)');
    });

    final invalidCases =
        <
          ({
            String label,
            Object Function() build,
            String requirement,
            String path,
          })
        >[
          (
            label: 'C15 first entry at level 2',
            build: () => CharacterLevelTable<int>([(2, 1)]),
            requirement:
                'doc/specs/spell-effect-data.md FR-019 - the first level '
                'is 1 (SRD 5.2.1, "Fire Bolt", p. 132)',
            path: 'unhappy (invalid input)',
          ),
          (
            label: 'C16 levels 5 then 5',
            build: () => CharacterLevelTable<int>([(1, 1), (5, 2), (5, 3)]),
            requirement:
                'doc/specs/spell-effect-data.md FR-019 - strictly '
                'ascending levels',
            path: 'unhappy (invalid input)',
          ),
          (
            label: 'C17 a level 21 entry',
            build: () => CharacterLevelTable<int>([(1, 1), (21, 2)]),
            requirement:
                'doc/specs/spell-effect-data.md FR-019 - levels 1 to 20',
            path: 'unhappy (boundary)',
          ),
          (
            label: 'C19 True Strike, no level-1 entry',
            build: () => CharacterLevelTable<int>([(5, 1)]),
            requirement:
                'doc/specs/spell-effect-data.md FR-019 - a table starts '
                'at level 1, so a later-only upgrade cannot be held ("True '
                'Strike", SRD 5.2.1, p. 171)',
            path: 'unhappy (rule interaction)',
          ),
        ];

    /// Requirement: per case
    /// Path: per case
    for (final c in invalidCases) {
      test('${c.label} throws [${c.path}]', () {
        expect(
          c.build,
          throwsA(
            isA<ArgumentError>().having((e) => e.name, 'name', 'entries'),
          ),
        );
      });
    }

    /// Requirement: doc/specs/spell-effect-data.md FR-041 - the character
    ///   level is 1 to 20, else ArgumentError.
    /// Path: unhappy (boundary)
    test('C20 a query with level 0 or 21 is rejected', () {
      expect(
        () => fireBolt.valueAt(0),
        throwsArgumentErrorFor('characterLevel', 0),
      );
      expect(
        () => fireBolt.valueAt(21),
        throwsArgumentErrorFor('characterLevel', 21),
      );
    });

    /// Requirement: doc/specs/spell-effect-data.md FR-008 - the table is a
    ///   value object over its entries: equal tables are equal, and another
    ///   type, a different length, a different level and a different value
    ///   each break equality; the level range is inclusive, so an entry at
    ///   level 20 is valid.
    /// Path: happy
    test('tables and amounts compare by value', () {
      final same = CharacterLevelTable<int>([(1, 1), (5, 2)]);
      final again = CharacterLevelTable<int>([(1, 1), (5, 2)]);
      expect(same, again);
      expect(same.hashCode, again.hashCode);
      expect(FixedSpellAmount(5), FixedSpellAmount(5));
      expect(_dice(1, Die.d6), _dice(1, Die.d6));
      expect(operatorEquals(same, 5), isFalse);
      expect(operatorEquals(same, CharacterLevelTable<int>([(1, 1)])), isFalse);
      expect(
        operatorEquals(same, CharacterLevelTable<int>([(1, 1), (6, 2)])),
        isFalse,
      );
      expect(
        operatorEquals(same, CharacterLevelTable<int>([(1, 1), (5, 3)])),
        isFalse,
      );
      expect(CharacterLevelTable<int>([(1, 1), (20, 2)]).valueAt(20), 2);
    });

    /// Requirement: doc/specs/spell-effect-data.md FR-019 - the error for a
    ///   table not starting at level 1 names the first entry's level as the
    ///   offending value, not a later entry's.
    /// Path: unhappy (invalid input)
    test('C22 the first-level error names the first entry', () {
      expect(
        () => CharacterLevelTable<int>([(2, 1), (3, 2)]),
        throwsArgumentErrorFor('entries', 2),
      );
    });
  });
}

/// The table value type of the Fire Bolt rows: a printed spell amount.
typedef SpellAmountLike = RolledSpellAmount;
