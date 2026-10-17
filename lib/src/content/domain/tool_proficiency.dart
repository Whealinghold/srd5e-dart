import 'package:meta/meta.dart';

/// A tool proficiency a background grants ("Parts of a Background: Tool
/// Proficiency", SRD 5.2.1, p. 83), as a sealed family with exactly the two
/// variants the SRD prints (FR-119).
///
/// Switch over it exhaustively, with no default branch.
@immutable
sealed class ToolProficiency {
  const ToolProficiency();
}

/// Proficiency with one named tool ("Thieves’ Tools") (FR-119).
@immutable
final class SpecificToolProficiency extends ToolProficiency {
  /// Creates a specific-tool proficiency.
  ///
  /// Throws an [ArgumentError] carrying the name `name` and the offending
  /// value when [name] is empty or has leading or trailing whitespace.
  SpecificToolProficiency(String name) : name = _validatedName(name);

  /// The tool's name as printed, verbatim.
  final String name;

  @override
  bool operator ==(Object other) =>
      other is SpecificToolProficiency && other.name == name;

  @override
  int get hashCode => Object.hash(SpecificToolProficiency, name);

  @override
  String toString() => 'SpecificToolProficiency($name)';
}

/// A choice of one tool from a category, such as `Gaming Set` ("Soldier",
/// SRD 5.2.1, p. 83) (FR-119).
@immutable
final class ChoiceToolProficiency extends ToolProficiency {
  /// Creates a choice tool proficiency.
  ///
  /// Throws an [ArgumentError] carrying the name `category` and the
  /// offending value when [category] is blank.
  ChoiceToolProficiency(String category)
    : category = _validatedCategory(category);

  /// The category to choose from, as printed.
  final String category;

  @override
  bool operator ==(Object other) =>
      other is ChoiceToolProficiency && other.category == category;

  @override
  int get hashCode => Object.hash(ChoiceToolProficiency, category);

  @override
  String toString() => 'ChoiceToolProficiency($category)';
}

String _validatedName(String name) {
  if (name.isEmpty || name.trim() != name) {
    throw ArgumentError.value(
      name,
      'name',
      'must be non-empty with no leading or trailing whitespace',
    );
  }
  return name;
}

String _validatedCategory(String category) {
  if (category.trim().isEmpty) {
    throw ArgumentError.value(category, 'category', 'must not be blank');
  }
  return category;
}
