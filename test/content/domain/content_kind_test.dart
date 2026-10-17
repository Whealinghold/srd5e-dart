import 'package:srd5e/src/content/domain/content_kind.dart';
import 'package:test/test.dart';

/// One pinned index of the declaration order, which FR-016, FR-071 and
/// FR-127 order by (FR-142).
typedef _IndexCase = ({
  String label,
  String requirement,
  String path,
  ContentKind kind,
  int index,
});

final List<_IndexCase> _indexes = [
  for (var i = 0; i < ContentKind.values.length; i++)
    (
      label: ContentKind.values[i].name,
      requirement:
          'doc/specs/content-schema-and-decoder.md FR-142 - each '
          'index is pinned, because FR-016, FR-071 and FR-127 order by it, '
          'so ${ContentKind.values[i].name} keeps index $i',
      path: 'happy',
      kind: ContentKind.values[i],
      index: i,
    ),
];

/// Exhaustive over the enum with no default branch (FR-142).
String _describe(ContentKind kind) => switch (kind) {
  ContentKind.species => 'species',
  ContentKind.background => 'background',
  ContentKind.characterClass => 'characterClass',
  ContentKind.feat => 'feat',
  ContentKind.equipment => 'equipment',
  ContentKind.spell => 'spell',
  ContentKind.magicItem => 'magicItem',
  ContentKind.monster => 'monster',
  ContentKind.poison => 'poison',
  ContentKind.trap => 'trap',
  ContentKind.contagion => 'contagion',
};

void main() {
  /// Requirement: doc/specs/content-schema-and-decoder.md FR-142 - exactly
  ///   one value per row of the kind table, named the singular of the SRD
  ///   heading, in declaration order (SRD 5.2.1, "Contents", p. 2);
  ///   doc/specs/content-schema-and-decoder.md FR-129 - the last three
  ///   values are the toolbox catalogue kinds poison, trap and contagion,
  ///   in the FR-129 order; doc/specs/content-schema-and-decoder.md
  ///   FR-130 - the declaration is the package's only one.
  /// Path: happy
  test('declares exactly eleven values in declaration order', () {
    expect(ContentKind.values.map((kind) => kind.name), [
      'species',
      'background',
      'characterClass',
      'feat',
      'equipment',
      'spell',
      'magicItem',
      'monster',
      'poison',
      'trap',
      'contagion',
    ]);
  });

  /// Requirement: per case
  /// Path: per case
  for (final c in _indexes) {
    test('${c.label} keeps index ${c.index} [${c.path}]', () {
      expect(c.kind.index, c.index);
    });
  }

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-142 - "Animals"
  ///   maps to monster; there is no animal value.
  /// Path: unhappy (invalid input)
  test('there is no animal value', () {
    expect(
      ContentKind.values.map((kind) => kind.name),
      isNot(contains('animal')),
    );
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-142 - a switch
  ///   over ContentKind is exhaustive without a default.
  /// Path: happy
  test('a switch over every value selects its case', () {
    expect(
      [for (final kind in ContentKind.values) _describe(kind)],
      [
        'species',
        'background',
        'characterClass',
        'feat',
        'equipment',
        'spell',
        'magicItem',
        'monster',
        'poison',
        'trap',
        'contagion',
      ],
    );
  });
}
