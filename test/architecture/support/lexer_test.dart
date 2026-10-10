import 'package:test/test.dart';

import 'lexer.dart';

void main() {
  /// Requirement: doc/specs/architecture-guardrails.md FR-063 - the lexer
  ///   returns the code with comment and string contents blanked, the comment
  ///   list and the string list, keeping positions (support code of
  ///   errors-and-results.md section 8).
  /// Path: happy
  group('lex', () {
    /// Requirement: doc/specs/architecture-guardrails.md FR-063 - blanking
    ///   keeps the length and every newline, so offsets and lines match.
    /// Path: happy
    test('blanking preserves length and line breaks', () {
      const source = "var a = 'x\\ny'; // note\n/* block\nmore */ var b;\n";

      final result = lex(source);

      expect(result.code.length, source.length);
      expect(
        '\n'.allMatches(result.code).length,
        '\n'.allMatches(source).length,
      );
      expect(result.code.contains('note'), isFalse);
      expect(result.code.contains('block'), isFalse);
      expect(result.code.contains('var a'), isTrue);
      expect(result.code.contains('var b'), isTrue);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-063 - comment kinds
    ///   and start lines.
    /// Path: happy
    test('comments report kind, line and text', () {
      const source = '// one\n/// two\nvar x; /* three */\n';

      final comments = lex(source).comments;

      expect(comments.map((c) => c.kind), [
        CommentKind.line,
        CommentKind.doc,
        CommentKind.block,
      ]);
      expect(comments.map((c) => c.line), [1, 2, 3]);
      expect(comments[2].text, '/* three */');
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-008 - text in
    ///   single, double, raw and triple-quoted strings never reaches the code.
    /// Path: unhappy (false positive)
    test('string contents of every form are blanked', () {
      const source =
          "var a = 'catch'; var b = \"catch\"; var c = r'catch'; "
          "var d = '''catch\ncatch'''; var e;";

      final result = lex(source);

      expect(result.code.contains('catch'), isFalse);
      expect(result.strings.map((s) => s.value), [
        'catch',
        'catch',
        'catch',
        'catch\ncatch',
      ]);
      expect(result.strings[2].isRaw, isTrue);
      expect(result.code.contains('var e'), isTrue);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-008 - code inside
    ///   `${...}` interpolation is still examined.
    /// Path: unhappy (false positive)
    test('code in an interpolation stays visible', () {
      const source = r"var s = 'a ${wrapPortFailure(x)} b $name';";

      final result = lex(source);

      expect(result.code.contains('wrapPortFailure(x)'), isTrue);
      expect(result.code.contains('name'), isTrue);
      expect(result.code.contains(' a '), isFalse);
      expect(result.strings.single.isInterpolated, isTrue);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-008 - a comment
    ///   marker inside a string is not a comment.
    /// Path: unhappy (false positive)
    test('a comment marker inside a string is not a comment', () {
      const source = "var url = 'http://x'; var after;";

      final result = lex(source);

      expect(result.comments, isEmpty);
      expect(result.code.contains('var after'), isTrue);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-063 - lineOf
    ///   counts lines from 1.
    /// Path: happy
    test('lineOf is 1-based', () {
      final result = lex('a\nb\nc');

      expect(result.lineOf(0), 1);
      expect(result.lineOf(2), 2);
      expect(result.lineOf(4), 3);
    });
  });

  /// Requirement: doc/specs/architecture-guardrails.md FR-063 - comment and
  ///   string records carry exact kinds, lines and offsets for odd inputs.
  /// Path: unhappy (boundary)
  group('lex edge cases', () {
    /// Requirement: doc/specs/architecture-guardrails.md FR-063 - a nested
    ///   block comment is one comment and ends at the matching marker.
    /// Path: unhappy (boundary)
    test('nested block comments are one comment', () {
      const source = 'a /* x /* y */ still */ b';

      final result = lex(source);

      expect(result.comments, hasLength(1));
      expect(result.comments.single.text, '/* x /* y */ still */');
      expect(result.code.contains('still'), isFalse);
      expect(result.code.endsWith(' b'), isTrue);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-063 - an
    ///   unterminated block comment runs to the end without a crash.
    /// Path: unhappy (invalid input)
    test('an unterminated block comment blanks to the end', () {
      const source = 'var a; /* open\nvar b;';

      final result = lex(source);

      expect(result.comments.single.kind, CommentKind.block);
      expect(result.code.contains('var b'), isFalse);
      expect(result.code.length, source.length);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-063 - four slashes
    ///   is an ordinary line comment, three is a doc comment.
    /// Path: unhappy (boundary)
    test('//// is a line comment and /// a doc comment', () {
      final comments = lex('//// a\n/// b\n').comments;

      expect(comments.map((c) => c.kind), [CommentKind.line, CommentKind.doc]);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-063 - a comment
    ///   that ends the file without a newline is still reported whole.
    /// Path: unhappy (empty case)
    test('a line comment at end of file keeps its text', () {
      final comments = lex('var a; // last').comments;

      expect(comments.single.text, '// last');
      expect(comments.single.line, 1);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-063 - the string
    ///   list gives value, start line, offset, raw and interpolated flags.
    /// Path: happy
    test('strings report line, offset and flags', () {
      const source = "var a;\nvar b = r'raw';\nvar c = 'x \$y';\n";

      final strings = lex(source).strings;

      expect(strings.map((s) => s.value), ['raw', 'x ']);
      expect(strings.map((s) => s.line), [2, 3]);
      expect(strings[0].offset, source.indexOf("r'raw'"));
      expect(strings.map((s) => s.isRaw), [true, false]);
      expect(strings.map((s) => s.isInterpolated), [false, true]);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-063 - a
    ///   multi-line string starts at its opening line and later code keeps
    ///   its own line number.
    /// Path: happy
    test('lines after a multi-line string stay aligned', () {
      const source = "var a = '''\none\ntwo''';\nvar b = 'z';\n";

      final result = lex(source);

      expect(result.strings.map((s) => s.line), [1, 4]);
      expect(result.lineOf(result.code.indexOf('var b')), 4);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-063 - string
    ///   values have their escapes resolved.
    /// Path: happy
    test('escapes are resolved in the value', () {
      final strings = lex(r"var a = 'q\'r\ntA\x42\u{43}\$';").strings;

      expect(strings.single.value, "q'r\ntABC\$");
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-063 - a malformed
    ///   numeric escape keeps the letter instead of crashing.
    /// Path: unhappy (invalid input)
    test('a malformed unicode escape does not throw', () {
      final strings = lex(r"var a = '\uZZ';").strings;

      expect(strings.single.value, 'uZZ');
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-008 - an escaped
    ///   quote does not end the string, so code after it is not swallowed.
    /// Path: unhappy (false positive)
    test('an escaped quote keeps the string open', () {
      final result = lex(r"var a = 'it\'s catch'; var after;");

      expect(result.code.contains('catch'), isFalse);
      expect(result.code.contains('var after'), isTrue);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-008 - an
    ///   unterminated single-line string ends at the line break.
    /// Path: unhappy (invalid input)
    test('an unterminated string stops at the end of the line', () {
      final result = lex("var a = 'open\nvar b;");

      expect(result.code.contains('var b'), isTrue);
      expect(result.strings.single.value, 'open');
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-008 - a string and
    ///   a comment inside an interpolation are handled, braces nest, and the
    ///   inner string is listed before the outer one.
    /// Path: unhappy (false positive)
    test('nested strings and braces in an interpolation', () {
      const source =
          r"""var s = 'a ${ {'k': 1}['k'] + f("catch") } z'; var e;""";

      final result = lex(source);

      expect(result.code.contains('catch'), isFalse);
      expect(result.code.contains('f('), isTrue);
      expect(result.code.contains('var e'), isTrue);
      expect(result.strings.map((s) => s.value), ['k', 'k', 'catch', 'a  z']);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-008 - a raw string
    ///   keeps `$` and backslashes literally and has no interpolation.
    /// Path: unhappy (false positive)
    test('a raw string is not interpolated or unescaped', () {
      final strings = lex(r"var a = r'\n ${x} $y';").strings;

      expect(strings.single.value, r'\n ${x} $y');
      expect(strings.single.isInterpolated, isFalse);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-008 - an
    ///   identifier ending in `r` before a quote is not a raw prefix.
    /// Path: unhappy (boundary)
    test('an r at the end of an identifier is not a raw prefix', () {
      final strings = lex(r"var a = bar'x\ny';").strings;

      expect(strings.single.isRaw, isFalse);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-008 - quotes of
    ///   the other kind inside a triple-quoted string do not end it.
    /// Path: unhappy (boundary)
    test('a triple-quoted string may contain single quotes', () {
      final result = lex("var a = '''it's \"x\" ''catch'''; var e;");

      expect(result.strings.single.value, "it's \"x\" ''catch");
      expect(result.code.contains('var e'), isTrue);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-063 - the lexer is
    ///   a pure function: the same source gives the same result.
    /// Path: unhappy (determinism)
    test('lexing twice gives identical output', () {
      const source = "// c\nvar a = 'x \${y}'; /* b */\n";

      final first = lex(source);
      final second = lex(source);

      expect(second.code, first.code);
      expect(
        second.comments.map((c) => '${c.kind}${c.line}${c.offset}${c.text}'),
        first.comments.map((c) => '${c.kind}${c.line}${c.offset}${c.text}'),
      );
      expect(
        second.strings.map((s) => '${s.value}${s.offset}'),
        first.strings.map((s) => '${s.value}${s.offset}'),
      );
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-063 - empty
    ///   source gives empty output and lineOf clamps past the end.
    /// Path: unhappy (empty case)
    test('empty source and an offset past the end', () {
      final result = lex('');

      expect(result.code, '');
      expect(result.comments, isEmpty);
      expect(result.strings, isEmpty);
      expect(lex('a\nb').lineOf(99), 2);
    });
  });
}
