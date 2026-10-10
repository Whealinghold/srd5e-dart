import 'package:test/test.dart';

import '../support/constants.dart' as constants;
import '../support/real_repository.dart';
import '../support/source_set.dart';
import '../support/violation.dart';
import 'attribute_values.dart';

const String _signals = 'lib/src/combat/application/combat_signals.dart';
const String _exception = 'lib/src/shared_ports/dice_roller/dice_roller.dart';
const String _catalogue = 'doc/observability/signals.md';

const Timeout _budget = Timeout(Duration(seconds: 10));

SourceSet _sources(Map<String, String> files) => SourceSet(files);

List<String> _where(List<Violation> violations) => [
  for (final v in violations) '${v.checkId} ${v.path}:${v.line}',
];

String _signalsClass(String members) =>
    'abstract final class CombatSignals {\n$members}\n';

String _catalogueWith(String attributes) =>
    '# Signals\n\n'
    '| Name | Type | Unit | Attributes | Emitted by | Purpose | Suggested monitoring |\n'
    '|---|---|---|---|---|---|---|\n'
    '| `srd5e.x` | counter | {x} | $attributes | X | p | m |\n';

const String _exceptions =
    'abstract class Srd5eException implements Exception {}\n'
    'class DiceRollerException extends Srd5eException {}\n'
    'class DiceRoller {}\n';

typedef _Case = ({
  String label,
  String path,
  Map<String, String> files,
  List<String> expected,
});

/// Fixtures for FR-085 (a), code.
final List<_Case> _code = [
  (
    label: 'outcome value in the set with the key in the doc comment',
    path: 'happy',
    files: {
      _signals: _signalsClass(
        '  /// The `srd5e.outcome` of a success.\n'
        "  static const String outcomeSuccessValue = 'success';\n",
      ),
    },
    expected: [],
  ),
  (
    label: 'a value outside the outcome set',
    path: 'unhappy (boundary)',
    files: {
      _signals: _signalsClass(
        '  /// The `srd5e.outcome` of a miss.\n'
        "  static const String missValue = 'miss';\n",
      ),
    },
    expected: ['FR-085 $_signals:3'],
  ),
  (
    label: 'a critical_hit word as an outcome value',
    path: 'unhappy (boundary)',
    files: {
      _signals: _signalsClass(
        '  /// The `srd5e.outcome` of a critical hit.\n'
        "  static const String criticalValue = 'critical_hit';\n",
      ),
    },
    expected: ['FR-085 $_signals:3'],
  ),
  (
    label: 'neither is not a roll mode',
    path: 'unhappy (boundary)',
    files: {
      _signals: _signalsClass(
        '  /// The `srd5e.d20_test.roll_mode` when none applies.\n'
        "  static const String neitherValue = 'neither';\n",
      ),
    },
    expected: ['FR-085 $_signals:3'],
  ),
  (
    label: 'a value with no key in its doc comment',
    path: 'unhappy (missing content)',
    files: {
      _signals: _signalsClass(
        '  /// A success.\n'
        "  static const String okValue = 'success';\n",
      ),
    },
    expected: ['FR-085 $_signals:3'],
  ),
  (
    label: 'a value with no doc comment at all',
    path: 'unhappy (missing content)',
    files: {
      _signals: _signalsClass("  static const String okValue = 'success';\n"),
    },
    expected: ['FR-085 $_signals:2'],
  ),
  (
    label: 'error.type value of an Srd5eException subtype',
    path: 'happy',
    files: {
      _exception: _exceptions,
      _signals: _signalsClass(
        '  /// The `error.type` of a failed roll.\n'
        "  static const String rollerValue = 'dice_roller_exception';\n",
      ),
    },
    expected: [],
  ),
  (
    label: 'error.type value of a class that is not a subtype',
    path: 'unhappy (rule conflict)',
    files: {
      _exception: _exceptions,
      _signals: _signalsClass(
        '  /// The `error.type` of a failed roll.\n'
        "  static const String rollerValue = 'dice_roller';\n",
      ),
    },
    expected: ['FR-085 $_signals:3'],
  ),
  (
    label: 'error.type value that is not snake_case',
    path: 'unhappy (invalid input)',
    files: {
      _exception: _exceptions,
      _signals: _signalsClass(
        '  /// The `error.type` of a failed roll.\n'
        "  static const String rollerValue = 'DiceRollerException';\n",
      ),
    },
    expected: ['FR-085 $_signals:3'],
  ),
  (
    label: 'an unrelated key has no constrained value',
    path: 'happy',
    files: {
      _signals: _signalsClass(
        '  /// The `srd5e.condition.name` of a poisoned target.\n'
        "  static const String poisonedValue = 'poisoned';\n",
      ),
    },
    expected: [],
  ),
  (
    label: 'a member without the Value suffix is not examined',
    path: 'unhappy (boundary)',
    files: {
      _signals: _signalsClass(
        "  static const String missMetric = 'srd5e.miss';\n",
      ),
    },
    expected: [],
  ),
  (
    label: 'a Value member of a class that is not a signals class',
    path: 'unhappy (boundary)',
    files: {
      _signals:
          'abstract final class Other {\n'
          "  static const String missValue = 'miss';\n"
          '}\n',
    },
    expected: [],
  ),
  (
    label: 'a bad value named only in a comment',
    path: 'unhappy (false positive)',
    files: {
      _signals: _signalsClass(
        '  // static const String missValue = \'miss\';\n',
      ),
    },
    expected: [],
  ),
  (
    label: 'an ignore comment does not suppress',
    path: 'unhappy (rule interaction)',
    files: {
      _signals: _signalsClass(
        '  /// The `srd5e.outcome` of a miss.\n'
        '  // ignore: architecture\n'
        "  static const String missValue = 'miss';\n",
      ),
    },
    expected: ['FR-085 $_signals:4'],
  ),
];

/// Fixtures for FR-085 (b), catalogue.
final List<_Case> _catalogueCases = [
  (
    label: 'outcome values in the set',
    path: 'happy',
    files: {
      _catalogue: _catalogueWith('`srd5e.outcome` (`success`, `failure`)'),
    },
    expected: [],
  ),
  (
    label: 'a listed value outside the set',
    path: 'unhappy (boundary)',
    files: {_catalogue: _catalogueWith('`srd5e.outcome` (`success`, `hit`)')},
    expected: ['FR-085 $_catalogue:5'],
  ),
  (
    label: 'two bad values in one cell are two violations',
    path: 'unhappy (multiple violations)',
    files: {_catalogue: _catalogueWith('`srd5e.outcome` (`win`, `hit`)')},
    expected: ['FR-085 $_catalogue:5', 'FR-085 $_catalogue:5'],
  ),
  (
    label: 'roll_mode and kind values in their sets',
    path: 'happy',
    files: {
      _catalogue: _catalogueWith(
        '`srd5e.d20_test.roll_mode` (`normal`, `advantage`), '
        '`srd5e.d20_test.kind` (`attack_roll`)',
      ),
    },
    expected: [],
  ),
  (
    label: 'critical_hit values must be true or false',
    path: 'unhappy (boundary)',
    files: {
      _catalogue: _catalogueWith('`srd5e.d20_test.critical_hit` (`yes`)'),
    },
    expected: ['FR-085 $_catalogue:5'],
  ),
  (
    label: 'error.type listing a subtype name',
    path: 'happy',
    files: {
      _exception: _exceptions,
      _catalogue: _catalogueWith('`error.type` (`dice_roller_exception`)'),
    },
    expected: [],
  ),
  (
    label: 'error.type listing a non-subtype',
    path: 'unhappy (rule conflict)',
    files: {
      _exception: _exceptions,
      _catalogue: _catalogueWith('`error.type` (`dice_roller`)'),
    },
    expected: ['FR-085 $_catalogue:5'],
  ),
  (
    label: 'a key outside the shared sets lists any values',
    path: 'happy',
    files: {_catalogue: _catalogueWith('`srd5e.other` (`anything`)')},
    expected: [],
  ),
  (
    label: 'a shared key with no values listed',
    path: 'unhappy (boundary)',
    files: {_catalogue: _catalogueWith('`srd5e.outcome`')},
    expected: [],
  ),
];

String _sectionFive(String markdown) {
  final start = markdown.indexOf('\n## 5.');
  final next = markdown.indexOf('\n## ', start + 1);
  return markdown.substring(start, next < 0 ? markdown.length : next);
}

List<String> _missing(String section) {
  final tokens = {
    for (final m in RegExp(r'`([^`]+)`').allMatches(section)) m.group(1)!,
  };
  return [
    for (final MapEntry(:key, :value)
        in constants.sharedAttributeValueSets.entries)
      for (final v in value)
        if (!tokens.contains(v)) '$key=$v',
  ];
}

void main() {
  for (final entry in {'code': _code, 'catalogue': _catalogueCases}.entries) {
    /// Requirement: per case - doc/specs/architecture-guardrails.md FR-085 - the check
    ///   flags an attribute value outside the key's closed set, a missing
    ///   key, and a bad catalogue value, and nothing else.
    /// Path: per case
    group('FR-085 shared attribute values (${entry.key})', () {
      /// Requirement: per case
      /// Path: per case
      for (final c in entry.value) {
        test('${c.label} [${c.path}]', () {
          final violations = checkAttributeValues(_sources(c.files));

          expect(_where(violations), c.expected);
        });
      }
    });
  }

  /// Requirement: doc/specs/architecture-guardrails.md FR-085 - an empty
  ///   repository has nothing to flag.
  /// Path: unhappy (empty and minimal)
  test('FR-085 accepts an empty repository', () {
    expect(checkAttributeValues(_sources({})), isEmpty);
  });

  /// Requirement: doc/specs/architecture-guardrails.md FR-085 (c) - the sets
  ///   in the support code and observability.md section 5 do not drift.
  /// Path: happy
  test('FR-085 (c): every set value is backticked in section 5', () {
    final section = _sectionFive(
      realRepository.files['doc/rules/observability.md']!,
    );

    expect(_missing(section), isEmpty);
  }, timeout: _budget);

  /// Requirement: doc/specs/architecture-guardrails.md FR-085 (c) - deleting
  ///   one value from a copy of section 5 makes the comparison fail.
  /// Path: unhappy (failure)
  test('FR-085 (c): a value deleted from a copy of section 5 is reported', () {
    final section = _sectionFive(
      realRepository.files['doc/rules/observability.md']!,
    ).replaceAll('`advantage`', 'x');

    expect(_missing(section), ['srd5e.d20_test.roll_mode=advantage']);
  }, timeout: _budget);
}
