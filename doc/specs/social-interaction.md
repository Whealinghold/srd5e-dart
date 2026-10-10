# Social interaction

| | |
|---|---|
| Status | draft |
| Context | `character` |
| Roadmap phase | 3 |
| Depends on | `d20-tests.md`, `resolve-d20-test-use-case.md`, `modifiers-and-advantage.md`, `dice-and-rolls.md`, `ability-scores.md`, `content-schema-and-decoder.md`, `observability-ports.md`, `errors-and-results.md` |

Notes. `resolve-d20-test-use-case.md` is listed only for the `D20TestSignals`
constants (its FR-040). Leaf in `character` (Q-10); names no `combat` type
(`shared-types-and-ownership.md` FR-013). Phases: `d20_test` types 1, `content`
vocabulary 2 (`shared-types-and-ownership.md` FR-014).

## 1. Purpose and scope

Social interaction as the SRD states it as rules: a monster's **attitude**
(Friendly, Indifferent, Hostile), the **Influence action**, and how an Influence
attempt resolves. The GM first decides whether the monster is Willing,
Unwilling or Hesitant. Only a Hesitant monster needs an ability check, resolved
by the `d20_test` domain service, with the attitude contributing Advantage or
Disadvantage, against a default DC of 15 or the monster's Intelligence score,
whichever is higher. A failed check starts a wait before the same urging may be
tried again.

The slice is a small pure domain plus one use case, `ResolveInfluence`, which
rolls the d20s through the `DiceRoller` port and hands them to the pure
`D20TestResolver` (`shared-types-and-ownership.md` FR-044). It adds no dice
logic or outcome rule and never calls `ResolveD20Test`.

**Ownership** (`shared-types-and-ownership.md` FR-048). This spec owns
`Attitude` (`rules-glossary-coverage.md` GL-013, GL-069, GL-082, GL-088) and the
resolution of the Influence action's effect. **Supersedes:** nothing; the
`initiative-and-actions.md` and `combat-action-resolution.md` entries only list
and spend the action, and `conditions.md` FR-054 owns the Charmed Advantage.

**Out of scope:**

- **Roleplaying and deciding Willing, Unwilling or Hesitant.** "The GM uses an
  NPC's personality ... to determine how an NPC reacts" (SRD 5.2.1,
  "Roleplaying", pp. 10-11) and "The GM then determines whether the monster
  feels willing, unwilling, or hesitant" (p. 184) are adjudication. The
  determination is an *input* (FR-013 to FR-015); `Alignment`
  (`content-schema-and-decoder.md` FR-137) is not used to infer it.
- **The GM choosing the check** (p. 184). The Influence Checks table only
  *suggests* (FR-008, FR-009).
- **Changing a monster's attitude.** The Actions table (p. 10) and "Ability
  Checks" (p. 11) mention altering attitude, but the Influence entry says only
  that on a success "the monster does as urged" (p. 184). The SRD gives no rule
  for moving between attitudes, so none is modelled (Q-04).
- **Tracking time and "the same way"**: host state (FR-019, FR-020; Q-05).
- **Spending the action**, a `combat` concern; the host composes the two
  (`combat-action-resolution.md` Q-23). The Help action (p. 182) is owned by
  `attack-and-help-actions.md` (FR-043); its Advantage arrives as a circumstance.
- **Item and spell effects on social checks**, caller-supplied circumstances or
  modifiers: Charmed ("Charmed", p. 178), Perfume (Advantage on Charisma
  (Persuasion) checks to influence an Indifferent Humanoid within 5 feet, p. 99),
  Speak with Animals (p. 164).
- **Skill modifiers**, built by `derived-stats.md`; the caller passes `Modifier`s.
- **Influence on a player character.** The SRD defines attitude for "a monster
  toward a player character" (p. 177) and the action for a monster only.
- **Anything not in the SRD.** No reaction table, attitude-shift table or
  social-encounter structure exists in SRD 5.2.1.

## 2. Source

- SRD 5.2.1, "Actions" table (Influence row), p. 10; "Social Interaction",
  "Roleplaying", "Ability Checks", pp. 10-11.
- Rules Glossary: "Attitude", p. 177; "Friendly [Attitude]", p. 182; "Hostile
  [Attitude]", p. 183; "Indifferent [Attitude]", "Influence [Action]" and the
  "Influence Checks" table, p. 184; "Monster" and "Nonplayer Character", p. 185.
- "Skills" table, p. 9; "D20 Tests", pp. 6-8; "Communicating", p. 13;
  "Charmed", p. 178; "Perfume", p. 99; "Speak with Animals", p. 164.
- Package rules: `doc/rules/architecture.md` §2, §3, §4, §6;
  `doc/rules/observability.md` §2 to §7; `doc/rules/testing.md` §4.

## 3. Vocabulary

| SRD term | Type | Notes |
|---|---|---|
| Attitude | `Attitude` (enum plus static `Attitude.monsterDefault`, in `character` `domain/`) | "A monster has a starting attitude toward a player character: Friendly, Hostile, or Indifferent" (p. 177). Static fact only; behaviour is `InfluenceRules.attitudeCircumstances` (Q-01). |
| Influence [Action] | use case `ResolveInfluence` | Resolves the effect only; the action is a `combat` concern. |
| Willing, Unwilling, Hesitant | variants of sealed `InfluenceCommand` | The GM's determination (p. 184); input, never inferred. |
| Influence Checks table row | `InfluenceApproach` (`deceive`, `intimidate`, `amuse`, `persuade`, `coax`) | Deceiving or Persuading a monster that understands you; Intimidating; Amusing; Gently coaxing a Beast or Monstrosity (p. 184). |
| "a monster that understands you" | `InfluenceComprehension` (`understands`, `doesNotUnderstand`) | Named state, not a boolean (`architecture.md` §3). |
| the monster | `InfluenceTarget` (value object) | Attitude, Intelligence score, creature type, comprehension. A monster is "a creature controlled by the GM" and an NPC "is a monster that has a personal name and a distinct personality" (p. 185), so one type serves both (Q-06). |
| caller's modifiers and circumstances | sealed `InfluenceAttempt` (`InfluenceRoll`, `InfluenceAutomaticFailure`) | Package term (FR-017, FR-028, FR-041). |

The model uses `monster` terms, as the rules do (Q-06). Friendly gives
Advantage (p. 182), Hostile Disadvantage (p. 183), Indifferent is "the default
attitude of a monster" (p. 184).

## 4. Requirements

Ids are stable and never renumbered. No requirement of this spec is withdrawn.

### 4.1 Attitude

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-001 | `Attitude` (owned by this spec, in `character` `domain/`) MUST enumerate exactly Friendly, Indifferent and Hostile (3 values), in that order, and expose the static fact `Attitude.monsterDefault`. It MUST carry no behaviour. | SRD 5.2.1, "Attitude", p. 177; "Social Interaction", p. 10; `shared-types-and-ownership.md` FR-006 | happy |
| FR-002 | `InfluenceTarget.attitude` MUST be optional and default to `Attitude.monsterDefault`, which MUST equal `Attitude.indifferent`. A target built without an attitude MUST yield no attitude circumstance (no Advantage or Disadvantage), the same as an explicit Indifferent one. | SRD 5.2.1, "Indifferent [Attitude]", p. 184 ("the default attitude of a monster") | happy; unhappy (empty and minimal) |
| FR-003 | `InfluenceRules.attitudeCircumstances(Attitude.friendly)` MUST return exactly one `Advantage`. | SRD 5.2.1, "Friendly [Attitude]", p. 182 | happy |
| FR-004 | `InfluenceRules.attitudeCircumstances(Attitude.hostile)` MUST return exactly one `Disadvantage`. | SRD 5.2.1, "Hostile [Attitude]", p. 183 | happy |
| FR-005 | `InfluenceRules.attitudeCircumstances(Attitude.indifferent)` MUST return an empty list: an Indifferent attitude contributes neither Advantage nor Disadvantage. | SRD 5.2.1, "Indifferent [Attitude]", p. 184 (no effect on the check is stated) | unhappy (empty and minimal) |

### 4.2 Approach and check suggestion

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-006 | `InfluenceApproach` MUST enumerate exactly the five rows of the Influence Checks table (`deceive`, `intimidate`, `amuse`, `persuade`, `coax`) and map them to the skills Deception, Intimidation, Performance, Persuasion and Animal Handling respectively. | SRD 5.2.1, "Influence Checks" table, p. 184; "Actions", Influence row, p. 10 | happy |
| FR-007 | The ability of an approach's check MUST be read from `Skill.ability` (published by `content`, `content-schema-and-decoder.md` FR-106): Charisma for `deceive`, `intimidate`, `amuse` and `persuade`; Wisdom for `coax`. This spec MUST NOT declare a second skill-to-ability mapping. | SRD 5.2.1, "Skills" table, p. 9; "Influence Checks" table, p. 184 | happy |
| FR-008 | `InfluenceRules.isSuggested(approach, target)` MUST be true exactly for the table's rows: `intimidate` and `amuse` for any target; `deceive` and `persuade` when the target `understands`; `coax` when the target's creature type is Beast or Monstrosity. Cases in section 4.7. | SRD 5.2.1, "Influence Checks" table, p. 184 | happy; unhappy (boundary) |
| FR-009 | The use case MUST NOT reject an approach that is not suggested for the target (for example `coax` on a Humanoid, or `persuade` on a target that `doesNotUnderstand`); it MUST resolve the check as for any other approach. | SRD 5.2.1, "Influence [Action]", p. 184 ("The Influence Checks table suggests ... The GM chooses the check") | unhappy (rule interaction) |

### 4.3 Difficulty Class

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-010 | `InfluenceRules.defaultDc(intelligence)` MUST return `DifficultyClass(15)` when the Intelligence score is 15 or lower, and `DifficultyClass(score)` when it is higher. Cases in section 4.7, including 1, 14, 15, 16 and 30. | SRD 5.2.1, "Influence [Action]", p. 184 ("a default DC equal to 15 or the monster's Intelligence score, whichever is higher") | happy; unhappy (boundary) |
| FR-011 | When the command carries a GM-set `DifficultyClass`, that `DifficultyClass` MUST be the check's target instead of the default; the default is only a default. | SRD 5.2.1, "Influence [Action]", p. 184 ("has a default DC") | happy |
| FR-012 | The result of a check MUST record how its DC was chosen as `DcBasis` (`defaultRule` or `gmSet`), together with the `DifficultyClass` used, so a consumer can explain it. | `doc/rules/architecture.md` §6 (results carry what explains them); SRD 5.2.1, p. 184 | happy |

### 4.4 Resolution

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-013 | An `InfluenceWillingCommand` MUST return `ResolveInfluenceFulfilled` without any request to the `DiceRoller` and without calling `D20TestResolver`. | SRD 5.2.1, "Influence [Action]", "Willing", p. 184 ("no ability check is necessary; the monster fulfills your request") | happy |
| FR-014 | An `InfluenceUnwillingCommand` MUST return `ResolveInfluenceRefused` without any request to the `DiceRoller` and without calling `D20TestResolver`. | SRD 5.2.1, "Influence [Action]", "Unwilling", p. 184 ("no ability check is necessary; it doesn't comply") | happy |
| FR-015 | An `InfluenceHesitantCommand` whose attempt is an `InfluenceRoll` MUST make exactly one ability check: it MUST make exactly one request to the `DiceRoller` through `rollChecked` for `DiceExpression(mode.diceCount, Die.d20)` with modifier 0 (a single `1d20` for `RollMode.normal`, a single `2d20` for `advantage` or `disadvantage`), build the `D20Roll` from the mode and the faces in order, and obtain the result from `D20TestResolver.resolveCheck(D20TestKind.abilityCheck, roll, modifiers, dc)`, with the `DifficultyClass` of FR-010 or FR-011 and the `RollModifiers` of FR-017. It MUST NOT compute any total, outcome or kept die itself. | SRD 5.2.1, "Influence [Action]", "Hesitant", p. 184 ("you must make an ability check"); "D20 Tests", p. 6; `d20-tests.md` FR-010, FR-069; `shared-types-and-ownership.md` FR-044 | happy |
| FR-016 | For a rolled attempt, the roll mode MUST be `RollMode.resolve` called once over the attitude's circumstances (FR-003 to FR-005) followed by the `InfluenceRoll`'s circumstances, unchanged and in order. This spec implements no stacking or cancelling. Cases in section 4.7. | SRD 5.2.1, "Friendly", p. 182; "Hostile", p. 183; "Advantage/Disadvantage", p. 7; "They Don't Stack", p. 8; `modifiers-and-advantage.md` FR-010 to FR-017 | unhappy (rule interaction) |
| FR-017 | The `RollModifiers` MUST be built from the `InfluenceRoll` unchanged: the ability modifier chosen by FR-041 for the approach's ability, the optional Proficiency Bonus and the other `Modifier`s in order. With only the ability modifier (no Proficiency Bonus, no other modifiers) the total MUST equal the natural d20 used plus that ability modifier; there is no bare-modifier-list form (`shared-types-and-ownership.md` FR-003). | SRD 5.2.1, "D20 Tests", "Add Modifiers", p. 6; `d20-tests.md` FR-016, FR-017 | unhappy (empty and minimal) |
| FR-018 | A check whose outcome is `D20TestOutcome.success` MUST return `ResolveInfluenceCheckSucceeded`, carrying the `CheckResult`; a total equal to the DC succeeds, and the result carries no retry wait. | SRD 5.2.1, "Influence [Action]", p. 184 ("On a successful check, the monster does as urged"); "Compare the Total to a Target Number", p. 6 | happy; unhappy (boundary) at equal |
| FR-019 | A check whose outcome is `failure` MUST return `ResolveInfluenceCheckFailed`, carrying the `CheckResult` and a `retryAfter` of 24 hours when no GM duration is given; a total one below the DC fails. | SRD 5.2.1, "Influence [Action]", p. 184 ("you must wait 24 hours (or a duration set by the GM) before urging it in the same way again") | happy; unhappy (boundary) at one below |
| FR-020 | When the command carries a GM-set wait, `retryAfter` on a failed check MUST equal it. A wait of `Duration.zero` is accepted. | SRD 5.2.1, "Influence [Action]", p. 184 ("or a duration set by the GM") | unhappy (boundary) |
| FR-021 | An `InfluenceHesitantCommand` built with a negative GM-set wait MUST throw `ArgumentError`. | Package design (not an SRD rule): `doc/rules/architecture.md` §6; `doc/rules/testing.md` §4 (invalid input) | unhappy (invalid input) |
| FR-022 | A command whose attempt is `InfluenceAutomaticFailure` MUST obtain its result from `D20TestResolver.forcedFailure(D20TestKind.abilityCheck, ForcedFailureReason.automatic)`, MUST make no request to the `DiceRoller`, MUST return `ResolveInfluenceCheckForcedFailure` carrying the `ForcedFailureResult` and the same `retryAfter` as FR-019, and the attitude's circumstances MUST NOT be applied. The caller decides when a check cannot succeed (for example one that requires sight or hearing while Blinded or Deafened). | SRD 5.2.1, "Blinded", p. 177; "Deafened", p. 181; `d20-tests.md` FR-036 | unhappy (rule interaction) |
| FR-023 | Natural 20 and natural 1 MUST NOT change the outcome: the check resolves by total against the DC alone (a natural 20 whose total is below the DC fails; a natural 1 whose total reaches the DC succeeds). | SRD 5.2.1, "Rolling 20 or 1", p. 7 ("for an attack roll"); `d20-tests.md` FR-031 | unhappy (boundary) |
| FR-024 | `ResolveInfluenceFulfilled` and `ResolveInfluenceRefused` MUST carry no fields; they are distinguished by type alone. No result variant has an attitude-change field (structural; Q-04). | `doc/rules/architecture.md` §6; SRD 5.2.1, p. 184 (no attitude change is stated) | happy |

### 4.5 Failures, determinism and immutability

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-025 | When the `DiceRoller` throws a typed `Srd5eException` (`DiceRollerException` with reason `unavailable`, or `invalidResult` from `rollChecked`), `ResolveInfluence` MUST propagate the same instance, MUST NOT request dice again and MUST return no result. | `doc/rules/architecture.md` §4 (port failure contract); `dice-and-rolls.md` FR-051, FR-052 | unhappy (failure of collaborator) |
| FR-026 | When the roller lets an `Error` escape (a `StateError` from a drained `FixedDiceRoller`), `ResolveInfluence` MUST let it propagate unchanged. | `doc/rules/architecture.md` §6 ("Never catch `Error`"); `dice-and-rolls.md` FR-053 | unhappy (failure of collaborator) |
| FR-027 | For equal commands and equal d20 values, `ResolveInfluence` MUST return equal results, including at the extremes (all 1s, all 20s) for each of the three attitudes. | `doc/rules/architecture.md` §3 (purity); `doc/rules/testing.md` §4 (determinism) | unhappy (determinism) |
| FR-028 | `InfluenceRoll` MUST hold its other `Modifier`s, its circumstances and its ability-modifier map as unmodifiable copies (mutating the caller's collection afterwards MUST NOT change the value; mutating the held collection MUST throw `UnsupportedError`), and `ResolveInfluence` MUST NOT alter its command. | `doc/rules/testing.md` §4 (immutability); `doc/rules/architecture.md` §4 (handoffs) | unhappy (immutability) |
| FR-029 | `InfluenceTarget`, the three commands and every result variant MUST be equal with equal hash codes when every field is equal, and unequal when any single field differs (including collection contents and order). | `doc/rules/architecture.md` §3 (value objects) | happy; unhappy (any differing field) |
| FR-030 | `InfluenceTarget` MUST take its Intelligence score as an `AbilityScore`; this spec adds no range check of its own and relies on the kernel's (`ability-scores.md` FR-002). | `ability-scores.md` FR-002 | unhappy (boundary) |

### 4.6 Telemetry and structure

This use case is the outermost one for every call: it records its own signals,
including its own error count, from the domain results
(`shared-types-and-ownership.md` FR-044; `doc/rules/observability.md` §7).

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-031 | Each call MUST run inside one span `srd5e.character.resolve_influence`, opened through the `Tracer` port, with no child spans. For a hesitant command it MUST set `srd5e.influence.approach` and `srd5e.influence.attitude` at start, and `srd5e.influence.response`, `srd5e.outcome` and (FR-043) `srd5e.d20_test.roll_mode` when a d20 was rolled (a forced failure has none). A failed check or a refusal MUST NOT set error status. | `doc/rules/observability.md` §6 | happy; unhappy (normal rule outcome is not an error) |
| FR-032 | Each completed call MUST increment `srd5e.character.influence_resolved` once, with `srd5e.influence.response` and `srd5e.outcome` always, and `srd5e.influence.approach`, `srd5e.influence.attitude` for hesitant commands only, and `srd5e.d20_test.roll_mode` only for rolled hesitant attempts (FR-043). | `doc/rules/observability.md` §5 | happy |
| FR-033 | Each call, completing or throwing, MUST record its duration in seconds in `srd5e.character.influence_duration` exactly once through `Meter.time`, with no attribute, and `Meter.time` MUST run inside the `Tracer.trace` body. The use case MUST NOT read a clock. | `doc/rules/observability.md` §4, §5 | happy; unhappy (failure of collaborator) |
| FR-034 | When a typed `Srd5eException` leaves the use case (from the `DiceRoller`), it MUST be recorded exactly once, here, because this use case is the outermost one: span error status with the exception recorded on the span, and `srd5e.character.influence_errors` incremented once with `error.type` equal to the exception's `errorType` (`AttributeKeys.errorType`). It MUST NOT be logged, `influence_resolved` MUST NOT increment, and `influence_duration` is still recorded (FR-033). A thrown `Error` MUST be recorded on the span only (no counter). A returned failure result carries no `error.type`, and none of the four results is an error. | `doc/rules/observability.md` §7 ("Errors: who records what"); `shared-types-and-ownership.md` FR-044, FR-051; `errors-and-results.md` FR-005, FR-043 | unhappy (failure of collaborator, telemetry on failure) |
| FR-035 | Every attribute value MUST come from a closed set through a fixed mapping: `srd5e.influence.response` (`fulfilled`, `refused`, `check_succeeded`, `check_failed`); `srd5e.outcome` (`success` for `ResolveInfluenceFulfilled` and `ResolveInfluenceCheckSucceeded`, `failure` for `ResolveInfluenceRefused`, `ResolveInfluenceCheckFailed` and `ResolveInfluenceCheckForcedFailure`); `srd5e.influence.approach` (`deceive`, `intimidate`, `amuse`, `persuade`, `coax`); `srd5e.influence.attitude` (`friendly`, `indifferent`, `hostile`); `srd5e.d20_test.roll_mode` (`normal`, `advantage`, `disadvantage`); `error.type` (FR-034). Both failed-check variants map to response `check_failed`. Attributes MUST NOT carry ids, scores, DCs, totals or free text. | `doc/rules/observability.md` §5 (attributes); `shared-types-and-ownership.md` FR-041 | unhappy (boundary) |
| FR-036 | Results, the dice requested and the exception type thrown for a failing roller MUST be identical with `Observability.none` and with a recording one. | `doc/rules/observability.md` §9 | unhappy (determinism) |
| FR-037 | Signal and attribute-key names MUST be defined once as constants in `InfluenceSignals` (shared keys `srd5e.outcome` and `error.type` via `AttributeKeys`; the key `srd5e.d20_test.roll_mode` is read from `D20TestSignals`, which `resolve-d20-test-use-case.md` FR-040 and FR-042 export, not redefined), MUST NOT appear as literals at call sites, and MUST be pinned by tests that assert their literal values. | `doc/rules/observability.md` §5, §9, §10 | unhappy (boundary: contract pinning) |
| FR-038 | The `character` domain files of this spec MUST import only `shared_kernel`, the published language of `content` (`Skill`, `CreatureType`) and the published language of `d20_test` (`DifficultyClass`). The application files MUST additionally import `shared_ports` (`DiceRoller`, `Observability`) and, from the `d20_test` barrel only, `D20TestResolver`, `D20Roll`, `RollModifiers`, `D20TestKind`, `D20TestOutcome`, `ForcedFailureReason`, `CheckResult`, `ForcedFailureResult`, `D20TestSignals` and `DifficultyClass` (the command and the `ResolveInfluenceCheck*` results carry it). No file MUST import `combat`, `adapters/`, or `ResolveD20Test`. | `doc/rules/architecture.md` §1, §2 (dependency rule, context map); `shared-types-and-ownership.md` FR-013, FR-044 | unhappy (forbidden edge) |
| FR-039 | The `character` barrel MUST export, each once and each with a dartdoc comment, `ResolveInfluence`, `InfluenceCommand` with `InfluenceWillingCommand`, `InfluenceUnwillingCommand` and `InfluenceHesitantCommand`, `InfluenceAttempt` with `InfluenceRoll` and `InfluenceAutomaticFailure`, `ResolveInfluenceResult` with `ResolveInfluenceFulfilled`, `ResolveInfluenceRefused`, `ResolveInfluenceCheckSucceeded`, `ResolveInfluenceCheckFailed` and `ResolveInfluenceCheckForcedFailure`, `Attitude`, `InfluenceApproach`, `InfluenceTarget`, `InfluenceComprehension`, `DcBasis`, `InfluenceRules` and `InfluenceSignals`; `lib/srd5e.dart` MUST re-export the same set. They MUST NOT re-export `d20_test`, kernel or `content` types. | `doc/rules/architecture.md` §2, §4, §7 | happy |

### 4.7 Cases

Default DC (FR-010). Source for every row: SRD 5.2.1, "Influence [Action]", p. 184.

| Label | Intelligence score | Default `DifficultyClass` | Path |
|---|---|---|---|
| lowest score | 1 | 15 | unhappy (boundary) |
| below the floor | 14 | 15 | unhappy (boundary) |
| at the floor | 15 | 15 | unhappy (boundary) |
| one above the floor | 16 | 16 | unhappy (boundary) |
| typical high | 20 | 20 | happy |
| highest score | 30 | 30 | unhappy (boundary) |

Approach suggested for the target (FR-008). Source: p. 184, "Influence Checks".

| Label | Approach | Comprehension | Creature type | `isSuggested` | Path |
|---|---|---|---|---|---|
| intimidate, any target | `intimidate` | `doesNotUnderstand` | Aberration | true | unhappy (boundary) |
| amuse, any target | `amuse` | `doesNotUnderstand` | Beast | true | happy |
| deceive, understands | `deceive` | `understands` | Humanoid | true | happy |
| deceive, does not understand | `deceive` | `doesNotUnderstand` | Humanoid | false | unhappy (boundary) |
| persuade, understands | `persuade` | `understands` | Giant | true | happy |
| persuade, does not understand | `persuade` | `doesNotUnderstand` | Giant | false | unhappy (boundary) |
| coax a Beast | `coax` | `doesNotUnderstand` | Beast | true | happy |
| coax a Monstrosity | `coax` | `understands` | Monstrosity | true | happy |
| coax a Humanoid | `coax` | `understands` | Humanoid | false | unhappy (boundary) |
| coax an Ooze | `coax` | `doesNotUnderstand` | Ooze | false | unhappy (boundary) |

Roll mode of a hesitant check (FR-016), from the attitude's circumstance and the caller's. The mode is the existing `RollMode.resolve` over both lists.

| Label | Attitude | Caller's circumstances | Expected `RollMode` | Dice requested | Source | Path |
|---|---|---|---|---|---|---|
| Friendly alone | friendly | none | advantage | 2d20 | p. 182 | happy |
| Indifferent alone | indifferent | none | normal | 1d20 | p. 184 | unhappy (empty and minimal) |
| Hostile alone | hostile | none | disadvantage | 2d20 | p. 183 | happy |
| Friendly, caller adds Advantage | friendly | Advantage | advantage (no stacking) | 2d20 | p. 8 | unhappy (rule interaction) |
| Friendly, caller adds Disadvantage | friendly | Disadvantage | normal (cancel) | 1d20 | p. 8 | unhappy (rule interaction) |
| Hostile, caller adds Advantage (the charmer, Charmed, p. 178) | hostile | Advantage | normal (cancel) | 1d20 | pp. 8, 178, 183 | unhappy (rule interaction) |
| Indifferent, caller adds Advantage (Perfume, p. 99) | indifferent | Advantage | advantage | 2d20 | pp. 7-8 | happy |
| Hostile, caller adds two Advantages | hostile | Advantage, Advantage | normal (cancel) | 1d20 | p. 8 | unhappy (rule interaction) |

Resolution (FR-018, FR-019, FR-020, FR-023). Fixed rolls through `FixedDiceRoller`; Intelligence 10 (default DC 15), no GM-set `DifficultyClass`.

| Label | Attitude | d20 served | Modifier | Used d20 | Total | Result | `retryAfter` | Source | Path |
|---|---|---|---|---|---|---|---|---|---|
| total equals DC | indifferent | 12 | +3 | 12 | 15 | `ResolveInfluenceCheckSucceeded` | none | pp. 6, 184 | unhappy (boundary) |
| total one below | indifferent | 11 | +3 | 11 | 14 | `ResolveInfluenceCheckFailed` | 24 hours | pp. 6, 184 | unhappy (boundary) |
| natural 20, total below DC | indifferent | 20 | -10 | 20 | 10 | `ResolveInfluenceCheckFailed` | 24 hours | pp. 7, 184 | unhappy (boundary) |
| natural 1, total reaches DC | indifferent | 1 | +17 | 1 | 18 | `ResolveInfluenceCheckSucceeded` | none | pp. 7, 184 | unhappy (boundary) |
| Friendly, higher die kept | friendly | 4, 16 | +3 | 16 | 19 | `ResolveInfluenceCheckSucceeded` | none | pp. 8, 182 | happy |
| Hostile, lower die kept | hostile | 16, 4 | +3 | 4 | 7 | `ResolveInfluenceCheckFailed` | 24 hours | pp. 8, 183 | happy |
| GM-set wait of 1 hour | indifferent | 2 | +3 | 2 | 5 | `ResolveInfluenceCheckFailed` | 1 hour | p. 184 | happy |
| GM-set wait of zero | indifferent | 2 | +3 | 2 | 5 | `ResolveInfluenceCheckFailed` | `Duration.zero` | p. 184 | unhappy (boundary) |
| automatic failure | any | none served | n/a | none | n/a | `ResolveInfluenceCheckForcedFailure` | 24 hours | pp. 177, 184 | unhappy (rule interaction) |


"Modifier" is the total: the ability modifier is +3 (caller-supplied); where
the total differs, a second `Modifier` carries the difference (-13 and +14 in
the natural-roll rows), because `RollModifiers` always holds an ability modifier
(FR-017).

### 4.8 Added requirements

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-040 | `ResolveInfluenceCheckSucceeded`, `ResolveInfluenceCheckFailed` and `ResolveInfluenceCheckForcedFailure` MUST each carry the `InfluenceApproach`, the `Attitude` the urging was made against, the `DifficultyClass` and the `DcBasis`. The first two carry the `CheckResult` of the rolled check as `check`; the third carries the `ForcedFailureResult` as `check` (FR-022). The two failure variants additionally carry `retryAfter`. | `doc/rules/architecture.md` §3 (illegal states unrepresentable) and §6 (results carry what explains them); SRD 5.2.1, p. 184 | happy |
| FR-041 | The ability modifier in the check's `RollModifiers` MUST be the one for the approach's ability (FR-007). `InfluenceRoll` carries its ability modifiers as a map from `Ability` to `Modifier`; the use case reads the entry for `approach.skill.ability`. `InfluenceHesitantCommand` MUST throw `ArgumentError` when its `InfluenceRoll` has no entry for the approach's ability. Entries for other abilities are ignored. Trade-off: Q-13. | SRD 5.2.1, "Influence Checks" table, p. 184; "Skills" table, p. 9 | unhappy (invalid input; rule interaction) |
| FR-042 | `InfluenceApproach` MUST NOT hold an ability field or switch of its own: its ability getter MUST delegate to `Skill.ability`. | SRD 5.2.1, "Skills" table, p. 9; `shared-types-and-ownership.md` FR-006 | happy |
| FR-043 | For a rolled attempt, `srd5e.d20_test.roll_mode` MUST equal the `D20Roll.mode` inside the `CheckResult`; for `ResolveInfluenceCheckForcedFailure` (no d20 rolled) and for fulfilled and refused calls it MUST be absent, as in `resolve-d20-test-use-case.md` FR-029 and `attacks.md` FR-118. | `shared-types-and-ownership.md` FR-041 | happy; unhappy (boundary: attribute presence) |
| FR-044 | `ResolveInfluence` MUST NOT call, construct, hold or mention another use case (in particular `ResolveD20Test`). It composes the `D20TestResolver` domain service, which it holds as a `const` default constructor argument so a test can pass the same value. | `shared-types-and-ownership.md` FR-044; `architecture-guardrails.md` FR-097 | unhappy (forbidden edge) |
| FR-045 | The use case MUST emit no log event at any level, on success or on failure. | `doc/rules/observability.md` §7 ("Do not log what the result already says"); `shared-types-and-ownership.md` FR-043 (same convention) | happy |


## 5. Model

Layout (`doc/rules/architecture.md` §2): `lib/src/character/domain/` holds
`Attitude`, `InfluenceComprehension`, `InfluenceApproach`, `InfluenceTarget`,
`DcBasis` and the stateless `InfluenceRules`; `application/` holds
`ResolveInfluence`, the commands, `InfluenceAttempt` and variants, the results
and `InfluenceSignals`. Types and rules are as section 3 and section 4 state;
the shapes not given there:

- `InfluenceTarget({Attitude attitude = Attitude.monsterDefault, required
  AbilityScore intelligence, required CreatureType creatureType, required
  InfluenceComprehension comprehension})` (FR-002): a plain value, no monster
  entity (Q-06).
- `InfluenceRules` (stateless): `attitudeCircumstances(Attitude)` returning
  `List<RollCircumstance>`; `isSuggested(InfluenceApproach, InfluenceTarget)`;
  `defaultDc(AbilityScore)` returning `DifficultyClass`.
- Sealed `InfluenceCommand`: `InfluenceWillingCommand()`,
  `InfluenceUnwillingCommand()` (no fields) and `InfluenceHesitantCommand(approach,
  target, attempt: InfluenceAttempt, {DifficultyClass? gmDc, Duration?
  gmRetryAfter})`, which validates FR-021 and FR-041. The GM's determination
  chooses the variant, so a check cannot be requested for a Willing or Unwilling
  monster.
- Sealed `InfluenceAttempt`: `InfluenceRoll(abilityModifiers: Map<Ability,
  Modifier>, proficiencyBonus: Modifier?, otherModifiers: List<Modifier>,
  circumstances: List<RollCircumstance>)` and `InfluenceAutomaticFailure()`.
- Sealed `ResolveInfluenceResult` (variant prefix per
  `shared-types-and-ownership.md` FR-017): the five variants of FR-039, fields
  per FR-024 and FR-040. No domain events: nothing persists.
- `InfluenceApproach` holds its `Skill` as `skill` (FR-006); its `ability`
  getter delegates to `skill.ability` (FR-042).
- Result constructors: `ResolveInfluenceCheckSucceeded(approach, attitude, dc,
  dcBasis, check: CheckResult)`; `ResolveInfluenceCheckFailed(approach, attitude,
  dc, dcBasis, check: CheckResult, retryAfter: Duration)`;
  `ResolveInfluenceCheckForcedFailure(approach, attitude, dc, dcBasis, check:
  ForcedFailureResult, retryAfter: Duration)`.
- Failures: results are never exceptions. `DiceRollerException` propagates
  (FR-025, FR-034); `ArgumentError` for FR-021, FR-041 and the kernel range check
  (FR-030). No untrusted-input factory: values come from callers.

## 6. Interface

- **Use case:** `ResolveInfluence`, synchronous `call(InfluenceCommand)` returning
  `ResolveInfluenceResult` (`doc/rules/architecture.md` §4). Constructor
  `ResolveInfluence(DiceRoller diceRoller, {D20TestResolver resolver = const
  D20TestResolver(), Observability observability = Observability.none})`.
  `character` may use the `d20_test` barrel (context map). The rules live in
  `InfluenceRules` and `d20_test`; the flow is FR-013 to FR-023.
- **Ports and doubles:** `DiceRoller` and the observability ports; no new port,
  double or contract suite. Tests use `FixedDiceRoller`, `CallbackDiceRoller`
  and `RecordingObservability` from `lib/testing.dart`
  (`shared-types-and-ownership.md` FR-038). Port failures: FR-025, FR-026.
  Exports: FR-039.

## 7. Observability

The use case is instrumented, the domain is silent (`doc/rules/observability.md`
§3). The four signals below are owned here; shared keys are cited in FR-037.

Evaluation: a failing dice source or a thrown `Error` is the only failure; a
refusal or failed check is a normal outcome. Operators see span error status and
`influence_errors` with `error.type`, counted once here (outermost use case);
the result carries approach, attitude, DC, basis and full check, so signals hold
only the low-cardinality summary. Nothing is double counted: no `ResolveD20Test`
call, so no `srd5e.d20_test.*` signal fires (`shared-types-and-ownership.md`
FR-044). Consumers monitor error-status spans, `influence_errors`, latency, and a
Friendly `check_succeeded` share not above the Indifferent one (or a Hostile share far above it). Counted: calls and outcomes, errors; timed: duration, also on failure. A negative GM wait is a programmer error raised at construction, before any signal. No log is emitted
(FR-045).

| Signal | Type | Attributes | Purpose | Suggested monitoring |
|---|---|---|---|---|
| `srd5e.character.resolve_influence` | span | `srd5e.influence.approach`, `srd5e.influence.attitude` (hesitant only, at start); `srd5e.influence.response`, `srd5e.outcome`, `srd5e.d20_test.roll_mode` (only when a d20 was rolled) | See one Influence resolution; error status when the dice source fails | Alert when the error-status span rate stays above 0 for 5 minutes |
| `srd5e.character.influence_resolved` | counter, unit `{influence}` | `srd5e.influence.response` (`fulfilled`, `refused`, `check_succeeded`, `check_failed`), `srd5e.outcome`; `srd5e.influence.approach`, `srd5e.influence.attitude` for hesitant calls only; `srd5e.d20_test.roll_mode` for rolled attempts only | Throughput and outcome mix | Dashboard the `check_succeeded` share by attitude; investigate a Friendly share not above the Indifferent share over at least 500 hesitant calls |
| `srd5e.character.influence_errors` | counter, unit `{error}` | `error.type` | Thrown port failures, counted once | Alert on any sustained increase |
| `srd5e.character.influence_duration` | histogram, unit `s` (double) | none | Latency, dominated by the injected roller; recorded on failing calls too | Alert when p99 over 15 minutes exceeds 5 times the consumer's baseline |

These entries feed `doc/observability/signals.md`.

## 8. Test plan

| Id | Level | Notes |
|---|---|---|
| FR-001, FR-002 | unit | `Attitude.values` exactly friendly, indifferent, hostile in order; `monsterDefault` is `indifferent`; no behaviour member; a target without an attitude equals one with explicit Indifferent and its `attitudeCircumstances` is empty |
| FR-003 to FR-005 | unit | One `Advantage` for Friendly; one `Disadvantage` for Hostile; empty list for Indifferent |
| FR-006, FR-007 | unit | Table-driven: five approaches, their skills, exact count; ability equals `skill.ability` |
| FR-008 | unit | Suggestion cases table, every row |
| FR-009 | application | `coax` on a Humanoid and `persuade` without comprehension still make one check |
| FR-010 | unit | Default DC table, every row |
| FR-011, FR-012 | application | GM-set DC of 8 and 25 against Intelligence 10 and 20: target equals the GM-set DC; `DcBasis` `defaultRule` and `gmSet` on a success and a failure |
| FR-013, FR-014 | application | `FixedDiceRoller.requests` empty; result `ResolveInfluenceFulfilled` or `ResolveInfluenceRefused` |
| FR-015 | application | Real `D20TestResolver` over `FixedDiceRoller`: ability modifier per approach (Charisma and Wisdom), target `DifficultyClass`, exactly one request of `1d20` or `2d20` with modifier 0, `D20Roll` faces in served order |
| FR-016 | application + scenario | Roll mode table through `FixedDiceRoller`: assert `D20Roll.mode` and dice requested; scenario runs a Friendly and a Hostile urging through the public API |
| FR-017 | application | Ability modifier only: total is natural d20 plus modifier (`[1d20]`); ability plus Proficiency Bonus plus other modifiers `[+3, -1]` reach the total in order |
| FR-018 to FR-020, FR-023 | application | Resolution table rows: equal, one below, natural 20 below DC, natural 1 reaching DC, Friendly higher die, Hostile lower die, GM-set waits; default 24 hours |
| FR-021 | application | `-1` second throws `ArgumentError` |
| FR-022 | application | `InfluenceAutomaticFailure`: no roller request; `ResolveInfluenceCheckForcedFailure` carries a `ForcedFailureResult` with reason `automatic`; `retryAfter` 24 hours; no attitude circumstance applied |
| FR-024 | application | Both non-check variants have no fields (equal instances, no attitude-change member) |
| FR-025, FR-026 | application | `CallbackDiceRoller` throwing a typed `DiceRollerException`: same instance propagates, no result, one request recorded; drained `FixedDiceRoller` (`StateError`) propagates |
| FR-027 | application | Equal results across repeated calls with all 1s and all 20s, each attitude |
| FR-028 | application | `InfluenceRoll` copy semantics, `UnsupportedError` on mutating each held collection, command unchanged after the call |
| FR-029, FR-030 | unit | Equality and hash table, one differing field per row; scores 1 and 30 through `defaultDc` (15 and 30); the `AbilityScore` signature is compile-time, range rejection is tested in the kernel (`ability-scores.md` FR-002) |
| FR-031 to FR-033 | application | `RecordingTracer` and `RecordingMeter`: span name, one span, attributes, no error status on refusal or failed check; one counter increment with the hesitant and non-hesitant attribute sets; one duration measurement inside the span, on success and on a throwing roller, no attribute |
| FR-034 | application | Typed exception: span error status with the exception, `influence_errors` once with `error.type` `dice_roller_exception`, no log, no `influence_resolved`; `Error`: span only, no counter |
| FR-035, FR-037 | unit | Enum-to-string mapping table, every value, both failure variants mapping to `check_failed`; literal values of every constant pinned |
| FR-036 | application | `Observability.none` and a recording one give equal results, including a throwing typed exception |
| FR-038, FR-039, FR-044 | architecture | Import-direction scan (no `combat`, no `ResolveD20Test`); barrel scan (exports once, dartdoc, no upstream re-export); use-case scan (`architecture-guardrails.md` FR-097) |
| FR-040, FR-043 | application | Each check variant carries approach, attitude, `DifficultyClass`, `DcBasis`, check result type and, for a failure, `retryAfter`; `roll_mode` on span and counter equals `D20Roll.mode`, absent for forced failure, fulfilled and refused |
| FR-041, FR-042 | unit + application | Map with Charisma +4 and Wisdom -1: `coax` uses -1, `persuade` uses +4; missing ability throws `ArgumentError`; extra entries ignored; `InfluenceApproach` declares no ability member |
| FR-045 | application | `RecordingLogger` at the finest level records zero events on every row |

- **Mutation testing** (`doc/rules/testing.md` §8): required for `domain/`
  (`InfluenceRules`, `InfluenceApproach`, `InfluenceTarget`, `Attitude`);
  boundary rows (Intelligence 14, 15, 16; total equal and one below; wait of
  zero) kill comparison and constant mutants.
- **Scenario:** a Hostile Beast, a `coax` approach and Advantage from a caller,
  through `package:srd5e/srd5e.dart` only. Every FR id is covered.

## 9. Open questions and decisions

Open: none.

Decided: Q-06 a factory from a `content-monsters.md` definition to
`InfluenceTarget` is application code, added when that spec ships; the engine
exposes no such API (NPC and monster are one thing, p. 185).

Settled:

- Q-01 `Attitude` is owned here (not in `shared-types-and-ownership.md` FR-005
  or FR-046; `rules-glossary-coverage.md` GL-013, GL-069, GL-082, GL-088).
- Q-02, Q-03, Q-11, Q-12 Type names and ownership: `shared-types-and-ownership.md`
  FR-001, FR-002, FR-004, FR-005, FR-044, FR-046; `d20-tests.md` section 5.
- Q-04 No attitude change is modelled: the SRD states no rule (p. 184).
- Q-05 No memory of "the same way again": host state (`retryAfter` and approach
  are in the result). Q-07 Outermost use case, records the failure once
  (`shared-types-and-ownership.md` FR-044; FR-034). Q-10 Leaf in `character`. Sibling edits not made here: roadmap, `AGENTS.md` `character/` line, `architecture.md` §2 `character` Purpose cell (add social interaction).
- Q-08, Q-09 Charmed and the action itself are host composition
  (`combat-action-resolution.md` Q-23); no edge to `combat`
  (`shared-types-and-ownership.md` FR-013).
- Q-13 The `Map<Ability, Modifier>` with one validated constructor check
  (FR-041) is kept: one `InfluenceRoll` can be built before the approach is
  chosen and a Charisma-for-Wisdom mix-up is impossible.

## 10. Changelog impact

Under `Unreleased` / **Added**: social interaction in `character` (`Attitude`,
`ResolveInfluence`, `InfluenceApproach`, `InfluenceTarget`, `InfluenceRules`,
the Influence commands and results) and the signals
`srd5e.character.resolve_influence`, `srd5e.character.influence_resolved`,
`srd5e.character.influence_errors` and `srd5e.character.influence_duration`.
Not **BREAKING**: all additions.
