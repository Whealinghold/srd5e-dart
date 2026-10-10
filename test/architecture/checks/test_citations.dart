import '../support/markdown_tables.dart';
import '../support/source_set.dart';
import '../support/spec_ids.dart';
import '../support/test_scan.dart';
import '../support/violation.dart';

/// Test-citation checks FR-049 to FR-056 of
/// `doc/specs/architecture-guardrails.md` (section 4.4, `testing.md` §5, §9).
///
/// Every function is pure: it reads a [SourceSet] and returns [Violation]s.
/// The comment checks (FR-049 to FR-053) share one analysis of the files under
/// `test/`; each check function returns only its own id.

const String _testPrefix = 'test/';
const String _architectureTestPrefix = 'test/architecture/';
const String _specsPrefix = 'doc/specs/';

/// The Status values a spec may carry (FR-056).
const Set<String> specStatuses = {'draft', 'accepted', 'implemented'};

final RegExp _perCase = RegExp(r'^per case\b');
final RegExp _noneWithReason = RegExp(r'^none\s*[-–—]\s*\S');
final RegExp _noneWord = RegExp(r'^none\b');
final RegExp _pathValue = RegExp(
  r'^(?:happy|unhappy \(\s*[^)\s][^)]*\)|per case)$',
);
final RegExp _notCovered = RegExp(
  r'^Deliberately not covered:\s*(FR-\d+)\s*[-–—]\s*(\S.*)$',
);

bool _carriesRequirement(DocBlock? block) =>
    block != null && (block.hasField('Requirement') || block.hasField('Rule'));

bool _isPerCase(DocBlock? block) {
  final value = block?.fieldValue('Requirement');
  return value != null && _perCase.hasMatch(value);
}

/// Whether the per-case comment [block] sits above a loop that holds a test
/// or group, or above a group whose body holds such a loop (FR-052).
bool _perCaseTargetIsValid(TestScan scan, DocBlock block) {
  for (final loop in scan.loops) {
    if (identical(loop.comment, block) && scan.loopHasTest(loop)) return true;
  }
  for (final call in scan.calls) {
    if (call.kind == TestCallKind.group &&
        identical(call.comment, block) &&
        scan.loopsInside(call).isNotEmpty) {
      return true;
    }
  }
  return false;
}

final Expando<List<Violation>> _commentCache = Expando<List<Violation>>();

/// All violations of FR-049 to FR-053 in the Dart files under `test/`.
List<Violation> _commentViolations(SourceSet sources) {
  final cached = _commentCache[sources];
  if (cached != null) return cached;
  final violations = <Violation>[];
  for (final path in sources.dartPaths(_testPrefix)) {
    final scan = scanTests(sources.lexed(path));
    final architecture = path.startsWith(_architectureTestPrefix);

    for (final block in scan.blocks) {
      final requirement = block.fieldValue('Requirement');
      if (requirement == null) continue;
      final line = block.fieldLine('Requirement')!;
      final perCase = _perCase.hasMatch(requirement);

      if (requirement.isEmpty) {
        violations.add(
          Violation(
            checkId: 'FR-050',
            path: path,
            line: line,
            detail: 'An empty "Requirement:" says nothing; cite a requirement.',
          ),
        );
      } else if (_noneWord.hasMatch(requirement) &&
          !_noneWithReason.hasMatch(requirement)) {
        violations.add(
          Violation(
            checkId: 'FR-050',
            path: path,
            line: line,
            detail:
                '"Requirement: none" needs a reason: "Requirement: none - '
                '<reason>".',
          ),
        );
      }

      final pathValue = block.fieldValue('Path');
      if (pathValue == null) {
        violations.add(
          Violation(
            checkId: 'FR-053',
            path: path,
            line: line,
            detail:
                'A "Requirement:" comment needs a "Path:" line: happy, '
                'unhappy (<kind>) or per case.',
          ),
        );
      } else if (!_pathValue.hasMatch(pathValue)) {
        violations.add(
          Violation(
            checkId: 'FR-053',
            path: path,
            line: block.fieldLine('Path')!,
            detail:
                '"Path: $pathValue" must be happy, unhappy (<kind>) with a '
                'kind, or per case.',
          ),
        );
      } else if (pathValue == 'per case' && !perCase) {
        violations.add(
          Violation(
            checkId: 'FR-053',
            path: path,
            line: block.fieldLine('Path')!,
            detail:
                '"Path: per case" is valid only with "Requirement: per case".',
          ),
        );
      }

      if (perCase && !_perCaseTargetIsValid(scan, block)) {
        violations.add(
          Violation(
            checkId: 'FR-052',
            path: path,
            line: line,
            detail:
                '"Requirement: per case" must sit above a loop that holds a '
                'test or group, or above a group whose body holds one.',
          ),
        );
      }
    }

    for (final call in scan.calls) {
      if (_carriesRequirement(call.comment)) continue;
      final name = call.kind == TestCallKind.test ? 'test' : 'group';
      if (call.loops.isNotEmpty) {
        DocBlock? loopComment;
        for (final loop in call.loops) {
          if (_carriesRequirement(loop.comment)) {
            loopComment = loop.comment;
            break;
          }
        }
        if (loopComment != null) {
          if (!_isPerCase(loopComment)) {
            violations.add(
              Violation(
                checkId: 'FR-051',
                path: path,
                line: call.line,
                detail:
                    'A $name inside a loop is covered only by '
                    '"Requirement: per case" on the loop; the loop comment '
                    'says something else.',
              ),
            );
          }
          continue;
        }
        if (call.groups.any((g) => _isPerCase(g.comment))) continue;
      }
      if (architecture) continue;
      violations.add(
        Violation(
          checkId: 'FR-049',
          path: path,
          line: call.line,
          detail:
              'This $name has no "Requirement:" or "Rule:" doc comment '
              'directly above it.',
        ),
      );
    }
  }
  return _commentCache[sources] = sortedViolations(violations);
}

List<Violation> _only(String id, List<Violation> all) => [
  for (final v in all)
    if (v.checkId == id) v,
];

/// FR-049: every `group(` and `test(` outside `test/architecture/` is
/// directly preceded by a doc comment with a `Requirement:` or `Rule:` line,
/// unless it sits in a loop covered by FR-051.
List<Violation> checkTestsHaveRequirementComment(SourceSet sources) =>
    _only('FR-049', _commentViolations(sources));

/// FR-050: `Requirement: none` carries a reason after the dash, and a
/// `Requirement:` line is never empty.
List<Violation> checkNoneHasReason(SourceSet sources) =>
    _only('FR-050', _commentViolations(sources));

/// FR-051: a test or group inside a loop is covered by the nearest enclosing
/// loop comment, which must say `Requirement: per case`.
List<Violation> checkLoopCommentIsPerCase(SourceSet sources) =>
    _only('FR-051', _commentViolations(sources));

/// FR-052: `Requirement: per case` appears only above a loop that holds a
/// test or group, or above a group whose body holds such a loop.
List<Violation> checkPerCaseOnlyOnLoops(SourceSet sources) =>
    _only('FR-052', _commentViolations(sources));

/// FR-053: a `Requirement:` comment carries a valid `Path:` line.
List<Violation> checkRequirementHasPath(SourceSet sources) =>
    _only('FR-053', _commentViolations(sources));

/// The spec files of [sources]: `doc/specs/<name>.md`, not starting with `_`.
List<String> specFilePaths(SourceSet sources) => [
  for (final path in sources.paths(prefix: _specsPrefix, suffix: '.md'))
    if (!path.substring(_specsPrefix.length).contains('/') &&
        !path.substring(_specsPrefix.length).startsWith('_'))
      path,
];

String _specName(String path) =>
    path.substring(_specsPrefix.length, path.length - '.md'.length);

/// FR-054: every citation in a test names an existing spec and ids present in
/// that spec's requirements table; a range and a moved id are Violations.
List<Violation> checkCitationsResolve(SourceSet sources) {
  const id = 'FR-054';
  final violations = <Violation>[];
  final specs = <String, SpecRequirements?>{};
  SpecRequirements? requirementsOf(String specPath) =>
      specs.putIfAbsent(specPath, () {
        final text = sources.files[specPath];
        return text == null ? null : parseSpecRequirements(text);
      });

  for (final path in sources.dartPaths(_testPrefix)) {
    for (final text in parseRequirementTexts(sources.files[path]!)) {
      for (final citation in text.citations) {
        final spec = requirementsOf(citation.specPath);
        if (spec == null) {
          violations.add(
            Violation(
              checkId: id,
              path: path,
              line: citation.line,
              detail: 'Cites ${citation.specPath}, which does not exist.',
            ),
          );
          continue;
        }
        for (final range in citation.ranges) {
          violations.add(
            Violation(
              checkId: id,
              path: path,
              line: citation.line,
              detail:
                  'Cites the range "$range" of ${citation.specPath}; name '
                  'each id.',
            ),
          );
        }
        final inRange = {
          for (final range in citation.ranges)
            ...RegExp(r'FR-\d+').allMatches(range).map((m) => m.group(0)!),
        };
        for (final cited in citation.ids) {
          if (inRange.contains(cited)) continue;
          if (spec.movedIds.contains(cited)) {
            violations.add(
              Violation(
                checkId: id,
                path: path,
                line: citation.line,
                detail:
                    'Cites $cited of ${citation.specPath}, which moved to '
                    'another spec.',
              ),
            );
          } else if (!spec.ids.contains(cited)) {
            violations.add(
              Violation(
                checkId: id,
                path: path,
                line: citation.line,
                detail:
                    'Cites $cited, which is not in the requirements table '
                    'of ${citation.specPath}.',
              ),
            );
          }
        }
      }
    }
  }
  return sortedViolations(violations);
}

/// The Status row of a spec header: its value and 1-based line, or null.
({String value, int line})? _statusOf(String markdown) {
  final tables = parseMarkdownTables(markdown);
  if (tables.isEmpty) return null;
  for (final row in tables.first.rows) {
    final key = row.cell(0);
    if (key == null || stripBackticks(key).trim() != 'Status') continue;
    return (value: stripBackticks(row.cell(1) ?? '').trim(), line: row.line);
  }
  return null;
}

/// The ids a spec's section 8 lists on a "Deliberately not covered" line with
/// a non-empty reason after the dash (FR-055).
Set<String> _deliberatelyNotCovered(String markdown) {
  final ids = <String>{};
  var inSection8 = false;
  var fenced = false;
  for (final line in markdown.split('\n')) {
    if (line.trimLeft().startsWith('```')) fenced = !fenced;
    if (fenced) continue;
    if (line.startsWith('## ')) {
      inSection8 = RegExp(r'^##\s+8\.').hasMatch(line);
      continue;
    }
    if (!inSection8) continue;
    final match = _notCovered.firstMatch(line.trimRight());
    if (match != null) ids.add(match.group(1)!);
  }
  return ids;
}

/// FR-055: for every spec whose Status is `implemented`, every requirement id
/// is cited by at least one test, unless it is a moved id or section 8 lists
/// it as deliberately not covered with a reason.
List<Violation> checkImplementedSpecsAreCovered(SourceSet sources) {
  const id = 'FR-055';
  final violations = <Violation>[];
  final cited = <String, Set<String>>{};
  for (final path in sources.dartPaths(_testPrefix)) {
    for (final text in parseRequirementTexts(sources.files[path]!)) {
      for (final citation in text.citations) {
        cited.putIfAbsent(citation.specName, () => {}).addAll(citation.ids);
      }
    }
  }
  for (final path in specFilePaths(sources)) {
    final markdown = sources.files[path]!;
    if (_statusOf(markdown)?.value != 'implemented') continue;
    final skipped = _deliberatelyNotCovered(markdown);
    final covered = cited[_specName(path)] ?? const <String>{};
    for (final requirement in parseSpecRequirements(markdown).requirements) {
      if (requirement.moved ||
          covered.contains(requirement.id) ||
          skipped.contains(requirement.id)) {
        continue;
      }
      violations.add(
        Violation(
          checkId: id,
          path: path,
          line: requirement.line,
          detail:
              '${requirement.id} is not cited by any test; add a test or list '
              'it under "Deliberately not covered: ${requirement.id} - '
              '<reason>" in section 8.',
        ),
      );
    }
  }
  return sortedViolations(violations);
}

/// FR-056: a spec's Status value is `draft`, `accepted` or `implemented`.
List<Violation> checkSpecStatusValue(SourceSet sources) {
  const id = 'FR-056';
  final violations = <Violation>[];
  for (final path in specFilePaths(sources)) {
    final status = _statusOf(sources.files[path]!);
    if (status == null || specStatuses.contains(status.value)) continue;
    violations.add(
      Violation(
        checkId: id,
        path: path,
        line: status.line,
        detail:
            'Status "${status.value}" must be one of '
            '${(specStatuses.toList()..sort()).join(', ')}.',
      ),
    );
  }
  return sortedViolations(violations);
}

/// The check function per id, for the registry (`registry.dart`, FR-005).
const Map<String, List<Violation> Function(SourceSet)> testCitationChecks = {
  'FR-049': checkTestsHaveRequirementComment,
  'FR-050': checkNoneHasReason,
  'FR-051': checkLoopCommentIsPerCase,
  'FR-052': checkPerCaseOnlyOnLoops,
  'FR-053': checkRequirementHasPath,
  'FR-054': checkCitationsResolve,
  'FR-055': checkImplementedSpecsAreCovered,
  'FR-056': checkSpecStatusValue,
};

const String _fixtureSpec =
    '# X\n\n| | |\n|---|---|\n| Status | draft |\n\n'
    '## 4. Requirements\n\n| Id | Requirement |\n|---|---|\n'
    '| FR-1 | a |\n| FR-2 | b |\n';

String _implementedSpec(String rows, String section8) =>
    '# A\n\n| | |\n|---|---|\n| Status | implemented |\n\n'
    '## 4. Requirements\n\n| Id | Requirement |\n|---|---|\n$rows\n'
    '## 8. Test plan\n\n$section8\n';

SourceSet _testFile(String body, {String path = 'test/a_test.dart'}) =>
    SourceSet({path: body, 'doc/specs/x.md': _fixtureSpec});

/// One minimal violating fixture per check id; the registry merges this map
/// into its own (FR-005).
final Map<String, SourceSet Function()> testCitationViolatingFixtures = {
  'FR-049': () => _testFile('test("t", () {});\n'),
  'FR-050': () =>
      _testFile('/// Requirement: none\n/// Path: happy\ntest("t", () {});\n'),
  'FR-051': () => _testFile(
    '/// Requirement: doc/specs/x.md FR-1 - a\n/// Path: happy\n'
    'for (final c in cases) {\n  test("t", () {});\n}\n',
  ),
  'FR-052': () => _testFile(
    '/// Requirement: per case\n/// Path: per case\ntest("t", () {});\n',
  ),
  'FR-053': () =>
      _testFile('/// Requirement: none - reason\ntest("t", () {});\n'),
  'FR-054': () => _testFile(
    '/// Requirement: doc/specs/x.md FR-99 - a\n/// Path: happy\n'
    'test("t", () {});\n',
  ),
  'FR-055': () => SourceSet({
    'doc/specs/a.md': _implementedSpec('| FR-1 | a |\n', 'none\n'),
  }),
  'FR-056': () => SourceSet({
    'doc/specs/a.md': _fixtureSpec.replaceFirst('draft', 'finished'),
  }),
};
