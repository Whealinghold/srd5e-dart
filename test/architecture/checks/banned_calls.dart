import '../support/source_set.dart';
import '../support/violation.dart';

/// Banned-call checks FR-027, FR-028 and FR-103 of
/// `doc/specs/architecture-guardrails.md` (section 4.2).
///
/// Every function is pure: it reads a [SourceSet] and returns [Violation]s.
/// They read the lexer's code (FR-008), so text in comments and string
/// literals is ignored while code inside `${...}` interpolation is examined.
/// No inline suppression exists (FR-009).

/// One banned call: [label] names it in the Violation, [pattern] finds it in
/// lexed code.
typedef _Banned = ({String label, RegExp pattern});

/// Matches [name] only when no identifier character comes before it, so
/// `MyStopwatch(` and `Randomizer(` are different names. A `.` before it is
/// allowed: `math.Random(1)` is still `Random(`.
String _name(String name) => r'(?<![\w$])' + name;

/// The calls FR-027 bans in `domain/` and `application/`, and FR-103 bans in
/// `shared_ports/`: unseeded and seeded randomness, and the clock. A
/// `DateTime.now` match covers both the call and the tear-off.
final List<_Banned> _nondeterministic = [
  (label: 'Random(', pattern: RegExp('${_name('Random')}\\s*\\(')),
  (
    label: 'Random.secure(',
    pattern: RegExp('${_name('Random')}\\s*\\.\\s*secure\\s*\\('),
  ),
  (
    label: 'DateTime.now',
    pattern: RegExp('${_name('DateTime')}\\s*\\.\\s*now(?![\\w\$])'),
  ),
  (
    label: 'DateTime.timestamp(',
    pattern: RegExp('${_name('DateTime')}\\s*\\.\\s*timestamp\\s*\\('),
  ),
  (label: 'Stopwatch(', pattern: RegExp('${_name('Stopwatch')}\\s*\\(')),
];

/// A bare `print(` call: not preceded by an identifier character or a `.`
/// (a method named `print` on an object is allowed, FR-028).
final RegExp _bareLinePrint = RegExp(r'(?<![\w$.])print\s*\(');

/// The folders of [path] (every segment but the file name).
List<String> _folders(String path) {
  final segments = path.split('/');
  return segments.sublist(0, segments.length - 1);
}

/// Whether [path] is a `.dart` file under `lib/src/<x>/` with a folder named
/// [folder] below the context folder.
bool _inLayer(String path, String folder) =>
    path.endsWith('.dart') &&
    path.startsWith('lib/src/') &&
    _folders(path).skip(2).contains(folder);

/// Whether [path] is a `domain/` or `application/` file (FR-027).
bool isDomainOrApplicationFile(String path) =>
    _inLayer(path, 'domain') || _inLayer(path, 'application');

/// Whether [path] is a `.dart` file under `lib/src/shared_ports/`, including
/// its `adapters/` folder and the no-ops (FR-103).
bool isSharedPortsFile(String path) =>
    path.endsWith('.dart') && path.startsWith('lib/src/shared_ports/');

List<Violation> _scan(
  SourceSet sources, {
  required String id,
  required Iterable<String> paths,
  required Iterable<_Banned> banned,
  required String reason,
}) {
  final violations = <Violation>[];
  for (final path in paths) {
    final lexed = sources.lexed(path);
    final seen = <String>{};
    for (final ban in banned) {
      for (final match in ban.pattern.allMatches(lexed.code)) {
        final line = lexed.lineOf(match.start);
        if (!seen.add('$line:${ban.label}')) continue;
        violations.add(
          Violation(
            checkId: id,
            path: path,
            line: line,
            detail: 'the file uses ${ban.label}; $reason',
          ),
        );
      }
    }
  }
  return sortedViolations(violations);
}

/// FR-027: a `domain/` or `application/` file does not call `Random(`,
/// `Random.secure(`, `DateTime.now(`, `DateTime.timestamp(` or `Stopwatch(`,
/// nor tear off `DateTime.now`.
List<Violation> checkNondeterministicCalls(SourceSet sources) => _scan(
  sources,
  id: 'FR-027',
  paths: sources.dartPaths('lib/src/').where(isDomainOrApplicationFile),
  banned: _nondeterministic,
  reason:
      'randomness and time arrive as values through a port, never read '
      'in the domain or application layer',
);

/// FR-028: no file under `lib/` calls `print(` (a bare call).
List<Violation> checkPrintCalls(SourceSet sources) => _scan(
  sources,
  id: 'FR-028',
  paths: sources.dartPaths('lib/'),
  banned: [(label: 'print(', pattern: _bareLinePrint)],
  reason: 'anything that would be printed is a FINE or FINEST log',
);

/// FR-103: no file under `lib/src/shared_ports/`, `adapters/` and the no-ops
/// included, calls what FR-027 bans. There is no carve-out for adapters: the
/// seeded `Random` is injected by the consumer and only consumer adapters read
/// the clock.
List<Violation> checkSharedPortsNondeterminism(SourceSet sources) => _scan(
  sources,
  id: 'FR-103',
  paths: sources.dartPaths('lib/src/shared_ports/').where(isSharedPortsFile),
  banned: _nondeterministic,
  reason:
      'shared_ports code, adapters and no-ops included, takes its random '
      'source and clock from the consumer',
);

/// The check function per id, for the registry (`registry.dart`).
const Map<String, List<Violation> Function(SourceSet)> bannedCallsChecks = {
  'FR-027': checkNondeterministicCalls,
  'FR-028': checkPrintCalls,
  'FR-103': checkSharedPortsNondeterminism,
};

/// One minimal violating fixture per check id; the registry merges this map
/// into its own (`registry.dart`, FR-005).
final Map<String, SourceSet Function()> bannedCallsViolatingFixtures = {
  'FR-027': () =>
      SourceSet({'lib/src/d20_test/domain/a.dart': 'final r = Random(5);\n'}),
  'FR-028': () => SourceSet({
    'lib/src/d20_test/application/a.dart': "void f() => print('x');\n",
  }),
  'FR-103': () => SourceSet({
    'lib/src/shared_ports/adapters/a.dart': 'final r = Random(5);\n',
  }),
};
