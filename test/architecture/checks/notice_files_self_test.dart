import 'package:test/test.dart';

import '../support/source_set.dart';
import '../support/violation.dart';
import 'notice.dart';
import 'notice_files.dart';

const String _spec = 'doc/specs/content-licensing-and-notice.md';

List<String> _where(List<Violation> violations) => [
  for (final v in violations) '${v.checkId} ${v.path}:${v.line}',
];

/// The two embed header lines, as a file body.
String _embed(String body) => '$embedHeaderLine1\n$embedHeaderLine2\n\n$body';

typedef _Case = ({
  String label,
  String requirement,
  String path,
  SourceSet sources,
  List<Violation> Function(SourceSet sources) check,
  List<String> expected,
});

_Case _case(
  String label,
  String requirement,
  String path,
  SourceSet sources,
  List<Violation> Function(SourceSet) check,
  List<String> expected,
) => (
  label: label,
  requirement: '$_spec $requirement',
  path: path,
  sources: sources,
  check: check,
  expected: expected,
);

SourceSet _withBinary(Map<String, String> files, List<String> binaryPaths) =>
    SourceSet(files, binaryPaths: binaryPaths);

final List<_Case> _cases = [
  _case(
    'S-10: LICENSE mentions Creative Commons',
    'FR-036',
    'unhappy (rule interaction)',
    SourceSet({
      'LICENSE':
          'MIT License\n\nThe game content is under the Creative '
          'Commons Attribution 4.0 International License.\n',
    }),
    checkLicenseIsCodeOnly,
    ['CLN-FR-036 LICENSE:3'],
  ),
  _case(
    'S-10: plain MIT text',
    'FR-036',
    'happy',
    SourceSet({
      'LICENSE':
          'MIT License\n\nPermission is hereby granted, free of '
          'charge.\n',
    }),
    checkLicenseIsCodeOnly,
    [],
  ),
  _case(
    'S-11: JSON under lib/, and foreign files in the embed directory',
    'FR-008',
    'unhappy (state error)',
    SourceSet({
      'data/srd_5_2_1/spells.json': '{}\n',
      'lib/src/content/data/spells.dart': _embed('const x = 1;\n'),
      'lib/src/other/spells.json': '{}\n',
      'lib/src/content/data/spells.json': '{}\n',
      'lib/src/content/data/notes.txt': 'x\n',
    }),
    checkDataFileLocations,
    [
      'CLN-FR-008 lib/src/content/data/notes.txt:1',
      'CLN-FR-008 lib/src/content/data/spells.json:1',
      'CLN-FR-008 lib/src/other/spells.json:1',
    ],
  ),
  _case(
    'S-11: JSON only under data/, embed-dir README and .gitkeep exempt',
    'FR-008',
    'happy',
    SourceSet({
      'data/srd_5_2_1/spells.json': '{}\n',
      'lib/src/content/data/spells.dart': _embed('const x = 1;\n'),
      'lib/src/content/data/README.md':
          'Attribution: see NOTICE.md in the '
          'package root.\n',
      'lib/src/content/data/.gitkeep': '',
      'tool/x.json': '{}\n',
    }),
    checkDataFileLocations,
    [],
  ),
  _case(
    'S-12: a headed file outside lib/src/content/data/',
    'FR-037',
    'unhappy (state error)',
    SourceSet({
      'lib/src/content/x.dart': _embed('const x = 1;\n'),
      'lib/src/content/data/y.dart': _embed('const y = 2;\n'),
      'tool/x.dart': _embed('const t = 3;\n'),
      'test/tool/golden.dart': _embed('const g = 4;\n'),
    }),
    checkHeaderedFileLocation,
    ['CLN-FR-037 lib/src/content/x.dart:1'],
  ),
  _case(
    'S-12: headed files in the embed directory, tool/ and test/ are clean',
    'FR-037',
    'happy',
    SourceSet({
      'lib/src/content/data/y.dart': _embed('const y = 2;\n'),
      'tool/x.dart': _embed('const t = 3;\n'),
      'test/tool/golden.dart': _embed('const g = 4;\n'),
    }),
    checkHeaderedFileLocation,
    [],
  ),
  _case(
    'S-22: an SVG in example/',
    'FR-017',
    'unhappy (missing content)',
    SourceSet({'example/a.svg': '<svg></svg>\n'}),
    checkNoImageAssets,
    ['CLN-FR-017 example/a.svg:1'],
  ),
  _case(
    'S-22: no image paths; doc/x.svg is not scanned',
    'FR-017',
    'happy',
    SourceSet({'doc/x.svg': '<svg></svg>\n'}),
    checkNoImageAssets,
    [],
  ),
  _case(
    'S-23: binary images under lib/ and example/, every extension',
    'FR-017',
    'unhappy (missing content)',
    _withBinary({}, [
      'lib/src/logo.PNG',
      'example/a.jpg',
      'lib/a.gif',
      'lib/a.webp',
      'lib/a.ico',
    ]),
    checkNoImageAssets,
    [
      'CLN-FR-017 example/a.jpg:1',
      'CLN-FR-017 lib/a.gif:1',
      'CLN-FR-017 lib/a.ico:1',
      'CLN-FR-017 lib/a.webp:1',
      'CLN-FR-017 lib/src/logo.PNG:1',
    ],
  ),
  _case(
    'S-23: a binary image under doc/ is not scanned',
    'FR-017',
    'happy',
    _withBinary({}, ['doc/x.png']),
    checkNoImageAssets,
    [],
  ),
  _case(
    'S-29: content without a directory README',
    'FR-027',
    'unhappy (state error)',
    SourceSet({'data/srd_5_2_1/spells.json': '{}\n'}),
    checkDirectoryReadmes,
    ['CLN-FR-027 data/srd_5_2_1/README.md:1'],
  ),
  _case(
    'S-29: a README without statement and pointer',
    'FR-027',
    'unhappy (state error)',
    SourceSet({
      'lib/src/content/data/spells.dart': _embed('const x = 1;\n'),
      'lib/src/content/data/README.md': 'Nothing to attribute.\n',
    }),
    checkDirectoryReadmes,
    ['CLN-FR-027 lib/src/content/data/README.md:1'],
  ),
  _case(
    'S-29: a fixture alone requires the fixture README',
    'FR-027',
    'unhappy (state error)',
    SourceSet({'test/fixtures/srd/x.json': '{}\n'}),
    checkDirectoryReadmes,
    ['CLN-FR-027 test/fixtures/srd/README.md:1'],
  ),
  _case(
    'S-29: READMEs with the pointer sentence',
    'FR-027',
    'happy',
    SourceSet({
      'data/srd_5_2_1/spells.json': '{}\n',
      'lib/src/content/data/spells.dart': _embed('const x = 1;\n'),
      'test/fixtures/srd/x.json': '{}\n',
      'data/srd_5_2_1/README.md':
          'Attribution: see NOTICE.md in the package '
          'root.\n',
      'lib/src/content/data/README.md':
          'Attribution: see NOTICE.md in the '
          'package root.\n',
      'test/fixtures/srd/README.md':
          'Attribution: see NOTICE.md in the '
          'package root.\n',
    }),
    checkDirectoryReadmes,
    [],
  ),
  _case(
    'S-30: content present, README without the statement',
    'FR-028',
    'unhappy (state error)',
    SourceSet({
      'data/srd_5_2_1/spells.json': '{}\n',
      'README.md': 'A package without the statement.\n',
    }),
    checkReadmeStatement,
    ['CLN-FR-028 README.md:1'],
  ),
  _case(
    'S-30: README with the statement',
    'FR-028',
    'happy',
    SourceSet({
      'data/srd_5_2_1/spells.json': '{}\n',
      'README.md': '$attributionStatement\n',
    }),
    checkReadmeStatement,
    [],
  ),
  _case(
    'S-31: an embed whose first line names the old source path',
    'FR-029',
    'unhappy (state error)',
    SourceSet({
      'lib/src/content/data/x.dart':
          '// GENERATED from '
          'lib/src/content/data/. Contains SRD 5.2.1 content.\n'
          '$embedHeaderLine2\n'
          'const x = 1;\n',
    }),
    (sources) => [
      ...checkEmbedHeaders(sources),
      ...checkHeaderedFileLocation(sources),
    ],
    ['CLN-FR-029 lib/src/content/data/x.dart:1'],
  ),
  _case(
    'S-31: an embed with no header',
    'FR-029',
    'unhappy (state error)',
    SourceSet({'lib/src/content/data/x.dart': 'const x = 1;\n'}),
    (sources) => [
      ...checkEmbedHeaders(sources),
      ...checkHeaderedFileLocation(sources),
    ],
    ['CLN-FR-029 lib/src/content/data/x.dart:1'],
  ),
  _case(
    'S-31: the exact header, reported once',
    'FR-029',
    'happy',
    SourceSet({'lib/src/content/data/x.dart': _embed('const x = 1;\n')}),
    (sources) => [
      ...checkEmbedHeaders(sources),
      ...checkHeaderedFileLocation(sources),
    ],
    [],
  ),
];

void main() {
  group('file placement and carried notice', () {
    /// Requirement: per case - doc/specs/content-licensing-and-notice.md
    ///   table S (S-10, S-11, S-12, S-22, S-23, S-29, S-30, S-31): one
    ///   violating and one clean fixture per requirement, with the exact
    ///   Violations (path and line).
    /// Path: per case
    for (final c in _cases) {
      test('${c.label} [${c.path}] (${c.requirement})', () {
        expect(_where(c.check(c.sources)), c.expected);
      });
    }
  });

  /// Requirement: doc/specs/content-licensing-and-notice.md FR-027 - the
  ///   per-directory rule is independent: a fixture alone in one directory
  ///   requires that directory's README even with no data or embed present.
  /// Path: unhappy (state error)
  test('S-29: the directories are judged independently', () {
    final sources = SourceSet({
      'test/fixtures/srd/a.json': '{}\n',
      'test/fixtures/srd/README.md':
          'Attribution: see NOTICE.md in the '
          'package root.\n',
    });

    expect(_where(checkDirectoryReadmes(sources)), isEmpty);
  });

  /// Requirement: doc/specs/architecture-guardrails.md FR-011 - the same
  ///   files in another order give the same violations.
  /// Path: unhappy (determinism)
  test('the checks are independent of the SourceSet order', () {
    final files = {
      'lib/src/content/data/x.json': '{}\n',
      'lib/src/other/y.json': '{}\n',
      'example/a.svg': '<svg></svg>\n',
    };
    List<Violation> run(Map<String, String> order) => sortedViolations([
      for (final check in noticeFileChecks.values) ...check(SourceSet(order)),
    ]);
    final forward = run(files);
    final reversed = run({
      for (final key in files.keys.toList().reversed) key: files[key]!,
    });

    expect(_where(reversed), _where(forward));
    expect(_where(forward), [
      'CLN-FR-028 README.md:1',
      'CLN-FR-017 example/a.svg:1',
      'CLN-FR-027 lib/src/content/data/README.md:1',
      'CLN-FR-008 lib/src/content/data/x.json:1',
      'CLN-FR-008 lib/src/other/y.json:1',
    ]);
  });
}
