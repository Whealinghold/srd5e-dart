/// The thin slice's oracle: the entry-citation table
/// (doc/specs/content-thin-slice.md section 2, "Entry citations", FR-007).
///
/// SRD 5.2.1 text, transcribed from the spec's table independently of the
/// data files under `data/srd_5_2_1/` (shared-types-and-ownership.md
/// FR-033 puts SRD text here and nowhere else in `test/`). The envelope's
/// `source` is `{document, section, page}` with one integer page: the first
/// printed page of the entry.
library;

/// The document every slice entry cites (FR-007).
const String document = 'SRD 5.2.1';

/// The `section` and `page` of every entry id of the slice, in the spec's
/// table order (FR-007). `wizard` uses the class's first page.
const Map<String, ({String section, int page})> citations = {
  'dragonborn': (section: 'Dragonborn', page: 84),
  'dwarf': (section: 'Dwarf', page: 84),
  'elf': (section: 'Elf', page: 84),
  'human': (section: 'Human', page: 86),
  'wizard': (section: 'Wizard', page: 77),
  'dancing_lights': (section: 'Spell Descriptions', page: 121),
  'darkness': (section: 'Spell Descriptions', page: 122),
  'detect_magic': (section: 'Spell Descriptions', page: 123),
  'druidcraft': (section: 'Spell Descriptions', page: 126),
  'faerie_fire': (section: 'Spell Descriptions', page: 129),
  'fireball': (section: 'Spell Descriptions', page: 131),
  'fire_bolt': (section: 'Spell Descriptions', page: 132),
  'longstrider': (section: 'Spell Descriptions', page: 145),
  'magic_missile': (section: 'Spell Descriptions', page: 146),
  'misty_step': (section: 'Spell Descriptions', page: 150),
  'pass_without_trace': (section: 'Spell Descriptions', page: 151),
  'prestidigitation': (section: 'Spell Descriptions', page: 154),
};

/// Every entry id of the slice (content-thin-slice.md section 4, the id
/// list under "Requirements"): the seventeen entries of FR-001 to FR-003.
const List<String> entryIds = [
  'dragonborn',
  'dwarf',
  'elf',
  'human',
  'wizard',
  'fire_bolt',
  'prestidigitation',
  'detect_magic',
  'magic_missile',
  'misty_step',
  'fireball',
  'dancing_lights',
  'darkness',
  'druidcraft',
  'faerie_fire',
  'longstrider',
  'pass_without_trace',
];

/// The four species ids of FR-001, in the spec's order.
const List<String> speciesIds = ['dragonborn', 'dwarf', 'elf', 'human'];

/// The twelve spell ids of FR-003, in the spec's order.
const List<String> spellIds = [
  'fire_bolt',
  'prestidigitation',
  'detect_magic',
  'magic_missile',
  'misty_step',
  'fireball',
  'dancing_lights',
  'darkness',
  'druidcraft',
  'faerie_fire',
  'longstrider',
  'pass_without_trace',
];
