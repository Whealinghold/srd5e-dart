import '../support/lexer.dart';
import '../support/source_set.dart';
import '../support/test_scan.dart';
import '../support/violation.dart';

/// Test-hygiene check FR-086 of `doc/specs/architecture-guardrails.md`
/// (section 4.4, `testing.md` §6, §11): no commented-out test code and no
/// skipped test without an `Issue:` line.
///
/// Every function is pure: it reads a [SourceSet] and returns [Violation]s.

const String _testPrefix = 'test/';

final RegExp _commentedCall = RegExp(r'^(?:test|group|setUp|tearDown)\(');
final RegExp _commentMarkers = RegExp(r'^[\s/*]*');
final RegExp _skipArgument = RegExp(r'(?<![A-Za-z0-9_$.])skip\s*:');
final RegExp _skipCall = RegExp(r'(?<![A-Za-z0-9_$.])skip\s*\(');
final RegExp _voidBefore = RegExp(r'(?<![A-Za-z0-9_$])void\s*$');

/// The lines of [comment] with their markers removed, as (line, text) pairs.
List<({int line, String text})> _commentLines(LexComment comment) {
  final raw = comment.text.split('\n');
  return [
    for (var i = 0; i < raw.length; i++)
      (line: comment.line + i, text: raw[i].replaceFirst(_commentMarkers, '')),
  ];
}

bool _issueIsStated(DocBlock? block) {
  final value = block?.fieldValue('Issue');
  return value != null && value.isNotEmpty;
}

/// FR-086: no file under `test/` holds a commented-out `test(`, `group(`,
/// `setUp(` or `tearDown(` call, and a `skip:` argument or `skip(` call is
/// allowed only when the doc comment above the test carries an `Issue:` line
/// with a non-empty value.
List<Violation> checkNoCommentedOutOrSkippedTests(SourceSet sources) {
  const id = 'FR-086';
  final violations = <Violation>[];
  for (final path in sources.dartPaths(_testPrefix)) {
    final lexed = sources.lexed(path);

    for (final comment in lexed.comments) {
      for (final line in _commentLines(comment)) {
        if (!_commentedCall.hasMatch(line.text)) continue;
        violations.add(
          Violation(
            checkId: id,
            path: path,
            line: line.line,
            detail:
                'A commented-out test call; delete the test or fix it '
                '(testing.md §6).',
          ),
        );
      }
    }

    final code = lexed.code;
    final scan = scanTests(lexed);
    final skips = <int>[
      for (final m in _skipArgument.allMatches(code)) m.start,
      for (final m in _skipCall.allMatches(code))
        if (!_voidBefore.hasMatch(
          code.substring(m.start < 12 ? 0 : m.start - 12, m.start),
        ))
          m.start,
    ];
    for (final offset in skips) {
      final call = scan.innermostCallAt(offset);
      final stated =
          call != null &&
          (_issueIsStated(call.comment) ||
              call.loops.any((loop) => _issueIsStated(loop.comment)));
      if (stated) continue;
      violations.add(
        Violation(
          checkId: id,
          path: path,
          line: lexed.lineOf(offset),
          detail:
              'A skip needs an "Issue:" line with a link or id and a reason '
              'in the doc comment above the test.',
        ),
      );
    }
  }
  return sortedViolations(violations);
}

/// The check function per id, for the registry (`registry.dart`, FR-005).
const Map<String, List<Violation> Function(SourceSet)> testHygieneChecks = {
  'FR-086': checkNoCommentedOutOrSkippedTests,
};

/// One minimal violating fixture per check id; the registry merges this map
/// into its own (FR-005).
final Map<String, SourceSet Function()> testHygieneViolatingFixtures = {
  'FR-086': () => SourceSet({'test/a_test.dart': '// test("t", () {});\n'}),
};
