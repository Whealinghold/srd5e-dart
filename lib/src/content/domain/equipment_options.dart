import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import 'named_text.dart';

/// One printed equipment item of a background's equipment option:
/// `{name, quantity}` (FR-030; SRD 5.2.1, "Equipment", p. 83).
///
/// A leading numeral in the printed text is the [quantity], not part of
/// [name] ("20 Arrows" is name "Arrows", quantity 20); a parenthetical stays
/// in [name] as printed ("Book (prayers)"); no numeral means quantity 1.
@immutable
final class EquipmentItem {
  /// Creates an equipment item.
  ///
  /// Throws an [ArgumentError] carrying the name `name` or `quantity` and
  /// the offending value when [name] breaks the name rule (FR-027) or
  /// [quantity] is below [minQuantity] (FR-030).
  EquipmentItem(String name, int quantity)
    : name = _validatedName(name),
      quantity = _validatedQuantity(quantity);

  /// The smallest quantity an item may hold (FR-030). The constant the
  /// decoder reuses instead of repeating the literal (FR-069).
  static const int minQuantity = 1;

  /// The item's printed name, verbatim, parenthetical included.
  final String name;

  /// How many of the item the option grants.
  final int quantity;

  /// Whether [quantity] is a quantity an item may hold: [minQuantity] or
  /// more (FR-030). The predicate the decoder reuses (FR-069).
  static bool isValidQuantity(int quantity) => quantity >= minQuantity;

  static String _validatedName(String name) {
    if (!NamedText.isValidName(name)) {
      throw ArgumentError.value(
        name,
        'name',
        'must be non-empty with no leading or trailing whitespace',
      );
    }
    return name;
  }

  static int _validatedQuantity(int quantity) {
    if (!isValidQuantity(quantity)) {
      throw ArgumentError.value(
        quantity,
        'quantity',
        'must be $minQuantity or more',
      );
    }
    return quantity;
  }

  @override
  bool operator ==(Object other) =>
      other is EquipmentItem &&
      other.name == name &&
      other.quantity == quantity;

  @override
  int get hashCode => Object.hash(EquipmentItem, name, quantity);

  @override
  String toString() => 'EquipmentItem($name, x$quantity)';
}

/// One option of a background's equipment: the printed items and the gold
/// the character receives with them (FR-029, FR-030; SRD 5.2.1, "Equipment",
/// p. 83).
@immutable
final class EquipmentOption {
  /// Creates an equipment option from a defensive copy of [items].
  ///
  /// Throws an [ArgumentError] carrying the name `gold` and the offending
  /// value when [gold] is below [minGold].
  EquipmentOption(List<EquipmentItem> items, int gold)
    : items = List.unmodifiable(items),
      gold = _validatedGold(gold);

  /// The lowest gold amount an option may carry: 0 or more (the section 5
  /// model's invariant for this type). The constant the decoder reuses
  /// (FR-069).
  static const int minGold = 0;

  /// The printed items, in printed order; unmodifiable, possibly empty.
  final List<EquipmentItem> items;

  /// The gold the option grants, 0 or more.
  final int gold;

  /// Whether [gold] is a gold amount an option may carry: [minGold] or more.
  /// The predicate the decoder reuses (FR-069).
  static bool isValidGold(int gold) => gold >= minGold;

  static int _validatedGold(int gold) {
    if (!isValidGold(gold)) {
      throw ArgumentError.value(gold, 'gold', 'must be $minGold or more');
    }
    return gold;
  }

  @override
  bool operator ==(Object other) =>
      other is EquipmentOption &&
      other.gold == gold &&
      const ListEquality<EquipmentItem>().equals(other.items, items);

  @override
  int get hashCode => Object.hash(
    EquipmentOption,
    gold,
    const ListEquality<EquipmentItem>().hash(items),
  );

  @override
  String toString() => 'EquipmentOption($items, $gold GP)';
}

/// The two equipment options a background offers, JSON keys `A` and `B`
/// ("choose A or B", SRD 5.2.1, p. 83) (FR-029).
@immutable
final class EquipmentOptions {
  /// Creates the options.
  const EquipmentOptions({required this.a, required this.b});

  /// Option A: the printed items and gold.
  final EquipmentOption a;

  /// Option B.
  final EquipmentOption b;

  @override
  bool operator ==(Object other) =>
      other is EquipmentOptions && other.a == a && other.b == b;

  @override
  int get hashCode => Object.hash(EquipmentOptions, a, b);

  @override
  String toString() => 'EquipmentOptions(a: $a, b: $b)';
}
