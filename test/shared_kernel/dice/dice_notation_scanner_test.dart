import 'package:srd5e/src/shared_kernel/dice/dice_notation_scanner.dart';
import 'package:test/test.dart';

typedef _Scanned = ({
  String label,
  String requirement,
  String path,
  String input,
  String count,
  String sides,
  bool negative,
  String modifier,
});

typedef _Unscannable = ({
  String label,
  String requirement,
  String path,
  String input,
});

const String _minus = '−';

/// Text of the accepted shape and the groups the scanner reads from it.
const List<_Scanned> _scanned = [
  (
    label: 'count omitted',
    requirement: 'doc/specs/dice-and-rolls.md FR-017',
    path: 'happy',
    input: 'd20',
    count: '',
    sides: '20',
    negative: false,
    modifier: '',
  ),
  (
    label: 'count and sides',
    requirement: 'doc/specs/dice-and-rolls.md FR-018',
    path: 'happy',
    input: '4d6',
    count: '4',
    sides: '6',
    negative: false,
    modifier: '',
  ),
  (
    label: 'upper-case D',
    requirement: 'doc/specs/dice-and-rolls.md FR-019',
    path: 'happy',
    input: '2D12',
    count: '2',
    sides: '12',
    negative: false,
    modifier: '',
  ),
  (
    label: 'unspaced plus',
    requirement: 'doc/specs/dice-and-rolls.md FR-020',
    path: 'happy',
    input: '1d4+2',
    count: '1',
    sides: '4',
    negative: false,
    modifier: '2',
  ),
  (
    label: 'spaced plus',
    requirement: 'doc/specs/dice-and-rolls.md FR-020',
    path: 'happy',
    input: '2d8 + 2',
    count: '2',
    sides: '8',
    negative: false,
    modifier: '2',
  ),
  (
    label: 'unspaced ASCII minus',
    requirement: 'doc/specs/dice-and-rolls.md FR-020',
    path: 'happy',
    input: '1d4-5',
    count: '1',
    sides: '4',
    negative: true,
    modifier: '5',
  ),
  (
    label: 'spaced ASCII minus',
    requirement: 'doc/specs/dice-and-rolls.md FR-020',
    path: 'happy',
    input: '1d4 - 5',
    count: '1',
    sides: '4',
    negative: true,
    modifier: '5',
  ),
  (
    label: 'spaced Unicode minus',
    requirement: 'doc/specs/dice-and-rolls.md FR-021',
    path: 'happy',
    input: '1d20 $_minus 1',
    count: '1',
    sides: '20',
    negative: true,
    modifier: '1',
  ),
  (
    label: 'unspaced Unicode minus',
    requirement: 'doc/specs/dice-and-rolls.md FR-021',
    path: 'happy',
    input: '1d20${_minus}1',
    count: '1',
    sides: '20',
    negative: true,
    modifier: '1',
  ),
  (
    label: 'the digits zero and nine are digits',
    requirement: 'doc/specs/dice-and-rolls.md FR-018',
    path: 'unhappy (boundary)',
    input: '90d9+90',
    count: '90',
    sides: '9',
    negative: false,
    modifier: '90',
  ),
  (
    label: 'leading zeros are kept as written',
    requirement: 'doc/specs/dice-and-rolls.md FR-081',
    path: 'unhappy (boundary)',
    input: '01d006+007',
    count: '01',
    sides: '006',
    negative: false,
    modifier: '007',
  ),
  (
    label: 'zero modifier keeps its sign',
    requirement: 'doc/specs/dice-and-rolls.md FR-020',
    path: 'unhappy (boundary)',
    input: '1d20-0',
    count: '1',
    sides: '20',
    negative: true,
    modifier: '0',
  ),
];

/// Text the scanner cannot read at all (the shape is wrong).
const List<_Unscannable> _unscannable = [
  (
    label: 'empty text',
    requirement: 'doc/specs/dice-and-rolls.md FR-022',
    path: 'unhappy (boundary)',
    input: '',
  ),
  (
    label: 'a lone d',
    requirement: 'doc/specs/dice-and-rolls.md FR-023',
    path: 'unhappy (invalid input)',
    input: 'd',
  ),
  (
    label: 'count only',
    requirement: 'doc/specs/dice-and-rolls.md FR-023',
    path: 'unhappy (invalid input)',
    input: '12',
  ),
  (
    label: 'no sides',
    requirement: 'doc/specs/dice-and-rolls.md FR-023',
    path: 'unhappy (invalid input)',
    input: '2d',
  ),
  (
    label: 'a different letter',
    requirement: 'doc/specs/dice-and-rolls.md FR-023',
    path: 'unhappy (invalid input)',
    input: '2x6',
  ),
  (
    label: 'sign without digits',
    requirement: 'doc/specs/dice-and-rolls.md FR-023',
    path: 'unhappy (invalid input)',
    input: '1d6+',
  ),
  (
    label: 'doubled sign',
    requirement: 'doc/specs/dice-and-rolls.md FR-023',
    path: 'unhappy (invalid input)',
    input: '1d6++1',
  ),
  (
    label: 'a sign and nothing else after the sides',
    requirement: 'doc/specs/dice-and-rolls.md FR-023',
    path: 'unhappy (invalid input)',
    input: '1d6 +',
  ),
  (
    label: 'a space and no sign',
    requirement: 'doc/specs/dice-and-rolls.md FR-023',
    path: 'unhappy (invalid input)',
    input: '1d6 ',
  ),
  (
    label: 'a space then a digit',
    requirement: 'doc/specs/dice-and-rolls.md FR-020',
    path: 'unhappy (invalid input)',
    input: '1d6 5',
  ),
  (
    label: 'space only before the sign',
    requirement: 'doc/specs/dice-and-rolls.md FR-020',
    path: 'unhappy (invalid input)',
    input: '1d4 +2',
  ),
  (
    label: 'space only after the sign',
    requirement: 'doc/specs/dice-and-rolls.md FR-020',
    path: 'unhappy (invalid input)',
    input: '1d4+ 2',
  ),
  (
    label: 'two spaces before the sign',
    requirement: 'doc/specs/dice-and-rolls.md FR-020',
    path: 'unhappy (invalid input)',
    input: '1d4  + 2',
  ),
  (
    label: 'two spaces after the sign',
    requirement: 'doc/specs/dice-and-rolls.md FR-020',
    path: 'unhappy (invalid input)',
    input: '1d4 +  2',
  ),
  (
    label: 'the spaced form with no digits',
    requirement: 'doc/specs/dice-and-rolls.md FR-020',
    path: 'unhappy (invalid input)',
    input: '1d4 + ',
  ),
  (
    label: 'trailing text after the modifier',
    requirement: 'doc/specs/dice-and-rolls.md FR-023',
    path: 'unhappy (invalid input)',
    input: '1d4+2x',
  ),
  (
    label: 'a decimal point in the modifier',
    requirement: 'doc/specs/dice-and-rolls.md FR-023',
    path: 'unhappy (invalid input)',
    input: '1d6+1.5',
  ),
  (
    label: 'trailing newline',
    requirement: 'doc/specs/dice-and-rolls.md FR-028',
    path: 'unhappy (invalid input)',
    input: '1d6\n',
  ),
  (
    label: 'leading space',
    requirement: 'doc/specs/dice-and-rolls.md FR-028',
    path: 'unhappy (invalid input)',
    input: ' 1d6',
  ),
  (
    label: 'en dash as the sign',
    requirement: 'doc/specs/dice-and-rolls.md FR-028',
    path: 'unhappy (invalid input)',
    input: '1d6–1',
  ),
  (
    label: 'full-width digit in the count',
    requirement: 'doc/specs/dice-and-rolls.md FR-028',
    path: 'unhappy (invalid input)',
    input: '１d6',
  ),
  (
    label: 'a leading sign',
    requirement: 'doc/specs/dice-and-rolls.md FR-023',
    path: 'unhappy (invalid input)',
    input: '-1d6',
  ),
  (
    label: 'a lone surrogate',
    requirement: 'doc/specs/dice-and-rolls.md FR-029',
    path: 'unhappy (invalid input)',
    input: '\ud800',
  ),
];

void main() {
  /// Requirement: per case - doc/specs/dice-and-rolls.md FR-017, FR-018, FR-019,
  ///   FR-020, FR-021 and FR-081 - the scanner splits text of the accepted
  ///   shape into its digit and sign groups, leaving the numbers to the
  ///   caller.
  /// Path: per case
  group('scanDiceNotation reads', () {
    /// Requirement: per case
    /// Path: per case
    for (final c in _scanned) {
      test('${c.label}: "${c.input}" [${c.path}]', () {
        final tokens = scanDiceNotation(c.input);

        expect(tokens, isNotNull);
        expect(tokens!.countDigits, c.count);
        expect(tokens.sidesDigits, c.sides);
        expect(tokens.isNegative, c.negative);
        expect(tokens.modifierDigits, c.modifier);
      });
    }
  });

  /// Requirement: per case - doc/specs/dice-and-rolls.md FR-022, FR-023, FR-028 and FR-029
  ///   - text of any other shape gives null, and the scanner never throws.
  /// Path: per case
  group('scanDiceNotation does not read', () {
    /// Requirement: per case
    /// Path: per case
    for (final c in _unscannable) {
      test('${c.label}: "${c.input}" [${c.path}]', () {
        expect(scanDiceNotation(c.input), isNull);
      });
    }
  });
}
