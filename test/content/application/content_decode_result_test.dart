import 'package:srd5e/src/content/application/content_decode_result.dart';
import 'package:srd5e/src/content/application/content_problem.dart';
import 'package:srd5e/src/content/application/schema_version.dart';
import 'package:srd5e/src/content/domain/content_problem_kind.dart';
import 'package:srd5e/src/content/domain/content_set.dart';
import 'package:test/test.dart';

import '../../support/argument_error_matcher.dart';

const _problem = ContentProblem(
  '/species/0/name',
  ContentProblemKind.invalidValue,
);

ContentSet _emptySet() => ContentSet(const []);

/// The exhaustive switch the port result demands: no default branch
/// compiles only while the sealed family has exactly these two variants.
String _variantOf(ContentDecodeResult result) => switch (result) {
  ContentDecoded() => 'decoded',
  ContentDecodeFailed() => 'failed',
};

void main() {
  /// Requirement: doc/specs/content-schema-and-decoder.md FR-007 -
  ///   supportedSchemaVersions holds exactly the current version;
  ///   doc/specs/content-schema-and-decoder.md FR-103 - one schemaVersion
  ///   for the whole format: the landed revision rows claimed no version,
  ///   so the set is still exactly the current one.
  /// Path: happy
  test('supportedSchemaVersions is exactly {1}', () {
    expect(supportedSchemaVersions, {1});
    expect(currentSchemaVersion, 1);
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-001 - the
  ///   result is a sealed type with exactly ContentDecoded and
  ///   ContentDecodeFailed, exhaustive in a switch without a default.
  /// Path: happy
  test('an exhaustive switch covers both variants without a default', () {
    expect(_variantOf(ContentDecoded(_emptySet())), 'decoded');
    expect(_variantOf(ContentDecodeFailed(const [_problem])), 'failed');
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-014, FR-097 -
  ///   a problem carries a path and a kind only and compares by value.
  /// Path: happy
  test('ContentProblem carries path and kind and compares by value', () {
    expect(_problem.path, '/species/0/name');
    expect(_problem.kind, ContentProblemKind.invalidValue);
    expect(
      _problem,
      const ContentProblem('/species/0/name', ContentProblemKind.invalidValue),
    );
    expect(
      _problem.hashCode,
      const ContentProblem(
        '/species/0/name',
        ContentProblemKind.invalidValue,
      ).hashCode,
    );
    expect(
      _problem,
      isNot(
        const ContentProblem('/species/0/name', ContentProblemKind.wrongType),
      ),
    );
    expect(
      _problem,
      isNot(
        const ContentProblem(
          '/species/1/name',
          ContentProblemKind.invalidValue,
        ),
      ),
    );
    expect(
      _problem.toString(),
      'ContentProblem(/species/0/name, invalidValue)',
    );
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-017 -
  ///   ContentDecodeFailed rejects an empty problem list with ArgumentError.
  /// Path: unhappy (immutability)
  test('ContentDecodeFailed rejects an empty list', () {
    expect(
      () => ContentDecodeFailed(const []),
      throwsArgumentErrorFor('problems', const <ContentProblem>[]),
    );
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-017 - the
  ///   problem list is an unmodifiable defensive copy.
  /// Path: unhappy (immutability)
  test('the problem list is unmodifiable and a defensive copy', () {
    final problems = [
      _problem,
      const ContentProblem('', ContentProblemKind.syntax),
    ];
    final failed = ContentDecodeFailed(problems);
    problems.clear();

    expect(failed.problems, hasLength(2));
    expect(() => failed.problems.clear(), throwsUnsupportedError);
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-097 - the
  ///   result variants have value equality and a consistent hashCode; a
  ///   ContentDecodeFailed and a ContentDecoded are never equal.
  /// Path: happy
  test('result equality', () {
    final decoded = ContentDecoded(_emptySet());
    final sameDecoded = ContentDecoded(_emptySet());
    final failed = ContentDecodeFailed(const [_problem]);
    final sameFailed = ContentDecodeFailed([_problem]);

    expect(decoded, sameDecoded);
    expect(decoded.hashCode, sameDecoded.hashCode);
    expect(failed, sameFailed);
    expect(failed.hashCode, sameFailed.hashCode);
    expect(decoded, isNot(failed));
    expect(decoded, isNot(ContentDecoded(ContentSet(const [])) == failed));
    expect(
      failed,
      isNot(
        ContentDecodeFailed(const [
          ContentProblem('', ContentProblemKind.syntax),
        ]),
      ),
    );
  });
}
