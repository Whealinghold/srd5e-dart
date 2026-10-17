import 'package:meta/meta.dart';

import 'content_key.dart';
import 'feat_category.dart';

/// The sites of an entry that name another entry of the set (FR-125).
///
/// An entry type of a data spec implements this and lists exactly the sites
/// its revision row registers; an entry implementing no [ContentReferences]
/// has no sites. Every reference is resolved by the whole-set validation,
/// never by a single-document decoder, and no site is exempt.
@immutable
abstract interface class ContentReferences {
  /// The entry's reference sites, in the order the entry type declares.
  Iterable<ContentReference> get references;
}

/// One reference site of an entry: a field inside the owner that names a
/// target entry by its key, optionally under a constraint (FR-125, FR-126).
///
/// `field` is a path inside the owner entry, relative to it (for example
/// `feat/featId`). A reference carries no display text and adds no site of
/// its own.
@immutable
final class ContentReference {
  /// Creates a reference site.
  const ContentReference(this.field, this.target, [this.constraint]);

  /// The field inside the owner entry that holds the reference.
  final String field;

  /// The key of the entry the reference names.
  final ContentKey target;

  /// What the target must satisfy, or null when existence is enough.
  final ReferenceConstraint? constraint;

  @override
  bool operator ==(Object other) =>
      other is ContentReference &&
      other.field == field &&
      other.target == target &&
      other.constraint == constraint;

  @override
  int get hashCode => Object.hash(field, target, constraint);

  @override
  String toString() => 'ContentReference($field -> $target)';
}

/// What the target of a reference must satisfy (FR-126).
///
/// A sealed, value-equal, pure family with exactly one variant,
/// [TargetHasFeatCategory]; a further variant needs a revision row.
@immutable
sealed class ReferenceConstraint {
  const ReferenceConstraint();
}

/// The target must be an entry that [HasFeatCategory] reports the named
/// category for, such as a background's feat being of category `Origin`
/// (FR-126).
@immutable
final class TargetHasFeatCategory extends ReferenceConstraint {
  /// Creates the constraint that the target's category be [category].
  const TargetHasFeatCategory(this.category);

  /// The category the target must report.
  final FeatCategory category;

  @override
  bool operator ==(Object other) =>
      other is TargetHasFeatCategory && other.category == category;

  @override
  int get hashCode => Object.hash(TargetHasFeatCategory, category);

  @override
  String toString() => 'TargetHasFeatCategory(${category.name})';
}

/// An entry whose category a reference constraint can check, such as a feat
/// (FR-126).
@immutable
abstract interface class HasFeatCategory {
  /// The entry's category.
  FeatCategory get featCategory;
}
