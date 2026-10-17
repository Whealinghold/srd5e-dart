/// The `schemaVersion` values this package's decoder supports (FR-007):
/// exactly the current version, `1`.
///
/// There is one version for the whole JSON format (FR-103): a content spec
/// that needs a format addition requests a revision-table row and claims no
/// version number. After the first release, a revision that rejects or
/// re-reads a previously valid document raises the version and is a breaking
/// change; until then every revision lands as this one version, so the set
/// holds a single member.
const Set<int> supportedSchemaVersions = {1};

/// The current `schemaVersion`, the single member of
/// [supportedSchemaVersions].
const int currentSchemaVersion = 1;
