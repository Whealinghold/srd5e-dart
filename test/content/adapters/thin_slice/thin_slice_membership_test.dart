import 'package:srd5e/adapters.dart';
import 'package:srd5e/srd5e.dart';
import 'package:test/test.dart';

import '../../../fixtures/srd/thin_slice/citations.dart';
import '../../../fixtures/srd/thin_slice/species_facts.dart' show elvenLineages;
import '../../../fixtures/srd/thin_slice/wizard_facts.dart';
import 'oracle.dart';

/// A synthetic entry with one dangling reference site, for the negative
/// half of the closure pin (FR-084).
final class _DanglingEntry implements ContentEntry, ContentReferences {
  const _DanglingEntry(this.key, this.target);

  @override
  final ContentKey key;

  final ContentKey target;

  @override
  Iterable<ContentReference> get references => [
    ContentReference('choices/0/options/0/levelBenefits/0/spellId', target),
  ];
}

/// The content kind of an entry id of the slice: a species id, the wizard,
/// or a spell.
ContentKind kindOf(String id) => speciesIds.contains(id)
    ? ContentKind.species
    : id == 'wizard'
    ? ContentKind.characterClass
    : ContentKind.spell;

void main() {
  /// Requirement: doc/specs/content-thin-slice.md FR-001, FR-002, FR-003,
  ///   FR-004, FR-005, FR-006 - membership and addressability of the
  ///   seventeen slice entries.
  /// Path: happy
  group('thin slice membership', () {
    /// Requirement: doc/specs/content-thin-slice.md FR-001, FR-003 - the
    ///   bundled species are exactly dragonborn, dwarf, elf and human, and
    ///   the bundled spells exactly the twelve of the slice table: none
    ///   missing, none extra (SRD 5.2.1, "Character Species", pp. 84-86;
    ///   "Spell Descriptions", pp. 121-154).
    /// Path: happy
    test('listKind holds exactly the four species and twelve spells', () async {
      final species = [
        for (final entry in await entriesOf(ContentKind.species))
          entry.key.id.value,
      ];
      final spells = [
        for (final entry in await entriesOf(ContentKind.spell))
          entry.key.id.value,
      ];

      expect(species, unorderedEquals(speciesIds));
      expect(species, hasLength(speciesIds.length));
      expect(spells, unorderedEquals(spellIds));
      expect(spells, hasLength(spellIds.length));
    });

    /// Requirement: doc/specs/content-thin-slice.md FR-002 - the bundled
    ///   characterClass entries are exactly wizard; no subclass entry is
    ///   bundled, so the evoker and fighter keys are ContentNotFound
    ///   (SRD 5.2.1, "Wizard", p. 77).
    /// Path: unhappy (boundary: nothing beyond the slice)
    test('wizard is the only class; evoker and fighter are absent', () async {
      final classes = [
        for (final entry in await entriesOf(ContentKind.characterClass))
          entry.key.id.value,
      ];
      final evokerKey = ContentKey(
        ContentKind.characterClass,
        ContentId('evoker'),
      );
      final fighterKey = ContentKey(
        ContentKind.characterClass,
        ContentId('fighter'),
      );

      final evoker = await sliceSource.lookup(evokerKey);
      final fighter = await sliceSource.lookup(fighterKey);

      expect(classes, ['wizard']);
      expect(evoker, ContentNotFound(evokerKey));
      expect(fighter, ContentNotFound(fighterKey));
    });

    /// Requirement: doc/specs/content-thin-slice.md FR-004 - the slice
    ///   holds no entry of any kind other than species, characterClass and
    ///   spell: listKind returns an empty list for each other kind.
    /// Path: unhappy (empty case)
    test('listKind is empty for every other kind', () async {
      final sliceKinds = {
        ContentKind.species,
        ContentKind.characterClass,
        ContentKind.spell,
      };
      for (final kind in ContentKind.values) {
        if (sliceKinds.contains(kind)) continue;
        expect(await entriesOf(kind), isEmpty, reason: '${kind.name} is empty');
      }
    });

    /// Requirement: doc/specs/content-thin-slice.md FR-005 - each entry is
    ///   addressable by its id under its kind as a ContentKey
    ///   (content-source-port.md FR-008).
    /// Path: happy
    test('lookup finds each of the seventeen keys', () async {
      for (final id in entryIds) {
        final key = ContentKey(kindOf(id), ContentId(id));
        final lookup = await sliceSource.lookup(key);
        expect(
          switch (lookup) {
            ContentFound(:final entry) => entry.key,
            ContentNotFound() => null,
          },
          key,
          reason: '$id is found under its kind',
        );
      }
    });

    /// Requirement: doc/specs/content-thin-slice.md FR-006 - building a
    ///   BundledContentSource from the three slice texts completes without
    ///   BundledContentInvalid and without the duplicate-key ArgumentError
    ///   (content-source-port.md FR-021, FR-061).
    /// Path: unhappy (duplicate)
    test('building the source from the three texts raises nothing', () {
      expect(() => BundledContentSource(texts: sliceTexts), returnsNormally);
    });
  });

  /// Requirement: doc/specs/content-thin-slice.md FR-007 - every entry
  ///   carries the source value of the section 2 citation table.
  /// Path: happy
  group('thin slice citations', () {
    /// Requirement: per case - doc/specs/content-thin-slice.md FR-007 -
    ///   every entry carries the source value of the "Entry citations"
    ///   table of section 2 (SRD 5.2.1, cited by section and page).
    /// Path: per case
    for (final row in citations.entries) {
      test('${row.key} cites its section and page', () async {
        final found = await sliceSource.lookup(
          ContentKey(kindOf(row.key), ContentId(row.key)),
        );
        final source = switch (found) {
          ContentFound(entry: Species(:final source)) => source,
          ContentFound(entry: Spell(:final source)) => source,
          ContentFound(entry: ClassDefinition(:final source)) => source,
          ContentFound(entry: final entry) => throw StateError(
            'an unhandled entry type ${entry.runtimeType}',
          ),
          ContentNotFound(:final key) => throw StateError(
            'the slice holds no ${key.id.value}',
          ),
        };

        expect(source, isNotNull, reason: '${row.key} has a source');
        expect(source!.document, document);
        expect(source.section, row.value.section);
        expect(source.page, row.value.page);
      });
    }
  });

  /// Requirement: doc/specs/content-thin-slice.md FR-008 - pinned phrases
  ///   and the whole-word banned-term scan.
  /// Path: unhappy (invalid input: non-SRD terms)
  group('thin slice text fidelity', () {
    /// Requirement: doc/specs/content-thin-slice.md FR-008 - no entry text
    ///   contains a whole-word, case-insensitive banned term (race, races,
    ///   subrace, subraces; word boundaries, so "trace" and "grace" never
    ///   match). Verbatim fidelity beyond the pinned phrases is FR-079, a
    ///   human review, not a CI claim.
    /// Path: unhappy (invalid input: non-SRD terms)
    test('no entry text holds a banned term', () async {
      for (final id in entryIds) {
        final entry = await entryOf(kindOf(id), id);
        expect(
          bannedTermsIn(entryTexts(entry)),
          isEmpty,
          reason: '$id carries no non-SRD term',
        );
      }
    });

    /// Requirement: doc/specs/content-thin-slice.md FR-008 - the scan is
    ///   word-bounded: "trace" and "grace" do not match, "race" does.
    /// Path: unhappy (invalid input: non-SRD terms)
    test('the banned-term scan matches whole words only', () {
      expect(bannedTermsIn(['a trace of grace']), isEmpty);
      expect(bannedTermsIn(['a Race of beings']), ['Race']);
      expect(bannedTermsIn(['its subraces are gone']), ['subraces']);
    });
  });

  /// Requirement: doc/specs/content-thin-slice.md FR-062 - the Wizard
  ///   Spellcasting text names its cantrips; none is a reference.
  /// Path: unhappy (invalid input: prose is not data)
  group('thin slice wizard text', () {
    /// Requirement: doc/specs/content-thin-slice.md FR-062 - the Wizard
    ///   Spellcasting text names Light, Mage Hand and Ray of Frost, and
    ///   none of them appears as a reference: the slice registers no
    ///   AlwaysPreparedSpells site, so the class holds no reference at all
    ///   (SRD 5.2.1, "Level 1: Spellcasting", pp. 77-78).
    /// Path: unhappy (invalid input: prose is not data)
    test(
      'the Spellcasting text names the cantrips; none is a reference',
      () async {
        final wizard = await classOf('wizard');
        final lookup = wizard.entry(FeatureId(spellcastingFeatureId));

        expect(lookup, isA<FeatureEntryFound>());
        final spellcasting = switch (lookup) {
          FeatureEntryFound(:final entry) => entry,
          FeatureEntryNotFound() => throw StateError(
            'the wizard has no $spellcastingFeatureId feature',
          ),
        };
        expect(
          containsPhrase(spellcasting.text, spellcastingCantripsPhrase),
          isTrue,
          reason: 'the Spellcasting text names the recommended cantrips',
        );
        expect(
          wizard.references,
          isEmpty,
          reason:
              'the slice registers no AlwaysPreparedSpells site, so Light, '
              'Mage Hand and Ray of Frost stay prose',
        );
      },
    );
  });

  /// Requirement: doc/specs/content-thin-slice.md FR-063, FR-084 - the
  ///   slice is closed under its references.
  /// Path: unhappy (dangling id: none permitted)
  group('thin slice reference closure', () {
    /// Requirement: doc/specs/content-thin-slice.md FR-063, FR-084 - the
    ///   slice is closed under its references: the decoded entries carry
    ///   exactly the nine lineage spellIds, each a bundled spell key equal
    ///   to the T3 spells, and validateContentSet over the three merged
    ///   documents returns ContentSetValid (SRD 5.2.1, "Elven Lineages",
    ///   p. 85).
    /// Path: unhappy (dangling id: none permitted)
    test(
      'the nine lineage spellIds resolve; the merged set is valid',
      () async {
        const decoder = JsonContentSetDecoder();
        final sets = <ContentSet>[];
        for (final text in sliceTexts.values) {
          sets.add(switch (decoder.decode(text)) {
            ContentDecoded(contentSet: final set) => set,
            ContentDecodeFailed(:final problems) => throw StateError(
              'a slice document failed to decode: ${problems.length} '
              'problems',
            ),
          });
        }
        final bundledSpellIds = {
          for (final entry in await entriesOf(ContentKind.spell))
            entry.key.id.value,
        };
        final lineageSpellIds = {
          for (final lineage in elvenLineages) ...[
            lineage.level1SpellId,
            lineage.level3SpellId,
            lineage.level5SpellId,
          ],
        };

        // The registered sites, collected from the decoded data, not a
        // hand-kept list (FR-084): each entry implementing
        // ContentReferences contributes its sites with its owner kind.
        final sites = <(ContentKind, ContentReference)>[];
        for (final set in sets) {
          for (final entry in set.entries) {
            if (entry is! ContentReferences) continue;
            // `ContentReferences` is not a subtype of `ContentEntry`, so the
            // type test above does not promote; the cast is checked.
            final owner = entry as ContentReferences;
            for (final site in owner.references) {
              sites.add((entry.key.kind, site));
            }
          }
        }

        expect(sites, hasLength(9));
        expect(
          sites.map((site) => site.$1),
          everyElement(ContentKind.species),
          reason: 'the species lineage spellIds are the only sites',
        );
        final targetIds = {for (final (_, site) in sites) site.target.id.value};
        expect(targetIds, lineageSpellIds);
        expect(bundledSpellIds, containsAll(targetIds));
        expect(validateContentSet(sets), isA<ContentSetValid>());
      },
    );

    /// Requirement: doc/specs/content-thin-slice.md FR-084 - a future
    ///   entry adding a site whose target is outside the slice fails the
    ///   pin: a synthetic entry with a dangling site makes
    ///   validateContentSet return ContentSetInvalid.
    /// Path: unhappy (dangling id: a new site with an absent target)
    test('a dangling site fails the whole-set validation', () {
      // Not const: ContentId's public constructor is a factory.
      final dangling = _DanglingEntry(
        ContentKey(ContentKind.species, ContentId('synthetic')),
        ContentKey(ContentKind.spell, ContentId('not_bundled')),
      );

      final validation = validateContentSet([
        ContentSet([dangling]),
      ]);

      expect(validation, isA<ContentSetInvalid>());
      final problems = (validation as ContentSetInvalid).problems;
      expect(problems, hasLength(1));
      expect(problems.single.kind, ContentProblemKind.unresolvedReference);
    });
  });

  const absentKeys = [
    (label: 'light', kind: ContentKind.spell, id: 'light'),
    (label: 'ray_of_frost', kind: ContentKind.spell, id: 'ray_of_frost'),
    (label: 'gnome', kind: ContentKind.species, id: 'gnome'),
    (label: 'species/fireball', kind: ContentKind.species, id: 'fireball'),
    (label: 'spell/wizard', kind: ContentKind.spell, id: 'wizard'),
  ];

  /// Requirement: per case - doc/specs/content-thin-slice.md FR-064,
  ///   FR-065, FR-066 - a lookup of an id the slice does not bundle
  ///   completes with ContentNotFound carrying that key and never throws:
  ///   spells in the SRD but not the slice (light, ray_of_frost), a
  ///   species in the SRD but not the slice (gnome), and ids that exist
  ///   only under another kind (species/fireball, spell/wizard)
  ///   (content-source-port.md FR-009, FR-010).
  /// Path: per case
  for (final row in absentKeys) {
    test('${row.label} is ContentNotFound', () async {
      final key = ContentKey(row.kind, ContentId(row.id));

      final lookup = await sliceSource.lookup(key);

      expect(lookup, ContentNotFound(key));
    });
  }

  /// Requirement: doc/specs/content-thin-slice.md FR-067 - each document
  ///   decodes with zero problems; the source holds exactly seventeen
  ///   entries.
  /// Path: happy
  group('thin slice decode', () {
    /// Requirement: doc/specs/content-thin-slice.md FR-067 - each of the
    ///   three embedded documents decodes with zero problems, producing 4,
    ///   1 and 12 entries of its kind, and the whole-set validation over
    ///   the merged documents passes; the check runs against the embedded
    ///   strings only, through the same decode path as host JSON.
    /// Path: happy
    test('each document decodes with zero problems; the set is valid', () {
      const decoder = JsonContentSetDecoder();
      final expectedCounts = {
        'species.json': (kind: ContentKind.species, count: 4),
        'class_wizard.json': (kind: ContentKind.characterClass, count: 1),
        'spells.json': (kind: ContentKind.spell, count: 12),
      };
      final sets = <ContentSet>[];

      for (final MapEntry(key: name, value: text) in sliceTexts.entries) {
        final result = decoder.decode(text);
        // Zero problems: a ContentDecodeFailed would fail this check, so
        // ContentDecoded is the only reachable variant below.
        expect(result, isA<ContentDecoded>(), reason: '$name decodes');
        final decoded = result as ContentDecoded;
        final expected = expectedCounts[name]!;
        expect(decoded.contentSet.entries, hasLength(expected.count));
        for (final entry in decoded.contentSet.entries) {
          expect(entry.key.kind, expected.kind, reason: name);
        }
        sets.add(decoded.contentSet);
      }

      expect(validateContentSet(sets), isA<ContentSetValid>());
    });

    /// Requirement: doc/specs/content-thin-slice.md FR-067 - a
    ///   BundledContentSource built from exactly the three texts holds
    ///   exactly the seventeen entries of FR-001 to FR-003.
    /// Path: happy
    test('the source holds exactly seventeen entries', () async {
      var count = 0;
      for (final kind in ContentKind.values) {
        count += (await entriesOf(kind)).length;
      }

      expect(count, 17);
    });
  });
}
