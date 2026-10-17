import 'package:srd5e/src/content/domain/content_entry.dart';
import 'package:srd5e/src/content/domain/content_id.dart';
import 'package:srd5e/src/content/domain/content_key.dart';
import 'package:srd5e/src/content/domain/content_kind.dart';
import 'package:srd5e/src/content/domain/content_set.dart';
import 'package:test/test.dart';

import '../../support/argument_error_matcher.dart';

/// A minimal entry: only its key. Whole entries are the kind specs' concern;
/// the set rules are about keys and order.
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

void main() {
  /// Requirement: doc/specs/content-schema-and-decoder.md FR-071 - a set is
  ///   ordered by ContentKind (declaration order) then id (ordinal),
  ///   independent of document order, its entries unmodifiable, and every
  ///   entry carries the key kind of its registered kind.
  /// Path: happy
  group('ContentSet ordering', () {
    /// Requirement: per case
    /// Path: per case
    for (final c in _orderingCases) {
      test('shuffled ${c.label} orders by kind then id [${c.path}]', () {
        final set = ContentSet(c.entries.reversed);
        final keys = [for (final entry in set.entries) entry.key];
        expect(keys, c.expectedKeys);
      });
    }

    /// Requirement: doc/specs/content-schema-and-decoder.md FR-071 - the
    ///   entries list is unmodifiable.
    /// Path: unhappy (immutability)
    test('entries cannot be mutated', () {
      final set = ContentSet([_entry(ContentKind.species, 'elf')]);

      expect(
        () => set.entries.add(_entry(ContentKind.species, 'orc')),
        throwsUnsupportedError,
      );
    });

    /// Requirement: doc/specs/content-schema-and-decoder.md FR-093 - a set
    ///   does not check references: a background whose feat is absent or not
    ///   Origin is a valid ContentSet.
    /// Path: unhappy (rule interaction)
    test('accepts entries without reference checking', () {
      // A background stub whose key exists but whose feat target does not:
      // the set only knows keys, and nothing here resolves references.
      final set = ContentSet([
        _entry(ContentKind.background, 'acolyte'),
        _entry(ContentKind.feat, 'savage_attacker'),
      ]);

      expect(set.entries, hasLength(2));
    });
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-093 - a
  ///   ContentSet with two entries of one key throws ArgumentError; FR-031
  ///   pins the uniqueness it enforces.
  /// Path: unhappy (invalid input)
  group('ContentSet duplicate keys', () {
    /// Requirement: per case
    /// Path: per case
    for (final c in _duplicateCases) {
      test('${c.label} [${c.path}]', () {
        expect(
          () => ContentSet(c.entries),
          throwsArgumentErrorFor('entries', c.entries.last.key),
        );
      });
    }

    /// Requirement: doc/specs/content-schema-and-decoder.md FR-032 - the
    ///   same id in two kinds is two keys and is accepted.
    /// Path: happy
    test('the same id under two kinds is accepted', () {
      final set = ContentSet([
        _entry(ContentKind.feat, 'sage'),
        _entry(ContentKind.species, 'sage'),
      ]);

      expect(set.entries, hasLength(2));
    });
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-072 - two sets
  ///   over equal entries are equal with equal hash codes.
  /// Path: happy
  group('ContentSet equality', () {
    /// Requirement: doc/specs/content-schema-and-decoder.md FR-072 - equal
    ///   entries in a different input order give equal sets.
    /// Path: happy
    test('input order does not change equality', () {
      final a = ContentSet([
        _entry(ContentKind.feat, 'alert'),
        _entry(ContentKind.species, 'elf'),
      ]);
      final b = ContentSet([
        _entry(ContentKind.species, 'elf'),
        _entry(ContentKind.feat, 'alert'),
      ]);

      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    /// Requirement: doc/specs/content-schema-and-decoder.md FR-072 - a set
    ///   with another entry is not equal.
    /// Path: unhappy (rule interaction)
    test('a different entry makes sets unequal', () {
      final a = ContentSet([_entry(ContentKind.species, 'elf')]);
      final b = ContentSet([_entry(ContentKind.species, 'dwarf')]);

      expect(a, isNot(equals(b)));
    });

    /// Requirement: doc/specs/content-schema-and-decoder.md FR-009 - the
    ///   empty set is a set (a minimal document decodes to one).
    /// Path: happy
    test('the empty set is valid and equal to another empty set', () {
      expect(ContentSet(const []), ContentSet(const []));
    });
  });
}

final class _OrderingCase {
  const _OrderingCase(this.label, this.entries, this.expectedKeys)
    : path = 'happy';

  final String label;
  final List<_StubEntry> entries;
  final List<ContentKey> expectedKeys;
  final String path;
}

ContentKey _key(ContentKind kind, String id) => ContentKey(kind, ContentId(id));

/// FR-071's order: the declaration order of ContentKind, then the id in
/// ordinal order - whatever order the entries arrive in.
final List<_OrderingCase> _orderingCases = [
  _OrderingCase(
    'an equipment entry before a spell',
    [_entry(ContentKind.spell, 'a'), _entry(ContentKind.equipment, 'a')],
    [_key(ContentKind.equipment, 'a'), _key(ContentKind.spell, 'a')],
  ),
  _OrderingCase(
    'species, feat, background by kind, then ids within a kind',
    [
      _entry(ContentKind.feat, 'b'),
      _entry(ContentKind.background, 'z'),
      _entry(ContentKind.species, 'a'),
      _entry(ContentKind.feat, 'a'),
      _entry(ContentKind.background, 'a'),
    ],
    [
      _key(ContentKind.species, 'a'),
      _key(ContentKind.background, 'a'),
      _key(ContentKind.background, 'z'),
      _key(ContentKind.feat, 'a'),
      _key(ContentKind.feat, 'b'),
    ],
  ),
];

final class _DuplicateCase {
  const _DuplicateCase(this.label, this.entries)
    : path = 'unhappy (invalid input)';

  final String label;
  final List<_StubEntry> entries;
  final String path;
}

final List<_DuplicateCase> _duplicateCases = [
  _DuplicateCase('two species entries with one id', [
    _entry(ContentKind.species, 'elf'),
    _entry(ContentKind.species, 'elf'),
  ]),
  _DuplicateCase('a duplicate later in the list after other entries', [
    _entry(ContentKind.species, 'elf'),
    _entry(ContentKind.feat, 'alert'),
    _entry(ContentKind.feat, 'alert'),
  ]),
];
