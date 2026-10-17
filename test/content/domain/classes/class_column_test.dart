import 'package:srd5e/src/content/domain/classes/class_column.dart';
import 'package:test/test.dart';

import '../../../support/argument_error_matcher.dart';

void main() {
  /// Requirement: doc/specs/content-classes.md FR-036 - `columns` is an
  ///   array of `{id, header, kind}`; `id` is a `ClassColumnId` (snake_case
  ///   with the id rule), `header` non-blank, `kind` one of `count`, `dice`,
  ///   `bonus`, `feetBonus`; the array may be empty (the Wizard).
  /// Path: happy
  group('ClassColumn constructor rows', () {
    /// Requirement: per case
    /// Path: per case
    for (final c in [
      (
        label: 'a declared column',
        requirement:
            'doc/specs/content-classes.md FR-036 - a column of id rages, '
            'header Rages and kind count constructs',
        path: 'happy',
        build: () => ClassColumn(
          id: ClassColumnId('rages'),
          header: 'Rages',
          kind: ClassColumnKind.count,
        ),
        throwsFor: null,
      ),
      (
        label: 'blank header',
        requirement:
            'doc/specs/content-classes.md FR-036 - a blank header is '
            'rejected',
        path: 'unhappy (invalid input)',
        build: () => ClassColumn(
          id: ClassColumnId('rages'),
          header: ' ',
          kind: ClassColumnKind.count,
        ),
        throwsFor: throwsArgumentErrorFor('header', ' '),
      ),
      (
        label: 'uppercase id',
        requirement:
            'doc/specs/content-classes.md FR-036 - an id that breaks the '
            'snake_case rule is rejected',
        path: 'unhappy (invalid input)',
        build: () => ClassColumnId('Rages'),
        throwsFor: throwsArgumentErrorFor('value', 'Rages'),
      ),
      (
        label: 'empty id',
        requirement:
            'doc/specs/content-classes.md FR-036 - an empty id is rejected',
        path: 'unhappy (boundary)',
        build: () => ClassColumnId(''),
        throwsFor: throwsArgumentErrorFor('value', ''),
      ),
      (
        label: 'too long id',
        requirement:
            'doc/specs/content-classes.md FR-036 - an id longer than 64 '
            'characters is rejected',
        path: 'unhappy (boundary)',
        build: () => ClassColumnId('a' * 65),
        throwsFor: throwsArgumentErrorFor('value', 'a' * 65),
      ),
    ]) {
      test('${c.label} [${c.path}]', () {
        if (c.throwsFor != null) {
          expect(c.build, c.throwsFor);
        } else {
          expect(c.build(), isA<Object>());
        }
      });
    }
  });

  /// Requirement: doc/specs/content-classes.md FR-036 - the kind is one of
  ///   `count`, `dice`, `bonus`, `feetBonus` (lower camel case).
  /// Path: happy
  test('the four kinds carry their lower camel case tags', () {
    expect(ClassColumnKind.values.map((k) => k.jsonValue), [
      'count',
      'dice',
      'bonus',
      'feetBonus',
    ]);
    expect(ClassColumnKind.fromJson('feetBonus'), ClassColumnKind.feetBonus);
    expect(ClassColumnKind.fromJson('Feet'), isNull);
  });

  /// Requirement: doc/specs/content-classes.md FR-036, FR-008 - an id of
  ///   exactly 64 characters is accepted; value equality holds; ids compare
  ///   by their string.
  /// Path: happy
  test('boundary id length, equality and hash', () {
    final long = ClassColumnId('a${'b' * 63}');
    expect(long.value.length, 64);
    expect(ClassColumnId('rages'), equals(ClassColumnId('rages')));
    expect(ClassColumnId('rages').hashCode, ClassColumnId('rages').hashCode);
    expect(ClassColumnId('rages').value, 'rages');
    expect(ClassColumnId('rages'), isNot(equals(ClassColumnId('rage_points'))));
  });

  /// Requirement: doc/specs/content-classes.md FR-036, FR-008 - a column
  ///   compares by id, header and kind, with a consistent hash code and the
  ///   debug form.
  /// Path: happy
  test('column equality, hash code and debug form hold', () {
    final a = ClassColumn(
      id: ClassColumnId('rages'),
      header: 'Rages',
      kind: ClassColumnKind.count,
    );
    final b = ClassColumn(
      id: ClassColumnId('rages'),
      header: 'Rages',
      kind: ClassColumnKind.count,
    );
    expect(a, equals(b));
    expect(a.hashCode, b.hashCode);
    expect(
      a,
      isNot(
        equals(
          ClassColumn(
            id: ClassColumnId('rages'),
            header: 'Rages',
            kind: ClassColumnKind.dice,
          ),
        ),
      ),
    );
    expect(a.toString(), 'ClassColumn(rages, Rages, count)');
  });
}
