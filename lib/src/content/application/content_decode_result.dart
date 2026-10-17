import 'package:collection/collection.dart'
    show ListEquality, UnmodifiableListView;
import 'package:meta/meta.dart';

import '../domain/content_set.dart';
import 'content_problem.dart';

/// The outcome of one `ContentSetDecoder.decode` call (FR-001): the decoded
/// [ContentSet], or every problem found.
///
/// The port never throws for content (FR-018): every failure to decode is a
/// [ContentDecodeFailed]. Switch over the result exhaustively, with no
/// default branch.
@immutable
sealed class ContentDecodeResult {
  const ContentDecodeResult();
}

/// The document decoded (FR-001).
@immutable
final class ContentDecoded extends ContentDecodeResult {
  /// Carries the decoded [contentSet].
  const ContentDecoded(this.contentSet);

  /// The decoded entries; immutable, its lists unmodifiable (FR-071).
  final ContentSet contentSet;

  @override
  bool operator ==(Object other) =>
      other is ContentDecoded && other.contentSet == contentSet;

  @override
  int get hashCode => Object.hash(ContentDecoded, contentSet);

  @override
  String toString() => 'ContentDecoded($contentSet)';
}

/// The document was rejected (FR-001).
///
/// [problems] holds every problem found, in the deterministic order of
/// FR-016; it is never empty (the constructor throws an [ArgumentError] for
/// an empty list, FR-017) and is an unmodifiable defensive copy: later
/// changes to the caller's list leave the result unchanged.
@immutable
final class ContentDecodeFailed extends ContentDecodeResult {
  /// Creates the failure over an ordered copy of [problems].
  ///
  /// Throws an [ArgumentError] carrying the name `problems` when the list is
  /// empty (FR-017).
  factory ContentDecodeFailed(List<ContentProblem> problems) {
    if (problems.isEmpty) {
      throw ArgumentError.value(
        problems,
        'problems',
        'must hold at least one problem',
      );
    }
    return ContentDecodeFailed._(
      UnmodifiableListView<ContentProblem>(List<ContentProblem>.of(problems)),
    );
  }

  const ContentDecodeFailed._(this.problems);

  /// Every problem found, in FR-016 order; unmodifiable.
  final List<ContentProblem> problems;

  @override
  bool operator ==(Object other) =>
      other is ContentDecodeFailed &&
      const ListEquality<ContentProblem>().equals(other.problems, problems);

  @override
  int get hashCode =>
      Object.hash(ContentDecodeFailed, Object.hashAll(problems));

  @override
  String toString() => 'ContentDecodeFailed(${problems.length} problems)';
}
