import 'package:test/test.dart';

import '../support/directives.dart';
import '../support/real_repository.dart';
import '../support/source_set.dart';
import '../support/violation.dart';
import 'registry.dart';

const String _specPath = 'doc/specs/architecture-guardrails.md';

const Timeout _budget = Timeout(Duration(seconds: 10));

final SourceSet _repository = realRepository;

Violation _violation(String id) =>
    Violation(checkId: id, path: 'lib/a.dart', line: 1, detail: 'x');

List<Violation> _flagsFr901(SourceSet sources) => [_violation('FR-901')];
List<Violation> _flagsFr902(SourceSet sources) => [_violation('FR-902')];
List<Violation> _flagsNothing(SourceSet sources) => const [];

SourceSet _anySet() => SourceSet({'lib/a.dart': ''});

/// A minimal guardrail-shaped spec: the given ids in each subsection.
String _spec({
  List<String> harness = const [],
  List<String> architecture = const [],
  List<String> support = const [],
  List<String> specification = const [],
  List<String> moved = const [],
}) {
  String table(List<String> ids, {String? second}) =>
      '| Id | Requirement |\n|---|---|\n'
      '${ids.map((id) => '| $id | ${second ?? 'text'} |').join('\n')}\n';
  return '# Spec\n\n## 4. Requirements\n\n'
      '### 4.1 Harness\n\n${table(harness)}\n'
      '### 4.2 Architecture checks\n\n${table(architecture)}\n'
      '### 4.5 Import legality cases\n\n'
      '| Label | Requirement |\n|---|---|\n| FR-950 | not an id row |\n\n'
      '### 4.6 Support rules\n\n${table(support)}\n'
      '### 4.7 Specification checks\n\n${table(specification)}\n'
      '### 4.8 Withdrawn ids\n\n'
      '${table(moved, second: 'Withdrawn: moved to x.md (FR-1)')}';
}

void main() {
  /// Requirement: doc/specs/architecture-guardrails.md FR-005 - the real
  ///   registry is sound: every check id of the spec is registered with a
  ///   violating fixture; no id is left pending.
  /// Path: unhappy (missing content)
  group('FR-005 meta-test on the real repository', () {
    final specText = _repository.files[_specPath];

    /// Requirement: doc/specs/architecture-guardrails.md FR-005 - an id with
    ///   no registry entry or no violating fixture is a defect.
    /// Path: unhappy (missing content)
    test('every check id is registered with a violating fixture', () {
      expect(specText, isNotNull, reason: 'missing $_specPath');
      final problems = registryProblems(
        specIds: checkIdsInSpec(specText!),
        registry: registry,
        fixtures: violatingFixtures,
      );

      expect(problems, isEmpty, reason: '\n${problems.join('\n')}');
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-005 - the ids
    ///   read from the tables must not be vacuously few.
    /// Path: unhappy (empty case)
    test('the spec tables yield the known check ids and not the others', () {
      final ids = checkIdsInSpec(specText!);

      expect(ids, containsAll(['FR-007', 'FR-010', 'FR-013', 'FR-102']));
      expect(ids, isNot(contains('FR-001')));
      expect(ids, isNot(contains('FR-058')));
      expect(ids, isNot(contains('FR-087')));
      expect(ids, isNot(contains('FR-091')));
      expect(ids, isNot(contains('FR-005')));
      expect(ids.length, greaterThan(70));
    });
  }, timeout: _budget);

  /// Requirement: doc/specs/architecture-guardrails.md FR-005 - the registry
  ///   maps FR-007 to its check and holds a violating fixture for it.
  /// Path: happy
  group('registry content', () {
    /// Requirement: doc/specs/architecture-guardrails.md FR-005, FR-007 - the
    ///   FR-007 fixture yields exactly the expected Violation.
    /// Path: happy
    test('FR-007 is registered and its fixture yields the exact Violation', () {
      expect(registry['FR-007'], same(unresolvedDirectives));

      final found = registry['FR-007']!(violatingFixtures['FR-007']!());

      expect(found, [
        const Violation(
          checkId: 'FR-007',
          path: 'lib/a.dart',
          line: 1,
          detail: 'importDirective of "missing.dart" resolves to no file',
        ),
      ]);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-005 - a check with
    ///   a clean fixture yields none, so a fixture really is what fails it.
    /// Path: happy
    test('the FR-007 check is silent on a resolving import', () {
      final clean = SourceSet({
        'lib/a.dart': "import 'b.dart';\n",
        'lib/b.dart': '',
      });

      expect(unresolvedDirectives(clean), isEmpty);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-005 - ids of
    ///   other specs are not registered, and an exempt id is not either.
    /// Path: unhappy (rule interaction)
    test('registry keys are FR ids and exclude the exempt ids', () {
      expect(registry.keys, everyElement(matches(RegExp(r'^FR-\d+$'))));
      expect(exemptCheckIds.intersection(registry.keys.toSet()), isEmpty);
    });
  });

  /// Requirement: doc/specs/architecture-guardrails.md FR-005, FR-071 - check
  ///   ids come from the spec tables of sections 4.2, 4.3, 4.4 and 4.7 plus
  ///   FR-007 and FR-010.
  /// Path: unhappy (invalid input)
  group('checkIdsInSpec', () {
    /// Requirement: doc/specs/architecture-guardrails.md FR-005 - which
    ///   sections count, and which ids are exempt.
    /// Path: unhappy (invalid input)
    test('reads checked sections, FR-007 and FR-010 only, minus exempt', () {
      final ids = checkIdsInSpec(
        _spec(
          harness: ['FR-001', 'FR-007', 'FR-010', 'FR-012'],
          architecture: ['FR-013', 'FR-014'],
          support: ['FR-087', 'FR-058'],
          specification: ['FR-091', 'FR-101'],
          moved: ['FR-040'],
        ),
      );

      expect(ids, {'FR-007', 'FR-010', 'FR-013', 'FR-014', 'FR-101'});
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-005, FR-087 - a
    ///   moved-id row is not a check, wherever it sits.
    /// Path: unhappy (state error)
    test('skips a moved-id row inside a checked section', () {
      const spec =
          '## 4. Requirements\n\n### 4.2 Architecture checks\n\n'
          '| Id | Requirement |\n|---|---|\n'
          '| FR-013 | Withdrawn: moved to x.md (FR-3) |\n'
          '| FR-014 | live |\n';

      expect(checkIdsInSpec(spec), {'FR-014'});
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-005 - a spec with
    ///   no section 4 yields no ids rather than throwing.
    /// Path: unhappy (empty case)
    test('yields no ids for a document without tables', () {
      expect(checkIdsInSpec('# Title\n\ntext'), isEmpty);
    });
  });

  /// Requirement: doc/specs/architecture-guardrails.md FR-005 - the meta-test
  ///   fails for a missing, clean-only or stray id.
  /// Path: unhappy (missing content)
  group('registryProblems', () {
    final ids = {'FR-901', 'FR-902'};
    final fixtures = <String, FixtureBuilder>{
      'FR-901': _anySet,
      'FR-902': _anySet,
    };
    final checks = <String, Check>{
      'FR-901': _flagsFr901,
      'FR-902': _flagsFr902,
    };

    /// Requirement: doc/specs/architecture-guardrails.md FR-005 - a sound
    ///   registry has no defects.
    /// Path: happy
    test('reports nothing for a sound registry', () {
      expect(
        registryProblems(specIds: ids, registry: checks, fixtures: fixtures),
        isEmpty,
      );
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-005 - an id absent
    ///   from the registry fails, even when it has a fixture.
    /// Path: unhappy (missing content)
    test('fails an id that is not in the registry', () {
      expect(
        registryProblems(
          specIds: ids,
          registry: {'FR-901': _flagsFr901},
          fixtures: {'FR-901': _anySet},
        ),
        ['FR-902 is not in the registry'],
      );
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-005 - a
    ///   registered id with no fixture fails.
    /// Path: unhappy (missing content)
    test('fails a registered id with no violating fixture', () {
      expect(
        registryProblems(
          specIds: ids,
          registry: checks,
          fixtures: {'FR-901': _anySet},
        ),
        ['FR-902 has no violating fixture'],
      );
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-005 - a fixture
    ///   on which the check yields nothing (clean only) fails.
    /// Path: unhappy (empty and minimal)
    test('fails a clean-only fixture', () {
      expect(
        registryProblems(
          specIds: {'FR-901'},
          registry: {'FR-901': _flagsNothing},
          fixtures: {'FR-901': _anySet},
        ),
        ['FR-901 fixture yields no Violation with that id (yielded: none)'],
      );
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-005 - the
    ///   Violation must carry the id itself, not another one.
    /// Path: unhappy (rule interaction)
    test('fails a fixture whose Violation has another id', () {
      expect(
        registryProblems(
          specIds: {'FR-901'},
          registry: {'FR-901': _flagsFr902},
          fixtures: {'FR-901': _anySet},
        ),
        ['FR-901 fixture yields no Violation with that id (yielded: FR-902)'],
      );
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-005 - one function
    ///   may implement several ids; each id needs its own Violation.
    /// Path: happy
    test('accepts one function shared by two ids that yields both', () {
      List<Violation> both(SourceSet s) => [
        _violation('FR-901'),
        _violation('FR-902'),
      ];

      expect(
        registryProblems(
          specIds: ids,
          registry: {'FR-901': both, 'FR-902': both},
          fixtures: fixtures,
        ),
        isEmpty,
      );
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-005 - a registry
    ///   key or fixture key that is not a check id is a defect.
    /// Path: unhappy (invalid input)
    test('fails stray registry and fixture entries', () {
      final problems = registryProblems(
        specIds: {'FR-901'},
        registry: {'FR-901': _flagsFr901, 'FR-777': _flagsFr901},
        fixtures: {'FR-901': _anySet, 'FR-888': _anySet},
      );

      expect(problems, [
        'registry key FR-777 is not a check id of the spec',
        'fixture for FR-888 has no registry entry',
      ]);
    });
  });
}
