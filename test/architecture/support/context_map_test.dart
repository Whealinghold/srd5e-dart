import 'package:test/test.dart';

import 'context_map.dart';

String _architecture(List<String> rows, {String header = _header}) =>
    '# Rules\n\n### Context map\n\n$header\n|---|---|---|\n'
    '${rows.join('\n')}\n';

const String _header = '| Context | Purpose | May depend on (upstream) |';

const List<String> _rows = [
  '| `content` | p | none |',
  '| `d20_test` | p | none |',
  '| `character` | p | `content`, `d20_test` |',
  '| `combat` | p | `character`, `d20_test`, `content` |',
  '| `toolbox` | p | `content`, `d20_test`, `character`, `combat` |',
];

const String _agents =
    '# Rules\n\n'
    'Current contexts (provisional). See the map.\n'
    'Second line.\n\n'
    '- `content/`: a\n'
    '- `d20_test/`: b\n\n'
    'Update this section.\n';

void main() {
  /// Requirement: doc/specs/architecture-guardrails.md FR-022 - the map is
  ///   parsed from the table: contexts, upstream sets and row lines.
  /// Path: happy
  group('ContextMap.fromTexts reads the table', () {
    final map = ContextMap.fromTexts(
      architecture: _architecture(_rows),
      agents: _agents,
    );

    /// Requirement: doc/specs/architecture-guardrails.md FR-022 - contexts in
    ///   table order, `none` meaning an empty upstream set.
    /// Path: happy
    test('lists contexts in table order with their upstream sets', () {
      expect(map.tableFound, isTrue);
      expect(map.contexts, [
        'content',
        'd20_test',
        'character',
        'combat',
        'toolbox',
      ]);
      expect(map.upstreamOf('content'), isEmpty);
      expect(map.upstreamOf('character'), {'content', 'd20_test'});
      expect(map.rowOf('combat')!.line, 10);
      expect(map.problems, isEmpty);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-019 - the upstream
    ///   test of an import is a set lookup.
    /// Path: happy
    test('mayDependOn is true only for a listed upstream', () {
      expect(map.mayDependOn('combat', 'content'), isTrue);
      expect(map.mayDependOn('content', 'combat'), isFalse);
      expect(map.mayDependOn('unknown', 'content'), isFalse);
      expect(map.upstreamOf('unknown'), isEmpty);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-098 - the leaf
    ///   contexts are the named constant limited to the map.
    /// Path: happy
    test('leaves holds toolbox, and dependantsOf shows nobody uses it', () {
      expect(map.leaves, {'toolbox'});
      expect(map.isLeaf('toolbox'), isTrue);
      expect(map.isLeaf('combat'), isFalse);
      expect(map.dependantsOf('toolbox'), isEmpty);
      expect(map.dependantsOf('d20_test'), ['character', 'combat', 'toolbox']);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-098 - a leaf
    ///   absent from the map is not a leaf of it.
    /// Path: unhappy (empty and minimal)
    test('leaves is empty when toolbox has no row', () {
      final without = ContextMap.fromTexts(
        architecture: _architecture(_rows.take(2).toList()),
      );

      expect(without.leaves, isEmpty);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-019 - transitive
    ///   upstream is used to reason about the whole map.
    /// Path: happy
    test('transitiveUpstreamOf follows edges', () {
      expect(map.transitiveUpstreamOf('combat'), {
        'character',
        'd20_test',
        'content',
      });
      expect(map.transitiveUpstreamOf('content'), isEmpty);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-022 - the
    ///   "Current contexts" list is read with its lines.
    /// Path: happy
    test('reads the AGENTS.md list and the paragraph line', () {
      expect(map.agentsListLine, 3);
      expect(
        [for (final c in map.agentsContexts) c.name],
        ['content', 'd20_test'],
      );
      expect([for (final c in map.agentsContexts) c.line], [6, 7]);
    });
  });

  /// Requirement: doc/specs/architecture-guardrails.md FR-022 - a table that
  ///   is missing, has another header or has a cell outside the format is a
  ///   problem, never an exception.
  /// Path: unhappy (invalid input)
  group('ContextMap.fromTexts reports format problems', () {
    List<String> problemsOf(String architecture) => [
      for (final p in ContextMap.fromTexts(
        architecture: architecture,
        agents: _agents,
      ).problems)
        if (p.path == architectureRulesPath) '${p.line} ${p.detail}',
    ];

    /// Requirement: doc/specs/architecture-guardrails.md FR-022 - no table at
    ///   all.
    /// Path: unhappy (missing content)
    test('no table', () {
      final map = ContextMap.fromTexts(architecture: '# Rules\n');

      expect(map.tableFound, isFalse);
      expect(map.rows, isEmpty);
      expect(map.problems.first.path, architectureRulesPath);
      expect(map.problems.first.line, 1);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-022 - a table
    ///   under "Context map" with another header is pointed at.
    /// Path: unhappy (invalid input)
    test('another header', () {
      final map = ContextMap.fromTexts(
        agents: _agents,
        architecture: _architecture(
          _rows,
          header: '| Context | Purpose | Depends on |',
        ),
      );

      expect(map.tableFound, isFalse);
      expect(map.problems.single.line, 5);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-022 - a context
    ///   cell without backticks.
    /// Path: unhappy (invalid input)
    test('a context cell without backticks drops the row', () {
      final map = ContextMap.fromTexts(
        agents: _agents,
        architecture: _architecture(['| content | p | none |']),
      );

      expect(map.tableFound, isTrue);
      expect(map.rows, isEmpty);
      expect(map.problems.single.line, 7);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-022 - an upstream
    ///   cell outside the format keeps its well-formed names.
    /// Path: unhappy (invalid input)
    test('an upstream cell with a bare name', () {
      final map = ContextMap.fromTexts(
        agents: _agents,
        architecture: _architecture([
          '| `a` | p | `b`, c |',
          '| `b` | p | none |',
        ]),
      );

      expect(map.upstreamOf('a'), {'b'});
      expect(map.problems.single.line, 7);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-022 - rows of the
    ///   wrong width, repeated contexts and a second map table.
    /// Path: unhappy (invalid input)
    test('short row, repeated context and second table', () {
      final first = _architecture([
        '| `a` | none |',
        '| `b` | p | none |',
        '| `b` | p | none |',
      ]);
      final lines = problemsOf(
        '$first\n$_header\n|---|---|---|\n| `c` | p | none |\n',
      );

      expect(lines, hasLength(3));
      expect(lines[0], startsWith('7 '));
      expect(lines[1], startsWith('9 '));
      expect(lines[2], startsWith('11 '));
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-022 - missing
    ///   files and a missing "Current contexts" paragraph.
    /// Path: unhappy (missing content)
    test('absent files and paragraph', () {
      final absent = ContextMap.fromTexts();
      final noParagraph = ContextMap.fromTexts(
        architecture: _architecture(_rows),
        agents: '# Rules\n',
      );

      expect(
        [for (final p in absent.problems) p.path],
        [architectureRulesPath, agentsPath],
      );
      expect(noParagraph.agentsListLine, isNull);
      expect(noParagraph.problems.single.path, agentsPath);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-022 - an AGENTS.md
    ///   item without a backticked `name/`.
    /// Path: unhappy (invalid input)
    test('a list item without a backticked name', () {
      final map = ContextMap.fromTexts(
        architecture: _architecture(_rows),
        agents: 'Current contexts\n\n- content: a\n- `combat/`: b\n',
      );

      expect([for (final c in map.agentsContexts) c.name], ['combat']);
      expect(map.problems.single.line, 3);
    });
  });

  /// Requirement: doc/specs/architecture-guardrails.md FR-020 - cycles are
  ///   found, a self-edge included, one closed path per cycle.
  /// Path: unhappy (invalid input)
  group('ContextMap.cycles', () {
    List<List<String>> cyclesOf(List<String> rows) =>
        ContextMap.fromTexts(architecture: _architecture(rows)).cycles();

    /// Requirement: doc/specs/architecture-guardrails.md FR-020 - the real
    ///   map shape has no cycle.
    /// Path: happy
    test('an acyclic map has none', () {
      expect(cyclesOf(_rows), isEmpty);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-020 - A to B to A.
    /// Path: unhappy (invalid input)
    test('a two-cycle', () {
      expect(cyclesOf(['| `a` | p | `b` |', '| `b` | p | `a` |']), [
        ['a', 'b', 'a'],
      ]);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-020 - a self-edge
    ///   counts as a cycle.
    /// Path: unhappy (boundary)
    test('a self-edge', () {
      expect(cyclesOf(['| `a` | p | `a` |']), [
        ['a', 'a'],
      ]);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-020 - a cycle of
    ///   three, with a bystander that is not on it.
    /// Path: unhappy (invalid input)
    test('a three-cycle leaves bystanders out', () {
      expect(
        cyclesOf([
          '| `z` | p | `a` |',
          '| `a` | p | `b` |',
          '| `b` | p | `c` |',
          '| `c` | p | `a` |',
        ]),
        [
          ['a', 'b', 'c', 'a'],
        ],
      );
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-020 - separate
    ///   cycles are reported separately, in table order.
    /// Path: unhappy (multiple violations)
    test('two separate cycles', () {
      expect(
        cyclesOf([
          '| `a` | p | `b` |',
          '| `b` | p | `a` |',
          '| `c` | p | `d` |',
          '| `d` | p | `c` |',
        ]),
        [
          ['a', 'b', 'a'],
          ['c', 'd', 'c'],
        ],
      );
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-020 - an edge to a
    ///   name with no row cannot close a cycle.
    /// Path: unhappy (boundary)
    test('an unknown upstream name is ignored', () {
      expect(cyclesOf(['| `a` | p | `ghost` |']), isEmpty);
    });
  });

  /// Requirement: doc/specs/architecture-guardrails.md FR-018, FR-021 - the
  ///   structural context of a path is the folder under lib/src/ unless it is
  ///   one of the three non-context folders.
  /// Path: happy
  group('contextOf and friends', () {
    /// Requirement: doc/specs/architecture-guardrails.md FR-018 - a file
    ///   inside a context folder belongs to that context.
    /// Path: happy
    test('a file in a context folder', () {
      expect(contextOf('lib/src/combat/domain/damage.dart'), 'combat');
      expect(contextOf('lib/src/combat/combat.dart'), 'combat');
      expect(moduleOf('lib/src/combat/combat.dart'), 'combat');
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-021 - the three
    ///   non-context folders are not contexts.
    /// Path: unhappy (boundary)
    test('the non-context folders have no context', () {
      expect(contextOf('lib/src/testing/fake.dart'), isNull);
      expect(contextOf('lib/src/shared_kernel/modifier.dart'), isNull);
      expect(contextOf('lib/src/shared_ports/adapters/x.dart'), isNull);
      expect(moduleOf('lib/src/testing/fake.dart'), 'testing');
      expect(isNonContextFolder('testing'), isTrue);
      expect(isNonContextFolder('combat'), isFalse);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-021 - a loose file
    ///   and paths outside lib/src/ have no folder.
    /// Path: unhappy (boundary)
    test('a loose file or a path outside lib/src/ has none', () {
      expect(contextOf('lib/src/loose.dart'), isNull);
      expect(moduleOf('lib/src/loose.dart'), isNull);
      expect(contextOf('lib/srd5e.dart'), isNull);
      expect(contextOf('test/combat/x.dart'), isNull);
      expect(contextOf('tool/x.dart'), isNull);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-018 - only
    ///   lib/src/X/X.dart is the barrel of X.
    /// Path: unhappy (boundary)
    test('barrelContextOf accepts only the barrel path', () {
      expect(barrelContextOf('lib/src/combat/combat.dart'), 'combat');
      expect(barrelContextOf('lib/src/combat/domain/combat.dart'), isNull);
      expect(barrelContextOf('lib/src/combat/other.dart'), isNull);
      expect(barrelContextOf('lib/src/testing/testing.dart'), isNull);
      expect(barrelPathOf('combat'), 'lib/src/combat/combat.dart');
    });
  });
}
