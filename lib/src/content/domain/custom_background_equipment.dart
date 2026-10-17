import 'package:meta/meta.dart';

import 'equipment_item_value.dart';
import 'equipment_options.dart';

/// Prices one [EquipmentItem] for the step-5 check, or returns null to mark
/// it unpriced (FR-073).
///
/// The valuation is caller-supplied — a host prices items from its own
/// equipment data — so the species-backgrounds-feats rules import nothing
/// from content-equipment.md (shared-types-and-ownership.md FR-047).
typedef EquipmentValuation = EquipmentItemValue? Function(EquipmentItem item);

/// Why a custom background's equipment option breaks step 5 of "Creating a
/// Background" (SRD 5.2.1, pp. 192-193), as a sealed family with exactly the
/// three problems FR-073 defines (SRD 5.2.1, p. 193; "Coins", p. 89).
///
/// Switch over it exhaustively, with no default branch.
@immutable
sealed class CustomBackgroundEquipmentProblem {
  const CustomBackgroundEquipmentProblem._();
}

/// The option is not worth 50 GP including the unspent gold: the sum of
/// every priced item's quantity times its copper pieces, plus the gold, is
/// not [requiredCopperPieces] (FR-073; 100 CP is 1 GP).
@immutable
final class EquipmentValueNotFiftyGold
    extends CustomBackgroundEquipmentProblem {
  /// Carries the computed [copperPieces] total.
  const EquipmentValueNotFiftyGold(this.copperPieces) : super._();

  /// The value a valid option totals: 50 GP (FR-073).
  static const int requiredCopperPieces = 5000;

  /// The computed total, in copper pieces.
  final int copperPieces;

  @override
  bool operator ==(Object other) =>
      other is EquipmentValueNotFiftyGold && other.copperPieces == copperPieces;

  @override
  int get hashCode => Object.hash(EquipmentValueNotFiftyGold, copperPieces);

  @override
  String toString() => 'EquipmentValueNotFiftyGold($copperPieces)';
}

/// The valuation could not price an item (FR-073). While any item is
/// unpriced the total check is skipped — an unpriced item is not counted as
/// 0 CP.
@immutable
final class EquipmentItemUnpriced extends CustomBackgroundEquipmentProblem {
  /// Names the unpriced [itemName].
  const EquipmentItemUnpriced(this.itemName) : super._();

  /// The name of the item the valuation returned null for.
  final String itemName;

  @override
  bool operator ==(Object other) =>
      other is EquipmentItemUnpriced && other.itemName == itemName;

  @override
  int get hashCode => Object.hash(EquipmentItemUnpriced, itemName);

  @override
  String toString() => 'EquipmentItemUnpriced($itemName)';
}

/// An item is priced as a Martial weapon or armor, which a custom background
/// package must not include (FR-073; SRD 5.2.1, "Creating a Background",
/// p. 193). A priced excluded item still counts toward the total.
@immutable
final class EquipmentItemExcluded extends CustomBackgroundEquipmentProblem {
  /// Names the excluded [itemName].
  const EquipmentItemExcluded(this.itemName) : super._();

  /// The name of the excluded item.
  final String itemName;

  @override
  bool operator ==(Object other) =>
      other is EquipmentItemExcluded && other.itemName == itemName;

  @override
  int get hashCode => Object.hash(EquipmentItemExcluded, itemName);

  @override
  String toString() => 'EquipmentItemExcluded($itemName)';
}

/// Checks step 5 of "Creating a Background" (SRD 5.2.1, p. 193) for one
/// equipment option of a custom background (FR-073): every item is priced,
/// none is a Martial weapon or armor, and the package is worth exactly 50 GP
/// including the unspent gold.
///
/// Pure and synchronous. Reports every problem in item order, then the
/// total, as an unmodifiable, possibly empty list. While any item is
/// unpriced the total check is skipped — an unpriced item is not counted as
/// 0 CP — and an excluded but priced item still counts toward the total.
/// Steps 1 to 4 are the `Background` shape and the whole-set validation
/// (FR-072); this function does not run on the four SRD backgrounds.
List<CustomBackgroundEquipmentProblem> customBackgroundEquipmentProblems(
  EquipmentOption option,
  EquipmentValuation valuation,
) {
  final problems = <CustomBackgroundEquipmentProblem>[];
  var allPriced = true;
  var copperPieces = option.gold * EquipmentItemValue.copperPiecesPerGold;
  for (final item in option.items) {
    final value = valuation(item);
    if (value == null) {
      problems.add(EquipmentItemUnpriced(item.name));
      allPriced = false;
    } else {
      copperPieces += item.quantity * value.copperPieces;
      if (value.isMartialWeaponOrArmor) {
        problems.add(EquipmentItemExcluded(item.name));
      }
    }
  }
  if (allPriced &&
      copperPieces != EquipmentValueNotFiftyGold.requiredCopperPieces) {
    problems.add(EquipmentValueNotFiftyGold(copperPieces));
  }
  return List.unmodifiable(problems);
}
