import 'package:srd5e/src/content/domain/classes/class_column.dart';
import 'package:srd5e/src/content/domain/classes/column_value.dart';
import 'package:srd5e/src/content/domain/classes/feature_fact.dart';
import 'package:srd5e/src/content/domain/classes/progression_row.dart';
import 'package:srd5e/src/content/domain/feat_category.dart';
import 'package:srd5e/src/content/domain/typed_ids.dart';
import 'package:test/test.dart';

import '../../../support/argument_error_matcher.dart';

final _eightSlots = [2, 1, 0, 0, 0, 0, 0, 0];
final _twoMarkers = [const RowSubclassFeature(), const RowSubclassFeature()];
final _nineSlotList = [2, 1, 0, 0, 0, 0, 0, 0, 0];
final _zeroSlots = [0, 0, 0, 0, 0, 0, 0, 0, 0];
final _negativeSlots = [-1, 0, 0, 0, 0, 0, 0, 0, 0];

ProgressionRow _row({
  int level = 1,
  List<RowFeature> features = const [],
  SpellcastingRow? spellcasting,
}) => ProgressionRow(
  level: level,
  proficiencyBonus: 2,
  features: features,
  spellcasting: spellcasting,
  values: const {},
);

SlotSpellcastingRow _slotRow({
  int? cantrips = 2,
  required List<int> spellSlots,
}) => SlotSpellcastingRow(
  cantrips: cantrips,
  preparedSpells: 4,
  spellSlots: spellSlots,
);

PactSpellcastingRow _pactRow({required int slotLevel, int spellSlots = 2}) =>
    PactSpellcastingRow(
      cantrips: 2,
      preparedSpells: 1,
      spellSlots: spellSlots,
      slotLevel: slotLevel,
    );

void main() {
  /// Requirement: doc/specs/content-classes.md FR-037, FR-038 - a row's
  ///   level is 1 to 20 and its Proficiency Bonus an integer of at least 1
  ///   (SRD 5.2.1, "Proficiency Bonus", p. 8).
  /// Path: happy
  group('ProgressionRow constructor rows', () {
    /// Requirement: per case
    /// Path: per case
    for (final c in [
      (
        label: 'level 1',
        requirement:
            'doc/specs/content-classes.md FR-037 - level 1 is accepted',
        path: 'happy',
        build: () => _row(level: 1),
        throwsFor: null,
      ),
      (
        label: 'level 20',
        requirement:
            'doc/specs/content-classes.md FR-037 - level 20 is accepted',
        path: 'unhappy (boundary)',
        build: () => _row(level: 20),
        throwsFor: null,
      ),
      (
        label: 'level 0',
        requirement:
            'doc/specs/content-classes.md FR-037 - level 0 is rejected',
        path: 'unhappy (boundary)',
        build: () => _row(level: 0),
        throwsFor: throwsArgumentErrorFor('level', 0),
      ),
      (
        label: 'level 21',
        requirement:
            'doc/specs/content-classes.md FR-037 - level 21 is rejected',
        path: 'unhappy (boundary)',
        build: () => _row(level: 21),
        throwsFor: throwsArgumentErrorFor('level', 21),
      ),
      (
        label: 'proficiency bonus zero',
        requirement:
            'doc/specs/content-classes.md FR-038 - a Proficiency Bonus of 0 '
            'is rejected',
        path: 'unhappy (boundary)',
        build: () => ProgressionRow(
          level: 1,
          proficiencyBonus: 0,
          features: const [],
          values: const {},
        ),
        throwsFor: throwsArgumentErrorFor('proficiencyBonus', 0),
      ),
      (
        label: 'two subclass markers',
        requirement:
            'doc/specs/content-classes.md FR-043 - a row holds at most one '
            'subclass marker (Cases PR: "two subclass markers")',
        path: 'unhappy (boundary)',
        build: () => _row(features: _twoMarkers),
        throwsFor: throwsArgumentErrorFor('features', _twoMarkers),
      ),
      (
        label: 'blank annotation',
        requirement:
            'doc/specs/content-classes.md FR-043 - an annotation is '
            'non-blank (Cases PR: "blank annotation")',
        path: 'unhappy (invalid input)',
        build: () => _row(
          features: [
            RowClassFeature(FeatureId('fighter_action_surge'), annotation: ''),
          ],
        ),
        throwsFor: throwsArgumentErrorFor('annotation', ''),
      ),
    ]) {
      test('${c.label} [${c.path}]', () {
        if (c.throwsFor != null) {
          expect(c.build, c.throwsFor);
        } else {
          expect(c.build(), isA<ProgressionRow>());
        }
      });
    }
  });

  /// Requirement: doc/specs/content-classes.md FR-031 - a slot row carries
  ///   exactly nine non-negative slot counts; preparedSpells at least 0; a
  ///   printed em dash is stored as 0 (Cases SP rows).
  /// Path: happy
  group('SlotSpellcastingRow rows (Cases SP)', () {
    /// Requirement: per case
    /// Path: per case
    for (final c in [
      (
        label: 'nine slots',
        requirement:
            'doc/specs/content-classes.md FR-031 - nine integers are '
            'accepted (Cases SP: "nine slots")',
        path: 'happy',
        build: () => _slotRow(spellSlots: _nineSlotList),
        throwsFor: null,
      ),
      (
        label: 'eight slots',
        requirement:
            'doc/specs/content-classes.md FR-031 - a length other than nine '
            'is rejected (Cases SP: "eight slots")',
        path: 'unhappy (boundary)',
        build: () => _slotRow(spellSlots: _eightSlots),
        throwsFor: throwsArgumentErrorFor('spellSlots', _eightSlots),
      ),
      (
        label: 'negative slot',
        requirement:
            'doc/specs/content-classes.md FR-031 - a slot count below 0 is '
            'rejected (Cases SP: "negative slot")',
        path: 'unhappy (boundary)',
        build: () => _slotRow(spellSlots: _negativeSlots),
        throwsFor: throwsArgumentErrorFor('spellSlots', -1),
      ),
      (
        label: 'negative prepared',
        requirement:
            'doc/specs/content-classes.md FR-031 - preparedSpells below 0 '
            'is rejected',
        path: 'unhappy (boundary)',
        build: () => SlotSpellcastingRow(
          cantrips: 2,
          preparedSpells: -1,
          spellSlots: _zeroSlots,
        ),
        throwsFor: throwsArgumentErrorFor('preparedSpells', -1),
      ),
    ]) {
      test('${c.label} [${c.path}]', () {
        if (c.throwsFor != null) {
          expect(c.build, c.throwsFor);
        } else {
          expect(c.build(), isA<SlotSpellcastingRow>());
        }
      });
    }
  });

  /// Requirement: doc/specs/content-classes.md FR-032 - a Pact row carries
  ///   spellSlots at least 1 and a slot level from 1 to 9; 0 and 10 are
  ///   rejected (Cases SP rows; SRD 5.2.1, "Warlock Features", p. 71).
  /// Path: happy
  group('PactSpellcastingRow rows (Cases SP)', () {
    /// Requirement: per case
    /// Path: per case
    for (final c in [
      (
        label: 'slot level 9',
        requirement:
            'doc/specs/content-classes.md FR-032 - slot level 9 is accepted '
            '(Cases SP: "slot level 9")',
        path: 'unhappy (boundary)',
        build: () => _pactRow(slotLevel: 9),
        throwsFor: null,
      ),
      (
        label: 'slot level 0',
        requirement:
            'doc/specs/content-classes.md FR-032 - slot level 0 is rejected '
            '(Cases SP: "slot level 0")',
        path: 'unhappy (boundary)',
        build: () => _pactRow(slotLevel: 0),
        throwsFor: throwsArgumentErrorFor('slotLevel', 0),
      ),
      (
        label: 'slot level 10',
        requirement:
            'doc/specs/content-classes.md FR-032 - slot level 10 is '
            'rejected (Cases SP: "slot level 10")',
        path: 'unhappy (boundary)',
        build: () => _pactRow(slotLevel: 10),
        throwsFor: throwsArgumentErrorFor('slotLevel', 10),
      ),
      (
        label: 'zero slots',
        requirement:
            'doc/specs/content-classes.md FR-032 - spellSlots below 1 is '
            'rejected',
        path: 'unhappy (boundary)',
        build: () => _pactRow(slotLevel: 1, spellSlots: 0),
        throwsFor: throwsArgumentErrorFor('spellSlots', 0),
      ),
      (
        label: 'negative cantrips',
        requirement:
            'doc/specs/content-classes.md FR-032 - a cantrips count below 0 '
            'is rejected',
        path: 'unhappy (boundary)',
        build: () => PactSpellcastingRow(
          cantrips: -1,
          preparedSpells: 1,
          spellSlots: 2,
          slotLevel: 1,
        ),
        throwsFor: throwsArgumentErrorFor('cantrips', -1),
      ),
      (
        label: 'negative prepared',
        requirement:
            'doc/specs/content-classes.md FR-032 - a prepared-spells count '
            'below 0 is rejected',
        path: 'unhappy (boundary)',
        build: () => PactSpellcastingRow(
          cantrips: 2,
          preparedSpells: -1,
          spellSlots: 2,
          slotLevel: 1,
        ),
        throwsFor: throwsArgumentErrorFor('preparedSpells', -1),
      ),
    ]) {
      test('${c.label} [${c.path}]', () {
        if (c.throwsFor != null) {
          expect(c.build, c.throwsFor);
        } else {
          expect(c.build(), isA<PactSpellcastingRow>());
        }
      });
    }
  });

  /// Requirement: doc/specs/content-classes.md FR-031, FR-007 - the decoder
  ///   reuses `isValidSpellSlots`: exactly nine non-negative integers.
  /// Path: happy
  test('the isValidSpellSlots predicate agrees with the constructor', () {
    expect(SlotSpellcastingRow.isValidSpellSlots(_nineSlotList), isTrue);
    expect(SlotSpellcastingRow.isValidSpellSlots(_eightSlots), isFalse);
    expect(SlotSpellcastingRow.isValidSpellSlots(_negativeSlots), isFalse);
  });

  /// Requirement: doc/specs/content-classes.md FR-031, FR-032, FR-038 - the
  ///   decoder-reused count predicates and the Proficiency Bonus bound are
  ///   inclusive at their minimum: a count of 0, one spell slot and a
  ///   Proficiency Bonus of exactly 1 are accepted.
  /// Path: happy
  test(
    'the count and Proficiency Bonus bounds are inclusive at the minimum',
    () {
      expect(SlotSpellcastingRow.isValidCount(0), isTrue);
      expect(PactSpellcastingRow.isValidCount(0), isTrue);
      expect(PactSpellcastingRow.isValidSlotCount(1), isTrue);
      expect(
        ProgressionRow(
          level: 1,
          proficiencyBonus: ProgressionRow.minProficiencyBonus,
          features: const [],
          values: const {},
        ).proficiencyBonus,
        ProgressionRow.minProficiencyBonus,
      );
      expect(
        _pactRow(slotLevel: PactSpellcastingRow.minSlotLevel, spellSlots: 1),
        isA<PactSpellcastingRow>(),
      );
    },
  );

  /// Requirement: doc/specs/content-classes.md FR-031 - a slot row without
  ///   cantrips is accepted (the Paladin's rows).
  /// Path: happy
  test('a slot row without cantrips is accepted', () {
    final row = _slotRow(cantrips: null, spellSlots: _zeroSlots);
    expect(row.cantrips, isNull);
    expect(row.preparedSpells, 4);
  });

  /// Requirement: doc/specs/content-classes.md FR-050 - `value` returns the
  ///   column's value and throws for an undeclared id.
  /// Path: unhappy (invalid input)
  test('value returns the declared value and rejects an undeclared id', () {
    final id = ClassColumnId('rages');
    final row = ProgressionRow(
      level: 1,
      proficiencyBonus: 2,
      features: const [],
      values: {id: ColumnCount(2)},
    );
    expect(row.value(id), ColumnCount(2));
    expect(
      () => row.value(ClassColumnId('luck')),
      throwsArgumentErrorFor('id', ClassColumnId('luck')),
    );
  });

  /// Requirement: doc/specs/content-classes.md FR-043, FR-008 - the row's
  ///   features and values are unmodifiable and the caller's input is
  ///   defensively copied; value equality holds.
  /// Path: unhappy (immutability)
  test('collections are defensively copied and unmodifiable', () {
    final features = [RowClassFeature(FeatureId('barbarian_rage'))];
    final values = {ClassColumnId('rages'): ColumnCount(2)};
    final row = ProgressionRow(
      level: 1,
      proficiencyBonus: 2,
      features: features,
      spellcasting: _slotRow(spellSlots: _zeroSlots),
      values: values,
    );
    features.clear();
    values.clear();
    expect(row.features.length, 1);
    expect(row.values.length, 1);
    expect(() => row.features.clear(), throwsUnsupportedError);
    expect(() => row.values.clear(), throwsUnsupportedError);

    expect(
      row,
      equals(
        ProgressionRow(
          level: 1,
          proficiencyBonus: 2,
          features: [RowClassFeature(FeatureId('barbarian_rage'))],
          spellcasting: _slotRow(cantrips: 2, spellSlots: _zeroSlots),
          values: {ClassColumnId('rages'): ColumnCount(2)},
        ),
      ),
    );
    final twin = ProgressionRow(
      level: 1,
      proficiencyBonus: 2,
      features: [RowClassFeature(FeatureId('barbarian_rage'))],
      spellcasting: _slotRow(cantrips: 2, spellSlots: _zeroSlots),
      values: {ClassColumnId('rages'): ColumnCount(2)},
    );
    expect(row.hashCode, twin.hashCode);
    expect(row.toString(), 'ProgressionRow(level 1)');
  });

  /// Requirement: doc/specs/content-classes.md FR-043 - `RowFeature` is
  ///   sealed with exactly the two variants; `SpellcastingRow` with exactly
  ///   the two variants; both exhaustive in a `switch` without a default.
  /// Path: happy
  test('the row families switch exhaustively', () {
    String describeFeature(RowFeature feature) => switch (feature) {
      RowClassFeature() => 'class',
      RowSubclassFeature() => 'subclass',
    };
    String describePart(SpellcastingRow part) => switch (part) {
      SlotSpellcastingRow() => 'slot',
      PactSpellcastingRow() => 'pact',
    };
    expect(describeFeature(const RowSubclassFeature()), 'subclass');
    expect(
      describeFeature(RowClassFeature(FeatureId('barbarian_rage'))),
      'class',
    );
    expect(describePart(_pactRow(slotLevel: 1)), 'pact');
    expect(describePart(_slotRow(spellSlots: _zeroSlots)), 'slot');

    final slot = _slotRow(spellSlots: _zeroSlots);
    expect(slot.hashCode, _slotRow(spellSlots: _zeroSlots).hashCode);
    expect(slot.toString(), startsWith('SlotSpellcastingRow('));
    final pact = _pactRow(slotLevel: 1);
    expect(pact, equals(_pactRow(slotLevel: 1)));
    expect(pact.hashCode, _pactRow(slotLevel: 1).hashCode);
    expect(pact, isNot(equals(_pactRow(slotLevel: 2))));
    expect(pact.toString(), startsWith('PactSpellcastingRow('));
  });

  /// Requirement: doc/specs/content-classes.md FR-043, FR-008 - markers and
  ///   annotations participate in equality with other domain values.
  /// Path: happy
  test('markers and annotations participate in equality', () {
    expect(const RowSubclassFeature(), equals(const RowSubclassFeature()));
    expect(
      const RowSubclassFeature().hashCode,
      const RowSubclassFeature().hashCode,
    );
    expect(const RowSubclassFeature().toString(), 'RowSubclassFeature');
    final annotated = RowClassFeature(
      FeatureId('fighter_action_surge'),
      annotation: 'one use',
    );
    expect(
      annotated,
      equals(
        RowClassFeature(
          FeatureId('fighter_action_surge'),
          annotation: 'one use',
        ),
      ),
    );
    expect(
      annotated,
      isNot(equals(RowClassFeature(FeatureId('fighter_action_surge')))),
    );
    expect(annotated, isNot(equals(const GrantsFeat(FeatCategory.general))));
    expect(annotated.toString(), startsWith('RowClassFeature('));
  });
}
