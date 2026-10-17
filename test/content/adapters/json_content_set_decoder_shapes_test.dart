import 'package:srd5e/src/content/adapters/json_content_set_decoder.dart';
import 'package:srd5e/src/content/application/content_decode_result.dart';
import 'package:srd5e/src/content/domain/content_problem_kind.dart';
import 'package:srd5e/src/content/domain/equipment/weapon.dart';
import 'package:srd5e/src/content/domain/species.dart';
import 'package:test/test.dart';

import 'document_fixtures.dart';

const decoder = JsonContentSetDecoder();

void expectProblems(
  ContentDecodeResult result,
  List<(String, ContentProblemKind)> expected,
) {
  expect(result, isA<ContentDecodeFailed>());
  final failed = result as ContentDecodeFailed;
  expect([
    for (final problem in failed.problems) (problem.path, problem.kind),
  ], expected);
}

void expectDecoded(ContentDecodeResult result, int entryCount) {
  expect(result, isA<ContentDecoded>());
  expect((result as ContentDecoded).contentSet.entries, hasLength(entryCount));
}

Species decodedSpecies(ContentDecodeResult result) =>
    (result as ContentDecoded).contentSet.entries.first as Species;

void main() {
  /// Requirement: per case - doc/specs/content-schema-and-decoder.md FR-019, FR-016 - one required field removed per field of every registered kind is missingField at the field's path, in declaration order when several are gone.
  /// Path: per case
  for (final c in _missingFieldCases) {
    test(
      'missing ${c.field} of ${c.array} is missingField [unhappy (missing content)]',
      () {
        expectProblems(decoder.decode(documentOf(c.array, c.entry())), [
          ('/${c.array}/0/${c.field}', ContentProblemKind.missingField),
        ]);
      },
    );
  }

  /// Requirement: per case - doc/specs/content-species-backgrounds-feats.md
  ///   FR-010, FR-011, FR-012, FR-013, FR-014, FR-060, FR-061, FR-074 (of
  ///   that spec); doc/specs/content-schema-and-decoder.md FR-021, FR-023,
  ///   FR-024, FR-025 - the species field rules: integer and enum field
  ///   rules, integer and array bounds, sizes bounds and membership, speed,
  ///   traits, choices, and verbatim text.
  /// Path: per case
  for (final c in _speciesCases) {
    test('species: ${c.label} [${c.path}]', () {
      final result = decoder.decode(documentOf('species', c.entry));

      if (c.expected == null) {
        expectDecoded(result, 1);
      } else {
        expectProblems(result, c.expected!);
      }
    });
  }

  /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-018
  ///   (of the schema: text verbatim);
  ///   doc/specs/content-schema-and-decoder.md FR-029 - a name with a
  ///   typographic apostrophe and a line feed reaches the entry character
  ///   for character.
  /// Path: happy
  test('verbatim text survives the decode', () {
    final result = decoder.decode(
      documentOf(
        'species',
        speciesEntry(
          instead: {
            'name': "Elf’s Line\nFeed",
            'traits': [
              {'name': 'Trait’s', 'text': 'Line one.\nLine two.'},
            ],
          },
        ),
      ),
    );

    expectDecoded(result, 1);
    final species = decodedSpecies(result);
    expect(species.name, 'Elf’s Line\nFeed');
    expect(species.traits.single.text, 'Line one.\nLine two.');
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-016 - a
  ///   species with several problems reports them in the field order the
  ///   owning spec declares.
  /// Path: unhappy (invalid input)
  test('species problems follow the declared field order', () {
    final result = decoder.decode(
      documentOf(
        'species',
        speciesEntry(
          instead: {
            'creatureType': 'Goblinoid',
            'traits': [
              {'name': ' Keen Senses ', 'text': 'You gain proficiency.'},
            ],
          },
          without: const {'speed'},
        ),
      ),
    );

    expectProblems(result, [
      ('/species/0/creatureType', ContentProblemKind.invalidValue),
      ('/species/0/speed', ContentProblemKind.missingField),
      ('/species/0/traits/0/name', ContentProblemKind.invalidValue),
    ]);
  });

  /// Requirement: per case - doc/specs/content-species-backgrounds-feats.md
  ///   FR-024, FR-025, FR-026, FR-027, FR-028, FR-029, FR-030 (of that
  ///   spec); doc/specs/content-schema-and-decoder.md FR-118, FR-119 - the
  ///   background field rules.
  /// Path: per case
  for (final c in _backgroundCases) {
    test('background: ${c.label} [${c.path}]', () {
      final result = decoder.decode(documentOf('backgrounds', c.entry));

      if (c.expected == null) {
        expectDecoded(result, 1);
      } else {
        expectProblems(result, c.expected!);
      }
    });
  }

  /// Requirement: per case - doc/specs/content-species-backgrounds-feats.md
  ///   FR-033, FR-034, FR-035, FR-038, FR-039, FR-040, FR-063 (of that
  ///   spec); doc/specs/content-schema-and-decoder.md FR-118 - the feat
  ///   field rules.
  /// Path: per case
  for (final c in _featCases) {
    test('feat: ${c.label} [${c.path}]', () {
      final result = decoder.decode(documentOf('feats', c.entry));

      if (c.expected == null) {
        expectDecoded(result, 1);
      } else {
        expectProblems(result, c.expected!);
      }
    });
  }

  /// Requirement: per case - doc/specs/content-equipment.md FR-106,
  ///   FR-109, FR-110, FR-111, FR-080, FR-013, FR-014 (of that spec);
  ///   doc/specs/content-schema-and-decoder.md FR-021, FR-025, FR-026 - the
  ///   weapon field rules.
  /// Path: per case
  for (final c in _weaponCases) {
    test('weapon: ${c.label} [${c.path}]', () {
      final result = decoder.decode(documentOf('weapons', c.entry));

      if (c.expected == null) {
        expectDecoded(result, 1);
      } else {
        expectProblems(result, c.expected!);
      }
    });
  }

  /// Requirement: per case - doc/specs/content-equipment.md FR-105,
  ///   FR-109, FR-112, FR-024, FR-080 (of that spec);
  ///   doc/specs/content-schema-and-decoder.md FR-023 - the armor field
  ///   rules.
  /// Path: per case
  for (final c in _armorCases) {
    test('armor: ${c.label} [${c.path}]', () {
      final result = decoder.decode(documentOf('armor', c.entry));

      if (c.expected == null) {
        expectDecoded(result, 1);
      } else {
        expectProblems(result, c.expected!);
      }
    });
  }

  final validShapes = [
    (
      label: 'a fixed damage',
      array: 'weapons',
      entry: weaponEntry(
        instead: {
          'damage': {'fixed': 1},
          'damageType': 'Piercing',
          'properties': <Object?>[],
        },
      ),
    ),
    (
      label: 'a plain property',
      array: 'weapons',
      entry: weaponEntry(
        instead: {
          'properties': <Object?>[
            {'property': 'Light'},
            {'property': 'Loading'},
          ],
        },
      ),
    ),
    (
      label: 'an ammunition property',
      array: 'weapons',
      entry: weaponEntry(
        instead: {
          'properties': <Object?>[
            {
              'property': 'Ammunition',
              'range': {'normal': 80, 'long': 320},
              'ammunition': 'Arrow',
            },
          ],
        },
      ),
    ),
    (
      label: 'a thrown property',
      array: 'weapons',
      entry: weaponEntry(
        instead: {
          'weaponType': 'Melee',
          'properties': <Object?>[
            {
              'property': 'Thrown',
              'range': {'normal': 20, 'long': 60},
            },
          ],
        },
      ),
    ),
    (
      label: 'a light armor with full dexterity',
      array: 'armor',
      entry: armorEntry(
        instead: {
          'category': 'Light',
          'armorClass': {'base': 11, 'dexterity': 'full'},
          'stealthDisadvantage': false,
          'weightPounds': 10,
          'cost': {'amount': 10, 'coin': 'GP'},
        },
      ),
    ),
    (
      label: 'a medium armor with capped dexterity',
      array: 'armor',
      entry: armorEntry(
        instead: {
          'category': 'Medium',
          'armorClass': {'base': 15, 'dexterity': 'capped', 'maximum': 2},
          'stealthDisadvantage': false,
          'weightPounds': 20,
          'cost': {'amount': 750, 'coin': 'GP'},
        },
      ),
    ),
  ];

  /// Requirement: per case - doc/specs/content-equipment.md FR-110, FR-103,
  ///   FR-111 (of that spec) - the remaining valid wire shapes decode to
  ///   their variants: a fixed damage, plain properties, an Ammunition
  ///   property, a Thrown property, and Light and Medium armor with their
  ///   Dexterity treatments.
  /// Path: per case
  for (final c in validShapes) {
    test('valid shape: ${c.label} [happy]', () {
      expectDecoded(decoder.decode(documentOf(c.array, c.entry)), 1);
    });
  }

  final wrongTypeCases = [
    _WrongTypeCase(
      'a source that is not an object',
      'species',
      speciesEntry(instead: {'source': 'nowhere'}),
      '/species/0/source',
    ),
    _WrongTypeCase(
      'a trait element that is not an object',
      'species',
      speciesEntry(
        instead: {
          'traits': <Object?>['Darkvision'],
        },
      ),
      '/species/0/traits/0',
    ),
    _WrongTypeCase(
      'a size element that is not a string',
      'species',
      speciesEntry(
        instead: {
          'sizes': <Object?>[1],
        },
      ),
      '/species/0/sizes/0',
    ),
    _WrongTypeCase(
      'a cost that is not an object',
      'weapons',
      weaponEntry(instead: {'cost': 'free'}),
      '/weapons/0/cost',
    ),
    _WrongTypeCase(
      'a weight that is not a number',
      'weapons',
      weaponEntry(instead: {'weightPounds': '3'}),
      '/weapons/0/weightPounds',
    ),
    _WrongTypeCase(
      'a benefit name that is not a string',
      'feats',
      featEntry(
        instead: {
          'benefits': <Object?>[
            {'name': 5, 'text': 'x'},
          ],
        },
      ),
      '/feats/0/benefits/0/name',
    ),
    _WrongTypeCase(
      'an ability element that is not a string',
      'backgrounds',
      backgroundEntry(
        instead: {
          'abilityScores': <Object?>['Strength', 'Dexterity', 1],
        },
      ),
      '/backgrounds/0/abilityScores/2',
    ),
    _WrongTypeCase(
      'a prerequisite ability that is not a string',
      'feats',
      featEntry(
        instead: {
          'prerequisites': <Object?>[
            {
              'kind': 'abilityScore',
              'abilities': <Object?>[1],
              'minimum': 13,
            },
          ],
        },
      ),
      '/feats/0/prerequisites/0/abilities/0',
    ),
    _WrongTypeCase(
      'an ability element outside the six',
      'feats',
      featEntry(
        instead: {
          'prerequisites': <Object?>[
            {
              'kind': 'abilityScore',
              'abilities': <Object?>['Silly'],
              'minimum': 13,
            },
          ],
        },
      ),
      '/feats/0/prerequisites/0/abilities/0',
      kind: ContentProblemKind.invalidValue,
    ),
    _WrongTypeCase(
      'a spell id that is not a string',
      'species',
      speciesEntry(
        instead: {
          'choices': [
            {
              'traitName': 'Keen Senses',
              'options': [
                {
                  'kind': 'text',
                  'name': 'Forest Gnome',
                  'text': 'You know Minor Illusion.',
                  'spellIds': <Object?>[1],
                },
              ],
            },
          ],
        },
      ),
      '/species/0/choices/0/options/0/spellIds/0',
    ),
    _WrongTypeCase(
      'a spell id outside the id rule',
      'species',
      speciesEntry(
        instead: {
          'choices': [
            {
              'traitName': 'Keen Senses',
              'options': [
                {
                  'kind': 'text',
                  'name': 'Forest Gnome',
                  'text': 'You know Minor Illusion.',
                  'spellIds': <Object?>['Minor Illusion'],
                },
              ],
            },
          ],
        },
      ),
      '/species/0/choices/0/options/0/spellIds/0',
      kind: ContentProblemKind.invalidValue,
    ),
    _WrongTypeCase(
      'an explicit null in a required field',
      'species',
      speciesEntry(instead: {'speed': null}),
      '/species/0/speed',
    ),
    _WrongTypeCase(
      'an explicit null in an optional field',
      'species',
      speciesEntry(instead: {'sizeText': null}),
      '/species/0/sizeText',
    ),
    _WrongTypeCase(
      'an explicit null in a nested optional field',
      'backgrounds',
      backgroundEntry(
        instead: {
          'feat': <String, Object?>{
            'featId': 'savage_attacker',
            'choice': null,
          },
        },
      ),
      '/backgrounds/0/feat/choice',
    ),
  ];

  /// Requirement: per case - doc/specs/content-schema-and-decoder.md
  ///   FR-020, FR-021 - a null or wrong-typed value in a required or
  ///   optional position is wrongType at its own path; absence, never null,
  ///   expresses optionality.
  /// Path: per case
  for (final c in wrongTypeCases) {
    test('${c.kind.name}: ${c.label} [unhappy (invalid input)]', () {
      expectProblems(decoder.decode(documentOf(c.array, c.entry)), [
        (c.path, c.kind),
      ]);
    });
  }

  /// Requirement: doc/specs/content-species-backgrounds-feats.md FR-012
  ///   (of that spec); schema FR-071 - a decoded species entry carries the
  ///   key of its registered kind and its typed id.
  /// Path: happy
  test('a decoded entry carries its registered key kind', () {
    final result = decoder.decode(documentOf('weapons', weaponEntry()));

    final weapon = (result as ContentDecoded).contentSet.entries.single;
    expect(weapon, isA<Weapon>());
    expect(weapon.key.kind.name, 'equipment');
    expect(weapon.key.id.value, 'longsword');
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-073 - the
  ///   decoded collections are unmodifiable.
  /// Path: unhappy (immutability)
  test('decoded collections cannot be mutated', () {
    final result = decoder.decode(documentOf('species', speciesEntry()));
    final species = decodedSpecies(result);

    expect(() => species.traits.clear(), throwsUnsupportedError);
    expect(() => species.sizes.clear(), throwsUnsupportedError);
  });
}

final class _MissingFieldCase {
  const _MissingFieldCase(this.array, this.field, this.entry)
    : path = 'unhappy (missing content)';

  final String array;
  final String field;
  final Map<String, Object?> Function() entry;
  final String path;
}

final List<_MissingFieldCase> _missingFieldCases = [
  _MissingFieldCase(
    'species',
    'creatureType',
    () => speciesEntry(without: const {'creatureType'}),
  ),
  _MissingFieldCase(
    'species',
    'sizes',
    () => speciesEntry(without: const {'sizes'}),
  ),
  _MissingFieldCase(
    'species',
    'speed',
    () => speciesEntry(without: const {'speed'}),
  ),
  _MissingFieldCase(
    'species',
    'traits',
    () => speciesEntry(without: const {'traits'}),
  ),
  _MissingFieldCase(
    'backgrounds',
    'abilityScores',
    () => backgroundEntry(without: const {'abilityScores'}),
  ),
  _MissingFieldCase(
    'backgrounds',
    'feat',
    () => backgroundEntry(without: const {'feat'}),
  ),
  _MissingFieldCase(
    'backgrounds',
    'skillProficiencies',
    () => backgroundEntry(without: const {'skillProficiencies'}),
  ),
  _MissingFieldCase(
    'backgrounds',
    'toolProficiency',
    () => backgroundEntry(without: const {'toolProficiency'}),
  ),
  _MissingFieldCase(
    'backgrounds',
    'equipmentOptions',
    () => backgroundEntry(without: const {'equipmentOptions'}),
  ),
  _MissingFieldCase(
    'feats',
    'category',
    () => featEntry(without: const {'category'}),
  ),
  _MissingFieldCase(
    'feats',
    'benefits',
    () => featEntry(without: const {'benefits'}),
  ),
  _MissingFieldCase(
    'feats',
    'repeatable',
    () => featEntry(without: const {'repeatable'}),
  ),
  _MissingFieldCase(
    'weapons',
    'category',
    () => weaponEntry(without: const {'category'}),
  ),
  _MissingFieldCase(
    'weapons',
    'weaponType',
    () => weaponEntry(without: const {'weaponType'}),
  ),
  _MissingFieldCase(
    'weapons',
    'damage',
    () => weaponEntry(without: const {'damage'}),
  ),
  _MissingFieldCase(
    'weapons',
    'damageType',
    () => weaponEntry(without: const {'damageType'}),
  ),
  _MissingFieldCase(
    'weapons',
    'properties',
    () => weaponEntry(without: const {'properties'}),
  ),
  _MissingFieldCase(
    'weapons',
    'mastery',
    () => weaponEntry(without: const {'mastery'}),
  ),
  _MissingFieldCase(
    'weapons',
    'cost',
    () => weaponEntry(without: const {'cost'}),
  ),
  _MissingFieldCase(
    'armor',
    'category',
    () => armorEntry(without: const {'category'}),
  ),
  _MissingFieldCase(
    'armor',
    'armorClass',
    () => armorEntry(without: const {'armorClass'}),
  ),
  _MissingFieldCase(
    'armor',
    'stealthDisadvantage',
    () => armorEntry(without: const {'stealthDisadvantage'}),
  ),
  _MissingFieldCase(
    'armor',
    'weightPounds',
    () => armorEntry(without: const {'weightPounds'}),
  ),
  _MissingFieldCase('armor', 'cost', () => armorEntry(without: const {'cost'})),
];

final class _ShapeCase {
  const _ShapeCase(this.label, this.entry, this.expected)
    : path = expected == null ? 'happy' : 'unhappy (invalid input)';

  final String label;
  final Map<String, Object?> entry;
  final List<(String, ContentProblemKind)>? expected;
  final String path;
}

/// One wrong-typed (or, with [kind], invalid) value at its own path.
final class _WrongTypeCase {
  const _WrongTypeCase(
    this.label,
    this.array,
    this.entry,
    this.path, {
    this.kind = ContentProblemKind.wrongType,
  });

  final String label;
  final String array;
  final Map<String, Object?> entry;
  final String path;
  final ContentProblemKind kind;
}

List<Object?> _trait(String name, [String text = 'You gain a benefit.']) =>
    <Object?>[
      {'name': name, 'text': text},
    ];

List<Object?> _lineageLevels() => <Object?>[
  {'level': 1, 'text': 'You learn a cantrip.', 'spellId': 'dancing_lights'},
  {'level': 3, 'text': 'You learn a spell.', 'spellId': 'detect_magic'},
  {'level': 5, 'text': 'You learn more.', 'spellId': 'misty_step'},
];

final List<_ShapeCase> _speciesCases = [
  _ShapeCase(
    'an empty sizes array',
    speciesEntry(instead: {'sizes': <Object?>[]}),
    [('/species/0/sizes', ContentProblemKind.outOfRange)],
  ),
  _ShapeCase(
    'three sizes',
    speciesEntry(
      instead: {
        'sizes': ['Small', 'Medium', 'Large'],
      },
    ),
    [('/species/0/sizes', ContentProblemKind.outOfRange)],
  ),
  _ShapeCase(
    'a repeated size',
    speciesEntry(
      instead: {
        'sizes': ['Medium', 'Medium'],
      },
    ),
    [('/species/0/sizes/1', ContentProblemKind.duplicate)],
  ),
  _ShapeCase(
    'a size a species may not be',
    speciesEntry(
      instead: {
        'sizes': ['Large'],
      },
    ),
    [('/species/0/sizes/0', ContentProblemKind.invalidValue)],
  ),
  _ShapeCase('a negative speed', speciesEntry(instead: {'speed': -5}), [
    ('/species/0/speed', ContentProblemKind.outOfRange),
  ]),
  _ShapeCase('a fractional speed', speciesEntry(instead: {'speed': 30.5}), [
    ('/species/0/speed', ContentProblemKind.wrongType),
  ]),
  _ShapeCase(
    'an empty traits array',
    speciesEntry(instead: {'traits': <Object?>[]}),
    [('/species/0/traits', ContentProblemKind.outOfRange)],
  ),
  _ShapeCase(
    'a repeated trait name',
    speciesEntry(
      instead: {
        'traits': [..._trait('Darkvision'), ..._trait('Darkvision')],
      },
    ),
    [('/species/0/traits/1', ContentProblemKind.duplicate)],
  ),
  _ShapeCase(
    'a blank trait name',
    speciesEntry(
      instead: {
        'traits': [
          {'name': ' ', 'text': 'x'},
        ],
      },
    ),
    [('/species/0/traits/0/name', ContentProblemKind.invalidValue)],
  ),
  _ShapeCase(
    'a blank trait text',
    speciesEntry(
      instead: {
        'traits': [
          {'name': 'Darkvision', 'text': ' '},
        ],
      },
    ),
    [('/species/0/traits/0/text', ContentProblemKind.invalidValue)],
  ),
  _ShapeCase(
    'an unknown key in a trait',
    speciesEntry(
      instead: {
        'traits': [
          {'name': 'Darkvision', 'text': 'x', 'range': 60},
        ],
      },
    ),
    [('/species/0/traits/0/range', ContentProblemKind.unknownField)],
  ),
  _ShapeCase(
    'an option kind that is not one of the three',
    speciesEntry(
      instead: {
        'choices': [
          {
            'traitName': 'Keen Senses',
            'options': [
              {'kind': 'skill', 'name': 'Perception'},
            ],
          },
        ],
      },
    ),
    [('/species/0/choices/0/options/0/kind', ContentProblemKind.invalidValue)],
  ),
  _ShapeCase(
    'a missing kind',
    speciesEntry(
      instead: {
        'choices': [
          {
            'traitName': 'Keen Senses',
            'options': [
              {'name': 'Perception'},
            ],
          },
        ],
      },
    ),
    [('/species/0/choices/0/options/0/kind', ContentProblemKind.missingField)],
  ),
  _ShapeCase(
    'an empty options array',
    speciesEntry(
      instead: {
        'choices': [
          {'traitName': 'Keen Senses', 'options': <Object?>[]},
        ],
      },
    ),
    [('/species/0/choices/0/options', ContentProblemKind.outOfRange)],
  ),
  _ShapeCase(
    'a repeated option name',
    speciesEntry(
      instead: {
        'choices': [
          {
            'traitName': 'Keen Senses',
            'options': [
              {'kind': 'text', 'name': 'Option', 'text': 'x'},
              {'kind': 'text', 'name': 'Option', 'text': 'y'},
            ],
          },
        ],
      },
    ),
    [('/species/0/choices/0/options/1', ContentProblemKind.duplicate)],
  ),
  _ShapeCase(
    'mixed variants in one choice',
    speciesEntry(
      instead: {
        'choices': [
          {
            'traitName': 'Keen Senses',
            'options': [
              {'kind': 'text', 'name': 'Option', 'text': 'x'},
              {'kind': 'damageType', 'name': 'Black', 'damageType': 'Acid'},
            ],
          },
        ],
      },
    ),
    [
      (
        '/species/0/choices/0/options/1/kind',
        ContentProblemKind.constraintViolation,
      ),
    ],
  ),
  _ShapeCase(
    'a damage-type option with a text key',
    speciesEntry(
      instead: {
        'choices': [
          {
            'traitName': 'Keen Senses',
            'options': [
              {
                'kind': 'damageType',
                'name': 'Black',
                'damageType': 'Acid',
                'text': 'none',
              },
            ],
          },
        ],
      },
    ),
    [('/species/0/choices/0/options/0/text', ContentProblemKind.unknownField)],
  ),
  _ShapeCase(
    'an unknown damage type',
    speciesEntry(
      instead: {
        'choices': [
          {
            'traitName': 'Keen Senses',
            'options': [
              {'kind': 'damageType', 'name': 'Black', 'damageType': 'Sonic'},
            ],
          },
        ],
      },
    ),
    [
      (
        '/species/0/choices/0/options/0/damageType',
        ContentProblemKind.invalidValue,
      ),
    ],
  ),
  _ShapeCase(
    'a valid damage-type choice',
    speciesEntry(
      instead: {
        'choices': [
          {
            'traitName': 'Keen Senses',
            'options': [
              {'kind': 'damageType', 'name': 'Black', 'damageType': 'Acid'},
              {'kind': 'damageType', 'name': 'Blue', 'damageType': 'Lightning'},
            ],
          },
        ],
      },
    ),
    null,
  ),
  _ShapeCase(
    'a valid lineage choice',
    speciesEntry(
      instead: {
        'choices': [
          {
            'traitName': 'Keen Senses',
            'options': [
              {
                'kind': 'lineage',
                'name': 'Drow',
                'levelBenefits': _lineageLevels(),
              },
            ],
          },
        ],
      },
    ),
    null,
  ),
  _ShapeCase(
    'two level benefits',
    speciesEntry(
      instead: {
        'choices': [
          {
            'traitName': 'Keen Senses',
            'options': [
              {
                'kind': 'lineage',
                'name': 'Drow',
                'levelBenefits': (_lineageLevels()..removeLast()),
              },
            ],
          },
        ],
      },
    ),
    [
      (
        '/species/0/choices/0/options/0/levelBenefits',
        ContentProblemKind.outOfRange,
      ),
    ],
  ),
  _ShapeCase(
    'a level outside 1, 3 and 5',
    speciesEntry(
      instead: {
        'choices': [
          {
            'traitName': 'Keen Senses',
            'options': [
              {
                'kind': 'lineage',
                'name': 'Drow',
                'levelBenefits': [
                  {'level': 1, 'text': 'a', 'spellId': 'dancing_lights'},
                  {'level': 3, 'text': 'b', 'spellId': 'detect_magic'},
                  {'level': 2, 'text': 'c', 'spellId': 'misty_step'},
                ],
              },
            ],
          },
        ],
      },
    ),
    [
      (
        '/species/0/choices/0/options/0/levelBenefits/2/level',
        ContentProblemKind.invalidValue,
      ),
    ],
  ),
  _ShapeCase(
    'a repeated level',
    speciesEntry(
      instead: {
        'choices': [
          {
            'traitName': 'Keen Senses',
            'options': [
              {
                'kind': 'lineage',
                'name': 'Drow',
                'levelBenefits': [
                  {'level': 1, 'text': 'a', 'spellId': 'dancing_lights'},
                  {'level': 3, 'text': 'b', 'spellId': 'detect_magic'},
                  {'level': 3, 'text': 'c', 'spellId': 'misty_step'},
                ],
              },
            ],
          },
        ],
      },
    ),
    [
      (
        '/species/0/choices/0/options/0/levelBenefits/2/level',
        ContentProblemKind.duplicate,
      ),
    ],
  ),
  _ShapeCase(
    'levels in another order',
    speciesEntry(
      instead: {
        'choices': [
          {
            'traitName': 'Keen Senses',
            'options': [
              {
                'kind': 'lineage',
                'name': 'Drow',
                'levelBenefits': [
                  {'level': 1, 'text': 'a', 'spellId': 'dancing_lights'},
                  {'level': 5, 'text': 'b', 'spellId': 'misty_step'},
                  {'level': 3, 'text': 'c', 'spellId': 'detect_magic'},
                ],
              },
            ],
          },
        ],
      },
    ),
    [
      (
        '/species/0/choices/0/options/0/levelBenefits',
        ContentProblemKind.constraintViolation,
      ),
    ],
  ),
  _ShapeCase(
    'a benefit with no spellId',
    speciesEntry(
      instead: {
        'choices': [
          {
            'traitName': 'Keen Senses',
            'options': [
              {
                'kind': 'lineage',
                'name': 'Drow',
                'levelBenefits': [
                  {'level': 1, 'text': 'a'},
                  {'level': 3, 'text': 'b', 'spellId': 'detect_magic'},
                  {'level': 5, 'text': 'c', 'spellId': 'misty_step'},
                ],
              },
            ],
          },
        ],
      },
    ),
    [
      (
        '/species/0/choices/0/options/0/levelBenefits/0/spellId',
        ContentProblemKind.missingField,
      ),
    ],
  ),
  _ShapeCase(
    'a text option with spell ids',
    speciesEntry(
      instead: {
        'choices': [
          {
            'traitName': 'Keen Senses',
            'options': [
              {
                'kind': 'text',
                'name': 'Forest Gnome',
                'text': 'You know Minor Illusion.',
                'spellIds': ['minor_illusion', 'speak_with_animals'],
              },
            ],
          },
        ],
      },
    ),
    null,
  ),
  _ShapeCase(
    'a choice whose traitName names no trait',
    speciesEntry(
      instead: {
        'choices': [
          {
            'traitName': 'Draconic Ancestry',
            'options': [
              {'kind': 'text', 'name': 'Option', 'text': 'x'},
            ],
          },
        ],
      },
    ),
    [
      (
        '/species/0/choices/0/traitName',
        ContentProblemKind.constraintViolation,
      ),
    ],
  ),
  _ShapeCase(
    'an optional sizeText present',
    speciesEntry(instead: {'sizeText': 'You are Medium or Small.'}),
    null,
  ),
  _ShapeCase('a blank sizeText', speciesEntry(instead: {'sizeText': ' '}), [
    ('/species/0/sizeText', ContentProblemKind.invalidValue),
  ]),
];

final List<_ShapeCase> _backgroundCases = [
  _ShapeCase(
    'two abilities',
    backgroundEntry(
      instead: {
        'abilityScores': ['Strength', 'Dexterity'],
      },
    ),
    [('/backgrounds/0/abilityScores', ContentProblemKind.outOfRange)],
  ),
  _ShapeCase(
    'four abilities',
    backgroundEntry(
      instead: {
        'abilityScores': [
          'Strength',
          'Dexterity',
          'Constitution',
          'Intelligence',
        ],
      },
    ),
    [('/backgrounds/0/abilityScores', ContentProblemKind.outOfRange)],
  ),
  _ShapeCase(
    'a repeated ability',
    backgroundEntry(
      instead: {
        'abilityScores': ['Strength', 'Dexterity', 'Dexterity'],
      },
    ),
    [('/backgrounds/0/abilityScores/2', ContentProblemKind.duplicate)],
  ),
  _ShapeCase(
    'an unknown ability spelling',
    backgroundEntry(
      instead: {
        'abilityScores': ['Strength', 'Dexterity', 'Charisma '],
      },
    ),
    [('/backgrounds/0/abilityScores/2', ContentProblemKind.invalidValue)],
  ),
  _ShapeCase(
    'one skill',
    backgroundEntry(
      instead: {
        'skillProficiencies': ['Athletics'],
      },
    ),
    [('/backgrounds/0/skillProficiencies', ContentProblemKind.outOfRange)],
  ),
  _ShapeCase(
    'a repeated skill',
    backgroundEntry(
      instead: {
        'skillProficiencies': ['Athletics', 'Athletics'],
      },
    ),
    [('/backgrounds/0/skillProficiencies/1', ContentProblemKind.duplicate)],
  ),
  _ShapeCase(
    'a specific tool proficiency',
    backgroundEntry(
      instead: {
        'toolProficiency': {'kind': 'specific', 'name': "Thieves’ Tools"},
      },
    ),
    null,
  ),
  _ShapeCase(
    'an unknown tool kind',
    backgroundEntry(
      instead: {
        'toolProficiency': {'kind': 'any', 'name': 'x'},
      },
    ),
    [('/backgrounds/0/toolProficiency/kind', ContentProblemKind.invalidValue)],
  ),
  _ShapeCase(
    'a specific tool with a blank name',
    backgroundEntry(
      instead: {
        'toolProficiency': {'kind': 'specific', 'name': ' '},
      },
    ),
    [('/backgrounds/0/toolProficiency/name', ContentProblemKind.invalidValue)],
  ),
  _ShapeCase(
    'a choice tool with a blank category',
    backgroundEntry(
      instead: {
        'toolProficiency': {'kind': 'choice', 'category': ' '},
      },
    ),
    [
      (
        '/backgrounds/0/toolProficiency/category',
        ContentProblemKind.invalidValue,
      ),
    ],
  ),
  _ShapeCase(
    'a feat reference with a choice qualifier',
    backgroundEntry(
      instead: {
        'feat': {'featId': 'magic_initiate', 'choice': 'Cleric'},
      },
    ),
    null,
  ),
  _ShapeCase(
    'a feat reference with a blank choice',
    backgroundEntry(
      instead: {
        'feat': {'featId': 'magic_initiate', 'choice': ' '},
      },
    ),
    [('/backgrounds/0/feat/choice', ContentProblemKind.invalidValue)],
  ),
  _ShapeCase(
    'a feat reference with an unknown key',
    backgroundEntry(
      instead: {
        'feat': {'featId': 'magic_initiate', 'level': 1},
      },
    ),
    [('/backgrounds/0/feat/level', ContentProblemKind.unknownField)],
  ),
  _ShapeCase(
    'equipment options with only A',
    backgroundEntry(
      instead: {
        'equipmentOptions': {
          'A': {'items': <Object?>[], 'gold': 8},
        },
      },
    ),
    [('/backgrounds/0/equipmentOptions/B', ContentProblemKind.missingField)],
  ),
  _ShapeCase(
    'equipment options with an extra key',
    backgroundEntry(
      instead: {
        'equipmentOptions': {
          'A': {'items': <Object?>[], 'gold': 8},
          'B': {'items': <Object?>[], 'gold': 50},
          'C': {'items': <Object?>[], 'gold': 0},
        },
      },
    ),
    [('/backgrounds/0/equipmentOptions/C', ContentProblemKind.unknownField)],
  ),
  _ShapeCase(
    'a quantity of zero',
    backgroundEntry(
      instead: {
        'equipmentOptions': {
          'A': {
            'items': <Object?>[
              {'name': 'Arrows', 'quantity': 0},
            ],
            'gold': 8,
          },
          'B': {'items': <Object?>[], 'gold': 50},
        },
      },
    ),
    [
      (
        '/backgrounds/0/equipmentOptions/A/items/0/quantity',
        ContentProblemKind.outOfRange,
      ),
    ],
  ),
  _ShapeCase(
    'a negative gold',
    backgroundEntry(
      instead: {
        'equipmentOptions': {
          'A': {'items': <Object?>[], 'gold': -1},
          'B': {'items': <Object?>[], 'gold': 50},
        },
      },
    ),
    [('/backgrounds/0/equipmentOptions/A/gold', ContentProblemKind.outOfRange)],
  ),
  _ShapeCase(
    'a blank item name',
    backgroundEntry(
      instead: {
        'equipmentOptions': {
          'A': {
            'items': <Object?>[
              {'name': '', 'quantity': 1},
            ],
            'gold': 8,
          },
          'B': {'items': <Object?>[], 'gold': 50},
        },
      },
    ),
    [
      (
        '/backgrounds/0/equipmentOptions/A/items/0/name',
        ContentProblemKind.invalidValue,
      ),
    ],
  ),
];

final List<_ShapeCase> _featCases = [
  _ShapeCase(
    'a lowercase category',
    featEntry(instead: {'category': 'origin'}),
    [('/feats/0/category', ContentProblemKind.invalidValue)],
  ),
  _ShapeCase(
    'an empty prerequisites array',
    featEntry(
      instead: {
        'prerequisites': <Object?>[],
        'repeatable': true,
        'repeatableText': 'Repeatable.',
      },
    ),
    [('/feats/0/prerequisites', ContentProblemKind.outOfRange)],
  ),
  _ShapeCase(
    'a level prerequisite at the bounds',
    featEntry(
      instead: {
        'category': 'General',
        'prerequisites': [
          {'kind': 'level', 'minimum': 4},
        ],
        'repeatable': true,
        'repeatableText': 'Repeatable.',
      },
    ),
    null,
  ),
  _ShapeCase(
    'a level prerequisite below 1',
    featEntry(
      instead: {
        'prerequisites': [
          {'kind': 'level', 'minimum': 0},
        ],
      },
    ),
    [('/feats/0/prerequisites/0/minimum', ContentProblemKind.outOfRange)],
  ),
  _ShapeCase(
    'a level prerequisite above 20',
    featEntry(
      instead: {
        'prerequisites': [
          {'kind': 'level', 'minimum': 21},
        ],
      },
    ),
    [('/feats/0/prerequisites/0/minimum', ContentProblemKind.outOfRange)],
  ),
  _ShapeCase(
    'an ability-score prerequisite at the bounds',
    featEntry(
      instead: {
        'category': 'General',
        'prerequisites': [
          {
            'kind': 'abilityScore',
            'abilities': ['Strength', 'Dexterity'],
            'minimum': 13,
          },
        ],
      },
    ),
    null,
  ),
  _ShapeCase(
    'an empty abilities array',
    featEntry(
      instead: {
        'prerequisites': [
          {'kind': 'abilityScore', 'abilities': <Object?>[], 'minimum': 13},
        ],
      },
    ),
    [('/feats/0/prerequisites/0/abilities', ContentProblemKind.outOfRange)],
  ),
  _ShapeCase(
    'a repeated ability',
    featEntry(
      instead: {
        'prerequisites': [
          {
            'kind': 'abilityScore',
            'abilities': ['Strength', 'Strength'],
            'minimum': 13,
          },
        ],
      },
    ),
    [('/feats/0/prerequisites/0/abilities/1', ContentProblemKind.duplicate)],
  ),
  _ShapeCase(
    'an ability-score minimum outside 1 to 30',
    featEntry(
      instead: {
        'prerequisites': [
          {
            'kind': 'abilityScore',
            'abilities': ['Strength'],
            'minimum': 31,
          },
        ],
      },
    ),
    [('/feats/0/prerequisites/0/minimum', ContentProblemKind.outOfRange)],
  ),
  _ShapeCase(
    'a feature prerequisite',
    featEntry(
      instead: {
        'category': 'Fighting Style',
        'prerequisites': [
          {'kind': 'feature', 'name': 'Fighting Style Feature'},
        ],
      },
    ),
    null,
  ),
  _ShapeCase(
    'an unknown prerequisite kind',
    featEntry(
      instead: {
        'prerequisites': [
          {'kind': 'skill', 'name': 'x'},
        ],
      },
    ),
    [('/feats/0/prerequisites/0/kind', ContentProblemKind.invalidValue)],
  ),
  _ShapeCase(
    'an empty benefits array',
    featEntry(instead: {'benefits': <Object?>[]}),
    [('/feats/0/benefits', ContentProblemKind.outOfRange)],
  ),
  _ShapeCase(
    'a blank benefit text',
    featEntry(
      instead: {
        'benefits': [
          {'name': 'x', 'text': ' '},
        ],
      },
    ),
    [('/feats/0/benefits/0/text', ContentProblemKind.invalidValue)],
  ),
  _ShapeCase(
    'a benefit with a padded name',
    featEntry(
      instead: {
        'benefits': [
          {'name': ' Initiative Proficiency ', 'text': 'x'},
        ],
      },
    ),
    [('/feats/0/benefits/0/name', ContentProblemKind.invalidValue)],
  ),
  _ShapeCase(
    'a repeatable feat with its text',
    featEntry(
      instead: {
        'repeatable': true,
        'repeatableText': 'You can take this feat multiple times.',
      },
    ),
    null,
  ),
  _ShapeCase(
    'repeatable without text',
    featEntry(instead: {'repeatable': true}),
    [('/feats/0/repeatableText', ContentProblemKind.missingField)],
  ),
  _ShapeCase(
    'repeatable text without repeatable',
    featEntry(
      instead: {
        'repeatable': false,
        'repeatableText': 'You can take this feat multiple times.',
      },
    ),
    [('/feats/0/repeatableText', ContentProblemKind.constraintViolation)],
  ),
  _ShapeCase(
    'a non-boolean repeatable',
    featEntry(instead: {'repeatable': 'yes'}),
    [('/feats/0/repeatable', ContentProblemKind.wrongType)],
  ),
];

final List<_ShapeCase> _weaponCases = [
  _ShapeCase(
    'an unknown category',
    weaponEntry(instead: {'category': 'Exotic'}),
    [('/weapons/0/category', ContentProblemKind.invalidValue)],
  ),
  _ShapeCase(
    'an unknown weaponType',
    weaponEntry(instead: {'weaponType': 'Thrown'}),
    [('/weapons/0/weaponType', ContentProblemKind.invalidValue)],
  ),
  _ShapeCase(
    'a damage with neither dice nor fixed',
    weaponEntry(instead: {'damage': <String, Object?>{}}),
    [('/weapons/0/damage', ContentProblemKind.missingField)],
  ),
  _ShapeCase(
    'a damage with both dice and fixed',
    weaponEntry(
      instead: {
        'damage': {'dice': '1d8', 'fixed': 1},
      },
    ),
    [('/weapons/0/damage', ContentProblemKind.constraintViolation)],
  ),
  _ShapeCase(
    'a dice without an explicit count',
    weaponEntry(
      instead: {
        'damage': {'dice': 'd8'},
      },
    ),
    [('/weapons/0/damage/dice', ContentProblemKind.invalidValue)],
  ),
  _ShapeCase(
    'a dice with a modifier',
    weaponEntry(
      instead: {
        'damage': {'dice': '1d8+1'},
      },
    ),
    [('/weapons/0/damage/dice', ContentProblemKind.invalidValue)],
  ),
  _ShapeCase(
    'a dice of x notation',
    weaponEntry(
      instead: {
        'damage': {'dice': 'xd8'},
      },
    ),
    [('/weapons/0/damage/dice', ContentProblemKind.invalidValue)],
  ),
  _ShapeCase(
    'a dice without sides',
    weaponEntry(
      instead: {
        'damage': {'dice': '1d'},
      },
    ),
    [('/weapons/0/damage/dice', ContentProblemKind.invalidValue)],
  ),
  _ShapeCase(
    'a fixed damage of zero',
    weaponEntry(
      instead: {
        'damage': {'fixed': 0},
      },
    ),
    [('/weapons/0/damage/fixed', ContentProblemKind.outOfRange)],
  ),
  _ShapeCase(
    'a fixed damage that is not whole',
    weaponEntry(
      instead: {
        'damage': {'fixed': 1.5},
      },
    ),
    [('/weapons/0/damage/fixed', ContentProblemKind.wrongType)],
  ),
  _ShapeCase(
    'an unknown damageType',
    weaponEntry(instead: {'damageType': 'Sonic'}),
    [('/weapons/0/damageType', ContentProblemKind.invalidValue)],
  ),
  _ShapeCase(
    'a repeated property',
    weaponEntry(
      instead: {
        'properties': [
          {'property': 'Light'},
          {'property': 'Light'},
        ],
      },
    ),
    [('/weapons/0/properties/1', ContentProblemKind.duplicate)],
  ),
  _ShapeCase(
    'a property element without property',
    weaponEntry(
      instead: {
        'properties': [
          {'damage': '1d6'},
        ],
      },
    ),
    [('/weapons/0/properties/0/property', ContentProblemKind.missingField)],
  ),
  _ShapeCase(
    'an ammunition property without its range',
    weaponEntry(
      instead: {
        'properties': [
          {'property': 'Ammunition', 'ammunition': 'Arrow'},
        ],
      },
    ),
    [('/weapons/0/properties/0/range', ContentProblemKind.missingField)],
  ),
  _ShapeCase(
    'an ammunition property without its ammunition',
    weaponEntry(
      instead: {
        'properties': [
          {
            'property': 'Ammunition',
            'range': {'normal': 80, 'long': 320},
          },
        ],
      },
    ),
    [('/weapons/0/properties/0/ammunition', ContentProblemKind.missingField)],
  ),
  _ShapeCase(
    'an ammunition type outside the four',
    weaponEntry(
      instead: {
        'properties': [
          {
            'property': 'Ammunition',
            'range': {'normal': 80, 'long': 320},
            'ammunition': 'Rocks',
          },
        ],
      },
    ),
    [('/weapons/0/properties/0/ammunition', ContentProblemKind.invalidValue)],
  ),
  _ShapeCase(
    'a long range not greater than normal',
    weaponEntry(
      instead: {
        'properties': [
          {
            'property': 'Thrown',
            'range': {'normal': 20, 'long': 20},
          },
        ],
      },
    ),
    [
      (
        '/weapons/0/properties/0/range/long',
        ContentProblemKind.constraintViolation,
      ),
    ],
  ),
  _ShapeCase(
    'a normal range of zero',
    weaponEntry(
      instead: {
        'properties': [
          {
            'property': 'Thrown',
            'range': {'normal': 0, 'long': 20},
          },
        ],
      },
    ),
    [('/weapons/0/properties/0/range/normal', ContentProblemKind.outOfRange)],
  ),
  _ShapeCase(
    'a range on a plain property',
    weaponEntry(
      instead: {
        'properties': [
          {
            'property': 'Light',
            'range': {'normal': 1, 'long': 2},
          },
        ],
      },
    ),
    [('/weapons/0/properties/0/range', ContentProblemKind.constraintViolation)],
  ),
  _ShapeCase(
    'a versatile damage that is malformed',
    weaponEntry(
      instead: {
        'properties': [
          {'property': 'Versatile', 'damage': 'two dice'},
        ],
      },
    ),
    [('/weapons/0/properties/0/damage', ContentProblemKind.invalidValue)],
  ),
  _ShapeCase(
    'a condition outside the two',
    weaponEntry(
      instead: {
        'properties': [
          {'property': 'Two-Handed', 'condition': 'sometimes'},
        ],
      },
    ),
    [('/weapons/0/properties/0/condition', ContentProblemKind.invalidValue)],
  ),
  _ShapeCase(
    'a Two-Handed property with unless mounted',
    weaponEntry(
      instead: {
        'properties': [
          {'property': 'Two-Handed', 'condition': 'unless mounted'},
        ],
      },
    ),
    null,
  ),
  _ShapeCase(
    'an empty properties list',
    weaponEntry(instead: {'properties': <Object?>[]}),
    null,
  ),
  _ShapeCase(
    'an unknown mastery',
    weaponEntry(instead: {'mastery': 'Sneaky'}),
    [('/weapons/0/mastery', ContentProblemKind.invalidValue)],
  ),
  _ShapeCase('a negative weight', weaponEntry(instead: {'weightPounds': -1}), [
    ('/weapons/0/weightPounds', ContentProblemKind.outOfRange),
  ]),
  _ShapeCase(
    'no weightPounds at all',
    weaponEntry(without: const {'weightPounds'}),
    null,
  ),
  _ShapeCase(
    'a weightVaries flag',
    weaponEntry(instead: {'weightVaries': true}),
    [('/weapons/0/weightVaries', ContentProblemKind.constraintViolation)],
  ),
  _ShapeCase('a costVaries flag', weaponEntry(instead: {'costVaries': true}), [
    ('/weapons/0/costVaries', ContentProblemKind.constraintViolation),
  ]),
  _ShapeCase(
    'a negative cost amount',
    weaponEntry(
      instead: {
        'cost': {'amount': -1, 'coin': 'GP'},
      },
    ),
    [('/weapons/0/cost/amount', ContentProblemKind.outOfRange)],
  ),
  _ShapeCase(
    'an unknown coin',
    weaponEntry(
      instead: {
        'cost': {'amount': 1, 'coin': 'gp'},
      },
    ),
    [('/weapons/0/cost/coin', ContentProblemKind.invalidValue)],
  ),
  _ShapeCase(
    'a cost without a coin',
    weaponEntry(
      instead: {
        'cost': {'amount': 1},
      },
    ),
    [('/weapons/0/cost/coin', ContentProblemKind.missingField)],
  ),
  _ShapeCase(
    'a cost with an unknown rate',
    weaponEntry(
      instead: {
        'cost': {'amount': 1, 'coin': 'SP', 'per': 'Week'},
      },
    ),
    [('/weapons/0/cost/per', ContentProblemKind.invalidValue)],
  ),
];

final List<_ShapeCase> _armorCases = [
  _ShapeCase(
    'an unknown category',
    armorEntry(instead: {'category': 'Cloth'}),
    [('/armor/0/category', ContentProblemKind.invalidValue)],
  ),
  _ShapeCase(
    'an armorClass with neither shape',
    armorEntry(instead: {'armorClass': <String, Object?>{}}),
    [('/armor/0/armorClass', ContentProblemKind.missingField)],
  ),
  _ShapeCase(
    'an armorClass with both shapes',
    armorEntry(
      instead: {
        'armorClass': {'base': 18, 'dexterity': 'none', 'bonus': 2},
      },
    ),
    [('/armor/0/armorClass', ContentProblemKind.constraintViolation)],
  ),
  _ShapeCase(
    'a base of zero',
    armorEntry(
      instead: {
        'armorClass': {'base': 0, 'dexterity': 'full'},
      },
    ),
    [('/armor/0/armorClass/base', ContentProblemKind.outOfRange)],
  ),
  _ShapeCase(
    'a base above 30',
    armorEntry(
      instead: {
        'armorClass': {'base': 31, 'dexterity': 'full'},
      },
    ),
    [('/armor/0/armorClass/base', ContentProblemKind.outOfRange)],
  ),
  _ShapeCase(
    'an unknown dexterity treatment',
    armorEntry(
      instead: {
        'armorClass': {'base': 11, 'dexterity': 'halved'},
      },
    ),
    [('/armor/0/armorClass/dexterity', ContentProblemKind.invalidValue)],
  ),
  _ShapeCase(
    'capped without a maximum',
    armorEntry(
      instead: {
        'armorClass': {'base': 15, 'dexterity': 'capped'},
      },
    ),
    [('/armor/0/armorClass/maximum', ContentProblemKind.missingField)],
  ),
  _ShapeCase(
    'capped with a negative maximum',
    armorEntry(
      instead: {
        'armorClass': {'base': 15, 'dexterity': 'capped', 'maximum': -1},
      },
    ),
    [('/armor/0/armorClass/maximum', ContentProblemKind.outOfRange)],
  ),
  _ShapeCase(
    'a maximum with full dexterity',
    armorEntry(
      instead: {
        'armorClass': {'base': 11, 'dexterity': 'full', 'maximum': 2},
      },
    ),
    [('/armor/0/armorClass/maximum', ContentProblemKind.constraintViolation)],
  ),
  _ShapeCase(
    'a bonus outside 1 to 10',
    armorEntry(
      instead: {
        'armorClass': {'bonus': 0},
      },
    ),
    [('/armor/0/armorClass/bonus', ContentProblemKind.outOfRange)],
  ),
  _ShapeCase(
    'a bonus on body armor',
    armorEntry(
      instead: {
        'armorClass': {'bonus': 2},
      },
    ),
    [('/armor/0/armorClass', ContentProblemKind.constraintViolation)],
  ),
  _ShapeCase(
    'a base rule on a Shield',
    armorEntry(
      instead: {
        'category': 'Shield',
        'armorClass': {'base': 2, 'dexterity': 'full'},
      },
    ),
    [('/armor/0/armorClass', ContentProblemKind.constraintViolation)],
  ),
  _ShapeCase(
    'a valid Shield',
    armorEntry(
      instead: {
        'category': 'Shield',
        'armorClass': {'bonus': 2},
        'stealthDisadvantage': false,
        'weightPounds': 6,
        'cost': {'amount': 10, 'coin': 'GP'},
      },
    ),
    null,
  ),
  _ShapeCase(
    'a strength requirement of zero',
    armorEntry(instead: {'strengthRequirement': 0}),
    [('/armor/0/strengthRequirement', ContentProblemKind.outOfRange)],
  ),
  _ShapeCase(
    'a strength requirement above 30',
    armorEntry(instead: {'strengthRequirement': 31}),
    [('/armor/0/strengthRequirement', ContentProblemKind.outOfRange)],
  ),
  _ShapeCase(
    'a fractional strength requirement',
    armorEntry(instead: {'strengthRequirement': 13.5}),
    [('/armor/0/strengthRequirement', ContentProblemKind.wrongType)],
  ),
  _ShapeCase(
    'a non-boolean stealth disadvantage',
    armorEntry(instead: {'stealthDisadvantage': 'yes'}),
    [('/armor/0/stealthDisadvantage', ContentProblemKind.wrongType)],
  ),
];
