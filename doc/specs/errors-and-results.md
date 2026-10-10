# Errors and results

| | |
|---|---|
| Status | implemented |
| Context | `package` |
| Roadmap phase | 0 |
| Depends on | none |

## 1. Purpose and scope

Defines how every part of srd5e reports that something did not go to plan:

- the `Srd5eException` root and the conventions every subtype follows. The root
  is thrown only when a port or its backend fails, including a port that breaks
  its contract (FR-036);
- the conventions every sealed result type follows (expected outcomes, absence,
  rejection, untrusted input that fails validation);
- the split between results, `Srd5eException` and `ArgumentError` / `StateError`;
- the guard helpers adapters use to wrap underlying exceptions into the typed
  hierarchy without catching `Error`;
- the `error.type` value registry (FR-034, FR-005; decisions FR-041), the naming
  rules for results and variants (FR-041, FR-042; decisions FR-017, FR-018) and
  how a returned failure is classified in telemetry (FR-043).

This spec is the contract every other spec's result types, constructors and
ports follow. It defines no game rule. It builds on nothing but the binding
decisions (types ship in phase 0; decisions FR-014). Other files are cited, not
depended on: `dice-and-rolls.md` and `content-source-port.md` depend on this
one and own the concrete subtypes; `observability-ports.md` is cited for the
tracer exemption (FR-047) and the `error.type` key constant;
`release-0-1-0.md` and `content-schema-and-decoder.md` for the example-code scan
(FR-045) and the decoder test of FR-024.

**Out of scope:**

- Any concrete result type of a context (`ContentLookup`, `d20_test` outcomes,
  decoder failures, every `<UseCase>Result`); contexts define them following 4.3.
- Any shared result variant or failure-detail type. `MissingContent(kind, id)`
  is owned by `content` (decisions FR-018); FR-042 states the convention.
- Any concrete exception subtype and its fields: `DiceRollerException` is owned
  by [dice-and-rolls.md](dice-and-rolls.md), `ContentSourceException` by
  [content-source-port.md](content-source-port.md).
- A shared problem value object (each context owns its own; OQ-2) and a generic
  `Result<T, E>` (OQ-1).
- SRD content. Nothing here comes from SRD 5.2.1.

## 2. Source

n/a (package design). Derived from, and extending:

- `doc/rules/architecture.md` §4 (driven-port failure contract), §5 (decoders
  return every problem), §6 (errors and results), §7 (public API changes).
- `doc/rules/observability.md` §5 (error counter by error type; shared
  attribute values), §7 ("Errors: who records what").
- `doc/rules/testing.md` §4 ("Expected outcomes vs errors"), §5, §10.
- `doc/specs/shared-types-and-ownership.md` FR-017, FR-018, FR-038,
  FR-039, FR-041, FR-051, FR-055 (binding; wins on any conflict).
- `doc/roadmap.md`, Phase 0 (the base, not sealed, `Srd5eException` hierarchy).

The rule-file amendments this spec depends on were accepted by decisions FR-051
and are applied (architecture.md §6 and §1; observability.md §5 and §7).

Follow-ups outside this file (OQ-9): checks E1 to E8 (section 8) are owned here,
since `architecture-guardrails.md` declined to register them; `dice-and-rolls.md`
FR-048 and FR-084 cite FR-032 here for the guard, whose rows are FR-008 to
FR-017, FR-037 to FR-039 and FR-033. Specs known to cite FR-034 without an
FR-031 row (FR-053): character-creation.md, character-aggregate.md,
combat-foundations.md, combat-action-resolution.md, derived-stats.md,
feats-behaviour.md, level-advancement-and-multiclassing.md,
resolve-d20-test-use-case.md.

## 3. Vocabulary

Every row is a package term, not an SRD term.

| SRD term | Type | Notes |
|---|---|---|
| `Srd5eException` | `abstract base class`, implements `Exception` | Root of failures thrown by ports. Never an `Error`. Not `sealed` (FR-049). Not for subclassing outside the package (FR-050). |
| concrete subtype | `final class`, extends `Srd5eException` | One per port, defined in the spec that owns the port. |
| `cause` / `causeStackTrace` | `Object?` / `StackTrace?` | The original thrown object and its stack trace, unchanged. |
| `errorType` | `String get errorType` on the root | Value for `error.type`. Low-cardinality, stable, one per concrete subtype: the snake_case of the class name (`dice_roller_exception`). |
| sealed result | sealed class with `final` variants | Returns an expected outcome, absence or rejection. A use case's is `<UseCase>Result`; variants carry the operation prefix (FR-041). |
| failure detail | value object held as a field | Detail shared by several results (`MissingContent(kind, id)`), never a shared variant (FR-042). |
| problem | defined per context | One entry in a decoder failure that reports every problem (architecture §5). |
| rejection reason | typed value (enum or sealed) | The single typed reason a scalar `tryCreate` / `tryParse` returns (FR-035). |
| `wrapPortFailure`, `wrapPortFailureAsync` | functions | Sync and async guards used by adapters. |

## 4. Requirements

Source for every row is `n/a (package design)` plus the cited rule section.
Path labels follow `doc/rules/testing.md` §4, plus "architecture guardrail" for
rows enforced by `test/architecture/`. Convention rows (FR-018 onward) apply to
every type in the package; each context spec cites and tests them for its own
types.

### 4.1 The `Srd5eException` root

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-001 | `Srd5eException` MUST be an `abstract base class` that implements `Exception` and is not a subtype of `Error`, so a consumer can catch it with `on Srd5eException`. Its shape is in section 5. | architecture.md §4, §6 | happy |
| FR-002 | The root MUST store `cause` and `causeStackTrace` as `final` fields set through its `const` constructor (`const Srd5eException({this.cause, this.causeStackTrace})`), so a subtype passes them with `super.cause, super.causeStackTrace`. Every concrete subtype MUST be `final`, immutable and `const`-constructible, and MUST expose the `cause` and `causeStackTrace` it was built with, unchanged (same instance). Further typed fields belong to the owning port spec (OQ-6). | architecture.md §4 ("keeping the original as `cause`") | happy |
| FR-003 | `cause` and `causeStackTrace` MUST be optional; a subtype built without them reports `null` for both. | architecture.md §4 | unhappy (empty and minimal) |
| FR-004 | Every concrete subtype, including `DiceRollerException` (dice-and-rolls.md FR-049), MUST extend the FR-001 root and conform to FR-002, FR-003, FR-005 and FR-007. This spec defines no concrete subtype. | roadmap.md Phase 0; architecture.md §4 | happy |
| FR-005 | The root MUST declare an instance getter `String get errorType`. Each concrete subtype MUST return a constant, non-empty, lower-snake-case value equal to the snake_case of its class name, one value per subtype (not per reason or instance). The values are listed in section 7 and are a public telemetry contract (decisions FR-041; observability.md §5). | observability.md §5, §7 | happy |
| FR-006 | `errorType` values MUST be unique across all concrete subtypes. Check E1 scans `lib/src` for every class that `extends Srd5eException` and fails unless each is in the registry of sample instances in the test support code and the registry's `errorType` values are distinct. A new subtype fails the check until registered. | package design (extends observability.md §7) | n/a (architecture guardrail) |
| FR-007 | An `Srd5eException` subtype MUST carry data, not display text: no field or getter named `message`, `description`, `text` or `displayText`, and no code or test may depend on `toString` output. Path-like `String` fields (`path`) are allowed, because the rule is by name. | architecture.md §6 | n/a (architecture guardrail) |
| FR-049 | `Srd5eException` is deliberately not `sealed`: Dart allows extending a sealed class only inside its own library, and each port's subtype lives with its port. A `switch` over it is not exhaustive, so consumer code needs a default branch. The set of concrete subtypes is closed by documentation, check E1 and FR-050, not the compiler. | architecture.md §4, §6 | happy |
| FR-050 | The root's constructor MUST be annotated `@internal` (`package:meta`), so a consumer outside the package cannot subclass it without an analyzer warning. A consumer adapter throws the published port subtypes through their public constructors. The closed set is the one in section 7. | architecture.md §6 ("closed, documented set of subtypes") | n/a (architecture guardrail) |

### 4.2 Guard helpers for adapters

Signatures are frozen (OQ-7):

```dart
T wrapPortFailure<T>(
  T Function() body,
  Srd5eException Function(Object cause, StackTrace stackTrace) wrap,
);

Future<T> wrapPortFailureAsync<T>(
  Future<T> Function() body,
  Srd5eException Function(Object cause, StackTrace stackTrace) wrap,
);
```

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-008 | `wrapPortFailure` MUST return the value `body` returns, unchanged, and MUST NOT call `wrap`. | architecture.md §4 | happy |
| FR-009 | When `body` throws an `Exception` that is not an `Srd5eException`, `wrapPortFailure` MUST throw the object returned by `wrap`, called with that exception and its stack trace. | architecture.md §4, §6 | unhappy (failure of collaborator) |
| FR-010 | When `body` throws an `Srd5eException`, `wrapPortFailure` MUST rethrow the same instance and MUST NOT call `wrap` (no double wrapping). | architecture.md §6, observability.md §7 | unhappy (rule interaction) |
| FR-011 | When `body` throws an `Error` (for example `ArgumentError` or `StateError`), `wrapPortFailure` MUST let it propagate unchanged and MUST NOT call `wrap`. | architecture.md §6 ("Never catch `Error`") | unhappy (state error) |
| FR-012 | When `body` throws an object that is neither an `Exception` nor an `Error` (Dart permits any object), `wrapPortFailure` MUST let it propagate unchanged and MUST NOT call `wrap`. | architecture.md §6 | unhappy (failure of collaborator) |
| FR-013 | When `wrap` itself throws, that error MUST propagate; `wrapPortFailure` MUST NOT catch it. | architecture.md §6 | unhappy (failure of collaborator) |
| FR-014 | `wrapPortFailureAsync` MUST complete with the value `body`'s future completes with, unchanged, and MUST NOT call `wrap`. | architecture.md §4 | happy |
| FR-015 | When the future returned by `body` completes with a non-`Srd5eException` `Exception`, `wrapPortFailureAsync` MUST complete with an error identical to the object returned by `wrap`, called with that exception and its stack trace. | architecture.md §4 | unhappy (failure of collaborator) |
| FR-016 | When `body` throws synchronously before returning a future, `wrapPortFailureAsync` MUST apply the handling of FR-015 and return a failed future, never throw synchronously. | architecture.md §4 | unhappy (failure of collaborator) |
| FR-017 | In `wrapPortFailureAsync`, an `Srd5eException`, an `Error` or any other non-`Exception` object thrown or completed by `body` MUST NOT call `wrap` and MUST NOT be changed. Per FR-037 it surfaces as a failed future carrying the same instance, in both the thrown-synchronously and failed-future forms. | architecture.md §6 | unhappy (rule interaction) |
| FR-037 | `wrapPortFailureAsync` MUST be declared `async` (or be observationally equivalent): it never throws synchronously, and every non-value outcome is a failed future. A synchronous `Srd5eException`, `Error` or other object thrown by `body` becomes a failed future carrying that same instance. | architecture.md §4 | unhappy (failure of collaborator) |
| FR-038 | When `wrap` itself throws inside `wrapPortFailureAsync` (the async counterpart of FR-013), the returned future MUST fail with that error; the guard MUST NOT catch it or call `wrap` again. | architecture.md §6 | unhappy (failure of collaborator) |
| FR-039 | When a guard throws or fails with the object returned by `wrap`, it MUST do so with the original `stackTrace` (via `Error.throwWithStackTrace`), so the wrapper's stack trace points at the underlying failure. The same stack trace is what `wrap` receives. | architecture.md §4 | unhappy (failure of collaborator) |
| FR-040 | The guards MUST wrap only `Exception`s. A `String`, `int`, `Error` or other non-`Exception` thrown by a backend propagates unchanged (FR-011, FR-012, FR-017). This is a documented limitation, not an infrastructure-failure guarantee. | architecture.md §6 | unhappy (failure of collaborator) |
| FR-052 | `wrapPortFailure` MUST NOT be used with a `Future`-returning body: a failure arrives later and is not wrapped, so the adapter would leak a raw exception. An async body uses `wrapPortFailureAsync`. Detection is lexical (check E8): a `wrapPortFailure(` call (not `wrapPortFailureAsync(`) is flagged when its first argument closure is declared `async`, contains `await`, or the call has an explicit type argument starting `Future<`. A closure that returns a `Future` without `async` (for example `() => client.get()`) cannot be detected without type information; this documented limitation is covered by the adapter's contract suite (FR-032). | architecture.md §4 ("pick one per port, never `FutureOr`"), §6 | unhappy (rule interaction) |

### 4.3 Result conventions

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-018 | Every result type MUST be a `sealed class` whose direct variants are `final` (FR-044), so a consumer switches exhaustively (FR-045). An expected outcome, absence or rejection MUST be returned as a variant and MUST NOT be thrown. Naming is FR-041; shared failure detail is FR-042. | architecture.md §4, §6; decisions FR-017, FR-018 | happy |
| FR-019 | Result variants MUST be immutable (`@immutable`, `final` fields) and compared by value: equal data gives `==` and equal `hashCode`; any differing field gives inequality. | architecture.md §3 | happy |
| FR-020 | A sealed `<UseCase>Result` hierarchy and any rejection or problem type MUST carry typed data (ids, enums, numbers, value objects), never engine-generated display text: no field or getter named `message`, `description`, `text` or `displayText`. Consumers render their own text. Exempt, because they hold verbatim SRD text or describe telemetry: content value objects (`Spell.description`, `FeatureEntry.text`, `FeatureOption.text`, `NamedText`, `ToolUtilizeAction.description` and the like) and telemetry descriptors (the instrument `description` of observability-ports.md FR-025). The exemption is by declaration site: classes under `lib/src/content/domain/` and the observability descriptor classes under `lib/src/shared_ports/` are not scanned. | architecture.md §6 | architecture guardrail (check E2) |
| FR-021 | A collection exposed by a result or other value object that crosses a barrel MUST be unmodifiable, and MUST be a copy: mutating it throws `UnsupportedError`, and mutating the list passed to the constructor afterwards does not change the result. | architecture.md §4 ("Handoffs") | unhappy (immutability) |
| FR-022 | Results SHOULD carry the information needed to explain them (inputs, modifiers applied, roll made, DC) so consumers render their own breakdown. | architecture.md §6 | happy |
| FR-023 | A decoder or aggregate parser for untrusted input MUST list every problem found, not only the first, in a failure result. Each problem has a path and a typed kind, ordered deterministically (input order of the offending items). Scalar factories follow FR-035. The problem type is owned by the context (OQ-2). | architecture.md §5 | unhappy (invalid input) |
| FR-024 | A failure result that holds a problem list MUST NOT be constructible with an empty list; the constructor throws `ArgumentError`. A single-problem failure is valid. Tested in content-schema-and-decoder.md against its real failure type. | architecture.md §3 | unhappy (empty and minimal) |
| FR-025 | A non-throwing factory (`tryCreate` / `tryParse` / `parse`) MUST NOT throw for any input of its parameter type, including extreme values, empty strings and empty collections; it returns a failure result instead. | architecture.md §6 | unhappy (invalid input) |
| FR-026 | For the same input, a non-throwing factory returns a failure result if and only if the throwing constructor of the same type throws `ArgumentError`. | architecture.md §6 | unhappy (rule conflict) |
| FR-027 | A value-object constructor MUST throw `ArgumentError` (or a subtype such as `RangeError`) for an invalid argument, carrying the argument `name` and `invalidValue`. Tests assert the type and these fields, never the message text. | architecture.md §3, §6; testing.md §4 | unhappy (invalid input) |
| FR-028 | `StateError` MUST be used only for a broken invariant or API misuse that is a bug. An action that is illegal in the current state, but that a caller can reasonably attempt, MUST be a result variant. | architecture.md §6 | unhappy (state error) |
| FR-035 | A scalar non-throwing factory (`DiceExpression.tryParse`, `AbilityScore.tryCreate`) MUST return a failure carrying a single typed rejection reason (an enum or sealed value), never display text. It need not list every problem (FR-023 is for decoders). | architecture.md §5, §6 | unhappy (invalid input) |
| FR-041 | Every use case returns its own sealed result named `<UseCase>Result`. Its variants are prefixed with the operation (`DamageApplied`, `DamageRejected`, `CreateCharacterContentMissing`). Generic names (`Applied`, `Rejected`, `Succeeded`, `ContentMissing`, `Found`, `NotFound`) MUST NOT be exported from any barrel. | decisions FR-017; architecture.md §4, §9 | unhappy (name collision) |
| FR-042 | Failure detail shared by several results MUST be a value object held as a field of each variant, never a shared variant, because a Dart sealed hierarchy cannot span libraries. `content` owns `MissingContent(kind, id)`; this spec defines no shared detail type. | decisions FR-018 | happy |
| FR-043 | A failure returned as a result variant (decode failure, content not found; not a rule refusal, which is a normal outcome per observability.md §7), not thrown, MUST NOT be given an `error.type` value: that attribute is the closed set of FR-034. A use case counts a returned failure with `srd5e.outcome` = `failure` (the only values are `success` and `failure`) and puts the variant in a low-cardinality attribute defined by its own spec. A spec MUST NOT add other `srd5e.outcome` values, such as `rejected` or `refused`. Decided (OQ-11). | decisions FR-041, FR-051; observability.md §5 | unhappy (rule interaction) |
| FR-044 | Every `sealed class` under `lib/src` MUST have only `final` or `sealed` direct subtypes. Enforced by check E6. | architecture.md §3, §6 | n/a (architecture guardrail) |
| FR-045 | Consumer code that switches over a result MUST compile without a default branch; `dart analyze --fatal-infos` and the example-code scan in release-0-1-0.md FR-021 enforce this. | architecture.md §6 | happy |

### 4.4 Placement and use

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-029 | `Srd5eException`, its subtypes and the guards MUST NOT be referenced from any `domain/` file: domain code is pure and synchronous and reports expected outcomes as results. Enforced by the import rule (`architecture-guardrails.md` FR-015, FR-024); check E3 is the name-scan backstop. | architecture.md §1, §2, §6 | n/a (architecture guardrail) |
| FR-030 | Under `lib/`, no code may catch `Error`: a bare `catch`, `on Error`, `on Object` and `on dynamic` are forbidden, except the record-and-rethrow clause of FR-047. | architecture.md §6 ("Never catch `Error`") | n/a (architecture guardrail) |
| FR-046 | Every `catch` clause under `lib/` MUST have an `on` type matching `\w*Exception`. `on Exception` and narrower catches are allowed only to wrap, translate or record, and MUST rethrow unless they fully handle the exception. Except the clause of FR-047, which may catch `Object` or `Error`. | architecture.md §6 | n/a (architecture guardrail) |
| FR-047 | A clause that does nothing but record and ends in an unconditional `rethrow` MAY catch `Object` or `Error` (the tracer; observability-ports.md FR-012). Check E4 accepts it only when the last statement of the clause body is `rethrow` (lexer brace matching, architecture-guardrails.md FR-063). Authority: architecture.md §6 and observability.md §7 ("Programmer error" row), amended under decisions FR-051. | package design (extends architecture.md §6) | n/a (architecture guardrail) |
| FR-048 | `Future.catchError`, `Future.onError` and `runZonedGuarded` MUST NOT be used under `lib/`, since they bypass the `on` type rules. | architecture.md §6 | n/a (architecture guardrail) |
| FR-031 | A use case MUST let an `Srd5eException` thrown by a port propagate with its original type, `cause` and `causeStackTrace`. It MUST NOT convert it to a result and MUST NOT wrap it again. | architecture.md §4, observability.md §7 | unhappy (failure of collaborator) |
| FR-032 | Every port whose failure contract throws an `Srd5eException` subtype (`DiceRoller`, `ContentSource`) MUST ship a shared contract suite in `test/contract/` (not exported; decisions FR-039) proving that a backend `Exception` surfaces as the port's typed subtype with the original as `cause`. The observability ports are exempt (OQ-4): no subtype, and a thrown object propagates unchanged (observability-ports.md FR-012). The `DiceRoller` suite runs against `SeededDiceRoller` with a throwing `Random`, through the `failingVariant` hook (dice-and-rolls.md FR-048, FR-084). The content port suite is added when that port ships. | architecture.md §4; testing.md §10 | unhappy (failure of collaborator) |
| FR-033 | `Srd5eException`, `wrapPortFailure` and `wrapPortFailureAsync` MUST be exported from `lib/srd5e.dart` with dartdoc, so consumers can catch the root and write adapters with the same guards. A consumer adapter throws the published port subtypes; it does not subclass the root (FR-050). Each subtype is exported by its owning spec (dice-and-rolls.md FR-067, content-source-port.md FR-025); this requirement is the rule and those entries are the list. | architecture.md §7 | happy |
| FR-034 | A use case that records a thrown `Srd5eException` MUST set the `error.type` attribute to the exception's `errorType` getter, never `runtimeType` or `toString()`, so the attribute stays within the closed set of section 7. | observability.md §5, §7; decisions FR-041 | unhappy (failure of collaborator) |
| FR-036 | A port that returns data breaking its documented contract (for example a `DiceRoller` returning a roll for a different expression) has failed, not the caller. Detection MUST surface as the port's own concrete `Srd5eException` subtype carrying a typed reason (`DiceRollerException` with reason `invalidResult`), never as a `StateError`. An `Error` stays reserved for a caller breaking a documented precondition. | package design (extends architecture.md §4, §6) | unhappy (failure of collaborator) |
| FR-051 | When a port leaks an `Exception` that is not an `Srd5eException` (a contract breach, FR-032), the use case MUST NOT catch it: it propagates unchanged and the `Tracer` records it on the span as it passes through `trace` (observability-ports.md FR-012). No counter increment, no `error.type`, never converted to a result. A use case adds no `on Exception` clause for it (FR-046 would require a rethrow). observability.md §7 has no row for this case; it follows the "Programmer error" row by analogy. | architecture.md §6; observability.md §7 | unhappy (failure of collaborator) |
| FR-053 | The test plan of every use-case spec (one whose section 7 defines a `srd5e.<context>.<operation>` span) MUST contain a row for each of FR-031, FR-034 and FR-051, or state that the use case calls no port. Each such spec adds the row or states it has no port call (specs to act listed in section 2). Enforcement is a spec-set scan in `test/architecture/`, beside the citation check of decisions FR-052. | testing.md §2 | unhappy (rule interaction) |

### Withdrawn ids

None.

## 5. Model

| Situation | Mechanism | Examples |
|---|---|---|
| Expected outcome, absence, rejection | Sealed `<UseCase>Result` variant (FR-041) | A failed D20 Test; content id not found |
| Untrusted input fails validation | Sealed result from `tryCreate` / `tryParse` / a decoder | Host-supplied ability score; decoded content with problems |
| Infrastructure failure inside a port | `Srd5eException` subtype, thrown | `DiceRoller` implementation throws; content backend fails |
| A port returns contract-violating output | The port's subtype with a typed reason (FR-036) | `DiceRollerException` with reason `invalidResult` |
| Programmer error | `ArgumentError` / `StateError`, thrown, never caught | Constructor given an invalid argument |

Split rule: if a well-behaved caller can trigger it with valid dependencies, it
is a result. If a collaborator outside the package failed or broke its port
contract, it is an `Srd5eException`. If the caller broke a documented
precondition, it is an `Error`.

### Types

- `Srd5eException` lives in `lib/src/shared_ports/errors/` (OQ-10). Binding
  shape (FR-001, FR-002, FR-050):

  ```dart
  abstract base class Srd5eException implements Exception {
    @internal
    const Srd5eException({this.cause, this.causeStackTrace});
    final Object? cause;
    final StackTrace? causeStackTrace;
    String get errorType;
  }
  ```

- Concrete subtypes live with their port (`shared_ports/dice_roller/`,
  `content/application/ports/`) and are `final`; the owning spec defines fields.
- The guards live beside the root and may be used by any adapter, including
  `shared_ports/adapters/` and context `adapters/` (both may import
  `shared_ports`, architecture.md §1). Test doubles in `lib/src/testing/` throw
  the subtypes directly and do not need them (decisions FR-038).

### Factories

- Value-object constructors throw `ArgumentError` for trusted, already-validated
  values. Any type buildable from untrusted input also offers `tryCreate` or
  `tryParse`, and the two paths agree (FR-025, FR-026).
- A host-assembled command whose fields contradict each other is rejected by the
  command constructor with `ArgumentError`, unless the command is meant to take
  untrusted input, in which case a sealed result is used. Each spec states which.

## 6. Interface

- **Sync/async.** `wrapPortFailure` is for in-memory ports such as `DiceRoller`;
  `wrapPortFailureAsync` for ports that do I/O such as `ContentSource`
  (architecture §4: one per port, never `FutureOr`).
- **Port failure contract** (every port): expected absence or rejection is a
  sealed result in the return type; infrastructure failure and
  contract-violating output are a typed `Srd5eException`.
- **Exports.** `shared_ports/errors/` has no barrel; the root and guards are
  exported from `lib/srd5e.dart` (FR-033), not `lib/adapters.dart` (OQ-7).
  `lib/testing.dart` needs nothing from this spec.
- **Consumer view.** `on Srd5eException catch (e)` reads `e.errorType` and
  `e.cause`; a `switch` over `Srd5eException` needs a default branch (FR-049).

## 7. Observability

Silent by design: exception and guard types with no use case, no port call and
no I/O.

| Signal | Owned here |
|---|---|
| Metrics, spans, log events | none (nothing for doc/observability/signals.md) |

Nothing is logged or counted here (question 7); FR-010 and FR-031 prevent
double recording. The error counter, `error.type` and
`srd5e.outcome` are shared signals owned by the use case specs and
`observability-ports.md`.

The seven evaluation questions reduce to one answer: nothing runs here, so
nothing is emitted. Defects (a leaked raw exception, double wrapping, a swallowed
`Error`, a duplicate `errorType`) are caught by the FR-006 and FR-009 to FR-017
tests and the contract suites (FR-032). At run time, use cases record a thrown
`Srd5eException` once (FR-031) with `error.type` = `errorType` (FR-034); a
consumer should monitor any non-zero rate of a use case error counter with an
`error.type` from the table below, meaning a host-supplied port is failing or
breaking its contract. Diagnosis uses `errorType`, `cause` and `causeStackTrace`
(FR-002). FR-005 pins the values as a public telemetry contract.

Allowed `error.type` values for an `Srd5eException` (owned here; the key
constant is owned by observability-ports.md). A use case never uses
`runtimeType` or `toString` (FR-034).

| `error.type` value | Subtype | Owning spec |
|---|---|---|
| `dice_roller_exception` | `DiceRollerException` | dice-and-rolls.md |
| `content_source_exception` | `ContentSourceException` | content-source-port.md |

A new subtype adds a row here and a registry entry for check E1 (FR-006).
`content_source_exception` is a forward registration: its subtype ships with
the content port in phase 2. A non-`Srd5eException` `Exception` has no row: the
Tracer records it on the span as it propagates, with no counter and no
`error.type` (FR-051). Decode failures and not-found results are returned, so
they have no `error.type` at all (FR-043).

## 8. Test plan

Tests live in `test/shared_ports/errors/` and `test/architecture/`. Every test
cites its FR id. Unit tests of the root and guards use a test-local
`final class _TestException extends Srd5eException`, so they import nothing
from `dice_roller/` or `content` (testing.md §3). The registry of real subtypes
is used only by check E1 and the FR-004 and FR-005 tests, which are therefore
`architecture` level. Convention rows for result types are proved by the owning
specs' tests on their real types.

**Architecture checks** (owned here; each has a violating and a clean fixture
beside it, testing.md §8; comments and strings never trigger them, via
architecture-guardrails.md FR-008, FR-063). FR-006, FR-007, FR-018, FR-020,
FR-029, FR-030, FR-044, FR-046, FR-047, FR-048, FR-050, FR-052 and FR-053 are
enforced by these checks.

| Check | Covers | Rule |
|---|---|---|
| E1 | FR-001, FR-006, FR-049, FR-050 | Every class extending `Srd5eException` is in the registry; registry `errorType` values are distinct. The root's declaration tokens read `abstract base class` and `sealed` is absent; its constructor carries `@internal`. |
| E2 | FR-007, FR-020 | No field or getter named `message`, `description`, `text` or `displayText` on an `Srd5eException` subtype, a sealed `<UseCase>Result` class or variant, or a rejection or problem type. `lib/src/content/domain/` and telemetry descriptor classes under `lib/src/shared_ports/` are exempt. Path-like `String` fields are not flagged (by name, not type). |
| E3 | FR-029 | Backstop: `Srd5eException` or an E1 class name appears in code (not comments or strings) of a `domain/` file. |
| E4 | FR-030, FR-046, FR-047 | Every `catch` has an `on` type matching `\w*Exception`; no bare `catch`, `on Error`, `on Object`, `on dynamic`, except a clause whose body ends in `rethrow`. |
| E5 | FR-034 | Lexical, no registry: the `error.type` constant is assigned only from a `.errorType` getter; `runtimeType` and `toString(` are banned in `application/` files that mention it. Closed value sets are checked by architecture-guardrails.md FR-085 (FR-043). |
| E6 | FR-018, FR-044 | Every `sealed class` under `lib/src` has only `final` or `sealed` direct subtypes. |
| E7 | FR-048 | `catchError`, `onError` and `runZonedGuarded` tokens are absent under `lib/`; part of E4's module. |
| E8 | FR-052 | A `wrapPortFailure(` call whose closure is `async`, contains `await`, or has a `Future<` type argument is flagged. |

| Id | Level | Notes |
|---|---|---|
| FR-001 | unit, architecture | Unit: `_TestException` is `isA<Exception>()` and `isNot(isA<Error>())`. Architecture (E1): a fixture with a `sealed` or non-`base` declaration is flagged. |
| FR-002, FR-003 | unit | `identical` cause and stack trace through `super.cause, super.causeStackTrace`; a `const` `_TestException` can be created; both fields null when omitted. |
| FR-004, FR-005 | architecture | Per registered real subtype: extends the root, passes FR-002/FR-003; `errorType` matches `^[a-z][a-z0-9_]*$`, equals the section 7 value and the snake_case of the scanned class name (computed in the test, not from `runtimeType` in `lib/`). Subtype fields are tested in the owning spec. |
| FR-006, FR-007, FR-049, FR-050 | architecture | Checks E1 and E2: duplicate `errorType` and unregistered subtype flagged; `message`/`description`/`text`/`displayText` flagged, `path` not; `sealed` root flagged; constructor `@internal` read from the lexer's annotation token. |
| FR-008, FR-014 | unit | Sync table (int, null, empty list) and async success, including a future completing later; `wrap` spy never called. |
| FR-009, FR-015, FR-016 | unit | `FormatException` and a custom `Exception` (sync body, failed future, throw-before-future): the result is the `wrap`-returned object (`identical`), `cause` identical, stack trace present; the async call does not throw synchronously. Test-local `wrap` returns `_TestException`. |
| FR-010, FR-011, FR-012, FR-040 | unit | Same `Srd5eException` instance rethrown; `ArgumentError`, `StateError`, `RangeError`, a `String` and an `int` propagate as the same instance; `wrap` not called. |
| FR-013, FR-038 | unit | `wrap` throws `StateError`; that propagates (sync, sync-throw and failed-future async paths); `wrap` called once. |
| FR-017, FR-037 | unit | Table of `Srd5eException`, `Error`, `String`, each thrown-synchronously and failed-future: the call returns a future (does not throw) that fails with the same instance; `wrap` not called. |
| FR-039 | unit | `wrap` spy records the stack trace; the thrown wrapper's `StackTrace` equals it (`Error.throwWithStackTrace`), sync and async. |
| FR-018, FR-044 | architecture | Check E6 (fixture: a `sealed class` with a non-`final` direct subtype is flagged) plus the barrel scan of FR-041. |
| FR-020 | architecture | Check E2 over every sealed result hierarchy and rejection or problem type; fixtures: a `final` variant with a `message` field is flagged; a content value object with `text` under `content/domain/` and a telemetry descriptor with `description` are not. |
| FR-029 | architecture | Denylist (root plus every transitive `extends`/`implements`) scanned over `domain/` files. |
| FR-030, FR-046, FR-047 | architecture | Check E4: `on` types not matching `\w*Exception` and a `catch` without `on` are flagged; a clause ending in `rethrow` is accepted; the same clause with a statement after `rethrow`, or ending in `return`, is flagged. |
| FR-048 | architecture | Check E7: each of `catchError`, `onError` and `runZonedGuarded` is flagged. |
| FR-031 | application | Per use case, with a failing double from `testing.dart`: same type, same `cause`, thrown not returned. |
| FR-032 | contract | Per port's suite in `test/contract/`: a backend `Exception` yields the typed subtype with `cause`. Phase 0 covers `DiceRoller` (dice-and-rolls.md FR-048, FR-084). Negative self-test: a leaking adapter (raw `FormatException`) makes the suite fail. |
| FR-033 | scenario | Public-API test importing only `package:srd5e/srd5e.dart`: catch `Srd5eException`, call the guards. |
| FR-034 | application, architecture | Per use case: recorded `error.type` equals the thrown subtype's `errorType`. Architecture: check E5. |
| FR-036 | unit | In the port's owning spec: a wrong-data double yields the subtype with the typed reason; never `StateError`. |
| FR-041, FR-042 | architecture, unit | Barrel scan (architecture.md §9): a generic variant name, a duplicate exported name or a variant shared between two results fails; each result is `<UseCase>Result` with operation-prefixed variants; each variant carries its detail as a field (`MissingContent`) in the owning spec. |
| FR-043 | architecture, application | Closed value sets: architecture-guardrails.md FR-085. Per use case: a returned failure records `srd5e.outcome = failure` and no `error.type`. |
| FR-045 | scenario | `dart analyze --fatal-infos` over the example code (no `default` arm in a switch over a result) and the scan in release-0-1-0.md FR-021. |
| FR-051 | application | Per use case: a double throwing a raw `Exception` records no `error.type` (the `Tracer` double records it on the span), no counter increments, the same instance propagates, the use case has no catch clause. |
| FR-052 | architecture | Check E8 fixtures: an `async` closure, an `await` inside and `wrapPortFailure<Future<int>>(` are flagged; a sync closure and `wrapPortFailureAsync(` with an `async` closure are not. |
| FR-053 | architecture | Spec-set scan: each use-case spec's test plan cites FR-031, FR-034 and FR-051 or states it calls no port; a fixture spec missing a row is flagged. |

| FR-019, FR-021, FR-023 to FR-028, FR-035 | unit (owning spec) | Per-type cases listed below. |
| FR-022 | review | SHOULD, checked in code review. |

Not tested in this spec (owning-spec tests cite `Requirement:
doc/specs/errors-and-results.md FR-nnn`), with the per-type case each owes:
FR-018 an expected-outcome case returns a variant without throwing, and the
context's own switch over the result is exhaustive; FR-019 equality, hash, per-field inequality; FR-021 mutation throws
`UnsupportedError` and source-list mutation leaves the result unchanged; FR-023
several problems at once in deterministic order; FR-024 empty list throws
`ArgumentError`, one problem accepted (content-schema-and-decoder.md);
FR-025 and FR-026 extremes and empty input never throw, one input table through
both paths; FR-027 `throwsA(isA<ArgumentError>().having(...name...invalidValue...))`;
FR-028 illegal-state action returns a variant, `StateError` only for a broken
invariant; FR-035 typed reason, no `String` display field. FR-022 is a SHOULD
checked in code review, as is that nothing depends on `toString` text (FR-007).

A context spec that creates a result, factory, use case or port without a test
for the matching row is incomplete.

Deliberately not covered: FR-022 - a SHOULD about what a result carries, judged in code review; no assertion can say whether a breakdown is enough.

Deliberately not covered: FR-023 - no decoder or aggregate parser exists in phase 0; the several-problems case is owed by content-schema-and-decoder.md against its real failure type.

Deliberately not covered: FR-024 - no failure result with a problem list exists in phase 0; content-schema-and-decoder.md tests it against its real type.

Deliberately not covered: FR-028 - no state-dependent action or use case exists in phase 0, so there is no illegal-in-this-state case to attempt; the first context with one owes the test.

Deliberately not covered: FR-031 - no use case exists in phase 0; each use-case spec owes the row, and the spec-set scan of FR-053 requires it.

Deliberately not covered: FR-041 - no use case or `<UseCase>Result` exists in phase 0; the generic-name and duplicate-name barrel scan is architecture-guardrails.md FR-077 (deferred to that check), and each use-case spec owes its naming test.

Deliberately not covered: FR-042 - no result variant shares a failure detail value object in phase 0; `content` owns `MissingContent` and tests it in its own spec.

Deliberately not covered: FR-043 - no use case exists in phase 0 to count a returned failure; the closed value sets are architecture-guardrails.md FR-085 (deferred to that check) and each use-case spec owes the `srd5e.outcome = failure`, no `error.type` row.

Deliberately not covered: FR-051 - no use case exists in phase 0 to propagate a leaked raw `Exception`; each use-case spec owes the row (FR-053), and the `Tracer` side is observability-ports.md FR-012.

- **Mutation testing:** `mutate4dart` on `lib/src/shared_ports/errors`,
  threshold 80, although only `domain/` is mandatory (testing.md §8), because
  every context depends on these branches. Keep `toString` trivial or silence
  equivalent mutants with a reason.

## 9. Open questions and decisions

No open questions. Settled ones, one line each:

| Id | Decision |
|---|---|
| OQ-1 | No generic `Result<T, E>`: each use case has its own `<UseCase>Result` (FR-041). Revisit only if three or more contexts copy one shape after release. |
| OQ-2 | No shared problem value object; each context owns its own (decisions FR-018; FR-042). |
| OQ-3 | Guards live in `shared_ports/errors/` (OQ-10). |
| OQ-4 | Observability ports get no `Srd5eException` subtype in phase 0; a thrown object propagates as the host's error, and the tracer rethrows what it records (FR-047). Reopen only if a real failure shows up. |
| OQ-5 | `abstract base class`, not `sealed` (FR-001, FR-049): `dart analyze` reports `invalid_use_of_type_outside_library` for a cross-library sealed extension. Cost: no compiler exhaustiveness; adding a subtype is breaking after release, not before. Accepted by decisions FR-051. |
| OQ-6 | Subtypes carry extra typed fields, owned by the port spec (`DiceRollerException`: dice-and-rolls.md FR-049; `ContentSourceException`: `query`, content-source-port.md FR-018). The root carries only `cause`, `causeStackTrace` and `errorType`. |
| OQ-7 | Guards are exported from `srd5e.dart` (FR-033), not `adapters.dart`; the 4.2 signatures are frozen. |
| OQ-8 | `cause` is `Object?`: Dart can throw anything and hand-written adapters may wrap non-`Exception`s. |
| OQ-9 | Outside edits settled by decisions FR-051 and FR-055: rule-file amendments applied; the stale `shared_kernel/errors/` wording is `dice-and-rolls.md`'s to fix (section 2); E1 to E8 are owned here. |
| OQ-10 | The root and guards live in `lib/src/shared_ports/errors/` (decisions FR-055): the kernel is small, pure and synchronous (architecture.md §2), and the import rule (`domain/` may not import `shared_ports`) enforces FR-029 for free. |
| OQ-11 | A returned failure carries no `error.type` (FR-043; decisions FR-041, FR-051). |

## 10. Changelog impact

`CHANGELOG.md`, `Unreleased`, **Added**:

- "`Srd5eException` base class (port exceptions extend it), the
  `wrapPortFailure` and `wrapPortFailureAsync` adapter guards, and the
  documented rules for results versus exceptions versus `ArgumentError`."

Not **BREAKING**: the package is unreleased. After release, adding a subtype to
`Srd5eException`, or removing or renaming an `errorType` value, is **BREAKING**
(architecture §7, observability §5).
