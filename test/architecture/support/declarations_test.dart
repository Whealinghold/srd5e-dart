import 'package:test/test.dart';

import 'declarations.dart';
import 'lexer.dart';

List<Declaration> _parse(String source) =>
    declarationsIn('lib/src/x.dart', lex(source));

void main() {
  /// Requirement: doc/specs/errors-and-results.md section 8 - the checks read
  ///   class declarations from the lexer's code (support code, no rule).
  /// Path: happy
  group('declarationsIn', () {
    /// Requirement: doc/specs/errors-and-results.md FR-001 - modifiers and
    ///   supertypes of `abstract base class` and `final class` are read.
    /// Path: happy
    test('reads modifiers, extends, implements and with', () {
      final declarations = _parse('''
abstract base class A implements Exception {}
final class B<T> extends A with M implements C<T>, D {}
sealed class S {}
''');

      expect(declarations.map((d) => d.name), ['A', 'B', 'S']);
      expect(declarations[0].modifiers, {'abstract', 'base'});
      expect(declarations[0].supertypes, ['Exception']);
      expect(declarations[1].modifiers, {'final'});
      expect(declarations[1].extendsName, 'A');
      expect(declarations[1].supertypes, ['A', 'M', 'C', 'D']);
      expect(declarations[2].modifiers, {'sealed'});
    });

    /// Requirement: doc/specs/errors-and-results.md FR-007 - fields and
    ///   getters are found; constructor parameters, methods and nested bodies
    ///   are not members.
    /// Path: happy
    test('finds fields and getters but not parameters or methods', () {
      final declarations = _parse('''
final class A {
  const A(this.message, {required this.text});
  final String message;
  final int? text;
  String get description => 'x';
  String get displayText {
    return 'y';
  }
  void shout(String message) {
    final inner = message;
  }
  final Map<String, int> path = {};
}
''');

      expect(declarations.single.memberNames.map((m) => m.name), [
        'message',
        'text',
        'description',
        'displayText',
        'path',
      ]);
      expect(declarations.single.memberNames.first.line, 3);
    });

    /// Requirement: doc/specs/errors-and-results.md FR-020 - enum constants
    ///   are not members, but fields declared after them are.
    /// Path: unhappy (false positive)
    test('an enum constant named text is not a member', () {
      final declarations = _parse('''
enum Reason {
  text,
  message;

  final int code = 1;
}
''');

      expect(declarations.single.kind, DeclarationKind.enumDeclaration);
      expect(declarations.single.memberNames.map((m) => m.name), ['code']);
    });

    /// Requirement: doc/specs/errors-and-results.md section 8 - a declaration
    ///   inside a comment or a string is not a declaration.
    /// Path: unhappy (false positive)
    test('ignores declarations in comments and strings', () {
      final declarations = _parse('''
// final class A extends Srd5eException {}
const s = 'final class B extends Srd5eException {}';
''');

      expect(declarations, isEmpty);
    });
  });
}
