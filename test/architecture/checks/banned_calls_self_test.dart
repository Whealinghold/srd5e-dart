import 'package:test/test.dart';

import '../support/source_set.dart';
import '../support/violation.dart';
import 'banned_calls.dart';

const String _spec = 'doc/specs/architecture-guardrails.md';
const String _domain = 'lib/src/d20_test/domain/x.dart';
const String _application = 'lib/src/content/application/x.dart';
const String _port = 'lib/src/shared_ports/dice_roller/x.dart';
const String _sharedAdapter = 'lib/src/shared_ports/adapters/seeded.dart';
const String _noop = 'lib/src/shared_ports/observability/noop_logger.dart';

typedef _Case = ({
  String label,
  String requirement,
  String path,
  Map<String, String> files,
  List<String> expected,
});

List<String> _where(List<Violation> violations) => [
  for (final v in violations) '${v.checkId} ${v.path}:${v.line}',
];

/// A single file at [path] whose body is [body].
Map<String, String> _file(String body, {String path = _domain}) => {path: body};

/// A case in which [body] in [path] yields exactly [expected] lines.
_Case _hit(
  String label,
  String id,
  String body, {
  String path = _domain,
  int line = 1,
}) => (
  label: label,
  requirement: '$_spec $id',
  path: 'unhappy (invalid input)',
  files: _file(body, path: path),
  expected: ['$id $path:$line'],
);

/// A case in which [body] in [path] is clean.
_Case _clean(
  String label,
  String id,
  String body, {
  String path = _domain,
  String kind = 'unhappy (false positive)',
}) => (
  label: label,
  requirement: '$_spec $id',
  path: kind,
  files: _file(body, path: path),
  expected: [],
);

final List<_Case> _fr027 = [
  _hit('Random( in the domain', 'FR-027', 'final r = Random(5);\n'),
  _hit(
    'Random.secure( in the domain',
    'FR-027',
    'final r = Random.secure();\n',
  ),
  _hit('DateTime.now( in the domain', 'FR-027', 'final t = DateTime.now();\n'),
  _hit(
    'DateTime.timestamp( in the domain',
    'FR-027',
    'final t = DateTime.timestamp();\n',
  ),
  _hit(
    'Stopwatch( in the domain',
    'FR-027',
    'final s = Stopwatch()..start();\n',
  ),
  _hit('a tear-off of DateTime.now', 'FR-027', 'final clock = DateTime.now;\n'),
  _hit(
    'Random( in the application layer',
    'FR-027',
    'final r = Random(5);\n',
    path: _application,
  ),
  _hit(
    'DateTime.now( in an application ports folder',
    'FR-027',
    'final t = DateTime.now();\n',
    path: 'lib/src/content/application/ports/p.dart',
  ),
  _hit(
    'a library prefix does not hide the call',
    'FR-027',
    'final r = math.Random(5);\n',
  ),
  _hit(
    'whitespace before the parenthesis',
    'FR-027',
    'final r = Random (5);\n',
  ),
  _hit(
    'a call on the second line is reported at that line',
    'FR-027',
    'void f() {\n  final s = Stopwatch();\n}\n',
    line: 2,
  ),
  _hit(
    'code inside an interpolation is examined',
    'FR-027',
    "const a = 'x \${DateTime.now()}';\n",
  ),
  (
    label: 'an ignore comment does not suppress the Violation',
    requirement: '$_spec FR-027, FR-009',
    path: 'unhappy (rule interaction)',
    files: _file('// ignore: avoid_dynamic_calls\nfinal r = Random(5);\n'),
    expected: ['FR-027 $_domain:2'],
  ),
  (
    label: 'every banned call is reported, sorted by line',
    requirement: '$_spec FR-027',
    path: 'unhappy (multiple violations)',
    files: _file(
      'final a = Random(1);\nfinal b = DateTime.now();\nfinal c = Stopwatch();\n',
    ),
    expected: ['FR-027 $_domain:1', 'FR-027 $_domain:2', 'FR-027 $_domain:3'],
  ),
  (
    label: 'two different banned calls on one line are two Violations',
    requirement: '$_spec FR-027',
    path: 'unhappy (multiple violations)',
    files: _file('final a = [Random(1), Stopwatch()];\n'),
    expected: ['FR-027 $_domain:1', 'FR-027 $_domain:1'],
  ),
  _clean(
    'banned calls in comments and strings',
    'FR-027',
    "// Random( DateTime.now( Stopwatch(\n/// Random.secure(\n"
        "/* DateTime.timestamp( */\nconst a = 'Random(';\n"
        "const b = r'DateTime.now()';\nconst c = '''\nStopwatch(\n''';\n",
  ),
  _clean(
    'other names that only contain a banned name',
    'FR-027',
    'final a = Randomizer(1);\nfinal b = MyStopwatch();\n'
        'final c = DateTime.nowhere;\nfinal d = SecureRandom();\n',
  ),
  _clean(
    'DateTime values built from arguments, and an injected Random',
    'FR-027',
    'final a = DateTime(2020);\nfinal b = DateTime.utc(2020);\n'
        'int roll(Random random) => random.nextInt(6);\n',
    kind: 'happy',
  ),
  _clean(
    'a call in an adapters folder is not FR-027',
    'FR-027',
    'final r = Random(5);\n',
    path: 'lib/src/content/adapters/x.dart',
    kind: 'unhappy (boundary)',
  ),
  _clean(
    'a call in shared_ports is FR-103, not FR-027',
    'FR-027',
    'final r = Random(5);\n',
    path: _port,
    kind: 'unhappy (boundary)',
  ),
  _clean(
    'a call outside lib/ is not constrained',
    'FR-027',
    'final r = Random(5);\n',
    path: 'test/d20_test/domain/x_test.dart',
    kind: 'unhappy (boundary)',
  ),
];

final List<_Case> _fr028 = [
  _hit('print( in a domain file', 'FR-028', "void f() => print('x');\n"),
  _hit(
    'print( in the main entry point',
    'FR-028',
    "void f() { print('x'); }\n",
    path: 'lib/srd5e.dart',
  ),
  _hit(
    'print( in an adapter',
    'FR-028',
    "void f() { print('x'); }\n",
    path: 'lib/src/content/adapters/x.dart',
  ),
  _hit(
    'print( in shared_ports',
    'FR-028',
    "void f() { print('x'); }\n",
    path: _noop,
  ),
  _hit(
    'whitespace before the parenthesis',
    'FR-028',
    "void f() { print ('x'); }\n",
  ),
  _hit(
    'code inside an interpolation is examined',
    'FR-028',
    "const a = 'x \${print(1)}';\n",
  ),
  _hit(
    'a call on the third line is reported at that line',
    'FR-028',
    "void f() {\n  g();\n  print('x');\n}\n",
    line: 3,
  ),
  (
    label: 'an ignore comment does not suppress the Violation',
    requirement: '$_spec FR-028, FR-009',
    path: 'unhappy (rule interaction)',
    files: _file("// ignore: avoid_print\nvoid f() { print('x'); }\n"),
    expected: ['FR-028 $_domain:2'],
  ),
  (
    label: 'two prints on one line are one Violation',
    requirement: '$_spec FR-028',
    path: 'unhappy (boundary)',
    files: _file("void f() { print('a'); print('b'); }\n"),
    expected: ['FR-028 $_domain:1'],
  ),
  _clean(
    'a method named print on an object',
    'FR-028',
    'void f(Logger logger) { logger.print(x); this.print(y); }\n',
  ),
  _clean(
    'print( in comments and strings',
    'FR-028',
    "// print('x')\n/// print(\n/* print( */\nconst a = 'print(';\n"
        "const b = r'print(x)';\n",
  ),
  _clean(
    'names that only end in print',
    'FR-028',
    'void f() { debugPrint(1); sprint(2); blueprint(3); }\n',
  ),
  _clean(
    'print( outside lib/ is not constrained',
    'FR-028',
    "void main() { print('x'); }\n",
    path: 'test/x_test.dart',
    kind: 'unhappy (boundary)',
  ),
  _clean(
    'print( in tool/ and example/ is not constrained',
    'FR-028',
    "void main() { print('x'); }\n",
    path: 'example/main.dart',
    kind: 'unhappy (boundary)',
  ),
  _clean('a file with no print', 'FR-028', 'int f() => 1;\n', kind: 'happy'),
];

final List<_Case> _fr103 = [
  _hit(
    'seeded Random( in a shared adapter',
    'FR-103',
    'class S { S(int seed) : _r = Random(seed); final Random _r; }\n',
    path: _sharedAdapter,
  ),
  _hit(
    'Random.secure( in a port library',
    'FR-103',
    'final r = Random.secure();\n',
    path: _port,
  ),
  _hit(
    'DateTime.now( in a no-op',
    'FR-103',
    'final t = DateTime.now();\n',
    path: _noop,
  ),
  _hit(
    'DateTime.timestamp( in shared_ports/adapters',
    'FR-103',
    'final t = DateTime.timestamp();\n',
    path: _sharedAdapter,
  ),
  _hit(
    'Stopwatch( in a no-op',
    'FR-103',
    'final s = Stopwatch();\n',
    path: _noop,
  ),
  _hit(
    'a tear-off of DateTime.now in shared_ports',
    'FR-103',
    'final clock = DateTime.now;\n',
    path: _port,
  ),
  _hit(
    'a call on the second line is reported at that line',
    'FR-103',
    'void f() {\n  Random(1);\n}\n',
    path: _sharedAdapter,
    line: 2,
  ),
  (
    label: 'an ignore comment does not suppress the Violation',
    requirement: '$_spec FR-103, FR-009',
    path: 'unhappy (rule interaction)',
    files: _file('// ignore: unused_element\nRandom(1);\n', path: _noop),
    expected: ['FR-103 $_noop:2'],
  ),
  _clean(
    'banned calls in comments and strings',
    'FR-103',
    "// Random( DateTime.now(\n/// Stopwatch(\nconst a = 'Random.secure(';\n",
    path: _sharedAdapter,
  ),
  _clean(
    'an injected Random and a typed field',
    'FR-103',
    'class S { S(this._random); final Random _random; }\n',
    path: _sharedAdapter,
    kind: 'happy',
  ),
  _clean(
    'a domain hit is FR-027, not FR-103',
    'FR-103',
    'final r = Random(5);\n',
    kind: 'unhappy (boundary)',
  ),
  _clean(
    'a hit outside shared_ports is not FR-103',
    'FR-103',
    'final r = Random(5);\n',
    path: 'lib/src/content/adapters/x.dart',
    kind: 'unhappy (boundary)',
  ),
  _clean(
    'a folder that only starts like shared_ports',
    'FR-103',
    'final r = Random(5);\n',
    path: 'lib/src/shared_ports_extra/x.dart',
    kind: 'unhappy (boundary)',
  ),
];

void _run(
  String title,
  List<_Case> cases,
  List<Violation> Function(SourceSet) check,
) {
  /// Requirement: per case
  /// Path: per case
  group(title, () {
    for (final c in cases) {
      test('${c.label} [${c.path}] (${c.requirement})', () {
        expect(_where(check(SourceSet(c.files))), c.expected);
      });
    }
  });
}

void main() {
  // Requirement: doc/specs/architecture-guardrails.md FR-027 - a domain or
  //   application file does not call Random(, Random.secure(, DateTime.now(,
  //   DateTime.timestamp( or Stopwatch(, nor tear off DateTime.now.
  // Path: per case
  _run('FR-027 nondeterministic calls', _fr027, checkNondeterministicCalls);

  // Requirement: doc/specs/architecture-guardrails.md FR-028 - no file under
  //   lib/ makes a bare print( call; a method named print is allowed.
  // Path: per case
  _run('FR-028 print calls', _fr028, checkPrintCalls);

  // Requirement: doc/specs/architecture-guardrails.md FR-103 - no
  //   shared_ports file, adapters and no-ops included, calls what FR-027
  //   bans.
  // Path: per case
  _run(
    'FR-103 shared_ports nondeterminism',
    _fr103,
    checkSharedPortsNondeterminism,
  );

  /// Requirement: doc/specs/architecture-guardrails.md FR-011 - the output
  ///   does not depend on the order of the files in the SourceSet.
  /// Path: unhappy (determinism)
  test('the same files in another order give the same violations', () {
    final files = {
      'lib/src/b/domain/y.dart': 'final t = DateTime.now();\n',
      'lib/src/a/application/x.dart': 'final r = Random(1);\n',
    };

    final forward = checkNondeterministicCalls(SourceSet(files));
    final reversed = checkNondeterministicCalls(
      SourceSet({for (final k in files.keys.toList().reversed) k: files[k]!}),
    );

    expect(_where(forward), [
      'FR-027 lib/src/a/application/x.dart:1',
      'FR-027 lib/src/b/domain/y.dart:1',
    ]);
    expect(reversed, forward);
  });

  /// Requirement: doc/specs/architecture-guardrails.md FR-058 - a source set
  ///   with no .dart file under lib/src/ yields no Violation.
  /// Path: happy
  test('a source set with no code is clean', () {
    final empty = SourceSet({'lib/srd5e.dart': '', 'pubspec.yaml': ''});

    for (final check in bannedCallsChecks.values) {
      expect(check(empty), isEmpty);
    }
  });

  /// Requirement: doc/specs/architecture-guardrails.md FR-005 - each id has a
  ///   violating fixture on which its registered function yields that id.
  /// Path: unhappy (failure)
  group('registry wiring', () {
    for (final id in bannedCallsChecks.keys) {
      /// Requirement: doc/specs/architecture-guardrails.md FR-005 - the
      ///   fixture for the id yields a Violation with that id.
      /// Path: unhappy (failure)
      test('$id has a violating fixture', () {
        final fixture = bannedCallsViolatingFixtures[id];

        expect(fixture, isNotNull);
        final found = bannedCallsChecks[id]!(fixture!());
        expect(found.map((v) => v.checkId), contains(id));
      });
    }

    /// Requirement: doc/specs/architecture-guardrails.md FR-005 - fixtures and
    ///   functions cover the same ids.
    /// Path: unhappy (failure)
    test('fixtures and checks name the same ids', () {
      expect(
        bannedCallsViolatingFixtures.keys.toSet(),
        bannedCallsChecks.keys.toSet(),
      );
      expect(bannedCallsChecks.keys.toSet(), {'FR-027', 'FR-028', 'FR-103'});
    });
  });
}
