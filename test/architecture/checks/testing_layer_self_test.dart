import 'package:test/test.dart';

import '../support/source_set.dart';
import '../support/violation.dart';
import 'testing_layer.dart';

typedef _Case = ({
  String label,
  String requirement,
  String path,
  SourceSet sources,
  List<String> expected,
});

List<String> _where(List<Violation> violations) => [
  for (final v in violations) '${v.checkId} ${v.path}:${v.line}',
];

String _import(String uri) => "import '$uri';\n";

const String _spec = 'doc/specs/architecture-guardrails.md';
const String _fr074 = '$_spec FR-074';
const String _fr075 = '$_spec FR-075';
const String _fr081 = '$_spec FR-081';
const String _fr082 = '$_spec FR-082';

const String _testing = 'lib/src/testing';
const String _ports = 'lib/src/shared_ports';
const String _diceRoller = '$_ports/dice_roller.dart';

const String _diceRollerSource =
    '/// A roller.\nabstract interface class DiceRoller {\n  int roll();\n}\n';

_Case _case(
  String requirement,
  String label,
  Map<String, String> files,
  List<String> expected, {
  String path = 'happy',
}) => (
  label: label,
  requirement: requirement,
  path: path,
  sources: SourceSet(files),
  expected: expected,
);

final List<_Case> _fr074Cases = [
  _case(_fr074, 'the testing entry point exports doubles', {
    'lib/testing.dart':
        "export 'src/testing/a.dart';\n"
        "export 'package:srd5e/src/testing/b.dart' show B;\n",
    '$_testing/a.dart': '',
    '$_testing/b.dart': '',
  }, []),
  _case(_fr074, 'a double imports another double', {
    '$_testing/a.dart': _import('b.dart'),
    '$_testing/b.dart': '',
  }, []),
  _case(_fr074, 'a context file imports a shared port, not a double', {
    'lib/src/combat/application/a.dart': _import('../../shared_ports/p.dart'),
    '$_ports/p.dart': '',
  }, []),
  _case(
    _fr074,
    'a context file imports a double by relative URI',
    {
      'lib/src/combat/application/a.dart': _import('../../testing/t.dart'),
      '$_testing/t.dart': '',
    },
    ['FR-074 lib/src/combat/application/a.dart:1'],
    path: 'unhappy (rule interaction)',
  ),
  _case(
    _fr074,
    'an entry point exports a double by package URI',
    {
      'lib/srd5e.dart': "\nexport 'package:srd5e/src/testing/t.dart';\n",
      '$_testing/t.dart': '',
    },
    ['FR-074 lib/srd5e.dart:2'],
    path: 'unhappy (rule interaction)',
  ),
  _case(
    _fr074,
    'the adapters entry point and an adapter reach a double',
    {
      'lib/adapters.dart': "export 'src/testing/t.dart';\n",
      'lib/src/content/adapters/a.dart': _import(
        'package:srd5e/src/testing/t.dart',
      ),
      '$_testing/t.dart': '',
    },
    ['FR-074 lib/adapters.dart:1', 'FR-074 lib/src/content/adapters/a.dart:1'],
    path: 'unhappy (multiple violations)',
  ),
  _case(
    _fr074,
    'a conditional import of a double is an edge',
    {
      'lib/src/content/a.dart':
          "import 'b.dart'\n    if (dart.library.io) '../testing/t.dart';\n",
      'lib/src/content/b.dart': '',
      '$_testing/t.dart': '',
    },
    ['FR-074 lib/src/content/a.dart:2'],
    path: 'unhappy (boundary)',
  ),
  _case(
    _fr074,
    'an import in a comment is no edge',
    {
      'lib/src/content/a.dart': "// import '../testing/t.dart';\n",
      '$_testing/t.dart': '',
    },
    [],
    path: 'unhappy (false positive)',
  ),
  _case(
    _fr074,
    'an ignore comment does not hide the import',
    {
      'lib/src/content/a.dart':
          '// ignore: implementation_imports\n${_import('../testing/t.dart')}',
      '$_testing/t.dart': '',
    },
    ['FR-074 lib/src/content/a.dart:2'],
    path: 'unhappy (rule interaction)',
  ),
  _case(_fr074, 'a test file under the default scope is not scanned', {
    'test/a_test.dart': _import('package:srd5e/src/testing/t.dart'),
    '$_testing/t.dart': '',
  }, []),
];

final List<_Case> _fr075Cases = [
  _case(_fr075, 'a double uses a port, barrels, a double and the kernel', {
    '$_testing/a.dart':
        _import('../shared_ports/p.dart') +
        _import('../content/content.dart') +
        _import('../combat/combat.dart') +
        _import('b.dart') +
        _import('package:srd5e/src/shared_kernel/k.dart'),
    '$_testing/b.dart': '',
    '$_ports/p.dart': '',
    'lib/src/content/content.dart': '',
    'lib/src/combat/combat.dart': '',
    'lib/src/shared_kernel/k.dart': '',
  }, []),
  _case(_fr075, 'a double uses dart:, meta and collection', {
    '$_testing/a.dart':
        _import('dart:collection') +
        _import('dart:async') +
        _import('package:meta/meta.dart') +
        _import('package:collection/collection.dart'),
  }, []),
  _case(_fr075, 'the same import outside the doubles is not FR-075', {
    'lib/src/combat/application/a.dart': _import('../../content/domain/s.dart'),
    'lib/src/content/domain/s.dart': '',
  }, []),
  _case(
    _fr075,
    'a double reaches context internals',
    {
      '$_testing/a.dart': _import('../content/domain/species.dart'),
      'lib/src/content/domain/species.dart': '',
    },
    ['FR-075 $_testing/a.dart:1'],
    path: 'unhappy (invalid input)',
  ),
  _case(
    _fr075,
    'a double reaches a context adapter and the shared adapters',
    {
      '$_testing/a.dart':
          _import('../content/adapters/a.dart') +
          _import('../shared_ports/adapters/s.dart'),
      'lib/src/content/adapters/a.dart': '',
      '$_ports/adapters/s.dart': '',
    },
    ['FR-075 $_testing/a.dart:1', 'FR-075 $_testing/a.dart:2'],
    path: 'unhappy (invalid input)',
  ),
  _case(
    _fr075,
    'a double imports an entry point',
    {
      '$_testing/a.dart':
          _import('package:srd5e/srd5e.dart') +
          _import('../../adapters.dart') +
          _import('../../testing.dart'),
      'lib/srd5e.dart': '',
      'lib/adapters.dart': '',
      'lib/testing.dart': '',
    },
    [
      'FR-075 $_testing/a.dart:1',
      'FR-075 $_testing/a.dart:2',
      'FR-075 $_testing/a.dart:3',
    ],
    path: 'unhappy (rule interaction)',
  ),
  _case(
    _fr075,
    'a double imports another package and a loose lib/src file',
    {
      '$_testing/a.dart':
          _import('package:flutter/foundation.dart') + _import('../loose.dart'),
      'lib/src/loose.dart': '',
    },
    ['FR-075 $_testing/a.dart:1', 'FR-075 $_testing/a.dart:2'],
    path: 'unhappy (invalid input)',
  ),
  _case(
    _fr075,
    'a double exports a context file and a conditional import is read',
    {
      '$_testing/a.dart':
          "export '../content/domain/s.dart';\n"
          "import 'b.dart'\n    if (dart.library.io) '../content/adapters/a.dart';\n",
      '$_testing/b.dart': '',
      'lib/src/content/domain/s.dart': '',
      'lib/src/content/adapters/a.dart': '',
    },
    ['FR-075 $_testing/a.dart:1', 'FR-075 $_testing/a.dart:3'],
    path: 'unhappy (boundary)',
  ),
  _case(
    _fr075,
    'an ignore comment does not hide the import',
    {
      '$_testing/a.dart':
          '// ignore: implementation_imports\n'
          '${_import('../content/domain/s.dart')}',
      'lib/src/content/domain/s.dart': '',
    },
    ['FR-075 $_testing/a.dart:2'],
    path: 'unhappy (rule interaction)',
  ),
];

final List<_Case> _fr081Cases = [
  _case(_fr081, 'a double of a port under lib/src/testing/', {
    _diceRoller: _diceRollerSource,
    '$_testing/fake_dice_roller.dart':
        'class FakeDiceRoller implements DiceRoller {}\n',
  }, []),
  _case(_fr081, 'a Noop class beside the ports is not a double', {
    _diceRoller: _diceRollerSource,
    '$_ports/noop.dart':
        'final class NoopDiceRoller implements DiceRoller {}\n',
  }, []),
  _case(_fr081, 'a shared adapter without a double prefix', {
    _diceRoller: _diceRollerSource,
    '$_ports/adapters/seeded.dart':
        'final class SeededDiceRoller implements DiceRoller {}\n',
  }, []),
  _case(_fr081, 'a port handle double outside lib/src/testing/ is clean', {
    '$_ports/observability/tracer.dart': 'abstract interface class Span {}\n',
    'lib/src/content/adapters/fake_span.dart':
        'class FakeSpan implements Span {}\n',
  }, []),
  _case(_fr081, 'a double prefix on a class of a non-port is clean', {
    'lib/src/content/domain/base.dart': 'abstract class Base {}\n',
    'lib/src/content/domain/fake.dart': 'class FakeThing implements Base {}\n',
  }, []),
  _case(_fr081, 'no ports at all is vacuous', {
    'lib/src/content/domain/fake.dart': 'class FakeThing implements Port {}\n',
  }, []),
  _case(_fr081, 'a double in test/ is out of scope', {
    _diceRoller: _diceRollerSource,
    'test/fake_dice_roller.dart':
        'class FakeDiceRoller implements DiceRoller {}\n',
  }, []),
  _case(
    _fr081,
    'a Fake implementing a shared port in a context',
    {
      _diceRoller: _diceRollerSource,
      'lib/src/content/adapters/fake.dart':
          '\nclass FakeDiceRoller implements DiceRoller {}\n',
    },
    ['FR-081 lib/src/content/adapters/fake.dart:2'],
    path: 'unhappy (invalid input)',
  ),
  _case(
    _fr081,
    'each double prefix is a double, inside shared_ports too',
    {
      _diceRoller: _diceRollerSource,
      '$_ports/doubles.dart':
          'class RecordingA implements DiceRoller {}\n'
          'class FixedB extends DiceRoller {}\n'
          'class ScriptedC implements DiceRoller {}\n'
          'class StubD implements DiceRoller {}\n'
          'class SpyE implements DiceRoller {}\n'
          'class MockF with Other implements DiceRoller {}\n',
    },
    [
      'FR-081 $_ports/doubles.dart:1',
      'FR-081 $_ports/doubles.dart:2',
      'FR-081 $_ports/doubles.dart:3',
      'FR-081 $_ports/doubles.dart:4',
      'FR-081 $_ports/doubles.dart:5',
      'FR-081 $_ports/doubles.dart:6',
    ],
    path: 'unhappy (multiple violations)',
  ),
  _case(
    _fr081,
    'a double of a context application port, with a prefixed type name',
    {
      'lib/src/content/application/ports/content_source.dart':
          'abstract interface class ContentSource {}\n',
      'lib/src/combat/domain/fake.dart':
          'import "x.dart" as p;\n'
          'class FakeContentSource implements p.ContentSource {}\n',
    },
    ['FR-081 lib/src/combat/domain/fake.dart:2'],
    path: 'unhappy (invalid input)',
  ),
  _case(
    _fr081,
    'a double named in a comment or string is clean',
    {
      _diceRoller: _diceRollerSource,
      'lib/src/content/a.dart':
          '// class FakeA implements DiceRoller {}\n'
          "const s = 'class FakeB implements DiceRoller {}';\n",
    },
    [],
    path: 'unhappy (false positive)',
  ),
  _case(
    _fr081,
    'an ignore comment does not hide the double',
    {
      _diceRoller: _diceRollerSource,
      'lib/src/content/a.dart':
          '// ignore: unused_element\n'
          'class FakeA implements DiceRoller {}\n',
    },
    ['FR-081 lib/src/content/a.dart:2'],
    path: 'unhappy (rule interaction)',
  ),
];

const String _doubleSource = 'class FixedDiceRoller implements DiceRoller {}\n';

final List<_Case> _fr082Cases = [
  _case(_fr082, 'a port with an exported double and a contract suite', {
    _diceRoller: _diceRollerSource,
    '$_testing/fixed.dart': _doubleSource,
    'lib/testing.dart':
        "export 'src/testing/fixed.dart' show FixedDiceRoller;\n",
    'test/contract/dice_roller_contract.dart': '',
  }, []),
  _case(_fr082, 'a double exported without show or hide', {
    _diceRoller: _diceRollerSource,
    '$_testing/fixed.dart': _doubleSource,
    'lib/testing.dart': "export 'package:srd5e/src/testing/fixed.dart';\n",
    'test/contract/dice_roller_contract.dart': '',
  }, []),
  _case(_fr082, 'the four handles need neither double nor contract', {
    '$_ports/observability/tracer.dart': 'abstract interface class Span {}\n',
    '$_ports/observability/meter.dart':
        'abstract interface class Counter {}\n'
        'abstract interface class Histogram {}\n'
        'abstract interface class Gauge {}\n',
  }, []),
  _case(_fr082, 'a shared adapter, a plain abstract class, a final class', {
    '$_ports/adapters/a.dart': 'abstract interface class Adapter {}\n',
    '$_ports/b.dart': 'abstract class Base {}\n',
    '$_ports/c.dart': 'final class Thing {}\n',
    'lib/src/content/application/ports/d.dart': 'abstract class NotAPort {}\n',
  }, []),
  _case(_fr082, 'no ports at all is vacuous', {
    'lib/srd5e.dart': '',
    'lib/testing.dart': '',
  }, []),
  _case(
    _fr082,
    'a port with no double',
    {
      _diceRoller: _diceRollerSource,
      'lib/testing.dart': '',
      'test/contract/dice_roller_contract.dart': '',
    },
    ['FR-082 $_diceRoller:2'],
    path: 'unhappy (missing content)',
  ),
  _case(
    _fr082,
    'a double that lib/testing.dart does not export',
    {
      _diceRoller: _diceRollerSource,
      '$_testing/fixed.dart': _doubleSource,
      'lib/testing.dart': "export 'src/testing/other.dart';\n",
      '$_testing/other.dart': '',
      'test/contract/dice_roller_contract.dart': '',
    },
    ['FR-082 $_diceRoller:2'],
    path: 'unhappy (missing content)',
  ),
  _case(
    _fr082,
    'no lib/testing.dart at all',
    {
      _diceRoller: _diceRollerSource,
      '$_testing/fixed.dart': _doubleSource,
      'test/contract/dice_roller_contract.dart': '',
    },
    ['FR-082 $_diceRoller:2'],
    path: 'unhappy (missing content)',
  ),
  _case(
    _fr082,
    'a double hidden or left out by show and hide',
    {
      _diceRoller: _diceRollerSource,
      '$_testing/fixed.dart': _doubleSource,
      'lib/testing.dart':
          "export 'src/testing/fixed.dart' show Other;\n"
          "export 'src/testing/fixed.dart' hide FixedDiceRoller;\n",
      'test/contract/dice_roller_contract.dart': '',
    },
    ['FR-082 $_diceRoller:2'],
    path: 'unhappy (boundary)',
  ),
  _case(
    _fr082,
    'a port with no contract suite, and a misnamed one',
    {
      _diceRoller: _diceRollerSource,
      '$_testing/fixed.dart': _doubleSource,
      'lib/testing.dart': "export 'src/testing/fixed.dart';\n",
      'test/contract/diceroller_contract.dart': '',
    },
    ['FR-082 $_diceRoller:2'],
    path: 'unhappy (missing content)',
  ),
  _case(
    _fr082,
    'a port missing both reports both at its declaration',
    {_diceRoller: _diceRollerSource},
    ['FR-082 $_diceRoller:2', 'FR-082 $_diceRoller:2'],
    path: 'unhappy (multiple violations)',
  ),
  _case(
    _fr082,
    'a context application port needs its own double and snake_case file',
    {
      'lib/src/content/application/ports/content_source.dart':
          'abstract interface class ContentSource {}\n',
      '$_ports/dice_roller.dart': _diceRollerSource,
      '$_testing/fixed.dart': _doubleSource,
      'lib/testing.dart': "export 'src/testing/fixed.dart';\n",
      'test/contract/dice_roller_contract.dart': '',
    },
    [
      'FR-082 lib/src/content/application/ports/content_source.dart:1',
      'FR-082 lib/src/content/application/ports/content_source.dart:1',
    ],
    path: 'unhappy (missing content)',
  ),
  _case(
    _fr082,
    'a double only named in a comment does not count',
    {
      _diceRoller: _diceRollerSource,
      '$_testing/fixed.dart':
          '// class FixedDiceRoller implements DiceRoller {}\n',
      'lib/testing.dart': "export 'src/testing/fixed.dart';\n",
      'test/contract/dice_roller_contract.dart': '',
    },
    ['FR-082 $_diceRoller:2'],
    path: 'unhappy (false positive)',
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
        expect(_where(check(c.sources)), c.expected);
      });
    }
  });
}

void main() {
  // Requirement: doc/specs/architecture-guardrails.md FR-074 - only
  //   lib/testing.dart imports or exports a file under lib/src/testing/.
  // Path: per case
  _run(
    'FR-074 doubles reached only by the entry point',
    _fr074Cases,
    checkTestingImportedOnlyByEntryPoint,
  );

  // Requirement: doc/specs/architecture-guardrails.md FR-075 - a double
  //   imports only the SDK, meta, collection, doubles, the shared modules
  //   and context barrels.
  // Path: per case
  _run('FR-075 imports of doubles', _fr075Cases, checkTestingImports);

  // Requirement: doc/specs/architecture-guardrails.md FR-081 - a port double
  //   is declared under lib/src/testing/.
  // Path: per case
  _run(
    'FR-081 doubles live in testing',
    _fr081Cases,
    checkDoublesLiveInTesting,
  );

  // Requirement: doc/specs/architecture-guardrails.md FR-082 - every port has
  //   an exported double and a contract suite.
  // Path: per case
  _run(
    'FR-082 ports have doubles and contracts',
    _fr082Cases,
    checkPortsHaveDoublesAndContracts,
  );

  /// Requirement: doc/specs/architecture-guardrails.md FR-074 - the scope is a
  ///   parameter; with test/ in it a test importing a double is reported.
  /// Path: unhappy (boundary)
  test('FR-074 widened to test/ reports a test importing a double', () {
    final sources = SourceSet({
      'test/a_test.dart': _import('package:srd5e/src/testing/t.dart'),
      '$_testing/t.dart': '',
    });

    final found = checkTestingImportedOnlyByEntryPoint(
      sources,
      scope: const ['lib/', 'test/'],
    );

    expect(_where(found), ['FR-074 test/a_test.dart:1']);
  });

  /// Requirement: doc/specs/architecture-guardrails.md FR-082 - a Violation
  ///   names the missing double or contract file.
  /// Path: unhappy (failure)
  test('FR-082 details name the missing pieces', () {
    final found = checkPortsHaveDoublesAndContracts(
      SourceSet({_diceRoller: _diceRollerSource}),
    );

    expect(found.map((v) => v.detail).join('\n'), contains('no test double'));
    expect(
      found.map((v) => v.detail).join('\n'),
      contains('test/contract/dice_roller_contract.dart'),
    );
  });

  /// Requirement: doc/specs/architecture-guardrails.md FR-004, FR-011 - the
  ///   combined check reports every id, sorted by path and line.
  /// Path: unhappy (multiple violations)
  test('the combined check reports every id, sorted', () {
    final found = checkTestingLayer(
      SourceSet({
        _diceRoller: _diceRollerSource,
        '$_testing/a.dart': _import('../content/domain/s.dart'),
        'lib/src/content/domain/s.dart': '',
        'lib/src/content/application/a.dart': _import('../../testing/a.dart'),
        'lib/src/content/adapters/fake.dart':
            'class FakeDiceRoller implements DiceRoller {}\n',
      }),
    );

    expect(_where(found), [
      'FR-081 lib/src/content/adapters/fake.dart:1',
      'FR-074 lib/src/content/application/a.dart:1',
      'FR-082 $_diceRoller:2',
      'FR-082 $_diceRoller:2',
      'FR-075 $_testing/a.dart:1',
    ]);
  });

  /// Requirement: doc/specs/architecture-guardrails.md FR-058 - a fixture with
  ///   no Dart file under lib/src/ yields no Violation.
  /// Path: happy
  test('a source set with no files under lib/src/ is clean', () {
    final sources = SourceSet({'lib/srd5e.dart': '', 'pubspec.yaml': ''});

    expect(checkTestingLayer(sources), isEmpty);
  });

  /// Requirement: doc/specs/architecture-guardrails.md FR-005 - each id has a
  ///   violating fixture on which its registered function yields that id.
  /// Path: unhappy (failure)
  group('registry wiring', () {
    for (final id in testingLayerChecks.keys) {
      /// Requirement: doc/specs/architecture-guardrails.md FR-005 - the
      ///   fixture for the id yields a Violation with that id.
      /// Path: unhappy (failure)
      test('$id has a violating fixture', () {
        final fixture = testingLayerViolatingFixtures[id];

        expect(fixture, isNotNull);
        final found = testingLayerChecks[id]!(fixture!());
        expect(found.map((v) => v.checkId), contains(id));
      });
    }

    /// Requirement: doc/specs/architecture-guardrails.md FR-005 - fixtures and
    ///   functions cover the same ids.
    /// Path: unhappy (failure)
    test('fixtures and checks name the same ids', () {
      expect(
        testingLayerViolatingFixtures.keys.toSet(),
        testingLayerChecks.keys.toSet(),
      );
      expect(testingLayerChecks.keys.toSet(), {
        'FR-074',
        'FR-075',
        'FR-081',
        'FR-082',
      });
    });
  });
}
