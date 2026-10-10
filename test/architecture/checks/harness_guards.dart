import '../support/source_set.dart';
import '../support/violation.dart';

/// Harness guards FR-010 and FR-012 of
/// `doc/specs/architecture-guardrails.md` (section 4.1).
///
/// FR-010 is a registered check (a pure function of a [SourceSet]). FR-012 is
/// not a check: [requireRepositoryRoots] is a guard the real-repository tests
/// call once, so a wrong root cannot make every check pass vacuously.

/// The file whose absence means the snapshot is not the package (FR-012).
const String entryPointPath = 'lib/srd5e.dart';

/// The manifest whose absence or wrong name means a wrong root (FR-012).
const String pubspecPath = 'pubspec.yaml';

final RegExp _packageName = RegExp(r'^name:\s*srd5e\s*$', multiLine: true);

/// FR-010: one Violation per file the loader could not read or decode as
/// UTF-8, naming the file and the reason.
List<Violation> checkUnreadableFiles(SourceSet sources) {
  const id = 'FR-010';
  return sortedViolations([
    for (final entry in sources.unreadable.entries)
      Violation(
        checkId: id,
        path: entry.key,
        line: 1,
        detail: 'The file could not be read: ${entry.value}.',
      ),
  ]);
}

/// FR-012: throws a [StateError] naming what is missing when [sources] lacks
/// `lib/srd5e.dart`, lacks `pubspec.yaml`, or has a `pubspec.yaml` that does
/// not declare `name: srd5e`.
///
/// This is a harness guard, not a registered check: it fails the suite
/// instead of reporting a Violation.
void requireRepositoryRoots(SourceSet sources) {
  final problems = <String>[];
  final pubspec = sources.files[pubspecPath];
  if (pubspec == null) {
    problems.add('$pubspecPath is missing');
  } else if (!_packageName.hasMatch(pubspec)) {
    problems.add('$pubspecPath does not declare "name: srd5e"');
  }
  if (!sources.files.containsKey(entryPointPath)) {
    problems.add('$entryPointPath is missing');
  }
  if (problems.isNotEmpty) {
    throw StateError(
      'Wrong repository root (${problems.join('; ')}); every check would '
      'pass vacuously.',
    );
  }
}

/// The harness checks by id, for the registry.
const Map<String, List<Violation> Function(SourceSet)> harnessGuardChecks = {
  'FR-010': checkUnreadableFiles,
};

/// A minimal violating fixture per id of [harnessGuardChecks].
final Map<String, SourceSet Function()> harnessGuardViolatingFixtures = {
  'FR-010': () => SourceSet(
    {'lib/srd5e.dart': 'library;\n', 'pubspec.yaml': 'name: srd5e\n'},
    unreadable: {'lib/bad.dart': 'not valid UTF-8 (offset 3)'},
  ),
};
