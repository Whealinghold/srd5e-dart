import 'package:test/test.dart';

import '../support/directives.dart';
import '../support/real_repository.dart';
import '../support/violation.dart';
import 'harness_guards.dart';

const Timeout _budget = Timeout(Duration(seconds: 10));

void main() {
  /// Requirement: doc/specs/architecture-guardrails.md FR-012 - the suite
  ///   fails if the snapshot lacks lib/srd5e.dart or pubspec.yaml.
  /// Path: unhappy (empty case)
  test('FR-012: the real repository has lib/srd5e.dart and pubspec.yaml', () {
    expect(realRepository.files.keys, contains(entryPointPath));
    expect(realRepository.files.keys, contains(pubspecPath));
    expect(() => requireRepositoryRoots(realRepository), returnsNormally);
  }, timeout: _budget);

  /// Requirement: doc/specs/architecture-guardrails.md FR-010 - every file
  ///   the loader could not decode is a Violation.
  /// Path: unhappy (failure)
  test('FR-010: every file in the real repository is readable as UTF-8', () {
    final found = checkUnreadableFiles(realRepository);

    expect(found, isEmpty, reason: '\n${formatViolations(found)}');
  }, timeout: _budget);

  /// Requirement: doc/specs/architecture-guardrails.md FR-003 - a check is a
  ///   pure function of a SourceSet and does no I/O: no check implementation
  ///   file imports dart:io (only the loader of the support code does).
  /// Path: happy
  test('FR-003: no check implementation imports dart:io', () {
    final importers = {
      for (final d in allDirectives(
        realRepository,
        prefix: 'test/architecture/checks/',
      ))
        if (!d.from.endsWith('_test.dart') && d.uri == 'dart:io') d.from,
    };

    expect(importers, isEmpty);
  }, timeout: _budget);

  /// Requirement: doc/specs/architecture-guardrails.md FR-003 - the scan is
  ///   not vacuous: there are check implementation files, and the loader in
  ///   the support code is where dart:io is used.
  /// Path: unhappy (empty and minimal)
  test('FR-003: the scan sees the checks and the loader', () {
    final checkFiles = realRepository
        .dartPaths('test/architecture/checks/')
        .where((p) => !p.endsWith('_test.dart'));
    final loaderImports = [
      for (final d in allDirectives(
        realRepository,
        prefix: 'test/architecture/support/source_set.dart',
      ))
        d.uri,
    ];

    expect(checkFiles, isNotEmpty);
    expect(loaderImports, contains('dart:io'));
  }, timeout: _budget);
}
