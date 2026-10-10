import 'package:test/test.dart';

import '../support/source_set.dart';
import '../support/violation.dart';
import 'platform_imports.dart';

typedef _Check = List<Violation> Function(SourceSet, Set<String>);

typedef _Case = ({
  String label,
  String requirement,
  String path,
  Map<String, String> files,
  List<String> expected,
  Set<String> platform,
});

const String _fr013 = 'doc/specs/architecture-guardrails.md FR-013';
const String _fr062 = 'doc/specs/architecture-guardrails.md FR-062';
const String _fr014 = 'doc/specs/architecture-guardrails.md FR-014';
const String _fr067 = 'doc/specs/architecture-guardrails.md FR-067';

const String _domain = 'lib/src/d20_test/domain/x.dart';
const String _application = 'lib/src/content/application/x.dart';
const String _adapter = 'lib/src/content/adapters/a.dart';
const String _sharedAdapter = 'lib/src/shared_ports/adapters/b.dart';
const String _io = "import 'dart:io';\n";

List<String> _where(List<Violation> violations) => [
  for (final v in violations) '${v.checkId} ${v.path}:${v.line}',
];

_Case _case(
  String label,
  String requirement,
  String path,
  Map<String, String> files,
  List<String> expected, {
  Set<String> platform = const {},
}) => (
  label: label,
  requirement: requirement,
  path: path,
  files: files,
  expected: expected,
  platform: platform,
);

final List<_Case> _fr013Cases = [
  _case(
    'dart:io in domain',
    _fr013,
    'unhappy (invalid input)',
    {_domain: _io},
    ['FR-013 $_domain:1'],
  ),
  _case(
    'dart:io and flutter in domain',
    _fr013,
    'unhappy (invalid input)',
    {_domain: "import 'dart:io';\nimport 'package:flutter/foundation.dart';\n"},
    ['FR-013 $_domain:1', 'FR-013 $_domain:2'],
  ),
  _case(
    'flutter_test and dart:ui in application',
    _fr013,
    'unhappy (invalid input)',
    {
      _application:
          "import 'package:flutter_test/flutter_test.dart';\n"
          "import 'dart:ui';\n",
    },
    ['FR-013 $_application:1', 'FR-013 $_application:2'],
  ),
  _case(
    'conditional import of dart:io',
    _fr013,
    'unhappy (rule interaction)',
    {
      _domain: "import 'a.dart'\n    if (dart.library.io) 'dart:io';\n",
      'lib/src/d20_test/domain/a.dart': '',
    },
    ['FR-013 $_domain:2'],
  ),
  _case(
    'an export of dart:io',
    _fr013,
    'unhappy (invalid input)',
    {_domain: "export 'dart:io';\n"},
    ['FR-013 $_domain:1'],
  ),
  _case(
    'an ignore comment changes nothing (FR-009)',
    _fr013,
    'unhappy (rule interaction)',
    {_domain: '// ignore: depend_on_referenced_packages\n$_io'},
    ['FR-013 $_domain:2'],
  ),
  _case('dart:io in an adapters folder', _fr013, 'happy', {
    _adapter: _io,
    _sharedAdapter: _io,
  }, []),
  _case('dart:async, meta and a lookalike package', _fr013, 'happy', {
    _domain:
        "import 'dart:async';\nimport 'package:meta/meta.dart';\n"
        "import 'package:flutterish/x.dart';\n",
  }, []),
  _case('dart:io in a comment, a string and a doc comment', _fr013, 'happy', {
    _domain: "// import 'dart:io';\nconst s = \"import 'dart:ui';\";\n",
  }, []),
  _case('dart:io outside lib/src/ is not this check', _fr013, 'happy', {
    'lib/adapters.dart': _io,
    'tool/x.dart': _io,
    'test/x_test.dart': "import 'dart:ui';\n",
  }, []),
];

final List<_Case> _fr062Cases = [
  for (final entry in coreEntryPoints)
    _case(
      'dart:io in $entry',
      _fr062,
      'unhappy (invalid input)',
      {entry: _io},
      ['FR-062 $entry:1'],
    ),
  _case(
    'dart:ui and flutter_test in lib/srd5e.dart',
    _fr062,
    'unhappy (invalid input)',
    {
      'lib/srd5e.dart':
          "import 'dart:ui';\nimport 'package:flutter_test/flutter_test.dart';\n"
          "export 'package:flutter/widgets.dart';\n",
    },
    [
      'FR-062 lib/srd5e.dart:1',
      'FR-062 lib/srd5e.dart:2',
      'FR-062 lib/srd5e.dart:3',
    ],
  ),
  _case(
    'a conditional dart:io in lib/adapters.dart',
    _fr062,
    'unhappy (rule interaction)',
    {
      'lib/adapters.dart':
          "export 'a.dart'\n    if (dart.library.io) 'dart:io';\n",
      'lib/a.dart': '',
    },
    ['FR-062 lib/adapters.dart:2'],
  ),
  _case('plain exports and dart:async', _fr062, 'happy', {
    'lib/srd5e.dart': "import 'dart:async';\nexport 'src/a.dart';\n",
    'lib/adapters.dart': "export 'src/a.dart';\n",
    'lib/testing.dart': "export 'src/a.dart';\n",
    'lib/src/a.dart': '',
  }, []),
  _case(
    'dart:io in a platform entry point is not this check',
    _fr062,
    'happy',
    {'lib/io.dart': _io},
    [],
    platform: {'lib/io.dart'},
  ),
  _case('dart:io in a comment', _fr062, 'happy', {
    'lib/adapters.dart': "// import 'dart:io';\n",
  }, []),
];

final List<_Case> _fr014Cases = [
  _case(
    'adapter reachable from lib/adapters.dart and lib/io.dart',
    _fr014,
    'unhappy (boundary)',
    {
      'lib/adapters.dart': "export 'src/content/adapters/a.dart';\n",
      'lib/io.dart': "export 'src/content/adapters/a.dart';\n",
      _adapter: _io,
    },
    ['FR-014 $_adapter:1'],
    platform: {'lib/io.dart'},
  ),
  _case(
    'adapter two files deep from lib/srd5e.dart',
    _fr014,
    'unhappy (rule interaction)',
    {
      'lib/srd5e.dart': "export 'src/content/content.dart';\n",
      'lib/src/content/content.dart': "export 'adapters/a.dart';\n",
      _adapter: "\n$_io",
    },
    ['FR-014 $_adapter:2'],
  ),
  _case(
    'adapter reached from lib/testing.dart by a conditional import',
    _fr014,
    'unhappy (rule interaction)',
    {
      'lib/testing.dart':
          "export 'src/testing/t.dart'\n"
          "    if (dart.library.io) 'src/content/adapters/a.dart';\n",
      'lib/src/testing/t.dart': '',
      _adapter: _io,
    },
    ['FR-014 $_adapter:1'],
  ),
  _case(
    'a cycle in the graph still terminates',
    _fr014,
    'unhappy (boundary)',
    {
      'lib/srd5e.dart': "export 'src/content/adapters/b.dart';\n",
      'lib/src/content/adapters/b.dart': "export 'a.dart';\n",
      _adapter: "export 'b.dart';\n$_io",
    },
    ['FR-014 $_adapter:2'],
  ),
  _case(
    'adapter reached only from lib/io.dart',
    _fr014,
    'happy',
    {
      'lib/adapters.dart': "export 'src/shared_ports/adapters/b.dart';\n",
      'lib/io.dart': "export 'src/content/adapters/a.dart';\n",
      _adapter: _io,
      _sharedAdapter: '',
    },
    [],
    platform: {'lib/io.dart'},
  ),
  _case('a reachable adapter without dart:io', _fr014, 'happy', {
    'lib/adapters.dart': "export 'src/content/adapters/a.dart';\n",
    _adapter: "import 'dart:async';\n",
  }, []),
  _case('a commented-out export is no edge', _fr014, 'happy', {
    'lib/adapters.dart': "// export 'src/content/adapters/a.dart';\n",
    _adapter: _io,
  }, []),
  _case(
    'dart:io outside an adapters folder is FR-013, not this',
    _fr014,
    'happy',
    {'lib/srd5e.dart': "export 'src/d20_test/domain/x.dart';\n", _domain: _io},
    [],
  ),
];

final List<_Case> _fr067Cases = [
  _case(
    'adapter reached from no entry point',
    _fr067,
    'unhappy (rule interaction)',
    {_adapter: _io},
    ['FR-067 $_adapter:1'],
  ),
  _case(
    'adapter reached only from a core entry point',
    _fr067,
    'unhappy (rule interaction)',
    {
      'lib/adapters.dart': "export 'src/content/adapters/a.dart';\n",
      _adapter: "\n\n$_io",
    },
    ['FR-067 $_adapter:3'],
  ),
  _case(
    'adapter reached from a file that is not a platform entry point',
    _fr067,
    'unhappy (boundary)',
    {
      'lib/other.dart': "export 'src/content/adapters/a.dart';\n",
      _adapter: _io,
    },
    ['FR-067 $_adapter:1'],
    platform: {'lib/io.dart'},
  ),
  _case(
    'two unreachable adapters, both reported',
    _fr067,
    'unhappy (multiple violations)',
    {_adapter: _io, _sharedAdapter: _io},
    ['FR-067 $_adapter:1', 'FR-067 $_sharedAdapter:1'],
  ),
  _case(
    'adapter reached only from lib/io.dart',
    _fr067,
    'happy',
    {'lib/io.dart': "export 'src/content/adapters/a.dart';\n", _adapter: _io},
    [],
    platform: {'lib/io.dart'},
  ),
  _case(
    'adapter reached from lib/io.dart through a barrel',
    _fr067,
    'happy',
    {
      'lib/io.dart': "export 'src/content/content.dart';\n",
      'lib/src/content/content.dart': "export 'adapters/a.dart';\n",
      _adapter: _io,
    },
    [],
    platform: {'lib/io.dart'},
  ),
  _case('an unreachable adapter without dart:io', _fr067, 'happy', {
    _adapter: "import 'dart:async';\n",
  }, []),
  _case(
    'dart:io outside an adapters folder is FR-013, not this',
    _fr067,
    'happy',
    {_domain: _io},
    [],
  ),
];

/// Runs [cases] against [check], one test per case.
void _run(String title, List<_Case> cases, _Check check) {
  /// Requirement: per case
  /// Path: per case
  group(title, () {
    for (final c in cases) {
      test('${c.label} [${c.path}] (${c.requirement})', () {
        expect(_where(check(SourceSet(c.files), c.platform)), c.expected);
      });
    }
  });
}

void main() {
  // Requirement: doc/specs/architecture-guardrails.md FR-013 - Flutter and
  //   dart:ui are banned under lib/src/, dart:io outside adapters/.
  // Path: per case
  _run(
    'FR-013 lib/src/ imports',
    _fr013Cases,
    (s, _) => checkSrcPlatformImports(s),
  );

  // Requirement: doc/specs/architecture-guardrails.md FR-062 - the core entry
  //   points are platform-neutral.
  // Path: per case
  _run(
    'FR-062 entry points',
    _fr062Cases,
    (s, _) => checkEntryPointPlatformImports(s),
  );

  // Requirement: doc/specs/architecture-guardrails.md FR-014 - a dart:io
  //   adapter is not reachable from a core entry point.
  // Path: per case
  _run(
    'FR-014 core reachability',
    _fr014Cases,
    (s, _) => checkDartIoAdaptersNotCoreReachable(s),
  );

  // Requirement: doc/specs/architecture-guardrails.md FR-067 - a dart:io
  //   adapter is reachable from a platform entry point.
  // Path: per case
  _run(
    'FR-067 platform reachability',
    _fr067Cases,
    (s, platform) =>
        checkDartIoAdaptersReachableFromPlatform(s, platformEntries: platform),
  );

  /// Requirement: doc/specs/architecture-guardrails.md FR-014, FR-067 - a
  ///   dart:io adapter reached from both kinds of entry point breaks only
  ///   FR-014, and one reached from a core entry point alone breaks both.
  /// Path: unhappy (rule interaction)
  test('the combined check reports the ids each graph breaks', () {
    final both = SourceSet({
      'lib/adapters.dart': "export 'src/content/adapters/a.dart';\n",
      'lib/io.dart': "export 'src/content/adapters/a.dart';\n",
      _adapter: _io,
    });
    final coreOnly = SourceSet({
      'lib/adapters.dart': "export 'src/content/adapters/a.dart';\n",
      _adapter: _io,
    });

    expect(
      _where([
        ...checkDartIoAdaptersNotCoreReachable(both),
        ...checkDartIoAdaptersReachableFromPlatform(
          both,
          platformEntries: {'lib/io.dart'},
        ),
      ]),
      ['FR-014 $_adapter:1'],
    );
    expect(_where(checkPlatformImports(coreOnly)), [
      'FR-014 $_adapter:1',
      'FR-067 $_adapter:1',
    ]);
  });

  /// Requirement: doc/specs/architecture-guardrails.md FR-004, FR-011 - every
  ///   violation is reported, sorted by path, line and id.
  /// Path: unhappy (multiple violations)
  test('the combined check reports every violation, sorted', () {
    final found = checkPlatformImports(
      SourceSet({'lib/adapters.dart': _io, _domain: "import 'dart:ui';\n$_io"}),
    );

    expect(_where(found), [
      'FR-062 lib/adapters.dart:1',
      'FR-013 $_domain:1',
      'FR-013 $_domain:2',
    ]);
  });

  /// Requirement: doc/specs/architecture-guardrails.md FR-005 - each id has a
  ///   violating fixture on which its registered function yields that id.
  /// Path: unhappy (failure)
  group('registry wiring', () {
    for (final id in platformImportsChecks.keys) {
      /// Requirement: doc/specs/architecture-guardrails.md FR-005 - the
      ///   fixture for the id yields a Violation with that id.
      /// Path: unhappy (failure)
      test('$id has a violating fixture', () {
        final fixture = platformImportsViolatingFixtures[id];

        expect(fixture, isNotNull);
        final found = platformImportsChecks[id]!(fixture!());
        expect(found.map((v) => v.checkId), contains(id));
      });
    }

    /// Requirement: doc/specs/architecture-guardrails.md FR-005 - fixtures and
    ///   functions cover the same ids.
    /// Path: unhappy (failure)
    test('fixtures and checks name the same ids', () {
      expect(
        platformImportsViolatingFixtures.keys.toSet(),
        platformImportsChecks.keys.toSet(),
      );
      expect(platformImportsChecks.keys.toSet(), {
        'FR-013',
        'FR-014',
        'FR-062',
        'FR-067',
      });
    });
  });
}
