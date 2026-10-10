import '../support/declarations.dart';
import '../support/lexer.dart';
import '../support/source_set.dart';
import '../support/violation.dart';
import 'domain_observability.dart';
import 'platform_imports.dart' show hasAdaptersFolder;

/// No-op and global-state checks FR-035, FR-084 and FR-104 of
/// `doc/specs/architecture-guardrails.md` (sections 4.2 and 4.3).
///
/// Every function is pure: it reads a [SourceSet] and returns [Violation]s.
/// They read the lexer's code (FR-008), so comments and strings are ignored.

/// Where every `Noop*` class lives (FR-084): under this folder and outside any
/// `adapters/` folder.
const String sharedPortsPrefix = 'lib/src/shared_ports/';

/// The one folder that holds `Observability` and `NoopObservability` (FR-104).
const String observabilityPrefix = 'lib/src/shared_ports/observability/';

/// A statement of a declaration body: its code text with nested bodies
/// removed, and the offset of its first non-blank character.
typedef BodyStatement = ({String text, int offset});

final RegExp _literalOpener = RegExp(r'=\s*(?:const\s*)?(?:<[^{};]*>\s*)?$');

/// Splits the lexed [code] between [start] and [end] into statements at depth
/// zero: at `;` and after the closing `}` of a nested body. Parentheses and
/// brackets are kept whole (named-parameter braces stay inside them), and a
/// `{` that follows `=` is a collection literal that stays in the statement.
List<BodyStatement> bodyStatements(String code, int start, int end) {
  final statements = <BodyStatement>[];
  final text = StringBuffer();
  int? first;
  var braces = 0;
  var parens = 0;
  var literal = 0;
  void write(String char, int offset) {
    if (first == null && char.trim().isNotEmpty) first = offset;
    text.write(char);
  }

  void flush() {
    final body = text.toString();
    if (body.trim().isNotEmpty) {
      statements.add((text: body, offset: first ?? start));
    }
    text.clear();
    first = null;
  }

  for (var i = start; i < end; i++) {
    final c = code[i];
    if (braces > 0) {
      if (c == '{') braces++;
      if (c == '}') {
        braces--;
        if (braces == 0) flush();
      }
      continue;
    }
    if (parens > 0) {
      if (c == '(' || c == '[') parens++;
      if (c == ')' || c == ']') parens--;
      write(c, i);
      continue;
    }
    if (literal > 0) {
      if (c == '{') literal++;
      if (c == '}') literal--;
      write(c, i);
      continue;
    }
    if (c == '(' || c == '[') {
      parens++;
      write(c, i);
    } else if (c == '{') {
      if (_literalOpener.hasMatch(text.toString())) {
        literal++;
        write(c, i);
      } else {
        braces++;
        write(' ', i);
      }
    } else if (c == ';') {
      flush();
    } else {
      write(c, i);
    }
  }
  flush();
  return statements;
}

final RegExp _annotation = RegExp(
  r'@\s*(?:[\w$]+\s*\.\s*)?[\w$]+(?:\s*\.\s*[\w$]+)?(?:\s*\([^()]*\))?',
);

/// [text] without leading annotations (`@override`, `@Deprecated('x')`).
String withoutAnnotations(String text) {
  var rest = text.trimLeft();
  while (rest.startsWith('@')) {
    final match = _annotation.matchAsPrefix(rest);
    if (match == null) break;
    rest = rest.substring(match.end).trimLeft();
  }
  return rest;
}

/// One constructor found in a class body.
typedef ClassConstructor = ({bool isConst, int line});

/// The constructors declared in the body of [declaration], from [lexed].
List<ClassConstructor> constructorsOf(
  Declaration declaration,
  LexResult lexed,
) {
  final pattern = RegExp(
    '^(?:external\\s+)?(?:(const)\\s+)?(?:factory\\s+)?(?:(const)\\s+)?'
    '${RegExp.escape(declaration.name)}(?:\\s*\\.\\s*[\\w\$]+)?\\s*\\(',
  );
  return [
    for (final statement in bodyStatements(
      lexed.code,
      declaration.bodyStart + 1,
      declaration.bodyEnd - 1,
    ))
      if (pattern.firstMatch(withoutAnnotations(statement.text))
          case final match?)
        (
          isConst: match.group(1) != null || match.group(2) != null,
          line: lexed.lineOf(statement.offset),
        ),
  ];
}

/// Every class declaration of the Dart files of [sources] under [prefix] whose
/// text contains [needle], with the lexed code of its file.
Iterable<({Declaration declaration, LexResult lexed})> _declarations(
  SourceSet sources,
  String prefix,
  String needle,
) sync* {
  for (final path in sources.dartPaths(prefix)) {
    if (!sources.files[path]!.contains(needle)) continue;
    final lexed = sources.lexed(path);
    for (final declaration in declarationsIn(path, lexed)) {
      if (declaration.kind == DeclarationKind.classDeclaration) {
        yield (declaration: declaration, lexed: lexed);
      }
    }
  }
}

/// FR-084: every class whose name starts with `Noop` is declared under
/// `lib/src/shared_ports/` and outside any `adapters/` folder, has at least
/// one constructor, and has only `const` constructors.
List<Violation> checkNoopClasses(SourceSet sources) {
  const id = 'FR-084';
  final violations = <Violation>[];
  for (final (:declaration, :lexed) in _declarations(sources, 'lib/', 'Noop')) {
    if (!declaration.name.startsWith('Noop')) continue;
    final path = declaration.path;
    if (!path.startsWith(sharedPortsPrefix) || hasAdaptersFolder(path)) {
      violations.add(
        Violation(
          checkId: id,
          path: path,
          line: declaration.line,
          detail:
              '${declaration.name} is declared outside lib/src/shared_ports/ '
              '(or under an adapters/ folder); no-ops live beside the ports',
        ),
      );
    }
    final constructors = constructorsOf(declaration, lexed);
    if (constructors.isEmpty) {
      violations.add(
        Violation(
          checkId: id,
          path: path,
          line: declaration.line,
          detail:
              '${declaration.name} declares no constructor; a no-op needs an '
              'explicit const one',
        ),
      );
    }
    for (final constructor in constructors.where((c) => !c.isConst)) {
      violations.add(
        Violation(
          checkId: id,
          path: path,
          line: constructor.line,
          detail:
              '${declaration.name} has a constructor that is not const; a '
              'no-op is stateless and const',
        ),
      );
    }
  }
  return sortedViolations(violations);
}

/// Whether the declaration of [name] in [lexed] code is annotated
/// `@immutable`.
bool _isImmutable(LexResult lexed, String name) {
  final match = RegExp(
    r'(?<![\w$])(?:(?:abstract|base|final|sealed|interface|mixin)\s+)*'
    'class\\s+${RegExp.escape(name)}(?![\\w\$])',
  ).firstMatch(lexed.code);
  if (match == null) return false;
  var before = lexed.code.substring(0, match.start).trimRight();
  final trailing = RegExp(
    r'@\s*(?:[\w$]+\s*\.\s*)?([\w$]+)(?:\s*\([^()]*\))?$',
  );
  while (true) {
    final annotation = trailing.firstMatch(before);
    if (annotation == null) return false;
    if (annotation.group(1) == 'immutable') return true;
    before = before.substring(0, annotation.start).trimRight();
  }
}

/// FR-104: `Observability` and `NoopObservability` are each a `final class`
/// declared in the same file under `lib/src/shared_ports/observability/`;
/// `Observability` carries `@immutable`; `NoopObservability` extends it and
/// has only `const` constructors. When either is declared, both must be.
List<Violation> checkObservabilityClasses(SourceSet sources) {
  const id = 'FR-104';
  const bundle = 'Observability';
  const noop = 'NoopObservability';
  final found = [
    for (final entry in _declarations(sources, 'lib/', bundle))
      if (const {bundle, noop}.contains(entry.declaration.name)) entry,
  ];
  if (found.isEmpty) return const [];
  final violations = <Violation>[];
  void add(Declaration declaration, String detail) => violations.add(
    Violation(
      checkId: id,
      path: declaration.path,
      line: declaration.line,
      detail: detail,
    ),
  );
  for (final (:declaration, :lexed) in found) {
    final name = declaration.name;
    if (!declaration.modifiers.contains('final')) {
      add(
        declaration,
        '$name is not a final class; final blocks every other extends or '
        'implements',
      );
    }
    if (!declaration.path.startsWith(observabilityPrefix)) {
      add(declaration, '$name is declared outside $observabilityPrefix');
    }
    if (name == bundle && !_isImmutable(lexed, bundle)) {
      add(declaration, '$bundle lacks @immutable');
    }
    if (name == noop) {
      if (declaration.extendsName != bundle) {
        add(declaration, '$noop does not extend $bundle');
      }
      for (final c in constructorsOf(
        declaration,
        lexed,
      ).where((c) => !c.isConst)) {
        violations.add(
          Violation(
            checkId: id,
            path: declaration.path,
            line: c.line,
            detail: '$noop has a constructor that is not const',
          ),
        );
      }
    }
  }
  final bundles = found.where((e) => e.declaration.name == bundle).toList();
  final noops = found.where((e) => e.declaration.name == noop).toList();
  if (bundles.isEmpty) {
    add(noops.first.declaration, '$bundle is not declared beside $noop');
  } else if (noops.isEmpty) {
    add(bundles.first.declaration, '$noop is not declared beside $bundle');
  } else {
    final bundlePaths = {for (final e in bundles) e.declaration.path};
    for (final e in noops) {
      if (!bundlePaths.contains(e.declaration.path)) {
        add(
          e.declaration,
          '$noop is declared in a different file from $bundle; the two '
          'must share one library so final allows the subclass',
        );
      }
    }
  }
  return sortedViolations(violations);
}

final RegExp _identifier = RegExp(r'[A-Za-z_$][\w$]*');
final RegExp _notAVariable = RegExp(
  r'^(?:(?:abstract|base|final|sealed|interface|mixin)\s+)*'
  r'(?:class|enum|mixin|extension|typedef|import|export|part|library)\b',
);

/// The text before the first plain `=` of [statement] (not `==`, `=>`, `<=`,
/// `>=` or `!=`), and the text after it; the second is empty when there is no
/// initialiser.
({String head, String initialiser}) _splitAtAssignment(String statement) {
  for (var i = 0; i < statement.length; i++) {
    if (statement[i] != '=') continue;
    final before = i > 0 ? statement[i - 1] : '';
    final after = i + 1 < statement.length ? statement[i + 1] : '';
    if (after == '=' ||
        after == '>' ||
        '<>!='.contains(before) && before != '') {
      continue;
    }
    return (
      head: statement.substring(0, i),
      initialiser: statement.substring(i + 1),
    );
  }
  return (head: statement, initialiser: '');
}

bool _mentionsObservability(String text) => _identifier
    .allMatches(text)
    .any((m) => endsInObservabilityWord(m.group(0)!));

/// FR-035: a top-level or `static` variable whose declared type or initialiser
/// names a `Logger`, `Tracer`, `Meter` or `Observability` type is a Violation
/// unless it is `const` (a stateless no-op default).
List<Violation> checkNoGlobalObservability(SourceSet sources) {
  const id = 'FR-035';
  final violations = <Violation>[];
  void inspect(
    LexResult lexed,
    String path,
    BodyStatement statement, {
    required bool requireStatic,
  }) {
    final text = withoutAnnotations(statement.text);
    if (_notAVariable.hasMatch(text)) return;
    final (:head, :initialiser) = _splitAtAssignment(text);
    final words = _identifier.allMatches(head).map((m) => m.group(0)!).toSet();
    if (head.contains('(') || words.contains('get') || words.contains('set')) {
      return;
    }
    if (requireStatic && !words.contains('static')) return;
    if (words.contains('const')) return;
    if (!_mentionsObservability(head) && !_mentionsObservability(initialiser)) {
      return;
    }
    violations.add(
      Violation(
        checkId: id,
        path: path,
        line: lexed.lineOf(statement.offset),
        detail:
            'a ${requireStatic ? 'static' : 'top-level'} variable holds a '
            'logger, tracer, meter or observability bundle; only a const '
            'no-op is allowed',
      ),
    );
  }

  for (final path in sources.dartPaths('lib/')) {
    final text = sources.files[path]!;
    if (!observabilityWords.any(text.contains)) continue;
    final lexed = sources.lexed(path);
    for (final statement in bodyStatements(lexed.code, 0, lexed.code.length)) {
      inspect(lexed, path, statement, requireStatic: false);
    }
    for (final declaration in declarationsIn(path, lexed)) {
      for (final statement in bodyStatements(
        lexed.code,
        declaration.bodyStart + 1,
        declaration.bodyEnd - 1,
      )) {
        inspect(lexed, path, statement, requireStatic: true);
      }
    }
  }
  return sortedViolations(violations);
}

/// The check function per id, for the registry (`registry.dart`).
const Map<String, List<Violation> Function(SourceSet)> noopClassesChecks = {
  'FR-035': checkNoGlobalObservability,
  'FR-084': checkNoopClasses,
  'FR-104': checkObservabilityClasses,
};

/// One minimal violating fixture per check id; the registry merges this map
/// into its own (`registry.dart`, FR-005).
final Map<String, SourceSet Function()> noopClassesViolatingFixtures = {
  'FR-035': () => SourceSet({
    'lib/src/d20_test/application/a.dart':
        'class A {\n  static final Logger shared = NoopLogger();\n}\n',
  }),
  'FR-084': () => SourceSet({
    'lib/src/shared_ports/observability/logger.dart':
        'final class NoopLogger {\n  NoopLogger();\n}\n',
  }),
  'FR-104': () => SourceSet({
    'lib/src/shared_ports/observability/observability.dart':
        'class Observability {\n  const Observability();\n}\n'
        'final class NoopObservability extends Observability {\n'
        '  const NoopObservability();\n}\n',
  }),
};
