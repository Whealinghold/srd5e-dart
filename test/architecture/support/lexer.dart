/// The three kinds of Dart comment the lexer reports.
enum CommentKind {
  /// A `//` comment that is not a doc comment.
  line,

  /// A `///` doc comment line.
  doc,

  /// A `/* ... */` comment (nested comments are one comment).
  block,
}

/// One comment found by [lex].
final class LexComment {
  /// Creates a comment record.
  const LexComment({
    required this.kind,
    required this.line,
    required this.offset,
    required this.text,
  });

  /// Whether it is a line, doc or block comment.
  final CommentKind kind;

  /// The 1-based line on which it starts.
  final int line;

  /// The offset of its first character.
  final int offset;

  /// The full text including the comment markers.
  final String text;
}

/// One string literal found by [lex].
final class LexString {
  /// Creates a string literal record.
  const LexString({
    required this.value,
    required this.line,
    required this.offset,
    required this.isRaw,
    required this.isInterpolated,
  });

  /// The literal's text with escapes resolved; interpolated parts are left out.
  final String value;

  /// The 1-based line on which it starts.
  final int line;

  /// The offset of its opening quote (or of the `r` prefix).
  final int offset;

  /// Whether it is a raw string (`r'...'`).
  final bool isRaw;

  /// Whether it contains `$name` or `${...}` interpolation.
  final bool isInterpolated;
}

/// What [lex] returns.
final class LexResult {
  /// Creates a result.
  const LexResult({
    required this.code,
    required this.comments,
    required this.strings,
  });

  /// The source with comment and string contents blanked to spaces (newlines
  /// kept), so offsets and lines match the original. Quote characters stay;
  /// code inside `${...}` interpolation stays and can be examined.
  final String code;

  /// Every comment, in source order.
  final List<LexComment> comments;

  /// Every string literal. A string inside an interpolated expression is listed
  /// before the outer string that contains it, which is closed last.
  final List<LexString> strings;

  /// The 1-based line of [offset] in [code].
  int lineOf(int offset) {
    var line = 1;
    final limit = offset < code.length ? offset : code.length;
    for (var i = 0; i < limit; i++) {
      if (code.codeUnitAt(i) == 0x0A) line++;
    }
    return line;
  }
}

/// Lexes Dart [source] into blanked code, comments and string literals.
///
/// A hand-written scanner, not `package:analyzer`: it only has to tell code
/// from comments and strings so token checks never fire on text inside them.
LexResult lex(String source) => _Lexer(source).run();

final class _Lexer {
  _Lexer(this.source) : out = List<int>.of(source.codeUnits);

  final String source;
  final List<int> out;
  final List<LexComment> comments = [];
  final List<LexString> strings = [];
  int pos = 0;

  static const int _newline = 0x0A;
  static const int _space = 0x20;

  LexResult run() {
    _scanCode(untilClosingBrace: false);
    return LexResult(
      code: String.fromCharCodes(out),
      comments: comments,
      strings: strings,
    );
  }

  late final List<int> _lineStarts = () {
    final starts = <int>[0];
    for (var i = 0; i < source.length; i++) {
      if (source.codeUnitAt(i) == _newline) starts.add(i + 1);
    }
    return starts;
  }();

  /// The 1-based line of [offset], by binary search over the line starts.
  int _lineAt(int offset) {
    var low = 0;
    var high = _lineStarts.length - 1;
    while (low < high) {
      final mid = (low + high + 1) >> 1;
      if (_lineStarts[mid] <= offset) {
        low = mid;
      } else {
        high = mid - 1;
      }
    }
    return low + 1;
  }

  void _blank(int from, int to) {
    for (var i = from; i < to && i < out.length; i++) {
      if (out[i] != _newline) out[i] = _space;
    }
  }

  bool _isIdentifierChar(int unit) =>
      (unit >= 0x30 && unit <= 0x39) ||
      (unit >= 0x41 && unit <= 0x5A) ||
      (unit >= 0x61 && unit <= 0x7A) ||
      unit == 0x5F ||
      unit == 0x24;

  bool _startsWith(String text) => source.startsWith(text, pos);

  /// Decodes `\xHH`, `\uHHHH` or `\u{H...}` whose letter is at [letterAt];
  /// null when it is not a well-formed numeric escape.
  ({int codePoint, int end})? _unicodeEscape(int letterAt) {
    final letter = source.codeUnitAt(letterAt);
    final RegExp pattern;
    if (letter == 0x78 /* x */ ) {
      pattern = RegExp(r'x([0-9A-Fa-f]{2})');
    } else if (letter == 0x75 /* u */ ) {
      pattern = RegExp(r'u(?:([0-9A-Fa-f]{4})|\{([0-9A-Fa-f]{1,6})\})');
    } else {
      return null;
    }
    final match = pattern.matchAsPrefix(source, letterAt);
    if (match == null) return null;
    final digits = match.group(1) ?? match.group(2)!;
    final codePoint = int.parse(digits, radix: 16);
    if (codePoint > 0x10FFFF) return null;
    return (codePoint: codePoint, end: match.end);
  }

  /// Scans code. With [untilClosingBrace] it stops (without consuming) at the
  /// `}` that closes an interpolation.
  void _scanCode({required bool untilClosingBrace}) {
    var depth = 0;
    while (pos < source.length) {
      final unit = source.codeUnitAt(pos);
      if (_startsWith('//')) {
        _lineComment();
      } else if (_startsWith('/*')) {
        _blockComment();
      } else if (unit == 0x27 || unit == 0x22) {
        _string(raw: false, start: pos);
      } else if (unit == 0x72 /* r */ &&
          pos + 1 < source.length &&
          (source.codeUnitAt(pos + 1) == 0x27 ||
              source.codeUnitAt(pos + 1) == 0x22) &&
          (pos == 0 || !_isIdentifierChar(source.codeUnitAt(pos - 1)))) {
        _string(raw: true, start: pos);
      } else {
        if (untilClosingBrace) {
          if (unit == 0x7B) {
            depth++;
          } else if (unit == 0x7D) {
            if (depth == 0) return;
            depth--;
          }
        }
        pos++;
      }
    }
  }

  void _lineComment() {
    final start = pos;
    while (pos < source.length && source.codeUnitAt(pos) != _newline) {
      pos++;
    }
    final text = source.substring(start, pos);
    comments.add(
      LexComment(
        kind: text.startsWith('///') && !text.startsWith('////')
            ? CommentKind.doc
            : CommentKind.line,
        line: _lineAt(start),
        offset: start,
        text: text,
      ),
    );
    _blank(start, pos);
  }

  void _blockComment() {
    final start = pos;
    var depth = 0;
    while (pos < source.length) {
      if (_startsWith('/*')) {
        depth++;
        pos += 2;
      } else if (_startsWith('*/')) {
        depth--;
        pos += 2;
        if (depth == 0) break;
      } else {
        pos++;
      }
    }
    comments.add(
      LexComment(
        kind: CommentKind.block,
        line: _lineAt(start),
        offset: start,
        text: source.substring(start, pos),
      ),
    );
    _blank(start, pos);
  }

  void _string({required bool raw, required int start}) {
    pos = raw ? start + 1 : start;
    final quote = source.codeUnitAt(pos);
    final triple =
        pos + 2 < source.length &&
        source.codeUnitAt(pos + 1) == quote &&
        source.codeUnitAt(pos + 2) == quote;
    final delimiterLength = triple ? 3 : 1;
    // The prefix `r` is blanked with the contents; the quotes stay.
    if (raw) _blank(start, start + 1);
    pos += delimiterLength;
    final value = StringBuffer();
    var interpolated = false;
    var contentStart = pos;
    while (pos < source.length) {
      final unit = source.codeUnitAt(pos);
      if (unit == quote &&
          (!triple ||
              (pos + 2 < source.length &&
                  source.codeUnitAt(pos + 1) == quote &&
                  source.codeUnitAt(pos + 2) == quote))) {
        _blank(contentStart, pos);
        pos += delimiterLength;
        break;
      }
      if (unit == _newline && !triple) {
        // Unterminated single-line string: stop at the line end.
        _blank(contentStart, pos);
        break;
      }
      if (!raw && unit == 0x5C /* \ */ && pos + 1 < source.length) {
        final next = source.codeUnitAt(pos + 1);
        final unicode = _unicodeEscape(pos + 1);
        if (unicode != null) {
          value.writeCharCode(unicode.codePoint);
          pos = unicode.end;
          continue;
        }
        value.writeCharCode(switch (next) {
          0x6E => _newline,
          0x74 => 0x09,
          0x72 => 0x0D,
          _ => next,
        });
        pos += 2;
        continue;
      }
      if (!raw && unit == 0x24 /* $ */ ) {
        if (pos + 1 < source.length && source.codeUnitAt(pos + 1) == 0x7B) {
          interpolated = true;
          _blank(contentStart, pos + 2);
          pos += 2;
          _scanCode(untilClosingBrace: true);
          if (pos < source.length) {
            _blank(pos, pos + 1);
            pos++;
          }
          contentStart = pos;
          continue;
        }
        if (pos + 1 < source.length &&
            _isIdentifierChar(source.codeUnitAt(pos + 1)) &&
            source.codeUnitAt(pos + 1) != 0x24 &&
            !(source.codeUnitAt(pos + 1) >= 0x30 &&
                source.codeUnitAt(pos + 1) <= 0x39)) {
          interpolated = true;
          _blank(contentStart, pos + 1);
          pos++;
          while (pos < source.length &&
              _isIdentifierChar(source.codeUnitAt(pos)) &&
              source.codeUnitAt(pos) != 0x24) {
            pos++;
          }
          contentStart = pos;
          continue;
        }
      }
      value.writeCharCode(unit);
      pos++;
    }
    strings.add(
      LexString(
        value: value.toString(),
        line: _lineAt(start),
        offset: start,
        isRaw: raw,
        isInterpolated: interpolated,
      ),
    );
  }
}
