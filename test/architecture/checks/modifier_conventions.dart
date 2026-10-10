import '../support/source_set.dart';
import '../support/violation.dart';

/// Architecture checks K1 and K2 of `doc/specs/modifiers-and-advantage.md`
/// (section 6 and FR-043).
///
/// Every function is pure: it reads a [SourceSet] and returns [Violation]s.

/// The kernel files of the modifier and roll mode types.
const List<String> modifierKernelFiles = [
  'lib/src/shared_kernel/modifier.dart',
  'lib/src/shared_kernel/roll_circumstance.dart',
  'lib/src/shared_kernel/roll_mode.dart',
];

/// The folder of the ability types, which must not import the modifier library
/// (`doc/specs/ability-scores.md` FR-027).
const String abilityKernelPrefix = 'lib/src/shared_kernel/ability/';

final RegExp _directive = RegExp(
  r'''^[ \t]*(?:import|export)\s+['"]([^'"]+)['"]''',
  multiLine: true,
);

int _lineOf(String text, int offset) =>
    '\n'.allMatches(text.substring(0, offset)).length + 1;

/// Whether [uri] is allowed in a modifier kernel file: the Dart SDK math
/// library, `package:meta`, or a sibling file of the same folder.
bool _isAllowedKernelImport(String uri) =>
    uri == 'dart:math' ||
    uri == 'package:meta/meta.dart' ||
    (!uri.contains(':') && !uri.contains('/'));

/// K1 (section 6): the modifier kernel files import nothing from
/// `shared_ports`, a context or any other part of the package: only
/// `dart:math`, `package:meta` and sibling kernel files.
List<Violation> checkModifierFilesImportNothingElse(SourceSet sources) {
  const id = 'K1';
  final violations = <Violation>[];
  for (final path in modifierKernelFiles.where(sources.files.containsKey)) {
    final text = sources.files[path]!;
    for (final match in _directive.allMatches(text)) {
      final uri = match.group(1)!;
      if (_isAllowedKernelImport(uri)) continue;
      violations.add(
        Violation(
          checkId: id,
          path: path,
          line: _lineOf(text, match.start),
          detail:
              'Imports $uri; a modifier kernel file may import only '
              'dart:math, package:meta and its sibling kernel files.',
        ),
      );
    }
  }
  return sortedViolations(violations);
}

final RegExp _abilityModifierName = RegExp(r'\bAbilityModifier\b');

/// K2 (FR-043): `Modifier` and `AbilityModifier` do not know each other. The
/// modifier files never name `AbilityModifier`, and no file under
/// `shared_kernel/ability/` imports a modifier kernel file.
List<Violation> checkModifierAndAbilityModifierAreIndependent(
  SourceSet sources,
) {
  const id = 'K2';
  final violations = <Violation>[];
  for (final path in modifierKernelFiles.where(sources.files.containsKey)) {
    final code = sources.lexed(path).code;
    for (final match in _abilityModifierName.allMatches(code)) {
      violations.add(
        Violation(
          checkId: id,
          path: path,
          line: _lineOf(code, match.start),
          detail:
              'A modifier kernel file names AbilityModifier; callers '
              'convert with Modifier(abilityModifier.value).',
        ),
      );
    }
  }
  final modifierFileNames = {
    for (final path in modifierKernelFiles) path.split('/').last,
  };
  for (final path in sources.dartPaths(abilityKernelPrefix)) {
    final text = sources.files[path]!;
    for (final match in _directive.allMatches(text)) {
      final uri = match.group(1)!;
      if (modifierFileNames.contains(uri.split('/').last)) {
        violations.add(
          Violation(
            checkId: id,
            path: path,
            line: _lineOf(text, match.start),
            detail:
                'An ability file imports $uri; the ability types must '
                'not import the Modifier library.',
          ),
        );
      }
    }
  }
  return sortedViolations(violations);
}
