import '../support/directives.dart';
import '../support/source_set.dart';
import '../support/violation.dart';

/// Shared-module import checks FR-023 and FR-024 of
/// `doc/specs/architecture-guardrails.md` (section 4.2).
///
/// Every function is pure: it reads a [SourceSet] and returns [Violation]s.

/// The folder of the shared kernel.
const String sharedKernelPrefix = 'lib/src/shared_kernel/';

/// The folder of the shared ports.
const String sharedPortsPrefix = 'lib/src/shared_ports/';

/// Whether [directive] names a file of this package that [allowed] does not
/// cover. Only a local directive (a relative URI or `package:srd5e/...`)
/// names the package; `dart:` libraries and other packages never do. A local
/// URI that cannot be mapped inside the repository counts as outside.
bool _leavesAllowed(Directive directive, List<String> allowed) {
  if (!directive.isLocal) return false;
  final resolved = directive.resolvedPath;
  return resolved == null || !allowed.any(resolved.startsWith);
}

List<Violation> _importsOutside({
  required String id,
  required SourceSet sources,
  required String prefix,
  required List<String> allowed,
  required String subject,
  required String allowedText,
}) => sortedViolations([
  for (final directive in allDirectives(sources, prefix: prefix))
    if (_leavesAllowed(directive, allowed))
      Violation(
        checkId: id,
        path: directive.from,
        line: directive.line,
        detail:
            '$subject ${directive.kind.name} of "${directive.uri}" '
            '(${directive.resolvedPath ?? 'outside the package'}); it may '
            'import only $allowedText',
      ),
]);

/// FR-023: a `shared_kernel/` file imports nothing in the package outside
/// `lib/src/shared_kernel/`, the entry point `package:srd5e/srd5e.dart`
/// included. `dart:` libraries, `package:meta` and `package:collection` are
/// not in the package and stay allowed.
List<Violation> checkSharedKernelImports(SourceSet sources) => _importsOutside(
  id: 'FR-023',
  sources: sources,
  prefix: sharedKernelPrefix,
  allowed: const [sharedKernelPrefix],
  subject: 'a shared_kernel file has an',
  allowedText:
      'dart: libraries, package:meta, package:collection and '
      'other shared_kernel files',
);

/// FR-024: a `shared_ports/` file, its `adapters/` folder included, imports
/// nothing in the package except `shared_kernel/` and `shared_ports/`.
///
/// A file outside `shared_ports/adapters/` importing that folder is FR-017's
/// finding, not this check's: it stays inside `shared_ports/` here.
List<Violation> checkSharedPortsImports(SourceSet sources) => _importsOutside(
  id: 'FR-024',
  sources: sources,
  prefix: sharedPortsPrefix,
  allowed: const [sharedKernelPrefix, sharedPortsPrefix],
  subject: 'a shared_ports file has an',
  allowedText:
      'dart: libraries, package:meta, package:collection, '
      'shared_kernel and shared_ports files',
);

/// Both shared-module checks, for the combined real-repository run.
List<Violation> checkSharedModules(SourceSet sources) => sortedViolations([
  ...checkSharedKernelImports(sources),
  ...checkSharedPortsImports(sources),
]);

/// Check functions by FR id; the registry wires these (`registry.dart`).
const Map<String, List<Violation> Function(SourceSet)> sharedModulesChecks = {
  'FR-023': checkSharedKernelImports,
  'FR-024': checkSharedPortsImports,
};

/// One minimal violating fixture per check id; the registry merges this map
/// into its own (`registry.dart`, FR-005).
final Map<String, SourceSet Function()> sharedModulesViolatingFixtures = {
  'FR-023': () => SourceSet({
    'lib/src/shared_kernel/a.dart': "import '../shared_ports/b.dart';\n",
    'lib/src/shared_ports/b.dart': '',
  }),
  'FR-024': () => SourceSet({
    'lib/src/shared_ports/a.dart': "import '../content/content.dart';\n",
    'lib/src/content/content.dart': '',
  }),
};
