import 'package:srd5e/src/d20_test/domain/roll_modifiers.dart';
import 'package:srd5e/src/shared_kernel/modifier.dart';
import 'package:test/test.dart';

typedef _ShapeCase = ({
  String label,
  String requirement,
  String path,
  Modifier ability,
  Modifier? proficiencyBonus,
  List<Modifier> others,
});

/// Shape rows: the slots hold what was given, whatever the signs and counts
/// (SRD 5.2.1, "Add Modifiers", p. 6).
const List<_ShapeCase> _shapes = [
  (
    label: 'ability only',
    requirement:
        'doc/specs/d20-tests.md FR-017 (SRD 5.2.1, "Add Modifiers", p. 6)',
    path: 'unhappy (empty and minimal)',
    ability: Modifier(3),
    proficiencyBonus: null,
    others: [],
  ),
  (
    label: 'ability and Proficiency Bonus',
    requirement:
        'doc/specs/d20-tests.md FR-017 and FR-018 (SRD 5.2.1, "Add '
        'Modifiers", p. 6; "The Bonus Doesn\'t Stack", p. 8)',
    path: 'happy',
    ability: Modifier(-1),
    proficiencyBonus: Modifier(2),
    others: [],
  ),
  (
    label: 'several others',
    requirement:
        'doc/specs/d20-tests.md FR-017 (SRD 5.2.1, "Add Modifiers", '
        '"Circumstantial Bonuses and Penalties", p. 6)',
    path: 'happy',
    ability: Modifier(0),
    proficiencyBonus: null,
    others: [Modifier(1), Modifier(-2), Modifier(0)],
  ),
];

void main() {
  /// Requirement: per case - doc/specs/d20-tests.md FR-017 and FR-018 - the
  ///   shape holds exactly one ability modifier, at most one Proficiency
  ///   Bonus and any number of others (SRD 5.2.1, "Add Modifiers", p. 6; "The
  ///   Bonus Doesn't Stack", p. 8). The single slots are compile-time: the
  ///   analyzer enforces them.
  /// Path: per case
  group('RollModifiers shape', () {
    for (final c in _shapes) {
      test('${c.label} [${c.path}] (${c.requirement})', () {
        final modifiers = RollModifiers(
          ability: c.ability,
          proficiencyBonus: c.proficiencyBonus,
          others: c.others,
        );

        expect(modifiers.ability, c.ability);
        expect(modifiers.proficiencyBonus, c.proficiencyBonus);
        expect(modifiers.others, c.others);
      });
    }

    /// Requirement: doc/specs/d20-tests.md FR-017 - an untrusted caller
    ///   cannot make a RollModifiers without an ability modifier; the
    ///   required named parameter is a compile-time guarantee the analyzer
    ///   enforces (doc/specs/d20-tests.md section 8, "Not covered at
    ///   runtime").
    /// Path: happy
    test('the ability modifier is a required argument', () {
      // The missing-parameter diagnostic of this very call (commented out)
      // is the guarantee: RollModifiers() does not compile.
      //
      // RollModifiers();
      expect(
        RollModifiers(ability: const Modifier(0)).ability,
        const Modifier(0),
      );
    });
  });

  /// Requirement: doc/specs/d20-tests.md FR-061 - RollModifiers holds an
  ///   unmodifiable copy of others: the caller's list may change afterwards,
  ///   the exposed list may not be mutated, and the default is empty
  ///   (doc/rules/architecture.md §3, §4).
  /// Path: unhappy (immutability)
  group('RollModifiers others copy', () {
    /// Requirement: doc/specs/d20-tests.md FR-061 - mutating the caller's
    ///   list after construction does not change the value
    ///   (doc/rules/architecture.md §3, §4).
    /// Path: unhappy (immutability)
    test('mutating the caller list leaves the held others unchanged', () {
      final source = [const Modifier(1)];
      final modifiers = RollModifiers(
        ability: const Modifier(0),
        others: source,
      );

      source[0] = const Modifier(9);
      source.add(const Modifier(5));

      expect(modifiers.others, [const Modifier(1)]);
    });

    /// Requirement: doc/specs/d20-tests.md FR-061 - mutating the exposed
    ///   list throws UnsupportedError (doc/rules/architecture.md §3, §4).
    /// Path: unhappy (immutability)
    test('the exposed others list cannot be mutated', () {
      final modifiers = RollModifiers(
        ability: const Modifier(0),
        others: [const Modifier(1)],
      );

      expect(
        () => modifiers.others.add(const Modifier(2)),
        throwsUnsupportedError,
      );
      expect(
        () => modifiers.others[0] = const Modifier(2),
        throwsUnsupportedError,
      );
    });

    /// Requirement: doc/specs/d20-tests.md FR-061 - the default others is
    ///   empty (doc/rules/architecture.md §3, §4).
    /// Path: unhappy (empty and minimal)
    test('the default others is empty', () {
      final modifiers = RollModifiers(ability: const Modifier(3));

      expect(modifiers.others, isEmpty);
    });

    /// Requirement: doc/specs/d20-tests.md FR-061 - the others is a copy of
    ///   any Iterable, so the value does not change when the source does
    ///   (doc/rules/architecture.md §3, §4).
    /// Path: unhappy (immutability)
    test('others accepts any Iterable and holds a copy', () {
      final source = {const Modifier(1), const Modifier(-2)};
      final modifiers = RollModifiers(
        ability: const Modifier(0),
        others: source,
      );

      source.clear();

      expect(modifiers.others, [const Modifier(1), const Modifier(-2)]);
    });
  });

  /// Requirement: doc/specs/d20-tests.md FR-050 - a RollModifiers is equal,
  ///   with an equal hash code, when every field is equal, and unequal when
  ///   any single field differs, including collection contents and order
  ///   (doc/rules/architecture.md §3).
  /// Path: happy
  group('RollModifiers value semantics', () {
    /// Requirement: doc/specs/d20-tests.md FR-050 - a RollModifiers is equal,
    ///   with an equal hash code, when every field is equal
    ///   (doc/rules/architecture.md §3).
    /// Path: happy
    test('equal modifiers are equal with equal hash codes', () {
      final a = RollModifiers(
        ability: const Modifier(3),
        proficiencyBonus: const Modifier(2),
        others: [const Modifier(1), const Modifier(-2)],
      );
      final b = RollModifiers(
        ability: const Modifier(3),
        proficiencyBonus: const Modifier(2),
        others: [const Modifier(1), const Modifier(-2)],
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    /// Requirement: doc/specs/d20-tests.md FR-050 - a RollModifiers is
    ///   unequal when any single field differs, including collection contents
    ///   and order (doc/rules/architecture.md §3).
    /// Path: unhappy (any differing field)
    test('modifiers differing in one field are unequal', () {
      final base = RollModifiers(
        ability: const Modifier(3),
        proficiencyBonus: const Modifier(2),
        others: [const Modifier(1)],
      );
      final otherAbility = RollModifiers(
        ability: const Modifier(4),
        proficiencyBonus: const Modifier(2),
        others: [const Modifier(1)],
      );
      final noProficiency = RollModifiers(
        ability: const Modifier(3),
        others: [const Modifier(1)],
      );
      final otherProficiency = RollModifiers(
        ability: const Modifier(3),
        proficiencyBonus: const Modifier(3),
        others: [const Modifier(1)],
      );
      final otherContent = RollModifiers(
        ability: const Modifier(3),
        proficiencyBonus: const Modifier(2),
        others: [const Modifier(2)],
      );
      final otherOrder = RollModifiers(
        ability: const Modifier(3),
        proficiencyBonus: const Modifier(2),
        others: [const Modifier(1), const Modifier(-2)],
      );
      final reordered = RollModifiers(
        ability: const Modifier(3),
        proficiencyBonus: const Modifier(2),
        others: [const Modifier(-2), const Modifier(1)],
      );
      final longer = RollModifiers(
        ability: const Modifier(3),
        proficiencyBonus: const Modifier(2),
        others: [const Modifier(1), const Modifier(-2), const Modifier(0)],
      );

      expect(base, isNot(otherAbility));
      expect(base, isNot(noProficiency));
      expect(base, isNot(otherProficiency));
      expect(base, isNot(otherContent));
      expect(base, isNot(otherOrder));
      expect(otherOrder, isNot(reordered));
      expect(otherOrder, isNot(longer));
    });
  });
}
