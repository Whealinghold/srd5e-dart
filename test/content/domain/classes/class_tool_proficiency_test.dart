import 'package:srd5e/src/content/domain/classes/class_tool_proficiency.dart';
import 'package:test/test.dart';

import '../../../support/argument_error_matcher.dart';

const _emptyCategories = <String>[];

void main() {
  /// Requirement: doc/specs/content-classes.md FR-023 - a tool proficiency
  ///   is a specific tool (non-blank name) or a choice of non-empty,
  ///   distinct, non-blank categories with picks at least 1 (SRD 5.2.1,
  ///   "Core Bard Traits" (Choose 3 Musical Instruments), p. 31).
  /// Path: happy
  group('ClassToolProficiency constructor rows', () {
    /// Requirement: per case
    /// Path: per case
    for (final c in [
      (
        label: 'a specific tool',
        requirement:
            'doc/specs/content-classes.md FR-023 - the Rogue\'s "Thieves\' '
            'Tools" is a specific proficiency',
        path: 'happy',
        build: () => ClassToolProficiencySpecific('Thieves’ Tools'),
        throwsFor: null,
      ),
      (
        label: 'a choice',
        requirement:
            'doc/specs/content-classes.md FR-023 - the Bard\'s choice of 3 '
            'musical instruments constructs',
        path: 'happy',
        build: () => ClassToolProficiencyChoice(['Musical Instrument'], 3),
        throwsFor: null,
      ),
      (
        label: 'blank specific name',
        requirement:
            'doc/specs/content-classes.md FR-023 - a blank specific name is '
            'rejected',
        path: 'unhappy (invalid input)',
        build: () => ClassToolProficiencySpecific(' '),
        throwsFor: throwsArgumentErrorFor('name', ' '),
      ),
      (
        label: 'empty categories',
        requirement:
            'doc/specs/content-classes.md FR-023 - empty categories are '
            'rejected',
        path: 'unhappy (boundary)',
        build: () => ClassToolProficiencyChoice(_emptyCategories, 1),
        throwsFor: throwsArgumentErrorFor('categories', _emptyCategories),
      ),
      (
        label: 'blank category',
        requirement:
            'doc/specs/content-classes.md FR-023 - a blank category is '
            'rejected',
        path: 'unhappy (invalid input)',
        build: () => ClassToolProficiencyChoice([' '], 1),
        throwsFor: throwsArgumentErrorFor('categories', ' '),
      ),
      (
        label: 'duplicate category',
        requirement:
            'doc/specs/content-classes.md FR-023 - a repeated category is '
            'rejected',
        path: 'unhappy (boundary)',
        build: () => ClassToolProficiencyChoice(const [
          'Musical Instrument',
          'Musical Instrument',
        ], 1),
        throwsFor: throwsArgumentErrorFor('categories', 'Musical Instrument'),
      ),
      (
        label: 'duplicate category after another',
        requirement:
            'doc/specs/content-classes.md FR-023 - a repeat is rejected '
            'wherever it sits: a repeat after a different category is '
            'rejected too',
        path: 'unhappy (boundary)',
        build: () => ClassToolProficiencyChoice(const [
          'Musical Instrument',
          "Artisan's Tools",
          'Musical Instrument',
        ], 1),
        throwsFor: throwsArgumentErrorFor('categories', 'Musical Instrument'),
      ),
      (
        label: 'picks zero',
        requirement:
            'doc/specs/content-classes.md FR-023 - picks 0 is rejected',
        path: 'unhappy (boundary)',
        build: () => ClassToolProficiencyChoice(['Musical Instrument'], 0),
        throwsFor: throwsArgumentErrorFor('picks', 0),
      ),
    ]) {
      test('${c.label} [${c.path}]', () {
        if (c.throwsFor != null) {
          expect(c.build, c.throwsFor);
        } else {
          expect(c.build(), isA<ClassToolProficiency>());
        }
      });
    }
  });

  /// Requirement: doc/specs/content-classes.md FR-023 - the type is sealed
  ///   with exactly the two variants, exhaustive in a `switch` without a
  ///   default; the constants and predicates are public.
  /// Path: happy
  test('the family switches exhaustively and the limits are public', () {
    String describe(ClassToolProficiency proficiency) => switch (proficiency) {
      ClassToolProficiencySpecific() => 'specific',
      ClassToolProficiencyChoice() => 'choice',
    };
    expect(
      describe(ClassToolProficiencySpecific('Thieves’ Tools')),
      'specific',
    );
    expect(
      describe(ClassToolProficiencyChoice(['Musical Instrument'], 3)),
      'choice',
    );

    expect(ClassToolProficiencyChoice.minPicks, 1);
    expect(ClassToolProficiencyChoice.isValidPicks(1), isTrue);
    expect(ClassToolProficiencyChoice.isValidPicks(0), isFalse);
    expect(
      ClassToolProficiencyChoice.isValidCategory('Musical Instrument'),
      isTrue,
    );
    expect(ClassToolProficiencyChoice.isValidCategory(' '), isFalse);
  });

  /// Requirement: doc/specs/content-classes.md FR-008 - value equality and
  ///   a consistent hash code; the categories list is unmodifiable.
  /// Path: happy
  test('value equality and unmodifiability hold', () {
    final choice = ClassToolProficiencyChoice(['Musical Instrument'], 3);
    expect(
      choice,
      equals(ClassToolProficiencyChoice(['Musical Instrument'], 3)),
    );
    expect(
      choice.hashCode,
      ClassToolProficiencyChoice(['Musical Instrument'], 3).hashCode,
    );
    expect(
      choice,
      isNot(equals(ClassToolProficiencyChoice(['Musical Instrument'], 2))),
    );
    expect(
      () => choice.categories.add("Artisan's Tools"),
      throwsUnsupportedError,
    );
    expect(
      ClassToolProficiencySpecific('Thieves’ Tools'),
      equals(ClassToolProficiencySpecific('Thieves’ Tools')),
    );
    expect(
      ClassToolProficiencySpecific('Thieves’ Tools').hashCode,
      ClassToolProficiencySpecific('Thieves’ Tools').hashCode,
    );
    expect(
      ClassToolProficiencySpecific('Thieves’ Tools'),
      isNot(equals(ClassToolProficiencySpecific('Forgery Kit'))),
    );
    expect(
      ClassToolProficiencySpecific('Thieves’ Tools').toString(),
      'ClassToolProficiencySpecific(Thieves’ Tools)',
    );
    expect(
      choice.toString(),
      'ClassToolProficiencyChoice(3 from [Musical Instrument])',
    );
  });
}
