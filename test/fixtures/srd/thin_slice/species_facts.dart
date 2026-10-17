/// The thin slice's oracle for the four species: the pinned phrases and the
/// case tables T1 to T4 of doc/specs/content-thin-slice.md (section 4,
/// "Species: Dwarf" FR-009 to FR-013, "Species: Dragonborn" FR-014 to
/// FR-020, "Species: Elf" FR-021 to FR-028, "Species: Human" FR-029 to
/// FR-031, and "Tables of cases").
///
/// SRD 5.2.1 text, transcribed from the spec's tables and requirement rows
/// independently of the data files under `data/srd_5_2_1/`
/// (shared-types-and-ownership.md FR-033). Each phrase is text the cited
/// page prints and the entry's text must contain; where a requirement says
/// a trait "MUST state" a fact, the pin is the phrase (content-thin-slice.md
/// section 1, "Text pins"). Phrases avoid the typographic apostrophe by
/// splitting around contractions, never by rewording.
library;

/// One pinned trait: its printed name and the phrases its text must state.
typedef TraitPin = ({String name, List<String> phrases});

/// The core fields and trait pins of one species.
typedef SpeciesPin = ({
  String id,

  /// The printed Creature Type.
  String creatureType,

  /// The printed sizes; a set (FR-029), order not asserted.
  List<String> sizes,
  int speed,

  /// Phrases the `sizeText` must carry; empty when the spec pins none.
  List<String> sizeTextPhrases,
  List<TraitPin> traits,
});

/// The Dwarf (FR-009 to FR-013; SRD 5.2.1, "Dwarf", p. 84).
const SpeciesPin dwarf = (
  id: 'dwarf',
  creatureType: 'Humanoid',
  sizes: ['Medium'],
  speed: 30,
  sizeTextPhrases: [],
  traits: [
    (
      name: 'Darkvision',

      /// FR-010: the Darkvision text states a range of 120 feet.
      phrases: ['range of 120 feet'],
    ),
    (
      name: 'Dwarven Resilience',

      /// FR-011: Resistance to Poison damage; Advantage on saving throws to
      /// avoid or end the Poisoned condition.
      phrases: [
        'Resistance to Poison damage',
        'Advantage on saving throws',
        'avoid or end the Poisoned condition',
      ],
    ),
    (
      name: 'Dwarven Toughness',

      /// FR-012: a Hit Point maximum increase of 1, and a further increase
      /// of 1 for each level gained.
      phrases: [
        'Hit Point maximum increases by 1',
        'whenever you gain a level',
      ],
    ),
    (
      name: 'Stonecunning',

      /// FR-013: Bonus Action; Tremorsense range 60 feet; duration 10
      /// minutes; uses equal to Proficiency Bonus; expended uses regained
      /// on a Long Rest; works only on or touching a stone surface,
      /// natural or worked.
      phrases: [
        'Bonus Action',
        'Tremorsense with a range of 60 feet',
        'for 10 minutes',
        'a number of times equal to your Proficiency Bonus',
        'regain all expended uses when you finish a Long Rest',
        'stone surface',
        'natural or worked',
      ],
    ),
  ],
);

/// The Dragonborn (FR-014 to FR-020; SRD 5.2.1, "Dragonborn", p. 84). The
/// Breath Weapon phrases cover FR-016 and FR-018; FR-017's damage rows are
/// [breathWeaponDamage] (T2).
const SpeciesPin dragonborn = (
  id: 'dragonborn',
  creatureType: 'Humanoid',
  sizes: ['Medium'],
  speed: 30,
  sizeTextPhrases: [],
  traits: [
    (
      name: 'Draconic Ancestry',
      phrases: ['Choose the kind of dragon from the Draconic Ancestors table'],
    ),
    (
      name: 'Breath Weapon',

      /// FR-016: Attack action, replacing one attack; a 15-foot Cone or a
      /// 30-foot Line 5 feet wide, chosen each use; a Dexterity saving
      /// throw, DC 8 plus Constitution modifier plus Proficiency Bonus;
      /// damage of the chosen type on a failed save, half on a success.
      /// FR-018: uses equal to Proficiency Bonus, regained on a Long Rest.
      phrases: [
        'Attack action',
        'replace one of your attacks',
        '15-foot Cone',
        '30-foot Line',
        '5 feet wide',
        'Dexterity saving throw',
        'DC 8 plus your Constitution modifier',
        'Proficiency Bonus',
        'half as much damage',
        'damage of the type determined by your Draconic Ancestry trait',
        'a number of times equal to your Proficiency Bonus',
        'regain all expended uses when you finish a Long Rest',
      ],
    ),
    (
      name: 'Damage Resistance',

      /// FR-019: Resistance to the chosen damage type, and no fixed type.
      phrases: [
        'Resistance to the damage type determined by your Draconic Ancestry trait',
      ],
    ),
    (
      name: 'Darkvision',

      /// FR-014: a range of 60 feet.
      phrases: ['range of 60 feet'],
    ),
    (
      name: 'Draconic Flight',

      /// FR-020: from character level 5; Bonus Action; 10 minutes or until
      /// retracted or Incapacitated; Fly Speed equal to Speed; once per
      /// Long Rest.
      phrases: [
        'character level 5',
        'Bonus Action',
        '10 minutes',
        'Incapacitated',
        'Fly Speed equal to your Speed',
        'until you finish a Long Rest',
      ],
    ),
  ],
);

/// The Elf (FR-021 to FR-028; SRD 5.2.1, "Elf", pp. 84-85). The Elven
/// Lineage phrases are FR-024's grant semantics, stated in the trait text
/// and held as no structured data.
const SpeciesPin elf = (
  id: 'elf',
  creatureType: 'Humanoid',
  sizes: ['Medium'],
  speed: 30,
  sizeTextPhrases: [],
  traits: [
    (
      name: 'Darkvision',

      /// FR-022: a range of 60 feet.
      phrases: ['range of 60 feet'],
    ),
    (
      name: 'Elven Lineage',

      /// FR-024: the lineage spell is always prepared; castable once
      /// without a slot; the free cast regained on a Long Rest; also
      /// castable with a slot; Intelligence, Wisdom or Charisma as the
      /// spellcasting ability.
      phrases: [
        'always have that spell prepared',
        'cast it once without a spell slot',
        'regain the ability to cast it',
        'finish a Long Rest',
        'using any spell slots',
        'Intelligence, Wisdom, or Charisma is your spellcasting ability',
      ],
    ),
    (
      name: 'Fey Ancestry',

      /// FR-026: Advantage on saving throws to avoid or end the Charmed
      /// condition.
      phrases: [
        'Advantage on saving throws',
        'avoid or end the Charmed condition',
      ],
    ),
    (
      name: 'Keen Senses',

      /// FR-027: proficiency in one skill chosen from Insight, Perception
      /// or Survival.
      phrases: ['proficiency in the Insight, Perception, or Survival skill'],
    ),
    (
      name: 'Trance',

      /// FR-028: no need to sleep; magic cannot put the Elf to sleep; a
      /// Long Rest can be finished in 4 hours.
      phrases: ['need to sleep', 'put you to sleep', 'Long Rest in 4 hours'],
    ),
  ],
);

/// The Human (FR-029 to FR-031; SRD 5.2.1, "Human", p. 86).
const SpeciesPin human = (
  id: 'human',
  creatureType: 'Humanoid',
  sizes: ['Medium', 'Small'],
  speed: 30,

  /// FR-029: the printed heights for Medium and Small, and that the size
  /// is chosen when the species is selected.
  sizeTextPhrases: [
    '4–7 feet tall',
    '2–4 feet tall',
    'chosen when you select this species',
  ],
  traits: [
    (
      name: 'Resourceful',

      /// FR-030: Heroic Inspiration whenever a Long Rest is finished.
      phrases: ['Heroic Inspiration', 'finish a Long Rest'],
    ),
    (
      name: 'Skillful',

      /// FR-030: proficiency in one skill of the player's choice.
      phrases: ['proficiency in one skill of your choice'],
    ),
    (
      name: 'Versatile',

      /// FR-030: an Origin feat of the player's choice, Skilled
      /// recommended.
      phrases: ['Origin feat of your choice', 'Skilled'],
    ),
  ],
);

/// The four species pins, by id.
const Map<String, SpeciesPin> speciesPins = {
  'dwarf': dwarf,
  'dragonborn': dragonborn,
  'elf': elf,
  'human': human,
};

/// **T1. Draconic Ancestors** (FR-015; SRD 5.2.1, "Draconic Ancestors",
/// p. 84): each option's printed name and damage type, in table order.
const List<({String label, String dragon, String damageType})>
draconicAncestors = [
  (label: 'black', dragon: 'Black', damageType: 'Acid'),
  (label: 'blue', dragon: 'Blue', damageType: 'Lightning'),
  (label: 'brass', dragon: 'Brass', damageType: 'Fire'),
  (label: 'bronze', dragon: 'Bronze', damageType: 'Lightning'),
  (label: 'copper', dragon: 'Copper', damageType: 'Acid'),
  (label: 'gold', dragon: 'Gold', damageType: 'Fire'),
  (label: 'green', dragon: 'Green', damageType: 'Poison'),
  (label: 'red', dragon: 'Red', damageType: 'Fire'),
  (label: 'silver', dragon: 'Silver', damageType: 'Cold'),
  (label: 'white', dragon: 'White', damageType: 'Cold'),
];

/// **T2. Breath Weapon damage by character level** (FR-017; SRD 5.2.1,
/// "Dragonborn", p. 84): the base damage and the printed form of each
/// upgrade threshold. The thresholds stay in the text
/// (content-species-backgrounds-feats.md Q16).
const List<({String label, int level, String phrase})> breathWeaponDamage = [
  (label: 'base', level: 1, phrase: '1d10 damage'),
  (label: 'first upgrade', level: 5, phrase: '5 (2d10)'),
  (label: 'second upgrade', level: 11, phrase: '11 (3d10)'),
  (label: 'third upgrade', level: 17, phrase: '17 (4d10)'),
];

/// The one printed sentence carrying every threshold of T2 above level 1:
/// the count row ("exactly three upgrades") pins it whole.
const String breathWeaponUpgradesSentence =
    'character levels 5 (2d10), 11 (3d10), and 17 (4d10)';

/// **T3. Elven Lineages** (FR-023, FR-063; SRD 5.2.1, "Elven Lineages",
/// p. 85): each lineage's Level 1 phrases (the printed Level 1 benefit)
/// and the spells of its levels 1, 3 and 5, as entry ids. All nine spells
/// are bundled (T6).
const List<
  ({
    String label,
    String lineage,
    List<String> level1Phrases,
    String level1SpellId,
    String level3SpellId,
    String level5SpellId,
  })
>
elvenLineages = [
  (
    label: 'drow',
    lineage: 'Drow',
    level1Phrases: ['Darkvision increases to 120 feet', 'Dancing Lights'],
    level1SpellId: 'dancing_lights',
    level3SpellId: 'faerie_fire',
    level5SpellId: 'darkness',
  ),
  (
    label: 'high elf',
    lineage: 'High Elf',
    level1Phrases: [
      'Prestidigitation',
      'replace that cantrip with a different cantrip from the Wizard spell list',
    ],
    level1SpellId: 'prestidigitation',
    level3SpellId: 'detect_magic',
    level5SpellId: 'misty_step',
  ),
  (
    label: 'wood elf',
    lineage: 'Wood Elf',
    level1Phrases: ['Speed increases to 35 feet', 'Druidcraft'],
    level1SpellId: 'druidcraft',
    level3SpellId: 'longstrider',
    level5SpellId: 'pass_without_trace',
  ),
];

/// **T4. Choices in the species** (FR-032; SRD 5.2.1, pp. 84-86): every
/// selection the species traits offer, what the SRD prints for it, and
/// where the data holds it. `heldAs` is one of `choices` (the SX-1
/// structured element), `trait text`, `option text` and `sizes`.
const List<
  ({
    String label,
    String speciesId,
    String ownerTraitName,
    String heldAs,
    List<String> facts,
  })
>
choicesInTheSpecies = [
  (
    label: 'draconic ancestry',
    speciesId: 'dragonborn',
    ownerTraitName: 'Draconic Ancestry',
    heldAs: 'choices',
    facts: [],
  ),
  (
    label: 'breath weapon shape',
    speciesId: 'dragonborn',
    ownerTraitName: 'Breath Weapon',
    heldAs: 'trait text',
    facts: ['15-foot Cone', '30-foot Line', '5 feet wide'],
  ),
  (
    label: 'elven lineage',
    speciesId: 'elf',
    ownerTraitName: 'Elven Lineage',
    heldAs: 'choices',
    facts: [],
  ),
  (
    label: 'lineage spellcasting ability',
    speciesId: 'elf',
    ownerTraitName: 'Elven Lineage',
    heldAs: 'trait text',
    facts: ['Intelligence, Wisdom, or Charisma'],
  ),
  (
    label: 'keen senses skill',
    speciesId: 'elf',
    ownerTraitName: 'Keen Senses',
    heldAs: 'trait text',
    facts: ['Insight, Perception, or Survival'],
  ),
  (
    label: 'high elf cantrip replacement',
    speciesId: 'elf',
    ownerTraitName: 'Elven Lineage',
    heldAs: 'option text',
    facts: [
      'replace that cantrip with a different cantrip from the Wizard spell list',
    ],
  ),
  (
    label: 'human size',
    speciesId: 'human',
    ownerTraitName: '',
    heldAs: 'sizes',
    facts: ['Medium', 'Small'],
  ),
  (
    label: 'skillful skill',
    speciesId: 'human',
    ownerTraitName: 'Skillful',
    heldAs: 'trait text',
    facts: ['one skill of your choice'],
  ),
  (
    label: 'versatile feat',
    speciesId: 'human',
    ownerTraitName: 'Versatile',
    heldAs: 'trait text',
    facts: ['Origin feat of your choice'],
  ),
];

/// The stone-surface condition of FR-013, pinned separately: a copy of the
/// Stonecunning text without it must fail. The strings are also held in the
/// Dwarf's Stonecunning phrases above, so the full-phrase check fails a
/// copy without them too.
const List<String> stonecunningSurfaceCondition = [
  'stone surface',
  'natural or worked',
];

/// The printed damage types: the fixed types FR-019 forbids in the Damage
/// Resistance text (SRD 5.2.1, "Damage Types", p. 180).
const List<String> damageTypes = [
  'Acid',
  'Bludgeoning',
  'Cold',
  'Fire',
  'Force',
  'Lightning',
  'Necrotic',
  'Piercing',
  'Poison',
  'Psychic',
  'Radiant',
  'Slashing',
  'Thunder',
];
