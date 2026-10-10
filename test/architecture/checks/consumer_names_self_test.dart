import 'package:test/test.dart';

import '../support/constants.dart';
import '../support/source_set.dart';
import '../support/violation.dart';
import 'consumer_names.dart';

const String _spec = 'doc/specs/architecture-guardrails.md';

/// The first consumer name, assembled at run time (FR-068).
final String _name = consumerDenylist.first.name;
final DeniedName _entry = consumerDenylist.first;

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

/// A single-file case.
_Case _case(
  String label,
  String id,
  String path,
  String body,
  List<String> expected, {
  String kind = 'unhappy (invalid input)',
}) => (
  label: label,
  requirement: '$_spec $id',
  path: kind,
  files: {path: body},
  expected: expected,
);

/// The FR-025 cases: the name under `lib/` in each form.
final List<_Case> _fr025 = [
  _case(
    'the name in a comment',
    'FR-025',
    'lib/src/a.dart',
    '// built for $_name\n',
    ['FR-025 lib/src/a.dart:1'],
  ),
  _case(
    'the name in a doc comment on the third line',
    'FR-025',
    'lib/src/a.dart',
    '\n\n/// $_name\nclass A {}\n',
    ['FR-025 lib/src/a.dart:3'],
  ),
  _case(
    'the name in a string literal',
    'FR-025',
    'lib/src/a.dart',
    "const s = '$_name';\n",
    ['FR-025 lib/src/a.dart:1'],
  ),
  _case(
    'the name in code',
    'FR-025',
    'lib/src/a.dart',
    'class ${_name}Adapter {}\n',
    ['FR-025 lib/src/a.dart:1'],
  ),
  _case(
    'the name in the file path',
    'FR-025',
    'lib/src/$_name/a.dart',
    'class A {}\n',
    ['FR-025 lib/src/$_name/a.dart:1'],
  ),
  _case(
    'upper case',
    'FR-025',
    'lib/src/a.dart',
    '// ${_name.toUpperCase()}\n',
    ['FR-025 lib/src/a.dart:1'],
  ),
  _case(
    'hyphen separators',
    'FR-025',
    'lib/src/a.dart',
    '// ${_entry.spelled('-')}\n',
    ['FR-025 lib/src/a.dart:1'],
  ),
  _case(
    'underscore separators',
    'FR-025',
    'lib/src/a.dart',
    'const ${_entry.spelled('_')} = 1;\n',
    ['FR-025 lib/src/a.dart:1'],
  ),
  _case(
    'space separators',
    'FR-025',
    'lib/src/a.dart',
    '// ${_entry.spelled(' ')}\n',
    ['FR-025 lib/src/a.dart:1'],
  ),
  _case(
    'the name in a non-Dart file under lib/',
    'FR-025',
    'lib/src/content/data/notes.json',
    '{"owner": "$_name"}\n',
    ['FR-025 lib/src/content/data/notes.json:1'],
  ),
  (
    label: 'path and content are both reported',
    requirement: '$_spec FR-025',
    path: 'unhappy (multiple violations)',
    files: {'lib/$_name.dart': '// $_name\n'},
    expected: ['FR-025 lib/$_name.dart:1', 'FR-025 lib/$_name.dart:1'],
  ),
  (
    label: 'an ignore comment does not suppress the Violation',
    requirement: '$_spec FR-025, FR-009',
    path: 'unhappy (rule interaction)',
    files: {'lib/src/a.dart': '// ignore: lint\n// $_name\n'},
    expected: ['FR-025 lib/src/a.dart:2'],
  ),
  _case(
    'the first fragment alone is not the name',
    'FR-025',
    'lib/src/a.dart',
    '// ${_entry.fragments.first}\n',
    [],
    kind: 'unhappy (false positive)',
  ),
  _case(
    'a file outside lib/ is FR-026, not FR-025',
    'FR-025',
    'doc/notes.md',
    '$_name\n',
    [],
    kind: 'unhappy (boundary)',
  ),
  _case(
    'an ordinary lib file',
    'FR-025',
    'lib/src/a.dart',
    'class A {}\n',
    [],
    kind: 'happy',
  ),
];

/// The FR-026 cases: the name outside `lib/`, and the exempt paths.
final List<_Case> _fr026 = [
  _case(
    'the name in .github/workflows/ci.yml',
    'FR-026',
    '.github/workflows/ci.yml',
    'name: $_name\n',
    ['FR-026 .github/workflows/ci.yml:1'],
  ),
  _case(
    'the name in tool/x.dart',
    'FR-026',
    'tool/x.dart',
    'void main() {}\n// $_name\n',
    ['FR-026 tool/x.dart:2'],
  ),
  _case(
    'the name in a test file',
    'FR-026',
    'test/a_test.dart',
    "const s = '$_name';\n",
    ['FR-026 test/a_test.dart:1'],
  ),
  _case('the name in doc/', 'FR-026', 'doc/notes.md', '# Notes\n\n$_name\n', [
    'FR-026 doc/notes.md:3',
  ]),
  _case(
    'the name in example/',
    'FR-026',
    'example/main.dart',
    '// ${_entry.spelled('-')}\n',
    ['FR-026 example/main.dart:1'],
  ),
  _case(
    'the name in a root file',
    'FR-026',
    'README.md',
    '${_name.toUpperCase()}\n',
    ['FR-026 README.md:1'],
  ),
  _case(
    'the name in the file path',
    'FR-026',
    'test/fixtures/${_entry.spelled('_')}/a.txt',
    'x\n',
    ['FR-026 test/fixtures/${_entry.spelled('_')}/a.txt:1'],
  ),
  _case(
    'the name on a pubspec line other than repository:',
    'FR-026',
    'pubspec.yaml',
    'name: srd5e\nhomepage: https://example.org/$_name\n',
    ['FR-026 pubspec.yaml:2'],
  ),
  _case(
    'the name in a pubspec comment above the repository line',
    'FR-026',
    'pubspec.yaml',
    '# $_name\nrepository: https://github.com/$_name/srd5e\n',
    ['FR-026 pubspec.yaml:1'],
  ),
  (
    label: 'an ignore comment does not suppress the Violation',
    requirement: '$_spec FR-026, FR-009',
    path: 'unhappy (rule interaction)',
    files: {'tool/x.dart': '// ignore: lint\n// $_name\n'},
    expected: ['FR-026 tool/x.dart:2'],
  ),
  _case(
    'the pubspec repository: line is exempt',
    'FR-026',
    'pubspec.yaml',
    'name: srd5e\nrepository: https://github.com/$_name/srd5e\n',
    [],
    kind: 'unhappy (boundary)',
  ),
  _case(
    'AGENTS.md is exempt',
    'FR-026',
    'AGENTS.md',
    'Nothing may reference $_name.\n',
    [],
    kind: 'unhappy (boundary)',
  ),
  _case(
    'CLAUDE.md is exempt',
    'FR-026',
    'CLAUDE.md',
    '$_name\n',
    [],
    kind: 'unhappy (boundary)',
  ),
  _case(
    'a file called AGENTS.md in a subfolder is not exempt',
    'FR-026',
    'doc/AGENTS.md',
    '$_name\n',
    ['FR-026 doc/AGENTS.md:1'],
    kind: 'unhappy (boundary)',
  ),
  _case(
    'a repository: line in another file is not exempt',
    'FR-026',
    'doc/other.yaml',
    'repository: https://github.com/$_name/x\n',
    ['FR-026 doc/other.yaml:1'],
    kind: 'unhappy (boundary)',
  ),
  _case(
    'the name under lib/ is FR-025, not FR-026',
    'FR-026',
    'lib/src/a.dart',
    '// $_name\n',
    [],
    kind: 'unhappy (boundary)',
  ),
  _case(
    'an ordinary document',
    'FR-026',
    'doc/notes.md',
    'Nothing to see.\n',
    [],
    kind: 'happy',
  ),
];

/// The FR-068 cases: names in the denylist source, from every list.
final List<_Case> _fr068 = [
  _case(
    'a consumer name in constants.dart',
    'FR-068',
    denylistSourcePaths.first,
    'const x = "${consumerDenylist.first.name}";\n',
    ['FR-068 ${denylistSourcePaths.first}:1'],
  ),
  _case(
    'a trademark name in constants.dart',
    'FR-068',
    denylistSourcePaths.first,
    '\n// ${trademarkDenylist.first.name}\n',
    ['FR-068 ${denylistSourcePaths.first}:2'],
  ),
  _case(
    'an affiliate name in constants.dart',
    'FR-068',
    denylistSourcePaths.first,
    "const x = '${affiliateDenylist.first.name}';\n",
    ['FR-068 ${denylistSourcePaths.first}:1'],
  ),
  _case(
    'a name in the constants test',
    'FR-068',
    denylistSourcePaths.last,
    '// ${trademarkDenylist.last.name}\n',
    ['FR-068 ${denylistSourcePaths.last}:1'],
  ),
  (
    label: 'every list is covered: one Violation per entry per line',
    requirement: '$_spec FR-068',
    path: 'unhappy (multiple violations)',
    files: {
      denylistSourcePaths.first:
          '// ${consumerDenylist.first.name}\n'
          '// ${trademarkDenylist.first.name}\n'
          '// ${affiliateDenylist.first.name}\n',
    },
    expected: [
      'FR-068 ${denylistSourcePaths.first}:1',
      'FR-068 ${denylistSourcePaths.first}:2',
      'FR-068 ${denylistSourcePaths.first}:3',
    ],
  ),
  _case(
    'fragments joined at run time are clean',
    'FR-068',
    denylistSourcePaths.first,
    "const e = DeniedName(['${_entry.fragments.join("', '")}']);\n",
    [],
    kind: 'happy',
  ),
  _case(
    'a file that is not a denylist source is not constrained',
    'FR-068',
    'test/architecture/support/other.dart',
    '// ${trademarkDenylist.first.name}\n',
    [],
    kind: 'unhappy (boundary)',
  ),
  _case(
    'no denylist source in the set is vacuous',
    'FR-068',
    'lib/srd5e.dart',
    '',
    [],
    kind: 'unhappy (empty and minimal)',
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
  // Requirement: doc/specs/architecture-guardrails.md FR-025 - no file under
  //   lib/ names a consumer in its path, comments or code, whatever the
  //   case or separators.
  // Path: per case
  _run('FR-025 consumer names in lib/', _fr025, checkNoConsumerNamesInLib);

  // Requirement: doc/specs/architecture-guardrails.md FR-026 - no file
  //   outside lib/ names a consumer, except AGENTS.md, CLAUDE.md and the
  //   pubspec.yaml repository: line.
  // Path: per case
  _run(
    'FR-026 consumer names outside lib/',
    _fr026,
    checkNoConsumerNamesOutsideLib,
  );

  // Requirement: doc/specs/architecture-guardrails.md FR-068 - the denylist
  //   source files hold no name of any list in plain text.
  // Path: per case
  _run(
    'FR-068 denylist source holds no names',
    _fr068,
    checkDenylistSourceHoldsNoNames,
  );

  /// Requirement: doc/specs/architecture-guardrails.md FR-025 and FR-026 - the
  ///   path of a binary file is scanned too, though its content is not.
  /// Path: unhappy (boundary)
  test('a binary file whose path names a consumer is reported', () {
    final inLib = SourceSet({}, binaryPaths: ['lib/src/$_name.bin']);
    final outside = SourceSet({}, binaryPaths: ['test/$_name.bin']);

    expect(_where(checkNoConsumerNamesInLib(inLib)), [
      'FR-025 lib/src/$_name.bin:1',
    ]);
    expect(_where(checkNoConsumerNamesOutsideLib(outside)), [
      'FR-026 test/$_name.bin:1',
    ]);
  });

  /// Requirement: doc/specs/architecture-guardrails.md FR-004 - a violation
  ///   detail never prints the denied name itself.
  /// Path: unhappy (false positive)
  test('a report line does not spell the name it found', () {
    final found = checkNoConsumerNamesInLib(
      SourceSet({'lib/src/a.dart': '// $_name\n'}),
    );

    expect(found, hasLength(1));
    expect(_entry.appearsIn(found.single.toString()), isFalse);
  });

  /// Requirement: per case - doc/specs/architecture-guardrails.md FR-069 - every
  ///   denylist entry is detected by FR-025 and FR-026 in each form (comment,
  ///   string, path, case, separators), so a name added to the constants is
  ///   enforced without editing the checks.
  /// Path: per case
  group('every consumer denylist entry is enforced', () {
    /// Requirement: per case
    /// Path: per case
    for (var i = 0; i < consumerDenylist.length; i++) {
      final entry = consumerDenylist[i];
      final forms = <String, Map<String, String>>{
        'comment': {'lib/a.dart': '// ${entry.name}\n'},
        'string': {'lib/a.dart': "const s = '${entry.name}';\n"},
        'path': {'lib/${entry.name}.dart': ''},
        'upper case': {'lib/a.dart': '// ${entry.name.toUpperCase()}\n'},
        'hyphens': {'lib/a.dart': '// ${entry.spelled('-')}\n'},
        'underscores': {'lib/a.dart': '// ${entry.spelled('_')}\n'},
        'spaces': {'lib/a.dart': '// ${entry.spelled(' ')}\n'},
      };
      for (final MapEntry(key: form, value: files) in forms.entries) {
        test('entry ${i + 1}: $form in lib/ [unhappy (state error)]', () {
          expect(checkNoConsumerNamesInLib(SourceSet(files)), isNotEmpty);
        });

        test('entry ${i + 1}: $form outside lib/ [unhappy (state error)]', () {
          final moved = {
            for (final e in files.entries)
              e.key.replaceFirst('lib/', 'doc/'): e.value,
          };

          expect(checkNoConsumerNamesOutsideLib(SourceSet(moved)), isNotEmpty);
        });
      }
    }
  });

  /// Requirement: doc/specs/architecture-guardrails.md FR-011 - the output
  ///   does not depend on the order of the files in the SourceSet.
  /// Path: unhappy (determinism)
  test('the same files in another order give the same violations', () {
    final files = {
      'doc/b.md': '$_name\n',
      'doc/a.md': '$_name\n',
      'README.md': '$_name\n',
    };

    final forward = checkNoConsumerNamesOutsideLib(SourceSet(files));
    final reversed = checkNoConsumerNamesOutsideLib(
      SourceSet({for (final k in files.keys.toList().reversed) k: files[k]!}),
    );

    expect(_where(forward), [
      'FR-026 README.md:1',
      'FR-026 doc/a.md:1',
      'FR-026 doc/b.md:1',
    ]);
    expect(reversed, forward);
  });

  /// Requirement: doc/specs/architecture-guardrails.md FR-058 - a source set
  ///   with only the entry file, the pubspec and docs yields no Violation.
  /// Path: happy
  test('a minimal source set is clean', () {
    final empty = SourceSet({
      'lib/srd5e.dart': '',
      'pubspec.yaml': 'name: srd5e\n',
    });

    for (final check in consumerNamesChecks.values) {
      expect(check(empty), isEmpty);
    }
  });

  /// Requirement: doc/specs/architecture-guardrails.md FR-005 - each id has a
  ///   violating fixture on which its registered function yields that id.
  /// Path: unhappy (failure)
  group('registry wiring', () {
    for (final id in consumerNamesChecks.keys) {
      /// Requirement: doc/specs/architecture-guardrails.md FR-005 - the
      ///   fixture for the id yields a Violation with that id.
      /// Path: unhappy (failure)
      test('$id has a violating fixture', () {
        final fixture = consumerNamesViolatingFixtures[id];

        expect(fixture, isNotNull);
        final found = consumerNamesChecks[id]!(fixture!());
        expect(found.map((v) => v.checkId), contains(id));
      });
    }

    /// Requirement: doc/specs/architecture-guardrails.md FR-005 - fixtures and
    ///   functions cover the same ids.
    /// Path: unhappy (failure)
    test('fixtures and checks name the same ids', () {
      expect(
        consumerNamesViolatingFixtures.keys.toSet(),
        consumerNamesChecks.keys.toSet(),
      );
      expect(consumerNamesChecks.keys.toSet(), {'FR-025', 'FR-026', 'FR-068'});
    });
  });
}
