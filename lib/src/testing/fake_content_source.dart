import 'dart:collection' show UnmodifiableListView;

import '../content/content.dart';

/// A scriptable, recording test double [ContentSource]
/// (content-source-port.md FR-029 to FR-031): the in-memory content double
/// the use-case tests of code built on srd5e use.
///
/// Without a script it answers from the [ContentCatalogue] built over the
/// entries you give it, exactly like the real in-memory source, and passes
/// the source contract suite. Script it to fail [lookup], [listKind] or
/// both with one [ContentSourceException] each: the very instance supplied
/// is delivered through a failed future, never a synchronous throw (FR-030).
///
/// Every request is recorded in [requests], in call order, as a
/// [ContentQuery] (`ContentLookupQuery` or `ContentListKindQuery`),
/// unmodifiable (FR-031) — including the requests a scripted failure
/// answers.
///
/// The double is a double, not an adapter: it knows nothing about any
/// backend, which is why the contract suite can run against it beside the
/// real sources. It is exported only by `package:srd5e/testing.dart`.
final class FakeContentSource implements ContentSource {
  /// Creates the double over [entries], with optional per-operation
  /// failures.
  ///
  /// Throws an [ArgumentError] carrying the name `entries` and the duplicate
  /// key when two entries share one key, through the catalogue. The input is
  /// iterated once and copied; later mutation of the caller's collection
  /// changes nothing.
  FakeContentSource(
    Iterable<ContentEntry> entries, {
    ContentSourceException? lookupFailure,
    ContentSourceException? listKindFailure,
  }) : _catalogue = ContentCatalogue(entries),
       _lookupFailure = lookupFailure,
       _listKindFailure = listKindFailure;

  final ContentCatalogue _catalogue;

  final ContentSourceException? _lookupFailure;

  final ContentSourceException? _listKindFailure;

  final List<ContentQuery> _requests = [];

  /// Every request received, in call order; unmodifiable (FR-031).
  List<ContentQuery> get requests =>
      UnmodifiableListView<ContentQuery>(_requests);

  @override
  Future<ContentLookup> lookup(ContentKey key) {
    _requests.add(ContentLookupQuery(key));
    final failure = _lookupFailure;
    if (failure != null) return Future<ContentLookup>.error(failure);
    return Future<ContentLookup>.value(_catalogue.lookup(key));
  }

  @override
  Future<List<ContentEntry>> listKind(ContentKind kind) {
    _requests.add(ContentListKindQuery(kind));
    final failure = _listKindFailure;
    if (failure != null) return Future<List<ContentEntry>>.error(failure);
    return Future<List<ContentEntry>>.value(_catalogue.ofKind(kind));
  }
}
