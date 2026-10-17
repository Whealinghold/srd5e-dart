import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import '../named_text.dart';

/// One printed equipment item of a class starting-equipment option:
/// `{name, quantity}` (FR-024, FR-025).
///
/// The [name] is stored as printed, in the singular where the SRD prints a
/// count ("2 Daggers" is name "Dagger", quantity 2) with any parenthetical
/// kept ("Arcane Focus (Quarterstaff)"); the two lines that name a choice
/// rather than an item are stored verbatim after the count is removed
/// (FR-025). Names are never resolved to item ids. This is the class-side
/// type, sharing nothing with the background spec's same-shaped
/// `EquipmentItem` (D10, shared-types-and-ownership.md FR-047).
@immutable
final class ClassEquipmentItem {
  /// Creates an equipment item.
  ///
  /// Throws an [ArgumentError] carrying the name `name` or `quantity` and
  /// the offending value when [name] breaks the name rule or [quantity] is
  /// below [minQuantity] (FR-024).
  ClassEquipmentItem(String name, int quantity)
    : name = _validatedName(name),
      quantity = _validatedQuantity(quantity);

  /// The smallest quantity an item may hold: 1 (FR-024). The constant the
  /// decoder reuses instead of repeating the literal (FR-007).
  static const int minQuantity = 1;

  /// The item's printed name, verbatim, parenthetical included (FR-025).
  final String name;

  /// How many of the item the option grants (FR-024); at least [minQuantity].
  final int quantity;

  /// Whether [quantity] is a quantity an item may hold: [minQuantity] or
  /// more (FR-024). The predicate the decoder reuses (FR-007).
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
      other is ClassEquipmentItem &&
      other.name == name &&
      other.quantity == quantity;

  @override
  int get hashCode => Object.hash(ClassEquipmentItem, name, quantity);

  @override
  String toString() => 'ClassEquipmentItem($name, x$quantity)';
}

/// One option of a class's starting equipment: the printed items and the
/// gold the character receives with them, JSON `{"items": [...], "gold": n}`
/// (FR-024; SRD 5.2.1, "Core Fighter Traits: Starting Equipment", p. 47).
@immutable
final class ClassEquipmentOption {
  /// Creates an equipment option from a defensive copy of [items].
  ///
  /// Throws an [ArgumentError] carrying the name `gold` and the offending
  /// value when [gold] is below [minGold] (FR-024). [items] may be empty.
  ClassEquipmentOption(List<ClassEquipmentItem> items, int gold)
    : items = List.unmodifiable(items),
      gold = _validatedGold(gold);

  /// The lowest gold amount an option may carry: 0 (FR-024). The constant
  /// the decoder reuses instead of repeating the literal (FR-007).
  static const int minGold = 0;

  /// The printed items, in printed order; unmodifiable, possibly empty
  /// (FR-024).
  final List<ClassEquipmentItem> items;

  /// The gold the option grants, in GP (FR-024); at least [minGold].
  final int gold;

  /// Whether [gold] is a gold amount an option may carry: [minGold] or more
  /// (FR-024). The predicate the decoder reuses (FR-007).
  static bool isValidGold(int gold) => gold >= minGold;

  static int _validatedGold(int gold) {
    if (!isValidGold(gold)) {
      throw ArgumentError.value(gold, 'gold', 'must be $minGold or more');
    }
    return gold;
  }

  @override
  bool operator ==(Object other) =>
      other is ClassEquipmentOption &&
      other.gold == gold &&
      const ListEquality<ClassEquipmentItem>().equals(other.items, items);

  @override
  int get hashCode => Object.hash(
    ClassEquipmentOption,
    gold,
    const ListEquality<ClassEquipmentItem>().hash(items),
  );

  @override
  String toString() => 'ClassEquipmentOption($items, $gold GP)';
}

/// The two-or-three starting-equipment options a class offers, JSON keys
/// `A` and `B` and the optional `C` the Fighter prints (FR-024; SRD 5.2.1,
/// "Core Fighter Traits: Starting Equipment", p. 47).
@immutable
final class ClassStartingEquipment {
  /// Creates the options.
  ///
  /// The options validate themselves; the composite carries them as `a`,
  /// `b` and the optional `c` (JSON keys `A`, `B`, `C`).
  const ClassStartingEquipment({required this.a, required this.b, this.c});

  /// Option A.
  final ClassEquipmentOption a;

  /// Option B.
  final ClassEquipmentOption b;

  /// The optional option C (the Fighter's third choice), or null when the
  /// class prints only A and B (FR-024).
  final ClassEquipmentOption? c;

  @override
  bool operator ==(Object other) =>
      other is ClassStartingEquipment &&
      other.a == a &&
      other.b == b &&
      other.c == c;

  @override
  int get hashCode => Object.hash(ClassStartingEquipment, a, b, c);

  @override
  String toString() => 'ClassStartingEquipment(a: $a, b: $b, c: $c)';
}
