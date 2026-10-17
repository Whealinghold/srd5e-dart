import 'package:srd5e/adapters.dart';
import 'package:srd5e/src/content/data/embedded_documents.dart';
import 'package:srd5e/srd5e.dart';
import 'package:test/test.dart';

import 'support/real_repository.dart';
import 'support/source_set.dart';

/// The single architecture test over the bundled content
/// (doc/specs/content-schema-and-decoder.md FR-104; FR-089 and FR-090 have no
/// test of their own).
///
/// One walk: every `data/srd_5_2_1/*.json` file, taken from the SourceSet of
/// architecture-guardrails.md FR-002 (no file I/O of its own), and every
/// embedded document, taken from the index of FR-122. While no JSON file
/// exists and the index is empty the walk asserts that fact explicitly and
/// passes; it is never skipped.
final SourceSet _repository = realRepository;

const Timeout _budget = Timeout(Duration(seconds: 10));

const JsonContentSetDecoder _decoder = JsonContentSetDecoder();

/// The stem of a `data/srd_5_2_1/<stem>.json` path.
String _stemOf(String path) {
  final name = path.substring(path.lastIndexOf('/') + 1);
  return name.substring(0, name.length - '.json'.length);
}

/// Where [entry] carries its `source` citation; every content entry type
/// declares one. A type missing here fails the walk loudly instead of
/// skipping its citation check.
SourceCitation? _sourceOf(ContentEntry entry) => switch (entry) {
  Species(:final source) ||
  Background(:final source) ||
  Feat(:final source) ||
  ClassDefinition(:final source) ||
  Spell(:final source) ||
  Weapon(:final source) ||
  Armor(:final source) => source,
  _ => throw StateError(
    'The FR-104 walk does not know entry type ${entry.runtimeType}; '
    'add it to the citation check.',
  ),
};

ContentSet _decodedOrFail(String document, String origin) {
  final result = _decoder.decode(document);
  return switch (result) {
    ContentDecoded(contentSet: final set) => set,
    ContentDecodeFailed(problems: final problems) => throw StateError(
      '$origin failed to decode: '
      '${[for (final p in problems) '${p.kind} at ${p.path}'].join(', ')}',
    ),
  };
}

void main() {
  group('FR-104 bundled content', timeout: _budget, () {
    /// Requirement: doc/specs/content-schema-and-decoder.md FR-104, FR-089,
    ///   FR-090 - one walk over every `data/srd_5_2_1/*.json` file and every
    ///   embedded document: stem sets equal, each embedded string equal to
    ///   its file text, each text decoding alone to `ContentDecoded` with
    ///   zero problems, the merged set `ContentSetValid`, and every entry
    ///   citing the SRD (`citesSrd521`). While both sides are empty the
    ///   emptiness itself is asserted and the walk passes.
    /// Path: happy
    test('one walk over data/ and the embedded index', () {
      final jsonPaths = _repository.paths(
        prefix: 'data/srd_5_2_1/',
        suffix: '.json',
      );
      final stems = embeddedDocuments.keys.toList();
      if (jsonPaths.isEmpty) {
        // FR-104: while no `*.json` file exists and the index is empty, the
        // walk asserts that fact explicitly and passes; it is never skipped.
        expect(jsonPaths, isEmpty);
        expect(
          stems,
          isEmpty,
          reason:
              'data/srd_5_2_1/ holds no JSON file, so the embedded index '
              'must be empty too (FR-122)',
        );
        return;
      }

      final fileStems = [for (final path in jsonPaths) _stemOf(path)]..sort();
      expect(
        stems,
        fileStems,
        reason:
            'the embedded index and data/srd_5_2_1/ hold the same stems, '
            'in ordinal order (FR-122, FR-123)',
      );

      final sets = <ContentSet>[];
      for (final path in jsonPaths) {
        final text = _repository.files[path]!;
        final stem = _stemOf(path);
        final embedded = embeddedDocuments[stem]!;
        expect(
          embedded,
          text,
          reason: 'the embedded document of "$stem" equals its file text',
        );
        // Every file and every embedded string decodes on its own, with zero
        // problems (FR-089; no cross-file reference is a decode problem).
        final decoded = _decodedOrFail(text, 'data file $path');
        _decodedOrFail(embedded, 'embedded document "$stem"');
        // One decode is pooled per document: the duplicate rule of FR-125
        // flags any non-identical repeat of a ContentKey, and two decoder
        // calls return distinct instances even over byte-equal text.
        sets.add(decoded);
      }

      final validation = validateContentSet(sets);
      expect(
        validation,
        isA<ContentSetValid>(),
        reason: 'the merged documents hold no cross-entry problem (FR-140)',
      );

      for (final set in sets) {
        for (final entry in set.entries) {
          final source = _sourceOf(entry);
          expect(
            source,
            isNotNull,
            reason:
                'the bundled entry ${entry.key.id.value} has a source '
                '(FR-090)',
          );
          expect(
            source!.citesSrd521,
            isTrue,
            reason:
                'the source of ${entry.key.id.value} names '
                '${SourceCitation.srdDocument} up to page '
                '${SourceCitation.srdLastPage} (FR-090, FR-138)',
          );
        }
      }
    });
  });
}
