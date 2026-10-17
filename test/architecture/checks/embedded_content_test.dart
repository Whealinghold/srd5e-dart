import 'package:test/test.dart';

import '../../../tool/generate_embedded_data.dart';
import '../support/real_repository.dart';
import '../support/source_set.dart';
import '../support/violation.dart';
import 'embedded_content.dart';

/// The repository, loaded once per test file and never mutated.
final SourceSet _repository = realRepository;

const Timeout _budget = Timeout(Duration(seconds: 10));

void main() {
  /// Requirement: doc/specs/architecture-guardrails.md FR-078 - running the
  ///   real generator (`tool/generate_embedded_data.dart`,
  ///   content-schema-and-decoder.md FR-121) on the texts of
  ///   `data/srd_5_2_1/*.json` reproduces every committed library under
  ///   `lib/src/content/data/` byte for byte, with none missing and none
  ///   extra (content-schema-and-decoder.md FR-123).
  /// Path: unhappy (state error)
  test('FR-078: embedded libraries match the real generator', () {
    final violations = checkEmbeddedContent(
      _repository,
      generateEmbeddedLibraries,
    );
    expect(violations, isEmpty, reason: '\n${formatViolations(violations)}');
  }, timeout: _budget);
}
