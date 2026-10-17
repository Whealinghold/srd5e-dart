import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import '../damage_type.dart';
import 'spell_effect_facts.dart';
import 'spell_effect_part.dart';
import 'spell_outcome.dart';
import 'spell_scaling.dart';
import 'spell_targeting.dart';
import 'zone_facts.dart';

/// How much of a spell's effect text is modelled (FR-004).
///
/// `complete` states that every outcome the effect text describes is
/// modelled; `partial` marks a spell whose text also describes outcomes no
/// variant expresses — movement, summoned creatures, terrain, light, objects,
/// Hit Point maximum changes, effects on later turns ("Effects",
/// SRD 5.2.1, p. 106). Limits on who may be chosen are the host's and do not
/// affect the coverage (FR-004).
enum EffectCoverage {
  /// Every described outcome is modelled.
  complete,

  /// The text describes outcomes beyond the modelled ones; they stay in the
  /// text and are the Game Master's (FR-005).
  partial,
}

/// A spell's structured effects (FR-001), sealed with exactly the two
/// variants.
///
/// The extension point of the spell-effects design: the model is **data** in
/// `content` — value objects with validation and static queries only, no
/// function, callback or spell-specific type (FR-002) — and the interpreter
/// is the standard rules in `combat`. A spell with no structured data carries
/// `const TextOnlyEffects()`; that is a valid spell. Switch over the family
/// exhaustively, with no default branch.
@immutable
sealed class SpellEffectModel {
  const SpellEffectModel();

  /// Rejects this model when it contradicts a spell of [spellLevel]
  /// (FR-009).
  ///
  /// Called by the `Spell` constructor with the spell's level. A per-slot
  /// scaling ([PerSlotLevelAmount], [PerSlotLevelCount]) on a cantrip, a
  /// character-level table ([ByCharacterLevelAmount],
  /// [ByCharacterLevelCount]) on a level 1+ spell, and a per-slot
  /// `aboveLevel` below the spell's level or above 9 throw an
  /// [ArgumentError]; a model that agrees with the level returns.
  void checkSpellLevel(int spellLevel);

  /// The five derived spell facts (FR-022).
  SpellEffectFacts get facts;
}

/// A spell whose description text is the only source of its effects (FR-001).
@immutable
final class TextOnlyEffects extends SpellEffectModel {
  /// The single shape; no structured data. The default of `Spell.effects`
  /// (FR-122).
  const TextOnlyEffects();

  @override
  void checkSpellLevel(int spellLevel) {
    // No data: the model cannot contradict any spell level.
  }

  @override
  SpellEffectFacts get facts => const SpellEffectFacts(
    forcesSavingThrow: FactUnknown<bool>(),
    makesSpellAttackRoll: FactUnknown<bool>(),
    dealsDamage: FactUnknown<bool>(),
    damageTypes: FactUnknown<Set<DamageType>>(),
    canTargetMoreWithHigherSlot: FactUnknown<bool>(),
  );

  @override
  bool operator ==(Object other) => other is TextOnlyEffects;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'TextOnlyEffects()';
}

/// A spell with structured effect data: a coverage, targeting, at least one
/// ordered part and optional zone facts (FR-001, FR-004, FR-006, FR-048).
@immutable
final class ModelledEffects extends SpellEffectModel {
  /// Creates the model from a defensive copy of [parts].
  ///
  /// Throws an [ArgumentError] carrying the name `parts` and the offending
  /// value when [parts] is empty: a spell with nothing structurally
  /// modellable is [TextOnlyEffects] (FR-006). Throws the name `parts` when
  /// more than one outcome of the model holds a [ChosenDamageType]: the cast
  /// carries a single damage-type choice (FR-045).
  ModelledEffects({
    required this.coverage,
    required this.targeting,
    required List<SpellEffectPart> parts,
    this.zoneFacts,
  }) : parts = List.unmodifiable(parts) {
    if (parts.isEmpty) {
      throw ArgumentError.value(parts, 'parts', 'must have at least one part');
    }
    _validateSingleChoice(this.parts);
  }

  /// How much of the effect text is modelled (FR-004).
  final EffectCoverage coverage;

  /// How the spell picks its targets.
  final SpellTargeting targeting;

  /// The parts, in printed order; unmodifiable, never empty (FR-006).
  final List<SpellEffectPart> parts;

  /// The static facts of a lingering zone, or null for none (FR-048).
  final ZoneFacts? zoneFacts;

  /// Whether a higher slot level adds targets: the targets' count carries a
  /// [PerSlotLevelCount]. More instances — darts, rays — are not additional
  /// targets (FR-022).
  bool get scalesTargetsWithSlotLevel => switch (targeting) {
    TargetsChosen(:final count) => switch (count) {
      ExactlyTargets(:final scaling) => scaling is PerSlotLevelCount,
      UpToTargets(:final scaling) => scaling is PerSlotLevelCount,
      TargetsByInstance() => false,
    },
    TargetsSelf() => false,
    TargetsInArea() => false,
  };

  @override
  void checkSpellLevel(int spellLevel) {
    if (spellLevel < 0 || spellLevel > 9) {
      throw ArgumentError.value(
        spellLevel,
        'spellLevel',
        'must be from 0 to 9',
      );
    }
    for (final scaling in _countScalings()) {
      if (scaling is PerSlotLevelCount) {
        _checkPerSlot(spellLevel, scaling.aboveLevel);
      } else if (scaling is ByCharacterLevelCount && spellLevel > 0) {
        throw ArgumentError.value(
          spellLevel,
          'spellLevel',
          'a character-level count table belongs to a cantrip',
        );
      }
    }
    for (final scaling in _amountScalings()) {
      if (scaling is PerSlotLevelAmount) {
        _checkPerSlot(spellLevel, scaling.aboveLevel);
      } else if (scaling is ByCharacterLevelAmount && spellLevel > 0) {
        throw ArgumentError.value(
          spellLevel,
          'spellLevel',
          'a character-level amount table belongs to a cantrip',
        );
      }
    }
  }

  /// A per-slot scaling agrees with [spellLevel] when [aboveLevel] is within
  /// it and at most 9; on a cantrip no per-slot scaling is allowed (FR-009).
  void _checkPerSlot(int spellLevel, int aboveLevel) {
    if (spellLevel == 0) {
      throw ArgumentError.value(
        spellLevel,
        'spellLevel',
        'a cantrip is cast without a spell slot, so it cannot scale per slot level',
      );
    }
    if (aboveLevel < spellLevel || aboveLevel > 9) {
      throw ArgumentError.value(
        aboveLevel,
        'aboveLevel',
        'must be from the spell level ($spellLevel) to 9',
      );
    }
  }

  Iterable<CountScaling> _countScalings() sync* {
    switch (targeting) {
      case TargetsChosen(:final count):
        switch (count) {
          case ExactlyTargets(:final scaling):
            yield scaling;
          case UpToTargets(:final scaling):
            yield scaling;
          case TargetsByInstance():
            break;
        }
      case TargetsSelf():
        break;
      case TargetsInArea():
        break;
    }
    for (final part in parts) {
      yield part.instances.scaling;
    }
  }

  Iterable<AmountScaling> _amountScalings() sync* {
    for (final part in parts) {
      for (final outcomes in part.resolution.outcomeLists) {
        for (final outcome in outcomes) {
          switch (outcome) {
            case SpellDealsDamage(:final amount):
              yield amount.scaling;
            case SpellRestoresHitPoints(:final amount):
              yield amount.scaling;
            case SpellGrantsTemporaryHitPoints(:final amount):
              yield amount.scaling;
            case SpellAppliesCondition():
              break;
          }
        }
      }
    }
  }

  static void _validateSingleChoice(List<SpellEffectPart> parts) {
    var chosen = 0;
    for (final part in parts) {
      for (final outcomes in part.resolution.outcomeLists) {
        for (final outcome in outcomes) {
          if (outcome case SpellDealsDamage(type: ChosenDamageType())) {
            chosen++;
            if (chosen > 1) {
              throw ArgumentError.value(
                parts,
                'parts',
                'a model holds at most one ChosenDamageType '
                    '(the cast carries a single choice, FR-045)',
              );
            }
          }
        }
      }
    }
  }

  @override
  SpellEffectFacts get facts {
    var savingThrow = false;
    var attackRoll = false;
    var damage = false;
    final damageTypes = <DamageType>{};
    for (final part in parts) {
      final resolution = part.resolution;
      if (resolution is SavingThrowResolution) {
        savingThrow = true;
      }
      if (resolution is AttackRollResolution) {
        attackRoll = true;
      }
      for (final outcomes in resolution.outcomeLists) {
        for (final outcome in outcomes) {
          if (outcome is! SpellDealsDamage) {
            continue;
          }
          damage = true;
          switch (outcome.type) {
            case FixedDamageType(:final type):
              damageTypes.add(type);
            case ChosenDamageType(types: final chosen):
              damageTypes.addAll(chosen);
          }
        }
      }
    }
    final complete = coverage == EffectCoverage.complete;
    return SpellEffectFacts(
      forcesSavingThrow: savingThrow
          ? const FactKnown<bool>(true)
          : _negativeOrUnknown(complete),
      makesSpellAttackRoll: attackRoll
          ? const FactKnown<bool>(true)
          : _negativeOrUnknown(complete),
      dealsDamage: damage
          ? const FactKnown<bool>(true)
          : _negativeOrUnknown(complete),
      damageTypes: complete
          ? FactKnown<Set<DamageType>>(Set.unmodifiable(damageTypes))
          : const FactUnknown<Set<DamageType>>(),
      canTargetMoreWithHigherSlot: scalesTargetsWithSlotLevel
          ? const FactKnown<bool>(true)
          : _negativeOrUnknown(complete),
    );
  }

  /// A negative answer is known only when the coverage is complete; with
  /// `partial` coverage the text may hold what the model leaves out
  /// (FR-023).
  static EffectFact<bool> _negativeOrUnknown(bool complete) =>
      complete ? const FactKnown<bool>(false) : const FactUnknown<bool>();

  @override
  bool operator ==(Object other) =>
      other is ModelledEffects &&
      other.coverage == coverage &&
      other.targeting == targeting &&
      const ListEquality<SpellEffectPart>().equals(other.parts, parts) &&
      other.zoneFacts == zoneFacts;

  @override
  int get hashCode => Object.hash(
    ModelledEffects,
    coverage,
    targeting,
    const ListEquality<SpellEffectPart>().hash(parts),
    zoneFacts,
  );

  @override
  String toString() => 'ModelledEffects($coverage, ${parts.length} parts)';
}
