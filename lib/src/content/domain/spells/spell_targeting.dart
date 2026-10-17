import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import '../creature_type.dart';
import 'spell_scaling.dart';

/// What a spell's targets are, as "Targets" prints it: "creatures, objects,
/// or something else" (SRD 5.2.1, p. 106) (FR-011).
///
/// A target that is something else — a point, a location — is not modelled; a
/// spell whose effect depends on one is `partial` or text-only (FR-011).
enum TargetSubject {
  /// Creatures.
  creature,

  /// Objects.
  object,

  /// Creatures or objects, as Fire Bolt prints "a creature or an object"
  /// (SRD 5.2.1, p. 132).
  creatureOrObject,
}

/// Whether a spell whose targets are chosen may include the caster
/// ("Targeting Yourself", SRD 5.2.1, p. 106) (FR-040).
///
/// [excludesCaster] states the SRD exceptions "the creature must be Hostile
/// or specifically a creature other than you"; that a creature really is
/// Hostile is the host's fact and is not modelled (FR-040).
enum SelfTargetPolicy {
  /// The default: the caster may include themself.
  mayIncludeCaster,

  /// The caster is excluded.
  excludesCaster,
}

/// How many targets a spell takes, sealed with the three printed shapes
/// (FR-012).
///
/// "Targets" prints "one or more creatures" (SRD 5.2.1, p. 106); Magic
/// Missile throws three darts, one per assigned target (p. 146). Either
/// counted variant may carry a [CountScaling] (FR-012); [TargetsByInstance]
/// means the targets are those the part's instances are assigned to.
/// Switch over the family exhaustively, with no default branch.
@immutable
sealed class TargetCount {
  const TargetCount();
}

/// Exactly [n] targets (FR-012).
@immutable
final class ExactlyTargets extends TargetCount {
  /// Creates the count of [n], scaled by [scaling].
  ///
  /// Throws an [ArgumentError] carrying the name `n` and the offending value
  /// when [n] is below 1 (FR-012).
  ExactlyTargets(int n, {this.scaling = const NoCountScaling()})
    : n = _validatedN(n);

  /// The printed count, at least 1.
  final int n;

  /// How the count grows with the slot level or the character level.
  final CountScaling scaling;

  @override
  bool operator ==(Object other) =>
      other is ExactlyTargets && other.n == n && other.scaling == scaling;

  @override
  int get hashCode => Object.hash(ExactlyTargets, n, scaling);

  @override
  String toString() => 'ExactlyTargets($n, scaling: $scaling)';
}

/// Up to [n] targets (FR-012).
@immutable
final class UpToTargets extends TargetCount {
  /// Creates the maximum count of [n], scaled by [scaling].
  ///
  /// Throws an [ArgumentError] carrying the name `n` and the offending value
  /// when [n] is below 1 (FR-012).
  UpToTargets(int n, {this.scaling = const NoCountScaling()})
    : n = _validatedN(n);

  /// The printed maximum count, at least 1.
  final int n;

  /// How the count grows with the slot level or the character level.
  final CountScaling scaling;

  @override
  bool operator ==(Object other) =>
      other is UpToTargets && other.n == n && other.scaling == scaling;

  @override
  int get hashCode => Object.hash(UpToTargets, n, scaling);

  @override
  String toString() => 'UpToTargets($n, scaling: $scaling)';
}

/// The targets are those the part's instances are assigned to, one per
/// instance (FR-012): Magic Missile's darts (SRD 5.2.1, p. 146).
@immutable
final class TargetsByInstance extends TargetCount {
  /// The single shape; the assignment carries no count data.
  const TargetsByInstance();

  @override
  bool operator ==(Object other) => other is TargetsByInstance;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'TargetsByInstance()';
}

int _validatedN(int n) {
  if (n < 1) {
    throw ArgumentError.value(n, 'n', 'must be at least 1');
  }
  return n;
}

/// Which creatures a spell's targets may be, sealed with the two printed
/// shapes (FR-015).
///
/// Most spells target any creature; Hold Person targets "a Humanoid"
/// (SRD 5.2.1, p. 141). A restriction describes creatures only: which listed
/// target is invalid under it is the spell-effects rules' concern. Switch
/// over the family exhaustively, with no default branch.
@immutable
sealed class CreatureTypeRestriction {
  const CreatureTypeRestriction();
}

/// Any creature is a valid target.
@immutable
final class AnyCreatureType extends CreatureTypeRestriction {
  /// The single shape; an unrestricted target list carries no data.
  const AnyCreatureType();

  @override
  bool operator ==(Object other) => other is AnyCreatureType;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'AnyCreatureType()';
}

/// Only creatures of the listed types are valid targets (FR-015).
@immutable
final class OnlyCreatureTypes extends CreatureTypeRestriction {
  /// Creates the restriction over a defensive copy of [types].
  ///
  /// Throws an [ArgumentError] carrying the name `types` and the offending
  /// value when [types] is empty (FR-015); that a restriction other than
  /// [AnyCreatureType] is rejected for an [TargetSubject.object] subject is
  /// checked by `TargetsChosen` and `TargetsInArea`, which hold both values
  /// (table T2).
  OnlyCreatureTypes(Set<CreatureType> types)
    : types = Set.unmodifiable(_validated(types));

  /// The creature types allowed; unmodifiable, never empty.
  final Set<CreatureType> types;

  static Set<CreatureType> _validated(Set<CreatureType> types) {
    if (types.isEmpty) {
      throw ArgumentError.value(types, 'types', 'must hold at least one type');
    }
    return types;
  }

  @override
  bool operator ==(Object other) =>
      other is OnlyCreatureTypes &&
      const SetEquality<CreatureType>().equals(other.types, types);

  @override
  int get hashCode => const SetEquality<CreatureType>().hash(types);

  @override
  String toString() =>
      'OnlyCreatureTypes(${types.map((t) => t.jsonValue).toSet()})';
}

/// One of the six shapes of the "Area of Effect" glossary entry
/// ("Area of Effect", SRD 5.2.1, p. 177), each holding its dimensions in
/// whole feet (FR-013).
///
/// These are the only definitions of the six shapes in the package: the
/// magical-effects rules reuse them and define no second set. Every dimension
/// must be at least 1, else an [ArgumentError]. [includesOrigin] is a static
/// fact per shape (FR-014): the SRD's "unless its creator decides otherwise"
/// is the magical-effects rules' origin override, which leaves this the
/// default. Switch over the family exhaustively, with no default branch.
@immutable
sealed class AreaShape {
  const AreaShape();

  /// Whether the shape includes its origin: false for Cone, Cube, Emanation
  /// and Line; true for Cylinder and Sphere (FR-014, table A).
  bool get includesOrigin;
}

/// A cone, [lengthFeet] feet long ("Cone", SRD 5.2.1, p. 179).
@immutable
final class ConeArea extends AreaShape {
  /// Creates the cone of [lengthFeet] feet.
  ///
  /// Throws an [ArgumentError] carrying the name `lengthFeet` and the
  /// offending value when [lengthFeet] is below 1 (FR-013).
  ConeArea(int lengthFeet) : lengthFeet = _validated(lengthFeet, 'lengthFeet');

  /// The cone's length, in feet.
  final int lengthFeet;

  @override
  bool get includesOrigin => false;

  @override
  bool operator ==(Object other) =>
      other is ConeArea && other.lengthFeet == lengthFeet;

  @override
  int get hashCode => Object.hash(ConeArea, lengthFeet);

  @override
  String toString() => 'ConeArea($lengthFeet)';
}

/// A cube with sides [sideFeet] feet long ("Cube", SRD 5.2.1, p. 179).
@immutable
final class CubeArea extends AreaShape {
  /// Creates the cube of [sideFeet] feet.
  ///
  /// Throws an [ArgumentError] carrying the name `sideFeet` and the offending
  /// value when [sideFeet] is below 1 (FR-013).
  CubeArea(int sideFeet) : sideFeet = _validated(sideFeet, 'sideFeet');

  /// The side length, in feet.
  final int sideFeet;

  @override
  bool get includesOrigin => false;

  @override
  bool operator ==(Object other) =>
      other is CubeArea && other.sideFeet == sideFeet;

  @override
  int get hashCode => Object.hash(CubeArea, sideFeet);

  @override
  String toString() => 'CubeArea($sideFeet)';
}

/// A cylinder of [radiusFeet] feet radius and [heightFeet] feet height
/// ("Cylinder", SRD 5.2.1, p. 180).
@immutable
final class CylinderArea extends AreaShape {
  /// Creates the cylinder of [radiusFeet] and [heightFeet] feet.
  ///
  /// Throws an [ArgumentError] carrying the name `radiusFeet` or `heightFeet`
  /// and the offending value when a dimension is below 1 (FR-013).
  CylinderArea(int radiusFeet, int heightFeet)
    : radiusFeet = _validated(radiusFeet, 'radiusFeet'),
      heightFeet = _validated(heightFeet, 'heightFeet');

  /// The radius, in feet.
  final int radiusFeet;

  /// The height, in feet.
  final int heightFeet;

  @override
  bool get includesOrigin => true;

  @override
  bool operator ==(Object other) =>
      other is CylinderArea &&
      other.radiusFeet == radiusFeet &&
      other.heightFeet == heightFeet;

  @override
  int get hashCode => Object.hash(CylinderArea, radiusFeet, heightFeet);

  @override
  String toString() => 'CylinderArea($radiusFeet, $heightFeet)';
}

/// An emanation reaching [distanceFeet] feet from the origin
/// ("Emanation", SRD 5.2.1, p. 181).
@immutable
final class EmanationArea extends AreaShape {
  /// Creates the emanation of [distanceFeet] feet.
  ///
  /// Throws an [ArgumentError] carrying the name `distanceFeet` and the
  /// offending value when [distanceFeet] is below 1 (FR-013).
  EmanationArea(int distanceFeet)
    : distanceFeet = _validated(distanceFeet, 'distanceFeet');

  /// The distance, in feet.
  final int distanceFeet;

  @override
  bool get includesOrigin => false;

  @override
  bool operator ==(Object other) =>
      other is EmanationArea && other.distanceFeet == distanceFeet;

  @override
  int get hashCode => Object.hash(EmanationArea, distanceFeet);

  @override
  String toString() => 'EmanationArea($distanceFeet)';
}

/// A line [lengthFeet] feet long and [widthFeet] feet wide
/// ("Line", SRD 5.2.1, p. 184).
@immutable
final class LineArea extends AreaShape {
  /// Creates the line of [lengthFeet] and [widthFeet] feet.
  ///
  /// Throws an [ArgumentError] carrying the name `lengthFeet` or `widthFeet`
  /// and the offending value when a dimension is below 1 (FR-013).
  LineArea(int lengthFeet, int widthFeet)
    : lengthFeet = _validated(lengthFeet, 'lengthFeet'),
      widthFeet = _validated(widthFeet, 'widthFeet');

  /// The length, in feet.
  final int lengthFeet;

  /// The width, in feet.
  final int widthFeet;

  @override
  bool get includesOrigin => false;

  @override
  bool operator ==(Object other) =>
      other is LineArea &&
      other.lengthFeet == lengthFeet &&
      other.widthFeet == widthFeet;

  @override
  int get hashCode => Object.hash(LineArea, lengthFeet, widthFeet);

  @override
  String toString() => 'LineArea($lengthFeet, $widthFeet)';
}

/// A sphere of [radiusFeet] feet radius ("Sphere", SRD 5.2.1, p. 188).
@immutable
final class SphereArea extends AreaShape {
  /// Creates the sphere of [radiusFeet] feet.
  ///
  /// Throws an [ArgumentError] carrying the name `radiusFeet` and the
  /// offending value when [radiusFeet] is below 1 (FR-013).
  SphereArea(int radiusFeet)
    : radiusFeet = _validated(radiusFeet, 'radiusFeet');

  /// The radius, in feet.
  final int radiusFeet;

  @override
  bool get includesOrigin => true;

  @override
  bool operator ==(Object other) =>
      other is SphereArea && other.radiusFeet == radiusFeet;

  @override
  int get hashCode => Object.hash(SphereArea, radiusFeet);

  @override
  String toString() => 'SphereArea($radiusFeet)';
}

int _validated(int feet, String name) {
  if (feet < 1) {
    throw ArgumentError.value(feet, name, 'must be at least 1');
  }
  return feet;
}

/// How a spell's targets are picked, sealed with the three printed shapes
/// (FR-010).
///
/// [TargetsSelf] for a spell the caster targets themself with; [TargetsChosen]
/// for targets the caster picks; [TargetsInArea] for everything inside an
/// area. Switch over the family exhaustively, with no default branch.
@immutable
sealed class SpellTargeting {
  const SpellTargeting();
}

/// The spell targets the caster (FR-010).
@immutable
final class TargetsSelf extends SpellTargeting {
  /// The single shape; targeting yourself carries no data. Holds no
  /// [SelfTargetPolicy] (FR-040).
  const TargetsSelf();

  @override
  bool operator ==(Object other) => other is TargetsSelf;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'TargetsSelf()';
}

/// The caster picks the targets (FR-010).
@immutable
final class TargetsChosen extends SpellTargeting {
  /// Creates the targeting of [count] [subject]s under [restriction], with
  /// [selfPolicy] saying whether the caster may include themself (FR-040).
  ///
  /// Throws an [ArgumentError] carrying the name `restriction` and the
  /// offending value when [restriction] limits the creature type while
  /// [subject] is [TargetSubject.object]: a creature restriction describes
  /// creatures only (FR-015, table T2).
  TargetsChosen(
    this.subject,
    this.count,
    this.restriction, {
    this.selfPolicy = SelfTargetPolicy.mayIncludeCaster,
  }) {
    _validateRestriction(restriction, subject);
  }

  /// What the targets are.
  final TargetSubject subject;

  /// How many targets the spell takes.
  final TargetCount count;

  /// Which creatures the targets may be.
  final CreatureTypeRestriction restriction;

  /// Whether the caster may include themself (FR-040).
  final SelfTargetPolicy selfPolicy;

  @override
  bool operator ==(Object other) =>
      other is TargetsChosen &&
      other.subject == subject &&
      other.count == count &&
      other.restriction == restriction &&
      other.selfPolicy == selfPolicy;

  @override
  int get hashCode =>
      Object.hash(TargetsChosen, subject, count, restriction, selfPolicy);

  @override
  String toString() => 'TargetsChosen($subject, $count)';
}

/// The spell targets everything inside an area (FR-010).
@immutable
final class TargetsInArea extends SpellTargeting {
  /// Creates the targeting of the [subject]s inside [shape] under
  /// [restriction].
  ///
  /// Throws an [ArgumentError] carrying the name `restriction` and the
  /// offending value when [restriction] limits the creature type while
  /// [subject] is [TargetSubject.object] (FR-015, table T2). Holds no
  /// [SelfTargetPolicy] (FR-040).
  TargetsInArea(this.shape, this.subject, this.restriction) {
    _validateRestriction(restriction, subject);
  }

  /// The area of effect.
  final AreaShape shape;

  /// What the targets are.
  final TargetSubject subject;

  /// Which creatures the targets may be.
  final CreatureTypeRestriction restriction;

  @override
  bool operator ==(Object other) =>
      other is TargetsInArea &&
      other.shape == shape &&
      other.subject == subject &&
      other.restriction == restriction;

  @override
  int get hashCode => Object.hash(TargetsInArea, shape, subject, restriction);

  @override
  String toString() => 'TargetsInArea($shape, $subject)';
}

void _validateRestriction(
  CreatureTypeRestriction restriction,
  TargetSubject subject,
) {
  if (subject == TargetSubject.object && restriction is OnlyCreatureTypes) {
    throw ArgumentError.value(
      restriction,
      'restriction',
      'a creature restriction cannot apply to an object subject',
    );
  }
}
