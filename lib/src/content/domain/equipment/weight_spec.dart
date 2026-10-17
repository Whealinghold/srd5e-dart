import 'package:meta/meta.dart';

import '../named_text.dart';

/// A printed weight, as the table prints it: a number of pounds, the word
/// "Varies", or an em dash for no weight (FR-013).
///
/// The sealed family replaces a nullable weight plus a boolean flag: a row
/// with a weight holds a [Weight], the Ammunition and Arcane Focus families
/// hold [WeightVaries], and the rows printed "—" (the Sling, the Spell Scroll
/// family) hold [NoWeight] ("Weapons", SRD 5.2.1, p. 91; Adventuring Gear
/// table, p. 95). Switch over it exhaustively, with no default branch.
@immutable
sealed class WeightSpec {
  const WeightSpec();
}

/// A weight printed as a number of pounds, with an optional printed
/// parenthetical such as "(full)" (FR-013, FR-035).
@immutable
final class Weight extends WeightSpec {
  /// The lightest weight an entry may carry, in pounds (FR-080). The
  /// constant the decoder reuses instead of repeating the literal (FR-094).
  static const double minPounds = 0.0;

  /// Whether [pounds] is a weight an entry may carry: [minPounds] or more
  /// (FR-080). The predicate the decoder reuses (FR-094).
  static bool isValidPounds(num pounds) => pounds >= minPounds;

  /// Creates a weight of [pounds] pounds with the printed [note].
  ///
  /// Throws an [ArgumentError] carrying the name `note` and the offending
  /// value when [note] is present but blank (FR-115). The multiple-of-0.25
  /// rule is a bundled-data check, not a constructor rule (FR-015).
  Weight(this.pounds, {String? note}) : note = _validatedNote(note);

  /// The weight in pounds.
  final double pounds;

  /// The printed parenthetical after the weight, verbatim, or null when the
  /// table prints none (FR-115).
  final String? note;

  static String? _validatedNote(String? note) {
    if (note != null && !NamedText.isValidText(note)) {
      throw ArgumentError.value(
        note,
        'note',
        'must contain at least one non-whitespace character',
      );
    }
    return note;
  }

  @override
  bool operator ==(Object other) =>
      other is Weight && other.pounds == pounds && other.note == note;

  @override
  int get hashCode => Object.hash(Weight, pounds, note);

  @override
  String toString() => 'Weight($pounds)';
}

/// A weight printed "Varies" (FR-013).
///
/// Held only by `ToolFamily` (the Gaming Set, p. 94), `GearFamily` and
/// `ScrollFamily` rows; `Weapon` and `Armor` never hold it, as their tables
/// print a number or an em dash (FR-106).
@immutable
final class WeightVaries extends WeightSpec {
  /// The single instance; the printed word carries no data.
  const WeightVaries();

  @override
  bool operator ==(Object other) => other is WeightVaries;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'WeightVaries()';
}

/// A weight printed "—": the entry has none (FR-013).
@immutable
final class NoWeight extends WeightSpec {
  /// The single instance; the printed em dash carries no data.
  const NoWeight();

  @override
  bool operator ==(Object other) => other is NoWeight;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'NoWeight()';
}
