import '../domain/content_kind.dart';
import '../domain/content_problem_kind.dart';

/// The names of the signals `LoadContentSet` emits and the attribute keys it
/// sets, defined once (doc/specs/content-schema-and-decoder.md section 7, the
/// single authority for these signals).
///
/// The names and keys are part of the public contract: renaming one is a
/// breaking change for consumers' dashboards and alerts
/// (`doc/rules/observability.md` §5). Call sites use the constants; no signal
/// or key appears as a string literal anywhere else. The key shared by every
/// signal, `srd5e.outcome`, is [AttributeKeys.outcome] in `shared_ports/`.
/// `error.type` is set only for a thrown `Srd5eException`, counted once on
/// `srd5e.content.loads` (FR-086(b)); the problems of a rejected document are
/// counted on `srd5e.content.decode_errors` by `srd5e.content.problem_kind`,
/// never by `error.type` (FR-100).
/// `doc/observability/signals.md` catalogues these signals.
abstract final class ContentSignals {
  /// The span that wraps one `LoadContentSet` call.
  static const String loadSpan = 'srd5e.content.load';

  /// The child span around the `ContentSetDecoder` port call.
  static const String decodeSpan = 'srd5e.content.decode';

  /// The counter of load attempts, by outcome.
  static const String loadsMetric = 'srd5e.content.loads';

  /// The counter of the problems of a rejected document, by problem kind.
  static const String decodeErrorsMetric = 'srd5e.content.decode_errors';

  /// The counter of the entries of a loaded set, by content kind.
  static const String entriesLoadedMetric = 'srd5e.content.entries_loaded';

  /// The histogram of load durations, in seconds; also recorded when the port
  /// throws (FR-080, FR-086).
  static const String loadDurationMetric = 'srd5e.content.load_duration';

  /// The key of the kind of the entries a load added.
  static const String kindAttribute = 'srd5e.content.kind';

  /// The key of the kind of one problem of a rejected document.
  static const String problemKindAttribute = 'srd5e.content.problem_kind';

  /// The `srd5e.outcome` value of a load that returned a result.
  static const String outcomeSuccessValue = 'success';

  /// The `srd5e.outcome` value of a load that returned `LoadContentSetRejected`
  /// or threw (FR-086).
  static const String outcomeFailureValue = 'failure';

  /// The `srd5e.content.kind` value of [kind]: the snake_case of its name, so
  /// `characterClass` is `character_class` (FR-101). The set of values is
  /// bounded by the content revision table.
  static String kindValue(ContentKind kind) => _snakeCase(kind.name);

  /// The `srd5e.content.problem_kind` value of [kind]: the snake_case of its
  /// name, so `unsupportedVersion` is `unsupported_version` (FR-100).
  static String problemKindValue(ContentProblemKind kind) =>
      _snakeCase(kind.name);

  /// The snake_case of a lower-camel-case enum name: an uppercase letter
  /// starts a word, preceded by an underscore and lower-cased.
  static String _snakeCase(String name) => name.replaceAllMapped(
    RegExp('[A-Z]'),
    (match) => '_${match.group(0)!.toLowerCase()}',
  );
}
