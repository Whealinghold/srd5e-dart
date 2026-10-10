import 'package:test/test.dart';

import '../support/source_set.dart';
import '../support/violation.dart';
import 'embedded_content.dart';

const String _lib = 'lib/src/content/data/a.dart';

List<String> _where(List<Violation> violations) => [
  for (final v in violations) '${v.checkId} ${v.path}:${v.line}',
];

typedef _Case = ({
  String label,
  String path,
  Map<String, String> files,
  EmbeddedLibraryGenerator? generator,
  List<String> expected,
});

final List<_Case> _cases = [
  (
    label: 'identical output',
    path: 'happy',
    files: {'data/a.json': 'x\n', _lib: 'x\n'},
    generator: stubEmbeddedGenerator,
    expected: [],
  ),
  (
    label: 'one differing byte on the second line',
    path: 'unhappy (state error)',
    files: {'data/a.json': 'x\ny\n', _lib: 'x\nz\n'},
    generator: stubEmbeddedGenerator,
    expected: ['FR-078 $_lib:2'],
  ),
  (
    label: 'a missing library',
    path: 'unhappy (state error)',
    files: {'data/a.json': 'x\n', 'lib/src/content/data/.gitkeep': ''},
    generator: stubEmbeddedGenerator,
    expected: ['FR-078 $_lib:1'],
  ),
  (
    label: 'an extra library',
    path: 'unhappy (state error)',
    files: {
      'data/a.json': 'x\n',
      _lib: 'x\n',
      'lib/src/content/data/b.dart': 'y\n',
    },
    generator: stubEmbeddedGenerator,
    expected: ['FR-078 lib/src/content/data/b.dart:1'],
  ),
  (
    label: 'no data/ and no libraries (vacuous)',
    path: 'unhappy (empty and minimal)',
    files: {'lib/a.dart': 'x\n'},
    generator: stubEmbeddedGenerator,
    expected: [],
  ),
  (
    label: 'a null generator with libraries present (vacuous)',
    path: 'unhappy (empty and minimal)',
    files: {'data/a.json': 'x\n', _lib: 'different\n'},
    generator: null,
    expected: [],
  ),
  (
    label: 'only README.md and .gitkeep placeholders (vacuous)',
    path: 'unhappy (empty and minimal)',
    files: {'data/README.md': 'r\n', 'lib/src/content/data/.gitkeep': ''},
    generator: stubEmbeddedGenerator,
    expected: [],
  ),
];

void main() {
  group('checkEmbeddedContent', () {
    /// Requirement: per case - doc/specs/architecture-guardrails.md FR-078 -
    ///   the drift check against a stub generator; every case asserts the
    ///   exact Violations (check id, path, line).
    /// Path: per case
    for (final c in _cases) {
      test('${c.path}: ${c.label}', () {
        final found = checkEmbeddedContent(SourceSet(c.files), c.generator);
        expect(_where(found), c.expected);
      });
    }
  });

  group('violating fixture', () {
    /// Requirement: doc/specs/architecture-guardrails.md FR-005 and FR-078 -
    ///   the registered fixture yields an FR-078 Violation, and a clean
    ///   fixture yields none.
    /// Path: unhappy (state error)
    test('FR-078 fixture violates, clean fixture does not', () {
      final fixture = embeddedContentViolatingFixtures['FR-078']!();
      final check = embeddedContentChecks['FR-078']!;
      expect(check(fixture).map((v) => v.checkId), ['FR-078']);
      expect(check(SourceSet({'data/a.json': 'x\n', _lib: 'x\n'})), isEmpty);
    });
  });
}
