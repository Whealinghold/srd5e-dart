import 'package:meta/meta.dart';

import 'die.dart';

/// Why a [DieRoll] could not be created from a die and a value.
enum DieRollRejection {
  /// The value is below 1 or above the die's number of sides.
  valueOutOfRange,
}

/// One roll of one die: the die and the face it showed.
///
/// A face is a whole number from 1 to the die's sides (a package-design
/// reading of "Roll 1d20", SRD 5.2.1, "D20 Tests", p. 6).
@immutable
final class DieRoll {
  /// Creates a roll of [die] that showed [value].
  ///
  /// Throws an [ArgumentError] carrying the name `value` and the offending
  /// value when [value] is below 1 or above `die.sides`. Use [tryCreate] for
  /// faces entered by a host from physical dice.
  DieRoll(this.die, int value) : value = _validated(die, value);

  const DieRoll._(this.die, this.value);

  /// The die that was rolled.
  final Die die;

  /// The face the die showed, from 1 to `die.sides`.
  final int value;

  /// Creates a roll from an untrusted face without throwing.
  ///
  /// Returns [CreatedDieRoll] exactly when the [DieRoll] constructor would
  /// accept [value], and [RejectedDieRoll] with
  /// [DieRollRejection.valueOutOfRange] otherwise.
  static DieRollCreation tryCreate(Die die, int value) => _fits(die, value)
      ? CreatedDieRoll(DieRoll._(die, value))
      : const RejectedDieRoll(DieRollRejection.valueOutOfRange);

  static bool _fits(Die die, int value) => value >= 1 && value <= die.sides;

  static int _validated(Die die, int value) {
    if (!_fits(die, value)) {
      throw ArgumentError.value(
        value,
        'value',
        'must be from 1 to ${die.sides}',
      );
    }
    return value;
  }

  @override
  bool operator ==(Object other) =>
      other is DieRoll && other.die == die && other.value == value;

  @override
  int get hashCode => Object.hash(die, value);

  /// The debugging form, `d<sides>=<value>`. Not display text.
  @override
  String toString() => '$die=$value';
}

/// The result of [DieRoll.tryCreate]: a created roll or a typed rejection.
@immutable
sealed class DieRollCreation {
  const DieRollCreation();
}

/// [DieRoll.tryCreate] accepted the face.
final class CreatedDieRoll extends DieRollCreation {
  /// Wraps the created [value].
  const CreatedDieRoll(this.value);

  /// The roll that was created.
  final DieRoll value;

  @override
  bool operator ==(Object other) =>
      other is CreatedDieRoll && other.value == value;

  @override
  int get hashCode => Object.hash(CreatedDieRoll, value);

  @override
  String toString() => 'CreatedDieRoll($value)';
}

/// [DieRoll.tryCreate] rejected the face.
final class RejectedDieRoll extends DieRollCreation {
  /// Carries the typed [reason].
  const RejectedDieRoll(this.reason);

  /// Why the roll was rejected.
  final DieRollRejection reason;

  @override
  bool operator ==(Object other) =>
      other is RejectedDieRoll && other.reason == reason;

  @override
  int get hashCode => Object.hash(RejectedDieRoll, reason);

  @override
  String toString() => 'RejectedDieRoll(${reason.name})';
}
