import 'package:test/test.dart';

import '../support/source_set.dart';
import 'context_map.dart' show contextMapFixtureArchitecture;
import 'platform_imports.dart';
import 'registry.dart';

const String _p = 'package:srd5e/src/';

/// The ids the section 4.5 table speaks about.
const List<String> _ids = [
  'FR-013',
  'FR-014',
  'FR-015',
  'FR-016',
  'FR-017',
  'FR-018',
  'FR-019',
  'FR-023',
  'FR-024',
  'FR-061',
  'FR-062',
  'FR-067',
  'FR-074',
  'FR-075',
  'FR-076',
  'FR-080',
  'FR-095',
  'FR-097',
];

/// The platform entry points of the section 4.5 fixtures: the example the
/// guardrails spec uses for a `dart:io` entry point.
const Set<String> _platformEntries = {'lib/io.dart'};

/// The map of `architecture.md` section 2, as the fixtures spell it.
const Map<String, List<String>> _contextMap = {
  'content': [],
  'd20_test': [],
  'character': ['content', 'd20_test'],
  'combat': ['character', 'd20_test', 'content'],
  'toolbox': ['content', 'd20_test', 'character', 'combat'],
};

/// One importer/imports pair of a row, with the files the fixture needs
/// besides the importer itself.
typedef _Pair = ({
  String file,
  List<String> directives,
  Map<String, String> extra,
});

typedef _Row = ({
  String label,
  String path,
  List<_Pair> pairs,
  Set<String> expected,
});

/// The file path of an importer written as in section 4.5: a folder under
/// `lib/src/`, or a path under `lib/`, `tool/` or `test/`.
String _fileOf(String importer) =>
    importer.startsWith('lib/') ||
        importer.startsWith('tool/') ||
        importer.startsWith('test/')
    ? importer
    : 'lib/src/$importer/x.dart';

/// A directive for [import]: a full directive is kept as written, a bare URI
/// becomes `import '<uri>';`.
String _directive(String import) =>
    import.contains(' ') ? import : "import '$import';";

_Pair _pair(
  String importer,
  List<String> imports, {
  Map<String, String> extra = const {},
}) => (
  file: _fileOf(importer),
  directives: [for (final i in imports) _directive(i)],
  extra: extra,
);

_Row _row(
  String label,
  String path,
  List<_Pair> pairs, [
  Set<String> expected = const {},
]) => (label: label, path: path, pairs: pairs, expected: expected);

SourceSet _sources(_Pair pair) => SourceSet({
  'doc/rules/architecture.md': contextMapFixtureArchitecture(_contextMap),
  ...pair.extra,
  pair.file: pair.directives.join('\n'),
});

/// The ids of the section 4.5 checks that fire on [sources]. FR-067 runs with
/// the fixtures' platform entry point, as the registry default is empty.
Set<String> _fired(SourceSet sources) => {
  for (final id in _ids)
    for (final v
        in id == 'FR-067'
            ? checkDartIoAdaptersReachableFromPlatform(
                sources,
                platformEntries: _platformEntries,
              )
            : registry[id]!(sources))
      // FR-017 exempts the platform entry points of `platformEntryPoints`
      // (empty today), which cannot be injected, so the fixtures' stand-in
      // `lib/io.dart` is exempted here.
      if (!(v.checkId == 'FR-017' && _platformEntries.contains(v.path)))
        v.checkId,
};

const String _useCase = 'class ResolveD20Test {\n  void call() {}\n}\n';

final List<_Row> _rows = [
  _row('domain to own domain, kernel', 'happy', [
    _pair('d20_test/domain', [
      '${_p}d20_test/domain/y.dart',
      '${_p}shared_kernel/z.dart',
    ]),
  ]),
  _row('domain to upstream barrel', 'happy', [
    _pair('character/domain', ['${_p}d20_test/d20_test.dart']),
  ]),
  _row('application to upstream barrel, shared ports', 'happy', [
    _pair('character/application', ['${_p}content/content.dart']),
    _pair('d20_test/application', ['${_p}shared_ports/x.dart']),
  ]),
  _row('adapter to own ports', 'happy', [
    _pair('content/adapters', ['${_p}content/application/ports/p.dart']),
  ]),
  _row('combat to every upstream', 'happy', [
    _pair('combat/application', [
      '${_p}character/character.dart',
      '${_p}d20_test/d20_test.dart',
      '${_p}content/content.dart',
    ]),
  ]),
  _row('toolbox to every upstream', 'happy', [
    _pair('toolbox/application', [
      '${_p}content/content.dart',
      '${_p}d20_test/d20_test.dart',
      '${_p}character/character.dart',
      '${_p}combat/combat.dart',
    ]),
  ]),
  _row('use case uses a domain service', 'happy', [
    _pair(
      'combat/application',
      ['${_p}d20_test/d20_test.dart', 'final _x = D20TestResolver;'],
      extra: {
        'lib/src/d20_test/domain/d20_test_resolver.dart':
            'class D20TestResolver {\n  void call() {}\n}\n',
      },
    ),
  ]),
  _row('shared ports to kernel; shared adapter to port and kernel', 'happy', [
    _pair('shared_ports', ['${_p}shared_kernel/z.dart']),
    _pair('shared_ports/adapters', [
      '${_p}shared_ports/port.dart',
      '${_p}shared_kernel/z.dart',
    ]),
  ]),
  _row('no-op default in application', 'happy', [
    _pair('d20_test/application', ['${_p}shared_ports/noop_logger.dart']),
  ]),
  _row('dart:async in application', 'happy', [
    _pair('d20_test/application', ['dart:async']),
  ]),
  _row('dart:io behind platform entry point', 'happy', [
    _pair(
      'content/adapters',
      ['dart:io'],
      extra: {'lib/io.dart': "export 'src/content/adapters/x.dart';\n"},
    ),
  ]),
  _row('adapter reads embedded data; tool imports lib', 'happy', [
    _pair('content/adapters', ['${_p}content/data/x.dart']),
    _pair('tool/generate.dart', ['${_p}content/content.dart']),
  ]),
  _row('adapters entry point to shared adapters', 'happy', [
    _pair('lib/adapters.dart', ['${_p}shared_ports/adapters/x.dart']),
  ]),
  _row('double to port, barrels, another double', 'happy', [
    _pair('testing', [
      '${_p}shared_ports/port.dart',
      '${_p}content/content.dart',
      '${_p}combat/combat.dart',
      '${_p}testing/y.dart',
    ]),
  ]),
  _row('testing entry point to doubles', 'happy', [
    _pair('lib/testing.dart', ['${_p}testing/x.dart']),
  ]),
  _row(
    'domain to shared ports',
    'unhappy (invalid input)',
    [
      _pair('d20_test/domain', ['${_p}shared_ports/x.dart']),
    ],
    {'FR-015'},
  ),
  _row(
    'domain to own application',
    'unhappy (invalid input)',
    [
      _pair('d20_test/domain', ['${_p}d20_test/application/x.dart']),
    ],
    {'FR-015'},
  ),
  _row(
    'domain to own adapters',
    'unhappy (invalid input)',
    [
      _pair('d20_test/domain', ['${_p}d20_test/adapters/x.dart']),
    ],
    {'FR-015', 'FR-017'},
  ),
  _row(
    'dart:async in domain',
    'unhappy (invalid input)',
    [
      _pair('d20_test/domain', ['dart:async']),
    ],
    {'FR-015'},
  ),
  _row(
    'application to own adapters',
    'unhappy (invalid input)',
    [
      _pair('content/application', ['${_p}content/adapters/x.dart']),
    ],
    {'FR-017'},
  ),
  _row(
    'port library imports its adapters',
    'unhappy (invalid input)',
    [
      _pair('shared_ports', ['${_p}shared_ports/adapters/x.dart']),
    ],
    {'FR-017'},
  ),
  _row(
    'domain to other internals',
    'unhappy (invalid input)',
    [
      _pair('character/domain', ['${_p}content/domain/species.dart']),
    ],
    {'FR-018'},
  ),
  _row(
    'toolbox imports internals',
    'unhappy (invalid input)',
    [
      _pair('toolbox/domain', ['${_p}combat/domain/damage.dart']),
    ],
    {'FR-018'},
  ),
  _row(
    'adapter to other adapter',
    'unhappy (rule interaction)',
    [
      _pair('combat/adapters', ['${_p}character/adapters/x.dart']),
    ],
    {'FR-018'},
  ),
  _row(
    'non-upstream barrel',
    'unhappy (rule interaction)',
    [
      _pair('character/domain', ['${_p}combat/combat.dart']),
    ],
    {'FR-019'},
  ),
  _row(
    'upstream context imports downstream',
    'unhappy (rule interaction)',
    [
      _pair('d20_test/application', ['${_p}character/character.dart']),
    ],
    {'FR-019'},
  ),
  _row(
    'root context has no upstream',
    'unhappy (rule interaction)',
    [
      _pair('content/application', ['${_p}d20_test/d20_test.dart']),
    ],
    {'FR-019'},
  ),
  _row(
    'downstream of toolbox',
    'unhappy (rule interaction)',
    [
      _pair('combat/application', ['${_p}toolbox/toolbox.dart']),
    ],
    {'FR-019'},
  ),
  _row(
    'use case calls a use case',
    'unhappy (rule interaction)',
    [
      _pair(
        'toolbox/application',
        ['${_p}d20_test/d20_test.dart', 'final _x = ResolveD20Test;'],
        extra: {'lib/src/d20_test/application/resolve_d20_test.dart': _useCase},
      ),
    ],
    {'FR-097'},
  ),
  _row(
    'kernel to ports',
    'unhappy (invalid input)',
    [
      _pair('shared_kernel', ['${_p}shared_ports/x.dart']),
    ],
    {'FR-023'},
  ),
  _row(
    'kernel to entry point',
    'unhappy (invalid input)',
    [
      _pair('shared_kernel', ['package:srd5e/srd5e.dart']),
    ],
    {'FR-023', 'FR-061'},
  ),
  _row(
    'ports or shared adapter to a context',
    'unhappy (invalid input)',
    [
      _pair('shared_ports', ['${_p}content/content.dart']),
      _pair('shared_ports/adapters', ['${_p}content/content.dart']),
    ],
    {'FR-024'},
  ),
  _row(
    'dart:io in core adapter',
    'unhappy (boundary)',
    [
      _pair(
        'content/adapters',
        ['dart:io'],
        extra: {
          'lib/adapters.dart': "export 'src/content/adapters/x.dart';\n",
          'lib/io.dart': "export 'src/content/adapters/x.dart';\n",
        },
      ),
    ],
    {'FR-014'},
  ),
  _row(
    'dart:io in unreachable adapter',
    'unhappy (rule interaction)',
    [
      _pair('content/adapters', ['dart:io']),
    ],
    {'FR-067'},
  ),
  _row(
    'conditional import',
    'unhappy (rule interaction)',
    [
      _pair('d20_test/domain', [
        "import 'a.dart' if (dart.library.io) 'dart:io';",
      ]),
    ],
    {'FR-013'},
  ),
  _row(
    'dart:io, flutter, dart:ui in domain',
    'unhappy (invalid input)',
    [
      _pair('d20_test/domain', [
        'dart:io',
        'package:flutter/foundation.dart',
        'dart:ui',
      ]),
    ],
    {'FR-013'},
  ),
  _row(
    'flutter test package, dart:ui',
    'unhappy (invalid input)',
    [
      _pair('content/application', [
        'package:flutter_test/flutter_test.dart',
        'dart:ui',
      ]),
    ],
    {'FR-013'},
  ),
  _row(
    'domain or application to aggregate entry point',
    'unhappy (rule interaction)',
    [
      _pair('d20_test/domain', ['package:srd5e/srd5e.dart']),
      _pair('content/application', ['package:srd5e/adapters.dart']),
    ],
    {'FR-061'},
  ),
  _row(
    'core entry point to dart:io',
    'unhappy (invalid input)',
    [
      _pair('lib/adapters.dart', ['dart:io']),
    ],
    {'FR-062'},
  ),
  _row(
    'double to context internals',
    'unhappy (invalid input)',
    [
      _pair('testing', ['${_p}content/domain/species.dart']),
    ],
    {'FR-075'},
  ),
  _row(
    'double to adapters',
    'unhappy (invalid input)',
    [
      _pair('testing', [
        '${_p}content/adapters/x.dart',
        '${_p}shared_ports/adapters/x.dart',
      ]),
    ],
    {'FR-075', 'FR-017'},
  ),
  _row(
    'double to entry point',
    'unhappy (rule interaction)',
    [
      _pair('testing', ['package:srd5e/srd5e.dart']),
    ],
    {'FR-075', 'FR-061'},
  ),
  _row(
    'context or entry point imports a double',
    'unhappy (rule interaction)',
    [
      _pair('combat/application', ['${_p}testing/x.dart']),
      _pair('lib/srd5e.dart', ['${_p}testing/x.dart']),
    ],
    {'FR-074'},
  ),
  _row(
    'lib imports tool, contract suite, test package',
    'unhappy (invalid input)',
    [
      _pair(
        'content/adapters',
        ['../../../../tool/generate.dart'],
        extra: {'tool/generate.dart': ''},
      ),
      _pair(
        'content/adapters',
        ['../../../../test/contract/x_contract.dart'],
        extra: {'test/contract/x_contract.dart': ''},
      ),
      _pair('content/application', ['package:test/test.dart']),
    ],
    {'FR-076'},
  ),
  _row(
    'entry point reads embedded data',
    'unhappy (rule interaction)',
    [
      _pair('lib/adapters.dart', ['${_p}content/data/x.dart']),
    ],
    {'FR-095'},
  ),
  _row(
    'domain or application reads embedded data',
    'unhappy (rule interaction)',
    [
      _pair('content/domain', ['${_p}content/data/x.dart']),
      _pair('content/application', ['${_p}content/data/x.dart']),
    ],
    {'FR-095'},
  ),
  _row(
    'data library imports',
    'unhappy (invalid input)',
    [
      _pair('content/data', ['${_p}content/domain/y.dart']),
    ],
    {'FR-095'},
  ),
  _row(
    'own barrel',
    'unhappy (rule interaction)',
    [
      _pair('character/domain', ['${_p}character/character.dart']),
    ],
    {'FR-080'},
  ),
];

void main() {
  /// Requirement: per case - doc/specs/architecture-guardrails.md FR-013, FR-014, FR-015, FR-016, FR-017, FR-018, FR-019, FR-023, FR-024, FR-061, FR-062, FR-067, FR-074, FR-075, FR-076, FR-080, FR-095, FR-097
  /// Path: per case
  group('section 4.5 import legality rows', () {
    for (final row in _rows) {
      test('${row.label} [${row.path}]', () {
        for (final pair in row.pairs) {
          expect(
            _fired(_sources(pair)),
            row.expected,
            reason: '${pair.file}: ${pair.directives.join(' | ')}',
          );
        }
      });
    }
  });

  /// Requirement: doc/specs/architecture-guardrails.md FR-005 - the table is
  ///   not vacuous: it has happy and unhappy rows, and each id of the table
  ///   is expected by at least one row.
  /// Path: unhappy (empty case)
  test('the rows cover every id of the table', () {
    final covered = {for (final row in _rows) ...row.expected};

    expect(_rows.where((r) => r.path == 'happy'), isNotEmpty);
    expect(
      covered,
      containsAll(_ids.where((id) => id != 'FR-016' && id != 'FR-077')),
    );
  });

  /// Requirement: doc/specs/architecture-guardrails.md FR-016 - FR-016 has no
  ///   row in section 4.5; the token case is covered by its own self-test.
  /// Path: unhappy (invalid input)
  test('a Future token in a domain file is reported as FR-016', () {
    final sources = SourceSet({
      'lib/src/d20_test/domain/x.dart': 'Future<int>? f;\n',
    });

    expect(_fired(sources), {'FR-016'});
  });
}
