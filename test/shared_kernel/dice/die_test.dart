import 'package:srd5e/src/shared_kernel/dice/die.dart';
import 'package:test/test.dart';

import '../../support/argument_error_matcher.dart';

typedef _SidesCase = ({
  String label,
  String requirement,
  String path,
  int sides,
});

/// The largest integer that is exact on every platform.
const int _safeInteger = 9007199254740991;

const List<({String label, Die die, int sides})> _constants = [
  (label: 'd3', die: Die.d3, sides: 3),
  (label: 'd4', die: Die.d4, sides: 4),
  (label: 'd6', die: Die.d6, sides: 6),
  (label: 'd8', die: Die.d8, sides: 8),
  (label: 'd10', die: Die.d10, sides: 10),
  (label: 'd12', die: Die.d12, sides: 12),
  (label: 'd20', die: Die.d20, sides: 20),
  (label: 'd100', die: Die.d100, sides: 100),
];

const List<_SidesCase> _accepted = [
  (
    label: 'two sides is the smallest die',
    requirement: 'doc/specs/dice-and-rolls.md FR-002 (package design)',
    path: 'unhappy (boundary)',
    sides: 2,
  ),
  (
    label: 'seven sides is a die the SRD does not print',
    requirement: 'doc/specs/dice-and-rolls.md FR-002 (package design)',
    path: 'happy',
    sides: 7,
  ),
  (
    label: 'thirty sides is a die the SRD does not print',
    requirement: 'doc/specs/dice-and-rolls.md FR-002 (package design)',
    path: 'happy',
    sides: 30,
  ),
  (
    label: 'one thousand sides is the largest die',
    requirement: 'doc/specs/dice-and-rolls.md FR-002 (package design)',
    path: 'unhappy (boundary)',
    sides: 1000,
  ),
];

const List<_SidesCase> _rejected = [
  (
    label: 'one side',
    requirement:
        'doc/specs/dice-and-rolls.md FR-003 (a one-sided die cannot be rolled)',
    path: 'unhappy (boundary)',
    sides: 1,
  ),
  (
    label: 'zero sides',
    requirement:
        'doc/specs/dice-and-rolls.md FR-003 (a one-sided die cannot be rolled)',
    path: 'unhappy (invalid input)',
    sides: 0,
  ),
  (
    label: 'negative sides',
    requirement:
        'doc/specs/dice-and-rolls.md FR-003 (a one-sided die cannot be rolled)',
    path: 'unhappy (invalid input)',
    sides: -6,
  ),
  (
    label: 'the smallest safe integer',
    requirement:
        'doc/specs/dice-and-rolls.md FR-003 / FR-070 (integer extreme)',
    path: 'unhappy (boundary)',
    sides: -_safeInteger,
  ),
  (
    label: 'one thousand and one sides',
    requirement: 'doc/specs/dice-and-rolls.md FR-004 (keeps arithmetic safe)',
    path: 'unhappy (boundary)',
    sides: 1001,
  ),
  (
    label: 'the largest safe integer',
    requirement:
        'doc/specs/dice-and-rolls.md FR-004 / FR-070 (integer extreme)',
    path: 'unhappy (boundary)',
    sides: _safeInteger,
  ),
];

void main() {
  /// Requirement: doc/specs/dice-and-rolls.md FR-001 - the named dice have the
  ///   printed number of sides (SRD 5.2.1, "Hit Points", p. 255; "Trinkets",
  ///   p. 26).
  /// Path: happy
  group('named dice', () {
    /// Requirement: per case
    /// Path: per case
    for (final c in _constants) {
      test('${c.label} has ${c.sides} sides [happy]', () {
        expect(c.die.sides, c.sides);
      });
    }
  });

  /// Requirement: doc/specs/dice-and-rolls.md FR-002 - any integer from 2 to
  ///   `maxSides` is a die (package design).
  /// Path: happy
  group('Die accepts', () {
    /// Requirement: per case
    /// Path: per case
    for (final c in _accepted) {
      test('${c.label} [${c.path}]', () {
        expect(Die(c.sides).sides, c.sides);
      });
    }

    /// Requirement: doc/specs/dice-and-rolls.md FR-002 and FR-004 - the limits
    ///   are published as constants (package design).
    /// Path: happy
    test('the limits are 2 and 1000', () {
      expect(Die.minSides, 2);
      expect(Die.maxSides, 1000);
    });
  });

  /// Requirement: doc/specs/dice-and-rolls.md FR-003, FR-004 and FR-077 - an
  ///   invalid number of sides is a programmer error carrying name and value.
  /// Path: unhappy (invalid input)
  group('Die rejects', () {
    /// Requirement: per case
    /// Path: per case
    for (final c in _rejected) {
      test('${c.label} [${c.path}]', () {
        expect(() => Die(c.sides), throwsArgumentErrorFor('sides', c.sides));
      });
    }
  });

  /// Requirement: doc/specs/dice-and-rolls.md FR-005 - a value object compared
  ///   by its sides (package design).
  /// Path: happy
  group('Die equality', () {
    /// Requirement: doc/specs/dice-and-rolls.md FR-005 - equal sides give equal
    ///   dice with equal hash codes, including a constant and a constructed die.
    /// Path: happy
    test('same sides are equal with equal hash codes', () {
      expect(Die(20), Die.d20);
      expect(Die(20).hashCode, Die.d20.hashCode);
      expect(Die(7) == Die(7), isTrue);
    });

    /// Requirement: doc/specs/dice-and-rolls.md FR-005 - different sides are
    ///   unequal.
    /// Path: unhappy (boundary)
    test('different sides are unequal', () {
      expect(Die(6) == Die(7), isFalse);
      expect(Die.d4 == Die.d6, isFalse);
      const Object notADie = 20;
      expect(Die.d20 == notADie, isFalse);
    });

    /// Requirement: doc/specs/dice-and-rolls.md FR-030 - the debugging form of
    ///   a die is `d<sides>` (not display text).
    /// Path: happy
    test('toString is d followed by the sides', () {
      expect(Die.d8.toString(), 'd8');
    });
  });

  /// Requirement: doc/specs/dice-and-rolls.md FR-070 - tryCreate returns a
  ///   created die or a typed rejection for untrusted numbers.
  /// Path: happy
  group('Die.tryCreate', () {
    /// Requirement: per case
    /// Path: per case
    for (final c in _accepted) {
      test('creates a die: ${c.label} [${c.path}]', () {
        final result = Die.tryCreate(c.sides);

        expect(result, CreatedDie(Die(c.sides)));
      });
    }

    /// Requirement: per case
    /// Path: per case
    for (final c in _rejected) {
      test('rejects ${c.label} [${c.path}]', () {
        final result = Die.tryCreate(c.sides);

        expect(result, const RejectedDie(DieRejection.sidesOutOfRange));
      });
    }

    /// Requirement: doc/specs/dice-and-rolls.md FR-074 - tryCreate rejects if
    ///   and only if the constructor throws ArgumentError.
    /// Path: unhappy (rule conflict)
    test('rejects exactly the inputs the constructor throws for', () {
      final sides = [..._accepted, ..._rejected].map((c) => c.sides);

      final rejectedByTryCreate = {
        for (final s in sides)
          if (Die.tryCreate(s) is RejectedDie) s,
      };
      final thrownByConstructor = <int>{};
      for (final s in sides) {
        try {
          Die(s);
        } on ArgumentError {
          thrownByConstructor.add(s);
        }
      }

      expect(rejectedByTryCreate, thrownByConstructor);
      expect(rejectedByTryCreate, isNotEmpty);
    });

    /// Requirement: doc/specs/dice-and-rolls.md FR-075 - the creation result is
    ///   sealed with final variants that carry the value or the typed reason.
    /// Path: unhappy (invalid input)
    test('the result is switched over exhaustively', () {
      String describe(DieCreation creation) => switch (creation) {
        CreatedDie(:final value) => 'created d${value.sides}',
        RejectedDie(:final reason) => 'rejected ${reason.name}',
      };

      expect(describe(Die.tryCreate(12)), 'created d12');
      expect(describe(Die.tryCreate(1)), 'rejected sidesOutOfRange');
    });

    /// Requirement: doc/specs/dice-and-rolls.md FR-070 - the variants compare
    ///   by value.
    /// Path: unhappy (boundary)
    test('variants compare by value', () {
      // Built at run time so the instances are distinct objects.
      final created = Die.tryCreate(6);
      final createdAgain = Die.tryCreate(6);
      final createdOther = Die.tryCreate(8);
      final rejected = Die.tryCreate(1);
      final rejectedAgain = Die.tryCreate(0);

      expect(identical(created, createdAgain), isFalse);
      expect(created, createdAgain);
      expect(created.hashCode, createdAgain.hashCode);
      expect(created == createdOther, isFalse);
      expect(identical(rejected, rejectedAgain), isFalse);
      expect(rejected, rejectedAgain);
      expect(rejected.hashCode, rejectedAgain.hashCode);
      expect(created == rejected, isFalse);
    });
  });

  /// Requirement: doc/specs/dice-and-rolls.md FR-070 and FR-075 - the creation
  ///   variants have a debugging form that names the value or the typed reason
  ///   (not display text; it makes failing test output readable).
  /// Path: happy
  test('the creation variants have a debugging form', () {
    expect(Die.tryCreate(6).toString(), 'CreatedDie(d6)');
    expect(Die.tryCreate(1).toString(), 'RejectedDie(sidesOutOfRange)');
  });
}
