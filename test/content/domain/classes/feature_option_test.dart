import 'package:srd5e/src/content/domain/classes/feature_fact.dart';
import 'package:srd5e/src/content/domain/classes/feature_option.dart';
import 'package:srd5e/src/content/domain/feat_category.dart';
import 'package:srd5e/src/content/domain/typed_ids.dart';
import 'package:test/test.dart';

import '../../../support/argument_error_matcher.dart';

final _agonizingBlast = FeatureOption(
  id: FeatureOptionId('agonizing_blast'),
  name: 'Agonizing Blast',
  text: 'Choose one of your known Warlock cantrips...',
  prerequisite: OptionPrerequisite(
    requiresOptionIds: [FeatureOptionId('no_such_option')],
  ),
);
final _selfReference = FeatureOption(
  id: FeatureOptionId('agonizing_blast'),
  name: 'Agonizing Blast',
  text: 'Choose one of your known Warlock cantrips...',
  prerequisite: OptionPrerequisite(
    requiresOptionIds: [FeatureOptionId('agonizing_blast')],
  ),
);
final _zeroCost = FeatureOption(
  id: FeatureOptionId('careful_spell'),
  name: 'Careful Spell',
  text: 'Spend 1 sorcery point...',
  pointCost: 0,
);
final _blankName = FeatureOption(
  id: FeatureOptionId('careful_spell'),
  name: ' ',
  text: 'Spend 1 sorcery point...',
);
final _blankText = FeatureOption(
  id: FeatureOptionId('careful_spell'),
  name: 'Careful Spell',
  text: '   ',
);
final _plainOption = FeatureOption(
  id: FeatureOptionId('careful_spell'),
  name: 'Careful Spell',
  text: 'Spend 1 sorcery point...',
);
final _preparedSpellOption = FeatureOption(
  id: FeatureOptionId('forest'),
  name: 'Forest',
  text: 'The land type grants spells...',
  facts: [
    AlwaysPreparedSpells([
      SpellGrant(3, [SpellId('barkskin')]),
    ]),
  ],
);

void main() {
  /// Requirement: doc/specs/content-classes.md FR-061 - an option id is a
  ///   `FeatureOptionId` (snake_case); FR-062 - a prerequisite carries at
  ///   least one part, a minimum class level from 1 to 20 and a non-blank
  ///   note (SRD 5.2.1, "Eldritch Invocation Options", pp. 72-74).
  /// Path: happy
  group('OptionPrerequisite and FeatureOptionId constructor rows', () {
    /// Requirement: per case
    /// Path: per case
    for (final c in [
      (
        label: 'a level prerequisite',
        requirement:
            'doc/specs/content-classes.md FR-062 - a minimum class level of '
            '7 constructs',
        path: 'happy',
        build: () => OptionPrerequisite(minClassLevel: 7),
        throwsFor: null,
        throwsForName: null,
      ),
      (
        label: 'a required option',
        requirement:
            'doc/specs/content-classes.md FR-062 - a required option id '
            'constructs',
        path: 'happy',
        build: () => OptionPrerequisite(
          requiresOptionIds: [FeatureOptionId('agonizing_blast')],
        ),
        throwsFor: null,
        throwsForName: null,
      ),
      (
        label: 'a note',
        requirement:
            'doc/specs/content-classes.md FR-062 - a printed note '
            'constructs',
        path: 'happy',
        build: () =>
            OptionPrerequisite(note: 'a Warlock Cantrip That Deals Damage'),
        throwsFor: null,
        throwsForName: null,
      ),
      (
        label: 'empty prerequisite',
        requirement:
            'doc/specs/content-classes.md FR-062 - a prerequisite with no '
            'part is rejected (Cases FT: "empty prerequisite")',
        path: 'unhappy (empty case)',
        build: () => OptionPrerequisite(),
        throwsFor: null,
        throwsForName: 'prerequisite',
      ),
      (
        label: 'minClassLevel zero',
        requirement:
            'doc/specs/content-classes.md FR-062 - a minimum class level of '
            '0 is rejected',
        path: 'unhappy (boundary)',
        build: () => OptionPrerequisite(minClassLevel: 0),
        throwsFor: throwsArgumentErrorFor('minClassLevel', 0),
        throwsForName: null,
      ),
      (
        label: 'minClassLevel 21',
        requirement:
            'doc/specs/content-classes.md FR-062 - a minimum class level of '
            '21 is rejected',
        path: 'unhappy (boundary)',
        build: () => OptionPrerequisite(minClassLevel: 21),
        throwsFor: throwsArgumentErrorFor('minClassLevel', 21),
        throwsForName: null,
      ),
      (
        label: 'minClassLevel one',
        requirement:
            'doc/specs/content-classes.md FR-062 - the range is inclusive: '
            'a minimum class level of exactly 1 constructs',
        path: 'happy',
        build: () => OptionPrerequisite(minClassLevel: 1),
        throwsFor: null,
        throwsForName: null,
      ),
      (
        label: 'minClassLevel twenty',
        requirement:
            'doc/specs/content-classes.md FR-062 - the range is inclusive: '
            'a minimum class level of exactly 20 constructs',
        path: 'happy',
        build: () => OptionPrerequisite(minClassLevel: 20),
        throwsFor: null,
        throwsForName: null,
      ),
      (
        label: 'blank note',
        requirement:
            'doc/specs/content-classes.md FR-062 - a blank note is rejected',
        path: 'unhappy (invalid input)',
        build: () => OptionPrerequisite(note: '  '),
        throwsFor: throwsArgumentErrorFor('note', '  '),
        throwsForName: null,
      ),
      (
        label: 'uppercase option id',
        requirement:
            'doc/specs/content-classes.md FR-061 - an option id that breaks '
            'the snake_case rule is rejected',
        path: 'unhappy (invalid input)',
        build: () => FeatureOptionId('Agonizing Blast'),
        throwsFor: throwsArgumentErrorFor('value', 'Agonizing Blast'),
        throwsForName: null,
      ),
    ]) {
      test('${c.label} [${c.path}]', () {
        if (c.throwsFor != null) {
          expect(c.build, c.throwsFor);
        } else if (c.throwsForName != null) {
          expect(
            c.build,
            throwsA(
              isA<ArgumentError>().having(
                (e) => e.name,
                'name',
                c.throwsForName,
              ),
            ),
          );
        } else {
          expect(c.build(), isA<Object>());
        }
      });
    }
  });

  /// Requirement: doc/specs/content-classes.md FR-061, FR-063, FR-064 - an
  ///   option carries name, text, point cost at least 1 and only
  ///   `AlwaysPreparedSpells` facts (SRD 5.2.1, "Metamagic Options",
  ///   pp. 66-67, "Level 3: Circle of the Land Spells", p. 46).
  /// Path: happy
  group('FeatureOption constructor rows', () {
    /// Requirement: per case
    /// Path: per case
    for (final c in [
      (
        label: 'a plain option',
        requirement:
            'doc/specs/content-classes.md FR-061 - an option of id, name '
            'and text constructs without optional parts',
        path: 'happy',
        build: () => _plainOption,
        throwsFor: null,
        throwsForName: null,
      ),
      (
        label: 'zero point cost',
        requirement:
            'doc/specs/content-classes.md FR-063 - a point cost of 0 is '
            'rejected (Cases FT: "zero point cost")',
        path: 'unhappy (boundary)',
        build: () => _zeroCost,
        throwsFor: throwsArgumentErrorFor('pointCost', 0),
        throwsForName: null,
      ),
      (
        label: 'point cost of one',
        requirement:
            'doc/specs/content-classes.md FR-063 - the minimum is inclusive: '
            'a point cost of exactly [minPointCost] constructs',
        path: 'happy',
        build: () => FeatureOption(
          id: FeatureOptionId('careful_spell'),
          name: 'Careful Spell',
          text: 'Spend 1 sorcery point...',
          pointCost: FeatureOption.minPointCost,
        ),
        throwsFor: null,
        throwsForName: null,
      ),
      (
        label: 'subclass fact on option',
        requirement:
            'doc/specs/content-classes.md FR-064 - a GrantsSubclass fact on '
            'an option is rejected (Cases FT: "subclass fact on option")',
        path: 'unhappy (invalid input)',
        build: () => FeatureOption(
          id: FeatureOptionId('land_type'),
          name: 'Land Type',
          text: 'Choose a land type...',
          facts: [const GrantsSubclass()],
        ),
        throwsFor: null,
        throwsForName: 'facts',
      ),
      (
        label: 'feat fact on option',
        requirement:
            'doc/specs/content-classes.md FR-064 - a GrantsFeat fact on an '
            'option is rejected',
        path: 'unhappy (invalid input)',
        build: () => FeatureOption(
          id: FeatureOptionId('land_type'),
          name: 'Land Type',
          text: 'Choose a land type...',
          facts: [const GrantsFeat(FeatCategory.general)],
        ),
        throwsFor: null,
        throwsForName: 'facts',
      ),
      (
        label: 'prepared-spell fact on option',
        requirement:
            'doc/specs/content-classes.md FR-064 - an AlwaysPreparedSpells '
            'fact on an option is accepted (the Circle of the Land)',
        path: 'happy',
        build: () => _preparedSpellOption,
        throwsFor: null,
        throwsForName: null,
      ),
      (
        label: 'blank name',
        requirement:
            'doc/specs/content-classes.md FR-061 - an option name is '
            'non-blank',
        path: 'unhappy (invalid input)',
        build: () => _blankName,
        throwsFor: throwsArgumentErrorFor('name', ' '),
        throwsForName: null,
      ),
      (
        label: 'blank text',
        requirement:
            'doc/specs/content-classes.md FR-061 - an option text is '
            'non-blank',
        path: 'unhappy (invalid input)',
        build: () => _blankText,
        throwsFor: throwsArgumentErrorFor('text', '   '),
        throwsForName: null,
      ),
    ]) {
      test('${c.label} [${c.path}]', () {
        if (c.throwsFor != null) {
          expect(c.build, c.throwsFor);
        } else if (c.throwsForName != null) {
          expect(
            c.build,
            throwsA(
              isA<ArgumentError>().having(
                (e) => e.name,
                'name',
                c.throwsForName,
              ),
            ),
          );
        } else {
          expect(c.build(), isA<FeatureOption>());
        }
      });
    }
  });

  /// Requirement: doc/specs/content-classes.md FR-062, FR-008 - the
  ///   required ids are defensively copied and unmodifiable; value equality
  ///   holds; the FeatureOptionId value is readable.
  /// Path: happy
  test('prerequisite collections are copied and value equality holds', () {
    final required = [FeatureOptionId('agonizing_blast')];
    final prerequisite = OptionPrerequisite(requiresOptionIds: required);
    required.clear();
    expect(prerequisite.requiresOptionIds.length, 1);
    expect(
      () => prerequisite.requiresOptionIds.clear(),
      throwsUnsupportedError,
    );
    expect(
      prerequisite,
      equals(
        OptionPrerequisite(
          requiresOptionIds: [FeatureOptionId('agonizing_blast')],
        ),
      ),
    );
    expect(
      prerequisite.hashCode,
      OptionPrerequisite(
        requiresOptionIds: [FeatureOptionId('agonizing_blast')],
      ).hashCode,
    );
    expect(prerequisite.toString(), startsWith('OptionPrerequisite('));
    expect(
      _plainOption.hashCode,
      FeatureOption(
        id: FeatureOptionId('careful_spell'),
        name: 'Careful Spell',
        text: 'Spend 1 sorcery point...',
      ).hashCode,
    );
    expect(_plainOption.toString(), 'FeatureOption(careful_spell)');
    expect(FeatureOptionId('agonizing_blast').value, 'agonizing_blast');
    expect(
      FeatureOptionId('agonizing_blast'),
      equals(FeatureOptionId('agonizing_blast')),
    );
    expect(
      FeatureOptionId('agonizing_blast').hashCode,
      FeatureOptionId('agonizing_blast').hashCode,
    );
  });

  /// Requirement: doc/specs/content-classes.md FR-063 - `repeatable` means
  ///   the SRD prints "Repeatable"; absent is false; value equality holds
  ///   over every field.
  /// Path: happy
  test('repeatable defaults to false and options compare by value', () {
    final option = FeatureOption(
      id: FeatureOptionId('quickened_spell'),
      name: 'Quickened Spell',
      text: 'Spend 2 sorcery points...',
      prerequisite: OptionPrerequisite(minClassLevel: 10),
      pointCost: 2,
      repeatable: true,
    );
    expect(option.repeatable, isTrue);
    expect(_plainOption.repeatable, isFalse);
    expect(
      option,
      equals(
        FeatureOption(
          id: FeatureOptionId('quickened_spell'),
          name: 'Quickened Spell',
          text: 'Spend 2 sorcery points...',
          prerequisite: OptionPrerequisite(minClassLevel: 10),
          pointCost: 2,
          repeatable: true,
        ),
      ),
    );
    expect(_agonizingBlast, isNot(equals(_selfReference)));
  });

  /// Requirement: doc/specs/content-classes.md FR-061 - an option id of
  ///   exactly 64 characters is accepted.
  /// Path: unhappy (boundary)
  test('a 64-character option id is accepted', () {
    final id = FeatureOptionId('a${'b' * 63}');
    expect(id.value.length, 64);
  });
}
