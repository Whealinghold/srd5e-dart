/// The names of the signals `ResolveD20Test` emits and the attribute keys it
/// sets, defined once (doc/specs/resolve-d20-test-use-case.md section 7, the
/// single authority for these signals).
///
/// The names and keys are part of the public contract: renaming one is a
/// breaking change for consumers' dashboards and alerts
/// (`doc/rules/observability.md` §5). Call sites use the constants; no signal
/// or key appears as a string literal anywhere else. The keys shared by every
/// signal, `srd5e.outcome` and `error.type`, are [AttributeKeys.outcome] and
/// [AttributeKeys.errorType] in `shared_ports/`. `doc/observability/signals.md`
/// catalogues these signals.
abstract final class D20TestSignals {
  /// The span that wraps one `ResolveD20Test` call.
  static const String resolveSpan = 'srd5e.d20_test.resolve';

  /// The counter of resolved calls, by outcome.
  static const String resolvedMetric = 'srd5e.d20_test.resolved';

  /// The histogram of call durations, in seconds, failed calls included.
  static const String durationMetric = 'srd5e.d20_test.duration';

  /// The histogram of the number of modifiers in a call's `RollModifiers`.
  static const String modifiersMetric = 'srd5e.d20_test.modifiers';

  /// The histogram of the d20 face a rolled call used, 1 to 20.
  static const String naturalMetric = 'srd5e.d20_test.natural';

  /// The counter of thrown port failures leaving the use case.
  static const String errorsMetric = 'srd5e.d20_test.errors';

  /// The key of the kind of D20 Test resolved.
  static const String kindAttribute = 'srd5e.d20_test.kind';

  /// The key of the command's ability label.
  static const String abilityAttribute = 'srd5e.ability';

  /// The key of the roll mode; absent for a forced failure, where no d20 was
  /// rolled.
  static const String rollModeAttribute = 'srd5e.d20_test.roll_mode';

  /// The key of the critical-hit flag; an attack roll only.
  static const String criticalHitAttribute = 'srd5e.d20_test.critical_hit';

  /// The key of the reason a `DiceRoller` failed; the `errors` counter and
  /// the error span only.
  static const String rollerFailureAttribute = 'srd5e.d20_test.roller_failure';

  /// The key of why a call was forced to fail; a forced failure only.
  static const String forcedFailureReasonAttribute =
      'srd5e.d20_test.forced_failure_reason';

  /// The `srd5e.d20_test.kind` value of an ability check.
  static const String abilityCheckKindValue = 'ability_check';

  /// The `srd5e.d20_test.kind` value of a saving throw.
  static const String savingThrowKindValue = 'saving_throw';

  /// The `srd5e.d20_test.kind` value of an attack roll.
  static const String attackRollKindValue = 'attack_roll';

  /// The `srd5e.d20_test.roller_failure` value of an unavailable roller.
  static const String rollerFailureUnavailableValue = 'unavailable';

  /// The `srd5e.d20_test.roller_failure` value of a roller that broke its
  /// contract by answering a different expression.
  static const String rollerFailureInvalidResultValue = 'invalid_result';

  /// The `srd5e.d20_test.forced_failure_reason` value of a failure the
  /// creature chose.
  static const String forcedFailureChosenToFailValue = 'chosen_to_fail';

  /// The `srd5e.d20_test.forced_failure_reason` value of a failure the
  /// caller declared.
  static const String forcedFailureAutomaticValue = 'automatic';
}
