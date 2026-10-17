/// The shared helpers of the thin-slice pin tests: the three slice texts
/// (content-thin-slice.md section 4, "Loading unit"), a source built from
/// exactly those texts, and the pure readers and printed forms the pins
/// compare against. No file is read (testing.md section 6); the data tests
/// use the embedded libraries only.
library;

import 'package:srd5e/adapters.dart';
import 'package:srd5e/src/content/data/class_wizard.dart' show classWizardJson;
import 'package:srd5e/src/content/data/species.dart' show speciesJson;
import 'package:srd5e/src/content/data/spells.dart' show spellsJson;
import 'package:srd5e/srd5e.dart';

/// The three slice texts by file name (FR-067: exactly the three texts).
const Map<String, String> sliceTexts = {
  'class_wizard.json': classWizardJson,
  'species.json': speciesJson,
  'spells.json': spellsJson,
};

/// The source over exactly the three slice texts
/// (content-source-port.md FR-059; thin-slice FR-067).
final BundledContentSource sliceSource = BundledContentSource(
  texts: sliceTexts,
);

/// Every entry of [kind] the source holds, ordered by id.
Future<List<ContentEntry>> entriesOf(ContentKind kind) =>
    sliceSource.listKind(kind);

/// The entry [kind]/[id]; fails the test's process when it is absent —
/// expected absence is pinned separately (FR-064 to FR-066).
Future<ContentEntry> entryOf(ContentKind kind, String id) async {
  final lookup = await sliceSource.lookup(ContentKey(kind, ContentId(id)));
  return switch (lookup) {
    ContentFound(:final entry) => entry,
    ContentNotFound(:final key) => throw StateError(
      'the slice holds no ${key.kind.name}/${key.id.value}',
    ),
  };
}

/// The entry as a [Species], or a failed lookup of the wrong kind.
Future<Species> speciesOf(String id) async =>
    (await entryOf(ContentKind.species, id)) as Species;

/// The entry as a [Spell], or a failed lookup of the wrong kind.
Future<Spell> spellOf(String id) async =>
    (await entryOf(ContentKind.spell, id)) as Spell;

/// The entry as a [ClassDefinition], or a failed lookup of the wrong kind.
Future<ClassDefinition> classOf(String id) async =>
    (await entryOf(ContentKind.characterClass, id)) as ClassDefinition;

/// Whether [text] contains [phrase], ignoring case and whitespace runs.
bool containsPhrase(String text, String phrase) {
  String normalize(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  return normalize(text).contains(normalize(phrase));
}

/// Whether every [phrases] entry is in [text].
bool containsAllPhrases(String text, List<String> phrases) =>
    phrases.every((phrase) => containsPhrase(text, phrase));

/// The printed text an entry carries, for the pinned-phrase check and the
/// banned-term scan of FR-008: trait, feature and spell descriptions and
/// table cell text, verbatim.
List<String> entryTexts(ContentEntry entry) {
  final texts = <String>[];
  void addBlock(ContentTextBlock block) {
    switch (block) {
      case ContentTextParagraph(:final text):
        texts.add(text);
      case ContentTextEntry(:final name, :final text):
        texts
          ..add(name)
          ..add(text);
      case ContentTextBulletList(:final items):
        texts.addAll(items);
      case ContentTextTable(:final title, :final header, :final rows):
        texts
          ..add(title ?? '')
          ..addAll(header)
          ..addAll([for (final row in rows) ...row]);
      case ContentTextEmbeddedStatBlock(:final lines):
        texts.addAll(lines);
    }
  }

  switch (entry) {
    case Species(:final sizeText, :final traits, :final choices):
      if (sizeText != null) texts.add(sizeText);
      for (final trait in traits) {
        texts
          ..add(trait.name)
          ..add(trait.text);
      }
      for (final choice in choices) {
        for (final option in choice.options) {
          switch (option) {
            case DamageTypeOption():
              texts.add(option.name);
            case LineageOption(:final levelBenefits):
              texts.add(option.name);
              for (final benefit in levelBenefits) {
                texts.add(benefit.text);
              }
            case TextOption(:final text):
              texts
                ..add(option.name)
                ..add(text);
          }
        }
      }
    case Spell(
      :final description,
      :final higherLevel,
      :final cantripUpgrade,
      :final components,
    ):
      for (final block in description) {
        addBlock(block);
      }
      for (final block in [...?higherLevel, ...?cantripUpgrade]) {
        addBlock(block);
      }
      final material = components.material;
      if (material != null) texts.add(material.description);
    case ClassDefinition(:final features, :final subclasses):
      for (final feature in features) {
        texts
          ..add(feature.name)
          ..add(feature.text);
      }
      for (final subclass in subclasses) {
        for (final feature in subclass.features) {
          texts
            ..add(feature.name)
            ..add(feature.text);
        }
      }
    case _:
      break;
  }
  return texts;
}

/// The whole-word, case-insensitive banned terms of FR-008: word
/// boundaries, so "trace" and "grace" never match. The list is a test
/// constant (content-thin-slice.md section 1, "Oracle"); extending it is a
/// test change, not a spec change.
final RegExp bannedTerm = RegExp(
  r'\b(?:subraces|subrace|races|race)\b',
  caseSensitive: false,
);

/// Every banned-term occurrence in [texts], as the matched word.
Iterable<String> bannedTermsIn(Iterable<String> texts) sync* {
  for (final text in texts) {
    for (final match in bannedTerm.allMatches(text)) {
      yield match.group(0)!;
    }
  }
}

/// The printed Casting Time of [spell], as the T6 column spells it: the
/// Ritual tag prints as part of the entry ("Action or Ritual").
String printedCastingTime(Spell spell) => switch (spell.castingTimes) {
  SpellCastingTimesSingle(:final time) => switch (time) {
    CastingTimeMagicAction() => spell.ritual ? 'Action or Ritual' : 'Action',
    CastingTimeBonusAction() => 'Bonus Action',
    CastingTimeReaction() => 'Reaction',
    CastingTimeMinutes(:final amount) => 'Minutes $amount',
    CastingTimeHours(:final amount) => 'Hours $amount',
  },
  SpellCastingTimesModes() => 'Modes',
};

/// The printed Range of [spell], as the T6 column spells it.
String printedRange(Spell spell) => switch (spell.range) {
  SpellRangeSelf() => 'Self',
  SpellRangeTouch() => 'Touch',
  SpellRangeDistance(:final amount, :final unit) => switch (unit) {
    DistanceUnit.feet => '$amount feet',
    DistanceUnit.miles => '$amount miles',
  },
  SpellRangeSight() => 'Sight',
  SpellRangeUnlimited() => 'Unlimited',
  SpellRangeSpecial() => 'Special',
};

/// The printed Components of [spell], as the T6 column spells it.
String printedComponents(Spell spell) {
  final parts = <String>[
    if (spell.components.verbal) 'V',
    if (spell.components.somatic) 'S',
  ];
  final material = spell.components.material;
  if (material != null) parts.add('M (${material.description})');
  return parts.isEmpty ? 'none' : parts.join(', ');
}

/// The printed Duration of [spell], as the T6 column spells it.
String printedDuration(Spell spell) => switch (spell.duration) {
  SpellDurationInstantaneous() => 'Instantaneous',
  SpellDurationTimed(:final amount, :final unit, :final limit) =>
    switch (limit) {
      DurationLimit.fixed => '$amount ${_unitWord(unit, amount)}',
      DurationLimit.upTo => 'Up to $amount ${_unitWord(unit, amount)}',
      DurationLimit.concentrationUpTo =>
        'Concentration, up to $amount ${_unitWord(unit, amount)}',
    },
  SpellDurationUntilDispelled() => 'Until dispelled',
  SpellDurationUntilDispelledOrTriggered() => 'Until dispelled or triggered',
  SpellDurationSpecial() => 'Special',
};

/// The printed Time Span unit: the SRD prints the singular for 1
/// ("Up to 1 hour") and the plural otherwise.
String _unitWord(DurationUnit unit, int amount) => switch (unit) {
  DurationUnit.rounds => amount == 1 ? 'round' : 'rounds',
  DurationUnit.minutes => amount == 1 ? 'minute' : 'minutes',
  DurationUnit.hours => amount == 1 ? 'hour' : 'hours',
  DurationUnit.days => amount == 1 ? 'day' : 'days',
};
