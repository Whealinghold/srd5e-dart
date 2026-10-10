import 'lexer.dart';
import 'source_set.dart';
import 'violation.dart';

/// The kind of a Dart directive that names another file.
enum DirectiveKind {
  /// `import 'x.dart';`
  importDirective,

  /// `export 'x.dart';`
  exportDirective,

  /// `part 'x.dart';`
  partDirective,

  /// `part of 'x.dart';` (the URI form; `part of name;` has no edge).
  partOfDirective,
}

/// One edge from a file to the URI a directive names.
///
/// A directive with conditional configurations yields one [Directive] for the
/// default URI and one per `if (...) 'uri'` configuration (FR-064); the latter
/// have [isConditional] set and share the combinators of their directive.
final class Directive {
  /// Creates a directive record.
  const Directive({
    required this.kind,
    required this.from,
    required this.uri,
    required this.line,
    required this.isLocal,
    required this.resolvedPath,
    required this.exists,
    this.isConditional = false,
    this.isDeferred = false,
    this.prefix,
    this.shown = const [],
    this.hidden = const [],
  });

  /// Import, export, part or part-of.
  final DirectiveKind kind;

  /// The repository-relative path of the file holding the directive.
  final String from;

  /// The URI text exactly as written (adjacent literals concatenated).
  final String uri;

  /// The 1-based line of the directive keyword, or of the URI literal for a
  /// conditional configuration.
  final int line;

  /// Whether the URI is relative or `package:srd5e/...`, so FR-007 applies.
  final bool isLocal;

  /// The repository-relative path a local URI names, or `null` for a
  /// non-local URI and for a local one that cannot be mapped inside the
  /// repository (for example `../../outside.dart`, or an unparsable URI).
  final String? resolvedPath;

  /// Whether [resolvedPath] is a file of the source set (readable, unreadable
  /// or binary). Always false for a non-local URI.
  final bool exists;

  /// Whether this edge comes from an `if (...) 'uri'` configuration.
  final bool isConditional;

  /// Whether the directive is `deferred as`.
  final bool isDeferred;

  /// The `as` prefix, if any.
  final String? prefix;

  /// Names listed by `show` clauses.
  final List<String> shown;

  /// Names listed by `hide` clauses.
  final List<String> hidden;

  /// Whether the URI is `dart:...`.
  bool get isDartLibrary => uri.startsWith('dart:');

  /// Whether the URI is `package:<name>/...` (any package, `srd5e` included).
  bool get isPackage => uri.startsWith('package:');

  @override
  String toString() => '$from:$line ${kind.name} $uri';
}

/// The Dart files of [sources] with the given path [prefix] and their
/// directives, in path then source order.
List<Directive> allDirectives(SourceSet sources, {String prefix = ''}) => [
  for (final path in sources.dartPaths(prefix)) ...directivesOf(sources, path),
];

/// The directives of the Dart file [path] in [sources], read from the lexer's
/// code and string list (FR-065).
List<Directive> directivesOf(SourceSet sources, String path) {
  final lexed = sources.lexed(path);
  return _Extractor(sources, path, lexed).run();
}

/// FR-007: every local directive URI that names no file of [sources] is a
/// Violation, over every Dart file of the set.
List<Violation> unresolvedDirectives(SourceSet sources) => sortedViolations([
  for (final directive in allDirectives(sources))
    if (directive.isLocal && !directive.exists)
      Violation(
        checkId: 'FR-007',
        path: directive.from,
        line: directive.line,
        detail:
            '${directive.kind.name} of "${directive.uri}" resolves to no '
            'file',
      ),
]);

/// The repository path that [uri], written in the file [from], names, or
/// `null` when it cannot be mapped inside the repository. Only call for a
/// relative URI or one starting `package:srd5e/`.
String? resolveLocalUri(String from, String uri) {
  const packagePrefix = 'package:srd5e/';
  final String base;
  final String reference;
  if (uri.startsWith(packagePrefix)) {
    base = 'lib';
    reference = uri.substring(packagePrefix.length);
  } else {
    final slash = from.lastIndexOf('/');
    base = slash < 0 ? '' : from.substring(0, slash);
    reference = uri;
  }
  final parsed = Uri.tryParse(reference);
  if (parsed == null ||
      parsed.hasScheme ||
      parsed.hasAuthority ||
      parsed.path.startsWith('/') ||
      reference.isEmpty) {
    return null;
  }
  final segments = <String>[...base.split('/').where((s) => s.isNotEmpty)];
  for (final segment in parsed.pathSegments) {
    if (segment == '' || segment == '.') continue;
    if (segment == '..') {
      if (segments.isEmpty) return null;
      segments.removeLast();
    } else {
      segments.add(segment);
    }
  }
  if (segments.isEmpty) return null;
  return segments.join('/');
}

bool _isLocalUri(String uri) {
  if (uri.startsWith('package:srd5e/')) return true;
  // Any other scheme (dart:, package:other/, file:, http:) is not a local edge.
  return !RegExp(r'^[A-Za-z][A-Za-z0-9+.\-]*:').hasMatch(uri);
}

final class _Extractor {
  _Extractor(this.sources, this.path, this.lexed)
    : code = lexed.code,
      stringsAt = {for (final s in lexed.strings) s.offset: s};

  final SourceSet sources;
  final String path;
  final LexResult lexed;
  final String code;
  final Map<int, LexString> stringsAt;
  final List<Directive> found = [];

  static final RegExp _keyword = RegExp(
    r'(?<![\w$])(import|export|part)(?![\w$])',
  );

  List<Directive> run() {
    var searchFrom = 0;
    for (final match in _keyword.allMatches(code)) {
      if (match.start < searchFrom) continue;
      if (!_atStatementStart(match.start)) continue;
      searchFrom = _directive(match);
    }
    return found;
  }

  bool _atStatementStart(int offset) {
    var i = offset - 1;
    while (i >= 0 && _isSpace(code.codeUnitAt(i))) {
      i--;
    }
    if (i < 0) return true;
    final c = code[i];
    return c == ';' || c == '}' || c == ')' || c == ']';
  }

  bool _isSpace(int unit) =>
      unit == 0x20 || unit == 0x0A || unit == 0x0D || unit == 0x09;

  int _skipSpace(int i) {
    while (i < code.length && _isSpace(code.codeUnitAt(i))) {
      i++;
    }
    return i;
  }

  bool _isQuoteAt(int i) {
    if (i >= code.length) return false;
    final c = code.codeUnitAt(i);
    if (c == 0x27 || c == 0x22) return true;
    return c == 0x72 /* r */ &&
        i + 1 < code.length &&
        (code.codeUnitAt(i + 1) == 0x27 || code.codeUnitAt(i + 1) == 0x22);
  }

  /// Reads one or more adjacent string literals starting at [start] (which
  /// satisfies [_isQuoteAt]). Returns the concatenated value, the offset of
  /// the first literal and the offset after the last one.
  ({String value, int first, int end, bool valid}) _readLiteral(int start) {
    final buffer = StringBuffer();
    var valid = true;
    var i = start;
    while (_isQuoteAt(i)) {
      // A raw literal is listed at its `r` prefix, which the lexer blanks.
      final literal = stringsAt[i] ?? stringsAt[i - 1];
      var open = i;
      if (code.codeUnitAt(open) == 0x72) open++;
      final quote = code.codeUnitAt(open);
      final triple =
          open + 2 < code.length &&
          code.codeUnitAt(open + 1) == quote &&
          code.codeUnitAt(open + 2) == quote;
      final delimiter = triple ? 3 : 1;
      var close = open + delimiter;
      while (close < code.length) {
        if (code.codeUnitAt(close) == quote &&
            (!triple ||
                (close + 2 < code.length &&
                    code.codeUnitAt(close + 1) == quote &&
                    code.codeUnitAt(close + 2) == quote))) {
          break;
        }
        close++;
      }
      if (literal == null || literal.isInterpolated) {
        valid = false;
      } else {
        buffer.write(literal.value);
      }
      i = close + delimiter;
      if (i > code.length) i = code.length;
      final next = _skipSpace(i);
      if (_isQuoteAt(next)) {
        i = next;
      } else {
        break;
      }
    }
    return (value: buffer.toString(), first: start, end: i, valid: valid);
  }

  /// Parses the directive that starts at [keyword] and returns the offset
  /// after it (the `;`, or the end of the code when it is missing).
  int _directive(RegExpMatch keyword) {
    var kind = switch (keyword.group(1)) {
      'import' => DirectiveKind.importDirective,
      'export' => DirectiveKind.exportDirective,
      _ => DirectiveKind.partDirective,
    };
    var i = _skipSpace(keyword.end);
    if (kind == DirectiveKind.partDirective &&
        code.startsWith('of', i) &&
        (i + 2 >= code.length || !_isWordUnit(code.codeUnitAt(i + 2)))) {
      kind = DirectiveKind.partOfDirective;
      i = _skipSpace(i + 2);
    }
    if (!_isQuoteAt(i)) return keyword.end;
    final keywordLine = lexed.lineOf(keyword.start);
    final primary = _readLiteral(i);
    final entries = <({String uri, int line, bool conditional, bool valid})>[
      (
        uri: primary.value,
        line: keywordLine,
        conditional: false,
        valid: primary.valid,
      ),
    ];
    i = primary.end;
    var isDeferred = false;
    String? prefix;
    final shown = <String>[];
    final hidden = <String>[];
    List<String>? list;
    var expectPrefix = false;
    while (i < code.length) {
      i = _skipSpace(i);
      if (i >= code.length) break;
      final unit = code.codeUnitAt(i);
      if (unit == 0x3B /* ; */ ) {
        i++;
        break;
      }
      if (_isWordUnit(unit)) {
        var end = i;
        while (end < code.length && _isWordUnit(code.codeUnitAt(end))) {
          end++;
        }
        final word = code.substring(i, end);
        i = end;
        if (word == 'if') {
          final open = _skipSpace(i);
          if (open < code.length && code[open] == '(') {
            var depth = 0;
            var j = open;
            for (; j < code.length; j++) {
              if (code[j] == '(') depth++;
              if (code[j] == ')') {
                depth--;
                if (depth == 0) break;
              }
            }
            final afterParen = _skipSpace(j + 1);
            if (_isQuoteAt(afterParen)) {
              final configured = _readLiteral(afterParen);
              entries.add((
                uri: configured.value,
                line: lexed.lineOf(afterParen),
                conditional: true,
                valid: configured.valid,
              ));
              i = configured.end;
            } else {
              i = j + 1;
            }
          }
          continue;
        }
        if (word == 'deferred') {
          isDeferred = true;
        } else if (word == 'as') {
          expectPrefix = true;
        } else if (word == 'show') {
          list = shown;
        } else if (word == 'hide') {
          list = hidden;
        } else if (expectPrefix) {
          prefix = word;
          expectPrefix = false;
        } else {
          list?.add(word);
        }
        continue;
      }
      i++;
    }
    for (final entry in entries) {
      final local = entry.valid && _isLocalUri(entry.uri);
      final resolved = local ? resolveLocalUri(path, entry.uri) : null;
      found.add(
        Directive(
          kind: kind,
          from: path,
          uri: entry.uri,
          line: entry.line,
          isLocal: local || !entry.valid,
          resolvedPath: resolved,
          exists: resolved != null && _exists(resolved),
          isConditional: entry.conditional,
          isDeferred: isDeferred,
          prefix: prefix,
          shown: List.unmodifiable(shown),
          hidden: List.unmodifiable(hidden),
        ),
      );
    }
    return i;
  }

  bool _exists(String resolved) =>
      sources.files.containsKey(resolved) ||
      sources.unreadable.containsKey(resolved) ||
      sources.binaryPaths.contains(resolved);

  bool _isWordUnit(int unit) =>
      (unit >= 0x30 && unit <= 0x39) ||
      (unit >= 0x41 && unit <= 0x5A) ||
      (unit >= 0x61 && unit <= 0x7A) ||
      unit == 0x5F ||
      unit == 0x24;
}
