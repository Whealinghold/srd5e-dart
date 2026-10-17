import 'package:srd5e/src/content/domain/classes/derive_feature_id.dart';
import 'package:test/test.dart';

import '../../../support/argument_error_matcher.dart';

void main() {
  /// Requirement: doc/specs/content-classes.md FR-052, FR-053 (D4) - the
  ///   derived id is the owner's id, an underscore, then the slug of the
  ///   name: lower-case, the two apostrophes deleted, each run of other
  ///   characters one underscore, edge underscores trimmed; a repeated name
  ///   carries `_level_<n>` (SRD 5.2.1, "Classes", pp. 28-82).
  /// Path: happy
  group('Cases ID: feature id derivation', () {
    /// Requirement: per case
    /// Path: per case
    for (final c in [
      (
        label: 'plain',
        requirement:
            'doc/specs/content-classes.md FR-052 - Rage under barbarian is '
            'barbarian_rage',
        path: 'happy',
        ownerId: 'barbarian',
        name: 'Rage',
        level: null,
        expected: 'barbarian_rage',
      ),
      (
        label: 'spaces',
        requirement:
            'doc/specs/content-classes.md FR-052 - Jack of All Trades under '
            'bard is bard_jack_of_all_trades',
        path: 'happy',
        ownerId: 'bard',
        name: 'Jack of All Trades',
        level: null,
        expected: 'bard_jack_of_all_trades',
      ),
      (
        label: 'apostrophe deleted',
        requirement:
            'doc/specs/content-classes.md FR-052 - the straight apostrophe '
            'is deleted: Monk\'s Focus under monk is monk_monks_focus',
        path: 'unhappy (boundary)',
        ownerId: 'monk',
        name: "Monk's Focus",
        level: null,
        expected: 'monk_monks_focus',
      ),
      (
        label: 'plural possessive',
        requirement:
            'doc/specs/content-classes.md FR-052 - the typographic '
            'apostrophe (U+2019) is deleted: Thieves’ Cant under rogue is '
            'rogue_thieves_cant',
        path: 'unhappy (boundary)',
        ownerId: 'rogue',
        name: 'Thieves’ Cant',
        level: null,
        expected: 'rogue_thieves_cant',
      ),
      (
        label: 'hyphen',
        requirement:
            'doc/specs/content-classes.md FR-052 - the hyphen and the space '
            'are one underscore run: Second-Story Work under thief is '
            'thief_second_story_work',
        path: 'unhappy (boundary)',
        ownerId: 'thief',
        name: 'Second-Story Work',
        level: null,
        expected: 'thief_second_story_work',
      ),
      (
        label: 'subclass owner',
        requirement:
            'doc/specs/content-classes.md FR-052 - a subclass owner id '
            'works the same: Dark One\'s Own Luck under fiend_patron is '
            'fiend_patron_dark_ones_own_luck',
        path: 'happy',
        ownerId: 'fiend_patron',
        name: "Dark One's Own Luck",
        level: null,
        expected: 'fiend_patron_dark_ones_own_luck',
      ),
      (
        label: 'duplicate name, first',
        requirement:
            'doc/specs/content-classes.md FR-053 - the first Improved '
            'Brutal Strike carries its level: '
            'barbarian_improved_brutal_strike_level_13',
        path: 'unhappy (name collision)',
        ownerId: 'barbarian',
        name: 'Improved Brutal Strike',
        level: 13,
        expected: 'barbarian_improved_brutal_strike_level_13',
      ),
      (
        label: 'duplicate name, second',
        requirement:
            'doc/specs/content-classes.md FR-053 - the second Improved '
            'Brutal Strike carries its own level: '
            'barbarian_improved_brutal_strike_level_17',
        path: 'unhappy (name collision)',
        ownerId: 'barbarian',
        name: 'Improved Brutal Strike',
        level: 17,
        expected: 'barbarian_improved_brutal_strike_level_17',
      ),
      (
        label: 'letter z',
        requirement:
            'doc/specs/content-classes.md FR-052 - the letter z (0x7a) is '
            'kept: Topaz under wizard is wizard_topaz',
        path: 'unhappy (boundary)',
        ownerId: 'wizard',
        name: 'Topaz',
        level: null,
        expected: 'wizard_topaz',
      ),
      (
        label: 'digit zero',
        requirement:
            'doc/specs/content-classes.md FR-052 - the digit 0 (0x30) is '
            'kept: Level 0 Spell under sorcerer is sorcerer_level_0_spell',
        path: 'unhappy (boundary)',
        ownerId: 'sorcerer',
        name: 'Level 0 Spell',
        level: null,
        expected: 'sorcerer_level_0_spell',
      ),
      (
        label: 'digit nine',
        requirement:
            'doc/specs/content-classes.md FR-052 - the digit 9 (0x39) is '
            'kept: Level 9 Spell under sorcerer is sorcerer_level_9_spell',
        path: 'unhappy (boundary)',
        ownerId: 'sorcerer',
        name: 'Level 9 Spell',
        level: null,
        expected: 'sorcerer_level_9_spell',
      ),
    ]) {
      test('${c.label} [${c.path}]', () {
        expect(deriveFeatureId(c.ownerId, c.name, level: c.level), c.expected);
      });
    }
  });

  /// Requirement: doc/specs/content-classes.md FR-052 - every derived id
  ///   satisfies schema FR-030: 64 characters are accepted.
  /// Path: unhappy (boundary)
  test('a derived id of exactly 64 characters is accepted', () {
    // 'a' + '_' + 62 letters = 64 characters.
    final id = deriveFeatureId('a', 'b' * 62);
    expect(id.length, 64);
    expect(id, 'a_${'b' * 62}');
  });

  /// Requirement: doc/specs/content-classes.md FR-052 - every derived id
  ///   satisfies schema FR-030: a result longer than 64 characters throws
  ///   `ArgumentError`.
  /// Path: unhappy (boundary)
  test('a derived id of 65 characters throws', () {
    final expected = 'a_${'b' * 63}';
    expect(
      () => deriveFeatureId('a', 'b' * 63),
      throwsArgumentErrorFor('value', expected),
    );
  });

  /// Requirement: doc/specs/content-classes.md FR-052 - edge underscores
  ///   are trimmed: a name that starts or ends with non-id characters
  ///   derives a clean id.
  /// Path: unhappy (boundary)
  test('leading and trailing punctuation is trimmed from the slug', () {
    expect(
      deriveFeatureId('monk', '(Unarmored Defense)'),
      'monk_unarmored_defense',
    );
  });
}
