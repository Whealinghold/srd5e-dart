import 'package:collection/collection.dart'
    show ListEquality, UnmodifiableListView;
import 'package:meta/meta.dart';

import 'content_reference_problem.dart';
import 'content_set.dart';

/// The outcome of the whole-set cross-reference validation over one or more
/// [ContentSet]s (FR-125): the merged, valid set, or every cross-entry
/// problem found.
///
/// Switch over it exhaustively, with no default branch.
@immutable
sealed class ContentSetValidation {
  const ContentSetValidation();
}

/// The merged set of every given set is free of cross-entry problems
/// (FR-125).
///
/// [contentSet] holds the entries of all sets, merged and ordered as FR-071
/// orders a set (by kind, then id) — the set to serve lookups from.
@immutable
final class ContentSetValid extends ContentSetValidation {
  /// Carries the merged [contentSet].
  const ContentSetValid(this.contentSet);

  /// The merged, unmodifiable set (FR-071 order).
  final ContentSet contentSet;

  @override
  bool operator ==(Object other) =>
      other is ContentSetValid && other.contentSet == contentSet;

  @override
  int get hashCode => Object.hash(ContentSetValid, contentSet);

  @override
  String toString() => 'ContentSetValid($contentSet)';
}

/// The merged sets carry cross-entry problems (FR-125).
///
/// The list is non-empty, ordered as FR-127 orders it (by owner kind, then
/// owner id, then the order the entry lists its references), an unmodifiable
/// defensive copy; the constructor throws an [ArgumentError] for an empty
/// list (FR-017, FR-093).
@immutable
final class ContentSetInvalid extends ContentSetValidation {
  /// Creates the result over an ordered copy of [problems].
  ///
  /// Throws an [ArgumentError] carrying the name `problems` when the list is
  /// empty: an invalid result states at least one problem.
  factory ContentSetInvalid(List<ContentReferenceProblem> problems) {
    if (problems.isEmpty) {
      throw ArgumentError.value(
        problems,
        'problems',
        'must hold at least one cross-entry problem',
      );
    }
    return ContentSetInvalid._(
      UnmodifiableListView<ContentReferenceProblem>(
        List<ContentReferenceProblem>.of(problems),
      ),
    );
  }

  const ContentSetInvalid._(this.problems);

  /// Every cross-entry problem, in FR-127 order; unmodifiable.
  final List<ContentReferenceProblem> problems;

  @override
  bool operator ==(Object other) =>
      other is ContentSetInvalid &&
      const ListEquality<ContentReferenceProblem>().equals(
        other.problems,
        problems,
      );

  @override
  int get hashCode => Object.hash(ContentSetInvalid, Object.hashAll(problems));

  @override
  String toString() => 'ContentSetInvalid(${problems.length} problems)';
}
