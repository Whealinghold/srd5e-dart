import 'package:srd5e/src/content/domain/language.dart';
import 'package:test/test.dart';

/// One language with the [isStandard] value its table gives it.
typedef _StandardCase = ({
  String label,
  String requirement,
  String path,
  Language language,
  bool isStandard,
});

/// The 10 standard languages, in table order ("Standard Languages", SRD
/// 5.2.1, p. 20).
final List<_StandardCase> _standard = [
  (
    label: 'Common',
    requirement:
        'doc/specs/content-schema-and-decoder.md FR-111 - isStandard '
        'is true for the first 10 members (SRD 5.2.1, p. 20)',
    path: 'happy',
    language: Language.common,
    isStandard: true,
  ),
  (
    label: 'Common Sign Language',
    requirement:
        'doc/specs/content-schema-and-decoder.md FR-111 - isStandard '
        'is true for the first 10 members (SRD 5.2.1, p. 20)',
    path: 'happy',
    language: Language.commonSignLanguage,
    isStandard: true,
  ),
  (
    label: 'Draconic',
    requirement:
        'doc/specs/content-schema-and-decoder.md FR-111 - isStandard '
        'is true for the first 10 members (SRD 5.2.1, p. 20)',
    path: 'happy',
    language: Language.draconic,
    isStandard: true,
  ),
  (
    label: 'Dwarvish',
    requirement:
        'doc/specs/content-schema-and-decoder.md FR-111 - isStandard '
        'is true for the first 10 members (SRD 5.2.1, p. 20)',
    path: 'happy',
    language: Language.dwarvish,
    isStandard: true,
  ),
  (
    label: 'Elvish',
    requirement:
        'doc/specs/content-schema-and-decoder.md FR-111 - isStandard '
        'is true for the first 10 members (SRD 5.2.1, p. 20)',
    path: 'happy',
    language: Language.elvish,
    isStandard: true,
  ),
  (
    label: 'Giant',
    requirement:
        'doc/specs/content-schema-and-decoder.md FR-111 - isStandard '
        'is true for the first 10 members (SRD 5.2.1, p. 20)',
    path: 'happy',
    language: Language.giant,
    isStandard: true,
  ),
  (
    label: 'Gnomish',
    requirement:
        'doc/specs/content-schema-and-decoder.md FR-111 - isStandard '
        'is true for the first 10 members (SRD 5.2.1, p. 20)',
    path: 'happy',
    language: Language.gnomish,
    isStandard: true,
  ),
  (
    label: 'Goblin',
    requirement:
        'doc/specs/content-schema-and-decoder.md FR-111 - isStandard '
        'is true for the first 10 members (SRD 5.2.1, p. 20)',
    path: 'happy',
    language: Language.goblin,
    isStandard: true,
  ),
  (
    label: 'Halfling',
    requirement:
        'doc/specs/content-schema-and-decoder.md FR-111 - isStandard '
        'is true for the first 10 members (SRD 5.2.1, p. 20)',
    path: 'happy',
    language: Language.halfling,
    isStandard: true,
  ),
  (
    label: 'Orc',
    requirement:
        'doc/specs/content-schema-and-decoder.md FR-111 - isStandard '
        'is true for the first 10 members (SRD 5.2.1, p. 20)',
    path: 'happy',
    language: Language.orc,
    isStandard: true,
  ),
  (
    label: 'Abyssal',
    requirement:
        'doc/specs/content-schema-and-decoder.md FR-111 - isStandard '
        'is false for the 9 rare members (SRD 5.2.1, "Rare Languages", p. 20)',
    path: 'happy',
    language: Language.abyssal,
    isStandard: false,
  ),
  (
    label: 'Celestial',
    requirement:
        'doc/specs/content-schema-and-decoder.md FR-111 - isStandard '
        'is false for the 9 rare members (SRD 5.2.1, "Rare Languages", p. 20)',
    path: 'happy',
    language: Language.celestial,
    isStandard: false,
  ),
  (
    label: 'Deep Speech',
    requirement:
        'doc/specs/content-schema-and-decoder.md FR-111 - isStandard '
        'is false for the 9 rare members (SRD 5.2.1, "Rare Languages", p. 20)',
    path: 'happy',
    language: Language.deepSpeech,
    isStandard: false,
  ),
  (
    label: 'Druidic',
    requirement:
        'doc/specs/content-schema-and-decoder.md FR-111 - isStandard '
        'is false for the 9 rare members (SRD 5.2.1, "Rare Languages", p. 20)',
    path: 'happy',
    language: Language.druidic,
    isStandard: false,
  ),
  (
    label: 'Infernal',
    requirement:
        'doc/specs/content-schema-and-decoder.md FR-111 - isStandard '
        'is false for the 9 rare members (SRD 5.2.1, "Rare Languages", p. 20)',
    path: 'happy',
    language: Language.infernal,
    isStandard: false,
  ),
  (
    label: 'Primordial',
    requirement:
        'doc/specs/content-schema-and-decoder.md FR-111 - isStandard '
        'is false for the 9 rare members (SRD 5.2.1, "Rare Languages", p. 20)',
    path: 'happy',
    language: Language.primordial,
    isStandard: false,
  ),
  (
    label: 'Sylvan',
    requirement:
        'doc/specs/content-schema-and-decoder.md FR-111 - isStandard '
        'is false for the 9 rare members (SRD 5.2.1, "Rare Languages", p. 20)',
    path: 'happy',
    language: Language.sylvan,
    isStandard: false,
  ),
  (
    label: 'Thieves’ Cant',
    requirement:
        'doc/specs/content-schema-and-decoder.md FR-111 - isStandard '
        'is false for the 9 rare members (SRD 5.2.1, "Rare Languages", p. 20)',
    path: 'happy',
    language: Language.thievesCant,
    isStandard: false,
  ),
  (
    label: 'Undercommon',
    requirement:
        'doc/specs/content-schema-and-decoder.md FR-111 - isStandard '
        'is false for the 9 rare members (SRD 5.2.1, "Rare Languages", p. 20)',
    path: 'happy',
    language: Language.undercommon,
    isStandard: false,
  ),
];

/// Exhaustive over the enum with no default branch (FR-111).
String _describe(Language language) => switch (language) {
  Language.common => 'common',
  Language.commonSignLanguage => 'commonSignLanguage',
  Language.draconic => 'draconic',
  Language.dwarvish => 'dwarvish',
  Language.elvish => 'elvish',
  Language.giant => 'giant',
  Language.gnomish => 'gnomish',
  Language.goblin => 'goblin',
  Language.halfling => 'halfling',
  Language.orc => 'orc',
  Language.abyssal => 'abyssal',
  Language.celestial => 'celestial',
  Language.deepSpeech => 'deepSpeech',
  Language.druidic => 'druidic',
  Language.infernal => 'infernal',
  Language.primordial => 'primordial',
  Language.sylvan => 'sylvan',
  Language.thievesCant => 'thievesCant',
  Language.undercommon => 'undercommon',
};

void main() {
  /// Requirement: doc/specs/content-schema-and-decoder.md FR-111 - exactly
  ///   these 19 members: the 10 of the Standard Languages table in order,
  ///   then the 9 of the Rare Languages table in order (SRD 5.2.1, p. 20).
  /// Path: happy
  test('declares exactly 19 members in table order', () {
    expect(Language.values.map((language) => language.jsonValue), [
      'Common',
      'Common Sign Language',
      'Draconic',
      'Dwarvish',
      'Elvish',
      'Giant',
      'Gnomish',
      'Goblin',
      'Halfling',
      'Orc',
      'Abyssal',
      'Celestial',
      'Deep Speech',
      'Druidic',
      'Infernal',
      'Primordial',
      'Sylvan',
      'Thieves’ Cant',
      'Undercommon',
    ]);
  });

  /// Requirement: per case
  /// Path: per case
  for (final c in _standard) {
    test('${c.label} isStandard is ${c.isStandard} [per case]', () {
      expect(c.language.isStandard, c.isStandard);
    });
  }

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-111 - the
  ///   typographic apostrophe of "Thieves’ Cant" (U+2019) is kept exactly
  ///   (FR-029), so the ASCII spelling is a non-member.
  /// Path: unhappy (invalid input)
  test('the Thieves’ Cant apostrophe is U+2019, never ASCII', () {
    expect(Language.thievesCant.jsonValue, 'Thieves’ Cant');
    expect(Language.thievesCant.jsonValue.codeUnits, contains(0x2019));
    expect(Language.fromJson('Thieves’ Cant'), Language.thievesCant);
    expect(Language.fromJson('Thieves\' Cant'), isNull);
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-111 - Primordial
  ///   is one member; Aquan, Auran, Ignan and Terran are its dialects and
  ///   not members.
  /// Path: unhappy (invalid input)
  test('the Primordial dialects are not members', () {
    expect(Language.fromJson('Aquan'), isNull);
    expect(Language.fromJson('Auran'), isNull);
    expect(Language.fromJson('Ignan'), isNull);
    expect(Language.fromJson('Terran'), isNull);
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-105 - the
  ///   static fromJson accepts exactly the jsonValue spellings.
  /// Path: happy
  test('fromJson round-trips every member', () {
    for (final language in Language.values) {
      expect(Language.fromJson(language.jsonValue), language);
    }
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-111 - a switch
  ///   over Language is exhaustive without a default.
  /// Path: happy
  test('a switch over every member selects its case', () {
    expect(
      [for (final language in Language.values) _describe(language)],
      [
        'common',
        'commonSignLanguage',
        'draconic',
        'dwarvish',
        'elvish',
        'giant',
        'gnomish',
        'goblin',
        'halfling',
        'orc',
        'abyssal',
        'celestial',
        'deepSpeech',
        'druidic',
        'infernal',
        'primordial',
        'sylvan',
        'thievesCant',
        'undercommon',
      ],
    );
  });
}
