import 'package:srd5e/src/d20_test/domain/d20_roll.dart';
import 'package:srd5e/src/d20_test/domain/reroll_decision.dart';
import 'package:srd5e/src/shared_kernel/roll_mode.dart';
import 'package:test/test.dart';

/// The operation a reroll-table case performs on its roll.
sealed class _Operation {
  const _Operation();
}

/// Constructs the roll and does nothing else.
final class _Construct extends _Operation {
  const _Construct();
}

/// Constructs the roll from a fresh copy of the case's list, then mutates
/// that source list (the caller's list changed after construction).
final class _MutateSource extends _Operation {
  const _MutateSource();
}

/// `replaceDie(index, value)`.
final class _Replace extends _Operation {
  const _Replace(this.index, this.value);

  final int index;
  final int value;
}

/// `replaceDie` twice, in order (the caller enforces the SRD one-die limit).
final class _ReplaceTwice extends _Operation {
  const _ReplaceTwice(
    this.firstIndex,
    this.firstValue,
    this.secondIndex,
    this.secondValue,
  );

  final int firstIndex;
  final int firstValue;
  final int secondIndex;
  final int secondValue;
}

/// `applyReroll(RerollDie(dieIndex), newValue: newValue)`.
final class _Reroll extends _Operation {
  const _Reroll(this.dieIndex, this.newValue);

  final int dieIndex;
  final int? newValue;
}

/// `applyReroll(KeepRoll(), newValue: newValue)`.
final class _Keep extends _Operation {
  const _Keep(this.newValue);

  final int? newValue;
}

/// What a reroll-table case expects to happen.
sealed class _Expectation {
  const _Expectation();
}

/// The resulting roll holds exactly these dice, natural and kept index (and
/// the roll the operation started from is unchanged).
final class _Holds extends _Expectation {
  const _Holds(this.dice, this.natural, this.keptIndex);

  final List<int> dice;
  final int natural;
  final int keptIndex;
}

/// The operation throws an ArgumentError with this name and invalidValue.
final class _Rejects extends _Expectation {
  const _Rejects(this.argumentName, this.invalidValue);

  final String argumentName;
  final Object? invalidValue;
}

typedef _RerollCase = ({
  String label,
  String requirement,
  String path,
  RollMode mode,
  List<int> dice,
  _Operation operation,
  _Expectation expectation,
});

/// The 29-row reroll and replace table of `doc/specs/d20-tests.md` section
/// 4.2, in the order written there.
const List<_RerollCase> _rerollCases = [
  (
    label: 'replace the higher die, advantage',
    requirement:
        'doc/specs/d20-tests.md FR-012 and FR-013 (SRD 5.2.1, "Interactions '
        'with Rerolls", p. 8)',
    path: 'happy',
    mode: RollMode.advantage,
    dice: [18, 3],
    operation: _Replace(0, 2),
    expectation: _Holds([2, 3], 3, 1),
  ),
  (
    label: 'replace the lower die, advantage',
    requirement:
        'doc/specs/d20-tests.md FR-012, FR-013 and FR-058 (SRD 5.2.1, '
        '"Interactions with Rerolls", p. 8)',
    path: 'happy',
    mode: RollMode.advantage,
    dice: [18, 3],
    operation: _Replace(1, 19),
    expectation: _Holds([18, 19], 19, 1),
  ),
  (
    label: 'replace the unused die, no change to natural',
    requirement:
        'doc/specs/d20-tests.md FR-012 and FR-013 (SRD 5.2.1, "Interactions '
        'with Rerolls", p. 8, "only one die, not both")',
    path: 'unhappy (rule interaction)',
    mode: RollMode.advantage,
    dice: [18, 3],
    operation: _Replace(1, 5),
    expectation: _Holds([18, 5], 18, 0),
  ),
  (
    label: 'replace under disadvantage',
    requirement:
        'doc/specs/d20-tests.md FR-012 (SRD 5.2.1, "Interactions with '
        'Rerolls", p. 8)',
    path: 'unhappy (rule interaction)',
    mode: RollMode.disadvantage,
    dice: [18, 3],
    operation: _Replace(1, 20),
    expectation: _Holds([18, 20], 18, 0),
  ),
  (
    label: 'replace the single die',
    requirement:
        'doc/specs/d20-tests.md FR-012 (SRD 5.2.1, "Interactions with '
        'Rerolls", p. 8)',
    path: 'happy',
    mode: RollMode.normal,
    dice: [7],
    operation: _Replace(0, 20),
    expectation: _Holds([20], 20, 0),
  ),
  (
    label: 'replacement to equal dice',
    requirement:
        'doc/specs/d20-tests.md FR-012 and FR-058 (SRD 5.2.1, "Interactions '
        'with Rerolls", "Roll Two D20s", p. 8)',
    path: 'unhappy (boundary)',
    mode: RollMode.advantage,
    dice: [18, 3],
    operation: _Replace(0, 3),
    expectation: _Holds([3, 3], 3, 0),
  ),
  (
    label: 'replacement to the minimum',
    requirement:
        'doc/specs/d20-tests.md FR-012 and FR-014 (SRD 5.2.1, "D20 Tests", '
        '"Roll 1d20", p. 6)',
    path: 'unhappy (boundary)',
    mode: RollMode.normal,
    dice: [20],
    operation: _Replace(0, 1),
    expectation: _Holds([1], 1, 0),
  ),
  (
    label: 'replacement to the maximum',
    requirement:
        'doc/specs/d20-tests.md FR-012 and FR-014 (SRD 5.2.1, "D20 Tests", '
        '"Roll 1d20", p. 6)',
    path: 'unhappy (boundary)',
    mode: RollMode.normal,
    dice: [1],
    operation: _Replace(0, 20),
    expectation: _Holds([20], 20, 0),
  ),
  (
    label: 'replacement twice (caller enforces the SRD limit)',
    requirement:
        'doc/specs/d20-tests.md FR-067 and FR-012 (SRD 5.2.1, "Interactions '
        'with Rerolls", p. 8)',
    path: 'unhappy (state errors)',
    mode: RollMode.advantage,
    dice: [18, 3],
    operation: _ReplaceTwice(0, 2, 1, 9),
    expectation: _Holds([2, 9], 9, 1),
  ),
  (
    label: 'source list mutated after construction',
    requirement: 'doc/specs/d20-tests.md FR-068 (doc/rules/architecture.md §3)',
    path: 'unhappy (immutability)',
    mode: RollMode.advantage,
    dice: [18, 3],
    operation: _MutateSource(),
    expectation: _Holds([18, 3], 18, 0),
  ),
  (
    label: 'applyReroll leaves the original',
    requirement:
        'doc/specs/d20-tests.md FR-015 and FR-059 (SRD 5.2.1, "Interactions '
        'with Rerolls", p. 8)',
    path: 'unhappy (immutability)',
    mode: RollMode.advantage,
    dice: [18, 3],
    operation: _Reroll(0, 2),
    expectation: _Holds([2, 3], 3, 1),
  ),
  (
    label: 'index equal to length',
    requirement: 'doc/specs/d20-tests.md FR-014 (doc/rules/testing.md §4)',
    path: 'unhappy (invalid input)',
    mode: RollMode.advantage,
    dice: [18, 3],
    operation: _Replace(2, 5),
    expectation: _Rejects('index', 2),
  ),
  (
    label: 'negative index',
    requirement: 'doc/specs/d20-tests.md FR-014 (doc/rules/testing.md §4)',
    path: 'unhappy (invalid input)',
    mode: RollMode.advantage,
    dice: [18, 3],
    operation: _Replace(-1, 5),
    expectation: _Rejects('index', -1),
  ),
  (
    label: 'index 1 under normal',
    requirement: 'doc/specs/d20-tests.md FR-014 (doc/rules/testing.md §4)',
    path: 'unhappy (invalid input)',
    mode: RollMode.normal,
    dice: [7],
    operation: _Replace(1, 5),
    expectation: _Rejects('index', 1),
  ),
  (
    label: 'value 0',
    requirement:
        'doc/specs/d20-tests.md FR-009 and FR-014 (SRD 5.2.1, "D20 Tests", '
        '"Roll 1d20", p. 6)',
    path: 'unhappy (boundary)',
    mode: RollMode.normal,
    dice: [7],
    operation: _Replace(0, 0),
    expectation: _Rejects('value', 0),
  ),
  (
    label: 'value 21',
    requirement:
        'doc/specs/d20-tests.md FR-009 and FR-014 (SRD 5.2.1, "D20 Tests", '
        '"Roll 1d20", p. 6)',
    path: 'unhappy (boundary)',
    mode: RollMode.normal,
    dice: [7],
    operation: _Replace(0, 21),
    expectation: _Rejects('value', 21),
  ),
  (
    label: 'reroll lower than before is kept',
    requirement:
        'doc/specs/d20-tests.md FR-059 (SRD 5.2.1, "Heroic Inspiration", '
        'p. 8)',
    path: 'unhappy (rule interaction)',
    mode: RollMode.normal,
    dice: [15],
    operation: _Reroll(0, 2),
    expectation: _Holds([2], 2, 0),
  ),
  (
    label: 'keep the roll',
    requirement:
        'doc/specs/d20-tests.md FR-059 (SRD 5.2.1, "Interactions with '
        'Rerolls", p. 8)',
    path: 'happy',
    mode: RollMode.advantage,
    dice: [18, 3],
    operation: _Keep(null),
    expectation: _Holds([18, 3], 18, 0),
  ),
  (
    label: 'keep with a new value',
    requirement:
        'doc/specs/d20-tests.md FR-059 (SRD 5.2.1, "Interactions with '
        'Rerolls", p. 8)',
    path: 'unhappy (invalid input)',
    mode: RollMode.advantage,
    dice: [18, 3],
    operation: _Keep(5),
    expectation: _Rejects('newValue', 5),
  ),
  (
    label: 'reroll without a new value',
    requirement:
        'doc/specs/d20-tests.md FR-059 (SRD 5.2.1, "Interactions with '
        'Rerolls", p. 8)',
    path: 'unhappy (invalid input)',
    mode: RollMode.advantage,
    dice: [18, 3],
    operation: _Reroll(0, null),
    expectation: _Rejects('newValue', null),
  ),
  (
    label: 'wrong die count for the mode',
    requirement:
        'doc/specs/d20-tests.md FR-010 (SRD 5.2.1, "Roll Two D20s", "They '
        'Don\'t Stack", p. 8)',
    path: 'unhappy (invalid input)',
    mode: RollMode.advantage,
    dice: [18],
    operation: _Construct(),
    expectation: _Rejects('dice', [18]),
  ),
  (
    label: 'three dice',
    requirement:
        'doc/specs/d20-tests.md FR-010 (SRD 5.2.1, "Roll Two D20s", "They '
        'Don\'t Stack", p. 8)',
    path: 'unhappy (invalid input)',
    mode: RollMode.advantage,
    dice: [1, 2, 3],
    operation: _Construct(),
    expectation: _Rejects('dice', [1, 2, 3]),
  ),
  (
    label: 'equal dice',
    requirement:
        'doc/specs/d20-tests.md FR-011, FR-055 and FR-058 (SRD 5.2.1, "Roll '
        'Two D20s", p. 8)',
    path: 'unhappy (boundary)',
    mode: RollMode.advantage,
    dice: [9, 9],
    operation: _Construct(),
    expectation: _Holds([9, 9], 9, 0),
  ),
  (
    label: 'construct with a die of 0',
    requirement:
        'doc/specs/d20-tests.md FR-009 (SRD 5.2.1, "D20 Tests", "Roll 1d20", '
        'p. 6)',
    path: 'unhappy (boundary)',
    mode: RollMode.advantage,
    dice: [0, 5],
    operation: _Construct(),
    expectation: _Rejects('dice', [0, 5]),
  ),
  (
    label: 'construct with a die of 21',
    requirement:
        'doc/specs/d20-tests.md FR-009 (SRD 5.2.1, "D20 Tests", "Roll 1d20", '
        'p. 6)',
    path: 'unhappy (boundary)',
    mode: RollMode.advantage,
    dice: [5, 21],
    operation: _Construct(),
    expectation: _Rejects('dice', [5, 21]),
  ),
  (
    label: 'construct with a negative die',
    requirement:
        'doc/specs/d20-tests.md FR-009 (SRD 5.2.1, "D20 Tests", "Roll 1d20", '
        'p. 6)',
    path: 'unhappy (invalid input)',
    mode: RollMode.normal,
    dice: [-3],
    operation: _Construct(),
    expectation: _Rejects('dice', [-3]),
  ),
  (
    label: 'normal with two dice',
    requirement:
        'doc/specs/d20-tests.md FR-010 (SRD 5.2.1, "Roll Two D20s", "They '
        'Don\'t Stack", p. 8)',
    path: 'unhappy (invalid input)',
    mode: RollMode.normal,
    dice: [7, 8],
    operation: _Construct(),
    expectation: _Rejects('dice', [7, 8]),
  ),
  (
    label: 'no dice under advantage',
    requirement:
        'doc/specs/d20-tests.md FR-010 (SRD 5.2.1, "Roll Two D20s", "They '
        'Don\'t Stack", p. 8)',
    path: 'unhappy (empty and minimal)',
    mode: RollMode.advantage,
    dice: [],
    operation: _Construct(),
    expectation: _Rejects('dice', []),
  ),
  (
    label: 'normal with one die',
    requirement:
        'doc/specs/d20-tests.md FR-011 (SRD 5.2.1, "D20 Tests", "Roll 1d20", '
        'p. 6)',
    path: 'happy',
    mode: RollMode.normal,
    dice: [7],
    operation: _Construct(),
    expectation: _Holds([7], 7, 0),
  ),
];

/// The roll the case constructs and the roll its operation returns.
(D20Roll, D20Roll) _performed(RollMode mode, List<int> dice, _Operation op) =>
    switch (op) {
      _Construct() => _constructed(mode, dice),
      _MutateSource() => _constructedFromMutatedSource(mode, dice),
      _Replace(:final index, :final value) => _replaced(
        mode,
        dice,
        index,
        value,
      ),
      _ReplaceTwice(
        :final firstIndex,
        :final firstValue,
        :final secondIndex,
        :final secondValue,
      ) =>
        _replacedTwice(
          mode,
          dice,
          firstIndex,
          firstValue,
          secondIndex,
          secondValue,
        ),
      _Reroll(:final dieIndex, :final newValue) => _rerolled(
        mode,
        dice,
        dieIndex,
        newValue,
      ),
      _Keep(:final newValue) => _kept(mode, dice, newValue),
    };

(D20Roll, D20Roll) _constructed(RollMode mode, List<int> dice) {
  final roll = D20Roll(mode: mode, dice: dice);
  return (roll, roll);
}

(D20Roll, D20Roll) _constructedFromMutatedSource(
  RollMode mode,
  List<int> dice,
) {
  final source = [...dice];
  final roll = D20Roll(mode: mode, dice: source);
  source[0] = 1;
  return (roll, roll);
}

(D20Roll, D20Roll) _replaced(
  RollMode mode,
  List<int> dice,
  int index,
  int value,
) {
  final original = D20Roll(mode: mode, dice: dice);
  return (original, original.replaceDie(index, value));
}

(D20Roll, D20Roll) _replacedTwice(
  RollMode mode,
  List<int> dice,
  int firstIndex,
  int firstValue,
  int secondIndex,
  int secondValue,
) {
  final original = D20Roll(mode: mode, dice: dice);
  final once = original.replaceDie(firstIndex, firstValue);
  return (original, once.replaceDie(secondIndex, secondValue));
}

(D20Roll, D20Roll) _rerolled(
  RollMode mode,
  List<int> dice,
  int dieIndex,
  int? newValue,
) {
  final original = D20Roll(mode: mode, dice: dice);
  return (
    original,
    original.applyReroll(RerollDie(dieIndex), newValue: newValue),
  );
}

(D20Roll, D20Roll) _kept(RollMode mode, List<int> dice, int? newValue) {
  final original = D20Roll(mode: mode, dice: dice);
  return (original, original.applyReroll(const KeepRoll(), newValue: newValue));
}

void main() {
  /// Requirement: per case - the 29-row reroll and replace table of
  ///   doc/specs/d20-tests.md section 4.2; each row cites its own ids and
  ///   path.
  /// Path: per case
  group('D20Roll reroll and replace table', () {
    for (final c in _rerollCases) {
      test('${c.label} [${c.path}] (${c.requirement})', () {
        final expectation = c.expectation;
        switch (expectation) {
          case _Holds(:final dice, :final natural, :final keptIndex):
            final (original, result) = _performed(c.mode, c.dice, c.operation);
            expect(result.dice, dice);
            expect(result.natural, natural);
            expect(result.keptIndex, keptIndex);
            expect(original, D20Roll(mode: c.mode, dice: c.dice));
          case _Rejects(:final argumentName, :final invalidValue):
            // The exact runtime type is pinned: the guards throw ArgumentError
            // itself, never a subtype such as RangeError, so a mutant that
            // lets an invalid index through to the list assignment (whose
            // RangeError carries the same name and invalidValue) still fails.
            expect(
              () => _performed(c.mode, c.dice, c.operation),
              throwsA(
                isA<ArgumentError>()
                    .having((e) => e.runtimeType, 'runtimeType', ArgumentError)
                    .having((e) => e.name, 'name', argumentName)
                    .having(
                      (e) => e.invalidValue,
                      'invalidValue',
                      invalidValue,
                    ),
              ),
            );
        }
      });
    }
  });

  /// Requirement: doc/specs/d20-tests.md FR-055 - a roll built from a mode
  ///   and the face values in the order rolled selects its natural with the
  ///   kernel RollMode.select: [18, 3] gives natural 18, kept index 0, under
  ///   advantage and natural 3, kept index 1, under disadvantage (SRD 5.2.1,
  ///   "Roll Two D20s", p. 8).
  /// Path: happy
  test(
    '[18, 3] keeps 18 at index 0 under advantage and 3 at index 1 under disadvantage',
    () {
      final advantage = D20Roll(mode: RollMode.advantage, dice: [18, 3]);
      final disadvantage = D20Roll(mode: RollMode.disadvantage, dice: [18, 3]);

      expect(advantage.natural, 18);
      expect(advantage.keptIndex, 0);
      expect(disadvantage.natural, 3);
      expect(disadvantage.keptIndex, 1);
    },
  );

  /// Requirement: doc/specs/d20-tests.md FR-015 - dice is unmodifiable:
  ///   mutating it throws UnsupportedError (doc/rules/architecture.md §3).
  /// Path: unhappy (immutability)
  test('dice cannot be mutated', () {
    final roll = D20Roll(mode: RollMode.advantage, dice: [18, 3]);

    expect(() => roll.dice.add(1), throwsUnsupportedError);
    expect(() => roll.dice[0] = 1, throwsUnsupportedError);
  });

  /// Requirement: doc/specs/d20-tests.md FR-068 - each result of replaceDie
  ///   and applyReroll has its own dice list (doc/rules/architecture.md §3,
  ///   §4).
  /// Path: unhappy (immutability)
  test('results of replaceDie and applyReroll hold their own dice lists', () {
    final original = D20Roll(mode: RollMode.advantage, dice: [18, 3]);

    final replaced = original.replaceDie(0, 18);
    final rerolled = original.applyReroll(const RerollDie(1), newValue: 3);

    expect(identical(replaced.dice, original.dice), isFalse);
    expect(identical(rerolled.dice, original.dice), isFalse);
    expect(replaced, original);
    expect(rerolled, original);
  });

  /// Requirement: doc/specs/d20-tests.md FR-050 - a D20Roll is equal, with an
  ///   equal hash code, when every field is equal (doc/rules/architecture.md
  ///   §3).
  /// Path: happy
  test('equal rolls are equal with equal hash codes', () {
    final a = D20Roll(mode: RollMode.advantage, dice: [18, 3]);
    final b = D20Roll(mode: RollMode.advantage, dice: [18, 3]);

    expect(a, b);
    expect(a.hashCode, b.hashCode);
  });

  /// Requirement: doc/specs/d20-tests.md FR-050 - a D20Roll is unequal when
  ///   any single field differs: the mode, the dice contents or the dice
  ///   order (doc/rules/architecture.md §3).
  /// Path: unhappy (any differing field)
  test('rolls differing in one field are unequal', () {
    final base = D20Roll(mode: RollMode.advantage, dice: [18, 3]);
    final otherMode = D20Roll(mode: RollMode.disadvantage, dice: [18, 3]);
    final otherDice = D20Roll(mode: RollMode.advantage, dice: [18, 4]);
    final otherOrder = D20Roll(mode: RollMode.advantage, dice: [3, 18]);

    expect(base, isNot(otherMode));
    expect(base, isNot(otherDice));
    expect(base, isNot(otherOrder));
  });

  /// Requirement: doc/specs/d20-tests.md FR-050 - the RerollDecision variants
  ///   are equal, with equal hash codes, when every field is equal
  ///   (doc/rules/architecture.md §3).
  /// Path: happy
  test('equal reroll decisions are equal with equal hash codes', () {
    expect(const KeepRoll(), const KeepRoll());
    expect(const KeepRoll().hashCode, const KeepRoll().hashCode);
    expect(const RerollDie(0), const RerollDie(0));
    expect(const RerollDie(0).hashCode, const RerollDie(0).hashCode);
  });

  /// Requirement: doc/specs/d20-tests.md FR-050 - a RerollDecision is unequal
  ///   when any single field differs: the die index or the variant itself
  ///   (doc/rules/architecture.md §3).
  /// Path: unhappy (any differing field)
  test('reroll decisions differing in one field are unequal', () {
    expect(const RerollDie(0), isNot(const RerollDie(1)));
    expect(const KeepRoll(), isNot(const RerollDie(0)));
  });
}
