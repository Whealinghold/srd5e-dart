# Phase 2 plan: the `content` context

| | |
|---|---|
| Status | proposed |
| Roadmap phase | 2 ([../roadmap.md](../roadmap.md)) |
| Specs flipped to `implemented` | [../specs/content-schema-and-decoder.md](../specs/content-schema-and-decoder.md), [../specs/content-source-port.md](../specs/content-source-port.md), [../specs/content-licensing-and-notice.md](../specs/content-licensing-and-notice.md), [../specs/content-thin-slice.md](../specs/content-thin-slice.md) (all draft → implemented, in the final PR) |
| Specs shipped as types only (stay draft) | content-species-backgrounds-feats, content-classes, content-spells, spell-effect-data, content-equipment (bulk data lands in phases 3 and 5) |
| Depends on | Phase 0 (done 2026-10-09): kernel, ports, doubles, guardrails. Phase 1 (merged 2026-10-11, `main`@`6bb9c74`): `d20_test`, and `ResolveD20Test` as the reference use case |

## 1. Goal

Ship the `content` bounded context as a vertical slice: the content identity
types, every closed SRD vocabulary type and typed id (so `character` and
`combat` later import them from here), the JSON envelope and its decoder that
reports every problem at once, whole-set cross-reference validation, the
`LoadContentSet` use case with its six telemetry signals, the `ContentSource`
port with the in-memory and bundled adapters, doubles and contract suites, the
embedded-data generator with its drift check, and a **self-consistent thin
slice of bundled SRD data** (4 species, the Wizard class, 12 spells — 17
entries in 3 documents) that validates the schema end to end and activates
`NOTICE.md` coverage.

Phase 2 also ships the **type and shape surface of the five kind specs the
registered envelope must decode**: species/backgrounds/feats, classes, spells
(with the `spell-effect-data` model `Spell.effects` defaults to), and
equipment's weapons/armor/cost shapes, which the baseline revision row R1
registers. Their bulk data and extraction tooling stay in phases 3 and 5.

All specs involved state no open questions; the binding decisions are
[../specs/shared-types-and-ownership.md](../specs/shared-types-and-ownership.md)
FR-030 to FR-039 (content delivery) and FR-046 to FR-067 (ownership). This
plan sequences and traces; it changes no decision. Where this plan and a spec
disagree, the spec wins and this plan changes.

## 2. What already exists (Phases 0–1, reused as-is)

| Asset | Where | Used for |
|---|---|---|
| `Ability`, `AbilityScore`, `DiceExpression`, `Die`, `Modifier`, `RollMode` | `lib/src/shared_kernel/` | vocabulary facts (`Skill.ability`), weapon damage dice, `AbilityRequirement` |
| `Srd5eException`, `wrapPortFailureAsync`, error-type registry | `lib/src/shared_ports/errors/` | `ContentSourceException`; `LoadContentSet`'s thrown-exception handling (decoder FR-086) |
| `Observability` (`Logger`/`Tracer`/`Meter`), `NoopObservability`, `AttributeKeys` | `lib/src/shared_ports/observability/` | `LoadContentSet` telemetry; shared key `srd5e.outcome` |
| `RecordingObservability`/`RecordingTracer`/`RecordingMeter` (`timedDuration`)/`RecordingLogger`, `FixedDiceRoller`, `CallbackDiceRoller` | `lib/src/testing/`, exported by `lib/testing.dart` | application tests; **Phase 2 adds two doubles** (`FakeContentSetDecoder`, `FakeContentSource`) and imports no others |
| Architecture guardrail suite (layering, context map, barrel scan, domain purity, banned calls, signal catalogue and constants, use-case calls, spec conformance FR-055, test citations) plus the vacuous `embedded_content` drift check (generator injected as a parameter) and `notice_paths` (FR-033 path list) | `test/architecture/` | extended, not replaced; PR 8 wires the real generator into the drift check, PR 10 adds the `CLN-` licensing checks |
| `NOTICE.md` (statement, scope, status line), `lib/adapters.dart` (`SeededDiceRoller`), `doc/observability/signals.md` (six `d20_test` rows) | repo root / `lib/` / `doc/` | PR 10 fixes the statement's quotes and activates coverage; the catalogue gains six `srd5e.content.*` rows in PR 7 |
| `ResolveD20Test` | `lib/src/d20_test/` | the reference template PR 7 copies (constructor injection, span/counter shape, one-owner failure recording) |

No content code exists (the `content` folders hold `.gitkeep`); `data/`,
`tool/`, `lib/src/content/data/`, `test/fixtures/srd/`, `test/content/`,
`test/tool/`, `test/contract/content_*.dart` and `test/scenarios/content_*`
are all created by this phase. No new `shared_ports` port is introduced:
`ContentSetDecoder` and `ContentSource` live in
`content/application/ports/` (context-local; they move to `shared_ports/`
only if a second context needs them, architecture.md §1).

## 3. Scope fence

**In scope:**

- content-schema-and-decoder.md in full: identity types (FR-142 to FR-148),
  vocabulary and static facts (FR-105 to FR-113, FR-117, FR-128 to FR-130,
  FR-132 to FR-137, FR-139, FR-149), typed ids (FR-114: the nine
  `SpeciesId`…`FeatureId`; `MagicItemId`/`PoisonId`/`TrapId`/`ContagionId`
  land with their rows), building blocks (FR-115, FR-116, FR-118, FR-119),
  `ContentTextBlock` (FR-150 to FR-152), `ContentSet` and whole-set
  validation (FR-071, FR-072, FR-093, FR-095, FR-097, FR-098, FR-125 to
  FR-127, FR-140, FR-141), the decoder port and `JsonContentSetDecoder`
  (FR-001 to FR-036, FR-073 to FR-076, FR-089, FR-090, FR-094, FR-104),
  `LoadContentSet` with telemetry (FR-077 to FR-088, FR-100 to FR-103,
  FR-131), the fake and contract suite (FR-087), the generator (FR-120 to
  FR-124) and the Chrome requirement (FR-099, including the CI and
  AGENTS.md edits and the release-0-1-0.md checklist row it owns).
- content-source-port.md in full (port, `ContentLookup`, `ContentQuery`,
  `ContentCatalogue`, `ContentSourceException`, `InMemoryContentSource`,
  `BundledContentSource`, `BundledContentInvalid`, both contract suites,
  `FakeContentSource`, the scenario of FR-043, the README reuse docs of
  FR-050).
- content-licensing-and-notice.md: the `CLN-` check suite in
  `test/architecture/checks/notice*.dart` with self-test pairs, and the
  notice artefacts its activation list requires at the first data file
  (FR-002 quote fix, FR-005 three-path Scope, FR-011 status-line removal,
  FR-027 per-directory READMEs, FR-028 README statement; FR-029 comes free —
  the generator emits the header).
- content-thin-slice.md in full: the 17-entry slice, its oracle fixtures,
  data pins, telemetry pin and scenario.
- The **type and shape rows** of the five kind specs the registered envelope
  decodes, each minus its bulk-data, extraction and verification rows:
  - content-species-backgrounds-feats.md: entry types and shapes (§5 table;
    FR-010 to FR-033 shape rows, FR-060, FR-061, FR-069, FR-071 to FR-073,
    SX-1 to SX-4). Bulk pins (FR-001 to FR-003, FR-015, FR-022, FR-031,
    FR-034, FR-038 to FR-041, FR-043, FR-044 to FR-053, FR-055, FR-059,
    FR-062, FR-070, FR-074) wait for the phase-5 data change; the slice's
    own four-species pins come from content-thin-slice.md.
  - content-classes.md: types, accessors and shapes (§5; FR-001, FR-002,
    FR-005 to FR-019, FR-021 to FR-026, FR-028 to FR-032, FR-036 to FR-040,
    FR-043 to FR-045, FR-047 to FR-055, FR-058, FR-059, FR-061 to FR-066,
    FR-070 to FR-075, FR-095 to FR-099, FR-102). The bundled oracle rows
    (FR-003, FR-016, FR-020, FR-027, FR-029, FR-033 to FR-035, FR-038
    values, FR-041, FR-042, FR-046, FR-057, FR-060, FR-065, FR-067 to
    FR-069, FR-076, FR-077) are staged — its own test plan says "Staged:
    bundled ids a subset of SRC" — and complete with
    content-classes-data.md in phase 3.
  - content-spells.md: the `Spell` model, its sealed families and
    `classSpellList` (FR-009 to FR-012, FR-017, FR-018, FR-026 to FR-032
    model rows, FR-036, FR-037, FR-049 to FR-058, FR-086 to FR-090, FR-092,
    FR-098, FR-101, FR-102, FR-107 to FR-111, FR-113 to FR-115, FR-119 to
    FR-122). The 339-spell bulk set, the extraction tool and the
    distribution pins are phase 5.
  - spell-effect-data.md: the content model of §5.2
    (`SpellEffectModel` … zone facts) with its constructor and table tests;
    the `effects` JSON field and decode rows land with R2-spell-effects in
    phase 5.
  - content-equipment.md: `Coin`, `Cost`, `Price`, `WeightSpec`,
    `EquipmentCategory`, `ArmorCategory`, `ArmorClassRule`, `Weapon`,
    `Armor` and their shape rows (the weapons/armor shapes the baseline row
    R1 registers: FR-001, FR-002, FR-005, FR-009 to FR-015, FR-019, FR-022,
    FR-024, and the shape FRs the R2-equipment row assigns here: FR-080,
    FR-093, FR-098, FR-103, FR-105, FR-106, FR-109 to FR-112).

**Out of scope** (do not drift here):

- All bulk data except the slice: the other five species, four backgrounds,
  17 feats, the eleven other classes and every subclass (phase 3), the other
  327 spells, all equipment, monsters, magic items (phase 5).
- Extraction and verification tooling of the bulk specs
  (`tool/extract_spells.dart`, `tool/extract_equipment.dart`, the species
  normalisation/manifest/PDF-check rows, the spells `pdftohtml` pipeline):
  their data phases. Phase 2's only `tool/` script is the generator.
- **Monster types** (`content-monsters.md`), **magic-item types**
  (`content-magic-items.md`) and **equipment beyond weapons/armor/cost**
  (tools, adventuring gear, mounts, vehicles, services, crafting data):
  their types, their R2 rows and their arrays land with the phase that
  first consumes them (monsters with phase 4's monster specs; magic-item
  vocabulary with phase 3's `magic-item-rules.md`; the equipment tail with
  the phase-5 bulk change). This is a deliberate reading of FR-014 (see
  below).
- The toolbox catalogue kinds' rows and ids (R3-poisons/traps/contagions,
  `PoisonId`/`TrapId`/`ContagionId`): phase 5. `ContentKind` still declares
  all eleven values now (FR-142 pins it).
- `.pubignore` and the release-spec notice items (release-0-1-0.md FR-048,
  FR-061): phase 5. Nothing in Phase 2 excludes `lib/src/content/data/`
  from publishing because no `.pubignore` exists yet.
- Editing any spec's requirements. New gaps found while coding get a new FR
  id or a new spec (roadmap planning note 1), never a renumbering.
- Any `character`, `combat` or `toolbox` work; any change to
  `shared_kernel` or `shared_ports` (a need for one is a design smell to
  raise, not to fix silently).

**Scope decision to ratify.** shared-types-and-ownership.md FR-014 defaults
to "content types and vocabulary in 2", and the three deferred type sets
above all carry "Types 2" headers. Deferring them is legal under FR-014's
operative rule (a spec may depend only on specs whose types ship in the same
or an **earlier** phase — monsters' first consumer is phase 4, magic items'
is phase 3), and it keeps Phase 2 a reviewable vertical slice instead of
three large type families with no decoder path, no data and no consumer.
If the letter is preferred instead, PRs 4b/4c/4d (monster, magic-item,
equipment-tail types) slot in after PR 4 with no rework; the recommendation
of this plan is to defer.

## 4. Delivery sequence

Eleven PRs, each independently green, ordered by dependency. PRs 1–4 ship
tested domain types; PRs 5–8 the decoder, use case and generator; PR 9 the
port and adapters; PRs 10–11 the licensing activation and the slice, which
flips the four specs.

| PR | Ships | Spec progress |
|---|---|---|
| 1 | Vocabulary, identity types, typed ids, building blocks, `ContentTextBlock`, reference interfaces; the `content` barrel's domain half | schema: identity/vocabulary FRs |
| 2 | Species, background and feat entry types | species-bg-feats: types |
| 3 | Classes types (`ClassDefinition` … `deriveFeatureId`) | classes: types |
| 4 | Spells + spell-effect-data model + equipment weapon/armor/cost types | spells/effects/equipment: types |
| 5 | `ContentSet`, whole-set validation, decoder port, `JsonContentSetDecoder` (envelope, generic field rules, species/backgrounds/feats/weapons/armor shapes), `FakeContentSetDecoder`, decoder contract suite, Chrome CI + AGENTS.md command | schema: decoder core |
| 6 | Decoder shapes for classes and spells; the FR-094 agreement test; revision rows R1-* marked landed | schema: decoder complete; kind specs: shapes |
| 7 | `LoadContentSet`, `ContentSignals`, six catalogue rows | schema: use case + telemetry |
| 8 | `tool/generate_embedded_data.dart`, embedded index, drift wiring, the FR-104 architecture test (vacuous) | schema: generator |
| 9 | `ContentSource` port, `ContentCatalogue`, `ContentLookup`/`ContentQuery`, `ContentSourceException`, `InMemoryContentSource`, `BundledContentSource`/`BundledContentInvalid`, `FakeContentSource`, contract suites, entry-point exports, FR-043 scenario | port spec: all |
| 10 | `CLN-` licensing checks + `NOTICE.md`/README fixes | licensing: all |
| 11 | The thin slice (3 documents, 17 entries), fixtures, data pins, telemetry pin, scenario; four spec flips; roadmap/doc updates | thin-slice: all; 4 flips |

**Process contract for every PR** (from `AGENTS.md` and the rule files;
identical to Phase 1):

- Full check green before review: `dart format --set-exit-if-changed`,
  `dart analyze --fatal-infos`, whole suite with
  `--test-randomize-ordering-seed=random`, coverage generated
  (`coverage/lcov.info`), all in Docker (command in `AGENTS.md`). From PR 5
  on, also the Chrome run (FR-099; §17).
- Every changed or added line in `domain/` and `application/` covered;
  uncovered lines need a stated reason (testing.md §7).
- Mutation testing over `lib/src/shared_kernel lib/src/shared_ports
  lib/src/d20_test/domain lib/src/content/domain` with `--diff-base` the
  PR's base branch, threshold 80, Docker-capped jobs (testing.md §8).
  Survivors are fixed with better tests, not silenced, unless provably
  equivalent. The CI mutation job's path list gains `lib/src/content/domain`
  in PR 1.
- `CHANGELOG.md` under `Unreleased` / **Added** (text from the specs' §10).
  Not **BREAKING**: everything is new (the `Srd5eException` hierarchy gains
  `ContentSourceException`, noted as accepted pre-0.1.0 per
  content-source-port.md §10).
- PR description carries `Testing` and `Observability` entries
  (`.github/pull_request_template.md`).
- Every `group(`/`test(` outside `test/architecture/` carries
  `Requirement:` and `Path:` doc comments citing `doc/specs/<name>.md
  FR-<n>` (testing.md §5; enforced by the citation guardrail).

## 5. PR 1 — vocabulary and identity types

**Files** (suggested granularity; the spec fixes names and API, not files),
all under `lib/src/content/domain/`:

- The vocabulary enums with their `jsonValue`/`fromJson` and static facts:
  `Skill`, `DamageType`, `CreatureType`, `CreatureSize` (+ `CreatureSpace`
  sealed family, six constants, no public constructor), `ConditionKind`,
  `Language`, `RechargeTrigger`, `WeaponProperty`, `MasteryProperty`,
  `FeatCategory`, `HitPointDie`, `LightLevel`, `DarknessKind`,
  `Obscurement`, `SpecialSense`, `Alignment`, `DurationUnit`,
  `ContentProblemKind`, `ContentIdProblem`, `SourceCitationProblem`.
- Identity: `ContentKind` (eleven values, FR-142 order), `ContentId` +
  `tryCreate`/`ContentIdParse`, `ContentKey`, `ContentEntry`
  (`@immutable` interface), `MissingContent`.
- Typed ids (FR-114): the nine ids plus `TypedId`, `ContentKeyedId`,
  `TypedIdParse`.
- Building blocks: `SourceCitation` (+ constants, `citesSrd521`,
  `citationText`, `tryCreate`), `NamedText`, the sealed `Prerequisite` and
  `ToolProficiency` families, the sealed `ContentTextBlock` family with its
  factories (FR-150, FR-151).
- The reference interfaces of FR-125/FR-126: `ContentReferences`,
  `ContentReference`, `ReferenceConstraint` (`TargetHasFeatCategory`),
  `HasFeatCategory`.
- `lib/src/content/content.dart` — the context barrel, created here with the
  domain exports; PRs 5–9 add the application and port exports. Library doc
  comment lists inputs and outputs (architecture.md §4).
- `lib/srd5e.dart` — re-export the barrel; dartdoc on every exported member.
- `.github/workflows/ci.yml` — add `lib/src/content/domain` to the mutation
  job's paths.
- `CHANGELOG.md`.

**Tests** (`test/content/domain/`, unit level, no doubles): the decoder
spec's case rows that are unit-level — every vocabulary member set, order,
spelling and fact (FR-105 to FR-113, FR-117, FR-132 to FR-137, FR-139,
FR-149: 18 skills with abilities, 13 damage types, the U+2019 apostrophe of
Thieves' Cant, no Aquan/Auran/Ignan/Terran, 9+8 weapon/mastery properties
with no `Range`, four `HitPointDie` with `faces`, the size-and-space table,
the ten alignments rejecting `LG` and "Any Alignment"); `ContentId`
accept/reject/precedence rows and `tryCreate` agreement (FR-143, FR-144);
`ContentKey`/`MissingContent` equality (FR-145, FR-147); the typed-id table
(FR-114: constructor/`.of`/equality/`key`/`missing`/`tryCreate`, per the
mapping table); `SourceCitation` rows incl. `citationText` and the SRD
constants (FR-115, FR-138); `NamedText`/`Prerequisite`/`ToolProficiency`
constructor rows (FR-116, FR-118, FR-119); `ContentTextBlock` constructor
rows and exhaustive switches (FR-150, FR-151); `ContentKind` pinned to
eleven values with indexes (FR-142). `ArgumentError` assertions use `name`
and `invalidValue`, never message text.

**Definition of done:** full check green; mutation ≥ 80 over the new
domain code; barrel scan clean (no generic variant names; the family
prefixes of `ContentTextBlock` hold); layering guardrails pass with the
folder populated; changelog entry present.

## 6. PR 2 — species, background and feat types

**Files** (`lib/src/content/domain/`): `Species`, `SpeciesChoice`, the
sealed `ChoiceOption` family (`DamageTypeOption`, `LineageOption`,
`TextOption`), `LevelBenefit`, `Background`, `BackgroundFeatReference`,
`EquipmentOptions`/`EquipmentOption`/`EquipmentItem`, `Feat`, `FeatBenefit`,
`EquipmentItemValue`, the sealed `CustomBackgroundEquipmentProblem` family
and the pure `customBackgroundEquipmentProblems` (FR-073). `Species` and
`Background` implement `ContentReferences`; `Feat` implements
`HasFeatCategory`. Limits are public constants/predicates for the decoder to
reuse (FR-069, schema FR-094). Barrel + `lib/srd5e.dart` extended.

**Tests** (`test/content/domain/`): constructor rows of the spec's case
tables ("Species header", "Background cases", "Feat cases",
"Elven Lineages and Fiendish Legacies", id-derivation rows at type level
where they pin constructor behaviour), sealed-family exhaustive switches,
value equality and `UnsupportedError` on collection mutation, and the
custom-background function's rows (FR-072 step 5 cases). No bundled-data
pins (none exist yet).

**Definition of done:** as PR 1.

## 7. PR 3 — classes types

**Files** (`lib/src/content/domain/classes/`, per FR-010):
`ClassDefinition` with its pure accessors (`subclassLevel`, `rowAt`,
`rowFeatures`/`ResolvedRow`, `entriesGainedAt`, `featGrantsAt`, `column`,
`entry`/`FeatureEntryLookup`, `subclass`/`SubclassLookup`),
`SubclassDefinition`, `ProgressionRow` (+ sealed `RowFeature`,
`SpellcastingRow` = `SlotSpellcastingRow`/`PactSpellcastingRow`, `values`
map, sealed `ColumnValue` family), `ClassColumn`, `FeatureEntry` (+ sealed
`FeatureFact`: `GrantsSubclass`, `GrantsFeat`, `AlwaysPreparedSpells` with
`SpellGrant`), `FeatureOption`, `OptionPrerequisite`, `FeatureTable` +
`TableCell` family, `AbilityRequirement` (`AllOf`/`AnyOf` with `isMetBy`),
`SkillChoice` variants, `WeaponProficiency`/`WeaponTrainingCategory`,
`ArmorTrainingCategory`, `ClassToolProficiency` variants,
`ClassStartingEquipment`/`ClassEquipmentOption`/`ClassEquipmentItem`,
`MulticlassGrants`, `ClassSpellcastingTrait` variants, `deriveFeatureId`,
`FeatureOptionId`, `ClassColumnId`. Barrel + `lib/srd5e.dart` extended.

**Tests:** the spec's non-bundled case tables — Cases AR (`isMetBy`), Cases
ID (feature-id derivation incl. the duplicate-name `_level_<n>` rule),
Cases CV (column values), accessor boundaries (`rowAt` 0/1/20/21,
`entriesGainedAt` empty levels, undeclared column `ArgumentError`,
lookups found/not-found), constructor rejections (FR-007 rows: slot-count
shapes, `AnyOf` of one, duplicate abilities, level outside 1–20), equality
and immutability.

**Definition of done:** as PR 1.

## 8. PR 4 — spells, spell-effect data and equipment weapon/armor types

**Files:**

- `lib/src/content/domain/` (spells): `Spell` (with `effects` defaulting to
  `const TextOnlyEffects`, FR-122), `SpellLevel` + `tryCreate`, 
  `SpellSchool`, `SpellCastingTimes`/`CastingTimeMode`/the `CastingTime*`
  variants, `SpellRange` variants, `SpellComponents`/`MaterialComponent`,
  `SpellDuration` variants + `DurationLimit`, `DistanceUnit`, and the pure
  `classSpellList`/`ClassSpellList` (FR-120, FR-121).
- `lib/src/content/domain/` (spell effects, spell-effect-data §5.2):
  `SpellEffectModel` (`TextOnlyEffects`/`ModelledEffects`), `EffectCoverage`,
  the targeting, part, outcome, amount/scaling, facts and zone-fact types,
  with their constructor invariants and scaled-value queries.
- `lib/src/content/domain/` (equipment subset): `Coin`, `Cost` (+ static
  `compareByValue`), `Price`, `WeightSpec`, `EquipmentCategory`,
  `ArmorCategory` (don/doff facts), the sealed `ArmorClassRule`
  (`BaseRule`/`BonusRule`), `Weapon`, `WeaponDamage`, `Armor`.
- Barrel + `lib/srd5e.dart` extended (exact export lists: spells FR-114,
  spell-effect-data §6, equipment FR-077).

**Tests:** spells model rows (level boundaries incl. `tryCreate`, casting
time/range/duration/component constructor rules of FR-026 to FR-058,
`requiresConcentration`, name rules, `classSpellList` derivation over
synthetic sets); spell-effect-data Tables A/T/L/C/F and the constructor
invariants (FR-012 to FR-029, FR-041 to FR-048 — synthetic values only; no
pilot-set fixtures, those are verification rows for phase 5); equipment
cost/coin rows (FR-009 to FR-011: equality of 5 SP vs 50 CP,
`valueInCopper`), armor-category facts, `ArmorClassRule` switch, weapon/
armor constructor rows. Exhaustive switches over every sealed family;
equality and immutability throughout.

**Definition of done:** as PR 1.

## 9. PR 5 — `ContentSet`, validation, decoder core

**Files:**

- `lib/src/content/domain/`: `ContentSet` (ordered, unmodifiable,
  duplicate-key `ArgumentError`), the whole-set validation types and the
  pure `validateContentSet` (FR-125 to FR-127: `ContentSetValidation` =
  `ContentSetValid`/`ContentSetInvalid`, `ContentReferenceProblem`).
- `lib/src/content/application/ports/content_set_decoder.dart`: the
  synchronous `ContentSetDecoder` port.
- `lib/src/content/application/`: `ContentProblem`, the sealed
  `ContentDecodeResult` (`ContentDecoded`/`ContentDecodeFailed`), and the
  exported `supportedSchemaVersions` (FR-007).
- `lib/src/content/adapters/json_content_set_decoder.dart`: the decoder —
  envelope (FR-001 to FR-011: syntax, root object, `schemaVersion` rules,
  registered root arrays), generic field rules (FR-012 to FR-034: report
  everything, no cascade, JSON pointers, `wrongType`/`outOfRange`/
  `invalidValue`/`duplicate`/`unknownField`, `source`, safe integers), the
  FR-016 problem ordering, the FR-095 lookup/construction sets, and the
  shapes for `species`, `backgrounds`, `feats` (incl. SX-1 to SX-4),
  `weapons` and `armor`.
- `lib/src/testing/fake_content_set_decoder.dart` (scriptable, recording)
  + export from `lib/testing.dart`.
- `test/contract/content_set_decoder_contract.dart`:
  `runContentSetDecoderContract` + self-test with deliberately bad doubles
  (FR-087; not exported).
- `.github/workflows/ci.yml` + `AGENTS.md` "Commands" +
  `doc/specs/release-0-1-0.md`: the three FR-099 changes (Chrome install
  and `dart test -p chrome test/content/adapters`; local Docker command;
  release checklist row).
- Barrel: application exports (`ContentProblem`, `ContentDecodeResult`,
  `ContentSetDecoder`, `supportedSchemaVersions`, `ContentSet`, validation
  types); `lib/adapters.dart` gains `JsonContentSetDecoder`.

**Tests:**

- `test/content/domain/`: `ContentSet` and validation unit rows (the
  "whole-set references" case table: resolve/unresolved/constraint/
  duplicate/ordering/lookup-set rules, FR-093, FR-095, FR-097, FR-098).
- `test/content/adapters/` (VM **and** Chrome, FR-099): the document-level
  and field-rule case tables (FR-002 to FR-034 rows: not-JSON corpus,
  version rows, minimal document, legacy keys, escaped keys, integer-form
  rows incl. `2.0`/`2.5`/20-digit, no-cascade, duplicate groups by kind,
  `source` rows, hostile corpus and the seeded property loop — never
  throws, VM/Chrome agreement); the species/background/feat and weapons/
  armor decode rows from their specs' case tables (one required field
  removed per field, unknown keys, range boundaries).
- `test/contract/`: the decoder contract suite against
  `JsonContentSetDecoder` and `FakeContentSetDecoder`; `test/testing/`:
  the fake's scripting/recording/thrown-error tests.
- Architecture additions: FR-073 scans (no `dart:convert` in `domain/`, no
  raw `Map`/`dynamic` in public signatures), FR-141 (only
  `content/application/` imports `shared_ports/errors/`), FR-088 dartdoc
  and export placement.

**Definition of done:** full check green **including the Chrome run**;
mutation ≥ 80 over `lib/src/content/domain` (the decoder itself SHOULD be
mutated too, per the spec's test plan); the architecture suite green with
the new checks; changelog entry.

## 10. PR 6 — decoder shapes for classes and spells; the agreement test

**Files:** `JsonContentSetDecoder` extended with the `classes` array
(nested subclasses, progression/columns/values, features/facts/options/
tables, the R1-classes-ids uniqueness groups reported after class-id
duplicates per FR-016) and the `spells` array (the §5.2 key orders, the
sealed-family `kind` discriminators, `classes` as plain id strings,
block decoding per FR-152). Revision-table edits in
content-schema-and-decoder.md: R1-species-backgrounds-feats, R1-classes,
R1-classes-ids, R1-classes-spell-ids and R1-spells flip to "landed" (their
shapes now decode); R1-thin-slice reads "closed (declined)" already.

**Tests:** the classes decode rows (FR-004 to FR-006 document rules, Cases
PR and SP decode halves, wrong-container rows, feature-id agreement) and
the spells decode rows ("Cases: spell JSON", FR-107 to FR-111); the FR-094
agreement test across every kind now decodable — each invalid case-table
row fed to decoder (expected problem), constructor (`ArgumentError`) and
`tryCreate` where present, each valid row accepted by all; the lint-style
test that the decoder uses the domain constants; FR-035/FR-036 rows
(a backgrounds-only document decodes clean; the Origin rule is reported
only by `validateContentSet`). Mutation over the changed decoder lines.

**Definition of done:** as PR 5; the agreement test green for all five
kind specs' case tables.

## 11. PR 7 — `LoadContentSet` use case and telemetry

**Files:** `lib/src/content/application/load_content_set.dart` (command,
the sealed `LoadContentSetResult` = `LoadContentSetLoaded`/
`LoadContentSetRejected`, the use case composing only the port and its
`Observability`, FR-077, FR-131); `lib/src/content/application/
content_signals.dart` (the `ContentSignals` constants: `srd5e.content.load`,
`.decode`, `.loads`, `.decode_errors`, `.entries_loaded`,
`.load_duration`, and the attribute keys `srd5e.content.kind`,
`srd5e.content.problem_kind`);
`doc/observability/signals.md` — the six rows from the spec's §7 table,
purpose and suggested monitoring filled (same PR as the constants;
catalogue-consistency guardrail). If the shared attribute-value registry
in `test/architecture/support/constants.dart` requires it (as Phase 1's
gap-fill did), `doc/rules/observability.md` §5 gains the two `srd5e.content`
keys with a fresh RULE-TAG rotation. Barrel + `lib/srd5e.dart` gain the
use case and result types.

**Tests** (`test/content/application/`): the FR-079 to FR-086 table —
span names and nesting, counter increments and non-increments per outcome,
`timedDuration` proving `load_duration` (including when the port throws),
two-kind fixture → exactly two `entries_loaded` (never `add(0)`), rejected
fixture → error span status + `decode_errors` per problem kind + one
`loads` increment + zero log records, `StateError`/test-
`Srd5eException`/`FormatException` throw paths (record/no-count/rethrow
matrix of FR-086), no-op vs recording identity, attribute values within
the registered sets. Pin the constant names literally (they are public
contract, observability.md §9).

**Definition of done:** full check green; mutation over the use case
SHOULD-reported and domain paths ≥ 80; catalogue rows match the constants;
changelog entry.

## 12. PR 8 — generator, embedded index, drift wiring

**Files:** `tool/generate_embedded_data.dart` — the pure
`generateEmbeddedLibraries(Map<String, String>)` core (byte-stable,
ordinal output, `\n` endings, the FR-029 two-line header, escaped literals,
the `embedded_documents.dart` index) plus a thin `main` wrapper (FR-120,
FR-121); `lib/src/content/data/` — the generated empty index (committed);
`test/architecture/checks/embedded_content.dart` — register the real
generator (the check exists vacuous; now it enforces FR-123 drift with the
FR-078 fixtures: identical/differing byte/missing/extra/no-`data/`); the
FR-104 architecture test created (enumerates `data/srd_5_2_1/*.json` from
the `SourceSet` and the embedded index, decodes each, validates the merged
set, compares embedded strings to file texts, checks `citesSrd521` —
asserting emptiness explicitly and passing while both are empty);
`test/tool/generate_embedded_data_test.dart` (the FR-120 to FR-122 rows:
constant naming, header verbatim, escaping round-trip of `$`, `'`, `\`,
tab, CR, U+2019, determinism across map orders, bad-name `ArgumentError`s,
empty input → index only).

**Definition of done:** full check green; drift check live and green with
an empty `data/`; no `lib/` import of `tool/` (existing guardrail);
changelog entry (the generator is unpublished tooling — entry per the
spec's §10).

## 13. PR 9 — `ContentSource` port, adapters, doubles, contract suites

**Files:**

- `lib/src/content/domain/`: `ContentLookup` (`ContentFound`/
  `ContentNotFound` + `missing`), `ContentCatalogue`, `ContentQuery`
  (`ContentLookupQuery`/`ContentListKindQuery`) — FR-015, FR-016, FR-051,
  FR-057, FR-046.
- `lib/src/content/application/ports/content_source.dart`:
  `ContentSource` (async) and `ContentSourceException` (FR-007 to FR-009,
  FR-018, FR-037 to FR-039; added to the error-type uniqueness sample test
  of errors-and-results.md FR-006).
- `lib/src/content/adapters/`: `InMemoryContentSource`,
  `BundledContentSource` (decode-each-text → `validateContentSet` →
  catalogue → delegate; `BundledContentInvalid` on any failure; defaults
  to the embedded index and the real decoder), FR-020, FR-059 to FR-064.
- `lib/src/testing/fake_content_source.dart` + export: scriptable
  failures, recorded `ContentQuery`s (FR-029 to FR-031, FR-049).
- `test/contract/content_source_contract.dart`:
  `contentSourceContractChecks` and `contentSourceReadOnlyChecks` with
  `ContentSourceContractViolation` self-tests (FR-027, FR-028, FR-042,
  FR-058); registrations for `InMemoryContentSource`,
  `FakeContentSource`, the test-only wrapping adapter and
  `BundledContentSource` (FR-047) + the registration architecture scan.
- `lib/adapters.dart`: gains `InMemoryContentSource`,
  `BundledContentSource`, `BundledContentInvalid`. Barrel gains the FR-025
  list; `lib/testing.dart` gains `FakeContentSource`.
- `README.md`: the adapter-author section pointing at
  `test/contract/content_source_contract.dart` (FR-050).

**Tests:** `ContentCatalogue` unit rows (duplicate-key `ArgumentError`
with `name`/`invalidValue`, ordering table incl. digit/underscore rows,
same id under two kinds, single-pass input, mutation isolation);
`ContentLookup`/`ContentQuery` unit rows; `InMemoryContentSource` Zone
test (no `Timer`, FR-024) and contract runs; `BundledContentSource`
adapter tests with an injected `FakeContentSetDecoder` (FR-059 to FR-063
rows: one decode call per text, validation hand-off, corrupted text /
duplicate across texts / dangling reference → `BundledContentInvalid`
with ordered unmodifiable lists, empty index → empty source, results equal
an `InMemoryContentSource` over the same entries); the fake's tests;
`test/scenarios/content_source_scenario_test.dart` (FR-043: three public
entry points only, exhaustive `switch`, present/absent/listKind).

**Definition of done:** full check green; contract suites green for every
registered implementation; architecture scans (export placement, fake
import rules, registration) green; changelog entry.

## 14. PR 10 — licensing checks and notice activation

**Files:** `test/architecture/checks/notice*.dart` (+ self-test pairs, not
in the guardrails registry) implementing the `CLN-` checks with the §3
normalisation; `NOTICE.md` — the statement re-fixed with typographic
quotes (FR-002 currently fails: straight quotes), the Scope section lists
the three covered paths as backticked paths, the status line stays (no
content yet — it is removed in PR 11, or now if the PRs land together);
`README.md` gains the attribution statement (FR-028, conditional on
content — safe to add now); `data/srd_5_2_1/README.md`,
`lib/src/content/data/README.md` with the pointer sentence (their
directories hold files from PR 8 on — FR-027 fires per directory).

**Tests:** the licensing spec's two case tables as the checks' self-tests
(A-01 to A-18, S-01 to S-37), one violating and one clean fixture per
check, exact `CLN-` ids and line numbers; the always-on checks green
against the real repository files.

**Definition of done:** full check green; every always-on `CLN-` check
green on the repository as it stands; changelog entry (per the spec §10).

## 15. PR 11 — the thin slice, pins, flips

**Data** (hand-transcribed from the cited PDF pages, independently
re-read, human review recorded in the PR checklist per FR-079):

- `data/srd_5_2_1/species.json` — `dragonborn`, `dwarf`, `elf`, `human`
  (pp. 84–86) with `choices` (Draconic Ancestry, Elven Lineage),
  `sizeText`, and the nine lineage `spellId`s.
- `data/srd_5_2_1/spells.json` — the twelve spells of the slice table
  (pp. 121–154).
- `data/srd_5_2_1/class_wizard.json` — the Wizard (pp. 77–78): core
  traits, 20-row progression, ten feature entries, `subclasses: []`.
- Regenerate and commit the embedded libraries + index; `NOTICE.md`
  status line removed; `test/fixtures/srd/README.md` added (the oracle
  lands there).

**Oracle fixtures** (`test/fixtures/srd/thin_slice/`, Dart `const`
libraries, transcribed independently of the data): tables T1–T4, T6, T7
and the pinned phrases of §4.

**Tests:**

- `test/content/adapters/thin_slice_pins_test.dart` (or a folder): every
  row of the thin-slice §8 table — membership (FR-001 to FR-004, FR-067:
  4/1/12 entries, no other kind), citations (FR-007), pinned phrases and
  the banned-term word-boundary scan (FR-008), the species and spell pins
  (FR-009 to FR-032, FR-048 to FR-061, FR-083: one test per T-row),
  reference closure (FR-063, FR-084: collect the nine `spellId`s from the
  decoded entries, each resolves; `validateContentSet` over the merged
  documents is `ContentSetValid`), absent-id lookups (FR-064 to FR-066).
- `test/content/application/load_content_set_slice_test.dart` — FR-078:
  three loads with a recording `Observability`, `entries_loaded` 4/1/12 by
  kind, three `loads{success}`, zero `decode_errors`.
- `test/scenarios/bundled_content_scenario_test.dart` — the thin-slice
  scenario: `BundledContentSource` from the three texts, look up `elf`,
  follow all nine lineage spells to `ContentFound`, `light` →
  `ContentNotFound` (imports `srd5e.dart` and `adapters.dart` only).
- The FR-104 architecture test goes live over real data (every file and
  embedded string decodes with zero problems; merged set valid; embedded
  strings equal file texts; every `source` passes `citesSrd521`).

**Flips and docs:** the four specs → `implemented`; before each flip,
audit citations against the spec's §8 so FR-055 is clean (add
`Deliberately not covered` lines only for ids with genuinely no runtime
test, e.g. FR-079's process row); `doc/roadmap.md` Phase 2 status;
`doc/documentation_index.md` rows (spec statuses, this plan);
`CHANGELOG.md` (the four §10 entries).

**Definition of done:** full check green (VM + Chrome); drift and FR-104
green over real data; all `CLN-` content-conditional checks green
(status line gone, READMEs present); FR-055 clean for four specs; the
human PDF review recorded in the PR description.

## 16. Requirement traceability

Per-id test mapping lives in the specs' own §8 (authoritative). This
matrix fixes slice ownership; an id may not close until its §8 row has its
test.

| Ids (grouped) | PR | Level |
|---|---|---|
| schema FR-105 to FR-119, FR-128 to FR-130, FR-132 to FR-137, FR-139, FR-142 to FR-151 | 1 | unit |
| species-bg-feats type rows (§5; FR-010 to FR-033 shapes, FR-060, FR-061, FR-069, FR-071 to FR-073) | 2 | unit |
| classes type rows (§5; FR-001, FR-002, FR-005 to FR-019, FR-021 to FR-026, FR-028 to FR-032, FR-036 to FR-040, FR-043 to FR-045, FR-047 to FR-055, FR-058, FR-059, FR-061 to FR-066, FR-070 to FR-075, FR-095 to FR-099, FR-102) | 3 | unit |
| spells model rows (FR-009 to FR-012, FR-017, FR-018, FR-026 to FR-032, FR-036, FR-037, FR-049 to FR-058, FR-086 to FR-090, FR-098, FR-101, FR-102, FR-113 to FR-115, FR-119 to FR-122); spell-effect-data §5.2 constructors and tables; equipment cost/weapon/armor type rows (FR-001, FR-002, FR-005, FR-009 to FR-015, FR-019, FR-022, FR-024, FR-080, FR-093, FR-098, FR-103, FR-105, FR-106, FR-109 to FR-112) | 4 | unit |
| schema FR-001 to FR-036, FR-071 to FR-076, FR-089 to FR-098 (envelope, generic rules, `ContentSet`, validation), FR-087, FR-099 | 5 | unit + contract (VM/Chrome) + architecture |
| classes/spells decode rows + FR-094 agreement; revision-row edits | 6 | contract (VM/Chrome) + doc |
| schema FR-077 to FR-086, FR-100 to FR-103, FR-131; catalogue rows | 7 | application + catalogue |
| schema FR-120 to FR-124; drift wiring; FR-104 (vacuous) | 8 | tool unit + architecture |
| port spec FR-007 to FR-031, FR-033 to FR-039, FR-041 to FR-047, FR-049 to FR-051, FR-057 to FR-064 | 9 | unit + contract + adapter + scenario + architecture |
| licensing FR-001 to FR-008, FR-011 to FR-019, FR-024, FR-027 to FR-031, FR-035 to FR-038 + notice edits | 10 | architecture (self-tested checks) |
| thin slice FR-001 to FR-009, FR-032, FR-048 to FR-053, FR-055 to FR-058, FR-060 to FR-067, FR-078 to FR-084; four spec flips; FR-104 live | 11 | adapter + application + scenario + architecture |

Withdrawn ids in every spec have no row, per the FR-055 moved-id exemption.

## 17. Verification commands

Full check, as CI runs it (Docker; `AGENTS.md`):

```sh
docker run --rm -v "$PWD":/app -w /app dart:stable sh -c \
  "dart pub get && dart format --set-exit-if-changed . && dart analyze --fatal-infos && dart run coverage:test_with_coverage -- --test-randomize-ordering-seed=random"
```

Chrome run, from PR 5 on (FR-099(b); CI installs Chrome and runs the same
target per FR-099(a)):

```sh
docker run --rm -v "$PWD":/app -w /app <chrome-capable image built from dart:stable> sh -c \
  "dart pub get && dart test -p chrome test/content/adapters"
```

Mutation testing, after coverage exists (testing.md §8; Docker CPU cap;
never `--jobs 1`):

```sh
cpus=$(( $(nproc) / 4 )); cpus=$(( cpus < 2 ? 2 : cpus ))
docker run --rm --cpus="$cpus" -v "$PWD":/app -w /app dart:stable sh -c \
  "dart pub get && dart pub global activate mutate4dart 0.12.2 && \
   dart run coverage:test_with_coverage && \
   /root/.pub-cache/bin/mutate4dart lib/src/shared_kernel lib/src/shared_ports \
     lib/src/d20_test/domain lib/src/content/domain --diff-base <pr-base> --threshold 80 --jobs $cpus"
```

`<pr-base>` is the PR's base branch (PR 1 against `main`; later PRs against
the previous PR's branch when stacked). `tool/` code is not in the mutation
paths (it is not `lib/`); its pure core is covered by `test/tool/` unit
tests. Gate scripts must tee full-suite output to a log and tail it (the
suite's stdout exceeds the runner's output cap).

## 18. Risks and mitigations

| Risk | Mitigation |
|---|---|
| Decoder PRs (5, 6) are the largest single changes (envelope + field rules + two hard kind shapes + agreement test) | Split at the kind boundary as sequenced; the generic rules are table-driven from the spec's case rows, so review is of the tables; the agreement test (FR-094) is what keeps decoder and constructors in lock-step — land it with the last kind |
| Chrome CI is new and can be flaky or unavailable on runners | Land FR-099 in PR 5 with the smallest possible target (`test/content/adapters` only); pin the install step; if the runner lacks Chrome, the job installs it — the spec makes failure block the build, so verify on the first PR, not the last |
| Transcription fidelity of the slice (the only data) | The spec's process: independent oracle fixtures, pinned phrases, banned-term scan, and the human PDF review recorded in the PR checklist (FR-079); the FR-104 test makes any decode or drift failure build-breaking |
| FR-055 flips on for four specs at once in PR 11 | Audit citations per spec §8 before each flip (Phase 1's lesson); the failure is the guardrail working — add the missing test, not a `Deliberately not covered` line |
| `NOTICE.md`/`README` text precision (typographic quotes, exact statement) | The licensing checks land (PR 10) before the data (PR 11) and are self-tested against the A/S tables; copy the statement from the SRD's "Legal Information" page (p. 1), never from memory |
| Mutation scope grows with `lib/src/content/domain` (large, table-tested) | Tables give dense assertion per mutant; run scoped per-PR (`--diff-base`) rather than whole-folder late; expect the ordered-comparison and boundary rules to need boundary-specific rows |
| Signal catalogue / constants mismatch mid-PR | `ContentSignals` and the six `signals.md` rows land in the same PR 7 (Phase 1's rule); run the architecture suite before pushing |
| Scope creep into bulk data or deferred type sets | The scope fence (§3) and the deferred-types table; a mid-phase need for monsters/magic-items/equipment-tail types is a plan change to ratify, not a quiet addition |

## 19. Out-of-scope observations (recorded, not acted on)

- The three deferred type sets (monsters, magic items, equipment tail) are
  the plan's one deliberate deviation from the FR-014 default letter
  ("content types and vocabulary in 2"); §3 records the recommendation to
  defer and the cost of reversing it (three additive PRs, no rework).
- Phase 1 left a wording-only edit pending in d20-tests.md (FR-009
  parenthetical and §5 sentence describing re-throwing that the
  implementation pre-validates); unrelated to Phase 2, still open.
- `doc/plans/plan-phase-1.md` is deleted in the working tree while
  `doc/documentation_index.md` still lists it; PR 11's documentation pass
  should reconcile the index (archive row or restore the file — Andy's
  call, recorded here so it is not lost).
- release-0-1-0.md FR-061 (`.pubignore`) is phase 5, but PR 11 should
  confirm nothing added in Phase 2 (`data/`, `test/fixtures/`) needs an
  earlier exclusion decision; the licensing FR-018/FR-019 checks stay
  vacuous until that spec's evaluator lands.

## 20. Reporting

Each PR description and the phase-closing summary carry, per `AGENTS.md`:

- **Testing**: tests added by level, happy/unhappy coverage, requirements
  covered, mutation score and survivors, coverage of changed lines,
  anything deliberately uncovered with its reason.
- **Observability**: for the type and tooling PRs (1–6, 8–10), the
  specific justification (domain and adapters silent by design — the
  decoder reports through results, `BundledContentSource` throws
  `BundledContentInvalid`, no signal; the specs' §7 sections say so); for
  PR 7, the six signals, their attribute sets and the deviation FR-080
  documents; for PR 11, the asserted slice values of FR-078 and what a
  consumer should monitor (the spec's §7 monitoring column).

Phase 2 is done when: the four specs read `implemented` and FR-055 is
clean for each; the full check (VM and Chrome) and the mutation gate pass;
the drift check and the FR-104 test run green over real data; the
catalogue holds the six `srd5e.content.*` signals; the thin slice passes
every pin; `NOTICE.md` coverage is active with every `CLN-` check green;
and `CHANGELOG.md` carries the entries.
