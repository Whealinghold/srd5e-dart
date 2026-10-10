import 'lexer.dart';

/// The kind of a type declaration found by [declarationsIn].
enum DeclarationKind {
  /// A `class` (any modifiers).
  classDeclaration,

  /// An `enum`.
  enumDeclaration,
}

/// A class, enum or mixin declaration found in lexed code.
final class Declaration {
  /// Creates a declaration record.
  const Declaration({
    required this.path,
    required this.kind,
    required this.name,
    required this.modifiers,
    required this.line,
    required this.supertypes,
    required this.extendsName,
    required this.memberNames,
    required this.bodyStart,
    required this.bodyEnd,
  });

  /// The repository-relative path of the declaring file.
  final String path;

  /// Class, enum or mixin.
  final DeclarationKind kind;

  /// The declared name.
  final String name;

  /// The leading modifiers: `abstract`, `base`, `final`, `sealed`,
  /// `interface`, `mixin`.
  final Set<String> modifiers;

  /// The 1-based line of the name.
  final int line;

  /// Every name after `extends`, `implements`, `with` and `on`, without type
  /// arguments.
  final List<String> supertypes;

  /// The name after `extends`, if any.
  final String? extendsName;

  /// Field and getter names declared directly in the body, with their lines.
  final List<({String name, int line})> memberNames;

  /// Offset of the opening `{` in the lexed code.
  final int bodyStart;

  /// Offset just after the matching `}` in the lexed code.
  final int bodyEnd;
}

const Set<String> _modifierWords = {
  'abstract',
  'base',
  'final',
  'sealed',
  'interface',
  'mixin',
};

final RegExp _declaration = RegExp(
  r'(?<![\w$])((?:(?:abstract|base|final|sealed|interface|mixin)\s+)*)'
  r'(class|enum|mixin)\s+([A-Za-z_]\w*)',
);

/// Finds every class, enum and mixin declaration in [lexed] code of [path].
///
/// Reads the lexer's blanked code, so comments and strings never produce a
/// declaration.
List<Declaration> declarationsIn(String path, LexResult lexed) {
  final code = lexed.code;
  final result = <Declaration>[];
  for (final match in _declaration.allMatches(code)) {
    final keyword = match.group(2)!;
    final modifiers = {
      for (final word in match.group(1)!.trim().split(RegExp(r'\s+')))
        if (_modifierWords.contains(word)) word,
    };
    // `mixin class` is a class; a bare `mixin Name` is a mixin.
    if (keyword == 'mixin') {
      continue;
    }
    final headerStart = match.end;
    final open = code.indexOf('{', headerStart);
    final semicolon = code.indexOf(';', headerStart);
    if (open == -1 || (semicolon != -1 && semicolon < open)) continue;
    final header = code.substring(headerStart, open);
    final close = _matchingBrace(code, open);
    final supertypes = <String>[];
    String? extendsName;
    String? clause;
    for (final token in RegExp(
      r'[\w$.]+',
    ).allMatches(_stripTypeArguments(header))) {
      final word = token.group(0)!;
      if (const {'extends', 'implements', 'with', 'on'}.contains(word)) {
        clause = word;
      } else if (clause != null) {
        supertypes.add(word);
        if (clause == 'extends') extendsName ??= word;
      }
    }
    final kind = keyword == 'enum'
        ? DeclarationKind.enumDeclaration
        : DeclarationKind.classDeclaration;
    result.add(
      Declaration(
        path: path,
        kind: kind,
        name: match.group(3)!,
        modifiers: modifiers,
        line: lexed.lineOf(match.end - match.group(3)!.length),
        supertypes: supertypes,
        extendsName: extendsName,
        memberNames: _memberNames(
          lexed,
          open,
          close,
          skipFirstStatement: kind == DeclarationKind.enumDeclaration,
        ),
        bodyStart: open,
        bodyEnd: close,
      ),
    );
  }
  return result;
}

/// Offset just after the `}` that matches the `{` at [open] in [code].
int _matchingBrace(String code, int open) {
  var depth = 0;
  for (var i = open; i < code.length; i++) {
    final c = code.codeUnitAt(i);
    if (c == 0x7B) {
      depth++;
    } else if (c == 0x7D) {
      depth--;
      if (depth == 0) return i + 1;
    }
  }
  return code.length;
}

/// Removes `<...>` type arguments (possibly nested) from [text].
String _stripTypeArguments(String text) {
  final buffer = StringBuffer();
  var depth = 0;
  for (final unit in text.codeUnits) {
    if (unit == 0x3C) {
      depth++;
    } else if (unit == 0x3E && depth > 0) {
      depth--;
    } else if (depth == 0) {
      buffer.writeCharCode(unit);
    }
  }
  return buffer.toString();
}

/// Replaces `<...>` type arguments (possibly nested) with spaces, keeping
/// every offset.
String _blankTypeArguments(String text) {
  final buffer = StringBuffer();
  var depth = 0;
  for (final unit in text.codeUnits) {
    if (unit == 0x3C) {
      depth++;
      buffer.write(' ');
    } else if (unit == 0x3E && depth > 0) {
      depth--;
      buffer.write(' ');
    } else {
      buffer.write(depth == 0 ? String.fromCharCode(unit) : ' ');
    }
  }
  return buffer.toString();
}

/// Names of fields and getters declared directly in the body between [open]
/// and [close], with their lines.
///
/// Statements are split at `;` and at the `}` that ends a member body.
/// Parameters and nested bodies are skipped, so a constructor's
/// `this.message` is not a member; its field declaration is.
List<({String name, int line})> _memberNames(
  LexResult lexed,
  int open,
  int close, {
  required bool skipFirstStatement,
}) {
  final code = lexed.code;
  final statements = <({String text, List<int> offsets})>[];
  final text = StringBuffer();
  var offsets = <int>[];
  var depth = 0;
  void write(String char, int offset) {
    text.write(char);
    offsets.add(offset);
  }

  void flush() {
    statements.add((text: text.toString(), offsets: offsets));
    text.clear();
    offsets = <int>[];
  }

  for (var i = open + 1; i < close - 1; i++) {
    final c = code[i];
    if (c == '(' || c == '{' || c == '[') {
      if (depth == 0) write(c == '(' ? '(' : ' ', i);
      depth++;
    } else if (c == ')' || c == '}' || c == ']') {
      depth--;
      if (depth == 0 && c == '}') {
        flush();
      } else if (depth == 0 && c == ')') {
        write(')', i);
      }
    } else if (depth == 0) {
      if (c == ';') {
        flush();
      } else {
        write(c, i);
      }
    }
  }
  flush();

  final names = <({String name, int line})>[];
  final skip = skipFirstStatement ? 1 : 0;
  for (var index = skip; index < statements.length; index++) {
    final statement = statements[index].text;
    final at = statements[index].offsets;
    final getter = RegExp(r'\bget\s+([A-Za-z_]\w*)').firstMatch(statement);
    if (getter != null) {
      names.add((
        name: getter.group(1)!,
        line: lexed.lineOf(at[getter.end - getter.group(1)!.length]),
      ));
      continue;
    }
    if (statement.contains('(')) continue; // a method or constructor
    final declarationEnd = statement.contains('=')
        ? statement.indexOf('=')
        : statement.length;
    final declaration = _blankTypeArguments(
      statement.substring(0, declarationEnd),
    );
    var partStart = 0;
    for (final part in declaration.split(',')) {
      final words = RegExp(r'[A-Za-z_]\w*').allMatches(part).toList();
      if (words.isNotEmpty) {
        final last = words.last;
        names.add((
          name: last.group(0)!,
          line: lexed.lineOf(at[partStart + last.start]),
        ));
      }
      partStart += part.length + 1;
    }
  }
  return names;
}
