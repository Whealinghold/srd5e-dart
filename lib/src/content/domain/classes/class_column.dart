import 'package:meta/meta.dart';

import '../content_id.dart';
import '../named_text.dart';

/// The id of one class-specific column of a Features table: a short
/// lowercase string such as `rages` or `ki_points` (FR-036).
///
/// An extension type over [String] with the same id rule as `ContentId`
/// (`[a-z][a-z0-9_]*`, at most [ContentId.maxLength] UTF-16 code units); the
/// factory rejects anything else. Ids are unique within their class (the
/// [ClassDefinition] constructor checks); the same id under two classes is
/// two columns. It compares and hashes by its string, as the representation.
extension type const ClassColumnId._(String _value) {
  /// Creates a column id from [value].
  ///
  /// Throws an [ArgumentError] carrying the name `value` and the offending
  /// input when it is not of the id shape or is longer than
  /// [ContentId.maxLength] (FR-036, schema FR-030).
  factory ClassColumnId(String value) {
    final problem = _problemOf(value);
    if (problem != null) {
      throw ArgumentError.value(value, 'value', problem);
    }
    return ClassColumnId._(value);
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

/// One of the four kinds a class-specific column can have (FR-036).
///
/// The JSON spelling is the lower camel case tag. The kind says how a cell
/// is read: a count, a dice expression (`2d6`), a flat bonus, or a bonus in
/// feet. The printed em dash ("—") is `ColumnNone` under every kind (FR-040).
enum ClassColumnKind {
  /// A whole-number count, 0 or more (`ColumnCount`).
  count('count'),

  /// A dice expression (`ColumnDice`).
  dice('dice'),

  /// A flat bonus, 0 or more (`ColumnBonus`).
  bonus('bonus'),

  /// A bonus in feet (`ColumnFeetBonus`).
  feetBonus('feetBonus');

  const ClassColumnKind(this.jsonValue);

  /// The lower camel case tag used in JSON.
  final String jsonValue;

  /// The member whose [jsonValue] is [value], or null for a non-member: the
  /// decoder turns a non-member into `invalidValue` (FR-105, FR-025).
  static ClassColumnKind? fromJson(String value) => switch (value) {
    'count' => count,
    'dice' => dice,
    'bonus' => bonus,
    'feetBonus' => feetBonus,
    _ => null,
  };
}

/// One class-specific column of a class's Features table: its id, the
/// printed heading and the kind its cells carry (FR-036; SRD 5.2.1,
/// Features tables, pp. 28-77).
@immutable
final class ClassColumn {
  /// Creates a column.
  ///
  /// Throws an [ArgumentError] carrying the name `header` and the offending
  /// value when [header] breaks the name rule (FR-036).
  ClassColumn({required this.id, required String header, required this.kind})
    : header = _validatedHeader(header);

  /// The column's id, unique within its class (FR-036).
  final ClassColumnId id;

  /// The printed column heading, verbatim ("Rages", "Focus Points").
  final String header;

  /// The kind the column's cells carry (FR-036, FR-040).
  final ClassColumnKind kind;

  static String _validatedHeader(String header) {
    if (!NamedText.isValidName(header)) {
      throw ArgumentError.value(
        header,
        'header',
        'must be non-empty with no leading or trailing whitespace',
      );
    }
    return header;
  }

  @override
  bool operator ==(Object other) =>
      other is ClassColumn &&
      other.id == id &&
      other.header == header &&
      other.kind == kind;

  @override
  int get hashCode => Object.hash(ClassColumn, id, header, kind);

  @override
  String toString() => 'ClassColumn($id, $header, ${kind.name})';
}
