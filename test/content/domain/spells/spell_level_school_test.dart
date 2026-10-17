import 'package:srd5e/src/content/domain/spells/spell_level.dart';
import 'package:srd5e/src/content/domain/spells/spell_school.dart';
import 'package:test/test.dart';

import '../../../support/argument_error_matcher.dart';

void main() {
  /// Requirement: doc/specs/content-spells.md FR-009, FR-010, FR-011 - the SpellLevel
  ///   boundaries
  ///   and tryCreate agreement (SRD 5.2.1, "Spell Level", p. 104).
  /// Path: unhappy (boundary)
  group('SpellLevel', () {
    const cases = [
      (
        label: 'one below minimum',
        input: -1,
        accepted: false,
        isCantrip: false,
        requirement:
            'doc/specs/content-spells.md FR-009 - SpellLevel rejects '
            '-1 with ArgumentError (SRD 5.2.1, "Spell Level", p. 104)',
        path: 'unhappy (boundary)',
      ),
      (
        label: 'minimum',
        input: 0,
        accepted: true,
        isCantrip: true,
        requirement:
            'doc/specs/content-spells.md FR-009, FR-011 - level 0 is '
            'accepted and is a cantrip (SRD 5.2.1, "Spell Level", p. 104)',
        path: 'unhappy (boundary)',
      ),
      (
        label: 'first level 1+',
        input: 1,
        accepted: true,
        isCantrip: false,
        requirement:
            'doc/specs/content-spells.md FR-011 - level 1 is not a '
            'cantrip (SRD 5.2.1, "Spell Level", p. 104)',
        path: 'unhappy (boundary)',
      ),
      (
        label: 'maximum',
        input: 9,
        accepted: true,
        isCantrip: false,
        requirement:
            'doc/specs/content-spells.md FR-009 - level 9 is the '
            'maximum (SRD 5.2.1, "Spell Level", p. 104)',
        path: 'unhappy (boundary)',
      ),
      (
        label: 'one above maximum',
        input: 10,
        accepted: false,
        isCantrip: false,
        requirement:
            'doc/specs/content-spells.md FR-009 - SpellLevel rejects '
            '10 with ArgumentError (SRD 5.2.1, "Spell Level", p. 104)',
        path: 'unhappy (boundary)',
      ),
    ];

    /// Requirement: per case
    /// Path: per case
    for (final c in cases) {
      test(
        '${c.label} ${c.accepted ? 'is accepted' : 'throws'} [${c.path}]',
        () {
          if (c.accepted) {
            final level = SpellLevel(c.input);
            expect(level.level, c.input);
            expect(level.isCantrip, c.isCantrip);
          } else {
            expect(
              () => SpellLevel(c.input),
              throwsArgumentErrorFor('level', c.input),
            );
          }
        },
      );
    }

    /// Requirement: doc/specs/content-spells.md FR-010 - tryCreate returns a
    ///   SpellLevelParse carrying the level for 0 to 9 and the rejected
    ///   integer otherwise, without throwing (architecture.md §6).
    /// Path: unhappy (invalid input)
    test('tryCreate agrees with the constructor on both sides', () {
      expect(SpellLevel.tryCreate(0), SpellLevelParsed(SpellLevel(0)));
      expect(SpellLevel.tryCreate(9), SpellLevelParsed(SpellLevel(9)));
      expect(SpellLevel.tryCreate(-1), const SpellLevelRejected(-1));
      expect(SpellLevel.tryCreate(10), const SpellLevelRejected(10));
    });

    /// Requirement: doc/specs/content-spells.md FR-011, FR-111 - isValid is
    ///   the predicate the decoder reuses (SRD 5.2.1, p. 104).
    /// Path: happy
    test('isValid accepts 0 to 9 and rejects outside', () {
      expect(SpellLevel.isValid(0), isTrue);
      expect(SpellLevel.isValid(9), isTrue);
      expect(SpellLevel.isValid(-1), isFalse);
      expect(SpellLevel.isValid(10), isFalse);
    });

    /// Requirement: doc/specs/content-spells.md FR-087 - equal levels are
    ///   equal value objects (architecture.md §3).
    /// Path: happy
    test('equal levels are equal with equal hash codes', () {
      expect(SpellLevel(3), SpellLevel(3));
      expect(SpellLevel(3).hashCode, SpellLevel(3).hashCode);
      expect(SpellLevel(3) == SpellLevel(4), isFalse);
    });
  });

  /// Requirement: doc/specs/content-spells.md FR-012 - exactly the eight schools of the
  ///   Schools of Magic table (SRD 5.2.1, p. 105).
  /// Path: happy
  group('SpellSchool', () {
    /// Requirement: doc/specs/content-spells.md FR-012 - exactly the eight
    ///   schools of the Schools of Magic table and nothing else (SRD 5.2.1,
    ///   p. 105).
    /// Path: happy
    test('enumerates the eight schools in table order', () {
      expect(SpellSchool.values.map((s) => s.jsonValue), [
        'Abjuration',
        'Conjuration',
        'Divination',
        'Enchantment',
        'Evocation',
        'Illusion',
        'Necromancy',
        'Transmutation',
      ]);
    });

    /// Requirement: doc/specs/content-spells.md FR-108 - a value outside the
    ///   closed set, including wrong case, is no member (decoder
    ///   invalidValue) (SRD 5.2.1, p. 105).
    /// Path: unhappy (invalid input)
    test('fromJson rejects unknown and wrong-case spellings', () {
      expect(SpellSchool.fromJson('Evocation'), SpellSchool.evocation);
      expect(SpellSchool.fromJson('evocation'), isNull);
      expect(SpellSchool.fromJson('Lore'), isNull);
    });
  });
}
