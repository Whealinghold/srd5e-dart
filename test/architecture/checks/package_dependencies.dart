import '../support/constants.dart' as constants;
import '../support/source_set.dart';
import '../support/violation.dart';
import 'observability_sdk.dart';

/// Dependency checks FR-033 and FR-083 of
/// `doc/specs/architecture-guardrails.md` (sections 4.2 and 4.3).
///
/// Both read the `dependencies:` block of `pubspec.yaml` line by line (no YAML
/// package: the suite adds no dependency). `dev_dependencies:` and
/// `dependency_overrides:` are not read. Every function is pure.

/// The repository path of the package manifest.
const String pubspecPath = 'pubspec.yaml';

/// One package listed under `dependencies:`, with its 1-based line.
typedef DeclaredDependency = ({String name, int line});

final RegExp _topLevelKey = RegExp(r'^([A-Za-z_][\w-]*)\s*:');
final RegExp _entry = RegExp(r'''^(\s+)['"]?([A-Za-z_][\w.-]*)['"]?\s*:''');

/// The packages listed directly under the top-level `dependencies:` key of
/// [pubspec], in order. A nested line (a version map, `sdk: flutter`) belongs
/// to the entry above it. Comments and blank lines are ignored.
List<DeclaredDependency> dependenciesIn(String pubspec) {
  final result = <DeclaredDependency>[];
  var inBlock = false;
  int? entryIndent;
  final lines = pubspec.split('\n');
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i].replaceAll('\r', '');
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
    final top = _topLevelKey.firstMatch(line);
    if (top != null) {
      inBlock = top.group(1) == 'dependencies';
      entryIndent = null;
      continue;
    }
    if (!inBlock) continue;
    final entry = _entry.firstMatch(line);
    if (entry == null) continue;
    final indent = entry.group(1)!.length;
    entryIndent ??= indent;
    if (indent != entryIndent) continue;
    result.add((name: entry.group(2)!, line: i + 1));
  }
  return result;
}

/// FR-033: `pubspec.yaml` `dependencies:` lists no observability or
/// error-tracking package (the FR-032 denylist). `dev_dependencies:` are not
/// checked.
List<Violation> checkNoObservabilitySdkDependency(SourceSet sources) {
  const id = 'FR-033';
  final pubspec = sources.files[pubspecPath];
  if (pubspec == null) return const [];
  return sortedViolations([
    for (final dependency in dependenciesIn(pubspec))
      if (isSdkPackage(dependency.name))
        Violation(
          checkId: id,
          path: pubspecPath,
          line: dependency.line,
          detail:
              'dependencies lists ${dependency.name}, an observability or '
              'error-tracking package; use the ports instead',
        ),
  ]);
}

/// FR-083: `pubspec.yaml` `dependencies:` lists only the packages of
/// `constants.dependencyAllowlist`. `dev_dependencies:` are not checked.
List<Violation> checkDependencyAllowlist(SourceSet sources) {
  const id = 'FR-083';
  final pubspec = sources.files[pubspecPath];
  if (pubspec == null) return const [];
  return sortedViolations([
    for (final dependency in dependenciesIn(pubspec))
      if (!constants.dependencyAllowlist.contains(dependency.name))
        Violation(
          checkId: id,
          path: pubspecPath,
          line: dependency.line,
          detail:
              'dependencies lists ${dependency.name}; only '
              '${(constants.dependencyAllowlist.toList()..sort()).join(' and ')} '
              'are allowed without discussion',
        ),
  ]);
}

/// The check function per id, for the registry (`registry.dart`).
const Map<String, List<Violation> Function(SourceSet)>
packageDependenciesChecks = {
  'FR-033': checkNoObservabilitySdkDependency,
  'FR-083': checkDependencyAllowlist,
};

SourceSet _pubspecFixture(String dependencies) =>
    SourceSet({pubspecPath: 'name: srd5e\n\ndependencies:\n$dependencies\n'});

/// One minimal violating fixture per check id; the registry merges this map
/// into its own (`registry.dart`, FR-005).
final Map<String, SourceSet Function()> packageDependenciesViolatingFixtures = {
  'FR-033': () => _pubspecFixture('  sentry: ^8.0.0'),
  'FR-083': () => _pubspecFixture('  http: ^1.0.0'),
};
