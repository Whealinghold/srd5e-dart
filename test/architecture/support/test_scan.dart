import 'lexer.dart';

/// Whether a scanned call is a `test(` or a `group(`.
enum TestCallKind {
  /// A `test(` call.
  test,

  /// A `group(` call.
  group,
}

/// The shape of a loop recognised by FR-066.
enum LoopKind {
  /// A `for` statement, `for-in` and `await for` included.
  forStatement,

  /// The closure passed to `.forEach(`.
  forEach,

  /// The closure passed to `.map(`.
  map,
}

/// A block of consecutive `///` lines (a doc comment).
final class DocBlock {
  /// Creates a block.
  const DocBlock({
    required this.startLine,
    required this.endLine,
    required this.lines,
  });

  /// The 1-based line of the first `///`.
  final int startLine;

  /// The 1-based line of the last `///`.
  final int endLine;

  /// The text of every line after its `///`, in order.
  final List<String> lines;

  int? _labelIndex(String label) {
    final prefix = '$label:';
    for (var i = 0; i < lines.length; i++) {
      if (lines[i].trimLeft().startsWith(prefix)) return i;
    }
    return null;
  }

  /// Whether a line of the block starts with `<label>:`.
  bool hasField(String label) => _labelIndex(label) != null;

  /// The 1-based line of the first `<label>:` line, or null.
  int? fieldLine(String label) {
    final index = _labelIndex(label);
    return index == null ? null : startLine + index;
  }

  /// The trimmed value after `<label>:`, with the continuation lines (three
  /// spaces after the slashes) that directly follow joined by one space, or
  /// null when the block has no such field.
  String? fieldValue(String label) {
    final index = _labelIndex(label);
    if (index == null) return null;
    final first = lines[index].trimLeft().substring(label.length + 1).trim();
    final parts = [if (first.isNotEmpty) first];
    for (var i = index + 1; i < lines.length; i++) {
      final line = lines[i];
      if (!line.startsWith('   ') || line.trim().isEmpty) break;
      parts.add(line.trim());
    }
    return parts.join(' ');
  }
}

/// A loop found by [scanTests] (FR-066).
final class LoopScope {
  /// Creates a loop record.
  const LoopScope({
    required this.kind,
    required this.line,
    required this.bodyStart,
    required this.bodyEnd,
    required this.comment,
  });

  /// Which kind of loop it is.
  final LoopKind kind;

  /// The 1-based line of the statement the loop starts (the line its comment
  /// must end above).
  final int line;

  /// The offset where the body starts (inclusive).
  final int bodyStart;

  /// The offset where the body ends (exclusive).
  final int bodyEnd;

  /// The doc comment block that ends on the line above the loop, or null.
  final DocBlock? comment;

  /// Whether [offset] lies in the loop body.
  bool contains(int offset) => offset >= bodyStart && offset < bodyEnd;
}

/// One `test(` or `group(` call found by [scanTests].
final class TestCall {
  /// Creates a call record.
  const TestCall({
    required this.kind,
    required this.line,
    required this.offset,
    required this.argsStart,
    required this.argsEnd,
    required this.comment,
    required this.loops,
    required this.groups,
  });

  /// Whether it is a test or a group.
  final TestCallKind kind;

  /// The 1-based line of the call name.
  final int line;

  /// The offset of the call name.
  final int offset;

  /// The offset of the opening parenthesis.
  final int argsStart;

  /// The offset just after the closing parenthesis.
  final int argsEnd;

  /// The doc comment block that ends on the line above the call, when the
  /// call is the first token of its line; otherwise null.
  final DocBlock? comment;

  /// The loops whose body holds the call, innermost first.
  final List<LoopScope> loops;

  /// The `group(` calls whose arguments hold the call, innermost first.
  final List<TestCall> groups;
}

/// The result of [scanTests].
final class TestScan {
  /// Creates a result.
  const TestScan({
    required this.calls,
    required this.loops,
    required this.blocks,
  });

  /// Every `test(` and `group(` call, in source order.
  final List<TestCall> calls;

  /// Every loop, in source order, with or without a test inside.
  final List<LoopScope> loops;

  /// Every doc comment block, in source order.
  final List<DocBlock> blocks;

  /// The calls whose name lies in the body of [loop].
  List<TestCall> callsInside(LoopScope loop) => [
    for (final call in calls)
      if (loop.contains(call.offset)) call,
  ];

  /// Whether [loop] holds at least one `test(` or `group(` call.
  bool loopHasTest(LoopScope loop) => callsInside(loop).isNotEmpty;

  /// The loops inside the arguments of [group] that hold a test or group.
  List<LoopScope> loopsInside(TestCall group) => [
    for (final loop in loops)
      if (loop.bodyStart >= group.argsStart &&
          loop.bodyEnd <= group.argsEnd &&
          loopHasTest(loop))
        loop,
  ];

  /// The innermost call whose arguments hold [offset], or null.
  TestCall? innermostCallAt(int offset) {
    TestCall? best;
    for (final call in calls) {
      if (offset < call.argsStart || offset >= call.argsEnd) continue;
      if (best == null || call.argsStart > best.argsStart) best = call;
    }
    return best;
  }
}

/// A call name that is not a member access or part of a longer identifier
/// (FR-057): `mytest(` and `helper.test(` do not match.
final RegExp _callPattern = RegExp(r'(?<![A-Za-z0-9_$.])(test|group)\s*\(');
final RegExp _forPattern = RegExp(r'(?<![A-Za-z0-9_$.])for\s*\(');
final RegExp _closurePattern = RegExp(r'\.\s*(forEach|map)\s*\(');
final RegExp _voidBefore = RegExp(r'(?<![A-Za-z0-9_$])void\s*$');
final RegExp _awaitBefore = RegExp(r'(?<![A-Za-z0-9_$])await\s*$');

/// Finds the `test(` and `group(` calls, the loops and the doc comment blocks
/// of a lexed Dart file (FR-057, FR-066).
///
/// Detection reads the lexer's blanked code, so a call inside a comment or a
/// string never matches. A call preceded by `.` or an identifier character
/// (`helper.test(`, `mytest(`) is not a test, and neither are `setUp(`,
/// `tearDown(` or a `testOn:` argument. A call declared with `void` before it
/// is a declaration, not a call.
TestScan scanTests(LexResult lexed) {
  final code = lexed.code;
  final lineStarts = <int>[0];
  for (var i = 0; i < code.length; i++) {
    if (code.codeUnitAt(i) == 0x0A) lineStarts.add(i + 1);
  }
  int lineOf(int offset) {
    var low = 0;
    var high = lineStarts.length - 1;
    while (low < high) {
      final mid = (low + high + 1) >> 1;
      if (lineStarts[mid] <= offset) {
        low = mid;
      } else {
        high = mid - 1;
      }
    }
    return low + 1;
  }

  bool firstOnLine(int offset) {
    final start = lineStarts[lineOf(offset) - 1];
    return code.substring(start, offset).trim().isEmpty;
  }

  String lineText(int line) {
    final start = lineStarts[line - 1];
    final end = line < lineStarts.length ? lineStarts[line] : code.length;
    return code.substring(start, end);
  }

  final blocks = docBlocksOf(lexed);
  final byEndLine = {for (final b in blocks) b.endLine: b};

  final loops = <LoopScope>[];
  for (final match in _forPattern.allMatches(code)) {
    final open = match.end - 1;
    final close = _matching(code, open);
    if (close < 0) continue;
    var bodyStart = close + 1;
    var cursor = bodyStart;
    while (cursor < code.length && _isSpace(code.codeUnitAt(cursor))) {
      cursor++;
    }
    int bodyEnd;
    if (cursor < code.length && code[cursor] == '{') {
      final end = _matching(code, cursor);
      bodyStart = cursor;
      bodyEnd = end < 0 ? code.length : end + 1;
    } else {
      bodyEnd = _statementEnd(code, bodyStart);
    }
    var start = match.start;
    final windowStart = start - 12 < 0 ? 0 : start - 12;
    final awaitMatch = _awaitBefore.firstMatch(
      code.substring(windowStart, start),
    );
    if (awaitMatch != null) start = windowStart + awaitMatch.start;
    final line = lineOf(start);
    loops.add(
      LoopScope(
        kind: LoopKind.forStatement,
        line: line,
        bodyStart: bodyStart,
        bodyEnd: bodyEnd,
        comment: firstOnLine(start) ? byEndLine[line - 1] : null,
      ),
    );
  }
  for (final match in _closurePattern.allMatches(code)) {
    final open = match.end - 1;
    final close = _matching(code, open);
    if (close < 0) continue;
    var line = lineOf(match.start);
    while (line > 1 && lineText(line).trimLeft().startsWith('.')) {
      line--;
    }
    loops.add(
      LoopScope(
        kind: match.group(1) == 'forEach' ? LoopKind.forEach : LoopKind.map,
        line: line,
        bodyStart: open + 1,
        bodyEnd: close,
        comment: byEndLine[line - 1],
      ),
    );
  }
  loops.sort((a, b) => a.bodyStart.compareTo(b.bodyStart));

  final raw = <({TestCallKind kind, int offset, int open, int close})>[];
  for (final match in _callPattern.allMatches(code)) {
    final tail = code.substring(
      match.start - 12 < 0 ? 0 : match.start - 12,
      match.start,
    );
    if (_voidBefore.hasMatch(tail)) continue;
    final open = match.end - 1;
    final close = _matching(code, open);
    raw.add((
      kind: match.group(1) == 'test' ? TestCallKind.test : TestCallKind.group,
      offset: match.start,
      open: open,
      close: close < 0 ? code.length : close + 1,
    ));
  }

  // Source order: an enclosing group is always built before the calls in it.
  final calls = <TestCall>[];
  for (final r in raw) {
    final enclosingLoops = [
      for (final loop in loops)
        if (loop.contains(r.offset)) loop,
    ]..sort((a, b) => b.bodyStart.compareTo(a.bodyStart));
    final enclosingGroups = [
      for (final call in calls)
        if (call.kind == TestCallKind.group &&
            r.offset >= call.argsStart &&
            r.offset < call.argsEnd)
          call,
    ]..sort((a, b) => b.argsStart.compareTo(a.argsStart));
    final line = lineOf(r.offset);
    final call = TestCall(
      kind: r.kind,
      line: line,
      offset: r.offset,
      argsStart: r.open,
      argsEnd: r.close,
      comment: firstOnLine(r.offset) ? byEndLine[line - 1] : null,
      loops: List.unmodifiable(enclosingLoops),
      groups: List.unmodifiable(enclosingGroups),
    );
    calls.add(call);
  }

  return TestScan(
    calls: List.unmodifiable(calls),
    loops: List.unmodifiable(loops),
    blocks: blocks,
  );
}

/// Groups the doc comments (`///` lines) of [lexed] into blocks of
/// consecutive lines.
List<DocBlock> docBlocksOf(LexResult lexed) {
  final blocks = <DocBlock>[];
  var startLine = 0;
  var endLine = 0;
  var lines = <String>[];
  void flush() {
    if (lines.isEmpty) return;
    blocks.add(
      DocBlock(
        startLine: startLine,
        endLine: endLine,
        lines: List.unmodifiable(lines),
      ),
    );
    lines = <String>[];
  }

  for (final comment in lexed.comments) {
    if (comment.kind != CommentKind.doc) continue;
    var body = comment.text.substring(3);
    while (body.endsWith('\n') || body.endsWith('\r')) {
      body = body.substring(0, body.length - 1);
    }
    if (lines.isNotEmpty && comment.line == endLine + 1) {
      lines.add(body);
      endLine = comment.line;
    } else {
      flush();
      startLine = comment.line;
      endLine = comment.line;
      lines = [body];
    }
  }
  flush();
  return List.unmodifiable(blocks);
}

bool _isSpace(int unit) =>
    unit == 0x20 || unit == 0x09 || unit == 0x0A || unit == 0x0D;

bool _isOpener(String c) => c == '(' || c == '[' || c == '{';

bool _isCloser(String c) => c == ')' || c == ']' || c == '}';

/// The index of the bracket that closes the one at [open], or -1.
int _matching(String code, int open) {
  var depth = 0;
  for (var i = open; i < code.length; i++) {
    final c = code[i];
    if (_isOpener(c)) {
      depth++;
    } else if (_isCloser(c)) {
      depth--;
      if (depth == 0) return i;
    }
  }
  return -1;
}

/// The end (exclusive) of the single statement or expression that starts at
/// [from]: its terminating `;` or `,` at depth zero, or the closing bracket of
/// the enclosing construct.
int _statementEnd(String code, int from) {
  var depth = 0;
  for (var i = from; i < code.length; i++) {
    final c = code[i];
    if (_isOpener(c)) {
      depth++;
    } else if (_isCloser(c)) {
      if (depth == 0) return i;
      depth--;
    } else if (depth == 0 && (c == ';' || c == ',')) {
      return i;
    }
  }
  return code.length;
}
