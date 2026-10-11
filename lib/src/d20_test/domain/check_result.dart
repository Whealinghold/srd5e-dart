import 'package:meta/meta.dart';

import '../../shared_kernel/modifier.dart';
import 'd20_roll.dart';
import 'd20_test_kind.dart';
import 'd20_test_outcome.dart';
import 'd20_test_resolver.dart';
import 'difficulty_class.dart';
import 'roll_modifiers.dart';

/// The outcome of one ability check or saving throw ("D20 Tests",
/// SRD 5.2.1, p. 6): the roll it was made with, the modifiers added, the
/// total and the Difficulty Class it was compared with, and whether the test
/// succeeded.
///
/// It is an immutable value compared field by field. It carries everything a
/// consumer needs to render its own breakdown, and no `Ability` and no
/// separate roll-mode field: the mode is `D20Roll.mode`. There is no
/// critical-hit field — the natural 20 and natural 1 rules hold for attack
/// rolls only (SRD 5.2.1, "Rolling 20 or 1", p. 7) — so the outcome is
/// `D20TestOutcome` alone.
@immutable
final class CheckResult {
  /// Resolves [kind] (`abilityCheck` or `savingThrow`) for [roll] with
  /// [modifiers] against the Difficulty Class [target].
  ///
  /// Published static delegate of `D20TestResolver.resolveCheck` (the
  /// behaviour is identical): any `D20Roll` is accepted, including a rerolled
  /// or replaced one, so downstream domain code resolves a rerolled roll
  /// without the use case. Throws the same [ArgumentError] (name `kind`)
  /// when [kind] is `attackRoll`.
  static CheckResult resolve(
    D20TestKind kind,
    D20Roll roll,
    RollModifiers modifiers,
    DifficultyClass target,
  ) => const D20TestResolver().resolveCheck(kind, roll, modifiers, target);

  /// Creates a result from its parts. Prefer [resolve], which derives the
  /// [total] and [outcome] from the rules.
  const CheckResult({
    required this.kind,
    required this.roll,
    required this.modifiers,
    required this.total,
    required this.target,
    required this.outcome,
  });

  /// Which kind of D20 Test this is: an ability check or a saving throw.
  /// Never `attackRoll` for a result from [resolve].
  final D20TestKind kind;

  /// The roll the test was made with, including its mode, dice and the
  /// natural value used.
  final D20Roll roll;

  /// The modifiers added to the natural value.
  final RollModifiers modifiers;

  /// The total the test compared with the target: the roll's natural value
  /// plus the modifiers' kernel sum, with no clamping.
  final int total;

  /// The Difficulty Class the total was compared with.
  final DifficultyClass target;

  /// Whether the test succeeded (`success`: the total equals or exceeds the
  /// DC) or failed.
  final D20TestOutcome outcome;

  /// The result of the same test with the adjustment [delta] applied after
  /// the roll (an effect that adds or subtracts, "Add Modifiers",
  /// SRD 5.2.1, p. 6): a new result for the same [kind], [roll] and [target]
  /// with `Modifier(delta)` appended to the modifiers' others, the total
  /// re-derived and the outcome re-resolved by the rules of [resolve].
  ///
  /// A delta of 0 is allowed and yields a result whose others carry one 0
  /// modifier. The original result is unchanged.
  CheckResult adjustedBy(int delta) {
    final adjusted = RollModifiers(
      ability: modifiers.ability,
      proficiencyBonus: modifiers.proficiencyBonus,
      others: [...modifiers.others, Modifier(delta)],
    );
    return resolve(kind, roll, adjusted, target);
  }

  @override
  bool operator ==(Object other) =>
      other is CheckResult &&
      other.kind == kind &&
      other.roll == roll &&
      other.modifiers == modifiers &&
      other.total == total &&
      other.target == target &&
      other.outcome == outcome;

  @override
  int get hashCode =>
      Object.hash(kind, roll, modifiers, total, target, outcome);
}
