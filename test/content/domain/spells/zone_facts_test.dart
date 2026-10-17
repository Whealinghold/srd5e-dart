import 'package:srd5e/src/content/domain/spells/zone_facts.dart';
import 'package:test/test.dart';

import '../../../support/argument_error_matcher.dart';

ZoneRuleFact _rule({
  ZoneTrigger trigger = ZoneTrigger.creatureEndsTurnInside,
  int? unitFeet,
}) => ZoneRuleFact(
  trigger: trigger,
  partIndex: 0,
  scope: ZoneTargetScope.anyCreature,
  unitFeet: unitFeet,
  casterChoice: false,
);

void main() {
  /// Requirement: doc/specs/spell-effect-data.md FR-048 - unitFeet is set exactly for a
  ///   travelsWithin rule and is at least 1 (SRD 5.2.1, "Flaming
  ///   Sphere", p. 132).
  /// Path: unhappy (boundary)
  group('ZoneRuleFact unitFeet', () {
    /// Requirement: doc/specs/spell-effect-data.md FR-048 - unitFeet (at
    ///   least 1) MUST be set for travelsWithin and for no other trigger
    ///   (SRD 5.2.1, "Flaming Sphere", p. 132).
    /// Path: unhappy (boundary)
    test('travelsWithin requires a unitFeet of at least 1; 0 is rejected', () {
      expect(
        () => _rule(trigger: ZoneTrigger.travelsWithin),
        throwsArgumentErrorFor('unitFeet', null),
      );
      expect(
        () => _rule(trigger: ZoneTrigger.travelsWithin, unitFeet: 0),
        throwsArgumentErrorFor('unitFeet', 0),
      );
      expect(
        _rule(trigger: ZoneTrigger.travelsWithin, unitFeet: 5).unitFeet,
        5,
      );
      // The minimum is inclusive: exactly 1 is a unit.
      expect(
        _rule(trigger: ZoneTrigger.travelsWithin, unitFeet: 1).unitFeet,
        1,
      );
    });

    /// Requirement: doc/specs/spell-effect-data.md FR-048 - unitFeet on any
    ///   other trigger is rejected.
    /// Path: unhappy (invalid input)
    test('unitFeet on a non-travelling rule is rejected', () {
      expect(() => _rule(unitFeet: 5), throwsArgumentErrorFor('unitFeet', 5));
      expect(_rule().unitFeet, isNull);
    });
  });

  /// Requirement: doc/specs/spell-effect-data.md FR-048 - the four mobility shapes with
  ///   their feet bounds (SRD 5.2.1, pp. 116, 132, 164-165).
  /// Path: unhappy (boundary)
  group('ZoneMobility', () {
    /// Requirement: doc/specs/spell-effect-data.md FR-048 - maxFeet and feet
    ///   are at least 1 ("Flaming Sphere" p. 132; "Cloudkill" p. 116).
    /// Path: unhappy (boundary)
    test('MovedByCaster and DriftsAtTurnStart reject distances below 1', () {
      expect(
        () =>
            MovedByCaster(0, ZoneActionKind.bonusAction, laterTurnsOnly: false),
        throwsArgumentErrorFor('maxFeet', 0),
      );
      expect(
        () => DriftsAtTurnStart(0, DriftDirectionRule.awayFromCaster),
        throwsArgumentErrorFor('feet', 0),
      );
      final moved = MovedByCaster(
        20,
        ZoneActionKind.bonusAction,
        laterTurnsOnly: true,
      );
      expect(moved.maxFeet, 20);
      expect(moved.action, ZoneActionKind.bonusAction);
      expect(moved.laterTurnsOnly, isTrue);
      final drifting = DriftsAtTurnStart(
        10,
        DriftDirectionRule.awayFromCasterChosen,
      );
      expect(drifting.feet, 10);
      expect(drifting.direction, DriftDirectionRule.awayFromCasterChosen);
      // The minimum is inclusive: a distance of exactly 1 foot is a
      // distance.
      expect(
        MovedByCaster(
          1,
          ZoneActionKind.magicAction,
          laterTurnsOnly: false,
        ).maxFeet,
        1,
      );
      expect(DriftsAtTurnStart(1, DriftDirectionRule.awayFromCaster).feet, 1);
    });

    /// Requirement: doc/specs/spell-effect-data.md FR-048 - the four
    ///   mobility shapes are sealed and distinct ("Spirit Guardians",
    ///   SRD 5.2.1, pp. 164-165).
    /// Path: happy
    test('the four mobility shapes are exhaustive and distinct', () {
      final mobilities = <ZoneMobility>[
        const StationaryZone(),
        const MovesWithOrigin(),
        MovedByCaster(20, ZoneActionKind.magicAction, laterTurnsOnly: false),
        DriftsAtTurnStart(10, DriftDirectionRule.awayFromCaster),
      ];
      expect(mobilities[0], isNot(mobilities[1]));
      expect(const StationaryZone(), const StationaryZone());
      expect(const MovesWithOrigin(), const MovesWithOrigin());
    });
  });

  /// Requirement: doc/specs/spell-effect-data.md FR-048 - extraFeetPerFoot is 0 or more
  ///   ("Wall of Thorns", SRD 5.2.1, p. 173).
  /// Path: unhappy (boundary)
  group('ZoneMovementFacts', () {
    /// Requirement: doc/specs/spell-effect-data.md FR-048 - extraFeetPerFoot
    ///   is at least 0 ("Wall of Thorns", SRD 5.2.1, p. 173).
    /// Path: unhappy (boundary)
    test('extraFeetPerFoot rejects -1, accepts 0 and 3', () {
      expect(
        () => ZoneMovementFacts(
          difficultTerrain: true,
          speedHalved: false,
          extraFeetPerFoot: -1,
        ),
        throwsArgumentErrorFor('extraFeetPerFoot', -1),
      );
      expect(
        ZoneMovementFacts(
          difficultTerrain: true,
          speedHalved: false,
        ).extraFeetPerFoot,
        0,
      );
      expect(
        ZoneMovementFacts(
          difficultTerrain: true,
          speedHalved: false,
          extraFeetPerFoot: 3,
        ).extraFeetPerFoot,
        3,
      );
    });
  });

  /// Requirement: doc/specs/spell-effect-data.md FR-048 - at least one rule; the budget
  ///   is at least 1; regions are non-blank (SRD 5.2.1, pp. 164-165).
  /// Path: unhappy (empty and minimal)
  group('ZoneFacts', () {
    /// Requirement: doc/specs/spell-effect-data.md FR-048 - at least one
    ///   ZoneRuleFact; damageBudget at least 1.
    /// Path: unhappy (empty and minimal)
    test('empty rules are rejected; a damage budget below 1 is rejected', () {
      expect(
        () => ZoneFacts(
          rules: const [],
          mobility: const StationaryZone(),
          oncePerTurn: true,
          designation: DesignationPolicy.none,
          stopsMoverOnContact: false,
        ),
        throwsArgumentErrorFor('rules', const <ZoneRuleFact>[]),
      );
      expect(
        () => ZoneFacts(
          rules: [_rule()],
          mobility: const StationaryZone(),
          oncePerTurn: true,
          designation: DesignationPolicy.none,
          damageBudget: 0,
          stopsMoverOnContact: false,
        ),
        throwsArgumentErrorFor('damageBudget', 0),
      );
      // The minimum is inclusive: a budget of exactly 1 damage is a budget.
      expect(
        ZoneFacts(
          rules: [_rule()],
          mobility: const StationaryZone(),
          oncePerTurn: true,
          designation: DesignationPolicy.none,
          damageBudget: 1,
          stopsMoverOnContact: false,
        ).damageBudget,
        1,
      );
    });

    /// Requirement: doc/specs/spell-effect-data.md FR-048 - the facts
    ///   compare by value: a different rule count and a different single
    ///   rule each break equality.
    /// Path: happy
    test('a different rule count or a different rule breaks equality', () {
      ZoneFacts build(List<ZoneRuleFact> rules) => ZoneFacts(
        rules: rules,
        mobility: const StationaryZone(),
        oncePerTurn: true,
        designation: DesignationPolicy.none,
        stopsMoverOnContact: false,
      );
      final facts = build([_rule()]);
      final otherCount = build([
        _rule(),
        _rule(trigger: ZoneTrigger.creatureEnters),
      ]);
      final otherRule = build([_rule(trigger: ZoneTrigger.creatureEnters)]);

      expect(facts, isNot(otherCount));
      expect(facts, isNot(otherRule));
      expect(facts.hashCode, build([_rule()]).hashCode);
    });

    /// Requirement: doc/specs/spell-effect-data.md FR-048 - the facts hold
    ///   rules, mobility, designation and movement as data ("Spike Growth",
    ///   SRD 5.2.1, p. 164).
    /// Path: happy
    test('a zone with one rule and movement facts is valid and comparable', () {
      ZoneFacts build() => ZoneFacts(
        rules: [
          ZoneRuleFact(
            trigger: ZoneTrigger.creatureEnters,
            partIndex: 0,
            scope: ZoneTargetScope.enemiesOfCaster,
            casterChoice: false,
          ),
        ],
        mobility: const StationaryZone(),
        oncePerTurn: true,
        designation: DesignationPolicy.atCastingOnly,
        stopsMoverOnContact: false,
        movement: ZoneMovementFacts(
          difficultTerrain: true,
          speedHalved: false,
          extraFeetPerFoot: 3,
        ),
      );
      final facts = build();
      expect(facts.rules, hasLength(1));
      expect(facts.designation, DesignationPolicy.atCastingOnly);
      expect(facts.movement, isNotNull);
      expect(facts, build());
      expect(facts.hashCode, build().hashCode);
    });

    /// Requirement: doc/specs/spell-effect-data.md FR-048 - ZoneRegionId is
    ///   non-blank with the default body.
    /// Path: unhappy (invalid input)
    test('a blank region id is rejected; body is the default', () {
      expect(() => ZoneRegionId(' '), throwsArgumentErrorFor('value', ' '));
      expect(const ZoneRegionId.body().value, 'body');
      expect(ZoneRegionId('thorns').value, 'thorns');
    });
  });
}
