/// One data row of a [MarkdownTable].
final class TableRow {
  /// Creates a row at [line] with its already trimmed [cells].
  const TableRow({required this.line, required this.cells});

  /// The 1-based line of the row in the document.
  final int line;

  /// The cell texts, trimmed, with `\|` unescaped to `|`. Backticks are kept;
  /// see [stripBackticks].
  final List<String> cells;

  /// The cell at [index], or null when the row is shorter.
  String? cell(int index) =>
      index >= 0 && index < cells.length ? cells[index] : null;
}

/// A pipe table found by [parseMarkdownTables].
final class MarkdownTable {
  /// Creates a table.
  const MarkdownTable({
    required this.headerLine,
    required this.header,
    required this.rows,
    required this.heading,
    this.enclosingSectionNumber,
  });

  /// The 1-based line of the header row.
  final int headerLine;

  /// The header cell texts, trimmed.
  final List<String> header;

  /// The data rows, in document order (the separator row is not included).
  final List<TableRow> rows;

  /// The nearest heading above the table without its `#` marks, or null when
  /// the table precedes every heading.
  final String? heading;

  /// The section number the [heading] starts with (`4.2`), or null.
  String? get sectionNumber => headingSectionNumber(heading);

  /// The first component of [sectionNumber] (`4` for `4.2`), or null.
  int? get topSection {
    final number = sectionNumber;
    if (number == null) return null;
    return int.parse(number.split('.').first);
  }

  /// The section number of the nearest numbered heading above the table,
  /// looking through unnumbered sub-headings nested under it (an unnumbered
  /// heading of the same or a higher level ends the section), or null.
  final String? enclosingSectionNumber;

  /// The first component of [enclosingSectionNumber], or null.
  int? get enclosingTopSection {
    final number = enclosingSectionNumber;
    if (number == null) return null;
    return int.parse(number.split('.').first);
  }
}

final RegExp _headingPattern = RegExp(r'^ {0,3}#{1,6}\s+(.*?)\s*#*\s*$');
final RegExp _fencePattern = RegExp(r'^ {0,3}(```|~~~)');
final RegExp _separatorCell = RegExp(r'^:?-+:?$');
final RegExp _sectionNumberPattern = RegExp(
  r'^(\d+(?:\.\d+)*)[a-z]?\.?(?:\s|$)',
);

/// The section number at the start of [heading] (`4.2 Foo` gives `4.2`,
/// `4. Requirements` gives `4`), or null when there is none.
String? headingSectionNumber(String? heading) => heading == null
    ? null
    : _sectionNumberPattern.firstMatch(heading)?.group(1);

/// Removes every backtick from [cell] (`` `FR-1` `` gives `FR-1`).
String stripBackticks(String cell) => cell.replaceAll('`', '');

/// Splits one table line into trimmed cells.
///
/// The optional leading and trailing pipe is dropped, and `\|` is a literal
/// pipe inside a cell rather than a separator.
List<String> splitTableRow(String line) {
  var text = line.trim();
  if (text.startsWith('|')) text = text.substring(1);
  final cells = <String>[];
  final current = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    final char = text[i];
    if (char == r'\' && i + 1 < text.length && text[i + 1] == '|') {
      current.write('|');
      i++;
    } else if (char == '|') {
      cells.add(current.toString().trim());
      current.clear();
    } else {
      current.write(char);
    }
  }
  final last = current.toString().trim();
  // A trailing pipe leaves an empty last piece that is not a cell.
  if (last.isNotEmpty || !line.trimRight().endsWith('|')) cells.add(last);
  return cells;
}

bool _isSeparatorRow(String line) {
  if (!line.contains('-')) return false;
  final cells = splitTableRow(line);
  return cells.isNotEmpty && cells.every(_separatorCell.hasMatch);
}

bool _looksLikeRow(String line) => line.trimLeft().startsWith('|');

/// Parses every pipe table of [markdown], skipping fenced code blocks.
///
/// A table is a row starting with `|`, then a separator row, then the rows
/// that follow while they start with `|`. Line numbers are 1-based.
List<MarkdownTable> parseMarkdownTables(String markdown) {
  final lines = markdown
      .split('\n')
      .map((l) => l.endsWith('\r') ? l.substring(0, l.length - 1) : l)
      .toList();
  final tables = <MarkdownTable>[];
  String? heading;
  String? enclosing;
  var enclosingLevel = 0;
  String? fence;
  var i = 0;
  while (i < lines.length) {
    final line = lines[i];
    final fenceMatch = _fencePattern.firstMatch(line);
    if (fence != null) {
      if (fenceMatch != null && fenceMatch.group(1) == fence) fence = null;
      i++;
      continue;
    }
    if (fenceMatch != null) {
      fence = fenceMatch.group(1);
      i++;
      continue;
    }
    final headingMatch = _headingPattern.firstMatch(line);
    if (headingMatch != null) {
      heading = headingMatch.group(1);
      final level = line.trimLeft().indexOf(' ');
      final number = headingSectionNumber(heading);
      if (number != null) {
        final sameTop =
            enclosing != null &&
            enclosing.split('.').first == number.split('.').first;
        enclosingLevel = sameTop && enclosingLevel < level
            ? enclosingLevel
            : level;
        enclosing = number;
      } else if (level <= enclosingLevel) {
        enclosing = null;
        enclosingLevel = 0;
      }
      i++;
      continue;
    }
    if (_looksLikeRow(line) &&
        i + 1 < lines.length &&
        _looksLikeRow(lines[i + 1]) &&
        _isSeparatorRow(lines[i + 1])) {
      final header = splitTableRow(line);
      final rows = <TableRow>[];
      var j = i + 2;
      while (j < lines.length && _looksLikeRow(lines[j])) {
        rows.add(TableRow(line: j + 1, cells: splitTableRow(lines[j])));
        j++;
      }
      tables.add(
        MarkdownTable(
          headerLine: i + 1,
          header: header,
          rows: rows,
          heading: heading,
          enclosingSectionNumber: enclosing,
        ),
      );
      i = j;
      continue;
    }
    i++;
  }
  return tables;
}
