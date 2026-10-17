import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import 'named_text.dart';

/// A block of verbatim printed text, neutral between content kinds (FR-150).
///
/// The sealed family has exactly the five shapes the SRD prints: a
/// [ContentTextParagraph], a [ContentTextEntry] (a run-in heading and its
/// text), a [ContentTextBulletList], a [ContentTextTable] and a
/// [ContentTextEmbeddedStatBlock]. The factories give the short names and
/// return the variant; switch over the family exhaustively, with no default
/// branch. Text is stored verbatim — nothing trims, wraps, normalises or
/// rewords it (FR-029) — and lists are unmodifiable defensive copies.
@immutable
sealed class ContentTextBlock {
  const ContentTextBlock();

  /// Creates a paragraph from [text], which must pass the text rule
  /// (FR-028).
  factory ContentTextBlock.paragraph(String text) => ContentTextParagraph(text);

  /// Creates a run-in entry from [name] and [text], which must pass the name
  /// and text rules (FR-027, FR-028).
  factory ContentTextBlock.entry(String name, String text) =>
      ContentTextEntry(name, text);

  /// Creates a bullet list from [items], which must be non-empty and hold
  /// only texts (FR-028).
  factory ContentTextBlock.bulletList(Iterable<String> items) =>
      ContentTextBulletList(items);

  /// Creates a table from [header] and [rows], with an optional [title]
  /// (FR-151).
  factory ContentTextBlock.table({
    String? title,
    required List<String> header,
    required List<List<String>> rows,
  }) => ContentTextTable(title: title, header: header, rows: rows);

  /// Creates an embedded stat block from [lines], which must be non-empty
  /// and hold only texts (FR-028).
  factory ContentTextBlock.embeddedStatBlock(Iterable<String> lines) =>
      ContentTextEmbeddedStatBlock(lines);
}

/// A paragraph: one or more lines of printed text (FR-150).
@immutable
final class ContentTextParagraph extends ContentTextBlock {
  /// Creates a paragraph.
  ///
  /// Throws an [ArgumentError] carrying the name `text` and the offending
  /// value when [text] holds no non-whitespace character.
  ContentTextParagraph(String text) : text = _validatedText(text);

  /// The printed text, verbatim.
  final String text;

  @override
  bool operator ==(Object other) =>
      other is ContentTextParagraph && other.text == text;

  @override
  int get hashCode => Object.hash(ContentTextParagraph, text);

  @override
  String toString() => 'ContentTextParagraph($text)';
}

/// A run-in heading and its text, such as a trait's name and description
/// (FR-150).
@immutable
final class ContentTextEntry extends ContentTextBlock {
  /// Creates a run-in entry.
  ///
  /// Throws an [ArgumentError] carrying the name `name` or `text` and the
  /// offending value when [name] is empty or has surrounding whitespace, or
  /// [text] holds no non-whitespace character. Applying the name rule to
  /// entry names is stricter than a bare non-blank rule so that constructor
  /// and decoder agree (FR-094): a printed run-in heading never has
  /// surrounding whitespace.
  ContentTextEntry(String name, String text)
    : name = _validatedName(name),
      text = _validatedText(text);

  /// The run-in heading, verbatim.
  final String name;

  /// The printed text, verbatim.
  final String text;

  @override
  bool operator ==(Object other) =>
      other is ContentTextEntry && other.name == name && other.text == text;

  @override
  int get hashCode => Object.hash(ContentTextEntry, name, text);

  @override
  String toString() => 'ContentTextEntry($name)';
}

/// A list of bullet items (FR-150).
@immutable
final class ContentTextBulletList extends ContentTextBlock {
  /// Creates a bullet list from a defensive copy of [items].
  ///
  /// Throws an [ArgumentError] carrying the name `items` and the offending
  /// value when [items] is empty or holds a text with no non-whitespace
  /// character.
  ContentTextBulletList(Iterable<String> items)
    : items = List.unmodifiable(_validatedItems(items));

  /// The bullet items, verbatim; unmodifiable.
  final List<String> items;

  @override
  bool operator ==(Object other) =>
      other is ContentTextBulletList &&
      const ListEquality<String>().equals(other.items, items);

  @override
  int get hashCode => const ListEquality<String>().hash(items);

  @override
  String toString() => 'ContentTextBulletList($items)';
}

/// A printed table: a header row and body rows of equal width (FR-150).
@immutable
final class ContentTextTable extends ContentTextBlock {
  /// Creates a table from defensive copies of [header] and [rows].
  ///
  /// Throws an [ArgumentError] carrying the name `title`, `header` or `rows`
  /// and the offending value when [title] is present but blank, the header
  /// is empty or holds a blank cell, there is no row, a row is not exactly
  /// as wide as the header, or a row cell is neither empty nor holds a
  /// non-whitespace character.
  ContentTextTable({
    String? title,
    required List<String> header,
    required List<List<String>> rows,
  }) : title = _validatedTitle(title),
       header = List.unmodifiable(_validatedHeader(header)),
       rows = List.unmodifiable(
         _validatedRows(rows, header.length).map(_unmodifiableRow),
       );

  /// Whether [cell] is a valid body cell: empty, as in a printed blank cell,
  /// or containing at least one non-whitespace character (FR-151).
  static bool isValidCell(String cell) =>
      cell.isEmpty || NamedText.isValidText(cell);

  /// An unmodifiable copy of one [row], so no inner row is shared.
  static List<String> _unmodifiableRow(List<String> row) =>
      List.unmodifiable(row);

  /// The printed title, verbatim, or null when the table has none.
  final String? title;

  /// The header cells, verbatim; unmodifiable.
  final List<String> header;

  /// The body rows, verbatim, each as wide as [header]; unmodifiable, as is
  /// every row.
  final List<List<String>> rows;

  @override
  bool operator ==(Object other) =>
      other is ContentTextTable &&
      other.title == title &&
      const ListEquality<String>().equals(other.header, header) &&
      const ListEquality<List<String>>(
        ListEquality<String>(),
      ).equals(other.rows, rows);

  @override
  int get hashCode => Object.hash(
    ContentTextTable,
    title,
    const ListEquality<String>().hash(header),
    const ListEquality<List<String>>(ListEquality<String>()).hash(rows),
  );

  @override
  String toString() =>
      'ContentTextTable(title: $title, header: $header, '
      'rows: $rows)';
}

/// A stat block quoted inside another text, line by line (FR-150).
@immutable
final class ContentTextEmbeddedStatBlock extends ContentTextBlock {
  /// Creates an embedded stat block from a defensive copy of [lines].
  ///
  /// Throws an [ArgumentError] carrying the name `lines` and the offending
  /// value when [lines] is empty or holds a line with no non-whitespace
  /// character.
  ContentTextEmbeddedStatBlock(Iterable<String> lines)
    : lines = List.unmodifiable(_validatedLines(lines));

  /// The stat block's lines, verbatim; unmodifiable.
  final List<String> lines;

  @override
  bool operator ==(Object other) =>
      other is ContentTextEmbeddedStatBlock &&
      const ListEquality<String>().equals(other.lines, lines);

  @override
  int get hashCode => const ListEquality<String>().hash(lines);

  @override
  String toString() => 'ContentTextEmbeddedStatBlock($lines)';
}

String _validatedText(String text) {
  if (!NamedText.isValidText(text)) {
    throw ArgumentError.value(
      text,
      'text',
      'must contain at least one non-whitespace character',
    );
  }
  return text;
}

String _validatedName(String name) {
  if (!NamedText.isValidName(name)) {
    throw ArgumentError.value(
      name,
      'name',
      'must be non-empty with no leading or trailing whitespace',
    );
  }
  return name;
}

String? _validatedTitle(String? title) {
  if (title != null && !NamedText.isValidText(title)) {
    throw ArgumentError.value(
      title,
      'title',
      'must contain at least one non-whitespace character',
    );
  }
  return title;
}

List<String> _validatedHeader(List<String> header) {
  if (header.isEmpty) {
    throw ArgumentError.value(header, 'header', 'must have at least one cell');
  }
  for (final cell in header) {
    if (!NamedText.isValidText(cell)) {
      throw ArgumentError.value(
        cell,
        'header',
        'cells must contain at least one non-whitespace character',
      );
    }
  }
  return header;
}

List<List<String>> _validatedRows(List<List<String>> rows, int width) {
  if (rows.isEmpty) {
    throw ArgumentError.value(rows, 'rows', 'must have at least one row');
  }
  for (final row in rows) {
    if (row.length != width) {
      throw ArgumentError.value(
        row,
        'rows',
        'must be exactly $width cells wide',
      );
    }
    for (final cell in row) {
      if (!ContentTextTable.isValidCell(cell)) {
        throw ArgumentError.value(
          cell,
          'rows',
          'cells must be empty or contain a non-whitespace character',
        );
      }
    }
  }
  return rows;
}

List<String> _validatedLines(Iterable<String> lines) {
  final list = List.of(lines);
  if (list.isEmpty) {
    throw ArgumentError.value(lines, 'lines', 'must have at least one line');
  }
  for (final line in list) {
    if (!NamedText.isValidText(line)) {
      throw ArgumentError.value(
        line,
        'lines',
        'lines must contain at least one non-whitespace character',
      );
    }
  }
  return list;
}

List<String> _validatedItems(Iterable<String> items) {
  final list = List.of(items);
  if (list.isEmpty) {
    throw ArgumentError.value(items, 'items', 'must have at least one item');
  }
  for (final item in list) {
    if (!NamedText.isValidText(item)) {
      throw ArgumentError.value(
        item,
        'items',
        'items must contain at least one non-whitespace character',
      );
    }
  }
  return list;
}
