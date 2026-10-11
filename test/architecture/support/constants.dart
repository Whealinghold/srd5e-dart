// The named constants of the architecture guardrails
// (doc/specs/architecture-guardrails.md section 5, FR-009).
//
// These are the only exemptions the suite allows: no inline suppression
// exists. Every constant that copies a decision has a self-test in
// `constants_test.dart` that fails when its source text drifts.
//
// No name of a consuming project, trademark or affiliate is spelled out
// here (FR-068): each is a list of fragments joined at run time.

import 'source_set.dart';

/// Normalises [text] for the name scans of FR-025: lower-cased, with `-`, `_`
/// and whitespace removed. Both the term and the scanned text go through it.
String normaliseName(String text) =>
    text.toLowerCase().replaceAll(RegExp(r'[-_\s]'), '');

/// A name the suite must keep out of the repository, held as [fragments] so
/// no file contains it in plain text (FR-068).
final class DeniedName {
  /// Creates an entry whose name is the concatenation of [fragments].
  const DeniedName(this.fragments);

  /// The pieces of the name; joined with nothing they give the name.
  final List<String> fragments;

  /// The name assembled at run time.
  String get name => fragments.join();

  /// The name after [normaliseName].
  String get normalised => normaliseName(name);

  /// The name with [separator] between the fragments, for the separator form
  /// of FR-025.
  String spelled(String separator) => fragments.join(separator);

  /// Whether [text] mentions the name, after [normaliseName] on both sides.
  bool appearsIn(String text) => normaliseName(text).contains(normalised);
}

/// The entries of [list] that [text] mentions, in list order.
List<DeniedName> deniedNamesIn(String text, Iterable<DeniedName> list) => [
  for (final entry in list)
    if (entry.appearsIn(text)) entry,
];

/// Consuming projects and the hosting organisation (FR-025, FR-026).
///
/// A new consuming project is added here, as fragments, in the same change
/// that first introduces the dependency (FR-069).
const List<DeniedName> consumerDenylist = [
  DeniedName(['wheal', 'ing', 'hold']),
];

/// Trademarked edition, product and brand names (`content-licensing-and-notice.md`
/// FR-031). The bare licensor name is on no list.
const List<DeniedName> trademarkDenylist = [
  DeniedName(['dungeons', '&', 'dragons']),
  DeniedName(['dungeons', 'and', 'dragons']),
  DeniedName(['d', '&', 'd']),
  DeniedName(['player', "'s", 'handbook']),
  DeniedName(['dungeon', 'master', "'s", 'guide']),
  DeniedName(['monster', 'manual']),
  DeniedName(['forgotten', 'realms']),
];

/// Names of the licensor's parent and affiliates (`content-licensing-and-notice.md`
/// FR-031).
const List<DeniedName> affiliateDenylist = [
  DeniedName(['has', 'bro']),
];

/// Every list in this file that holds names, for the plain-text self-test of
/// FR-068.
const List<DeniedName> allDeniedNames = [
  ...consumerDenylist,
  ...trademarkDenylist,
  ...affiliateDenylist,
];

/// Entry points, besides the core ones, that may expose a `dart:io` adapter
/// (FR-013, FR-014, FR-017, FR-067). Empty today.
const Set<String> platformEntryPoints = {};

/// Files the consumer-name scan skips entirely (FR-026): they state the rule
/// and so must name its subject.
const Set<String> consumerScanExemptFiles = {'AGENTS.md', 'CLAUDE.md'};

/// The file whose `repository:` line the consumer-name scan skips (FR-026).
const String consumerScanExemptLineFile = 'pubspec.yaml';

/// The one line of [consumerScanExemptLineFile] the scan skips (FR-026).
final RegExp consumerScanExemptLine = RegExp(r'^repository:');

/// Package-name prefixes of observability and error-tracking SDKs (FR-032,
/// FR-033): a package equal to or starting with one is refused.
const List<String> sdkPackagePrefixes = [
  'opentelemetry',
  'dart_opentelemetry',
  'sentry',
  'logging',
  'logger',
  'datadog',
  'bugsnag',
  'newrelic',
  'firebase_crashlytics',
];

/// `dart:` libraries refused alongside the SDK packages (FR-032).
const Set<String> sdkLibraries = {'dart:developer'};

/// The only packages `pubspec.yaml` `dependencies:` may list (FR-083).
const Set<String> dependencyAllowlist = {'collection', 'meta'};

/// Generic variant names that no barrel may export (FR-077).
const Set<String> genericVariantNames = {
  'Applied',
  'Rejected',
  'Succeeded',
  'ContentMissing',
  'Found',
  'NotFound',
};

/// Name prefixes that mark a test double (FR-081).
const List<String> doublePrefixes = [
  'Fake',
  'Recording',
  'Fixed',
  'Scripted',
  'Stub',
  'Spy',
  'Mock',
];

/// Handles returned by ports, which are not ports themselves (FR-081, FR-082).
const Set<String> portHandles = {'Span', 'Counter', 'Histogram', 'Gauge'};

/// Attribute keys that are not `srd5e.`-prefixed (FR-036, FR-039).
const Set<String> reservedAttributeKeys = {'error.type'};

/// The key whose values are the snake_case names of `Srd5eException` subtypes
/// rather than a fixed set (FR-085).
const String exceptionTypeAttributeKey = 'error.type';

/// The closed value sets of the shared attribute keys (FR-085).
///
/// `error.type` is not here: its values come from the exception subtypes
/// declared in `lib/`.
const Map<String, Set<String>> sharedAttributeValueSets = {
  'srd5e.outcome': {'success', 'failure'},
  'srd5e.d20_test.kind': {'ability_check', 'saving_throw', 'attack_roll'},
  'srd5e.d20_test.roll_mode': {'normal', 'advantage', 'disadvantage'},
  'srd5e.d20_test.critical_hit': {'true', 'false'},
  'srd5e.d20_test.roller_failure': {'unavailable', 'invalid_result'},
  'srd5e.d20_test.forced_failure_reason': {'chosen_to_fail', 'automatic'},
};

/// The paths `NOTICE.md` must cover while bundled content is present (FR-079).
const Set<String> noticeCoveredPaths = {
  'data/',
  'lib/src/content/data/',
  'test/fixtures/srd/',
};

/// Contexts nothing may depend on (FR-098).
const Set<String> leafContexts = {'toolbox'};

/// Fixture spec names that spec citations may use without a file (FR-096).
const Set<String> placeholderSpecNames = {'x', 'y', 'z'};

/// Content data specs, which may depend only on the schema, the source port
/// and `package` specs (FR-099). File stems, without `.md`.
const Set<String> dataSpecs = {
  'content-thin-slice',
  'content-species-backgrounds-feats',
  'content-equipment',
  'content-spells',
  'content-monsters',
  'content-classes',
  'content-magic-items',
};

/// The documentation index (FR-102).
const String documentationIndexPath = 'doc/documentation_index.md';

/// Directories left out of every SourceSet (FR-002); the loader's own set.
const Set<String> excludedDirectories = SourceSet.excludedDirectories;

/// File names left out of every SourceSet (FR-002); the loader's own set.
const Set<String> excludedFiles = SourceSet.excludedFiles;

/// A spec of this rank or higher may list any spec and is exempt from the
/// phase rule (FR-092, FR-101).
const int highRankThreshold = 90;
