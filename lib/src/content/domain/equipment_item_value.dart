import 'package:meta/meta.dart';

/// What an item of a custom background's equipment is worth to the step-5
/// check: its price in copper pieces and whether it is a Martial weapon or
/// armor, which such a package must not include (FR-073; SRD 5.2.1,
/// "Creating a Background", p. 193).
///
/// The value comes from the caller ([EquipmentValuation]), so this spec
/// imports nothing from content-equipment.md (shared-types-and-ownership.md
/// FR-047).
@immutable
final class EquipmentItemValue {
  /// Creates an equipment item value.
  ///
  /// Throws an [ArgumentError] carrying the name `copperPieces` and the
  /// offending value when [copperPieces] is below [minCopperPieces].
  EquipmentItemValue({
    required int copperPieces,
    required this.isMartialWeaponOrArmor,
  }) : copperPieces = _validatedCopperPieces(copperPieces);

  /// The smallest price an item may have: 0 or more (FR-073). The constant
  /// the decoder reuses instead of repeating the literal (FR-069).
  static const int minCopperPieces = 0;

  /// How many copper pieces one gold piece is ("Coins", SRD 5.2.1, p. 89:
  /// 100 CP to 1 GP), the conversion the step-5 total uses (FR-073).
  static const int copperPiecesPerGold = 100;

  /// The item's price, in copper pieces, 0 or more.
  final int copperPieces;

  /// Whether the item is a Martial weapon or armor.
  final bool isMartialWeaponOrArmor;

  static int _validatedCopperPieces(int copperPieces) {
    if (copperPieces < minCopperPieces) {
      throw ArgumentError.value(
        copperPieces,
        'copperPieces',
        'must be $minCopperPieces or more',
      );
    }
    return copperPieces;
  }

  @override
  bool operator ==(Object other) =>
      other is EquipmentItemValue &&
      other.copperPieces == copperPieces &&
      other.isMartialWeaponOrArmor == isMartialWeaponOrArmor;

  @override
  int get hashCode =>
      Object.hash(EquipmentItemValue, copperPieces, isMartialWeaponOrArmor);

  @override
  String toString() =>
      'EquipmentItemValue($copperPieces CP, '
      'isMartialWeaponOrArmor: $isMartialWeaponOrArmor)';
}
