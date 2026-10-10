# Release 0.1.0

| | |
|---|---|
| Status | draft |
| Context | `package` |
| Roadmap phase | 5 |
| Depends on | `architecture-guardrails.md`, `content-licensing-and-notice.md`, `content-source-port.md`, `rules-glossary-coverage.md`, `content-schema-and-decoder.md`, `errors-and-results.md`, `observability-ports.md`, `resolve-d20-test-use-case.md`, `dice-and-rolls.md`, `spell-effect-data.md`, `monster-limited-use.md`, `class-wizard-evoker.md`, `content-classes-data.md`, `higher-level-start-equipment-and-trinkets.md`, `readying-a-spell.md`, `returning-to-life.md`, `telepathy.md`, `grid-positions-and-movement.md` |

## 1. Purpose and scope

Defines what must be true of the repository before the first public release,
version 0.1.0, is tagged and published:

- the public API surface of the three entry points (`lib/srd5e.dart`,
  `lib/adapters.dart`, `lib/testing.dart`) and how it is reviewed and pinned;
- how consumers reach the bundled SRD content: only through the embedded
  libraries under `lib/src/content/data/` and `BundledContentSource` exported
  from `lib/adapters.dart` (shared-types-and-ownership.md FR-030, FR-031; the
  adapter is defined by content-source-port.md FR-059; ownership is
  shared-types-and-ownership.md FR-047), never through a file path;
- the programs in `example/`, including the observability bridge examples
  (documented, not shipped);
- `README.md`, `CHANGELOG.md`, `pubspec.yaml` and the published archive;
- the publish checklist, as release gates a maintainer can run and record.

This spec adds no runtime behaviour and no game rule. Its requirements are
checked by architecture tests that read repository files, by scenario tests that
run the examples, and by release checks run in CI or by hand (section 8).

**Out of scope:**

- Running `dart pub publish` or pushing a tag. Publishing is irreversible and
  is a maintainer's decision (FR-063). The spec defines the gates, not the act.
- Any game rule or SRD content. What the release contains is whatever the
  other specs have implemented by then; this spec only requires the README to
  say so honestly (FR-045).
- Shipped bridges to `package:logging`, OpenTelemetry or any other SDK. They are
  documented only (`doc/rules/architecture.md` §5, `doc/rules/observability.md`
  §4). A separate companion package would be a different project.
- A documentation site, an API reference beyond dartdoc, and publisher or
  automated-publishing setup on pub.dev.
- A `dart:io` entry point (`lib/io.dart`). None exists at 0.1.0.
- SRD material that looks like core fifth-edition content but is not in SRD
  5.2.1. Nothing in this spec depends on any; the README coverage table
  (FR-045) lists what is not included.

## 2. Source

`n/a (package design)`. Derived from:

- `doc/rules/architecture.md` §5 (adapters, bridges not shipped), §7 (entry
  points, documented exports, versioning, changelog), §9, §10.
- `doc/rules/observability.md` §4 to §7 and §10; `doc/rules/testing.md` §3, §6,
  §7, §8, §10.
- `doc/specs/shared-types-and-ownership.md` (it wins over this spec): FR-013,
  FR-014, FR-017, FR-021, FR-030 to FR-045, FR-047, FR-048, FR-050 to FR-052,
  FR-056. Header and graph: rank 99 in table 4.11, may depend on any spec; no
  spec lists this one. It is outside the context map (it adds no code). Phase 5
  follows the type-phase rule (FR-014).
- This spec's own citations of other specs ("<file>.md FR-nnn") are checked
  under shared-types-and-ownership.md FR-052: each names an existing spec and a
  live id. The release manifest (FR-078) marks which specs are `in 0.1.0`.
  The specs added after the first draft are in the inventory of section 6
  (`class-wizard-evoker`, `content-classes-data`,
  `higher-level-start-equipment-and-trinkets`, `monster-limited-use`,
  `readying-a-spell`, `returning-to-life`, `spell-effect-data`, `spell-outcome-tables`, `telepathy`;
  shared-types-and-ownership.md FR-059, FR-060) and FR-098 pins their rows.
- `dice-and-rolls.md` (`DiceRoller`, `SeededDiceRoller`, `FixedDiceRoller`; FR-010, FR-011, FR-019, section 6) and `resolve-d20-test-use-case.md` (`ResolveD20Test`; FR-019, FR-028): the types the entry points, the quickstart and the smoke test use.
- `AGENTS.md` ("Hard constraints", "Licensing and source material", "Reporting
  a change", "Directory structure"); `doc/roadmap.md` Phase 5;
  `doc/research/sources.md` ("Structure of the document", for the coverage table).
- Dart ecosystem conventions for `pubspec.yaml`, `.pubignore`, `CHANGELOG.md`
  and `example/`: tooling conventions, not SRD content; re-check pub.dev's
  documentation when the release is prepared (Q4, settled).


## 3. Vocabulary

No SRD terms apply. Package terms used in this spec:

| Term | Type | Notes |
|---|---|---|
| Entry point | file | One of `lib/srd5e.dart`, `lib/adapters.dart`, `lib/testing.dart`. |
| Public API snapshot | file | `test/architecture/public_api.snapshot`: a committed, line-oriented list of every symbol each entry point exports (section 6). |
| Port | interface | A driven-port interface exported by `lib/srd5e.dart` (for example `DiceRoller`, `ContentSource`, `Logger`, `Tracer`, `Meter`). |
| Double | class | A test implementation of a port, declared in `lib/src/testing/` and exported only by `lib/testing.dart` (shared-types-and-ownership.md FR-038). `FakeContentSource` is a double, not an adapter. |
| Adapter | class | A generic implementation of a port or an external-data decoder, declared under an `adapters/` folder (a context's, or `shared_ports/adapters/`) and exported only by `lib/adapters.dart` (shared-types-and-ownership.md FR-037). The no-ops are not adapters (FR-036). |
| Contract suite | test code | A shared port test in `test/contract/`. Not exported (shared-types-and-ownership.md FR-039). |
| Embedded content library | file | A generated Dart library of raw JSON strings under `lib/src/content/data/`, written by `tool/` from `data/` (shared-types-and-ownership.md FR-030). |
| Bridge | adapter | An implementation of `Logger`, `Tracer` or `Meter` that forwards to a third-party package. Documented in `example/`, never shipped. |
| Moved-id row | table row | A requirement row of the form `\| FR-nnn \| Withdrawn: moved to <spec>.md (FR-mmm) \|` kept in the compact table at the end of section 4 (shared-types-and-ownership.md FR-062). Its id is never reused and never cited as a live id. |
| Release gate | check | A condition that must hold before tagging; automated where possible (FR-065 to FR-075, FR-097). |
| Published archive | artifact | What `dart pub publish` uploads, as listed by `dart pub publish --dry-run`. |
| Release candidate commit (RC) | commit | The head commit of the branch `release/0.1.0`, which sets `version: 0.1.0`. After its PR merges, the merge commit on `main` is re-gated in RC mode; that merge commit is the one that is published and tagged (FR-076). |
| RC mode | test setting | Environment variable `SRD5E_RELEASE_CANDIDATE=1`, read once by the test support code (FR-076). |
| Release manifest | file | `doc/release/0.1.0.md` (planned; the change that creates it also adds its `documentation_index.md` row): one row per spec in `doc/specs/` (except `_template.md` and this spec) with `Released in` (`in 0.1.0` or `deferred`) and `SRD sections` (the section names and page ranges of `doc/research/sources.md` the spec covers, or `none` for a spec with no SRD source) (FR-078). |

### Check phases

Each requirement belongs to one phase. Checks of phase **always** run on every
commit and, for a file that does not exist yet, pass vacuously unless the id is
listed under RC-only. Checks of phase **RC-only** assert the final state of the
release and run only in RC mode. **Post-release** says what replaces an
RC-only check once `v0.1.0` is tagged (RC mode is then never set).

| Phase | Requirements |
|---|---|
| always | FR-001 to FR-013, FR-015 to FR-017, FR-019 to FR-028, FR-030 to FR-041, FR-044, FR-048, FR-050, FR-059 to FR-061, FR-063, FR-066, FR-072, FR-076, FR-078, FR-080 to FR-086, FR-088 to FR-092, FR-096, FR-098 |
| RC-only | FR-014, FR-018, FR-029, FR-042, FR-043, FR-045 to FR-047, FR-049, FR-051 to FR-058, FR-062, FR-065, FR-067 to FR-071, FR-073, FR-075, FR-079, FR-087, FR-093 to FR-095, FR-097 |
| post-release | FR-014 and FR-056 expire; FR-051 to FR-055 are replaced by FR-077, which starts running once `v0.1.0` is tagged; FR-057 becomes an always check (`publish_to` MUST stay absent); FR-074 is post-release only and runs once, on the follow-up PR |

FR-029 to FR-039 and FR-090 need `example/observability_bridges.md`: its
existence is RC-only (FR-029); once it exists, the checks on its content run
always (FR-090 is listed under always for that reason).

## 4. Requirements

Stable ids. Never renumber. Sources name a rule file and section, or
"package design" for ecosystem conventions. Test names cite this file and the
FR id.

### 4.1 Public API surface

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-001 | `lib/` MUST contain exactly three `.dart` files directly in it: `srd5e.dart`, `adapters.dart` and `testing.dart`. Any other file directly in `lib/` is a Violation. | architecture.md §7 | happy |
| FR-002 | No file in `example/`, `test/scenarios/`, `README.md` Dart snippets or the bridge documentation MAY import `package:srd5e/src/...` or a relative path into `lib/src/`. | architecture.md §7 ("Consumers MUST NOT import from it") | unhappy (invalid input) |
| FR-003 | Every `export` directive in the three entry points MUST use a `show` clause listing the exported names. A bare export, or a `hide` clause, is a Violation. | architecture.md §7 ("Export deliberately"); section 9, Q2 (decided) | unhappy (invalid input) |
| FR-004 | The public API snapshot MUST list every symbol exported by each entry point, one line per symbol, sorted by entry point file name and then by Name, in the line grammar of section 6 (FR-084), and MUST equal the symbols the entry points actually export. | architecture.md §7 ("Anything exported is a compatibility promise") | happy |
| FR-005 | When an entry point exports a symbol missing from the snapshot, or the snapshot lists a symbol the entry point no longer exports, or a symbol moved between entry points, the suite MUST fail and name every such symbol. | architecture.md §7 | unhappy (rule interaction) |
| FR-006 | Every exported member MUST have a dartdoc comment: `dart analyze --fatal-infos` with `public_member_api_docs` MUST report no issue under `lib/`. | architecture.md §7 | happy |
| FR-007 | Each entry point MUST have a library doc comment stating its purpose and listing the commands, results, events, ports and value objects it exports, grouped by context. A check MUST extract the backticked names from the doc comment and require that (a) each is a symbol of that entry point in the snapshot, and (b) every symbol of kind `port`, `usecase`, `double` or `adapter` of that entry point appears. Other kinds are listed at the author's discretion. | architecture.md §4 ("Handoffs"), §7 | happy |
| FR-008 | A symbol MUST be exported from exactly one entry point. | architecture.md §7 | unhappy (rule interaction) |
| FR-009 | `lib/srd5e.dart` MUST NOT export any adapter implementation (a symbol declared under an `adapters/` folder) or any test double (a symbol declared under `lib/src/testing/`). The `const` no-op implementations (`NoopLogger`, `NoopTracer`, `NoopMeter`, `NoopObservability`) are declared in the port library under `shared_ports/`, not an `adapters/` folder, and are exported from `lib/srd5e.dart` (shared-types-and-ownership.md FR-036). | architecture.md §7; testing.md §6 ("No test-only code in `lib/`") | unhappy (invalid input) |
| FR-010 | `lib/adapters.dart` MUST export only symbols defined under an `adapters/` folder (a context's, or `shared_ports/adapters/` such as `SeededDiceRoller`; shared-types-and-ownership.md FR-037), including `BundledContentSource` (owned by content-source-port.md; shared-types-and-ownership.md FR-031), and every one of them MUST either implement or extend a type named in a snapshot `port` line (matched by name in the declaration's `implements`/`extends` clause, as the lexer reads it, with no cross-file type resolution) or be listed in the `DECODERS` constant of the test support code (external-data decoders), or be listed in the `ADAPTER_SUPPORT_TYPES` constant of the same code (adapter-folder failure or helper types that implement no port; the first entry is `BundledContentInvalid`, an `Error` subclass that content-source-port.md FR-061 requires `lib/adapters.dart` to export). | architecture.md §5, §7; content-source-port.md FR-061 | unhappy (invalid input) |
| FR-011 | `lib/testing.dart` MUST export a double for every port (kind `port`, FR-084) that `lib/srd5e.dart` exports. The snapshot MUST record the mapping on the port's line (`double:`, one or more names: a port may have several doubles, for example `FixedDiceRoller` and `CallbackDiceRoller`), and a port without a double MUST fail the suite. The port set is derived from the source, not read from the snapshot (FR-084), so a port forgotten in the snapshot is still checked. Driven ports that are not obvious infrastructure, such as `ContentSetDecoder` (double `FakeContentSetDecoder`), are covered by the same rule. All doubles live in `lib/src/testing/` (shared-types-and-ownership.md FR-038). | architecture.md §7 ("Every port MUST ship with a test double"); observability.md §4 | unhappy (missing content) |
| FR-012 | The transitive import closure of the three entry points MUST use only these libraries: `dart:core`, `dart:async`, `dart:collection`, `dart:convert`, `dart:math`, `dart:typed_data`, `package:meta`, `package:collection` and files of this package. `dart:io`, `dart:ui`, `dart:html`, `dart:ffi`, `dart:mirrors` and any other package are Violations. | architecture.md §5, §9 bullet 1; AGENTS.md "Hard constraints" | unhappy (invalid input) |
| FR-013 | For every sealed class or sealed interface exported by an entry point, the snapshot MUST record its direct subtypes, so adding or removing a subtype changes the snapshot (FR-081 requires each subtype to be exported). `Srd5eException` is an `abstract base class`, not sealed (errors-and-results.md FR-001), so it carries no `subtypes:` pin; its subtype set is covered by errors-and-results.md FR-006 and the `error.type` rule of architecture-guardrails.md FR-085. | architecture.md §7 ("changing a sealed hierarchy consumers switch over" is breaking) | unhappy (rule interaction) |
| FR-014 | In RC mode no exported member MAY be annotated `@Deprecated`: nothing has shipped yet that needs a deprecation cycle. The check expires at release (section 3, Check phases); afterwards deprecation follows architecture.md §7. | architecture.md §7 ("Deprecate ... for at least one release") | unhappy (empty and minimal) |
| FR-015 | `test/scenarios/` MUST contain a public-API smoke test that imports only the three entry points and calls every use case exported by `lib/srd5e.dart` (kind `usecase`, FR-084) at least once, with test doubles only. Naming every use case is checked by FR-085. | testing.md §3 (scenario level) | happy |
| FR-016 | Every exported use case MUST be constructible and callable without supplying `Observability`, and MUST give the same result with `NoopObservability` as with a recording bundle. The smoke test (FR-015) MUST check both for each use case. | observability.md §4 ("No-op by default"), §9 | unhappy (determinism) |

### 4.2 Examples

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-017 | Every `.dart` file directly in `example/` MUST declare `main` and MUST import only the three entry points and SDK libraries. | architecture.md §7; section 9, Q4 (decided) | happy |
| FR-018 | `example/` MUST contain at least these programs: a quickstart (`example/example.dart`), a content-loading example, a character example, a combat example, a console observability bridge (`example/console_observability.dart`), and a telemetry-inspection example (`example/inspect_telemetry.dart`). An example MAY be omitted only when the release manifest (FR-078) marks every spec of its context `deferred` (content-loading: `content`; character: `character`; combat: `combat`). No example is required for `toolbox` (shared-types-and-ownership.md FR-045); the README coverage rows for the SRD sections those specs cover are then `not included` or `partial`. | roadmap.md Phase 5 ("Examples in `example/`") | happy |
| FR-019 | The region of `example/example.dart` between `// #region quickstart` and `// #endregion` (FR-044) MUST have at most 40 lines, and the quickstart MUST create the dice roller with a fixed seed, run one D20 Test through the published `ResolveD20Test` use case, and print the `D20TestOutcome` (`success` or `failure`; shared-types-and-ownership.md FR-004) and the values the result carries (roll, modifiers, DC), not a pre-formatted sentence from the engine. | architecture.md §6 ("carry data, not display text") | happy |
| FR-020 | The content-loading example MUST decode a JSON document containing at least two deliberate problems and print every problem the decoder reports (path and kind), then look up an entry that exists and one that does not, handling both variants of the lookup result. When the release bundles content, the example MUST also load it through `BundledContentSource` from `lib/adapters.dart` (the only consumer route to bundled content, which goes through the same decoder; shared-types-and-ownership.md FR-031; owner content-source-port.md) and look up one entry from it. | architecture.md §5 ("every problem found"), §6 | unhappy (invalid input) |
| FR-021 | Examples MUST handle each sealed result with an exhaustive `switch` with no `default` arm, and at least one example MUST catch `Srd5eException` by type for a failing port, forced with `FakeContentSource` (the scriptable `ContentSource` double from `testing.dart`) scripted to throw. | architecture.md §3, §6 | unhappy (failure) |
| FR-022 | The character and combat examples MUST each show the domain events or state returned by the use case (state in, new state and events out) and MUST NOT mutate any input. | architecture.md §3 ("Immutability and state transitions"), §4 | happy |
| FR-023 | Every example MUST be deterministic: fixed seeds, no `Random`, `DateTime.now`, `Stopwatch`, environment, network or filesystem access. The only way an example may observe time is through a clock injected as a `Duration Function()` argument (FR-041), which `main` fills with a fake deterministic function. Two runs MUST print identical output. | testing.md §6 ("Deterministic") | unhappy (determinism) |
| FR-024 | A scenario test MUST run each program in `example/` in a separate process, assert exit code 0 and assert stdout equals a committed golden file under `test/scenarios/golden/`. testing.md §6 currently says tests use no real network or real filesystem, and a spec cannot amend a rule file. This requirement therefore takes effect with the amendment of testing.md §6 and §10 (section 9, Q15, settled) that permits a real process and file reads for only this example runner and the repository-reading architecture checks; every other test stays hermetic. Until that amendment is in the rule file with a fresh tag, the subprocess runner is not in force. | testing.md §3, §6, §10 | happy |
| FR-025 | A program that fails (non-zero exit, or stdout different from its golden file) MUST fail the test naming the program and showing the difference. | testing.md §4 | unhappy (failure) |
| FR-026 | `example/` MUST be formatted and analysed by the same `dart format` and `dart analyze --fatal-infos` run as `lib/`, with no `// ignore` comments, and MUST write output with `stdout`, not `print`. | architecture.md §9; AGENTS.md "Commands" | unhappy (invalid input) |
| FR-027 | Game content appearing in an example (names, numbers, rules text) MUST come from SRD 5.2.1 and carry a citation comment of the form `SRD 5.2.1, "<section>", p. <n>`; this citation check is review-only (no tool can tell game content from other literals). Examples MUST NOT name any consuming project or the hosting organisation. | AGENTS.md "Hard constraints", "Licensing and source material" | unhappy (invalid input) |
| FR-028 | The telemetry-inspection example MUST run a published use case with a recording `Observability` from `testing.dart` and print the spans, measurements and log records it captured by name, attribute keys and level. The use case is `ResolveD20Test`, whose signals are owned by `resolve-d20-test-use-case.md` and which emits spans and metrics and no log (shared-types-and-ownership.md FR-040, FR-043), so the printed log section is empty for it and the example MUST say so rather than invent a record. | observability.md §9 | happy |

### 4.3 Observability bridge examples (documented, not shipped)

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-029 | `example/observability_bridges.md` MUST exist and document three bridges: `Logger` to `package:logging`, `Tracer` to OpenTelemetry, `Meter` to OpenTelemetry, targeting `package:logging` and, for both `Tracer` and `Meter`, `package:dartastic_opentelemetry` (it implements the tracing and the metrics API; the older `opentelemetry` package lists metrics as alpha; Q12, settled). A bridge whose snippet the maintainer cannot compile against the then-current version MUST be labelled a sketch and carry `Verified against: none (sketch)`. It MUST state that the bridges are not shipped and why (no dependency is forced on consumers). | observability.md §4; architecture.md §5 | happy |
| FR-030 | Each bridge MUST be a complete class implementing every member of its port as defined by the port's current signature, and MUST carry a line `Verified against: <package> <version>` naming the third-party version the snippet was compiled against in a scratch project. The line MUST match `^Verified against: [a-z_]+ \d+\.\d+\.\d+(\S*)$` or `^Verified against: none \(sketch\)$` (Q12). A check MUST also verify that each snippet class declares every member name of its port, read from the port's source (FR-086). | observability.md §4 ("a consumer's adapter is a thin translation"); section 9, Q3, Q12 | happy |
| FR-031 | The documentation MUST include a table mapping each `LogLevel` (`finest`, `fine`, `info`, `warning`, `severe`) to the `package:logging` level and to the OpenTelemetry severity. `SHOUT`/`fatal` MUST be marked as unused by srd5e. | observability.md §7 ("Levels") | happy |
| FR-032 | The `Logger` bridge MUST implement `isEnabled` by asking the backend, and MUST call the `attributes` closure only after `isEnabled(level)` returned true. | observability.md §7 ("Cheap when disabled") | unhappy (collaborator: disabled level) |
| FR-033 | The `Tracer` bridge MUST end each span exactly once. When the body throws, it MUST set error status, record the error and stack trace on the span, end it, and rethrow the same object. The asynchronous variant MUST end the span when the future completes, with or without error. | observability.md §6, §7 ("Errors: who records what") | unhappy (failure) |
| FR-034 | The `Tracer` bridge MUST map `SpanStatus.unset`, `ok` and `error` to the backend's statuses, and MUST implement `recordError` without ending the span or changing its status. | observability.md §4, §6 | happy |
| FR-035 | The `Meter` bridge MUST map `createCounter`, `createHistogram` and `createGauge` to the backend's instruments, passing unit and description through. Its `time` and `timeAsync` MUST read the consumer's own monotonic clock, record elapsed seconds as a `double`, and record also when the body throws, rethrowing the same object. | observability.md §4 ("Timing"), §5 ("Units follow UCUM"; "Durations are always seconds") | unhappy (failure) |
| FR-036 | The bridges MUST pass attribute values to the backend with their native types (`String`, `bool`, `int`, `double`) and MUST NOT stringify them or add attributes of their own. | observability.md §5 ("Attributes"), §8 | unhappy (invalid input) |
| FR-037 | The documentation MUST state that production implementations MUST NOT throw from port methods, and that the recording doubles in `testing.dart` throw `ArgumentError`/`StateError` on misuse by design and are for tests only. Source: observability-ports.md §9 (decisions) and its FR-010, FR-023, FR-040. It MUST also state that srd5e does not manage trace context: parent and child linkage is the bridge's job, typically through Dart zones. Source: observability.md §6. | observability-ports.md §9; observability.md §6 | unhappy (collaborator failure) |
| FR-038 | The documentation MUST show composition: build one `Observability(logger:, tracer:, meter:)` and pass it to each use case constructor; and show a partial bundle (only a `Meter`) leaving the other ports as no-ops. It MUST NOT show a global, static or service-locator registration. | observability.md §4 ("Constructor injection only"); architecture.md §10 | happy |
| FR-039 | The documentation MUST point to the signal catalogue (`doc/observability/signals.md`) by a relative link, as the list of what to dashboard and alert on, and to the recording doubles for testing a bridge. The catalogue ships in the archive (FR-061, FR-062), so the link works on pub.dev and no shipped file needs the repository URL (section 9, Q13). The documentation's "What to monitor" section is specified by FR-082. | observability.md §2 ("The signal catalogue"), §9 | happy |
| FR-040 | `lib/`, `pubspec.yaml` (including `dev_dependencies`) and every compiled file in `example/` MUST NOT reference `package:logging`, any OpenTelemetry package, Sentry or any other SDK. Only the markdown documentation (and other prose) names them. The SDK denylist is architecture-guardrails.md FR-032, an ordinary named constant in `test/architecture/support/constants.dart` matched only in `lib/`, `pubspec.yaml` and compiled `example/` code; this requirement extends it to `dev_dependencies` (guardrails FR-033 exempts them) and to `example/`. The trademark list is stored as content-licensing-and-notice.md FR-031 specifies (FR-080). | observability.md §10; architecture.md §5; architecture-guardrails.md FR-032, FR-033 | unhappy (invalid input) |
| FR-041 | `example/console_observability.dart` MUST implement all three ports using only SDK libraries, write to an injectable sink (a `StringSink` constructor argument, defaulting to `stdout`) that the contract suites and the golden run replace with a buffer so output is observable, and be wired into a use case, so the shape of a bridge is compiled and run even though the third-party ones are not. The console `Tracer` and `Meter` take their clock as an injected `Duration Function()` constructor argument and read no other clock; `main` passes a fake deterministic clock, and the golden output shows the fake durations, each span's status and any recorded error, and attribute values with their native types (FR-088). The class MUST pass the `Logger`, `Tracer` and `Meter` contract suites (the three files of observability-ports.md FR-063 under `test/contract/`; the generic checks only, as FR-088 lists them). | observability.md §4 | happy |

### 4.4 README

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-042 | `README.md` MUST NOT contain the phrases "scaffold only", "No functionality yet", "planned design", "does not exist yet" or "Names are provisional", nor any statement that describes a released feature as future. | architecture.md §7 | unhappy (state) |
| FR-043 | `README.md` MUST contain these H2 headings, exactly and in this order, after a one-paragraph summary directly under the H1: `## Installation` (`srd5e: ^0.1.0`, without a `path:` dependency), `## Quickstart`, `## Entry points` (a table of the three entry points and what each is for), `## Observability`, `## Coverage`, `## Versioning`, `## Development`, `## Licence and content`. No other H2 heading may appear before `## Development`. | architecture.md §7 | happy |
| FR-044 | The README quickstart snippet MUST be byte-identical to the region of `example/example.dart` between the markers `// #region quickstart` and `// #endregion`, and a test MUST fail when they differ. | package design (README code must not rot) | unhappy (state) |
| FR-045 | The coverage table MUST have one row per top-level section in `doc/research/sources.md` ("Structure of the document") with a status of `included`, `partial` or `not included` and, for `included` or `partial`, the context that provides it. The specs covering a row are those whose `SRD sections` cell in the release manifest (FR-078) names the section. A row MUST be `included` only if every covering spec is `in 0.1.0` and has Status `implemented`; it MUST be `not included` if every covering spec is `deferred` or none covers it; otherwise `partial`. Each `deferred` spec MUST be named in the table (in a Notes column). | AGENTS.md "Licensing and source material"; doc/research/sources.md | unhappy (missing content) |
| FR-046 | The README MUST state the versioning policy: before 1.0.0 a breaking change bumps the minor version, anything else the patch version, and metric, span and attribute names are part of the public contract. | architecture.md §7, observability.md §5 | happy |
| FR-047 | The README Observability section MUST describe the real API, name the example files (`example/console_observability.dart`, `example/observability_bridges.md`, `example/inspect_telemetry.dart`) and state that bridges to third-party packages are not shipped. | observability.md §4 | happy |
| FR-048 | Every link in every `.md` file in the published archive (`README.md`, `CHANGELOG.md`, `NOTICE.md`, `example/observability_bridges.md`, `doc/observability/signals.md`) MUST be either an absolute URL or a relative path that resolves to a file in the archive (FR-062). A relative link to `doc/` (other than `doc/observability/signals.md`), `AGENTS.md`, `CLAUDE.md`, `test/` or `.github/` is a Violation. An absolute URL MUST NOT point at the repository: no shipped file may name the hosting organisation (AGENTS.md "Hard constraints"; FR-072), and pub.dev links the repository from `pubspec.yaml` itself. The change that lands this requirement MUST also rewrite the links that violate it today (`NOTICE.md` to `AGENTS.md`, `doc/observability/signals.md` to `../rules/observability.md`, `README.md` to `doc/rules/observability.md`) as plain text; `NOTICE.md` is co-owned with content-licensing-and-notice.md. | package design (the published archive omits those paths); AGENTS.md "Hard constraints" | unhappy (invalid input) |
| FR-049 | The README licence section MUST state that the code is MIT-licensed, that the game content comes from SRD 5.2.1 under CC-BY-4.0, and MUST link `NOTICE.md`. While content is bundled the section also contains the attribution statement itself (content-licensing-and-notice.md FR-028), because pub.dev renders the README and not `NOTICE.md`. It MAY say the package is "compatible with fifth edition" or "5E compatible" and MUST NOT use any trademarked name or logo as a brand or imply endorsement. | AGENTS.md "Trademarks and attribution"; content-licensing-and-notice.md FR-028 | unhappy (invalid input) |
| FR-050 | The README MUST state the minimum Dart SDK, and the stated version MUST equal the lower bound of `environment.sdk` in `pubspec.yaml` (architecture check; the statement is mandatory in RC mode and, when present, always checked). The claim that the three entry points have no platform restriction is separate (FR-087). | package design | happy |

### 4.5 Changelog

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-051 | In RC mode, `CHANGELOG.md` MUST contain, from the top: an empty `## Unreleased` heading, then a heading beginning `## 0.1.0` with the release date. | architecture.md §7 | happy |
| FR-052 | In the release candidate commit, every entry under `Unreleased` on `main` MUST be moved into the 0.1.0 section; none MAY be dropped. The reviewer compares the 0.1.0 section with `Unreleased` on `main` in the PR diff (review); the architecture check asserts only that `Unreleased` is empty in RC mode. | architecture.md §7 ("Every user-visible change gets an entry") | unhappy (state) |
| FR-053 | The 0.1.0 section MUST group entries under `Added` only, one bullet per entry point, per context (including `toolbox` when `in 0.1.0`), per package module (`shared_kernel`, `shared_ports`), and one each for the examples, the bundled content (when any) and the signal catalogue, and MUST NOT carry the **BREAKING** marker, because there is no earlier release to break. | architecture.md §7 | unhappy (empty and minimal) |
| FR-054 | The 0.1.0 section MUST list the three entry points, name the signals in `doc/observability/signals.md` as a stable contract from this version, and say what game content is bundled and where the attribution is (`NOTICE.md`). | observability.md §5; AGENTS.md "Licensing" | happy |
| FR-055 | Every bullet in the 0.1.0 section MUST describe something present in the public API snapshot, a signal in the catalogue, or a file in the archive. The check: every backticked token that looks like a Dart type name (matches `^[A-Z][A-Za-z0-9]*$`) MUST be a symbol in the snapshot. Backticked tokens that are file paths (contain `/` or end in `.md`/`.dart`), URIs (`package:`/`dart:`), a folder name from the context map (`shared_kernel`, `shared_ports`, `content`, `d20_test`, `character`, `combat`, `toolbox`), or a signal name in the catalogue are exempt from the type-name check; each exempt class has its own fixture. A bullet naming a type absent from the snapshot is a Violation. | architecture.md §7 | unhappy (invalid input) |

### 4.6 `pubspec.yaml` and the published archive

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-056 | In RC mode `pubspec.yaml` MUST set `version: 0.1.0`. Before the release candidate the version stays `0.0.1` (review). After release FR-077 replaces this check. | architecture.md §7; section 9, Q9 (decided) | happy |
| FR-057 | In RC mode `pubspec.yaml` MUST NOT contain `publish_to`. Removing it is part of the release candidate commit (FR-063). | package design | happy |
| FR-058 | `description` MUST be 60 to 180 characters, MUST state what the package is without any trademarked product name used as a brand, and MUST mention neither Flutter nor any consumer. The current description ends "No Flutter or UI dependencies" and therefore MUST be rewritten (FR-079). The trademark list is the one in `constants.dart` (FR-080). | AGENTS.md "Trademarks and attribution"; package design | unhappy (boundary) |
| FR-059 | `pubspec.yaml` MUST have a `repository` that is an `https` URL (the one place the hosting organisation may appear), MUST NOT set `issue_tracker` (a second line naming the organisation, which the exemption of AGENTS.md and guardrails FR-026 does not cover; pub.dev derives the tracker from `repository` for supported hosts), and MUST have `topics` of at most five lowercase entries, none a trademarked name. | AGENTS.md "Hard constraints" (the `repository` exception); package design; section 9, Q13 | unhappy (boundary) |
| FR-060 | The dependency allowlist (`collection`, `meta`) is owned by architecture-guardrails.md FR-083 and is not restated here. This release adds only: each dependency has a caret constraint, there is no `dependency_overrides`, and no `path:` or `git:` dependency in any section (`dev_dependencies` included). | AGENTS.md "Hard constraints"; architecture-guardrails.md FR-083 | unhappy (invalid input) |
| FR-061 | `.pubignore` MUST exclude `AGENTS.md`, `CLAUDE.md`, `.github/`, `test/` (section 9, Q6, decided; this also keeps `test/fixtures/srd/` and the contract suites out), `data/` and `tool/`, each directory as an anchored pattern (`/.github/`, `/test/`, `/data/`, `/tool/`), because a bare `data/` is unanchored and also matches `lib/src/content/data/` (the embedded libraries under `lib/src/content/data/` carry the content; section 9, Q14; content-licensing-and-notice.md FR-019 agrees: only `lib/src/content/data/` must ship), and every part of `doc/` except `doc/observability/signals.md` (a literal `doc/research/` line, because notes that hold SRD text are not distributed, shared-types-and-ownership.md FR-033, then `doc/*`, then `!doc/observability/` then `doc/observability/*` then `!doc/observability/signals.md`, so the catalogue ships; Q13), and, because a `.pubignore` replaces `.gitignore` for the directory, MUST also repeat every `.gitignore` entry (`.dart_tool/`, `.packages`, `build/`, `coverage/`, `pubspec.lock`, `.mutate4dart/`). | package design | unhappy (invalid input) |
| FR-062 | The published archive MUST contain `LICENSE`, `NOTICE.md`, `README.md`, `CHANGELOG.md`, `pubspec.yaml`, `analysis_options.yaml`, `doc/observability/signals.md`, `lib/` (which includes any bundled game content under `lib/src/content/data/`) and `example/`. A missing `NOTICE.md` is a Violation. Its exact file set is FR-067. | AGENTS.md "The notice"; content-licensing-and-notice.md | unhappy (missing content) |
| FR-063 | An agent MUST NOT run `dart pub publish` without `--dry-run`, push a tag, or hold a publish credential. An agent MAY edit `publish_to` and `version` only in the release candidate commit and only when the maintainer asks explicitly. The maintainer performs the publish and the tag after the gates in 4.7 pass. The review row covers the process; CI workflows MUST NOT contain `pub publish` without `--dry-run` (FR-083). | package design (a published version cannot be deleted) | unhappy (state) |

### 4.7 Publish checklist (release gates)

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-065 | The full CI check in `AGENTS.md` ("Commands") MUST pass on the release candidate commit: `dart pub get`, `dart format --set-exit-if-changed .`, `dart analyze --fatal-infos`, and the test suite with coverage in random order. | testing.md §10 | happy |
| FR-066 | CI MUST compile a program importing all three entry points with `dart compile js` and `dart compile wasm`, and MUST run `dart analyze` and the test suite on the lowest SDK allowed by `environment.sdk` as well as on stable. CI MUST also run the web test run `dart test -p chrome test/content/adapters` in the Chrome-capable setup (content-schema-and-decoder.md FR-099, which asks this spec to list it in its CI checklist); a failure of that run fails the release gate. | AGENTS.md "Hard constraints" (pure Dart); package design | unhappy (boundary) |
| FR-067 | `dart pub publish --dry-run` MUST exit 0 (any non-zero exit, including exit 65 for a warning, is a failure) and its reported archive file set MUST equal this allowlist: `LICENSE`, `NOTICE.md`, `README.md`, `CHANGELOG.md`, `pubspec.yaml`, `analysis_options.yaml`, `doc/observability/signals.md`, `lib/**`, `example/**`. It MUST contain none of `AGENTS.md`, `CLAUDE.md`, `.github/`, `test/`, `data/`, `tool/`, or any other `doc/` path. Verified behaviour of the current repository: `dart pub publish --dry-run` does run with `publish_to: none` and already exits 65 on a warning (it reports a missing 0.0.1 changelog entry and lists `test/`), so the existing CI step is meaningful, but it is a failing gate until the changelog and `.pubignore` are fixed; the step runs in RC mode only. | package design | happy |
| FR-068 | Mutation testing, as defined in `doc/rules/testing.md` §8, MUST be run over `lib/src/shared_kernel`, `lib/src/shared_ports` and each `lib/src/<context>/domain` (every context of architecture.md §2, `toolbox` included; no `--diff-base`), with the exact mutate4dart target paths listed in the release record (FR-075), threshold 80. The pass condition is score >= 80 and every surviving mutant either fixed or recorded with a reason it is equivalent; a survivor that is not equivalent blocks the release even when the score is above 80. | testing.md §8 | unhappy (failure) |
| FR-069 | Line coverage of `lib/src/shared_kernel/`, `lib/src/shared_ports/` and `lib/src/**/domain/` and `lib/src/**/application/` MUST be 100% or each uncovered line MUST be listed with a reason in the release record. | testing.md §7 | unhappy (boundary) |
| FR-070 | `doc/observability/signals.md` MUST contain none of the placeholder phrases `No signals yet`, `TODO`, `TBD`. The catalogue is not otherwise re-checked here: that signal names in code equal the catalogue is architecture-guardrails.md FR-042 and FR-043. Empty or placeholder Purpose and Suggested monitoring cells are already forbidden by architecture-guardrails.md FR-045 and FR-046, and an empty or `n/a` Unit is allowed for spans and log events (observability.md §2: Unit "where applicable"). Attribute values and names follow FR-093. | observability.md §2, §10; architecture-guardrails.md FR-042, FR-043, FR-045, FR-046 | unhappy (state) |
| FR-071 | No spec marked `in 0.1.0` in the release manifest (FR-078) MAY have Status `draft` on the release candidate commit; `deferred` specs may stay `draft` and MUST be named in the README coverage table (FR-045). Every FR id in the `in 0.1.0` specs MUST have a test (the coverage rule is architecture-guardrails.md FR-055), except moved-id rows (architecture-guardrails.md FR-087), or be listed in the release record with the reason it has none. | testing.md §5 ("every requirement SHOULD be covered"); architecture-guardrails.md FR-055, FR-087 | unhappy (state) |
| FR-072 | The architecture suite MUST pass with the denylist scan covering `lib/`, `test/`, `example/`, `doc/`, `README.md`, `CHANGELOG.md`, `NOTICE.md` and `pubspec.yaml` (with the exemptions of architecture-guardrails.md FR-026: the `repository` line, `AGENTS.md` and `CLAUDE.md`). Because FR-048 forbids repository URLs in shipped files, a compliant README, CHANGELOG, bridge document and shipped catalogue pass this scan. | architecture.md §9; architecture-guardrails.md FR-026 | unhappy (invalid input) |
| FR-073 | `pana` (or the equivalent pub.dev scoring tool) MUST be run on the archive. Every category that does not score full points MUST be listed with its cause and a decision (fix or accept) in the release record. | package design | unhappy (failure) |
| FR-074 | After publishing, the maintainer MUST tag the published commit `v0.1.0` (matching `pubspec.yaml`), and `AGENTS.md`, `README.md` and the roadmap MUST describe the package as released. | package design; section 9, Q8 | happy |
| FR-075 | The release record MUST be the PR description of the release candidate commit, with the `Testing` and `Observability` entries of `AGENTS.md` ("Reporting a change"), and MUST contain: SDK versions, the mutate4dart target paths, mutation score and survivors per target, coverage exceptions, pana result, the archive file list, and the README coverage table. The release PR is `release/0.1.0` into `main`; the merge commit is re-gated in RC mode (FR-076). | AGENTS.md "Reporting a change" | happy |

### 4.8 Added requirements

Added after review and reconciliation; ids continue the sequence.

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-076 | RC mode MUST be the environment variable `SRD5E_RELEASE_CANDIDATE=1`, read in one place in the test support code. CI MUST set it in a job that runs on pull requests whose head branch is `release/0.1.0`, and on the merge commit on `main` through a manually dispatched workflow; ordinary runs MUST NOT set it. The commit published and tagged is that re-gated merge commit. RC-only requirements (section 3, Check phases) MUST be skipped when the variable is unset, and MUST run when it is set. | package design | unhappy (state) |
| FR-077 | After release, `pubspec.yaml` `version` MUST equal the version in the first non-`Unreleased` heading of `CHANGELOG.md`. | architecture.md §7 | happy |
| FR-078 | `doc/release/0.1.0.md` MUST contain a table with one row per file in `doc/specs/` (excluding `_template.md` and this spec) giving `Released in` (`in 0.1.0` or `deferred`) and `SRD sections` (names and pages as in `doc/research/sources.md`, or `none` for a spec with no SRD source, such as shared-types-and-ownership.md, errors-and-results.md and architecture-guardrails.md). A spec's context (used by FR-018) is read from the Context row of its header (architecture-guardrails.md FR-094), not from the manifest. A spec without a row, or with a `Released in` value other than those two, or an empty `SRD sections` cell, MUST fail the suite. | package design; section 9, Q1 | unhappy (missing content) |
| FR-079 | `pubspec.yaml` `description` MUST be rewritten to remove the Flutter clause, for example "A pure-Dart implementation of fifth-edition rules from the SRD 5.2.1." (length and trademark rules of FR-058 apply). | AGENTS.md "Trademarks"; package design | unhappy (state) |
| FR-080 | The trademark denylist and the consumer and hosting-organisation denylist used by this spec's checks MUST live in `test/architecture/support/constants.dart` and MUST NOT appear in plain text anywhere else in the repository; their storage and matching are content-licensing-and-notice.md FR-031 and architecture-guardrails.md FR-026 and FR-068, not restated here. The SDK denylist (architecture-guardrails.md FR-032) is an ordinary named constant in the same file, is matched only as FR-040 says, and its names MAY appear in prose. | AGENTS.md "Hard constraints"; architecture-guardrails.md FR-032 | unhappy (invalid input) |
| FR-081 | Every direct subtype of a sealed type exported by an entry point MUST itself be exported from an entry point, or be listed with a reason in the `EXPORT_EXCEPTIONS` constant of the support code. | architecture.md §4, §6, §7; FR-021 of this spec | unhappy (rule interaction) |
| FR-082 | The "What to monitor" section of the bridge documentation MUST name the two generic cases (any non-zero use case error rate; a latency regression against the consumer's own baseline) and link the catalogue for thresholds, without repeating them. | observability.md §2 | happy |
| FR-083 | No workflow file under `.github/workflows/` MAY contain `pub publish` unless the same command contains `--dry-run`. | package design | unhappy (invalid input) |
| FR-084 | Snapshot kinds are derived by the lexer (no `package:analyzer`). A `port` is a driven port exactly as architecture-guardrails.md FR-082 defines it, including its `portHandles` exemption (observability-ports.md FR-065); this spec defines no second port list. A handle is recorded with its Dart kind and needs no double (FR-011). A `usecase` is a class under `lib/src/*/application/` (not `ports/`) with a public `call` member; a `double` is a symbol exported by `testing.dart` whose declaration implements or extends a port by name; an `adapter` is a symbol declared under an `adapters/` folder; any other symbol has its Dart kind (`class`, `sealed`, `enum`, `mixin`, `typedef`, `extension`, `extension type`, `function`, `const`). `function` and `const` (a top-level function, variable or getter, such as `supportedSchemaVersions`) are not seen by the export closure of architecture-guardrails.md FR-093, which covers types only; the release check finds them with its own lexer pass over each entry point's `show` names and the declaring files. The kind recorded in the snapshot MUST equal the derived kind. The line grammar is in section 6. | architecture.md §7; architecture-guardrails.md FR-082 | unhappy (invalid input) |
| FR-085 | A check MUST fail when `test/scenarios/` public-API smoke test source does not name a use case that has a `usecase` line in the snapshot. | testing.md §3 | unhappy (missing content) |
| FR-086 | A check MUST read each port's member names from its source and fail when a bridge snippet class in `example/observability_bridges.md` omits one. | observability.md §4 | unhappy (rule interaction) |
| FR-087 | The README MAY state that the three entry points have no platform restriction only once the FR-066 job is green on the release candidate; the release record (FR-075) holds that evidence. | package design | happy |
| FR-088 | `example/console_observability.dart` MUST be run against the `Logger`, `Tracer` and `Meter` contract suites of observability-ports.md (the files are its FR-063: `test/contract/logger_contract.dart`, `tracer_contract.dart` and `meter_contract.dart`) from `test/contract/`, limited to the checks that apply to any implementation: observability-ports.md FR-006, FR-011, FR-013, FR-025, FR-029 to FR-032, FR-054, FR-055 and the generic parts of FR-012 and FR-014 (body once, result returned, same object rethrown, span ended, elapsed time recorded). Assertions that read a recording double's state read the console bridge's injected sink instead (FR-041). FR-019 and FR-033 of that spec are `NoopTracer` and `NoopMeter` rules (record nothing, read no clock) and are NOT run against the console bridge. These cover this spec's FR-032, FR-033 (end once, rethrow, async) and FR-035 for the console bridge. FR-034 and FR-036, and the status and recorded-error part of FR-033, are not contract-level; for the console bridge they are asserted on the golden output (FR-041); the markdown snippets stay review. | testing.md §3; observability-ports.md | unhappy (collaborator failure) |
| FR-089 | `lib/testing.dart` MUST export no contract suite, no check closure standing in for one, and nothing that imports `package:test`; contract suites exist only under `test/contract/`. | shared-types-and-ownership.md FR-039; architecture.md §7 | unhappy (rule interaction) |
| FR-090 | The "Testing a bridge" section of `example/observability_bridges.md` MUST state that the port contract suites are not exported (they would make `package:test` a runtime dependency), and MUST say how a consumer reuses them: copy the suite for the port from `test/contract/` in the source repository linked from the package page, and run it against their own adapter. It MUST NOT contain a repository URL (FR-048). | shared-types-and-ownership.md FR-039; testing.md §10 | happy |
| FR-091 | No symbol in the snapshot MAY carry a banned generic name (the list is owned by architecture-guardrails.md FR-077 and is not repeated here), and no Name MAY appear on two snapshot lines (any entry point or kind). The uniqueness check applies to the Name field of each line, the symbol being declared; names inside `subtypes:` and `double:` clauses are references and are excluded. The check reuses the barrel scan of architecture-guardrails.md rather than redefining it. | shared-types-and-ownership.md FR-017, FR-021; architecture-guardrails.md FR-077; architecture.md §9 | unhappy (name collision) |
| FR-092 | Every `usecase` line in the snapshot MUST have a matching `sealed <UseCase>Result` line (use case `ResolveD20Test`, result `ResolveD20TestResult`), and the use case's `call` MUST return that type or a `Future` of it. | shared-types-and-ownership.md FR-017; architecture.md §4 | unhappy (missing content) |
| FR-093 | In `doc/observability/signals.md`: the values of the shared attributes (`srd5e.outcome`, `srd5e.d20_test.kind`, `srd5e.d20_test.roll_mode`, `srd5e.d20_test.critical_hit`) and of `error.type` are checked in code and catalogue by architecture-guardrails.md FR-085 and are not restated here. Unique to this release: no returned failure result carries `error.type` in the catalogue (errors-and-results.md FR-043); class features use the single counter `srd5e.character.feature_used` with attributes `srd5e.class` and `srd5e.feature` and no per-feature metric name exists; and no log row exists for the d20 test. | shared-types-and-ownership.md FR-041 to FR-043; architecture-guardrails.md FR-085; observability.md §5 | unhappy (state) |
| FR-094 | The content format MUST have one `schemaVersion` integer. At release, `content-schema-and-decoder.md`'s revision table MUST show every revision landed as that single version, no content spec MAY claim another version number, `data/` files and the embedded libraries MUST carry it, and the decoder MUST reject any other value. | shared-types-and-ownership.md FR-034 | unhappy (version mismatch) |
| FR-095 | Every embedded content library under `lib/src/content/data/` MUST decode with zero problems through `BundledContentSource` and the real `ContentSetDecoder` (no second loader), and the drift check that regenerates the libraries from `data/` MUST pass on the release candidate commit. | shared-types-and-ownership.md FR-030 to FR-032 | unhappy (drift) |
| FR-096 | Every folder directly under `lib/src/` other than `shared_kernel`, `shared_ports` and `testing` MUST be a context in the table of `doc/rules/architecture.md` §2 (`content`, `d20_test`, `character`, `combat`, `toolbox`); the snapshot kinds, the barrel and the `show` rules (FR-003, FR-084) apply to `toolbox` like any other context. Each `toolbox` use case in the snapshot is called by the FR-015 smoke test. The smoke test MUST record telemetry per use case and assert that each call emits only that use case's own catalogue signals, because a use case never calls another use case (shared-types-and-ownership.md FR-044). | shared-types-and-ownership.md FR-044, FR-045; architecture.md §2 | unhappy (rule interaction) |
| FR-097 | In RC mode, `doc/specs/rules-glossary-coverage.md` MUST have no unit in state `gap` whose interim or planned owner spec has Status `accepted` or `implemented` (an exported rule); a release MUST NOT be tagged while one exists. The release record (FR-075) states the `gap` count published in that spec's section 4.6. | rules-glossary-coverage.md FR-009, Q-17; roadmap.md Phase 5 | unhappy (state) |
| FR-098 | The release manifest (FR-078) MUST have a row for each spec added after the first draft, with the context its header gives (the inventory of section 6): `class-wizard-evoker.md` (`character`), `content-classes-data.md` (`content`), `grid-positions-and-movement.md` (`combat`; SRD pp. 13 to 15), `higher-level-start-equipment-and-trinkets.md` (`character`), `monster-limited-use.md` (`combat`), `readying-a-spell.md` (`combat`), `returning-to-life.md` (`combat`), `spell-effect-data.md` (`content`), `spell-outcome-tables.md` (`combat`) and `telepathy.md` (`combat`), and the ten further rows of the inventory (`wish-spell.md`, `magic-item-effects.md`, `spell-scroll-use.md`, `item-use-effects.md`, `monster-engulf-and-swallow.md`, `monster-stat-block-actions.md`, `monster-traits.md`, `monster-spellcasting.md`, `persistent-spell-zones.md`, `summoned-and-companion-creatures.md`; contexts as the inventory gives). When one is `in 0.1.0`, its exported types, ports and use cases are in the snapshot under the rules of FR-003 to FR-013 and FR-084, its signals are in the catalogue (FR-070, FR-093), and the FR-015 smoke test calls its use cases (a spec whose section 6 states no use case adds none); when `deferred`, it is named in the README coverage table (FR-045). | shared-types-and-ownership.md FR-025, FR-059, FR-060 | unhappy (missing content) |

### 4.9 Withdrawn ids

| Id | Status |
|---|---|
| FR-064 | Withdrawn: moved to content-licensing-and-notice.md (FR-002, FR-011, FR-012); the covered-path list is architecture-guardrails.md FR-079 (shared-types-and-ownership.md FR-050) |

## 5. Model

No domain layer: this spec describes a release, not rules.

- **Public API snapshot:** a text file kept in step with the code by test, so
  a public API change is a visible, reviewed diff (format in section 6).
- **Release gates (4.7):** conditions on a commit, not code; each has an owner
  (CI job, architecture test, or maintainer) and leaves evidence in the
  release record.
- **Checks as pure functions:** architecture-level rows of section 8 follow
  architecture-guardrails.md (source set in, violations out, with a violating
  and a clean fixture); scenario rows run through the public API or a subprocess.
- **Invariants:** the three entry points are the whole public surface
  (FR-001, FR-002); a symbol has one home (FR-008) and a compatibility promise
  (FR-004, FR-005); no shipped file claims something the archive lacks
  (FR-048, FR-055, FR-062).
- **Failures:** all checks report violations as test failures; no result type
  or exception is added to the package.


## 6. Interface

No new Dart API. This spec fixes shapes of repository artefacts.

### Entry points

| Entry point | Exports (by `show`) | Must not export |
|---|---|---|
| `package:srd5e/srd5e.dart` | use cases, commands, results (`<UseCase>Result`), events, value objects and ids of every context (`content`, `d20_test`, `character`, `combat`, `toolbox`) (including whatever the specs of the inventory below export) and of `shared_kernel`, ports, `const` no-ops (`NoopLogger`, `NoopTracer`, `NoopMeter`, `NoopObservability`), `Observability`, the `Srd5eException` base class (`abstract base class`, not sealed; errors-and-results.md FR-001) and its subtypes | adapters, doubles |
| `package:srd5e/adapters.dart` | generic adapters (`SeededDiceRoller`, `BundledContentSource`, JSON decoders), platform-neutral | ports, doubles, no-ops, anything needing `dart:io` |
| `package:srd5e/testing.dart` | a double for every port (`FixedDiceRoller`, `FakeContentSource`, `FakeContentSetDecoder`, recording observability), recording records | adapters, contract suites, anything importing `package:test` (FR-089) |

### Inventory of specs added after the first draft

Each contributes to `lib/srd5e.dart` only what its own section 6 exports; the
snapshot (FR-004) is the record, this table is the checklist behind FR-098.

| Spec | Context | Rank | Contribution to the entry points |
|---|---|---|---|
| `spell-effect-data.md` | `content` | 7 | Spell effect data types and queries; no use case or port. |
| `content-classes-data.md` | `content` | 7 | Data only: twelve class files and their embedded libraries, loaded through `BundledContentSource` (FR-095); no type, port or use case. |
| `class-wizard-evoker.md` | `character` | 18 | Evoker use cases (`AddEvocationSavantSpells`, `ResolvePotentCantrip`, and so on) with their `<UseCase>Result` types. |
| `higher-level-start-equipment-and-trinkets.md` | `character` | 15 | `StartAtHigherLevel`, `RollHigherLevelStartingMoney`, `RollTrinket` and their results. |
| `monster-limited-use.md` | `combat` | 26 | Limited-use state, outcomes and events, and the use case `ApplyMonsterTurnStart` with its result. |
| `readying-a-spell.md` | `combat` | 26 | Pure functions and value objects; the use cases that call them are an amendment to `combat-action-resolution.md`, not this spec's. |
| `grid-positions-and-movement.md` | `combat` | 26 | Grid value objects and pure `GridRules` functions; no use case or port; callers as for `readying-a-spell.md`. |
| `telepathy.md` | `combat` | 23 | Pure functions and `TelepathicContactState`; callers as for `readying-a-spell.md`. |
| `returning-to-life.md` | `combat` | 27 | A pure function and `ReviveCreatureResult`; callers as for `readying-a-spell.md`. |
| `spell-outcome-tables.md` | `combat` | 28 | The pure tables and the use case `ResolveSpellOutcomeTable` with its sealed command and result types. |
| `wish-spell.md` | `character` | 16 | What its own section 6 exports; use cases with their results. |
| `magic-item-effects.md` | `character` | 14 | What its own section 6 exports; use cases with their results. |
| `spell-scroll-use.md` | `character` | 15 | What its own section 6 exports; use cases with their results. |
| `item-use-effects.md` | `combat` | 25 | What its own section 6 exports; use cases with their results. |
| `monster-engulf-and-swallow.md` | `combat` | 24 | What its own section 6 exports; use cases with their results. |
| `monster-stat-block-actions.md` | `combat` | 27 | What its own section 6 exports; use cases with their results. |
| `monster-traits.md` | `combat` | 27 | What its own section 6 exports; use cases with their results. |
| `monster-spellcasting.md` | `combat` | 27 | What its own section 6 exports; use cases with their results. |
| `persistent-spell-zones.md` | `combat` | 28 | What its own section 6 exports; use cases with their results. |
| `summoned-and-companion-creatures.md` | `combat` | 31 | What its own section 6 exports; use cases with their results. |

### Public API snapshot (`test/architecture/public_api.snapshot`)

One line per symbol, sorted by entry point file name and then by Name (code-unit order). Grammar (FR-084):

```
line    = entry SP kind SP Name [SP "subtypes:" SP Name {"," SP Name}]
          [SP "double:" SP Name {"," SP Name}]
entry   = "srd5e.dart" | "adapters.dart" | "testing.dart"
kind    = "port" | "usecase" | "double" | "adapter"
        | "class" | "sealed" | "enum" | "mixin" | "typedef" | "extension" | "extension type"
        | "function" | "const"
```

`subtypes:` appears only on `sealed` lines and lists the direct subtypes
(FR-013); `double:` appears only on `port` lines of `srd5e.dart` (FR-011), with at least one name. There
are no free-standing mapping lines. A symbol with a role kind (`port`,
`usecase`, `double`, `adapter`) uses it in place of its Dart kind.

```
adapters.dart adapter BundledContentSource
srd5e.dart port DiceRoller double: FixedDiceRoller, CallbackDiceRoller
srd5e.dart usecase ResolveD20Test
srd5e.dart class ResolveD20TestForcedFailure
srd5e.dart sealed ResolveD20TestResult subtypes: ResolveD20TestForcedFailure, ResolveD20TestRolledAttack, ResolveD20TestRolledCheck
srd5e.dart class ResolveD20TestRolledAttack
srd5e.dart class ResolveD20TestRolledCheck
srd5e.dart class Srd5eException
testing.dart double FixedDiceRoller
```

(Names above illustrate the format and are not a list of what exists.)
Regenerating the file is a deliberate act (a documented command in the test's
failure message), and the diff is reviewed with the CHANGELOG entry.

### `example/` layout

```
example/
├── example.dart                   # quickstart; region markers for the README
├── content_loading.dart
├── character.dart
├── combat.dart
├── console_observability.dart     # plain-Dart bridge, compiled and run
├── inspect_telemetry.dart         # recording doubles
└── observability_bridges.md       # package:logging and OpenTelemetry, documented only
test/scenarios/golden/<program>.txt   # expected stdout
```

`// #region quickstart` and `// #endregion` in `example/example.dart` delimit
the text the README embeds (FR-044).

### Published archive layout

In: `lib/` (including `lib/src/content/data/`, `lib/src/testing/`), `example/`,
`doc/observability/signals.md` and the root files of FR-062. Out: `data/`,
`tool/`, `test/`, `.github/`, `AGENTS.md`, `CLAUDE.md` and the rest of `doc/`
(FR-061).

### Bridge documentation outline

1. Why bridges are not shipped. 2. Composition of `Observability`. 3. `Logger`
to `package:logging`. 4. `Tracer` to OpenTelemetry. 5. `Meter` to
OpenTelemetry. 6. Testing a bridge with the recording doubles and the
non-exported contract suites (FR-090). 7. What to monitor (FR-082).

## 7. Observability

Silent by design. This spec adds no use case, port call or adapter, so it adds
no signal and `doc/observability/signals.md` gets no row
(`doc/rules/observability.md` §3). The seven questions:

1. **What can go wrong?** Undocumented or placeholder signals (catalogue
   drift); an example or bridge document showing a pattern that breaks the
   observability rules (global logger, throwing bridge, eager attributes); a
   bridge that stringifies attributes or ignores the closure; the archive omits the catalogue (FR-061, FR-062 and FR-067 guard this).
2. **How would an operator know?** At release, by the gates: FR-070 and FR-093
   with architecture-guardrails.md FR-042, FR-043, FR-085; FR-032 to FR-039 and
   FR-088 (bridge rules); FR-016 (same result with and without telemetry). After release, by the owning specs' error counters and duration histograms.
3. **What would someone need to diagnose it?** The release record (FR-075), the
   catalogue, the bridge documentation and the telemetry-inspection example.
4. **What should be counted or timed?** Nothing new. Mutation score, coverage
   and the `pana` result are one-off evidence, not runtime signals.
5. **Is existing instrumentation still correct?** FR-070 is the check: the
   release makes every signal name a compatibility promise
   (`doc/rules/architecture.md` §7), so a stale entry is fixed before tagging.
6. **What should a consumer monitor?** FR-082: any non-zero use case error rate
   and a latency regression, with the catalogue linked for the rest.
7. **Is anything now noisy?** No. The console bridge prints to `stdout` by
   design, as a demonstration.

| Signal | Type | Attributes | Purpose | Suggested monitoring |
|---|---|---|---|---|
| none | | | | |


## 8. Test plan

Levels: unit, application, contract, scenario, architecture, plus **release
check** (a CI step or maintainer action, evidenced in the release record) and
**review** (judged by a human). Architecture rows have a violating and a clean
fixture each unless the note says otherwise.

| Id | Level | Notes |
|---|---|---|
| FR-001 | architecture | Lists `lib/*.dart`; fixtures with an extra file and a missing file. |
| FR-002 | architecture | Scans `example/`, `test/scenarios/`, README and bridge-doc code blocks for `src/` imports. |
| FR-003 to FR-005 | architecture | `show` parsing against the snapshot. Fixtures: bare export, `hide`, valid `show`; added, removed and moved symbol, every one named. |
| FR-006 | release check | `dart analyze --fatal-infos` in CI; also asserted by reading the analyzer lint config. |
| FR-007 | architecture | Backticked names from each entry point's library doc; fixtures: phantom name, missing port, clean doc. |
| FR-008, FR-009 | architecture | One symbol exported from two entry points; an adapter and a double exported from `srd5e.dart`; a `const` no-op under `shared_ports/` passes. |
| FR-010 | architecture | Fixtures: a non-adapter symbol in `adapters.dart`; a `shared_ports/adapters/` symbol and `BundledContentSource` pass; a no-op or a double fails; `BundledContentInvalid` (in `ADAPTER_SUPPORT_TYPES`) passes, absent from the constant fails. |
| FR-011 | architecture | Port list derived from source (FR-084); fixtures: a port lacking a double, a port missing from the snapshot, a handle (`Span`) with no double (passes). |
| FR-012 | architecture | Import-closure walk shared with architecture-guardrails.md; fixtures importing `dart:io` and a dev dependency. |
| FR-013, FR-014 | architecture | Sealed hierarchy gaining a subtype changes the snapshot; a subtype hidden by `show` (FR-081). `@Deprecated` scan; FR-014 RC-only. |
| FR-015, FR-016 | scenario | One test per use case, public API only (imports asserted by FR-002); table-driven `NoopObservability` versus recording bundle, equal results. |
| FR-017 | architecture | Scans `example/*.dart` for `main` and imports. |
| FR-018 | architecture | File existence; an omitted example must match a context whose specs (context from each header, FR-078) are all `deferred`, and the README rows (FR-045). |
| FR-019 | architecture | Line count of the region and the seed literal; output built from result data is by review. |
| FR-020 | scenario | Golden shows both decoder problems, both lookup variants and, when bundled, the `BundledContentSource` lookup. |
| FR-021 | architecture | Token scan: no `default:` or `_ =>` in `switch` over sealed types in `example/` (conservative); `on Srd5eException` present; `FakeContentSource` scripted to throw is used. |
| FR-022 | scenario | Golden shows returned state and events; immutability is covered by the owning specs' unit tests. |
| FR-023 | scenario | Runs each program twice, identical stdout; architecture scan bans the tokens except a clock via the injected `Duration Function()`. |
| FR-024, FR-025 | scenario | Subprocess runner and golden reads, taking effect with the testing.md §6/§10 amendment (Q15); self-test: a failing fixture program is reported by name with a diff. |
| FR-026 | release check | Full CI check; an architecture check scans `example/` for `// ignore` and `print(`. |
| FR-027 | architecture | Consumer-name denylist scan; the citation-comment check is review-only. |
| FR-028 | scenario | Golden lists the recorded spans and measurements of `ResolveD20Test` and states no log record was emitted (shared-types-and-ownership.md FR-043). |
| FR-029, FR-037 to FR-039, FR-082 | architecture | File exists with the required headings and "not shipped" statement; keyword scans for the three FR-037 statements, `Observability(` composition without `static`/`GetIt` registration, the "What to monitor" section; the catalogue link resolves in the archive set. |
| FR-030 | review | Compile-in-scratch-project is a maintainer action (Q3); the architecture check asserts a `Verified against:` line per bridge by the FR-030 regex and (FR-086) every port member name in each snippet class. |
| FR-031 | architecture | The table has a row for every `LogLevel` value read from the source. |
| FR-032, FR-035 | contract + review | Logger contract suite for `isEnabled` and the lazy closure; Meter suite (observability-ports.md FR-025, FR-031, FR-032, FR-055) for instruments, units, timing on a throw with the injected clock. Snippets reviewed. |
| FR-033 | contract + scenario + review | Tracer suite for end-once, same object rethrown, async; error status and recorded error on the console-bridge golden (FR-041). Snippets reviewed. |
| FR-034, FR-036 | scenario + review | Status mapping, `recordError` not ending the span and native attribute types are asserted on the console-bridge golden (FR-041), not as contract rows. Snippets reviewed. |
| FR-040 | architecture | Import and `pubspec.yaml` scan (including `dev_dependencies`) with the denylist from `constants.dart` (FR-080), extended to `example/`. |
| FR-041 | scenario + contract | Program run with its fake clock, golden shows fake durations; a throwing double records the error once on the span; the class passes the three contract suites (FR-088). |
| FR-042 to FR-047 | architecture | README: phrase scan; the eight exact H2 headings in order; region equals README block; coverage table rows compared with `doc/research/sources.md`, expected status derived from manifest and spec `Status` lines; versioning keywords; the three example file names appear and exist. |
| FR-048 | architecture | Link extraction over every archive `.md`; fixtures: a `doc/` link, the catalogue link (allowed), an absolute non-repository link, a link to an archive file. |
| FR-049, FR-050 | architecture | Keyword scan and `NOTICE.md` link check (trademark wording by review); stated SDK equals `pubspec.yaml`, fixture with a mismatch. |
| FR-051, FR-053 to FR-055 | architecture | Heading order; group headings, bullet subjects and the marker; keyword scan (entry points, "signal", `NOTICE.md`); type-name tokens against the snapshot with a fixture per exempt class (path, `package:` URI, context folder, signal name) and a type absent from the snapshot. RC-only for FR-051. |
| FR-052 | review | Nothing-dropped needs a diff of the release PR against `Unreleased` on `main`; the architecture check asserts `Unreleased` is empty in RC mode. |
| FR-056, FR-057 | architecture | Reads `pubspec.yaml`; RC mode only (FR-076). |
| FR-058, FR-079 | architecture | Both RC-only (the old description still ends with the Flutter clause until the rewrite lands, so the Flutter scan is not an always check). Boundary fixtures at 59, 60, 180, 181 characters; trademark and Flutter scan using `constants.dart`; fixture with the old description. |
| FR-059 | architecture | Boundary fixtures: 5 and 6 topics, uppercase topic, `http` URL, a present `issue_tracker`. |
| FR-060 | architecture | Non-caret constraint, `git:` (also under `dev_dependencies`), `path:`, override; a lone `collection` passes. Allowlist fixtures are guardrails FR-083's. |
| FR-061 | architecture | `.pubignore` entries against the required set (including `/test/`, `/data/`, `/tool/` as anchored lines, the literal `doc/research/` line, the catalogue negation) and `.gitignore`; a bare `data/` line is a Violation (content-licensing-and-notice.md FR-019). |
| FR-062, FR-067 | release check | The `dart pub publish --dry-run` step in `.github/workflows/ci.yml` (RC mode) fails on any non-zero exit and its file list is compared with the allowlist; the architecture check covers file existence. |
| FR-063 | review + architecture | Process rule is review of the release PR; the workflow scan is FR-083. CI never holds a publish credential. |
| FR-065, FR-066 | release check | CI; matrix, compile steps and the Chrome web run of `test/content/adapters`, which the architecture check asserts the workflow contains. |
| FR-068, FR-069 | release check | Docker command from testing.md §8 without `--diff-base`, over the FR-068 paths; `coverage/lcov.info` filtered to the FR-069 folders; results in the release record. |
| FR-070 | architecture | Reuses guardrails FR-045, FR-046; adds the placeholder-phrase scan. Fixture: a span row with an empty Unit passes. |
| FR-071 | architecture | Manifest and `Status` of each `in 0.1.0` spec; coverage by a scan of `Requirement:` comments; moved-id rows skipped (fixture); exceptions in the release record. |
| FR-072 | architecture | The guardrails scan; this requirement pins its scope at release. |
| FR-073 | release check | Manual `pana` run in Docker; evidence in the release record. |
| FR-074, FR-075 | review | Post-publish, checked on the follow-up PR; the PR template carries the headings, completeness is judged by the reviewer. |
| FR-076, FR-077 | architecture | Flag unset skips RC-only checks, set runs them; a workflow scan asserts the RC job sets it on `release/0.1.0` and ordinary jobs do not; version equal to and different from the top changelog heading (FR-077 is post-release: it does not run before `v0.1.0` is tagged). |
| FR-078 | architecture | Lists `doc/specs/`, compares with the manifest; fixtures: missing row, bad value, a package-design spec with `none` (clean), an empty `SRD sections` cell. |
| FR-080, FR-083 | architecture | Plain-text trademark and consumer names outside `constants.dart` (SDK names not scanned here); fixtures `pub publish` and `pub publish --dry-run`. |
| FR-081, FR-084 to FR-086 | architecture | Hidden subtype of an exported sealed class, and a listed exception; fixtures per kind, a hand-edited kind that disagrees with the lexer, an interface in `ports/` missing from the snapshot, `Span` (a `portHandles` name, no double demanded) beside `Tracer` (a port), a `function`, `const` and `extension type` line; a use case the smoke test does not name; a snippet class missing one port member. |
| FR-087 | release check | CI matrix result (FR-066) in the release record; the README claim is by review against it. |
| FR-088 | contract | `test/contract/` runs the generic Logger, Tracer and Meter checks against the console bridge writing to a `StringBuffer`; a fixture lists the no-op-only rows (observability-ports.md FR-019, FR-033) as excluded. |
| FR-089, FR-090 | architecture | `testing.dart` exporting a contract-suite symbol, a file under `lib/src/testing/` importing `package:test`; keyword scan of "Testing a bridge" for "not exported" and `test/contract/`, and for repository URLs (FR-048). |
| FR-091, FR-092 | architecture | A snapshot with a banned name, one with a Name on two lines; clean: a sealed type with `subtypes:` and a port with `double:` names, each with its own line; a `usecase` line without its `...Result` sealed line; a `call` returning another type. |
| FR-093 | architecture | Parses the catalogue; fixtures: a per-feature metric name, an `error.type` on a returned-failure row, a d20 test log row. Value sets are guardrails FR-085's. |
| FR-094 | architecture + unit | Revision table and `schemaVersion` of `data/` and the embedded libraries (the decoder rejection test is content-schema-and-decoder.md's). RC-only. |
| FR-095 | architecture + scenario | Every embedded library loads through `BundledContentSource` with zero problems; generator-drift test. RC-only. |
| FR-096 | architecture + scenario | `lib/src/` folders against the context map, fixture with an unknown folder; smoke test with a recording `Observability` asserts per-use-case signals; fixture: two use cases that share a pure domain service each emit only their own catalogue signals, with no nested or double-counted span or counter. |
| FR-097 | architecture | RC-only. Unit table of rules-glossary-coverage.md and owner `Status`; fixtures: `gap` with `implemented` owner (Violation), `gap` with `draft` owner (clean), no `gap` (clean). The record's `gap` count equals section 4.6 (review). |
| FR-098 | architecture | Manifest lacking any inventory row (Violation, one per missing spec); all present (clean); a row whose context differs from the spec header; an `in 0.1.0` spec whose use case has no snapshot line. |

- **Doubles and contract suites required:** the recording doubles and the fixed
  `DiceRoller`, `ContentSource` and `ContentSetDecoder` doubles from
  `testing.dart`. No new port; `console_observability.dart` implements Logger,
  Tracer and Meter and passes their existing contract suites (FR-088).
- **Mutation-testing scope:** the check functions are test support code with
  their own fixtures; `lib/` gains no code from this spec. Release-wide
  mutation testing is FR-068.
- **Deliberately not mechanically covered** (the form architecture-guardrails.md
  reads for its coverage rule):

  Deliberately not covered: FR-052 - nothing-dropped needs a PR diff review
  Deliberately not covered: FR-074 - a post-publish action, checked on the follow-up PR
  Deliberately not covered: FR-075 - completeness of the release record is judged by the reviewer


## 9. Open questions and decisions

No open questions.

Settled (decided; the requirement named is the decision):

- Q1 release content is whatever is `in 0.1.0` in the manifest, not full SRD coverage: FR-078, FR-071, FR-045.
- Q2 `show` lists on every export: FR-003. Q3 third-party snippets are not compiled in this repository, compiled once in a scratch project: FR-030.
- Q4 package example is `example/example.dart`; `pana` confirms it: FR-018, FR-073.
- Q5 contract suites are not exported (shared-types-and-ownership.md FR-039; content-source-port.md Q2): FR-089, FR-090.
- Q6 `test/` is excluded from the archive (tests read paths the archive omits): FR-061, FR-067.
- Q7 a maintainer publishes; agents prepare the release candidate only: FR-063. Q8 tag `vX.Y.Z` on the published commit: FR-074.
- Q9 `version: 0.1.0` only in the release candidate commit: FR-056, FR-076. Q10 minimum SDK stays `>=3.9.0 <4.0.0`, lower bound tested: FR-066.
- Q11 `pana` need not score full points; every loss is explained: FR-073.
- Q12 bridges target `package:logging` and `package:dartastic_opentelemetry` (tracing and metrics in one package; `opentelemetry` has no stable metrics API); versions go in each `Verified against:` line at release, sketch label only if the scratch compile fails: FR-029, FR-030.
- Q15 the example runner and repository-reading checks may use a real process and file reads, by an amendment of testing.md §6 and §10 limited to those two cases (a spec cannot grant it; FR-024 in force once it lands): FR-024, FR-025.
- Q13 the catalogue ships and is linked relatively, no repository URL, no `issue_tracker`: FR-039, FR-048, FR-059.
- Q14 `data/` and `tool/` do not ship; the embedded libraries are the only route (shared-types-and-ownership.md FR-030, FR-031; content-licensing-and-notice.md FR-019): FR-061.
- The console bridge may print: the rule against `print` scopes `lib/`; examples use `stdout` (FR-026, FR-041).
- A compiled console bridge exists so the port shape is compiled and run in CI while the third-party snippets stay thin markdown (FR-041).

## 10. Changelog impact

No `CHANGELOG.md` entry of its own: the work this spec describes is the
release. The release candidate commit moves everything under `Unreleased` into:

```
## 0.1.0 - <release date>

### Added
- Entry points `srd5e.dart`, `adapters.dart`, `testing.dart`: one bullet each.
- Package modules `shared_kernel` and `shared_ports`: one bullet each.
- One bullet per implemented context (`d20_test`, `content`, `character`,
  `combat`, `toolbox`); a `deferred` context (FR-078) has none.
- Bundled SRD 5.2.1 content (only when any is bundled), attribution in `NOTICE.md`.
- Examples in `example/`, including bridge documentation (not shipped as code).
- Telemetry signals in `doc/observability/signals.md`, stable from this version.
```

There is no "First public release." line (FR-055). Not **BREAKING**: there is no
earlier release. From 0.1.0 onward, a change to a snapshot entry, a sealed
hierarchy, a rule result for the same input, or a signal or attribute name is
breaking and bumps the minor version (`doc/rules/architecture.md` §7).
