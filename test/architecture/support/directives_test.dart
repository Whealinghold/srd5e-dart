import 'package:test/test.dart';

import 'directives.dart';
import 'source_set.dart';

/// Builds a source set from [source] (at [path]) and [others], and returns the
/// directives of [path].
List<Directive> _directives(
  String path,
  String source, {
  Map<String, String> others = const {},
}) {
  final sources = SourceSet({path: source, ...others});
  return directivesOf(sources, path);
}

void main() {
  /// Requirement: doc/specs/architecture-guardrails.md FR-006 - import,
  ///   export and part are edges, resolved to repository paths.
  /// Path: happy
  group('directive extraction', () {
    /// Requirement: doc/specs/architecture-guardrails.md FR-006 - import,
    ///   export and part directives are all edges, in source order, with their
    ///   line.
    /// Path: happy
    test('reads import, export and part with kind and line', () {
      final found = _directives('lib/src/a/x.dart', '''
import 'dart:core';
export 'y.dart';

part 'z.dart';
''');

      expect(found.map((d) => d.kind), [
        DirectiveKind.importDirective,
        DirectiveKind.exportDirective,
        DirectiveKind.partDirective,
      ]);
      expect(found.map((d) => d.uri), ['dart:core', 'y.dart', 'z.dart']);
      expect(found.map((d) => d.line), [1, 2, 4]);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-006 - a
    ///   `package:srd5e/` URI resolves under `lib/`.
    /// Path: happy
    test('resolves a package URI under lib', () {
      final found = _directives(
        'test/x_test.dart',
        "import 'package:srd5e/src/a/a.dart';",
        others: {'lib/src/a/a.dart': ''},
      ).single;

      expect(found.isLocal, isTrue);
      expect(found.resolvedPath, 'lib/src/a/a.dart');
      expect(found.exists, isTrue);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-006 - a relative
    ///   URI resolves against the importing file's directory, with `..` and
    ///   `.` segments.
    /// Path: happy
    test('resolves relative URIs including parent segments', () {
      final found = _directives(
        'lib/src/a/domain/x.dart',
        "import '../a.dart';\nimport './y.dart';\nimport '../../b/b.dart';",
        others: {
          'lib/src/a/a.dart': '',
          'lib/src/a/domain/y.dart': '',
          'lib/src/b/b.dart': '',
        },
      );

      expect(found.map((d) => d.resolvedPath), [
        'lib/src/a/a.dart',
        'lib/src/a/domain/y.dart',
        'lib/src/b/b.dart',
      ]);
      expect(found.map((d) => d.exists), [true, true, true]);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-006 - a file at
    ///   the repository root resolves a relative URI to a root path.
    /// Path: happy
    test('resolves a relative URI from a root-level file', () {
      final found = _directives('build_x.dart', "import 'tool/t.dart';").single;

      expect(found.resolvedPath, 'tool/t.dart');
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-006 - dart: and
    ///   other-package URIs are not local edges and have no resolved path.
    /// Path: unhappy (boundary)
    test('dart: and foreign package URIs are not local', () {
      final found = _directives('lib/a.dart', '''
import 'dart:io';
import 'package:meta/meta.dart';
import 'package:srd5e_other/x.dart';
''');

      expect(found.map((d) => d.isLocal), [false, false, false]);
      expect(found.map((d) => d.resolvedPath), [null, null, null]);
      expect(found.map((d) => d.exists), [false, false, false]);
      expect(found.first.isDartLibrary, isTrue);
      expect(found[1].isPackage, isTrue);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-006 - `part of`
    ///   with a URI is an edge; `part of name;` names no file and is not.
    /// Path: unhappy (boundary)
    test('part of with a URI is an edge, part of a name is not', () {
      final found = _directives('lib/src/p.dart', '''
part of 'q.dart';
part of some.library;
''');

      expect(found.map((d) => d.kind), [DirectiveKind.partOfDirective]);
      expect(found.single.uri, 'q.dart');
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-006 - an
    ///   identifier named `part` or `export` is not a directive.
    /// Path: unhappy (false positive)
    test('identifiers named like directive keywords are ignored', () {
      final found = _directives('lib/a.dart', '''
void f() {
  var part = 'x';
  final export = part;
  print(export);
}
''');

      expect(found, isEmpty);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-006 - a file with
    ///   no directive yields no edge.
    /// Path: unhappy (empty case)
    test('an empty file has no directives', () {
      expect(_directives('lib/a.dart', ''), isEmpty);
    });
  });

  /// Requirement: doc/specs/architecture-guardrails.md FR-060 - show, hide,
  ///   as and deferred as clauses, and directives split over lines.
  /// Path: happy
  group('directive clauses and layout', () {
    /// Requirement: doc/specs/architecture-guardrails.md FR-060 - show and
    ///   hide lists are read, several combinators on one directive.
    /// Path: happy
    test('reads show and hide name lists', () {
      final found = _directives('lib/a.dart', '''
export 'b.dart' show A, B hide C;
import 'c.dart' hide D;
''');

      expect(found[0].shown, ['A', 'B']);
      expect(found[0].hidden, ['C']);
      expect(found[1].shown, isEmpty);
      expect(found[1].hidden, ['D']);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-060 - `as` and
    ///   `deferred as` prefixes.
    /// Path: happy
    test('reads as and deferred as prefixes', () {
      final found = _directives('lib/a.dart', '''
import 'b.dart' as b;
import 'c.dart' deferred as c show X;
''');

      expect(found[0].prefix, 'b');
      expect(found[0].isDeferred, isFalse);
      expect(found[1].prefix, 'c');
      expect(found[1].isDeferred, isTrue);
      expect(found[1].shown, ['X']);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-060 - a directive
    ///   split across several lines is one edge, at the keyword's line.
    /// Path: happy
    test('a multi-line directive is one edge at the keyword line', () {
      final found = _directives('lib/a.dart', '''
// header
import
    'b.dart'
    as
    b
    show
    X,
    Y;
export 'c.dart';
''');

      expect(found.map((d) => d.uri), ['b.dart', 'c.dart']);
      expect(found.map((d) => d.line), [2, 9]);
      expect(found.first.prefix, 'b');
      expect(found.first.shown, ['X', 'Y']);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-060 - adjacent
    ///   string literals, a raw literal and triple quotes still give one URI.
    /// Path: unhappy (boundary)
    test('adjacent and raw literals form one URI', () {
      final found = _directives('lib/a.dart', '''
import 'b'
    '.dart';
import r'c.dart';
import """d.dart""";
''');

      expect(found.map((d) => d.uri), ['b.dart', 'c.dart', 'd.dart']);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-060 - directives
    ///   after a library declaration and with no trailing newline are read.
    /// Path: unhappy (boundary)
    test('reads directives after a library declaration and at end of file', () {
      final found = _directives('lib/a.dart', '''
library;

import 'b.dart';
export 'c.dart';''');

      expect(found.map((d) => d.uri), ['b.dart', 'c.dart']);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-060 - a missing
    ///   semicolon at the end of the file does not crash or lose the edge.
    /// Path: unhappy (invalid input)
    test('an unterminated directive keeps its URI', () {
      final found = _directives('lib/a.dart', "import 'b.dart'");

      expect(found.single.uri, 'b.dart');
    });
  });

  /// Requirement: doc/specs/architecture-guardrails.md FR-064 - every URI of
  ///   a conditional configuration is an edge, with the default URI.
  /// Path: happy
  group('conditional configurations', () {
    /// Requirement: doc/specs/architecture-guardrails.md FR-064 - the default
    ///   URI and each `if` URI are edges; only the latter are conditional.
    /// Path: happy
    test('returns the default and every configured URI', () {
      final found = _directives('lib/a.dart', '''
import 'stub.dart'
    if (dart.library.io) 'io.dart'
    if (dart.library.js_interop) 'web.dart';
''');

      expect(found.map((d) => d.uri), ['stub.dart', 'io.dart', 'web.dart']);
      expect(found.map((d) => d.isConditional), [false, true, true]);
      expect(found.map((d) => d.line), [1, 2, 3]);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-064 - a
    ///   comparison value inside the condition (`== 'true'`) is not an edge,
    ///   and clauses after the configurations are still read.
    /// Path: unhappy (false positive)
    test('a condition value is not a URI and clauses still apply', () {
      final found = _directives('lib/a.dart', '''
export 'stub.dart'
    if (dart.library.io == 'true') 'io.dart'
    show Thing;
''');

      expect(found.map((d) => d.uri), ['stub.dart', 'io.dart']);
      expect(found.map((d) => d.shown), [
        ['Thing'],
        ['Thing'],
      ]);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-064 - a configured
    ///   URI is resolved against the source set like the default one.
    /// Path: unhappy (invalid input)
    test('a configured URI is resolved against the source set', () {
      final found = _directives(
        'lib/a.dart',
        "import 'stub.dart' if (dart.library.io) 'io.dart';",
        others: {'lib/stub.dart': ''},
      );

      expect(found.map((d) => d.exists), [true, false]);
    });
  });

  /// Requirement: doc/specs/architecture-guardrails.md FR-065 - directives
  ///   come from the lexer's code, so comments and strings give no edge.
  /// Path: unhappy (false positive)
  group('lexer-based extraction', () {
    /// Requirement: doc/specs/architecture-guardrails.md FR-065 - a directive
    ///   in a line, doc or block comment is not an edge.
    /// Path: unhappy (false positive)
    test('directives in comments are ignored', () {
      final found = _directives('lib/a.dart', '''
// import 'dart:io';
/// import 'dart:io';
/* import 'dart:io';
export 'x.dart'; */
import 'real.dart'; // import 'dart:ui';
''');

      expect(found.map((d) => d.uri), ['real.dart']);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-065 - a directive
    ///   inside a string (single, triple, raw, interpolation) is not an edge.
    /// Path: unhappy (false positive)
    test('directives in strings are ignored', () {
      final found = _directives('lib/a.dart', r"""
const a = "import 'dart:io';";
const b = '''
import 'dart:ui';
''';
const c = r'export "x.dart";';
""");

      expect(found, isEmpty);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-065 - a comment
    ///   between the keyword and the URI does not hide the edge.
    /// Path: unhappy (boundary)
    test('a comment inside a directive is skipped', () {
      final found = _directives('lib/a.dart', '''
import /* why */ 'b.dart' // trailing
    as b;
''');

      expect(found.single.uri, 'b.dart');
      expect(found.single.prefix, 'b');
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-065 - the URI
    ///   text comes from the string-literal list, so an escape is resolved.
    /// Path: happy
    test('the URI text is the literal value', () {
      final found = _directives('lib/a.dart', r"import 'ab.dart';");

      expect(found.single.uri, 'ab.dart');
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-065 - an
    ///   interpolated URI cannot name a file, so FR-007 flags it.
    /// Path: unhappy (invalid input)
    test('an interpolated URI is local and does not exist', () {
      final found = _directives('lib/a.dart', r"import 'a$x.dart';").single;

      expect(found.isLocal, isTrue);
      expect(found.exists, isFalse);
      expect(found.resolvedPath, isNull);
    });
  });

  /// Requirement: doc/specs/architecture-guardrails.md FR-007 - a local URI
  ///   that names no file of the source set is a Violation.
  /// Path: unhappy (invalid input)
  group('unresolvedDirectives', () {
    /// Requirement: doc/specs/architecture-guardrails.md FR-007 - a typo in a
    ///   relative or package URI is reported with id, path and line.
    /// Path: unhappy (invalid input)
    test('reports each unresolved local URI with path and line', () {
      final sources = SourceSet({
        'lib/a.dart':
            "import 'b.dart';\nimport 'typo.dart';\n"
            "export 'package:srd5e/src/nope.dart';\n",
        'lib/b.dart': '',
      });

      final violations = unresolvedDirectives(sources);

      expect(violations.map((v) => '${v.path}:${v.line} ${v.checkId}'), [
        'lib/a.dart:2 FR-007',
        'lib/a.dart:3 FR-007',
      ]);
      expect(violations.first.detail, contains('typo.dart'));
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-007 - a URI that
    ///   leaves the repository root resolves to no file.
    /// Path: unhappy (boundary)
    test('a URI above the repository root is a violation', () {
      final violations = unresolvedDirectives(
        SourceSet({'lib/a.dart': "import '../../outside.dart';"}),
      );

      expect(violations, hasLength(1));
      expect(violations.single.line, 1);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-007 - files
    ///   outside lib/ resolve, so `../tool/x.dart` is not a violation, and
    ///   dart:/foreign package URIs are never reported.
    /// Path: happy
    test('resolves into tool/ and ignores non-local URIs', () {
      final violations = unresolvedDirectives(
        SourceSet({
          'test/t.dart':
              "import '../tool/x.dart';\nimport 'dart:io';\n"
              "import 'package:test/test.dart';\n",
          'tool/x.dart': '',
        }),
      );

      expect(violations, isEmpty);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-007 - a URI naming
    ///   a binary or unreadable file still exists, so it is not a typo.
    /// Path: unhappy (boundary)
    test('a binary or unreadable target counts as existing', () {
      final violations = unresolvedDirectives(
        SourceSet(
          {'lib/a.dart': "import 'bin.dart';\nimport 'bad.dart';\n"},
          binaryPaths: ['lib/bin.dart'],
          unreadable: {'lib/bad.dart': 'not valid UTF-8'},
        ),
      );

      expect(violations, isEmpty);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-007 - violations
    ///   come back sorted by path and line, whatever the file order.
    /// Path: unhappy (determinism)
    test('violations are sorted by path then line', () {
      final violations = unresolvedDirectives(
        SourceSet({
          'lib/z.dart': "import 'nope.dart';\n",
          'lib/a.dart': "\nimport 'q.dart';\nimport 'r.dart';\n",
        }),
      );

      expect(violations.map((v) => '${v.path}:${v.line}'), [
        'lib/a.dart:2',
        'lib/a.dart:3',
        'lib/z.dart:1',
      ]);
    });
  });

  /// Requirement: doc/specs/architecture-guardrails.md FR-080 - the raw edges
  ///   a barrel-import check needs are available per path prefix.
  /// Path: happy
  group('allDirectives', () {
    /// Requirement: doc/specs/architecture-guardrails.md FR-080 - edges are
    ///   listed per Dart file under a prefix with their resolved paths, so a
    ///   file importing its own barrel can be found.
    /// Path: happy
    test('lists edges of Dart files under a prefix only', () {
      final sources = SourceSet({
        'lib/src/a/domain/x.dart': "import '../a.dart';\n",
        'lib/src/a/a.dart': "export 'domain/x.dart';\n",
        'test/t.dart': "import 'x.dart';\n",
        'lib/src/a/notes.md': "import 'zzz.dart';\n",
      });

      final found = allDirectives(sources, prefix: 'lib/src/a/');

      expect(found.map((d) => '${d.from} -> ${d.resolvedPath}'), [
        'lib/src/a/a.dart -> lib/src/a/domain/x.dart',
        'lib/src/a/domain/x.dart -> lib/src/a/a.dart',
      ]);
    });
  });

  /// Requirement: doc/specs/architecture-guardrails.md FR-006 - resolution of
  ///   a URI to a repository path.
  /// Path: happy
  group('resolveLocalUri', () {
    const cases =
        <
          ({
            String label,
            String requirement,
            String path,
            String from,
            String uri,
            String? want,
          })
        >[
          (
            label: 'sibling file',
            requirement: 'doc/specs/architecture-guardrails.md FR-006',
            path: 'happy',
            from: 'lib/a/b.dart',
            uri: 'c.dart',
            want: 'lib/a/c.dart',
          ),
          (
            label: 'package URI',
            requirement: 'doc/specs/architecture-guardrails.md FR-006',
            path: 'happy',
            from: 'test/t.dart',
            uri: 'package:srd5e/srd5e.dart',
            want: 'lib/srd5e.dart',
          ),
          (
            label: 'climbs to the root exactly',
            requirement: 'doc/specs/architecture-guardrails.md FR-006',
            path: 'unhappy (boundary)',
            from: 'lib/a.dart',
            uri: '../pubspec.yaml',
            want: 'pubspec.yaml',
          ),
          (
            label: 'climbs one past the root',
            requirement: 'doc/specs/architecture-guardrails.md FR-007',
            path: 'unhappy (boundary)',
            from: 'lib/a.dart',
            uri: '../../x.dart',
            want: null,
          ),
          (
            label: 'absolute path',
            requirement: 'doc/specs/architecture-guardrails.md FR-007',
            path: 'unhappy (invalid input)',
            from: 'lib/a.dart',
            uri: '/x.dart',
            want: null,
          ),
          (
            label: 'empty URI',
            requirement: 'doc/specs/architecture-guardrails.md FR-007',
            path: 'unhappy (invalid input)',
            from: 'lib/a.dart',
            uri: '',
            want: null,
          ),
          (
            label: 'percent-encoded segment',
            requirement: 'doc/specs/architecture-guardrails.md FR-006',
            path: 'unhappy (boundary)',
            from: 'lib/a.dart',
            uri: 'my%20file.dart',
            want: 'lib/my file.dart',
          ),
        ];

    /// Requirement: per case
    /// Path: per case
    for (final c in cases) {
      test('${c.label} [${c.path}]', () {
        expect(resolveLocalUri(c.from, c.uri), c.want);
      });
    }
  });
}
