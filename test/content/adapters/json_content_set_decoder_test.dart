import 'dart:math' show Random;

import 'package:srd5e/src/content/adapters/json_content_set_decoder.dart';
import 'package:srd5e/src/content/application/content_decode_result.dart';
import 'package:srd5e/src/content/domain/content_problem_kind.dart';
import 'package:test/test.dart';

import 'document_fixtures.dart';

const decoder = JsonContentSetDecoder();

/// Asserts [result] is `ContentDecodeFailed` with exactly the given
/// (path, kind) pairs in order.
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

/// Asserts [result] is `ContentDecoded` with [entryCount] entries.
void expectDecoded(ContentDecodeResult result, int entryCount) {
  expect(result, isA<ContentDecoded>());
  expect((result as ContentDecoded).contentSet.entries, hasLength(entryCount));
}

void main() {
  /// Requirement: per case - doc/specs/content-schema-and-decoder.md FR-002 - text that is not valid JSON (including empty and whitespace-only) gives exactly one problem: path "", kind syntax.
  /// Path: per case
  for (final text in const [
    '',
    ' ',
    '\t\n',
    '{',
    '{"schemaVersion": 1',
    'nope',
  ]) {
    test(
      'not JSON: ${text.isEmpty ? '<empty>' : text} [unhappy (invalid input)]',
      () {
        expectProblems(decoder.decode(text), [('', ContentProblemKind.syntax)]);
      },
    );
  }

  /// Requirement: per case - doc/specs/content-schema-and-decoder.md FR-003 - a root value that is not an object gives exactly one problem: path "", kind wrongType.
  /// Path: per case
  for (final text in const ['[]', 'null', '1', '"text"', 'true']) {
    test('root not an object: $text [unhappy (invalid input)]', () {
      expectProblems(decoder.decode(text), [
        ('', ContentProblemKind.wrongType),
      ]);
    });
  }

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-004 - a
  ///   missing schemaVersion gives exactly one problem, and no other field
  ///   is examined.
  /// Path: unhappy (missing content)
  test('a missing schemaVersion is the only problem', () {
    expectProblems(decoder.decode('{"bogus":1}'), [
      ('/schemaVersion', ContentProblemKind.missingField),
    ]);
  });

  /// Requirement: per case - doc/specs/content-schema-and-decoder.md FR-005, FR-021 - a schemaVersion that is not a whole number is wrongType.
  /// Path: per case
  for (final version in const ['"1"', '1.5', 'null', 'true', '2.5', '"2"']) {
    test('version wrong type: $version [unhappy (invalid input)]', () {
      expectProblems(decoder.decode('{"schemaVersion":$version}'), [
        ('/schemaVersion', ContentProblemKind.wrongType),
      ]);
    });
  }

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-005, FR-021 -
  ///   1.0 is the integer 1 on every platform and is accepted.
  /// Path: unhappy (boundary)
  test('version as 1.0 is accepted on every platform', () {
    expectDecoded(decoder.decode('{"schemaVersion":1.0}'), 0);
  });

  /// Requirement: per case - doc/specs/content-schema-and-decoder.md FR-005, FR-006, FR-018 - an unsupported version, including a 20-digit literal, is unsupportedVersion, never a throw.
  /// Path: per case
  for (final version in const ['0', '2', '-1', '12345678901234567890']) {
    test('version unsupported: $version [unhappy (boundary)]', () {
      expectProblems(decoder.decode('{"schemaVersion":$version}'), [
        ('/schemaVersion', ContentProblemKind.unsupportedVersion),
      ]);
    });
  }

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-006 - no
  ///   other field is examined when the version is unsupported.
  /// Path: unhappy (rule interaction)
  test('an unsupported version stops before other fields', () {
    expectProblems(decoder.decode('{"schemaVersion":2,"bogus":1}'), [
      ('/schemaVersion', ContentProblemKind.unsupportedVersion),
    ]);
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-009 - a
  ///   minimal document decodes to a ContentSet with no entries.
  /// Path: unhappy (empty case)
  test('the minimal document decodes to an empty set', () {
    expectDecoded(decoder.decode('{"schemaVersion":1}'), 0);
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-008 - every
  ///   registered root array is accepted; an absent array means no entries
  ///   of that kind.
  /// Path: happy
  test('all registered arrays with entries decode together', () {
    final result = decoder.decode(
      document(
        arrays: {
          'species': [speciesEntry()],
          'backgrounds': [backgroundEntry()],
          'classes': [classEntry(id: 'wizard', name: 'Wizard')],
          'feats': [featEntry()],
          'spells': [spellEntry()],
          'weapons': [weaponEntry()],
          'armor': [armorEntry()],
        },
      ),
    );

    // Every registered kind's shape has landed, so all seven entries are
    // constructed (schema FR-008; revision table, section 5).
    expectDecoded(result, 7);
  });

  /// Requirement: per case - doc/specs/content-schema-and-decoder.md FR-010, FR-074 - a root key not registered is unknownField; legacy and other-edition names are never aliases.
  /// Path: per case
  for (final key in const ['races', 'race', 'raceTraits', 'bogus']) {
    test('legacy root key: $key [unhappy (invalid input)]', () {
      expectProblems(decoder.decode('{"schemaVersion":1,"$key":[]}'), [
        ('/$key', ContentProblemKind.unknownField),
      ]);
    });
  }

  /// Requirement: per case - doc/specs/content-schema-and-decoder.md FR-010, FR-014 - an unknown key's path escapes `~` and `/`.
  /// Path: per case
  for (final c in const [
    (key: 'a/b', path: '/a~1b'),
    (key: 'a~b', path: '/a~0b'),
  ]) {
    test('escaped key: ${c.key} [unhappy (boundary)]', () {
      expectProblems(decoder.decode('{"schemaVersion":1,"${c.key}":[]}'), [
        (c.path, ContentProblemKind.unknownField),
      ]);
    });
  }

  /// Requirement: per case - doc/specs/content-schema-and-decoder.md FR-011 - a root array whose value is not an array is wrongType at the field; an element that is not an object is wrongType at its index, without examining children.
  /// Path: per case
  for (final c in const [
    (document: '{"schemaVersion":1,"spells":{}}', path: '/spells'),
    (document: '{"schemaVersion":1,"spells":[1]}', path: '/spells/0'),
    (document: '{"schemaVersion":1,"spells":["x"]}', path: '/spells/0'),
  ]) {
    test('wrong container: ${c.document} [unhappy (invalid input)]', () {
      expectProblems(decoder.decode(c.document), [
        (c.path, ContentProblemKind.wrongType),
      ]);
    });
  }

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-012, FR-016 -
  ///   problems in several entries yield one problem each, in array order.
  /// Path: unhappy (invalid input)
  test(
    'two entries with one missing field each yield two problems in order',
    () {
      final result = decoder.decode(
        document(
          arrays: {
            'species': [
              speciesEntry(without: const {'speed'}),
              speciesEntry(id: 'dwarf'),
              speciesEntry(id: 'gnome'),
              speciesEntry(id: 'orc', without: const {'speed'}),
            ],
          },
        ),
      );

      expectProblems(result, [
        ('/species/0/speed', ContentProblemKind.missingField),
        ('/species/3/speed', ContentProblemKind.missingField),
      ]);
    },
  );

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-013 - a value
  ///   of the wrong type yields one problem for itself, none for its
  ///   children.
  /// Path: unhappy (rule interaction)
  test('no cascade: a string where an array belongs is one problem', () {
    final result = decoder.decode(
      documentOf('species', speciesEntry(instead: {'sizes': 'Medium'})),
    );

    expectProblems(result, [
      ('/species/0/sizes', ContentProblemKind.wrongType),
    ]);
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-022 - an
  ///   unknown key is reported at any depth, after the known fields, in
  ///   ordinal order.
  /// Path: unhappy (invalid input)
  test(
    'unknown keys inside an entry follow the known fields, in ordinal order',
    () {
      final result = decoder.decode(
        documentOf(
          'species',
          speciesEntry(
            instead: {'zebra': 1, 'abilityIncreases': 2, 'alpha': 3},
          ),
        ),
      );

      expectProblems(result, [
        ('/species/0/abilityIncreases', ContentProblemKind.unknownField),
        ('/species/0/alpha', ContentProblemKind.unknownField),
        ('/species/0/zebra', ContentProblemKind.unknownField),
      ]);
    },
  );

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-016 - root
  ///   fields are ordered schemaVersion, then the registered arrays in
  ///   revision order; a wrong-typed array reports at its turn, before
  ///   later arrays' elements and before unknown root keys.
  /// Path: happy
  test('root field order: arrays in revision order, unknown keys last', () {
    final result = decoder.decode(
      '{"schemaVersion":1,"zoo":1,"spells":{},"feats":[{"bogus":1}]}',
    );

    expectProblems(result, [
      ('/feats/0/id', ContentProblemKind.missingField),
      ('/feats/0/name', ContentProblemKind.missingField),
      ('/feats/0/category', ContentProblemKind.missingField),
      ('/feats/0/benefits', ContentProblemKind.missingField),
      ('/feats/0/repeatable', ContentProblemKind.missingField),
      ('/feats/0/bogus', ContentProblemKind.unknownField),
      ('/spells', ContentProblemKind.wrongType),
      ('/zoo', ContentProblemKind.unknownField),
    ]);
  });

  /// Requirement: per case - doc/specs/content-schema-and-decoder.md FR-021, FR-018 - integer fields take 2 and 2.0 as the same whole value on every platform; 2.5 and a string are wrongType; a 20-digit literal is outOfRange at the field, never a throw.
  /// Path: per case
  for (final c in const [
    (speed: '30', accepted: true, kind: ContentProblemKind.missingField),
    (speed: '30.0', accepted: true, kind: ContentProblemKind.missingField),
    (speed: '30.5', accepted: false, kind: ContentProblemKind.wrongType),
    (speed: '"30"', accepted: false, kind: ContentProblemKind.wrongType),
    (
      speed: '12345678901234567890',
      accepted: false,
      kind: ContentProblemKind.outOfRange,
    ),
  ]) {
    test(
      'integer form: speed ${c.speed} ${c.accepted ? 'is the whole value' : 'is ${c.kind.name}'}'
      ' [unhappy (boundary)]',
      () {
        final text = documentOf(
          'species',
          speciesEntry(),
        ).replaceFirst('"speed":30', '"speed":${c.speed}');

        final result = decoder.decode(text);

        if (c.accepted) {
          expectDecoded(result, 1);
        } else {
          expectProblems(result, [('/species/0/speed', c.kind)]);
        }
      },
    );
  }

  /// Requirement: per case - doc/specs/content-schema-and-decoder.md FR-031, FR-098 - a later entry with an id already used in the same kind is duplicate at its id, whether or not either entry has other problems; an invalid id takes no part.
  /// Path: per case
  for (final c in _duplicateCases) {
    test('duplicate ids: ${c.label} [${c.path}]', () {
      expectProblems(decoder.decode(c.document), c.expected);
    });
  }

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-032 - the
  ///   same id in two different kinds is accepted: the keys differ.
  /// Path: happy
  test('the same id under two kinds is accepted', () {
    final result = decoder.decode(
      document(
        arrays: {
          'feats': [featEntry(id: 'a', name: 'A')],
          'spells': [spellEntry(id: 'a', name: 'A')],
        },
      ),
    );

    // Both entries decode: their ContentKeys differ (FR-145).
    expectDecoded(result, 2);
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-016 - the
  ///   duplicate problems come after every entry-level problem, grouped by
  ///   ContentKind in declaration order; within equipment, the later entry
  ///   of a weapon-and-armor pair sits in `armor`.
  /// Path: happy
  test('duplicate groups follow kind order, weapons before armor', () {
    final result = decoder.decode(
      document(
        arrays: {
          'armor': [armorEntry(id: 'shared')],
          'weapons': [weaponEntry(id: 'shared')],
          'species': [speciesEntry(), speciesEntry(id: 'elf')],
          'feats': [featEntry(), featEntry()],
        },
      ),
    );

    expectProblems(result, [
      // Duplicates grouped by kind: species (kind 0), feat (kind 3),
      // equipment (kind 4) - root order (armor, weapons, species, feats)
      // plays no part.
      ('/species/1/id', ContentProblemKind.duplicate),
      ('/feats/1/id', ContentProblemKind.duplicate),
      // Inside equipment, the later position is the armor entry.
      ('/armor/0/id', ContentProblemKind.duplicate),
    ]);
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-016, FR-142 -
  ///   the case row "duplicate groups by kind": species, characterClass,
  ///   feat and spell duplicates group in declaration order whatever the
  ///   root order; within the characterClass group the class ids come
  ///   first, then the subclass ids, then the feature ids
  ///   (content-classes.md FR-004, R1-classes-ids).
  /// Path: happy
  test('duplicate groups include the class, feature and spell kinds', () {
    final duplicatedFeature = Map<String, Object?>.from(
      (classEntry()['features']! as List<Object?>).first
          as Map<String, Object?>,
    );
    final result = decoder.decode(
      document(
        arrays: {
          'spells': [
            spellEntry(),
            spellEntry(id: 'acid_arrow', name: 'Acid Arrow'),
          ],
          'species': [speciesEntry(), speciesEntry(id: 'elf')],
          'classes': [
            classEntry(),
            // A feature entry carrying the Rage id again: the feature-id
            // group sits inside the characterClass position, after the
            // class-id group.
            classEntry(
              instead: {
                'features': [
                  ...(classEntry()['features']! as List<Object?>),
                  duplicatedFeature,
                ],
              },
            ),
          ],
          'feats': [featEntry(), featEntry(id: 'alert', name: 'Alert')],
        },
      ),
    );

    expectProblems(result, [
      // Species (kind 0), then the characterClass group (kind 2): the
      // class-id duplicate of the second class first, then the feature-id
      // duplicates at their later features in document order (the second
      // class's three features share the first's ids, and the appended
      // copy repeats Rage).
      ('/species/1/id', ContentProblemKind.duplicate),
      ('/classes/1/id', ContentProblemKind.duplicate),
      ('/classes/1/features/0/id', ContentProblemKind.duplicate),
      ('/classes/1/features/1/id', ContentProblemKind.duplicate),
      ('/classes/1/features/2/id', ContentProblemKind.duplicate),
      ('/classes/1/features/3/id', ContentProblemKind.duplicate),
      // Then feat (kind 3) and spell (kind 5), both after every
      // characterClass problem.
      ('/feats/1/id', ContentProblemKind.duplicate),
      ('/spells/1/id', ContentProblemKind.duplicate),
    ]);
  });

  /// Requirement: per case - doc/specs/content-schema-and-decoder.md FR-034, FR-115 - a source object with all three parts or page 1 is accepted.
  /// Path: per case
  for (final c in const [
    (label: 'all three parts', document: 'SRD 5.2.1', section: 'Elf', page: 16),
    (label: 'page 1', document: 'Homebrew', section: 's', page: 1),
  ]) {
    test('source accepted: ${c.label} [happy]', () {
      final result = decoder.decode(
        documentOf(
          'species',
          speciesEntry(
            instead: {
              'source': {
                'document': c.document,
                'section': c.section,
                'page': c.page,
              },
            },
          ),
        ),
      );

      expectDecoded(result, 1);
    });
  }

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-034, FR-115 -
  ///   a source without the entry is accepted (FR-034 optional field).
  /// Path: happy
  test('no source at all is accepted', () {
    expectDecoded(decoder.decode(documentOf('species', speciesEntry())), 1);
  });

  /// Requirement: per case - doc/specs/content-schema-and-decoder.md FR-034, FR-022 - a broken source reports the usual field problems at its own paths.
  /// Path: per case
  for (final c in _sourceCases) {
    test('source rejected: ${c.label} [${c.path}]', () {
      expectProblems(decoder.decode(c.document), c.expected);
    });
  }

  /// Requirement: per case - doc/specs/content-schema-and-decoder.md
  ///   FR-030 - a conforming id is accepted: a letter, then letters, digits
  ///   and underscores, at most 64 characters.
  /// Path: per case
  for (final id in ['a', 'acid_arrow_2', 'a${'b' * 63}']) {
    test('id accepted: ${id.length} characters [happy]', () {
      expectDecoded(
        decoder.decode(
          documentOf('species', speciesEntry(instead: {'id': id})),
        ),
        1,
      );
    });
  }

  /// Requirement: per case - doc/specs/content-schema-and-decoder.md
  ///   FR-030 - an id outside the rule is invalidValue at its field.
  /// Path: per case
  for (final id in ['a${'b' * 64}', '2a', 'Acid', 'acid-arrow', '', ' a']) {
    test(
      'id rejected: "${id.isEmpty ? '<empty>' : id}" [unhappy (boundary)]',
      () {
        expectProblems(
          decoder.decode(
            documentOf('species', speciesEntry(instead: {'id': id})),
          ),
          [('/species/0/id', ContentProblemKind.invalidValue)],
        );
      },
    );
  }

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-072 - two
  ///   documents differing only in entry order decode to equal sets.
  /// Path: happy
  test('entry order does not change the decoded set', () {
    final first = decoder.decode(
      document(
        arrays: {
          'species': [speciesEntry(), speciesEntry(id: 'dwarf')],
          'feats': [featEntry()],
        },
      ),
    );
    final second = decoder.decode(
      document(
        arrays: {
          'feats': [featEntry()],
          'species': [speciesEntry(id: 'dwarf'), speciesEntry()],
        },
      ),
    );

    expect(first, second);
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-076 - the
  ///   decoder neither retains nor mutates its input: the same text twice,
  ///   around another document, gives equal results.
  /// Path: happy
  test('decoding is independent of previous calls', () {
    final text = documentOf('species', speciesEntry());
    final first = decoder.decode(text);
    decoder.decode(documentOf('feats', featEntry()));
    final again = decoder.decode(text);

    expect(again, first);
  });

  /// Requirement: per case - doc/specs/content-schema-and-decoder.md FR-018 - the decoder never throws for any String: a hostile corpus of malformed, deeply nested, wrong-typed and huge-numbered documents all return.
  /// Path: per case
  for (final text in hostileCorpus) {
    test('hostile corpus: ${_label(text)} [unhappy (invalid input)]', () {
      expect(decoder.decode(text), isA<ContentDecodeResult>());
    });
  }

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-018 - a
  ///   seeded mutation loop over a valid document never throws and always
  ///   returns one of the two variants.
  /// Path: unhappy (invalid input)
  test('a seeded property loop never throws', () {
    final random = Random(20261012);
    final valid = documentOf('species', speciesEntry());
    const alphabet = 'abc{}[]":,1234567890.-eA \n';
    for (var i = 0; i < 500; i++) {
      var text = valid;
      for (var mutation = 0; mutation < 1 + random.nextInt(4); mutation++) {
        final position = random.nextInt(text.length + 1);
        switch (random.nextInt(3)) {
          case 0 when text.isNotEmpty:
            final start = position.clamp(0, text.length);
            text =
                text.substring(0, start) +
                text.substring((start + 1).clamp(0, text.length));
          case 1:
            final start = position.clamp(0, text.length);
            text =
                '${text.substring(0, start)}'
                '${alphabet[random.nextInt(alphabet.length)]}'
                '${text.substring(start)}';
          case 2:
            final start = position.clamp(0, text.length);
            final end = (start + random.nextInt(6)).clamp(0, text.length);
            text =
                '${text.substring(0, start)}'
                '${alphabet[random.nextInt(alphabet.length)] * (1 + random.nextInt(3))}'
                '${text.substring(end)}';
        }
      }
      final result = decoder.decode(text);
      expect(result, isA<ContentDecodeResult>());
    }
  });

  /// Requirement: doc/specs/content-spells.md FR-107, schema FR-019,
  ///   FR-022 - a spell element holding only the envelope header reports
  ///   every declared field missing, in the declared key order, then the
  ///   unknown key (content-spells.md R1-spells landed).
  /// Path: unhappy (missing content)
  test('a shapeless spell element reports the missing fields', () {
    expectProblems(
      decoder.decode('{"schemaVersion":1,"spells":[{"id":"a","bogus":1}]}'),
      [
        ('/spells/0/name', ContentProblemKind.missingField),
        ('/spells/0/level', ContentProblemKind.missingField),
        ('/spells/0/school', ContentProblemKind.missingField),
        ('/spells/0/classes', ContentProblemKind.missingField),
        ('/spells/0/castingTimes', ContentProblemKind.missingField),
        ('/spells/0/ritual', ContentProblemKind.missingField),
        ('/spells/0/range', ContentProblemKind.missingField),
        ('/spells/0/components', ContentProblemKind.missingField),
        ('/spells/0/duration', ContentProblemKind.missingField),
        ('/spells/0/description', ContentProblemKind.missingField),
        ('/spells/0/bogus', ContentProblemKind.unknownField),
      ],
    );
  });
}

String _label(String text) {
  final shortened = text.length <= 24 ? text : '${text.substring(0, 21)}...';
  return shortened.replaceAll('\n', '\\n');
}

final class _DuplicateCase {
  const _DuplicateCase(this.label, this.document, this.expected)
    : path = 'unhappy (invalid input)';

  final String label;
  final String document;
  final List<(String, ContentProblemKind)> expected;
  final String path;
}

final List<_DuplicateCase> _duplicateCases = [
  _DuplicateCase(
    'two clean entries with one id',
    document(
      arrays: {
        'spells': [spellEntry(id: 'a'), spellEntry(id: 'a', name: 'B')],
      },
    ),
    [('/spells/1/id', ContentProblemKind.duplicate)],
  ),
  _DuplicateCase(
    'the earlier entry also has a problem',
    document(
      arrays: {
        'spells': [
          spellEntry(id: 'a', without: {'school'}),
          spellEntry(id: 'a', name: 'B'),
        ],
      },
    ),
    [
      ('/spells/0/school', ContentProblemKind.missingField),
      ('/spells/1/id', ContentProblemKind.duplicate),
    ],
  ),
  _DuplicateCase(
    'the later entry also has a problem',
    document(
      arrays: {
        'spells': [
          spellEntry(id: 'a'),
          spellEntry(id: 'a', name: 'B', without: {'school'}),
        ],
      },
    ),
    [
      ('/spells/1/school', ContentProblemKind.missingField),
      ('/spells/1/id', ContentProblemKind.duplicate),
    ],
  ),
  _DuplicateCase(
    'two invalid ids take no part in duplicate checks',
    document(
      arrays: {
        'spells': [spellEntry(id: 'A'), spellEntry(id: 'A', name: 'B')],
      },
    ),
    [
      ('/spells/0/id', ContentProblemKind.invalidValue),
      ('/spells/1/id', ContentProblemKind.invalidValue),
    ],
  ),
];

final class _SourceCase {
  const _SourceCase(this.label, this.document, this.expected)
    : path = 'unhappy (boundary)';

  final String label;
  final String document;
  final List<(String, ContentProblemKind)> expected;
  final String path;
}

String _speciesWithSource(String sourceJson) =>
    '{"schemaVersion":1,"species":[{"id":"elf","name":"Elf","creatureType":"Humanoid",'
    '"sizes":["Medium"],"speed":30,'
    '"traits":[{"name":"Keen Senses","text":"You gain proficiency."}],'
    '"source":$sourceJson}]}';

final List<_SourceCase> _sourceCases = [
  _SourceCase(
    'page 0',
    _speciesWithSource('{"document":"SRD 5.2.1","section":"Elf","page":0}'),
    [('/species/0/source/page', ContentProblemKind.outOfRange)],
  ),
  _SourceCase(
    'no section',
    _speciesWithSource('{"document":"SRD 5.2.1","page":16}'),
    [('/species/0/source/section', ContentProblemKind.missingField)],
  ),
  _SourceCase(
    'blank section',
    _speciesWithSource('{"document":"SRD 5.2.1","section":"  ","page":16}'),
    [('/species/0/source/section', ContentProblemKind.invalidValue)],
  ),
  _SourceCase(
    'blank document',
    _speciesWithSource('{"document":"  ","section":"Elf","page":16}'),
    [('/species/0/source/document', ContentProblemKind.invalidValue)],
  ),
  _SourceCase(
    'an unknown key',
    _speciesWithSource('{"document":"d","section":"s","page":1,"url":"x"}'),
    [('/species/0/source/url', ContentProblemKind.unknownField)],
  ),
  _SourceCase(
    'a 20-digit page',
    _speciesWithSource(
      '{"document":"d","section":"s","page":12345678901234567890}',
    ),
    [('/species/0/source/page', ContentProblemKind.outOfRange)],
  ),
];

/// Documents that must always return a result, never throw (FR-018):
/// malformed JSON, deep nesting, lone surrogates, huge numbers.
final List<String> hostileCorpus = [
  '{"schemaVersion":1,"species":[{"id":"\\uD800","name":"\u{D800}x","creatureType":"Humanoid","sizes":["Medium"],"speed":30,"traits":[{"name":"T","text":"x"}]}]}',
  '{"schemaVersion":1.00000000000000000000000000000099,"species":[]}',
  '{"schemaVersion":1,"species":[{"id":"a","name":"A","creatureType":"Humanoid","sizes":['
      '"Medium","Small","Large","Tiny","Huge","Gargantuan","Medium","Small","Large","Tiny"],'
      '"speed":30,"traits":[{"name":"T","text":"x"}]}]}',
  '{"schemaVersion":1,"feats":[{"id":"a","name":"A","category":"General",'
      '"prerequisites":[{"kind":"level","minimum":1},'
      '{"kind":"level","minimum":2},{"kind":"level","minimum":3},'
      '{"kind":"level","minimum":4},{"kind":"level","minimum":5}],'
      '"benefits":[{"text":"x"}],"repeatable":false}]}',
  '{"schemaVersion":1,"weapons":[{"id":"w","name":"W","category":"Simple",'
      '"weaponType":"Ranged","damage":{"dice":"99999999999999999999d12"},'
      '"damageType":"Fire","properties":[],"mastery":"Cleave","cost":{"amount":1,"coin":"CP"}}]}',
  '﻿{"schemaVersion":1}',
  '{"schemaVersion":1,"armor":[{"id":"a","name":"A","category":"Shield",'
      '"armorClass":{"bonus":2},"strengthRequirement":9007199254740992,'
      '"stealthDisadvantage":false,"weightPounds":1,"cost":{"amount":1,"coin":"GP"}}]}',
];
