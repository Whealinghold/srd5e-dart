import 'package:srd5e/src/content/domain/level_benefit.dart';
import 'package:srd5e/src/content/domain/typed_ids.dart';
import 'package:test/test.dart';

import '../../support/argument_error_matcher.dart';
import '../../support/operator_equals.dart';

/// One constructor input with the field the constructor must reject, or null
/// when accepted.
typedef _LevelBenefitCase = ({
  String label,
  String requirement,
  String path,
  int level,
  String text,
  String? rejectedField,
});

final List<_LevelBenefitCase> _cases = [
  (
    label: 'level 1 is accepted',
    requirement:
        'doc/specs/content-species-backgrounds-feats.md FR-061 - a lineage '
        'benefit sits at level 1, 3 or 5 (SRD 5.2.1, "Elven Lineages", p. 85)',
    path: 'happy',
    level: 1,
    text: 'The Level 1 cell text.',
    rejectedField: null,
  ),
  (
    label: 'level 3 is accepted',
    requirement:
        'doc/specs/content-species-backgrounds-feats.md FR-061 - a lineage '
        'benefit sits at level 1, 3 or 5 (SRD 5.2.1, "Elven Lineages", p. 85)',
    path: 'happy',
    level: 3,
    text: 'The Level 3 cell text.',
    rejectedField: null,
  ),
  (
    label: 'level 5 is accepted',
    requirement:
        'doc/specs/content-species-backgrounds-feats.md FR-061 - a lineage '
        'benefit sits at level 1, 3 or 5 (SRD 5.2.1, "Elven Lineages", p. 85)',
    path: 'happy',
    level: 5,
    text: 'The Level 5 cell text.',
    rejectedField: null,
  ),
  (
    label: 'level 0 is rejected',
    requirement:
        'doc/specs/content-species-backgrounds-feats.md FR-061 - a level '
        'outside {1, 3, 5} is invalidValue',
    path: 'unhappy (boundary)',
    level: 0,
    text: 'text',
    rejectedField: 'level',
  ),
  (
    label: 'level 2 is rejected',
    requirement:
        'doc/specs/content-species-backgrounds-feats.md FR-061 - a level '
        'outside {1, 3, 5} is invalidValue ("a level 2")',
    path: 'unhappy (boundary)',
    level: 2,
    text: 'text',
    rejectedField: 'level',
  ),
  (
    label: 'level 4 is rejected',
    requirement:
        'doc/specs/content-species-backgrounds-feats.md FR-061 - a level '
        'outside {1, 3, 5} is invalidValue',
    path: 'unhappy (boundary)',
    level: 4,
    text: 'text',
    rejectedField: 'level',
  ),
  (
    label: 'level 6 is rejected',
    requirement:
        'doc/specs/content-species-backgrounds-feats.md FR-061 - a level '
        'outside {1, 3, 5} is invalidValue',
    path: 'unhappy (boundary)',
    level: 6,
    text: 'text',
    rejectedField: 'level',
  ),
  (
    label: 'blank text is rejected',
    requirement:
        'doc/specs/content-species-backgrounds-feats.md FR-061 and schema '
        'FR-028 - the text holds at least one non-whitespace character',
    path: 'unhappy (invalid input)',
    level: 1,
    text: ' ',
    rejectedField: 'text',
  ),
];

void main() {
  /// Requirement: per case
  /// Path: per case
  for (final c in _cases) {
    test('LevelBenefit ${c.label} [${c.path}]', () {
      if (c.rejectedField == null) {
        final benefit = LevelBenefit(
          c.level,
          c.text,
          SpellId('dancing_lights'),
        );
        expect(benefit.level, c.level);
        expect(benefit.text, c.text);
        expect(benefit.spellId, SpellId('dancing_lights'));
      } else {
        expect(
          () => LevelBenefit(c.level, c.text, SpellId('dancing_lights')),
          throwsArgumentErrorFor(
            c.rejectedField!,
            c.rejectedField == 'level' ? c.level : c.text,
          ),
        );
      }
    });
  }

  /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-061 and
  ///   FR-069 - the levels are a public constant and predicate the decoder
  ///   reuses.
  /// Path: happy
  test('the lineage levels are a public constant and predicate', () {
    expect(LevelBenefit.lineageLevels, [1, 3, 5]);
    expect(LevelBenefit.isValidLevel(1), isTrue);
    expect(LevelBenefit.isValidLevel(3), isTrue);
    expect(LevelBenefit.isValidLevel(5), isTrue);
    expect(LevelBenefit.isValidLevel(0), isFalse);
    expect(LevelBenefit.isValidLevel(2), isFalse);
    expect(LevelBenefit.isValidLevel(4), isFalse);
    expect(LevelBenefit.isValidLevel(6), isFalse);
  });

  /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-061 -
  ///   value equality; the spell id is part of the value.
  /// Path: happy
  test('level benefits compare by level, text and spell id', () {
    final benefit = LevelBenefit(1, 'text', SpellId('dancing_lights'));
    final same = LevelBenefit(1, 'text', SpellId('dancing_lights'));
    final otherSpell = LevelBenefit(1, 'text', SpellId('faerie_fire'));
    final otherLevel = LevelBenefit(3, 'text', SpellId('dancing_lights'));

    expect(benefit, same);
    expect(benefit.hashCode, same.hashCode);
    expect(operatorEquals(benefit, otherSpell), isFalse);
    expect(operatorEquals(benefit, otherLevel), isFalse);
    expect(operatorEquals(benefit, 'text'), isFalse);
  });

  /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-061 -
  ///   toString is a debugging form.
  /// Path: happy
  test('a level benefit prints its level', () {
    expect(
      LevelBenefit(1, 'text', SpellId('dancing_lights')).toString(),
      'LevelBenefit(1, SpellId(dancing_lights))',
    );
  });
}
