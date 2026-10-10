import 'package:test/test.dart';

import '../support/real_repository.dart';
import '../support/source_set.dart';
import '../support/violation.dart';
import 'notice_paths.dart';

/// The repository, loaded once per test file and never mutated.
final SourceSet _repository = realRepository;

const Timeout _budget = Timeout(Duration(seconds: 10));

void main() {
  /// Requirement: doc/specs/architecture-guardrails.md FR-079 - NOTICE.md
  ///   lists the covered paths once content is bundled, and `.pubignore`
  ///   excludes `doc/research/`, on the real repository.
  /// Path: happy
  test(
    'FR-079: NOTICE.md covered paths and .pubignore on the real repository',
    () {
      final violations = checkNoticePaths(_repository);
      expect(violations, isEmpty, reason: '\n${formatViolations(violations)}');
    },
    timeout: _budget,
  );
}
