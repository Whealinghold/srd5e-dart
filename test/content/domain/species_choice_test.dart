import 'package:srd5e/src/content/domain/choice_option.dart';
import 'package:srd5e/src/content/domain/damage_type.dart';
import 'package:srd5e/src/content/domain/level_benefit.dart';
import 'package:srd5e/src/content/domain/species_choice.dart';
import 'package:srd5e/src/content/domain/typed_ids.dart';
import 'package:test/test.dart';

import '../../support/argument_error_matcher.dart';
import '../../support/operator_equals.dart';

ChoiceOption _lineage(String name) => LineageOption(name, [
  LevelBenefit(1, 'first', SpellId('dancing_lights')),
  LevelBenefit(3, 'second', SpellId('faerie_fire')),
  LevelBenefit(5, 'third', SpellId('darkness')),
]);

void main() {
  /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-016 -
  ///   a choice holds the trait it extends and its options (SX-1).
  /// Path: happy
  test('holds a trait name and its options', () {
    final choice = SpeciesChoice('Elven Lineage', [
      _lineage('Drow'),
      _lineage('High Elf'),
    ]);

    expect(choice.traitName, 'Elven Lineage');
    expect(choice.options, hasLength(2));
    expect(choice.options[0].name, 'Drow');
    expect(choice.options[1].name, 'High Elf');
  });

  /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-016 -
  ///   an empty options list is outOfRange.
  /// Path: unhappy (empty case)
  test('rejects an empty options list', () {
    expect(
      () => SpeciesChoice('Elven Lineage', []),
      throwsArgumentErrorFor('options', isEmpty),
    );
  });

  /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-016 -
  ///   a repeated option name is duplicate at the later index.
  /// Path: unhappy (invalid input)
  test('rejects a repeated option name', () {
    expect(
      () =>
          SpeciesChoice('Elven Lineage', [_lineage('Drow'), _lineage('Drow')]),
      throwsArgumentErrorFor('options', 'Drow'),
    );
    // A repeat is caught whatever sits between the repeats: one differing
    // earlier option must not hide it.
    expect(
      () => SpeciesChoice('Elven Lineage', [
        _lineage('Drow'),
        _lineage('High Elf'),
        _lineage('Drow'),
      ]),
      throwsArgumentErrorFor('options', 'Drow'),
    );
  });

  /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-016 -
  ///   a differing variant is a constraintViolation: every option of one
  ///   choice has the same variant.
  /// Path: unhappy (rule interaction)
  test('rejects options of differing variants', () {
    expect(
      () => SpeciesChoice('Elven Lineage', [
        _lineage('Drow'),
        TextOption('High Elf', 'text'),
      ]),
      throwsArgumentErrorFor('options', isA<TextOption>()),
    );
  });

  /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-060 -
  ///   the trait name rule (the link to the species' traits is the
  ///   Species constructor's check).
  /// Path: unhappy (invalid input)
  test('rejects a blank trait name', () {
    expect(
      () => SpeciesChoice(' ', [_lineage('Drow')]),
      throwsArgumentErrorFor('traitName', ' '),
    );
  });

  /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-016 and
  ///   FR-069 - the minimum option count is a public constant the decoder
  ///   reuses.
  /// Path: happy
  test('exposes the minimum option count', () {
    expect(SpeciesChoice.minOptions, 1);
  });

  /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-016 -
  ///   value equality and an unmodifiable options list.
  /// Path: happy
  test('compares by trait name and options, unmodifiable', () {
    final choice = SpeciesChoice('Elven Lineage', [_lineage('Drow')]);
    final same = SpeciesChoice('Elven Lineage', [_lineage('Drow')]);

    expect(choice, same);
    expect(choice.hashCode, same.hashCode);
    expect(
      operatorEquals(
        choice,
        SpeciesChoice('Gnomish Lineage', [_lineage('Drow')]),
      ),
      isFalse,
    );
    expect(operatorEquals(choice, 'Elven Lineage'), isFalse);
    expect(
      () => choice.options.add(_lineage('Wood Elf')),
      throwsUnsupportedError,
    );
  });

  /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-016 -
  ///   toString is a debugging form.
  /// Path: happy
  test('a choice prints its trait name', () {
    expect(
      SpeciesChoice('Draconic Ancestry', [
        DamageTypeOption('Black', DamageType.acid),
      ]).toString(),
      'SpeciesChoice(Draconic Ancestry)',
    );
  });
}
