import 'package:collection/collection.dart'
    show ListEquality, UnmodifiableListView;
import 'package:meta/meta.dart';

import 'content_entry.dart';
import 'content_key.dart';
import 'content_kind.dart';
import 'content_lookup.dart';

/// A pure, in-memory index of content entries (content-source-port.md
/// FR-046): every in-process source delegates to it, so the duplicate-key,
/// lookup and ordering rules are written and tested once.
///
/// Immutable and validated in the constructor: the entries are iterated
/// exactly once and copied (FR-046), two entries with one [ContentKey] are
/// rejected with an [ArgumentError] naming `entries` and carrying the
/// duplicate key (FR-021), and the same id under two kinds is two keys and
/// is accepted (FR-041). [lookup] answers per FR-008 to FR-010,
/// [ofKind](content-source-port.md FR-011, FR-012) returns the entries of
/// one kind ordered by id (ordinal, code-unit comparison) as an unmodifiable
/// list. Pure and synchronous: no `Future`, no I/O, no clock.
@immutable
final class ContentCatalogue {
  /// Creates the catalogue over a single-pass copy of [entries].
  ///
  /// Throws an [ArgumentError] carrying the name `entries` and the offending
  /// key when two entries share one [ContentKey]. The input is read exactly
  /// once, so a lazy or generated iterable works, and later mutation of the
  /// caller's collection changes nothing.
  factory ContentCatalogue(Iterable<ContentEntry> entries) {
    final list = entries.toList();
    final seen = <ContentKey>{};
    for (final entry in list) {
      if (!seen.add(entry.key)) {
        throw ArgumentError.value(entry.key, 'entries', 'is already held');
      }
    }
    list.sort(_byKindThenId);
    return ContentCatalogue._(List.unmodifiable(list), {
      for (final entry in list) entry.key: entry,
    }, _kindListsOf(list));
  }

  const ContentCatalogue._(this._entries, this._byKey, this._byKind);

  /// Every entry, ordered by kind (declaration order) then id (ordinal).
  final List<ContentEntry> _entries;

  /// The entry of each key; no key of another kind ever answers a lookup.
  final Map<ContentKey, ContentEntry> _byKey;

  /// The entries of each kind that has at least one, in id order.
  final Map<ContentKind, List<ContentEntry>> _byKind;

  /// Looks [key] up: the [ContentFound] entry, or the [ContentNotFound] key
  /// (content-source-port.md FR-008 to FR-010). Never throws.
  ContentLookup lookup(ContentKey key) {
    final entry = _byKey[key];
    return entry == null ? ContentNotFound(key) : ContentFound(entry);
  }

  /// Every entry of [kind], ordered by id (ordinal, FR-011); empty when
  /// there is none (FR-012). The list is unmodifiable (FR-013): mutating it
  /// throws an [UnsupportedError] and leaves the catalogue unchanged.
  List<ContentEntry> ofKind(ContentKind kind) =>
      _byKind[kind] ?? const <ContentEntry>[];

  @override
  bool operator ==(Object other) =>
      other is ContentCatalogue &&
      const ListEquality<ContentEntry>().equals(other._entries, _entries);

  @override
  int get hashCode => Object.hash(ContentCatalogue, Object.hashAll(_entries));

  @override
  String toString() => 'ContentCatalogue(${_entries.length} entries)';

  static int _byKindThenId(ContentEntry a, ContentEntry b) {
    final byKind = a.key.kind.index.compareTo(b.key.kind.index);
    if (byKind != 0) return byKind;
    return a.key.id.value.compareTo(b.key.id.value);
  }

  static Map<ContentKind, List<ContentEntry>> _kindListsOf(
    List<ContentEntry> sorted,
  ) {
    final lists = <ContentKind, List<ContentEntry>>{};
    for (final entry in sorted) {
      (lists[entry.key.kind] ??= []).add(entry);
    }
    return {
      for (final MapEntry(key: kind, value: list) in lists.entries)
        kind: UnmodifiableListView<ContentEntry>(list),
    };
  }
}
