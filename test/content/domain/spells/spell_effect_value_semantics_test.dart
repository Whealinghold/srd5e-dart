import 'package:srd5e/src/content/domain/condition_kind.dart';
import 'package:srd5e/src/content/domain/creature_type.dart';
import 'package:srd5e/src/content/domain/damage_type.dart';
import 'package:srd5e/src/content/domain/duration_unit.dart';
import 'package:srd5e/src/content/domain/spells/spell_effect_facts.dart';
import 'package:srd5e/src/content/domain/spells/spell_effect_model.dart';
import 'package:srd5e/src/content/domain/spells/spell_effect_part.dart';
import 'package:srd5e/src/content/domain/spells/spell_outcome.dart';
import 'package:srd5e/src/content/domain/spells/spell_scaling.dart';
import 'package:srd5e/src/content/domain/spells/spell_targeting.dart';
import 'package:srd5e/src/content/domain/spells/zone_facts.dart';
import 'package:srd5e/src/shared_kernel/ability/ability.dart';
import 'package:srd5e/src/shared_kernel/dice/dice_expression.dart';
import 'package:srd5e/src/shared_kernel/dice/die.dart';
import 'package:test/test.dart';

import '../../../support/argument_error_matcher.dart';

const _stationary = StationaryZone();

SpellEffectPart _attackDamagePart() => SpellEffectPart(
  AttackRollResolution(SpellAttackKind.ranged, [
    SpellDealsDamage(
      ScalableAmount(RolledSpellAmount(DiceExpression(1, Die.d10))),
      const FixedDamageType(DamageType.fire),
      ModifierAddition.none,
    ),
  ]),
  PartInstances(1),
);

SpellEffectPart _saveDamagePart() => SpellEffectPart(
  SavingThrowResolution(Ability.dexterity, [
    SpellDealsDamage(
      ScalableAmount(RolledSpellAmount(DiceExpression(8, Die.d6))),
      const FixedDamageType(DamageType.fire),
      ModifierAddition.none,
    ),
  ], const HalfDamageOnSuccess()),
  PartInstances(1),
);

SpellEffectPart _conditionPart() => SpellEffectPart(
  SavingThrowResolution(Ability.wisdom, [
    const SpellAppliesCondition(ConditionKind.paralyzed, ForSpellDuration()),
  ], const NothingOnSuccess()),
  PartInstances(1),
);

CharacterLevelTable<SpellAmount> _cantripTable() =>
    CharacterLevelTable<SpellAmount>([
      (1, RolledSpellAmount(DiceExpression(1, Die.d10))),
      (5, RolledSpellAmount(DiceExpression(2, Die.d10))),
      (11, RolledSpellAmount(DiceExpression(3, Die.d10))),
      (17, RolledSpellAmount(DiceExpression(4, Die.d10))),
    ]);

CharacterLevelTable<int> _beamTable() =>
    CharacterLevelTable<int>([(1, 1), (5, 2), (11, 3), (17, 4)]);

void main() {
  /// Requirement: doc/specs/spell-effect-data.md FR-008 - every model type
  ///   has value equality with a consistent hash code, set-valued fields
  ///   order-insensitive; the printed form is its debugging view
  ///   (architecture.md §6).
  /// Path: happy
  group('target count value forms', () {
    /// Requirement: doc/specs/spell-effect-data.md FR-008, FR-012 - the
    ///   counted shapes compare by value and print their parts.
    /// Path: happy
    test('ExactlyTargets compares by value and prints its parts', () {
      final a = ExactlyTargets(1, scaling: PerSlotLevelCount(2, 1));
      final b = ExactlyTargets(1, scaling: PerSlotLevelCount(2, 1));
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(ExactlyTargets(1)));
      expect(a, isNot(UpToTargets(1, scaling: PerSlotLevelCount(2, 1))));
      expect(
        a.toString(),
        'ExactlyTargets(1, scaling: PerSlotLevelCount(aboveLevel: 2, extra: 1))',
      );
    });

    /// Requirement: doc/specs/spell-effect-data.md FR-008, FR-012 - the
    ///   up-to shape compares by value and prints its parts.
    /// Path: happy
    test('UpToTargets compares by value and prints its parts', () {
      final a = UpToTargets(3);
      final b = UpToTargets(3);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(UpToTargets(4)));
      expect(a, isNot(ExactlyTargets(3)));
      expect(a.toString(), 'UpToTargets(3, scaling: NoCountScaling())');
    });

    /// Requirement: doc/specs/spell-effect-data.md FR-008, FR-012 - the
    ///   per-instance shape is the single equal instance.
    /// Path: happy
    test('TargetsByInstance is a single equal shape and prints its form', () {
      const a = TargetsByInstance();
      const b = TargetsByInstance();
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(ExactlyTargets(1)));
      expect(a.toString(), 'TargetsByInstance()');
    });
  });

  /// Requirement: doc/specs/spell-effect-data.md FR-008 - the restriction
  ///   and area-shape types compare by value with order-insensitive sets.
  /// Path: happy
  group('restriction and area shape value forms', () {
    /// Requirement: doc/specs/spell-effect-data.md FR-008, FR-015 - the
    ///   unrestricted shape is single; the listed shape is
    ///   order-insensitive.
    /// Path: happy
    test('creature-type restrictions compare by value', () {
      const any = AnyCreatureType();
      expect(any, const AnyCreatureType());
      expect(any.hashCode, const AnyCreatureType().hashCode);
      expect(any.toString(), 'AnyCreatureType()');
      expect(any, isNot(OnlyCreatureTypes({CreatureType.humanoid})));

      final only = OnlyCreatureTypes({CreatureType.humanoid});
      final same = OnlyCreatureTypes({CreatureType.humanoid});
      final larger = OnlyCreatureTypes({
        CreatureType.humanoid,
        CreatureType.monstrosity,
      });
      expect(only, same);
      expect(only.hashCode, same.hashCode);
      expect(
        OnlyCreatureTypes({CreatureType.beast, CreatureType.humanoid}),
        OnlyCreatureTypes({CreatureType.humanoid, CreatureType.beast}),
      );
      expect(only, isNot(larger));
      expect(only.toString(), 'OnlyCreatureTypes({Humanoid})');
    });

    /// Requirement: doc/specs/spell-effect-data.md FR-008, FR-013 - the six
    ///   area shapes compare by value over their dimensions.
    /// Path: happy
    test('the six area shapes compare by value and print their parts', () {
      final shapes = <AreaShape>[
        ConeArea(15),
        CubeArea(10),
        CylinderArea(10, 20),
        EmanationArea(15),
        LineArea(60, 5),
        SphereArea(20),
      ];
      for (final shape in shapes) {
        final same = switch (shape) {
          ConeArea(:final lengthFeet) => ConeArea(lengthFeet),
          CubeArea(:final sideFeet) => CubeArea(sideFeet),
          CylinderArea(:final radiusFeet, :final heightFeet) => CylinderArea(
            radiusFeet,
            heightFeet,
          ),
          EmanationArea(:final distanceFeet) => EmanationArea(distanceFeet),
          LineArea(:final lengthFeet, :final widthFeet) => LineArea(
            lengthFeet,
            widthFeet,
          ),
          SphereArea(:final radiusFeet) => SphereArea(radiusFeet),
        };
        expect(shape, same, reason: '$shape compares equal to an equal one');
        expect(shape.hashCode, same.hashCode);
        expect(shape.toString(), isNotEmpty);
      }
      expect(ConeArea(15), isNot(ConeArea(30)));
      expect(CubeArea(10), isNot(ConeArea(10)));
      expect(CylinderArea(10, 20), isNot(CylinderArea(20, 10)));
      expect(EmanationArea(15), isNot(EmanationArea(30)));
      expect(LineArea(60, 5), isNot(LineArea(5, 60)));
      expect(LineArea(60, 5), isNot(SphereArea(60)));
      expect(SphereArea(20), isNot(SphereArea(15)));
    });
  });

  /// Requirement: doc/specs/spell-effect-data.md FR-008, FR-010 - the three
  ///   targeting shapes compare by value over their fields.
  /// Path: happy
  group('targeting value forms', () {
    /// Requirement: doc/specs/spell-effect-data.md FR-008, FR-010 - the
    ///   chosen, self and area shapes compare by value and print their
    ///   parts.
    /// Path: happy
    test('the targeting shapes compare by value and print their parts', () {
      final chosen = TargetsChosen(
        TargetSubject.creature,
        ExactlyTargets(1),
        OnlyCreatureTypes({CreatureType.humanoid}),
        selfPolicy: SelfTargetPolicy.excludesCaster,
      );
      final sameChosen = TargetsChosen(
        TargetSubject.creature,
        ExactlyTargets(1),
        OnlyCreatureTypes({CreatureType.humanoid}),
        selfPolicy: SelfTargetPolicy.excludesCaster,
      );
      expect(chosen, sameChosen);
      expect(chosen.hashCode, sameChosen.hashCode);
      expect(
        chosen,
        isNot(
          TargetsChosen(
            TargetSubject.creature,
            ExactlyTargets(1),
            OnlyCreatureTypes({CreatureType.humanoid}),
          ),
        ),
        reason: 'the self policy is part of the value',
      );
      expect(
        chosen.toString(),
        'TargetsChosen(TargetSubject.creature, ExactlyTargets(1, scaling: '
        'NoCountScaling()))',
      );

      const self = TargetsSelf();
      expect(self, const TargetsSelf());
      expect(self.hashCode, const TargetsSelf().hashCode);
      expect(self, isNot(chosen));
      expect(self.toString(), 'TargetsSelf()');

      final area = TargetsInArea(
        SphereArea(20),
        TargetSubject.creature,
        const AnyCreatureType(),
      );
      final sameArea = TargetsInArea(
        SphereArea(20),
        TargetSubject.creature,
        const AnyCreatureType(),
      );
      expect(area, sameArea);
      expect(area.hashCode, sameArea.hashCode);
      expect(
        area,
        isNot(
          TargetsInArea(
            SphereArea(20),
            TargetSubject.creatureOrObject,
            const AnyCreatureType(),
          ),
        ),
      );
      expect(area, isNot(const TargetsSelf()));
      expect(
        area.toString(),
        'TargetsInArea(SphereArea(20), TargetSubject.creature)',
      );
    });
  });

  /// Requirement: doc/specs/spell-effect-data.md FR-008, FR-047 - the four
  ///   outcomes, their damage-type selections and condition durations
  ///   compare by value and print their parts.
  /// Path: happy
  group('outcome value forms', () {
    /// Requirement: doc/specs/spell-effect-data.md FR-008, FR-044 - the
    ///   fixed selection compares by value; the chosen selection is
    ///   order-insensitive.
    /// Path: happy
    test('damage type selections compare by value and print', () {
      const fire = FixedDamageType(DamageType.fire);
      expect(fire, const FixedDamageType(DamageType.fire));
      expect(fire.hashCode, const FixedDamageType(DamageType.fire).hashCode);
      expect(fire, isNot(const FixedDamageType(DamageType.cold)));
      expect(fire.toString(), 'FixedDamageType(Fire)');

      final chosen = ChosenDamageType({DamageType.acid, DamageType.cold});
      expect(chosen, ChosenDamageType({DamageType.cold, DamageType.acid}));
      expect(
        chosen.hashCode,
        ChosenDamageType({DamageType.cold, DamageType.acid}).hashCode,
      );
      expect(
        chosen,
        isNot(ChosenDamageType({DamageType.acid, DamageType.fire})),
      );
      expect(chosen, isNot(fire));
      expect(chosen.toString(), 'ChosenDamageType({Acid, Cold})');
    });

    /// Requirement: doc/specs/spell-effect-data.md FR-008, FR-046 - the
    ///   three condition durations compare by value and print their
    ///   parts.
    /// Path: happy
    test('condition durations compare by value and print their parts', () {
      const forDuration = ForSpellDuration();
      expect(forDuration, const ForSpellDuration());
      expect(forDuration.hashCode, const ForSpellDuration().hashCode);
      expect(
        forDuration,
        isNot(TimedConditionDuration(1, DurationUnit.rounds)),
      );
      expect(forDuration.toString(), 'ForSpellDuration()');

      final timed = TimedConditionDuration(1, DurationUnit.rounds);
      expect(timed, TimedConditionDuration(1, DurationUnit.rounds));
      expect(
        timed.hashCode,
        TimedConditionDuration(1, DurationUnit.rounds).hashCode,
      );
      expect(timed, isNot(TimedConditionDuration(2, DurationUnit.rounds)));
      expect(timed, isNot(forDuration));
      expect(timed.toString(), 'TimedConditionDuration(1, rounds)');

      const boundary = UntilNextTurnBoundary(
        TurnOwner.caster,
        TurnBoundary.end,
      );
      expect(
        boundary,
        const UntilNextTurnBoundary(TurnOwner.caster, TurnBoundary.end),
      );
      expect(
        boundary.hashCode,
        const UntilNextTurnBoundary(
          TurnOwner.caster,
          TurnBoundary.end,
        ).hashCode,
      );
      expect(
        boundary,
        isNot(const UntilNextTurnBoundary(TurnOwner.target, TurnBoundary.end)),
      );
      expect(
        boundary,
        isNot(
          const UntilNextTurnBoundary(TurnOwner.caster, TurnBoundary.start),
        ),
      );
      expect(
        boundary.toString(),
        'UntilNextTurnBoundary(TurnOwner.caster, TurnBoundary.end)',
      );
    });

    /// Requirement: doc/specs/spell-effect-data.md FR-008, FR-047 - the
    ///   four outcomes compare by value over their fields and print their
    ///   amount.
    /// Path: happy
    test('the outcomes compare by value and print their parts', () {
      final damage = SpellDealsDamage(
        ScalableAmount(RolledSpellAmount(DiceExpression(8, Die.d6))),
        const FixedDamageType(DamageType.fire),
        ModifierAddition.none,
      );
      final sameDamage = SpellDealsDamage(
        ScalableAmount(RolledSpellAmount(DiceExpression(8, Die.d6))),
        const FixedDamageType(DamageType.fire),
        ModifierAddition.none,
      );
      expect(damage, sameDamage);
      expect(damage.hashCode, sameDamage.hashCode);
      expect(
        damage,
        isNot(
          SpellDealsDamage(
            ScalableAmount(RolledSpellAmount(DiceExpression(8, Die.d6))),
            const FixedDamageType(DamageType.fire),
            ModifierAddition.spellcastingAbilityModifier,
          ),
        ),
      );
      expect(
        damage.toString(),
        'SpellDealsDamage(ScalableAmount(RolledSpellAmount(8d6), scaling: '
        'NoAmountScaling()))',
      );

      final healing = SpellRestoresHitPoints(
        ScalableAmount(RolledSpellAmount(DiceExpression(2, Die.d8))),
        ModifierAddition.spellcastingAbilityModifier,
      );
      expect(
        healing,
        SpellRestoresHitPoints(
          ScalableAmount(RolledSpellAmount(DiceExpression(2, Die.d8))),
          ModifierAddition.spellcastingAbilityModifier,
        ),
      );
      expect(
        healing.hashCode,
        SpellRestoresHitPoints(
          ScalableAmount(RolledSpellAmount(DiceExpression(2, Die.d8))),
          ModifierAddition.spellcastingAbilityModifier,
        ).hashCode,
      );
      expect(
        healing.toString(),
        'SpellRestoresHitPoints(ScalableAmount(RolledSpellAmount(2d8), '
        'scaling: NoAmountScaling()))',
      );

      final temp = SpellGrantsTemporaryHitPoints(
        ScalableAmount(FixedSpellAmount(5)),
        ModifierAddition.none,
      );
      expect(
        temp,
        SpellGrantsTemporaryHitPoints(
          ScalableAmount(FixedSpellAmount(5)),
          ModifierAddition.none,
        ),
      );
      expect(
        temp.hashCode,
        SpellGrantsTemporaryHitPoints(
          ScalableAmount(FixedSpellAmount(5)),
          ModifierAddition.none,
        ).hashCode,
      );
      expect(
        temp,
        isNot(
          SpellGrantsTemporaryHitPoints(
            ScalableAmount(FixedSpellAmount(5)),
            ModifierAddition.spellcastingAbilityModifier,
          ),
        ),
      );
      expect(temp, isNot(healing));
      expect(
        temp.toString(),
        'SpellGrantsTemporaryHitPoints(ScalableAmount(FixedSpellAmount(5), '
        'scaling: NoAmountScaling()))',
      );

      const condition = SpellAppliesCondition(
        ConditionKind.poisoned,
        ForSpellDuration(),
      );
      expect(
        condition,
        const SpellAppliesCondition(ConditionKind.poisoned, ForSpellDuration()),
      );
      expect(
        condition.hashCode,
        const SpellAppliesCondition(
          ConditionKind.poisoned,
          ForSpellDuration(),
        ).hashCode,
      );
      expect(
        condition,
        isNot(
          const SpellAppliesCondition(
            ConditionKind.blinded,
            ForSpellDuration(),
          ),
        ),
      );
      expect(condition, isNot(const ForSpellDuration()));
      expect(condition.toString(), 'SpellAppliesCondition(Poisoned)');
    });
  });

  /// Requirement: doc/specs/spell-effect-data.md FR-008, FR-042 - the
  ///   resolution types compare by value over their outcome lists.
  /// Path: happy
  group('resolution value forms', () {
    /// Requirement: doc/specs/spell-effect-data.md FR-008, FR-042 - an
    ///   attack resolution compares by value over kind, hit and miss.
    /// Path: happy
    test('AttackRollResolution compares by value and prints its parts', () {
      SpellDealsDamage hit() => SpellDealsDamage(
        ScalableAmount(RolledSpellAmount(DiceExpression(1, Die.d10))),
        const FixedDamageType(DamageType.fire),
        ModifierAddition.none,
      );
      const miss = SpellAppliesCondition(
        ConditionKind.blinded,
        UntilNextTurnBoundary(TurnOwner.caster, TurnBoundary.end),
      );
      final a = AttackRollResolution(SpellAttackKind.ranged, [hit()], [miss]);
      final b = AttackRollResolution(SpellAttackKind.ranged, [hit()], [miss]);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(AttackRollResolution(SpellAttackKind.melee, [hit()])));
      expect(a, isNot(AttackRollResolution(SpellAttackKind.ranged, [hit()])));
      expect(a.toString(), 'AttackRollResolution(SpellAttackKind.ranged)');
    });

    /// Requirement: doc/specs/spell-effect-data.md FR-008, FR-042, FR-043 -
    ///   a saving-throw resolution compares by value over ability,
    ///   failures and the success effect.
    /// Path: happy
    test('SavingThrowResolution compares by value and prints its parts', () {
      SavingThrowResolution build(SuccessEffect success) =>
          SavingThrowResolution(Ability.constitution, [
            SpellDealsDamage(
              ScalableAmount(RolledSpellAmount(DiceExpression(8, Die.d6))),
              const FixedDamageType(DamageType.poison),
              ModifierAddition.none,
            ),
          ], success);
      final a = build(const HalfDamageOnSuccess());
      final b = build(const HalfDamageOnSuccess());
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(build(const NothingOnSuccess())));
      expect(
        a,
        isNot(
          SavingThrowResolution(Ability.dexterity, a.onFailure, a.onSuccess),
        ),
      );
      expect(a.toString(), 'SavingThrowResolution(Ability.constitution)');

      const nothing = NothingOnSuccess();
      expect(nothing, const NothingOnSuccess());
      expect(nothing.hashCode, const NothingOnSuccess().hashCode);
      expect(nothing, isNot(const HalfDamageOnSuccess()));
      expect(nothing.toString(), 'NothingOnSuccess()');
      const half = HalfDamageOnSuccess();
      expect(half, const HalfDamageOnSuccess());
      expect(half.hashCode, const HalfDamageOnSuccess().hashCode);
      expect(half.toString(), 'HalfDamageOnSuccess()');
    });

    /// Requirement: doc/specs/spell-effect-data.md FR-008, FR-042 - an
    ///   automatic resolution compares by value over its outcomes.
    /// Path: happy
    test('AutomaticResolution compares by value and prints its size', () {
      AutomaticResolution build() => AutomaticResolution([
        SpellRestoresHitPoints(
          ScalableAmount(RolledSpellAmount(DiceExpression(2, Die.d8))),
          ModifierAddition.spellcastingAbilityModifier,
        ),
      ]);
      final a = build();
      expect(a, build());
      expect(a.hashCode, build().hashCode);
      expect(
        a,
        isNot(
          AutomaticResolution([
            SpellDealsDamage(
              ScalableAmount(RolledSpellAmount(DiceExpression(1, Die.d6))),
              const FixedDamageType(DamageType.fire),
              ModifierAddition.none,
            ),
          ]),
        ),
      );
      expect(a, isNot(PartInstances(1)));
      expect(a.toString(), 'AutomaticResolution(1)');
    });

    /// Requirement: doc/specs/spell-effect-data.md FR-008, FR-021, FR-042 -
    ///   a part and its instances compare by value and print their parts.
    /// Path: happy
    test('SpellEffectPart and PartInstances compare by value', () {
      final part = _attackDamagePart();
      expect(part, _attackDamagePart());
      expect(part.hashCode, _attackDamagePart().hashCode);
      expect(part, isNot(SpellEffectPart(part.resolution, PartInstances(2))));
      expect(part, isNot(_conditionPart()));
      expect(
        part.toString(),
        'SpellEffectPart(AttackRollResolution(SpellAttackKind.ranged))',
      );

      final instances = PartInstances(3);
      expect(instances, PartInstances(3));
      expect(instances.hashCode, PartInstances(3).hashCode);
      expect(
        instances,
        isNot(PartInstances(3, scaling: PerSlotLevelCount(1, 1))),
      );
      expect(instances, isNot(PartInstances(2)));
      expect(
        instances.toString(),
        'PartInstances(3, scaling: NoCountScaling())',
      );
    });
  });

  /// Requirement: doc/specs/spell-effect-data.md FR-008, FR-041 - the
  ///   count and amount scalings compare by value; the queries answer from
  ///   the printed tables and per-slot growth (SRD 5.2.1,
  ///   "Using a Higher-Level Spell Slot", pp. 104-105).
  /// Path: happy
  group('scaling value forms and queries', () {
    /// Requirement: doc/specs/spell-effect-data.md FR-008, FR-016, FR-020 -
    ///   the three amount scalings compare by value and print their parts.
    /// Path: happy
    test('the amount scalings compare by value and print their parts', () {
      const none = NoAmountScaling();
      expect(none, const NoAmountScaling());
      expect(none.hashCode, const NoAmountScaling().hashCode);
      expect(none, isNot(PerSlotLevelAmount(1, AmountStep(extraFlat: 5))));
      expect(none.toString(), 'NoAmountScaling()');

      final perSlot = PerSlotLevelAmount(3, AmountStep(extraDice: 1));
      expect(perSlot, PerSlotLevelAmount(3, AmountStep(extraDice: 1)));
      expect(
        perSlot.hashCode,
        PerSlotLevelAmount(3, AmountStep(extraDice: 1)).hashCode,
      );
      expect(perSlot, isNot(PerSlotLevelAmount(2, AmountStep(extraDice: 1))));
      expect(perSlot, isNot(PerSlotLevelAmount(3, AmountStep(extraFlat: 5))));
      expect(
        perSlot.toString(),
        'PerSlotLevelAmount(aboveLevel: 3, step: '
        'AmountStep(extraDice: 1, extraFlat: 0))',
      );

      final byLevel = ByCharacterLevelAmount(_cantripTable());
      expect(byLevel, ByCharacterLevelAmount(_cantripTable()));
      expect(
        byLevel.hashCode,
        ByCharacterLevelAmount(_cantripTable()).hashCode,
      );
      expect(byLevel, isNot(ByCharacterLevelCount(_beamTable())));
      expect(
        byLevel.toString(),
        'ByCharacterLevelAmount(CharacterLevelTable('
        '[(1, RolledSpellAmount(1d10)), (5, RolledSpellAmount(2d10)), '
        '(11, RolledSpellAmount(3d10)), (17, RolledSpellAmount(4d10))]))',
      );
    });

    /// Requirement: doc/specs/spell-effect-data.md FR-008, FR-017, FR-020 -
    ///   the three count scalings compare by value and print their parts.
    /// Path: happy
    test('the count scalings compare by value and print their parts', () {
      const none = NoCountScaling();
      expect(none, const NoCountScaling());
      expect(none.hashCode, const NoCountScaling().hashCode);
      expect(none, isNot(PerSlotLevelCount(2, 1)));
      expect(none.toString(), 'NoCountScaling()');

      final perSlot = PerSlotLevelCount(2, 1);
      expect(perSlot, PerSlotLevelCount(2, 1));
      expect(perSlot.hashCode, PerSlotLevelCount(2, 1).hashCode);
      expect(perSlot, isNot(PerSlotLevelCount(1, 1)));
      expect(perSlot, isNot(PerSlotLevelCount(2, 2)));
      expect(perSlot.toString(), 'PerSlotLevelCount(aboveLevel: 2, extra: 1)');

      final byLevel = ByCharacterLevelCount(_beamTable());
      expect(byLevel, ByCharacterLevelCount(_beamTable()));
      expect(byLevel.hashCode, ByCharacterLevelCount(_beamTable()).hashCode);
      expect(byLevel, isNot(ByCharacterLevelAmount(_cantripTable())));
      expect(
        byLevel.toString(),
        'ByCharacterLevelCount(CharacterLevelTable('
        '[(1, 1), (5, 2), (11, 3), (17, 4)]))',
      );
    });

    /// Requirement: doc/specs/spell-effect-data.md FR-016 - a step with a
    ///   negative part is rejected in either field.
    /// Path: unhappy (invalid input)
    test('AmountStep rejects a negative die or flat part', () {
      expect(
        () => AmountStep(extraDice: -1, extraFlat: 1),
        throwsArgumentErrorFor('extraDice', -1),
      );
      expect(
        () => AmountStep(extraDice: 0, extraFlat: -1),
        throwsArgumentErrorFor('extraFlat', -1),
      );
    });

    /// Requirement: doc/specs/spell-effect-data.md FR-008, FR-016 - a step
    ///   compares by value over its two parts and prints them.
    /// Path: happy
    test('AmountStep compares by value and prints its parts', () {
      final step = AmountStep(extraDice: 1, extraFlat: 5);
      expect(step, AmountStep(extraFlat: 5, extraDice: 1));
      expect(step.hashCode, AmountStep(extraDice: 1, extraFlat: 5).hashCode);
      expect(step, isNot(AmountStep(extraDice: 2, extraFlat: 5)));
      expect(step, isNot(AmountStep(extraDice: 1, extraFlat: 0)));
      expect(step.toString(), 'AmountStep(extraDice: 1, extraFlat: 5)');
    });

    /// Requirement: doc/specs/spell-effect-data.md FR-008, FR-019 - a table
    ///   compares by value over its entries, rejects an empty one and
    ///   prints its entries.
    /// Path: unhappy (empty and minimal)
    test('CharacterLevelTable compares by value, rejects empties, prints', () {
      final table = _beamTable();
      expect(table, _beamTable());
      expect(table.hashCode, _beamTable().hashCode);
      final empty = <(int, int)>[];
      expect(
        () => CharacterLevelTable<int>(empty),
        throwsArgumentErrorFor('entries', empty),
      );
      expect(
        table.toString(),
        'CharacterLevelTable([(1, 1), (5, 2), '
        '(11, 3), (17, 4)])',
      );
    });

    /// Requirement: doc/specs/spell-effect-data.md FR-047, FR-018 - an
    ///   amount compares by value, reads its table for a cantrip upgrade
    ///   and prints its parts (SRD 5.2.1, "Cantrip Upgrade", p. 107).
    /// Path: happy
    test('ScalableAmount compares by value, reads tables, prints', () {
      final fixed = FixedSpellAmount(70);
      expect(fixed, FixedSpellAmount(70));
      expect(fixed.hashCode, FixedSpellAmount(70).hashCode);

      final plain = ScalableAmount(
        RolledSpellAmount(DiceExpression(8, Die.d6)),
      );
      expect(
        plain,
        ScalableAmount(RolledSpellAmount(DiceExpression(8, Die.d6))),
      );
      expect(
        plain.hashCode,
        ScalableAmount(RolledSpellAmount(DiceExpression(8, Die.d6))).hashCode,
      );
      expect(
        plain.amountAt(slotLevelsAbove: 3, characterLevel: 5),
        RolledSpellAmount(DiceExpression(8, Die.d6)),
        reason: 'a scaling that reads neither input returns the base',
      );

      final upgraded = ScalableAmount(
        RolledSpellAmount(DiceExpression(1, Die.d10)),
        scaling: ByCharacterLevelAmount(_cantripTable()),
      );
      expect(
        upgraded.amountAt(slotLevelsAbove: 0, characterLevel: 11),
        RolledSpellAmount(DiceExpression(3, Die.d10)),
      );
      expect(
        plain,
        isNot(ScalableAmount(RolledSpellAmount(DiceExpression(9, Die.d6)))),
      );
      expect(
        plain.toString(),
        'ScalableAmount(RolledSpellAmount(8d6), scaling: NoAmountScaling())',
      );
    });

    /// Requirement: doc/specs/spell-effect-data.md FR-008, FR-047 - the two
    ///   printed amount shapes compare by value and print their form.
    /// Path: happy
    test('the printed amounts compare by value and print their form', () {
      final rolled = RolledSpellAmount(DiceExpression(2, Die.d6, modifier: 1));
      expect(rolled, RolledSpellAmount(DiceExpression(2, Die.d6, modifier: 1)));
      expect(
        rolled.hashCode,
        RolledSpellAmount(DiceExpression(2, Die.d6, modifier: 1)).hashCode,
      );
      expect(rolled, isNot(RolledSpellAmount(DiceExpression(3, Die.d6))));
      expect(rolled.toString(), 'RolledSpellAmount(2d6+1)');
      expect(
        FixedSpellAmount(70),
        isNot(RolledSpellAmount(DiceExpression(2, Die.d6, modifier: 1))),
      );
      expect(FixedSpellAmount(70).toString(), 'FixedSpellAmount(70)');
    });
  });

  /// Requirement: doc/specs/spell-effect-data.md FR-017, FR-041 - the
  ///   instance count answers from its base and scaling (SRD 5.2.1,
  ///   "Magic Missile", p. 146).
  /// Path: happy
  group('instanceCountAt', () {
    /// Requirement: doc/specs/spell-effect-data.md FR-041 - a part without
    ///   a scaling keeps its base count at any level.
    /// Path: happy
    test('an unscaled part keeps its base count', () {
      expect(
        PartInstances(
          3,
        ).instanceCountAt(slotLevelsAbove: 2, characterLevel: 11),
        3,
      );
    });

    /// Requirement: doc/specs/spell-effect-data.md FR-017 - a per-slot
    ///   count grows by its extra per slot level above its level.
    /// Path: happy
    test('a per-slot part grows by the slot levels above', () {
      expect(
        PartInstances(
          3,
          scaling: PerSlotLevelCount(1, 1),
        ).instanceCountAt(slotLevelsAbove: 2, characterLevel: 11),
        5,
      );
    });

    /// Requirement: doc/specs/spell-effect-data.md FR-020 - a character
    ///   level table replaces the count: Eldritch Blast's beams
    ///   (SRD 5.2.1, p. 127).
    /// Path: happy
    test('a table part reads its printed count', () {
      expect(
        PartInstances(
          1,
          scaling: ByCharacterLevelCount(_beamTable()),
        ).instanceCountAt(slotLevelsAbove: 0, characterLevel: 11),
        3,
      );
    });
  });

  /// Requirement: doc/specs/spell-effect-data.md FR-008, FR-022 - the fact
  ///   types compare by value with set-valued fields order-insensitive.
  /// Path: happy
  group('effect fact value forms', () {
    /// Requirement: doc/specs/spell-effect-data.md FR-008, FR-022 - a known
    ///   fact compares by value, sets order-insensitively, and prints.
    /// Path: happy
    test('FactKnown compares by value and prints its value', () {
      const bools = FactKnown<bool>(true);
      expect(bools, const FactKnown<bool>(true));
      expect(bools.hashCode, const FactKnown<bool>(true).hashCode);
      expect(bools, isNot(const FactKnown<bool>(false)));
      expect(bools, isNot(const FactUnknown<bool>()));
      expect(bools.toString(), 'FactKnown(true)');

      const oneOrder = FactKnown<Set<DamageType>>({
        DamageType.fire,
        DamageType.cold,
      });
      const otherOrder = FactKnown<Set<DamageType>>({
        DamageType.cold,
        DamageType.fire,
      });
      expect(oneOrder, otherOrder);
      expect(oneOrder.hashCode, otherOrder.hashCode);
      expect(
        oneOrder,
        isNot(const FactKnown<Set<DamageType>>({DamageType.fire})),
      );
      expect(
        oneOrder.toString(),
        'FactKnown({DamageType.fire, DamageType.cold})',
      );
    });

    /// Requirement: doc/specs/spell-effect-data.md FR-008, FR-024 - the
    ///   unknown fact is one single shape and prints its form.
    /// Path: happy
    test('FactUnknown is a single shape and prints its form', () {
      const unknown = FactUnknown<bool>();
      expect(unknown, const FactUnknown<bool>());
      expect(unknown.hashCode, const FactUnknown<bool>().hashCode);
      expect(unknown, isNot(const FactUnknown<int>()));
      expect(unknown, isNot(const FactKnown<bool>(false)));
      expect(unknown.toString(), 'FactUnknown()');
    });

    /// Requirement: doc/specs/spell-effect-data.md FR-008, FR-022 - the
    ///   five facts compare by value over all five answers and print
    ///   them.
    /// Path: happy
    test('SpellEffectFacts compares by value and prints its answers', () {
      SpellEffectFacts build() => const SpellEffectFacts(
        forcesSavingThrow: FactKnown<bool>(true),
        makesSpellAttackRoll: FactUnknown<bool>(),
        dealsDamage: FactKnown<bool>(true),
        damageTypes: FactKnown<Set<DamageType>>({DamageType.fire}),
        canTargetMoreWithHigherSlot: FactUnknown<bool>(),
      );
      expect(build(), build());
      expect(build().hashCode, build().hashCode);
      expect(
        build(),
        isNot(
          const SpellEffectFacts(
            forcesSavingThrow: FactKnown<bool>(false),
            makesSpellAttackRoll: FactUnknown<bool>(),
            dealsDamage: FactKnown<bool>(true),
            damageTypes: FactKnown<Set<DamageType>>({DamageType.fire}),
            canTargetMoreWithHigherSlot: FactUnknown<bool>(),
          ),
        ),
      );
      expect(
        build().toString(),
        startsWith('SpellEffectFacts(FactKnown(true)'),
      );
    });
  });

  /// Requirement: doc/specs/spell-effect-data.md FR-008, FR-048 - the zone
  ///   types compare by value and print their parts.
  /// Path: happy
  group('zone fact value forms', () {
    /// Requirement: doc/specs/spell-effect-data.md FR-008, FR-048 - a
    ///   region id compares by value and prints its name.
    /// Path: happy
    test('ZoneRegionId compares by value and prints its name', () {
      const body = ZoneRegionId.body();
      expect(body, ZoneRegionId('body'));
      expect(body.hashCode, ZoneRegionId('body').hashCode);
      expect(body, isNot(ZoneRegionId('hedge')));
      expect(body.toString(), 'ZoneRegionId(body)');
    });

    /// Requirement: doc/specs/spell-effect-data.md FR-008, FR-048 - the
    ///   four mobility shapes compare by value and print their parts.
    /// Path: happy
    test('the mobility shapes compare by value and print their parts', () {
      const stationary = StationaryZone();
      expect(stationary, const StationaryZone());
      expect(stationary.hashCode, const StationaryZone().hashCode);
      expect(stationary, isNot(const MovesWithOrigin()));
      expect(stationary.toString(), 'StationaryZone()');

      const withOrigin = MovesWithOrigin();
      expect(withOrigin, const MovesWithOrigin());
      expect(withOrigin.hashCode, const MovesWithOrigin().hashCode);
      expect(withOrigin, isNot(stationary));
      expect(withOrigin.toString(), 'MovesWithOrigin()');

      final moved = MovedByCaster(
        20,
        ZoneActionKind.bonusAction,
        laterTurnsOnly: false,
      );
      expect(
        moved,
        MovedByCaster(20, ZoneActionKind.bonusAction, laterTurnsOnly: false),
      );
      expect(
        moved.hashCode,
        MovedByCaster(
          20,
          ZoneActionKind.bonusAction,
          laterTurnsOnly: false,
        ).hashCode,
      );
      expect(
        moved,
        isNot(
          MovedByCaster(15, ZoneActionKind.bonusAction, laterTurnsOnly: false),
        ),
      );
      expect(
        moved,
        isNot(
          MovedByCaster(20, ZoneActionKind.magicAction, laterTurnsOnly: false),
        ),
      );
      expect(moved.toString(), 'MovedByCaster(20, ZoneActionKind.bonusAction)');

      final drifts = DriftsAtTurnStart(10, DriftDirectionRule.awayFromCaster);
      expect(drifts, DriftsAtTurnStart(10, DriftDirectionRule.awayFromCaster));
      expect(
        drifts.hashCode,
        DriftsAtTurnStart(10, DriftDirectionRule.awayFromCaster).hashCode,
      );
      expect(
        drifts,
        isNot(DriftsAtTurnStart(10, DriftDirectionRule.awayFromCasterChosen)),
      );
      expect(
        drifts,
        isNot(DriftsAtTurnStart(5, DriftDirectionRule.awayFromCaster)),
      );
      expect(
        drifts.toString(),
        'DriftsAtTurnStart(10, DriftDirectionRule.awayFromCaster)',
      );
    });

    /// Requirement: doc/specs/spell-effect-data.md FR-008, FR-048 - the
    ///   movement facts, one rule and the whole facts compare by value and
    ///   print their parts.
    /// Path: happy
    test('movement facts, rules and ZoneFacts compare by value', () {
      final movement = ZoneMovementFacts(
        difficultTerrain: true,
        speedHalved: false,
        extraFeetPerFoot: 1,
      );
      expect(
        movement,
        ZoneMovementFacts(
          difficultTerrain: true,
          speedHalved: false,
          extraFeetPerFoot: 1,
        ),
      );
      expect(
        movement.hashCode,
        ZoneMovementFacts(
          difficultTerrain: true,
          speedHalved: false,
          extraFeetPerFoot: 1,
        ).hashCode,
      );
      expect(
        movement,
        isNot(ZoneMovementFacts(difficultTerrain: true, speedHalved: false)),
      );
      expect(movement.toString(), 'ZoneMovementFacts(true, false, 1)');

      ZoneRuleFact rule() => ZoneRuleFact(
        trigger: ZoneTrigger.creatureEnters,
        partIndex: 0,
        scope: ZoneTargetScope.anyCreature,
        casterChoice: false,
      );
      expect(rule(), rule());
      expect(rule().hashCode, rule().hashCode);
      expect(
        rule(),
        isNot(
          ZoneRuleFact(
            trigger: ZoneTrigger.creatureEnters,
            partIndex: 1,
            scope: ZoneTargetScope.anyCreature,
            casterChoice: false,
          ),
        ),
      );
      expect(
        rule(),
        isNot(
          ZoneRuleFact(
            trigger: ZoneTrigger.creatureEndsTurnInside,
            partIndex: 0,
            scope: ZoneTargetScope.anyCreature,
            casterChoice: false,
          ),
        ),
      );
      expect(
        rule().toString(),
        'ZoneRuleFact(ZoneTrigger.creatureEnters, part: 0)',
      );

      ZoneFacts facts() => ZoneFacts(
        rules: [rule()],
        mobility: _stationary,
        oncePerTurn: true,
        designation: DesignationPolicy.atCastingOnly,
        damageBudget: 20,
        stopsMoverOnContact: false,
        movement: movement,
      );
      expect(facts(), facts());
      expect(facts().hashCode, facts().hashCode);
      expect(
        facts(),
        isNot(
          ZoneFacts(
            rules: [rule()],
            mobility: _stationary,
            oncePerTurn: false,
            designation: DesignationPolicy.atCastingOnly,
            damageBudget: 20,
            stopsMoverOnContact: false,
            movement: movement,
          ),
        ),
      );
      expect(facts().toString(), 'ZoneFacts(1 rules)');
    });
  });

  /// Requirement: doc/specs/spell-effect-data.md FR-008, FR-001 - the two
  ///   model variants compare by value and print their debugging form.
  /// Path: happy
  group('model value forms', () {
    /// Requirement: doc/specs/spell-effect-data.md FR-008, FR-001 - the
    ///   text-only model prints its form.
    /// Path: happy
    test('TextOnlyEffects prints its form', () {
      expect(const TextOnlyEffects().toString(), 'TextOnlyEffects()');
    });

    /// Requirement: doc/specs/spell-effect-data.md FR-008, FR-001 - a
    ///   modelled model prints its coverage and part count.
    /// Path: happy
    test('ModelledEffects prints its coverage and part count', () {
      final model = ModelledEffects(
        coverage: EffectCoverage.complete,
        targeting: const TargetsSelf(),
        parts: [_attackDamagePart()],
      );
      expect(
        model.toString(),
        'ModelledEffects(EffectCoverage.complete, 1 parts)',
      );
    });
  });

  /// Requirement: doc/specs/spell-effect-data.md FR-009 - the model must
  ///   not contradict the spell's level; every branch of the check throws
  ///   its named value (SRD 5.2.1, "Casting without Slots", p. 104;
  ///   "Cantrip Upgrade", p. 107).
  /// Path: unhappy (boundary)
  group('checkSpellLevel branches', () {
    /// Requirement: doc/specs/spell-effect-data.md FR-009 - a level outside
    ///   0 to 9 is rejected before any scaling is read.
    /// Path: unhappy (boundary)
    test('a level outside 0 to 9 is rejected', () {
      final model = ModelledEffects(
        coverage: EffectCoverage.complete,
        targeting: const TargetsSelf(),
        parts: [_attackDamagePart()],
      );
      expect(
        () => model.checkSpellLevel(-1),
        throwsArgumentErrorFor('spellLevel', -1),
      );
      expect(
        () => model.checkSpellLevel(10),
        throwsArgumentErrorFor('spellLevel', 10),
      );
    });

    /// Requirement: doc/specs/spell-effect-data.md FR-009 - a per-slot
    ///   target count is checked against the spell's level.
    /// Path: happy
    test('a per-slot target count within the level is accepted', () {
      TargetsChosen count() => TargetsChosen(
        TargetSubject.creature,
        ExactlyTargets(1, scaling: PerSlotLevelCount(2, 1)),
        OnlyCreatureTypes({CreatureType.humanoid}),
      );
      final model = ModelledEffects(
        coverage: EffectCoverage.complete,
        targeting: count(),
        parts: [_conditionPart()],
      );
      expect(() => model.checkSpellLevel(2), returnsNormally);
      expect(
        () => ModelledEffects(
          coverage: EffectCoverage.complete,
          targeting: count(),
          parts: [_conditionPart()],
        ).checkSpellLevel(5),
        throwsArgumentErrorFor('aboveLevel', 2),
        reason: 'the slot level the growth starts at is below the spell level',
      );
    });

    /// Requirement: doc/specs/spell-effect-data.md FR-009 - a per-slot
    ///   target count on an up-to count is checked the same way.
    /// Path: happy
    test('a per-slot count on an up-to targeting is accepted', () {
      final model = ModelledEffects(
        coverage: EffectCoverage.complete,
        targeting: TargetsChosen(
          TargetSubject.creature,
          UpToTargets(3, scaling: PerSlotLevelCount(2, 1)),
          OnlyCreatureTypes({CreatureType.humanoid}),
        ),
        parts: [_conditionPart()],
      );
      expect(() => model.checkSpellLevel(2), returnsNormally);
    });

    /// Requirement: doc/specs/spell-effect-data.md FR-009 - a
    ///   character-level count table belongs to a cantrip.
    /// Path: unhappy (rule interaction)
    test('a character-level count table on a level 1+ spell is rejected', () {
      TargetsChosen count() => TargetsChosen(
        TargetSubject.creature,
        ExactlyTargets(1, scaling: ByCharacterLevelCount(_beamTable())),
        const AnyCreatureType(),
      );
      final model = ModelledEffects(
        coverage: EffectCoverage.complete,
        targeting: count(),
        parts: [_attackDamagePart()],
      );
      expect(
        () => model.checkSpellLevel(1),
        throwsArgumentErrorFor('spellLevel', 1),
      );
      expect(
        () => ModelledEffects(
          coverage: EffectCoverage.complete,
          targeting: count(),
          parts: [_attackDamagePart()],
        ).checkSpellLevel(0),
        returnsNormally,
      );
    });

    /// Requirement: doc/specs/spell-effect-data.md FR-009 - the count and
    ///   amount loops walk every targeting and outcome shape, including
    ///   per-instance targets, areas and condition outcomes, without
    ///   finding a scaling that is not there.
    /// Path: happy
    test('instance, area and condition shapes are walked and accepted', () {
      final byInstance = ModelledEffects(
        coverage: EffectCoverage.complete,
        targeting: TargetsChosen(
          TargetSubject.creature,
          const TargetsByInstance(),
          const AnyCreatureType(),
        ),
        parts: [_attackDamagePart()],
      );
      expect(() => byInstance.checkSpellLevel(1), returnsNormally);

      final inArea = ModelledEffects(
        coverage: EffectCoverage.complete,
        targeting: TargetsInArea(
          SphereArea(20),
          TargetSubject.creature,
          const AnyCreatureType(),
        ),
        parts: [_saveDamagePart()],
      );
      expect(() => inArea.checkSpellLevel(3), returnsNormally);

      final conditionOnly = ModelledEffects(
        coverage: EffectCoverage.complete,
        targeting: const TargetsSelf(),
        parts: [_conditionPart()],
      );
      expect(() => conditionOnly.checkSpellLevel(1), returnsNormally);
    });
  });
}
