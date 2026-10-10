import 'package:test/test.dart';

import '../support/source_set.dart';
import '../support/violation.dart';
import 'modifier_conventions.dart';

const String _modifier = 'lib/src/shared_kernel/modifier.dart';
const String _mode = 'lib/src/shared_kernel/roll_mode.dart';
const String _abilityFile =
    'lib/src/shared_kernel/ability/ability_modifier.dart';

SourceSet _sources(Map<String, String> files) => SourceSet(files);

List<String> _where(List<Violation> violations) => [
  for (final v in violations) '${v.checkId} ${v.path}:${v.line}',
];

typedef _Case = ({
  String label,
  String requirement,
  String path,
  Map<String, String> files,
  List<String> expected,
});

/// Fixtures for K1: each foreign import is flagged, allowed ones are not.
final List<_Case> _k1 = [
  (
    label: 'an import of a shared_ports file',
    requirement: 'section 6',
    path: 'unhappy (rule conflict)',
    files: {
      _modifier: "import '../shared_ports/dice_roller/dice_roller.dart';\n",
    },
    expected: ['K1 $_modifier:1'],
  ),
  (
    label: 'a package import of the srd5e package',
    requirement: 'section 6',
    path: 'unhappy (rule conflict)',
    files: {_mode: "import 'package:srd5e/src/content/content.dart';\n"},
    expected: ['K1 $_mode:1'],
  ),
  (
    label: 'an import from a subfolder of the kernel',
    requirement: 'section 6',
    path: 'unhappy (boundary)',
    files: {_mode: "\nimport 'dice/die.dart';\n"},
    expected: ['K1 $_mode:2'],
  ),
  (
    label: 'dart:io',
    requirement: 'section 6',
    path: 'unhappy (rule conflict)',
    files: {_modifier: "import 'dart:io';\n"},
    expected: ['K1 $_modifier:1'],
  ),
  (
    label: 'meta, math and a sibling file',
    requirement: 'section 6',
    path: 'happy',
    files: {
      _mode:
          "import 'dart:math' as math;\n"
          "import 'package:meta/meta.dart';\n"
          "import 'roll_circumstance.dart';\n",
    },
    expected: [],
  ),
  (
    label: 'a foreign import in a file outside the scope',
    requirement: 'section 6',
    path: 'unhappy (boundary)',
    files: {
      'lib/src/shared_kernel/other.dart':
          "import '../shared_ports/errors/srd5e_exception.dart';\n",
    },
    expected: [],
  ),
];

/// Fixtures for K2: the two types stay independent.
final List<_Case> _k2 = [
  (
    label: 'Modifier names AbilityModifier',
    requirement: 'doc/specs/modifiers-and-advantage.md FR-043',
    path: 'unhappy (rule interaction)',
    files: {
      _modifier: 'Modifier from(AbilityModifier m) => Modifier(m.value);\n',
    },
    expected: ['K2 $_modifier:1'],
  ),
  (
    label: 'an ability file imports the modifier library',
    requirement: 'doc/specs/modifiers-and-advantage.md FR-043',
    path: 'unhappy (rule interaction)',
    files: {_abilityFile: "import '../modifier.dart';\n"},
    expected: ['K2 $_abilityFile:1'],
  ),
  (
    label: 'AbilityModifier named only in a comment',
    requirement: 'doc/specs/modifiers-and-advantage.md FR-043',
    path: 'unhappy (boundary)',
    files: {_modifier: '// not an AbilityModifier\n'},
    expected: [],
  ),
  (
    label: 'an ability file importing something else',
    requirement: 'doc/specs/modifiers-and-advantage.md FR-043',
    path: 'happy',
    files: {_abilityFile: "import 'ability.dart';\n"},
    expected: [],
  ),
];

void main() {
  /// Requirement: per case - doc/specs/modifiers-and-advantage.md section 6 - K1 flags a
  ///   modifier kernel file that imports anything but meta, math or a sibling.
  /// Path: per case
  group('K1 modifier files import nothing else', () {
    /// Requirement: per case
    /// Path: per case
    for (final c in _k1) {
      test('${c.label} [${c.path}]', () {
        final violations = checkModifierFilesImportNothingElse(
          _sources(c.files),
        );

        expect(_where(violations), c.expected);
      });
    }
  });

  /// Requirement: per case - doc/specs/modifiers-and-advantage.md FR-043 - K2 flags a
  ///   dependency between Modifier and AbilityModifier in either direction.
  /// Path: per case
  group('K2 Modifier and AbilityModifier are independent', () {
    /// Requirement: per case
    /// Path: per case
    for (final c in _k2) {
      test('${c.label} [${c.path}]', () {
        final violations = checkModifierAndAbilityModifierAreIndependent(
          _sources(c.files),
        );

        expect(_where(violations), c.expected);
      });
    }
  });

  /// Requirement: doc/specs/modifiers-and-advantage.md section 6 - an empty
  ///   repository has nothing to flag.
  /// Path: unhappy (empty and minimal)
  test('both checks accept an empty repository', () {
    final empty = _sources({});

    expect(checkModifierFilesImportNothingElse(empty), isEmpty);
    expect(checkModifierAndAbilityModifierAreIndependent(empty), isEmpty);
  });
}
