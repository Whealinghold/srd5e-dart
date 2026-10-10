import 'package:test/test.dart';

import '../support/source_set.dart';
import '../support/violation.dart';
import 'domain_purity.dart';

const String _spec = 'doc/specs/architecture-guardrails.md';
const String _p = 'package:srd5e/src/';
const String _file = 'lib/src/d20_test/domain/x.dart';

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

/// A domain file whose body is [body].
Map<String, String> _domain(String body, {String path = _file}) => {path: body};

/// A file at `lib/src/[folder]/x.dart` with one import per URI, from line 1.
Map<String, String> _imports(String folder, List<String> uris) => {
  'lib/src/$folder/x.dart': [for (final u in uris) "import '$u';"].join('\n'),
};

final List<_Case> _importCases = [
  (
    label: 'domain to own domain and shared_kernel',
    requirement: '$_spec FR-015',
    path: 'happy',
    files: _imports('d20_test/domain', [
      '${_p}d20_test/domain/y.dart',
      '${_p}shared_kernel/z.dart',
    ]),
    expected: [],
  ),
  (
    label: 'domain to an upstream barrel',
    requirement: '$_spec FR-015',
    path: 'happy',
    files: _imports('character/domain', ['${_p}d20_test/d20_test.dart']),
    expected: [],
  ),
  (
    label: 'dart:io in the domain is FR-013, not FR-015',
    requirement: '$_spec FR-015',
    path: 'unhappy (boundary)',
    files: _imports('d20_test/domain', ['dart:io']),
    expected: [],
  ),
  (
    label: 'dart:async in the application layer is allowed',
    requirement: '$_spec FR-015',
    path: 'happy',
    files: _imports('d20_test/application', ['dart:async']),
    expected: [],
  ),
  (
    label: 'an application file importing application is allowed',
    requirement: '$_spec FR-015',
    path: 'happy',
    files: _imports('content/application', [
      '${_p}content/application/ports/p.dart',
      '${_p}shared_ports/observability/noop_observability.dart',
    ]),
    expected: [],
  ),
  (
    label: 'domain to shared_ports',
    requirement: '$_spec FR-015',
    path: 'unhappy (invalid input)',
    files: _imports('d20_test/domain', [
      '${_p}shared_ports/dice_roller/dice_roller.dart',
    ]),
    expected: ['FR-015 $_file:1'],
  ),
  (
    label: 'domain to own application',
    requirement: '$_spec FR-015',
    path: 'unhappy (invalid input)',
    files: _imports('d20_test/domain', ['${_p}d20_test/application/u.dart']),
    expected: ['FR-015 $_file:1'],
  ),
  (
    label: 'domain to own adapters',
    requirement: '$_spec FR-015',
    path: 'unhappy (invalid input)',
    files: _imports('d20_test/domain', ['${_p}d20_test/adapters/a.dart']),
    expected: ['FR-015 $_file:1'],
  ),
  (
    label: 'domain to another context application',
    requirement: '$_spec FR-015',
    path: 'unhappy (rule interaction)',
    files: _imports('combat/domain', ['${_p}content/application/u.dart']),
    expected: ['FR-015 lib/src/combat/domain/x.dart:1'],
  ),
  (
    label: 'dart:async in the domain',
    requirement: '$_spec FR-015',
    path: 'unhappy (invalid input)',
    files: _imports('d20_test/domain', ['dart:async']),
    expected: ['FR-015 $_file:1'],
  ),
  (
    label: 'dart:developer in the domain',
    requirement: '$_spec FR-015',
    path: 'unhappy (invalid input)',
    files: _imports('d20_test/domain', ['dart:developer']),
    expected: ['FR-015 $_file:1'],
  ),
  (
    label: 'relative import of an application file',
    requirement: '$_spec FR-015',
    path: 'unhappy (invalid input)',
    files: _imports('d20_test/domain', ['../application/u.dart']),
    expected: ['FR-015 $_file:1'],
  ),
  (
    label: 'export and part directives count as edges',
    requirement: '$_spec FR-015',
    path: 'unhappy (rule interaction)',
    files: _domain(
      "export '../adapters/a.dart';\npart '../application/u.dart';\n",
    ),
    expected: ['FR-015 $_file:1', 'FR-015 $_file:2'],
  ),
  (
    label: 'a conditional configuration URI is an edge',
    requirement: '$_spec FR-015',
    path: 'unhappy (rule interaction)',
    files: _domain(
      "import 'dart:math'\n"
      "    if (dart.library.js_interop) 'dart:async';\n",
    ),
    expected: ['FR-015 $_file:2'],
  ),
  (
    label: 'three violations are all reported, sorted by line',
    requirement: '$_spec FR-015',
    path: 'unhappy (multiple violations)',
    files: _imports('d20_test/domain', [
      '${_p}d20_test/application/u.dart',
      'dart:math',
      'dart:async',
      '${_p}shared_ports/s.dart',
    ]),
    expected: ['FR-015 $_file:1', 'FR-015 $_file:3', 'FR-015 $_file:4'],
  ),
  (
    label: 'an import inside a comment or string is not an edge',
    requirement: '$_spec FR-015, FR-008',
    path: 'unhappy (false positive)',
    files: _domain(
      "// import 'dart:async';\n"
      "const s = \"import 'package:srd5e/src/d20_test/application/u.dart';\";\n",
    ),
    expected: [],
  ),
  (
    label: 'an ignore comment does not suppress the Violation',
    requirement: '$_spec FR-015, FR-009',
    path: 'unhappy (rule interaction)',
    files: _domain(
      "// ignore: depend_on_referenced_packages\nimport 'dart:async';\n",
    ),
    expected: ['FR-015 $_file:2'],
  ),
  (
    label: 'a file outside any domain folder is not constrained',
    requirement: '$_spec FR-015',
    path: 'unhappy (boundary)',
    files: _imports('shared_kernel', ['${_p}d20_test/application/u.dart']),
    expected: [],
  ),
];

final List<_Case> _tokenCases = [
  (
    label: 'Future and async in a signature',
    requirement: '$_spec FR-016',
    path: 'unhappy (invalid input)',
    files: _domain('Future<int> f() async => 1;\n'),
    expected: ['FR-016 $_file:1', 'FR-016 $_file:1'],
  ),
  (
    label: 'await on its own line',
    requirement: '$_spec FR-016',
    path: 'unhappy (invalid input)',
    files: _domain('void f() {\n  g(await h);\n}\n'),
    expected: ['FR-016 $_file:2'],
  ),
  (
    label: 'async* generator',
    requirement: '$_spec FR-016',
    path: 'unhappy (invalid input)',
    files: _domain('f() async* {}\n'),
    expected: ['FR-016 $_file:1'],
  ),
  (
    label: 'Stream',
    requirement: '$_spec FR-016',
    path: 'unhappy (invalid input)',
    files: _domain('Stream<int> s;\n'),
    expected: ['FR-016 $_file:1'],
  ),
  (
    label: 'FutureOr',
    requirement: '$_spec FR-016',
    path: 'unhappy (invalid input)',
    files: _domain('FutureOr<int> s;\n'),
    expected: ['FR-016 $_file:1'],
  ),
  (
    label: 'StreamController',
    requirement: '$_spec FR-016',
    path: 'unhappy (invalid input)',
    files: _domain('final c = StreamController<int>();\n'),
    expected: ['FR-016 $_file:1'],
  ),
  (
    label: 'StreamSubscription',
    requirement: '$_spec FR-016',
    path: 'unhappy (invalid input)',
    files: _domain('StreamSubscription<int>? s;\n'),
    expected: ['FR-016 $_file:1'],
  ),
  (
    label: 'Completer',
    requirement: '$_spec FR-016',
    path: 'unhappy (invalid input)',
    files: _domain('final c = Completer<int>();\n'),
    expected: ['FR-016 $_file:1'],
  ),
  (
    label: 'the same token twice on one line is reported once',
    requirement: '$_spec FR-016',
    path: 'unhappy (boundary)',
    files: _domain('Future<Future<int>> f;\n'),
    expected: ['FR-016 $_file:1'],
  ),
  (
    label: 'Futures, Streams and myFuture are different identifiers',
    requirement: '$_spec FR-016',
    path: 'unhappy (false positive)',
    files: _domain(
      'final Futures = 1;\nfinal Streams = 2;\nfinal myFuture = 3;\n',
    ),
    expected: [],
  ),
  (
    label: 'tokens in comments and strings are ignored',
    requirement: '$_spec FR-016, FR-008',
    path: 'unhappy (false positive)',
    files: _domain(
      "// Future async await\n/// Stream\n/* Completer */\n"
      "const a = 'Future';\nconst b = r'async';\n"
      "const c = '''\nStream\n''';\n",
    ),
    expected: [],
  ),
  (
    label: 'code inside an interpolation is still examined',
    requirement: '$_spec FR-016, FR-008',
    path: 'unhappy (rule interaction)',
    files: _domain("const a = 'x \${await y}';\n"),
    expected: ['FR-016 $_file:1'],
  ),
  (
    label: 'an ignore comment does not suppress the Violation',
    requirement: '$_spec FR-016, FR-009',
    path: 'unhappy (rule interaction)',
    files: _domain('// ignore: avoid_void_async\nFuture<void> f() async {}\n'),
    expected: ['FR-016 $_file:2', 'FR-016 $_file:2'],
  ),
  (
    label: 'a nested domain folder is a domain file',
    requirement: '$_spec FR-016',
    path: 'unhappy (boundary)',
    files: _domain(
      'Future<int>? f;\n',
      path: 'lib/src/combat/domain/sub/y.dart',
    ),
    expected: ['FR-016 lib/src/combat/domain/sub/y.dart:1'],
  ),
  (
    label: 'the application layer may use Future',
    requirement: '$_spec FR-016',
    path: 'happy',
    files: _domain(
      'Future<int> f() async => 1;\n',
      path: 'lib/src/content/application/u.dart',
    ),
    expected: [],
  ),
  (
    label: 'a domain file with plain synchronous code is clean',
    requirement: '$_spec FR-016',
    path: 'happy',
    files: _domain('final class A {\n  const A();\n  int get v => 1;\n}\n'),
    expected: [],
  ),
];

void _run(String title, List<_Case> cases) {
  /// Requirement: per case
  /// Path: per case
  group(title, () {
    for (final c in cases) {
      test('${c.label} [${c.path}] (${c.requirement})', () {
        expect(_where(checkDomainPurity(SourceSet(c.files))), c.expected);
      });
    }
  });
}

void main() {
  // Requirement: doc/specs/architecture-guardrails.md FR-015 - a domain file
  //   imports no application, adapters or shared_ports path and no
  //   dart:async or dart:developer.
  // Path: per case
  _run('FR-015 domain imports', _importCases);

  // Requirement: doc/specs/architecture-guardrails.md FR-016 - a domain file
  //   contains none of async, await, Future, Stream and their relatives.
  // Path: per case
  _run('FR-016 domain tokens', _tokenCases);

  /// Requirement: doc/specs/architecture-guardrails.md FR-011 - the output
  ///   does not depend on the order of the files in the SourceSet.
  /// Path: unhappy (determinism)
  test('the same files in another order give the same violations', () {
    final files = {
      'lib/src/b/domain/y.dart': 'Future<int>? f;\n',
      'lib/src/a/domain/x.dart': "import 'dart:async';\n",
    };

    final forward = checkDomainPurity(SourceSet(files));
    final reversed = checkDomainPurity(
      SourceSet({for (final k in files.keys.toList().reversed) k: files[k]!}),
    );

    expect(_where(forward), [
      'FR-015 lib/src/a/domain/x.dart:1',
      'FR-016 lib/src/b/domain/y.dart:1',
    ]);
    expect(reversed, forward);
  });

  /// Requirement: doc/specs/architecture-guardrails.md FR-058 - a source set
  /// with no .dart file under lib/src/ yields no Violation.
  /// Path: happy
  test('a source set with no domain code is clean', () {
    expect(
      checkDomainPurity(SourceSet({'lib/srd5e.dart': '', 'pubspec.yaml': ''})),
      isEmpty,
    );
  });

  /// Requirement: doc/specs/architecture-guardrails.md FR-005 - each id has a
  ///   violating fixture on which its registered function yields that id.
  /// Path: unhappy (failure)
  group('registry wiring', () {
    for (final id in domainPurityChecks.keys) {
      /// Requirement: doc/specs/architecture-guardrails.md FR-005 - the
      ///   fixture for the id yields a Violation with that id.
      /// Path: unhappy (failure)
      test('$id has a violating fixture', () {
        final fixture = domainPurityViolatingFixtures[id];

        expect(fixture, isNotNull);
        final found = domainPurityChecks[id]!(fixture!());
        expect(found.map((v) => v.checkId), contains(id));
      });
    }

    /// Requirement: doc/specs/architecture-guardrails.md FR-005 - fixtures and
    ///   functions cover the same ids.
    /// Path: unhappy (failure)
    test('fixtures and checks name the same ids', () {
      expect(
        domainPurityViolatingFixtures.keys.toSet(),
        domainPurityChecks.keys.toSet(),
      );
      expect(domainPurityChecks.keys.toSet(), {'FR-015', 'FR-016'});
    });
  });
}
