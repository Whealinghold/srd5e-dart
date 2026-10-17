import '../support/source_set.dart';
import '../support/violation.dart';
import 'notice.dart';

/// The file-placement checks of `doc/specs/content-licensing-and-notice.md`
/// (FR-008, FR-017, FR-027, FR-028, FR-029, FR-036, FR-037): which paths may hold
/// SRD content, which assets may ship, and which notice the covered
/// directories, the README and the embeds carry.
///
/// Pure functions over a [SourceSet]; not registered in the guardrails
/// registry. The statement and normalisation helpers come from `notice.dart`.

/// Every path of [sources] under [prefix] (text, binary and unreadable).
List<String> _pathsUnder(SourceSet sources, String prefix) => [
  for (final path in sourcePaths(sources))
    if (path.startsWith(prefix)) path,
];

/// The last path segment of [path].
String _baseName(String path) => path.substring(path.lastIndexOf('/') + 1);

/// FR-008: bundled source data lives only under `data/srd_5_2_1/` (or
/// `test/fixtures/srd/` for test input). Scoped to `lib/`: any `.json` file
/// is a Violation, and so is any file in `lib/src/content/data/` that is not
/// a `.dart` file, other than the single `README.md` and `.gitkeep`. `tool/`,
/// `doc/` and `example/` are not scanned.
List<Violation> checkDataFileLocations(SourceSet sources) {
  const id = 'CLN-FR-008';
  return sortedViolations([
    for (final path in _pathsUnder(sources, 'lib/'))
      if (path.toLowerCase().endsWith('.json'))
        Violation(
          checkId: id,
          path: path,
          line: 1,
          detail:
              'a .json file under lib/; JSON lives only under '
              'data/srd_5_2_1/ or test/fixtures/srd/',
        )
      else if (path.startsWith('lib/src/content/data/'))
        ..._embedDirForeignFiles(id, path),
  ]);
}

List<Violation> _embedDirForeignFiles(String id, String path) {
  final name = _baseName(path);
  if (name == 'README.md' || name == '.gitkeep' || name.endsWith('.dart')) {
    return const [];
  }
  return [
    Violation(
      checkId: id,
      path: path,
      line: 1,
      detail:
          'lib/src/content/data/ holds .dart files, README.md and '
          '.gitkeep only',
    ),
  ];
}

/// FR-017: no image asset is bundled: no file under `lib/` or `example/` has
/// an image extension (checked on the final extension, case-insensitive).
/// Whether an image is a licensor logo needs review; the extension scan is
/// the mechanical stand-in.
List<Violation> checkNoImageAssets(SourceSet sources) {
  const id = 'CLN-FR-017';
  const extensions = {'png', 'jpg', 'jpeg', 'gif', 'svg', 'webp', 'ico'};
  bool isImage(String path) {
    final name = _baseName(path);
    final dot = name.lastIndexOf('.');
    if (dot < 0) return false;
    return extensions.contains(name.substring(dot + 1).toLowerCase());
  }

  return sortedViolations([
    for (final path in sourcePaths(sources))
      if ((path.startsWith('lib/') || path.startsWith('example/')) &&
          isImage(path))
        Violation(
          checkId: id,
          path: path,
          line: 1,
          detail:
              'an image asset is bundled; any image needs an explicit '
              'review decision',
        ),
  ]);
}

/// The directories FR-027 judges, each with its own README: the source data
/// directory (`data/srd_5_2_1/`, not the whole covered root `data/`), the
/// embed directory and the fixture directory.
const List<String> readmeDirectories = [
  'data/srd_5_2_1/',
  'lib/src/content/data/',
  'test/fixtures/srd/',
];

/// FR-027: each of the three directories holding a file other than
/// `.gitkeep` and `README.md` contains a `README.md` carrying the attribution
/// statement or the pointer sentence, independently of the other directories.
List<Violation> checkDirectoryReadmes(SourceSet sources) {
  const id = 'CLN-FR-027';
  final violations = <Violation>[];
  for (final directory in readmeDirectories) {
    final hasContent = sourcePaths(sources).any(
      (path) =>
          path.startsWith(directory) &&
          _baseName(path) != '.gitkeep' &&
          _baseName(path) != 'README.md',
    );
    if (!hasContent) continue;
    final readme = '${directory}README.md';
    final text = sources.files[readme];
    if (text == null) {
      violations.add(
        Violation(
          checkId: id,
          path: readme,
          line: 1,
          detail: 'the directory holds content but has no README.md',
        ),
      );
      continue;
    }
    final normalised = normalise(text).text;
    if (!normalised.contains(attributionStatement) &&
        !normalised.contains(attributionPointer)) {
      violations.add(
        Violation(
          checkId: id,
          path: readme,
          line: 1,
          detail:
              'the README carries neither the attribution statement nor '
              'the pointer sentence',
        ),
      );
    }
  }
  return sortedViolations(violations);
}

/// FR-028: while bundled content is present, `README.md` contains the
/// attribution statement (the pub.dev page renders the README, not
/// `NOTICE.md`).
List<Violation> checkReadmeStatement(SourceSet sources) {
  const id = 'CLN-FR-028';
  if (!bundledContentPresent(sources)) return const [];
  final readme = sources.files['README.md'];
  if (readme != null && normalise(readme).text.contains(attributionStatement)) {
    return const [];
  }
  return const [
    Violation(
      checkId: id,
      path: 'README.md',
      line: 1,
      detail:
          'the README does not contain the attribution statement while '
          'bundled content is present',
    ),
  ];
}

bool _startsWithHeader(String text) {
  final lines = text.split('\n');
  return lines.length >= 2 &&
      lines[0] == embedHeaderLine1 &&
      lines[1] == embedHeaderLine2;
}

/// FR-029: every `.dart` file in `lib/src/content/data/` starts with the
/// two-line embed header, verbatim.
List<Violation> checkEmbedHeaders(SourceSet sources) {
  const id = 'CLN-FR-029';
  return sortedViolations([
    for (final path in sources.dartPaths('lib/src/content/data/'))
      if (!_startsWithHeader(sources.files[path]!))
        Violation(
          checkId: id,
          path: path,
          line: 1,
          detail:
              'the file does not start with the two-line attribution '
              'header',
        ),
  ]);
}

/// FR-037: a `.dart` file under `lib/` whose first two lines are the FR-029
/// header lives in `lib/src/content/data/`. Only `lib/` is scanned, so the
/// generator's string literal in `tool/` and a golden fixture under `test/`
/// are not hits.
List<Violation> checkHeaderedFileLocation(SourceSet sources) {
  const id = 'CLN-FR-037';
  return sortedViolations([
    for (final path in sources.dartPaths('lib/'))
      if (!path.startsWith('lib/src/content/data/') &&
          _startsWithHeader(sources.files[path]!))
        Violation(
          checkId: id,
          path: path,
          line: 1,
          detail:
              'a file with the embed header lives outside '
              'lib/src/content/data/',
        ),
  ]);
}

/// FR-036: `LICENSE` does not mention the bundled game content, the SRD or
/// Creative Commons: it is the MIT text for the code only.
List<Violation> checkLicenseIsCodeOnly(SourceSet sources) {
  const id = 'CLN-FR-036';
  final license = sources.files['LICENSE'];
  if (license == null) return const [];
  final doc = normalise(license);
  final keywords = keywordIndexed(doc.text);
  const phrases = ['game content', 'srd', 'creative commons'];
  int? first;
  String? phrase;
  for (final candidate in phrases) {
    final at = keywords.text.indexOf(candidate);
    if (at < 0) continue;
    if (first == null || keywords.sources[at] < first) {
      first = keywords.sources[at];
      phrase = candidate;
    }
  }
  if (first == null) return const [];
  return [
    Violation(
      checkId: id,
      path: 'LICENSE',
      line: doc.lineAt(first),
      detail:
          'LICENSE mentions "$phrase"; it is the MIT text for the code '
          'only',
    ),
  ];
}

/// The check functions of this file by `CLN-` id; not registered in the
/// guardrails registry.
const Map<String, List<Violation> Function(SourceSet)> noticeFileChecks = {
  'CLN-FR-008': checkDataFileLocations,
  'CLN-FR-017': checkNoImageAssets,
  'CLN-FR-027': checkDirectoryReadmes,
  'CLN-FR-028': checkReadmeStatement,
  'CLN-FR-029': checkEmbedHeaders,
  'CLN-FR-036': checkLicenseIsCodeOnly,
  'CLN-FR-037': checkHeaderedFileLocation,
};
