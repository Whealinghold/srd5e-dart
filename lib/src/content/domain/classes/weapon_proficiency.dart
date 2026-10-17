import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import '../weapon_property.dart';

/// One of the two weapon training categories of the Core Traits tables
/// ("Weapon Proficiencies" rows, SRD 5.2.1, pp. 28, 31, 36, 41, 47, 49, 53,
/// 57, 61, 64, 70, 77), in SRD order (FR-021).
///
/// The JSON spelling is the SRD's own word.
enum WeaponTrainingCategory {
  /// Simple weapons.
  simple('Simple'),

  /// Martial weapons.
  martial('Martial');

  const WeaponTrainingCategory(this.jsonValue);

  /// The printed word used in JSON.
  final String jsonValue;

  /// The member whose [jsonValue] is [value], or null for a non-member: the
  /// decoder turns a non-member into `invalidValue` (FR-105, FR-025).
  static WeaponTrainingCategory? fromJson(String value) => switch (value) {
    'Simple' => simple,
    'Martial' => martial,
    _ => null,
  };
}

/// One weapon proficiency of a class: a [WeaponTrainingCategory] and the
/// optional weapon properties a weapon of the category must have (FR-021).
///
/// A [requiresAnyProperty] narrows the category to the weapons that have at
/// least one of the listed properties (the Monk's "Martial weapons that have
/// the Light property", the Rogue's Finesse or Light); absent, it covers
/// every weapon of the category. The properties are a filter the consumer
/// applies; the type holds the fact only.
@immutable
final class WeaponProficiency {
  /// Creates a weapon proficiency from a defensive copy of the filter.
  ///
  /// Throws an [ArgumentError] carrying the name `requiresAnyProperty` and
  /// the offending value when the property filter is present but empty or
  /// holds a property twice (FR-021).
  WeaponProficiency(this.category, {List<WeaponProperty>? requiresAnyProperty})
    : requiresAnyProperty = requiresAnyProperty == null
          ? null
          : List.unmodifiable(_validatedProperties(requiresAnyProperty));

  /// The category of weapons the proficiency covers (FR-021).
  final WeaponTrainingCategory category;

  /// The properties a weapon must have at least one of, or null when the
  /// proficiency covers every weapon of the [category]; unmodifiable, never
  /// empty when present (FR-021).
  final List<WeaponProperty>? requiresAnyProperty;

  /// Whether [proficiencies] holds at most one element per category, as
  /// FR-021 requires of every list that holds them. The predicate the
  /// decoder reuses (FR-007).
  static bool hasUniqueCategories(List<WeaponProficiency> proficiencies) {
    for (var i = 1; i < proficiencies.length; i++) {
      final category = proficiencies[i].category;
      if (proficiencies
          .sublist(0, i)
          .any((proficiency) => proficiency.category == category)) {
        return false;
      }
    }
    return true;
  }

  /// Whether [core] covers every weapon the [grant] proficiency covers
  /// (FR-026): the same [WeaponTrainingCategory], and the grant's property
  /// filter covered by the core's — an absent grant filter (every weapon of
  /// the category) needs an absent core filter, and a present one needs the
  /// core filter absent or holding every property of the grant. The
  /// predicate the decoder reuses (FR-007).
  static bool covers(WeaponProficiency core, WeaponProficiency grant) {
    if (core.category != grant.category) return false;
    final grantFilter = grant.requiresAnyProperty;
    final coreFilter = core.requiresAnyProperty;
    if (grantFilter == null) return coreFilter == null;
    if (coreFilter == null) return true;
    return grantFilter.every(coreFilter.contains);
  }

  /// Throws the [ArgumentError] the [hasUniqueCategories] predicate answers,
  /// so every list of weapon proficiencies rejects a repeated category with
  /// the same error (FR-021, FR-026). [name] is the argument name the error
  /// carries.
  static void requireUniqueCategories(
    List<WeaponProficiency> proficiencies, {
    String name = 'weaponProficiencies',
  }) {
    if (!hasUniqueCategories(proficiencies)) {
      throw ArgumentError.value(
        proficiencies,
        name,
        'must hold at most one proficiency per category',
      );
    }
  }

  static List<WeaponProperty> _validatedProperties(
    List<WeaponProperty> properties,
  ) {
    if (properties.isEmpty) {
      throw ArgumentError.value(
        properties,
        'requiresAnyProperty',
        'must be absent or non-empty',
      );
    }
    for (var i = 1; i < properties.length; i++) {
      if (properties.indexOf(properties[i]) != i) {
        throw ArgumentError.value(
          properties[i],
          'requiresAnyProperty',
          'must be distinct',
        );
      }
    }
    return properties;
  }

  @override
  bool operator ==(Object other) =>
      other is WeaponProficiency &&
      other.category == category &&
      _sameProperties(other.requiresAnyProperty, requiresAnyProperty);

  @override
  int get hashCode => Object.hash(
    WeaponProficiency,
    category,
    requiresAnyProperty == null
        ? null
        : const ListEquality<WeaponProperty>().hash(requiresAnyProperty!),
  );

  @override
  String toString() =>
      'WeaponProficiency($category'
      '${requiresAnyProperty == null ? '' : ', any of $requiresAnyProperty'})';

  static bool _sameProperties(
    List<WeaponProperty>? a,
    List<WeaponProperty>? b,
  ) {
    if (a == null || b == null) return a == b;
    return const ListEquality<WeaponProperty>().equals(a, b);
  }
}
