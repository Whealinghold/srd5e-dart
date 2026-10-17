import 'package:collection/collection.dart' show ListEquality;
import 'package:meta/meta.dart';

import 'content_entry.dart';
import 'content_id.dart';
import 'content_key.dart';
import 'content_kind.dart';

/// The entries of one decoded document, or of several merged documents
/// (FR-071, FR-072).
///
/// A set is immutable: its [entries] are an unmodifiable list ordered by
/// [ContentKind] (declaration order) then [ContentId] (ordinal), independent
/// of the document order the entries arrived in. The constructor throws an
/// [ArgumentError] for two entries with one [ContentKey] — the one
/// cross-entry rule a constructor checks (FR-093); references and the Origin
/// rule are the whole-set validation's (FR-035, FR-140), so a set whose
/// background's feat is absent or not `Origin` is a valid [ContentSet].
@immutable
final class ContentSet {
  /// Creates a set over an ordered copy of [entries].
  ///
  /// Throws an [ArgumentError] carrying the name `entries` and the offending
  /// key when two entries share one [ContentKey].
  factory ContentSet(Iterable<ContentEntry> entries) {
    final list = entries.toList();
    final seen = <ContentKey>{};
    for (final entry in list) {
      if (!seen.add(entry.key)) {
        throw ArgumentError.value(entry.key, 'entries', 'is already held');
      }
    }
    list.sort(_byKindThenId);
    return ContentSet._(List.unmodifiable(list));
  }

  const ContentSet._(this.entries);

  /// The entries, ordered by [ContentKind] (declaration order) then
  /// [ContentId] (ordinal); unmodifiable (FR-071).
  final List<ContentEntry> entries;

  @override
  bool operator ==(Object other) =>
      other is ContentSet &&
      const ListEquality<ContentEntry>().equals(other.entries, entries);

  @override
  int get hashCode => Object.hash(ContentSet, Object.hashAll(entries));

  @override
  String toString() => 'ContentSet(${entries.length} entries)';

  static int _byKindThenId(ContentEntry a, ContentEntry b) {
    final byKind = a.key.kind.index.compareTo(b.key.kind.index);
    if (byKind != 0) return byKind;
    return a.key.id.value.compareTo(b.key.id.value);
  }
}
