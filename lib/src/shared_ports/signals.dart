/// The attribute keys shared by every signal srd5e emits.
///
/// This is the only place under `lib/` that spells the shared keys out. Call
/// sites refer to the constants, so metrics, spans and logs agree on the key,
/// and the strings are part of the public contract: renaming one is a breaking
/// change for consumers' dashboards and alerts.
///
/// The class defines key names only. The values each key may take are listed
/// in `doc/rules/observability.md` §5 and in `doc/observability/signals.md`.
abstract final class AttributeKeys {
  /// The key of the outcome of an operation: `success` or `failure`.
  ///
  /// A normal rule outcome (a failed check) is a `success` of the operation; a
  /// returned failure result (content that fails to decode, content not found)
  /// is a `failure`.
  static const String outcome = 'srd5e.outcome';

  /// The key of the kind of a thrown failure: one value per `Srd5eException`
  /// subtype, read from its `errorType`.
  ///
  /// It is set only for a thrown failure, never for a returned failure result.
  static const String errorType = 'error.type';
}
