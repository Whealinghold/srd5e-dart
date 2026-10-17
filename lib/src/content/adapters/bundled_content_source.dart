import 'dart:collection' show UnmodifiableListView;

import '../application/content_decode_result.dart';
import '../application/content_problem.dart';
import '../application/ports/content_set_decoder.dart';
import '../application/ports/content_source.dart';
import '../data/embedded_documents.dart';
import '../domain/content_entry.dart';
import '../domain/content_key.dart';
import '../domain/content_kind.dart';
import '../domain/content_lookup.dart';
import '../domain/content_reference_problem.dart';
import '../domain/content_set.dart';
import '../domain/content_set_validation.dart';
import '../domain/validate_content_set.dart';
import 'in_memory_content_source.dart';
import 'json_content_set_decoder.dart';

/// Serves the embedded SRD content documents
/// (content-source-port.md FR-059 to FR-064): decodes each document text
/// once through a [ContentSetDecoder], runs [validateContentSet] over the
/// merged sets — the one place a reference between entries is checked — and
/// delegates every [lookup] and [listKind] to an [InMemoryContentSource]
/// over the validated entries. It adds no lookup logic of its own: its
/// results equal an `InMemoryContentSource` over the same entries.
///
/// The constructor is synchronous and runs the decode once, at build time
/// (FR-060): there is no second JSON reader, no file, network or `dart:io`
/// access, and no import of the generator tooling. The texts default to the
/// index of embedded documents (content-schema-and-decoder.md FR-122),
/// which every content data spec contributes to; a data spec that adds a
/// library needs no change here (FR-063). A document that fails to decode,
/// or a merged set that fails whole-set validation, throws
/// [BundledContentInvalid] — a bad bundle is a packaging error, not an
/// infrastructure failure (FR-061).
///
/// With an empty index it behaves as an empty source (FR-062), and building
/// it twice from the same texts yields sources whose results are equal,
/// entry for entry and in the same order.
final class BundledContentSource implements ContentSource {
  /// Builds the source over [texts] with [decoder].
  ///
  /// [texts] defaults to the embedded document index; [decoder] defaults to
  /// the real JSON decoder. Throws [BundledContentInvalid] when any document
  /// fails to decode or the merged set fails whole-set validation; it never
  /// returns a partial source (FR-061).
  factory BundledContentSource({
    Map<String, String>? texts,
    ContentSetDecoder? decoder,
  }) => BundledContentSource._from(
    texts ?? embeddedDocuments,
    decoder ?? const JsonContentSetDecoder(),
  );

  factory BundledContentSource._from(
    Map<String, String> texts,
    ContentSetDecoder decoder,
  ) {
    final decodeProblems = <ContentProblem>[];
    final sets = <ContentSet>[];
    for (final document in texts.values) {
      switch (decoder.decode(document)) {
        case ContentDecoded(contentSet: final set):
          sets.add(set);
        case ContentDecodeFailed(problems: final problems):
          decodeProblems.addAll(problems);
      }
    }
    // Validation runs only when every document decoded (FR-061), so a
    // decode failure is reported before any cross-entry check.
    if (decodeProblems.isNotEmpty) {
      throw BundledContentInvalid(decodeProblems: decodeProblems);
    }
    final ContentSet merged = switch (validateContentSet(sets)) {
      ContentSetValid(contentSet: final merged) => merged,
      ContentSetInvalid(problems: final problems) =>
        throw BundledContentInvalid(referenceProblems: problems),
    };
    return BundledContentSource._(InMemoryContentSource(merged.entries));
  }

  BundledContentSource._(this._delegate);

  final InMemoryContentSource _delegate;

  @override
  Future<ContentLookup> lookup(ContentKey key) => _delegate.lookup(key);

  @override
  Future<List<ContentEntry>> listKind(ContentKind kind) =>
      _delegate.listKind(kind);
}

/// The embedded SRD documents are not usable content
/// (content-source-port.md FR-061): a document failed to decode, or the
/// merged set failed the whole-set cross-reference validation.
///
/// A packaging error of the bundle itself, thrown by the
/// [BundledContentSource] constructor as an [Error] — not a
/// [ContentSourceException] (an infrastructure failure) and never a partial
/// source. It carries data, not display text: the two lists, at least one
/// of them non-empty.
final class BundledContentInvalid extends Error {
  /// Creates the error over the two problem lists.
  ///
  /// Both are copied and made unmodifiable. Throws an [ArgumentError]
  /// carrying the name `decodeProblems` and the empty list when both lists
  /// are empty: the error states at least one problem.
  BundledContentInvalid({
    List<ContentProblem> decodeProblems = const [],
    List<ContentReferenceProblem> referenceProblems = const [],
  }) : decodeProblems = UnmodifiableListView<ContentProblem>(
         List<ContentProblem>.of(decodeProblems),
       ),
       referenceProblems = UnmodifiableListView<ContentReferenceProblem>(
         List<ContentReferenceProblem>.of(referenceProblems),
       ) {
    if (decodeProblems.isEmpty && referenceProblems.isEmpty) {
      throw ArgumentError.value(
        decodeProblems,
        'decodeProblems',
        'and referenceProblems must not both be empty',
      );
    }
  }

  /// Every problem the decoder reported, in the decoder's order, document by
  /// document in index order; unmodifiable (FR-061).
  final List<ContentProblem> decodeProblems;

  /// Every problem the whole-set validation found over the merged sets, in
  /// its order; unmodifiable (FR-061). Validation runs only when every
  /// document decoded, so a decode failure leaves it empty.
  final List<ContentReferenceProblem> referenceProblems;

  /// The debugging form. Not display text, and not to be relied on.
  @override
  String toString() =>
      'BundledContentInvalid(${decodeProblems.length} decode problems, '
      '${referenceProblems.length} reference problems)';
}
