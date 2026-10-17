import 'package:srd5e/adapters.dart';
import 'package:srd5e/src/content/application/content_decode_result.dart';
import 'package:srd5e/src/content/application/ports/content_source.dart';
import 'package:srd5e/src/content/data/embedded_documents.dart';
import 'package:srd5e/src/content/domain/content_entry.dart';
import 'package:srd5e/src/content/domain/content_key.dart';
import 'package:srd5e/src/content/domain/content_kind.dart';
import 'package:srd5e/src/content/domain/content_lookup.dart';
import 'package:srd5e/src/content/domain/content_query.dart';
import 'package:srd5e/src/content/domain/content_set.dart';
import 'package:srd5e/src/shared_ports/errors/port_failure_guards.dart';
import 'package:srd5e/testing.dart';

import 'content_source_contract.dart';

/// The registrations of content-source-port.md FR-047: every
/// `ContentSource` implementation the package ships runs the shared
/// contract suite here.
///
/// `InMemoryContentSource`, `FakeContentSource` and the test-only wrapping
/// adapter run [contentSourceContractChecks]; `BundledContentSource` runs
/// it through an injected `FakeContentSetDecoder` (it has no backend to
/// fail, so no failing group) and the read-only variant over the real
/// embedded libraries. Adding an implementation without registering it
/// fails the architecture scan in `test/architecture/`.
void main() {
  /// Requirement: doc/specs/content-source-port.md FR-047, FR-020 - the
  ///   in-memory source runs the full contract suite; it has no failing
  ///   backend, so no failing group.
  /// Path: happy
  runContentSourceChecks(
    'InMemoryContentSource',
    contentSourceContractChecks(create: InMemoryContentSource.new),
  );

  /// Requirement: doc/specs/content-source-port.md FR-047, FR-029 - the
  ///   double passes the suite when not scripted to fail (FR-029), so no
  ///   failing group.
  /// Path: happy
  runContentSourceChecks(
    'FakeContentSource',
    contentSourceContractChecks(create: FakeContentSource.new),
  );

  /// Requirement: doc/specs/content-source-port.md FR-047, FR-017 - the
  ///   test-only wrapping adapter wraps a throwing backend with
  ///   wrapPortFailureAsync, so the failing group runs.
  /// Path: happy
  runContentSourceChecks(
    'WrappingContentSource (test-only adapter)',
    contentSourceContractChecks(
      create: (entries) =>
          _WrappingContentSource(InMemoryContentSource(entries)),
      createFailing: (entries, backendFailure) =>
          _WrappingContentSource(_FailingBackend(backendFailure)),
    ),
  );

  /// Requirement: doc/specs/content-source-port.md FR-047, FR-059 -
  ///   BundledContentSource runs the suite through an injected
  ///   FakeContentSetDecoder; it has no backend to fail (FR-061), so no
  ///   failing group.
  /// Path: happy
  runContentSourceChecks(
    'BundledContentSource (scripted texts)',
    contentSourceContractChecks(
      create: (entries) => BundledContentSource(
        texts: {'x': 'x'},
        decoder: FakeContentSetDecoder(
          results: {'x': ContentDecoded(ContentSet(entries))},
        ),
      ),
    ),
  );

  /// Requirement: doc/specs/content-source-port.md FR-047, FR-058 -
  ///   BundledContentSource over the real embedded libraries runs the
  ///   read-only suite, with the entries decoded from them as the fixture.
  ///   The index is empty until the thin-slice change lands, so the fixture
  ///   is empty today; the checks still run.
  /// Path: happy
  runContentSourceChecks(
    'BundledContentSource (bundled index)',
    contentSourceReadOnlyChecks(
      source: BundledContentSource(),
      expectedEntries: _bundledEntries(),
    ),
  );
}

/// The entries of the real embedded libraries, decoded through the real
/// decoder: the fixture of the bundled read-only run.
///
/// A document that fails to decode is a broken bundle; the source
/// constructor would throw `BundledContentInvalid` on the same input, so
/// this fails loudly instead of passing an empty fixture by accident.
List<ContentEntry> _bundledEntries() {
  const decoder = JsonContentSetDecoder();
  final entries = <ContentEntry>[];
  for (final document in embeddedDocuments.values) {
    final ContentSet set = switch (decoder.decode(document)) {
      ContentDecoded(contentSet: final set) => set,
      ContentDecodeFailed(problems: final problems) => throw StateError(
        'the bundled index does not decode: '
        '${[for (final p in problems) '${p.kind} at ${p.path}'].join(', ')}',
      ),
    };
    entries.addAll(set.entries);
  }
  return entries;
}

/// A backend that throws one exception on every call, for the failing
/// group of the test-only wrapping adapter.
final class _FailingBackend implements ContentSource {
  _FailingBackend(this.failure);

  final Exception failure;

  @override
  Future<ContentLookup> lookup(ContentKey key) => throw failure;

  @override
  Future<List<ContentEntry>> listKind(ContentKind kind) => throw failure;
}

/// The test-only adapter of FR-047 and FR-027: wraps a [ContentSource]
/// backend with `wrapPortFailureAsync`, delivering a backend [Exception]
/// as the port's typed failure through the returned future.
///
/// It demonstrates the wrap the port documentation requires of a real
/// backend adapter, in the one place that can fail; the shipped sources
/// cannot fail (their catalogue answers from memory), and the
/// content/adapters/ layer imports nothing from shared_ports/errors/ (the
/// schema spec's FR-141), so the shipped ones wrap nothing.
final class _WrappingContentSource implements ContentSource {
  _WrappingContentSource(this._backend);

  final ContentSource _backend;

  @override
  Future<ContentLookup> lookup(ContentKey key) => wrapPortFailureAsync(
    () => _backend.lookup(key),
    (cause, stackTrace) => ContentSourceException(
      ContentLookupQuery(key),
      cause: cause,
      causeStackTrace: stackTrace,
    ),
  );

  @override
  Future<List<ContentEntry>> listKind(ContentKind kind) => wrapPortFailureAsync(
    () => _backend.listKind(kind),
    (cause, stackTrace) => ContentSourceException(
      ContentListKindQuery(kind),
      cause: cause,
      causeStackTrace: stackTrace,
    ),
  );
}
