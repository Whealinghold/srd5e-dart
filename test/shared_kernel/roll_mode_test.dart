import 'dart:math' as math;

import 'package:srd5e/src/shared_kernel/dice/dice_expression.dart';
import 'package:srd5e/src/shared_kernel/dice/die.dart';
import 'package:srd5e/src/shared_kernel/dice/die_roll.dart';
import 'package:srd5e/src/shared_kernel/dice/roll_result.dart';
import 'package:srd5e/src/shared_kernel/roll_circumstance.dart';
import 'package:srd5e/src/shared_kernel/roll_mode.dart';
import 'package:test/test.dart';

import '../support/argument_error_matcher.dart';

const Advantage _a = Advantage();
const Disadvantage _d = Disadvantage();

/// An Iterable that may be iterated once: asking for a second iterator throws.
/// Unlike the Iterable returned by a `sync*` function, which re-runs its body
/// for every iterator, this proves `RollMode.resolve` reads its input once
/// (and calls neither `isEmpty` nor `length` first).
final class _SinglePass extends Iterable<RollCircumstance> {
  _SinglePass(this._items);

  final List<RollCircumstance> _items;
  bool _used = false;

  @override
  Iterator<RollCircumstance> get iterator {
    if (_used) {
      throw StateError('iterated more than once');
    }
    _used = true;
    return _items.iterator;
  }
}

Iterable<RollCircumstance> _generated(List<RollCircumstance> items) sync* {
  yield* items;
}

List<RollCircumstance> _counts(int advantages, int disadvantages) => [
  for (var i = 0; i < advantages; i++) _a,
  for (var i = 0; i < disadvantages; i++) _d,
];

typedef _CountCase = ({
  String label,
  String requirement,
  String path,
  int advantages,
  int disadvantages,
  RollMode expected,
});

typedef _SequenceCase = ({
  String label,
  String requirement,
  String path,
  Iterable<RollCircumstance> Function() make,
  RollMode expected,
});

typedef _SelectCase = ({
  String label,
  String requirement,
  String path,
  RollMode mode,
  List<int> rolled,
  int expected,
});

typedef _RejectCase = ({
  String label,
  String requirement,
  String path,
  RollMode mode,
  List<int> rolled,
});

typedef _DiceCountCase = ({
  String label,
  String requirement,
  String path,
  RollMode mode,
  int expected,
});

const List<_CountCase> _counted = [
  (
    label: 'none',
    requirement:
        'doc/specs/modifiers-and-advantage.md FR-010 (SRD 5.2.1, "D20 Tests", "Roll 1d20", p. 6)',
    path: 'unhappy (empty and minimal)',
    advantages: 0,
    disadvantages: 0,
    expected: RollMode.normal,
  ),
  (
    label: 'one Advantage',
    requirement:
        'doc/specs/modifiers-and-advantage.md FR-011 (SRD 5.2.1, "Rules Glossary", "Advantage", p. 176)',
    path: 'happy',
    advantages: 1,
    disadvantages: 0,
    expected: RollMode.advantage,
  ),
  (
    label: 'one Disadvantage',
    requirement:
        'doc/specs/modifiers-and-advantage.md FR-012 (SRD 5.2.1, "Rules Glossary", "Disadvantage", p. 181)',
    path: 'happy',
    advantages: 0,
    disadvantages: 1,
    expected: RollMode.disadvantage,
  ),
  (
    label: 'two Advantage',
    requirement:
        'doc/specs/modifiers-and-advantage.md FR-013 and FR-039 (SRD 5.2.1, "They Don\'t Stack", p. 8)',
    path: 'unhappy (rule interaction)',
    advantages: 2,
    disadvantages: 0,
    expected: RollMode.advantage,
  ),
  (
    label: 'many Advantage',
    requirement:
        'doc/specs/modifiers-and-advantage.md FR-013 and FR-039 (SRD 5.2.1, "They Don\'t Stack", p. 8)',
    path: 'unhappy (rule interaction)',
    advantages: 5,
    disadvantages: 0,
    expected: RollMode.advantage,
  ),
  (
    label: 'two Disadvantage',
    requirement:
        'doc/specs/modifiers-and-advantage.md FR-014 and FR-040 (SRD 5.2.1, "They Don\'t Stack", p. 8)',
    path: 'unhappy (rule interaction)',
    advantages: 0,
    disadvantages: 2,
    expected: RollMode.disadvantage,
  ),
  (
    label: 'many Disadvantage',
    requirement:
        'doc/specs/modifiers-and-advantage.md FR-014 and FR-040 (SRD 5.2.1, "They Don\'t Stack", p. 8)',
    path: 'unhappy (rule interaction)',
    advantages: 0,
    disadvantages: 5,
    expected: RollMode.disadvantage,
  ),
  (
    label: 'one each',
    requirement:
        'doc/specs/modifiers-and-advantage.md FR-015 (SRD 5.2.1, "They Don\'t Stack", p. 8)',
    path: 'unhappy (rule interaction)',
    advantages: 1,
    disadvantages: 1,
    expected: RollMode.normal,
  ),
  (
    label: 'many Advantage, one Disadvantage',
    requirement:
        'doc/specs/modifiers-and-advantage.md FR-015 (SRD 5.2.1, "They Don\'t Stack", p. 8)',
    path: 'unhappy (rule interaction)',
    advantages: 3,
    disadvantages: 1,
    expected: RollMode.normal,
  ),
  (
    label: 'one Advantage, many Disadvantage',
    requirement:
        'doc/specs/modifiers-and-advantage.md FR-015 (SRD 5.2.1, "They Don\'t Stack", p. 8)',
    path: 'unhappy (rule interaction)',
    advantages: 1,
    disadvantages: 3,
    expected: RollMode.normal,
  ),
  (
    label: 'many each',
    requirement:
        'doc/specs/modifiers-and-advantage.md FR-015 (SRD 5.2.1, "They Don\'t Stack", p. 8)',
    path: 'unhappy (rule interaction)',
    advantages: 4,
    disadvantages: 4,
    expected: RollMode.normal,
  ),
];

final List<_SequenceCase> _sequences = [
  (
    label: 'order: Disadvantage first',
    requirement:
        'doc/specs/modifiers-and-advantage.md FR-016 (derived from SRD 5.2.1, "They Don\'t Stack", p. 8)',
    path: 'unhappy (rule interaction)',
    make: () => [_d, _a],
    expected: RollMode.normal,
  ),
  (
    label: 'order: Advantage first',
    requirement:
        'doc/specs/modifiers-and-advantage.md FR-016 (derived from SRD 5.2.1, "They Don\'t Stack", p. 8)',
    path: 'unhappy (rule interaction)',
    make: () => [_a, _d],
    expected: RollMode.normal,
  ),
  (
    label: 'order: mixed',
    requirement:
        'doc/specs/modifiers-and-advantage.md FR-016 (derived from SRD 5.2.1, "They Don\'t Stack", p. 8)',
    path: 'unhappy (rule interaction)',
    make: () => [_a, _d, _a, _d, _a],
    expected: RollMode.normal,
  ),
  (
    label: 'order: Disadvantage then Advantages only',
    requirement:
        'doc/specs/modifiers-and-advantage.md FR-016 (derived from SRD 5.2.1, "They Don\'t Stack", p. 8)',
    path: 'unhappy (rule interaction)',
    make: () => [_d, _d, _a, _a, _a],
    expected: RollMode.normal,
  ),
  (
    label: 'single-pass Iterable',
    requirement:
        'doc/specs/modifiers-and-advantage.md FR-042 and FR-017 (read once)',
    path: 'unhappy (rule interaction)',
    make: () => _SinglePass([_a, _d]),
    expected: RollMode.normal,
  ),
  (
    label: 'single-pass Iterable, Advantage only',
    requirement:
        'doc/specs/modifiers-and-advantage.md FR-042 and FR-017 (read once)',
    path: 'unhappy (rule interaction)',
    make: () => _SinglePass([_a, _a]),
    expected: RollMode.advantage,
  ),
  (
    label: 'single-pass Iterable, Disadvantage only',
    requirement:
        'doc/specs/modifiers-and-advantage.md FR-042 and FR-017 (read once)',
    path: 'unhappy (rule interaction)',
    make: () => _SinglePass([_d]),
    expected: RollMode.disadvantage,
  ),
  (
    label: 'sync* generator',
    requirement:
        'doc/specs/modifiers-and-advantage.md FR-042 and FR-017 (any Iterable)',
    path: 'unhappy (rule interaction)',
    make: () => _generated([_a, _d]),
    expected: RollMode.normal,
  ),
  (
    label: 'sync* generator, Advantage only',
    requirement:
        'doc/specs/modifiers-and-advantage.md FR-042 and FR-017 (any Iterable)',
    path: 'unhappy (rule interaction)',
    make: () => _generated([_a, _a]),
    expected: RollMode.advantage,
  ),
  (
    label: 'Set',
    requirement:
        'doc/specs/modifiers-and-advantage.md FR-042 (any Iterable, here a Set)',
    path: 'unhappy (rule interaction)',
    make: () => <RollCircumstance>{_a, _d},
    expected: RollMode.normal,
  ),
  (
    label: 'Set of one Advantage',
    requirement:
        'doc/specs/modifiers-and-advantage.md FR-042 (any Iterable, here a Set)',
    path: 'unhappy (rule interaction)',
    make: () => <RollCircumstance>{_a},
    expected: RollMode.advantage,
  ),
  (
    label: 'empty Iterable',
    requirement:
        'doc/specs/modifiers-and-advantage.md FR-042 and FR-010 (any Iterable, here an empty one)',
    path: 'unhappy (empty and minimal)',
    make: () => const Iterable<RollCircumstance>.empty(),
    expected: RollMode.normal,
  ),
  (
    label: 'lazy Iterable, Disadvantage only',
    requirement:
        'doc/specs/modifiers-and-advantage.md FR-042 (any Iterable, here a lazy map)',
    path: 'unhappy (rule interaction)',
    make: () => [false, false].map((on) => on ? _a : _d),
    expected: RollMode.disadvantage,
  ),
];

const List<_DiceCountCase> _diceCounts = [
  (
    label: 'normal needs one d20',
    requirement:
        'FR-018 (SRD 5.2.1, "D20 Tests", "Roll 1d20", p. 6; "They Don\'t '
        'Stack", p. 8)',
    mode: RollMode.normal,
    path: 'happy',
    expected: 1,
  ),
  (
    label: 'advantage needs two d20s',
    requirement:
        'doc/specs/modifiers-and-advantage.md FR-019 (SRD 5.2.1, "Roll Two D20s", p. 8)',
    mode: RollMode.advantage,
    path: 'happy',
    expected: 2,
  ),
  (
    label: 'disadvantage needs two d20s',
    requirement:
        'doc/specs/modifiers-and-advantage.md FR-020 (SRD 5.2.1, "Roll Two D20s", p. 8)',
    mode: RollMode.disadvantage,
    path: 'happy',
    expected: 2,
  ),
];

const List<_SelectCase> _selected = [
  (
    label: 'single d20',
    requirement:
        'doc/specs/modifiers-and-advantage.md FR-021 (SRD 5.2.1, "D20 Tests", "Roll 1d20", p. 6)',
    path: 'happy',
    mode: RollMode.normal,
    rolled: [14],
    expected: 14,
  ),
  (
    label: 'single d20, lowest',
    requirement:
        'doc/specs/modifiers-and-advantage.md FR-021 and FR-027 (SRD 5.2.1, "Rolling 20 or 1", p. 7)',
    path: 'unhappy (boundary)',
    mode: RollMode.normal,
    rolled: [1],
    expected: 1,
  ),
  (
    label: 'single d20, highest',
    requirement:
        'doc/specs/modifiers-and-advantage.md FR-021 and FR-027 (SRD 5.2.1, "Rolling 20 or 1", p. 7)',
    path: 'unhappy (boundary)',
    mode: RollMode.normal,
    rolled: [20],
    expected: 20,
  ),
  (
    label: 'Advantage, SRD example',
    requirement:
        'doc/specs/modifiers-and-advantage.md FR-022 (SRD 5.2.1, "Roll Two D20s", p. 8)',
    path: 'happy',
    mode: RollMode.advantage,
    rolled: [18, 3],
    expected: 18,
  ),
  (
    label: 'Disadvantage, SRD example',
    requirement:
        'doc/specs/modifiers-and-advantage.md FR-023 (SRD 5.2.1, "Roll Two D20s", p. 8)',
    path: 'happy',
    mode: RollMode.disadvantage,
    rolled: [18, 3],
    expected: 3,
  ),
  (
    label: 'Advantage, swapped',
    requirement:
        'doc/specs/modifiers-and-advantage.md FR-022 and FR-038 (SRD 5.2.1, "Roll Two D20s", p. 8)',
    path: 'unhappy (determinism)',
    mode: RollMode.advantage,
    rolled: [3, 18],
    expected: 18,
  ),
  (
    label: 'Disadvantage, swapped',
    requirement:
        'doc/specs/modifiers-and-advantage.md FR-023 and FR-038 (SRD 5.2.1, "Roll Two D20s", p. 8)',
    path: 'unhappy (determinism)',
    mode: RollMode.disadvantage,
    rolled: [3, 18],
    expected: 3,
  ),
  (
    label: 'Advantage, equal',
    requirement:
        'doc/specs/modifiers-and-advantage.md FR-024 (derived from SRD 5.2.1, "Roll Two D20s", p. 8)',
    path: 'unhappy (boundary)',
    mode: RollMode.advantage,
    rolled: [7, 7],
    expected: 7,
  ),
  (
    label: 'Disadvantage, equal',
    requirement:
        'doc/specs/modifiers-and-advantage.md FR-024 (derived from SRD 5.2.1, "Roll Two D20s", p. 8)',
    path: 'unhappy (boundary)',
    mode: RollMode.disadvantage,
    rolled: [7, 7],
    expected: 7,
  ),
  (
    label: 'Advantage, extremes',
    requirement:
        'doc/specs/modifiers-and-advantage.md FR-025 (SRD 5.2.1, "Roll Two D20s", p. 8)',
    path: 'unhappy (boundary)',
    mode: RollMode.advantage,
    rolled: [1, 20],
    expected: 20,
  ),
  (
    label: 'Disadvantage, extremes',
    requirement:
        'doc/specs/modifiers-and-advantage.md FR-025 (SRD 5.2.1, "Roll Two D20s", p. 8)',
    path: 'unhappy (boundary)',
    mode: RollMode.disadvantage,
    rolled: [20, 1],
    expected: 1,
  ),
  (
    label: 'Advantage, extremes reversed',
    requirement:
        'doc/specs/modifiers-and-advantage.md FR-025 and FR-038 (SRD 5.2.1, "Roll Two D20s", p. 8)',
    path: 'unhappy (boundary)',
    mode: RollMode.advantage,
    rolled: [20, 1],
    expected: 20,
  ),
  (
    label: 'Disadvantage, extremes reversed',
    requirement:
        'doc/specs/modifiers-and-advantage.md FR-025 and FR-038 (SRD 5.2.1, "Roll Two D20s", p. 8)',
    path: 'unhappy (boundary)',
    mode: RollMode.disadvantage,
    rolled: [1, 20],
    expected: 1,
  ),
  (
    label: 'Advantage, both 1',
    requirement:
        'doc/specs/modifiers-and-advantage.md FR-024 (derived from SRD 5.2.1, "Roll Two D20s", p. 8)',
    path: 'unhappy (boundary)',
    mode: RollMode.advantage,
    rolled: [1, 1],
    expected: 1,
  ),
  (
    label: 'Disadvantage, both 20',
    requirement:
        'doc/specs/modifiers-and-advantage.md FR-024 (derived from SRD 5.2.1, "Roll Two D20s", p. 8)',
    path: 'unhappy (boundary)',
    mode: RollMode.disadvantage,
    rolled: [20, 20],
    expected: 20,
  ),
];

const List<_RejectCase> _rejected = [
  (
    label: 'normal, no values',
    requirement:
        'doc/specs/modifiers-and-advantage.md FR-026 (SRD 5.2.1, "D20 Tests", p. 6)',
    path: 'unhappy (invalid input)',
    mode: RollMode.normal,
    rolled: [],
  ),
  (
    label: 'normal, two values',
    requirement:
        'doc/specs/modifiers-and-advantage.md FR-026 (SRD 5.2.1, "D20 Tests", p. 6)',
    path: 'unhappy (invalid input)',
    mode: RollMode.normal,
    rolled: [4, 9],
  ),
  (
    label: 'Advantage, no values',
    requirement:
        'doc/specs/modifiers-and-advantage.md FR-026 (SRD 5.2.1, "Roll Two D20s", p. 8)',
    path: 'unhappy (invalid input)',
    mode: RollMode.advantage,
    rolled: [],
  ),
  (
    label: 'Advantage, one value',
    requirement:
        'doc/specs/modifiers-and-advantage.md FR-026 (SRD 5.2.1, "Roll Two D20s", p. 8)',
    path: 'unhappy (invalid input)',
    mode: RollMode.advantage,
    rolled: [12],
  ),
  (
    label: 'Advantage, three values',
    requirement:
        'doc/specs/modifiers-and-advantage.md FR-026 (SRD 5.2.1, "Roll Two D20s", p. 8)',
    path: 'unhappy (invalid input)',
    mode: RollMode.advantage,
    rolled: [1, 2, 3],
  ),
  (
    label: 'Disadvantage, no values',
    requirement:
        'doc/specs/modifiers-and-advantage.md FR-026 (SRD 5.2.1, "Roll Two D20s", p. 8)',
    path: 'unhappy (invalid input)',
    mode: RollMode.disadvantage,
    rolled: [],
  ),
  (
    label: 'Disadvantage, one value',
    requirement:
        'doc/specs/modifiers-and-advantage.md FR-026 (SRD 5.2.1, "Roll Two D20s", p. 8)',
    path: 'unhappy (invalid input)',
    mode: RollMode.disadvantage,
    rolled: [12],
  ),
  (
    label: 'Disadvantage, three values',
    requirement:
        'doc/specs/modifiers-and-advantage.md FR-026 (SRD 5.2.1, "Roll Two D20s", p. 8)',
    path: 'unhappy (invalid input)',
    mode: RollMode.disadvantage,
    rolled: [5, 6, 7],
  ),
  (
    label: 'wrong count and out of range',
    requirement:
        'doc/specs/modifiers-and-advantage.md FR-026 and FR-027 (no check order is claimed)',
    path: 'unhappy (invalid input)',
    mode: RollMode.advantage,
    rolled: [0],
  ),
  (
    label: 'value zero',
    requirement:
        'doc/specs/modifiers-and-advantage.md FR-027 (SRD 5.2.1, "Rolling 20 or 1", p. 7)',
    path: 'unhappy (boundary)',
    mode: RollMode.normal,
    rolled: [0],
  ),
  (
    label: 'value 21',
    requirement:
        'doc/specs/modifiers-and-advantage.md FR-027 (SRD 5.2.1, "Rolling 20 or 1", p. 7)',
    path: 'unhappy (boundary)',
    mode: RollMode.normal,
    rolled: [21],
  ),
  (
    label: 'value negative',
    requirement:
        'doc/specs/modifiers-and-advantage.md FR-027 (derived from SRD 5.2.1, "D20 Tests", p. 6)',
    path: 'unhappy (invalid input)',
    mode: RollMode.normal,
    rolled: [-3],
  ),
  (
    label: 'one die out of range under Advantage',
    requirement:
        'doc/specs/modifiers-and-advantage.md FR-027 (SRD 5.2.1, "Rolling 20 or 1", p. 7)',
    path: 'unhappy (boundary)',
    mode: RollMode.advantage,
    rolled: [20, 21],
  ),
  (
    label: 'one die out of range under Disadvantage',
    requirement:
        'doc/specs/modifiers-and-advantage.md FR-027 (SRD 5.2.1, "Rolling 20 or 1", p. 7)',
    path: 'unhappy (boundary)',
    mode: RollMode.disadvantage,
    rolled: [0, 10],
  ),
  (
    label: 'first die out of range under Advantage',
    requirement:
        'doc/specs/modifiers-and-advantage.md FR-027 (SRD 5.2.1, "Rolling 20 or 1", p. 7)',
    path: 'unhappy (boundary)',
    mode: RollMode.advantage,
    rolled: [21, 10],
  ),
  (
    label: 'second die negative under Disadvantage',
    requirement:
        'doc/specs/modifiers-and-advantage.md FR-027 (derived from SRD 5.2.1, "D20 Tests", p. 6)',
    path: 'unhappy (invalid input)',
    mode: RollMode.disadvantage,
    rolled: [10, -1],
  ),
];

void main() {
  /// Requirement: doc/specs/modifiers-and-advantage.md section 3 and
  ///   doc/specs/shared-types-and-ownership.md FR-001 and FR-041 - the roll modes are
  ///   normal, advantage and disadvantage, and their names are the values of
  ///   `srd5e.d20_test.roll_mode` (SRD 5.2.1, "Advantage/Disadvantage",
  ///   p. 8).
  /// Path: happy
  test('RollMode has exactly the modes normal, advantage, disadvantage', () {
    expect(RollMode.values.map((mode) => mode.name), [
      'normal',
      'advantage',
      'disadvantage',
    ]);
  });

  /// Requirement: per case - doc/specs/modifiers-and-advantage.md FR-010, FR-011, FR-012,
  ///   FR-013, FR-014, FR-015, FR-016, FR-039, FR-040 and FR-042 - circumstances resolve to a roll mode by
  ///   which kinds are present, never by how many (SRD 5.2.1,
  ///   "Advantage/Disadvantage", "They Don't Stack", p. 8).
  /// Path: per case
  group('RollMode.resolve', () {
    /// Requirement: per case
    /// Path: per case
    for (final c in _counted) {
      test('${c.label} [${c.path}] (${c.requirement})', () {
        final circumstances = _counts(c.advantages, c.disadvantages);

        final mode = RollMode.resolve(circumstances);

        expect(mode, c.expected);
      });
    }

    /// Requirement: per case
    /// Path: per case
    for (final c in _sequences) {
      test('${c.label} [${c.path}] (${c.requirement})', () {
        final circumstances = c.make();

        final mode = RollMode.resolve(circumstances);

        expect(mode, c.expected);
      });
    }

    /// Requirement: doc/specs/modifiers-and-advantage.md FR-017 - resolving
    ///   does not alter the input collection.
    /// Path: unhappy (immutability)
    test('leaves the input list unchanged', () {
      final input = <RollCircumstance>[_a, _d, _a];

      RollMode.resolve(input);

      expect(input, [_a, _d, _a]);
    });

    /// Requirement: doc/specs/modifiers-and-advantage.md FR-017 - resolving an
    ///   unmodifiable input works (the input is only read).
    /// Path: unhappy (immutability)
    test('resolves an unmodifiable list', () {
      final input = List<RollCircumstance>.unmodifiable([_a, _a]);

      expect(RollMode.resolve(input), RollMode.advantage);
    });

    /// Requirement: doc/specs/modifiers-and-advantage.md FR-039 - adding
    ///   further Advantage circumstances to a set that already resolves to
    ///   advantage does not change the mode (1, 2 and 5 give the same mode).
    /// Path: unhappy (rule interaction)
    test('1, 2 and 5 Advantage circumstances give the same mode', () {
      final modes = [
        for (final n in [1, 2, 5]) RollMode.resolve(_counts(n, 0)),
      ];

      expect(modes, [
        RollMode.advantage,
        RollMode.advantage,
        RollMode.advantage,
      ]);
    });

    /// Requirement: doc/specs/modifiers-and-advantage.md FR-040 - adding
    ///   further Disadvantage circumstances to a set that already resolves to
    ///   disadvantage does not change the mode (1, 2 and 5 give the same mode).
    /// Path: unhappy (rule interaction)
    test('1, 2 and 5 Disadvantage circumstances give the same mode', () {
      final modes = [
        for (final n in [1, 2, 5]) RollMode.resolve(_counts(0, n)),
      ];

      expect(modes, [
        RollMode.disadvantage,
        RollMode.disadvantage,
        RollMode.disadvantage,
      ]);
    });

    /// Requirement: doc/specs/modifiers-and-advantage.md FR-015 - the cancel
    ///   rule has no counts: every combination of 1 to 4 Advantage and 1 to 4
    ///   Disadvantage circumstances is normal (SRD 5.2.1, "They Don't Stack",
    ///   p. 8).
    /// Path: unhappy (rule interaction)
    test('any mix of both kinds is normal whatever the counts', () {
      final modes = {
        for (var a = 1; a <= 4; a++)
          for (var d = 1; d <= 4; d++) RollMode.resolve(_counts(a, d)),
      };

      expect(modes, {RollMode.normal});
    });
  });

  /// Requirement: per case - doc/specs/modifiers-and-advantage.md FR-018, FR-019 and FR-020
  ///   - the number of d20s a mode needs (SRD 5.2.1, "D20 Tests", "Roll 1d20", p. 6;
  ///   "Roll Two D20s", p. 8).
  /// Path: per case
  group('RollMode.diceCount', () {
    /// Requirement: per case
    /// Path: per case
    for (final c in _diceCounts) {
      test('${c.label} [${c.path}] (${c.requirement})', () {
        expect(c.mode.diceCount, c.expected);
      });
    }
  });

  /// Requirement: per case - doc/specs/modifiers-and-advantage.md FR-021, FR-022, FR-023,
  ///   FR-024, FR-025 and FR-038 - the used d20 number (SRD 5.2.1, "D20 Tests", "Roll 1d20",
  ///   p. 6; "Roll Two D20s", p. 8).
  /// Path: per case
  group('RollMode.select picks', () {
    /// Requirement: per case
    /// Path: per case
    for (final c in _selected) {
      test('${c.label} [${c.path}] (${c.requirement})', () {
        final used = c.mode.select(c.rolled);

        expect(used, c.expected);
      });
    }

    /// Requirement: doc/specs/modifiers-and-advantage.md FR-022, FR-023 and
    ///   FR-038 - for every pair of d20 faces Advantage uses the higher and
    ///   Disadvantage the lower, whichever order the dice are given in (SRD
    ///   5.2.1, "Roll Two D20s", p. 8).
    /// Path: unhappy (determinism)
    test('the higher or lower of every pair of faces, in either order', () {
      final pairs = [
        for (var x = 1; x <= 20; x++)
          for (var y = 1; y <= 20; y++) [x, y],
      ];

      final higher = [for (final p in pairs) RollMode.advantage.select(p)];
      final lower = [for (final p in pairs) RollMode.disadvantage.select(p)];

      expect(higher, [for (final p in pairs) math.max(p[0], p[1])]);
      expect(lower, [for (final p in pairs) math.min(p[0], p[1])]);
    });

    /// Requirement: doc/specs/modifiers-and-advantage.md FR-021 - with normal
    ///   the used number is the single d20 rolled, for every face.
    /// Path: unhappy (boundary)
    test('normal returns each single face unchanged', () {
      final faces = [for (var x = 1; x <= 20; x++) x];

      final used = [
        for (final f in faces) RollMode.normal.select([f]),
      ];

      expect(used, faces);
    });

    /// Requirement: doc/specs/modifiers-and-advantage.md section 5 (and
    ///   doc/specs/dice-and-rolls.md) - `select` agrees with the generic dice
    ///   arithmetic `sumOfHighest(1)` and `sumOfLowest(1)` on the SRD example
    ///   [18, 3], though it does not use them (SRD 5.2.1, "Roll Two D20s",
    ///   p. 8).
    /// Path: happy
    test('agrees with RollResult.sumOfHighest and sumOfLowest on [18, 3]', () {
      final result = RollResult(DiceExpression(2, Die.d20), [
        DieRoll(Die.d20, 18),
        DieRoll(Die.d20, 3),
      ]);

      expect(RollMode.advantage.select([18, 3]), result.sumOfHighest(1));
      expect(RollMode.disadvantage.select([18, 3]), result.sumOfLowest(1));
    });
  });

  /// Requirement: per case - doc/specs/modifiers-and-advantage.md FR-026 and FR-027 - the
  ///   wrong number of dice, or a die outside 1 to 20, is a programmer error:
  ///   ArgumentError named `rolled` carrying the list passed in (SRD 5.2.1,
  ///   "Roll Two D20s", p. 8; "Rolling 20 or 1", p. 7).
  /// Path: per case
  group('RollMode.select rejects', () {
    /// Requirement: per case
    /// Path: per case
    for (final c in _rejected) {
      test('${c.label} [${c.path}] (${c.requirement})', () {
        expect(
          () => c.mode.select(c.rolled),
          throwsArgumentErrorFor('rolled', c.rolled),
        );
      });
    }

    /// Requirement: doc/specs/modifiers-and-advantage.md FR-026 - the
    ///   invalidValue is the very list passed in, not a copy.
    /// Path: unhappy (invalid input)
    test('reports the list that was passed in', () {
      final rolled = <int>[3, 4, 5];

      Object? invalidValue;
      try {
        RollMode.advantage.select(rolled);
      } on ArgumentError catch (e) {
        invalidValue = e.invalidValue;
      }

      expect(identical(invalidValue, rolled), isTrue);
    });
  });

  /// Requirement: doc/specs/modifiers-and-advantage.md FR-030 and FR-031 -
  ///   select does not alter its input and is deterministic (package design;
  ///   architecture.md §3).
  /// Path: unhappy (immutability, determinism)
  group('RollMode.select purity', () {
    /// Requirement: doc/specs/modifiers-and-advantage.md FR-030 - the input
    ///   list is unchanged after select.
    /// Path: unhappy (immutability)
    test('leaves a mutable input list unchanged', () {
      final rolled = <int>[18, 3];

      RollMode.advantage.select(rolled);
      RollMode.disadvantage.select(rolled);

      expect(rolled, [18, 3]);
    });

    /// Requirement: doc/specs/modifiers-and-advantage.md FR-030 - select reads
    ///   an unmodifiable list without an UnsupportedError.
    /// Path: unhappy (immutability)
    test('selects from an unmodifiable list', () {
      final rolled = List<int>.unmodifiable([18, 3]);

      final higher = RollMode.advantage.select(rolled);
      final lower = RollMode.disadvantage.select(rolled);

      expect(higher, 18);
      expect(lower, 3);
    });

    /// Requirement: doc/specs/modifiers-and-advantage.md FR-031 - the same mode
    ///   and values always give the same used number.
    /// Path: unhappy (determinism)
    test('the same mode and values give the same number every time', () {
      final results = [
        for (var i = 0; i < 3; i++) RollMode.disadvantage.select([18, 3]),
      ];

      expect(results, [3, 3, 3]);
    });
  });
}
