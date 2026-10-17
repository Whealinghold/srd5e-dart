import '../application/ports/content_source.dart';
import '../domain/content_catalogue.dart';
import '../domain/content_entry.dart';
import '../domain/content_key.dart';
import '../domain/content_kind.dart';
import '../domain/content_lookup.dart';

/// A [ContentSource] over an in-memory list of entries
/// (content-source-port.md FR-020): a thin asynchronous wrapper over a
/// [ContentCatalogue], which owns the duplicate-key, lookup and ordering
/// rules.
///
/// The source copies its input at construction and never changes after
/// that: every [lookup] and [listKind] is answered by the catalogue, per
/// FR-008 to FR-014. There is no backend that can fail, so no call ever
/// completes with a [ContentSourceException] (FR-024); the futures
/// complete through microtasks only, never a `Timer`. A host whose content
/// lives in a file, a database or the network writes its own adapter and
/// wraps its backend failures with `wrapPortFailureAsync`.
///
/// Generic and bundled, it is exported from `package:srd5e/adapters.dart`
/// only; the test double is `FakeContentSource` in
/// `package:srd5e/testing.dart`.
final class InMemoryContentSource implements ContentSource {
  /// Creates the source over [entries].
  ///
  /// Throws an [ArgumentError] carrying the name `entries` and the
  /// duplicate key when two entries share one [ContentKey] (FR-021). The
  /// input is iterated exactly once (FR-023) and copied, so later mutation
  /// of the caller's collection changes nothing.
  InMemoryContentSource(Iterable<ContentEntry> entries)
    : _catalogue = ContentCatalogue(entries);

  final ContentCatalogue _catalogue;

  @override
  Future<ContentLookup> lookup(ContentKey key) async => _catalogue.lookup(key);

  @override
  Future<List<ContentEntry>> listKind(ContentKind kind) async =>
      _catalogue.ofKind(kind);
}
