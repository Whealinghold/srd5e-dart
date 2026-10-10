import '../support/constants.dart' as constants;
import '../support/declarations.dart';
import '../support/lexer.dart';
import '../support/markdown_tables.dart';
import '../support/names.dart';
import '../support/source_set.dart';
import '../support/violation.dart';

/// Shared attribute value check FR-085 of
/// `doc/specs/architecture-guardrails.md` (section 4.3).
///
/// Every function is pure: it reads a [SourceSet] and returns [Violation]s.
/// Code is examined through the lexer (FR-008), so a member named in a comment
/// or a string is not a declaration. The closed value sets are the named
/// constants `constants.sharedAttributeValueSets` (FR-009).

const String _id = 'FR-085';

const String _cataloguePath = 'doc/observability/signals.md';

final RegExp _staticConstString = RegExp(
  r'(?<![\w$])static\s+const\s+String\s+([A-Za-z_]\w*)\s*=\s*',
);

final RegExp _backticked = RegExp(r'`([^`]+)`');

final RegExp _otherKey = RegExp(r'^[a-z][a-z0-9_]*(\.[a-z0-9_]+)+$');

final RegExp _snakeValue = RegExp(r'^[a-z][a-z0-9_]*$');

final RegExp _catalogueKeyWithValues = RegExp(r'`([^`]+)`\s*\(([^)]*)\)');

bool _isSignalsClass(String name) =>
    name.endsWith('Signals') || name == 'AttributeKeys';

/// The snake_case names of the classes under `lib/` that `extends` or
/// `implements` `Srd5eException` (FR-085 (a)).
Set<String> _exceptionTypeValues(SourceSet sources) {
  final values = <String>{};
  for (final path in sources.dartPaths('lib/')) {
    for (final declaration in declarationsIn(path, sources.lexed(path))) {
      if (declaration.kind != DeclarationKind.classDeclaration) continue;
      if (declaration.supertypes.contains('Srd5eException')) {
        values.add(snakeCase(declaration.name));
      }
    }
  }
  return values;
}

/// The attribute key named in backticks in [doc]: a shared key or
/// `error.type` when present, else another dotted key, else `null`.
String? _keyNamedIn(String doc) {
  final tokens = [
    for (final match in _backticked.allMatches(doc)) match.group(1)!,
  ];
  for (final token in tokens) {
    if (constants.sharedAttributeValueSets.containsKey(token) ||
        token == constants.exceptionTypeAttributeKey) {
      return token;
    }
  }
  for (final token in tokens) {
    if (_otherKey.hasMatch(token)) return token;
  }
  return null;
}

/// The doc comment text directly above the line [line] of [lexed].
String _docAbove(LexResult lexed, int line) {
  final byLine = {
    for (final comment in lexed.comments)
      if (comment.kind == CommentKind.doc) comment.line: comment.text,
  };
  final lines = <String>[];
  for (var at = line - 1; byLine.containsKey(at); at--) {
    lines.add(byLine[at]!);
  }
  return lines.reversed.join('\n');
}

/// The part of [sources] FR-085 (a) covers: attribute value constants.
List<Violation> _checkCode(SourceSet sources, Set<String> exceptionValues) {
  final violations = <Violation>[];
  for (final path in sources.dartPaths('lib/')) {
    final lexed = sources.lexed(path);
    for (final declaration in declarationsIn(path, lexed)) {
      if (declaration.kind != DeclarationKind.classDeclaration) continue;
      if (!_isSignalsClass(declaration.name)) continue;
      final body = lexed.code.substring(
        declaration.bodyStart,
        declaration.bodyEnd,
      );
      for (final match in _staticConstString.allMatches(body)) {
        final name = match.group(1)!;
        if (!name.endsWith('Value')) continue;
        final offset = declaration.bodyStart + match.start;
        final line = lexed.lineOf(offset);
        final literalOffset = declaration.bodyStart + match.end;
        final literals = lexed.strings.where((s) => s.offset == literalOffset);
        if (literals.isEmpty) continue;
        final value = literals.first.value;
        final key = _keyNamedIn(_docAbove(lexed, line));
        if (key == null) {
          violations.add(
            Violation(
              checkId: _id,
              path: path,
              line: line,
              detail:
                  '${declaration.name}.$name has no doc comment naming its '
                  'attribute key in backticks',
            ),
          );
          continue;
        }
        final problem = _valueProblem(key, value, exceptionValues);
        if (problem != null) {
          violations.add(
            Violation(
              checkId: _id,
              path: path,
              line: line,
              detail: '${declaration.name}.$name: $problem',
            ),
          );
        }
      }
    }
  }
  return violations;
}

/// Why [value] is not allowed for [key], or `null` when it is.
String? _valueProblem(String key, String value, Set<String> exceptionValues) {
  if (key == constants.exceptionTypeAttributeKey) {
    if (!_snakeValue.hasMatch(value)) {
      return '"$value" is not snake_case (^[a-z][a-z0-9_]*\$) for $key';
    }
    if (!exceptionValues.contains(value)) {
      return '"$value" is not the snake_case of a Srd5eException subtype '
          'for $key';
    }
    return null;
  }
  final allowed = constants.sharedAttributeValueSets[key];
  if (allowed != null && !allowed.contains(value)) {
    return '"$value" is not in the closed set of $key '
        '(${(allowed.toList()..sort()).join(', ')})';
  }
  return null;
}

/// The part of the catalogue FR-085 (b) covers.
List<Violation> _checkCatalogue(
  SourceSet sources,
  Set<String> exceptionValues,
) {
  final text = sources.files[_cataloguePath];
  if (text == null) return const [];
  final violations = <Violation>[];
  for (final table in parseMarkdownTables(text)) {
    final column = table.header.indexOf('Attributes');
    if (column < 0 || !table.header.contains('Name')) continue;
    for (final row in table.rows) {
      final cell = row.cell(column);
      if (cell == null) continue;
      for (final match in _catalogueKeyWithValues.allMatches(cell)) {
        final key = match.group(1)!;
        if (!constants.sharedAttributeValueSets.containsKey(key) &&
            key != constants.exceptionTypeAttributeKey) {
          continue;
        }
        for (final value in _backticked.allMatches(match.group(2)!)) {
          final problem = _valueProblem(key, value.group(1)!, exceptionValues);
          if (problem == null) continue;
          violations.add(
            Violation(
              checkId: _id,
              path: _cataloguePath,
              line: row.line,
              detail: 'catalogue Attributes cell: $problem',
            ),
          );
        }
      }
    }
  }
  return violations;
}

/// FR-085: shared attribute values. In code, an attribute value constant has a
/// doc comment naming its key in backticks and a value allowed for that key;
/// in the catalogue, each value listed after a shared key is allowed for it.
List<Violation> checkAttributeValues(SourceSet sources) {
  final exceptionValues = _exceptionTypeValues(sources);
  return sortedViolations([
    ..._checkCode(sources, exceptionValues),
    ..._checkCatalogue(sources, exceptionValues),
  ]);
}

/// The check function per id, for the registry (`registry.dart`).
const Map<String, List<Violation> Function(SourceSet)> attributeValuesChecks = {
  'FR-085': checkAttributeValues,
};

/// One minimal violating fixture per check id; the registry merges this map
/// into its own (`registry.dart`, FR-005).
final Map<String, SourceSet Function()> attributeValuesViolatingFixtures = {
  'FR-085': () => SourceSet({
    'lib/src/combat/application/combat_signals.dart':
        'abstract final class CombatSignals {\n'
        '  /// The `srd5e.outcome` value for a miss.\n'
        "  static const String missValue = 'miss';\n"
        '}\n',
  }),
};
