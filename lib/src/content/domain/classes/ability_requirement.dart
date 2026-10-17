import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import '../../../shared_kernel/ability/ability.dart';

/// The abilities a class names as its Primary Ability ("Class Overview",
/// SRD 5.2.1, p. 19) (FR-011).
///
/// The SRD prints two shapes: a single ability or several abilities all of
/// which matter ("Strength and Charisma", the Sorcerer), and several of
/// which any one matters ("Strength or Dexterity", the Fighter). The type is
/// sealed with exactly the two variants, exhaustive in a `switch` without a
/// default (FR-011).
///
/// The type only answers whether a set of abilities [isMetBy]s it; the
/// threshold that decides which abilities "meet" the requirement belongs to
/// the rule owner (character-aggregate.md), never to this type (FR-014).
@immutable
sealed class AbilityRequirement {
  AbilityRequirement._(List<Ability> abilities)
    : abilities = List.unmodifiable(abilities);

  /// The abilities, in printed order; unmodifiable (FR-015).
  final List<Ability> abilities;

  /// Whether [meeting] satisfies this requirement (FR-014): every listed
  /// ability for [AllOf], at least one for [AnyOf]. Abilities in [meeting]
  /// that the requirement does not list are ignored.
  bool isMetBy(Set<Ability> meeting);
}

/// A Primary Ability of one ability or of several that all matter: the
/// Barbarian's "Strength" and the Sorcerer's "Charisma" are `AllOf` of one
/// (FR-012; SRD 5.2.1, "Core Barbarian Traits", p. 28, "Core Sorcerer
/// Traits", p. 64).
@immutable
final class AllOf extends AbilityRequirement {
  /// Creates the requirement from a defensive copy of [abilities].
  ///
  /// Throws an [ArgumentError] carrying the name `abilities` and the
  /// offending value when [abilities] is empty (an `AllOf` holds at least
  /// one ability) or holds an ability twice.
  AllOf(List<Ability> abilities) : super._(_validated(abilities));

  /// The fewest abilities an [AllOf] may hold: one (FR-012). The constant
  /// the decoder reuses instead of repeating the literal (FR-007).
  static const int minAbilities = 1;

  /// Whether [abilities] is a list an [AllOf] may hold: at least
  /// [minAbilities] distinct abilities (FR-012). The predicate the decoder
  /// reuses (FR-007).
  static bool isValid(List<Ability> abilities) {
    if (abilities.length < minAbilities) return false;
    for (var i = 1; i < abilities.length; i++) {
      if (abilities.indexOf(abilities[i]) != i) return false;
    }
    return true;
  }

  static List<Ability> _validated(List<Ability> abilities) {
    if (abilities.length < minAbilities) {
      throw ArgumentError.value(
        abilities,
        'abilities',
        'must hold at least $minAbilities ability',
      );
    }
    for (var i = 1; i < abilities.length; i++) {
      if (abilities.indexOf(abilities[i]) != i) {
        throw ArgumentError.value(
          abilities[i],
          'abilities',
          'must be distinct',
        );
      }
    }
    return abilities;
  }

  @override
  bool isMetBy(Set<Ability> meeting) => meeting.containsAll(abilities);

  @override
  bool operator ==(Object other) =>
      other is AllOf &&
      const ListEquality<Ability>().equals(other.abilities, abilities);

  @override
  int get hashCode =>
      Object.hash(AllOf, const ListEquality<Ability>().hash(abilities));

  @override
  String toString() => 'AllOf($abilities)';
}

/// A Primary Ability of several abilities, any one of which matters: the
/// Fighter's "Strength or Dexterity" (FR-013; SRD 5.2.1, "Core Fighter
/// Traits", p. 47).
///
/// `AnyOf` of one is the same fact as `AllOf` of one and is not
/// representable (FR-013, D14): the constructor requires at least two.
@immutable
final class AnyOf extends AbilityRequirement {
  /// Creates the requirement from a defensive copy of [abilities].
  ///
  /// Throws an [ArgumentError] carrying the name `abilities` and the
  /// offending value when [abilities] holds fewer than [minAbilities]
  /// abilities or holds one twice.
  AnyOf(List<Ability> abilities) : super._(_validated(abilities));

  /// The fewest abilities an [AnyOf] may hold: two (FR-013). The constant
  /// the decoder reuses instead of repeating the literal (FR-007).
  static const int minAbilities = 2;

  /// Whether [abilities] is a list an [AnyOf] may hold: at least
  /// [minAbilities] distinct abilities (FR-013). The predicate the decoder
  /// reuses (FR-007).
  static bool isValid(List<Ability> abilities) {
    if (abilities.length < minAbilities) return false;
    for (var i = 1; i < abilities.length; i++) {
      if (abilities.indexOf(abilities[i]) != i) return false;
    }
    return true;
  }

  static List<Ability> _validated(List<Ability> abilities) {
    if (abilities.length < minAbilities) {
      throw ArgumentError.value(
        abilities,
        'abilities',
        'must hold at least $minAbilities abilities',
      );
    }
    for (var i = 1; i < abilities.length; i++) {
      if (abilities.indexOf(abilities[i]) != i) {
        throw ArgumentError.value(
          abilities[i],
          'abilities',
          'must be distinct',
        );
      }
    }
    return abilities;
  }

  @override
  bool isMetBy(Set<Ability> meeting) => abilities.any(meeting.contains);

  @override
  bool operator ==(Object other) =>
      other is AnyOf &&
      const ListEquality<Ability>().equals(other.abilities, abilities);

  @override
  int get hashCode =>
      Object.hash(AnyOf, const ListEquality<Ability>().hash(abilities));

  @override
  String toString() => 'AnyOf($abilities)';
}
