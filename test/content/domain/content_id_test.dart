import 'package:srd5e/src/content/domain/content_id.dart';
import 'package:test/test.dart';

import '../../support/argument_error_matcher.dart';
import '../../support/operator_equals.dart';

/// One id case: [value] with the [problem] `ContentId.tryCreate` must
/// report, or null when the id is accepted. The label names the row of the
/// spec's case tables.
typedef _IdCase = ({
  String label,
  String requirement,
  String path,
  String value,
  ContentIdProblem? problem,
});

final List<_IdCase> _cases = [
  (
    label: 'single letter',
    requirement: 'doc/specs/content-schema-and-decoder.md FR-143 - accepts a',
    path: 'unhappy (boundary)',
    value: 'a',
    problem: null,
  ),
  (
    label: 'digits and underscores after the letter',
    requirement:
        'doc/specs/content-schema-and-decoder.md FR-143 - accepts '
        'ids of lowercase letters, digits and underscores that start with a '
        'letter',
    path: 'unhappy (boundary)',
    value: 'acid_arrow_2',
    problem: null,
  ),
  (
    label: 'exactly 64 code units',
    requirement:
        'doc/specs/content-schema-and-decoder.md FR-143 - accepts '
        'one of exactly 64 units',
    path: 'unhappy (boundary)',
    value: 'a${'b' * 63}',
    problem: null,
  ),
  (
    label: 'empty string',
    requirement:
        'doc/specs/content-schema-and-decoder.md FR-143 and FR-144 '
        '- the empty string is rejected as empty',
    path: 'unhappy (invalid input)',
    value: '',
    problem: ContentIdProblem.empty,
  ),
  (
    label: '65 characters',
    requirement:
        'doc/specs/content-schema-and-decoder.md FR-143 - a string '
        'over 64 UTF-16 code units is too long',
    path: 'unhappy (boundary)',
    value: 'a${'b' * 64}',
    problem: ContentIdProblem.tooLong,
  ),
  (
    label: '65 uppercase characters report tooLong',
    requirement:
        'doc/specs/content-schema-and-decoder.md FR-144 - the first '
        'failing check in the order empty, tooLong, invalidFormat (65 '
        'uppercase characters give tooLong)',
    path: 'unhappy (boundary)',
    value: 'A' * 65,
    problem: ContentIdProblem.tooLong,
  ),
  (
    label: 'leading space',
    requirement:
        'doc/specs/content-schema-and-decoder.md FR-143 - leading '
        'whitespace is not of the id shape',
    path: 'unhappy (invalid input)',
    value: ' a',
    problem: ContentIdProblem.invalidFormat,
  ),
  (
    label: 'trailing space',
    requirement:
        'doc/specs/content-schema-and-decoder.md FR-143 - trailing '
        'whitespace is not of the id shape',
    path: 'unhappy (invalid input)',
    value: 'a ',
    problem: ContentIdProblem.invalidFormat,
  ),
  (
    label: 'whitespace only',
    requirement:
        'doc/specs/content-schema-and-decoder.md FR-143 - interior '
        'and whole-string whitespace is not of the id shape',
    path: 'unhappy (invalid input)',
    value: '   ',
    problem: ContentIdProblem.invalidFormat,
  ),
  (
    label: 'interior space',
    requirement:
        'doc/specs/content-schema-and-decoder.md FR-143 - interior '
        'whitespace is not of the id shape',
    path: 'unhappy (invalid input)',
    value: 'a b',
    problem: ContentIdProblem.invalidFormat,
  ),
  (
    label: 'control character',
    requirement:
        'doc/specs/content-schema-and-decoder.md FR-143 - control '
        'characters are not of the id shape',
    path: 'unhappy (invalid input)',
    value: 'a\nb',
    problem: ContentIdProblem.invalidFormat,
  ),
  (
    label: 'non-ASCII',
    requirement:
        'doc/specs/content-schema-and-decoder.md FR-143 - non-ASCII '
        'is not of the id shape',
    path: 'unhappy (invalid input)',
    value: 'é',
    problem: ContentIdProblem.invalidFormat,
  ),
  (
    label: 'uppercase',
    requirement:
        'doc/specs/content-schema-and-decoder.md FR-143 - uppercase '
        'is not of the id shape',
    path: 'unhappy (invalid input)',
    value: 'aB',
    problem: ContentIdProblem.invalidFormat,
  ),
  (
    label: 'hyphen',
    requirement:
        'doc/specs/content-schema-and-decoder.md FR-143 - a hyphen '
        'is not of the id shape',
    path: 'unhappy (invalid input)',
    value: 'acid-arrow',
    problem: ContentIdProblem.invalidFormat,
  ),
  (
    label: 'digit first',
    requirement:
        'doc/specs/content-schema-and-decoder.md FR-143 - a digit '
        'first is not of the id shape',
    path: 'unhappy (boundary)',
    value: '1a',
    problem: ContentIdProblem.invalidFormat,
  ),
  (
    label: 'underscore first',
    requirement:
        'doc/specs/content-schema-and-decoder.md FR-143 - an '
        'underscore first is not of the id shape',
    path: 'unhappy (boundary)',
    value: '_a',
    problem: ContentIdProblem.invalidFormat,
  ),
];

void main() {
  /// Requirement: per case
  /// Path: per case
  for (final c in _cases) {
    test('${c.label} [${c.path}]', () {
      if (c.problem == null) {
        expect(ContentId(c.value).value, c.value);
        final parse = ContentId.tryCreate(c.value);
        expect(parse, isA<ContentIdParsed>());
        expect((parse as ContentIdParsed).id.value, c.value);
        expect(ContentId.isValid(c.value), isTrue);
      } else {
        expect(
          () => ContentId(c.value),
          throwsArgumentErrorFor('value', c.value),
        );
        final parse = ContentId.tryCreate(c.value);
        expect(parse, ContentIdRejected(c.problem!));
        expect(ContentId.isValid(c.value), isFalse);
      }
    });
  }

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-143 - the
  ///   constructor throws ArgumentError with name value and invalidValue set,
  ///   never message text; the limit is the decoder's (FR-030).
  /// Path: unhappy (invalid input)
  test('a rejected id carries name value and the offending input', () {
    expect(() => ContentId('Acid'), throwsArgumentErrorFor('value', 'Acid'));
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-143 - the
  ///   length limit is a public constant the decoder reuses.
  /// Path: happy
  test('maxLength is 64', () {
    expect(ContentId.maxLength, 64);
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-143 - it
  ///   compares and hashes by its string.
  /// Path: happy
  test('ids compare and hash by their string', () {
    final a = ContentId('elf');
    final same = ContentId('elf');
    final other = ContentId('dwarf');

    expect(a, same);
    expect(a.hashCode, same.hashCode);
    expect(operatorEquals(a, other), isFalse);
    expect(operatorEquals(other, a), isFalse);
    expect(operatorEquals(a, 'elf'), isFalse);
  });

  /// Requirement: per case
  /// Path: per case
  for (final c in _cases) {
    test('tryCreate agrees with the constructor: ${c.label} [${c.path}]', () {
      final parse = ContentId.tryCreate(c.value);
      if (c.problem == null) {
        expect(parse, isA<ContentIdParsed>());
      } else {
        expect(parse, isA<ContentIdRejected>());
        expect((parse as ContentIdRejected).problem, c.problem);
      }
    });
  }

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-143 - the id
  ///   compares and hashes by its string, and toString is its debugging
  ///   form.
  /// Path: happy
  test('a ContentId prints its value', () {
    expect(ContentId('acid_arrow_2').toString(), 'acid_arrow_2');
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-144 - the
  ///   parse results are value objects: they compare by value, hash
  ///   consistently and print their parts.
  /// Path: happy
  test('parse results compare by value and print their parts', () {
    final parsed = ContentId.tryCreate('a');
    final same = ContentId.tryCreate('a');
    final other = ContentId.tryCreate('b');
    final rejected = ContentId.tryCreate('');

    expect(parsed, same);
    expect(parsed.hashCode, same.hashCode);
    expect(operatorEquals(parsed, other), isFalse);
    expect(operatorEquals(parsed, rejected), isFalse);
    expect(parsed.toString(), 'ContentIdParsed(a)');

    final sameRejected = ContentId.tryCreate('');
    expect(rejected, sameRejected);
    expect(rejected.hashCode, sameRejected.hashCode);
    expect(operatorEquals(rejected, parsed), isFalse);
    expect(rejected.toString(), 'ContentIdRejected(empty)');
  });
}
