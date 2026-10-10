# Modifiers and Advantage/Disadvantage

| | |
|---|---|
| Status | implemented |
| Context | `shared_kernel` |
| Roadmap phase | 0 |
| Depends on | none |

## 1. Purpose and scope

Defines the two small value-level concepts of a D20 Test that every context
shares:

1. `Modifier`: a signed whole number added to the number rolled on the d20,
   and the rule that modifiers are added together.
2. Advantage and Disadvantage: how any number of Advantage and Disadvantage
   circumstances on one roll resolve to a roll mode (Advantage, Disadvantage
   or normal), how many d20s that means rolling, and which d20 is used.

All of it is pure, synchronous, deterministic domain logic. Rolling is done by
the `DiceRoller` port; this spec only consumes the rolled values.

Ownership (shared-types-and-ownership.md FR-001, FR-002): the kernel owns
`Modifier` (plain signed integer, no kind tag) and `RollMode` (`normal`,
`advantage`, `disadvantage`, with `resolve`, `diceCount`, `select`).
`RollCircumstance` (`Advantage`, `Disadvantage`) is `RollMode.resolve`'s input
type and stays here (FR-042). `D20Roll`, `RollModifiers` and `D20TestOutcome`
belong to the `d20_test` context (`d20-tests.md`), which calls `RollMode.select`.

Relationships (none is a code dependency): `shared_kernel` imports nothing
else in the package. Consumers include `d20-tests.md`, `conditions.md`,
`attacks.md`, `initiative-and-actions.md` and `derived-stats.md`.
`ability-scores.md` and `dice-and-rolls.md` are sibling kernel specs, not
consumers (`ability-scores.md` FR-027).

**Out of scope:**

- Comparing a total to a DC or AC, success and failure, natural 20 and 1
  (SRD 5.2.1, "Rolling 20 or 1", p. 7); `D20Roll`, rerolls, `RollModifiers`
  (shared-types-and-ownership.md FR-002, FR-003): `d20-tests.md`. `select` is
  pure, so `d20_test` can call it again with a replaced value.
- Deriving an ability modifier from a score (SRD 5.2.1, "Ability Modifiers",
  pp. 5-6; `ability-scores.md`), the Proficiency Bonus and its "doesn't stack"
  rule (p. 8; `derived-stats.md`) and the "Round Down" rule (p. 5). Here a
  `Modifier` is just a number.
- Which circumstances grant Advantage or Disadvantage (Blinded, SRD 5.2.1,
  p. 177; Dodge, p. 181; features, spells, GM rulings). The callers of
  `resolve` are `resolve-d20-test-use-case.md` FR-006, `conditions.md`
  FR-105, `attacks.md` FR-011, `grappling.md` FR-037 and
  `spell-effects.md` FR-024, each deciding for its own command.
- The d20 reduction from Exhaustion ("D20 Tests Affected", p. 181) and Heroic
  Inspiration (p. 8; `heroic-inspiration.md`, shared-types-and-ownership.md
  FR-010, FR-048).
- Any modifier stacking or ordering rule beyond plain addition (the SRD states
  none) and any cap on modifier size (FR-035 withdrawn).

## 2. Source

- SRD 5.2.1, "D20 Tests", steps "Roll 1d20" and "Add Modifiers", p. 6. The
  page says "Add these modifiers to the number rolled on the d20" and speaks of
  a "bonus or penalty". It does not say that modifiers are whole numbers, that
  a total may leave 1 to 20, or that order is irrelevant; requirements resting
  on those points are marked "derived from".
- SRD 5.2.1, "Ability Modifiers" table, p. 6 (the +0 row); "Rolling 20 or 1",
  p. 7.
- SRD 5.2.1, "Advantage/Disadvantage", pp. 7-8, incl. "Roll Two D20s" and
  "They Don't Stack" (p. 8).
- SRD 5.2.1, "Rules Glossary", "Advantage", p. 176; "Disadvantage", p. 181;
  "D20 Test", p. 180.
- Package design: `doc/rules/architecture.md` (§3, §6), `doc/rules/testing.md` (§4).

Page numbering: PDF page index equals printed page number (no offset). In the
case tables of section 4, each FR id's own Source cell applies to its rows.

## 3. Vocabulary

| SRD term | Type | Notes |
|---|---|---|
| D20 Test | concept (no type here) | Ability check, saving throw or attack roll (pp. 6, 180). |
| modifier; bonus / penalty | `Modifier` | Bonus is a `Modifier` above zero, penalty below zero; not separate types ("Circumstantial Bonuses and Penalties", p. 6). |
| the number rolled on the d20 | `int` 1 to 20 | The used d20 value, before modifiers. |
| total | `int` | d20 number plus modifiers (p. 6). |
| Advantage / Disadvantage | `Advantage` / `Disadvantage` (`RollCircumstance`) | Positive / negative circumstances of a d20 roll (p. 7). |
| neither | `RollMode.normal` | SRD: "the roll has neither of them" (p. 8). Name fixed by shared-types-and-ownership.md FR-001, FR-041; value of `srd5e.d20_test.roll_mode`. |
| (a roll with) Advantage / Disadvantage | `RollMode.advantage` / `RollMode.disadvantage` | Resolved state of one roll. |
| roll two d20s | `RollMode.diceCount` = 2 | "Roll Two D20s", p. 8. |

`RollMode` is a package name for an SRD concept without a noun and contains no
term from another edition.

## 4. Requirements

Ids are stable; withdrawn ids are in the table at the end of this section.

Modifier.

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-001 | A `Modifier` MUST hold one whole number (any `int`, no bound) and expose it as `value`; positive (bonus), zero and negative (penalty) values are all valid. | derived from SRD 5.2.1, "D20 Tests", "Add Modifiers", p. 6 ("bonus or penalty") | happy |
| FR-002 | Two `Modifier`s with the same value MUST be equal and have equal hash codes; different values MUST NOT be equal. | package design (architecture.md §3, value objects) | happy |
| FR-003 | `Modifier.zero` MUST have value 0. | SRD 5.2.1, "Ability Modifiers" table, +0 row, p. 6 | unhappy (empty and minimal) |
| FR-004 | `Modifier.sum` over a collection and `Modifier + Modifier` MUST give the arithmetic sum of the values. | SRD 5.2.1, "D20 Tests", "Add Modifiers", p. 6 | happy |
| FR-005 | The sum of an empty collection MUST be `Modifier.zero`. | derived from SRD 5.2.1, "D20 Tests", p. 6 (no modifiers: the total is the d20 number) | unhappy (empty and minimal) |
| FR-006 | Bonuses and penalties MUST combine by signed addition: a mixed collection sums to the net value, which MAY be negative. | SRD 5.2.1, "D20 Tests", "Circumstantial Bonuses and Penalties", p. 6 | unhappy (rule interaction) |
| FR-007 | The sum MUST NOT depend on the order of the modifiers. | derived from SRD 5.2.1, "D20 Tests", "Add Modifiers", p. 6 | unhappy (rule interaction) |
| FR-008 | Applying a modifier to a d20 number MUST give number plus value, with no clamping: the total MAY be below 1 or above 20. `applyTo` accepts any `int` and does not validate 1 to 20 (that check belongs to `RollMode.select`, FR-027), so `applyTo(0)` and `applyTo(25)` return `value` and `25 + value` and throw nothing. | derived from SRD 5.2.1, "D20 Tests", "Compare the Total to a Target Number", p. 6 (no clamping is stated); package design | unhappy (boundary) |
| FR-009 | Summing MUST NOT alter the input collection or its elements. | package design (testing.md §4, immutability) | unhappy (immutability) |
| FR-036 | Summing and applying MUST be exact plain integer arithmetic with no bound or wrap added by the kernel: the sum of two `Modifier`s of 1000000 is 2000000, and `applyTo` returns number plus value. Exactness is that of Dart `int` on the platform (up to 2^53 on the web), which no SRD value approaches. | package design (silent wrong totals are the worst failure of a rules engine) | unhappy (boundary) |
| FR-037 | Adding `Modifier.zero` to any modifier or sum MUST leave the value unchanged. | derived from SRD 5.2.1, "Ability Modifiers" table, +0 row, p. 6 | unhappy (empty and minimal) |

Resolving Advantage and Disadvantage.

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-010 | With no `RollCircumstance` the roll mode MUST be `normal`. | SRD 5.2.1, "D20 Tests", "Roll 1d20", p. 6 | unhappy (empty and minimal) |
| FR-011 | With exactly one `Advantage` and no `Disadvantage` the roll mode MUST be `advantage`. | SRD 5.2.1, "Rules Glossary", "Advantage", p. 176 | happy |
| FR-012 | With exactly one `Disadvantage` and no `Advantage` the roll mode MUST be `disadvantage`. | SRD 5.2.1, "Rules Glossary", "Disadvantage", p. 181 | happy |
| FR-013 | Two or more `Advantage` circumstances and no `Disadvantage` MUST resolve to `advantage`. | SRD 5.2.1, "Advantage/Disadvantage", "They Don't Stack", p. 8 | unhappy (rule interaction) |
| FR-014 | Two or more `Disadvantage` circumstances and no `Advantage` MUST resolve to `disadvantage`. | SRD 5.2.1, "Advantage/Disadvantage", "They Don't Stack", p. 8 | unhappy (rule interaction) |
| FR-015 | At least one `Advantage` and at least one `Disadvantage` MUST resolve to `normal`, whatever the counts (1 and 1, 3 and 1, 1 and 3, 4 and 4). They cancel as a whole, not one for one. | SRD 5.2.1, "They Don't Stack", p. 8 ("even if multiple circumstances impose Disadvantage and only one grants Advantage or vice versa"); "Rules Glossary", "Advantage", p. 176 | unhappy (rule interaction) |
| FR-016 | The resolved mode MUST NOT depend on the order of the circumstances. | derived from SRD 5.2.1, "They Don't Stack", p. 8 (only presence is described) | unhappy (rule interaction) |
| FR-017 | Resolving MUST NOT alter the input collection. | package design (testing.md §4, immutability) | unhappy (immutability) |
| FR-039 | Adding further `Advantage` circumstances to a set that already resolves to `advantage` MUST NOT change the mode (1, 2 and 5 all give the same mode). | SRD 5.2.1, "They Don't Stack", p. 8 ("you still roll only two d20s") | unhappy (rule interaction) |
| FR-040 | Adding further `Disadvantage` circumstances to a set that already resolves to `disadvantage` MUST NOT change the mode. | SRD 5.2.1, "They Don't Stack", p. 8 | unhappy (rule interaction) |
| FR-034 | `Advantage` instances MUST be equal to one another with equal hash codes; `Disadvantage` likewise; an `Advantage` MUST NOT equal a `Disadvantage`. A `switch` over a `RollCircumstance` with an `Advantage` case and a `Disadvantage` case MUST be exhaustive without a default. | package design (architecture.md §3, value objects; encodes "They Don't Stack", p. 8) | happy |
| FR-042 | `RollCircumstance` (sealed: `Advantage`, `Disadvantage`) MUST be defined in the kernel as the input type of `RollMode.resolve`, which MUST accept any `Iterable<RollCircumstance>` (read once), and MUST carry no data (no cause, no source). The kernel imports nothing from `conditions.md`. | package design; shared-types-and-ownership.md FR-001, FR-013, FR-026 | happy |

Dice count.

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-018 | `normal` MUST require 1 d20. | SRD 5.2.1, "D20 Tests", "Roll 1d20", p. 6; "They Don't Stack", p. 8 ("you roll one d20") | happy |
| FR-019 | `advantage` MUST require 2 d20s. | SRD 5.2.1, "Advantage/Disadvantage", "Roll Two D20s", p. 8 | happy |
| FR-020 | `disadvantage` MUST require 2 d20s. | SRD 5.2.1, "Advantage/Disadvantage", "Roll Two D20s", p. 8 | happy |

Selecting the used d20. `RollMode.select(List<int> rolled)` returns the used
number as an `int`; it builds no `D20Roll`.

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-021 | With `normal`, the used number MUST be the one d20 rolled. | SRD 5.2.1, "D20 Tests", "Roll 1d20", p. 6 | happy |
| FR-022 | With `advantage`, the used number MUST be the higher of the two d20s. | SRD 5.2.1, "Roll Two D20s", p. 8 ("Use the higher of the two rolls") | happy |
| FR-023 | With `disadvantage`, the used number MUST be the lower of the two d20s. | SRD 5.2.1, "Roll Two D20s", p. 8 ("use the lower roll") | happy |
| FR-024 | When the two d20s are equal, the used number MUST be that value under either mode. | derived from SRD 5.2.1, "Roll Two D20s", p. 8 | unhappy (boundary) |
| FR-025 | At the extremes: `advantage` with 1 and 20 MUST use 20; `disadvantage` with 1 and 20 MUST use 1. | SRD 5.2.1, "Roll Two D20s", p. 8 | unhappy (boundary) |
| FR-026 | `select` with the wrong number of values for the mode (0, 1 or 3 or more for `advantage`/`disadvantage`; 0, 2 or more for `normal`) MUST throw `ArgumentError` whose `name` is `rolled` and whose `invalidValue` is the list passed in (errors-and-results.md FR-027). A list failing both this check and the range check (FR-027) throws the same `ArgumentError`; no order between the two checks is claimed. | SRD 5.2.1, "Roll Two D20s", p. 8 ("roll a second d20"); "D20 Tests", p. 6 | unhappy (invalid input) |
| FR-027 | `select` with any value outside 1 to 20 (0, 21, negatives) MUST throw `ArgumentError` whose `name` is `rolled` and whose `invalidValue` is the list passed in (errors-and-results.md FR-027); 1 and 20 MUST be accepted. | SRD 5.2.1, "Rolling 20 or 1", p. 7; derived from "D20 Tests", p. 6 | unhappy (boundary, invalid input) |
| FR-030 | `select` MUST NOT alter the input list. | package design (testing.md §4, immutability) | unhappy (immutability) |
| FR-031 | `select` MUST be deterministic and pure: the same mode and values always give the same used number. | package design (architecture.md §3, purity) | unhappy (determinism) |
| FR-038 | Swapping the two values given to `select` MUST NOT change the used number under `advantage` or `disadvantage`. | SRD 5.2.1, "Roll Two D20s", p. 8 | unhappy (determinism) |

Package enforcement.

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-043 | The kernel MUST provide no conversion between `AbilityModifier` and `Modifier`; neither type imports the other. Callers convert with `Modifier(abilityModifier.value)` (`ability-scores.md` FR-027); `RollModifiers.ability` in `d20-tests.md` is a plain `Modifier` (`d20-tests.md` section 4.3, D-16). | package design; shared-types-and-ownership.md FR-001, FR-003; ability-scores.md FR-027 | unhappy (rule interaction) |

### Case tables

FR-004 to FR-008, FR-036, FR-037, modifier arithmetic.

| Label | Inputs | Expected | Requirement | Path |
|---|---|---|---|---|
| one bonus | [+3] | +3 | FR-004 | happy |
| two bonuses | [+2, +3] | +5 | FR-004 | happy |
| one penalty | [-2] | -2 | FR-001, FR-004 | happy |
| bonus and penalty, net positive | [+3, -2] | +1 | FR-006 | unhappy (rule interaction) |
| bonus and penalty, net zero | [+2, -2] | 0 | FR-006 | unhappy (rule interaction) |
| bonus and penalty, net negative | [+1, -4] | -3 | FR-006 | unhappy (rule interaction) |
| empty | [] | 0 | FR-005 | unhappy (empty and minimal) |
| zero among others | [0, +2] | +2 | FR-037 | unhappy (empty and minimal) |
| zero value | `Modifier.zero` | value 0 | FR-003 | unhappy (empty and minimal) |
| reordered | [-4, +1] vs [+1, -4] | both -3 | FR-007 | unhappy (rule interaction) |
| d20 1, penalty | 1 with -5 | total -4 | FR-008 | unhappy (boundary) |
| d20 20, bonus | 20 with +10 | total 30 | FR-008 | unhappy (boundary) |
| d20 10, no modifiers | 10 with [] | total 10 | FR-005, FR-008 | unhappy (empty and minimal) |
| large sum | [+1000000, +1000000] | +2000000 | FR-036 | unhappy (boundary) |
| applyTo below 1 | 0 with +2 | total 2, no error | FR-008 | unhappy (boundary) |
| applyTo above 20 | 25 with -3 | total 22, no error | FR-008 | unhappy (boundary) |
| extreme total | 20 with +1000000 | total 1000020 | FR-036 | unhappy (boundary) |
| extreme negative total | 1 with -1000000 | total -999999 | FR-036 | unhappy (boundary) |

FR-010 to FR-016, FR-039, FR-040, FR-042, resolution (A = count of `Advantage`,
D = count of `Disadvantage`).

| Label | A | D | Expected mode | Requirement | Path |
|---|---|---|---|---|---|
| none | 0 | 0 | normal | FR-010 | unhappy (empty and minimal) |
| one Advantage | 1 | 0 | advantage | FR-011 | happy |
| one Disadvantage | 0 | 1 | disadvantage | FR-012 | happy |
| two Advantage | 2 | 0 | advantage | FR-013, FR-039 | unhappy (rule interaction) |
| many Advantage | 5 | 0 | advantage | FR-013, FR-039 | unhappy (rule interaction) |
| two Disadvantage | 0 | 2 | disadvantage | FR-014, FR-040 | unhappy (rule interaction) |
| many Disadvantage | 0 | 5 | disadvantage | FR-014, FR-040 | unhappy (rule interaction) |
| one each | 1 | 1 | normal | FR-015 | unhappy (rule interaction) |
| many Advantage, one Disadvantage | 3 | 1 | normal | FR-015 | unhappy (rule interaction) |
| one Advantage, many Disadvantage | 1 | 3 | normal | FR-015 | unhappy (rule interaction) |
| many each | 4 | 4 | normal | FR-015 | unhappy (rule interaction) |
| order: Disadvantage first | D, A | | normal | FR-016 | unhappy (rule interaction) |
| order: mixed | A, D, A, D, A | | normal | FR-016 | unhappy (rule interaction) |
| single-pass Iterable | `sync*` generator yielding A, D (cannot be iterated twice) | | normal | FR-042, FR-017 | unhappy (rule interaction) |
| single-pass Iterable, Advantage only | `sync*` generator yielding A, A | | advantage | FR-042, FR-017 | unhappy (rule interaction) |
| Set | `{Advantage(), Disadvantage()}` as a `Set<RollCircumstance>` | | normal | FR-042 | unhappy (rule interaction) |
| empty Iterable | `Iterable<RollCircumstance>.empty()` | | normal | FR-042, FR-010 | unhappy (empty and minimal) |

FR-034, circumstance equality.

| Label | Inputs | Expected | Requirement | Path |
|---|---|---|---|---|
| Advantage with Advantage | `Advantage()` vs `Advantage()` | equal, equal hash codes | FR-034 | happy |
| Disadvantage with Disadvantage | `Disadvantage()` vs `Disadvantage()` | equal, equal hash codes | FR-034 | happy |
| Advantage with Disadvantage | `Advantage()` vs `Disadvantage()` | not equal | FR-034 | unhappy (rule interaction) |
| exhaustive switch | `switch (c)` with two cases, no default | compiles and returns for both | FR-034 | happy |

FR-018 to FR-027, FR-038, selection (values in the order given). Dice count
(FR-018 to FR-020): `normal` 1, `advantage` 2, `disadvantage` 2.

| Label | Mode | Values | Expected used | Requirement | Path |
|---|---|---|---|---|---|
| single d20 | normal | [14] | 14 | FR-021 | happy |
| single d20, lowest | normal | [1] | 1 | FR-021, FR-027 | unhappy (boundary) |
| single d20, highest | normal | [20] | 20 | FR-021, FR-027 | unhappy (boundary) |
| Advantage, SRD example | advantage | [18, 3] | 18 | FR-022 | happy |
| Disadvantage, SRD example | disadvantage | [18, 3] | 3 | FR-023 | happy |
| Advantage, swapped | advantage | [3, 18] | 18 | FR-022, FR-038 | unhappy (determinism) |
| Disadvantage, swapped | disadvantage | [3, 18] | 3 | FR-023, FR-038 | unhappy (determinism) |
| Advantage, equal | advantage | [7, 7] | 7 | FR-024 | unhappy (boundary) |
| Disadvantage, equal | disadvantage | [7, 7] | 7 | FR-024 | unhappy (boundary) |
| Advantage, extremes | advantage | [1, 20] | 20 | FR-025 | unhappy (boundary) |
| Disadvantage, extremes | disadvantage | [20, 1] | 1 | FR-025 | unhappy (boundary) |
| Advantage, both 1 | advantage | [1, 1] | 1 | FR-024 | unhappy (boundary) |
| Disadvantage, both 20 | disadvantage | [20, 20] | 20 | FR-024 | unhappy (boundary) |
| normal, no values | normal | [] | ArgumentError (`rolled`) | FR-026 | unhappy (invalid input) |
| normal, two values | normal | [4, 9] | ArgumentError (`rolled`) | FR-026 | unhappy (invalid input) |
| Advantage, no values | advantage | [] | ArgumentError (`rolled`) | FR-026 | unhappy (invalid input) |
| Advantage, one value | advantage | [12] | ArgumentError (`rolled`) | FR-026 | unhappy (invalid input) |
| Advantage, three values | advantage | [1, 2, 3] | ArgumentError (`rolled`) | FR-026 | unhappy (invalid input) |
| Disadvantage, one value | disadvantage | [12] | ArgumentError (`rolled`) | FR-026 | unhappy (invalid input) |
| Disadvantage, three values | disadvantage | [5, 6, 7] | ArgumentError (`rolled`) | FR-026 | unhappy (invalid input) |
| wrong count and out of range | advantage | [0] | ArgumentError (`rolled`) | FR-026, FR-027 | unhappy (invalid input) |
| value zero | normal | [0] | ArgumentError (`rolled`) | FR-027 | unhappy (boundary) |
| value 21 | normal | [21] | ArgumentError (`rolled`) | FR-027 | unhappy (boundary) |
| value negative | normal | [-3] | ArgumentError (`rolled`) | FR-027 | unhappy (invalid input) |
| one die out of range under Advantage | advantage | [20, 21] | ArgumentError (`rolled`) | FR-027 | unhappy (boundary) |
| one die out of range under Disadvantage | disadvantage | [0, 10] | ArgumentError (`rolled`) | FR-027 | unhappy (boundary) |

### Withdrawn ids

| Id | Withdrawn |
|---|---|
| FR-028 | Withdrawn: moved to d20-tests.md (FR-011, FR-055) |
| FR-029 | Withdrawn: moved to d20-tests.md (FR-068) |
| FR-032 | Withdrawn: moved to d20-tests.md (FR-050) |
| FR-033 | Withdrawn: moved to d20-tests.md (FR-009, FR-010, FR-011); kernel side is FR-026, FR-027, FR-022, FR-023 |
| FR-035 | Withdrawn: settled, no spec. `Modifier` has no bound (shared-types-and-ownership.md FR-001); constructor is `const` (allows const tables, testing.md §6) and never throws |
| FR-041 | Withdrawn: settled, no spec. No purity scan of `shared_kernel/` (architecture-guardrails.md FR-015, FR-027); purity shown by FR-030, FR-031 |

## 5. Model

All types are immutable value objects (`@immutable`, `const` constructors).
No entities, aggregates, events or services beyond the stateless functions below.

- **`Modifier`**: wraps an `int`. `const Modifier(int value)` accepts any `int`
  and never throws; `Modifier.zero` is `const`. `+` and static `sum` go through
  the same constructor; `applyTo(int)` returns `int` (FR-008, FR-036). Equality
  by value (FR-002). No `AbilityModifier` conversion (FR-043).
- **`RollCircumstance`**: sealed, final subclasses `Advantage` and
  `Disadvantage` (FR-042); `const`, no data, equal within their own type
  (FR-034). Only counts matter, which encodes "they don't stack".
- **`RollMode`**: enum `normal`, `advantage`, `disadvantage`, in
  `lib/src/shared_kernel/`.
  - `static RollMode resolve(Iterable<RollCircumstance>)`: the only place the
    cancel rule lives (FR-010 to FR-017, FR-039, FR-040).
  - `int get diceCount`: 1 or 2 (FR-018 to FR-020).
  - `int select(List<int> rolled)`: the used d20 number (FR-021 to FR-027,
    FR-030, FR-031, FR-038); the single owner of the higher/lower rule.
    `RollResult.sumOfHighest(1)`/`sumOfLowest(1)` in `dice-and-rolls.md` are
    generic dice arithmetic and are not used to pick a D20 Test die; the
    `[18, 3]` rows guard that both agree.
- No `D20Roll`, `RollModifiers` or `D20TestOutcome` here
  (shared-types-and-ownership.md FR-002); `select` returns a plain `int`.

Invariants and enforcement:

| Invariant | Enforced by |
|---|---|
| `rolled.length == mode.diceCount` | `select` (FR-026): `ArgumentError` (`rolled`) |
| every rolled value in 1..20 | `select` (FR-027): same `ArgumentError`; no check order claimed |
| returned number is what the mode selects | `select` (FR-022, FR-023), the only code that picks a die |
| a `Modifier` holds one `int`, equal by value | the type itself (FR-001, FR-002); `+` and `sum` cannot violate it |
| input not mutated | `select` and `resolve` only read it (FR-017, FR-030) |

Failures. Every combination of circumstances resolves to a mode, so there are
no expected-outcome results. A wrong dice count or out-of-range die is a
violated precondition (programmer error): `ArgumentError` (architecture.md §6).
Nothing parses untrusted input, so no `tryCreate`. A bad `DiceRoller` result is
caught upstream by `dice-and-rolls.md` FR-051; `select` is a second line of
defence.

## 6. Interface

- No commands, results, use cases or ports. `D20TestResolver` (`d20-tests.md`;
  shared-types-and-ownership.md FR-044) calls `RollMode.select` (inside
  `D20Roll`); `resolve-d20-test-use-case.md` uses `diceCount` for the
  `DiceRoller` port. The callers of `resolve` are listed in section 1.
- Everything is synchronous.
- No barrel of its own: export `Modifier`, `RollCircumstance`, `Advantage`,
  `Disadvantage` and `RollMode` from `lib/srd5e.dart`, each with a dartdoc
  comment. `D20Roll` is exported from the `d20_test` barrel (names are unique:
  shared-types-and-ownership.md FR-021).
- These files MUST NOT import from `shared_ports` or a context.

## 7. Observability

Silent by design (`doc/rules/observability.md` §2): pure in-memory integer
operations, no I/O. The only failures are precondition violations
(`ArgumentError`, a programmer error), which propagate to the calling use case
whose span records them (observability.md §7), and wrong rule results, caught by
unit tests. The `d20_test` use case owns the signals, including
`srd5e.d20_test.roll_mode` (shared-types-and-ownership.md FR-040, FR-041,
FR-043; `resolve-d20-test-use-case.md` section 7). The domain emits nothing
(observability.md §3).

| Signal | Type | Attributes | Purpose | Suggested monitoring |
|---|---|---|---|---|
| none | | | | |

Existing instrumentation: none, nothing is affected. Consumers watching `d20_test` outcome rates can use `srd5e.d20_test.roll_mode` to spot an unexpected shift in Advantage frequency. No signal is added, so nothing becomes noisy, and nothing is added to `doc/observability/signals.md`.

## 8. Test plan

All tests are unit tests in `test/shared_kernel/` (no ports, doubles or I/O).
Rule maths is table-driven from the case tables in section 4, one test per row
(`Requirement: per case`). No contract suite, no application tests; scenario
coverage belongs to `d20-tests.md`.

| Id | Level | Notes |
|---|---|---|
| FR-001 to FR-003 | unit | values +3, 0, -2 readable; equal and unequal pairs with hash codes; `Modifier.zero` is 0 |
| FR-004 | unit | rows "one bonus", "two bonuses", "one penalty", through `Modifier.sum` and again through `+` |
| FR-005 to FR-007 | unit | rows "empty", "d20 10, no modifiers"; "bonus and penalty" nets; "reordered" |
| FR-008 | unit | rows "d20 1, penalty", "d20 20, bonus": no clamping; "applyTo below 1", "applyTo above 20": any `int` accepted, no error |
| FR-009 | unit | input list and elements unchanged after sum |
| FR-036, FR-037 | unit | rows "large sum" (via `sum` and `+`), "extreme total", "extreme negative total"; "zero among others"; add-zero identity via `+` and `sum` |
| FR-010 to FR-016 | unit | resolution table: none, one, 2 and 5 of each kind, 1/1, 3/1, 1/3, 4/4; two orderings give the same mode |
| FR-017 | unit | input list unchanged; a single-pass `sync*` generator holding A and D resolves to `normal` (an implementation that iterates twice would misbehave) |
| FR-039, FR-040 | unit | 1, 2 and 5 of the same kind give the same mode |
| FR-034 | unit | equality table incl. hash codes and a two-case switch with no default |
| FR-042 | unit | exactly two subtypes, no fields (FR-034 switch row); `sync*` generator, `Set` and `Iterable.empty()` rows |
| FR-018 to FR-020 | unit | `diceCount` is 1, 2, 2 |
| FR-021 to FR-025 | unit | selection table: single d20, SRD example, equal-dice and extreme rows under both modes |
| FR-026, FR-027 | unit | wrong-count rows (incl. "wrong count and out of range": asserts only `ArgumentError`, no check order); 0, 1, 20, 21, negative; one-die-out-of-range rows; `throwsA(isA<ArgumentError>().having((e) => e.name, 'name', 'rolled').having((e) => e.invalidValue, 'invalidValue', <the list passed>))`, not message text |
| FR-030, FR-031, FR-038 | unit | list unchanged after select, also when unmodifiable (no `UnsupportedError`); repeat call same number; swapped-order rows |
| FR-043 | architecture | the import check of `ability-scores.md` FR-027 is the enforcement; no signature scan is claimed |

- **Doubles and contract suites:** none required.
- **Mutation testing:** all changed lines in `lib/src/shared_kernel/` for these
  types, `--diff-base main --threshold 80` (testing.md §8). The `>`/`<` in the
  higher/lower selection and the `1`/`20` bounds in FR-027 are mutation-prone;
  the boundary rows exist to kill them.
- **Architecture tests:** the generic "shared_kernel imports nothing else in the
  package" check (architecture.md §9) covers this directory; the purity scans
  do not reach the kernel (FR-041).
- **Not covered:** none. Every live FR id is in the table.

## 9. Open questions and decisions

| Question | Recommendation | Status |
|---|---|---|
| Who owns `RollMode`, `D20Roll`, the `normal` name, source-less `Modifier`, rerolls? | shared-types-and-ownership.md FR-001, FR-002, FR-003, FR-010, FR-048. Bard Countercharm, SRD p. 33: "the new roll has Advantage", so a new D20 Test with one more Advantage circumstance (`class-bard.md` FR-084). | decided |
| Bound `Modifier`? | No (FR-035 withdrawn, FR-036): a bound on the public constructor is not an invariant if `+` and `sum` can exceed it, and it would forbid const tables (testing.md §6). The SRD gives no bound. | decided |
| Kernel purity scans? | None (FR-041 withdrawn); architecture.md §2, §9. | decided |
| Should `Advantage`/`Disadvantage` carry a cause? | No: counting is all the rules need (p. 8). | decided |
| `AbilityModifier` conversion in the kernel? | None: `ability-scores.md` FR-027; FR-043 here. | decided |
| Bad dice from `DiceRoller`? | `dice-and-rolls.md` FR-051, plus FR-026 and FR-027 here. | decided |
| Who picks higher/lower of two d20s? | `select`, not `sumOfHighest(1)`/`sumOfLowest(1)` (pp. 6, 8, 21). | decided |
| Does a roll type hold the total? | No: totals belong to `d20-tests.md`. | decided |
| Which rolls take Advantage? | Only d20 rolls: D20 Tests (pp. 6-8, 176, 181) and, as an SRD fact, the Death Saving Throw (p. 17; Defy Death, p. 49). Whether the package applies it to the Death Saving Throw is open question hit-points-and-damage.md Q-4 (v1: no, FR-061); Defy Death is `class-fighter.md` FR-095. No other die is supported. | decided here; Q-4 open elsewhere |

## 10. Changelog impact

Under `Unreleased`, **Added**: `Modifier`, `RollCircumstance` (`Advantage`,
`Disadvantage`) and `RollMode`, with resolution of Advantage and Disadvantage
and selection of the used d20, exported from `package:srd5e/srd5e.dart`. Not
**BREAKING** (new API). Later changes to this surface are breaking-change
candidates because every context shares the kernel (architecture.md §2).
