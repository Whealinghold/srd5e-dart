import '../support/source_set.dart';
import '../support/violation.dart';

/// FR-078 of `doc/specs/architecture-guardrails.md`: the embedded data
/// libraries under `lib/src/content/data/` equal the generator's output.
///
/// Pure: the generator is a parameter and the function does no I/O.

/// The generator: a pure function from the `data/` file texts (keyed by
/// repository-relative path, for example `data/srd_5_2_1/x.json`) to the text
/// of each embedded library (keyed by repository-relative path under
/// `lib/src/content/data/`).
typedef EmbeddedLibraryGenerator =
    Map<String, String> Function(Map<String, String> dataFiles);

/// The folder of the source data.
const String dataRoot = 'data/';

/// The folder of the embedded libraries.
const String embeddedRoot = 'lib/src/content/data/';

bool _counts(String path, String root) {
  if (!path.startsWith(root)) return false;
  final name = path.substring(path.lastIndexOf('/') + 1);
  return name != '.gitkeep' && name != 'README.md';
}

int _firstDifferingLine(String expected, String actual) {
  final a = expected.split('\n');
  final b = actual.split('\n');
  for (var i = 0; i < a.length && i < b.length; i++) {
    if (a[i] != b[i]) return i + 1;
  }
  return (a.length < b.length ? a.length : b.length) + 1;
}

/// FR-078: with a non-null [generator], every library it produces matches the
/// file in [sources] byte for byte; a missing, extra or differing library is a
/// Violation naming it. Vacuous when [generator] is null or when neither
/// `data/` nor `lib/src/content/data/` holds a file.
List<Violation> checkEmbeddedContent(
  SourceSet sources,
  EmbeddedLibraryGenerator? generator,
) {
  const id = 'FR-078';
  if (generator == null) return const [];
  final data = {
    for (final e in sources.files.entries)
      if (_counts(e.key, dataRoot)) e.key: e.value,
  };
  final actual = {
    for (final e in sources.files.entries)
      if (_counts(e.key, embeddedRoot)) e.key: e.value,
  };
  if (data.isEmpty && actual.isEmpty) return const [];
  final expected = generator(Map.unmodifiable(data));
  final violations = <Violation>[];
  for (final entry in expected.entries) {
    final text = actual[entry.key];
    if (text == null) {
      violations.add(
        Violation(
          checkId: id,
          path: entry.key,
          line: 1,
          detail: 'The generator produces this library but it is missing.',
        ),
      );
    } else if (text != entry.value) {
      violations.add(
        Violation(
          checkId: id,
          path: entry.key,
          line: _firstDifferingLine(entry.value, text),
          detail: 'The library differs from the generator output.',
        ),
      );
    }
  }
  for (final path in actual.keys) {
    if (expected.containsKey(path)) continue;
    violations.add(
      Violation(
        checkId: id,
        path: path,
        line: 1,
        detail: 'The generator does not produce this library.',
      ),
    );
  }
  return sortedViolations(violations);
}

/// A stand-in generator for fixtures and the registry: each `data/**/name.ext`
/// becomes `lib/src/content/data/name.dart` holding the data text unchanged.
Map<String, String> stubEmbeddedGenerator(Map<String, String> dataFiles) {
  final libraries = <String, String>{};
  for (final entry in dataFiles.entries) {
    final file = entry.key.substring(entry.key.lastIndexOf('/') + 1);
    final dot = file.lastIndexOf('.');
    final name = dot < 0 ? file : file.substring(0, dot);
    libraries['$embeddedRoot$name.dart'] = entry.value;
  }
  return libraries;
}

/// The registry entry: FR-078 evaluated with [stubEmbeddedGenerator], so the
/// FR-005 meta-test can exercise a violating fixture. The real-repository
/// test passes `null` (plan decision D3) until `tool/` has the generator.
const Map<String, List<Violation> Function(SourceSet)> embeddedContentChecks = {
  'FR-078': _checkWithStub,
};

List<Violation> _checkWithStub(SourceSet sources) =>
    checkEmbeddedContent(sources, stubEmbeddedGenerator);

/// One minimal violating fixture per check id (FR-005).
final Map<String, SourceSet Function()> embeddedContentViolatingFixtures = {
  'FR-078': () => SourceSet({
    'data/a.json': '{"a":1}\n',
    'lib/src/content/data/a.dart': '{"a":2}\n',
  }),
};
