import 'package:srd5e/src/content/application/content_decode_result.dart';
import 'package:srd5e/src/content/application/content_problem.dart';
import 'package:srd5e/src/content/domain/content_problem_kind.dart';
import 'package:srd5e/src/content/domain/content_set.dart';
import 'package:srd5e/testing.dart';
import 'package:test/test.dart';

import '../support/argument_error_matcher.dart';

ContentDecodeFailed _failed([String path = '']) =>
    ContentDecodeFailed([ContentProblem(path, ContentProblemKind.syntax)]);

void main() {
  /// Requirement: doc/specs/content-schema-and-decoder.md FR-087 - the
  ///   fake is scriptable per input: a map from document text to a result.
  /// Path: happy
  test('a scripted input returns its scripted result', () {
    final result = ContentDecoded(ContentSet(const []));
    final fake = FakeContentSetDecoder(results: {'doc': result});

    expect(fake.decode('doc'), same(result));
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-087 - a
  ///   scripted thrown error is thrown as is, after the input is recorded.
  /// Path: unhappy (failure)
  test('a scripted error is thrown and its input recorded', () {
    final error = StateError('port failure');
    final fake = FakeContentSetDecoder(errors: {'doc': error});

    expect(() => fake.decode('doc'), throwsSame(error));
    expect(fake.inputs, ['doc']);
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-087 - each
  ///   input is recorded in call order, unmodifiable.
  /// Path: happy
  test('inputs are recorded in order and cannot be mutated', () {
    final fake = FakeContentSetDecoder(
      results: const {},
      defaultResult: _failed(),
    );

    fake.decode('first');
    fake.decode('second');
    fake.decode('first');

    expect(fake.inputs, ['first', 'second', 'first']);
    expect(() => fake.inputs.clear(), throwsUnsupportedError);
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-087 - an
  ///   unscripted input falls back to the default result.
  /// Path: happy
  test('an unscripted input falls back to the default result', () {
    final fallback = _failed();
    final fake = FakeContentSetDecoder(
      results: {'scripted': ContentDecoded(ContentSet(const []))},
      defaultResult: fallback,
    );

    expect(fake.decode('anything'), same(fallback));
    expect(fake.decode('scripted'), isA<ContentDecoded>());
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-087 - an
  ///   unscripted input with no default is a test set-up bug: StateError.
  /// Path: unhappy (invalid input)
  test('an unscripted input without a default throws StateError', () {
    final fake = FakeContentSetDecoder();

    expect(() => fake.decode('doc'), throwsStateError);
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-087 - the
  ///   script maps are copied: changing the caller's maps afterwards
  ///   changes nothing.
  /// Path: unhappy (immutability)
  test('the scripts are copied at construction', () {
    final results = <String, ContentDecodeResult>{};
    final errors = <String, Object>{};
    final fake = FakeContentSetDecoder(
      results: results,
      errors: errors,
      defaultResult: _failed(),
    );
    results['late'] = ContentDecoded(ContentSet(const []));
    errors['late'] = StateError('late');

    expect(fake.decode('late'), isA<ContentDecodeFailed>());
  });

  /// Requirement: doc/specs/errors-and-results.md FR-021 - the failed
  ///   result the fake is given rejects an empty problem list (it is the
  ///   real result type, not a double of its own).
  /// Path: unhappy (invalid input)
  test('the fake builds real results, which reject an empty list', () {
    expect(
      () => ContentDecodeFailed(const []),
      throwsArgumentErrorFor('problems', const <ContentProblem>[]),
    );
  });
}

Matcher throwsSame(Object error) => throwsA(same(error));
