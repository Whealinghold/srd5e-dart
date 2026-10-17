import 'package:meta/meta.dart';

import '../domain/content_problem_kind.dart';

/// One problem a decoder or the whole-set validation found in content
/// (FR-014): a JSON Pointer [path] from the document root (`~` escaped as
/// `~0`, `/` as `~1`; the root itself is the empty string) and the
/// [ContentProblemKind], and nothing else — no display text.
///
/// Value equality over both fields (FR-097).
@immutable
final class ContentProblem {
  /// Creates the problem at [path] of [kind].
  const ContentProblem(this.path, this.kind);

  /// The JSON Pointer (RFC 6901) of the value the problem is about, from the
  /// document root.
  final String path;

  /// What is wrong with the value.
  final ContentProblemKind kind;

  @override
  bool operator ==(Object other) =>
      other is ContentProblem && other.path == path && other.kind == kind;

  @override
  int get hashCode => Object.hash(ContentProblem, path, kind);

  @override
  String toString() => 'ContentProblem($path, ${kind.name})';
}
