import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import '../named_text.dart';

/// The tool proficiencies a class grants ("Tool Proficiency" rows of the
/// Core Traits tables, SRD 5.2.1, pp. 28, 31, 36, 41, 47, 49, 53, 57, 61,
/// 64, 70, 77) (FR-023).
///
/// The type is sealed with exactly the two variants, exhaustive in a
/// `switch` without a default. It is deliberately a separate class-side type
/// from the species spec's `ToolProficiency` (D10): the two share nothing.
@immutable
sealed class ClassToolProficiency {
  const ClassToolProficiency();
}

/// A specific tool: the Rogue's "Thieves' Tools" (FR-023; SRD 5.2.1, "Core
/// Rogue Traits", p. 61).
@immutable
final class ClassToolProficiencySpecific extends ClassToolProficiency {
  /// Creates the proficiency.
  ///
  /// Throws an [ArgumentError] carrying the name `name` and the offending
  /// value when [name] is blank (FR-023).
  ClassToolProficiencySpecific(String name) : name = _validatedName(name);

  /// The tool's printed name, verbatim ("Thieves' Tools", "Calligrapher's
  /// Supplies").
  final String name;

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

  @override
  bool operator ==(Object other) =>
      other is ClassToolProficiencySpecific && other.name == name;

  @override
  int get hashCode => Object.hash(ClassToolProficiencySpecific, name);

  @override
  String toString() => 'ClassToolProficiencySpecific($name)';
}

/// A choice of tool categories: the Bard's "Choose 3: Musical Instrument" or
/// the Monk's "one type of Artisan's Tools" (FR-023; SRD 5.2.1, "Core Bard
/// Traits", p. 31, "Core Monk Traits", p. 49).
@immutable
final class ClassToolProficiencyChoice extends ClassToolProficiency {
  /// Creates the proficiency from a defensive copy of [categories].
  ///
  /// Throws an [ArgumentError] carrying the name `categories` or `picks` and
  /// the offending value when [categories] is empty, holds a blank or
  /// repeated category, or [picks] is below [minPicks] (FR-023).
  ClassToolProficiencyChoice(List<String> categories, int picks)
    : categories = List.unmodifiable(_validatedCategories(categories)),
      picks = _validatedPicks(picks);

  /// The fewest picks a tool choice may ask the player to make: one (FR-023).
  /// The constant the decoder reuses instead of repeating the literal
  /// (FR-007).
  static const int minPicks = 1;

  /// The categories the player picks from, in printed order; unmodifiable,
  /// never empty, each a non-blank printed category name ("Musical
  /// Instrument", "Artisan's Tools") (FR-023).
  final List<String> categories;

  /// How many categories the player picks (FR-023); at least [minPicks].
  final int picks;

  /// Whether [picks] is a number of picks a tool choice may ask for: at
  /// least [minPicks] (FR-023). The predicate the decoder reuses (FR-007).
  static bool isValidPicks(int picks) => picks >= minPicks;

  /// Whether [category] is a category a tool choice may name: a non-blank
  /// string (FR-023). The predicate the decoder reuses (FR-007).
  static bool isValidCategory(String category) =>
      NamedText.isValidText(category);

  static int _validatedPicks(int picks) {
    if (!isValidPicks(picks)) {
      throw ArgumentError.value(picks, 'picks', 'must be $minPicks or more');
    }
    return picks;
  }

  static List<String> _validatedCategories(List<String> categories) {
    if (categories.isEmpty) {
      throw ArgumentError.value(categories, 'categories', 'must not be empty');
    }
    for (final category in categories) {
      if (!isValidCategory(category)) {
        throw ArgumentError.value(category, 'categories', 'must be non-blank');
      }
    }
    for (var i = 1; i < categories.length; i++) {
      if (categories.indexOf(categories[i]) != i) {
        throw ArgumentError.value(
          categories[i],
          'categories',
          'must be distinct',
        );
      }
    }
    return categories;
  }

  @override
  bool operator ==(Object other) =>
      other is ClassToolProficiencyChoice &&
      other.picks == picks &&
      const ListEquality<String>().equals(other.categories, categories);

  @override
  int get hashCode => Object.hash(
    ClassToolProficiencyChoice,
    picks,
    const ListEquality<String>().hash(categories),
  );

  @override
  String toString() => 'ClassToolProficiencyChoice($picks from $categories)';
}
