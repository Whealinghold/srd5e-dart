import 'package:srd5e/src/content/adapters/json_content_set_decoder.dart';
import 'package:srd5e/src/content/application/content_decode_result.dart';
import 'package:srd5e/src/content/domain/content_problem_kind.dart';
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

/// A modified row of the class fixture's progression: [instead] merged over
/// the row map and [features] replacing the row's feature list.
Map<String, Object?> rowOverride(
  int level, {
  Map<String, Object?> instead = const {},
  List<Object?>? features,
}) {
  final row = <String, Object?>{
    'level': level,
    'proficiencyBonus': fixtureProficiencyBonus(level),
    'features': features ?? fixtureRowFeatures(level, 'barbarian_'),
    'values': <String, Object?>{},
    ...instead,
  };
  if (features != null) row['features'] = features;
  return row;
}

/// The class fixture's progression with one row replaced.
List<Object?> progressionWithRow(Map<String, Object?> row) => <Object?>[
  for (var level = 1; level <= 20; level++)
    row['level'] == level ? row : rowOverride(level),
];

/// A subclass over the fixture: one feature at the class's subclass level
/// (3), its id prefixed with the subclass id (FR-070 to FR-072).
Map<String, Object?> subclass(String id) => {
  'id': id,
  'name': 'Path of Testing',
  'features': [
    {
      'id': '${id}_feature',
      'name': 'Subclass Feature',
      'level': 3,
      'text': 'You gain the subclass feature.',
    },
  ],
};

void main() {
  /// Requirement: per case - doc/specs/content-classes.md FR-002 - a class
  ///   entry carries its fields in the declared order; a required field
  ///   removed is missingField at the field's path. `toolProficiencies`,
  ///   `armorTraining`, `columns` and `subclasses` MAY be empty arrays,
  ///   which the default fixture holds and decodes (FR-002, FR-070).
  /// Path: per case
  for (final field in const [
    'primaryAbility',
    'hitPointDie',
    'savingThrowProficiencies',
    'skillChoice',
    'weaponProficiencies',
    'toolProficiencies',
    'armorTraining',
    'startingEquipment',
    'multiclassGrants',
    'columns',
    'progression',
    'features',
    'subclasses',
  ]) {
    test(
      'missing $field of classes is missingField [unhappy (missing content)]',
      () {
        expectProblems(
          decoder.decode(documentOf('classes', classEntry(without: {field}))),
          [('/classes/0/$field', ContentProblemKind.missingField)],
        );
      },
    );
  }

  /// Requirement: doc/specs/content-classes.md FR-002, schema FR-022 - an
  ///   unknown key on a class entry is unknownField.
  /// Path: unhappy (invalid input)
  test('an unknown key on a class entry is unknownField', () {
    expectProblems(
      decoder.decode(
        documentOf(
          'classes',
          classEntry(instead: const {'castingStyle': 'brutal'}),
        ),
      ),
      [('/classes/0/castingStyle', ContentProblemKind.unknownField)],
    );
  });

  /// Requirement: doc/specs/content-classes.md FR-004 - class ids are
  ///   unique (schema FR-031), the first id space reported (schema FR-016).
  /// Path: unhappy (invalid input)
  test('a duplicate class id is duplicate at the later class', () {
    final result = decoder.decode(
      document(
        arrays: {
          'classes': [
            classEntry(),
            classEntry(instead: const {'name': 'Berserker Class'}),
          ],
        },
      ),
    );
    // The class-id group first, then the feature-id group: the later
    // class's features carry the same feature ids (FR-016).
    expectProblems(result, [
      ('/classes/1/id', ContentProblemKind.duplicate),
      ('/classes/1/features/0/id', ContentProblemKind.duplicate),
      ('/classes/1/features/1/id', ContentProblemKind.duplicate),
      ('/classes/1/features/2/id', ContentProblemKind.duplicate),
    ]);
  });

  /// Requirement: doc/specs/content-classes.md FR-004 - subclass ids are
  ///   unique across the whole document, `duplicate` at the later
  ///   subclass, after the class-id duplicates (R1-classes-ids).
  /// Path: unhappy (invalid input)
  test('a subclass id repeated across the document is duplicate', () {
    final result = decoder.decode(
      documentOf(
        'classes',
        classEntry(
          instead: {
            'subclasses': [
              subclass('path_of_testing'),
              subclass('path_of_testing'),
            ],
          },
        ),
      ),
    );
    // The subclass group first, then the feature group: the later
    // subclass's feature carries the same feature id (FR-016).
    expectProblems(result, [
      ('/classes/0/subclasses/1/id', ContentProblemKind.duplicate),
      ('/classes/0/subclasses/1/features/0/id', ContentProblemKind.duplicate),
    ]);
  });

  /// Requirement: doc/specs/content-classes.md FR-004 - feature ids are
  ///   unique across all class and subclass features; the same string in
  ///   two different id spaces is accepted (a subclass id equal to the
  ///   class id is two spaces).
  /// Path: unhappy (invalid input)
  test(
    'a feature id repeated across owners is duplicate, an id space may share a string',
    () {
      final result = decoder.decode(
        documentOf(
          'classes',
          classEntry(
            instead: {
              'subclasses': [
                {
                  // A subclass whose id equals the class id: another id
                  // space, accepted (FR-004).
                  'id': 'barbarian',
                  'name': 'Path of Testing',
                  'features': [
                    {
                      // A subclass feature carrying the class feature Rage's
                      // id: the feature id space sees it twice.
                      'id': 'barbarian_rage',
                      'name': 'Subclass Feature',
                      'level': 3,
                      'text': 'You gain the subclass feature.',
                    },
                  ],
                },
              ],
            },
          ),
        ),
      );
      expectProblems(result, [
        ('/classes/0/subclasses/0/features/0/id', ContentProblemKind.duplicate),
      ]);
    },
  );

  /// Requirement: doc/specs/content-classes.md FR-004, schema FR-098 - a
  ///   subclass whose own id is invalid takes no part in the duplicate
  ///   check: two invalid ids give two invalidValue and no duplicate.
  /// Path: unhappy (invalid input)
  test('invalid subclass ids take no part in the duplicate check', () {
    final result = decoder.decode(
      documentOf(
        'classes',
        classEntry(
          instead: {
            'subclasses': [subclass('Not_An_Id'), subclass('Not_An_Id')],
          },
        ),
      ),
    );
    // The invalid subclass ids leave the group; their features' ids are
    // invalid in their own right (the prefix `Not_An_Id_` is not an id).
    // Only duplicate problems are grouped after the entry problems, so
    // these stay in field order.
    expectProblems(result, [
      ('/classes/0/subclasses/0/id', ContentProblemKind.invalidValue),
      (
        '/classes/0/subclasses/0/features/0/id',
        ContentProblemKind.invalidValue,
      ),
      ('/classes/0/subclasses/1/id', ContentProblemKind.invalidValue),
      (
        '/classes/0/subclasses/1/features/0/id',
        ContentProblemKind.invalidValue,
      ),
    ]);
  });

  /// Requirement: doc/specs/content-classes.md FR-005, FR-016 - problems
  ///   in one class entry are reported in the field order of FR-002 first,
  ///   then the entry's cross-field problems; the same text always gives
  ///   an equal result.
  /// Path: unhappy (rule interaction)
  test('problems follow the field order, then the cross-field order', () {
    final entry = classEntry(
      without: const {'hitPointDie'},
      instead: {
        'spellcasting': 'fierce',
        'progression': progressionWithRow(
          rowOverride(
            1,
            features: [
              {'featureId': 'barbarian_nothing'},
              {'featureId': 'barbarian_rage'},
            ],
          ),
        ),
      },
    );
    final text = documentOf('classes', entry);
    final expected = [
      ('/classes/0/hitPointDie', ContentProblemKind.missingField),
      ('/classes/0/spellcasting', ContentProblemKind.wrongType),
      (
        '/classes/0/progression/0/features/0/featureId',
        ContentProblemKind.unresolvedReference,
      ),
    ];
    expectProblems(decoder.decode(text), expected);
    expectProblems(decoder.decode(text), expected);
  });

  /// The Cases PR rows: the otherwise-valid class fixture with one change
  /// (content-classes.md FR-037, FR-043, FR-044, FR-045).
  final prCases =
      <(String, Map<String, Object?>, List<(String, ContentProblemKind)>?)>[
        ('exactly 20', classEntry(), null),
        (
          '19 rows',
          classEntry(
            instead: {
              'progression': [
                for (var level = 1; level <= 19; level++) rowOverride(level),
              ],
            },
          ),
          [('/classes/0/progression', ContentProblemKind.outOfRange)],
        ),
        (
          '21 rows',
          classEntry(
            instead: {
              'progression': [
                for (var level = 1; level <= 20; level++) rowOverride(level),
                rowOverride(20),
              ],
            },
          ),
          [
            (
              '/classes/0/progression/20/level',
              ContentProblemKind.invalidValue,
            ),
            ('/classes/0/progression', ContentProblemKind.outOfRange),
          ],
        ),
        (
          'level out of order',
          classEntry(
            instead: {
              'progression': [
                for (var level = 1; level <= 20; level++)
                  level == 4
                      ? rowOverride(4, instead: const {'level': 5})
                      : rowOverride(level),
              ],
            },
          ),
          [('/classes/0/progression/3/level', ContentProblemKind.invalidValue)],
        ),
        (
          'unresolved feature',
          classEntry(
            instead: {
              'progression': progressionWithRow(
                rowOverride(
                  1,
                  features: [
                    {'featureId': 'barbarian_nothing'},
                    {'featureId': 'barbarian_rage'},
                  ],
                ),
              ),
            },
          ),
          [
            (
              '/classes/0/progression/0/features/0/featureId',
              ContentProblemKind.unresolvedReference,
            ),
          ],
        ),
        (
          'entry later than row',
          classEntry(
            instead: {
              'features': [
                ...(classEntry()['features']! as List<Object?>),
                {
                  'id': 'barbarian_late',
                  'name': 'Late Feature',
                  'level': 5,
                  'text': 'You gain the late feature.',
                },
              ],
              'progression': [
                for (var level = 1; level <= 20; level++)
                  if (level == 1)
                    rowOverride(
                      1,
                      features: [
                        {'featureId': 'barbarian_late'},
                        {'featureId': 'barbarian_rage'},
                      ],
                    )
                  else if (level == 5)
                    rowOverride(
                      5,
                      features: [
                        {'featureId': 'barbarian_late'},
                      ],
                    )
                  else
                    rowOverride(level),
              ],
            },
          ),
          [
            (
              '/classes/0/progression/0/features/0/featureId',
              ContentProblemKind.constraintViolation,
            ),
          ],
        ),
        (
          'entry never listed',
          classEntry(
            instead: {
              'features': [
                ...(classEntry()['features']! as List<Object?>),
                {
                  'id': 'barbarian_unlisted',
                  'name': 'Unlisted Feature',
                  'level': 2,
                  'text': 'You gain the unlisted feature.',
                },
              ],
            },
          ),
          [
            (
              '/classes/0/features/3/level',
              ContentProblemKind.constraintViolation,
            ),
          ],
        ),
        (
          'two subclass markers',
          classEntry(
            instead: {
              'progression': progressionWithRow(
                rowOverride(
                  5,
                  features: [
                    {'kind': 'subclassFeature'},
                    {'kind': 'subclassFeature'},
                  ],
                ),
              ),
            },
          ),
          [
            (
              '/classes/0/progression/4/features/1',
              ContentProblemKind.duplicate,
            ),
          ],
        ),
        (
          'empty cell',
          classEntry(
            instead: {
              'progression': progressionWithRow(
                rowOverride(8, features: <Object?>[]),
              ),
            },
          ),
          null,
        ),
        (
          'blank annotation',
          classEntry(
            instead: {
              'progression': progressionWithRow(
                rowOverride(
                  1,
                  features: [
                    {'featureId': 'barbarian_rage', 'annotation': ' '},
                  ],
                ),
              ),
            },
          ),
          [
            (
              '/classes/0/progression/0/features/0/annotation',
              ContentProblemKind.invalidValue,
            ),
          ],
        ),
        (
          'wrong container',
          classEntry(instead: const {'progression': 'twenty rows'}),
          [('/classes/0/progression', ContentProblemKind.wrongType)],
        ),
      ];

  /// Requirement: per case - doc/specs/content-classes.md FR-037, FR-043,
  ///   FR-044, FR-045 - Cases PR: the progression, rows and references
  ///   decode halves.
  /// Path: per case
  for (final c in prCases) {
    test('Cases PR: ${c.$1} [${c.$3 == null ? 'happy' : 'unhappy'}]', () {
      final result = decoder.decode(documentOf('classes', c.$2));
      if (c.$3 == null) {
        expectDecoded(result, 1);
      } else {
        expectProblems(result, c.$3!);
      }
    });
  }

  /// Requirement: doc/specs/content-classes.md FR-006, schema FR-013 - a
  ///   features element that is not an object is one wrongType at its
  ///   index, no cascade.
  /// Path: unhappy (rule interaction)
  test('a features element that is not an object is one wrongType', () {
    final features = classEntry()['features']! as List<Object?>;
    final result = decoder.decode(
      documentOf(
        'classes',
        classEntry(
          instead: {
            'features': ['Rage', ...features],
          },
        ),
      ),
    );
    expectProblems(result, [
      ('/classes/0/features/0', ContentProblemKind.wrongType),
    ]);
  });

  /// The Cases SP rows: the otherwise-valid spellcasting fixture with one
  /// change (content-classes.md FR-030, FR-031, FR-032).
  final spCases =
      <(String, Map<String, Object?>, List<(String, ContentProblemKind)>?)>[
        ('nine slots', casterClassEntry(), null),
        (
          'eight slots',
          casterClassEntry(
            rowSpellcasting: (level) => level == 1
                ? {
                    'cantrips': 2,
                    'preparedSpells': 4,
                    'spellSlots': <int>[2, 0, 0, 0, 0, 0, 0, 0],
                  }
                : null,
          ),
          [
            (
              '/classes/0/progression/0/spellcasting/spellSlots',
              ContentProblemKind.outOfRange,
            ),
          ],
        ),
        (
          'negative slot',
          casterClassEntry(
            rowSpellcasting: (level) => level == 1
                ? {
                    'cantrips': 2,
                    'preparedSpells': 4,
                    'spellSlots': <int>[-1, 0, 0, 0, 0, 0, 0, 0, 0],
                  }
                : null,
          ),
          [
            (
              '/classes/0/progression/0/spellcasting/spellSlots/0',
              ContentProblemKind.outOfRange,
            ),
          ],
        ),
        (
          'cantrips missing',
          casterClassEntry(
            rowSpellcasting: (level) => level == 1
                ? {
                    'preparedSpells': 4,
                    'spellSlots': <int>[2, 0, 0, 0, 0, 0, 0, 0, 0],
                  }
                : null,
          ),
          [
            (
              '/classes/0/progression/0/spellcasting/cantrips',
              ContentProblemKind.missingField,
            ),
          ],
        ),
        (
          'cantrips on Paladin',
          casterClassEntry(
            cantrips: false,
            rowSpellcasting: (level) => level == 1
                ? {
                    'cantrips': 2,
                    'preparedSpells': 4,
                    'spellSlots': <int>[2, 0, 0, 0, 0, 0, 0, 0, 0],
                  }
                : null,
          ),
          [
            (
              '/classes/0/progression/0/spellcasting/cantrips',
              ContentProblemKind.constraintViolation,
            ),
          ],
        ),
        (
          'pact row on slot class',
          casterClassEntry(
            rowSpellcasting: (level) => level == 1
                ? {
                    'cantrips': 2,
                    'preparedSpells': 1,
                    'spellSlots': 2,
                    'slotLevel': 1,
                  }
                : null,
          ),
          [
            (
              '/classes/0/progression/0/spellcasting',
              ContentProblemKind.constraintViolation,
            ),
          ],
        ),
        (
          'row part on a non-caster',
          classEntry(
            instead: {
              'progression': progressionWithRow(
                rowOverride(
                  1,
                  instead: {
                    'spellcasting': {
                      'cantrips': 2,
                      'preparedSpells': 4,
                      'spellSlots': <int>[2, 0, 0, 0, 0, 0, 0, 0, 0],
                    },
                  },
                ),
              ),
            },
          ),
          [
            (
              '/classes/0/progression/0/spellcasting',
              ContentProblemKind.constraintViolation,
            ),
          ],
        ),
        (
          'slot level 0',
          casterClassEntry(
            kind: 'pact',
            rowSpellcasting: (level) => level == 1
                ? {
                    'cantrips': 2,
                    'preparedSpells': 1,
                    'spellSlots': 2,
                    'slotLevel': 0,
                  }
                : null,
          ),
          [
            (
              '/classes/0/progression/0/spellcasting/slotLevel',
              ContentProblemKind.outOfRange,
            ),
          ],
        ),
        (
          'slot level 10',
          casterClassEntry(
            kind: 'pact',
            rowSpellcasting: (level) => level == 1
                ? {
                    'cantrips': 2,
                    'preparedSpells': 1,
                    'spellSlots': 2,
                    'slotLevel': 10,
                  }
                : null,
          ),
          [
            (
              '/classes/0/progression/0/spellcasting/slotLevel',
              ContentProblemKind.outOfRange,
            ),
          ],
        ),
        (
          'slot level 9',
          casterClassEntry(
            kind: 'pact',
            rowSpellcasting: (level) => level == 1
                ? {
                    'cantrips': 2,
                    'preparedSpells': 1,
                    'spellSlots': 2,
                    'slotLevel': 9,
                  }
                : null,
          ),
          null,
        ),
      ];

  /// Requirement: per case - doc/specs/content-classes.md FR-030, FR-031,
  ///   FR-032 - Cases SP: the spellcasting rows decode halves.
  /// Path: per case
  for (final c in spCases) {
    test('Cases SP: ${c.$1} [${c.$3 == null ? 'happy' : 'unhappy'}]', () {
      final result = decoder.decode(documentOf('classes', c.$2));
      if (c.$3 == null) {
        expectDecoded(result, 1);
      } else {
        expectProblems(result, c.$3!);
      }
    });
  }

  /// The Cases CV rows: column values under their declared kinds; the
  /// printed em dash is ColumnNone under every kind (content-classes.md
  /// FR-039, FR-040).
  final cvCases =
      <(String, String, Object?, Object?, List<(String, ContentProblemKind)>?)>[
        ('count', 'count', 2, 2, null),
        ('count zero', 'count', 2, 0, null),
        (
          'count negative',
          'count',
          2,
          -1,
          [
            (
              '/classes/0/progression/0/values/rages',
              ContentProblemKind.outOfRange,
            ),
          ],
        ),
        (
          'count as string',
          'count',
          2,
          '2',
          [
            (
              '/classes/0/progression/0/values/rages',
              ContentProblemKind.wrongType,
            ),
          ],
        ),
        (
          'dice',
          'dice',
          const {'count': 1, 'sides': 6},
          const {'count': 1, 'sides': 6},
          null,
        ),
        (
          'dice zero count',
          'dice',
          const {'count': 1, 'sides': 6},
          const {'count': 0, 'sides': 6},
          [
            (
              '/classes/0/progression/0/values/rages/count',
              ContentProblemKind.outOfRange,
            ),
          ],
        ),
        (
          'dice one side',
          'dice',
          const {'count': 1, 'sides': 6},
          const {'count': 1, 'sides': 1},
          [
            (
              '/classes/0/progression/0/values/rages/sides',
              ContentProblemKind.outOfRange,
            ),
          ],
        ),
        (
          'integer for dice',
          'dice',
          const {'count': 1, 'sides': 6},
          6,
          [
            (
              '/classes/0/progression/0/values/rages',
              ContentProblemKind.wrongType,
            ),
          ],
        ),
        ('bonus', 'bonus', 2, 2, null),
        ('feet bonus', 'feetBonus', 10, 10, null),
        ('none, count', 'count', 2, '—', null),
        ('none, dice', 'dice', const {'count': 1, 'sides': 6}, '—', null),
        (
          'hyphen for none',
          'count',
          2,
          '-',
          [
            (
              '/classes/0/progression/0/values/rages',
              ContentProblemKind.invalidValue,
            ),
          ],
        ),
        (
          'object for count',
          'count',
          2,
          const {'count': 1, 'sides': 6},
          [
            (
              '/classes/0/progression/0/values/rages',
              ContentProblemKind.wrongType,
            ),
          ],
        ),
      ];

  /// Requirement: per case - doc/specs/content-classes.md FR-039, FR-040
  ///   - Cases CV: the column values decode halves.
  /// Path: per case
  for (final c in cvCases) {
    test('Cases CV: ${c.$1} [${c.$5 == null ? 'happy' : 'unhappy'}]', () {
      final entry = columnedClassEntry(
        kind: c.$2,
        defaultValue: c.$3,
        overrides: {1: ?c.$4},
      );
      final result = decoder.decode(documentOf('classes', entry));
      if (c.$5 == null) {
        expectDecoded(result, 1);
      } else {
        expectProblems(result, c.$5!);
      }
    });
  }

  /// Requirement: doc/specs/content-classes.md FR-039 - a row's values
  ///   carry exactly one key per declared column: an undeclared key is
  ///   unknownField at `values/<id>`, a missing declared column
  ///   missingField there.
  /// Path: unhappy (missing content)
  test('a row exceeding and missing the declared columns', () {
    final entry = columnedClassEntry(kind: 'count', defaultValue: 2);
    final progression = entry['progression']! as List<Object?>;
    progression[0] = {
      ...(progression[0]! as Map<String, Object?>),
      'values': <String, Object?>{'luck': 3},
    };
    final result = decoder.decode(documentOf('classes', entry));
    expectProblems(result, [
      (
        '/classes/0/progression/0/values/rages',
        ContentProblemKind.missingField,
      ),
      ('/classes/0/progression/0/values/luck', ContentProblemKind.unknownField),
    ]);
  });

  /// Requirement: doc/specs/content-classes.md FR-036, FR-038 - a column
  ///   header breaks the name rule (invalidValue) and a Proficiency Bonus
  ///   below one is outOfRange.
  /// Path: unhappy (invalid input)
  test('a blank column header and a low Proficiency Bonus', () {
    final result = decoder.decode(
      documentOf(
        'classes',
        classEntry(
          instead: {
            'columns': [
              {'id': 'rages', 'header': ' ', 'kind': 'count'},
            ],
            'progression': [
              for (var level = 1; level <= 20; level++)
                {
                  'level': level,
                  'proficiencyBonus': level == 1
                      ? 0
                      : fixtureProficiencyBonus(level),
                  'features': fixtureRowFeatures(level, 'barbarian_'),
                  'values': <String, Object?>{'rages': 2},
                },
            ],
          },
        ),
      ),
    );
    expectProblems(result, [
      ('/classes/0/columns/0/header', ContentProblemKind.invalidValue),
      (
        '/classes/0/progression/0/proficiencyBonus',
        ContentProblemKind.outOfRange,
      ),
    ]);
  });
}
