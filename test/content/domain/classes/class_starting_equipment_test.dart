import 'package:srd5e/src/content/domain/classes/class_starting_equipment.dart';
import 'package:test/test.dart';

import '../../../support/argument_error_matcher.dart';

ClassStartingEquipment _fighterOptions() => ClassStartingEquipment(
  a: ClassEquipmentOption([ClassEquipmentItem('Longsword', 1)], 0),
  b: ClassEquipmentOption([], 75),
  c: ClassEquipmentOption([ClassEquipmentItem('Light Crossbow', 1)], 0),
);

void main() {
  /// Requirement: doc/specs/content-classes.md FR-024, FR-025 - each option
  ///   holds items with quantity at least 1 and gold at least 0; the
  ///   composite carries a, b and the optional c (SRD 5.2.1, "Core Fighter
  ///   Traits: Starting Equipment", p. 47).
  /// Path: happy
  group('Starting-equipment constructor rows (Cases FT equipment)', () {
    /// Requirement: per case
    /// Path: per case
    for (final c in [
      (
        label: 'option C',
        requirement:
            'doc/specs/content-classes.md FR-024 - startingEquipment with '
            'A, B and C is accepted (the Fighter\'s third option)',
        path: 'happy',
        build: _fighterOptions,
        throwsFor: null,
      ),
      (
        label: 'two options only',
        requirement:
            'doc/specs/content-classes.md FR-024 - A and B without C is '
            'accepted',
        path: 'happy',
        build: () => ClassStartingEquipment(
          a: ClassEquipmentOption(const [], 0),
          b: ClassEquipmentOption(const [], 0),
        ),
        throwsFor: null,
      ),
      (
        label: 'empty items',
        requirement:
            'doc/specs/content-classes.md FR-024 - option B with empty '
            'items and gold 75 is accepted (Cases FT: "empty items")',
        path: 'unhappy (empty case)',
        build: () => ClassEquipmentOption(const [], 75),
        throwsFor: null,
      ),
      (
        label: 'quantity zero',
        requirement:
            'doc/specs/content-classes.md FR-024 - item quantity 0 is '
            'rejected (Cases FT: "quantity zero")',
        path: 'unhappy (boundary)',
        build: () => ClassEquipmentItem('Dagger', 0),
        throwsFor: throwsArgumentErrorFor('quantity', 0),
      ),
      (
        label: 'negative gold',
        requirement:
            'doc/specs/content-classes.md FR-024 - gold -1 is rejected '
            '(Cases FT: "negative gold")',
        path: 'unhappy (boundary)',
        build: () => ClassEquipmentOption(const [], -1),
        throwsFor: throwsArgumentErrorFor('gold', -1),
      ),
      (
        label: 'blank name',
        requirement:
            'doc/specs/content-classes.md FR-025 - an item name is stored '
            'as printed and must be non-blank',
        path: 'unhappy (invalid input)',
        build: () => ClassEquipmentItem(' ', 1),
        throwsFor: throwsArgumentErrorFor('name', ' '),
      ),
    ]) {
      test('${c.label} [${c.path}]', () {
        if (c.throwsFor != null) {
          expect(c.build, c.throwsFor);
        } else {
          expect(c.build(), isA<Object>());
        }
      });
    }
  });

  /// Requirement: doc/specs/content-classes.md FR-025 - a leading count is
  ///   not part of the name ("2 Daggers" is Dagger x 2) and a parenthetical
  ///   stays in the name; the choice-naming lines are stored verbatim.
  /// Path: happy
  test('item names are stored verbatim, count separate', () {
    final item = ClassEquipmentItem('Dagger', 2);
    expect(item.name, 'Dagger');
    expect(item.quantity, 2);

    final parenthetical = ClassEquipmentItem('Arcane Focus (Quarterstaff)', 1);
    expect(parenthetical.name, 'Arcane Focus (Quarterstaff)');

    // FR-025 stores a line that names a choice rather than an item
    // verbatim; the constructor test uses a synthetic line, keeping SRD
    // prose out of the unit tests (shared-types-and-ownership.md FR-033).
    const choiceLine = 'Any one tool of the player\'s choice';
    final choice = ClassEquipmentItem(choiceLine, 1);
    expect(choice.name, choiceLine);
  });

  /// Requirement: doc/specs/content-classes.md FR-024, FR-008 - the limits
  ///   are public constants and predicates; value equality holds; the items
  ///   are defensively copied and unmodifiable.
  /// Path: happy
  test('limits, predicates, equality and immutability hold', () {
    expect(ClassEquipmentItem.minQuantity, 1);
    expect(ClassEquipmentItem.isValidQuantity(1), isTrue);
    expect(ClassEquipmentItem.isValidQuantity(0), isFalse);
    expect(ClassEquipmentOption.minGold, 0);
    expect(ClassEquipmentOption.isValidGold(0), isTrue);
    expect(ClassEquipmentOption.isValidGold(-1), isFalse);

    final a = _fighterOptions();
    final b = _fighterOptions();
    expect(a, equals(b));
    expect(a.hashCode, b.hashCode);

    final items = [ClassEquipmentItem('Dagger', 2)];
    final option = ClassEquipmentOption(items, 0);
    items.clear();
    expect(option.items.length, 1);
    expect(
      () => option.items.add(ClassEquipmentItem('Bow', 1)),
      throwsUnsupportedError,
    );
    expect(
      ClassEquipmentItem('Dagger', 2).toString(),
      'ClassEquipmentItem(Dagger, x2)',
    );
    expect(option.toString(), startsWith('ClassEquipmentOption('));
    expect(a.toString(), startsWith('ClassStartingEquipment('));
  });
}
