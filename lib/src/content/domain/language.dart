/// One of the 19 languages ("Standard Languages", "Rare Languages", SRD
/// 5.2.1, p. 20): the 10 of the Standard Languages table in order, then the
/// 9 of the Rare Languages table in order (FR-111).
///
/// The JSON spelling is the printed name, with the typographic apostrophe of
/// "Thieves’ Cant" (U+2019) kept exactly, so the ASCII spelling is a
/// non-member. Primordial is one member; Aquan, Auran, Ignan and Terran are
/// its dialects and not members.
enum Language {
  /// Common (standard).
  common('Common'),

  /// Common Sign Language (standard).
  commonSignLanguage('Common Sign Language'),

  /// Draconic (standard).
  draconic('Draconic'),

  /// Dwarvish (standard).
  dwarvish('Dwarvish'),

  /// Elvish (standard).
  elvish('Elvish'),

  /// Giant (standard).
  giant('Giant'),

  /// Gnomish (standard).
  gnomish('Gnomish'),

  /// Goblin (standard).
  goblin('Goblin'),

  /// Halfling (standard).
  halfling('Halfling'),

  /// Orc (standard).
  orc('Orc'),

  /// Abyssal (rare).
  abyssal('Abyssal'),

  /// Celestial (rare).
  celestial('Celestial'),

  /// Deep Speech (rare).
  deepSpeech('Deep Speech'),

  /// Druidic (rare).
  druidic('Druidic'),

  /// Infernal (rare).
  infernal('Infernal'),

  /// Primordial (rare); Aquan, Auran, Ignan and Terran are its dialects.
  primordial('Primordial'),

  /// Sylvan (rare).
  sylvan('Sylvan'),

  /// Thieves’ Cant (rare), printed with a typographic apostrophe (U+2019).
  thievesCant('Thieves’ Cant'),

  /// Undercommon (rare).
  undercommon('Undercommon');

  const Language(this.jsonValue);

  /// The printed name used in JSON.
  final String jsonValue;

  /// Whether the language is in the Standard Languages table: true for the
  /// first 10 members, false for the 9 rare ones (SRD 5.2.1, p. 20).
  bool get isStandard => index < standardCount;

  /// How many of the members the Standard Languages table holds.
  static const int standardCount = 10;

  /// The member whose [jsonValue] is [value], or null for a non-member: the
  /// decoder turns a non-member into `invalidValue` (FR-105, FR-025).
  static Language? fromJson(String value) => switch (value) {
    'Common' => common,
    'Common Sign Language' => commonSignLanguage,
    'Draconic' => draconic,
    'Dwarvish' => dwarvish,
    'Elvish' => elvish,
    'Giant' => giant,
    'Gnomish' => gnomish,
    'Goblin' => goblin,
    'Halfling' => halfling,
    'Orc' => orc,
    'Abyssal' => abyssal,
    'Celestial' => celestial,
    'Deep Speech' => deepSpeech,
    'Druidic' => druidic,
    'Infernal' => infernal,
    'Primordial' => primordial,
    'Sylvan' => sylvan,
    'Thieves’ Cant' => thievesCant,
    'Undercommon' => undercommon,
    _ => null,
  };
}
