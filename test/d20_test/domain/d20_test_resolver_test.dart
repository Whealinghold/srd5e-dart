import 'package:srd5e/src/d20_test/domain/armor_class.dart';
import 'package:srd5e/src/d20_test/domain/attack_roll_result.dart';
import 'package:srd5e/src/d20_test/domain/check_result.dart';
import 'package:srd5e/src/d20_test/domain/d20_roll.dart';
import 'package:srd5e/src/d20_test/domain/d20_test_kind.dart';
import 'package:srd5e/src/d20_test/domain/d20_test_outcome.dart';
import 'package:srd5e/src/d20_test/domain/d20_test_resolver.dart';
import 'package:srd5e/src/d20_test/domain/difficulty_class.dart';
import 'package:srd5e/src/d20_test/domain/forced_failure_reason.dart';
import 'package:srd5e/src/d20_test/domain/forced_failure_result.dart';
import 'package:srd5e/src/d20_test/domain/roll_modifiers.dart';
import 'package:srd5e/src/shared_kernel/modifier.dart';
import 'package:srd5e/src/shared_kernel/roll_mode.dart';
import 'package:test/test.dart';

typedef _CheckCase = ({
  String label,
  String requirement,
  String path,
  int natural,
  int ability,
  int? proficiency,
  List<int> others,
  int total,
  int dc,
  D20TestOutcome outcome,
});

/// The 14-row check and save resolution table of `doc/specs/d20-tests.md`
/// section 4.5, in the order written there. Each row runs for both kinds:
/// `abilityCheck` and `savingThrow`.
const List<_CheckCase> _checkCases = [
  (
    label: 'total equals the DC',
    requirement:
        'doc/specs/d20-tests.md FR-023 and FR-025 (SRD 5.2.1, "Compare the '
        'Total to a Target Number", p. 6)',
    path: 'unhappy (boundary)',
    natural: 10,
    ability: 3,
    proficiency: 2,
    others: [],
    total: 15,
    dc: 15,
    outcome: D20TestOutcome.success,
  ),
  (
    label: 'total one below the DC',
    requirement:
        'doc/specs/d20-tests.md FR-024 and FR-026 (SRD 5.2.1, "Compare the '
        'Total to a Target Number", p. 6)',
    path: 'unhappy (boundary)',
    natural: 10,
    ability: 4,
    proficiency: null,
    others: [],
    total: 14,
    dc: 15,
    outcome: D20TestOutcome.failure,
  ),
  (
    label: 'total one above the DC',
    requirement:
        'doc/specs/d20-tests.md FR-023 and FR-025 (SRD 5.2.1, "Compare the '
        'Total to a Target Number", p. 6)',
    path: 'unhappy (boundary)',
    natural: 10,
    ability: 6,
    proficiency: null,
    others: [],
    total: 16,
    dc: 15,
    outcome: D20TestOutcome.success,
  ),
  (
    label: 'well above',
    requirement:
        'doc/specs/d20-tests.md FR-023 and FR-025 (SRD 5.2.1, "Compare the '
        'Total to a Target Number", p. 6)',
    path: 'happy',
    natural: 15,
    ability: 5,
    proficiency: 3,
    others: [],
    total: 23,
    dc: 10,
    outcome: D20TestOutcome.success,
  ),
  (
    label: 'well below',
    requirement:
        'doc/specs/d20-tests.md FR-024 and FR-026 (SRD 5.2.1, "Compare the '
        'Total to a Target Number", p. 6)',
    path: 'happy',
    natural: 3,
    ability: 0,
    proficiency: null,
    others: [],
    total: 3,
    dc: 20,
    outcome: D20TestOutcome.failure,
  ),
  (
    label: 'ability only meets the DC',
    requirement:
        'doc/specs/d20-tests.md FR-023 and FR-025 (SRD 5.2.1, "Compare the '
        'Total to a Target Number", p. 6)',
    path: 'unhappy (empty and minimal)',
    natural: 15,
    ability: 0,
    proficiency: null,
    others: [],
    total: 15,
    dc: 15,
    outcome: D20TestOutcome.success,
  ),
  (
    label: 'natural 20 below the DC fails',
    requirement:
        'doc/specs/d20-tests.md FR-024, FR-026 and FR-031 (SRD 5.2.1, '
        '"Compare the Total to a Target Number", p. 6; "Rolling 20 or 1", '
        'p. 7)',
    path: 'unhappy (rule interaction)',
    natural: 20,
    ability: -6,
    proficiency: null,
    others: [],
    total: 14,
    dc: 15,
    outcome: D20TestOutcome.failure,
  ),
  (
    label: 'natural 20 short of a high DC',
    requirement:
        'doc/specs/d20-tests.md FR-024, FR-026 and FR-031 (SRD 5.2.1, '
        '"Compare the Total to a Target Number", p. 6; "Rolling 20 or 1", '
        'p. 7)',
    path: 'unhappy (rule interaction)',
    natural: 20,
    ability: 0,
    proficiency: null,
    others: [],
    total: 20,
    dc: 30,
    outcome: D20TestOutcome.failure,
  ),
  (
    label: 'natural 1 above the DC succeeds',
    requirement:
        'doc/specs/d20-tests.md FR-023, FR-025 and FR-031 (SRD 5.2.1, '
        '"Compare the Total to a Target Number", p. 6; "Rolling 20 or 1", '
        'p. 7)',
    path: 'unhappy (rule interaction)',
    natural: 1,
    ability: 10,
    proficiency: null,
    others: [4],
    total: 15,
    dc: 15,
    outcome: D20TestOutcome.success,
  ),
  (
    label: 'natural 20 reaches DC 30',
    requirement:
        'doc/specs/d20-tests.md FR-023, FR-025 and FR-031 (SRD 5.2.1, '
        '"Compare the Total to a Target Number", p. 6; "Rolling 20 or 1", '
        'p. 7)',
    path: 'unhappy (boundary)',
    natural: 20,
    ability: 10,
    proficiency: null,
    others: [],
    total: 30,
    dc: 30,
    outcome: D20TestOutcome.success,
  ),
  (
    label: 'negative total',
    requirement:
        'doc/specs/d20-tests.md FR-024 and FR-026 (SRD 5.2.1, "Compare the '
        'Total to a Target Number", p. 6)',
    path: 'unhappy (boundary)',
    natural: 1,
    ability: -5,
    proficiency: null,
    others: [-2],
    total: -6,
    dc: 5,
    outcome: D20TestOutcome.failure,
  ),
  (
    label: 'DC 5, very easy, low roll',
    requirement:
        'doc/specs/d20-tests.md FR-023 and FR-025 (SRD 5.2.1, "Compare the '
        'Total to a Target Number", p. 6)',
    path: 'unhappy (boundary)',
    natural: 2,
    ability: 3,
    proficiency: null,
    others: [],
    total: 5,
    dc: 5,
    outcome: D20TestOutcome.success,
  ),
  (
    label: 'very large bonus',
    requirement:
        'doc/specs/d20-tests.md FR-023, FR-025 and FR-016 (SRD 5.2.1, '
        '"Compare the Total to a Target Number", p. 6)',
    path: 'unhappy (boundary)',
    natural: 1,
    ability: 100,
    proficiency: null,
    others: [],
    total: 101,
    dc: 30,
    outcome: D20TestOutcome.success,
  ),
  (
    label: 'very large penalty',
    requirement:
        'doc/specs/d20-tests.md FR-024, FR-026 and FR-016 (SRD 5.2.1, '
        '"Compare the Total to a Target Number", p. 6)',
    path: 'unhappy (boundary)',
    natural: 20,
    ability: -100,
    proficiency: null,
    others: [],
    total: -80,
    dc: 5,
    outcome: D20TestOutcome.failure,
  ),
];

/// What an attack-table case expects: the stated outcome and critical hit, or
/// a rejected critical range.
sealed class _AttackExpected {
  const _AttackExpected();
}

/// The attack resolves to this outcome and critical hit.
final class _AttackOutcome extends _AttackExpected {
  const _AttackOutcome(this.outcome, this.isCriticalHit);

  final D20TestOutcome outcome;
  final bool isCriticalHit;
}

/// The critical range is rejected through both forms.
final class _AttackRejectsRange extends _AttackExpected {
  const _AttackRejectsRange();
}

typedef _AttackCase = ({
  String label,
  String requirement,
  String path,
  RollMode mode,
  List<int> dice,
  int natural,
  int ability,
  int? proficiency,
  List<int> others,
  int total,
  int ac,
  int criticalRange,
  _AttackExpected expected,
});

/// The attack roll resolution table of `doc/specs/d20-tests.md` section 4.5,
/// in the order written there; the "range 18: natural 20 and natural 1" and
/// "range 17 or 21" rows are split into one case per natural value and per
/// rejected range.
const List<_AttackCase> _attackCases = [
  (
    label: 'total equals the AC',
    requirement:
        'doc/specs/d20-tests.md FR-027 (SRD 5.2.1, "Attack Rolls", p. 7)',
    path: 'unhappy (boundary)',
    mode: RollMode.normal,
    dice: [10],
    natural: 10,
    ability: 3,
    proficiency: 2,
    others: [],
    total: 15,
    ac: 15,
    criticalRange: 20,
    expected: _AttackOutcome(D20TestOutcome.success, false),
  ),
  (
    label: 'total one below the AC',
    requirement:
        'doc/specs/d20-tests.md FR-028 (SRD 5.2.1, "Attack Rolls", p. 7)',
    path: 'unhappy (boundary)',
    mode: RollMode.normal,
    dice: [10],
    natural: 10,
    ability: 4,
    proficiency: null,
    others: [],
    total: 14,
    ac: 15,
    criticalRange: 20,
    expected: _AttackOutcome(D20TestOutcome.failure, false),
  ),
  (
    label: 'total one above the AC',
    requirement:
        'doc/specs/d20-tests.md FR-027 (SRD 5.2.1, "Attack Rolls", p. 7)',
    path: 'unhappy (boundary)',
    mode: RollMode.normal,
    dice: [10],
    natural: 10,
    ability: 6,
    proficiency: null,
    others: [],
    total: 16,
    ac: 15,
    criticalRange: 20,
    expected: _AttackOutcome(D20TestOutcome.success, false),
  ),
  (
    label: 'natural 20 beats any AC',
    requirement:
        'doc/specs/d20-tests.md FR-029 and FR-051 (SRD 5.2.1, "Rolling 20 or '
        '1", p. 7; "Critical Hit", p. 179)',
    path: 'unhappy (boundary)',
    mode: RollMode.normal,
    dice: [20],
    natural: 20,
    ability: 0,
    proficiency: null,
    others: [],
    total: 20,
    ac: 15,
    criticalRange: 20,
    expected: _AttackOutcome(D20TestOutcome.success, true),
  ),
  (
    label: 'natural 20, total far below AC',
    requirement:
        'doc/specs/d20-tests.md FR-029 and FR-051 (SRD 5.2.1, "Rolling 20 or '
        '1", p. 7; "Critical Hit", p. 179)',
    path: 'unhappy (boundary)',
    mode: RollMode.normal,
    dice: [20],
    natural: 20,
    ability: -5,
    proficiency: null,
    others: [],
    total: 15,
    ac: 30,
    criticalRange: 20,
    expected: _AttackOutcome(D20TestOutcome.success, true),
  ),
  (
    label: 'natural 20, total equals AC',
    requirement:
        'doc/specs/d20-tests.md FR-029 and FR-051 (SRD 5.2.1, "Rolling 20 or '
        '1", p. 7; "Critical Hit", p. 179)',
    path: 'unhappy (boundary)',
    mode: RollMode.normal,
    dice: [20],
    natural: 20,
    ability: 5,
    proficiency: null,
    others: [],
    total: 25,
    ac: 25,
    criticalRange: 20,
    expected: _AttackOutcome(D20TestOutcome.success, true),
  ),
  (
    label: 'natural 20, total above AC',
    requirement:
        'doc/specs/d20-tests.md FR-029 and FR-051 (SRD 5.2.1, "Rolling 20 or '
        '1", p. 7; "Critical Hit", p. 179)',
    path: 'unhappy (boundary)',
    mode: RollMode.normal,
    dice: [20],
    natural: 20,
    ability: 10,
    proficiency: null,
    others: [],
    total: 30,
    ac: 15,
    criticalRange: 20,
    expected: _AttackOutcome(D20TestOutcome.success, true),
  ),
  (
    label: 'natural 1 misses a low AC',
    requirement:
        'doc/specs/d20-tests.md FR-030 and FR-051 (SRD 5.2.1, "Rolling 20 or '
        '1", p. 7)',
    path: 'unhappy (boundary)',
    mode: RollMode.normal,
    dice: [1],
    natural: 1,
    ability: 12,
    proficiency: null,
    others: [],
    total: 13,
    ac: 10,
    criticalRange: 20,
    expected: _AttackOutcome(D20TestOutcome.failure, false),
  ),
  (
    label: 'natural 1, total far above AC',
    requirement:
        'doc/specs/d20-tests.md FR-030 and FR-051 (SRD 5.2.1, "Rolling 20 or '
        '1", p. 7)',
    path: 'unhappy (boundary)',
    mode: RollMode.normal,
    dice: [1],
    natural: 1,
    ability: 20,
    proficiency: null,
    others: [],
    total: 21,
    ac: 5,
    criticalRange: 20,
    expected: _AttackOutcome(D20TestOutcome.failure, false),
  ),
  (
    label: 'natural 1, total also below AC',
    requirement:
        'doc/specs/d20-tests.md FR-030 and FR-051 (SRD 5.2.1, "Rolling 20 or '
        '1", p. 7)',
    path: 'unhappy (boundary)',
    mode: RollMode.normal,
    dice: [1],
    natural: 1,
    ability: 2,
    proficiency: null,
    others: [],
    total: 3,
    ac: 15,
    criticalRange: 20,
    expected: _AttackOutcome(D20TestOutcome.failure, false),
  ),
  (
    label: 'natural 19 one below AC',
    requirement:
        'doc/specs/d20-tests.md FR-033 (SRD 5.2.1, "Rolling 20 or 1", p. 7)',
    path: 'unhappy (boundary)',
    mode: RollMode.normal,
    dice: [19],
    natural: 19,
    ability: 0,
    proficiency: null,
    others: [],
    total: 19,
    ac: 20,
    criticalRange: 20,
    expected: _AttackOutcome(D20TestOutcome.failure, false),
  ),
  (
    label: 'natural 19 above AC is not critical',
    requirement:
        'doc/specs/d20-tests.md FR-033 (SRD 5.2.1, "Rolling 20 or 1", p. 7)',
    path: 'unhappy (boundary)',
    mode: RollMode.normal,
    dice: [19],
    natural: 19,
    ability: 10,
    proficiency: null,
    others: [],
    total: 29,
    ac: 20,
    criticalRange: 20,
    expected: _AttackOutcome(D20TestOutcome.success, false),
  ),
  (
    label: 'range 19: natural 19 crits below AC',
    requirement:
        'doc/specs/d20-tests.md FR-071 (SRD 5.2.1, "Critical Hit", p. 179)',
    path: 'unhappy (boundary)',
    mode: RollMode.normal,
    dice: [19],
    natural: 19,
    ability: -5,
    proficiency: null,
    others: [],
    total: 14,
    ac: 30,
    criticalRange: 19,
    expected: _AttackOutcome(D20TestOutcome.success, true),
  ),
  (
    label: 'range 19: natural 18 does not',
    requirement:
        'doc/specs/d20-tests.md FR-071 and FR-028 (SRD 5.2.1, "Critical Hit", '
        'p. 179; "Attack Rolls", p. 7)',
    path: 'unhappy (boundary)',
    mode: RollMode.normal,
    dice: [18],
    natural: 18,
    ability: 0,
    proficiency: null,
    others: [],
    total: 18,
    ac: 30,
    criticalRange: 19,
    expected: _AttackOutcome(D20TestOutcome.failure, false),
  ),
  (
    label: 'range 18: natural 18 crits below AC',
    requirement:
        'doc/specs/d20-tests.md FR-071 (SRD 5.2.1, "Critical Hit", p. 179)',
    path: 'unhappy (boundary)',
    mode: RollMode.normal,
    dice: [18],
    natural: 18,
    ability: 0,
    proficiency: null,
    others: [],
    total: 18,
    ac: 30,
    criticalRange: 18,
    expected: _AttackOutcome(D20TestOutcome.success, true),
  ),
  (
    label: 'range 18: natural 17 does not',
    requirement:
        'doc/specs/d20-tests.md FR-071 and FR-028 (SRD 5.2.1, "Critical Hit", '
        'p. 179; "Attack Rolls", p. 7)',
    path: 'unhappy (boundary)',
    mode: RollMode.normal,
    dice: [17],
    natural: 17,
    ability: 0,
    proficiency: null,
    others: [],
    total: 17,
    ac: 30,
    criticalRange: 18,
    expected: _AttackOutcome(D20TestOutcome.failure, false),
  ),
  (
    label: 'range 18: natural 20',
    requirement:
        'doc/specs/d20-tests.md FR-071 and FR-029 (SRD 5.2.1, "Critical Hit", '
        'p. 179; "Rolling 20 or 1", p. 7)',
    path: 'unhappy (boundary)',
    mode: RollMode.normal,
    dice: [20],
    natural: 20,
    ability: 0,
    proficiency: null,
    others: [],
    total: 20,
    ac: 30,
    criticalRange: 18,
    expected: _AttackOutcome(D20TestOutcome.success, true),
  ),
  (
    label: 'range 18: natural 1',
    requirement:
        'doc/specs/d20-tests.md FR-071 and FR-030 (SRD 5.2.1, "Critical Hit", '
        'p. 179; "Rolling 20 or 1", p. 7)',
    path: 'unhappy (boundary)',
    mode: RollMode.normal,
    dice: [1],
    natural: 1,
    ability: 0,
    proficiency: null,
    others: [],
    total: 1,
    ac: 30,
    criticalRange: 18,
    expected: _AttackOutcome(D20TestOutcome.failure, false),
  ),
  (
    label: 'range 17 is rejected',
    requirement:
        'doc/specs/d20-tests.md FR-072 (SRD 5.2.1, "Critical Hit", p. 179; '
        '"Level 3: Improved Critical", p. 49)',
    path: 'unhappy (invalid input)',
    mode: RollMode.normal,
    dice: [10],
    natural: 10,
    ability: 0,
    proficiency: null,
    others: [],
    total: 10,
    ac: 15,
    criticalRange: 17,
    expected: _AttackRejectsRange(),
  ),
  (
    label: 'range 21 is rejected',
    requirement:
        'doc/specs/d20-tests.md FR-072 (SRD 5.2.1, "Critical Hit", p. 179; '
        '"Rolling 20 or 1", p. 7)',
    path: 'unhappy (invalid input)',
    mode: RollMode.normal,
    dice: [10],
    natural: 10,
    ability: 0,
    proficiency: null,
    others: [],
    total: 10,
    ac: 15,
    criticalRange: 21,
    expected: _AttackRejectsRange(),
  ),
  (
    label: 'natural 2 above AC',
    requirement:
        'doc/specs/d20-tests.md FR-027 (SRD 5.2.1, "Attack Rolls", p. 7)',
    path: 'happy',
    mode: RollMode.normal,
    dice: [2],
    natural: 2,
    ability: 10,
    proficiency: null,
    others: [4],
    total: 16,
    ac: 15,
    criticalRange: 20,
    expected: _AttackOutcome(D20TestOutcome.success, false),
  ),
  (
    label: 'Advantage dice 20 and 1',
    requirement:
        'doc/specs/d20-tests.md FR-032 and FR-029 (SRD 5.2.1, "Roll Two D20s", '
        'p. 8; "Rolling 20 or 1", p. 7)',
    path: 'unhappy (rule interaction)',
    mode: RollMode.advantage,
    dice: [20, 1],
    natural: 20,
    ability: 0,
    proficiency: null,
    others: [],
    total: 20,
    ac: 15,
    criticalRange: 20,
    expected: _AttackOutcome(D20TestOutcome.success, true),
  ),
  (
    label: 'Disadvantage dice 20 and 1',
    requirement:
        'doc/specs/d20-tests.md FR-032 and FR-030 (SRD 5.2.1, "Roll Two D20s", '
        'p. 8; "Rolling 20 or 1", p. 7)',
    path: 'unhappy (rule interaction)',
    mode: RollMode.disadvantage,
    dice: [20, 1],
    natural: 1,
    ability: 20,
    proficiency: null,
    others: [],
    total: 21,
    ac: 5,
    criticalRange: 20,
    expected: _AttackOutcome(D20TestOutcome.failure, false),
  ),
  (
    label: 'Advantage dice 1 and 1',
    requirement:
        'doc/specs/d20-tests.md FR-030 and FR-011 (SRD 5.2.1, "Roll Two D20s", '
        'p. 8; "Rolling 20 or 1", p. 7)',
    path: 'unhappy (boundary)',
    mode: RollMode.advantage,
    dice: [1, 1],
    natural: 1,
    ability: 20,
    proficiency: null,
    others: [],
    total: 21,
    ac: 5,
    criticalRange: 20,
    expected: _AttackOutcome(D20TestOutcome.failure, false),
  ),
  (
    label: 'Disadvantage dice 20 and 20',
    requirement:
        'doc/specs/d20-tests.md FR-029 and FR-011 (SRD 5.2.1, "Roll Two D20s", '
        'p. 8; "Rolling 20 or 1", p. 7)',
    path: 'unhappy (boundary)',
    mode: RollMode.disadvantage,
    dice: [20, 20],
    natural: 20,
    ability: -3,
    proficiency: null,
    others: [],
    total: 17,
    ac: 30,
    criticalRange: 20,
    expected: _AttackOutcome(D20TestOutcome.success, true),
  ),
  (
    label: 'Advantage dice 12 and 5',
    requirement:
        'doc/specs/d20-tests.md FR-027 and FR-011 (SRD 5.2.1, "Roll Two D20s", '
        'p. 8; "Attack Rolls", p. 7)',
    path: 'happy',
    mode: RollMode.advantage,
    dice: [12, 5],
    natural: 12,
    ability: 3,
    proficiency: null,
    others: [],
    total: 15,
    ac: 15,
    criticalRange: 20,
    expected: _AttackOutcome(D20TestOutcome.success, false),
  ),
  (
    label: 'Advantage, natural 1 discarded',
    requirement:
        'doc/specs/d20-tests.md FR-032 (SRD 5.2.1, "Roll Two D20s", p. 8; '
        '"Rolling 20 or 1", p. 7)',
    path: 'unhappy (rule interaction)',
    mode: RollMode.advantage,
    dice: [1, 12],
    natural: 12,
    ability: 3,
    proficiency: null,
    others: [],
    total: 15,
    ac: 15,
    criticalRange: 20,
    expected: _AttackOutcome(D20TestOutcome.success, false),
  ),
  (
    label: 'very large bonus',
    requirement:
        'doc/specs/d20-tests.md FR-027 and FR-016 (SRD 5.2.1, "Attack Rolls", '
        'p. 7; "Add Modifiers", p. 6)',
    path: 'unhappy (boundary)',
    mode: RollMode.normal,
    dice: [10],
    natural: 10,
    ability: 100,
    proficiency: null,
    others: [],
    total: 110,
    ac: 30,
    criticalRange: 20,
    expected: _AttackOutcome(D20TestOutcome.success, false),
  ),
  (
    label: 'natural 20, very large penalty',
    requirement:
        'doc/specs/d20-tests.md FR-029, FR-051 and FR-016 (SRD 5.2.1, '
        '"Rolling 20 or 1", p. 7; "Add Modifiers", p. 6)',
    path: 'unhappy (boundary)',
    mode: RollMode.normal,
    dice: [20],
    natural: 20,
    ability: -100,
    proficiency: null,
    others: [],
    total: -80,
    ac: 10,
    criticalRange: 20,
    expected: _AttackOutcome(D20TestOutcome.success, true),
  ),
  (
    label: 'natural 1, very large bonus',
    requirement:
        'doc/specs/d20-tests.md FR-030, FR-051 and FR-016 (SRD 5.2.1, '
        '"Rolling 20 or 1", p. 7; "Add Modifiers", p. 6)',
    path: 'unhappy (boundary)',
    mode: RollMode.normal,
    dice: [1],
    natural: 1,
    ability: 100,
    proficiency: null,
    others: [],
    total: 101,
    ac: 10,
    criticalRange: 20,
    expected: _AttackOutcome(D20TestOutcome.failure, false),
  ),
];

/// What a forced-failure case expects: the failure result, or a rejection.
sealed class _ForcedExpected {
  const _ForcedExpected();
}

/// Both forms produce the failure result of the case's kind and reason.
final class _FailureWithoutRoll extends _ForcedExpected {
  const _FailureWithoutRoll();
}

/// Both forms throw an ArgumentError with this name and invalidValue.
final class _Rejects extends _ForcedExpected {
  const _Rejects(this.argumentName, this.invalidValue);

  final String argumentName;
  final Object invalidValue;
}

typedef _ForcedCase = ({
  String label,
  String requirement,
  String path,
  D20TestKind kind,
  ForcedFailureReason reason,
  _ForcedExpected expected,
});

/// The forced-failure table of `doc/specs/d20-tests.md` section 4.5, in the
/// order written there.
const List<_ForcedCase> _forcedCases = [
  (
    label: 'chosen to fail a save',
    requirement:
        'doc/specs/d20-tests.md FR-035 (SRD 5.2.1, "Saving Throws", p. 7)',
    path: 'happy',
    kind: D20TestKind.savingThrow,
    reason: ForcedFailureReason.chosenToFail,
    expected: _FailureWithoutRoll(),
  ),
  (
    label: 'automatic failure of a save',
    requirement: 'doc/specs/d20-tests.md FR-036 (SRD 5.2.1, "Object", p. 178)',
    path: 'happy',
    kind: D20TestKind.savingThrow,
    reason: ForcedFailureReason.automatic,
    expected: _FailureWithoutRoll(),
  ),
  (
    label: 'automatic failure of a check',
    requirement:
        'doc/specs/d20-tests.md FR-036 (SRD 5.2.1, "Blinded", p. 177; '
        '"Deafened", p. 181)',
    path: 'happy',
    kind: D20TestKind.abilityCheck,
    reason: ForcedFailureReason.automatic,
    expected: _FailureWithoutRoll(),
  ),
  (
    label: 'chosen to fail a check',
    requirement:
        'doc/specs/d20-tests.md FR-052 (SRD 5.2.1, "Saving Throws", p. 7; '
        '"D20 Tests", p. 6)',
    path: 'unhappy (invalid input)',
    kind: D20TestKind.abilityCheck,
    reason: ForcedFailureReason.chosenToFail,
    expected: _Rejects('reason', ForcedFailureReason.chosenToFail),
  ),
  (
    label: 'forced failure of an attack roll',
    requirement:
        'doc/specs/d20-tests.md FR-052 (SRD 5.2.1, "Attack Rolls", p. 7)',
    path: 'unhappy (invalid input)',
    kind: D20TestKind.attackRoll,
    reason: ForcedFailureReason.automatic,
    expected: _Rejects('kind', D20TestKind.attackRoll),
  ),
  (
    label: 'forced failure of an attack roll, chosen',
    requirement:
        'doc/specs/d20-tests.md FR-052 (SRD 5.2.1, "Attack Rolls", p. 7)',
    path: 'unhappy (invalid input)',
    kind: D20TestKind.attackRoll,
    reason: ForcedFailureReason.chosenToFail,
    expected: _Rejects('kind', D20TestKind.attackRoll),
  ),
];

/// Builds the modifiers of a case from its plain values.
RollModifiers _modifiers(int ability, int? proficiency, List<int> others) =>
    RollModifiers(
      ability: Modifier(ability),
      proficiencyBonus: proficiency == null ? null : Modifier(proficiency),
      others: [for (final value in others) Modifier(value)],
    );

/// Matches the ArgumentError the guards throw: the exact runtime type (never
/// a subtype such as RangeError), the argument name and the invalid value.
/// Never the message text.
Matcher _argumentError(String name, Object? invalidValue) => throwsA(
  isA<ArgumentError>()
      .having((e) => e.runtimeType, 'runtimeType', ArgumentError)
      .having((e) => e.name, 'name', name)
      .having((e) => e.invalidValue, 'invalidValue', invalidValue),
);

/// The label of a kind, for the generated test names.
String _kindLabel(D20TestKind kind) => switch (kind) {
  D20TestKind.abilityCheck => 'ability check',
  D20TestKind.savingThrow => 'saving throw',
  D20TestKind.attackRoll => 'attack roll',
};

void main() {
  /// Requirement: per case - doc/specs/d20-tests.md FR-069 and FR-070 - the
  ///   check and save resolution table of section 4.5, run for both kinds,
  ///   through both `D20TestResolver.resolveCheck` and `CheckResult.resolve`;
  ///   the results are equal, with equal hash codes, and each row carries the
  ///   total and outcome the table states. Each row cites its own ids and
  ///   path.
  /// Path: per case
  group('check resolution rows through the resolver and the static member', () {
    for (final kind in const [
      D20TestKind.abilityCheck,
      D20TestKind.savingThrow,
    ]) {
      for (final c in _checkCases) {
        test(
          '${c.label}, ${_kindLabel(kind)} [${c.path}] (${c.requirement})',
          () {
            final roll = D20Roll(mode: RollMode.normal, dice: [c.natural]);
            final modifiers = _modifiers(c.ability, c.proficiency, c.others);
            final target = DifficultyClass(c.dc);

            final viaResolver = const D20TestResolver().resolveCheck(
              kind,
              roll,
              modifiers,
              target,
            );
            final viaStatic = CheckResult.resolve(
              kind,
              roll,
              modifiers,
              target,
            );

            expect(viaResolver, viaStatic);
            expect(viaResolver.hashCode, viaStatic.hashCode);
            expect(viaResolver.kind, kind);
            expect(viaResolver.roll, roll);
            expect(viaResolver.modifiers, modifiers);
            expect(viaResolver.target, target);
            expect(viaResolver.total, c.total);
            expect(viaResolver.outcome, c.outcome);
          },
        );
      }
    }

    /// Requirement: doc/specs/d20-tests.md FR-062, FR-069 and FR-070 -
    ///   resolveCheck rejects a kind of attackRoll, through both
    ///   `D20TestResolver.resolveCheck` and `CheckResult.resolve`, with the
    ///   same ArgumentError (SRD 5.2.1, "Ability Checks", p. 6; "Attack
    ///   Rolls", p. 7).
    /// Path: unhappy (invalid input)
    test('resolveCheck rejects an attack roll through both forms', () {
      final roll = D20Roll(mode: RollMode.normal, dice: const [10]);
      final modifiers = _modifiers(0, null, const []);
      const target = DifficultyClass(15);

      expect(
        () => const D20TestResolver().resolveCheck(
          D20TestKind.attackRoll,
          roll,
          modifiers,
          target,
        ),
        _argumentError('kind', D20TestKind.attackRoll),
      );
      expect(
        () => CheckResult.resolve(
          D20TestKind.attackRoll,
          roll,
          modifiers,
          target,
        ),
        _argumentError('kind', D20TestKind.attackRoll),
      );
    });
  });

  /// Requirement: per case - doc/specs/d20-tests.md FR-069 and FR-070 - the
  ///   attack roll resolution table of section 4.5 through both
  ///   `D20TestResolver.resolveAttackRoll` and `AttackRollResult.resolve`;
  ///   the results are equal, with equal hash codes, and each row carries the
  ///   natural, total, outcome and critical hit the table states. Each row
  ///   cites its own ids and path.
  /// Path: per case
  group('attack rows through the resolver and the static member', () {
    for (final c in _attackCases) {
      test('${c.label} [${c.path}] (${c.requirement})', () {
        final roll = D20Roll(mode: c.mode, dice: c.dice);
        final modifiers = _modifiers(c.ability, c.proficiency, c.others);
        final target = ArmorClass(c.ac);
        final expected = c.expected;

        switch (expected) {
          case _AttackOutcome(:final outcome, :final isCriticalHit):
            final viaResolver = const D20TestResolver().resolveAttackRoll(
              roll,
              modifiers,
              target,
              criticalRange: c.criticalRange,
            );
            final viaStatic = AttackRollResult.resolve(
              roll,
              modifiers,
              target,
              criticalRange: c.criticalRange,
            );

            expect(viaResolver, viaStatic);
            expect(viaResolver.hashCode, viaStatic.hashCode);
            expect(viaResolver.roll.natural, c.natural);
            expect(viaResolver.total, c.total);
            expect(viaResolver.outcome, outcome);
            expect(viaResolver.isCriticalHit, isCriticalHit);
            expect(viaResolver.criticalRange, c.criticalRange);
          case _AttackRejectsRange():
            expect(
              () => const D20TestResolver().resolveAttackRoll(
                roll,
                modifiers,
                target,
                criticalRange: c.criticalRange,
              ),
              _argumentError('criticalRange', c.criticalRange),
            );
            expect(
              () => AttackRollResult.resolve(
                roll,
                modifiers,
                target,
                criticalRange: c.criticalRange,
              ),
              _argumentError('criticalRange', c.criticalRange),
            );
        }
      });
    }
  });

  /// Requirement: per case - doc/specs/d20-tests.md FR-069 and FR-070 - the
  ///   forced-failure table of section 4.5 through both
  ///   `D20TestResolver.forcedFailure` and `ForcedFailureResult.of`; the
  ///   results are equal, with equal hash codes, and the invalid rows throw
  ///   the same ArgumentError through both forms. Each row cites its own ids
  ///   and path.
  /// Path: per case
  group('forced-failure rows through the resolver and the static member', () {
    for (final c in _forcedCases) {
      test('${c.label} [${c.path}] (${c.requirement})', () {
        final expected = c.expected;

        switch (expected) {
          case _FailureWithoutRoll():
            final viaResolver = const D20TestResolver().forcedFailure(
              c.kind,
              c.reason,
            );
            final viaStatic = ForcedFailureResult.of(c.kind, c.reason);

            expect(viaResolver, viaStatic);
            expect(viaResolver.hashCode, viaStatic.hashCode);
            expect(viaResolver.kind, c.kind);
            expect(viaResolver.reason, c.reason);
          case _Rejects(:final argumentName, :final invalidValue):
            expect(
              () => const D20TestResolver().forcedFailure(c.kind, c.reason),
              _argumentError(argumentName, invalidValue),
            );
            expect(
              () => ForcedFailureResult.of(c.kind, c.reason),
              _argumentError(argumentName, invalidValue),
            );
        }
      });
    }
  });
}
