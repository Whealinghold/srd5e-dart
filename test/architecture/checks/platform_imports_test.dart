import 'package:test/test.dart';

import '../support/real_repository.dart';
import '../support/source_set.dart';
import '../support/violation.dart';
import 'platform_imports.dart';

/// The repository, loaded once per test file and never mutated.
final SourceSet _repository = realRepository;

const Timeout _budget = Timeout(Duration(seconds: 10));

void _expectNone(List<Violation> violations) {
  expect(violations, isEmpty, reason: '\n${formatViolations(violations)}');
}

void main() {
  /// Requirement: doc/specs/architecture-guardrails.md FR-012, FR-013 - a
  ///   check must not pass vacuously: the real repository has the three core
  ///   entry points and files under lib/src/.
  /// Path: unhappy (empty and minimal)
  test('the real repository has the files the checks read', () {
    expect(_repository.files.keys, containsAll(coreEntryPoints));
    expect(_repository.dartPaths('lib/src/'), isNotEmpty);
  }, timeout: _budget);

  /// Requirement: doc/specs/architecture-guardrails.md FR-013 - no file
  ///   under
  ///   lib/src/ imports Flutter or dart:ui, and dart:io stays in adapters/.
  /// Path: happy
  test(
    'FR-013: lib/src/ has no Flutter, dart:ui or stray dart:io import',
    () => _expectNone(checkSrcPlatformImports(_repository)),
    timeout: _budget,
  );

  /// Requirement: doc/specs/architecture-guardrails.md FR-062 - the core
  ///   entry points are platform-neutral.
  /// Path: happy
  test(
    'FR-062: no core entry point imports dart:io, dart:ui or Flutter',
    () => _expectNone(checkEntryPointPlatformImports(_repository)),
    timeout: _budget,
  );

  /// Requirement: doc/specs/architecture-guardrails.md FR-014 - no dart:io;
  ///   doc/specs/content-schema-and-decoder.md FR-075 - the decoder is a
  ///   pure function of its input with no dart:io import
  ///   adapter is reachable from a core entry point.
  /// Path: happy
  test(
    'FR-014: no dart:io adapter is reachable from a core entry point',
    () => _expectNone(checkDartIoAdaptersNotCoreReachable(_repository)),
    timeout: _budget,
  );

  /// Requirement: doc/specs/architecture-guardrails.md FR-067 - every dart:io
  ///   adapter is reachable from a platform entry point.
  /// Path: happy
  test(
    'FR-067: every dart:io adapter is reachable from a platform entry point',
    () => _expectNone(checkDartIoAdaptersReachableFromPlatform(_repository)),
    timeout: _budget,
  );
}
