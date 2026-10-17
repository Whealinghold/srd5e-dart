import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import '../named_text.dart';
import '../source_citation.dart';
import '../typed_ids.dart';
import 'feature_entry.dart';
import 'progression_row.dart' show ProgressionRow;

/// A subclass, nested inside its class entry ("Barbarian Subclass: Path of
/// the Berserker", SRD 5.2.1, p. 30) (FR-070).
///
/// A class may have no subclasses (`"subclasses": []`). A subclass
/// constructed outside a class is validated against the class's
/// `subclassLevel` when added: the [ClassDefinition] constructor throws an
/// [ArgumentError] for an invalid combination (FR-073) — its features must
/// start at the subclass level and at least one must sit exactly there
/// (FR-071), and their ids are prefixed with the subclass id (FR-052,
/// FR-072).
@immutable
final class SubclassDefinition {
  /// Creates a subclass from a defensive copy of [features].
  ///
  /// Throws an [ArgumentError] carrying the name `name` or `features` and
  /// the offending value when [name] breaks the name rule (FR-070) or
  /// [features] is empty (FR-070). The feature entries validate themselves.
  SubclassDefinition({
    required this.id,
    required String name,
    this.source,
    required List<FeatureEntry> features,
  }) : name = _validatedName(name),
       features = List.unmodifiable(_validatedFeatures(features));

  /// The subclass's id, as a typed id.
  final SubclassId id;

  /// The subclass's printed name, verbatim ("Path of the Berserker").
  final String name;

  /// Where the entry comes from, or null when the supplying document omits
  /// it (schema FR-034).
  final SourceCitation? source;

  /// The subclass's feature entries, in document order (ascending level,
  /// then printed order, as FR-051 describes); unmodifiable, never empty
  /// (FR-070).
  final List<FeatureEntry> features;

  /// The subclass features whose level does not exceed [level], in printed
  /// order — "you gain each of your subclass's features that are of your
  /// class level or lower" — and an empty list below the subclass level
  /// (FR-075; SRD 5.2.1, "Level 3: Barbarian Subclass", p. 29).
  ///
  /// Throws an [ArgumentError] carrying the name `level` and the offending
  /// value outside [ProgressionRow.minLevel] to [ProgressionRow.maxLevel].
  List<FeatureEntry> featuresAtOrBelow(int level) {
    if (level < ProgressionRow.minLevel || level > ProgressionRow.maxLevel) {
      throw ArgumentError.value(
        level,
        'level',
        'must be from ${ProgressionRow.minLevel} to '
            '${ProgressionRow.maxLevel}',
      );
    }
    return List.unmodifiable([
      for (final feature in features)
        if (feature.level <= level) feature,
    ]);
  }

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

  static List<FeatureEntry> _validatedFeatures(List<FeatureEntry> features) {
    if (features.isEmpty) {
      throw ArgumentError.value(
        features,
        'features',
        'must have at least one feature',
      );
    }
    return features;
  }

  @override
  bool operator ==(Object other) =>
      other is SubclassDefinition &&
      other.id == id &&
      other.name == name &&
      other.source == source &&
      const ListEquality<FeatureEntry>().equals(other.features, features);

  @override
  int get hashCode => Object.hash(
    SubclassDefinition,
    id,
    name,
    source,
    const ListEquality<FeatureEntry>().hash(features),
  );

  @override
  String toString() => 'SubclassDefinition(${id.id.value})';
}
