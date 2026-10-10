import '../support/constants.dart';
import '../support/source_set.dart';
import '../support/violation.dart';

/// Consumer-name checks FR-025, FR-026 and FR-068 of
/// `doc/specs/architecture-guardrails.md` (section 4.2).
///
/// Every function is pure: it reads a [SourceSet] and returns [Violation]s.
/// The names come from [consumerDenylist] and [allDeniedNames] (fragments
/// joined at run time, FR-068), so nothing here spells one. A Violation's
/// detail names the list entry by position, never by name. No inline
/// suppression exists (FR-009).

/// The files that hold the denylists and so must not spell a name (FR-068):
/// the constants and their test.
const List<String> denylistSourcePaths = [
  'test/architecture/support/constants.dart',
  'test/architecture/support/constants_test.dart',
];

/// The 1-based positions in [list] of the entries that [text] mentions.
List<int> _hits(String text, List<DeniedName> list) => [
  for (var i = 0; i < list.length; i++)
    if (list[i].appearsIn(text)) i + 1,
];

/// Every path of [sources] that [include] accepts: files, then the paths of
/// binary files (path only, no content to scan).
List<String> _paths(SourceSet sources, bool Function(String) include) =>
    [...sources.files.keys, ...sources.binaryPaths].where(include).toList()
      ..sort();

/// Violations of [id] for [path]: one for a path that names an entry, and one
/// per line and entry for content. [skipLine] drops a line from the scan.
List<Violation> _scanFile(
  SourceSet sources,
  String path, {
  required String id,
  required List<DeniedName> list,
  required String listName,
  bool Function(String line)? skipLine,
}) {
  final violations = <Violation>[];
  for (final entry in _hits(path, list)) {
    violations.add(
      Violation(
        checkId: id,
        path: path,
        line: 1,
        detail: 'the path names $listName entry #$entry',
      ),
    );
  }
  final text = sources.files[path];
  if (text == null) return violations;
  final lines = text.split('\n');
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (skipLine != null && skipLine(line)) continue;
    for (final entry in _hits(line, list)) {
      violations.add(
        Violation(
          checkId: id,
          path: path,
          line: i + 1,
          detail: 'the line names $listName entry #$entry',
        ),
      );
    }
  }
  return violations;
}

/// FR-025: no file under `lib/` (path, comment or code) contains a name of
/// [consumerDenylist], case-insensitively and ignoring `-`, `_` and spaces.
List<Violation> checkNoConsumerNamesInLib(SourceSet sources) =>
    sortedViolations([
      for (final path in _paths(sources, (p) => p.startsWith('lib/')))
        ..._scanFile(
          sources,
          path,
          id: 'FR-025',
          list: consumerDenylist,
          listName: 'consumer denylist',
        ),
    ]);

/// FR-026: no file of the SourceSet outside `lib/` (path or content) contains
/// a name of [consumerDenylist], except [consumerScanExemptFiles] and the
/// `repository:` line of [consumerScanExemptLineFile].
List<Violation> checkNoConsumerNamesOutsideLib(SourceSet sources) =>
    sortedViolations([
      for (final path in _paths(
        sources,
        (p) => !p.startsWith('lib/') && !consumerScanExemptFiles.contains(p),
      ))
        ..._scanFile(
          sources,
          path,
          id: 'FR-026',
          list: consumerDenylist,
          listName: 'consumer denylist',
          skipLine: path == consumerScanExemptLineFile
              ? consumerScanExemptLine.hasMatch
              : null,
        ),
    ]);

/// FR-068: the denylist source files ([denylistSourcePaths]) contain no name
/// of any list in `constants.dart` ([allDeniedNames]: consumer, trademark and
/// affiliate) in plain text. A file absent from the SourceSet is skipped.
List<Violation> checkDenylistSourceHoldsNoNames(SourceSet sources) =>
    sortedViolations([
      for (final path in denylistSourcePaths.where(sources.files.containsKey))
        ..._scanFile(
          sources,
          path,
          id: 'FR-068',
          list: allDeniedNames,
          listName: 'denylist',
        ),
    ]);

/// The check function per id, for the registry (`registry.dart`).
const Map<String, List<Violation> Function(SourceSet)> consumerNamesChecks = {
  'FR-025': checkNoConsumerNamesInLib,
  'FR-026': checkNoConsumerNamesOutsideLib,
  'FR-068': checkDenylistSourceHoldsNoNames,
};

/// One minimal violating fixture per check id; the registry merges this map
/// into its own (`registry.dart`, FR-005). The name is assembled at run time.
final Map<String, SourceSet Function()> consumerNamesViolatingFixtures = {
  'FR-025': () =>
      SourceSet({'lib/src/a.dart': '// ${consumerDenylist.first.name}\n'}),
  'FR-026': () =>
      SourceSet({'doc/notes.md': '${consumerDenylist.first.name}\n'}),
  'FR-068': () => SourceSet({
    denylistSourcePaths.first: 'const x = "${allDeniedNames.first.name}";\n',
  }),
};
