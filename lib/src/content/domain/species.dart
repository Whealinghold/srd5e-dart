import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import 'choice_option.dart';
import 'content_entry.dart';
import 'content_key.dart';
import 'content_reference.dart';
import 'creature_size.dart';
import 'creature_type.dart';
import 'named_text.dart';
import 'source_citation.dart';
import 'species_choice.dart';
import 'typed_ids.dart';

/// A character species ("Character Species", SRD 5.2.1, pp. 83-86) as one
/// content entry of kind [ContentKind.species] (FR-010 to FR-014).
///
/// A species lists its creature type, the one or two player-character sizes
/// it may be chosen as, its speed, its special traits as verbatim
/// [NamedText]s and, where a trait asks the player to choose from a closed
/// list, one [SpeciesChoice] per such trait (FR-016). Its spell references
/// are the sites of FR-023, listed by [references] and resolved by the
/// whole-set validation — never by a single-document decode.
@immutable
final class Species implements ContentEntry, ContentReferences {
  /// Creates a species from defensive copies of the collection fields.
  ///
  /// Throws an [ArgumentError] carrying the name of the offending field and
  /// value when [name] breaks the name rule (FR-027), [sizes] does not hold
  /// [minSizes] to [maxSizes] distinct player-character sizes (FR-012),
  /// [sizeText] is present but blank (SX-3), [speed] is below [minSpeed]
  /// (FR-013), [traits] is empty or repeats a trait name (FR-014), or a
  /// choice's `traitName` names no trait of this species (FR-060).
  Species({
    required this.id,
    required String name,
    this.source,
    required this.creatureType,
    required List<CreatureSize> sizes,
    String? sizeText,
    required int speed,
    required List<NamedText> traits,
    List<SpeciesChoice> choices = const [],
  }) : name = _validatedName(name),
       sizes = List.unmodifiable(_validatedSizes(sizes)),
       sizeText = _validatedSizeText(sizeText),
       speed = _validatedSpeed(speed),
       traits = List.unmodifiable(_validatedTraits(traits)),
       choices = List.unmodifiable(choices) {
    _validateChoices(this.choices, this.traits);
  }

  /// The smallest number of sizes a species may list (FR-012). The constant
  /// the decoder reuses instead of repeating the literal (FR-069).
  static const int minSizes = 1;

  /// The largest number of sizes a species may list (FR-012).
  static const int maxSizes = 2;

  /// The lowest speed a species may carry: an integer of 0 or more (FR-013).
  static const int minSpeed = 0;

  /// Whether [size] is a size a species may list: Small or Medium (FR-012).
  /// The predicate the decoder reuses (FR-069).
  static bool isPlayerCharacterSize(CreatureSize size) =>
      size == CreatureSize.small || size == CreatureSize.medium;

  /// Whether [speed] is a speed a species may carry: [minSpeed] or more
  /// (FR-013). The predicate the decoder reuses (FR-069).
  static bool isValidSpeed(int speed) => speed >= minSpeed;

  /// The species' id, as a typed id.
  final SpeciesId id;

  /// The species' printed name ("Elf", "Goliath"), verbatim.
  final String name;

  /// Where the entry comes from, or null when the supplying document omits
  /// it (schema FR-034).
  final SourceCitation? source;

  /// The species' creature type; every bundled species is Humanoid (FR-011).
  final CreatureType creatureType;

  /// The sizes the species may be chosen as, each Small or Medium, in
  /// printed order; unmodifiable (FR-012).
  final List<CreatureSize> sizes;

  /// The printed Size sentence after "Size:", verbatim, or null when the
  /// supplying document omits it (SX-3; the bundled-data requirement is
  /// FR-074).
  final String? sizeText;

  /// The species' speed, in feet, 0 or more (FR-013).
  final int speed;

  /// The special traits, in printed order, each with a unique name;
  /// unmodifiable, never empty (FR-014).
  final List<NamedText> traits;

  /// The choices the species' traits offer, one per choosing trait;
  /// unmodifiable, possibly empty (FR-016).
  final List<SpeciesChoice> choices;

  @override
  ContentKey get key => id.key;

  /// The species' reference sites (FR-023): one site per lineage
  /// `LevelBenefit.spellId` and per `TextOption.spellIds` element, in choice,
  /// option and element order. A damage-type option names no spell, so it
  /// contributes no site.
  @override
  Iterable<ContentReference> get references sync* {
    for (var i = 0; i < choices.length; i++) {
      final options = choices[i].options;
      for (var k = 0; k < options.length; k++) {
        switch (options[k]) {
          case DamageTypeOption():
            break;
          case LineageOption(:final levelBenefits):
            for (var m = 0; m < levelBenefits.length; m++) {
              yield ContentReference(
                'choices/$i/options/$k/levelBenefits/$m/spellId',
                levelBenefits[m].spellId.key,
              );
            }
          case TextOption(:final spellIds):
            for (var n = 0; n < spellIds.length; n++) {
              yield ContentReference(
                'choices/$i/options/$k/spellIds/$n',
                spellIds[n].key,
              );
            }
        }
      }
    }
  }

  static String _validatedName(String name) {
    if (!NamedText.isValidName(name)) {
      throw ArgumentError.value(
        name,
        'name',
        'must be non-empty with no leading or trailing whitespace',
      );
    }
    return name;
  }

  static List<CreatureSize> _validatedSizes(List<CreatureSize> sizes) {
    if (sizes.length < minSizes || sizes.length > maxSizes) {
      throw ArgumentError.value(
        sizes,
        'sizes',
        'must hold $minSizes or $maxSizes sizes',
      );
    }
    for (final size in sizes) {
      if (!isPlayerCharacterSize(size)) {
        throw ArgumentError.value(size, 'sizes', 'must be Small or Medium');
      }
    }
    for (var i = 1; i < sizes.length; i++) {
      if (sizes.indexOf(sizes[i]) != i) {
        throw ArgumentError.value(sizes[i], 'sizes', 'must be distinct');
      }
    }
    return sizes;
  }

  static String? _validatedSizeText(String? sizeText) {
    if (sizeText != null && !NamedText.isValidText(sizeText)) {
      throw ArgumentError.value(
        sizeText,
        'sizeText',
        'must contain at least one non-whitespace character',
      );
    }
    return sizeText;
  }

  static int _validatedSpeed(int speed) {
    if (!isValidSpeed(speed)) {
      throw ArgumentError.value(speed, 'speed', 'must be $minSpeed or more');
    }
    return speed;
  }

  static List<NamedText> _validatedTraits(List<NamedText> traits) {
    if (traits.isEmpty) {
      throw ArgumentError.value(
        traits,
        'traits',
        'must have at least one trait',
      );
    }
    for (var i = 1; i < traits.length; i++) {
      final name = traits[i].name;
      if (traits.sublist(0, i).any((trait) => trait.name == name)) {
        throw ArgumentError.value(
          name,
          'traits',
          'must not repeat a trait name',
        );
      }
    }
    return traits;
  }

  static void _validateChoices(
    List<SpeciesChoice> choices,
    List<NamedText> traits,
  ) {
    for (final choice in choices) {
      final known = traits.any((trait) => trait.name == choice.traitName);
      if (!known) {
        throw ArgumentError.value(
          choice.traitName,
          'choices',
          'must name a trait of the same species (FR-060)',
        );
      }
    }
  }

  @override
  bool operator ==(Object other) =>
      other is Species &&
      other.id == id &&
      other.name == name &&
      other.source == source &&
      other.creatureType == creatureType &&
      const ListEquality<CreatureSize>().equals(other.sizes, sizes) &&
      other.sizeText == sizeText &&
      other.speed == speed &&
      const ListEquality<NamedText>().equals(other.traits, traits) &&
      const ListEquality<SpeciesChoice>().equals(other.choices, choices);

  @override
  int get hashCode => Object.hash(
    Species,
    id,
    name,
    source,
    creatureType,
    const ListEquality<CreatureSize>().hash(sizes),
    sizeText,
    speed,
    const ListEquality<NamedText>().hash(traits),
    const ListEquality<SpeciesChoice>().hash(choices),
  );

  @override
  String toString() => 'Species(${id.id.value})';
}
