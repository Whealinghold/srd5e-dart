import 'package:test/test.dart';

import 'exports.dart';
import 'source_set.dart';

SourceSet _sources(Map<String, String> files) => SourceSet(files);

List<String> _at(List<Exported> exported) => [
  for (final e in exported) '${e.name} ${e.path}:${e.line}',
];

List<String> _names(List<Exported> exported) => [
  for (final e in exported) e.name,
];

const String _req = 'doc/specs/architecture-guardrails.md FR-093';

typedef _Case = ({
  String label,
  String path,
  Map<String, String> files,
  String entry,
  List<String> expected,
});

/// Closure cases: `expected` is `<name> <declaring path>:<line>`, sorted by
/// name then path.
final List<_Case> _closureCases = [
  (
    label: 'every declaration kind is found, with its line',
    path: 'happy',
    files: {
      'lib/a.dart': '''
class A {}
abstract interface class B {}
mixin C {}
mixin class D {}
enum E { x }
extension type F(int v) {}
extension G on int {}
typedef H = void Function();
typedef int I(int a);
sealed class J {}
final class K = A with C;
''',
    },
    entry: 'lib/a.dart',
    expected: [
      'A lib/a.dart:1',
      'B lib/a.dart:2',
      'C lib/a.dart:3',
      'D lib/a.dart:4',
      'E lib/a.dart:5',
      'F lib/a.dart:6',
      'G lib/a.dart:7',
      'H lib/a.dart:8',
      'I lib/a.dart:9',
      'J lib/a.dart:10',
      'K lib/a.dart:11',
    ],
  ),
  (
    label: 'a private name is excluded',
    path: 'unhappy (boundary)',
    files: {
      'lib/a.dart':
          'class _A {}\nenum _E { x }\ntypedef _T = int;\nclass B {}\n',
    },
    entry: 'lib/a.dart',
    expected: ['B lib/a.dart:4'],
  ),
  (
    label: 'an unnamed extension and a function are not declarations',
    path: 'unhappy (boundary)',
    files: {
      'lib/a.dart': 'extension on int {}\nvoid helper() {}\nint v = 1;\n',
    },
    entry: 'lib/a.dart',
    expected: [],
  ),
  (
    label: 'a name inside a class body or function is not top-level',
    path: 'unhappy (false positive)',
    files: {
      'lib/a.dart': '''
class Outer {
  void m() {
    final x = 1;
  }
  static const enumeration = 1;
}
void f() {
  var class_ = 1;
}
''',
    },
    entry: 'lib/a.dart',
    expected: ['Outer lib/a.dart:1'],
  ),
  (
    label: 'text in a comment or a string is not a declaration',
    path: 'unhappy (false positive)',
    files: {
      'lib/a.dart': '''
// class Ghost {}
/* enum Ghost2 { x } */
/// mixin Ghost3 {}
const s = 'class Ghost4 {}';
const r = r"""
class Ghost5 {}
""";
class Real {}
''',
    },
    entry: 'lib/a.dart',
    expected: ['Real lib/a.dart:8'],
  ),
  (
    label: 'an export is followed, and an annotation does not hide the name',
    path: 'happy',
    files: {
      'lib/srd5e.dart': "export 'src/a.dart';\n",
      'lib/src/a.dart': "@Deprecated('x')\nclass A {}\n",
    },
    entry: 'lib/srd5e.dart',
    expected: ['A lib/src/a.dart:2'],
  ),
  (
    label: 'an export chain two files deep',
    path: 'happy',
    files: {
      'lib/srd5e.dart': "export 'src/b.dart';\n",
      'lib/src/b.dart': "export 'c.dart';\nclass B {}\n",
      'lib/src/c.dart': "export 'package:srd5e/src/d.dart';\nclass C {}\n",
      'lib/src/d.dart': 'class D {}\n',
    },
    entry: 'lib/srd5e.dart',
    expected: [
      'B lib/src/b.dart:2',
      'C lib/src/c.dart:2',
      'D lib/src/d.dart:1',
    ],
  ),
  (
    label: 'show keeps only the listed names',
    path: 'happy',
    files: {
      'lib/srd5e.dart': "export 'src/a.dart' show A;\n",
      'lib/src/a.dart': 'class A {}\nclass B {}\n',
    },
    entry: 'lib/srd5e.dart',
    expected: ['A lib/src/a.dart:1'],
  ),
  (
    label: 'hide removes the listed names',
    path: 'happy',
    files: {
      'lib/srd5e.dart': "export 'src/a.dart' hide A;\n",
      'lib/src/a.dart': 'class A {}\nclass B {}\n',
    },
    entry: 'lib/srd5e.dart',
    expected: ['B lib/src/a.dart:2'],
  ),
  (
    label: 'show and hide apply at every step of a chain',
    path: 'unhappy (rule interaction)',
    files: {
      'lib/srd5e.dart': "export 'src/b.dart' hide C;\n",
      'lib/src/b.dart': "export 'c.dart' show B, C;\n",
      'lib/src/c.dart': 'class A {}\nclass B {}\nclass C {}\n',
    },
    entry: 'lib/srd5e.dart',
    expected: ['B lib/src/c.dart:2'],
  ),
  (
    label: 'an import is not an export',
    path: 'unhappy (rule interaction)',
    files: {
      'lib/srd5e.dart': "import 'src/a.dart';\nclass Own {}\n",
      'lib/src/a.dart': 'class A {}\n',
    },
    entry: 'lib/srd5e.dart',
    expected: ['Own lib/srd5e.dart:2'],
  ),
  (
    label: 'the entry point own declarations are included',
    path: 'happy',
    files: {
      'lib/src/x/x.dart': "export 'domain/a.dart';\nclass Own {}\n",
      'lib/src/x/domain/a.dart': 'class A {}\n',
    },
    entry: 'lib/src/x/x.dart',
    expected: ['A lib/src/x/domain/a.dart:1', 'Own lib/src/x/x.dart:2'],
  ),
  (
    label: 'a cycle of exports terminates and keeps every name',
    path: 'unhappy (boundary)',
    files: {
      'lib/a.dart': "export 'b.dart';\nclass A {}\n",
      'lib/b.dart': "export 'a.dart';\nclass B {}\n",
    },
    entry: 'lib/a.dart',
    expected: ['A lib/a.dart:2', 'B lib/b.dart:2'],
  ),
  (
    label: 'an export of a missing file is skipped',
    path: 'unhappy (missing content)',
    files: {'lib/a.dart': "export 'missing.dart';\nclass A {}\n"},
    entry: 'lib/a.dart',
    expected: ['A lib/a.dart:2'],
  ),
  (
    label: 'a conditional configuration adds nothing beyond the default URI',
    path: 'unhappy (rule interaction)',
    files: {
      'lib/a.dart': "export 'b.dart' if (dart.library.io) 'c.dart';\n",
      'lib/b.dart': 'class B {}\n',
      'lib/c.dart': 'class C {}\n',
    },
    entry: 'lib/a.dart',
    expected: ['B lib/b.dart:1'],
  ),
  (
    label: 'a part file declarations belong to the library',
    path: 'happy',
    files: {
      'lib/a.dart': "part 'a_part.dart';\nclass A {}\n",
      'lib/a_part.dart': "part of 'a.dart';\nclass P {}\n",
    },
    entry: 'lib/a.dart',
    expected: ['A lib/a.dart:2', 'P lib/a_part.dart:2'],
  ),
  (
    label: 'the same declaration reached twice appears once',
    path: 'happy',
    files: {
      'lib/a.dart': "export 'b.dart';\nexport 'c.dart';\n",
      'lib/b.dart': "export 'd.dart';\n",
      'lib/c.dart': "export 'd.dart';\n",
      'lib/d.dart': 'class D {}\n',
    },
    entry: 'lib/a.dart',
    expected: ['D lib/d.dart:1'],
  ),
  (
    label: 'two files with the same name give two entries',
    path: 'unhappy (rule interaction)',
    files: {
      'lib/a.dart': "export 'b.dart';\nexport 'c.dart';\n",
      'lib/b.dart': 'class Damage {}\n',
      'lib/c.dart': 'class Damage {}\n',
    },
    entry: 'lib/a.dart',
    expected: ['Damage lib/b.dart:1', 'Damage lib/c.dart:1'],
  ),
];

void main() {
  /// Requirement: per case
  /// Path: per case
  group('exportClosure', () {
    for (final c in _closureCases) {
      test('${c.label} [${c.path}] ($_req)', () {
        expect(_at(exportClosure(_sources(c.files), c.entry)), c.expected);
      });
    }
  });

  /// Requirement: doc/specs/architecture-guardrails.md FR-093 - the support
  ///   code takes a barrel that is part of the set; anything else is a defect
  ///   in the caller.
  /// Path: unhappy (invalid input)
  test('an entry point that is not in the source set is an ArgumentError', () {
    expect(
      () => exportClosure(_sources({}), 'lib/srd5e.dart'),
      throwsA(isA<ArgumentError>()),
    );
  });

  /// Requirement: doc/specs/architecture-guardrails.md FR-093 - the result is
  ///   sorted and unmodifiable, so a check cannot disturb a shared closure.
  /// Path: unhappy (immutability)
  test('the closure is sorted by name and cannot be modified', () {
    final closure = exportClosure(
      _sources({'lib/a.dart': 'class Zed {}\nclass Abe {}\n'}),
      'lib/a.dart',
    );

    expect(_names(closure), ['Abe', 'Zed']);
    expect(closure.removeLast, throwsUnsupportedError);
  });

  /// Requirement: doc/specs/architecture-guardrails.md FR-093 - a declaration
  ///   is identified by its declaring file and name, not by its line.
  /// Path: happy
  test('Exported equality ignores the line', () {
    const a = Exported(path: 'lib/a.dart', name: 'A', line: 1);

    expect(a, const Exported(path: 'lib/a.dart', name: 'A', line: 9));
    expect(
      a.hashCode,
      const Exported(path: 'lib/a.dart', name: 'A', line: 9).hashCode,
    );
    expect(
      a == const Exported(path: 'lib/b.dart', name: 'A', line: 1),
      isFalse,
    );
    expect(
      a == const Exported(path: 'lib/a.dart', name: 'B', line: 1),
      isFalse,
    );
  });

  /// Requirement: doc/specs/architecture-guardrails.md FR-077 - the barrel
  ///   scan covers the core entry points and the context barrels, and only
  ///   those.
  /// Path: happy
  group('entryPointsIn', () {
    /// Requirement: doc/specs/architecture-guardrails.md FR-077 - core entry
    ///   points and context barrels are entry points.
    /// Path: happy
    test('finds the core entry points and every context barrel', () {
      final found = entryPointsIn(
        _sources({
          'lib/srd5e.dart': '',
          'lib/adapters.dart': '',
          'lib/testing.dart': '',
          'lib/src/combat/combat.dart': '',
          'lib/src/content/content.dart': '',
        }),
      );

      expect(found, [
        'lib/adapters.dart',
        'lib/src/combat/combat.dart',
        'lib/src/content/content.dart',
        'lib/srd5e.dart',
        'lib/testing.dart',
      ]);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-077 - a file that
    ///   is not a barrel is not an entry point.
    /// Path: unhappy (boundary)
    test('leaves out non-barrels, non-context folders and absent entries', () {
      final found = entryPointsIn(
        _sources({
          'lib/srd5e.dart': '',
          'lib/src/combat/domain/combat.dart': '',
          'lib/src/combat/other.dart': '',
          'lib/src/testing/testing.dart': '',
          'lib/src/shared_ports/shared_ports.dart': '',
          'lib/src/shared_kernel/shared_kernel.dart': '',
          'lib/io.dart': '',
        }),
      );

      expect(found, ['lib/srd5e.dart']);
    });
  });
}
