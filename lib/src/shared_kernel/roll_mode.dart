import 'dart:math' as math;

import 'roll_circumstance.dart';

/// How a d20 is rolled: with Advantage, with Disadvantage, or with neither.
///
/// [normal] is the SRD's "the roll has neither of them" ("They Don't Stack",
/// SRD 5.2.1, p. 8). The mode is the resolved state of one roll: [resolve]
/// turns the circumstances into a mode, [diceCount] says how many d20s to roll
/// and [select] picks the one that is used. The names are the values of the
/// `srd5e.d20_test.roll_mode` telemetry attribute.
enum RollMode {
  /// Neither Advantage nor Disadvantage: roll one d20.
  normal,

  /// Advantage: roll two d20s and use the higher.
  advantage,

  /// Disadvantage: roll two d20s and use the lower.
  disadvantage;

  /// The lowest face of a d20 ("Rolling 20 or 1", SRD 5.2.1, p. 7).
  static const int _lowestFace = 1;

  /// The highest face of a d20.
  static const int _highestFace = 20;

  /// Resolves [circumstances] to the roll mode of one d20 roll ("Advantage/
  /// Disadvantage", SRD 5.2.1, pp. 7-8).
  ///
  /// * No circumstance resolves to [normal].
  /// * One or more [Advantage] and no [Disadvantage] resolves to [advantage];
  ///   one or more [Disadvantage] and no [Advantage] resolves to
  ///   [disadvantage]. They don't stack, so how many does not matter.
  /// * At least one of each resolves to [normal], however many of each: they
  ///   cancel as a whole, not one for one.
  ///
  /// The order of the circumstances does not matter. [circumstances] is read
  /// once and not altered, so any [Iterable] will do.
  static RollMode resolve(Iterable<RollCircumstance> circumstances) {
    var hasAdvantage = false;
    var hasDisadvantage = false;
    for (final circumstance in circumstances) {
      switch (circumstance) {
        case Advantage():
          hasAdvantage = true;
        case Disadvantage():
          hasDisadvantage = true;
      }
    }
    return switch ((hasAdvantage, hasDisadvantage)) {
      (true, false) => advantage,
      (false, true) => disadvantage,
      (true, true) || (false, false) => normal,
    };
  }

  /// How many d20s this mode rolls: 1 for [normal], 2 for [advantage] and
  /// [disadvantage] ("Roll Two D20s", SRD 5.2.1, p. 8).
  int get diceCount => switch (this) {
    normal => 1,
    advantage || disadvantage => 2,
  };

  /// The d20 number this mode uses out of the [rolled] values, in the order
  /// they were rolled ("D20 Tests", p. 6; "Roll Two D20s", p. 8).
  ///
  /// With [normal] it is the one d20 rolled. With [advantage] it is the higher
  /// of the two, with [disadvantage] the lower; when both are equal it is that
  /// value. The order of the two does not matter.
  ///
  /// This is a pure function of the mode and the values: [rolled] is only read.
  /// It returns the number used, before any modifier; it builds no roll record.
  ///
  /// Throws an [ArgumentError] carrying the name `rolled` and the list passed
  /// in when the count of values differs from [diceCount] or any value is
  /// outside 1 to 20. That is a programmer error: a `DiceRoller` that returns
  /// bad dice is reported upstream, and this is a second line of defence.
  int select(List<int> rolled) {
    if (rolled.length != diceCount || !rolled.every(_isD20Face)) {
      throw ArgumentError.value(
        rolled,
        'rolled',
        'must hold $diceCount d20 value(s), each from $_lowestFace to '
            '$_highestFace',
      );
    }
    return switch (this) {
      normal => rolled[0],
      advantage => math.max(rolled[0], rolled[1]),
      disadvantage => math.min(rolled[0], rolled[1]),
    };
  }

  static bool _isD20Face(int value) =>
      value >= _lowestFace && value <= _highestFace;
}
