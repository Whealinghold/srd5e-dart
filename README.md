# srd5e

A pure-Dart, framework-agnostic implementation of the fifth-edition rules in System Reference Document 5.2.1.

Status: early. Dice, modifiers, ability scores, the `DiceRoller` port and the error model exist; the rules themselves are not implemented yet.

## Goals

- Reusable by any Dart project: Flutter apps, servers, CLIs, web.
- No dependency on Flutter, UI, persistence, state management or any
  specific consuming project.
- Rules engine (code) kept separate from rules content (data).

## Usage

```yaml
dependencies:
  srd5e:
    path: ../srd5e-dart # during local development
```

```dart
import 'package:srd5e/srd5e.dart';
```

## Dice and rolling

All randomness enters through the `DiceRoller` port, so the rules stay pure and
tests stay deterministic.

- **Values** (`package:srd5e/srd5e.dart`): `Die`, `DiceExpression` (`1d20`,
  `2d8 + 2`), `DieRoll` and `RollResult`. Read untrusted text with
  `DiceExpression.tryParse` and untrusted numbers with the `tryCreate`
  factories, which return sealed results. The plain constructors throw
  `ArgumentError`.
- **Rolling:** call `roller.rollChecked(expression)`. A roller that cannot roll
  throws `DiceRollerException` (`errorType` `dice_roller_exception`); one that
  answers the wrong expression is reported the same way, with the reason
  `invalidResult`.
- **Adapter** (`package:srd5e/adapters.dart`): `SeededDiceRoller(Random(7))`
  rolls from a `Random` you supply. It never creates one itself.
- **Test doubles** (`package:srd5e/testing.dart`): `FixedDiceRoller([18, 3])`
  serves the faces you choose, `FixedDiceRoller.minimum()` and `.maximum()`
  roll the extremes, and `CallbackDiceRoller` simulates failures.

See [example/dice_example.dart](example/dice_example.dart).

### Testing your own `DiceRoller`

The contract suite for the port is `test/contract/dice_roller_contract.dart`.
It is not exported, because it needs `package:test`. Copy it into your tests
and call `diceRollerContract('MyRoller', () => MyRoller(), failingVariant:
...)`. The `failingVariant` factory builds your roller over a backend that
throws the `Exception` it is given, and the suite then checks that your adapter
surfaces it as `DiceRollerException(unavailable)` with the same `cause` and
`causeStackTrace` (wrap the backend call with `wrapPortFailure`).

## Content sources

Content reaches the rules through the `ContentSource` port
(`package:srd5e/srd5e.dart`):

- **Lookup:** `source.lookup(key)` returns a sealed `ContentLookup` — a
  `ContentFound` carrying the entry, or a `ContentNotFound` carrying the
  requested `ContentKey` (and its `missing` detail). Absence is a result,
  never a throw. `source.listKind(kind)` returns every entry of one kind,
  ordered by id; an empty list when there is none. Both lists are
  unmodifiable.
- **Adapters** (`package:srd5e/adapters.dart`): `InMemoryContentSource`
  serves an in-memory list of entries; `BundledContentSource` serves the
  embedded SRD content documents and throws `BundledContentInvalid` when the
  bundle does not decode or fails cross-reference validation.
- **Failures:** a backend that fails completes the future with a
  `ContentSourceException` (`errorType` `content_source_exception`) carrying
  the `ContentQuery` asked, the cause and its stack trace. Wrap your backend
  call with `wrapPortFailureAsync`.
- **Test doubles** (`package:srd5e/testing.dart`): `FakeContentSource`
  answers from an in-memory catalogue and can be scripted to fail, recording
  every request.

### Testing your own `ContentSource`

The contract suite for the port is
`test/contract/content_source_contract.dart`. It is not exported, because it
needs `package:test`. Copy it into your tests and run
`contentSourceContractChecks(create: ..., createFailing: ...)` against your
adapter — `create` builds it from arbitrary entries, and the optional
`createFailing` builds it over a backend that throws the `Exception` it is
given, so the suite can check that your adapter surfaces it as
`ContentSourceException` with the same cause. For a source backed by a fixed
fixture, use `contentSourceReadOnlyChecks(source: ..., expectedEntries: ...)`.
A failed check throws `ContentSourceContractViolation` naming the check.

## Ability scores

`Ability` names the six abilities. An `AbilityScore` is a whole number from 1 to
30; its `modifier` is the `AbilityModifier` from the SRD's Ability Modifiers
table (score 1 gives -5, 10 gives +0, 20 gives +5, 30 gives +10). The
constructor throws `ArgumentError` for a number outside 1 to 30; read untrusted
numbers with `AbilityScore.tryCreate`, which returns a sealed
`AbilityScoreResult` (`ValidAbilityScore` or `InvalidAbilityScore` with an
`AbilityScoreRejection`). `AbilityScores.fromMap` holds one score per ability
(`scoreOf`, `modifierOf`, `withScore`). An `AbilityModifier` is not a
`Modifier`: convert it with `Modifier(abilityModifier.value)`.

## Observability (logging, tracing, metrics)

srd5e emits logs, traces and metrics but never chooses a backend. It defines
three small ports (`Logger`, `Tracer`, `Meter`), bundled as `Observability`.
You inject your own implementations, for example OpenTelemetry for traces and
metrics and `package:logging` or your app's logger for logs.

- **Optional.** If you inject nothing, everything is a silent no-op.
- **No vendor dependencies.** srd5e does not depend on OpenTelemetry, Sentry or
  any logging package. Your adapters live in your project.
- **Injected once,** through the constructor of the engine or use case you
  create. There are no global loggers or registries.
- **Metrics are shaped for OpenTelemetry** (counters, histograms, low-cardinality
  attributes), so an adapter is a thin translation.
- Only the application layer emits telemetry. The domain stays pure and silent;
  what happened is in the returned results and events.

> The API below is the planned design and does not exist yet. Names are
> provisional. The rules are in
> [doc/rules/observability.md](doc/rules/observability.md).

```dart
// In your project: adapt your own tools to srd5e's ports.
class OtelMeter implements Meter { /* forward to your OpenTelemetry meter */ }
class OtelTracer implements Tracer { /* forward to your OpenTelemetry tracer */ }

class LoggingBridge implements srd5e.Logger { /* forward to package:logging */ }

final observability = Observability(
  logger: LoggingBridge(Logger('srd5e')),
  tracer: OtelTracer(tracer),
  meter: OtelMeter(meter),
);

final resolveCheck = ResolveD20Test(
  roller: SeededDiceRoller(42),
  observability: observability, // omit for no-op
);
```

Bridges to `package:logging`, OpenTelemetry and similar are not shipped, so
srd5e never pulls those packages into your app. Examples will live in
`example/`. Tests can use the recording doubles in `package:srd5e/testing.dart`
to assert on what was emitted.

## Errors and results

srd5e keeps three kinds of "it did not go to plan" apart:

- **Expected outcomes** (a failed check, a content id that is not found, input
  that fails validation) are returned as a variant of a sealed result type and
  switched over exhaustively. They are never thrown.
- **Failures outside the package** (a dice roller or content source that fails,
  or breaks its contract) are thrown as a subtype of `Srd5eException`. Catch
  `on Srd5eException` and read `errorType`, `cause` and `causeStackTrace`. The
  root is not sealed, so a `switch` over it needs a default branch.
- **Programmer errors** (an invalid constructor argument, a broken invariant)
  are `ArgumentError`, `StateError` or another `Error`, and are bugs, not
  conditions to handle.

Adapters wrap their backend's exceptions with `wrapPortFailure` (synchronous
ports) or `wrapPortFailureAsync` (asynchronous ports), which keep the original
exception and stack trace and let errors and srd5e's own exceptions through
untouched.

## Development

Dart is not installed on the host; use Docker:

```sh
docker run --rm -v "$PWD":/app -w /app dart:stable sh -c \
  "dart pub get && dart format --set-exit-if-changed . && dart analyze --fatal-infos && dart run coverage:test_with_coverage -- --test-randomize-ordering-seed=random"
```

## Licence and content

- **Code:** MIT. See [LICENSE](LICENSE).
- **Game content:** rules from the System Reference Document 5.2.1, used under
  the Creative Commons Attribution 4.0 International License. The required
  attribution is in [NOTICE.md](NOTICE.md). Nothing outside the SRD is
  included, and Wizards' trademarks are not used.

This work includes material from the System Reference Document 5.2.1 (“SRD
5.2.1”) by Wizards of the Coast LLC, available at
https://www.dndbeyond.com/srd. The SRD 5.2.1 is licensed under the Creative
Commons Attribution 4.0 International License, available at
https://creativecommons.org/licenses/by/4.0/legalcode.

This package is compatible with fifth edition. It is independent and is not
published, endorsed or approved by Wizards of the Coast.
