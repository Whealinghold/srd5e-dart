import 'package:test/test.dart';

import '../support/source_set.dart';
import '../support/violation.dart';
import 'domain_observability.dart';

const String _spec = 'doc/specs/architecture-guardrails.md';
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

Map<String, String> _domain(String body, {String path = _file}) => {path: body};

final List<_Case> _cases = [
  (
    label: 'a parameter typed Logger and named logger',
    requirement: '$_spec FR-034',
    path: 'unhappy (invalid input)',
    files: _domain('void f(Logger logger) {}\n'),
    expected: ['FR-034 $_file:1', 'FR-034 $_file:1'],
  ),
  (
    label: 'Tracer, Meter and Observability types',
    requirement: '$_spec FR-034',
    path: 'unhappy (invalid input)',
    files: _domain('Tracer a;\n\nMeter b;\nObservability c;\n'),
    expected: ['FR-034 $_file:1', 'FR-034 $_file:3', 'FR-034 $_file:4'],
  ),
  (
    label: 'NoopLogger ends in the CamelCase word Logger',
    requirement: '$_spec FR-034',
    path: 'unhappy (invalid input)',
    files: _domain('final x = const NoopLogger();\n'),
    expected: ['FR-034 $_file:1'],
  ),
  (
    label: 'variables named tracer, meter, observability and _logger',
    requirement: '$_spec FR-034',
    path: 'unhappy (invalid input)',
    files: _domain(
      'var tracer = 1;\nvar meter = 2;\nvar observability = 3;\n'
      'var _logger = 4;\n',
    ),
    expected: [
      'FR-034 $_file:1',
      'FR-034 $_file:2',
      'FR-034 $_file:3',
      'FR-034 $_file:4',
    ],
  ),
  (
    label: 'the same name twice on one line is reported once',
    requirement: '$_spec FR-034',
    path: 'unhappy (boundary)',
    files: _domain('Logger a = Logger();\n'),
    expected: ['FR-034 $_file:1'],
  ),
  (
    label: 'Parameter, Loggers and MeterReading are other identifiers',
    requirement: '$_spec FR-034',
    path: 'unhappy (false positive)',
    files: _domain(
      'final Parameter p = Parameter();\nfinal Loggers l = 1;\n'
      'final MeterReading m = 2;\nfinal thermometer = 3;\n',
    ),
    expected: [],
  ),
  (
    label: 'names in comments and strings are ignored',
    requirement: '$_spec FR-034, FR-008',
    path: 'unhappy (false positive)',
    files: _domain(
      "// Logger logger\n/// Tracer\n/* Meter */\n"
      "const a = 'Observability';\nconst b = r'logger';\n",
    ),
    expected: [],
  ),
  (
    label: 'code inside an interpolation is still examined',
    requirement: '$_spec FR-034, FR-008',
    path: 'unhappy (rule interaction)',
    files: _domain("const a = 'x \${logger.info}';\n"),
    expected: ['FR-034 $_file:1'],
  ),
  (
    label: 'an ignore comment does not suppress the Violation',
    requirement: '$_spec FR-034, FR-009',
    path: 'unhappy (rule interaction)',
    files: _domain('// ignore: unused_element\nLogger? _unused;\n'),
    expected: ['FR-034 $_file:2'],
  ),
  (
    label: 'a nested domain folder is a domain file',
    requirement: '$_spec FR-034',
    path: 'unhappy (boundary)',
    files: _domain('Meter? m;\n', path: 'lib/src/combat/domain/sub/y.dart'),
    expected: ['FR-034 lib/src/combat/domain/sub/y.dart:1'],
  ),
  (
    label: 'the application layer may use telemetry',
    requirement: '$_spec FR-034',
    path: 'happy',
    files: _domain(
      'void f(Observability observability) {}\n',
      path: 'lib/src/content/application/u.dart',
    ),
    expected: [],
  ),
  (
    label: 'a domain file with plain code is clean',
    requirement: '$_spec FR-034',
    path: 'happy',
    files: _domain('final class A {\n  const A();\n  int get v => 1;\n}\n'),
    expected: [],
  ),
];

void main() {
  /// Requirement: per case - doc/specs/architecture-guardrails.md FR-034 - a domain file
  ///   mentions no Logger, Tracer, Meter or Observability identifier and no
  ///   variable of those names.
  /// Path: per case
  group('FR-034 domain telemetry identifiers', () {
    for (final c in _cases) {
      test('${c.label} [${c.path}] (${c.requirement})', () {
        expect(
          _where(checkDomainHasNoObservability(SourceSet(c.files))),
          c.expected,
        );
      });
    }
  });

  /// Requirement: doc/specs/architecture-guardrails.md FR-058 - a source set
  ///   with no .dart file under lib/src/ yields no Violation.
  /// Path: happy
  test('a source set with no domain code is clean', () {
    expect(
      checkDomainHasNoObservability(
        SourceSet({'lib/srd5e.dart': '', 'pubspec.yaml': ''}),
      ),
      isEmpty,
    );
  });

  /// Requirement: doc/specs/architecture-guardrails.md FR-005 - each id has a
  ///   violating fixture on which its registered function yields that id.
  /// Path: unhappy (failure)
  group('registry wiring', () {
    for (final id in domainObservabilityChecks.keys) {
      /// Requirement: doc/specs/architecture-guardrails.md FR-005 - the
      ///   fixture for the id yields a Violation with that id.
      /// Path: unhappy (failure)
      test('$id has a violating fixture', () {
        final fixture = domainObservabilityViolatingFixtures[id];

        expect(fixture, isNotNull);
        final found = domainObservabilityChecks[id]!(fixture!());
        expect(found.map((v) => v.checkId), contains(id));
      });
    }

    /// Requirement: doc/specs/architecture-guardrails.md FR-005 - fixtures and
    ///   functions cover the same ids.
    /// Path: unhappy (failure)
    test('fixtures and checks name the same ids', () {
      expect(
        domainObservabilityViolatingFixtures.keys.toSet(),
        domainObservabilityChecks.keys.toSet(),
      );
      expect(domainObservabilityChecks.keys.toSet(), {'FR-034'});
    });
  });
}
