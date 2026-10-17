import 'package:srd5e/src/content/domain/content_id.dart';
import 'package:srd5e/src/content/domain/content_key.dart';
import 'package:srd5e/src/content/domain/content_kind.dart';
import 'package:srd5e/src/content/domain/content_query.dart';
import 'package:test/test.dart';

ContentKey _key(String id) => ContentKey(ContentKind.spell, ContentId(id));

void main() {
  /// Requirement: doc/specs/content-source-port.md FR-057 - a
  ///   ContentLookupQuery compares by value: same key equal, other key not.
  /// Path: happy
  group('ContentLookupQuery equality', () {
    /// Requirement: doc/specs/content-source-port.md FR-057 - two lookup
    ///   queries over the same key are equal and hash equal.
    /// Path: happy
    test('same key is equal', () {
      final query = ContentLookupQuery(_key('acid_arrow'));
      final same = ContentLookupQuery(_key('acid_arrow'));

      expect(query, same);
      expect(query.hashCode, same.hashCode);
    });

    /// Requirement: doc/specs/content-source-port.md FR-057 - two lookup
    ///   queries over different keys differ.
    /// Path: unhappy (invalid input)
    test('another key differs', () {
      expect(
        ContentLookupQuery(_key('acid_arrow')),
        isNot(ContentLookupQuery(_key('light'))),
      );
    });

    /// Requirement: doc/specs/content-source-port.md FR-057 - the query
    ///   exposes the key it was asked for.
    /// Path: happy
    test('exposes its key', () {
      final key = _key('acid_arrow');

      expect(ContentLookupQuery(key).key, key);
    });
  });

  /// Requirement: doc/specs/content-source-port.md FR-057 - a
  ///   ContentListKindQuery compares by value: same kind equal, other kind
  ///   not.
  /// Path: happy
  group('ContentListKindQuery equality', () {
    /// Requirement: doc/specs/content-source-port.md FR-057 - two list
    ///   queries over the same kind are equal and hash equal.
    /// Path: happy
    test('same kind is equal', () {
      const query = ContentListKindQuery(ContentKind.spell);

      expect(query, const ContentListKindQuery(ContentKind.spell));
      expect(
        query.hashCode,
        const ContentListKindQuery(ContentKind.spell).hashCode,
      );
    });

    /// Requirement: doc/specs/content-source-port.md FR-057 - two list
    ///   queries over different kinds differ.
    /// Path: unhappy (invalid input)
    test('another kind differs', () {
      expect(
        const ContentListKindQuery(ContentKind.spell),
        isNot(const ContentListKindQuery(ContentKind.feat)),
      );
    });
  });

  /// Requirement: doc/specs/content-source-port.md FR-057 - the two
  ///   variants are never equal to each other.
  /// Path: unhappy (rule interaction)
  test('a lookup query and a list query differ', () {
    final lookup = ContentLookupQuery(_key('acid_arrow'));
    const list = ContentListKindQuery(ContentKind.spell);

    expect(lookup == list, isFalse);
    expect(list == lookup, isFalse);
    expect(lookup.hashCode, isNot(list.hashCode));
  });

  /// Requirement: doc/specs/content-source-port.md FR-057 - a switch over
  ///   ContentQuery is exhaustive without a default branch.
  /// Path: happy
  test('a switch over ContentQuery is exhaustive without a default', () {
    String describe(ContentQuery query) => switch (query) {
      ContentLookupQuery(:final key) =>
        'lookup ${key.kind.name}/${key.id.value}',
      ContentListKindQuery(:final kind) => 'list ${kind.name}',
    };

    expect(describe(ContentLookupQuery(_key('light'))), 'lookup spell/light');
    expect(describe(const ContentListKindQuery(ContentKind.feat)), 'list feat');
  });
}
