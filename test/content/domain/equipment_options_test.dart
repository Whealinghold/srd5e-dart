import 'package:srd5e/src/content/domain/equipment_options.dart';
import 'package:test/test.dart';

import '../../support/argument_error_matcher.dart';
import '../../support/operator_equals.dart';

void main() {
  /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-030 -
  ///   an item holds its printed name and a quantity of at least one; the
  ///   quantity and name rules reject the invalid shapes.
  /// Path: happy
  group('EquipmentItem', () {
    /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-030 -
    ///   a quantity of one is accepted ("no numeral means quantity 1") and
    ///   the parenthetical stays in the name.
    /// Path: happy
    test('holds a name and a quantity of one or more', () {
      final item = EquipmentItem('Book (prayers)', 1);

      expect(item.name, 'Book (prayers)');
      expect(item.quantity, 1);
      expect(EquipmentItem('Arrows', 20).quantity, 20);
    });

    /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-030 -
    ///   a quantity below 1 is outOfRange (the "Daggers x0" case row).
    /// Path: unhappy (boundary)
    test('rejects a quantity below one', () {
      expect(
        () => EquipmentItem('Daggers', 0),
        throwsArgumentErrorFor('quantity', 0),
      );
      expect(
        () => EquipmentItem('Daggers', -1),
        throwsArgumentErrorFor('quantity', -1),
      );
    });

    /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-030 -
    ///   the name rule (schema FR-027).
    /// Path: unhappy (invalid input)
    test('rejects a blank or whitespace-padded name', () {
      expect(() => EquipmentItem('', 1), throwsArgumentErrorFor('name', ''));
      expect(
        () => EquipmentItem(' Robe', 1),
        throwsArgumentErrorFor('name', ' Robe'),
      );
    });

    /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-030
    ///   and FR-069 - the quantity limit is a public constant and predicate
    ///   the decoder reuses.
    /// Path: happy
    test('the quantity limit is public', () {
      expect(EquipmentItem.minQuantity, 1);
      expect(EquipmentItem.isValidQuantity(1), isTrue);
      expect(EquipmentItem.isValidQuantity(0), isFalse);
    });

    /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-030 -
    ///   value equality.
    /// Path: happy
    test('compares by name and quantity', () {
      final item = EquipmentItem('Daggers', 2);

      expect(item, EquipmentItem('Daggers', 2));
      expect(item.hashCode, EquipmentItem('Daggers', 2).hashCode);
      expect(operatorEquals(item, EquipmentItem('Daggers', 3)), isFalse);
      expect(operatorEquals(item, EquipmentItem('Crowbar', 2)), isFalse);
      expect(operatorEquals(item, 'Daggers'), isFalse);
    });

    /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-030 -
    ///   toString is a debugging form.
    /// Path: happy
    test('an item prints its name and quantity', () {
      expect(
        EquipmentItem('Daggers', 2).toString(),
        'EquipmentItem(Daggers, x2)',
      );
    });
  });

  /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-029 -
  ///   an option holds its items (possibly none) and gold of at least 0,
  ///   unmodifiable and value-equal.
  /// Path: happy
  group('EquipmentOption', () {
    /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-029 -
    ///   an option holds its items and its gold; an empty item list is the
    ///   shape of option B.
    /// Path: happy
    test('holds items and gold, possibly no items', () {
      final option = EquipmentOption([EquipmentItem('Robe', 1)], 8);

      expect(option.items, [EquipmentItem('Robe', 1)]);
      expect(option.gold, 8);
      expect(EquipmentOption([], 50).items, isEmpty);
      expect(EquipmentOption([], 50).gold, 50);
    });

    /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-029 -
    ///   gold is at least 0.
    /// Path: unhappy (boundary)
    test('rejects a negative gold amount', () {
      expect(() => EquipmentOption([], -1), throwsArgumentErrorFor('gold', -1));
    });

    /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-029 -
    ///   the items are an unmodifiable defensive copy.
    /// Path: unhappy (immutability)
    test('holds an unmodifiable item list', () {
      final option = EquipmentOption([EquipmentItem('Robe', 1)], 8);

      expect(
        () => option.items.add(EquipmentItem('Robe', 2)),
        throwsUnsupportedError,
      );
    });

    /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-029 -
    ///   value equality.
    /// Path: happy
    test('compares by items and gold', () {
      final option = EquipmentOption([EquipmentItem('Robe', 1)], 8);
      final same = EquipmentOption([EquipmentItem('Robe', 1)], 8);

      expect(option, same);
      expect(option.hashCode, same.hashCode);
      expect(
        operatorEquals(option, EquipmentOption([EquipmentItem('Robe', 1)], 9)),
        isFalse,
      );
      expect(operatorEquals(option, EquipmentOption([], 8)), isFalse);
      expect(operatorEquals(option, 'Robe'), isFalse);
    });
  });

  /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-029 -
  ///   the two options A and B, value-equal by both.
  /// Path: happy
  group('EquipmentOptions', () {
    /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-029 -
    ///   the two options A and B, as the section 5 model declares them.
    /// Path: happy
    test('holds options A and B', () {
      final a = EquipmentOption([EquipmentItem('Robe', 1)], 8);
      final b = EquipmentOption([], 50);
      final options = EquipmentOptions(a: a, b: b);

      expect(options.a, a);
      expect(options.b, b);
    });

    /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-029 -
    ///   value equality.
    /// Path: happy
    test('compares by both options', () {
      final options = EquipmentOptions(
        a: EquipmentOption([], 8),
        b: EquipmentOption([], 50),
      );

      expect(
        options,
        EquipmentOptions(a: EquipmentOption([], 8), b: EquipmentOption([], 50)),
      );
      expect(options.hashCode, options.hashCode);
      expect(
        operatorEquals(
          options,
          EquipmentOptions(
            a: EquipmentOption([], 9),
            b: EquipmentOption([], 50),
          ),
        ),
        isFalse,
      );
      expect(operatorEquals(options, 'A'), isFalse);
    });

    /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-029 -
    ///   toString is a debugging form.
    /// Path: happy
    test('the options print their parts', () {
      expect(
        EquipmentOptions(
          a: EquipmentOption([], 8),
          b: EquipmentOption([], 50),
        ).toString(),
        'EquipmentOptions(a: EquipmentOption([], 8 GP), '
        'b: EquipmentOption([], 50 GP))',
      );
    });
  });
}
