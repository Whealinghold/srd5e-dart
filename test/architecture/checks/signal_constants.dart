import '../support/constants.dart';
import '../support/signal_constants.dart';
import '../support/source_set.dart';
import '../support/violation.dart';

/// Signal and attribute constant checks FR-036 to FR-040 of
/// `doc/specs/architecture-guardrails.md` (section 4.3).
///
/// Every function is pure: it reads a [SourceSet] and returns [Violation]s.
/// All of them scan `lib/` only (FR-072): tests and the architecture fixtures
/// may spell signal names as literals.

final RegExp _metricOrSpanName = RegExp(
  r'^srd5e\.[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$',
);
final RegExp _logEventMessage = RegExp(r'^[a-z][a-z0-9]*( [a-z0-9]+)*$');
final RegExp _attributeName = RegExp(
  r'^srd5e\.[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)*$',
);
final RegExp _logEventAssignment = RegExp(r'''\w*LogEvent\s*=\s*(?=r?['"])''');
final RegExp _topLevelConstString = RegExp(r'const\s+String\s+([A-Za-z_]\w*)');

bool _isIdentifierUnit(int unit) =>
    (unit >= 0x30 && unit <= 0x39) ||
    (unit >= 0x41 && unit <= 0x5A) ||
    (unit >= 0x61 && unit <= 0x7A) ||
    unit == 0x5F ||
    unit == 0x24;

/// FR-036: a string literal under `lib/` that begins with `srd5e.` or equals
/// a reserved attribute key appears only in a constants file.
List<Violation> checkSignalLiteralsOnlyInConstantsFiles(SourceSet sources) {
  const id = 'FR-036';
  final index = SignalIndex.of(sources);
  final violations = <Violation>[];
  for (final path in sources.dartPaths('lib/')) {
    if (index.isConstantsFile(path)) continue;
    for (final literal in sources.lexed(path).strings) {
      final value = literal.value;
      if (!value.startsWith('srd5e.') &&
          !reservedAttributeKeys.contains(value)) {
        continue;
      }
      violations.add(
        Violation(
          checkId: id,
          path: path,
          line: literal.line,
          detail:
              'the literal ${_quote(value)} names a signal or attribute; '
              'only a constants file may spell it, call sites use the '
              'constant',
        ),
      );
    }
  }
  return sortedViolations(violations);
}

String _quote(String value) => "'$value'";

/// FR-037: in a constants file every `srd5e.` literal and every literal
/// initialising a `*LogEvent` member is the plain initialiser of a
/// `static const String` of an `abstract final` signals class; every member
/// of a `*Signals` class carries a kind suffix; no top-level `const String`;
/// a signals class lives in a constants file.
List<Violation> checkSignalsClassShape(SourceSet sources) {
  const id = 'FR-037';
  final index = SignalIndex.of(sources);
  final violations = <Violation>[];

  for (final signalsClass in index.classes) {
    if (!index.isConstantsFile(signalsClass.path)) {
      violations.add(
        Violation(
          checkId: id,
          path: signalsClass.path,
          line: signalsClass.line,
          detail:
              '${signalsClass.name} is a signals class outside a constants '
              'file; declare it in lib/src/<context>/application/'
              '*signals.dart (or AttributeKeys in shared_ports)',
        ),
      );
    }
    if (signalsClass.name == attributeKeysClassName) continue;
    for (final member in signalsClass.members) {
      if (member.kind != SignalKind.unsuffixed) continue;
      violations.add(
        Violation(
          checkId: id,
          path: member.path,
          line: member.line,
          detail:
              '${signalsClass.name}.${member.name} has no kind suffix; end '
              'it with Metric, Span, LogEvent, Attribute or Value',
        ),
      );
    }
  }

  for (final path in index.constantsFiles.toList()..sort()) {
    final lexed = sources.lexed(path);
    final accepted = <int>{
      for (final c in index.classes)
        if (c.path == path && c.isAbstractFinal)
          for (final m in c.members)
            if (m.literalOffset != null) m.literalOffset!,
    };
    final logEventOffsets = <int>{
      for (final m in _logEventAssignment.allMatches(lexed.code)) m.end,
    };
    for (final literal in lexed.strings) {
      final constrained =
          literal.value.startsWith('srd5e.') ||
          logEventOffsets.contains(literal.offset);
      if (!constrained || accepted.contains(literal.offset)) continue;
      violations.add(
        Violation(
          checkId: id,
          path: path,
          line: literal.line,
          detail:
              'the literal ${_quote(literal.value)} must be the plain '
              'initialiser of a static const String member of an abstract '
              'final signals class',
        ),
      );
    }
    final code = lexed.code;
    var depth = 0;
    for (var i = 0; i < code.length; i++) {
      final unit = code.codeUnitAt(i);
      if (unit == 0x7B) {
        depth++;
      } else if (unit == 0x7D) {
        depth--;
      } else if (depth == 0 &&
          unit == 0x63 /* c */ &&
          (i == 0 || !_isIdentifierUnit(code.codeUnitAt(i - 1)))) {
        final match = _topLevelConstString.matchAsPrefix(code, i);
        if (match == null) continue;
        violations.add(
          Violation(
            checkId: id,
            path: path,
            line: lexed.lineOf(i),
            detail:
                'top-level const String ${match.group(1)} in a constants '
                'file; make it a static const member of a signals class',
          ),
        );
        i = match.end - 1;
      }
    }
  }
  return sortedViolations(violations);
}

/// FR-038: metric and span constants have a dotted `srd5e.<context>.<noun>`
/// value whose second segment is the defining context folder; a log event
/// constant is a lowercase message; no signal constant lives in
/// `shared_ports/`.
List<Violation> checkSignalNameShape(SourceSet sources) {
  const id = 'FR-038';
  final violations = <Violation>[];
  for (final constant in SignalIndex.of(sources).constants) {
    if (!constant.isSignal) continue;
    void report(String detail) => violations.add(
      Violation(
        checkId: id,
        path: constant.path,
        line: constant.line,
        detail: '${constant.className}.${constant.name} $detail',
      ),
    );

    if (constant.path.startsWith('lib/src/shared_ports/')) {
      report(
        'is a signal constant in shared_ports; shared constants are the '
        'AttributeKeys members',
      );
      continue;
    }
    final value = constant.value;
    if (value == null) continue; // not plain: FR-037
    if (constant.effectiveKind == SignalKind.logEvent) {
      if (!_logEventMessage.hasMatch(value)) {
        report(
          'has the value ${_quote(value)}; a log event is a lowercase '
          'message of words separated by single spaces',
        );
      }
      continue;
    }
    if (!_metricOrSpanName.hasMatch(value)) {
      report(
        'has the value ${_quote(value)}; it must match '
        'srd5e.<context>.<noun> in lowercase',
      );
      continue;
    }
    final context = contextFolderOf(constant.path);
    final segment = value.split('.')[1];
    if (segment != context) {
      report(
        'has the context segment "$segment" but is defined under '
        '${context ?? 'no context folder'}',
      );
    }
  }
  return sortedViolations(violations);
}

/// FR-039: an attribute constant's value is `srd5e.`-prefixed lowercase
/// dotted, or a reserved key.
List<Violation> checkAttributeNameShape(SourceSet sources) {
  const id = 'FR-039';
  final violations = <Violation>[];
  for (final constant in SignalIndex.of(sources).constants) {
    if (constant.effectiveKind != SignalKind.attribute) continue;
    final value = constant.value;
    if (value == null) continue; // not plain: FR-037
    if (_attributeName.hasMatch(value) ||
        reservedAttributeKeys.contains(value)) {
      continue;
    }
    violations.add(
      Violation(
        checkId: id,
        path: constant.path,
        line: constant.line,
        detail:
            '${constant.className}.${constant.name} has the value '
            '${_quote(value)}; an attribute key is srd5e.<lowercase dotted> '
            'or a reserved key',
      ),
    );
  }
  return sortedViolations(violations);
}

/// FR-040: no two signal constants under `lib/` share a value.
List<Violation> checkSignalValuesUnique(SourceSet sources) {
  const id = 'FR-040';
  final first = <String, SignalConstant>{};
  final violations = <Violation>[];
  final signals =
      SignalIndex.of(
          sources,
        ).constants.where((c) => c.isSignal && c.value != null).toList()
        ..sort((a, b) {
          final byPath = a.path.compareTo(b.path);
          return byPath != 0 ? byPath : a.line.compareTo(b.line);
        });
  for (final constant in signals) {
    final earlier = first[constant.value!];
    if (earlier == null) {
      first[constant.value!] = constant;
      continue;
    }
    violations.add(
      Violation(
        checkId: id,
        path: constant.path,
        line: constant.line,
        detail:
            '${constant.className}.${constant.name} repeats the value '
            '${_quote(constant.value!)} of ${earlier.className}.'
            '${earlier.name} (${earlier.path}:${earlier.line})',
      ),
    );
  }
  return sortedViolations(violations);
}

/// The check function per id, for the registry (`registry.dart`).
const Map<String, List<Violation> Function(SourceSet)> signalConstantsChecks = {
  'FR-036': checkSignalLiteralsOnlyInConstantsFiles,
  'FR-037': checkSignalsClassShape,
  'FR-038': checkSignalNameShape,
  'FR-039': checkAttributeNameShape,
  'FR-040': checkSignalValuesUnique,
};

const String _combatSignals = 'lib/src/combat/application/combat_signals.dart';

/// One minimal violating fixture per check id; the registry merges this map
/// into its own (`registry.dart`, FR-005).
final Map<String, SourceSet Function()> signalConstantsViolatingFixtures = {
  'FR-036': () => SourceSet({
    'lib/src/combat/application/attack.dart':
        "const n = 'srd5e.combat.attack';\n",
  }),
  'FR-037': () => SourceSet({
    _combatSignals:
        'abstract final class CombatSignals {\n'
        "  static const String attack = 'srd5e.combat.attack';\n"
        '}\n',
  }),
  'FR-038': () => SourceSet({
    _combatSignals:
        'abstract final class CombatSignals {\n'
        "  static const String attackSpan = 'srd5e.d20_test.attack';\n"
        '}\n',
  }),
  'FR-039': () => SourceSet({
    _combatSignals:
        'abstract final class CombatSignals {\n'
        "  static const String kindAttribute = 'Kind';\n"
        '}\n',
  }),
  'FR-040': () => SourceSet({
    _combatSignals:
        'abstract final class CombatSignals {\n'
        "  static const String attackSpan = 'srd5e.combat.attack';\n"
        "  static const String attackMetric = 'srd5e.combat.attack';\n"
        '}\n',
  }),
};
