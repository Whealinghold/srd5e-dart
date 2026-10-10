import 'package:srd5e/srd5e.dart';
import 'package:test/test.dart';

void main() {
  /// Requirement: doc/specs/modifiers-and-advantage.md section 6 - srd5e.dart
  ///   exports Modifier, RollCircumstance, Advantage, Disadvantage and
  ///   RollMode. A name that is not exported does not compile; a renamed type
  ///   fails the comparison.
  /// Path: happy
  test('srd5e.dart exports the modifier and roll mode types', () {
    final names = <Type>[
      Modifier,
      RollCircumstance,
      Advantage,
      Disadvantage,
      RollMode,
    ].map((type) => type.toString());

    expect(names, [
      'Modifier',
      'RollCircumstance',
      'Advantage',
      'Disadvantage',
      'RollMode',
    ]);
  });

  /// Requirement: doc/specs/modifiers-and-advantage.md sections 1 and 6 - a
  ///   d20 number is resolved, selected and modified through the public entry
  ///   point only: Advantage and Disadvantage cancel, so one d20 is used and
  ///   the modifiers add (SRD 5.2.1, "D20 Tests", p. 6; "They Don't Stack",
  ///   p. 8).
  /// Path: happy
  test('resolve, select and apply work through the public API alone', () {
    const circumstances = <RollCircumstance>[
      Advantage(),
      Advantage(),
      Disadvantage(),
    ];

    final mode = RollMode.resolve(circumstances);
    final used = mode.select(List.filled(mode.diceCount, 14));
    final total = Modifier.sum(const [Modifier(3), Modifier(-1)]).applyTo(used);

    expect(mode, RollMode.normal);
    expect(mode.diceCount, 1);
    expect(total, 16);
  });

  /// Requirement: doc/specs/modifiers-and-advantage.md FR-019, FR-022 and
  ///   FR-042 - with Advantage two d20s are rolled and the higher is used
  ///   (SRD 5.2.1, "Roll Two D20s", p. 8).
  /// Path: happy
  test(
    'Advantage rolls two d20s and uses the higher through the public API',
    () {
      final mode = RollMode.resolve(const [Advantage()]);

      final used = mode.select([18, 3]);

      expect(mode.diceCount, 2);
      expect(used, 18);
    },
  );
}
