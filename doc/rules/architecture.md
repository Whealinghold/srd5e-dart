# srd5e Architecture Rules

Normative. MUST / MUST NOT / SHOULD are binding on all code and review.

Target architecture: **Domain-Driven Design** inside a **Hexagonal
(Ports & Adapters)** structure. The package is a library with no UI, storage or
framework. The hexagon *is* the package; every consumer is an adapter on the
outside.

Goals, in priority order:

1. Decoupled modules and components, each separately testable.
2. Well-defined handoffs between components.
3. A rules model that reads like the fifth-edition rules in SRD 5.2.1 themselves.

---

## 1. Hexagonal structure

```
                 driving side                         driven side
        (consumers call into us)             (we call out to the host)

  host app ──► [ use cases ]  ┌──────────────┐  [ ports ] ──► adapter
  CLI      ──►  (application) │    DOMAIN    │  DiceRoller    SeededDiceRoller
  server   ──►                │ (pure rules) │  ContentSource JsonContentSource
                              └──────────────┘  Observability host's own impls
```

- **Domain**: pure rules. Entities, value objects, aggregates, domain events,
  domain services.
- **Application**: use cases (the *driving ports*: what consumers can ask for)
  and the interfaces for everything the domain needs from outside (the *driven
  ports*, in `application/ports/` or `shared_ports/`).
- **Adapters**: implementations of driven ports, and decoders from external
  formats into domain types. The host app supplies its own; the package MAY ship
  generic ones.

### Package-level modules

| Folder under `lib/src/` | Holds |
|---|---|
| `shared_kernel/` | Domain concepts every context shares (§2) |
| `shared_ports/` | Driven ports used by more than one context: `DiceRoller`, `Observability` (`Logger`, `Tracer`, `Meter`), the exception root and port-failure guards (`shared_ports/errors/`, §6), and any other cross-cutting port. Depends only on `shared_kernel`. May hold an `adapters/` folder for generic implementations (see below). |
| `testing/` | Every test double (§7). Exported only by `lib/testing.dart`. |
| `<context>/` | One bounded context each (§2) |

A port used by exactly one context lives in that context's
`application/ports/`. When a second context needs it, move it to
`shared_ports/`; do not import it across contexts.

- **No-op implementations** (`NoopLogger`, `NoopTracer`, `NoopMeter`,
  `NoopObservability`) are `const` classes in the port library itself, under
  `lib/src/shared_ports/`. They are not adapters: `application` may not import
  `adapters/` yet needs the default.
- **`shared_ports/adapters/`** holds generic implementations of shared ports
  (`SeededDiceRoller`). It depends only on `shared_kernel` and the port. Only
  `lib/adapters.dart` imports adapter folders.
- **`lib/src/testing/`** holds all test doubles, including `FakeContentSource`
  (a double, not an adapter). Nothing imports it except `lib/testing.dart`.
  Doubles MAY depend on ports, `shared_kernel` and context barrels.

### Dependency rule

Dependencies point inward only.

| Layer | MAY depend on | MUST NOT depend on |
|---|---|---|
| `shared_kernel` | nothing in the package | everything else |
| `shared_ports` (including its `adapters/`) | `shared_kernel` | contexts |
| `domain` | own context's `domain`, `shared_kernel`, the **published language** (value objects, ids, events) of upstream contexts (§2) | `application`, `adapters`, `shared_ports`, other contexts' use cases or internals |
| `application` | own `domain`, own `ports`, `shared_ports`, `shared_kernel`, the domain services and **published language** exported by the barrels of upstream contexts | `adapters`, other contexts' internals, other contexts' use cases (§4) |
| `adapters` | own `application` (ports), own `domain`, `shared_ports`, `shared_kernel`, the barrel of upstream contexts | other contexts' adapters or internals |
| `testing` | `shared_ports`, `shared_kernel`, context barrels | context internals; anything outside `lib/testing.dart` MUST NOT import it |

"Upstream" is defined by the context map (§2). Importing anything from
`dart:io`, `dart:ui` or a framework is governed by §5 and §3.

---

## 2. Bounded contexts (modules)

Each folder under `lib/src/` other than `shared_kernel/`, `shared_ports/` and
`testing/` is a **bounded context**: one cohesive part of the rules with its own model and
vocabulary.

```
lib/src/<context>/
├── <context>.dart # the barrel: this context's published API
├── domain/        # entities, value objects, aggregates, events, domain services
├── application/   # use cases, commands, results
│   └── ports/     # driven-port interfaces used only by this context
└── adapters/      # port implementations, external-format decoders
```

Rules:

- A context MUST be understandable and testable on its own.
- Each context has exactly one barrel, `lib/src/<context>/<context>.dart`,
  exporting its published API: its use cases and its handoff types. The barrel
  is the **only** file of a context that another context may import.
  Everything else under the context's folder is internal.
- The **published language** of a context is the subset of its barrel made of
  value objects, ids and domain events. Downstream domain code MAY use it;
  downstream domain code MUST NOT call another context's use cases.
- Prefer referencing another context's aggregates **by id**, not by holding the
  object.
- If two contexts need the same concept, the upstream one owns and publishes
  it. Move it to `shared_kernel` only if every context needs it. Do not
  duplicate and do not reach into internals.
- `content` owns every closed SRD vocabulary type and typed id (`DamageType`,
  `ConditionKind`, `Skill`, `CreatureSize`, `WeaponProperty`, `ClassId`,
  `SpellId`, and so on). Vocabulary types carry static SRD facts only; the
  behaviour that interprets one is owned by the context where the rule is
  applied. This keeps `content` upstream of `character` and `combat` with no
  edge back.
- `lib/srd5e.dart` re-exports only what consumers are meant to use.

### Context map

Context dependencies MUST form a directed acyclic graph. The allowed
directions are listed here and nowhere else; anything not listed is
forbidden.

| Context | Purpose | May depend on (upstream) |
|---|---|---|
| `content` | Species, backgrounds, classes, feats, spells, equipment, monsters; content-source ports and decoders | none |
| `d20_test` | D20 Tests (ability checks, saving throws, attack rolls), DCs, Advantage and Disadvantage, success and failure resolution, from modifiers and a roll | none |
| `character` | Abilities, Proficiency Bonus, level, derived stats, spellcasting, equipment rule maths (Armor Class, Carrying Capacity, crafting) | `content`, `d20_test` |
| `combat` | Initiative, actions, attacks, conditions, hit points, damage | `character`, `d20_test`, `content` |
| `toolbox` | Gameplay Toolbox rules (travel pace, environmental effects, poison, traps, curses and contagions, fear and mental stress, XP-budget encounter planning) | `content`, `d20_test`, `character`, `combat` |

Nothing depends on `toolbox`.

The contexts are **provisional**. Adding, merging or re-pointing a context is
an architecture change: update this table, `AGENTS.md`, and the architecture
tests (§9) in the same change. A new edge MUST NOT create a cycle; if two
contexts seem to need each other, a concept is in the wrong place.

### Shared kernel

`shared_kernel/` holds the small set of concepts every context genuinely shares
(dice expressions and roll results, modifiers, Advantage and Disadvantage,
ability scores, identifiers).

- It MUST stay small. If only some contexts need a concept, it belongs to the
  most upstream of them and is published from there.
- It MUST depend on nothing else in the package.
- Changing it affects every context, so treat changes as breaking-change
  candidates.

---

## 3. Domain model (DDD)

### Ubiquitous language

- Names MUST use the terminology of **SRD 5.2.1** exactly: `D20Test`,
  `AbilityScore`, `AbilityModifier`, `ProficiencyBonus`, `Advantage`,
  `Disadvantage`, `ArmorClass`, `HitPoints`, `Species` (not `Race`). Do not
  invent synonyms.
- Terms from other editions of the rules and removed concepts MUST NOT appear
  in the domain. Decoders for external content translate them at the boundary
  (§5).
- When the rules text and the code disagree on a term, the code changes.
- Domain code MUST NOT contain generic technical names (`Manager`, `Helper`,
  `Processor`, `Data`) for domain concepts.

### Building blocks

- **Value object**: immutable, compared by value, no identity, no side
  effects. Most rules concepts are value objects: `Modifier`, `Dc`,
  `AbilityScore`, `ProficiencyBonus`. Prefer these. Validate in the
  constructor so an invalid instance cannot exist (see §6 for untrusted
  input).
- **Entity**: has identity that persists across changes (a character, a
  combat encounter). Identity is an explicit typed id (an extension type or
  value object), not a raw `String`. Entities MUST NOT be required to carry
  timestamps or persistence concerns.
- **Aggregate**: a cluster of entities and value objects with one **aggregate
  root**. Outside code MUST only hold and call the root, and MUST NOT mutate
  inside parts directly. The root enforces the aggregate's invariants.
- **Domain event**: an immutable fact about something that happened in the
  rules (`DamageTaken`, `ConditionApplied`). Named in the past tense.
- **Domain service**: rules logic that belongs to no single entity or value
  object (e.g. resolving a check against a DC). Stateless; takes everything it
  needs as arguments.

### Immutability and state transitions

> **Project default (changeable):** hand-written immutable classes, no
> `freezed` or other code generation.

- All domain types MUST be immutable: `final` fields, `const` constructors where
  possible, `@immutable` from `package:meta` on classes.
- A state change MUST return a new instance, plus the domain events it produced.
  Never mutate in place.
- Prefer sealed classes, records and exhaustive `switch` for closed sets of
  outcomes. No `null` or booleans standing in for named states.
- Invariants MUST be enforced by the type itself, not by callers.

### Purity

Domain code MUST be pure Dart, synchronous and deterministic:

- No `Random`, `DateTime.now()`, `Stopwatch`, file or network access, `print`,
  or global state. Anything non-deterministic comes in as a value (e.g. a roll
  result) obtained by the use case through a port.
- No `Future`, `Stream` or `async` in the domain.
- No `dart:io`, `dart:ui`, Flutter, or any framework import.
- No display strings. Return structured data (see §6).

### Optional rules and extension points

The SRD presents some rules as optional or leaves them to the Game Master, and
consumers will want house rules. Support them without consumer-specific code:

- Optional rules are modelled as an immutable `RuleOptions` value object (or
  one per context) that names each option the **SRD itself presents**
  explicitly. It is part of the state passed in a command, never a global
  setting.
- Domain code that varies by rule option branches with an exhaustive `switch`
  over a sealed type, or takes a domain-level strategy object. No scattered
  boolean flags.
- House rules and new content arrive as **content** through `ContentSource`
  (feats, items, effects expressed as data), not as code paths keyed to a
  consumer.
- Where a consumer needs to change behaviour that content cannot express,
  expose a narrow, documented strategy interface in the domain with the
  standard rule as its default. Add one only when a real need appears.

---

## 4. Application layer and ports

### Use cases (driving ports)

- A use case is a single-purpose class exposing one thing a consumer can ask
  for (`ResolveAttackRoll`, `CalculateArmorClass`) through a single `call` method.
- Input is an explicit, immutable **command** type that carries all data
  needed. Output is an explicit **result** type. No raw maps, no loose
  positional primitives across the boundary.
- Every use case returns its own sealed result named `<UseCase>Result`. Its
  variants are prefixed with the operation (`DamageApplied`, `DamageRejected`,
  `CreateCharacterContentMissing`). Generic variant names (`Applied`,
  `Rejected`, `Succeeded`, `ContentMissing`, `Found`, `NotFound`) MUST NOT be
  exported, so barrels never collide. Failure detail shared by several results
  is a value object held as a field of each variant, not a shared variant.
- A use case orchestrates: loads what it needs through ports, calls the domain,
  returns a result. It MUST NOT contain rules logic; that lives in the domain.
- A use case MUST NOT call another use case. It composes the pure domain
  services that upstream contexts publish in their barrels (e.g.
  `D20TestResolver`), supplying dice and content through its own ports. Each
  use case records only its own signals ([observability.md](observability.md)
  §7).
- A use case MUST receive all collaborators through its constructor, typed as
  port interfaces. It MUST NOT construct adapters or reach for globals.
- A use case is synchronous unless it calls an asynchronous port, in which case
  it returns a `Future` of its result. Do not make a use case async
  speculatively.

> **Project default (changeable):** the engine is *state in, new state and
> events out*. Use cases take current state in the command and return the new
> state and events in the result. They hold no hidden mutable state, so the
> host decides how and where state is stored.

### Driven ports

- A driven port is an abstract interface class, **named for what the domain
  needs**, not for the technology behind it (`DiceRoller`, not
  `RandomWrapper`; `ContentSource`, not `JsonFileLoader`).
- Ports use domain types only. No DTOs, maps, SQL, HTTP, or `dynamic`.
- Keep ports small and role-specific. Prefer several narrow ports to one wide
  one.
- **Sync or async.** A port whose implementations may reasonably do I/O
  (`ContentSource`) returns `Future<T>`. A port that is computational or
  in-memory by nature (`DiceRoller`, `Observability`) is synchronous. Never
  `FutureOr<T>`; pick one. The one exception is `Observability`: `Tracer` and
  `Meter` also carry async wrappers (`traceAsync`, `timeAsync`) so a use case
  that returns a `Future` can be spanned and timed
  ([observability.md](observability.md) §4).
- **Failure contract.** Each port documents its failures:
  - Expected absence or rejection (content id not found, unsupported content
    version) is part of the return type, as a sealed result
    (e.g. `ContentLookup` = `ContentFound` | `ContentNotFound`). It is not an
    exception.
  - Infrastructure failure (I/O error, backend unavailable) is thrown as a
    typed `Exception` subtype from the package's error hierarchy (§6). Adapters
    MUST wrap underlying errors into it, keeping the original as `cause`.
- Expected ports include dice rolling, content lookup and observability
  (logging, tracing, metrics; see [observability.md](observability.md)). Add
  others only when a real need appears.

### Handoffs

Every boundary, between layers, between contexts, and between the package and
its consumer, is crossed by one of: a command, a result, a domain event, a
value object, or an id. Nothing else.

- Handoff types MUST be immutable and documented.
- Each context's barrel MUST make its handoff types easy to find. Document the
  context's inputs and outputs in the barrel's library doc comment.
- A handoff type MUST NOT expose internal collections for mutation; use
  unmodifiable views.

---

## 5. Adapters and anti-corruption

- Adapters implement ports and translate between external formats and domain
  types. They are the only place that knows about JSON shapes, file layouts,
  legacy terminology or host specifics.
- External data enters the domain only through a **decoder** that parses and
  validates it into domain objects ("parse, don't validate"). A decoder
  returns a sealed result: the decoded value, or a typed failure listing every
  problem found (path, kind), not just the first. The domain MUST NOT see raw
  `Map<String, dynamic>`.
- Generic adapters MAY be shipped (seeded dice roller, in-memory content
  source, JSON decoder). They MUST NOT assume a particular consumer.
- Adapters needing `dart:io` or any platform API MUST live behind a separate
  entry point so the core stays platform-neutral.
- Adapters bridging to third-party packages (OpenTelemetry, `package:logging`,
  Sentry) MUST NOT be shipped in this package, because they would force the
  dependency on every consumer. Document them as examples instead.
- Bundled content is embedded Dart (raw JSON strings under
  `lib/src/content/data/`, generated from `data/`) and goes through the same
  decoder as host-supplied JSON. Extraction and generation tooling lives only
  in `tool/` and MUST NOT be imported from `lib/`.
- A consumer's adapters live in the consumer's repo, never here.

---

## 6. Errors and results

Follow Dart's own split between `Error` and `Exception`:

| Situation | Mechanism | Caller expected to handle? |
|---|---|---|
| Expected rule outcome (failed check, illegal action in this state, content not found) | Sealed **result** type | Yes, by reading the result |
| Untrusted input that fails validation (decoded content, host-supplied values) | Sealed **result** from a decoder or a `tryCreate`/`parse` factory | Yes |
| Infrastructure failure in a port (I/O, backend down) | Typed `Exception` subtype of the package's base `Srd5eException` (an `abstract base class`, not `sealed`, with a closed, documented set of subtypes) | Yes, by catching |
| Programmer error (violated precondition, invalid argument to a constructor, broken invariant) | `ArgumentError`, `StateError` or another `Error` | No; it is a bug |

- Value object constructors throw `ArgumentError` on invalid arguments. Where
  values may come from untrusted input, the type also offers a non-throwing
  factory that returns a result. Consumers parsing user input use that.
- Errors and failures crossing a boundary are typed, and carry data, not
  display text. `toString` is for debugging only and MUST NOT be relied on.
- Results SHOULD carry the information needed to explain them (modifiers
  applied, roll made, DC) so consumers can render their own breakdowns.
- Never catch `Error`. Catch `Exception` only to wrap, translate or record it,
  and rethrow unless the catching code fully handles it. The one exemption is a
  clause that only records and ends in an unconditional `rethrow` (the
  `Tracer`, [observability.md](observability.md) §7); it MAY catch `Object` or
  `Error`.

---

## 7. Public API, entry points and versioning

| Entry point | Purpose |
|---|---|
| `package:srd5e/srd5e.dart` | Published use cases, handoff types, domain types consumers need |
| `package:srd5e/adapters.dart` *(planned)* | Generic bundled adapters (seeded roller, in-memory content, JSON decoders). Platform-neutral. |
| `package:srd5e/testing.dart` *(planned)* | Test doubles for every port (fixed roller, fake content source, recording observability). Implementation in `lib/src/testing/`. |

A `dart:io`-dependent adapter, if one is ever needed, gets its own further
entry point (e.g. `package:srd5e/io.dart`).

- Everything under `lib/src/` is private. Consumers MUST NOT import from it.
- Export deliberately. Anything exported is a compatibility promise.
- Every exported member has a dartdoc comment (`public_member_api_docs`).
- Every port MUST ship with a test double in the testing entry point. All
  doubles live in `lib/src/testing/` and nowhere else.
- Contract suites live in `test/contract/` and are not exported (they would
  need `package:test` as a runtime dependency). Documentation tells consumers
  how to reuse them.

### Versioning

- The package follows [Semantic Versioning](https://semver.org/) as applied by
  the Dart ecosystem: before 1.0.0, a breaking change bumps the minor version
  (0.1.0 → 0.2.0) and anything else bumps the patch version.
- Breaking changes include: removing or renaming an exported member, changing
  a signature, changing a sealed hierarchy consumers switch over, changing a
  rule's result for the same input (unless fixing a bug against the rules),
  and renaming or removing a telemetry signal or attribute
  ([observability.md](observability.md) §5).
- Every user-visible change gets an entry in `CHANGELOG.md` under an
  `Unreleased` heading, grouped as Added / Changed / Deprecated / Removed /
  Fixed (Keep a Changelog). Breaking changes are marked **BREAKING**.
- Deprecate with `@Deprecated` for at least one release before removing, where
  practical.

---

## 8. Testing

Per-layer approach, in short (full rules: [testing.md](testing.md)):

- Domain: plain unit tests with no ports, doubles or I/O.
- Application: the real domain with test doubles from `testing.dart`.
- Adapters: the shared contract suite for their port.
- Scenarios: through the public entry points only.

---

## 9. Enforcement

Rules are checked mechanically wherever possible. A test in `test/architecture/`
MUST fail the build when it finds:

- `flutter`, `dart:ui` or `dart:io` imported anywhere under `lib/src/` except
  in an adapter behind a platform-specific entry point.
- A `domain/` file importing `application/`, `adapters/`, `shared_ports/`,
  `dart:async`, or using `async`, `Future` or `Stream`.
- A file outside `adapters/` importing from an `adapters/` folder, other than
  the entry point `lib/adapters.dart`.
- A file importing `lib/src/testing/`, other than `lib/testing.dart`; or a file
  under `lib/src/testing/` importing a context's internals (anything but its
  barrel).
- A file under `lib/` importing anything from `tool/`.
- A generic variant name (`Applied`, `Rejected`, `Succeeded`, `ContentMissing`,
  `Found`, `NotFound`) or a duplicate name among the exported members of the
  barrels (barrel scan).
- The embedded libraries under `lib/src/content/data/` differing from what the
  generator in `tool/` produces from `data/` (drift check).
- A file in one context importing any file of another context other than its
  barrel, or importing the barrel of a context that is not upstream of it in
  the context map (§2).
- A cycle in the context map, or a context folder missing from it.
- `shared_kernel/` importing anything else in the package, or `shared_ports/`
  (including its `adapters/`) importing anything but `shared_kernel/`.
- A file in `lib/` containing the name of any consuming project.
- Use of `Random(`, `DateTime.now(` or `Stopwatch(` in `domain/` or
  `application/`. Use of `print(` anywhere in `lib/`.
- A `doc/rules/*.md` file without exactly one line that starts with the tag
  label (see its "Read receipt" section), or a tag value appearing in any
  other file (tags must not be copied elsewhere).

### Bootstrap

The architecture suite and the `testing.dart` doubles do not exist yet. The
first change that adds code under `lib/src/` MUST add `test/architecture/`
with every check above that can apply to the code present, and every port it
introduces MUST arrive with its test double and contract suite. After that,
these rules apply in full.

---

## 10. Anti-patterns (prohibited)

- **Anemic domain**: all logic in use cases with the domain reduced to data
  holders.
- **God object**: one `Game` or `Engine` class that knows everything.
- **Leaky ports**: a port that exposes a JSON map, a file path or an HTTP
  client.
- **Reaching across contexts**: importing another context's files other than
  its barrel, or depending against the context map.
- **Shared mutable state**: static fields, singletons, service locators. A
  `const` instance of a no-op observability class is stateless and exempt.
- **Hidden non-determinism**: random numbers or time read inside the domain.
- **Stringly-typed domain**: raw strings or ints where a value object or id
  type exists.
- **Exceptions for outcomes**: throwing for a failed check, missing content or
  invalid user input instead of returning a result.
- **Display text in results**: pre-formatted messages from the engine.
- **Global rule toggles**: optional rules as static flags or environment
  settings instead of options in the state.
- **Consumer-shaped API**: any type or option that exists only because one
  consuming project needed it.

---

## Checklist before submitting

- [ ] Code sits in the right layer; the dependency rule and context map hold.
- [ ] No context imports another's internals; only upstream barrels.
- [ ] Domain types are immutable, validated on construction, pure and
      synchronous.
- [ ] Randomness, time and content arrive through ports.
- [ ] Expected outcomes are results; port failures are typed exceptions;
      programmer errors are `Error`s.
- [ ] Boundaries are crossed by commands, results, events, value objects or ids.
- [ ] Names match SRD 5.2.1 terminology.
- [ ] Every new port has a test double (in `lib/src/testing/`) and a contract
      test.
- [ ] Each use case returns its own `<UseCase>Result` with operation-prefixed
      variants; no generic variant names are exported.
- [ ] Nothing refers to a specific consuming project.
- [ ] Exported members are documented; `CHANGELOG.md` is updated; breaking
      changes are marked.
- [ ] Architecture tests pass.

---

## Read receipt

RULE-TAG: `architecture-cfa26cd4486b`

This tag proves you read this document in this session. Quote it verbatim as
required by `AGENTS.md`. Do not copy it anywhere else. Whoever edits this
document MUST replace the tag with a fresh random value.
