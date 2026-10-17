import 'package:srd5e/src/content/domain/classes/armor_training_category.dart';
import 'package:test/test.dart';

void main() {
  /// Requirement: doc/specs/content-classes.md FR-022 - `armorTraining` is
  ///   the four categories in the SRD's order, JSON `Light`, `Medium`,
  ///   `Heavy`, `Shield` (SRD 5.2.1, "Core Wizard Traits" (None), p. 77).
  /// Path: happy
  test('the four categories carry their SRD spelling and order', () {
    expect(ArmorTrainingCategory.values.map((c) => c.jsonValue), [
      'Light',
      'Medium',
      'Heavy',
      'Shield',
    ]);
  });

  /// Requirement: doc/specs/content-classes.md FR-022, FR-007 - the decoder
  ///   reuses `fromJson`: the SRD spellings parse, another spelling and the
  ///   printed "None" give null (invalidValue at the decoder).
  /// Path: happy
  group('fromJson rows', () {
    /// Requirement: per case
    /// Path: per case
    for (final c in [
      (
        label: 'Shield',
        requirement:
            'doc/specs/content-classes.md FR-022 - the SRD spelling Shield '
            'parses',
        path: 'happy',
        input: 'Shield',
        expected: ArmorTrainingCategory.shield,
      ),
      (
        label: 'Light',
        requirement:
            'doc/specs/content-classes.md FR-022 - the SRD spelling Light '
            'parses',
        path: 'happy',
        input: 'Light',
        expected: ArmorTrainingCategory.light,
      ),
      (
        label: 'lower case',
        requirement:
            'doc/specs/content-classes.md FR-022 - another spelling gives '
            'null',
        path: 'unhappy (invalid input)',
        input: 'shield',
        expected: null,
      ),
      (
        label: 'None',
        requirement:
            'doc/specs/content-classes.md FR-022 - the printed "None" is an '
            'empty set, not a member',
        path: 'unhappy (invalid input)',
        input: 'None',
        expected: null,
      ),
    ]) {
      test('${c.label} [${c.path}]', () {
        expect(ArmorTrainingCategory.fromJson(c.input), c.expected);
      });
    }
  });
}
