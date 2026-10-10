import 'dart:io';

import 'package:srd5e/src/shared_ports/errors/srd5e_exception.dart';
import 'package:test/test.dart';

import '../support/exception_registry.dart';
import '../support/names.dart';
import '../support/package_root.dart';
import '../support/real_repository.dart';
import '../support/source_set.dart';
import '../support/use_case_spec_baseline.dart';
import '../support/violation.dart';
import 'error_conventions.dart';

/// The repository, loaded once per test file and never mutated.
final SourceSet _repository = realRepository;

const Timeout _budget = Timeout(Duration(seconds: 10));

/// The registry as plain data for check E1.
List<RegisteredSubtype> get _registry => [
  for (final entry in registeredExceptions)
    (className: entry.className, errorType: entry.errorType),
];

void _expectNone(List<Violation> violations) {
  expect(violations, isEmpty, reason: '\n${formatViolations(violations)}');
}

/// Reads the `error.type` table of section 7 of the errors spec as
/// `subtype -> error.type value`.
Map<String, String> _specErrorTypes() {
  final text = File(
    '${findPackageRoot().path}/doc/specs/errors-and-results.md',
  ).readAsStringSync();
  final section = text.substring(text.indexOf('## 7. Observability'));
  final end = section.indexOf('## 8. ');
  final result = <String, String>{};
  for (final match in RegExp(
    r'^\| `([a-z][a-z0-9_]*)` \| `(\w+)` \|',
    multiLine: true,
  ).allMatches(section.substring(0, end))) {
    result[match.group(2)!] = match.group(1)!;
  }
  return result;
}

void main() {
  /// Requirement: doc/specs/architecture-guardrails.md FR-012 - the suite must
  ///   fail when the package root is wrong, so no check passes vacuously.
  /// Path: unhappy (empty and minimal)
  test('the loaded repository is the srd5e package', () {
    expect(_repository.files.containsKey('lib/srd5e.dart'), isTrue);
    expect(_repository.files.containsKey('pubspec.yaml'), isTrue);
    expect(
      _repository.files.containsKey(rootExceptionPath),
      isTrue,
      reason: 'the root exception file is where FR-055 of the decisions says',
    );
    expect(_repository.unreadable, isEmpty);
  }, timeout: _budget);

  /// Requirement: doc/specs/errors-and-results.md FR-001, FR-006, FR-049 and
  ///   FR-050 - E1 on the real repository.
  /// Path: happy
  test(
    'E1: the root and every subtype follow the exception rules',
    () => _expectNone(checkExceptionRegistry(_repository, _registry)),
    timeout: _budget,
  );

  /// Requirement: doc/specs/errors-and-results.md FR-007 and FR-020 - E2 on
  ///   the real repository.
  /// Path: happy
  test(
    'E2: no display-text member on a failure or result type',
    () => _expectNone(checkNoDisplayText(_repository)),
    timeout: _budget,
  );

  /// Requirement: doc/specs/errors-and-results.md FR-029 - E3 on the real
  ///   repository.
  /// Path: happy
  test(
    'E3: domain code does not name the exception root or the guards',
    () => _expectNone(checkDomainDoesNotUseErrors(_repository)),
    timeout: _budget,
  );

  /// Requirement: doc/specs/errors-and-results.md FR-030, FR-046 and FR-047 -
  ///   E4 on the real repository.
  /// Path: happy
  test(
    'E4: every catch clause has an Exception type or ends in rethrow',
    () => _expectNone(checkCatchClauses(_repository)),
    timeout: _budget,
  );

  /// Requirement: doc/specs/errors-and-results.md FR-034 - E5 on the real
  ///   repository.
  /// Path: happy
  test(
    'E5: error.type is set from the errorType getter only',
    () => _expectNone(checkErrorTypeAttribute(_repository)),
    timeout: _budget,
  );

  /// Requirement: doc/specs/errors-and-results.md FR-018 and FR-044 - E6 on
  ///   the real repository.
  /// Path: happy
  test(
    'E6: sealed classes have only final or sealed direct subtypes',
    () => _expectNone(checkSealedSubtypes(_repository)),
    timeout: _budget,
  );

  /// Requirement: doc/specs/errors-and-results.md FR-048 - E7 on the real
  ///   repository.
  /// Path: happy
  test(
    'E7: no catchError, onError or runZonedGuarded under lib',
    () => _expectNone(checkNoCatchBypass(_repository)),
    timeout: _budget,
  );

  /// Requirement: doc/specs/errors-and-results.md FR-052 - E8 on the real
  ///   repository.
  /// Path: happy
  test(
    'E8: wrapPortFailure is never given a Future-returning body',
    () => _expectNone(checkSyncGuardIsSync(_repository)),
    timeout: _budget,
  );

  /// Requirement: doc/specs/errors-and-results.md FR-053 - the spec-set scan
  ///   on the real specs, as a ratchet over a known baseline (see
  ///   use_case_spec_baseline.dart).
  /// Path: unhappy (rule interaction)
  group('FR-053 use-case spec test plans', () {
    final nonconforming = {
      for (final v in checkUseCaseSpecRows(_repository))
        v.path.substring('doc/specs/'.length),
    };

    /// Requirement: doc/specs/errors-and-results.md FR-053 - a use-case spec
    ///   outside the baseline must carry the FR-031, FR-034 and FR-051 rows
    ///   or state that it calls no port.
    /// Path: unhappy (rule interaction)
    test('no new use-case spec lacks the required rows', () {
      expect(nonconforming.difference(useCaseSpecsMissingErrorRows), isEmpty);
    });

    /// Requirement: doc/specs/errors-and-results.md FR-053 - a spec that now
    ///   conforms is removed from the baseline, so it cannot regress.
    /// Path: unhappy (state error)
    test('the baseline lists only specs that still lack the rows', () {
      expect(useCaseSpecsMissingErrorRows.difference(nonconforming), isEmpty);
    });
  }, timeout: _budget);

  /// Requirement: doc/specs/errors-and-results.md FR-004, FR-005 and FR-006 -
  ///   the registry of real subtypes against the section 7 table.
  /// Path: happy
  group('exception registry', () {
    /// Requirement: doc/specs/errors-and-results.md FR-005 - every errorType in
    ///   section 7 is lower snake case and the snake_case of its subtype name.
    /// Path: happy
    test('section 7 values are the snake_case of their subtype', () {
      final table = _specErrorTypes();

      expect(table, isNotEmpty);
      for (final entry in table.entries) {
        expect(entry.value, snakeCase(entry.key), reason: entry.key);
        expect(entry.value, matches(RegExp(r'^[a-z][a-z0-9_]*$')));
      }
    });

    /// Requirement: doc/specs/errors-and-results.md FR-006 - errorType values
    ///   in section 7 are unique.
    /// Path: unhappy (rule interaction)
    test('section 7 values are unique', () {
      final values = _specErrorTypes().values.toList();

      expect(values.toSet(), hasLength(values.length));
    });

    /// Requirement: doc/specs/errors-and-results.md FR-006 - every subtype in
    ///   section 7 is registered or pending, never both, and a pending one is
    ///   not declared under lib/ yet.
    /// Path: unhappy (missing content)
    test('every section 7 subtype is registered or pending', () {
      final table = _specErrorTypes();
      final registered = {for (final e in registeredExceptions) e.className};

      expect(registered.intersection(pendingSubtypes), isEmpty);
      expect(registered.union(pendingSubtypes), table.keys.toSet());
      for (final entry in registeredExceptions) {
        expect(entry.errorType, table[entry.className]);
      }
    });

    /// Requirement: doc/specs/errors-and-results.md FR-006 - a pending subtype
    ///   has no declaration yet; the stage that adds it registers it.
    /// Path: unhappy (state error)
    test('a pending subtype is not declared under lib yet', () {
      final declaredText = _repository
          .paths(prefix: 'lib/', suffix: '.dart')
          .map((p) => _repository.lexed(p).code)
          .join('\n');

      for (final name in pendingSubtypes) {
        expect(
          RegExp('class\\s+$name\\b').hasMatch(declaredText),
          isFalse,
          reason: '$name now exists: register it and drop it from pending',
        );
      }
    });

    /// Requirement: per case
    /// Path: per case
    for (final entry in registeredExceptions) {
      test('${entry.className} follows the exception conventions [happy]', () {
        const cause = FormatException('backend');
        final trace = StackTrace.fromString('trace');

        final withBoth = entry.create(cause: cause, causeStackTrace: trace);
        final bare = entry.create();

        expect(withBoth, isA<Srd5eException>());
        expect(withBoth.cause, same(cause));
        expect(withBoth.causeStackTrace, same(trace));
        expect(bare.cause, isNull);
        expect(bare.causeStackTrace, isNull);
        expect(withBoth.errorType, entry.errorType);
        expect(bare.errorType, entry.errorType);
      });
    }
  }, timeout: _budget);
}
