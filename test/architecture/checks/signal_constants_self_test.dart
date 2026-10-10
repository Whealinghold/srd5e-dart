import 'package:test/test.dart';

import '../support/source_set.dart';
import '../support/violation.dart';
import 'signal_constants.dart';

const String _spec = 'doc/specs/architecture-guardrails.md';
const String _combat = 'lib/src/combat/application/combat_signals.dart';
const String _other = 'lib/src/combat/application/other_signals.dart';
const String _content = 'lib/src/content/application/content_signals.dart';
const String _d20 = 'lib/src/d20_test/application/d20_test_signals.dart';
const String _shared = 'lib/src/shared_ports/signals.dart';
const String _sharedOther = 'lib/src/shared_ports/other.dart';
const String _call = 'lib/src/combat/application/attack.dart';
const String _domain = 'lib/src/combat/domain/damage.dart';
const String _keysElsewhere = 'lib/src/combat/domain/keys.dart';
const String _scenario = 'test/scenarios/signals_test.dart';

typedef _Case = ({
  String label,
  String requirement,
  String path,
  Map<String, String> files,
  List<String> expected,
});

_Case _c(
  String label,
  String requirement,
  String path,
  Map<String, String> files,
  List<String> expected,
) => (
  label: label,
  requirement: requirement,
  path: path,
  files: files,
  expected: expected,
);

List<String> _where(List<Violation> violations) => [
  for (final v in violations) '${v.checkId} ${v.path}:${v.line}',
];

/// A signals class whose first member sits on line 2.
String _signals(String members, {String name = 'CombatSignals'}) =>
    'abstract final class $name {\n$members}\n';

String _member(String name, String value) =>
    "  static const String $name = '$value';\n";

final List<_Case> _fr036 = [
  _c(
    'a srd5e. literal at a call site',
    '$_spec FR-036',
    'unhappy (invalid input)',
    {_call: "final n = 'srd5e.combat.attack';\n"},
    ['FR-036 $_call:1'],
  ),
  _c(
    'a srd5e. literal in domain code on a later line',
    '$_spec FR-036',
    'unhappy (invalid input)',
    {_domain: "\nfinal n = 'srd5e.combat.damage';\n"},
    ['FR-036 $_domain:2'],
  ),
  _c(
    'a name built by interpolation',
    '$_spec FR-036',
    'unhappy (invalid input)',
    {_call: "final n = 'srd5e.\${kind}.attack';\n"},
    ['FR-036 $_call:1'],
  ),
  _c(
    'a name built by concatenation',
    '$_spec FR-036',
    'unhappy (invalid input)',
    {_call: "final n = 'srd5e.' + kind;\n"},
    ['FR-036 $_call:1'],
  ),
  _c(
    'the reserved key error.type at a call site',
    '$_spec FR-036',
    'unhappy (invalid input)',
    {_call: "final k = 'error.type';\n"},
    ['FR-036 $_call:1'],
  ),
  _c(
    'a raw string literal',
    '$_spec FR-036, FR-008',
    'unhappy (boundary)',
    {_call: "final n = r'srd5e.combat.attack';\n"},
    ['FR-036 $_call:1'],
  ),
  _c(
    'a literal nested in an interpolation',
    '$_spec FR-036, FR-008',
    'unhappy (boundary)',
    {_call: "final n = 'x\${'srd5e.combat.attack'}';\n"},
    ['FR-036 $_call:1'],
  ),
  _c(
    'an ignore comment does not suppress',
    '$_spec FR-036, FR-009',
    'unhappy (rule interaction)',
    {_call: "// ignore: srd5e\nfinal n = 'srd5e.combat.attack';\n"},
    ['FR-036 $_call:2'],
  ),
  _c('the literal in a constants file', '$_spec FR-036', 'happy', {
    _combat: _signals(_member('attackSpan', 'srd5e.combat.attack')),
  }, []),
  _c(
    'AttributeKeys with both shared literals in its constants file',
    '$_spec FR-036',
    'happy',
    {
      _shared: _signals(
        _member('outcome', 'srd5e.outcome') +
            _member('errorType', 'error.type'),
        name: 'AttributeKeys',
      ),
    },
    [],
  ),
  _c(
    'the same shared literals in any other file',
    '$_spec FR-036',
    'unhappy (rule interaction)',
    {
      _keysElsewhere: _signals(
        _member('outcome', 'srd5e.outcome') +
            _member('errorType', 'error.type'),
        name: 'AttributeKeys',
      ),
    },
    ['FR-036 $_keysElsewhere:2', 'FR-036 $_keysElsewhere:3'],
  ),
  _c('the same literal under test/', '$_spec FR-036, FR-072', 'happy', {
    _scenario: "final n = 'srd5e.combat.attack';\nfinal k = 'error.type';\n",
  }, []),
  _c(
    'names in comments only',
    '$_spec FR-036, FR-008',
    'unhappy (false positive)',
    {_call: "// srd5e.combat.attack error.type\n/// srd5e.combat.attack\n"},
    [],
  ),
  _c(
    'strings that only resemble the names',
    '$_spec FR-036',
    'unhappy (boundary)',
    {
      _call:
          "final a = 'srd5e';\nfinal b = 'error.types';\nfinal c = ' srd5e.x';\n",
    },
    [],
  ),
  _c(
    'an empty repository',
    '$_spec FR-036',
    'unhappy (empty and minimal)',
    {},
    [],
  ),
];

final List<_Case> _fr037 = [
  _c(
    'a member with no kind suffix',
    '$_spec FR-037',
    'unhappy (invalid input)',
    {_combat: _signals(_member('attack', 'srd5e.combat.attack'))},
    ['FR-037 $_combat:2'],
  ),
  _c(
    'a signals class outside a constants file',
    '$_spec FR-037',
    'unhappy (rule interaction)',
    {_domain: 'abstract final class CombatSignals {}\n'},
    ['FR-037 $_domain:1'],
  ),
  _c(
    'a signals class in shared_ports that is not AttributeKeys',
    '$_spec FR-037',
    'unhappy (rule interaction)',
    {_sharedOther: 'abstract final class SharedSignals {\n}\n'},
    ['FR-037 $_sharedOther:1'],
  ),
  _c(
    'AttributeKeys declared outside a constants file',
    '$_spec FR-037',
    'unhappy (rule interaction)',
    {
      _keysElsewhere: _signals(
        _member('outcome', 'srd5e.outcome'),
        name: 'AttributeKeys',
      ),
    },
    ['FR-037 $_keysElsewhere:1'],
  ),
  _c(
    'a top-level const String in a constants file',
    '$_spec FR-037',
    'unhappy (invalid input)',
    {
      _combat:
          "const String note = 'x';\n"
          '${_signals(_member('attackSpan', 'srd5e.combat.attack'))}',
    },
    ['FR-037 $_combat:1'],
  ),
  _c(
    'a srd5e. literal that initialises nothing',
    '$_spec FR-037',
    'unhappy (invalid input)',
    {
      _combat:
          "final x = 'srd5e.combat.a';\n"
          '${_signals(_member('attackSpan', 'srd5e.combat.attack'))}',
    },
    ['FR-037 $_combat:1'],
  ),
  _c(
    'the class is not abstract final',
    '$_spec FR-037',
    'unhappy (invalid input)',
    {
      _combat:
          'class CombatSignals {\n'
          "${_member('attackSpan', 'srd5e.combat.attack')}"
          '}\n',
    },
    ['FR-037 $_combat:2'],
  ),
  _c(
    'adjacent literals as the initialiser',
    '$_spec FR-037',
    'unhappy (boundary)',
    {
      _combat: _signals(
        "  static const String attackSpan = 'srd5e.' 'combat.attack';\n",
      ),
    },
    ['FR-037 $_combat:2'],
  ),
  _c(
    'an interpolated srd5e. initialiser',
    '$_spec FR-037',
    'unhappy (boundary)',
    {
      _combat: _signals(
        "  static const String attackSpan = 'srd5e.combat.\$x';\n",
      ),
    },
    ['FR-037 $_combat:2'],
  ),
  _c(
    'a log event built by concatenation',
    '$_spec FR-037',
    'unhappy (boundary)',
    {
      _content: _signals(
        "  static const String setLoadedLogEvent = 'set' + ' loaded';\n",
        name: 'ContentSignals',
      ),
    },
    ['FR-037 $_content:2'],
  ),
  _c(
    'a log event in a class that is not a signals class',
    '$_spec FR-037',
    'unhappy (invalid input)',
    {
      _content:
          'class Helper {\n'
          "${_member('setLoadedLogEvent', 'set loaded')}"
          '}\n',
    },
    ['FR-037 $_content:2'],
  ),
  _c(
    'every suffix, a log event message and AttributeKeys members without one',
    '$_spec FR-037',
    'happy',
    {
      _content: _signals(
        _member('setLoadedLogEvent', 'content set loaded') +
            _member('loadSpan', 'srd5e.content.load') +
            _member('loadMetric', 'srd5e.content.loads') +
            _member('kindAttribute', 'srd5e.content.kind') +
            _member('okValue', 'ok'),
        name: 'ContentSignals',
      ),
      _shared: _signals(
        _member('outcome', 'srd5e.outcome') +
            _member('errorType', 'error.type'),
        name: 'AttributeKeys',
      ),
    },
    [],
  ),
  _c(
    'an unconstrained literal in a helper class of a constants file',
    '$_spec FR-037',
    'unhappy (false positive)',
    {_combat: "class Helper {\n  static const String note = 'hello';\n}\n"},
    [],
  ),
  _c(
    'a name in a comment of a constants file',
    '$_spec FR-037, FR-008',
    'unhappy (false positive)',
    {_combat: '// srd5e.combat.attack\n${_signals('')}'},
    [],
  ),
  _c(
    'an empty constants file',
    '$_spec FR-037',
    'unhappy (empty and minimal)',
    {_combat: ''},
    [],
  ),
];

final List<_Case> _fr038 = [
  _c(
    'a metric whose context segment is another context',
    '$_spec FR-038',
    'unhappy (boundary)',
    {_combat: _signals(_member('attackSpan', 'srd5e.d20_test.attack'))},
    ['FR-038 $_combat:2'],
  ),
  _c(
    'a span with an uppercase segment',
    '$_spec FR-038',
    'unhappy (boundary)',
    {_combat: _signals(_member('attackSpan', 'srd5e.combat.Attack'))},
    ['FR-038 $_combat:2'],
  ),
  _c(
    'a metric with no noun segment',
    '$_spec FR-038',
    'unhappy (boundary)',
    {_combat: _signals(_member('attackMetric', 'srd5e.combat'))},
    ['FR-038 $_combat:2'],
  ),
  _c(
    'a metric without the srd5e prefix',
    '$_spec FR-038',
    'unhappy (invalid input)',
    {_combat: _signals(_member('attackMetric', 'combat.attack'))},
    ['FR-038 $_combat:2'],
  ),
  _c(
    'a dotted log event',
    '$_spec FR-038',
    'unhappy (invalid input)',
    {
      _content: _signals(
        _member('setLoadedLogEvent', 'content.set.loaded'),
        name: 'ContentSignals',
      ),
    },
    ['FR-038 $_content:2'],
  ),
  _c(
    'a log event starting with a capital',
    '$_spec FR-038',
    'unhappy (invalid input)',
    {
      _content: _signals(
        _member('setLoadedLogEvent', 'Content set'),
        name: 'ContentSignals',
      ),
    },
    ['FR-038 $_content:2'],
  ),
  _c(
    'a log event with a double space',
    '$_spec FR-038',
    'unhappy (boundary)',
    {
      _content: _signals(
        _member('setLoadedLogEvent', 'content  set'),
        name: 'ContentSignals',
      ),
    },
    ['FR-038 $_content:2'],
  ),
  _c(
    'a signal constant in shared_ports',
    '$_spec FR-038',
    'unhappy (rule interaction)',
    {
      _sharedOther: _signals(
        _member('attackSpan', 'srd5e.shared.attack'),
        name: 'SharedSignals',
      ),
    },
    ['FR-038 $_sharedOther:2'],
  ),
  _c(
    'valid span, metric and log event, digits and underscores',
    '$_spec FR-038',
    'happy',
    {
      _d20: _signals(
        _member('resolveSpan', 'srd5e.d20_test.resolve') +
            _member('rollsMetric', 'srd5e.d20_test.roll_count') +
            _member('deepMetric', 'srd5e.d20_test.roll.count') +
            _member('doneLogEvent', 'check 2 done'),
        name: 'D20TestSignals',
      ),
    },
    [],
  ),
  _c(
    'a malformed attribute is not this check',
    '$_spec FR-038',
    'unhappy (false positive)',
    {_combat: _signals(_member('kindAttribute', 'Kind'))},
    [],
  ),
  _c(
    'a non-plain initialiser is left to FR-037',
    '$_spec FR-038, FR-037',
    'unhappy (false positive)',
    {_combat: _signals("  static const String attackSpan = 'a' + 'b';\n")},
    [],
  ),
  _c(
    'an empty repository',
    '$_spec FR-038',
    'unhappy (empty and minimal)',
    {},
    [],
  ),
];

final List<_Case> _fr039 = [
  _c(
    'an attribute value with no srd5e prefix',
    '$_spec FR-039',
    'unhappy (boundary)',
    {_combat: _signals(_member('kindAttribute', 'kind'))},
    ['FR-039 $_combat:2'],
  ),
  _c(
    'a capitalised attribute value',
    '$_spec FR-039',
    'unhappy (boundary)',
    {_combat: _signals(_member('kindAttribute', 'Outcome'))},
    ['FR-039 $_combat:2'],
  ),
  _c(
    'an uppercase segment after the prefix',
    '$_spec FR-039',
    'unhappy (boundary)',
    {_combat: _signals(_member('kindAttribute', 'srd5e.combat.Kind'))},
    ['FR-039 $_combat:2'],
  ),
  _c(
    'the prefix alone',
    '$_spec FR-039',
    'unhappy (empty and minimal)',
    {_combat: _signals(_member('kindAttribute', 'srd5e.'))},
    ['FR-039 $_combat:2'],
  ),
  _c(
    'an AttributeKeys member with a bare value',
    '$_spec FR-039',
    'unhappy (invalid input)',
    {_shared: _signals(_member('outcome', 'outcome'), name: 'AttributeKeys')},
    ['FR-039 $_shared:2'],
  ),
  _c('valid keys, a deep key and the reserved key', '$_spec FR-039', 'happy', {
    _combat: _signals(
      _member('kindAttribute', 'srd5e.d20_test.kind') +
          _member('shortAttribute', 'srd5e.kind') +
          _member('reservedAttribute', 'error.type'),
    ),
    _shared: _signals(
      _member('outcome', 'srd5e.outcome') + _member('errorType', 'error.type'),
      name: 'AttributeKeys',
    ),
  }, []),
  _c(
    'an attribute value constant is unconstrained here',
    '$_spec FR-039',
    'unhappy (false positive)',
    {_combat: _signals(_member('successValue', 'Success'))},
    [],
  ),
  _c(
    'a malformed metric is not this check',
    '$_spec FR-039',
    'unhappy (false positive)',
    {_combat: _signals(_member('attackMetric', 'Attack'))},
    [],
  ),
  _c(
    'an empty repository',
    '$_spec FR-039',
    'unhappy (empty and minimal)',
    {},
    [],
  ),
];

final List<_Case> _fr040 = [
  _c(
    'the same value twice in one class',
    '$_spec FR-040',
    'unhappy (invalid input)',
    {
      _combat: _signals(
        _member('attackSpan', 'srd5e.combat.attack') +
            _member('attackMetric', 'srd5e.combat.attack'),
      ),
    },
    ['FR-040 $_combat:3'],
  ),
  _c(
    'the same value in two files',
    '$_spec FR-040',
    'unhappy (invalid input)',
    {
      _combat: _signals(_member('attackSpan', 'srd5e.combat.attack')),
      _other: _signals(
        _member('attackMetric', 'srd5e.combat.attack'),
        name: 'OtherSignals',
      ),
    },
    ['FR-040 $_other:2'],
  ),
  _c(
    'the same log event twice',
    '$_spec FR-040',
    'unhappy (invalid input)',
    {
      _content: _signals(
        _member('aLogEvent', 'set loaded') + _member('bLogEvent', 'set loaded'),
        name: 'ContentSignals',
      ),
    },
    ['FR-040 $_content:3'],
  ),
  _c(
    'three copies report the second and the third',
    '$_spec FR-040',
    'unhappy (boundary)',
    {
      _combat: _signals(
        _member('aSpan', 'srd5e.combat.a') +
            _member('bSpan', 'srd5e.combat.a') +
            _member('cSpan', 'srd5e.combat.a'),
      ),
    },
    ['FR-040 $_combat:3', 'FR-040 $_combat:4'],
  ),
  _c('distinct values', '$_spec FR-040', 'happy', {
    _combat: _signals(
      _member('aSpan', 'srd5e.combat.a') +
          _member('bSpan', 'srd5e.combat.b') +
          _member('aLogEvent', 'a done'),
    ),
  }, []),
  _c(
    'an attribute that repeats a signal value',
    '$_spec FR-040',
    'unhappy (false positive)',
    {
      _combat: _signals(
        _member('aSpan', 'srd5e.combat.a') +
            _member('aAttribute', 'srd5e.combat.a') +
            _member('bValue', 'srd5e.combat.a'),
      ),
    },
    [],
  ),
  _c(
    'a duplicate that exists only under test/',
    '$_spec FR-040, FR-072',
    'happy',
    {
      _scenario: _signals(
        _member('aSpan', 'srd5e.combat.a') + _member('bSpan', 'srd5e.combat.a'),
      ),
    },
    [],
  ),
  _c(
    'an empty repository',
    '$_spec FR-040',
    'unhappy (empty and minimal)',
    {},
    [],
  ),
];

void _cases(List<_Case> cases, List<Violation> Function(SourceSet) check) {
  /// Requirement: per case
  /// Path: per case
  for (final c in cases) {
    test('${c.label} [${c.path}]', () {
      expect(_where(check(SourceSet(c.files))), c.expected);
    });
  }
}

void main() {
  // Requirement: doc/specs/architecture-guardrails.md FR-036 - a srd5e. or
  //   reserved-key literal appears only in a constants file.
  // Path: per case
  group('FR-036 literals only in constants files', () {
    _cases(_fr036, checkSignalLiteralsOnlyInConstantsFiles);
  });

  // Requirement: doc/specs/architecture-guardrails.md FR-037 - a constants
  //   file holds plain static const String members of abstract final signals
  //   classes with kind suffixes.
  // Path: per case
  group('FR-037 signals class shape', () {
    _cases(_fr037, checkSignalsClassShape);
  });

  // Requirement: doc/specs/architecture-guardrails.md FR-038 - metric, span
  //   and log event values have the documented shape and context segment.
  // Path: per case
  group('FR-038 signal name shape', () {
    _cases(_fr038, checkSignalNameShape);
  });

  // Requirement: doc/specs/architecture-guardrails.md FR-039 - attribute
  //   constant values are srd5e.-prefixed lowercase dotted or reserved.
  // Path: per case
  group('FR-039 attribute name shape', () {
    _cases(_fr039, checkAttributeNameShape);
  });

  // Requirement: doc/specs/architecture-guardrails.md FR-040 - no two signal
  //   constants share a value.
  // Path: per case
  group('FR-040 signal values are unique', () {
    _cases(_fr040, checkSignalValuesUnique);
  });

  /// Requirement: doc/specs/architecture-guardrails.md FR-072 - FR-036 to
  ///   FR-040 scan lib/ only, so a test file may spell every literal and
  ///   declare any signals class.
  /// Path: happy
  test('FR-072: a file under test/ is never flagged by FR-036 to FR-040', () {
    final sources = SourceSet({
      _scenario:
          "final n = 'srd5e.combat.attack';\n"
          'abstract final class BadSignals {\n'
          "  static const String attack = 'srd5e.x';\n"
          "  static const String aSpan = 'Bad';\n"
          "  static const String bSpan = 'Bad';\n"
          "  static const String kindAttribute = 'kind';\n"
          '}\n'
          "const String top = 'x';\n",
    });

    for (final check in signalConstantsChecks.values) {
      expect(check(sources), isEmpty);
    }
  });

  /// Requirement: doc/specs/architecture-guardrails.md FR-005 - each check id
  ///   has a violating fixture that yields a Violation with that id.
  /// Path: unhappy (failure)
  group('FR-005 violating fixtures', () {
    for (final entry in signalConstantsViolatingFixtures.entries) {
      /// Requirement: doc/specs/architecture-guardrails.md FR-005
      /// Path: unhappy (failure)
      test('${entry.key} fixture yields its own id', () {
        final violations = signalConstantsChecks[entry.key]!(entry.value());

        expect(violations.map((v) => v.checkId), contains(entry.key));
      });
    }

    /// Requirement: doc/specs/architecture-guardrails.md FR-005
    /// Path: unhappy (failure)
    test('the checks and fixtures cover the same ids', () {
      expect(
        signalConstantsViolatingFixtures.keys.toSet(),
        signalConstantsChecks.keys.toSet(),
      );
    });
  });
}
