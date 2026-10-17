import 'package:srd5e/src/content/domain/content_problem_kind.dart';
import 'package:test/test.dart';

/// Exhaustive over the enum with no default branch (FR-015).
String _describe(ContentProblemKind kind) => switch (kind) {
  ContentProblemKind.syntax => 'syntax',
  ContentProblemKind.unsupportedVersion => 'unsupportedVersion',
  ContentProblemKind.missingField => 'missingField',
  ContentProblemKind.unknownField => 'unknownField',
  ContentProblemKind.wrongType => 'wrongType',
  ContentProblemKind.outOfRange => 'outOfRange',
  ContentProblemKind.invalidValue => 'invalidValue',
  ContentProblemKind.duplicate => 'duplicate',
  ContentProblemKind.unresolvedReference => 'unresolvedReference',
  ContentProblemKind.constraintViolation => 'constraintViolation',
};

void main() {
  /// Requirement: doc/specs/content-schema-and-decoder.md FR-015 - a closed
  ///   enum with exactly these ten members.
  /// Path: happy
  test('declares exactly ten members in declaration order', () {
    expect(ContentProblemKind.values.map((kind) => kind.name), [
      'syntax',
      'unsupportedVersion',
      'missingField',
      'unknownField',
      'wrongType',
      'outOfRange',
      'invalidValue',
      'duplicate',
      'unresolvedReference',
      'constraintViolation',
    ]);
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-015 - a switch
  ///   over ContentProblemKind is exhaustive without a default.
  /// Path: happy
  test('a switch over every member selects its case', () {
    expect(
      [for (final kind in ContentProblemKind.values) _describe(kind)],
      [
        'syntax',
        'unsupportedVersion',
        'missingField',
        'unknownField',
        'wrongType',
        'outOfRange',
        'invalidValue',
        'duplicate',
        'unresolvedReference',
        'constraintViolation',
      ],
    );
  });
}
