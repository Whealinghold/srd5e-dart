import 'declarations.dart';
import 'lexer.dart';
import 'source_set.dart';

/// The kind of a member of a signals class, told by its identifier suffix
/// (doc/specs/architecture-guardrails.md section 3, FR-037).
enum SignalKind {
  /// Identifier ends in `Metric`.
  metric,

  /// Identifier ends in `Span`.
  span,

  /// Identifier ends in `LogEvent`.
  logEvent,

  /// Identifier ends in `Attribute`.
  attribute,

  /// Identifier ends in `Value` (an attribute value constant, FR-085).
  value,

  /// No recognised suffix.
  unsuffixed,
}

/// The kind named by the suffix of [identifier].
SignalKind signalKindOf(String identifier) {
  if (identifier.endsWith('LogEvent')) return SignalKind.logEvent;
  if (identifier.endsWith('Metric')) return SignalKind.metric;
  if (identifier.endsWith('Span')) return SignalKind.span;
  if (identifier.endsWith('Attribute')) return SignalKind.attribute;
  if (identifier.endsWith('Value')) return SignalKind.value;
  return SignalKind.unsuffixed;
}

/// The name of the shared attribute-key class (`observability-ports.md`
/// FR-052).
const String attributeKeysClassName = 'AttributeKeys';

/// Whether [name] names a signals class: it ends in `Signals` or is exactly
/// [attributeKeysClassName].
bool isSignalsClassName(String name) =>
    name.endsWith('Signals') || name == attributeKeysClassName;

/// A `static const String` member of a signals class.
final class SignalConstant {
  /// Creates a record.
  const SignalConstant({
    required this.path,
    required this.className,
    required this.name,
    required this.line,
    required this.kind,
    required this.value,
    required this.literalOffset,
    required this.docComment,
  });

  /// The declaring file.
  final String path;

  /// The declaring class.
  final String className;

  /// The member identifier.
  final String name;

  /// The 1-based line of the identifier.
  final int line;

  /// The kind told by the identifier suffix alone.
  final SignalKind kind;

  /// The literal's value when the initialiser is exactly one plain string
  /// literal (no interpolation, concatenation or adjacent literals); else
  /// null.
  final String? value;

  /// The offset of the plain initialiser literal, or null when it is not
  /// plain.
  final int? literalOffset;

  /// The text of the `///` lines directly above the member, or the empty
  /// string.
  final String docComment;

  /// Whether the member belongs to `AttributeKeys`, whose members are all
  /// attribute keys whatever their names.
  bool get isAttributeKey => className == attributeKeysClassName;

  /// The kind the member plays: every `AttributeKeys` member is an
  /// attribute; otherwise the suffix decides.
  SignalKind get effectiveKind => isAttributeKey ? SignalKind.attribute : kind;

  /// Whether it is a metric, span or log event constant.
  bool get isSignal =>
      effectiveKind == SignalKind.metric ||
      effectiveKind == SignalKind.span ||
      effectiveKind == SignalKind.logEvent;
}

/// A class whose name makes it a signals class.
final class SignalsClass {
  /// Creates a record.
  const SignalsClass({
    required this.path,
    required this.name,
    required this.line,
    required this.isAbstractFinal,
    required this.members,
  });

  /// The declaring file.
  final String path;

  /// The class name.
  final String name;

  /// The 1-based line of the name.
  final int line;

  /// Whether it is declared `abstract final`.
  final bool isAbstractFinal;

  /// Its `static const String` members, in source order.
  final List<SignalConstant> members;
}

final RegExp _staticConstString = RegExp(
  r'static\s+const\s+String\s+([A-Za-z_]\w*)\s*=\s*',
);
final RegExp _singleLiteral = RegExp(r'''^r?(?:''|""|'{6}|"{6})$''');
final RegExp _whitespace = RegExp(r'\s');

bool _isIdentifierUnit(int unit) =>
    (unit >= 0x30 && unit <= 0x39) ||
    (unit >= 0x41 && unit <= 0x5A) ||
    (unit >= 0x61 && unit <= 0x7A) ||
    unit == 0x5F ||
    unit == 0x24;

/// The signals classes declared in [path] with their `static const String`
/// members.
List<SignalsClass> signalsClassesIn(SourceSet sources, String path) {
  final text = sources.files[path];
  if (text == null ||
      !(text.contains('Signals') || text.contains(attributeKeysClassName))) {
    return const [];
  }
  final lexed = sources.lexed(path);
  final sorted = [...lexed.strings]
    ..sort((a, b) => a.offset.compareTo(b.offset));
  final indexByOffset = {
    for (var i = 0; i < sorted.length; i++) sorted[i].offset: i,
  };
  final docByLine = <int, String>{
    for (final comment in lexed.comments)
      if (comment.kind == CommentKind.doc)
        comment.line: comment.text.replaceFirst(RegExp(r'^///\s?'), ''),
  };
  final code = lexed.code;

  String docAbove(int line) {
    final lines = <String>[];
    for (var l = line - 1; docByLine.containsKey(l); l--) {
      lines.insert(0, docByLine[l]!);
    }
    return lines.join('\n');
  }

  ({String? value, int? offset}) plainInitialiser(int from) {
    final semicolon = code.indexOf(';', from);
    if (semicolon == -1) return (value: null, offset: null);
    final statement = code.substring(from, semicolon);
    if (!_singleLiteral.hasMatch(statement.replaceAll(_whitespace, ''))) {
      return (value: null, offset: null);
    }
    var start = from;
    while (start < semicolon && code[start].trim().isEmpty) {
      start++;
    }
    final index = indexByOffset[start] ?? indexByOffset[start - 1];
    if (index == null) return (value: null, offset: null);
    final next = index + 1 < sorted.length ? sorted[index + 1] : null;
    if (next != null && next.offset < semicolon) {
      return (value: null, offset: null);
    }
    return (value: sorted[index].value, offset: sorted[index].offset);
  }

  final classes = <SignalsClass>[];
  for (final declaration in declarationsIn(path, lexed)) {
    if (declaration.kind != DeclarationKind.classDeclaration ||
        !isSignalsClassName(declaration.name)) {
      continue;
    }
    final members = <SignalConstant>[];
    var depth = 0;
    for (var i = declaration.bodyStart; i < declaration.bodyEnd; i++) {
      final unit = code.codeUnitAt(i);
      if (unit == 0x7B) {
        depth++;
      } else if (unit == 0x7D) {
        depth--;
      } else if (depth == 1 &&
          unit == 0x73 /* s */ &&
          (i == 0 || !_isIdentifierUnit(code.codeUnitAt(i - 1)))) {
        final match = _staticConstString.matchAsPrefix(code, i);
        if (match == null) continue;
        final name = match.group(1)!;
        final plain = plainInitialiser(match.end);
        members.add(
          SignalConstant(
            path: path,
            className: declaration.name,
            name: name,
            line: lexed.lineOf(code.indexOf(name, i + 6)),
            kind: signalKindOf(name),
            value: plain.value,
            literalOffset: plain.offset,
            docComment: docAbove(lexed.lineOf(i)),
          ),
        );
        i = match.end - 1;
      }
    }
    classes.add(
      SignalsClass(
        path: path,
        name: declaration.name,
        line: declaration.line,
        isAbstractFinal:
            declaration.modifiers.contains('abstract') &&
            declaration.modifiers.contains('final'),
        members: members,
      ),
    );
  }
  return classes;
}

final RegExp _applicationConstantsPath = RegExp(
  r'^lib/src/([^/]+)/application/[^/]*signals\.dart$',
);

/// The folders directly under `lib/src/` that are not bounded contexts.
const Set<String> nonContextFolders = {
  'shared_kernel',
  'shared_ports',
  'testing',
};

/// The context folder of [path] (`lib/src/<context>/...`), or null for a file
/// not in a folder directly under `lib/src/`, or in one of
/// [nonContextFolders].
String? contextFolderOf(String path) {
  final segments = path.split('/');
  if (segments.length < 4 ||
      segments[0] != 'lib' ||
      segments[1] != 'src' ||
      nonContextFolders.contains(segments[2])) {
    return null;
  }
  return segments[2];
}

/// Every signals class under `lib/`, and the constants files (section 3).
final class SignalIndex {
  SignalIndex._(this.classes, this.constantsFiles);

  /// Reads every `.dart` file under `lib/` of [sources].
  factory SignalIndex.of(SourceSet sources) {
    final classes = <SignalsClass>[];
    for (final path in sources.dartPaths('lib/')) {
      classes.addAll(signalsClassesIn(sources, path));
    }
    final constantsFiles = <String>{
      for (final path in sources.dartPaths('lib/'))
        if (_applicationConstantsPath.hasMatch(path)) path,
      for (final c in classes)
        if (c.name == attributeKeysClassName &&
            c.path.startsWith('lib/src/shared_ports/'))
          c.path,
    };
    return SignalIndex._(classes, constantsFiles);
  }

  /// Every signals class, in path order.
  final List<SignalsClass> classes;

  /// The constants files: `lib/src/<context>/application/*signals.dart`, and
  /// a file under `lib/src/shared_ports/` declaring `AttributeKeys`.
  final Set<String> constantsFiles;

  /// Every member of every signals class.
  Iterable<SignalConstant> get constants => classes.expand((c) => c.members);

  /// Whether [path] is a constants file.
  bool isConstantsFile(String path) => constantsFiles.contains(path);
}
