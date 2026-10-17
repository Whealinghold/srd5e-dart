/// The thin slice's oracle for the Wizard entry: the phrases of the
/// Spellcasting feature text that doc/specs/content-thin-slice.md FR-062
/// pins (SRD 5.2.1, "Wizard Class Features", "Level 1: Spellcasting",
/// pp. 77-78).
///
/// SRD 5.2.1 text, transcribed from the spec's test-plan row independently
/// of the data files under `data/srd_5_2_1/` (shared-types-and-ownership.md
/// FR-033). The Wizard's other values are content-classes.md's, withdrawn
/// from this spec (its section 4.10); this spec keeps membership (FR-002)
/// and citation (FR-007).
library;

/// The cantrip-recommendation sentence of the Spellcasting feature (the
/// names FR-062 pins, with the printed commas and "and").
const String spellcastingCantripsPhrase = 'Light, Mage Hand, and Ray of Frost';

/// The spell-recommendation sentence of the Spellbook heading: Magic
/// Missile and Detect Magic are two of the six level 1 spells it
/// recommends (the slice bundles both, section 1 "Why these spells").
const String spellbookRecommendationPhrase =
    'Detect Magic, Feather Fall, Mage Armor, Magic Missile, Sleep, and '
    'Thunderwave are recommended';

/// The feature entry the phrases live in, by its derived id
/// (content-classes.md FR-054; the id is the owner and printed name).
const String spellcastingFeatureId = 'wizard_spellcasting';
