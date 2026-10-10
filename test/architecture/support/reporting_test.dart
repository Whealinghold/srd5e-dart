import 'package:test/test.dart';

import 'reporting.dart';
import 'violation.dart';

const _b = Violation(
  checkId: 'FR-020',
  path: 'lib/b.dart',
  line: 7,
  detail: 'second',
);
const _a2 = Violation(
  checkId: 'FR-021',
  path: 'lib/a.dart',
  line: 12,
  detail: 'third',
);
const _a1 = Violation(
  checkId: 'FR-019',
  path: 'lib/a.dart',
  line: 3,
  detail: 'first',
);

void main() {
  /// Requirement: doc/specs/architecture-guardrails.md FR-004 - a report
  ///   lists every violation, one per line, as path:line id detail.
  /// Path: unhappy (multiple violations)
  group('violationLines', () {
    /// Requirement: doc/specs/architecture-guardrails.md FR-004, FR-011 - three
    ///   violations give three sorted lines.
    /// Path: unhappy (multiple violations)
    test('lists all three violations sorted by path and line', () {
      expect(violationLines([_b, _a2, _a1]), [
        'lib/a.dart:3 FR-019 first',
        'lib/a.dart:12 FR-021 third',
        'lib/b.dart:7 FR-020 second',
      ]);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-011 - input order
    ///   does not change the output.
    /// Path: unhappy (determinism)
    test('is independent of input order', () {
      final forward = violationLines([_a1, _a2, _b]);

      expect(violationLines([_b, _a2, _a1]), forward);
      expect(violationLines([_a2, _b, _a1]), forward);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-004 - identical
    ///   violations are not collapsed.
    /// Path: unhappy (multiple violations)
    test('keeps duplicate violations', () {
      expect(violationLines([_a1, _a1]), hasLength(2));
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-004 - no
    ///   violation, no lines.
    /// Path: happy
    test('is empty for no violations', () {
      expect(violationLines(const []), isEmpty);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-004 - lines match
    ///   the shared formatter.
    /// Path: happy
    test('joins to what formatViolations prints', () {
      expect(violationLines([_b, _a1]).join('\n'), formatViolations([_b, _a1]));
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-004 - a violation
    ///   that cannot be one line is a defect in the check.
    /// Path: unhappy (invalid input)
    test('rejects a violation that cannot be one line', () {
      Violation make({
        String id = 'FR-1',
        String path = 'p',
        int line = 1,
        String detail = 'd',
      }) => Violation(checkId: id, path: path, line: line, detail: detail);

      expect(() => violationLines([make(detail: 'a\nb')]), throwsArgumentError);
      expect(() => violationLines([make(path: 'a\rb')]), throwsArgumentError);
      expect(() => violationLines([make(id: 'a\nb')]), throwsArgumentError);
      expect(() => violationLines([make(detail: '')]), throwsArgumentError);
      expect(() => violationLines([make(path: '')]), throwsArgumentError);
      expect(() => violationLines([make(id: '')]), throwsArgumentError);
      expect(() => violationLines([make(line: 0)]), throwsArgumentError);
      expect(violationLines([make(line: 1)]), ['p:1 FR-1 d']);
    });
  });

  /// Requirement: doc/specs/architecture-guardrails.md FR-059 - a non-empty
  ///   list fails the test with every violation printed.
  /// Path: unhappy (failure)
  group('expectNoViolations', () {
    /// Requirement: doc/specs/architecture-guardrails.md FR-059 - an empty
    ///   list passes.
    /// Path: happy
    test('passes for an empty list', () {
      expectNoViolations(const []);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-059, FR-004 - the
    ///   failure message carries every line.
    /// Path: unhappy (failure)
    test('fails and prints all violations', () {
      Object? caught;
      try {
        expectNoViolations([_b, _a2, _a1]);
      } on TestFailure catch (e) {
        caught = e;
      }

      expect(caught, isA<TestFailure>());
      final message = (caught! as TestFailure).message!;
      expect(message, violationReport([_a1, _a2, _b]));
      expect(message, startsWith('3 architecture violation(s):\n'));
      for (final line in violationLines([_a1, _a2, _b])) {
        expect(message, contains(line));
      }
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-059 - a single
    ///   violation also fails.
    /// Path: unhappy (boundary)
    test('fails for one violation', () {
      expect(() => expectNoViolations([_a1]), throwsA(isA<TestFailure>()));
    });
  });
}
