# ResolveD20Test use case

| | |
|---|---|
| Status | implemented |
| Context | `d20_test` |
| Roadmap phase | 1 |
| Depends on | `d20-tests.md`, `modifiers-and-advantage.md`, `dice-and-rolls.md`, `ability-scores.md`, `observability-ports.md`, `errors-and-results.md` |

Roadmap: [../roadmap.md](../roadmap.md); type phase 1 (shared-types-and-ownership.md FR-014). Binding
decisions: [shared-types-and-ownership.md](shared-types-and-ownership.md). `AbilityScore` and
`AbilityModifier` are not used (callers pass the finished ability modifier in `RollModifiers`; only
`Ability` is used). No dependency on `character`, `combat` or `content`
(shared-types-and-ownership.md FR-013). No use case is a dependency: `ResolveD20Test` composes
`D20TestResolver` and is never called by another use case (shared-types-and-ownership.md FR-044).

## 1. Purpose and scope

`ResolveD20Test` is the first use case of the package. It composes the pure `D20TestResolver` domain
service and is a use case **for hosts**: no other use case calls it (shared-types-and-ownership.md
FR-044; `doc/rules/architecture.md` §4). This is the **application-layer spec**: how it orchestrates
the `DiceRoller` port, handles port failure, its sealed result `ResolveD20TestResult`, and its full
telemetry contract. It is the **single authority for the `ResolveD20Test` signals**
(shared-types-and-ownership.md FR-040) and the **reference template for later use cases** (constructor
injection, error handling, result naming, telemetry shape).

Given a `D20TestCommand`, the use case resolves the roll mode from the attempt's circumstances
(FR-006), builds the roll through the `DiceRoller` port (one request, FR-007), hands the dice to
`D20TestResolver`, and returns the sealed result carrying the whole breakdown. It contains no rules
logic.

**Ownership (shared-types-and-ownership.md FR-001, FR-002, FR-017).**

| Concern | Owner |
|---|---|
| `D20Roll` (incl. reroll and replace-a-die), `RollModifiers`, `DifficultyClass`, `ArmorClass`, `D20TestKind`, `D20TestOutcome`, `CheckResult`, `AttackRollResult`, `ForcedFailureResult`, `ForcedFailureReason`, `RerollDecision` | [d20-tests.md](d20-tests.md) (decisions: `shared-types-and-ownership.md` FR-002) |
| Pure `D20TestResolver` (`resolveCheck` FR-063, `resolveAttackRoll` FR-064, `forcedFailure` FR-035, FR-036, FR-052; methods FR-069; static `resolve` members only delegate, FR-070) | [d20-tests.md](d20-tests.md) (decisions FR-002, FR-044) |
| Every rule requirement (used die, total, success/failure, natural 20/1, forced failure, one Proficiency Bonus via the shape of `RollModifiers`) | [d20-tests.md](d20-tests.md); roll-mode combination and used-die selection by [modifiers-and-advantage.md](modifiers-and-advantage.md) (`RollMode.resolve`, `RollMode.select`) |
| `RollMode`, `RollCircumstance`, `Modifier`, `Ability`, `DiceExpression`, `Die` | `shared_kernel` (decisions FR-001); this spec defines none |
| **Command and attempt types** (`D20TestCommand`, `AbilityCheckCommand`, `SavingThrowCommand`, `AttackRollCommand`, `CheckAttempt`, `SaveAttempt`, `RollAttempt`, `ChooseToFail`, `AutomaticFailure`), `ResolveD20Test`, `ResolveD20TestResult` and variants, the single `RollMode.resolve` call, dice requested, port failure handling, no-op versus recording identity, command immutability, the telemetry catalogue | this spec |
| Heroic Inspiration | Not owned, not a dependency (decisions FR-010, FR-048); reroll operations on `D20Roll` take the decision as input |

This spec states no rule twice: where a rule matters here it is a "delegated" row in 4.3.
`doc/observability/signals.md` takes the catalogue from section 7 only.

**Out of scope:**

- Deriving the ability modifier, Proficiency Bonus, proficiencies, and choosing the ability
  (SRD 5.2.1, "The Six Abilities", p. 5; "Proficiency", p. 8).
- **Proficiency Bonus stacking** ("The Bonus Doesn't Stack", p. 8): the use case sums the
  `RollModifiers` it is given; a doubled bonus cannot be constructed (decisions FR-003; d20-tests.md).
- Choosing the target number and Armor Class calculation (SRD 5.2.1, "Armor Class", p. 7).
- Deciding whether a D20 Test is warranted. Choosing to fail a saving throw (SRD 5.2.1, "Saving
  Throws", p. 7) and automatic failure are modelled by d20-tests.md (`ForcedFailureReason`); this use
  case only requests no die for them (FR-007).
- **Death Saving Throws** (SRD 5.2.1, pp. 17-18): owned by `combat`.
- Rerolls and replacing a die, including Heroic Inspiration (SRD 5.2.1, "Interactions with
  Rerolls", p. 8): operations on `D20Roll`; no use case drives them yet.
- Condition effects (Exhaustion, automatic failure, Disadvantage): applied by callers and passed as
  modifiers, circumstances or a forced failure (decisions FR-026).
- Damage and what a Critical Hit does to damage (SRD 5.2.1, "Critical Hit", p. 179).
- **Widened and automatic Critical Hits.** `isCriticalHit` means exactly "a natural 20 on the d20
  used" (p. 179). Wider ranges (Champion, "Improved Critical" and "Superior Critical", p. 49) and
  automatic Critical Hits (within 5 feet of a Paralyzed or Unconscious creature, "Paralyzed
  [Condition]", p. 186, "Unconscious [Condition]", p. 191) are applied by the caller (decisions FR-026).
- Contests and group checks: not defined as D20 Test variants in the SRD text read.
- Automatic success or failure on a natural 20 or 1 for **ordinary** checks and saves (stated for
  attack rolls, "Rolling 20 or 1", p. 7, and for Death Saving Throws, pp. 17-18). d20-tests.md pins
  the absence.

## 2. Source

PDF page numbers equal printed page numbers in SRD 5.2.1 (PDF page 6 shows printed page 6).

- "D20 Tests", p. 6 (steps cited by name: "Roll 1d20", "Add Modifiers", "Compare the Total to a Target Number"); "Ability Checks" incl. "Difficulty Class", p. 6.
- "Saving Throws", p. 7; "Attack Rolls" incl. "Armor Class" and "Rolling 20 or 1", p. 7.
- "Advantage/Disadvantage", "Roll Two D20s", "They Don't Stack", pp. 7-8; "Proficiency", "The Bonus Doesn't Stack", p. 8.
- "Death Saving Throws", pp. 17-18 (out of scope); "Fighter Subclass: Champion", p. 49 (out of scope).
- "Blinded [Condition]", p. 177; "Paralyzed [Condition]", p. 186; "Unconscious [Condition]", p. 191 (automatic failures and Critical Hits named in the case table; conditions applied by callers).
- "Rules Glossary": "Advantage", p. 176; "Armor Class", p. 177; "Attack Roll", p. 177; "Critical Hit", p. 179; "D20 Test", p. 180; "Difficulty Class", "Disadvantage", p. 181; "Ability Check", p. 176.
- Package design: `doc/rules/architecture.md` (§3, §4, §6), `doc/rules/observability.md` (§2-§9), `doc/rules/testing.md` (§3-§5, §8), shared-types-and-ownership.md. Requirements that are not SRD rules say "package design".

## 3. Vocabulary

| SRD term | Type | Notes |
|---|---|---|
| D20 Test | sealed `ResolveD20TestResult` (`ResolveD20TestRolledCheck`, `ResolveD20TestRolledAttack`, `ResolveD20TestForcedFailure`) | pp. 6, 180. Declared here (decisions FR-017); the domain values it carries are d20-tests.md's. |
| Ability Check / Saving Throw / Attack Roll | `D20TestKind` (d20-tests.md); sealed `D20TestCommand` (`AbilityCheckCommand`, `SavingThrowCommand`, `AttackRollCommand`, here) | |
| Difficulty Class / Armor Class | `DifficultyClass` / `ArmorClass` | pp. 181, 177. No union target type: each result variant carries the one it can (FR-049). |
| Modifier | `Modifier` (kernel, plain signed integer), `RollModifiers` (d20_test, structured composite) | p. 6 |
| Advantage / Disadvantage | `RollCircumstance` (`Advantage`, `Disadvantage`; modifiers-and-advantage.md FR-042), carried by `RollAttempt.circumstances` | p. 8 |
| (neither) | `RollMode.normal` (kernel enum `normal`, `advantage`, `disadvantage`) | Also the telemetry value. |
| natural 20 / natural 1 | `D20Roll.natural` | The d20 used, before modifiers (p. 7). |
| Critical Hit | `AttackRollResult.isCriticalHit` | Natural 20 on the d20 used (p. 179). |
| hit / miss | `AttackRollResult.hit` (`outcome == success`) | p. 7; no separate enum (decisions FR-004). |
| succeeds / fails | `D20TestOutcome.success`, `.failure` | One enum for every kind (decisions FR-004); this spec adds no outcome type. |

Package terms introduced here: `ResolveD20Test`, the command and attempt types, `ResolveD20TestResult`
with three operation-prefixed variants, `D20TestSignals` (FR-040). None collides with an SRD term.

## 4. Requirements

Ids are stable. A "delegated" requirement is owned by the named requirement elsewhere; its row exists
so earlier ids stay stable and the use-case-level consequence is explicit. Withdrawn ids are kept in
"Withdrawn ids" at the end of this section and never reused.

### 4.1 Command

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-001 | The command MUST be a sealed `D20TestCommand` (section 5) whose variants pair a kind with its target and attempt type: `AbilityCheckCommand(ability, target: DifficultyClass, attempt: CheckAttempt)`, `SavingThrowCommand(ability, target: DifficultyClass, attempt: SaveAttempt)`, `AttackRollCommand(ability, target: ArmorClass, attempt: RollAttempt)`. A DC cannot be paired with an attack roll, nor an AC with a check or save, and an attack roll cannot be forced to fail (d20-tests.md FR-052 rejects it in the domain too); the analyzer rejects each mismatch. `CheckAttempt` admits `RollAttempt` and `AutomaticFailure`; `SaveAttempt` admits `RollAttempt`, `ChooseToFail` and `AutomaticFailure` (a creature may choose to fail a saving throw, SRD 5.2.1, "Saving Throws", p. 7; "not a check" is package design, derived from the SRD naming only saves as optional). | SRD 5.2.1, "D20 Tests", p. 6 | happy |
| FR-002 | A minimal command (a `RollAttempt` whose `RollModifiers` holds only the mandatory ability modifier and whose `circumstances` is empty, so `RollMode.normal`) MUST resolve with one d20 requested and a total equal to the d20 used plus the ability modifier. | SRD 5.2.1, "D20 Tests", p. 6 | unhappy (empty and minimal) |
| FR-005 | A command MUST be a value object: equal inputs give equal commands and hash codes; any differing input differs. Inputs: `ability`, `target`, the attempt's type, and for a `RollAttempt` its `modifiers` and `circumstances` (compared in order; `Advantage` instances equal one another, likewise `Disadvantage`). Two `ChooseToFail` values are equal, as are two `AutomaticFailure` values. | `doc/rules/architecture.md` §3 | happy |
| FR-055 | `ability` on a command is a label for telemetry (`srd5e.ability`) and the result only. The use case does not read it to compute anything: the modifier summed is the one inside `RollModifiers`. The caller MUST keep the two consistent; the use case cannot check it, because `Modifier` has no ability tag (d20-tests.md D-06, answered here). Mechanism: a test builds a command whose `ability` and modifier disagree and asserts the total uses the modifier and the attribute uses the label. | package design; d20-tests.md D-06 | unhappy (rule interaction) |
| FR-056 | A command MUST copy its collections on construction: `RollAttempt` holds `circumstances` as an unmodifiable list and its `RollModifiers` as built (d20-tests.md copies `others`), so mutating the caller's iterable afterwards changes nothing and mutating the command's own view throws `UnsupportedError`. `RollAttempt` declares `modifiers: RollModifiers` and `circumstances: Iterable<RollCircumstance>`; `ChooseToFail` and `AutomaticFailure` carry no fields. | `doc/rules/architecture.md` §3, §4 | unhappy (immutability) |

### 4.2 Roll mode and dice requested

For a rolling attempt the use case calls the kernel's `RollMode.resolve` on `RollAttempt.circumstances`
exactly once (modifiers-and-advantage.md; they do not stack, one of each cancels) and uses that one
`RollMode` for the request (FR-007) and the `D20Roll`. The combination rule is the kernel's.

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-006 | Roll mode derived from circumstances, including "They Don't Stack" and cancellation, is owned by modifiers-and-advantage.md (FR-010 to FR-017, `RollMode.resolve`). The use case MUST derive the mode with `RollMode.resolve` and use that one mode both to size the dice request (FR-007) and as the `mode` of the `D20Roll`. Testable: request size and `D20Roll.mode` equal `RollMode.resolve(circumstances)` for the case-table rows. "Exactly once" and "MUST NOT count, filter or combine circumstances itself" are review-only (the call count is not observable through the public API). | SRD 5.2.1, "They Don't Stack", p. 8 | happy (rule owned elsewhere) |
| FR-007 | For a command that rolls, the use case MUST make exactly one request to the `DiceRoller`, through `rollChecked`, for `DiceExpression(mode.diceCount, Die.d20)` with modifier 0: a single `1d20` in `normal`, a single `2d20` in `advantage` or `disadvantage`. For `ChooseToFail` or `AutomaticFailure` it MUST make no request. The faces, in order, are the dice handed to the domain. | SRD 5.2.1, "D20 Tests", step "Roll 1d20", p. 6; "Roll Two D20s", p. 8; dice-and-rolls.md FR-050 | happy |
| FR-008 | Delegated. The d20 used is the higher die under Advantage and the lower under Disadvantage (`RollMode.select`, modifiers-and-advantage.md FR-021 to FR-027; d20-tests.md FR-011). The use case MUST NOT re-select the die. | SRD 5.2.1, "Roll Two D20s", p. 8 | happy (rule owned elsewhere) |
| FR-009 | Delegated. Equal dice give that value and both dice remain in the result (d20-tests.md FR-011; kept index FR-058). The SRD example does not state the equal case; it follows from "use the higher / lower" (package-level derivation). | derived from SRD 5.2.1, "Roll Two D20s", p. 8 | unhappy (boundary, rule owned elsewhere) |

### 4.3 Total and outcome (delegated rules and end-to-end checks)

Owned and unit-tested in d20-tests.md; the use case MUST NOT reimplement them. Every kind resolves to
`D20TestOutcome.success` or `.failure`; an attack roll result adds `isCriticalHit` and reads `hit` as
`outcome == success` (decisions FR-004).

| Id | Requirement as seen from the use case (delegated rule owner first) | Source | Path |
|---|---|---|---|
| FR-011 | Delegated to d20-tests.md FR-023 to FR-026: A check or save is `success` when the total is >= the DC, otherwise `failure`. | SRD 5.2.1, "D20 Tests", step "Compare the Total to a Target Number", p. 6 | happy |
| FR-012 | Delegated to d20-tests.md FR-027, FR-028: An attack roll whose d20 used is neither 1 nor 20 is a hit (`success`) when the total is >= the AC, otherwise a miss (`failure`), and `isCriticalHit` is false. | SRD 5.2.1, "Attack Rolls", p. 7 | happy |
| FR-013 | Delegated to d20-tests.md FR-029: A natural 20 on the d20 used is a hit with `isCriticalHit` true, regardless of modifiers or AC. | SRD 5.2.1, "Rolling 20 or 1", p. 7; "Critical Hit", p. 179 | unhappy (boundary) |
| FR-014 | Delegated to d20-tests.md FR-030: A natural 1 on the d20 used is a miss with `isCriticalHit` false, regardless of modifiers or AC. | SRD 5.2.1, "Rolling 20 or 1", p. 7 | unhappy (boundary) |
| FR-015 | Delegated to d20-tests.md FR-031: For ordinary checks and saves a natural 20 MUST NOT cause automatic success and a natural 1 MUST NOT cause automatic failure; only the DC comparison decides. Death Saving Throws are out of scope. | SRD 5.2.1, "Rolling 20 or 1", p. 7 (under "Attack Rolls") | unhappy (rule interaction) |
| FR-016 | Delegated to d20-tests.md FR-029, FR-031, FR-033: The use case MUST report `isCriticalHit` true only for a natural 20 on an attack roll; a check or save carries no critical-hit field; an attack roll with a d20 used of 2 to 19 has it false. | SRD 5.2.1, "Critical Hit", p. 179 | unhappy (rule interaction) |
| FR-017 | Delegated to d20-tests.md FR-032: Natural 20 and natural 1 are judged on the d20 used after Advantage or Disadvantage, not on the discarded die. | SRD 5.2.1, "Roll Two D20s", p. 8; "Rolling 20 or 1", p. 7 | unhappy (rule interaction) |

Two requirements stay at the application level because they pin that nothing between port and result
alters the numbers.

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-010 | The result's total MUST equal the d20 used plus the sum of the modifiers (d20-tests.md FR-016, FR-019), negative modifiers reducing it, and the use case MUST NOT clamp it: a total below zero or above 30 is reported as computed. | derived from SRD 5.2.1, "D20 Tests", step "Add Modifiers", p. 6; the SRD is silent on clamping, so no clamping is a package decision | unhappy (boundary) |
| FR-028 | Extreme rolls MUST resolve through the whole use case: a fixed roller giving 1 and 20 on a Normal roll, and 1 and 1, 20 and 20 on both dice under Advantage and under Disadvantage, MUST each produce the case-table outcome below. | `doc/rules/testing.md` §4 | unhappy (boundary) |

End-to-end case table (one table-driven application test per row, real domain, `FixedDiceRoller`;
"d20" is the d20 used; rolls in request order; every row has the mandatory ability modifier). "Crit" is
`isCriticalHit` for an attack roll and "n/a" for a check or save. A forced failure names its
`ForcedFailureReason`.

| Label | Kind | Mode | Rolls | Modifiers | Target | Total | Expected outcome | Crit | FR | Source | Path |
|---|---|---|---|---|---|---|---|---|---|---|---|
| check meets DC | check | normal | 10 | ability +5 | DC 15 | 15 | success | n/a | FR-007, FR-010 | SRD 5.2.1, "D20 Tests", p. 6 | happy |
| save fails | save | normal | 8 | ability +1 | DC 10 | 9 | failure | n/a | FR-007, FR-010 | SRD 5.2.1, "Saving Throws", p. 7 | happy |
| attack hits | attack | normal | 12 | ability +3 | AC 15 | 15 | success | false | FR-007, FR-010 | SRD 5.2.1, "Attack Rolls", p. 7 | happy |
| total above 30 | check | normal | 20 | ability +15 | DC 30 | 35 | success | n/a | FR-010, FR-028 | derived from SRD 5.2.1, "D20 Tests", p. 6 | unhappy (boundary) |
| total below zero | check | normal | 1 | ability -5, other -2 | DC 5 | -6 | failure | n/a | FR-010, FR-028 | derived from SRD 5.2.1, "D20 Tests", p. 6 | unhappy (boundary) |
| extreme low, normal | check | normal | 1 | ability +0 | DC 5 | 1 | failure | n/a | FR-028 | SRD 5.2.1, "D20 Tests", p. 6 | unhappy (boundary) |
| extreme high, normal | attack | normal | 20 | ability +0 | AC 30 | 20 | success | true | FR-013, FR-028 | SRD 5.2.1, "Rolling 20 or 1", p. 7 | unhappy (boundary) |
| Advantage uses the higher die | check | advantage | 18, 3 | ability +0 | DC 15 | 18 | success | n/a | FR-007, FR-008 | SRD 5.2.1, "Roll Two D20s", p. 8 | happy |
| Disadvantage uses the lower die | check | disadvantage | 18, 3 | ability +0 | DC 15 | 3 | failure | n/a | FR-007, FR-008 | SRD 5.2.1, "Roll Two D20s", p. 8 | happy |
| Advantage, both dice 1 | attack | advantage | 1, 1 | ability +20 | AC 5 | 21 | failure | false | FR-010, FR-028 | SRD 5.2.1, "Rolling 20 or 1", p. 7 | unhappy (boundary) |
| Disadvantage, both dice 20 | attack | disadvantage | 20, 20 | ability -3 | AC 30 | 17 | success | true | FR-010, FR-028 | SRD 5.2.1, "Rolling 20 or 1", p. 7 | unhappy (boundary) |
| Advantage, both dice 20 | attack | advantage | 20, 20 | ability -3 | AC 30 | 17 | success | true | FR-010, FR-028 | SRD 5.2.1, "Rolling 20 or 1", p. 7 | unhappy (boundary) |
| Disadvantage, both dice 1 | attack | disadvantage | 1, 1 | ability +20 | AC 5 | 21 | failure | false | FR-010, FR-028 | SRD 5.2.1, "Rolling 20 or 1", p. 7 | unhappy (boundary) |
| Disadvantage, natural 1 used | attack | disadvantage | 20, 1 | ability +10 | AC 5 | 11 | failure | false | FR-007, FR-017, FR-028 | SRD 5.2.1, "Roll Two D20s", p. 8 | unhappy (rule interaction) |
| Advantage and Disadvantage cancel | check | normal (circumstances `Advantage`, `Disadvantage`) | 14 | ability +0 | DC 15 | 14 | failure | n/a | FR-006, FR-007 | SRD 5.2.1, "They Don't Stack", p. 8 | unhappy (rule interaction) |
| chosen to fail a save | save | normal (no roll) | none | none | DC 10 | no total | failure (`ResolveD20TestForcedFailure`, `chosenToFail`) | n/a | FR-007 | SRD 5.2.1, "Saving Throws", p. 7 | happy |
| automatic failure on a check | check | normal (no roll) | none | none | DC 10 | no total | failure (`ResolveD20TestForcedFailure`, `automatic`) | n/a | FR-007 | SRD 5.2.1, "Blinded [Condition]", p. 177 | happy |

### 4.4 Result

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-018 | A rolled result MUST carry the breakdown needed to explain it without recomputation, through the section 5 fields: each variant carries `ability` (the command's label), and its domain result holds what d20-tests.md FR-041 and FR-034 list: for a `CheckResult` the kind, `D20Roll` (roll mode `mode`, dice in request order, `natural`, kept index), `RollModifiers`, total, `DifficultyClass` and outcome; for an `AttackRollResult` the same with an `ArmorClass` and `isCriticalHit`; for a `ForcedFailureResult` the kind and reason, plus the `target` the variant adds. The roll mode is `D20Roll.mode`; no field duplicates it. The use case MUST populate every field from what it requested and the domain returned. | `doc/rules/architecture.md` §6; SRD 5.2.1, "D20 Tests", p. 6 | happy |
| FR-020 | `ResolveD20TestResult` MUST be a closed set with exactly the three variants of section 3, so a consumer's exhaustive `switch` fails to compile when a variant is added. (`D20TestOutcome` being exactly `success` and `failure` is d20-tests.md FR-060.) | `doc/rules/architecture.md` §3, §6, §10 | happy |
| FR-021 | A result MUST be a value object: equal when every field is equal. | `doc/rules/architecture.md` §3 | happy |
| FR-022 | The use case MUST NOT modify its command: after `call` returns, the command (`ability`, `target`, the attempt's `modifiers` and `circumstances`) and the collections it was built from MUST equal what they were before. | `doc/rules/testing.md` §4 | unhappy (immutability) |
| FR-043 | Delegated. `ResolveD20TestRolledCheck` has no `kind` field and no guard of its own: the kind is `CheckResult.kind`, and `D20TestResolver.resolveCheck` (d20-tests.md FR-062, FR-069) and `CheckResult.resolve` (FR-063, FR-070) throw `ArgumentError` for kind `attackRoll`, through a real check and not `assert`; the rejection is in `resolveCheck` and `CheckResult.resolve`, and this spec does not require the `CheckResult` constructor to reject it. The other impossible combinations (a check carrying an `AttackRollResult`, an attack roll carrying a `DifficultyClass`) are unrepresentable by the field types. | `doc/rules/architecture.md` §6; d20-tests.md FR-062 | unhappy (invalid input) |
| FR-044 | Result types MUST NOT carry display text. Mechanism: an architecture test scans the result declarations in `lib/src/d20_test/` and fails on any `String` field or getter. | `doc/rules/architecture.md` §3, §6, §10 | architecture guardrail |
| FR-049 | The target in a result MUST be typed by variant: `ResolveD20TestRolledCheck` and `ResolveD20TestForcedFailure` carry a `DifficultyClass`, `ResolveD20TestRolledAttack` an `ArmorClass`. No union or `num` target type exists. | SRD 5.2.1, "D20 Tests", p. 6; "Armor Class", p. 7 | happy |
| FR-053 | The result MUST be named `ResolveD20TestResult` and its variants prefixed with the operation (`ResolveD20TestRolledCheck`, `ResolveD20TestRolledAttack`, `ResolveD20TestForcedFailure`). Generic names (`Rolled`, `Applied`, `Rejected`, `Succeeded`, `ForcedFailure`) MUST NOT be exported. | shared-types-and-ownership.md FR-017; `doc/rules/architecture.md` §4 | unhappy (name collision) |

### 4.5 Collaborators, determinism and failure

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-023 | `ResolveD20Test` MUST take its `DiceRoller` through its constructor, typed as the port, and `Observability` as an optional argument defaulting to `Observability.none` (observability-ports.md FR-042; the `const` no-op in the port library, decisions FR-036); omitting it MUST work. | `doc/rules/architecture.md` §4; `doc/rules/observability.md` §4 | happy |
| FR-045 | Structural purity: no file in `lib/src/d20_test/application/` MAY contain `Random(`, `DateTime.now(`, `Stopwatch(`, a non-`const` top-level or `static` mutable field, or construct a `DiceRoller` adapter or a recording or exporting `Observability`; referencing the `const` `NoopObservability` default is allowed. Mechanism: the architecture test scans the folder (`doc/rules/architecture.md` §9). "Does not branch on whether observability is enabled" is review-only; FR-039 covers it behaviourally. | `doc/rules/architecture.md` §3, §4, §9; `doc/rules/observability.md` §4 | architecture guardrail |
| FR-057 | `ResolveD20Test` MUST obtain every result by calling the pure `D20TestResolver` (`resolveCheck`, `resolveAttackRoll`, `forcedFailure`; d20-tests.md FR-069, FR-063, FR-064, FR-035, FR-036, FR-052) and MUST NOT call, construct or hold another use case. No use case in any context may call `ResolveD20Test`; one needing a D20 Test result composes `D20TestResolver` and records its own signals. Mechanism: architecture-guardrails.md FR-097 (identifier scan of `application/` and `domain/` files; `lib/src/testing/` and tests exempt). | shared-types-and-ownership.md FR-044; `doc/rules/architecture.md` §4 | architecture guardrail |
| FR-058 | The use case MUST orchestrate as follows: (a) the `D20TestKind` derives from the command variant (`AbilityCheckCommand` gives `abilityCheck`, `SavingThrowCommand` `savingThrow`, `AttackRollCommand` `attackRoll`); (b) `ChooseToFail` maps to `ForcedFailureReason.chosenToFail`, `AutomaticFailure` to `.automatic`; (c) a `RollAttempt` calls `resolveCheck` for a check or save and `resolveAttackRoll` for an attack roll, while `ChooseToFail` or `AutomaticFailure` calls `forcedFailure` (d20-tests.md FR-069, FR-035, FR-036); (d) the domain result is wrapped with the command's `ability` and, for a forced failure, its `target`. | package design; d20-tests.md FR-035, FR-036, FR-069 | happy |
| FR-024 | `call` MUST be synchronous and return the result directly, not a `Future`, because both ports are synchronous. | `doc/rules/architecture.md` §4 | happy |
| FR-025 | Given equal commands and a `DiceRoller` yielding the same values in the same order, `call` MUST return equal results on every invocation, in any test order. | `doc/rules/testing.md` §4 | happy |
| FR-026 | When the `DiceRoller` throws a `DiceRollerException` (`unavailable`, or `invalidResult` from `rollChecked`), `call` MUST let that same instance propagate (not wrapped, not converted into a result) and MUST NOT return a partial result. | `doc/rules/architecture.md` §4, §6; dice-and-rolls.md FR-048, FR-052 | unhappy (collaborator failure) |
| FR-051 | After the `DiceRoller` has thrown, `call` MUST NOT request dice again (no retry, no fallback roller): a failing call leaves exactly one request on record. | `doc/rules/architecture.md` §4 | unhappy (collaborator failure) |
| FR-027 | When the `DiceRoller` returns a `RollResult` for a different expression than requested, `call` MUST throw `DiceRollerException` with reason `invalidResult` (raised by `rollChecked`) and MUST NOT return a result built from it. A d20 value of 0 or 21 cannot reach the use case: the kernel's die roll and `RollResult` reject out-of-range faces (dice-and-rolls.md FR-031 to FR-035). | dice-and-rolls.md FR-050, FR-051; `doc/rules/architecture.md` §6 | unhappy (collaborator returns invalid data) |
| FR-037 | An `Error` thrown by the roller (for example a `StateError` from a defective adapter, which `rollChecked` does not catch, dice-and-rolls.md FR-053) is a defect the port types cannot prevent. `call` MUST let it propagate unchanged; the span records it as it propagates (FR-029), and the use case MUST NOT count it in `srd5e.d20_test.errors`, increment `srd5e.d20_test.resolved` or log. | `doc/rules/observability.md` §7; `doc/rules/architecture.md` §6 | unhappy (state error) |

### 4.6 Telemetry

Names are defaults; the constants are in section 7, the single source for `doc/observability/signals.md`.
Attribute values follow decisions FR-041.

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-029 | Each `call` MUST run inside one span named `srd5e.d20_test.resolve` obtained through the `Tracer`, with `srd5e.d20_test.kind` and `srd5e.ability` set at span start, and `srd5e.d20_test.roll_mode` and `srd5e.outcome` set once the result is known, plus `srd5e.d20_test.critical_hit` for an attack roll only (FR-052). For a `ResolveD20TestForcedFailure` no d20 was rolled and the domain result carries no mode, so `roll_mode` MUST be absent (as `critical_hit` is) and `outcome` is `failure`; `roll_mode` therefore always equals `D20Roll.mode` when present. | `doc/rules/observability.md` §6; decisions FR-041 | happy |
| FR-030 | Each successful `call` MUST increment the counter `srd5e.d20_test.resolved` exactly once with the same attributes as the span, whatever the outcome; a `failure` is a normal outcome. | `doc/rules/observability.md` §5 | happy |
| FR-031 | Each `call` MUST record its duration, in seconds, into the histogram `srd5e.d20_test.duration` through `Meter.time`, exactly once, with `srd5e.d20_test.kind`, **including a call whose body throws** (recorded, same object rethrown; observability-ports.md FR-029, FR-030). The use case MUST NOT read a clock. | `doc/rules/observability.md` §4, §5; observability-ports.md FR-029, FR-030 | happy / unhappy (collaborator failure) |
| FR-032 | Each successful `call` that rolled MUST record the number of modifiers in its `RollModifiers` (ability modifier, Proficiency Bonus when present, each other `Modifier`) into the histogram `srd5e.d20_test.modifiers` (unit `{modifier}`) with `srd5e.d20_test.kind`; the minimum is 1. A `ResolveD20TestForcedFailure` MUST record nothing there. | `doc/rules/observability.md` §5 (sizes) | unhappy (empty and minimal) |
| FR-047 | The use case MUST emit no log event at any level, on success or failure, and takes the `Logger` from `Observability` without using it. | `doc/rules/observability.md` §1.4, §7; decisions FR-043 | happy |
| FR-035 | A `failure` outcome of any kind (including a missed attack roll) MUST NOT set the span status to error, MUST NOT increment the `errors` counter and MUST NOT be reported as an error in any signal. | `doc/rules/observability.md` §6, §7 | unhappy (rule interaction) |
| FR-036 | When the `DiceRoller` throws a `DiceRollerException` (`unavailable` or `invalidResult`), the failure MUST be recorded exactly once: span status error with the exception recorded, `srd5e.d20_test.errors` incremented once with `srd5e.d20_test.kind` and `error.type` equal to the exception's `errorType`, and `srd5e.d20_test.resolved` not incremented. | `doc/rules/observability.md` §7, §9; errors-and-results.md FR-034 | unhappy (collaborator failure) |
| FR-038 | Every attribute value MUST come from a closed set (decisions FR-041): `srd5e.d20_test.kind` in {`ability_check`, `saving_throw`, `attack_roll`}; `srd5e.ability` in {`strength`, `dexterity`, `constitution`, `intelligence`, `wisdom`, `charisma`}, the lower-case enum name of the command's `Ability` (the test pins all six); `srd5e.d20_test.roll_mode` in {`normal`, `advantage`, `disadvantage`}, absent for a `ResolveD20TestForcedFailure`; `srd5e.outcome` in {`success`, `failure`}; `srd5e.d20_test.critical_hit` a `bool`, never a string; `srd5e.d20_test.roller_failure` in {`unavailable`, `invalid_result`}; `srd5e.d20_test.forced_failure_reason` in {`chosen_to_fail`, `automatic`}; `error.type` equal to `Srd5eException.errorType` (`dice_roller_exception` for `DiceRollerException`, errors-and-results.md). Attributes MUST NOT carry ids, totals, rolls, target numbers or free text. | `doc/rules/observability.md` §5 | happy / unhappy (boundary: closed value sets) |
| FR-039 | With no `Observability` supplied, and with a recording one, `call` MUST return equal results for the same command and roller values, make the same request, and throw the same exception type for the same failing roller. | `doc/rules/observability.md` §9 | happy |
| FR-040 | Metric names, span name and attribute keys in this section MUST be defined once as constants in a single `abstract final class D20TestSignals` in the `d20_test` context (in a file under `lib/src/d20_test/application/` whose name ends `signals.dart`, architecture-guardrails.md §9; shared keys `srd5e.outcome` and `error.type` are `AttributeKeys.outcome` and `AttributeKeys.errorType` in `shared_ports/`), MUST NOT appear as string literals at call sites, and MUST be pinned by tests asserting their literal values. | `doc/rules/observability.md` §5, §9, §10 | happy |
| FR-041 | The use case MUST NOT open child spans: the `DiceRoller` is in-memory and the domain silent, so the one span is the whole trace. | `doc/rules/observability.md` §3, §6 | happy |
| FR-046 | `Meter.time` MUST run inside the `Tracer.trace` body, so the span encloses the timed work and a failure reaches the span after the duration is recorded. | `doc/rules/observability.md` §4, §6; observability-ports.md FR-012, FR-030 | happy |
| FR-052 | `srd5e.d20_test.critical_hit` MUST be present, as a `bool`, on the span and on `resolved` for an attack roll that rolled, and absent for a check, a save and any `ResolveD20TestForcedFailure`. Its value equals `AttackRollResult.isCriticalHit`. The former `srd5e.d20_test.basis` attribute and the outcome values `miss`, `hit` and `critical_hit` no longer exist. | decisions FR-004, FR-041 | unhappy (boundary: attribute presence) |
| FR-059 | A rolled call MUST record the d20 face it used (`D20Roll.natural`, 1 to 20) into the histogram `srd5e.d20_test.natural` (unit `{face}`) with `srd5e.d20_test.kind`, exactly once, through the instrument created once at construction. A `ResolveD20TestForcedFailure` MUST record nothing there. The face is a histogram measurement, not an attribute, so FR-038's no-rolls rule is untouched. | `doc/rules/observability.md` §5 (distributions); package design (roller-fairness diagnosis) | happy; unhappy (empty and minimal: forced rows) |
| FR-060 | A `ResolveD20TestForcedFailure` MUST set `srd5e.d20_test.forced_failure_reason` to `chosen_to_fail` for `ChooseToFail` and `automatic` for `AutomaticFailure`, on the span and on `srd5e.d20_test.resolved`; a rolled call MUST NOT carry the key. | `doc/rules/observability.md` §5; decisions FR-041 | happy; unhappy (boundary: attribute presence) |
| FR-061 | When the `DiceRoller` throws a `DiceRollerException`, the `srd5e.d20_test.errors` counter and the error span MUST carry `srd5e.d20_test.roller_failure`: `unavailable` for reason `unavailable`, `invalid_result` for `invalidResult`. | `doc/rules/observability.md` §5, §7 | unhappy (collaborator failure) |

### 4.7 Public API

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-042 | `lib/srd5e.dart` MUST export, each exactly once and each with a dartdoc comment, from the `d20_test` barrel: `ResolveD20Test`; `ResolveD20TestResult`, `ResolveD20TestRolledCheck`, `ResolveD20TestRolledAttack`, `ResolveD20TestForcedFailure`; `D20TestCommand`, `AbilityCheckCommand`, `SavingThrowCommand`, `AttackRollCommand`, `CheckAttempt`, `SaveAttempt`, `RollAttempt`, `ChooseToFail`, `AutomaticFailure`; `D20TestOutcome`, `AttackRollResult`, `CheckResult`, `ForcedFailureResult`, `ForcedFailureReason`, `D20TestKind`; `D20Roll`, `RerollDecision`, `KeepRoll`, `RerollDie`, `RollModifiers`; `DifficultyClass`, `ArmorClass`; `D20TestResolver`; `D20TestSignals`. Further domain types follow d20-tests.md. The kernel types (`Modifier`, `RollMode`, `RollCircumstance`, `Advantage`, `Disadvantage`, `Ability`, `Die`, `DiceExpression`) are exported once by the kernel specs directly from `lib/srd5e.dart`, and the `d20_test` barrel MUST NOT re-export them. The barrel's library doc MUST list the use case's inputs and outputs. The names `CheckOutcome`, `AttackOutcome`, `AttackRollOutcome`, `AttackBasis`, `RolledCheck`, `RolledAttackRoll`, `ForcedFailure`, `D20TestResult`, `Dc`, `RollModifier` and `ModifierSource` MUST NOT be exported. | `doc/rules/architecture.md` §2, §4, §7; modifiers-and-advantage.md §6; decisions FR-002, FR-004, FR-017 | happy |

The telemetry constants are exported on purpose: attribute keys and values are a public contract
(`doc/rules/observability.md` §9). The shape and validation of `DifficultyClass`, `ArmorClass`,
`D20Roll` and `RollModifiers` are d20-tests.md's; this use case does not re-validate them.

### Withdrawn ids

| Id | Withdrawn |
|---|---|
| FR-003 | Withdrawn: moved to d20-tests.md (`RollModifiers` shape and copy; decisions FR-003). Command immutability stays in FR-022. |
| FR-004 | Withdrawn: the command carries no source counts; the combination rule is modifiers-and-advantage.md (FR-010 to FR-017). |
| FR-019 | Withdrawn: moved to d20-tests.md (FR-041; decisions FR-048). |
| FR-033 | Withdrawn: the `FINE` log is dropped (FR-047; decisions FR-043). |
| FR-034 | Withdrawn with FR-033: no log, no lazy attribute closure. |
| FR-054 | Withdrawn: moved to d20-tests.md (FR-034, FR-060; decisions FR-004, FR-048). |

FR-048 and FR-050 were never issued: the gaps are reserved group spacing, not lost requirements.

## 5. Model

Domain (pure, synchronous, silent; owned by d20-tests.md and the kernel specs, only used here): value
objects `DifficultyClass`, `ArmorClass`, `RollModifiers`, `D20Roll`, `CheckResult`, `AttackRollResult`,
`ForcedFailureResult`, `ForcedFailureReason`, `D20TestKind`, `D20TestOutcome`, and from the kernel
`Modifier`, `RollMode`, `RollCircumstance`, `Ability`, `DiceExpression`; and the domain service
`D20TestResolver` (d20-tests.md FR-069). The use case composes it and re-derives nothing (FR-057). No
entities, aggregates or domain events: a D20 Test is a one-shot calculation.

Invariants and where they are enforced:

- Kind and target type cannot disagree: sealed command variants and typed result variants (FR-001, FR-049).
- One ability modifier, at most one Proficiency Bonus: the shape of `RollModifiers` (decisions FR-003).
- Dice are 1 to 20 and counted per mode: the kernel's die roll, `RollResult` and `D20Roll` (dice-and-rolls.md FR-031 to FR-035).
- A check never carries a critical-hit flag (FR-016); a check resolution rejects kind `attackRoll` with `ArgumentError` (d20-tests.md FR-062, FR-063, FR-070; FR-043). No `assert`-based invariant. The rejection of kind `attackRoll` lives in `resolveCheck` and `CheckResult.resolve`; this spec does not require the `CheckResult` constructor to reject it.
- Result collections are unmodifiable (d20-tests.md FR-041).

Application (declared here; signatures illustrative, behaviour fixed by the requirements):

- **Commands (FR-001, FR-055, FR-056).** `sealed class D20TestCommand` with `Ability ability` and
  `AbilityCheckCommand(ability, target: DifficultyClass, attempt: CheckAttempt)`,
  `SavingThrowCommand(ability, target: DifficultyClass, attempt: SaveAttempt)`,
  `AttackRollCommand(ability, target: ArmorClass, attempt: RollAttempt)`.
- **Attempts.** `RollAttempt(modifiers: RollModifiers, circumstances: Iterable<RollCircumstance>)`
  (circumstances default empty; copied, unmodifiable); `ChooseToFail` (`SaveAttempt` only);
  `AutomaticFailure` (`CheckAttempt` and `SaveAttempt`). `sealed CheckAttempt` is implemented by
  `RollAttempt` and `AutomaticFailure`; `sealed SaveAttempt` by `RollAttempt`, `ChooseToFail` and
  `AutomaticFailure`.
- **Results (FR-018, FR-049).** `sealed ResolveD20TestResult`, each variant a value object with
  `ability`: `ResolveD20TestRolledCheck(ability, result: CheckResult)`,
  `ResolveD20TestRolledAttack(ability, result: AttackRollResult)`,
  `ResolveD20TestForcedFailure(ability, result: ForcedFailureResult, target: DifficultyClass)`.
- `ResolveD20Test` orchestrates only: `RollMode.resolve` once (FR-006), one `rollChecked` request sized
  by that mode (FR-007), builds the `D20Roll`, calls `D20TestResolver`, builds the result and emits
  telemetry (FR-029 to FR-032, FR-046). A forced failure makes no request.

| Situation | Mechanism |
|---|---|
| Failed check, failed save, a miss, a forced failure | Result (outcome `failure`), not an error |
| `DiceRoller` unavailable | `DiceRollerException(unavailable)`, propagated unchanged, recorded once (FR-026, FR-036) |
| Roller answers a different expression | `DiceRollerException(invalidResult)` from `rollChecked`, propagated, recorded once (FR-027, FR-036) |
| Roller returns an out-of-range face | Unrepresentable: the kernel's die roll rejects it |
| Defective adapter throws an `Error` | Propagates unchanged; the span records it, nothing counts it (FR-037) |
| Mismatched kind and target, impossible result | Unrepresentable or `ArgumentError` at construction (FR-001, FR-043) |

No domain failure is a result variant (commands are built from typed values). Port failures are
`Srd5eException`s that propagate; decisions FR-018 and `MissingContent` do not apply.

## 6. Interface

```dart
final class ResolveD20Test {
  ResolveD20Test(DiceRoller diceRoller,
      {Observability observability = Observability.none});

  ResolveD20TestResult call(D20TestCommand command);
}
```

- **Sync** (FR-024). **Ports:** `DiceRoller` (`shared_ports`) and `Observability` (`Logger` unused,
  `Tracer`, `Meter`).
- **Exact port calls (FR-007).** One `diceRoller.rollChecked(DiceExpression(mode.diceCount, Die.d20))`
  per rolling call, with `mode` from one `RollMode.resolve` (FR-006): a single `1d20` or `2d20`, never
  two `1d20`. A single request is atomic (a failure leaves no half-rolled pair, FR-051) and keeps dice
  order unambiguous. The faces, in order, go to `RollMode.select` through `D20Roll`.
- **`DiceRoller` failure contract as relied on.** The port returns a `RollResult` per request; no
  sealed result. A roller that cannot roll throws `DiceRollerException(unavailable)`; one answering a
  different expression is caught by `rollChecked` as `invalidResult`; both propagate unchanged
  (FR-026, FR-027). An `Error` from a defective adapter is not caught (FR-037).
- **Barrel.** `lib/src/d20_test/d20_test.dart` exports the use case and the FR-042 types;
  `lib/srd5e.dart` re-exports them. Nothing in `adapters/` is needed.
- **Layering.** The use case lives in `lib/src/d20_test/application/` and imports the context's
  `domain`, `shared_ports` and `shared_kernel` only (decisions FR-013). The command, attempt and
  result types live in the same folder (d20-tests.md D-17), and `D20TestSignals` in a file there whose
  name ends `signals.dart` (FR-040).

## 7. Observability

Evaluation (`doc/rules/observability.md` §2):

1. **What can go wrong?** The `DiceRoller` is unavailable or answers a different expression; a
   defective adapter throws an `Error`; outcome rates drift (wrong maths or a biased roller).
2. **How would an operator know?** Port failure: span error status plus `errors`
   (`error.type=dice_roller_exception`, `roller_failure` per reason, FR-036, FR-061). A defective
   adapter's `Error`: the span only (FR-037). A failed check or miss is not an error and shows only
   in the `srd5e.outcome` and `critical_hit` attributes of `resolved` (FR-035). A misfiring caller
   shows as a sustained `automatic` share of `forced_failure_reason` (FR-060).
3. **Diagnosis:** kind, ability, roll mode, outcome, the critical-hit flag, the forced-failure
   reason and the roller-failure reason as low-cardinality attributes; the full breakdown is in the
   returned result, not telemetry.
4. **Counted or timed:** throughput and outcomes (`resolved`), latency including failed calls
   (`duration`), sizes (`modifiers`), the d20 face used (`natural`, FR-059), errors (`errors`).
5. **Existing instrumentation:** none; these are the first entries in `doc/observability/signals.md`.
6. **Monitor or alert on:** see the table below; errors split by `roller_failure`, resolved outcome
   mix and `critical_hit` share, the `automatic` forced-failure share, duration, modifiers, the
   natural-face distribution.
7. **Noise:** no logs (FR-047), no child spans, no per-modifier or per-die log events; every signal
   aggregates one record per call.

Constants live in `D20TestSignals` (FR-040); shared keys are `AttributeKeys` in `shared_ports/`. This
table is the only catalogue of these signals (decisions FR-040).

| Signal | Type | Attributes | Purpose | Suggested monitoring |
|---|---|---|---|---|
| `srd5e.d20_test.resolve` | span | `srd5e.d20_test.kind` (`ability_check`, `saving_throw`, `attack_roll`), `srd5e.ability` (`strength`, `dexterity`, `constitution`, `intelligence`, `wisdom`, `charisma`), `srd5e.d20_test.roll_mode` (`normal`, `advantage`, `disadvantage`; absent for a forced failure), `srd5e.outcome` (`success`, `failure`), `srd5e.d20_test.critical_hit` (`true`, `false`; attack rolls only), `srd5e.d20_test.forced_failure_reason` (`chosen_to_fail`, `automatic`; forced failures only), `srd5e.d20_test.roller_failure` (`unavailable`, `invalid_result`; error spans only); error status on failure | Trace one D20 Test; the only signal that carries the recorded exception, including a defective adapter's `Error` | Inspect error-status spans when `errors` alerts, or when a span has error status without an `errors` increment (FR-037). Do not alert on span error rate as well as on `errors`; they overlap for port failures |
| `srd5e.d20_test.resolved` | counter, unit `{test}` | same as the span | Throughput and outcome mix | Over at least 500 attack rolls in `normal`, `critical_hit=true` outside roughly 2 to 8 percent suggests a biased roller (expected 5 percent; widened ranges are applied by callers). Covers direct host calls only: no other use case calls `ResolveD20Test` (FR-057), so combat attack rolls are counted under those use cases' own signals. A `forced_failure_reason`=`automatic` share near 100 percent for one ability, sustained, suggests misapplied caller condition wiring rather than gameplay. Alert on a drop to zero throughput against the consumer's baseline |
| `srd5e.d20_test.duration` | histogram, unit `s` | `srd5e.d20_test.kind` | Latency, including failed calls; dominated by the injected roller | p99 above 5 times the consumer's baseline for a sustained window; expect microseconds with an in-memory roller |
| `srd5e.d20_test.modifiers` | histogram, unit `{modifier}` | `srd5e.d20_test.kind` | Size of the `RollModifiers` callers pass (minimum 1) | p99 above 20 sustained suggests a caller accumulating modifiers; dashboard otherwise |
| `srd5e.d20_test.natural` | histogram, unit `{face}` | `srd5e.d20_test.kind` | The d20 face each rolled call used (1 to 20), so an unfair or stuck injected roller is visible on every face, not only on the natural 20 (FR-059) | Over at least 500 rolled calls in `normal`, any face's share outside roughly 2 to 8 percent (expected 5) points at the roller; a share pinned at one face means a stuck roller. Compare with the `critical_hit` monitor on `resolved`, which sees only the 20 face |
| `srd5e.d20_test.errors` | counter, unit `{error}` | `srd5e.d20_test.kind`, `error.type` (`dice_roller_exception`), `srd5e.d20_test.roller_failure` (`unavailable`, `invalid_result`) | Port failures leaving the use case, counted once, with why the roller failed | Alert on any non-zero rate sustained over 5 minutes. Split the alert by `srd5e.d20_test.roller_failure` (FR-061): `unavailable` is infrastructure (the dice source is down; page ops), `invalid_result` is the host's adapter answering a different expression (a contract breach; file a bug). The span of the same call holds the exception |

Each failure is recorded once, by the use case at whose boundary it leaves srd5e; the `DiceRoller`
adapter and the domain emit nothing for it. A caller in another context that wraps this use case
records its own failures under its own signals and must not re-count these.

## 8. Test plan

Levels: unit (`test/d20_test/...`), application (`test/d20_test/application/`), architecture
(`test/architecture/`), scenario (`test/scenarios/`). Rules are proven at unit level in d20-tests.md;
the application level proves orchestration, port failure and telemetry only. Tests carry
`Requirement:` and `Path:` doc comments; the 4.3 case table is a `const` list of records, one `test`
per row.

Doubles from `lib/testing.dart` (decisions FR-038): `FixedDiceRoller` with its `requests` list (success
rows, dice count and order, FR-007); `CallbackDiceRoller` for every failure and invalid-result case
(throws a chosen `DiceRollerException(unavailable)`, returns a `RollResult` for a different expression
so `rollChecked` throws `invalidResult`, or throws a `StateError`; `FixedDiceRoller` cannot throw a
chosen `Srd5eException`, dice-and-rolls.md FR-056, FR-057); `RecordingObservability` with
`RecordingTracer`, `RecordingMeter` (`timedDuration` 250 ms in the FR-031 test, so the recorded 0.25
proves the value comes from the meter) and `RecordingLogger` (level `finest`, to prove zero records).
The `DiceRoller` contract suite is `test/contract/` and not exported (decisions FR-039); this spec adds none.

| Ids | Level | Notes |
|---|---|---|
| FR-001, FR-005, FR-056 | unit | Each command variant builds and keeps its fields (type pairings are analyzer-enforced, see "Not covered"); equality and hash code with one differing field per case (ability, target, modifiers, circumstances order and content, attempt type); mutating the source list changes nothing and the command's `circumstances` throws `UnsupportedError` |
| FR-020, FR-021, FR-049 | unit | A function mapping each `ResolveD20TestResult` variant to a distinct marker is exercised on every variant (exhaustiveness is analyzer-enforced); result equality and hash code; one row per variant reads its `target` (`DifficultyClass`, `ArmorClass`, `DifficultyClass`) |
| FR-008, FR-009, FR-011 to FR-017, FR-043 | unit | Delegated to d20-tests.md (FR-011, FR-023 to FR-033, FR-062, FR-063; `throwsA(isA<ArgumentError>())` for kind `attackRoll`) plus one application smoke row each from the case table; FR-016 application: no `critical_hit` on any check or save row, `false` on an attack row with a d20 used of 2 to 19 |
| FR-002, FR-007 | application | Minimal command: one `1d20` request, total = d20 plus the ability modifier. `FixedDiceRoller.requests`: `[1d20]` normal, `[2d20]` advantage and disadvantage, `[]` for chosen and automatic failure; one request per rolling call; modifier 0 |
| FR-006 | unit + application | Kernel `RollMode.resolve` tests (modifiers-and-advantage.md FR-010 to FR-017); rows "Advantage uses the higher die", "Disadvantage uses the lower die" and "Advantage and Disadvantage cancel" check the mode reaches the request (`2d20`, `2d20`, single `1d20`) and `D20Roll.mode`. "Exactly once" is review-only |
| FR-010, FR-028 | application | Rows "total above 30", "total below zero" and the six extreme-roll rows (normal low and high; Advantage and Disadvantage with both 1 and both 20); also unit via d20-tests.md FR-016, FR-019 |
| FR-055 | application | Command with `ability` strength and a modifier built for dexterity: total uses the modifier, attribute is `strength` |
| FR-018, FR-022, FR-058 | application | Every field of one fully populated result per variant (`ability`, kind, `D20Roll.mode`, dice, natural, modifiers, total, target, outcome, `isCriticalHit`; forced failure: reason and `target`); command and source collections compared before and after `call`; table-driven kind and reason mapping (`ability_check` / `saving_throw` / `attack_roll` with a `ResolveD20TestRolledAttack`; `chosenToFail` for `ChooseToFail`; `automatic` for `AutomaticFailure` on a check and on a save, so a swapped reason fails), wrapped `ability`, forced-failure `target`, empty `requests` for forced rows |
| FR-023, FR-024, FR-025 | application | Omitted `Observability` works and the constructor takes the port type; the returned object is not a `Future` (static type analyzer-enforced); two calls with the same scripted roller, also under random ordering |
| FR-026, FR-027, FR-051 | application | `CallbackDiceRoller` throws a `DiceRollerException`: the same instance propagates, no result, exactly one call recorded; returns a result for a different expression (one case per differing field): `DiceRollerException` with reason `invalidResult` |
| FR-031, FR-034, FR-051 | application | The errors-and-results.md FR-031, FR-034 and FR-051 rows (FR-053): a `DiceRollerException` propagates with its original type unchanged, never converted or wrapped (FR-031, the "roller failures" tests); the thrown failure is recorded exactly once with `error.type` equal to the exception's `errorType`, `dice_roller_exception` (FR-034, the "failure recording" tests); a failing call is not retried - one request on record - and an `Exception` from the port that is not an `Srd5eException` also propagates unchanged, recorded on the span only, with no `error.type` and no increment (the "raw Exception" test) |
| FR-029, FR-030, FR-041, FR-052 | application | `RecordingTracer`/`RecordingMeter`: span name, attributes at start and end, exactly one span per call, one `resolved` increment with the span's attributes for success and failure outcomes; forced failure: `roll_mode` and `critical_hit` absent, `outcome` `failure` with `forced_failure_reason` (FR-060); attack rows: `critical_hit` present and equal to `isCriticalHit`; check, save and forced-failure rows: absent; no `basis` key and no `miss`, `hit` or `critical_hit` outcome value |
| FR-031, FR-032, FR-046 | application | `timedDuration` 250 ms: one duration record of 0.25, unit `s`, kind attribute; repeated with a throwing roller: still one record, same exception rethrown; the span encloses the measurement, also with a throwing roller; modifier-count histogram 1 (ability only), 2 (with a Proficiency Bonus), several; absent for a forced failure |
| FR-035, FR-036, FR-037, FR-047 | application | A failing check and a miss: span status not error, `errors` unchanged; throwing (`unavailable`) and wrong-expression (`invalidResult`) rollers: error span with exception, one `errors` increment with `error.type` `dice_roller_exception` and `roller_failure` (FR-061), `resolved` untouched; a `StateError` propagates, span records it, no `errors`, no `resolved`; `RecordingLogger` at `finest`: zero records on every row |
| FR-059, FR-060, FR-061 | application | The natural histogram records `D20Roll.natural` once per rolled case-table row (unit `{face}`, kind attribute) and nothing for a forced row (FR-059); `forced_failure_reason` `chosen_to_fail` / `automatic` on the span and `resolved` for the two forced rows, absent for rolled rows (FR-060); `roller_failure` `unavailable` / `invalid_result` on the error span and the `errors` counter (FR-061); the new constants pinned by literal |
| FR-038, FR-039 | application | Every attribute value across all rows is in its closed set; all six abilities map to lower-case names; `critical_hit` is a `bool`; same table with no-op and recording `Observability`, comparing results, requests and exception types |
| FR-040, FR-044, FR-045, FR-053, FR-057 | architecture | Catalogue and constant checks (`doc/rules/observability.md` §10) plus pin tests per literal; no `String` field in result declarations; folder scan for `Random(`, `DateTime.now(`, `Stopwatch(`, mutable top-level and `static` state, adapter construction (the `const` `NoopObservability` default allowed; "no branching on enabled" review-only); barrel scan: no generic variant name exported and every variant starts with `ResolveD20Test`; import scan per architecture-guardrails.md FR-097: no use case mentions `ResolveD20Test`, `application/` mentions no other use case; application assertion (or review-only note) that results come only from `D20TestResolver`: a recording double of the resolver sees every call and the result is the one it returned |
| FR-042 | scenario | Imports `package:srd5e/srd5e.dart` and `package:srd5e/testing.dart` only, references each exported name once and resolves one check, one save, one attack roll and one chosen failure with a fixed roller and recording `Observability`; an architecture check fails if a "MUST NOT be exported" name appears in the barrel. This is the first scenario test (roadmap phase 1) and also covers Advantage |

- **Mutation testing:** `application/` SHOULD be mutated; the `d20_test` `domain/` rules it exercises
  MUST be (threshold 80, `doc/rules/testing.md` §8). Boundary rows live in d20-tests.md and guard
  against surviving `>=` / `>` mutants; the application rows only smoke-test wiring.
- **Not covered (analyzer-enforced; a test that could not fail at runtime would be a defect,
  `doc/rules/testing.md` §8):** the command and result type pairings (FR-001, FR-049), exhaustive
  switch (FR-020) and the synchronous return type (FR-024); `dart analyze --fatal-infos` is the
  check. Every other live id is tested. FR-043 is delegated.

## 9. Open questions and decisions

No open questions. Settled, one line each:

- Ownership split (domain and `D20TestResolver` in d20-tests.md; use case, commands, result, signals here): decisions FR-002, FR-040, FR-044.
- The command carries `Iterable<RollCircumstance>`, not counts or a resolved mode; `RollMode.resolve` runs once (FR-006).
- The `Ability` label may disagree with the modifier; the caller keeps it consistent (FR-055; d20-tests.md D-06).
- One `2d20` request, not two `1d20` (FR-007).
- Critical Hit is a flag, not an outcome variant (decisions FR-004). Natural 20 and 1 do not apply to ordinary checks and saves (d20-tests.md FR-031).
- No out-of-range roll case: unrepresentable; a wrong answer is `invalidResult` (FR-027); `StateError` only for defective adapters (FR-037).
- `error.type` values: decisions FR-041 (`dice_roller_exception` here). Duration is recorded on failed calls (FR-031). No log (FR-047; decisions FR-043).
- `Modifier` has no kind tag and `RollModifiers` is structured: decisions FR-001, FR-003. No `basis` attribute: decisions FR-041 (FR-052).
- Heroic Inspiration rerolls are not a command option in phase 1: decisions FR-002, FR-010.
- `ResolveD20Test` is not reusable by other use cases: decisions FR-044 (FR-057). Combat use cases emit no `srd5e.d20_test.*` signals (attacks.md FR-002 and FR-109 already compose `D20TestResolver`).
- Sibling follow-up, not edited here: class-barbarian.md FR-089, FR-093 and FR-115 have `UseRelentlessRage` take and call `ResolveD20Test` (nested span, reliance on FR-036), which FR-057 and decisions FR-044 forbid; it must compose `D20TestResolver` and a `DiceRoller` and record its own signals.
- `roll_mode` is absent for a forced failure (FR-029). Sibling follow-up, not edited here: social-interaction.md FR-043 says `normal` for its forced failure and must follow this convention; attacks.md FR-118 already omits it.

## 10. Changelog impact

Under `Unreleased` / **Added**:

- `ResolveD20Test` use case for ability checks, saving throws and attack rolls (domain types in
  d20-tests.md), returning the sealed `ResolveD20TestResult` (`ResolveD20TestRolledCheck`,
  `ResolveD20TestRolledAttack`, `ResolveD20TestForcedFailure`), with Advantage and Disadvantage,
  natural 20 and natural 1 on attack rolls, saves chosen or forced to fail, and Critical Hit as a
  natural 20 (`AttackRollResult.isCriticalHit`).
- Telemetry signals `srd5e.d20_test.resolve` (span), `srd5e.d20_test.resolved`,
  `srd5e.d20_test.duration`, `srd5e.d20_test.modifiers`, `srd5e.d20_test.natural` and
  `srd5e.d20_test.errors`, with attribute keys `srd5e.d20_test.kind`, `srd5e.ability`,
  `srd5e.d20_test.roll_mode`, `srd5e.outcome`, `srd5e.d20_test.critical_hit`,
  `srd5e.d20_test.roller_failure`, `srd5e.d20_test.forced_failure_reason` and `error.type`, and the
  exported `D20TestSignals` constants.

Not **BREAKING**: new API with no earlier release. From the first release containing it, renaming any
signal name or attribute key above is **BREAKING** (`doc/rules/observability.md` §5).
