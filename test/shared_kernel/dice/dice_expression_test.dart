import 'package:srd5e/src/shared_kernel/dice/dice_expression.dart';
import 'package:srd5e/src/shared_kernel/dice/die.dart';
import 'package:test/test.dart';

import '../../support/argument_error_matcher.dart';

typedef _StatsCase = ({
  String label,
  String requirement,
  String path,
  int count,
  Die die,
  int modifier,
  int minimum,
  int maximum,
  int average,
});

/// Case table for FR-010, FR-011 and FR-012 (section 4.2 of the spec).
// Not const: a die the SRD does not print is built by the validating
// constructor.
final List<_StatsCase> _stats = [
  (
    label: 'one d20',
    requirement: 'SRD 5.2.1, "Hit Points", p. 255 (d20 averages 10 1/2); p. 5',
    path: 'happy',
    count: 1,
    die: Die.d20,
    modifier: 0,
    minimum: 1,
    maximum: 20,
    average: 10,
  ),
  (
    label: 'one d4 plus 2',
    requirement: 'SRD 5.2.1, "Damage Notation", p. 257 prints "4 (1d4 + 2)"',
    path: 'happy',
    count: 1,
    die: Die.d4,
    modifier: 2,
    minimum: 3,
    maximum: 6,
    average: 4,
  ),
  (
    label: 'two d8 plus 2',
    requirement:
        'SRD 5.2.1, "Hit Points", p. 255 prints "2d8 + 2 (average 11)"',
    path: 'happy',
    count: 2,
    die: Die.d8,
    modifier: 2,
    minimum: 4,
    maximum: 18,
    average: 11,
  ),
  (
    label: 'two d4',
    requirement: 'SRD 5.2.1, "Hit Points", p. 255 (d4 averages 2 1/2)',
    path: 'happy',
    count: 2,
    die: Die.d4,
    modifier: 0,
    minimum: 2,
    maximum: 8,
    average: 5,
  ),
  (
    label: 'one d6',
    requirement: 'SRD 5.2.1, "Hit Points", p. 255 (d6 averages 3 1/2)',
    path: 'happy',
    count: 1,
    die: Die.d6,
    modifier: 0,
    minimum: 1,
    maximum: 6,
    average: 3,
  ),
  (
    label: 'four d6',
    requirement: 'arithmetic; SRD 5.2.1, "Rogue Features", p. 62 prints 4d6',
    path: 'happy',
    count: 4,
    die: Die.d6,
    modifier: 0,
    minimum: 4,
    maximum: 24,
    average: 14,
  ),
  (
    label: 'one d100',
    requirement: 'SRD 5.2.1, "Trinkets", p. 26 prints the 1d100 table',
    path: 'happy',
    count: 1,
    die: Die.d100,
    modifier: 0,
    minimum: 1,
    maximum: 100,
    average: 50,
  ),
  (
    label: 'negative modifier (printed)',
    requirement:
        'SRD 5.2.1, p. 302 prints "HP 7 (3d6 - 3)"; rounding down, p. 5',
    path: 'happy',
    count: 3,
    die: Die.d6,
    modifier: -3,
    minimum: 0,
    maximum: 15,
    average: 7,
  ),
  (
    label: 'negative modifier, negative average',
    requirement: 'package design; rounding towards negative infinity, p. 5',
    path: 'unhappy (boundary)',
    count: 1,
    die: Die.d4,
    modifier: -5,
    minimum: -4,
    maximum: -1,
    average: -3,
  ),
  (
    label: 'largest allowed',
    requirement: 'package design (limits)',
    path: 'unhappy (boundary)',
    count: 1000,
    die: Die(1000),
    modifier: 1000000,
    minimum: 1001000,
    maximum: 2000000,
    average: 1500500,
  ),
  (
    label: 'smallest allowed',
    requirement: 'package design (limits)',
    path: 'unhappy (boundary)',
    count: 1,
    die: Die(2),
    modifier: -1000000,
    minimum: -999999,
    maximum: -999998,
    average: -999999,
  ),
];

typedef _NotationCase = ({
  String label,
  String requirement,
  String path,
  int count,
  int sides,
  int modifier,
  String notation,
});

const List<_NotationCase> _notations = [
  (
    label: 'count is always present',
    requirement: 'doc/specs/dice-and-rolls.md FR-030 (canonical machine form)',
    path: 'happy',
    count: 1,
    sides: 20,
    modifier: 0,
    notation: '1d20',
  ),
  (
    label: 'positive modifier has an ASCII plus and no spaces',
    requirement: 'doc/specs/dice-and-rolls.md FR-030 (canonical machine form)',
    path: 'happy',
    count: 2,
    sides: 8,
    modifier: 2,
    notation: '2d8+2',
  ),
  (
    label: 'negative modifier has an ASCII minus and no spaces',
    requirement: 'doc/specs/dice-and-rolls.md FR-030 (canonical machine form)',
    path: 'happy',
    count: 1,
    sides: 4,
    modifier: -5,
    notation: '1d4-5',
  ),
  (
    label: 'a zero modifier is omitted',
    requirement: 'doc/specs/dice-and-rolls.md FR-030 (canonical machine form)',
    path: 'unhappy (boundary)',
    count: 4,
    sides: 6,
    modifier: 0,
    notation: '4d6',
  ),
  (
    label: 'every limit',
    requirement: 'doc/specs/dice-and-rolls.md FR-030 (canonical machine form)',
    path: 'unhappy (boundary)',
    count: 1000,
    sides: 1000,
    modifier: 1000000,
    notation: '1000d1000+1000000',
  ),
  (
    label: 'the smallest modifier',
    requirement: 'doc/specs/dice-and-rolls.md FR-030 (canonical machine form)',
    path: 'unhappy (boundary)',
    count: 1,
    sides: 2,
    modifier: -1000000,
    notation: '1d2-1000000',
  ),
];

typedef _CreateCase = ({
  String label,
  String requirement,
  String path,
  int count,
  int sides,
  int modifier,
  DiceExpressionRejection? rejection,
});

/// Argument sets for tryCreate, FR-071 and FR-074. A null rejection means the
/// constructor accepts the arguments.
const List<_CreateCase> _creations = [
  (
    label: 'typical expression',
    requirement: 'doc/specs/dice-and-rolls.md FR-071 (accepted)',
    path: 'happy',
    count: 2,
    sides: 8,
    modifier: 2,
    rejection: null,
  ),
  (
    label: 'count of one',
    requirement: 'doc/specs/dice-and-rolls.md FR-006, FR-071 (accepted)',
    path: 'unhappy (boundary)',
    count: 1,
    sides: 20,
    modifier: 0,
    rejection: null,
  ),
  (
    label: 'count of 1000',
    requirement: 'doc/specs/dice-and-rolls.md FR-008, FR-071 (accepted)',
    path: 'unhappy (boundary)',
    count: 1000,
    sides: 6,
    modifier: 0,
    rejection: null,
  ),
  (
    label: 'modifier of 1000000',
    requirement: 'doc/specs/dice-and-rolls.md FR-009, FR-071 (accepted)',
    path: 'unhappy (boundary)',
    count: 1,
    sides: 6,
    modifier: 1000000,
    rejection: null,
  ),
  (
    label: 'modifier of -1000000',
    requirement: 'doc/specs/dice-and-rolls.md FR-009, FR-071 (accepted)',
    path: 'unhappy (boundary)',
    count: 1,
    sides: 6,
    modifier: -1000000,
    rejection: null,
  ),
  (
    label: 'count of zero',
    requirement: 'doc/specs/dice-and-rolls.md FR-007, FR-071 (rejected)',
    path: 'unhappy (boundary)',
    count: 0,
    sides: 6,
    modifier: 0,
    rejection: DiceExpressionRejection.countOutOfRange,
  ),
  (
    label: 'negative count',
    requirement: 'doc/specs/dice-and-rolls.md FR-007, FR-071 (rejected)',
    path: 'unhappy (invalid input)',
    count: -1,
    sides: 6,
    modifier: 0,
    rejection: DiceExpressionRejection.countOutOfRange,
  ),
  (
    label: 'count of 1001',
    requirement: 'doc/specs/dice-and-rolls.md FR-008, FR-071 (rejected)',
    path: 'unhappy (boundary)',
    count: 1001,
    sides: 6,
    modifier: 0,
    rejection: DiceExpressionRejection.countOutOfRange,
  ),
  (
    label: 'modifier of 1000001',
    requirement: 'doc/specs/dice-and-rolls.md FR-009, FR-071 (rejected)',
    path: 'unhappy (boundary)',
    count: 1,
    sides: 6,
    modifier: 1000001,
    rejection: DiceExpressionRejection.modifierOutOfRange,
  ),
  (
    label: 'modifier of -1000001',
    requirement: 'doc/specs/dice-and-rolls.md FR-009, FR-071 (rejected)',
    path: 'unhappy (boundary)',
    count: 1,
    sides: 6,
    modifier: -1000001,
    rejection: DiceExpressionRejection.modifierOutOfRange,
  ),
  (
    label: 'count is checked before modifier',
    requirement:
        'doc/specs/dice-and-rolls.md FR-071 (reasons are checked in argument order)',
    path: 'unhappy (rule conflict)',
    count: 0,
    sides: 6,
    modifier: 1000001,
    rejection: DiceExpressionRejection.countOutOfRange,
  ),
];

DiceExpression _build(_CreateCase c) =>
    DiceExpression(c.count, Die(c.sides), modifier: c.modifier);

void main() {
  /// Requirement: doc/specs/dice-and-rolls.md FR-006 - an expression is a
  ///   count of identical dice plus a flat modifier (SRD 5.2.1, "D20 Tests",
  ///   p. 6; "Hit Points", p. 255).
  /// Path: happy
  group('DiceExpression construction', () {
    /// Requirement: doc/specs/dice-and-rolls.md FR-006 - 1d20 is valid and
    ///   exposes count, die and modifier unchanged.
    /// Path: happy
    test('1d20 exposes its parts', () {
      final expression = DiceExpression(1, Die.d20);

      expect(expression.count, 1);
      expect(expression.die, Die.d20);
      expect(expression.modifier, 0);
    });

    /// Requirement: doc/specs/dice-and-rolls.md FR-006 - 2d8 + 2 is valid and
    ///   exposes count, die and modifier unchanged.
    /// Path: happy
    test('2d8 + 2 exposes its parts', () {
      final expression = DiceExpression(2, Die.d8, modifier: 2);

      expect(expression.count, 2);
      expect(expression.die, Die.d8);
      expect(expression.modifier, 2);
    });

    /// Requirement: doc/specs/dice-and-rolls.md FR-006, FR-008 and FR-009 - the
    ///   limits are published as constants (package design).
    /// Path: happy
    test('the limits are 1000, 1000 and 1000000', () {
      expect(DiceExpression.maxCount, 1000);
      expect(DiceExpression.maxModifier, 1000000);
      expect(Die.maxSides, 1000);
    });

    /// Requirement: doc/specs/dice-and-rolls.md FR-006 and FR-008 - the count
    ///   bounds 1 and 1000 are accepted.
    /// Path: unhappy (boundary)
    test('counts of 1 and 1000 are accepted', () {
      expect(DiceExpression(1, Die.d6).count, 1);
      expect(DiceExpression(1000, Die.d6).count, 1000);
    });

    /// Requirement: doc/specs/dice-and-rolls.md FR-007 and FR-077 - a count
    ///   below 1 is a programmer error carrying name and value.
    /// Path: unhappy (boundary)
    test('a count of zero or less is rejected', () {
      expect(
        () => DiceExpression(0, Die.d6),
        throwsArgumentErrorFor('count', 0),
      );
      expect(
        () => DiceExpression(-3, Die.d6),
        throwsArgumentErrorFor('count', -3),
      );
    });

    /// Requirement: doc/specs/dice-and-rolls.md FR-008 and FR-077 - a count
    ///   above 1000 is rejected.
    /// Path: unhappy (boundary)
    test('a count of 1001 is rejected', () {
      expect(
        () => DiceExpression(1001, Die.d6),
        throwsArgumentErrorFor('count', 1001),
      );
    });

    /// Requirement: doc/specs/dice-and-rolls.md FR-009 - modifiers of exactly
    ///   plus and minus 1000000 are accepted.
    /// Path: unhappy (boundary)
    test('modifiers of 1000000 and -1000000 are accepted', () {
      expect(DiceExpression(1, Die.d6, modifier: 1000000).modifier, 1000000);
      expect(DiceExpression(1, Die.d6, modifier: -1000000).modifier, -1000000);
    });

    /// Requirement: doc/specs/dice-and-rolls.md FR-009 and FR-077 - a modifier
    ///   whose magnitude exceeds 1000000 is rejected.
    /// Path: unhappy (boundary)
    test('modifiers of 1000001 and -1000001 are rejected', () {
      expect(
        () => DiceExpression(1, Die.d6, modifier: 1000001),
        throwsArgumentErrorFor('modifier', 1000001),
      );
      expect(
        () => DiceExpression(1, Die.d6, modifier: -1000001),
        throwsArgumentErrorFor('modifier', -1000001),
      );
    });

    /// Requirement: doc/specs/dice-and-rolls.md FR-071 - when both are invalid
    ///   the count is reported first.
    /// Path: unhappy (rule conflict)
    test('an invalid count is reported before an invalid modifier', () {
      expect(
        () => DiceExpression(0, Die.d6, modifier: 1000001),
        throwsArgumentErrorFor('count', 0),
      );
    });
  });

  /// Requirement: per case - doc/specs/dice-and-rolls.md FR-010, FR-011 and
  ///   FR-012 (each row asserts minimum, maximum and the rounded-down average).
  /// Path: per case
  group('minimum, maximum and average', () {
    for (final c in _stats) {
      test('${c.label} [${c.path}]', () {
        final expression = DiceExpression(c.count, c.die, modifier: c.modifier);

        expect(expression.minimum, c.minimum, reason: 'minimum');
        expect(expression.maximum, c.maximum, reason: 'maximum');
        expect(expression.average, c.average, reason: 'average');
      });
    }
  });

  /// Requirement: doc/specs/dice-and-rolls.md FR-013 - a value object compared
  ///   by count, die and modifier.
  /// Path: happy
  group('DiceExpression equality', () {
    /// Requirement: doc/specs/dice-and-rolls.md FR-013 - equal fields give
    ///   equal expressions with equal hash codes.
    /// Path: happy
    test('equal fields are equal with equal hash codes', () {
      final first = DiceExpression(2, Die.d8, modifier: 2);
      final second = DiceExpression(2, Die.d8, modifier: 2);

      expect(identical(first, second), isFalse);
      expect(first, second);
      expect(first.hashCode, second.hashCode);
    });

    /// Requirement: doc/specs/dice-and-rolls.md FR-013 - any differing field
    ///   makes two expressions unequal.
    /// Path: unhappy (boundary)
    test('a differing count, die or modifier makes them unequal', () {
      final base = DiceExpression(2, Die.d8, modifier: 2);

      expect(base == DiceExpression(3, Die.d8, modifier: 2), isFalse);
      expect(base == DiceExpression(2, Die.d6, modifier: 2), isFalse);
      expect(base == DiceExpression(2, Die.d8, modifier: 3), isFalse);
      const Object notAnExpression = '2d8+2';
      expect(base == notAnExpression, isFalse);
    });
  });

  /// Requirement: doc/specs/dice-and-rolls.md FR-014 - doubling the dice for a
  ///   Critical Hit doubles the count only (SRD 5.2.1, "Critical Hits", p. 16).
  /// Path: happy
  group('doubleDice', () {
    /// Requirement: doc/specs/dice-and-rolls.md FR-014 - 1d4 gives 2d4.
    /// Path: happy
    test('1d4 becomes 2d4', () {
      expect(DiceExpression(1, Die.d4).doubleDice(), DiceExpression(2, Die.d4));
    });

    /// Requirement: doc/specs/dice-and-rolls.md FR-014 - the modifier is kept
    ///   as it is ("added as normal"): 1d4 + 3 gives 2d4 + 3.
    /// Path: happy
    test('1d4 + 3 becomes 2d4 + 3', () {
      expect(
        DiceExpression(1, Die.d4, modifier: 3).doubleDice(),
        DiceExpression(2, Die.d4, modifier: 3),
      );
    });

    /// Requirement: doc/specs/dice-and-rolls.md FR-015 and FR-069 - a count of
    ///   500 doubles to 1000, the largest allowed.
    /// Path: unhappy (boundary)
    test('a count of 500 doubles to 1000', () {
      final expression = DiceExpression(500, Die.d6);

      expect(expression.canDoubleDice, isTrue);
      expect(expression.doubleDice().count, 1000);
    });

    /// Requirement: doc/specs/dice-and-rolls.md FR-015, FR-069 and FR-077 - a
    ///   count of 501 cannot double; the error names the expression's count.
    /// Path: unhappy (boundary)
    test('a count of 501 is rejected with the expression count', () {
      final expression = DiceExpression(501, Die.d6);

      expect(expression.canDoubleDice, isFalse);
      expect(expression.doubleDice, throwsArgumentErrorFor('count', 501));
    });

    /// Requirement: doc/specs/dice-and-rolls.md FR-069 - canDoubleDice is true
    ///   exactly when count * 2 is at most 1000.
    /// Path: unhappy (boundary)
    test('canDoubleDice is true at 1 and 500, false at 501 and 1000', () {
      expect(DiceExpression(1, Die.d6).canDoubleDice, isTrue);
      expect(DiceExpression(500, Die.d6).canDoubleDice, isTrue);
      expect(DiceExpression(501, Die.d6).canDoubleDice, isFalse);
      expect(DiceExpression(1000, Die.d6).canDoubleDice, isFalse);
    });

    /// Requirement: doc/specs/dice-and-rolls.md FR-016 - doubling does not
    ///   alter the expression it is called on.
    /// Path: unhappy (immutability)
    test('the original expression is unchanged', () {
      final original = DiceExpression(2, Die.d8, modifier: 2);

      final doubled = original.doubleDice();

      expect(doubled, DiceExpression(4, Die.d8, modifier: 2));
      expect(original, DiceExpression(2, Die.d8, modifier: 2));
      expect(identical(original, doubled), isFalse);
    });
  });

  /// Requirement: per case - doc/specs/dice-and-rolls.md FR-030 - notation is the
  ///   canonical machine form (package design).
  /// Path: per case
  group('notation', () {
    /// Requirement: per case
    /// Path: per case
    for (final c in _notations) {
      test('${c.label}: ${c.notation} [${c.path}]', () {
        final expression = DiceExpression(
          c.count,
          Die(c.sides),
          modifier: c.modifier,
        );

        expect(expression.notation, c.notation);
        expect(expression.toString(), c.notation);
      });
    }
  });

  /// Requirement: per case - doc/specs/dice-and-rolls.md FR-071, FR-074 and FR-075 -
  ///   tryCreate agrees with the constructor and carries only a typed reason.
  /// Path: per case
  group('DiceExpression.tryCreate', () {
    /// Requirement: per case
    /// Path: per case
    for (final c in _creations) {
      test('${c.label} [${c.path}]', () {
        final result = DiceExpression.tryCreate(
          c.count,
          Die(c.sides),
          modifier: c.modifier,
        );

        final reason = c.rejection;
        if (reason == null) {
          expect(result, CreatedDiceExpression(_build(c)));
        } else {
          expect(result, RejectedDiceExpressionInput(reason));
        }
      });
    }

    /// Requirement: doc/specs/dice-and-rolls.md FR-074 - tryCreate rejects if
    ///   and only if the constructor throws ArgumentError.
    /// Path: unhappy (rule conflict)
    test('rejects exactly the argument sets the constructor throws for', () {
      for (final c in _creations) {
        final rejected =
            DiceExpression.tryCreate(
                  c.count,
                  Die(c.sides),
                  modifier: c.modifier,
                )
                is RejectedDiceExpressionInput;
        var thrown = false;
        try {
          _build(c);
        } on ArgumentError {
          thrown = true;
        }

        expect(rejected, thrown, reason: c.label);
      }
    });

    /// Requirement: doc/specs/dice-and-rolls.md FR-071 - the reason is only
    ///   ever count or modifier out of range, never empty, malformed or sides.
    /// Path: unhappy (invalid input)
    test('the result is switched over exhaustively', () {
      String describe(DiceExpressionCreation creation) => switch (creation) {
        CreatedDiceExpression(:final value) => 'created ${value.notation}',
        RejectedDiceExpressionInput(:final reason) => 'rejected ${reason.name}',
      };

      expect(describe(DiceExpression.tryCreate(2, Die.d6)), 'created 2d6');
      expect(
        describe(DiceExpression.tryCreate(0, Die.d6)),
        'rejected countOutOfRange',
      );
    });

    /// Requirement: doc/specs/dice-and-rolls.md FR-071 - the variants compare
    ///   by value.
    /// Path: unhappy (boundary)
    test('variants compare by value', () {
      final created = DiceExpression.tryCreate(2, Die.d6);
      final createdAgain = DiceExpression.tryCreate(2, Die.d6);
      final createdOther = DiceExpression.tryCreate(3, Die.d6);
      final rejected = DiceExpression.tryCreate(0, Die.d6);
      final rejectedAgain = DiceExpression.tryCreate(-1, Die.d6);
      final rejectedOther = DiceExpression.tryCreate(
        1,
        Die.d6,
        modifier: 1000001,
      );

      expect(created, createdAgain);
      expect(created.hashCode, createdAgain.hashCode);
      expect(created == createdOther, isFalse);
      expect(rejected, rejectedAgain);
      expect(rejected.hashCode, rejectedAgain.hashCode);
      expect(rejected == rejectedOther, isFalse);
      expect(created == rejected, isFalse);
    });
  });

  /// Requirement: doc/specs/dice-and-rolls.md FR-071 and FR-075 - the creation
  ///   variants have a debugging form that names the value or the typed reason.
  /// Path: happy
  test('the creation variants have a debugging form', () {
    expect(
      DiceExpression.tryCreate(2, Die.d6).toString(),
      'CreatedDiceExpression(2d6)',
    );
    expect(
      DiceExpression.tryCreate(0, Die.d6).toString(),
      'RejectedDiceExpressionInput(countOutOfRange)',
    );
  });

  /// Requirement: doc/specs/dice-and-rolls.md FR-075 - the parse variants have
  ///   a debugging form that names the value or the typed reason.
  /// Path: happy
  test('the parse variants have a debugging form', () {
    expect(
      DiceExpression.tryParse('2d8 + 2').toString(),
      'ParsedDiceExpression(2d8+2)',
    );
    expect(
      DiceExpression.tryParse('2x').toString(),
      'RejectedDiceExpression(malformed)',
    );
  });
}
