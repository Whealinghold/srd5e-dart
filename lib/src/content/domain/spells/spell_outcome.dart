import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import '../condition_kind.dart';
import '../damage_type.dart';
import '../duration_unit.dart';
import 'spell_scaling.dart';

/// What one effect of a part does, sealed with exactly the four shapes the
/// SRD names as the substance of a spell's effects (FR-047).
///
/// The outcomes a part lists are the answers to "targets, saving throws,
/// attack rolls, or all three" ("Effects", SRD 5.2.1, p. 106): damage
/// ("Damage Rolls", p. 16), Hit Point restoration ("Healing", p. 17),
/// Temporary Hit Points ("Temporary Hit Points", p. 18) and a Condition
/// ("Condition", p. 179). Everything else the description says stays in the
/// text. Switch over the family exhaustively, with no default branch.
@immutable
sealed class SpellOutcome {
  const SpellOutcome();
}

/// Whether an amount adds the spellcasting ability modifier, as "Cure Wounds"
/// prints "2d8 plus your spellcasting ability modifier" (SRD 5.2.1, p. 121)
/// (FR-047).
enum ModifierAddition {
  /// No modifier is added.
  none,

  /// The spellcasting ability modifier is added.
  spellcastingAbilityModifier,
}

/// The damage type of a [SpellDealsDamage], as the spell prints it: a fixed
/// type, or a closed set the caster chooses one of (FR-044).
///
/// Chromatic Orb prints "Choose Acid, Cold, Fire, Lightning, Poison, or
/// Thunder" (SRD 5.2.1, p. 115). Switch over the family exhaustively, with no
/// default branch.
@immutable
sealed class DamageTypeSelection {
  const DamageTypeSelection();
}

/// The damage type is fixed by the spell.
@immutable
final class FixedDamageType extends DamageTypeSelection {
  /// Wraps the fixed [type].
  const FixedDamageType(this.type);

  /// The spell's damage type.
  final DamageType type;

  @override
  bool operator ==(Object other) =>
      other is FixedDamageType && other.type == type;

  @override
  int get hashCode => Object.hash(FixedDamageType, type);

  @override
  String toString() => 'FixedDamageType(${type.jsonValue})';
}

/// The caster chooses one of a closed set of damage types (FR-044).
@immutable
final class ChosenDamageType extends DamageTypeSelection {
  /// Creates the choice over a defensive copy of [types].
  ///
  /// Throws an [ArgumentError] carrying the name `types` and the offending
  /// value when [types] holds fewer than 2 distinct damage types (FR-027):
  /// a choice of one is a [FixedDamageType]. A model holds at most one
  /// `ChosenDamageType`, because the cast carries a single choice (FR-045);
  /// that rule is `ModelledEffects`'s.
  ChosenDamageType(Set<DamageType> types)
    : types = Set.unmodifiable(_validated(types));

  /// The smallest number of distinct types a choice may offer (FR-027).
  static const int minTypes = 2;

  /// The types the caster chooses from; unmodifiable.
  final Set<DamageType> types;

  static Set<DamageType> _validated(Set<DamageType> types) {
    if (types.length < minTypes) {
      throw ArgumentError.value(
        types,
        'types',
        'must offer at least $minTypes distinct damage types',
      );
    }
    return types;
  }

  @override
  bool operator ==(Object other) =>
      other is ChosenDamageType &&
      const SetEquality<DamageType>().equals(other.types, types);

  @override
  int get hashCode => const SetEquality<DamageType>().hash(types);

  @override
  String toString() =>
      'ChosenDamageType(${types.map((t) => t.jsonValue).toSet()})';
}

/// How long a condition lasts, as the spell prints it, sealed with exactly
/// the three printed shapes (FR-046).
///
/// Hold Person applies Paralyzed "for the duration" (SRD 5.2.1, p. 141); Ray
/// of Sickness poisons "until the end of your next turn" (p. 158); other
/// spells print a Time Span ("Duration", p. 106). Switch over the family
/// exhaustively, with no default branch.
@immutable
sealed class ConditionDuration {
  const ConditionDuration();
}

/// The condition lasts for the spell's duration (FR-046).
@immutable
final class ForSpellDuration extends ConditionDuration {
  /// The single shape; the printed phrase carries no data.
  const ForSpellDuration();

  @override
  bool operator ==(Object other) => other is ForSpellDuration;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'ForSpellDuration()';
}

/// The condition lasts a printed Time Span (FR-046).
@immutable
final class TimedConditionDuration extends ConditionDuration {
  /// Creates the duration of [amount] [unit].
  ///
  /// Throws an [ArgumentError] carrying the name `amount` and the offending
  /// value when [amount] is below 1 (FR-046).
  TimedConditionDuration(int amount, this.unit)
    : amount = _validatedAmount(amount);

  /// The printed length.
  final int amount;

  /// The unit the length is counted in ("Duration" (Time Span),
  /// SRD 5.2.1, p. 106).
  final DurationUnit unit;

  static int _validatedAmount(int amount) {
    if (amount < 1) {
      throw ArgumentError.value(amount, 'amount', 'must be at least 1');
    }
    return amount;
  }

  @override
  bool operator ==(Object other) =>
      other is TimedConditionDuration &&
      other.amount == amount &&
      other.unit == unit;

  @override
  int get hashCode => Object.hash(TimedConditionDuration, amount, unit);

  @override
  String toString() => 'TimedConditionDuration($amount, ${unit.jsonValue})';
}

/// Whose next turn an "until the end of your next turn" boundary belongs to:
/// the caster's ("your") or the target's. Package terms (FR-046).
///
/// Not the `TurnHolder` (`player`/`gameMaster`) of the magical-effects rules,
/// which renamed its type so the two never share a name in the barrels.
enum TurnOwner {
  /// The caster's turn.
  caster,

  /// The target's turn.
  target,
}

/// Which boundary of the turn: its start or its end (FR-046).
enum TurnBoundary {
  /// The start of the turn.
  start,

  /// The end of the turn.
  end,
}

/// The condition lasts until a boundary of a turn (FR-046).
@immutable
final class UntilNextTurnBoundary extends ConditionDuration {
  /// Wraps the printed [owner] and [boundary].
  const UntilNextTurnBoundary(this.owner, this.boundary);

  /// Whose turn the boundary is on.
  final TurnOwner owner;

  /// Which boundary of the turn.
  final TurnBoundary boundary;

  @override
  bool operator ==(Object other) =>
      other is UntilNextTurnBoundary &&
      other.owner == owner &&
      other.boundary == boundary;

  @override
  int get hashCode => Object.hash(UntilNextTurnBoundary, owner, boundary);

  @override
  String toString() => 'UntilNextTurnBoundary($owner, $boundary)';
}

/// Damage of a chosen or fixed type (FR-047).
@immutable
final class SpellDealsDamage extends SpellOutcome {
  /// Wraps the printed [amount], [type] and [addsModifier].
  const SpellDealsDamage(this.amount, this.type, this.addsModifier);

  /// The damage dealt.
  final ScalableAmount amount;

  /// The damage type.
  final DamageTypeSelection type;

  /// Whether the spellcasting ability modifier is added.
  final ModifierAddition addsModifier;

  @override
  bool operator ==(Object other) =>
      other is SpellDealsDamage &&
      other.amount == amount &&
      other.type == type &&
      other.addsModifier == addsModifier;

  @override
  int get hashCode => Object.hash(SpellDealsDamage, amount, type, addsModifier);

  @override
  String toString() => 'SpellDealsDamage($amount)';
}

/// Hit Point restoration (FR-047).
@immutable
final class SpellRestoresHitPoints extends SpellOutcome {
  /// Wraps the printed [amount] and [addsModifier].
  const SpellRestoresHitPoints(this.amount, this.addsModifier);

  /// The Hit Points restored.
  final ScalableAmount amount;

  /// Whether the spellcasting ability modifier is added.
  final ModifierAddition addsModifier;

  @override
  bool operator ==(Object other) =>
      other is SpellRestoresHitPoints &&
      other.amount == amount &&
      other.addsModifier == addsModifier;

  @override
  int get hashCode => Object.hash(SpellRestoresHitPoints, amount, addsModifier);

  @override
  String toString() => 'SpellRestoresHitPoints($amount)';
}

/// Temporary Hit Points granted (FR-047).
@immutable
final class SpellGrantsTemporaryHitPoints extends SpellOutcome {
  /// Wraps the printed [amount] and [addsModifier].
  const SpellGrantsTemporaryHitPoints(this.amount, this.addsModifier);

  /// The Temporary Hit Points granted.
  final ScalableAmount amount;

  /// Whether the spellcasting ability modifier is added.
  final ModifierAddition addsModifier;

  @override
  bool operator ==(Object other) =>
      other is SpellGrantsTemporaryHitPoints &&
      other.amount == amount &&
      other.addsModifier == addsModifier;

  @override
  int get hashCode =>
      Object.hash(SpellGrantsTemporaryHitPoints, amount, addsModifier);

  @override
  String toString() => 'SpellGrantsTemporaryHitPoints($amount)';
}

/// A condition applied (FR-047, FR-028).
///
/// Any of the fifteen [ConditionKind] values is accepted (the closed set is
/// owned upstream); for Exhaustion one application adds one level.
@immutable
final class SpellAppliesCondition extends SpellOutcome {
  /// Wraps the applied [kind] and its [duration].
  const SpellAppliesCondition(this.kind, this.duration);

  /// The condition applied ("Condition", SRD 5.2.1, p. 179).
  final ConditionKind kind;

  /// How long the condition lasts.
  final ConditionDuration duration;

  @override
  bool operator ==(Object other) =>
      other is SpellAppliesCondition &&
      other.kind == kind &&
      other.duration == duration;

  @override
  int get hashCode => Object.hash(SpellAppliesCondition, kind, duration);

  @override
  String toString() => 'SpellAppliesCondition(${kind.jsonValue})';
}
