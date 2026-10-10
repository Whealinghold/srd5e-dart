import 'package:test/test.dart';

import '../support/source_set.dart';
import '../support/violation.dart';
import 'rule_tags.dart';

typedef _Case = ({
  String label,
  String requirement,
  String path,
  Map<String, String> files,
  List<String> expected,
});

const String _fr029 = 'doc/specs/architecture-guardrails.md FR-029';
const String _fr030 = 'doc/specs/architecture-guardrails.md FR-030';
const String _fr031 = 'doc/specs/architecture-guardrails.md FR-031';

const String _a = 'doc/rules/a.md';
const String _b = 'doc/rules/b.md';
const String _tagA = 'a-0123456789ab';
const String _tagB = 'b-ba9876543210';
const String _goodA = 'RULE-TAG: `$_tagA`\n';
const String _goodB = 'RULE-TAG: `$_tagB`\n';
const String _agents =
    '# Rules\n\n## Read the rules first\n\n- `doc/rules/a.md`\n'
    '- `doc/rules/b.md`\n\n## Next\n';

List<String> _where(List<Violation> violations) => [
  for (final v in violations) '${v.checkId} ${v.path}:${v.line}',
];

_Case _case(
  String label,
  String requirement,
  String path,
  Map<String, String> files,
  List<String> expected,
) => (
  label: label,
  requirement: requirement,
  path: path,
  files: files,
  expected: expected,
);

final List<_Case> _fr029Cases = [
  _case(
    'no tag line',
    _fr029,
    'unhappy (boundary)',
    {_a: '# A\n'},
    ['FR-029 $_a:1'],
  ),
  _case(
    'two tag lines, both reported',
    _fr029,
    'unhappy (boundary)',
    {_a: '# A\n$_goodA$_goodA'},
    ['FR-029 $_a:2', 'FR-029 $_a:3'],
  ),
  _case(
    'hex too short',
    _fr029,
    'unhappy (invalid input)',
    {_a: 'x\nRULE-TAG: `a-0123456789a`\n'},
    ['FR-029 $_a:2'],
  ),
  _case(
    'hex has uppercase digits',
    _fr029,
    'unhappy (invalid input)',
    {_a: 'RULE-TAG: `a-0123456789AB`\n'},
    ['FR-029 $_a:1'],
  ),
  _case(
    'stem does not match the file',
    _fr029,
    'unhappy (invalid input)',
    {_a: 'RULE-TAG: `b-0123456789ab`\n'},
    ['FR-029 $_a:1'],
  ),
  _case(
    'value not backticked',
    _fr029,
    'unhappy (invalid input)',
    {_a: 'RULE-TAG: $_tagA\n'},
    ['FR-029 $_a:1'],
  ),
  _case('well-formed tag', _fr029, 'happy', {_a: '# A\n\n$_goodA'}, []),
  _case('label inside a sentence is not a tag line', _fr029, 'happy', {
    _a: 'Quote the RULE-TAG: label.\n$_goodA',
  }, []),
  _case('a non-rule file is ignored', _fr029, 'happy', {'doc/x.md': '#\n'}, []),
  _case('no rule files', _fr029, 'happy', {}, []),
];

final List<_Case> _fr030Cases = [
  _case(
    'copied into README',
    _fr030,
    'unhappy (invalid input)',
    {_a: _goodA, 'README.md': 'see\n$_tagA\n'},
    ['FR-030 README.md:2'],
  ),
  _case(
    'copied into a tool file',
    _fr030,
    'unhappy (invalid input)',
    {_a: _goodA, 'tool/t.dart': "const x = '$_tagA';\n"},
    ['FR-030 tool/t.dart:1'],
  ),
  _case(
    'repeated on another line of its own file',
    _fr030,
    'unhappy (invalid input)',
    {_a: '$_goodA\nagain $_tagA\n'},
    ['FR-030 $_a:3'],
  ),
  _case(
    'two rule files share a value, reported in both',
    _fr030,
    'unhappy (invalid input)',
    {_a: _goodA, _b: 'RULE-TAG: `$_tagA`\n'},
    ['FR-030 $_a:1', 'FR-030 $_b:1'],
  ),
  _case('own tag line only', _fr030, 'happy', {
    _a: _goodA,
    _b: _goodB,
    'README.md': 'nothing\n',
  }, []),
  _case('malformed tag is not searched for', _fr030, 'happy', {
    _a: 'RULE-TAG: `a-xyz`\n',
    'README.md': 'a-xyz\n',
  }, []),
];

final List<_Case> _fr031Cases = [
  _case(
    'unlisted rule file',
    _fr031,
    'unhappy (missing content)',
    {
      _a: _goodA,
      _b: _goodB,
      'AGENTS.md': '## Read the rules first\n\n- `doc/rules/a.md`\n',
    },
    ['FR-031 $_b:1'],
  ),
  _case(
    'listed file missing',
    _fr031,
    'unhappy (missing content)',
    {_a: _goodA, 'AGENTS.md': _agents},
    ['FR-031 AGENTS.md:6'],
  ),
  _case(
    'no AGENTS.md',
    _fr031,
    'unhappy (missing content)',
    {_a: _goodA},
    ['FR-031 $_a:1'],
  ),
  _case(
    'listed only outside the section',
    _fr031,
    'unhappy (missing content)',
    {_a: _goodA, 'AGENTS.md': '## Other\n\n- `doc/rules/a.md`\n'},
    ['FR-031 $_a:1'],
  ),
  _case('all listed and present', _fr031, 'happy', {
    _a: _goodA,
    _b: _goodB,
    'AGENTS.md': _agents,
  }, []),
  _case('empty repository', _fr031, 'happy', {}, []),
];

void _run(
  String title,
  List<_Case> cases,
  List<Violation> Function(SourceSet) check,
) {
  /// Requirement: per case
  /// Path: per case
  group(title, () {
    for (final c in cases) {
      test('${c.label} [${c.path}] (${c.requirement})', () {
        expect(_where(check(SourceSet(c.files))), c.expected);
      });
    }
  });
}

void main() {
  // Requirement: doc/specs/architecture-guardrails.md FR-029 - exactly one
  //   well-formed tag line per rule file.
  // Path: per case
  _run('FR-029', _fr029Cases, checkRuleTagShape);

  // Requirement: doc/specs/architecture-guardrails.md FR-030 - a tag value
  //   is not copied elsewhere.
  // Path: per case
  _run('FR-030', _fr030Cases, checkRuleTagsNotCopied);

  // Requirement: doc/specs/architecture-guardrails.md FR-031 - rule files
  //   and the AGENTS.md list agree.
  // Path: per case
  _run('FR-031', _fr031Cases, checkRuleFilesListed);
}
