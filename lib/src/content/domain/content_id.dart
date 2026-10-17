import 'package:meta/meta.dart';

/// Why a string is not a [ContentId], the first failing check in declaration
/// order (FR-144).
enum ContentIdProblem {
  /// The string is empty.
  empty,

  /// The string is longer than [ContentId.maxLength] UTF-16 code units.
  tooLong,

  /// The string is not made of lowercase letters, digits and underscores with
  /// a letter first.
  invalidFormat,
}

/// The result of [ContentId.tryCreate]: a valid id or a typed rejection.
///
/// Switch over it exhaustively, with no default branch.
@immutable
sealed class ContentIdParse {
  const ContentIdParse();
}

/// [ContentId.tryCreate] accepted the string.
@immutable
final class ContentIdParsed extends ContentIdParse {
  /// Wraps the created [id].
  const ContentIdParsed(this.id);

  /// The id that was created.
  final ContentId id;

  @override
  bool operator ==(Object other) => other is ContentIdParsed && other.id == id;

  @override
  int get hashCode => Object.hash(ContentIdParsed, id);

  @override
  String toString() => 'ContentIdParsed(${id.value})';
}

/// [ContentId.tryCreate] rejected the string.
@immutable
final class ContentIdRejected extends ContentIdParse {
  /// Carries the typed [problem].
  const ContentIdRejected(this.problem);

  /// Why the string was rejected.
  final ContentIdProblem problem;

  @override
  bool operator ==(Object other) =>
      other is ContentIdRejected && other.problem == problem;

  @override
  int get hashCode => Object.hash(ContentIdRejected, problem);

  @override
  String toString() => 'ContentIdRejected(${problem.name})';
}

/// The identity of one content entry within its kind: a short lowercase
/// string such as `elf` or `acid_arrow_2`.
///
/// An id matches `[a-z][a-z0-9_]*` and is at most [maxLength] UTF-16 code
/// units (shared-types-and-ownership.md FR-007). The constructor throws an
/// [ArgumentError] carrying the name `value` and the offending input for a
/// string the rules exclude; [tryCreate] is the non-throwing form for
/// untrusted input. The id compares and hashes by its string.
@immutable
final class ContentId {
  /// Creates an id from [value].
  ///
  /// Throws an [ArgumentError] carrying the name `value` and [value] itself
  /// when it is empty, longer than [maxLength] or not of the shape
  /// `[a-z][a-z0-9_]*`. Use [tryCreate] for untrusted input.
  factory ContentId(String value) {
    final problem = _problemOf(value);
    if (problem != null) {
      throw ArgumentError.value(value, 'value', 'is not a content id');
    }
    return ContentId._(value);
  }

  const ContentId._(this.value);

  /// The most UTF-16 code units an id may have.
  static const int maxLength = 64;

  /// The shape of a valid id: a lowercase letter, then lowercase letters,
  /// digits and underscores.
  static final RegExp pattern = RegExp(r'^[a-z][a-z0-9_]*$');

  /// The id's characters.
  final String value;

  /// Creates an id from untrusted input without throwing.
  ///
  /// Returns [ContentIdParsed] exactly when the [ContentId] constructor would
  /// accept [value], and [ContentIdRejected] with the first failing check
  /// (empty, too long, wrong shape) otherwise.
  static ContentIdParse tryCreate(String value) {
    final problem = _problemOf(value);
    return problem == null
        ? ContentIdParsed(ContentId._(value))
        : ContentIdRejected(problem);
  }

  /// Whether [value] is a valid id: the [ContentId] constructor would accept
  /// it. The decoder's length limit (FR-030) is [maxLength].
  static bool isValid(String value) => _problemOf(value) == null;

  static ContentIdProblem? _problemOf(String value) {
    if (value.isEmpty) return ContentIdProblem.empty;
    if (value.length > maxLength) return ContentIdProblem.tooLong;
    if (!pattern.hasMatch(value)) return ContentIdProblem.invalidFormat;
    return null;
  }

  @override
  bool operator ==(Object other) => other is ContentId && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
