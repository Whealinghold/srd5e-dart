import 'package:meta/meta.dart';

import 'cost.dart';

/// A printed price, as the table prints it: a [Cost] or the word "Varies"
/// (FR-013).
///
/// The sealed family replaces a nullable cost plus a boolean flag (the
/// architecture rule against booleans standing in for named states): a table
/// row with a price holds a [FixedCost], the Gaming Set and Musical Instrument
/// families and the Spell Scroll family hold [CostVaries] ("Gaming Set",
/// SRD 5.2.1, p. 94; "Spell Scroll", p. 99). Switch over it exhaustively, with
/// no default branch.
@immutable
sealed class Price {
  const Price();
}

/// A price printed as a number and coin (FR-013).
@immutable
final class FixedCost extends Price {
  /// Wraps the printed [cost].
  const FixedCost(this.cost);

  /// The printed price.
  final Cost cost;

  @override
  bool operator ==(Object other) => other is FixedCost && other.cost == cost;

  @override
  int get hashCode => Object.hash(FixedCost, cost);

  @override
  String toString() => 'FixedCost($cost)';
}

/// A price printed "Varies" (FR-013).
///
/// Held only by `ToolFamily`, `GearFamily` and `ScrollFamily`; every other
/// entry type declares [FixedCost], so the type forbids a "Varies" price
/// elsewhere (FR-014).
@immutable
final class CostVaries extends Price {
  /// The single instance; the printed word carries no data.
  const CostVaries();

  @override
  bool operator ==(Object other) => other is CostVaries;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'CostVaries()';
}
