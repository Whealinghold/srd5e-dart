import 'package:test/test.dart';

import '../support/source_set.dart';
import '../support/violation.dart';
import 'dice_conventions.dart';

const String _kernelFile = 'lib/src/shared_kernel/dice/fixture.dart';
const String _portFile = 'lib/src/shared_ports/dice_roller/fixture.dart';
const String _doubleFile = 'lib/src/testing/fixed_dice_roller.dart';

SourceSet _sources(Map<String, String> files) => SourceSet(files);

List<String> _where(List<Violation> violations) => [
  for (final v in violations) '${v.checkId} ${v.path}:${v.line}',
];

typedef _Case = ({
  String label,
  String requirement,
  String path,
  String file,
  String code,
  List<String> expected,
});

/// Fixtures for D1 (FR-066): each forbidden call is flagged, and clean code,
/// comments and strings are not.
final List<_Case> _d1 = [
  (
    label: 'Random( in a kernel file',
    requirement: 'doc/specs/dice-and-rolls.md FR-066',
    path: 'unhappy (determinism)',
    file: _kernelFile,
    code: 'int roll() => Random(7).nextInt(6);\n',
    expected: ['D1 $_kernelFile:1'],
  ),
  (
    label: 'an unseeded Random() in the port folder',
    requirement: 'doc/specs/dice-and-rolls.md FR-066',
    path: 'unhappy (determinism)',
    file: _portFile,
    code: 'final r = Random();\n',
    expected: ['D1 $_portFile:1'],
  ),
  (
    label: 'DateTime.now( with spacing',
    requirement: 'doc/specs/dice-and-rolls.md FR-066',
    path: 'unhappy (determinism)',
    file: _kernelFile,
    code: '\nfinal t = DateTime . now ();\n',
    expected: ['D1 $_kernelFile:2'],
  ),
  (
    label: 'Stopwatch( in a double',
    requirement: 'doc/specs/dice-and-rolls.md FR-066',
    path: 'unhappy (determinism)',
    file: _doubleFile,
    code: 'final s = Stopwatch();\n',
    expected: ['D1 $_doubleFile:1'],
  ),
  (
    label: 'Random( in the seeded roller itself',
    requirement: 'doc/specs/dice-and-rolls.md FR-064',
    path: 'unhappy (determinism)',
    file: seededRollerPath,
    code: 'final r = Random(42);\n',
    expected: ['D1 $seededRollerPath:1'],
  ),
  (
    label: 'two calls on two lines',
    requirement: 'doc/specs/dice-and-rolls.md FR-066',
    path: 'unhappy (determinism)',
    file: _kernelFile,
    code: 'a() => Random(1);\nb() => DateTime.now();\n',
    expected: ['D1 $_kernelFile:1', 'D1 $_kernelFile:2'],
  ),
  (
    label: 'the type Random without a call',
    requirement: 'doc/specs/dice-and-rolls.md FR-064',
    path: 'happy',
    file: seededRollerPath,
    code: 'final Random _random;\n',
    expected: [],
  ),
  (
    label: 'a longer name ending in Random',
    requirement: 'doc/specs/dice-and-rolls.md FR-066',
    path: 'unhappy (boundary)',
    file: _kernelFile,
    code: 'final x = SecureRandom(1);\n',
    expected: [],
  ),
  (
    label: 'a mention in a comment and a string',
    requirement: 'doc/specs/dice-and-rolls.md FR-066',
    path: 'unhappy (boundary)',
    file: _kernelFile,
    code: "// Random(7) is the caller's job\nconst s = 'DateTime.now(';\n",
    expected: [],
  ),
  (
    label: 'a file outside the dice scope',
    requirement: 'doc/specs/dice-and-rolls.md FR-066',
    path: 'unhappy (boundary)',
    file: 'lib/src/shared_ports/errors/other.dart',
    code: 'final r = Random(7);\n',
    expected: [],
  ),
];

/// Fixtures for D3 (FR-087).
final List<_Case> _d3 = [
  (
    label: 'a Logger in a kernel file',
    requirement: 'doc/specs/dice-and-rolls.md FR-087',
    path: 'unhappy (rule conflict)',
    file: _kernelFile,
    code: 'final Logger log;\n',
    expected: ['D3 $_kernelFile:1'],
  ),
  (
    label: 'an Observability argument in the port folder',
    requirement: 'doc/specs/dice-and-rolls.md FR-087',
    path: 'unhappy (rule conflict)',
    file: _portFile,
    code: 'void f(Observability o) {}\n',
    expected: ['D3 $_portFile:1'],
  ),
  (
    label: 'a Tracer and a Meter in a double',
    requirement: 'doc/specs/dice-and-rolls.md FR-087',
    path: 'unhappy (rule conflict)',
    file: _doubleFile,
    code: 'Tracer t;\nMeter m;\n',
    expected: ['D3 $_doubleFile:1', 'D3 $_doubleFile:2'],
  ),
  (
    label: 'a NoopLogger in the seeded roller',
    requirement: 'doc/specs/dice-and-rolls.md FR-087',
    path: 'unhappy (rule conflict)',
    file: seededRollerPath,
    code: 'const l = NoopLogger();\n',
    expected: ['D3 $seededRollerPath:1'],
  ),
  (
    label: 'a mention in a comment',
    requirement: 'doc/specs/dice-and-rolls.md FR-087',
    path: 'unhappy (boundary)',
    file: _kernelFile,
    code: '// takes no Observability argument\nint x = 1;\n',
    expected: [],
  ),
  (
    label: 'a longer identifier containing Logger',
    requirement: 'doc/specs/dice-and-rolls.md FR-087',
    path: 'unhappy (boundary)',
    file: _kernelFile,
    code: 'final BlockLogger x;\n',
    expected: [],
  ),
  (
    label: 'a file outside the dice scope',
    requirement: 'doc/specs/dice-and-rolls.md FR-087',
    path: 'unhappy (boundary)',
    file: 'lib/src/shared_ports/observability/logger.dart',
    code: 'abstract interface class Logger {}\n',
    expected: [],
  ),
];

void main() {
  /// Requirement: per case - doc/specs/dice-and-rolls.md FR-064 and FR-066 - check D1 over
  ///   fixtures: each banned call is flagged and clean code is not.
  /// Path: per case
  group('D1 no hidden non-determinism', () {
    /// Requirement: per case
    /// Path: per case
    for (final c in _d1) {
      test('${c.label} [${c.path}]', () {
        final violations = checkNoHiddenNonDeterminism(
          _sources({c.file: c.code}),
        );

        expect(_where(violations), c.expected);
      });
    }
  });

  // Requirement: doc/specs/dice-and-rolls.md FR-066 - check D2 over fixtures:
  //   only the seeded roller may import dart:math.
  // Path: per case
  group('D2 only the seeded roller imports dart:math', () {
    /// Requirement: doc/specs/dice-and-rolls.md FR-066 - a kernel dice file
    ///   importing dart:math is flagged.
    /// Path: unhappy (determinism)
    test('a kernel file importing dart:math is flagged', () {
      final violations = checkOnlySeededRollerImportsMath(
        _sources({_kernelFile: "\nimport 'dart:math';\n"}),
      );

      expect(_where(violations), ['D2 $_kernelFile:2']);
    });

    /// Requirement: doc/specs/dice-and-rolls.md FR-066 - a port, a double and
    ///   another shared_ports file importing dart:math (also with show, or as
    ///   an export) are flagged.
    /// Path: unhappy (determinism)
    test('the port, a double and other ports are flagged', () {
      final violations = checkOnlySeededRollerImportsMath(
        _sources({
          _portFile: "import 'dart:math' show Random;\n",
          _doubleFile: 'import "dart:math";\n',
          'lib/src/shared_ports/errors/other.dart': "export 'dart:math';\n",
        }),
      );

      expect(_where(violations), [
        'D2 $_portFile:1',
        'D2 lib/src/shared_ports/errors/other.dart:1',
        'D2 $_doubleFile:1',
      ]);
    });

    /// Requirement: doc/specs/dice-and-rolls.md FR-066 - the seeded roller may
    ///   import dart:math.
    /// Path: happy
    test('the seeded roller may import dart:math', () {
      final violations = checkOnlySeededRollerImportsMath(
        _sources({seededRollerPath: "import 'dart:math' show Random;\n"}),
      );

      expect(violations, isEmpty);
    });

    /// Requirement: doc/specs/dice-and-rolls.md FR-066 - a comment mentioning
    ///   the import, other dart: libraries and files outside the scope are not
    ///   flagged.
    /// Path: unhappy (boundary)
    test('comments, other libraries and other folders are not flagged', () {
      final violations = checkOnlySeededRollerImportsMath(
        _sources({
          _kernelFile: "// import 'dart:math';\nimport 'dart:collection';\n",
          'lib/src/content/domain/x.dart': "import 'dart:math';\n",
        }),
      );

      expect(violations, isEmpty);
    });
  });

  /// Requirement: per case - doc/specs/dice-and-rolls.md FR-087 - check D3 over fixtures:
  ///   the dice files name no logger, tracer, meter or Observability.
  /// Path: per case
  group('D3 the dice files are silent', () {
    /// Requirement: per case
    /// Path: per case
    for (final c in _d3) {
      test('${c.label} [${c.path}]', () {
        final violations = checkDiceFilesAreSilent(_sources({c.file: c.code}));

        expect(_where(violations), c.expected);
      });
    }
  });

  /// Requirement: doc/specs/dice-and-rolls.md FR-066 and FR-087 - the dice
  ///   scope covers the kernel folder, the port folder, the seeded roller and
  ///   both doubles, and nothing else.
  /// Path: unhappy (boundary)
  group('diceFiles', () {
    /// Requirement: doc/specs/dice-and-rolls.md FR-066 and FR-087 - the scope.
    /// Path: unhappy (boundary)
    test('lists exactly the dice-bearing files that exist', () {
      final sources = _sources({
        _kernelFile: '',
        _portFile: '',
        seededRollerPath: '',
        _doubleFile: '',
        'lib/src/testing/callback_dice_roller.dart': '',
        'lib/src/testing/other_double.dart': '',
        'lib/src/shared_ports/errors/other.dart': '',
        'lib/src/shared_kernel/modifier.dart': '',
        'lib/src/shared_kernel/dice/readme.md': '',
      });

      expect(diceFiles(sources), [
        _kernelFile,
        _portFile,
        seededRollerPath,
        _doubleFile,
        'lib/src/testing/callback_dice_roller.dart',
      ]);
    });

    /// Requirement: doc/specs/dice-and-rolls.md FR-066 - a missing optional
    ///   file is skipped rather than reported.
    /// Path: unhappy (empty and minimal)
    test('an empty repository has no dice files', () {
      expect(diceFiles(_sources({})), isEmpty);
    });
  });
}
