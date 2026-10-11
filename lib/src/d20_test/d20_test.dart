/// The `d20_test` bounded context: the pure model of D20 Tests — ability
/// checks, saving throws and attack rolls (SRD 5.2.1, "D20 Tests", pp. 6-8) —
/// and the `ResolveD20Test` use case that resolves one of them.
///
/// ### Inputs
///
/// What a consumer supplies: the resolved [RollMode] and the d20 face values
/// in the order rolled (a `D20Roll`); kernel `Modifier`s — exactly one
/// ability modifier, at most one Proficiency Bonus and any number of others
/// (a `RollModifiers`); a target number (`DifficultyClass` for checks and
/// saves, `ArmorClass` for attack rolls); and, for a reroll, a
/// [RerollDecision] with the new face.
///
/// To the use case a consumer supplies a [D20TestCommand]: the command's
/// [Ability] label, the attempt ([RollAttempt] with its `RollModifiers` and
/// circumstances, [ChooseToFail], or [AutomaticFailure]) and the target, and
/// a `DiceRoller` with an optional `Observability`.
///
/// ### Outputs
///
/// What the context hands back: a `D20Roll` holding its `dice`, `natural` and
/// `keptIndex`, with `replaceDie` and `applyReroll` returning new rolls;
/// `RollModifiers` as an immutable value, whose `total` is the kernel sum of
/// its modifiers; the Typical Difficulty Classes as named constants on
/// `DifficultyClass`; the closed vocabularies [D20TestKind],
/// [D20TestOutcome] and [ForcedFailureReason]; the resolved outcomes as
/// values — a `CheckResult` or `AttackRollResult` carrying roll, modifiers,
/// total, target and outcome (the attack result also `isCriticalHit` and
/// `criticalRange`, with `hit`), and a `ForcedFailureResult` for a failure
/// without a roll — resolvable through `CheckResult.resolve`,
/// `AttackRollResult.resolve` and `ForcedFailureResult.of`, or through the
/// pure [D20TestResolver] service the static members delegate to.
///
/// The use case hands back a [ResolveD20TestResult] — a
/// `ResolveD20TestRolledCheck`, a `ResolveD20TestRolledAttack` or a
/// `ResolveD20TestForcedFailure` — carrying the command's ability, the domain
/// result of the kind it rolled and the typed target, plus [D20TestSignals],
/// the constants of the telemetry the use case emits.
///
/// The kernel types (`Modifier`, `RollMode`, `RollCircumstance`) are not
/// re-exported here; import them from the package's public entry point.
library;

export 'application/d20_test_attempts.dart'
    show AutomaticFailure, CheckAttempt, ChooseToFail, RollAttempt, SaveAttempt;
export 'application/d20_test_command.dart'
    show
        AbilityCheckCommand,
        AttackRollCommand,
        D20TestCommand,
        SavingThrowCommand;
export 'application/d20_test_signals.dart' show D20TestSignals;
export 'application/resolve_d20_test.dart' show ResolveD20Test;
export 'application/resolve_d20_test_result.dart'
    show
        ResolveD20TestForcedFailure,
        ResolveD20TestResult,
        ResolveD20TestRolledAttack,
        ResolveD20TestRolledCheck;
export 'domain/armor_class.dart' show ArmorClass;
export 'domain/attack_roll_result.dart' show AttackRollResult;
export 'domain/check_result.dart' show CheckResult;
export 'domain/d20_roll.dart' show D20Roll;
export 'domain/d20_test_kind.dart' show D20TestKind;
export 'domain/d20_test_outcome.dart' show D20TestOutcome;
export 'domain/d20_test_resolver.dart' show D20TestResolver;
export 'domain/difficulty_class.dart' show DifficultyClass;
export 'domain/forced_failure_reason.dart' show ForcedFailureReason;
export 'domain/forced_failure_result.dart' show ForcedFailureResult;
export 'domain/reroll_decision.dart' show KeepRoll, RerollDecision, RerollDie;
export 'domain/roll_modifiers.dart' show RollModifiers;
