# D20 Tests

| | |
|---|---|
| Status | draft |
| Context | `d20_test` |
| Roadmap phase | 1 |
| Depends on | `errors-and-results.md`, `modifiers-and-advantage.md` |

## 1. Purpose and scope

Models the three kinds of D20 Test (ability checks, saving throws, attack
rolls) as defined by SRD 5.2.1: a d20 is rolled (two with Advantage or
Disadvantage), modifiers are added, the total is compared with a target number
(a Difficulty Class or an Armor Class), and the test succeeds or fails. It
covers the natural 20 and natural 1 rules for attack rolls exactly as the SRD
states them, saving throws a creature chooses to fail, automatic failure, and
rerolling or replacing a d20. The results carry the full breakdown so a
consumer can render its own explanation.

**This spec is domain-only and silent.** It owns the pure model of the
`d20_test` context: `D20Roll` (with its reroll and replace-a-die operations),
`RollModifiers`, `DifficultyClass`, `D20TestKind`, `D20TestOutcome`,
`AttackRollResult`, `ArmorClass`, `CheckResult`, `ForcedFailureResult`,
`ForcedFailureReason`, `RerollDecision` and the pure `D20TestResolver` domain
service (shared-types-and-ownership.md FR-002 to FR-004, FR-044). The resolution
rules are here. `D20TestResolver` (FR-069) is the published service other use
cases compose instead of calling `ResolveD20Test`. The use case, the command and
attempt types, `ResolveD20TestResult` and **every signal** are owned by
[resolve-d20-test-use-case.md](resolve-d20-test-use-case.md) (D-17;
shared-types-and-ownership.md FR-017, FR-040, FR-043).

The kernel owns `Modifier`, `RollMode` (`normal`, `advantage`, `disadvantage`),
`RollMode.resolve`, `RollMode.select` and `RollCircumstance`
(shared-types-and-ownership.md FR-001; modifiers-and-advantage.md FR-042). This
spec uses them and does not redefine them. `DiceRoller`, `DiceExpression` and
`RollResult` belong to `dice-and-rolls.md`; the domain never sees them because
dice values arrive as plain integers. This context has no upstream context
(`doc/rules/architecture.md` §2) and imports only `shared_kernel`.

**Out of scope:**

- Deriving an ability modifier from a score (pp. 5-6), the Proficiency Bonus by
  level and Expertise (p. 8): `d20_test` receives finished `Modifier`s. The
  Proficiency Bonus slot holds the already-multiplied value.
- Which skill uses which ability (p. 9), proficiencies, which ability an attack
  uses (p. 7) and Armor Class calculation (p. 7; Cover, p. 15):
  `derived-stats.md`, `attacks.md`. `d20_test` owns only `ArmorClass` as a
  target number.
- Damage, extra Critical Hit dice and half damage on a save (p. 16). This spec
  reports a Critical Hit; `combat` acts on it. Automatic Critical Hits from
  conditions are `conditions.md` and `attacks.md` (shared-types-and-ownership.md
  FR-026); this spec reports only the natural 20.
- Death Saving Throws (pp. 17-18): not tied to an ability score, own natural 1
  and 20 effects; `combat` specifies them.
- Sources of Advantage, Disadvantage and automatic failure, and the Exhaustion
  penalty (p. 181): callers supply circumstances, failure kinds or plain
  `Modifier`s in `RollModifiers.others` (D-10).
- Heroic Inspiration: slot `character-aggregate.md` (FR-089 to FR-091);
  mechanics and new face `heroic-inspiration.md` (shared-types-and-ownership.md
  FR-048; its FR-034 consumes `applyReroll`). This spec takes the reroll
  decision and the new face as input (FR-059).
- The use case, commands, attempt types, `DiceRoller` calls and telemetry:
  resolve-d20-test-use-case.md.
- Whether the GM calls for a D20 Test and the DC set; contested, group and
  passive checks (not in the sections of §2).
- **Not in SRD 5.2.1 as a D20 Test rule, so left out:** automatic success on a
  natural 20 or failure on a natural 1 for ability checks and saving throws; the
  SRD states it for attack rolls only (p. 7).

## 2. Source

PDF page numbers equal printed page numbers. The three steps of a D20 Test are
numbered 4, 5, 6 in the PDF text (list continuation), so this spec cites them by
bold name: "Roll 1d20", "Add Modifiers", "Compare the Total to a Target Number".

- SRD 5.2.1, "The Six Abilities", "Ability Modifiers", pp. 5-6
- SRD 5.2.1, "D20 Tests" (the three steps), p. 6
- SRD 5.2.1, "Ability Checks", "Difficulty Class", Typical Difficulty Classes table, p. 6
- SRD 5.2.1, "Saving Throws", p. 7
- SRD 5.2.1, "Attack Rolls", "Armor Class", "Rolling 20 or 1", p. 7
- SRD 5.2.1, "Advantage/Disadvantage", p. 7; "Roll Two D20s", "They Don't
  Stack", "Interactions with Rerolls", p. 8
- SRD 5.2.1, "Heroic Inspiration" (sidebar, p. 8): "reroll any die immediately
  after rolling it, and you must use the new roll"
- SRD 5.2.1, "Proficiency", "The Bonus Doesn't Stack", p. 8
- SRD 5.2.1, Rules Glossary: "Ability Check", "Advantage", "Armor Class",
  "Attack Roll", "Critical Hit", "D20 Test", "Difficulty Class", "Disadvantage",
  pp. 176-181; "Blinded", p. 177; "Object" ("No Ability Scores"), p. 178;
  "Deafened", p. 181; "Exhaustion", p. 181
- SRD 5.2.1, "Critical Hits", p. 16 (cross-reference only)
- Package design: `doc/rules/architecture.md` §2 to §6,
  `doc/rules/observability.md` §3, `doc/rules/testing.md` §4

## 3. Vocabulary

| SRD term | Type | Notes |
|---|---|---|
| D20 Test | concept; `D20TestKind` | "ability checks, attack rolls, and saving throws" (p. 180) |
| Ability Check / Saving Throw / Attack Roll | `D20TestKind.abilityCheck` / `.savingThrow` / `.attackRoll` | Checks and saves against a DC (pp. 6-7); attack rolls against an AC (p. 7) |
| Difficulty Class (DC) | `DifficultyClass` | Target number of a check or save (p. 6) |
| Armor Class (AC) | `ArmorClass` | Target number of an attack roll (p. 7); owned here (shared-types-and-ownership.md FR-002) |
| Advantage / Disadvantage / neither | kernel `RollMode` | Not redefined here |
| d20 / "the roll" | `D20Roll` | The d20s rolled, the kept die, the natural value |
| natural 20 / natural 1 | `D20Roll.natural` equal to 20 / 1 | Kept d20 before modifiers (p. 7) |
| modifier | kernel `Modifier` | Plain signed integer |
| the modifiers added | `RollModifiers` | One ability modifier, at most one Proficiency Bonus, any number of others (shared-types-and-ownership.md FR-003) |
| Critical Hit | `AttackRollResult.isCriticalHit` | Natural 20, or a d20 at or above the critical range, on an attack roll; it hits (p. 7, p. 49, p. 179) |
| hit / miss | `AttackRollResult.hit` / `D20TestOutcome.failure` | `hit` is `outcome == success` (shared-types-and-ownership.md FR-004) |
| succeeds / fails | `D20TestOutcome.success`, `.failure` | Every kind (p. 6) |
| Heroic Inspiration | not modelled here | See §1; the reroll decision is `RerollDecision` |

Package names that are not SRD terms: `D20TestKind`, `ForcedFailureReason`,
`RerollDecision`, `CheckResult`, `ForcedFailureResult`, `D20TestResolver`. There
is no parallel outcome enum (`AttackOutcome`, `AttackConclusion`,
`AttackRollOutcome`); all kinds use `D20TestOutcome` (shared-types-and-ownership.md
FR-004). `attacks.md` may add richer results under its own names. Terms use SRD
5.2.1 wording exactly (`doc/rules/architecture.md` §3).

## 4. Requirements

Stable ids. Never renumber; new requirements get new ids. Withdrawn ids are
listed at the end of this section and have no test here.

### 4.1 Roll mode (owned by the kernel)

`D20Roll` only calls `RollMode.select` (FR-011); the mode rules are
modifiers-and-advantage.md.

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-009 | A `D20Roll` MUST reject any die value outside 1 to 20 with `ArgumentError`, at construction and in `replaceDie` (FR-012, FR-014). At construction the range check is the kernel's `RollMode.select` behaviour (modifiers-and-advantage.md FR-027), not reimplemented; `replaceDie` pre-validates `value` itself (FR-014). | SRD 5.2.1, "Roll 1d20", p. 6 | unhappy (invalid input) |
| FR-010 | A `D20Roll` MUST hold exactly `mode.diceCount` dice: one for `normal`, two for `advantage` and `disadvantage`. Any other count throws `ArgumentError` (modifiers-and-advantage.md FR-026). | SRD 5.2.1, "Roll Two D20s", "They Don't Stack", p. 8 | unhappy (invalid input) |
| FR-011 | `D20Roll.natural` MUST be the number `RollMode.select` returns: the higher die under `advantage`, the lower under `disadvantage`, the only die under `normal`. Both dice stay visible in `D20Roll.dice`. Equal dice give that value (modifiers-and-advantage.md FR-021 to FR-025). | SRD 5.2.1, "Roll Two D20s", p. 8 | happy; unhappy (boundary) at equal dice |

### 4.2 The roll: kept die, rerolls and replaced dice

SRD 5.2.1 p. 8 ("Interactions with Rerolls"): when something lets you reroll or
replace the d20 under Advantage or Disadvantage, you can do so for "only one die,
not both", and you choose which. Heroic Inspiration's reroll must use the new
roll (p. 8). Rerolls are operations on the roll, so they live with `D20Roll`
(shared-types-and-ownership.md FR-002). A decision names one index (FR-059).
`D20Roll` keeps no hidden "already replaced" state (FR-067), so the SRD limit of
one replaced die per roll is the callers' responsibility, not enforced by this
type.

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-012 | `D20Roll.replaceDie(index, value)` MUST return a new `D20Roll` with the die at `index` set to `value`, the same `mode`, and `natural` re-selected with `RollMode.select`. Example: dice `[18, 3]` under advantage, replace index 0 with 2, gives dice `[2, 3]` and natural 3. | SRD 5.2.1, "Interactions with Rerolls", p. 8 | happy |
| FR-013 | A single `replaceDie` call MUST change exactly one die: every other die keeps its value, in its position. | SRD 5.2.1, "Interactions with Rerolls", p. 8 ("only one die, not both") | unhappy (rule interaction) |
| FR-014 | `replaceDie` MUST validate `index` and `value` itself: an index outside `0` to `dice.length - 1` (negative, equal to the length, or any index under `normal` other than 0) or a value outside 1 to 20 MUST throw `ArgumentError` (name `index` or `value`). The constructor instead re-throws the kernel's `select` error under name `dice`. | `doc/rules/testing.md` §4 | unhappy (invalid input) |
| FR-015 | `replaceDie` and `applyReroll` MUST NOT alter the original `D20Roll`; the original's `dice`, `natural` and `keptIndex` are unchanged, and `dice` is unmodifiable (`UnsupportedError` on mutation). | `doc/rules/architecture.md` §3 | unhappy (immutability) |
| FR-055 | A `D20Roll` built from a mode and the face values in the order rolled MUST select its `natural` with the kernel `RollMode.select`. `[18, 3]` under advantage gives natural 18, kept index 0; under disadvantage, natural 3, kept index 1. | SRD 5.2.1, "Roll Two D20s", p. 8; modifiers-and-advantage.md FR-021 to FR-023 | happy |
| FR-058 | `D20Roll.keptIndex` MUST be the index of the kept die: the first index whose value equals `natural`. For equal dice that is index 0. After `replaceDie` it is recomputed. | SRD 5.2.1, "Roll Two D20s", p. 8; package design (D-15) | unhappy (boundary: equal dice) |
| FR-059 | `RerollDecision` MUST be a sealed type with `KeepRoll` and `RerollDie(dieIndex)`. `D20Roll.applyReroll(decision, {newValue})` MUST return the roll unchanged for `KeepRoll` (rejecting a supplied `newValue` with `ArgumentError`), and for `RerollDie` MUST return `replaceDie(dieIndex, newValue)`, requiring a `newValue`. The new value is used even when lower than the old one. | SRD 5.2.1, "Interactions with Rerolls", "Heroic Inspiration", p. 8 | happy; unhappy (rule interaction: lower new value kept; invalid input) |
| FR-067 | Package design: `D20Roll` MUST keep no "already replaced" state, so a second `replaceDie` on a replaced roll is allowed and returns a valid roll. **The SRD limit "only one die, not both" (p. 8) is enforced by the caller**, not by this type. | package design (D-20); limit: SRD 5.2.1, "Interactions with Rerolls", p. 8 | unhappy (state errors) |
| FR-068 | `D20Roll` MUST hold an unmodifiable copy of the dice list it is given: mutating the source list afterwards MUST NOT change `dice`, `natural` or `keptIndex`. Each result of `replaceDie` and `applyReroll` has its own list. | `doc/rules/architecture.md` §3, §4; `doc/rules/testing.md` §4 | unhappy (immutability) |

Reroll cases (table-driven; build the roll, apply the operation, assert dice,
natural and kept index). Sources: SRD 5.2.1 p. 8 for reroll, replace and dice
count rows, p. 6 for the 1 to 20 range (value and die 0/21/negative rows),
`testing.md` §4 for invalid-input rows.

| Case label | Mode, dice | Operation | Expected dice | Expected natural, kept index | Path |
|---|---|---|---|---|---|
| replace the higher die, advantage | advantage, [18, 3] | `replaceDie(0, 2)` | [2, 3] | 3, 1 | happy |
| replace the lower die, advantage | advantage, [18, 3] | `replaceDie(1, 19)` | [18, 19] | 19, 1 | happy |
| replace the unused die, no change to natural | advantage, [18, 3] | `replaceDie(1, 5)` | [18, 5] | 18, 0 | unhappy (rule interaction) |
| replace under disadvantage | disadvantage, [18, 3] | `replaceDie(1, 20)` | [18, 20] | 18, 0 | unhappy (rule interaction) |
| replace the single die | normal, [7] | `replaceDie(0, 20)` | [20] | 20, 0 | happy |
| replacement to equal dice | advantage, [18, 3] | `replaceDie(0, 3)` | [3, 3] | 3, 0 | unhappy (boundary) |
| replacement to the minimum | normal, [20] | `replaceDie(0, 1)` | [1] | 1, 0 | unhappy (boundary) |
| replacement to the maximum | normal, [1] | `replaceDie(0, 20)` | [20] | 20, 0 | unhappy (boundary) |
| replacement twice (caller enforces the SRD limit) | advantage, [18, 3] | `replaceDie(0, 2)` then `replaceDie(1, 9)` | [2, 9] | 9, 1 | unhappy (state errors) |
| source list mutated after construction | advantage, list `[18, 3]` | construct, then set source `[0] = 1` | `dice` [18, 3] | 18, 0 | unhappy (immutability) |
| `applyReroll` leaves the original | advantage, [18, 3] | `applyReroll(RerollDie(0), newValue: 2)` | original [18, 3]; result [2, 3] | original 18, 0; result 3, 1 | unhappy (immutability) |
| index equal to length | advantage, [18, 3] | `replaceDie(2, 5)` | `ArgumentError` (name `index`) | n/a | unhappy (invalid input) |
| negative index | advantage, [18, 3] | `replaceDie(-1, 5)` | `ArgumentError` (name `index`) | n/a | unhappy (invalid input) |
| index 1 under normal | normal, [7] | `replaceDie(1, 5)` | `ArgumentError` (name `index`) | n/a | unhappy (invalid input) |
| value 0 | normal, [7] | `replaceDie(0, 0)` | `ArgumentError` (name `value`) | n/a | unhappy (boundary) |
| value 21 | normal, [7] | `replaceDie(0, 21)` | `ArgumentError` (name `value`) | n/a | unhappy (boundary) |
| reroll lower than before is kept | normal, [15] | `applyReroll(RerollDie(0), newValue: 2)` | [2] | 2, 0 | unhappy (rule interaction) |
| keep the roll | advantage, [18, 3] | `applyReroll(KeepRoll)` | [18, 3] | 18, 0 | happy |
| keep with a new value | advantage, [18, 3] | `applyReroll(KeepRoll, newValue: 5)` | `ArgumentError` (name `newValue`) | n/a | unhappy (invalid input) |
| reroll without a new value | advantage, [18, 3] | `applyReroll(RerollDie(0))` | `ArgumentError` (name `newValue`) | n/a | unhappy (invalid input) |
| wrong die count for the mode | advantage, [18] | construct | `ArgumentError` (name `dice`) | n/a | unhappy (invalid input) |
| three dice | advantage, [1, 2, 3] | construct | `ArgumentError` (name `dice`) | n/a | unhappy (invalid input) |
| equal dice | advantage, [9, 9] | construct | [9, 9] | 9, 0 | unhappy (boundary) |
| construct with a die of 0 | advantage, [0, 5] | construct | `ArgumentError` (name `dice`) | n/a | unhappy (boundary) |
| construct with a die of 21 | advantage, [5, 21] | construct | `ArgumentError` (name `dice`) | n/a | unhappy (boundary) |
| construct with a negative die | normal, [-3] | construct | `ArgumentError` (name `dice`) | n/a | unhappy (invalid input) |
| normal with two dice | normal, [7, 8] | construct | `ArgumentError` (name `dice`) | n/a | unhappy (invalid input) |
| no dice under advantage | advantage, [] | construct | `ArgumentError` (name `dice`) | n/a | unhappy (empty and minimal) |
| normal with one die | normal, [7] | construct | [7] | 7, 0 | happy |

### 4.3 Modifiers and the total

`RollModifiers(ability: Modifier, proficiencyBonus: Modifier?, others:
Iterable<Modifier>)` (shared-types-and-ownership.md FR-003) enforces by shape
every "at most one of X" rule, so no runtime check exists. The slots hold kernel
`Modifier`s (plain integers), not `AbilityModifier` or `character`'s
`ProficiencyBonus` (D-16); a caller converts with
`Modifier(abilityModifier.value)`. In the tables a modifier set is written
`A+3 P+2 O[+1, -2]`: `A` the ability modifier (always present; `A+0` is "none"),
`P` the Proficiency Bonus (omitted when absent), `O` the other modifiers
(omitted when empty).

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-016 | The total of a rolled D20 Test MUST equal `D20Roll.natural` plus the kernel sum of the ability modifier, the Proficiency Bonus (when present) and every other modifier, with no clamping: a total MAY be below 1 or above 20. | SRD 5.2.1, "Add Modifiers", p. 6; modifiers-and-advantage.md FR-004, FR-008 | happy |
| FR-017 | `RollModifiers` MUST require exactly one ability modifier (non-optional constructor parameter) and MUST accept any number of other modifiers, including none. With only the ability modifier, the total is the natural value plus that modifier. | SRD 5.2.1, "Add Modifiers", p. 6; modifiers-and-advantage.md FR-005 | unhappy (empty and minimal) |
| FR-018 | `RollModifiers` MUST hold at most one Proficiency Bonus (a single nullable slot), so it cannot be added twice. It MUST NOT apply any other stacking rule. | SRD 5.2.1, "The Bonus Doesn't Stack", p. 8 | unhappy (rule interaction) |
| FR-019 | Modifiers MAY be positive, zero or negative, in any mix, and a total MAY be zero or negative. | SRD 5.2.1, "Add Modifiers" (Circumstantial Bonuses and Penalties), p. 6 | happy; unhappy (empty and minimal) |
| FR-020 | The total MUST NOT depend on the order in which the other modifiers are listed. | SRD 5.2.1, "Add Modifiers", p. 6; modifiers-and-advantage.md FR-007 | unhappy (determinism) |
| FR-061 | `RollModifiers` MUST hold an unmodifiable copy of `others`: mutating the caller's list afterwards MUST NOT change the value, and mutating the exposed list MUST throw `UnsupportedError`. Default `others` is empty. | `doc/rules/architecture.md` §3, §4 | unhappy (immutability; empty and minimal) |

Total cases (source SRD 5.2.1 p. 6):

| Case label | Natural | Modifiers | Expected total | Path |
|---|---|---|---|---|
| ability only, zero | 10 | `A+0` | 10 | unhappy (empty and minimal) |
| zero other modifier | 10 | `A+0 O[0]` | 10 | unhappy (empty and minimal) |
| single bonus | 10 | `A+3` | 13 | happy |
| ability and Proficiency Bonus | 10 | `A+3 P+2` | 15 | happy |
| bonuses and penalties | 10 | `A+3 P+2 O[+1, -2]` | 14 | happy |
| negative modifier | 5 | `A-5` | 0 | unhappy (boundary) |
| total below zero | 1 | `A-5 O[-2]` | -6 | unhappy (boundary) |
| total above 20 | 20 | `A+10` | 30 | unhappy (boundary) |
| other modifiers reordered, first order | 10 | `A+3 O[-2, +2]` | 13 | unhappy (determinism) |
| other modifiers reordered, second order | 10 | `A+3 O[+2, -2]` | 13 | unhappy (determinism) |
| very large bonus | 1 | `A+100` | 101 | unhappy (boundary) |
| very large penalty | 20 | `A-100` | -80 | unhappy (boundary) |

### 4.4 Target numbers

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-021 | `DifficultyClass` MUST be a value object wrapping an integer, with named constants for the Typical Difficulty Classes: Very easy 5, Easy 10, Medium 15, Hard 20, Very hard 25, Nearly impossible 30. | SRD 5.2.1, Typical Difficulty Classes table, p. 6 | happy |
| FR-022 | `DifficultyClass` and `ArmorClass` MUST compare equal by value within their own type, and MUST NOT compare equal to each other for the same number. | `doc/rules/architecture.md` §3; the SRD names the two target numbers, pp. 6-7 | unhappy (boundary) |

The SRD gives no minimum or maximum for a DC or an AC, so neither type rejects
any integer (D-02). Cases: `DifficultyClass.veryEasy == DifficultyClass(5)`,
`.easy == (10)`, `.medium == (15)`, `.hard == (20)`, `.veryHard == (25)`,
`.nearlyImpossible == (30)`, `DifficultyClass(10) != ArmorClass(10)`,
`DifficultyClass(10) == DifficultyClass(10)`, `ArmorClass(10) == ArmorClass(10)`,
`DifficultyClass(10) != DifficultyClass(11)`, equal `hashCode` for equal values.

### 4.5 Success and failure resolution

The entry points are the methods of the pure `D20TestResolver` (FR-069):
`resolveCheck(kind, roll, modifiers, target)`, `resolveAttackRoll(roll,
modifiers, target)` and `forcedFailure(kind, reason)`. The result types publish
delegating static members (D-18, FR-070): `CheckResult.resolve`,
`AttackRollResult.resolve`, `ForcedFailureResult.of`. Both forms behave
identically and accept any `D20Roll`, including a rerolled or replaced one.

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-023 | An ability check whose total equals or exceeds the DC MUST resolve to `D20TestOutcome.success`. | SRD 5.2.1, "Compare the Total to a Target Number", p. 6 | happy; unhappy (boundary) at equal |
| FR-024 | An ability check whose total is below the DC MUST resolve to `failure`. | SRD 5.2.1, "Compare the Total to a Target Number", p. 6 | happy; unhappy (boundary) at one below |
| FR-025 | A saving throw whose total equals or exceeds the DC MUST resolve to `success`. | SRD 5.2.1, "Compare the Total to a Target Number", p. 6; "Saving Throws", p. 7 | happy; unhappy (boundary) at equal |
| FR-026 | A saving throw whose total is below the DC MUST resolve to `failure`. | SRD 5.2.1, "Compare the Total to a Target Number", p. 6; "Saving Throws", p. 7 | happy; unhappy (boundary) at one below |
| FR-027 | An attack roll whose natural value is neither 1 nor 20 and whose total equals or exceeds the AC MUST resolve to `success` (`hit` true) with `isCriticalHit` false. | SRD 5.2.1, "Attack Rolls", p. 7 | happy; unhappy (boundary) at equal |
| FR-028 | An attack roll whose natural value is neither 1 nor 20 and whose total is below the AC MUST resolve to `failure` (a miss) with `isCriticalHit` false. | SRD 5.2.1, "Attack Rolls", p. 7 | happy; unhappy (boundary) at one below |
| FR-029 | An attack roll with a natural 20 MUST resolve to `success` with `isCriticalHit` true, regardless of modifiers or the AC and of any critical range (FR-071). | SRD 5.2.1, "Rolling 20 or 1", p. 7; "Critical Hit", p. 179 | unhappy (boundary) |
| FR-030 | An attack roll with a natural 1 MUST resolve to `failure` with `isCriticalHit` false, regardless of modifiers or the AC. | SRD 5.2.1, "Rolling 20 or 1", p. 7 | unhappy (boundary) |
| FR-031 | The natural 20 and natural 1 rules MUST apply to attack rolls only. A check or save MUST resolve by comparing its total with the DC alone, whatever the natural value, and a `CheckResult` has no critical-hit field. | SRD 5.2.1, "Rolling 20 or 1", p. 7 ("for an attack roll") | unhappy (rule interaction) |
| FR-032 | Under `advantage` or `disadvantage`, the natural 20 and natural 1 rules MUST be judged on `D20Roll.natural` (the kept die), not the discarded one. | SRD 5.2.1, "Roll Two D20s", p. 8; "Rolling 20 or 1", p. 7 | unhappy (rule interaction) |
| FR-033 | With the default critical range (20), a natural 19 MUST NOT be a Critical Hit: it resolves by its total. | SRD 5.2.1, "Rolling 20 or 1", p. 7 | unhappy (boundary) |
| FR-034 | `AttackRollResult` MUST carry its `D20Roll`, `RollModifiers`, total, `ArmorClass` target, `D20TestOutcome` and `isCriticalHit`, and expose `hit` as `outcome == D20TestOutcome.success`. There is no basis enum and no `criticalHit` outcome. | SRD 5.2.1, "Attack Rolls", p. 7; `doc/rules/architecture.md` §6 | happy |
| FR-035 | A saving throw the creature chooses to fail MUST resolve to `failure` with no `D20Roll`, and the result MUST say so (`ForcedFailureReason.chosenToFail`). `forcedFailure(kind, reason)` produces it. | SRD 5.2.1, "Saving Throws", p. 7 ("you can choose to fail the save without rolling") | happy |
| FR-036 | A check or save declared an automatic failure by the caller MUST resolve to `failure` with no `D20Roll`, reason `ForcedFailureReason.automatic`. Sources the caller may rely on: a check that requires sight while Blinded (p. 177) or hearing while Deafened (p. 181), and, for saving throws only, an object with no ability scores ("fails all saving throws", p. 178; it "can't make ability checks", so objects are not a source for checks). | SRD 5.2.1, "Blinded", p. 177; "Deafened", p. 181; "Object", p. 178 | happy |
| FR-063 | `CheckResult.resolve(kind, roll, modifiers, target)` MUST be a published static member that resolves any `D20Roll` (fresh, rerolled or replaced) exactly as FR-016 and FR-023 to FR-026 say, so downstream domain code gets an outcome from a rerolled roll without the use case. It rejects `attackRoll` (FR-062). | SRD 5.2.1, "Interactions with Rerolls", "Heroic Inspiration", p. 8; D-18 | happy; unhappy (rule interaction) |
| FR-064 | `AttackRollResult.resolve(roll, modifiers, target)` MUST be a published static member that resolves any `D20Roll`, including a rerolled or replaced one, by FR-027 to FR-033, judging the natural 20 and natural 1 on the roll's current `natural`. | SRD 5.2.1, "Rolling 20 or 1", p. 7; "Interactions with Rerolls", p. 8; D-18 | happy; unhappy (rule interaction) |
| FR-065 | `CheckResult.adjustedBy(int delta)` and `AttackRollResult.adjustedBy(int delta)` MUST return a new result for the same roll and target with `Modifier(delta)` appended to `modifiers.others`, the total re-derived (FR-016) and the outcome re-resolved by the rules of `resolve`. The original is unchanged. A delta of 0 is allowed. `ForcedFailureResult` has no `adjustedBy`. Effects that add or subtract after the roll (Bardic Inspiration, Cutting Words) call it. | SRD 5.2.1, "Add Modifiers", p. 6; D-18 | happy; unhappy (boundary; immutability) |
| FR-066 | After `adjustedBy`, an attack roll MUST still be judged on its natural value: a natural 20 stays a hit and a Critical Hit and a natural 1 stays a miss at any total; a natural 20 or 1 on a check or save stays irrelevant (FR-031). | SRD 5.2.1, "Rolling 20 or 1", p. 7 | unhappy (boundary; rule interaction) |

Check and save resolution (identical rows for each kind; one table-driven test
per row per kind). Source SRD 5.2.1 p. 6; rows with "natural 20" or "natural 1"
in the label also p. 7 (no natural rule for checks and saves).

| Case label | Natural | Modifiers | Total | DC | Expected | Path |
|---|---|---|---|---|---|---|
| total equals the DC | 10 | `A+3 P+2` | 15 | 15 | success | unhappy (boundary) |
| total one below the DC | 10 | `A+4` | 14 | 15 | failure | unhappy (boundary) |
| total one above the DC | 10 | `A+6` | 16 | 15 | success | unhappy (boundary) |
| well above | 15 | `A+5 P+3` | 23 | 10 | success | happy |
| well below | 3 | `A+0` | 3 | 20 | failure | happy |
| ability only meets the DC | 15 | `A+0` | 15 | 15 | success | unhappy (empty and minimal) |
| natural 20 below the DC fails | 20 | `A-6` | 14 | 15 | failure | unhappy (rule interaction) |
| natural 20 short of a high DC | 20 | `A+0` | 20 | 30 | failure | unhappy (rule interaction) |
| natural 1 above the DC succeeds | 1 | `A+10 O[+4]` | 15 | 15 | success | unhappy (rule interaction) |
| natural 20 reaches DC 30 | 20 | `A+10` | 30 | 30 | success | unhappy (boundary) |
| negative total | 1 | `A-5 O[-2]` | -6 | 5 | failure | unhappy (boundary) |
| DC 5, very easy, low roll | 2 | `A+3` | 5 | 5 | success | unhappy (boundary) |
| very large bonus | 1 | `A+100` | 101 | 30 | success | unhappy (boundary) |
| very large penalty | 20 | `A-100` | -80 | 5 | failure | unhappy (boundary) |

Attack roll resolution (SRD 5.2.1 p. 7; rows labelled Advantage or Disadvantage
also p. 8 for the kept die; the dice column shows both dice when the mode is not `normal`):

| Case label | Mode, dice | Natural | Modifiers | Total | AC | Expected outcome | `isCriticalHit` | Path |
|---|---|---|---|---|---|---|---|---|
| total equals the AC | normal, 10 | 10 | `A+3 P+2` | 15 | 15 | success | false | unhappy (boundary) |
| total one below the AC | normal, 10 | 10 | `A+4` | 14 | 15 | failure | false | unhappy (boundary) |
| total one above the AC | normal, 10 | 10 | `A+6` | 16 | 15 | success | false | unhappy (boundary) |
| natural 20 beats any AC | normal, 20 | 20 | `A+0` | 20 | 15 | success | true | unhappy (boundary) |
| natural 20, total far below AC | normal, 20 | 20 | `A-5` | 15 | 30 | success | true | unhappy (boundary) |
| natural 20, total equals AC | normal, 20 | 20 | `A+5` | 25 | 25 | success | true | unhappy (boundary) |
| natural 20, total above AC | normal, 20 | 20 | `A+10` | 30 | 15 | success | true | unhappy (boundary) |
| natural 1 misses a low AC | normal, 1 | 1 | `A+12` | 13 | 10 | failure | false | unhappy (boundary) |
| natural 1, total far above AC | normal, 1 | 1 | `A+20` | 21 | 5 | failure | false | unhappy (boundary) |
| natural 1, total also below AC | normal, 1 | 1 | `A+2` | 3 | 15 | failure | false | unhappy (boundary) |
| natural 19 one below AC | normal, 19 | 19 | `A+0` | 19 | 20 | failure | false | unhappy (boundary) |
| natural 19 above AC is not critical | normal, 19 | 19 | `A+10` | 29 | 20 | success | false | unhappy (boundary) |
| range 19: natural 19 crits below AC | normal, 19; `criticalRange` 19 | 19 | `A-5` | 14 | 30 | success | true | unhappy (boundary) |
| range 19: natural 18 does not | normal, 18; `criticalRange` 19 | 18 | `A+0` | 18 | 30 | failure | false | unhappy (boundary) |
| range 18: natural 18 crits below AC | normal, 18; `criticalRange` 18 | 18 | `A+0` | 18 | 30 | success | true | unhappy (boundary) |
| range 18: natural 17 does not | normal, 17; `criticalRange` 18 | 17 | `A+0` | 17 | 30 | failure | false | unhappy (boundary) |
| range 18: natural 20 and natural 1 | normal, 20 / 1; `criticalRange` 18 | 20 / 1 | `A+0` | 20 / 1 | 30 | success / failure | true / false | unhappy (boundary) |
| range 17 or 21 | `criticalRange` 17, 21 | any | any | any | any | `ArgumentError` (name `criticalRange`) | none | unhappy (invalid input) |
| natural 2 above AC | normal, 2 | 2 | `A+10 O[+4]` | 16 | 15 | success | false | happy |
| Advantage dice 20 and 1 | advantage, 20 and 1 | 20 | `A+0` | 20 | 15 | success | true | unhappy (rule interaction) |
| Disadvantage dice 20 and 1 | disadvantage, 20 and 1 | 1 | `A+20` | 21 | 5 | failure | false | unhappy (rule interaction) |
| Advantage dice 1 and 1 | advantage, 1 and 1 | 1 | `A+20` | 21 | 5 | failure | false | unhappy (boundary) |
| Disadvantage dice 20 and 20 | disadvantage, 20 and 20 | 20 | `A-3` | 17 | 30 | success | true | unhappy (boundary) |
| Advantage dice 12 and 5 | advantage, 12 and 5 | 12 | `A+3` | 15 | 15 | success | false | happy |
| Advantage, natural 1 discarded | advantage, 1 and 12 | 12 | `A+3` | 15 | 15 | success | false | unhappy (rule interaction) |
| very large bonus | normal, 10 | 10 | `A+100` | 110 | 30 | success | false | unhappy (boundary) |
| natural 20, very large penalty | normal, 20 | 20 | `A-100` | -80 | 10 | success | true | unhappy (boundary) |
| natural 1, very large bonus | normal, 1 | 1 | `A+100` | 101 | 10 | failure | false | unhappy (boundary) |

Re-resolution after a reroll or adjustment (FR-063 to FR-066). Each row builds
the original result, then applies the operation. Source SRD 5.2.1 p. 6 (check
rows), p. 7 (attack rows; "natural 20 check adjusted below the DC" p. 6 and
p. 7), p. 8 (rows using `replaceDie`).

| Case label | Original | Operation | Expected | Path |
|---|---|---|---|---|
| attack rerolled from a miss to a hit | attack, advantage, [4, 3], `A+3`, AC 15 (total 7, failure) | `AttackRollResult.resolve` with `replaceDie(0, 14)` roll | natural 14, total 17, success, not critical | happy |
| attack replaced to a natural 20 | attack, normal, [5], `A+0`, AC 30 | resolve with `replaceDie(0, 20)` | success, `isCriticalHit` true | unhappy (rule interaction) |
| attack replaced to a natural 1 | attack, normal, [18], `A+10`, AC 10 | resolve with `replaceDie(0, 1)` | failure, `isCriticalHit` false | unhappy (rule interaction) |
| check rerolled | check, normal, [3], `A+2`, DC 10 | `CheckResult.resolve` with `replaceDie(0, 19)` | total 21, success | happy |
| adjusted check up to the DC | check, normal, [8], `A+1`, DC 15 (total 9) | `adjustedBy(+6)` | total 15, success; `others` gains `+6` | unhappy (boundary) |
| adjusted check down one below | check, normal, [10], `A+5`, DC 15 (total 15) | `adjustedBy(-1)` | total 14, failure | unhappy (boundary) |
| adjusted by zero | check, normal, [10], `A+5`, DC 15 | `adjustedBy(0)` | equal to a result with `others` `[0]`; total 15, success | unhappy (empty and minimal) |
| natural 20 attack adjusted far down | attack, normal, [20], `A+0`, AC 15 | `adjustedBy(-100)` | total -80, success, `isCriticalHit` true | unhappy (boundary) |
| natural 1 attack adjusted far up | attack, normal, [1], `A+0`, AC 5 | `adjustedBy(+100)` | total 101, failure, `isCriticalHit` false | unhappy (boundary) |
| natural 19 attack adjusted onto the AC | attack, normal, [19], `A+0`, AC 25 | `adjustedBy(+6)` | total 25, success, not critical | unhappy (boundary) |
| natural 20 check adjusted below the DC | check, normal, [20], `A+0`, DC 15 | `adjustedBy(-6)` | total 14, failure (no natural 20 rule) | unhappy (rule interaction) |
| adjustment leaves the original | any row above | `adjustedBy(n)` | original result unchanged | unhappy (immutability) |
| rerolled roll for a save | save, advantage, [18, 3], `A+0`, DC 15 | resolve with `replaceDie(0, 2)` | natural 3, total 3, failure | unhappy (rule interaction) |
| `CheckResult.resolve` with attackRoll | kind `attackRoll`, normal, [10], `A+0`, DC 15 | `CheckResult.resolve` | `ArgumentError` (name `kind`) | unhappy (invalid input) |

Forced failure (FR-035, FR-036, FR-052):

| Case label | Kind | Reason | Expected | Source | Path |
|---|---|---|---|---|---|
| chosen to fail a save | savingThrow | chosenToFail | failure, reason chosenToFail, no roll | p. 7 | happy |
| automatic failure of a save | savingThrow | automatic | failure, reason automatic, no roll | p. 178 | happy |
| automatic failure of a check | abilityCheck | automatic | failure, reason automatic, no roll | p. 177, p. 181 | happy |
| chosen to fail a check | abilityCheck | chosenToFail | `ArgumentError` (name `reason`) | p. 6 (no such rule) | unhappy (invalid input) |
| forced failure of an attack roll | attackRoll | automatic | `ArgumentError` (name `kind`) | p. 7 (no such rule) | unhappy (invalid input) |
| forced failure of an attack roll, chosen | attackRoll | chosenToFail | `ArgumentError` (name `kind`) | p. 7 (no such rule) | unhappy (invalid input) |

### 4.6 Result shape, value semantics and guards

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-041 | A rolled `CheckResult` MUST carry its kind, `D20Roll`, `RollModifiers`, total, `DifficultyClass` target and `D20TestOutcome`; an `AttackRollResult` carries what FR-034 lists; a `ForcedFailureResult` MUST carry its kind and `ForcedFailureReason` and no roll. Collections reachable from a result MUST be unmodifiable. A result carries no `Ability` and no separate roll-mode field: the mode is `D20Roll.mode` (D-19). | `doc/rules/architecture.md` §6, §4 | happy; unhappy (immutability) |
| FR-050 | `DifficultyClass`, `ArmorClass`, `D20Roll`, `RollModifiers`, the `RerollDecision` variants, `CheckResult`, `AttackRollResult` and `ForcedFailureResult` MUST each be equal, with equal hash codes, when every field is equal, and unequal when any single field differs (including collection contents and order). | `doc/rules/architecture.md` §3 | happy; unhappy (any differing field) |
| FR-051 | For an attack roll with a natural 20, `isCriticalHit` MUST be true, and with a natural 1 it MUST be false and the outcome `failure`, even when the total alone would give the other outcome (nat 20 with total below AC; nat 1 with total at or above AC). | SRD 5.2.1, "Rolling 20 or 1", p. 7; `doc/rules/architecture.md` §6 | unhappy (rule interaction) |
| FR-052 | `forcedFailure(kind, reason)` MUST reject with `ArgumentError` an attack roll (any reason) and an ability check with reason `chosenToFail`. | SRD 5.2.1, "Saving Throws", p. 7; `doc/rules/testing.md` §4 | unhappy (invalid input) |
| FR-060 | `D20TestOutcome` MUST be exactly `success` and `failure` for every kind, and `isCriticalHit` MUST exist only on `AttackRollResult`. No `criticalHit` outcome and no `AttackOutcome`, `AttackConclusion` or `AttackRollOutcome` enum is exported. | shared-types-and-ownership.md FR-004; SRD 5.2.1, "Rolling 20 or 1", p. 7 | happy |
| FR-062 | `resolveCheck` MUST reject a kind of `attackRoll` with `ArgumentError`. A DC cannot be paired with an attack roll, nor an AC with a check or save, because the target parameter types differ. | SRD 5.2.1, "Ability Checks", p. 6; "Attack Rolls", p. 7; `doc/rules/testing.md` §4 | unhappy (invalid input) |
| FR-069 | `D20TestResolver` MUST be a published, stateless, `const`-constructible pure domain service in `lib/src/d20_test/domain/`, exported from the `d20_test` barrel and `lib/srd5e.dart`, with exactly three methods: `resolveCheck` (FR-063, FR-062), `resolveAttackRoll` (FR-064) and `forcedFailure` (FR-035, FR-036, FR-052). It takes no port, no `Observability` and no dice. Other use cases compose it and record their own signals from its results (shared-types-and-ownership.md FR-044). | shared-types-and-ownership.md FR-002, FR-044; `doc/rules/architecture.md` §4 | happy; unhappy (invalid input: delegated ArgumentError rows) |
| FR-070 | `CheckResult.resolve`, `AttackRollResult.resolve` and `ForcedFailureResult.of` MUST delegate to `D20TestResolver` and return equal results for equal inputs, including the same `ArgumentError` for the same invalid input. `adjustedBy` (FR-065) stays a method of the results. | package design (D-18, D-21) | happy; unhappy (rule interaction) |
| FR-071 | `D20TestResolver.resolveAttackRoll` and `AttackRollResult.resolve` MUST take an optional named `int criticalRange` (default 20). A roll whose `natural` is at or above it MUST resolve to `success` with `isCriticalHit` true regardless of modifiers or AC (FR-029); below it, FR-027, FR-028 and FR-030 apply. A natural 20 is always a Critical Hit and a natural 1 never is, whatever the range. | SRD 5.2.1, "Critical Hit", p. 179; Fighter "Level 3: Improved Critical", "Level 15: Superior Critical", p. 49 | happy; unhappy (boundary at 19 and 18) |
| FR-072 | `criticalRange` MUST be 18, 19 or 20; any other value MUST throw `ArgumentError` (name `criticalRange`). Interpretation: the lowest range the SRD grants is 18-20 (p. 49), so a wider one is a caller bug. Checks and saves take no range (FR-031). | SRD 5.2.1, p. 49; `doc/rules/testing.md` §4 | unhappy (invalid input) |
| FR-073 | `AttackRollResult` MUST also carry `criticalRange` (default 20), included in equality (FR-050); `adjustedBy` MUST re-resolve with it, so a natural at or above the range stays a Critical Hit at any total (FR-066). | SRD 5.2.1, p. 179; package design | happy; unhappy (rule interaction) |

### 4.7 Withdrawn ids

Kept so references stay valid; no test here.

| Id | Withdrawn |
|---|---|
| FR-001 | Withdrawn: moved to modifiers-and-advantage.md (FR-010, FR-018) |
| FR-002 | Withdrawn: moved to modifiers-and-advantage.md (FR-011, FR-019) |
| FR-003 | Withdrawn: moved to modifiers-and-advantage.md (FR-012, FR-020) |
| FR-004 | Withdrawn: moved to modifiers-and-advantage.md (FR-013) |
| FR-005 | Withdrawn: moved to modifiers-and-advantage.md (FR-014) |
| FR-006 | Withdrawn: moved to modifiers-and-advantage.md (FR-015, FR-016) |
| FR-007 | Withdrawn: moved to modifiers-and-advantage.md (FR-010) |
| FR-008 | Withdrawn: moved to modifiers-and-advantage.md (FR-010 to FR-017) |
| FR-037 | Withdrawn: moved to resolve-d20-test-use-case.md (dice requested) |
| FR-038 | Withdrawn: moved to resolve-d20-test-use-case.md (port failure) |
| FR-039 | Withdrawn: moved to resolve-d20-test-use-case.md (invalid roller result) |
| FR-040 | Withdrawn: moved to resolve-d20-test-use-case.md (determinism) |
| FR-042 | Withdrawn: moved to resolve-d20-test-use-case.md (command not altered) |
| FR-043 | Withdrawn: moved to resolve-d20-test-use-case.md (counter) |
| FR-044 | Withdrawn: moved to resolve-d20-test-use-case.md (span) |
| FR-045 | Withdrawn: moved to resolve-d20-test-use-case.md (duration histogram) |
| FR-046 | Withdrawn: moved to resolve-d20-test-use-case.md (modifiers histogram) |
| FR-047 | Withdrawn: moved to resolve-d20-test-use-case.md (error recording) |
| FR-048 | Withdrawn: moved to resolve-d20-test-use-case.md (no-op and recording identity) |
| FR-049 | Withdrawn: moved to resolve-d20-test-use-case.md (constants) |
| FR-053 | Withdrawn: moved to resolve-d20-test-use-case.md (forced failure signal) |
| FR-054 | Withdrawn: moved to resolve-d20-test-use-case.md (attribute values) |
| FR-056 | Withdrawn: moved to resolve-d20-test-use-case.md (roller `Error` propagates) |
| FR-057 | Withdrawn: moved to resolve-d20-test-use-case.md (command defaults and copies; live domain equivalents FR-061, FR-068) |

## 5. Model

Layout (`doc/rules/architecture.md` §4): `lib/src/d20_test/domain/` holds
everything in this spec; it is pure, synchronous, immutable (`@immutable`,
`final` fields) and imports only `shared_kernel`. `application/` is owned by
resolve-d20-test-use-case.md.

- `D20Roll`: `mode`, `dice` (unmodifiable, in the order rolled), `natural`,
  `keptIndex` (FR-058); `replaceDie` (FR-012) and `applyReroll` (FR-059) return
  new rolls. The constructor copies the list (FR-068) and validates count and
  range through `select` (FR-009 to FR-011). No replaced state (FR-067).
- `RerollDecision`: sealed `KeepRoll` | `RerollDie(dieIndex)`.
- `RollModifiers`: `ability` (required), `proficiencyBonus` (`Modifier?`),
  `others` (unmodifiable); `total` is the kernel sum (FR-016 to FR-020, FR-061).
- `DifficultyClass` (with constants) and `ArmorClass`: integer wrappers with
  value equality, no range check (FR-021, FR-022, D-02).
- `D20TestKind`: `abilityCheck` | `savingThrow` | `attackRoll`.
  `D20TestOutcome`: `success` | `failure`. `ForcedFailureReason`:
  `chosenToFail` | `automatic`.
- Results: `CheckResult(kind, roll, modifiers, total, target: DifficultyClass,
  outcome)`; `AttackRollResult(roll, modifiers, total, target: ArmorClass,
  outcome, isCriticalHit, criticalRange = 20)` with getter `hit`; `ForcedFailureResult(kind,
  reason)` (always `failure`, no roll). `adjustedBy` on the first two (FR-065,
  FR-066).
- `D20TestResolver` (stateless, `const`, FR-069):
  `resolveCheck(D20TestKind, D20Roll, RollModifiers, DifficultyClass)` (no
  natural 20/1 branch: FR-016, FR-023 to FR-026, FR-031, FR-062);
  `resolveAttackRoll(D20Roll, RollModifiers, ArmorClass, {int criticalRange =
  20})` (the only natural 20/1 branch: FR-027 to FR-034, FR-051, FR-071 to
  FR-073); `forcedFailure(D20TestKind,
  ForcedFailureReason)` (FR-035, FR-036, FR-052). Static delegates: FR-070.

No domain events: a D20 Test is a calculation; `combat` raises events from the
result.

**Failures.** Success, failure, hit, miss and Critical Hit are results, never
exceptions. No `Srd5eException` is thrown by the domain. Every `ArgumentError`
follows errors-and-results.md FR-027: it carries the argument `name` (`dice`,
`index`, `value`, `newValue`, `kind`, `reason`) and `invalidValue`; tests assert
both, never the message. A `D20Roll` re-throws the kernel's `select` error with
`name` `dice`, not `rolled`. `ArgumentError` covers an invalid `D20Roll`, a bad
`replaceDie` or `applyReroll`, a `forcedFailure` combination without an SRD
rule, and `resolveCheck` with an attack roll (FR-009, FR-010, FR-014, FR-052,
FR-059, FR-062): programmer errors, as values come from callers.

## 6. Interface

- No use case, command, attempt type or port here (D-17); no new test double or
  contract suite.
- Domain API: the types in section 5.
- `lib/src/d20_test/d20_test.dart` exports `D20Roll`, `RerollDecision`
  (`KeepRoll`, `RerollDie`), `RollModifiers`, `DifficultyClass`, `ArmorClass`,
  `D20TestKind`, `D20TestOutcome`, `ForcedFailureReason`, `CheckResult`,
  `AttackRollResult`, `ForcedFailureResult` and `D20TestResolver`, alongside the
  use case exports of resolve-d20-test-use-case.md. It does not re-export
  `Modifier`, `RollMode` or other kernel types. Its library doc comment lists
  inputs and outputs.
- `lib/srd5e.dart` re-exports the same set. Downstream code resolves a rerolled
  or adjusted roll with `D20TestResolver` or the static members and `adjustedBy`
  without the use case (D-18, FR-069, FR-070). No free functions are exported,
  and no generic variant names (`doc/rules/architecture.md` §4).

## 7. Observability

Silent by design: the domain is pure (`doc/rules/observability.md` §3) and all
`ResolveD20Test` signals belong to resolve-d20-test-use-case.md
(shared-types-and-ownership.md FR-040, FR-043). No signal is defined here and
none feeds `doc/observability/signals.md` from this spec. No log is emitted.

1. **What can go wrong?** A programmer builds an invalid roll, reroll or forced
   failure (FR-009, FR-010, FR-014, FR-052, FR-059, FR-062): `ArgumentError` at
   the call site. Wrong rule maths would show as a drifting outcome mix at the
   use case.
2. **How would an operator know?** Through the use case's counter and span,
   whose critical-hit and outcome attributes come from `AttackRollResult` and
   `D20TestOutcome` (shared-types-and-ownership.md FR-041).
3. **What to diagnose with?** The results carry dice, kept die, modifiers,
   total, target and outcome (FR-034, FR-041).
4. **What to count or time?** Nothing is counted in the domain; the use case
   counts and times.
5. **Is existing instrumentation still correct?** Nothing here can go stale.
6. **What to monitor?** The use case's critical-hit share; this spec adds the
   `isCriticalHit` field it uses.
7. **What is noisy?** Nothing; no log is emitted.

## 8. Test plan

Levels: unit (`test/d20_test/domain/`), architecture (`test/architecture/`).
Use case and scenario tests are in resolve-d20-test-use-case.md. Row names refer
to the case tables in section 4.

| Ids | Level | Notes |
|---|---|---|
| FR-009, FR-010 | unit | Reroll rows "value 0", "value 21", "construct with a die of 0/21/negative", "wrong die count", "three dice", "no dice under advantage", "normal with two dice"; control "normal with one die" |
| FR-011, FR-055, FR-058 | unit | Reroll row "equal dice"; Advantage and Disadvantage attack rows; `[18, 3]` under both modes; kept index after each replacement |
| FR-012, FR-013 | unit | Reroll replace rows; "replace the unused die"; other dice unchanged in position |
| FR-014 | unit | Reroll index and value `ArgumentError` rows |
| FR-015, FR-068 | unit | Original equal before and after `replaceDie` and `applyReroll`; "source list mutated after construction"; `dice` mutation throws `UnsupportedError` |
| FR-059 | unit | Reroll `applyReroll` rows |
| FR-067 | unit | Row "replacement twice": no error, valid roll |
| FR-016 to FR-020 | unit | Total cases through `CheckResult.resolve` and `AttackRollResult.resolve`; zero-other rows; Proficiency Bonus row; penalty rows; reordered rows plus a permutation of every row's `others`; compile-time: required ability parameter, single Proficiency Bonus slot |
| FR-061 | unit | Mutate source list; mutate exposed list expects `UnsupportedError`; empty default |
| FR-021, FR-022 | unit | `DifficultyClass` constants; `DifficultyClass`/`ArmorClass` equality cases |
| FR-023 to FR-026, FR-031 | unit | Check resolution table, run for both kinds; natural 20 and natural 1 rows |
| FR-027 to FR-030, FR-032 to FR-034, FR-051 | unit | Attack table by row group (ordinary, natural 20, natural 1, natural 19, Advantage/Disadvantage via `RollMode.select`, the "far below/above" rows); `hit` getter; outcome and `isCriticalHit` columns |
| FR-071 to FR-073 | unit | Range 19 and 18 rows of the attack table (crit, non-crit, natural 20/1, invalid 17 and 21); `adjustedBy` keeps the range; equality differs by range |
| FR-035, FR-036, FR-052 | unit | Forced failure table, success and `ArgumentError` rows |
| FR-041, FR-050 | unit | Result fields per variant; collections unmodifiable; equal and hash-equal pairs and one inequality case per field for every domain handoff type |
| FR-060 | unit + architecture | Exhaustive `switch` over `D20TestOutcome` with two cases; barrel scan finds no `AttackOutcome`, `AttackConclusion` or `AttackRollOutcome` export |
| FR-062 | unit | `resolveCheck(attackRoll, ...)` throws `ArgumentError` (name `kind`) |
| FR-063 to FR-066 | unit | Re-resolution table by row group: check/save rerolls, attack rerolls, `adjustedBy` rows, natural 19/20/1 adjusted rows, "adjustment leaves the original", "`CheckResult.resolve` with attackRoll" |
| FR-069 | unit + architecture | Check, attack and forced-failure tables through `D20TestResolver`; the class has no constructor parameters, imports no port or `Observability`, and is exported from both barrels |
| FR-070 | unit | Every resolution row through both the resolver and the static member, results equal; same `ArgumentError` rows |

- **Doubles and contract suites:** none; domain tests use plain values
  (`doc/rules/testing.md` §3, `observability.md` §9).
- **Table-driven tests:** one test per row of the section 4 tables, citing
  `Requirement: per case` and `Path: per case`.
- **Mutation testing:** scope all of `lib/src/d20_test/domain` (score at least
  80, `--diff-base main`). Boundary rows (equal, one below, one above, natural
  19, 20, 1; first and last die index; values 0, 1, 20, 21) kill `>=` to `>`
  and `==` to `!=` mutants.
- **Not covered at runtime:** compile-time guarantees (one required ability
  modifier, one Proficiency Bonus slot, a DC only for a check or save and an AC
  only for an attack roll); the analyzer enforces them.

## 9. Open questions and decisions

No open questions. Settled decisions cited elsewhere:

- D-02: no range check on `DifficultyClass`/`ArmorClass`; the SRD never bounds
  them (p. 6) and rejecting values would invent a rule.
- D-10: the Exhaustion reduction (p. 181) is a plain negative `Modifier` in
  `others`, wrapped by the caller; conditions.md FR-041 publishes the number.
- D-15: with equal dice the kept die is the first index (FR-058).
- D-16: `RollModifiers` slots are plain `Modifier`s because `d20_test` cannot
  import `character` and the bounded `AbilityModifier` cannot build the
  boundary cases; callers convert (ability-scores.md FR-027).
- D-17: command and attempt types are application types owned by
  resolve-d20-test-use-case.md.
- D-18: re-resolution is published as static members and `adjustedBy` on the
  result value objects, not free functions (FR-063 to FR-066).
- D-19: results carry no `Ability` and no separate roll mode (FR-041).
- D-20: no hidden replaced state in `D20Roll`; the caller enforces the SRD
  limit (FR-067). Revisit if a consumer needs it enforced (a nullable
  `replacedIndex` would make a second replacement throw `StateError`).
- D-22: critical range is an optional input (FR-071 to FR-073) so features
  that widen it (class-fighter.md FR-090) are reachable; no other spec owns it.
- D-21: `D20TestResolver` is the published service, static members delegate
  (FR-069, FR-070; shared-types-and-ownership.md FR-044, FR-048).
- D-01: `RollMode`, `RollCircumstance`, `resolve`, `select` live in the kernel;
  `D20Roll` is here (shared-types-and-ownership.md FR-001, FR-002).
- D-03: `d20_test` owns and publishes `ArmorClass`; the attack outcome is
  `D20TestOutcome` plus `AttackRollResult.isCriticalHit`, with no parallel enum
  (shared-types-and-ownership.md FR-002, FR-004).
- D-04: one use case, `ResolveD20Test` (resolve-d20-test-use-case.md).
- D-05: structured `RollModifiers` (shared-types-and-ownership.md FR-003).
- D-06: the `Ability` label is not a domain question; it belongs to the use case
  (resolve-d20-test-use-case.md FR-055).
- D-07: no per-call log (shared-types-and-ownership.md FR-043).
- D-08: one authority for the use case and its signals, resolve-d20-test-use-case.md
  (shared-types-and-ownership.md FR-040).
- D-09, D-13, D-14: circumstance list, failed-call duration and `2d20` versus
  two `1d20` requests are use-case matters (resolve-d20-test-use-case.md).
- D-11: Death Saving Throws are `combat`'s; FR-031 stays attack-roll-only.
- D-12: reroll operations are here (FR-012 to FR-015, FR-059, FR-067); the
  Inspiration slot and mechanics are elsewhere (shared-types-and-ownership.md
  FR-002, FR-010, FR-048).

## 10. Changelog impact

`CHANGELOG.md`, `Unreleased`, **Added**: "D20 Tests (`d20_test` context, domain
model): `D20Roll` with reroll and replace-a-die operations, `RollModifiers`,
`DifficultyClass`, `ArmorClass`, `D20TestOutcome`, `AttackRollResult` with
`isCriticalHit`, forced failures, the pure `D20TestResolver` service, and the
natural 20 and natural 1 attack rules, using the shared kernel's `Modifier` and
`RollMode`." Not **BREAKING**: first release of these members. The
`ResolveD20Test` use case and its `srd5e.d20_test.*` signals are recorded by
resolve-d20-test-use-case.md; from the first release containing them, renaming
any signal or attribute key is **BREAKING** (`doc/rules/observability.md` §5).
