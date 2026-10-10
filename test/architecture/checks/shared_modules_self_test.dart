import 'package:test/test.dart';

import '../support/source_set.dart';
import '../support/violation.dart';
import 'shared_modules.dart';

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

const String _fr023 = 'doc/specs/architecture-guardrails.md FR-023';
const String _fr024 = 'doc/specs/architecture-guardrails.md FR-024';

const String _kernel = 'lib/src/shared_kernel';
const String _ports = 'lib/src/shared_ports';

_Case _kernelCase(
  String label,
  Map<String, String> files,
  List<String> expected, {
  String path = 'happy',
}) => (
  label: label,
  requirement: _fr023,
  path: path,
  sources: SourceSet(files),
  expected: expected,
);

_Case _portsCase(
  String label,
  Map<String, String> files,
  List<String> expected, {
  String path = 'happy',
}) => (
  label: label,
  requirement: _fr024,
  path: path,
  sources: SourceSet(files),
  expected: expected,
);

final List<_Case> _fr023Cases = [
  _kernelCase('kernel to a sibling and to a sub-folder file', {
    '$_kernel/a.dart': _import('b.dart') + _import('dice/c.dart'),
    '$_kernel/b.dart': '',
    '$_kernel/dice/c.dart': _import('../a.dart'),
  }, []),
  _kernelCase('kernel to dart: libraries, meta and collection', {
    '$_kernel/a.dart':
        _import('dart:math') +
        _import('dart:io') +
        _import('package:meta/meta.dart') +
        _import('package:collection/collection.dart'),
  }, []),
  _kernelCase('kernel to kernel by package URI', {
    '$_kernel/a.dart': _import('package:srd5e/src/shared_kernel/b.dart'),
    '$_kernel/b.dart': '',
  }, []),
  _kernelCase('the same import outside the kernel is not FR-023', {
    'lib/src/content/a.dart': _import('../shared_ports/b.dart'),
    '$_ports/b.dart': '',
  }, []),
  _kernelCase(
    'kernel to shared_ports',
    {
      '$_kernel/a.dart': _import('../shared_ports/b.dart'),
      '$_ports/b.dart': '',
    },
    ['FR-023 $_kernel/a.dart:1'],
    path: 'unhappy (invalid input)',
  ),
  _kernelCase(
    'kernel to the aggregate entry point',
    {
      '$_kernel/a.dart': '// header\n${_import('package:srd5e/srd5e.dart')}',
      'lib/srd5e.dart': '',
    },
    ['FR-023 $_kernel/a.dart:2'],
    path: 'unhappy (invalid input)',
  ),
  _kernelCase(
    'kernel exports a context barrel',
    {
      '$_kernel/a.dart': "export '../content/content.dart';\n",
      'lib/src/content/content.dart': '',
    },
    ['FR-023 $_kernel/a.dart:1'],
    path: 'unhappy (invalid input)',
  ),
  _kernelCase(
    'kernel reaches a file outside lib/ and one outside the repository',
    {
      '$_kernel/a.dart':
          _import('../../../tool/x.dart') + _import('../../../../x.dart'),
      'tool/x.dart': '',
    },
    ['FR-023 $_kernel/a.dart:1', 'FR-023 $_kernel/a.dart:2'],
    path: 'unhappy (boundary)',
  ),
  _kernelCase(
    'a conditional import of an outside file',
    {
      '$_kernel/a.dart':
          "import 'b.dart'\n    if (dart.library.io) '../shared_ports/c.dart';\n",
      '$_kernel/b.dart': '',
      '$_ports/c.dart': '',
    },
    ['FR-023 $_kernel/a.dart:2'],
    path: 'unhappy (rule interaction)',
  ),
  _kernelCase(
    'every violation is reported, in order',
    {
      '$_kernel/b.dart': _import('../shared_ports/p.dart'),
      '$_kernel/a.dart':
          _import('../shared_ports/p.dart') +
          _import('../content/content.dart'),
      '$_ports/p.dart': '',
      'lib/src/content/content.dart': '',
    },
    [
      'FR-023 $_kernel/a.dart:1',
      'FR-023 $_kernel/a.dart:2',
      'FR-023 $_kernel/b.dart:1',
    ],
    path: 'unhappy (multiple violations)',
  ),
  _kernelCase(
    'an import in a comment or a string is no edge',
    {
      '$_kernel/a.dart':
          "// import '../shared_ports/p.dart';\n"
          "const s = \"import '../shared_ports/p.dart';\";\n",
      '$_ports/p.dart': '',
    },
    [],
    path: 'unhappy (false positive)',
  ),
  _kernelCase(
    'an ignore comment does not hide the import',
    {
      '$_kernel/a.dart':
          '// ignore: depend_on_referenced_packages\n'
          '${_import('../shared_ports/p.dart')}',
      '$_ports/p.dart': '',
    },
    ['FR-023 $_kernel/a.dart:2'],
    path: 'unhappy (rule interaction)',
  ),
];

final List<_Case> _fr024Cases = [
  _portsCase('ports to kernel and to a sibling port file', {
    '$_ports/a.dart': _import('../shared_kernel/k.dart') + _import('b.dart'),
    '$_ports/b.dart': '',
    '$_kernel/k.dart': '',
  }, []),
  _portsCase('shared adapter to its port and to the kernel', {
    '$_ports/adapters/s.dart':
        _import('../dice_roller/dice_roller.dart') +
        _import('../../shared_kernel/k.dart'),
    '$_ports/dice_roller/dice_roller.dart': '',
    '$_kernel/k.dart': '',
  }, []),
  _portsCase('ports to dart:async, meta and collection', {
    '$_ports/a.dart':
        _import('dart:async') +
        _import('package:meta/meta.dart') +
        _import('package:collection/collection.dart'),
  }, []),
  _portsCase('ports importing the adapters folder is FR-017, not FR-024', {
    '$_ports/a.dart': _import('adapters/s.dart'),
    '$_ports/adapters/s.dart': '',
  }, []),
  _portsCase('the same import outside shared_ports is not FR-024', {
    'lib/src/content/a.dart': _import('../content/content.dart'),
    'lib/src/content/content.dart': '',
  }, []),
  _portsCase(
    'ports to a context barrel',
    {
      '$_ports/a.dart': _import('../content/content.dart'),
      'lib/src/content/content.dart': '',
    },
    ['FR-024 $_ports/a.dart:1'],
    path: 'unhappy (invalid input)',
  ),
  _portsCase(
    'shared adapter to a context barrel',
    {
      '$_ports/adapters/s.dart':
          '\n\n${_import('package:srd5e/src/content/content.dart')}',
      'lib/src/content/content.dart': '',
    },
    ['FR-024 $_ports/adapters/s.dart:3'],
    path: 'unhappy (invalid input)',
  ),
  _portsCase(
    'ports to the doubles and to an entry point',
    {
      '$_ports/a.dart':
          _import('../testing/t.dart') + _import('package:srd5e/adapters.dart'),
      'lib/src/testing/t.dart': '',
      'lib/adapters.dart': '',
    },
    ['FR-024 $_ports/a.dart:1', 'FR-024 $_ports/a.dart:2'],
    path: 'unhappy (rule interaction)',
  ),
  _portsCase(
    'ports exporting a context file',
    {
      '$_ports/observability/o.dart': "export '../../combat/combat.dart';\n",
      'lib/src/combat/combat.dart': '',
    },
    ['FR-024 $_ports/observability/o.dart:1'],
    path: 'unhappy (invalid input)',
  ),
  _portsCase(
    'an ignore comment does not hide the import',
    {
      '$_ports/a.dart':
          '// ignore_for_file: implementation_imports\n'
          '${_import('../content/content.dart')}',
      'lib/src/content/content.dart': '',
    },
    ['FR-024 $_ports/a.dart:2'],
    path: 'unhappy (rule interaction)',
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
  // Requirement: doc/specs/architecture-guardrails.md FR-023 - a
  //   shared_kernel file imports nothing in the package outside
  //   shared_kernel.
  // Path: per case
  _run('FR-023 shared_kernel imports', _fr023Cases, checkSharedKernelImports);

  // Requirement: doc/specs/architecture-guardrails.md FR-024 - a
  //   shared_ports file imports only shared_kernel and shared_ports.
  // Path: per case
  _run('FR-024 shared_ports imports', _fr024Cases, checkSharedPortsImports);

  /// Requirement: doc/specs/architecture-guardrails.md FR-023 - a Violation
  ///   names the file, the line and the import.
  /// Path: unhappy (failure)
  test('a violation names the import and where it leads', () {
    final found = checkSharedKernelImports(
      SourceSet({
        '$_kernel/a.dart': _import('../shared_ports/b.dart'),
        '$_ports/b.dart': '',
      }),
    );

    expect(found, hasLength(1));
    expect(found.single.checkId, 'FR-023');
    expect(found.single.detail, contains('../shared_ports/b.dart'));
    expect(found.single.detail, contains('$_ports/b.dart'));
  });

  /// Requirement: doc/specs/architecture-guardrails.md FR-004, FR-011 - the
  ///   combined check reports every violation of both ids, sorted.
  /// Path: unhappy (multiple violations)
  test('the combined check reports both ids, sorted by path', () {
    final found = checkSharedModules(
      SourceSet({
        '$_kernel/a.dart': _import('../shared_ports/b.dart'),
        '$_ports/b.dart': _import('../content/content.dart'),
        'lib/src/content/content.dart': '',
      }),
    );

    expect(_where(found), [
      'FR-023 $_kernel/a.dart:1',
      'FR-024 $_ports/b.dart:1',
    ]);
  });

  /// Requirement: doc/specs/architecture-guardrails.md FR-058 - a fixture
  ///   with no Dart file under lib/src/ yields no Violation.
  /// Path: happy
  test('a source set with no shared module files is clean', () {
    final sources = SourceSet({'lib/srd5e.dart': '', 'pubspec.yaml': ''});

    expect(checkSharedModules(sources), isEmpty);
  });

  /// Requirement: doc/specs/architecture-guardrails.md FR-005 - each id has a
  ///   violating fixture on which its registered function yields that id.
  /// Path: unhappy (failure)
  group('registry wiring', () {
    for (final id in sharedModulesChecks.keys) {
      /// Requirement: doc/specs/architecture-guardrails.md FR-005 - the
      ///   fixture for the id yields a Violation with that id.
      /// Path: unhappy (failure)
      test('$id has a violating fixture', () {
        final fixture = sharedModulesViolatingFixtures[id];

        expect(fixture, isNotNull);
        final found = sharedModulesChecks[id]!(fixture!());
        expect(found.map((v) => v.checkId), contains(id));
      });
    }

    /// Requirement: doc/specs/architecture-guardrails.md FR-005 - fixtures and
    ///   functions cover the same ids.
    /// Path: unhappy (failure)
    test('fixtures and checks name the same ids', () {
      expect(
        sharedModulesViolatingFixtures.keys.toSet(),
        sharedModulesChecks.keys.toSet(),
      );
      expect(sharedModulesChecks.keys.toSet(), {'FR-023', 'FR-024'});
    });
  });
}
