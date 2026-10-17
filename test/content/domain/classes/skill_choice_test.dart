import 'package:srd5e/src/content/domain/classes/skill_choice.dart';
import 'package:srd5e/src/content/domain/skill.dart';
import 'package:test/test.dart';

import '../../../support/argument_error_matcher.dart';

const _emptySkills = <Skill>[];
final _twoSkills = [Skill.athletics, Skill.survival];

SkillChoiceListed _listedTwoOfThree() =>
    SkillChoiceListed(2, [Skill.athletics, Skill.survival, Skill.perception]);

void main() {
  /// Requirement: doc/specs/content-classes.md FR-019 - `picks` is at least
  ///   1; a listed set is non-empty, has distinct `Skill` values and at
  ///   least `picks` of them; `SkillChoiceAny` carries picks only (SRD
  ///   5.2.1, "Core Bard Traits", p. 31, "Core Barbarian Traits", p. 28).
  /// Path: happy
  group('SkillChoice constructor rows', () {
    /// Requirement: per case
    /// Path: per case
    for (final c in [
      (
        label: 'listed two picks',
        requirement:
            'doc/specs/content-classes.md FR-019 - a listed choice of two '
            'picks over more skills is accepted',
        path: 'happy',
        build: _listedTwoOfThree,
        throwsFor: null,
      ),
      (
        label: 'any three picks',
        requirement:
            'doc/specs/content-classes.md FR-019 - the Bard\'s "Choose any '
            '3 skills" is a SkillChoiceAny of 3',
        path: 'happy',
        build: () => SkillChoiceAny(3),
        throwsFor: null,
      ),
      (
        label: 'picks zero',
        requirement:
            'doc/specs/content-classes.md FR-019 - picks 0 is rejected',
        path: 'unhappy (boundary)',
        build: () => SkillChoiceAny(0),
        throwsFor: throwsArgumentErrorFor('picks', 0),
      ),
      (
        label: 'listed empty',
        requirement:
            'doc/specs/content-classes.md FR-019 - an empty listed set is '
            'rejected',
        path: 'unhappy (boundary)',
        build: () => SkillChoiceListed(1, _emptySkills),
        throwsFor: throwsArgumentErrorFor('skills', _emptySkills),
      ),
      (
        label: 'listed too few',
        requirement:
            'doc/specs/content-classes.md FR-019 - fewer skills than picks '
            'is rejected',
        path: 'unhappy (boundary)',
        build: () => SkillChoiceListed(3, _twoSkills),
        throwsFor: throwsArgumentErrorFor('skills', _twoSkills),
      ),
      (
        label: 'listed duplicate',
        requirement:
            'doc/specs/content-classes.md FR-019 - a repeated skill is '
            'rejected',
        path: 'unhappy (boundary)',
        build: () => SkillChoiceListed(1, [Skill.athletics, Skill.athletics]),
        throwsFor: throwsArgumentErrorFor('skills', Skill.athletics),
      ),
    ]) {
      test('${c.label} [${c.path}]', () {
        if (c.throwsFor != null) {
          expect(c.build, c.throwsFor);
        } else {
          expect(c.build(), isA<SkillChoice>());
        }
      });
    }
  });

  /// Requirement: doc/specs/content-classes.md FR-019 - the choice is
  ///   sealed with exactly the two variants, exhaustive in a `switch`
  ///   without a default; the printed order and unmodifiability hold.
  /// Path: happy
  test('the family switches exhaustively and the list is unmodifiable', () {
    String describe(SkillChoice choice) => switch (choice) {
      SkillChoiceListed() => 'listed',
      SkillChoiceAny() => 'any',
    };
    final listed = SkillChoiceListed(2, [Skill.athletics, Skill.survival]);
    expect(describe(listed), 'listed');
    expect(describe(SkillChoiceAny(3)), 'any');
    expect(listed.skills, [Skill.athletics, Skill.survival]);
    expect(() => listed.skills.add(Skill.arcana), throwsUnsupportedError);
    expect(listed.toString(), startsWith('SkillChoiceListed('));
    expect(SkillChoiceAny(3).hashCode, SkillChoiceAny(3).hashCode);
    expect(SkillChoiceAny(3), equals(SkillChoiceAny(3)));
    expect(SkillChoiceAny(3), isNot(equals(SkillChoiceAny(2))));
    expect(SkillChoiceAny(3).toString(), 'SkillChoiceAny(3)');
  });

  /// Requirement: doc/specs/content-classes.md FR-008 - two instances built
  ///   from the same data are equal, with a consistent hash code.
  /// Path: happy
  test('value equality holds for both variants', () {
    final a = SkillChoiceListed(2, [Skill.athletics, Skill.survival]);
    final b = SkillChoiceListed(2, [Skill.athletics, Skill.survival]);
    expect(a, equals(b));
    expect(a.hashCode, b.hashCode);
    expect(a, isNot(equals(SkillChoiceAny(2))));
  });
}
