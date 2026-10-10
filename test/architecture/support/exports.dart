import 'context_map.dart';
import 'directives.dart';
import 'source_set.dart';

/// The core entry points of the package (`doc/specs/architecture-guardrails.md`
/// section 3): the files that expose the public API.
const List<String> coreEntryPoints = [
  'lib/srd5e.dart',
  'lib/adapters.dart',
  'lib/testing.dart',
];

/// One top-level declaration a barrel can export: where it is declared and
/// what it is called (FR-093).
final class Exported implements Comparable<Exported> {
  /// Creates a record for [name] declared at [path]:[line].
  const Exported({required this.path, required this.name, required this.line});

  /// The repository-relative path of the declaring file. For a declaration in
  /// a `part` file this is the part file.
  final String path;

  /// The declared name (a class, mixin, enum, extension type, extension or
  /// typedef).
  final String name;

  /// The 1-based line of the name in [path].
  final int line;

  @override
  int compareTo(Exported other) {
    final byName = name.compareTo(other.name);
    return byName != 0 ? byName : path.compareTo(other.path);
  }

  /// Two records are equal when the declaring file and the name are equal;
  /// the line is a position, not an identity.
  @override
  bool operator ==(Object other) =>
      other is Exported && other.path == path && other.name == name;

  @override
  int get hashCode => Object.hash(path, name);

  @override
  String toString() => '$name ($path:$line)';
}

final RegExp _classDeclaration = RegExp(r'(?<![\w$.])class\s+([A-Za-z_]\w*)');
final RegExp _mixinDeclaration = RegExp(
  r'(?<![\w$.])mixin\s+(?!class\b)([A-Za-z_]\w*)',
);
final RegExp _enumDeclaration = RegExp(r'(?<![\w$.])enum\s+([A-Za-z_]\w*)');
final RegExp _extensionTypeDeclaration = RegExp(
  r'(?<![\w$.])extension\s+type\s+(?:const\s+)?([A-Za-z_]\w*)',
);
final RegExp _extensionDeclaration = RegExp(
  r'(?<![\w$.])extension\s+(?!(?:type|on)\b)([A-Za-z_]\w*)(?=[^{;]*\bon\b)',
);
final RegExp _typedefStatement = RegExp(r'(?<![\w$.])typedef\s+([^;]*);');
final RegExp _typedefNewName = RegExp(r'^\s*([A-Za-z_]\w*)');
final RegExp _typedefOldName = RegExp(r'([A-Za-z_]\w*)\s*(?:<[^<>()]*>)?\s*\(');

/// [code] with everything inside `{}`, `()` and `[]` replaced by spaces
/// (newlines kept), so only top-level text is left. The brackets that open and
/// close the nesting stay, so a declaration header is still readable.
String _topLevelOnly(String code) {
  final out = StringBuffer();
  var depth = 0;
  for (var i = 0; i < code.length; i++) {
    final c = code[i];
    if (c == '{' || c == '(' || c == '[') {
      out.write(depth == 0 ? c : (c == '\n' ? c : ' '));
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

/// The public top-level declarations of the Dart file [path], and of the
/// files it takes as `part`s, read from the lexer's code (FR-063).
///
/// Covers `class` (any modifiers, including a mixin class and a class
/// alias), `mixin`, `enum`, `extension type`, a named `extension` and
/// `typedef`. A name starting with `_` is private and left out. Functions,
/// variables and an unnamed extension are not declarations of a type name and
/// are not returned.
List<Exported> topLevelDeclarations(SourceSet sources, String path) {
  final found = <Exported>[..._declaredIn(sources, path)];
  for (final directive in directivesOf(sources, path)) {
    final target = directive.resolvedPath;
    if (directive.kind == DirectiveKind.partDirective &&
        target != null &&
        sources.files.containsKey(target)) {
      found.addAll(_declaredIn(sources, target));
    }
  }
  return found;
}

List<Exported> _declaredIn(SourceSet sources, String path) {
  final lexed = sources.lexed(path);
  final top = _topLevelOnly(lexed.code);
  final found = <Exported>[];
  void add(RegExpMatch match, [int group = 1]) {
    final name = match.group(group)!;
    if (name.startsWith('_')) return;
    found.add(
      Exported(
        path: path,
        name: name,
        line: lexed.lineOf(match.end - name.length),
      ),
    );
  }

  for (final pattern in [
    _classDeclaration,
    _mixinDeclaration,
    _enumDeclaration,
    _extensionTypeDeclaration,
    _extensionDeclaration,
  ]) {
    pattern.allMatches(top).forEach(add);
  }
  for (final statement in _typedefStatement.allMatches(top)) {
    final body = statement.group(1)!;
    final bodyStart = statement.start + statement.group(0)!.indexOf(body);
    final RegExpMatch? name = body.contains('=')
        ? _typedefNewName.firstMatch(body)
        : _typedefOldName.firstMatch(body);
    if (name == null) continue;
    final text = name.group(1)!;
    if (text.startsWith('_')) continue;
    found.add(
      Exported(
        path: path,
        name: text,
        line: lexed.lineOf(bodyStart + body.indexOf(text, name.start)),
      ),
    );
  }
  found.sort((a, b) => a.line.compareTo(b.line));
  return found;
}

/// The export closure of the barrel or entry point [entryPath] (FR-093): every
/// public top-level declaration reachable through `export` directives,
/// followed transitively, with `show` and `hide` applied at each step. The
/// entry file's own declarations are included.
///
/// Sorted by name then path. A conditional export configuration
/// (`export 'a.dart' if (...) 'b.dart'`) contributes its default URI only. An
/// export that names no file of [sources] is skipped (FR-007 reports it). A
/// cycle of exports is followed once, so each file contributes the same names
/// however it is reached.
///
/// Throws [ArgumentError] when [entryPath] is not a file of [sources].
List<Exported> exportClosure(SourceSet sources, String entryPath) {
  if (!sources.files.containsKey(entryPath)) {
    throw ArgumentError.value(
      entryPath,
      'entryPath',
      'is not in the source set',
    );
  }
  final memo = <String, List<Exported>>{};
  List<Exported> visible(String path, Set<String> visiting) {
    final cached = memo[path];
    if (cached != null) return cached;
    if (!visiting.add(path)) return const [];
    final result = <Exported>{...topLevelDeclarations(sources, path)};
    for (final directive in directivesOf(sources, path)) {
      final target = directive.resolvedPath;
      if (directive.kind != DirectiveKind.exportDirective ||
          directive.isConditional ||
          target == null ||
          !target.endsWith('.dart') ||
          !sources.files.containsKey(target)) {
        continue;
      }
      for (final item in visible(target, visiting)) {
        if (directive.shown.isNotEmpty &&
            !directive.shown.contains(item.name)) {
          continue;
        }
        if (directive.hidden.contains(item.name)) continue;
        result.add(item);
      }
    }
    visiting.remove(path);
    final list = result.toList()..sort();
    return memo[path] = List.unmodifiable(list);
  }

  return visible(entryPath, <String>{});
}

/// The barrels and core entry points present in [sources]: the core entry
/// points of [coreEntryPoints] and every `lib/src/<context>/<context>.dart`
/// where `<context>` is a folder that is not `shared_kernel`, `shared_ports`
/// or `testing`. Sorted.
List<String> entryPointsIn(SourceSet sources) {
  final entries = <String>{
    for (final path in coreEntryPoints)
      if (sources.files.containsKey(path)) path,
  };
  for (final path in sources.dartPaths('lib/src/')) {
    if (barrelContextOf(path) != null) entries.add(path);
  }
  return entries.toList()..sort();
}
