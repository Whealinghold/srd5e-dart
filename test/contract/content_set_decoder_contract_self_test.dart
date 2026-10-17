import 'package:srd5e/src/content/application/content_decode_result.dart';
import 'package:srd5e/src/content/application/content_problem.dart';
import 'package:srd5e/src/content/application/ports/content_set_decoder.dart';
import 'package:srd5e/src/content/domain/content_problem_kind.dart';
import 'package:srd5e/src/content/domain/content_set.dart';
import 'package:srd5e/src/testing/fake_content_set_decoder.dart';
import 'package:test/test.dart';

import 'content_set_decoder_contract.dart';

/// Deliberately bad doubles: each violates one clause of the port contract,
/// and the clause check must fail for it (testing.md §8: a test that cannot
/// fail is a defect).

const _validDocument = 'valid';
const _invalidDocument = 'invalid';

ContentDecodeFailed _failed() =>
    ContentDecodeFailed([const ContentProblem('', ContentProblemKind.syntax)]);

/// A decoder that throws for an input nobody scripted (here: the empty
/// string of the corpus).
final class _ThrowingDecoder implements ContentSetDecoder {
  @override
  ContentDecodeResult decode(String document) {
    if (document.isEmpty) {
      throw StateError('deliberately wrong: the port never throws');
    }
    return document == _validDocument
        ? ContentDecoded(ContentSet(const []))
        : _failed();
  }
}

/// A decoder that accepts the invalid document.
final class _AcceptingDecoder implements ContentSetDecoder {
  @override
  ContentDecodeResult decode(String document) =>
      ContentDecoded(ContentSet(const []));
}

/// A decoder that rejects the valid document.
final class _RejectingDecoder implements ContentSetDecoder {
  @override
  ContentDecodeResult decode(String document) => _failed();
}

/// A decoder whose result for the same input differs between calls.
final class _InconsistentDecoder implements ContentSetDecoder {
  var _firstCall = true;

  @override
  ContentDecodeResult decode(String document) {
    _firstCall = !_firstCall;
    return _firstCall ? ContentDecoded(ContentSet(const [])) : _failed();
  }
}

/// The correct implementation the failure cases are compared with: the
/// package's own fake, scripted.
ContentSetDecoder _correct() => FakeContentSetDecoder(
  results: {
    _validDocument: ContentDecoded(ContentSet(const [])),
    _invalidDocument: _failed(),
  },
  defaultResult: _failed(),
);

void main() {
  /// Requirement: doc/specs/content-schema-and-decoder.md FR-087,
  ///   FR-018 - the suite must be able to fail: a decoder that throws for
  ///   a String fails the never-throws clause.
  /// Path: unhappy (failure)
  test('a decoder that throws for a String fails the never-throws clause', () {
    expect(
      () => expectNeverThrows(
        _ThrowingDecoder(),
        contractCorpus(_validDocument, _invalidDocument),
      ),
      throwsA(isA<TestFailure>()),
    );
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-087 - a
  ///   decoder that accepts the invalid document fails the rejection
  ///   clause.
  /// Path: unhappy (failure)
  test('a decoder that accepts the invalid document fails the suite', () {
    expect(
      () => expectRejectsInvalidDocument(_AcceptingDecoder(), _invalidDocument),
      throwsA(isA<TestFailure>()),
    );
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-087 - a
  ///   decoder that rejects the valid document fails the acceptance
  ///   clause.
  /// Path: unhappy (failure)
  test('a decoder that rejects the valid document fails the suite', () {
    expect(
      () => expectDecodesValidDocument(_RejectingDecoder(), _validDocument),
      throwsA(isA<TestFailure>()),
    );
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-087, FR-097 -
  ///   a decoder whose repeat calls disagree fails the equal-results
  ///   clause.
  /// Path: unhappy (failure)
  test('an inconsistent decoder fails the equal-results clause', () {
    expect(
      () => expectEqualResultsOnRepeat(
        _InconsistentDecoder(),
        _validDocument,
        _invalidDocument,
      ),
      throwsA(isA<TestFailure>()),
    );
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-087 - a
  ///   correct implementation passes every clause, so the failures above
  ///   are for the right reason.
  /// Path: happy
  test('a correct implementation passes the same clauses', () {
    expectDecodesValidDocument(_correct(), _validDocument);
    expectRejectsInvalidDocument(_correct(), _invalidDocument);
    expectNeverThrows(
      _correct(),
      contractCorpus(_validDocument, _invalidDocument),
    );
    expectEqualResultsOnRepeat(_correct(), _validDocument, _invalidDocument);
  });
}
