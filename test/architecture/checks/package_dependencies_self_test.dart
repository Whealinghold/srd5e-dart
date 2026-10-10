import 'package:test/test.dart';

import '../support/source_set.dart';
import '../support/violation.dart';
import 'package_dependencies.dart';

const String _spec = 'doc/specs/architecture-guardrails.md';

typedef _Case = ({
  String label,
  String requirement,
  String path,
  String pubspec,
  List<String> expectedSdk,
  List<String> expectedAllowlist,
});

List<String> _where(List<Violation> violations) => [
  for (final v in violations) '${v.checkId} ${v.path}:${v.line}',
];

final List<_Case> _cases = [
  (
    label: 'collection and meta only',
    requirement: '$_spec FR-033, FR-083',
    path: 'happy',
    pubspec:
        'name: srd5e\n'
        'environment:\n'
        '  sdk: ">=3.9.0 <4.0.0"\n'
        'dependencies:\n'
        '  collection: ^1.19.1\n'
        '  meta: ^1.14.0\n'
        'dev_dependencies:\n'
        '  test: ^1.25.0\n',
    expectedSdk: [],
    expectedAllowlist: [],
  ),
  (
    label: 'http, path and logging under dependencies',
    requirement: '$_spec FR-033, FR-083',
    path: 'unhappy (invalid input)',
    pubspec:
        'name: srd5e\n'
        'dependencies:\n'
        '  collection: ^1.19.1\n'
        '  http: ^1.0.0\n'
        '  path: ^1.9.0\n'
        '  logging: ^1.2.0\n',
    expectedSdk: ['FR-033 pubspec.yaml:6'],
    expectedAllowlist: [
      'FR-083 pubspec.yaml:4',
      'FR-083 pubspec.yaml:5',
      'FR-083 pubspec.yaml:6',
    ],
  ),
  (
    label: 'the same packages under dev_dependencies',
    requirement: '$_spec FR-033, FR-083',
    path: 'unhappy (boundary)',
    pubspec:
        'name: srd5e\n'
        'dependencies:\n'
        '  meta: ^1.14.0\n'
        'dev_dependencies:\n'
        '  http: ^1.0.0\n'
        '  logging: ^1.2.0\n'
        '  sentry: ^8.0.0\n',
    expectedSdk: [],
    expectedAllowlist: [],
  ),
  (
    label: 'each denylist prefix matches by prefix',
    requirement: '$_spec FR-033',
    path: 'unhappy (invalid input)',
    pubspec:
        'dependencies:\n'
        '  opentelemetry: ^0.18.0\n'
        '  sentry_flutter: ^8.0.0\n'
        '  logger: ^2.0.0\n'
        '  datadog_flutter_plugin: ^2.0.0\n'
        '  bugsnag_flutter: ^4.0.0\n'
        '  newrelic_mobile: ^1.0.0\n'
        '  firebase_crashlytics: ^4.0.0\n',
    expectedSdk: [
      'FR-033 pubspec.yaml:2',
      'FR-033 pubspec.yaml:3',
      'FR-033 pubspec.yaml:4',
      'FR-033 pubspec.yaml:5',
      'FR-033 pubspec.yaml:6',
      'FR-033 pubspec.yaml:7',
      'FR-033 pubspec.yaml:8',
    ],
    expectedAllowlist: [
      'FR-083 pubspec.yaml:2',
      'FR-083 pubspec.yaml:3',
      'FR-083 pubspec.yaml:4',
      'FR-083 pubspec.yaml:5',
      'FR-083 pubspec.yaml:6',
      'FR-083 pubspec.yaml:7',
      'FR-083 pubspec.yaml:8',
    ],
  ),
  (
    label: 'a nested map belongs to its entry, a comment is ignored',
    requirement: '$_spec FR-083',
    path: 'unhappy (rule interaction)',
    pubspec:
        'dependencies:\n'
        '  # http: ^1.0.0\n'
        '  meta: ^1.14.0\n'
        '  flutter:\n'
        '    sdk: flutter\n'
        '  collection:\n'
        '    version: ^1.19.1\n',
    expectedSdk: [],
    expectedAllowlist: ['FR-083 pubspec.yaml:4'],
  ),
  (
    label: 'a quoted name and a dependency_overrides block',
    requirement: '$_spec FR-083',
    path: 'unhappy (boundary)',
    pubspec:
        'dependencies:\n'
        '  "meta": ^1.14.0\n'
        '  \'path\': ^1.9.0\n'
        'dependency_overrides:\n'
        '  http: ^1.0.0\n',
    expectedSdk: [],
    expectedAllowlist: ['FR-083 pubspec.yaml:3'],
  ),
  (
    label: 'no dependencies block at all',
    requirement: '$_spec FR-083',
    path: 'unhappy (empty and minimal)',
    pubspec: 'name: srd5e\n',
    expectedSdk: [],
    expectedAllowlist: [],
  ),
  (
    label: 'an ignore comment does not suppress the Violation',
    requirement: '$_spec FR-083, FR-009',
    path: 'unhappy (rule interaction)',
    pubspec:
        'dependencies:\n'
        '  # ignore: allow\n'
        '  http: ^1.0.0 # ignore\n',
    expectedSdk: [],
    expectedAllowlist: ['FR-083 pubspec.yaml:3'],
  ),
];

void main() {
  /// Requirement: per case - doc/specs/architecture-guardrails.md FR-033 - dependencies
  ///   lists no observability or error-tracking package.
  /// Path: per case
  group('FR-033 observability packages in dependencies', () {
    for (final c in _cases) {
      test('${c.label} [${c.path}] (${c.requirement})', () {
        final sources = SourceSet({pubspecPath: c.pubspec});

        expect(
          _where(checkNoObservabilitySdkDependency(sources)),
          c.expectedSdk,
        );
      });
    }
  });

  /// Requirement: per case - doc/specs/architecture-guardrails.md FR-083 - dependencies
  ///   lists only collection and meta.
  /// Path: per case
  group('FR-083 dependency allowlist', () {
    for (final c in _cases) {
      test('${c.label} [${c.path}] (${c.requirement})', () {
        final sources = SourceSet({pubspecPath: c.pubspec});

        expect(_where(checkDependencyAllowlist(sources)), c.expectedAllowlist);
      });
    }
  });

  /// Requirement: doc/specs/architecture-guardrails.md FR-058 - a source set
  ///   without a pubspec.yaml yields no Violation (FR-012 reports the wrong
  ///   root).
  /// Path: unhappy (empty and minimal)
  test('a source set with no pubspec.yaml is clean', () {
    final empty = SourceSet({'lib/srd5e.dart': ''});

    expect(checkNoObservabilitySdkDependency(empty), isEmpty);
    expect(checkDependencyAllowlist(empty), isEmpty);
  });

  /// Requirement: doc/specs/architecture-guardrails.md FR-005 - each id has a
  ///   violating fixture on which its registered function yields that id.
  /// Path: unhappy (failure)
  group('registry wiring', () {
    for (final id in packageDependenciesChecks.keys) {
      /// Requirement: doc/specs/architecture-guardrails.md FR-005 - the
      ///   fixture for the id yields a Violation with that id.
      /// Path: unhappy (failure)
      test('$id has a violating fixture', () {
        final fixture = packageDependenciesViolatingFixtures[id];

        expect(fixture, isNotNull);
        final found = packageDependenciesChecks[id]!(fixture!());
        expect(found.map((v) => v.checkId), contains(id));
      });
    }

    /// Requirement: doc/specs/architecture-guardrails.md FR-005 - fixtures and
    ///   functions cover the same ids.
    /// Path: unhappy (failure)
    test('fixtures and checks name the same ids', () {
      expect(
        packageDependenciesViolatingFixtures.keys.toSet(),
        packageDependenciesChecks.keys.toSet(),
      );
      expect(packageDependenciesChecks.keys.toSet(), {'FR-033', 'FR-083'});
    });
  });
}
