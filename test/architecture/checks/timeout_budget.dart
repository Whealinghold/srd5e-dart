import '../support/source_set.dart';
import '../support/test_scan.dart';
import '../support/violation.dart';

/// Per-group time budget FR-073 of `doc/specs/architecture-guardrails.md`
/// (section 4.6).
///
/// FR-073 is a support rule, not a registered check (FR-005 reads section 4.2,
/// 4.3, 4.4 and 4.7 only), so nothing here is in `registry.dart`. The function
/// is pure: it reads a [SourceSet] and returns [Violation]s. The budget is per
/// group only; no total is set for the suite.

const String _id = 'FR-073';
const String _testPrefix = 'test/';
const String _testSuffix = '_test.dart';

/// The only accepted value of a real-repository group's `timeout:` argument,
/// with whitespace removed.
final RegExp _budgetPattern = RegExp(
  r'^(?:const)?Timeout\(Duration\(seconds:10,?\),?\)$',
);

/// What marks code as reading the real repository: the shared snapshot, or
/// `findPackageRoot()` called with no argument (a fixture root passes one).
final RegExp _realRepositoryPattern = RegExp(
  r'(?<![A-Za-z0-9_$.])realRepository(?![A-Za-z0-9_$])'
  r'|(?<![A-Za-z0-9_$.])findPackageRoot\s*\(\s*\)',
);

final RegExp _timeoutArgument = RegExp(r'(?<![A-Za-z0-9_$.])timeout\s*:');
final RegExp _lastIdentifier = RegExp(r'([A-Za-z_$][A-Za-z0-9_$]*)\s*$');
final RegExp _identifier = RegExp(r'^[A-Za-z_$][A-Za-z0-9_$]*$');

bool _isOpener(String c) => c == '(' || c == '[' || c == '{';

bool _isCloser(String c) => c == ')' || c == ']' || c == '}';

bool _mentions(String code, String name) => RegExp(
  '(?<![A-Za-z0-9_\$.])${RegExp.escape(name)}(?![A-Za-z0-9_\$])',
).hasMatch(code);

/// One top-level declaration: its name (null for a directive) and its text.
typedef _Declaration = ({String? name, String text});

/// The top-level declarations of lexed [code], split at a `;` or a closing
/// brace at depth zero.
List<_Declaration> _declarations(String code) {
  final result = <_Declaration>[];
  var depth = 0;
  var start = 0;
  void close(int end) {
    final text = code.substring(start, end).trim();
    start = end;
    if (text.isEmpty) return;
    result.add((name: _declaredName(text), text: text));
  }

  for (var i = 0; i < code.length; i++) {
    final c = code[i];
    if (_isOpener(c)) {
      depth++;
    } else if (_isCloser(c)) {
      depth--;
      if (depth == 0 && c == '}') {
        var next = i + 1;
        while (next < code.length && code[next].trim().isEmpty) {
          next++;
        }
        final continues =
            next < code.length && (code[next] == ';' || code[next] == ',');
        if (!continues) close(i + 1);
      }
    } else if (depth == 0 && c == ';') {
      close(i + 1);
    }
  }
  close(code.length);
  return result;
}

/// The name a declaration introduces: the last identifier before its first
/// `=`, `(` or `{` at depth zero.
String? _declaredName(String text) {
  var depth = 0;
  for (var i = 0; i < text.length; i++) {
    final c = text[i];
    if (depth == 0 && (c == '=' || c == '(' || c == '{')) {
      return _lastIdentifier.firstMatch(text.substring(0, i))?.group(1);
    }
    if (_isOpener(c)) depth++;
    if (_isCloser(c)) depth--;
  }
  return null;
}

/// The names of top-level declarations that read the real repository, directly
/// or through another such declaration (`main` is the entry point, not a
/// helper).
Set<String> _realRepositoryNames(List<_Declaration> declarations) {
  final tainted = <String>{};
  var changed = true;
  while (changed) {
    changed = false;
    for (final declaration in declarations) {
      final name = declaration.name;
      if (name == null || name == 'main' || tainted.contains(name)) continue;
      final reads =
          _realRepositoryPattern.hasMatch(declaration.text) ||
          tainted.any((other) => _mentions(declaration.text, other));
      if (reads) {
        tainted.add(name);
        changed = true;
      }
    }
  }
  return tainted;
}

/// The value of the `timeout:` argument directly in [args] (the text between a
/// call's parentheses, brackets balanced), whitespace removed; null when the
/// call has none.
String? _timeoutValue(String args) {
  var depth = 0;
  for (var i = 0; i < args.length; i++) {
    final c = args[i];
    if (_isOpener(c)) {
      depth++;
    } else if (_isCloser(c)) {
      depth--;
    } else if (depth == 0) {
      final match = _timeoutArgument.matchAsPrefix(args, i);
      if (match == null) continue;
      var end = match.end;
      var inner = 0;
      while (end < args.length) {
        final d = args[end];
        if (_isOpener(d)) inner++;
        if (_isCloser(d)) inner--;
        if (inner == 0 && d == ',') break;
        end++;
      }
      return args.substring(match.end, end).replaceAll(RegExp(r'\s+'), '');
    }
  }
  return null;
}

/// Whether [value] is the 10 second Timeout, literally or through a top-level
/// constant of that value.
bool _isBudget(String value, List<_Declaration> declarations) {
  if (_budgetPattern.hasMatch(value)) return true;
  if (!_identifier.hasMatch(value)) return false;
  for (final declaration in declarations) {
    if (declaration.name != value) continue;
    final equals = declaration.text.indexOf('=');
    if (equals < 0) return false;
    final initializer = declaration.text
        .substring(equals + 1)
        .replaceAll(RegExp(r'[\s;]+'), '');
    return _budgetPattern.hasMatch(initializer);
  }
  return false;
}

/// FR-073: in every `*_test.dart` file under `test/`, each outermost `group(`
/// or `test(` call that reads the real repository carries
/// `timeout: Timeout(Duration(seconds: 10))`, literally or through a top-level
/// constant. A call reads the real repository when its arguments mention
/// `realRepository`, a call of `findPackageRoot()` with no argument, or a
/// top-level declaration of the same file that does (`_repository` is the
/// usual alias). Calls nested in a group are covered by the group's budget.
List<Violation> checkRealRepositoryTimeouts(SourceSet sources) {
  final violations = <Violation>[];
  for (final path in sources.dartPaths(_testPrefix)) {
    if (!path.endsWith(_testSuffix)) continue;
    final lexed = sources.lexed(path);
    final code = lexed.code;
    final declarations = _declarations(code);
    final reading = _realRepositoryNames(declarations);

    for (final call in scanTests(lexed).calls) {
      if (call.groups.isNotEmpty) continue;
      final args = code.substring(call.argsStart + 1, call.argsEnd - 1);
      final reads =
          _realRepositoryPattern.hasMatch(args) ||
          reading.any((name) => _mentions(args, name));
      if (!reads) continue;

      final value = _timeoutValue(args);
      final String? problem;
      if (value == null) {
        problem = 'declares no timeout';
      } else if (!_isBudget(value, declarations)) {
        problem = 'declares timeout: $value';
      } else {
        problem = null;
      }
      if (problem == null) continue;
      violations.add(
        Violation(
          checkId: _id,
          path: path,
          line: call.line,
          detail:
              'A ${call.kind.name} that reads the real repository $problem; '
              'it must carry timeout: Timeout(Duration(seconds: 10)).',
        ),
      );
    }
  }
  return sortedViolations(violations);
}
