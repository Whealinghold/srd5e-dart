import 'package:test/test.dart';

import '../support/source_set.dart';
import '../support/violation.dart';
import 'use_case_calls.dart';

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

const String _fr097 = 'doc/specs/architecture-guardrails.md FR-097';

const String _resolve = 'lib/src/d20_test/application/resolve_d20_test.dart';
const String _poison = 'lib/src/toolbox/application/roll_poison.dart';
const String _apply = 'lib/src/combat/application/apply_damage.dart';
const String _heal = 'lib/src/combat/application/heal_damage.dart';
const String _helper = 'lib/src/combat/application/helper.dart';
const String _rules = 'lib/src/combat/domain/rules.dart';

/// A use case with a public `call` and the types around it.
const String _resolveSource = '''
class ResolveD20TestCommand {}

sealed class ResolveD20TestResult {}

class ResolveD20Test {
  ResolveD20TestResult call(ResolveD20TestCommand command) => throw 0;
}
''';

SourceSet _sources(Map<String, String> files) => SourceSet(files);

final List<_Case> _cases = [
  (
    label: 'toolbox use case mentions ResolveD20Test (the 4.5 row)',
    requirement: _fr097,
    path: 'unhappy (rule interaction)',
    files: {
      _resolve: _resolveSource,
      _poison: '''
import '../../d20_test/d20_test.dart';

class RollPoison {
  int call() => ResolveD20Test().call(ResolveD20TestCommand()).hashCode;
}
''',
    },
    expected: ['FR-097 $_poison:4'],
  ),
  (
    label: 'two use cases of one context, one mentioning the other',
    requirement: _fr097,
    path: 'unhappy (rule interaction)',
    files: {
      _apply: 'class ApplyDamage {\n  int call() => 1;\n}\n',
      _heal:
          'class HealDamage {\n  final ApplyDamage inner = ApplyDamage();\n  int call() => 2;\n}\n',
    },
    expected: ['FR-097 $_heal:2'],
  ),
  (
    label: 'a mention in an import show clause',
    requirement: _fr097,
    path: 'unhappy (rule interaction)',
    files: {
      _resolve: _resolveSource,
      _poison:
          "import '../../d20_test/d20_test.dart' show ResolveD20Test;\n"
          'class RollPoison {\n  int call() => 1;\n}\n',
    },
    expected: ['FR-097 $_poison:1'],
  ),
  (
    label: 'a domain file mentions a use case',
    requirement: _fr097,
    path: 'unhappy (rule interaction)',
    files: {
      _resolve: _resolveSource,
      _rules: 'int rule(Object o) => o is ResolveD20Test ? 1 : 0;\n',
    },
    expected: ['FR-097 $_rules:1'],
  ),
  (
    label: 'an application/ports file mentions a use case',
    requirement: _fr097,
    path: 'unhappy (boundary)',
    files: {
      _resolve: _resolveSource,
      'lib/src/combat/application/ports/clock.dart':
          'abstract interface class Clock {\n  ResolveD20Test now();\n}\n',
    },
    expected: ['FR-097 lib/src/combat/application/ports/clock.dart:2'],
  ),
  (
    label: 'a helper in application/ with a public call is a use case',
    requirement: _fr097,
    path: 'unhappy (rule interaction)',
    files: {
      _helper: 'class Helper {\n  int call(int x) => x;\n}\n',
      _apply: 'class ApplyDamage {\n  int call() => Helper().call(1);\n}\n',
    },
    expected: ['FR-097 $_apply:2'],
  ),
  (
    label: 'a generic call<T> and a get call count as a public call',
    requirement: _fr097,
    path: 'unhappy (boundary)',
    files: {
      'lib/src/combat/application/generic.dart':
          'class Generic {\n  R call<R>(R r) => r;\n}\n',
      'lib/src/combat/application/getter.dart':
          'class Getter {\n  int get call => 1;\n}\n',
      _apply:
          'class ApplyDamage {\n  int call() => 1;\n  Generic g;\n  Getter t;\n}\n',
    },
    expected: ['FR-097 $_apply:3', 'FR-097 $_apply:4'],
  ),
  (
    label: 'two mentions on two lines are two Violations, one line is one',
    requirement: _fr097,
    path: 'unhappy (multiple violations)',
    files: {
      _resolve: _resolveSource,
      _poison:
          'class RollPoison {\n'
          '  Object a = ResolveD20Test, b = ResolveD20Test;\n'
          '  Object c = ResolveD20Test;\n'
          '  int call() => 1;\n'
          '}\n',
    },
    expected: ['FR-097 $_poison:2', 'FR-097 $_poison:3'],
  ),
  (
    label: 'a use case mentions a domain service (the happy 4.5 row)',
    requirement: _fr097,
    path: 'happy',
    files: {
      'lib/src/d20_test/domain/d20_test_resolver.dart':
          'class D20TestResolver {\n  int call() => 1;\n}\n',
      _apply:
          "import '../../d20_test/d20_test.dart';\n"
          'class ApplyDamage {\n  int call() => D20TestResolver().call();\n}\n',
    },
    expected: [],
  ),
  (
    label: 'a use case mentions the Command and Result of another',
    requirement: _fr097,
    path: 'happy',
    files: {
      _resolve: _resolveSource,
      _poison:
          'class RollPoison {\n'
          '  ResolveD20TestResult? last;\n'
          '  ResolveD20TestCommand? first;\n'
          '  int call() => 1;\n'
          '}\n',
    },
    expected: [],
  ),
  (
    label: 'a use case mentioning itself',
    requirement: _fr097,
    path: 'happy',
    files: {
      _resolve:
          '$_resolveSource\nconst ResolveD20Test shared = ResolveD20Test();\n',
    },
    expected: [],
  ),
  (
    label: 'a mention in a comment, a doc comment or a string',
    requirement: 'doc/specs/architecture-guardrails.md FR-008, FR-097',
    path: 'unhappy (false positive)',
    files: {
      _resolve: _resolveSource,
      _poison: '''
// Does not call ResolveD20Test.
/// Unlike ResolveD20Test, this is its own use case.
/* ResolveD20Test */
class RollPoison {
  static const String name = 'ResolveD20Test';
  static const String raw = r'ResolveD20Test';
  int call() => 1;
}
''',
    },
    expected: [],
  ),
  (
    label: 'a mention inside string interpolation is code',
    requirement: 'doc/specs/architecture-guardrails.md FR-008, FR-097',
    path: 'unhappy (false positive)',
    files: {
      _resolve: _resolveSource,
      _poison:
          'class RollPoison {\n'
          "  String call() => 'x \${ResolveD20Test()}';\n"
          '}\n',
    },
    expected: ['FR-097 $_poison:2'],
  ),
  (
    label: 'a longer identifier that contains a use case name',
    requirement: _fr097,
    path: 'unhappy (false positive)',
    files: {
      _resolve: _resolveSource,
      _poison:
          'class RollPoison {\n'
          '  int myResolveD20Test = 1;\n'
          '  int ResolveD20Test2 = 2;\n'
          '  int call() => 1;\n'
          '}\n',
    },
    expected: [],
  ),
  (
    label: 'a mention in test/, in lib/src/testing/ and in an adapter',
    requirement: _fr097,
    path: 'unhappy (boundary)',
    files: {
      _resolve: _resolveSource,
      'test/combat/application/x_test.dart':
          'void main() { ResolveD20Test(); }\n',
      'lib/src/testing/fake.dart': 'Object f() => ResolveD20Test();\n',
      'lib/src/content/adapters/decoder.dart':
          'Object f() => ResolveD20Test();\n',
      'lib/src/shared_kernel/k.dart': 'Object f() => ResolveD20Test();\n',
    },
    expected: [],
  ),
  (
    label: 'a class with no public call is not a use case',
    requirement: _fr097,
    path: 'unhappy (boundary)',
    files: {
      _helper:
          'class Helper {\n'
          '  int _call() => 1;\n'
          '  int run(Helper other) => other.call() + this.call();\n'
          '  Helper.call();\n'
          '}\n',
      _apply:
          'class ApplyDamage {\n  Helper h = Helper();\n  int call() => 1;\n}\n',
    },
    expected: [],
  ),
  (
    label: 'a Signals class with a call member is not a use case',
    requirement: _fr097,
    path: 'unhappy (boundary)',
    files: {
      'lib/src/combat/application/combat_signals.dart':
          'abstract final class CombatSignals {\n  static int call() => 1;\n}\n',
      _apply:
          'class ApplyDamage {\n  Object s = CombatSignals;\n  int call() => 1;\n}\n',
    },
    expected: [],
  ),
  (
    label: 'a class under application/ports/ with a call is not a use case',
    requirement: _fr097,
    path: 'unhappy (boundary)',
    files: {
      'lib/src/combat/application/ports/clock.dart':
          'abstract interface class Clock {\n  int call();\n}\n',
      _apply: 'class ApplyDamage {\n  Clock? clock;\n  int call() => 1;\n}\n',
    },
    expected: [],
  ),
  (
    label: 'a source set with no use case at all',
    requirement: _fr097,
    path: 'unhappy (empty and minimal)',
    files: {'lib/srd5e.dart': '', _rules: 'class Rules {}\n'},
    expected: [],
  ),
  (
    label: 'an ignore comment does not suppress (FR-009)',
    requirement: 'doc/specs/architecture-guardrails.md FR-009, FR-097',
    path: 'unhappy (rule interaction)',
    files: {
      _resolve: _resolveSource,
      _poison:
          'class RollPoison {\n'
          '  // ignore: use_case_calls\n'
          '  Object o = ResolveD20Test;\n'
          '  int call() => 1;\n'
          '}\n',
    },
    expected: ['FR-097 $_poison:3'],
  ),
];

void main() {
  /// Requirement: per case
  /// Path: per case
  group('FR-097 use case calls', () {
    for (final c in _cases) {
      test('${c.label} [${c.path}] (${c.requirement})', () {
        expect(_where(checkNoUseCaseCalls(_sources(c.files))), c.expected);
      });
    }
  });

  /// Requirement: doc/specs/architecture-guardrails.md FR-097 - the use case
  ///   set is derived from the source: a class under application/ (not
  ///   ports/) with a public call member, other than a Signals class.
  /// Path: happy
  test('useCaseClasses derives the set from the source', () {
    final found = useCaseClasses(
      _sources({
        _resolve: _resolveSource,
        _helper: 'class Helper {\n  int call(int x) => x;\n}\nclass Plain {}\n',
        _rules: 'class Rules {\n  int call() => 1;\n}\n',
        'lib/src/combat/application/ports/clock.dart':
            'abstract interface class Clock {\n  int call();\n}\n',
        'lib/src/combat/application/combat_signals.dart':
            'abstract final class CombatSignals {\n  static int call() => 1;\n}\n',
      }),
    );

    expect(
      [for (final u in found) '${u.name} ${u.path}:${u.line}'],
      ['Helper $_helper:1', 'ResolveD20Test $_resolve:5'],
    );
  });

  /// Requirement: doc/specs/architecture-guardrails.md FR-097, FR-004 - the
  ///   detail names the use case, its declaring file and the way out.
  /// Path: unhappy (rule interaction)
  test('the detail names the mentioned use case and where it is declared', () {
    final found = checkNoUseCaseCalls(
      _sources({
        _resolve: _resolveSource,
        _poison: 'class RollPoison {\n  Object o = ResolveD20Test;\n}\n',
      }),
    );

    expect(found.single.detail, contains('`ResolveD20Test`'));
    expect(found.single.detail, contains(_resolve));
    expect(found.single.detail, contains('domain services'));
  });

  /// Requirement: doc/specs/architecture-guardrails.md FR-005 - each id has a
  ///   violating fixture on which its registered function yields that id.
  /// Path: unhappy (failure)
  group('registry wiring', () {
    for (final id in useCaseCallChecks.keys) {
      /// Requirement: doc/specs/architecture-guardrails.md FR-005 - the
      ///   fixture for the id yields a Violation with that id.
      /// Path: unhappy (failure)
      test('$id has a violating fixture', () {
        final fixture = useCaseCallViolatingFixtures[id];

        expect(fixture, isNotNull);
        final found = useCaseCallChecks[id]!(fixture!());
        expect(found.map((v) => v.checkId), contains(id));
      });
    }

    /// Requirement: doc/specs/architecture-guardrails.md FR-005 - fixtures and
    ///   functions cover the same ids.
    /// Path: unhappy (failure)
    test('fixtures and checks name the same ids', () {
      expect(
        useCaseCallViolatingFixtures.keys.toSet(),
        useCaseCallChecks.keys.toSet(),
      );
      expect(useCaseCallChecks.keys.toSet(), {'FR-097'});
    });
  });
}
