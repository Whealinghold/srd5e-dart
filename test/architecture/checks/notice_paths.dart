import '../support/gitignore.dart';
import '../support/source_set.dart';
import '../support/violation.dart';

/// FR-079 of `doc/specs/architecture-guardrails.md`: the `NOTICE.md` covered
/// paths and the `.pubignore` exclusion of `doc/research/`.
///
/// Pure: a function of a [SourceSet].

/// The paths `NOTICE.md` must cover (FR-079 (a), a named constant of FR-009).
/// A self-test keeps it equal to the list in
/// `doc/specs/shared-types-and-ownership.md` FR-033.
const Set<String> noticeCoveredPaths = {
  'data/',
  'lib/src/content/data/',
  'test/fixtures/srd/',
};

/// The roots whose files count as bundled content (FR-079 (a)).
const List<String> bundledContentRoots = [
  'data/',
  'lib/src/content/data/',
  'test/fixtures/srd/',
];

/// The root of the research notes (FR-079 (b)).
const String researchRoot = 'doc/research/';

/// A backticked token that is a path ending in `/` (FR-079 (a)).
final RegExp noticePathToken = RegExp(r'^[A-Za-z0-9_.-]+(/[A-Za-z0-9_.-]+)*/$');

final RegExp _inlineCode = RegExp(r'`([^`\n]+)`');
final RegExp _heading = RegExp(r'^ {0,3}(#{1,6})\s+(.*?)\s*#*\s*$');

/// The backticked path tokens of [text], by the token rule of FR-079 (a),
/// with their 1-based line offsets (relative to the first line of [text]).
List<({String token, int line})> noticePathTokens(String text) {
  final tokens = <({String token, int line})>[];
  final lines = text.split('\n');
  for (var i = 0; i < lines.length; i++) {
    for (final match in _inlineCode.allMatches(lines[i])) {
      final token = match.group(1)!;
      if (noticePathToken.hasMatch(token)) {
        tokens.add((token: token, line: i + 1));
      }
    }
  }
  return tokens;
}

bool _isContent(String path) {
  if (!bundledContentRoots.any(path.startsWith)) return false;
  final name = path.substring(path.lastIndexOf('/') + 1);
  return name != '.gitkeep' && name != 'README.md';
}

/// FR-079: (a) while bundled content is present, the covered paths in the
/// "Scope" section of `NOTICE.md` equal [noticeCoveredPaths]; (b) while
/// `doc/research/` holds files, `.pubignore` excludes it.
List<Violation> checkNoticePaths(SourceSet sources) {
  return sortedViolations([
    ..._checkNoticeScope(sources),
    ..._checkPubignore(sources),
  ]);
}

List<Violation> _checkNoticeScope(SourceSet sources) {
  const id = 'FR-079';
  const path = 'NOTICE.md';
  if (!sources.files.keys.any(_isContent)) return const [];
  final text = sources.files[path];
  if (text == null) return const [];
  final lines = text.split('\n');
  int? headingLine;
  var level = 0;
  var end = lines.length;
  for (var i = 0; i < lines.length; i++) {
    final match = _heading.firstMatch(lines[i]);
    if (match == null) continue;
    if (headingLine == null) {
      if (match.group(2)!.toLowerCase() == 'scope') {
        headingLine = i;
        level = match.group(1)!.length;
      }
    } else if (match.group(1)!.length <= level) {
      end = i;
      break;
    }
  }
  if (headingLine == null) return const [];
  final tokens = noticePathTokens(
    lines.sublist(headingLine + 1, end).join('\n'),
  );
  final found = {for (final t in tokens) t.token};
  final violations = <Violation>[];
  for (final missing in noticeCoveredPaths.toList()..sort()) {
    if (found.contains(missing)) continue;
    violations.add(
      Violation(
        checkId: id,
        path: path,
        line: headingLine + 1,
        detail: 'The Scope section does not list the covered path `$missing`.',
      ),
    );
  }
  for (final token in tokens) {
    if (noticeCoveredPaths.contains(token.token)) continue;
    violations.add(
      Violation(
        checkId: id,
        path: path,
        line: headingLine + 2 + token.line - 1,
        detail:
            'The Scope section lists `${token.token}`, which is not a '
            'covered path.',
      ),
    );
  }
  return violations;
}

List<Violation> _checkPubignore(SourceSet sources) {
  const id = 'FR-079';
  const path = '.pubignore';
  if (!sources.files.keys.any((p) => p.startsWith(researchRoot))) {
    return const [];
  }
  final text = sources.files[path];
  if (text == null) {
    return const [
      Violation(
        checkId: id,
        path: path,
        line: 1,
        detail: 'doc/research/ holds files but there is no .pubignore.',
      ),
    ];
  }
  final rules = GitignoreRules.parse(text);
  if (rules.excludes('doc/research', isDirectory: true)) return const [];
  return const [
    Violation(
      checkId: id,
      path: path,
      line: 1,
      detail: '.pubignore does not exclude doc/research/.',
    ),
  ];
}

/// The check ids of this file, for the registry (FR-005).
const Map<String, List<Violation> Function(SourceSet)> noticePathsChecks = {
  'FR-079': checkNoticePaths,
};

/// One minimal violating fixture per check id (FR-005).
final Map<String, SourceSet Function()> noticePathsViolatingFixtures = {
  'FR-079': () => SourceSet({
    'data/a.json': '{}\n',
    'NOTICE.md': '# Notice\n\n## Scope\n\nCovers `data/` only.\n',
  }),
};
