# Architecture guardrails

| | |
|---|---|
| Status | implemented |
| Context | `package` |
| Roadmap phase | 0 |
| Depends on | `ability-scores.md`, `active-effects.md`, `attack-and-help-actions.md`, `attacks.md`, `casting-and-concentration.md`, `character-aggregate.md`, `character-creation.md`, `class-barbarian.md`, `class-bard.md`, `class-cleric.md`, `class-druid.md`, `class-fighter.md`, `class-monk.md`, `class-paladin.md`, `class-ranger.md`, `class-rogue.md`, `class-sorcerer.md`, `class-warlock.md`, `class-wizard.md`, `class-wizard-evoker.md`, `combat-action-resolution.md`, `combat-foundations.md`, `combatant-roster-changes.md`, `conditions.md`, `content-classes.md`, `content-classes-data.md`, `content-equipment.md`, `content-licensing-and-notice.md`, `content-magic-items.md`, `content-monsters.md`, `content-schema-and-decoder.md`, `content-source-port.md`, `content-species-backgrounds-feats.md`, `content-spells.md`, `content-thin-slice.md`, `d20-tests.md`, `deployed-and-restraining-gear.md`, `derived-stats.md`, `dice-and-rolls.md`, `dispel-and-counterspell.md`, `encounter-aggregate.md`, `environment-hazards-and-objects.md`, `equipment-rules.md`, `errors-and-results.md`, `exploration.md`, `feats-behaviour.md`, `grappling.md`, `grid-positions-and-movement.md`, `heroic-inspiration.md`, `hiding-searching-and-senses.md`, `higher-level-start-equipment-and-trinkets.md`, `hit-points-and-damage.md`, `initiative-and-actions.md`, `item-use-effects.md`, `level-advancement-and-multiclassing.md`, `magic-item-effects.md`, `magic-item-rules.md`, `magical-effects.md`, `modifiers-and-advantage.md`, `monster-combatant-setup.md`, `monster-engulf-and-swallow.md`, `monster-limited-use.md`, `monster-spellcasting.md`, `monster-stat-block-actions.md`, `monster-traits.md`, `mounted-and-underwater-combat.md`, `movement-lifting-and-flight.md`, `observability-ports.md`, `persistent-spell-zones.md`, `readying-a-spell.md`, `resolve-d20-test-use-case.md`, `rests-and-hit-dice.md`, `returning-to-life.md`, `revival-and-restoration-spells.md`, `rule-options.md`, `shape-changing-spells.md`, `social-interaction.md`, `species-trait-behaviour.md`, `spell-effect-data.md`, `spell-effects.md`, `spell-granted-modifiers.md`, `spell-outcome-tables.md`, `spell-scroll-use.md`, `spellcasting.md`, `summoned-and-companion-creatures.md`, `telepathy.md`, `tool-proficiency-and-crafting.md`, `toolbox-combat-encounter-difficulty.md`, `toolbox-curses-and-contagions.md`, `toolbox-environmental-effects.md`, `toolbox-fear-and-mental-stress.md`, `toolbox-hazard-effects.md`, `toolbox-poison.md`, `toolbox-traps.md`, `toolbox-travel-pace.md`, `weapon-properties-and-mastery.md`, `wish-spell.md` |

## 1. Purpose and scope

The mechanical checks that make the rules in `doc/rules/` binding: every check
listed in `architecture.md` §9, `observability.md` §10 and `testing.md` §9, as
tests under `test/architecture/`. Each check is a pure function over an
in-memory snapshot of the repository's files, so it can be tested against a
violating fixture as well as run against the real repository. The suite
includes the read-receipt tag check and the consistency check between
`doc/observability/signals.md` and the signal constants in code. It also
carries the mechanical decisions of `shared-types-and-ownership.md` (FR-013,
FR-052): the `lib/src/testing/` and `tool/` import rules, the barrel scan, the
embedded-content drift check, the `NOTICE.md` covered-paths and `.pubignore`
check (FR-079; decisions FR-050), no use case calling another (FR-097;
decisions FR-044), the `toolbox` leaf context (FR-098; decisions FR-045), and
the spec checks: template shape, context map, the token-only "Depends on"
header (FR-100), the rank rule from table 4.11 and the cycle check (FR-101,
FR-089), phase, the content data specs' dependency rule (FR-099; decisions
FR-047, FR-067), citations, and the documentation index (FR-102), section 4.7.

This spec is rank 90 and lists every spec it verifies as a header token
(decisions FR-061); other specs reference it in prose only.

The bootstrap rule (`architecture.md` §9) requires the first change that adds
code under `lib/src/` to bring this suite with it. Checks for code that does
not exist yet (the `dart:io` entry-point exemption) ship now, with fixtures,
and pass vacuously on the real repository. Where a check needs a file that does
not exist yet (the generator in `tool/`, FR-078), it takes it as a parameter
and the real-repository wiring is added with that file.

**Out of scope:**

- No game rules: no SRD content and no `lib/` API.
- Process checks that cannot be automated: that the observability and testing
  evaluations were done, and that a rule file's tag was replaced when the file
  was edited (`observability.md` §10; `AGENTS.md`). Reviewers enforce them;
  detecting the latter needs git history, so it is a CI step outside the unit tests (section 9).
- Duplicate ownership of a type or event across specs: reviewed by doc
  (`shared-types-and-ownership.md` §8). Only the code-level duplicate (FR-077)
  is mechanical.
- Topic mechanics owned elsewhere (decisions FR-048): the embedded-content
  generator (`content-schema-and-decoder.md` FR-121, FR-123), the `NOTICE.md`
  wording (`content-licensing-and-notice.md`), `.pubignore` entries other than
  `doc/research/` (`release-0-1-0.md`). `content-thin-slice.md` withdrew its
  drift check and `content-equipment.md` FR-096 defers to FR-078.
- Other specs' own check ids (`CLN-` in `content-licensing-and-notice.md`, E1 to
  E6 of `errors-and-results.md`, `rules-glossary-coverage.md`): not registered
  here (section 9).
- Lint rules already in `analysis_options.yaml`. `avoid_print` overlaps FR-028,
  which stays as defence in depth (an analyzer `exclude`, or `// ignore:
  avoid_print`, which FR-009 refuses to honour).
- Mutation testing of `lib/` code (`testing.md` §8): the guardrail code is test
  code; its self-tests (FR-005) play that role.

## 2. Source

n/a (package design). Derived from the rule files and
`doc/specs/shared-types-and-ownership.md`. "decisions" below means that file; its ids are cited as "decisions FR-n". A check that goes beyond the rule
text (for example FR-013, FR-015, FR-016, FR-032, FR-076, FR-082, FR-083, FR-084) says "extends <rule> (package design)" in its Source cell
(section 9).

- `doc/rules/architecture.md` §1 (dependency rule, `testing/`, no-ops,
  `shared_ports/adapters/`), §2 (context map, kernel), §3 (purity), §4 (a use
  case MUST NOT call another), §5 (adapters, bundled content), §7 (doubles,
  contract suites), §9 (enforcement, bootstrap).
- `doc/rules/observability.md` §2 (catalogue), §3, §4 (ports, no-ops), §5
  (naming, constants, attribute values), §10 (enforcement).
- `doc/rules/testing.md` §5 (citation format), §6 (no skipped tests), §9
  (guardrail tests), §10 (contract suites not exported).
- `doc/specs/shared-types-and-ownership.md` FR-013 to FR-017, FR-021, FR-030 to
  FR-033, FR-036 to FR-038, FR-041, FR-044, FR-045, FR-047, FR-050, FR-052,
  FR-056, FR-061 and table 4.11; `doc/specs/_template.md`; `AGENTS.md` ("Read
  the rules first", "Hard constraints", "Directory structure").

## 3. Vocabulary

| Term | Type | Notes |
|---|---|---|
| Barrel | file | `lib/src/<context>/<context>.dart`, the only file of a context another context may import (`architecture.md` §2). |
| Context folder | folder | Any folder directly under `lib/src/` other than `shared_kernel/`, `shared_ports/` and `testing/`. Those three are not contexts: FR-018 and FR-019 do not apply inside them (FR-075 and FR-024 govern them). |
| Testing folder | folder | `lib/src/testing/`, the only place for test doubles; exported only by `lib/testing.dart` (decisions FR-038). |
| Embedded data library | file | A `.dart` file under `lib/src/content/data/` holding raw JSON strings generated from `data/` by `tool/` (decisions FR-030). |
| Core entry points | files | `lib/srd5e.dart`, `lib/adapters.dart`, `lib/testing.dart`. |
| Platform entry point | file | An entry point other than the core ones that may expose a `dart:io` adapter (for example `lib/io.dart`). The set is a constant in the test support code, empty today. |
| Signal | concept | A metric name, span name or log event (`observability.md` §2). Metric and span names are dotted; a log event is its constant message, because the `Logger` port has no event-name field (section 9). |
| Signals class | declaration | An `abstract final class` whose name ends in `Signals` (`D20TestSignals`, `CombatSignals`, `ConditionSignals`), or is exactly `AttributeKeys` (`observability-ports.md` FR-052). |
| Signal constant | declaration | A `static const String` member of a `*Signals` class whose identifier ends in `Metric`, `Span` or `LogEvent`; the suffix gives the kind. |
| Attribute constant | declaration | A `static const String` member of a `*Signals` class whose identifier ends in `Attribute`, or any `static const String` member of `AttributeKeys` (attribute keys with no suffix: `outcome`, `errorType`). |
| Attribute value constant | declaration | A `static const String` member of a signals class whose identifier ends in `Value`; its doc comment names the attribute key in backticks (FR-085). |
| Constants file | file | A file under `lib/src/<context>/application/` whose name ends in `signals.dart`, or a file under `lib/src/shared_ports/` declaring `AttributeKeys` (`shared_ports/signals.dart`). The only places under `lib/` where signal and attribute names may be spelled as literals. A `*Signals` class declared elsewhere is a Violation of FR-037. The classes are public API where the specs export them from `lib/srd5e.dart` (the barrel scan, FR-077, accepts them). |
| SourceSet | value | Immutable map of repository-relative path to file content, plus the `unreadable` map of path to reason (FR-002, FR-010). |
| Use case class | declaration | A class in a file under `lib/src/<context>/application/` (not `ports/`) with a public `call` member, found by the lexer, other than a `*Signals` class (`architecture.md` §4). A helper that is not a use case must not have a public `call` member there. |
| Spec | file | A `doc/specs/*.md` file whose name does not start with `_`; its header table has Status, Context, Roadmap phase and Depends on (FR-094). |
| Context map | table | Allowed upstream edges between contexts, parsed from the table in `architecture.md` §2, the single source of truth (FR-022). |
| Moved-id row | table row | A requirement-table row kept so an id is never reused: its second cell begins with the word `Withdrawn` and a colon, then `moved to <spec>.md (<id>)` (shared-types-and-ownership.md FR-062). Prose calls the id a moved id; a citation of one may carry the suffix `(withdrawn)` in parentheses (FR-096). |
| Rank | integer | A spec's number in table 4.11 of the decisions spec. Only the order matters; the values have gaps (FR-101). |
| Documentation index | file | `doc/documentation_index.md`: a three-column table (`File`, `Summary`, `Read when`) with one row per file under `doc/`, the first cell one backticked path relative to `doc/` (FR-102). |
| Violation | value | One finding: check id (an FR id), path, 1-based line, detail. A check is one FR id that yields Violations; one function may implement several (FR-005). |

## 4. Requirements

Stable ids, never renumbered; new ids sit where they belong, not in numeric
order. "Source" gives the rule file and section, or "package design". Check ids
are those in sections 4.1 (FR-007, FR-010), 4.2, 4.3, 4.4 and 4.7 (FR-005).
Every check has a clean fixture (happy) and a violating fixture (unhappy), so
most rows read `unhappy (<kind>)`. Withdrawn ids are listed in 4.8; none today.

### 4.1 Harness

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-001 | The suite MUST locate the package root as the nearest ancestor of the working directory whose `pubspec.yaml` declares `name: srd5e`, and MUST fail with a message naming the directory searched when none is found. | package design | unhappy (state error) |
| FR-002 | A SourceSet MUST contain every non-ignored text file of the repository: every regular file under the package root, keyed by repository-relative path with `/` separators, excluding the directories `.git/`, `.dart_tool/`, `build/`, `coverage/`, `.mutate4dart/`, `.idea/` and `.vscode/` **at the repository root only** (a nested folder of the same name, such as `test/fixtures/coverage/`, is kept and checked), the files `pubspec.lock`, `.packages` and `.DS_Store`, and files whose name ends in `.swp`, `.swo` or `~` (the ignored and per-machine files; named constants, FR-009, so the result does not depend on one developer's editor), and excluding binary files (a NUL byte in the first 8 KiB). A binary file's repository-relative path (only the path, no content) is kept in the SourceSet's `binaryPaths` list, so a check can see that it exists (`content-licensing-and-notice.md` R-2). Each check filters by path prefix. `tool/`, `bin/`, `.github/`, `LICENSE`, `.pubignore` and `analysis_options.yaml` are therefore in scope for the checks that name them. | architecture.md §9; observability.md §10; AGENTS.md "Hard constraints" | happy |
| FR-003 | Each check MUST be a pure function from a SourceSet (plus its constants) to a list of Violation, doing no I/O. | architecture.md §9 | happy |
| FR-004 | A failing check MUST report every violation it finds, one per line as `<path>:<line> <FR id> <detail>`, not only the first. | package design | unhappy (multiple violations) |
| FR-005 | A check is one FR id that sits in section 4.2, 4.3, 4.4 or 4.7 (FR-013 to FR-056 as they appear there, plus FR-061, FR-062, FR-067, FR-068, FR-074 to FR-086, FR-088 to FR-090, FR-092 and FR-095 to FR-104), plus FR-007 and FR-010; one function MAY implement several ids. Moved-id rows (section 3; none today), FR-087 (a support rule in section 4.6) and FR-091 (a restatement of FR-101; its violations are reported as FR-101) are not checks. Every check id MUST have a self-test pair: a minimal violating fixture asserting the exact Violation(s) (id, path, line), and a clean fixture asserting none. A meta-test MUST read the check ids from this spec's tables, look each up in the registry (section 5), and fail unless the id has a fixture yielding a Violation whose id equals it. A check id with no violating fixture is a defect. | testing.md §8 ("a test that cannot fail is a defect") | unhappy (failure) |
| FR-006 | Directive extraction MUST treat `import`, `export` and `part` as edges, and MUST resolve `package:srd5e/...` and relative URIs to repository paths. | architecture.md §9 | happy |
| FR-007 | A directive URI that is relative or `package:srd5e/` and resolves to no file in the SourceSet (which holds every file per FR-002, so `../tool/x.dart` resolves) MUST be a Violation (a typo must not hide an edge). | architecture.md §9 | unhappy (invalid input) |
| FR-008 | Token checks (FR-013 to FR-016, FR-027, FR-028, FR-032, FR-034, FR-035, FR-036, FR-081, FR-084, FR-085, FR-097) and directive extraction MUST work on the lexer's output (FR-063): text inside `//`, `///` and `/* */` comments and inside string literals (single, double, raw, triple-quoted) MUST be ignored, but code inside `${...}` interpolation MUST still be examined. | architecture.md §9 | unhappy (false positive) |
| FR-009 | The suite MUST provide no inline suppression: a `// ignore` or similar comment MUST NOT change any check's result. The only exemptions are the named constants in the support code (platform entry points, reserved attribute keys, the shared attribute value sets of FR-085, the dependency allowlist of FR-083, the double-name prefixes of FR-081, the port handles of FR-082, the consumer-name list, the consumer-name scan's exempt paths of FR-026, the covered paths of FR-079, the leaf contexts of FR-098, the rank-90 threshold of FR-101, the placeholder spec names of FR-096, the data spec names of FR-099, the documentation index path of FR-102, the excluded paths of FR-002). | architecture.md §9 ("MUST fail the build") | unhappy (rule interaction) |
| FR-010 | The SourceSet's `unreadable` map (path to reason) lists every file the loader could not read or decode as UTF-8; the check MUST produce one Violation per entry, naming the file. The loader MUST NOT skip such a file silently. | package design | unhappy (failure) |
| FR-011 | Checks MUST be deterministic and independent: same SourceSet gives the same violations sorted by path, line, id; no network, clock, randomness or writes; passes under `--test-randomize-ordering-seed=random`. | testing.md §6, §10 | unhappy (determinism) |
| FR-012 | The suite MUST fail if the SourceSet lacks `lib/srd5e.dart` or `pubspec.yaml`, so a wrong root cannot pass every check vacuously. | package design | unhappy (empty case) |
| FR-059 | A test MUST fail when a check returns a non-empty list of Violation, printing them per FR-004. | architecture.md §9 | unhappy (failure) |
| FR-060 | Directive extraction MUST handle `show`, `hide`, `as` and `deferred as` clauses, and directives split across several lines. | architecture.md §9 | happy |
| FR-064 | Directive extraction MUST return every URI of a conditional configuration (`if (dart.library.io) 'x.dart'`) as an edge, in addition to the default URI. | architecture.md §9 | happy |
| FR-065 | Directive extraction MUST read directives from the lexer's code, so a directive inside a comment or string (`// import 'dart:io';`) is not an edge. The URI text comes from the lexer's string-literal list at the directive's position. | architecture.md §9 | unhappy (false positive) |
| FR-073 | Each real-repository test group MUST finish in under 10 seconds on CI. It carries a `Timeout(Duration(seconds: 10))`, so a slow group fails instead of hanging. No total budget is set for the whole suite; CI's own job duration is watched (section 7). | testing.md §6 | unhappy (boundary) |

### 4.2 Architecture checks (architecture.md §9)

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-013 | No file under `lib/src/` may import `package:flutter` or a package whose name starts with `flutter_` (for example `flutter_test`, `flutter_localizations`), or `dart:ui`; and no file under `lib/src/` outside an `adapters/` folder may import `dart:io`. Inside an `adapters/` folder `dart:io` is governed by FR-014. | architecture.md §9, bullet 1; §3 Purity; AGENTS.md "Pure Dart" | unhappy (invalid input) |
| FR-062 | No core entry point (`lib/srd5e.dart`, `lib/adapters.dart`, `lib/testing.dart`) may import `dart:io`, `dart:ui` or a Flutter package (FR-013's package rule). `lib/adapters.dart` is platform-neutral. | architecture.md §7, §9, bullet 1; AGENTS.md "Pure Dart" | unhappy (invalid input) |
| FR-014 | A file under an `adapters/` folder that imports `dart:io` MUST NOT be reachable through the import graph from a core entry point. A reachable file is a Violation. | architecture.md §9, bullet 1; §5 | unhappy (rule interaction) |
| FR-067 | A file under an `adapters/` folder that imports `dart:io` MUST be reachable through the import graph from a platform entry point; an unreachable one is a Violation (dead platform code). | architecture.md §9, bullet 1; §5; package design | unhappy (rule interaction) |
| FR-015 | A `domain/` file MUST NOT import a path containing an `application/`, `adapters/` or `shared_ports/` folder (own or another context's). It MUST NOT import `dart:async` or `dart:developer` either (the two libraries extend the rule: package design, section 9). | architecture.md §9, bullet 2; §1; extends §3 Purity (package design) | unhappy (invalid input) |
| FR-016 | A `domain/` file MUST NOT contain the tokens `async`, `await`, `Future`, `Stream`, or, as an extension of the rule text, `FutureOr`, `StreamController`, `StreamSubscription` or `Completer` (section 9). | architecture.md §9, bullet 2; §3 Purity; extends it (package design) | unhappy (invalid input) |
| FR-017 | A file whose path has no `adapters/` folder MUST NOT import a path with an `adapters/` folder, except `lib/adapters.dart` and platform entry points. This includes `shared_ports/adapters/`: a `shared_ports/` file outside that folder (a port, a no-op, `signals.dart`) importing it is a Violation. | architecture.md §1, §9, bullet 3; shared-types-and-ownership.md FR-037 | unhappy (invalid input) |
| FR-018 | A file in context X (a context folder, see section 3) importing any file of context Y (Y not X) MUST import exactly `lib/src/Y/Y.dart`; any other file of Y is a Violation. Files in `shared_kernel/`, `shared_ports/` and `testing/` are not in a context; FR-023, FR-024 and FR-075 govern them. | architecture.md §9, bullet 8 ("A file in one context importing"); §2 | unhappy (invalid input) |
| FR-019 | A file in context X importing the barrel of context Y MUST have Y in X's upstream set in the context map; otherwise Violation. | architecture.md §9, bullet 8 ("A file in one context importing"); §2 | unhappy (rule interaction) |
| FR-020 | The context map MUST be acyclic, and a self-edge counts as a cycle. A Violation names the contexts on the cycle. | architecture.md §9, bullet 9 ("A cycle in the context map"); §2 | unhappy (invalid input) |
| FR-021 | Every folder directly under `lib/src/` other than `shared_kernel/`, `shared_ports/` and `testing/` MUST be a context in the map, and no loose `.dart` file may sit directly in `lib/src/`. A map entry with no folder is allowed (planned contexts). | architecture.md §1, §9, bullet 9 ("A cycle in the context map"); shared-types-and-ownership.md FR-038 | unhappy (missing content) |
| FR-022 | The context map MUST be parsed from the table whose header cells are `Context`, `Purpose`, `May depend on (upstream)` in `architecture.md` §2: the Context cell is one backticked name, the upstream cell is `none` or backticked names separated by commas. A table that is missing, has another header, or has a cell outside this format is a Violation. The `AGENTS.md` "Current contexts" list MUST name exactly the same contexts. | architecture.md §2 ("update this table, AGENTS.md and the architecture tests in the same change") | unhappy (state error) |
| FR-023 | A `shared_kernel/` file MUST NOT import anything in the package outside `lib/src/shared_kernel/` (including `package:srd5e/srd5e.dart`); `dart:` core libraries, `package:meta` and `package:collection` are allowed. | architecture.md §9, bullet 10 ("shared_kernel/ importing anything else"); §2 | unhappy (invalid input) |
| FR-024 | A `shared_ports/` file, including one under `shared_ports/adapters/`, MUST NOT import anything in the package except `lib/src/shared_kernel/` and its own `shared_ports/` folder (a file in `shared_ports/adapters/` may import its port; one outside it may not import the adapters folder, FR-017). | architecture.md §9, bullet 10 ("shared_kernel/ importing anything else"); §1; shared-types-and-ownership.md FR-036, FR-037 | unhappy (invalid input) |
| FR-061 | No file under `lib/src/` may import or export a core entry point (`lib/srd5e.dart`, `lib/adapters.dart`, `lib/testing.dart`) or a platform entry point, by `package:srd5e/...` or by a relative URI. Entry points re-export every barrel, so such an import bypasses FR-015, FR-018, FR-019 and FR-034. | architecture.md §2, §9, bullet 8 ("A file in one context importing") | unhappy (rule interaction) |
| FR-025 | No file under `lib/` (path, comment or code) may contain, case-insensitively and ignoring `-`, `_` and spaces, the name of a consuming project or the hosting organisation from the denylist. | architecture.md §9, bullet 11 ("A file in lib/ containing the name"); AGENTS.md "Hard constraints" | unhappy (invalid input) |
| FR-026 | No file of the SourceSet outside `lib/` (path or content) MUST contain a denylist name (same matching as FR-025). The scan covers every SourceSet path (`test/`, `example/`, `tool/`, `doc/`, `.github/`, the root files, `pubspec.yaml`) except these exempt paths, kept as named constants (FR-009): the `repository:` line of `pubspec.yaml`, and `AGENTS.md` and `CLAUDE.md`, which state the rule and so must name its subject. | AGENTS.md "Hard constraints" (exception limited to the `repository` URL) | unhappy (invalid input) |
| FR-068 | The denylist's own source file MUST NOT contain a denylist name in plain text; it assembles the names from fragments at run time. The same holds for the trademark and affiliate lists that `content-licensing-and-notice.md` FR-031 keeps in `test/architecture/support/constants.dart`: the plain-text self-test covers every list in that file. | AGENTS.md "Hard constraints" | unhappy (invalid input) |
| FR-027 | A `domain/` or `application/` file MUST NOT call `Random(`, `Random.secure(`, `DateTime.now(`, `DateTime.timestamp(` or `Stopwatch(`, nor tear off `DateTime.now`. | architecture.md §9, bullet 12 ("Use of Random("); §3 Purity | unhappy (invalid input) |
| FR-028 | No file under `lib/` may call `print(` (a bare call, not a method named `print` on an object). | architecture.md §9, bullet 12 ("Use of Random("); observability.md §10 | unhappy (invalid input) |
| FR-029 | Each `doc/rules/*.md` file MUST have exactly one line starting with `RULE-TAG:`, whose value is a backticked token `<file stem>-<12 lowercase hex digits>`. Zero or two such lines is a Violation. | architecture.md §9, bullet 13 ("A doc/rules/*.md file without exactly one line"); AGENTS.md | unhappy (boundary) |
| FR-030 | A rule tag's value MUST NOT appear in any other file of the SourceSet (FR-002 scope, so `.github/`, `CLAUDE.md` and `tool/` are covered), nor on another line of its own file; two rule files sharing a value is a Violation in both. | architecture.md §9, bullet 13 ("A doc/rules/*.md file without exactly one line") | unhappy (invalid input) |
| FR-031 | Every `doc/rules/*.md` file MUST be listed in the `AGENTS.md` "Read the rules first" list, and every path listed there MUST exist. | AGENTS.md ("new rule files go on this list") | unhappy (missing content) |
| FR-074 | No file outside `lib/src/testing/`, other than `lib/testing.dart`, may import or export a file under `lib/src/testing/`, by `package:srd5e/src/testing/...` or by a relative URI. | architecture.md §1, §9, bullet 4; observability.md §10, last bullet; shared-types-and-ownership.md FR-038 | unhappy (rule interaction) |
| FR-075 | A file under `lib/src/testing/` MAY import only: `dart:` core libraries, `package:meta`, `package:collection`, other files of `lib/src/testing/`, `lib/src/shared_kernel/`, `lib/src/shared_ports/` (not its `adapters/` folder) and the barrel `lib/src/<context>/<context>.dart` of any context. Any other path in the package (a context's `domain/`, `application/`, `adapters/`, an entry point) is a Violation. The context map does not apply: a double may use any barrel. | architecture.md §1 (`testing` row), §9, bullet 4; shared-types-and-ownership.md FR-038 | unhappy (invalid input) |
| FR-076 | No file under `lib/` may import or export a path that resolves outside `lib/` (a relative `../` that escapes `lib/`: `tool/`, `test/` including `test/contract/`, or any other), and none may import `package:test`, `package:test_api`, `package:matcher` or `package:coverage` (dev-only packages: contract suites are not exported, so `package:test` must not become a runtime dependency). `package:srd5e/` cannot reach `tool/` or `test/`. Files under `tool/` and `test/` MAY import `lib/`. | architecture.md §5, §7, §9, bullet 5 ("A file under `lib/` importing anything from `tool/`"); extends it to `test/` and the dev packages (package design); shared-types-and-ownership.md FR-032, FR-039 | unhappy (invalid input) |
| FR-077 | Barrel scan. Resolve the export closure (FR-093) of every barrel and every core entry point. (a) A top-level declaration named `Applied`, `Rejected`, `Succeeded`, `ContentMissing`, `Found` or `NotFound` (class, enum, mixin, extension type or typedef) that is exported by any of them is a Violation. (b) Two different declarations (different defining file) with the same name exported through the same barrel or entry point, or through two different barrels, are a Violation; one declaration re-exported by several barrels or entry points is not. A `show` or `hide` clause is honoured. A `*Signals` class and `AttributeKeys` are legitimately exported from `lib/srd5e.dart` (`resolve-d20-test-use-case.md` FR-042, `observability-ports.md` FR-048); the scan does not flag them, and the duplicate rule (b) still applies to them. | architecture.md §4, §9; shared-types-and-ownership.md FR-017, FR-021 | unhappy (invalid input) |
| FR-078 | Drift check. The check function takes the generator as a parameter: a pure function from the `data/` file texts to the text of each library, or `null`. Given a function, it MUST reproduce, byte for byte, every embedded data library under `lib/src/content/data/`; a missing, extra or differing library is a Violation naming it. The check passes vacuously when neither `data/` nor `lib/src/content/data/` exists, and when the generator is `null`. The real-repository wiring imports `generateEmbeddedLibraries` from `tool/generate_embedded_data.dart` and is added in the change that adds that file (until then the real-repository test passes `null`, so the first guardrail change compiles and passes; no stub tool file is required). The generator's own shape and tests belong to the spec that defines it (`content-schema-and-decoder.md` FR-121; the drift rule is its FR-123). The function does no I/O. `content-thin-slice.md` moved its drift check here (it withdrew its own), and `content-equipment.md` FR-096 defers to this one (`shared-types-and-ownership.md` FR-048). | architecture.md §5, §9, bullet 7 ("The embedded libraries under");  shared-types-and-ownership.md FR-030, FR-032 | unhappy (state error) |
| FR-079 | Notice paths and `.pubignore` (check name `notice_paths`; owner: `shared-types-and-ownership.md` FR-050; `content-licensing-and-notice.md` defines the list and the Scope wording, FR-005 there). (a) While bundled content is present (the SourceSet holds a path under `data/`, `lib/src/content/data/` or `test/fixtures/srd/` other than `.gitkeep` and `README.md`), the set of backticked tokens in the "Scope" section of `NOTICE.md` that match `^[A-Za-z0-9_.-]+(/[A-Za-z0-9_.-]+)*/$` (a path ending in `/`) MUST equal the named constant `noticeCoveredPaths` = {`data/`, `lib/src/content/data/`, `test/fixtures/srd/`}; a missing or extra path is a Violation naming it, at the line of the token (or of the heading when missing). A missing `NOTICE.md`, a missing "Scope" section and the statement wording are not this check: they belong to `content-licensing-and-notice.md` FR-002 and FR-005. (b) While the SourceSet holds a path under `doc/research/`, `.pubignore` MUST exclude `doc/research/`, evaluated with the gitignore rules (later lines win, `!` negation, a leading `/` anchors, a trailing `/` matches directories only, a parent directory excluded excludes its content, `*` and `**`); a missing `.pubignore`, or one that does not exclude it, is a Violation. The evaluator is support code (`gitignore.dart`) shared with the checks that `content-licensing-and-notice.md` and `release-0-1-0.md` define; this check adds no other `.pubignore` rule. (c) A self-test fails when the constant is not equal to the set of backticked tokens, by the token rule of (a), in the first sentence of the FR-033 row of `shared-types-and-ownership.md` (the sentence that begins "`NOTICE.md` covers exactly:" and ends at its first full stop followed by a space), so the two cannot drift. Later sentences of that row, such as the backticked `doc/research/` in the one about notes that are not distributed, are not part of the set. | shared-types-and-ownership.md FR-033, FR-050; `AGENTS.md`, "The notice" | unhappy (state error) |
| FR-080 | A file under `lib/src/<context>/` MUST NOT import its own barrel `lib/src/<context>/<context>.dart` (it only creates a cycle). | package design (decoupling; section 9) | unhappy (rule interaction) |
| FR-081 | A class under `lib/` that `implements` or `extends` a driven port (FR-082; a port handle is not one) and whose name starts with one of the double prefixes (`Fake`, `Recording`, `Fixed`, `Scripted`, `Stub`, `Spy`, `Mock`; a named constant, FR-009) MUST be declared under `lib/src/testing/`. A `Noop*` class is not a double (FR-084). The import side is FR-074. | observability.md §10, last bullet; architecture.md §7; shared-types-and-ownership.md FR-038 | unhappy (invalid input) |
| FR-082 | Every driven port (an `abstract interface class` declared in `shared_ports/`, including a subfolder such as `shared_ports/observability/` but not `shared_ports/adapters/`, or in a `<context>/application/ports/` folder, and whose name is not in the named constant `portHandles`, FR-009) MUST have (a) at least one class under `lib/src/testing/` that `implements` or `extends` it, with the declaring file exported by `lib/testing.dart`, and (b) a contract suite file `test/contract/<port name in snake_case>_contract.dart`. Both are vacuous when no port exists. `portHandles` is `{Span, Counter, Histogram, Gauge}`: handles returned by ports, not ports, so they need no double or contract file of their own (`observability-ports.md` FR-065 requests the exemption). `release-0-1-0.md` FR-084 takes its port definition from this requirement; it must also apply `portHandles`, so the release snapshot and this check agree that the four handles are not ports (a change request to that spec, section 9). | extends architecture.md §7 (package design: the `test/contract/<snake>_contract.dart` naming and the handle exemption); architecture.md §9 (Bootstrap), Checklist; observability.md §4 (recording double); testing.md §10; shared-types-and-ownership.md FR-038, FR-039 | unhappy (missing content) |
| FR-083 | `pubspec.yaml` `dependencies:` MUST list only `collection` and `meta` (and the `sdk` environment line outside that block). The allowlist is a named constant (FR-009); changing it is the "discussion" `AGENTS.md` requires, made in the same change as the new dependency. `dev_dependencies:` are not checked. FR-033 stays as the observability-specific message. `release-0-1-0.md` FR-060 restates the allowlist today and already cites this check instead. | AGENTS.md "Hard constraints"; extends observability.md §10, bullet 1 (package design) | unhappy (invalid input) |
| FR-095 | A file under `lib/src/content/data/` MUST import nothing in the package, and MAY be imported, among files under `lib/`, only by files under `lib/src/content/adapters/`; `lib/adapters.dart` and the other entry points reach the data only through that adapter (one decode path: embedded strings reach the domain only through the decoder). The scope is files under `lib/`: `test/` and `tool/` MAY import the data libraries. | architecture.md §5; shared-types-and-ownership.md FR-030, FR-031 | unhappy (rule interaction) |
| FR-097 | No use case calls another use case. A file under `lib/src/<context>/application/` or `lib/src/<context>/domain/` MUST NOT mention, as an identifier in the lexer's code (FR-063), a use case class (section 3) declared in a different file, whether of its own context or another. A use case composes the pure domain services that upstream barrels publish (for example `D20TestResolver`, which is in `domain/`, so not a use case class) and takes dice and content through its own ports; nesting a use case would hide telemetry and count a signal twice. A domain service must therefore never be given a public `call` member under `application/`. The use case set is derived from the source, not listed. Test files and `lib/src/testing/` MAY mention use cases. | architecture.md §2, §4; shared-types-and-ownership.md FR-044 | unhappy (rule interaction) |
| FR-098 | Shape of the parsed context map (FR-022), for the leaf contexts in the named constant `leafContexts` = {`toolbox`}: (a) no context's upstream set may contain a leaf context (nothing depends on `toolbox`); (b) a leaf context present in the map MUST list only contexts that are themselves in the map (no unknown name); (c) a leaf context's folder `lib/src/toolbox/` is a context folder like any other (FR-021) and its files obey FR-018 and FR-019 in the import legality cases of section 4.5. The map, not a copy, stays the source of truth: the constant only names which entries are leaves, and a self-test fails when `shared-types-and-ownership.md` no longer contains `toolbox` in its FR-045 row. A context not in `leafContexts` is not constrained here, so a future leaf is a constant edit in the change that adds it. | architecture.md §2 (context map, "Nothing depends on `toolbox`"); shared-types-and-ownership.md FR-045 | unhappy (rule interaction) |
| FR-103 | No file under `lib/src/shared_ports/`, including its `adapters/` folder and the no-ops, may call `Random(` in any form (seeded or not), `Random.secure(`, `DateTime.now(`, `DateTime.timestamp(` or `Stopwatch(`, nor tear off `DateTime.now`. FR-027 covers `domain/` and `application/`; this extends the same ban to `shared_ports/` with no carve-out for adapters, because the seeded `Random` is injected by the consumer (`dice-and-rolls.md` FR-064) and only consumer adapters read the clock. `print(` stays FR-028's. | observability-ports.md FR-053; architecture.md §3, §9; observability.md §4 "Timing"; extends FR-027 (package design) | unhappy (determinism) |
| FR-104 | `Observability` and `NoopObservability` MUST each be a `final class`, declared in the same file under `lib/src/shared_ports/observability/`; `Observability` MUST carry `@immutable` and `NoopObservability` MUST extend it and have only `const` constructors (FR-084 also applies). Dart's `final` modifier then allows the subclass inside that library and blocks every other `extends` or `implements`, including a consumer's, so `identical(Observability.none, ...)` and the immutability guarantee cannot be broken. | observability-ports.md FR-062; shared-types-and-ownership.md FR-036; observability.md §4 | unhappy (invalid input) |

### 4.3 Observability checks (observability.md §10)

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-032 | No file under `lib/` may import an observability or error-tracking package: package name equal to or starting with `opentelemetry`, `dart_opentelemetry`, `sentry`, `logging`, `logger`, `datadog`, `bugsnag`, `newrelic`, `firebase_crashlytics`, or the library `dart:developer`. | observability.md §10, bullet 1; §4; the package list and `dart:developer` extend it (package design) | unhappy (invalid input) |
| FR-033 | `pubspec.yaml` `dependencies:` MUST NOT list a package matching FR-032's denylist. `dev_dependencies:` are not checked. | observability.md §10, bullet 1 | unhappy (invalid input) |
| FR-034 | A `domain/` file MUST NOT mention an identifier that is, or ends in a CamelCase word, `Logger`, `Tracer`, `Meter` or `Observability`, nor a variable named `logger`, `tracer`, `meter` or `observability`. | observability.md §10, bullet 2; §3 | unhappy (invalid input) |
| FR-035 | A top-level or `static` declaration whose declared type or constructor initialiser names a `Logger`, `Tracer`, `Meter` or `Observability` type MUST be a Violation, unless the declaration is `const` (stateless no-op default). The `const` classes themselves are checked by FR-084. | observability.md §10, bullet 4; §4 | unhappy (invalid input) |
| FR-036 | Under `lib/` only: a string literal whose value begins with `srd5e.` or equals a reserved attribute key (`error.type`) MUST appear only in a constants file (section 3), never at a call site, in `domain/`, or built by interpolation or concatenation. `AttributeKeys` is in a constants file, so its `'srd5e.outcome'` and `'error.type'` literals are allowed there and nowhere else. | observability.md §10, bullet 5; §5 Naming | unhappy (invalid input) |
| FR-037 | Under `lib/` only: in a constants file, every `srd5e.` literal, and every literal initialising a `*LogEvent` member, MUST be the plain initialiser of a `static const String` member of an `abstract final class` that is a signals class (section 3); any other string literal in a constants file is not constrained by this check. Every such member of a `*Signals` class MUST have an identifier ending `Metric`, `Span`, `LogEvent`, `Attribute` or `Value` (an attribute value constant, FR-085). Members of `AttributeKeys` are exempt from the suffix rule (they are attribute keys: `observability-ports.md` FR-052). A `*Signals` class MUST be declared in a constants file, and a top-level `const String` in a constants file is a Violation. | observability.md §5 Naming ("defined in one place per context") | unhappy (invalid input) |
| FR-038 | Under `lib/` only: a `Metric` or `Span` signal constant's value MUST match `^srd5e\.[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$`, and its second segment MUST be the context folder of the defining file. A `LogEvent` constant is the constant log message (the Logger has no event-name field): its value MUST match `^[a-z][a-z0-9]*( [a-z0-9]+)*$` and has no context segment. A signal constant of any kind in `shared_ports/` is a Violation (shared constants are the `AttributeKeys` members). The rule is about shape only: the check names no use case, and which spec owns a given signal is settled by `shared-types-and-ownership.md` FR-040 (one authority per signal; FR-040 here catches a duplicate value). | observability.md §5 Naming, §7; observability-ports.md FR-002; shared-types-and-ownership.md FR-040, FR-043 | unhappy (boundary) |
| FR-039 | Under `lib/` only: an attribute constant's value (a `*Attribute` member of a `*Signals` class, or any `AttributeKeys` member) MUST match `^srd5e\.[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)*$` or be a reserved key. | observability.md §5 Attributes | unhappy (boundary) |
| FR-040 | Under `lib/` only: no two signal constants anywhere in `lib/` may have the same value. | observability.md §10, bullet 6 | unhappy (invalid input) |
| FR-041 | `doc/observability/signals.md` MUST contain a table whose header cells are, in order, Name, Type, Unit, Attributes, Emitted by, Purpose, Suggested monitoring; a row with a different cell count is a Violation. Zero data rows is valid. Backticks around a Name cell are stripped. | observability.md §2 (catalogue fields) | unhappy (invalid input) |
| FR-042 | Every signal constant's value MUST appear as a Name in the catalogue. | observability.md §10, bullet 6 | unhappy (missing content) |
| FR-043 | Every catalogue Name MUST equal some signal constant's value. | observability.md §10, bullet 6 | unhappy (missing content) |
| FR-044 | Catalogue Names MUST be unique. | observability.md §2 ("single list") | unhappy (invalid input) |
| FR-045 | A catalogue row's Purpose MUST NOT be empty or a placeholder (`TODO`, `TBD`, `N/A`, `-`, case-insensitive). | observability.md §10, bullet 7 | unhappy (boundary) |
| FR-046 | A catalogue row's Suggested monitoring MUST NOT be empty or a placeholder (same set as FR-045). | observability.md §10, bullet 7; §2 | unhappy (boundary) |
| FR-047 | A catalogue row's Type MUST start, case-insensitively, with `counter`, `histogram`, `gauge`, `span` or `log event`, and trailing text after that word is ignored. It MUST agree with the member-name suffix in the `*Signals` class (`...Metric` is counter, histogram or gauge; `...Span` is span; `...LogEvent` is log event). The unit is the Unit column's content, never part of Type. The conversion from the template's five-column signal table (`_template.md` section 7: Signal, Type, Attributes, Purpose, Suggested monitoring) to these seven catalogue columns happens when a row is copied into `doc/observability/signals.md`: Unit and Emitted by are added then, not in the specs. | observability.md §2 (catalogue fields) | unhappy (invalid input) |
| FR-048 | Every attribute constant's value (a `*Attribute` member of a `*Signals` class or an `AttributeKeys` member, FR-039) MUST appear in backticks in the Attributes cell of at least one catalogue row, and every backticked `srd5e.`-prefixed or reserved key in an Attributes cell MUST be an attribute constant's value. | observability.md §5 Attributes; §2 | unhappy (missing content) |
| FR-084 | Every class whose name starts with `Noop` MUST be declared under `lib/src/shared_ports/` and outside any `adapters/` folder, and MUST have at least one constructor and only `const` constructors. | extends observability.md §4, §10 (no-op bullet) to every `Noop*` class, not only the observability ones (package design); architecture.md §1; shared-types-and-ownership.md FR-036 | unhappy (invalid input) |
| FR-085 | Shared attribute values. The closed sets are named constants in the support code (FR-009): `srd5e.outcome` is `success`, `failure`; `srd5e.d20_test.kind` is `ability_check`, `saving_throw`, `attack_roll`; `srd5e.d20_test.roll_mode` is `normal`, `advantage`, `disadvantage`; `srd5e.d20_test.critical_hit` is `true`, `false`. (a) In code, an attribute value constant (a `static const String` member of a `*Signals` class whose identifier ends `Value`) MUST have a doc comment that names its attribute key in backticks; if the key is one of the four above its value MUST be in that key's set; if the key is `error.type` its value MUST equal the snake_case of the name of a class in `lib/` that `extends` or `implements` `Srd5eException`, and MUST match `^[a-z][a-z0-9_]*$`. (b) In the catalogue, a shared key in an Attributes cell lists its values as backticked tokens in parentheses straight after it, for example `` `srd5e.outcome` (`success`, `failure`) ``; each listed value MUST be in the key's set (for `error.type`, as in (a)). (c) A self-test fails when any set value is absent, in backticks, from `observability.md` §5, so the two cannot drift. | observability.md §5 Attributes, §10 (shared attribute value bullet); shared-types-and-ownership.md FR-041 | unhappy (boundary) |

### 4.4 Test-citation checks (testing.md §9)

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-049 | Every `group(` and `test(` in `test/`, outside `test/architecture/`, MUST be immediately preceded (no blank line between) by a `///` comment block containing a line starting `Requirement:` or `Rule:`, unless FR-051 applies. | testing.md §9 | unhappy (invalid input) |
| FR-050 | `Requirement: none - <reason>` MUST have a non-empty reason after the dash; a bare `Requirement: none`, or an empty `Requirement:`, is a Violation. | testing.md §5, §9 | unhappy (boundary) |
| FR-051 | A `group(` or `test(` inside a loop (FR-066) is satisfied by the comment of the nearest enclosing loop or enclosing `group(` that carries `Requirement: per case`. That comment MUST contain `Requirement: per case`. | testing.md §5, §9 | unhappy (rule interaction) |
| FR-052 | `Requirement: per case` MUST appear only on a comment above a loop (FR-066) that contains at least one `group(` or `test(`, or above a `group(` whose body contains such a loop. | testing.md §5 | unhappy (state error) |
| FR-053 | Each comment with a `Requirement:` line (including `Requirement: none - ...`) MUST contain a `Path:` line whose value is `happy`, `unhappy (<kind>)` with a non-empty kind, or `per case`; `per case` is valid only with `Requirement: per case`. A comment with only `Rule:` need not carry `Path:` (decided, section 9). | testing.md §5 (format) | unhappy (invalid input) |
| FR-054 | A citation (FR-070) MUST name an existing spec file and ids present in that spec's requirements table (FR-071). A range (`FR-1 to FR-3`, `FR-1-FR-3`, `FR-1..3`) is a Violation, and so is a moved id (FR-087). | testing.md §5 ("keep citations true") | unhappy (missing content) |
| FR-055 | For every spec whose Status is `implemented`, every FR id in its requirements table MUST be cited by at least one test, except a moved id (FR-087) and an id its section 8 lists on a line `Deliberately not covered: FR-<n> - <reason>` with a non-empty reason (one id per line; `none` lists nothing). | testing.md §5 ("every requirement SHOULD be covered"); doc/specs/_template.md §8 | unhappy (missing content) |
| FR-056 | A spec's Status value MUST be one of `draft`, `accepted`, `implemented`. | doc/specs/_template.md | unhappy (invalid input) |
| FR-086 | No file under `test/` may contain a comment line that is a commented-out `test(`, `group(`, `setUp(` or `tearDown(` call (a comment whose text, after `//`, starts with one of them; this check reads the lexer's comment list, FR-063), and a `skip:` argument or `skip(` call is allowed only when the doc comment above the test carries an `Issue:` line with a non-empty value (a link or id and a reason). | testing.md §6 ("No skipped or commented-out tests"), §11; the `Issue:` field extends it (package design) | unhappy (invalid input) |

### 4.5 Import legality cases

A `;` in the Importer and Imports cells pairs them by position; each pair is a separate test case. Each row is one table-driven self-test for FR-013 to FR-019, FR-023, FR-024,
FR-061, FR-062, FR-074 to FR-076, FR-080, FR-095, FR-097 and FR-098; the
reachability rows also exercise FR-014 and FR-067 (graph fixtures in section 8).
"Violates" lists the FR ids expected; `none` means the import is allowed.
FR-020 to FR-022 and FR-007 have their own fixtures (section 8).

| Label | Importer | Imports | Violates | Source | Path |
|---|---|---|---|---|---|
| domain to own domain, kernel | `d20_test/domain` | a `d20_test/domain` file; `shared_kernel` | none | architecture.md §1 | happy |
| domain to upstream barrel | `character/domain` | `d20_test/d20_test.dart` | none | architecture.md §1, §2 | happy |
| application to upstream barrel, shared ports | `character/application`; `d20_test/application` | `content/content.dart`; `shared_ports` | none | architecture.md §1 | happy |
| adapter to own ports | `content/adapters` | `content/application/ports` | none | architecture.md §1 | happy |
| combat to every upstream | `combat/application` | barrels of `character`, `d20_test`, `content` | none | architecture.md §2 | happy |
| toolbox to every upstream | `toolbox/application` | barrels of `content`, `d20_test`, `character`, `combat` | none | architecture.md §2 | happy |
| use case uses a domain service | `combat/application` file mentioning `D20TestResolver` (a `domain/` class) | `d20_test/d20_test.dart` | none | architecture.md §4 | happy |
| shared ports to kernel; shared adapter to port and kernel | `shared_ports`; `shared_ports/adapters` | `shared_kernel`; a `shared_ports` port file; `shared_kernel` | none | architecture.md §1 | happy |
| no-op default in application | `d20_test/application` | `shared_ports` no-op file | none | observability.md §4 | happy |
| `dart:async` in application | `d20_test/application` | `dart:async` | none | architecture.md §3 | happy |
| `dart:io` behind platform entry point | `content/adapters` file reached only from `lib/io.dart` | `dart:io` | none | architecture.md §9 | happy |
| adapter reads embedded data; tool imports lib | `content/adapters`; `tool/generate.dart` | `content/data` file; `lib/src/content/content.dart` | none | architecture.md §5 | happy |
| adapters entry point to shared adapters | `lib/adapters.dart` | `shared_ports/adapters/` file | none | architecture.md §1 | happy |
| double to port, barrels, another double | `testing` | a `shared_ports` port file; `content/content.dart` and `combat/combat.dart` (no map edge); `testing` | none | architecture.md §1 | happy |
| testing entry point to doubles | `lib/testing.dart` | `lib/src/testing/` file | none | architecture.md §7 | happy |
| domain to shared ports | `d20_test/domain` | `shared_ports` | FR-015 | architecture.md §1 | unhappy (invalid input) |
| domain to own application | `d20_test/domain` | `d20_test/application` | FR-015 | architecture.md §9 | unhappy (invalid input) |
| domain to own adapters | `d20_test/domain` | `d20_test/adapters` | FR-015, FR-017 | architecture.md §9 | unhappy (invalid input) |
| `dart:async` in domain | `d20_test/domain` | `dart:async` | FR-015 | architecture.md §3 | unhappy (invalid input) |
| application to own adapters | `content/application` | `content/adapters` | FR-017 | architecture.md §9 | unhappy (invalid input) |
| port library imports its adapters | `shared_ports` (outside `adapters/`) | `shared_ports/adapters/` file | FR-017 | architecture.md §1 | unhappy (invalid input) |
| domain to other internals | `character/domain` | `content/domain/species.dart` | FR-018 | architecture.md §2 | unhappy (invalid input) |
| toolbox imports internals | `toolbox/domain` | `combat/domain/damage.dart` | FR-018 | architecture.md §2 | unhappy (invalid input) |
| adapter to other adapter | `combat/adapters` | `character/adapters` | FR-018 | architecture.md §9 | unhappy (rule interaction) |
| non-upstream barrel | `character/domain` | `combat/combat.dart` | FR-019 | architecture.md §2 | unhappy (rule interaction) |
| upstream context imports downstream | `d20_test/application` | `character/character.dart` | FR-019 | architecture.md §2 | unhappy (rule interaction) |
| root context has no upstream | `content/application` | `d20_test/d20_test.dart` | FR-019 | architecture.md §2 | unhappy (rule interaction) |
| downstream of toolbox | `combat/application` | `toolbox/toolbox.dart` | FR-019 | architecture.md §2 | unhappy (rule interaction) |
| use case calls a use case | `toolbox/application` file mentioning `ResolveD20Test` (a use case of `d20_test`) | `d20_test/d20_test.dart` | FR-097 | architecture.md §4 | unhappy (rule interaction) |
| kernel to ports | `shared_kernel` | `shared_ports` | FR-023 | architecture.md §9 | unhappy (invalid input) |
| kernel to entry point | `shared_kernel` | `package:srd5e/srd5e.dart` | FR-023, FR-061 | architecture.md §9 | unhappy (invalid input) |
| ports or shared adapter to a context | `shared_ports`; `shared_ports/adapters` | `content/content.dart` | FR-024 | architecture.md §9 | unhappy (invalid input) |
| `dart:io` in core adapter | `content/adapters` file reachable from `lib/adapters.dart` and also from `lib/io.dart` (so FR-067 is satisfied and only FR-014 fires) | `dart:io` | FR-014 | architecture.md §9 | unhappy (boundary) |
| `dart:io` in unreachable adapter | `content/adapters` file reached from no entry point | `dart:io` | FR-067 | architecture.md §5 | unhappy (rule interaction) |
| conditional import | `d20_test/domain` | `if (dart.library.io) 'dart:io'` | FR-013 | architecture.md §9 | unhappy (rule interaction) |
| `dart:io`, flutter, `dart:ui` in domain | `d20_test/domain` | `dart:io`; `package:flutter/foundation.dart` | FR-013 | architecture.md §9 | unhappy (invalid input) |
| flutter test package, `dart:ui` | `content/application` | `package:flutter_test/flutter_test.dart`; `dart:ui` | FR-013 | AGENTS.md "Pure Dart" | unhappy (invalid input) |
| domain or application to aggregate entry point | `d20_test/domain`; `content/application` | `package:srd5e/srd5e.dart`; `package:srd5e/adapters.dart` | FR-061 | architecture.md §2, §9 | unhappy (rule interaction) |
| core entry point to `dart:io` | `lib/adapters.dart` | `dart:io` | FR-062 | architecture.md §7 | unhappy (invalid input) |
| double to context internals | `testing` | `content/domain/species.dart` | FR-075 | architecture.md §1 | unhappy (invalid input) |
| double to adapters | `testing` | `content/adapters/` file or `shared_ports/adapters/` file | FR-075, FR-017 | architecture.md §1 | unhappy (invalid input) |
| double to entry point | `testing` | `package:srd5e/srd5e.dart` | FR-075, FR-061 | architecture.md §1, §2 | unhappy (rule interaction) |
| context or entry point imports a double | `combat/application`; `lib/srd5e.dart` | `testing` file; `lib/src/testing/` file | FR-074 | architecture.md §9 | unhappy (rule interaction) |
| lib imports tool, contract suite, test package | `content/adapters`; `content/adapters`; `content/application` | `../../../../tool/generate.dart` (exists); `../../../../test/contract/x_contract.dart` (exists); `package:test/test.dart` | FR-076 | architecture.md §9; testing.md §10 | unhappy (invalid input) |
| entry point reads embedded data | `lib/adapters.dart` | `content/data` file | FR-095 | architecture.md §5 | unhappy (rule interaction) |
| domain or application reads embedded data | `content/domain`; `content/application` | `content/data` file | FR-095 | architecture.md §5 | unhappy (rule interaction) |
| data library imports | `content/data` | `content/domain` file | FR-095 | architecture.md §5 | unhappy (invalid input) |
| own barrel | `character/domain` | `character/character.dart` | FR-080 | package design | unhappy (rule interaction) |

### 4.6 Support rules (not checks)

These shape the support code. They yield no Violation of their own, so they are
not check ids (FR-005); each is a unit-level test of the support code
(section 8).

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-057 | `test(` and `group(` detection MUST ignore matches preceded by `.` or an identifier character (`mytest(`, `helper.test(`) and MUST NOT treat `setUp(`, `tearDown(` or `testOn:` arguments as tests. | testing.md §9 | unhappy (false positive) |
| FR-058 | A fixture SourceSet holding only `lib/srd5e.dart`, `pubspec.yaml`, the docs, and empty context folders (no `.dart` file under `lib/src/`) MUST yield zero Violations from every check. FR-003's real-repository run covers the repository itself. | architecture.md §9 Bootstrap | happy |
| FR-069 | A new consuming project is added to the denylist by adding its fragments to the constant in `test/architecture/support/constants.dart`, in the same change that first introduces the dependency. The self-test asserts every denylist entry matches a fixture in each form of FR-025 (comment, string, path, case, separators). | AGENTS.md "Hard constraints" | unhappy (state error) |
| FR-070 | Citation grammar: in a `Requirement:` comment, including its `///   ` continuation lines, and in the string value of a `requirement:` field of a table row, a citation is `doc/specs/<name>.md` followed by one or more `FR-<n>` ids separated by commas, `and` or `&`. Ids in `requirement:` fields count for FR-054 and FR-055 as much as comment ids. | testing.md §5 (format, table-driven tests) | happy |
| FR-071 | The requirements table of a spec is every row in its section 4 whose first cell matches `^FR-\d+$`; rows of other section 4 tables (such as section 4.5's label column) are not ids. | testing.md §5; doc/specs/_template.md | happy |
| FR-087 | A moved-id row (section 3) is kept so ids are never renumbered. It is excluded from FR-005's meta-test, from FR-055's coverage rule and from the section 8 id-coverage rule. FR-087 is a support rule, not a check: it yields no Violation of its own. A citation (FR-070) of a moved id is a Violation of FR-054 ("keep citations true"). | testing.md §5 ("Keep citations true"); package design (ids are stable, so a moved requirement stays as a moved-id row) | unhappy (state error) |
| FR-072 | FR-036 to FR-040 scan `lib/` only. Tests under `test/` and the architecture fixtures MAY spell signal names, attribute keys and log messages as literals (they pin the values: `observability.md` §9). | observability.md §9 | happy |
| FR-063 | The lexer MUST return three things: (a) the code with comment and string contents blanked, positions preserved; (b) the comment list, each with kind (line, doc or block), start line and text; (c) the string literal list, each with value, start line and offset, and whether it is raw or interpolated. Brace matching for loop bodies MUST run on (a). | package design | happy |
| FR-066 | A test or group counts as inside a loop when it is lexically inside the body of a `for` statement (including `for-in`), or inside the closure passed to `.forEach(` or `.map(`. Other generators (`List.generate`, `Iterable.expand`, ...) are not recognised: a test inside one needs its own comment (FR-049). | testing.md §5 (table-driven tests) | happy |
| FR-093 | Export closure. Given a barrel or core entry point, the support code returns the set of (declaring file, declared name) for every top-level class, mixin, enum, extension type, extension and typedef reachable through `export` directives, followed transitively, with `show` and `hide` applied at each step. Names come from the lexer's code (FR-063). A name starting with `_` is private and excluded. | architecture.md §9 (barrel scan); package design | happy |
| FR-094 | Spec header. The support code parses the first table of a spec (the two-column table under the title) into Status, Context, Roadmap phase and Depends on. Context is the first backticked token of its cell. Roadmap phase is the type phase: the first integer in the cell, or the first range `a-b` or `a–b` (which gives a lowest and a highest); everything after it is ignored, including later integers, `bulk data N`, `Phase 5` and any parenthesised text, as for Depends on. A cell with no integer is a Violation under FR-092. So `Types 2; bulk data 5` is phase 2, `3 for the Armor...; 5 for the rest` is phase 3, and `0 (see ../roadmap.md)` is phase 0. Depends on is the set of `` `name.md` `` tokens in the cell, separated by commas; `none` or empty means an empty set. Anything else in the cell (a link, prose, an FR id, a parenthesis) is a Violation of FR-100. Every token counts as a real dependency, so a spec MUST NOT name one there that it does not depend on; explanations belong in section 1. Any other header row (for example `Consumed by`) is ignored: its tokens are consumers, never dependencies (decisions FR-056). | doc/specs/_template.md; shared-types-and-ownership.md FR-014 | happy |

### 4.7 Specification checks (shared-types-and-ownership.md)

The decisions bind specs, not only code (`shared-types-and-ownership.md`
FR-013). These checks read `doc/specs/*.md` (files not starting with `_`) and
parse headers per FR-094. They are checks (FR-005), run on the real
repository, and sit in `test/architecture/checks/spec_conformance.dart`.

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-088 | A spec MUST contain, in order, exactly the ten level-2 headings of the template: `1. Purpose and scope`, `2. Source`, `3. Vocabulary`, `4. Requirements`, `5. Model`, `6. Interface`, `7. Observability`, `8. Test plan`, `9. Open questions and decisions`, `10. Changelog impact`; and a header table with the rows Status, Context, Roadmap phase and Depends on. Context MUST be a backticked `package`, `shared_kernel`, `shared_ports`, `testing` or a context in the map (FR-022). | doc/specs/_template.md | unhappy (missing content) |
| FR-089 | Every file name in a spec's Depends on (FR-094) MUST exist in `doc/specs/`, MUST NOT be the spec itself, and the graph of all specs' Depends on edges MUST be acyclic; a Violation names the specs on the cycle. This is the cycle check of `shared-types-and-ownership.md` FR-056; FR-101 makes cycles impossible for ranked specs, and FR-089 still guards the rank-90 specs and any spec missing from the table. | shared-types-and-ownership.md FR-015, FR-016 (no cycles); FR-013 | unhappy (rule interaction) |
| FR-090 | A spec whose Context is a context (A) listing a spec whose Context is a different context (B) MUST have B upstream of A in the map (FR-022). A spec in context X MUST NOT list a spec of a context that is not upstream (forbidden edge). A `shared_kernel`, `shared_ports` or `testing` spec MAY be listed by any spec; a `shared_kernel` spec lists only `shared_kernel` specs, and a `shared_ports` spec lists only `shared_kernel` and `shared_ports` specs. A spec whose Context is `package` MAY be listed by any spec (`shared-types-and-ownership.md`, `errors-and-results.md` and this spec are `package` specs, and nearly every spec lists them); a `package` spec is constrained only by FR-089 (acyclic) and FR-092 (phase), and a `package` spec listing a context spec is not a forbidden edge. | shared-types-and-ownership.md FR-013; architecture.md §2 | unhappy (rule interaction) |
| FR-091 | In-context order is the rank table, not a copy. For two specs of the same context FR-101 already requires a strictly lower rank, so the old peer exception is gone (`feats-behaviour` and `spellcasting` are different ranks; the twelve `class-*` specs share rank 17 and so cannot list each other, and `class-wizard-evoker`, rank 18, may list `class-wizard`). | shared-types-and-ownership.md FR-015, FR-016, FR-056, 4.11 | unhappy (rule interaction) |
| FR-092 | Phase. A spec MUST list only specs whose type-phase upper bound (the end of its range, or its single integer, per FR-094; never a data phase) is at most the listing spec's lowest type phase (`shared-types-and-ownership.md` FR-014: same or earlier phase; bulk data may ship later without changing the cell). A Roadmap phase cell with no integer is a Violation. A spec of rank 90 or higher (FR-101) is exempt from this phase rule, because it lists every spec it verifies. | shared-types-and-ownership.md FR-014, FR-056 | unhappy (boundary) |
| FR-096 | Spec cross-references. In every spec (FR-094's file set), outside fenced code blocks, every spec citation MUST name an existing file in `doc/specs/` and ids that exist in that spec's requirements table (FR-071) and are not moved (FR-087). Grammar: the file token is `[a-z0-9_-]+\.md`, optionally preceded by `doc/specs/`, inside backticks, as link text or as a link target. After it, between the token and the first `FR-<n>`, only the characters `` ` `` `)` `]` `(` and spaces may stand; the id run then continues over the separators `,`, `and`, `&`, `/` and `to`, each followed by another `FR-<n>`, and ends at any other text (so in `<file> FR-005 for a, FR-034 for b` only FR-005 is cited; repeat the file name before an id that follows prose). A range `FR-a to FR-b` checks both endpoints. The pointer inside a moved-id row (section 3) is a citation like any other. A bare `FR-<n>` with no file token is local and is not checked here. A citation of a moved id is accepted only when the run is immediately followed by the moved-id suffix (section 3) and the id is in fact moved, so the statement stays true. The names in the constant `placeholderSpecNames` (`x`, `y`, `z`) are exempt: they are the fixture spec names of section 8. Mangled names are also Violations: any token matching `\b(doc-specs\|toolbox)-[a-z0-9-]+-md\b` (they mean `<x>.md` and `toolbox-<x>.md`). Test citations are FR-054, not this check. | shared-types-and-ownership.md FR-052; testing.md §5 ("keep citations true") | unhappy (missing content) |
| FR-099 | Content data specs. A spec named in the constant `dataSpecs` = {`content-thin-slice`, `content-species-backgrounds-feats`, `content-equipment`, `content-spells`, `content-monsters`, `content-classes`, `content-magic-items`} MAY list (FR-094) only `content-schema-and-decoder.md`, `content-source-port.md` and specs whose Context is `package`; any other file name in its Depends on is a Violation naming the data spec and the listed file (this includes another data spec, so FR-089's cycle check is not the only guard). A rank 7 bundle spec (`content-classes-data`; decisions FR-067) is not in `dataSpecs`: it MAY list the rank 6 data specs it validates against, and only FR-101 constrains it. The toolbox catalogues join `dataSpecs` when a `toolbox-*` spec is a pure data catalogue; no `toolbox-*` spec is in the set today because each lists use-case and rule specs (section 9). The constant only names the stems; the rule itself is not copied. A self-test fails when the FR-047 row of `shared-types-and-ownership.md` no longer contains, in backticks, each stem in `dataSpecs`, `content-schema-and-decoder` and `content-source-port`, or its FR-067 row no longer names `content-classes-data`. | shared-types-and-ownership.md FR-047, FR-067 | unhappy (rule interaction) |
| FR-100 | Header tokens only (`shared-types-and-ownership.md` FR-056). A token matches `` `[a-z0-9-]+\.md` ``, and tokens are separated by a comma and optional spaces. The Depends on cell, after removing every `` `name.md` `` token, commas and spaces, MUST be empty or `none`; a link, prose, a bare file name, an FR id or a parenthesis left over is a Violation naming the leftover text. Listing `shared-types-and-ownership.md` is allowed and not required. Consumers are not listed; the check cannot see intent, so it relies on FR-101 and FR-089. | shared-types-and-ownership.md FR-056 | unhappy (invalid input) |
| FR-101 | Rank rule. The rank table is parsed from section 4.11 of `shared-types-and-ownership.md` (rows `\| <integer> \| `a`, `b` \|`; the header row and any row whose first cell is not an integer are skipped), never copied. Ranks are arbitrary integers and only their order counts: the table has gaps and several specs per rank (the twelve `class-*` specs share rank 17; `class-wizard-evoker` is 18; `spell-effect-data` and `content-classes-data` are 7; `equipment-rules` is 9; `telepathy` and `grappling` are 23; `returning-to-life` and `spell-effects` are 27). A spec absent from the table is a Violation (a new spec needs a rank in the same change), as is a table name with no file or a name listed under two ranks. For a spec of rank below 90, every Depends on token other than `shared-types-and-ownership.md` (rank 0, always allowed, need not be listed) MUST name a spec of strictly lower rank; an equal or higher rank is a Violation naming both ranks. A spec of rank 90 or higher MAY list any spec; this spec is rank 90 and lists every spec it verifies as tokens (FR-061 of the decisions), and the rank-91 and rank-99 specs are not listed here, so no cycle. Because ranks strictly decrease along every edge, a cycle among ranked specs below 90 cannot exist; FR-089 reports the cycle if one appears through a rank-90 spec. The threshold 90 is a named constant (FR-009). A self-test fails when the decisions spec no longer has a table with a `Rank` header, or when the parse of the real table does not give `spell-effect-data` 7, `equipment-rules` 9, `higher-level-start-equipment-and-trinkets` 15, `class-wizard` 17, `class-wizard-evoker` 18, `telepathy` 23 and `returning-to-life` 27 (multi-name cells and gaps parse). | shared-types-and-ownership.md FR-056, FR-061, 4.11 | unhappy (rule interaction) |
| FR-102 | Documentation index. The file `doc/documentation_index.md` (named constant `documentationIndexPath`, FR-009) MUST be present and hold a table whose header cells are, in order, `File`, `Summary`, `Read when`; each data row's first cell is one backticked path relative to `doc/`, and no path appears twice. (a) Every `doc/specs/*.md` file in the SourceSet, `_template.md` included, MUST have a row `specs/<name>.md`; a spec file with no row is a Violation naming the file, at the line of the table header. (b) Every row's path MUST name a file of the SourceSet under `doc/`; a row for a deleted, renamed or never-created file is a Violation at the row's line. (c) A missing index, another header, a first cell that is not one backticked path and a duplicate path are Violations. Only the presence and validity of rows is checked; summaries and triggers are reviewed under the index's own rules. | `doc/documentation_index.md` ("One row per file under `doc/`"; no row for a file that does not exist); shared-types-and-ownership.md FR-052 | unhappy (missing content) |

### 4.8 Withdrawn ids

| Id | Requirement |
|---|---|
| none | No id is withdrawn today (FR-087 defines the form). |

## 5. Model

- **Test support** (`test/architecture/support/`): `SourceSet` (FR-002, FR-010;
  the loader does all I/O), `Directive` (kind, URI, resolved path, line),
  `Violation`, `ContextMap` (parsed per FR-022), `SignalConstant` (identifier,
  value, kind, defining file, line), `CatalogueRow` (seven cells, line),
  `SpecHeader` (FR-094), `RankTable` (FR-101) and `Exported` (FR-093).
- **Checks** live in `test/architecture/checks/` as `List<Violation>
  check(SourceSet)`; each has a `*_test.dart` on the real repository and a
  `*_self_test.dart` on fixtures (FR-005).
- **Registry.** `checks/registry.dart` is a constant map from check id to
  function (several ids may share one). The FR-005 meta-test compares this
  spec's ids with its keys. Other specs' checks are not registered (section 9).
- **Lexer.** A hand-written scanner returns what FR-063 lists. No
  `package:analyzer` (a new dependency, slow). Its cases are self-tests under
  FR-008.
- **Invariants:** a SourceSet is built once per test file and never mutated;
  paths use `/`; violations are sorted before reporting (FR-011).
- **Failures:** violations are test failures, not `Srd5eException`s. A helper
  given a malformed fixture throws `ArgumentError` (`architecture.md` §6). A
  missing package root fails the test (FR-001).
- **Constants** (support code; each constant that copies a decision has a
  self-test that fails when its source text no longer contains it, FR-079 (c),
  FR-085 (c), FR-098, FR-099): the platform entry-point set (empty), the exempt
  paths of FR-026, the SDK denylist, the dependency allowlist (FR-083), the
  generic variant names (FR-077), the double prefixes (FR-081), `portHandles`
  (`Span`, `Counter`, `Histogram`, `Gauge`, FR-082), the reserved attribute
  keys (`error.type`), the shared attribute value sets (FR-085),
  `noticeCoveredPaths` (FR-079), `leafContexts` (FR-098), `placeholderSpecNames`
  (FR-096), `dataSpecs` (FR-099), `documentationIndexPath` (FR-102), the SourceSet excluded paths (FR-002), the
  rank-90 threshold (FR-101), and the consumer-name denylist assembled from
  fragments so no file names a consumer. The context map and rank table are
  parsed, not constants (FR-022, FR-101).
- **Embedded content generator.** FR-078 takes the generator's pure function as
  a parameter; fixtures pass a stub, and the real-repository test passes `null`
  until the change that adds `tool/generate_embedded_data.dart` imports it
  (tests may import `tool/`; `lib/` may not, FR-076).

## 6. Interface

- No `lib/` change: nothing is exported from `lib/srd5e.dart`. No new
  `pubspec.yaml` dependency: the suite uses `dart:io` and `package:test` only,
  and parses Markdown tables and the `dependencies:` block line by line. One
  requirement lands on `tool/`: the generator MUST expose the pure function
  FR-078 takes (the spec that defines it owns its shape), and the change that
  adds it MUST wire it into FR-078's real-repository test.
- Files: `test/architecture/support/{catalogue,constants,context_map,declarations,directives,exception_registry,exports,gitignore,lexer,markdown_tables,names,package_root,rank_table,real_repository,reporting,signal_constants,source_set,spec_header,spec_ids,test_scan,use_case_spec_baseline,violation}.dart`
  (each has a `_test.dart` except `exception_registry`, `package_root`,
  `real_repository`, `use_case_spec_baseline` and `violation`, which are
  exercised through the checks); `test/architecture/checks/registry.dart` (with
  `registry_test.dart` only);
  `test/architecture/checks/{ability_conventions,attribute_values,banned_calls,barrel_scan,consumer_names,context_map,dice_conventions,domain_observability,domain_purity,embedded_content,error_conventions,harness_guards,layering,lib_boundaries,modifier_conventions,noop_classes,notice_paths,observability_sdk,package_dependencies,platform_imports,rule_tags,shared_modules,signal_catalogue,signal_constants,spec_conformance,test_citations,test_hygiene,testing_layer,timeout_budget,use_case_calls}.dart`
  with a `_test.dart` and `_self_test.dart` each. Three test files have no
  implementation file of their own: `empty_repository_test.dart` (the FR-058
  fixture through every check), `import_legality_self_test.dart` (the section
  4.5 rows, which span several checks) and `dice_entry_points_self_test.dart`
  (the entry-point fixtures of `dice_conventions`).
- Everything is synchronous; no ports, so no port failure contract and no
  double. Run with the Docker command in `AGENTS.md`; each real-repository
  group MUST finish in under 10 seconds (FR-073).

## 7. Observability

Silent by design: test code run in development and CI, never inside a
consumer's process, so no use case, port or adapter to instrument. It owns no
signal; `doc/observability/signals.md` gets no entry from this spec. It enforces
the rules for everyone else's signals (FR-032 to FR-048, FR-084, FR-085).

Evaluation: (1) what can go wrong is a vacuous, loose or drifting check
(FR-001, FR-005, FR-012, FR-021, FR-022); (2) an operator sees `path:line`,
check id and detail (FR-004), and a vacuous pass is exposed by FR-005 and
FR-012; (3) diagnosis needs only that line and the requirement id; (4) nothing
is counted in-package, and FR-073 budgets each real-repository group at 10
seconds; (5) there is no existing instrumentation, and the value sets FR-085
checks are fixed in decisions FR-041; (6) a failing `test/architecture` CI job
MUST block merge, maintainers watch suite duration (SourceSet growth, a
quadratic check), a rule change must update its guardrail test (`testing.md`
§9) and reviewers check the reverse; (7) nothing is noisy, since reports list
only violations.

## 8. Test plan

Check ids are verified at level `architecture`: the check on the real
repository plus a self-test with fixtures (FR-005). Support code (lexer, directive
extraction, loop recognition, citation and table parsers) is tested at level
`unit` in `test/architecture/support/` (`testing.md` §3). Guardrail tests are
exempt from FR-049 only (`testing.md` §9) and MUST cite this spec like any other
test (`testing.md` §5); FR-055 applies once this spec is `implemented`.

| Ids | Level | Notes |
|---|---|---|
| FR-001, FR-012 | architecture | Fixture roots: no pubspec, wrong `name`, missing `lib/srd5e.dart`. |
| FR-002, FR-010 | architecture | Temp-dir fixture with excluded `coverage/`, `.mutate4dart/`, `.git/`, `.idea/`, `.vscode/`, a `pubspec.lock`, `.DS_Store`, `x.dart.swp`, `x.dart~` (all absent from the SourceSet); a binary file (path in `binaryPaths`, content unread); a `tool/x.dart` and `.github/` file; a non-UTF-8 file (in `unreadable`, one FR-010 Violation). |
| FR-003, FR-004, FR-005, FR-059 | architecture | A fixture with three violations: all three lines, sorted. Meta-test: read ids from the spec tables (FR-071 parser), look each up in the registry, assert a violating fixture yields that id; a registry missing an id, and an id with a clean-only fixture, both fail. |
| FR-006, FR-007, FR-060, FR-064, FR-065 | architecture, unit (support) | Directive cases: multi-line, `show`, `deferred as`, conditional, `part`, relative `../`, `package:srd5e/`, an existing `../tool/x.dart` (resolves), an unresolved `../nope.dart` (FR-007), a commented `// import 'dart:io';` (no edge). |
| FR-008, FR-009, FR-063 | architecture, unit (support) | Lexer cases (comment kinds and lines, literal list, brace matching); banned token in a comment, string, raw string, interpolation; `// ignore: ...` next to a violation still reports. |
| FR-011 | architecture | Each check twice on a shuffled SourceSet; equal output. |
| FR-013 to FR-019, FR-023, FR-024, FR-061, FR-062, FR-067, FR-074 to FR-076, FR-080, FR-095, FR-097 | architecture, unit (support) | Rows of section 4.5, table-driven, one test per row. Plus reachability graphs (a core entry point reaches the file; only `lib/io.dart` reaches it; no entry point reaches it); `flutter_test`, `dart:ui`, `dart:io` in each core entry point; token fixtures `FutureOr`, `async*`, `Futures` (no match); `shared_ports` importing `shared_ports/adapters/`; `shared_ports/adapters` to its port (allowed) and to a context barrel (FR-024); a relative `../tool/x.dart` and a `package:srd5e/src/testing/x.dart` each reported. FR-097: two use cases in separate files, one mentioning the other (Violation, at the mention); the same in a `domain/` file (Violation); a `domain/` service mentioned from a use case (clean); a mention in a comment or string (clean, FR-008); a `Command`/`Result` type of another use case (clean, no `call`); a mention in `test/` (clean); a helper in `application/` with a public `call` (a use case class, so a mention is a Violation). |
| FR-020, FR-021, FR-022, FR-098 | architecture | Cycles (A to B to A, self-edge, three-cycle, `content` listing `toolbox` upstream), unmapped folder, a `toolbox` folder (accepted), loose file in `lib/src/`, planned context without folder, `lib/src/testing/` (not a context). Real run parses `architecture.md` and `AGENTS.md`; fixtures: other header, a cell without backticks, a context in `AGENTS.md` missing from the table. FR-098: `toolbox` with four upstreams and nobody listing it (clean); `character` listing `toolbox`; `toolbox` listing an unknown context; `toolbox` listing itself (FR-020 also); no `toolbox` (vacuous); self-test that the decisions spec FR-045 row still contains `toolbox`. |
| FR-077, FR-093 | architecture, unit (support) | `Applied` and `NotFound` exported (a); two files declaring `Damage` exported through two barrels (b); the same declaration re-exported twice (clean); a name hidden by `hide` or left out by `show` (clean); an export chain two files deep; a private `_Applied` (clean). |
| FR-078 | architecture | Stub generator: identical output (clean), one differing byte, a missing library, an extra library, no `data/` at all (vacuous); a `null` generator with libraries present (vacuous). The real test passes `null` until `tool/generate_embedded_data.dart` exists. |
| FR-079 | architecture | NOTICE with content present: Scope listing exactly the three paths (clean), a missing path, an extra `docs/`, a path without trailing `/` (counts as missing), tokens outside Scope (ignored), no content (vacuous), no `NOTICE.md` (no Violation here). `.pubignore` with `doc/research/` present: `doc/` (clean, parent excluded), `doc/research/` (clean), `doc/*` then `!doc/research/` (Violation), no `.pubignore` (Violation), no `doc/research/` files (vacuous). Self-test: the constant equals the backticked path tokens in the first sentence of the FR-033 row of the decisions spec. |
| FR-081, FR-082, FR-083, FR-084 | architecture | A `FakeX implements XPort` outside `lib/src/testing/` (FR-081); a port with no double, a double not exported by `lib/testing.dart`, a port with no `test/contract/` file (FR-082); `Span`, `Counter`, `Histogram`, `Gauge` in `shared_ports/observability/` with no double or contract (clean, `portHandles`) and a `FakeSpan implements Span` outside `lib/src/testing/` (clean); no ports (vacuous). Pubspec: `collection` and `meta` only (clean); `http`, `path`, `logging` under `dependencies:`; the same under `dev_dependencies:` (clean). `NoopLogger` with a `const` constructor under `shared_ports/` (clean); non-const; mixed; the same class under `shared_ports/adapters/` and `d20_test/application/`; a class with no explicit constructor (Violation). |
| FR-025, FR-026, FR-068, FR-069, FR-027, FR-028 | architecture | Denylist fragments joined at run time; the name in a comment, a string, a file path, other case and separators; `pubspec.yaml` `repository:` line, `AGENTS.md`, `CLAUDE.md` exempt; the name in `.github/workflows/ci.yml` and `tool/x.dart` reported; the denylist source scanned for plain text. `Random(5)`, `Random.secure()`, `DateTime.now`, `Stopwatch()..start()`, `print('x')` vs `logger.print(x)` (allowed), `'print('` in a string (allowed). |
| FR-103, FR-104 | architecture | FR-103: `Random(`, `Random.secure(`, `DateTime.now(`, `DateTime.timestamp(`, `Stopwatch(` in `shared_ports/`, in `shared_ports/adapters/` and in a no-op file (each a Violation), the same text in a comment or string (clean, FR-008), a `domain/` hit still reported by FR-027 only. FR-104: both classes `final` in one file (clean); `Observability` not `final`; `NoopObservability` in another file; `NoopObservability` with a non-`const` constructor (FR-084 also fires); `@immutable` missing. |
| FR-029, FR-030, FR-031 | architecture | Zero tags, two tags, malformed hex, tag copied into README and into its own file twice, unlisted rule file, listed missing file. Real run reads the three real rule files. |
| FR-032, FR-033, FR-034, FR-035 | architecture | Imports `package:sentry_flutter`, `package:logging/logging.dart`, `dart:developer`; pubspec with each package under `dependencies:` and `dev_dependencies:`. Identifiers `NoopLogger` (match), `Parameter` (no match); `static final`, top-level `final`, `const` default (allowed). |
| FR-036 to FR-040, FR-072 | architecture | The same literal under `test/` passes (FR-072). Constants-file fixtures (each a `static const String` in an `abstract final class XSignals`): `contentSetLoadedLogEvent = 'content set loaded'` (valid; a fixture message only) and `content.set.loaded` or `Content set` (FR-038); literal at a call site; interpolated name; unsuffixed member (FR-037); wrong context segment; uppercase; duplicate value; signal constant in `shared_ports/`. An attribute constant `'Outcome'` or `'outcome'` with no `srd5e.` prefix, and a `*Attribute` member with an uppercase segment (FR-039). `AttributeKeys` with `outcome = 'srd5e.outcome'`, `errorType = 'error.type'` and no suffix (clean), the same literals in any other file (FR-036), a top-level `const String` in a constants file, a `*Signals` class outside a constants file (FR-037). |
| FR-041 to FR-048 | architecture | Catalogue: empty table (valid), extra column, short row, name only in code, name only in catalogue, duplicate row; cells empty, whitespace, `TODO`, `n/a`; wrong Type word; lower-case `span` and `counter, unit {test}` (valid); Type vs suffix mismatch; attribute only in code; attribute only in catalogue. |
| FR-085 | architecture, unit (support) | Code: `outcomeSuccessValue = 'success'` with the key in its doc comment (clean), `'miss'`, `'neither'` for roll mode, `'critical_hit'` for `srd5e.outcome`, a value with no key in its comment, `error.type` value `dice_roller_exception` against a `Srd5eException` subtype `DiceRollerException` (clean) and against a non-subtype `DiceRoller` (Violation). Catalogue: `` `srd5e.outcome` (`success`, `failure`) `` clean; `` (`success`, `hit`) `` Violation. The self-test deletes one value from a copy of `observability.md` §5 and fails. |
| FR-049 to FR-054, FR-057, FR-066, FR-086 | architecture, unit (support) | The cases table below; `// test('x', ...)` commented out; `skip: true` without and with an `Issue:` line; `skip: 'reason'` with an empty `Issue:`. |
| FR-055, FR-056, FR-070, FR-071, FR-087 | architecture, unit (support) | Fixture specs: `implemented` with an uncited id, unknown file, unknown id, bad status; an id cited only in a table row's `requirement:` field (covered); a continuation-line citation; several ids in one citation; a range (FR-054); an id listed `Deliberately not covered: FR-3 - reason` (accepted); a 4.5-style table whose first cell is a label (not an id). FR-087 is a support rule, so its fixture expects FR-054: a spec with a moved-id row cited by a test (Violation), uncited under `implemented` (clean), skipped by the FR-005 meta-test. Real run covers the actual `doc/specs/`. |
| FR-088 to FR-092, FR-094, FR-099 to FR-101 | architecture, unit (support) | Data spec (`content-equipment`) listing `content-schema-and-decoder.md`, `content-source-port.md` and a `package` spec (clean), another data spec (Violation), a non-package spec such as `shared_ports` (Violation); a non-data spec listing a data spec (clean); self-test that the FR-047 row of the decisions spec still names each `dataSpecs` stem. Header cell with prose, a link, a bare file name or an FR id (FR-100 Violation) vs only tokens (clean). a rank-90 phase-0 spec listing a phase-4 spec (clean, FR-092 exemption); Rank-4 spec listing a rank-4 and a rank-5 spec (FR-101), rank-5 listing rank-4 (clean), a spec missing from the table (FR-101), a rank-90 spec listing rank-1 and rank-60 specs (clean). Missing or reordered heading; missing header row; Depends on naming a missing file, itself, a two-spec cycle. `combat` listing `character` and `character` listing `combat` (forbidden edge); a `content` spec listing `shared-types-and-ownership.md` (clean); `conditions` listing `attacks` (FR-101), `attacks` listing `conditions` (clean); a `class-*` listing `spellcasting` (clean), `spellcasting` listing a `class-*` (Violation), two `class-*` listing each other (FR-101). Ranks of table 4.11 with gaps: `class-wizard-evoker` (18) listing `class-wizard` (17) clean, `class-wizard` listing it Violation; `content-classes-data` (7) listing a rank 6 data spec clean, a rank 6 data spec listing another rank 6 spec Violation (FR-099 and FR-101); `equipment-rules` (9) listing `content-equipment` (6) clean; `higher-level-start-equipment-and-trinkets` (15) listing `level-advancement-and-multiclassing` (14) clean and `feats-behaviour` (15) Violation; `telepathy` (23) listing `conditions` (22) clean and `grappling` (23) Violation; `readying-a-spell` (26) listing `initiative-and-actions` (25) clean; `returning-to-life` (27) listing `magical-effects` (26) clean and `spell-effects` (27) Violation; a `Consumed by` header row naming a higher-rank spec (ignored, clean); a spec listed under two ranks; a table name with no file. Phase `0` parsed as 0, `3-4` as 3 and 4, `Types 2; bulk data 5` as 2 (a phase-3 spec listing it is clean), `3 for the Armor...; 5 for the rest` as 3; phase-2 listing phase-2 (clean); phase-0 listing phase-1 (Violation); phase-3 listing a `3-4` spec (Violation); a cell with no integer; `none. ... foo.md ...` as no dependencies. Real run covers the actual `doc/specs/`. |
| FR-102 | architecture | Index fixtures: every spec file has a row (clean); a spec file with no row, as when a new spec is added without its row (Violation naming it); a row `specs/gone.md` for a missing file (Violation at the row); a row for an existing non-spec file such as `rules/testing.md` (clean); a duplicate path; another header; a first cell without backticks; no index at all. The real run reads the repository's index. |
| FR-096 | architecture, unit (support) | `x.md` placeholder (clean); a citation of a missing file; of a missing id; of a moved id (Violation) and the same followed by the suffix (clean when it is moved, Violation when not); a range whose end is moved; ids joined by `and` and `&`; prose after the first id (second unchecked); a fenced block (ignored); a spec name with its final dot turned into a hyphen under the `doc-specs` and `toolbox` prefixes (mangled Violations; assembled at run time so this spec stays clean); a moved-id row's pointer to another moved id. The real run MUST pass before a spec change is accepted (decisions FR-052). |
| FR-058, FR-073 | architecture | The FR-058 fixture through every check yields zero Violations, with the FR-078 generator `null`. Each real-repository group declares the 10 second `Timeout`; a fixture asserts the declaration is present on every group (per-group budget only). |

Cases for FR-049 to FR-053 (table-driven in the self-test):

| Label | Fixture | Expected |
|---|---|---|
| comment directly above | `/// Requirement: ...` then `/// Path: happy` then `test(` | none |
| blank line between | comment, blank line, `test(` | FR-049 |
| `Rule:` instead | `/// Rule: ...` plus `Path:` | none |
| none with reason | `Requirement: none - pins current behaviour` | none |
| none bare | `Requirement: none` | FR-050 |
| test in loop, loop commented | `Requirement: per case`, `Path: per case`, `for` containing `test(` | none |
| test in loop, loop uncommented | `for` containing `test(` | FR-049 |
| loop comment not per case | `Requirement: x` (not `per case`) above a `for` containing `test(` | FR-051 |
| per case on plain test | `Requirement: per case` above a `test(` outside loops | FR-052 |
| per case path mismatch | `Requirement: x`, `Path: per case` | FR-053 |
| empty unhappy kind | `Path: unhappy ()` | FR-053 |
| tooling method | `helper.test(` | none (FR-057) |
| per case on a group | `Requirement: per case`, `Path: per case` above `group(` whose body has a `for` with an uncommented `test(` | none |
| per case on a group without a loop | same comment above a `group(` with plain tests | FR-052 |
| `forEach` loop | `Requirement: per case` above `cases.forEach((c) { test(...) })` | none |
| `map` loop | same above `cases.map((c) => test(...))` | none |
| unsupported generator | `List.generate(3, (i) => test(...))` with comment only above the call | FR-049 |
| table-row citation | `for` with per case comment and a row whose `requirement:` field cites FR-2 of the placeholder spec, FR-2 exists | none |
| table-row unknown id | row cites FR-99 of the placeholder spec | FR-054 |
| several ids | `Requirement:` citing FR-1 and FR-2 of the placeholder spec | none |
| range | `Requirement:` citing the range FR-1 to FR-3 of the placeholder spec | FR-054 |
| continuation line | id on a `///   ` line | none |
| `none` without `Path:` | `Requirement: none - reason` only | FR-053 |

Mutation-testing scope: none (section 1).

Deliberately not covered: none.

## 9. Open questions and decisions

Settled (one line each; the rationale is kept here because Source cells point at it):

| Decision | Outcome |
|---|---|
| Rule-file tag replaced on edit? | Decided: a CI step outside the unit tests, because it needs git history; out of scope for this spec. |
| FR-073 loading budget with all data in every SourceSet | Decided: keep the 10 second per-group budget; if bulk data pushes a group over it, the loader reads lazily per path prefix (signatures stay pure). Trigger: the first bulk-data change whose real-repository group exceeds 5 seconds on CI. |
| Signal and attribute constants | `static const String` members of `<X>Signals` in an `application/*signals.dart` file; shared keys are `AttributeKeys` in `shared_ports/signals.dart`; this follows the existing use-case specs (`resolve-d20-test-use-case.md` FR-040, `combat-foundations.md` FR-027, `observability-ports.md` FR-052). Kind is told by the member suffix (FR-037). |
| Log event | The constant message (`observability-ports.md` FR-002); lowercase pattern, not dotted (FR-038). No event-name field on the port. |
| Which interfaces in `shared_ports/` are not driven ports? | The handles in `portHandles` (FR-082; `observability-ports.md` FR-065). `release-0-1-0.md` FR-084 takes its port definition from FR-082 and applies `portHandles` too. |
| Who owns the dependency allowlist? | FR-083 here. `release-0-1-0.md` FR-060 cites FR-083 and adds only the caret, override and `path:`/`git:` rules. |
| Do the current data-spec headers pass FR-099 (decisions FR-047)? | Yes: every spec in `dataSpecs` lists only `content-schema-and-decoder.md`, `content-source-port.md` and, where used, the package-context `errors-and-results.md`; the kernel types they use are reached through the decoder spec. Toolbox catalogues join `dataSpecs` when a `toolbox-*` spec is pure data. |
| Does the documentation index have rows for every spec? | Yes: every file in `doc/specs/` has a row in `doc/documentation_index.md` and no row names a missing file, so FR-102's real run passes. |
| Lexer vs `package:analyzer` | Hand-written lexer plus self-tests; revisit if a check needs types. |
| Beyond the rule text (FR-013, FR-015, FR-016, FR-032, FR-076, FR-082 to FR-084) | `dart:developer`, `dart:async`, `FutureOr`, `Completer`, `flutter_*` and the extra SDK package names close obvious bypasses; Source cells say "package design". |
| Call-site string literals (`Meter`, `Tracer`, `Logger`, attribute values) | Not checkable without types; the recording-double tests that pin names (`observability.md` §9) catch them. |
| Registering other specs' checks (E1 to E6, R-1, R-4, Q-13, Q-17) | R-1, E1 to E6, Q-13, Q-17 declined: FR-005 ids would collide and each spec has its own self-test duty (`testing.md` §8). R-2 accepted (`binaryPaths`, FR-002); R-4 accepted (FR-068); R-3 met by FR-079. Those specs must not claim registry slots. |

Other decisions are recorded in the decisions spec: ownership of FR-079 (FR-050) and FR-078 (FR-048), toolbox leaf (FR-045), use-case rule (FR-044), rank table (FR-056), citations (FR-052), port doubles and contract suites (FR-038, FR-039).

## 10. Changelog impact

None. Test and tooling only: no user-visible, API or signal change. Not
**BREAKING**.
