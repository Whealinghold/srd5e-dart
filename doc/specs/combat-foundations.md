# Combat foundations

| | |
|---|---|
| Status | draft |
| Context | `combat` |
| Roadmap phase | 4 |
| Depends on | `errors-and-results.md`, `observability-ports.md`, `content-schema-and-decoder.md`, `character-aggregate.md` |
| Deviations from the decisions | None. |

## 1. Purpose and scope

Rank 20, the leftmost spec of the `combat` order (`shared-types-and-ownership.md` FR-015); it depends on no other `combat` spec. Prose dependencies (the header lists only lower-rank specs, FR-056): `CharacterId` from the `character` barrel (`character-aggregate.md`); `MonsterId` from the `content` barrel (`content-schema-and-decoder.md`, FR-114); `error.type` and the scalar `tryCreate` factories of `errors-and-results.md` (FR-043, OQ-11); `Observability`, `NoopObservability`, `AttributeKeys` of `observability-ports.md`; the kernel marker `DomainEvent` (FR-001). `shared-types-and-ownership.md` is called "decisions" below. It applies decisions FR-012, FR-015, FR-017, FR-019, FR-021, FR-041, FR-044, FR-046, FR-051.

The earlier `combat` specs each assumed something different about who a combatant is, what an event is and how signals are named. This spec is the one owner of:

1. `CombatantId`, the typed id of a creature in a fight.
2. `CombatantKind` (which character or monster) and `CombatantRef` (id plus kind).
3. `CombatEvent`, the base of the combat event family (implements `DomainEvent`).
4. Naming conventions for commands, results, rejections and events in the `combat` barrel.
5. The `srd5e.combat.*` observability conventions: shared signals, shared attributes, result-to-outcome mapping.
6. `CombatRuleOptions` and `PlayingOnAGrid` (section 4.6; decisions FR-057; pattern in `rule-options.md`).

**Out of scope:**

- Any rule. Hit points, conditions, turn state and side belong to specs to the right; `Side`, `Combatant` and `EncounterId` stay in `encounter-aggregate.md`.
- Assigning ids: the host supplies every `CombatantId`; the package never generates one (no randomness or clock in the domain).
- Anything about a creature that is not an SRD 5.2.1 fact. The SRD names participants ("each participant in a battle", "The Order of Combat", p. 13) but defines no combatant record; these types are package design. Whether a combatant is a Player Character or a Monster is identity only; no rule reads it.
- Movement costs on a grid and range counting (p. 13): `initiative-and-actions.md` keeps feet; `grid-positions-and-movement.md` FR-001 reads `CombatRuleOptions.grid` and owns grid rules; FR-042 to FR-045 hold only the grid choice and the feet-to-squares conversion.
- Tracking an object or location as a creature (`attacks.md` defines no `AttackTarget`).

## 2. Source

- SRD 5.2.1, "The Order of Combat" and "Combat Step by Step", p. 13.
- SRD 5.2.1, "Playing on a Grid" sidebar ("If you play using a square grid"; "Squares. Each square represents 5 feet"; "Speed ... dividing it by 5"), p. 13; "Round Down", p. 5.
- SRD 5.2.1, Rules Glossary, "Player Character", p. 186, and "Monster", p. 185.
- Package design: `doc/rules/architecture.md` §2, §3, §4, §6; `doc/rules/observability.md` §2, §5-§7; `doc/rules/testing.md` §4-§5; `shared-types-and-ownership.md`.

## 3. Vocabulary

| SRD term | Type | Notes |
|---|---|---|
| (combatant identity) | `CombatantId` (extension type over `String`) | Not an SRD term ("combatant", "participant", p. 13). No `CreatureId`, `ParticipantId` or `TargetId` exists. |
| Player Character / Monster | `CombatantKind` (sealed): `PlayerCharacterCombatant(CharacterId)`, `MonsterCombatant(MonsterId)` | "Player Character", p. 186; "Monster", p. 185. Identity only. Variant names avoid `Monster` and `PlayerCharacter`, which `content` and `character` own. |
| (combatant reference) | `CombatantRef` (`id`, `kind`) | Not an SRD term. What a host gives the engine to introduce a combatant. |
| (combat event) | `CombatEvent` (`abstract interface class`, implements `DomainEvent`) | Base of every combat domain event (decisions FR-019, D-1). |
| (event kind) | `CombatEvent.kind` (`String`) | Constant `snake_case` name per event class (an envelope reports the wrapped event's, FR-038); the value of `srd5e.combat.event`. Not display text. |
| (event envelope) | an `...Occurred` event marked `TransportEnvelope` | Past-tense event wrapping another spec's event for transport (FR-038). |
| (envelope marker) | `TransportEnvelope` (`abstract interface class`, `domain/`, not exported) | Declared once here; only envelopes implement it. |
| (use case name) | `CombatOperation` | The `srd5e.combat.operation` value and span-name suffix. |
| (result class) | `CombatResultClass` (`applied`, `refused`, `invalid`) | Classifies every result variant for telemetry (FR-031). |
| Playing on a Grid | sealed `PlayingOnAGrid`: `NoGrid`, `SquareGrid` | p. 13. Default `NoGrid` (the SRD baseline; a package term). `SquareGrid` is named from the SRD's "Squares" entry. |
| Speed | `int` feet | Converted to squares by `SquareGrid` (p. 13). |

Terms use SRD 5.2.1 wording (`doc/rules/architecture.md` §3).

## 4. Requirements

Stable ids. Never renumber. One behaviour each.

### 4.1 `CombatantId`

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-001 | `CombatantId` MUST be an extension type over `String`, defined once in `combat` and exported from the `combat` barrel and `lib/srd5e.dart`. No other `combat` spec defines an id for a creature in a fight. | `shared-types-and-ownership.md` FR-012; architecture §3 | happy |
| FR-002 | The `CombatantId` constructor MUST accept any string for which `value.trim().isEmpty` is false (Dart's `trim` removes `\r`, no-break space and the Unicode space separators as well as space, tab, newline) and MUST expose it unchanged as `value`. `CharacterId` and `EncounterId` are to use the same predicate so the three id types agree on blank (D-7); `character-aggregate.md` FR-002 and `encounter-aggregate.md` FR-001 say only "whitespace", and their owners are asked to pin it. | architecture §3 | happy |
| FR-003 | The `CombatantId` constructor MUST throw `ArgumentError` for the empty string. | architecture §6 | unhappy (invalid input) |
| FR-004 | The `CombatantId` constructor MUST throw `ArgumentError` for a blank string (`value.trim().isEmpty`): only space, tab, newline, `'\r'` or `'\u00A0'` (no-break space), in any mix. | architecture §6 | unhappy (boundary) |
| FR-005 | `CombatantId.tryCreate` MUST return `CombatantIdParsed(id)` for a string the constructor accepts and `CombatantIdRejected(CombatantIdRejection.empty)` for one it rejects. It MUST NOT throw for any string, and MUST return a rejection if and only if the constructor throws for the same string. | `errors-and-results.md` FR-025, FR-035; architecture §6 | unhappy (invalid input) |
| FR-006 | A `CombatantId` MUST NOT normalise its value: no trimming, no case folding. `CombatantId('Goblin 1')`, `CombatantId('goblin 1')` and `CombatantId(' Goblin 1')` MUST be three different ids. | architecture §3 | unhappy (boundary) |
| FR-007 | Two `CombatantId`s built from equal strings MUST be equal with equal hash codes; different strings MUST differ. | architecture §3 | happy |
| FR-008 | A `CombatantId` MUST NOT be assignable where an `EncounterId`, `CharacterId` or `MonsterId` is expected, or the reverse. Static property verified by an analyzer fixture (section 8), not a runtime test; runtime equality across id types is unspecified and no code may rely on it. | architecture §3, §10 | unhappy (invalid input) |
| FR-009 | The package MUST NOT generate `CombatantId`s. No `combat` file under `lib/src/` may use `Random(` or import a uuid package, and no static or top-level function, factory or constructor may return a `CombatantId` other than `CombatantId(...)` and `CombatantId.tryCreate`. Uniqueness within one fight is the host's responsibility, checked by the encounter (`DuplicateCombatantId`, `encounter-aggregate.md`). | architecture §3, §9 | unhappy (determinism) |

### 4.2 Combatant reference types

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-010 | `CombatantKind` MUST be a sealed class with exactly two variants, `PlayerCharacterCombatant` (carrying a `CharacterId`) and `MonsterCombatant` (carrying a `MonsterId`), so a `switch` is exhaustive. | SRD 5.2.1, "Player Character", p. 186; "Monster", p. 185 | happy |
| FR-011 | Each `CombatantKind` variant MUST be immutable and equal by value: the same variant with an equal reference id is equal with an equal hash code; a different variant or reference id MUST NOT be equal, even when the underlying strings match. | architecture §3 | unhappy (boundary) |
| FR-012 | A `CombatantKind` MUST carry identity only. Its variants' only public members MUST be the reference id, equality and `hashCode`; no rule, predicate or behaviour is attached. | `encounter-aggregate.md`; architecture §3 | happy |
| FR-013 | `CombatantRef(id, kind)` MUST be an immutable value object equal by value over both fields. Two refs with the same `CombatantId` and different kinds MUST NOT be equal. | architecture §3 | unhappy (rule interaction) |
| FR-014 | `CombatantKind` MUST NOT reference `Side`, hit points, conditions or any other `combat` type. The reference types MAY import `dart:core`, `package:meta`, the `character` and `content` barrels, `shared_kernel` and this context's own `domain/` files. They MUST NOT import another `combat` spec's files, `d20_test`, `toolbox` (a downstream leaf: `architecture.md` §2, `architecture-guardrails.md` FR-098), or a non-barrel file of another context. | `shared-types-and-ownership.md` FR-013, FR-015 | unhappy (forbidden edge) |

### 4.3 The `CombatEvent` family

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-015 | `CombatEvent` MUST be an `abstract interface class` implementing `DomainEvent`, declaring `String get kind` and `List<CombatantId> get combatants`, defined once here and exported from the `combat` barrel. It is not `sealed` because Dart requires the direct subtypes of a sealed class to share a library (D-1). | `shared-types-and-ownership.md` FR-001, FR-019 | happy |
| FR-016 | Every domain event exported by the `combat` barrel MUST implement `CombatEvent` through exactly one sealed sub-family owned by one spec (`HitPointEvent`, the condition events, `EncounterEvent`, ...), so a consumer's `switch` over a sub-family is exhaustive. An architecture test lists the implementers of `CombatEvent` and fails on one that implements it directly or is not in a sealed sub-family. An envelope (FR-038) is a member of its owning spec's sealed family (for example `EncounterEvent`, `encounter-aggregate.md` FR-050), never a direct implementer. | `shared-types-and-ownership.md` FR-019 | happy |
| FR-017 | For every non-envelope `CombatEvent` implementer, `kind` MUST be a compile-time constant per class, match `[a-z][a-z0-9_]*`, and be unique across the package's `CombatEvent` implementers (`CharacterEvent` and class events have no `kind` and are out of this rule). An envelope reports the wrapped event's dynamic `kind`, so it is exempt from the constant rule and uniqueness (FR-038). Equal events MUST report equal kinds. `kind` MUST NOT be derived from `runtimeType` or `toString()`. | observability §5; `errors-and-results.md` FR-034 | unhappy (name collision) |
| FR-018 | `CombatEvent.combatants` MUST be an unmodifiable list of the creatures the event is about, in a deterministic order its defining spec documents, empty only for an event about no creature (for example a round starting), with no duplicates. | architecture §4 | unhappy (boundary) |
| FR-019 | Every `CombatEvent` implementer MUST be annotated `@immutable`, have only `final` fields, and be equal by value including `kind` and `combatants`. Events carry no timestamp and no display text. | architecture §3, §6 | unhappy (immutability) |
| FR-020 | An event MUST be named in the past tense and state a fact that happened. It MUST NOT end in `Required` or `Needed`, and MUST NOT end in `Due` unless the word before `Due` is `Became` (the pattern `(?<!Became)Due$\|Required$\|Needed$` fails). A spec that must tell the host something is due names the happening: `...BecameDue` (`MovementSpeedsReviewBecameDue`, `GrappleCheckBecameDue`, both in `combat-action-resolution.md`) or the causing fact (`DyingCombatantTurnStarted`, `encounter-aggregate.md` FR-018, which replaced `DeathSavingThrowDue`). A transport wrapper MAY end in `Occurred` and follows FR-038. Each named event has exactly one defining spec. | architecture §3; `shared-types-and-ownership.md` FR-019 | happy |
| FR-021 | A transition result MUST hold its events as an unmodifiable `List<CombatEvent>` (or the owning sub-family type), in the order they happened. Adding to it MUST throw `UnsupportedError`. | architecture §3, §4; `encounter-aggregate.md` FR-050 | unhappy (immutability) |

### 4.4 Naming conventions in the `combat` barrel

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-022 | Every `combat` use case MUST take a command named `<UseCase>Command` and return a sealed `<UseCase>Result`. Variants MUST be prefixed with the operation noun (`DamageApplied`, `DamageRejected`, `StartEncounterInvalid`). A generic name (`Applied`, `Rejected`, `Succeeded`, `Invalid`, `ContentMissing`, `Found`, `NotFound`) MUST NOT be exported from the `combat` barrel. | `shared-types-and-ownership.md` FR-017; architecture §4, §9 | unhappy (name collision) |
| FR-023 | A reason a use case refuses or rejects MUST be a value object or enum named `<Subject>Rejection` (or `<Subject>Problem` for a list), held as a field of the `<Operation>Rejected` or `<Operation>Invalid` variant, not a variant of a result shared across use cases. Exception (reason is a domain refusal, class `refused`, not invalid input): `AttackNotPossible` and `UnarmedStrikeNotPossible` (`attacks.md` FR-120) keep the `...NotPossible` suffix and hold an `AttackNotPossibleReason`; `combat-action-resolution.md` consumes the names. | `shared-types-and-ownership.md` FR-018; architecture §4 | happy |
| FR-024 | Every name exported by the `combat` barrel MUST be unique across the package barrels. The in-context order is the rank table `shared-types-and-ownership.md` 4.11 (ranks 20 to 29); a `combat` spec MAY depend only on strictly lower ranks (FR-056), so equal-rank specs never depend on each other. Where two `combat` specs named the same thing, the lower-rank spec keeps the plain name and the higher uses an `...ToCombatant`, `...OnSet` or similar qualified form; at equal rank the spec file name that sorts first alphabetically keeps it. A new `combat` spec takes its rank from the table (changing the table changes the decisions). `architecture-guardrails.md` FR-091 is kept in sync. | `shared-types-and-ownership.md` FR-015, FR-021, 4.11 | unhappy (name collision) |
| FR-025 | Names this spec reserves MUST NOT be defined by any other spec: `CombatantId`, `CombatantIdParse`, `CombatantIdParsed`, `CombatantIdRejected`, `CombatantIdRejection`, `CombatantKind`, `PlayerCharacterCombatant`, `MonsterCombatant`, `CombatantRef`, `CombatEvent`, `CombatOperation`, `CombatResultClass`, `CombatTelemetry`, `CombatSignals`, `TransportEnvelope`. | `shared-types-and-ownership.md` FR-012 | unhappy (duplicate) |
| FR-026 | A `combat` spec MUST NOT import, list or assume a type from a `combat` spec of equal or higher rank (FR-024), or from `toolbox`. It MAY use only the barrels of `character`, `d20_test` and `content`: their published language (value objects, ids, events) in `domain/`, and that plus the domain services their barrels export (for example `D20TestResolver`) in `application/` (`architecture.md` §1, `shared-types-and-ownership.md` FR-044). It MUST NOT import another context's use cases or non-barrel files. | `shared-types-and-ownership.md` FR-013, FR-015, FR-044; architecture §1, §2 | unhappy (cycle) |

### 4.5 Observability conventions

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-027 | Every combat-specific signal name and attribute key MUST begin `srd5e.combat.`, be lowercase, dot-separated, and be a constant in one library, `CombatSignals` (FR-039). Exempt: the shared keys `AttributeKeys.outcome` and `AttributeKeys.errorType` (`observability-ports.md` FR-052), which `CombatSignals` MUST NOT re-declare or contain as a literal; and keys owned by another context's signals (`srd5e.d20_test.*`, `srd5e.ability`), which `combat` code reads from the constants that context's barrel exports (for `d20_test`, `D20TestSignals`: `resolve-d20-test-use-case.md` FR-040, FR-042), never as a literal and never re-declared in `CombatSignals`. Later `combat` specs add their constants to `CombatSignals` and their rows to the catalogue; no call site uses a string literal. | observability §5, §10 | unhappy (invalid input) |
| FR-028 | The operation attribute MUST be `srd5e.combat.operation`, whose value is the `snake_case` use-case name (`apply_damage`, `advance_tracker_turn`). `CombatOperation` MUST reject a value not matching `[a-z][a-z0-9_]*`, and a span name not ending in `.` followed by the value (FR-040). This key replaces `srd5e.combat.use_case`, `srd5e.operation` and `srd5e.combat.condition.operation`. | observability §5 | unhappy (invalid input) |
| FR-029 | Every `combat` use case MUST run inside one span named `srd5e.combat.<operation>`. When the work returns a result it MUST record exactly once the counter `srd5e.combat.operations` (`{operation}`) and, per event produced, the counter `srd5e.combat.events` (`{event}`, attribute `srd5e.combat.event` = the event's `kind`; FR-038 for envelopes). It MUST record the histogram `srd5e.combat.operation_duration` (`s`, through the `Meter` timing operation) exactly once per call, whether the work returns or throws. **Throw path:** `operations` is **not** incremented and no `events` are counted (no result exists to classify); the call is counted by `srd5e.combat.errors` (FR-032) for an `Srd5eException` and by the span only for an `Error`. Extras from the `attributes` argument (FR-041) go on the span and the `operations` increment only. Use-case-specific signals are added by their owning spec and MUST NOT repeat these. | observability §4-§6 | happy |
| FR-030 | The shared attributes (a closed list; more only through FR-041) are: `srd5e.combat.operation` (FR-028); `srd5e.outcome` (`success` or `failure` only, `shared-types-and-ownership.md` FR-041); `srd5e.combat.result` (a closed `snake_case` set per use case, owned by that spec; each value names one reason or outcome and maps to exactly one `CombatResultClass`, for example `damaged`, `killed`, `rejected_dead`, `not_dying`; not derived from the variant class name, finer than `result_class`; `CombatTelemetry.run` obtains it from the caller's `resultName` and `classify`); `srd5e.combat.result_class` (`applied`, `refused`, `invalid`); `srd5e.combat.event` (an event `kind`); `error.type` (only on `srd5e.combat.errors`). A spec MUST NOT add a value to `srd5e.outcome` or `srd5e.combat.result_class`. Each `srd5e.combat.result` value is a `...Value` constant added to `CombatSignals` by its owning spec (FR-039); the `srd5e.outcome` and `result_class` values come from `CombatSignals` `...Value` constants (`CombatResultClass.outcome` returns them). | `errors-and-results.md` FR-043; observability §5 | unhappy (boundary) |
| FR-031 | Every result value of every `combat` use case MUST be classified as one `CombatResultClass`. `applied` records `srd5e.outcome` = `success` and no error status. `refused` (legal input the rules do not allow in the current state: a dead creature making a death saving throw, the wrong combatant's turn, nothing to stabilise) records `failure` and **no** error status, being a normal rule outcome. `invalid` (host input the engine cannot use: an unknown combatant, a malformed start, a rejected tie-break) records `failure` and sets the span error status. `CombatResultClass` MUST expose `outcome` and `isSpanError` so no use case re-derives them. | observability §6, §7; `errors-and-results.md` FR-043 | unhappy (rule interaction) |
| FR-032 | `srd5e.combat.errors` (`{error}`) MUST count only a thrown `Srd5eException` from a port, once, with `srd5e.combat.operation` and `AttributeKeys.errorType` (`errors-and-results.md` FR-034). `CombatTelemetry` only increments this counter; span status and the recorded exception come from `Tracer.trace` (`observability-ports.md` FR-012) and `CombatTelemetry` MUST NOT call `Span.recordError`. "Once" holds because no use case calls another (`shared-types-and-ownership.md` FR-044), so each failure leaves exactly one `CombatTelemetry`. A `refused` or `invalid` result MUST NOT increment it and MUST NOT be given an `error.type`; it is counted by `srd5e.combat.operations` with its `result_class` (D-9). | `errors-and-results.md` FR-034, FR-043, OQ-11; `observability-ports.md` FR-012; observability §5, §7; `shared-types-and-ownership.md` FR-044, FR-051 | unhappy (failure) |
| FR-033 | No `combat` attribute may carry a combatant id, `CharacterId`, `MonsterId`, an amount, or free text. Event kinds, operations, result names and every value passed through `attributes` (FR-041) are closed sets. | observability §5 | unhappy (invalid input) |
| FR-034 | `combat` use cases MUST NOT log a rule outcome, refusal or invalid input at `INFO` or above; the span, counter and result record it (observability §7). A spec needing a `WARNING` (a handled fallback) declares it in its own table. | observability §7 | unhappy (telemetry) |
| FR-035 | `CombatTelemetry` MUST be the one helper through which `combat` use cases record FR-029 to FR-032. It takes an `Observability` (default `NoopObservability`), wraps the work in the span, times it, classifies the result with a caller-supplied function, applies the optional extras (FR-041), counts events, and for a thrown `Srd5eException` increments `srd5e.combat.errors` once (FR-032) and rethrows the same object (the span records it once, `Tracer.trace`'s job). A thrown `Error` MUST propagate unchanged, the span recording it and no `errors` increment. | observability §3, §4, §9; architecture §6 | happy |
| FR-036 | With the no-op and with the recording `Observability`, a use case run through `CombatTelemetry` MUST return equal results. | observability §9 | happy |
| FR-037 | `doc/observability/signals.md` MUST NOT list the names this spec supersedes (section 5). The shared names `srd5e.combat.operations`, `srd5e.combat.operation_duration`, `srd5e.combat.errors` and `srd5e.combat.events` each have exactly one catalogue row, owned by this spec (`architecture-guardrails.md` FR-044). A later spec needing extra attributes on a shared signal lists its extra keys and closed values in its own section 7 prose or extras table (no `Name` repeating a shared name) and in the Attributes cell of the shared row here, never a second row. Each per-operation span `srd5e.combat.<operation>` has one catalogue row, owned by its use-case spec (FR-040). | observability §10; `architecture-guardrails.md` FR-042 to FR-044 | unhappy (duplicate) |
| FR-038 | An event wrapping another spec's event for transport (an `...Occurred` envelope) MUST implement `TransportEnvelope` (`abstract interface class` in `lib/src/combat/domain/`, not exported) and MUST report the wrapped event's `kind` and `combatants` from its getters. `CombatTelemetry` counts it as that one wrapped event, once, under the wrapped `kind` (for example `tracker_round_started`). An envelope is exempt from FR-017's constant and uniqueness rules, still belongs to its owning spec's sealed family (FR-016), and its class name never appears as a `kind`. Architecture tests recognise envelopes by the marker and check the marked set equals the envelopes the owning spec names (for `encounter-aggregate.md`: `TurnEventOccurred`, `HitPointEventOccurred`, `ConditionEventOccurred`, `GrappleEventOccurred`). | `encounter-aggregate.md` FR-050, FR-084; observability §5 | unhappy (rule interaction) |
| FR-039 | `CombatSignals` MUST be an `abstract final class` in `lib/src/combat/application/combat_signals.dart`, with only `static const String` members named with a suffix `Metric`, `Span`, `LogEvent`, `Attribute` or `Value` (`architecture-guardrails.md` FR-037). This spec declares: `operationsMetric` (`srd5e.combat.operations`), `operationDurationMetric` (`srd5e.combat.operation_duration`), `errorsMetric` (`srd5e.combat.errors`), `eventsMetric` (`srd5e.combat.events`); `operationAttribute` (`srd5e.combat.operation`), `resultAttribute` (`srd5e.combat.result`), `resultClassAttribute` (`srd5e.combat.result_class`), `eventAttribute` (`srd5e.combat.event`); `resultClassAppliedValue` (`applied`), `resultClassRefusedValue` (`refused`), `resultClassInvalidValue` (`invalid`) (each with a doc comment naming `srd5e.combat.result_class`); `outcomeSuccessValue` (`success`), `outcomeFailureValue` (`failure`) (doc comment naming `srd5e.outcome`; the key is `AttributeKeys.outcome`, FR-027). `CombatResultClass.outcome` MUST return these two constants and `CombatTelemetry` MUST record `result_class` from the three `resultClass...Value` constants. Later specs add their own `...Value` constants for `srd5e.combat.result` (FR-030) and operation constants (FR-040). | `architecture-guardrails.md` FR-037, FR-085; observability §5 | happy |
| FR-040 | `CombatOperation(String value, {required String spanName})` MUST hold the `snake_case` value and its span name; `CombatTelemetry` uses `spanName` as given, never by concatenation. For each operation the owning spec adds to `CombatSignals` a pair `<operation>OperationValue` (doc comment naming `srd5e.combat.operation`) and `<operation>Span` (`srd5e.combat.<operation>`), and one catalogue row for the span, so every catalogue Name equals a signal constant (`architecture-guardrails.md` FR-042, FR-043). The constructor throws `ArgumentError` when `spanName` does not end in `.` followed by `value`; an architecture test checks every `...OperationValue` has a `...Span` of `srd5e.combat.` plus it, and the reverse. | `architecture-guardrails.md` FR-042, FR-043; observability §5 | unhappy (invalid input) |
| FR-041 | `CombatTelemetry.run` MUST accept an optional `Map<String, Object> Function(R)? attributes`. Its entries MUST be added to the span and the `srd5e.combat.operations` increment of that call, and nothing else (not `operation_duration`, `errors` or `events`). Every key MUST be a `CombatSignals` `...Attribute` constant starting `srd5e.combat.`, or a key owned by another context's signals under FR-027; every value MUST come from a closed, low-cardinality set (FR-033). An entry whose key is a shared attribute of FR-030 MUST throw `ArgumentError`. A use case omits an extra that does not apply (no d20 rolled) by leaving the key out. The owning spec lists its extra keys and values (FR-037). Registered extras, all `CombatSignals` `...Attribute` constants: `srd5e.combat.roster_reason` (`summoned`, `arrived`, `fled`, `surrendered`, `disappeared`, `departed`, `repositioned`; `combatant-roster-changes.md` FR-043, with its three operation constants and spans per FR-040); `srd5e.combat.spell_table` (`teleport`, `confusion`, `prismatic_spray`, `prismatic_wall`, `reincarnate`, `blink`; `spell-outcome-tables.md` FR-101); `srd5e.combat.monster_hit_points_method` (`average`, `rolled`; `monster-combatant-setup.md` FR-049); `srd5e.combat.damage_notation` (`number`, `dice`, `mixed`; `monster-stat-block-actions.md` FR-047). `srd5e.combat.summon_kind` (`animated_object`, `giant_insect`, `draconic_spirit`, `otherworldly_steed`, `animated_undead`, `created_undead`, `familiar`, `simulacrum`) and `srd5e.combat.summon_end_cause` (`dropped_to_zero_hit_points`, `spell_ended`, `summoner_died`, `long_rest_finished`, `dismissed_forever`, `dismissed_temporarily`, `replaced`, `control_lapsed`) are attributes of the owner's own counters `summons` and `summon_endings` (`summoned-and-companion-creatures.md` section 7), not of `operations`. | `attacks.md` FR-116, FR-118; `mounted-and-underwater-combat.md` FR-061; observability §5 | unhappy (boundary) |

### 4.6 `CombatRuleOptions`

Moved here from `rule-options.md` (decisions FR-057); follows that spec's pattern and shared rules (FR-023, FR-029, FR-033, FR-034). The one option is the SRD sidebar "Playing on a Grid" (p. 13). `grid-positions-and-movement.md` FR-001 reads `grid` (an exhaustive `switch` yields the `SquareGrid` its operations take), so `CombatRuleOptions` and `PlayingOnAGrid` (`NoGrid`, `SquareGrid`) are exported from the `combat` barrel and `lib/srd5e.dart` (`rule-options.md` FR-029).

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-042 | `CombatRuleOptions` MUST hold one field, `grid` (`PlayingOnAGrid`), and have a `const` constructor. `CombatRuleOptions.standard` MUST be a `const` value using `NoGrid`. Equality and `hashCode` MUST be by value on `grid`; `copyWith({PlayingOnAGrid? grid})` MUST return a new instance changing only the supplied field and leave the original unchanged. It has no invalid state: no `tryCreate`, no result type. | SRD 5.2.1, "Playing on a Grid", p. 13; architecture.md §3 | happy / unhappy (rule interaction) |
| FR-043 | `PlayingOnAGrid` MUST be a sealed type with exactly two variants, `NoGrid` and `SquareGrid`, each a `final class` and a `const` value-equal instance. | SRD 5.2.1, "Playing on a Grid", p. 13 | happy |
| FR-044 | `SquareGrid.feetPerSquare` MUST be 5. `SquareGrid.speedInSquares(feet)` MUST return `feet` divided by 5, rounded down (table below). | SRD 5.2.1, "Playing on a Grid", "Squares" and "Speed", p. 13; "Round Down", p. 5 | happy / unhappy (boundary) |
| FR-045 | `SquareGrid.speedInSquares` MUST throw `ArgumentError` for a negative number of feet. | architecture.md §6 | unhappy (invalid input) |

`SquareGrid.speedInSquares` (FR-044). Each row is one table-driven test.

| Label | feet | Expected | Source | Path |
|---|---|---|---|---|
| the SRD's own example | 30 | 6 | p. 13 | happy |
| zero Speed | 0 | 0 | p. 13 | unhappy (boundary, minimal) |
| one square | 5 | 1 | p. 13 | unhappy (boundary) |
| one foot short of a square | 4 | 0 | p. 13; p. 5 | unhappy (boundary) |
| one foot over a square | 6 | 1 | p. 13; p. 5 | unhappy (boundary) |
| non-multiple rounds down | 32 | 6 | p. 13; p. 5 | unhappy (rule interaction) |
| large Speed | 120 | 24 | p. 13 | happy |

### Withdrawn ids

None.

## 5. Model

- `CombatantId` (extension type; constructor enforces FR-002 to FR-004). `CombatantIdParse` is sealed: `CombatantIdParsed(id)`, `CombatantIdRejected(reason)`; `CombatantIdRejection` is an enum with the single value `empty` (the constructor's only failure).
- `CombatantKind` sealed; `CombatantRef(CombatantId id, CombatantKind kind)`; `CombatEvent` (FR-015); `TransportEnvelope` (FR-038); `CombatOperation` (FR-040); `CombatSignals` (FR-039); `CombatResultClass` enum with `outcome` and `isSpanError`.
- `CombatRuleOptions { PlayingOnAGrid grid }` and sealed `PlayingOnAGrid` (`NoGrid`, `SquareGrid`; only `SquareGrid` has behaviour, FR-043 to FR-045).

**Failures.** Constructors throw `ArgumentError` for invalid arguments (programmer error); `tryCreate` is the non-throwing path for untrusted ids. No `Srd5eException` is defined here: nothing calls a port.

**Layers.** `CombatantId`, `CombatantKind`, `CombatantRef`, `CombatEvent`: `domain/`, pure, silent. `CombatOperation`, `CombatResultClass`, `CombatSignals`, `CombatTelemetry`: `application/`, the only place that touches `Observability`.

### Superseded definitions

The supersession list: where a row says superseded, the other spec changes to match; this spec wins (decisions FR-012, FR-015).

| Spec | What it assumed | Outcome |
|---|---|---|
| `hit-points-and-damage.md` | `CombatantId` and `CombatEvent` come from here; `HitPointEvent` implements `CombatEvent`. FR-080: rejections (`CreatureIsDead`, `NotDying`, `NotStable`) set error status. FR-079: defines `operations`, `errors`, `operation_duration`. | Confirmed: events gain `kind` and `combatants` (FR-015, FR-017, FR-018). FR-080 now says `refused`, `failure`, no error status (FR-031); its result values (`damaged`, `killed`, `rejected_dead`, `not_dying`, `not_stable`) model `srd5e.combat.result` (FR-030). The three shared signals **moved** here (FR-029, FR-032); its use-case-specific signals stay. |
| `conditions.md` | D-1: `Charmed`, `Frightened`, `Grappled` and condition events carry `CombatantId`. Own signals `srd5e.combat.condition.apply`, `.remove`, `.reduce_exhaustion` (spans), `.operations`, `.duration`, and attributes `srd5e.combat.condition.operation`, `.outcome`. | Confirmed for ids; events gain `kind` and `combatants`. Signals **superseded**: spans are `srd5e.combat.<operation>`; throughput, duration, errors use the shared signals (FR-028, FR-029); the attributes become `srd5e.combat.operation`, `srd5e.combat.result` plus `result_class`. `.active` and per-kind detail stay. |
| `attacks.md` | No creature type (no `AttackTarget`). Own signals `srd5e.combat.attack.resolve` (span), `.resolved`, `.duration`, `.errors`, `.modifiers`, and `srd5e.combat.unarmed_strike.resolve` (span), `.resolved`, `.duration`, `.errors`. | No-creature assumption confirmed. The `.errors` signals duplicate `srd5e.combat.errors` and are removed (FR-037); spans are `srd5e.combat.resolve_attack` and `srd5e.combat.resolve_unarmed_strike` (FR-040) with the shared `operations` and `operation_duration`. `.attack.modifiers` stays (`attacks.md` section 7 lists it as a non-duplicate). Extras (`srd5e.combat.attack.form`, `.cover`, `.automatic_critical`, `.reason`, `srd5e.combat.unarmed_strike.option`, `srd5e.d20_test.roll_mode`, `srd5e.d20_test.critical_hit`) go through `attributes` (FR-041); its second `operations` row becomes prose (FR-037). |
| `initiative-and-actions.md` | Ids and naming come from here; refusals set no error status; shares `operation_duration` and `errors`. | Confirmed, including the unknown-combatant case: `invalid` (failure plus error status, FR-031), as in `encounter-aggregate.md` FR-046, FR-059 and `initiative-and-actions.md` FR-095, FR-099; `InitiativeTieBreakRejected` is `invalid`. `srd5e.combat.use_case` becomes `srd5e.combat.operation` (FR-028); `srd5e.combat.refusal` values become `srd5e.combat.result` values. |
| `encounter-aggregate.md` | `CombatantKind` with `PlayerCharacter` / `Monster`; `tryParse`. Own signals `encounter_transitions`, `encounter_errors`, `encounter_duration`, `encounter_events`; attributes `srd5e.combat.rejection`, `.error_kind`; result values `applied` / `rejected` / `invalid`. `DeathSavingThrowDue` and `...Occurred` envelopes. | **Superseded**: variants are `PlayerCharacterCombatant` / `MonsterCombatant` (FR-010); factory is `tryCreate` (FR-005, `character-aggregate.md` FR-003); `Combatant` holds a `CombatantRef`. Signals use the shared four; the coarse values become `result_class` (`rejected` is `refused`) and `result` holds a finer owned value (FR-030). `DeathSavingThrowDue` became `DyingCombatantTurnStarted` (FR-020; done, `encounter-aggregate.md` FR-018); the four envelopes follow FR-038. `encounter_size`, `encounter_deaths`, `death_cause` stay. `EncounterEvent` is a sealed sub-family (FR-016, D-1). |
| `combat-action-resolution.md` | FR-094 named `MovementSpeedsReviewDue`, `GrappleCheckDue`. Sibling use cases built with `Observability.none`. | **Superseded**: renamed `...BecameDue` (FR-020; done). No use case calls another (decisions FR-044), so FR-032's "once" needs no silenced telemetry (done: its FR-007). |
| `magical-effects.md` | A second section 7 row named `srd5e.combat.operations`. | **Superseded** by FR-037: prose; extras via FR-041. |
| `mounted-and-underwater-combat.md` | FR-061: extras `srd5e.combat.mount_control`, `.falling_off_trigger` "need a `CombatTelemetry` extension". | The extension is FR-041; the keys are `...Attribute` constants in `CombatSignals` (FR-039) and listed in the shared rows' Attributes cells (FR-037). |

## 6. Interface

No ports, no I/O; everything is synchronous.

```dart
extension type const CombatantId._(String value) {
  factory CombatantId(String value);                 // ArgumentError if blank
  static CombatantIdParse tryCreate(String value);   // never throws
}
sealed class CombatantIdParse { }                    // CombatantIdParsed(id) | CombatantIdRejected(reason)
enum CombatantIdRejection { empty }

sealed class CombatantKind { }                       // PlayerCharacterCombatant(CharacterId) | MonsterCombatant(MonsterId)
final class CombatantRef { const CombatantRef(this.id, this.kind); final CombatantId id; final CombatantKind kind; }

abstract interface class CombatEvent implements DomainEvent {
  String get kind;
  List<CombatantId> get combatants;
}

final class CombatOperation { CombatOperation(String value, {required String spanName}); final String value; final String spanName; }
abstract interface class TransportEnvelope { }       // marker for the ...Occurred envelopes (domain/, not exported)
abstract final class CombatSignals { /* static const String members, FR-039 */ }
enum CombatResultClass { applied, refused, invalid; String get outcome; bool get isSpanError; }

final class CombatTelemetry {
  const CombatTelemetry([Observability observability = const NoopObservability()]);
  R run<R>(CombatOperation operation, R Function() work, {
    required CombatResultClass Function(R) classify,
    required String Function(R) resultName,
    required Iterable<CombatEvent> Function(R) events,
    Map<String, Object> Function(R)? attributes,     // extras for the span and `operations` only (FR-041)
  });
}
```

`run` is synchronous; a use case with an asynchronous port (none today) would add `runAsync` in the change that needs it.

Exports: the `combat` barrel and `lib/srd5e.dart` export `CombatantId`, `CombatantIdParse`, `CombatantIdParsed`, `CombatantIdRejected`, `CombatantIdRejection`, `CombatantKind` and its variants, `CombatantRef`, `CombatEvent`. `CombatOperation`, `CombatResultClass`, `CombatTelemetry`, `CombatSignals` and `TransportEnvelope` stay internal to `lib/src/combat/application/` (application helpers, not handoff types; an export is a compatibility promise, architecture §7, §10; signal names are already public contract through the catalogue). `CombatRuleOptions` and `PlayingOnAGrid` with its variants are exported because `grid-positions-and-movement.md` FR-001 reads `grid` (`rule-options.md` FR-029); the `combat` library doc comment states that an option is a value in the command, never a global setting (`rule-options.md` FR-034). `lib/testing.dart` needs no new double: `CombatTelemetry` uses the existing recording `Observability`.

## 7. Observability

The domain pieces (ids, kinds, events) are **silent by design**. The signals below are emitted by later `combat` use cases through `CombatTelemetry`; this spec owns the shared rows and each later spec its own extras. All rows feed `doc/observability/signals.md`.

1. **What can go wrong?** A blank id (programmer error, thrown before any use case); two specs defining a signal differently; a port throwing; a refused action (normal); invalid host input; a reused event kind; an id leaking into an attribute.
2. **How would an operator know?** Port failures: `srd5e.combat.errors` with `error.type` plus span error status. Invalid input: `operations` with `result_class` = `invalid` plus span error status. Refusals: `refused`, no error status. Duplicate kinds and leaked ids are caught at build time (FR-017, FR-033).
3. **What is needed to diagnose?** Operation, result name, result class and event kinds, all low-cardinality; ids stay in results and events (FR-033).
4. **What to count or time?** Calls and outcome per operation; duration per operation; events per kind; port failures per error type.
5. **Is existing instrumentation still correct?** Not entirely: section 5 lists what the earlier specs defined and this spec replaces.
6. **What to monitor or alert on?** See the table.
7. **Is anything noisy?** No logs (FR-034). Counters are bounded by the use-case and event-class lists.

| Signal | Type | Attributes | Purpose | Suggested monitoring |
|---|---|---|---|---|
| `srd5e.combat.operations` | counter `{operation}` | `srd5e.combat.operation`, `srd5e.outcome` (`success`, `failure`), `srd5e.combat.result`, `srd5e.combat.result_class` (`applied`, `refused`, `invalid`), plus closed-value extras (FR-037, FR-041): `srd5e.combat.attack.form`, `srd5e.combat.attack.cover`, `srd5e.combat.attack.automatic_critical`, `srd5e.combat.attack.reason`, `srd5e.combat.unarmed_strike.option`, `srd5e.d20_test.roll_mode`, `srd5e.d20_test.critical_hit` (`attacks.md`); `srd5e.combat.mount_control`, `srd5e.combat.falling_off_trigger` (`mounted-and-underwater-combat.md`); `srd5e.combat.roster_reason` (`summoned`, `arrived`, `fled`, `surrendered`, `disappeared`, `departed`, `repositioned`; `combatant-roster-changes.md`); `srd5e.combat.spell_table` (6 values; `spell-outcome-tables.md`); `srd5e.combat.monster_hit_points_method` (`average`, `rolled`; `monster-combatant-setup.md`); `srd5e.combat.damage_notation` (`number`, `dice`, `mixed`; `monster-stat-block-actions.md`) | Throughput and outcome of every combat use case | Rate by operation and `result_class`; alert if `invalid` exceeds 1% of an operation's calls over 15 minutes; watch a sudden shift in the `refused` share |
| `srd5e.combat.operation_duration` | histogram `s` | `srd5e.combat.operation` | Latency of each use case, through the `Meter` timing operation | p99 above 10 ms for 5 minutes, or 3 times its 7-day baseline; usually a slow host adapter |
| `srd5e.combat.errors` | counter `{error}` | `srd5e.combat.operation`, `error.type` | Port failures leaving a use case (for example `dice_roller_exception`) | Alert on any increment; page if above 0.1% of calls over 5 minutes |
| `srd5e.combat.events` | counter `{event}` | `srd5e.combat.event` | Domain events produced, by kind | Dashboard rate by kind; investigate a kind dropping to zero after a release |

**Spans.** Each use case runs in one span `srd5e.combat.<operation>` (FR-029) carrying `srd5e.combat.operation`, `srd5e.outcome`, `srd5e.combat.result`, `srd5e.combat.result_class` and any FR-041 extras; error status only for `invalid` results and thrown exceptions. The template is not a signal name, so no span row is listed here; each use-case spec lists the row for its own span (FR-040). Suggested monitoring: trace sampling, alert on a sustained rise in error-status spans for one operation.

Value sets are closed: `srd5e.outcome` is `success` or `failure`; `result_class` is `applied`, `refused` or `invalid`; `error.type` is the `Srd5eException` constant set of `errors-and-results.md`; `operation`, `result` and `event` are closed sets listed by the owning specs.

## 8. Test plan

| Id | Level | Notes |
|---|---|---|
| FR-001, FR-009, FR-012, FR-014 | architecture | Barrel scan: one `CombatantId`, exported from `combat` and `srd5e.dart`, no second creature-id type. Scan of `lib/src/combat/` for `Random(`, uuid imports, and any static, top-level, factory or constructor returning `CombatantId` other than `CombatantId(...)` and `tryCreate`. Kind variants' public members are the reference id, `==`, `hashCode`. Reference-type import allowlist: `dart:core`, `package:meta`, `character` and `content` barrels, `shared_kernel`, own `domain/` files; fails on another `combat` spec file, `d20_test`, `toolbox`, or a non-barrel file |
| FR-002 to FR-006 | unit | Accepted and unchanged: `'a'`, `'goblin_1'`, `' a'`, `'a '`, `'\u00A0a'`. Throw (`ArgumentError`, all `trim().isEmpty`): `''`, `' '`, `'\t'`, `'\n'`, `'\r'`, `'\u00A0'`, `'  \n\r '`. `tryCreate` over the same table returns `CombatantIdParsed` or `CombatantIdRejected(empty)`; property over extreme strings (very long, unicode, empty): never throws, rejection iff the constructor throws. Three differently cased/padded ids are pairwise unequal |
| FR-007, FR-011, FR-013 | unit | Equal strings: equal and same hash; different strings differ; usable as `Set` and `Map` keys. Kind and ref equality pairs, including `PlayerCharacterCombatant(CharacterId('x'))` versus `MonsterCombatant(MonsterId('x'))` and the same id with a different kind |
| FR-008 | architecture | Analyzer fixture: assigning `CombatantId` to `EncounterId`, `CharacterId`, `MonsterId` (and back) produces `invalid_assignment` |
| FR-010 | unit | Exhaustive `switch` over `CombatantKind` compiles with two cases; each variant exposes its id |
| FR-015 to FR-017 | unit, architecture | A test event implements `CombatEvent` and is accepted as `DomainEvent`; `CombatEvent` is an `abstract interface class` with `kind` and `combatants`. Lists every implementer; fails on a direct implementer or a non-sealed sub-family; an envelope in a sealed family passes. Scan collects every non-envelope `kind` constant: matches the pattern, unique; envelopes (marker) skipped; `CharacterEvent` ignored; no `runtimeType` in event code; equal events, equal kinds |
| FR-018, FR-021 | unit | Self-test of helper `test/combat/event_family_checks.dart` against a fake family (a good one passes; a modifiable list, a duplicate, an unordered list, and a result with a modifiable events list each fail). Per owning spec using the helper: `combatants` unmodifiable, ordered, duplicate-free, empty only for no-creature events; `events.add` throws `UnsupportedError`; order preserved |
| FR-019 | architecture | Scan: `@immutable`, `final` fields only, on every implementer. Unit (owning specs): value equality including `kind` and `combatants` |
| FR-020 | architecture | No event class name matches `(?<!Became)Due$\|Required$\|Needed$` (`MovementSpeedsReviewBecameDue` passes; `DeathSavingThrowDue` and `RollRequired` fail). Tense is otherwise a naming review |
| FR-022 to FR-025 | architecture | Barrel scan fails on the banned generic names, a result or command without the `<UseCase>` prefix, a `*Rejected` / `*Invalid` variant without a `*Rejection` / `*Problem` field, and a duplicate exported name (lower-rank spec wins; alphabetical at equal rank). Each reserved name is declared exactly once, in this spec's files |
| FR-026 | architecture | Import-direction check inside `combat` using the 4.11 ranks; fails on an import of `toolbox`, of a non-barrel file of `character`, `d20_test` or `content`, of another context's use case, and of a non-published-language type in `domain/`. Passes a `D20TestResolver` import in `application/` |
| FR-027, FR-033 | architecture | Every `srd5e.combat.` name appears only in `CombatSignals`; no literal at a call site; `CombatSignals` contains neither `srd5e.outcome` nor `error.type` nor any `srd5e.d20_test.*` key; `combat` code uses `AttributeKeys.outcome`, `AttributeKeys.errorType` and the other context's exported constants; catalogue and constants match. Attribute-building code in `combat/application/` reads no id, amount or free text; a recording-double test asserts no attribute value equals a supplied `CombatantId` |
| FR-028 | unit, architecture | `CombatOperation('apply_damage', spanName: 'srd5e.combat.apply_damage')` accepted; `''`, `'Apply'`, `'apply damage'`, `'1x'` throw `ArgumentError`, as does a span name not ending in `.apply_damage`. No `srd5e.combat.use_case` or `srd5e.operation` remains in the catalogue |
| FR-029, FR-041 | application, unit | `CombatTelemetry` with the recording `Observability`: one span name, one `operations` increment, one `operation_duration` sample, one `events` increment per event (zero events, zero increments). Extras from `attributes` appear on the span and the `operations` increment only; an absent entry is omitted; a shared key in the map throws `ArgumentError`; no `attributes` records the shared set only. Throw path: one `operation_duration` sample, no `operations` or `events` increment |
| FR-030, FR-031 | unit, application, architecture | Recorded attribute sets equal FR-030's lists (plus FR-041 extras); fails on a `srd5e.outcome` or `result_class` value outside its set and on a catalogue `srd5e.combat.result` value with no `CombatResultClass`; a fake use case whose `resultName` values each map to one class; one `result` value never appears under two classes. `CombatResultClass` table: `applied` is `success`, not error; `refused` is `failure`, not error; `invalid` is `failure`, error; span status set accordingly |
| FR-032, FR-035 | application, architecture | A work function throwing a test `Srd5eException`: one `errors` increment with `error.type`, error span, exception rethrown, recorded once (no `recordError` by `CombatTelemetry`). A `refused` or `invalid` result: no `errors` increment. A thrown `StateError` propagates unchanged, the span records it, no `errors` increment. No `combat` use case holds or calls another use case (decisions FR-044) |
| FR-034, FR-036 | application | Recording logger sees no record at `INFO` or above for applied, refused and invalid results. Same work, same result with `NoopObservability` and the recording one |
| FR-037 | architecture | Catalogue consistency: each shared name has one row; no superseded name listed; no second row repeats a shared name (`attacks.md` and `magical-effects.md` extras are prose); the shared rows' Attributes cells write `srd5e.outcome` (`success`, `failure`) and `srd5e.combat.result_class` (`applied`, `refused`, `invalid`) |
| FR-038 | unit, application, architecture | A fake envelope wrapping a fake event: `kind` and `combatants` equal the wrapped event's; `events` incremented once under the wrapped `kind`; scans accept the marked envelope and fail on a non-envelope duplicate or constant-less kind; the set of `TransportEnvelope` classes equals the named list |
| FR-039, FR-040 | architecture, unit | `CombatSignals` is an `abstract final class` of `static const String` members with legal suffixes; the FR-039 constants and values exist; `CombatResultClass.outcome` returns the two `outcome...Value` constants (unit); `result_class` is recorded from the three `resultClass...Value` constants. `CombatOperation` accepts a matching pair and rejects a mismatched span name; every `...OperationValue` has a `...Span` of `srd5e.combat.` plus it, and the reverse; each per-operation span has one catalogue row and every `srd5e.combat.` span Name in the catalogue equals a constant |
| FR-042, FR-043 | unit, architecture | `standard` field is `NoGrid`; equality, `hashCode`, `copyWith` for `grid`, original unchanged after `copyWith`; two `const` instances are `identical`; variants are `final class` (`errors-and-results.md` FR-018 scan); an exhaustive `switch` over `PlayingOnAGrid` maps the two variants to two distinct values; option files are covered by the `rule-options.md` FR-023 scan |
| FR-044, FR-045 | unit | `feetPerSquare == 5`; the seven table rows of 4.6; -1 and -9007199254740991 throw `ArgumentError`; boundary rows kill `<` / `<=` and off-by-one mutants |

- **Doubles and contract suites.** None: there is no port. The recording `Observability` comes from `lib/testing.dart`. Event-family tests (FR-018, FR-019, FR-021) reuse `test/combat/event_family_checks.dart`; each `combat` spec's test plan MUST cite it for its event family and result types (checked by the spec-consistency critic).
- **Mutation testing.** `lib/src/combat/domain/` and `CombatResultClass` at score 80 or more (`doc/rules/testing.md` §8). `CombatTelemetry` SHOULD be mutation tested.
- **Not covered by a runtime test:** FR-008 (static property, analyzer fixture) and the tense half of FR-020 (naming review).
- **Layout.** `test/combat/domain/combatant_id_test.dart`, `combatant_kind_test.dart`, `combatant_ref_test.dart`; `test/combat/application/combat_telemetry_test.dart`; `test/combat/event_family_checks.dart` with self-test `event_family_checks_test.dart`; `test/architecture/combat_*_test.dart`. Each test cites its FR id.

## 9. Open questions and decisions

No open questions. Settled:

- D-1 (`CombatEvent` is an interface, not sealed): Dart sealed subtypes must share a library, so `part` files would defeat one-owner-per-spec, and naming the sub-families here would point the leftmost spec at later ones; `shared-types-and-ownership.md` FR-019; FR-015, FR-016.
- D-2 (ids carry no kind): the host may field two goblins; an id derived from the kind would make two goblins equal; the id is host-assigned and unique, the `MonsterId` is a separate fact.
- D-3 (`kind` and `combatants` on every event): routing, filtering and counting need no `runtimeType`.
- D-4 (a refusal is not an error status): observability §6-§7; FR-031.
- D-5 (one `CombatTelemetry` helper): uniform telemetry by construction; FR-035.
- D-6 (the "source of fear" need not be a creature): out of scope; settled in `conditions.md` D-2: the source of fear is a `CombatantId` and no `FearSource` type is added.
- D-7 (no trimming; blank means `value.trim().isEmpty`): FR-002, FR-006.
- D-8 (`MonsterId` is owned by `content-schema-and-decoder.md`): decisions FR-046.
- D-9 (a returned failure carries no `error.type`): decisions FR-051; FR-032.
- D-10 (`D20TestSignals` is exported from the `d20_test` barrel): `resolve-d20-test-use-case.md` FR-042.
- D-11 (header lists only lower-rank specs): decisions FR-056.
- D-12 (`CombatRuleOptions` lives here, type phase 4): decisions FR-057; Monster Death and the Initiative method are not options (`hit-points-and-damage.md` FR-087; `initiative-and-actions.md` FR-010).

## 10. Changelog impact

`Added`: `CombatantId`, `CombatantKind` (`PlayerCharacterCombatant`, `MonsterCombatant`), `CombatantRef`, `CombatEvent` (`CombatTelemetry`, `CombatOperation`, `CombatResultClass`, `CombatSignals`, `TransportEnvelope` are not exported); the shared signals `srd5e.combat.operations`, `srd5e.combat.operation_duration`, `srd5e.combat.errors`, `srd5e.combat.events`.

Also **Added** (exported under `rule-options.md` FR-029): "`combat`: `CombatRuleOptions` (playing on a grid)". Purely additive; `standard` is the SRD baseline.

Not **BREAKING** if it ships in the first release containing `combat`. Once any of those signals or names is released, renaming one is **BREAKING** (`doc/rules/architecture.md` §7, `doc/rules/observability.md` §5).
