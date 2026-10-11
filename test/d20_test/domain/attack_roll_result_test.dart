import 'package:srd5e/src/d20_test/domain/armor_class.dart';
import 'package:srd5e/src/d20_test/domain/attack_roll_result.dart';
import 'package:srd5e/src/d20_test/domain/d20_roll.dart';
import 'package:srd5e/src/d20_test/domain/d20_test_outcome.dart';
import 'package:srd5e/src/d20_test/domain/roll_modifiers.dart';
import 'package:srd5e/src/shared_kernel/modifier.dart';
import 'package:srd5e/src/shared_kernel/roll_mode.dart';
import 'package:test/test.dart';

/// What an attack-table case expects to happen.
sealed class _Expectation {
  const _Expectation();
}

/// The roll resolves to exactly this total, outcome and critical-hit flag.
final class _Resolves extends _Expectation {
  const _Resolves(this.total, this.outcome, this.isCriticalHit);

  final int total;
  final D20TestOutcome outcome;
  final bool isCriticalHit;
}

/// `resolve` throws an ArgumentError named `criticalRange` carrying
/// [invalidValue].
final class _RejectsRange extends _Expectation {
  const _RejectsRange(this.invalidValue);

  final int invalidValue;
}

/// One field of an `AttackRollResult` that an inequality case differs in.
enum _DifferingField {
  roll,
  modifiers,
  total,
  target,
  outcome,
  isCriticalHit,
  criticalRange,
}

typedef _AttackCase = ({
  String label,
  String requirement,
  String path,
  RollMode mode,
  List<int> dice,
  int ability,
  int? proficiency,
  List<int> others,
  int ac,
  int? criticalRange,
  _Expectation expectation,
});

typedef _HitCase = ({
  String label,
  String requirement,
  String path,
  List<int> dice,
  int ability,
  int ac,
  bool hit,
});

typedef _InequalityCase = ({
  String label,
  String requirement,
  String path,
  _DifferingField field,
});

/// The 28-row attack roll resolution table of `doc/specs/d20-tests.md`
/// section 4.5, in the order written there. Its "range 18: natural 20 and
/// natural 1" and "range 17 or 21" rows each name two cases, so they appear
/// as two entries here.
const List<_AttackCase> _attackCases = [
  (
    label: 'total equals the AC',
    requirement:
        'doc/specs/d20-tests.md FR-027 (SRD 5.2.1, "Attack Rolls", p. 7)',
    path: 'unhappy (boundary)',
    mode: RollMode.normal,
    dice: [10],
    ability: 3,
    proficiency: 2,
    others: [],
    ac: 15,
    criticalRange: null,
    expectation: _Resolves(15, D20TestOutcome.success, false),
  ),
  (
    label: 'total one below the AC',
    requirement:
        'doc/specs/d20-tests.md FR-028 (SRD 5.2.1, "Attack Rolls", p. 7)',
    path: 'unhappy (boundary)',
    mode: RollMode.normal,
    dice: [10],
    ability: 4,
    proficiency: null,
    others: [],
    ac: 15,
    criticalRange: null,
    expectation: _Resolves(14, D20TestOutcome.failure, false),
  ),
  (
    label: 'total one above the AC',
    requirement:
        'doc/specs/d20-tests.md FR-027 (SRD 5.2.1, "Attack Rolls", p. 7)',
    path: 'unhappy (boundary)',
    mode: RollMode.normal,
    dice: [10],
    ability: 6,
    proficiency: null,
    others: [],
    ac: 15,
    criticalRange: null,
    expectation: _Resolves(16, D20TestOutcome.success, false),
  ),
  (
    label: 'natural 20 beats any AC',
    requirement:
        'doc/specs/d20-tests.md FR-029 and FR-051 (SRD 5.2.1, "Rolling 20 or '
        '1", p. 7; "Critical Hit", p. 179)',
    path: 'unhappy (boundary)',
    mode: RollMode.normal,
    dice: [20],
    ability: 0,
    proficiency: null,
    others: [],
    ac: 15,
    criticalRange: null,
    expectation: _Resolves(20, D20TestOutcome.success, true),
  ),
  (
    label: 'natural 20, total far below AC',
    requirement:
        'doc/specs/d20-tests.md FR-029 and FR-051 (SRD 5.2.1, "Rolling 20 or '
        '1", p. 7; "Critical Hit", p. 179)',
    path: 'unhappy (boundary)',
    mode: RollMode.normal,
    dice: [20],
    ability: -5,
    proficiency: null,
    others: [],
    ac: 30,
    criticalRange: null,
    expectation: _Resolves(15, D20TestOutcome.success, true),
  ),
  (
    label: 'natural 20, total equals AC',
    requirement:
        'doc/specs/d20-tests.md FR-029 and FR-051 (SRD 5.2.1, "Rolling 20 or '
        '1", p. 7; "Critical Hit", p. 179)',
    path: 'unhappy (boundary)',
    mode: RollMode.normal,
    dice: [20],
    ability: 5,
    proficiency: null,
    others: [],
    ac: 25,
    criticalRange: null,
    expectation: _Resolves(25, D20TestOutcome.success, true),
  ),
  (
    label: 'natural 20, total above AC',
    requirement:
        'doc/specs/d20-tests.md FR-029 and FR-051 (SRD 5.2.1, "Rolling 20 or '
        '1", p. 7; "Critical Hit", p. 179)',
    path: 'unhappy (boundary)',
    mode: RollMode.normal,
    dice: [20],
    ability: 10,
    proficiency: null,
    others: [],
    ac: 15,
    criticalRange: null,
    expectation: _Resolves(30, D20TestOutcome.success, true),
  ),
  (
    label: 'natural 1 misses a low AC',
    requirement:
        'doc/specs/d20-tests.md FR-030 and FR-051 (SRD 5.2.1, "Rolling 20 or '
        '1", p. 7)',
    path: 'unhappy (boundary)',
    mode: RollMode.normal,
    dice: [1],
    ability: 12,
    proficiency: null,
    others: [],
    ac: 10,
    criticalRange: null,
    expectation: _Resolves(13, D20TestOutcome.failure, false),
  ),
  (
    label: 'natural 1, total far above AC',
    requirement:
        'doc/specs/d20-tests.md FR-030 and FR-051 (SRD 5.2.1, "Rolling 20 or '
        '1", p. 7)',
    path: 'unhappy (boundary)',
    mode: RollMode.normal,
    dice: [1],
    ability: 20,
    proficiency: null,
    others: [],
    ac: 5,
    criticalRange: null,
    expectation: _Resolves(21, D20TestOutcome.failure, false),
  ),
  (
    label: 'natural 1, total also below AC',
    requirement:
        'doc/specs/d20-tests.md FR-030 and FR-051 (SRD 5.2.1, "Rolling 20 or '
        '1", p. 7)',
    path: 'unhappy (boundary)',
    mode: RollMode.normal,
    dice: [1],
    ability: 2,
    proficiency: null,
    others: [],
    ac: 15,
    criticalRange: null,
    expectation: _Resolves(3, D20TestOutcome.failure, false),
  ),
  (
    label: 'natural 19 one below AC',
    requirement:
        'doc/specs/d20-tests.md FR-033 (SRD 5.2.1, "Rolling 20 or 1", p. 7)',
    path: 'unhappy (boundary)',
    mode: RollMode.normal,
    dice: [19],
    ability: 0,
    proficiency: null,
    others: [],
    ac: 20,
    criticalRange: null,
    expectation: _Resolves(19, D20TestOutcome.failure, false),
  ),
  (
    label: 'natural 19 above AC is not critical',
    requirement:
        'doc/specs/d20-tests.md FR-033 (SRD 5.2.1, "Rolling 20 or 1", p. 7)',
    path: 'unhappy (boundary)',
    mode: RollMode.normal,
    dice: [19],
    ability: 10,
    proficiency: null,
    others: [],
    ac: 20,
    criticalRange: null,
    expectation: _Resolves(29, D20TestOutcome.success, false),
  ),
  (
    label: 'range 19: natural 19 crits below AC',
    requirement:
        'doc/specs/d20-tests.md FR-071 and FR-072 (SRD 5.2.1, "Critical Hit", '
        'p. 179; Fighter "Level 3: Improved Critical", p. 49)',
    path: 'unhappy (boundary)',
    mode: RollMode.normal,
    dice: [19],
    ability: -5,
    proficiency: null,
    others: [],
    ac: 30,
    criticalRange: 19,
    expectation: _Resolves(14, D20TestOutcome.success, true),
  ),
  (
    label: 'range 19: natural 18 does not',
    requirement:
        'doc/specs/d20-tests.md FR-071 and FR-072 (SRD 5.2.1, "Critical Hit", '
        'p. 179; Fighter "Level 3: Improved Critical", p. 49)',
    path: 'unhappy (boundary)',
    mode: RollMode.normal,
    dice: [18],
    ability: 0,
    proficiency: null,
    others: [],
    ac: 30,
    criticalRange: 19,
    expectation: _Resolves(18, D20TestOutcome.failure, false),
  ),
  (
    label: 'range 18: natural 18 crits below AC',
    requirement:
        'doc/specs/d20-tests.md FR-071 (SRD 5.2.1, "Critical Hit", p. 179; '
        'Fighter "Level 15: Superior Critical", p. 49)',
    path: 'unhappy (boundary)',
    mode: RollMode.normal,
    dice: [18],
    ability: 0,
    proficiency: null,
    others: [],
    ac: 30,
    criticalRange: 18,
    expectation: _Resolves(18, D20TestOutcome.success, true),
  ),
  (
    label: 'range 18: natural 17 does not',
    requirement:
        'doc/specs/d20-tests.md FR-071 (SRD 5.2.1, "Critical Hit", p. 179; '
        'Fighter "Level 15: Superior Critical", p. 49)',
    path: 'unhappy (boundary)',
    mode: RollMode.normal,
    dice: [17],
    ability: 0,
    proficiency: null,
    others: [],
    ac: 30,
    criticalRange: 18,
    expectation: _Resolves(17, D20TestOutcome.failure, false),
  ),
  (
    label: 'range 18: natural 20 (of "natural 20 and natural 1")',
    requirement:
        'doc/specs/d20-tests.md FR-071 and FR-029 (SRD 5.2.1, "Rolling 20 or '
        '1", p. 7; "Critical Hit", p. 179)',
    path: 'unhappy (boundary)',
    mode: RollMode.normal,
    dice: [20],
    ability: 0,
    proficiency: null,
    others: [],
    ac: 30,
    criticalRange: 18,
    expectation: _Resolves(20, D20TestOutcome.success, true),
  ),
  (
    label: 'range 18: natural 1 (of "natural 20 and natural 1")',
    requirement:
        'doc/specs/d20-tests.md FR-071 and FR-030 (SRD 5.2.1, "Rolling 20 or '
        '1", p. 7)',
    path: 'unhappy (boundary)',
    mode: RollMode.normal,
    dice: [1],
    ability: 0,
    proficiency: null,
    others: [],
    ac: 30,
    criticalRange: 18,
    expectation: _Resolves(1, D20TestOutcome.failure, false),
  ),
  (
    label: 'critical range 17 (of "range 17 or 21")',
    requirement:
        'doc/specs/d20-tests.md FR-072 (SRD 5.2.1, p. 49; '
        'doc/rules/testing.md §4)',
    path: 'unhappy (invalid input)',
    mode: RollMode.normal,
    dice: [10],
    ability: 0,
    proficiency: null,
    others: [],
    ac: 15,
    criticalRange: 17,
    expectation: _RejectsRange(17),
  ),
  (
    label: 'critical range 21 (of "range 17 or 21")',
    requirement:
        'doc/specs/d20-tests.md FR-072 (SRD 5.2.1, p. 49; '
        'doc/rules/testing.md §4)',
    path: 'unhappy (invalid input)',
    mode: RollMode.normal,
    dice: [10],
    ability: 0,
    proficiency: null,
    others: [],
    ac: 15,
    criticalRange: 21,
    expectation: _RejectsRange(21),
  ),
  (
    label: 'natural 2 above AC',
    requirement:
        'doc/specs/d20-tests.md FR-027 (SRD 5.2.1, "Attack Rolls", p. 7)',
    path: 'happy',
    mode: RollMode.normal,
    dice: [2],
    ability: 10,
    proficiency: null,
    others: [4],
    ac: 15,
    criticalRange: null,
    expectation: _Resolves(16, D20TestOutcome.success, false),
  ),
  (
    label: 'Advantage dice 20 and 1',
    requirement:
        'doc/specs/d20-tests.md FR-032 and FR-029 (SRD 5.2.1, "Roll Two '
        'D20s", p. 8; "Rolling 20 or 1", p. 7)',
    path: 'unhappy (rule interaction)',
    mode: RollMode.advantage,
    dice: [20, 1],
    ability: 0,
    proficiency: null,
    others: [],
    ac: 15,
    criticalRange: null,
    expectation: _Resolves(20, D20TestOutcome.success, true),
  ),
  (
    label: 'Disadvantage dice 20 and 1',
    requirement:
        'doc/specs/d20-tests.md FR-032 and FR-030 (SRD 5.2.1, "Roll Two '
        'D20s", p. 8; "Rolling 20 or 1", p. 7)',
    path: 'unhappy (rule interaction)',
    mode: RollMode.disadvantage,
    dice: [20, 1],
    ability: 20,
    proficiency: null,
    others: [],
    ac: 5,
    criticalRange: null,
    expectation: _Resolves(21, D20TestOutcome.failure, false),
  ),
  (
    label: 'Advantage dice 1 and 1',
    requirement:
        'doc/specs/d20-tests.md FR-030 and FR-058 (SRD 5.2.1, "Roll Two '
        'D20s", p. 8; "Rolling 20 or 1", p. 7)',
    path: 'unhappy (boundary)',
    mode: RollMode.advantage,
    dice: [1, 1],
    ability: 20,
    proficiency: null,
    others: [],
    ac: 5,
    criticalRange: null,
    expectation: _Resolves(21, D20TestOutcome.failure, false),
  ),
  (
    label: 'Disadvantage dice 20 and 20',
    requirement:
        'doc/specs/d20-tests.md FR-029 and FR-058 (SRD 5.2.1, "Roll Two '
        'D20s", p. 8; "Rolling 20 or 1", p. 7)',
    path: 'unhappy (boundary)',
    mode: RollMode.disadvantage,
    dice: [20, 20],
    ability: -3,
    proficiency: null,
    others: [],
    ac: 30,
    criticalRange: null,
    expectation: _Resolves(17, D20TestOutcome.success, true),
  ),
  (
    label: 'Advantage dice 12 and 5',
    requirement:
        'doc/specs/d20-tests.md FR-027 and FR-011 (SRD 5.2.1, "Attack Rolls", '
        'p. 7; "Roll Two D20s", p. 8)',
    path: 'happy',
    mode: RollMode.advantage,
    dice: [12, 5],
    ability: 3,
    proficiency: null,
    others: [],
    ac: 15,
    criticalRange: null,
    expectation: _Resolves(15, D20TestOutcome.success, false),
  ),
  (
    label: 'Advantage, natural 1 discarded',
    requirement:
        'doc/specs/d20-tests.md FR-032 and FR-011 (SRD 5.2.1, "Roll Two '
        'D20s", p. 8; "Rolling 20 or 1", p. 7)',
    path: 'unhappy (rule interaction)',
    mode: RollMode.advantage,
    dice: [1, 12],
    ability: 3,
    proficiency: null,
    others: [],
    ac: 15,
    criticalRange: null,
    expectation: _Resolves(15, D20TestOutcome.success, false),
  ),
  (
    label: 'very large bonus',
    requirement:
        'doc/specs/d20-tests.md FR-027 and FR-016 (SRD 5.2.1, "Attack Rolls", '
        'p. 7; "Add Modifiers", p. 6)',
    path: 'unhappy (boundary)',
    mode: RollMode.normal,
    dice: [10],
    ability: 100,
    proficiency: null,
    others: [],
    ac: 30,
    criticalRange: null,
    expectation: _Resolves(110, D20TestOutcome.success, false),
  ),
  (
    label: 'natural 20, very large penalty',
    requirement:
        'doc/specs/d20-tests.md FR-029 and FR-016 (SRD 5.2.1, "Rolling 20 or '
        '1", p. 7; "Add Modifiers", p. 6)',
    path: 'unhappy (boundary)',
    mode: RollMode.normal,
    dice: [20],
    ability: -100,
    proficiency: null,
    others: [],
    ac: 10,
    criticalRange: null,
    expectation: _Resolves(-80, D20TestOutcome.success, true),
  ),
  (
    label: 'natural 1, very large bonus',
    requirement:
        'doc/specs/d20-tests.md FR-030 and FR-016 (SRD 5.2.1, "Rolling 20 or '
        '1", p. 7; "Add Modifiers", p. 6)',
    path: 'unhappy (boundary)',
    mode: RollMode.normal,
    dice: [1],
    ability: 100,
    proficiency: null,
    others: [],
    ac: 10,
    criticalRange: null,
    expectation: _Resolves(101, D20TestOutcome.failure, false),
  ),
];

/// The three distinct outcomes the `hit` getter must mirror: a hit, a miss
/// and a Critical Hit (which is always a hit).
const List<_HitCase> _hitCases = [
  (
    label: 'a hit reports hit',
    requirement:
        'doc/specs/d20-tests.md FR-034 (SRD 5.2.1, "Attack Rolls", p. 7; '
        'doc/rules/architecture.md §6)',
    path: 'happy',
    dice: [10],
    ability: 5,
    ac: 15,
    hit: true,
  ),
  (
    label: 'a miss reports no hit',
    requirement:
        'doc/specs/d20-tests.md FR-034 (SRD 5.2.1, "Attack Rolls", p. 7; '
        'doc/rules/architecture.md §6)',
    path: 'happy',
    dice: [10],
    ability: 4,
    ac: 15,
    hit: false,
  ),
  (
    label: 'a Critical Hit reports hit',
    requirement:
        'doc/specs/d20-tests.md FR-034 and FR-051 (SRD 5.2.1, "Rolling 20 or '
        '1", p. 7; doc/rules/architecture.md §6)',
    path: 'happy',
    dice: [20],
    ability: 0,
    ac: 30,
    hit: true,
  ),
];

/// One FR-050 inequality case per `AttackRollResult` field: the result is
/// unequal when any single field differs. The critical-range field is FR-073.
const List<_InequalityCase> _attackInequalityCases = [
  (
    label: 'the roll differs',
    requirement: 'doc/specs/d20-tests.md FR-050 (doc/rules/architecture.md §3)',
    path: 'unhappy (any differing field)',
    field: _DifferingField.roll,
  ),
  (
    label: 'the modifiers differ',
    requirement: 'doc/specs/d20-tests.md FR-050 (doc/rules/architecture.md §3)',
    path: 'unhappy (any differing field)',
    field: _DifferingField.modifiers,
  ),
  (
    label: 'the total differs',
    requirement: 'doc/specs/d20-tests.md FR-050 (doc/rules/architecture.md §3)',
    path: 'unhappy (any differing field)',
    field: _DifferingField.total,
  ),
  (
    label: 'the target differs',
    requirement: 'doc/specs/d20-tests.md FR-050 (doc/rules/architecture.md §3)',
    path: 'unhappy (any differing field)',
    field: _DifferingField.target,
  ),
  (
    label: 'the outcome differs',
    requirement: 'doc/specs/d20-tests.md FR-050 (doc/rules/architecture.md §3)',
    path: 'unhappy (any differing field)',
    field: _DifferingField.outcome,
  ),
  (
    label: 'the critical-hit flag differs',
    requirement: 'doc/specs/d20-tests.md FR-050 (doc/rules/architecture.md §3)',
    path: 'unhappy (any differing field)',
    field: _DifferingField.isCriticalHit,
  ),
  (
    label: 'the critical range differs',
    requirement:
        'doc/specs/d20-tests.md FR-073 and FR-050 '
        '(doc/rules/architecture.md §3)',
    path: 'unhappy (any differing field)',
    field: _DifferingField.criticalRange,
  ),
];

/// One `adjustedBy` case at a widened critical range (FR-073): the original
/// resolves at the range, the adjustment re-resolves with the same range.
typedef _AdjustedRangeCase = ({
  String label,
  String requirement,
  String path,
  List<int> dice,
  int ability,
  int ac,
  int criticalRange,
  int delta,
  int total,
  D20TestOutcome outcome,
  bool isCriticalHit,
});

/// The FR-073 "adjustedBy keeps the range" cases of the d20-tests.md §8 test
/// plan: a natural at or above a widened range stays a Critical Hit at any
/// total after `adjustedBy`, and one below it stays a plain total result, so
/// dropping the range pass-through fails.
const List<_AdjustedRangeCase> _adjustedRangeCases = [
  (
    label: 'range 19: a natural 19 adjusted far down stays a Critical Hit',
    requirement:
        'doc/specs/d20-tests.md FR-073, FR-066 and FR-071 (SRD 5.2.1, '
        '"Critical Hit", p. 179; "Rolling 20 or 1", p. 7)',
    path: 'unhappy (boundary)',
    dice: [19],
    ability: -5,
    ac: 30,
    criticalRange: 19,
    delta: -100,
    total: -86,
    outcome: D20TestOutcome.success,
    isCriticalHit: true,
  ),
  (
    label: 'range 18: a natural 18 adjusted far down stays a Critical Hit',
    requirement:
        'doc/specs/d20-tests.md FR-073, FR-066 and FR-071 (SRD 5.2.1, '
        '"Critical Hit", p. 179; "Rolling 20 or 1", p. 7)',
    path: 'unhappy (boundary)',
    dice: [18],
    ability: 0,
    ac: 30,
    criticalRange: 18,
    delta: -50,
    total: -32,
    outcome: D20TestOutcome.success,
    isCriticalHit: true,
  ),
  (
    label: 'range 19: a natural 18 adjusted onto the AC is not a Critical Hit',
    requirement:
        'doc/specs/d20-tests.md FR-073 and FR-066 (SRD 5.2.1, "Critical Hit", '
        'p. 179; "Rolling 20 or 1", p. 7)',
    path: 'unhappy (boundary)',
    dice: [18],
    ability: 2,
    ac: 20,
    criticalRange: 19,
    delta: 0,
    total: 20,
    outcome: D20TestOutcome.success,
    isCriticalHit: false,
  ),
];

/// The modifiers of a table row: `A<ability>`, the optional Proficiency
/// Bonus and the other modifiers, in the spec's `A+3 P+2 O[+1, -2]` shape.
RollModifiers _modifiers(int ability, int? proficiency, List<int> others) =>
    RollModifiers(
      ability: Modifier(ability),
      proficiencyBonus: proficiency == null ? null : Modifier(proficiency),
      others: [for (final value in others) Modifier(value)],
    );

/// A fully specified result: a natural 10 with `A+3 P+2` against AC 15,
/// total 15, a hit, not a Critical Hit, default critical range.
AttackRollResult _baseResult() {
  final roll = D20Roll(mode: RollMode.normal, dice: [10]);
  final modifiers = RollModifiers(
    ability: const Modifier(3),
    proficiencyBonus: const Modifier(2),
  );
  return AttackRollResult(
    roll: roll,
    modifiers: modifiers,
    total: 15,
    target: const ArmorClass(15),
    outcome: D20TestOutcome.success,
    isCriticalHit: false,
  );
}

/// A copy of [_baseResult] with exactly one field replaced.
AttackRollResult _rebased({
  D20Roll? roll,
  RollModifiers? modifiers,
  int? total,
  ArmorClass? target,
  D20TestOutcome? outcome,
  bool? isCriticalHit,
  int? criticalRange,
}) {
  final base = _baseResult();
  return AttackRollResult(
    roll: roll ?? base.roll,
    modifiers: modifiers ?? base.modifiers,
    total: total ?? base.total,
    target: target ?? base.target,
    outcome: outcome ?? base.outcome,
    isCriticalHit: isCriticalHit ?? base.isCriticalHit,
    criticalRange: criticalRange ?? base.criticalRange,
  );
}

/// The [_DifferingField.field] variant of [_baseResult]: equal to it in
/// every other field, so the pair differs in exactly one field.
AttackRollResult _variant(_DifferingField field) => switch (field) {
  _DifferingField.roll => _rebased(
    roll: D20Roll(mode: RollMode.normal, dice: [11]),
  ),
  _DifferingField.modifiers => _rebased(
    modifiers: RollModifiers(
      ability: const Modifier(4),
      proficiencyBonus: const Modifier(2),
    ),
  ),
  _DifferingField.total => _rebased(total: 16),
  _DifferingField.target => _rebased(target: const ArmorClass(16)),
  _DifferingField.outcome => _rebased(outcome: D20TestOutcome.failure),
  _DifferingField.isCriticalHit => _rebased(isCriticalHit: true),
  _DifferingField.criticalRange => _rebased(criticalRange: 19),
};

void main() {
  /// Requirement: per case - the 28-row attack roll resolution table of
  ///   doc/specs/d20-tests.md section 4.5 (its "range 18: natural 20 and
  ///   natural 1" and "range 17 or 21" rows each name two cases, split into
  ///   two entries); each row cites its own ids and path. Resolving rows
  ///   also pin the fields FR-034 says the result carries - the roll, the
  ///   total, the ArmorClass target, the outcome, the critical-hit flag and
  ///   the hit getter - and the carried critical range of FR-073 (default
  ///   20 when the row omits it).
  /// Path: per case
  group('AttackRollResult.resolve attack roll resolution table', () {
    for (final c in _attackCases) {
      test('${c.label} [${c.path}] (${c.requirement})', () {
        final roll = D20Roll(mode: c.mode, dice: c.dice);
        final modifiers = _modifiers(c.ability, c.proficiency, c.others);
        final target = ArmorClass(c.ac);
        final expectation = c.expectation;
        switch (expectation) {
          case _Resolves(:final total, :final outcome, :final isCriticalHit):
            final result = c.criticalRange == null
                ? AttackRollResult.resolve(roll, modifiers, target)
                : AttackRollResult.resolve(
                    roll,
                    modifiers,
                    target,
                    criticalRange: c.criticalRange!,
                  );
            expect(result.roll, roll);
            expect(result.total, total);
            expect(result.target, target);
            expect(result.outcome, outcome);
            expect(result.isCriticalHit, isCriticalHit);
            expect(result.criticalRange, c.criticalRange ?? 20);
            expect(result.hit, outcome == D20TestOutcome.success);
          case _RejectsRange(:final invalidValue):
            // The exact runtime type is pinned: the guard throws ArgumentError
            // itself, never a subtype such as RangeError, so a mutant that let
            // an out-of-range value through to a comparison whose RangeError
            // carries the same name and invalidValue still fails.
            expect(
              () => AttackRollResult.resolve(
                roll,
                modifiers,
                target,
                criticalRange: c.criticalRange!,
              ),
              throwsA(
                isA<ArgumentError>()
                    .having((e) => e.runtimeType, 'runtimeType', ArgumentError)
                    .having((e) => e.name, 'name', 'criticalRange')
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

  /// Requirement: per case - doc/specs/d20-tests.md FR-073 - adjustedBy
  ///   re-resolves with the result's carried criticalRange ("adjustedBy keeps
  ///   the range", §8), so a natural at or above the range stays a Critical
  ///   Hit at any total (FR-066) and one below it resolves by its total
  ///   (FR-071); each row also pins FR-065's immutability and appended other.
  /// Path: per case
  group('AttackRollResult.adjustedBy keeps the critical range', () {
    for (final c in _adjustedRangeCases) {
      test('${c.label} [${c.path}] (${c.requirement})', () {
        final roll = D20Roll(mode: RollMode.normal, dice: c.dice);
        final modifiers = _modifiers(c.ability, null, const []);
        final target = ArmorClass(c.ac);
        final original = AttackRollResult.resolve(
          roll,
          modifiers,
          target,
          criticalRange: c.criticalRange,
        );

        final adjusted = original.adjustedBy(c.delta);

        expect(adjusted.criticalRange, c.criticalRange);
        expect(adjusted.roll, roll);
        expect(adjusted.target, target);
        expect(adjusted.total, c.total);
        expect(adjusted.outcome, c.outcome);
        expect(adjusted.isCriticalHit, c.isCriticalHit);
        expect(adjusted.hit, c.outcome == D20TestOutcome.success);
        expect(adjusted.modifiers.others, [Modifier(c.delta)]);
        expect(
          original,
          AttackRollResult.resolve(
            roll,
            modifiers,
            target,
            criticalRange: c.criticalRange,
          ),
        );
        expect(original.criticalRange, c.criticalRange);
      });
    }
  });

  /// Requirement: per case - doc/specs/d20-tests.md FR-034 - hit is exposed
  ///   as outcome == D20TestOutcome.success (SRD 5.2.1, "Attack Rolls",
  ///   p. 7; doc/rules/architecture.md §6).
  /// Path: per case
  group('AttackRollResult.hit getter', () {
    for (final c in _hitCases) {
      test('${c.label} [${c.path}] (${c.requirement})', () {
        final result = AttackRollResult.resolve(
          D20Roll(mode: RollMode.normal, dice: c.dice),
          _modifiers(c.ability, null, const []),
          ArmorClass(c.ac),
        );

        expect(result.hit, c.hit);
      });
    }
  });

  /// Requirement: doc/specs/d20-tests.md FR-050 - an AttackRollResult is
  ///   equal, with an equal hash code, when every field is equal
  ///   (doc/rules/architecture.md §3).
  /// Path: happy
  test('equal attack results are equal with equal hash codes', () {
    final a = _baseResult();
    final b = _baseResult();

    expect(a, b);
    expect(a.hashCode, b.hashCode);
  });

  /// Requirement: per case - doc/specs/d20-tests.md FR-050 - an
  ///   AttackRollResult is unequal when any single field differs; the
  ///   critical-range row also pins FR-073
  ///   (doc/rules/architecture.md §3).
  /// Path: per case
  group('attack results differing in one field are unequal', () {
    for (final c in _attackInequalityCases) {
      test('${c.label} [${c.path}] (${c.requirement})', () {
        expect(_variant(c.field), isNot(_baseResult()));
        expect(_baseResult(), isNot(_variant(c.field)));
      });
    }
  });

  /// Requirement: doc/specs/d20-tests.md FR-050 - an ArmorClass is equal,
  ///   with an equal hash code, when its value is equal
  ///   (doc/rules/architecture.md §3).
  /// Path: happy
  test('equal ArmorClass values are equal with equal hash codes', () {
    const a = ArmorClass(15);
    const b = ArmorClass(15);

    expect(a, b);
    expect(a.hashCode, b.hashCode);
  });

  /// Requirement: doc/specs/d20-tests.md FR-050 - an ArmorClass is unequal
  ///   when its value differs (doc/rules/architecture.md §3).
  /// Path: unhappy (any differing field)
  test('ArmorClass values differing in the value are unequal', () {
    expect(const ArmorClass(15), isNot(const ArmorClass(16)));
  });
}
