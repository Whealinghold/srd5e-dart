import 'package:srd5e/src/content/adapters/json_content_set_decoder.dart';
import 'package:srd5e/src/content/application/content_decode_result.dart';
import 'package:srd5e/src/content/application/content_problem.dart';
import 'package:srd5e/src/content/domain/content_problem_kind.dart';
import 'package:srd5e/src/content/domain/content_set.dart';
import 'package:srd5e/src/testing/fake_content_set_decoder.dart';

import 'content_set_decoder_contract.dart';

/// A minimal synthetic species document for the real decoder: shape data
/// invented for the suite, not SRD content.
const _validDocument =
    '{"schemaVersion":1,"species":[{"id":"fixture","name":"Fixture",'
    '"creatureType":"Humanoid","sizes":["Medium"],"speed":30,'
    '"traits":[{"name":"Trait","text":"Its text."}]}]}';

/// A minimal document the real decoder rejects.
const _invalidDocument = '{"schemaVersion":1,"bogus":1}';

ContentDecodeFailed _failedWithSyntax() =>
    ContentDecodeFailed([const ContentProblem('', ContentProblemKind.syntax)]);

void main() {
  /// Requirement: doc/specs/content-schema-and-decoder.md FR-087 - the
  ///   real decoder runs the contract suite.
  /// Path: happy
  runContentSetDecoderContract(
    'JsonContentSetDecoder',
    JsonContentSetDecoder.new,
    validDocument: _validDocument,
    invalidDocument: _invalidDocument,
  );

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-087 - the
  ///   fake runs the same suite, scripted per input.
  /// Path: happy
  runContentSetDecoderContract(
    'FakeContentSetDecoder',
    () => FakeContentSetDecoder(
      results: {
        _validDocument: ContentDecoded(ContentSet(const [])),
        _invalidDocument: ContentDecodeFailed([
          const ContentProblem('/bogus', ContentProblemKind.unknownField),
        ]),
      },
      defaultResult: _failedWithSyntax(),
    ),
    validDocument: _validDocument,
    invalidDocument: _invalidDocument,
  );
}
