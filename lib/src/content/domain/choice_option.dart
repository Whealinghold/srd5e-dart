import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import 'damage_type.dart';
import 'level_benefit.dart';
import 'named_text.dart';
import 'typed_ids.dart';

/// One option of a species choice, as a sealed family with exactly the three
/// variants the SRD prints (FR-016, SX-1): a [DamageTypeOption] (Draconic
/// Ancestry), a [LineageOption] (Elven Lineage, Fiendish Legacy) and a
/// [TextOption] (Gnomish Lineage, Giant Ancestry).
///
/// Every option of one choice has the same variant — a differing variant is
/// rejected by [SpeciesChoice] (FR-016) — so switch over this family
/// exhaustively, with no default branch. An option's [name] follows the name
/// rule (FR-027).
@immutable
sealed class ChoiceOption {
  const ChoiceOption._(this.name);

  /// The option's printed name, verbatim: the dragon color, the lineage name
  /// or the printed heading with its descriptor
  /// ("Cloud’s Jaunt (Cloud Giant)").
  final String name;

  /// Whether [name] passes the name rule (FR-027): non-empty, with no leading
  /// or trailing whitespace. The predicate the decoder reuses (FR-069).
  static bool isValidName(String name) => NamedText.isValidName(name);
}

/// A Draconic Ancestry option: one dragon color and the damage type its
/// Breath Weapon deals (FR-016, FR-017; SRD 5.2.1, "Dragonborn", p. 84).
///
/// It carries no text, because the SRD's table prints none.
@immutable
final class DamageTypeOption extends ChoiceOption {
  /// Creates a damage-type option.
  ///
  /// Throws an [ArgumentError] carrying the name `name` and the offending
  /// value when [name] breaks the name rule (FR-027).
  DamageTypeOption(String name, this.damageType)
    : super._(_validatedName(name));

  /// The damage type of the option's Breath Weapon.
  final DamageType damageType;

  @override
  bool operator ==(Object other) =>
      other is DamageTypeOption &&
      other.name == name &&
      other.damageType == damageType;

  @override
  int get hashCode => Object.hash(DamageTypeOption, name, damageType);

  @override
  String toString() => 'DamageTypeOption($name, ${damageType.name})';
}

/// A lineage option of the "Elven Lineages" and "Fiendish Legacies" tables:
/// one lineage with the benefits of its levels 1, 3 and 5 (FR-061; SRD 5.2.1,
/// pp. 85-86).
///
/// A [LevelBenefit] carries its spell beside the printed text (FR-021); the
/// Level 1 cell is `levelBenefits[0].text` and no other text exists.
@immutable
final class LineageOption extends ChoiceOption {
  /// Creates a lineage option from a defensive copy of [levelBenefits].
  ///
  /// Throws an [ArgumentError] carrying the name `name` or `levelBenefits`
  /// and the offending value when [name] breaks the name rule (FR-027), or
  /// [levelBenefits] does not hold exactly [requiredLevelBenefitCount]
  /// benefits whose levels are [LevelBenefit.lineageLevels] in that order and
  /// without a repeat (FR-061).
  LineageOption(String name, List<LevelBenefit> levelBenefits)
    : levelBenefits = List.unmodifiable(levelBenefits),
      super._(_validatedName(name)) {
    _validateLevels(this.levelBenefits);
  }

  /// How many benefits a lineage option holds: one per printed level
  /// (FR-061). The constant the decoder reuses (FR-069).
  static const int requiredLevelBenefitCount = 3;

  /// The benefits of the levels [LevelBenefit.lineageLevels], in that order;
  /// unmodifiable.
  final List<LevelBenefit> levelBenefits;

  static void _validateLevels(List<LevelBenefit> levelBenefits) {
    if (levelBenefits.length != requiredLevelBenefitCount) {
      throw ArgumentError.value(
        levelBenefits,
        'levelBenefits',
        'must hold exactly $requiredLevelBenefitCount benefits, one per '
            'level of ${LevelBenefit.lineageLevels}',
      );
    }
    for (var i = 1; i < levelBenefits.length; i++) {
      final level = levelBenefits[i].level;
      final repeated = levelBenefits
          .sublist(0, i)
          .any((benefit) => benefit.level == level);
      if (repeated) {
        throw ArgumentError.value(
          level,
          'levelBenefits',
          'must not repeat a level',
        );
      }
    }
    for (var i = 0; i < levelBenefits.length; i++) {
      if (levelBenefits[i].level != LevelBenefit.lineageLevels[i]) {
        throw ArgumentError.value(
          levelBenefits.map((benefit) => benefit.level).toList(),
          'levelBenefits',
          'must hold the levels ${LevelBenefit.lineageLevels} in that order',
        );
      }
    }
  }

  @override
  bool operator ==(Object other) =>
      other is LineageOption &&
      other.name == name &&
      const ListEquality<LevelBenefit>().equals(
        other.levelBenefits,
        levelBenefits,
      );

  @override
  int get hashCode => Object.hash(
    LineageOption,
    name,
    const ListEquality<LevelBenefit>().hash(levelBenefits),
  );

  @override
  String toString() => 'LineageOption($name)';
}

/// A text-only option: the verbatim text printed after the option's heading,
/// with the spells the option names beside it (FR-020, FR-021).
///
/// Gnomish Lineage options name their spells in [spellIds]; the Giant
/// Ancestry options have none.
@immutable
final class TextOption extends ChoiceOption {
  /// Creates a text option from a defensive copy of [spellIds].
  ///
  /// Throws an [ArgumentError] carrying the name `name` or `text` and the
  /// offending value when [name] breaks the name rule (FR-027) or [text]
  /// holds no non-whitespace character (FR-028).
  TextOption(String name, String text, {List<SpellId> spellIds = const []})
    : text = _validatedText(text),
      spellIds = List.unmodifiable(spellIds),
      super._(_validatedName(name));

  /// The printed text after the heading, verbatim.
  final String text;

  /// The spells the option names, each as a typed id beside the text
  /// (FR-020, FR-021); unmodifiable, possibly empty.
  final List<SpellId> spellIds;

  @override
  bool operator ==(Object other) =>
      other is TextOption &&
      other.name == name &&
      other.text == text &&
      const ListEquality<SpellId>().equals(other.spellIds, spellIds);

  @override
  int get hashCode => Object.hash(
    TextOption,
    name,
    text,
    const ListEquality<SpellId>().hash(spellIds),
  );

  @override
  String toString() => 'TextOption($name)';
}

String _validatedName(String name) {
  if (!ChoiceOption.isValidName(name)) {
    throw ArgumentError.value(
      name,
      'name',
      'must be non-empty with no leading or trailing whitespace',
    );
  }
  return name;
}

String _validatedText(String text) {
  if (!NamedText.isValidText(text)) {
    throw ArgumentError.value(
      text,
      'text',
      'must contain at least one non-whitespace character',
    );
  }
  return text;
}
