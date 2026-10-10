import 'package:srd5e/src/shared_kernel/modifier.dart';
import 'package:test/test.dart';

typedef _SumCase = ({
  String label,
  String requirement,
  String path,
  List<int> inputs,
  int expected,
});

typedef _ApplyCase = ({
  String label,
  String requirement,
  String path,
  int d20,
  List<int> inputs,
  int expected,
});

/// FR-004, FR-005, FR-006, FR-007, FR-036, FR-037: the sum of a collection of modifiers.
const List<_SumCase> _sums = [
  (
    label: 'one bonus',
    requirement:
        'doc/specs/modifiers-and-advantage.md FR-004 (SRD 5.2.1, "D20 Tests", "Add Modifiers", p. 6)',
    path: 'happy',
    inputs: [3],
    expected: 3,
  ),
  (
    label: 'two bonuses',
    requirement:
        'doc/specs/modifiers-and-advantage.md FR-004 (SRD 5.2.1, "D20 Tests", "Add Modifiers", p. 6)',
    path: 'happy',
    inputs: [2, 3],
    expected: 5,
  ),
  (
    label: 'one penalty',
    requirement:
        'FR-001 and FR-004 (SRD 5.2.1, "D20 Tests", "Add Modifiers", p. 6)',
    path: 'happy',
    inputs: [-2],
    expected: -2,
  ),
  (
    label: 'bonus and penalty, net positive',
    requirement:
        'FR-006 (SRD 5.2.1, "D20 Tests", "Circumstantial Bonuses and '
        'Penalties", p. 6)',
    path: 'unhappy (rule interaction)',
    inputs: [3, -2],
    expected: 1,
  ),
  (
    label: 'bonus and penalty, net zero',
    requirement:
        'FR-006 (SRD 5.2.1, "D20 Tests", "Circumstantial Bonuses and '
        'Penalties", p. 6)',
    path: 'unhappy (rule interaction)',
    inputs: [2, -2],
    expected: 0,
  ),
  (
    label: 'bonus and penalty, net negative',
    requirement:
        'FR-006 (SRD 5.2.1, "D20 Tests", "Circumstantial Bonuses and '
        'Penalties", p. 6)',
    path: 'unhappy (rule interaction)',
    inputs: [1, -4],
    expected: -3,
  ),
  (
    label: 'zero among others',
    requirement:
        'doc/specs/modifiers-and-advantage.md FR-037 (SRD 5.2.1, "Ability Modifiers" table, +0 row, p. 6)',
    path: 'unhappy (empty and minimal)',
    inputs: [0, 2],
    expected: 2,
  ),
  (
    label: 'reordered, penalty last',
    requirement:
        'doc/specs/modifiers-and-advantage.md FR-007 (derived from SRD 5.2.1, "D20 Tests", p. 6)',
    path: 'unhappy (rule interaction)',
    inputs: [-4, 1],
    expected: -3,
  ),
  (
    label: 'reordered, penalty first',
    requirement:
        'doc/specs/modifiers-and-advantage.md FR-007 (derived from SRD 5.2.1, "D20 Tests", p. 6)',
    path: 'unhappy (rule interaction)',
    inputs: [1, -4],
    expected: -3,
  ),
  (
    label: 'large sum',
    requirement:
        'doc/specs/modifiers-and-advantage.md FR-036 (package design: no bound or wrap)',
    path: 'unhappy (boundary)',
    inputs: [1000000, 1000000],
    expected: 2000000,
  ),
  (
    label: 'large negative sum',
    requirement:
        'doc/specs/modifiers-and-advantage.md FR-036 (package design: no bound or wrap)',
    path: 'unhappy (boundary)',
    inputs: [-1000000, -1000000],
    expected: -2000000,
  ),
];

/// FR-005: the sum of nothing.
const _SumCase _emptySum = (
  label: 'empty',
  requirement:
      'FR-005 (derived from SRD 5.2.1, "D20 Tests", p. 6: no modifiers)',
  path: 'unhappy (empty and minimal)',
  inputs: [],
  expected: 0,
);

/// FR-008, FR-005, FR-036: applying modifiers to a d20 number.
const List<_ApplyCase> _applications = [
  (
    label: 'd20 1, penalty',
    requirement:
        'doc/specs/modifiers-and-advantage.md FR-008 (SRD 5.2.1, "D20 Tests", p. 6: no clamping stated)',
    path: 'unhappy (boundary)',
    d20: 1,
    inputs: [-5],
    expected: -4,
  ),
  (
    label: 'd20 20, bonus',
    requirement:
        'doc/specs/modifiers-and-advantage.md FR-008 (SRD 5.2.1, "D20 Tests", p. 6: no clamping stated)',
    path: 'unhappy (boundary)',
    d20: 20,
    inputs: [10],
    expected: 30,
  ),
  (
    label: 'd20 10, no modifiers',
    requirement:
        'doc/specs/modifiers-and-advantage.md FR-005 and FR-008 (SRD 5.2.1, "D20 Tests", p. 6)',
    path: 'unhappy (empty and minimal)',
    d20: 10,
    inputs: [],
    expected: 10,
  ),
  (
    label: 'applyTo below 1',
    requirement:
        'doc/specs/modifiers-and-advantage.md FR-008 (applyTo accepts any int; no 1 to 20 check)',
    path: 'unhappy (boundary)',
    d20: 0,
    inputs: [2],
    expected: 2,
  ),
  (
    label: 'applyTo above 20',
    requirement:
        'doc/specs/modifiers-and-advantage.md FR-008 (applyTo accepts any int; no 1 to 20 check)',
    path: 'unhappy (boundary)',
    d20: 25,
    inputs: [-3],
    expected: 22,
  ),
  (
    label: 'extreme total',
    requirement:
        'doc/specs/modifiers-and-advantage.md FR-036 (package design: exact integer arithmetic)',
    path: 'unhappy (boundary)',
    d20: 20,
    inputs: [1000000],
    expected: 1000020,
  ),
  (
    label: 'extreme negative total',
    requirement:
        'doc/specs/modifiers-and-advantage.md FR-036 (package design: exact integer arithmetic)',
    path: 'unhappy (boundary)',
    d20: 1,
    inputs: [-1000000],
    expected: -999999,
  ),
];

/// Builds a modifier at run time, so each call returns a distinct object.
Modifier _make(int value) => Modifier(value);

List<Modifier> _modifiers(List<int> values) => [
  for (final v in values) Modifier(v),
];

void main() {
  /// Requirement: doc/specs/modifiers-and-advantage.md FR-001 - a Modifier
  ///   holds one whole number: bonus, zero and penalty are all valid (derived
  ///   from SRD 5.2.1, "D20 Tests", "Add Modifiers", p. 6).
  /// Path: happy
  group('Modifier value', () {
    /// Requirement: doc/specs/modifiers-and-advantage.md FR-001 - a bonus is a
    ///   positive value (SRD 5.2.1, "D20 Tests", p. 6).
    /// Path: happy
    test('a bonus exposes its positive value', () {
      expect(const Modifier(3).value, 3);
    });

    /// Requirement: doc/specs/modifiers-and-advantage.md FR-001 - zero is a
    ///   valid modifier (SRD 5.2.1, "Ability Modifiers" table, +0 row, p. 6).
    /// Path: unhappy (empty and minimal)
    test('zero exposes the value zero', () {
      expect(const Modifier(0).value, 0);
    });

    /// Requirement: doc/specs/modifiers-and-advantage.md FR-001 - a penalty is
    ///   a negative value (SRD 5.2.1, "D20 Tests", p. 6).
    /// Path: happy
    test('a penalty exposes its negative value', () {
      expect(const Modifier(-2).value, -2);
    });

    /// Requirement: doc/specs/modifiers-and-advantage.md FR-001 and FR-036 -
    ///   the constructor takes any int with no bound and never throws.
    /// Path: unhappy (boundary)
    test('the constructor accepts very large and very small integers', () {
      expect(const Modifier(1000000000000).value, 1000000000000);
      expect(const Modifier(-1000000000000).value, -1000000000000);
    });
  });

  /// Requirement: doc/specs/modifiers-and-advantage.md FR-003 - Modifier.zero
  ///   is the +0 modifier (SRD 5.2.1, "Ability Modifiers" table, +0 row, p. 6).
  /// Path: unhappy (empty and minimal)
  test('Modifier.zero has value 0 and equals Modifier(0)', () {
    expect(Modifier.zero.value, 0);
    expect(Modifier.zero, const Modifier(0));
  });

  /// Requirement: doc/specs/modifiers-and-advantage.md FR-002 - a value object
  ///   compared by its value (package design, architecture.md §3).
  /// Path: happy
  group('Modifier equality', () {
    /// Requirement: doc/specs/modifiers-and-advantage.md FR-002 - the same
    ///   value gives equal modifiers with equal hash codes.
    /// Path: happy
    test('same value is equal with equal hash codes', () {
      // Built at run time so the instances are distinct objects.
      final a = _make(4);
      final b = _make(4);

      expect(identical(a, b), isFalse);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    /// Requirement: doc/specs/modifiers-and-advantage.md FR-002 - different
    ///   values are not equal, including opposite signs.
    /// Path: unhappy (boundary)
    test('different values are not equal', () {
      expect(const Modifier(4) == const Modifier(5), isFalse);
      expect(const Modifier(4) == const Modifier(-4), isFalse);
      expect(const Modifier(0) == const Modifier(1), isFalse);
    });

    /// Requirement: doc/specs/modifiers-and-advantage.md FR-002 - a Modifier is
    ///   not equal to a bare int of the same value (no kind confusion).
    /// Path: unhappy (invalid input)
    test('is not equal to an int', () {
      const Object plain = 4;

      expect(const Modifier(4) == plain, isFalse);
    });

    /// Requirement: none - pins the debugging form of a Modifier (toString is
    ///   not display text, architecture.md §6).
    /// Path: happy
    test('toString names the type and the value', () {
      expect(const Modifier(-2).toString(), 'Modifier(-2)');
    });
  });

  /// Requirement: per case - doc/specs/modifiers-and-advantage.md FR-004, FR-005, FR-006,
  ///   FR-007, FR-036 and FR-037 - modifiers add together by signed addition (SRD
  ///   5.2.1, "D20 Tests", "Add Modifiers", p. 6).
  /// Path: per case
  group('Modifier.sum', () {
    /// Requirement: per case
    /// Path: per case
    for (final c in _sums) {
      test('${c.label} [${c.path}] (${c.requirement})', () {
        final result = Modifier.sum(_modifiers(c.inputs));

        expect(result, Modifier(c.expected));
      });
    }

    /// Requirement: doc/specs/modifiers-and-advantage.md FR-005 - the sum of an
    ///   empty collection is Modifier.zero (derived from SRD 5.2.1, "D20
    ///   Tests", p. 6).
    /// Path: unhappy (empty and minimal)
    test('${_emptySum.label} [${_emptySum.path}]', () {
      final result = Modifier.sum(const <Modifier>[]);

      expect(result, Modifier.zero);
    });

    /// Requirement: doc/specs/modifiers-and-advantage.md FR-004 - sum accepts
    ///   any Iterable, not only a List.
    /// Path: happy
    test('sums a lazy iterable', () {
      final result = Modifier.sum(
        [1, 2, 3, 4].where((v) => v.isEven).map(Modifier.new),
      );

      expect(result, const Modifier(6));
    });

    /// Requirement: doc/specs/modifiers-and-advantage.md FR-007 - the sum does
    ///   not depend on the order of the modifiers.
    /// Path: unhappy (rule interaction)
    test('a collection and its reverse sum to the same modifier', () {
      final forward = _modifiers([5, -2, 7, -11, 0, 3]);

      final a = Modifier.sum(forward);
      final b = Modifier.sum(forward.reversed);

      expect(a, const Modifier(2));
      expect(b, a);
    });

    /// Requirement: doc/specs/modifiers-and-advantage.md FR-036 and FR-037 -
    ///   adding Modifier.zero to a sum leaves the value unchanged.
    /// Path: unhappy (empty and minimal)
    test('adding Modifier.zero to the collection changes nothing', () {
      final others = _modifiers([4, -1]);

      final without = Modifier.sum(others);
      final withZero = Modifier.sum([Modifier.zero, ...others]);

      expect(withZero, without);
      expect(withZero, const Modifier(3));
    });

    /// Requirement: doc/specs/modifiers-and-advantage.md FR-009 - summing does
    ///   not alter the input collection or its elements.
    /// Path: unhappy (immutability)
    test('leaves a mutable input list and its elements unchanged', () {
      final input = _modifiers([3, -2, 5]);
      final copy = List<Modifier>.of(input);

      Modifier.sum(input);

      expect(input, copy);
      expect([for (final m in input) m.value], [3, -2, 5]);
    });

    /// Requirement: doc/specs/modifiers-and-advantage.md FR-009 - summing an
    ///   unmodifiable input works (the input is only read).
    /// Path: unhappy (immutability)
    test('sums an unmodifiable list', () {
      final input = List<Modifier>.unmodifiable(_modifiers([1, 2]));

      expect(Modifier.sum(input), const Modifier(3));
    });
  });

  /// Requirement: per case - doc/specs/modifiers-and-advantage.md FR-004, FR-005, FR-006,
  ///   FR-007, FR-036 and FR-037 - Modifier + Modifier gives the arithmetic sum (SRD
  ///   5.2.1, "D20 Tests", "Add Modifiers", p. 6).
  /// Path: per case
  group('Modifier +', () {
    /// Requirement: per case
    /// Path: per case
    for (final c in _sums) {
      test('${c.label} [${c.path}] (${c.requirement})', () {
        final result = _modifiers(c.inputs).reduce((a, b) => a + b);

        expect(result, Modifier(c.expected));
      });
    }

    /// Requirement: doc/specs/modifiers-and-advantage.md FR-037 - adding
    ///   Modifier.zero leaves a modifier unchanged, on either side.
    /// Path: unhappy (empty and minimal)
    test('adding Modifier.zero on either side changes nothing', () {
      const m = Modifier(-6);

      expect(m + Modifier.zero, m);
      expect(Modifier.zero + m, m);
    });

    /// Requirement: doc/specs/modifiers-and-advantage.md FR-009 - adding does
    ///   not alter either operand.
    /// Path: unhappy (immutability)
    test('leaves both operands unchanged', () {
      const a = Modifier(2);
      const b = Modifier(3);

      final sum = a + b;

      expect(sum, const Modifier(5));
      expect(a, const Modifier(2));
      expect(b, const Modifier(3));
    });
  });

  /// Requirement: per case - doc/specs/modifiers-and-advantage.md FR-008 and FR-036 -
  ///   applying a modifier adds its value to the d20 number with no clamping
  ///   (derived from SRD 5.2.1, "D20 Tests", "Compare the Total to a Target
  ///   Number", p. 6).
  /// Path: per case
  group('Modifier.applyTo', () {
    /// Requirement: per case
    /// Path: per case
    for (final c in _applications) {
      test('${c.label} [${c.path}] (${c.requirement})', () {
        final total = Modifier.sum(_modifiers(c.inputs)).applyTo(c.d20);

        expect(total, c.expected);
      });
    }

    /// Requirement: doc/specs/modifiers-and-advantage.md FR-008 - applyTo of a
    ///   single modifier returns number plus value, as an int.
    /// Path: happy
    test('adds the value to the number', () {
      final Object total = const Modifier(4).applyTo(13);

      expect(total, isA<int>());
      expect(total, 17);
    });

    /// Requirement: doc/specs/modifiers-and-advantage.md FR-008 - a bonus and
    ///   a penalty of the same size land on different totals (guards a sign
    ///   mix-up).
    /// Path: unhappy (boundary)
    test('a penalty subtracts and a bonus adds', () {
      expect(const Modifier(5).applyTo(10), 15);
      expect(const Modifier(-5).applyTo(10), 5);
    });
  });
}
