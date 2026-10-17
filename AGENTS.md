# srd5e — contributor/agent rules

Pure-Dart implementation of the fifth-edition rules in System Reference
Document 5.2.1, shared by multiple projects.

## Read the rules first

Before doing anything else on a task, read each of these files in full and
quote the `RULE-TAG` from the "Read receipt" at the end of each, verbatim, in
your first message:

- `doc/rules/architecture.md`
- `doc/rules/observability.md`
- `doc/rules/testing.md`

Format: `Rule tags: architecture=<tag>, observability=<tag>, testing=<tag>`

The tags are only in the files. Do not guess or reuse one from memory. A wrong
or missing tag means you did not read the file. When you edit a rule file,
replace its tag with a fresh random value; new rule files go on this list.

## Hard constraints

- **No consumer-specific code.** Nothing may reference any consuming
  project. If a consumer needs something, expose a general extension point
  instead. The one exception is the `repository` URL in `pubspec.yaml`, which
  is where this repo is hosted: the `whealinghold` GitHub organisation. It is
  not a code dependency, and nothing else may name the organisation (this
  file and the `repository` line are the only places the name may appear).
  (The split-fragment denylist in `test/architecture/support/constants.dart`
  names consumers — today only the hosting organisation, `whealinghold` —
  so the rule can be enforced; the architecture scan exempts it.)
- **Pure Dart.** No `flutter`, `dart:ui`, or other framework dependencies.
- **Public API only via the entry points** `lib/srd5e.dart`,
  `lib/adapters.dart` and `lib/testing.dart`. Implementation lives in
  `lib/src/`.
- **No third-party runtime dependencies** beyond `collection` and `meta`
  without discussion. In particular no logging, telemetry or SDK packages.
- **Never include anything outside SRD 5.2.1.** See "Licensing and source
  material" below. This applies to code, data, tests, docs, examples and
  commit messages alike.

Everything else (layering, ports, purity, errors, telemetry, tests,
versioning) is in the rule files.

`doc/specs/shared-types-and-ownership.md` is binding on every other spec and on
the code: it settles who owns each shared type, the dependency order inside
contexts, result and event naming, content delivery, and where ports, no-ops and
test doubles live. Where another spec conflicts with it, it wins and the other
spec changes.

## Licensing and source material

- **Code** is MIT-licensed (`LICENSE`).
- **Game content** comes from one source only: the **System Reference
  Document 5.2.1** (SRD 5.2.1), which Wizards of the Coast LLC provides under
  the **Creative Commons Attribution 4.0 International License** (CC-BY-4.0).
  The document is the PDF linked from `doc/research/sources.md`.
- **If it is not in that PDF, it does not go in this repository,** however
  well known it is. That excludes every other fifth-edition book, the earlier
  SRD 5.1 (a different rules edition; do not mix them), third-party and
  community material, and anything remembered from play. When something looks
  like core fifth-edition material but cannot be found in the PDF, leave it
  out and flag it in your summary.
- Cite the SRD by section and page (`SRD 5.2.1, "Damage Rolls", p. 16`).
  Where the SRD's text is reused in data, keep it faithful to the source.

### Trademarks and attribution

CC-BY-4.0 licenses the SRD's content. It does not license Wizards' trademarks.

- **Attribution** uses the statement from the SRD's own "Legal Information"
  page, verbatim, in `NOTICE.md` (and wherever the content is redistributed).
  Do not add any other attribution to Wizards or its parent or affiliates.
- The package MAY say it is "compatible with fifth edition" or "5E
  compatible" (the SRD allows exactly this). It MUST NOT use Wizards'
  trademarked names or logos as a brand, in package or identifier names, or
  imply endorsement.
- Changes to the SRD material (restructuring it into code and data) are
  indicated in `NOTICE.md`, as CC-BY-4.0 requires.

### The notice

- The notice lives in the repository root as `NOTICE.md`, next to `LICENSE`.
  It MUST state which paths it covers (the bundled game content only) and that
  the MIT `LICENSE` covers the code, so the two licences stay clearly
  distinguishable. Bundled game content lives in its own directory, separate
  from code.
- The first change that bundles any game content MUST add `NOTICE.md`, taken
  from the SRD's own "Legal Information" page. Do not write the attribution
  from memory.
- A new SRD version is a deliberate change: update the statement, the cited
  pages and `doc/research/sources.md` together.

## Reporting a change

Every PR description and every agent's final summary has a `Testing` entry
(see `doc/rules/testing.md` §2) and an `Observability` entry (see
`doc/rules/observability.md` §2). `.github/pull_request_template.md` has the
headings. User-visible changes also get a `CHANGELOG.md` entry
(`doc/rules/architecture.md` §7).

## Directory structure

```
srd5e-dart/
├── pubspec.yaml            # pure Dart; deps: collection, meta (keep minimal)
├── analysis_options.yaml   # lints/recommended + strict analyzer modes
├── CHANGELOG.md
├── NOTICE.md               # CC-BY-4.0 attribution for the bundled SRD content
├── README.md
├── CLAUDE.md               # imports this file
├── AGENTS.md               # this file
├── .github/
│   ├── workflows/ci.yml
│   └── pull_request_template.md  # Testing / Observability / Changelog headings
├── data/
│   └── srd_5_2_1/          # source-of-truth JSON content (covered by NOTICE.md)
├── tool/                   # extraction and generator scripts; never imported from lib/
├── doc/
│   ├── rules/              # normative rules (architecture, observability, testing)
│   ├── observability/      # signals.md: catalogue of every metric/span/log event
│   ├── research/           # sources.md: which document the rules come from
│   └── specs/              # one spec per unit of work; shape in _template.md
├── lib/
│   ├── srd5e.dart          # main public entry point (barrel exports)
│   ├── adapters.dart       # generic bundled adapters (SeededDiceRoller)
│   ├── testing.dart        # exports lib/src/testing/ (all test doubles)
│   └── src/                # private implementation; never import from outside the package
│       ├── shared_kernel/  # small set of concepts every context shares
│       │                   # (dice/rolls, modifiers, advantage, ability scores)
│       ├── shared_ports/   # driven ports used by several contexts
│       │                   # (DiceRoller, Observability: Logger/Tracer/Meter)
│       │   └── adapters/   # generic port implementations (SeededDiceRoller);
│       │                   # imports only shared_kernel and the port. No-ops
│       │                   # (Noop*) are const classes beside the ports, not here.
│       ├── testing/        # every test double; imported only by lib/testing.dart
│       └── <context>/      # one bounded context per folder; see below
│                           # (content/data/ holds the embedded raw-JSON libraries
│                           # generated from data/ by tool/; committed, covered
│                           # by NOTICE.md)
├── test/                   # mirrors lib/src/
│   ├── contract/           # shared port contract suites; not exported
│   ├── fixtures/srd/       # SRD text used by tests (covered by NOTICE.md)
│   ├── scenarios/          # cross-context tests via the public API only
│   └── architecture/       # tests enforcing the dependency rules
└── example/                # minimal usage examples
```

Each bounded context under `lib/src/` has the same internal shape:

```
<context>/
├── <context>.dart          # the barrel: the only file other contexts may import
├── domain/                 # entities, value objects, aggregates, events, domain services
├── application/            # use cases, commands, results
│   └── ports/              # driven-port interfaces used only by this context
└── adapters/               # port implementations, external-format decoders
```

Current contexts (provisional). Allowed dependencies between them are the
context map in `doc/rules/architecture.md` §2; change it there.

- `content/`: species, backgrounds, classes, feats, spells, equipment, monsters, and the content-source ports
- `d20_test/`: D20 Tests (ability checks, saving throws, attack rolls), DCs, Advantage and Disadvantage, success and failure resolution
- `character/`: abilities, Proficiency Bonus, level, derived stats, spellcasting, equipment rule maths (Armor Class, Carrying Capacity, crafting)
- `combat/`: initiative, actions, attacks, conditions, hit points, damage
- `toolbox/`: Gameplay Toolbox rules (travel pace, environmental effects, poison, traps, curses and contagions, fear and mental stress, XP-budget encounter planning); downstream of all the others, nothing depends on it

Update this section when the structure changes. Add new public API by
exporting it from the context's barrel and from `lib/srd5e.dart`.

## Commands (Dart is not installed locally; use Docker)

Full check, as CI runs it:

```sh
docker run --rm -v "$PWD":/app -w /app dart:stable sh -c \
  "dart pub get && dart format --set-exit-if-changed . && dart analyze --fatal-infos && dart run coverage:test_with_coverage -- --test-randomize-ordering-seed=random"
```

Coverage is written to `coverage/lcov.info`. Mutation testing (`mutate4dart`, required for changed `domain/` code) has its own command in `doc/rules/testing.md` §8.

Chrome run for the decoder tests (content-schema-and-decoder.md FR-099; the decoder tests in `test/content/adapters/` must pass on Chrome, because number handling differs on the web). Build the Chrome-capable image once, then run the web target:

```sh
docker build --rm -t srd5e-dart-chrome -f tool/docker/Dockerfile.chrome . && \
docker run --rm -v "$PWD":/app -w /app srd5e-dart-chrome sh -c \
  "dart pub get && dart test -p chrome test/content/adapters"
```
