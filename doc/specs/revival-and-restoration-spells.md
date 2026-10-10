# Revival and restoration spells

| | |
|---|---|
| Status | draft |
| Context | `combat` |
| Roadmap phase | 4 |
| Depends on | `combat-foundations.md`, `dice-and-rolls.md`, `modifiers-and-advantage.md`, `content-schema-and-decoder.md`, `rests-and-hit-dice.md`, `spell-effect-data.md`, `hit-points-and-damage.md`, `conditions.md`, `magical-effects.md`, `spell-effects.md`, `returning-to-life.md` |

Rank 28 (`shared-types-and-ownership.md` 4.11): right of `returning-to-life` and `spell-effects` (27), `magical-effects` (26), `conditions` (22) and `hit-points-and-damage` (21). It has no port, no use case and throws no `Srd5eException`, so `errors-and-results.md` and `observability-ports.md` are not dependencies. Consumed by `combat-action-resolution.md` and hosts (section 6). Supersedes no numbered requirement of another spec (`shared-types-and-ownership.md` FR-048); it fills the rows `spell-effect-data.md` marks "later" (E13 for Aid and Heroes' Feast, E22) and the out-of-scope lines of `returning-to-life.md`, `hit-points-and-damage.md` and `rests-and-hit-dice.md`.

**Amendments asked of other specs (none made here; labels are unique to this spec).** **RR-1** `shared-types-and-ownership.md` 4.11: add `revival-and-restoration-spells` at rank 28 (pending, as `persistent-spell-zones.md` RA-3 does for its own row). **RR-2** `combat-action-resolution.md`: the use cases and telemetry of sections 6 and 7. **RR-3** `documentation_index.md`: one row for this spec (it lists only `returning-to-life.md` today).

## 1. Purpose and scope

The spells that change a creature's Hit Points, Hit Point maximum, conditions or death, as **pure domain operations** over host-held values (state in, new state and events out). `spell-effects.md` and `spell-effect-data.md` keep these spells as text (their E13 and E22 rows, and `spell-effect-data.md` FR-005, which forbids encoding Aid as Temporary Hit Points); this spec supplies the rules those specs defer:

- **Revival spells** (Revivify, Raise Dead, Resurrection, True Resurrection): who may be revived (time since death, old age, Undead, body), the Hit Points returned, what is neutralised or lifted, the ordeal (a penalty to D20 Tests that shrinks by 1 per finished Long Rest) and the strain on the caster. The revival itself is `returning-to-life.md`, composed here.
- **Hit Point maximum increases** (Aid, Heroes' Feast): raise the maximum and current Hit Points together, combine per "Combining Spell Effects", and end by lowering the maximum again.
- **Restoration** (Lesser Restoration, Greater Restoration, Heal, Power Word Heal, Mass Heal): which conditions and other effects each ends, and the Hit Point restoration of the Heal family.
- **Death Ward**: the first drop to 0 Hit Points leaves 1 Hit Point instead.

**Out of scope:** Reincarnate and its species table (`spell-outcome-tables.md` FR-050 to FR-054); casting itself (slots, casting time, Material components and their consumption, ranges, targets: `spellcasting.md`, `spell-effects.md`); durations and expiry of Aid, Heroes' Feast and Death Ward (the host ends them, as `spell-effects.md` FR-040 does for every effect); the other Heroes' Feast benefits (Resistance to Poison damage, Immunity to Frightened and Poisoned) and the choice to stand from Prone in Power Word Heal (host or `conditions.md`); Hit Point restoration of Cure Wounds, Healing Word, Regenerate and similar (`spell-effects.md`, `hit-points-and-damage.md`); Harm's reduction of the Hit Point maximum (E13's other half: `hit-points-and-damage.md` `reduceMaximum`, FR-047, with `RestoreMaximum` here as its undo); ending Attunement to a cursed item (`magic-item-rules.md`, the host calls it); the positions of bodies and the summoned body of True Resurrection; anything outside SRD 5.2.1. Nothing core to this topic was left out; Q-1 to Q-10 flag the readings that are interpretation. **Limitation, with its escape:** a creature that died of a Hit Point maximum of 0 stays Dead for `RestoreMaximum` (FR-031); the host revives it by passing `restoredMaximum` to `ReviveBySpell` (FR-049).

## 2. Source

Printed page equals PDF page. SRD 5.2.1 spell entries: "Aid", p. 107; "Death Ward", p. 122; "Greater Restoration", p. 137; "Heal", p. 139; "Heroes' Feast", p. 140; "Lesser Restoration", p. 144; "Mass Heal", p. 147; "Power Word Heal", p. 154; "Raise Dead", p. 157; "Resurrection", pp. 158-159; "Revivify", p. 159; "True Resurrection", p. 170. Rules: "Dead", p. 180; "Combining Spell Effects", p. 106; "Hit Points", p. 183; "Healing", p. 17; "Hit Point Maximum of 0", p. 17; "Falling Unconscious", p. 17; "Knocking Out a Creature", p. 17; "Massive Damage", p. 17; "Long Rest", p. 185; "D20 Test", p. 180; "Exhaustion", p. 181; "Curses", p. 179; "Magical Contagions", p. 194. Rule files: `doc/rules/architecture.md` §2, §3, §6; `doc/rules/testing.md` §4, §5; `doc/rules/observability.md` §2, §3. Binding: `shared-types-and-ownership.md` FR-017, FR-019, FR-044, FR-048, FR-056, FR-062.

## 3. Vocabulary

| SRD term | Type | Notes |
|---|---|---|
| Revivify, Raise Dead, Resurrection, True Resurrection | `RevivalSpell` (`revivify`, `raiseDead`, `resurrection`, `trueResurrection`), `RevivalSpellFacts` | Static facts of table 4.1a. `tryFromSpell(SpellId)` maps the four ids. |
| died, dead for, Undead, old age | `DeathCircumstances(timeSinceDeath, diedOfOldAge, wasUndead, body)`, `BodyState` | Host facts. `BodyState`: `intact`, `missingNonIntegralParts`, `missingIntegralParts`, `noBody`. `timeSinceDeath` is a `Duration`. |
| poisons that affected the creature | `PoisonsAtDeath(effects, poisonedConditionFromPoison)` | The host says which listed effects are poisons (the SRD has no poison category in `magical-effects.md`). |
| the spell's cast and result | `ReviveBySpell`, `ReviveBySpellResult` | Operation prefix `ReviveBySpell`. |
| "an ordeal", "-4 penalty to D20 Tests" | `ReviveOrdeal` | 0 to 4; the host holds one per creature. |
| "taxes you" | `CasterStrain` (`none`, `strained`) | The host holds one per caster. |
| Hit Point maximum increase | `HitPointMaximumIncrease`, `HitPointMaximumIncreases` (ledger), `IncreaseMaximum`, `EndMaximumIncrease` | Operation prefixes `IncreaseMaximum`, `EndMaximumIncrease`. |
| ending a reduction to the Hit Point maximum | `RestoreMaximum` | Operation prefix `RestoreMaximum`. |
| Lesser/Greater Restoration, Heal, Power Word Heal, Mass Heal | `RestorativeSpell`, `LesserRestoration`, `GreaterRestoration`, `GreaterRestorationChoice` (sealed), `RestorativeHealing` | Operation prefixes as the names. |
| Death Ward | `DeathWard` (`active`, `spent`), `DeathWardTrigger` | Operation prefix `GuardWithDeathWard`. |
| Conditions, curses, contagions, Hit Points | `ConditionSet`, `ConditionKind`, `OngoingEffects`, `OngoingEffectId`, `CurseRemovalMeans`, `HitPointStatus`, `HitPointTransition`, `RestKind`, `Modifier`, `RollCircumstance` | Owners in the header specs. |

Package names with no SRD source: every type above except the four `RevivalSpell` values' names, `Duration` and the SRD terms; they add no rules. `BodyState` names three SRD phrases ("missing body parts", "body parts or organs integral for its survival", "the original no longer exists"). Terms follow SRD wording (`doc/rules/architecture.md` §3).

## 4. Requirements

Ids are stable. Case-table rows are one test each, citing the FR in the row.

### 4.1 Revival eligibility

Table 4.1a, the static facts of each spell (`RevivalSpellFacts`; "none" means the text states no rule, Q-1):

| Spell | Dead at most | Old age | Undead at death | Hit Points | Poison | Curses and contagions | Ordeal | Strain | Source |
|---|---|---|---|---|---|---|---|---|---|
| Revivify | 1 minute | cannot | allowed (no rule) | 1 | not neutralised | as "Dead" | none | none | p. 159 |
| Raise Dead | 10 days | allowed (no rule) | cannot | 1 | neutralised | as "Dead" | -4 | none | p. 157 |
| Resurrection | 100 years | cannot | cannot | all | neutralised | as "Dead" | -4 | at 365 days or more | pp. 158-159 |
| True Resurrection | 200 years | cannot | allowed, restored to non-Undead | all | neutralised | all lifted | none | none | p. 170 |

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-001 | `RevivalSpell.tryFromSpell(SpellId)` MUST return `revivify`, `raiseDead`, `resurrection` or `trueResurrection` for `revivify`, `raise_dead`, `resurrection` and `true_resurrection`, and `null` for any other id (including `reincarnate`, `revive` and an unknown id). | SRD 5.2.1, "Revivify" p. 159; "Raise Dead" p. 157; "Resurrection" pp. 158-159; "True Resurrection" p. 170 | happy |
| FR-002 | A revival MUST be eligible only when `timeSinceDeath` is at most the spell's window of table 4.1a, **inclusive**: 1 minute (60 s), 10 days, 100 years, 200 years. A year is 365 days (36,500 and 73,000 days); one day is 24 hours (interpretation, Q-2). Over the window the reason is `timeWindowExceeded`. | SRD 5.2.1, "Revivify" ("within the last minute") p. 159; "Raise Dead" ("no longer than 10 days") p. 157; "Resurrection" ("no more than a century") p. 159; "True Resurrection" ("no longer than 200 years") p. 170 | unhappy (boundary) |
| FR-003 | `diedOfOldAge` true MUST make Revivify, Resurrection and True Resurrection ineligible (`diedOfOldAge`); Raise Dead MUST NOT be affected, because its text names no old-age rule (Q-1). | SRD 5.2.1, "Revivify" p. 159; "Resurrection" p. 159; "True Resurrection" p. 170; "Raise Dead" p. 157 | unhappy (rule interaction) |
| FR-004 | `wasUndead` true MUST make Raise Dead and Resurrection ineligible (`wasUndead`); Revivify and True Resurrection MUST NOT be affected (Q-1). True Resurrection MUST report `restoredToNonUndead` true on success when `wasUndead` is true, and false otherwise. | SRD 5.2.1, "Raise Dead" p. 157; "Resurrection" p. 159; "True Resurrection" ("restored to its non-Undead form") p. 170 | unhappy (rule interaction) |
| FR-005 | Every revival spell is cast by touch, so `BodyState.noBody` MUST be ineligible (`noBodyToTouch`), except True Resurrection with `nameSpoken` (FR-006). Raise Dead MUST also be ineligible for `missingIntegralParts` (`integralPartsMissing`): "the spell automatically fails". `missingNonIntegralParts` and `intact` MUST be eligible for all four spells. Revivify, Resurrection and True Resurrection have no integral-parts failure by design: a host that wants one refused reports `noBody` (Q-3). | SRD 5.2.1, "Raise Dead" p. 157; "Revivify" ("nor does it restore any missing body parts") p. 159; "Resurrection" ("restores any missing body parts") p. 159; "True Resurrection" ("replaces damaged or missing organs and limbs") p. 170 | unhappy (rule interaction) |
| FR-006 | True Resurrection with `BodyState.noBody` MUST be eligible only when `nameSpoken` is true (the caster "must speak the creature's name"); otherwise the reason is `nameNotSpoken`. `nameSpoken` MUST be ignored for every other body state and spell. | SRD 5.2.1, "True Resurrection" ("can provide a new body ... you must speak the creature's name") p. 170 | unhappy (rule interaction) |
| FR-007 | `ReviveBySpell` MUST check eligibility before the spirit's consent: an ineligible cast MUST return `ReviveBySpellIneligible` listing **every** failed reason as `RevivalIneligibility` values in the fixed order `timeWindowExceeded`, `diedOfOldAge`, `wasUndead`, `noBodyToTouch`, `integralPartsMissing`, `nameNotSpoken`, with the status, conditions and effects unchanged, no events, no ordeal and no strain (Q-4). | SRD 5.2.1, "Dead" p. 180; `doc/rules/architecture.md` §6 | unhappy (rule interaction) |
| FR-008 | `DeathCircumstances` MUST throw `ArgumentError` for a negative `timeSinceDeath`; zero is valid (died this instant). | `doc/rules/architecture.md` §6; `doc/rules/testing.md` §4 | unhappy (invalid input) |

#### Case table 4.1b: eligibility (FR-002 to FR-007)

Baseline: `intact` body, not old age, not Undead, spirit accepts.

| Case | Spell | Circumstances | Expected | FR | Source | Path |
|---|---|---|---|---|---|---|
| inside the minute | Revivify | 59 s | eligible | FR-002 | p. 159 | happy |
| exactly one minute | Revivify | 60 s | eligible | FR-002 | p. 159 | unhappy (boundary) |
| one second late | Revivify | 61 s | `timeWindowExceeded` | FR-002 | p. 159 | unhappy (boundary) |
| just born dead | Revivify | 0 s | eligible | FR-008 | p. 159 | unhappy (empty and minimal) |
| 10 days exactly | Raise Dead | 10 days | eligible | FR-002 | p. 157 | unhappy (boundary) |
| 10 days and 1 s | Raise Dead | 10 days 1 s | `timeWindowExceeded` | FR-002 | p. 157 | unhappy (boundary) |
| 100 years exactly | Resurrection | 36,500 days | eligible | FR-002 | p. 159 | unhappy (boundary) |
| past a century | Resurrection | 36,500 days 1 s | `timeWindowExceeded` | FR-002 | p. 159 | unhappy (boundary) |
| 200 years exactly | True Resurrection | 73,000 days | eligible | FR-002 | p. 170 | unhappy (boundary) |
| past 200 years | True Resurrection | 73,000 days 1 s | `timeWindowExceeded` | FR-002 | p. 170 | unhappy (boundary) |
| old age, four spells | each | `diedOfOldAge` | Raise Dead eligible; the other three `diedOfOldAge` | FR-003 | pp. 157, 159, 170 | unhappy (rule interaction) |
| Undead, four spells | each | `wasUndead` | Raise Dead, Resurrection `wasUndead`; Revivify eligible; True Resurrection eligible, `restoredToNonUndead` | FR-004 | pp. 157, 159, 170 | unhappy (rule interaction) |
| no body | Revivify | `noBody` | `noBodyToTouch` | FR-005 | p. 159 | unhappy (rule interaction) |
| head missing | Raise Dead | `missingIntegralParts` | `integralPartsMissing` | FR-005 | p. 157 | unhappy (rule interaction) |
| head missing | Resurrection | `missingIntegralParts` | eligible | FR-005 | p. 159 | unhappy (rule interaction) |
| head missing, by design | Revivify | `missingIntegralParts` | eligible (Q-3) | FR-005 | p. 159 | unhappy (rule interaction) |
| head missing, host refuses | Revivify | `noBody` | `noBodyToTouch` | FR-005 | p. 159 | unhappy (rule interaction) |
| arm missing | Raise Dead | `missingNonIntegralParts` | eligible | FR-005 | p. 157 | happy |
| no body, name not spoken | True Resurrection | `noBody`, `nameSpoken` false | `nameNotSpoken` | FR-006 | p. 170 | unhappy (rule interaction) |
| no body, name spoken | True Resurrection | `noBody`, `nameSpoken` true | eligible | FR-006 | p. 170 | happy |
| name spoken, body intact | True Resurrection | `intact`, `nameSpoken` true | eligible | FR-006 | p. 170 | unhappy (boundary) |
| several reasons | Raise Dead | 11 days, Undead, `missingIntegralParts` | `timeWindowExceeded`, `wasUndead`, `integralPartsMissing` in that order | FR-007 | p. 157 | unhappy (rule interaction) |
| negative time | any | -1 s | `ArgumentError` | FR-008 | package | unhappy (invalid input) |

### 4.2 Revival outcome

`ReviveBySpell.revive(command)` takes the `RevivalSpell`, the `CombatantId` (`subject`), the Dead `HitPointStatus`, an optional `restoredMaximum` (FR-049), the creature's `ConditionSet` and `OngoingEffects`, `DeathCircumstances`, `nameSpoken`, `RevivalConsent`, `PoisonsAtDeath`, and the host's `elapsedConditions` and `elapsedEffects` (`returning-to-life.md` FR-009, FR-010). It returns `ReviveBySpellApplied(revival, ordeal, strain, restoredToNonUndead)`, `ReviveBySpellIneligible(reasons)` or `ReviveBySpellNotRevived(revival, strain)`, where `revival` is the `returning-to-life.md` result.

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-009 | The Hit Point value handed to the revival MUST be 1 for Revivify and Raise Dead, and the Hit Point maximum for Resurrection and True Resurrection ("all its Hit Points"); a maximum below 1 MUST be handed on as 1, so `returning-to-life.md` FR-006 returns `ReviveCreatureMaximumBelowOne` and `ReviveCreatureHitPointsBelowOne` is unreachable from this spec. | SRD 5.2.1, "Revivify" p. 159; "Raise Dead" p. 157; "Resurrection" p. 159; "True Resurrection" p. 170; `returning-to-life.md` FR-003, FR-006 | happy |
| FR-010 | An eligible cast MUST call `Revival.revive` (`returning-to-life.md`) with the consent and the elapsed sets of FR-011 and FR-012. A successful call MUST return `ReviveBySpellApplied` holding that `ReviveCreatureApplied`. Every other variant (`ReviveCreatureNotDead`, `ReviveCreatureRefused`, `ReviveCreatureMaximumBelowOne`) MUST be returned unchanged inside `ReviveBySpellNotRevived`. The conditions, Exhaustion reduction and events of the revival are `returning-to-life.md` FR-009, FR-011, FR-013; this spec adds none. | SRD 5.2.1, "Dead" p. 180; `returning-to-life.md` FR-001 to FR-003, FR-013 | happy |
| FR-011 | For Raise Dead, Resurrection and True Resurrection ("neutralizes any poison") every id in `PoisonsAtDeath.effects` MUST be added to `elapsedEffects`, and the `Poisoned` condition kind MUST be added to `elapsedConditions` when `poisonedConditionFromPoison` is true. Revivify MUST add neither (Table 4.1a). The host's own elapsed sets MUST be kept (union). | SRD 5.2.1, "Raise Dead" p. 157; "Resurrection" p. 159; "True Resurrection" p. 170; `returning-to-life.md` FR-009, FR-010 | happy |
| FR-012 | True Resurrection MUST add to `elapsedEffects` the id of every held `OngoingEffect` of category `curse` or `magicalContagion` ("cures all magical contagions, and lifts any curses affecting the creature when it died"). The other three spells MUST NOT: those effects return when their durations are still ongoing and the host reports them elapsed (`returning-to-life.md` FR-010). Effects of the categories `spell` and `magicalEffect` MUST be unaffected by the spell. | SRD 5.2.1, "True Resurrection" p. 170; "Dead" p. 180 | unhappy (rule interaction) |
| FR-013 | A spell that neutralises or lifts something MUST NOT touch Exhaustion, explicit conditions other than `Poisoned` (FR-011), or an id the creature does not hold: `returning-to-life.md` FR-011 and FR-015 decide those. | SRD 5.2.1, "Dead" p. 180 | unhappy (rule interaction) |
| FR-014 | `ReviveBySpellApplied.ordeal` and `.strain` MUST be the values FR-018 and FR-022 give. `ReviveBySpellNotRevived.strain` MUST be the strain of FR-022 when the variant wraps `ReviveCreatureRefused` and `CasterStrain.none` otherwise. `ReviveBySpellIneligible` carries neither. | SRD 5.2.1, "Resurrection" ("Casting this spell to revive ...") p. 159; Q-5 | unhappy (rule interaction) |
| FR-015 | `ReviveBySpell` MUST NOT alter its inputs, MUST return unmodifiable collections, MUST give equal results for equal inputs, and MUST emit only the events of the revival (no event of its own). | `doc/rules/testing.md` §4 (immutability, determinism) | unhappy (immutability) |
| FR-049 | When the status is `Dead` with cause `hitPointMaximumZero` and maximum 0, a non-null `restoredMaximum` (at least 1; `ArgumentError` below 1) MUST be used as the maximum: `ReviveBySpell` rebuilds the status as Dead with that maximum and the same cause, then proceeds by FR-009 (Resurrection and True Resurrection restore it in full, the others 1). In every other status `restoredMaximum` MUST be ignored. Without it, such a creature yields `ReviveCreatureMaximumBelowOne` (FR-009). This is the host-side way for a GM who rules that the spell restores the lost maximum (Q-10); the SRD text states no restored maximum, so the package never invents one. | SRD 5.2.1, "Hit Point Maximum of 0" p. 17; "Dead" p. 180; `returning-to-life.md` FR-006, FR-007; Q-10 | unhappy (rule interaction) |

#### Case table 4.2: what a cast returns (FR-009 to FR-013)

Baseline: Dead, maximum 20, `ConditionSet` {Poisoned, Blinded}, `OngoingEffects` [curse `c1`, contagion `c2`, spell `s1`, poison `p1`], `PoisonsAtDeath({p1}, true)`, spirit accepts, nothing reported elapsed.

| Case | Spell | Expected Hit Points | Expected conditions | Expected effects | FR | Path |
|---|---|---|---|---|---|---|
| Revivify keeps everything | Revivify | 1 | Poisoned, Blinded | `c1`, `c2`, `s1`, `p1` | FR-009, FR-011, FR-012 | happy |
| Raise Dead neutralises poison | Raise Dead | 1 | Blinded | `c1`, `c2`, `s1` | FR-011, FR-012 | unhappy (rule interaction) |
| Resurrection | Resurrection | 20 | Blinded | `c1`, `c2`, `s1` | FR-009, FR-011 | happy |
| True Resurrection lifts all | True Resurrection | 20 | Blinded | `s1` | FR-012 | unhappy (rule interaction) |
| poison condition not from poison | Raise Dead, `poisonedConditionFromPoison` false | 1 | Poisoned, Blinded | `c1`, `c2`, `s1` | FR-011 | unhappy (rule interaction) |
| host reports `s1` elapsed | Revivify, `elapsedEffects` {`s1`} | 1 | Poisoned, Blinded | `c1`, `c2`, `p1` | FR-011 | unhappy (rule interaction) |
| poison id not held | Raise Dead, `PoisonsAtDeath({p9}, false)` | 1 | Poisoned, Blinded | `c1`, `c2`, `s1`, `p1` | FR-013 | unhappy (invalid input) |
| Exhaustion 3, all four spells | each | per row 1 or 20 | Exhaustion 2 | unchanged | FR-013 | unhappy (rule interaction) |
| maximum 0 | Resurrection, status maximum 0 | `ReviveBySpellNotRevived` (`ReviveCreatureMaximumBelowOne`) | n/a | n/a | FR-009, FR-010 | unhappy (boundary) |
| maximum 0, host restores 12 | Resurrection, `restoredMaximum` 12 | 12, Alive | per baseline | per baseline | FR-049 | unhappy (rule interaction) |
| maximum 0, host restores 12 | Raise Dead, `restoredMaximum` 12 | 1 of 12, Alive | per baseline | per baseline | FR-049 | unhappy (rule interaction) |
| `restoredMaximum` 0 / ignored | `restoredMaximum` 0; and 5 on a status with maximum 20 | `ArgumentError`; maximum stays 20 | n/a | n/a | FR-049 | unhappy (invalid input) |
| spirit refuses | Revivify | `ReviveBySpellNotRevived` (`ReviveCreatureRefused`), status unchanged | n/a | n/a | FR-010 | unhappy (rule interaction) |
| creature not Dead | Revivify, `Alive` status | `ReviveBySpellNotRevived` (`ReviveCreatureNotDead`) | n/a | n/a | FR-010 | unhappy (state error) |

### 4.3 The ordeal

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-016 | `ReviveOrdeal(penalty)` MUST accept 0 to 4 and throw `ArgumentError` outside it; `ReviveOrdeal.none` is 0 and `ReviveOrdeal.fresh` is 4. It MUST expose `modifier`, the `Modifier` of `-penalty` (0 for none), and be equal by value. | SRD 5.2.1, "Raise Dead" ("-4 penalty to D20 Tests") p. 157; `shared-types-and-ownership.md` FR-001 | happy |
| FR-017 | `ReviveOrdeal.afterRest(RestKind)` MUST lower the penalty by 1, never below 0, for `RestKind.longRest`, and MUST return an equal value for `RestKind.shortRest`. The host passes `RestApplied.benefitsOf` (`rests-and-hit-dice.md` FR-061), so a Long Rest interrupted into Short Rest benefits does not reduce it ("finishes a Long Rest"). | SRD 5.2.1, "Raise Dead" p. 157; "Long Rest" p. 185; `rests-and-hit-dice.md` FR-036, FR-061 | unhappy (boundary) |
| FR-018 | A successful Raise Dead or Resurrection MUST give `ReviveOrdeal.fresh` (4). A successful Revivify or True Resurrection MUST give `ReviveOrdeal.none`: their texts state no penalty. A revival MUST NOT add to an ordeal the creature already had before it died: the result is the fresh value, not a sum (Q-6). | SRD 5.2.1, "Raise Dead" p. 157; "Resurrection" p. 159; "Revivify" p. 159; "True Resurrection" p. 170 | unhappy (rule interaction) |
| FR-019 | The ordeal applies to **every** D20 Test (ability checks, saving throws including Death Saving Throws, attack rolls, initiative) as one more `Modifier` in the host's `RollModifiers` and in the Death Saving Throw total (`hit-points-and-damage.md` FR-061). It stacks with the Exhaustion reduction (`conditions.md` FR-041): the two are summed, never the larger of them. The package reads the penalty nowhere else. | SRD 5.2.1, "Raise Dead" p. 157; "D20 Test" p. 180; "Exhaustion" ("D20 Tests Affected") p. 181 | unhappy (rule interaction) |

Case table 4.3, ordeal after rests (FR-016 to FR-018; Source for every row: SRD 5.2.1, "Raise Dead" p. 157):

| Case | Start | Rest | Result | Path |
|---|---|---|---|---|
| fresh | none | n/a | 4, modifier -4 | happy |
| first Long Rest | 4 | `longRest` | 3 | happy |
| second to fourth | 3, 2, 1 | `longRest` | 2, 1, 0 | happy |
| already clear | 0 | `longRest` | 0, modifier 0 | unhappy (boundary) |
| Short Rest | 4 | `shortRest` | 4 | unhappy (rule interaction) |
| interrupted Long Rest | 4 | benefits `shortRest` | 4 | unhappy (rule interaction) |
| constructor range | 5 and -1 | n/a | `ArgumentError` | unhappy (invalid input) |
| revived while penalised | creature held 2, Raise Dead | n/a | 4 | unhappy (rule interaction) |

### 4.4 Caster strain

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-020 | A Resurrection cast whose `timeSinceDeath` is **365 days or more** (inclusive) MUST give `CasterStrain.strained` when the cast is applied or the spirit refuses (FR-014). Under 365 days, and for the other three spells at any time, the strain MUST be `none`. | SRD 5.2.1, "Resurrection" ("dead for 365 days or longer taxes you") p. 159; Q-5 | unhappy (boundary) |
| FR-021 | While `strained`, `canCastSpells` MUST be false ("you can't cast spells again", every spell including cantrips, Q-7) and `rollCircumstances` MUST contain one `Disadvantage` instance (`RollCircumstance`, `modifiers-and-advantage.md` FR-042) for every D20 Test, for the host to merge with other sources through `RollMode.resolve` (`modifiers-and-advantage.md` FR-042). While `none`, `canCastSpells` MUST be true and the list empty. | SRD 5.2.1, "Resurrection" p. 159; "D20 Test" p. 180 | unhappy (rule interaction) |
| FR-022 | `CasterStrain.afterRest(RestKind)` MUST return `none` for `RestKind.longRest` (the host passes `RestApplied.benefitsOf`) and an equal value for `RestKind.shortRest`. A second strained cast while strained MUST leave it `strained` (strain does not stack). | SRD 5.2.1, "Resurrection" ("Until you finish a Long Rest") p. 159; "Long Rest" p. 185 | unhappy (boundary) |

Case table 4.4 (FR-020 to FR-022; Source for every row: SRD 5.2.1, "Resurrection" p. 159): 364 days 23 h is `none` (boundary); 365 days is `strained` (boundary); 5,000 days `strained` (happy); Raise Dead after 400 days `none` (rule interaction); True Resurrection after 70,000 days `none` (rule interaction); ineligible Resurrection cast at 400 days gives no strain (FR-007, FR-014); spirit refuses at 400 days gives `strained` (FR-014); `strained` has `canCastSpells` false and one `Disadvantage` instance (FR-021); `afterRest(longRest)` gives `none`, `afterRest(shortRest)` stays `strained` (FR-022).

### 4.5 Hit Point maximum increases (Aid, Heroes' Feast)

`HitPointMaximumIncrease(effectId, spell, amount)`: an `OngoingEffectId`, the `SpellId` that grants it and a positive amount. `HitPointMaximumIncreases` is the host-held ledger (unmodifiable list, no duplicate `effectId`). The increase is **not** Temporary Hit Points (`spell-effect-data.md` FR-005; `hit-points-and-damage.md` FR-031, FR-032 do not apply): it changes `HitPoints.maximum` and `current`.

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-023 | `HitPointMaximumIncrease.aid(effectId, castLevel)` MUST give `5 * (castLevel - 1)` (level 2: 5; level 3: 10; level 9: 40) and MUST throw `ArgumentError` for a `castLevel` below 2 or above 9. The constructor MUST throw `ArgumentError` for an amount below 1. (Reading: "increase by 5 for each spell slot level above 2" adds to the base 5, Q-8.) | SRD 5.2.1, "Aid", "Using a Higher-Level Spell Slot" p. 107 | happy |
| FR-024 | `HitPointMaximumIncrease.heroesFeast(effectId, RollResult)` MUST accept only a result whose expression is exactly `2d10` with modifier 0 (count 2, die d10) and use `total` (2 to 20) as the amount; any other expression MUST throw `ArgumentError`. The package rolls nothing (`dice-and-rolls.md` FR-033). One roll per creature is the host's choice. | SRD 5.2.1, "Heroes' Feast" ("increases by 2d10") p. 140 | unhappy (invalid input) |
| FR-025 | The ledger MUST apply "Combining Spell Effects": the active amount of one `SpellId` is the **largest** amount among its entries (the most recent entry wins an equal amount, which changes nothing observable); the effective total is the **sum** over distinct `SpellId`s. Ending the larger entry of a spell lets the smaller entry of the same spell show again. | SRD 5.2.1, "Combining Spell Effects" p. 106 | unhappy (rule interaction) |
| FR-026 | `IncreaseMaximum` on an Alive, Dying or Stable creature MUST add the entry to the ledger, raise `HitPoints.maximum` by the **change in the effective total** (FR-025) and then restore the same change to current Hit Points through `restore` (`hit-points-and-damage.md` FR-109), so current is raised by the change and never above the new maximum. Temporary Hit Points MUST be kept. A change of 0 (a weaker second Aid) MUST add the entry and change the status and events not at all. The new status is built through the restore factory (`hit-points-and-damage.md` FR-087). | SRD 5.2.1, "Aid" p. 107; "Heroes' Feast" ("gains the same number of Hit Points") p. 140; "Hit Points" p. 183 | happy |
| FR-027 | `IncreaseMaximum` on a creature at 0 Hit Points (Dying or Stable) MUST make it Alive at the added amount, reset the Death Saving Throw tallies and follow `hit-points-and-damage.md` FR-038 (`HitPointsRestored`, `Recovered`): the status type cannot hold current Hit Points above 0 in those states (`hit-points-and-damage.md` FR-089), so the current increase is regaining Hit Points (interpretation, Q-9). | SRD 5.2.1, "Falling Unconscious" p. 17; `hit-points-and-damage.md` FR-038, FR-089 | unhappy (rule interaction) |
| FR-028 | `EndMaximumIncrease(effectId)` MUST remove the entry, and lower the maximum by the **drop in the effective total** through `reduceMaximum` (`hit-points-and-damage.md` FR-047, FR-109): current is lowered to the new maximum only when above it, and no current Hit Points are lost otherwise. It is not damage: no `DamageTaken`, no Death Saving Throw failure, no Temporary Hit Point loss. A drop of 0 (ending the weaker entry of a spell) MUST change the status not at all. Reaching a maximum of 0 is `hit-points-and-damage.md` FR-046. | SRD 5.2.1, "Hit Points" ("You can't have more Hit Points than your Hit Point maximum") p. 183; "Hit Point Maximum of 0" p. 17; Q-9 | unhappy (boundary) |
| FR-029 | An `effectId` not in the ledger MUST return `EndMaximumIncreaseNotPresent` with status and ledger unchanged; a duplicate `effectId` on increase MUST throw `ArgumentError`; a Dead creature MUST return `IncreaseMaximumRejected` / `EndMaximumIncreaseRejected` holding `CreatureIsDead`, status and ledger unchanged (`hit-points-and-damage.md` FR-075). **Precedence:** Dead is checked first, then the duplicate precondition, so a Dead creature with a duplicate id returns the rejection and does not throw. | SRD 5.2.1, "Dead" p. 180; `hit-points-and-damage.md` FR-075 | unhappy (state error) |
| FR-030 | Events (members of the sealed `RestorationEvent`, FR-046; past tense, `combatants == [subject]`): `HitPointMaximumIncreased(newMaximum, increase)` before the events of the `restore` call; `HitPointMaximumIncreaseEnded(newMaximum, drop, hitPointsLost)` before the events of the `reduceMaximum` call, `hitPointsLost` being the current Hit Points removed (0 when none). Neither is emitted for a change of 0. | `doc/rules/architecture.md` §3; `combat-foundations.md` FR-015 to FR-019 | happy |

Case table 4.5 (maximum 20, current 15, FR-023 to FR-030; Source for every row: SRD 5.2.1, "Aid" p. 107 unless given):

| Case | Operation | Expected maximum, current | Path |
|---|---|---|---|
| Aid at level 2 | `IncreaseMaximum` aid 5 | 25, 20 | happy |
| Aid at level 3 | aid 10 | 30, 25 | happy |
| Heroes' Feast roll 7 (p. 140) | `heroesFeast` 7 | 27, 22 | happy |
| at full Hit Points | current 20, aid 5 | 25, 25 | unhappy (boundary) |
| two Aids | aid 5 then aid 10 | total 10: 30, 25 | unhappy (rule interaction) |
| weaker second Aid | aid 10 then aid 5 | total 10: unchanged by the second | unhappy (rule interaction) |
| equal second Aid | aid 5 then aid 5 | total 5: unchanged by the second | unhappy (boundary) |
| Aid and Heroes' Feast | aid 5 (spell A) and 7 (spell B) | total 12: 32, 27 | unhappy (rule interaction) |
| end Aid, current inside | aid 5 ends, current 15 | 20, 15, `hitPointsLost` 0 | happy |
| end Aid, current above | current 25 of 25, aid 5 ends | 20, 20, `hitPointsLost` 5 | unhappy (boundary) |
| end the stronger of one spell | aid 10 and aid 5 (two casts), end 10 | total 10 to 5: drop 5 | unhappy (rule interaction) |
| end the weaker | same, end 5 | drop 0, unchanged | unhappy (rule interaction) |
| Dying creature | maximum 20, current 0, aid 5 | 25, 5, Alive, `Recovered` | unhappy (state error) |
| maximum drained meanwhile (interpretation, Q-9) | maximum 4 after a reduction, aid 5 ends | 0, Dead (`hitPointMaximumZero`) | unhappy (boundary) |
| Dead creature | aid | `IncreaseMaximumRejected` | unhappy (state error) |
| Dead creature, end | `EndMaximumIncrease` | `EndMaximumIncreaseRejected`, ledger unchanged | unhappy (state error) |
| Dead and duplicate id | `IncreaseMaximum` with an id already in the ledger | `IncreaseMaximumRejected`, no throw (FR-029 precedence) | unhappy (state error) |
| duplicate id | `IncreaseMaximum` with an id already in the ledger, creature Alive | `ArgumentError` | unhappy (invalid input) |
| Stable creature | maximum 20, current 0, Stable, aid 5 | 25, 5, Alive, `Recovered` | unhappy (state error) |
| Temporary Hit Points kept | temp 4, aid 5 | maximum 25, current 20, temp 4 | unhappy (rule interaction) |
| level 1 / 10 | `aid` | `ArgumentError` | unhappy (invalid input) |
| roll `3d10` or `2d10+1` | `heroesFeast` | `ArgumentError` | unhappy (invalid input) |
| unknown id | end | `EndMaximumIncreaseNotPresent` | unhappy (state error) |

### 4.6 Restoring a reduced Hit Point maximum

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-031 | `RestoreMaximum(amount)` (the amount of one reduction the host recorded from a `HitPointMaximumReduced` event) MUST raise `HitPoints.maximum` by the amount and MUST leave current Hit Points, Temporary Hit Points and `LifeState` unchanged: ending a reduction restores no Hit Points. It MUST emit `HitPointMaximumRestored(newMaximum, amount)`. An amount of 0 MUST be a no-op with no event; a negative amount MUST throw `ArgumentError`; a Dead creature MUST return `RestoreMaximumRejected` holding `CreatureIsDead` (a creature that died of a maximum of 0 stays Dead here; `ReviveBySpell` with `restoredMaximum`, FR-049, is the way back; Q-10). | SRD 5.2.1, "Greater Restoration" ("Any reduction to the target's Hit Point maximum") p. 137; "Hit Point Maximum of 0" p. 17; `hit-points-and-damage.md` FR-047, FR-075 | unhappy (boundary) |

Case table 4.6 (FR-031; Source: SRD 5.2.1, "Greater Restoration" p. 137): maximum 12 current 12 restore 8 gives 20, 12 (happy); Dying at 0 stays Dying (state error); amount 0 no event (boundary); amount -1 `ArgumentError`; Dead rejected.

### 4.7 Restoration spells

Table 4.7a, `RestorativeSpell` facts (Hit Points are restored with `restore`; the conditions are removed with `conditions.md` `remove`):

| Spell | Level | Hit Points restored | Conditions ended | Source |
|---|---|---|---|---|
| Lesser Restoration | 2 | none | one of Blinded, Deafened, Paralyzed, Poisoned (the host's choice) | p. 144 |
| Greater Restoration | 5 | none | one of: 1 Exhaustion level; Charmed; Petrified; a curse; ability score reduction; Hit Point maximum reduction | p. 137 |
| Heal | 6 | 70, plus 10 per slot level above 6 | Blinded, Deafened, Poisoned | p. 139 |
| Power Word Heal | 9 | all (the maximum) | Charmed, Frightened, Paralyzed, Poisoned, Stunned | p. 154 |
| Mass Heal | 9 | up to 700, divided as the caster chooses | Blinded, Deafened, Poisoned, for each creature healed | p. 147 |

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-032 | `LesserRestoration.apply(subject, set, kind)` MUST accept exactly `blinded`, `deafened`, `paralyzed` and `poisoned` (any other `ConditionKind` MUST throw `ArgumentError`) and end that **one** condition through `remove`, returning `LesserRestorationApplied(set, events)`. A kind the creature does not hold as an explicit condition MUST return `LesserRestorationNothingToEnd(set)` with no events. The `conditions.md` outcomes `ConditionRemovalNotPresent` and `ConditionRemovalImpliedBy` map to it unchanged (the implied-by kinds are reported). | SRD 5.2.1, "Lesser Restoration" p. 144; `conditions.md` FR-031, FR-115 | happy |
| FR-033 | `GreaterRestoration.apply` MUST take exactly one `GreaterRestorationChoice` (sealed: `EndOneExhaustionLevel`, `EndCharmed`, `EndPetrified`, `EndCurse(OngoingEffectId)`, `EndAbilityScoreReduction`, `EndHitPointMaximumReduction(amount)`) and apply only that effect ("one of the following effects"). A cast cannot take two choices because the type holds one. | SRD 5.2.1, "Greater Restoration" p. 137 | unhappy (rule interaction) |
| FR-034 | `EndOneExhaustionLevel` MUST be `reduceExhaustion(subject, 1)` (`conditions.md` FR-043, FR-044): level `n` gives `n - 1`, level 1 ends the condition, and a creature with no Exhaustion returns `GreaterRestorationNothingToEnd` with no events (`conditions.md` FR-046). `EndCharmed` and `EndPetrified` MUST be `remove` of that kind, with `GreaterRestorationNothingToEnd` when it is not held explicitly. Ending Petrified MUST NOT end a condition that another explicit condition still implies (`conditions.md` FR-033). | SRD 5.2.1, "Greater Restoration" p. 137; "Exhaustion" p. 181; `conditions.md` FR-036, FR-043, FR-046 | happy |
| FR-035 | `EndCurse(id)` MUST use `CurseRemoval.remove` with `CurseRemovalMeans.greaterRestoration` (`magical-effects.md` FR-028, FR-030 to FR-032), mapping `RemoveCurseNotPresent` and `RemoveCurseNotACurse` to `GreaterRestorationNothingToEnd` and `GreaterRestorationNotACurse` (no events, inputs unchanged). `magical-effects.md`'s `RemoveCurseApplied` and `CurseRemoved` carry the id and means but not the source, so this operation MUST read the `EffectSource` of the curse from the host's `OngoingEffects` entry before removal and carry it on `GreaterRestorationApplied`, so the host can end Attunement to a cursed magic item when the source is a `MagicItemSource` ("including the target's Attunement"); this spec ends no Attunement. | SRD 5.2.1, "Greater Restoration" p. 137; "Curses" p. 179 | unhappy (rule interaction) |
| FR-036 | `EndHitPointMaximumReduction(amount)` MUST be `RestoreMaximum` (FR-031). `EndAbilityScoreReduction` changes no combat state: the package has no ability-score-reduction state, so the result is `GreaterRestorationHostResolved`, which the host applies to its own scores (Q-10). | SRD 5.2.1, "Greater Restoration" p. 137 | unhappy (rule interaction) |
| FR-037 | `RestorativeHealing.apply(spell, subject, status, set, amount, castLevel)` (`castLevel` read for Heal only) for Heal, Power Word Heal and Mass Heal MUST restore `amount` with `restore` first, then remove each condition of table 4.7a that the creature holds explicitly, in the table's order. Absent conditions MUST be skipped without an event or error, and the removals MUST happen even when nothing was regained (a creature at its maximum). The restoration events precede the condition events. | SRD 5.2.1, "Heal" p. 139; "Power Word Heal" p. 154; "Mass Heal" p. 147; `hit-points-and-damage.md` FR-036, FR-109 | happy |
| FR-038 | The amount MUST be: Heal the `amount` the caller supplies from the spell's data (`spell-effect-data.md` FR-016, rows L10 to L12: 70 plus 10 per slot level above 6, so 70 to 100), with `RestorativeHealing` taking the `castLevel` only to validate it (below 6 or above 9 MUST throw `ArgumentError`) and holding no copy of the formula, so there is one source of truth; Power Word Heal the status's maximum; Mass Heal the creature's allotment. A Dead creature MUST return `RestorativeHealingRejected` holding `CreatureIsDead` with nothing removed: a spell cannot end conditions on a creature it cannot heal ("A dead creature ... can't regain them", Q-10). | SRD 5.2.1, "Heal" p. 139; "Dead" p. 180; `hit-points-and-damage.md` FR-039 | unhappy (state error) |
| FR-039 | A creature at 0 Hit Points healed by Heal, Power Word Heal or Mass Heal MUST follow `hit-points-and-damage.md` FR-038 (Alive, tallies reset, `Recovered`). Power Word Heal's Prone rule ("can use its Reaction to stand up") MUST be left to the host. | SRD 5.2.1, "Power Word Heal" p. 154; "Falling Unconscious" p. 17 | unhappy (rule interaction) |
| FR-040 | `MassHealAllotment(Map<CombatantId, int>)` MUST throw `ArgumentError` for an allotment below 0 or a total above 700 ("up to 700"), accept an empty map, and treat an allotment of 0 as "not healed": that creature gets neither Hit Points nor condition removal (interpretation: "Creatures healed by this spell", Q-8). The package does not choose the split. | SRD 5.2.1, "Mass Heal" p. 147 | unhappy (boundary) |

Case table 4.7b (FR-032 to FR-040; Source: the spell's page of table 4.7a):

| Case | Spell, inputs | Expected | FR | Path |
|---|---|---|---|---|
| Lesser, held | `poisoned`, set {Poisoned, Blinded} | {Blinded} | FR-032 | happy |
| Lesser, not held | `deafened`, set {Blinded} | nothing to end | FR-032 | unhappy (state error) |
| Lesser, wrong kind | `charmed` | `ArgumentError` | FR-032 | unhappy (invalid input) |
| Lesser, one only | `blinded`, set {Blinded, Deafened} | {Deafened} | FR-032 | unhappy (rule interaction) |
| Greater, Exhaustion 3 | `EndOneExhaustionLevel` | Exhaustion 2 | FR-034 | happy |
| Greater, Exhaustion 1 | same | no Exhaustion | FR-034 | unhappy (boundary) |
| Greater, no Exhaustion | same | nothing to end | FR-034 | unhappy (empty and minimal) |
| Greater, Charmed / Petrified | `EndCharmed`, `EndPetrified` | removed (one test each) | FR-034 | happy |
| Greater, Petrified with Paralyzed | `EndPetrified`, set {Petrified, Paralyzed} | Paralyzed and its implied Incapacitated stay | FR-034 | unhappy (rule interaction) |
| Greater, curse | `EndCurse(c1)` | `c1` gone, source reported | FR-035 | happy |
| Greater, not a curse | `EndCurse(s1)` | not a curse, unchanged | FR-035 | unhappy (state error) |
| Greater, ability score | `EndAbilityScoreReduction` | host-resolved | FR-036 | unhappy (rule interaction) |
| Lesser, implied only | `blinded`, set {} with Blinded implied by another held kind | `ConditionRemovalImpliedBy` mapped to nothing to end, implied-by kinds reported, set unchanged | FR-032 | unhappy (rule interaction) |
| Greater, Charmed / Petrified not held | `EndCharmed`, `EndPetrified` on a set without them | nothing to end, no events (one test each) | FR-034 | unhappy (state error) |
| Greater, curse from an item | `EndCurse(c3)`, `c3` sourced by a `MagicItemSource` | `c3` gone, `GreaterRestorationApplied` carries the `MagicItemSource` | FR-035 | unhappy (rule interaction) |
| Heal at 10 | castLevel 10 | `ArgumentError` | FR-038 | unhappy (invalid input) |
| Heal, amount from data | castLevel 6 to 9 | the caller's amounts equal the `spell-effect-data.md` L10 to L12 values (70 to 100) | FR-038 | unhappy (boundary) |
| Power Word Heal on Dead | Dead, Stunned | `RestorativeHealingRejected`, Stunned kept | FR-038 | unhappy (state error) |
| Mass Heal on Dead | Dead, allotment 50, Blinded | `RestorativeHealingRejected`, Blinded kept | FR-038 | unhappy (state error) |
| Mass Heal negative | {a: -1} | `ArgumentError` | FR-040 | unhappy (invalid input) |
| Heal at 6 | current 5 of 100 | 75; Blinded, Poisoned ended, Charmed kept | FR-037, FR-038 | happy |
| Heal at 7, 8, 9 | current 1 of 500 | +80, +90, +100 | FR-038 | unhappy (boundary) |
| Heal at 5 | castLevel 5 | `ArgumentError` | FR-038 | unhappy (invalid input) |
| Heal at full | current = maximum, Poisoned | Hit Points unchanged, Poisoned ended | FR-037 | unhappy (boundary) |
| Heal, none held | set empty | Hit Points only | FR-037 | unhappy (empty and minimal) |
| Heal on Dead | Dead, Blinded | rejected, Blinded kept | FR-038 | unhappy (state error) |
| Heal on Dying | current 0 | Alive | FR-039 | unhappy (rule interaction) |
| Power Word Heal | current 3 of 40, Stunned, Prone | 40; Stunned ended, Prone kept | FR-037, FR-038 | happy |
| Mass Heal split | {a: 400, b: 300} | total 700 valid | FR-040 | unhappy (boundary) |
| Mass Heal over | total 701 | `ArgumentError` | FR-040 | unhappy (boundary) |
| Mass Heal zero | {a: 0} | a untouched, Blinded kept | FR-040 | unhappy (boundary) |

### 4.8 Death Ward

`DeathWard` is `active` or `spent` (the host holds it per warded creature and ends it when the 8 hours pass). `GuardWithDeathWard.applyDamage` takes the same inputs as `applyDamage` (`hit-points-and-damage.md` FR-109) plus the `DeathWard`, and returns `GuardedDamageApplied(transition, ward)` or the refusal of the wrapped call.

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-041 | With an `active` ward, the operation MUST first run the real `applyDamage`. If its events contain no `DroppedToZeroHitPoints`, it MUST return that transition unchanged with the ward `active`. The ward is not spent by damage that leaves the creature above 0, by damage to a creature already at 0 Hit Points, by a knock-out (`KnockedOut`: the creature never "would drop to 0"), or by a refused call. | SRD 5.2.1, "Death Ward" ("The first time the target would drop to 0 Hit Points") p. 122; "Knocking Out a Creature" p. 17 | unhappy (boundary) |
| FR-042 | If the events contain `DroppedToZeroHitPoints`, the operation MUST discard that transition and rerun `applyDamage` on the **same** status with `DamageDelivery.MeleeAttackKnockOut` (`hit-points-and-damage.md` FR-050), so the creature has 1 Hit Point and stays Alive whatever its `ZeroHitPointsRule` or the kind of the first delivery. It MUST replace the `KnockedOut` event with `DeathWardSpent(reason: dropToZero)` as the last event, MUST return the ward `spent`, and MUST NOT apply Massive Damage or a Death Saving Throw failure (the creature did not drop to 0). Temporary Hit Points, `DamageTaken` and `BecameBloodied` are those of the rerun. | SRD 5.2.1, "Death Ward" ("instead drops to 1 Hit Point, and the spell ends") p. 122; "Massive Damage" p. 17; Q-10 | happy |
| FR-043 | `GuardWithDeathWard.negateInstantKill(subject, status, ward)` is for an effect the **host** classifies as one that "would kill it instantly without dealing damage". With an `active` ward and a creature that is not Dead it MUST leave the status unchanged, return the ward `spent` and emit `DeathWardSpent(reason: instantKill)`. The package does not decide which effects qualify (Q-10). | SRD 5.2.1, "Death Ward" ("that effect is negated against the target, and the spell ends") p. 122 | unhappy (rule interaction) |
| FR-044 | With a `spent` ward, both operations MUST pass through: `applyDamage` returns the plain transition (Dying or Dead as the rules say) and `negateInstantKill` returns `GuardedDamageNotWarded` with nothing changed. A Dead creature MUST return the refusal (`CreatureIsDead`) and the ward unchanged. The ward guards **only** `applyDamage` (FR-041, FR-042): a Hit Point maximum reduced to 0 (`reduceMaximum`, `hit-points-and-damage.md` FR-046), an Exhaustion death and any other loss that does not go through `applyDamage` are not guarded, and `negateInstantKill` is the host's path for an effect it classifies as an instant kill (Q-10). | SRD 5.2.1, "Death Ward" p. 122; `hit-points-and-damage.md` FR-066 | unhappy (state error) |

Case table 4.8 (FR-041 to FR-044; baseline: maximum 20, `FallsUnconscious`, ward `active`; Source for every row: SRD 5.2.1, "Death Ward" p. 122):

| Case | Current, temp, damage, delivery | Expected | FR | Path |
|---|---|---|---|---|
| ordinary hit | 20, 0, 5, other | 15, ward `active` | FR-041 | happy |
| exactly to 0 | 5, 0, 5, other | 1 Hit Point, Alive, ward `spent`, `DeathWardSpent` last | FR-042 | happy |
| well past 0 | 5, 0, 100, other | 1 Hit Point (no Massive Damage) | FR-042 | unhappy (boundary) |
| one short of 0 | 5, 0, 4, other | 1, ward `active` | FR-041 | unhappy (boundary) |
| temporary Hit Points absorb part | 5, 3, 8, other | temp 0, 1 Hit Point, `TemporaryHitPointsEnded`, spent | FR-042 | unhappy (rule interaction) |
| fully absorbed | 5, 10, 8, other | temp 2, 5, ward `active` | FR-041 | unhappy (rule interaction) |
| monster | 5, 0, 5, `DiesInstantly` | 1 Hit Point, Alive, spent | FR-042 | unhappy (rule interaction) |
| knock-out | 5, 0, 5, `MeleeAttackKnockOut` | `KnockedOut`, 1, ward `active` | FR-041 | unhappy (rule interaction) |
| already at 0 | Dying 0, 0, 3, other | one failure, ward `active` | FR-041 | unhappy (state error) |
| two types summed | 6, 0, 10 Fire and 8 Cold | 1, spent, one ward | FR-042 | unhappy (rule interaction) |
| Immunity | 5, 0, 5 Fire, immune | unchanged, `active` | FR-041 | unhappy (empty and minimal) |
| second drop | next `applyDamage` on `spent` | Dying | FR-044 | unhappy (rule interaction) |
| instant kill | `negateInstantKill` | status unchanged, `spent`, `DeathWardSpent` | FR-043 | happy |
| instant kill, spent | same | `GuardedDamageNotWarded` | FR-044 | unhappy (state error) |
| Dead | any | refusal | FR-044 | unhappy (state error) |
| maximum reduced to 0 | `reduceMaximum` to 0 with ward `active` | Dead (`hitPointMaximumZero`), ward `active`: not guarded | FR-044 | unhappy (rule interaction) |

### 4.9 Purity, layering and exports

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-045 | Every operation MUST return new values plus events without mutating its inputs, MUST return unmodifiable collections, MUST read no clock or randomness, and MUST give equal results for equal inputs. Operations that compose `hit-points-and-damage.md` FR-109 operations or `conditions.md` / `returning-to-life.md` operations MUST NOT call a use case (`shared-types-and-ownership.md` FR-044). | `doc/rules/architecture.md` §3, §4; `doc/rules/testing.md` §4; `shared-types-and-ownership.md` FR-044 | unhappy (immutability) |
| FR-046 | Types live in `lib/src/combat/domain/`, are pure and import only `combat`'s domain, `shared_kernel`, the barrel of `character` (`RestKind`) and the published language of the specs in the header. The events `HitPointMaximumIncreased`, `HitPointMaximumIncreaseEnded`, `HitPointMaximumRestored` and `DeathWardSpent` are the members of the one sealed `RestorationEvent implements CombatEvent` (no nested sub-family, so each event is in exactly one sealed sub-family, `combat-foundations.md` FR-016); `kind` is the snake_case of the class name, unique in the package, with `combatants == [subject]` (`combat-foundations.md` FR-015 to FR-019). | `doc/rules/architecture.md` §1, §2, §9; `shared-types-and-ownership.md` FR-019 | unhappy (forbidden edge) |
| FR-047 | Rejections are values, never exceptions: expected outcomes (`Ineligible`, `NotPresent`, `NothingToEnd`, `CreatureIsDead`, `NotWarded`) are variants of the operation's sealed result, prefixed with the operation (`shared-types-and-ownership.md` FR-017); only a violated precondition (FR-008, FR-016, FR-023, FR-024, FR-032, FR-038, FR-040) is an `ArgumentError`. No variant is named `Applied`, `Rejected` or `Succeeded` alone. | `doc/rules/architecture.md` §6; `shared-types-and-ownership.md` FR-017 | unhappy (invalid input) |
| FR-048 | The barrel and `lib/srd5e.dart` MUST export `RevivalSpell`, `RevivalSpellFacts`, `DeathCircumstances`, `BodyState`, `PoisonsAtDeath`, `RevivalIneligibility`, `ReviveBySpell`, `ReviveBySpellResult` and its variants, `ReviveOrdeal`, `CasterStrain`, `HitPointMaximumIncrease`, `HitPointMaximumIncreases`, `IncreaseMaximum`, `EndMaximumIncrease`, `RestoreMaximum` and their results, `RestorativeSpell`, `LesserRestoration`, `GreaterRestoration`, `GreaterRestorationChoice`, `RestorativeHealing`, `MassHealAllotment`, `DeathWard`, `GuardWithDeathWard` and the events of FR-046, each with a dartdoc comment. | `doc/rules/architecture.md` §4, §7 | happy |

## 5. Model

- **Referenced, not defined here:** `CombatantId`, `CombatEvent`; `HitPointStatus`, `HitPoints`, `LifeState`, `HitPointTransition`, `DamageDelivery`, `HitPointRejection`, `CreatureIsDead`; `ConditionSet`, `ConditionKind`, `remove`, `reduceExhaustion`; `OngoingEffects`, `OngoingEffectId`, `EffectSource`, `CurseRemoval`, `CurseRemovalMeans`; `Revival.revive`, `ReviveCreatureResult`, `RevivalConsent`; `RestKind`; `RollResult`; `Modifier`, `RollCircumstance`; `SpellId`.
- **Value objects:** `RevivalSpellFacts`, `DeathCircumstances`, `PoisonsAtDeath`, `ReviveOrdeal`, `CasterStrain`, `HitPointMaximumIncrease`, `HitPointMaximumIncreases`, `MassHealAllotment`, `DeathWard`, and the choice and command types of section 3. **Events:** sealed `RestorationEvent` (FR-046). **Domain services** (stateless): `ReviveBySpell`, `IncreaseMaximum`, `EndMaximumIncrease`, `RestoreMaximum`, `LesserRestoration`, `GreaterRestoration`, `RestorativeHealing`, `GuardWithDeathWard`.
- **Invariants:** ordeal 0 to 4 and amounts at least 1 (constructors); a ledger has distinct ids; `DeathCircumstances` non-negative time.
- **Failures:** sealed `<Operation>Result` with operation-prefixed variants; `ArgumentError` for preconditions; no `Srd5eException` (no port).

## 6. Interface

- Synchronous pure functions over host-held values; no use case, port, adapter or double in this spec. A use case per operation (`revive_by_spell`, `guard_with_death_ward` and so on) is a later amendment of `combat-action-resolution.md` (RR-2); until then hosts call the domain operations, which stay the single implementation (`shared-types-and-ownership.md` FR-044).
- The host holds: one `ReviveOrdeal` per revived creature and one `CasterStrain` per caster, both aged by `afterRest(RestApplied.benefitsOf)` and read by `RollModifiers` / `RollMode.resolve` and by the cast check; one `HitPointMaximumIncreases` per creature; one `DeathWard` per warded creature. It ends Aid, Heroes' Feast and Death Ward at the end of their durations (`EndMaximumIncrease`, or discarding the ward).
- Barrel: exported from `lib/src/combat/combat.dart` and `lib/srd5e.dart`; the handoff types are the results and ordeal / strain values. No test doubles.

## 7. Observability

Silent by design (`doc/rules/observability.md` §3): pure domain code with no port, no I/O and no use case; no signal of its own and no `doc/observability/signals.md` entry. When the use cases of RR-2 land they record through `CombatTelemetry` (`combat-foundations.md` FR-029 to FR-035) with one `srd5e.combat.result` value per variant (for example `revived`, `ineligible`, `refused`, `increased`, `ended`, `warded`, `not_warded`; `Ineligible`, `NotPresent`, `NothingToEnd` and `CreatureIsDead` are `refused`, never errors).

Seven questions: (1) a host passes an impossible death circumstance or a stale ward (`Ineligible`, `NotWarded`). (2) By `srd5e.combat.operations` once the use cases land; nothing before. (3) Results and events carry the reasons and amounts. (4) Each call by result. (5) Existing instrumentation is unchanged. (6) A sustained rise in `ineligible` with `timeWindowExceeded` is a host clock or table bug; repeated `CreatureIsDead` on `EndMaximumIncrease` is a host state bug (a Dead creature's ledger should be discarded). (7) Nothing is noisy: no log.

## 8. Test plan

| Id | Level | Notes |
|---|---|---|
| FR-001 | unit | Four ids and the three nulls |
| FR-002 to FR-008 | unit | Table 4.1b, one test per row (both sides of every boundary), including the multi-reason order |
| FR-009 to FR-015 | unit | Table 4.2; one test per spell and per `returning-to-life.md` variant; inputs unchanged, equal results |
| FR-016 to FR-019 | unit | Table 4.3; the ordeal modifier added to `RollModifiers` and to a Death Saving Throw total together with an Exhaustion reduction |
| FR-020 to FR-022 | unit | Table 4.4 including the 364 / 365 day pair; `afterRest` for both `RestKind` values |
| FR-023 to FR-030 | unit | Table 4.5 and the events in order; the Dying row; the maximum-0 row |
| FR-031 | unit | Table 4.6 |
| FR-032 to FR-040 | unit | Table 4.7b, one test per row; Heal at every castLevel 6 to 9 |
| FR-041 to FR-044 | unit | Table 4.8; a recording check that a refused call spends nothing |
| FR-045 | unit | Immutability and determinism across every operation |
| FR-046 to FR-048 | architecture | Import direction; `kind` unique in the barrel scan; no generic variant names; export list |
| FR-046, FR-030 | unit | Cites `test/combat/event_family_checks.dart` (`combat-foundations.md` FR-018, FR-021) for `RestorationEvent` and every result type: `kind` constant and unique, `combatants == [subject]`, unmodifiable `combatants` and `events` lists, each event in exactly one sealed family |
| FR-049 | unit | Table 4.2 `restoredMaximum` rows |

Rows added by review are in tables 4.2, 4.5, 4.7b and 4.8 (duplicate and Dead precedence, Stable, Temporary Hit Points, implied-by, item-sourced curse, Heal at 10, Dead for the Heal family, negative allotment, unguarded maximum reduction).

No doubles or contract suites; the dice are a `RollResult` built in the test (FR-024). Mutation testing (`doc/rules/testing.md` §8): all changed `domain/` lines; boundary rows exist for every inclusive limit (FR-002, FR-020, FR-016, FR-040).

## 9. Open questions and decisions

None escalated. Each is settled by SRD text (cited) or package design; "interpretation" marks a reading the SRD does not state, and the web research found community rulings agreeing with Q-8 and Q-9 (not used as a source).

Settled, one line each: Q-1 the four revival texts differ on old age and Undead, and the package follows each text literally (Table 4.1a): no old-age rule for Raise Dead, no Undead rule for Revivify, a GM adds either by choosing not to cast or by an ineligible `DeathCircumstances` fact (SRD 5.2.1, pp. 157, 159, 170). Q-2 "within the last minute", "no longer than", "no more than" and "or longer" are read inclusive; a year is 365 days because Resurrection itself counts 365 days for its strain and the SRD defines no calendar (interpretation, p. 159). Q-3 only Raise Dead states a failure for missing integral parts; the others state no failure, and so Revivify with `missingIntegralParts` is eligible by design and a GM who rules otherwise has the host report `noBody` (FR-005; interpretation: faithful to the text, a GM may rule more strictly). Q-4 eligibility is checked before the spirit's consent because a spell that cannot work is never completed (p. 180: "When such a spell is cast"; interpretation). Q-5 strain follows the cast, so it applies when the revival succeeds or the spirit refuses and not when the cast was ineligible or the creature was not Dead (interpretation of "Casting this spell to revive a creature", p. 159). Q-6 the ordeal is a flat -4 that restarts, not a stack: the text sets "a -4 penalty" and counts a Long Rest at a time, so a second revival restarts at 4 (p. 157). Q-7 "can't cast spells" covers cantrips because cantrips are spells (SRD 5.2.1 "Cantrip", p. 178 treats them as spells that need no slot; p. 159). Q-8 Aid adds 5 per level above 2 to its base 5; Mass Heal's "creatures healed" excludes an allotment of 0; both are the reasonable readings of p. 107 and p. 147. Q-9 a current Hit Point increase from 0 is regaining Hit Points because the status type forbids Dying above 0 (`hit-points-and-damage.md` FR-089), and an ending increase lowers current Hit Points only down to the new maximum, as p. 183 ("can't have more Hit Points than your Hit Point maximum") requires. The ending drop and an earlier reduction are independent subtractions from the maximum, clamped at 0, so a maximum of 4 losing an Aid of 5 reaches 0 and the creature dies (interpretation of "Hit Point Maximum of 0", p. 17, and "Hit Points", p. 183; the SRD states no order). Q-10 the package does not classify "instantly kill without dealing damage" effects, track ability score reductions, restore a maximum by itself for a creature that died of a maximum of 0 (`RestoreMaximum` rejects Dead, `hit-points-and-damage.md` FR-075; the host passes `restoredMaximum` to `ReviveBySpell`, FR-049, when its GM rules the spell restores one) or bypass Dead for Heal-type spells, and Death Ward guards `applyDamage` only (FR-044): each is the host's or the GM's call, and Death Ward's drop-to-1 is built from the knock-out rule so Massive Damage never applies (p. 122, p. 17).

## 10. Changelog impact

- **Added:** revival spell rules (eligibility, outcome, ordeal, caster strain), Hit Point maximum increases (Aid, Heroes' Feast), maximum restoration, condition and effect removal for the restoration spells, and Death Ward in `combat` (`doc/specs/revival-and-restoration-spells.md`).
- **BREAKING:** no. Everything is new.
