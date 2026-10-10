import 'package:test/test.dart';

import '../support/source_set.dart';
import '../support/violation.dart';
import 'observability_sdk.dart';

const String _spec = 'doc/specs/architecture-guardrails.md';
const String _file = 'lib/src/content/adapters/a.dart';

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

Map<String, String> _lib(String body, {String path = _file}) => {path: body};

final List<_Case> _cases = [
  (
    label: 'only package:meta and package:collection',
    requirement: '$_spec FR-032',
    path: 'happy',
    files: _lib(
      "import 'package:meta/meta.dart';\n"
      "import 'package:collection/collection.dart';\n"
      "import 'dart:math';\n",
    ),
    expected: [],
  ),
  (
    label: 'package:sentry_flutter',
    requirement: '$_spec FR-032',
    path: 'unhappy (invalid input)',
    files: _lib("import 'package:sentry_flutter/sentry_flutter.dart';\n"),
    expected: ['FR-032 $_file:1'],
  ),
  (
    label: 'package:logging',
    requirement: '$_spec FR-032',
    path: 'unhappy (invalid input)',
    files: _lib("\nimport 'package:logging/logging.dart';\n"),
    expected: ['FR-032 $_file:2'],
  ),
  (
    label: 'dart:developer',
    requirement: '$_spec FR-032',
    path: 'unhappy (invalid input)',
    files: _lib("import 'dart:developer';\n"),
    expected: ['FR-032 $_file:1'],
  ),
  (
    label: 'each prefix of the denylist matches by prefix',
    requirement: '$_spec FR-032',
    path: 'unhappy (boundary)',
    files: _lib(
      "import 'package:opentelemetry/api.dart';\n"
      "import 'package:dart_opentelemetry/x.dart';\n"
      "import 'package:logger/logger.dart';\n"
      "import 'package:datadog_flutter_plugin/x.dart';\n"
      "import 'package:bugsnag_flutter/x.dart';\n"
      "import 'package:newrelic_mobile/x.dart';\n"
      "import 'package:firebase_crashlytics/x.dart';\n",
    ),
    expected: [
      'FR-032 $_file:1',
      'FR-032 $_file:2',
      'FR-032 $_file:3',
      'FR-032 $_file:4',
      'FR-032 $_file:5',
      'FR-032 $_file:6',
      'FR-032 $_file:7',
    ],
  ),
  (
    label: 'an export is an edge too',
    requirement: '$_spec FR-032',
    path: 'unhappy (rule interaction)',
    files: _lib("export 'package:sentry/sentry.dart';\n"),
    expected: ['FR-032 $_file:1'],
  ),
  (
    label: 'a conditional configuration URI is an edge',
    requirement: '$_spec FR-032, FR-064',
    path: 'unhappy (rule interaction)',
    files: _lib(
      "import 'dart:math'\n    if (dart.library.io) 'dart:developer';\n",
    ),
    expected: ['FR-032 $_file:2'],
  ),
  (
    label: 'a package that only contains a denied word in the middle',
    requirement: '$_spec FR-032',
    path: 'unhappy (false positive)',
    files: _lib("import 'package:blogging_tools/x.dart';\n"),
    expected: [],
  ),
  (
    label: 'an import in a comment or string is not an edge',
    requirement: '$_spec FR-032, FR-008',
    path: 'unhappy (false positive)',
    files: _lib(
      "// import 'package:sentry/sentry.dart';\n"
      "const s = \"import 'dart:developer';\";\n",
    ),
    expected: [],
  ),
  (
    label: 'an ignore comment does not suppress the Violation',
    requirement: '$_spec FR-032, FR-009',
    path: 'unhappy (rule interaction)',
    files: _lib(
      "// ignore: depend_on_referenced_packages\n"
      "import 'package:logging/logging.dart';\n",
    ),
    expected: ['FR-032 $_file:2'],
  ),
  (
    label: 'the same import under test/ is outside the scan',
    requirement: '$_spec FR-032',
    path: 'unhappy (boundary)',
    files: _lib(
      "import 'package:logging/logging.dart';\n",
      path: 'test/x_test.dart',
    ),
    expected: [],
  ),
  (
    label: 'two violations in two files are all reported, sorted',
    requirement: '$_spec FR-032',
    path: 'unhappy (multiple violations)',
    files: {
      'lib/src/b/b.dart': "import 'dart:developer';\n",
      'lib/src/a/a.dart': "\nimport 'package:sentry/sentry.dart';\n",
    },
    expected: ['FR-032 lib/src/a/a.dart:2', 'FR-032 lib/src/b/b.dart:1'],
  ),
];

void main() {
  /// Requirement: per case - doc/specs/architecture-guardrails.md FR-032 - a file under
  ///   lib/ imports no observability or error-tracking package and not
  ///   dart:developer.
  /// Path: per case
  group('FR-032 observability SDK imports', () {
    for (final c in _cases) {
      test('${c.label} [${c.path}] (${c.requirement})', () {
        expect(
          _where(checkNoObservabilitySdkImports(SourceSet(c.files))),
          c.expected,
        );
      });
    }
  });

  /// Requirement: doc/specs/architecture-guardrails.md FR-058 - a source set
  ///   with no .dart file under lib/src/ yields no Violation.
  /// Path: happy
  test('a source set with no Dart code is clean', () {
    expect(
      checkNoObservabilitySdkImports(
        SourceSet({'lib/srd5e.dart': '', 'pubspec.yaml': ''}),
      ),
      isEmpty,
    );
  });

  /// Requirement: doc/specs/architecture-guardrails.md FR-005 - each id has a
  ///   violating fixture on which its registered function yields that id.
  /// Path: unhappy (failure)
  group('registry wiring', () {
    for (final id in observabilitySdkChecks.keys) {
      /// Requirement: doc/specs/architecture-guardrails.md FR-005 - the
      ///   fixture for the id yields a Violation with that id.
      /// Path: unhappy (failure)
      test('$id has a violating fixture', () {
        final fixture = observabilitySdkViolatingFixtures[id];

        expect(fixture, isNotNull);
        final found = observabilitySdkChecks[id]!(fixture!());
        expect(found.map((v) => v.checkId), contains(id));
      });
    }

    /// Requirement: doc/specs/architecture-guardrails.md FR-005 - fixtures and
    ///   functions cover the same ids.
    /// Path: unhappy (failure)
    test('fixtures and checks name the same ids', () {
      expect(
        observabilitySdkViolatingFixtures.keys.toSet(),
        observabilitySdkChecks.keys.toSet(),
      );
      expect(observabilitySdkChecks.keys.toSet(), {'FR-032'});
    });
  });
}
