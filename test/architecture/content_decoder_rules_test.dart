import 'package:test/test.dart';

import 'support/real_repository.dart';
import 'support/violation.dart';

/// The decoder's architecture rules of
/// `doc/specs/content-schema-and-decoder.md` that a source scan enforces:
/// FR-073 (the domain never imports `dart:convert` and no decoded type
/// exposes raw JSON), FR-141 (only `content/application/` reaches the
/// shared error types) and FR-088 (the export placement of FR-078 and
/// FR-087).
void main() {
  /// Requirement: doc/specs/content-schema-and-decoder.md FR-073 - no
  ///   `dart:convert` in `content/domain/`; only the adapter decodes JSON.
  /// Path: happy
  test('content/domain imports no dart:convert', () {
    final violations = <Violation>[];
    for (final path in realRepository.dartPaths('lib/src/content/domain/')) {
      final text = realRepository.files[path]!;
      if (text.contains("import 'dart:convert")) {
        violations.add(
          Violation(
            checkId: 'FR-073',
            path: path,
            line: _lineOf(text, "import 'dart:convert"),
            detail: 'content/domain imports dart:convert.',
          ),
        );
      }
    }

    expect(violations, isEmpty);
  }, timeout: const Timeout(Duration(seconds: 10)));

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-073 - no raw
  ///   JSON in public signatures: no `dynamic` and no `Map<String,
  ///   dynamic>` anywhere in the content domain or application.
  /// Path: happy
  test('content/domain and content/application use no raw JSON types', () {
    final violations = <Violation>[];
    for (final folder in const [
      'lib/src/content/domain/',
      'lib/src/content/application/',
    ]) {
      for (final path in realRepository.dartPaths(folder)) {
        final text = realRepository.files[path]!;
        for (final token in const ['dynamic', 'Map<String, dynamic>']) {
          if (text.contains(token)) {
            violations.add(
              Violation(
                checkId: 'FR-073',
                path: path,
                line: _lineOf(text, token),
                detail: 'Raw JSON type "$token" in $folder.',
              ),
            );
          }
        }
      }
    }

    expect(violations, isEmpty);
  }, timeout: const Timeout(Duration(seconds: 10)));

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-141 - only
  ///   `content/application/` refers to `shared_ports/errors/`; the domain
  ///   and the adapters import nothing from it, so every content domain
  ///   type throws only `ArgumentError`.
  /// Path: happy
  test('only content/application imports shared_ports/errors', () {
    final violations = <Violation>[];
    for (final folder in const [
      'lib/src/content/domain/',
      'lib/src/content/adapters/',
    ]) {
      for (final path in realRepository.dartPaths(folder)) {
        final text = realRepository.files[path]!;
        if (text.contains('shared_ports/errors/')) {
          violations.add(
            Violation(
              checkId: 'FR-141',
              path: path,
              line: _lineOf(text, 'shared_ports/errors/'),
              detail: '$folder imports shared_ports/errors/.',
            ),
          );
        }
      }
    }

    expect(violations, isEmpty);
  }, timeout: const Timeout(Duration(seconds: 10)));

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-078, FR-088 -
  ///   `JsonContentSetDecoder` is exported from `lib/adapters.dart` only,
  ///   and `FakeContentSetDecoder` (FR-087) from `lib/testing.dart` only;
  ///   neither reaches `lib/srd5e.dart` or the barrel.
  /// Path: happy
  test('decoder exports sit in their own entry points', () {
    final adapters = realRepository.files['lib/adapters.dart']!;
    final testing = realRepository.files['lib/testing.dart']!;
    final main = realRepository.files['lib/srd5e.dart']!;
    final barrel = realRepository.files['lib/src/content/content.dart']!;

    expect(adapters.contains('json_content_set_decoder.dart'), isTrue);
    expect(adapters.contains('JsonContentSetDecoder'), isTrue);
    expect(testing.contains('fake_content_set_decoder.dart'), isTrue);
    expect(testing.contains('FakeContentSetDecoder'), isTrue);
    expect(
      main.contains('json_content_set_decoder.dart'),
      isFalse,
      reason: 'FR-078: the adapter is not exported from lib/srd5e.dart',
    );
    expect(
      main.contains('fake_content_set_decoder.dart'),
      isFalse,
      reason: 'FR-087: the double is not exported from lib/srd5e.dart',
    );
    expect(
      barrel.contains('json_content_set_decoder.dart'),
      isFalse,
      reason: 'FR-078: the adapter is not exported from the barrel',
    );
    expect(
      barrel.contains('fake_content_set_decoder.dart'),
      isFalse,
      reason: 'FR-087: the double is not exported from the barrel',
    );
  }, timeout: const Timeout(Duration(seconds: 10)));

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-088 - every
  ///   exported member is documented: the analyzer lint
  ///   `public_member_api_docs` stays on (the file the lint reads).
  /// Path: happy
  test('the analyzer config keeps public_member_api_docs on', () {
    final options = realRepository.files['analysis_options.yaml']!;

    expect(options.contains('public_member_api_docs'), isTrue);
  }, timeout: const Timeout(Duration(seconds: 10)));
}

int _lineOf(String text, String needle) {
  final index = text.indexOf(needle);
  if (index < 0) return 1;
  return '\n'.allMatches(text.substring(0, index)).length + 1;
}
