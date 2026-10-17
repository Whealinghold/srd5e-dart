import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import '../named_text.dart';

/// A spell's Material component: its printed description, the "N+ GP"
/// minimum costs it states, and whether the spell consumes any of the
/// materials (FR-041 to FR-045).
///
/// The description is verbatim from the parentheses ("Material (M)",
/// SRD 5.2.1, pp. 105-106), with line breaks inside it replaced by single
/// spaces (FR-042). [costsGp] lists, in printed order, every figure written
/// as "N+ GP", with thousands separators removed (FR-043); a cost stated in
/// another currency is not listed — Gentle Repose's Copper Pieces keep the
/// list empty (FR-045). [consumesMaterial] is true exactly when the
/// description says the spell consumes any of the materials (FR-044).
@immutable
final class MaterialComponent {
  /// Creates the component with [description], [costsGp] and
  /// [consumesMaterial].
  ///
  /// Throws an [ArgumentError] carrying the name `description` and the
  /// offending value when [description] is empty or whitespace-only
  /// (FR-041), and the name `costsGp` and the offending value when an entry
  /// is below [MaterialComponent.minCostGp] (FR-101).
  MaterialComponent(
    String description,
    List<int> costsGp, {
    required this.consumesMaterial,
  }) : description = _validatedDescription(description),
       costsGp = List.unmodifiable(_validatedCosts(costsGp));

  /// The lowest "N+ GP" figure a [MaterialComponent] may list (FR-101,
  /// FR-111).
  static const int minCostGp = 1;

  /// Whether [costGp] is a valid "N+ GP" figure: at least [minCostGp]
  /// (FR-101, FR-111). The predicate the decoder reuses instead of
  /// repeating the bound.
  static bool isValidCostGp(int costGp) => costGp >= minCostGp;

  /// The printed description, verbatim (FR-041, FR-042).
  final String description;

  /// The "N+ GP" figures, in printed order; unmodifiable, possibly empty
  /// (FR-043).
  final List<int> costsGp;

  /// Whether the spell consumes any of the materials (FR-044).
  final bool consumesMaterial;

  static String _validatedDescription(String description) {
    if (!NamedText.isValidText(description)) {
      throw ArgumentError.value(
        description,
        'description',
        'must contain at least one non-whitespace character',
      );
    }
    return description;
  }

  static List<int> _validatedCosts(List<int> costsGp) {
    for (final cost in costsGp) {
      if (!MaterialComponent.isValidCostGp(cost)) {
        throw ArgumentError.value(
          cost,
          'costsGp',
          'must be at least ${MaterialComponent.minCostGp}',
        );
      }
    }
    return costsGp;
  }

  @override
  bool operator ==(Object other) =>
      other is MaterialComponent &&
      other.description == description &&
      const ListEquality<int>().equals(other.costsGp, costsGp) &&
      other.consumesMaterial == consumesMaterial;

  @override
  int get hashCode => Object.hash(
    MaterialComponent,
    description,
    const ListEquality<int>().hash(costsGp),
    consumesMaterial,
  );

  @override
  String toString() => 'MaterialComponent($description)';
}

/// A spell's Components entry: whether it has Verbal and Somatic components
/// and, when printed with M, its Material component ("Components",
/// SRD 5.2.1, p. 105) (FR-049).
///
/// A spell with M has a non-null [material]; a spell without M has null.
/// The letters are stored as typed values, never as a string of letters.
@immutable
final class SpellComponents {
  /// Creates the components with their [material] when the spell has M.
  SpellComponents({required this.verbal, required this.somatic, this.material});

  /// Whether the spell has a Verbal component.
  final bool verbal;

  /// Whether the spell has a Somatic component.
  final bool somatic;

  /// The Material component, or null when the spell has none (FR-049).
  final MaterialComponent? material;

  @override
  bool operator ==(Object other) =>
      other is SpellComponents &&
      other.verbal == verbal &&
      other.somatic == somatic &&
      other.material == material;

  @override
  int get hashCode => Object.hash(SpellComponents, verbal, somatic, material);

  @override
  String toString() =>
      'SpellComponents(v: $verbal, s: $somatic, m: ${material != null})';
}
