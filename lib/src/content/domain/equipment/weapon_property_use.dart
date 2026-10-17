import 'package:meta/meta.dart';

import '../../../shared_kernel/dice/dice_expression.dart';
import '../weapon_property.dart';

/// A printed range pair "X ft. / Y ft." (FR-103).
///
/// A value object holding the normal and long ranges of an Ammunition or
/// Thrown weapon property.
@immutable
final class RangePair {
  /// The smallest [normal] range a property may print (FR-111). The constant
  /// the decoder reuses instead of repeating the literal (FR-094).
  static const int minNormal = 1;

  /// Creates the pair of [normal] and [long] range.
  ///
  /// Throws an [ArgumentError] carrying the name `normal` or `long` and the
  /// offending value when [normal] is below 1 or [long] is not greater than
  /// [normal].
  RangePair(int normal, int long)
    : normal = _validatedNormal(normal),
      long = _validatedLong(long, normal);

  /// The normal range, in feet.
  final int normal;

  /// The long range, in feet, greater than [normal].
  final int long;

  static int _validatedNormal(int normal) {
    if (normal < 1) {
      throw ArgumentError.value(normal, 'normal', 'must be at least 1');
    }
    return normal;
  }

  static int _validatedLong(int long, int normal) {
    if (long <= normal) {
      throw ArgumentError.value(long, 'long', 'must be greater than normal');
    }
    return long;
  }

  @override
  bool operator ==(Object other) =>
      other is RangePair && other.normal == normal && other.long == long;

  @override
  int get hashCode => Object.hash(RangePair, normal, long);

  @override
  String toString() => 'RangePair($normal, $long)';
}

/// The ammunition a ranged weapon uses (FR-103).
///
/// The wire spelling is the printed word. A weapon keeps its printed label
/// only: the Firearm and Sling Bullets are not distinguished here ("Bullets,
/// Firearm" and "Bullets, Sling" are equipment entries, not this enum).
enum AmmunitionType {
  /// Arrows.
  arrow('Arrow'),

  /// Crossbow bolts.
  bolt('Bolt'),

  /// Firearm and sling bullets, as printed ("Bullets (Firearm)",
  /// "Bullets (Sling)", SRD 5.2.1, p. 91).
  bullet('Bullet'),

  /// Blowgun needles.
  needle('Needle');

  const AmmunitionType(this.jsonValue);

  /// The printed word used in JSON.
  final String jsonValue;

  /// The member whose [jsonValue] is [value], or null for a non-member: the
  /// decoder turns a non-member into `invalidValue` (FR-105, FR-111).
  static AmmunitionType? fromJson(String value) => switch (value) {
    'Arrow' => arrow,
    'Bolt' => bolt,
    'Bullet' => bullet,
    'Needle' => needle,
    _ => null,
  };
}

/// The printed condition of a Two-Handed weapon (FR-103).
enum TwoHandedCondition {
  /// Two-Handed with no printed condition: always used with two hands.
  always('always'),

  /// The Lance's "unless mounted" (SRD 5.2.1, p. 91).
  unlessMounted('unless mounted');

  const TwoHandedCondition(this.jsonValue);

  /// The printed form used in JSON.
  final String jsonValue;

  /// The member whose [jsonValue] is [value], or null for a non-member: the
  /// decoder turns a non-member into `invalidValue` (FR-105, FR-111).
  static TwoHandedCondition? fromJson(String value) => switch (value) {
    'always' => always,
    'unless mounted' => unlessMounted,
    _ => null,
  };
}

/// One use of a weapon property, as the Weapons table prints it (FR-103).
///
/// The sealed family holds the five printed shapes: a bare property word
/// ([PlainUse]), Ammunition and Thrown with their "Range X ft. / Y ft."
/// notation, Versatile with its parenthesised damage, and Two-Handed with its
/// optional condition. Switch over it exhaustively, with no default branch.
@immutable
sealed class WeaponPropertyUse {
  const WeaponPropertyUse();

  /// The property this use is of.
  WeaponProperty get property;
}

/// A property printed as its word alone: Finesse, Heavy, Light, Loading or
/// Reach (FR-103).
@immutable
final class PlainUse extends WeaponPropertyUse {
  /// Creates the use of [property].
  ///
  /// Throws an [ArgumentError] carrying the name `property` and the offending
  /// value when [property] is not one of the five plain properties: the other
  /// four have data and are held by the other variants.
  PlainUse(this.property) {
    if (!_plain.contains(property)) {
      throw ArgumentError.value(
        property,
        'property',
        'is not a property printed without data',
      );
    }
  }

  /// The properties printed without data (FR-103).
  static const List<WeaponProperty> _plain = [
    WeaponProperty.finesse,
    WeaponProperty.heavy,
    WeaponProperty.light,
    WeaponProperty.loading,
    WeaponProperty.reach,
  ];

  /// Whether [property] is printed without data: a valid [PlainUse] (FR-103).
  static bool isPlain(WeaponProperty property) => _plain.contains(property);

  @override
  final WeaponProperty property;

  @override
  bool operator ==(Object other) =>
      other is PlainUse && other.property == property;

  @override
  int get hashCode => Object.hash(PlainUse, property);

  @override
  String toString() => 'PlainUse(${property.jsonValue})';
}

/// The Ammunition property with its "Range X ft. / Y ft." notation and
/// ammunition type (FR-103).
@immutable
final class AmmunitionUse extends WeaponPropertyUse {
  /// Creates the Ammunition use over [range] of [ammunition].
  const AmmunitionUse(this.range, this.ammunition);

  /// The printed "Range X ft. / Y ft." notation.
  final RangePair range;

  /// The ammunition the weapon uses.
  final AmmunitionType ammunition;

  @override
  WeaponProperty get property => WeaponProperty.ammunition;

  @override
  bool operator ==(Object other) =>
      other is AmmunitionUse &&
      other.range == range &&
      other.ammunition == ammunition;

  @override
  int get hashCode => Object.hash(AmmunitionUse, range, ammunition);

  @override
  String toString() => 'AmmunitionUse($range, ${ammunition.jsonValue})';
}

/// The Thrown property with its "Range X ft. / Y ft." notation (FR-103).
@immutable
final class ThrownUse extends WeaponPropertyUse {
  /// Creates the Thrown use over [range].
  const ThrownUse(this.range);

  /// The printed "Range X ft. / Y ft." notation.
  final RangePair range;

  @override
  WeaponProperty get property => WeaponProperty.thrown;

  @override
  bool operator ==(Object other) => other is ThrownUse && other.range == range;

  @override
  int get hashCode => Object.hash(ThrownUse, range);

  @override
  String toString() => 'ThrownUse($range)';
}

/// The Versatile property with its parenthesised two-handed damage (FR-103).
@immutable
final class VersatileUse extends WeaponPropertyUse {
  /// Creates the Versatile use with the two-handed [damage].
  const VersatileUse(this.damage);

  /// The damage printed in parentheses, such as a Longsword's "1d10".
  final DiceExpression damage;

  @override
  WeaponProperty get property => WeaponProperty.versatile;

  @override
  bool operator ==(Object other) =>
      other is VersatileUse && other.damage == damage;

  @override
  int get hashCode => Object.hash(VersatileUse, damage);

  @override
  String toString() => 'VersatileUse($damage)';
}

/// The Two-Handed property, with its condition when one is printed (FR-103).
@immutable
final class TwoHandedUse extends WeaponPropertyUse {
  /// Creates the Two-Handed use with the printed [condition].
  const TwoHandedUse(this.condition);

  /// The printed condition, or [TwoHandedCondition.always] when the table
  /// prints none.
  final TwoHandedCondition condition;

  @override
  WeaponProperty get property => WeaponProperty.twoHanded;

  @override
  bool operator ==(Object other) =>
      other is TwoHandedUse && other.condition == condition;

  @override
  int get hashCode => Object.hash(TwoHandedUse, condition);

  @override
  String toString() => 'TwoHandedUse(${condition.jsonValue})';
}
