import 'package:test/test.dart';

import 'support/real_repository.dart';
import 'support/source_set.dart';

/// The web-run wiring of content-schema-and-decoder.md FR-099: the decoder
/// tests in `test/content/adapters/` must pass on Chrome, so CI installs
/// Chrome and runs them there, the local command in AGENTS.md matches, and
/// the release checklist lists the run. Pure scan over the `SourceSet`; no
/// browser is launched here.
final SourceSet _repository = realRepository;

void main() {
  /// Requirement: doc/specs/content-schema-and-decoder.md FR-099 - the
  ///   decoder tests run on the VM and on Chrome: `.github/workflows/ci.yml`
  ///   installs Chrome and runs `dart test -p chrome test/content/adapters`
  ///   as a blocking step, AGENTS.md "Commands" carries the matching local
  ///   Docker command, and release-0-1-0.md lists the web run in its CI
  ///   checklist.
  /// Path: happy
  test('CI, AGENTS.md and the release checklist wire the Chrome run', () {
    final ci = _repository.files['.github/workflows/ci.yml']!;
    expect(
      ci,
      contains('browser-actions/setup-chrome@v1'),
      reason: 'CI installs Chrome',
    );
    expect(
      ci,
      contains('dart test -p chrome test/content/adapters'),
      reason:
          'CI runs the decoder tests on Chrome; a failure blocks the '
          'build',
    );

    final agents = _repository.files['AGENTS.md']!;
    expect(
      agents,
      contains('dart test -p chrome test/content/adapters'),
      reason: 'AGENTS.md "Commands" carries the local Chrome run',
    );

    final release = _repository.files['doc/specs/release-0-1-0.md']!;
    expect(
      release,
      contains('dart test -p chrome test/content/adapters'),
      reason: 'the release checklist lists the web run',
    );
  }, timeout: const Timeout(Duration(seconds: 10)));
}
