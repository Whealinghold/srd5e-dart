/// A small `.gitignore`-style evaluator for the `.pubignore` checks
/// (`doc/specs/architecture-guardrails.md` FR-079 (b)).
///
/// Rules: later lines win, `!` negates, a leading or inner `/` anchors the
/// pattern to the root, a trailing `/` matches directories only, a parent
/// directory that is excluded excludes its content (which cannot be
/// re-included), `*` stays inside one segment, `**` crosses segments. Pure:
/// it reads text, not the file system.
final class GitignoreRules {
  GitignoreRules._(this._rules);

  /// Parses the text of an ignore file.
  factory GitignoreRules.parse(String text) {
    final rules = <_Rule>[];
    var lineNumber = 0;
    for (final raw in text.split('\n')) {
      lineNumber++;
      var line = raw.endsWith('\r') ? raw.substring(0, raw.length - 1) : raw;
      line = _trimTrailingSpaces(line);
      if (line.isEmpty || line.startsWith('#')) continue;
      var negated = false;
      if (line.startsWith('!')) {
        negated = true;
        line = line.substring(1);
      } else if (line.startsWith(r'\!') || line.startsWith(r'\#')) {
        line = line.substring(1);
      }
      var directoryOnly = false;
      if (line.endsWith('/')) {
        directoryOnly = true;
        line = line.substring(0, line.length - 1);
      }
      if (line.isEmpty) continue;
      final anchored = line.contains('/');
      if (line.startsWith('/')) line = line.substring(1);
      if (line.isEmpty) continue;
      final body = _globToRegex(line);
      final expression = anchored ? '^$body\$' : '^(?:.*/)?$body\$';
      rules.add(
        _Rule(
          line: lineNumber,
          negated: negated,
          directoryOnly: directoryOnly,
          pattern: RegExp(expression),
        ),
      );
    }
    return GitignoreRules._(rules);
  }

  final List<_Rule> _rules;

  /// Whether [path] (repository-relative, `/` separated, no trailing `/`) is
  /// excluded. [isDirectory] says whether [path] itself is a directory;
  /// every ancestor is a directory.
  bool excludes(String path, {bool isDirectory = false}) {
    final segments = path.split('/').where((s) => s.isNotEmpty).toList();
    for (var i = 1; i < segments.length; i++) {
      if (_decide(segments.take(i).join('/'), true)) return true;
    }
    return _decide(segments.join('/'), isDirectory);
  }

  bool _decide(String path, bool isDirectory) {
    var excluded = false;
    for (final rule in _rules) {
      if (rule.directoryOnly && !isDirectory) continue;
      if (rule.pattern.hasMatch(path)) excluded = !rule.negated;
    }
    return excluded;
  }

  /// The 1-based line of the rule that finally makes [path] excluded, by the
  /// same walk [excludes] performs (ancestors first, then the path itself);
  /// null when [path] is not excluded.
  int? excludedByLine(String path, {bool isDirectory = false}) {
    final segments = path.split('/').where((s) => s.isNotEmpty).toList();
    int? deciding;
    for (var i = 1; i < segments.length; i++) {
      final line = _decidingLine(segments.take(i).join('/'), true);
      if (line != null) deciding = line;
    }
    final own = _decidingLine(segments.join('/'), isDirectory);
    if (own != null) deciding = own;
    return deciding;
  }

  int? _decidingLine(String path, bool isDirectory) {
    var excluded = false;
    int? line;
    for (final rule in _rules) {
      if (rule.directoryOnly && !isDirectory) continue;
      if (rule.pattern.hasMatch(path)) {
        excluded = !rule.negated;
        line = excluded ? rule.line : null;
      }
    }
    return excluded ? line : null;
  }
}

final class _Rule {
  const _Rule({
    required this.line,
    required this.negated,
    required this.directoryOnly,
    required this.pattern,
  });

  /// The 1-based line of the pattern in the parsed text.
  final int line;

  final bool negated;
  final bool directoryOnly;
  final RegExp pattern;
}

String _trimTrailingSpaces(String line) {
  var end = line.length;
  while (end > 0 && line[end - 1] == ' ' && !_escapedAt(line, end - 1)) {
    end--;
  }
  return line.substring(0, end);
}

bool _escapedAt(String line, int index) => index > 0 && line[index - 1] == r'\';

String _globToRegex(String glob) {
  final out = StringBuffer();
  var i = 0;
  while (i < glob.length) {
    final char = glob[i];
    if (char == '*') {
      if (i + 1 < glob.length && glob[i + 1] == '*') {
        final before = i == 0 || glob[i - 1] == '/';
        final after = i + 2 >= glob.length || glob[i + 2] == '/';
        if (before && after) {
          if (i + 2 >= glob.length) {
            out.write('.*');
            i += 2;
          } else {
            out.write('(?:.*/)?');
            i += 3;
          }
          continue;
        }
        out.write('[^/]*');
        i += 2;
        continue;
      }
      out.write('[^/]*');
    } else if (char == '?') {
      out.write('[^/]');
    } else if (char == r'\' && i + 1 < glob.length) {
      out.write(RegExp.escape(glob[i + 1]));
      i++;
    } else {
      out.write(RegExp.escape(char));
    }
    i++;
  }
  return out.toString();
}
