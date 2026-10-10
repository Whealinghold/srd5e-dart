import '../support/catalogue.dart';
import '../support/constants.dart' as constants;
import '../support/source_set.dart';
import '../support/violation.dart';

/// Signal catalogue checks FR-041 to FR-048 of
/// `doc/specs/architecture-guardrails.md` (section 4.3).
///
/// Every function is pure: it reads a [SourceSet] and returns [Violation]s.
/// The constants come from the lexer's code (FR-008), so comments and strings
/// are ignored. A source set with no catalogue file and no signal constants is
/// clean (FR-058).

Violation _violation(String id, String path, int line, String detail) =>
    Violation(checkId: id, path: path, line: line, detail: detail);

/// FR-041: the catalogue holds a table with the seven required header cells,
/// and every row of it has seven cells. Zero data rows is valid.
List<Violation> checkCatalogueTable(SourceSet sources) {
  const id = 'FR-041';
  final catalogue = parseSignalCatalogue(sources);
  final constantsInCode = signalConstants(sources);
  if (!catalogue.present) {
    if (constantsInCode.isEmpty) return const [];
    return [
      _violation(
        id,
        signalCataloguePath,
        1,
        'The catalogue file is missing while lib/ declares signal or '
        'attribute constants',
      ),
    ];
  }
  if (!catalogue.hasTable) {
    return [
      _violation(
        id,
        signalCataloguePath,
        1,
        'No table with the header cells ${signalCatalogueHeader.join(', ')}, '
        'in that order',
      ),
    ];
  }
  return sortedViolations([
    for (final row in catalogue.malformedRows)
      _violation(
        id,
        signalCataloguePath,
        row.line,
        'A row has ${row.cells} cells; the catalogue has '
        '${signalCatalogueHeader.length}',
      ),
  ]);
}

/// FR-042: every signal constant's value appears as a Name in the catalogue.
List<Violation> checkSignalsInCatalogue(SourceSet sources) {
  const id = 'FR-042';
  final names = {
    for (final row in parseSignalCatalogue(sources).rows) row.name,
  };
  return sortedViolations([
    for (final constant in signalConstants(sources))
      if (constant.isSignal && !names.contains(constant.value))
        _violation(
          id,
          constant.path,
          constant.line,
          '${constant.className}.${constant.member} "${constant.value}" is '
          'not a Name in $signalCataloguePath',
        ),
  ]);
}

/// FR-043: every catalogue Name equals some signal constant's value.
List<Violation> checkCatalogueNamesInCode(SourceSet sources) {
  const id = 'FR-043';
  final values = {
    for (final constant in signalConstants(sources))
      if (constant.isSignal) constant.value,
  };
  return sortedViolations([
    for (final row in parseSignalCatalogue(sources).rows)
      if (!values.contains(row.name))
        _violation(
          id,
          signalCataloguePath,
          row.line,
          'The Name "${row.name}" is not the value of any signal constant '
          'in lib/',
        ),
  ]);
}

/// FR-044: catalogue Names are unique; each repeat is a Violation.
List<Violation> checkCatalogueNamesUnique(SourceSet sources) {
  const id = 'FR-044';
  final firstLine = <String, int>{};
  final violations = <Violation>[];
  for (final row in parseSignalCatalogue(sources).rows) {
    final first = firstLine[row.name];
    if (first == null) {
      firstLine[row.name] = row.line;
      continue;
    }
    violations.add(
      _violation(
        id,
        signalCataloguePath,
        row.line,
        'The Name "${row.name}" repeats the row at line $first',
      ),
    );
  }
  return sortedViolations(violations);
}

/// FR-045: a Purpose cell is neither empty nor a placeholder.
List<Violation> checkCataloguePurpose(SourceSet sources) {
  const id = 'FR-045';
  return sortedViolations([
    for (final row in parseSignalCatalogue(sources).rows)
      if (isEmptyOrPlaceholder(row.purpose))
        _violation(
          id,
          signalCataloguePath,
          row.line,
          'The Purpose of "${row.name}" is empty or a placeholder',
        ),
  ]);
}

/// FR-046: a Suggested monitoring cell is neither empty nor a placeholder.
List<Violation> checkCatalogueMonitoring(SourceSet sources) {
  const id = 'FR-046';
  return sortedViolations([
    for (final row in parseSignalCatalogue(sources).rows)
      if (isEmptyOrPlaceholder(row.monitoring))
        _violation(
          id,
          signalCataloguePath,
          row.line,
          'The Suggested monitoring of "${row.name}" is empty or a '
          'placeholder',
        ),
  ]);
}

final RegExp _typeWord = RegExp(
  r'^(counter|histogram|gauge|span|log event)\b',
  caseSensitive: false,
);

/// The Type words each constant kind accepts (FR-047).
const Map<SignalConstantKind, Set<String>> _typeWordsByKind = {
  SignalConstantKind.metric: {'counter', 'histogram', 'gauge'},
  SignalConstantKind.span: {'span'},
  SignalConstantKind.logEvent: {'log event'},
};

/// FR-047: a Type cell starts with `counter`, `histogram`, `gauge`, `span` or
/// `log event` (any case; trailing text ignored), and agrees with the member
/// suffix of the signal constant the row names.
List<Violation> checkCatalogueTypes(SourceSet sources) {
  const id = 'FR-047';
  final kindByValue = <String, SignalConstantKind>{};
  for (final constant in signalConstants(sources)) {
    if (constant.isSignal) {
      kindByValue.putIfAbsent(constant.value, () => constant.kind);
    }
  }
  final violations = <Violation>[];
  for (final row in parseSignalCatalogue(sources).rows) {
    final match = _typeWord.firstMatch(row.type.trim());
    if (match == null) {
      violations.add(
        _violation(
          id,
          signalCataloguePath,
          row.line,
          'The Type "${row.type}" of "${row.name}" does not start with '
          'counter, histogram, gauge, span or log event',
        ),
      );
      continue;
    }
    final kind = kindByValue[row.name];
    if (kind == null) continue; // FR-043 reports an unknown Name.
    final word = match.group(1)!.toLowerCase();
    if (!_typeWordsByKind[kind]!.contains(word)) {
      violations.add(
        _violation(
          id,
          signalCataloguePath,
          row.line,
          'The Type "$word" of "${row.name}" disagrees with its constant, '
          'a ${kind.name}',
        ),
      );
    }
  }
  return sortedViolations(violations);
}

bool _isAttributeKeyToken(String token) =>
    token.startsWith('srd5e.') ||
    constants.reservedAttributeKeys.contains(token);

/// FR-048: every attribute constant's value is backticked in the Attributes
/// cell of at least one row, and every backticked `srd5e.`-prefixed or
/// reserved key in an Attributes cell is an attribute constant's value.
List<Violation> checkCatalogueAttributes(SourceSet sources) {
  const id = 'FR-048';
  final attributes = [
    for (final constant in signalConstants(sources))
      if (constant.kind == SignalConstantKind.attribute) constant,
  ];
  final rows = parseSignalCatalogue(sources).rows;
  final listed = <String>{
    for (final row in rows) ...backtickedTokens(row.attributes),
  };
  final known = {for (final constant in attributes) constant.value};
  final violations = <Violation>[];
  // An empty catalogue (FR-041: zero data rows is valid) means no signal is
  // emitted yet, so nothing can list the attribute keys; the plan's Phase F
  // acceptance requires the real run to be clean. Once a row exists, every
  // attribute constant must be listed.
  for (final constant in rows.isEmpty ? const <SignalConstant>[] : attributes) {
    if (listed.contains(constant.value)) continue;
    violations.add(
      _violation(
        id,
        constant.path,
        constant.line,
        '${constant.className}.${constant.member} "${constant.value}" is in '
        'no Attributes cell of $signalCataloguePath',
      ),
    );
  }
  for (final row in rows) {
    for (final token in backtickedTokens(row.attributes)) {
      if (!_isAttributeKeyToken(token) || known.contains(token)) continue;
      violations.add(
        _violation(
          id,
          signalCataloguePath,
          row.line,
          'The Attributes of "${row.name}" list "$token", which is no '
          'attribute constant in lib/',
        ),
      );
    }
  }
  return sortedViolations(violations);
}

/// The check function per id, for the registry (`registry.dart`).
const Map<String, List<Violation> Function(SourceSet)> signalCatalogueChecks = {
  'FR-041': checkCatalogueTable,
  'FR-042': checkSignalsInCatalogue,
  'FR-043': checkCatalogueNamesInCode,
  'FR-044': checkCatalogueNamesUnique,
  'FR-045': checkCataloguePurpose,
  'FR-046': checkCatalogueMonitoring,
  'FR-047': checkCatalogueTypes,
  'FR-048': checkCatalogueAttributes,
};

const String _fixtureSignals =
    'lib/src/d20_test/application/d20_test_signals.dart';

const String _fixtureHeader =
    '| Name | Type | Unit | Attributes | Emitted by | Purpose | '
    'Suggested monitoring |\n|---|---|---|---|---|---|---|\n';

const String _fixtureRow =
    '| `srd5e.d20_test.resolved` | Counter | {test} | '
    '`srd5e.outcome` (`success`, `failure`) | ResolveD20Test | Counts '
    'checks. | Alert on a drop. |\n';

SourceSet _fixture({
  String members =
      "  static const String resolvedMetric = 'srd5e.d20_test.resolved';\n",
  String rows = _fixtureRow,
  String? header,
}) => SourceSet({
  _fixtureSignals: 'abstract final class D20TestSignals {\n$members}\n',
  'lib/src/shared_ports/signals.dart':
      'abstract final class AttributeKeys {\n'
      "  static const String outcome = 'srd5e.outcome';\n"
      '}\n',
  signalCataloguePath: '# Signals\n\n${header ?? _fixtureHeader}$rows',
});

String _row(
  String name, {
  String type = 'Counter',
  String attributes = '`srd5e.outcome`',
  String purpose = 'Counts checks.',
  String monitoring = 'Alert on a drop.',
}) =>
    '| `$name` | $type | {test} | $attributes | ResolveD20Test | $purpose | '
    '$monitoring |\n';

/// One minimal violating fixture per check id; the registry merges this map
/// into its own (`registry.dart`, FR-005).
final Map<String, SourceSet Function()> signalCatalogueViolatingFixtures = {
  'FR-041': () =>
      _fixture(rows: '$_fixtureRow| `srd5e.d20_test.other` | Counter |\n'),
  'FR-042': () => _fixture(rows: ''),
  'FR-043': () => _fixture(rows: _fixtureRow + _row('srd5e.d20_test.gone')),
  'FR-044': () => _fixture(rows: _fixtureRow + _fixtureRow),
  'FR-045': () =>
      _fixture(rows: _row('srd5e.d20_test.resolved', purpose: 'TODO')),
  'FR-046': () =>
      _fixture(rows: _row('srd5e.d20_test.resolved', monitoring: '')),
  'FR-047': () => _fixture(rows: _row('srd5e.d20_test.resolved', type: 'Span')),
  'FR-048': () =>
      _fixture(rows: _row('srd5e.d20_test.resolved', attributes: '')),
};
