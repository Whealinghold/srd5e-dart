# Shared types and ownership

| | |
|---|---|
| Status | accepted |
| Context | `package` |
| Roadmap phase | 0 (binding on every later spec) |
| Depends on | none |

## 1. Purpose and scope

The specs were drafted in parallel and disagreed about who owns which type, which
context may depend on which, and how bundled data reaches consumers. This spec
settles those questions once. Where another spec conflicts with it, **this spec
wins** and the other spec changes.

Principles used to decide, in priority order:

1. **Decoupled and testable first.** Prefer the design in which each unit is
   testable with plain values and no collaborators (pure functions, state in and
   state out, small ports, doubles in one place).
2. **Dependency inversion.** A type lives in the most upstream context that
   needs it, never in a downstream one. Contexts depend on published language
   (value objects, ids, events), not on each other's use cases.
3. **Identity apart from behaviour.** A closed SRD vocabulary (`DamageType`)
   is data owned upstream. The behaviour that interprets it (`ConditionEffects`)
   is owned where the rules are applied.
4. **Make illegal states unrepresentable.** Structured composites and sealed
   types instead of flags, nulls and "validate later".
5. **One owner per type.** Every other spec references it by file and id.
   Redefining a type is a defect.

**Out of scope:** any SRD rule. This is package design; it adds no game content.

## 2. Source

`n/a (package design)`. Derived from `doc/rules/architecture.md` §1–§6 and
`doc/rules/observability.md` §4, and from the consistency review of the first 38
specs. The rule-file amendments in §5 are part of this change.

## 3. Vocabulary

| Term | Meaning here |
|---|---|
| Vocabulary type | A closed set of SRD names with static SRD facts only (enum or extension type) |
| Behaviour owner | The spec whose domain code interprets a vocabulary type |
| Published language | The value objects, ids and events exported from a context barrel |
| Type phase | The roadmap phase in which a spec's *types* ship; bulk *data* may ship later |

## 4. Requirements

Each row is a decision. Ids are stable.

### 4.1 Ownership of shared types

| Id | Decision | Why | Path |
|---|---|---|---|
| FR-001 | `shared_kernel` owns: `Dice`/`DiceExpression`, `RollResult`, `Modifier` (a plain signed integer value object, no kind tag), `RollMode` (`normal`, `advantage`, `disadvantage`), `Ability` (the six abilities), `AbilityScore`, `AbilityModifier`, `AbilityScoreRejection` (single definition, in `ability-scores.md`), and the marker `DomainEvent`. | Used by every context and by `d20_test`, which has no upstream. | happy |
| FR-002 | `d20_test` owns: `D20Roll` (the d20 or d20s rolled, which die was kept, natural value) **including the reroll and replace-a-die operations**; `RollModifiers`; `DifficultyClass`; `D20TestKind`; `D20TestOutcome`; `AttackRollResult`; `ArmorClass`; `CheckResult`; `ForcedFailureResult`; `ForcedFailureReason`; `RerollDecision`; the pure `D20TestResolver` domain service (FR-044); the `ResolveD20Test` use case. | Rerolls (Indomitable, Heroic Inspiration, similar features) act on a roll, so the roll type and its operations live together upstream of `character` and `combat`. | happy |
| FR-003 | `RollModifiers` is a **structured composite** (one ability modifier, an optional Proficiency Bonus, a list of other `Modifier`s), not a bare list. Any "at most one of X" rule the SRD states is enforced by the shape, so no runtime check is needed. | Illegal states unrepresentable. | happy |
| FR-004 | `D20TestOutcome` is `success` or `failure` for every test kind. `AttackRollResult` adds `isCriticalHit` and exposes `hit` as `outcome == success`. No parallel enums (`AttackOutcome`, `AttackConclusion`, `AttackRollOutcome`) exist. | One vocabulary; combat reuses d20_test's types. | happy |
| FR-005 | `content` owns every closed SRD vocabulary type and id: `DamageType`, `ConditionKind`, `Skill` (with its `Ability`), `CreatureSize`, `CreatureType`, `Language`, `RechargeTrigger`, `WeaponProperty`, `MasteryProperty`, and the typed ids `ClassId`, `SubclassId`, `SpeciesId`, `BackgroundId`, `FeatId`, `SpellId`, `ItemId`, `MonsterId`, `FeatureId`. Their owning specs are the content specs. | `content` is upstream of `character` and `combat`; moving these there removes every content→combat and content→character dependency. | happy |
| FR-006 | Vocabulary types carry static SRD facts only (`Skill.ability`). Behaviour is owned elsewhere: `ConditionEffects` in `conditions.md`, damage handling in `hit-points-and-damage.md`, weapon mastery behaviour in `weapon-properties-and-mastery.md`. | Identity apart from behaviour. | happy |
| FR-007 | Content ids are lowercase `snake_case` matching `[a-z][a-z0-9_]*`, in JSON and in typed ids. | Matches the schema spec; one convention. | happy |
| FR-008 | `character` owns, in `derived-stats.md`: `CharacterLevel`, `ClassLevels` (ordered; the first entry is the initial class), `ProficiencyBonus`, `HitPointMaximum`, `HitDicePool`, `HitPointGain`. The aggregate (`character-aggregate.md`) depends on `derived-stats.md`, never the reverse. **`LevelHistory` does not exist**: the aggregate stores state and emits events; hosts keep history if they want it. | Breaks the mutual deferral; state-in/state-out stays small. | happy |
| FR-009 | `rests-and-hit-dice.md` owns `RestKind` and rest effects. `content` owns only `RechargeTrigger` (data); `character` maps `RestKind` to triggers. | `content` must not depend on `character`. | happy |
| FR-010 | `character-aggregate.md` owns `HeroicInspiration` as a sealed state (`Inspired` / `NotInspired`); `d20_test` reroll operations take the decision as input. | No boolean standing in for a named state. | happy |
| FR-011 | `spellcasting.md` owns the `Concentration` state shape (held in `SpellcastingState`); `casting-and-concentration.md` owns the Concentration rules and the save-DC rule, which takes a plain `int` damage amount, never a `combat` event. `combat-action-resolution.md` reads the character's concentration state and calls it. | `character` may not depend on `combat`. | happy |
| FR-012 | `combat-foundations.md` (new) owns `CombatantId`, the combatant reference types, and the in-context naming conventions. See FR-021. | The bottom of the combat dependency order. | happy |

### 4.2 Dependency rules

| Id | Decision | Why | Path |
|---|---|---|---|
| FR-013 | The context map in `architecture.md` §2 is binding on specs, not only on code. A spec may not list, import or assume a type from a downstream context. If it needs one, the type moves upstream under FR-001–FR-012. | The first review found `character`→`combat` and `content`→`combat` edges. | unhappy (forbidden edge) |
| FR-014 | A spec's **types** ship in its context's phase; bulk **data** may ship later. A spec may depend only on specs whose types ship in the same or an earlier phase. Phases: shared and `d20_test` types 0–1; `content` types and vocabulary 2; `character` 3; `combat` 4; bulk data and release 5. | Fixes the phase inversions without reshuffling content volume. | happy |
| FR-015 | Inside `combat`, specs form a strict order: `combat-foundations` ← `hit-points-and-damage` ← `conditions` ← `attacks` ← `initiative-and-actions` ← `encounter-aggregate` ← `combat-action-resolution`. A spec may depend only on specs to its left. | Removes the `conditions`/`initiative`/`encounter` cycle. | unhappy (cycle) |
| FR-016 | Inside `character`, order: `derived-stats` ← `character-aggregate` ← `rests-and-hit-dice`, `spellcasting`, `feats-behaviour`, `weapon-properties-and-mastery`, `level-advancement-and-multiclassing`, `character-creation` ← `class-*`. | Same reason. | unhappy (cycle) |

### 4.3 Results, events and naming

| Id | Decision | Why | Path |
|---|---|---|---|
| FR-017 | Every use case returns its own sealed result named `<UseCase>Result`. Variants are prefixed with the operation: `DamageApplied`, `DamageRejected`, `CreateCharacterContentMissing`. Generic names (`Applied`, `Rejected`, `Succeeded`, `ContentMissing`) are never exported. | Removes barrel collisions. | unhappy (name collision) |
| FR-018 | Shared failure detail is a **value object held as a field**, not a shared variant: `MissingContent(kind, id)` owned by `content`. Variants of different results each carry one. | Dart sealed hierarchies cannot span libraries; fields can. | happy |
| FR-019 | Each context has an event base that is an `abstract interface class` (`CharacterEvent`, `CombatEvent`) implementing `DomainEvent`. Each spec's own event family is `sealed`, so a host switches exhaustively per family. Events are past-tense value objects describing something that happened (never `...Requested`, `...Required` or `...Needed`, and `...Due` only as `...BecameDue`, `combat-foundations.md` FR-020; result values such as `ContainmentDamageDue` are not events). A named event has exactly one defining spec; others reference it. | Dart sealed hierarchies cannot span libraries; an interface base stays open for each spec while families stay exhaustive. | happy |
| FR-020 | `SubclassChosen`, `SubclassRejected` live in `level-advancement-and-multiclassing.md`; `FightingStyleChoice` in `feats-behaviour.md`; `WeaponMasteryChoice` in `weapon-properties-and-mastery.md`; `RestApplied` in `rests-and-hit-dice.md`; `ClassDataInvalid` is replaced by the decoder's failure type. Class specs reference these and define none of them. | Class specs duplicated them. | unhappy (duplicate) |
| FR-021 | Command and event names are unique across the package. Where two specs named the same thing (`ApplyDamageCommand`, `Damage`/`DamageInstance`), `hit-points-and-damage.md` keeps the plain name and `encounter-aggregate.md` uses the `...ToCombatant` form. | Collision list from the review. | unhappy (name collision) |

### 4.4 Class features and state

| Id | Decision | Why | Path |
|---|---|---|---|
| FR-022 | The character aggregate holds `FeatureStates`: an immutable typed-key store. A class spec defines its `FeatureState` implementations and typed `FeatureStateKey`s. The aggregate defines the slot and the read/write API only. | Open for extension without a sealed hierarchy spanning files; testable by constructing states directly. | happy |
| FR-023 | Class feature logic is a **pure domain function** from (character state, inputs) to (new state, events). A feature needing dice or content gets one use case in `application/` that supplies them through ports. No class has a different pattern. | Uniform, testable. | happy |
| FR-024 | Class creation choices travel in `CreateCharacter` as a typed `ClassCreationChoices` carried by the class spec that defines them; the aggregate stores no class-specific field. | No hook proliferation. | happy |
| FR-025 | `ClassDefinition`, `SubclassDefinition`, `ProgressionRow`, `FeatureEntry` and bulk class and subclass data (all 12 classes, including the Evoker subclass) are owned by a new spec, `content-classes.md`. `class-*.md` specs own behaviour only. Primary-ability requirements are `AbilityRequirement`, sealed `AllOf` / `AnyOf`. | Nine specs referenced a class content spec that did not exist; Fighter's "or" needs `AnyOf`. | happy |

### 4.5 Combat wiring

| Id | Decision | Why | Path |
|---|---|---|---|
| FR-026 | `conditions.md` publishes a pure function `ConditionEffects` returning `RollContributions` (roll-mode sources, automatic failure, `AutomaticCritical`). `attacks.md` is pure: it takes `RollModifiers`, roll-mode sources and an `AutomaticCritical` input already computed. `combat-action-resolution.md` is the only place that calls both. | Attacks testable with plain values; no cycle. | happy |
| FR-027 | `attacks.md` defines no `Proficiency` type; the Proficiency Bonus arrives inside `RollModifiers` (FR-003). | Duplicated `ProficiencyBonus`. | unhappy (duplicate) |
| FR-028 | Cover (AC and Dexterity-save bonus) is owned by `attacks.md`. `derived-stats.md` does not compute it. | One owner. | happy |
| FR-029 | `grappling.md` owns grapple **mechanics** (the grapple option, escape, movement while grappling, ending the grapple, the `GrappleEnded` event). `conditions.md` owns only the Grappled **condition entry** (its effects row) and references `grappling.md`. `attacks.md` owns only the Unarmed Strike attack and references `grappling.md` for the grapple option. `encounter-aggregate.md` handles `GrappleEnded`. See FR-048 for the general rule. | Three-way split resolved; the topic-specific spec wins. | happy |

### 4.6 Content delivery

| Id | Decision | Why | Path |
|---|---|---|---|
| FR-030 | The JSON files under `data/srd_5_2_1/` are the source of truth. A generator in `tool/` writes **embedded Dart libraries of raw JSON strings**, one per content kind, under `lib/src/content/data/`. The embedded output is committed. | `dart:io` is forbidden in the core, and pure Dart packages cannot read assets at runtime; embedding stays platform-neutral. | happy |
| FR-031 | There is **one decode path**: embedded strings go through the same `ContentSetDecoder` as any host-supplied JSON. `BundledContentSource` is exported from `lib/adapters.dart`. | Bundled data exercises the real decoder; no second loader to test. | happy |
| FR-032 | A test regenerates the embedded libraries from `data/` and fails on any diff (drift check). Extraction tooling lives only in `tool/` and is never imported from `lib/`. | Source of truth stays authoritative. | unhappy (drift) |
| FR-033 | `NOTICE.md` covers exactly: `data/`, `lib/src/content/data/`, `test/fixtures/srd/`. SRD text in tests lives only under `test/fixtures/srd/`. `doc/research/` notes that hold SRD text are not distributed (`.pubignore`). | One covered-path list; CC-BY changes are indicated. | happy |
| FR-034 | There is **one** `schemaVersion` integer for the whole content format. The decoder accepts exactly the current version. `content-schema-and-decoder.md` owns a revision table. Other content specs request additions as rows there; none claims a version number. Before 0.1.0 all revisions land as one version. | Stops v2 collisions. | unhappy (version mismatch) |
| FR-035 | `content-schema-and-decoder.md` owns the envelope, ids, decoder and failure type. Each kind's shape is owned by its content spec (`Spell` by `content-spells.md`, and so on) and is registered in the revision table. | Stops "supersedes" disputes. | happy |

### 4.7 Ports, doubles and adapters

| Id | Decision | Why | Path |
|---|---|---|---|
| FR-036 | No-op implementations (`NoopLogger`, `NoopTracer`, `NoopMeter`, `NoopObservability`) are `const` classes in the port library itself, under `lib/src/shared_ports/`. They are not adapters. | `application` may not import `adapters/`, yet needs the default. | happy |
| FR-037 | `shared_ports/` may contain an `adapters/` folder for generic implementations (`SeededDiceRoller`). It depends only on `shared_kernel` and the port. Only `lib/adapters.dart` imports adapter folders. | One consistent rule. | happy |
| FR-038 | All test doubles live in `lib/src/testing/`, exported only by `lib/testing.dart`. Nothing else imports `lib/src/testing/`. Doubles may depend on ports, the kernel and context barrels. `FakeContentSource` is a double, not an adapter. | One place; layering clear. | happy |
| FR-039 | Contract suites live in `test/contract/` and are not exported (they would need `package:test` as a runtime dependency, which is forbidden). Documentation tells consumers how to reuse them. | Dependency rule. | happy |

### 4.8 Telemetry conventions shared by all specs

| Id | Decision | Why | Path |
|---|---|---|---|
| FR-040 | `ResolveD20Test` has one authority for signals: `resolve-d20-test-use-case.md`. `d20-tests.md` is domain-only and silent. | Two authorities disagreed. | unhappy (duplicate) |
| FR-041 | Attribute values: `srd5e.outcome` = `success` or `failure`; `srd5e.d20_test.kind` = `ability_check`, `saving_throw` or `attack_roll`; `srd5e.d20_test.roll_mode` = `normal`, `advantage` or `disadvantage`; `srd5e.d20_test.critical_hit` = `true` or `false` (attack rolls only); `error.type` = one constant per `Srd5eException` subtype, defined in `errors-and-results.md` as snake_case of the subtype name. | One set of values across metrics, spans and logs. | happy |
| FR-042 | Class features share one counter, `srd5e.character.feature_used`, with attributes `srd5e.class` and `srd5e.feature`. No per-feature metric names. | Bounded signal count. | happy |
| FR-043 | The d20 test emits no log (spans and metrics already cover it). | `observability.md` §7. | happy |

### 4.9 Further decisions (second consistency pass)

| Id | Decision | Why | Path |
|---|---|---|---|
| FR-044 | **A use case never calls another use case.** It composes pure domain services that upstream contexts publish in their barrels (`D20TestResolver` from `d20_test`), supplying dice and content through its own ports. Each use case records only its own signals, taking attribute values from the domain result. `attacks` therefore does not build a nested `ResolveD20Test` and does not use a silenced `Observability`. | No hidden nested telemetry, no double counting, and the domain service is testable with plain values. | unhappy (nested telemetry) |
| FR-045 | A new bounded context **`toolbox`** holds the Gameplay Toolbox rules (SRD pp. 192-203). It is downstream of `content`, `d20_test`, `character` and `combat` and no context depends on it, so the map stays acyclic. Its type phase is 5. It hands results back to the host (an Exhaustion level to apply, a condition to apply); it does not mutate character or combat state. Named catalogue entries (poisons, traps, contagions) are content kinds registered in the schema revision table; small rules tables are constants in the toolbox domain. Optional Game Master riders are explicit `ToolboxRuleOptions` fields in commands, never global flags. "Creating a Background" is a validation rule in `content-species-backgrounds-feats.md`, not a toolbox spec. | Nearly every modellable rule is "save, then damage / condition / Exhaustion", which needs `combat` types that `character` cannot import. | happy |
| FR-046 | The owning spec for the FR-005 vocabulary is `content-schema-and-decoder.md`: `DamageType`, `ConditionKind`, `Skill`, `CreatureSize`, `CreatureType`, `Language`, `RechargeTrigger`, `WeaponProperty`, `MasteryProperty` and every typed id including `MonsterId`. Bulk content specs reference them and define none. | `content-monsters.md` and `content-equipment.md` each re-defined some. | unhappy (duplicate) |
| FR-047 | Content **data** specs (`content-thin-slice`, `content-species-backgrounds-feats`, `content-equipment`, `content-spells`, `content-monsters`, `content-classes`, `content-magic-items`) depend only on `content-schema-and-decoder` and `content-source-port`, never on each other. The `toolbox-*` catalogue specs are behaviour specs (FR-045, FR-056), not bound by this rule; their entries are only data kinds in the schema revision table. Cross-references between data are by id, checked by the decoder's whole-set cross-reference validation, which `content-schema-and-decoder.md` owns. `BundledContentSource` is owned by `content-source-port.md`; each data spec adds its embedded library, and `content-thin-slice.md` supplies only the first entries. | Removes the data-spec cycle; keeps content testable one kind at a time. | unhappy (cycle) |
| FR-048 | **General ownership rule:** when two specs cover one topic, the topic-specific spec owns the mechanics and the broader spec keeps only its entry and a reference. (`grappling.md` over `conditions.md`; `heroic-inspiration.md` owns the mechanics while `character-aggregate.md` owns the state slot; `attack-and-help-actions.md` over `initiative-and-actions.md` for those actions; `magical-effects.md` and `spell-effects.md` over `spellcasting.md` and `content-spells.md` for effect resolution.) The broader spec's duplicate requirements become "Withdrawn: moved to X". | Prevents the parallel-drafting overlaps. | unhappy (overlap) |
| FR-049 | `isBloodied(currentHitPoints, HitPointMaximum)` is a pure function in `derived-stats.md`. `hit-points-and-damage.md` and the class specs reference it and define no other Bloodied predicate. | `character` cannot import the `combat` definition. | happy |
| FR-050 | The mechanical check that `NOTICE.md`'s covered paths equal the FR-033 list is owned by `architecture-guardrails.md` FR-079. `content-licensing-and-notice.md` defines the list and does not withdraw the check. | A delegation loop left no owner. | unhappy (no owner) |
| FR-051 | The rule amendments that specs mark "blocked" or "outstanding" are accepted as written, provided they weaken no MUST: `errors-and-results.md` OQ-5, OQ-9, OQ-11 and FR-043 (`Srd5eException` is a base type; record-and-rethrow exemption; a returned failure result carries no `error.type`), `observability-ports.md` FR-059 (async wrappers, closure-only attributes, `const` no-op exemption) and `combat-foundations.md` FR-032 / D-9. They are applied to the rule files in the same change, with fresh tags. | The specs depended on rule text the rules lacked. | happy |
| FR-052 | Cross-references are checked mechanically: every `<spec>.md FR-nnn` citation must name an existing spec and an FR id that exists and is not withdrawn. The check lives in `test/architecture/` (spec set) and is run before any spec change is accepted. | Dangling citations were the commonest drift. | unhappy (dangling reference) |

### 4.10 Third-pass decisions (ownership gaps, header meaning, size)

| Id | Decision | Why | Path |
|---|---|---|---|
| FR-053 | `content-schema-and-decoder.md` also owns these vocabulary types: `HitPointDie`, `LightLevel`, `DarknessKind`, `Obscurement`, `SpecialSense`, `Alignment`, `SourceCitation`, and the Creature Size and Space table as static facts of `CreatureSize` (SRD p. 14, p. 188). The specs that used them (`hiding-searching-and-senses`, `content-monsters`, `content-spells`, `exploration`, `magic-item-rules`, `derived-stats`, `rests-and-hit-dice`) reference them and define none. | These had no owner, a ghost owner, or two owners. | unhappy (duplicate) |
| FR-054 | Cross-reference validation is **whole-set**: after decoding, the decoder checks every id reference across the full content set. A reference site never opts out. The thin slice must be self-consistent (it may reference only ids it contains). Specs that said "sameDocument" or "the decoder must not check" change. | One rule; the first slice fails fast. | unhappy (dangling id) |
| FR-055 | `Srd5eException` and the port-failure guard helpers live in `shared_ports/errors/`. `dice-and-rolls.md` and any spec saying `shared_kernel/errors/` is corrected. The kernel throws only `ArgumentError`. | The kernel depends on nothing in the package. | unhappy (kernel dependency) |
| FR-056 | **"Depends on" means one thing:** the specs that must be implemented before this one can be, listed only as `` `name.md` `` tokens separated by commas, no prose in the cell. Consumers are never listed. A prose mention is not a dependency. Every dependency listed must have a **strictly lower rank** in section 4.11; `shared-types-and-ownership.md` (rank 0) is always allowed and need not be listed. Specs of rank 90 or higher may depend on any spec. | An acyclic graph by construction; checkable by script. | unhappy (cycle) |
| FR-057 | `rule-options.md` is a package-level spec defining only the option **pattern** (immutable value object, in the command, never global) and the shared rules. Each context's options are owned by its own spec: `CharacterRuleOptions` by `character-aggregate.md`, `CombatRuleOptions` by `combat-foundations.md`, `ToolboxRuleOptions` by `toolbox-hazard-effects.md`. | Removes the character-to-toolbox edge and phase inversion. | unhappy (forbidden edge) |
| FR-058 | `magic-item-rules.md` is a `character` spec (behaviour and state). The closed vocabulary and static tables it needs (rarity, category, attunement facts, Magic Item Resilience facts) move to `content-magic-items.md` as content types. Magic Item Resilience facts are recorded in `magic-item-rules.md`; `environment-hazards-and-objects.md` (Objects) references them. | Single context per spec; no content→character edge. | unhappy (mixed context) |
| FR-059 | `spell-effects.md` is split. The new `spell-effect-data.md` is a `content` spec (effect data model, facts, decoder shape, bundling, rank 7). `spell-effects.md` stays `combat` (resolver, use case, telemetry). Requirement ids stay with their current file where they are; `spell-effects.md` Q3's FR-to-part assignment says which ids move, and moved ids are marked withdrawn with the new owner id. | Mixed-context spec; its own Q3 asked for the split. | unhappy (mixed context) |
| FR-060 | New spec `monster-limited-use.md` (`combat`): Recharge X–Y, X/Day, Legendary Action timing and Lair actions (SRD pp. 254-257), as pure state-in/state-out rules over the monster stat block. Other unowned items: Armor Training Disadvantage (SRD pp. 92, 177) is owned by `equipment-rules.md` (rule) and applied in `derived-stats.md` (roll circumstances); the Creature Size and Space table is a static fact of `CreatureSize` (FR-053); "Rhythm of Play" and "Exceptions Supersede General Rules" (p. 5) are recorded in `rules-glossary-coverage.md` as narrative guidance with no requirement. | Closes the SRD ownership gaps. | happy |
| FR-061 | `architecture-guardrails.md` depends on every spec it verifies (rank 90). Other specs reference it in prose only. `observability-ports.md` therefore does not list it in "Depends on". | Removes the mutual dependency. | unhappy (cycle) |
| FR-062 | **Size discipline.** A spec stays under 600 lines. Withdrawn requirements are collapsed into one compact "Withdrawn ids" table at the end of section 4 (`| FR-nnn | Withdrawn: moved to <spec>.md (<id>) |`, one line each) and their test-plan rows are deleted. The test plan groups consecutive FR ids that share a level and a test file into one row. Section 9 lists only open questions; settled ones become one line citing the decision. A spec does not restate another spec's requirement; it cites it. Live FR ids are never changed or dropped. | The first reconciliation passes grew the specs to 63,000 lines. | unhappy (bloat) |
| FR-063 | Class specs do not define their own feature-use signals. They use the shared `srd5e.character.feature_used` counter and the shared `.duration` and `.errors` signals owned by `character-aggregate.md`, with attributes `srd5e.class` and `srd5e.feature`. The owner of emitting them is the use case (FR-023). `StrokeOfLuckUsed` and every character event implement `CharacterEvent` and carry `characterId`. | Nine class specs each re-declared signals. | unhappy (duplicate) |
| FR-064 | `content-schema-and-decoder.md` owns the content identity types `ContentId`, `ContentIdProblem`, `ContentKey`, `ContentKind`, `ContentEntry` and `MissingContent`. `content-source-port.md` keeps only the `ContentSource` port, `ContentSourceException` and its kind mapping, and depends on the schema. | The decoder used identity types from the port while the port listed the decoder: a real cycle. | unhappy (cycle) |
| FR-065 | `DurationUnit` is a vocabulary type owned by `content-schema-and-decoder.md` (FR-149). `content-spells.md` and the toolbox specs use it and define none. | `toolbox-poison` and `toolbox-traps` imported it from a data spec. | unhappy (duplicate) |
| FR-066 | A class spell list is derived in `content-spells.md` from `Spell.classes`. `content-classes.md` defines no `ClassSpellListMember` interface and asks nothing of `content-spells.md`. | Avoids content-spells importing content-classes. | unhappy (cycle) |
| FR-067 | FR-047 is amended: a **bundle** spec at rank 7 (`content-classes-data`) may depend on the rank 6 data specs it validates against. A rank 6 data spec never depends on another rank 6 spec; the check that species data needs spell data is part of whole-set validation (FR-054), not a spec dependency. | `content-species-backgrounds-feats` and the class data needed cross-checks. | unhappy (cycle) |

### 4.11 Spec rank table

A spec's "Depends on" may list only specs of strictly lower rank (FR-056).

| Rank | Specs |
|---|---|
| 0 | `shared-types-and-ownership` |
| 1 | `errors-and-results` |
| 2 | `dice-and-rolls`, `modifiers-and-advantage`, `ability-scores` |
| 3 | `observability-ports`, `rule-options` |
| 4 | `d20-tests`, `content-schema-and-decoder` |
| 5 | `resolve-d20-test-use-case`, `content-source-port`, `content-licensing-and-notice` |
| 6 | `content-thin-slice`, `content-classes`, `content-species-backgrounds-feats`, `content-equipment`, `content-spells`, `content-monsters`, `content-magic-items` |
| 7 | `spell-effect-data`, `content-classes-data` |
| 9 | `equipment-rules` |
| 10 | `derived-stats` |
| 11 | `character-aggregate` |
| 12 | `rests-and-hit-dice`, `heroic-inspiration`, `weapon-properties-and-mastery`, `social-interaction`, `exploration` |
| 13 | `spellcasting`, `magic-item-rules` |
| 14 | `level-advancement-and-multiclassing`, `casting-and-concentration`, `magic-item-effects`, `tool-proficiency-and-crafting` |
| 15 | `feats-behaviour`, `higher-level-start-equipment-and-trinkets`, `spell-scroll-use` |
| 16 | `character-creation`, `wish-spell` |
| 17 | `class-barbarian`, `class-bard`, `class-cleric`, `class-druid`, `class-fighter`, `class-monk`, `class-paladin`, `class-ranger`, `class-rogue`, `class-sorcerer`, `class-warlock`, `class-wizard`, `species-trait-behaviour` |
| 18 | `class-wizard-evoker` |
| 20 | `combat-foundations` |
| 21 | `hit-points-and-damage` |
| 22 | `conditions` |
| 23 | `grappling`, `hiding-searching-and-senses`, `environment-hazards-and-objects`, `telepathy` |
| 24 | `attacks`, `attack-and-help-actions`, `mounted-and-underwater-combat`, `deployed-and-restraining-gear`, `monster-engulf-and-swallow` |
| 25 | `initiative-and-actions`, `item-use-effects` |
| 26 | `monster-limited-use`, `magical-effects`, `movement-lifting-and-flight`, `grid-positions-and-movement`, `readying-a-spell`, `monster-combatant-setup` |
| 27 | `spell-effects`, `returning-to-life`, `monster-stat-block-actions`, `monster-traits`, `monster-spellcasting` |
| 28 | `encounter-aggregate`, `active-effects`, `spell-granted-modifiers`, `persistent-spell-zones`, `dispel-and-counterspell`, `shape-changing-spells`, `revival-and-restoration-spells`, `spell-outcome-tables` |
| 29 | `combat-action-resolution` |
| 30 | `combatant-roster-changes` |
| 31 | `summoned-and-companion-creatures` |
| 40 | `toolbox-hazard-effects` |
| 41 | `toolbox-travel-pace`, `toolbox-environmental-effects`, `toolbox-poison`, `toolbox-traps`, `toolbox-curses-and-contagions`, `toolbox-fear-and-mental-stress`, `toolbox-combat-encounter-difficulty` |
| 90 | `architecture-guardrails` |
| 91 | `rules-glossary-coverage` |
| 99 | `release-0-1-0` |

## 5. Model

Rule-file amendments made together with this spec (read-receipt tags replaced):

- `architecture.md` §1: `shared_ports/` may hold `adapters/`; no-ops are in the
  port library; `lib/src/testing/` exists (FR-036–FR-038). §2: `content` owns
  closed vocabulary types (FR-005). §4: use cases return `<UseCase>Result` with
  operation-prefixed variants (FR-017). §9: guardrail updates.
- `observability.md` §4: no-op defaults are `const` and live with the port; the
  attribute value sets in FR-041 are the shared convention.
- `testing.md` §10: contract suites are not exported (FR-039).

`AGENTS.md` and `doc/roadmap.md` are updated to match (class data in Phase 3,
type-phase rule FR-014, specs list).

## 6. Interface

None of its own. Consumers of this spec are the other specs, which cite it as
`shared-types-and-ownership.md FR-nnn`.

## 7. Observability

Silent by design: this spec defines conventions, not code. FR-041 and FR-042 fix
attribute values and names so every spec's signal table agrees. Failure mode of
the conventions: two specs defining the same signal differently; the guardrail
check on `doc/observability/signals.md` consistency catches it.

## 8. Test plan

| Id | Level | Notes |
|---|---|---|
| FR-013, FR-015, FR-016, FR-038 | architecture | Import-direction and cycle checks in `test/architecture/` |
| FR-017, FR-021 | architecture | Barrel scan fails on generic variant names and duplicate exported names |
| FR-030–FR-033 | architecture + unit | Drift check; NOTICE path list; no `tool/` imports from `lib/` |
| FR-034 | unit | Decoder rejects any other `schemaVersion` |
| FR-036, FR-037 | architecture | Folder and import rules |
| FR-001–FR-012, FR-014, FR-018–FR-029, FR-035, FR-039–FR-067 | doc review | Verified by the spec-consistency critic; ownership table in §9 is the checklist |

## 9. Open questions and decisions

All questions raised by the consistency review are settled above. None open.

## 10. Changelog impact

None (no code yet). The first code change records the decisions it implements.
