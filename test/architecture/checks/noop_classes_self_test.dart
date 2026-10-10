import 'package:test/test.dart';

import '../support/source_set.dart';
import '../support/violation.dart';
import 'noop_classes.dart';

const String _spec = 'doc/specs/architecture-guardrails.md';
const String _logger = 'lib/src/shared_ports/observability/logger.dart';
const String _bundle = 'lib/src/shared_ports/observability/observability.dart';
const String _other = 'lib/src/shared_ports/observability/other.dart';

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

List<String> Function(SourceSet) _run(
  List<Violation> Function(SourceSet) check,
) =>
    (sources) => _where(check(sources));

const String _goodBundle =
    "import 'package:meta/meta.dart';\n"
    '@immutable\n'
    'final class Observability {\n'
    '  const Observability();\n'
    '}\n'
    'final class NoopObservability extends Observability {\n'
    '  const NoopObservability();\n'
    '}\n';

final List<_Case> _noopCases = [
  (
    label: 'NoopLogger with a const constructor in shared_ports',
    requirement: '$_spec FR-084',
    path: 'happy',
    files: {_logger: 'final class NoopLogger {\n  const NoopLogger();\n}\n'},
    expected: [],
  ),
  (
    label: 'a named const constructor and an annotation',
    requirement: '$_spec FR-084',
    path: 'happy',
    files: {
      _logger:
          'final class NoopLogger {\n'
          '  @literal\n'
          '  const NoopLogger.silent();\n'
          '}\n',
    },
    expected: [],
  ),
  (
    label: 'a non-const constructor',
    requirement: '$_spec FR-084',
    path: 'unhappy (invalid input)',
    files: {_logger: 'final class NoopLogger {\n\n  NoopLogger();\n}\n'},
    expected: ['FR-084 $_logger:3'],
  ),
  (
    label: 'a const and a non-const constructor mixed',
    requirement: '$_spec FR-084',
    path: 'unhappy (invalid input)',
    files: {
      _logger:
          'final class NoopLogger {\n'
          '  const NoopLogger();\n'
          '  NoopLogger.other();\n'
          '}\n',
    },
    expected: ['FR-084 $_logger:3'],
  ),
  (
    label: 'a class with no explicit constructor',
    requirement: '$_spec FR-084',
    path: 'unhappy (missing content)',
    files: {_logger: 'final class NoopLogger {\n  int get v => 1;\n}\n'},
    expected: ['FR-084 $_logger:1'],
  ),
  (
    label: 'the class under shared_ports/adapters/',
    requirement: '$_spec FR-084',
    path: 'unhappy (rule interaction)',
    files: {
      'lib/src/shared_ports/adapters/noop_x.dart':
          'final class NoopX {\n  const NoopX();\n}\n',
    },
    expected: ['FR-084 lib/src/shared_ports/adapters/noop_x.dart:1'],
  ),
  (
    label: 'the class under a context application folder',
    requirement: '$_spec FR-084',
    path: 'unhappy (rule interaction)',
    files: {
      'lib/src/d20_test/application/noop_x.dart':
          'final class NoopX {\n  const NoopX();\n}\n',
    },
    expected: ['FR-084 lib/src/d20_test/application/noop_x.dart:1'],
  ),
  (
    label: 'the class under lib/src/testing/',
    requirement: '$_spec FR-084',
    path: 'unhappy (rule interaction)',
    files: {
      'lib/src/testing/noop_x.dart':
          'final class NoopX {\n  const NoopX();\n}\n',
    },
    expected: ['FR-084 lib/src/testing/noop_x.dart:1'],
  ),
  (
    label: 'wrong place and non-const are both reported',
    requirement: '$_spec FR-084',
    path: 'unhappy (multiple violations)',
    files: {
      'lib/src/d20_test/application/noop_x.dart':
          'class NoopX {\n  NoopX();\n}\nclass NoopY {}\n',
    },
    expected: [
      'FR-084 lib/src/d20_test/application/noop_x.dart:1',
      'FR-084 lib/src/d20_test/application/noop_x.dart:2',
      'FR-084 lib/src/d20_test/application/noop_x.dart:4',
      'FR-084 lib/src/d20_test/application/noop_x.dart:4',
    ],
  ),
  (
    label: 'private _NoopSpan and NotNoop do not start with Noop',
    requirement: '$_spec FR-084',
    path: 'unhappy (false positive)',
    files: {
      _logger:
          'final class _NoopSpan {\n  _NoopSpan();\n}\n'
          'class NotNoop {\n  NotNoop();\n}\n',
    },
    expected: [],
  ),
  (
    label: 'a Noop class in a comment or string is ignored',
    requirement: '$_spec FR-084, FR-008',
    path: 'unhappy (false positive)',
    files: {
      'lib/src/d20_test/application/a.dart':
          "// class NoopX {}\nconst s = 'class NoopY {}';\n",
    },
    expected: [],
  ),
  (
    label: 'a Noop class under test/ is outside the scan',
    requirement: '$_spec FR-084',
    path: 'unhappy (boundary)',
    files: {'test/x_test.dart': 'class NoopX {}\n'},
    expected: [],
  ),
  (
    label: 'an ignore comment does not suppress the Violation',
    requirement: '$_spec FR-084, FR-009',
    path: 'unhappy (rule interaction)',
    files: {
      _logger:
          'final class NoopLogger {\n'
          '  // ignore: prefer_const_constructors\n'
          '  NoopLogger();\n'
          '}\n',
    },
    expected: ['FR-084 $_logger:3'],
  ),
];

final List<_Case> _bundleCases = [
  (
    label: 'both classes final in one file, immutable, const',
    requirement: '$_spec FR-104',
    path: 'happy',
    files: {_bundle: _goodBundle},
    expected: [],
  ),
  (
    label: 'other annotations beside @immutable',
    requirement: '$_spec FR-104',
    path: 'happy',
    files: {
      _bundle: _goodBundle.replaceFirst(
        '@immutable\n',
        "@Deprecated('x')\n@immutable\n",
      ),
    },
    expected: [],
  ),
  (
    label: 'Observability is not final',
    requirement: '$_spec FR-104',
    path: 'unhappy (invalid input)',
    files: {_bundle: _goodBundle.replaceFirst('final class Obs', 'class Obs')},
    expected: ['FR-104 $_bundle:3'],
  ),
  (
    label: 'NoopObservability is not final',
    requirement: '$_spec FR-104',
    path: 'unhappy (invalid input)',
    files: {
      _bundle: _goodBundle.replaceFirst('final class Noop', 'class Noop'),
    },
    expected: ['FR-104 $_bundle:6'],
  ),
  (
    label: 'NoopObservability in another file',
    requirement: '$_spec FR-104',
    path: 'unhappy (rule interaction)',
    files: {
      _bundle:
          "import 'package:meta/meta.dart';\n"
          '@immutable\n'
          'final class Observability {\n'
          '  const Observability();\n'
          '}\n',
      _other:
          'final class NoopObservability extends Observability {\n'
          '  const NoopObservability();\n'
          '}\n',
    },
    expected: ['FR-104 $_other:1'],
  ),
  (
    label: 'NoopObservability with a non-const constructor',
    requirement: '$_spec FR-104, FR-084',
    path: 'unhappy (rule interaction)',
    files: {
      _bundle: _goodBundle.replaceFirst(
        'const NoopObservability();',
        'NoopObservability();',
      ),
    },
    expected: ['FR-104 $_bundle:7'],
  ),
  (
    label: 'the @immutable annotation is missing',
    requirement: '$_spec FR-104',
    path: 'unhappy (invalid input)',
    files: {_bundle: _goodBundle.replaceFirst('@immutable\n', '')},
    expected: ['FR-104 $_bundle:2'],
  ),
  (
    label: 'NoopObservability does not extend Observability',
    requirement: '$_spec FR-104',
    path: 'unhappy (invalid input)',
    files: {_bundle: _goodBundle.replaceFirst(' extends Observability', '')},
    expected: ['FR-104 $_bundle:6'],
  ),
  (
    label: 'both classes outside the observability folder',
    requirement: '$_spec FR-104',
    path: 'unhappy (invalid input)',
    files: {'lib/src/shared_ports/observability.dart': _goodBundle},
    expected: [
      'FR-104 lib/src/shared_ports/observability.dart:3',
      'FR-104 lib/src/shared_ports/observability.dart:6',
    ],
  ),
  (
    label: 'Observability declared without NoopObservability',
    requirement: '$_spec FR-104',
    path: 'unhappy (missing content)',
    files: {
      _bundle:
          "import 'package:meta/meta.dart';\n"
          '@immutable\n'
          'final class Observability {\n'
          '  const Observability();\n'
          '}\n',
    },
    expected: ['FR-104 $_bundle:3'],
  ),
  (
    label: 'neither class is declared',
    requirement: '$_spec FR-104',
    path: 'unhappy (empty and minimal)',
    files: {_logger: 'final class NoopLogger {\n  const NoopLogger();\n}\n'},
    expected: [],
  ),
  (
    label: 'a class only mentioning the names in a comment',
    requirement: '$_spec FR-104, FR-008',
    path: 'unhappy (false positive)',
    files: {_bundle: '// class Observability {}\n'},
    expected: [],
  ),
];

final List<_Case> _globalCases = [
  (
    label: 'a static const no-op default',
    requirement: '$_spec FR-035',
    path: 'happy',
    files: {
      'lib/src/shared_ports/observability/observability.dart':
          'class A {\n'
          '  static const Observability none = NoopObservability();\n'
          '}\n',
    },
    expected: [],
  ),
  (
    label: 'a top-level const no-op',
    requirement: '$_spec FR-035',
    path: 'happy',
    files: {_logger: 'const Logger quiet = NoopLogger();\n'},
    expected: [],
  ),
  (
    label: 'a static final logger',
    requirement: '$_spec FR-035',
    path: 'unhappy (invalid input)',
    files: {
      _logger: 'class A {\n  static final Logger shared = NoopLogger();\n}\n',
    },
    expected: ['FR-035 $_logger:2'],
  ),
  (
    label: 'a top-level final logger',
    requirement: '$_spec FR-035',
    path: 'unhappy (invalid input)',
    files: {_logger: '\nfinal Logger logger = NoopLogger();\n'},
    expected: ['FR-035 $_logger:2'],
  ),
  (
    label: 'a top-level late tracer and a nullable meter',
    requirement: '$_spec FR-035',
    path: 'unhappy (invalid input)',
    files: {_logger: 'late Tracer tracer;\nMeter? meter;\n'},
    expected: ['FR-035 $_logger:1', 'FR-035 $_logger:2'],
  ),
  (
    label: 'a var whose initialiser names a no-op',
    requirement: '$_spec FR-035',
    path: 'unhappy (invalid input)',
    files: {_logger: 'var tracer = NoopTracer();\n'},
    expected: ['FR-035 $_logger:1'],
  ),
  (
    label: 'a static map of loggers with a literal initialiser',
    requirement: '$_spec FR-035',
    path: 'unhappy (invalid input)',
    files: {
      _logger:
          'class A {\n'
          "  static final m = {'a': NoopLogger()};\n"
          '  static final Map<String, Logger> loggers = {};\n'
          '}\n',
    },
    expected: ['FR-035 $_logger:2', 'FR-035 $_logger:3'],
  ),
  (
    label: 'a static Observability in an enum',
    requirement: '$_spec FR-035',
    path: 'unhappy (rule interaction)',
    files: {_logger: 'enum E {\n  a;\n  static Observability? shared;\n}\n'},
    expected: ['FR-035 $_logger:3'],
  ),
  (
    label: 'instance fields, functions and getters are not globals',
    requirement: '$_spec FR-035',
    path: 'unhappy (false positive)',
    files: {
      _logger:
          'class A {\n'
          '  final Logger logger;\n'
          '  const A(this.logger);\n'
          '  static Logger make() => const NoopLogger();\n'
          '  static Logger get shared => const NoopLogger();\n'
          '}\n'
          'Logger build() => const NoopLogger();\n',
    },
    expected: [],
  ),
  (
    label: 'Parameter is not a Meter',
    requirement: '$_spec FR-035',
    path: 'unhappy (false positive)',
    files: {
      _logger:
          'class A {\n  static final Parameter p = Parameter();\n}\n'
          'final Parameter q = Parameter();\n',
    },
    expected: [],
  ),
  (
    label: 'a declaration in a comment or string is ignored',
    requirement: '$_spec FR-035, FR-008',
    path: 'unhappy (false positive)',
    files: {
      _logger:
          '// final Logger a = NoopLogger();\n'
          "const s = 'final Logger b = NoopLogger();';\n",
    },
    expected: [],
  ),
  (
    label: 'an ignore comment does not suppress the Violation',
    requirement: '$_spec FR-035, FR-009',
    path: 'unhappy (rule interaction)',
    files: {
      _logger:
          '// ignore: non_constant_identifier_names\n'
          'final Logger logger = NoopLogger();\n',
    },
    expected: ['FR-035 $_logger:2'],
  ),
  (
    label: 'a global outside lib/ is not scanned',
    requirement: '$_spec FR-035',
    path: 'unhappy (boundary)',
    files: {'test/x.dart': 'final Logger logger = NoopLogger();\n'},
    expected: [],
  ),
];

void _group(
  String title,
  List<_Case> cases,
  List<Violation> Function(SourceSet) check,
) {
  /// Requirement: per case
  /// Path: per case
  group(title, () {
    for (final c in cases) {
      test('${c.label} [${c.path}] (${c.requirement})', () {
        expect(_run(check)(SourceSet(c.files)), c.expected);
      });
    }
  });
}

void main() {
  // Requirement: doc/specs/architecture-guardrails.md FR-035 - a top-level
  //   or static logger, tracer, meter or bundle is a Violation unless const.
  // Path: per case
  _group(
    'FR-035 global observability',
    _globalCases,
    checkNoGlobalObservability,
  );

  // Requirement: doc/specs/architecture-guardrails.md FR-084 - every Noop
  //   class is in shared_ports/, outside adapters/, with only const
  //   constructors and at least one.
  // Path: per case
  _group('FR-084 Noop classes', _noopCases, checkNoopClasses);

  // Requirement: doc/specs/architecture-guardrails.md FR-104 -
  //   Observability and NoopObservability are final, share one file,
  //   Observability is immutable and the no-op extends it with const
  //   constructors.
  // Path: per case
  _group(
    'FR-104 observability bundle classes',
    _bundleCases,
    checkObservabilityClasses,
  );

  /// Requirement: doc/specs/architecture-guardrails.md FR-104, FR-084 - a
  ///   non-const NoopObservability constructor is reported by both checks.
  /// Path: unhappy (rule interaction)
  test('a non-const NoopObservability constructor fires FR-084 as well', () {
    final sources = SourceSet({
      _bundle: _goodBundle.replaceFirst(
        'const NoopObservability();',
        'NoopObservability();',
      ),
    });

    expect(_where(checkNoopClasses(sources)), ['FR-084 $_bundle:7']);
    expect(_where(checkObservabilityClasses(sources)), ['FR-104 $_bundle:7']);
  });

  /// Requirement: doc/specs/observability-ports.md FR-059 - the const
  ///   exemption: a const instance of a no-op class is not a static or
  ///   top-level logger, tracer or meter, and a non-const one is.
  /// Path: unhappy (rule interaction)
  test('a const no-op is exempt from FR-035 and a non-const one is not', () {
    final constant = SourceSet({
      _logger:
          'const Logger quiet = NoopLogger();\n'
          'class A {\n'
          '  static const Tracer none = NoopTracer();\n'
          '}\n',
    });
    final mutable = SourceSet({_logger: 'Meter meter = NoopMeter();\n'});

    expect(checkNoGlobalObservability(constant), isEmpty);
    expect(_where(checkNoGlobalObservability(mutable)), ['FR-035 $_logger:1']);
  });

  /// Requirement: doc/specs/architecture-guardrails.md FR-058 - a source set
  ///   with no .dart file under lib/src/ yields no Violation.
  /// Path: happy
  test('a source set with no Dart code is clean', () {
    final empty = SourceSet({'lib/srd5e.dart': '', 'pubspec.yaml': ''});

    expect(checkNoGlobalObservability(empty), isEmpty);
    expect(checkNoopClasses(empty), isEmpty);
    expect(checkObservabilityClasses(empty), isEmpty);
  });

  /// Requirement: doc/specs/architecture-guardrails.md FR-005 - each id has a
  ///   violating fixture on which its registered function yields that id.
  /// Path: unhappy (failure)
  group('registry wiring', () {
    for (final id in noopClassesChecks.keys) {
      /// Requirement: doc/specs/architecture-guardrails.md FR-005 - the
      ///   fixture for the id yields a Violation with that id.
      /// Path: unhappy (failure)
      test('$id has a violating fixture', () {
        final fixture = noopClassesViolatingFixtures[id];

        expect(fixture, isNotNull);
        final found = noopClassesChecks[id]!(fixture!());
        expect(found.map((v) => v.checkId), contains(id));
      });
    }

    /// Requirement: doc/specs/architecture-guardrails.md FR-005 - fixtures and
    ///   functions cover the same ids.
    /// Path: unhappy (failure)
    test('fixtures and checks name the same ids', () {
      expect(
        noopClassesViolatingFixtures.keys.toSet(),
        noopClassesChecks.keys.toSet(),
      );
      expect(noopClassesChecks.keys.toSet(), {'FR-035', 'FR-084', 'FR-104'});
    });
  });
}
