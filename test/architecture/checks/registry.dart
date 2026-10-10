import '../support/directives.dart';
import '../support/markdown_tables.dart';
import '../support/source_set.dart';
import '../support/spec_ids.dart';
import '../support/violation.dart';
import 'attribute_values.dart';
import 'banned_calls.dart';
import 'barrel_scan.dart';
import 'consumer_names.dart';
import 'context_map.dart';
import 'domain_observability.dart';
import 'domain_purity.dart';
import 'embedded_content.dart';
import 'harness_guards.dart';
import 'layering.dart';
import 'lib_boundaries.dart';
import 'noop_classes.dart';
import 'notice_paths.dart';
import 'observability_sdk.dart';
import 'package_dependencies.dart';
import 'platform_imports.dart';
import 'rule_tags.dart';
import 'shared_modules.dart';
import 'signal_catalogue.dart';
import 'signal_constants.dart';
import 'spec_conformance.dart';
import 'test_citations.dart';
import 'test_hygiene.dart';
import 'testing_layer.dart';
import 'use_case_calls.dart';

/// A check: a pure function from a [SourceSet] to violations (FR-003).
typedef Check = List<Violation> Function(SourceSet sources);

/// Builds a minimal violating [SourceSet] for one check id.
typedef FixtureBuilder = SourceSet Function();

// HOW A PHASE ADDS A CHECK (doc/specs/architecture-guardrails.md FR-005).
//
// 1. Write the check as `List<Violation> check(SourceSet)` in its own file
//    under `test/architecture/checks/`, with a `*_test.dart` (real
//    repository) and a `*_self_test.dart` (clean and violating fixtures).
// 2. In that file expose, for every FR id the function implements, one
//    minimal violating fixture, as a top-level map
//
//        final Map<String, FixtureBuilder> <name>ViolatingFixtures = {
//          'FR-013': _fr013Fixture,
//        };
//
//    The fixture builder returns a SourceSet on which the check yields a
//    Violation whose `checkId` equals the key. A fixture that only yields
//    other ids, or none, fails the meta-test.
// 3. In this file add one entry per id to [registry] (several ids may point
//    at the same function) and spread the file's fixture map into
//    [violatingFixtures].
// 4. An id of the spec that is not in [registry] fails the meta-test
//    (registry_test.dart); there is no list of pending ids to hide behind.
//
// Other specs' own check ids (E1 to E6 and so on) are never registered
// (architecture-guardrails.md section 9). The FR-058 empty-repository test
// loops over [registry], so a new check is covered there without edits.

/// Every implemented check, by its FR id. Several ids may share a function.
const Map<String, Check> registry = {
  'FR-007': unresolvedDirectives,
  ...attributeValuesChecks,
  ...bannedCallsChecks,
  ...barrelScanChecks,
  ...consumerNamesChecks,
  ...contextMapChecks,
  ...domainObservabilityChecks,
  ...domainPurityChecks,
  ...embeddedContentChecks,
  ...harnessGuardChecks,
  ...layeringChecks,
  ...libBoundaryChecks,
  ...noopClassesChecks,
  ...noticePathsChecks,
  ...observabilitySdkChecks,
  ...packageDependenciesChecks,
  ...platformImportsChecks,
  ...ruleTagChecks,
  ...sharedModulesChecks,
  ...signalCatalogueChecks,
  ...signalConstantsChecks,
  ...specConformanceChecks,
  ...testCitationChecks,
  ...testHygieneChecks,
  ...testingLayerChecks,
  ...useCaseCallChecks,
};

/// A minimal violating fixture per registered id. Each check file exposes its
/// own map (see the header); they are merged here.
final Map<String, FixtureBuilder> violatingFixtures = {
  'FR-007': _unresolvedDirectiveFixture,
  ...attributeValuesViolatingFixtures,
  ...bannedCallsViolatingFixtures,
  ...barrelScanViolatingFixtures,
  ...consumerNamesViolatingFixtures,
  ...contextMapViolatingFixtures,
  ...domainObservabilityViolatingFixtures,
  ...domainPurityViolatingFixtures,
  ...embeddedContentViolatingFixtures,
  ...harnessGuardViolatingFixtures,
  ...layeringViolatingFixtures,
  ...libBoundaryViolatingFixtures,
  ...noopClassesViolatingFixtures,
  ...noticePathsViolatingFixtures,
  ...observabilitySdkViolatingFixtures,
  ...packageDependenciesViolatingFixtures,
  ...platformImportsViolatingFixtures,
  ...ruleTagViolatingFixtures,
  ...sharedModulesViolatingFixtures,
  ...signalCatalogueViolatingFixtures,
  ...signalConstantsViolatingFixtures,
  ...specConformanceViolatingFixtures,
  ...testCitationViolatingFixtures,
  ...testHygieneViolatingFixtures,
  ...testingLayerViolatingFixtures,
  ...useCaseCallViolatingFixtures,
};

SourceSet _unresolvedDirectiveFixture() =>
    SourceSet({'lib/a.dart': "import 'missing.dart';\n"});

/// Ids that sit in a checked section but are not checks (FR-005): FR-087 is a
/// support rule, FR-091 restates FR-101 and reports as FR-101.
const Set<String> exemptCheckIds = {'FR-087', 'FR-091'};

/// The check ids of section 4.1 (FR-005 names FR-007 and FR-010 there).
const Set<String> harnessCheckIds = {'FR-007', 'FR-010'};

/// The subsections of section 4 whose requirement rows are all checks.
const Set<String> checkSections = {'4.2', '4.3', '4.4', '4.7'};

/// The check ids of the guardrail spec text [markdown] (FR-005): every id row
/// in 4.2, 4.3, 4.4 and 4.7, plus [harnessCheckIds] from 4.1, minus moved-id
/// rows (FR-087) and [exemptCheckIds]. The tables are read with the FR-071
/// parser.
Set<String> checkIdsInSpec(String markdown) {
  final ids = <String>{};
  for (final table in parseMarkdownTables(markdown)) {
    final section = table.sectionNumber;
    final inCheckSection = checkSections.contains(section);
    if (!inCheckSection && section != '4.1') continue;
    for (final row in table.rows) {
      final id = row.cell(0);
      if (id == null || !requirementIdPattern.hasMatch(id)) continue;
      if (isMovedIdRow(row) || exemptCheckIds.contains(id)) continue;
      if (inCheckSection || harnessCheckIds.contains(id)) ids.add(id);
    }
  }
  return ids;
}

/// The defects of a registry (FR-005), one line each; empty when sound.
///
/// For each id of [specIds]: an id missing from [registry] is a defect; a
/// registered id needs a fixture in [fixtures] on which its check yields a
/// Violation whose `checkId` equals the id. Registry keys and fixture keys
/// that are not check ids (or not registered) are defects too.
List<String> registryProblems({
  required Set<String> specIds,
  required Map<String, Check> registry,
  required Map<String, FixtureBuilder> fixtures,
}) {
  final problems = <String>[];
  for (final id in specIds.toList()..sort()) {
    if (!registry.containsKey(id)) {
      problems.add('$id is not in the registry');
    } else {
      final build = fixtures[id];
      if (build == null) {
        problems.add('$id has no violating fixture');
      } else {
        final found = registry[id]!(build());
        if (!found.any((v) => v.checkId == id)) {
          final seen = {for (final v in found) v.checkId}.toList()..sort();
          problems.add(
            '$id fixture yields no Violation with that id '
            '(yielded: ${seen.isEmpty ? 'none' : seen.join(', ')})',
          );
        }
      }
    }
  }
  for (final id in registry.keys.toList()..sort()) {
    if (!specIds.contains(id)) {
      problems.add('registry key $id is not a check id of the spec');
    }
  }
  for (final id in fixtures.keys.toList()..sort()) {
    if (!registry.containsKey(id)) {
      problems.add('fixture for $id has no registry entry');
    }
  }
  return problems;
}
