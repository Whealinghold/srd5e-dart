import 'package:test/test.dart';

import '../support/real_repository.dart';
import '../support/source_set.dart';
import '../support/violation.dart';
import 'notice_files.dart';

/// The repository, loaded once per test file and never mutated.
final SourceSet _repository = realRepository;

const Timeout _budget = Timeout(Duration(seconds: 10));

void main() {
  /// Requirement: doc/specs/content-licensing-and-notice.md FR-008, FR-017,
  ///   FR-027, FR-028, FR-029, FR-036 and FR-037 - the file placement and
  ///   carried-notice checks are green on the real repository. FR-027 and
  ///   FR-028 are content-conditional and live: the embedded index
  ///   (lib/src/content/data/embedded_documents.dart) is a file under a
  ///   covered path, and the covered directories carry their READMEs.
  /// Path: happy
  test('the file-placement checks pass on the repository', () {
    final violations = [
      checkDataFileLocations(_repository),
      checkNoImageAssets(_repository),
      checkDirectoryReadmes(_repository),
      checkReadmeStatement(_repository),
      checkEmbedHeaders(_repository),
      checkLicenseIsCodeOnly(_repository),
      checkHeaderedFileLocation(_repository),
    ].expand((list) => list).toList();
    expect(violations, isEmpty, reason: '\n${formatViolations(violations)}');
  }, timeout: _budget);
}
