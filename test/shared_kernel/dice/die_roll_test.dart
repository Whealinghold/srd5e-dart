import 'package:srd5e/src/shared_kernel/dice/die.dart';
import 'package:srd5e/src/shared_kernel/dice/die_roll.dart';
import 'package:test/test.dart';

import '../../support/argument_error_matcher.dart';

typedef _ValueCase = ({
  String label,
  String requirement,
  String path,
  Die die,
  int value,
  bool valid,
});

const List<_ValueCase> _values = [
  (
    label: 'the lowest face of a d20',
    requirement:
        'doc/specs/dice-and-rolls.md FR-031 (face range, package design)',
    path: 'unhappy (boundary)',
    die: Die.d20,
    value: 1,
    valid: true,
  ),
  (
    label: 'a middle face of a d20',
    requirement:
        'doc/specs/dice-and-rolls.md FR-031 (SRD 5.2.1, "D20 Tests", p. 6)',
    path: 'happy',
    die: Die.d20,
    value: 11,
    valid: true,
  ),
  (
    label: 'the highest face of a d20',
    requirement:
        'doc/specs/dice-and-rolls.md FR-031 (SRD 5.2.1, "D20 Tests", p. 6)',
    path: 'unhappy (boundary)',
    die: Die.d20,
    value: 20,
    valid: true,
  ),
  (
    label: 'the highest face of a d4',
    requirement:
        'doc/specs/dice-and-rolls.md FR-031 (face range, package design)',
    path: 'unhappy (boundary)',
    die: Die.d4,
    value: 4,
    valid: true,
  ),
  (
    label: 'zero',
    requirement:
        'doc/specs/dice-and-rolls.md FR-032 (a die cannot show a face it does not have)',
    path: 'unhappy (boundary)',
    die: Die.d20,
    value: 0,
    valid: false,
  ),
  (
    label: 'a negative value',
    requirement:
        'doc/specs/dice-and-rolls.md FR-032 (a die cannot show a face it does not have)',
    path: 'unhappy (invalid input)',
    die: Die.d20,
    value: -4,
    valid: false,
  ),
  (
    label: 'one above the highest face of a d20',
    requirement:
        'doc/specs/dice-and-rolls.md FR-032 (a die cannot show a face it does not have)',
    path: 'unhappy (boundary)',
    die: Die.d20,
    value: 21,
    valid: false,
  ),
  (
    label: 'five on a d4',
    requirement:
        'doc/specs/dice-and-rolls.md FR-032 (a die cannot show a face it does not have)',
    path: 'unhappy (boundary)',
    die: Die.d4,
    value: 5,
    valid: false,
  ),
];

void main() {
  /// Requirement: per case - doc/specs/dice-and-rolls.md FR-031 - a DieRoll accepts a
  ///   value from 1 to the die's sides (package design, from "Roll 1d20",
  ///   SRD 5.2.1, p. 6).
  /// Path: per case
  group('DieRoll accepts', () {
    /// Requirement: per case
    /// Path: per case
    for (final c in _values.where((c) => c.valid)) {
      test('${c.label} [${c.path}]', () {
        final roll = DieRoll(c.die, c.value);

        expect(roll.die, c.die);
        expect(roll.value, c.value);
      });
    }
  });

  /// Requirement: per case - doc/specs/dice-and-rolls.md FR-032 and FR-077 - a value the
  ///   die cannot show is a programmer error carrying name and value.
  /// Path: per case
  group('DieRoll rejects', () {
    /// Requirement: per case
    /// Path: per case
    for (final c in _values.where((c) => !c.valid)) {
      test('${c.label} [${c.path}]', () {
        expect(
          () => DieRoll(c.die, c.value),
          throwsArgumentErrorFor('value', c.value),
        );
      });
    }
  });

  /// Requirement: doc/specs/dice-and-rolls.md FR-031 - a DieRoll is a value
  ///   object compared by die and value (package design).
  /// Path: happy
  group('DieRoll equality', () {
    /// Requirement: doc/specs/dice-and-rolls.md FR-031 - equal die and value
    ///   give equal rolls with equal hash codes.
    /// Path: happy
    test('same die and value are equal with equal hash codes', () {
      final first = DieRoll(Die.d8, 5);
      final second = DieRoll(Die.d8, 5);

      expect(identical(first, second), isFalse);
      expect(first, second);
      expect(first.hashCode, second.hashCode);
    });

    /// Requirement: doc/specs/dice-and-rolls.md FR-031 - a different value or
    ///   die makes rolls unequal.
    /// Path: unhappy (boundary)
    test('a different value or die is unequal', () {
      final base = DieRoll(Die.d8, 5);

      expect(base == DieRoll(Die.d8, 6), isFalse);
      expect(base == DieRoll(Die.d10, 5), isFalse);
      const Object notARoll = 5;
      expect(base == notARoll, isFalse);
    });

    /// Requirement: doc/specs/dice-and-rolls.md FR-031 - the debugging form is
    ///   `d<sides>=<value>` (not display text).
    /// Path: happy
    test('toString names the die and the face', () {
      expect(DieRoll(Die.d20, 17).toString(), 'd20=17');
    });
  });

  /// Requirement: per case - doc/specs/dice-and-rolls.md FR-072 - tryCreate returns a
  ///   created roll or a typed rejection for physical dice entered by a host.
  /// Path: per case
  group('DieRoll.tryCreate', () {
    /// Requirement: per case
    /// Path: per case
    for (final c in _values) {
      test('${c.label} [${c.path}]', () {
        final result = DieRoll.tryCreate(c.die, c.value);

        if (c.valid) {
          expect(result, CreatedDieRoll(DieRoll(c.die, c.value)));
        } else {
          expect(
            result,
            const RejectedDieRoll(DieRollRejection.valueOutOfRange),
          );
        }
      });
    }

    /// Requirement: doc/specs/dice-and-rolls.md FR-074 - tryCreate rejects if
    ///   and only if the constructor throws ArgumentError.
    /// Path: unhappy (rule conflict)
    test('rejects exactly the inputs the constructor throws for', () {
      for (final c in _values) {
        final rejected = DieRoll.tryCreate(c.die, c.value) is RejectedDieRoll;
        var thrown = false;
        try {
          DieRoll(c.die, c.value);
        } on ArgumentError {
          thrown = true;
        }

        expect(rejected, thrown, reason: c.label);
      }
    });

    /// Requirement: doc/specs/dice-and-rolls.md FR-075 - the result is sealed
    ///   with final variants carrying the value or the typed reason.
    /// Path: unhappy (invalid input)
    test('the result is switched over exhaustively', () {
      String describe(DieRollCreation creation) => switch (creation) {
        CreatedDieRoll(:final value) => 'created ${value.value}',
        RejectedDieRoll(:final reason) => 'rejected ${reason.name}',
      };

      expect(describe(DieRoll.tryCreate(Die.d6, 6)), 'created 6');
      expect(
        describe(DieRoll.tryCreate(Die.d6, 7)),
        'rejected valueOutOfRange',
      );
    });

    /// Requirement: doc/specs/dice-and-rolls.md FR-072 - the variants compare
    ///   by value.
    /// Path: unhappy (boundary)
    test('variants compare by value', () {
      final created = DieRoll.tryCreate(Die.d6, 3);
      final createdAgain = DieRoll.tryCreate(Die.d6, 3);
      final createdOther = DieRoll.tryCreate(Die.d6, 4);
      final rejected = DieRoll.tryCreate(Die.d6, 0);
      final rejectedAgain = DieRoll.tryCreate(Die.d6, 7);

      expect(created, createdAgain);
      expect(created.hashCode, createdAgain.hashCode);
      expect(created == createdOther, isFalse);
      expect(rejected, rejectedAgain);
      expect(rejected.hashCode, rejectedAgain.hashCode);
      expect(created == rejected, isFalse);
    });
  });

  /// Requirement: doc/specs/dice-and-rolls.md FR-072 and FR-075 - the creation
  ///   variants have a debugging form that names the value or the typed reason.
  /// Path: happy
  test('the creation variants have a debugging form', () {
    expect(DieRoll.tryCreate(Die.d6, 3).toString(), 'CreatedDieRoll(d6=3)');
    expect(
      DieRoll.tryCreate(Die.d6, 7).toString(),
      'RejectedDieRoll(valueOutOfRange)',
    );
  });
}
