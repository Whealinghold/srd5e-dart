import 'package:srd5e/src/content/domain/background.dart';
import 'package:srd5e/src/content/domain/background_feat_reference.dart';
import 'package:srd5e/src/content/domain/custom_background_equipment.dart';
import 'package:srd5e/src/content/domain/equipment_item_value.dart';
import 'package:srd5e/src/content/domain/equipment_options.dart';
import 'package:srd5e/src/content/domain/skill.dart';
import 'package:srd5e/src/content/domain/tool_proficiency.dart';
import 'package:srd5e/src/content/domain/typed_ids.dart';
import 'package:srd5e/src/shared_kernel/ability/ability.dart';
import 'package:test/test.dart';

import '../../support/argument_error_matcher.dart';
import '../../support/operator_equals.dart';

/// A valuation pricing every item the same, optionally excluded; the case
/// tables use fixture functions, no equipment content is read (FR-073).
EquipmentValuation _priced(int copperPieces, {bool excluded = false}) =>
    (item) => EquipmentItemValue(
      copperPieces: copperPieces,
      isMartialWeaponOrArmor: excluded,
    );

/// A valuation marking every item unpriced (returns null).
EquipmentItemValue? _unpriced(EquipmentItem item) => null;

void main() {
  /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-072,
  ///   FR-073 - the step-5 function over the "Cases: custom background
  ///   equipment" table, one test per row; each row carries its own path.
  /// Path: unhappy (boundary)
  group('Cases: custom background equipment', () {
    /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-073 -
    ///   "50 GP by gold alone": no items, gold 50 gives no problems.
    /// Path: happy
    test('gold alone worth 50 GP gives no problems', () {
      final problems = customBackgroundEquipmentProblems(
        EquipmentOption([], 50),
        _priced(0),
      );

      expect(problems, isEmpty);
    });

    /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-073 -
    ///   "items plus gold": 2 x 1000 CP + 30 GP totals 5000 CP.
    /// Path: happy
    test('two items at 1000 CP with 30 GP gives no problems', () {
      final problems = customBackgroundEquipmentProblems(
        EquipmentOption([EquipmentItem('Item', 2)], 30),
        _priced(1000),
      );

      expect(problems, isEmpty);
    });

    /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-073 -
    ///   "items plus gold": 3 x 1000 CP + 20 GP totals 5000 CP.
    /// Path: happy
    test('three items at 1000 CP with 20 GP gives no problems', () {
      final problems = customBackgroundEquipmentProblems(
        EquipmentOption([EquipmentItem('Item', 3)], 20),
        _priced(1000),
      );

      expect(problems, isEmpty);
    });

    /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-073 -
    ///   "49 and 51 GP": the problem carries the computed copper total.
    /// Path: unhappy (boundary)
    test('gold 49 and gold 51 report the computed total', () {
      expect(
        customBackgroundEquipmentProblems(EquipmentOption([], 49), _priced(0)),
        [const EquipmentValueNotFiftyGold(4900)],
      );
      expect(
        customBackgroundEquipmentProblems(EquipmentOption([], 51), _priced(0)),
        [const EquipmentValueNotFiftyGold(5100)],
      );
    });

    /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-073 -
    ///   "unpriced item": EquipmentItemUnpriced only; the total check is
    ///   skipped.
    /// Path: unhappy (missing content)
    test('an unpriced item is reported and skips the total check', () {
      final problems = customBackgroundEquipmentProblems(
        EquipmentOption([EquipmentItem('Item', 1)], 50),
        _unpriced,
      );

      expect(problems, [const EquipmentItemUnpriced('Item')]);
    });

    /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-073 -
    ///   "unpriced and wrong total": the unpriced item is not counted as
    ///   0 CP, so only the unpriced problem is reported.
    /// Path: unhappy (rule interaction)
    test('an unpriced item with a wrong total reports only the unpriced', () {
      final problems = customBackgroundEquipmentProblems(
        EquipmentOption([
          EquipmentItem('Unpriced', 1),
          EquipmentItem('Priced', 1),
        ], 10),
        (item) => item.name == 'Priced'
            ? EquipmentItemValue(
                copperPieces: 1000,
                isMartialWeaponOrArmor: false,
              )
            : null,
      );

      expect(problems, [const EquipmentItemUnpriced('Unpriced')]);
    });

    /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-073 -
    ///   "Martial item": an excluded item worth 50 GP reports only the
    ///   exclusion.
    /// Path: unhappy (rule interaction)
    test('an excluded item worth 50 GP reports only the exclusion', () {
      final problems = customBackgroundEquipmentProblems(
        EquipmentOption([EquipmentItem('Item', 1)], 0),
        _priced(5000, excluded: true),
      );

      expect(problems, [const EquipmentItemExcluded('Item')]);
    });

    /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-073 -
    ///   "Martial item and wrong total": an excluded but priced item still
    ///   counts toward the total, so both problems appear, exclusion first.
    /// Path: unhappy (rule interaction)
    test(
      'an excluded item with a wrong total reports exclusion then total',
      () {
        final problems = customBackgroundEquipmentProblems(
          EquipmentOption([EquipmentItem('Item', 1)], 10),
          _priced(1000, excluded: true),
        );

        expect(problems, [
          const EquipmentItemExcluded('Item'),
          const EquipmentValueNotFiftyGold(2000),
        ]);
      },
    );

    /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-073 -
    ///   "zero-cost item": an item at 0 CP with gold 50 gives no problems.
    /// Path: unhappy (boundary)
    test('a zero-cost item with gold 50 gives no problems', () {
      final problems = customBackgroundEquipmentProblems(
        EquipmentOption([EquipmentItem('Item', 1)], 50),
        _priced(0),
      );

      expect(problems, isEmpty);
    });

    /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-073 -
    ///   "negative cost": EquipmentItemValue(copperPieces: -1) is a
    ///   constructor ArgumentError.
    /// Path: unhappy (invalid input)
    test('a negative price is rejected by the value constructor', () {
      expect(
        () =>
            EquipmentItemValue(copperPieces: -1, isMartialWeaponOrArmor: false),
        throwsArgumentErrorFor('copperPieces', -1),
      );
    });

    /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-072 -
    ///   "steps 1 to 4": two abilities and one skill are rejected by the
    ///   Background shape (FR-024, FR-027), a General feat is a whole-set
    ///   matter (FR-025) — none of it is this function's (FR-073).
    /// Path: unhappy (rule interaction)
    test('steps 1 to 4 are the Background shape, not this function', () {
      expect(
        () => Background(
          id: BackgroundId('custom'),
          name: 'Custom',
          abilityScores: [Ability.strength, Ability.dexterity],
          feat: BackgroundFeatReference(FeatId('grappler')),
          skillProficiencies: [Skill.athletics, Skill.intimidation],
          toolProficiency: ChoiceToolProficiency('Gaming Set'),
          equipmentOptions: EquipmentOptions(
            a: EquipmentOption([], 50),
            b: EquipmentOption([], 50),
          ),
        ),
        throwsArgumentErrorFor('abilityScores', [
          Ability.strength,
          Ability.dexterity,
        ]),
      );
      expect(
        () => Background(
          id: BackgroundId('custom'),
          name: 'Custom',
          abilityScores: [
            Ability.strength,
            Ability.dexterity,
            Ability.constitution,
          ],
          feat: BackgroundFeatReference(FeatId('grappler')),
          skillProficiencies: [Skill.athletics],
          toolProficiency: ChoiceToolProficiency('Gaming Set'),
          equipmentOptions: EquipmentOptions(
            a: EquipmentOption([], 50),
            b: EquipmentOption([], 50),
          ),
        ),
        throwsArgumentErrorFor('skillProficiencies', [Skill.athletics]),
      );
      // The same option would pass step 5: the equipment rule is not what
      // rejects the steps above (FR-072).
      expect(
        customBackgroundEquipmentProblems(EquipmentOption([], 50), _priced(0)),
        isEmpty,
      );
    });
  });

  /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-073 -
  ///   the sealed problem family, its exhaustive switch, the unmodifiable
  ///   returned list, value equality and the required total.
  /// Path: happy
  group('The problem family', () {
    /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-073 -
    ///   the family is sealed with exactly the three variants, and a switch
    ///   is exhaustive without a default.
    /// Path: happy
    test('a switch over the problem family selects its case', () {
      String describe(CustomBackgroundEquipmentProblem problem) =>
          switch (problem) {
            EquipmentValueNotFiftyGold() => 'value',
            EquipmentItemUnpriced() => 'unpriced',
            EquipmentItemExcluded() => 'excluded',
          };

      expect(describe(const EquipmentValueNotFiftyGold(4900)), 'value');
      expect(describe(const EquipmentItemUnpriced('Item')), 'unpriced');
      expect(describe(const EquipmentItemExcluded('Item')), 'excluded');
    });

    /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-073 -
    ///   the returned list is unmodifiable.
    /// Path: unhappy (immutability)
    test('the returned list is unmodifiable', () {
      final problems = customBackgroundEquipmentProblems(
        EquipmentOption([], 49),
        _priced(0),
      );

      expect(
        () => problems.add(const EquipmentValueNotFiftyGold(4900)),
        throwsUnsupportedError,
      );
    });

    /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-073 -
    ///   value equality of the three variants, and cross-type inequality.
    /// Path: happy
    test('the variants compare by their data', () {
      expect(
        const EquipmentValueNotFiftyGold(4900),
        const EquipmentValueNotFiftyGold(4900),
      );
      expect(
        const EquipmentItemUnpriced('Item'),
        const EquipmentItemUnpriced('Item'),
      );
      expect(
        const EquipmentItemExcluded('Item'),
        const EquipmentItemExcluded('Item'),
      );
      expect(
        operatorEquals(
          const EquipmentItemUnpriced('Item'),
          const EquipmentItemExcluded('Item'),
        ),
        isFalse,
      );
      expect(
        const EquipmentValueNotFiftyGold(4900).hashCode,
        const EquipmentValueNotFiftyGold(4900).hashCode,
      );
      expect(
        const EquipmentItemUnpriced('Item').hashCode,
        const EquipmentItemUnpriced('Item').hashCode,
      );
      expect(
        const EquipmentItemExcluded('Item').hashCode,
        const EquipmentItemExcluded('Item').hashCode,
      );
      expect(
        operatorEquals(const EquipmentItemUnpriced('Item'), 'Item'),
        isFalse,
      );
      expect(
        const EquipmentValueNotFiftyGold(4900).hashCode,
        const EquipmentValueNotFiftyGold(4900).hashCode,
      );
      expect(
        operatorEquals(
          const EquipmentValueNotFiftyGold(4900),
          const EquipmentValueNotFiftyGold(5100),
        ),
        isFalse,
      );
      expect(
        operatorEquals(
          const EquipmentItemUnpriced('A'),
          const EquipmentItemUnpriced('B'),
        ),
        isFalse,
      );
      expect(
        operatorEquals(
          const EquipmentItemExcluded('A'),
          const EquipmentItemExcluded('B'),
        ),
        isFalse,
      );
    });

    /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-073 -
    ///   the required total is a public constant (50 GP).
    /// Path: happy
    test('the required total is 5000 copper pieces', () {
      expect(EquipmentValueNotFiftyGold.requiredCopperPieces, 5000);
    });

    /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-073 -
    ///   toString is a debugging form.
    /// Path: happy
    test('the problems print their parts', () {
      expect(
        const EquipmentValueNotFiftyGold(4900).toString(),
        'EquipmentValueNotFiftyGold(4900)',
      );
      expect(
        const EquipmentItemUnpriced('Item').toString(),
        'EquipmentItemUnpriced(Item)',
      );
      expect(
        const EquipmentItemExcluded('Item').toString(),
        'EquipmentItemExcluded(Item)',
      );
    });
  });
}
