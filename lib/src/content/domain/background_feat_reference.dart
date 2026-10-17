import 'package:meta/meta.dart';

import 'named_text.dart';
import 'typed_ids.dart';

/// The Origin feat a background grants, with the qualifier printed beside it
/// ("Parts of a Background: Feat", SRD 5.2.1, p. 83) (FR-025, FR-026).
///
/// [featId] is a reference site (FR-025), listed by [Background.references]
/// with the `TargetHasFeatCategory(Origin)` constraint and resolved by the
/// whole-set validation: construction cannot see the target's category, so a
/// host-built reference to a non-Origin feat is representable and only
/// validation rejects it (FR-072, step 2).
@immutable
final class BackgroundFeatReference {
  /// Creates a background feat reference.
  ///
  /// Throws an [ArgumentError] carrying the name `choice` and the offending
  /// value when [choice] is present but blank (FR-026).
  BackgroundFeatReference(this.featId, [String? choice])
    : choice = _validatedChoice(choice);

  /// The id of the granted feat.
  final FeatId featId;

  /// The printed qualifier ("Cleric", "Wizard"), as its own field, or null
  /// when the feat has none (FR-026).
  final String? choice;

  static String? _validatedChoice(String? choice) {
    if (choice != null && !NamedText.isValidText(choice)) {
      throw ArgumentError.value(choice, 'choice', 'must not be blank');
    }
    return choice;
  }

  @override
  bool operator ==(Object other) =>
      other is BackgroundFeatReference &&
      other.featId == featId &&
      other.choice == choice;

  @override
  int get hashCode => Object.hash(BackgroundFeatReference, featId, choice);

  @override
  String toString() => choice == null
      ? 'BackgroundFeatReference(${featId.id.value})'
      : 'BackgroundFeatReference(${featId.id.value}, $choice)';
}
