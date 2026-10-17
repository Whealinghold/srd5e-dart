import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import '../named_text.dart';

/// One printed Casting Time form, sealed with exactly the five exported
/// variants ("Casting Time", SRD 5.2.1, p. 105) (FR-026).
///
/// Printed "Action" is the Magic action. The factories on this class give
/// the short names of the case tables and return the variant; variant
/// constructors validate and throw [ArgumentError]. Switch over the family
/// exhaustively, with no default branch.
@immutable
sealed class CastingTime {
  const CastingTime();

  /// The lowest amount a [CastingTimeMinutes] or [CastingTimeHours] may
  /// hold ("Longer Casting Times", SRD 5.2.1, p. 105) (FR-029, FR-111).
  static const int minAmount = 1;

  /// Whether [amount] is a valid Minutes or Hours amount: at least
  /// [minAmount] (FR-029, FR-111). The predicate the decoder reuses
  /// instead of repeating the bound.
  static bool isValidAmount(int amount) => amount >= minAmount;

  /// The Magic action (FR-026).
  static CastingTimeMagicAction magicAction() => const CastingTimeMagicAction();

  /// A Bonus Action, with its printed trigger when one follows the comma
  /// ("Reaction and Bonus Action Triggers", p. 105) (FR-028).
  static CastingTimeBonusAction bonusAction([String? trigger]) =>
      trigger == null
      ? CastingTimeBonusAction(null)
      : CastingTimeBonusAction(trigger);

  /// A Reaction, which always carries its printed trigger text — verbatim
  /// after "which you take" (FR-027).
  static CastingTimeReaction reaction(String trigger) =>
      CastingTimeReaction(trigger);

  /// [n] Minutes (FR-029).
  static CastingTimeMinutes minutes(int n) => CastingTimeMinutes(n);

  /// [n] Hours (FR-029).
  static CastingTimeHours hours(int n) => CastingTimeHours(n);
}

/// The Magic action (FR-026).
@immutable
final class CastingTimeMagicAction extends CastingTime {
  /// The single form; the printed "Action" carries no data.
  const CastingTimeMagicAction();

  @override
  bool operator ==(Object other) => other is CastingTimeMagicAction;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'CastingTimeMagicAction()';
}

/// A Bonus Action, optionally with its printed trigger (FR-028).
@immutable
final class CastingTimeBonusAction extends CastingTime {
  /// Creates the Bonus Action with [trigger].
  ///
  /// Throws an [ArgumentError] carrying the name `trigger` and the offending
  /// value when [trigger] is present but empty or whitespace-only (FR-028):
  /// an empty trigger string is not a printed trigger.
  CastingTimeBonusAction(String? trigger)
    : trigger = _validatedTrigger(trigger);

  /// The printed trigger, or null when none follows the comma.
  final String? trigger;

  static String? _validatedTrigger(String? trigger) {
    if (trigger != null && !NamedText.isValidText(trigger)) {
      throw ArgumentError.value(
        trigger,
        'trigger',
        'must contain at least one non-whitespace character',
      );
    }
    return trigger;
  }

  @override
  bool operator ==(Object other) =>
      other is CastingTimeBonusAction && other.trigger == trigger;

  @override
  int get hashCode => Object.hash(CastingTimeBonusAction, trigger);

  @override
  String toString() => trigger == null
      ? 'CastingTimeBonusAction()'
      : 'CastingTimeBonusAction($trigger)';
}

/// A Reaction with its printed trigger (FR-027).
@immutable
final class CastingTimeReaction extends CastingTime {
  /// Creates the Reaction with [trigger].
  ///
  /// Throws an [ArgumentError] carrying the name `trigger` and the offending
  /// value when [trigger] is empty or whitespace-only (FR-027): a Reaction is
  /// always printed with what it is taken in response to.
  CastingTimeReaction(String trigger) : trigger = _validatedTrigger(trigger);

  /// The printed trigger, verbatim after "which you take".
  final String trigger;

  static String _validatedTrigger(String trigger) {
    if (!NamedText.isValidText(trigger)) {
      throw ArgumentError.value(
        trigger,
        'trigger',
        'must contain at least one non-whitespace character',
      );
    }
    return trigger;
  }

  @override
  bool operator ==(Object other) =>
      other is CastingTimeReaction && other.trigger == trigger;

  @override
  int get hashCode => Object.hash(CastingTimeReaction, trigger);

  @override
  String toString() => 'CastingTimeReaction($trigger)';
}

/// A Casting Time of [amount] Minutes (FR-026, FR-029).
@immutable
final class CastingTimeMinutes extends CastingTime {
  /// Creates the Casting Time of [amount] Minutes.
  ///
  /// Throws an [ArgumentError] carrying the name `amount` and the offending
  /// value when [amount] is below [CastingTime.minAmount] (FR-029).
  CastingTimeMinutes(int amount) : amount = _validatedAmount(amount);

  /// The number of Minutes.
  final int amount;

  @override
  bool operator ==(Object other) =>
      other is CastingTimeMinutes && other.amount == amount;

  @override
  int get hashCode => Object.hash(CastingTimeMinutes, amount);

  @override
  String toString() => 'CastingTimeMinutes($amount)';
}

/// A Casting Time of [amount] Hours (FR-026, FR-029).
@immutable
final class CastingTimeHours extends CastingTime {
  /// Creates the Casting Time of [amount] Hours.
  ///
  /// Throws an [ArgumentError] carrying the name `amount` and the offending
  /// value when [amount] is below [CastingTime.minAmount] (FR-029).
  CastingTimeHours(int amount) : amount = _validatedAmount(amount);

  /// The number of Hours.
  final int amount;

  @override
  bool operator ==(Object other) =>
      other is CastingTimeHours && other.amount == amount;

  @override
  int get hashCode => Object.hash(CastingTimeHours, amount);

  @override
  String toString() => 'CastingTimeHours($amount)';
}

int _validatedAmount(int amount) {
  if (!CastingTime.isValidAmount(amount)) {
    throw ArgumentError.value(
      amount,
      'amount',
      'must be at least ${CastingTime.minAmount}',
    );
  }
  return amount;
}

/// One labelled option of a spell with more than one Casting Time, such as
/// Plant Growth's "Overgrowth" and "Enrichment" (SRD 5.2.1, p. 153)
/// (FR-030).
@immutable
final class CastingTimeMode {
  /// Creates the option labelled [label] taking [time].
  ///
  /// Throws an [ArgumentError] carrying the name `label` and the offending
  /// value when [label] is blank (FR-030).
  CastingTimeMode(String label, this.time) : label = _validatedLabel(label);

  /// The printed label, non-blank (FR-030).
  final String label;

  /// The Casting Time the option takes.
  final CastingTime time;

  static String _validatedLabel(String label) {
    if (!NamedText.isValidText(label)) {
      throw ArgumentError.value(
        label,
        'label',
        'must contain at least one non-whitespace character',
      );
    }
    return label;
  }

  @override
  bool operator ==(Object other) =>
      other is CastingTimeMode && other.label == label && other.time == time;

  @override
  int get hashCode => Object.hash(CastingTimeMode, label, time);

  @override
  String toString() => 'CastingTimeMode($label)';
}

/// The Casting Time options of a spell, sealed with exactly the two shapes
/// the label rule allows (FR-030).
///
/// A spell has one Casting Time with no label, or at least
/// [SpellCastingTimes.minModes] labelled options; a single option carrying a
/// label, and a modes list below the minimum, are unrepresentable by type.
/// Switch over the family exhaustively, with no default branch.
@immutable
sealed class SpellCastingTimes {
  const SpellCastingTimes();

  /// The smallest number of labelled options a [SpellCastingTimesModes] may
  /// hold (FR-030, FR-111).
  static const int minModes = 2;
}

/// One Casting Time, with no label (FR-030).
@immutable
final class SpellCastingTimesSingle extends SpellCastingTimes {
  /// Wraps the single [time]. There is no labelled form: a labelled option
  /// exists only when there are two or more.
  const SpellCastingTimesSingle(this.time);

  /// The spell's Casting Time.
  final CastingTime time;

  @override
  bool operator ==(Object other) =>
      other is SpellCastingTimesSingle && other.time == time;

  @override
  int get hashCode => Object.hash(SpellCastingTimesSingle, time);

  @override
  String toString() => 'SpellCastingTimesSingle($time)';
}

/// At least [SpellCastingTimes.minModes] labelled options (FR-030): Plant
/// Growth's two (SRD 5.2.1, p. 153); no other bundled spell has more than
/// one option (FR-033).
@immutable
final class SpellCastingTimesModes extends SpellCastingTimes {
  /// Creates the options from a defensive copy of [modes].
  ///
  /// Throws an [ArgumentError] carrying the name `modes` and the offending
  /// value when [modes] holds fewer than [SpellCastingTimes.minModes]
  /// options (FR-030).
  SpellCastingTimesModes(List<CastingTimeMode> modes)
    : modes = List.unmodifiable(_validated(modes));

  /// The labelled options, in printed order; unmodifiable.
  final List<CastingTimeMode> modes;

  static List<CastingTimeMode> _validated(List<CastingTimeMode> modes) {
    if (modes.length < SpellCastingTimes.minModes) {
      throw ArgumentError.value(
        modes,
        'modes',
        'must hold at least ${SpellCastingTimes.minModes} labelled options',
      );
    }
    return modes;
  }

  @override
  bool operator ==(Object other) =>
      other is SpellCastingTimesModes &&
      const ListEquality<CastingTimeMode>().equals(other.modes, modes);

  @override
  int get hashCode => const ListEquality<CastingTimeMode>().hash(modes);

  @override
  String toString() => 'SpellCastingTimesModes($modes)';
}
