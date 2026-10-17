import 'package:srd5e/src/content/application/content_decode_result.dart';
import 'package:srd5e/src/content/application/ports/content_set_decoder.dart';
import 'package:test/test.dart';

/// The shared `ContentSetDecoder` contract suite
/// (content-schema-and-decoder.md FR-087).
///
/// It asserts only format-independent behaviour, so it runs against any
/// implementation of the port — the bundled `JsonContentSetDecoder` and the
/// scriptable `FakeContentSetDecoder` today, a consumer's own decoder for
/// another external format tomorrow. JSON-text behaviour (the envelope and
/// field rules) is tested on the real decoder alone, in
/// `test/content/adapters/`.
///
/// The suite is **not exported** from the package (exporting it would make
/// `package:test` a runtime dependency). To reuse it against your own
/// adapter, copy this file, register with [runContentSetDecoderContract],
/// and reuse the per-clause checks in your own self-tests.

/// Builds a fresh decoder for the suite.
typedef ContentSetDecoderFactory = ContentSetDecoder Function();

/// The small corpus the never-throws clause runs over: the given documents
/// plus junk around them, including the empty string.
List<String> contractCorpus(String validDocument, String invalidDocument) => [
  '',
  ' ',
  '{',
  validDocument,
  invalidDocument,
  '$invalidDocument ',
];

/// FR-087: the valid document gives `ContentDecoded`.
void expectDecodesValidDocument(ContentSetDecoder decoder, String valid) {
  expect(decoder.decode(valid), isA<ContentDecoded>());
}

/// FR-087: the invalid document gives `ContentDecodeFailed` with a
/// non-empty list.
void expectRejectsInvalidDocument(ContentSetDecoder decoder, String invalid) {
  final result = decoder.decode(invalid);
  expect(result, isA<ContentDecodeFailed>());
  expect((result as ContentDecodeFailed).problems, isNotEmpty);
}

/// FR-018, at port level: nothing thrown for any `String` of the corpus;
/// every answer is one of the two variants. A throw is a TestFailure, so
/// the self-tests can tell a contract breach from a crash.
void expectNeverThrows(ContentSetDecoder decoder, List<String> corpus) {
  for (final text in corpus) {
    Object? thrown;
    ContentDecodeResult? result;
    try {
      result = decoder.decode(text);
    } on Object catch (error) {
      thrown = error;
    }
    expect(thrown, isNull, reason: 'the port never throws for a String');
    expect(result, isA<ContentDecodeResult>());
  }
}

/// FR-087, FR-097: the same input twice gives equal results.
void expectEqualResultsOnRepeat(
  ContentSetDecoder decoder,
  String valid,
  String invalid,
) {
  expect(decoder.decode(valid), decoder.decode(valid));
  expect(decoder.decode(invalid), decoder.decode(invalid));
  expect(decoder.decode(''), decoder.decode(''));
}

/// Registers the shared contract suite against the implementation
/// [create] builds, over one [validDocument] and one [invalidDocument].
void runContentSetDecoderContract(
  String name,
  ContentSetDecoderFactory create, {
  required String validDocument,
  required String invalidDocument,
}) {
  /// Requirement: doc/specs/content-schema-and-decoder.md FR-087 - the
  ///   port contract holds for this implementation: the valid document
  ///   decodes, the invalid one is rejected, nothing throws for a String,
  ///   and the same input twice gives equal results.
  /// Path: happy
  group('ContentSetDecoder contract: $name', () {
    /// Requirement: doc/specs/content-schema-and-decoder.md FR-087 - the
    ///   valid document gives ContentDecoded.
    /// Path: happy
    test('the valid document gives ContentDecoded', () {
      expectDecodesValidDocument(create(), validDocument);
    });

    /// Requirement: doc/specs/content-schema-and-decoder.md FR-087 - the
    ///   invalid document gives ContentDecodeFailed with a non-empty list.
    /// Path: unhappy (invalid input)
    test('the invalid document gives a non-empty ContentDecodeFailed', () {
      expectRejectsInvalidDocument(create(), invalidDocument);
    });

    /// Requirement: per case - doc/specs/content-schema-and-decoder.md
    ///   FR-018 - the port never throws for a String; the corpus includes
    ///   the empty string.
    /// Path: per case
    for (final text in contractCorpus(validDocument, invalidDocument)) {
      test(
        'never throws for ${text.isEmpty ? '<the empty string>' : 'a ${text.length}-character input'}'
        ' [unhappy (invalid input)]',
        () {
          expect(create().decode(text), isA<ContentDecodeResult>());
        },
      );
    }

    /// Requirement: doc/specs/content-schema-and-decoder.md FR-087 - the
    ///   same input twice gives equal results (FR-097's equality, at port
    ///   level).
    /// Path: happy
    test('the same input twice gives equal results', () {
      final decoder = create();

      expectEqualResultsOnRepeat(decoder, validDocument, invalidDocument);
    });
  });
}
