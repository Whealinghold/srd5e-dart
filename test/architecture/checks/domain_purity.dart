import '../support/directives.dart';
import '../support/source_set.dart';
import '../support/violation.dart';

/// Domain purity checks FR-015 and FR-016 of
/// `doc/specs/architecture-guardrails.md` (section 4.2).
///
/// Every function is pure: it reads a [SourceSet] and returns [Violation]s.

/// The folders a `domain/` file may not import from, whichever context owns
/// them (FR-015; `architecture.md` section 1, dependency rule).
const Set<String> domainForbiddenFolders = {
  'application',
  'adapters',
  'shared_ports',
};

/// The Dart libraries a `domain/` file may not import (FR-015). The second
/// extends the rule text (package design, section 9 of the spec).
const Set<String> domainForbiddenLibraries = {'dart:async', 'dart:developer'};

/// The tokens a `domain/` file may not contain (FR-016). The last four extend
/// the rule text (package design, section 9 of the spec).
const List<String> domainForbiddenTokens = [
  'async',
  'await',
  'Future',
  'Stream',
  'FutureOr',
  'StreamController',
  'StreamSubscription',
  'Completer',
];

final RegExp _forbiddenToken = RegExp(
  r'(?<![\w$])('
  '${(domainForbiddenTokens.toList()..sort((a, b) => b.length - a.length)).join('|')}'
  r')(?![\w$])',
);

/// The folder segments of [path] (every segment but the file name).
List<String> _folders(String path) {
  final segments = path.split('/');
  return segments.sublist(0, segments.length - 1);
}

/// Whether [path] is a `domain/` file: a file under `lib/src/` with a folder
/// named `domain` in its path.
bool isDomainFile(String path) =>
    path.endsWith('.dart') &&
    path.startsWith('lib/src/') &&
    _folders(path).skip(2).contains('domain');

/// FR-015: a `domain/` file does not import a path with an `application/`,
/// `adapters/` or `shared_ports/` folder (own or another context's), nor
/// `dart:async` or `dart:developer`.
List<Violation> checkDomainImports(SourceSet sources) {
  const id = 'FR-015';
  final violations = <Violation>[];
  for (final path in sources.dartPaths('lib/src/').where(isDomainFile)) {
    for (final directive in directivesOf(sources, path)) {
      if (directive.kind == DirectiveKind.partOfDirective) continue;
      if (domainForbiddenLibraries.contains(directive.uri)) {
        violations.add(
          Violation(
            checkId: id,
            path: path,
            line: directive.line,
            detail:
                'a domain file imports ${directive.uri}; the domain is '
                'synchronous and silent',
          ),
        );
        continue;
      }
      final target = directive.resolvedPath;
      if (target == null) continue;
      final folder = _folders(
        target,
      ).where(domainForbiddenFolders.contains).firstOrNull;
      if (folder != null) {
        violations.add(
          Violation(
            checkId: id,
            path: path,
            line: directive.line,
            detail:
                'a domain file imports $target, which is under a $folder/ '
                'folder; the domain depends inward only',
          ),
        );
      }
    }
  }
  return sortedViolations(violations);
}

/// FR-016: a `domain/` file does not contain the tokens of
/// [domainForbiddenTokens]. Reads the lexer's code, so comments and string
/// contents are ignored and `${...}` interpolation is still examined (FR-008).
List<Violation> checkDomainTokens(SourceSet sources) {
  const id = 'FR-016';
  final violations = <Violation>[];
  for (final path in sources.dartPaths('lib/src/').where(isDomainFile)) {
    final lexed = sources.lexed(path);
    final seen = <String>{};
    for (final match in _forbiddenToken.allMatches(lexed.code)) {
      final token = match.group(1)!;
      final line = lexed.lineOf(match.start);
      if (!seen.add('$line:$token')) continue;
      violations.add(
        Violation(
          checkId: id,
          path: path,
          line: line,
          detail:
              'a domain file contains the token $token; domain code is '
              'synchronous (no async, Future or Stream)',
        ),
      );
    }
  }
  return sortedViolations(violations);
}

/// FR-015 and FR-016 together.
List<Violation> checkDomainPurity(SourceSet sources) => sortedViolations([
  ...checkDomainImports(sources),
  ...checkDomainTokens(sources),
]);

/// The check function per id, for the registry (`registry.dart`).
const Map<String, List<Violation> Function(SourceSet)> domainPurityChecks = {
  'FR-015': checkDomainImports,
  'FR-016': checkDomainTokens,
};

/// One minimal violating fixture per check id; the registry merges this map
/// into its own (`registry.dart`, FR-005).
final Map<String, SourceSet Function()> domainPurityViolatingFixtures = {
  'FR-015': () => SourceSet({
    'lib/src/d20_test/domain/a.dart':
        "import 'package:srd5e/src/d20_test/application/b.dart';\n",
    'lib/src/d20_test/application/b.dart': '',
  }),
  'FR-016': () => SourceSet({
    'lib/src/d20_test/domain/a.dart': 'Future<int> f() async => 1;\n',
  }),
};
