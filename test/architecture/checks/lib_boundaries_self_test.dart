import 'package:test/test.dart';

import '../support/source_set.dart';
import '../support/violation.dart';
import 'lib_boundaries.dart';

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

const String _fr076 = 'doc/specs/architecture-guardrails.md FR-076';
const String _fr095 = 'doc/specs/architecture-guardrails.md FR-095';

const String _adapter = 'lib/src/content/adapters/embedded_source.dart';
const String _application = 'lib/src/content/application/load.dart';
const String _domain = 'lib/src/content/domain/species.dart';
const String _data = 'lib/src/content/data/species_data.dart';
const String _dataOther = 'lib/src/content/data/spell_data.dart';

final List<_Case> _fr076Cases = [
  (
    label: 'lib imports a file of tool/',
    requirement: _fr076,
    path: 'unhappy (invalid input)',
    files: {
      _adapter: "import '../../../../tool/generate.dart';\n",
      'tool/generate.dart': '',
    },
    expected: ['FR-076 $_adapter:1'],
  ),
  (
    label: 'lib imports a contract suite',
    requirement: _fr076,
    path: 'unhappy (invalid input)',
    files: {
      _adapter: "\nimport '../../../../test/contract/x_contract.dart';\n",
      'test/contract/x_contract.dart': '',
    },
    expected: ['FR-076 $_adapter:2'],
  ),
  (
    label: 'lib imports package:test',
    requirement: _fr076,
    path: 'unhappy (invalid input)',
    files: {_application: "import 'package:test/test.dart';\n"},
    expected: ['FR-076 $_application:1'],
  ),
  (
    label: 'package:test_api, package:matcher and package:coverage',
    requirement: _fr076,
    path: 'unhappy (invalid input)',
    files: {
      _application:
          "import 'package:test_api/test_api.dart';\n"
          "import 'package:matcher/matcher.dart';\n"
          "import 'package:coverage/coverage.dart';\n",
    },
    expected: [
      'FR-076 $_application:1',
      'FR-076 $_application:2',
      'FR-076 $_application:3',
    ],
  ),
  (
    label: 'an export of tool/ and an export of package:test',
    requirement: _fr076,
    path: 'unhappy (invalid input)',
    files: {
      'lib/srd5e.dart':
          "export 'src/a.dart';\n"
          "export '../tool/generate.dart';\n"
          "export 'package:test/test.dart' show test;\n",
      'lib/src/a.dart': '',
      'tool/generate.dart': '',
    },
    expected: ['FR-076 lib/srd5e.dart:2', 'FR-076 lib/srd5e.dart:3'],
  ),
  (
    label: 'a relative import from lib/adapters.dart onto tool/',
    requirement: _fr076,
    path: 'unhappy (boundary)',
    files: {'lib/adapters.dart': "import '../tool/x.dart';\n"},
    expected: ['FR-076 lib/adapters.dart:1'],
  ),
  (
    label: 'a relative import that climbs to the repository root',
    requirement: _fr076,
    path: 'unhappy (boundary)',
    files: {_application: "import '../../../../analysis.dart';\n"},
    expected: ['FR-076 $_application:1'],
  ),
  (
    label: 'a relative import that climbs out of the repository',
    requirement: _fr076,
    path: 'unhappy (boundary)',
    files: {_application: "import '../../../../../../x.dart';\n"},
    expected: ['FR-076 $_application:1'],
  ),
  (
    label: 'a package URI that climbs out of lib/',
    requirement: _fr076,
    path: 'unhappy (boundary)',
    files: {_application: "import 'package:srd5e/../tool/x.dart';\n"},
    expected: ['FR-076 $_application:1'],
  ),
  (
    label: 'a conditional configuration that names tool/',
    requirement: _fr076,
    path: 'unhappy (rule interaction)',
    files: {
      _application:
          "import 'a.dart' if (dart.library.io) '../../../../tool/x.dart';\n",
      'lib/src/content/application/a.dart': '',
    },
    expected: ['FR-076 $_application:1'],
  ),
  (
    label: 'relative and package imports that stay in lib/',
    requirement: _fr076,
    path: 'happy',
    files: {
      _application:
          "import '../domain/species.dart';\n"
          "import 'package:srd5e/src/shared_kernel/modifier.dart';\n"
          "import 'package:meta/meta.dart';\n"
          "import 'package:collection/collection.dart';\n"
          "import 'dart:io';\n",
      _domain: '',
      'lib/src/shared_kernel/modifier.dart': '',
    },
    expected: [],
  ),
  (
    label: 'a package whose name only starts like a dev package',
    requirement: _fr076,
    path: 'unhappy (false positive)',
    files: {
      _application:
          "import 'package:testing_tools/x.dart';\n"
          "import 'package:test_core/x.dart';\n",
    },
    expected: [],
  ),
  (
    label: 'tool/ and test/ importing lib/ and package:test',
    requirement: _fr076,
    path: 'happy',
    files: {
      'tool/generate.dart': "import '../lib/src/content/content.dart';\n",
      'test/a_test.dart':
          "import 'package:test/test.dart';\n"
          "import '../lib/srd5e.dart';\n"
          "import '../tool/generate.dart';\n",
      'lib/srd5e.dart': '',
      'lib/src/content/content.dart': '',
    },
    expected: [],
  ),
  (
    label: 'an import in a comment or a string',
    requirement: 'doc/specs/architecture-guardrails.md FR-008, FR-076',
    path: 'unhappy (false positive)',
    files: {
      _application:
          "// import 'package:test/test.dart';\n"
          "const s = \"import '../../../../tool/x.dart';\";\n",
    },
    expected: [],
  ),
  (
    label: 'an ignore comment does not suppress (FR-009)',
    requirement: 'doc/specs/architecture-guardrails.md FR-009, FR-076',
    path: 'unhappy (rule interaction)',
    files: {
      _application:
          '// ignore: depend_on_referenced_packages\n'
          "import 'package:test/test.dart';\n",
    },
    expected: ['FR-076 $_application:2'],
  ),
];

final List<_Case> _fr095Cases = [
  (
    label: 'lib/adapters.dart reads the embedded data',
    requirement: _fr095,
    path: 'unhappy (rule interaction)',
    files: {
      'lib/adapters.dart': "import 'src/content/data/species_data.dart';\n",
      _data: '',
    },
    expected: ['FR-095 lib/adapters.dart:1'],
  ),
  (
    label: 'lib/srd5e.dart exports the embedded data',
    requirement: _fr095,
    path: 'unhappy (rule interaction)',
    files: {
      'lib/srd5e.dart': "\nexport 'src/content/data/species_data.dart';\n",
      _data: '',
    },
    expected: ['FR-095 lib/srd5e.dart:2'],
  ),
  (
    label: 'content/domain and content/application read the embedded data',
    requirement: _fr095,
    path: 'unhappy (rule interaction)',
    files: {
      _domain: "import '../data/species_data.dart';\n",
      _application: "import '../data/species_data.dart';\n",
      _data: '',
    },
    expected: ['FR-095 $_application:1', 'FR-095 $_domain:1'],
  ),
  (
    label: 'a package URI to the embedded data from the application layer',
    requirement: _fr095,
    path: 'unhappy (rule interaction)',
    files: {
      _application:
          "import 'package:srd5e/src/content/data/species_data.dart';\n",
      _data: '',
    },
    expected: ['FR-095 $_application:1'],
  ),
  (
    label: 'another context adapters and a shared adapter read the data',
    requirement: _fr095,
    path: 'unhappy (rule interaction)',
    files: {
      'lib/src/combat/adapters/x.dart':
          "import '../../content/data/species_data.dart';\n",
      'lib/src/shared_ports/adapters/y.dart':
          "import '../../content/data/species_data.dart';\n",
      _data: '',
    },
    expected: [
      'FR-095 lib/src/combat/adapters/x.dart:1',
      'FR-095 lib/src/shared_ports/adapters/y.dart:1',
    ],
  ),
  (
    label: 'a data library imports a domain file',
    requirement: _fr095,
    path: 'unhappy (invalid input)',
    files: {_data: "import '../domain/species.dart';\n", _domain: ''},
    expected: ['FR-095 $_data:1'],
  ),
  (
    label: 'a data library imports the package barrel and a sibling data file',
    requirement: _fr095,
    path: 'unhappy (invalid input)',
    files: {
      _data:
          "import 'package:srd5e/srd5e.dart';\n"
          "export 'spell_data.dart';\n",
      _dataOther: '',
      'lib/srd5e.dart': '',
    },
    expected: ['FR-095 $_data:1', 'FR-095 $_data:2'],
  ),
  (
    label: 'a data library in a subfolder imports a package file',
    requirement: _fr095,
    path: 'unhappy (boundary)',
    files: {
      'lib/src/content/data/spells/level_one.dart':
          "import '../../domain/species.dart';\n",
      _domain: '',
    },
    expected: ['FR-095 lib/src/content/data/spells/level_one.dart:1'],
  ),
  (
    label: 'a data library imports an unresolved package path',
    requirement: _fr095,
    path: 'unhappy (missing content)',
    files: {_data: "import '../domain/missing.dart';\n"},
    expected: ['FR-095 $_data:1'],
  ),
  (
    label: 'content/adapters reads the data, in a subfolder too',
    requirement: _fr095,
    path: 'happy',
    files: {
      _adapter: "import '../data/species_data.dart';\n",
      'lib/src/content/adapters/json/reader.dart':
          "import '../../data/spell_data.dart';\n"
          "export '../../data/species_data.dart';\n",
      _data: '',
      _dataOther: '',
    },
    expected: [],
  ),
  (
    label: 'tool/ and test/ import the data libraries',
    requirement: _fr095,
    path: 'happy',
    files: {
      'tool/generate.dart':
          "import '../lib/src/content/data/species_data.dart';\n",
      'test/content/data_test.dart':
          "import 'package:srd5e/src/content/data/species_data.dart';\n",
      _data: '',
    },
    expected: [],
  ),
  (
    label: 'a data library that imports only the SDK and meta',
    requirement: _fr095,
    path: 'happy',
    files: {
      _data:
          "import 'dart:convert';\n"
          "import 'package:meta/meta.dart';\n"
          "const String speciesJson = r'''{}''';\n",
    },
    expected: [],
  ),
  (
    label: 'an import of the data in a comment or a string',
    requirement: 'doc/specs/architecture-guardrails.md FR-008, FR-095',
    path: 'unhappy (false positive)',
    files: {
      'lib/adapters.dart':
          "// import 'src/content/data/species_data.dart';\n"
          "const s = \"import 'src/content/data/species_data.dart';\";\n",
      _data: "// import '../domain/species.dart';\n",
    },
    expected: [],
  ),
  (
    label: 'an ignore comment does not suppress (FR-009)',
    requirement: 'doc/specs/architecture-guardrails.md FR-009, FR-095',
    path: 'unhappy (rule interaction)',
    files: {
      'lib/adapters.dart':
          '// ignore: implementation_imports\n'
          "import 'src/content/data/species_data.dart';\n",
      _data: '',
    },
    expected: ['FR-095 lib/adapters.dart:2'],
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
  // Requirement: doc/specs/architecture-guardrails.md FR-076 - lib/ imports
  //   nothing outside lib/ and no dev-only package.
  // Path: per case
  _run('FR-076 lib stays in lib', _fr076Cases, checkLibImportsStayInLib);

  // Requirement: doc/specs/architecture-guardrails.md FR-095 - the embedded
  //   data imports nothing and only content/adapters reads it.
  // Path: per case
  _run('FR-095 embedded data', _fr095Cases, checkEmbeddedDataImports);

  /// Requirement: doc/specs/architecture-guardrails.md FR-076, FR-004 - the
  ///   detail says what was imported and why it is refused.
  /// Path: unhappy (invalid input)
  test('FR-076 details name the target and the reason', () {
    final found = checkLibImportsStayInLib(
      SourceSet({
        _adapter: "import '../../../../tool/generate.dart';\n",
        _application: "import 'package:test/test.dart';\n",
      }),
    );

    expect(found.map((v) => v.detail), [
      'import of "../../../../tool/generate.dart" resolves to '
          'tool/generate.dart, outside lib/',
      'import of "package:test/test.dart": `test` is a dev-only package and '
          'must not become a runtime dependency',
    ]);
  });

  /// Requirement: doc/specs/architecture-guardrails.md FR-095, FR-004 - the
  ///   detail names the data library and the one reader.
  /// Path: unhappy (rule interaction)
  test('FR-095 details name the data library and the allowed reader', () {
    final found = checkEmbeddedDataImports(
      SourceSet({
        'lib/adapters.dart': "import 'src/content/data/species_data.dart';\n",
        _data: "import '../domain/species.dart';\n",
      }),
    );

    expect(found.map((v) => v.detail), [
      'import of the embedded data library $_data; only files under '
          'lib/src/content/adapters/ read it (one decode path)',
      'importDirective of "../domain/species.dart": an embedded data library '
          'imports nothing in the package',
    ]);
  });

  /// Requirement: doc/specs/architecture-guardrails.md FR-058 - an empty
  ///   source set and a lib/ with no directive yield no Violation.
  /// Path: unhappy (empty and minimal)
  test('an empty source set is clean for both checks', () {
    expect(checkLibImportsStayInLib(SourceSet({})), isEmpty);
    expect(checkEmbeddedDataImports(SourceSet({})), isEmpty);
    expect(
      checkEmbeddedDataImports(SourceSet({'lib/srd5e.dart': 'library;\n'})),
      isEmpty,
    );
  });

  /// Requirement: doc/specs/architecture-guardrails.md FR-005 - each id has a
  ///   violating fixture on which its registered function yields that id.
  /// Path: unhappy (failure)
  group('registry wiring', () {
    for (final id in libBoundaryChecks.keys) {
      /// Requirement: doc/specs/architecture-guardrails.md FR-005 - the
      ///   fixture for the id yields a Violation with that id.
      /// Path: unhappy (failure)
      test('$id has a violating fixture', () {
        final fixture = libBoundaryViolatingFixtures[id];

        expect(fixture, isNotNull);
        final found = libBoundaryChecks[id]!(fixture!());
        expect(found.map((v) => v.checkId), contains(id));
      });
    }

    /// Requirement: doc/specs/architecture-guardrails.md FR-005 - fixtures and
    ///   functions cover the same ids.
    /// Path: unhappy (failure)
    test('fixtures and checks name the same ids', () {
      expect(
        libBoundaryViolatingFixtures.keys.toSet(),
        libBoundaryChecks.keys.toSet(),
      );
      expect(libBoundaryChecks.keys.toSet(), {'FR-076', 'FR-095'});
    });
  });
}
