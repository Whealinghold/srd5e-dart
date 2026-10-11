import '../support/declarations.dart';
import '../support/source_set.dart';
import '../support/violation.dart';

/// The `d20_test` application checks of `doc/specs/resolve-d20-test-use-case.md`.
///
/// The spec's own mechanism ids, as the dice checks of `dice-and-rolls.md` are
/// D1 to D4: R1 is FR-044 (no `String` field or getter in the result
/// declarations under `lib/src/d20_test/`), R2 is FR-045's folder purity for
/// `lib/src/d20_test/application/`.
///
/// Every function is pure: it reads a [SourceSet] and returns [Violation]s.
/// Code is examined through the lexer, so a `String` or a variable named in a
/// comment or a string is not a declaration.
///
/// FR-045's remaining claims are covered by the guardrail checks it cites:
/// `Random(`, `DateTime.now(` and `Stopwatch(` by FR-027 (`banned_calls.dart`,
/// which scans `application/`), an adapter construction by FR-017
/// (`layering.dart`, which bars `adapters/` imports outside the entry point),
/// a recording `Observability` by FR-074 (`testing_layer.dart`, which bars
/// `lib/src/testing/` imports outside `lib/testing.dart`), and a static or
/// top-level variable of an observability type by FR-035 (`noop_classes.dart`).
/// R2 closes the one gap those leave: any other mutable top-level or static
/// state in the folder.

const String _resolveId = 'R1';

const String _purityId = 'R2';

/// The folder whose result declarations R1 scans (FR-044).
const String _contextPrefix = 'lib/src/d20_test/';

/// The folder R2 scans (FR-045).
const String _applicationPrefix = 'lib/src/d20_test/application/';

final RegExp _stringGetter = RegExp(
  r'(?<![\w$.])String\??\s+get\s+([A-Za-z_]\w*)',
);

final RegExp _stringField = RegExp(
  r'(?<![\w$.])String\??\s+(?!get\b|set\b)([A-Za-z_]\w*)\s*(?![\w$(])',
);

final RegExp _staticMutable = RegExp(
  r'(?<![\w$])static\s+(?!(?:const|final)\b)'
  r'[A-Za-z_$][\w$<>,\s?]*\s+[A-Za-z_$][\w$]*\s*(?==|;|$)',
);

final RegExp _topLevelVariable = RegExp(
  r'(?<![\w$])(?:(?:late\s+)?(?:final|var)\b|'
  r'[A-Za-z_$][\w$]*(?:<[^=;{}]*>)?)\s+'
  r'[A-Za-z_$][\w$]*\s*(?==|;|$)',
);

/// The header of a top-level type declaration, blanked before the top-level
/// scan so `final class X` is not read as a variable.
final RegExp _classHeader = RegExp(
  r'(?:(?:abstract|base|final|sealed|interface|mixin)\s+)*'
  r'(?:class|enum|mixin|extension)\s+[A-Za-z_$][\w$]*'
  r'(?:<[^;={}]*>)?'
  r'(?:\s+(?:extends|implements|with|on)\s+[^;={}]*)?',
);

/// The first word of [statement], lower-cased, or the empty string.
String _firstWord(String statement) =>
    RegExp(r'^\s*([A-Za-z_]\w*)').firstMatch(statement)?.group(1) ?? '';

/// The statements of the class body between [start] and [end]: the text at
/// the outermost level, split at `;` and at a `}` that closes a member body.
/// Parameters and nested bodies are blanked.
List<String> _statements(String code, int start, int end) {
  final statements = <String>[];
  final text = StringBuffer();
  var depth = 0;
  for (var i = start + 1; i < end - 1; i++) {
    final c = code[i];
    if (c == '(' || c == '{' || c == '[') {
      if (depth == 0) {
        text.write(c == '(' ? c : ' ');
      }
      depth++;
    } else if (c == ')' || c == '}' || c == ']') {
      depth--;
      if (depth == 0 && c == '}') {
        statements.add(text.toString());
        text.clear();
      } else if (depth == 0 && c == ')') {
        text.write(')');
      }
    } else if (depth == 0) {
      if (c == ';') {
        statements.add(text.toString());
        text.clear();
      } else {
        text.write(c);
      }
    }
  }
  return statements;
}

/// [code] with every balanced `{...}` block replaced by spaces, newlines kept.
String _withoutBlocks(String code) {
  final out = StringBuffer();
  var depth = 0;
  for (var i = 0; i < code.length; i++) {
    final c = code[i];
    if (c == '{') {
      depth++;
      out.write(' ');
    } else if (c == '}') {
      depth--;
      out.write(' ');
    } else {
      out.write(depth == 0 ? c : (c == '\n' ? '\n' : ' '));
    }
  }
  return out.toString();
}

/// Whether [name] names a result declaration of the `d20_test` context: the
/// domain results (`CheckResult`, `AttackRollResult`, `ForcedFailureResult`)
/// and the sealed `ResolveD20TestResult` family.
bool isResultDeclaration(String name) =>
    name.endsWith('Result') ||
    RegExp(r'^ResolveD20Test(Rolled|Forced)').hasMatch(name);

/// R1 (FR-044): no `String` field or getter in the result declarations under
/// `lib/src/d20_test/`. Results carry data, not display text
/// (`doc/rules/architecture.md` §3, §6, §10).
List<Violation> checkResultsCarryNoStrings(SourceSet sources) {
  final violations = <Violation>[];
  for (final path in sources.dartPaths(_contextPrefix)) {
    final lexed = sources.lexed(path);
    for (final declaration in declarationsIn(path, lexed)) {
      if (declaration.kind != DeclarationKind.classDeclaration) continue;
      if (!isResultDeclaration(declaration.name)) continue;
      for (final statement in _statements(
        lexed.code,
        declaration.bodyStart,
        declaration.bodyEnd,
      )) {
        for (final match in _stringGetter.allMatches(statement)) {
          violations.add(
            Violation(
              checkId: _resolveId,
              path: path,
              line: lexed.lineOf(
                declaration.bodyStart + _statementOffset(statement, match),
              ),
              detail:
                  '${declaration.name} has the String getter '
                  '`get ${match.group(1)}`; a result carries data, not '
                  'display text',
            ),
          );
        }
        for (final match in _stringField.allMatches(statement)) {
          violations.add(
            Violation(
              checkId: _resolveId,
              path: path,
              line: lexed.lineOf(
                declaration.bodyStart + _statementOffset(statement, match),
              ),
              detail:
                  '${declaration.name} has the String field '
                  '`${match.group(1)}`; a result carries data, not display '
                  'text',
            ),
          );
        }
      }
    }
  }
  return sortedViolations(violations);
}

/// The offset of [match] within [statement] itself is unavailable after the
/// split, so a stable line is approximated by counting the newlines of the
/// statement text before the match.
int _statementOffset(String statement, RegExpMatch match) {
  final index = statement.indexOf(match.group(0)!);
  return index < 0 ? 0 : index;
}

/// R2 (FR-045): no non-`const` top-level variable and no `static` mutable
/// field in `lib/src/d20_test/application/` — the folder holds no hidden
/// mutable state (doc/rules/architecture.md §3, §4, §9).
List<Violation> checkApplicationFolderPurity(SourceSet sources) {
  final violations = <Violation>[];
  for (final path in sources.dartPaths(_applicationPrefix)) {
    final lexed = sources.lexed(path);
    for (final declaration in declarationsIn(path, lexed)) {
      for (final statement in _statements(
        lexed.code,
        declaration.bodyStart,
        declaration.bodyEnd,
      )) {
        for (final match in _staticMutable.allMatches(statement)) {
          violations.add(
            Violation(
              checkId: _purityId,
              path: path,
              line: lexed.lineOf(
                declaration.bodyStart + _statementOffset(statement, match),
              ),
              detail:
                  'a static mutable field (`${match.group(0)}`) in '
                  'application/; the use case holds no hidden mutable state',
            ),
          );
        }
      }
    }
    // Top-level variables: the type-declaration headers are blanked at their
    // own offsets and every block is blanked one char per char, so offsets
    // still line up with the lexed code and the line of a match is exact.
    final blanked = _withoutBlocks(
      lexed.code.replaceAllMapped(
        _classHeader,
        (match) => ' ' * (match.end - match.start),
      ),
    );
    var at = 0;
    for (final statement in blanked.split(';')) {
      final start = at;
      at += statement.length + 1;
      final word = _firstWord(statement);
      if (const {
        'import',
        'export',
        'library',
        'part',
        'typedef',
        'const',
      }.contains(word)) {
        continue;
      }
      for (final match in _topLevelVariable.allMatches(statement)) {
        violations.add(
          Violation(
            checkId: _purityId,
            path: path,
            line: lexed.lineOf(start + match.start),
            detail:
                'a non-const top-level variable in application/; the folder '
                'holds no hidden mutable state',
          ),
        );
      }
    }
  }
  return sortedViolations(violations);
}

/// Both checks of the resolve spec, for the registry-shaped consumers of this
/// suite (the real-repository test and the self-test).
List<Violation> checkResolveConventions(SourceSet sources) => [
  ...checkResultsCarryNoStrings(sources),
  ...checkApplicationFolderPurity(sources),
];
