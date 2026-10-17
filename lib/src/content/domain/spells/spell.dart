import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import '../content_entry.dart';
import '../content_key.dart';
import '../content_text_block.dart';
import '../named_text.dart';
import '../source_citation.dart';
import '../typed_ids.dart';
import 'spell_casting_time.dart';
import 'spell_components.dart';
import 'spell_duration.dart';
import 'spell_effect_model.dart';
import 'spell_level.dart';
import 'spell_range.dart';
import 'spell_school.dart';

/// One spell of the "Spell Descriptions" section ("Spell Descriptions",
/// SRD 5.2.1, pp. 107-175) as one content entry of kind
/// [ContentKind.spell] (FR-113).
///
/// The entry holds the printed header — level, school, class lists, Casting
/// Time (with Ritual), Range, Components, Duration — and the verbatim
/// description blocks, plus the optional `higherLevel` and `cantripUpgrade`
/// text and the optional structured `effects` model (FR-122, default
/// [TextOnlyEffects]). Every list is an unmodifiable copy (FR-086). The
/// header parentheses are authoritative for the class lists; the printed
/// class spell lists are the verification oracle, not the source (FR-022).
@immutable
final class Spell implements ContentEntry {
  /// Whether [name] is a valid spell name (FR-098, FR-111): non-empty with
  /// no leading or trailing whitespace. The predicate the decoder reuses
  /// so the name rule exists once.
  static bool isValidName(String name) => NamedText.isValidName(name);

  /// Creates a spell from defensive copies of its list fields.
  ///
  /// Throws an [ArgumentError] carrying the name of the offending field and
  /// the offending value when [name] breaks the name rule (FR-098),
  /// [description] is empty (FR-058), [higherLevel] or [cantripUpgrade] is
  /// present but an empty list (FR-102), or the [effects] model contradicts
  /// the spell's [level] (`SpellEffectModel.checkSpellLevel`, FR-009,
  /// FR-122).
  Spell({
    required this.id,
    required String name,
    this.source,
    required this.level,
    required this.school,
    required Set<ClassId> classes,
    required this.castingTimes,
    required this.ritual,
    required this.range,
    required this.components,
    required this.duration,
    required List<ContentTextBlock> description,
    List<ContentTextBlock>? higherLevel,
    List<ContentTextBlock>? cantripUpgrade,
    this.effects = const TextOnlyEffects(),
  }) : name = _validatedName(name),
       classes = Set.unmodifiable(classes),
       description = List.unmodifiable(_validatedDescription(description)),
       higherLevel = _copyOptional(higherLevel, 'higherLevel'),
       cantripUpgrade = _copyOptional(cantripUpgrade, 'cantripUpgrade') {
    effects.checkSpellLevel(level.level);
  }

  /// The spell's id, as a typed id.
  final SpellId id;

  /// The spell's printed name, exactly as the heading prints it (FR-006),
  /// non-empty with no surrounding whitespace (FR-098).
  final String name;

  /// Where the entry comes from, or null when the supplying document omits
  /// it (FR-007).
  final SourceCitation? source;

  /// The spell's level; 0 is a cantrip ("Spell Level", SRD 5.2.1, p. 104).
  final SpellLevel level;

  /// The spell's school ("Schools of Magic", SRD 5.2.1, p. 105).
  final SpellSchool school;

  /// The classes the spell is on, as printed in the header parentheses;
  /// unmodifiable (FR-017). The set may be empty: a host's content may grant
  /// a spell only through features (FR-018). Two spells whose classes differ
  /// only in listing order are equal (FR-017).
  final Set<ClassId> classes;

  /// The spell's Casting Time options (FR-030).
  final SpellCastingTimes castingTimes;

  /// Whether the printed Casting Time entry contains "or Ritual" ("Casting
  /// without Slots", SRD 5.2.1, p. 104) (FR-031).
  final bool ritual;

  /// The spell's Range ("Range", SRD 5.2.1, p. 105).
  final SpellRange range;

  /// The spell's Components ("Components", SRD 5.2.1, p. 105).
  final SpellComponents components;

  /// The spell's Duration ("Duration", SRD 5.2.1, p. 106).
  final SpellDuration duration;

  /// The description blocks, in printed order; unmodifiable, never empty
  /// (FR-058, FR-060).
  final List<ContentTextBlock> description;

  /// The text after the run-in heading "Using a Higher-Level Spell Slot.",
  /// heading removed, or null when the spell has none (FR-061); unmodifiable
  /// and non-empty when present (FR-102).
  final List<ContentTextBlock>? higherLevel;

  /// The text after the run-in heading "Cantrip Upgrade.", heading removed,
  /// or null when the spell has none (FR-062); unmodifiable and non-empty
  /// when present (FR-102).
  final List<ContentTextBlock>? cantripUpgrade;

  /// The structured effects, or `const TextOnlyEffects()` when the
  /// description text is the only source (FR-122).
  final SpellEffectModel effects;

  /// Whether the spell requires Concentration: exactly when its duration is
  /// a Concentration-capped Time Span (FR-057).
  bool get requiresConcentration =>
      duration is SpellDurationTimed &&
      (duration as SpellDurationTimed).limit == DurationLimit.concentrationUpTo;

  @override
  ContentKey get key => id.key;

  static String _validatedName(String name) {
    if (!Spell.isValidName(name)) {
      throw ArgumentError.value(
        name,
        'name',
        'must be non-empty with no leading or trailing whitespace',
      );
    }
    return name;
  }

  static List<ContentTextBlock> _validatedDescription(
    List<ContentTextBlock> description,
  ) {
    if (description.isEmpty) {
      throw ArgumentError.value(
        description,
        'description',
        'must have at least one block',
      );
    }
    return description;
  }

  static List<ContentTextBlock>? _validatedOptional(
    List<ContentTextBlock>? blocks,
    String fieldName,
  ) {
    if (blocks != null && blocks.isEmpty) {
      throw ArgumentError.value(
        blocks,
        fieldName,
        'must be absent or hold at least one block',
      );
    }
    return blocks;
  }

  /// An unmodifiable copy of [blocks], or null when it is absent; an empty
  /// present list throws (FR-102).
  static List<ContentTextBlock>? _copyOptional(
    List<ContentTextBlock>? blocks,
    String fieldName,
  ) {
    final validated = _validatedOptional(blocks, fieldName);
    return validated == null ? null : List.unmodifiable(validated);
  }

  @override
  bool operator ==(Object other) =>
      other is Spell &&
      other.id == id &&
      other.name == name &&
      other.source == source &&
      other.level == level &&
      other.school == school &&
      const SetEquality<ClassId>().equals(other.classes, classes) &&
      other.castingTimes == castingTimes &&
      other.ritual == ritual &&
      other.range == range &&
      other.components == components &&
      other.duration == duration &&
      const ListEquality<ContentTextBlock>().equals(
        other.description,
        description,
      ) &&
      _blocksEqual(other.higherLevel, higherLevel) &&
      _blocksEqual(other.cantripUpgrade, cantripUpgrade) &&
      other.effects == effects;

  @override
  int get hashCode => Object.hash(
    Spell,
    id,
    name,
    source,
    level,
    school,
    const SetEquality<ClassId>().hash(classes),
    castingTimes,
    ritual,
    range,
    components,
    duration,
    const ListEquality<ContentTextBlock>().hash(description),
    // mutate4dart: ignore null_coalescing // a hash code may ignore a field: equal objects still hash equally and collisions are legal; == pins the field.
    const ListEquality<ContentTextBlock>().hash(higherLevel ?? const []),
    // mutate4dart: ignore null_coalescing // a hash code may ignore a field: equal objects still hash equally and collisions are legal; == pins the field.
    const ListEquality<ContentTextBlock>().hash(cantripUpgrade ?? const []),
    effects,
  );

  @override
  String toString() => 'Spell(${id.id.value})';
}

bool _blocksEqual(List<ContentTextBlock>? a, List<ContentTextBlock>? b) =>
    const ListEquality<ContentTextBlock>().equals(a ?? const [], b ?? const []);
