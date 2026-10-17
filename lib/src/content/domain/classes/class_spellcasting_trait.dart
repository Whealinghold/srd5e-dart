import 'package:meta/meta.dart';

import '../../../shared_kernel/ability/ability.dart';

/// The spellcasting rule a class uses, from the "Level 1: Spellcasting" and
/// "Level 1: Pact Magic" headings (SRD 5.2.1, pp. 32, 36, 41, 54, 57, 64,
/// 77, 71) (FR-028).
///
/// The type is sealed with exactly the two variants, exhaustive in a
/// `switch` without a default. It is named `...Trait` because
/// `ClassSpellcasting` is spellcasting.md state (shared-types-and-ownership
/// .md FR-021): this is the data the state is built from.
@immutable
sealed class ClassSpellcastingTrait {
  const ClassSpellcastingTrait._(this.ability);

  /// The spellcasting ability ("Spellcasting Ability" sentences, SRD 5.2.1,
  /// pp. 32, 37, 42, 54, 58, 65, 72, 78).
  final Ability ability;
}

/// The standard spellcasting rule of the half and full casters: the class
/// prepares spells and, when [cantrips] is true, knows cantrips (FR-028).
@immutable
final class SlotSpellcastingTrait extends ClassSpellcastingTrait {
  /// Creates the trait.
  const SlotSpellcastingTrait(super.ability, {required this.cantrips})
    : super._();

  /// Whether the class learns cantrips; every slot row then carries a
  /// cantrips count (FR-028, FR-031).
  final bool cantrips;

  @override
  bool operator ==(Object other) =>
      other is SlotSpellcastingTrait &&
      other.ability == ability &&
      other.cantrips == cantrips;

  @override
  int get hashCode => Object.hash(SlotSpellcastingTrait, ability, cantrips);

  @override
  String toString() => 'SlotSpellcastingTrait($ability, cantrips: $cantrips)';
}

/// The Warlock's Pact Magic rule (FR-028; SRD 5.2.1, "Level 1: Pact Magic",
/// p. 71).
@immutable
final class PactSpellcastingTrait extends ClassSpellcastingTrait {
  /// Creates the trait.
  const PactSpellcastingTrait(super.ability) : super._();

  @override
  bool operator ==(Object other) =>
      other is PactSpellcastingTrait && other.ability == ability;

  @override
  int get hashCode => Object.hash(PactSpellcastingTrait, ability);

  @override
  String toString() => 'PactSpellcastingTrait($ability)';
}
