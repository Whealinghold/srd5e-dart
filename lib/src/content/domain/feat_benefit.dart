import 'package:meta/meta.dart';

import 'named_text.dart';

/// One benefit of a feat: its optional run-in heading and its verbatim text
/// ("Parts of a Feat: Benefit", SRD 5.2.1, p. 87) (FR-040, FR-063).
///
/// A feat printed as one block has exactly one benefit with no [name]
/// (FR-040); a named benefit ("Initiative Proficiency", "Two Cantrips")
/// carries the printed heading.
@immutable
final class FeatBenefit {
  /// Creates a feat benefit.
  ///
  /// Throws an [ArgumentError] carrying the name `name` or `text` and the
  /// offending value when [name] is present but breaks the name rule
  /// (FR-027) or [text] holds no non-whitespace character (FR-028).
  FeatBenefit({String? name, required String text})
    : name = _validatedName(name),
      text = _validatedText(text);

  /// The benefit's printed heading, verbatim, or null for a benefit printed
  /// without one (FR-040, FR-063).
  final String? name;

  /// The benefit's text, verbatim (FR-063).
  final String text;

  static String? _validatedName(String? name) {
    if (name != null && !NamedText.isValidName(name)) {
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

  @override
  bool operator ==(Object other) =>
      other is FeatBenefit && other.name == name && other.text == text;

  @override
  int get hashCode => Object.hash(FeatBenefit, name, text);

  @override
  String toString() =>
      name == null ? 'FeatBenefit($text)' : 'FeatBenefit($name, $text)';
}
