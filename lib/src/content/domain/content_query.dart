import 'package:meta/meta.dart';

import 'content_key.dart';
import 'content_kind.dart';

/// What was asked of a content source (content-source-port.md FR-057): one
/// entry by [ContentLookupQuery], or every entry of one kind by
/// [ContentListKindQuery].
///
/// A pure value with no outcome in it: [ContentSourceException] carries the
/// query that failed and the `FakeContentSource` double records the queries
/// it received, so both name the operation through this one sealed type and
/// a `switch` over it is exhaustive without a default branch. Switch over it
/// exhaustively, with no default branch.
@immutable
sealed class ContentQuery {
  /// Creates the query.
  const ContentQuery();
}

/// The request of one entry: the [ContentSource.lookup] of [key]
/// (content-source-port.md FR-057).
@immutable
final class ContentLookupQuery extends ContentQuery {
  /// Creates the lookup request for [key].
  const ContentLookupQuery(this.key);

  /// The key whose entry was asked for.
  final ContentKey key;

  @override
  bool operator ==(Object other) =>
      other is ContentLookupQuery && other.key == key;

  @override
  int get hashCode => Object.hash(ContentLookupQuery, key);

  @override
  String toString() => 'ContentLookupQuery($key)';
}

/// The request of every entry of one kind: the [ContentSource.listKind] of
/// [kind] (content-source-port.md FR-057).
@immutable
final class ContentListKindQuery extends ContentQuery {
  /// Creates the list request for [kind].
  const ContentListKindQuery(this.kind);

  /// The kind whose entries were asked for.
  final ContentKind kind;

  @override
  bool operator ==(Object other) =>
      other is ContentListKindQuery && other.kind == kind;

  @override
  int get hashCode => Object.hash(ContentListKindQuery, kind);

  @override
  String toString() => 'ContentListKindQuery(${kind.name})';
}
