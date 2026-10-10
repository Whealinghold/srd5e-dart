# Observability ports and `lib/testing.dart`

| | |
|---|---|
| Status | implemented |
| Context | `shared_ports` |
| Roadmap phase | 0 |
| Depends on | `errors-and-results.md` |

## 1. Purpose and scope

Defines the three observability ports (`Logger`, `Tracer`, `Meter`), the
`Observability` bundle, their `const` no-op defaults (`NoopLogger`, `NoopTracer`,
`NoopMeter`, `NoopObservability`; in the port library, not an adapters folder:
`shared-types-and-ownership.md` FR-036), the `Meter` timing operation that stands
in for clock access, the recording test doubles (in `lib/src/testing/`, shipped
from `package:srd5e/testing.dart`: `shared-types-and-ownership.md` FR-038), and
the shape of `lib/testing.dart`. Every use case takes these ports
(`doc/rules/observability.md` §4), so this is the contract the package is
instrumented against. Type phase 0.

**Dependencies (prose; the header lists tokens only, FR-056 of
`shared-types-and-ownership.md`).** `shared-types-and-ownership.md` is binding
(FR-014, FR-036 to FR-039, FR-041, FR-051). `errors-and-results.md` supplies the
catch-`Error` rule FR-030 with its record-and-rethrow exemption FR-047 (used by
FR-012 and FR-054) and the rule that a returned failure carries no `error.type`
(FR-043, cited by FR-059). `dice-and-rolls.md` FR-064 has the consumer inject the
seeded `Random` (why FR-053 has no carve-out) and specifies the `DiceRoller`
double that `lib/testing.dart` exports. `architecture-guardrails.md` is a prose
reference only (`shared-types-and-ownership.md` FR-061): its FR-038 (span-name
regex, FR-024), FR-082 (port scan and `portHandles`, FR-065) and FR-028, FR-074,
FR-075, FR-076 (checks FR-050, FR-053, FR-060 point to). This spec supplies
`AttributeKeys` (FR-052) to it. `shared_ports` may depend on `shared_kernel`;
this spec needs nothing from it.

**Rule-file amendments (applied).** `shared-types-and-ownership.md` FR-051
accepted the rule text this spec relies on; the rule files carry it with fresh
tags (FR-059): async wrappers `traceAsync` and `timeAsync`
(`observability.md` §4, `architecture.md` §4); closure-only log attributes and
no `error.type` on a returned failure (`observability.md` §7); `const` no-op
instances exempt from the static or top-level logger, tracer or meter ban
(`observability.md` §4, §10, §11; `architecture.md` §10).

**Out of scope:**

- Any game rule. This spec has no SRD content.
- Which signals a use case emits (each context's specs and
  `doc/observability/signals.md`). The ports emit nothing (section 7).
- Bridges to `package:logging`, OpenTelemetry, Sentry or any SDK: not shipped
  (`observability.md` §4); examples go in `example/` and the README.
- Trace-context propagation across zones or async gaps: the consumer adapter's
  job (`observability.md` §6).
- The `DiceRoller` double and doubles for other ports (such as the fake content
  source: `shared-types-and-ownership.md` FR-038). `lib/testing.dart`
  re-exports them; only the entry point's shape is fixed here.
- The value sets of shared attribute keys: see `shared-types-and-ownership.md`
  FR-041 and `observability.md` §5. This spec defines only the key constants
  (FR-052).
- A helper asserting "same result with no-op and recording observability":
  deferred (section 9).

## 2. Source

`n/a (package design)`. Derived from `shared-types-and-ownership.md` (FR-013,
FR-014, FR-036 to FR-039, FR-041, FR-051; ids of other specs are written with
the file name) and:

- `doc/rules/observability.md` §1, §4 (ports, timing), §5 (naming, attributes,
  units), §6 (traces), §7 (levels, lazy attributes, errors), §9, §10, §11.
- `doc/rules/architecture.md` §1, §3 (no clock), §4 (observability is
  synchronous), §6, §7 (entry points, every port ships a double), §9, §10.
- `doc/rules/testing.md` §3, §4 (state errors, boundaries, invalid input, empty
  and minimal, immutability), §6, §10.

## 3. Vocabulary

No SRD terms apply. Package terms:

| Term | Type | Notes |
|---|---|---|
| `Logger`, `Tracer`, `Meter` | driven ports | Emit a log event; run work in a named span; create instruments and time work. |
| `LoggerLevels` | extension on `Logger` | Shortcuts `finest`, `fine`, `info`, `warning`, `severe`. |
| `Span` | handle | Passed to the work run by `Tracer`; carries attributes, status, recorded errors. |
| `SpanStatus` | enum | `unset`, `ok`, `error`. |
| `Counter`, `Histogram`, `Gauge` | handles | Created by `Meter`. |
| `InstrumentKind` | enum | `counter`, `histogram`, `gauge`. Test-only, exported by `testing.dart`; the `kind` of a `MeasurementRecord`. |
| `LogLevel` | enum | `finest`, `fine`, `info`, `warning`, `severe`. |
| `Attributes` | typedef | `Map<String, Object>`; values are `String`, `bool`, `int` or `double`. |
| `AttributeKeys` | constants class | Shared keys `outcome` and `errorType` (FR-052). |
| `LogRecord`, `SpanRecord`, `MeasurementRecord` | record types | What the recording doubles store; in `lib/src/testing/`, exported by `testing.dart` only. |
| `Observability` | value object | Immutable bundle of the three ports. |
| No-op | implementation | `NoopLogger`, `NoopTracer`, `NoopMeter`, `NoopObservability`: `const`, silent, stateless, read no clock. Not adapters (`shared-types-and-ownership.md` FR-036). |
| No-op handles | implementation | The no-op `Span`, `Counter`, `Histogram`, `Gauge` (FR-019, FR-020, FR-064): private `const` classes (`_NoopSpan`, `_NoopCounter`, `_NoopHistogram`, `_NoopGauge`) in `lib/src/shared_ports/observability/`, not exported, so the `Noop*` naming rule of `architecture-guardrails.md` FR-084 does not apply; still stateless and `const`. |
| Recording double | test double | `RecordingLogger`, `RecordingTracer`, `RecordingMeter`, `RecordingObservability`; in `lib/src/testing/` (`shared-types-and-ownership.md` FR-038). |

## 4. Requirements

One behaviour each. Source is the rule-file section named in the row. Test names
cite `doc/specs/observability-ports.md` and the FR id.

### 4.1 Logger

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-001 | `LogLevel` MUST have exactly the values `finest`, `fine`, `info`, `warning`, `severe`, in ascending severity. It MUST NOT have a `shout`/`fatal` value. | observability.md §7, "Levels" | happy |
| FR-002 | `Logger` MUST expose `bool isEnabled(LogLevel level)` and `void log(LogLevel level, String message, {Map<String, Object> Function()? attributes, Object? error, StackTrace? stackTrace})`. Attributes are a closure so they are built only when needed. | observability.md §4, §7 "Cheap when disabled" | happy |
| FR-003 | `NoopLogger.isEnabled` MUST return `false` for every `LogLevel`. | observability.md §4, "No-op by default" | happy |
| FR-004 | `NoopLogger.log` MUST NOT invoke the `attributes` closure and MUST have no observable effect, for every level and with or without `error` and `stackTrace`. | observability.md §1.5, §7 | happy |
| FR-005 | Level shortcuts (`finest`, `fine`, `info`, `warning`, `severe`, in the public extension `LoggerLevels on Logger`) MUST delegate to `log` with the matching level and pass `message`, `attributes`, `error` and `stackTrace` through unchanged. | observability.md §7 | happy |
| FR-006 | Every `Logger` implementation MUST NOT invoke the `attributes` closure when `isEnabled(level)` is `false` for that call. | observability.md §7 "Cheap when disabled" | unhappy (collaborator: disabled level) |
| FR-007 | `RecordingLogger` MUST store one `LogRecord` (level, message, attributes, error, stack trace) per enabled call, in call order. | observability.md §9 | happy |
| FR-008 | `RecordingLogger` MUST have a `minLevel` (default `LogLevel.finest`). A call below `minLevel` MUST NOT be recorded; a call exactly at `minLevel` MUST be recorded; `isEnabled` MUST agree with both. | observability.md §7 | unhappy (boundary) |
| FR-009 | `RecordingLogger` MUST invoke the `attributes` closure exactly once per recorded call and store an unmodifiable copy. When no closure is given, the record's attributes MUST be an empty map. | observability.md §7 | unhappy (empty and minimal) |
| FR-010 | Each recording double (`RecordingLogger`, `RecordingTracer`, `RecordingMeter`) MUST throw `ArgumentError` when given an attribute value that is not a `String`, `bool`, `int` or `double`, naming the offending key. | observability.md §4 "No vendor types", §5 "Attributes" | unhappy (invalid input) |

### 4.2 Tracer and Span

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-011 | `Tracer.trace<T>(String name, T Function(Span span) body, {Map<String, Object> attributes = const {}})` MUST run `body` exactly once with a `Span` and return its value. | observability.md §4, §6 | happy |
| FR-012 | When `body` throws (an `Exception` or an `Error`), `trace` MUST set the span status to `error`, record the thrown object and its stack trace on the span, end the span, and rethrow the same object. It MUST NOT wrap or swallow it. Implementations catch with a clause that only records and ends in an unconditional `rethrow`; this is the one catch-`Error` shape that `architecture.md` §6 and `errors-and-results.md` FR-030 (the rule) allow through the exemption in `errors-and-results.md` FR-047, and the clause MUST contain nothing else. | observability.md §6, §7 "Errors: who records what"; errors-and-results.md FR-047, FR-030 | unhappy (failure) |
| FR-013 | `Tracer.traceAsync<T>` (same parameters, `Future<T> Function(Span)`) MUST end the span only when the returned future completes, and return its value. | observability.md §6; architecture.md §4 | happy |
| FR-014 | When the future given to `traceAsync` completes with an error, the span MUST get the same treatment as in FR-012, and the same error MUST propagate. | observability.md §6 | unhappy (failure) |
| FR-015 | `Span.setAttribute(String key, Object value)` MUST add the attribute or overwrite an earlier value for the key. Attributes passed to `trace` MUST be present from the start. | observability.md §6 | happy |
| FR-016 | A new span's status MUST be `SpanStatus.unset`. `Span.setStatus` MUST change it, and the last call MUST win. | observability.md §6 | happy |
| FR-017 | `Span.recordError(Object error, StackTrace stackTrace)` MUST append the error to the span in call order and MUST NOT change the span's status or end it. A failure result (not a thrown error) is recorded by the use case calling `setStatus(error)`. | observability.md §6, §7 | happy |
| FR-018 | If `body` sets status `ok` or `unset` and then throws, the final status MUST be `error`. | observability.md §6 | unhappy (rule interaction) |
| FR-019 | `NoopTracer.trace` and `traceAsync` MUST run `body` once with a no-op span, return its result, and let any thrown error propagate unchanged; a synchronous throw from a `traceAsync` body surfaces as a failed `Future` (FR-054). | observability.md §4 | happy |
| FR-020 | A no-op span MUST accept `setAttribute`, `setStatus` and `recordError` at any time, including after `trace` has returned, without throwing and without changing any recorded state. | observability.md §1.5 | unhappy (state) |
| FR-021 | `RecordingTracer` MUST store one `SpanRecord` per span, in span start order (a parent precedes its children): name, final attributes (start attributes plus later ones), status, recorded errors, `parent` (FR-022), and whether it ended. A `SpanRecord` is mutable through its recording span while the span is open and frozen once it has ended. | observability.md §9 | happy |
| FR-022 | When `trace` is nested inside another `trace` (nested synchronous use, or sequential async use; interleaved concurrent `traceAsync` calls are not supported, section 9), the inner `SpanRecord.parent` MUST be the outer record; for a top-level span it MUST be `null`. | observability.md §6, §7 ("inner spans still record status") | unhappy (rule interaction) |
| FR-023 | After the span has ended (`trace` has returned or thrown, or the future given to `traceAsync` has completed), a `RecordingTracer` span MUST throw `StateError` on `setAttribute`, `setStatus` or `recordError`. | testing.md §4 "State errors" | unhappy (state) |
| FR-024 | `RecordingTracer` MUST reject a span name that does not match `^srd5e\.[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$` (the regex of `architecture-guardrails.md` FR-038: `srd5e` prefix, at least three parts, each part starting with a letter) with `ArgumentError`. | observability.md §5 "Naming"; architecture-guardrails.md FR-038 | unhappy (invalid input) |

### 4.3 Meter and instruments

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-025 | `Meter` MUST offer `createCounter`, `createHistogram` and `createGauge`, each taking a name and optional `unit` (UCUM string, default empty) and `description`, and returning an instrument that exposes `name`, `unit` and `description` as getters returning exactly the values given. | observability.md §4, §5 "Naming" | happy |
| FR-026 | `Counter.add(int value, {Attributes attributes = const {}})` on an instrument created by `RecordingMeter` MUST record the value and attributes of each call. | observability.md §4, §5 | happy |
| FR-027 | `RecordingMeter`'s `Counter.add` MUST accept `0` and MUST throw `ArgumentError` for a negative value. | testing.md §4 "Boundaries" | unhappy (boundary) |
| FR-028 | `Histogram.record(num value, {attributes})` and `Gauge.record(num value, {attributes})` MUST each be recorded by `RecordingMeter` as one measurement with the given value and attributes. | observability.md §5 "What to record" | happy |
| FR-029 | `Meter.time<T>(Histogram histogram, T Function() body, {attributes})` MUST run `body` exactly once, return its value, and record one measurement into `histogram` of the elapsed time in seconds as a `double`. | observability.md §4 "Timing" | happy |
| FR-030 | If `body` passed to `time` throws, `time` MUST still record the elapsed time and MUST rethrow the same object. | observability.md §4 "Timing"; testing.md §4 | unhappy (failure) |
| FR-031 | `Meter.timeAsync<T>(Histogram, Future<T> Function() body, {attributes})` MUST record the elapsed seconds when the future completes, and return its value. | observability.md §4 | happy |
| FR-032 | If the future passed to `timeAsync` completes with an error, the elapsed time MUST still be recorded and the same error MUST propagate. | observability.md §4 | unhappy (failure) |
| FR-033 | `NoopMeter.time` and `timeAsync` MUST run `body` once, return its result, record nothing, read no clock, and let any thrown error propagate unchanged; a synchronous throw from a `timeAsync` body surfaces as a failed `Future` (FR-055). | observability.md §4, architecture.md §3 | happy |
| FR-034 | `NoopMeter.createCounter`, `createHistogram` and `createGauge` MUST accept any name, unit and description (including an empty name and empty strings) without throwing, and return an instrument. | observability.md §1.5 | unhappy (empty and minimal) |
| FR-035 | `RecordingMeter` MUST store one `MeasurementRecord` per measurement (instrument name, `InstrumentKind` kind, unit, value, attributes), in call order, across all instruments. | observability.md §9 | happy |
| FR-036 | `RecordingMeter` timing MUST be deterministic: the elapsed time recorded by `time` and `timeAsync` is the meter's current `timedDuration` (default `Duration.zero`), converted to seconds. | testing.md §6 "Deterministic" | unhappy (determinism) |
| FR-037 | Setting `RecordingMeter.timedDuration` to a negative `Duration` MUST throw `ArgumentError`. | testing.md §4 "Boundaries" | unhappy (boundary) |
| FR-038 | When name, kind, `unit` and `description` all equal an existing instrument's, `RecordingMeter` MUST return that same instrument. The same name with a different kind, or the same name and kind with a different `unit` or `description`, MUST throw `StateError` (the first definition is kept). | testing.md §4 "State errors" | unhappy (state) |
| FR-039 | `RecordingMeter` MUST reject an instrument name that does not match the pattern in FR-024 with `ArgumentError`. | observability.md §5 "Naming" | unhappy (invalid input) |
| FR-040 | `RecordingMeter.time` and `timeAsync` MUST throw `ArgumentError` when the histogram was not created by that meter. | testing.md §4 "Invalid input" | unhappy (invalid input) |

### 4.4 Observability bundle and recording bundle

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-041 | `Observability` MUST have a `const` constructor with named `logger`, `tracer` and `meter` parameters, each defaulting to its no-op. | observability.md §4 "No-op by default" | happy |
| FR-042 | `Observability.none` MUST be `const NoopObservability()` (FR-062), a bundle of the three no-ops, canonicalised so `identical(Observability.none, const NoopObservability())` holds. Use cases take `Observability observability = Observability.none` and MUST NOT null-check it. | observability.md §4 | happy |
| FR-043 | Supplying only one port to `Observability` MUST leave the other two as their no-ops (not `null`). Each default port, exercised through the bundle (`isEnabled` is `false`, `trace` runs the body, `time` runs the body and records nothing), MUST behave as a no-op. | testing.md §4 "Empty and minimal" | unhappy (empty and minimal) |
| FR-044 | `Observability` MUST be annotated `@immutable` with `final` fields; the analyzer's `must_be_immutable` lint (under `dart analyze --fatal-infos`) enforces it. | architecture.md §3 | architecture (enforced by the analyzer) |
| FR-045 | `RecordingObservability` MUST create one `RecordingLogger`, `RecordingTracer` and `RecordingMeter` (constructor takes optional `minLevel` and `timedDuration`), expose them, and expose `observability`, an `Observability` wrapping exactly those three objects. | observability.md §9 | happy |
| FR-046 | `RecordingObservability.clear()` MUST remove only the log, span and measurement records. It MUST keep created instruments (`RecordingMeter.instruments`) and configuration (`minLevel`, `timedDuration`); earlier instruments stay valid and keep recording. | testing.md §6 "Independent" | unhappy (state) |
| FR-047 | Lists exposed by the recording doubles (`records`, `spans`, `measurements`, a span's errors) MUST be unmodifiable views, and a stored attributes map MUST NOT change when the caller later mutates the map it passed. | testing.md §4 "Immutability" | unhappy (immutability) |

### 4.5 Package shape and guardrails

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-048 | `lib/srd5e.dart` MUST export `Logger`, `LogLevel`, `LoggerLevels` (the level-shortcut extension), `Tracer`, `Span`, `SpanStatus`, `Meter`, `Counter`, `Histogram`, `Gauge`, `Attributes`, `Observability`, the four no-ops (`NoopLogger`, `NoopTracer`, `NoopMeter`, `NoopObservability`), and `AttributeKeys` (FR-052). Every exported member MUST have a dartdoc comment, and the dartdoc of each port (`Logger`, `Tracer`, `Meter`) MUST state the contract in FR-056 (`InstrumentKind` is not exported here: it is test-only, FR-049), and that of `Tracer.trace` and `Meter.time` the restriction in FR-057. | architecture.md §7 | happy |
| FR-049 | `lib/testing.dart` MUST export the recording doubles, their record types (`LogRecord`, `SpanRecord`, `MeasurementRecord`) and `InstrumentKind`, all implemented under `lib/src/testing/`, and MUST be the only entry point that exports any double. `lib/srd5e.dart` MUST NOT export any double. | architecture.md §7; shared-types-and-ownership.md FR-038 | happy |
| FR-050 | Pointer, no check here: `architecture-guardrails.md` FR-076 bans `package:test`, `package:test_api`, `package:matcher` and `package:coverage` for every file under `lib/`, which covers `lib/testing.dart` and `lib/src/testing/`, and FR-083 checks `dependencies:`. A wider ban on any `dev_dependencies` package would be a request to extend `architecture-guardrails.md` FR-076, not a check owned here. | testing.md §6 "No test-only code in `lib/`"; architecture-guardrails.md FR-076, FR-083 | guardrail |
| FR-051 | Files under `lib/src/shared_ports/` (including any `adapters/` folder there) MUST import nothing from the package except `lib/src/shared_kernel/` and other files of `lib/src/shared_ports/` itself; a file outside `shared_ports/adapters/` MUST NOT import that folder (this matches `architecture-guardrails.md` FR-024 and FR-017). The no-ops MUST be `const` classes in the port library, not under an `adapters/` folder (`shared-types-and-ownership.md` FR-036). They MUST NOT import `dart:io`, `dart:ui`, an SDK, or `package:logging`. No port, no-op or recording double may hold a top-level or `static` non-`const` logger, tracer or meter; `const` instances of the no-op classes are exempt (FR-059). | architecture.md §1, §9; observability.md §4, §10; architecture-guardrails.md FR-017, FR-024 | architecture |
| FR-052 | The shared attribute keys MUST be defined in one `abstract final class AttributeKeys` declared in `lib/src/shared_ports/signals.dart` (the shared constants file of `architecture-guardrails.md`), with `static const String outcome = 'srd5e.outcome'` and `static const String errorType = 'error.type'`, exported from `lib/srd5e.dart` (FR-048). Other specs refer to `AttributeKeys.outcome` and `AttributeKeys.errorType`. The class is the only definition site: no other file under `lib/` may contain either string literal, and the string values are part of the public contract. The class defines key names only; the value sets are owned by `doc/rules/observability.md` §5 and `shared-types-and-ownership.md` FR-041 and are not enumerated or validated here. `architecture-guardrails.md` FR-037 exempts members of `AttributeKeys` from its constants-file suffix rule; the keys are not renamed, because about 7 specs use the dotted names. | observability.md §5 "Naming", "Attributes", §7 table; shared-types-and-ownership.md FR-041; architecture-guardrails.md FR-037 | happy |
| FR-053 | No file under `lib/src/shared_ports/`, no-ops and `adapters/` included, may call `DateTime.now(`, `DateTime.timestamp(`, `Stopwatch(`, `Random.secure(` or `Random(` in any form (seeded or not); this extends architecture.md §9, which bans `Random(` only in `domain/` and `application/`. There is no carve-out: the seeded `Random` is injected by the consumer (`dice-and-rolls.md` FR-064). Time is read only by consumer adapters. `print(` is banned across all of `lib/` by `architecture-guardrails.md` FR-028. | architecture.md §3, §9; observability.md §4 "Timing"; dice-and-rolls.md FR-064; architecture-guardrails.md FR-028 | unhappy (determinism) |

### 4.6 Added requirements

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-054 | If the `body` given to `traceAsync` throws synchronously before returning a `Future` (for example a non-`async` closure), the span MUST get the FR-012 treatment (status `error`, error and stack trace recorded, span ended) and `traceAsync` MUST return a `Future` that completes with that same error. It MUST NOT throw synchronously. The synchronous-throw path is subject to the same catch-clause rule as FR-012 (`errors-and-results.md` FR-047, the exemption from FR-030): the clause only records and ends in `rethrow`, or the error is passed on through the returned `Future` without a catch of `Error` that does anything else. | observability.md §6; errors-and-results.md FR-047, FR-030 | unhappy (failure) |
| FR-055 | If the `body` given to `timeAsync` throws synchronously before returning a `Future`, a recording meter MUST still record the elapsed time (FR-030; a no-op records nothing, FR-033) and `timeAsync` MUST return a `Future` that completes with the same error. It MUST NOT throw synchronously. | observability.md §4 "Timing" | unhappy (failure) |
| FR-056 | The dartdoc of `Logger`, `Tracer` and `Meter` MUST state: "Production implementations MUST NOT throw of their own accord (trace/time rethrow the body's own error unchanged); srd5e does not catch. The recording doubles in `testing.dart` throw `ArgumentError`/`StateError` on misuse by design." A test MUST read the doc comments of the three port declarations and fail if the sentence is missing. | section 9 (decided); `architecture.md` §6 | unhappy (invalid input) |
| FR-057 | The dartdoc of `Tracer.trace` and `Meter.time` MUST state that the body MUST NOT return a `Future` (use `traceAsync` or `timeAsync`), because the span or measurement would end before the future completes. Checked with FR-056's doc-comment test. | observability.md §6 | unhappy (invalid input) |
| FR-058 | `RecordingMeter.time` and `timeAsync` MUST throw `ArgumentError` unless the histogram's `unit` is `'s'`. | observability.md §5 "Naming" (durations are always seconds) | unhappy (invalid input) |
| FR-059 | The rule files MUST state the three departures this spec relies on, as accepted by `shared-types-and-ownership.md` FR-051 and now applied: `observability.md` §4 and `architecture.md` §4 "Sync or async" (`Tracer` and `Meter` also carry async wrappers; the other ports stay synchronous); `observability.md` §7 (log attributes are closure-only, the example is `log.fine('check resolved', attributes: () => {AttributeKeys.outcome: 'success'})`, and a returned failure carries no `error.type`, per `errors-and-results.md` FR-043); `observability.md` §4, §10, §11 and the `architecture.md` §10 "Shared mutable state: static fields" anti-pattern (a `const` instance of a no-op class is not a "static or top-level logger, tracer or meter"). Any later edit of those passages MUST keep these three statements and give the file a fresh `RULE-TAG`. `architecture.md` §9 has no static-logger bullet and needs no such edit. | architecture.md §4, §10; observability.md §4, §7, §10, §11; shared-types-and-ownership.md FR-051 | architecture (the `const` exemption test) |
| FR-060 | Pointer, nothing added here: `architecture-guardrails.md` FR-074 (no file other than `lib/testing.dart` imports or exports `lib/src/testing/`), FR-075 (what a file under `lib/src/testing/` may import) and FR-081 (where double-prefixed classes live) own the checks. Doubles MAY depend on ports, `shared_kernel` and context barrels. | architecture.md §1, §9; shared-types-and-ownership.md FR-038; architecture-guardrails.md FR-074, FR-075, FR-081 | guardrail |
| FR-062 | `NoopObservability` MUST be a `final class` that extends `Observability` (`const NoopObservability()`), with all three no-op ports. `Observability` MUST be a `final class` (`@immutable`) declared in the same file as `NoopObservability`, under `lib/src/shared_ports/observability/`, so that Dart's `final` modifier allows the subclass inside that library and blocks every other subclass, `implements` and `extends`, including consumers'. A consumer therefore cannot break `identical(Observability.none, ...)` or the immutability guarantee. A test MUST assert that `NoopObservability` is `const`-constructible and that its ports are the no-ops, and an architecture test MUST assert the two declarations and their modifiers. | shared-types-and-ownership.md FR-036; observability.md §4 | happy |
| FR-063 | The contract suites are three files, one per port, as `architecture-guardrails.md` FR-082 requires: `test/contract/logger_contract.dart`, `test/contract/tracer_contract.dart` and `test/contract/meter_contract.dart`. None may be exported from `lib/`; they live only under `test/contract/` and are reused by consumers through documentation (`shared-types-and-ownership.md` FR-039). | testing.md §3; shared-types-and-ownership.md FR-039; architecture-guardrails.md FR-082 | architecture |
| FR-064 | Every instrument returned by a `NoopMeter` (counter, histogram, gauge) MUST accept `add` or `record` with any value (including a negative one) and any attributes, without throwing and without any observable effect. | observability.md §1.5 | unhappy (empty and minimal) |
| FR-065 | `Span`, `Counter`, `Histogram` and `Gauge` are handles, not driven ports. They MUST NOT need a double or a contract file of their own; their behaviour is pinned through the port contract files of FR-063. `architecture-guardrails.md` FR-082 treats every `abstract interface class` declared directly in `shared_ports/` (subfolders such as `shared_ports/observability/` included) as a port, and exempts these four names through its named constant `portHandles` (`architecture-guardrails.md` FR-009). | architecture-guardrails.md FR-009, FR-082 | architecture |

### 4.7 Withdrawn ids

| Id | Requirement |
|---|---|
| FR-061 | Withdrawn: moved to shared-types-and-ownership.md (FR-038) |

## 5. Model

No domain layer: `shared_ports` holds ports, handles and plain value types.

- **Ports** (abstract interface classes): `Logger`, `Tracer`, `Meter`.
  `Logger` is synchronous. `Tracer` and `Meter` are synchronous except
  `traceAsync` and `timeAsync`, which exist so a use case that already returns a
  `Future` can be spanned and timed correctly (FR-059).
- **Handles, not ports:** `Span`, `Counter`, `Histogram`, `Gauge` (FR-065).
- **Value types:** `LogLevel`, `SpanStatus`, `Attributes`; in `lib/src/testing/`
  `InstrumentKind`, immutable `LogRecord` and `MeasurementRecord`, and
  `SpanRecord` (mutable while its span is open, frozen once it ends).
- **`Observability`:** `@immutable` `final class`, three final fields;
  `NoopObservability extends Observability` is the all-no-op `const` instance
  (FR-062) and `Observability.none`.
- **Invariants:** a recording span is writable only between start and end
  (FR-023); a recording instrument name maps to exactly one kind (FR-038);
  attribute values are one of four plain types (FR-010). Each is enforced by the
  recording double, the only place that sees the violation.
- **Failures:** violations are programmer errors (`ArgumentError`,
  `StateError`), thrown by the recording doubles only. The no-ops never validate
  and never throw (FR-034, FR-064). No `Srd5eException`: nothing here does I/O.
  srd5e does not catch an exception from a consumer's port; production
  implementations MUST NOT throw (FR-056).
- **Layout** (`shared-types-and-ownership.md` FR-036 to FR-038): ports, handles,
  no-ops and the bundle live in `lib/src/shared_ports/observability/`;
  `AttributeKeys` in `lib/src/shared_ports/signals.dart` (FR-052); all recording
  doubles in `lib/src/testing/`, imported only by `lib/testing.dart` (FR-060).
  Doubles depend on ports, never the reverse. Any generic adapter would go in
  `lib/src/shared_ports/adapters/` and export from `lib/adapters.dart` only.

## 6. Interface

Plain Dart types only.

```dart
enum LogLevel { finest, fine, info, warning, severe }
enum SpanStatus { unset, ok, error }
typedef Attributes = Map<String, Object>;

abstract interface class Logger {
  bool isEnabled(LogLevel level);
  void log(LogLevel level, String message,
      {Attributes Function()? attributes, Object? error, StackTrace? stackTrace});
}
extension LoggerLevels on Logger {
  // finest/fine/info/warning/severe(String message,
  //     {Attributes Function()? attributes, Object? error, StackTrace? stackTrace})
}

abstract interface class Span {
  void setAttribute(String key, Object value);
  void setStatus(SpanStatus status);
  void recordError(Object error, StackTrace stackTrace);
}
abstract interface class Tracer {
  T trace<T>(String name, T Function(Span span) body, {Attributes attributes = const {}});
  Future<T> traceAsync<T>(String name, Future<T> Function(Span span) body,
      {Attributes attributes = const {}});
}

abstract interface class Counter   { String get name; String get unit; String get description; void add(int value, {Attributes attributes = const {}}); }
abstract interface class Histogram { String get name; String get unit; String get description; void record(num value, {Attributes attributes = const {}}); }
abstract interface class Gauge     { String get name; String get unit; String get description; void record(num value, {Attributes attributes = const {}}); }
abstract interface class Meter {
  Counter createCounter(String name, {String unit = '', String description = ''});
  Histogram createHistogram(String name, {String unit = '', String description = ''});
  Gauge createGauge(String name, {String unit = '', String description = ''});
  T time<T>(Histogram histogram, T Function() body, {Attributes attributes = const {}});
  Future<T> timeAsync<T>(Histogram histogram, Future<T> Function() body,
      {Attributes attributes = const {}});
}

// lib/src/shared_ports/signals.dart
abstract final class AttributeKeys {
  static const String outcome = 'srd5e.outcome';
  static const String errorType = 'error.type';
}

@immutable
final class Observability {
  const Observability({this.logger = const NoopLogger(),
      this.tracer = const NoopTracer(), this.meter = const NoopMeter()});
  static const Observability none = NoopObservability();
  final Logger logger; final Tracer tracer; final Meter meter;
}
/// Same file as `Observability`, not in an adapters folder.
final class NoopObservability extends Observability {
  const NoopObservability();
}
```

Notes:

- Only `traceAsync` and `timeAsync` return a `Future`; a synchronous throw from
  their body surfaces as a failed `Future` (FR-054, FR-055). `trace` and `time`
  must not be given `Future`-returning bodies (FR-057).
- Duration instruments are created with `unit: 's'`; `time` records seconds as a
  `double`; the consumer's `Meter` reads its own clock. Use cases create their
  instruments once, in the constructor. Attributes are per call, not bound to
  instruments.
- Production implementations MUST NOT throw and srd5e does not catch (FR-056);
  the recording doubles throw on misuse by design.

### Shape of `lib/testing.dart`

`package:srd5e/testing.dart` is a barrel of test doubles for every port, pure
Dart, with no dependency on `package:test`. From this spec it exports
`RecordingObservability`, `RecordingLogger`, `RecordingTracer`, `RecordingMeter`,
`LogRecord`, `SpanRecord`, `MeasurementRecord`, `InstrumentKind`; other specs
add the `DiceRoller` double (`dice-and-rolls.md`) and fakes for later ports. All
live in `lib/src/testing/`.

```dart
enum InstrumentKind { counter, histogram, gauge }

final class LogRecord {
  final LogLevel level; final String message; final Attributes attributes;
  final Object? error; final StackTrace? stackTrace;
}
final class MeasurementRecord {
  final String name; final InstrumentKind kind; final String unit;
  final num value; final Attributes attributes;
}
final class SpanRecord {  // only these fields are mutable, through the recording span, until it ends
  final String name; Attributes attributes; SpanStatus status;
  List<(Object error, StackTrace stackTrace)> errors;  // in call order
  final SpanRecord? parent; bool ended;
}
```

| Type | Constructor | Read | Control |
|---|---|---|---|
| `RecordingLogger` | `({LogLevel minLevel = LogLevel.finest})` | `records` (unmodifiable), `recordsAt(LogLevel)` | `minLevel` |
| `RecordingTracer` | `()` | `spans` (in start order), `spansNamed(String)` | none |
| `RecordingMeter` | `({Duration timedDuration = Duration.zero})` | `measurements`, `measurementsNamed(String)`, `instruments` | `timedDuration` |
| `RecordingObservability` | `({LogLevel minLevel = LogLevel.finest, Duration timedDuration = Duration.zero})` | `logger`, `tracer`, `meter`, `observability` | `clear()` |

`lib/srd5e.dart` re-exports the ports and no-ops; `lib/testing.dart` exports the
doubles. No new context barrel: `shared_ports/` is not a bounded context.

## 7. Observability

Silent by design: these are the ports through which every signal is emitted. A
port that observed itself would recurse, and a no-op that emitted anything
would break "zero cost when unused" (`observability.md` §1.5).
`doc/observability/signals.md` gets no rows from this spec. The seven questions:

1. **What can go wrong?** A consumer's implementation throws, is slow, or
   violates the contract (calls the attributes closure while disabled, passes
   unsupported value types, mutates a span after it ended). A srd5e use case may
   pass a bad name or attribute, which only the recording doubles detect.
2. **How would an operator know?** They would not: the ports cannot report on
   themselves. Defence is in tests (recording doubles throw on misuse, the
   contract suites) and architecture tests (FR-051, FR-053), not at runtime.
3. **What would someone need to diagnose it?** An exception from a consumer's
   implementation arrives with its own stack trace, since srd5e does not catch
   it (FR-056). Nothing more.
4. **What should be counted or timed?** Nothing here.
5. **Is existing instrumentation still correct?** None exists yet.
6. **What should a consumer monitor?** Nothing from the ports; adapters should
   be cheap and non-throwing.
7. **Is anything noisy?** No. No-ops emit nothing; doubles are test-only.

| Signal | Type | Attributes | Purpose | Suggested monitoring |
|---|---|---|---|---|
| (none) | | | | |

`srd5e.outcome` and `error.type` (FR-052) are not signals; they are vocabulary
for other specs' signals.

## 8. Test plan

Tests mirror `lib/src/`: port, no-op and bundle tests in `test/shared_ports/`;
recording-double tests in `test/testing/`; plus `test/contract/` and
`test/architecture/`. "Contract" rows run against the no-op and the recording
implementation through one shared suite per port (FR-063). Each contract file
takes a factory per implementation (`NoopX`, `RecordingX`) and is documented for
consumer reuse, not exported (FR-063, `shared-types-and-ownership.md` FR-039).

| Ids | Level | Notes |
|---|---|---|
| FR-001 | unit | values and order of `LogLevel` |
| FR-002 | unit | `Logger` is an interface class; a fake `Logger` (via `implements`) receives the closure and `error`/`stackTrace` intact |
| FR-003, FR-004 | unit | table over all levels, with and without `error`; closure probe |
| FR-005 | unit | fake logger captures the delegated call via `LoggerLevels`; one row per shortcut |
| FR-006 | contract | probe closure; `NoopLogger` and a `RecordingLogger` with `minLevel` above the call |
| FR-007, FR-009 | unit | order and all fields; closure counter; no closure gives `{}`; later mutation of the map changes nothing |
| FR-008 | unit | table: below, at, above `minLevel`, across every level |
| FR-010 | unit | table over the three doubles and unsupported values (`List`, `Map`, `DateTime`, other objects) |
| FR-011 | contract | body once, result, span non-null |
| FR-012 | contract | table: `Exception` and `Error`; same instance and stack trace; recording asserts status and error. Architecture row: the catch clause in each tracer implementation only records and ends in `rethrow` (the `errors-and-results.md` FR-030 scan with its FR-047 exemption, over `shared_ports/` and `lib/src/testing/`) |
| FR-013, FR-014 | contract | completer-based; recording asserts `ended` is false before completion; failing future asserts status and error |
| FR-015 to FR-018 | unit | start attributes, later attribute, overwrite; default `unset`, last write wins; two errors in order, status unchanged; `ok` then throw and `unset` then throw |
| FR-019 | contract | sync and async, result and propagation |
| FR-020 | unit | keep the span, call each mutator after return; no throw, no change in a recording run |
| FR-021, FR-022 | unit | all `SpanRecord` fields including `parent`; start order with a nested pair; mutable while open, frozen after end; two levels deep; sequential async; top-level has null parent |
| FR-023 | unit | each mutator, after sync return and after the async future completes (not before) |
| FR-024, FR-039 | unit | shared name table: valid and invalid (empty, uppercase, two parts, trailing dot, space, `foo.bar.baz` (no prefix), `srd5e.1x.y`, `srd5e._x.y`) |
| FR-025 | contract | each create method; `name`, `unit`, `description` getters |
| FR-026 to FR-028 | unit | recorded `add`; boundary `0`, `1`, `-1`; histogram and gauge, int and double values |
| FR-029, FR-030 | contract | one body call, result, one measurement in seconds as `double`; recording asserts a measurement exists after a throw |
| FR-031, FR-032 | contract | completer-based; measurement absent before completion and present after, in seconds as `double`; failing future records and propagates |
| FR-033 | contract | no-op records nothing; FR-053 architecture test covers "no clock" |
| FR-034, FR-064 | unit | `NoopMeter` create methods: empty name, odd unit, empty description; instruments accept `0`, negative, fractional values and attributes; no throw |
| FR-035 | unit | order across a counter and a histogram; `kind` is the matching `InstrumentKind` |
| FR-036, FR-037 | unit | table: zero, 1500 ms (1.5), 1 microsecond (0.000001); boundary: zero accepted, minus one microsecond rejected |
| FR-038 | unit | same name same kind; same name other kind; same name and kind, other unit or description |
| FR-040, FR-058 | unit | histogram from a second meter; unit `'s'` accepted, `''` and `'{modifier}'` rejected, for `time` and `timeAsync` |
| FR-041 to FR-043 | unit | defaults; table: only logger, only tracer, only meter, each default exercised as a no-op; `identical(Observability.none, const NoopObservability())` |
| FR-044 | architecture | `@immutable` plus `must_be_immutable` in the CI analyze step; no source-reading test |
| FR-045, FR-046 | unit | four accessors share objects (`identical`); clear, then keep using an earlier instrument; `instruments`, `minLevel`, `timedDuration` unchanged |
| FR-047 | unit | `UnsupportedError` on add to each list; caller mutation after the call |
| FR-048, FR-049 | architecture | export list pinned by a test importing only `srd5e.dart` and referencing every symbol (including `AttributeKeys`, `LoggerLevels`); `public_member_api_docs` lint; both barrels' `export` lines, `InstrumentKind` from `testing.dart` only |
| FR-050, FR-060 | n/a | covered by `architecture-guardrails.md` FR-076, FR-074/FR-075 (no check here) |
| FR-051 | architecture | the observability §10 and architecture §9 checks applied to `shared_ports/`; `const` no-op instances exempt (FR-059); imports limited to `shared_kernel/` and `shared_ports/`; nothing outside `shared_ports/adapters/` imports it |
| FR-052 | unit | pins both keys and string values; architecture scan: class declared in `lib/src/shared_ports/signals.dart`, literals appear nowhere else under `lib/` |
| FR-053 | architecture | banned-call scan of architecture §9 extended to `shared_ports/`: (the check is `architecture-guardrails.md` FR-103) `DateTime.now(`, `DateTime.timestamp(`, `Stopwatch(`, `Random.secure(`, every `Random(` form, no `adapters/` exemption; `print(` is `architecture-guardrails.md` FR-028's check |
| FR-054, FR-055 | contract | non-`async` closure that throws; failed `Future`, no sync throw; recording asserts status, error, ended (trace) or the measurement (time); no-op records nothing |
| FR-056, FR-057 | architecture | doc comments of the three ports contain the full sentence including "of their own accord" and the recording-double carve-out; same test for `trace` and `time` |
| FR-059 | architecture | `const` exemption: a non-`const` static or top-level logger, tracer or meter is flagged, a `const` no-op is not. Fresh-tag-on-edit is not automated (below) |
| FR-062 | unit + architecture | `const NoopObservability()` canonical; ports are the no-op types; `Observability.none` identical. Architecture: both are `final class` declarations in one file (the check is `architecture-guardrails.md` FR-104) |
| FR-063 | architecture | the three contract files exist; no file under `lib/` exports or imports `test/contract/` (reachable only from `test/`) |
| FR-065 | architecture | the `architecture-guardrails.md` FR-082 scan, with the four handles in `portHandles`, reports no missing double or contract file |

- **Pyramid:** nearly all unit and contract tests; no scenario tests here.
  Per `architecture.md` §9, ports, doubles and suites ship together with the
  first code under `lib/src/`.
- **Mutation testing:** `shared_ports/` is not `domain/`, so `testing.md` §8
  does not require it. SHOULD be run on `lib/src/testing/` (validation branches
  in FR-010, FR-027, FR-036 to FR-040), target score at least 80.
- **Not covered deliberately:** (a) whether a later edit of the FR-059 passages
  gives the rule file a fresh `RULE-TAG` is checked in review; (b) behaviour of a
  consumer's own implementations (section 1).

Deliberately not covered: FR-044 - enforced by the analyzer's `must_be_immutable` lint under `dart analyze --fatal-infos` in the CI analyze step; the row itself says there is no source-reading test.

Deliberately not covered: FR-050 - a pointer row that adds no requirement here; the ban on `package:test` and friends under `lib/` is checked by architecture-guardrails.md FR-076 and FR-083.

Deliberately not covered: FR-060 - a pointer row that adds no requirement here; the checks belong to architecture-guardrails.md FR-074, FR-075 and FR-081.

## 9. Open questions and decisions

No open questions. Settled:

- Attributes are closure-only; `traceAsync` and `timeAsync` are included now
  (the async content use cases of phase 2 need them; adding abstract methods to a
  port later would break implementers) (FR-059).
- No try/catch around consumer ports in use cases: it would add a branch to every
  use case, hide bugs and make srd5e swallow exceptions (`architecture.md` §6);
  revisit if a real consumer needs it (FR-056).
- No-ops do not validate (zero cost); recording doubles do. The "identical
  behaviour" test of `observability.md` §9 covers valid use only.
- Doubles live in `lib/src/testing/` (`shared-types-and-ownership.md` FR-038);
  no-ops are `const` classes in the port library, not adapters (FR-036);
  contract suites are not exported (FR-039; FR-063).
- `const` no-op instances are exempt from the static-logger ban (FR-059).
- A "run with no-op and recording" helper in `testing.dart` is deferred until
  two contexts repeat the pattern; it would live in `lib/src/testing/` and not
  import `package:test`.
- `AttributeKeys` members are exempt from the `architecture-guardrails.md`
  FR-037 suffix rule rather than renamed (FR-052). `portHandles` exempts the
  four handles from the FR-082 port scan (FR-065).
- `Observability` is `final` with `NoopObservability` in the same file (FR-062);
  a `base` class would still allow consumer subclasses.
- `RecordingTracer` records no span duration (it would need a clock).
- Shared attribute keys are only `srd5e.outcome` and `error.type`; context keys
  live in their contexts; value sets are in `shared-types-and-ownership.md`
  FR-041.
- `RecordingTracer.parent` uses a stack of open spans: correct for nested
  synchronous and sequential async use only (FR-022); real linkage is the
  consumer's job.

## 10. Changelog impact

Under `Unreleased` / **Added**:

- `Logger`, `Tracer`, `Meter` ports with `LogLevel`, `Span`, `SpanStatus`,
  `Counter`, `Histogram`, `Gauge`, the `LoggerLevels` shortcuts; the
  `Observability` bundle with no-op defaults and `Observability.none`; shared
  attribute keys (`AttributeKeys`).
- `NoopLogger`, `NoopTracer`, `NoopMeter`, `NoopObservability` (`const`, in the
  port library).
- `package:srd5e/testing.dart` with `RecordingObservability` and the recording
  doubles (implemented in `lib/src/testing/`).

Rule-file amendments (not user-visible) are applied to `doc/rules/observability.md`
§4, §7, §10, §11 and `doc/rules/architecture.md` §4, §10 (FR-059).

Not **BREAKING**: first release of these APIs. After release, renaming a shared
attribute key, adding an abstract method to a port, or changing a no-op's
behaviour is **BREAKING** (`doc/rules/architecture.md` §7).
