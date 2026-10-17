import 'package:srd5e/src/content/domain/condition_kind.dart';
import 'package:srd5e/src/content/domain/creature_type.dart';
import 'package:srd5e/src/content/domain/damage_type.dart';
import 'package:srd5e/src/content/domain/spells/spell_effect_facts.dart';
import 'package:srd5e/src/content/domain/spells/spell_effect_model.dart';
import 'package:srd5e/src/content/domain/spells/spell_effect_part.dart';
import 'package:srd5e/src/content/domain/spells/spell_outcome.dart';
import 'package:srd5e/src/content/domain/spells/spell_scaling.dart';
import 'package:srd5e/src/content/domain/spells/spell_targeting.dart';
import 'package:srd5e/src/shared_kernel/ability/ability.dart';
import 'package:srd5e/src/shared_kernel/dice/dice_expression.dart';
import 'package:srd5e/src/shared_kernel/dice/die.dart';
import 'package:test/test.dart';

import '../../../support/argument_error_matcher.dart';

SpellEffectPart _attackPart({DamageType type = DamageType.fire}) =>
    SpellEffectPart(
      AttackRollResolution(SpellAttackKind.ranged, [
        SpellDealsDamage(
          ScalableAmount(RolledSpellAmount(DiceExpression(1, Die.d10))),
          FixedDamageType(type),
          ModifierAddition.none,
        ),
      ]),
      PartInstances(1),
    );

SpellEffectPart _automaticHealing() => SpellEffectPart(
  AutomaticResolution([
    SpellRestoresHitPoints(
      ScalableAmount(RolledSpellAmount(DiceExpression(2, Die.d8))),
      ModifierAddition.spellcastingAbilityModifier,
    ),
  ]),
  PartInstances(1),
);

void main() {
  /// Requirement: doc/specs/spell-effect-data.md FR-006, FR-007, FR-045 - at least one
  ///   part, at most one ChosenDamageType, unmodifiable lists (package
  ///   design).
  /// Path: unhappy (empty and minimal)
  group('ModelledEffects construction', () {
    /// Requirement: doc/specs/spell-effect-data.md FR-006 - at least one
    ///   part; a spell with nothing modellable is TextOnlyEffects.
    /// Path: unhappy (empty and minimal)
    test('an empty parts list is rejected', () {
      expect(
        () => ModelledEffects(
          coverage: EffectCoverage.complete,
          targeting: const TargetsSelf(),
          parts: const [],
        ),
        throwsArgumentErrorFor('parts', const <SpellEffectPart>[]),
      );
    });

    /// Requirement: doc/specs/spell-effect-data.md FR-045 - at most one
    ///   ChosenDamageType among all outcomes (package design).
    /// Path: unhappy (invalid input)
    test('two ChosenDamageType outcomes are rejected', () {
      final chosen = ChosenDamageType(const {DamageType.fire, DamageType.cold});
      final part = SpellEffectPart(
        AttackRollResolution(SpellAttackKind.ranged, [
          SpellDealsDamage(
            ScalableAmount(RolledSpellAmount(DiceExpression(3, Die.d8))),
            chosen,
            ModifierAddition.none,
          ),
        ]),
        PartInstances(1),
      );
      expect(
        () => ModelledEffects(
          coverage: EffectCoverage.complete,
          targeting: TargetsChosen(
            TargetSubject.creatureOrObject,
            ExactlyTargets(1),
            const AnyCreatureType(),
          ),
          parts: [part, part],
        ),
        throwsA(isA<ArgumentError>().having((e) => e.name, 'name', 'parts')),
      );
    });

    /// Requirement: doc/specs/spell-effect-data.md FR-007 - every list is
    ///   unmodifiable and copied (architecture.md §3, §4).
    /// Path: unhappy (immutability)
    test('the parts list is an unmodifiable copy', () {
      final input = [_automaticHealing()];
      final model = ModelledEffects(
        coverage: EffectCoverage.complete,
        targeting: TargetsChosen(
          TargetSubject.creature,
          ExactlyTargets(1),
          const AnyCreatureType(),
        ),
        parts: input,
      );
      input.clear();
      expect(model.parts, hasLength(1));
      expect(() => model.parts.clear(), throwsUnsupportedError);
      expect(model.parts, hasLength(1));
    });
  });

  /// Requirement: doc/specs/spell-effect-data.md FR-009, FR-001 - the model must not
  ///   contradict the spell's level (SRD 5.2.1, pp. 104, 107).
  /// Path: unhappy (rule interaction)
  group('checkSpellLevel', () {
    /// Requirement: doc/specs/spell-effect-data.md FR-009 - a per-slot
    ///   scaling on a cantrip is rejected ("Casting without Slots",
    ///   SRD 5.2.1, p. 104).
    /// Path: unhappy (rule interaction)
    test('per-slot scaling on a cantrip is rejected', () {
      final model = ModelledEffects(
        coverage: EffectCoverage.complete,
        targeting: const TargetsSelf(),
        parts: [
          SpellEffectPart(
            AutomaticResolution([
              SpellGrantsTemporaryHitPoints(
                ScalableAmount(
                  RolledSpellAmount(DiceExpression(2, Die.d4)),
                  scaling: PerSlotLevelAmount(1, AmountStep(extraFlat: 5)),
                ),
                ModifierAddition.none,
              ),
            ]),
            PartInstances(1),
          ),
        ],
      );
      expect(
        () => model.checkSpellLevel(0),
        throwsA(
          isA<ArgumentError>().having((e) => e.name, 'name', 'spellLevel'),
        ),
      );
    });

    /// Requirement: doc/specs/spell-effect-data.md FR-009 - a
    ///   character-level table on a level 1+ spell is rejected ("Cantrip
    ///   Upgrade", SRD 5.2.1, p. 107).
    /// Path: unhappy (rule interaction)
    test('a character-level table on a level 1+ spell is rejected', () {
      final cantripTable = CharacterLevelTable<SpellAmount>([
        (1, RolledSpellAmount(DiceExpression(1, Die.d10))),
        (5, RolledSpellAmount(DiceExpression(2, Die.d10))),
        (11, RolledSpellAmount(DiceExpression(3, Die.d10))),
        (17, RolledSpellAmount(DiceExpression(4, Die.d10))),
      ]);
      final model = ModelledEffects(
        coverage: EffectCoverage.complete,
        targeting: TargetsChosen(
          TargetSubject.creature,
          ExactlyTargets(1),
          const AnyCreatureType(),
        ),
        parts: [
          SpellEffectPart(
            AttackRollResolution(SpellAttackKind.ranged, [
              SpellDealsDamage(
                ScalableAmount(
                  RolledSpellAmount(DiceExpression(1, Die.d10)),
                  scaling: ByCharacterLevelAmount(cantripTable),
                ),
                const FixedDamageType(DamageType.fire),
                ModifierAddition.none,
              ),
            ]),
            PartInstances(1),
          ),
        ],
      );
      expect(
        () => model.checkSpellLevel(1),
        throwsA(
          isA<ArgumentError>().having((e) => e.name, 'name', 'spellLevel'),
        ),
      );
      expect(() => _perSlotModel().checkSpellLevel(1), returnsNormally);
    });

    /// Requirement: doc/specs/spell-effect-data.md FR-009 - an aboveLevel
    ///   below the spell's level or above 9 is rejected.
    /// Path: unhappy (rule interaction)
    test('an aboveLevel below the level or above 9 is rejected', () {
      final low = ModelledEffects(
        coverage: EffectCoverage.complete,
        targeting: const TargetsSelf(),
        parts: [_flatScaledPart(aboveLevel: 3)],
      );
      expect(
        () => low.checkSpellLevel(5),
        throwsA(
          isA<ArgumentError>().having((e) => e.name, 'name', 'aboveLevel'),
        ),
      );
      expect(
        () => _flatScaledPartModel(aboveLevel: 10).checkSpellLevel(9),
        throwsA(
          isA<ArgumentError>().having((e) => e.name, 'name', 'aboveLevel'),
        ),
      );
      expect(
        () => _flatScaledPartModel(aboveLevel: 5).checkSpellLevel(5),
        returnsNormally,
      );
      expect(
        () => _flatScaledPartModel(aboveLevel: 6).checkSpellLevel(5),
        returnsNormally,
      );
      // The bound is inclusive: an aboveLevel of exactly 9 is valid.
      expect(
        () => _flatScaledPartModel(aboveLevel: 9).checkSpellLevel(3),
        returnsNormally,
      );
    });

    /// Requirement: doc/specs/spell-effect-data.md FR-009 - a
    ///   character-level count table belongs to a cantrip, so a cantrip
    ///   holding one does not contradict its level.
    /// Path: happy
    test('a character-level count table on a cantrip is accepted', () {
      final model = ModelledEffects(
        coverage: EffectCoverage.complete,
        targeting: TargetsChosen(
          TargetSubject.creature,
          ExactlyTargets(
            1,
            scaling: ByCharacterLevelCount(
              CharacterLevelTable<int>([(1, 1), (5, 2), (11, 3), (17, 4)]),
            ),
          ),
          const AnyCreatureType(),
        ),
        parts: [_automaticHealing()],
      );
      expect(() => model.checkSpellLevel(0), returnsNormally);
    });

    /// Requirement: doc/specs/spell-effect-data.md FR-009 - a
    ///   character-level amount table belongs to a cantrip, so a cantrip
    ///   holding one does not contradict its level either.
    /// Path: happy
    test('a character-level amount table on a cantrip is accepted', () {
      final cantripTable = CharacterLevelTable<SpellAmount>([
        (1, RolledSpellAmount(DiceExpression(1, Die.d10))),
        (5, RolledSpellAmount(DiceExpression(2, Die.d10))),
        (11, RolledSpellAmount(DiceExpression(3, Die.d10))),
        (17, RolledSpellAmount(DiceExpression(4, Die.d10))),
      ]);
      final model = ModelledEffects(
        coverage: EffectCoverage.complete,
        targeting: const TargetsSelf(),
        parts: [
          SpellEffectPart(
            AutomaticResolution([
              SpellRestoresHitPoints(
                ScalableAmount(
                  RolledSpellAmount(DiceExpression(2, Die.d8)),
                  scaling: ByCharacterLevelAmount(cantripTable),
                ),
                ModifierAddition.spellcastingAbilityModifier,
              ),
            ]),
            PartInstances(1),
          ),
        ],
      );
      expect(() => model.checkSpellLevel(0), returnsNormally);
    });

    /// Requirement: doc/specs/spell-effect-data.md FR-001 - a spell with no
    ///   structured data carries TextOnlyEffects, which cannot contradict a
    ///   level (SRD 5.2.1, "Effects", p. 106).
    /// Path: happy
    test('TextOnlyEffects accepts any level and knows no fact', () {
      const model = TextOnlyEffects();
      expect(() => model.checkSpellLevel(0), returnsNormally);
      expect(() => model.checkSpellLevel(9), returnsNormally);
      expect(model.facts.forcesSavingThrow, const FactUnknown<bool>());
      expect(model.facts.makesSpellAttackRoll, const FactUnknown<bool>());
      expect(model.facts.dealsDamage, const FactUnknown<bool>());
      expect(model.facts.damageTypes, const FactUnknown<Set<DamageType>>());
      expect(
        model.facts.canTargetMoreWithHigherSlot,
        const FactUnknown<bool>(),
      );
    });
  });

  /// Requirement: doc/specs/spell-effect-data.md FR-022, FR-023, FR-024 - the five facts are
  ///   known from the parts; negatives and damage types are known only
  ///   when complete (SRD 5.2.1, "Effects", p. 106).
  /// Path: happy
  group('derived facts (Table F)', () {
    /// Requirement: doc/specs/spell-effect-data.md FR-022 - known facts from
    ///   the modelled parts, in any coverage ("Effects", SRD 5.2.1, p. 106).
    /// Path: happy
    test('an attack-roll spell is known to attack and, when complete, not to '
        'save', () {
      final eldritchBlast = ModelledEffects(
        coverage: EffectCoverage.complete,
        targeting: TargetsChosen(
          TargetSubject.creatureOrObject,
          const TargetsByInstance(),
          const AnyCreatureType(),
        ),
        parts: [
          SpellEffectPart(
            AttackRollResolution(SpellAttackKind.ranged, [
              SpellDealsDamage(
                ScalableAmount(RolledSpellAmount(DiceExpression(1, Die.d10))),
                const FixedDamageType(DamageType.force),
                ModifierAddition.none,
              ),
            ]),
            PartInstances(1),
          ),
        ],
      );
      expect(
        eldritchBlast.facts.makesSpellAttackRoll,
        const FactKnown<bool>(true),
      );
      expect(
        eldritchBlast.facts.forcesSavingThrow,
        const FactKnown<bool>(false),
      );
      expect(eldritchBlast.facts.dealsDamage, const FactKnown<bool>(true));
      expect(
        eldritchBlast.facts.damageTypes,
        const FactKnown<Set<DamageType>>({DamageType.force}),
      );
      expect(
        eldritchBlast.facts.canTargetMoreWithHigherSlot,
        const FactKnown<bool>(false),
      );
    });

    /// Requirement: doc/specs/spell-effect-data.md FR-022 - a complete model
    ///   answers every question: self-targeted and in-area spells never add
    ///   targets with a higher slot, and a spell that neither attacks nor
    ///   deals damage knows both negatives and the empty type set.
    /// Path: happy
    test('a complete spell without attacks or damage knows the negatives', () {
      ModelledEffects build(SpellTargeting targeting) => ModelledEffects(
        coverage: EffectCoverage.complete,
        targeting: targeting,
        parts: [_automaticHealing()],
      );
      expect(
        build(const TargetsSelf()).facts.canTargetMoreWithHigherSlot,
        const FactKnown<bool>(false),
      );
      expect(
        build(
          TargetsInArea(
            SphereArea(20),
            TargetSubject.creature,
            const AnyCreatureType(),
          ),
        ).facts.canTargetMoreWithHigherSlot,
        const FactKnown<bool>(false),
      );
      final chosen = build(
        TargetsChosen(
          TargetSubject.creature,
          ExactlyTargets(1),
          const AnyCreatureType(),
        ),
      );
      expect(chosen.facts.makesSpellAttackRoll, const FactKnown<bool>(false));
      expect(chosen.facts.dealsDamage, const FactKnown<bool>(false));
      expect(
        chosen.facts.damageTypes,
        const FactKnown<Set<DamageType>>(<DamageType>{}),
      );
    });

    /// Requirement: doc/specs/spell-effect-data.md FR-023 - known-false and
    ///   damage types are unknown under partial coverage ("AGENTS.md",
    ///   never guess content).
    /// Path: unhappy (rule interaction)
    test('a partial spell answers negatives with FactUnknown', () {
      final partial = ModelledEffects(
        coverage: EffectCoverage.partial,
        targeting: TargetsChosen(
          TargetSubject.creatureOrObject,
          ExactlyTargets(1),
          const AnyCreatureType(),
        ),
        parts: [_attackPart(type: DamageType.fire)],
      );
      expect(partial.facts.makesSpellAttackRoll, const FactKnown<bool>(true));
      expect(partial.facts.forcesSavingThrow, const FactUnknown<bool>());
      expect(partial.facts.dealsDamage, const FactKnown<bool>(true));
      expect(partial.facts.damageTypes, const FactUnknown<Set<DamageType>>());
    });

    /// Requirement: doc/specs/spell-effect-data.md FR-022, FR-023 - a fact
    ///   is FactKnown(true) when the modelled parts show it, in any
    ///   coverage: Fireball's modelled Dexterity save on a partial spell
    ///   (SRD 5.2.1, "Fireball", p. 131).
    /// Path: happy
    test('F8 a partial spell with a saving throw knows it forces one', () {
      final fireball = ModelledEffects(
        coverage: EffectCoverage.partial,
        targeting: TargetsInArea(
          SphereArea(20),
          TargetSubject.creature,
          const AnyCreatureType(),
        ),
        parts: [_savePartTypeOnly()],
      );
      expect(fireball.facts.forcesSavingThrow, const FactKnown<bool>(true));
      expect(fireball.coverage, EffectCoverage.partial);
    });

    /// Requirement: doc/specs/spell-effect-data.md FR-022 - a per-slot
    ///   target count is known to add targets ("Hold Person", SRD 5.2.1,
    ///   p. 141); instances are not targets ("Magic Missile", p. 146).
    /// Path: happy
    test('canTargetMoreWithHigherSlot counts targets, not instances', () {
      final holdPerson = ModelledEffects(
        coverage: EffectCoverage.partial,
        targeting: TargetsChosen(
          TargetSubject.creature,
          ExactlyTargets(1, scaling: PerSlotLevelCount(2, 1)),
          OnlyCreatureTypes({CreatureType.humanoid}),
        ),
        parts: [_savePartTypeOnly()],
      );
      expect(
        holdPerson.facts.canTargetMoreWithHigherSlot,
        const FactKnown<bool>(true),
      );
      final magicMissile = ModelledEffects(
        coverage: EffectCoverage.complete,
        targeting: TargetsChosen(
          TargetSubject.creature,
          const TargetsByInstance(),
          const AnyCreatureType(),
        ),
        parts: [
          SpellEffectPart(
            AutomaticResolution([
              SpellDealsDamage(
                ScalableAmount(
                  RolledSpellAmount(DiceExpression(1, Die.d4, modifier: 1)),
                ),
                const FixedDamageType(DamageType.force),
                ModifierAddition.none,
              ),
            ]),
            PartInstances(3, scaling: PerSlotLevelCount(1, 1)),
          ),
        ],
      );
      expect(
        magicMissile.facts.canTargetMoreWithHigherSlot,
        const FactKnown<bool>(false),
      );
    });

    /// Requirement: doc/specs/spell-effect-data.md FR-022 - a chosen damage
    ///   type contributes its whole set (Chromatic Orb, SRD 5.2.1, p. 115).
    /// Path: happy
    test('a chosen damage type contributes its set when complete', () {
      const sixTypes = {
        DamageType.acid,
        DamageType.cold,
        DamageType.fire,
        DamageType.lightning,
        DamageType.poison,
        DamageType.thunder,
      };
      final model = ModelledEffects(
        coverage: EffectCoverage.complete,
        targeting: TargetsChosen(
          TargetSubject.creatureOrObject,
          ExactlyTargets(1),
          const AnyCreatureType(),
        ),
        parts: [
          SpellEffectPart(
            AttackRollResolution(SpellAttackKind.ranged, [
              SpellDealsDamage(
                ScalableAmount(RolledSpellAmount(DiceExpression(3, Die.d8))),
                ChosenDamageType(sixTypes),
                ModifierAddition.none,
              ),
            ]),
            PartInstances(1),
          ),
        ],
      );
      expect(
        model.facts.damageTypes,
        const FactKnown<Set<DamageType>>(sixTypes),
      );
    });

    /// Requirement: doc/specs/spell-effect-data.md FR-008 - the model is a
    ///   value object over its fields, set-valued fields
    ///   order-insensitive.
    /// Path: happy
    test('models compare by value', () {
      ModelledEffects build() => ModelledEffects(
        coverage: EffectCoverage.complete,
        targeting: const TargetsSelf(),
        parts: [_automaticHealing()],
      );
      expect(build(), build());
      expect(build().hashCode, build().hashCode);
      expect(const TextOnlyEffects(), const TextOnlyEffects());
      expect(build(), isNot(const TextOnlyEffects()));
    });
  });
}

SpellEffectPart _flatScaledPart({required int aboveLevel}) => SpellEffectPart(
  AutomaticResolution([
    SpellGrantsTemporaryHitPoints(
      ScalableAmount(
        FixedSpellAmount(5),
        scaling: PerSlotLevelAmount(aboveLevel, AmountStep(extraFlat: 5)),
      ),
      ModifierAddition.none,
    ),
  ]),
  PartInstances(1),
);

ModelledEffects _flatScaledPartModel({required int aboveLevel}) =>
    ModelledEffects(
      coverage: EffectCoverage.complete,
      targeting: const TargetsSelf(),
      parts: [_flatScaledPart(aboveLevel: aboveLevel)],
    );

ModelledEffects _perSlotModel() => _flatScaledPartModel(aboveLevel: 1);

SpellEffectPart _savePartTypeOnly() => SpellEffectPart(
  SavingThrowResolution(Ability.wisdom, [
    const SpellAppliesCondition(ConditionKind.paralyzed, ForSpellDuration()),
  ], const NothingOnSuccess()),
  PartInstances(1),
);
