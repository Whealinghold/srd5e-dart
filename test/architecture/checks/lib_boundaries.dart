import '../support/directives.dart';
import '../support/source_set.dart';
import '../support/violation.dart';

/// The boundaries of `lib/`: FR-076 and FR-095 of
/// `doc/specs/architecture-guardrails.md` (section 4.2).
///
/// Every function is pure: it reads a [SourceSet] and returns [Violation]s.

/// Packages that are dev-only: `lib/` must not import them, so none becomes a
/// runtime dependency (FR-076; FR-009 names this exemption list).
const Set<String> devOnlyPackages = {'test', 'test_api', 'matcher', 'coverage'};

/// The folder of the embedded data libraries (FR-095).
const String embeddedDataPrefix = 'lib/src/content/data/';

/// The only `lib/` folder that may import the embedded data libraries
/// (FR-095).
const String embeddedDataReaderPrefix = 'lib/src/content/adapters/';

bool _isImportOrExport(Directive directive) =>
    directive.kind == DirectiveKind.importDirective ||
    directive.kind == DirectiveKind.exportDirective;

String _verb(Directive directive) =>
    directive.kind == DirectiveKind.exportDirective ? 'export' : 'import';

/// FR-076: no file under `lib/` imports or exports a path that resolves
/// outside `lib/` (a relative `../` that escapes it, onto `tool/`, `test/`
/// including `test/contract/`, or anything else), and none imports one of
/// [devOnlyPackages]. Files under `tool/` and `test/` may import `lib/`.
List<Violation> checkLibImportsStayInLib(SourceSet sources) {
  const id = 'FR-076';
  final violations = <Violation>[];
  for (final directive in allDirectives(sources, prefix: 'lib/')) {
    if (!_isImportOrExport(directive)) continue;
    final uri = directive.uri;
    if (directive.isPackage && !uri.startsWith('package:srd5e/')) {
      final package = uri.substring('package:'.length).split('/').first;
      if (devOnlyPackages.contains(package)) {
        violations.add(
          Violation(
            checkId: id,
            path: directive.from,
            line: directive.line,
            detail:
                '${_verb(directive)} of "$uri": `$package` is a dev-only '
                'package and must not become a runtime dependency',
          ),
        );
      }
      continue;
    }
    if (!directive.isLocal) continue;
    final target = directive.resolvedPath;
    if (target != null) {
      if (!target.startsWith('lib/')) {
        violations.add(
          Violation(
            checkId: id,
            path: directive.from,
            line: directive.line,
            detail:
                '${_verb(directive)} of "$uri" resolves to $target, outside '
                'lib/',
          ),
        );
      }
    } else if (uri.split('/').contains('..')) {
      violations.add(
        Violation(
          checkId: id,
          path: directive.from,
          line: directive.line,
          detail:
              '${_verb(directive)} of "$uri" climbs out of the repository, '
              'outside lib/',
        ),
      );
    }
  }
  return sortedViolations(violations);
}

/// FR-095: a file under `lib/src/content/data/` imports nothing in the
/// package, and among the files under `lib/` only a file under
/// `lib/src/content/adapters/` may import or export one of those data
/// libraries. `test/` and `tool/` are out of scope.
List<Violation> checkEmbeddedDataImports(SourceSet sources) {
  const id = 'FR-095';
  final violations = <Violation>[];
  for (final directive in allDirectives(sources, prefix: 'lib/')) {
    final inData = directive.from.startsWith(embeddedDataPrefix);
    if (inData) {
      if (directive.isLocal) {
        violations.add(
          Violation(
            checkId: id,
            path: directive.from,
            line: directive.line,
            detail:
                '${directive.kind.name} of "${directive.uri}": an embedded '
                'data library imports nothing in the package',
          ),
        );
      }
      continue;
    }
    if (!_isImportOrExport(directive)) continue;
    final target = directive.resolvedPath;
    if (target == null || !target.startsWith(embeddedDataPrefix)) continue;
    if (directive.from.startsWith(embeddedDataReaderPrefix)) continue;
    violations.add(
      Violation(
        checkId: id,
        path: directive.from,
        line: directive.line,
        detail:
            '${_verb(directive)} of the embedded data library $target; only '
            'files under $embeddedDataReaderPrefix read it (one decode path)',
      ),
    );
  }
  return sortedViolations(violations);
}

/// The check function per id, for the registry (`registry.dart`).
const Map<String, List<Violation> Function(SourceSet)> libBoundaryChecks = {
  'FR-076': checkLibImportsStayInLib,
  'FR-095': checkEmbeddedDataImports,
};

/// One minimal violating fixture per check id; the registry merges this map
/// into its own (`registry.dart`, FR-005).
final Map<String, SourceSet Function()> libBoundaryViolatingFixtures = {
  'FR-076': () => SourceSet({
    'lib/src/content/application/a.dart': "import 'package:test/test.dart';\n",
  }),
  'FR-095': () => SourceSet({
    'lib/adapters.dart': "import 'src/content/data/species.dart';\n",
    'lib/src/content/data/species.dart': 'const species = r"""{}""";\n',
  }),
};
