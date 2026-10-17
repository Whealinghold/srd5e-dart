import 'package:srd5e/src/content/domain/equipment_item_value.dart';
import 'package:test/test.dart';

import '../../support/argument_error_matcher.dart';
import '../../support/operator_equals.dart';

void main() {
  /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-073 -
  ///   a price of 0 copper pieces is accepted (the "zero-cost item" row).
  /// Path: happy
  test('holds a price of zero or more and the exclusion flag', () {
    final value = EquipmentItemValue(
      copperPieces: 0,
      isMartialWeaponOrArmor: false,
    );

    expect(value.copperPieces, 0);
    expect(value.isMartialWeaponOrArmor, isFalse);
    expect(
      EquipmentItemValue(
        copperPieces: 1000,
        isMartialWeaponOrArmor: true,
      ).isMartialWeaponOrArmor,
      isTrue,
    );
  });

  /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-073 -
  ///   a negative price is rejected (the "negative cost" row:
  ///   EquipmentItemValue(copperPieces: -1) is a constructor ArgumentError).
  /// Path: unhappy (invalid input)
  test('rejects a negative price', () {
    expect(
      () => EquipmentItemValue(copperPieces: -1, isMartialWeaponOrArmor: false),
      throwsArgumentErrorFor('copperPieces', -1),
    );
  });

  /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-073 and
  ///   FR-069 - the price floor and the coins conversion are public
  ///   constants the decoder and the step-5 function reuse ("Coins",
  ///   SRD 5.2.1, p. 89: 100 CP to 1 GP).
  /// Path: happy
  test('exposes the price floor and the copper-per-gold conversion', () {
    expect(EquipmentItemValue.minCopperPieces, 0);
    expect(EquipmentItemValue.copperPiecesPerGold, 100);
  });

  /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-073 -
  ///   value equality.
  /// Path: happy
  test('compares by price and flag', () {
    final value = EquipmentItemValue(
      copperPieces: 1000,
      isMartialWeaponOrArmor: false,
    );

    expect(
      value,
      EquipmentItemValue(copperPieces: 1000, isMartialWeaponOrArmor: false),
    );
    expect(
      value.hashCode,
      EquipmentItemValue(
        copperPieces: 1000,
        isMartialWeaponOrArmor: false,
      ).hashCode,
    );
    expect(
      operatorEquals(
        value,
        EquipmentItemValue(copperPieces: 1000, isMartialWeaponOrArmor: true),
      ),
      isFalse,
    );
    expect(
      operatorEquals(
        value,
        EquipmentItemValue(copperPieces: 999, isMartialWeaponOrArmor: false),
      ),
      isFalse,
    );
    expect(operatorEquals(value, 1000), isFalse);
  });

  /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-073 -
  ///   toString is a debugging form.
  /// Path: happy
  test('a value prints its parts', () {
    expect(
      EquipmentItemValue(
        copperPieces: 1000,
        isMartialWeaponOrArmor: true,
      ).toString(),
      'EquipmentItemValue(1000 CP, isMartialWeaponOrArmor: true)',
    );
  });
}
