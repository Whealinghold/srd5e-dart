import '../support/source_set.dart';
import '../support/violation.dart';

/// Rule-file checks FR-029, FR-030 and FR-031 of
/// `doc/specs/architecture-guardrails.md` (section 4.2).
///
/// Every function is pure: it reads a [SourceSet] and returns [Violation]s.
/// The checks read the tag lines of the rule files as data; no tag value is
/// kept in this file.

const String _rulesPrefix = 'doc/rules/';
const String _tagLabel = 'RULE-TAG:';
const String _agentsPath = 'AGENTS.md';
const String _listHeading = '## Read the rules first';

final RegExp _tagValue = RegExp(r'^`([a-z0-9_]+)-([0-9a-f]{12})`$');
final RegExp _backticked = RegExp(r'`([^`]+)`');

/// The rule files of [sources]: `doc/rules/<name>.md`, sorted.
List<String> ruleFilePaths(SourceSet sources) => [
  for (final path in sources.paths(prefix: _rulesPrefix, suffix: '.md'))
    if (!path.substring(_rulesPrefix.length).contains('/')) path,
];

String _stem(String path) =>
    path.substring(_rulesPrefix.length, path.length - '.md'.length);

/// The 1-based numbers of the lines of [path] that start with the tag label.
List<int> _tagLines(SourceSet sources, String path) {
  final lines = sources.files[path]!.split('\n');
  return [
    for (var i = 0; i < lines.length; i++)
      if (lines[i].startsWith(_tagLabel)) i + 1,
  ];
}

/// The well-formed tag token of [line] (the text after the label), or null.
/// A null [stem] accepts any stem.
String? _wellFormedToken(String line, String? stem) {
  final rest = line.substring(_tagLabel.length).trim();
  final match = _tagValue.firstMatch(rest);
  if (match == null || (stem != null && match.group(1) != stem)) return null;
  return '${match.group(1)}-${match.group(2)}';
}

/// FR-029: each rule file has exactly one tag line, and its value is a
/// backticked `<file stem>-<12 lowercase hex digits>` token.
List<Violation> checkRuleTagShape(SourceSet sources) {
  const id = 'FR-029';
  final violations = <Violation>[];
  for (final path in ruleFilePaths(sources)) {
    final tagLines = _tagLines(sources, path);
    if (tagLines.length != 1) {
      if (tagLines.isEmpty) {
        violations.add(
          Violation(
            checkId: id,
            path: path,
            line: 1,
            detail:
                'Has no line starting with "$_tagLabel"; exactly one is '
                'required.',
          ),
        );
      } else {
        for (final line in tagLines) {
          violations.add(
            Violation(
              checkId: id,
              path: path,
              line: line,
              detail:
                  'One of ${tagLines.length} lines starting with '
                  '"$_tagLabel"; exactly one is required.',
            ),
          );
        }
      }
      continue;
    }
    final line = tagLines.single;
    final text = sources.files[path]!.split('\n')[line - 1];
    if (_wellFormedToken(text, _stem(path)) == null) {
      violations.add(
        Violation(
          checkId: id,
          path: path,
          line: line,
          detail:
              'The tag value must be a backticked token '
              '"${_stem(path)}-" followed by 12 lowercase hex digits.',
        ),
      );
    }
  }
  return sortedViolations(violations);
}

/// FR-030: a rule tag's value appears nowhere but on its own tag line. Any
/// other line of any file (the file's own included) naming it is a Violation,
/// and two rule files sharing a value is a Violation in both.
List<Violation> checkRuleTagsNotCopied(SourceSet sources) {
  const id = 'FR-030';
  final violations = <Violation>[];
  for (final path in ruleFilePaths(sources)) {
    final tagLines = _tagLines(sources, path);
    if (tagLines.length != 1) continue;
    final ownLine = tagLines.single;
    final token = _wellFormedToken(
      sources.files[path]!.split('\n')[ownLine - 1],
      null,
    );
    if (token == null) continue;
    for (final other in sources.files.keys.toList()..sort()) {
      final lines = sources.files[other]!.split('\n');
      for (var i = 0; i < lines.length; i++) {
        if (other == path && i + 1 == ownLine) continue;
        if (!lines[i].contains(token)) continue;
        violations.add(
          Violation(
            checkId: id,
            path: other,
            line: i + 1,
            detail:
                'Contains the rule tag value of $path; a tag must appear '
                'only on its own tag line.',
          ),
        );
      }
    }
  }
  return sortedViolations(violations.toSet());
}

/// FR-031: every rule file is listed in the `AGENTS.md` "Read the rules
/// first" list, and every path listed there exists.
List<Violation> checkRuleFilesListed(SourceSet sources) {
  const id = 'FR-031';
  final violations = <Violation>[];
  final rules = ruleFilePaths(sources);
  final listed = <String, int>{};
  final agents = sources.files[_agentsPath];
  if (agents != null) {
    var inList = false;
    final lines = agents.split('\n');
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.startsWith('#')) {
        inList = line.trimRight() == _listHeading;
        continue;
      }
      if (!inList || !line.startsWith('- ')) continue;
      final match = _backticked.firstMatch(line);
      if (match != null) listed.putIfAbsent(match.group(1)!, () => i + 1);
    }
  }
  for (final path in rules) {
    if (listed.containsKey(path)) continue;
    violations.add(
      Violation(
        checkId: id,
        path: path,
        line: 1,
        detail: 'Is not listed under "$_listHeading" in $_agentsPath.',
      ),
    );
  }
  for (final entry in listed.entries) {
    if (sources.files.containsKey(entry.key)) continue;
    violations.add(
      Violation(
        checkId: id,
        path: _agentsPath,
        line: entry.value,
        detail: 'Lists ${entry.key}, which does not exist.',
      ),
    );
  }
  return sortedViolations(violations);
}

/// The check function per id, for the registry (`registry.dart`, FR-005).
const Map<String, List<Violation> Function(SourceSet)> ruleTagChecks = {
  'FR-029': checkRuleTagShape,
  'FR-030': checkRuleTagsNotCopied,
  'FR-031': checkRuleFilesListed,
};

/// One minimal violating fixture per check id; the registry merges this map
/// into its own (FR-005).
final Map<String, SourceSet Function()> ruleTagViolatingFixtures = {
  'FR-029': () => SourceSet({'doc/rules/a.md': '# A\n'}),
  'FR-030': () => SourceSet({
    'doc/rules/a.md': 'RULE-TAG: `a-0123456789ab`\n',
    'README.md': 'a-0123456789ab\n',
  }),
  'FR-031': () => SourceSet({
    'doc/rules/a.md': 'RULE-TAG: `a-0123456789ab`\n',
    'AGENTS.md': '## Read the rules first\n\n- `doc/rules/b.md`\n',
  }),
};
