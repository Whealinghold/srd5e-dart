import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import '../damage_type.dart';

/// One answer to a derived spell fact (FR-022): known, carrying [value], or
/// unknown because the description text is the only source.
///
/// "Unknown" is never "no": a consumer MUST NOT read [FactUnknown] as a
/// negative answer (FR-024). Switch over the family exhaustively, with no
/// default branch.
@immutable
sealed class EffectFact<T> {
  const EffectFact();
}

/// The fact is known from the modelled parts (FR-022).
@immutable
final class FactKnown<T> extends EffectFact<T> {
  /// Carries the known [value].
  const FactKnown(this.value);

  /// The known fact.
  final T value;

  @override
  bool operator ==(Object other) {
    if (other is! FactKnown<T>) {
      return false;
    }
    final mine = value;
    final theirs = other.value;
    if (mine is Set<DamageType> && theirs is Set<DamageType>) {
      return const SetEquality<DamageType>().equals(mine, theirs);
    }
    return mine == theirs;
  }

  @override
  int get hashCode {
    final mine = value;
    return Object.hash(
      FactKnown,
      mine is Set<DamageType>
          ? const SetEquality<DamageType>().hash(mine)
          : mine,
    );
  }

  @override
  String toString() => 'FactKnown($value)';
}

/// The model does not know the fact, because the coverage is `partial` or the
/// spell is text-only (FR-023, FR-024).
@immutable
final class FactUnknown<T> extends EffectFact<T> {
  /// The single shape; unknown carries no data.
  const FactUnknown();

  @override
  bool operator ==(Object other) => other is FactUnknown<T>;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'FactUnknown()';
}

/// The five derived spell facts (FR-022).
///
/// The authoritative definition of these facts: the class specs' private
/// spell-fact types read them instead of holding their own tables. Each fact
/// is an [EffectFact]: known when the modelled parts show it (in any
/// coverage), known-false and the damage types known only when the coverage
/// is `complete`, and unknown when the coverage is `partial` or the spell is
/// text-only (FR-023, FR-024).
@immutable
final class SpellEffectFacts {
  /// Creates the facts from the five answers.
  const SpellEffectFacts({
    required this.forcesSavingThrow,
    required this.makesSpellAttackRoll,
    required this.dealsDamage,
    required this.damageTypes,
    required this.canTargetMoreWithHigherSlot,
  });

  /// Whether the spell forces a saving throw.
  final EffectFact<bool> forcesSavingThrow;

  /// Whether the spell makes a spell attack roll.
  final EffectFact<bool> makesSpellAttackRoll;

  /// Whether the spell deals damage.
  final EffectFact<bool> dealsDamage;

  /// The damage types the spell deals.
  final EffectFact<Set<DamageType>> damageTypes;

  /// Whether a higher slot level adds targets (a [PerSlotLevelCount] on the
  /// targets' count). More instances — darts, rays — are not additional
  /// targets (FR-022).
  final EffectFact<bool> canTargetMoreWithHigherSlot;

  @override
  bool operator ==(Object other) =>
      other is SpellEffectFacts &&
      other.forcesSavingThrow == forcesSavingThrow &&
      other.makesSpellAttackRoll == makesSpellAttackRoll &&
      other.dealsDamage == dealsDamage &&
      other.damageTypes == damageTypes &&
      other.canTargetMoreWithHigherSlot == canTargetMoreWithHigherSlot;

  @override
  int get hashCode => Object.hash(
    SpellEffectFacts,
    forcesSavingThrow,
    makesSpellAttackRoll,
    dealsDamage,
    damageTypes,
    canTargetMoreWithHigherSlot,
  );

  @override
  String toString() =>
      'SpellEffectFacts($forcesSavingThrow, $makesSpellAttackRoll, '
      '$dealsDamage, $damageTypes, $canTargetMoreWithHigherSlot)';
}
