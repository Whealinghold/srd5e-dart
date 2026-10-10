import 'declarations.dart';
import 'markdown_tables.dart';
import 'source_set.dart';

/// Support for the signal catalogue checks FR-041 to FR-048 of
/// `doc/specs/architecture-guardrails.md` (section 4.3): the signal and
/// attribute constants declared in `lib/`, and the parsed catalogue
/// `doc/observability/signals.md`.
///
/// Everything here is pure: it reads a [SourceSet] and returns data.

/// The repository-relative path of the signal catalogue.
const String signalCataloguePath = 'doc/observability/signals.md';

/// The header cells of the catalogue table, in order (FR-041).
const List<String> signalCatalogueHeader = [
  'Name',
  'Type',
  'Unit',
  'Attributes',
  'Emitted by',
  'Purpose',
  'Suggested monitoring',
];

/// Cell values that count as empty in a Purpose or Suggested monitoring cell
/// (FR-045, FR-046), compared trimmed and lower-cased.
const Set<String> catalogueCellPlaceholders = {'todo', 'tbd', 'n/a', '-'};

/// The kind of a constant in a signals class.
enum SignalConstantKind {
  /// A `...Metric` member: a counter, histogram or gauge name.
  metric,

  /// A `...Span` member: a span name.
  span,

  /// A `...LogEvent` member: a constant log message.
  logEvent,

  /// A `...Attribute` member of a `*Signals` class, or any `AttributeKeys`
  /// member.
  attribute,

  /// A `...Value` member: an attribute value (checked by FR-085).
  value,
}

/// A `static const String` member of a signals class in `lib/`.
final class SignalConstant {
  /// Creates a record.
  const SignalConstant({
    required this.path,
    required this.line,
    required this.className,
    required this.member,
    required this.kind,
    required this.value,
  });

  /// The repository-relative path of the declaring file.
  final String path;

  /// The 1-based line of the member.
  final int line;

  /// The declaring class.
  final String className;

  /// The member identifier.
  final String member;

  /// The kind given by the identifier's suffix, or by the class for
  /// `AttributeKeys`.
  final SignalConstantKind kind;

  /// The literal initialiser's value.
  final String value;

  /// Whether this is a signal constant (metric, span or log event).
  bool get isSignal =>
      kind == SignalConstantKind.metric ||
      kind == SignalConstantKind.span ||
      kind == SignalConstantKind.logEvent;
}

/// The name of the shared attribute keys class.
const String attributeKeysClass = 'AttributeKeys';

/// Whether [name] is a signals class name: ends in `Signals`, or is exactly
/// `AttributeKeys`.
bool isSignalsClassName(String name) =>
    name.endsWith('Signals') || name == attributeKeysClass;

final RegExp _member = RegExp(
  r'\bstatic\s+const\s+(?:String\s+)?([A-Za-z_]\w*)\s*=\s*',
);

SignalConstantKind? _kindOf(String className, String member) {
  if (className == attributeKeysClass) return SignalConstantKind.attribute;
  if (member.endsWith('Metric')) return SignalConstantKind.metric;
  if (member.endsWith('Span')) return SignalConstantKind.span;
  if (member.endsWith('LogEvent')) return SignalConstantKind.logEvent;
  if (member.endsWith('Attribute')) return SignalConstantKind.attribute;
  if (member.endsWith('Value')) return SignalConstantKind.value;
  return null;
}

/// Every signal, attribute and attribute value constant declared under `lib/`,
/// sorted by path then line.
///
/// A member whose initialiser is not a string literal, or whose identifier has
/// no recognised suffix (outside `AttributeKeys`), is not listed: FR-037
/// reports it.
List<SignalConstant> signalConstants(SourceSet sources) {
  final result = <SignalConstant>[];
  for (final path in sources.dartPaths('lib/')) {
    final lexed = sources.lexed(path);
    final code = lexed.code;
    for (final declaration in declarationsIn(path, lexed)) {
      if (!isSignalsClassName(declaration.name)) continue;
      final body = code.substring(declaration.bodyStart, declaration.bodyEnd);
      for (final match in _member.allMatches(body)) {
        final member = match.group(1)!;
        final kind = _kindOf(declaration.name, member);
        if (kind == null) continue;
        final literalOffset = declaration.bodyStart + match.end;
        final literal = lexed.strings
            .where((s) => s.offset == literalOffset)
            .firstOrNull;
        if (literal == null) continue;
        result.add(
          SignalConstant(
            path: path,
            line: lexed.lineOf(declaration.bodyStart + match.start),
            className: declaration.name,
            member: member,
            kind: kind,
            value: literal.value,
          ),
        );
      }
    }
  }
  result.sort((a, b) {
    final byPath = a.path.compareTo(b.path);
    return byPath != 0 ? byPath : a.line.compareTo(b.line);
  });
  return result;
}

/// One well-formed data row of the catalogue (seven cells).
final class CatalogueRow {
  /// Creates a row from its raw [cells].
  const CatalogueRow({required this.line, required this.cells});

  /// The 1-based line in the catalogue file.
  final int line;

  /// The seven trimmed cell texts, backticks kept.
  final List<String> cells;

  /// The Name cell with backticks stripped.
  String get name => stripBackticks(cells[0]).trim();

  /// The Type cell.
  String get type => cells[1];

  /// The Attributes cell.
  String get attributes => cells[3];

  /// The Purpose cell.
  String get purpose => cells[5];

  /// The Suggested monitoring cell.
  String get monitoring => cells[6];
}

/// The parsed signal catalogue.
final class SignalCatalogue {
  /// Creates a parse result.
  const SignalCatalogue({
    required this.present,
    required this.tableLine,
    required this.rows,
    required this.malformedRows,
  });

  /// Whether the file is in the source set.
  final bool present;

  /// The 1-based line of the matching table's header, or null when the file
  /// has no table with the required header (FR-041).
  final int? tableLine;

  /// The rows with exactly seven cells.
  final List<CatalogueRow> rows;

  /// The lines of the rows with another cell count (FR-041).
  final List<({int line, int cells})> malformedRows;

  /// Whether the file holds a table with the required header.
  bool get hasTable => tableLine != null;
}

/// Parses the catalogue from [sources].
///
/// The table is the first whose header cells equal [signalCatalogueHeader]
/// exactly, in order.
SignalCatalogue parseSignalCatalogue(SourceSet sources) {
  final text = sources.files[signalCataloguePath];
  if (text == null) {
    return const SignalCatalogue(
      present: false,
      tableLine: null,
      rows: [],
      malformedRows: [],
    );
  }
  for (final table in parseMarkdownTables(text)) {
    if (!_sameHeader(table.header)) continue;
    final rows = <CatalogueRow>[];
    final malformed = <({int line, int cells})>[];
    for (final row in table.rows) {
      if (row.cells.length == signalCatalogueHeader.length) {
        rows.add(CatalogueRow(line: row.line, cells: row.cells));
      } else {
        malformed.add((line: row.line, cells: row.cells.length));
      }
    }
    return SignalCatalogue(
      present: true,
      tableLine: table.headerLine,
      rows: rows,
      malformedRows: malformed,
    );
  }
  return const SignalCatalogue(
    present: true,
    tableLine: null,
    rows: [],
    malformedRows: [],
  );
}

bool _sameHeader(List<String> header) {
  if (header.length != signalCatalogueHeader.length) return false;
  for (var i = 0; i < header.length; i++) {
    if (header[i] != signalCatalogueHeader[i]) return false;
  }
  return true;
}

final RegExp _backticked = RegExp(r'`([^`]+)`');

/// The backticked tokens of [cell], trimmed, in order.
List<String> backtickedTokens(String cell) => [
  for (final match in _backticked.allMatches(cell)) match.group(1)!.trim(),
];

/// Whether [cell] is empty or a placeholder (FR-045, FR-046).
bool isEmptyOrPlaceholder(String cell) {
  final text = cell.trim().toLowerCase();
  return text.isEmpty || catalogueCellPlaceholders.contains(text);
}
