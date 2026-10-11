# Phase 1 plan: the `d20_test` context

| | |
|---|---|
| Status | proposed |
| Roadmap phase | 1 ([../roadmap.md](../roadmap.md)) |
| Specs implemented | [../specs/d20-tests.md](../specs/d20-tests.md) (draft → implemented), [../specs/resolve-d20-test-use-case.md](../specs/resolve-d20-test-use-case.md) (draft → implemented) |
| Depends on | Phase 0 (done 2026-10-09): kernel, ports, doubles, guardrails |

## 1. Goal

Ship the whole `d20_test` bounded context as a vertical slice: the pure
domain model of D20 Tests (ability checks, saving throws, attack rolls, DCs
and ACs, Advantage and Disadvantage application, natural 20 and natural 1,
success and failure, rerolls and forced failure), then the package's first
use case `ResolveD20Test` with its command and sealed result types, its full
telemetry contract, and the first scenario test. Phase 1 has no upstream
context; the domain imports only `shared_kernel`, the application only
`domain`, `shared_ports` and `shared_kernel`.

The use case is the **reference template for every later use case**
(constructor injection, error handling, result naming, telemetry shape), so
PR 3 should be reviewed with that in mind.

Both specs state "No open questions" and carry settled decisions (D-01 to
D-22 in d20-tests.md, plus the ownership table in
resolve-d20-test-use-case.md §1). This plan sequences and traces them; it
changes no decision. Where this plan and a spec disagree, the spec wins and
this plan changes.

## 2. What already exists (Phase 0, reused as-is)

| Asset | Where | Used for |
|---|---|---|
| `Modifier`, `RollMode` (`resolve`, `diceCount`, `select`), `RollCircumstance`/`Advantage`/`Disadvantage` | `lib/src/shared_kernel/` | `RollModifiers` slots, mode resolution, kept-die selection (d20-tests.md FR-009 to FR-011 delegate to `RollMode.select`) |
| `Ability` (six values) | `lib/src/shared_kernel/ability/` | command label and `srd5e.ability` attribute |
| `Die.d20`, `DiceExpression` | `lib/src/shared_kernel/dice/` | the `1d20` / `2d20` dice request |
| `DiceRoller` + `rollChecked` (`DiceRollerChecked`), `DiceRollerException` | `lib/src/shared_ports/dice_roller/` | the one dice request per rolling call; `invalidResult` enforcement |
| `Observability` (`Logger`, `Tracer`, `Meter`), `NoopObservability`, `AttributeKeys` | `lib/src/shared_ports/observability/` | telemetry; shared keys `srd5e.outcome`, `error.type` |
| `FixedDiceRoller` (+`requests`), `CallbackDiceRoller`, `RecordingObservability`/`RecordingTracer`/`RecordingMeter` (`timedDuration`)/`RecordingLogger` | `lib/src/testing/`, exported by `lib/testing.dart` | application tests; **no new double is added in Phase 1** |
| Architecture guardrail suite (context map, layering, barrel scan, domain purity, banned calls, signal catalogue and constants, use-case calls, spec conformance, test citations) | `test/architecture/` | enforces the rules below; extended, not replaced |
| Signal catalogue | `doc/observability/signals.md` | has **no** `d20_test` rows yet; PR 3 adds the five |

No new port, test double or contract suite is introduced (both specs §6/§8).
`lib/adapters.dart` and `NOTICE.md` are untouched: no content is bundled and
tests only cite the SRD by section and page.

## 3. Scope fence

**In scope:** every live requirement of the two specs — d20-tests.md FR-009
to FR-036, FR-041, FR-050 to FR-052, FR-055, FR-058 to FR-062, FR-063 to
FR-073; resolve-d20-test-use-case.md FR-001, FR-002, FR-005 to FR-018,
FR-020 to FR-032, FR-035 to FR-047, FR-049, FR-051 to FR-053, FR-055 to
FR-058.

**Out of scope** (from the specs' own lists; do not drift here):

- Death Saving Throws, damage, extra Critical Hit dice, contests, group and
  passive checks, automatic success/failure on natural 20/1 for checks and
  saves (the SRD states it for attack rolls only, p. 7).
- Heroic Inspiration as a use case or command option; only the reroll
  *operations* on `D20Roll` ship (`RerollDecision`, FR-059).
- Deriving ability modifiers, Proficiency Bonus, AC calculation, which skill
  uses which ability, sources of Advantage/Disadvantage, Exhaustion and
  condition effects: callers supply finished values.
- Any `content`, `character`, `combat` or `toolbox` work; any bundled data;
  any change to `shared_kernel` or `shared_ports` (a need for one is a
  design smell to raise, not to fix silently).
- Editing either spec's requirements. New gaps found while coding get a new
  FR id or a new spec (roadmap planning note 1), never a renumbering.

## 4. Delivery sequence

Three PRs, each independently green, sized for review. The split is by
dependency, not by layer-at-a-time: PR 1 and PR 2 each ship tested value
objects with real behaviour; PR 3 ships the orchestration slice.

| PR | Ships | Spec progress | Flips |
|---|---|---|---|
| 1 | Domain value objects: `D20Roll`, `RerollDecision`, `RollModifiers`, `DifficultyClass`, `ArmorClass`, `D20TestKind`, `D20TestOutcome`, `ForcedFailureReason`; the context barrel; public exports; CI mutation path | d20-tests.md partial (shapes, immutability, DC/AC, enums) | — |
| 2 | Domain results and resolution: `CheckResult`, `AttackRollResult`, `ForcedFailureResult`, `D20TestResolver`, static delegates, `adjustedBy`, critical range | d20-tests.md complete | d20-tests.md → `implemented` |
| 3 | Application: commands and attempts, `ResolveD20Test`, `ResolveD20TestResult`, `D20TestSignals`, telemetry, application tests, scenario test, catalogue rows, guardrail additions | resolve-d20-test-use-case.md complete | resolve-d20-test-use-case.md → `implemented` |

**Process contract for every PR** (from `AGENTS.md` and the rule files):

- Full check green before review: `dart format --set-exit-if-changed`,
  `dart analyze --fatal-infos`, whole suite with
  `--test-randomize-ordering-seed=random`, coverage generated
  (`coverage/lcov.info`), all in Docker (command in `AGENTS.md`).
- Every changed or added line in `domain/` and `application/` covered;
  uncovered lines need a stated reason (testing.md §7).
- Mutation testing over `lib/src/shared_kernel lib/src/shared_ports
  lib/src/d20_test/domain` with `--diff-base` the PR's base branch,
  threshold 80, Docker-capped jobs (testing.md §8). Survivors are fixed with
  better tests, not silenced, unless provably equivalent.
- `CHANGELOG.md` under `Unreleased` / **Added**; text comes from the specs'
  §10. Not **BREAKING** (first release of these members).
- PR description carries `Testing` and `Observability` entries
  (`.github/pull_request_template.md`).
- Every `group(`/`test(` outside `test/architecture/` carries
  `Requirement:` and `Path:` doc comments citing `doc/specs/<name>.md FR-<n>`
  (testing.md §5; enforced by the citation guardrail).

## 5. PR 1 — domain value objects

**Files** (suggested granularity; the specs fix names and API, not files):

- `lib/src/d20_test/domain/d20_roll.dart` — `D20Roll` (`mode`, `dice`
  unmodifiable copy, `natural` via `RollMode.select`, `keptIndex` FR-058,
  `replaceDie` FR-012 to FR-014, `applyReroll` FR-059; no replaced state
  FR-067).
- `lib/src/d20_test/domain/reroll_decision.dart` — sealed
  `RerollDecision`: `KeepRoll`, `RerollDie(dieIndex)`.
- `lib/src/d20_test/domain/roll_modifiers.dart` — `RollModifiers(ability:
  Modifier, proficiencyBonus: Modifier?, others: Iterable<Modifier>)` with
  unmodifiable copy of `others` (FR-061); the kernel-sum total is exercised
  in PR 2 through the resolve members, as the spec's test plan directs.
- `lib/src/d20_test/domain/difficulty_class.dart`,
  `lib/src/d20_test/domain/armor_class.dart` — integer wrappers, value
  equality, `DifficultyClass.veryEasy`…`nearlyImpossible` (FR-021, FR-022,
  D-02: no range check).
- `lib/src/d20_test/domain/d20_test_kind.dart`,
  `d20_test_outcome.dart`, `forced_failure_reason.dart` — the three enums
  (FR-060: `D20TestOutcome` is exactly `success`/`failure`).
- `lib/src/d20_test/d20_test.dart` — the context barrel, created here with
  the domain exports of d20-tests.md §6; PR 3 adds the application exports.
  Library doc comment lists inputs and outputs (architecture.md §4).
- `lib/srd5e.dart` — export the new types from the barrel (dartdoc on every
  exported member; the kernel types are **not** re-exported through the
  barrel).
- `.github/workflows/ci.yml` — add `lib/src/d20_test/domain` to the
  mutation job's path list, in the same change that creates the folder's
  code (testing.md §8).
- `CHANGELOG.md` — the d20-tests.md §10 domain bullet.

**Tests** (`test/d20_test/domain/`, mirroring the layout; unit level, no
doubles):

- `d20_roll_test.dart`: the 29-row reroll table of d20-tests.md §4.2 as a
  `const` list of records, one `test` per row, `Requirement: per case`,
  `Path: per case` (FR-009 to FR-015, FR-055, FR-058, FR-059, FR-067,
  FR-068; boundary rows 0/1/20/21, first/last index, equal dice).
- `roll_modifiers_test.dart`: shape and immutability — required ability
  slot, single nullable Proficiency Bonus slot, `others` copy and
  `UnsupportedError`, empty default (FR-017, FR-018, FR-061).
- `target_numbers_test.dart`: the eleven FR-021/FR-022 cases (constants,
  cross-type inequality, equal hash codes) plus FR-050 equality for the
  types present.
- `d20_test_outcome_test.dart`: exhaustive two-case `switch` (FR-060).
- `ArgumentError` assertions use `name` and `invalidValue`, never message
  text (errors-and-results.md FR-027, d20-tests.md §5).

**Definition of done:** full check green; mutation ≥ 80 over
`lib/src/d20_test/domain`; barrel scan and layering guardrails pass with the
new folder populated; changelog entry present.

## 6. PR 2 — domain results and `D20TestResolver`

**Files:**

- `lib/src/d20_test/domain/check_result.dart` — `CheckResult` with the
  published static `resolve` (FR-063) and `adjustedBy` (FR-065).
- `lib/src/d20_test/domain/attack_roll_result.dart` — `AttackRollResult`
  with `isCriticalHit`, `hit`, `criticalRange` (default 20, FR-073), static
  `resolve` (FR-064) and `adjustedBy` (FR-065, FR-066).
- `lib/src/d20_test/domain/forced_failure_result.dart` —
  `ForcedFailureResult` with static `of` (FR-035, FR-036); no `adjustedBy`.
- `lib/src/d20_test/domain/d20_test_resolver.dart` — the stateless `const`
  `D20TestResolver` (FR-069): `resolveCheck` (FR-062 rejects `attackRoll`),
  `resolveAttackRoll` (FR-027 to FR-033, FR-071, FR-072 range 18/19/20),
  `forcedFailure` (FR-052 rejections). Static members delegate to it
  (FR-070); both forms stay behaviourally identical.
- Barrel and `lib/srd5e.dart` extended with these types.
- `doc/specs/d20-tests.md`: Status → `implemented`.

**Tests** (`test/d20_test/domain/`):

- `roll_modifiers_total_test.dart` or rows inside the result suites: the
  12-row total table (FR-016, FR-019, FR-020 with a permutation of every
  row's `others`) through `CheckResult.resolve` /
  `AttackRollResult.resolve`, as the spec's test plan directs.
- `check_result_test.dart`: the 14-row check/save resolution table run for
  **both** kinds (FR-023 to FR-026, FR-031; natural 20/1 rows prove no
  natural rule for checks and saves).
- `attack_roll_result_test.dart`: the 28-row attack table by row group —
  ordinary, natural 20, natural 1, natural 19, critical range 19/18 and the
  invalid 17/21 rows, Advantage/Disadvantage kept-die rows, extremes
  (FR-027 to FR-034, FR-051, FR-071 to FR-073).
- `re_resolution_test.dart`: the 14-row table of rerolled/replaced/
  `adjustedBy` cases (FR-063 to FR-066), including "adjustment leaves the
  original".
- `forced_failure_result_test.dart`: the 6-row table (FR-035, FR-036,
  FR-052).
- `d20_test_resolver_test.dart`: the same resolution rows through the
  resolver, and FR-070 — every row through both the resolver and the static
  member yields equal results and the same `ArgumentError`.
- `result_shape_test.dart`: FR-041 field coverage per variant,
  unmodifiable collections; FR-050 equality/hash for every handoff type,
  one inequality case per field.
- FR-060's barrel half (no `AttackOutcome`-style exports) is the existing
  architecture scan; verify the forbidden names of FR-042/§6 are covered,
  extend the scan's name list if not.

**Flipping the spec to `implemented`** switches on the FR-055 guardrail:
every live FR id of d20-tests.md must then be cited by at least one test,
except ids its §8 lists under `Deliberately not covered`. Before flipping,
audit citations against the spec's §8 test-plan mapping (its
"Not covered at runtime" note names the analyzer-enforced items); add the
`Deliberately not covered` lines the spec's §8 wording implies, with
non-empty reasons, only for ids with genuinely no runtime test.

**Definition of done:** as PR 1, plus FR-055 clean for d20-tests.md and the
full domain mutation score reported in the PR description.

## 7. PR 3 — `ResolveD20Test` use case, telemetry, scenario

**Files:**

- `lib/src/d20_test/application/d20_test_command.dart` — sealed
  `D20TestCommand`: `AbilityCheckCommand`, `SavingThrowCommand`,
  `AttackRollCommand` (FR-001, FR-005, FR-056).
- `lib/src/d20_test/application/d20_test_attempts.dart` — sealed
  `CheckAttempt` (`RollAttempt`, `AutomaticFailure`) and `SaveAttempt`
  (`RollAttempt`, `ChooseToFail`, `AutomaticFailure`); `RollAttempt` copies
  `circumstances`.
- `lib/src/d20_test/application/resolve_d20_test_result.dart` — sealed
  `ResolveD20TestResult`: `ResolveD20TestRolledCheck`,
  `ResolveD20TestRolledAttack`, `ResolveD20TestForcedFailure` (FR-018,
  FR-020, FR-049, FR-053; typed targets per variant).
- `lib/src/d20_test/application/resolve_d20_test.dart` — the use case; one
  `RollMode.resolve`, one `rollChecked` request sized by the mode, no
  request for forced failures, composes `D20TestResolver` only (FR-006,
  FR-007, FR-026, FR-051, FR-057, FR-058).
- `lib/src/d20_test/application/d20_test_signals.dart` — the single
  `abstract final class D20TestSignals` of name and attribute-key constants
  (FR-040; file name ends `signals.dart` by guardrail rule).
- Barrel completed per FR-042 (exact export list, including `D20TestSignals`;
  the MUST-NOT-export names absent); `lib/srd5e.dart` re-exports.
- `doc/observability/signals.md` — the five rows of resolve-d20-test-use-case.md
  §7 (`srd5e.d20_test.resolve`, `.resolved`, `.duration`, `.modifiers`,
  `.errors`), purpose and suggested monitoring filled. Must land in the same
  PR as the code constants (catalogue consistency guardrail).
- `doc/documentation_index.md` — update the `observability/signals.md` row's
  summary (it currently says "currently the spell-outcome-table and
  containment signals").
- `doc/specs/resolve-d20-test-use-case.md`: Status → `implemented`.
- `CHANGELOG.md` — the use-case and signals bullets from §10.

**Tests:**

- `test/d20_test/application/d20_test_command_test.dart` — build/equality/
  immutability per variant (FR-001, FR-005, FR-056).
- `test/d20_test/application/resolve_d20_test_test.dart` — the 17-row
  end-to-end case table with `FixedDiceRoller` (FR-002, FR-006, FR-007,
  FR-010, FR-028, delegated rows as application smoke); full result-shape
  and command-untouched rows (FR-018, FR-022, FR-058); `ability` label
  disagreement (FR-055); determinism and omitted-`Observability`
  construction (FR-023 to FR-025); `CallbackDiceRoller` failures — thrown
  `DiceRollerException` propagates with exactly one request on record,
  wrong-expression `invalidResult`, `StateError` propagates uncounted
  (FR-026, FR-027, FR-037, FR-051); telemetry with the recording doubles —
  span name and attribute lifecycle, one `resolved` increment,
  `timedDuration` 250 ms proving the 0.25 s record, modifiers histogram,
  forced-failure attribute absence, failure-recording exactly once, zero
  log records at `finest` (FR-029 to FR-032, FR-035, FR-036, FR-038, FR-039,
  FR-041, FR-046, FR-047, FR-052); no-op versus recording identity over the
  whole table (FR-039).
- `test/scenarios/resolve_d20_test_scenario_test.dart` — the first scenario
  test (FR-042): imports only `package:srd5e/srd5e.dart` and
  `package:srd5e/testing.dart`, resolves one check, one save, one attack
  roll and one chosen failure with a fixed roller and recording
  observability, covering Advantage.
- Architecture additions/verification in `test/architecture/`: FR-044 (no
  `String` field or getter in the result declarations under
  `lib/src/d20_test/`) as a new or extended check with self-test fixtures
  following the suite's `_self_test`/`_test` pattern and `registry.dart`;
  verify FR-045 (application purity scan) and FR-057 (`use_case_calls`,
  FR-097 of architecture-guardrails.md) already cover their claims — extend
  only a real gap.

**Flipping the spec** — same FR-055 audit as PR 2; the spec's §8 "Not
covered (analyzer-enforced)" note names the ids that may need
`Deliberately not covered` lines (type pairings, exhaustive switch,
synchronous return).

**Definition of done:** as PR 2 for the resolve spec; catalogue rows match
the constants; scenario test green through the public API only.

## 8. Requirement traceability

Per-id test mapping lives in the specs' own §8 (authoritative). This matrix
fixes slice ownership; an id may not close until its §8 row has its test.

| Ids | PR | Primary code | Test level |
|---|---|---|---|
| d20-tests FR-009 to FR-015, FR-017, FR-018, FR-021, FR-022, FR-055, FR-058, FR-059, FR-061, FR-067, FR-068 | 1 | `domain/d20_roll.dart`, `roll_modifiers.dart`, `difficulty_class.dart`, `armor_class.dart` | unit |
| d20-tests FR-060 | 1 (+2 barrel half) | `domain/d20_test_outcome.dart` | unit + architecture |
| d20-tests FR-050 | 1–2 | the value objects (1), the results (2) | unit |
| d20-tests FR-016, FR-019, FR-020 | 2 | `RollModifiers` total via the resolve members | unit |
| d20-tests FR-023 to FR-036, FR-041, FR-051, FR-052, FR-062 to FR-073 | 2 | `check_result.dart`, `attack_roll_result.dart`, `forced_failure_result.dart`, `d20_test_resolver.dart` | unit |
| resolve FR-001, FR-002, FR-005, FR-055, FR-056 | 3 | `d20_test_command.dart`, `d20_test_attempts.dart` | unit |
| resolve FR-006 to FR-018, FR-020 to FR-022, FR-024 to FR-028, FR-043, FR-058 | 3 | `resolve_d20_test.dart`, `resolve_d20_test_result.dart` | application |
| resolve FR-023, FR-049 | 3 | `resolve_d20_test.dart`, `resolve_d20_test_result.dart` | application |
| resolve FR-029 to FR-032, FR-035 to FR-039, FR-041, FR-046, FR-047, FR-052 | 3 | `resolve_d20_test.dart`, `d20_test_signals.dart` | application + catalogue |
| resolve FR-040, FR-044, FR-045, FR-053, FR-057 | 3 | `d20_test_signals.dart`, result declarations | architecture |
| resolve FR-042 | 3 | barrel, `lib/srd5e.dart`, `signals.md` | scenario + architecture |

Withdrawn and never-issued ids (d20-tests §4.7; resolve §4 "Withdrawn ids")
have no row here, per FR-055's moved-id exemption.

## 9. Verification commands

Full check, as CI runs it (Docker; `AGENTS.md`):

```sh
docker run --rm -v "$PWD":/app -w /app dart:stable sh -c \
  "dart pub get && dart format --set-exit-if-changed . && dart analyze --fatal-infos && dart run coverage:test_with_coverage -- --test-randomize-ordering-seed=random"
```

Mutation testing, after coverage exists (testing.md §8; Docker CPU cap;
never `--jobs 1`):

```sh
cpus=$(( $(nproc) / 4 )); cpus=$(( cpus < 2 ? 2 : cpus ))
docker run --rm --cpus="$cpus" -v "$PWD":/app -w /app dart:stable sh -c \
  "dart pub get && dart pub global activate mutate4dart 0.12.2 && \
   dart run coverage:test_with_coverage && \
   /root/.pub-cache/bin/mutate4dart lib/src/shared_kernel lib/src/shared_ports \
     lib/src/d20_test/domain --diff-base <pr-base> --threshold 80 --jobs $cpus"
```

`<pr-base>` is the PR's base branch (for PR 1 against `main`, later PRs
against the previous PR's branch or `main` if stacked flat). CI's mutation
job gets `lib/src/d20_test/domain` added in PR 1 and runs it with
`--jobs 2`.

## 10. Risks and mitigations

| Risk | Mitigation |
|---|---|
| Review size: ~120 table-driven domain rows in PRs 1–2 | The split at the results boundary; rows are generated from the specs' `const` tables, so review is of the tables, not of hand-written cases |
| FR-055 flips on with the status change and fails the build | Audit citations before flipping (§6, §7); the failure is the guardrail working — add the missing test, not a `Deliberately not covered` line |
| Catalogue/constants mismatch fails the guardrail mid-PR | Land `D20TestSignals` and the `signals.md` rows in the same PR 3 commit sequence; run the architecture suite locally before pushing |
| Telemetry contract drift (the reference template for later use cases) | Pin tests assert literal names and attribute keys (FR-040); review PR 3 against observability.md §5 to §7 explicitly |
| `application/` purity or use-case-call guardrail gaps surface late | PR 3 starts by running the full architecture suite against a skeleton, before the telemetry work |
| Kernel API mismatch discovered mid-implementation (e.g. `RollMode.select` shape) | Stop and raise it; do not fork the rule into `d20_test` — the kernel owns mode selection (D-01) |

## 11. Out-of-scope observations (recorded, not acted on)

- resolve-d20-test-use-case.md §9 already flags sibling follow-ups:
  class-barbarian.md FR-089/FR-093/FR-115 must stop calling `ResolveD20Test`
  (compose `D20TestResolver` instead), and social-interaction.md FR-043 must
  drop `roll_mode: normal` for forced failures. Both are later-phase spec
  edits; Phase 1 does not touch them.
- `doc/plans/` is new with this plan; `doc/documentation_index.md` gains a
  row for it, and later phase plans follow this file's shape.

## 12. Reporting

Each PR description and the phase-closing summary carry, per
`AGENTS.md`:

- **Testing**: tests added by level, happy/unhappy coverage, requirements
  covered, mutation score and survivors, coverage of changed lines,
  anything deliberately uncovered with its reason.
- **Observability**: for PR 1–2, the specific justification (domain silent
  by design, d20-tests.md §7 — no signal, no catalogue change); for PR 3,
  the five signals added, their attribute sets, and what a consumer should
  monitor (resolve-d20-test-use-case.md §7's table is the text).

Phase 1 is done when: both specs read `implemented`, the full check and
mutation gate pass, the catalogue holds the five `d20_test` signals, the
scenario test exists, and the changelog carries both entries.
