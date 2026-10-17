# srd5e Roadmap

Status: proposed. Phases are ordered by the context map in
[rules/architecture.md](rules/architecture.md) §2, which is itself provisional.
Each phase is a vertical slice that ships tested, instrumented, documented
code, not a layer built in isolation.

[specs/shared-types-and-ownership.md](specs/shared-types-and-ownership.md) is
binding on every phase: it settles type ownership, dependency order and
content delivery, and wins over any other spec.

Every phase follows the process rules in `AGENTS.md`: a spec first, then the
`Testing` and `Observability` evaluations
([rules/testing.md](rules/testing.md) §2,
[rules/observability.md](rules/observability.md) §2), then a `CHANGELOG.md`
entry.

## Phase 0: Foundation (no game rules yet)

- `shared_kernel`: dice expressions and roll results, `Modifier`,
  `Advantage` / `Disadvantage`, `AbilityScore`, typed ids.
- `shared_ports`: `DiceRoller` and `Observability` (`Logger`, `Tracer`,
  `Meter`) with `const` no-op defaults in the port library, and the generic
  `SeededDiceRoller` in `shared_ports/adapters/`.
- `lib/src/testing/` and `lib/testing.dart`: fixed roller and recording
  observability doubles (all doubles live in `lib/src/testing/`).
- `test/architecture/`: every guardrail from architecture §9 and
  observability §10 that can apply to the code present. The bootstrap rule
  requires the first code under `lib/src/` to add these.
- `doc/observability/signals.md`, the base (not sealed) `Srd5eException`
  hierarchy, and a CI job for mutation testing.

**Outcome:** the rules are enforced by tests before any real logic exists.

**Status: done (2026-10-09).** The six Phase 0 specs (`errors-and-results`,
`dice-and-rolls`, `modifiers-and-advantage`, `ability-scores`,
`observability-ports`, `architecture-guardrails`) are `implemented` and pass
the FR-055 coverage check; the guardrail suite, the mutation CI job and the
empty signal catalogue are in place.

## Phase 1: `d20_test` context

No upstream dependencies, and the core of the ruleset.

- Ability checks, saving throws, attack rolls, DCs, Advantage and
  Disadvantage, success and failure resolution.
- The first use case, with command and result types, telemetry, table-driven
  unit tests and a first scenario test.
- Treat it as the reference implementation that later contexts copy.

## Phase 2: `content` context

- `ContentSource` port with a sealed `ContentLookup` result.
- JSON decoder reporting all problems at once, an in-memory source, and a
  shared contract suite.
- `content` owns every closed SRD vocabulary type and typed id
  (`DamageType`, `ConditionKind`, `Skill`, `ClassId`, ...), so `character` and
  `combat` import them from here.
- A thin slice of bundled SRD data (a few species, one class, a few spells) to
  validate the schema before bulk entry. This adds `NOTICE.md` coverage for the
  bundled content directories.
- `lib/adapters.dart` entry point, exporting `BundledContentSource`.

**Settled:** bundled data is JSON under `data/srd_5_2_1/` (source of truth); a
generator in `tool/` writes committed embedded Dart libraries of raw JSON
strings under `lib/src/content/data/`; one decoder serves bundled and
host-supplied JSON; a drift test regenerates and fails on any diff
(shared-types-and-ownership.md FR-030 to FR-032).

**Status: done (2026-10-17).** All eleven PRs of
[plans/plan-phase-2.md](plans/plan-phase-2.md) are in: the `content` context
(identity types, vocabulary, typed ids, entry types, decoder, `LoadContentSet`
with its six signals, the generator with its drift check, the `ContentSource`
port with its adapters, doubles and contract suites), the `CLN-` licensing
checks with `NOTICE.md` activated, and the thin slice of bundled SRD 5.2.1
data (four species, the Wizard, twelve spells in three documents) with its
oracle fixtures, data pins, telemetry pin and scenario. The four content specs
(`content-schema-and-decoder`, `content-source-port`,
`content-licensing-and-notice`, `content-thin-slice`) are `implemented` and
pass the FR-055 coverage check. Verbatim fidelity of the bundled texts to the
PDF (content-thin-slice.md FR-079) is recorded for human review in the PR
checklist.

## Phase 3: `character` context

- Ability modifiers, Proficiency Bonus, level, derived stats (AC, HP, saves,
  skills) and the character aggregate.
- Spellcasting after the basics.
- Level-up and class features, one class at a time. Each class's **data**
  (`ClassDefinition`, progression, features, subclasses; spec
  `content-classes.md`) ships in this phase together with its behaviour spec
  (`class-*.md`), not in Phase 5.
- Species trait behaviour (`species-trait-behaviour.md`): choices, limited
  uses and declared effects of the nine species.
- Spell Scroll use (`spell-scroll-use.md`, rank 15): reading and casting from a
  Spell Scroll, shared with the Rogue and Wizard class specs.
- Magic item effects (`magic-item-effects.md`): typed numeric effects of the
  SRD magic items (bonus items, set ability scores, potions, charged spell
  items, Ring of Spell Storing, extradimensional containers), beside
  `magic-item-rules.md`.

**Type-phase rule (FR-014):** a spec's *types* ship in its context's phase and
bulk *data* may ship later. A spec may depend only on specs whose types ship in
the same or an earlier phase: shared and `d20_test` types in Phases 0 and 1,
`content` types and vocabulary in 2, `character` in 3, `combat` in 4, `toolbox`
types (after `combat`'s), bulk data and release in 5.

## Phase 4: `combat` context

Suggested order:

1. Hit points and damage.
2. Attacks (reusing `d20_test`).
3. Conditions.
4. Initiative and actions.
5. The encounter aggregate.

Domain events such as `DamageTaken` and `ConditionApplied` matter most here.

Monster abilities that need the `combat` types ship here too: limited use
(`monster-limited-use.md`, rank 26) and monster spellcasting
(`monster-spellcasting.md`, rank 27, SRD p. 257).

## Phase 5: Breadth and release

- Remaining bulk data: spells, equipment, monsters and magic items from the
  SRD. (Class data is delivered in Phase 3.)
- Magic Items, the Gameplay Toolbox and the Rules Glossary are in scope, each
  with its own spec before any code: magic items as a `content` kind (SRD
  5.2.1, pp. 204-253), the Gameplay Toolbox (pp. 192-203) as the `toolbox`
  context, and the Rules Glossary (pp. 176-191) as the reference for terms the
  other specs cite. They land in the phase of the context they belong to, under
  the same type-phase rule.
- `toolbox` context (shared-types-and-ownership.md FR-045): downstream of
  `content`, `d20_test`, `character` and `combat`, with nothing depending on it.
  Its types ship in this phase, after `combat`'s. It hands results to the host
  (an Exhaustion level, a condition to apply) and mutates no character or
  combat state. Named catalogue entries (poisons, traps, contagions) are
  content kinds.
- `RuleOptions` for the optional rules the SRD itself names.
- Examples in `example/`, including observability bridge examples.
- Tag 0.1.0 and publish.

## Planning notes

1. **Specs first.** Tests must cite requirement ids, so every unit of work has
   a spec in `doc/specs/` (SRD sections and pages, plus FR-ids) before it is
   coded, in `_template.md` shape. Every unit of work now has a spec: the
   foundation, content, character, combat and `toolbox` specs, the class
   behaviour specs, the Rules Glossary coverage table and the spell, monster,
   magic item, summoned creature and grid specs added by the later reconciliation
   passes (listed in [documentation_index.md](documentation_index.md)). All of
   them except the Phase 0 specs and the accepted decisions spec are drafts.
   The remaining work is implementation, phase by phase, each spec flipping to
   `implemented` in the change that ships it. New gaps found while coding get a new spec or a new
   requirement id (never a renumbering), with its rank in
   `shared-types-and-ownership.md` section 4.11.
2. **One plan per phase,** sized to a reviewable PR sequence.
3. **Revisit the context map early.** For example, does `character` need
   `d20_test` upstream, or only `shared_kernel`? Changing the map means
   updating the architecture table, `AGENTS.md` and the architecture tests
   together.
4. **Content volume is the biggest risk.** Transcribing SRD content faithfully
   is the largest workload. The data format and delivery are settled (Phase 2,
   FR-030 to FR-034); scale up only through that path.
5. **Start with Phases 0 and 1 together,** since Phase 0 has no value on its
   own.
