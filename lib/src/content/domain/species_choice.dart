import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import 'choice_option.dart';
import 'named_text.dart';

/// One species choice: the trait it extends and the closed list of options
/// the player picks from (FR-016, SX-1; SRD 5.2.1, pp. 84-86).
///
/// Every option of one choice has the same variant (FR-016); the trait name
/// must name a trait of the same species, which the [Species] constructor
/// checks (FR-060) — this type cannot see the species' traits.
@immutable
final class SpeciesChoice {
  /// Creates a species choice from a defensive copy of [options].
  ///
  /// Throws an [ArgumentError] carrying the name `traitName` or `options`
  /// and the offending value when [traitName] breaks the name rule (FR-027),
  /// [options] is empty, repeats an option name, or holds options of more
  /// than one variant (FR-016).
  SpeciesChoice(String traitName, List<ChoiceOption> options)
    : traitName = _validatedTraitName(traitName),
      options = List.unmodifiable(_validatedOptions(options));

  /// The smallest number of options a choice may hold (FR-016). The constant
  /// the decoder reuses instead of repeating the literal (FR-069).
  static const int minOptions = 1;

  /// The name of the trait the choice extends, as printed ("Draconic
  /// Ancestry", "Elven Lineage").
  final String traitName;

  /// The options, all of one variant, in printed order; unmodifiable, never
  /// empty.
  final List<ChoiceOption> options;

  static String _validatedTraitName(String traitName) {
    if (!NamedText.isValidName(traitName)) {
      throw ArgumentError.value(
        traitName,
        'traitName',
        'must be non-empty with no leading or trailing whitespace',
      );
    }
    return traitName;
  }

  static List<ChoiceOption> _validatedOptions(List<ChoiceOption> options) {
    if (options.length < minOptions) {
      throw ArgumentError.value(
        options,
        'options',
        'must have at least $minOptions option',
      );
    }
    for (var i = 1; i < options.length; i++) {
      final name = options[i].name;
      if (options.sublist(0, i).any((option) => option.name == name)) {
        throw ArgumentError.value(
          name,
          'options',
          'must not repeat an option name',
        );
      }
    }
    for (var i = 1; i < options.length; i++) {
      if (options[i].runtimeType != options[0].runtimeType) {
        throw ArgumentError.value(
          options[i],
          'options',
          'every option of one choice must have the same variant',
        );
      }
    }
    return options;
  }

  @override
  bool operator ==(Object other) =>
      other is SpeciesChoice &&
      other.traitName == traitName &&
      const ListEquality<ChoiceOption>().equals(other.options, options);

  @override
  int get hashCode =>
      Object.hash(traitName, const ListEquality<ChoiceOption>().hash(options));

  @override
  String toString() => 'SpeciesChoice($traitName)';
}
