# srd5e Testing Rules

Normative. MUST / MUST NOT / SHOULD are binding on all code and review.
Read together with [architecture.md](architecture.md) (§8 sets the per-layer
test approach) and [observability.md](observability.md) (§9 covers testing
telemetry).

## 1. Principles

1. **Every change is tested.** No behaviour is added, changed, fixed or removed
   without tests that would fail if it broke. "Tests pass" only means something
   if the right tests exist.
2. **Follow the test pyramid.** Many fast, isolated tests at the base; fewer,
   broader tests as you go up. Do not invert it.
3. **Test the unhappy paths as seriously as the happy path.** Rules engines fail
   at edges: boundaries, invalid input, stacking conflicts, missing content.
4. **Tests document requirements.** Each test says what requirement or rule it
   verifies, so a reader can trace from requirement to test and back.
5. **Tests are deterministic and independent.** The same result every run, in
   any order.

---

## 2. Evaluating test coverage is mandatory

For **every change** (new feature, changed behaviour, new port or adapter,
refactor, bug fix) you MUST work out what tests it needs before you finish. Do
the thinking; do not just add one test and move on.

1. **What behaviour changed?** List each observable behaviour added, altered or
   removed.
2. **Which pyramid level tests each?** Prefer the lowest level that can prove
   it (§3).
3. **What is the happy path?** The ordinary, valid, expected case.
4. **What are the unhappy paths?** Walk the checklist in §4 and cover every item
   that applies.
5. **Which requirement or rule does each test verify?** Identify it and cite it
   (§5). If there is none, say so.
6. **Is existing coverage now wrong or stale?** Update or remove tests that
   encode old behaviour. Do not leave them failing, skipped or lying.
7. **What could still break without a test noticing?** Check the tests would
   fail if the implementation were wrong (§8).

### The outcome

- Write the tests the evaluation calls for.
- Your PR description (see `.github/pull_request_template.md`) and final
  summary MUST contain a `Testing` entry:
  tests added or changed, by pyramid level; which happy and unhappy paths and
  requirements they cover; and anything deliberately not covered, with the
  reason.
- If a change adds no tests, justify it specifically (for example: "comment
  only change"; "pure rename, covered unchanged by existing `check_test.dart`").
  "Covered by existing tests" or "N/A" alone is not acceptable.
- **Bug fixes:** first write a test that reproduces the bug and watch it fail,
  then fix, then watch it pass. Keep the test as the regression test and cite
  the bug.
- Reviewers MUST reject a change that lacks the evaluation, the tests or the
  report.

---

## 3. The test pyramid

```
              /\
             /  \        Scenario tests         few, slow-ish, whole slices
            /----\       through the public API
           /      \
          /--------\     Application + contract tests    some
         /          \    real domain, test-double ports; adapters vs port contract
        /------------\
       /              \  Unit tests (domain)            many, tiny, instant
      /----------------\ no ports, no I/O, no doubles
```

Cross-cutting guardrail, outside the pyramid: architecture tests (§9).

| Level | Location | What it proves | Uses | Share |
|---|---|---|---|---|
| **Unit** | `test/<context>/domain/` | Rules logic: value objects, entities, aggregates, domain services. Every rule, edge and invariant. | Nothing but the code under test | The large majority |
| **Application** | `test/<context>/application/` | A use case orchestrates correctly: calls ports, returns the right result, emits the right telemetry. | Real domain; **test doubles** for ports | Substantial |
| **Contract** | `test/<context>/adapters/` and `test/contract/` | Each adapter honours its port's contract; every implementation of a port passes the same shared contract suite. | The real adapter | Moderate |
| **Scenario** | `test/scenarios/` | Several contexts work together through `package:srd5e/srd5e.dart` only, end to end for a realistic situation. | Public API, test doubles for the outside world | Few |

Rules:

- **Test at the lowest level that can prove the behaviour.** If a unit test can
  prove it, do not prove it with a scenario test.
- **Every rule gets unit tests.** Scenario tests supplement them; they never
  replace them.
- **Do not build an ice-cream cone.** Many scenario tests and few unit tests is
  a defect. Slow, broad tests catch regressions late and point nowhere.
- **No inverted dependencies.** A unit test imports no ports or doubles. If it
  needs one, the design or the level is wrong.
- Scenario tests MUST import only the public API, never `src/`, so they also
  protect the consumer-facing contract.
- Tests mirror `lib/src/` in `test/`, except `test/architecture/`,
  `test/contract/` and `test/scenarios/`.

---

## 4. Happy and unhappy paths

Every behaviour is tested for the happy path **and** for each applicable
unhappy path. A suite with only happy-path tests is incomplete.

### Happy path

The normal, valid case with typical inputs and the expected outcome. Cover every
distinct valid outcome, not just one (for a D20 Test: both success and failure).

### Unhappy-path checklist

Work through every item and cover the ones that apply.

- **Boundaries:** exactly at, one below and one above every threshold (DC
  differences of ±10, natural 1 and natural 20, min/max level, zero, negative,
  maximum values).
- **Invalid input:** out of range, wrong type, empty, null where nullable is
  allowed, malformed or contradictory data. Constructors reject invalid
  instances.
- **Empty and minimal cases:** no modifiers, no targets, an empty collection,
  the lowest level.
- **Rule interactions and conflicts:** several modifiers on one roll, Advantage
  and Disadvantage together, several conditions at once, ordering effects.
- **Failure of collaborators:** a port that throws its typed exception,
  returns its not-found or rejected result, or returns invalid data (through
  the test doubles).
- **Missing or bad content:** unknown id, missing field, unsupported version,
  duplicate entries, content that fails to decode.
- **State errors:** an action that is illegal in the current state, a repeated
  or out-of-order action.
- **Determinism and randomness:** results for fixed rolls, including extremes.
  Never depend on an unseeded roller.
- **Immutability:** an operation does not alter its inputs; a returned
  collection cannot be mutated.
- **Telemetry on failure:** failures are observable as required by
  [observability.md](observability.md).

### Expected outcomes vs errors

Follow the error model in [architecture.md](architecture.md) §6:

- A failed check, an illegal-but-expected action, missing content or invalid
  untrusted input is a **result**; assert the exact result variant and data.
- A port's infrastructure failure is a typed `Srd5eException`; assert the type,
  its data and that the use case propagates it.
- A programmer error throws an `Error` (`ArgumentError`, `StateError`); assert
  with `throwsA(isA<ArgumentError>())` and relevant fields, not the message
  text.

For each unhappy test, assert something specific: the exact result or error
type. A test that only checks "does not crash" is not an unhappy-path test.

---

## 5. Tests document requirements

Every test and test group SHOULD record the requirement or rule it verifies.
Where a PRD, spec, ticket or rule source exists, it MUST.

### Format

Place a doc comment immediately above the `group` or `test`:

```dart
/// Requirement: doc/specs/d20-tests.md FR-012 - a total that equals the DC
///   succeeds (SRD 5.2.1, "D20 Tests", p. 6).
/// Path: happy
test('total equal to the DC succeeds', () { ... });

/// Requirement: doc/specs/d20-tests.md FR-013 - a total one below the DC
///   fails (SRD 5.2.1, "D20 Tests", p. 6).
/// Path: unhappy (boundary)
test('total one below the DC fails', () { ... });
```

Fields:

| Field | Meaning |
|---|---|
| `Requirement:` | Path to the PRD/spec/doc and the requirement id or section, plus a short paraphrase. For an SRD rule, cite the section and page, e.g. `SRD 5.2.1, "D20 Tests", p. 6`. |
| `Path:` | `happy`, or `unhappy` with the kind in brackets (boundary, invalid input, failure, ...) |

Additional fields when useful: `Rule:` (game rule source), `Bug:` (ticket or
issue for a regression test), `Note:` (a non-obvious reason).

### Rules

- **Cite precisely.** A path and requirement id (or section heading), not just
  "see the spec". A reader MUST be able to find the requirement from the
  comment.
- **If implementing a PRD or spec, every test MUST cite the requirement it
  covers,** and every requirement SHOULD be covered by at least one test. After
  implementing, check each requirement has a test; list any that do not.
- **If the spec has no ids, add them** (or cite the section heading) rather than
  skipping the citation.
- **If there is no governing document,** say what behaviour the test pins in a
  `Requirement:` comment in your own words (for example `Requirement: none -
  pins current behaviour of ...`). Do not invent a citation.
- **One requirement per behaviour, not one per file.** Cite at group or test
  level. A file-level comment alone is not enough.
- **Table-driven tests cite per row.** Put the doc comment on the loop (or the
  enclosing `group`) with `Requirement: per case` and `Path: per case`. Each
  case in the table then carries its own `requirement` and `path` fields, and
  the generated test name includes the case label, so a failure points at one
  row and one requirement:

  ```dart
  /// Requirement: per case
  /// Path: per case
  for (final c in d20TestCases) {
    test('${c.label} [${c.path}]', () { ... });
  }
  ```

  where each `c` is built like
  `(label: 'total equals the DC', requirement: 'SRD 5.2.1, "D20 Tests", p. 6', path: 'unhappy (boundary)', ...)`.
- **Keep citations true.** When a requirement changes, update or remove the
  tests and their comments.
- **Cite, do not copy.** Reference an SRD rule by section and page. Quote only
  what a test needs to be understood, and only from SRD 5.2.1. Nothing from
  outside the SRD belongs in tests (see "Licensing and source material" in
  `AGENTS.md`).

---

## 6. Writing good tests

- **One behaviour per test.** A failing test names one thing that broke.
- **Names state behaviour and condition** in plain language:
  `'natural 20 improves success to critical success'`, not `'test1'`.
- **Arrange, act, assert,** visibly separated. No logic (loops, branches,
  conditionals) in the assertion path; use table-driven tests with named cases
  for variations.
- **Table-driven tests for rule maths.** Enumerate inputs and expected outputs
  in a readable table (a `const` list of records), each row with a label,
  requirement and path (§5). Generate one `test` per row; the loop that
  generates tests is not "logic in the assertion path".
- **Assert outcomes, not implementation.** Check results and observable
  effects, not private calls or call order, unless order is the requirement.
- **Specific assertions.** Exact values and types over `isNotNull` or
  `isTrue` on a vague expression.
- **Deterministic.** Use a fixed or seeded roller. No `Random()`,
  `DateTime.now()`, real network or real filesystem. Durations are recorded
  through the observability ports, so the recording doubles control them.
- **Independent.** No shared mutable state, no dependency on test order, no
  leftover state. Build fresh fixtures per test. The suite MUST pass with
  `dart test --test-randomize-ordering-seed=random`.
- **Fast.** The unit suite runs in seconds. Never `sleep` or wait on real
  time; async doubles complete immediately.
- **Readable fixtures.** Small builders with sensible defaults, overridden per
  test to make the relevant detail obvious. No giant shared fixtures.
- **Test doubles from `testing.dart`.** Use the package's provided doubles for
  ports. Prefer fakes and fixed doubles over mocks; verify interactions only
  when the interaction is the requirement.
- **No skipped or commented-out tests.** Delete tests that no longer apply, or
  fix them. A skip needs a linked issue and a reason.
- **No test-only code in `lib/`.** Doubles that consumers may use belong in
  `testing.dart`; the rest belong in `test/`.

---

## 7. Coverage

- Measure coverage with `package:coverage` (a dev dependency):
  `dart run coverage:test_with_coverage`, which writes
  `coverage/lcov.info`. CI runs it on every change. Report the line coverage
  of each changed file in your `Testing` entry.
- **Every changed or added line in `domain/` and `application/` MUST be
  covered,** including error branches. Uncovered lines need a stated reason.
- **Coverage is necessary, not sufficient.** A line executed with no meaningful
  assertion is not tested. Review tests for quality (§8), not just for the
  number.
- Do not write tests whose only purpose is to raise the number.

---

## 8. Checking that tests actually test

Before finishing, convince yourself the tests would catch a real mistake:

- **For bug fixes,** the new test MUST fail without the fix (§2).
- **For new behaviour,** run mutation testing on the changed code (below).
  A surviving mutant means a test is missing or too weak: add or strengthen a
  test, do not just re-run.
- A test that cannot fail is a defect.

### Mutation testing

The project uses [`mutate4dart`](https://pub.dev/packages/mutate4dart), run
as a global tool inside Docker, never added to `pubspec.yaml`. It mutates a
copy of the project (small changes such as `<` to `<=` or `&&` to `||`) and
checks that a test fails for each.

```sh
cpus=$(( $(nproc) / 4 )); cpus=$(( cpus < 2 ? 2 : cpus ))
docker run --rm --cpus="$cpus" -v "$PWD":/app -w /app dart:stable sh -c \
  "dart pub get && dart pub global activate mutate4dart 0.12.2 && \
   dart run coverage:test_with_coverage && \
   /root/.pub-cache/bin/mutate4dart lib/src/shared_kernel lib/src/shared_ports \
     lib/src/<context>/domain --diff-base main --threshold 80 --jobs $cpus"
```

The tool takes several paths in one run. The paths are `lib/src/shared_kernel`,
`lib/src/shared_ports` and each context's `domain/` folder that exists.
`--diff-base` names a branch that exists locally: a pull request's base (for
example `origin/main`, or a release gathering branch), not a hard-coded `main`.

- **Scope:** changed lines in `shared_kernel/`, `shared_ports/` and `domain/`
  MUST be mutation tested (`--diff-base`), with a score of at least **80**.
  Changed lines in `application/` SHOULD be. Report the score and the number
  of survivors in your `Testing` entry.
- **Never use `--jobs 1`.** It mutates the working tree in place and a crash
  can leave mutated source behind. Use at least 2 jobs, which run in isolated
  copies.
- **Cap the workers.** The tool runs its jobs in parallel and can saturate a
  machine. A local run MUST be inside Docker with a CPU quota (`--cpus`) of at
  most a quarter of the host's processors (never below 2, because of the
  previous rule), with `--jobs` equal to that number and never above it. Run
  one mutation process at a time. CI runs the same command with `--jobs 2`.
- **Coverage first.** The tool reads `coverage/lcov.info` and skips lines no
  test runs, so generate it first (§7).
- **Surviving mutants** are fixed with a better test. Only a mutant that
  provably cannot change behaviour (an *equivalent* mutant) may be silenced
  with the tool's pragma comment, with a one-line reason next to it.
- **Pin the version** in the command above. The tool is pre-1.0 and its
  behaviour may change; upgrading is a deliberate change to this file.
- **Fallback:** if the tool cannot analyse a file (for example, a new Dart
  language feature), do the manual check instead: break the implementation
  (flip a comparison, drop a branch, off-by-one a boundary), confirm a test
  fails, restore it, and list the mutations tried.
- CI runs the `mutation` job (`.github/workflows/ci.yml`) on pull requests:
  the command above over the same paths, against the pull request's base
  branch. Whether it blocks merge is a repository setting. A new `domain/`
  folder is added to the job's path list in the same change that creates it.

---

## 9. Architecture and guardrail tests

`test/architecture/` holds tests that enforce the rules in
[architecture.md](architecture.md) and [observability.md](observability.md):
dependency direction, forbidden imports, banned calls, signal catalogue
consistency, the barrel scan for generic variant names and duplicate exported
names, the `lib/src/testing/` import rule, no import of `tool/` from `lib/`,
and the drift check on the embedded content libraries. Add the following check
too:

- Every `group(` and `test(` in `test/` (outside `test/architecture/`) is
  preceded by a `Requirement:` or `Rule:` doc comment, or by an explicit
  `Requirement: none - ...`. A `test(` inside a `for` loop satisfies this
  through the comment on the loop (`Requirement: per case`, §5).

Until the suite exists, the bootstrap rule in
[architecture.md](architecture.md) §9 applies.

A change to a rule or boundary MUST update or add the matching architecture
test.

---

## 10. Where tests live and how they run

```
test/
├── <context>/domain/        # unit
├── <context>/application/   # use cases with real domain + test doubles
├── <context>/adapters/      # adapter tests
├── contract/                # shared port contract suites, run against every implementation; not exported
├── scenarios/               # cross-context, public API only
└── architecture/            # guardrails (§9)
```

Contract suites are **not exported** from the package: exporting them would
make `package:test` a runtime dependency, which is forbidden. The documentation
tells consumers how to reuse them against their own adapters. Test doubles, by
contrast, live in `lib/src/testing/` and are exported by `lib/testing.dart`.

Run everything with the Docker commands in `AGENTS.md`. Run the narrowest set
while developing, and the whole suite with coverage before you finish. CI MUST
run the whole suite in random order with coverage, and a failing or flaky test
blocks the change. Fix flakiness; never retry it away.

---

## 11. Anti-patterns (prohibited)

- **Happy-path-only suites.**
- **Ice-cream cone:** mostly broad, slow tests with thin unit coverage.
- **Testing the mock:** tests that assert only on what a double was told to do.
- **Implementation-coupled tests** that break on refactors and not on bugs.
- **Tests with logic,** or assertions inside loops and branches.
- **Vague assertions** (`isNotNull`, `isTrue`) on behaviour that has an exact
  expected value.
- **Shared mutable fixtures** and tests that depend on order.
- **Hidden non-determinism:** unseeded randomness, real time, real I/O.
- **Skipped or commented-out tests** with no issue.
- **Uncited tests** where a spec or rule exists.
- **Coverage theatre:** executing code without asserting anything.
- **Fixing a bug without a regression test.**
- **Leaving stale tests** that encode old behaviour.
- **Skipping the evaluation:** finishing a change without working out its tests,
  or reporting "covered by existing tests" without saying which.
- **Content from outside SRD 5.2.1** in tests, comments or fixtures.

---

## Checklist before submitting

- [ ] I evaluated what tests this change needs (§2) and wrote them.
- [ ] Each behaviour is tested at the lowest pyramid level that can prove it.
- [ ] Happy path covered for every distinct valid outcome.
- [ ] Applicable unhappy paths from §4 covered, with specific assertions.
- [ ] Every test cites its requirement or rule (`Requirement:` and `Path:`), and
      every requirement in the spec I implemented has a test.
- [ ] Bug fix: regression test written first and seen to fail.
- [ ] Tests are deterministic, independent, fast, and use the package's doubles.
- [ ] Changed domain and application lines are covered; coverage is meaningful.
- [ ] Changed `domain/` lines are mutation tested with a score of at least 80,
      survivors handled (§8), and the score is in my `Testing` entry.
- [ ] Stale tests updated or removed; nothing skipped or commented out.
- [ ] The commit/PR and my final summary have a `Testing` entry.
- [ ] The full suite and architecture tests pass.

---

## Read receipt

RULE-TAG: `testing-366c927701fd`

This tag proves you read this document in this session. Quote it verbatim as
required by `AGENTS.md`. Do not copy it anywhere else. Whoever edits this
document MUST replace the tag with a fresh random value.
