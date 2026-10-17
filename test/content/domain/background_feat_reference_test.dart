import 'package:srd5e/src/content/domain/background_feat_reference.dart';
import 'package:srd5e/src/content/domain/typed_ids.dart';
import 'package:test/test.dart';

import '../../support/argument_error_matcher.dart';
import '../../support/operator_equals.dart';

void main() {
  /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-026 -
  ///   the qualifier is stored as its own field ("Acolyte has 'Cleric'").
  /// Path: happy
  test('holds a feat id and the printed qualifier', () {
    final reference = BackgroundFeatReference(
      FeatId('magic_initiate'),
      'Cleric',
    );

    expect(reference.featId, FeatId('magic_initiate'));
    expect(reference.choice, 'Cleric');
  });

  /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-026 -
  ///   Criminal and Soldier have no qualifier.
  /// Path: happy
  test('holds no qualifier when the feat has none', () {
    final reference = BackgroundFeatReference(FeatId('alert'));

    expect(reference.choice, isNull);
  });

  /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-026 -
  ///   a blank choice is invalidValue.
  /// Path: unhappy (invalid input)
  test('rejects a blank qualifier', () {
    expect(
      () => BackgroundFeatReference(FeatId('alert'), ' '),
      throwsArgumentErrorFor('choice', ' '),
    );
  });

  /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-026 -
  ///   value equality.
  /// Path: happy
  test('compares by feat id and choice', () {
    final reference = BackgroundFeatReference(
      FeatId('magic_initiate'),
      'Cleric',
    );

    expect(
      reference,
      BackgroundFeatReference(FeatId('magic_initiate'), 'Cleric'),
    );
    expect(
      reference.hashCode,
      BackgroundFeatReference(FeatId('magic_initiate'), 'Cleric').hashCode,
    );
    expect(
      operatorEquals(
        reference,
        BackgroundFeatReference(FeatId('magic_initiate'), 'Wizard'),
      ),
      isFalse,
    );
    expect(
      operatorEquals(reference, BackgroundFeatReference(FeatId('alert'))),
      isFalse,
    );
    expect(operatorEquals(reference, 'Cleric'), isFalse);
  });

  /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-025 -
  ///   toString is a debugging form.
  /// Path: happy
  test('a reference prints its id and qualifier', () {
    expect(
      BackgroundFeatReference(FeatId('alert')).toString(),
      'BackgroundFeatReference(alert)',
    );
    expect(
      BackgroundFeatReference(FeatId('magic_initiate'), 'Cleric').toString(),
      'BackgroundFeatReference(magic_initiate, Cleric)',
    );
  });
}
