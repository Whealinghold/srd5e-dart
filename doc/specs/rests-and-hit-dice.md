# Rests and Hit Dice

| | |
|---|---|
| Status | draft |
| Context | `character` |
| Roadmap phase | 3 |
| Depends on | `errors-and-results.md`, `dice-and-rolls.md`, `ability-scores.md`, `observability-ports.md`, `content-schema-and-decoder.md`, `derived-stats.md`, `character-aggregate.md` |

## 1. Purpose and scope

Specifies the Short Rest and Long Rest and spending Hit Point Dice, as the SRD
states them: durations, when a rest may start, what stops it and what an
interrupted one still confers, what a finished rest restores (Hit Points, Hit
Point Dice, a reduced Hit Point maximum, reduced ability scores, one Exhaustion
level, Temporary Hit Points, features), and the Hit Point Dice rule (spend one
die, roll it, add the Constitution modifier, at least 1 Hit Point regained).
That rule includes the one spend needing no rest: the Warlock's Lifedrinker
("expend one of your Hit Point Dice to roll it", SRD 5.2.1, "Lifedrinker",
p. 73), which updates the same `SpentHitDice` (FR-069). It **owns** `RestKind`
and the `RestApplied` event. Section 5.4 lists the deferrals it satisfies.

The package has no clock and no current Hit Points in `character`. The host
reports what happened (hours rested, what interrupted) and the facts the rules
need (current Hit Points, Exhaustion level); the spec returns what the rest
confers as effects the host applies in the context that owns each.

**Out of scope:**

- Applying Hit Points, Temporary Hit Points and a Hit Point maximum:
  `hit-points-and-damage.md`. The `Exhaustion` condition and its levels:
  `conditions.md` (this spec decides only that a Long Rest lowers it by 1, Q-4, and takes the level as a plain `int`).
- Exhaustion from dehydration or malnutrition, which "can't be removed" by a
  rest until the creature drinks or eats the full amount (SRD 5.2.1,
  "Dehydration", p. 181; "Malnutrition", p. 185): `environment-hazards-and-objects.md`
  (`RemoveExhaustionLevels`, Q-9).
- Each class feature's own recharge state: the `class-*.md` specs (Table R, 4.8,
  records which rest recharges what; a scenario test pins it). Spell slot
  recovery and prepared-spell changes: `spellcasting.md`.
- Monster Hit Dice ("A creature can spend Hit Dice during a Short Rest", SRD
  5.2.1, "Hit Point Dice", p. 183): the d4 to d20 dice of `content-monsters.md`;
  monsters are not `character` (Q-8).
- The sleeping Unconscious condition in a Long Rest (SRD 5.2.1, "Long Rest",
  p. 185) and the knocked-out creature's Short Rest ending Unconscious (SRD
  5.2.1, "Knocking Out a Creature", p. 17): Q-7.
- Attunement in a Short Rest (SRD 5.2.1, p. 102): `magic-item-rules.md`. Mounts
  needing a rest (p. 12): `exploration.md`. Feat renewal: `feats-behaviour.md`.
  They consume `RestKind`, the resolution and `RestApplied` (5.4).
- The sleep and light-activity requirements of a Long Rest ("sleep for at least
  6 hours and perform no more than 2 hours of light activity", SRD 5.2.1, "Long
  Rest", p. 185) and the Short Rest activity limit ("nothing more strenuous
  than reading, talking, eating, or standing watch", p. 187): host
  preconditions (FR-063).
- Effects that block or stand in for rest benefits: Sewer Plague (SRD 5.2.1,
  "Magical Contagions", p. 194), a pure filter in
  `toolbox-curses-and-contagions.md`; Demonic Possession (p. 193) reacts to `RestApplied(longRest)`; the Raise
  Dead and Resurrection penalty and strain (pp. 157, 159) are defined in
  `revival-and-restoration-spells.md` FR-016 to FR-022 (`ReviveOrdeal.afterRest`,
  `CasterStrain.afterRest` take `RestApplied.benefitsOf`); Prayer of Healing
  ("gain the benefits of a Short Rest", p. 154) uses FR-064.
- Reviving a dead creature (SRD 5.2.1, "Dead", p. 180); counting Long Rests for
  a feature (Greater Divine Intervention, p. 38: the class spec counts
  `RestApplied`); time (the host, `hit-points-and-damage.md` Q-12); any rule
  from another edition or outside SRD 5.2.1.

## 2. Source

- SRD 5.2.1, "Healing" and "Knocking Out a Creature", p. 17; "Temporary Hit
  Points", "Duration", p. 18; "Rest" sidebar, p. 16; "Character Creation",
  Step 5, "Hit Point Dice", p. 22; "Gaining a Level", step 2, p. 23;
  "Multiclassing", "Hit Points and Hit Point Dice", p. 25.
- SRD 5.2.1, "Rules Glossary": "Exhaustion", p. 181; "Hit Points", "Hit Point
  Dice", p. 183; "Long Rest", p. 185; "Per Day", p. 186; "Short Rest", p. 187.
- Rest triggers in class text (Tables R, W): Barbarian p. 28 to 30; Bard p. 32;
  Cleric p. 37, 38; Druid p. 42, 43, 46; Fighter p. 48; Monk p. 50 to 52;
  Paladin p. 53 to 55, 57; Ranger p. 58, 59, 61; Rogue p. 62, 63; Sorcerer
  p. 65, 66, 70; Warlock p. 71 to 74, 76; Wizard p. 77 to 79, 82.
- Species and feats: "Dwarf", "Dragonborn", "Elf" (Elven Lineage), p. 84; "Elf"
  (Trance), "Gnome", p. 85; "Goliath", pp. 85 to 86; "Human", "Orc",
  "Tiefling" (Fiendish Legacy), p. 86; "Magic Initiate", p. 87; "Boon of
  Fate", p. 88. Warlock "Lifedrinker", p. 73.
- Out of scope, section 1: "Prayer of Healing", p. 154; "Raise Dead",
  "Resurrection", pp. 157, 159; "Demonic Possession", p. 193; "Magical
  Contagions", p. 194.

## 3. Vocabulary

| SRD term | Type | Notes |
|---|---|---|
| Short Rest, Long Rest | `RestKind` (`shortRest`, `longRest`) | Owned here (`shared-types-and-ownership.md` FR-009). Reported by the host. |
| "Rolling Initiative", "Casting a spell other than a cantrip", "Taking any damage", "1 hour of walking or other physical exertion" | `RestInterruption` (`rollingInitiative`, `castingSpellOtherThanCantrip`, `takingDamage`, `physicalExertion`) | The Interrupting the Rest lists, pp. 185, 187. The Short Rest list has three entries; `physicalExertion` also stops a Short Rest by its definition (p. 187, FR-019, Q-10). |
| Interrupting the Rest | `RestEnd` (sealed: `RestRanItsCourse`, `RestStopped`) | How the host reports a rest ended. |
| (a rest report) | `RestReport` | Kind, Long Rest variant, and a `RestEnd`; `RestReport.tryCreate` for host input (FR-066). |
| Trance ("finish a Long Rest in 4 hours") | `LongRestVariant` (`standard`, `trance`) | The host says whether the creature has the trait. |
| "wait at least 16 hours before starting another one" | `LongRestSpacing` | Time comes from the host. |
| Hit Point Dice | `HitPointDie` (`content-schema-and-decoder.md` FR-132, published by `content`, `shared-types-and-ownership.md` FR-053: `d6`, `d8`, `d10`, `d12`, fact `faces`; no die type is defined here); pool `HitDicePool` (`derived-stats.md` FR-061, FR-070); spent ones `SpentHitDice` (owned here). The use case rolls `DiceExpression(1, Die(die.faces))` | |
| Special Feature (recharged by a rest) | `FeaturesRecharged(RestKind)`; `RechargeTrigger` (`content-schema-and-decoder.md` FR-112); `RestKind.recharges(RechargeTrigger)` | The mapping is owned here (`shared-types-and-ownership.md` FR-009; FR-032, FR-065). |
| Exhaustion level | plain `int` 0 to 6 | `conditions.md` owns `ExhaustionLevel`; `character` cannot import it (Q-4). |

## 4. Requirements

Ids are stable. Required hours: Short Rest 1, Long Rest 8, Long Rest with Trance
4. All hours are whole hours.

### 4.1 Vocabulary and durations

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-001 | `RestKind` MUST have exactly two values, `shortRest` and `longRest`, and no other rest value. | SRD 5.2.1, "Short Rest", p. 187; "Long Rest", p. 185 | happy |
| FR-002 | The minimum duration of a Short Rest MUST be 1 hour. | SRD 5.2.1, "Short Rest" ("a 1-hour period of downtime"), p. 187 | happy |
| FR-003 | The minimum duration of a Long Rest of the `standard` variant MUST be 8 hours. | SRD 5.2.1, "Long Rest" ("at least 8 hours"), p. 185 | happy |
| FR-004 | The minimum duration of a Long Rest of the `trance` variant MUST be 4 hours. The variant MUST NOT change a Short Rest. | SRD 5.2.1, "Elf", Trance, p. 85 | happy |
| FR-005 | `RestInterruption` MUST have exactly four values: `rollingInitiative`, `castingSpellOtherThanCantrip`, `takingDamage`, `physicalExertion`. Casting a cantrip MUST NOT be representable as an interruption. | SRD 5.2.1, "Long Rest", "Interrupting the Rest", p. 185; "Short Rest", p. 187 | unhappy (boundary: cantrip) |
| FR-006 | The interruptions that stop a Short Rest MUST be `rollingInitiative`, `castingSpellOtherThanCantrip` and `takingDamage` (its list) and `physicalExertion` (inference from its definition, "nothing more strenuous than reading, talking, eating, or standing watch", Q-10); those that stop a Long Rest MUST be all four (table 4.8a). | SRD 5.2.1, "Short Rest", "Interrupting the Rest" and definition, p. 187; "Long Rest", p. 185 | happy |

### 4.2 Starting a rest

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-007 | A Short Rest MUST be startable with at least 1 current Hit Point, and MUST NOT be startable at 0 (`RestMayNotStart` with `RestStartNoHitPoints`). A creature at exactly 1 Hit Point, as a knocked-out creature is, MAY start one. | SRD 5.2.1, "Short Rest" ("you must have at least 1 Hit Point"), p. 187; "Knocking Out a Creature", p. 17 | unhappy (boundary: 0 and 1) |
| FR-008 | A Long Rest MUST be startable with at least 1 current Hit Point, and MUST NOT be startable at 0 (`RestStartNoHitPoints`). | SRD 5.2.1, "Long Rest" ("you must have at least 1 Hit Point"), p. 185 | unhappy (boundary: 0 and 1) |
| FR-009 | A Long Rest MUST NOT be startable fewer than 16 hours after the previous Long Rest finished (only a `RestCompleted(longRest)` counts as finished, FR-072; `RestStartTooSoonAfterLongRest(hoursStillToWait)`, where `hoursStillToWait` is 16 minus the hours since the previous Long Rest, at least 1); at exactly 16 hours it MUST be startable; with no previous Long Rest it MUST NOT be blocked by spacing. | SRD 5.2.1, "Long Rest" ("you must wait at least 16 hours before starting another one"), p. 185 | unhappy (boundary: 15, 16, 17 hours) |
| FR-010 | A Short Rest MUST NOT be blocked by `LongRestSpacing`: one may be taken straight after a Long Rest finished. | SRD 5.2.1, "Rest" paragraph ("hour-long Short Rests in the midst of a day and an 8-hour Long Rest to end it"), p. 16; "Short Rest", p. 187 (no spacing rule) | unhappy (rule interaction) |
| FR-011 | A creature with Exhaustion level 6 MUST NOT be able to start either rest (`RestStartExhaustionLevelSix`). Inference: a creature at level 6 has died, so it cannot rest (Q-10). | SRD 5.2.1, "Exhaustion", "Exhaustion Levels" ("You die if your Exhaustion level is 6"), p. 181 | unhappy (state error) |
| FR-012 | When several blockers apply, `RestMayNotStart` MUST list every one, once each, in the fixed order `RestStartNoHitPoints`, `RestStartExhaustionLevelSix`, `RestStartTooSoonAfterLongRest`, and never only the first. | architecture.md section 5 (list every problem, not only the first); testing.md section 4 (unhappy-path coverage) | unhappy (rule interaction) |
| FR-013 | A negative current Hit Points value, a negative hours value or an Exhaustion level outside 0 to 6 MUST throw `ArgumentError` from the plain constructors and domain functions (a host precondition, not a rule outcome). `TakeRestCommand.tryCreate` returns a sealed rejection for the same inputs instead (FR-066). | architecture.md section 6 | unhappy (invalid input) |

### 4.3 Ending a rest: completion and interruption
`RestRanItsCourse(hoursRested, interruptionsResumed)` says the rest was not
stopped and lasted that long after resuming `interruptionsResumed` times.
`RestStopped(interruption, hoursRestedBefore, interruptionsResumed)` says it was
stopped by that interruption after `hoursRestedBefore` hours, resumed that many
times before (FR-071 needs the count). Hours are cumulative totals (FR-067); the
1-hour threshold of FR-020 and FR-021 is on the total, not per segment.

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-014 | `RestRanItsCourse` with `hoursRested` at or above the required hours MUST resolve to `RestCompleted(kind)`, which grants the benefits of that `RestKind`. | SRD 5.2.1, "Short Rest", "Benefits of the Rest" ("When you finish the rest"), p. 187; "Long Rest", p. 185 | happy |
| FR-015 | `RestRanItsCourse` with `hoursRested` below the required hours MUST resolve to `RestIncomplete(hoursStillNeeded)` and grant nothing. One hour short MUST give `hoursStillNeeded` 1. | SRD 5.2.1, "Short Rest", p. 187; "Long Rest", p. 185 | unhappy (boundary) |
| FR-016 | A Long Rest resumed after `n` interruptions MUST require the base hours plus `n` ("1 additional hour per interruption") of total rested time (FR-067). With the `trance` variant the base is 4 (inference, Q-12). | SRD 5.2.1, "Long Rest", "Interrupting the Rest", p. 185 | unhappy (boundary) |
| FR-017 | A Short Rest report with `interruptionsResumed` above 0 (on `RestRanItsCourse` or on `RestStopped`) MUST resolve to `RestReportRejected(ShortRestCannotBeResumed)`, the one variant of the sealed `RestReportRejection`: a rule result of `RestResolution.resolve`, not a creation failure, because the report is well-typed (FR-066). The SRD gives resumption for a Long Rest only (Q-11). | SRD 5.2.1, "Long Rest" ("You can resume a Long Rest immediately after an interruption"), p. 185; "Short Rest" ("An interrupted Short Rest confers no benefits"), p. 187 | unhappy (state error) |
| FR-018 | A Short Rest stopped by `rollingInitiative`, `castingSpellOtherThanCantrip` or `takingDamage` MUST resolve to `RestStoppedWithoutBenefits`, however many hours had been rested. | SRD 5.2.1, "Short Rest", "Interrupting the Rest" ("An interrupted Short Rest confers no benefits"), p. 187 | unhappy (state error) |
| FR-019 | A Short Rest reported as stopped by `physicalExertion` MUST resolve to `RestStoppedWithoutBenefits`, however many hours had been rested, exactly as FR-018. Inference: the Short Rest definition allows nothing more strenuous than reading, talking, eating or standing watch, so strenuous activity ends it even though the three-entry list omits it; the host can therefore report a Short Rest that was spent exerting (Q-10). | SRD 5.2.1, "Short Rest" (definition and "Interrupting the Rest"), p. 187 | unhappy (state error) |
| FR-020 | A Long Rest stopped by any of the four interruptions after at least 1 hour rested and fewer hours than the required hours of FR-014 and FR-016 (FR-071) MUST resolve to `RestStoppedWithShortRestBenefits`, which grants the benefits of `RestKind.shortRest`. | SRD 5.2.1, "Long Rest" ("If you rested at least 1 hour before the interruption, you gain the benefits of a Short Rest"), p. 185 | happy |
| FR-021 | A Long Rest stopped after 0 hours rested MUST resolve to `RestStoppedWithoutBenefits`; after exactly 1 hour it MUST resolve as FR-020. | SRD 5.2.1, "Long Rest", p. 185 | unhappy (boundary: 0 and 1 hour) |
| FR-022 | Every one of the four interruptions MUST stop a Long Rest (table 4.8a). | SRD 5.2.1, "Long Rest", "Interrupting the Rest", p. 185 | happy |
| FR-023 | A negative `hoursRested`, `hoursRestedBefore` or `interruptionsResumed` (on either `RestEnd` variant) MUST throw `ArgumentError` from the plain constructors. `RestReport.tryCreate` is for host-supplied reports and returns a sealed rejection instead (FR-066). | architecture.md section 6 | unhappy (invalid input) |

### 4.4 Benefits of a rest
`RestBenefits.of(benefitsOf, exhaustionLevel, spentHitDice)` returns the effects in
the fixed order of FR-034. Effects that would change nothing for a known reason
are left out (FR-026, FR-029); the others are always present because the host
knows the current Hit Points, maximum, ability scores and Temporary Hit Points.

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-024 | The benefits of a Short Rest MUST be exactly two effects: `SpendHitPointDiceAvailable` and `FeaturesRecharged(shortRest)`. | SRD 5.2.1, "Short Rest", "Benefits of the Rest", p. 187 | happy |
| FR-025 | The benefits of a Long Rest MUST include `AllLostHitPointsRegained`. | SRD 5.2.1, "Long Rest", "Regain All HP", p. 185 | happy |
| FR-026 | The benefits of a Long Rest MUST include `HitPointDiceRegained(count)` with `count` equal to the total number of spent Hit Point Dice when that total is above 0, and MUST omit it when none are spent. The spent dice then become none. | SRD 5.2.1, "Long Rest", "Regain All HP" ("all lost Hit Points and all spent Hit Point Dice"), p. 185 | happy / unhappy (boundary: 0 spent) |
| FR-027 | The benefits of a Long Rest MUST include `HitPointMaximumReturnedToNormal`, an effect the host applies to its Hit Point maximum (Q-15). | SRD 5.2.1, "Long Rest" ("If your Hit Point maximum was reduced, it returns to normal"), p. 185 | happy |
| FR-028 | The benefits of a Long Rest MUST include `AbilityScoresReturnedToNormal`, an effect the host applies by lifting its ability score reductions (Q-15). | SRD 5.2.1, "Long Rest", "Ability Scores Restored", p. 185 | happy |
| FR-029 | The benefits of a Long Rest at Exhaustion level `n` of 1 or more MUST include `ExhaustionLevelReduced(from: n, to: n - 1)`, and MUST omit it at level 0. Level 1 gives `to` 0, which is the end of the condition. The effect states the Long Rest rule alone; the host applies it through `environment-hazards-and-objects.md` `RemoveExhaustionLevels` (levels 1), which withholds levels locked by Dehydration or Malnutrition (SRD 5.2.1, pp. 181, 185; Q-9), so a blocked removal leaves the level unchanged. | SRD 5.2.1, "Long Rest", "Exhaustion Reduced", p. 185; "Exhaustion", "Removing Exhaustion Levels", p. 181 | unhappy (boundary: 0, 1, 2, 5) |
| FR-030 | The benefits of a Long Rest MUST include `TemporaryHitPointsEndedByRest` (a name distinct from any event: the effect is data the host applies, not something that happened, FR-059). The benefits of a Short Rest MUST NOT. | SRD 5.2.1, "Temporary Hit Points", "Duration" ("until they're depleted or you finish a Long Rest"), p. 18 | happy / unhappy (rule interaction) |
| FR-031 | The benefits of a Long Rest MUST include `FeaturesRecharged(longRest)`. | SRD 5.2.1, "Long Rest", "Special Feature", p. 185 | happy |
| FR-032 | `FeaturesRecharged(kind)` MUST mean `kind.recharges(trigger)` of `RestKind.recharges(RechargeTrigger)` (FR-065, table 4.8f), where `RechargeTrigger` is the `content`-owned enum of `content-schema-and-decoder.md` FR-112: `shortRest` recharges a feature whose trigger is `shortRest` or `shortOrLongRest`; `longRest` one whose trigger is `longRest` or `shortOrLongRest`. A Long Rest MUST NOT count as also finishing a Short Rest for features that say Short Rest only (Q-8). A "Per Day" feature is data with trigger `longRest` (SRD "Per Day": "you must finish a Long Rest to use it again"). How much is regained (one use, all uses) is the feature's own rule. | SRD 5.2.1, "Short Rest", "Special Feature", p. 187; "Long Rest", "Special Feature", p. 185; "Per Day", p. 186 | happy |
| FR-033 | The benefits of a Short Rest MUST NOT include any Hit Point, Hit Point Dice, Hit Point maximum, ability score, Exhaustion or Temporary Hit Points effect. | SRD 5.2.1, "Short Rest", p. 187 | unhappy (rule interaction) |
| FR-034 | The effects of a Long Rest MUST be ordered `AllLostHitPointsRegained`, `HitPointDiceRegained`, `HitPointMaximumReturnedToNormal`, `AbilityScoresReturnedToNormal`, `ExhaustionLevelReduced`, `TemporaryHitPointsEndedByRest`, `FeaturesRecharged`, skipping omitted ones, so equal inputs give equal lists. The order is package design: it follows the SRD list (Regain All HP, which covers Hit Points, Hit Point Dice and the Hit Point maximum; Ability Scores Restored; Exhaustion Reduced; Special Feature) with the Hit Point Dice and Hit Point maximum split out and the Temporary Hit Points ending (p. 18) placed before the features. | package design; SRD 5.2.1, "Long Rest", "Benefits of the Rest", p. 185; "Temporary Hit Points", "Duration", p. 18 (inputs) | unhappy (determinism) |
| FR-035 | `RestStoppedWithShortRestBenefits` MUST give exactly the effects of FR-024. `RestStoppedWithoutBenefits`, `RestIncomplete` and a rejected report MUST give no effects and leave the spent Hit Point Dice unchanged. | SRD 5.2.1, "Long Rest", p. 185; "Short Rest", p. 187 | unhappy (state error) |
| FR-036 | `RestApplied(characterId, benefitsOf, source, effects)` MUST be a past-tense event naming the `RestKind` whose benefits were applied (`shortRest` for an interrupted Long Rest, FR-020), the `RestSource` (`finished`, or `longRestInterrupted` for FR-020, FR-061) and the effect list. `RestInterrupted(characterId, kind, interruption, benefitsGranted)` MUST be raised for every rest that resolves to `RestStoppedWithShortRestBenefits` or `RestStoppedWithoutBenefits`, and for no other result; a stop that FR-071 resolves to `RestCompleted` raises `RestApplied` only (LI-11 to LI-13, LI-15). It carries `benefitsGranted` of the sealed type `RestBenefitsGranted` (`RestBenefitsOfShortRest`, `RestBenefitsNone`). Both are variants of the sealed `RestEvent` family (FR-068). | architecture.md section 3 (domain events); `shared-types-and-ownership.md` FR-019, FR-020; `character-aggregate.md` FR-085 | happy |

### 4.5 Hit Point Dice
`SpentHitDice` holds how many dice of each size are spent, keyed by
`HitPointDie`; the pool is the `HitDicePool` of `derived-stats.md` (FR-061,
FR-070: a count per `HitPointDie`, entries by ascending faces). An absent pool
key means 0 (Q-5); no `countOf` accessor is assumed. "d8" means `HitPointDie.d8`.

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-037 | `SpentHitDice` MUST hold a count of at least 1 for each `HitPointDie` listed and omit dice with none spent, so equal spent sets compare equal; a count below 1 MUST throw `ArgumentError` from the plain constructor (host-stored counts go through `SpentHitDice.tryCreate`, FR-073). A die other than d6, d8, d10 or d12 cannot be expressed, because `HitPointDie` is a closed enum. Entries are ordered by ascending `HitPointDie.faces`, as in the pool. | SRD 5.2.1, "Hit Point Dice", p. 22 ("note how many Hit Dice you've spent"); class "Hit Point Die" traits, pp. 28 to 77 | unhappy (invalid input) |
| FR-038 | The dice left of a size MUST be the pool's count of that size minus the spent count, and MUST NOT be negative. A `SpentHitDice` whose count for any size exceeds the pool's count (host-stored state that disagrees with the pool) MUST make `trySpend` and `trySpendOutsideRest` return `HitDieSpendRejected(spentExceedsPool)` and change nothing; no operation throws for it (FR-073). `TakeRest` has no pool and does not check this: a Long Rest clears every spent die (FR-026). | SRD 5.2.1, "Hit Point Dice", p. 22; "Multiclassing", p. 25 | unhappy (invalid input) |
| FR-039 | `SpentHitDice.trySpend(pool, die, benefitsOf)` (`benefitsOf` the `RestKind` whose benefits are claimed) with at least one die of that size left and `benefitsOf` `shortRest` MUST return `HitDieSpendAllowed` with the spent count of that size raised by 1, the other sizes unchanged, and the original value unchanged. | SRD 5.2.1, "Short Rest", "Spend Hit Point Dice" ("spend one or more of your Hit Point Dice"), p. 187 | happy |
| FR-040 | `trySpend` of a size with none left MUST return `HitDieSpendRejected(noneRemaining)`. `trySpend` of a size the pool has none of MUST return `HitDieSpendRejected(notInPool)`. Neither changes the state. When several reasons apply, the reported one follows the fixed order `notAShortRestBenefit` (FR-045), `spentExceedsPool` (FR-038), `notInPool`, `noneRemaining`. | SRD 5.2.1, "Hit Point Dice", p. 183 ("A creature can spend Hit Dice during a Short Rest"); "Multiclassing", p. 25 | unhappy (boundary: last die, no die) |
| FR-041 | Dice of different sizes MUST be tracked separately: spending a d8 MUST NOT change the d10 count, and a level 5 Cleric and level 5 Paladin MUST have five d8 and five d10 dice to spend. | SRD 5.2.1, "Multiclassing", "Hit Points and Hit Point Dice", p. 25 | unhappy (rule interaction) |
| FR-042 | A level 1 character, whose pool is one die, MUST be able to spend one die and then none (second spend `noneRemaining`). Gaining a level adds one die to the pool and leaves the spent dice unchanged, so one more die is left to spend. | SRD 5.2.1, "Step 5", "Hit Point Dice" ("At level 1, your character has 1 Hit Die"), p. 22; "Gaining a Level", step 2 ("you gain an additional Hit Die"), p. 23; `character-aggregate.md` FR-037 | unhappy (boundary) |
| FR-043 | The Hit Points regained by spending one die MUST be the die roll plus the Constitution modifier, and at least 1 (table 4.8c). | SRD 5.2.1, "Short Rest", "Spend Hit Point Dice" ("You regain Hit Points equal to the total (minimum of 1 Hit Point)"), p. 187 | happy / unhappy (boundary) |
| FR-044 | A die roll below 1 or above `HitPointDie.faces` passed to `HitDieRecovery.hitPointsRegained` MUST throw `ArgumentError` naming `roll`. A `SpendHitPointDie` run cannot reach it, because a `RollResult` cannot hold a face its die does not have (`dice-and-rolls.md` FR-032); the check guards a host that supplies a roll directly (FR-054 reads the face from `RollResult.diceTotal`). | dice-and-rolls.md FR-032 (a roll is within its die); architecture.md section 6 | unhappy (invalid input) |
| FR-045 | Spending Hit Point Dice in a rest MUST be allowed only when the benefits being claimed are those of `RestKind.shortRest` (a finished Short Rest, or a Long Rest that earned them under FR-020). `SpentHitDice.trySpend(pool, die, benefitsOf)` MUST do this check: `benefitsOf` `longRest` MUST be rejected as `HitDieSpendRejected(notAShortRestBenefit)` (Q-3), and the `SpendHitPointDie` use case MUST only pass its command's `RestKind` to it and hold no rule of its own (FR-052, FR-053). The check does not apply to `trySpendOutsideRest` (FR-069). | SRD 5.2.1, "Short Rest", "Benefits of the Rest", p. 187 (listed there only) | unhappy (state error) |
| FR-046 | Each spend MUST be one die, so the host decides whether to spend another after seeing each roll. There MUST be no operation that spends several dice at once. | SRD 5.2.1, "Short Rest" ("You can decide to spend an additional Hit Point Die after each roll"), p. 187 | happy |
| FR-047 | The result of a spend MUST carry the amount of Hit Points regained uncapped by the Hit Point maximum. Capping belongs to the host that applies Hit Points (non-normative hand-off to `hit-points-and-damage.md`: Hit Points regained in excess of the maximum are lost). | SRD 5.2.1, "Healing", p. 17; "Hit Points", p. 183 | unhappy (boundary) |
| FR-048 | `SpentHitDice` and every collection it exposes MUST be unmodifiable; mutating one MUST throw `UnsupportedError`, and an operation MUST NOT change its input. | architecture.md section 4 (handoffs), section 3 | unhappy (immutability) |

### 4.6 Use cases
Both use cases are synchronous; `TakeRest` calls only `Observability`, `SpendHitPointDie` also the `DiceRoller`.

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-049 | `TakeRest` MUST return `TakeRestApplied` (the new `SpentHitDice` and the `RestApplied` event, whose `effects` are the effects) for `RestCompleted`, and `TakeRestAppliedAfterInterruption` (the same, plus the `RestInterrupted` event) for `RestStoppedWithShortRestBenefits`. Both are variants of the sealed `TakeRestResult`; no field holds a null or a flag for the other case. | SRD 5.2.1, "Long Rest", p. 185; "Short Rest", p. 187 | happy |
| FR-050 | `TakeRest` MUST return `TakeRestNotStarted(blockers)` when FR-007 to FR-011 block the rest, evaluated on the values at the start of the rest (FR-070), with the list of FR-012, before it looks at the end of the rest. | SRD 5.2.1, "Short Rest", p. 187; "Long Rest", p. 185 (conditions to start) | unhappy (state error) |
| FR-051 | `TakeRest` MUST return `TakeRestIncomplete(hoursStillNeeded)` for FR-015, `TakeRestStopped` (with `RestInterrupted`, no effects) for `RestStoppedWithoutBenefits`, and `TakeRestRejected(problem)` for FR-017 (`problem` is a `RestReportRejection`). The `SpentHitDice` MUST be returned unchanged in all three. | SRD 5.2.1, "Long Rest", p. 185; "Short Rest", p. 187 | unhappy (state error) |
| FR-052 | `TakeRest` MUST contain no rule logic: every outcome is the one the domain functions of 4.2 to 4.4 return for the same inputs. | architecture.md section 4 (a use case orchestrates) | happy |
| FR-053 | `SpendHitPointDie` MUST check the spend by calling `SpentHitDice.trySpend(pool, die, benefitsOf)` (FR-039, FR-040, FR-045) before it rolls, and on a rejection MUST NOT call the `DiceRoller`. | architecture.md section 4; testing.md section 4 | unhappy (state error) |
| FR-054 | On an allowed spend `SpendHitPointDie` MUST build `DiceExpression(1, Die(die.faces))` from the chosen `HitPointDie` (modifier 0), roll it exactly once through `DiceRoller.rollChecked`, read the face from the single `DieRoll` (`RollResult.diceTotal`), and return `SpendHitPointDieApplied` with the roll, the Constitution modifier, the Hit Points regained (FR-043), the new `SpentHitDice` and the `HitPointDieSpent` event. | SRD 5.2.1, "Short Rest", "Spend Hit Point Dice" ("roll the die and add your Constitution modifier"), p. 187; dice-and-rolls.md FR-006, FR-050 | happy |
| FR-055 | A `DiceRollerException` from the roller MUST propagate unchanged and the state MUST NOT change; the use case MUST NOT swallow it. A roller that returns a result for a different expression (a different count, die or modifier) makes `rollChecked` throw `DiceRollerException(invalidResult)`, which MUST propagate unchanged and leave the state unchanged. A roll outside the die cannot reach the use case (FR-044). | architecture.md section 4 (port failure contract); dice-and-rolls.md FR-050, FR-051, FR-052 | unhappy (failure of a collaborator) |
| FR-056 | With fixed rolls `SpendHitPointDie` MUST return the Hit Points of table 4.8c, including the extremes (roll 1 with a negative modifier, roll equal to the die's faces with a positive one). | SRD 5.2.1, "Short Rest", p. 187 | unhappy (determinism) |
| FR-057 | Each use case MUST return an equal result with the no-op `Observability` and with a recording one, and MUST emit the signals of section 7, including for a thrown `DiceRollerException`: `srd5e.outcome` `failure`, `error.type` `dice_roller_exception` and no `srd5e.character.result`. | observability.md section 9 | happy |
| FR-058 | Neither use case MUST read or hold current Hit Points, a clock or a `Character`; the effects they return are data the host applies in the contexts that own them (non-normative hand-off, 5.4). | `shared-types-and-ownership.md` FR-013 | happy |

### 4.7 Public surface and hand-offs

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-059 | Every type this spec exports (section 6) MUST be defined once, here, and exported from `character.dart` and `srd5e.dart`. No other type named `RestKind` or `RestApplied`, no `RestKind` member spelled `short` or `long`, and no exported name equal to one of this spec's names, MAY exist in the package (`shared-types-and-ownership.md` FR-021). The rest effect `TemporaryHitPointsEndedByRest` is data the host applies and MUST NOT share a name with any event, and no `RestEffect` variant, blocker, event, result or command name may equal an export of another spec (grep over `doc/specs/` and the barrel scan). Every type named in 5.1, including `RestReportRejection`, `HitDieSpendRejection`, `RestBenefitsGranted`, `RestReportProblem`, `TakeRestCommandProblem`, `SpentHitDiceProblem` and `SpendHitPointDieCommandProblem` with their members, is in that export list and the scan. Variants carry an operation prefix (`RestStart...`, `RestBenefits...`, `TakeRest...`, `SpendHitPointDie...`, `HitDieSpend...`) and no generic name (`Applied`, `Rejected`) is exported (`shared-types-and-ownership.md` FR-017). | `shared-types-and-ownership.md` FR-009, FR-017, FR-019, FR-020, FR-021; architecture.md section 9 (duplicate-name barrel scan) | unhappy (duplicate) |
| FR-060 | Every class, species or feat function that reacts to finishing a rest MUST take a `RestKind` (or the `RestApplied` event) from this spec, or a context-local trigger enum mapped from it one to one (`feats-behaviour.md` `FeatRenewal`: `shortRestFinished` from `shortRest`, `longRestFinished` from `longRest`), and MUST accept both rest values, so a Short Rest and a Long Rest are each handled (Table R). | `shared-types-and-ownership.md` FR-009, FR-023 | happy |
| FR-061 | Table W (4.8) lists the "whenever you finish a ... Rest, you can ..." windows. `RestApplied` with `benefitsOf` `longRest` MUST be the only trigger a window that names a Long Rest accepts, and `RestApplied` with `benefitsOf` `shortRest` and `source` `finished` the only trigger for one that names a Short Rest. A window naming Short or Long Rest MUST accept `source` `finished` of either kind. Every "when/whenever you finish a Short Rest" window of Table W (W-3, W-11 to W-14 included) is a window, not a recharge: it MUST accept `source` `finished` only, so an interrupted Long Rest never enables Natural Recovery, Tireless, Sorcerous Restoration or Arcane Recovery (their once-until-Long-Rest limits are recharges and stay in Table R). An interrupted Long Rest gives `RestApplied(shortRest)` with `source` `longRestInterrupted`: it recharges features (FR-020, FR-032) but opens no "finish a Short Rest" window. Inference: the SRD says the creature "gains the benefits of a Short Rest" (Hit Point Dice and Special Feature), not that it finishes one (Q-16). | SRD 5.2.1, the pages of Table W; "Long Rest", p. 185 | unhappy (rule interaction) |
| FR-062 | The `RestStartCheck`, `RestResolution`, `RestBenefits`, `SpentHitDice` and `HitDieRecovery` domain code MUST be pure, synchronous, deterministic and silent (no logging, metrics or spans). | architecture.md section 3 (purity); observability.md section 3 | unhappy (architecture) |
| FR-063 | The sleep and light-activity requirements of a Long Rest (at least 6 hours asleep and no more than 2 hours of light activity) and the Short Rest activity limit are host preconditions: the package sees neither. A host MUST NOT report a period that fails them as a Long Rest. Strenuous activity during a Short Rest is reported as `physicalExertion` (FR-019) and a Long Rest broken by 1 hour of walking or other exertion as `physicalExertion` (FR-022). `RestReport` and `TakeRestCommand` document this in their doc comments, and the `TakeRestCommand` comment also documents FR-070 (start values) and FR-072 (what counts as a finished Long Rest). | SRD 5.2.1, "Long Rest", p. 185; "Short Rest", p. 187 | unhappy (host precondition) |
| FR-064 | `RestBenefits.of(RestKind.shortRest, exhaustionLevel, spentHitDice)` MUST be callable without a `RestReport` and MUST return exactly the effects of FR-024 and the unchanged `SpentHitDice`, so a host can grant "the benefits of a Short Rest" to a creature that did not rest (the Prayer of Healing spell, SRD 5.2.1, p. 154). Calling it raises no `RestApplied` event, because nothing finished; `RestApplied` is raised by `TakeRest` only. | SRD 5.2.1, "Prayer of Healing", p. 154; "Short Rest", p. 187 | happy |
| FR-065 | `RestKind.recharges(RechargeTrigger)` MUST be the one mapping from a rest to the `content`-owned `RechargeTrigger` (`content-schema-and-decoder.md` FR-112: `shortRest`, `longRest`, `shortOrLongRest`) and MUST return true exactly as table 4.8f shows. This spec defines no wording enum of its own and no string getter of SRD wording MAY exist; "Per Day" is data with trigger `longRest` (FR-032). The class and species specs apply the mapping through this predicate (`shared-types-and-ownership.md` FR-009). | SRD 5.2.1, "Short Rest", "Special Feature", p. 187; "Long Rest", "Special Feature", p. 185; "Per Day", p. 186 | unhappy (boundary: the Long Rest does not recharge a `shortRest` trigger) |
| FR-066 | Input from a host (`int` values) MUST have a non-throwing factory: `RestReport.tryCreate` returns sealed `RestReportCreation` (`CreatedRestReport`, `RejectedRestReportInput(problems)`) and `TakeRestCommand.tryCreate` returns `TakeRestCommandCreation` (`CreatedTakeRestCommand`, `RejectedTakeRestCommandInput(problems)`). Each lists every problem, once each, from the `RestReportProblem` enum (`negativeHoursRested`, `negativeHoursRestedBefore`, `negativeInterruptionsResumed`) and the `TakeRestCommandProblem` enum (`negativeCurrentHitPoints`, `exhaustionLevelOutOfRange`). `SpentHitDice.tryCreate` and `SpendHitPointDieCommand.tryCreate` are in FR-073. The creation layer rejects only malformed values; rule results come from the domain: a resumed Short Rest is `RestReportRejected(ShortRestCannotBeResumed)` from `resolve` (FR-017), and a Short Rest stopped by exertion is not rejected at all (FR-019). The plain constructors keep throwing `ArgumentError` (FR-013, FR-023). | architecture.md section 5 (list every problem), section 6; errors-and-results.md (operation-prefixed variants) | unhappy (invalid input) |
| FR-067 | `hoursRested` and `hoursRestedBefore` MUST be total rested time across all segments of one rest, excluding the interruptions themselves, as whole hours the host has floored. A Long Rest stopped after 3 hours, resumed and stopped again after 2 more hours is reported as `hoursRestedBefore` 5. FR-014, FR-015, FR-016, FR-020 and FR-021 MUST all compare this total. | SRD 5.2.1, "Long Rest" ("rested at least 1 hour before the interruption"; "1 additional hour per interruption"), p. 185; package design for the cumulative reading (Q-17) | unhappy (boundary: stop, resume, stop again) |
| FR-068 | `RestApplied`, `RestInterrupted` and `HitPointDieSpent` MUST be the variants of the sealed family `RestEvent`, which implements `CharacterEvent` (`character-aggregate.md` FR-085, an `abstract interface class` implementing `DomainEvent` and declaring `characterId`) and carries the `CharacterId` on the sealed supertype. A host switches exhaustively over `RestEvent` for the rest family and over `CharacterEvent` for the context (`shared-types-and-ownership.md` FR-019). Events are past tense. `TakeRestCommand` and `SpendHitPointDieCommand` carry the `CharacterId`. | `character-aggregate.md` FR-085; `shared-types-and-ownership.md` FR-019; architecture.md section 4 (handoffs) | happy |
| FR-069 | `SpentHitDice.trySpendOutsideRest(pool, die)` MUST spend one die exactly as `trySpend` (FR-039, FR-040, FR-038) but without a `RestKind` and without the `notAShortRestBenefit` check, returning `HitDieSpendAllowed` or `HitDieSpendRejected` with `noneRemaining`, `notInPool` or `spentExceedsPool`. It exists for the one SRD spend that is not a rest benefit, the Warlock's Lifedrinker ("you can expend one of your Hit Point Dice to roll it", p. 73), so that the die is recorded in the same `SpentHitDice` and cannot be spent again at the next Short Rest (table 4.8d SP-13 to SP-15). This spec defines no Lifedrinker use case or roll; those are `class-warlock.md` FR-078, whose `UseLifedrinker` takes and returns the `SpentHitDice` and calls `trySpendOutsideRest` (Q-22). | SRD 5.2.1, "Lifedrinker", p. 73; "Hit Point Dice", p. 22 | unhappy (rule interaction) |
| FR-070 | The values on `TakeRestCommand` that decide whether a rest may start (`currentHitPoints`, `LongRestSpacing`) MUST be the values at the start of the rest, not at the time it is reported; `exhaustionLevel` MUST be the level at the start of the rest and is also the level FR-029 lowers, which is the same by contract (nothing in the rest changes the level). A Long Rest stopped by `takingDamage` that leaves the creature at 0 Hit Points when reported is therefore reported with the Hit Points it started with, and is not `TakeRestNotStarted`. The `RestReport` and `TakeRestCommand` doc comments state this (FR-063). | SRD 5.2.1, "Long Rest" and "Short Rest" ("To start a rest, you must have at least 1 Hit Point"), pp. 185, 187; package design for the contract | unhappy (rule interaction: stopped by damage, reported at 0 Hit Points; table 4.8a LI-10) |
| FR-071 | A Long Rest reported as `RestStopped(interruption, hoursRestedBefore, interruptionsResumed)` with `hoursRestedBefore` at or above the required hours (the base 8, or 4 for `trance`, plus `interruptionsResumed`, as FR-016) MUST resolve to `RestCompleted(longRest)`: the required time had already passed, so the rest is finished, and the late interruption does not take the Long Rest benefits away. Below the required hours FR-020 and FR-021 apply. A Short Rest is unchanged (FR-018, FR-019): no benefits however many hours. This is an inference (Q-21). | SRD 5.2.1, "Long Rest" ("at least 8 hours"; "If you rested at least 1 hour before the interruption"), p. 185 | unhappy (boundary: 7, 8, 9 hours; resumed n plus 8) |
| FR-072 | Only a `RestCompleted(longRest)` (FR-014, FR-071) MUST count as a finished Long Rest for `LongRestSpacing`: a Long Rest that was interrupted and earned Short Rest benefits (`RestStoppedWithShortRestBenefits`), stopped without benefits or incomplete does not start the 16-hour clock, and neither does a Short Rest (table 4.8g). The host updates `LongRestSpacing` only after a `TakeRestApplied` whose `RestApplied` has `benefitsOf` `longRest` and `source` `finished`. The `LongRestSpacing` and `TakeRestCommand` doc comments state this. | SRD 5.2.1, "Long Rest" ("after you finish a Long Rest"), p. 185 | unhappy (rule interaction) |
| FR-073 | Host-stored spent counts MUST have non-throwing factories. `SpentHitDice.tryCreate(Map<HitPointDie, int>)` returns sealed `SpentHitDiceCreation` (`CreatedSpentHitDice`, `RejectedSpentHitDiceInput(problems)`) with every problem once each from `SpentHitDiceProblem` (`countBelowOne`). `SpendHitPointDieCommand.tryCreate` takes the host's spent counts as `Map<HitPointDie, int>` and returns sealed `SpendHitPointDieCommandCreation` (`CreatedSpendHitPointDieCommand`, `RejectedSpendHitPointDieCommandInput(problems)`) with `SpendHitPointDieCommandProblem` (`spentCountBelowOne`, `spentExceedsPool`). A spent count above the pool's count is a returned rejection (`spentExceedsPool`, FR-038), never a thrown error, and the use case maps it to `SpendHitPointDieRejected(spentExceedsPool)` with its own `srd5e.character.rejection` value `spent_exceeds_pool`. The plain constructors keep throwing `ArgumentError` for a count below 1. | architecture.md section 5, section 6 (non-throwing factories for untrusted values) | unhappy (invalid input; table 4.8d SP-9, SP-11, SP-12) |

### 4.8 Case tables

**Table 4.8a. Interruptions by rest (FR-005, FR-006, FR-018, FR-019, FR-022, FR-067, FR-070, FR-071).** One test per row. `interruptionsResumed` is 0 unless a row says otherwise; hours are totals; a Long Rest is `standard` unless a row says `trance`.

| Case | Rest | Interruption | Hours rested before | Expected | Source | Path |
|---|---|---|---|---|---|---|
| SI-1 to SI-3 | Short | `rollingInitiative`, `castingSpellOtherThanCantrip`, `takingDamage` (one test each) | 0 | `RestStoppedWithoutBenefits` | p. 187 | unhappy (state error) |
| SI-4 | Short | `physicalExertion` | 0 | `RestStoppedWithoutBenefits` (inference, Q-10) | p. 187 | unhappy (state error) |
| SI-5 | Short | `physicalExertion` | 1 | `RestStoppedWithoutBenefits` | p. 187 | unhappy (boundary) |
| LI-1 to LI-4 | Long | `rollingInitiative`, `castingSpellOtherThanCantrip`, `takingDamage`, `physicalExertion` (one test each) | 3 | `RestStoppedWithShortRestBenefits` | p. 185 | happy |
| LI-5, LI-6 | Long | `takingDamage` | 1; 0 | `RestStoppedWithShortRestBenefits`; `RestStoppedWithoutBenefits` | p. 185 | unhappy (boundary) |
| LI-7 | Long | `rollingInitiative` | 7 | `RestStoppedWithShortRestBenefits` (not a Long Rest) | p. 185 | unhappy (boundary: one hour short) |
| LI-8 | Long | `takingDamage`, after a stop at 3 hours, a resume and 2 more hours (`interruptionsResumed` 1) | 5 (total, FR-067) | `RestStoppedWithShortRestBenefits` | p. 185 | unhappy (boundary: stop, resume, stop again) |
| LI-9 | Long | `rollingInitiative`, after a stop at 0 hours and a resume (`interruptionsResumed` 1) | 0 | `RestStoppedWithoutBenefits` | p. 185 | unhappy (boundary: no hours in any segment) |
| LI-10 | Long | `takingDamage`, command reports current Hit Points 12 as at the start of the rest although the creature is at 0 when the rest is reported (FR-070) | 3 | `TakeRestAppliedAfterInterruption` (Short Rest benefits); not `TakeRestNotStarted` | p. 185 | unhappy (rule interaction: stopped by damage, reported at 0 Hit Points) |
| LI-11, LI-12 | Long | `rollingInitiative` | 8; 9 | `RestCompleted(longRest)` (inference, Q-21) | p. 185 | unhappy (boundary: required hours reached) |
| LI-13 | Long, `trance` | `takingDamage` | 4 | `RestCompleted(longRest)` (inference, Q-21) | p. 185, p. 85 | unhappy (boundary) |
| LI-14 | Long | `takingDamage`, `interruptionsResumed` 1 | 8 | `RestStoppedWithShortRestBenefits` (required hours are 9) | p. 185 | unhappy (boundary: resumed n plus 8, one short) |
| LI-15 | Long | `takingDamage`, `interruptionsResumed` 1 | 9 | `RestCompleted(longRest)` (inference, Q-21) | p. 185 | unhappy (boundary: resumed n plus 8) |

**Table 4.8b. Required hours and completion (FR-002 to FR-004, FR-014 to FR-017).** One test per row.

| Case | Rest | Variant | Resumed interruptions | Hours rested | Expected | Source | Path |
|---|---|---|---|---|---|---|---|
| RH-1 | Short | n/a | 0 | 1 | `RestCompleted(shortRest)` | p. 187 | happy |
| RH-2 | Short | n/a | 0 | 0 | `RestIncomplete(1)` | p. 187 | unhappy (boundary) |
| RH-3 | Long | `standard` | 0 | 8 | `RestCompleted(longRest)` | p. 185 | happy |
| RH-4 | Long | `standard` | 0 | 7 | `RestIncomplete(1)` | p. 185 | unhappy (boundary) |
| RH-5 | Long | `standard` | 1 | 9 | `RestCompleted(longRest)` | p. 185 | happy |
| RH-6 | Long | `standard` | 1 | 8 | `RestIncomplete(1)` | p. 185 | unhappy (boundary) |
| RH-7 | Long | `standard` | 3 | 11 | `RestCompleted(longRest)` | p. 185 | unhappy (rule interaction) |
| RH-8 | Long | `trance` | 0 | 4 | `RestCompleted(longRest)` | p. 85 | happy |
| RH-9 | Long | `trance` | 0 | 3 | `RestIncomplete(1)` | p. 85 | unhappy (boundary) |
| RH-10 | Long | `trance` | 1 | 5 | `RestCompleted(longRest)` | p. 185, p. 85 (derived, Q-12) | unhappy (rule interaction) |
| RH-11 | Short | `trance` | 0 | 1 | `RestCompleted(shortRest)` | p. 85 | unhappy (rule interaction) |
| RH-12 | Short | n/a | 1 | 1 | rejected `ShortRestCannotBeResumed` | p. 187 | unhappy (state error) |
| RH-13 | Long | `standard` | 2 | 10 (total of segments 4, 3 and 3, FR-067) | `RestCompleted(longRest)` | p. 185 | unhappy (boundary: stop, resume, stop again, resume) |
| RH-14 | Long | `standard` | 2 | 9 (total) | `RestIncomplete(1)` | p. 185 | unhappy (boundary) |

**Table 4.8c. Hit Points regained by one Hit Point Die (FR-043, FR-044, FR-056).** One test per row.

| Case | Die | Roll | Constitution modifier | Expected Hit Points regained | Source | Path |
|---|---|---|---|---|---|---|
| HD-1 | d8 | 4 | +2 | 6 | p. 187 | happy |
| HD-2 | d8 | 4 | 0 | 4 | p. 187 | happy |
| HD-3 | d8 | 4 | -3 | 1 (total 1, no raise needed) | p. 187 | unhappy (boundary) |
| HD-4 | d8 | 1 | -3 | 1 (total -2, raised to 1) | p. 187 | unhappy (boundary) |
| HD-5 | d8 | 5 | -3 | 2 | p. 187 | unhappy (boundary) |
| HD-6 | d10 | 1 | -5 | 1 (total -4, raised to 1) | p. 187 | unhappy (boundary) |
| HD-7 | d12 | 12 | +5 | 17 | p. 187 | unhappy (boundary: maximum roll) |
| HD-8 | d6 | 1 | 0 | 1 | p. 187 | unhappy (boundary: minimum roll) |
| HD-9, HD-10 | d8 | 0; 9 | +2 | `ArgumentError` (roll) | dice-and-rolls.md | unhappy (invalid input) |

**Table 4.8d. Pool and spending (FR-037 to FR-042, FR-045, FR-069, FR-073).** One test per row. "Spend" is `trySpend(pool, die, shortRest)` unless a row says otherwise.

| Case | Pool | Spent before | Action | Expected | Source | Path |
|---|---|---|---|---|---|---|
| SP-1 | d10 x 1 (level 1 Fighter) | none | spend d10 | allowed, d10 spent 1 | p. 22 | happy |
| SP-2 | d10 x 1 | d10 x 1 | spend d10 | rejected `noneRemaining` | p. 22 | unhappy (boundary) |
| SP-3 | d8 x 5, d10 x 5 (level 5 Cleric and level 5 Paladin) | none | spend d10 | allowed, d10 spent 1, d8 spent 0 | p. 25 | happy |
| SP-4 | d8 x 5, d10 x 5 | d10 x 5 | spend d10 | rejected `noneRemaining`; spend d8 allowed | p. 25 | unhappy (boundary, rule interaction) |
| SP-5 | d8 x 5, d10 x 5 | none | spend d12 | rejected `notInPool` | p. 25 | unhappy (invalid input) |
| SP-6 | d10 x 10 (level 5 Fighter and level 5 Paladin) | none | spend d10 ten times | ten allowed, the eleventh rejected | p. 25 | unhappy (boundary) |
| SP-7 | d10 x 1 | d10 x 1 | level up: pool d10 x 2 | one die left to spend | p. 23 | unhappy (boundary) |
| SP-8 | d10 x 1 | none | `trySpend(pool, d10, longRest)` (claiming Long Rest benefits) | rejected `notAShortRestBenefit`; no roll in the use case | p. 187 | unhappy (state error) |
| SP-9 | d8 x 2 | d8 x 3 | any spend | rejected `spentExceedsPool` (host-stored state disagrees with the pool); nothing thrown | p. 22 | unhappy (invalid input) |
| SP-10 | d8 x 2 | d8 x 0 given as an entry | construct `SpentHitDice` | `ArgumentError` (count below 1) | p. 22 | unhappy (invalid input) |
| SP-11 | n/a | d8 x 0 given as an entry | `SpentHitDice.tryCreate` | `RejectedSpentHitDiceInput([countBelowOne])` | p. 22 | unhappy (invalid input) |
| SP-12 | d8 x 2 | d8 x 3 as host ints | `SpendHitPointDieCommand.tryCreate` | `RejectedSpendHitPointDieCommandInput([spentExceedsPool])`; `SpendHitPointDie` on a command built another way returns `SpendHitPointDieRejected(spentExceedsPool)` | p. 22 | unhappy (invalid input) |
| SP-13 | d8 x 2 | none | `trySpendOutsideRest(pool, d8)` (Lifedrinker) | allowed, d8 spent 1; no `notAShortRestBenefit` check | p. 73 | happy |
| SP-14 | d8 x 2 | d8 x 1 (from Lifedrinker) | `trySpend(pool, d8, shortRest)` then `trySpend(pool, d8, shortRest)` | first allowed (d8 spent 2), second `noneRemaining`: the Lifedrinker die is not spendable again at the Short Rest | p. 73, p. 187 | unhappy (rule interaction) |
| SP-15 | d8 x 2 | d8 x 2 | `trySpendOutsideRest(pool, d8)` | rejected `noneRemaining` | p. 73 | unhappy (boundary) |

**Table 4.8e. Benefits of a Long Rest by state (FR-025 to FR-034).** One test per row. Effect order is FR-034.

| Case | Exhaustion level | Spent dice | Expected effects | Source | Path |
|---|---|---|---|---|---|
| LB-1 | 0 | none | all lost Hit Points regained, Hit Point maximum returned, ability scores returned, Temporary Hit Points ended, features recharged (long rest) | p. 185, p. 18 | happy |
| LB-2 | 0 | d8 x 3 | as LB-1 plus `HitPointDiceRegained(3)` after the first effect | p. 185 | happy |
| LB-3 | 1 | none | as LB-1 plus `ExhaustionLevelReduced(1 to 0)` | p. 185, p. 181 | unhappy (boundary) |
| LB-4 | 2 | d8 x 1, d10 x 2 | as LB-1 plus `HitPointDiceRegained(3)` and `ExhaustionLevelReduced(2 to 1)` | p. 185 | unhappy (rule interaction) |
| LB-5 | 5 | none | `ExhaustionLevelReduced(5 to 4)` | p. 185 | unhappy (boundary) |
| LB-6 | 6 | none | not startable (`RestStartExhaustionLevelSix`), no effects | p. 181 | unhappy (state error) |
| SB-1 | 3 | d8 x 2 | Short Rest: `SpendHitPointDiceAvailable`, features recharged (short rest) only; Exhaustion and spent dice unchanged | p. 187 | unhappy (rule interaction) |
| SB-2 | 0 | none | interrupted Long Rest with 1 hour rested: same as SB-1 | p. 185 | unhappy (boundary) |

**Table 4.8f. `RestKind.recharges(trigger)` over `RechargeTrigger` (FR-032, FR-065).** One test per cell, 6 in all.

| Case | Trigger | `shortRest` recharges | `longRest` recharges | Source | Path |
|---|---|---|---|---|---|
| RW-1 | `RechargeTrigger.shortRest` | true | false | p. 187 | unhappy (rule interaction: a Long Rest is not also a Short Rest) |
| RW-2 | `RechargeTrigger.longRest` | false | true | p. 185 | happy |
| RW-3 | `RechargeTrigger.shortOrLongRest` | true | true | pp. 185, 187 | happy |

**Table 4.8g. What starts the 16-hour clock (FR-009, FR-072).** One test per row.

| Case | Rest result | Counts as a finished Long Rest for `LongRestSpacing` | Source | Path |
|---|---|---|---|---|
| SC-1 | `RestCompleted(longRest)` | yes | p. 185 | happy |
| SC-2 | `RestStoppedWithShortRestBenefits` (interrupted Long Rest) | no | p. 185 | unhappy (rule interaction) |
| SC-3 | `RestStoppedWithoutBenefits` of a Long Rest | no | p. 185 | unhappy (state error) |
| SC-4 | `RestIncomplete` of a Long Rest | no | p. 185 | unhappy (state error) |
| SC-5 | `RestCompleted(shortRest)` | no | p. 187 | unhappy (rule interaction) |
| SC-6 | `RestCompleted(longRest)` reached through FR-071 (stopped after the required hours) | yes | p. 185 | unhappy (boundary) |

**Table R. What recharges, ends or is capped on which rest (FR-032, FR-060).**
One scenario test per row, through the owner's public API; "amount" is the
owner's rule, this spec supplies only the `RestKind`. The table lists the
class, species and feat features of SRD 5.2.1 pp. 28 to 88 whose text ties a
use, recharge, created resource or summoned creature to a rest, plus the
subclass and Invocation features the class specs model (R-17, R-27, R-34, R-39,
R-43). It is a cross-check: FR-060 is the requirement, and a feature missing
from the table is still bound by it. The "finish a Short Rest" windows are in
Table W; Table R keeps only the recharge halves.

| Row | Feature (SRD name) | `shortRest` | `longRest` | Source | Owner spec |
|---|---|---|---|---|---|
| R-1 | Rage uses | regain 1 expended use | regain all | "Level 1: Rage", p. 28 | class-barbarian.md FR-025, FR-026 |
| R-2 | Relentless Rage DC | resets to 10 | resets to 10 | "Level 11: Relentless Rage", p. 30 | class-barbarian.md |
| R-3 | Persistent Rage (regain Rage on Initiative) | no change | available again | "Level 15: Persistent Rage", p. 30 | class-barbarian.md FR-071 |
| R-4 | Bardic Inspiration, Bard level 1 to 4 | no change | regain all | "Bardic Inspiration", p. 32 | class-bard.md FR-038, FR-040 |
| R-5 | Bardic Inspiration, Bard level 5+ | regain all | regain all | "Level 5: Font of Inspiration", p. 32 | class-bard.md FR-039 |
| R-6 | Spell slots (Spellcasting) | no change | regain all expended | "Spellcasting" of Bard p. 32, Cleric p. 37, Druid p. 42, Paladin p. 54, Ranger p. 57, Sorcerer p. 65, Wizard p. 78 | spellcasting.md FR-025, FR-026 |
| R-7 | Pact Magic slots | regain all | regain all | "Level 1: Pact Magic", p. 71 | spellcasting.md FR-025, FR-026; class-warlock.md FR-028 |
| R-8 | Channel Divinity uses (Cleric, Paladin) | regain 1 | regain all | "Level 2: Channel Divinity", p. 37; "Level 3: Channel Divinity", p. 54 | class-cleric.md FR-042, FR-043; class-paladin.md FR-067 |
| R-9 | Divine Intervention | no change | available again | "Level 10: Divine Intervention", p. 38 | class-cleric.md |
| R-10 | Wild Shape uses | regain 1 | regain all | "Level 2: Wild Shape", p. 42 | class-druid.md FR-068, FR-069 |
| R-11 | Natural Recovery free cast of a Circle spell (once until a Long Rest) | no change (the slot recovery is window W-11) | available again | "Level 6: Natural Recovery", p. 46 | class-druid.md FR-125, FR-156 |
| R-12 | Second Wind uses | regain 1 | regain all | "Level 1: Second Wind", p. 48 | class-fighter.md FR-063 |
| R-13 | Action Surge uses | regain all | regain all | "Level 2: Action Surge", p. 48 | class-fighter.md FR-074 |
| R-14 | Indomitable uses | no change | regain all | "Level 9: Indomitable", p. 48 | class-fighter.md FR-083 |
| R-15 | Focus Points | regain all expended | regain all expended | "Level 2: Monk's Focus", p. 50 | class-monk.md FR-036, FR-124 |
| R-16 | Uncanny Metabolism | no change | available again | "Level 2: Uncanny Metabolism", p. 51 | class-monk.md FR-124 |
| R-17 | Wholeness of Body uses | no change | regain all | "Level 6: Wholeness of Body", p. 52 | class-monk.md FR-111 |
| R-18 | Lay On Hands pool | no change | replenished | "Level 1: Lay On Hands", p. 53 | class-paladin.md |
| R-19 | Paladin's Smite free cast | no change | available again | "Level 2: Paladin's Smite", p. 54 | class-paladin.md FR-064 |
| R-20 | Favored Enemy free casts | no change | regain all | "Level 1: Favored Enemy", p. 58 | class-ranger.md FR-036 |
| R-21, R-22 | Tireless uses; Nature's Veil uses | no change | regain all | "Level 10: Tireless", p. 59; "Level 14: Nature's Veil", p. 59 | class-ranger.md FR-075, FR-080 |
| R-23 | Tireless, Decrease Exhaustion | no recharge (the Short Rest reduction is window W-12) | lowers by 1 (the Long Rest rule, FR-029 here) | "Level 10: Tireless", p. 59 | class-ranger.md FR-076 (Short Rest); FR-029 here (Long Rest) |
| R-24 | Stroke of Luck | available again | available again | "Level 20: Stroke of Luck", p. 63 | class-rogue.md FR-088 |
| R-25 | Sorcery Points | no change (Sorcerous Restoration is window W-13; its once-until-a-Long-Rest limit is reset by the Long Rest) | regain all | "Level 2: Font of Magic", "Level 5: Sorcerous Restoration", p. 66 | class-sorcerer.md FR-083, FR-107 |
| R-26 | Innate Sorcery uses | no change | regain all | "Level 1: Innate Sorcery", p. 66 | class-sorcerer.md |
| R-27 | Magical Cunning, Contact Patron, Mystic Arcanum, Gift of the Depths, Dark One's Own Luck, Hurl Through Hell | no change | available again | pp. 72, 73, 76 | class-warlock.md FR-139, FR-140 |
| R-28 | Arcane Recovery (once until a Long Rest) | no change (the recovery is window W-14) | available again | "Level 1: Arcane Recovery", p. 78 | class-wizard.md FR-050 |
| R-29 | Signature Spells free casts | available again | available again | "Level 20: Signature Spells", p. 79 | class-wizard.md FR-074 |
| R-30 | Overchannel use count | no change | resets | "Level 14: Overchannel", p. 82 | class-wizard.md FR-090 |
| R-31 | Species uses equal to Proficiency Bonus: Breath Weapon, Stonecunning, Giant Ancestry; Draconic Flight; Large Form; Relentless Endurance | no change | regain all | "Dragonborn", "Dwarf", p. 84; "Goliath", p. 85, 86; "Orc", p. 86 | species-trait-behaviour.md FR-030 to FR-033 (use state, limits and renewal; content-thin-slice.md FR-013, FR-018, FR-020 hold the data) |
| R-32 | Orc Adrenaline Rush uses | regain all | regain all | "Orc", p. 86 | species-trait-behaviour.md FR-030 to FR-033 |
| R-33 | Epic Boon "Boon of Fate", Improve Fate | available again | available again | "Boon of Fate", p. 88 | feats-behaviour.md FR-050 (`FeatRenewal`: `shortRestFinished`, `longRestFinished`) |
| R-34 | Intimidating Presence (Path of the Berserker) | no change | available again (or restored by expending a use of Rage) | "Level 14: Intimidating Presence", p. 30 | class-barbarian.md FR-082 |
| R-35 | Wild Companion familiar | no change | the familiar disappears (`WildCompanionDismissed`) | "Level 2: Wild Companion", p. 43 | class-druid.md FR-090; summoned-and-companion-creatures.md FR-053 (`ReportLongRestFinished` departs it, cause `longRestFinished`) |
| R-36, R-37 | Wild Resurgence (Wild Shape use for a level 1 slot); Nature Magician (Wild Shape uses for a slot) | no change | available again | "Level 5: Wild Resurgence", p. 43; "Level 20: Archdruid", p. 43 | class-druid.md FR-102, FR-113 |
| R-38, R-39 | Faithful Steed free cast of Find Steed; Holy Nimbus (Oath of Devotion) | no change | available again | "Level 5: Faithful Steed", p. 55; "Level 20: Holy Nimbus", p. 57 | class-paladin.md FR-062, FR-091 |
| R-40 | Spell slots created with Creating Spell Slots | no change | the created slots vanish | "Level 2: Font of Magic", Creating Spell Slots, p. 66 | class-sorcerer.md FR-054 |
| R-41, R-42 | Dragon Wings (Draconic Sorcery); Dragon Companion free cast of Summon Dragon | no change | available again | "Level 14: Dragon Wings", p. 70; "Level 18: Dragon Companion", p. 70 | class-sorcerer.md FR-093, FR-095 |
| R-43 | Gift of the Protectors (Eldritch Invocation) | no change | available again (no creature benefits until then) | "Gift of the Protectors", p. 73 | class-warlock.md FR-103 |
| R-44 | Elven Lineage spells (levels 3 and 5) free casts | no change | regain the free cast | "Elf", Elven Lineage, p. 84 | species-trait-behaviour.md FR-021, FR-033 (content-thin-slice.md FR-024 holds the data) |
| R-45 | Forest Gnome Speak with Animals uses (Proficiency Bonus) | no change | regain all | "Gnome", Gnomish Lineage, p. 85 | species-trait-behaviour.md FR-030 to FR-033 (content-species-backgrounds-feats.md FR-020 holds the data) |
| R-46 | Fiendish Legacy spells (levels 3 and 5) free casts | no change | regain the free cast | "Tiefling", Fiendish Legacy, p. 86 | species-trait-behaviour.md FR-021, FR-033 (content-species-backgrounds-feats.md FR-019 holds the data) |
| R-47 | Magic Initiate level 1 spell free cast | no change | regain the free cast | "Magic Initiate", p. 87 | feats-behaviour.md FR-032 |

**Table W. Windows opened by finishing a rest (FR-061).** These are not
recharges: "whenever you finish a ... Rest, you can ...". An interrupted Long Rest
(`source` `longRestInterrupted`) opens none of them.

| Row | Window | Rest | Source | Owner spec |
|---|---|---|---|---|
| W-1 | Change prepared spells (Cleric, Druid, Wizard: any; Paladin, Ranger: replace one) | Long | pp. 37, 42, 54, 58, 78 | spellcasting.md FR-048, FR-049 |
| W-2 | Replace one Wizard cantrip; Spell Mastery swap | Long | "Spellcasting", p. 77; "Level 18: Spell Mastery", p. 79 | spellcasting.md FR-053; class-wizard.md FR-069 |
| W-3 | Memorize Spell | Short | "Level 5: Memorize Spell", p. 79 | spellcasting.md FR-091; class-wizard.md FR-061 |
| W-4 | Weapon Mastery swap (Barbarian, Fighter, Paladin, Ranger, Rogue) | Long | pp. 29, 48, 54, 59, 62 | weapon-properties-and-mastery.md FR-024; class-fighter.md FR-046, FR-047 |
| W-5 | Fiendish Resilience damage type | Short or Long | "Level 10: Fiendish Resilience", p. 76 | class-warlock.md FR-131, FR-133 |
| W-6 | Book of Shadows | Short or Long | "Pact of the Tome", p. 74 | class-warlock.md FR-097 |
| W-7 | Hunter's Prey, Defensive Tactics option | Short or Long | p. 61 | class-ranger.md |
| W-8 | Known form replacement; land type choice | Long | "Wild Shape", p. 42; "Circle of the Land Spells", p. 46 | class-druid.md FR-153, FR-156 |
| W-9 | High Elf cantrip replacement | Long | "Elf", p. 85 | species-trait-behaviour.md FR-025, FR-033 |
| W-10 | Resourceful: gain Heroic Inspiration | Long | "Human", p. 86 | species-trait-behaviour.md FR-045, FR-033; heroic-inspiration.md (`shared-types-and-ownership.md` FR-048); character-aggregate.md FR-089 (the `HeroicInspiration` state) |
| W-11 | Natural Recovery: recover spell slots (once until a Long Rest) | Short | "Level 6: Natural Recovery", p. 46 | class-druid.md FR-127, FR-153 |
| W-12 | Tireless: Decrease Exhaustion (reduce Exhaustion by 1) | Short | "Level 10: Tireless", p. 59 | class-ranger.md FR-076 |
| W-13 | Sorcerous Restoration: regain Sorcery Points (once until a Long Rest) | Short | "Level 5: Sorcerous Restoration", p. 66 | class-sorcerer.md FR-083, FR-107 |
| W-14 | Arcane Recovery: recover spell slots (once until a Long Rest) | Short | "Level 1: Arcane Recovery", p. 78 | class-wizard.md FR-050 |

### 4.9 Withdrawn ids

None. (`perDay` and `RestRechargeWording` were removed: "Per Day" is data with trigger `longRest`, FR-032.)

## 5. Model

### 5.1 Types

| Part | Kind | Holds |
|---|---|---|
| `RestKind` | enum | `shortRest`, `longRest`. Methods `minimumHours(LongRestVariant)` (FR-002 to FR-004) and `recharges(RechargeTrigger)` (FR-032, FR-065). |
| `LongRestVariant`, `RestInterruption`, `RestSource` | enums | `standard`, `trance`; the four values of FR-005 with `stops(RestKind)` (FR-006); `finished`, `longRestInterrupted` (FR-036, FR-061). |
| `LongRestSpacing` | sealed | `NoLongRestFinishedYet`, `LongRestFinishedHoursAgo(hours >= 0)`; start-of-rest value (FR-070, FR-072). |
| `RestStartCheck` | domain service | `check(kind, currentHitPoints, exhaustionLevel, spacing)` returns sealed `RestStartDecision`: `RestMayStart` or `RestMayNotStart(blockers)`, each a sealed `RestStartBlocker`: `RestStartNoHitPoints`, `RestStartExhaustionLevelSix`, `RestStartTooSoonAfterLongRest(hoursStillToWait)` (FR-007 to FR-012). |
| `RestEnd` | sealed | `RestRanItsCourse(hoursRested, interruptionsResumed)`, `RestStopped(interruption, hoursRestedBefore, interruptionsResumed)`; hours are totals (FR-067). |
| `RestReport` | value object | kind, `LongRestVariant`, `RestEnd`. `tryCreate` returns sealed `RestReportCreation` (`CreatedRestReport`, `RejectedRestReportInput(problems)` of `RestReportProblem`), FR-066. |
| `RestResolution` | sealed | `RestCompleted(kind)`, `RestIncomplete(hoursStillNeeded)`, `RestStoppedWithShortRestBenefits(interruption)`, `RestStoppedWithoutBenefits(interruption)`, `RestReportRejected(problem: RestReportRejection)`. `RestResolution.resolve(report)` is the domain service. |
| `RestReportRejection`, `RestBenefitsGranted` | sealed | `ShortRestCannotBeResumed` (FR-017); `RestBenefitsOfShortRest`, `RestBenefitsNone` (FR-036). |
| `RestReportProblem`, `TakeRestCommandProblem`, `SpentHitDiceProblem`, `SpendHitPointDieCommandProblem` | enums | `negativeHoursRested`, `negativeHoursRestedBefore`, `negativeInterruptionsResumed` (FR-066); `negativeCurrentHitPoints`, `exhaustionLevelOutOfRange` (FR-066); `countBelowOne` (FR-073); `spentCountBelowOne`, `spentExceedsPool` (FR-073). |
| `RestBenefits` | domain service | `of(benefitsOf, exhaustionLevel, spentHitDice)` returns the ordered effect list and the new `SpentHitDice` (FR-024 to FR-035, FR-064). It takes no pool: a Long Rest clears every spent die. |
| `RestEffect` | sealed | `SpendHitPointDiceAvailable`, `AllLostHitPointsRegained`, `HitPointDiceRegained(count)`, `HitPointMaximumReturnedToNormal`, `AbilityScoresReturnedToNormal`, `ExhaustionLevelReduced(from, to)`, `TemporaryHitPointsEndedByRest`, `FeaturesRecharged(RestKind)`. |
| `SpentHitDice` | value object, implements `FeatureState` (`character-aggregate.md` FR-092) | counts by `HitPointDie` (FR-037, FR-038); `none`; `tryCreate(Map<HitPointDie, int>)` returns sealed `SpentHitDiceCreation` (`CreatedSpentHitDice`, `RejectedSpentHitDiceInput(problems)`), FR-073; `trySpend(HitDicePool, HitPointDie, RestKind benefitsOf)` and `trySpendOutsideRest(HitDicePool, HitPointDie)` (FR-069) return sealed `HitDieSpendResult`: `HitDieSpendAllowed(spent)` or `HitDieSpendRejected(reason)`. |
| `HitDieSpendRejection` | enum | The `reason` of `HitDieSpendRejected` and `SpendHitPointDieRejected`: `noneRemaining`, `notInPool`, `notAShortRestBenefit` (`trySpend` only), `spentExceedsPool`. |
| `spentHitDiceKey` | `FeatureStateKey<SpentHitDice>` | Name `spent_hit_dice` (`character-aggregate.md` FR-093), defined here as `shared-types-and-ownership.md` FR-022 asks; the functions here take `SpentHitDice` as an argument and never read the store. |
| `HitDieRecovery` | domain service | `hitPointsRegained(die, roll, constitutionModifier)` (FR-043, FR-044). |
| `RestEvent` | sealed event family | implements `CharacterEvent` (`character-aggregate.md` FR-085); `characterId` on the supertype (FR-068). Variants: `RestApplied(characterId, benefitsOf, source, effects)`, `RestInterrupted(characterId, kind, interruption, benefitsGranted)`, `HitPointDieSpent(characterId, die: HitPointDie, roll, constitutionModifier, hitPointsRegained)`. Past tense, immutable. |

### 5.2 Invariants and results

Plain constructors and domain functions throw `ArgumentError` for a programmer
error: a `SpentHitDice` count below 1, a negative hours, interruption count or
current Hit Points, an Exhaustion level outside 0 to 6, a die roll outside its
die (`HitDieRecovery`, FR-044); effect lists and `SpentHitDice` views are
unmodifiable (`UnsupportedError`, FR-048). Host input goes through the
`tryCreate` factories, which return every problem (FR-066, FR-073). A spent
count above the pool's is a returned `spentExceedsPool` from `trySpend`,
`trySpendOutsideRest` and `SpendHitPointDieCommand.tryCreate`, not from
`RestBenefits.of`, which has no pool (FR-038). Start-of-rest values on
`TakeRestCommand` are a documented contract, not checkable (FR-070). A resumed
Short Rest is a `RestResolution.resolve` result (FR-017), not a creation
failure.

### 5.3 Results and errors

Expected outcomes (not started, incomplete, stopped, rejected report,
rejected spend, rejected input) are results; the only infrastructure failure is
the `DiceRoller`'s `DiceRollerException`, which propagates.

### 5.4 Deferrals satisfied and mechanics superseded

Other specs left these to a rest spec (or wrongly to `spellcasting.md`); each
owner reconciles its own text (Q-1, Q-14; `shared-types-and-ownership.md`
FR-048). Rows naming `combat` specs are non-normative hand-offs: nothing here
depends on them (`shared-types-and-ownership.md` FR-013).

| Spec | Left to a rest spec | Satisfied by here |
|---|---|---|
| shared-types-and-ownership.md FR-009, FR-016, FR-020 | `RestKind`, rest effects and `RestApplied` owned here; `character` maps `RestKind` to triggers | FR-001, FR-032, FR-036, FR-059, FR-065 |
| spellcasting.md (FR-025, FR-026, FR-048, FR-091) | A rest "arrives as a `RestKind`" | FR-001 to FR-006, FR-014 to FR-022, FR-060; R-6, R-7, W-1 to W-3. Slot recovery is not superseded. The telemetry key `srd5e.character.rest_kind` is defined here (section 7); `spellcasting.md` reuses it |
| hit-points-and-damage.md FR-034; conditions.md FR-036, FR-043, D-15; encounter-aggregate.md | A Long Rest ends Temporary Hit Points and lowers Exhaustion by 1 | FR-030 and FR-029 (rules and triggers); the operations stay there. FR-007, FR-009, FR-058 |
| character-aggregate.md; derived-stats.md FR-028 | Spending Hit Dice and the spent state | FR-037 to FR-048; Q-6 |
| class-fighter.md (`TakeRest`, `LongRestFinished`) | A `TakeRest` applying recovery to all class states | FR-049 to FR-052, FR-036. Classes are downstream (`shared-types-and-ownership.md` FR-016): the host calls each class function with `RestApplied.benefitsOf` (Q-1); `LongRestFinished` is `RestApplied(longRest)` (FR-061) |
| class-barbarian, -bard, -cleric, -druid, -monk, -paladin, -ranger, -rogue, -sorcerer, -wizard (rest-trigger text, `RestKind.short`, a result variant `RestApplied`) | Own rest triggers, wording and `RestKind` ownership, including an interrupted Long Rest | FR-001, FR-020, FR-059 to FR-061 (Q-2); `InitiativeRolled` stays Bard-owned; R-4 to R-6; they define no rest event (`shared-types-and-ownership.md` FR-020) |
| class-warlock.md (FR-028, FR-078, FR-139, FR-140) | Rest and Hit Die rules; Lifedrinker's spent die | FR-001 to FR-048; FR-069 (taken up by FR-078, Q-22) |
| class-ranger.md FR-076 | Long Rest lowering of Tireless | FR-029, R-23, W-12 |
| content-thin-slice.md, content-species-backgrounds-feats.md, species-trait-behaviour.md | Species recharge: data in content, use state and windows in species-trait-behaviour.md | FR-004, FR-032, FR-065; R-31, R-32, R-44 to R-46; W-9, W-10 |
| revival-and-restoration-spells.md (FR-016 to FR-022) | Raise Dead penalty and Resurrection strain end at a finished Long Rest | FR-036, FR-061: `afterRest` takes `RestApplied.benefitsOf`; an interrupted Long Rest gives Short Rest benefits and reduces nothing |
| content-monsters.md FR-035 | A monster part recharges after "a Short or Long Rest" | Not a dependency; monsters are out of scope (Q-8) |
| magic-item-rules.md (`ShortRestFocus`; FR-041, FR-114; Q3) | A parallel Short Rest completion vocabulary | Keeps `ShortRestFocus` and `RestPurpose` (host facts about one item); its FR-114 builds the focus from `RestResolution`: `isCompleted` is true for `RestCompleted(shortRest)` and false for `RestStoppedWithoutBenefits` of a Short Rest (FR-018, FR-019) or `RestIncomplete`; a Long Rest, even interrupted with Short Rest benefits (FR-020), is `notAShortRest` there, agreeing with FR-061 (Q-19) |
| feats-behaviour.md (`FeatRenewal`, `RenewFeatUses`; FR-032, FR-050 to FR-052; Q9) | Renews on `shortRestFinished` and `longRestFinished`; who calls it | FR-060: `shortRestFinished` from `RestApplied.benefitsOf == shortRest` (any `RestSource`, renewal being a recharge, FR-020) and `longRestFinished` from `longRest`; the host calls `RenewFeatUses` after each `TakeRestApplied` (Q-1); R-33, R-47 |
| exploration.md (`MountedPaceBoost.restFinished(RestKind)`; FR-022 to FR-024) | Restores a mount boost after "a Short or Long Rest" | FR-001, FR-060: either `RestApplied.benefitsOf` restores it; an unfinished or refused rest is not reported |
| toolbox-curses-and-contagions.md (`ContagionSewerPlagueRestRules`; FR-082, FR-083) | A hook for a condition that changes rest benefits | None needed: its filter takes the `RestBenefits` effects and a Hit Die result; the names in FR-025, FR-026, FR-029 are stable |
| weapon-properties-and-mastery.md FR-024; magic-item-rules.md FR-041 | The Long Rest moment for a Weapon Mastery change; whether an interrupted rest counts for attunement | W-4 (FR-061); FR-018 to FR-020, FR-061 (the attunement consequence stays there) |

## 6. Interface

All use cases are classes with a single `call` method and an immutable command,
taking `Observability` as an optional constructor argument (no-op default). Both
are synchronous and neither calls another use case (`shared-types-and-ownership.md` FR-044).

| Use case | Command | Result (sealed `<UseCase>Result`, `shared-types-and-ownership.md` FR-017) | Ports |
|---|---|---|---|
| `TakeRest` | `TakeRestCommand`: `CharacterId`, `RestReport`, `currentHitPoints` (int), `exhaustionLevel` (int 0 to 6), `LongRestSpacing`, `SpentHitDice`; the three start values are as at the start of the rest (FR-070); `tryCreate` returns `TakeRestCommandCreation` (FR-066) | `TakeRestResult`: `TakeRestApplied(spentHitDice, applied: RestApplied)`, `TakeRestAppliedAfterInterruption(spentHitDice, applied: RestApplied, interrupted: RestInterrupted)` (effects are `applied.effects`, FR-049), `TakeRestNotStarted(blockers)`, `TakeRestIncomplete(hoursStillNeeded)`, `TakeRestStopped(interrupted: RestInterrupted)`, `TakeRestRejected(problem: RestReportRejection)` | `Observability` |
| `SpendHitPointDie` | `SpendHitPointDieCommand`: `CharacterId`, `HitDicePool`, `SpentHitDice`, `HitPointDie`, `AbilityModifier` (Constitution), `RestKind` (the benefits being claimed); `tryCreate` takes the host's spent counts as ints and returns `SpendHitPointDieCommandCreation` (FR-073) | `SpendHitPointDieResult`: `SpendHitPointDieApplied(roll, constitutionModifier, hitPointsRegained, spentHitDice, hitPointDieSpent)`, `SpendHitPointDieRejected(reason: HitDieSpendRejection)` | `DiceRoller`, `Observability` |

`RestInterrupted` is carried by `TakeRestAppliedAfterInterruption` and `TakeRestStopped`.

- **Port failure contract:** `DiceRoller` returns a result or throws `DiceRollerException` (a typed `Srd5eException`), which the use case propagates (FR-055). No other port fails.
- **Exports.** `character.dart` and `lib/srd5e.dart` export every type of 5.1, the two use cases with their commands, creation types and results (including `TakeRestApplied`, `TakeRestAppliedAfterInterruption`) and the domain services (`RestStartCheck`, `RestBenefits`, `HitDieRecovery`). Named variants: `CreatedTakeRestCommand`, `RejectedTakeRestCommandInput` (of `TakeRestCommandCreation`), `CreatedSpendHitPointDieCommand`, `RejectedSpendHitPointDieCommandInput` (of `SpendHitPointDieCommandCreation`), `HitDieSpendAllowed`, `HitDieSpendRejected`. `HitDicePool`, `CharacterId` and `AbilityModifier` are exported by their owners, `HitPointDie` by `content`. FR-059 applies to every name; the barrel doc comment lists each command, result and event.

## 7. Observability

Per `doc/rules/observability.md` section 2: the host may never report a rest,
may report too early or inconsistently, the `DiceRoller` may fail, or stored
spent dice may exceed the pool. Rule results are values of
`srd5e.character.result` on the counter and span; a roller failure is a thrown
`DiceRollerException` with `error.type`; corrupt stored state is a returned
rejection (`spent_exceeds_pool`, FR-073). Counted: rests by kind and result,
spends by die size and result, Hit Points per spend, thrown failures, duration.
`srd5e.character.operations` and `.duration` (`character-aggregate.md`) are
not reused. This spec defines `srd5e.character.rest_kind` (values `short`,
`long`, the snake_case of `RestKind`); `spellcasting.md` reuses it. To
diagnose: the rest kind, result, first blocker or rejection reason and, for
spends, the die size are span and counter attributes and are in the returned
result. Alert on a rise in `not_started`, `rests` flat at zero while spells
are cast, and any `error.type` on `hit_point_dice_spent`. No logs: spans and
counters carry every result; one event per rest; each failure is counted once.

**Attribute values (errors-and-results.md FR-043, shared-types-and-ownership.md
FR-041).** `srd5e.outcome` is `success` or `failure`. `success` means the
operation did what was asked; every other result is a rule outcome that
conferred nothing, recorded as `failure` with the variant in
`srd5e.character.result` (as `character-aggregate.md` FR-072 does).

| Operation | `srd5e.character.result` | `srd5e.outcome` |
|---|---|---|
| `take_rest` | `applied`, `applied_after_interruption` | `success` |
| `take_rest` | `stopped`, `incomplete`, `not_started`, `rejected` | `failure` |
| `spend_hit_point_die` | `spent` | `success` |
| `spend_hit_point_die` | `rejected` | `failure` |
| `spend_hit_point_die` | (thrown `dice_roller_exception`; result absent) | `failure`, with `error.type` `dice_roller_exception` |

A returned rule result leaves span status not error and `error.type` absent (observability.md section 6); only a thrown `DiceRollerException` sets span error status (an `ArgumentError` is not counted). `TakeRest` calls no port, so it throws only `ArgumentError`.

| Signal | Type | Attributes | Purpose | Suggested monitoring |
|---|---|---|---|---|
| `srd5e.character.take_rest` | span | `srd5e.outcome`, `srd5e.character.result` (`applied`, `applied_after_interruption`, `stopped`, `incomplete`, `not_started`, `rejected`), `srd5e.character.rest_kind` (`short`, `long`; the kind reported; defined here), `srd5e.character.rejection` (`not_started` and `rejected` only: the first blocker or the problem, snake_case) | Trace one `TakeRest` | Error status above 0 means a bug (a propagated `ArgumentError`) |
| `srd5e.character.spend_hit_point_die` | span | `srd5e.outcome`, `srd5e.character.result` (`spent`, `rejected`), `srd5e.character.hit_die_faces` (`6`, `8`, `10`, `12`), `srd5e.character.rejection` (rejections only: `none_remaining`, `not_in_pool`, `not_a_short_rest_benefit`, `spent_exceeds_pool`), `error.type` (thrown `dice_roller_exception` only) | Trace one spend, including the single roll | Error status above 0 |
| `srd5e.character.rests` | counter, `{rest}` | `srd5e.character.rest_kind`, `srd5e.outcome`, `srd5e.character.result`, `srd5e.character.rest_benefits` (`short`, `long`, `none`), `srd5e.character.rejection` (`not_started` and `rejected` only) | Rest traffic and the share of interrupted or refused rests (the only `TakeRest` counter) | `not_started` above a baseline share; a zero rate beside spell casts |
| `srd5e.character.hit_point_dice_spent` | counter, `{spend}` | `srd5e.character.hit_die_faces`, `srd5e.outcome`, `srd5e.character.result` (absent when an exception left the use case), `srd5e.character.rejection` (rejections only), `error.type` (thrown only) | One increment per `SpendHitPointDie` call (the only spend counter, so a failure is counted once) | Any `error.type`; compare `spent` with `rests` of kind `short` |
| `srd5e.character.hit_die_hit_points` | histogram, `{hit_point}` | `srd5e.character.hit_die_faces` | Hit Points regained per spent die, including the minimum of 1 | Dashboard; the mean tracks half the faces plus one plus the Constitution modifier |
| `srd5e.character.rest_operation_duration` | histogram, `s` | `srd5e.character.rest_operation` (`take_rest`, `spend_hit_point_die`) only: attributes are fixed before the timed body runs (`observability-ports.md` FR-029, FR-031) | Latency of each use case, via the `Meter` timing operation | p99 regression per operation |

Entries here feed `doc/observability/signals.md`; names and keys are constants defined once in the context (observability.md section 5). The domain (`RestStartCheck`, `RestResolution`, `RestBenefits`, `SpentHitDice`, `HitDieRecovery`) is **silent by design**; the use cases translate its values into signals.

## 8. Test plan

| Id | Level | Notes |
|---|---|---|
| FR-001 to FR-006, FR-065 | unit | `test/character/domain/rest_kind_test.dart`: values, minimum hours per variant, interruption set per rest, table 4.8a rows SI-1 to SI-5; table 4.8f (all six cells) |
| FR-009, FR-072 | unit | `long_rest_spacing_test.dart`: table 4.8g rows SC-1 to SC-6 |
| FR-007 to FR-013 | unit | `rest_start_check_test.dart`: Hit Points 0 and 1; spacing 15, 16, 17 hours, none, and a Short Rest straight after a Long Rest; Exhaustion level 6; every blocker together and their order; `hoursStillToWait` at 1 and 15 hours since; negative and out-of-range inputs |
| FR-014 to FR-023, FR-066, FR-067, FR-071 | unit | `rest_resolution_test.dart`: tables 4.8a (all rows) and 4.8b (all rows); `RestReport.tryCreate` and `TakeRestCommand.tryCreate` return every problem once each and agree with the throwing constructors row by row; a resumed Short Rest is a `resolve` result, not a creation failure |
| FR-024 to FR-036, FR-064, FR-068 | unit | `rest_benefits_test.dart`: table 4.8e rows LB-1 to LB-6, SB-1, SB-2; effect order; no effects for stopped, incomplete and rejected rests; `RestBenefits.of(shortRest, ...)` without a report equals FR-024 and raises no event; event contents (`RestInterrupted` only for the two stopped results: LI-11 to LI-13 and LI-15 raise `RestApplied` only); every `RestEvent` is a `CharacterEvent` and a `DomainEvent` and a switch over `RestEvent` is exhaustive; events of two characters are distinguishable |
| FR-037 to FR-048, FR-069, FR-073 | unit | `spent_hit_dice_test.dart`, `hit_die_recovery_test.dart`: tables 4.8c and 4.8d (SP-1 to SP-15, both `tryCreate` factories); a corrupt state returns `spentExceedsPool` and never throws; unmodifiable views; inputs not altered; `SpentHitDice` stored and read back under `spentHitDiceKey` through `FeatureStates` |
| FR-049 to FR-052, FR-058, FR-070 | application | `take_rest_test.dart`: every result variant (including `TakeRestAppliedAfterInterruption`); table 4.8a LI-10; no port other than observability; state returned unchanged on non-applied outcomes |
| FR-053 to FR-056 | application | `spend_hit_point_die_test.dart`: fixed roller records no call on a rejection and exactly one call (one die, no modifier) on an allowed spend; extremes; the roller's `DiceRollerException` propagates with state unchanged; a roller answering a different expression (count, die, modifier, one case each) makes `rollChecked` throw `DiceRollerException(invalidResult)`, propagated unchanged |
| FR-057 | application | recording and no-op `Observability` give equal results; neither use case calls another (`shared-types-and-ownership.md` FR-044); the signals of section 7 are asserted (spans, counter attributes, no log; `srd5e.outcome` only `success` or `failure`; `error.type` only `dice_roller_exception`; a thrown exception gives `failure`, `error.type` set, no `srd5e.character.result`, counted once in `hit_point_dice_spent`) |
| FR-059, FR-062 | architecture | the duplicate-name barrel scan finds each exported name of sections 5.1 and 6 exactly once (`RestKind`, `RestApplied`, `TemporaryHitPointsEndedByRest` included), no `RestKind` member `short` or `long`; no logging, metric or span call, `async`, `Future` or non-determinism in the domain files |
| FR-060, FR-061 | scenario | `test/scenarios/rests_test.dart`, public API only: Table R rows through each owner's function for both `RestKind` values (one table-driven test per row); Table W rows accept only their named rest and `source` (an interrupted Long Rest opens no Short Rest window, W-3 and W-11 to W-14 included, but recharges Short Rest features); `FeatRenewal` and `MountedPaceBoost` map from `RestApplied.benefitsOf`. Cites the owner FR in the row |
| FR-063 | doc review | the doc comments of `RestReport` and `TakeRestCommand` state the sleep, light-activity and Short Rest activity preconditions (no clock in the package, so not testable in code) |

- **Doubles:** fixed `DiceRoller` and recording `Observability` (`lib/src/testing/`; `shared-types-and-ownership.md` FR-038); no new port or contract suite.
- **Mutation testing:** `lib/src/character/domain/` rest and Hit Dice files MUST score at least 80 (testing.md section 8); likely survivors are the boundaries 0 and 1 Hit Point, 15, 16, 17 hours, 0 and 1 hour rested, required hours minus one, and the minimum of 1 Hit Point regained. `application/` SHOULD be mutated.

## 9. Open questions and decisions

**Settled** (the decision, not a question; none is escalated):

- Q-1: no use case calls another and class logic is pure (`shared-types-and-ownership.md` FR-044, FR-023): the host calls class functions, spell slot restoration and `RenewFeatUses` with `RestApplied.benefitsOf`. Q-2: values `shortRest`, `longRest`; `RestApplied` is this event; class specs define no rest event (`shared-types-and-ownership.md` FR-009, FR-017, FR-020). Q-18: `RestEvent` implements `CharacterEvent` (`shared-types-and-ownership.md` FR-019; `character-aggregate.md` FR-085; FR-068).
- Q-3: no Hit Die spend claiming Long Rest benefits (FR-045); a completed Long Rest has regained every die. Q-11: a Short Rest cannot be resumed (FR-017). Q-10: Exhaustion 6 cannot start a rest (FR-011) and `physicalExertion` stops a Short Rest, accepted not rejected (FR-006, FR-019). All readings of the text.
- Q-5: the pool is `HitDicePool` keyed by `HitPointDie` (`shared-types-and-ownership.md` FR-008; `derived-stats.md` FR-061); absent key means 0; a published `countOf` would replace it in FR-038 to FR-042. Q-20: `HitPointDie` is owned by `content-schema-and-decoder.md` FR-132 (`shared-types-and-ownership.md` FR-053); the roll is `DiceExpression(1, Die(die.faces))` (FR-054). Q-6: `SpentHitDice` lives in `FeatureStates` under `spentHitDiceKey` (`shared-types-and-ownership.md` FR-022; `character-aggregate.md` FR-092, FR-093).
- Q-8: a Long Rest is not also a Short Rest (FR-032); mapping `RestKind.recharges(RechargeTrigger)` (FR-065, `shared-types-and-ownership.md` FR-009); monster rests are out of scope (`content-monsters.md` FR-035). Q-13: the host owns time (`hit-points-and-damage.md` Q-12). Q-14: each owner reconciles its own deferral (5.4; `shared-types-and-ownership.md` FR-048). Q-19: `magic-item-rules.md` Q3 and `feats-behaviour.md` Q9 are answered in 5.4; those specs still edit their own text.
- Q-4: `character` may not import `combat` (`shared-types-and-ownership.md` FR-013), so the Exhaustion level is a plain `int` 0 to 6 here and in `class-ranger.md`; the host converts to `ExhaustionLevel` at the `combat` boundary. Permanent design, not pending: an upstream level type would be a mechanical edit. Q-7: Knocking Out a Creature (SRD 5.2.1, p. 17) and sleeping Unconscious in a Long Rest (p. 185) are conditions and Hit Point rules owned by `conditions.md` and `hit-points-and-damage.md`; this spec supplies a Short Rest startable at 1 Hit Point (FR-007) and `RestApplied(shortRest)` as the trigger. Q-9: dehydration and malnutrition Exhaustion "can't be removed" until the daily amount is taken (pp. 181, 185); `environment-hazards-and-objects.md` keeps that lock in `HazardRecord` and `RemoveExhaustionLevels` (FR-060 to FR-065), so the host routes `ExhaustionLevelReduced` through it (FR-029). Q-15: `HitPointMaximumReturnedToNormal` and `AbilityScoresReturnedToNormal` are effects the host applies (interpretation: the SRD says only that they "return to normal", p. 185, and a rest needs no stored original); owner operations are requested as amendments, none is a dependency. Q-22: `class-warlock.md` FR-078 already takes `SpentHitDice` and calls `trySpendOutsideRest` (FR-069).
- Derived: Q-12 Trance plus resumption is 4 plus one per interruption (FR-016, RH-10). Q-16 an interrupted Long Rest recharges features and allows Hit Die spends but opens no "finish a Short Rest" window (`source` `longRestInterrupted`, FR-061; a host with the opposite reading treats it as `finished`). Q-17 hours are cumulative totals floored by the host (FR-067). Q-21 a Long Rest stopped after the required hours is `RestCompleted(longRest)` (FR-071), so 9 hours never confers less than 8; a Short Rest stays no-benefits (FR-018).

## 10. Changelog impact

`CHANGELOG.md`, under `Unreleased`, **Added**: "Short Rest and Long Rest
(`RestKind`, interruption, what each restores, `TakeRest`), Hit Point Dice
spending (`SpentHitDice`, `SpendHitPointDie`) and the `RestApplied` event, in
the `character` context; telemetry `srd5e.character.take_rest`,
`srd5e.character.spend_hit_point_die`, the `rests`, `hit_point_dice_spent`,
`hit_die_hit_points` and `rest_operation_duration` metrics."
Not **BREAKING**: new API in an unreleased package. Specs that renamed their own
rest types (Q-2) change documentation only.
