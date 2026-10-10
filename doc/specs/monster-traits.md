# Monster traits

| | |
|---|---|
| Status | draft |
| Context | `combat` |
| Roadmap phase | 4 |
| Depends on | `content-schema-and-decoder.md`, `content-monsters.md`, `modifiers-and-advantage.md`, `d20-tests.md`, `derived-stats.md`, `combat-foundations.md`, `hit-points-and-damage.md`, `conditions.md`, `environment-hazards-and-objects.md`, `initiative-and-actions.md`, `monster-limited-use.md` |

Types ship with the `combat` phase (`shared-types-and-ownership.md` FR-014). Rank 27 (listed in `shared-types-and-ownership.md` 4.11).

## 1. Purpose and scope

Many stat blocks repeat a handful of Traits (SRD 5.2.1, "Traits", p. 256). `content-monsters.md` keeps each one as a `StatBlockPart` with verbatim text and a `PartUsage`; nothing interprets it. This spec recognises twelve recurring traits and turns each into a typed fact, a `RollCircumstance` source or a pure state-in, state-out rule that composes the existing specs, with **no new roll logic**:

- **Defensive:** Legendary Resistance (fail to succeed, counted by `monster-limited-use.md`), Magic Resistance, Undead Fortitude, Regeneration (with suppression), Death Burst, Swarm.
- **Situational:** Pack Tactics, Sunlight Sensitivity (and the same-shaped Sunlight Weakness), Flyby, Amorphous, Siege Monster, Parry.

Every operation is a domain function. **There is no use case, no port and no signal**: the dice a trait needs (the Constitution save of Undead Fortitude) are rolled by the host through `ResolveD20Test` or `D20TestResolver` (`shared-types-and-ownership.md` FR-044), and the host passes the finished outcome in.

**Out of scope:**

- **What a used part does:** a Death Burst's damage and save are the part's `StatBlockSavingThrow` and `EffectClause`s (`content-monsters.md` FR-038, FR-039, FR-042), resolved by the host and the damage specs. Who stands in an Emanation is a map question (`combat-action-resolution.md` has no map).
- **Other traits** (Amphibious, Spider Climb, Web Walker, Fire Absorption, Charge, Diabolical Restoration, ...): not recognised, never an error (FR-002).
- **The vampire's "Sunlight" trait** (p. 335: 20 Radiant damage when its turn starts in sunlight, plus Disadvantage on attack rolls and ability checks): a start-of-turn damage rider the host resolves with `ApplyDamage`. Flagged, not modelled.
- **The Vorpal Sword's use of Legendary Resistance** (an item rule, p. 250): `magic-item-rules.md`.
- **Narrow spaces:** "Difficult Terrain" (p. 181) lists "a narrow opening sized for a creature one size smaller than you", which costs extra movement; Amorphous waives it. Terrain is host-supplied (`grid-positions-and-movement.md`), so Amorphous is a fact the host honours when it builds terrain (FR-072); no movement operation consults it.
- **Rolling, rests, Hit Point arithmetic, Opportunity Attack acceptance, the Reaction economy:** the specs that own them.

## 2. Source

- SRD 5.2.1, "Monsters", "Traits", p. 256; "Reactions", "Legendary Actions", "Limited Usage", p. 257.
- Trait text, one citation per template (table T-1): Legendary Resistance, "Aboleth", p. 258; Magic Resistance, "Balor", p. 261; Undead Fortitude, "Zombie", p. 343, "Ogre Zombie", p. 344; Regeneration, "Oni", p. 312, "Shield Guardian", p. 323, "Troll", p. 333; Death Burst, "Magmin", p. 305, "Mephits", p. 307; Swarm, "Swarm of Crawling Claws", p. 278, pp. 361-363; Pack Tactics, "Vulture", p. 364 (primary wording), "Wolf", p. 364 (attack-rolls variant); Sunlight Sensitivity, "Drider", p. 281, "Specter", p. 327; Sunlight Weakness, "Shadow", p. 322; Flyby, "Hippogriff", p. 298; Amorphous, "Black Pudding", p. 265; Siege Monster, "Treant", p. 333; Parry, "Bandit", p. 262, "Marilith", p. 306.
- Rules: "D20 Tests", "Saving Throws", p. 7; "Rolling 20 or 1", p. 7; "Advantage/Disadvantage", "They Don't Stack", p. 8; "Hit Points", "Damage Rolls", "Order of Application", "Monster Death", "Healing", p. 16-17; "Stabilizing a Character", p. 18; "Opportunity Attacks", p. 185; "Breaking Objects", pp. 177-178; "Critical Hit", p. 179; Rules Glossary "Difficult Terrain", p. 181; "Incapacitated", p. 184.
- Package design: `doc/rules/architecture.md` §3, §4, §6; `doc/rules/observability.md` §3; `doc/rules/testing.md` §4, §5, §8; `shared-types-and-ownership.md` FR-044, FR-048.

## 3. Vocabulary

| SRD term | Type | Notes |
|---|---|---|
| Trait | `MonsterTrait` (sealed: `LegendaryResistanceTrait`, `MagicResistanceTrait`, `UndeadFortitudeTrait`, `RegenerationTrait`, `DeathBurstTrait`, `SwarmTrait`, `PackTacticsTrait`, `SunlightPenaltyTrait`, `FlybyTrait`, `AmorphousTrait`, `SiegeMonsterTrait`, `ParryTrait`) | Each holds the `LimitedUsePartRef` (`monster-limited-use.md` FR-005) of its part. |
| (recognition) | `MonsterTraits.of(Monster)` returns `RecognisedTraits(traits, unrecognised)`; `UnrecognisedTrait(part, reason)`; `TraitRejection` (`sectionMismatch`, `textMismatch`, `usageMismatch`, `parameterOutOfRange`, `unknownDamageType`, `noSavingThrow`) | Package terms. |
| Legendary Resistance | `LegendaryResistance.use`, sealed `SaveFailure` (`RolledSaveFailure(CheckResult)`, `ForcedSaveFailure(ForcedFailureResult)`), sealed `LegendaryResistanceOutcome` (`LegendaryResistanceApplied`, `LegendaryResistanceRefused`) | Uses are a `PartPerDay` entry of `LimitedUseState`. |
| Advantage on saving throws against spells and other magical effects | `MagicResistance.circumstances`, `SaveSourceKind` (`spellOrMagicalEffect`, `other`) | Yields `Advantage` (`RollCircumstance`). |
| Undead Fortitude | `UndeadFortitude.assess` / `.settle`, `UndeadFortitudeFacts`, sealed `UndeadFortitudeCheck` (`UndeadFortitudeNotTriggered(reason)`, `UndeadFortitudeSaveRequired(dc)`) and `UndeadFortitudeSettlement` (`UndeadFortitudeSurvived`, `UndeadFortitudeFell`) | `ExemptionReason`: `notReducedToZero`, `criticalHit`, `radiantDamage`. |
| Regeneration | `RegenerationState`, `RegenerationStep`, `Regeneration` operations, sealed `RegenerationTurn` (`RegenerationHealed`, `RegenerationSkipped(reason)`, `RegenerationLetDie`), `RegenerationDeferral` (`RegenerationDeathDeferred`, `RegenerationNotDeferred`) | `SkipReason`: `suppressed`, `noHitPoints`, `swarmCannotRegain`. |
| Death Burst | `DeathBurst.trigger`, sealed `DeathBurstResult` (`DeathBurstTriggered(part, ability, dc)`, `DeathBurstNotTriggered`) | A fact; the host resolves the burst. |
| Swarm | `SwarmRules`, `SwarmChange` (`SwarmHealing`, `SwarmTemporaryHitPoints`, `SwarmMaximumReduction`), `SwarmRefusal` | `smallestOpening` is `CreatureSize.tiny`. |
| Pack Tactics | `PackTactics.circumstances`, `AllyFact(distanceFeet, incapacitated)` | `distanceFeet` runs from the ally to the attack's target |
| Sunlight Sensitivity, Sunlight Weakness | `SunlightPenaltyScope` (`abilityChecksAndAttackRolls`, `allD20Tests`) | |
| Opportunity Attack | `Flyby.exemptsFromOpportunityAttack(MovementMode)` | `MovementMode` is `initiative-and-actions.md`'s. |
| Siege Monster | `SiegeMonster.apply`, `DamageRecipient` (`creature`, `objectOrStructure`) | |
| Parry | `Parry.assess` / `.respond`, `ParryFacts`, sealed `ParryOffer` (`ParryAvailable`, `ParryUnavailable`), `ParryResponse` | |
| (events) | sealed `MonsterTraitEvent` implementing `CombatEvent` | FR-090. |

## 4. Requirements

Stable ids. Never renumber; new requirements get new ids. Ids are allocated in blocks; an id absent from this section and not in the Withdrawn ids was never used by this spec. "Printed order" is `MonsterPartSection` declaration order, then position (`monster-limited-use.md` section 4).

### 4.1 Recognition

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-001 | `MonsterTraits.of(monster)` MUST return the recognised traits in printed order, each with its part ref, and the unrecognised ones in printed order. A monster with none of the twelve names returns two empty lists. A part whose name is none of the twelve appears in neither list. | SRD 5.2.1, "Traits", p. 256 | happy |
| FR-002 | A part is recognised only when its name equals a trait name (case-sensitive, after the usage parenthetical is removed by the content model) **and** its verbatim text matches the template of table T-1. A part with a known name that fails a check MUST appear in `unrecognised` with its `TraitRejection`; the function MUST NOT throw for any monster. | SRD 5.2.1, "Traits", p. 256; architecture.md §6 | unhappy (invalid input) |
| FR-003 | Matching MUST collapse whitespace runs to one space, treat `'` and `’` as the same, and be otherwise exact. The noun slot `⟨n⟩` of T-1 matches one or more lower-case words ("the zombie", "the shambling mound"); the same noun MUST fill every occurrence in one text. | SRD 5.2.1, trait texts p. 258-364 | unhappy (boundary) |
| FR-004 | Section: Parry MUST be in `reactions`, every other trait in `traits`; otherwise `sectionMismatch`. | SRD 5.2.1, "Traits", "Reactions", pp. 256-257 | unhappy (rule interaction) |
| FR-005 | `LegendaryResistanceTrait` MUST require a `PartPerDay` usage (`content-monsters.md` FR-035); any other usage is `usageMismatch`. The count and in-Lair count are not copied: they live in `LimitedUseState` (`monster-limited-use.md` FR-002). | SRD 5.2.1, "Aboleth", p. 258; "Limited Usage", p. 257 | unhappy (missing content) |
| FR-006 | `DeathBurstTrait` MUST require the text to start "The ⟨n⟩ explodes when it dies." and the part to hold at least one `StatBlockSavingThrow`; otherwise `textMismatch` or `noSavingThrow`. It exposes the first saving throw's ability and DC. | SRD 5.2.1, "Magmin", p. 305; "Mephits", p. 307 | unhappy (missing content) |
| FR-007 | Parameters MUST be parsed from the text: Regeneration amount and Parry bonus are integers of at least 1 (`parameterOutOfRange` otherwise); Regeneration's suppressing damage types ("Acid or Fire") MUST each be a known `DamageType` (`unknownDamageType` otherwise). The trait constructors enforce the same bounds and throw `ArgumentError`; only `MonsterTraits.of` converts these failures into a `TraitRejection` (FR-002). | SRD 5.2.1, "Troll", p. 333; "Bandit", p. 262 | unhappy (boundary) |
| FR-008 | `RecognisedTraits`, every trait and `UnrecognisedTrait` MUST be value objects (equal fields, equal hash codes); the two lists MUST be unmodifiable (`UnsupportedError` on mutation); `of` MUST leave the monster unchanged and give equal results for equal input. | architecture.md §3; testing.md §4 | unhappy (immutability) |

Table T-1, templates (`⟨n⟩` noun, `⟨k⟩` integer, `⟨t⟩` damage type; the text after the name's full stop):

| Trait (section) | Template | Source |
|---|---|---|
| Legendary Resistance (traits) | `If the ⟨n⟩ fails a saving throw, it can choose to succeed instead.` | "Aboleth", p. 258 |
| Magic Resistance (traits) | `The ⟨n⟩ has Advantage on saving throws against spells and other magical effects.` | "Balor", p. 261 |
| Undead Fortitude (traits) | `If damage reduces the ⟨n⟩ to 0 Hit Points, it makes a Constitution saving throw (DC 5 plus the damage taken) unless the damage is Radiant or from a Critical Hit. On a successful save, the ⟨n⟩ drops to 1 Hit Point instead.` | "Zombie", p. 343 |
| Regeneration, RG-1 (traits) | `The ⟨n⟩ regains ⟨k⟩ Hit Points at the start of each of its turns if it has at least 1 Hit Point.` | "Oni", p. 312; "Shield Guardian", p. 323 |
| Regeneration, RG-2 (traits) | `The ⟨n⟩ regains ⟨k⟩ Hit Points at the start of each of its turns. If the ⟨n⟩ takes ⟨t⟩ or ⟨t⟩ damage, this trait doesn't function on the ⟨n⟩'s next turn. The ⟨n⟩ dies only if it starts its turn with 0 Hit Points and doesn't regenerate.` | "Troll", p. 333 |
| Death Burst (traits) | `The ⟨n⟩ explodes when it dies.` then the saving throw notation | "Magmin", p. 305 |
| Swarm (traits) | `The swarm can occupy another creature's space and vice versa, and the swarm can move through any opening large enough for a Tiny ⟨n⟩. The swarm can't regain Hit Points or gain Temporary Hit Points.` | p. 278, p. 361 |
| Pack Tactics (traits) | `The ⟨n⟩ has Advantage on an attack roll against a creature if at least one of the ⟨n⟩'s allies is within 5 feet of the creature and the ally doesn't have the Incapacitated condition.` Variant: `on attack rolls against a creature if`. | "Vulture", p. 364; "Wolf", p. 364 (variant) |
| Sunlight Sensitivity (traits) | `While in sunlight, the ⟨n⟩ has Disadvantage on ability checks and attack rolls.` | "Drider", p. 281 |
| Sunlight Weakness (traits) | `While in sunlight, the ⟨n⟩ has Disadvantage on D20 Tests.` | "Shadow", p. 322 |
| Flyby (traits) | `The ⟨n⟩ doesn't provoke an Opportunity Attack when it flies out of an enemy's reach.` | "Hippogriff", p. 298 |
| Amorphous (traits) | `The ⟨n⟩ can move through a space as narrow as 1 inch without expending extra movement to do so.` | "Black Pudding", p. 265 |
| Siege Monster (traits) | `The ⟨n⟩ deals double damage to objects and structures.` | "Treant", p. 333 |
| Parry (reactions) | `Trigger: The ⟨n⟩ is hit by a melee attack roll while holding a weapon. Response: The ⟨n⟩ adds ⟨k⟩ to its AC against that attack, possibly causing it to miss.` | "Bandit", p. 262 |

### 4.2 Legendary Resistance

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-010 | `LegendaryResistance.use(state, trait, subject, failure)` with a failed save and at least one use left MUST return `LegendaryResistanceApplied` holding the new `LimitedUseState` (one use spent through `LimitedUseState.spend`, `monster-limited-use.md` FR-006), the original failure, an effective outcome of `D20TestOutcome.success`, and the events `LimitedUsePartSpent` then the event `LegendaryResistanceUsed` (FR-090; `combatants == [subject]`). The original result is not edited. The choice to use it is the host's: nothing here decides it. | SRD 5.2.1, "Aboleth", p. 258; "Saving Throws", p. 7 | happy |
| FR-011 | An automatic failure or chosen failure (`ForcedSaveFailure`) MUST be accepted like a rolled one. Interpretation: both are "fails a saving throw", and the trait lists no exception. | SRD 5.2.1, "Saving Throws", p. 7; "Aboleth", p. 258 | unhappy (rule interaction) |
| FR-012 | Refusals (`LegendaryResistanceRefused`, state unchanged, no event), first match wins in this order: `notTracked` (the trait's part has no entry in the state), `notAFailure` (a rolled save that succeeded), `exhausted` (0 uses). | SRD 5.2.1, "Limited Usage" (X/Day), p. 257; "Aboleth", p. 258 | unhappy (boundary) |
| FR-013 | A `RolledSaveFailure` whose `CheckResult` kind is not `savingThrow` MUST throw `ArgumentError`: the trait covers saving throws only. | SRD 5.2.1, "Aboleth", p. 258; architecture.md §6 | unhappy (invalid input) |
| FR-014 | Uses MUST follow `LimitedUseState`: 3 outside the lair and 4 in it for "3/Day, or 4/Day in Lair"; the fourth use outside the lair is refused `exhausted`; a Long Rest restores them (`monster-limited-use.md` FR-002, FR-026). This spec adds no counter. | SRD 5.2.1, "Aboleth", p. 258 | unhappy (boundary) |

### 4.3 Magic Resistance

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-020 | `MagicResistance.circumstances(trait, source)` MUST return `[Advantage()]` for `spellOrMagicalEffect` and an empty list for `other`. | SRD 5.2.1, "Balor", p. 261 | happy |
| FR-021 | The result MUST feed `RollMode.resolve` unchanged: with a `Disadvantage` from another source the mode is `normal`, with a second `Advantage` it is `advantage` (no stacking). This spec never computes a `RollMode`. | SRD 5.2.1, "They Don't Stack", p. 8; modifiers-and-advantage.md FR-042 | unhappy (rule interaction) |
| FR-022 | There is no check or attack-roll API: the trait gives nothing to a roll that is not a saving throw, and the host asks only for saves. Classifying a source as magical is the host's input. | SRD 5.2.1, "Balor", p. 261 | unhappy (boundary) |

### 4.4 Undead Fortitude

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-030 | `UndeadFortitudeFacts(damageTaken, dealtTypes, hitKind)` MUST throw `ArgumentError` for `damageTaken` below 1 or an empty `dealtTypes`. `dealtTypes` holds the `DamageType` of each `Damage` instance of the command whose amount was above 0 after the pipeline (Immunity gives 0, so that type is absent); `damageTaken` is `DamageTaken.total` of the transition (`hit-points-and-damage.md` FR-102). | SRD 5.2.1, "Damage Rolls", "Immunity", p. 16-17; "Zombie", p. 343 | unhappy (invalid input) |
| FR-031 | `UndeadFortitude.assess(trait, transition, facts)` MUST return `UndeadFortitudeNotTriggered(notReducedToZero)` unless `transition.events` holds a `DroppedToZeroHitPoints`. Damage at 0 Hit Points, a knock-out and a hit that leaves the creature above 0 therefore never trigger it. | SRD 5.2.1, "Zombie", p. 343 ("reduces the zombie to 0 Hit Points") | unhappy (rule interaction) |
| FR-032 | With a drop to 0, a `criticalHit` kind MUST give `NotTriggered(criticalHit)`; otherwise any Radiant in `dealtTypes` MUST give `NotTriggered(radiantDamage)`; both present gives `criticalHit`. Interpretation of "the damage is Radiant": one Radiant instance in the triggering command voids it, as one command is one hit (`hit-points-and-damage.md` FR-085). | SRD 5.2.1, "Zombie", p. 343; "Critical Hit", p. 179 | unhappy (rule interaction) |
| FR-033 | Otherwise `assess` MUST return `UndeadFortitudeSaveRequired(dc, ability)` with `DifficultyClass(5 + damageTaken)` and `Ability.constitution`. Damage absorbed by Temporary Hit Points counts (it is part of `total`): interpretation of "the damage taken", matching `DamageTaken`. | SRD 5.2.1, "Zombie", p. 343; "Hit Points", p. 16 | happy |
| FR-034 | `settle(check, before, transition, subject, outcome)` with `D20TestOutcome.success` MUST return `UndeadFortitudeSurvived`: a status rebuilt by `HitPointStatus.restore` with 1 current Hit Point, the same maximum, `Alive`, the rule and affinities of `before`, Temporary Hit Points 0; events = `transition.events` without `Died` and `FellUnconscious`, then `BecameBloodied` when `before` was not Bloodied and the new status is (`isBloodied`, `derived-stats.md` FR-071), then `UndeadFortitudeSaved(dc)`. `DroppedToZeroHitPoints` and the earlier `DamageTaken` are kept (they report what the damage did before the trait acted); `UndeadFortitudeSaved` supersedes them, so a host counting drops to 0 or `DamageTaken.hitPointsLost` against the final status MUST treat an `UndeadFortitudeSaved` in the same list as cancelling the drop. | SRD 5.2.1, "Zombie", p. 343 ("drops to 1 Hit Point instead") | happy |
| FR-035 | With `failure`, `settle` MUST return `UndeadFortitudeFell` holding the transition's status and events unchanged. | SRD 5.2.1, "Zombie", p. 343 | happy |
| FR-036 | `settle` MUST throw `ArgumentError` when `check` is not `SaveRequired`, or when the transition's status is neither `Dead` nor `Dying`, or when `before` is at 0 Hit Points (the creature must have been above 0). | architecture.md §6 | unhappy (state error) |
| FR-037 | The trait has no usage limit: each new drop to 0 is assessed alone, with its own `damageTaken`. The drop is assessed whichever death rule produced it (interpretation: the trait is triggered by "reduces to 0 Hit Points", which precedes any death rule). `massiveDamage` arises only for a creature given the `FallsUnconscious` rule; a `DiesInstantly` monster never dies of it (`hit-points-and-damage.md` FR-043). | SRD 5.2.1, "Zombie", p. 343; "Massive Damage", p. 17 | unhappy (rule interaction) |

Cases UF-1 (one test per row; FR-030 to FR-037). `before` is 10 of 10 Hit Points, `DiesInstantly`.

| Label | Damage and kind | Expected | Source | Path |
|---|---|---|---|---|
| ordinary drop | 10 Slashing, normal hit | `SaveRequired`, DC 15 | "Zombie", p. 343 | happy |
| overkill | 17 Slashing, normal | DC 15 (damage taken is the 10 Hit Points lost, not 17) | FR-033 | unhappy (boundary) |
| above zero | 9 Slashing | `NotTriggered(notReducedToZero)` | p. 343 | unhappy (boundary) |
| Radiant | 10 Radiant | `NotTriggered(radiantDamage)` | p. 343 | unhappy (rule interaction) |
| mixed with Radiant | 6 Slashing, 4 Radiant | `NotTriggered(radiantDamage)` | FR-032 | unhappy (rule interaction) |
| Radiant Immune | Slashing 10 plus Radiant fully Immune | `SaveRequired` | FR-030 | unhappy (rule interaction) |
| Critical Hit | 10 Slashing, `criticalHit` | `NotTriggered(criticalHit)` | "Critical Hit", p. 179 | unhappy (rule interaction) |
| critical and Radiant | `criticalHit`, Radiant | `criticalHit` | FR-032 | unhappy (rule interaction) |
| Temporary Hit Points | 5 temporary, 17 Slashing (5 absorbed, 10 lost, total 15) | `SaveRequired`, DC 5 + 15 = 20 | FR-033 | unhappy (rule interaction) |
| temporary absorbs all | 5 temporary, 5 Slashing | `NotTriggered(notReducedToZero)` | FR-031 | unhappy (boundary) |
| bad facts | `damageTaken` 0; empty `dealtTypes` | `ArgumentError` each | FR-030 | unhappy (invalid input) |
| save succeeds | `SaveRequired`, `success` | 1 Hit Point, `Alive`; events exactly `DamageTaken`, `DroppedToZeroHitPoints`, (`BecameBloodied`), `UndeadFortitudeSaved`; no `Died` | FR-034, p. 343 | happy |
| Dying then survives | `FallsUnconscious` zombie to Dying, `success` | 1 Hit Point, `Alive`, no `FellUnconscious` | FR-034, FR-037 | unhappy (rule interaction) |
| settle from 0 | `before` at 0 Hit Points | `ArgumentError` | FR-036 | unhappy (state error) |
| settle Alive | transition status `Alive` | `ArgumentError` | FR-036 | unhappy (state error) |
| save fails | `failure` | `Fell`, `Died(monsterDeath)` kept | p. 343 | happy |
| settle wrong check | `NotTriggered` passed | `ArgumentError` | FR-036 | unhappy (invalid input) |

### 4.5 Regeneration

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-040 | `RegenerationState.start(trait)` MUST hold the trait and `suppressed` false; the constructor throws `ArgumentError` for any other trait type. The host stores it with the monster's `HitPointStatus` (state in, state out). | SRD 5.2.1, "Troll", p. 333 | happy |
| FR-041 | `afterDamage(subject, dealtTypes)` MUST set `suppressed` when `dealtTypes` holds any of the trait's suppressing types, and add one `RegenerationSuppressed` event (`combatants == [subject]`) only when it was not already set; it returns a `RegenerationStep` (state, optional event). An RG-1 trait (no suppressing types), or no match, MUST return an equal state and no event. | SRD 5.2.1, "Troll", p. 333 | unhappy (rule interaction) |
| FR-042 | `atStartOfTurn(state, status, subject)` MUST, for an unsuppressed trait on a monster that qualifies (FR-043), return `RegenerationHealed` with the transition of `HitPointStatus.restore(subject, amount)` (never above the maximum, `hit-points-and-damage.md` FR-035, FR-036) and the state unchanged. Every `RegenerationTurn` variant carries the resulting `state`. Healing at the maximum regains 0 and adds no event. | SRD 5.2.1, "Oni", p. 312; "Healing", p. 17 | happy |
| FR-043 | The monster qualifies unless: `swarmCannotRegain` (it also has a `SwarmTrait`, FR-062); or `noHitPoints` (it is `Dead`, whatever the cause, for either variant: `restore` rejects Dead, `hit-points-and-damage.md` FR-075); or, for RG-1 only, its current Hit Points are below 1. A skip returns `RegenerationSkipped(reason)` with the status unchanged. RG-2 has no other Hit Point condition: a Stable creature at 0 qualifies. | SRD 5.2.1, "Oni", p. 312; "Troll", p. 333 | unhappy (boundary) |
| FR-044 | A suppressed trait MUST return `RegenerationSkipped(suppressed)` for exactly one turn start and clear `suppressed` in the returned state: "doesn't function on the troll's next turn". A second suppression before that turn still skips once. | SRD 5.2.1, "Troll", p. 333 | unhappy (boundary) |
| FR-045 | `Regeneration.deferDeath(trait, subject, transition)` for an RG-2 trait MUST, when the transition holds `DroppedToZeroHitPoints` and its status is `Dead` with cause `monsterDeath` or `massiveDamage`, or `Dying`, return `RegenerationDeathDeferred`: a `Stable` status at 0 Hit Points (rebuilt by `restore`, same maximum, rule and affinities), events = the transition's without `Died`, with `FellUnconscious` present once, then `RegenerationDeathDeferred`. The `massiveDamage` and `Dying` branches are reachable only for a creature given the `FallsUnconscious` rule (`hit-points-and-damage.md` FR-043). For RG-1, other causes or no drop it MUST return `RegenerationNotDeferred(reason)`. Interpretation (Q-2): the SRD gives a creature at 0 Hit Points that is not dead no named state; `Stable` (0 Hit Points, Unconscious, no Death Saving Throws) is the one that fits and lets Healing return it to `Alive` (`hit-points-and-damage.md` FR-038, FR-070). | SRD 5.2.1, "Troll", p. 333; "Monster Death", p. 17; "Stabilizing a Character", p. 18 | unhappy (rule interaction) |
| FR-046 | At the turn start of a deferred RG-2 creature that is suppressed, `atStartOfTurn` MUST return `RegenerationLetDie`: a `Dead(monsterDeath)` status at 0 Hit Points and the event `Died(monsterDeath)` (`hit-points-and-damage.md` FR-103). Unsuppressed, it heals (FR-042) and the creature is `Alive`. | SRD 5.2.1, "Troll", p. 333 ("dies only if it starts its turn with 0 Hit Points and doesn't regenerate") | happy |
| FR-047 | A `Died` from a cause other than a drop to 0 (`hitPointMaximumZero`, `exhaustion`) MUST NOT be deferred: the trait defers only the Monster Death and Massive Damage rule. | SRD 5.2.1, "Instant Death", p. 17 | unhappy (rule interaction) |

Cases RG-1 (one test per row; FR-041 to FR-047). Troll: 15, RG-2; Oni: 10, RG-1.

| Label | State and input | Expected | Source | Path |
|---|---|---|---|---|
| heals | Troll at 40 of 84, unsuppressed | 55 | p. 333 | happy |
| capped | Troll at 80 of 84 | 84, regained 4 | "Healing", p. 17 | unhappy (boundary) |
| at maximum | Troll at 84 | regained 0, no event | FR-042 | unhappy (empty and minimal) |
| Fire suppresses | `afterDamage({fire})`, then turn start | `Skipped(suppressed)`, flag cleared | p. 333 | unhappy (rule interaction) |
| Acid suppresses | `afterDamage({acid, slashing})` | suppressed, one event | FR-041 | unhappy (rule interaction) |
| Cold does not | `afterDamage({cold})` | equal state, no event | FR-041 | unhappy (rule interaction) |
| suppressed twice | two `afterDamage({fire})` | one event, one skipped turn | FR-044 | unhappy (boundary) |
| next turn heals | suppressed, two turn starts | skipped, then 15 | FR-044 | unhappy (boundary) |
| oni at 0 | Oni `Dead` | `Skipped(noHitPoints)` | p. 312 | unhappy (boundary) |
| oni at 1 | Oni at 1 of 66 | 11 | p. 312 | unhappy (boundary) |
| troll dropped | Troll to 0, `DiesInstantly` | `Stable` at 0, no `Died`, `FellUnconscious` once | FR-045 | happy |
| deferred then regen | Stable troll, turn start | 15, `Alive`, `Recovered` | FR-046 | happy |
| deferred then acid | Troll took Acid, then dropped, turn start | `LetDie`, `Died(monsterDeath)` | FR-046 | unhappy (rule interaction) |
| maximum drained | `Died(hitPointMaximumZero)` | `NotDeferred` | FR-047 | unhappy (rule interaction) |
| dead troll | Troll `Dead(hitPointMaximumZero)` at turn start | `Skipped(noHitPoints)`, status unchanged | FR-043 | unhappy (state error) |
| unconscious troll | `FallsUnconscious` troll to Dying (and a `massiveDamage` death), deferred | `Stable` at 0, no `Died`, `FellUnconscious` once | FR-045 | unhappy (rule interaction) |
| bad state | `RegenerationState` of a non-Regeneration trait; trait constructor with amount 0 | `ArgumentError` | FR-007, FR-040 | unhappy (invalid input) |
| swarm with trait | swarm and Regeneration | `Skipped(swarmCannotRegain)` | FR-043 | unhappy (rule interaction) |

### 4.6 Death Burst

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-050 | `DeathBurst.trigger(trait, subject, events)` MUST return `DeathBurstTriggered(part, ability, dc)` (the first saving throw of the part) when `events` holds a `Died` for `subject`, whatever its cause. | SRD 5.2.1, "Magmin", p. 305; "Mephits", p. 307 | happy |
| FR-051 | It MUST return `DeathBurstNotTriggered` when no `Died` for `subject` is present, including the events of an Undead Fortitude survival (FR-034) or a deferred death (FR-045), which carry no `Died`. A later `RegenerationLetDie` event list triggers it. | SRD 5.2.1, "Zombie", p. 343; "Troll", p. 333 | unhappy (rule interaction) |
| FR-052 | The burst is a fact only: its damage, Emanation size and targets are the part's `StatBlockSavingThrow` and clauses (`content-monsters.md` FR-038, FR-039). Nothing here rolls, targets or applies damage. | SRD 5.2.1, "Magmin", p. 305 | unhappy (boundary) |

### 4.7 Swarm

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-060 | `SwarmRules` MUST expose `canRegainHitPoints` false, `canGainTemporaryHitPoints` false, `sharesSpaces` true and `smallestOpening` `CreatureSize.tiny` for a recognised `SwarmTrait`. | SRD 5.2.1, "Swarm of Crawling Claws", p. 278; p. 361 | happy |
| FR-061 | `SwarmRules.check(trait, change)` MUST return `SwarmRefusal.cannotRegainHitPoints` for `SwarmHealing` and `cannotGainTemporaryHitPoints` for `SwarmTemporaryHitPoints`, and null (permitted) for `SwarmMaximumReduction`; the return type is `SwarmRefusal?`. The host calls it before `restore` or `gainTemporary`. | SRD 5.2.1, p. 278; "Temporary Hit Points", p. 18 | unhappy (rule interaction) |
| FR-062 | A monster with both a `SwarmTrait` and a `RegenerationTrait` MUST be skipped by Regeneration (FR-043): the swarm clause wins. Package design; no SRD swarm has Regeneration. | SRD 5.2.1, p. 278 | unhappy (rule interaction) |

### 4.8 Situational traits

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-070 | `PackTactics.circumstances(trait, allies)` MUST return `[Advantage()]` when at least one `AllyFact` has `distanceFeet` from 0 to 5 inclusive and `incapacitated` false, else an empty list. A negative distance throws `ArgumentError`. `distanceFeet` is the distance between the ally and the creature being attacked (the target), not the monster or the attacker. The host lists allies of the monster (not the monster) and decides `incapacitated` from the Incapacitated condition, which Paralyzed, Petrified, Stunned and Unconscious include (`conditions.md`). | SRD 5.2.1, "Wolf", p. 364; "Incapacitated", p. 184; conditions.md section 4 | happy |
| FR-071 | `SunlightPenalty.circumstances(trait, kind, inSunlight)` MUST return `[Disadvantage()]` when `inSunlight` and the kind is in scope, else empty. Scope `abilityChecksAndAttackRolls` covers `abilityCheck` and `attackRoll` and not `savingThrow`; `allD20Tests` covers all three. | SRD 5.2.1, "Drider", p. 281; "Shadow", p. 322 | unhappy (boundary) |
| FR-072 | `AmorphousRules` MUST expose `narrowestSpaceInches` 1 and `narrowOpeningCostsExtraMovement` false for a recognised `AmorphousTrait`. The extra movement it waives is the Difficult Terrain cost of "a narrow opening sized for a creature one size smaller than you"; the host MUST NOT mark narrow-opening squares `difficult` for this mover. No movement operation consults the fact, because terrain is host-supplied `GridTerrain` (Q-4). | SRD 5.2.1, "Black Pudding", p. 265; "Difficult Terrain", p. 181 | unhappy (boundary) |
| FR-073 | `Flyby.exemptsFromOpportunityAttack(trait, mode)` MUST be true only for `MovementMode.fly`, false for every other mode. It never changes `DepartureMeans`, and Disengage (`initiative-and-actions.md` FR-069) is unaffected. | SRD 5.2.1, "Hippogriff", p. 298; "Opportunity Attacks", p. 185 | unhappy (boundary) |
| FR-074 | `SiegeMonster.apply(trait, damages, recipient)` MUST return new `Damage` values with each amount doubled and the same type for `objectOrStructure`, and equal values for `creature`. An empty list throws `ArgumentError`. The doubling happens before the target's adjustments, Resistance and Vulnerability (a "multiplier" is applied first); interpretation. A structure is a `CompositeObject` of sections (`environment-hazards-and-objects.md` FR-114). | SRD 5.2.1, "Treant", p. 333; "Order of Application", p. 17; "Breaking Objects", pp. 177-178 | happy |
| FR-075 | `Parry.assess(trait, facts)` MUST return `ParryAvailable` only when `facts.attack.hit` is true, `isMeleeAttackRoll` is true and `holdingWeapon` is true; else `ParryUnavailable(reason)` with the first of `attackMissed`, `notMeleeAttackRoll`, `notHoldingWeapon`. It does not spend the Reaction: the host takes it first (`TakeReaction` with a `FeatureReaction`, `initiative-and-actions.md` FR-112, FR-134) and then calls `respond`. | SRD 5.2.1, "Bandit", p. 262; "Reactions", p. 10 | happy |
| FR-076 | `Parry.respond(trait, subject, attack)` (`subject` is the parrying monster) MUST re-resolve the attack with `AttackRollResult.resolve` (`d20-tests.md` FR-064) against an `ArmorClass` raised by the trait's bonus, keep the roll and modifiers, and return `ParryResponse(result, becameMiss)`; `becameMiss` is true when the original hit now fails. The original result is unchanged. | SRD 5.2.1, "Marilith", p. 306 ("possibly causing it to miss"); "Attack Rolls", p. 7 | happy |
| FR-077 | A natural 20 MUST stay a hit and a Critical Hit after Parry, and a natural 1 stays a miss: the natural-20 and natural-1 rules ignore the AC. | SRD 5.2.1, "Rolling 20 or 1", p. 7; d20-tests.md FR-029, FR-066 | unhappy (boundary) |
| FR-078 | `respond` on an attack that did not hit MUST throw `ArgumentError`; the bonus is the trait's printed number (2 to 5 in the SRD), not a table. | SRD 5.2.1, "Bandit", "Marilith", pp. 262, 306 | unhappy (invalid input) |

Cases PT-1: Parry and Pack Tactics (one test per row; FR-070 to FR-078). Attack roll total 15 against AC 14 unless stated.

| Label | Input | Expected | Source | Path |
|---|---|---|---|---|
| Parry +2 turns a hit | total 15 vs AC 14, bonus 2 | miss, `becameMiss` | p. 262 | happy |
| Parry exactly meets | total 16 vs AC 14, bonus 2 | still a hit | p. 262 | unhappy (boundary) |
| Parry +5 | total 18 vs AC 14, bonus 5 | miss (19 > 18) | p. 306 | unhappy (boundary) |
| natural 20 | natural 20, total 12, bonus 5 | hit and Critical Hit | p. 7 | unhappy (boundary) |
| missed attack | `hit` false | `ParryUnavailable(attackMissed)` | FR-075 | unhappy (state error) |
| respond on a miss | `respond` with `hit` false | `ArgumentError` | FR-078 | unhappy (invalid input) |
| ally at -1 | ally -1 ft | `ArgumentError` | FR-070 | unhappy (invalid input) |
| ranged attack | ranged hit | `ParryUnavailable(notMeleeAttackRoll)` | p. 262 | unhappy (rule interaction) |
| no weapon | melee hit, hands empty | `ParryUnavailable(notHoldingWeapon)` | p. 262 | unhappy (rule interaction) |
| ally at 5 | ally 5 ft, capable | `[Advantage]` | p. 364 | unhappy (boundary) |
| ally at 6 | ally 6 ft | empty | p. 364 | unhappy (boundary) |
| ally near monster only | ally 5 ft from the monster but 10 ft from the target (`distanceFeet` 10) | empty | p. 364 | unhappy (rule interaction) |
| ally at 0 | ally 0 ft | `[Advantage]` | FR-070 | unhappy (boundary) |
| ally incapacitated | only ally Incapacitated | empty | p. 364 | unhappy (rule interaction) |
| one capable of two | one Incapacitated, one capable, both 5 ft | `[Advantage]` | FR-070 | unhappy (rule interaction) |
| no allies | empty list | empty | FR-070 | unhappy (empty and minimal) |
| Amorphous fact | recognised `AmorphousTrait` | `narrowestSpaceInches` 1, `narrowOpeningCostsExtraMovement` false | FR-072, p. 181 | happy |
| sunlight, save | Sensitivity, saving throw, in sunlight | empty | p. 281 | unhappy (boundary) |
| sunlight, save, Weakness | Weakness, saving throw | `[Disadvantage]` | p. 322 | unhappy (boundary) |

### 4.9 Events, placement and API

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-090 | `LegendaryResistanceUsed`, `UndeadFortitudeSaved`, `RegenerationSuppressed`, `RegenerationDeathDeferred` and `ParryUsed` MUST be the members of one sealed `MonsterTraitEvent` implementing `CombatEvent`, with constant unique `kind`s (`legendary_resistance_used`, `undead_fortitude_saved`, `regeneration_suppressed`, `regeneration_death_deferred`, `parry_used`) and `combatants` equal to `[subject]`; each is `@immutable`, past tense, equal by value. `respond` returns `ParryUsed` (inside `ParryResponse`). Every emitting operation takes the `subject` `CombatantId` (`use`, `afterDamage`, `respond`, `settle`, `deferDeath`), so no event has an empty `combatants` (`combat-foundations.md` FR-018). The outcome variants of Legendary Resistance are `LegendaryResistanceApplied`/`Refused`, never the event's name. | `combat-foundations.md` FR-015 to FR-020; shared-types-and-ownership.md FR-019 | happy |
| FR-091 | Every operation MUST return a new value and leave its inputs unchanged; collections and event lists MUST be unmodifiable and ordered as they happened; none MUST throw for a rule refusal. Only FR-007, FR-013, FR-030, FR-036, FR-040, FR-070, FR-074, FR-078 throw `ArgumentError`. | architecture.md §3, §6 | unhappy (immutability) |
| FR-092 | The code MUST live under `lib/src/combat/domain/monster_traits/`, be synchronous and deterministic (no `Random`, `DateTime.now`, `Future`, `async`, `dart:io`), hold no `Logger`, `Tracer`, `Meter` or signal constant, and import only `shared_kernel`, the `content` and `d20_test` barrels and `combat` files left of it in the order of `combat-foundations.md` FR-024. No use case or port is added. | architecture.md §1, §3, §9; observability.md §3 | happy |
| FR-093 | The types of sections 3 and 5 MUST be exported from `lib/src/combat/combat.dart` and `lib/srd5e.dart` with a dartdoc each; no exported name MAY duplicate another barrel's or be generic (`Applied`, `Refused`). | architecture.md §4, §7; architecture-guardrails.md FR-077 | happy |
| FR-094 | A bundled-content test MUST recognise, in the bundled stat blocks (`content-monsters.md` FR-056), every part carrying one of the twelve names, with none left unrecognised, and the counts per trait MUST equal a committed fixture (derived once from the PDF pages cited in section 2). | SRD 5.2.1, pp. 258-364; content-monsters.md FR-056 | unhappy (missing content) |
| FR-095 | Nothing in the code, tests or data of this spec MAY name a consuming project or use content from outside SRD 5.2.1. | AGENTS.md ("Hard constraints") | happy |

## 5. Model

- **Value objects:** the twelve traits and `RecognisedTraits`, `UnrecognisedTrait`, `TraitRejection`; `SaveFailure`, sealed `LegendaryResistanceOutcome` (`LegendaryResistanceApplied(state, failure, effectiveOutcome, events)`, `LegendaryResistanceRefused(reason)`); `UndeadFortitudeFacts` and its sealed check and settlement types; `RegenerationState`, `RegenerationStep(state, event?)`, sealed `RegenerationTurn` (each variant carries `state`), `RegenerationDeferral` (`RegenerationDeathDeferred`, `RegenerationNotDeferred(reason)`); sealed `DeathBurstResult` (`DeathBurstTriggered`, `DeathBurstNotTriggered`); `SwarmRules`, sealed `SwarmChange` (`SwarmHealing`, `SwarmTemporaryHitPoints`, `SwarmMaximumReduction`), `SwarmRefusal`; `AllyFact`; `SunlightPenaltyScope`; `DamageRecipient`; `ParryFacts(attack, isMeleeAttackRoll, holdingWeapon)`, sealed `ParryOffer` (`ParryAvailable`, `ParryUnavailable(reason)`), `ParryResponse`. Each exported type has a dartdoc (FR-093).
- **Services (stateless, pure):** `MonsterTraits`, `LegendaryResistance`, `MagicResistance`, `UndeadFortitude`, `Regeneration`, `DeathBurst`, `SwarmRules`, `PackTactics`, `SunlightPenalty`, `Flyby`, `AmorphousRules`, `SiegeMonster`, `Parry`. Each is a `const`-constructible class with static or instance methods and no state.
- **Events:** sealed `MonsterTraitEvent` (FR-090). Events of other families (`LimitedUsePartSpent`, `DroppedToZeroHitPoints`, `Died`, `FellUnconscious`, `BecameBloodied`) are reused, never redefined; mixed lists are `List<CombatEvent>`.
- **Self-contained traits:** a trait copies the numbers it needs (amount, bonus, suppressing types) so no operation takes the `Monster` again.
- **Invariants:** FR-007, FR-030 and FR-040 in constructors (`ArgumentError`); `RegenerationState` holds a Regeneration trait only.
- **Failures:** no `Srd5eException` is defined and no port is used; rule refusals are results, caller errors are `ArgumentError` (architecture.md §6).

## 6. Interface

```dart
// lib/src/combat/domain/monster_traits/ (indicative signatures)
RecognisedTraits MonsterTraits.of(Monster monster);                                    // FR-001..FR-008
LegendaryResistanceOutcome LegendaryResistance.use(LimitedUseState state,
    LegendaryResistanceTrait trait, CombatantId subject, SaveFailure failure);         // FR-010..FR-014
List<RollCircumstance> MagicResistance.circumstances(MagicResistanceTrait t, SaveSourceKind source); // FR-020
UndeadFortitudeCheck UndeadFortitude.assess(UndeadFortitudeTrait t, HitPointTransitionApplied transition,
    UndeadFortitudeFacts facts);                                                       // FR-031..FR-033
UndeadFortitudeSettlement UndeadFortitude.settle(UndeadFortitudeCheck check, HitPointStatus before,
    HitPointTransitionApplied transition, CombatantId subject, D20TestOutcome outcome); // FR-034..FR-036
RegenerationStep RegenerationState.afterDamage(CombatantId subject, Set<DamageType> dealt);                 // FR-041
RegenerationTurn RegenerationState.atStartOfTurn(HitPointStatus status, CombatantId subject); // FR-042..FR-046
RegenerationDeferral Regeneration.deferDeath(RegenerationTrait t, CombatantId subject,
    HitPointTransitionApplied transition);                                             // FR-045, FR-047
DeathBurstResult DeathBurst.trigger(DeathBurstTrait t, CombatantId subject, List<CombatEvent> events); // FR-050
SwarmRefusal? SwarmRules.check(SwarmTrait t, SwarmChange change);                      // FR-061
List<RollCircumstance> PackTactics.circumstances(PackTacticsTrait t, List<AllyFact> allies); // FR-070
List<RollCircumstance> SunlightPenalty.circumstances(SunlightPenaltyTrait t, D20TestKind kind, bool inSunlight); // FR-071
bool Flyby.exemptsFromOpportunityAttack(FlybyTrait t, MovementMode mode);              // FR-073
List<Damage> SiegeMonster.apply(SiegeMonsterTrait t, List<Damage> damages, DamageRecipient r); // FR-074
ParryOffer Parry.assess(ParryTrait t, ParryFacts facts);                               // FR-075
ParryResponse Parry.respond(ParryTrait t, CombatantId subject, AttackRollResult attack);                    // FR-076..FR-078
```

- **Driving it.** Once per monster, `MonsterTraits.of` and keep the traits next to the monster's `LimitedUseState` and `HitPointStatus`. A save: ask `MagicResistance.circumstances` and merge with `RollMode.resolve`; after a failure offer `LegendaryResistance.use`. A hit: `applyDamage`, then `SiegeMonster.apply` beforehand if the target is an object, then `UndeadFortitude.assess`; if a save is required roll it through `ResolveD20Test` and call `settle`; `Regeneration.deferDeath`, `afterDamage` and `DeathBurst.trigger` follow on the resulting events. At a turn start: `atStartOfTurn`. An attack roll: `PackTactics` and `SunlightPenalty` circumstances join the host's list (`attacks.md` FR-044). An incoming hit: `Parry.assess`, take the Reaction, `respond`.
- **Exports:** every type of sections 3 and 5 from the `combat` barrel and `lib/srd5e.dart`. `lib/testing.dart` gains nothing.

## 7. Observability

**Silent by design** (observability.md §3): the spec is domain-only, adds no use case, port or signal, and `doc/observability/signals.md` is unchanged. Evaluation (observability.md §2):

1. Failure modes: content whose trait text differs from the template (an unrecognised trait, FR-002) and a host that forgets to call an operation (a missing Legendary Resistance, Undead Fortitude or Regeneration step).
2. How an operator knows: `RecognisedTraits.unrecognised` is returned data; the bundled-content test (FR-094) guards the SRD set. A forgotten call is not detectable by the engine.
3. Diagnosis: results carry the DC, damage taken, original save and events; nothing is hidden in attributes.
4. Counted or timed: the Constitution save and any `ApplyDamage` or `RestoreHitPoints` call by the host are already counted by `srd5e.d20_test.resolved` and the `combat` signals (`hit-points-and-damage.md` section 7); the uses of Legendary Resistance are state, not a signal.
5. Existing instrumentation is unchanged; nothing is misled because no use case wraps these functions.
6. Consumers monitor the existing signals of those specs; there is nothing new to alert on.
7. Nothing is noisy: no log exists.

| Signal | Type | Attributes | Purpose | Suggested monitoring |
|---|---|---|---|---|
| none | n/a | n/a | n/a | n/a |

## 8. Test plan

Paths: `test/combat/domain/monster_traits/` (unit); `test/scenarios/` (one). Doubles: none; hit-point, `LimitedUseState` and `AttackRollResult` fixtures are built with the real domain. Case tables are table-driven, one test per row (`Requirement: per case`).

| Id | Level | Notes |
|---|---|---|
| FR-001 to FR-004 | unit | `recognise_test.dart`: template rows of T-1 (one per trait and variant), wrong section, extra word, apostrophe and whitespace variants, unrelated part names |
| FR-005 to FR-007 | unit | `recognise_parameters_test.dart`: `PartUsage` other than `PartPerDay`; no saving throw; amount 0; unknown damage word; direct construction of `RegenerationTrait` (amount 0) and `ParryTrait` (bonus 0) throws `ArgumentError` |
| FR-008, FR-091 | unit | `immutability_test.dart`: equality and hash codes, `UnsupportedError` on lists, inputs unchanged, determinism |
| FR-010 to FR-014 | unit | `legendary_resistance_test.dart`: rolled and forced failures, refusal order, `ArgumentError` for an ability check, Aboleth 3 and 4 uses, Long Rest through `LimitedUseState` |
| FR-020 to FR-022 | unit | `magic_resistance_test.dart`: both sources; with `RollMode.resolve` against a Disadvantage and a second Advantage |
| FR-030 to FR-037 | unit | `undead_fortitude_test.dart`: UF-1, exact event lists, `restore` result, wrong-check `ArgumentError`, second drop |
| FR-040 to FR-047 | unit | `regeneration_test.dart`: RG-1 rows; deferral events; cause rows |
| FR-050 to FR-052, FR-060 to FR-062 | unit | `death_burst_test.dart`, `swarm_test.dart`: with and without `Died`, after Undead Fortitude and deferral; each `SwarmChange` |
| FR-070 to FR-078 | unit | `situational_traits_test.dart`: PT-1, sunlight scopes, Flyby per `MovementMode`, Siege Monster (creature, object, empty list, type kept), Amorphous constants |
| FR-090 | unit, architecture | `events_test.dart`: `kind`s, `combatants`, exhaustive `switch`; `test/architecture/`: kind uniqueness |
| FR-092, FR-093, FR-095 | architecture | directory purity, import allowlist, no signal code in `domain/`, barrel scan, consumer-name scan |
| FR-094 | scenario | `test/scenarios/`, public API only: `BundledContentSource` monsters through `MonsterTraits.of`, counts equal the fixture; one chain: Troll hit by Fire, dropped, deferred, turn start `LetDie` |

- **Mutation testing:** `lib/src/combat/domain/monster_traits` at a score of at least 80 (testing.md §8), watching the `0..5` inclusive bounds of FR-070, the `5 +` in FR-033, the exemption order of FR-032, the refusal order of FR-012 and the `>` versus `>=` of `becameMiss`.
- **Not covered:** nothing.

## 9. Open questions and decisions

Settled, one line each (web research confirmed the common reading in each case; every decision is justified by SRD text or package design):

- Q-1: Legendary Resistance applies to automatic and chosen failures (FR-011); the trait says "fails a saving throw" and lists no exception (interpretation).
- Q-2: A troll-type creature at 0 Hit Points is `Stable` and Unconscious until its turn starts (FR-045); the SRD names no other state, and `Stable` allows Healing back to `Alive`. Common practice reads it as unconscious and not rolling Death Saving Throws (interpretation).
- Q-3: Undead Fortitude is voided by any Radiant instance in the triggering command, and the DC uses `DamageTaken.total` including damage absorbed by Temporary Hit Points (FR-032, FR-033); "the damage" is one hit (interpretation).
- Q-4: Amorphous is a fact only (`narrowOpeningCostsExtraMovement` false): the SRD has no separate squeezing rule, but "Difficult Terrain", p. 181, makes a narrow opening cost extra movement, and terrain is host-supplied (FR-072).
- Q-5: Siege Monster doubles before the target's adjustments (FR-074); p. 17 applies "multipliers" first.
- Q-6: Parry re-resolves with a raised Armor Class, so a natural 20 still hits (FR-077); "Rolling 20 or 1", p. 7.
- Q-7: Traits are recognised by exact name plus text template, with parameters parsed from the verbatim text, rather than adding structured fields to `content-monsters.md`; no schema revision is needed and a host-supplied monster with changed wording is flagged, not misread (FR-002).
- Q-8: The Vampire's "Sunlight" damage rider and the Vorpal Sword's use of Legendary Resistance are left to the host and `magic-item-rules.md` (section 1).

Open: none. Escalated: none.

**Amendments for other specs:** A-1 (made) `shared-types-and-ownership.md` 4.11 rank 27 gains `monster-traits` beside `spell-effects` and `returning-to-life` (the guardrail rank check, `architecture-guardrails.md` FR-101, fails until the row exists, so land both together). A-2 (made) `documentation_index.md` gains a `specs/monster-traits.md` row. A-3 (not yet made) `CHANGELOG.md` `Unreleased` gets the section 10 entry.

## 10. Changelog impact

`Added` (combat): `MonsterTraits` recognition of twelve SRD traits and their rules (Legendary Resistance, Magic Resistance, Undead Fortitude, Regeneration, Death Burst, Swarm, Pack Tactics, Sunlight Sensitivity and Weakness, Flyby, Amorphous, Siege Monster, Parry), and the `MonsterTraitEvent` family. No signal added. Not **BREAKING**: nothing is released.
