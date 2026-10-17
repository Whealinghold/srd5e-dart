import 'package:meta/meta.dart';

import 'content_entry.dart';
import 'content_key.dart';
import 'missing_content.dart';

/// The outcome of a content lookup (content-source-port.md FR-015): the
/// entry is there ([ContentFound]) or it is not ([ContentNotFound]).
///
/// Expected absence is a result, not an exception (architecture.md §6).
/// Switch over it exhaustively, with no default branch.
@immutable
sealed class ContentLookup {
  /// Creates the outcome.
  const ContentLookup();
}

/// The asked-for entry is there (content-source-port.md FR-016).
@immutable
final class ContentFound extends ContentLookup {
  /// Carries the [entry] whose key was asked for.
  const ContentFound(this.entry);

  /// The entry found; its key equals the requested one (a
  /// [ContentCatalogue] never answers with another entry).
  final ContentEntry entry;

  @override
  bool operator ==(Object other) =>
      other is ContentFound && other.entry == entry;

  @override
  int get hashCode => Object.hash(ContentFound, entry);

  @override
  String toString() => 'ContentFound(${entry.key})';
}

/// No entry has the requested key (content-source-port.md FR-016).
///
/// The absence is never thrown: it is this result, carrying the requested
/// [key] and, through [missing], the [MissingContent] detail another
/// context's result variant holds as a field.
@immutable
final class ContentNotFound extends ContentLookup {
  /// Carries the requested [key].
  const ContentNotFound(this.key);

  /// The key that was asked for.
  final ContentKey key;

  /// The absence detail of [key]: the value a calling context's
  /// `...ContentMissing` result variant carries as a field
  /// (shared-types-and-ownership.md FR-018).
  MissingContent get missing => MissingContent(key.kind, key.id);

  @override
  bool operator ==(Object other) =>
      other is ContentNotFound && other.key == key;

  @override
  int get hashCode => Object.hash(ContentNotFound, key);

  @override
  String toString() => 'ContentNotFound($key)';
}
