import '../support/constants.dart' as constants;
import '../support/directives.dart';
import '../support/source_set.dart';
import '../support/violation.dart';

/// Observability SDK import check FR-032 of
/// `doc/specs/architecture-guardrails.md` (section 4.3).
///
/// Every function is pure: it reads a [SourceSet] and returns [Violation]s.
/// Directives come from the lexer's code (FR-065), so an import inside a
/// comment or string is not an edge (FR-008).

/// The package name of a `package:` [uri], or `null` for any other URI.
String? packageNameOf(String uri) {
  const prefix = 'package:';
  if (!uri.startsWith(prefix)) return null;
  final rest = uri.substring(prefix.length);
  final slash = rest.indexOf('/');
  return slash < 0 ? rest : rest.substring(0, slash);
}

/// Whether [package] is an observability or error-tracking SDK: equal to, or
/// starting with, one of `constants.sdkPackagePrefixes` (FR-032, FR-033).
bool isSdkPackage(String package) =>
    constants.sdkPackagePrefixes.any(package.startsWith);

/// FR-032: no file under `lib/` imports (or exports) an observability or
/// error-tracking package, or `dart:developer`.
List<Violation> checkNoObservabilitySdkImports(SourceSet sources) {
  const id = 'FR-032';
  final violations = <Violation>[];
  for (final path in sources.dartPaths('lib/')) {
    for (final directive in directivesOf(sources, path)) {
      if (directive.kind == DirectiveKind.partOfDirective) continue;
      final package = packageNameOf(directive.uri);
      final banned =
          constants.sdkLibraries.contains(directive.uri) ||
          (package != null && isSdkPackage(package));
      if (!banned) continue;
      violations.add(
        Violation(
          checkId: id,
          path: path,
          line: directive.line,
          detail:
              '${directive.kind.name} of "${directive.uri}": observability '
              'goes through the ports, never an SDK',
        ),
      );
    }
  }
  return sortedViolations(violations);
}

/// The check function per id, for the registry (`registry.dart`).
const Map<String, List<Violation> Function(SourceSet)> observabilitySdkChecks =
    {'FR-032': checkNoObservabilitySdkImports};

/// One minimal violating fixture per check id; the registry merges this map
/// into its own (`registry.dart`, FR-005).
final Map<String, SourceSet Function()> observabilitySdkViolatingFixtures = {
  'FR-032': () => SourceSet({
    'lib/src/content/adapters/a.dart':
        "import 'package:sentry_flutter/sentry_flutter.dart';\n",
  }),
};
