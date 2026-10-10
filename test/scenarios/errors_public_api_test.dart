import 'package:srd5e/srd5e.dart';
import 'package:test/test.dart';

/// A stand-in for a port's published subtype, declared here because phase 0
/// ships none yet. A real consumer throws the published subtypes instead.
final class _BackendUnavailable extends Srd5eException {
  const _BackendUnavailable({super.cause, super.causeStackTrace});

  @override
  String get errorType => 'backend_unavailable';
}

/// A port-like adapter that guards a failing backend, using only the public
/// API.
int _roll(int Function() backend) => wrapPortFailure(
  backend,
  (cause, stackTrace) =>
      _BackendUnavailable(cause: cause, causeStackTrace: stackTrace),
);

/// The asynchronous counterpart.
Future<int> _rollLater(Future<int> Function() backend) => wrapPortFailureAsync(
  backend,
  (cause, stackTrace) =>
      _BackendUnavailable(cause: cause, causeStackTrace: stackTrace),
);

void main() {
  /// Requirement: doc/specs/errors-and-results.md FR-033 - a consumer catches
  ///   the exported root and reads errorType, cause and causeStackTrace after
  ///   a backend Exception passes through the exported sync guard.
  /// Path: happy
  test('a backend Exception surfaces as a catchable Srd5eException', () {
    const backendFailure = FormatException('backend down');
    final trace = StackTrace.fromString('backend trace');

    Srd5eException? caught;
    try {
      _roll(() => Error.throwWithStackTrace(backendFailure, trace));
    } on Srd5eException catch (e) {
      caught = e;
    }

    expect(caught, isA<Srd5eException>());
    expect(caught!.errorType, 'backend_unavailable');
    expect(caught.cause, same(backendFailure));
    expect(caught.causeStackTrace, same(trace));
  });

  /// Requirement: doc/specs/errors-and-results.md FR-033 - the exported async
  ///   guard returns a value and surfaces an Exception as the typed failure.
  /// Path: happy
  test('the async guard returns a value or a typed failure', () async {
    const backendFailure = FormatException('backend down');

    final value = await _rollLater(() async => 7);
    final failed = _rollLater(() => Future<int>.error(backendFailure));

    expect(value, 7);
    await expectLater(
      failed,
      throwsA(
        isA<Srd5eException>().having((e) => e.cause, 'cause', backendFailure),
      ),
    );
  });

  /// Requirement: doc/specs/errors-and-results.md FR-011 and FR-033 - through
  ///   the public API a programmer error is not turned into a port failure.
  /// Path: unhappy (state error)
  test('a programmer error passes through the exported guard', () {
    expect(
      () => _roll(() => throw StateError('broken invariant')),
      throwsA(isA<StateError>()),
    );
  });

  /// Requirement: doc/specs/errors-and-results.md FR-049 - a switch over the
  ///   non-sealed root needs a default branch, which the consumer provides.
  /// Path: happy
  test('a consumer switch over the root uses a default branch', () {
    const Srd5eException failure = _BackendUnavailable();

    final label = switch (failure) {
      _BackendUnavailable() => 'backend',
      _ => 'other',
    };

    expect(label, 'backend');
  });

  /// Requirement: doc/specs/errors-and-results.md FR-036 - a port that answers
  ///   for a different expression has failed, so the guard raises the port's
  ///   own Srd5eException with a typed reason, never a StateError.
  /// Path: unhappy (failure of collaborator)
  test('a roller answering for another expression is a typed port failure', () {
    final requested = DiceExpression(2, Die.d6);
    final answered = RollResult(DiceExpression(1, Die.d8), [
      DieRoll(Die.d8, 5),
    ]);
    final roller = _WrongExpressionRoller(answered);

    expect(
      () => roller.rollChecked(requested),
      throwsA(
        isA<DiceRollerException>()
            .having(
              (e) => e.reason,
              'reason',
              DiceRollerFailureReason.invalidResult,
            )
            .having((e) => e.expression, 'expression', requested)
            .having((e) => e.errorType, 'errorType', 'dice_roller_exception'),
      ),
    );
  });

  /// Requirement: doc/specs/errors-and-results.md FR-036 - a port that answers
  ///   for the requested expression has not failed.
  /// Path: happy
  test('a roller answering for the requested expression is passed through', () {
    final requested = DiceExpression(1, Die.d8);
    final answered = RollResult(requested, [DieRoll(Die.d8, 5)]);
    final roller = _WrongExpressionRoller(answered);

    expect(roller.rollChecked(requested), same(answered));
  });

  /// Requirement: doc/specs/errors-and-results.md FR-018 - an expected
  ///   rejection is returned as a variant of a sealed result, not thrown.
  /// Path: unhappy (invalid input)
  test('an out-of-range score is returned as a variant, not thrown', () {
    late AbilityScoreResult result;

    expect(() => result = AbilityScore.tryCreate(31), returnsNormally);

    expect(
      result,
      const InvalidAbilityScore(31, AbilityScoreRejection.aboveMaximum),
    );
  });

  /// Requirement: doc/specs/errors-and-results.md FR-045 - a switch over each
  ///   published result compiles with no default branch (the analyzer rejects
  ///   a non-exhaustive switch) and reaches the right arm.
  /// Path: happy
  test('a consumer switch over published results needs no default', () {
    final score = switch (AbilityScore.tryCreate(12)) {
      ValidAbilityScore() => 'valid',
      InvalidAbilityScore() => 'invalid',
    };
    final die = switch (Die.tryCreate(1)) {
      CreatedDie() => 'created',
      RejectedDie() => 'rejected',
    };
    final parse = switch (DiceExpression.tryParse('2d8 + 2')) {
      ParsedDiceExpression() => 'parsed',
      RejectedDiceExpression() => 'rejected',
    };

    expect([score, die, parse], ['valid', 'rejected', 'parsed']);
  });

  /// Requirement: doc/specs/errors-and-results.md FR-019 - results with equal
  ///   data are equal and have equal hash codes.
  /// Path: happy
  test('results with equal data are equal with equal hash codes', () {
    final validA = AbilityScore.tryCreate(12);
    final validB = AbilityScore.tryCreate(12);
    final invalidA = AbilityScore.tryCreate(0);
    final invalidB = AbilityScore.tryCreate(0);
    final parsedA = DiceExpression.tryParse('2d8+2');
    final parsedB = DiceExpression.tryParse('2d8 + 2');

    expect(validA, validB);
    expect(validA.hashCode, validB.hashCode);
    expect(invalidA, invalidB);
    expect(invalidA.hashCode, invalidB.hashCode);
    expect(parsedA, parsedB);
    expect(parsedA.hashCode, parsedB.hashCode);
  });

  /// Requirement: doc/specs/errors-and-results.md FR-019 - any differing field
  ///   gives inequality.
  /// Path: unhappy (rule interaction)
  group('results differing in one field are not equal', () {
    /// Requirement: doc/specs/errors-and-results.md FR-019 - the wrapped score
    ///   differs.
    /// Path: unhappy (rule interaction)
    test('a valid score of 12 is not a valid score of 13', () {
      expect(AbilityScore.tryCreate(12), isNot(AbilityScore.tryCreate(13)));
    });

    /// Requirement: doc/specs/errors-and-results.md FR-019 - the rejected value
    ///   differs, the reason is the same.
    /// Path: unhappy (rule interaction)
    test('a rejected 31 is not a rejected 32', () {
      expect(AbilityScore.tryCreate(31), isNot(AbilityScore.tryCreate(32)));
    });

    /// Requirement: doc/specs/errors-and-results.md FR-019 - the reason
    ///   differs, the value is the same type of problem.
    /// Path: unhappy (rule interaction)
    test('a rejection below the minimum is not one above the maximum', () {
      const below = InvalidAbilityScore(5, AbilityScoreRejection.belowMinimum);
      const above = InvalidAbilityScore(5, AbilityScoreRejection.aboveMaximum);

      expect(below, isNot(above));
    });

    /// Requirement: doc/specs/errors-and-results.md FR-019 - the variant
    ///   differs.
    /// Path: unhappy (rule interaction)
    test('a valid result is not an invalid result', () {
      expect(
        AbilityScore.tryCreate(1),
        isNot(const InvalidAbilityScore(1, AbilityScoreRejection.belowMinimum)),
      );
    });
  });

  /// Requirement: doc/specs/errors-and-results.md FR-021 - a collection a value
  ///   object exposes cannot be mutated.
  /// Path: unhappy (immutability)
  test('the rolls of a RollResult cannot be mutated', () {
    final result = RollResult(DiceExpression(1, Die.d6), [DieRoll(Die.d6, 4)]);

    expect(() => result.rolls.add(DieRoll(Die.d6, 1)), throwsUnsupportedError);
    expect(result.rolls.clear, throwsUnsupportedError);
    expect(result.rolls, [DieRoll(Die.d6, 4)]);
  });

  /// Requirement: doc/specs/errors-and-results.md FR-021 - the exposed
  ///   collection is a copy: changing the list passed in afterwards does not
  ///   change the value, through the constructor or the non-throwing factory.
  /// Path: unhappy (immutability)
  group('a RollResult copies the list it was given', () {
    /// Requirement: doc/specs/errors-and-results.md FR-021 - constructor path.
    /// Path: unhappy (immutability)
    test('the constructor copies', () {
      final source = [DieRoll(Die.d6, 4)];
      final result = RollResult(DiceExpression(1, Die.d6), source);

      source[0] = DieRoll(Die.d6, 1);

      expect(result.rolls, [DieRoll(Die.d6, 4)]);
      expect(result.total, 4);
    });

    /// Requirement: doc/specs/errors-and-results.md FR-021 - tryCreate path.
    /// Path: unhappy (immutability)
    test('tryCreate copies', () {
      final source = [DieRoll(Die.d6, 4)];
      final creation = RollResult.tryCreate(DiceExpression(1, Die.d6), source);

      source[0] = DieRoll(Die.d6, 1);

      final result = (creation as CreatedRollResult).value;
      expect(result.rolls, [DieRoll(Die.d6, 4)]);
      expect(
        () => result.rolls.add(DieRoll(Die.d6, 2)),
        throwsUnsupportedError,
      );
    });
  });

  /// Requirement: doc/specs/errors-and-results.md FR-035 - the rejection a
  ///   scalar factory returns is a typed value, an enum, never display text.
  /// Path: unhappy (invalid input)
  test('scalar factories reject with an enum reason', () {
    final reasons = <Object>[
      (AbilityScore.tryCreate(0) as InvalidAbilityScore).reason,
      (Die.tryCreate(1) as RejectedDie).reason,
      (DiceExpression.tryCreate(0, Die.d6) as RejectedDiceExpressionInput)
          .reason,
      (DiceExpression.tryParse('') as RejectedDiceExpression).reason,
    ];

    expect(reasons, everyElement(isA<Enum>()));
  });

  /// Requirement: per case
  /// Path: per case
  for (final c in _factoryCases) {
    test('${c.label} [${c.path}]', () {
      final reason = c.reason();

      expect(reason, c.expectedReason);
      expect(
        c.construct,
        c.expectedReason == null
            ? returnsNormally
            : throwsA(isA<ArgumentError>()),
      );
    });
  }

  /// Requirement: per case
  /// Path: per case
  for (final c in _parseCases) {
    test('${c.label} [${c.path}]', () {
      final result = DiceExpression.tryParse(c.text);

      expect(switch (result) {
        ParsedDiceExpression() => null,
        RejectedDiceExpression(:final reason) => reason,
      }, c.expectedReason);
    });
  }

  /// Requirement: per case
  /// Path: per case
  for (final c in _argumentCases) {
    test('${c.label} [${c.path}]', () {
      expect(
        c.construct,
        throwsA(
          isA<ArgumentError>()
              .having((e) => e.name, 'name', c.name)
              .having((e) => e.invalidValue, 'invalidValue', c.invalidValue),
        ),
      );
    });
  }
}

/// One non-throwing text parse: the text and the one reason it is rejected
/// with (`null` accepts).
typedef _ParseCase = ({
  String label,
  String requirement,
  String path,
  String text,
  DiceExpressionRejection? expectedReason,
});

/// One value-object constructor given an invalid argument.
typedef _ArgumentCase = ({
  String label,
  String requirement,
  String path,
  Object? Function() construct,
  String name,
  Object? invalidValue,
});

const _largestInt = 9007199254740991;

const _factoryRequirement =
    'doc/specs/errors-and-results.md FR-025, FR-026 and FR-035';
const _parseRequirement = 'doc/specs/errors-and-results.md FR-025 and FR-035';
const _argumentRequirement = 'doc/specs/errors-and-results.md FR-027';

/// One input of the convention table for FR-025, FR-026 and FR-035: the
/// non-throwing path, the throwing constructor path and the rejection both
/// must agree on (`null` accepts).
typedef _FactoryCase = ({
  String label,
  String requirement,
  String path,
  Object? expectedReason,
  Object? Function() reason,
  Object? Function() construct,
});

String _pathOf(Object? expected) =>
    expected == null ? 'happy' : 'unhappy (boundary)';

_FactoryCase _abilityCase(String label, int value, Object? expected) => (
  label: 'AbilityScore: $label',
  requirement: _factoryRequirement,
  path: _pathOf(expected),
  expectedReason: expected,
  reason: () => switch (AbilityScore.tryCreate(value)) {
    ValidAbilityScore() => null,
    InvalidAbilityScore(:final reason) => reason,
  },
  construct: () => AbilityScore(value),
);

_FactoryCase _dieCase(String label, int sides, Object? expected) => (
  label: 'Die: $label',
  requirement: _factoryRequirement,
  path: _pathOf(expected),
  expectedReason: expected,
  reason: () => switch (Die.tryCreate(sides)) {
    CreatedDie() => null,
    RejectedDie(:final reason) => reason,
  },
  construct: () => Die(sides),
);

_FactoryCase _expressionCase(
  String label,
  int count,
  int modifier,
  Object? expected,
) => (
  label: 'DiceExpression: $label',
  requirement: _factoryRequirement,
  path: _pathOf(expected),
  expectedReason: expected,
  reason: () =>
      switch (DiceExpression.tryCreate(count, Die.d6, modifier: modifier)) {
        CreatedDiceExpression() => null,
        RejectedDiceExpressionInput(:final reason) => reason,
      },
  construct: () => DiceExpression(count, Die.d6, modifier: modifier),
);

const _below = AbilityScoreRejection.belowMinimum;
const _above = AbilityScoreRejection.aboveMaximum;
const _sides = DieRejection.sidesOutOfRange;
const _count = DiceExpressionRejection.countOutOfRange;
const _modifier = DiceExpressionRejection.modifierOutOfRange;

final List<_FactoryCase> _factoryCases = [
  _abilityCase('0 is below the minimum', 0, _below),
  _abilityCase('1 is the minimum', 1, null),
  _abilityCase('30 is the maximum', 30, null),
  _abilityCase('31 is above the maximum', 31, _above),
  _abilityCase('the most negative safe integer', -_largestInt, _below),
  _abilityCase('the largest safe integer', _largestInt, _above),
  _dieCase('1 side is below the minimum', 1, _sides),
  _dieCase('2 sides is the minimum', 2, null),
  _dieCase('1000 sides is the maximum', 1000, null),
  _dieCase('1001 sides is above the maximum', 1001, _sides),
  _dieCase('the most negative safe integer', -_largestInt, _sides),
  _dieCase('the largest safe integer', _largestInt, _sides),
  _expressionCase('count 0 is below the minimum', 0, 0, _count),
  _expressionCase('count 1 is the minimum', 1, 0, null),
  _expressionCase('count 1000 is the maximum', 1000, 0, null),
  _expressionCase('count 1001 is above the maximum', 1001, 0, _count),
  _expressionCase('modifier 1000000 is the largest', 1, 1000000, null),
  _expressionCase('modifier -1000000 is the smallest', 1, -1000000, null),
  _expressionCase('modifier 1000001 is too large', 1, 1000001, _modifier),
  _expressionCase('modifier -1000001 is too small', 1, -1000001, _modifier),
  _expressionCase('the count is judged first', 0, _largestInt, _count),
  _expressionCase('the largest safe integer count', _largestInt, 0, _count),
];

final List<_ParseCase> _parseCases = [
  (
    label: 'DiceExpression.tryParse: empty text is rejected as empty',
    requirement: _parseRequirement,
    path: 'unhappy (empty and minimal)',
    text: '',
    expectedReason: DiceExpressionRejection.empty,
  ),
  (
    label: 'DiceExpression.tryParse: words are malformed',
    requirement: _parseRequirement,
    path: 'unhappy (invalid input)',
    text: 'abc',
    expectedReason: DiceExpressionRejection.malformed,
  ),
  (
    label: 'DiceExpression.tryParse: surrounding whitespace is malformed',
    requirement: _parseRequirement,
    path: 'unhappy (invalid input)',
    text: ' 1d6',
    expectedReason: DiceExpressionRejection.malformed,
  ),
  (
    label: 'DiceExpression.tryParse: a non-ASCII digit is malformed',
    requirement: _parseRequirement,
    path: 'unhappy (invalid input)',
    text: '٣d6',
    expectedReason: DiceExpressionRejection.malformed,
  ),
  (
    label: 'DiceExpression.tryParse: 1d6 is accepted',
    requirement: _parseRequirement,
    path: 'happy',
    text: '1d6',
    expectedReason: null,
  ),
  (
    label: 'DiceExpression.tryParse: a count of 0 is out of range',
    requirement: _parseRequirement,
    path: 'unhappy (boundary)',
    text: '0d6',
    expectedReason: DiceExpressionRejection.countOutOfRange,
  ),
  (
    label: 'DiceExpression.tryParse: one side is out of range',
    requirement: _parseRequirement,
    path: 'unhappy (boundary)',
    text: 'd1',
    expectedReason: DiceExpressionRejection.sidesOutOfRange,
  ),
  (
    label:
        'DiceExpression.tryParse: a modifier above the limit is out of range',
    requirement: _parseRequirement,
    path: 'unhappy (boundary)',
    text: '1d6+1000001',
    expectedReason: DiceExpressionRejection.modifierOutOfRange,
  ),
  (
    label: 'DiceExpression.tryParse: a count too long for an int never throws',
    requirement: _parseRequirement,
    path: 'unhappy (boundary)',
    text: '99999999999999999999999999d6',
    expectedReason: DiceExpressionRejection.countOutOfRange,
  ),
  (
    label: 'DiceExpression.tryParse: sides too long for an int never throws',
    requirement: _parseRequirement,
    path: 'unhappy (boundary)',
    text: '1d99999999999999999999999999',
    expectedReason: DiceExpressionRejection.sidesOutOfRange,
  ),
  (
    label:
        'DiceExpression.tryParse: a modifier too long for an int never throws',
    requirement: _parseRequirement,
    path: 'unhappy (boundary)',
    text: '1d6+99999999999999999999',
    expectedReason: DiceExpressionRejection.modifierOutOfRange,
  ),
];

final List<_ArgumentCase> _argumentCases = [
  (
    label: 'AbilityScore(0) names value and carries 0',
    requirement: _argumentRequirement,
    path: 'unhappy (invalid input)',
    construct: () => AbilityScore(0),
    name: 'value',
    invalidValue: 0,
  ),
  (
    label: 'AbilityScore(31) names value and carries 31',
    requirement: _argumentRequirement,
    path: 'unhappy (invalid input)',
    construct: () => AbilityScore(31),
    name: 'value',
    invalidValue: 31,
  ),
  (
    label: 'Die(1) names sides and carries 1',
    requirement: _argumentRequirement,
    path: 'unhappy (invalid input)',
    construct: () => Die(1),
    name: 'sides',
    invalidValue: 1,
  ),
  (
    label: 'Die(1001) names sides and carries 1001',
    requirement: _argumentRequirement,
    path: 'unhappy (invalid input)',
    construct: () => Die(1001),
    name: 'sides',
    invalidValue: 1001,
  ),
  (
    label: 'DiceExpression with count 0 names count and carries 0',
    requirement: _argumentRequirement,
    path: 'unhappy (invalid input)',
    construct: () => DiceExpression(0, Die.d6),
    name: 'count',
    invalidValue: 0,
  ),
  (
    label: 'DiceExpression with count 1001 names count and carries 1001',
    requirement: _argumentRequirement,
    path: 'unhappy (invalid input)',
    construct: () => DiceExpression(1001, Die.d6),
    name: 'count',
    invalidValue: 1001,
  ),
  (
    label: 'DiceExpression with modifier 1000001 names modifier',
    requirement: _argumentRequirement,
    path: 'unhappy (invalid input)',
    construct: () => DiceExpression(1, Die.d6, modifier: 1000001),
    name: 'modifier',
    invalidValue: 1000001,
  ),
  (
    label: 'DiceExpression with modifier -1000001 names modifier',
    requirement: _argumentRequirement,
    path: 'unhappy (invalid input)',
    construct: () => DiceExpression(1, Die.d6, modifier: -1000001),
    name: 'modifier',
    invalidValue: -1000001,
  ),
  (
    label: 'DieRoll above the die names value and carries it',
    requirement: _argumentRequirement,
    path: 'unhappy (invalid input)',
    construct: () => DieRoll(Die.d6, 7),
    name: 'value',
    invalidValue: 7,
  ),
  (
    label: 'RollResult with the wrong number of rolls names rolls',
    requirement: _argumentRequirement,
    path: 'unhappy (invalid input)',
    construct: () => RollResult(DiceExpression(2, Die.d6), <DieRoll>[]),
    name: 'rolls',
    invalidValue: <DieRoll>[],
  ),
];

/// A roller that breaks its port contract by answering for another expression.
final class _WrongExpressionRoller implements DiceRoller {
  _WrongExpressionRoller(this._answer);

  final RollResult _answer;

  @override
  RollResult roll(DiceExpression expression) => _answer;
}
