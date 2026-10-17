import 'package:srd5e/src/content/domain/named_text.dart';
import 'package:test/test.dart';

import '../../support/argument_error_matcher.dart';
import '../../support/operator_equals.dart';

/// One constructor input pair with the field the constructor must reject, or
/// null when accepted.
typedef _NamedTextCase = ({
  String label,
  String requirement,
  String path,
  String name,
  String text,
  String? rejectedField,
});

final List<_NamedTextCase> _cases = [
  (
    label: 'a valid pair',
    requirement:
        'doc/specs/content-schema-and-decoder.md FR-116 - a valid '
        'NamedText holds its parts verbatim (SRD 5.2.1, "Parts of a Species: '
        'Special Traits", p. 84)',
    path: 'happy',
    name: 'Darkvision',
    text: 'You can see in Dim Light within 120 feet of you.',
    rejectedField: null,
  ),
  (
    label: 'text with surrounding whitespace',
    requirement:
        'doc/specs/content-schema-and-decoder.md FR-116 and FR-028 - '
        'the text rule is at least one non-whitespace character; nothing '
        'trims it (FR-029)',
    path: 'happy',
    name: 'Trait',
    text: ' The text is stored verbatim. ',
    rejectedField: null,
  ),
  (
    label: 'empty name',
    requirement:
        'doc/specs/content-schema-and-decoder.md FR-116 and FR-027 - '
        'the name must be non-empty',
    path: 'unhappy (invalid input)',
    name: '',
    text: 'text',
    rejectedField: 'name',
  ),
  (
    label: 'name with a leading space',
    requirement:
        'doc/specs/content-schema-and-decoder.md FR-116 and FR-027 - '
        'the name must have no leading whitespace',
    path: 'unhappy (invalid input)',
    name: ' Trait',
    text: 'text',
    rejectedField: 'name',
  ),
  (
    label: 'name with a trailing space',
    requirement:
        'doc/specs/content-schema-and-decoder.md FR-116 and FR-027 - '
        'the name must have no trailing whitespace',
    path: 'unhappy (invalid input)',
    name: 'Trait ',
    text: 'text',
    rejectedField: 'name',
  ),
  (
    label: 'blank text',
    requirement:
        'doc/specs/content-schema-and-decoder.md FR-116 and FR-028 - '
        'the text must contain at least one non-whitespace character',
    path: 'unhappy (invalid input)',
    name: 'Trait',
    text: ' ',
    rejectedField: 'text',
  ),
  (
    label: 'empty text',
    requirement:
        'doc/specs/content-schema-and-decoder.md FR-116 and FR-028 - '
        'the text must contain at least one non-whitespace character',
    path: 'unhappy (invalid input)',
    name: 'Trait',
    text: '',
    rejectedField: 'text',
  ),
];

void main() {
  /// Requirement: per case
  /// Path: per case
  for (final c in _cases) {
    test('NamedText ${c.label} [${c.path}]', () {
      if (c.rejectedField == null) {
        final namedText = NamedText(c.name, c.text);
        expect(namedText.name, c.name);
        expect(namedText.text, c.text);
      } else {
        expect(
          () => NamedText(c.name, c.text),
          throwsArgumentErrorFor(
            c.rejectedField!,
            c.rejectedField == 'name' ? c.name : c.text,
          ),
        );
      }
    });
  }

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-116 - the
  ///   limits are public predicates the decoder reuses (FR-094).
  /// Path: happy
  test('the name and text rules are public predicates', () {
    expect(NamedText.isValidName('Trait'), isTrue);
    expect(NamedText.isValidName(''), isFalse);
    expect(NamedText.isValidName(' Trait'), isFalse);
    expect(NamedText.isValidText('text'), isTrue);
    expect(NamedText.isValidText(' '), isFalse);
    expect(NamedText.isValidText(''), isFalse);
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-116 - value
  ///   equality.
  /// Path: happy
  test('named texts compare by both parts', () {
    final namedText = NamedText('Trait', 'text');
    final same = NamedText('Trait', 'text');
    final otherText = NamedText('Trait', 'other');
    final otherName = NamedText('Other', 'text');

    expect(namedText, same);
    expect(namedText.hashCode, same.hashCode);
    expect(operatorEquals(namedText, otherText), isFalse);
    expect(operatorEquals(namedText, otherName), isFalse);
    expect(operatorEquals(namedText, 'Trait'), isFalse);
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-116 - toString
  ///   is a debugging form.
  /// Path: happy
  test('a named text prints its name', () {
    expect(NamedText('Trait', 'text').toString(), 'NamedText(Trait)');
  });
}
