import 'package:meta/meta.dart';

import '../../shared_kernel/ability/ability.dart';
import '../../shared_kernel/dice/dice_expression.dart';
import '../../shared_kernel/dice/die.dart';
import '../../shared_kernel/roll_circumstance.dart';
import '../../shared_kernel/roll_mode.dart';
import '../../shared_ports/dice_roller/dice_roller.dart';
import '../../shared_ports/dice_roller/dice_roller_checked.dart';
import '../../shared_ports/dice_roller/dice_roller_exception.dart';
import '../../shared_ports/observability/meter.dart';
import '../../shared_ports/observability/observability.dart';
import '../../shared_ports/observability/tracer.dart';
import '../../shared_ports/signals.dart';
import '../domain/d20_roll.dart';
import '../domain/d20_test_kind.dart';
import '../domain/d20_test_outcome.dart';
import '../domain/d20_test_resolver.dart';
import '../domain/difficulty_class.dart';
import '../domain/forced_failure_reason.dart';
import '../domain/roll_modifiers.dart';
import 'd20_test_attempts.dart';
import 'd20_test_command.dart';
import 'd20_test_signals.dart';
import 'resolve_d20_test_result.dart';

/// The first use case of the package: resolve one D20 Test — an ability
/// check, a saving throw or an attack roll ("D20 Tests", SRD 5.2.1, p. 6).
///
/// The use case orchestrates and contains no rules logic: it derives the roll
/// mode from the attempt's circumstances with one `RollMode.resolve`, makes
/// exactly one `rollChecked` request sized by that mode (a single `1d20` in
/// `normal`, a single `2d20` in `advantage` or `disadvantage`; none for a
/// chosen or automatic failure), hands the dice to the pure
/// [D20TestResolver], and returns the sealed [ResolveD20TestResult] with the
/// whole breakdown. It is never called by another use case: a use case
/// needing a D20 Test result composes `D20TestResolver` and records its own
/// signals.
///
/// The [DiceRoller] is taken through the constructor, typed as the port;
/// [observability] defaults to `Observability.none`, so omitting it is silent
/// and changes no behaviour. Both ports are synchronous, so `call` is
/// synchronous and returns its result directly. A `DiceRollerException`
/// (`unavailable` from a failing roller, `invalidResult` for a wrong answer)
/// propagates unchanged and is recorded once; a failed check or a missed
/// attack is a normal result, not an error.
@immutable
final class ResolveD20Test {
  /// Creates the use case. The observability instruments are created once,
  /// here, from the injected [observability].
  ResolveD20Test(
    this._diceRoller, {
    Observability observability = Observability.none,
  }) : _observability = observability,
       _resolver = const D20TestResolver(),
       _resolved = observability.meter.createCounter(
         D20TestSignals.resolvedMetric,
         unit: '{test}',
         description: 'Resolved D20 Tests, by outcome.',
       ),
       _duration = observability.meter.createHistogram(
         D20TestSignals.durationMetric,
         unit: 's',
         description: 'Duration of resolving one D20 Test.',
       ),
       _modifiers = observability.meter.createHistogram(
         D20TestSignals.modifiersMetric,
         unit: '{modifier}',
         description: 'Modifiers in one D20 Test roll.',
       ),
       _natural = observability.meter.createHistogram(
         D20TestSignals.naturalMetric,
         unit: '{face}',
         description: 'The d20 face a rolled D20 Test used, 1 to 20.',
       ),
       _errors = observability.meter.createCounter(
         D20TestSignals.errorsMetric,
         unit: '{error}',
         description: 'Dice roller failures leaving the use case.',
       );

  final DiceRoller _diceRoller;

  final D20TestResolver _resolver;

  final Observability _observability;

  final Counter _resolved;

  final Histogram _duration;

  final Histogram _modifiers;

  final Histogram _natural;

  final Counter _errors;

  /// Resolves [command] and returns the result. Synchronous: both ports are.
  ResolveD20TestResult call(D20TestCommand command) {
    final kindValue = _kindValue(_kindOf(command));
    final attributes = <String, Object>{
      D20TestSignals.kindAttribute: kindValue,
      D20TestSignals.abilityAttribute: command.ability.name,
    };
    return _observability.tracer.trace(D20TestSignals.resolveSpan, (span) {
      // The timing encloses the work inside the span, so a failure reaches
      // the span after the duration is recorded.
      return _observability.meter.time(_duration, () {
        try {
          final result = _resolve(command);
          _record(span, result, kindValue, attributes);
          return result;
        } on DiceRollerException catch (error) {
          // Recorded exactly once, here; the span status and the
          // exception on it are the Tracer's record-and-rethrow.
          final rollerFailure = _rollerFailureValue(error.reason);
          span.setAttribute(
            D20TestSignals.rollerFailureAttribute,
            rollerFailure,
          );
          _errors.add(
            1,
            attributes: <String, Object>{
              D20TestSignals.kindAttribute: kindValue,
              AttributeKeys.errorType: error.errorType,
              D20TestSignals.rollerFailureAttribute: rollerFailure,
            },
          );
          rethrow;
        }
      }, attributes: <String, Object>{D20TestSignals.kindAttribute: kindValue});
    }, attributes: Map<String, Object>.of(attributes));
  }

  /// The kind a command variant stands for.
  static D20TestKind _kindOf(D20TestCommand command) => switch (command) {
    AbilityCheckCommand() => D20TestKind.abilityCheck,
    SavingThrowCommand() => D20TestKind.savingThrow,
    AttackRollCommand() => D20TestKind.attackRoll,
  };

  /// The `srd5e.d20_test.kind` attribute value of [kind].
  static String _kindValue(D20TestKind kind) => switch (kind) {
    D20TestKind.abilityCheck => D20TestSignals.abilityCheckKindValue,
    D20TestKind.savingThrow => D20TestSignals.savingThrowKindValue,
    D20TestKind.attackRoll => D20TestSignals.attackRollKindValue,
  };

  /// The `srd5e.d20_test.forced_failure_reason` attribute value of [reason].
  static String _forcedFailureReasonValue(ForcedFailureReason reason) =>
      switch (reason) {
        ForcedFailureReason.chosenToFail =>
          D20TestSignals.forcedFailureChosenToFailValue,
        ForcedFailureReason.automatic =>
          D20TestSignals.forcedFailureAutomaticValue,
      };

  /// The `srd5e.d20_test.roller_failure` attribute value of [reason].
  static String _rollerFailureValue(DiceRollerFailureReason reason) =>
      switch (reason) {
        DiceRollerFailureReason.unavailable =>
          D20TestSignals.rollerFailureUnavailableValue,
        DiceRollerFailureReason.invalidResult =>
          D20TestSignals.rollerFailureInvalidResultValue,
      };

  /// Resolves [command] through the domain service, and wraps the domain
  /// result with the command's ability and target.
  ResolveD20TestResult _resolve(D20TestCommand command) => switch (command) {
    AbilityCheckCommand(:final ability, :final target, :final attempt) =>
      switch (attempt) {
        RollAttempt() => _rolledCheck(
          ability,
          D20TestKind.abilityCheck,
          attempt,
          target,
        ),
        AutomaticFailure() => ResolveD20TestForcedFailure(
          ability,
          result: _resolver.forcedFailure(
            D20TestKind.abilityCheck,
            ForcedFailureReason.automatic,
          ),
          target: target,
        ),
      },
    SavingThrowCommand(:final ability, :final target, :final attempt) =>
      switch (attempt) {
        RollAttempt() => _rolledCheck(
          ability,
          D20TestKind.savingThrow,
          attempt,
          target,
        ),
        ChooseToFail() => ResolveD20TestForcedFailure(
          ability,
          result: _resolver.forcedFailure(
            D20TestKind.savingThrow,
            ForcedFailureReason.chosenToFail,
          ),
          target: target,
        ),
        AutomaticFailure() => ResolveD20TestForcedFailure(
          ability,
          result: _resolver.forcedFailure(
            D20TestKind.savingThrow,
            ForcedFailureReason.automatic,
          ),
          target: target,
        ),
      },
    AttackRollCommand(:final ability, :final target, :final attempt) =>
      ResolveD20TestRolledAttack(
        ability,
        result: _resolver.resolveAttackRoll(
          _rolled(attempt.circumstances),
          attempt.modifiers,
          target,
        ),
      ),
  };

  /// The roll one attempt makes: the mode resolved once from the
  /// circumstances, exactly one checked request sized by that mode, and the
  /// faces, in request order, handed to the domain.
  D20Roll _rolled(Iterable<RollCircumstance> circumstances) {
    final mode = RollMode.resolve(circumstances);
    final rolled = _diceRoller.rollChecked(
      DiceExpression(mode.diceCount, Die.d20),
    );
    return D20Roll(
      mode: mode,
      dice: [for (final dieRoll in rolled.rolls) dieRoll.value],
    );
  }

  /// The rolled check or save of [kind]: the shared shape of the two command
  /// variants (FR-058c). Their attempt types and validation stay distinct;
  /// only the resolver call is shared.
  ResolveD20TestRolledCheck _rolledCheck(
    Ability ability,
    D20TestKind kind,
    RollAttempt attempt,
    DifficultyClass target,
  ) => ResolveD20TestRolledCheck(
    ability,
    result: _resolver.resolveCheck(
      kind,
      _rolled(attempt.circumstances),
      attempt.modifiers,
      target,
    ),
  );

  /// Records the outcome on the span and the meter, then counts the resolved
  /// call with the span's attributes. A failed check or a missed attack is a
  /// normal outcome. A rolled call also records the d20 face it used. A
  /// forced failure carries why it was forced and has no roll mode and no
  /// critical-hit flag, so those attributes stay absent.
  void _record(
    Span span,
    ResolveD20TestResult result,
    String kindValue,
    Map<String, Object> attributes,
  ) {
    switch (result) {
      case ResolveD20TestRolledCheck(result: final check):
        _setAttribute(
          span,
          attributes,
          D20TestSignals.rollModeAttribute,
          check.roll.mode.name,
        );
        _setAttribute(
          span,
          attributes,
          AttributeKeys.outcome,
          check.outcome.name,
        );
        _modifiers.record(
          _modifierCount(check.modifiers),
          attributes: <String, Object>{D20TestSignals.kindAttribute: kindValue},
        );
        _natural.record(
          check.roll.natural,
          attributes: <String, Object>{D20TestSignals.kindAttribute: kindValue},
        );
      case ResolveD20TestRolledAttack(result: final attack):
        _setAttribute(
          span,
          attributes,
          D20TestSignals.rollModeAttribute,
          attack.roll.mode.name,
        );
        _setAttribute(
          span,
          attributes,
          AttributeKeys.outcome,
          attack.outcome.name,
        );
        span.setAttribute(
          D20TestSignals.criticalHitAttribute,
          attack.isCriticalHit,
        );
        attributes[D20TestSignals.criticalHitAttribute] = attack.isCriticalHit;
        _modifiers.record(
          _modifierCount(attack.modifiers),
          attributes: <String, Object>{D20TestSignals.kindAttribute: kindValue},
        );
        _natural.record(
          attack.roll.natural,
          attributes: <String, Object>{D20TestSignals.kindAttribute: kindValue},
        );
      case ResolveD20TestForcedFailure(result: final failure):
        _setAttribute(
          span,
          attributes,
          D20TestSignals.forcedFailureReasonAttribute,
          _forcedFailureReasonValue(failure.reason),
        );
        _setAttribute(
          span,
          attributes,
          AttributeKeys.outcome,
          D20TestOutcome.failure.name,
        );
    }
    _resolved.add(1, attributes: Map<String, Object>.of(attributes));
  }

  /// Sets [key] to [value] on the span and in the attributes shared with the
  /// counter, so the two stay identical.
  void _setAttribute(
    Span span,
    Map<String, Object> attributes,
    String key,
    Object value,
  ) {
    span.setAttribute(key, value);
    attributes[key] = value;
  }

  /// The number of modifiers in [modifiers]: the ability modifier, the
  /// Proficiency Bonus when present, and each other modifier. At least 1.
  static int _modifierCount(RollModifiers modifiers) =>
      1 +
      (modifiers.proficiencyBonus == null ? 0 : 1) +
      modifiers.others.length;
}
