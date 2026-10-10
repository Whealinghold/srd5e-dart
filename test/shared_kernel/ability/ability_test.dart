import 'package:srd5e/src/shared_kernel/ability/ability.dart';
import 'package:test/test.dart';

void main() {
  /// Requirement: doc/specs/ability-scores.md FR-001 - Ability has exactly six
  ///   values in the order Strength, Dexterity, Constitution, Intelligence,
  ///   Wisdom, Charisma (SRD 5.2.1, "The Six Abilities", p. 5).
  /// Path: happy
  group('Ability', () {
    /// Requirement: doc/specs/ability-scores.md FR-001 - the six values in the
    ///   SRD's order (SRD 5.2.1, "The Six Abilities", p. 5).
    /// Path: happy
    test('has the six abilities in the SRD order', () {
      expect(Ability.values, [
        Ability.strength,
        Ability.dexterity,
        Ability.constitution,
        Ability.intelligence,
        Ability.wisdom,
        Ability.charisma,
      ]);
    });

    /// Requirement: doc/specs/ability-scores.md FR-001 - exactly six values,
    ///   none more (SRD 5.2.1, "The Six Abilities", p. 5).
    /// Path: unhappy (boundary)
    test('has exactly six values', () {
      expect(Ability.values, hasLength(6));
    });
  });
}
