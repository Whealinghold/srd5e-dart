import 'package:meta/meta.dart';

import 'content_id.dart';
import 'content_key.dart';
import 'missing_content.dart';

/// A typed id wrapping one [ContentId] (FR-114).
///
/// Typed ids are final classes, not extension types, so a cast cannot bypass
/// the id's invariant. Equality and the hash code are by type and id, so
/// `SpellId('a') != ClassId('a')`.
@immutable
abstract interface class TypedId {
  /// The wrapped id.
  ContentId get id;
}

/// A typed id whose entry kind is registered in a [ContentSource]: the id
/// addresses a whole entry by its [ContentKey] (FR-114).
///
/// [SubclassId] and [FeatureId] name entries nested inside a class,
/// subclass, species or feat entry and are [TypedId]s only: they have no key
/// and no kind and are never looked up in a content source.
@immutable
abstract interface class ContentKeyedId implements TypedId {
  /// The key of the entry this id addresses.
  ContentKey get key;

  /// The absence of the entry this id addresses, as a result detail.
  MissingContent get missing;
}

/// The result of a typed id's `tryCreate`: a wrapped id or a typed rejection.
///
/// Switch over it exhaustively, with no default branch. The rejection carries
/// the same [ContentIdProblem] and precedence as [ContentId.tryCreate].
@immutable
sealed class TypedIdParse<T extends TypedId> {
  const TypedIdParse();
}

/// A typed id's `tryCreate` accepted the string.
@immutable
final class TypedIdParsed<T extends TypedId> extends TypedIdParse<T> {
  /// Wraps the created [id].
  const TypedIdParsed(this.id);

  /// The typed id that was created.
  final T id;

  @override
  bool operator ==(Object other) => other is TypedIdParsed && other.id == id;

  @override
  int get hashCode => Object.hash(TypedIdParsed, id);

  @override
  String toString() => 'TypedIdParsed($id)';
}

/// A typed id's `tryCreate` rejected the string.
@immutable
final class TypedIdRejected<T extends TypedId> extends TypedIdParse<T> {
  /// Carries the typed [problem].
  const TypedIdRejected(this.problem);

  /// Why the string was rejected.
  final ContentIdProblem problem;

  @override
  bool operator ==(Object other) =>
      other is TypedIdRejected && other.problem == problem;

  @override
  int get hashCode => Object.hash(TypedIdRejected, problem);

  @override
  String toString() => 'TypedIdRejected(${problem.name})';
}
