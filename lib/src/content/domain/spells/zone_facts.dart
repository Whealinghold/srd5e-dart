import 'package:meta/meta.dart';

/// What happening inside a lingering zone a rule fires on (FR-048).
///
/// The triggers are the static facts a zone spell prints: Spirit Guardians'
/// creature entering and ending its turn inside, Moonbeam's turn starts,
/// Flaming Sphere's movement and travel. Package terms, named from the
/// printed sentences ("Spirit Guardians", SRD 5.2.1, pp. 164-165;
/// "Moonbeam", pp. 150-151; "Flaming Sphere", p. 132).
enum ZoneTrigger {
  /// A creature enters the zone.
  creatureEnters,

  /// A creature enters the zone for the first time on its turn.
  creatureFirstEntryOnTurn,

  /// A creature ends its turn inside the zone.
  creatureEndsTurnInside,

  /// A creature starts its turn inside the zone.
  creatureStartsTurnInside,

  /// The zone moves into a creature's space.
  zoneMovesIntoSpace,

  /// The zone travels, so the rule fires per [ZoneRuleFact.unitFeet] feet of
  /// travel.
  travelsWithin,
}

/// Which creatures inside the zone a rule's effect applies to (FR-048).
enum ZoneTargetScope {
  /// Any creature inside the zone.
  anyCreature,

  /// Only the caster's enemies.
  enemiesOfCaster,

  /// Only creatures the caster can see.
  creaturesCasterCanSee,
}

/// Which part of the zone a rule's region is, as a non-blank identifier with
/// the whole zone as its default (FR-048).
///
/// Package term: a zone may name regions its text distinguishes; `body` is
/// the default region of the zone itself.
@immutable
final class ZoneRegionId {
  /// The default region: the whole zone.
  const ZoneRegionId.body() : value = 'body';

  /// Creates the region named [value].
  ///
  /// Throws an [ArgumentError] carrying the name `value` and the offending
  /// value when [value] is blank (FR-048).
  ZoneRegionId(String value) : value = _validatedValue(value);

  /// The region's name.
  final String value;

  static String _validatedValue(String value) {
    if (value.trim().isEmpty) {
      throw ArgumentError.value(value, 'value', 'must not be blank');
    }
    return value;
  }

  @override
  bool operator ==(Object other) =>
      other is ZoneRegionId && other.value == value;

  @override
  int get hashCode => Object.hash(ZoneRegionId, value);

  @override
  String toString() => 'ZoneRegionId($value)';
}

/// Whether the caster may designate creatures the zone's rules skip
/// (FR-048).
enum DesignationPolicy {
  /// The zone has no designation.
  none,

  /// The caster designates creatures when casting ("Wall of Thorns",
  /// SRD 5.2.1, p. 173).
  atCastingOnly,
}

/// How the zone moves, sealed with the four printed shapes (FR-048).
///
/// Spirit Guardians moves with its origin; Cloudkill drifts at the start of
/// each of the caster's turns; Flaming Sphere is moved by the caster with a
/// bonus action. Switch over the family exhaustively, with no default branch.
@immutable
sealed class ZoneMobility {
  const ZoneMobility();
}

/// The zone stays where it was created.
@immutable
final class StationaryZone extends ZoneMobility {
  /// The single shape; staying put carries no data.
  const StationaryZone();

  @override
  bool operator ==(Object other) => other is StationaryZone;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'StationaryZone()';
}

/// The zone moves with its origin, such as a emanation centred on the
/// caster (FR-048).
@immutable
final class MovesWithOrigin extends ZoneMobility {
  /// The single shape; moving with the origin carries no data.
  const MovesWithOrigin();

  @override
  bool operator ==(Object other) => other is MovesWithOrigin;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'MovesWithOrigin()';
}

/// The caster moves the zone, up to [maxFeet] feet with [action], either on
/// every turn or only [laterTurnsOnly] (FR-048): Flaming Sphere (p. 132),
/// Guardian of Faith (p. 137).
@immutable
final class MovedByCaster extends ZoneMobility {
  /// Creates the mobility of up to [maxFeet] feet per [action].
  ///
  /// Throws an [ArgumentError] carrying the name `maxFeet` and the offending
  /// value when [maxFeet] is below 1 (FR-048).
  MovedByCaster(int maxFeet, this.action, {required this.laterTurnsOnly})
    : maxFeet = _validatedFeet(maxFeet, 'maxFeet');

  /// The farthest the caster may move the zone, in feet.
  final int maxFeet;

  /// The action moving the zone takes.
  final ZoneActionKind action;

  /// Whether the zone may move only on later turns, not the casting turn.
  final bool laterTurnsOnly;

  @override
  bool operator ==(Object other) =>
      other is MovedByCaster &&
      other.maxFeet == maxFeet &&
      other.action == action &&
      other.laterTurnsOnly == laterTurnsOnly;

  @override
  int get hashCode =>
      Object.hash(MovedByCaster, maxFeet, action, laterTurnsOnly);

  @override
  String toString() => 'MovedByCaster($maxFeet, $action)';
}

/// The zone drifts [feet] feet in a [direction] at the start of a turn
/// (FR-048): Cloudkill (SRD 5.2.1, p. 116).
@immutable
final class DriftsAtTurnStart extends ZoneMobility {
  /// Creates the drift of [feet] feet [direction].
  ///
  /// Throws an [ArgumentError] carrying the name `feet` and the offending
  /// value when [feet] is below 1 (FR-048).
  DriftsAtTurnStart(int feet, this.direction)
    : feet = _validatedFeet(feet, 'feet');

  /// How far the zone drifts, in feet.
  final int feet;

  /// Which way the zone drifts.
  final DriftDirectionRule direction;

  @override
  bool operator ==(Object other) =>
      other is DriftsAtTurnStart &&
      other.feet == feet &&
      other.direction == direction;

  @override
  int get hashCode => Object.hash(DriftsAtTurnStart, feet, direction);

  @override
  String toString() => 'DriftsAtTurnStart($feet, $direction)';
}

/// The action moving a [MovedByCaster] zone takes (FR-048).
enum ZoneActionKind {
  /// A bonus action (Flaming Sphere, SRD 5.2.1, p. 132).
  bonusAction,

  /// The Magic action (Guardian of Faith, SRD 5.2.1, p. 137).
  magicAction,

  /// Movement with the caster.
  withCasterMovement,
}

/// Which way a [DriftsAtTurnStart] zone drifts (FR-048).
enum DriftDirectionRule {
  /// Away from the caster, in the printed direction.
  awayFromCaster,

  /// Away from the caster, the direction chosen when the zone is cast.
  awayFromCasterChosen,
}

/// The terrain facts a zone's area carries (FR-048): Spike Growth's difficult
/// terrain ("Difficult Terrain", SRD 5.2.1, p. 181) and movement costs.
@immutable
final class ZoneMovementFacts {
  /// Creates the movement facts.
  ///
  /// Throws an [ArgumentError] carrying the name `extraFeetPerFoot` and the
  /// offending value when [extraFeetPerFoot] is below 0 (FR-048).
  ZoneMovementFacts({
    required this.difficultTerrain,
    required this.speedHalved,
    int extraFeetPerFoot = 0,
  }) : extraFeetPerFoot = _validatedExtraFeet(extraFeetPerFoot);

  /// Whether the zone's area is difficult terrain.
  final bool difficultTerrain;

  /// Whether movement through the zone is at half speed.
  final bool speedHalved;

  /// The extra feet of movement each foot through the zone costs: Wall of
  /// Thorns' 4 gives 3 (SRD 5.2.1, p. 173) (FR-048, FR-049).
  final int extraFeetPerFoot;

  static int _validatedExtraFeet(int extraFeetPerFoot) {
    if (extraFeetPerFoot < 0) {
      throw ArgumentError.value(
        extraFeetPerFoot,
        'extraFeetPerFoot',
        'must be 0 or more',
      );
    }
    return extraFeetPerFoot;
  }

  @override
  bool operator ==(Object other) =>
      other is ZoneMovementFacts &&
      other.difficultTerrain == difficultTerrain &&
      other.speedHalved == speedHalved &&
      other.extraFeetPerFoot == extraFeetPerFoot;

  @override
  int get hashCode => Object.hash(
    ZoneMovementFacts,
    difficultTerrain,
    speedHalved,
    extraFeetPerFoot,
  );

  @override
  String toString() =>
      'ZoneMovementFacts($difficultTerrain, $speedHalved, '
      '$extraFeetPerFoot)';
}

/// One static rule of a lingering zone (FR-048).
///
/// The types hold facts only — no state, ledger or event; the running zone is
/// the persistent-spell-zones rules' concern. The [partIndex] names a part of
/// the same model but is not range-checked by the constructor: the decoder and
/// the bundle check report a [partIndex] outside the model's parts
/// (FR-048, FR-049).
@immutable
final class ZoneRuleFact {
  /// Creates the rule firing on [trigger] over [scope] in [region].
  ///
  /// Throws an [ArgumentError] carrying the name `unitFeet` and the offending
  /// value when [trigger] is [ZoneTrigger.travelsWithin] and [unitFeet] is
  /// absent or below 1, or when [trigger] is any other trigger and [unitFeet]
  /// is present: only a travelling zone counts per feet (FR-048).
  ZoneRuleFact({
    required this.trigger,
    required this.partIndex,
    required this.scope,
    this.region = const ZoneRegionId.body(),
    this.unitFeet,
    required this.casterChoice,
  }) {
    _validateUnitFeet(trigger, unitFeet);
  }

  /// What happening fires the rule.
  final ZoneTrigger trigger;

  /// The zero-based index of the part of the same model the rule's effect
  /// comes from; not range-checked here (FR-048).
  final int partIndex;

  /// Which creatures the rule applies to.
  final ZoneTargetScope scope;

  /// Which region of the zone the rule is about.
  final ZoneRegionId region;

  /// The travel length the rule fires per, in feet, set exactly for
  /// [ZoneTrigger.travelsWithin] (FR-048).
  final int? unitFeet;

  /// Whether the rule's effect applies by the caster's choice among the
  /// creatures the [scope] admits. Package design: the zone facts hold what
  /// the spell's text states about who is affected.
  final bool casterChoice;

  static void _validateUnitFeet(ZoneTrigger trigger, int? unitFeet) {
    if (trigger == ZoneTrigger.travelsWithin) {
      if (unitFeet == null) {
        throw ArgumentError.value(
          unitFeet,
          'unitFeet',
          'is required for a travelsWithin rule',
        );
      }
      if (unitFeet < 1) {
        throw ArgumentError.value(unitFeet, 'unitFeet', 'must be at least 1');
      }
      return;
    }
    if (unitFeet != null) {
      throw ArgumentError.value(
        unitFeet,
        'unitFeet',
        'is set only for a travelsWithin rule',
      );
    }
  }

  @override
  bool operator ==(Object other) =>
      other is ZoneRuleFact &&
      other.trigger == trigger &&
      other.partIndex == partIndex &&
      other.scope == scope &&
      other.region == region &&
      other.unitFeet == unitFeet &&
      other.casterChoice == casterChoice;

  @override
  int get hashCode => Object.hash(
    ZoneRuleFact,
    trigger,
    partIndex,
    scope,
    region,
    unitFeet,
    casterChoice,
  );

  @override
  String toString() => 'ZoneRuleFact($trigger, part: $partIndex)';
}

/// The static facts of a lingering zone, optional on a spell's model
/// (FR-048).
///
/// A zone spell whose model carries no [ZoneFacts] has none; a zone spell
/// with text-only effects has none. The facts are what the spell's text
/// prints; nothing here rolls, ticks or tracks state.
@immutable
final class ZoneFacts {
  /// Creates the zone facts from a defensive copy of [rules].
  ///
  /// Throws an [ArgumentError] carrying the name `rules` and the offending
  /// value when [rules] is empty, or the name `damageBudget` and the
  /// offending value when [damageBudget] is present but below 1 (FR-048).
  ZoneFacts({
    required List<ZoneRuleFact> rules,
    required this.mobility,
    required this.oncePerTurn,
    required this.designation,
    this.damageBudget,
    required this.stopsMoverOnContact,
    this.movement,
  }) : rules = List.unmodifiable(_validatedRules(rules)) {
    _validateBudget(damageBudget);
  }

  /// The zone's rules, in printed order; unmodifiable, never empty (FR-048).
  final List<ZoneRuleFact> rules;

  /// How the zone moves.
  final ZoneMobility mobility;

  /// Whether each rule fires at most once per creature turn.
  final bool oncePerTurn;

  /// Whether the caster may designate creatures the rules skip.
  final DesignationPolicy designation;

  /// The zone's budget of damage, at least 1 when present (FR-048).
  final int? damageBudget;

  /// Whether the zone stops a mover that contacts it.
  final bool stopsMoverOnContact;

  /// The terrain facts of the zone's area, or null for none (FR-048).
  final ZoneMovementFacts? movement;

  static List<ZoneRuleFact> _validatedRules(List<ZoneRuleFact> rules) {
    if (rules.isEmpty) {
      throw ArgumentError.value(rules, 'rules', 'must have at least one rule');
    }
    return rules;
  }

  static void _validateBudget(int? damageBudget) {
    if (damageBudget != null && damageBudget < 1) {
      throw ArgumentError.value(
        damageBudget,
        'damageBudget',
        'must be at least 1',
      );
    }
  }

  @override
  bool operator ==(Object other) =>
      other is ZoneFacts &&
      _rulesEqual(other.rules, rules) &&
      other.mobility == mobility &&
      other.oncePerTurn == oncePerTurn &&
      other.designation == designation &&
      other.damageBudget == damageBudget &&
      other.stopsMoverOnContact == stopsMoverOnContact &&
      other.movement == movement;

  @override
  int get hashCode => Object.hash(
    ZoneFacts,
    Object.hashAll(rules),
    mobility,
    oncePerTurn,
    designation,
    damageBudget,
    stopsMoverOnContact,
    movement,
  );

  @override
  String toString() => 'ZoneFacts(${rules.length} rules)';
}

/// A travel length is at least 1 (FR-048).
int _validatedFeet(int feet, String name) {
  if (feet < 1) {
    throw ArgumentError.value(feet, name, 'must be at least 1');
  }
  return feet;
}

bool _rulesEqual(List<ZoneRuleFact> a, List<ZoneRuleFact> b) {
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
