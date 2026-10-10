import 'package:test/test.dart';

import '../support/source_set.dart';
import '../support/violation.dart';
import 'error_conventions.dart';

const String _libFile = 'lib/src/shared_ports/dice_roller/fixture.dart';

const String _root = '''
import 'package:meta/meta.dart';

abstract base class Srd5eException implements Exception {
  @internal
  const Srd5eException({this.cause, this.causeStackTrace});
  final Object? cause;
  final StackTrace? causeStackTrace;
  String get errorType;
}
''';

const String _diceRollerException = '''
import '../errors/srd5e_exception.dart';

final class DiceRollerException extends Srd5eException {
  const DiceRollerException();
  @override
  String get errorType => 'dice_roller_exception';
}
''';

const String _diceRollerPath =
    'lib/src/shared_ports/dice_roller/dice_roller_exception.dart';

const String _registryPath =
    'test/architecture/support/exception_registry.dart';

const RegisteredSubtype _diceRollerRegistration = (
  className: 'DiceRollerException',
  errorType: 'dice_roller_exception',
);

SourceSet _sources(Map<String, String> files) => SourceSet(files);

/// `<check id> <path>:<line>` for each violation, in order.
List<String> _where(List<Violation> violations) => [
  for (final v in violations) '${v.checkId} ${v.path}:${v.line}',
];

typedef _Case = ({
  String label,
  String requirement,
  String path,
  String code,
  List<int> lines,
});

void main() {
  /// Requirement: doc/specs/errors-and-results.md FR-001, FR-002, FR-005,
  ///   FR-006, FR-049 and FR-050 - check E1 over the exception root and the
  ///   registry of subtypes (self-test: a violating and a clean fixture).
  /// Path: unhappy (invalid input)
  group('E1 checkExceptionRegistry', () {
    /// Requirement: doc/specs/errors-and-results.md FR-006 - a root with a
    ///   registered, final subtype is clean.
    /// Path: happy
    test('a correct root and a registered final subtype are clean', () {
      final sources = _sources({
        rootExceptionPath: _root,
        _diceRollerPath: _diceRollerException,
      });

      final violations = checkExceptionRegistry(sources, [
        _diceRollerRegistration,
      ]);

      expect(violations, isEmpty);
    });

    /// Requirement: doc/specs/errors-and-results.md FR-006 - code with no
    ///   `lib/src` file at all is vacuously clean (bootstrap).
    /// Path: unhappy (empty and minimal)
    test('a source set with no code under lib/src is clean', () {
      final sources = _sources({'lib/srd5e.dart': 'library;\n'});

      expect(checkExceptionRegistry(sources, const []), isEmpty);
    });

    /// Requirement: doc/specs/errors-and-results.md FR-006 - a subtype that
    ///   extends the root but is not in the registry is flagged at its
    ///   declaration.
    /// Path: unhappy (missing content)
    test('an unregistered subtype is flagged', () {
      final sources = _sources({
        rootExceptionPath: _root,
        _diceRollerPath: _diceRollerException,
      });

      final violations = checkExceptionRegistry(sources, const []);

      expect(_where(violations), ['E1 $_diceRollerPath:3']);
      expect(violations.single.detail, contains('DiceRollerException'));
    });

    /// Requirement: doc/specs/errors-and-results.md FR-002 - a concrete
    ///   subtype must be `final`.
    /// Path: unhappy (invalid input)
    test('a subtype that is not final is flagged', () {
      final sources = _sources({
        rootExceptionPath: _root,
        _diceRollerPath: _diceRollerException.replaceFirst(
          'final class',
          'base class',
        ),
      });

      final violations = checkExceptionRegistry(sources, [
        _diceRollerRegistration,
      ]);

      expect(_where(violations), ['E1 $_diceRollerPath:3']);
      expect(violations.single.detail, contains('final class'));
    });

    /// Requirement: doc/specs/errors-and-results.md FR-001 and FR-049 - a
    ///   `sealed` root is flagged.
    /// Path: unhappy (invalid input)
    test('a sealed root is flagged', () {
      final sources = _sources({
        rootExceptionPath: _root.replaceFirst(
          'abstract base class',
          'sealed class',
        ),
      });

      final violations = checkExceptionRegistry(sources, const []);

      expect(_where(violations), ['E1 $rootExceptionPath:3']);
    });

    /// Requirement: doc/specs/errors-and-results.md FR-001 - a root that is
    ///   abstract but not `base` is flagged.
    /// Path: unhappy (invalid input)
    test('a root that is not base is flagged', () {
      final sources = _sources({
        rootExceptionPath: _root.replaceFirst(
          'abstract base class',
          'abstract class',
        ),
      });

      final violations = checkExceptionRegistry(sources, const []);

      expect(_where(violations), ['E1 $rootExceptionPath:3']);
    });

    /// Requirement: doc/specs/errors-and-results.md FR-050 - a root
    ///   constructor without `@internal` is flagged.
    /// Path: unhappy (invalid input)
    test('a root constructor without @internal is flagged', () {
      final sources = _sources({
        rootExceptionPath: _root.replaceFirst('  @internal\n', ''),
      });

      final violations = checkExceptionRegistry(sources, const []);

      expect(_where(violations), ['E1 $rootExceptionPath:3']);
      expect(violations.single.detail, contains('@internal'));
    });

    /// Requirement: doc/specs/errors-and-results.md FR-001 - code under
    ///   `lib/src` with no root declaration is flagged.
    /// Path: unhappy (missing content)
    test('a missing root declaration is flagged', () {
      final sources = _sources({_libFile: 'class Unrelated {}\n'});

      final violations = checkExceptionRegistry(sources, const []);

      expect(_where(violations), ['E1 $rootExceptionPath:1']);
    });

    /// Requirement: doc/specs/errors-and-results.md FR-006 - a registry entry
    ///   for a class that does not exist is flagged.
    /// Path: unhappy (state error)
    test('a stale registry entry is flagged', () {
      final sources = _sources({rootExceptionPath: _root});

      final violations = checkExceptionRegistry(sources, [
        _diceRollerRegistration,
      ]);

      expect(_where(violations), ['E1 $_registryPath:1']);
      expect(violations.single.detail, contains('DiceRollerException'));
    });

    /// Requirement: doc/specs/errors-and-results.md FR-005 - an errorType that
    ///   is not the snake_case of the class name is flagged.
    /// Path: unhappy (boundary)
    test('an errorType that is not the snake_case of the class is flagged', () {
      final sources = _sources({
        rootExceptionPath: _root,
        _diceRollerPath: _diceRollerException,
      });

      final violations = checkExceptionRegistry(sources, [
        (className: 'DiceRollerException', errorType: 'dice_roller'),
      ]);

      expect(_where(violations), ['E1 $_registryPath:1']);
      expect(violations.single.detail, contains('dice_roller_exception'));
    });

    /// Requirement: doc/specs/errors-and-results.md FR-006 - two registry
    ///   entries with the same errorType are flagged.
    /// Path: unhappy (rule interaction)
    test('duplicate errorType values are flagged', () {
      final sources = _sources({
        rootExceptionPath: _root,
        _diceRollerPath: _diceRollerException,
        'lib/src/shared_ports/dice_roller/other.dart': _diceRollerException
            .replaceAll('DiceRoller', 'Other')
            .replaceAll('dice_roller', 'other'),
      });

      final violations = checkExceptionRegistry(sources, [
        _diceRollerRegistration,
        (className: 'OtherException', errorType: 'dice_roller_exception'),
      ]);

      expect(violations.map((v) => v.detail), [
        contains('share the errorType'),
        contains('expected "other_exception"'),
      ]);
    });

    /// Requirement: doc/specs/errors-and-results.md FR-006 - a class
    ///   declaration inside a comment or string is not a subtype.
    /// Path: unhappy (false positive)
    test('a subtype mentioned in a comment or string is ignored', () {
      final sources = _sources({
        rootExceptionPath: _root,
        _libFile: '''
// final class Ghost extends Srd5eException {}
const s = 'final class Ghost2 extends Srd5eException {}';
''',
      });

      expect(checkExceptionRegistry(sources, const []), isEmpty);
    });
  });

  /// Requirement: doc/specs/errors-and-results.md FR-007 and FR-020 - check E2,
  ///   no display-text member on a failure, result, rejection or problem type.
  /// Path: unhappy (invalid input)
  group('E2 checkNoDisplayText', () {
    // Requirement: per case
    // Path: per case
    final cases = <_Case>[
      (
        label: 'an exception subtype with a message field',
        requirement:
            'doc/specs/errors-and-results.md FR-007 - no message field on a '
            'subtype',
        path: 'unhappy (invalid input)',
        code: '''
final class DiceRollerException extends Srd5eException {
  const DiceRollerException(this.message);
  final String message;
}
''',
        lines: [3],
      ),
      (
        label: 'an exception subtype with a description getter',
        requirement:
            'doc/specs/errors-and-results.md FR-007 - no description getter',
        path: 'unhappy (invalid input)',
        code: '''
final class DiceRollerException extends Srd5eException {
  const DiceRollerException();
  String get description => 'x';
}
''',
        lines: [3],
      ),
      (
        label: 'a sealed result variant with a text field',
        requirement:
            'doc/specs/errors-and-results.md FR-020 - no text field on a '
            'result variant',
        path: 'unhappy (invalid input)',
        code: '''
sealed class DamageResult {}

final class DamageRejected extends DamageResult {
  const DamageRejected(this.text);
  final String text;
}
''',
        lines: [5],
      ),
      (
        label: 'a sealed result itself with a displayText getter',
        requirement:
            'doc/specs/errors-and-results.md FR-020 - no displayText on the '
            'sealed class',
        path: 'unhappy (invalid input)',
        code: '''
sealed class DamageResult {
  String get displayText;
}
''',
        lines: [2],
      ),
      (
        label: 'a rejection enum with a displayText getter',
        requirement:
            'doc/specs/errors-and-results.md FR-020 - no displayText on a '
            'rejection type',
        path: 'unhappy (invalid input)',
        code: '''
enum DieRejection {
  tooFew(1);

  const DieRejection(this.value);
  final int value;
  String get displayText => 'x';
}
''',
        lines: [6],
      ),
      (
        label: 'a problem class with a message field',
        requirement:
            'doc/specs/errors-and-results.md FR-020 - no message on a '
            'problem type',
        path: 'unhappy (invalid input)',
        code: '''
final class ContentProblem {
  const ContentProblem(this.path, this.message);
  final String path;
  final String message;
}
''',
        lines: [4],
      ),
      (
        label: 'a path field and typed data',
        requirement:
            'doc/specs/errors-and-results.md FR-007 - a path-like String '
            'field is allowed (by name)',
        path: 'happy',
        code: '''
final class DiceRollerException extends Srd5eException {
  const DiceRollerException(this.path, this.reason);
  final String path;
  final int reason;
}
''',
        lines: [],
      ),
      (
        label: 'a plain class that is not a failure or result',
        requirement:
            'doc/specs/errors-and-results.md FR-020 - the rule is limited to '
            'failure, result, rejection and problem types',
        path: 'unhappy (false positive)',
        code: '''
final class Greeting {
  const Greeting(this.message);
  final String message;
}
''',
        lines: [],
      ),
      (
        label: 'an enum constant named text',
        requirement:
            'doc/specs/errors-and-results.md FR-020 - an enum constant is not '
            'a field',
        path: 'unhappy (false positive)',
        code: '''
enum DieRejection {
  text,
  message,
}
''',
        lines: [],
      ),
      (
        label: 'the member name only in a comment',
        requirement:
            'doc/specs/errors-and-results.md FR-007 - comments never trigger a '
            'check',
        path: 'unhappy (false positive)',
        code: '''
final class DiceRollerException extends Srd5eException {
  const DiceRollerException();
  // final String message;
}
''',
        lines: [],
      ),
    ];

    for (final c in cases) {
      test('${c.label} [${c.path}]', () {
        final sources = _sources({_libFile: c.code});

        final violations = checkNoDisplayText(sources);

        expect(_where(violations), [
          for (final l in c.lines) 'E2 $_libFile:$l',
        ]);
      });
    }

    /// Requirement: doc/specs/errors-and-results.md FR-020 - the content
    ///   domain (verbatim SRD text) and telemetry descriptor classes are
    ///   exempt by declaration site.
    /// Path: unhappy (false positive)
    test('content value objects and telemetry descriptors are exempt', () {
      final sources = _sources({
        'lib/src/content/domain/spell.dart': '''
sealed class SpellResult {}

final class SpellFound extends SpellResult {
  const SpellFound(this.description);
  final String description;
}
''',
        'lib/src/shared_ports/observability/meter.dart': '''
final class MeterProblem {
  const MeterProblem(this.description);
  final String description;
}
''',
      });

      expect(checkNoDisplayText(sources), isEmpty);
    });

    /// Requirement: doc/specs/errors-and-results.md FR-020 - the same member
    ///   outside the exempt sites is flagged.
    /// Path: unhappy (invalid input)
    test('the same member outside an exempt site is flagged', () {
      final sources = _sources({
        'lib/src/combat/application/meter.dart': '''
final class MeterProblem {
  const MeterProblem(this.description);
  final String description;
}
''',
      });

      expect(_where(checkNoDisplayText(sources)), [
        'E2 lib/src/combat/application/meter.dart:3',
      ]);
    });

    /// Requirement: doc/specs/errors-and-results.md FR-007 - an exception
    ///   subtype is scanned even under an exempt prefix.
    /// Path: unhappy (rule interaction)
    test('an exception subtype is scanned under an exempt prefix', () {
      final sources = _sources({
        'lib/src/shared_ports/observability/failure.dart': '''
final class TracerException extends Srd5eException {
  const TracerException(this.message);
  final String message;
}
''',
      });

      expect(_where(checkNoDisplayText(sources)), [
        'E2 lib/src/shared_ports/observability/failure.dart:3',
      ]);
    });

    /// Requirement: doc/specs/errors-and-results.md FR-007 - a subtype of a
    ///   subtype is also covered.
    /// Path: unhappy (rule interaction)
    test('a class that extends a known subtype is covered', () {
      final sources = _sources({
        _libFile: '''
base class MiddleException extends Srd5eException {}

final class LeafException extends MiddleException {
  final String text = '';
}
''',
      });

      expect(_where(checkNoDisplayText(sources)), ['E2 $_libFile:4']);
    });
  });

  /// Requirement: doc/specs/errors-and-results.md FR-029 - check E3, no domain
  ///   file names the exception root, a subtype or a guard.
  /// Path: unhappy (invalid input)
  group('E3 checkDomainDoesNotUseErrors', () {
    /// Requirement: doc/specs/errors-and-results.md FR-029 - the root, a
    ///   declared subtype and both guards are flagged in a domain file.
    /// Path: unhappy (invalid input)
    test('naming the root, a subtype or a guard in domain code is flagged', () {
      final sources = _sources({
        _diceRollerPath: _diceRollerException,
        'lib/src/combat/domain/damage.dart': '''
bool f(Object e) {
  if (e is Srd5eException) return true;
  if (e is DiceRollerException) return true;
  wrapPortFailure(() => 1, (c, s) => throw c);
  wrapPortFailureAsync(() async => 1, (c, s) => throw c);
  return false;
}
''',
      });

      final violations = checkDomainDoesNotUseErrors(sources);

      expect(_where(violations), [
        'E3 lib/src/combat/domain/damage.dart:2',
        'E3 lib/src/combat/domain/damage.dart:3',
        'E3 lib/src/combat/domain/damage.dart:4',
        'E3 lib/src/combat/domain/damage.dart:5',
      ]);
    });

    /// Requirement: doc/specs/errors-and-results.md FR-029 - comments, strings
    ///   and non-domain files do not trigger the check.
    /// Path: unhappy (false positive)
    test('comments, strings and application code are clean', () {
      final sources = _sources({
        'lib/src/combat/domain/damage.dart': '''
// Srd5eException is thrown by ports, never here.
const s = 'wrapPortFailure';
''',
        'lib/src/combat/application/apply.dart': '''
bool g(Object e) => e is Srd5eException;
''',
      });

      expect(checkDomainDoesNotUseErrors(sources), isEmpty);
    });
  });

  /// Requirement: per case
  /// Path: per case
  group('E4 checkCatchClauses', () {
    String wrap(String clauses) =>
        'void f() {\n  try {\n    g();\n  } $clauses\n}\n';

    final cases = <_Case>[
      (
        label: 'on a FormatException',
        requirement:
            'doc/specs/errors-and-results.md FR-046 - an on type matching '
            r'\w*Exception is allowed',
        path: 'happy',
        code: wrap('on FormatException catch (e) {\n    h(e);\n  }'),
        lines: [],
      ),
      (
        label: 'on Exception',
        requirement:
            'doc/specs/errors-and-results.md FR-046 - on Exception is allowed',
        path: 'happy',
        code: wrap('on Exception catch (e, s) {\n    h(e, s);\n  }'),
        lines: [],
      ),
      (
        label: 'on Srd5eException without catch',
        requirement:
            'doc/specs/errors-and-results.md FR-046 - an on clause without '
            'catch is a clause',
        path: 'happy',
        code: wrap('on Srd5eException {\n    rethrow;\n  }'),
        lines: [],
      ),
      (
        label: 'a qualified exception type',
        requirement:
            'doc/specs/errors-and-results.md FR-046 - a prefixed exception '
            'type is allowed',
        path: 'happy',
        code: wrap('on async.TimeoutException catch (e) {\n    h(e);\n  }'),
        lines: [],
      ),
      (
        label: 'on Object ending in rethrow',
        requirement:
            'doc/specs/errors-and-results.md FR-047 - a record-and-rethrow '
            'clause may catch Object',
        path: 'happy',
        code: wrap(
          'on Object catch (e, s) {\n    record(e, s);\n    rethrow;\n  }',
        ),
        lines: [],
      ),
      (
        label: 'on Error ending in rethrow',
        requirement:
            'doc/specs/errors-and-results.md FR-047 - a record-and-rethrow '
            'clause may catch Error',
        path: 'happy',
        code: wrap('on Error catch (e) {\n    record(e);\n    rethrow;\n  }'),
        lines: [],
      ),
      (
        label: 'a bare catch ending in rethrow',
        requirement:
            'doc/specs/errors-and-results.md FR-047 - a bare catch that only '
            'records and rethrows is accepted',
        path: 'happy',
        code: wrap('catch (e) {\n    record(e);\n    rethrow;\n  }'),
        lines: [],
      ),
      (
        label: 'try with only finally',
        requirement:
            'doc/specs/errors-and-results.md FR-046 - finally is not a catch '
            'clause',
        path: 'happy',
        code:
            'void f() {\n  try {\n    g();\n  } finally {\n    h();\n  }\n}\n',
        lines: [],
      ),
      (
        label: 'on Error that swallows',
        requirement:
            'doc/specs/errors-and-results.md FR-030 - catching Error is '
            'forbidden',
        path: 'unhappy (invalid input)',
        code: wrap('on Error catch (e) {\n    log(e);\n  }'),
        lines: [4],
      ),
      (
        label: 'a bare catch that swallows',
        requirement:
            'doc/specs/errors-and-results.md FR-030 - a bare catch is '
            'forbidden',
        path: 'unhappy (invalid input)',
        code: wrap('catch (e) {\n    log(e);\n  }'),
        lines: [4],
      ),
      (
        label: 'on Object with a statement after rethrow',
        requirement:
            'doc/specs/errors-and-results.md FR-047 - rethrow must be the '
            'last statement',
        path: 'unhappy (boundary)',
        code: wrap('on Object catch (e) {\n    rethrow;\n    log(e);\n  }'),
        lines: [4],
      ),
      (
        label: 'on Object ending in return',
        requirement:
            'doc/specs/errors-and-results.md FR-047 - a clause ending in '
            'return is not the exemption',
        path: 'unhappy (boundary)',
        code: wrap('on Object catch (e) {\n    record(e);\n    return;\n  }'),
        lines: [4],
      ),
      (
        label: 'on Object with a conditional rethrow',
        requirement:
            'doc/specs/errors-and-results.md FR-047 - a rethrow must be '
            'unconditional',
        path: 'unhappy (boundary)',
        code: wrap('on Object catch (e) {\n    if (x) rethrow;\n  }'),
        lines: [4],
      ),
      (
        label: 'on dynamic',
        requirement:
            'doc/specs/errors-and-results.md FR-030 - on dynamic is '
            'forbidden',
        path: 'unhappy (invalid input)',
        code: wrap('on dynamic catch (e) {\n    log(e);\n  }'),
        lines: [4],
      ),
      (
        label: 'a second clause that catches Error',
        requirement:
            'doc/specs/errors-and-results.md FR-030 - every clause of a try '
            'is checked',
        path: 'unhappy (rule interaction)',
        code: wrap(
          'on FormatException {\n    h();\n  } on Error catch (e) {\n    h();\n  }',
        ),
        lines: [6],
      ),
      (
        label: 'catch only in comments and strings',
        requirement:
            'doc/specs/errors-and-results.md FR-030 - comments and strings '
            'never trigger a check',
        path: 'unhappy (false positive)',
        code:
            "void f() {\n  // try { } catch (e) { }\n  const s = 'try { } catch (e) { }';\n}\n",
        lines: [],
      ),
    ];

    /// Requirement: per case
    /// Path: per case
    for (final c in cases) {
      test('${c.label} [${c.path}]', () {
        final sources = _sources({_libFile: c.code});

        final violations = checkCatchClauses(sources);

        expect(_where(violations), [
          for (final l in c.lines) 'E4 $_libFile:$l',
        ]);
      });
    }
  });

  /// Requirement: doc/specs/errors-and-results.md FR-034 - check E5, error.type
  ///   comes only from the errorType getter.
  /// Path: unhappy (invalid input)
  group('E5 checkErrorTypeAttribute', () {
    const application = 'lib/src/d20_test/application/resolve.dart';

    /// Requirement: doc/specs/errors-and-results.md FR-034 - an attribute
    ///   map that reads `.errorType` is clean, including with neighbours.
    /// Path: happy
    test('error.type set from the errorType getter is clean', () {
      final sources = _sources({
        application: '''
final attributes = {
  AttributeKeys.outcome: 'failure',
  AttributeKeys.errorType: e.errorType,
  AttributeKeys.other: 'x',
};
''',
      });

      expect(checkErrorTypeAttribute(sources), isEmpty);
    });

    /// Requirement: doc/specs/errors-and-results.md FR-034 - runtimeType or a
    ///   literal as the value is flagged at the assignment.
    /// Path: unhappy (invalid input)
    test('error.type set from anything else is flagged', () {
      final sources = _sources({
        application: '''
final a = {AttributeKeys.errorType: e.runtimeType.toString()};
final b = {AttributeKeys.errorType: 'dice_roller_exception'};
final c = {AttributeKeys.errorType: describe(e)};
''',
      });

      expect(_where(checkErrorTypeAttribute(sources)), [
        'E5 $application:1',
        'E5 $application:1',
        'E5 $application:1',
        'E5 $application:2',
        'E5 $application:3',
      ]);
    });

    /// Requirement: doc/specs/errors-and-results.md FR-034 - runtimeType and
    ///   toString( are banned in an application file that sets error.type.
    /// Path: unhappy (invalid input)
    test('runtimeType and toString are banned beside error.type', () {
      final sources = _sources({
        application: '''
void f(Object e) {
  final a = {AttributeKeys.errorType: e.errorType};
  final name = e.runtimeType;
  final text = e.toString();
}
''',
      });

      expect(_where(checkErrorTypeAttribute(sources)), [
        'E5 $application:3',
        'E5 $application:4',
      ]);
    });

    /// Requirement: doc/specs/errors-and-results.md FR-034 - an application
    ///   file that does not mention the key may use runtimeType.
    /// Path: unhappy (false positive)
    test('a file that never sets error.type may use runtimeType', () {
      final sources = _sources({
        application: 'String f(Object e) => e.runtimeType.toString();\n',
      });

      expect(checkErrorTypeAttribute(sources), isEmpty);
    });
  });

  /// Requirement: doc/specs/errors-and-results.md FR-018 and FR-044 - check E6,
  ///   direct subtypes of a sealed class are final or sealed.
  /// Path: unhappy (invalid input)
  group('E6 checkSealedSubtypes', () {
    /// Requirement: doc/specs/errors-and-results.md FR-018 - final and sealed
    ///   direct subtypes (and an enum) are clean.
    /// Path: happy
    test('final, sealed and enum subtypes are clean', () {
      final sources = _sources({
        'lib/src/combat/application/result.dart': '''
sealed class DamageResult {}

final class DamageApplied extends DamageResult {}

sealed class DamageFailed extends DamageResult {}

final class DamageBlocked extends DamageFailed {}

enum DamageKind implements DamageResult { a }
''',
      });

      expect(checkSealedSubtypes(sources), isEmpty);
    });

    /// Requirement: doc/specs/errors-and-results.md FR-044 - a non-final
    ///   direct subtype, in any file, is flagged at its declaration.
    /// Path: unhappy (invalid input)
    test('a non-final direct subtype is flagged', () {
      final sources = _sources({
        'lib/src/combat/application/result.dart': '''
sealed class DamageResult {}
''',
        'lib/src/combat/application/variants.dart': '''
class DamageApplied extends DamageResult {}

base class DamageRejected implements DamageResult {}

abstract final class DamageBlocked extends DamageResult {}
''',
      });

      expect(_where(checkSealedSubtypes(sources)), [
        'E6 lib/src/combat/application/variants.dart:1',
        'E6 lib/src/combat/application/variants.dart:3',
      ]);
    });

    /// Requirement: doc/specs/errors-and-results.md FR-044 - a class that is
    ///   only mentioned in a comment is not a subtype; a non-sealed parent is
    ///   not constrained.
    /// Path: unhappy (false positive)
    test('comments and non-sealed parents are ignored', () {
      final sources = _sources({
        _libFile: '''
abstract class Plain {}

class Child extends Plain {}

// class Ghost extends DamageResult {}
''',
      });

      expect(checkSealedSubtypes(sources), isEmpty);
    });
  });

  /// Requirement: doc/specs/errors-and-results.md FR-048 - check E7, no
  ///   catchError, onError or runZonedGuarded under lib/.
  /// Path: unhappy (invalid input)
  group('E7 checkNoCatchBypass', () {
    /// Requirement: doc/specs/errors-and-results.md FR-048 - each banned token
    ///   is flagged.
    /// Path: unhappy (invalid input)
    test('each bypass token is flagged', () {
      final sources = _sources({
        _libFile: '''
void f(Future<int> a) {
  a.catchError((Object e) => 1);
  a.then((v) => v, onError: (Object e) => 2);
  runZonedGuarded(() {}, (e, s) {});
}
''',
      });

      expect(_where(checkNoCatchBypass(sources)), [
        'E7 $_libFile:2',
        'E7 $_libFile:3',
        'E7 $_libFile:4',
      ]);
    });

    /// Requirement: doc/specs/errors-and-results.md FR-048 - similar
    ///   identifiers, comments and strings are clean.
    /// Path: unhappy (false positive)
    test('longer identifiers, comments and strings are clean', () {
      final sources = _sources({
        _libFile: '''
// catchError is banned.
const s = 'runZonedGuarded onError';
void catchErrorLater() {}
final onErrorHandler = 1;
''',
      });

      expect(checkNoCatchBypass(sources), isEmpty);
    });
  });

  /// Requirement: per case
  /// Path: per case
  group('E8 checkSyncGuardIsSync', () {
    final cases = <_Case>[
      (
        label: 'a synchronous closure',
        requirement:
            'doc/specs/errors-and-results.md FR-052 - a sync body is the '
            'intended use',
        path: 'happy',
        code: 'int f() => wrapPortFailure(() => g(), wrap);\n',
        lines: [],
      ),
      (
        label: 'wrapPortFailureAsync with an async closure',
        requirement:
            'doc/specs/errors-and-results.md FR-052 - the async guard takes '
            'an async body',
        path: 'happy',
        code:
            'Future<int> f() => wrapPortFailureAsync(() async => g(), wrap);\n',
        lines: [],
      ),
      (
        label: 'an async closure',
        requirement:
            'doc/specs/errors-and-results.md FR-052 - an async closure is '
            'flagged',
        path: 'unhappy (rule interaction)',
        code: 'Object f() => wrapPortFailure(() async => g(), wrap);\n',
        lines: [1],
      ),
      (
        label: 'an await inside the closure',
        requirement:
            'doc/specs/errors-and-results.md FR-052 - an await inside is '
            'flagged',
        path: 'unhappy (rule interaction)',
        code:
            'Object f() {\n  return wrapPortFailure(\n    () => await g(),\n    wrap,\n  );\n}\n',
        lines: [2],
      ),
      (
        label: 'a Future type argument',
        requirement:
            'doc/specs/errors-and-results.md FR-052 - a Future<...> type '
            'argument is flagged',
        path: 'unhappy (rule interaction)',
        code: 'Object f() => wrapPortFailure<Future<int>>(() => g(), wrap);\n',
        lines: [1],
      ),
      (
        label: 'the declaration of the guard itself',
        requirement:
            'doc/specs/errors-and-results.md FR-052 - a declaration is not '
            'a call',
        path: 'unhappy (false positive)',
        code:
            'T wrapPortFailure<T>(\n  T Function() body,\n  Srd5eException Function(Object c, StackTrace s) wrap,\n) {\n  return body();\n}\n',
        lines: [],
      ),
      (
        label: 'a call only in a comment or string',
        requirement:
            'doc/specs/errors-and-results.md FR-052 - comments and strings '
            'never trigger a check',
        path: 'unhappy (false positive)',
        code:
            "// wrapPortFailure(() async => 1, wrap)\nconst s = 'wrapPortFailure(() async => 1, wrap)';\n",
        lines: [],
      ),
    ];

    /// Requirement: per case
    /// Path: per case
    for (final c in cases) {
      test('${c.label} [${c.path}]', () {
        final sources = _sources({_libFile: c.code});

        final violations = checkSyncGuardIsSync(sources);

        expect(_where(violations), [
          for (final l in c.lines) 'E8 $_libFile:$l',
        ]);
      });
    }
  });

  /// Requirement: doc/specs/errors-and-results.md FR-053 - the spec-set scan:
  ///   a use-case spec's test plan has a row for FR-031, FR-034 and FR-051 or
  ///   states that it calls no port.
  /// Path: unhappy (rule interaction)
  group('FR-053 checkUseCaseSpecRows', () {
    String spec({required String observability, required String testPlan}) =>
        '''
# Fixture

## 7. Observability

$observability

## 8. Test plan

$testPlan

## 9. Open questions and decisions
''';

    const spanRow = '| `srd5e.combat.apply` | span | attributes |';
    const fullPlan =
        '| FR-031 | application | errors-and-results.md FR-031, FR-034 and FR-051 |';

    /// Requirement: doc/specs/errors-and-results.md FR-053 - a use-case spec
    ///   with a row citing all three ids is clean.
    /// Path: happy
    test('a spec with all three rows is clean', () {
      final sources = _sources({
        'doc/specs/uses-ports.md': spec(
          observability: spanRow,
          testPlan: fullPlan,
        ),
      });

      expect(checkUseCaseSpecRows(sources), isEmpty);
    });

    /// Requirement: doc/specs/errors-and-results.md FR-053 - a use-case spec
    ///   with no matching row is flagged once per missing id, at the test plan
    ///   heading.
    /// Path: unhappy (missing content)
    test('a spec missing the rows is flagged per id', () {
      final sources = _sources({
        'doc/specs/uses-ports.md': spec(
          observability: spanRow,
          testPlan: '| FR-001 | unit | something |',
        ),
      });

      final violations = checkUseCaseSpecRows(sources);

      expect(
        _where(violations),
        List.filled(3, 'FR-053 doc/specs/uses-ports.md:7'),
      );
      expect(violations.map((v) => v.detail), [
        contains('FR-031'),
        contains('FR-034'),
        contains('FR-051'),
      ]);
    });

    /// Requirement: doc/specs/errors-and-results.md FR-053 - only the missing
    ///   id is flagged when two of three are cited.
    /// Path: unhappy (boundary)
    test('only the missing id is flagged', () {
      final sources = _sources({
        'doc/specs/uses-ports.md': spec(
          observability: spanRow,
          testPlan: '| FR-031, FR-051 | application | errors-and-results.md |',
        ),
      });

      expect(checkUseCaseSpecRows(sources).map((v) => v.detail), [
        contains('FR-034'),
      ]);
    });

    /// Requirement: doc/specs/errors-and-results.md FR-053 - a spec that
    ///   states the use case calls no port is clean.
    /// Path: unhappy (empty and minimal)
    test('a spec that states it calls no port is clean', () {
      final sources = _sources({
        'doc/specs/no-ports.md': spec(
          observability: spanRow,
          testPlan: 'The encounter calls no port, so none of these apply.',
        ),
      });

      expect(checkUseCaseSpecRows(sources), isEmpty);
    });

    /// Requirement: doc/specs/errors-and-results.md FR-053 - a spec that
    ///   defines no span, and the template, are not scanned.
    /// Path: unhappy (false positive)
    test('a spec without a span and the template are skipped', () {
      final sources = _sources({
        'doc/specs/no-span.md': spec(
          observability: 'Silent by design.',
          testPlan: '| FR-001 | unit | something |',
        ),
        'doc/specs/_template.md': spec(
          observability: spanRow,
          testPlan: '| FR-001 | unit | something |',
        ),
      });

      expect(checkUseCaseSpecRows(sources), isEmpty);
    });
  });
}
