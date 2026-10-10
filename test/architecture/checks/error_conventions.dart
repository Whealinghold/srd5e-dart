import '../support/declarations.dart';
import '../support/names.dart';
import '../support/source_set.dart';
import '../support/violation.dart';

/// Architecture checks E1 to E8 of `doc/specs/errors-and-results.md` and the
/// spec-set scan of its FR-053.
///
/// Every function is pure: it reads a [SourceSet] and returns [Violation]s.

/// The root exception type.
const String rootExceptionName = 'Srd5eException';

/// Where the root is declared.
const String rootExceptionPath =
    'lib/src/shared_ports/errors/srd5e_exception.dart';

/// Names a field or getter of a failure or result type must not have: display
/// text belongs to the consumer.
const Set<String> displayTextNames = {
  'message',
  'description',
  'text',
  'displayText',
};

/// Path prefixes whose declarations are exempt from the display-text rule for
/// result, rejection and problem types: verbatim SRD content value objects and
/// telemetry descriptor classes (doc/specs/errors-and-results.md FR-020).
const List<String> displayTextExemptPrefixes = [
  'lib/src/content/domain/',
  'lib/src/shared_ports/observability/',
];

/// A registered concrete subtype: its class name and its `errorType` value.
typedef RegisteredSubtype = ({String className, String errorType});

/// All class, enum and mixin declarations under `lib/`.
List<Declaration> _libDeclarations(SourceSet sources) => [
  for (final path in sources.dartPaths('lib/'))
    ...declarationsIn(path, sources.lexed(path)),
];

/// Names of every class that extends or implements [rootExceptionName],
/// directly or through other declarations.
Set<String> _exceptionNames(List<Declaration> declarations) {
  final names = <String>{rootExceptionName};
  var grew = true;
  while (grew) {
    grew = false;
    for (final declaration in declarations) {
      if (!names.contains(declaration.name) &&
          declaration.supertypes.any(names.contains)) {
        names.add(declaration.name);
        grew = true;
      }
    }
  }
  return names;
}

/// E1 (FR-001, FR-002, FR-005, FR-006, FR-049, FR-050): the root is an
/// `abstract base class` with an `@internal` constructor, every class that
/// extends it is `final` and in [registry], and the registry's `errorType`
/// values are distinct snake_case names of their classes.
List<Violation> checkExceptionRegistry(
  SourceSet sources,
  List<RegisteredSubtype> registry,
) {
  const id = 'E1';
  final violations = <Violation>[];
  final declarations = _libDeclarations(sources);
  final roots = declarations.where((d) => d.name == rootExceptionName);

  if (roots.isEmpty) {
    if (sources.dartPaths('lib/src/').isNotEmpty) {
      violations.add(
        const Violation(
          checkId: id,
          path: rootExceptionPath,
          line: 1,
          detail: '$rootExceptionName is not declared under lib/.',
        ),
      );
    }
  } else {
    final root = roots.first;
    if (!root.modifiers.containsAll({'abstract', 'base'}) ||
        root.modifiers.contains('sealed')) {
      violations.add(
        Violation(
          checkId: id,
          path: root.path,
          line: root.line,
          detail:
              '$rootExceptionName must be an `abstract base class` and not '
              '`sealed` (found: ${(root.modifiers.toList()..sort()).join(' ')}).',
        ),
      );
    }
    final code = sources.lexed(root.path).code;
    if (!RegExp(
      '@internal\\s+const\\s+$rootExceptionName\\s*\\(',
    ).hasMatch(code)) {
      violations.add(
        Violation(
          checkId: id,
          path: root.path,
          line: root.line,
          detail:
              'The $rootExceptionName constructor must be `const` and '
              'annotated `@internal`.',
        ),
      );
    }
  }

  final registered = {for (final entry in registry) entry.className};
  final declared = <String>{};
  for (final declaration in declarations) {
    if (declaration.name == rootExceptionName ||
        declaration.extendsName != rootExceptionName) {
      continue;
    }
    declared.add(declaration.name);
    if (!registered.contains(declaration.name)) {
      violations.add(
        Violation(
          checkId: id,
          path: declaration.path,
          line: declaration.line,
          detail:
              '${declaration.name} extends $rootExceptionName but is not in '
              'the exception registry.',
        ),
      );
    }
    if (!declaration.modifiers.contains('final')) {
      violations.add(
        Violation(
          checkId: id,
          path: declaration.path,
          line: declaration.line,
          detail:
              '${declaration.name} extends $rootExceptionName and must be a '
              '`final class`.',
        ),
      );
    }
  }

  const registryPath = 'test/architecture/support/exception_registry.dart';
  final seen = <String, String>{};
  for (final entry in registry) {
    if (!declared.contains(entry.className)) {
      violations.add(
        Violation(
          checkId: id,
          path: registryPath,
          line: 1,
          detail:
              '${entry.className} is registered but no class of that name '
              'extends $rootExceptionName under lib/.',
        ),
      );
    }
    if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(entry.errorType) ||
        entry.errorType != snakeCase(entry.className)) {
      violations.add(
        Violation(
          checkId: id,
          path: registryPath,
          line: 1,
          detail:
              '${entry.className}.errorType is "${entry.errorType}", expected '
              '"${snakeCase(entry.className)}".',
        ),
      );
    }
    final other = seen[entry.errorType];
    if (other != null) {
      violations.add(
        Violation(
          checkId: id,
          path: registryPath,
          line: 1,
          detail:
              '${entry.className} and $other share the errorType '
              '"${entry.errorType}".',
        ),
      );
    }
    seen.putIfAbsent(entry.errorType, () => entry.className);
  }
  return sortedViolations(violations);
}

/// E2 (FR-007, FR-020): no field or getter named `message`, `description`,
/// `text` or `displayText` on an `Srd5eException` subtype, a sealed
/// `<UseCase>Result` class or variant, or a rejection or problem type.
List<Violation> checkNoDisplayText(SourceSet sources) {
  const id = 'E2';
  final declarations = _libDeclarations(sources);
  final exceptionNames = _exceptionNames(declarations);
  final sealedResults = {
    for (final d in declarations)
      if (d.modifiers.contains('sealed') && d.name.endsWith('Result')) d.name,
  };
  final violations = <Violation>[];
  for (final declaration in declarations) {
    final isException = exceptionNames.contains(declaration.name);
    final exempt = displayTextExemptPrefixes.any(declaration.path.startsWith);
    final isResultType =
        sealedResults.contains(declaration.name) ||
        declaration.supertypes.any(sealedResults.contains);
    final isRejectionOrProblem =
        declaration.name.endsWith('Rejection') ||
        declaration.name.endsWith('Problem');
    final inScope =
        isException || (!exempt && (isResultType || isRejectionOrProblem));
    if (!inScope) continue;
    for (final member in declaration.memberNames) {
      if (displayTextNames.contains(member.name)) {
        violations.add(
          Violation(
            checkId: id,
            path: declaration.path,
            line: member.line,
            detail:
                '${declaration.name} declares `${member.name}`; carry typed '
                'data, not display text.',
          ),
        );
      }
    }
  }
  return sortedViolations(violations);
}

/// E3 (FR-029): the exception root, its subtypes and the guards are not named
/// in the code of any `domain/` file.
List<Violation> checkDomainDoesNotUseErrors(SourceSet sources) {
  const id = 'E3';
  final denied = {
    ..._exceptionNames(_libDeclarations(sources)),
    'wrapPortFailure',
    'wrapPortFailureAsync',
  };
  final violations = <Violation>[];
  for (final path in sources.dartPaths('lib/')) {
    if (!path.contains('/domain/')) continue;
    final lexed = sources.lexed(path);
    for (final match in RegExp(r'[A-Za-z_$][\w$]*').allMatches(lexed.code)) {
      if (denied.contains(match.group(0))) {
        violations.add(
          Violation(
            checkId: id,
            path: path,
            line: lexed.lineOf(match.start),
            detail:
                'domain code must not name `${match.group(0)}`; report '
                'expected outcomes as results.',
          ),
        );
      }
    }
  }
  return sortedViolations(violations);
}

/// One `catch` or `on` clause of a `try` statement.
typedef _CatchClause = ({String? type, String body, int offset});

/// E4 (FR-030, FR-046, FR-047): every `catch` clause under `lib/` has an `on`
/// type matching `\w*Exception`, except a clause whose last statement is an
/// unconditional `rethrow;`.
List<Violation> checkCatchClauses(SourceSet sources) {
  const id = 'E4';
  final violations = <Violation>[];
  for (final path in sources.dartPaths('lib/')) {
    final lexed = sources.lexed(path);
    for (final clause in _catchClauses(lexed.code)) {
      final type = clause.type;
      final allowedType =
          type != null &&
          RegExp(r'^(?:\w+\.)?\w*Exception$').hasMatch(_plainType(type));
      if (allowedType || _endsInRethrow(clause.body)) continue;
      violations.add(
        Violation(
          checkId: id,
          path: path,
          line: lexed.lineOf(clause.offset),
          detail: type == null
              ? 'A catch clause needs an `on` type matching \\w*Exception.'
              : '`on $type` does not match \\w*Exception and the clause '
                    'does not end in `rethrow;`.',
        ),
      );
    }
  }
  return sortedViolations(violations);
}

String _plainType(String type) =>
    type.replaceAll(RegExp(r'<.*>'), '').replaceAll('?', '').trim();

bool _endsInRethrow(String body) {
  final trimmed = body.trim();
  if (!trimmed.endsWith('rethrow;')) return false;
  final before = trimmed
      .substring(0, trimmed.length - 'rethrow;'.length)
      .trimRight();
  return before.isEmpty || before.endsWith(';') || before.endsWith('}');
}

List<_CatchClause> _catchClauses(String code) {
  final onClause = RegExp(r'on\s');
  final catchKeyword = RegExp(r'catch(?![\w$])');
  final typeEnd = RegExp(r'(?<![\w$])catch(?![\w$])|\{');
  final clauses = <_CatchClause>[];
  for (final match in RegExp(r'(?<![\w$])try\s*\{').allMatches(code)) {
    var position = _matchingBrace(code, match.end - 1);
    while (true) {
      var start = position;
      while (start < code.length && code[start].trim().isEmpty) {
        start++;
      }
      String? type;
      var cursor = start;
      if (onClause.matchAsPrefix(code, start) != null) {
        final typeStart = start + 2;
        final end = typeEnd.firstMatch(code.substring(typeStart));
        if (end == null) break;
        type = code.substring(typeStart, typeStart + end.start).trim();
        cursor = typeStart + end.start;
      } else if (catchKeyword.matchAsPrefix(code, start) == null) {
        break; // `finally`, or the end of the statement
      }
      if (catchKeyword.matchAsPrefix(code, cursor) != null) {
        final open = code.indexOf('(', cursor);
        if (open == -1) break;
        cursor = _matching(code, open, '(', ')');
      }
      final bodyOpen = code.indexOf('{', cursor);
      if (bodyOpen == -1) break;
      final bodyEnd = _matchingBrace(code, bodyOpen);
      clauses.add((
        type: type,
        body: code.substring(bodyOpen + 1, bodyEnd - 1),
        offset: start,
      ));
      position = bodyEnd;
    }
  }
  return clauses;
}

int _matchingBrace(String code, int open) => _matching(code, open, '{', '}');

/// Offset just after the bracket that closes the one at [open].
int _matching(String code, int open, String opener, String closer) {
  var depth = 0;
  for (var i = open; i < code.length; i++) {
    if (code[i] == opener) {
      depth++;
    } else if (code[i] == closer) {
      depth--;
      if (depth == 0) return i + 1;
    }
  }
  return code.length;
}

/// E5 (FR-034): the `error.type` key (`AttributeKeys.errorType`) is only given
/// a value read from an `.errorType` getter, and an `application/` file that
/// mentions it does not use `runtimeType` or `toString(`.
List<Violation> checkErrorTypeAttribute(SourceSet sources) {
  const id = 'E5';
  final violations = <Violation>[];
  final assignment = RegExp(r'AttributeKeys\.errorType\s*:\s*');
  for (final path in sources.dartPaths('lib/')) {
    final lexed = sources.lexed(path);
    final code = lexed.code;
    for (final match in assignment.allMatches(code)) {
      final value = _expressionAt(code, match.end);
      if (!RegExp(
        r'^[\w$]+(?:[?!]?\.[\w$]+)*[?!]?\.errorType$',
      ).hasMatch(value)) {
        violations.add(
          Violation(
            checkId: id,
            path: path,
            line: lexed.lineOf(match.start),
            detail:
                'error.type is set from `$value`; use the exception\'s '
                '`.errorType` getter.',
          ),
        );
      }
    }
    if (path.contains('/application/') &&
        code.contains('AttributeKeys.errorType')) {
      for (final banned in RegExp(
        r'(?<![\w$])runtimeType(?![\w$])|(?<![\w$])toString\s*\(',
      ).allMatches(code)) {
        violations.add(
          Violation(
            checkId: id,
            path: path,
            line: lexed.lineOf(banned.start),
            detail:
                '`${banned.group(0)!.trim()}` is banned in a file that sets '
                'error.type.',
          ),
        );
      }
    }
  }
  return sortedViolations(violations);
}

/// The expression text starting at [start] up to the first top-level `,`, `}`
/// or `)`.
String _expressionAt(String code, int start) {
  var depth = 0;
  var i = start;
  for (; i < code.length; i++) {
    final c = code[i];
    if (c == '(' || c == '[' || c == '{') {
      depth++;
    } else if (c == ')' || c == ']' || c == '}') {
      if (depth == 0) break;
      depth--;
    } else if (c == ',' && depth == 0) {
      break;
    }
  }
  return code.substring(start, i).trim();
}

/// E6 (FR-018, FR-044): every `sealed class` under `lib/src` has only `final`
/// or `sealed` direct subtypes.
List<Violation> checkSealedSubtypes(SourceSet sources) {
  const id = 'E6';
  final declarations = _libDeclarations(
    sources,
  ).where((d) => d.path.startsWith('lib/src/')).toList();
  final sealedNames = {
    for (final d in declarations)
      if (d.kind == DeclarationKind.classDeclaration &&
          d.modifiers.contains('sealed'))
        d.name,
  };
  final violations = <Violation>[];
  for (final declaration in declarations) {
    if (declaration.kind != DeclarationKind.classDeclaration) continue;
    final parents = declaration.supertypes.where(sealedNames.contains);
    if (parents.isEmpty) continue;
    if (!declaration.modifiers.contains('final') &&
        !declaration.modifiers.contains('sealed')) {
      violations.add(
        Violation(
          checkId: id,
          path: declaration.path,
          line: declaration.line,
          detail:
              '${declaration.name} is a direct subtype of sealed '
              '${parents.first} and must be `final` or `sealed`.',
        ),
      );
    }
  }
  return sortedViolations(violations);
}

/// E7 (FR-048): `catchError`, `onError` and `runZonedGuarded` do not appear in
/// the code under `lib/`.
List<Violation> checkNoCatchBypass(SourceSet sources) {
  const id = 'E7';
  final violations = <Violation>[];
  final banned = RegExp(
    r'(?<![\w$])(catchError|onError|runZonedGuarded)(?![\w$])',
  );
  for (final path in sources.dartPaths('lib/')) {
    final lexed = sources.lexed(path);
    for (final match in banned.allMatches(lexed.code)) {
      violations.add(
        Violation(
          checkId: id,
          path: path,
          line: lexed.lineOf(match.start),
          detail:
              '`${match.group(1)}` bypasses the `on` type rules; use '
              'try/on/catch.',
        ),
      );
    }
  }
  return sortedViolations(violations);
}

/// E8 (FR-052): a `wrapPortFailure(` call whose first argument closure is
/// `async`, contains `await`, or whose type argument starts with `Future<`.
List<Violation> checkSyncGuardIsSync(SourceSet sources) {
  const id = 'E8';
  final violations = <Violation>[];
  final call = RegExp(r'(?<![\w$.])wrapPortFailure\s*(<[^()]*?>)?\s*\(');
  for (final path in sources.dartPaths('lib/')) {
    final lexed = sources.lexed(path);
    final code = lexed.code;
    for (final match in call.allMatches(code)) {
      if (_isDeclaration(code, match.start)) continue;
      final typeArgument = match.group(1) ?? '';
      final argument = _expressionAt(code, match.end);
      final reason = RegExp(r'<\s*Future<').hasMatch(typeArgument)
          ? 'has a Future<...> type argument'
          : RegExp(r'(?<![\w$])async(?![\w$])').hasMatch(argument)
          ? 'has an async closure'
          : RegExp(r'(?<![\w$])await(?![\w$])').hasMatch(argument)
          ? 'awaits inside the closure'
          : null;
      if (reason != null) {
        violations.add(
          Violation(
            checkId: id,
            path: path,
            line: lexed.lineOf(match.start),
            detail:
                'wrapPortFailure $reason; use wrapPortFailureAsync for a '
                'Future-returning body.',
          ),
        );
      }
    }
  }
  return sortedViolations(violations);
}

/// Whether the identifier at [offset] is preceded by a return type, which
/// makes it a declaration rather than a call.
bool _isDeclaration(String code, int offset) {
  final before = code.substring(0, offset).trimRight();
  if (before.isEmpty) return false;
  final last = before[before.length - 1];
  if (last == '>') return !before.endsWith('=>');
  if (!RegExp(r'[\w$]').hasMatch(last)) return false;
  final word = RegExp(r'[\w$]+$').firstMatch(before)!.group(0)!;
  return !const {
    'return',
    'await',
    'yield',
    'else',
    'in',
    'case',
    'do',
  }.contains(word);
}

/// The spec FR ids a use-case spec's test plan must cover (FR-053).
const List<String> useCaseSpecRequiredIds = ['FR-031', 'FR-034', 'FR-051'];

/// FR-053: the test plan of every use-case spec (one whose section 7 names a
/// `srd5e.<context>.<operation>` span) has a row for each of FR-031, FR-034
/// and FR-051 of `errors-and-results.md`, or states that it calls no port.
List<Violation> checkUseCaseSpecRows(SourceSet sources) {
  const id = 'FR-053';
  final violations = <Violation>[];
  for (final path in sources.paths(prefix: 'doc/specs/', suffix: '.md')) {
    final name = path.substring('doc/specs/'.length);
    if (name.startsWith('_') || name.contains('/')) continue;
    final lines = sources.files[path]!.split('\n');
    final observability = _section(lines, 7);
    final testPlan = _section(lines, 8);
    final definesSpan = observability.lines.any(
      (line) =>
          RegExp(r'`srd5e\.[a-z0-9_]+\.[a-z0-9_]+`').hasMatch(line) &&
          RegExp('span', caseSensitive: false).hasMatch(line),
    );
    if (!definesSpan) continue;
    if (testPlan.lines.any(
      (line) => RegExp('calls? no port', caseSensitive: false).hasMatch(line),
    )) {
      continue;
    }
    for (final required in useCaseSpecRequiredIds) {
      final covered = testPlan.lines.any(
        (line) =>
            line.contains('errors-and-results.md') && line.contains(required),
      );
      if (!covered) {
        violations.add(
          Violation(
            checkId: id,
            path: path,
            line: testPlan.headingLine,
            detail:
                'The test plan has no row for errors-and-results.md '
                '$required and does not state that the use case calls no '
                'port.',
          ),
        );
      }
    }
  }
  return sortedViolations(violations);
}

({List<String> lines, int headingLine}) _section(
  List<String> lines,
  int number,
) {
  final heading = RegExp('^## $number\\. ');
  final start = lines.indexWhere(heading.hasMatch);
  if (start == -1) return (lines: const [], headingLine: 1);
  var end = lines.length;
  for (var i = start + 1; i < lines.length; i++) {
    if (lines[i].startsWith('## ')) {
      end = i;
      break;
    }
  }
  return (lines: lines.sublist(start + 1, end), headingLine: start + 1);
}
