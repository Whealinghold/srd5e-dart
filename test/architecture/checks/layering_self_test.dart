import 'package:test/test.dart';

import '../support/context_map.dart';
import '../support/source_set.dart';
import '../support/violation.dart';
import 'context_map.dart' show contextMapFixtureArchitecture;
import 'layering.dart';

const String _spec = 'doc/specs/architecture-guardrails.md';
const String _p = 'package:srd5e/src/';

/// The map of `architecture.md` section 2, as the fixtures spell it.
const Map<String, List<String>> _realShape = {
  'content': [],
  'd20_test': [],
  'character': ['content', 'd20_test'],
  'combat': ['character', 'd20_test', 'content'],
  'toolbox': ['content', 'd20_test', 'character', 'combat'],
};

typedef _Case = ({
  String label,
  String requirement,
  String path,
  String importer,
  List<String> imports,
  List<String> expected,
});

List<String> _where(List<Violation> violations) => [
  for (final v in violations) '${v.checkId} ${v.path}:${v.line}',
];

/// The file path of an importer written as in section 4.5: a folder under
/// `lib/src/`, a path under `lib/`, or one of the other roots.
String _fileOf(String importer) =>
    importer.startsWith('lib/') ||
        importer.startsWith('test/') ||
        importer.startsWith('tool/')
    ? importer
    : 'lib/src/$importer/x.dart';

/// A source set whose importer has one import per entry, from line 1. An
/// entry is a URI, or a full directive when it starts with `export`/`import`.
SourceSet _sources(
  String importer,
  List<String> imports, {
  Map<String, List<String>>? map = _realShape,
}) => SourceSet({
  if (map != null) architectureRulesPath: contextMapFixtureArchitecture(map),
  _fileOf(importer): [
    for (final i in imports)
      i.startsWith('export ') || i.startsWith('import ') || i.startsWith('//')
          ? i
          : "import '$i';",
  ].join('\n'),
});

_Case _case(
  String label,
  String requirement,
  String path,
  String importer,
  List<String> imports,
  List<String> expected,
) => (
  label: label,
  requirement: '$_spec $requirement',
  path: path,
  importer: importer,
  imports: imports,
  expected: expected,
);

/// The `FR-n file:line` strings for violations of [id] at [file]'s lines.
List<String> _at(String id, String importer, List<int> lines) => [
  for (final line in lines) '$id ${_fileOf(importer)}:$line',
];

final List<_Case> _cases = [
  // Rows of section 4.5 that are happy for these ids.
  _case(
    'domain to own domain, kernel',
    'FR-017, FR-018, FR-019',
    'happy',
    'd20_test/domain',
    ['${_p}d20_test/domain/y.dart', '${_p}shared_kernel/z.dart'],
    [],
  ),
  _case(
    'domain to upstream barrel',
    'FR-018, FR-019',
    'happy',
    'character/domain',
    ['${_p}d20_test/d20_test.dart'],
    [],
  ),
  _case(
    'application to upstream barrel, shared ports',
    'FR-018, FR-019',
    'happy',
    'character/application',
    ['${_p}content/content.dart', '${_p}shared_ports/x.dart'],
    [],
  ),
  _case('adapter to own ports', 'FR-017, FR-018', 'happy', 'content/adapters', [
    '${_p}content/application/ports/p.dart',
  ], []),
  _case('combat to every upstream', 'FR-019', 'happy', 'combat/application', [
    '${_p}character/character.dart',
    '${_p}d20_test/d20_test.dart',
    '${_p}content/content.dart',
  ], []),
  _case('toolbox to every upstream', 'FR-019', 'happy', 'toolbox/application', [
    '${_p}content/content.dart',
    '${_p}d20_test/d20_test.dart',
    '${_p}character/character.dart',
    '${_p}combat/combat.dart',
  ], []),
  _case(
    'use case uses a domain service barrel',
    'FR-019',
    'happy',
    'combat/application',
    ['${_p}d20_test/d20_test.dart'],
    [],
  ),
  _case(
    'shared ports to kernel; shared adapter to port and kernel',
    'FR-017, FR-018',
    'happy',
    'shared_ports/adapters',
    [
      '${_p}shared_kernel/k.dart',
      '${_p}shared_ports/dice_roller/dice_roller.dart',
    ],
    [],
  ),
  _case(
    'no-op default in application',
    'FR-017, FR-018',
    'happy',
    'd20_test/application',
    ['${_p}shared_ports/observability/noop_observability.dart'],
    [],
  ),
  _case(
    'dart:async in application',
    'FR-017',
    'happy',
    'd20_test/application',
    ['dart:async'],
    [],
  ),
  _case(
    'dart:io behind platform entry point',
    'FR-017',
    'happy',
    'content/adapters',
    ['dart:io'],
    [],
  ),
  _case(
    'adapter reads embedded data',
    'FR-017, FR-018',
    'happy',
    'content/adapters',
    ['${_p}content/data/lib.dart'],
    [],
  ),
  _case(
    'tool imports lib',
    'FR-017, FR-018, FR-061',
    'happy',
    'tool/generate.dart',
    ['${_p}content/content.dart'],
    [],
  ),
  _case(
    'adapters entry point to shared adapters',
    'FR-017',
    'happy',
    'lib/adapters.dart',
    ['${_p}shared_ports/adapters/seeded_dice_roller.dart'],
    [],
  ),
  _case(
    'double to port, barrels, another double',
    'FR-017, FR-018, FR-019',
    'happy',
    'testing',
    [
      '${_p}shared_ports/dice_roller/dice_roller.dart',
      '${_p}content/content.dart',
      '${_p}combat/combat.dart',
      '${_p}testing/y.dart',
    ],
    [],
  ),
  _case(
    'testing entry point to doubles',
    'FR-017, FR-061',
    'happy',
    'lib/testing.dart',
    ['${_p}testing/fixed_dice_roller.dart'],
    [],
  ),
  _case(
    'entry point reads embedded data',
    'FR-017, FR-018',
    'happy',
    'lib/adapters.dart',
    ['${_p}content/data/lib.dart'],
    [],
  ),
  _case(
    'a test file importing an adapters folder is outside FR-017',
    'FR-017',
    'unhappy (boundary)',
    'test/content/x_test.dart',
    ['${_p}content/adapters/a.dart'],
    [],
  ),
  _case(
    'a relative import of the upstream barrel',
    'FR-018, FR-019',
    'happy',
    'character/domain',
    ['../../content/content.dart'],
    [],
  ),
  _case(
    'kernel and ports are not contexts: FR-023 and FR-024 govern them',
    'FR-018, FR-019',
    'unhappy (boundary)',
    'shared_ports',
    ['${_p}content/content.dart'],
    [],
  ),
  _case(
    'shared kernel importing context internals is FR-023',
    'FR-018',
    'unhappy (boundary)',
    'shared_kernel',
    ['${_p}content/domain/s.dart'],
    [],
  ),
  _case(
    'a context importing the testing folder is FR-074',
    'FR-017, FR-018',
    'unhappy (boundary)',
    'combat/application',
    ['${_p}testing/y.dart'],
    [],
  ),
  _case(
    'a commented-out import is not an edge',
    'FR-018, FR-008',
    'unhappy (false positive)',
    'character/domain',
    ["// import 'package:srd5e/src/content/domain/a.dart';"],
    [],
  ),

  // Unhappy rows of section 4.5.
  _case(
    'domain to own adapters',
    'FR-017',
    'unhappy (invalid input)',
    'd20_test/domain',
    ['${_p}d20_test/adapters/a.dart'],
    _at('FR-017', 'd20_test/domain', [1]),
  ),
  _case(
    'application to own adapters',
    'FR-017',
    'unhappy (invalid input)',
    'content/application',
    ['${_p}content/adapters/a.dart'],
    _at('FR-017', 'content/application', [1]),
  ),
  _case(
    'port library imports its adapters',
    'FR-017',
    'unhappy (invalid input)',
    'shared_ports',
    ['${_p}shared_ports/adapters/seeded_dice_roller.dart'],
    _at('FR-017', 'shared_ports', [1]),
  ),
  _case(
    'double to adapters (context)',
    'FR-017',
    'unhappy (invalid input)',
    'testing',
    ['${_p}content/adapters/a.dart'],
    _at('FR-017', 'testing', [1]),
  ),
  _case(
    'double to adapters (shared_ports)',
    'FR-017',
    'unhappy (invalid input)',
    'testing',
    ['${_p}shared_ports/adapters/seeded_dice_roller.dart'],
    _at('FR-017', 'testing', [1]),
  ),
  _case(
    'lib file outside adapters/ importing lib/adapters/ via a relative path',
    'FR-017',
    'unhappy (invalid input)',
    'lib/src/content/domain/y.dart',
    ['../adapters/a.dart'],
    _at('FR-017', 'lib/src/content/domain/y.dart', [1]),
  ),
  _case(
    'an adapters-looking file name is not an adapters folder',
    'FR-017',
    'unhappy (false positive)',
    'content/application',
    ['${_p}content/application/adapters.dart'],
    [],
  ),
  _case(
    'domain to other internals',
    'FR-018',
    'unhappy (invalid input)',
    'character/domain',
    ['${_p}content/domain/species.dart'],
    _at('FR-018', 'character/domain', [1]),
  ),
  _case(
    'toolbox imports internals',
    'FR-018',
    'unhappy (invalid input)',
    'toolbox/domain',
    ['${_p}combat/domain/damage.dart'],
    _at('FR-018', 'toolbox/domain', [1]),
  ),
  _case(
    'adapter to other adapter',
    'FR-018',
    'unhappy (rule interaction)',
    'combat/adapters',
    ['${_p}character/adapters/a.dart'],
    _at('FR-018', 'combat/adapters', [1]),
  ),
  _case(
    'relative import of another context internals',
    'FR-018',
    'unhappy (invalid input)',
    'character/domain',
    ['../../content/domain/species.dart'],
    _at('FR-018', 'character/domain', [1]),
  ),
  _case(
    'export of another context internals',
    'FR-018',
    'unhappy (rule interaction)',
    'character/application',
    ["export 'package:srd5e/src/content/domain/s.dart';"],
    _at('FR-018', 'character/application', [1]),
  ),
  _case(
    'conditional configuration URI of another context internals',
    'FR-018',
    'unhappy (rule interaction)',
    'character/domain',
    [
      "import 'a.dart' if (dart.library.io) 'package:srd5e/src/content/domain/b.dart';",
    ],
    _at('FR-018', 'character/domain', [1]),
  ),
  _case(
    'another context data library',
    'FR-018',
    'unhappy (invalid input)',
    'character/application',
    ['${_p}content/data/lib.dart'],
    _at('FR-018', 'character/application', [1]),
  ),
  _case(
    'three violations are all reported, sorted by line',
    'FR-018, FR-019',
    'unhappy (multiple violations)',
    'character/domain',
    [
      '${_p}content/domain/a.dart',
      '${_p}content/content.dart',
      '${_p}combat/combat.dart',
      '${_p}d20_test/domain/b.dart',
    ],
    [
      ..._at('FR-018', 'character/domain', [1]),
      ..._at('FR-019', 'character/domain', [3]),
      ..._at('FR-018', 'character/domain', [4]),
    ],
  ),
  _case(
    'non-upstream barrel',
    'FR-019',
    'unhappy (rule interaction)',
    'character/domain',
    ['${_p}combat/combat.dart'],
    _at('FR-019', 'character/domain', [1]),
  ),
  _case(
    'upstream context imports downstream',
    'FR-019',
    'unhappy (rule interaction)',
    'd20_test/application',
    ['${_p}character/character.dart'],
    _at('FR-019', 'd20_test/application', [1]),
  ),
  _case(
    'root context has no upstream',
    'FR-019',
    'unhappy (rule interaction)',
    'content/application',
    ['${_p}d20_test/d20_test.dart'],
    _at('FR-019', 'content/application', [1]),
  ),
  _case(
    'downstream of toolbox',
    'FR-019',
    'unhappy (rule interaction)',
    'combat/application',
    ['${_p}toolbox/toolbox.dart'],
    _at('FR-019', 'combat/application', [1]),
  ),
  _case(
    'relative import of a non-upstream barrel',
    'FR-019',
    'unhappy (rule interaction)',
    'character/domain',
    ['../../combat/combat.dart'],
    _at('FR-019', 'character/domain', [1]),
  ),
  _case(
    'a context with no row has no upstream',
    'FR-019',
    'unhappy (missing content)',
    'ghost/domain',
    ['${_p}content/content.dart'],
    _at('FR-019', 'ghost/domain', [1]),
  ),
  _case(
    'kernel to entry point',
    'FR-061',
    'unhappy (invalid input)',
    'shared_kernel',
    ['package:srd5e/srd5e.dart'],
    _at('FR-061', 'shared_kernel', [1]),
  ),
  _case(
    'domain to aggregate entry point',
    'FR-061',
    'unhappy (rule interaction)',
    'd20_test/domain',
    ['package:srd5e/srd5e.dart'],
    _at('FR-061', 'd20_test/domain', [1]),
  ),
  _case(
    'application to adapters entry point',
    'FR-061',
    'unhappy (rule interaction)',
    'content/application',
    ['package:srd5e/adapters.dart'],
    _at('FR-061', 'content/application', [1]),
  ),
  _case(
    'double to testing entry point',
    'FR-061',
    'unhappy (rule interaction)',
    'testing',
    ['package:srd5e/testing.dart'],
    _at('FR-061', 'testing', [1]),
  ),
  _case(
    'relative path to an entry point',
    'FR-061',
    'unhappy (rule interaction)',
    'character/domain',
    ['../../../srd5e.dart'],
    _at('FR-061', 'character/domain', [1]),
  ),
  _case(
    'export of an entry point',
    'FR-061',
    'unhappy (rule interaction)',
    'content/application',
    ["export 'package:srd5e/srd5e.dart';"],
    _at('FR-061', 'content/application', [1]),
  ),
  _case(
    'a file directly in lib/src/ importing an entry point',
    'FR-061',
    'unhappy (boundary)',
    'lib/src/loose.dart',
    ['package:srd5e/srd5e.dart'],
    _at('FR-061', 'lib/src/loose.dart', [1]),
  ),
  _case(
    'the entry points may import each other',
    'FR-061',
    'happy',
    'lib/srd5e.dart',
    ['package:srd5e/adapters.dart'],
    [],
  ),
  _case(
    'own barrel',
    'FR-080',
    'unhappy (rule interaction)',
    'character/domain',
    ['${_p}character/character.dart'],
    _at('FR-080', 'character/domain', [1]),
  ),
  _case(
    'own barrel by a relative path',
    'FR-080',
    'unhappy (rule interaction)',
    'character/domain',
    ['../character.dart'],
    _at('FR-080', 'character/domain', [1]),
  ),
  _case(
    'export of the own barrel',
    'FR-080',
    'unhappy (rule interaction)',
    'character/application',
    ["export 'package:srd5e/src/character/character.dart';"],
    _at('FR-080', 'character/application', [1]),
  ),
  _case(
    'a file importing a sibling file of the barrel folder',
    'FR-080',
    'happy',
    'character/domain',
    ['${_p}character/domain/y.dart'],
    [],
  ),
  _case(
    'an ignore comment does not suppress the Violation',
    'FR-080, FR-009',
    'unhappy (rule interaction)',
    'character/domain',
    ['// ignore: unused_import', '${_p}character/character.dart'],
    _at('FR-080', 'character/domain', [2]),
  ),
];

void main() {
  /// Requirement: per case
  /// Path: per case
  group('FR-017, FR-018, FR-019, FR-061, FR-080 import legality', () {
    for (final c in _cases) {
      test('${c.label} [${c.path}] (${c.requirement})', () {
        final sources = _sources(c.importer, c.imports);

        expect(_where(checkLayering(sources)), c.expected);
      });
    }
  });

  /// Requirement: doc/specs/architecture-guardrails.md FR-019, FR-022 - with
  ///   no readable context map FR-019 reports nothing (FR-022 reports the
  ///   missing table), while FR-018 still applies.
  /// Path: unhappy (state error)
  test('without a context map FR-019 is silent and FR-018 still fires', () {
    final sources = _sources('character/domain', [
      '${_p}combat/combat.dart',
      '${_p}content/domain/a.dart',
    ], map: null);

    expect(_where(checkLayering(sources)), [
      'FR-018 lib/src/character/domain/x.dart:2',
    ]);
  });

  /// Requirement: doc/specs/architecture-guardrails.md FR-018, FR-019 - one
  ///   edge to a non-upstream context's internals is an FR-018 Violation only.
  /// Path: unhappy (rule interaction)
  test('internals of a non-upstream context are FR-018 only', () {
    final sources = _sources('content/application', [
      '${_p}combat/domain/damage.dart',
    ]);

    expect(_where(checkLayering(sources)), [
      'FR-018 lib/src/content/application/x.dart:1',
    ]);
  });

  /// Requirement: doc/specs/architecture-guardrails.md FR-004 - every
  ///   violation is reported, across files, sorted by path and line.
  /// Path: unhappy (multiple violations)
  test('violations from several files are all reported, sorted', () {
    final sources = SourceSet({
      architectureRulesPath: contextMapFixtureArchitecture(_realShape),
      'lib/src/d20_test/domain/b.dart':
          "import '${_p}d20_test/adapters/a.dart';\n",
      'lib/src/character/domain/a.dart':
          "import '${_p}character/character.dart';\n",
      'lib/src/combat/application/c.dart':
          "import 'package:srd5e/srd5e.dart';\n",
    });

    expect(_where(checkLayering(sources)), [
      'FR-080 lib/src/character/domain/a.dart:1',
      'FR-061 lib/src/combat/application/c.dart:1',
      'FR-017 lib/src/d20_test/domain/b.dart:1',
    ]);
  });

  /// Requirement: doc/specs/architecture-guardrails.md FR-011 - the output
  ///   does not depend on the order of the files in the SourceSet.
  /// Path: unhappy (determinism)
  test('the same files in another order give the same violations', () {
    final files = {
      architectureRulesPath: contextMapFixtureArchitecture(_realShape),
      'lib/src/b/domain/y.dart': "import '${_p}a/adapters/z.dart';\n",
      'lib/src/a/domain/x.dart': "import 'package:srd5e/srd5e.dart';\n",
    };

    final forward = checkLayering(SourceSet(files));
    final reversed = checkLayering(
      SourceSet({for (final k in files.keys.toList().reversed) k: files[k]!}),
    );

    expect(reversed, forward);
    expect(forward, hasLength(greaterThan(1)));
  });

  /// Requirement: doc/specs/architecture-guardrails.md FR-058 - a source set
  ///   with no .dart file under lib/src/ yields no Violation.
  /// Path: happy
  test('a source set with no context code is clean', () {
    expect(
      checkLayering(
        SourceSet({
          'lib/srd5e.dart': '',
          'pubspec.yaml': '',
          architectureRulesPath: contextMapFixtureArchitecture(_realShape),
        }),
      ),
      isEmpty,
    );
  });

  /// Requirement: doc/specs/architecture-guardrails.md FR-005 - each id has a
  ///   violating fixture on which its registered function yields that id.
  /// Path: unhappy (failure)
  group('registry wiring', () {
    for (final id in layeringChecks.keys) {
      /// Requirement: doc/specs/architecture-guardrails.md FR-005 - the
      ///   fixture for the id yields a Violation with that id.
      /// Path: unhappy (failure)
      test('$id has a violating fixture', () {
        final fixture = layeringViolatingFixtures[id];

        expect(fixture, isNotNull);
        final found = layeringChecks[id]!(fixture!());
        expect(found.map((v) => v.checkId), contains(id));
      });
    }

    /// Requirement: doc/specs/architecture-guardrails.md FR-005 - fixtures and
    ///   functions cover the same ids.
    /// Path: unhappy (failure)
    test('fixtures and checks name the same ids', () {
      expect(
        layeringViolatingFixtures.keys.toSet(),
        layeringChecks.keys.toSet(),
      );
      expect(layeringChecks.keys.toSet(), {
        'FR-017',
        'FR-018',
        'FR-019',
        'FR-061',
        'FR-080',
      });
    });
  });
}
