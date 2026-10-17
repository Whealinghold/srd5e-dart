import 'package:meta/meta.dart';

import '../../../shared_kernel/ability/ability.dart';
import 'spell_outcome.dart';
import 'spell_scaling.dart';

/// What rolling or not rolling one part of a spell's effects is, sealed with
/// exactly the SRD's two hooks plus the package's no-roll shape (FR-042).
///
/// "Effects" names the two rolls a spell may ask for — attack rolls and
/// saving throws ("Effects", SRD 5.2.1, p. 106); [AutomaticResolution] is
/// package design for effects with no roll, such as Magic Missile and Cure
/// Wounds. A [SpellEffectPart] holds one resolution. Switch over the family
/// exhaustively, with no default branch.
@immutable
sealed class PartResolution {
  const PartResolution();

  /// The outcome lists the resolution carries, in variant order: the lists
  /// whose outcomes the part produces.
  List<List<SpellOutcome>> get outcomeLists => switch (this) {
    AttackRollResolution(:final onHit, :final onMiss) => [onHit, onMiss],
    SavingThrowResolution(:final onFailure) => [onFailure],
    AutomaticResolution(:final outcomes) => [outcomes],
  };
}

/// Which kind of spell attack the part makes ("Spell Attack",
/// SRD 5.2.1, p. 188) (FR-042).
enum SpellAttackKind {
  /// A melee spell attack ("Melee Attacks", SRD 5.2.1, p. 15).
  melee,

  /// A ranged spell attack ("Ranged Attacks", SRD 5.2.1, p. 15).
  ranged,
}

/// A spell attack roll, with the damage and other effects of a hit and of a
/// miss (FR-042).
@immutable
final class AttackRollResolution extends PartResolution {
  /// Creates the attack of [kind], producing [onHit] outcomes and [onMiss]
  /// outcomes.
  ///
  /// Throws an [ArgumentError] carrying the name `onHit` and the offending
  /// value when [onHit] is empty: an attack produces at least its hit effect
  /// (FR-026). [onMiss] may be empty (FR-026).
  AttackRollResolution(
    this.kind,
    List<SpellOutcome> onHit, [
    List<SpellOutcome> onMiss = const [],
  ]) : onHit = List.unmodifiable(_validatedOnHit(onHit)),
       onMiss = List.unmodifiable(onMiss);

  /// The kind of spell attack.
  final SpellAttackKind kind;

  /// The outcomes of a hit; unmodifiable, never empty (FR-026).
  final List<SpellOutcome> onHit;

  /// The outcomes of a miss; unmodifiable, possibly empty (FR-026).
  final List<SpellOutcome> onMiss;

  static List<SpellOutcome> _validatedOnHit(List<SpellOutcome> onHit) {
    if (onHit.isEmpty) {
      throw ArgumentError.value(
        onHit,
        'onHit',
        'must have at least one outcome',
      );
    }
    return onHit;
  }

  @override
  bool operator ==(Object other) =>
      other is AttackRollResolution &&
      other.kind == kind &&
      _listsEqual(other.onHit, onHit) &&
      _listsEqual(other.onMiss, onMiss);

  @override
  int get hashCode => Object.hash(
    AttackRollResolution,
    kind,
    _listHash(onHit),
    _listHash(onMiss),
  );

  @override
  String toString() => 'AttackRollResolution($kind)';
}

/// A saving throw against the spell's save DC, with the effects of a failure
/// and of a success (FR-042).
@immutable
final class SavingThrowResolution extends PartResolution {
  /// Creates the saving throw of [ability], producing [onFailure] outcomes
  /// and [onSuccess].
  ///
  /// Throws an [ArgumentError] carrying the name `onFailure` and the offending
  /// value when [onFailure] is empty (FR-026), and the name `onSuccess` and
  /// the offending value when [onSuccess] is [HalfDamageOnSuccess] while
  /// [onFailure] holds no [SpellDealsDamage]: there is nothing to halve
  /// (FR-043).
  SavingThrowResolution(
    this.ability,
    List<SpellOutcome> onFailure,
    this.onSuccess,
  ) : onFailure = List.unmodifiable(_validated(onFailure)) {
    if (onSuccess is HalfDamageOnSuccess) {
      final damages = onFailure.any((outcome) => outcome is SpellDealsDamage);
      if (!damages) {
        throw ArgumentError.value(
          onSuccess,
          'onSuccess',
          'requires at least one SpellDealsDamage outcome on a failure',
        );
      }
    }
  }

  /// The ability the save is made with ("Saving Throws", SRD 5.2.1, p. 106).
  final Ability ability;

  /// The outcomes of a failed save; unmodifiable, never empty (FR-026).
  final List<SpellOutcome> onFailure;

  /// What a successful save does.
  final SuccessEffect onSuccess;

  static List<SpellOutcome> _validated(List<SpellOutcome> onFailure) {
    if (onFailure.isEmpty) {
      throw ArgumentError.value(
        onFailure,
        'onFailure',
        'must have at least one outcome',
      );
    }
    return onFailure;
  }

  @override
  bool operator ==(Object other) =>
      other is SavingThrowResolution &&
      other.ability == ability &&
      _listsEqual(other.onFailure, onFailure) &&
      other.onSuccess == onSuccess;

  @override
  int get hashCode => Object.hash(
    SavingThrowResolution,
    ability,
    _listHash(onFailure),
    onSuccess,
  );

  @override
  String toString() => 'SavingThrowResolution($ability)';
}

/// What a successful saving throw does, sealed with the two printed shapes
/// (FR-043).
///
/// "Saving Throws and Damage" ("Half Damage", SRD 5.2.1, p. 16). Switch over
/// the family exhaustively, with no default branch.
@immutable
sealed class SuccessEffect {
  const SuccessEffect();
}

/// The spell has no effect on a successful save ("Acid Splash",
/// SRD 5.2.1, p. 107).
@immutable
final class NothingOnSuccess extends SuccessEffect {
  /// The single shape; no effect carries no data.
  const NothingOnSuccess();

  @override
  bool operator ==(Object other) => other is NothingOnSuccess;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'NothingOnSuccess()';
}

/// Half damage on a successful save ("Half Damage", SRD 5.2.1, p. 16)
/// (FR-043).
///
/// Requires at least one [SpellDealsDamage] in the [SavingThrowResolution]'s
/// `onFailure` outcomes, else [ArgumentError]; the rounding is the
/// hit-points-and-damage rules' concern.
@immutable
final class HalfDamageOnSuccess extends SuccessEffect {
  /// The single shape; the halving rule is fixed by the SRD.
  const HalfDamageOnSuccess();

  @override
  bool operator ==(Object other) => other is HalfDamageOnSuccess;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'HalfDamageOnSuccess()';
}

/// An effect that happens without a roll, producing its [outcomes] (FR-042):
/// Magic Missile's darts, Cure Wounds' healing (SRD 5.2.1, pp. 146, 121).
@immutable
final class AutomaticResolution extends PartResolution {
  /// Creates the automatic resolution producing [outcomes].
  ///
  /// Throws an [ArgumentError] carrying the name `outcomes` and the offending
  /// value when [outcomes] is empty (FR-026).
  AutomaticResolution(List<SpellOutcome> outcomes)
    : outcomes = List.unmodifiable(_validated(outcomes));

  /// The outcomes produced; unmodifiable, never empty (FR-026).
  final List<SpellOutcome> outcomes;

  static List<SpellOutcome> _validated(List<SpellOutcome> outcomes) {
    if (outcomes.isEmpty) {
      throw ArgumentError.value(
        outcomes,
        'outcomes',
        'must have at least one outcome',
      );
    }
    return outcomes;
  }

  @override
  bool operator ==(Object other) =>
      other is AutomaticResolution && _listsEqual(other.outcomes, outcomes);

  @override
  int get hashCode => Object.hash(AutomaticResolution, _listHash(outcomes));

  @override
  String toString() => 'AutomaticResolution(${outcomes.length})';
}

/// How many instances a part has, with their growth (FR-042, FR-029).
///
/// Eldritch Blast's "one beam" at level 1 grows by the character level
/// (SRD 5.2.1, p. 127); Magic Missile's three darts grow by the slot level
/// (p. 146). Instances are not targets: the targets are those the instances
/// are assigned to (FR-012).
@immutable
final class PartInstances {
  /// Creates [base] instances, scaled by [scaling].
  ///
  /// Throws an [ArgumentError] carrying the name `base` and the offending
  /// value when [base] is below 1 (FR-029).
  PartInstances(int base, {this.scaling = const NoCountScaling()})
    : base = _validatedBase(base);

  /// The base number of instances, at least 1.
  final int base;

  /// How the instance count grows.
  final CountScaling scaling;

  /// The instance count after growth (FR-017, FR-041): the count grown from
  /// [base] by [slotLevelsAbove] slot levels or by the [characterLevel]
  /// table, per this part's scaling.
  int instanceCountAt({
    required int slotLevelsAbove,
    required int characterLevel,
  }) => scaling.countAt(
    base,
    slotLevelsAbove: slotLevelsAbove,
    characterLevel: characterLevel,
  );

  static int _validatedBase(int base) {
    if (base < 1) {
      throw ArgumentError.value(base, 'base', 'must be at least 1');
    }
    return base;
  }

  @override
  bool operator ==(Object other) =>
      other is PartInstances && other.base == base && other.scaling == scaling;

  @override
  int get hashCode => Object.hash(PartInstances, base, scaling);

  @override
  String toString() => 'PartInstances($base, scaling: $scaling)';
}

/// One independent effect of a spell: its resolution and its instances
/// (FR-042).
///
/// Flame Strike's two damage types are two outcomes of one part; Eldritch
/// Blast's several beams are one part with several instances (FR-021).
@immutable
final class SpellEffectPart {
  /// Creates the part resolving through [resolution] with [instances].
  const SpellEffectPart(this.resolution, this.instances);

  /// What the part rolls, or that it rolls nothing.
  final PartResolution resolution;

  /// How many instances the part has.
  final PartInstances instances;

  @override
  bool operator ==(Object other) =>
      other is SpellEffectPart &&
      other.resolution == resolution &&
      other.instances == instances;

  @override
  int get hashCode => Object.hash(SpellEffectPart, resolution, instances);

  @override
  String toString() => 'SpellEffectPart($resolution)';
}

bool _listsEqual(List<SpellOutcome> a, List<SpellOutcome> b) {
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}

int _listHash(List<SpellOutcome> list) =>
    Object.hashAll(list.map((outcome) => outcome.hashCode));
