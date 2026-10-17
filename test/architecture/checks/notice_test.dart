import 'package:test/test.dart';

import '../support/real_repository.dart';
import '../support/source_set.dart';
import '../support/violation.dart';
import 'notice.dart';

/// The repository, loaded once per test file and never mutated.
final SourceSet _repository = realRepository;

const Timeout _budget = Timeout(Duration(seconds: 10));

void main() {
  /// Requirement: doc/specs/content-licensing-and-notice.md FR-001, FR-002,
  ///   FR-004, FR-005, FR-006, FR-007, FR-011, FR-013, FR-015, FR-024 and
  ///   FR-035 - the always-on notice checks are green on the real repository.
  ///   FR-011 holds because the status line was removed: bundled content is
  ///   present (the embedded index of PR 8,
  ///   lib/src/content/data/embedded_documents.dart, is a non-README file
  ///   under a covered path per the spec's section 3), so the spec's MUST NOT
  ///   applies today and the plan's section-14 branch "or now if the PRs land
  ///   together" was taken on review.
  /// Path: happy
  test('the always-on notice checks pass on the repository', () {
    final violations = [
      for (final id in const [
        'CLN-FR-001',
        'CLN-FR-002',
        'CLN-FR-004',
        'CLN-FR-005',
        'CLN-FR-006',
        'CLN-FR-007',
        'CLN-FR-011',
        'CLN-FR-013',
        'CLN-FR-015',
        'CLN-FR-024',
        'CLN-FR-035',
      ])
        ...noticeChecks[id]!(_repository),
    ];
    expect(violations, isEmpty, reason: '\n${formatViolations(violations)}');
  }, timeout: _budget);

  /// Requirement: doc/specs/content-licensing-and-notice.md FR-012 - the
  ///   Changes section exists while bundled content is present. The embedded
  ///   index (lib/src/content/data/embedded_documents.dart, PR 8) is a file
  ///   under a covered path, so the content-conditional checks are live.
  /// Path: happy
  test('FR-012: the Changes section is present while content is live', () {
    final violations = checkChangesSection(_repository);
    expect(violations, isEmpty, reason: '\n${formatViolations(violations)}');
  }, timeout: _budget);
}
