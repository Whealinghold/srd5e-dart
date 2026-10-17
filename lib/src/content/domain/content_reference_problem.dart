import 'package:meta/meta.dart';

import 'content_key.dart';
import 'content_problem_kind.dart';

/// One cross-entry problem the whole-set validation found (FR-125).
///
/// A value object carrying the [owner] entry's key, the [field] inside it
/// (a path relative to the entry, such as `feat/featId`; the empty string
/// when the problem is about the entry itself, as a key held by two sets),
/// the [target] key and the problem [kind]: [ContentProblemKind.duplicate]
/// (the same key in two sets), [ContentProblemKind.unresolvedReference]
/// (the target key is in no set) or [ContentProblemKind.constraintViolation]
/// (the target exists but fails the site's constraint). It carries no
/// display text.
@immutable
final class ContentReferenceProblem {
  /// Creates the problem.
  const ContentReferenceProblem({
    required this.owner,
    required this.field,
    required this.target,
    required this.kind,
  });

  /// The entry whose reference (or, for a duplicate, whose key) is at fault.
  final ContentKey owner;

  /// The field inside the owner the problem is about; empty when it is the
  /// entry itself.
  final String field;

  /// The key the reference names, or the duplicated key itself.
  final ContentKey target;

  /// Why the cross-entry check failed: duplicate, unresolvedReference or
  /// constraintViolation.
  final ContentProblemKind kind;

  @override
  bool operator ==(Object other) =>
      other is ContentReferenceProblem &&
      other.owner == owner &&
      other.field == field &&
      other.target == target &&
      other.kind == kind;

  @override
  int get hashCode => Object.hash(owner, field, target, kind);

  @override
  String toString() => field.isEmpty
      ? 'ContentReferenceProblem($owner -> $target, ${kind.name})'
      : 'ContentReferenceProblem($owner/$field -> $target, ${kind.name})';
}
