import 'package:test/test.dart';

import '../support/reporting.dart';
import '../support/source_set.dart';
import 'context_map.dart'
    show contextMapFixtureAgents, contextMapFixtureArchitecture;
import 'registry.dart';

/// The FR-058 fixture: the core entry point, the pubspec, docs (with a valid
/// context map and AGENTS.md list, which FR-022 requires), and context
/// folders that hold no `.dart` file (a folder is not a SourceSet entry).
const Map<String, List<String>> _contexts = {
  'content': [],
  'combat': ['content'],
};

/// The docs of the fixture carry a rule file with a well-formed tag (FR-029)
/// that `AGENTS.md` lists (FR-031); the tag value is a made-up fixture value.
const String _agentsRuleList =
    '\n## Read the rules first\n\n- `doc/rules/architecture.md`\n';
const String _ruleTagLine = '\nRULE-TAG: `architecture-0123456789ab`\n';

SourceSet _emptyRepository() => SourceSet({
  'AGENTS.md': contextMapFixtureAgents(_contexts.keys) + _agentsRuleList,
  'lib/srd5e.dart': '/// The public API.\nlibrary;\n',
  'pubspec.yaml': 'name: srd5e\n',
  'README.md': '# srd5e\n',
  'NOTICE.md': '# Notice\n',
  'doc/documentation_index.md': '# Index\n',
  'doc/rules/architecture.md':
      contextMapFixtureArchitecture(_contexts) + _ruleTagLine,
  'lib/src/combat/.gitkeep': '',
  'lib/src/content/.gitkeep': '',
});

void main() {
  /// Requirement: doc/specs/architecture-guardrails.md FR-058 - an
  ///   empty-contexts repository yields zero Violations from every
  ///   registered check.
  /// Path: happy
  group('FR-058 empty repository', () {
    /// Requirement: doc/specs/architecture-guardrails.md FR-058 - every
    ///   registered check is silent on the empty-contexts fixture.
    /// Path: happy
    test('every registered check yields no Violation', () {
      final sources = _emptyRepository();

      for (final entry in registry.entries) {
        final found = entry.value(sources);

        expect(
          found,
          isEmpty,
          reason: '${entry.key}\n${violationReport(found)}',
        );
      }
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-058 - the loop is
    ///   not vacuous: there is a registered check, and the fixture holds no
    ///   Dart file under lib/src/.
    /// Path: unhappy (empty case)
    test('the fixture is empty of source and the registry is not', () {
      final sources = _emptyRepository();

      expect(registry, isNotEmpty);
      expect(
        sources.files.keys.where(
          (p) => p.startsWith('lib/src/') && p.endsWith('.dart'),
        ),
        isEmpty,
      );
      expect(
        sources.files.keys,
        containsAll(['lib/srd5e.dart', 'pubspec.yaml']),
      );
    });
  });
}
