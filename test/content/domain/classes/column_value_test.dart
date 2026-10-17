import 'package:srd5e/src/content/domain/classes/column_value.dart';
import 'package:srd5e/src/shared_kernel/dice/die.dart';
import 'package:test/test.dart';

import '../../../support/argument_error_matcher.dart';

void main() {
  /// Requirement: doc/specs/content-classes.md FR-040 - a column value is a
  ///   sealed `ColumnValue`: `ColumnCount` (n at least 0), `ColumnDice`
  ///   (count at least 1, sides a valid `Die`), `ColumnBonus` (0 or more),
  ///   `ColumnFeetBonus` (feet) or `ColumnNone` (the em dash, allowed for
  ///   every kind) (SRD 5.2.1, "Monk Features", p. 50, "Cleric Features",
  ///   p. 36).
  /// Path: happy
  group('Cases CV: column values', () {
    /// Requirement: per case
    /// Path: per case
    for (final c in [
      (
        label: 'count',
        requirement:
            'doc/specs/content-classes.md FR-040 - count 2 is ColumnCount(2)',
        path: 'happy',
        build: () => ColumnCount(2),
        expected: ColumnCount(2),
        throwsFor: null,
      ),
      (
        label: 'count zero',
        requirement:
            'doc/specs/content-classes.md FR-040 - count 0 is accepted',
        path: 'unhappy (boundary)',
        build: () => ColumnCount(0),
        expected: ColumnCount(0),
        throwsFor: null,
      ),
      (
        label: 'count negative',
        requirement:
            'doc/specs/content-classes.md FR-040 - count -1 is rejected',
        path: 'unhappy (boundary)',
        build: () => ColumnCount(-1),
        expected: null,
        throwsFor: throwsArgumentErrorFor('value', -1),
      ),
      (
        label: 'dice',
        requirement:
            'doc/specs/content-classes.md FR-040 - count 1 sides 6 is '
            'ColumnDice(1, 6)',
        path: 'happy',
        build: () => ColumnDice(1, 6),
        expected: ColumnDice(1, 6),
        throwsFor: null,
      ),
      (
        label: 'dice zero count',
        requirement:
            'doc/specs/content-classes.md FR-040 - count 0 sides 6 is '
            'rejected',
        path: 'unhappy (boundary)',
        build: () => ColumnDice(0, 6),
        expected: null,
        throwsFor: throwsArgumentErrorFor('count', 0),
      ),
      (
        label: 'dice one side',
        requirement:
            'doc/specs/content-classes.md FR-040 - count 1 sides 1 is '
            'rejected: one side is not a valid Die',
        path: 'unhappy (boundary)',
        build: () => ColumnDice(1, 1),
        expected: null,
        throwsFor: throwsArgumentErrorFor('sides', 1),
      ),
      (
        label: 'bonus',
        requirement:
            'doc/specs/content-classes.md FR-040 - bonus 2 is ColumnBonus(2)',
        path: 'happy',
        build: () => ColumnBonus(2),
        expected: ColumnBonus(2),
        throwsFor: null,
      ),
      (
        label: 'feet bonus',
        requirement:
            'doc/specs/content-classes.md FR-040 - feetBonus 10 is '
            'ColumnFeetBonus(10)',
        path: 'happy',
        build: () => const ColumnFeetBonus(10),
        expected: const ColumnFeetBonus(10),
        throwsFor: null,
      ),
      (
        label: 'none, count',
        requirement:
            'doc/specs/content-classes.md FR-040 - the em dash under a '
            'count kind is ColumnNone',
        path: 'unhappy (empty case)',
        build: () => const ColumnNone(),
        expected: const ColumnNone(),
        throwsFor: null,
      ),
      (
        label: 'none, dice',
        requirement:
            'doc/specs/content-classes.md FR-040 - the em dash under a '
            'dice kind is ColumnNone',
        path: 'unhappy (empty case)',
        build: () => const ColumnNone(),
        expected: const ColumnNone(),
        throwsFor: null,
      ),
    ]) {
      test('${c.label} [${c.path}]', () {
        if (c.throwsFor != null) {
          expect(c.build, c.throwsFor);
        } else {
          expect(c.build(), c.expected);
        }
      });
    }
  });

  /// Requirement: doc/specs/content-classes.md FR-040 - `ColumnNone` is
  ///   allowed for every kind, every instance of it equals every other, and
  ///   the family is exhaustive in a `switch` without a default.
  /// Path: happy
  test('ColumnNone equals its instances and the family switches', () {
    const none = ColumnNone();
    expect(none, equals(const ColumnNone()));
    expect(none.hashCode, const ColumnNone().hashCode);

    String describe(ColumnValue value) => switch (value) {
      ColumnCount() => 'count',
      ColumnDice() => 'dice',
      ColumnBonus() => 'bonus',
      ColumnFeetBonus() => 'feet',
      ColumnNone() => 'none',
    };
    expect(describe(ColumnCount(1)), 'count');
    expect(describe(ColumnDice(1, 6)), 'dice');
    expect(describe(ColumnBonus(0)), 'bonus');
    expect(describe(const ColumnFeetBonus(5)), 'feet');
    expect(describe(const ColumnNone()), 'none');

    expect(ColumnCount(3).toString(), 'ColumnCount(3)');
    final dice = ColumnDice(2, 6);
    expect(dice.hashCode, ColumnDice(2, 6).hashCode);
    expect(dice.toString(), 'ColumnDice(2, d6)');
    expect(ColumnBonus(1).hashCode, ColumnBonus(1).hashCode);
    expect(ColumnBonus(1).toString(), 'ColumnBonus(1)');
    expect(
      const ColumnFeetBonus(5).hashCode,
      const ColumnFeetBonus(5).hashCode,
    );
    expect(const ColumnFeetBonus(5).toString(), 'ColumnFeetBonus(5)');
    expect(none.toString(), 'ColumnNone');
  });

  /// Requirement: doc/specs/content-classes.md FR-040, FR-008 - the limits
  ///   are public constants and predicates; a negative bonus is rejected; a
  ///   `ColumnDice` compares by count and die.
  /// Path: unhappy (boundary)
  test('limits and predicates agree with the constructors', () {
    expect(ColumnCount.minValue, 0);
    expect(ColumnCount.isValid(0), isTrue);
    expect(ColumnCount.isValid(-1), isFalse);
    expect(ColumnDice.minCount, 1);
    expect(ColumnDice.isValidCount(1), isTrue);
    expect(ColumnDice.isValidCount(0), isFalse);
    expect(ColumnBonus.minValue, 0);
    expect(ColumnBonus.isValid(0), isTrue);
    expect(ColumnBonus.isValid(-1), isFalse);
    expect(() => ColumnBonus(-1), throwsArgumentErrorFor('value', -1));

    final dice = ColumnDice(2, 10);
    expect(dice, equals(ColumnDice(2, 10)));
    expect(dice, isNot(equals(ColumnDice(2, 8))));
    expect(dice.sides, Die.d10);
  });

  /// Requirement: doc/specs/content-classes.md FR-040 - `ColumnBonus` may
  ///   be 0; `ColumnFeetBonus` states no range, so no value is excluded.
  /// Path: happy
  test('a zero bonus and a feet bonus construct', () {
    expect(ColumnBonus(0).value, 0);
    expect(const ColumnFeetBonus(0).value, 0);
  });
}
