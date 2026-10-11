import 'package:srd5e/src/d20_test/domain/check_result.dart';
import 'package:srd5e/src/d20_test/domain/d20_roll.dart';
import 'package:srd5e/src/d20_test/domain/d20_test_kind.dart';
import 'package:srd5e/src/d20_test/domain/d20_test_outcome.dart';
import 'package:srd5e/src/d20_test/domain/difficulty_class.dart';
import 'package:srd5e/src/d20_test/domain/roll_modifiers.dart';
import 'package:srd5e/src/shared_kernel/modifier.dart';
import 'package:srd5e/src/shared_kernel/roll_mode.dart';
import 'package:test/test.dart';

/// The two kinds a Difficulty Class is resolved for: the check-and-save table
/// is run for both. `attackRoll` is not one of them; FR-062 rejects it.
const List<(String, D20TestKind)> _kinds = [
  ('ability check', D20TestKind.abilityCheck),
  ('saving throw', D20TestKind.savingThrow),
];

typedef _ResolutionCase = ({
  String label,
  String requirement,
  String path,
  int natural,
  int ability,
  int? proficiency,
  List<int> others,
  int total,
  DifficultyClass dc,
  D20TestOutcome outcome,
});

/// The 14-row check and save resolution table of
/// `doc/specs/d20-tests.md` section 4.5, in the order written there. Every
/// row is run for both kinds, so a row's ids name the requirement per kind:
/// FR-023/FR-024 for the ability check, FR-025/FR-026 for the saving throw.
const List<_ResolutionCase> _resolutionCases = [
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
    dc: DifficultyClass(15),
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
    dc: DifficultyClass(15),
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
    dc: DifficultyClass(15),
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
    dc: DifficultyClass(10),
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
    dc: DifficultyClass(20),
    outcome: D20TestOutcome.failure,
  ),
  (
    label: 'ability only meets the DC',
    requirement:
        'doc/specs/d20-tests.md FR-017, FR-023 and FR-025 (SRD 5.2.1, "Add '
        'Modifiers", p. 6)',
    path: 'unhappy (empty and minimal)',
    natural: 15,
    ability: 0,
    proficiency: null,
    others: [],
    total: 15,
    dc: DifficultyClass(15),
    outcome: D20TestOutcome.success,
  ),
  (
    label: 'natural 20 below the DC fails',
    requirement:
        'doc/specs/d20-tests.md FR-031, FR-024 and FR-026 (SRD 5.2.1, '
        '"Rolling 20 or 1", p. 7, "for an attack roll")',
    path: 'unhappy (rule interaction)',
    natural: 20,
    ability: -6,
    proficiency: null,
    others: [],
    total: 14,
    dc: DifficultyClass(15),
    outcome: D20TestOutcome.failure,
  ),
  (
    label: 'natural 20 short of a high DC',
    requirement:
        'doc/specs/d20-tests.md FR-031 (SRD 5.2.1, "Rolling 20 or 1", p. 7, '
        '"for an attack roll")',
    path: 'unhappy (rule interaction)',
    natural: 20,
    ability: 0,
    proficiency: null,
    others: [],
    total: 20,
    dc: DifficultyClass(30),
    outcome: D20TestOutcome.failure,
  ),
  (
    label: 'natural 1 above the DC succeeds',
    requirement:
        'doc/specs/d20-tests.md FR-031 (SRD 5.2.1, "Rolling 20 or 1", p. 7, '
        '"for an attack roll")',
    path: 'unhappy (rule interaction)',
    natural: 1,
    ability: 10,
    proficiency: null,
    others: [4],
    total: 15,
    dc: DifficultyClass(15),
    outcome: D20TestOutcome.success,
  ),
  (
    label: 'natural 20 reaches DC 30',
    requirement:
        'doc/specs/d20-tests.md FR-023 and FR-025 (SRD 5.2.1, "Compare the '
        'Total to a Target Number", p. 6)',
    path: 'unhappy (boundary)',
    natural: 20,
    ability: 10,
    proficiency: null,
    others: [],
    total: 30,
    dc: DifficultyClass(30),
    outcome: D20TestOutcome.success,
  ),
  (
    label: 'negative total',
    requirement:
        'doc/specs/d20-tests.md FR-019, FR-024 and FR-026 (SRD 5.2.1, "Add '
        'Modifiers", p. 6)',
    path: 'unhappy (boundary)',
    natural: 1,
    ability: -5,
    proficiency: null,
    others: [-2],
    total: -6,
    dc: DifficultyClass(5),
    outcome: D20TestOutcome.failure,
  ),
  (
    label: 'DC 5, very easy, low roll',
    requirement:
        'doc/specs/d20-tests.md FR-021, FR-023 and FR-025 (SRD 5.2.1, '
        'Typical Difficulty Classes table, p. 6)',
    path: 'unhappy (boundary)',
    natural: 2,
    ability: 3,
    proficiency: null,
    others: [],
    total: 5,
    dc: DifficultyClass.veryEasy,
    outcome: D20TestOutcome.success,
  ),
  (
    label: 'very large bonus',
    requirement:
        'doc/specs/d20-tests.md FR-016, FR-023 and FR-025 (SRD 5.2.1, "Add '
        'Modifiers", p. 6)',
    path: 'unhappy (boundary)',
    natural: 1,
    ability: 100,
    proficiency: null,
    others: [],
    total: 101,
    dc: DifficultyClass(30),
    outcome: D20TestOutcome.success,
  ),
  (
    label: 'very large penalty',
    requirement:
        'doc/specs/d20-tests.md FR-016, FR-024 and FR-026 (SRD 5.2.1, "Add '
        'Modifiers", p. 6)',
    path: 'unhappy (boundary)',
    natural: 20,
    ability: -100,
    proficiency: null,
    others: [],
    total: -80,
    dc: DifficultyClass(5),
    outcome: D20TestOutcome.failure,
  ),
];

/// The modifiers a case describes: one ability modifier, the optional
/// Proficiency Bonus and the other modifiers as `Modifier`s.
RollModifiers _modifiers(int ability, int? proficiencyBonus, List<int> others) {
  return RollModifiers(
    ability: Modifier(ability),
    proficiencyBonus: proficiencyBonus == null
        ? null
        : Modifier(proficiencyBonus),
    others: [for (final value in others) Modifier(value)],
  );
}

void main() {
  /// Requirement: per case - the 14-row check and save resolution table of
  ///   doc/specs/d20-tests.md section 4.5, run for both kinds; each row cites
  ///   its own ids and path. The natural 20 and natural 1 rows resolve by the
  ///   total alone: the SRD states those rules "for an attack roll" only
  ///   (p. 7), and a CheckResult has no critical-hit field to set (FR-031;
  ///   that half is enforced by the analyzer).
  /// Path: per case
  group('CheckResult.resolve check and save resolution table', () {
    for (final (kindLabel, kind) in _kinds) {
      for (final c in _resolutionCases) {
        test('${c.label}, $kindLabel [${c.path}] (${c.requirement})', () {
          final roll = D20Roll(mode: RollMode.normal, dice: [c.natural]);
          final modifiers = _modifiers(c.ability, c.proficiency, c.others);

          final result = CheckResult.resolve(kind, roll, modifiers, c.dc);

          expect(result.kind, kind);
          expect(result.roll, roll);
          expect(result.modifiers, modifiers);
          expect(result.total, c.total);
          expect(result.target, c.dc);
          expect(result.outcome, c.outcome);
        });
      }
    }
  });
}
