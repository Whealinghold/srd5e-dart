import 'package:srd5e/src/d20_test/domain/armor_class.dart';
import 'package:srd5e/src/d20_test/domain/difficulty_class.dart';
import 'package:test/test.dart';

typedef _ConstantCase = ({
  String label,
  String requirement,
  String path,
  DifficultyClass constant,
  int value,
});

/// The Typical Difficulty Classes (SRD 5.2.1, Typical Difficulty Classes
/// table, p. 6).
const List<_ConstantCase> _constants = [
  (
    label: 'very easy is 5',
    requirement:
        'doc/specs/d20-tests.md FR-021 (SRD 5.2.1, Typical Difficulty '
        'Classes table, p. 6)',
    path: 'happy',
    constant: DifficultyClass.veryEasy,
    value: 5,
  ),
  (
    label: 'easy is 10',
    requirement:
        'doc/specs/d20-tests.md FR-021 (SRD 5.2.1, Typical Difficulty '
        'Classes table, p. 6)',
    path: 'happy',
    constant: DifficultyClass.easy,
    value: 10,
  ),
  (
    label: 'medium is 15',
    requirement:
        'doc/specs/d20-tests.md FR-021 (SRD 5.2.1, Typical Difficulty '
        'Classes table, p. 6)',
    path: 'happy',
    constant: DifficultyClass.medium,
    value: 15,
  ),
  (
    label: 'hard is 20',
    requirement:
        'doc/specs/d20-tests.md FR-021 (SRD 5.2.1, Typical Difficulty '
        'Classes table, p. 6)',
    path: 'happy',
    constant: DifficultyClass.hard,
    value: 20,
  ),
  (
    label: 'very hard is 25',
    requirement:
        'doc/specs/d20-tests.md FR-021 (SRD 5.2.1, Typical Difficulty '
        'Classes table, p. 6)',
    path: 'happy',
    constant: DifficultyClass.veryHard,
    value: 25,
  ),
  (
    label: 'nearly impossible is 30',
    requirement:
        'doc/specs/d20-tests.md FR-021 (SRD 5.2.1, Typical Difficulty '
        'Classes table, p. 6)',
    path: 'happy',
    constant: DifficultyClass.nearlyImpossible,
    value: 30,
  ),
];

void main() {
  /// Requirement: per case - doc/specs/d20-tests.md FR-021 - the named
  ///   constants hold the Typical Difficulty Classes (SRD 5.2.1, Typical
  ///   Difficulty Classes table, p. 6).
  /// Path: per case
  group('DifficultyClass typical constants', () {
    for (final c in _constants) {
      test('${c.label} [${c.path}] (${c.requirement})', () {
        expect(c.constant, DifficultyClass(c.value));
        expect(c.constant.value, c.value);
      });
    }
  });

  /// Requirement: doc/specs/d20-tests.md FR-022 and FR-050 - target numbers
  ///   compare equal by value within their own type, never across
  ///   DifficultyClass and ArmorClass, and are unequal when the value
  ///   differs; the SRD bounds neither, so any integer is valid (SRD 5.2.1,
  ///   pp. 6-7; doc/rules/architecture.md §3; d20-tests.md section 9, D-02).
  /// Path: happy
  group('target number value semantics', () {
    /// Requirement: doc/specs/d20-tests.md FR-022 - a DifficultyClass and an
    ///   ArmorClass compare equal by value within their own type (SRD 5.2.1,
    ///   pp. 6-7; doc/rules/architecture.md §3).
    /// Path: happy
    test(
      'equal target numbers of one type are equal with equal hash codes',
      () {
        const dcA = DifficultyClass(10);
        const dcB = DifficultyClass(10);
        const acA = ArmorClass(10);
        const acB = ArmorClass(10);

        expect(dcA, dcB);
        expect(dcA.hashCode, dcB.hashCode);
        expect(acA, acB);
        expect(acA.hashCode, acB.hashCode);
      },
    );

    /// Requirement: doc/specs/d20-tests.md FR-022 - a DifficultyClass and an
    ///   ArmorClass never compare equal to each other for the same number
    ///   (SRD 5.2.1, "Difficulty Class", p. 6; "Armor Class", p. 7).
    /// Path: unhappy (boundary)
    test('a DifficultyClass is not an ArmorClass for the same number', () {
      const dc = DifficultyClass(10);
      const ac = ArmorClass(10);

      expect(dc, isNot(ac));
      expect(ac, isNot(dc));
    });

    /// Requirement: doc/specs/d20-tests.md FR-050 - a target number is
    ///   unequal when its value differs (doc/rules/architecture.md §3).
    /// Path: unhappy (any differing field)
    test('target numbers differing in the value are unequal', () {
      expect(const DifficultyClass(10), isNot(const DifficultyClass(11)));
      expect(const ArmorClass(10), isNot(const ArmorClass(11)));
    });

    /// Requirement: doc/specs/d20-tests.md section 9, D-02 - the SRD gives no
    ///   minimum or maximum for a DC or an AC, so neither type rejects any
    ///   integer.
    /// Path: unhappy (boundary)
    test('any integer is a valid target number', () {
      const dcs = [
        DifficultyClass(-100),
        DifficultyClass(0),
        DifficultyClass(1000),
      ];
      const acs = [ArmorClass(-5), ArmorClass(0), ArmorClass(999)];

      expect(dcs.map((d) => d.value), [-100, 0, 1000]);
      expect(acs.map((a) => a.value), [-5, 0, 999]);
    });
  });
}
