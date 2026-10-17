import 'package:test/test.dart';

import '../support/constants.dart'
    show DeniedName, affiliateDenylist, trademarkDenylist;
import '../support/source_set.dart';
import '../support/violation.dart';
import 'notice.dart';
import 'notice_files.dart';
import 'notice_marks.dart';
import 'notice_paths.dart';

const String _spec = 'doc/specs/content-licensing-and-notice.md';

/// The licensor's bare name, assembled from fragments (FR-031): the bare name
/// is on no denylist, but the stress cases of S-19 and S-36 add it to the
/// scanned lists to prove the statement and the non-endorsement sentence are
/// removed before the scan.
const DeniedName _licensor = DeniedName(['wizards', 'of', 'the', 'coast']);

final List<DeniedName> _extendedTrademarks = [...trademarkDenylist, _licensor];
final List<DeniedName> _extendedAffiliates = [...affiliateDenylist, _licensor];

/// The first affiliate name, assembled at run time (FR-031).
final String _affiliate = affiliateDenylist.first.name;

/// The statement with its spaces replaced by U+00A0 (case A-04).
final String _statementNbsp = attributionStatement.replaceAll(
  ' ',
  String.fromCharCode(0xA0),
);

/// The statement re-wrapped across lines (cases A-02, A-03, S-36, S-28).
final String _statementWrapped = _wrap(attributionStatement, 9);

String _wrap(String text, int wordsPerLine) {
  final words = text.split(' ');
  final lines = <String>[];
  for (var i = 0; i < words.length; i += wordsPerLine) {
    lines.add(words.skip(i).take(wordsPerLine).join(' '));
  }
  return lines.join('\n');
}

String _blockquote(String text) =>
    [for (final line in text.split('\n')) '> $line'].join('\n');

List<String> _where(List<Violation> violations) => [
  for (final v in violations) '${v.checkId} ${v.path}:${v.line}',
];

/// The 1-based line of [needle] in [text]; fails the test when absent.
int _lineOf(String text, String needle) {
  final at = text.split('\n').indexOf(needle);
  if (at < 0) throw StateError('fixture lost the line: $needle');
  return at + 1;
}

/// A full, otherwise-clean notice; every part can be replaced or omitted
/// (null) per fixture.
const String _defaultScope =
    'This notice covers **only** the fifth-edition '
    '**game content** **bundled** with this package: `data/`, '
    '`lib/src/content/data/` and `test/fixtures/srd/`.';
const String _defaultMit =
    'The code is licensed under the MIT License; see [LICENSE](LICENSE).';
const String _defaultChanges =
    "The SRD's rules are restructured here into code and data files.";
const String _defaultEndorsement =
    'This package is independent and is not '
    'published, endorsed or approved by Wizards of the Coast.';

String _fullNotice({
  String scope = _defaultScope,
  String mit = _defaultMit,
  String? status,
  String attribution = attributionStatement,
  String? changes = _defaultChanges,
  String? endorsement = _defaultEndorsement,
}) {
  final buffer = StringBuffer('# Notice\n\n## Scope\n\n$scope\n\n$mit\n');
  if (status != null) buffer.write('\n$status\n');
  buffer.write('\n## Attribution\n\n$attribution\n');
  if (changes != null) buffer.write('\n## Changes\n\n$changes\n');
  if (endorsement != null) buffer.write('\n$endorsement\n');
  return buffer.toString();
}

const String _mitText =
    'MIT License\n'
    '\n'
    'Copyright (c) 2026 the package authors\n'
    '\n'
    'Permission is hereby granted, free of charge, to any person obtaining a '
    'copy of this software to deal in the Software without restriction.\n';

/// The Changes heading's line in a notice without a status line; its body
/// starts two lines lower.
final int _changesHeading = _lineOf(_fullNotice(changes: 'x'), '## Changes');

final String _statusNotice = _fullNotice(
  status: '**Status:** no game content is bundled yet.',
);

final int _statusLine = _lineOf(
  _statusNotice,
  '**Status:** no game content is bundled yet.',
);

typedef _Case = ({
  String label,
  String requirement,
  String path,
  SourceSet sources,
  List<Violation> Function(SourceSet sources) check,
  List<String> expected,
});

/// The statement checks of the A-table: the verbatim check, the
/// one-occurrence check and the affiliate scan together.
List<Violation> _statementChecks(SourceSet sources) => [
  ...checkAttributionStatement(sources),
  ...checkStatementOnceInAttribution(sources),
  ...checkNoAffiliateCredits(sources),
];

/// The A-table: a complete notice whose "Attribution" body is the candidate
/// text. Body line i sits on file line 8 + i.
_Case _caseA(
  String label,
  String requirement,
  String attributionBody, {
  List<String> expected = const [],
  String path = 'happy',
}) => (
  label: label,
  requirement: '$_spec $requirement',
  path: path,
  sources: SourceSet({'NOTICE.md': _candidate(attributionBody)}),
  check: _statementChecks,
  expected: expected,
);

/// The A-table template: a complete notice whose "Attribution" body is the
/// candidate text.
String _candidate(String attributionBody) =>
    '# Notice\n'
    '\n'
    '## Scope\n'
    '\n'
    'This notice covers **only** the fifth-edition **game content** '
    '**bundled** with this package.\n'
    '\n'
    '## Attribution\n'
    '\n'
    '$attributionBody\n'
    '## Changes\n'
    '\n'
    "The SRD's rules are **restructured** here into code and data files.\n"
    '\n'
    'This package is independent and is not published, endorsed or approved '
    'by Wizards of the Coast.\n';

/// An arbitrary-file case run by one named check or check combination.
_Case _case(
  String label,
  String requirement,
  String path,
  Map<String, String> files,
  List<Violation> Function(SourceSet) check,
  List<String> expected,
) => (
  label: label,
  requirement: '$_spec $requirement',
  path: path,
  sources: SourceSet(files),
  check: check,
  expected: expected,
);

final List<_Case> _attributionCases = [
  _caseA('A-01: exact statement', 'FR-002', attributionStatement),
  _caseA('A-02: re-wrapped across lines', 'FR-002', _statementWrapped),
  _caseA('A-03: blockquote-wrapped', 'FR-002', _blockquote(_statementWrapped)),
  _caseA('A-04: NBSP between words', 'FR-002', _statementNbsp),
  _caseA(
    'A-05: straight quotes',
    'FR-002',
    attributionStatement
        .replaceFirst('\u201C', '"')
        .replaceFirst('\u201D', '"'),
    expected: ['CLN-FR-002 NOTICE.md:1'],
    path: 'unhappy (boundary: near-miss)',
  ),
  _caseA(
    'A-06: word dropped',
    'FR-002',
    attributionStatement.replaceFirst('Document 5.2.1', 'Document'),
    expected: ['CLN-FR-002 NOTICE.md:1'],
    path: 'unhappy (boundary: near-miss)',
  ),
  _caseA(
    'A-07: wrong version',
    'FR-002',
    attributionStatement.replaceAll('5.2.1', '5.1'),
    expected: ['CLN-FR-002 NOTICE.md:1'],
    path: 'unhappy (boundary: edition mix-up)',
  ),
  _caseA(
    'A-08: http scheme',
    'FR-002',
    attributionStatement.replaceFirst(
      'https://www.dndbeyond.com',
      'http://www.dndbeyond.com',
    ),
    expected: ['CLN-FR-002 NOTICE.md:1'],
    path: 'unhappy (boundary: near-miss)',
  ),
  _caseA(
    'A-09: wrong licence URL',
    'FR-002',
    attributionStatement.replaceFirst('/by/4.0/legalcode.', '/by/4.0.'),
    expected: ['CLN-FR-002 NOTICE.md:1'],
    path: 'unhappy (boundary: near-miss)',
  ),
  _caseA(
    'A-10: trailing-slash URL',
    'FR-002',
    attributionStatement.replaceFirst(
      '/by/4.0/legalcode.',
      '/by/4.0/legalcode/.',
    ),
    expected: ['CLN-FR-002 NOTICE.md:1'],
    path: 'unhappy (boundary: near-miss)',
  ),
  _caseA(
    'A-11: lowercase licensor',
    'FR-002',
    attributionStatement.replaceFirst(
      'Wizards of the Coast LLC',
      'wizards of the coast llc',
    ),
    expected: ['CLN-FR-002 NOTICE.md:1'],
    path: 'unhappy (boundary: case)',
  ),
  _caseA(
    'A-12: punctuation swapped',
    'FR-002',
    attributionStatement.replaceFirst('LLC, available', 'LLC; available'),
    expected: ['CLN-FR-002 NOTICE.md:1'],
    path: 'unhappy (boundary: near-miss)',
  ),
  _caseA(
    'A-13: inside an HTML comment',
    'FR-002',
    '<!--\n$attributionStatement\n-->',
    expected: ['CLN-FR-002 NOTICE.md:1'],
    path: 'unhappy (invalid input: hidden)',
  ),
  _caseA(
    'A-14: inside a code fence',
    'FR-002',
    '```\n$attributionStatement\n```',
    expected: ['CLN-FR-002 NOTICE.md:1'],
    path: 'unhappy (invalid input: hidden)',
  ),
  _caseA(
    'A-15: statement missing',
    'FR-002',
    'Nothing is attributed here.',
    expected: ['CLN-FR-002 NOTICE.md:1'],
    path: 'unhappy (missing content)',
  ),
  _caseA(
    'A-16: statement twice',
    'FR-035',
    '$attributionStatement\n\n$attributionStatement',
    expected: ['CLN-FR-035 NOTICE.md:11'],
    path: 'unhappy (boundary: duplicate)',
  ),
  _caseA(
    'A-17: extra attribution',
    'FR-004',
    '$attributionStatement\n\nWith thanks to $_affiliate for the rules.',
    expected: ['CLN-FR-004 NOTICE.md:11'],
    path: 'unhappy (invalid input)',
  ),
  (
    label: 'A-18: empty file',
    requirement: '$_spec FR-002',
    path: 'unhappy (empty and minimal case)',
    sources: SourceSet({'NOTICE.md': ''}),
    check: _statementChecks,
    expected: ['CLN-FR-002 NOTICE.md:1'],
  ),
];

final List<_Case> _structuralCases = [
  _case(
    'S-01: no NOTICE.md',
    'FR-001',
    'unhappy (missing content)',
    {'LICENSE': _mitText},
    checkNoticeFilesPresent,
    ['CLN-FR-001 NOTICE.md:1'],
  ),
  _case(
    'S-01: no LICENSE',
    'FR-001',
    'unhappy (missing content)',
    {'NOTICE.md': _fullNotice()},
    checkNoticeFilesPresent,
    ['CLN-FR-001 LICENSE:1'],
  ),
  _case(
    'S-01: both present',
    'FR-001',
    'happy',
    {'NOTICE.md': _fullNotice(), 'LICENSE': _mitText},
    checkNoticeFilesPresent,
    [],
  ),
  _case(
    'S-02: no Scope section',
    'FR-005',
    'unhappy (missing content)',
    {'NOTICE.md': '# Notice\n\nNothing structured yet.\n'},
    checkScopeSection,
    ['CLN-FR-005 NOTICE.md:1'],
  ),
  _case(
    'S-02: Scope without the keywords',
    'FR-005',
    'unhappy (missing content)',
    {'NOTICE.md': '# Notice\n\n## Scope\n\nPoints at directories.\n'},
    checkScopeSection,
    ['CLN-FR-005 NOTICE.md:3'],
  ),
  _case(
    'S-02: bold keywords still match',
    'FR-005',
    'happy',
    {
      'NOTICE.md':
          '# Notice\n\n## Scope\n\nCovers **only** the fifth-edition '
          '**game content** **bundled** with this package.\n',
    },
    checkScopeSection,
    [],
  ),
  _case(
    'S-04: no whole word MIT',
    'FR-006',
    'unhappy (missing content)',
    {
      'NOTICE.md': _fullNotice(
        mit:
            'The code is licensed under a permissive licence; see '
            '[LICENSE](LICENSE).',
      ),
    },
    checkMitLicenseStatement,
    ['CLN-FR-006 NOTICE.md:1'],
  ),
  _case(
    'S-04: no whole word LICENSE',
    'FR-006',
    'unhappy (missing content)',
    {'NOTICE.md': _fullNotice(mit: 'The code is MIT-licensed.')},
    checkMitLicenseStatement,
    ['CLN-FR-006 NOTICE.md:1'],
  ),
  _case(
    'S-04: the **MIT** License and LICENSE both present',
    'FR-006',
    'happy',
    {
      'NOTICE.md': _fullNotice(
        mit:
            'The code is licensed under the **MIT** License; see '
            '[LICENSE](LICENSE).',
      ),
    },
    checkMitLicenseStatement,
    [],
  ),
  _case(
    'keyword normalisation: a keyword hidden in an HTML comment does not match',
    'FR-005',
    'unhappy (invalid input: hidden)',
    {
      'NOTICE.md':
          '# Notice\n\n## Scope\n\n<!-- only game content bundled -->\n',
    },
    checkScopeSection,
    ['CLN-FR-005 NOTICE.md:3'],
  ),
  _case(
    'keyword normalisation: a keyword wrapped across lines matches',
    'FR-005',
    'happy (boundary: line wrap)',
    {
      'NOTICE.md':
          '# Notice\n\n## Scope\n\nCovers **only** the fifth-edition '
          'game\ncontent **bundled** with this package.\n',
    },
    checkScopeSection,
    [],
  ),
  _case(
    'keyword normalisation: a fenced keyword does not satisfy the Changes section',
    'FR-012',
    'unhappy (invalid input: hidden)',
    {
      'data/srd_5_2_1/spells.json': '{}\n',
      'NOTICE.md': _fullNotice(changes: '```\nrestructured\n```'),
    },
    checkChangesSection,
    ['CLN-FR-012 NOTICE.md:$_changesHeading'],
  ),
  _case(
    'S-05: game content licensed under MIT in one sentence',
    'FR-007',
    'unhappy (rule interaction)',
    {
      'NOTICE.md':
          '# Notice\n\nThe game content is licensed under the MIT '
          'License.\n',
    },
    checkGameContentNotMit,
    ['CLN-FR-007 NOTICE.md:3'],
  ),
  _case(
    'S-05: the code licensed under MIT is clean',
    'FR-007',
    'happy',
    {'NOTICE.md': '# Notice\n\nThe code is licensed under the MIT License.\n'},
    checkGameContentNotMit,
    [],
  ),
  _case(
    'S-06: wrapped sentence still matches',
    'FR-007',
    'unhappy (boundary: line wrap)',
    {
      'NOTICE.md':
          '# Notice\n\nThe game content is licensed under\nthe MIT '
          'License.\n',
    },
    checkGameContentNotMit,
    ['CLN-FR-007 NOTICE.md:3'],
  ),
  _case(
    'S-06: "is not licensed" is negated',
    'FR-007',
    'happy',
    {
      'NOTICE.md':
          '# Notice\n\nThe game content is not licensed under\nthe '
          'MIT License.\n',
    },
    checkGameContentNotMit,
    [],
  ),
  _case(
    'S-07: "Note" is not "not"',
    'FR-007',
    'unhappy (boundary: substring not)',
    {
      'NOTICE.md':
          '# Notice\n\nNote: the game content is licensed under the '
          'MIT License.\n',
    },
    checkGameContentNotMit,
    ['CLN-FR-007 NOTICE.md:3'],
  ),
  _case(
    'S-08: adjacent lines are different sentences',
    'FR-007',
    'happy (boundary: wrap creates no match)',
    {
      'NOTICE.md':
          '# Notice\n\nThe code is MIT.\nThe SRD content is '
          'CC-BY-4.0.\n',
    },
    checkGameContentNotMit,
    [],
  ),
  _case(
    'S-09: semicolon keeps one sentence',
    'FR-007',
    'unhappy (boundary: semicolon)',
    {
      'NOTICE.md':
          '# Notice\n\nThe code is MIT-licensed; the game content is '
          'CC-BY-4.0.\n',
    },
    checkGameContentNotMit,
    ['CLN-FR-007 NOTICE.md:3'],
  ),
  _case(
    'S-09: full stop splits the sentences',
    'FR-007',
    'happy',
    {
      'NOTICE.md':
          '# Notice\n\nThe code is MIT-licensed. The game content is '
          'CC-BY-4.0.\n',
    },
    checkGameContentNotMit,
    [],
  ),
  _case(
    'S-13: status line while content is present',
    'FR-011',
    'unhappy (state error)',
    {'data/srd_5_2_1/spells.json': '{}\n', 'NOTICE.md': _statusNotice},
    checkStatusLine,
    ['CLN-FR-011 NOTICE.md:$_statusLine'],
  ),
  _case(
    'S-13: status line removed',
    'FR-011',
    'happy',
    {'data/srd_5_2_1/spells.json': '{}\n', 'NOTICE.md': _fullNotice()},
    checkStatusLine,
    [],
  ),
  _case(
    'S-14: only .gitkeep files, status line permitted',
    'FR-011',
    'happy (empty and minimal)',
    {
      'data/srd_5_2_1/.gitkeep': '',
      'lib/src/content/data/.gitkeep': '',
      'NOTICE.md': _fullNotice(
        status: '**Status:** no game content is bundled yet.',
      ),
    },
    checkStatusLine,
    [],
  ),
  _case(
    'S-15: a fixture alone counts as content',
    'FR-011',
    'unhappy (state error: fixture-only)',
    {'test/fixtures/srd/a.json': '{}\n', 'NOTICE.md': _statusNotice},
    checkStatusLine,
    ['CLN-FR-011 NOTICE.md:$_statusLine'],
  ),
  _case(
    'S-16: no Changes section while content is present',
    'FR-012',
    'unhappy (missing content)',
    {
      'data/srd_5_2_1/spells.json': '{}\n',
      'NOTICE.md': _fullNotice(changes: null),
    },
    checkChangesSection,
    ['CLN-FR-012 NOTICE.md:1'],
  ),
  _case(
    'S-16: Changes without "restructured"',
    'FR-012',
    'unhappy (missing content)',
    {
      'data/srd_5_2_1/spells.json': '{}\n',
      'NOTICE.md': _fullNotice(changes: 'The rules were rearranged.'),
    },
    checkChangesSection,
    ['CLN-FR-012 NOTICE.md:$_changesHeading'],
  ),
  _case(
    'S-16: bold "restructured" matches',
    'FR-012',
    'happy',
    {
      'data/srd_5_2_1/spells.json': '{}\n',
      'NOTICE.md': _fullNotice(
        changes:
            'The rules are **restructured** here into code and data '
            'files.',
      ),
    },
    checkChangesSection,
    [],
  ),
  _case(
    'S-17: Changes says "reviewed by Wizards"',
    'FR-013',
    'unhappy (invalid input)',
    {
      'NOTICE.md': _fullNotice(
        changes: 'The changes were reviewed by Wizards of the Coast.',
      ),
    },
    checkChangesEndorsement,
    ['CLN-FR-013 NOTICE.md:${_changesHeading + 2}'],
  ),
  _case(
    'S-17: wrapped "reviewed by" still matches',
    'FR-013',
    'unhappy (invalid input)',
    {
      'NOTICE.md': _fullNotice(
        changes: 'The changes were reviewed\nby Wizards of the Coast.',
      ),
    },
    checkChangesEndorsement,
    ['CLN-FR-013 NOTICE.md:${_changesHeading + 2}'],
  ),
  _case(
    'S-17: plain restructuring text is clean',
    'FR-013',
    'happy',
    {'NOTICE.md': _fullNotice()},
    checkChangesEndorsement,
    [],
  ),
  _case(
    'S-20: no non-endorsement sentence',
    'FR-015',
    'unhappy (missing content)',
    {'NOTICE.md': _fullNotice(endorsement: null)},
    checkNonEndorsementSentence,
    ['CLN-FR-015 NOTICE.md:1'],
  ),
  _case(
    'S-20: "independent" missing',
    'FR-015',
    'unhappy (missing content)',
    {
      'NOTICE.md': _fullNotice(
        endorsement:
            'It is not published, endorsed or approved by Wizards '
            'of the Coast.',
      ),
    },
    checkNonEndorsementSentence,
    ['CLN-FR-015 NOTICE.md:1'],
  ),
  _case(
    'S-20: the sentence with markup',
    'FR-015',
    'happy',
    {
      'NOTICE.md': _fullNotice(
        endorsement:
            'It is *independent* and is **not** published, endorsed '
            'or approved by Wizards of the Coast.',
      ),
    },
    checkNonEndorsementSentence,
    [],
  ),
  _case(
    'S-26: sources.md says 5.1.0',
    'FR-024',
    'unhappy (state error)',
    {
      'NOTICE.md': _fullNotice(),
      'doc/research/sources.md': '| System Reference Document | 5.1.0 |\n',
    },
    checkSrdVersionsAgree,
    ['CLN-FR-024 NOTICE.md:1'],
  ),
  _case(
    'S-26: both say 5.2.1',
    'FR-024',
    'happy',
    {
      'NOTICE.md': _fullNotice(),
      'doc/research/sources.md':
          '| System Reference Document | 5.2.1 (released 2025-05-01) |\n',
    },
    checkSrdVersionsAgree,
    [],
  ),
  _case(
    'S-27: sources.md has no version',
    'FR-024',
    'unhappy (empty set)',
    {
      'NOTICE.md': _fullNotice(),
      'doc/research/sources.md': 'No version in this file.\n',
    },
    checkSrdVersionsAgree,
    ['CLN-FR-024 doc/research/sources.md:1'],
  ),
  _case(
    'S-28: table row and re-wrapped statement',
    'FR-024',
    'happy (boundary: table row; re-wrap)',
    {
      'NOTICE.md': _fullNotice(
        attribution: _wrap(
          attributionStatement,
          9,
        ).replaceFirst('Document', 'Document\n'),
      ),
      'doc/research/sources.md':
          '| System Reference Document | 5.2.1 (released 2025-05-01) |\n',
    },
    checkSrdVersionsAgree,
    [],
  ),
  _case(
    'S-32: affiliate credit in the Scope section, spaced and capitalised',
    'FR-004',
    'unhappy (invalid input: credit outside Attribution)',
    {
      'NOTICE.md': _fullNotice(
        scope:
            'Presented by '
            '${affiliateDenylist.first.spelled(' ').toUpperCase()}.',
      ),
    },
    checkNoAffiliateCredits,
    ['CLN-FR-004 NOTICE.md:5'],
  ),
  _case(
    'S-32: affiliate credit in README.md, hyphenated',
    'FR-004',
    'unhappy (invalid input: credit outside Attribution)',
    {
      'NOTICE.md': _fullNotice(),
      'README.md':
          'Thanks to ${affiliateDenylist.first.spelled('-')} for the '
          'rules.\n',
    },
    checkNoAffiliateCredits,
    ['CLN-FR-004 README.md:1'],
  ),
  _case(
    'S-32: only the statement and the non-endorsement sentence',
    'FR-004',
    'happy',
    {'NOTICE.md': _fullNotice()},
    checkNoAffiliateCredits,
    [],
  ),
  _case(
    'S-35: the licensor named in explanations passes',
    'FR-038 and FR-004',
    'happy (rule interaction: licensor named in explanation)',
    {
      'NOTICE.md': _fullNotice(
        endorsement:
            'No other attribution to Wizards or its parent or affiliates is '
            'included.',
      ),
      'README.md': "Wizards' trademarks are not used.\n",
    },
    (sources) => [
      ...checkCompatibilityWording(sources),
      ...checkNoAffiliateCredits(sources),
    ],
    [],
  ),
  _case(
    'S-19: a list that holds the licensor is clean after the removals',
    'FR-038',
    'happy (rule interaction: mandatory text vs denylist)',
    {'NOTICE.md': _fullNotice()},
    (sources) =>
        checkCompatibilityWording(sources, denylist: _extendedTrademarks),
    [],
  ),
  _case(
    'S-37: sentence start and bold "reviewed"',
    'FR-007 and FR-013',
    'unhappy (boundary: case and emphasis)',
    {
      'NOTICE.md': _fullNotice(
        changes: '**reviewed** by Wizards of the Coast.',
        endorsement: 'Game content is licensed under the MIT License.',
      ),
    },
    (sources) => sortedViolations([
      ...checkGameContentNotMit(sources),
      ...checkChangesEndorsement(sources),
    ]),
    [
      'CLN-FR-013 NOTICE.md:${_changesHeading + 2}',
      'CLN-FR-007 NOTICE.md:${_changesHeading + 4}',
    ],
  ),
  _case(
    'S-37: "not" and plain restructuring text are clean',
    'FR-007 and FR-013',
    'happy',
    {
      'NOTICE.md': _fullNotice(
        changes: 'The rules are restructured here into code and data files.',
        endorsement: 'Game content is not licensed under the MIT License.',
      ),
    },
    (sources) => [
      ...checkGameContentNotMit(sources),
      ...checkChangesEndorsement(sources),
    ],
    [],
  ),
];

void main() {
  group('attribution statement variants', () {
    /// Requirement: per case - doc/specs/content-licensing-and-notice.md
    ///   FR-002, FR-035 and FR-004, table A-01 to A-18: the normalised
    ///   statement is matched verbatim, once, in the Attribution section, and
    ///   no affiliate is credited outside it.
    /// Path: per case
    for (final c in _attributionCases) {
      test('${c.label} [${c.path}]', () {
        expect(_where(c.check(c.sources)), c.expected);
      });
    }
  });

  group('structural requirements', () {
    /// Requirement: per case - doc/specs/content-licensing-and-notice.md
    ///   table S: one violating and one clean fixture per requirement, with
    ///   the exact Violations (path and line).
    /// Path: per case
    for (final c in _structuralCases) {
      test('${c.label} [${c.path}] (${c.requirement})', () {
        expect(_where(c.check(c.sources)), c.expected);
      });
    }
  });

  /// Requirement: doc/specs/content-licensing-and-notice.md FR-005 (S-03) -
  ///   with content present, a Scope that lists only two of the three paths
  ///   is clean here: the keywords are what this check reads, and the path
  ///   list is owned by architecture-guardrails.md FR-079.
  /// Path: happy
  test('S-03: an incomplete path list is clean for the keywords check', () {
    final sources = SourceSet({
      'data/a.json': '{}\n',
      'NOTICE.md': _fullNotice(
        scope:
            'This notice covers **only** the **game content** **bundled** '
            'here: `data/` and `lib/src/content/data/`.',
      ),
    });

    expect(_where(checkScopeSection(sources)), isEmpty);
  });

  /// Requirement: doc/specs/architecture-guardrails.md FR-079 (S-03, same
  ///   fixture) - the incomplete path list is reported by the delegated
  ///   guardrails check, at the Scope heading.
  /// Path: unhappy (state error)
  test('S-03: the incomplete path list yields the FR-079 Violation', () {
    final sources = SourceSet({
      'data/a.json': '{}\n',
      'NOTICE.md': _fullNotice(
        scope:
            'This notice covers **only** the **game content** **bundled** '
            'here: `data/` and `lib/src/content/data/`.',
      ),
    });

    expect(_where(checkNoticePaths(sources)), ['FR-079 NOTICE.md:3']);
  });

  /// Requirement: doc/specs/content-licensing-and-notice.md FR-002, FR-004,
  ///   FR-028 and FR-038 (S-36) - the statement blockquoted in both files is
  ///   found by FR-002 and FR-028 and removed before the FR-004 and FR-038
  ///   scans (normalisation step 2), so even a denylist that holds the bare
  ///   licensor name is clean.
  /// Path: happy
  test('S-36: blockquoted statement with a licensor-bearing denylist', () {
    final sources = SourceSet({
      'data/a.json': '{}\n',
      'NOTICE.md': _fullNotice(attribution: _blockquote(_statementWrapped)),
      'README.md': '${_blockquote(_statementWrapped)}\n',
    });

    expect(
      _where([
        ...checkAttributionStatement(sources),
        ...checkReadmeStatement(sources),
        ...checkNoAffiliateCredits(sources, denylist: _extendedAffiliates),
        ...checkCompatibilityWording(sources, denylist: _extendedTrademarks),
      ]),
      isEmpty,
    );
  });

  /// Requirement: doc/specs/architecture-guardrails.md FR-011 - the same
  ///   files in another order give the same violations.
  /// Path: unhappy (determinism)
  test('the checks are independent of the SourceSet order', () {
    final files = {
      'NOTICE.md': _statusNotice,
      'README.md': 'x\n',
      'data/srd_5_2_1/spells.json': '{}\n',
      'LICENSE': _mitText,
    };
    final forward = [
      for (final check in noticeChecks.values) ...check(SourceSet(files)),
    ];
    final reversed = [
      for (final check in noticeChecks.values)
        ...check(
          SourceSet({
            for (final key in files.keys.toList().reversed) key: files[key]!,
          }),
        ),
    ];

    expect(_where(reversed), _where(forward));
    expect(_where(forward), contains('CLN-FR-011 NOTICE.md:$_statusLine'));
  });

  /// Requirement: doc/specs/content-licensing-and-notice.md section 8 - a
  ///   complete clean repository yields no Violation from any check of this
  ///   file (and of the sibling licensing check files).
  /// Path: happy
  test('a complete clean repository is clean', () {
    final sources = SourceSet({
      'NOTICE.md': _fullNotice(),
      'LICENSE': _mitText,
      'README.md': '$attributionStatement\n\nThis package is 5E compatible.\n',
      'data/srd_5_2_1/spells.json': '{}\n',
      'data/srd_5_2_1/README.md':
          'Attribution: see NOTICE.md in the package root.\n',
      'lib/src/content/data/spells.dart':
          '$embedHeaderLine1\n'
          '$embedHeaderLine2\n'
          'const String spells = r"{}";\n',
      'lib/src/content/data/README.md':
          'Attribution: see NOTICE.md in the package root.\n',
      'test/fixtures/srd/README.md':
          'Attribution: see NOTICE.md in the package root.\n',
      'lib/srd5e.dart': 'library srd5e;\n',
      'pubspec.yaml': 'name: srd5e\ndescription: A pure-Dart rules package.\n',
      '.pubignore': 'AGENTS.md\ndoc/\n',
      'doc/research/sources.md':
          '| System Reference Document | 5.2.1 (released 2025-05-01) |\n',
    });

    for (final entry in [
      ...noticeChecks.entries,
      ...noticeFileChecks.entries,
      ...noticeMarkChecks.entries,
    ]) {
      expect(
        _where(entry.value(sources)),
        isEmpty,
        reason: 'check ${entry.key}',
      );
    }
  });
}
