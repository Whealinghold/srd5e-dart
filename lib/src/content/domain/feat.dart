import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import 'content_entry.dart';
import 'content_key.dart';
import 'content_reference.dart';
import 'feat_benefit.dart';
import 'feat_category.dart';
import 'named_text.dart';
import 'prerequisite.dart';
import 'source_citation.dart';
import 'typed_ids.dart';

/// A feat ("Parts of a Feat", SRD 5.2.1, p. 87) as one content entry of kind
/// [ContentKind.feat] (FR-033 to FR-040).
///
/// A feat has exactly one [category], one or more [benefits] (the
/// description is its benefits, prerequisites and repeatable text — there is
/// no whole-description field) and a [repeatable] flag whose printed
/// sentence is [repeatableText] (SX-2). It reports its category through
/// [featCategory] so a reference constraint can check it (FR-025, schema
/// FR-126); it carries no reference site of its own.
@immutable
final class Feat implements ContentEntry, HasFeatCategory {
  /// Creates a feat from a defensive copy of the collection fields.
  ///
  /// Throws an [ArgumentError] carrying the name of the offending field and
  /// value when [name] breaks the name rule (FR-027), [prerequisites] is
  /// present but empty (SX-4), [benefits] is empty (FR-033), [repeatableText]
  /// is present but blank (SX-2), or [repeatableText] and [repeatable]
  /// disagree: a repeatable feat requires the text, a non-repeatable feat
  /// forbids it (SX-2, FR-039).
  Feat({
    required this.id,
    required String name,
    this.source,
    required this.category,
    List<Prerequisite>? prerequisites,
    required List<FeatBenefit> benefits,
    required this.repeatable,
    String? repeatableText,
  }) : name = _validatedName(name),
       prerequisites = prerequisites == null
           ? null
           : List.unmodifiable(_validatedPrerequisites(prerequisites)),
       benefits = List.unmodifiable(_validatedBenefits(benefits)),
       repeatableText = _validatedRepeatableText(repeatableText, repeatable);

  /// The smallest number of benefits a feat may hold (FR-033). The constant
  /// the decoder reuses instead of repeating the literal (FR-069).
  static const int minBenefits = 1;

  /// The feat's id, as a typed id.
  final FeatId id;

  /// The feat's printed name ("Alert", "Grappler"), verbatim.
  final String name;

  /// Where the entry comes from, or null when the supplying document omits
  /// it (schema FR-034).
  final SourceCitation? source;

  /// The feat's category, exactly one per feat (FR-034).
  final FeatCategory category;

  /// The prerequisites, in printed order, or null when the feat has none —
  /// the JSON omits the field (FR-035). An empty list is rejected (SX-4);
  /// the clause shapes and ranges are the prerequisite family's own rules
  /// (schema FR-118). Unmodifiable.
  final List<Prerequisite>? prerequisites;

  /// The benefits, in printed order; unmodifiable, never empty (FR-033,
  /// FR-040).
  final List<FeatBenefit> benefits;

  /// Whether the feat can be taken more than once (FR-039).
  final bool repeatable;

  /// The printed "Repeatable" sentence, verbatim, required when
  /// [repeatable] is true and forbidden when it is false (SX-2, FR-039).
  final String? repeatableText;

  @override
  ContentKey get key => id.key;

  @override
  FeatCategory get featCategory => category;

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

  static List<Prerequisite> _validatedPrerequisites(
    List<Prerequisite> prerequisites,
  ) {
    if (prerequisites.isEmpty) {
      throw ArgumentError.value(
        prerequisites,
        'prerequisites',
        'must have at least one prerequisite',
      );
    }
    return prerequisites;
  }

  static List<FeatBenefit> _validatedBenefits(List<FeatBenefit> benefits) {
    if (benefits.length < minBenefits) {
      throw ArgumentError.value(
        benefits,
        'benefits',
        'must have at least $minBenefits benefit',
      );
    }
    return benefits;
  }

  static String? _validatedRepeatableText(
    String? repeatableText,
    bool repeatable,
  ) {
    if (repeatableText != null && !NamedText.isValidText(repeatableText)) {
      throw ArgumentError.value(
        repeatableText,
        'repeatableText',
        'must contain at least one non-whitespace character',
      );
    }
    if (repeatable && repeatableText == null) {
      throw ArgumentError.value(
        null,
        'repeatableText',
        'is required when the feat is repeatable',
      );
    }
    if (!repeatable && repeatableText != null) {
      throw ArgumentError.value(
        repeatableText,
        'repeatableText',
        'is forbidden when the feat is not repeatable',
      );
    }
    return repeatableText;
  }

  @override
  bool operator ==(Object other) =>
      other is Feat &&
      other.id == id &&
      other.name == name &&
      other.source == source &&
      other.category == category &&
      _samePrerequisites(other.prerequisites, prerequisites) &&
      const ListEquality<FeatBenefit>().equals(other.benefits, benefits) &&
      other.repeatable == repeatable &&
      other.repeatableText == repeatableText;

  @override
  int get hashCode => Object.hash(
    Feat,
    id,
    name,
    source,
    category,
    prerequisites == null ? null : Object.hashAll(prerequisites!),
    const ListEquality<FeatBenefit>().hash(benefits),
    repeatable,
    repeatableText,
  );

  @override
  String toString() => 'Feat(${id.id.value})';

  static bool _samePrerequisites(List<Prerequisite>? a, List<Prerequisite>? b) {
    if (a == null || b == null) return a == b;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
