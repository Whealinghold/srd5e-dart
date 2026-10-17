import 'package:meta/meta.dart';

import 'content_id.dart';
import 'content_key.dart';
import 'content_kind.dart';
import 'missing_content.dart';
import 'typed_id.dart';

/// The shared shape of the typed ids: the wrapped [ContentId], equality and
/// hash code by type and id (FR-114).
///
/// Base, with a private constructor, so only the nine typed ids of this
/// library can extend it; the private name is invisible to other libraries.
@immutable
abstract base class TypedIdBase implements TypedId {
  const TypedIdBase._(this.id);

  /// Runs [ContentId.tryCreate] on [value] and wraps the created id with
  /// [construct] on acceptance, so a typed id's `tryCreate` rejects exactly
  /// when its constructor throws, with the same problem and precedence.
  static TypedIdParse<T> parse<T extends TypedId>(
    T Function(ContentId id) construct,
    String value,
  ) {
    final parse = ContentId.tryCreate(value);
    return switch (parse) {
      ContentIdParsed(:final id) => TypedIdParsed(construct(id)),
      ContentIdRejected(:final problem) => TypedIdRejected(problem),
    };
  }

  @override
  final ContentId id;

  @override
  bool operator ==(Object other) =>
      other is TypedIdBase &&
      other.runtimeType == runtimeType &&
      other.id == id;

  @override
  int get hashCode => Object.hash(runtimeType, id);

  @override
  String toString() => '$runtimeType(${id.value})';
}

/// The id of a species entry (FR-114); its key kind is [ContentKind.species].
@immutable
final class SpeciesId extends TypedIdBase implements ContentKeyedId {
  /// Creates a species id from [value].
  ///
  /// Throws an [ArgumentError] carrying the name `value` and the offending
  /// input when it is not a valid [ContentId]; see [tryCreate] for untrusted
  /// input.
  factory SpeciesId(String value) => SpeciesId._(ContentId(value));

  const SpeciesId._(super.id) : super._();

  /// Wraps the already valid [id].
  static SpeciesId of(ContentId id) => SpeciesId._(id);

  /// Creates a species id from untrusted input without throwing; it rejects
  /// exactly when the constructor throws.
  static TypedIdParse<SpeciesId> tryCreate(String value) =>
      TypedIdBase.parse(SpeciesId.of, value);

  @override
  ContentKey get key => ContentKey(ContentKind.species, id);

  @override
  MissingContent get missing => MissingContent(key.kind, id);
}

/// The id of a background entry (FR-114); its key kind is
/// [ContentKind.background].
@immutable
final class BackgroundId extends TypedIdBase implements ContentKeyedId {
  /// Creates a background id from [value].
  ///
  /// Throws an [ArgumentError] carrying the name `value` and the offending
  /// input when it is not a valid [ContentId]; see [tryCreate] for untrusted
  /// input.
  factory BackgroundId(String value) => BackgroundId._(ContentId(value));

  const BackgroundId._(super.id) : super._();

  /// Wraps the already valid [id].
  static BackgroundId of(ContentId id) => BackgroundId._(id);

  /// Creates a background id from untrusted input without throwing; it
  /// rejects exactly when the constructor throws.
  static TypedIdParse<BackgroundId> tryCreate(String value) =>
      TypedIdBase.parse(BackgroundId.of, value);

  @override
  ContentKey get key => ContentKey(ContentKind.background, id);

  @override
  MissingContent get missing => MissingContent(key.kind, id);
}

/// The id of a class entry (FR-114); its key kind is
/// [ContentKind.characterClass].
@immutable
final class ClassId extends TypedIdBase implements ContentKeyedId {
  /// Creates a class id from [value].
  ///
  /// Throws an [ArgumentError] carrying the name `value` and the offending
  /// input when it is not a valid [ContentId]; see [tryCreate] for untrusted
  /// input.
  factory ClassId(String value) => ClassId._(ContentId(value));

  const ClassId._(super.id) : super._();

  /// Wraps the already valid [id].
  static ClassId of(ContentId id) => ClassId._(id);

  /// Creates a class id from untrusted input without throwing; it rejects
  /// exactly when the constructor throws.
  static TypedIdParse<ClassId> tryCreate(String value) =>
      TypedIdBase.parse(ClassId.of, value);

  @override
  ContentKey get key => ContentKey(ContentKind.characterClass, id);

  @override
  MissingContent get missing => MissingContent(key.kind, id);
}

/// The id of a subclass nested inside a class entry (FR-114).
///
/// A subclass is never looked up in a content source, so this is a
/// [TypedId] only: it has no key, no kind and no missing detail.
@immutable
final class SubclassId extends TypedIdBase {
  /// Creates a subclass id from [value].
  ///
  /// Throws an [ArgumentError] carrying the name `value` and the offending
  /// input when it is not a valid [ContentId]; see [tryCreate] for untrusted
  /// input.
  factory SubclassId(String value) => SubclassId._(ContentId(value));

  const SubclassId._(super.id) : super._();

  /// Wraps the already valid [id].
  static SubclassId of(ContentId id) => SubclassId._(id);

  /// Creates a subclass id from untrusted input without throwing; it rejects
  /// exactly when the constructor throws.
  static TypedIdParse<SubclassId> tryCreate(String value) =>
      TypedIdBase.parse(SubclassId.of, value);
}

/// The id of a feat entry (FR-114); its key kind is [ContentKind.feat].
@immutable
final class FeatId extends TypedIdBase implements ContentKeyedId {
  /// Creates a feat id from [value].
  ///
  /// Throws an [ArgumentError] carrying the name `value` and the offending
  /// input when it is not a valid [ContentId]; see [tryCreate] for untrusted
  /// input.
  factory FeatId(String value) => FeatId._(ContentId(value));

  const FeatId._(super.id) : super._();

  /// Wraps the already valid [id].
  static FeatId of(ContentId id) => FeatId._(id);

  /// Creates a feat id from untrusted input without throwing; it rejects
  /// exactly when the constructor throws.
  static TypedIdParse<FeatId> tryCreate(String value) =>
      TypedIdBase.parse(FeatId.of, value);

  @override
  ContentKey get key => ContentKey(ContentKind.feat, id);

  @override
  MissingContent get missing => MissingContent(key.kind, id);
}

/// The id of a spell entry (FR-114); its key kind is [ContentKind.spell].
@immutable
final class SpellId extends TypedIdBase implements ContentKeyedId {
  /// Creates a spell id from [value].
  ///
  /// Throws an [ArgumentError] carrying the name `value` and the offending
  /// input when it is not a valid [ContentId]; see [tryCreate] for untrusted
  /// input.
  factory SpellId(String value) => SpellId._(ContentId(value));

  const SpellId._(super.id) : super._();

  /// Wraps the already valid [id].
  static SpellId of(ContentId id) => SpellId._(id);

  /// Creates a spell id from untrusted input without throwing; it rejects
  /// exactly when the constructor throws.
  static TypedIdParse<SpellId> tryCreate(String value) =>
      TypedIdBase.parse(SpellId.of, value);

  @override
  ContentKey get key => ContentKey(ContentKind.spell, id);

  @override
  MissingContent get missing => MissingContent(key.kind, id);
}

/// The id of an equipment entry (FR-114); its key kind is
/// [ContentKind.equipment].
@immutable
final class ItemId extends TypedIdBase implements ContentKeyedId {
  /// Creates an equipment id from [value].
  ///
  /// Throws an [ArgumentError] carrying the name `value` and the offending
  /// input when it is not a valid [ContentId]; see [tryCreate] for untrusted
  /// input.
  factory ItemId(String value) => ItemId._(ContentId(value));

  const ItemId._(super.id) : super._();

  /// Wraps the already valid [id].
  static ItemId of(ContentId id) => ItemId._(id);

  /// Creates an equipment id from untrusted input without throwing; it
  /// rejects exactly when the constructor throws.
  static TypedIdParse<ItemId> tryCreate(String value) =>
      TypedIdBase.parse(ItemId.of, value);

  @override
  ContentKey get key => ContentKey(ContentKind.equipment, id);

  @override
  MissingContent get missing => MissingContent(key.kind, id);
}

/// The id of a monster entry, covering the SRD's "Animals" stat blocks too
/// (FR-114); its key kind is [ContentKind.monster].
@immutable
final class MonsterId extends TypedIdBase implements ContentKeyedId {
  /// Creates a monster id from [value].
  ///
  /// Throws an [ArgumentError] carrying the name `value` and the offending
  /// input when it is not a valid [ContentId]; see [tryCreate] for untrusted
  /// input.
  factory MonsterId(String value) => MonsterId._(ContentId(value));

  const MonsterId._(super.id) : super._();

  /// Wraps the already valid [id].
  static MonsterId of(ContentId id) => MonsterId._(id);

  /// Creates a monster id from untrusted input without throwing; it rejects
  /// exactly when the constructor throws.
  static TypedIdParse<MonsterId> tryCreate(String value) =>
      TypedIdBase.parse(MonsterId.of, value);

  @override
  ContentKey get key => ContentKey(ContentKind.monster, id);

  @override
  MissingContent get missing => MissingContent(key.kind, id);
}

/// The id of a feature entry nested inside a class, subclass, species or
/// feat entry (FR-114).
///
/// A feature is never looked up in a content source, so this is a [TypedId]
/// only: it has no key, no kind and no missing detail.
@immutable
final class FeatureId extends TypedIdBase {
  /// Creates a feature id from [value].
  ///
  /// Throws an [ArgumentError] carrying the name `value` and the offending
  /// input when it is not a valid [ContentId]; see [tryCreate] for untrusted
  /// input.
  factory FeatureId(String value) => FeatureId._(ContentId(value));

  const FeatureId._(super.id) : super._();

  /// Wraps the already valid [id].
  static FeatureId of(ContentId id) => FeatureId._(id);

  /// Creates a feature id from untrusted input without throwing; it rejects
  /// exactly when the constructor throws.
  static TypedIdParse<FeatureId> tryCreate(String value) =>
      TypedIdBase.parse(FeatureId.of, value);
}
