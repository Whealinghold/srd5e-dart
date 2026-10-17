import 'package:srd5e/src/content/domain/content_entry.dart';
import 'package:srd5e/src/content/domain/content_id.dart';
import 'package:srd5e/src/content/domain/content_key.dart';
import 'package:srd5e/src/content/domain/content_kind.dart';
import 'package:srd5e/src/content/domain/content_lookup.dart';
import 'package:srd5e/src/content/domain/missing_content.dart';
import 'package:test/test.dart';

/// A minimal entry: only its key, like the sets' and catalogue's fixtures.
final class _StubEntry implements ContentEntry {
  const _StubEntry(this.key);

  @override
  final ContentKey key;

  @override
  bool operator ==(Object other) => other is _StubEntry && other.key == key;

  @override
  int get hashCode => key.hashCode;
}

ContentKey _key(ContentKind kind, String id) => ContentKey(kind, ContentId(id));

void main() {
  /// Requirement: doc/specs/content-source-port.md FR-015, FR-016 - a
  ///   ContentFound carries its entry, compares by it, and a switch over
  ///   ContentLookup is exhaustive without a default.
  /// Path: happy
  group('ContentFound', () {
    /// Requirement: doc/specs/content-source-port.md FR-016 - two
    ///   ContentFounds are equal iff their entries are equal.
    /// Path: happy
    test('equal entries give equal results', () {
      final entry = _StubEntry(_key(ContentKind.spell, 'light'));

      expect(ContentFound(entry), ContentFound(_StubEntry(entry.key)));
      expect(
        ContentFound(entry).hashCode,
        ContentFound(_StubEntry(entry.key)).hashCode,
      );
    });

    /// Requirement: doc/specs/content-source-port.md FR-016 - two
    ///   ContentFounds over different entries differ.
    /// Path: unhappy (invalid input)
    test('another entry differs', () {
      final first = ContentFound(_StubEntry(_key(ContentKind.spell, 'light')));
      final second = ContentFound(_StubEntry(_key(ContentKind.feat, 'alert')));

      expect(first, isNot(second));
    });

    /// Requirement: doc/specs/content-source-port.md FR-016 - a
    ///   ContentFound exposes its entry.
    /// Path: happy
    test('exposes its entry', () {
      final entry = _StubEntry(_key(ContentKind.spell, 'light'));

      expect(ContentFound(entry).entry, same(entry));
    });
  });

  /// Requirement: doc/specs/content-source-port.md FR-016 - a
  ///   ContentNotFound carries the requested key and its missing getter
  ///   equals the MissingContent of that key (content-schema-and-decoder.md
  ///   FR-147).
  /// Path: unhappy (missing content)
  group('ContentNotFound', () {
    /// Requirement: doc/specs/content-source-port.md FR-016 - two
    ///   ContentNotFounds are equal iff their keys are equal.
    /// Path: happy
    test('equal keys give equal results', () {
      final key = _key(ContentKind.spell, 'light');

      expect(
        ContentNotFound(key),
        ContentNotFound(_key(ContentKind.spell, 'light')),
      );
      expect(
        ContentNotFound(key).hashCode,
        ContentNotFound(_key(ContentKind.spell, 'light')).hashCode,
      );
    });

    /// Requirement: doc/specs/content-source-port.md FR-016 - two
    ///   ContentNotFounds over different keys differ.
    /// Path: unhappy (invalid input)
    test('another key differs', () {
      expect(
        ContentNotFound(_key(ContentKind.spell, 'light')),
        isNot(ContentNotFound(_key(ContentKind.feat, 'alert'))),
      );
    });

    /// Requirement: doc/specs/content-source-port.md FR-016 - the
    ///   missing getter equals the MissingContent of the requested key
    ///   (content-schema-and-decoder.md FR-147).
    /// Path: happy
    test('missing equals the MissingContent of its key', () {
      final notFound = ContentNotFound(_key(ContentKind.spell, 'light'));

      expect(
        notFound.missing,
        MissingContent(ContentKind.spell, ContentId('light')),
      );
    });
  });

  /// Requirement: doc/specs/content-source-port.md FR-015 - ContentLookup
  ///   is sealed with exactly the two variants, so a switch over it is
  ///   exhaustive without a default branch.
  /// Path: happy
  test('a switch over ContentLookup is exhaustive without a default', () {
    String describe(ContentLookup lookup) => switch (lookup) {
      ContentFound(:final entry) => 'found ${entry.key}',
      ContentNotFound(:final key) => 'missing $key',
    };

    expect(
      describe(ContentFound(_StubEntry(_key(ContentKind.spell, 'light')))),
      'found spell/light',
    );
    expect(
      describe(ContentNotFound(_key(ContentKind.feat, 'alert'))),
      'missing feat/alert',
    );
  });
}
