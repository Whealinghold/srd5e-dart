import 'package:srd5e/src/content/domain/content_text_block.dart';
import 'package:srd5e/src/content/domain/spells/class_spell_list.dart';
import 'package:srd5e/src/content/domain/spells/spell.dart';
import 'package:srd5e/src/content/domain/spells/spell_casting_time.dart';
import 'package:srd5e/src/content/domain/spells/spell_components.dart';
import 'package:srd5e/src/content/domain/spells/spell_duration.dart';
import 'package:srd5e/src/content/domain/spells/spell_level.dart';
import 'package:srd5e/src/content/domain/spells/spell_range.dart';
import 'package:srd5e/src/content/domain/spells/spell_school.dart';
import 'package:srd5e/src/content/domain/typed_ids.dart';
import 'package:test/test.dart';

import '../../../support/operator_equals.dart';

Spell _spell(String id, String name, int level, Set<ClassId> classes) => Spell(
  id: SpellId(id),
  name: name,
  level: SpellLevel(level),
  school: SpellSchool.illusion,
  classes: classes,
  castingTimes: SpellCastingTimesSingle(CastingTime.magicAction()),
  ritual: false,
  range: SpellRange.self(),
  components: SpellComponents(verbal: false, somatic: false),
  duration: SpellDuration.instantaneous(),
  description: [ContentTextBlock.paragraph('Synthetic description text.')],
);

void main() {
  /// Requirement: doc/specs/content-spells.md FR-120, FR-121 - the
  ///   derivation over a synthetic spell set: non-caster and unknown
  ///   ClassId give empty groups; shuffled input gives an equal list;
  ///   ordinal order; unmodifiable groups; the input is unchanged
  ///   (SRD 5.2.1, "Class Spell Lists", p. 105).
  /// Path: happy
  test('derives ordered, unmodifiable groups over a synthetic set', () {
    final spells = [
      _spell('mage_armor', 'Mage Armor', 1, {ClassId('wizard')}),
      _spell('fire_bolt', 'Fire Bolt', 0, {
        ClassId('wizard'),
        ClassId('sorcerer'),
      }),
      _spell('light', 'Light', 0, {
        ClassId('bard'),
        ClassId('cleric'),
        ClassId('sorcerer'),
        ClassId('wizard'),
      }),
      _spell('detect_magic', 'Detect Magic', 1, {
        ClassId('bard'),
        ClassId('cleric'),
        ClassId('druid'),
        ClassId('paladin'),
        ClassId('ranger'),
        ClassId('sorcerer'),
        ClassId('warlock'),
        ClassId('wizard'),
      }),
      _spell('fireball', 'Fireball', 3, {
        ClassId('sorcerer'),
        ClassId('wizard'),
      }),
      _spell('hunters_mark', 'Hunter’s Mark', 1, {ClassId('ranger')}),
      _spell('meteor_swarm', 'Meteor Swarm', 9, {
        ClassId('sorcerer'),
        ClassId('wizard'),
      }),
      _spell('cure_wounds', 'Cure Wounds', 1, {
        ClassId('bard'),
        ClassId('cleric'),
        ClassId('druid'),
        ClassId('paladin'),
        ClassId('ranger'),
      }),
    ];
    final before = List.of(spells);

    final wizard = classSpellList(ClassId('wizard'), spells);

    expect(wizard.classId, ClassId('wizard'));
    expect(wizard.idsAt(SpellLevel(0)), hasLength(2));
    expect(wizard.idsAt(SpellLevel(0)).map((id) => id.id.value).toList(), [
      'fire_bolt',
      'light',
    ]);
    expect(wizard.idsAt(SpellLevel(1)).map((id) => id.id.value).toList(), [
      'detect_magic',
      'mage_armor',
    ]);
    expect(wizard.idsAt(SpellLevel(3)).single.id.value, 'fireball');
    expect(wizard.idsAt(SpellLevel(9)).single.id.value, 'meteor_swarm');
    expect(wizard.idsAt(SpellLevel(2)), isEmpty);
    for (var level = 0; level <= 9; level++) {
      expect(
        () => wizard.idsAt(SpellLevel(level)).add(SpellId('x')),
        throwsUnsupportedError,
      );
    }
    expect(spells, before);
  });

  /// Requirement: doc/specs/content-spells.md FR-120, FR-121 - a ClassId
  ///   listed by no spell yields empty groups, and the list for a class
  ///   held by no loaded class entry is derived the same way (a house
  ///   class).
  /// Path: happy
  test('a non-caster and a house class yield empty groups', () {
    final spells = [
      _spell('fire_bolt', 'Fire Bolt', 0, {ClassId('wizard')}),
    ];
    final noncaster = classSpellList(ClassId('barbarian'), spells);
    final house = classSpellList(ClassId('house_class'), spells);
    for (var level = 0; level <= 9; level++) {
      expect(noncaster.idsAt(SpellLevel(level)), isEmpty);
      expect(house.idsAt(SpellLevel(level)), isEmpty);
    }
    expect(noncaster, classSpellList(ClassId('barbarian'), spells));
  });

  /// Requirement: doc/specs/content-spells.md FR-121 - the ids are ordered
  ///   by string value with ordinal comparison, so the result is
  ///   deterministic and independent of input order.
  /// Path: happy
  test('shuffled input gives an equal list with ordinal ordering', () {
    final spells = [
      _spell('zeal', 'Zeal', 5, {ClassId('wizard')}),
      _spell('acid_arrow', 'Acid Arrow', 5, {ClassId('wizard')}),
      _spell('barkskin', 'Barkskin', 2, {ClassId('wizard')}),
      _spell('blink', 'Blink', 3, {ClassId('wizard')}),
      _spell('arcane_lock', 'Arcane Lock', 2, {ClassId('wizard')}),
    ];
    final forward = classSpellList(ClassId('wizard'), spells);
    final backward = classSpellList(ClassId('wizard'), spells.reversed);
    expect(backward, forward);
    final ids = forward.idsAt(SpellLevel(5)).map((id) => id.id.value);
    expect(ids.toList(), ['acid_arrow', 'zeal']);
    final level2 = forward.idsAt(SpellLevel(2)).map((id) => id.id.value);
    expect(level2.toList(), ['arcane_lock', 'barkskin']);
  });

  /// Requirement: doc/specs/content-spells.md FR-121 - the list compares by
  ///   value: another type, another class and one differing level group
  ///   each break equality.
  /// Path: happy
  test('another class or one differing group breaks equality', () {
    final spells = [
      _spell('fire_bolt', 'Fire Bolt', 0, {ClassId('wizard')}),
      _spell('fireball', 'Fireball', 3, {ClassId('wizard')}),
    ];
    final wizard = classSpellList(ClassId('wizard'), spells);
    final sorcerer = classSpellList(ClassId('sorcerer'), spells);
    final fewer = classSpellList(ClassId('wizard'), [
      _spell('fire_bolt', 'Fire Bolt', 0, {ClassId('wizard')}),
    ]);

    expect(operatorEquals(wizard, Object()), isFalse);
    expect(operatorEquals(wizard, sorcerer), isFalse);
    expect(operatorEquals(wizard, fewer), isFalse);
  });
}
