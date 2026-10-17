import 'package:srd5e/src/content/domain/choice_option.dart';
import 'package:srd5e/src/content/domain/damage_type.dart';
import 'package:srd5e/src/content/domain/level_benefit.dart';
import 'package:srd5e/src/content/domain/typed_ids.dart';
import 'package:test/test.dart';

import '../../support/argument_error_matcher.dart';
import '../../support/operator_equals.dart';

LevelBenefit _benefit(int level, String spellId) =>
    LevelBenefit(level, 'The Level $level cell text.', SpellId(spellId));

List<LevelBenefit> _levels(int first, int second, int third) => [
  LevelBenefit(first, 'first', SpellId('dancing_lights')),
  LevelBenefit(second, 'second', SpellId('faerie_fire')),
  LevelBenefit(third, 'third', SpellId('darkness')),
];

void main() {
  /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-016,
  ///   FR-017 - a Draconic Ancestry option holds its name and damage type,
  ///   rejects a blank name, and compares by value.
  /// Path: happy
  group('DamageTypeOption', () {
    /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-016,
    ///   FR-017 - a Draconic Ancestry option holds its name and damage type
    ///   and no text (SRD 5.2.1, "Dragonborn", p. 84).
    /// Path: happy
    test('holds a name and a damage type', () {
      final option = DamageTypeOption('Black', DamageType.acid);

      expect(option.name, 'Black');
      expect(option.damageType, DamageType.acid);
      expect(option, isA<ChoiceOption>());
    });

    /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-016 -
    ///   a blank option name is rejected (schema FR-027).
    /// Path: unhappy (invalid input)
    test('rejects a blank name', () {
      expect(
        () => DamageTypeOption(' ', DamageType.acid),
        throwsArgumentErrorFor('name', ' '),
      );
      expect(
        () => DamageTypeOption(' Black', DamageType.acid),
        throwsArgumentErrorFor('name', ' Black'),
      );
    });

    /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-016 -
    ///   value equality.
    /// Path: happy
    test('compares by name and damage type', () {
      final option = DamageTypeOption('Black', DamageType.acid);

      expect(option, DamageTypeOption('Black', DamageType.acid));
      expect(
        option.hashCode,
        DamageTypeOption('Black', DamageType.acid).hashCode,
      );
      expect(
        operatorEquals(option, DamageTypeOption('Black', DamageType.cold)),
        isFalse,
      );
      expect(
        operatorEquals(option, DamageTypeOption('Blue', DamageType.acid)),
        isFalse,
      );
      expect(operatorEquals(option, 'Black'), isFalse);
    });
  });

  /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-018,
  ///   FR-019, FR-061 - a lineage option holds the levels 1, 3 and 5 in
  ///   that order; the level-error rows of the "Elven Lineages and Fiendish
  ///   Legacies" table are rejected.
  /// Path: happy
  group('LineageOption', () {
    /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-018,
    ///   FR-019 - an Elven Lineage or Fiendish Legacy option holds the
    ///   levels 1, 3 and 5 in that order ("Elven Lineages", p. 85;
    ///   "Fiendish Legacies", p. 86).
    /// Path: happy
    test('holds the levels 1, 3 and 5 in that order', () {
      final option = LineageOption('Drow', [
        _benefit(1, 'dancing_lights'),
        _benefit(3, 'faerie_fire'),
        _benefit(5, 'darkness'),
      ]);

      expect(option.name, 'Drow');
      expect(option.levelBenefits, hasLength(3));
      expect(option.levelBenefits.map((b) => b.level), [1, 3, 5]);
      expect(option.levelBenefits[0].spellId, SpellId('dancing_lights'));
      expect(option.levelBenefits[1].spellId, SpellId('faerie_fire'));
      expect(option.levelBenefits[2].spellId, SpellId('darkness'));
    });

    /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-061 -
    ///   a length other than three is outOfRange (the "levels 1, 3 only"
    ///   case row).
    /// Path: unhappy (boundary)
    test('rejects two level benefits', () {
      expect(
        () => LineageOption('Drow', [_benefit(1, 'a'), _benefit(3, 'b')]),
        throwsArgumentErrorFor('levelBenefits', isA<List<LevelBenefit>>()),
      );
    });

    /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-061 -
    ///   a repeated level is duplicate at the later index (the "1, 3, 3"
    ///   case row).
    /// Path: unhappy (invalid input)
    test('rejects a repeated level', () {
      expect(
        () => LineageOption('Drow', _levels(1, 3, 3)),
        throwsArgumentErrorFor('levelBenefits', 3),
      );
    });

    /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-061 -
    ///   distinct valid levels in another order are a constraintViolation
    ///   (the "1, 5, 3" case row).
    /// Path: unhappy (rule interaction)
    test('rejects the levels 1, 5, 3', () {
      expect(
        () => LineageOption('Drow', _levels(1, 5, 3)),
        throwsArgumentErrorFor('levelBenefits', [1, 5, 3]),
      );
    });

    /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-061 -
    ///   a level outside {1, 3, 5} is invalidValue, so a lineage option
    ///   cannot hold one (the "a level 2" case row; LevelBenefit rejects).
    /// Path: unhappy (boundary)
    test('cannot hold a level 2', () {
      expect(
        () => LevelBenefit(2, 'text', SpellId('dancing_lights')),
        throwsArgumentErrorFor('level', 2),
      );
    });

    /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-069 -
    ///   the required benefit count is a public constant the decoder reuses.
    /// Path: happy
    test('exposes the required benefit count', () {
      expect(LineageOption.requiredLevelBenefitCount, 3);
    });

    /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-061 -
    ///   value equality.
    /// Path: happy
    test('compares by name and level benefits', () {
      final option = LineageOption('Drow', [
        _benefit(1, 'dancing_lights'),
        _benefit(3, 'faerie_fire'),
        _benefit(5, 'darkness'),
      ]);
      final same = LineageOption('Drow', [
        _benefit(1, 'dancing_lights'),
        _benefit(3, 'faerie_fire'),
        _benefit(5, 'darkness'),
      ]);

      expect(option, same);
      expect(option.hashCode, same.hashCode);
      expect(
        operatorEquals(option, LineageOption('High Elf', option.levelBenefits)),
        isFalse,
      );
      expect(operatorEquals(option, 'Drow'), isFalse);
    });

    /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-016 -
    ///   the level benefits are an unmodifiable defensive copy.
    /// Path: unhappy (immutability)
    test('holds an unmodifiable list', () {
      final option = LineageOption('Drow', [
        _benefit(1, 'dancing_lights'),
        _benefit(3, 'faerie_fire'),
        _benefit(5, 'darkness'),
      ]);

      expect(
        () => option.levelBenefits.add(_benefit(1, 'x')),
        throwsUnsupportedError,
      );
    });
  });

  /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-020 -
  ///   a text option holds the verbatim text and possibly empty spell ids;
  ///   a blank name or text is rejected.
  /// Path: happy
  group('TextOption', () {
    /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-020 -
    ///   a TextOption holds the verbatim text and possibly empty spell ids
    ///   (the Giant Ancestry options have none).
    /// Path: happy
    test('holds text and no spell ids', () {
      final option = TextOption('Hill’s Tumble (Hill Giant)', 'Printed text.');

      expect(option.name, 'Hill’s Tumble (Hill Giant)');
      expect(option.text, 'Printed text.');
      expect(option.spellIds, isEmpty);
    });

    /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-020 -
    ///   the Gnomish Lineage options carry their spells on the option.
    /// Path: happy
    test('holds text with spell ids', () {
      final option = TextOption(
        'Forest Gnome',
        'Printed text.',
        spellIds: [SpellId('minor_illusion'), SpellId('speak_with_animals')],
      );

      expect(option.spellIds, [
        SpellId('minor_illusion'),
        SpellId('speak_with_animals'),
      ]);
    });

    /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-016,
    ///   FR-020 - a blank name or text is rejected (schema FR-027, FR-028).
    /// Path: unhappy (invalid input)
    test('rejects a blank name or text', () {
      expect(
        () => TextOption(' ', 'text'),
        throwsArgumentErrorFor('name', ' '),
      );
      expect(
        () => TextOption('Forest Gnome', ' '),
        throwsArgumentErrorFor('text', ' '),
      );
    });

    /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-020 -
    ///   value equality and an unmodifiable spell-id list.
    /// Path: happy
    test('compares by name, text and spell ids and is unmodifiable', () {
      final option = TextOption(
        'Forest Gnome',
        'Printed text.',
        spellIds: [SpellId('minor_illusion')],
      );
      final same = TextOption(
        'Forest Gnome',
        'Printed text.',
        spellIds: [SpellId('minor_illusion')],
      );

      expect(option, same);
      expect(option.hashCode, same.hashCode);
      expect(
        operatorEquals(option, TextOption('Forest Gnome', 'Printed text.')),
        isFalse,
      );
      expect(operatorEquals(option, 'Forest Gnome'), isFalse);
      expect(
        () => option.spellIds.add(SpellId('mending')),
        throwsUnsupportedError,
      );
    });
  });

  /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-016 -
  ///   the option family is sealed with exactly the three variants, and a
  ///   switch is exhaustive without a default.
  /// Path: happy
  test('a switch over the option family selects its case', () {
    String describe(ChoiceOption option) => switch (option) {
      DamageTypeOption() => 'damageType',
      LineageOption() => 'lineage',
      TextOption() => 'text',
    };

    expect(describe(DamageTypeOption('Black', DamageType.acid)), 'damageType');
    expect(
      describe(
        LineageOption('Drow', [
          _benefit(1, 'dancing_lights'),
          _benefit(3, 'faerie_fire'),
          _benefit(5, 'darkness'),
        ]),
      ),
      'lineage',
    );
    expect(describe(TextOption('Forest Gnome', 'text')), 'text');
  });

  /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-016 -
  ///   toString is a debugging form for every variant.
  /// Path: happy
  test('the options print their parts', () {
    expect(
      DamageTypeOption('Black', DamageType.acid).toString(),
      'DamageTypeOption(Black, acid)',
    );
    expect(
      LineageOption('Drow', [
        _benefit(1, 'dancing_lights'),
        _benefit(3, 'faerie_fire'),
        _benefit(5, 'darkness'),
      ]).toString(),
      'LineageOption(Drow)',
    );
    expect(
      TextOption('Forest Gnome', 'text').toString(),
      'TextOption(Forest Gnome)',
    );
  });

  /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-016 and
  ///   FR-069 - the option-name rule is a public predicate the decoder
  ///   reuses.
  /// Path: happy
  test('the option-name rule is a public predicate', () {
    expect(ChoiceOption.isValidName('Forest Gnome'), isTrue);
    expect(ChoiceOption.isValidName(''), isFalse);
    expect(ChoiceOption.isValidName(' Forest Gnome'), isFalse);
  });

  /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-016 -
  ///   variants of one family are never equal across types.
  /// Path: happy
  test('options of different variants are not equal', () {
    final damageType = DamageTypeOption('Black', DamageType.acid);
    final text = TextOption('Black', 'text');

    expect(operatorEquals(damageType, text), isFalse);
    expect(operatorEquals(text, damageType), isFalse);
  });
}
