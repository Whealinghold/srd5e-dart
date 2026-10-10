import '../support/constants.dart' as constants;
import '../support/directives.dart';
import '../support/source_set.dart';
import '../support/violation.dart';

/// Platform-import checks FR-013, FR-062, FR-014 and FR-067 of
/// `doc/specs/architecture-guardrails.md` (section 4.2).
///
/// Every function is pure: it reads a [SourceSet] and returns [Violation]s.
/// Directives come from the lexer's code (FR-065), so an import inside a
/// comment or string is not an edge (FR-008), and a conditional configuration
/// counts as an edge (FR-064).

/// The core entry points (`doc/specs/architecture-guardrails.md` section 3).
const List<String> coreEntryPoints = [
  'lib/srd5e.dart',
  'lib/adapters.dart',
  'lib/testing.dart',
];

const String _libSrc = 'lib/src/';
const String _dartIo = 'dart:io';
const String _dartUi = 'dart:ui';

/// Whether [uri] names a Flutter package: `package:flutter/...` or a package
/// whose name starts with `flutter_` (FR-013).
bool isFlutterPackageUri(String uri) {
  const prefix = 'package:';
  if (!uri.startsWith(prefix)) return false;
  final rest = uri.substring(prefix.length);
  final slash = rest.indexOf('/');
  final name = slash < 0 ? rest : rest.substring(0, slash);
  return name == 'flutter' || name.startsWith('flutter_');
}

/// Whether [path] has an `adapters/` folder among its directories.
bool hasAdaptersFolder(String path) {
  final segments = path.split('/');
  return segments.take(segments.length - 1).contains('adapters');
}

/// The directive kinds that make the file named by `resolvedPath` reachable.
bool _isEdge(Directive d) =>
    d.kind != DirectiveKind.partOfDirective && d.isLocal && d.exists;

Violation _banned(String id, Directive d, String what) => Violation(
  checkId: id,
  path: d.from,
  line: d.line,
  detail: '${d.kind.name} of "${d.uri}": $what',
);

/// FR-013: no file under `lib/src/` imports a Flutter package or `dart:ui`,
/// and none outside an `adapters/` folder imports `dart:io`.
List<Violation> checkSrcPlatformImports(SourceSet sources) {
  const id = 'FR-013';
  final violations = <Violation>[];
  for (final path in sources.dartPaths(_libSrc)) {
    final inAdapters = hasAdaptersFolder(path);
    for (final d in directivesOf(sources, path)) {
      if (d.kind == DirectiveKind.partOfDirective) continue;
      if (isFlutterPackageUri(d.uri)) {
        violations.add(
          _banned(id, d, 'a Flutter package is banned under lib/src/.'),
        );
      } else if (d.uri == _dartUi) {
        violations.add(_banned(id, d, 'dart:ui is banned under lib/src/.'));
      } else if (d.uri == _dartIo && !inAdapters) {
        violations.add(
          _banned(
            id,
            d,
            'dart:io is allowed only inside an adapters/ folder '
            '(see FR-014).',
          ),
        );
      }
    }
  }
  return sortedViolations(violations);
}

/// FR-062: no core entry point imports `dart:io`, `dart:ui` or a Flutter
/// package.
List<Violation> checkEntryPointPlatformImports(SourceSet sources) {
  const id = 'FR-062';
  final violations = <Violation>[];
  for (final path in coreEntryPoints.where(sources.files.containsKey)) {
    for (final d in directivesOf(sources, path)) {
      if (d.kind == DirectiveKind.partOfDirective) continue;
      if (d.uri == _dartIo || d.uri == _dartUi || isFlutterPackageUri(d.uri)) {
        violations.add(
          _banned(id, d, 'a core entry point must stay platform-neutral.'),
        );
      }
    }
  }
  return sortedViolations(violations);
}

/// The `dart:io` directive that makes [path] a platform adapter, or null when
/// it has none or is not under an `adapters/` folder of `lib/src/`.
Directive? _dartIoDirective(SourceSet sources, String path) {
  if (!hasAdaptersFolder(path)) return null;
  for (final d in directivesOf(sources, path)) {
    if (d.uri == _dartIo && d.kind != DirectiveKind.partOfDirective) return d;
  }
  return null;
}

/// The adapter files that import `dart:io`, with that directive, in path
/// order.
List<Directive> _platformAdapters(SourceSet sources) => [
  for (final path in sources.dartPaths(_libSrc))
    ?_dartIoDirective(sources, path),
];

/// The set of files reachable from [roots] (the roots included) through
/// import, export and part directives.
Set<String> reachableFrom(SourceSet sources, Iterable<String> roots) {
  final seen = <String>{};
  final queue = <String>[
    for (final root in roots)
      if (sources.files.containsKey(root)) root,
  ];
  while (queue.isNotEmpty) {
    final path = queue.removeLast();
    if (!seen.add(path)) continue;
    if (!path.endsWith('.dart')) continue;
    for (final d in directivesOf(sources, path)) {
      if (!_isEdge(d)) continue;
      final target = d.resolvedPath!;
      if (sources.files.containsKey(target) && !seen.contains(target)) {
        queue.add(target);
      }
    }
  }
  return seen;
}

/// FR-014: an `adapters/` file that imports `dart:io` is not reachable from a
/// core entry point.
List<Violation> checkDartIoAdaptersNotCoreReachable(SourceSet sources) {
  const id = 'FR-014';
  final reachable = reachableFrom(sources, coreEntryPoints);
  return sortedViolations([
    for (final d in _platformAdapters(sources))
      if (reachable.contains(d.from))
        Violation(
          checkId: id,
          path: d.from,
          line: d.line,
          detail:
              'imports dart:io but is reachable from a core entry point; '
              'move it behind a platform entry point.',
        ),
  ]);
}

/// FR-067: an `adapters/` file that imports `dart:io` is reachable from a
/// platform entry point (in [platformEntries]; the support constant by
/// default). An unreachable one is dead platform code.
List<Violation> checkDartIoAdaptersReachableFromPlatform(
  SourceSet sources, {
  Set<String> platformEntries = constants.platformEntryPoints,
}) {
  const id = 'FR-067';
  final reachable = reachableFrom(sources, platformEntries);
  return sortedViolations([
    for (final d in _platformAdapters(sources))
      if (!reachable.contains(d.from))
        Violation(
          checkId: id,
          path: d.from,
          line: d.line,
          detail:
              'imports dart:io but no platform entry point reaches it '
              '(dead platform code).',
        ),
  ]);
}

/// All four checks, sorted.
List<Violation> checkPlatformImports(SourceSet sources) => sortedViolations([
  ...checkSrcPlatformImports(sources),
  ...checkEntryPointPlatformImports(sources),
  ...checkDartIoAdaptersNotCoreReachable(sources),
  ...checkDartIoAdaptersReachableFromPlatform(sources),
]);

/// The check function per id, for the registry (`registry.dart`, FR-005).
const Map<String, List<Violation> Function(SourceSet)> platformImportsChecks = {
  'FR-013': checkSrcPlatformImports,
  'FR-062': checkEntryPointPlatformImports,
  'FR-014': checkDartIoAdaptersNotCoreReachable,
  'FR-067': checkDartIoAdaptersReachableFromPlatform,
};

/// One minimal violating fixture per check id; the registry merges this map
/// into its own (FR-005).
final Map<String, SourceSet Function()> platformImportsViolatingFixtures = {
  'FR-013': () =>
      SourceSet({'lib/src/d20_test/domain/x.dart': "import 'dart:io';\n"}),
  'FR-062': () => SourceSet({'lib/adapters.dart': "import 'dart:io';\n"}),
  'FR-014': () => SourceSet({
    'lib/adapters.dart': "export 'src/content/adapters/a.dart';\n",
    'lib/src/content/adapters/a.dart': "import 'dart:io';\n",
  }),
  'FR-067': () =>
      SourceSet({'lib/src/content/adapters/a.dart': "import 'dart:io';\n"}),
};
