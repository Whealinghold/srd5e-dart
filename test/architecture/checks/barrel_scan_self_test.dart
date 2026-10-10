import 'package:test/test.dart';

import '../support/source_set.dart';
import '../support/violation.dart';
import 'barrel_scan.dart';

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

const String _fr077 = 'doc/specs/architecture-guardrails.md FR-077';

const String _combat = 'lib/src/combat/combat.dart';
const String _damage = 'lib/src/combat/domain/damage.dart';
const String _hp = 'lib/src/combat/domain/hit_points.dart';
const String _character = 'lib/src/character/character.dart';
const String _sheet = 'lib/src/character/domain/sheet.dart';

final List<_Case> _genericNames = [
  (
    label: 'Applied, a class, through a context barrel',
    requirement: _fr077,
    path: 'unhappy (invalid input)',
    files: {
      _combat: "export 'domain/damage.dart';\n",
      _damage: 'class Applied {}\n',
    },
    expected: ['FR-077 $_damage:1'],
  ),
  (
    label: 'Rejected, an enum, through lib/srd5e.dart',
    requirement: _fr077,
    path: 'unhappy (invalid input)',
    files: {
      'lib/srd5e.dart': "export 'src/combat/domain/damage.dart';\n",
      _damage: '\nenum Rejected { a, b }\n',
    },
    expected: ['FR-077 $_damage:2'],
  ),
  (
    label: 'Succeeded, a mixin, through lib/adapters.dart',
    requirement: _fr077,
    path: 'unhappy (invalid input)',
    files: {
      'lib/adapters.dart': "export 'src/combat/domain/damage.dart';\n",
      _damage: 'mixin Succeeded {}\n',
    },
    expected: ['FR-077 $_damage:1'],
  ),
  (
    label: 'ContentMissing, an extension type, through lib/testing.dart',
    requirement: _fr077,
    path: 'unhappy (invalid input)',
    files: {
      'lib/testing.dart': "export 'src/combat/domain/damage.dart';\n",
      _damage: 'extension type const ContentMissing(int v) {}\n',
    },
    expected: ['FR-077 $_damage:1'],
  ),
  (
    label: 'Found, a typedef',
    requirement: _fr077,
    path: 'unhappy (invalid input)',
    files: {
      _combat: "export 'domain/damage.dart';\n",
      _damage: 'typedef Found = int;\n',
    },
    expected: ['FR-077 $_damage:1'],
  ),
  (
    label: 'NotFound, a sealed class two exports deep',
    requirement: _fr077,
    path: 'unhappy (invalid input)',
    files: {
      _combat: "export 'domain/hit_points.dart';\n",
      _hp: "export 'damage.dart';\n",
      _damage: 'sealed class NotFound {}\n',
    },
    expected: ['FR-077 $_damage:1'],
  ),
  (
    label: 'Applied exported through two barrels is one Violation',
    requirement: _fr077,
    path: 'unhappy (rule interaction)',
    files: {
      _combat: "export 'domain/damage.dart';\n",
      'lib/srd5e.dart': "export 'src/combat/combat.dart';\n",
      _damage: 'class Applied {}\n',
    },
    expected: ['FR-077 $_damage:1'],
  ),
  (
    label: 'a generic name that no entry point exports',
    requirement: _fr077,
    path: 'happy',
    files: {
      _combat: "export 'domain/hit_points.dart';\n",
      _hp: 'class HitPoints {}\n',
      _damage: 'class Applied {}\n',
    },
    expected: [],
  ),
  (
    label: 'a generic name left out by show',
    requirement: _fr077,
    path: 'unhappy (boundary)',
    files: {
      _combat: "export 'domain/damage.dart' show DamageApplied;\n",
      _damage: 'class Applied {}\nclass DamageApplied {}\n',
    },
    expected: [],
  ),
  (
    label: 'a generic name removed by hide',
    requirement: _fr077,
    path: 'unhappy (boundary)',
    files: {
      _combat: "export 'domain/damage.dart' hide Applied;\n",
      _damage: 'class Applied {}\nclass DamageApplied {}\n',
    },
    expected: [],
  ),
  (
    label: 'a private _Applied',
    requirement: _fr077,
    path: 'unhappy (boundary)',
    files: {
      _combat: "export 'domain/damage.dart';\n",
      _damage: 'class _Applied {}\n',
    },
    expected: [],
  ),
  (
    label: 'an operation-prefixed variant name',
    requirement: _fr077,
    path: 'happy',
    files: {
      _combat: "export 'domain/damage.dart';\n",
      _damage:
          'class DamageApplied {}\nclass CreateCharacterContentMissing {}\n',
    },
    expected: [],
  ),
  (
    label: 'a generic name in a comment or a string',
    requirement: _fr077,
    path: 'unhappy (false positive)',
    files: {
      _combat: "export 'domain/damage.dart';\n",
      _damage:
          "// class Applied {}\nconst s = 'enum Found { a }';\nclass Hit {}\n",
    },
    expected: [],
  ),
  (
    label: 'a generic name declared in a file no entry point reaches',
    requirement: _fr077,
    path: 'unhappy (boundary)',
    files: {
      'lib/srd5e.dart': 'class Hit {}\n',
      'lib/src/combat/domain/internal.dart': 'class Rejected {}\n',
    },
    expected: [],
  ),
  (
    label: 'a generic name on a member or a function is not a declaration',
    requirement: _fr077,
    path: 'unhappy (false positive)',
    files: {
      _combat: "export 'domain/damage.dart';\n",
      _damage: 'class Hit {\n  int Applied() => 1;\n}\nvoid NotFound() {}\n',
    },
    expected: [],
  ),
  (
    label: 'an ignore comment does not suppress (FR-009)',
    requirement: 'doc/specs/architecture-guardrails.md FR-009, FR-077',
    path: 'unhappy (rule interaction)',
    files: {
      _combat: "export 'domain/damage.dart';\n",
      _damage: '// ignore: generic_variant_name\nclass Applied {}\n',
    },
    expected: ['FR-077 $_damage:2'],
  ),
];

final List<_Case> _duplicates = [
  (
    label: 'two files declaring Damage exported through two barrels',
    requirement: _fr077,
    path: 'unhappy (rule interaction)',
    files: {
      _combat: "export 'domain/damage.dart';\n",
      _character: "export 'domain/sheet.dart';\n",
      _damage: 'class Damage {}\n',
      _sheet: '\nclass Damage {}\n',
    },
    expected: ['FR-077 $_sheet:2', 'FR-077 $_damage:1'],
  ),
  (
    label: 'two files declaring Damage exported through the same barrel',
    requirement: _fr077,
    path: 'unhappy (invalid input)',
    files: {
      _combat:
          "export 'domain/damage.dart';\nexport 'domain/hit_points.dart';\n",
      _damage: 'enum Damage { a }\n',
      _hp: 'class Damage {}\n',
    },
    expected: ['FR-077 $_damage:1', 'FR-077 $_hp:1'],
  ),
  (
    label: 'a duplicate between lib/srd5e.dart and a barrel',
    requirement: _fr077,
    path: 'unhappy (rule interaction)',
    files: {
      'lib/srd5e.dart': 'class Damage {}\n',
      _combat: "export 'domain/damage.dart';\n",
      _damage: 'class Damage {}\n',
    },
    expected: ['FR-077 $_damage:1', 'FR-077 lib/srd5e.dart:1'],
  ),
  (
    label: 'one declaration re-exported by two barrels',
    requirement: _fr077,
    path: 'happy',
    files: {
      _combat: "export 'domain/damage.dart';\n",
      _character: "export '../combat/domain/damage.dart';\n",
      'lib/srd5e.dart': "export 'src/combat/combat.dart';\n",
      _damage: 'class Damage {}\n',
    },
    expected: [],
  ),
  (
    label: 'one declaration reached twice through one barrel',
    requirement: _fr077,
    path: 'happy',
    files: {
      _combat:
          "export 'domain/damage.dart';\nexport 'domain/hit_points.dart';\n",
      _hp: "export 'damage.dart';\n",
      _damage: 'class Damage {}\n',
    },
    expected: [],
  ),
  (
    label: 'the same name in a file hidden by hide',
    requirement: _fr077,
    path: 'unhappy (boundary)',
    files: {
      _combat:
          "export 'domain/damage.dart';\nexport 'domain/hit_points.dart' hide Damage;\n",
      _damage: 'class Damage {}\n',
      _hp: 'class Damage {}\nclass HitPoints {}\n',
    },
    expected: [],
  ),
  (
    label: 'the same name left out of a show list',
    requirement: _fr077,
    path: 'unhappy (boundary)',
    files: {
      _combat:
          "export 'domain/damage.dart';\nexport 'domain/hit_points.dart' show HitPoints;\n",
      _damage: 'class Damage {}\n',
      _hp: 'class Damage {}\nclass HitPoints {}\n',
    },
    expected: [],
  ),
  (
    label: 'the same name in a file that no entry point reaches',
    requirement: _fr077,
    path: 'unhappy (boundary)',
    files: {
      _combat: "export 'domain/damage.dart';\n",
      _damage: 'class Damage {}\n',
      _hp: 'class Damage {}\n',
    },
    expected: [],
  ),
  (
    label: 'two AttributeKeys declarations (the signals names get no pass)',
    requirement: _fr077,
    path: 'unhappy (rule interaction)',
    files: {
      'lib/srd5e.dart':
          "export 'src/shared_ports/signals.dart' show AttributeKeys;\n",
      _combat: "export 'application/signals.dart';\n",
      'lib/src/shared_ports/signals.dart':
          'abstract final class AttributeKeys {}\n',
      'lib/src/combat/application/signals.dart':
          'abstract final class AttributeKeys {}\n',
    },
    expected: [
      'FR-077 lib/src/combat/application/signals.dart:1',
      'FR-077 lib/src/shared_ports/signals.dart:1',
    ],
  ),
  (
    label: 'a Signals class and AttributeKeys exported from lib/srd5e.dart',
    requirement: _fr077,
    path: 'happy',
    files: {
      'lib/srd5e.dart':
          "export 'src/d20_test/application/signals.dart';\n"
          "export 'src/shared_ports/signals.dart';\n",
      'lib/src/d20_test/application/signals.dart':
          'abstract final class D20TestSignals {}\n',
      'lib/src/shared_ports/signals.dart':
          'abstract final class AttributeKeys {}\n',
    },
    expected: [],
  ),
];

void _run(String title, List<_Case> cases) {
  /// Requirement: per case
  /// Path: per case
  group(title, () {
    for (final c in cases) {
      test('${c.label} [${c.path}] (${c.requirement})', () {
        expect(_where(checkBarrelScan(SourceSet(c.files))), c.expected);
      });
    }
  });
}

void main() {
  // Requirement: doc/specs/architecture-guardrails.md FR-077 (a) - a generic
  //   variant name exported by a barrel or core entry point is a Violation.
  // Path: per case
  _run('FR-077 (a) generic variant names', _genericNames);

  // Requirement: doc/specs/architecture-guardrails.md FR-077 (b) - two
  //   different declarations with one exported name are a Violation.
  // Path: per case
  _run('FR-077 (b) duplicate names', _duplicates);

  /// Requirement: doc/specs/architecture-guardrails.md FR-077, FR-004 - the
  ///   Violation names the name, the other declaration and the entry points.
  /// Path: unhappy (rule interaction)
  test('the details name the name, the other file and the entry points', () {
    final found = checkBarrelScan(
      SourceSet({
        _combat: "export 'domain/damage.dart';\n",
        _character: "export 'domain/sheet.dart';\n",
        _damage: 'class Damage {}\n',
        _sheet: 'class Damage {}\n',
      }),
    );

    expect(found.map((v) => v.detail), [
      '`Damage` is also declared in $_damage and both are exported (through $_character, $_combat); rename one',
      '`Damage` is also declared in $_sheet and both are exported (through $_character, $_combat); rename one',
    ]);
  });

  /// Requirement: doc/specs/architecture-guardrails.md FR-077, FR-011 - every
  ///   violation is reported once, sorted by path and line.
  /// Path: unhappy (multiple violations)
  test('a generic duplicate is both Violations, sorted by path', () {
    final found = checkBarrelScan(
      SourceSet({
        _combat:
            "export 'domain/damage.dart';\nexport 'domain/hit_points.dart';\n",
        _damage: 'class Found {}\n',
        _hp: 'class Found {}\n',
      }),
    );

    expect(_where(found), [
      'FR-077 $_damage:1',
      'FR-077 $_damage:1',
      'FR-077 $_hp:1',
      'FR-077 $_hp:1',
    ]);
  });

  /// Requirement: doc/specs/architecture-guardrails.md FR-058 - a source set
  ///   with no entry point and no declaration yields no Violation.
  /// Path: unhappy (empty and minimal)
  test('an empty source set and a barrel-less lib/ are clean', () {
    expect(checkBarrelScan(SourceSet({})), isEmpty);
    expect(
      checkBarrelScan(
        SourceSet({'lib/src/combat/domain/damage.dart': 'class Applied {}\n'}),
      ),
      isEmpty,
    );
  });

  /// Requirement: doc/specs/architecture-guardrails.md FR-005 - each id has a
  ///   violating fixture on which its registered function yields that id.
  /// Path: unhappy (failure)
  group('registry wiring', () {
    for (final id in barrelScanChecks.keys) {
      /// Requirement: doc/specs/architecture-guardrails.md FR-005 - the
      ///   fixture for the id yields a Violation with that id.
      /// Path: unhappy (failure)
      test('$id has a violating fixture', () {
        final fixture = barrelScanViolatingFixtures[id];

        expect(fixture, isNotNull);
        final found = barrelScanChecks[id]!(fixture!());
        expect(found.map((v) => v.checkId), contains(id));
      });
    }

    /// Requirement: doc/specs/architecture-guardrails.md FR-005 - fixtures and
    ///   functions cover the same ids.
    /// Path: unhappy (failure)
    test('fixtures and checks name the same ids', () {
      expect(
        barrelScanViolatingFixtures.keys.toSet(),
        barrelScanChecks.keys.toSet(),
      );
      expect(barrelScanChecks.keys.toSet(), {'FR-077'});
    });
  });
}
