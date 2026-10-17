import 'package:srd5e/src/content/domain/feat_benefit.dart';
import 'package:test/test.dart';

import '../../support/argument_error_matcher.dart';
import '../../support/operator_equals.dart';

void main() {
  /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-040 -
  ///   a named benefit holds the printed heading and verbatim text
  ///   ("Initiative Proficiency").
  /// Path: happy
  test('holds a named benefit', () {
    final benefit = FeatBenefit(name: 'Initiative Proficiency', text: 'text.');

    expect(benefit.name, 'Initiative Proficiency');
    expect(benefit.text, 'text.');
  });

  /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-040 -
  ///   a feat printed as one block has exactly one benefit with no name.
  /// Path: happy
  test('holds an unnamed benefit', () {
    final benefit = FeatBenefit(text: 'text.');

    expect(benefit.name, isNull);
    expect(benefit.text, 'text.');
  });

  /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-063 -
  ///   a blank benefit name is invalidValue (schema FR-027).
  /// Path: unhappy (invalid input)
  test('rejects a blank name', () {
    expect(
      () => FeatBenefit(name: ' ', text: 'text.'),
      throwsArgumentErrorFor('name', ' '),
    );
    expect(
      () => FeatBenefit(name: ' Peerless Aim', text: 'text.'),
      throwsArgumentErrorFor('name', ' Peerless Aim'),
    );
  });

  /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-063 -
  ///   a blank benefit text is invalidValue (schema FR-028).
  /// Path: unhappy (invalid input)
  test('rejects a blank text', () {
    expect(() => FeatBenefit(text: ' '), throwsArgumentErrorFor('text', ' '));
  });

  /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-063 -
  ///   value equality.
  /// Path: happy
  test('compares by name and text', () {
    final benefit = FeatBenefit(name: 'Blink Steps', text: 'text.');

    expect(benefit, FeatBenefit(name: 'Blink Steps', text: 'text.'));
    expect(
      benefit.hashCode,
      FeatBenefit(name: 'Blink Steps', text: 'text.').hashCode,
    );
    expect(
      operatorEquals(benefit, FeatBenefit(name: 'Blink Steps', text: 'other.')),
      isFalse,
    );
    expect(operatorEquals(benefit, FeatBenefit(text: 'text.')), isFalse);
    expect(operatorEquals(benefit, 'Blink Steps'), isFalse);
  });

  /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-063 -
  ///   toString is a debugging form.
  /// Path: happy
  test('a benefit prints its parts', () {
    expect(
      FeatBenefit(name: 'Named', text: 'text.').toString(),
      'FeatBenefit(Named, text.)',
    );
    expect(FeatBenefit(text: 'text.').toString(), 'FeatBenefit(text.)');
  });
}
