import 'package:test/test.dart';

import '../support/source_set.dart';
import '../support/violation.dart';
import 'signal_catalogue.dart';

const String _spec = 'doc/specs/architecture-guardrails.md';
const String _code = 'lib/src/d20_test/application/d20_test_signals.dart';
const String _keys = 'lib/src/shared_ports/signals.dart';
const String _cat = 'doc/observability/signals.md';

/// Lines 2 to 5 hold the metric, span, log event and attribute constants.
const String _signals =
    'abstract final class D20TestSignals {\n'
    "  static const String resolvedMetric = 'srd5e.d20_test.resolved';\n"
    "  static const String resolveSpan = 'srd5e.d20_test.resolve';\n"
    "  static const String doneLogEvent = 'check resolved';\n"
    "  static const String kindAttribute = 'srd5e.d20_test.kind';\n"
    '}\n';

const String _header =
    '| Name | Type | Unit | Attributes | Emitted by | Purpose | '
    'Suggested monitoring |\n|---|---|---|---|---|---|---|\n';

const String _kind =
    '`srd5e.d20_test.kind` (`ability_check`, `saving_throw`, `attack_roll`)';

/// A catalogue row; the first row of [_catalogue] sits on line 5.
String _row(
  String name, {
  String type = 'Counter',
  String attributes = _kind,
  String purpose = 'Counts resolved checks.',
  String monitoring = 'Alert on a sudden drop.',
}) =>
    '| `$name` | $type | {test} | $attributes | ResolveD20Test | $purpose | '
    '$monitoring |\n';

String _catalogue(List<String> rows, {String header = _header}) =>
    '# Signals\n\n$header${rows.join()}';

final List<String> _goodRows = [
  _row('srd5e.d20_test.resolved'),
  _row('srd5e.d20_test.resolve', type: 'span', attributes: ''),
  _row('check resolved', type: 'Log event (DEBUG)', attributes: ''),
];

Map<String, String> _files(String catalogue, {String signals = _signals}) => {
  _code: signals,
  _cat: catalogue,
};

typedef _Check = List<Violation> Function(SourceSet);

typedef _Case = ({
  String label,
  String requirement,
  String path,
  _Check check,
  Map<String, String> files,
  List<String> expected,
});

List<String> _where(List<Violation> violations) => [
  for (final v in violations) '${v.checkId} ${v.path}:${v.line}',
];

_Case _case(
  String label,
  String id,
  String path,
  _Check check,
  Map<String, String> files,
  List<String> expected,
) => (
  label: label,
  requirement: '$_spec $id',
  path: path,
  check: check,
  files: files,
  expected: expected,
);

const String _invalid = 'unhappy (invalid input)';
const String _missing = 'unhappy (missing content)';
const String _boundary = 'unhappy (boundary)';

final List<_Case> _cases = [
  // FR-041
  _case(
    'a valid table with zero data rows and no constants',
    'FR-041',
    'happy',
    checkCatalogueTable,
    {_cat: _catalogue([])},
    [],
  ),
  _case(
    'a valid table with rows, Name in backticks',
    'FR-041',
    'happy',
    checkCatalogueTable,
    _files(_catalogue(_goodRows)),
    [],
  ),
  _case(
    'a header with an extra column',
    'FR-041',
    _invalid,
    checkCatalogueTable,
    _files(
      _catalogue(
        [],
        header:
            '| Name | Type | Unit | Attributes | Emitted by | Purpose | '
            'Suggested monitoring | Extra |\n|---|---|---|---|---|---|---|---|\n',
      ),
    ),
    ['FR-041 $_cat:1'],
  ),
  _case(
    'a header with the columns in another order',
    'FR-041',
    _invalid,
    checkCatalogueTable,
    _files(
      _catalogue(
        [],
        header:
            '| Type | Name | Unit | Attributes | Emitted by | Purpose | '
            'Suggested monitoring |\n|---|---|---|---|---|---|---|\n',
      ),
    ),
    ['FR-041 $_cat:1'],
  ),
  _case(
    'a short row',
    'FR-041',
    _invalid,
    checkCatalogueTable,
    _files(_catalogue(['| `srd5e.d20_test.resolved` | Counter |\n'])),
    ['FR-041 $_cat:5'],
  ),
  _case(
    'a row with eight cells beside a good row',
    'FR-041',
    _invalid,
    checkCatalogueTable,
    _files(
      _catalogue([
        _row('srd5e.d20_test.resolved'),
        '| `a` | Counter | u | x | y | p | m | extra |\n',
      ]),
    ),
    ['FR-041 $_cat:6'],
  ),
  _case(
    'a catalogue with no table',
    'FR-041',
    _invalid,
    checkCatalogueTable,
    _files('# Signals\n\nNo signals yet.\n'),
    ['FR-041 $_cat:1'],
  ),
  _case(
    'a missing catalogue while lib/ declares constants',
    'FR-041',
    _missing,
    checkCatalogueTable,
    {_code: _signals},
    ['FR-041 $_cat:1'],
  ),
  _case(
    'a missing catalogue and no constants is vacuously clean',
    'FR-041',
    'unhappy (empty case)',
    checkCatalogueTable,
    {'lib/srd5e.dart': ''},
    [],
  ),
  // FR-042
  _case(
    'every signal constant is a Name',
    'FR-042',
    'happy',
    checkSignalsInCatalogue,
    _files(_catalogue(_goodRows)),
    [],
  ),
  _case(
    'metric, span and log event named only in code; the attribute is not a signal',
    'FR-042',
    _missing,
    checkSignalsInCatalogue,
    _files(_catalogue([])),
    ['FR-042 $_code:2', 'FR-042 $_code:3', 'FR-042 $_code:4'],
  ),
  _case(
    'one signal missing among several',
    'FR-042',
    _missing,
    checkSignalsInCatalogue,
    _files(_catalogue([_goodRows[0], _goodRows[2]])),
    ['FR-042 $_code:3'],
  ),
  _case(
    'a constant in a comment is not a signal',
    'FR-042',
    'unhappy (false positive)',
    checkSignalsInCatalogue,
    _files(
      _catalogue([]),
      signals:
          'abstract final class D20TestSignals {\n'
          "  // static const String aMetric = 'srd5e.d20_test.a';\n"
          '}\n',
    ),
    [],
  ),
  // FR-043
  _case(
    'every Name is a signal constant',
    'FR-043',
    'happy',
    checkCatalogueNamesInCode,
    _files(_catalogue(_goodRows)),
    [],
  ),
  _case(
    'a Name only in the catalogue',
    'FR-043',
    _missing,
    checkCatalogueNamesInCode,
    _files(_catalogue([..._goodRows, _row('srd5e.d20_test.gone')])),
    ['FR-043 $_cat:8'],
  ),
  _case(
    'an attribute key is not a signal Name',
    'FR-043',
    _missing,
    checkCatalogueNamesInCode,
    _files(_catalogue([..._goodRows, _row('srd5e.d20_test.kind')])),
    ['FR-043 $_cat:8'],
  ),
  _case(
    'a catalogue row with no signal constants at all',
    'FR-043',
    'unhappy (empty case)',
    checkCatalogueNamesInCode,
    {
      _cat: _catalogue([_row('srd5e.d20_test.gone')]),
    },
    ['FR-043 $_cat:5'],
  ),
  // FR-044
  _case(
    'distinct Names',
    'FR-044',
    'happy',
    checkCatalogueNamesUnique,
    _files(_catalogue(_goodRows)),
    [],
  ),
  _case(
    'a Name listed twice, once with backticks and once without',
    'FR-044',
    _invalid,
    checkCatalogueNamesUnique,
    _files(
      _catalogue([
        _row('srd5e.d20_test.resolved'),
        _row('srd5e.d20_test.resolved').replaceAll('`', ''),
      ]),
    ),
    ['FR-044 $_cat:6'],
  ),
  _case(
    'a Name listed three times reports both repeats',
    'FR-044',
    _invalid,
    checkCatalogueNamesUnique,
    _files(
      _catalogue([
        _row('check resolved'),
        _row('check resolved'),
        _row('check resolved'),
      ]),
    ),
    ['FR-044 $_cat:6', 'FR-044 $_cat:7'],
  ),
  // FR-045
  _case(
    'a real Purpose, including text that merely starts with a placeholder',
    'FR-045',
    'happy',
    checkCataloguePurpose,
    _files(_catalogue([_row('a', purpose: 'N/A for rules, counts calls.')])),
    [],
  ),
  _case(
    'an empty Purpose',
    'FR-045',
    _boundary,
    checkCataloguePurpose,
    _files(_catalogue([_row('a', purpose: '')])),
    ['FR-045 $_cat:5'],
  ),
  _case(
    'a whitespace Purpose',
    'FR-045',
    _boundary,
    checkCataloguePurpose,
    _files(_catalogue([_row('a', purpose: '   ')])),
    ['FR-045 $_cat:5'],
  ),
  _case(
    'TODO, tbd, n/a and a dash, in any case',
    'FR-045',
    _boundary,
    checkCataloguePurpose,
    _files(
      _catalogue([
        _row('a', purpose: 'TODO'),
        _row('b', purpose: 'tbd'),
        _row('c', purpose: 'N/A'),
        _row('d', purpose: '-'),
      ]),
    ),
    ['FR-045 $_cat:5', 'FR-045 $_cat:6', 'FR-045 $_cat:7', 'FR-045 $_cat:8'],
  ),
  // FR-046
  _case(
    'a real Suggested monitoring',
    'FR-046',
    'happy',
    checkCatalogueMonitoring,
    _files(_catalogue(_goodRows)),
    [],
  ),
  _case(
    'an empty Suggested monitoring',
    'FR-046',
    _boundary,
    checkCatalogueMonitoring,
    _files(_catalogue([_row('a', monitoring: '')])),
    ['FR-046 $_cat:5'],
  ),
  _case(
    'TBD, todo, n/a and a dash, in any case',
    'FR-046',
    _boundary,
    checkCatalogueMonitoring,
    _files(
      _catalogue([
        _row('a', monitoring: 'tbd'),
        _row('b', monitoring: 'ToDo'),
        _row('c', monitoring: 'n/a'),
        _row('d', monitoring: '-'),
      ]),
    ),
    ['FR-046 $_cat:5', 'FR-046 $_cat:6', 'FR-046 $_cat:7', 'FR-046 $_cat:8'],
  ),
  _case(
    'an empty Purpose does not trip the monitoring check',
    'FR-046',
    'unhappy (rule interaction)',
    checkCatalogueMonitoring,
    _files(_catalogue([_row('a', purpose: '')])),
    [],
  ),
  // FR-047
  _case(
    'lower-case span and a counter with trailing unit text',
    'FR-047',
    'happy',
    checkCatalogueTypes,
    _files(
      _catalogue([
        _row('srd5e.d20_test.resolved', type: 'counter, unit {test}'),
        _row('srd5e.d20_test.resolve', type: 'span'),
        _row('check resolved', type: 'Log event (DEBUG)'),
      ]),
    ),
    [],
  ),
  _case(
    'histogram and gauge both fit a Metric constant',
    'FR-047',
    'happy',
    checkCatalogueTypes,
    _files(
      _catalogue([
        _row('srd5e.d20_test.resolved', type: 'Histogram'),
        _row('srd5e.d20_test.resolved', type: 'Gauge'),
      ]),
    ),
    [],
  ),
  _case(
    'a Type that is not one of the words',
    'FR-047',
    _invalid,
    checkCatalogueTypes,
    _files(_catalogue([_row('srd5e.d20_test.resolved', type: 'Timer')])),
    ['FR-047 $_cat:5'],
  ),
  _case(
    'a word run into the next letters is not the word',
    'FR-047',
    _boundary,
    checkCatalogueTypes,
    _files(_catalogue([_row('srd5e.d20_test.resolved', type: 'Counters')])),
    ['FR-047 $_cat:5'],
  ),
  _case(
    'an empty Type',
    'FR-047',
    _boundary,
    checkCatalogueTypes,
    _files(_catalogue([_row('srd5e.d20_test.resolved', type: '')])),
    ['FR-047 $_cat:5'],
  ),
  _case(
    'a Type that disagrees with the member suffix',
    'FR-047',
    'unhappy (rule interaction)',
    checkCatalogueTypes,
    _files(
      _catalogue([
        _row('srd5e.d20_test.resolved', type: 'Span'),
        _row('srd5e.d20_test.resolve', type: 'Counter'),
        _row('check resolved', type: 'Gauge'),
      ]),
    ),
    ['FR-047 $_cat:5', 'FR-047 $_cat:6', 'FR-047 $_cat:7'],
  ),
  _case(
    'a Name that is no constant is left to FR-043',
    'FR-047',
    'unhappy (rule interaction)',
    checkCatalogueTypes,
    _files(_catalogue([_row('srd5e.d20_test.gone', type: 'Span')])),
    [],
  ),
  // FR-048
  _case(
    'attribute constants listed in backticks, values in parentheses',
    'FR-048',
    'happy',
    checkCatalogueAttributes,
    _files(_catalogue(_goodRows)),
    [],
  ),
  _case(
    'AttributeKeys members count, error.type is a reserved key',
    'FR-048',
    'happy',
    checkCatalogueAttributes,
    {
      _keys:
          'abstract final class AttributeKeys {\n'
          "  static const String outcome = 'srd5e.outcome';\n"
          "  static const String errorType = 'error.type';\n"
          '}\n',
      _cat: _catalogue([
        _row(
          'a',
          attributes: '`srd5e.outcome` (`success`, `failure`), `error.type`',
        ),
      ]),
    },
    [],
  ),
  _case(
    'an attribute constant only in code',
    'FR-048',
    _missing,
    checkCatalogueAttributes,
    _files(_catalogue([_row('srd5e.d20_test.resolved', attributes: '')])),
    ['FR-048 $_code:5'],
  ),
  _case(
    'an AttributeKeys member only in code',
    'FR-048',
    _missing,
    checkCatalogueAttributes,
    {
      _keys:
          'abstract final class AttributeKeys {\n'
          "  static const String outcome = 'srd5e.outcome';\n"
          '}\n',
      _cat: _catalogue([_row('a', attributes: '')]),
    },
    ['FR-048 $_keys:2'],
  ),
  _case(
    'an AttributeKeys member with an empty catalogue: no signal is emitted yet',
    'FR-048',
    'happy',
    checkCatalogueAttributes,
    {
      _keys:
          'abstract final class AttributeKeys {\n'
          "  static const String outcome = 'srd5e.outcome';\n"
          '}\n',
      _cat: _catalogue([]),
    },
    [],
  ),
  _case(
    'an attribute key only in the catalogue',
    'FR-048',
    _missing,
    checkCatalogueAttributes,
    _files(
      _catalogue([
        _row('srd5e.d20_test.resolved', attributes: '$_kind, `srd5e.bogus`'),
      ]),
    ),
    ['FR-048 $_cat:5'],
  ),
  _case(
    'a reserved key only in the catalogue',
    'FR-048',
    _missing,
    checkCatalogueAttributes,
    _files(
      _catalogue([
        _row('srd5e.d20_test.resolved', attributes: '$_kind, `error.type`'),
      ]),
    ),
    ['FR-048 $_cat:5'],
  ),
  _case(
    'an unticked key is not read',
    'FR-048',
    _boundary,
    checkCatalogueAttributes,
    _files(
      _catalogue([
        _row('srd5e.d20_test.resolved', attributes: '$_kind, srd5e.bogus'),
      ]),
    ),
    [],
  ),
];

void main() {
  /// Requirement: per case - doc/specs/architecture-guardrails.md FR-041, FR-042,
  ///   FR-043, FR-044, FR-045, FR-046, FR-047, FR-048 - each catalogue check
  ///   is silent on a clean fixture and reports the exact id, path and line on
  ///   a violating one.
  /// Path: per case
  group('signal catalogue fixtures', () {
    for (final c in _cases) {
      test('${c.label} [${c.path}] (${c.requirement})', () {
        expect(_where(c.check(SourceSet(c.files))), c.expected);
      });
    }
  });

  /// Requirement: doc/specs/architecture-guardrails.md FR-058 - a source set
  ///   with no Dart file under lib/src/ and no catalogue yields no Violation
  ///   from any catalogue check.
  /// Path: happy
  test('a source set with no signals and no catalogue is clean', () {
    final sources = SourceSet({'lib/srd5e.dart': '', 'pubspec.yaml': ''});

    for (final check in signalCatalogueChecks.values) {
      expect(check(sources), isEmpty);
    }
  });

  /// Requirement: doc/specs/architecture-guardrails.md FR-009 - an ignore
  ///   comment does not change a catalogue check's result.
  /// Path: unhappy (rule interaction)
  test('an ignore comment does not suppress a Violation', () {
    final sources = SourceSet(
      _files(
        _catalogue([]),
        signals:
            'abstract final class D20TestSignals {\n'
            '  // ignore: unused_field\n'
            "  static const String resolvedMetric = 'srd5e.d20_test.resolved';\n"
            '}\n',
      ),
    );

    expect(_where(checkSignalsInCatalogue(sources)), ['FR-042 $_code:3']);
  });

  /// Requirement: doc/specs/architecture-guardrails.md FR-004 - a check
  ///   reports every violation, sorted by path and line.
  /// Path: unhappy (multiple violations)
  test('violations from several rows are all reported, sorted', () {
    final sources = SourceSet(
      _files(_catalogue([_row('a', purpose: 'TODO'), _row('b', purpose: '')])),
    );

    expect(_where(checkCataloguePurpose(sources)), [
      'FR-045 $_cat:5',
      'FR-045 $_cat:6',
    ]);
  });

  /// Requirement: doc/specs/architecture-guardrails.md FR-005 - each id has a
  ///   violating fixture on which its registered function yields that id.
  /// Path: unhappy (failure)
  group('registry wiring', () {
    for (final id in signalCatalogueChecks.keys) {
      /// Requirement: doc/specs/architecture-guardrails.md FR-005 - the
      ///   fixture for the id yields a Violation with that id.
      /// Path: unhappy (failure)
      test('$id has a violating fixture', () {
        final fixture = signalCatalogueViolatingFixtures[id];

        expect(fixture, isNotNull);
        final found = signalCatalogueChecks[id]!(fixture!());
        expect(found.map((v) => v.checkId), contains(id));
      });
    }

    /// Requirement: doc/specs/architecture-guardrails.md FR-005 - fixtures
    ///   and functions cover the same ids, FR-041 to FR-048.
    /// Path: unhappy (failure)
    test('fixtures and checks name the same ids', () {
      expect(
        signalCatalogueViolatingFixtures.keys.toSet(),
        signalCatalogueChecks.keys.toSet(),
      );
      expect(signalCatalogueChecks.keys.toSet(), {
        'FR-041',
        'FR-042',
        'FR-043',
        'FR-044',
        'FR-045',
        'FR-046',
        'FR-047',
        'FR-048',
      });
    });
  });
}
