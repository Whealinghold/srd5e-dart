import 'package:test/test.dart';

import '../support/real_repository.dart';
import '../support/source_set.dart';
import '../support/violation.dart';
import 'notice_marks.dart';

/// The repository, loaded once per test file and never mutated.
final SourceSet _repository = realRepository;

const Timeout _budget = Timeout(Duration(seconds: 10));

void main() {
  /// Requirement: doc/specs/content-licensing-and-notice.md FR-016, FR-018,
  ///   FR-019 and FR-038 - no trademarked name as a brand, and a .pubignore
  ///   that keeps the notice, the licence and the embeds, on the real
  ///   repository.
  /// Path: happy
  test('the trademark and .pubignore checks pass on the repository', () {
    final violations = [
      checkTrademarkFreeIdentifiers(_repository),
      checkPubignoreKeepsNotice(_repository),
      checkPubignoreKeepsEmbeds(_repository),
      checkCompatibilityWording(_repository),
    ].expand((list) => list).toList();
    expect(violations, isEmpty, reason: '\n${formatViolations(violations)}');
  }, timeout: _budget);
}
