import '../support/context_map.dart';
import '../support/declarations.dart';
import '../support/source_set.dart';
import '../support/violation.dart';

/// The use case call check, FR-097 of `doc/specs/architecture-guardrails.md`
/// (section 4.2).
///
/// Every function is pure: it reads a [SourceSet] and returns [Violation]s.

/// A use case class found in the source (`architecture.md` §4): a class in a
/// file under `lib/src/<context>/application/` (not `ports/`) with a public
/// `call` member, other than a `*Signals` class.
final class UseCaseClass {
  /// Creates a record for the class [name] declared at [path]:[line].
  const UseCaseClass({
    required this.name,
    required this.path,
    required this.line,
  });

  /// The class name.
  final String name;

  /// The declaring file.
  final String path;

  /// The 1-based line of the name.
  final int line;
}

/// The layer folder of [path] inside its context (`application`, `domain`,
/// `adapters`, ...), and the rest of the path below it; null when [path] is
/// not inside a context folder.
({String layer, List<String> below})? _layerOf(String path) {
  if (contextOf(path) == null) return null;
  final segments = path.substring('lib/src/'.length).split('/');
  if (segments.length < 3) return null;
  return (layer: segments[1], below: segments.sublist(2));
}

bool _isUseCaseFile(String path) {
  final layer = _layerOf(path);
  return layer != null &&
      layer.layer == 'application' &&
      layer.below.first != 'ports';
}

bool _isScannedFile(String path) {
  final layer = _layerOf(path);
  return layer != null &&
      (layer.layer == 'application' || layer.layer == 'domain');
}

/// [code] with everything nested inside `{}`, `()` and `[]` blanked, so only
/// the text at the outermost level is left.
String _outerLevelOnly(String code) {
  final out = StringBuffer();
  var depth = 0;
  for (var i = 0; i < code.length; i++) {
    final c = code[i];
    if (c == '{' || c == '(' || c == '[') {
      out.write(depth == 0 ? c : ' ');
      depth++;
    } else if (c == '}' || c == ')' || c == ']') {
      if (depth > 0) depth--;
      out.write(depth == 0 ? c : ' ');
    } else {
      out.write(depth == 0 || c == '\n' ? c : ' ');
    }
  }
  return out.toString();
}

final RegExp _publicCall = RegExp(
  r'(?<![\w$.])call(?![\w$])\s*(?:<[^<>]*>\s*)?[(;=]|(?<![\w$.])get\s+call(?![\w$])',
);

/// Every use case class of [sources] (`architecture.md` §4), in path then line
/// order. The set is derived from the source, not listed.
List<UseCaseClass> useCaseClasses(SourceSet sources) {
  final found = <UseCaseClass>[];
  for (final path in sources.dartPaths('lib/src/')) {
    if (!_isUseCaseFile(path)) continue;
    final lexed = sources.lexed(path);
    for (final declaration in declarationsIn(path, lexed)) {
      if (declaration.kind != DeclarationKind.classDeclaration ||
          declaration.name.endsWith('Signals')) {
        continue;
      }
      // The members of the class body, one nesting level only.
      final body = _outerLevelOnly(
        lexed.code.substring(
          declaration.bodyStart + 1,
          declaration.bodyEnd - 1,
        ),
      );
      if (_publicCall.hasMatch(body)) {
        found.add(
          UseCaseClass(
            name: declaration.name,
            path: path,
            line: declaration.line,
          ),
        );
      }
    }
  }
  return found;
}

/// FR-097: no use case calls another use case. A file under
/// `lib/src/<context>/application/` or `lib/src/<context>/domain/` MUST NOT
/// mention, as an identifier in the lexer's code, a use case class declared in
/// a different file, of its own context or another. One Violation per
/// mentioning line and name. Test files and `lib/src/testing/` are out of
/// scope.
List<Violation> checkNoUseCaseCalls(SourceSet sources) {
  const id = 'FR-097';
  final useCases = useCaseClasses(sources);
  if (useCases.isEmpty) return const [];
  final declaredIn = <String, Set<String>>{};
  for (final useCase in useCases) {
    declaredIn.putIfAbsent(useCase.name, () => <String>{}).add(useCase.path);
  }
  final mention = RegExp(
    '(?<![\\w\$])(${declaredIn.keys.map(RegExp.escape).join('|')})(?![\\w\$])',
  );
  final violations = <Violation>{};
  for (final path in sources.dartPaths('lib/src/')) {
    if (!_isScannedFile(path)) continue;
    final lexed = sources.lexed(path);
    for (final match in mention.allMatches(lexed.code)) {
      final name = match.group(1)!;
      final declaredAt = declaredIn[name]!;
      if (declaredAt.contains(path)) continue;
      violations.add(
        Violation(
          checkId: id,
          path: path,
          line: lexed.lineOf(match.start),
          detail:
              'mentions the use case `$name` (declared in '
              '${(declaredAt.toList()..sort()).join(', ')}); a use case must '
              'not call another use case, compose the domain services that '
              'upstream barrels publish',
        ),
      );
    }
  }
  return sortedViolations(violations);
}

/// The check function per id, for the registry (`registry.dart`).
const Map<String, List<Violation> Function(SourceSet)> useCaseCallChecks = {
  'FR-097': checkNoUseCaseCalls,
};

/// One minimal violating fixture per check id; the registry merges this map
/// into its own (`registry.dart`, FR-005).
final Map<String, SourceSet Function()> useCaseCallViolatingFixtures = {
  'FR-097': () => SourceSet({
    'lib/src/d20_test/application/resolve_d20_test.dart':
        'class ResolveD20Test {\n  int call() => 1;\n}\n',
    'lib/src/toolbox/application/roll_poison.dart':
        'class RollPoison {\n  int call() => ResolveD20Test().call();\n}\n',
  }),
};
