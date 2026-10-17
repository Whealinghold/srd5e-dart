# srd5e Observability Rules

Normative. MUST / MUST NOT / SHOULD are binding on all code and review.
Read together with [architecture.md](architecture.md); observability follows
its layering and dependency rules.

## 1. Principles

1. **The goal is good observability.** Someone running a system built on srd5e
   MUST be able to tell what it is doing, whether it is healthy, and why it
   gave a particular result, without changing the code. Observability is a
   feature of every change, not an afterthought and not optional polish.
2. **The package emits; the consumer decides where it goes.** srd5e defines
   observability ports. Consumers inject OpenTelemetry, `package:logging`,
   Sentry or anything else. srd5e never chooses a backend.
3. **Instrument for diagnosis.** Emit the signals someone would need to debug
   a wrong result, find a slow path, or understand how a rule resolved. The
   evaluation in §2 decides which. Do not wait for an incident to add them.
4. **Signal over noise.** Emit what helps, at the right level, once. Volume is
   a cost for every consumer.
5. **Zero cost when unused.** With no observability injected, everything is a
   no-op and behaviour is identical.
6. **Monitoring is part of the design.** A signal nobody can act on is
   incomplete. Each signal states what it is for and what a consumer should
   watch or alert on (see §2).

---

## 2. Evaluating observability is mandatory

Agents and contributors MUST actively evaluate observability and monitoring
for **every change**: a new use case, changed behaviour, a new port or adapter,
a new failure mode, a performance-sensitive path, or a bug fix. A change is
not done until this evaluation has been performed, acted on and reported.
Skipping it, or answering it with a bare "not applicable", is a defect.

### The evaluation

Before finishing, answer each of these for the change. Think about it, do not
just tick it off.

1. **What can go wrong here?** Failure modes: bad content, a port failing,
   invalid input, an invariant violated, unexpected rule interaction.
2. **How would an operator know it went wrong?** What signal (metric, span,
   log) surfaces each failure mode? Is it distinguishable from the normal
   outcome?
3. **What would someone need to diagnose it?** The identifiers, inputs summary,
   intermediate values and outcome, as low-cardinality attributes or in the
   returned result.
4. **What should be counted or timed?** Throughput, outcomes, latency, sizes,
   errors (§5).
5. **Is the existing instrumentation still correct?** Does the change make an
   existing metric, span or log misleading, stale or incomplete? Update it.
6. **What should a consumer monitor or alert on?** Which signal, what
   condition, and why it matters (e.g. any content decode failure; a latency
   regression; an outcome rate that suddenly shifts).
7. **Is anything now noisy?** Does the change add volume without value, or log
   at the wrong level?

### The outcome

- **Add or change the instrumentation** the evaluation calls for, following the
  rest of this document.
- **Update the signal catalogue** (below) for every metric, span or
  log event added, changed or removed.
- **Report it.** The PR description (see `.github/pull_request_template.md`)
  and the agent's final summary MUST contain an `Observability` entry saying
  what was added, changed or removed, and what a consumer should monitor.
- **If you add nothing, justify it specifically.** State why no failure mode,
  diagnostic need or measurement applies to this change (for example: "pure
  rename, no behavioural change; existing `srd5e.d20_test.resolved` unaffected").
  "N/A" or "no changes" alone is not acceptable.
- **Bug fixes:** also add the signal that would have exposed the bug sooner,
  or state why none could have.
- **Reviewers MUST reject** a change that lacks the evaluation or its report.

### The signal catalogue

`doc/observability/signals.md` is the single list of every signal srd5e emits.
It MUST stay in sync with the code. For each signal it records:

| Field | Meaning |
|---|---|
| Name | The metric, span or log-event name, exactly as defined in code |
| Type | Counter, histogram, gauge, span or log event (with level) |
| Unit | Unit of measure, where applicable |
| Attributes | Allowed attribute keys and their possible values |
| Emitted by | The use case or adapter that produces it |
| Purpose | What question it answers or what failure it exposes |
| Suggested monitoring | What consumers should dashboard or alert on, and the threshold or condition to start from |

srd5e is a library and cannot run alerts. The catalogue is how it tells
consumers what to monitor, so the "Suggested monitoring" column MUST be filled
in for every signal where an operator could act on it.

---

## 3. Where observability lives

| Layer | Observability rule |
|---|---|
| `domain` | **Silent.** No logging, metrics or spans. The domain is pure. It exposes what happened through return values and domain events. |
| `application` | **Instrumented.** Use cases emit metrics, spans and logs through the injected ports. This is the main place telemetry is produced. |
| `adapters` | **Instrumented only for what the use case cannot see**: retries, fallbacks, partial decodes, I/O timing. Emitted through the same ports, injected the same way. Failures the adapter returns or throws are recorded by the use case, not by the adapter (§7, "Errors: who records what"). |

- Domain events and result types already carry the *what* and *why* (modifiers
  applied, roll made, DC, outcome). Use cases translate those into
  telemetry. They MUST NOT re-derive them.
- A use case MUST NOT reach into the domain to emit telemetry. If the domain
  holds information worth observing, it returns it.

---

## 4. Ports

Defined once in `lib/src/shared_ports/` (every context uses them; see
[architecture.md](architecture.md) §1), named for what the code needs:

| Port | Responsibility |
|---|---|
| `Logger` | Emit a log event: level (an enum), constant message, structured attributes supplied lazily, optional error and stack trace. Exposes `isEnabled(level)`. |
| `Tracer` | Run a unit of work inside a named span with attributes; set span status and record errors on the span |
| `Meter` | Create counters, histograms and gauges, and **time a unit of work** into a duration histogram |

They are bundled in one `Observability` object that use cases take as an
optional constructor argument. The ports are synchronous, except that `Tracer`
and `Meter` also carry async wrappers (`traceAsync`, `timeAsync`) so a use case
that returns a `Future` can be spanned and timed. Their body runs to completion
before the span ends or the duration is recorded, and an error from it still
ends the span or records the time, then propagates.

**Timing.** Domain and application code may not read the clock
([architecture.md](architecture.md) §3, §9). Durations are therefore measured
by the ports: a span's duration by the `Tracer` implementation, and a duration
histogram by a `Meter` timing operation that wraps the work, sync or async (in
the style of Micrometer's `Timer.record`). The consumer's adapter reads its own
clock; the no-op implementation reads none.

Rules:

- **No-op by default.** Omitting the argument gives a silent implementation.
  Use cases MUST NOT null-check or branch on whether observability is enabled.
  The no-ops (`NoopLogger`, `NoopTracer`, `NoopMeter`, `NoopObservability`) are
  `const` classes in the port library itself, under `lib/src/shared_ports/`,
  not in an `adapters/` folder, so `application` can use them as defaults.
- **Constructor injection only.** No static loggers, no global registries, no
  service locators, no `Logger('name')` lookups from `package:logging` inside
  srd5e. A `const` instance of a no-op class (such as `Observability.none` or
  a `const NoopLogger()` default) is stateless and is not a static logger,
  tracer or meter.
- **No vendor types.** Ports use plain Dart types only: strings, numbers,
  booleans, durations, `Map<String, Object>` of attributes. No OpenTelemetry,
  Sentry or other SDK type may appear in a port or anywhere in `lib/`.
- **Shaped for OpenTelemetry.** Port semantics MUST map cleanly onto the OTel
  model (spans with attributes and status, counters, histograms, severity
  levels) so a consumer's adapter is a thin translation.
- **Small.** Add a port method only when an instrumentation point needs it.
- Every port MUST ship a recording test double in `testing.dart` (implemented
  in `lib/src/testing/`).
- Bridges to `package:logging`, OpenTelemetry or other SDKs are **not**
  shipped in this package (they would add a dependency for every consumer).
  Show them as examples in `example/` and the README instead.

---

## 5. Metrics

> **Rule: anything worth counting, timing or measuring in aggregate is a
> metric through the `Meter` port,** never only a log line (§8). Consumers
> route metrics to OpenTelemetry through their adapter. srd5e itself never
> imports an OTel package.

### What to record

- **Throughput:** a counter per use case invocation, e.g. a resolved check, an
  applied condition, a computed derived stat.
- **Outcomes:** counters broken down by result, e.g. outcome, rule
  outcome, validation failure, decode failure.
- **Latency:** a duration histogram for each use case, recorded with the
  `Meter` timing operation (§4).
- **Sizes:** histograms of things that grow, e.g. number of modifiers applied,
  size of an encounter, number of content entries loaded.
- **Errors:** a counter of thrown failures (port failures) by error type. A
  returned failure (content decode failure, content not found) is counted by
  outcome (`srd5e.outcome` = `failure`) plus a variant attribute defined by the
  use case's spec, and carries no `error.type`.
- **Content:** counters or gauges for content loaded, missing and rejected.

### Naming

- Names are lowercase, dot-separated and prefixed: `srd5e.<context>.<noun>` and
  an appropriate suffix, e.g. `srd5e.d20_test.resolved`,
  `srd5e.d20_test.duration`, `srd5e.content.decode_errors`.
- Units follow UCUM as OpenTelemetry does, and are stated in the instrument
  definition, not in the name. Durations are always seconds (`s`, as a
  `double`); counts of things use an annotation such as `{modifier}`.
- Names (metric, span, log event, attribute key) are constants defined in one
  place per context, or in `shared_ports/` for keys shared across contexts. No
  string literals at call sites.
- Renaming or removing a signal or attribute key is a breaking change for
  consumers' dashboards and alerts. Mark it **BREAKING** in the changelog
  ([architecture.md](architecture.md) §7).

### Attributes

- Attributes MUST be **low-cardinality**: rule names, outcome,
  ability, context name, error type. Never ids, free text, whole
  objects, or unbounded numbers.
- Attributes MUST NOT contain personal or consumer-identifying data.
- Use consistent attribute keys across metrics, spans and logs
  (`srd5e.outcome`, `srd5e.d20_test.kind`).
- Attribute **values** are shared too, so metrics, spans and logs agree:
  `srd5e.outcome` is `success` or `failure`; `srd5e.d20_test.kind` is
  `ability_check`, `saving_throw` or `attack_roll`;
  `srd5e.d20_test.roll_mode` is `normal`, `advantage` or `disadvantage`;
  `srd5e.d20_test.critical_hit` is `true` or `false` (attack rolls only);
  `srd5e.d20_test.roller_failure` is `unavailable` or `invalid_result`;
  `srd5e.d20_test.forced_failure_reason` is `chosen_to_fail` or `automatic`;
  `srd5e.content.kind` is the snake_case of a registered `ContentKind`
  (`species`, `background`, `character_class`, `feat`, `equipment`, `spell`,
  `magic_item`, `monster`, `poison`, `trap`, `contagion`; the set is bounded
  by the content revision table); `srd5e.content.problem_kind` is the
  snake_case of a `ContentProblemKind` (`syntax`, `unsupported_version`,
  `missing_field`, `unknown_field`, `wrong_type`, `out_of_range`,
  `invalid_value`, `duplicate`, `unresolved_reference`,
  `constraint_violation`);
  `error.type` is one constant per `Srd5eException` subtype, the snake_case of
  the subtype name, defined in `errors-and-results.md`, and is set only for a
  thrown subtype, never for a returned failure result. A new value for an
  existing key is added to this list and to the catalogue.

---

## 6. Traces

- Wrap each top-level use case in a span through the `Tracer` port. The span
  name is the use case, e.g. `srd5e.d20_test.resolve`.
- Add child spans only for steps that are slow or that cross a port (content
  lookup, decoding). Do not span trivial functions.
- Attach the same low-cardinality attributes as the matching metrics.
- On failure, set the span status to error, record the exception on the
  span, and let the exception or result propagate. Do not swallow it. A
  failure **result** (failed decode, content not found) also sets error status;
  a normal rule outcome (failed check) does not.
- srd5e does not manage trace context. Parent/child linkage is the consumer
  adapter's job (typically via Dart zones).

---

## 7. Logging

### Levels

Use the lowest level that serves the reader. Levels map to
`package:logging` and to OpenTelemetry severity.

| Level | Use for | Examples |
|---|---|---|
| `FINEST` / `trace` | Step-by-step detail useful only when chasing a specific bug. Off by default; MUST be cheap when off. | Each modifier considered and why it was dropped by stacking rules |
| `FINE` / `debug` | Normal operation details a developer would want while debugging | Use case started with inputs summary; content source selected; result summary |
| `INFO` | Significant lifecycle events, rare. At most a handful per process, never per call. | Content set loaded (name, count); engine configured |
| `WARNING` / `warn` | Something is wrong but handled; the result is still valid but possibly not what was intended | Unknown optional field ignored while decoding; deprecated content format; falling back to a default |
| `SEVERE` / `error` | An operation failed and the failure is **not** surfaced to the caller as a thrown exception or failure result (so a log is the only trace of it) | A best-effort step that failed and was skipped |
| `SHOUT` / `fatal` | Not used by this package | |

- **A library MUST NOT log at `INFO` per use case call.** Per-call detail is
  `FINE` or below. Consumers enable it when needed.
- A rule outcome the player simply failed (a failed check, an illegal but
  expected action) is **not** a warning or an error. It is a normal result.
  Log at `FINE` at most.
- `SEVERE` is rare in a library. If the failure reaches the caller as a
  result or exception, the caller decides whether to log it, so srd5e does not.

### Errors: who records what

Each failure is recorded once, by the right owner, in the right signal:

| Failure | Recorded by | How |
|---|---|---|
| Thrown out of the use case (port exception) | The use case at whose boundary it leaves srd5e | Span error status + exception on the span; increment the error counter with an `error.type` attribute. **No log.** |
| Returned out of the use case as a failure result (decode failure, content not found) | The use case that returns it | Span error status; count it with `srd5e.outcome` = `failure` plus a variant attribute defined by the use case's spec. **No `error.type`, no log.** A result the rules merely refuse is a normal outcome (last row), not this one. |
| Returned by an adapter to a use case | The use case (as above), not the adapter | Adapter emits nothing for it |
| Handled inside srd5e and not surfaced (fallback, skipped best-effort step, ignored unknown field) | The code that handled it | `WARNING` log (or `SEVERE` if the operation could not complete) + counter |
| Programmer error (`Error`: bad argument, broken invariant) | Nobody in srd5e | Thrown; it is a bug for the caller to see. The span records it as it propagates (the `Tracer`'s record-and-rethrow, [architecture.md](architecture.md) §6). |
| Normal rule outcome (failed check, illegal action) | The use case | Outcome attribute on the counter and span. Not an error. |

Use cases never call one another ([architecture.md](architecture.md) §4), so
none records another's signals and an error is counted once, by the use case it
left. Attribute values come from the domain result.

### Log intelligently

- **Log at boundaries, not in the middle.** Spans already record the start,
  end and duration of a use case, so do not log those. At most one `FINE`
  summary per use case call. Log at a port call only for what a span cannot
  hold. Do not narrate internal steps.
- **One event per occurrence.** Do not log the same fact at several layers,
  and never log an error that is also thrown or returned (see the table
  above).
- **Do not log what the result already says.** If the result type carries the
  breakdown, the log line refers to the outcome, not a copy of it.
- **Structured, not prose.** Short constant message, details in attributes:
  `log.fine('check resolved', attributes: () => {AttributeKeys.outcome: 'success'})`,
  not `log.fine('The check by $name against DC $dc rolled $roll ...')`.
- **No hot-loop logging.** Never log inside per-modifier or per-combatant loops
  above `FINEST`. Aggregate instead: log counts, or record a metric.
- **Cheap when disabled.** Do not build expensive attribute maps eagerly.
  Attributes are closure-only: supply them as a closure the `Logger` calls only
  when the level is enabled; there is no eager-map form. Messages are
  constants, so never need building.
- **Actionable messages.** An error or warning says what failed, with enough
  attributes to find it (context, rule or content identifier, port), and what
  the consumer can do.
- **No secrets or personal data** in messages or attributes.
- **No `print`.** Anything that would be printed is a `FINE` or `FINEST` log.

---

## 8. Logs, metrics and traces together

- Pick the right signal. Counting or timing something is a **metric**. Seeing
  the path of one operation is a **trace**. Explaining one unusual event is a
  **log**.
- If a log line would be useful in aggregate (you would grep and count it), it
  should also be a metric. Do not make consumers parse logs to count things.
- The same fact uses the same attribute keys across all three signals so a
  consumer can correlate them.

---

## 9. Testing

- Use cases MUST be tested for their emitted telemetry using the recording test
  doubles: the expected metrics, span names, attribute keys and log levels.
- A test MUST assert that a use case behaves identically with the no-op
  `Observability` and with a recording one.
- Failure tests assert the error is recorded exactly once (span status, one
  counter increment) and is not also logged.
- The domain MUST have no observability tests, because it has no observability.
- Metric names and attribute keys are part of the public contract. Tests that
  pin them guard against accidental renames.

---

## 10. Enforcement

A test in `test/architecture/` MUST fail the build when it finds:

- An import of an observability or error-tracking SDK (`opentelemetry`,
  `sentry`, `package:logging`, etc.) anywhere under `lib/`, or such a package
  in `pubspec.yaml` `dependencies`.
- Any logging, metric or span call in a `domain/` file.
- `print(` anywhere in `lib/` (also covered by the `avoid_print` lint).
- A static or top-level logger, tracer or meter. A `const` instance of a no-op
  class is exempt; a non-`const` one is flagged.
- A metric, span, log-event or attribute name used as a string literal at a
  call site instead of a defined constant.
- A metric, span or log-event name defined in code that is missing from
  `doc/observability/signals.md`, or listed there but no longer defined in
  code. Signals and catalogue MUST match.
- A catalogue entry with an empty "Purpose" or "Suggested monitoring" field.
- A shared attribute value (the sets in §5 "Attributes") used in code or listed
  in the catalogue that is outside its defined set.
- A no-op observability class that is not `const`, or that lives under an
  `adapters/` folder instead of `lib/src/shared_ports/`.
- A test double outside `lib/src/testing/`, or a file other than
  `lib/testing.dart` importing it (see [architecture.md](architecture.md) §9).

Process checks (evaluation performed, `Observability` entry reported) cannot be
fully automated; they are enforced in review (§2).

---

## 11. Anti-patterns (prohibited)

- **Instrumenting the domain.** It breaks purity and couples rules to a backend.
- **Vendor lock-in:** SDK types in ports, or SDK imports in `lib/`.
- **Static loggers or global tracers.** (A `const` no-op instance is exempt.)
- **Log spam:** per-call `INFO`, logging in tight loops, logging the same event
  at several layers.
- **Log-and-throw / log-and-return:** logging an error and then raising or
  returning it.
- **Double counting:** an error counted by both an adapter and the use case,
  or a use case that calls another use case and so records its signals twice.
- **Wrong severity:** a failed check recorded as an error, or a handled
  fallback logged at `FINE` instead of `WARNING`.
- **High-cardinality attributes:** ids, free text or unbounded values.
- **Prose logs** with the data interpolated into the message.
- **Counting by log parsing:** a countable event that exists only as a log line.
- **Unnamed constants:** metric and attribute names scattered as literals.
- **Skipping the evaluation:** finishing a change without assessing
  observability, or reporting "N/A" without a specific reason.
- **Signals nobody can use:** emitting telemetry with no stated purpose or
  monitoring guidance, or leaving the catalogue out of date.
- **Instrument-after-incident:** waiting for a production problem before adding
  the signal that would have exposed it.

---

## Checklist before submitting

- [ ] I evaluated observability and monitoring for this change (§2), thinking
      through all seven questions.
- [ ] The commit/PR and my final summary include an `Observability` entry
      (signals added, changed, removed, and what to monitor) or a specific
      reason none were needed.
- [ ] `doc/observability/signals.md` is updated, with purpose and suggested
      monitoring filled in.
- [ ] For a bug fix: I added the signal that would have exposed it, or said why
      none could.
- [ ] Telemetry is produced in `application` (and adapters only for what the
      use case cannot see), never in `domain`.
- [ ] Each failure is recorded once, by its owner, per "Errors: who records
      what"; nothing is logged and also thrown or returned.
- [ ] Everything goes through the injected ports; no vendor imports, no globals.
- [ ] Anything countable or timeable is a metric, not only a log line.
- [ ] Durations are recorded through the ports, in seconds.
- [ ] Signal and attribute names are defined constants, correctly prefixed.
- [ ] Attributes are low-cardinality and free of personal data.
- [ ] Log levels are the lowest that serve the reader; nothing noisy at `INFO`.
- [ ] No duplicate logging; no log-and-throw; no `print`.
- [ ] Telemetry is covered by tests using the recording doubles.
- [ ] Architecture tests pass.

---

## Read receipt

RULE-TAG: `observability-4f9c28b17ae3`

This tag proves you read this document in this session. Quote it verbatim as
required by `AGENTS.md`. Do not copy it anywhere else. Whoever edits this
document MUST replace the tag with a fresh random value.
