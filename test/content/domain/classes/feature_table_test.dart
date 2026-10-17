import 'package:srd5e/src/content/domain/classes/feature_table.dart';
import 'package:test/test.dart';

import '../../../support/argument_error_matcher.dart';

const _noRows = <List<TableCell>>[];
const _noColumns = <String>[];
final _landWardRows = [
  [TableCellText('Arid'), TableCellText('Fire')],
  [TableCellText('Polar'), TableCellText('Cold')],
  [TableCellText('Temperate'), TableCellText('Lightning')],
  [TableCellText('Tropical'), TableCellText('Poison')],
];
final _raggedRows = [
  [TableCellText('Arid'), TableCellText('Fire')],
  [TableCellText('Polar')],
];
final _mixedRows = [
  [TableCellText('Arid'), TableCellText('Fire')],
  [const TableCellInt(1), TableCellText('Cold')],
];

FeatureTable _wardTable({
  String? name,
  List<String>? columns,
  List<List<TableCell>>? rows,
}) => FeatureTable(
  name: name ?? "Nature's Ward",
  columns: columns ?? const ['Land Type', 'Resistance'],
  rows: rows ?? _landWardRows,
);

FeatureTable _slotTable() => FeatureTable(
  name: 'Creating Spell Slots',
  columns: const ['Spell Level', 'Sorcery Points'],
  rows: const [
    [TableCellInt(1), TableCellInt(2)],
    [TableCellInt(2), TableCellInt(3)],
  ],
);

void main() {
  /// Requirement: doc/specs/content-classes.md FR-066 - a `FeatureTable` is
  ///   a non-blank name, one or more non-blank headers, one or more rows,
  ///   every row as wide as the header list, and every column consistent in
  ///   kind (SRD 5.2.1, pp. 42, 46, 66).
  /// Path: happy
  group('FeatureTable constructor rows (Cases FT tables)', () {
    /// Requirement: per case
    /// Path: per case
    for (final c in [
      (
        label: 'a normalised table',
        requirement:
            'doc/specs/content-classes.md FR-066 - Nature\'s Ward, stored '
            'as two columns in four rows, constructs (Cases FT: '
            '"side-by-side pairs" stores the normalised shape)',
        path: 'unhappy (rule interaction)',
        build: () => _wardTable(),
        throwsFor: null,
        throwsForName: null,
      ),
      (
        label: 'integer cells',
        requirement:
            'doc/specs/content-classes.md FR-066 - a column of integers is '
            'consistent in kind',
        path: 'happy',
        build: _slotTable,
        throwsFor: null,
        throwsForName: null,
      ),
      (
        label: 'ragged table',
        requirement:
            'doc/specs/content-classes.md FR-066 - a row shorter than the '
            'header is rejected (Cases FT: "ragged table")',
        path: 'unhappy (boundary)',
        build: () => _wardTable(rows: _raggedRows),
        throwsFor: null,
        throwsForName: 'rows',
      ),
      (
        label: 'mixed column',
        requirement:
            'doc/specs/content-classes.md FR-066 - a column mixing text and '
            'integers is rejected (Cases FT: "mixed column")',
        path: 'unhappy (invalid input)',
        build: () => _wardTable(rows: _mixedRows),
        throwsFor: null,
        throwsForName: 'rows',
      ),
      (
        label: 'table with no rows',
        requirement:
            'doc/specs/content-classes.md FR-066 - an empty rows array is '
            'rejected (Cases FT: "table with no rows")',
        path: 'unhappy (empty case)',
        build: () => _wardTable(rows: _noRows),
        throwsFor: throwsArgumentErrorFor('rows', _noRows),
        throwsForName: null,
      ),
      (
        label: 'no columns',
        requirement:
            'doc/specs/content-classes.md FR-066 - an empty header list is '
            'rejected',
        path: 'unhappy (empty case)',
        build: () => _wardTable(columns: _noColumns),
        throwsFor: throwsArgumentErrorFor('columns', _noColumns),
        throwsForName: null,
      ),
      (
        label: 'blank header',
        requirement:
            'doc/specs/content-classes.md FR-066 - a blank header is '
            'rejected',
        path: 'unhappy (invalid input)',
        build: () => _wardTable(columns: const ['Land Type', ' ']),
        throwsFor: throwsArgumentErrorFor('columns', ' '),
        throwsForName: null,
      ),
      (
        label: 'blank name',
        requirement:
            'doc/specs/content-classes.md FR-066 - a blank name is rejected',
        path: 'unhappy (invalid input)',
        build: () => _wardTable(name: ' '),
        throwsFor: throwsArgumentErrorFor('name', ' '),
        throwsForName: null,
      ),
    ]) {
      test('${c.label} [${c.path}]', () {
        if (c.throwsFor != null) {
          expect(c.build, c.throwsFor);
        } else if (c.throwsForName != null) {
          expect(
            c.build,
            throwsA(
              isA<ArgumentError>().having(
                (e) => e.name,
                'name',
                c.throwsForName,
              ),
            ),
          );
        } else {
          expect(c.build(), isA<FeatureTable>());
        }
      });
    }
  });

  /// Requirement: doc/specs/content-classes.md FR-066, FR-008 - the limits
  ///   are public predicates; the rows are defensively copied and
  ///   unmodifiable; value equality holds.
  /// Path: happy
  test('predicates, immutability and value equality hold', () {
    expect(FeatureTable.minColumns, 1);
    expect(FeatureTable.minRows, 1);
    expect(FeatureTable.isValidColumns(['A']), isTrue);
    expect(FeatureTable.isValidColumns(const []), isFalse);
    // Every header must be non-blank, not merely one of them.
    expect(FeatureTable.isValidColumns([' ', 'A']), isFalse);
    expect(
      FeatureTable.isValidRows(1, [
        [TableCellText('A')],
      ]),
      isTrue,
    );
    expect(FeatureTable.isValidRows(1, const []), isFalse);
    // Every row must be as wide as the header list, not merely one of them.
    expect(
      FeatureTable.isValidRows(1, [
        [TableCellText('A')],
        [TableCellText('A'), TableCellText('B')],
      ]),
      isFalse,
    );
    // One column is the minimum and is accepted: the bound is inclusive.
    expect(
      _wardTable(
        columns: const ['Level'],
        rows: [
          [TableCellText('One')],
        ],
      ).columns,
      ['Level'],
    );

    final rows = [
      [TableCellText('Arid'), TableCellText('Fire')],
    ];
    final table = _wardTable(rows: rows);
    rows.clear();
    expect(table.rows.length, 1);
    expect(() => table.rows.clear(), throwsUnsupportedError);
    expect(() => table.rows.first.clear(), throwsUnsupportedError);

    expect(
      table,
      equals(
        _wardTable(
          rows: [
            [TableCellText('Arid'), TableCellText('Fire')],
          ],
        ),
      ),
    );
    expect(
      table.hashCode,
      _wardTable(
        rows: [
          [TableCellText('Arid'), TableCellText('Fire')],
        ],
      ).hashCode,
    );
    expect(table.toString(), "FeatureTable(Nature's Ward)");
    expect(TableCellText('Beast').hashCode, TableCellText('Beast').hashCode);
    expect(TableCellText('Beast').toString(), 'TableCellText(Beast)');
    expect(const TableCellInt(2).hashCode, const TableCellInt(2).hashCode);
    expect(const TableCellInt(2).toString(), 'TableCellInt(2)');
  });
}
