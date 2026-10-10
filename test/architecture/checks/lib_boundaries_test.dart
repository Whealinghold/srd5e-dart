import 'package:test/test.dart';

import '../support/real_repository.dart';
import '../support/source_set.dart';
import '../support/violation.dart';
import 'lib_boundaries.dart';

/// The repository, loaded once per test file and never mutated.
final SourceSet _repository = realRepository;

const Timeout _budget = Timeout(Duration(seconds: 10));

void _expectNone(List<Violation> violations) {
  expect(violations, isEmpty, reason: '\n${formatViolations(violations)}');
}

void main() {
  /// Requirement: doc/specs/architecture-guardrails.md FR-012, FR-076 - a
  ///   check must not pass vacuously: the real scan reads lib/ files that
  ///   have directives.
  /// Path: unhappy (empty and minimal)
  test('the real repository has lib/ files with imports to scan', () {
    final withImports = _repository
        .dartPaths('lib/')
        .where(
          (p) => RegExp(
            r'^\s*(import|export)\s',
            multiLine: true,
          ).hasMatch(_repository.files[p]!),
        );

    expect(withImports, isNotEmpty);
  }, timeout: _budget);

  /// Requirement: doc/specs/architecture-guardrails.md FR-076 - no file under
  ///   lib/ imports or exports a path outside lib/ or a dev-only package.
  /// Path: happy
  test(
    'FR-076: lib/ imports stay in lib/ and avoid dev-only packages',
    () => _expectNone(checkLibImportsStayInLib(_repository)),
    timeout: _budget,
  );

  /// Requirement: doc/specs/architecture-guardrails.md FR-095 - the embedded
  ///   data libraries import nothing and only content/adapters reads them.
  /// Path: happy
  test(
    'FR-095: embedded data is imported only by content/adapters',
    () => _expectNone(checkEmbeddedDataImports(_repository)),
    timeout: _budget,
  );
}
