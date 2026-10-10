# Ability scores and modifiers

| | |
|---|---|
| Status | implemented |
| Context | `shared_kernel` |
| Roadmap phase | 0 |
| Depends on | `errors-and-results.md` |

Ownership: per `shared-types-and-ownership.md` FR-001 this spec is the single
definition of `Ability`, `AbilityScore`, `AbilityModifier` and
`AbilityScoreRejection`. FR-001 there does not name `AbilityScores`; this spec
adds it to the kernel (section 9) and is its single definition too. Other specs
reference these types by file and id and define none of them. Type phase 0
(`shared-types-and-ownership.md` FR-014). `errors-and-results.md` is a
convention dependency only (result and `ArgumentError` rules; no code).

## 1. Purpose and scope

The six abilities, the ability score a creature has in each, the ability
modifier derived from a score, and a complete set of six scores. `d20_test`
uses the modifier of an ability, `character` stores the scores, `combat` reads
them. This spec defines the types, the valid score range, the score-to-modifier
derivation and the complete set.

**Out of scope:**

- How scores are determined or raised (Character Creation, feats, features):
  `character` and `content`.
- The adventurer cap of 20 "unless a feature says otherwise" (p. 5): a character
  rule. The kernel enforces only 1 to 30. Character-level caps and rejections use
  types named in `character-aggregate.md`, not `AbilityScoreRejection`.
- A score of 0: the SRD says only "If an effect reduces a score to 0, that effect
  explains what happens" (p. 5), so 0 is not a valid `AbilityScore`.
- Objects: "An object lacks ability scores unless a rule assigns scores to the
  object" (p. 178). The kernel has no "no scores" value; a consumer modelling an
  object holds no `AbilityScores`.
- Using a modifier in a D20 Test, Proficiency Bonus, Armor Class, Carrying
  Capacity and other derived rules (`d20_test`, `character`).
- The generic `Modifier` (owned by `modifiers-and-advantage.md`) and
  `RollModifiers`, whose ability slot is a plain `Modifier` (`d20-tests.md`
  section 4.3, D-16). Callers (`character`, `combat`) convert with
  `Modifier(abilityModifier.value)`. See `shared-types-and-ownership.md` FR-003.
- `Skill` and its `Ability` link (`content`, `shared-types-and-ownership.md`
  FR-005).
- The "Score Measures" text, the "Meaning" column (p. 5) and the abbreviations
  Str., Dex., Con., Int., Wis., Cha. (p. 176): display text; the domain holds no
  display strings (`doc/rules/architecture.md` §3).

## 2. Source

- SRD 5.2.1, "The Six Abilities", p. 5 (Ability Descriptions table).
- SRD 5.2.1, "Ability Scores", p. 5 (range 1 to 20, up to 30 for some monsters;
  Ability Scores table).
- SRD 5.2.1, "Ability Modifiers", p. 5 ("a modifier that you apply whenever you
  make a D20 Test with that ability"), and the Ability Modifiers table, p. 6.
- SRD 5.2.1, "Round Down" sidebar, p. 5 (consistent with the table; does not
  decide the negative case).
- SRD 5.2.1, "Rules Glossary", "Ability Score and Modifier", p. 176.
- SRD 5.2.1, "Rules Glossary", "Breaking Objects", "No Ability Scores", p. 178
  (out-of-scope note only).

PDF page index equals the printed page number (checked on pages 5 and 176).

## 3. Vocabulary

| SRD term | Type | Notes |
|---|---|---|
| ability | `Ability` (enum) | Strength, Dexterity, Constitution, Intelligence, Wisdom, Charisma. "All creatures ... have six abilities" (p. 5). |
| ability score | `AbilityScore` (value object) | Integer 1 to 30 (p. 5). |
| ability modifier | `AbilityModifier` (value object) | Derived from a score by the Ability Modifiers table (p. 6). Integer -5 to +10. |
| (the six scores of one creature) | `AbilityScores` (value object) | "A creature has six ability scores" (p. 176): exactly one `AbilityScore` per `Ability`. |

## 4. Requirements

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-001 | `Ability` MUST have exactly six values, in this order: Strength, Dexterity, Constitution, Intelligence, Wisdom, Charisma. | SRD 5.2.1, "The Six Abilities", p. 5 | happy |
| FR-002 | `AbilityScore` MUST accept every integer from 1 to 30 inclusive and expose it as `value`. | SRD 5.2.1, "Ability Scores", p. 5 | happy |
| FR-003 | `AbilityScore` MUST accept 1, the lowest score ("the lowest a score can normally go"). | SRD 5.2.1, "Ability Scores", p. 5 | unhappy (boundary) |
| FR-004 | `AbilityScore` MUST accept 30, the highest score ("the highest a score can go"). | SRD 5.2.1, "Ability Scores", p. 5 | unhappy (boundary) |
| FR-005 | Constructing an `AbilityScore` from 0 MUST throw `ArgumentError`. | SRD 5.2.1, "Ability Scores", p. 5 | unhappy (boundary) |
| FR-006 | Constructing an `AbilityScore` from 31 MUST throw `ArgumentError`. | SRD 5.2.1, "Ability Scores", p. 5 | unhappy (boundary) |
| FR-007 | Constructing an `AbilityScore` from a negative integer MUST throw `ArgumentError`. | SRD 5.2.1, "Ability Scores", p. 5 | unhappy (invalid input) |
| FR-008 | `AbilityScore.tryCreate` MUST return a `ValidAbilityScore` whose `score` is the `AbilityScore` for any integer from 1 to 30, without throwing. | SRD 5.2.1, "Ability Scores", p. 5 | happy |
| FR-009 | `AbilityScore.tryCreate` MUST return an `InvalidAbilityScore` whose `value` is the rejected integer and whose `reason` is `AbilityScoreRejection.belowMinimum`, for any integer below 1, without throwing. | SRD 5.2.1, "Ability Scores", p. 5 | unhappy (invalid input) |
| FR-010 | `AbilityScore.tryCreate` MUST return an `InvalidAbilityScore` whose `value` is the rejected integer and whose `reason` is `AbilityScoreRejection.aboveMaximum`, for any integer above 30, without throwing. | SRD 5.2.1, "Ability Scores", p. 5 | unhappy (invalid input) |
| FR-011 | Two `AbilityScore`s with the same value MUST be equal and have equal hash codes; different values MUST NOT be equal. | `doc/rules/architecture.md` §3 (value object) | happy |
| FR-012 | `AbilityScore.modifier` MUST return the `AbilityModifier` given by the Ability Modifiers table for every score from 1 to 30 (table in this section). | SRD 5.2.1, "Ability Modifiers", p. 5, table p. 6 | happy |
| FR-013 | For odd scores below 10 the modifier MUST be the table's value (floor division), not the truncating-division value: score 1 gives -5 (not -4), score 3 gives -4 (not -3), score 9 gives -1 (not 0). | SRD 5.2.1, Ability Modifiers table, p. 6 (the "Round Down" sidebar, p. 5, is consistent with it but does not decide the negative case) | unhappy (rule interaction) |
| FR-014 | Score 10 MUST give a modifier of +0. This and FR-015 are the labelled boundary rows of the FR-012 table, kept so a mutation of the band edges around zero fails a named test. | SRD 5.2.1, Ability Modifiers table, p. 6 | unhappy (boundary) |
| FR-015 | Score 1 MUST give the lowest modifier, -5. | SRD 5.2.1, Ability Modifiers table, p. 6 | unhappy (boundary) |
| FR-016 | Two `AbilityModifier`s with the same value MUST be equal and have equal hash codes; different values MUST NOT be equal. | `doc/rules/architecture.md` §3 (value object) | happy |
| FR-017 | `AbilityModifier` MUST expose its signed integer `value`, so a consumer can apply it to a D20 Test. | SRD 5.2.1, "Ability Modifiers", p. 5 ("a modifier that you apply whenever you make a D20 Test with that ability"); "Ability Score and Modifier", p. 176 ("Add the modifier when you make a D20 Test with the corresponding ability") | happy |
| FR-018 | The factory `AbilityScores.fromMap(Map<Ability, AbilityScore> scores)` MUST accept a map holding an `AbilityScore` for each of the six abilities. | SRD 5.2.1, "Ability Score and Modifier", p. 176 | happy |
| FR-019 | `AbilityScores.fromMap` MUST throw `ArgumentError` when any ability has no score, including an empty map. | SRD 5.2.1, "Ability Score and Modifier", p. 176 | unhappy (invalid input) |
| FR-020 | `AbilityScores.scoreOf(Ability)` MUST return the `AbilityScore` held for that ability, for all six abilities. | SRD 5.2.1, "Ability Score and Modifier", p. 176 | happy |
| FR-021 | `AbilityScores.withScore(ability, score)` MUST return a new `AbilityScores` that has the new score for that ability and the other five unchanged, and MUST NOT alter the original. | `doc/rules/architecture.md` §3 (immutability) | unhappy (immutability) |
| FR-022 | `AbilityScores` MUST NOT change when the map passed to `fromMap` is mutated afterwards. | `doc/rules/testing.md` §4 (immutability) | unhappy (immutability) |
| FR-023 | Two `AbilityScores` with the same score for every ability MUST be equal and have equal hash codes; differing in any one ability MUST NOT be equal. | `doc/rules/architecture.md` §3 (value object) | happy |
| FR-024 | `AbilityScores.modifierOf(Ability)` MUST return the `AbilityModifier` of the score held for that ability (equal to `scoreOf(ability).modifier`), for all six abilities. | SRD 5.2.1, "Ability Score and Modifier", p. 176 ("each of which has a corresponding modifier") | happy |
| FR-025 | `AbilityScore.minimum` MUST be 1 and `AbilityScore.maximum` MUST be 30, public constants other contexts reuse instead of repeating the bounds. | SRD 5.2.1, "Ability Scores", p. 5 | happy |
| FR-026 | `AbilityScoreRejection` (an enum with values `belowMinimum` and `aboveMaximum`) MUST be defined only here and exported once. No other spec defines a type of that name or re-exports its values. Character-level rejections (for example a score above 20) use differently named types owned by `character-aggregate.md`. | `shared-types-and-ownership.md` FR-001, FR-021 | unhappy (name collision) |
| FR-027 | `AbilityModifier` MUST expose `value`; it MUST NOT import or extend the kernel `Modifier`, and `Modifier` MUST NOT import it. Callers convert with `Modifier(abilityModifier.value)` (`character` and `combat` own that call). `RollModifiers.ability` is a plain `Modifier`, so `d20_test` tests need no ability scores. | `shared-types-and-ownership.md` FR-001, FR-003; `d20-tests.md` section 4.3 and D-16 | happy |
| FR-028 | An `ArgumentError` thrown by the `AbilityScore` constructor MUST carry `name` (`"value"`) and `invalidValue` (the rejected integer). | `errors-and-results.md` FR-027 | unhappy (invalid input) |
| FR-029 | `AbilityScore.tryCreate` MUST NOT throw for any `int`, including the minimum and maximum integers. | `errors-and-results.md` FR-025 | unhappy (invalid input) |
| FR-030 | `AbilityScore.tryCreate(n)` MUST return `InvalidAbilityScore` if and only if `AbilityScore(n)` throws. | `errors-and-results.md` FR-026 | unhappy (rule conflict) |
| FR-031 | `AbilityScoreResult`, `ValidAbilityScore` and `InvalidAbilityScore` MUST be `sealed` (the result) and `final` (the two variants), as `errors-and-results.md` FR-018 requires. | `errors-and-results.md` FR-018 | happy |

### Ability Modifiers table cases (FR-012 to FR-015)

One row per band of the Ability Modifiers table (SRD 5.2.1, p. 6). Each band
becomes two table-driven cases (lower and upper score), or one for a
single-score band, so all 30 scores are checked.

| Label | Scores | Modifier | Source | Path |
|---|---|---|---|---|
| lowest score | 1 | -5 | p. 6 | unhappy (boundary) |
| band 2-3 | 2, 3 | -4 | p. 6 | happy |
| band 4-5 | 4, 5 | -3 | p. 6 | happy |
| band 6-7 | 6, 7 | -2 | p. 6 | happy |
| band 8-9 | 8, 9 | -1 | p. 6 | unhappy (boundary) |
| human average | 10, 11 | +0 | p. 6 | unhappy (boundary) |
| band 12-13 | 12, 13 | +1 | p. 6 | happy |
| band 14-15 | 14, 15 | +2 | p. 6 | happy |
| band 16-17 | 16, 17 | +3 | p. 6 | happy |
| band 18-19 | 18, 19 | +4 | p. 6 | happy |
| band 20-21 | 20, 21 | +5 | p. 6 | happy |
| band 22-23 | 22, 23 | +6 | p. 6 | happy |
| band 24-25 | 24, 25 | +7 | p. 6 | happy |
| band 26-27 | 26, 27 | +8 | p. 6 | happy |
| band 28-29 | 28, 29 | +9 | p. 6 | happy |
| highest score | 30 | +10 | p. 6 | unhappy (boundary) |

The table is the sole authority. `floor((score - 10) / 2)` is not in SRD 5.2.1;
it is an implementation shortcut verified against all 30 rows and needs floor
division (not Dart's truncating `~/`). If it and the table disagree, the table
wins.

### Withdrawn ids

None.

## 5. Model

- `Ability`: enum of the six abilities (FR-001).
- `AbilityScore`: immutable value object wrapping an `int` in 1 to 30, with
  constants `minimum` (1) and `maximum` (30) (FR-025). The constructor is NOT
  `const`: it validates and throws `ArgumentError` with `name` and
  `invalidValue`, in release mode too (FR-003 to FR-007, FR-028); a `const`
  constructor could only `assert`, which throws in debug mode only.
  `tryCreate(int)` is the non-throwing factory for untrusted input (FR-008 to
  FR-010, FR-029, FR-030). Getter `modifier` (FR-012 to FR-015).
- `AbilityModifier`: immutable value object wrapping an `int` in -5 to +10, getter
  `value`, library-private `const` constructor `AbilityModifier._`. Both
  `AbilityScore` and `AbilityModifier` are declared in ONE library
  (`ability_score.dart`) so `AbilityScore.modifier` can call it and no outside
  code can build an out-of-range modifier.
- `AbilityScores`: immutable value object with exactly one `AbilityScore` per
  `Ability`. Non-`const` factory `fromMap(Map<Ability, AbilityScore>)` enforces
  completeness (FR-019) and keeps its own unmodifiable copy (FR-022). Members:
  `scoreOf` (FR-020), `modifierOf` (FR-024), `withScore` (FR-021). It exposes no
  collection, so `errors-and-results.md` FR-021 does not apply; consumers iterate
  `Ability.values`.
- Placement: `AbilityScores` is in `shared_kernel` because `character` and
  `combat` both need the complete set and neither may depend on the other
  (`doc/rules/architecture.md` §2). `content` monsters hold their own
  `AbilityBlock` (`content-monsters.md` FR-018). `Ability` and `AbilityModifier`
  are in the kernel because `d20_test` has no upstream context.
- Invariants: score in 1 to 30; modifier in -5 to +10; six scores present.
- Failures: an invalid score to a constructor, or an incomplete map to `fromMap`,
  throws `ArgumentError` (programmer error, `doc/rules/architecture.md` §6).
  Untrusted integers use `tryCreate`, returning the `sealed` `AbilityScoreResult`
  whose variants `ValidAbilityScore(score)` and `InvalidAbilityScore(value, reason)`
  are `final` (FR-031) and type-prefixed (FR-026). It is a
  value-object factory, not a use case, so the `<UseCase>Result` rule
  (`shared-types-and-ownership.md` FR-017) does not apply. `reason` is the enum
  `AbilityScoreRejection` (`errors-and-results.md` FR-035), data only, no display
  text (`errors-and-results.md` FR-020). All variants compare by value. No domain
  events.
- All types are `@immutable`, pure and synchronous. Only `AbilityModifier` and the
  result variants have `const` constructors.

## 6. Interface

- No use cases, commands, ports or async code; other contexts use these types
  directly in domain code (`doc/rules/architecture.md` §1).
- `shared_kernel` depends on nothing else in the package
  (`shared-types-and-ownership.md` FR-013).
- Exports from `lib/srd5e.dart`: `Ability`, `AbilityScore` (`minimum`, `maximum`,
  `tryCreate`, `value`, `modifier`), `AbilityModifier` (`value`), `AbilityScores`
  (`fromMap`, `scoreOf`, `modifierOf`, `withScore`), `AbilityScoreResult`,
  `ValidAbilityScore`, `InvalidAbilityScore`, `AbilityScoreRejection`. Every
  exported member has a dartdoc comment (`public_member_api_docs`).
- Layout: `lib/src/shared_kernel/ability/` with `ability.dart`,
  `ability_score.dart` (both `AbilityScore` and `AbilityModifier`),
  `ability_scores.dart`, `ability_score_result.dart` (also holds
  `AbilityScoreRejection`).

## 7. Observability

**Silent by design.** Pure `shared_kernel` value types stay free of
observability (`doc/rules/observability.md` §3). The seven questions:

1. **What can go wrong?** An out-of-range score or incomplete set: an
   `ArgumentError` (programmer error) or, for untrusted input, a `tryCreate`
   failure result.
2. **How would an operator know?** The `ArgumentError` propagates to the calling
   use case, whose span records it. A `tryCreate` failure is recorded by the use
   case at whose boundary it leaves srd5e, if any.
3. **What to diagnose it?** The rejected value and reason, carried by
   `InvalidAbilityScore` and named by field in the `ArgumentError`.
4. **Counted or timed?** Nothing; constant-time arithmetic.
5. **Existing instrumentation still correct?** Unaffected.
6. **What should a consumer monitor?** Nothing owned here. The expected caller of
   `tryCreate` is the content decoder for monster scores (`content-monsters.md`
   FR-018; `content-schema-and-decoder.md` FR-094 requires the decoder to use
   domain limit constants, here `AbilityScore.minimum` and `maximum`, not
   literals). It maps `InvalidAbilityScore` to its own
   `ContentProblem` (`srd5e.content.decode_errors` with
   `srd5e.content.problem_kind`) and does not use `error.type`, which a returned
   rejection lacks.
7. **Noisy?** No signals are added.

No signal is owned by this spec; `doc/observability/signals.md` is unchanged.

| Signal | Type | Attributes | Purpose | Suggested monitoring |
|---|---|---|---|---|
| none | | | | |

## 8. Test plan

No ports, so no doubles or contract suites. Plain unit tests in
`test/shared_kernel/ability/` mirroring `lib/src/shared_kernel/ability/`
(`ability_test.dart`, `ability_score_test.dart`, `ability_modifier_test.dart`,
`ability_scores_test.dart`; modifier tests import the barrel). Score-to-modifier
cases are table-driven from section 4.

| Id | Level | Notes |
|---|---|---|
| FR-001 | unit | The six values and their order. |
| FR-002 to FR-004 | unit | Loop 1 to 30, `value` round-trips; 1 and 30 accepted. |
| FR-005 to FR-007 | unit | 0, 31, -1 and the minimum int throw `ArgumentError` with `name` "value" and `invalidValue` equal to the input (`isA<ArgumentError>().having(...)`). |
| FR-008 | unit | `ValidAbilityScore` with the score for 1, 15 and 30. |
| FR-009, FR-010 | unit | `InvalidAbilityScore` with `belowMinimum` for 0, -5, minimum int; `aboveMaximum` for 31, 1000, maximum int; no throw. |
| FR-011 | unit | `ability_score_test.dart`: equal and unequal pairs, hash codes. |
| FR-016 | unit | `ability_modifier_test.dart`: equal and unequal pairs, hash codes. |
| FR-023 | unit | `ability_scores_test.dart`: equal sets and sets differing in one ability, hash codes. |
| FR-012 | unit | Table-driven, all 30 scores. |
| FR-013 | unit | 1 gives -5, 3 gives -4, 9 gives -1. Mutation target: truncation would give -4, -3, 0. |
| FR-014 | unit | 10 gives +0 (neighbours 9 gives -1, 11 gives +0, 12 gives +1). |
| FR-015 | unit | 1 gives -5; modifiers across all 30 scores stay in -5 to +10 (30 gives +10). Out-of-range modifiers cannot be built: the private constructor is enforced by the compiler and API review, so this enumeration is the test. |
| FR-017 | unit | `value` is the signed integer, e.g. -5, 0, +10. |
| FR-018, FR-020 | unit | A full map builds; for all six abilities `scoreOf` returns the input. |
| FR-019 | unit | Empty map and each single missing ability throw `ArgumentError`. |
| FR-021 | unit | Table-driven over six abilities: changed score for that ability, other five unchanged, original unchanged. |
| FR-022 | unit | Mutate the source map after `fromMap`; `AbilityScores` unchanged. |
| FR-024 | unit | For all six abilities `modifierOf` equals `scoreOf(a).modifier`, using scores that give different modifiers per ability. |
| FR-025 | unit | `minimum` is 1, `maximum` is 30. |
| FR-028 to FR-030 | unit | One table of 0, 1, 30, 31, minimum int, maximum int: the constructor accepts or throws `ArgumentError` with `name` "value" and `invalidValue` the input; `tryCreate` never throws and is `InvalidAbilityScore` exactly when the constructor throws. |
| FR-026 | architecture | Barrel scan (`shared-types-and-ownership.md` FR-017/FR-021): `AbilityScoreRejection` exported exactly once; no generic `BelowMinimum`/`AboveMaximum` exported. |
| FR-027 | architecture | Import check: `shared_kernel/ability/` and the `Modifier` library do not import each other. A unit test shows `Modifier(AbilityScore(20).modifier.value)` is `Modifier(5)`; the `RollModifiers` slot is tested in `d20-tests.md` section 4.3. |
| FR-031 | architecture | Part of the sealed-class scan (`errors-and-results.md` FR-018): `AbilityScoreResult` has only `final` direct subtypes. |

- Scenario: none. Architecture: the generic test that `shared_kernel` imports
  nothing else in the package covers these files, plus FR-026 and FR-027.
- Mutation testing (`doc/rules/testing.md` §8): the full Docker command there
  (pinned `mutate4dart` 0.12.2, coverage first with
  `dart run coverage:test_with_coverage`), target `lib/src/shared_kernel/ability`.
  Likely targets: the range checks (`< 1`, `> 30`), the floor division and the
  band boundaries; the boundary rows exist to kill them.
- Consumers get an `AbilityModifier` in their own tests with
  `AbilityScore(n).modifier` (20 gives +5, 8 gives -1, 10 gives +0).
- The private `AbilityModifier` constructor and non-`const` `AbilityScore`
  constructor are compile-time properties, not tested directly. Every FR id is
  covered.

## 9. Open questions and decisions

Settled: `AbilityModifier` to `Modifier` conversion is by callers
(`shared-types-and-ownership.md` FR-003, FR-027 here); `AbilityScoreRejection`
single definition (`shared-types-and-ownership.md` FR-001, FR-026 here);
`AbilityScores` is a kernel type (decided here, section 5); no 20 cap and no score of 0 (section 1);
the floor formula is acceptable, with the table as source of truth (section 4).

Settled, one line each:

- **Q-1 (decided amendment, roadmap).** `doc/roadmap.md` Phase 0 must list `Ability`, `AbilityScore`, `AbilityModifier`, `AbilityScores`, and Phase 3 must drop "Ability modifiers" (`shared-types-and-ownership.md` FR-001 and FR-014 already make them kernel types, phase 0). Score generation stays out of scope. The roadmap owner applies this edit; this spec does not touch that file.
- **Q-2 (decided amendment, shared types).** `shared-types-and-ownership.md` FR-001 adds `AbilityScores` to its `shared_kernel` list, with this spec as owner. The owner of that spec applies the edit.
- **Q-3 (decided: no).** SRD abbreviations (p. 176) are not exposed on `Ability`: display text. Revisit if `content` needs them for decoding.
- **Q-4 (decided: no).** `AbilityScore` does not implement `Comparable` now; add when a use case needs ordering.

## 10. Changelog impact

Added: `Ability`, `AbilityScore` (range 1 to 30, `minimum`, `maximum`,
non-throwing `tryCreate` returning `AbilityScoreResult`), `AbilityModifier`
(derivation from the Ability Modifiers table), `AbilityScores` (`scoreOf`,
`modifierOf`, `withScore`) and the enum `AbilityScoreRejection`. Not
**BREAKING**: all new exports in a first release.
