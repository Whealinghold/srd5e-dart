import '../support/source_set.dart';
import '../support/violation.dart';

/// Architecture checks D1 to D3 of `doc/specs/dice-and-rolls.md` (FR-064,
/// FR-066 and FR-087).
///
/// Every function is pure: it reads a [SourceSet] and returns [Violation]s.

/// The path prefixes of the dice value objects and the port.
const List<String> diceKernelAndPortPrefixes = [
  'lib/src/shared_kernel/dice/',
  'lib/src/shared_ports/dice_roller/',
];

/// The only file that may name `Random` and import `dart:math`.
const String seededRollerPath =
    'lib/src/shared_ports/adapters/seeded_dice_roller.dart';

/// The dice doubles under `lib/src/testing/`.
const List<String> diceDoublePaths = [
  'lib/src/testing/fixed_dice_roller.dart',
  'lib/src/testing/callback_dice_roller.dart',
];

/// The Dart files in scope for D1 and D3: the kernel dice files, the port
/// folder, the seeded adapter and the dice doubles.
List<String> diceFiles(SourceSet sources) => [
  for (final prefix in diceKernelAndPortPrefixes) ...sources.dartPaths(prefix),
  ...[seededRollerPath, ...diceDoublePaths].where(sources.files.containsKey),
];

int _lineOf(String text, int offset) =>
    '\n'.allMatches(text.substring(0, offset)).length + 1;

/// The calls D1 forbids, with the name used in the report.
final List<(String, RegExp)> _nonDeterministicCalls = [
  ('Random(', RegExp(r'\bRandom\s*\(')),
  ('DateTime.now(', RegExp(r'\bDateTime\s*\.\s*now\s*\(')),
  ('Stopwatch(', RegExp(r'\bStopwatch\s*\(')),
];

/// D1 (FR-064, FR-066): no `Random(`, `DateTime.now(` or `Stopwatch(` call in
/// the dice files. Comments and string literals are ignored.
List<Violation> checkNoHiddenNonDeterminism(SourceSet sources) {
  const id = 'D1';
  final violations = <Violation>[];
  for (final path in diceFiles(sources)) {
    final code = sources.lexed(path).code;
    for (final (name, pattern) in _nonDeterministicCalls) {
      for (final match in pattern.allMatches(code)) {
        violations.add(
          Violation(
            checkId: id,
            path: path,
            line: _lineOf(code, match.start),
            detail:
                'A dice file calls $name; randomness and time come in '
                'through the DiceRoller port.',
          ),
        );
      }
    }
  }
  return sortedViolations(violations);
}

final RegExp _mathImport = RegExp(
  r'''^[ \t]*(?:import|export)\s+['"]dart:math['"]''',
  multiLine: true,
);

/// D2 (FR-066): only `seeded_dice_roller.dart` imports `dart:math` among the
/// dice files, the rest of `shared_ports/` and the doubles.
List<Violation> checkOnlySeededRollerImportsMath(SourceSet sources) {
  const id = 'D2';
  final violations = <Violation>[];
  final paths = {
    ...sources.dartPaths('lib/src/shared_kernel/dice/'),
    ...sources.dartPaths('lib/src/shared_ports/'),
    ...sources.dartPaths('lib/src/testing/'),
  }..remove(seededRollerPath);
  for (final path in paths.toList()..sort()) {
    final text = sources.files[path]!;
    for (final match in _mathImport.allMatches(text)) {
      violations.add(
        Violation(
          checkId: id,
          path: path,
          line: _lineOf(text, match.start),
          detail: 'Only $seededRollerPath may import dart:math.',
        ),
      );
    }
  }
  return violations;
}

final RegExp _observabilityName = RegExp(
  r'\b(?:Observability|Logger|Tracer|Meter|NoopLogger|NoopTracer|NoopMeter)\b',
);

/// D3 (FR-087): no logger, tracer, meter or `Observability` is named in the
/// dice files, so no dice type takes one and none emits a signal.
List<Violation> checkDiceFilesAreSilent(SourceSet sources) {
  const id = 'D3';
  final violations = <Violation>[];
  for (final path in diceFiles(sources)) {
    final code = sources.lexed(path).code;
    for (final match in _observabilityName.allMatches(code)) {
      violations.add(
        Violation(
          checkId: id,
          path: path,
          line: _lineOf(code, match.start),
          detail:
              'A dice file names ${match.group(0)}; the dice types and '
              'the roller are silent by design.',
        ),
      );
    }
  }
  return sortedViolations(violations);
}

/// The names `lib/srd5e.dart` must export from the dice files, the single list
/// of `doc/specs/dice-and-rolls.md` FR-067.
const Set<String> expectedDiceCoreExports = {
  'Die',
  'DiceExpression',
  'DieRoll',
  'RollResult',
  'DiceExpressionParse',
  'ParsedDiceExpression',
  'RejectedDiceExpression',
  'DieCreation',
  'DiceExpressionCreation',
  'DieRollCreation',
  'RollResultCreation',
  'CreatedDie',
  'RejectedDie',
  'CreatedDiceExpression',
  'RejectedDiceExpressionInput',
  'CreatedDieRoll',
  'RejectedDieRoll',
  'CreatedRollResult',
  'RejectedRollResult',
  'DiceExpressionRejection',
  'DieRejection',
  'DieRollRejection',
  'RollResultRejection',
  'DiceRoller',
  'DiceRollerChecked',
  'DiceRollerException',
  'DiceRollerFailureReason',
};

/// The names `lib/adapters.dart` must export from `shared_ports/adapters/`.
const Set<String> expectedDiceAdapterExports = {'SeededDiceRoller'};

/// The names `lib/testing.dart` must export from the dice doubles.
const Set<String> expectedDiceDoubleExports = {
  'FixedDiceRoller',
  'CallbackDiceRoller',
};

final RegExp _exportDirective = RegExp(
  r'''export\s+['"]([^'"]+)['"]\s*(?:show\s+([^;]+?))?\s*;''',
);

/// The `export` directives of [text] whose URI satisfies [uriMatches], as
/// `(uri, shown names)`; the names are `null` for an export with no `show`.
List<(String, Set<String>?)> _exports(
  String text,
  bool Function(String uri) uriMatches,
) {
  final withoutComments = text.replaceAll(
    RegExp(r'//.*$', multiLine: true),
    '',
  );
  return [
    for (final match in _exportDirective.allMatches(withoutComments))
      if (uriMatches(match.group(1)!))
        (
          match.group(1)!,
          match
              .group(2)
              ?.split(',')
              .map((name) => name.trim())
              .where((name) => name.isNotEmpty)
              .toSet(),
        ),
  ];
}

List<Violation> _checkExports({
  required SourceSet sources,
  required String entryPoint,
  required bool Function(String uri) uriMatches,
  required Set<String> expected,
}) {
  const id = 'D4';
  final text = sources.files[entryPoint];
  if (text == null) {
    return [
      Violation(
        checkId: id,
        path: entryPoint,
        line: 1,
        detail: 'The entry point does not exist.',
      ),
    ];
  }
  final violations = <Violation>[];
  final names = <String>{};
  for (final (uri, shown) in _exports(text, uriMatches)) {
    if (shown == null) {
      violations.add(
        Violation(
          checkId: id,
          path: entryPoint,
          line: 1,
          detail: 'The export of $uri has no `show` clause.',
        ),
      );
    } else {
      names.addAll(shown);
    }
  }
  for (final name in expected.difference(names)) {
    violations.add(
      Violation(
        checkId: id,
        path: entryPoint,
        line: 1,
        detail: '$name is not exported but is on the FR-067 list.',
      ),
    );
  }
  for (final name in names.difference(expected)) {
    violations.add(
      Violation(
        checkId: id,
        path: entryPoint,
        line: 1,
        detail:
            '$name is exported from a dice file but is not on the FR-067 '
            'list.',
      ),
    );
  }
  return sortedViolations(violations);
}

/// D4 (FR-067): the entry points export exactly the dice names of FR-067:
/// `lib/srd5e.dart` the 27 core names, `lib/adapters.dart` only
/// `SeededDiceRoller` from `shared_ports/adapters/`, and `lib/testing.dart`
/// `FixedDiceRoller` and `CallbackDiceRoller` from `lib/src/testing/`.
List<Violation> checkDiceEntryPoints(SourceSet sources) => [
  ..._checkExports(
    sources: sources,
    entryPoint: 'lib/srd5e.dart',
    uriMatches: (uri) =>
        uri.contains('src/shared_kernel/dice/') ||
        uri.contains('src/shared_ports/dice_roller/'),
    expected: expectedDiceCoreExports,
  ),
  ..._checkExports(
    sources: sources,
    entryPoint: 'lib/adapters.dart',
    uriMatches: (uri) => uri.contains('src/shared_ports/adapters/'),
    expected: expectedDiceAdapterExports,
  ),
  ..._checkExports(
    sources: sources,
    entryPoint: 'lib/testing.dart',
    uriMatches: (uri) =>
        uri.endsWith('src/testing/fixed_dice_roller.dart') ||
        uri.endsWith('src/testing/callback_dice_roller.dart'),
    expected: expectedDiceDoubleExports,
  ),
];
