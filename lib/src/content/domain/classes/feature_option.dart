import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import '../content_id.dart';
import '../named_text.dart';
import 'feature_fact.dart';
import 'progression_row.dart' show ProgressionRow;

/// The id of one option of a feature's option list: a short lowercase string
/// such as `careful_spell` or `agonizing_blast` (FR-061).
///
/// An extension type over [String] with the same id rule as `ContentId`
/// (`[a-z][a-z0-9_]*`, at most [ContentId.maxLength] UTF-16 code units); the
/// factory rejects anything else. Ids are unique within their feature (the
/// [FeatureEntry] constructor checks); the same id under two features is two
/// options. It compares and hashes by its string, as the representation.
extension type const FeatureOptionId._(String _value) {
  /// Creates an option id from [value].
  ///
  /// Throws an [ArgumentError] carrying the name `value` and the offending
  /// input when it is not of the id shape or is longer than
  /// [ContentId.maxLength] (FR-061, schema FR-030).
  factory FeatureOptionId(String value) {
    final problem = _problemOf(value);
    if (problem != null) {
      throw ArgumentError.value(value, 'value', problem);
    }
    return FeatureOptionId._(value);
  }

  static String? _problemOf(String value) {
    if (value.isEmpty) return 'is empty';
    if (value.length > ContentId.maxLength) {
      return 'is longer than ${ContentId.maxLength} characters';
    }
    if (!ContentId.pattern.hasMatch(value)) {
      return 'is not a snake_case id (a lowercase letter, then lowercase '
          'letters, digits and underscores)';
    }
    return null;
  }

  /// The id's characters.
  String get value => _value;
}

/// The printed prerequisite of one feature option (FR-062; SRD 5.2.1,
/// "Eldritch Invocation Options", pp. 72-74).
///
/// At least one part must be present; an empty prerequisite is rejected. The
/// [requiresOptionIds] name other options of the same feature — existence,
/// self references and cycles are the [FeatureEntry] constructor's checks,
/// because only it holds the feature's option list.
@immutable
final class OptionPrerequisite {
  /// Creates the prerequisite from a defensive copy of [requiresOptionIds].
  ///
  /// Throws an [ArgumentError] carrying the name of the offending field and
  /// the offending value when [minClassLevel] is present but outside
  /// [ProgressionRow.minLevel] to [ProgressionRow.maxLevel], [note] is
  /// present but blank, or no part is present at all (FR-062).
  OptionPrerequisite({
    int? minClassLevel,
    List<FeatureOptionId> requiresOptionIds = const [],
    String? note,
  }) : minClassLevel = _validatedMinClassLevel(minClassLevel),
       requiresOptionIds = List.unmodifiable(requiresOptionIds),
       note = _validatedNote(note) {
    if (minClassLevel == null && requiresOptionIds.isEmpty && note == null) {
      throw ArgumentError.value(
        this,
        'prerequisite',
        'must carry at least one part (a minimum class level, a required '
            'option or a note) (FR-062)',
      );
    }
  }

  /// The lowest class level the option requires, from
  /// [ProgressionRow.minLevel] to [ProgressionRow.maxLevel], or null when
  /// the printed prerequisite states none (FR-062).
  final int? minClassLevel;

  /// The ids of the other options of the same feature the option requires;
  /// unmodifiable, possibly empty (FR-062). A self reference is not
  /// representable here — the [FeatureEntry] constructor rejects it.
  final List<FeatureOptionId> requiresOptionIds;

  /// The remaining printed requirement, verbatim ("a Warlock Cantrip That
  /// Deals Damage"), or null when the printed prerequisite states nothing
  /// else (FR-062).
  final String? note;

  static int? _validatedMinClassLevel(int? minClassLevel) {
    if (minClassLevel != null &&
        (minClassLevel < ProgressionRow.minLevel ||
            minClassLevel > ProgressionRow.maxLevel)) {
      throw ArgumentError.value(
        minClassLevel,
        'minClassLevel',
        'must be from ${ProgressionRow.minLevel} to '
            '${ProgressionRow.maxLevel}',
      );
    }
    return minClassLevel;
  }

  static String? _validatedNote(String? note) {
    if (note != null && !NamedText.isValidText(note)) {
      throw ArgumentError.value(note, 'note', 'must be non-blank');
    }
    return note;
  }

  @override
  bool operator ==(Object other) =>
      other is OptionPrerequisite &&
      other.minClassLevel == minClassLevel &&
      const ListEquality<FeatureOptionId>().equals(
        other.requiresOptionIds,
        requiresOptionIds,
      ) &&
      other.note == note;

  @override
  int get hashCode => Object.hash(
    OptionPrerequisite,
    minClassLevel,
    const ListEquality<FeatureOptionId>().hash(requiresOptionIds),
    note,
  );

  @override
  String toString() =>
      'OptionPrerequisite(minClassLevel: $minClassLevel, '
      'requiresOptionIds: $requiresOptionIds, note: $note)';
}

/// One option of a feature's option list — a catalogue of named, chosen
/// options: Metamagic, Eldritch Invocations, the Primal Order (FR-061;
/// SRD 5.2.1, "Level 1: Primal Order", p. 42, "Metamagic Options",
/// pp. 66-67).
///
/// An option list is a catalogue only; how many options a character holds is
/// stated by the feature text or a column (FR-061). An option may carry only
/// [AlwaysPreparedSpells] facts (FR-064).
@immutable
final class FeatureOption {
  /// Creates the option from a defensive copy of [facts].
  ///
  /// Throws an [ArgumentError] carrying the name of the offending field and
  /// the offending value when [name] or [text] breaks the text rules,
  /// [pointCost] is present but below [minPointCost] (FR-063), or [facts]
  /// holds a fact kind other than [AlwaysPreparedSpells] (FR-064).
  FeatureOption({
    required this.id,
    required String name,
    required String text,
    this.prerequisite,
    int? pointCost,
    this.repeatable = false,
    List<FeatureFact> facts = const [],
  }) : name = _validatedName(name),
       text = _validatedText(text),
       pointCost = _validatedPointCost(pointCost),
       facts = List.unmodifiable(_validatedFacts(facts));

  /// The option's id, unique within its feature (FR-061).
  final FeatureOptionId id;

  /// The option's printed name, verbatim ("Careful Spell").
  final String name;

  /// The option's printed text, verbatim (FR-054, FR-061).
  final String text;

  /// The printed prerequisite, or null when the option prints none
  /// (FR-062).
  final OptionPrerequisite? prerequisite;

  /// The Sorcery Points the option costs ("Cost: 2 Sorcery Points"), at
  /// least [minPointCost], or null when the option prints no cost (FR-063).
  final int? pointCost;

  /// Whether the SRD prints "Repeatable" for the option (FR-063).
  final bool repeatable;

  /// The option's facts; unmodifiable, possibly empty, each an
  /// [AlwaysPreparedSpells] (FR-064).
  final List<FeatureFact> facts;

  /// The lowest point cost an option may carry: 1 (FR-063). The constant the
  /// decoder reuses instead of repeating the literal (FR-007).
  static const int minPointCost = 1;

  /// Whether [pointCost] is a point cost an option may carry: null or at
  /// least [minPointCost] (FR-063). The predicate the decoder reuses
  /// (FR-007).
  static bool isValidPointCost(int? pointCost) =>
      pointCost == null || pointCost >= minPointCost;

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

  static String _validatedText(String text) {
    if (!NamedText.isValidText(text)) {
      throw ArgumentError.value(
        text,
        'text',
        'must contain at least one non-whitespace character',
      );
    }
    return text;
  }

  static int? _validatedPointCost(int? pointCost) {
    if (!isValidPointCost(pointCost)) {
      throw ArgumentError.value(
        pointCost,
        'pointCost',
        'must be $minPointCost or more',
      );
    }
    return pointCost;
  }

  static List<FeatureFact> _validatedFacts(List<FeatureFact> facts) {
    for (final fact in facts) {
      if (fact is! AlwaysPreparedSpells) {
        throw ArgumentError.value(
          fact,
          'facts',
          'must hold only AlwaysPreparedSpells facts (FR-064)',
        );
      }
    }
    return facts;
  }

  @override
  bool operator ==(Object other) =>
      other is FeatureOption &&
      other.id == id &&
      other.name == name &&
      other.text == text &&
      other.prerequisite == prerequisite &&
      other.pointCost == pointCost &&
      other.repeatable == repeatable &&
      const ListEquality<FeatureFact>().equals(other.facts, facts);

  @override
  int get hashCode => Object.hash(
    FeatureOption,
    id,
    name,
    text,
    prerequisite,
    pointCost,
    repeatable,
    const ListEquality<FeatureFact>().hash(facts),
  );

  @override
  String toString() => 'FeatureOption(${id.value})';
}
