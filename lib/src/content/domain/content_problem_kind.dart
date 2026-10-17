/// The kinds of problem a decoder or a validation can report about content
/// (FR-015).
///
/// The kinds are closed: a content spec that needs another requests a
/// revision row. A problem carries a path and one of these kinds only, and
/// no display text (FR-014). The declaration order is the order FR-016
/// orders duplicate groups and FR-100 lists the telemetry values by.
enum ContentProblemKind {
  /// The text is not valid JSON.
  syntax,

  /// The `schemaVersion` is not supported.
  unsupportedVersion,

  /// A required field is absent.
  missingField,

  /// A key is not declared for its object.
  unknownField,

  /// A value is of the wrong JSON type, or null where a value is required.
  wrongType,

  /// A number or array length is outside its declared bounds.
  outOfRange,

  /// A value is of the right type but not one of the allowed values.
  invalidValue,

  /// A value appears twice where it must appear once.
  duplicate,

  /// A reference names an entry that is in no set.
  unresolvedReference,

  /// The target of a reference exists but fails the site's constraint.
  constraintViolation,
}
