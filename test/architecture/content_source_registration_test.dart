import 'package:test/test.dart';

import 'support/declarations.dart';
import 'support/real_repository.dart';
import 'support/violation.dart';

/// The architecture rows of `doc/specs/content-source-port.md` a source
/// scan enforces: FR-047 (every shipped implementation is registered in
/// `test/contract/`), FR-019 (the lookup types carry no display text),
/// FR-025 and FR-051 (barrel export placement of the port's types), FR-026
/// and FR-059 (the generic adapters are exported from `lib/adapters.dart`
/// only), FR-044 (the barrel's library doc comment and the dartdoc lint),
/// FR-049 (the double imports and is exported exactly as the spec pins) and
/// FR-050 (the adapter-author documentation points at the contract suite).
void main() {
  /// Whether [file] holds an `export` directive naming [name] (a line
  /// starting with `export`, so prose mentions never count).
  bool exportedFrom(String file, String name) =>
      RegExp('^export[^;]*\\b$name\\b', multiLine: true).hasMatch(file);

  /// Requirement: doc/specs/content-source-port.md FR-047 - every shipped
  ///   ContentSource implementation appears among the contract-suite
  ///   registrations in test/contract/.
  /// Path: happy
  test(
    'every ContentSource implementation is registered in test/contract/',
    () {
      final violations = <Violation>[];
      final contractText = [
        for (final path in realRepository.dartPaths('test/contract/'))
          realRepository.files[path]!,
      ].join('\n');

      if (contractText.isEmpty) {
        violations.add(
          const Violation(
            checkId: 'FR-047',
            path: 'test/contract/',
            line: 1,
            detail: 'test/contract/ holds no registration file.',
          ),
        );
      }
      for (final path in realRepository.dartPaths('lib/')) {
        for (final declaration in declarationsIn(
          path,
          realRepository.lexed(path),
        )) {
          if (declaration.kind != DeclarationKind.classDeclaration) continue;
          if (declaration.modifiers.contains('abstract')) continue;
          if (!declaration.supertypes.contains('ContentSource')) continue;
          if (contractText.contains(declaration.name)) continue;
          violations.add(
            Violation(
              checkId: 'FR-047',
              path: path,
              line: declaration.line,
              detail:
                  '${declaration.name} implements ContentSource but is not '
                  'registered in test/contract/.',
            ),
          );
        }
      }

      expect(violations, isEmpty);
    },
    timeout: const Timeout(Duration(seconds: 10)),
  );

  /// Requirement: doc/specs/content-source-port.md FR-025, FR-051 - the
  ///   port's types are exported from the content barrel and
  ///   lib/srd5e.dart, under the prefixed names only (never bare Found or
  ///   NotFound).
  /// Path: happy
  test('the port types are exported from the barrel and lib/srd5e.dart', () {
    const exported = [
      'ContentSource',
      'ContentSourceException',
      'ContentLookup',
      'ContentFound',
      'ContentNotFound',
      'ContentCatalogue',
      'ContentQuery',
      'ContentLookupQuery',
      'ContentListKindQuery',
    ];
    final barrel = realRepository.files['lib/src/content/content.dart']!;
    final main = realRepository.files['lib/srd5e.dart']!;

    for (final name in exported) {
      expect(
        exportedFrom(barrel, name),
        isTrue,
        reason: 'the barrel does not export $name',
      );
      expect(
        exportedFrom(main, name),
        isTrue,
        reason: 'lib/srd5e.dart does not export $name',
      );
    }
    expect(
      exportedFrom(main, 'Found'),
      isFalse,
      reason: 'the bare name Found must not be exported',
    );
    expect(
      exportedFrom(main, 'NotFound'),
      isFalse,
      reason: 'the bare name NotFound must not be exported',
    );
  }, timeout: const Timeout(Duration(seconds: 10)));

  /// Requirement: doc/specs/content-source-port.md FR-026, FR-059 - the
  ///   generic sources and BundledContentInvalid are exported from
  ///   lib/adapters.dart only.
  /// Path: happy
  test('the generic sources are exported from lib/adapters.dart only', () {
    const names = [
      'InMemoryContentSource',
      'BundledContentSource',
      'BundledContentInvalid',
    ];
    final adapters = realRepository.files['lib/adapters.dart']!;
    final main = realRepository.files['lib/srd5e.dart']!;
    final testing = realRepository.files['lib/testing.dart']!;

    for (final name in names) {
      expect(
        exportedFrom(adapters, name),
        isTrue,
        reason: 'lib/adapters.dart does not export $name',
      );
      expect(
        exportedFrom(main, name),
        isFalse,
        reason: 'lib/srd5e.dart exports $name',
      );
      expect(
        exportedFrom(testing, name),
        isFalse,
        reason: 'lib/testing.dart exports $name',
      );
    }
  }, timeout: const Timeout(Duration(seconds: 10)));

  /// Requirement: doc/specs/content-source-port.md FR-049 - the double
  ///   imports only the content barrel (plus dart: libraries) and is
  ///   exported only by lib/testing.dart.
  /// Path: happy
  test(
    'FakeContentSource imports the barrel and is exported only by testing',
    () {
      const path = 'lib/src/testing/fake_content_source.dart';
      final source = realRepository.files[path]!;
      final testing = realRepository.files['lib/testing.dart']!;

      expect(
        source.contains("import '../content/content.dart'"),
        isTrue,
        reason: 'the double imports the content barrel',
      );
      const bannedImports = [
        "import '../content/application/",
        'import "../content/application/',
        "import '../content/adapters/",
        "import '../content/domain/",
        "import '../content/data/",
      ];
      for (final banned in bannedImports) {
        expect(
          source.contains(banned),
          isFalse,
          reason: 'the double must not import $banned',
        );
      }
      expect(
        testing.contains('fake_content_source.dart'),
        isTrue,
        reason: 'lib/testing.dart exports the double',
      );
      expect(
        testing.contains('FakeContentSource'),
        isTrue,
        reason: 'lib/testing.dart exports the double by name',
      );
    },
    timeout: const Timeout(Duration(seconds: 10)),
  );

  /// Requirement: doc/specs/content-source-port.md FR-050 - the README
  ///   adapter-author section and the ContentSource dartdoc point at
  ///   test/contract/content_source_contract.dart, which is not exported.
  /// Path: happy
  test('the adapter-author documentation names the contract suite', () {
    final readme = realRepository.files['README.md']!;
    final port = realRepository
        .files['lib/src/content/application/ports/content_source.dart']!;

    expect(
      readme.contains('test/contract/content_source_contract.dart'),
      isTrue,
    );
    expect(port.contains('test/contract/content_source_contract.dart'), isTrue);
  }, timeout: const Timeout(Duration(seconds: 10)));

  /// Requirement: doc/specs/content-source-port.md FR-019 - the exception
  ///   and the lookup result types carry structured data only: no field or
  ///   getter named message, description, text or displayText. This is the
  ///   errors-and-results.md FR-007 scan extended to the four types of this
  ///   spec; check E2 of that spec exempts lib/src/content/domain/, where
  ///   verbatim SRD value objects legitimately carry text members, so the
  ///   domain lookup types are scanned here.
  /// Path: happy
  test('the lookup types declare no display-text member', () {
    const banned = {'message', 'description', 'text', 'displayText'};
    const scanned = {
      'ContentLookup',
      'ContentFound',
      'ContentNotFound',
      'ContentSourceException',
    };
    const paths = [
      'lib/src/content/domain/content_lookup.dart',
      'lib/src/content/application/ports/content_source.dart',
    ];
    final violations = <Violation>[];
    for (final path in paths) {
      for (final declaration in declarationsIn(
        path,
        realRepository.lexed(path),
      )) {
        if (declaration.kind != DeclarationKind.classDeclaration) continue;
        if (!scanned.contains(declaration.name)) continue;
        for (final member in declaration.memberNames) {
          if (!banned.contains(member.name)) continue;
          violations.add(
            Violation(
              checkId: 'FR-019',
              path: path,
              line: member.line,
              detail:
                  '${declaration.name}.${member.name} is a display-text '
                  'member; the type carries structured data only.',
            ),
          );
        }
      }
    }

    expect(violations, isEmpty);
  }, timeout: const Timeout(Duration(seconds: 10)));

  /// Requirement: doc/specs/content-source-port.md FR-044 - the barrel has
  ///   a library doc comment listing the context's inputs and outputs, and
  ///   every exported member has a dartdoc comment (the mechanical half is
  ///   the analyzer's public_member_api_docs lint, which must stay on).
  /// Path: happy
  test(
    'the barrel documents its inputs and outputs and keeps the dartdoc lint',
    () {
      final barrel = realRepository.files['lib/src/content/content.dart']!;
      final options = realRepository.files['analysis_options.yaml']!;

      expect(
        RegExp('///[^\\n]*\\nlibrary;').hasMatch(barrel),
        isTrue,
        reason: 'content.dart carries a library doc comment',
      );
      expect(barrel.contains('/// ### Inputs'), isTrue);
      expect(barrel.contains('/// ### Outputs'), isTrue);
      expect(
        options.contains('public_member_api_docs'),
        isTrue,
        reason: 'every exported member must have a dartdoc comment',
      );
    },
    timeout: const Timeout(Duration(seconds: 10)),
  );
}
