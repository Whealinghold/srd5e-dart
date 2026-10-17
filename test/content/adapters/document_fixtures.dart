import 'dart:convert' show jsonEncode;

/// Synthetic entry fixtures for the decoder tests. Every value is invented
/// shape data, not SRD content: the fixtures exercise the envelope and the
/// field rules, never the bundled data (the schema spec's test plan,
/// "Fixtures are small synthetic entries").
///
/// Each builder returns the entry with every required field present and
/// valid; a test removes keys with [without] and overrides them with
/// [instead], so each row shows its one change.

/// A minimal valid species entry (content-species-backgrounds-feats.md §5).
Map<String, Object?> speciesEntry({
  String id = 'elf',
  String name = 'Elf',
  Set<String> without = const {},
  Map<String, Object?> instead = const {},
}) {
  final entry = <String, Object?>{
    'id': id,
    'name': name,
    'creatureType': 'Humanoid',
    'sizes': <String>['Medium'],
    'speed': 30,
    'traits': <Object?>[
      {'name': 'Keen Senses', 'text': 'You gain proficiency in Perception.'},
      {'name': 'Fey Ancestry', 'text': 'You have Advantage on saves.'},
    ],
  };
  for (final key in without) {
    entry.remove(key);
  }
  return entry..addAll(instead);
}

/// A minimal valid background entry.
Map<String, Object?> backgroundEntry({
  String id = 'soldier',
  String name = 'Soldier',
  Set<String> without = const {},
  Map<String, Object?> instead = const {},
}) {
  final entry = <String, Object?>{
    'id': id,
    'name': name,
    'abilityScores': <String>['Strength', 'Dexterity', 'Constitution'],
    'feat': {'featId': 'savage_attacker'},
    'skillProficiencies': <String>['Athletics', 'Intimidation'],
    'toolProficiency': {'kind': 'choice', 'category': 'Gaming Set'},
    'equipmentOptions': {
      'A': {
        'items': <Object?>[
          {'name': 'Spear', 'quantity': 1},
        ],
        'gold': 14,
      },
      'B': {'items': <Object?>[], 'gold': 50},
    },
  };
  for (final key in without) {
    entry.remove(key);
  }
  return entry..addAll(instead);
}

/// A minimal valid feat entry.
Map<String, Object?> featEntry({
  String id = 'alert',
  String name = 'Alert',
  Set<String> without = const {},
  Map<String, Object?> instead = const {},
}) {
  final entry = <String, Object?>{
    'id': id,
    'name': name,
    'category': 'Origin',
    'benefits': <Object?>[
      {'name': 'Initiative Proficiency', 'text': 'Add PB to Initiative.'},
    ],
    'repeatable': false,
  };
  for (final key in without) {
    entry.remove(key);
  }
  return entry..addAll(instead);
}

/// A minimal valid weapon entry (content-equipment.md FR-106).
Map<String, Object?> weaponEntry({
  String id = 'longsword',
  String name = 'Longsword',
  Set<String> without = const {},
  Map<String, Object?> instead = const {},
}) {
  final entry = <String, Object?>{
    'id': id,
    'name': name,
    'category': 'Martial',
    'weaponType': 'Melee',
    'damage': {'dice': '1d8'},
    'damageType': 'Slashing',
    'properties': <Object?>[
      {'property': 'Versatile', 'damage': '1d10'},
    ],
    'mastery': 'Sap',
    'weightPounds': 3,
    'cost': {'amount': 15, 'coin': 'GP'},
  };
  for (final key in without) {
    entry.remove(key);
  }
  return entry..addAll(instead);
}

/// A minimal valid armor entry (content-equipment.md FR-105).
Map<String, Object?> armorEntry({
  String id = 'plate',
  String name = 'Plate',
  Set<String> without = const {},
  Map<String, Object?> instead = const {},
}) {
  final entry = <String, Object?>{
    'id': id,
    'name': name,
    'category': 'Heavy',
    'armorClass': {'base': 18, 'dexterity': 'none'},
    'stealthDisadvantage': true,
    'weightPounds': 65,
    'cost': {'amount': 1500, 'coin': 'GP'},
  };
  for (final key in without) {
    entry.remove(key);
  }
  return entry..addAll(instead);
}

/// A document over the given arrays, with `schemaVersion` 1 unless
/// [version] says otherwise (pass `null` to omit the key entirely, a raw
/// string for a non-JSON-number version).
String document({
  Object? version = 1,
  Map<String, List<Object?>> arrays = const <String, List<Object?>>{},
  Map<String, Object?> extra = const <String, Object?>{},
}) {
  final root = <String, Object?>{
    'schemaVersion': ?version,
    ...arrays,
    ...extra,
  };
  return jsonEncode(root);
}

/// A one-entry document of [array].
String documentOf(String array, Map<String, Object?> entry) => document(
  arrays: <String, List<Object?>>{
    array: <Object?>[entry],
  },
);

/// The Proficiency Bonus of the Features tables: +2 at levels 1 to 4, +3 at
/// 5 to 8, +4 at 9 to 12, +5 at 13 to 16 and +6 at 17 to 20 (FR-038 of
/// content-classes.md; SRD 5.2.1, "Proficiency Bonus", p. 8).
int fixtureProficiencyBonus(int level) {
  if (level <= 4) return 2;
  if (level <= 8) return 3;
  if (level <= 12) return 4;
  if (level <= 16) return 5;
  return 6;
}

/// A minimal valid class entry (content-classes.md FR-002), shaped like the
/// domain tests' Barbarian fixture: three feature entries, the subclass
/// marker at level 3 and no columns or subclasses. Every value is synthetic
/// shape data.
Map<String, Object?> classEntry({
  String id = 'barbarian',
  String name = 'Barbarian',
  Set<String> without = const {},
  Map<String, Object?> instead = const {},
}) {
  final prefix = '${id}_';
  final entry = <String, Object?>{
    'id': id,
    'name': name,
    'primaryAbility': <String, Object?>{
      'kind': 'allOf',
      'abilities': <String>['Strength'],
    },
    'hitPointDie': 'D12',
    'savingThrowProficiencies': <String>['Strength', 'Constitution'],
    'skillChoice': <String, Object?>{
      'picks': 2,
      'options': <String, Object?>{
        'kind': 'listed',
        'skills': <String>[
          'Animal Handling',
          'Athletics',
          'Intimidation',
          'Nature',
          'Perception',
          'Survival',
        ],
      },
    },
    'weaponProficiencies': <Object?>[
      {'category': 'Simple'},
      {'category': 'Martial'},
    ],
    'toolProficiencies': <Object?>[],
    'armorTraining': <Object?>[],
    'startingEquipment': <String, Object?>{
      'A': <String, Object?>{
        'items': <Object?>[
          {'name': 'Greataxe', 'quantity': 1},
        ],
        'gold': 0,
      },
      'B': {'items': <Object?>[], 'gold': 50},
    },
    'multiclassGrants': <String, Object?>{
      'weaponProficiencies': <Object?>[],
      'armorTraining': <Object?>[],
      'toolProficiencies': <Object?>[],
    },
    'columns': <Object?>[],
    'progression': <Object?>[
      for (var level = 1; level <= 20; level++)
        {
          'level': level,
          'proficiencyBonus': fixtureProficiencyBonus(level),
          'features': <Object?>[
            if (level == 1) {'featureId': '${prefix}rage'},
            if (level == 3) ...[
              {'featureId': '${prefix}subclass'},
              {'kind': 'subclassFeature'},
            ],
            if (level == 4 || level == 8 || level == 12 || level == 16)
              {'featureId': '${prefix}ability_score_improvement'},
          ],
          'values': <String, Object?>{},
        },
    ],
    'features': <Object?>[
      {
        'id': '${prefix}rage',
        'name': 'Rage',
        'level': 1,
        'text': 'In battle, you fight with primal ferocity.',
      },
      {
        'id': '${prefix}subclass',
        'name': 'Subclass',
        'level': 3,
        'text': 'You choose a subclass.',
        'facts': <Object?>[
          {'kind': 'grantsSubclass'},
        ],
      },
      {
        'id': '${prefix}ability_score_improvement',
        'name': 'Ability Score Improvement',
        'level': 4,
        'text': 'You gain the Ability Score Improvement feat.',
        'facts': <Object?>[
          {'kind': 'grantsFeat', 'category': 'General'},
        ],
      },
    ],
    'subclasses': <Object?>[],
  };
  for (final key in without) {
    entry.remove(key);
  }
  return entry..addAll(instead);
}

/// A minimal valid spell entry (content-spells.md FR-107), synthetic.
Map<String, Object?> spellEntry({
  String id = 'acid_arrow',
  String name = 'Acid Arrow',
  Set<String> without = const {},
  Map<String, Object?> instead = const {},
}) {
  final entry = <String, Object?>{
    'id': id,
    'name': name,
    'level': 2,
    'school': 'Evocation',
    'classes': <String>['wizard'],
    'castingTimes': <Object?>[
      {'kind': 'magicAction'},
    ],
    'ritual': false,
    'range': <String, Object?>{
      'kind': 'distance',
      'amount': 90,
      'unit': 'feet',
    },
    'components': <String, Object?>{
      'verbal': true,
      'somatic': true,
      'material': <String, Object?>{
        'description': 'A pinch of powder.',
        'costsGp': <int>[],
        'consumesMaterial': false,
      },
    },
    'duration': <String, Object?>{'kind': 'instantaneous'},
    'description': <Object?>[
      {'kind': 'paragraph', 'text': 'A spell description paragraph.'},
    ],
  };
  for (final key in without) {
    entry.remove(key);
  }
  return entry..addAll(instead);
}

/// The default row features of [classEntry]'s fixture: Rage at level 1, the
/// subclass entry and the marker at level 3, Ability Score Improvement at
/// 4, 8, 12 and 16 (content-classes.md FR-043 to FR-045).
List<Object?> fixtureRowFeatures(int level, String prefix) => <Object?>[
  if (level == 1) {'featureId': '${prefix}rage'},
  if (level == 3) ...[
    {'featureId': '${prefix}subclass'},
    {'kind': 'subclassFeature'},
  ],
  if (level == 4 || level == 8 || level == 12 || level == 16)
    {'featureId': '${prefix}ability_score_improvement'},
];

/// A spellcasting class over the [classEntry] fixture: a `slots` or `pact`
/// trait and one spellcasting part per row (content-classes.md FR-028 to
/// FR-032).
Map<String, Object?> casterClassEntry({
  String kind = 'slots',
  bool cantrips = true,
  Map<String, Object?>? Function(int level)? rowSpellcasting,
}) {
  Map<String, Object?> defaultRow(int level) => kind == 'slots'
      ? {
          'cantrips': 2,
          'preparedSpells': 4,
          'spellSlots': <int>[2, 0, 0, 0, 0, 0, 0, 0, 0],
        }
      : {'cantrips': 2, 'preparedSpells': 1, 'spellSlots': 2, 'slotLevel': 1};
  return classEntry(
    instead: {
      'hitPointDie': 'D6',
      'spellcasting': <String, Object?>{
        'kind': kind,
        'ability': 'Charisma',
        if (kind == 'slots') 'cantrips': cantrips,
      },
      'progression': <Object?>[
        for (var level = 1; level <= 20; level++)
          {
            'level': level,
            'proficiencyBonus': fixtureProficiencyBonus(level),
            'features': fixtureRowFeatures(level, 'barbarian_'),
            'spellcasting':
                rowSpellcasting?.call(level) ??
                (kind == 'slots' && !cantrips
                    ? (defaultRow(level)..remove('cantrips'))
                    : defaultRow(level)),
            'values': <String, Object?>{},
          },
      ],
    },
  );
}

/// A class with one declared column of [kind] (content-classes.md FR-036,
/// FR-039, FR-040), every row carrying [defaultValue] and [overrides]
/// replacing single rows' values.
Map<String, Object?> columnedClassEntry({
  String columnId = 'rages',
  String header = 'Rages',
  String kind = 'count',
  required Object? defaultValue,
  Map<int, Object?> overrides = const {},
  Map<String, Object?> instead = const {},
}) {
  return classEntry(
    instead: {
      'columns': <Object?>[
        {'id': columnId, 'header': header, 'kind': kind},
      ],
      'progression': <Object?>[
        for (var level = 1; level <= 20; level++)
          {
            'level': level,
            'proficiencyBonus': fixtureProficiencyBonus(level),
            'features': fixtureRowFeatures(level, 'barbarian_'),
            'values': <String, Object?>{
              columnId: overrides[level] ?? defaultValue,
            },
          },
      ],
      ...instead,
    },
  );
}
