import 'package:test/test.dart';

import 'names.dart';

typedef _Case = ({
  String label,
  String requirement,
  String path,
  String input,
  String expected,
});

void main() {
  final cases = <_Case>[
    (
      label: 'a two-word subtype name',
      requirement:
          'doc/specs/errors-and-results.md FR-005 - errorType is the '
          'snake_case of the class name',
      path: 'happy',
      input: 'ContentSourceException',
      expected: 'content_source_exception',
    ),
    (
      label: 'a three-word subtype name',
      requirement:
          'doc/specs/errors-and-results.md FR-005 - errorType is the '
          'snake_case of the class name',
      path: 'happy',
      input: 'DiceRollerException',
      expected: 'dice_roller_exception',
    ),
    (
      label: 'a name with a digit',
      requirement:
          'doc/specs/errors-and-results.md FR-005 - digits stay attached',
      path: 'unhappy (boundary)',
      input: 'Srd5eException',
      expected: 'srd5e_exception',
    ),
    (
      label: 'a single word',
      requirement:
          'doc/specs/errors-and-results.md FR-005 - no separator is added '
          'before the first letter',
      path: 'unhappy (empty and minimal)',
      input: 'Exception',
      expected: 'exception',
    ),
  ];

  /// Requirement: per case
  /// Path: per case
  for (final c in cases) {
    test('snakeCase of ${c.label} [${c.path}]', () {
      expect(snakeCase(c.input), c.expected);
    });
  }
}
