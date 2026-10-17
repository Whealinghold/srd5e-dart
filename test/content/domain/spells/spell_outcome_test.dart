import 'package:srd5e/src/content/domain/condition_kind.dart';
import 'package:srd5e/src/content/domain/damage_type.dart';
import 'package:srd5e/src/content/domain/duration_unit.dart';
import 'package:srd5e/src/content/domain/spells/spell_effect_part.dart';
import 'package:srd5e/src/content/domain/spells/spell_outcome.dart';
import 'package:srd5e/src/content/domain/spells/spell_scaling.dart';
import 'package:srd5e/src/shared_kernel/ability/ability.dart';
import 'package:srd5e/src/shared_kernel/dice/dice_expression.dart';
import 'package:srd5e/src/shared_kernel/dice/die.dart';
import 'package:test/test.dart';

import '../../../support/argument_error_matcher.dart';

/// The label a `switch` over the sealed [SpellOutcome] family returns, with
/// no default branch.
String outcomeLabel(SpellOutcome outcome) => switch (outcome) {
  SpellDealsDamage() => 'damage',
  SpellRestoresHitPoints() => 'healing',
  SpellGrantsTemporaryHitPoints() => 'temporary',
  SpellAppliesCondition() => 'condition',
};

/// The label a `switch` over the sealed [DamageTypeSelection] family
/// returns, with no default branch.
String selectionLabel(DamageTypeSelection selection) => switch (selection) {
  FixedDamageType() => 'fixed',
  ChosenDamageType() => 'chosen',
};

SpellDealsDamage _damage([DamageType type = DamageType.fire]) =>
    SpellDealsDamage(
      ScalableAmount(RolledSpellAmount(DiceExpression(2, Die.d6))),
      FixedDamageType(type),
      ModifierAddition.none,
    );

void main() {
  /// Requirement: doc/specs/spell-effect-data.md FR-028, FR-047 - the four sealed outcome
  ///   shapes; any of the fifteen conditions (SRD 5.2.1, p. 106;
  ///   "Condition", p. 179).
  /// Path: happy
  group('SpellOutcome', () {
    /// Requirement: doc/specs/spell-effect-data.md FR-047 - SpellOutcome is
    ///   sealed with exactly the four shapes (SRD 5.2.1, "Effects", p. 106).
    /// Path: happy
    test('the four outcomes are exhaustive and distinct', () {
      final outcomes = <SpellOutcome>[
        _damage(),
        SpellRestoresHitPoints(
          ScalableAmount(RolledSpellAmount(DiceExpression(2, Die.d8))),
          ModifierAddition.spellcastingAbilityModifier,
        ),
        SpellGrantsTemporaryHitPoints(
          ScalableAmount(FixedSpellAmount(5)),
          ModifierAddition.none,
        ),
        const SpellAppliesCondition(
          ConditionKind.poisoned,
          UntilNextTurnBoundary(TurnOwner.caster, TurnBoundary.end),
        ),
      ];
      expect(outcomes.map(outcomeLabel).toSet(), {
        'damage',
        'healing',
        'temporary',
        'condition',
      });
      expect(outcomes[0], isNot(outcomes[1]));
    });

    /// Requirement: doc/specs/spell-effect-data.md FR-028 - any of the
    ///   fifteen ConditionKind values is accepted (SRD 5.2.1, "Condition",
    ///   p. 179).
    /// Path: happy
    test('all fifteen condition kinds are accepted', () {
      for (final kind in ConditionKind.values) {
        final outcome = SpellAppliesCondition(kind, const ForSpellDuration());
        expect(outcome.kind, kind);
      }
    });
  });

  /// Requirement: doc/specs/spell-effect-data.md FR-027, FR-044 - a fixed type or a
  ///   choice of at least two ("Chromatic Orb", SRD 5.2.1, p. 115).
  /// Path: unhappy (boundary)
  group('DamageTypeSelection', () {
    /// Requirement: doc/specs/spell-effect-data.md FR-044 - fixed or a
    ///   closed choice (Chromatic Orb, SRD 5.2.1, p. 115); exhaustive.
    /// Path: happy
    test('fixed and chosen are the two variants, exhaustive', () {
      expect(selectionLabel(const FixedDamageType(DamageType.acid)), 'fixed');
      expect(
        selectionLabel(
          ChosenDamageType(const {
            DamageType.acid,
            DamageType.cold,
            DamageType.fire,
            DamageType.lightning,
            DamageType.poison,
            DamageType.thunder,
          }),
        ),
        'chosen',
      );
    });

    /// Requirement: doc/specs/spell-effect-data.md FR-027 - a chosen set
    ///   holds at least 2 distinct types; one type is a FixedDamageType
    ///   (SRD 5.2.1, p. 115).
    /// Path: unhappy (boundary)
    test('a one-element chosen set is rejected', () {
      expect(
        () => ChosenDamageType(const {DamageType.fire}),
        throwsArgumentErrorFor('types', const {DamageType.fire}),
      );
    });

    /// Requirement: doc/specs/spell-effect-data.md FR-008 - set-valued
    ///   fields are order-insensitive in equality (architecture.md §3).
    /// Path: happy
    test('chosen sets compare order-insensitively', () {
      final a = ChosenDamageType(const {DamageType.fire, DamageType.cold});
      final b = ChosenDamageType(const {DamageType.cold, DamageType.fire});
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });

  /// Requirement: doc/specs/spell-effect-data.md FR-025 - a fixed amount is at least 1;
  ///   a rolled amount inherits the dice validation ("Heal",
  ///   SRD 5.2.1, p. 139).
  /// Path: unhappy (boundary)
  group('Amount validation', () {
    /// Requirement: doc/specs/spell-effect-data.md FR-025 - a fixed amount
    ///   is at least 1 (Heal's 70, SRD 5.2.1, p. 139).
    /// Path: unhappy (boundary)
    test('FixedSpellAmount rejects 0 and accepts 1', () {
      expect(() => FixedSpellAmount(0), throwsArgumentErrorFor('value', 0));
      expect(FixedSpellAmount(1).value, 1);
      expect(FixedSpellAmount(70).value, 70);
    });

    /// Requirement: doc/specs/spell-effect-data.md FR-025 - a rolled amount
    ///   inherits the DiceExpression validation (count at least 1).
    /// Path: unhappy (invalid input)
    test('a rolled amount inherits the dice validation', () {
      expect(
        () => RolledSpellAmount(DiceExpression(0, Die.d6)),
        throwsArgumentErrorFor('count', 0),
      );
      expect(RolledSpellAmount(DiceExpression(1, Die.d6)).dice.count, 1);
    });
  });

  /// Requirement: doc/specs/spell-effect-data.md FR-046 - the three printed duration
  ///   shapes, amount at least 1 (SRD 5.2.1, pp. 106, 141, 158).
  /// Path: unhappy (boundary)
  group('ConditionDuration', () {
    /// Requirement: doc/specs/spell-effect-data.md FR-046 - the three
    ///   printed shapes; amount at least 1 (SRD 5.2.1, pp. 106, 141, 158).
    /// Path: unhappy (boundary)
    test('the three variants, with amount 0 rejected', () {
      expect(
        () => TimedConditionDuration(0, DurationUnit.rounds),
        throwsArgumentErrorFor('amount', 0),
      );
      final durations = <ConditionDuration>[
        const ForSpellDuration(),
        TimedConditionDuration(1, DurationUnit.minutes),
        const UntilNextTurnBoundary(TurnOwner.target, TurnBoundary.start),
      ];
      expect(durations[0], isNot(durations[1]));
      expect((durations[2] as UntilNextTurnBoundary).owner, TurnOwner.target);
      expect(
        (durations[2] as UntilNextTurnBoundary).boundary,
        TurnBoundary.start,
      );
      expect(durations[1], TimedConditionDuration(1, DurationUnit.minutes));
    });
  });

  /// Requirement: doc/specs/spell-effect-data.md FR-026, FR-029, FR-042, FR-043 - the
  ///   three resolutions, their non-empty lists, the half-damage rule
  ///   and instance bases (SRD 5.2.1, p. 106; "Half Damage", p. 16).
  /// Path: unhappy (empty and minimal)
  group('PartResolution', () {
    /// Requirement: doc/specs/spell-effect-data.md FR-026 - onHit, onFailure
    ///   and outcomes are never empty; onMiss MAY be empty.
    /// Path: unhappy (empty and minimal)
    test(
      'empty onHit, onFailure and outcomes throw; empty onMiss is valid',
      () {
        expect(
          () => AttackRollResolution(SpellAttackKind.ranged, const []),
          throwsArgumentErrorFor('onHit', const <SpellOutcome>[]),
        );
        expect(
          () => SavingThrowResolution(
            Ability.dexterity,
            const [],
            const NothingOnSuccess(),
          ),
          throwsArgumentErrorFor('onFailure', const <SpellOutcome>[]),
        );
        expect(
          () => AutomaticResolution(const []),
          throwsArgumentErrorFor('outcomes', const <SpellOutcome>[]),
        );
        final attack = AttackRollResolution(SpellAttackKind.ranged, [
          _damage(),
        ]);
        expect(attack.onMiss, isEmpty);
        expect(attack.kind, SpellAttackKind.ranged);
      },
    );

    /// Requirement: doc/specs/spell-effect-data.md FR-042 - the three
    ///   resolutions: attack rolls and saving throws are the SRD's hooks,
    ///   AutomaticResolution the no-roll shape ("Effects", p. 106).
    /// Path: happy
    test('the three resolutions are distinct value objects', () {
      final attack = AttackRollResolution(SpellAttackKind.melee, [_damage()]);
      final save = SavingThrowResolution(Ability.constitution, [
        _damage(DamageType.necrotic),
      ], const HalfDamageOnSuccess());
      final automatic = AutomaticResolution([_damage()]);
      expect(attack, isNot(save));
      expect(attack, AttackRollResolution(SpellAttackKind.melee, [_damage()]));
      expect(automatic, AutomaticResolution([_damage()]));
    });

    /// Requirement: doc/specs/spell-effect-data.md FR-043 -
    ///   HalfDamageOnSuccess requires a SpellDealsDamage on the failure side
    ///   ("Half Damage", SRD 5.2.1, p. 16).
    /// Path: unhappy (invalid input)
    test('HalfDamageOnSuccess with no damage outcome throws', () {
      expect(
        () => SavingThrowResolution(Ability.wisdom, [
          const SpellAppliesCondition(
            ConditionKind.paralyzed,
            ForSpellDuration(),
          ),
        ], const HalfDamageOnSuccess()),
        throwsA(
          isA<ArgumentError>().having((e) => e.name, 'name', 'onSuccess'),
        ),
      );
      final valid = SavingThrowResolution(Ability.dexterity, [
        _damage(),
      ], const HalfDamageOnSuccess());
      expect(valid.onSuccess, const HalfDamageOnSuccess());
      // One damage outcome among several is enough: at least one, not only
      // damage outcomes.
      final mixed = SavingThrowResolution(Ability.dexterity, [
        _damage(),
        const SpellAppliesCondition(
          ConditionKind.paralyzed,
          ForSpellDuration(),
        ),
      ], const HalfDamageOnSuccess());
      expect(mixed.onFailure, hasLength(2));
    });

    /// Requirement: doc/specs/spell-effect-data.md FR-029 - PartInstances
    ///   has a base of at least 1; 0 and negative throw ("Eldritch Blast",
    ///   SRD 5.2.1, p. 127).
    /// Path: unhappy (boundary)
    test('PartInstances rejects a base below 1', () {
      expect(() => PartInstances(0), throwsArgumentErrorFor('base', 0));
      expect(PartInstances(1).base, 1);
      expect(PartInstances(3).base, 3);
    });

    /// Requirement: doc/specs/spell-effect-data.md FR-042 - a part holds one
    ///   resolution and its instances ("Flame Strike" p. 132: two outcomes
    ///   of one part).
    /// Path: happy
    test('a part holds one resolution and its instances', () {
      final part = SpellEffectPart(
        AutomaticResolution([
          _damage(DamageType.fire),
          _damage(DamageType.radiant),
        ]),
        PartInstances(1),
      );
      expect((part.resolution as AutomaticResolution).outcomes, hasLength(2));
      expect(part.instances.base, 1);
      expect(
        part,
        isNot(
          SpellEffectPart(AutomaticResolution([_damage()]), PartInstances(1)),
        ),
      );
    });
  });
}
