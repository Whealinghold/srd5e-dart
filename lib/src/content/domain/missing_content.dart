import 'package:meta/meta.dart';

import 'content_id.dart';
import 'content_key.dart';
import 'content_kind.dart';

/// The detail that an entry a consumer asked for is absent (FR-147).
///
/// Other contexts' result variants hold it as a field when content they need
/// is missing; no shared variant exists. It compares by [kind] and [id] and
/// carries no display text.
@immutable
final class MissingContent {
  /// Creates the absence of the entry of [kind] named [id].
  const MissingContent(this.kind, this.id);

  /// The kind of the absent entry.
  final ContentKind kind;

  /// The id of the absent entry within its kind.
  final ContentId id;

  /// The key the entry would have had.
  ContentKey get key => ContentKey(kind, id);

  @override
  bool operator ==(Object other) =>
      other is MissingContent && other.kind == kind && other.id == id;

  @override
  int get hashCode => Object.hash(MissingContent, kind, id);

  @override
  String toString() => 'MissingContent(${key.toString()})';
}
