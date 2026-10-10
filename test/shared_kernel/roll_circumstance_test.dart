import 'package:srd5e/src/shared_kernel/roll_circumstance.dart';
import 'package:test/test.dart';

/// Builds a circumstance at run time, so each call returns a distinct object
/// (a `const` expression would be canonicalised and hide a broken `==`).
Advantage _advantage() {
  const create = Advantage.new;
  return create();
}

/// See [_advantage].
Disadvantage _disadvantage() {
  const create = Disadvantage.new;
  return create();
}

/// Exhaustive over the sealed type with no default branch (FR-034).
String _describe(RollCircumstance circumstance) => switch (circumstance) {
  Advantage() => 'advantage',
  Disadvantage() => 'disadvantage',
};

typedef _EqualityCase = ({
  String label,
  String requirement,
  String path,
  RollCircumstance Function() left,
  RollCircumstance Function() right,
  bool equal,
});

final List<_EqualityCase> _equalities = [
  (
    label: 'Advantage with Advantage',
    requirement:
        'doc/specs/modifiers-and-advantage.md FR-034 (package design; "They Don\'t Stack", p. 8)',
    path: 'happy',
    left: _advantage,
    right: _advantage,
    equal: true,
  ),
  (
    label: 'Disadvantage with Disadvantage',
    requirement:
        'doc/specs/modifiers-and-advantage.md FR-034 (package design; "They Don\'t Stack", p. 8)',
    path: 'happy',
    left: _disadvantage,
    right: _disadvantage,
    equal: true,
  ),
  (
    label: 'Advantage with Disadvantage',
    requirement:
        'doc/specs/modifiers-and-advantage.md FR-034 (package design; "They Don\'t Stack", p. 8)',
    path: 'unhappy (rule interaction)',
    left: _advantage,
    right: _disadvantage,
    equal: false,
  ),
  (
    label: 'Disadvantage with Advantage',
    requirement:
        'doc/specs/modifiers-and-advantage.md FR-034 (package design; "They Don\'t Stack", p. 8)',
    path: 'unhappy (rule interaction)',
    left: _disadvantage,
    right: _advantage,
    equal: false,
  ),
];

void main() {
  /// Requirement: per case - doc/specs/modifiers-and-advantage.md FR-034 - circumstances
  ///   are equal within their own type and never across types (package design;
  ///   SRD 5.2.1, "Advantage/Disadvantage", "They Don't Stack", p. 8).
  /// Path: per case
  group('RollCircumstance equality', () {
    /// Requirement: per case
    /// Path: per case
    for (final c in _equalities) {
      test('${c.label} [${c.path}] (${c.requirement})', () {
        final left = c.left();
        final right = c.right();

        expect(identical(left, right), isFalse);
        expect(left == right, c.equal);
      });
    }

    /// Requirement: per case
    /// Path: per case
    for (final c in _equalities.where((c) => c.equal)) {
      test('${c.label} have equal hash codes [${c.path}]', () {
        final left = c.left();
        final right = c.right();

        expect(left.hashCode, right.hashCode);
      });
    }

    /// Requirement: doc/specs/modifiers-and-advantage.md FR-034 - a
    ///   circumstance is not equal to an unrelated object.
    /// Path: unhappy (invalid input)
    test('is not equal to an unrelated object', () {
      const Object other = 'advantage';

      expect(const Advantage() == other, isFalse);
      expect(const Disadvantage() == other, isFalse);
    });

    /// Requirement: doc/specs/modifiers-and-advantage.md FR-034 - a set holds
    ///   one of each type however many are added (counting is all that
    ///   matters; SRD 5.2.1, "They Don't Stack", p. 8).
    /// Path: unhappy (rule interaction)
    test('a set collapses repeated circumstances of one type', () {
      final set = <RollCircumstance>{
        _advantage(),
        _advantage(),
        _disadvantage(),
        _disadvantage(),
        _disadvantage(),
      };

      expect(set, hasLength(2));
    });
  });

  /// Requirement: doc/specs/modifiers-and-advantage.md FR-034 and FR-042 - the
  ///   sealed type has exactly the subtypes Advantage and Disadvantage, so a
  ///   switch with two cases and no default compiles (this file would not
  ///   compile otherwise).
  /// Path: happy
  group('RollCircumstance exhaustive switch', () {
    /// Requirement: doc/specs/modifiers-and-advantage.md FR-034 - the Advantage
    ///   case is chosen for an Advantage.
    /// Path: happy
    test('an Advantage selects the Advantage case', () {
      expect(_describe(const Advantage()), 'advantage');
    });

    /// Requirement: doc/specs/modifiers-and-advantage.md FR-034 - the
    ///   Disadvantage case is chosen for a Disadvantage.
    /// Path: happy
    test('a Disadvantage selects the Disadvantage case', () {
      expect(_describe(const Disadvantage()), 'disadvantage');
    });
  });

  /// Requirement: doc/specs/modifiers-and-advantage.md FR-042 - circumstances
  ///   carry no data and are const (a cause or source is not modelled).
  /// Path: happy
  test('circumstances are const and carry no data', () {
    const circumstances = <RollCircumstance>[Advantage(), Disadvantage()];

    expect(circumstances.map((c) => c.runtimeType), [Advantage, Disadvantage]);
    expect(const Advantage().toString(), 'Advantage');
    expect(const Disadvantage().toString(), 'Disadvantage');
  });
}
