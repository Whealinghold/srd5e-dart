import 'lexer.dart';
import 'markdown_tables.dart';

/// One requirement row of a spec.
final class SpecRequirement {
  /// Creates a requirement row.
  const SpecRequirement({
    required this.id,
    required this.line,
    required this.moved,
  });

  /// The id, for example `FR-012`.
  final String id;

  /// The 1-based line of the row.
  final int line;

  /// Whether the row is a moved-id row (second cell starts `Withdrawn:`).
  final bool moved;
}

/// The requirement ids of one spec (FR-071), with moved ids (FR-087) marked.
final class SpecRequirements {
  /// Creates a result.
  const SpecRequirements({
    required this.requirements,
    required this.hasSection4,
    required this.hasRequirementsTable,
  });

  /// Every row of section 4 whose first cell is an id, in document order.
  final List<SpecRequirement> requirements;

  /// Whether the document has a top-level section 4 heading at all.
  final bool hasSection4;

  /// Whether section 4 holds at least one table with an id row.
  final bool hasRequirementsTable;

  /// Every id, moved ones included.
  Set<String> get ids => {for (final r in requirements) r.id};

  /// The ids of the moved-id rows.
  Set<String> get movedIds => {
    for (final r in requirements)
      if (r.moved) r.id,
  };

  /// The ids that are not moved: the ones a test can cover and a citation may
  /// name.
  Set<String> get activeIds => ids.difference(movedIds);

  /// The ids that appear on more than one row, sorted.
  List<String> get duplicateIds {
    final seen = <String>{};
    final duplicates = <String>{};
    for (final r in requirements) {
      if (!seen.add(r.id)) duplicates.add(r.id);
    }
    return duplicates.toList()..sort();
  }
}

/// A requirement id: first cell of a requirements row (FR-071).
final RegExp requirementIdPattern = RegExp(r'^FR-\d+$');

final RegExp _movedPattern = RegExp(r'^Withdrawn\s*:');

/// Whether [row] is a moved-id row: its second cell begins with the word
/// `Withdrawn` and a colon (`architecture-guardrails.md` section 3).
bool isMovedIdRow(TableRow row) {
  final second = row.cell(1);
  return second != null && _movedPattern.hasMatch(second);
}

/// Parses the requirement ids of the spec text [markdown] (FR-071).
///
/// The requirements are every row in section 4 whose first cell matches
/// `^FR-\d+$`; rows of other section 4 tables (a label column, a `none` row)
/// are not ids. Rows outside section 4 are ignored. A document with no
/// section 4, or none with an id row, yields an empty list and the flags say
/// which (never an exception).
SpecRequirements parseSpecRequirements(String markdown) {
  final tables = parseMarkdownTables(markdown);
  final requirements = <SpecRequirement>[];
  for (final table in tables) {
    if (table.enclosingTopSection != 4) continue;
    for (final row in table.rows) {
      final first = row.cell(0);
      if (first == null || !requirementIdPattern.hasMatch(first)) continue;
      requirements.add(
        SpecRequirement(id: first, line: row.line, moved: isMovedIdRow(row)),
      );
    }
  }
  return SpecRequirements(
    requirements: requirements,
    hasSection4: _hasSection4Heading(markdown),
    hasRequirementsTable: requirements.isNotEmpty,
  );
}

final RegExp _section4Heading = RegExp(
  r'^#{1,6}\s+4\.?(\s|$)',
  multiLine: true,
);

bool _hasSection4Heading(String markdown) =>
    _section4Heading.hasMatch(markdown);

/// The number of an id (`FR-012` gives 12), for ordering.
int frNumber(String id) {
  final match = RegExp(r'^FR-(\d+)$').firstMatch(id);
  if (match == null) throw ArgumentError.value(id, 'id', 'not an FR id');
  return int.parse(match.group(1)!);
}

/// One spec citation (FR-070): `doc/specs/<name>.md` and the ids after it.
final class Citation {
  /// Creates a citation.
  const Citation({
    required this.specName,
    required this.ids,
    required this.ranges,
    required this.line,
  });

  /// The spec file name without `.md` (`d20-tests`).
  final String specName;

  /// The repository-relative spec path (`doc/specs/d20-tests.md`).
  String get specPath => 'doc/specs/$specName.md';

  /// The ids the citation names, as written, in order. For a range both
  /// endpoints are listed. Empty when no id follows the file.
  final List<String> ids;

  /// The text of every range in the citation (`FR-1 to FR-3`, `FR-1-FR-3`,
  /// `FR-1..3`). A range is a Violation of FR-054; its endpoints are in [ids].
  final List<String> ranges;

  /// The 1-based line of the file token.
  final int line;
}

/// Where a requirement citation was written.
enum RequirementSource {
  /// A `Requirement:` doc comment, continuation lines included.
  comment,

  /// The string value of a `requirement:` field.
  field,
}

/// The text of one `Requirement:` comment or `requirement:` field, with the
/// citations found in it.
final class RequirementText {
  /// Creates a record.
  const RequirementText({
    required this.source,
    required this.line,
    required this.text,
    required this.citations,
  });

  /// Whether it came from a comment or a field.
  final RequirementSource source;

  /// The 1-based line where the comment or string starts.
  final int line;

  /// The text after `Requirement:` (continuation lines joined by `\n`), or the
  /// string value.
  final String text;

  /// The citations in [text], in order. Empty when it cites nothing.
  final List<Citation> citations;
}

final RegExp _fileToken = RegExp(r'doc/specs/([a-z0-9_-]+)\.md');
final RegExp _idAt = RegExp(r'FR-\d+');
final RegExp _rangeAt = RegExp(
  r'(?:\s+to\s+(FR-\d+)|-(FR-\d+)|\.\.(?:FR-)?(\d+))',
);
final RegExp _separatorAt = RegExp(r'(?:\s*,\s*|\s+and\s+|\s*&\s*)(FR-\d+)');

/// Parses the citations in [text] by the FR-070 grammar.
///
/// A citation is `doc/specs/<name>.md`, whitespace, an id, then more ids
/// separated by `,`, `and` or `&`. A range after an id is recorded in
/// [Citation.ranges]. [firstLine] is the line of the first character; each
/// `\n` in [text] advances it.
List<Citation> parseCitations(String text, {int firstLine = 1}) {
  final citations = <Citation>[];
  var scanFrom = 0;
  for (final match in _fileToken.allMatches(text)) {
    if (match.start < scanFrom) continue;
    final ids = <String>[];
    final ranges = <String>[];
    var pos = match.end;
    var end = pos;
    while (pos < text.length && _isSpace(text.codeUnitAt(pos))) {
      pos++;
    }
    final first = _idAt.matchAsPrefix(text, pos);
    if (first != null) {
      ids.add(first.group(0)!);
      pos = first.end;
      end = pos;
      while (true) {
        final range = _rangeAt.matchAsPrefix(text, pos);
        if (range != null) {
          final endpoint =
              range.group(1) ?? range.group(2) ?? 'FR-${range.group(3)}';
          ranges.add('${ids.last}${text.substring(pos, range.end)}');
          ids.add(endpoint);
          pos = range.end;
          end = pos;
          continue;
        }
        final separated = _separatorAt.matchAsPrefix(text, pos);
        if (separated == null) break;
        ids.add(separated.group(1)!);
        pos = separated.end;
        end = pos;
      }
    }
    scanFrom = end;
    citations.add(
      Citation(
        specName: match.group(1)!,
        ids: ids,
        ranges: ranges,
        line:
            firstLine + '\n'.allMatches(text.substring(0, match.start)).length,
      ),
    );
  }
  return citations;
}

bool _isSpace(int unit) =>
    unit == 0x20 || unit == 0x09 || unit == 0x0A || unit == 0x0D;

final RegExp _requirementStart = RegExp(r'^\s*Requirement:\s*(.*)$');
final RegExp _fieldPrefix = RegExp(r'(?:^|[^A-Za-z0-9_$])requirement\s*:$');

/// Finds every `Requirement:` comment and `requirement:` string field in the
/// Dart [source] and parses their citations (FR-070).
///
/// A comment's text runs over the `///   ` continuation lines (three spaces
/// after the slashes) that directly follow it. A field's text is its string
/// literal, adjacent literals joined.
List<RequirementText> parseRequirementTexts(String source) {
  final lexed = lex(source);
  final result = <RequirementText>[];

  final docs = [
    for (final c in lexed.comments)
      if (c.kind == CommentKind.doc) c,
  ];
  for (var i = 0; i < docs.length; i++) {
    final body = _docBody(docs[i].text);
    final start = _requirementStart.firstMatch(body);
    if (start == null) continue;
    final startLine = docs[i].line;
    final parts = [start.group(1)!];
    var last = startLine;
    while (i + 1 < docs.length && docs[i + 1].line == last + 1) {
      final next = _docBody(docs[i + 1].text);
      if (!next.startsWith('   ') || next.trim().isEmpty) break;
      parts.add(next.trim());
      last = docs[i + 1].line;
      i++;
    }
    final text = parts.join('\n');
    result.add(
      RequirementText(
        source: RequirementSource.comment,
        line: startLine,
        text: text,
        citations: parseCitations(text, firstLine: startLine),
      ),
    );
  }

  final byOffset = {for (final s in lexed.strings) s.offset: s};
  final consumed = <int>{};
  for (final s in lexed.strings) {
    if (consumed.contains(s.offset)) continue;
    final before = lexed.code.substring(0, s.offset).trimRight();
    if (!_fieldPrefix.hasMatch(before)) continue;
    final buffer = StringBuffer(s.value);
    var current = s;
    while (!current.isInterpolated) {
      final end = _stringEnd(lexed.code, current);
      if (end == null) break;
      var next = end;
      while (next < lexed.code.length &&
          _isSpace(lexed.code.codeUnitAt(next))) {
        next++;
      }
      final following = byOffset[next];
      if (following == null) break;
      consumed.add(following.offset);
      buffer.write(following.value);
      current = following;
    }
    final text = buffer.toString();
    result.add(
      RequirementText(
        source: RequirementSource.field,
        line: s.line,
        text: text,
        citations: parseCitations(text, firstLine: s.line),
      ),
    );
  }
  result.sort((a, b) => a.line.compareTo(b.line));
  return result;
}

String _docBody(String commentText) {
  var body = commentText.startsWith('///')
      ? commentText.substring(3)
      : commentText;
  while (body.endsWith('\n') || body.endsWith('\r')) {
    body = body.substring(0, body.length - 1);
  }
  return body;
}

/// The offset just after the closing quote of [s] in blanked [code], or null.
int? _stringEnd(String code, LexString s) {
  var pos = s.offset;
  if (s.isRaw) pos++;
  if (pos >= code.length) return null;
  final quote = code[pos];
  if (quote != "'" && quote != '"') return null;
  final triple = code.startsWith(quote * 3, pos);
  final delimiter = triple ? quote * 3 : quote;
  final close = code.indexOf(delimiter, pos + delimiter.length);
  return close < 0 ? null : close + delimiter.length;
}
