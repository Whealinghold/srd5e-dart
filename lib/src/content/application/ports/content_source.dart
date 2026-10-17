import '../../../shared_ports/errors/srd5e_exception.dart';
import '../../domain/content_entry.dart';
import '../../domain/content_key.dart';
import '../../domain/content_kind.dart';
import '../../domain/content_lookup.dart';
import '../../domain/content_query.dart';

/// Where the engine gets content from (content-source-port.md FR-007 to
/// FR-014): one entry by key, or every entry of one kind. Asynchronous
/// because implementations may reasonably do I/O; a host with a file or
/// network backend writes its own adapter.
///
/// **Failure contract** (architecture.md §4). Expected absence is a result:
/// [lookup] completes with [ContentNotFound], never throws for it. An
/// infrastructure failure (a backend down, an I/O error) completes the
/// returned future with [ContentSourceException] — it never throws
/// synchronously and is never reported as [ContentNotFound] or an empty
/// list (FR-017). An adapter whose backend can fail wraps its call with
/// `wrapPortFailureAsync` (`package:srd5e/srd5e.dart`), so the backend's
/// exception surfaces as [ContentSourceException] with the original kept as
/// `cause`; an `Error` is a programmer error and propagates unchanged.
///
/// **Writing an adapter.** The shared contract suite for this port lives in
/// `test/contract/content_source_contract.dart` of the srd5e repository. It
/// is deliberately not exported (it would make `package:test` a runtime
/// dependency); copy it into your tests and run its checks against your
/// implementation — `contentSourceContractChecks` for a source you can
/// build from arbitrary entries, `contentSourceReadOnlyChecks` for one
/// backed by a fixed fixture (content-source-port.md FR-050).
///
/// The bundled generic adapter is `InMemoryContentSource` and the SRD
/// content is served by `BundledContentSource`, both in
/// `package:srd5e/adapters.dart`; the test double is `FakeContentSource` in
/// `package:srd5e/testing.dart`.
abstract interface class ContentSource {
  /// Completes with the [ContentFound] entry whose key equals [key], or
  /// with [ContentNotFound] carrying the requested key (FR-008, FR-009).
  /// An entry of another kind is never returned for a key that exists only
  /// under that other kind (FR-010).
  Future<ContentLookup> lookup(ContentKey key);

  /// Completes with every entry of [kind], ordered by [ContentId] (ordinal,
  /// code-unit comparison) so results are deterministic (FR-011); empty
  /// when there is none, never an error (FR-012). The list is unmodifiable
  /// (FR-013) and repeated calls on an unchanged source give equal results
  /// (FR-014).
  Future<List<ContentEntry>> listKind(ContentKind kind);
}

/// A content source's infrastructure failure (content-source-port.md
/// FR-018): the backend behind a [ContentSource] failed, so the request
/// could not be answered. This is thrown — as a failed future, never for an
/// expected absence, which is [ContentNotFound].
///
/// It carries data, not display text (FR-019): the [query] that was being
/// asked when the backend failed (a switch over it is exhaustive; the query
/// variant is the operation), plus the [cause] and [causeStackTrace] the
/// adapter wrapped. Its [errorType] is the value of the `error.type`
/// telemetry attribute wherever the calling use case records this failure.
final class ContentSourceException extends Srd5eException {
  /// Creates the failure of [query], with the original [cause] and its
  /// [causeStackTrace], unchanged, or `null` when the failure did not come
  /// from a thrown object.
  const ContentSourceException(
    this.query, {
    super.cause,
    super.causeStackTrace,
  });

  /// What was being asked when the backend failed: a [ContentLookupQuery]
  /// for a lookup, a [ContentListKindQuery] for a list. Never null, and
  /// there is no separate operation field (FR-018).
  final ContentQuery query;

  /// The constant `content_source_exception`: the snake_case of this class
  /// name (FR-038).
  @override
  String get errorType => 'content_source_exception';

  /// The debugging form. Not display text, and not to be relied on (FR-019).
  @override
  String toString() => 'ContentSourceException($query)';
}
