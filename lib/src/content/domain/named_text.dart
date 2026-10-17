import 'package:meta/meta.dart';

/// A named, verbatim printed text: a species Special Trait, or any list of
/// named texts a content entry carries (FR-116).
///
/// `name` must be a non-empty string with no leading or trailing whitespace
/// and `text` must contain at least one non-whitespace character, otherwise
/// the constructor throws an [ArgumentError] carrying the offending field's
/// name and value (FR-027, FR-028). The text is stored verbatim; nothing
/// trims, wraps, normalises or rewords it (FR-029). The JSON form is
/// `{name, text}` with no other key.
@immutable
final class NamedText {
  /// Creates a named text.
  ///
  /// Throws an [ArgumentError] carrying the name `name` or `text` and the
  /// offending value when a part breaks the rules above.
  NamedText(String name, String text)
    : name = _validatedName(name),
      text = _validatedText(text);

  /// The run-in heading, verbatim.
  final String name;

  /// The printed text, verbatim.
  final String text;

  /// Whether [name] is a valid name: non-empty, no leading or trailing
  /// whitespace (FR-027).
  static bool isValidName(String name) =>
      name.isNotEmpty && name.trim() == name;

  /// Whether [text] is a valid text: it contains at least one
  /// non-whitespace character (FR-028).
  static bool isValidText(String text) => text.trim().isNotEmpty;

  static String _validatedName(String name) {
    if (!isValidName(name)) {
      throw ArgumentError.value(
        name,
        'name',
        'must be non-empty with no leading or trailing whitespace',
      );
    }
    return name;
  }

  static String _validatedText(String text) {
    if (!isValidText(text)) {
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
      other is NamedText && other.name == name && other.text == text;

  @override
  int get hashCode => Object.hash(NamedText, name, text);

  @override
  String toString() => 'NamedText($name)';
}
