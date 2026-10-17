import 'package:srd5e/adapters.dart';
import 'package:srd5e/srd5e.dart';
import 'package:test/test.dart';

/// The thin-slice scenario (doc/specs/content-thin-slice.md section 8),
/// through the public entry points only: build a `BundledContentSource`
/// over the embedded documents, look up `elf`, follow every lineage spell
/// of all three lineages (nine) to `ContentFound`, and look up `light` for
/// `ContentNotFound`.
void main() {
  /// Requirement: doc/specs/content-thin-slice.md FR-063 - the slice is
  ///   closed under its references: following all nine lineage spellIds of
  ///   the elf through the bundled source reaches ContentFound
  ///   (SRD 5.2.1, "Elven Lineages", p. 85);
  ///   doc/specs/content-source-port.md FR-064 - the data pin runs through
  ///   BundledContentSource, the one bundled source.
  /// Path: happy
  test('the nine elf lineage spells resolve in the bundled source', () async {
    final source = BundledContentSource();

    final elfLookup = await source.lookup(
      ContentKey(ContentKind.species, ContentId('elf')),
    );
    // The key's kind is species; the cast fails loudly if the source ever
    // served a different entry type under it.
    final elf = switch (elfLookup) {
      ContentFound(:final entry) => entry as Species,
      ContentNotFound(:final key) => throw StateError(
        'the bundle holds no ${key.id.value}',
      ),
    };
    final lineageSpells = <SpellId>{
      for (final choice in elf.choices)
        for (final option in choice.options)
          if (option is LineageOption)
            for (final benefit in option.levelBenefits) benefit.spellId,
    };

    expect(lineageSpells, hasLength(9));
    for (final spellId in lineageSpells) {
      final spellLookup = await source.lookup(spellId.key);
      switch (spellLookup) {
        case ContentFound(:final entry):
          expect(entry.key, spellId.key, reason: '${spellId.id.value} found');
        case ContentNotFound(:final key):
          fail('the lineage spell ${key.id.value} is not bundled');
      }
    }
  });

  /// Requirement: doc/specs/content-thin-slice.md FR-064 - a lookup of a
  ///   spell in the SRD but not the slice completes with ContentNotFound
  ///   carrying that key and does not throw (content-source-port.md
  ///   FR-009).
  /// Path: unhappy (missing content)
  test('light is ContentNotFound in the bundled source', () async {
    final source = BundledContentSource();
    final lightKey = ContentKey(ContentKind.spell, ContentId('light'));

    final lookup = await source.lookup(lightKey);

    expect(lookup, ContentNotFound(lightKey));
  });
}
