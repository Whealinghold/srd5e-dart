import 'package:srd5e/src/content/domain/content_catalogue.dart';
import 'package:srd5e/src/content/domain/content_entry.dart';
import 'package:srd5e/src/content/domain/content_id.dart';
import 'package:srd5e/src/content/domain/content_key.dart';
import 'package:srd5e/src/content/domain/content_kind.dart';
import 'package:srd5e/src/content/domain/content_lookup.dart';
import 'package:test/test.dart';

import '../../support/argument_error_matcher.dart';

/// A minimal entry: only its key. The catalogue's rules are about keys and
/// order; whole entries are the kind specs' concern.
final class _StubEntry implements ContentEntry {
  const _StubEntry(this.key);

  @override
  final ContentKey key;

  @override
  bool operator ==(Object other) => other is _StubEntry && other.key == key;

  @override
  int get hashCode => key.hashCode;

  @override
  String toString() => 'Stub(${key.kind.name}/${key.id.value})';
}

_StubEntry _entry(ContentKind kind, String id) =>
    _StubEntry(ContentKey(kind, ContentId(id)));

final class _OrderingCase {
  const _OrderingCase(this.label, this.path, this.entries, this.expected);

  final String label;
  final String path;
  final List<_StubEntry> entries;
  final List<String> expected;
}

/// The ordering table of content-source-port.md section 4 ("Cases:
/// `listKind` ordering"), at catalogue level.
final List<_OrderingCase> _orderingCases = [
  _OrderingCase(
    'already sorted',
    'happy',
    [
      _entry(ContentKind.feat, 'a'),
      _entry(ContentKind.feat, 'b'),
      _entry(ContentKind.feat, 'c'),
    ],
    ['a', 'b', 'c'],
  ),
  _OrderingCase(
    'reverse insertion',
    'happy',
    [
      _entry(ContentKind.feat, 'c'),
      _entry(ContentKind.feat, 'b'),
      _entry(ContentKind.feat, 'a'),
    ],
    ['a', 'b', 'c'],
  ),
  _OrderingCase(
    'digit before underscore before letter',
    'unhappy (boundary)',
    [
      _entry(ContentKind.feat, 'ab'),
      _entry(ContentKind.feat, 'a_b'),
      _entry(ContentKind.feat, 'a1'),
    ],
    ['a1', 'a_b', 'ab'],
  ),
  _OrderingCase(
    'prefix first',
    'unhappy (boundary)',
    [_entry(ContentKind.feat, 'ab'), _entry(ContentKind.feat, 'a')],
    ['a', 'ab'],
  ),
  _OrderingCase(
    'single entry',
    'unhappy (empty and minimal)',
    [_entry(ContentKind.feat, 'a')],
    ['a'],
  ),
];

void main() {
  /// Requirement: doc/specs/content-source-port.md FR-046, FR-011 - the
  ///   catalogue answers ofKind with the entries of the kind ordered by id
  ///   (ordinal, code-unit comparison), per the ordering table.
  /// Path: happy
  group('ContentCatalogue ordering', () {
    /// Requirement: per case - the table's row orders by id with code-unit
    ///   comparison, whatever the insertion order.
    /// Path: per case
    for (final c in _orderingCases) {
      test('${c.label} orders [${c.path}]', () {
        final catalogue = ContentCatalogue(c.entries);

        expect([
          for (final entry in catalogue.ofKind(ContentKind.feat))
            entry.key.id.value,
        ], c.expected);
      });
    }

    /// Requirement: doc/specs/content-source-port.md FR-010, FR-011 - a
    ///   listKind over one kind never answers entries of another kind.
    /// Path: unhappy (rule interaction)
    test('other kind ignored', () {
      final catalogue = ContentCatalogue([
        _entry(ContentKind.spell, 'a'),
        _entry(ContentKind.feat, 'b'),
      ]);

      expect(
        [
          for (final entry in catalogue.ofKind(ContentKind.feat))
            entry.key.id.value,
        ],
        ['b'],
      );
    });

    /// Requirement: doc/specs/content-source-port.md FR-011 - the order is
    ///   ordinal, so digits sort before underscores before letters across
    ///   longer ids too.
    /// Path: unhappy (boundary)
    test('code-unit order holds for multi-character ids', () {
      final catalogue = ContentCatalogue([
        _entry(ContentKind.spell, 'acid_arrow'),
        _entry(ContentKind.spell, 'acid'),
        _entry(ContentKind.spell, 'acid2'),
      ]);

      expect(
        [
          for (final entry in catalogue.ofKind(ContentKind.spell))
            entry.key.id.value,
        ],
        ['acid', 'acid2', 'acid_arrow'],
      );
    });
  });

  /// Requirement: doc/specs/content-source-port.md FR-046, FR-012, FR-013 -
  ///   ofKind is empty for a kind with no entries and its lists are
  ///   unmodifiable, leaving the catalogue unchanged.
  /// Path: unhappy (empty case)
  group('ContentCatalogue ofKind edges', () {
    /// Requirement: doc/specs/content-source-port.md FR-012 - a kind with
    ///   no entries gives an empty list, not an error.
    /// Path: unhappy (empty case)
    test('a kind with no entries is empty', () {
      final catalogue = ContentCatalogue([_entry(ContentKind.spell, 'light')]);

      expect(catalogue.ofKind(ContentKind.feat), isEmpty);
    });

    /// Requirement: doc/specs/content-source-port.md FR-013 - mutating the
    ///   returned list throws UnsupportedError and does not alter the
    ///   catalogue.
    /// Path: unhappy (immutability)
    test('the returned list cannot be mutated', () {
      final catalogue = ContentCatalogue([_entry(ContentKind.spell, 'light')]);

      expect(
        () => catalogue
            .ofKind(ContentKind.spell)
            .add(_entry(ContentKind.spell, 'mage_armor')),
        throwsUnsupportedError,
      );
      expect(catalogue.ofKind(ContentKind.spell), hasLength(1));
    });

    /// Requirement: doc/specs/content-source-port.md FR-013 - an empty
    ///   ofKind list is unmodifiable too.
    /// Path: unhappy (immutability)
    test('the empty list cannot be mutated', () {
      final catalogue = ContentCatalogue(const []);

      expect(
        () => catalogue
            .ofKind(ContentKind.trap)
            .add(_entry(ContentKind.trap, 'pit')),
        throwsUnsupportedError,
      );
    });
  });

  /// Requirement: doc/specs/content-source-port.md FR-008, FR-009, FR-010 -
  ///   lookup answers ContentFound for a held key, ContentNotFound for an
  ///   absent one, and never an entry of another kind.
  /// Path: happy
  group('ContentCatalogue lookup', () {
    /// Requirement: doc/specs/content-source-port.md FR-008 - a held key
    ///   gives ContentFound with the entry whose key equals the request.
    /// Path: happy
    test('a held key is found', () {
      final entry = _entry(ContentKind.spell, 'light');
      final catalogue = ContentCatalogue([entry]);

      final lookup = catalogue.lookup(
        ContentKey(ContentKind.spell, ContentId('light')),
      );

      expect(lookup, ContentFound(entry));
    });

    /// Requirement: doc/specs/content-source-port.md FR-009 - an absent key
    ///   gives ContentNotFound carrying the requested key, never a throw.
    /// Path: unhappy (missing content)
    test('an absent key is not found', () {
      final catalogue = ContentCatalogue([_entry(ContentKind.spell, 'light')]);
      final requested = ContentKey(ContentKind.spell, ContentId('mage_armor'));

      expect(catalogue.lookup(requested), ContentNotFound(requested));
    });

    /// Requirement: doc/specs/content-source-port.md FR-010 - a key that
    ///   exists only under another kind is not found, never answered with
    ///   the other kind's entry.
    /// Path: unhappy (rule interaction)
    test('an id held under another kind is not found', () {
      final catalogue = ContentCatalogue([_entry(ContentKind.spell, 'light')]);
      final requested = ContentKey(ContentKind.feat, ContentId('light'));

      expect(catalogue.lookup(requested), ContentNotFound(requested));
    });
  });

  /// Requirement: doc/specs/content-source-port.md FR-021, FR-046 - a
  ///   catalogue rejects duplicate keys with an ArgumentError whose name is
  ///   entries and whose invalidValue is the duplicate key, and accepts the
  ///   same id under two kinds.
  /// Path: unhappy (invalid input)
  group('ContentCatalogue duplicate keys', () {
    /// Requirement: doc/specs/content-source-port.md FR-021 - two entries
    ///   of one key are rejected with name `entries` and invalidValue the
    ///   duplicate key; the message text is not asserted.
    /// Path: unhappy (invalid input)
    test('a duplicate key throws ArgumentError naming entries', () {
      final duplicate = ContentKey(ContentKind.spell, ContentId('light'));

      expect(
        () => ContentCatalogue([
          _entry(ContentKind.spell, 'light'),
          _entry(ContentKind.spell, 'mage_armor'),
          _StubEntry(duplicate),
        ]),
        throwsArgumentErrorFor('entries', duplicate),
      );
    });

    /// Requirement: doc/specs/content-source-port.md FR-041 - the same id
    ///   under two kinds is two keys: accepted, both found.
    /// Path: unhappy (rule interaction)
    test('the same id under two kinds is accepted', () {
      final catalogue = ContentCatalogue([
        _entry(ContentKind.spell, 'light'),
        _entry(ContentKind.feat, 'light'),
      ]);
      final spellKey = ContentKey(ContentKind.spell, ContentId('light'));
      final featKey = ContentKey(ContentKind.feat, ContentId('light'));

      expect(
        catalogue.lookup(spellKey),
        ContentFound(_entry(ContentKind.spell, 'light')),
      );
      expect(
        catalogue.lookup(featKey),
        ContentFound(_entry(ContentKind.feat, 'light')),
      );
      expect(catalogue.ofKind(ContentKind.spell), hasLength(1));
      expect(catalogue.ofKind(ContentKind.feat), hasLength(1));
    });
  });

  /// Requirement: doc/specs/content-source-port.md FR-023, FR-046 - the
  ///   input is iterated exactly once and copied: a single-pass iterable
  ///   works, later mutation of the caller's collection changes nothing.
  /// Path: unhappy (immutability)
  group('ContentCatalogue construction input', () {
    /// Requirement: doc/specs/content-source-port.md FR-046 - the input is
    ///   iterated exactly once.
    /// Path: happy
    test('a generated iterable is iterated exactly once', () {
      var iterations = 0;
      Iterable<ContentEntry> generated() sync* {
        iterations++;
        yield _entry(ContentKind.spell, 'light');
        yield _entry(ContentKind.feat, 'alert');
      }

      final catalogue = ContentCatalogue(generated());

      expect(iterations, 1);
      expect(catalogue.ofKind(ContentKind.spell), hasLength(1));
      expect(catalogue.ofKind(ContentKind.feat), hasLength(1));
    });

    /// Requirement: doc/specs/content-source-port.md FR-023 - later
    ///   mutation of the caller's collection changes nothing.
    /// Path: unhappy (immutability)
    test('mutating the input afterwards changes nothing', () {
      final input = [_entry(ContentKind.spell, 'light')];
      final catalogue = ContentCatalogue(input);
      input.add(_entry(ContentKind.spell, 'mage_armor'));

      expect(catalogue.ofKind(ContentKind.spell), hasLength(1));
      expect(
        catalogue.lookup(
          ContentKey(ContentKind.spell, ContentId('mage_armor')),
        ),
        ContentNotFound(ContentKey(ContentKind.spell, ContentId('mage_armor'))),
      );
    });

    /// Requirement: doc/specs/content-source-port.md FR-022 - a catalogue
    ///   with no entries answers every lookup with ContentNotFound and
    ///   every ofKind with an empty list.
    /// Path: unhappy (empty case)
    test('an empty catalogue is empty', () {
      final catalogue = ContentCatalogue(const []);
      final key = ContentKey(ContentKind.spell, ContentId('light'));

      expect(catalogue.lookup(key), ContentNotFound(key));
      expect(catalogue.ofKind(ContentKind.spell), isEmpty);
    });
  });

  /// Requirement: doc/specs/content-source-port.md section 5 (value
  ///   object) - a catalogue compares by value.
  /// Path: happy
  group('ContentCatalogue value equality', () {
    /// Requirement: doc/specs/content-source-port.md FR-046 - two
    ///   catalogues over the same entries are equal; different entries are
    ///   not.
    /// Path: happy
    test('same entries are equal, others are not', () {
      final entries = [
        _entry(ContentKind.spell, 'light'),
        _entry(ContentKind.feat, 'alert'),
      ];

      expect(ContentCatalogue(entries), ContentCatalogue(entries));
      expect(
        ContentCatalogue(entries),
        isNot(ContentCatalogue([_entry(ContentKind.spell, 'light')])),
      );
      expect(
        ContentCatalogue(entries).hashCode,
        ContentCatalogue(entries).hashCode,
      );
    });
  });
}
