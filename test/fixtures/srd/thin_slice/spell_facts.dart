/// The thin slice's oracle for the twelve spells: the spell-header table T6,
/// the scaling table T7 and the effect phrases of doc/specs/content-thin-slice.md
/// (section 4, "Spells" FR-048 to FR-061 and FR-083, and "Tables of cases").
///
/// SRD 5.2.1 text, transcribed from the spec's tables and requirement rows
/// independently of the data files under `data/srd_5_2_1/`
/// (shared-types-and-ownership.md FR-033). The T6 columns hold the printed
/// header values; the phrase lists are text the cited page prints and the
/// spell's description must contain.
library;

/// One T6 spell-header row (FR-048, FR-061). The class list is a set; the
/// printed order is not significant. `castingTime` is the printed Casting
/// Time entry, including "or Ritual" where the spell has the Ritual tag.
typedef SpellHeaderRow = ({
  String label,
  String id,

  /// The printed heading, exactly as the "Spell Descriptions" page prints
  /// it (content-spells.md FR-006).
  String name,
  int level,
  String school,
  List<String> classes,
  String castingTime,
  String range,
  String components,
  String duration,
});

/// **T6. Spell headers** (FR-048, FR-061; SRD 5.2.1, "Spell Descriptions").
/// (T5 was the Wizard Features table, moved to content-classes.md with
/// FR-038.)
const List<SpellHeaderRow> spellHeaders = [
  (
    label: 'fire bolt',
    id: 'fire_bolt',
    name: 'Fire Bolt',
    level: 0,
    school: 'Evocation',
    classes: ['Sorcerer', 'Wizard'],
    castingTime: 'Action',
    range: '120 feet',
    components: 'V, S',
    duration: 'Instantaneous',
  ),
  (
    label: 'prestidigitation',
    id: 'prestidigitation',
    name: 'Prestidigitation',
    level: 0,
    school: 'Transmutation',
    classes: ['Bard', 'Sorcerer', 'Warlock', 'Wizard'],
    castingTime: 'Action',
    range: '10 feet',
    components: 'V, S',
    duration: 'Up to 1 hour',
  ),
  (
    label: 'detect magic',
    id: 'detect_magic',
    name: 'Detect Magic',
    level: 1,
    school: 'Divination',
    classes: [
      'Bard',
      'Cleric',
      'Druid',
      'Paladin',
      'Ranger',
      'Sorcerer',
      'Warlock',
      'Wizard',
    ],
    castingTime: 'Action or Ritual',
    range: 'Self',
    components: 'V, S',
    duration: 'Concentration, up to 10 minutes',
  ),
  (
    label: 'magic missile',
    id: 'magic_missile',
    name: 'Magic Missile',
    level: 1,
    school: 'Evocation',
    classes: ['Sorcerer', 'Wizard'],
    castingTime: 'Action',
    range: '120 feet',
    components: 'V, S',
    duration: 'Instantaneous',
  ),
  (
    label: 'misty step',
    id: 'misty_step',
    name: 'Misty Step',
    level: 2,
    school: 'Conjuration',
    classes: ['Sorcerer', 'Warlock', 'Wizard'],
    castingTime: 'Bonus Action',
    range: 'Self',
    components: 'V',
    duration: 'Instantaneous',
  ),
  (
    label: 'fireball',
    id: 'fireball',
    name: 'Fireball',
    level: 3,
    school: 'Evocation',
    classes: ['Sorcerer', 'Wizard'],
    castingTime: 'Action',
    range: '150 feet',
    components: 'V, S, M (a ball of bat guano and sulfur)',
    duration: 'Instantaneous',
  ),
  (
    label: 'dancing lights',
    id: 'dancing_lights',
    name: 'Dancing Lights',
    level: 0,
    school: 'Illusion',
    classes: ['Bard', 'Sorcerer', 'Wizard'],
    castingTime: 'Action',
    range: '120 feet',
    components: 'V, S, M (a bit of phosphorus)',
    duration: 'Concentration, up to 1 minute',
  ),
  (
    label: 'darkness',
    id: 'darkness',
    name: 'Darkness',
    level: 2,
    school: 'Evocation',
    classes: ['Sorcerer', 'Warlock', 'Wizard'],
    castingTime: 'Action',
    range: '60 feet',
    components: 'V, M (bat fur and a piece of coal)',
    duration: 'Concentration, up to 10 minutes',
  ),
  (
    label: 'druidcraft',
    id: 'druidcraft',
    name: 'Druidcraft',
    level: 0,
    school: 'Transmutation',
    classes: ['Druid'],
    castingTime: 'Action',
    range: '30 feet',
    components: 'V, S',
    duration: 'Instantaneous',
  ),
  (
    label: 'faerie fire',
    id: 'faerie_fire',
    name: 'Faerie Fire',
    level: 1,
    school: 'Evocation',
    classes: ['Bard', 'Druid'],
    castingTime: 'Action',
    range: '60 feet',
    components: 'V',
    duration: 'Concentration, up to 1 minute',
  ),
  (
    label: 'longstrider',
    id: 'longstrider',
    name: 'Longstrider',
    level: 1,
    school: 'Transmutation',
    classes: ['Bard', 'Druid', 'Ranger', 'Wizard'],
    castingTime: 'Action',
    range: 'Touch',
    components: 'V, S, M (a pinch of dirt)',
    duration: '1 hour',
  ),
  (
    label: 'pass without trace',
    id: 'pass_without_trace',
    name: 'Pass without Trace',
    level: 2,
    school: 'Abjuration',
    classes: ['Druid', 'Ranger'],
    castingTime: 'Action',
    range: 'Self',
    components: 'V, S, M (ashes from burned mistletoe)',
    duration: 'Concentration, up to 1 hour',
  ),
];

/// **T7. Spell scaling** (FR-060): the data holds the text form only —
/// `cantripUpgrade`, `higherLevel` or neither. The Mechanism column of the
/// spec's table is for the test author and is not pinned here.
const List<({String label, List<String> ids, String scaling})> spellScaling = [
  (label: 'fire bolt upgrade', ids: ['fire_bolt'], scaling: 'cantripUpgrade'),
  (
    label: 'fire bolt thresholds match breath weapon',
    ids: ['fire_bolt'],
    scaling: 'cantripUpgrade',
  ),
  (label: 'magic missile slot', ids: ['magic_missile'], scaling: 'higherLevel'),
  (label: 'fireball slot', ids: ['fireball'], scaling: 'higherLevel'),
  (label: 'detect magic none', ids: ['detect_magic'], scaling: 'none'),
  (label: 'misty step none', ids: ['misty_step'], scaling: 'none'),
  (label: 'prestidigitation none', ids: ['prestidigitation'], scaling: 'none'),
  (label: 'longstrider slot', ids: ['longstrider'], scaling: 'higherLevel'),
  (
    label: 'lineage spells none',
    ids: [
      'dancing_lights',
      'darkness',
      'druidcraft',
      'faerie_fire',
      'pass_without_trace',
    ],
    scaling: 'none',
  ),
];

/// The Ritual tag is the flag beside the Casting Time (FR-050; SRD 5.2.1,
/// "Casting without Slots", p. 104): Detect Magic has the single Magic
/// action and ritual true, Fire Bolt the Magic action and ritual false,
/// Misty Step the Bonus Action and ritual false. Rows: (id, ritual).
const List<({String id, bool ritual})> ritualTags = [
  (id: 'detect_magic', ritual: true),
  (id: 'fire_bolt', ritual: false),
  (id: 'misty_step', ritual: false),
];

/// The Material component text of the five slice spells that have one
/// (FR-052; SRD 5.2.1, "Components", pp. 105-106). The T6 components
/// column carries the same text in its printed "V, S, M (...)" form; this
/// is the component data the decoder must carry beside the flags.
const Map<String, String> materialComponents = {
  'fireball': 'a ball of bat guano and sulfur',
  'dancing_lights': 'a bit of phosphorus',
  'darkness': 'bat fur and a piece of coal',
  'longstrider': 'a pinch of dirt',
  'pass_without_trace': 'ashes from burned mistletoe',
};

/// The printed Fire Bolt upgrade sentence of T7 (SRD 5.2.1, "Fire Bolt",
/// p. 132). Its thresholds equal T2's: the test cross-checks it against the
/// breathWeaponDamage rows of species_facts.dart.
const String fireBoltUpgradeSentence =
    'levels 5 (2d10), 11 (3d10), and 17 (4d10)';

/// The printed run-in effects of the two spells whose descriptions name
/// them (FR-059, FR-083): Prestidigitation's six effects and Druidcraft's
/// four. The set is pinned; the printed order is not.
const Map<String, List<String>> namedEffects = {
  'prestidigitation': [
    'Sensory Effect',
    'Fire Play',
    'Clean or Soil',
    'Minor Sensation',
    'Magic Mark',
    'Minor Creation',
  ],
  'druidcraft': ['Weather Sensor', 'Bloom', 'Sensory Effect', 'Fire Play'],
};

/// The effect phrases per spell: what each description must state
/// (FR-054 to FR-058, FR-083, and the limit of FR-059). Phrases avoid the
/// typographic apostrophe by splitting around contractions.
const Map<String, List<String>> effectPhrases = {
  'fire_bolt': [
    /// FR-054: a ranged spell attack; on a hit 1d10 Fire damage; a
    /// flammable object hit and not worn or carried starts burning.
    'ranged spell attack',
    '1d10 Fire damage',
    'starts burning',
  ],
  'magic_missile': [
    /// FR-055: three darts, each striking a creature of the caster's
    /// choice that can be seen within range, each dealing 1d4 + 1 Force
    /// damage, all striking simultaneously.
    'three glowing darts',
    'creature of your choice that you can see within range',
    '1d4 + 1 Force damage',
    'strike simultaneously',
  ],
  'fireball': [
    /// FR-056: a 20-foot-radius Sphere centred on a point within range; a
    /// Dexterity saving throw; 8d6 Fire damage on a failed save and half
    /// as much on a success; flammable objects in the area not worn or
    /// carried start burning.
    '20-foot-radius Sphere',
    'Dexterity saving throw',
    '8d6 Fire damage on a failed save',
    'half as much damage on a successful one',
    'Flammable objects in the area',
    'start burning',
  ],
  'misty_step': [
    /// FR-057: teleport up to 30 feet to an unoccupied space the caster
    /// can see. The SRD states the teleport in one sentence; "no attack
    /// roll, saving throw or damage" is the spec's rule reading of it,
    /// not printed text, so only the printed sentence is pinned.
    'teleport up to 30 feet to an unoccupied space you can see',
  ],
  'detect_magic': [
    /// FR-058: for the duration, sense magical effects within 30 feet; the
    /// Magic action reveals a faint aura and the school of a
    /// spell-created effect; blocked by 1 foot of stone, dirt or wood,
    /// 1 inch of metal or a thin sheet of lead.
    'sense the presence of magical effects within 30 feet',
    'Magic action',
    'faint aura',
    'school of magic',
    'blocked by 1 foot of stone, dirt, or wood',
    '1 inch of metal',
    'thin sheet of lead',
  ],
  'prestidigitation': [
    /// FR-059: the limit of three non-instantaneous effects active at a
    /// time. The six named effects are [namedEffects].
    'three of its non-instantaneous effects active at a time',
  ],
  'dancing_lights': [
    /// FR-083: up to four torch-size lights shedding Dim Light in a
    /// 10-foot radius; combinable into one Medium humanlike form; a Bonus
    /// Action to move them up to 60 feet.
    'up to four torch-size lights',
    'Dim Light in a 10-foot radius',
    'one glowing Medium form',
    'humanlike',
    'Bonus Action',
    'move the lights up to 60 feet',
  ],
  'darkness': [
    /// FR-083: magical Darkness filling a 15-foot-radius Sphere that
    /// Darkvision cannot see through; or a 15-foot Emanation on an
    /// object; dispelling an overlapping Bright Light or Dim Light of a
    /// spell of level 2 or lower. The phrases split around the printed
    /// "can't".
    'magical Darkness',
    '15-foot-radius Sphere',
    'Darkvision can',
    'see through it',
    '15-foot Emanation',
    'level 2 or lower',
    'dispelled',
  ],
  'faerie_fire': [
    /// FR-083: a 20-foot Cube, outlined in blue, green or violet light; a
    /// Dexterity saving throw; Advantage on attack rolls against an
    /// affected creature or object the attacker can see.
    '20-foot Cube',
    'blue, green, or violet',
    'Dexterity saving throw',
    'Attack rolls against an affected creature or object',
    'Advantage',
  ],
  'longstrider': [
    /// FR-083: a touched creature's Speed increases by 10 feet.
    'Speed increases by 10 feet',
  ],
  'pass_without_trace': [
    /// FR-083: a 30-foot Emanation; a +10 bonus to Dexterity (Stealth)
    /// checks; no tracks left.
    '30-foot Emanation',
    '+10 bonus to Dexterity (Stealth) checks',
    'leave no tracks',
  ],
};
