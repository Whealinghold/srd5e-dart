import 'package:srd5e/src/content/adapters/json_content_set_decoder.dart';
import 'package:srd5e/src/content/application/content_decode_result.dart';
import 'package:srd5e/src/content/domain/content_problem_kind.dart';
import 'package:srd5e/src/content/domain/content_set_validation.dart';
import 'package:srd5e/src/content/domain/spells/spell.dart';
import 'package:srd5e/src/content/domain/validate_content_set.dart';
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

Spell decodedSpell(ContentDecodeResult result) =>
    ((result as ContentDecoded).contentSet.entries.single) as Spell;

/// The entry's field [key] set to [value] — the "otherwise valid spell 0"
/// of the case table with one change (content-spells.md, "Cases: spell
/// JSON").
Map<String, Object?> spellWith(String key, Object? value) =>
    spellEntry(instead: {key: value});

void main() {
  /// Requirement: doc/specs/content-spells.md FR-107 - a valid spell with
  ///   every optional key and no citation decodes; the old shape's
  ///   `higherLevelSlot` is unknownField.
  /// Path: happy
  test('a valid spell with the optional keys decodes', () {
    final result = decoder.decode(
      documentOf(
        'spells',
        spellEntry(
          instead: {
            'higherLevel': [
              {
                'kind': 'paragraph',
                'text': 'When you cast this spell using a higher slot.',
              },
            ],
            'cantripUpgrade': [
              {'kind': 'paragraph', 'text': 'Upgrade paragraph.'},
            ],
          },
        ),
      ),
    );
    expectDecoded(result, 1);
    final spell = decodedSpell(result);
    expect(spell.higherLevel, hasLength(1));
    expect(spell.cantripUpgrade, hasLength(1));
    expect(spell.key.kind.name, 'spell');
  });

  /// Requirement: doc/specs/content-spells.md FR-107 - the old shape's
  ///   `higherLevelSlot` key is unknownField (FR-022).
  /// Path: unhappy (invalid input)
  test('the old shape key higherLevelSlot is unknownField', () {
    expectProblems(
      decoder.decode(
        documentOf('spells', spellWith('higherLevelSlot', 'When you cast...')),
      ),
      [('/spells/0/higherLevelSlot', ContentProblemKind.unknownField)],
    );
  });

  /// The "Cases: spell JSON" rows: the otherwise valid spell 0 with one
  /// change; the constructor verdicts are the agreement test's (schema
  /// FR-094; content-spells.md FR-107, FR-108, FR-109, FR-110, FR-111,
  /// FR-113).
  final cases =
      <(String, Map<String, Object?>, List<(String, ContentProblemKind)>?)>[
        ('valid minimal', spellEntry(), null),
        (
          'level too high',
          spellWith('level', 10),
          [('/spells/0/level', ContentProblemKind.outOfRange)],
        ),
        (
          'level negative',
          spellWith('level', -1),
          [('/spells/0/level', ContentProblemKind.outOfRange)],
        ),
        ('level 9', spellWith('level', 9), null),
        (
          'level a string',
          spellWith('level', '3'),
          [('/spells/0/level', ContentProblemKind.wrongType)],
        ),
        (
          'level absent',
          spellEntry(without: const {'level'}),
          [('/spells/0/level', ContentProblemKind.missingField)],
        ),
        (
          'unknown school',
          spellWith('school', 'Lore'),
          [('/spells/0/school', ContentProblemKind.invalidValue)],
        ),
        (
          'school wrong case',
          spellWith('school', 'evocation'),
          [('/spells/0/school', ContentProblemKind.invalidValue)],
        ),
        (
          'class repeated',
          spellWith('classes', ['wizard', 'wizard']),
          [('/spells/0/classes/1', ContentProblemKind.duplicate)],
        ),
        (
          'class not an id',
          spellWith('classes', ['Wizard']),
          [('/spells/0/classes/0', ContentProblemKind.invalidValue)],
        ),
        (
          'class unknown to the document',
          spellWith('classes', ['unknown_class']),
          null,
        ),
        (
          'no casting time',
          spellWith('castingTimes', <Object?>[]),
          [('/spells/0/castingTimes', ContentProblemKind.outOfRange)],
        ),
        (
          'unknown casting kind',
          spellWith('castingTimes', [
            {'kind': 'bonus'},
          ]),
          [('/spells/0/castingTimes/0/kind', ContentProblemKind.invalidValue)],
        ),
        (
          'reaction without trigger',
          spellWith('castingTimes', [
            {'kind': 'reaction'},
          ]),
          [
            (
              '/spells/0/castingTimes/0/trigger',
              ContentProblemKind.missingField,
            ),
          ],
        ),
        (
          'reaction blank trigger',
          spellWith('castingTimes', [
            {'kind': 'reaction', 'trigger': ' '},
          ]),
          [
            (
              '/spells/0/castingTimes/0/trigger',
              ContentProblemKind.invalidValue,
            ),
          ],
        ),
        (
          'minutes zero',
          spellWith('castingTimes', [
            {'kind': 'minutes', 'amount': 0},
          ]),
          [('/spells/0/castingTimes/0/amount', ContentProblemKind.outOfRange)],
        ),
        (
          'amount on an action',
          spellWith('castingTimes', [
            {'kind': 'magicAction', 'amount': 5},
          ]),
          [
            (
              '/spells/0/castingTimes/0/amount',
              ContentProblemKind.unknownField,
            ),
          ],
        ),
        (
          'label on the only option',
          spellWith('castingTimes', [
            {'kind': 'magicAction', 'label': 'Solo'},
          ]),
          [
            (
              '/spells/0/castingTimes/0/label',
              ContentProblemKind.constraintViolation,
            ),
          ],
        ),
        (
          'second mode unlabelled',
          spellWith('castingTimes', [
            {'kind': 'magicAction', 'label': 'First'},
            {'kind': 'hours', 'amount': 8},
          ]),
          [('/spells/0/castingTimes/1/label', ContentProblemKind.missingField)],
        ),
        (
          'blank mode label',
          spellWith('castingTimes', [
            {'kind': 'magicAction', 'label': 'First'},
            {'kind': 'hours', 'amount': 8, 'label': ''},
          ]),
          [('/spells/0/castingTimes/1/label', ContentProblemKind.invalidValue)],
        ),
        (
          'two labelled modes',
          spellWith('castingTimes', [
            {'kind': 'magicAction', 'label': 'First'},
            {'kind': 'hours', 'amount': 8, 'label': 'Second'},
          ]),
          null,
        ),
        (
          'distance zero',
          spellWith('range', {'kind': 'distance', 'amount': 0, 'unit': 'feet'}),
          [('/spells/0/range/amount', ContentProblemKind.outOfRange)],
        ),
        (
          'distance unit unknown',
          spellWith('range', {
            'kind': 'distance',
            'amount': 30,
            'unit': 'furlongs',
          }),
          [('/spells/0/range/unit', ContentProblemKind.invalidValue)],
        ),
        (
          'distance without unit',
          spellWith('range', {'kind': 'distance', 'amount': 5}),
          [('/spells/0/range/unit', ContentProblemKind.missingField)],
        ),
        (
          'unit on self',
          spellWith('range', {'kind': 'self', 'unit': 'feet'}),
          [('/spells/0/range/unit', ContentProblemKind.unknownField)],
        ),
        (
          'verbal not a boolean',
          spellWith('components', {
            'verbal': 'yes',
            'somatic': true,
            'material': {
              'description': 'A pinch of powder.',
              'costsGp': <int>[],
              'consumesMaterial': false,
            },
          }),
          [('/spells/0/components/verbal', ContentProblemKind.wrongType)],
        ),
        (
          'empty material',
          spellWith('components', {
            'verbal': true,
            'somatic': true,
            'material': {
              'description': '',
              'costsGp': <int>[],
              'consumesMaterial': false,
            },
          }),
          [
            (
              '/spells/0/components/material/description',
              ContentProblemKind.invalidValue,
            ),
          ],
        ),
        (
          'cost zero',
          spellWith('components', {
            'verbal': true,
            'somatic': true,
            'material': {
              'description': 'A pinch of powder.',
              'costsGp': [0],
              'consumesMaterial': false,
            },
          }),
          [
            (
              '/spells/0/components/material/costsGp/0',
              ContentProblemKind.outOfRange,
            ),
          ],
        ),
        (
          'timed without amount',
          spellWith('duration', {
            'kind': 'timed',
            'unit': 'hours',
            'limit': 'fixed',
          }),
          [('/spells/0/duration/amount', ContentProblemKind.missingField)],
        ),
        (
          'timed zero',
          spellWith('duration', {
            'kind': 'timed',
            'amount': 0,
            'unit': 'hours',
            'limit': 'fixed',
          }),
          [('/spells/0/duration/amount', ContentProblemKind.outOfRange)],
        ),
        (
          'concentration without a cap',
          spellWith('duration', {
            'kind': 'timed',
            'amount': 1,
            'unit': 'hours',
            'limit': 'concentration',
          }),
          [('/spells/0/duration/limit', ContentProblemKind.invalidValue)],
        ),
        (
          'timed concentration',
          spellWith('duration', {
            'kind': 'timed',
            'amount': 1,
            'unit': 'hours',
            'limit': 'concentrationUpTo',
          }),
          null,
        ),
        (
          'amount on instantaneous',
          spellWith('duration', {'kind': 'instantaneous', 'amount': 1}),
          [('/spells/0/duration/amount', ContentProblemKind.unknownField)],
        ),
        (
          'description empty',
          spellWith('description', <Object?>[]),
          [('/spells/0/description', ContentProblemKind.outOfRange)],
        ),
        (
          'blank paragraph',
          spellWith('description', [
            {'kind': 'paragraph', 'text': '  '},
          ]),
          [('/spells/0/description/0/text', ContentProblemKind.invalidValue)],
        ),
        (
          'unknown block kind',
          spellWith('description', [
            {'kind': 'quote', 'text': 'x'},
          ]),
          [('/spells/0/description/0/kind', ContentProblemKind.invalidValue)],
        ),
        (
          'ragged table',
          spellWith('description', [
            {
              'kind': 'table',
              'header': ['One', 'Two'],
              'rows': [
                ['a', 'b'],
                ['c', 'd', 'e'],
              ],
            },
          ]),
          [
            (
              '/spells/0/description/0/rows/1',
              ContentProblemKind.constraintViolation,
            ),
          ],
        ),
        (
          'table without rows',
          spellWith('description', [
            {
              'kind': 'table',
              'header': ['One'],
              'rows': <Object?>[],
            },
          ]),
          [('/spells/0/description/0/rows', ContentProblemKind.outOfRange)],
        ),
        (
          'empty higher-level text',
          spellWith('higherLevel', <Object?>[]),
          [('/spells/0/higherLevel', ContentProblemKind.outOfRange)],
        ),
        (
          'id not valid',
          spellWith('id', 'Acid-Arrow'),
          [('/spells/0/id', ContentProblemKind.invalidValue)],
        ),
        (
          'name padded',
          spellWith('name', ' Acid Arrow'),
          [('/spells/0/name', ContentProblemKind.invalidValue)],
        ),
        (
          'citation page zero',
          spellWith('source', {'document': 'd', 'section': 's', 'page': 0}),
          [('/spells/0/source/page', ContentProblemKind.outOfRange)],
        ),
        (
          'citation section absent',
          spellWith('source', {'document': 'd', 'page': 1}),
          [('/spells/0/source/section', ContentProblemKind.missingField)],
        ),
        (
          'citation blank document',
          spellWith('source', {'document': ' ', 'section': 's', 'page': 1}),
          [('/spells/0/source/document', ContentProblemKind.invalidValue)],
        ),
        ('citation absent', spellEntry(), null),
        (
          'two problems, one spell',
          spellEntry(instead: const {'level': 10, 'school': 'Lore'}),
          [
            ('/spells/0/level', ContentProblemKind.outOfRange),
            ('/spells/0/school', ContentProblemKind.invalidValue),
          ],
        ),
      ];

  /// Requirement: per case - doc/specs/content-spells.md FR-107, FR-108,
  ///   FR-109, FR-110, FR-111, FR-113 - "Cases: spell JSON" decode halves.
  /// Path: per case
  for (final c in cases) {
    test(
      'Cases spell JSON: ${c.$1} [${c.$3 == null ? 'happy' : 'unhappy'}]',
      () {
        final result = decoder.decode(documentOf('spells', c.$2));
        if (c.$3 == null) {
          expectDecoded(result, 1);
        } else {
          expectProblems(result, c.$3!);
        }
      },
    );
  }

  /// Requirement: doc/specs/content-spells.md FR-107, FR-016 (of the
  ///   schema spec) - the field problems of one spell are reported in the
  ///   declared key order.
  /// Path: unhappy (invalid input)
  test('spell problems follow the declared key order', () {
    final result = decoder.decode(
      documentOf(
        'spells',
        spellEntry(
          without: const {'school'},
          instead: const {
            'level': 11,
            'ritual': 'yes',
            'description': <Object?>[],
          },
        ),
      ),
    );
    expectProblems(result, [
      ('/spells/0/level', ContentProblemKind.outOfRange),
      ('/spells/0/school', ContentProblemKind.missingField),
      ('/spells/0/ritual', ContentProblemKind.wrongType),
      ('/spells/0/description', ContentProblemKind.outOfRange),
    ]);
  });

  /// Requirement: doc/specs/content-spells.md FR-107 - a wrong-typed
  ///   container is one problem, no cascade (schema FR-013).
  /// Path: unhappy (rule interaction)
  test('a wrong-typed container is one problem', () {
    final result = decoder.decode(
      documentOf('spells', spellWith('components', 'V, S')),
    );
    expectProblems(result, [
      ('/spells/0/components', ContentProblemKind.wrongType),
    ]);
  });

  /// The block wire-shape rows (schema FR-152): missing, non-string and
  /// unknown kinds; unknown keys; empty arrays outOfRange; ragged rows
  /// constraintViolation; a blank header cell invalidValue; an empty row
  /// cell accepted; every block kind decodes.
  final blockCases = <(String, Object?, List<(String, ContentProblemKind)>?)>[
    (
      'missing kind',
      {'text': 'x'},
      [('/spells/0/description/0/kind', ContentProblemKind.missingField)],
    ),
    (
      'non-string kind',
      {'kind': 1, 'text': 'x'},
      [('/spells/0/description/0/kind', ContentProblemKind.wrongType)],
    ),
    (
      'unknown key on a block',
      {'kind': 'paragraph', 'text': 'x', 'level': 1},
      [('/spells/0/description/0/level', ContentProblemKind.unknownField)],
    ),
    (
      'empty bullet list',
      {'kind': 'bulletList', 'items': <Object?>[]},
      [('/spells/0/description/0/items', ContentProblemKind.outOfRange)],
    ),
    (
      'blank bullet item',
      {
        'kind': 'bulletList',
        'items': [' '],
      },
      [('/spells/0/description/0/items/0', ContentProblemKind.invalidValue)],
    ),
    (
      'a non-string item',
      {
        'kind': 'bulletList',
        'items': [1],
      },
      [('/spells/0/description/0/items/0', ContentProblemKind.wrongType)],
    ),
    (
      'blank header cell',
      {
        'kind': 'table',
        'header': [' '],
        'rows': [
          ['x'],
        ],
      },
      [('/spells/0/description/0/header/0', ContentProblemKind.invalidValue)],
    ),
    (
      'a non-string cell',
      {
        'kind': 'table',
        'header': ['One'],
        'rows': [
          [1],
        ],
      },
      [('/spells/0/description/0/rows/0/0', ContentProblemKind.wrongType)],
    ),
    (
      'a blank title',
      {
        'kind': 'table',
        'title': ' ',
        'header': ['One'],
        'rows': [
          ['x'],
        ],
      },
      [('/spells/0/description/0/title', ContentProblemKind.invalidValue)],
    ),
    (
      'empty stat block',
      {'kind': 'embeddedStatBlock', 'lines': <Object?>[]},
      [('/spells/0/description/0/lines', ContentProblemKind.outOfRange)],
    ),
    (
      'entry block',
      {'kind': 'entry', 'name': 'At Higher Levels', 'text': 'The text.'},
      null,
    ),
    (
      'entry with padded name',
      {'kind': 'entry', 'name': ' Padded ', 'text': 'The text.'},
      [('/spells/0/description/0/name', ContentProblemKind.invalidValue)],
    ),
    (
      'an empty table cell is accepted',
      {
        'kind': 'table',
        'header': ['One', 'Two'],
        'rows': [
          ['x', ''],
        ],
      },
      null,
    ),
    (
      'a blank body cell',
      {
        'kind': 'table',
        'header': ['One'],
        'rows': [
          [' '],
        ],
      },
      [('/spells/0/description/0/rows/0/0', ContentProblemKind.invalidValue)],
    ),
  ];

  /// Requirement: per case - doc/specs/content-schema-and-decoder.md
  ///   FR-152 - the block wire shape.
  /// Path: per case
  for (final c in blockCases) {
    test('block: ${c.$1} [${c.$3 == null ? 'happy' : 'unhappy'}]', () {
      final result = decoder.decode(
        documentOf('spells', spellWith('description', [c.$2!])),
      );
      if (c.$3 == null) {
        expectDecoded(result, 1);
      } else {
        expectProblems(result, c.$3!);
      }
    });
  }

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-035,
  ///   FR-036 - one document is only part of the set: a backgrounds-only
  ///   document decodes with no problem about its feat, though no feat is
  ///   in the document; the Origin rule is the whole-set validation's
  ///   (reported here as unresolvedReference when no set holds the feat).
  /// Path: unhappy (missing content)
  test(
    'a backgrounds-only document decodes clean, the Origin rule is whole-set',
    () {
      final result = decoder.decode(
        documentOf('backgrounds', backgroundEntry()),
      );
      expectDecoded(result, 1);

      final validation = validateContentSet([
        (result as ContentDecoded).contentSet,
      ]);
      expect(validation, isA<ContentSetInvalid>());
      final problems = (validation as ContentSetInvalid).problems;
      expect(problems, hasLength(1));
      expect(problems.single.kind, ContentProblemKind.unresolvedReference);
      expect(problems.single.field, 'feat/featId');
    },
  );

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-036 - when a
  ///   set holds the feat of another category, the whole-set validation
  ///   reports constraintViolation; the decoder reported nothing.
  /// Path: unhappy (rule interaction)
  test('the Origin rule is reported by validateContentSet only', () {
    final backgrounds = decoder.decode(
      documentOf('backgrounds', backgroundEntry()),
    );
    final feats = decoder.decode(
      document(
        arrays: {
          'feats': [
            featEntry(
              instead: const {'id': 'savage_attacker', 'category': 'General'},
            ),
          ],
        },
      ),
    );
    expectDecoded(backgrounds, 1);
    expectDecoded(feats, 1);

    final validation = validateContentSet([
      (backgrounds as ContentDecoded).contentSet,
      (feats as ContentDecoded).contentSet,
    ]);
    expect(validation, isA<ContentSetInvalid>());
    final problems = (validation as ContentSetInvalid).problems;
    expect(problems, hasLength(1));
    expect(problems.single.kind, ContentProblemKind.constraintViolation);
  });

  /// Requirement: doc/specs/content-classes.md FR-059, schema FR-035 - a
  ///   spell id inside an AlwaysPreparedSpells fact is not checked at
  ///   decode time; the whole-set validation reports the unresolved id as
  ///   a reference site of R1-classes-spell-sites.
  /// Path: unhappy (missing content)
  test(
    'a spell id in a class fact is a whole-set site, not a decode problem',
    () {
      final result = decoder.decode(
        documentOf(
          'classes',
          classEntry(
            instead: {
              'features': [
                ...(classEntry()['features']! as List<Object?>),
                {
                  'id': 'barbarian_prepared',
                  'name': 'Prepared Spells',
                  'level': 2,
                  'text': 'You know the following spells.',
                  'facts': [
                    {
                      'kind': 'alwaysPreparedSpells',
                      'grants': [
                        {
                          'level': 2,
                          'spellIds': ['no_such_spell'],
                        },
                      ],
                    },
                  ],
                },
              ],
              'progression': [
                for (var level = 1; level <= 20; level++)
                  {
                    'level': level,
                    'proficiencyBonus': fixtureProficiencyBonus(level),
                    'features': [
                      ...fixtureRowFeatures(level, 'barbarian_'),
                      if (level == 2) {'featureId': 'barbarian_prepared'},
                    ],
                    'values': <String, Object?>{},
                  },
              ],
            },
          ),
        ),
      );
      // The decoder alone reports nothing about the spell id.
      expectDecoded(result, 1);

      final validation = validateContentSet([
        (result as ContentDecoded).contentSet,
      ]);
      expect(validation, isA<ContentSetInvalid>());
      final problems = (validation as ContentSetInvalid).problems;
      expect(problems, hasLength(1));
      expect(problems.single.kind, ContentProblemKind.unresolvedReference);
    },
  );
}
