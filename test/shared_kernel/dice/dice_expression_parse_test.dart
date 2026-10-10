import 'dart:math';

import 'package:srd5e/src/shared_kernel/dice/dice_expression.dart';
import 'package:srd5e/src/shared_kernel/dice/die.dart';
import 'package:test/test.dart';

/// U+2212 MINUS SIGN, the sign the SRD prints in "1d20 - 1" (p. 217).
const String _minus = '−';

/// U+2013 EN DASH, printed once by the SRD (p. 356) and rejected here.
const String _enDash = '–';

typedef _Accepted = ({
  String label,
  String requirement,
  String path,
  String input,
  int count,
  int sides,
  int modifier,
});

typedef _Rejected = ({
  String label,
  String requirement,
  String path,
  String input,
  DiceExpressionRejection reason,
});

const _empty = DiceExpressionRejection.empty;
const _malformed = DiceExpressionRejection.malformed;
const _count = DiceExpressionRejection.countOutOfRange;
const _sides = DiceExpressionRejection.sidesOutOfRange;
const _modifier = DiceExpressionRejection.modifierOutOfRange;

/// Case table for FR-017, FR-018, FR-019, FR-020, FR-021 and FR-081 (accepted
/// input).
const List<_Accepted> _accepted = [
  (
    label: 'count omitted',
    requirement:
        'doc/specs/dice-and-rolls.md FR-017 (SRD 5.2.1, "D20 Tests", p. 6)',
    path: 'happy',
    input: 'd20',
    count: 1,
    sides: 20,
    modifier: 0,
  ),
  (
    label: 'count of one',
    requirement:
        'doc/specs/dice-and-rolls.md FR-018 (SRD 5.2.1, "D20 Tests", p. 6)',
    path: 'happy',
    input: '1d20',
    count: 1,
    sides: 20,
    modifier: 0,
  ),
  (
    label: 'upper-case D',
    requirement:
        'doc/specs/dice-and-rolls.md FR-019 (SRD 5.2.1, "Barbarian", p. 28)',
    path: 'happy',
    input: 'D12',
    count: 1,
    sides: 12,
    modifier: 0,
  ),
  (
    label: 'upper-case D with a count',
    requirement:
        'doc/specs/dice-and-rolls.md FR-019 (SRD 5.2.1, "Barbarian", p. 28)',
    path: 'happy',
    input: '2D6',
    count: 2,
    sides: 6,
    modifier: 0,
  ),
  (
    label: 'several dice',
    requirement:
        'doc/specs/dice-and-rolls.md FR-018 (SRD 5.2.1, "Rogue Features", p. 62)',
    path: 'happy',
    input: '4d6',
    count: 4,
    sides: 6,
    modifier: 0,
  ),
  (
    label: 'percentile-sized die',
    requirement:
        'doc/specs/dice-and-rolls.md FR-018 (SRD 5.2.1, "Trinkets", p. 26)',
    path: 'happy',
    input: '1d100',
    count: 1,
    sides: 100,
    modifier: 0,
  ),
  (
    label: 'spaced plus with two dice',
    requirement:
        'doc/specs/dice-and-rolls.md FR-020 (SRD 5.2.1, "Hit Points", p. 255)',
    path: 'happy',
    input: '2d8 + 2',
    count: 2,
    sides: 8,
    modifier: 2,
  ),
  (
    label: 'spaced plus with one die',
    requirement:
        'doc/specs/dice-and-rolls.md FR-020 (SRD 5.2.1, "Damage Notation", p. 257)',
    path: 'happy',
    input: '1d4 + 2',
    count: 1,
    sides: 4,
    modifier: 2,
  ),
  (
    label: 'unspaced plus',
    requirement: 'doc/specs/dice-and-rolls.md FR-020 (package design)',
    path: 'happy',
    input: '1d4+2',
    count: 1,
    sides: 4,
    modifier: 2,
  ),
  (
    label: 'spaced ASCII minus',
    requirement: 'doc/specs/dice-and-rolls.md FR-020 (package design)',
    path: 'happy',
    input: '1d4 - 5',
    count: 1,
    sides: 4,
    modifier: -5,
  ),
  (
    label: 'unspaced ASCII minus',
    requirement: 'doc/specs/dice-and-rolls.md FR-020 (package design)',
    path: 'happy',
    input: '1d4-5',
    count: 1,
    sides: 4,
    modifier: -5,
  ),
  (
    label: 'spaced Unicode minus',
    requirement:
        'doc/specs/dice-and-rolls.md FR-021 (SRD 5.2.1, "Deck of Illusions", p. 217)',
    path: 'happy',
    input: '1d20 $_minus 1',
    count: 1,
    sides: 20,
    modifier: -1,
  ),
  (
    label: 'unspaced Unicode minus',
    requirement:
        'doc/specs/dice-and-rolls.md FR-021 (SRD 5.2.1, "Deck of Illusions", p. 217)',
    path: 'happy',
    input: '1d20${_minus}1',
    count: 1,
    sides: 20,
    modifier: -1,
  ),
  (
    label: 'zero modifier, unspaced plus',
    requirement: 'doc/specs/dice-and-rolls.md FR-020 (package design)',
    path: 'unhappy (boundary)',
    input: '1d20+0',
    count: 1,
    sides: 20,
    modifier: 0,
  ),
  (
    label: 'zero modifier, unspaced minus',
    requirement: 'doc/specs/dice-and-rolls.md FR-020 (package design)',
    path: 'unhappy (boundary)',
    input: '1d20-0',
    count: 1,
    sides: 20,
    modifier: 0,
  ),
  (
    label: 'zero modifier, spaced plus',
    requirement: 'doc/specs/dice-and-rolls.md FR-020 (package design)',
    path: 'unhappy (boundary)',
    input: '1d20 + 0',
    count: 1,
    sides: 20,
    modifier: 0,
  ),
  (
    label: 'leading zero in the count',
    requirement: 'doc/specs/dice-and-rolls.md FR-081 (package design)',
    path: 'unhappy (boundary)',
    input: '01d6',
    count: 1,
    sides: 6,
    modifier: 0,
  ),
  (
    label: 'leading zeros in the sides',
    requirement: 'doc/specs/dice-and-rolls.md FR-081 (package design)',
    path: 'unhappy (boundary)',
    input: '1d006',
    count: 1,
    sides: 6,
    modifier: 0,
  ),
  (
    label: 'leading zeros in the modifier',
    requirement: 'doc/specs/dice-and-rolls.md FR-081 (package design)',
    path: 'unhappy (boundary)',
    input: '1d6+007',
    count: 1,
    sides: 6,
    modifier: 7,
  ),
  (
    label: 'a very long run of leading zeros',
    requirement: 'doc/specs/dice-and-rolls.md FR-081 (package design)',
    path: 'unhappy (boundary)',
    input: '0000000000000000000001d6',
    count: 1,
    sides: 6,
    modifier: 0,
  ),
  (
    label: 'd3',
    requirement:
        'doc/specs/dice-and-rolls.md FR-001, FR-018 (SRD 5.2.1, "Traps", p. 200)',
    path: 'happy',
    input: '1d3',
    count: 1,
    sides: 3,
    modifier: 0,
  ),
  (
    label: 'a die the SRD does not print',
    requirement: 'doc/specs/dice-and-rolls.md FR-002, FR-018 (package design)',
    path: 'happy',
    input: '3d7',
    count: 3,
    sides: 7,
    modifier: 0,
  ),
  (
    label: 'every limit',
    requirement:
        'doc/specs/dice-and-rolls.md FR-006, FR-009 (package design, limits)',
    path: 'unhappy (boundary)',
    input: '1000d1000+1000000',
    count: 1000,
    sides: 1000,
    modifier: 1000000,
  ),
  (
    label: 'smallest modifier and die',
    requirement: 'doc/specs/dice-and-rolls.md FR-009 (package design, limits)',
    path: 'unhappy (boundary)',
    input: '1d2-1000000',
    count: 1,
    sides: 2,
    modifier: -1000000,
  ),
];

/// Case table for FR-022, FR-023, FR-024, FR-025, FR-026, FR-027 and FR-028
/// (rejected input).
const List<_Rejected> _rejected = [
  (
    label: 'zero-length text',
    requirement: 'doc/specs/dice-and-rolls.md FR-022',
    path: 'unhappy (invalid input)',
    input: '',
    reason: _empty,
  ),
  (
    label: 'a lone d',
    requirement: 'doc/specs/dice-and-rolls.md FR-023',
    path: 'unhappy (invalid input)',
    input: 'd',
    reason: _malformed,
  ),
  (
    label: 'count without sides',
    requirement: 'doc/specs/dice-and-rolls.md FR-023',
    path: 'unhappy (invalid input)',
    input: '2d',
    reason: _malformed,
  ),
  (
    label: 'x for d',
    requirement: 'doc/specs/dice-and-rolls.md FR-023',
    path: 'unhappy (invalid input)',
    input: '2x6',
    reason: _malformed,
  ),
  (
    label: 'sign without digits',
    requirement: 'doc/specs/dice-and-rolls.md FR-023',
    path: 'unhappy (invalid input)',
    input: '1d6+',
    reason: _malformed,
  ),
  (
    label: 'doubled sign',
    requirement: 'doc/specs/dice-and-rolls.md FR-023',
    path: 'unhappy (invalid input)',
    input: '1d6++1',
    reason: _malformed,
  ),
  (
    label: 'doubled spaced sign',
    requirement: 'doc/specs/dice-and-rolls.md FR-023',
    path: 'unhappy (invalid input)',
    input: '1d6 + + 1',
    reason: _malformed,
  ),
  (
    label: 'modifier without sides',
    requirement: 'doc/specs/dice-and-rolls.md FR-023',
    path: 'unhappy (invalid input)',
    input: 'd+2',
    reason: _malformed,
  ),
  (
    label: 'space before the d',
    requirement: 'doc/specs/dice-and-rolls.md FR-023, FR-028',
    path: 'unhappy (invalid input)',
    input: '2 d6',
    reason: _malformed,
  ),
  (
    label: 'space after the d',
    requirement: 'doc/specs/dice-and-rolls.md FR-023, FR-028',
    path: 'unhappy (invalid input)',
    input: '2d 6',
    reason: _malformed,
  ),
  (
    label: 'fractional count',
    requirement: 'doc/specs/dice-and-rolls.md FR-023',
    path: 'unhappy (invalid input)',
    input: '1.5d6',
    reason: _malformed,
  ),
  (
    label: 'fractional modifier',
    requirement: 'doc/specs/dice-and-rolls.md FR-023',
    path: 'unhappy (invalid input)',
    input: '1d6+1.5',
    reason: _malformed,
  ),
  (
    label: 'leading minus',
    requirement: 'doc/specs/dice-and-rolls.md FR-023',
    path: 'unhappy (invalid input)',
    input: '-1d6',
    reason: _malformed,
  ),
  (
    label: 'leading plus',
    requirement: 'doc/specs/dice-and-rolls.md FR-023',
    path: 'unhappy (invalid input)',
    input: '+1d6',
    reason: _malformed,
  ),
  (
    label: 'three spaces are not empty',
    requirement: 'doc/specs/dice-and-rolls.md FR-028',
    path: 'unhappy (invalid input)',
    input: '   ',
    reason: _malformed,
  ),
  (
    label: 'leading space',
    requirement: 'doc/specs/dice-and-rolls.md FR-028',
    path: 'unhappy (invalid input)',
    input: ' 1d20',
    reason: _malformed,
  ),
  (
    label: 'trailing space',
    requirement: 'doc/specs/dice-and-rolls.md FR-028',
    path: 'unhappy (invalid input)',
    input: '1d20 ',
    reason: _malformed,
  ),
  (
    label: 'trailing newline',
    requirement: 'doc/specs/dice-and-rolls.md FR-028',
    path: 'unhappy (invalid input)',
    input: '1d6\n',
    reason: _malformed,
  ),
  (
    label: 'space only before the sign',
    requirement: 'doc/specs/dice-and-rolls.md FR-020',
    path: 'unhappy (invalid input)',
    input: '1d4 +2',
    reason: _malformed,
  ),
  (
    label: 'space only after the sign',
    requirement: 'doc/specs/dice-and-rolls.md FR-020',
    path: 'unhappy (invalid input)',
    input: '1d4+ 2',
    reason: _malformed,
  ),
  (
    label: 'runs of spaces around the sign',
    requirement: 'doc/specs/dice-and-rolls.md FR-020',
    path: 'unhappy (invalid input)',
    input: '1d4  +  2',
    reason: _malformed,
  ),
  (
    label: 'Unicode minus with space only before',
    requirement: 'doc/specs/dice-and-rolls.md FR-021',
    path: 'unhappy (invalid input)',
    input: '1d20 ${_minus}1',
    reason: _malformed,
  ),
  (
    label: 'Unicode minus with space only after',
    requirement: 'doc/specs/dice-and-rolls.md FR-021',
    path: 'unhappy (invalid input)',
    input: '1d20$_minus 1',
    reason: _malformed,
  ),
  (
    label: 'en dash as the sign',
    requirement: 'doc/specs/dice-and-rolls.md FR-028 (section 9)',
    path: 'unhappy (invalid input)',
    input: '1d20 $_enDash 1',
    reason: _malformed,
  ),
  (
    label: 'unspaced en dash',
    requirement: 'doc/specs/dice-and-rolls.md FR-028 (section 9)',
    path: 'unhappy (invalid input)',
    input: '1d20${_enDash}1',
    reason: _malformed,
  ),
  (
    label: 'full-width digit',
    requirement: 'doc/specs/dice-and-rolls.md FR-028',
    path: 'unhappy (invalid input)',
    input: '１d20',
    reason: _malformed,
  ),
  (
    label: 'Arabic-Indic digit in the sides',
    requirement: 'doc/specs/dice-and-rolls.md FR-028',
    path: 'unhappy (invalid input)',
    input: '1d٢',
    reason: _malformed,
  ),
  (
    label: 'multiplied dice',
    requirement: 'doc/specs/dice-and-rolls.md FR-023 (section 1, out of scope)',
    path: 'unhappy (invalid input)',
    input: '1d4 × 10',
    reason: _malformed,
  ),
  (
    label: 'two terms',
    requirement: 'doc/specs/dice-and-rolls.md FR-023 (section 1, out of scope)',
    path: 'unhappy (invalid input)',
    input: '1d6+2d4',
    reason: _malformed,
  ),
  (
    label: 'syntax is judged before range: count zero, no sides',
    requirement: 'doc/specs/dice-and-rolls.md FR-023, FR-024',
    path: 'unhappy (rule conflict)',
    input: '0d',
    reason: _malformed,
  ),
  (
    label: 'count of zero',
    requirement: 'doc/specs/dice-and-rolls.md FR-024',
    path: 'unhappy (boundary)',
    input: '0d6',
    reason: _count,
  ),
  (
    label: 'count of zero written as 00',
    requirement: 'doc/specs/dice-and-rolls.md FR-024, FR-081',
    path: 'unhappy (boundary)',
    input: '00d6',
    reason: _count,
  ),
  (
    label: 'count of 1001',
    requirement: 'doc/specs/dice-and-rolls.md FR-024',
    path: 'unhappy (boundary)',
    input: '1001d6',
    reason: _count,
  ),
  (
    label: 'count is checked before sides',
    requirement: 'doc/specs/dice-and-rolls.md FR-024, FR-025',
    path: 'unhappy (rule conflict)',
    input: '0d0',
    reason: _count,
  ),
  (
    label: 'count is checked before modifier',
    requirement: 'doc/specs/dice-and-rolls.md FR-024, FR-026',
    path: 'unhappy (rule conflict)',
    input: '0d6+1000001',
    reason: _count,
  ),
  (
    label: 'count too large for an integer',
    requirement: 'doc/specs/dice-and-rolls.md FR-027',
    path: 'unhappy (invalid input)',
    input: '99999999999999999999d6',
    reason: _count,
  ),
  (
    label: 'sides of zero',
    requirement: 'doc/specs/dice-and-rolls.md FR-025',
    path: 'unhappy (boundary)',
    input: '1d0',
    reason: _sides,
  ),
  (
    label: 'sides of one',
    requirement: 'doc/specs/dice-and-rolls.md FR-025',
    path: 'unhappy (boundary)',
    input: '1d1',
    reason: _sides,
  ),
  (
    label: 'sides of 1001',
    requirement: 'doc/specs/dice-and-rolls.md FR-025',
    path: 'unhappy (boundary)',
    input: '1d1001',
    reason: _sides,
  ),
  (
    label: 'sides are checked before modifier',
    requirement: 'doc/specs/dice-and-rolls.md FR-025, FR-026',
    path: 'unhappy (rule conflict)',
    input: '1d1+1000001',
    reason: _sides,
  ),
  (
    label: 'sides too large for an integer',
    requirement: 'doc/specs/dice-and-rolls.md FR-027',
    path: 'unhappy (invalid input)',
    input: '1d99999999999999999999',
    reason: _sides,
  ),
  (
    label: 'modifier of 1000001',
    requirement: 'doc/specs/dice-and-rolls.md FR-026',
    path: 'unhappy (boundary)',
    input: '1d6+1000001',
    reason: _modifier,
  ),
  (
    label: 'modifier of -1000001',
    requirement: 'doc/specs/dice-and-rolls.md FR-026',
    path: 'unhappy (boundary)',
    input: '1d6-1000001',
    reason: _modifier,
  ),
  (
    label: 'Unicode modifier of -1000001',
    requirement: 'doc/specs/dice-and-rolls.md FR-021, FR-026',
    path: 'unhappy (boundary)',
    input: '1d6 $_minus 1000001',
    reason: _modifier,
  ),
  (
    label: 'modifier too large for an integer',
    requirement: 'doc/specs/dice-and-rolls.md FR-027',
    path: 'unhappy (invalid input)',
    input: '1d6+99999999999999999999',
    reason: _modifier,
  ),
  (
    label: 'negative modifier too large for an integer',
    requirement: 'doc/specs/dice-and-rolls.md FR-027',
    path: 'unhappy (invalid input)',
    input: '1d6-99999999999999999999',
    reason: _modifier,
  ),
];

typedef _Notation = ({
  String label,
  String requirement,
  String path,
  String input,
  String notation,
});

/// Inputs and the canonical form they produce (FR-030, FR-081).
const List<_Notation> _canonical = [
  (
    label: 'count omitted becomes explicit',
    requirement: 'doc/specs/dice-and-rolls.md FR-030',
    path: 'happy',
    input: 'd20',
    notation: '1d20',
  ),
  (
    label: 'upper-case D becomes lower-case',
    requirement: 'doc/specs/dice-and-rolls.md FR-030',
    path: 'happy',
    input: 'D12',
    notation: '1d12',
  ),
  (
    label: 'spaces are removed',
    requirement: 'doc/specs/dice-and-rolls.md FR-030',
    path: 'happy',
    input: '2d8 + 2',
    notation: '2d8+2',
  ),
  (
    label: 'Unicode minus becomes ASCII minus',
    requirement: 'doc/specs/dice-and-rolls.md FR-030',
    path: 'happy',
    input: '1d20 $_minus 1',
    notation: '1d20-1',
  ),
  (
    label: 'a zero modifier is dropped',
    requirement: 'doc/specs/dice-and-rolls.md FR-030',
    path: 'unhappy (boundary)',
    input: '1d20 - 0',
    notation: '1d20',
  ),
  (
    label: 'leading zeros are dropped',
    requirement: 'doc/specs/dice-and-rolls.md FR-030, FR-081',
    path: 'unhappy (boundary)',
    input: '01d006+007',
    notation: '1d6+7',
  ),
];

DiceExpression _expected(_Accepted c) =>
    DiceExpression(c.count, Die(c.sides), modifier: c.modifier);

void main() {
  /// Requirement: per case - doc/specs/dice-and-rolls.md FR-017, FR-018, FR-019,
  ///   FR-020, FR-021 and FR-081 - tryParse reads the forms the SRD prints,
  ///   plus the unspaced, ASCII-minus, zero and leading-zero forms (package
  ///   design).
  /// Path: per case
  group('tryParse accepts', () {
    /// Requirement: per case
    /// Path: per case
    for (final c in _accepted) {
      test('${c.label}: "${c.input}" [${c.path}]', () {
        final result = DiceExpression.tryParse(c.input);

        expect(result, ParsedDiceExpression(_expected(c)));
      });
    }
  });

  /// Requirement: per case - doc/specs/dice-and-rolls.md FR-022, FR-023, FR-024,
  ///   FR-025, FR-026, FR-027 and FR-028 - each rejected input is a result
  ///   carrying exactly one typed reason.
  /// Path: per case
  group('tryParse rejects', () {
    /// Requirement: per case
    /// Path: per case
    for (final c in _rejected) {
      test('${c.label} "${c.input}" as ${c.reason.name} [${c.path}]', () {
        final result = DiceExpression.tryParse(c.input);

        expect(result, RejectedDiceExpression(c.reason));
      });
    }
  });

  /// Requirement: doc/specs/dice-and-rolls.md FR-029 - tryParse never throws
  ///   for any input string.
  /// Path: unhappy (invalid input)
  group('tryParse never throws', () {
    final hostile = <String, String>{
      'a very long count': '${'9' * 100000}d6',
      'a very long run of leading zeros': '${'0' * 100000}1d6',
      'a very long run of d': 'd' * 100000,
      'a very long run of spaces': '1d6${' ' * 100000}',
      'a very long modifier': '1d6+${'9' * 100000}',
      'a null character': '\u0000',
      'an escape sequence': '\u001b[0m1d6',
      'a carriage return': '1d6\r',
      'a tab before the sign': '1d6\t+ 2',
      'a lone high surrogate': '\ud800',
      'a lone low surrogate in the sides': '1d\udc00',
      'a surrogate pair': '1d\u{1F3B2}',
    };

    /// Requirement: per case - doc/specs/dice-and-rolls.md FR-029 - hostile
    ///   strings give a result variant and do not throw.
    /// Path: per case
    for (final entry in hostile.entries) {
      test('${entry.key} gives a result [unhappy (invalid input)]', () {
        final result = DiceExpression.tryParse(entry.value);

        expect(
          result,
          anyOf(isA<ParsedDiceExpression>(), isA<RejectedDiceExpression>()),
        );
      });
    }

    /// Requirement: doc/specs/dice-and-rolls.md FR-029 and FR-030 - for a
    ///   seeded stream of random strings over the notation alphabet, tryParse
    ///   returns a result and every parsed expression round-trips through its
    ///   notation.
    /// Path: unhappy (invalid input)
    test('2000 generated strings give results that round-trip', () {
      const alphabet = [
        '0', '1', '2', '9', 'd', 'D', '+', '-', _minus, _enDash, ' ', //
        'x', '\n', '.', '\u0000', '\ud800', '5', '7',
      ];
      final random = Random(7);
      var parsed = 0;
      var rejected = 0;

      for (var i = 0; i < 2000; i++) {
        final length = random.nextInt(12);
        final input = [
          for (var j = 0; j < length; j++)
            alphabet[random.nextInt(alphabet.length)],
        ].join();

        final result = DiceExpression.tryParse(input);

        switch (result) {
          case ParsedDiceExpression(:final expression):
            parsed++;
            expect(
              DiceExpression.tryParse(expression.notation),
              result,
              reason: 'round trip of "$input"',
            );
          case RejectedDiceExpression():
            rejected++;
        }
      }

      expect(parsed, greaterThan(0));
      expect(rejected, greaterThan(0));
    });
  });

  /// Requirement: per case - doc/specs/dice-and-rolls.md FR-030 - tryParse(notation)
  ///   returns an expression equal to the original for every valid expression.
  /// Path: per case
  group('notation round trip', () {
    /// Requirement: per case
    /// Path: per case
    for (final c in _accepted) {
      test('${c.label}: "${c.input}" [${c.path}]', () {
        final original = _expected(c);

        final result = DiceExpression.tryParse(original.notation);

        expect(result, ParsedDiceExpression(original));
      });
    }

    /// Requirement: per case
    /// Path: per case
    for (final c in _canonical) {
      test('${c.label}: "${c.input}" gives ${c.notation} [${c.path}]', () {
        final result = DiceExpression.tryParse(c.input);

        expect(result, isA<ParsedDiceExpression>());
        expect(
          (result as ParsedDiceExpression).expression.notation,
          c.notation,
        );
      });
    }
  });

  /// Requirement: doc/specs/dice-and-rolls.md FR-075 - the parse result is a
  ///   sealed class with final variants carrying the value or the typed reason.
  /// Path: unhappy (invalid input)
  group('DiceExpressionParse', () {
    /// Requirement: doc/specs/dice-and-rolls.md FR-075 - a switch over the
    ///   result needs no default branch.
    /// Path: unhappy (invalid input)
    test('is switched over exhaustively', () {
      String describe(DiceExpressionParse parse) => switch (parse) {
        ParsedDiceExpression(:final expression) =>
          'parsed ${expression.notation}',
        RejectedDiceExpression(:final reason) => 'rejected ${reason.name}',
      };

      expect(describe(DiceExpression.tryParse('2d8 + 2')), 'parsed 2d8+2');
      expect(describe(DiceExpression.tryParse('2d')), 'rejected malformed');
    });

    /// Requirement: doc/specs/dice-and-rolls.md FR-022 and FR-075 - variants
    ///   compare by value.
    /// Path: unhappy (boundary)
    test('variants compare by value', () {
      final parsed = DiceExpression.tryParse('2d8');
      final parsedAgain = DiceExpression.tryParse('2D8');
      final parsedOther = DiceExpression.tryParse('3d8');
      final rejected = DiceExpression.tryParse('');
      final rejectedAgain = DiceExpression.tryParse('');
      final rejectedOther = DiceExpression.tryParse('2d');

      expect(identical(parsed, parsedAgain), isFalse);
      expect(parsed, parsedAgain);
      expect(parsed.hashCode, parsedAgain.hashCode);
      expect(parsed == parsedOther, isFalse);
      expect(rejected, rejectedAgain);
      expect(rejected.hashCode, rejectedAgain.hashCode);
      expect(rejected == rejectedOther, isFalse);
      expect(parsed == rejected, isFalse);
    });
  });
}
