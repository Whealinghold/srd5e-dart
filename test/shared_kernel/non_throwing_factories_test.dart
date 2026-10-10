import 'package:srd5e/src/shared_kernel/ability/ability_score.dart';
import 'package:srd5e/src/shared_kernel/ability/ability_score_result.dart';
import 'package:srd5e/src/shared_kernel/dice/dice_expression.dart';
import 'package:srd5e/src/shared_kernel/dice/die.dart';
import 'package:srd5e/src/shared_kernel/dice/die_roll.dart';
import 'package:srd5e/src/shared_kernel/dice/roll_result.dart';
import 'package:test/test.dart';

import '../support/argument_error_matcher.dart';

/// The largest integer that is exact on every platform.
const int _safeInteger = 9007199254740991;

/// One input pushed through a non-throwing factory and the throwing
/// constructor of the same type.
typedef _Case = ({
  String label,
  String requirement,
  String path,

  // Calls the non-throwing factory and says whether it returned a failure.
  bool Function() factoryFails,

  // Calls the throwing constructor.
  void Function() construct,

  // Whether the factory is expected to return a failure.
  bool failed,

  // What the constructor is expected to do: return, or throw an
  // ArgumentError carrying the argument name and the offending value.
  Matcher constructorOutcome,
});

_Case _die(int sides, {required bool failed, required String path}) => (
  label: 'Die with $sides sides',
  requirement: 'doc/specs/errors-and-results.md FR-025, FR-026, FR-027',
  path: path,
  factoryFails: () => Die.tryCreate(sides) is RejectedDie,
  construct: () => Die(sides),
  failed: failed,
  constructorOutcome: failed
      ? throwsArgumentErrorFor('sides', sides)
      : returnsNormally,
);

_Case _score(int value, {required bool failed, required String path}) => (
  label: 'AbilityScore of $value',
  requirement: 'doc/specs/errors-and-results.md FR-025, FR-026, FR-027',
  path: path,
  factoryFails: () => AbilityScore.tryCreate(value) is InvalidAbilityScore,
  construct: () => AbilityScore(value),
  failed: failed,
  constructorOutcome: failed
      ? throwsArgumentErrorFor('value', value)
      : returnsNormally,
);

_Case _roll(int value, {required bool failed, required String path}) => (
  label: 'DieRoll of $value on a d6',
  requirement: 'doc/specs/errors-and-results.md FR-025, FR-026, FR-027',
  path: path,
  factoryFails: () => DieRoll.tryCreate(Die.d6, value) is RejectedDieRoll,
  construct: () => DieRoll(Die.d6, value),
  failed: failed,
  constructorOutcome: failed
      ? throwsArgumentErrorFor('value', value)
      : returnsNormally,
);

_Case _expression(
  int count,
  int modifier, {
  required bool failed,
  required String path,
  String? argument,
  Object? invalid,
}) => (
  label: 'DiceExpression of $count d6 plus $modifier',
  requirement: 'doc/specs/errors-and-results.md FR-025, FR-026, FR-027',
  path: path,
  factoryFails: () =>
      DiceExpression.tryCreate(count, Die.d6, modifier: modifier)
          is RejectedDiceExpressionInput,
  construct: () => DiceExpression(count, Die.d6, modifier: modifier),
  failed: failed,
  constructorOutcome: failed
      ? throwsArgumentErrorFor(argument!, invalid)
      : returnsNormally,
);

_Case _parsed(
  String text,
  void Function() construct, {
  required bool failed,
  required String path,
  String? argument,
  Object? invalid,
}) => (
  label: 'DiceExpression.tryParse of "$text"',
  requirement: 'doc/specs/errors-and-results.md FR-025, FR-026, FR-027',
  path: path,
  factoryFails: () => DiceExpression.tryParse(text) is RejectedDiceExpression,
  construct: construct,
  failed: failed,
  constructorOutcome: failed
      ? throwsArgumentErrorFor(argument!, invalid)
      : returnsNormally,
);

_Case _result({
  required String label,
  required DiceExpression expression,
  required List<DieRoll> rolls,
  required bool failed,
  required String path,
}) => (
  label: 'RollResult of $label',
  requirement: 'doc/specs/errors-and-results.md FR-025, FR-026, FR-027',
  path: path,
  factoryFails: () =>
      RollResult.tryCreate(expression, rolls) is RejectedRollResult,
  construct: () => RollResult(expression, rolls),
  failed: failed,
  constructorOutcome: failed
      ? throwsArgumentErrorFor('rolls', rolls)
      : returnsNormally,
);

final DiceExpression _twoD6 = DiceExpression(2, Die.d6);

/// Case table: the same input through both paths, ends and extremes included.
final List<_Case> _cases = [
  _die(2, failed: false, path: 'unhappy (boundary)'),
  _die(1000, failed: false, path: 'unhappy (boundary)'),
  _die(1, failed: true, path: 'unhappy (boundary)'),
  _die(1001, failed: true, path: 'unhappy (boundary)'),
  _die(0, failed: true, path: 'unhappy (boundary)'),
  _die(-_safeInteger, failed: true, path: 'unhappy (invalid input)'),
  _die(_safeInteger, failed: true, path: 'unhappy (invalid input)'),
  _score(1, failed: false, path: 'unhappy (boundary)'),
  _score(30, failed: false, path: 'unhappy (boundary)'),
  _score(0, failed: true, path: 'unhappy (boundary)'),
  _score(31, failed: true, path: 'unhappy (boundary)'),
  _score(-_safeInteger, failed: true, path: 'unhappy (invalid input)'),
  _score(_safeInteger, failed: true, path: 'unhappy (invalid input)'),
  _roll(1, failed: false, path: 'unhappy (boundary)'),
  _roll(6, failed: false, path: 'unhappy (boundary)'),
  _roll(0, failed: true, path: 'unhappy (boundary)'),
  _roll(7, failed: true, path: 'unhappy (boundary)'),
  _roll(-_safeInteger, failed: true, path: 'unhappy (invalid input)'),
  _roll(_safeInteger, failed: true, path: 'unhappy (invalid input)'),
  _expression(1, 0, failed: false, path: 'unhappy (boundary)'),
  _expression(1000, 0, failed: false, path: 'unhappy (boundary)'),
  _expression(1, 1000000, failed: false, path: 'unhappy (boundary)'),
  _expression(1, -1000000, failed: false, path: 'unhappy (boundary)'),
  _expression(
    0,
    0,
    failed: true,
    path: 'unhappy (boundary)',
    argument: 'count',
    invalid: 0,
  ),
  _expression(
    1001,
    0,
    failed: true,
    path: 'unhappy (boundary)',
    argument: 'count',
    invalid: 1001,
  ),
  _expression(
    1,
    1000001,
    failed: true,
    path: 'unhappy (boundary)',
    argument: 'modifier',
    invalid: 1000001,
  ),
  _expression(
    1,
    -1000001,
    failed: true,
    path: 'unhappy (boundary)',
    argument: 'modifier',
    invalid: -1000001,
  ),
  _expression(
    -_safeInteger,
    _safeInteger,
    failed: true,
    path: 'unhappy (invalid input)',
    argument: 'count',
    invalid: -_safeInteger,
  ),
  _expression(
    1,
    _safeInteger,
    failed: true,
    path: 'unhappy (invalid input)',
    argument: 'modifier',
    invalid: _safeInteger,
  ),
  _parsed('1d6', () => DiceExpression(1, Die(6)), failed: false, path: 'happy'),
  _parsed(
    '1000d1000+1000000',
    () => DiceExpression(1000, Die(1000), modifier: 1000000),
    failed: false,
    path: 'unhappy (boundary)',
  ),
  _parsed(
    '0d6',
    () => DiceExpression(0, Die(6)),
    failed: true,
    path: 'unhappy (boundary)',
    argument: 'count',
    invalid: 0,
  ),
  _parsed(
    '1001d6',
    () => DiceExpression(1001, Die(6)),
    failed: true,
    path: 'unhappy (boundary)',
    argument: 'count',
    invalid: 1001,
  ),
  _parsed(
    '1d1',
    () => DiceExpression(1, Die(1)),
    failed: true,
    path: 'unhappy (boundary)',
    argument: 'sides',
    invalid: 1,
  ),
  _parsed(
    '1d1001',
    () => DiceExpression(1, Die(1001)),
    failed: true,
    path: 'unhappy (boundary)',
    argument: 'sides',
    invalid: 1001,
  ),
  _parsed(
    '1d6+1000001',
    () => DiceExpression(1, Die(6), modifier: 1000001),
    failed: true,
    path: 'unhappy (boundary)',
    argument: 'modifier',
    invalid: 1000001,
  ),
  _parsed(
    '1d6-1000001',
    () => DiceExpression(1, Die(6), modifier: -1000001),
    failed: true,
    path: 'unhappy (boundary)',
    argument: 'modifier',
    invalid: -1000001,
  ),
  _result(
    label: 'the right number of rolls of the right die',
    expression: _twoD6,
    rolls: [DieRoll(Die.d6, 1), DieRoll(Die.d6, 6)],
    failed: false,
    path: 'happy',
  ),
  _result(
    label: 'no rolls for two dice',
    expression: _twoD6,
    rolls: const [],
    failed: true,
    path: 'unhappy (empty case)',
  ),
  _result(
    label: 'a roll of another die',
    expression: _twoD6,
    rolls: [DieRoll(Die.d6, 1), DieRoll(Die.d8, 1)],
    failed: true,
    path: 'unhappy (rule conflict)',
  ),
];

/// Text pushed through `DiceExpression.tryParse`, which has no throwing
/// counterpart taking text.
const List<({String label, String requirement, String path, String text})>
_texts = [
  (
    label: 'empty text',
    requirement: 'doc/specs/errors-and-results.md FR-025',
    path: 'unhappy (empty case)',
    text: '',
  ),
  (
    label: 'only spaces',
    requirement: 'doc/specs/errors-and-results.md FR-025',
    path: 'unhappy (invalid input)',
    text: '   ',
  ),
  (
    label: 'a die letter with nothing else',
    requirement: 'doc/specs/errors-and-results.md FR-025',
    path: 'unhappy (invalid input)',
    text: 'd',
  ),
  (
    label: 'a count too large to be an int',
    requirement: 'doc/specs/errors-and-results.md FR-025',
    path: 'unhappy (boundary)',
    text: '99999999999999999999999999d6',
  ),
  (
    label: 'sides too large to be an int',
    requirement: 'doc/specs/errors-and-results.md FR-025',
    path: 'unhappy (boundary)',
    text: '1d99999999999999999999999999',
  ),
  (
    label: 'a modifier too large to be an int',
    requirement: 'doc/specs/errors-and-results.md FR-025',
    path: 'unhappy (boundary)',
    text: '1d6+99999999999999999999999999',
  ),
  (
    label: 'a NUL character',
    requirement: 'doc/specs/errors-and-results.md FR-025',
    path: 'unhappy (invalid input)',
    text: '1d6\u0000',
  ),
  (
    label: 'non-ASCII digits',
    requirement: 'doc/specs/errors-and-results.md FR-025',
    path: 'unhappy (invalid input)',
    text: '１d６',
  ),
];

void main() {
  /// Requirement: doc/specs/errors-and-results.md FR-025, FR-026 and FR-027 -
  ///   the non-throwing factories and the throwing constructors of the
  ///   shared-kernel value objects agree on every input (SRD-independent
  ///   package convention).
  /// Path: unhappy (rule conflict)
  group('factory and constructor agree', () {
    /// Requirement: per case
    /// Path: per case
    for (final c in _cases) {
      test('${c.label} [${c.path}]', () {
        expect(c.factoryFails, returnsNormally);
        expect(c.factoryFails(), c.failed);
        expect(c.construct, c.constructorOutcome);
      });
    }
  });

  /// Requirement: doc/specs/errors-and-results.md FR-025 - tryParse never
  ///   throws, whatever the text.
  /// Path: unhappy (invalid input)
  group('DiceExpression.tryParse never throws', () {
    /// Requirement: per case
    /// Path: per case
    for (final c in _texts) {
      test('${c.label} [${c.path}]', () {
        expect(() => DiceExpression.tryParse(c.text), returnsNormally);
        expect(DiceExpression.tryParse(c.text), isA<RejectedDiceExpression>());
      });
    }
  });
}
