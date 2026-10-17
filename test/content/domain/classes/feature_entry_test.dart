import 'package:srd5e/src/content/domain/classes/feature_entry.dart';
import 'package:srd5e/src/content/domain/classes/feature_fact.dart';
import 'package:srd5e/src/content/domain/classes/feature_option.dart';
import 'package:srd5e/src/content/domain/feat_category.dart';
import 'package:srd5e/src/content/domain/typed_ids.dart';
import 'package:test/test.dart';

import '../../../support/argument_error_matcher.dart';

FeatureEntry _entry({
  String id = 'barbarian_rage',
  String name = 'Rage',
  int level = 1,
  List<FeatureFact> facts = const [],
  List<FeatureOption> options = const [],
}) => FeatureEntry(
  id: FeatureId(id),
  name: name,
  level: level,
  text: 'In battle, you fight with primal ferocity.',
  facts: facts,
  options: options,
);

AlwaysPreparedSpells _grantAt(int level) => AlwaysPreparedSpells([
  SpellGrant(level, [SpellId('bless')]),
]);

FeatureOption _option(String id, {OptionPrerequisite? prerequisite}) =>
    FeatureOption(
      id: FeatureOptionId(id),
      name: 'Option',
      text: 'An option of the list.',
      prerequisite: prerequisite,
    );

void main() {
  /// Requirement: doc/specs/content-classes.md FR-051 - a `FeatureEntry`
  ///   has id, name, level (1 to 20), text and the optional arrays; level 0
  ///   and 21 are rejected, 1 and 20 accepted (SRD 5.2.1, "Barbarian Class
  ///   Features", pp. 28-30).
  /// Path: happy
  group('FeatureEntry level rows', () {
    /// Requirement: per case
    /// Path: per case
    for (final c in [
      (
        label: 'level 1',
        requirement:
            'doc/specs/content-classes.md FR-051 - level 1 is accepted',
        path: 'happy',
        level: 1,
        throwsFor: null,
      ),
      (
        label: 'level 20',
        requirement:
            'doc/specs/content-classes.md FR-051 - level 20 is accepted',
        path: 'unhappy (boundary)',
        level: 20,
        throwsFor: null,
      ),
      (
        label: 'level 0',
        requirement:
            'doc/specs/content-classes.md FR-051 - level 0 is rejected',
        path: 'unhappy (boundary)',
        level: 0,
        throwsFor: throwsArgumentErrorFor('level', 0),
      ),
      (
        label: 'level 21',
        requirement:
            'doc/specs/content-classes.md FR-051 - level 21 is rejected',
        path: 'unhappy (boundary)',
        level: 21,
        throwsFor: throwsArgumentErrorFor('level', 21),
      ),
    ]) {
      test('${c.label} [${c.path}]', () {
        if (c.throwsFor != null) {
          expect(() => _entry(level: c.level), c.throwsFor);
        } else {
          expect(_entry(level: c.level), isA<FeatureEntry>());
        }
      });
    }
  });

  /// Requirement: doc/specs/content-classes.md FR-051, FR-007 - a feature
  ///   name is non-blank.
  /// Path: unhappy (invalid input)
  test('a blank feature name is rejected', () {
    expect(() => _entry(name: ' '), throwsArgumentErrorFor('name', ' '));
  });

  /// Requirement: doc/specs/content-classes.md FR-051, FR-054, FR-007 - a
  ///   feature text is non-blank.
  /// Path: unhappy (invalid input)
  test('a blank feature text is rejected', () {
    expect(
      () => FeatureEntry(
        id: FeatureId('barbarian_rage'),
        name: 'Rage',
        level: 1,
        text: '   ',
      ),
      throwsArgumentErrorFor('text', '   '),
    );
  });

  /// Requirement: doc/specs/content-classes.md FR-051, FR-008 - the debug
  ///   form names the id and level.
  /// Path: happy
  test('the debug form names the id and level', () {
    expect(_entry().toString(), 'FeatureEntry(barbarian_rage, level 1)');
  });

  /// Requirement: doc/specs/content-classes.md FR-055 - facts on one entry
  ///   are distinct.
  /// Path: unhappy (boundary)
  test('a repeated fact is rejected', () {
    expect(
      () => _entry(
        facts: [
          const GrantsFeat(FeatCategory.general),
          const GrantsFeat(FeatCategory.general),
        ],
      ),
      throwsArgumentErrorFor('facts', const GrantsFeat(FeatCategory.general)),
    );
    // A repeat is caught wherever it sits in the list.
    expect(
      () => _entry(
        facts: [
          const GrantsFeat(FeatCategory.general),
          _grantAt(1),
          const GrantsFeat(FeatCategory.general),
        ],
      ),
      throwsArgumentErrorFor('facts', const GrantsFeat(FeatCategory.general)),
    );
  });

  /// Requirement: doc/specs/content-classes.md FR-058 - a grant level below
  ///   the owning feature's level is rejected (Cases FT: "grant below
  ///   entry").
  /// Path: unhappy (boundary)
  test('a grant below the entry fact level is rejected', () {
    expect(
      () => _entry(level: 3, facts: [_grantAt(1)]),
      throwsArgumentErrorFor('facts', 1),
    );
  });

  /// Requirement: doc/specs/content-classes.md FR-064, FR-058 - an option
  ///   fact's grant level is checked against the entry's level too.
  /// Path: unhappy (boundary)
  test('a grant below the level in an option fact is rejected', () {
    expect(
      () => _entry(
        level: 3,
        options: [
          FeatureOption(
            id: FeatureOptionId('forest'),
            name: 'Forest',
            text: 'The land type grants spells...',
            facts: [_grantAt(1)],
          ),
        ],
      ),
      throwsArgumentErrorFor('facts', 1),
    );
  });

  /// Requirement: doc/specs/content-classes.md FR-061 - option ids are
  ///   unique within the feature (Cases FT: "duplicate option id").
  /// Path: unhappy (invalid input)
  test('a repeated option id is rejected', () {
    expect(
      () =>
          _entry(level: 2, options: [_option('a_option'), _option('a_option')]),
      throwsArgumentErrorFor('options', FeatureOptionId('a_option')),
    );
    // A repeat is caught whatever sits between the repeats.
    expect(
      () => _entry(
        level: 2,
        options: [
          _option('a_option'),
          _option('b_option'),
          _option('a_option'),
        ],
      ),
      throwsArgumentErrorFor('options', FeatureOptionId('a_option')),
    );
  });

  /// Requirement: doc/specs/content-classes.md FR-062 - every required id
  ///   must name a different option of the same feature (Cases FT:
  ///   "prerequisite on a missing option").
  /// Path: unhappy (missing content)
  test('a prerequisite naming a missing option is rejected', () {
    expect(
      () => _entry(level: 2, options: [_agonizingBlastMissing]),
      throwsArgumentErrorFor('options', FeatureOptionId('no_such_option')),
    );
  });

  /// Requirement: doc/specs/content-classes.md FR-062 - a self reference is
  ///   rejected (Cases FT: "self prerequisite").
  /// Path: unhappy (rule interaction)
  test('a self reference is rejected', () {
    expect(
      () => _entry(level: 2, options: [_agonizingBlastSelf]),
      throwsArgumentErrorFor('options', FeatureOptionId('agonizing_blast')),
    );
  });

  /// Requirement: doc/specs/content-classes.md FR-062 - the references
  ///   MUST NOT form a cycle (Cases FT: "prerequisite cycle").
  /// Path: unhappy (rule interaction)
  test('a prerequisite cycle is rejected', () {
    expect(
      () => _entry(
        level: 2,
        options: [
          _option(
            'first',
            prerequisite: OptionPrerequisite(
              requiresOptionIds: [FeatureOptionId('second')],
            ),
          ),
          _option(
            'second',
            prerequisite: OptionPrerequisite(
              requiresOptionIds: [FeatureOptionId('first')],
            ),
          ),
        ],
      ),
      throwsA(isA<ArgumentError>()),
    );
  });

  /// Requirement: doc/specs/content-classes.md FR-062 - a prerequisite
  ///   naming another option of the same feature is accepted.
  /// Path: happy
  test('a valid prerequisite chain is accepted', () {
    final entry = _entry(
      level: 2,
      options: [
        _option('first'),
        _option(
          'second',
          prerequisite: OptionPrerequisite(
            requiresOptionIds: [FeatureOptionId('first')],
          ),
        ),
      ],
    );
    expect(entry.options.length, 2);
  });

  /// Requirement: doc/specs/content-classes.md FR-051, FR-008 - the arrays
  ///   are defensively copied and unmodifiable; value equality holds over
  ///   every field.
  /// Path: unhappy (immutability)
  test('arrays are defensively copied, unmodifiable and equal by value', () {
    final facts = [const GrantsFeat(FeatCategory.general)];
    final options = [_option('first')];
    final entry = _entry(facts: facts, options: options);
    facts.clear();
    options.clear();
    expect(entry.facts.length, 1);
    expect(entry.options.length, 1);
    expect(() => entry.facts.clear(), throwsUnsupportedError);
    expect(() => entry.options.clear(), throwsUnsupportedError);
    expect(() => entry.tables.clear(), throwsUnsupportedError);

    expect(
      entry,
      equals(
        _entry(
          facts: [const GrantsFeat(FeatCategory.general)],
          options: [_option('first')],
        ),
      ),
    );
    expect(entry, isNot(equals(_entry(name: 'Rage!', level: 1))));
  });
}

final _agonizingBlastMissing = FeatureOption(
  id: FeatureOptionId('agonizing_blast'),
  name: 'Agonizing Blast',
  text: 'Choose one of your known Warlock cantrips...',
  prerequisite: OptionPrerequisite(
    requiresOptionIds: [FeatureOptionId('no_such_option')],
  ),
);

final _agonizingBlastSelf = FeatureOption(
  id: FeatureOptionId('agonizing_blast'),
  name: 'Agonizing Blast',
  text: 'Choose one of your known Warlock cantrips...',
  prerequisite: OptionPrerequisite(
    requiresOptionIds: [FeatureOptionId('agonizing_blast')],
  ),
);
