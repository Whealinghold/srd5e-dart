import 'package:srd5e/src/content/application/ports/content_source.dart'
    show ContentSourceException;
import 'package:srd5e/src/content/domain/content_entry.dart';
import 'package:srd5e/src/content/domain/content_id.dart';
import 'package:srd5e/src/content/domain/content_key.dart';
import 'package:srd5e/src/content/domain/content_kind.dart';
import 'package:srd5e/src/content/domain/content_lookup.dart';
import 'package:srd5e/src/content/domain/content_query.dart';
import 'package:srd5e/testing.dart';
import 'package:test/test.dart';

import '../support/argument_error_matcher.dart';

/// A minimal entry: only its key.
final class _StubEntry implements ContentEntry {
  const _StubEntry(this.key);

  @override
  final ContentKey key;

  @override
  bool operator ==(Object other) => other is _StubEntry && other.key == key;

  @override
  int get hashCode => key.hashCode;
}

_StubEntry _entry(ContentKind kind, String id) =>
    _StubEntry(ContentKey(kind, ContentId(id)));

ContentKey _key(ContentKind kind, String id) => ContentKey(kind, ContentId(id));

void main() {
  /// Requirement: doc/specs/content-source-port.md FR-029 - unscripted, the
  ///   double answers from its catalogue like the real in-memory source.
  /// Path: happy
  test('unscripted, it answers from its entries', () async {
    final entry = _entry(ContentKind.spell, 'light');
    final fake = FakeContentSource([entry]);

    expect(
      await fake.lookup(_key(ContentKind.spell, 'light')),
      ContentFound(entry),
    );
    expect(await fake.listKind(ContentKind.spell), [entry]);
    expect(
      await fake.lookup(_key(ContentKind.feat, 'alert')),
      ContentNotFound(_key(ContentKind.feat, 'alert')),
    );
  });

  /// Requirement: doc/specs/content-source-port.md FR-030 - a scripted
  ///   lookup failure delivers exactly the supplied instance through a
  ///   failed future, never a synchronous throw.
  /// Path: unhappy (collaborator failure)
  test(
    'a scripted lookup failure is the same instance, asynchronously',
    () async {
      final failure = ContentSourceException(
        ContentLookupQuery(_key(ContentKind.spell, 'light')),
        cause: StateError('backend down'),
      );
      final fake = FakeContentSource([
        _entry(ContentKind.spell, 'light'),
      ], lookupFailure: failure);

      final future = fake.lookup(_key(ContentKind.spell, 'light'));
      expect(future, isA<Future<ContentLookup>>());
      await expectLater(future, throwsA(same(failure)));
    },
  );

  /// Requirement: doc/specs/content-source-port.md FR-030 - a scripted
  ///   listKind failure delivers the supplied instance, and lookup stays
  ///   unscripted.
  /// Path: unhappy (collaborator failure)
  test('a scripted listKind failure leaves lookup working', () async {
    const failure = ContentSourceException(
      ContentListKindQuery(ContentKind.spell),
    );
    final entry = _entry(ContentKind.spell, 'light');
    final fake = FakeContentSource([entry], listKindFailure: failure);

    await expectLater(fake.listKind(ContentKind.spell), throwsA(same(failure)));
    expect(
      await fake.lookup(_key(ContentKind.spell, 'light')),
      ContentFound(entry),
    );
  });

  /// Requirement: doc/specs/content-source-port.md FR-030 - both
  ///   operations can be scripted to fail.
  /// Path: unhappy (collaborator failure)
  test('both operations can be scripted to fail', () async {
    final lookupFailure = ContentSourceException(
      ContentLookupQuery(_key(ContentKind.spell, 'light')),
    );
    const listFailure = ContentSourceException(
      ContentListKindQuery(ContentKind.feat),
    );
    final fake = FakeContentSource(
      const [],
      lookupFailure: lookupFailure,
      listKindFailure: listFailure,
    );

    await expectLater(
      fake.lookup(_key(ContentKind.spell, 'light')),
      throwsA(same(lookupFailure)),
    );
    await expectLater(
      fake.listKind(ContentKind.feat),
      throwsA(same(listFailure)),
    );
  });

  /// Requirement: doc/specs/content-source-port.md FR-031 - every request
  ///   is recorded in call order as the matching ContentQuery variant,
  ///   including the ones a script failed.
  /// Path: happy
  test('requests are recorded in call order with their variants', () async {
    const failure = ContentSourceException(
      ContentListKindQuery(ContentKind.feat),
    );
    final entry = _entry(ContentKind.spell, 'light');
    final fake = FakeContentSource([entry], listKindFailure: failure);
    final key = _key(ContentKind.spell, 'light');

    final lookup = fake.lookup(key);
    final failedList = fake.listKind(ContentKind.feat);
    final absentLookup = fake.lookup(_key(ContentKind.spell, 'mage_armor'));
    final failedList2 = fake.listKind(ContentKind.spell);

    expect(await lookup, ContentFound(entry));
    await expectLater(failedList, throwsA(same(failure)));
    expect(await absentLookup, isA<ContentNotFound>());
    await expectLater(failedList2, throwsA(same(failure)));

    expect(fake.requests, [
      ContentLookupQuery(key),
      const ContentListKindQuery(ContentKind.feat),
      ContentLookupQuery(_key(ContentKind.spell, 'mage_armor')),
      const ContentListKindQuery(ContentKind.spell),
    ]);
  });

  /// Requirement: doc/specs/content-source-port.md FR-031 - the recorded
  ///   list is unmodifiable.
  /// Path: unhappy (immutability)
  test('the recorded requests cannot be mutated', () {
    final fake = FakeContentSource(const []);

    expect(() => fake.requests.clear(), throwsUnsupportedError);
  });

  /// Requirement: doc/specs/content-source-port.md FR-014 - repeated calls
  ///   on the same double give equal results: same variant, entry or key
  ///   equal, lists equal in order.
  /// Path: happy
  test('repeated calls give equal results', () async {
    final entry = _entry(ContentKind.spell, 'light');
    final fake = FakeContentSource([entry]);
    final key = _key(ContentKind.spell, 'light');

    final firstLookup = await fake.lookup(key);
    final secondLookup = await fake.lookup(key);
    final firstList = await fake.listKind(ContentKind.spell);
    final secondList = await fake.listKind(ContentKind.spell);

    expect(firstLookup, secondLookup);
    expect(firstList, secondList);
  });

  /// Requirement: doc/specs/content-source-port.md FR-021, FR-049 - the
  ///   double is constructed from an Iterable<ContentEntry> and rejects a
  ///   duplicate key through its catalogue, naming entries.
  /// Path: unhappy (invalid input)
  test('a duplicate key is rejected naming entries', () {
    final duplicate = _key(ContentKind.spell, 'light');

    expect(
      () => FakeContentSource([
        _entry(ContentKind.spell, 'light'),
        _StubEntry(duplicate),
      ]),
      throwsArgumentErrorFor('entries', duplicate),
    );
  });

  /// Requirement: doc/specs/content-source-port.md FR-023 - the input is
  ///   copied: later mutation of the caller's collection changes nothing.
  /// Path: unhappy (immutability)
  test('mutating the input afterwards changes nothing', () async {
    final input = [_entry(ContentKind.spell, 'light')];
    final fake = FakeContentSource(input);
    input.add(_entry(ContentKind.spell, 'mage_armor'));

    expect(await fake.listKind(ContentKind.spell), hasLength(1));
  });
}
