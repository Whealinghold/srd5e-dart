import '../support/constants.dart';
import '../support/exports.dart';
import '../support/source_set.dart';
import '../support/violation.dart';

/// The barrel scan, FR-077 of `doc/specs/architecture-guardrails.md`
/// (section 4.2).
///
/// Every function is pure: it reads a [SourceSet] and returns [Violation]s.

/// FR-077: resolve the export closure (FR-093) of every barrel and every core
/// entry point present, then report
///
/// (a) a declaration named in [genericVariantNames] that any of them exports,
///     at its declaring line, and
/// (b) a name declared in two different files that are exported through the
///     same entry point or through two entry points, at each declaring line.
///
/// One declaration re-exported by several entry points is not a duplicate. A
/// `show` or `hide` clause is honoured by the closure.
List<Violation> checkBarrelScan(SourceSet sources) {
  const id = 'FR-077';
  final exportedBy = <Exported, Set<String>>{};
  for (final entry in entryPointsIn(sources)) {
    for (final declaration in exportClosure(sources, entry)) {
      exportedBy.putIfAbsent(declaration, () => <String>{}).add(entry);
    }
  }
  final violations = <Violation>[];
  for (final MapEntry(key: declaration, value: entries) in exportedBy.entries) {
    if (!genericVariantNames.contains(declaration.name)) continue;
    violations.add(
      Violation(
        checkId: id,
        path: declaration.path,
        line: declaration.line,
        detail:
            '`${declaration.name}` is a generic variant name exported '
            'through ${_listed(entries)}; prefix it with the operation '
            '(for example `DamageApplied`)',
      ),
    );
  }
  final byName = <String, List<Exported>>{};
  for (final declaration in exportedBy.keys) {
    byName.putIfAbsent(declaration.name, () => []).add(declaration);
  }
  for (final MapEntry(key: name, value: declarations) in byName.entries) {
    if (declarations.length < 2) continue;
    for (final declaration in declarations) {
      final others = declarations.where((d) => d != declaration);
      final through = {for (final d in declarations) ...exportedBy[d]!};
      violations.add(
        Violation(
          checkId: id,
          path: declaration.path,
          line: declaration.line,
          detail:
              '`$name` is also declared in '
              '${others.map((d) => d.path).join(', ')} and both are '
              'exported (through ${_listed(through)}); rename one',
        ),
      );
    }
  }
  return sortedViolations(violations);
}

String _listed(Iterable<String> entries) =>
    (entries.toList()..sort()).join(', ');

/// The check function per id, for the registry (`registry.dart`).
const Map<String, List<Violation> Function(SourceSet)> barrelScanChecks = {
  'FR-077': checkBarrelScan,
};

/// One minimal violating fixture per check id; the registry merges this map
/// into its own (`registry.dart`, FR-005).
final Map<String, SourceSet Function()> barrelScanViolatingFixtures = {
  'FR-077': () => SourceSet({
    'lib/srd5e.dart': "export 'src/combat/domain/damage.dart' show Applied;\n",
    'lib/src/combat/domain/damage.dart': 'class Applied {}\n',
  }),
};
