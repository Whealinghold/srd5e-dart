import 'package:srd5e/src/content/domain/classes/feature_fact.dart';
import 'package:srd5e/src/content/domain/classes/feature_table.dart';
import 'package:srd5e/src/content/domain/feat_category.dart';
import 'package:srd5e/src/content/domain/typed_ids.dart';
import 'package:test/test.dart';

import '../../../support/argument_error_matcher.dart';

const _noGrants = <SpellGrant>[];
final _ascending = [
  SpellGrant(1, [SpellId('bless')]),
  SpellGrant(2, [SpellId('aid')]),
];
final _outOfOrder = [
  SpellGrant(5, [SpellId('bless')]),
  SpellGrant(3, [SpellId('aid')]),
];
final _repeatedLevel = [
  SpellGrant(1, [SpellId('bless')]),
  SpellGrant(1, [SpellId('aid')]),
];
final _oneGrant = [
  SpellGrant(1, [SpellId('bless')]),
];
final _duplicateSpellIds = [SpellId('bless'), SpellId('bless')];

void main() {
  /// Requirement: doc/specs/content-classes.md FR-057 - a `GrantsFeat`
  ///   category is a `FeatCategory` with its SRD spelling (SRD 5.2.1, "Parts
  ///   of a Feat: Category", p. 87).
  /// Path: happy
  test('a GrantsFeat fact carries its category', () {
    const fact = GrantsFeat(FeatCategory.general);
    expect(fact.category, FeatCategory.general);
    expect(fact, equals(const GrantsFeat(FeatCategory.general)));
    expect(fact.hashCode, const GrantsFeat(FeatCategory.general).hashCode);
    expect(fact, isNot(equals(const GrantsFeat(FeatCategory.epicBoon))));
  });

  /// Requirement: doc/specs/content-classes.md FR-058 - a grant's level is
  ///   from 1 to 20 and its spell ids non-empty and distinct (Cases FT
  ///   rows; SRD 5.2.1, "Level 3: Life Domain Spells", p. 40).
  /// Path: happy
  group('SpellGrant constructor rows', () {
    /// Requirement: per case
    /// Path: per case
    for (final c in [
      (
        label: 'a grant',
        requirement:
            'doc/specs/content-classes.md FR-058 - a grant of level 1 with '
            'one spell id constructs',
        path: 'happy',
        build: () => SpellGrant(1, [SpellId('bless')]),
        throwsFor: null,
      ),
      (
        label: 'level zero',
        requirement:
            'doc/specs/content-classes.md FR-058 - grant level 0 is '
            'rejected',
        path: 'unhappy (boundary)',
        build: () => SpellGrant(0, [SpellId('bless')]),
        throwsFor: throwsArgumentErrorFor('level', 0),
      ),
      (
        label: 'level 21',
        requirement:
            'doc/specs/content-classes.md FR-058 - grant level 21 is '
            'rejected',
        path: 'unhappy (boundary)',
        build: () => SpellGrant(21, [SpellId('bless')]),
        throwsFor: throwsArgumentErrorFor('level', 21),
      ),
      (
        label: 'level twenty',
        requirement:
            'doc/specs/content-classes.md FR-058 - the level range is '
            'inclusive: a grant at level 20 constructs',
        path: 'happy',
        build: () => SpellGrant(SpellGrant.maxLevel, [SpellId('bless')]),
        throwsFor: null,
      ),
      (
        label: 'empty spell ids',
        requirement:
            'doc/specs/content-classes.md FR-058 - empty spellIds is '
            'rejected (Cases FT: "empty spell ids")',
        path: 'unhappy (empty case)',
        build: () => SpellGrant(1, const []),
        throwsFor: throwsArgumentErrorFor('spellIds', const []),
      ),
      (
        label: 'duplicate spell id',
        requirement:
            'doc/specs/content-classes.md FR-058 - a repeated spell id is '
            'rejected',
        path: 'unhappy (boundary)',
        build: () => SpellGrant(1, _duplicateSpellIds),
        throwsFor: throwsArgumentErrorFor('spellIds', SpellId('bless')),
      ),
      (
        label: 'duplicate spell id after another',
        requirement:
            'doc/specs/content-classes.md FR-058 - a repeat is rejected '
            'wherever it sits: a repeat after a different id is rejected '
            'too',
        path: 'unhappy (boundary)',
        build: () =>
            SpellGrant(1, [SpellId('bless'), SpellId('aid'), SpellId('bless')]),
        throwsFor: throwsArgumentErrorFor('spellIds', SpellId('bless')),
      ),
    ]) {
      test('${c.label} [${c.path}]', () {
        if (c.throwsFor != null) {
          expect(c.build, c.throwsFor);
        } else {
          expect(c.build(), isA<SpellGrant>());
        }
      });
    }
  });

  /// Requirement: doc/specs/content-classes.md FR-058 - `grants` is
  ///   non-empty with strictly ascending levels (Cases FT: "grants out of
  ///   order").
  /// Path: happy
  group('AlwaysPreparedSpells constructor rows', () {
    /// Requirement: per case
    /// Path: per case
    for (final c in [
      (
        label: 'ascending grants',
        requirement:
            'doc/specs/content-classes.md FR-058 - grants at 1 then 2 '
            'construct',
        path: 'happy',
        build: () => AlwaysPreparedSpells(_ascending),
        throwsFor: null,
      ),
      (
        label: 'grants out of order',
        requirement:
            'doc/specs/content-classes.md FR-058 - grants at 5 then 3 are '
            'rejected (Cases FT: "grants out of order")',
        path: 'unhappy (boundary)',
        build: () => AlwaysPreparedSpells(_outOfOrder),
        throwsFor: throwsArgumentErrorFor('grants', 3),
      ),
      (
        label: 'repeated level',
        requirement:
            'doc/specs/content-classes.md FR-058 - levels are strictly '
            'ascending, so a repeated level is rejected',
        path: 'unhappy (boundary)',
        build: () => AlwaysPreparedSpells(_repeatedLevel),
        throwsFor: throwsArgumentErrorFor('grants', 1),
      ),
      (
        label: 'no grants',
        requirement:
            'doc/specs/content-classes.md FR-058 - an empty grants array is '
            'rejected',
        path: 'unhappy (empty case)',
        build: () => AlwaysPreparedSpells(_noGrants),
        throwsFor: throwsArgumentErrorFor('grants', _noGrants),
      ),
    ]) {
      test('${c.label} [${c.path}]', () {
        if (c.throwsFor != null) {
          expect(c.build, c.throwsFor);
        } else {
          expect(c.build(), isA<AlwaysPreparedSpells>());
        }
      });
    }
  });

  /// Requirement: doc/specs/content-classes.md FR-055 - `FeatureFact` is a
  ///   sealed class with exactly `GrantsSubclass`, `GrantsFeat` and
  ///   `AlwaysPreparedSpells`, exhaustive in a `switch` without a default;
  ///   `GrantsSubclass` is a marker.
  /// Path: happy
  test('the fact family switches exhaustively', () {
    String describe(FeatureFact fact) => switch (fact) {
      GrantsSubclass() => 'subclass',
      GrantsFeat() => 'feat',
      AlwaysPreparedSpells() => 'spells',
    };
    expect(describe(const GrantsSubclass()), 'subclass');
    expect(describe(const GrantsFeat(FeatCategory.fightingStyle)), 'feat');
    expect(describe(AlwaysPreparedSpells(_oneGrant)), 'spells');
    expect(const GrantsSubclass(), equals(const GrantsSubclass()));
    expect(const GrantsSubclass().hashCode, const GrantsSubclass().hashCode);
    expect(const GrantsSubclass().toString(), 'GrantsSubclass');
    expect(
      const GrantsFeat(FeatCategory.general).toString(),
      'GrantsFeat(General)',
    );
    final fact = AlwaysPreparedSpells(_oneGrant);
    expect(fact.hashCode, AlwaysPreparedSpells(_oneGrant).hashCode);
    expect(fact.toString(), startsWith('AlwaysPreparedSpells('));
    final grant = _oneGrant.single;
    expect(grant.hashCode, SpellGrant(1, [SpellId('bless')]).hashCode);
    expect(grant.toString(), startsWith('SpellGrant(level 1:'));
  });

  /// Requirement: doc/specs/content-classes.md FR-058, FR-008 - the grants
  ///   list is defensively copied and unmodifiable; value equality holds.
  /// Path: unhappy (immutability)
  test('grants are defensively copied, unmodifiable and equal by value', () {
    final grants = [
      SpellGrant(1, [SpellId('bless')]),
    ];
    final fact = AlwaysPreparedSpells(grants);
    grants.clear();
    expect(fact.grants.length, 1);
    expect(() => fact.grants.clear(), throwsUnsupportedError);
    expect(fact, equals(AlwaysPreparedSpells(_oneGrant)));
  });

  /// Requirement: doc/specs/content-classes.md FR-066 - a table cell is
  ///   printed text or a printed integer; the family is exhaustive.
  /// Path: happy
  test('table cells hold text or integers and switch exhaustively', () {
    String describe(TableCell cell) => switch (cell) {
      TableCellText() => 'text',
      TableCellInt() => 'int',
    };
    expect(describe(TableCellText('Beast')), 'text');
    expect(describe(const TableCellInt(2)), 'int');
    expect(() => TableCellText(' '), throwsArgumentErrorFor('text', ' '));
    expect(const TableCellInt(2), equals(const TableCellInt(2)));
  });
}
