import 'package:srd5e/adapters.dart';
import 'package:srd5e/srd5e.dart';
import 'package:srd5e/testing.dart';
import 'package:test/test.dart';

/// The `ContentSource` scenario (content-source-port.md FR-043), through
/// the public entry points only: build an in-memory source, look up a
/// present and an absent key, list a kind, and switch exhaustively over
/// `ContentLookup` with no default branch.
void main() {
  /// Requirement: doc/specs/content-source-port.md FR-043 - a consumer
  ///   imports the three public entry points, builds an
  ///   InMemoryContentSource, looks up a present and an absent key, calls
  ///   listKind, and switches exhaustively over ContentLookup.
  /// Path: happy
  test('an InMemoryContentSource answers lookups and lists a kind', () async {
    final spell = _StubEntry(
      key: ContentKey(ContentKind.spell, ContentId('light')),
    );
    final feat = _StubEntry(
      key: ContentKey(ContentKind.feat, ContentId('alert')),
    );
    final source = InMemoryContentSource([spell, feat]);

    final present = await source.lookup(
      ContentKey(ContentKind.spell, ContentId('light')),
    );
    final absent = await source.lookup(
      ContentKey(ContentKind.spell, ContentId('mage_armor')),
    );
    final feats = await source.listKind(ContentKind.feat);

    final description = switch (present) {
      ContentFound(:final entry) => 'found ${entry.key.kind.name}',
      ContentNotFound(:final key) => 'missing ${key.id.value}',
    };
    expect(description, 'found spell');
    expect(absent, isA<ContentNotFound>());
    expect(switch (absent) {
      ContentNotFound(:final missing) => missing,
      ContentFound() => null,
    }, MissingContent(ContentKind.spell, ContentId('mage_armor')));
    expect(feats, [feat]);
  });

  /// Requirement: doc/specs/content-source-port.md FR-043 - the scenario
  ///   runs the same through the scripted double, so a consumer's tests can
  ///   drive absence and failure the same way.
  /// Path: happy
  test('the FakeContentSource double drives the same switch', () async {
    final source = FakeContentSource(const []);

    final lookup = await source.lookup(
      ContentKey(ContentKind.feat, ContentId('alert')),
    );

    expect(switch (lookup) {
      ContentFound(:final entry) => entry.key.id.value,
      ContentNotFound(:final missing) => missing.id.value,
    }, 'alert');
  });
}

/// A minimal content entry of the scenario, shaped through the public
/// `ContentEntry` interface only.
final class _StubEntry implements ContentEntry {
  const _StubEntry({required this.key});

  @override
  final ContentKey key;
}
