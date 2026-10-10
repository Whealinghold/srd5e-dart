import 'dart:io';

import 'package:test/test.dart';

import '../support/markdown_tables.dart';
import '../support/package_root.dart';
import '../support/source_set.dart';
import '../support/violation.dart';
import 'notice_paths.dart';

const Timeout _budget = Timeout(Duration(seconds: 10));

List<String> _where(List<Violation> violations) => [
  for (final v in violations) '${v.checkId} ${v.path}:${v.line}',
];

String _notice(String scopeBody, {String after = ''}) =>
    '# Notice\n\n## Scope\n\n$scopeBody\n\n## Attribution\n\n$after\n';

const String _all =
    'Covers `data/`, `lib/src/content/data/` and '
    '`test/fixtures/srd/`.';

typedef _Case = ({
  String label,
  String path,
  Map<String, String> files,
  List<String> expected,
});

final List<_Case> _cases = [
  (
    label: 'Scope lists exactly the three paths',
    path: 'happy',
    files: {'data/a.json': '{}\n', 'NOTICE.md': _notice(_all)},
    expected: [],
  ),
  (
    label: 'a missing path is reported at the Scope heading',
    path: 'unhappy (state error)',
    files: {
      'lib/src/content/data/a.dart': 'x\n',
      'NOTICE.md': _notice('Covers `data/` and `test/fixtures/srd/`.'),
    },
    expected: ['FR-079 NOTICE.md:3'],
  ),
  (
    label: 'an extra docs/ is reported at its token line',
    path: 'unhappy (state error)',
    files: {
      'data/a.json': '{}\n',
      'NOTICE.md': _notice('$_all\n\nAlso `docs/`.'),
    },
    expected: ['FR-079 NOTICE.md:7'],
  ),
  (
    label: 'a path without the trailing slash counts as missing',
    path: 'unhappy (boundary)',
    files: {
      'test/fixtures/srd/a.txt': 'x\n',
      'NOTICE.md': _notice(
        'Covers `data/`, `lib/src/content/data/` and `test/fixtures/srd`.',
      ),
    },
    expected: ['FR-079 NOTICE.md:3'],
  ),
  (
    label: 'tokens outside Scope are ignored',
    path: 'unhappy (boundary)',
    files: {
      'data/a.json': '{}\n',
      'NOTICE.md': _notice(_all, after: 'Mentions `docs/` here.'),
    },
    expected: [],
  ),
  (
    label: 'no bundled content (vacuous)',
    path: 'unhappy (empty and minimal)',
    files: {
      'data/.gitkeep': '',
      'data/README.md': 'r\n',
      'NOTICE.md': _notice('Nothing.'),
    },
    expected: [],
  ),
  (
    label: 'no NOTICE.md is not this check',
    path: 'unhappy (empty and minimal)',
    files: {'data/a.json': '{}\n'},
    expected: [],
  ),
  (
    label: 'no Scope section is not this check',
    path: 'unhappy (empty and minimal)',
    files: {'data/a.json': '{}\n', 'NOTICE.md': '# Notice\n\nText.\n'},
    expected: [],
  ),
  (
    label: '.pubignore excluding doc/ (parent excluded)',
    path: 'happy',
    files: {'doc/research/sources.md': 'x\n', '.pubignore': 'doc/\n'},
    expected: [],
  ),
  (
    label: '.pubignore excluding doc/research/',
    path: 'happy',
    files: {'doc/research/sources.md': 'x\n', '.pubignore': 'doc/research/\n'},
    expected: [],
  ),
  (
    label: '.pubignore with doc/* then !doc/research/',
    path: 'unhappy (rule interaction)',
    files: {
      'doc/research/sources.md': 'x\n',
      '.pubignore': 'doc/*\n!doc/research/\n',
    },
    expected: ['FR-079 .pubignore:1'],
  ),
  (
    label: 'no .pubignore',
    path: 'unhappy (state error)',
    files: {'doc/research/sources.md': 'x\n'},
    expected: ['FR-079 .pubignore:1'],
  ),
  (
    label: 'no doc/research/ files (vacuous)',
    path: 'unhappy (empty and minimal)',
    files: {'doc/a.md': 'x\n'},
    expected: [],
  ),
];

void main() {
  group('checkNoticePaths', () {
    /// Requirement: per case - doc/specs/architecture-guardrails.md FR-079 -
    ///   NOTICE.md Scope paths and the `.pubignore` exclusion, with exact
    ///   Violations (check id, path, line) per case.
    /// Path: per case
    for (final c in _cases) {
      test('${c.path}: ${c.label}', () {
        expect(_where(checkNoticePaths(SourceSet(c.files))), c.expected);
      });
    }
  });

  group('violating fixture', () {
    /// Requirement: doc/specs/architecture-guardrails.md FR-005 and FR-079 -
    ///   the registered fixture yields an FR-079 Violation.
    /// Path: unhappy (state error)
    test('FR-079 fixture violates', () {
      final fixture = noticePathsViolatingFixtures['FR-079']!();
      final found = noticePathsChecks['FR-079']!(fixture);
      expect(found, isNotEmpty);
      expect(found.map((v) => v.checkId).toSet(), {'FR-079'});
    });
  });

  group('noticeCoveredPaths', () {
    /// Requirement: doc/specs/architecture-guardrails.md FR-079 (c) - the
    ///   constant equals the backticked path tokens in the first sentence of
    ///   the FR-033 row of shared-types-and-ownership.md, so the two cannot
    ///   drift.
    /// Path: unhappy (state error)
    test('equals the tokens of the FR-033 first sentence', () {
      final text = File(
        '${findPackageRoot().path}/doc/specs/shared-types-and-ownership.md',
      ).readAsStringSync();
      String? cell;
      for (final table in parseMarkdownTables(text)) {
        for (final row in table.rows) {
          final candidate = row.cell(1);
          if (row.cell(0) == 'FR-033' &&
              candidate != null &&
              candidate.startsWith('`NOTICE.md` covers exactly:')) {
            cell = candidate;
          }
        }
      }
      expect(cell, isNotNull, reason: 'FR-033 row not found');
      final end = cell!.indexOf('. ');
      final sentence = end < 0 ? cell : cell.substring(0, end + 1);
      final tokens = {for (final t in noticePathTokens(sentence)) t.token};
      expect(noticeCoveredPaths, tokens);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-079 (a) - the
    ///   token rule accepts a path ending in `/` and nothing else.
    /// Path: unhappy (boundary)
    test('the token rule needs a trailing slash and plain segments', () {
      final tokens = noticePathTokens(
        '`data/` `data` `a b/` `NOTICE.md` `x/y.z/` `/abs/`',
      ).map((t) => t.token);
      expect(tokens, ['data/', 'x/y.z/']);
    });
  }, timeout: _budget);
}
