import '../support/source_set.dart';
import '../support/violation.dart';

/// Architecture check A1 of `doc/specs/ability-scores.md` (FR-026).
///
/// Every function is pure: it reads a [SourceSet] and returns [Violation]s.

/// The names `lib/srd5e.dart` must export from `shared_kernel/ability/`, the
/// single list of `doc/specs/ability-scores.md` section 6.
const Set<String> expectedAbilityExports = {
  'Ability',
  'AbilityScore',
  'AbilityModifier',
  'AbilityScores',
  'AbilityScoreResult',
  'ValidAbilityScore',
  'InvalidAbilityScore',
  'AbilityScoreRejection',
};

/// Generic names that would collide with other rejection enums (FR-026).
const Set<String> forbiddenGenericAbilityNames = {
  'BelowMinimum',
  'AboveMaximum',
};

/// Entry points that must not re-export ability names.
const List<String> _entryPoints = [
  'lib/srd5e.dart',
  'lib/adapters.dart',
  'lib/testing.dart',
];

final RegExp _exportDirective = RegExp(
  r'''export\s+['"]([^'"]+)['"]\s*(?:show\s+([^;]+?))?\s*;''',
);

/// The `(uri, shown names)` pairs of the `export` directives of [text]; the
/// names are `null` for an export with no `show` clause.
List<(String, Set<String>?)> _exports(String text) {
  final withoutComments = text.replaceAll(
    RegExp(r'//.*$', multiLine: true),
    '',
  );
  return [
    for (final match in _exportDirective.allMatches(withoutComments))
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

/// A1 (FR-026): `lib/srd5e.dart` exports exactly [expectedAbilityExports]
/// from the ability files, each name once (so `AbilityScoreRejection` is
/// exported exactly once); no generic `BelowMinimum` or `AboveMaximum` name is
/// exported from any entry point; and no other entry point exports from the
/// ability files.
List<Violation> checkAbilityEntryPoints(SourceSet sources) {
  const id = 'A1';
  const abilityFolder = 'src/shared_kernel/ability/';
  final violations = <Violation>[];

  final core = sources.files['lib/srd5e.dart'];
  if (core == null) {
    return const [
      Violation(
        checkId: id,
        path: 'lib/srd5e.dart',
        line: 1,
        detail: 'The entry point does not exist.',
      ),
    ];
  }

  final counts = <String, int>{};
  for (final (uri, shown) in _exports(core)) {
    if (!uri.contains(abilityFolder)) continue;
    if (shown == null) {
      violations.add(
        Violation(
          checkId: id,
          path: 'lib/srd5e.dart',
          line: 1,
          detail: 'The export of $uri has no `show` clause.',
        ),
      );
      continue;
    }
    for (final name in shown) {
      counts[name] = (counts[name] ?? 0) + 1;
    }
  }
  for (final name in expectedAbilityExports) {
    final count = counts[name] ?? 0;
    if (count != 1) {
      violations.add(
        Violation(
          checkId: id,
          path: 'lib/srd5e.dart',
          line: 1,
          detail: '$name is exported $count times; it must be exported once.',
        ),
      );
    }
  }
  for (final name in counts.keys.toSet().difference(expectedAbilityExports)) {
    violations.add(
      Violation(
        checkId: id,
        path: 'lib/srd5e.dart',
        line: 1,
        detail:
            '$name is exported from an ability file but is not on the list.',
      ),
    );
  }

  for (final path in _entryPoints) {
    final text = sources.files[path];
    if (text == null) continue;
    for (final (uri, shown) in _exports(text)) {
      for (final name in shown ?? const <String>{}) {
        if (forbiddenGenericAbilityNames.contains(name)) {
          violations.add(
            Violation(
              checkId: id,
              path: path,
              line: 1,
              detail: 'The generic name $name is exported from $uri.',
            ),
          );
        }
      }
      if (path != 'lib/srd5e.dart' && uri.contains(abilityFolder)) {
        violations.add(
          Violation(
            checkId: id,
            path: path,
            line: 1,
            detail: '$path exports $uri; ability types belong in srd5e.dart.',
          ),
        );
      }
    }
  }
  return sortedViolations(violations);
}
