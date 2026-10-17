import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import '../named_text.dart';

/// One cell of a [FeatureTable]: printed text or a printed integer (FR-066).
///
/// The family is sealed with exactly the two variants, exhaustive in a
/// `switch` without a default. Every cell of one column has the same
/// variant — all text or all integers — which the [FeatureTable]
/// constructor checks.
@immutable
sealed class TableCell {
  const TableCell();
}

/// A cell that holds printed text (FR-066).
@immutable
final class TableCellText extends TableCell {
  /// Creates the cell.
  ///
  /// Throws an [ArgumentError] carrying the name `text` and the offending
  /// value when [text] is blank (FR-066: every cell is a JSON string or
  /// integer and a table's text is non-blank).
  TableCellText(String text) : text = _validatedText(text);

  /// The printed text, verbatim.
  final String text;

  static String _validatedText(String text) {
    if (!NamedText.isValidText(text)) {
      throw ArgumentError.value(text, 'text', 'must be non-blank');
    }
    return text;
  }

  @override
  bool operator ==(Object other) =>
      other is TableCellText && other.text == text;

  @override
  int get hashCode => Object.hash(TableCellText, text);

  @override
  String toString() => 'TableCellText($text)';
}

/// A cell that holds a printed integer (FR-066).
@immutable
final class TableCellInt extends TableCell {
  /// Creates the cell.
  const TableCellInt(this.value);

  /// The printed integer, verbatim.
  final int value;

  @override
  bool operator ==(Object other) =>
      other is TableCellInt && other.value == value;

  @override
  int get hashCode => Object.hash(TableCellInt, value);

  @override
  String toString() => 'TableCellInt($value)';
}

/// A table the SRD prints inside a feature and that no fact captures: Beast
/// Shapes on Wild Shape, Creating Spell Slots on Font of Magic, Nature's
/// Ward on Nature's Ward (FR-066, FR-067; SRD 5.2.1, pp. 42, 46, 66).
///
/// The stored [rows] are the printed rows, normalised (FR-066): a table
/// printed as side-by-side column pairs is stored as one pair per row, the
/// normalisation the decoder and the extraction apply — this type stores
/// normalised rows and restructures nothing. No cell is ever changed.
@immutable
final class FeatureTable {
  /// Creates the table from defensive copies of the collection fields.
  ///
  /// Throws an [ArgumentError] carrying the name of the offending field and
  /// the offending value when [name] or a [columns] header is blank,
  /// [columns] is empty, [rows] is empty, a row is not exactly as wide as
  /// [columns] (FR-066), or one column's cells mix text and integers
  /// (FR-066).
  FeatureTable({
    required String name,
    required List<String> columns,
    required List<List<TableCell>> rows,
  }) : name = _validatedName(name),
       columns = List.unmodifiable(_validatedColumns(columns)),
       rows = List.unmodifiable(
         _validatedRows(columns, rows).map(List<TableCell>.unmodifiable),
       );

  /// The fewest columns a table may have: one (FR-066). The constant the
  /// decoder reuses instead of repeating the literal (FR-007).
  static const int minColumns = 1;

  /// The fewest rows a table may have: one (FR-066). The constant the
  /// decoder reuses instead of repeating the literal (FR-007).
  static const int minRows = 1;

  /// The table's printed name, verbatim ("Beast Shapes").
  final String name;

  /// The printed column headers, in left-to-right order; unmodifiable, never
  /// empty (FR-066).
  final List<String> columns;

  /// The rows, each exactly as wide as [columns]; unmodifiable, never empty
  /// (FR-066).
  final List<List<TableCell>> rows;

  /// Whether [columns] is a header list a table may have: at least
  /// [minColumns] non-blank headers (FR-066). The predicate the decoder
  /// reuses (FR-007).
  static bool isValidColumns(List<String> columns) =>
      columns.length >= minColumns && columns.every(NamedText.isValidName);

  /// Whether [rows] is a row list a table of [columnCount] columns may have:
  /// at least [minRows] rows, each exactly [columnCount] wide (FR-066). The
  /// predicate the decoder reuses (FR-007).
  static bool isValidRows(int columnCount, List<List<TableCell>> rows) =>
      rows.length >= minRows && rows.every((row) => row.length == columnCount);

  static String _validatedName(String name) {
    if (!NamedText.isValidName(name)) {
      throw ArgumentError.value(
        name,
        'name',
        'must be non-empty with no leading or trailing whitespace',
      );
    }
    return name;
  }

  static List<String> _validatedColumns(List<String> columns) {
    if (columns.length < minColumns) {
      throw ArgumentError.value(
        columns,
        'columns',
        'must have at least $minColumns header',
      );
    }
    for (final column in columns) {
      if (!NamedText.isValidName(column)) {
        throw ArgumentError.value(column, 'columns', 'must be non-blank');
      }
    }
    return columns;
  }

  static List<List<TableCell>> _validatedRows(
    List<String> columns,
    List<List<TableCell>> rows,
  ) {
    if (rows.length < minRows) {
      throw ArgumentError.value(
        rows,
        'rows',
        'must have at least $minRows row',
      );
    }
    for (final row in rows) {
      if (row.length != columns.length) {
        throw ArgumentError.value(
          row,
          'rows',
          'must be exactly as wide as the header list',
        );
      }
    }
    // Every column consistent in kind: all text or all integers (FR-066).
    for (var column = 0; column < columns.length; column++) {
      for (var row = 1; row < rows.length; row++) {
        final first = rows[0][column];
        final cell = rows[row][column];
        if (first.runtimeType != cell.runtimeType) {
          throw ArgumentError.value(
            cell,
            'rows',
            'must hold one kind of cell per column: all text or all '
                'integers (FR-066)',
          );
        }
      }
    }
    return rows;
  }

  @override
  bool operator ==(Object other) =>
      other is FeatureTable &&
      other.name == name &&
      const ListEquality<String>().equals(other.columns, columns) &&
      const DeepCollectionEquality().equals(other.rows, rows);

  @override
  int get hashCode => Object.hash(
    FeatureTable,
    name,
    const ListEquality<String>().hash(columns),
    const DeepCollectionEquality().hash(rows),
  );

  @override
  String toString() => 'FeatureTable($name)';
}
