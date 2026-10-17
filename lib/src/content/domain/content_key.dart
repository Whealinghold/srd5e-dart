import 'package:meta/meta.dart';

import 'content_id.dart';
import 'content_kind.dart';

/// The identity of one content entry: its [ContentKind] and [ContentId]
/// together (FR-145).
///
/// Two keys are equal, with equal hash codes, iff both the kind and the id
/// are equal; the same id under two kinds is two keys.
@immutable
final class ContentKey {
  /// Creates the key of the entry of [kind] named [id].
  const ContentKey(this.kind, this.id);

  /// The kind of the entry.
  final ContentKind kind;

  /// The id of the entry within its kind.
  final ContentId id;

  @override
  bool operator ==(Object other) =>
      other is ContentKey && other.kind == kind && other.id == id;

  @override
  int get hashCode => Object.hash(kind, id);

  @override
  String toString() => '${kind.name}/${id.value}';
}
