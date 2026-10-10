import 'package:test/test.dart';

import 'gitignore.dart';

bool _dir(String rules, String path) =>
    GitignoreRules.parse(rules).excludes(path, isDirectory: true);

bool _file(String rules, String path) =>
    GitignoreRules.parse(rules).excludes(path);

void main() {
  group('GitignoreRules', () {
    /// Requirement: doc/specs/architecture-guardrails.md FR-079 - a trailing
    ///   `/` pattern excludes the directory.
    /// Path: happy
    test('doc/research/ excludes the directory', () {
      expect(_dir('doc/research/\n', 'doc/research'), isTrue);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-079 - a trailing
    ///   `/` matches directories only, not a file of that name.
    /// Path: unhappy (boundary)
    test('a trailing slash does not match a file', () {
      expect(_file('research/\n', 'doc/research'), isFalse);
      expect(_dir('research/\n', 'doc/research'), isTrue);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-079 - an excluded
    ///   parent excludes its content, and `!` cannot bring it back.
    /// Path: unhappy (rule interaction)
    test('a parent directory excluded excludes its content', () {
      expect(_dir('doc/\n', 'doc/research'), isTrue);
      expect(_file('doc/\n', 'doc/research/sources.md'), isTrue);
      expect(_dir('doc/\n!doc/research/\n', 'doc/research'), isTrue);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-079 - later lines
    ///   win and `!` negates.
    /// Path: unhappy (rule interaction)
    test('doc/* then !doc/research/ re-includes the directory', () {
      expect(_dir('doc/*\n!doc/research/\n', 'doc/research'), isFalse);
      expect(_dir('!doc/research/\ndoc/*\n', 'doc/research'), isTrue);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-079 - a leading
    ///   `/` anchors to the root; an unanchored name matches at any depth.
    /// Path: unhappy (boundary)
    test('leading slash anchors, a bare name matches at any depth', () {
      expect(_dir('/research/\n', 'doc/research'), isFalse);
      expect(_dir('/doc/\n', 'doc'), isTrue);
      expect(_dir('research\n', 'doc/research'), isTrue);
      expect(_dir('doc/research\n', 'a/doc/research'), isFalse);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-079 - `*` stays in
    ///   one segment and `**` crosses segments.
    /// Path: unhappy (boundary)
    test('star and double star', () {
      expect(_file('*.md\n', 'doc/a.md'), isTrue);
      expect(_file('doc/*.md\n', 'doc/x/a.md'), isFalse);
      expect(_file('doc/**/a.md\n', 'doc/x/y/a.md'), isTrue);
      expect(_file('doc/**/a.md\n', 'doc/a.md'), isTrue);
      expect(_file('doc/**\n', 'doc/x/a.md'), isTrue);
    });

    /// Requirement: doc/specs/architecture-guardrails.md FR-079 - comments and
    ///   blank lines are ignored; empty rules exclude nothing.
    /// Path: unhappy (empty and minimal)
    test('comments, blanks and the empty file exclude nothing', () {
      expect(_dir('# doc/research/\n\n', 'doc/research'), isFalse);
      expect(_dir('', 'doc/research'), isFalse);
      expect(_dir('doc/research/  \r\n', 'doc/research'), isTrue);
    });
  });
}
