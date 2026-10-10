import 'dart:collection' show UnmodifiableListView;

import '../shared_kernel/dice/dice_expression.dart';
import '../shared_kernel/dice/die_roll.dart';
import '../shared_kernel/dice/roll_result.dart';
import '../shared_ports/dice_roller/dice_roller.dart';

/// How a [FixedDiceRoller] decides the face of each die.
enum _Supply { listed, lowest, highest }

/// A test double [DiceRoller] whose faces you choose.
///
/// `FixedDiceRoller(values)` builds each [RollResult] from the next unused
/// values, in order, across dice and across calls: `[18, 3]` serves one `2d20`
/// or two `1d20` calls ("Roll Two D20s", SRD 5.2.1, p. 8). The supply is
/// finite. A call that needs more dice than remain throws a [StateError] (a
/// test set-up bug, not a port failure), and a value outside 1 to the
/// requested die's sides throws an [ArgumentError] named `values`. A call that
/// fails either way consumes nothing and is not recorded in [requests].
///
/// `FixedDiceRoller.minimum()` rolls 1 on every die and
/// `FixedDiceRoller.maximum()` rolls each die's highest face, for any
/// expression, with an unbounded supply.
///
/// The double is mutable: it advances through its values and records the
/// expressions it was asked for.
final class FixedDiceRoller implements DiceRoller {
  /// Creates a roller that serves [values] in order.
  ///
  /// The list is copied. The values are not validated here; [roll] validates
  /// each value it consumes. An empty list is valid and serves nothing.
  FixedDiceRoller(List<int> values)
    : _supply = _Supply.listed,
      _values = List<int>.of(values);

  /// Creates a roller with an unbounded supply that rolls 1 on every die.
  FixedDiceRoller.minimum() : _supply = _Supply.lowest, _values = const [];

  /// Creates a roller with an unbounded supply that rolls each die's highest
  /// face.
  FixedDiceRoller.maximum() : _supply = _Supply.highest, _values = const [];

  final _Supply _supply;
  final List<int> _values;
  final List<DiceExpression> _requests = [];
  int _next = 0;

  /// The expressions rolled so far, in call order. Unmodifiable.
  List<DiceExpression> get requests => UnmodifiableListView(_requests);

  /// The number of unused values, or `null` for [FixedDiceRoller.minimum] and
  /// [FixedDiceRoller.maximum], whose supply is unbounded.
  int? get remaining =>
      _supply == _Supply.listed ? _values.length - _next : null;

  @override
  RollResult roll(DiceExpression expression) {
    final die = expression.die;
    final faces = switch (_supply) {
      _Supply.lowest => List<int>.filled(expression.count, 1),
      _Supply.highest => List<int>.filled(expression.count, die.sides),
      _Supply.listed => _peek(expression),
    };
    final result = RollResult(expression, [
      for (final face in faces) DieRoll(die, face),
    ]);
    if (_supply == _Supply.listed) _next += expression.count;
    _requests.add(expression);
    return result;
  }

  /// The next `expression.count` values, validated, without consuming them.
  List<int> _peek(DiceExpression expression) {
    if (_values.length - _next < expression.count) {
      throw StateError(
        'FixedDiceRoller has $remaining value(s) left but '
        '${expression.notation} needs ${expression.count}.',
      );
    }
    final faces = _values.sublist(_next, _next + expression.count);
    for (final face in faces) {
      if (face < 1 || face > expression.die.sides) {
        throw ArgumentError.value(
          face,
          'values',
          'must be from 1 to ${expression.die.sides} for ${expression.die}',
        );
      }
    }
    return faces;
  }
}
