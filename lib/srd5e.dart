/// A pure-Dart, framework-agnostic implementation of the fifth-edition rules
/// in System Reference Document 5.2.1.
///
/// This is the package's main public entry point. Generic adapters and test
/// doubles will have their own entry points (`adapters.dart`,
/// `testing.dart`). Everything under `lib/src/` is private; export
/// deliberately from here.
///
/// ## Errors and results
///
/// srd5e separates three kinds of "it did not go to plan":
///
/// * An expected outcome, an absence or a rejection (a failed check, a
///   content id that is not found, host-supplied input that fails validation)
///   is returned as a variant of a sealed result type, never thrown. Switch
///   over it exhaustively, with no default branch.
/// * A failure of something outside the package (a dice roller or content
///   source that fails, or breaks its documented contract) is thrown as a
///   concrete subtype of [Srd5eException]. Catch it with
///   `on Srd5eException catch (e)` and read `e.errorType`, `e.cause` and
///   `e.causeStackTrace`. A `switch` over [Srd5eException] needs a default
///   branch, because the root is not sealed.
/// * A programmer error (an invalid constructor argument, a broken invariant)
///   is an [ArgumentError], [StateError] or another [Error]. It is a bug in the
///   caller and is not meant to be caught.
///
/// Adapters that implement a port wrap the exceptions of their backend with
/// [wrapPortFailure] (synchronous ports) or [wrapPortFailureAsync]
/// (asynchronous ports), so a backend [Exception] surfaces as the port's typed
/// subtype with the original kept as `cause`.
///
/// ## D20 rolls
///
/// [Modifier] is a signed whole number added to the number rolled on the d20,
/// and modifiers add together. [RollMode.resolve] turns any number of
/// [Advantage] and [Disadvantage] circumstances into a [RollMode] (they do not
/// stack, and at least one of each cancels to normal); `RollMode.diceCount`
/// says how many d20s to roll and `RollMode.select` picks the one that is used.
///
/// ## Abilities
///
/// [Ability] names the six abilities. An [AbilityScore] is a whole number from
/// 1 to 30 (`AbilityScore.minimum` and `AbilityScore.maximum`); its `modifier`
/// is the [AbilityModifier] from the SRD's Ability Modifiers table. [AbilityScores]
/// holds one score for each ability (`scoreOf`, `modifierOf`, `withScore`).
/// The constructor of [AbilityScore] throws [ArgumentError] for a number
/// outside the range; `AbilityScore.tryCreate` takes untrusted input and
/// returns an [AbilityScoreResult], either [ValidAbilityScore] or
/// [InvalidAbilityScore] with an [AbilityScoreRejection]. An [AbilityModifier]
/// is not a [Modifier]; convert with `Modifier(abilityModifier.value)`.
///
/// ## Observability
///
/// srd5e emits logs, traces and metrics through three small ports that you
/// implement: [Logger], [Tracer] and [Meter], bundled as [Observability]. A
/// use case takes `Observability observability = Observability.none`, so
/// omitting it gives silent `const` no-ops ([NoopLogger], [NoopTracer],
/// [NoopMeter], [NoopObservability]) and identical behaviour. Supply only the
/// ports you have: `Observability(logger: myLogger)` leaves the other two as
/// no-ops.
///
/// * [Logger.log] takes a [LogLevel], a constant message and attributes as a
///   closure that is called only when the level is enabled; [LoggerLevels]
///   adds `fine`, `warning` and the other shortcuts.
/// * [Tracer.trace] and `traceAsync` run a unit of work inside a named [Span]
///   (attributes, a [SpanStatus], recorded errors). An error thrown by the
///   work is recorded on the span and rethrown unchanged.
/// * [Meter] creates a [Counter], [Histogram] or [Gauge] and times work into a
///   duration histogram with `time` and `timeAsync`, in seconds. srd5e never
///   reads the clock; your adapter does.
/// * [Attributes] are plain `String`, `bool`, `int` or `double` values.
///   [AttributeKeys.outcome] and [AttributeKeys.errorType] are the keys shared
///   by every signal; `doc/observability/signals.md` lists the signals.
///
/// Production implementations must not throw of their own accord, and srd5e
/// does not catch what they throw. Bridges to OpenTelemetry, `package:logging`
/// or Sentry are not shipped; the README shows how to write one. Recording
/// doubles for tests are in `package:srd5e/testing.dart`.
library;

export 'src/shared_kernel/ability/ability.dart' show Ability;
export 'src/shared_kernel/ability/ability_score.dart'
    show AbilityModifier, AbilityScore;
export 'src/shared_kernel/ability/ability_score_result.dart'
    show
        AbilityScoreRejection,
        AbilityScoreResult,
        InvalidAbilityScore,
        ValidAbilityScore;
export 'src/shared_kernel/ability/ability_scores.dart' show AbilityScores;
export 'src/shared_kernel/dice/dice_expression.dart'
    show
        CreatedDiceExpression,
        DiceExpression,
        DiceExpressionCreation,
        DiceExpressionParse,
        DiceExpressionRejection,
        ParsedDiceExpression,
        RejectedDiceExpression,
        RejectedDiceExpressionInput;
export 'src/shared_kernel/dice/die.dart'
    show CreatedDie, Die, DieCreation, DieRejection, RejectedDie;
export 'src/shared_kernel/dice/die_roll.dart'
    show
        CreatedDieRoll,
        DieRoll,
        DieRollCreation,
        DieRollRejection,
        RejectedDieRoll;
export 'src/shared_kernel/dice/roll_result.dart'
    show
        CreatedRollResult,
        RejectedRollResult,
        RollResult,
        RollResultCreation,
        RollResultRejection;
export 'src/shared_kernel/modifier.dart' show Modifier;
export 'src/shared_kernel/roll_circumstance.dart'
    show Advantage, Disadvantage, RollCircumstance;
export 'src/shared_kernel/roll_mode.dart' show RollMode;
export 'src/shared_ports/dice_roller/dice_roller.dart' show DiceRoller;
export 'src/shared_ports/dice_roller/dice_roller_checked.dart'
    show DiceRollerChecked;
export 'src/shared_ports/dice_roller/dice_roller_exception.dart'
    show DiceRollerException, DiceRollerFailureReason;
export 'src/shared_ports/errors/port_failure_guards.dart'
    show wrapPortFailure, wrapPortFailureAsync;
export 'src/shared_ports/errors/srd5e_exception.dart' show Srd5eException;
export 'src/shared_ports/observability/attributes.dart' show Attributes;
export 'src/shared_ports/observability/log_level.dart' show LogLevel;
export 'src/shared_ports/observability/logger.dart'
    show Logger, LoggerLevels, NoopLogger;
export 'src/shared_ports/observability/meter.dart'
    show Counter, Gauge, Histogram, Meter, NoopMeter;
export 'src/shared_ports/observability/observability.dart'
    show NoopObservability, Observability;
export 'src/shared_ports/observability/tracer.dart'
    show NoopTracer, Span, SpanStatus, Tracer;
export 'src/shared_ports/signals.dart' show AttributeKeys;
