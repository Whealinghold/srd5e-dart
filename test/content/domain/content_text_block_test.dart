import 'package:srd5e/src/content/domain/content_text_block.dart';
import 'package:test/test.dart';

import '../../support/argument_error_matcher.dart';
import '../../support/operator_equals.dart';

/// Exhaustive over the sealed family with no default branch (FR-150).
String _describe(ContentTextBlock block) => switch (block) {
  ContentTextParagraph() => 'paragraph',
  ContentTextEntry() => 'entry',
  ContentTextBulletList() => 'bulletList',
  ContentTextTable() => 'table',
  ContentTextEmbeddedStatBlock() => 'embeddedStatBlock',
};

void main() {
  /// Requirement: doc/specs/content-schema-and-decoder.md FR-150 -
  ///   ContentTextParagraph is one of the five variants, its text
  ///   stored verbatim (FR-029).
  /// Path: happy
  group('ContentTextParagraph', () {
    /// Requirement: doc/specs/content-schema-and-decoder.md FR-151 - the
    ///   text passes FR-028.
    /// Path: happy
    test('accepts a text with a non-whitespace character, verbatim', () {
      final block = ContentTextParagraph('  leading spaces kept  ');

      expect(block.text, '  leading spaces kept  ');
    });

    /// Requirement: doc/specs/content-schema-and-decoder.md FR-151 - blank
    ///   text throws ArgumentError (FR-028).
    /// Path: unhappy (invalid input)
    test('rejects a blank text', () {
      expect(
        () => ContentTextParagraph(''),
        throwsArgumentErrorFor('text', ''),
      );
      expect(
        () => ContentTextParagraph('  '),
        throwsArgumentErrorFor('text', '  '),
      );
    });
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-150 -
  ///   ContentTextEntry is a run-in heading and its text, both
  ///   stored verbatim.
  /// Path: happy
  group('ContentTextEntry', () {
    /// Requirement: doc/specs/content-schema-and-decoder.md FR-151 - the
    ///   name passes FR-027 and the text passes FR-028.
    /// Path: happy
    test('accepts a heading and text verbatim', () {
      final block = ContentTextEntry('Draconic Ancestry', 'Text.');

      expect(block.name, 'Draconic Ancestry');
      expect(block.text, 'Text.');
    });

    /// Requirement: doc/specs/content-schema-and-decoder.md FR-151 - the
    ///   name must have no surrounding whitespace (FR-094: constructor and
    ///   decoder agree).
    /// Path: unhappy (invalid input)
    test('rejects a name with surrounding space', () {
      expect(
        () => ContentTextEntry(' Trait', 'Text.'),
        throwsArgumentErrorFor('name', ' Trait'),
      );
      expect(
        () => ContentTextEntry('Trait ', 'Text.'),
        throwsArgumentErrorFor('name', 'Trait '),
      );
    });

    /// Requirement: doc/specs/content-schema-and-decoder.md FR-151 - blank
    ///   text throws ArgumentError (FR-028).
    /// Path: unhappy (invalid input)
    test('rejects a blank text', () {
      expect(
        () => ContentTextEntry('Trait', ''),
        throwsArgumentErrorFor('text', ''),
      );
    });
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-150 -
  ///   ContentTextBulletList holds its items as an unmodifiable
  ///   defensive copy.
  /// Path: happy
  group('ContentTextBulletList', () {
    /// Requirement: doc/specs/content-schema-and-decoder.md FR-151 - at
    ///   least one item, every item passing FR-028.
    /// Path: happy
    test('accepts a non-empty list of texts as an unmodifiable copy', () {
      final source = <String>['First.', 'Second.'];
      final block = ContentTextBulletList(source);
      source.add('Third.');

      expect(block.items, ['First.', 'Second.']);
      expect(() => block.items.add('Third.'), throwsUnsupportedError);
    });

    /// Requirement: doc/specs/content-schema-and-decoder.md FR-151 - an
    ///   empty list throws ArgumentError.
    /// Path: unhappy (empty case)
    test('rejects an empty list', () {
      expect(
        () => ContentTextBulletList(const <String>[]),
        throwsArgumentErrorFor('items', const <String>[]),
      );
    });

    /// Requirement: doc/specs/content-schema-and-decoder.md FR-151 - a
    ///   blank item throws ArgumentError (FR-028).
    /// Path: unhappy (invalid input)
    test('rejects a blank item', () {
      expect(
        () => ContentTextBulletList(['First.', '  ']),
        throwsArgumentErrorFor('items', '  '),
      );
    });
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-151 -
  ///   a table has a non-empty header of non-blank cells, at least
  ///   one row as wide as the header, and an optional title.
  /// Path: happy
  group('ContentTextTable', () {
    /// Requirement: doc/specs/content-schema-and-decoder.md FR-151 - a
    ///   minimal valid table: a non-empty header of non-blank cells and at
    ///   least one row exactly as wide as the header; a cell may be the
    ///   empty string.
    /// Path: happy
    test('accepts a minimal table and keeps a blank body cell', () {
      final block = ContentTextTable(
        header: ['Die', 'Effect'],
        rows: [
          ['d6', ''],
          ['d8', 'Something.'],
        ],
      );

      expect(block.title, isNull);
      expect(block.header, ['Die', 'Effect']);
      expect(block.rows, [
        ['d6', ''],
        ['d8', 'Something.'],
      ]);
    });

    /// Requirement: doc/specs/content-schema-and-decoder.md FR-151 - a
    ///   title that passes FR-028 is kept verbatim.
    /// Path: happy
    test('accepts a title', () {
      final block = ContentTextTable(
        title: 'Draconic Ancestry',
        header: ['Damage Type'],
        rows: [
          ['Poison'],
        ],
      );

      expect(block.title, 'Draconic Ancestry');
    });

    /// Requirement: doc/specs/content-schema-and-decoder.md FR-151 - a
    ///   title that is present but blank throws ArgumentError.
    /// Path: unhappy (invalid input)
    test('rejects a blank title', () {
      expect(
        () => ContentTextTable(
          title: ' ',
          header: ['Die'],
          rows: [
            ['d6'],
          ],
        ),
        throwsArgumentErrorFor('title', ' '),
      );
    });

    /// Requirement: doc/specs/content-schema-and-decoder.md FR-151 - a
    ///   non-empty header of cells passing FR-028.
    /// Path: unhappy (invalid input)
    test('rejects an empty or blank-celled header', () {
      expect(
        () => ContentTextTable(header: <String>[], rows: [[]]),
        throwsArgumentErrorFor('header', <String>[]),
      );
      expect(
        () => ContentTextTable(
          header: ['Die', ' '],
          rows: [
            ['d6', ''],
          ],
        ),
        throwsArgumentErrorFor('header', ' '),
      );
    });

    /// Requirement: doc/specs/content-schema-and-decoder.md FR-151 - at
    ///   least one row.
    /// Path: unhappy (empty case)
    test('rejects zero rows', () {
      expect(
        () => ContentTextTable(header: ['Die'], rows: <List<String>>[]),
        throwsArgumentErrorFor('rows', <List<String>>[]),
      );
    });

    /// Requirement: doc/specs/content-schema-and-decoder.md FR-151 - every
    ///   row exactly as wide as the header.
    /// Path: unhappy (invalid input)
    test('rejects a ragged row', () {
      final ragged = <String>['d6'];
      expect(
        () => ContentTextTable(header: ['Die', 'Effect'], rows: [ragged]),
        throwsArgumentErrorFor('rows', ragged),
      );
      final wide = <String>['d6', 'Effect.', 'extra'];
      expect(
        () => ContentTextTable(header: ['Die', 'Effect'], rows: [wide]),
        throwsArgumentErrorFor('rows', wide),
      );
    });

    /// Requirement: doc/specs/content-schema-and-decoder.md FR-151 and
    ///   FR-152 - a body cell may be the empty string but not blank, so
    ///   constructor and decoder agree (FR-094).
    /// Path: unhappy (invalid input)
    test('rejects a blank body cell but accepts an empty one', () {
      expect(
        () => ContentTextTable(
          header: ['Die'],
          rows: [
            [' '],
          ],
        ),
        throwsArgumentErrorFor('rows', ' '),
      );
      expect(
        ContentTextTable(
          header: ['Die'],
          rows: [
            [''],
          ],
        ).rows,
        [
          [''],
        ],
      );
    });

    /// Requirement: doc/specs/content-schema-and-decoder.md FR-150 - lists
    ///   are unmodifiable defensive copies.
    /// Path: unhappy (immutability)
    test('stores unmodifiable copies of the header and rows', () {
      final header = <String>['Die'];
      final row = <String>['d6'];
      final rows = <List<String>>[row];
      final block = ContentTextTable(header: header, rows: rows);
      header.clear();
      row.clear();
      rows.clear();

      expect(block.header, ['Die']);
      expect(block.rows, [
        ['d6'],
      ]);
      expect(() => block.header.add('Other'), throwsUnsupportedError);
      expect(() => block.rows.add(['d8']), throwsUnsupportedError);
      expect(() => block.rows.first.add('extra'), throwsUnsupportedError);
    });
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-150 -
  ///   ContentTextEmbeddedStatBlock holds its lines as an
  ///   unmodifiable defensive copy.
  /// Path: happy
  group('ContentTextEmbeddedStatBlock', () {
    /// Requirement: doc/specs/content-schema-and-decoder.md FR-151 - at
    ///   least one line, every line passing FR-028.
    /// Path: happy
    test('accepts a non-empty list of lines as an unmodifiable copy', () {
      final block = ContentTextEmbeddedStatBlock(['AC 17', 'HP 34']);

      expect(block.lines, ['AC 17', 'HP 34']);
      expect(() => block.lines.add('Speed 30 ft.'), throwsUnsupportedError);
    });

    /// Requirement: doc/specs/content-schema-and-decoder.md FR-151 - an
    ///   empty list throws ArgumentError.
    /// Path: unhappy (empty case)
    test('rejects an empty list', () {
      expect(
        () => ContentTextEmbeddedStatBlock(const <String>[]),
        throwsArgumentErrorFor('lines', const <String>[]),
      );
    });

    /// Requirement: doc/specs/content-schema-and-decoder.md FR-151 - a
    ///   blank line throws ArgumentError (FR-028).
    /// Path: unhappy (invalid input)
    test('rejects a blank line', () {
      expect(
        () => ContentTextEmbeddedStatBlock(['AC 17', ' ']),
        throwsArgumentErrorFor('lines', ' '),
      );
    });
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-150 - the
  ///   sealed base offers non-const factories with the short names returning
  ///   the variant.
  /// Path: happy
  test('the factories return the variants', () {
    expect(ContentTextBlock.paragraph('Text.'), isA<ContentTextParagraph>());
    expect(ContentTextBlock.entry('Name', 'Text.'), isA<ContentTextEntry>());
    expect(
      ContentTextBlock.bulletList(['Item.']),
      isA<ContentTextBulletList>(),
    );
    expect(
      ContentTextBlock.table(
        header: ['H'],
        rows: [
          ['c'],
        ],
      ),
      isA<ContentTextTable>(),
    );
    expect(
      ContentTextBlock.embeddedStatBlock(['AC 17']),
      isA<ContentTextEmbeddedStatBlock>(),
    );
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-150 - the
  ///   family is sealed with exactly the five variants, and a switch is
  ///   exhaustive without a default.
  /// Path: happy
  test('a switch over every variant selects its case', () {
    expect(
      [
        _describe(ContentTextParagraph('Text.')),
        _describe(ContentTextEntry('Name', 'Text.')),
        _describe(ContentTextBulletList(['Item.'])),
        _describe(
          ContentTextTable(
            header: ['H'],
            rows: [
              ['c'],
            ],
          ),
        ),
        _describe(ContentTextEmbeddedStatBlock(['AC 17'])),
      ],
      ['paragraph', 'entry', 'bulletList', 'table', 'embeddedStatBlock'],
    );
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-150 - value
  ///   equality within each variant.
  /// Path: happy
  test('blocks compare by value', () {
    expect(
      operatorEquals(ContentTextParagraph('a'), ContentTextParagraph('a')),
      isTrue,
    );
    expect(
      operatorEquals(ContentTextParagraph('a'), ContentTextParagraph('b')),
      isFalse,
    );
    expect(
      operatorEquals(ContentTextEntry('n', 'a'), ContentTextEntry('n', 'a')),
      isTrue,
    );
    expect(
      operatorEquals(
        ContentTextBulletList(['a']),
        ContentTextBulletList(['a']),
      ),
      isTrue,
    );
    expect(
      operatorEquals(
        ContentTextBulletList(['a']),
        ContentTextBulletList(['b']),
      ),
      isFalse,
    );
    expect(
      operatorEquals(
        ContentTextTable(
          header: ['H'],
          rows: [
            ['c'],
          ],
        ),
        ContentTextTable(
          header: ['H'],
          rows: [
            ['c'],
          ],
        ),
      ),
      isTrue,
    );
    expect(
      operatorEquals(
        ContentTextTable(
          header: ['H'],
          rows: [
            ['c'],
          ],
        ),
        ContentTextTable(
          title: 'T',
          header: ['H'],
          rows: [
            ['c'],
          ],
        ),
      ),
      isFalse,
    );
    expect(
      operatorEquals(
        ContentTextEmbeddedStatBlock(['AC 17']),
        ContentTextEmbeddedStatBlock(['AC 17']),
      ),
      isTrue,
    );
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-150 - the
  ///   variants are value objects; hashCode and toString are part of their
  ///   value semantics.
  /// Path: happy
  test('blocks hash by value and print their parts', () {
    expect(
      ContentTextParagraph('Text.').hashCode,
      ContentTextParagraph('Text.').hashCode,
    );
    expect(
      ContentTextParagraph('Text.').toString(),
      'ContentTextParagraph(Text.)',
    );

    final entry = ContentTextEntry('Name', 'Text.');
    expect(entry.hashCode, ContentTextEntry('Name', 'Text.').hashCode);
    expect(entry.toString(), 'ContentTextEntry(Name)');

    final bullets = ContentTextBulletList(['First.']);
    expect(bullets.hashCode, ContentTextBulletList(['First.']).hashCode);
    expect(bullets.toString(), 'ContentTextBulletList([First.])');

    final table = ContentTextTable(
      title: 'T',
      header: ['H'],
      rows: [
        ['c'],
      ],
    );
    expect(
      table.hashCode,
      ContentTextTable(
        title: 'T',
        header: ['H'],
        rows: [
          ['c'],
        ],
      ).hashCode,
    );
    expect(
      table.toString(),
      'ContentTextTable(title: T, header: [H], rows: [[c]])',
    );

    final statBlock = ContentTextEmbeddedStatBlock(['AC 17']);
    expect(
      statBlock.hashCode,
      ContentTextEmbeddedStatBlock(['AC 17']).hashCode,
    );
    expect(statBlock.toString(), 'ContentTextEmbeddedStatBlock([AC 17])');
  });
}
