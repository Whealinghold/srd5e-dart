import '../support/constants.dart';
import '../support/context_map.dart';
import '../support/directives.dart';
import '../support/source_set.dart';
import '../support/violation.dart';
import 'context_map.dart' show contextMapFixtureArchitecture;

/// Layering checks FR-017, FR-018, FR-019, FR-061 and FR-080 of
/// `doc/specs/architecture-guardrails.md` (section 4.2).
///
/// Every function is pure: it reads a [SourceSet] and returns [Violation]s.

/// The core entry points (`architecture.md` section 7): they re-export every
/// barrel, so nothing under `lib/src/` may import them (FR-061).
const Set<String> coreEntryPoints = {
  'lib/srd5e.dart',
  'lib/adapters.dart',
  'lib/testing.dart',
};

/// The only entry point, besides the platform entry points, that may import
/// an `adapters/` folder (FR-017).
const String adaptersEntryPoint = 'lib/adapters.dart';

/// The folder segments of [path] (every segment but the file name).
List<String> _folders(String path) {
  final segments = path.split('/');
  return segments.sublist(0, segments.length - 1);
}

/// The edges FR-017 to FR-080 read: `import`, `export` and `part`, including
/// every URI of a conditional configuration (FR-064).
Iterable<Directive> _edges(SourceSet sources, String path) => directivesOf(
  sources,
  path,
).where((d) => d.kind != DirectiveKind.partOfDirective);

/// FR-017: a file under `lib/` whose path has no `adapters/` folder does not
/// import a path with an `adapters/` folder, except `lib/adapters.dart` and
/// the platform entry points. That includes `shared_ports/adapters/`.
List<Violation> checkAdaptersImports(SourceSet sources) {
  const id = 'FR-017';
  final violations = <Violation>[];
  for (final path in sources.dartPaths('lib/')) {
    if (_folders(path).contains('adapters') ||
        path == adaptersEntryPoint ||
        platformEntryPoints.contains(path)) {
      continue;
    }
    for (final directive in _edges(sources, path)) {
      final target = directive.resolvedPath;
      if (target == null || !_folders(target).contains('adapters')) continue;
      violations.add(
        Violation(
          checkId: id,
          path: path,
          line: directive.line,
          detail:
              'a file outside adapters/ imports $target; only '
              '$adaptersEntryPoint and the platform entry points may',
        ),
      );
    }
  }
  return sortedViolations(violations);
}

/// FR-018: a file in context X importing a file of another context Y imports
/// exactly the barrel `lib/src/Y/Y.dart`; any other file of Y is a Violation.
/// `shared_kernel/`, `shared_ports/` and `testing/` are not contexts.
List<Violation> checkContextBarrelsOnly(SourceSet sources) {
  const id = 'FR-018';
  final violations = <Violation>[];
  for (final path in sources.dartPaths('lib/src/')) {
    final own = contextOf(path);
    if (own == null) continue;
    for (final directive in _edges(sources, path)) {
      final target = directive.resolvedPath;
      final other = target == null ? null : contextOf(target);
      if (target == null || other == null || other == own) continue;
      if (target == barrelPathOf(other)) continue;
      violations.add(
        Violation(
          checkId: id,
          path: path,
          line: directive.line,
          detail:
              'context $own imports $target; the only file of context '
              '$other it may import is ${barrelPathOf(other)}',
        ),
      );
    }
  }
  return sortedViolations(violations);
}

/// FR-019: a file in context X importing the barrel of context Y has Y in X's
/// upstream set in the context map. Nothing is reported when the map cannot
/// be read (FR-022 reports that); a context with no row has no upstream.
List<Violation> checkUpstreamBarrels(SourceSet sources) {
  const id = 'FR-019';
  final map = ContextMap.parse(sources);
  if (!map.tableFound) return const [];
  final violations = <Violation>[];
  for (final path in sources.dartPaths('lib/src/')) {
    final own = contextOf(path);
    if (own == null) continue;
    for (final directive in _edges(sources, path)) {
      final target = directive.resolvedPath;
      final other = target == null ? null : barrelContextOf(target);
      if (other == null || other == own || map.mayDependOn(own, other)) {
        continue;
      }
      violations.add(
        Violation(
          checkId: id,
          path: path,
          line: directive.line,
          detail:
              'context $own imports the barrel of $other, which is not '
              'upstream of it in the context map',
        ),
      );
    }
  }
  return sortedViolations(violations);
}

/// FR-061: no file under `lib/src/` imports or exports a core entry point or
/// a platform entry point.
List<Violation> checkNoEntryPointImports(SourceSet sources) {
  const id = 'FR-061';
  final entryPoints = {...coreEntryPoints, ...platformEntryPoints};
  final violations = <Violation>[];
  for (final path in sources.dartPaths('lib/src/')) {
    for (final directive in _edges(sources, path)) {
      final target = directive.resolvedPath;
      if (target == null || !entryPoints.contains(target)) continue;
      violations.add(
        Violation(
          checkId: id,
          path: path,
          line: directive.line,
          detail:
              'a file under lib/src/ ${directive.kind == DirectiveKind.exportDirective ? 'exports' : 'imports'} '
              'the entry point $target, which bypasses the barrels',
        ),
      );
    }
  }
  return sortedViolations(violations);
}

/// FR-080: a file under `lib/src/<context>/` does not import its own barrel
/// `lib/src/<context>/<context>.dart`.
List<Violation> checkNoOwnBarrelImports(SourceSet sources) {
  const id = 'FR-080';
  final violations = <Violation>[];
  for (final path in sources.dartPaths('lib/src/')) {
    final own = contextOf(path);
    if (own == null) continue;
    for (final directive in _edges(sources, path)) {
      if (directive.resolvedPath != barrelPathOf(own)) continue;
      violations.add(
        Violation(
          checkId: id,
          path: path,
          line: directive.line,
          detail:
              'a file of context $own imports its own barrel '
              '${barrelPathOf(own)}, which only creates a cycle',
        ),
      );
    }
  }
  return sortedViolations(violations);
}

/// FR-017, FR-018, FR-019, FR-061 and FR-080 together.
List<Violation> checkLayering(SourceSet sources) => sortedViolations([
  ...checkAdaptersImports(sources),
  ...checkContextBarrelsOnly(sources),
  ...checkUpstreamBarrels(sources),
  ...checkNoEntryPointImports(sources),
  ...checkNoOwnBarrelImports(sources),
]);

/// The check function per id, for the registry (`registry.dart`).
const Map<String, List<Violation> Function(SourceSet)> layeringChecks = {
  'FR-017': checkAdaptersImports,
  'FR-018': checkContextBarrelsOnly,
  'FR-019': checkUpstreamBarrels,
  'FR-061': checkNoEntryPointImports,
  'FR-080': checkNoOwnBarrelImports,
};

/// A fixture holding a context map of [upstreamByContext] and [files].
SourceSet _withMap(
  Map<String, List<String>> upstreamByContext,
  Map<String, String> files,
) => SourceSet({
  architectureRulesPath: contextMapFixtureArchitecture(upstreamByContext),
  ...files,
});

/// One minimal violating fixture per check id; the registry merges this map
/// into its own (`registry.dart`, FR-005).
final Map<String, SourceSet Function()> layeringViolatingFixtures = {
  'FR-017': () => SourceSet({
    'lib/src/content/application/a.dart':
        "import 'package:srd5e/src/content/adapters/b.dart';\n",
    'lib/src/content/adapters/b.dart': '',
  }),
  'FR-018': () => _withMap(
    {
      'content': [],
      'character': ['content'],
    },
    {
      'lib/src/character/domain/a.dart':
          "import 'package:srd5e/src/content/domain/b.dart';\n",
      'lib/src/content/domain/b.dart': '',
    },
  ),
  'FR-019': () => _withMap(
    {'content': [], 'combat': []},
    {
      'lib/src/content/application/a.dart':
          "import 'package:srd5e/src/combat/combat.dart';\n",
      'lib/src/combat/combat.dart': '',
    },
  ),
  'FR-061': () => SourceSet({
    'lib/src/content/domain/a.dart': "import 'package:srd5e/srd5e.dart';\n",
    'lib/srd5e.dart': '',
  }),
  'FR-080': () => SourceSet({
    'lib/src/character/domain/a.dart':
        "import 'package:srd5e/src/character/character.dart';\n",
    'lib/src/character/character.dart': '',
  }),
};
