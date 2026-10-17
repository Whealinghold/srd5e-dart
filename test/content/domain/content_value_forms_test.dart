import 'package:srd5e/src/content/domain/content_catalogue.dart';
import 'package:srd5e/src/content/domain/content_entry.dart';
import 'package:srd5e/src/content/domain/content_id.dart';
import 'package:srd5e/src/content/domain/content_key.dart';
import 'package:srd5e/src/content/domain/content_kind.dart';
import 'package:srd5e/src/content/domain/content_lookup.dart';
import 'package:srd5e/src/content/domain/content_query.dart';
import 'package:test/test.dart';

/// A synthetic entry for the value-form rows; no SRD content.
final class _StubEntry implements ContentEntry {
  _StubEntry(ContentKind kind, String id)
    : key = ContentKey(kind, ContentId(id));

  @override
  final ContentKey key;
}

void main() {
  /// Requirement: doc/specs/content-source-port.md FR-019 - the lookup
  ///   results carry structured data only; toString is the debugging form
  ///   (architecture.md §6).
  /// Path: happy
  group('lookup result debugging forms', () {
    /// Requirement: doc/specs/content-source-port.md FR-016 - a found
    ///   result prints the found entry's key.
    /// Path: happy
    test('a found result prints the found key', () {
      final entry = _StubEntry(ContentKind.species, 'test_elf');
      expect(ContentFound(entry).toString(), 'ContentFound(species/test_elf)');
    });

    /// Requirement: doc/specs/content-source-port.md FR-016 - a not-found
    ///   result prints the requested key.
    /// Path: happy
    test('a not-found result prints the requested key', () {
      final key = ContentKey(ContentKind.spell, ContentId('test_gone'));
      expect(
        ContentNotFound(key).toString(),
        'ContentNotFound(spell/test_gone)',
      );
    });
  });

  /// Requirement: doc/specs/content-source-port.md FR-057 - the query is a
  ///   sealed value whose variants print the asked-for key or kind.
  /// Path: happy
  group('query debugging forms', () {
    /// Requirement: doc/specs/content-source-port.md FR-057 - a lookup
    ///   query prints its key; a list query prints its kind.
    /// Path: happy
    test('each query variant prints what was asked', () {
      final key = ContentKey(ContentKind.spell, ContentId('test_bolt'));
      expect(
        ContentLookupQuery(key).toString(),
        'ContentLookupQuery(spell/test_bolt)',
      );
      expect(
        const ContentListKindQuery(ContentKind.species).toString(),
        'ContentListKindQuery(species)',
      );
    });
  });

  /// Requirement: doc/specs/content-source-port.md FR-046 - the catalogue
  ///   is a pure immutable value object; its debugging form names its
  ///   size.
  /// Path: happy
  group('catalogue debugging form', () {
    /// Requirement: doc/specs/content-source-port.md FR-046 - the
    ///   catalogue prints the number of entries it holds.
    /// Path: happy
    test('the catalogue prints its entry count', () {
      final catalogue = ContentCatalogue([
        _StubEntry(ContentKind.species, 'test_dwarf'),
        _StubEntry(ContentKind.species, 'test_elf'),
      ]);
      expect(catalogue.toString(), 'ContentCatalogue(2 entries)');
      expect(
        ContentCatalogue(const []).toString(),
        'ContentCatalogue(0 entries)',
      );
    });
  });
}
