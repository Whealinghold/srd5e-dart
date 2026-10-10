import 'package:test/test.dart';

import 'lexer.dart';
import 'test_scan.dart';

TestScan _scan(String source) => scanTests(lex(source));

typedef _DetectionCase = ({
  String label,
  String requirement,
  String path,
  String source,
  List<TestCallKind> expected,
});

const List<_DetectionCase> _detection = [
  (
    label: 'a plain test call',
    requirement: 'doc/specs/architecture-guardrails.md FR-057',
    path: 'happy',
    source: 'test("a", () {});',
    expected: [TestCallKind.test],
  ),
  (
    label: 'a call with a space before the parenthesis',
    requirement: 'doc/specs/architecture-guardrails.md FR-057',
    path: 'happy',
    source: 'test ("a", () {});',
    expected: [TestCallKind.test],
  ),
  (
    label: 'a group holding a test',
    requirement: 'doc/specs/architecture-guardrails.md FR-057',
    path: 'happy',
    source: 'group("g", () { test("t", () {}); });',
    expected: [TestCallKind.group, TestCallKind.test],
  ),
  (
    label: 'an identifier ending in test',
    requirement: 'doc/specs/architecture-guardrails.md FR-057',
    path: 'unhappy (false positive)',
    source: 'mytest("a", () {});',
    expected: [],
  ),
  (
    label: 'an identifier ending in group',
    requirement: 'doc/specs/architecture-guardrails.md FR-057',
    path: 'unhappy (false positive)',
    source: 'subgroup("a", () {});',
    expected: [],
  ),
  (
    label: 'a method named test on another object',
    requirement: 'doc/specs/architecture-guardrails.md FR-057',
    path: 'unhappy (false positive)',
    source: 'helper.test("a", () {});',
    expected: [],
  ),
  (
    label: 'a null-aware method named group',
    requirement: 'doc/specs/architecture-guardrails.md FR-057',
    path: 'unhappy (false positive)',
    source: 'helper?.group("a", () {});',
    expected: [],
  ),
  (
    label: 'a cascade method named test',
    requirement: 'doc/specs/architecture-guardrails.md FR-057',
    path: 'unhappy (false positive)',
    source: 'helper..test("a", () {});',
    expected: [],
  ),
  (
    label: 'setUp and tearDown calls',
    requirement: 'doc/specs/architecture-guardrails.md FR-057',
    path: 'unhappy (false positive)',
    source: 'setUp(() {}); tearDown(() {}); setUpAll(() {});',
    expected: [],
  ),
  (
    label: 'a testOn argument is not a test',
    requirement: 'doc/specs/architecture-guardrails.md FR-057',
    path: 'unhappy (false positive)',
    source: 'test("a", () {}, testOn: "vm");',
    expected: [TestCallKind.test],
  ),
  (
    label: 'a function declared with void',
    requirement: 'doc/specs/architecture-guardrails.md FR-057',
    path: 'unhappy (false positive)',
    source: 'void test(String name) {}',
    expected: [],
  ),
  (
    label: 'a call inside a line comment',
    requirement: 'doc/specs/architecture-guardrails.md FR-057',
    path: 'unhappy (false positive)',
    source: '// test("a", () {});',
    expected: [],
  ),
  (
    label: 'a call inside a string',
    requirement: 'doc/specs/architecture-guardrails.md FR-057',
    path: 'unhappy (false positive)',
    source: 'final s = "test(1)";',
    expected: [],
  ),
];

typedef _LoopCase = ({
  String label,
  String requirement,
  String path,
  String source,
  List<LoopKind> expected,
});

const List<_LoopCase> _loops = [
  (
    label: 'a for-in loop with a block body',
    requirement: 'doc/specs/architecture-guardrails.md FR-066',
    path: 'happy',
    source: 'for (final c in cs) { test("a", () {}); }',
    expected: [LoopKind.forStatement],
  ),
  (
    label: 'a for loop with a single statement body',
    requirement: 'doc/specs/architecture-guardrails.md FR-066',
    path: 'happy',
    source: 'for (var i = 0; i < 3; i++) test("a", () {});',
    expected: [LoopKind.forStatement],
  ),
  (
    label: 'an await for loop',
    requirement: 'doc/specs/architecture-guardrails.md FR-066',
    path: 'happy',
    source: 'await for (final c in s) { test("a", () {}); }',
    expected: [LoopKind.forStatement],
  ),
  (
    label: 'a collection for element',
    requirement: 'doc/specs/architecture-guardrails.md FR-066',
    path: 'happy',
    source: 'final t = [for (final c in cs) test("a", () {})];',
    expected: [LoopKind.forStatement],
  ),
  (
    label: 'the closure passed to forEach',
    requirement: 'doc/specs/architecture-guardrails.md FR-066',
    path: 'happy',
    source: 'cs.forEach((c) { test("a", () {}); });',
    expected: [LoopKind.forEach],
  ),
  (
    label: 'the closure passed to map',
    requirement: 'doc/specs/architecture-guardrails.md FR-066',
    path: 'happy',
    source: 'cs.map((c) => test("a", () {}));',
    expected: [LoopKind.map],
  ),
  (
    label: 'nested loops list the innermost first',
    requirement: 'doc/specs/architecture-guardrails.md FR-066',
    path: 'unhappy (rule interaction)',
    source: 'for (final a in b) { cs.forEach((c) { test("a", () {}); }); }',
    expected: [LoopKind.forEach, LoopKind.forStatement],
  ),
  (
    label: 'List.generate is not recognised',
    requirement: 'doc/specs/architecture-guardrails.md FR-066',
    path: 'unhappy (invalid input)',
    source: 'List.generate(3, (i) => test("a", () {}));',
    expected: [],
  ),
  (
    label: 'Iterable.expand is not recognised',
    requirement: 'doc/specs/architecture-guardrails.md FR-066',
    path: 'unhappy (invalid input)',
    source: 'cs.expand((c) => [test("a", () {})]);',
    expected: [],
  ),
  (
    label: 'a test after a loop is outside it',
    requirement: 'doc/specs/architecture-guardrails.md FR-066',
    path: 'unhappy (boundary)',
    source: 'for (final c in cs) { use(c); } test("a", () {});',
    expected: [],
  ),
  (
    label: 'a test after a single statement loop is outside it',
    requirement: 'doc/specs/architecture-guardrails.md FR-066',
    path: 'unhappy (boundary)',
    source: 'for (final c in cs) use(c);\ntest("a", () {});',
    expected: [],
  ),
  (
    label: 'a for text inside a string is not a loop',
    requirement: 'doc/specs/architecture-guardrails.md FR-066',
    path: 'unhappy (false positive)',
    source: 'final s = "for (x in y) {"; test("a", () {});',
    expected: [],
  ),
];

void main() {
  group('call detection', () {
    /// Requirement: per case
    /// Path: per case
    for (final c in _detection) {
      test('${c.label} [${c.path}]', () {
        final scan = _scan(c.source);

        expect([for (final call in scan.calls) call.kind], c.expected);
      });
    }

    /// Requirement: doc/specs/architecture-guardrails.md FR-057 - the groups
    ///   around a test are listed innermost first, and the call records its
    ///   1-based line.
    /// Path: happy
    test('a test lists its enclosing groups innermost first', () {
      final scan = _scan(
        'group("outer", () {\n'
        '  group("inner", () {\n'
        '    test("t", () {});\n'
        '  });\n'
        '});\n',
      );

      final call = scan.calls.last;
      expect(call.kind, TestCallKind.test);
      expect(call.line, 3);
      expect([for (final g in call.groups) g.line], [2, 1]);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-057 - the
    ///   innermost call around an offset is the one whose arguments hold it.
    /// Path: happy
    test('innermostCallAt finds the nearest call', () {
      const source = 'group("g", () { test("t", () { x; }); });';
      final scan = _scan(source);

      final inside = scan.innermostCallAt(source.indexOf('x;'));
      final outside = scan.innermostCallAt(source.indexOf('test'));

      expect(inside?.kind, TestCallKind.test);
      expect(outside?.kind, TestCallKind.group);
      expect(scan.innermostCallAt(0), isNull);
    });
  });

  group('loop recognition', () {
    /// Requirement: per case
    /// Path: per case
    for (final c in _loops) {
      test('${c.label} [${c.path}]', () {
        final scan = _scan(c.source);

        expect([
          for (final loop in scan.calls.single.loops) loop.kind,
        ], c.expected);
      });
    }

    /// Requirement: doc/specs/architecture-guardrails.md FR-066 - a loop with
    ///   no test inside is still listed, and reports that it holds none.
    /// Path: unhappy (empty and minimal)
    test('a loop without a test holds none', () {
      final scan = _scan('for (final c in cs) { use(c); }');

      expect(scan.loops, hasLength(1));
      expect(scan.loopHasTest(scan.loops.single), isFalse);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-066 - loops inside
    ///   a group's arguments that hold a test are listed for that group.
    /// Path: happy
    test('loopsInside lists the loops with a test in a group', () {
      final scan = _scan(
        'group("g", () {\n'
        '  for (final c in cs) { test("a", () {}); }\n'
        '  for (final c in cs) { use(c); }\n'
        '});\n',
      );

      final group = scan.calls.first;

      expect(scan.loopsInside(group), hasLength(1));
      expect(scan.loopsInside(group).single.line, 2);
    });
  });

  group('doc comment attachment', () {
    /// Requirement: doc/specs/architecture-guardrails.md FR-049 - the block
    ///   that ends on the line above a test belongs to it.
    /// Path: happy
    test('a block directly above a test is its comment', () {
      final scan = _scan(
        '/// Requirement: a\n'
        '///   continued\n'
        '/// Path: happy\n'
        'test("t", () {});\n',
      );

      final comment = scan.calls.single.comment;
      expect(comment?.startLine, 1);
      expect(comment?.endLine, 3);
      expect(comment?.fieldValue('Requirement'), 'a continued');
      expect(comment?.fieldValue('Path'), 'happy');
      expect(comment?.fieldLine('Path'), 3);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-049 - a blank line
    ///   between the block and the test detaches it.
    /// Path: unhappy (boundary)
    test('a blank line detaches the block', () {
      final scan = _scan('/// Requirement: a\n\ntest("t", () {});\n');

      expect(scan.calls.single.comment, isNull);
      expect(scan.blocks, hasLength(1));
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-049 - a test that
    ///   shares its line with other code owns no comment.
    /// Path: unhappy (boundary)
    test('a test not first on its line has no comment', () {
      final scan = _scan('/// Requirement: a\nuse(); test("t", () {});\n');

      expect(scan.calls.single.comment, isNull);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-051 - a block
    ///   above a for loop is the loop's comment, and a test inside owns none.
    /// Path: happy
    test('a block above a for loop is the loop comment', () {
      final scan = _scan(
        '/// Requirement: per case\n'
        'for (final c in cs) {\n'
        '  test("t", () {});\n'
        '}\n',
      );

      expect(scan.loops.single.comment?.fieldValue('Requirement'), 'per case');
      expect(scan.loops.single.line, 2);
      expect(scan.calls.single.comment, isNull);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-051 - a loop
    ///   written as a method chain takes the comment above its first line.
    /// Path: happy
    test('a block above a chained forEach is the loop comment', () {
      final scan = _scan(
        '/// Requirement: per case\n'
        'cases\n'
        '    .forEach((c) { test("t", () {}); });\n',
      );

      expect(scan.loops.single.line, 2);
      expect(scan.loops.single.comment, isNotNull);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-051 - an await
    ///   for loop takes the comment above the await.
    /// Path: happy
    test('a block above an await for is the loop comment', () {
      final scan = _scan(
        '/// Requirement: per case\n'
        'await for (final c in s) { test("t", () {}); }\n',
      );

      expect(scan.loops.single.line, 2);
      expect(scan.loops.single.comment, isNotNull);
    });
  });

  group('doc blocks', () {
    /// Requirement: doc/specs/architecture-guardrails.md FR-053 - consecutive
    ///   doc lines form one block; a gap starts another.
    /// Path: happy
    test('blocks split at gaps and plain comments', () {
      final blocks = docBlocksOf(
        lex('/// a\n/// b\n\n/// c\n// plain\n/// d\n'),
      );

      expect(
        [for (final b in blocks) (b.startLine, b.endLine)],
        [(1, 2), (4, 4), (6, 6)],
      );
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-053 - a field with
    ///   no value reads as empty, an absent field as null.
    /// Path: unhappy (empty and minimal)
    test('fieldValue tells an empty field from an absent one', () {
      final block = docBlocksOf(
        lex('/// Requirement:\n/// Path: happy\n'),
      ).single;

      expect(block.fieldValue('Requirement'), '');
      expect(block.fieldValue('Rule'), isNull);
      expect(block.hasField('Path'), isTrue);
      expect(block.hasField('Rule'), isFalse);
    });
  });
}
