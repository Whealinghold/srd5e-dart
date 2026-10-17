import 'package:srd5e/src/content/domain/classes/class_spellcasting_trait.dart';
import 'package:srd5e/src/shared_kernel/ability/ability.dart';
import 'package:test/test.dart';

import '../../../support/operator_equals.dart';

void main() {
  /// Requirement: doc/specs/content-classes.md FR-028 - `spellcasting`, when
  ///   present, is a `SlotSpellcastingTrait` (ability, cantrips flag) or a
  ///   `PactSpellcastingTrait` (ability); the sealed
  ///   `ClassSpellcastingTrait` is exhaustive in a `switch` (SRD 5.2.1,
  ///   "Level 1: Spellcasting" headings, pp. 32, 36, 41, 54, 57, 64, 77;
  ///   "Level 1: Pact Magic", p. 71).
  /// Path: happy
  test('the two variants carry their facts and switch exhaustively', () {
    String describe(ClassSpellcastingTrait trait) => switch (trait) {
      SlotSpellcastingTrait() => 'slots',
      PactSpellcastingTrait() => 'pact',
    };
    const slots = SlotSpellcastingTrait(Ability.intelligence, cantrips: true);
    const pact = PactSpellcastingTrait(Ability.charisma);
    expect(describe(slots), 'slots');
    expect(describe(pact), 'pact');
    expect(slots.ability, Ability.intelligence);
    expect(slots.cantrips, isTrue);
    expect(pact.ability, Ability.charisma);
  });

  /// Requirement: doc/specs/content-classes.md FR-028 - a slot trait without
  ///   cantrips is the Paladin's shape.
  /// Path: happy
  test('a slot trait carries the cantrips flag', () {
    expect(
      const SlotSpellcastingTrait(Ability.charisma, cantrips: false).cantrips,
      isFalse,
    );
  });

  /// Requirement: doc/specs/content-classes.md FR-008 - the variants have
  ///   value equality and a consistent hash code.
  /// Path: happy
  test('value equality and hash code hold for both variants', () {
    const slots = SlotSpellcastingTrait(Ability.intelligence, cantrips: true);
    expect(
      slots,
      equals(const SlotSpellcastingTrait(Ability.intelligence, cantrips: true)),
    );
    expect(
      slots.hashCode,
      const SlotSpellcastingTrait(
        Ability.intelligence,
        cantrips: true,
      ).hashCode,
    );
    expect(
      slots,
      isNot(
        equals(
          const SlotSpellcastingTrait(Ability.intelligence, cantrips: false),
        ),
      ),
    );
    expect(
      slots,
      isNot(equals(const PactSpellcastingTrait(Ability.intelligence))),
    );

    const pact = PactSpellcastingTrait(Ability.charisma);
    expect(pact, equals(const PactSpellcastingTrait(Ability.charisma)));
    expect(
      pact.hashCode,
      const PactSpellcastingTrait(Ability.charisma).hashCode,
    );
    expect(
      pact,
      isNot(equals(const PactSpellcastingTrait(Ability.intelligence))),
    );
    expect(operatorEquals(pact, Object()), isFalse);
  });

  /// Requirement: doc/specs/content-classes.md FR-008 - the debug form names
  ///   the variant and its ability.
  /// Path: happy
  test('the debug forms name the variant', () {
    expect(
      const SlotSpellcastingTrait(
        Ability.intelligence,
        cantrips: true,
      ).toString(),
      'SlotSpellcastingTrait(Ability.intelligence, cantrips: true)',
    );
    expect(
      const PactSpellcastingTrait(Ability.charisma).toString(),
      'PactSpellcastingTrait(Ability.charisma)',
    );
  });
}
