import 'package:srd5e/src/d20_test/domain/armor_class.dart';
import 'package:srd5e/src/d20_test/domain/attack_roll_result.dart';
import 'package:srd5e/src/d20_test/domain/check_result.dart';
import 'package:srd5e/src/d20_test/domain/d20_roll.dart';
import 'package:srd5e/src/d20_test/domain/d20_test_kind.dart';
import 'package:srd5e/src/d20_test/domain/difficulty_class.dart';
import 'package:srd5e/src/d20_test/domain/roll_modifiers.dart';
import 'package:srd5e/src/shared_kernel/modifier.dart';
import 'package:srd5e/src/shared_kernel/roll_mode.dart';
import 'package:test/test.dart';

typedef _TotalCase = ({
  String label,
  String requirement,
  String path,
  int natural,
  int ability,
  int? proficiency,
  List<int> others,
  int expectedTotal,
});

/// The 12-row total table of `doc/specs/d20-tests.md` section 4.3, in the
/// order written there. The target numbers the resolves run against are
/// arbitrary: the table pins the total, not the outcome.
const List<_TotalCase> _totalCases = [
  (
    label: 'ability only, zero',
    requirement:
        'doc/specs/d20-tests.md FR-016 and FR-017 (SRD 5.2.1, "Add '
        'Modifiers", p. 6)',
    path: 'unhappy (empty and minimal)',
    natural: 10,
    ability: 0,
    proficiency: null,
    others: [],
    expectedTotal: 10,
  ),
  (
    label: 'zero other modifier',
    requirement:
        'doc/specs/d20-tests.md FR-016 and FR-017 (SRD 5.2.1, "Add '
        'Modifiers", p. 6)',
    path: 'unhappy (empty and minimal)',
    natural: 10,
    ability: 0,
    proficiency: null,
    others: [0],
    expectedTotal: 10,
  ),
  (
    label: 'single bonus',
    requirement:
        'doc/specs/d20-tests.md FR-016 and FR-017 (SRD 5.2.1, "Add '
        'Modifiers", p. 6)',
    path: 'happy',
    natural: 10,
    ability: 3,
    proficiency: null,
    others: [],
    expectedTotal: 13,
  ),
  (
    label: 'ability and Proficiency Bonus',
    requirement:
        'doc/specs/d20-tests.md FR-016 and FR-018 (SRD 5.2.1, "Add '
        'Modifiers", p. 6; "The Bonus Doesn\'t Stack", p. 8)',
    path: 'happy',
    natural: 10,
    ability: 3,
    proficiency: 2,
    others: [],
    expectedTotal: 15,
  ),
  (
    label: 'bonuses and penalties',
    requirement:
        'doc/specs/d20-tests.md FR-016 and FR-019 (SRD 5.2.1, "Add '
        'Modifiers", "Circumstantial Bonuses and Penalties", p. 6)',
    path: 'happy',
    natural: 10,
    ability: 3,
    proficiency: 2,
    others: [1, -2],
    expectedTotal: 14,
  ),
  (
    label: 'negative modifier',
    requirement:
        'doc/specs/d20-tests.md FR-016 and FR-019 (SRD 5.2.1, "Add '
        'Modifiers", "Circumstantial Bonuses and Penalties", p. 6)',
    path: 'unhappy (boundary)',
    natural: 5,
    ability: -5,
    proficiency: null,
    others: [],
    expectedTotal: 0,
  ),
  (
    label: 'total below zero',
    requirement:
        'doc/specs/d20-tests.md FR-016 and FR-019 (SRD 5.2.1, "Add '
        'Modifiers", p. 6)',
    path: 'unhappy (boundary)',
    natural: 1,
    ability: -5,
    proficiency: null,
    others: [-2],
    expectedTotal: -6,
  ),
  (
    label: 'total above 20',
    requirement:
        'doc/specs/d20-tests.md FR-016 (SRD 5.2.1, "Add Modifiers", p. 6)',
    path: 'unhappy (boundary)',
    natural: 20,
    ability: 10,
    proficiency: null,
    others: [],
    expectedTotal: 30,
  ),
  (
    label: 'other modifiers reordered, first order',
    requirement:
        'doc/specs/d20-tests.md FR-020 (SRD 5.2.1, "Add Modifiers", p. 6)',
    path: 'unhappy (determinism)',
    natural: 10,
    ability: 3,
    proficiency: null,
    others: [-2, 2],
    expectedTotal: 13,
  ),
  (
    label: 'other modifiers reordered, second order',
    requirement:
        'doc/specs/d20-tests.md FR-020 (SRD 5.2.1, "Add Modifiers", p. 6)',
    path: 'unhappy (determinism)',
    natural: 10,
    ability: 3,
    proficiency: null,
    others: [2, -2],
    expectedTotal: 13,
  ),
  (
    label: 'very large bonus',
    requirement:
        'doc/specs/d20-tests.md FR-016 (SRD 5.2.1, "Add Modifiers", p. 6)',
    path: 'unhappy (boundary)',
    natural: 1,
    ability: 100,
    proficiency: null,
    others: [],
    expectedTotal: 101,
  ),
  (
    label: 'very large penalty',
    requirement:
        'doc/specs/d20-tests.md FR-016 (SRD 5.2.1, "Add Modifiers", p. 6)',
    path: 'unhappy (boundary)',
    natural: 20,
    ability: -100,
    proficiency: null,
    others: [],
    expectedTotal: -80,
  ),
];

/// Builds the modifiers of a total-table row from its plain values.
RollModifiers _modifiers(int ability, int? proficiency, List<int> others) =>
    RollModifiers(
      ability: Modifier(ability),
      proficiencyBonus: proficiency == null ? null : Modifier(proficiency),
      others: [for (final value in others) Modifier(value)],
    );

void main() {
  /// Requirement: per case - the 12-row total table of doc/specs/d20-tests.md
  ///   section 4.3, resolved through both `CheckResult.resolve` and
  ///   `AttackRollResult.resolve`; each row cites its own ids and path. Every
  ///   row's others are also resolved in a permuted order, which must give
  ///   the same totals. The target numbers are arbitrary: the table pins the
  ///   total, not the outcome.
  /// Path: per case
  group('total table through the resolve members', () {
    for (final c in _totalCases) {
      test('${c.label} [${c.path}] (${c.requirement})', () {
        final roll = D20Roll(mode: RollMode.normal, dice: [c.natural]);
        final modifiers = _modifiers(c.ability, c.proficiency, c.others);

        final viaCheck = CheckResult.resolve(
          D20TestKind.abilityCheck,
          roll,
          modifiers,
          const DifficultyClass(10),
        );
        final viaAttack = AttackRollResult.resolve(
          roll,
          modifiers,
          const ArmorClass(10),
        );

        expect(viaCheck.total, c.expectedTotal);
        expect(viaAttack.total, c.expectedTotal);

        // FR-020: the same others in a permuted order give the same totals.
        final permutedModifiers = _modifiers(
          c.ability,
          c.proficiency,
          c.others.reversed.toList(),
        );
        final permutedRoll = D20Roll(mode: RollMode.normal, dice: [c.natural]);
        expect(
          CheckResult.resolve(
            D20TestKind.abilityCheck,
            permutedRoll,
            permutedModifiers,
            const DifficultyClass(10),
          ).total,
          c.expectedTotal,
        );
        expect(
          AttackRollResult.resolve(
            permutedRoll,
            permutedModifiers,
            const ArmorClass(10),
          ).total,
          c.expectedTotal,
        );
      });
    }
  });

  /// Requirement: doc/specs/d20-tests.md FR-061 - RollModifiers holds an
  ///   unmodifiable copy of others, observed here through the resolve
  ///   members: the caller's list may change afterwards, the exposed list may
  ///   not be mutated, and the default is empty
  ///   (doc/rules/architecture.md §3, §4).
  /// Path: unhappy (immutability)
  group('others immutability through resolution', () {
    /// Requirement: doc/specs/d20-tests.md FR-061 and FR-016 - mutating the
    ///   caller's list after resolving changes no total and no held modifier
    ///   (doc/rules/architecture.md §3, §4; SRD 5.2.1, "Add Modifiers", p. 6).
    /// Path: unhappy (immutability)
    test('mutating the caller list after resolving changes no total', () {
      final source = [const Modifier(1)];
      final modifiers = RollModifiers(
        ability: const Modifier(3),
        others: source,
      );
      final roll = D20Roll(mode: RollMode.normal, dice: const [10]);

      final checkBefore = CheckResult.resolve(
        D20TestKind.abilityCheck,
        roll,
        modifiers,
        const DifficultyClass(10),
      );
      final attackBefore = AttackRollResult.resolve(
        roll,
        modifiers,
        const ArmorClass(10),
      );
      source[0] = const Modifier(9);
      source.add(const Modifier(5));
      final checkAfter = CheckResult.resolve(
        D20TestKind.abilityCheck,
        roll,
        modifiers,
        const DifficultyClass(10),
      );
      final attackAfter = AttackRollResult.resolve(
        roll,
        modifiers,
        const ArmorClass(10),
      );

      expect(checkBefore.total, 14);
      expect(checkAfter.total, 14);
      expect(attackBefore.total, 14);
      expect(attackAfter.total, 14);
      expect(checkBefore, checkAfter);
      expect(modifiers.others, [const Modifier(1)]);
    });

    /// Requirement: doc/specs/d20-tests.md FR-061 - the others reachable from
    ///   a resolved result cannot be mutated
    ///   (doc/rules/architecture.md §3, §4).
    /// Path: unhappy (immutability)
    test('the others of a resolved result cannot be mutated', () {
      final modifiers = RollModifiers(
        ability: const Modifier(3),
        others: [const Modifier(1)],
      );
      final roll = D20Roll(mode: RollMode.normal, dice: const [10]);
      final check = CheckResult.resolve(
        D20TestKind.abilityCheck,
        roll,
        modifiers,
        const DifficultyClass(10),
      );
      final attack = AttackRollResult.resolve(
        roll,
        modifiers,
        const ArmorClass(10),
      );

      expect(
        () => check.modifiers.others.add(const Modifier(2)),
        throwsUnsupportedError,
      );
      expect(
        () => attack.modifiers.others[0] = const Modifier(2),
        throwsUnsupportedError,
      );
    });

    /// Requirement: doc/specs/d20-tests.md FR-061 and FR-017 - the default
    ///   others is empty, so with only the ability modifier the total is the
    ///   natural value plus that modifier (doc/rules/architecture.md §3, §4;
    ///   SRD 5.2.1, "Add Modifiers", p. 6).
    /// Path: unhappy (empty and minimal)
    test('the default others is empty through a resolved result', () {
      final modifiers = RollModifiers(ability: const Modifier(3));
      final roll = D20Roll(mode: RollMode.normal, dice: const [10]);

      final check = CheckResult.resolve(
        D20TestKind.savingThrow,
        roll,
        modifiers,
        const DifficultyClass(10),
      );

      expect(check.modifiers.others, isEmpty);
      expect(check.total, 13);
    });
  });
}
