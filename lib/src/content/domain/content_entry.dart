import 'package:meta/meta.dart';

import 'content_key.dart';

/// One entry of a content set: every content entry implements it (FR-146).
///
/// The interface carries the entry's [key] only. Every implementation is
/// immutable, so holding an entry by its key and reading its fields is safe
/// anywhere.
@immutable
abstract interface class ContentEntry {
  /// The kind and id that identify this entry.
  ContentKey get key;
}
