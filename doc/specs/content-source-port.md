# ContentSource port

| | |
|---|---|
| Status | implemented |
| Context | `content` |
| Roadmap phase | 2 |
| Depends on | `errors-and-results.md`, `content-schema-and-decoder.md` |

Binding decisions: [shared-types-and-ownership.md](shared-types-and-ownership.md) (rank 0, FR-056): FR-005
and FR-046 (vocabulary and typed ids owned by the decoder spec), FR-064 (the identity types `ContentId`,
`ContentIdProblem`, `ContentKey`, `ContentKind`, `ContentEntry` and `MissingContent` are owned by the decoder
spec; this spec depends on it), FR-007 (id format), FR-013 and FR-014
(dependency and phase rules), FR-017 and FR-018 (result naming, `MissingContent`), FR-030 to FR-033
(bundled delivery), FR-034 to FR-039 (schema version, ports, doubles, contract suites), FR-041
(`error.type` values), FR-044 (no use case calls a use case), FR-047 (`BundledContentSource` owner),
FR-048 (topic spec owns mechanics). [errors-and-results.md](errors-and-results.md) supplies
`Srd5eException`, `wrapPortFailureAsync` (in `shared_ports/errors/`, shared-types-and-ownership.md FR-055) and the result and port
conventions.

Consumers (never listed in the header): the bundled-data specs (each adds its embedded library, FR-064) and
the `character`, `combat` and `toolbox` use cases. `content` has no upstream context (architecture.md §2),
so the domain depends on `shared_kernel` only; the port depends on `shared_kernel` and `shared_ports`.

Direction with [content-schema-and-decoder.md](content-schema-and-decoder.md) (rank 4, lower, listed in the
header): that spec owns the identity types this spec uses (`ContentKind`, `ContentId`, `ContentKey`,
`ContentEntry`, `MissingContent`; its FR-142 to FR-148) and the typed ids with their kind mapping (its FR-114).
The port, `ContentLookup`, `ContentQuery` and `ContentCatalogue` use them; none is defined here. Only the
`BundledContentSource` adapter (FR-059 to FR-064) needs `ContentSetDecoder`, `ContentSet`, `validateContentSet`
and `embeddedDocuments` (its FR-104, FR-114, FR-122, FR-125 to FR-127, FR-129), because
shared-types-and-ownership.md FR-047 fixes the adapter's owner here. The adapter sits in `adapters/`; the domain
and port never import the decoder.

## 1. Purpose and scope

Defines how the rest of the package asks "give me the content entry with this key" without knowing where
content lives. It specifies:

- the `ContentSource` driven port (asynchronous), keyed by the `ContentKey` of `content-schema-and-decoder.md`
  (the identity types and typed ids are owned there, shared-types-and-ownership.md FR-046, FR-064);
- sealed `ContentQuery` (FR-057) and sealed `ContentLookup` (`ContentFound` | `ContentNotFound`, which carries
  the `MissingContent` of the schema spec, shared-types-and-ownership.md FR-018);
- `ContentCatalogue`, a pure in-memory index every in-process source delegates to, so duplicate-key, lookup
  and ordering rules are written and tested once;
- `ContentSourceException` (a `Srd5eException`), `InMemoryContentSource` and `BundledContentSource` with
  `BundledContentInvalid` (both exported from `lib/adapters.dart` only; FR-059 to FR-064);
- the contract suites (`test/contract/`, not exported: shared-types-and-ownership.md FR-039; FR-027,
  FR-058) and `FakeContentSource` (`lib/src/testing/`, exported only by `lib/testing.dart`: FR-038 there).

**Out of scope:** the shape of individual entries, every closed vocabulary type and the identity types
(`ContentId`, `ContentKey`, `ContentKind`, `ContentEntry`, `MissingContent`; `content-schema-and-decoder.md`,
shared-types-and-ownership.md FR-046, FR-064); JSON decoding, the envelope and
`schemaVersion` (FR-034, FR-035 there); bundled SRD data, its generator and `NOTICE.md` coverage
(shared-types-and-ownership.md FR-030 to FR-033; the bundled-data specs); `dart:io` or network sources;
search, filtering and pagination beyond "all entries of a kind"; reload, caching or mutation after
construction; "unsupported content version" (a decoder failure, section 9); use cases that call the port and
their telemetry. No SRD game rule is implemented here.

## 2. Source

n/a (package design); the SRD 5.2.1 category headings behind `ContentKind` are cited by
content-schema-and-decoder.md FR-142. Derived from `doc/rules/architecture.md` §1 to §7 and §9,
`doc/rules/observability.md` §2, §3, §7, `doc/rules/testing.md` §3, §4, §5, §8, §10,
`shared-types-and-ownership.md`, `errors-and-results.md` and `doc/roadmap.md` Phase 2.

## 3. Vocabulary

| Term | Type | Notes |
|---|---|---|
| Identity types | `ContentKind`, `ContentId`, `ContentIdParse`, `ContentIdProblem`, `ContentKey`, `ContentEntry`, `MissingContent` | **Owned by content-schema-and-decoder.md** (FR-142 to FR-148; shared-types-and-ownership.md FR-064) and used here, not defined. The typed ids and the typed id to `ContentKind` mapping (`id.key`) are its FR-114 and section 3 table. |
| `ContentSource` | driven port (abstract interface class) | Asynchronous. Named for what the domain needs, not the technology. `content/application/ports/`. |
| `ContentQuery` | sealed class (domain) | What was asked of a source: `ContentLookupQuery(key)` or `ContentListKindQuery(kind)`. Pure value; used by `ContentSourceException` and by the double's recording. |
| `ContentLookup` | sealed class (domain) | `ContentFound(entry)` carries the `ContentEntry`; `ContentNotFound(key)` carries the requested `ContentKey`. Not generic. Variants carry the operation prefix `Content` (shared-types-and-ownership.md FR-017); the bare names `Found` and `NotFound` are never exported. |
| `ContentCatalogue` | value object (domain) | Immutable, validated index of entries: rejects duplicate keys, answers `lookup(key)` as a `ContentLookup` and `ofKind(kind)` as an ordered unmodifiable list. Pure and synchronous. |
| `ContentSourceException` | final class, extends `Srd5eException` (`application/ports/`) | Infrastructure failure in a source. Carries one non-null `query` (`ContentQuery`), `cause`, `causeStackTrace`. There is no separate operation enum: the `query` variant is the operation. |
| `InMemoryContentSource` | adapter (`adapters/`) | Thin async wrapper over a `ContentCatalogue`. Exported from `lib/adapters.dart` only. |
| `BundledContentSource` | adapter (`adapters/`) | Serves the embedded SRD libraries: decodes them through `ContentSetDecoder`, validates the set with `validateContentSet`, delegates to `InMemoryContentSource`. Exported from `lib/adapters.dart` only. Owner: this spec (shared-types-and-ownership.md FR-047). |
| `BundledContentInvalid` | `Error` subclass (`adapters/`) | Thrown by the `BundledContentSource` constructor when the embedded documents fail to decode or the merged set fails whole-set validation; carries the decoder's `ContentProblem`s and the `ContentReferenceProblem`s, in two lists, at least one non-empty. |
| `ContentSourceCheck` | value class (`test/contract/`) | A named contract check: `name` and `Future<void> Function() run`. Not exported. |
| `contentSourceContractChecks` | function (`test/contract/`) | Builds the shared contract suite, for sources that can be built from arbitrary entries, as a list of `ContentSourceCheck`. Not exported. |
| `contentSourceReadOnlyChecks` | function (`test/contract/`) | Builds the read-only variant, for sources backed by a fixed fixture, as a list of `ContentSourceCheck`. Not exported. |
| `FakeContentSource` | test double (`lib/src/testing/`) | Wraps a `ContentCatalogue`; scriptable failure and recorded queries (`ContentQuery`). Exported only by `lib/testing.dart`. A double, not an adapter. |

### Kind mapping

The mapping from each top-level typed id to its `ContentKind` (so `source.lookup(id.key)` works, and
`SubclassId` and `FeatureId` have no kind) and the table of `ContentKind` values against the SRD headings are
owned by content-schema-and-decoder.md (section 3 and FR-114, FR-142). This spec relies on them and repeats
neither.

## 4. Requirements

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-007 | `ContentSource.lookup(ContentKey)` MUST return `Future<ContentLookup>` and MUST NOT use `FutureOr`. | architecture.md §4 (sync or async) | happy |
| FR-008 | `lookup` MUST complete with `ContentFound` holding the entry whose `key` equals the requested key when such an entry exists. | architecture.md §4 (failure contract) | happy |
| FR-009 | `lookup` MUST complete with `ContentNotFound` carrying the requested `ContentKey` when no entry has that key; it MUST NOT throw. | architecture.md §4, §6 | unhappy (missing content) |
| FR-010 | `lookup` MUST NOT return an entry of a different kind for a key whose id exists only under another kind. | architecture.md §4 | unhappy (rule interaction) |
| FR-011 | `ContentSource.listKind(ContentKind)` MUST complete with every entry of that kind, ordered by `ContentId` using ordinal (code unit) string comparison, so results are deterministic. | architecture.md §3 (determinism) | happy |
| FR-012 | `listKind` MUST complete with an empty list, not an error or `ContentNotFound`, when the source has no entries of that kind. | architecture.md §4 | unhappy (empty case) |
| FR-013 | The list returned by `listKind` MUST be unmodifiable; mutating it MUST throw `UnsupportedError` and MUST NOT alter the source. | architecture.md §4 (handoffs) | unhappy (immutability) |
| FR-014 | Repeated calls to `lookup` and `listKind` on an unchanged source MUST return equal results: the same `ContentFound` or `ContentNotFound` variant with an entry or key that is `identical` or `==`, and lists of the same length whose elements are pairwise `identical` or `==`, in the same order. This applies to `InMemoryContentSource` and to `FakeContentSource` given the same entries and script (no clock, randomness or I/O). | testing.md §4 (determinism); architecture.md §3 | happy |
| FR-015 | `ContentLookup` MUST be sealed with exactly the variants `ContentFound` and `ContentNotFound`, so a `switch` over it is exhaustive without a default. | architecture.md §3, §4 | happy |
| FR-016 | `ContentFound` MUST expose its `ContentEntry` and `ContentNotFound` MUST expose the requested `ContentKey` and a `missing` getter equal to the `MissingContent` of that key (content-schema-and-decoder.md FR-147); both MUST be immutable and compare by value (two `ContentFound`s are equal iff their entries are equal; two `ContentNotFound`s iff their keys are equal). `ContentLookup` is not generic. | architecture.md §3, §4 | happy |
| FR-017 | A source whose backend fails MUST complete the `lookup` or `listKind` future with `ContentSourceException`; it MUST NOT return `ContentNotFound` or an empty list for an infrastructure failure, and MUST NOT throw synchronously: the failure is delivered through the returned (failed) `Future`. Adapters MUST wrap their backend call with `wrapPortFailureAsync`. | architecture.md §4 (failure contract); errors-and-results.md FR-016, FR-032 | unhappy (collaborator failure) |
| FR-018 | `ContentSourceException` MUST carry one non-null `query` (a `ContentQuery`: `ContentLookupQuery(key)` for a `lookup`, `ContentListKindQuery(kind)` for a `listKind`) and the original error as `cause`, and MUST be a subtype of `Srd5eException`. It has no nullable `key` or `kind` field and no separate operation field; a `switch` over `query` is exhaustive. | architecture.md §4, §6 | unhappy (collaborator failure) |
| FR-019 | `ContentSourceException`, `ContentLookup`, `ContentFound` and `ContentNotFound` MUST carry structured data only: no field or getter named `message`, `description`, `text`, `displayText` or holding pre-formatted display text. `toString` is for debugging and no test depends on it. | architecture.md §6; errors-and-results.md FR-007, FR-020 | unhappy (invalid design) |
| FR-020 | `InMemoryContentSource` MUST construct from an `Iterable<ContentEntry>`, delegate to a `ContentCatalogue` (FR-046), and answer `lookup` and `listKind` per FR-008 to FR-014. | architecture.md §5 | happy |
| FR-021 | A `ContentCatalogue`, and therefore `InMemoryContentSource` and `FakeContentSource`, MUST reject entries with duplicate `ContentKey`s at construction with an `ArgumentError` whose `name` is `entries` and whose `invalidValue` equals the duplicate `ContentKey`. The message text is not specified or asserted. | testing.md §4 (duplicate entries); errors-and-results.md FR-027 | unhappy (invalid input) |
| FR-022 | `InMemoryContentSource` MUST behave correctly with no entries: every `lookup` is `ContentNotFound` and every `listKind` is empty. | testing.md §4 (empty and minimal) | unhappy (empty case) |
| FR-023 | `InMemoryContentSource` MUST iterate its input exactly once and copy it at construction; later mutation of the caller's collection MUST NOT change what the source returns, and a lazy or single-pass iterable MUST work. | testing.md §4 (immutability) | unhappy (immutability) |
| FR-024 | `InMemoryContentSource` MUST NOT throw `ContentSourceException` for any input and MUST complete its futures using microtasks only: no `Timer` is created. | architecture.md §5; testing.md §6 (fast) | happy |
| FR-025 | `ContentSource`, `ContentLookup`, `ContentFound`, `ContentNotFound`, `ContentCatalogue`, `ContentQuery` and its variants, and `ContentSourceException` MUST be exported from `lib/src/content/content.dart` and `lib/srd5e.dart` (the identity types are exported under content-schema-and-decoder.md FR-148). File placement is in section 5 ("Layer placement"). The bare names `Found` and `NotFound` MUST NOT be exported (shared-types-and-ownership.md FR-017). | architecture.md §2, §4, §7 | happy |
| FR-026 | `InMemoryContentSource` MUST be exported from `lib/adapters.dart` and MUST NOT be exported from `lib/srd5e.dart` or `lib/testing.dart`. It is a generic adapter, not a test double. | shared-types-and-ownership.md FR-037, FR-038; architecture.md §7 | happy |
| FR-027 | The repository MUST provide a shared contract suite in `test/contract/`, run against every `ContentSource` implementation that can be built from an arbitrary entry list (the in-memory source, the test double, and the test-only wrapping adapter), covering FR-008 to FR-014, FR-016, FR-017, FR-018, FR-022 and FR-041 (it has no duplicate-key group: FR-021 is unit-tested on `ContentCatalogue` and the constructors only). The FR-017 and FR-018 checks MUST run only when the caller supplies a failing-backend factory (FR-028), and MUST assert that the call does not throw synchronously, completes with `ContentSourceException` with `cause` set to the backend's exception, and is never `ContentNotFound` or an empty list. A source backed by a fixed fixture that cannot be built from arbitrary entries is covered by the read-only variant of FR-058; `BundledContentSource` is registered with both (FR-047). | architecture.md §7, §9 (bootstrap); testing.md §3, §10; shared-types-and-ownership.md FR-039 | happy |
| FR-028 | The contract suite MUST be the function `contentSourceContractChecks({required create, createFailing})` in `test/contract/content_source_contract.dart`. `create` takes a list of entries and returns a `ContentSource`. The optional `createFailing` takes a list of entries and a non-`Srd5eException` `Exception`, and returns a `ContentSource` whose backend throws that exception on every call. The suite returns a `List<ContentSourceCheck>` so it can be self-tested with deliberately bad adapters (FR-042); a failed check throws `ContentSourceContractViolation` carrying the check name. It is NOT exported from any `lib/` entry point (it would need `package:test` at runtime, which is forbidden); FR-050 covers how consumers reuse it. The read-only variant `contentSourceReadOnlyChecks` (FR-058) lives in the same file and follows the same rules. | shared-types-and-ownership.md FR-039; testing.md §3 | happy |
| FR-029 | `FakeContentSource` (in `lib/src/testing/`, exported by `lib/testing.dart`) MUST pass the contract suite when not scripted to fail. | architecture.md §7 (every port ships a double); shared-types-and-ownership.md FR-038 | happy |
| FR-030 | `FakeContentSource` MUST be scriptable to fail a given `ContentSourceException` from `lookup`, from `listKind`, or from both, and MUST deliver exactly the supplied instance through a failed `Future`, never a synchronous throw. | testing.md §4 (collaborator failure); errors-and-results.md FR-016 | unhappy (collaborator failure) |
| FR-031 | `FakeContentSource` MUST record every request, as a `ContentQuery` (`ContentLookupQuery(key)` or `ContentListKindQuery(kind)`, FR-057), in call order, as an unmodifiable list. | testing.md §6 | happy |
| FR-033 | Domain types in this spec (`ContentLookup`, `ContentFound`, `ContentNotFound`, `ContentCatalogue`, `ContentQuery` and its variants) MUST NOT import `dart:async`, use `Future`, import `application/`, `adapters/` or `shared_ports/`, or reference `Srd5eException` or any subtype (the identity types: content-schema-and-decoder.md FR-148). | architecture.md §3, §9; errors-and-results.md FR-029 | happy |
| FR-034 | No file under `lib/` may name a consuming project (mechanical scan). Test fixtures use clearly synthetic entries and no content from outside SRD 5.2.1; that rule is a review item with no test. | AGENTS.md, "Hard constraints" | happy |
| FR-037 | `ContentSourceException` MUST be `final` and `const`-constructible, and MUST expose the `cause` and `causeStackTrace` it was built with, unchanged (same instance). | errors-and-results.md FR-002 | happy |
| FR-038 | `ContentSourceException.errorType` MUST be the constant `content_source_exception` (the snake_case of the class name, per shared-types-and-ownership.md FR-041 and errors-and-results.md FR-005 and its section 7 registry), matching `^[a-z][a-z0-9_]*$` and unique among all `Srd5eException` subtypes. The `errorType` uniqueness sample test of errors-and-results.md FR-006 MUST include `ContentSourceException`. | shared-types-and-ownership.md FR-041; errors-and-results.md FR-005, FR-006 | happy |
| FR-039 | `ContentSourceException` MUST be built through one `const` constructor that takes the `ContentQuery` as a required positional argument (`ContentSourceException(ContentQuery query, {cause, causeStackTrace})`). Because the request is one sealed value, there is no combination of fields that can disagree. | architecture.md §3 (no null standing in for a named state), §10; shared-types-and-ownership.md principle 4 | unhappy (invalid design) |
| FR-041 | `InMemoryContentSource` MUST accept entries with the same `ContentId` under different `ContentKind`s. | content-schema-and-decoder.md FR-032 | unhappy (rule interaction) |
| FR-042 | The contract suite MUST fail an adapter that leaks a raw backend exception, and one that returns `ContentNotFound` or an empty list when its backend fails. | errors-and-results.md FR-032 | unhappy (collaborator failure) |
| FR-043 | A scenario test importing only `srd5e.dart`, `adapters.dart` and `testing.dart` MUST build an `InMemoryContentSource`, look up a present and an absent key, call `listKind`, and `switch` exhaustively over `ContentLookup` with no default. | testing.md §3 | happy |
| FR-044 | `lib/src/content/content.dart` MUST have a library doc comment listing the context's inputs and outputs, and every exported member of this spec MUST have a dartdoc comment. | architecture.md §4, §7 | happy |
| FR-046 | `ContentCatalogue` MUST be a pure, synchronous, immutable domain value object constructed from an `Iterable<ContentEntry>` that it iterates exactly once and copies. It MUST expose `lookup(ContentKey)` returning a `ContentLookup` (FR-008 to FR-010) and `ofKind(ContentKind)` returning an unmodifiable list ordered per FR-011 and empty per FR-012, and MUST reject duplicate keys per FR-021 and accept equal ids under different kinds per FR-041. `InMemoryContentSource` and `FakeContentSource` MUST delegate to it, so these rules are unit-tested once with plain values and no `Future`. | shared-types-and-ownership.md principle 1 (testable with plain values); architecture.md §3 | happy |
| FR-047 | Every `ContentSource` implementation the package ships MUST be registered in `test/contract/`. `InMemoryContentSource`, `FakeContentSource` and the test-only wrapping adapter run `contentSourceContractChecks`. `BundledContentSource` (FR-059) runs both: `contentSourceContractChecks` with `create: (entries) => BundledContentSource(texts: {'x': 'x'}, decoder: FakeContentSetDecoder({'x': ContentDecoded(ContentSet(entries))}))` and no `createFailing` (it has no backend to fail), and `contentSourceReadOnlyChecks` over the real embedded libraries, with the entries decoded from them as `expectedEntries`. Adding an implementation without registering it fails the architecture scan of `test/contract/`. | shared-types-and-ownership.md FR-031, FR-039, FR-047; architecture.md §9 (bootstrap) | happy |
| FR-049 | `FakeContentSource` MUST live in `lib/src/testing/` (file `lib/src/testing/fake_content_source.dart`, no subfolder), be exported only by `lib/testing.dart`, and import only `lib/src/content/content.dart` (the content barrel, which exports `ContentSource` and `ContentQuery`) and `shared_kernel`. It MUST NOT import `content/application/ports/`, any other `content` internal, or `content/adapters/` (architecture.md §1 and §9; architecture-guardrails.md FR-075). `FakeContentSource` MUST be constructed from an `Iterable<ContentEntry>` and is the in-memory content double that downstream use-case tests use. | shared-types-and-ownership.md FR-038; architecture.md §1, §9 | happy |
| FR-050 | Documentation (the README section on writing an adapter, and the dartdoc of `ContentSource`) MUST tell adapter authors how to reuse the contract suite: it lives in `test/contract/content_source_contract.dart` of this repository and is not exported. | shared-types-and-ownership.md FR-039 | happy |
| FR-051 | `ContentLookup` MUST be defined in `domain/`, not in `application/ports/`, because it is a pure value result that `ContentCatalogue` returns; `ContentSource.lookup` returns the same type. The catalogue thereby stays free of the port layer. | architecture.md §3, §4 | happy |
| FR-057 | `ContentQuery` MUST be a sealed value in `domain/` with exactly the variants `ContentLookupQuery(ContentKey key)` and `ContentListKindQuery(ContentKind kind)`, immutable and compared by value (same variant and same field). `ContentSourceException` (FR-018) and the recording of `FakeContentSource` (FR-031) both use it; no other type repeats the lookup-or-list modelling. | architecture.md §3 (sealed outcomes); shared-types-and-ownership.md principle 4 | happy |
| FR-058 | The repository MUST provide, in `test/contract/content_source_contract.dart`, the read-only suite `contentSourceReadOnlyChecks({required ContentSource source, required List<ContentEntry> expectedEntries})` returning a `List<ContentSourceCheck>`. It covers FR-008 to FR-014 and FR-016 against `source`, using `expectedEntries` as the fixture (ordering and kind filtering are computed from it; an absent key is generated so it is not in the fixture). It has no empty-source, same-id-under-two-kinds or failing-backend groups (FR-022, FR-041 and FR-017 need arbitrary entries or a backend), and it does not build sources. Failures throw `ContentSourceContractViolation`. | architecture.md §9 (bootstrap); testing.md §3, §10; shared-types-and-ownership.md FR-039 | happy |
| FR-059 | `BundledContentSource` MUST be defined under `lib/src/content/adapters/`, exported from `lib/adapters.dart` (and from no other entry point), and implement `ContentSource`. It reads the embedded document texts from the index of embedded documents (`embeddedDocuments`, content-schema-and-decoder.md FR-122), or from a `texts` constructor parameter that defaults to it. The constructor decodes each text with a `ContentSetDecoder` (constructor parameter, default the real `JsonContentSetDecoder`), collects the decoded `ContentSet`s, calls `validateContentSet(sets)` (content-schema-and-decoder.md FR-125 to FR-127), builds one `ContentCatalogue` from `ContentSetValid.contentSet`, and delegates `lookup` and `listKind` to an `InMemoryContentSource` over its entries. It adds no lookup logic of its own: its results equal an `InMemoryContentSource` over the same validated entries. | shared-types-and-ownership.md FR-030, FR-031, FR-047; content-schema-and-decoder.md FR-104, FR-122, FR-125, FR-127 | happy |
| FR-060 | `BundledContentSource` MUST decode every embedded document through the one decode path of shared-types-and-ownership.md FR-031: no second JSON reader, no file, network or `dart:io` access, no import from `tool/`, and `lib/srd5e.dart` MUST NOT export the embedded libraries or the index. The constructor is synchronous and runs the decode once; the futures of `lookup` and `listKind` follow FR-024. | shared-types-and-ownership.md FR-030, FR-031, FR-032; content-schema-and-decoder.md FR-104 | happy |
| FR-061 | If any embedded document fails to decode (`ContentDecodeFailed`) or the merged set fails whole-set validation (`ContentSetInvalid`), the `BundledContentSource` constructor MUST throw `BundledContentInvalid`, an `Error` subclass defined under `lib/src/content/adapters/` and exported from `lib/adapters.dart`. It carries two unmodifiable lists: `decodeProblems` (the decoder's `ContentProblem`s of every failed document, in the decoder's order, document by document in index order) and `referenceProblems` (the `ContentReferenceProblem`s of `ContentSetInvalid`, in its order); at least one is non-empty, and validation runs only when every document decoded. It MUST NOT return a partial source or throw `ContentSourceException`: a bad bundle is a packaging error, not an infrastructure failure. A duplicate `ContentKey` across documents is a `ContentReferenceProblem` of kind `duplicate`, not an `ArgumentError`. | architecture.md §6; errors-and-results.md FR-027; content-schema-and-decoder.md FR-104, FR-125, FR-127 | unhappy (invalid bundle) |
| FR-062 | Building `BundledContentSource` twice from the same texts MUST yield sources whose `lookup` and `listKind` results are equal entry for entry and in the same order (FR-014). With an empty index it MUST behave as an empty source (FR-022). | testing.md §4 (determinism, empty and minimal) | unhappy (determinism) |
| FR-063 | `BundledContentSource` MUST NOT depend on any bundled-data spec: it enumerates the index, so a data spec that adds an embedded library needs no change here. References between data are by id; every reference is checked by `validateContentSet` over the whole merged set inside this adapter (FR-059, FR-061; content-schema-and-decoder.md FR-125 to FR-127), and none is checked per document. | shared-types-and-ownership.md FR-047; content-schema-and-decoder.md FR-127 | happy |
| FR-064 | Each content data spec (`content-thin-slice`, `content-species-backgrounds-feats`, `content-equipment`, `content-spells`, `content-monsters`, `content-classes`, `content-magic-items`, the toolbox catalogues) MUST contribute only its embedded library and the entry in the index; none may define a second bundled source, loader or registration. Data pin tests of a data spec run through `BundledContentSource`. | shared-types-and-ownership.md FR-047, FR-048 | happy |

### Withdrawn ids

| Id | Withdrawn |
|---|---|
| FR-001 | Withdrawn: moved to content-schema-and-decoder.md (FR-142) |
| FR-002 | Withdrawn: moved to content-schema-and-decoder.md (FR-143) |
| FR-003 | Withdrawn: moved to content-schema-and-decoder.md (FR-143) |
| FR-004 | Withdrawn: moved to content-schema-and-decoder.md (FR-143) |
| FR-005 | Withdrawn: moved to content-schema-and-decoder.md (FR-143, FR-145) |
| FR-006 | Withdrawn: moved to content-schema-and-decoder.md (FR-145) |
| FR-032 | Withdrawn: moved to content-source-port.md (FR-014) |
| FR-035 | Withdrawn: moved to content-schema-and-decoder.md (FR-143) |
| FR-036 | Withdrawn: moved to content-schema-and-decoder.md (FR-144) |
| FR-040 | Withdrawn: moved to shared-types-and-ownership.md (FR-038) |
| FR-045 | Withdrawn: moved to content-schema-and-decoder.md (FR-146) |
| FR-048 | Withdrawn: moved to content-schema-and-decoder.md (FR-147); the `missing` getter of `ContentNotFound` is FR-016 here |
| FR-052 | Withdrawn: moved to content-schema-and-decoder.md (FR-114) |
| FR-053 | Withdrawn: moved to content-schema-and-decoder.md (FR-114) |
| FR-054 | Withdrawn: moved to content-schema-and-decoder.md (FR-114) |
| FR-055 | Withdrawn: moved to content-schema-and-decoder.md (FR-114) |
| FR-056 | Withdrawn: moved to content-schema-and-decoder.md (FR-114) |
| FR-065 | Withdrawn: moved to content-schema-and-decoder.md (FR-142) |

### Cases: `listKind` ordering (one test per row)

| Label | Entries (ids, insertion order) | Expected order | Source | Path |
|---|---|---|---|---|
| already sorted | `a`, `b`, `c` | `a`, `b`, `c` | FR-011 | happy |
| reverse insertion | `c`, `b`, `a` | `a`, `b`, `c` | FR-011 | happy |
| digit before underscore before letter | `ab`, `a_b`, `a1` | `a1`, `a_b`, `ab` | FR-011 | unhappy (boundary) |
| prefix first | `ab`, `a` | `a`, `ab` | FR-011 | unhappy (boundary) |
| other kind ignored | `a` (spell), `b` (feat), list feat | `b` | FR-010, FR-011 | unhappy (rule interaction) |
| single entry | `a` | `a` | FR-011 | unhappy (empty and minimal) |


## 5. Model

- **Value objects (immutable, by value):** `ContentCatalogue`, `ContentQuery` variants. The identity types
  (`ContentKind`, `ContentId`, `ContentKey`, `ContentEntry`, `MissingContent`) and typed ids are the schema
  spec's (section 3). No aggregate, no domain event.
- **Result (pure, `domain/`):** `sealed class ContentLookup` with `ContentFound(entry)` and
  `ContentNotFound(key)` plus a `missing` getter (FR-016, FR-051). `MissingContent` is a field of other
  contexts' results, never a shared variant.
- **One rules implementation:** `ContentCatalogue` holds duplicate-key, lookup and ordering rules;
  `InMemoryContentSource` and `FakeContentSource` add only the `Future` (and scripting and recording).
- **Layer placement** (under `lib/src/content/`, mirrored under `test/content/`, except the double):

  | Type | File location |
  |---|---|
  | `ContentLookup` (`ContentFound`, `ContentNotFound`), `ContentCatalogue`, `ContentQuery` (`ContentLookupQuery`, `ContentListKindQuery`) | `domain/` |
  | `ContentSource`, `ContentSourceException` | `application/ports/` |
  | `InMemoryContentSource`, `BundledContentSource`, `BundledContentInvalid` | `adapters/` |
  | `FakeContentSource` | `lib/src/testing/` (flat; exported only by `lib/testing.dart`) |
  | `ContentSourceCheck`, `contentSourceContractChecks`, `contentSourceReadOnlyChecks`, `ContentSourceContractViolation` | `test/contract/` (not in `lib/`) |

  `ContentSourceException` is not in `domain/` because the domain must not reference `Srd5eException` or
  `Future` (errors-and-results.md FR-029, architecture.md §9).
- **Invariants:** a `ContentFound` entry's `key`
  equals the requested key (enforced by `ContentCatalogue` and the contract suite). A `ContentCatalogue`
  holds no duplicate keys (`ArgumentError`, `name == 'entries'`, `invalidValue` the duplicate key).
- **Failures:** result, not exception: `ContentNotFound`. `Srd5eException` subtype: `ContentSourceException`.
  `ArgumentError`: duplicate keys.

## 6. Interface

```dart
/// Where the engine gets content from. Asynchronous because implementations
/// may do I/O.
abstract interface class ContentSource {
  /// Expected absence is [ContentNotFound]. Infrastructure failure completes
  /// the future with [ContentSourceException]; it never throws synchronously.
  Future<ContentLookup> lookup(ContentKey key);

  /// All entries of [kind], ordered by id; empty if there are none.
  Future<List<ContentEntry>> listKind(ContentKind kind);
}

// ContentKind, ContentId, ContentKey, ContentEntry, MissingContent: content-schema-and-decoder.md
// (FR-142 to FR-148), imported here, not defined.

// In domain/:
final class ContentCatalogue {
  ContentCatalogue(Iterable<ContentEntry> entries); // ArgumentError on duplicate key
  ContentLookup lookup(ContentKey key);
  List<ContentEntry> ofKind(ContentKind kind);       // unmodifiable, ordered by id
}

/// What was asked of a source. Sealed, so a switch is exhaustive.
sealed class ContentQuery {
  const ContentQuery();
}

final class ContentLookupQuery extends ContentQuery {
  const ContentLookupQuery(this.key);
  final ContentKey key;
}

final class ContentListKindQuery extends ContentQuery {
  const ContentListKindQuery(this.kind);
  final ContentKind kind;
}

// In adapters/:
final class BundledContentSource implements ContentSource {
  /// Decodes [texts] (default: the embedded index) with [decoder] (default:
  /// the real JSON decoder), then runs validateContentSet over the decoded
  /// sets. Throws [BundledContentInvalid] if any decode or the validation fails.
  BundledContentSource({Map<String, String>? texts, ContentSetDecoder? decoder});
}

final class BundledContentInvalid extends Error {
  /// Both lists are unmodifiable copies; at least one is non-empty.
  BundledContentInvalid({
    List<ContentProblem> decodeProblems = const [],
    List<ContentReferenceProblem> referenceProblems = const [],
  });
  final List<ContentProblem> decodeProblems;
  final List<ContentReferenceProblem> referenceProblems;
}

final class ContentSourceException extends Srd5eException {
  const ContentSourceException(
    this.query, {
    super.cause,
    super.causeStackTrace,
  });

  /// What was being asked when the backend failed. Never null.
  final ContentQuery query;

  @override
  String get errorType => 'content_source_exception';
}

// In test/contract/ (not exported):
final class ContentSourceCheck {
  const ContentSourceCheck(this.name, this.run);
  final String name;
  final Future<void> Function() run;
}

/// For sources built from arbitrary entries (in-memory, fake, wrapping adapter).
List<ContentSourceCheck> contentSourceContractChecks({
  required ContentSource Function(List<ContentEntry> entries) create,
  ContentSource Function(List<ContentEntry> entries, Exception backendFailure)?
      createFailing,
});

/// For sources backed by a fixed fixture (`BundledContentSource`): FR-008 to
/// FR-014 and FR-016 only; no empty, duplicate or failing-backend groups.
List<ContentSourceCheck> contentSourceReadOnlyChecks({
  required ContentSource source,
  required List<ContentEntry> expectedEntries,
});
```

- **Async, not `FutureOr`** (architecture.md §4): use cases await the port, then hand plain values to the
  domain. Failure is delivered through the returned `Future`, never a synchronous throw; adapters wrap with
  `wrapPortFailureAsync` (errors-and-results.md FR-016, FR-032).
- **Typed access:** a use case calls `source.lookup(spellId.key)` and pattern-matches the entry type
  (`ContentFound(entry: final Spell spell)`). `ContentLookup` is not generic and has no typed accessor. On
  `ContentNotFound` a use case returns its own `<UseCase>...ContentMissing` variant holding `spellId.missing`
  or `notFound.missing` (shared-types-and-ownership.md FR-017, FR-018; FR-048).
- **Exports:** `lib/src/content/content.dart` and `lib/srd5e.dart`: the FR-025 list (the identity types and
  typed ids ride the same barrel but are defined by the decoder spec). `lib/adapters.dart`: `InMemoryContentSource`,
  `BundledContentSource`, `BundledContentInvalid`. `lib/testing.dart`: `FakeContentSource` only (FR-026).
  Every exported member has dartdoc (FR-044).
- **Contract suite:** `test/contract/content_source_contract.dart`, not exported; two entry points
  (FR-027, FR-058); consumers reuse it as FR-050 describes.
- **In-memory double:** downstream specs use `FakeContentSource` from `lib/testing.dart`, built from
  synthetic entries (FR-049); production hosts use `InMemoryContentSource` from `lib/adapters.dart`.

## 7. Observability

`ContentSource`, the domain types, `InMemoryContentSource` and `FakeContentSource` are silent by design
(observability.md §3: domain silent; no retries, fallbacks or I/O timing here). A returned `ContentNotFound`
or thrown `ContentSourceException` is recorded by the calling use case (observability.md §5, §7) under its
own context prefix: `ContentNotFound` as `srd5e.outcome=failure` plus the use case's variant attribute (no
`error.type`), `ContentSourceException` in the error counter with `error.type=content_source_exception`
(FR-038; shared-types-and-ownership.md FR-041, FR-051; errors-and-results.md FR-043). This spec owns no
signal and reserves no names; the exception carries `query`, `cause` and `causeStackTrace` for diagnosis
(kind is low-cardinality; the id stays in the result or exception).

1. **What can go wrong?** Backend unavailable (`ContentSourceException`); absent key (`ContentNotFound`);
   malformed id or duplicate keys (`ArgumentError`, programmer error).
2. **How would an operator know?** The calling use case's span and counters (use-case specs).
3. **What is needed to diagnose it?** `query`, `cause`, `causeStackTrace`.
4. **What should be counted or timed?** Lookups and `listKind` sizes, by the calling use case (this layer
   cannot read a clock, observability.md §4).
5. **Is existing instrumentation still correct?** Nothing exists yet.
6. **What should a consumer monitor?** Any `content_source_exception`; a rising `ContentMissing` rate for ids
   believed to exist.
7. **Is anything now noisy?** No: nothing is emitted.

| Signal | Type | Attributes | Purpose | Suggested monitoring |
|---|---|---|---|---|
| none defined by this spec | n/a | n/a | n/a | Defined by calling use-case specs: alert on `error.type=content_source_exception`; watch `srd5e.outcome=failure` results that are a `ContentMissing` variant |

## 8. Test plan

| Id | Level | Notes |
|---|---|---|
| FR-007 | architecture | Port return types are `Future`, none `FutureOr`; compile-time assignment in `test/content/application/` |
| FR-008, FR-010, FR-012, FR-020, FR-022, FR-041 | contract | Contract suite; FR-022 empty-entries group; FR-041 same id under two kinds, both found |
| FR-009, FR-013 | contract | Contract suite; exact `ContentNotFound` and its key; `UnsupportedError` and unchanged next result |
| FR-011 | contract | Contract suite, ordering table above |
| FR-014 | contract | Run for `InMemoryContentSource` and `FakeContentSource`; element-wise `identical` or `==` |
| FR-015, FR-016 | unit | `test/content/domain/content_lookup_test.dart`: exhaustive `switch` with no default, value equality, accessors; `ContentNotFound.missing` equals the `MissingContent` of its key; two contract checks assert `ContentFound.entry.key` equals the request |
| FR-017, FR-018 | contract + unit | Failing-backend group via `createFailing`: `await expectLater(call(), throwsA(isA<ContentSourceException>()))`; no synchronous throw (call not `await`ed, assert it returns a `Future`); never `ContentNotFound` or empty; `query` variant and key or kind, and `cause`, for both operations. In this repo `createFailing` is a test-only adapter in `test/contract/` wrapping a throwing backend with `wrapPortFailureAsync`. Unit: fields, exhaustive `switch` over `query`, `isA<Srd5eException>()` in `test/content/application/ports/content_source_exception_test.dart` |
| FR-019 | architecture | Scan of `ContentSourceException`, `ContentLookup`, `ContentFound`, `ContentNotFound` for string fields named `message`, `description`, `text`, `displayText` (errors-and-results.md FR-007 scan, extended) |
| FR-021, FR-046 | unit | `test/content/domain/content_catalogue_test.dart`: `ArgumentError` with `name == 'entries'` and `invalidValue` the duplicate key (never the message); lookup present and absent, `ofKind` ordering table, empty, single-pass iterable, input mutation, unmodifiable list, same id under two kinds; no `Future`. `in_memory_content_source_test.dart` and `fake_content_source_test.dart` assert the duplicate rule through their constructors |
| FR-023, FR-024 | unit | Mutate the input after construction; generator-style iterable counting exactly one iteration; calls inside a `Zone` whose `createTimer` and `createPeriodicTimer` fail the test |
| FR-025, FR-026, FR-051 | architecture | Layer placement per section 5; barrel export check on `content.dart` and `lib/srd5e.dart`, fails on exported `Found` or `NotFound`; `InMemoryContentSource` in `adapters.dart`, absent from `srd5e.dart` and `testing.dart` |
| FR-027, FR-029, FR-047 | contract + architecture | `contentSourceContractChecks` against `InMemoryContentSource`, `FakeContentSource` (no failing group) and the test-only wrapping adapter (with failing group). `BundledContentSource` runs it through an injected `FakeContentSetDecoder` (no `createFailing`) and `contentSourceReadOnlyChecks` over the real embedded libraries. Architecture scan of `test/contract/` fails if a shipped `ContentSource` is not registered |
| FR-028 | unit + architecture | Both suites use the same factory signature; no file in `lib/` imports `package:test`; no `lib/` entry point exports the suite |
| FR-030, FR-031 | unit | `test/testing/fake_content_source_test.dart`: scripted failure per operation, same instance via `throwsA(same(e))`, no synchronous throw; recorded order, request variants, unmodifiable |
| FR-033 | architecture | Domain import, `Future` and `Srd5eException` ban in `test/architecture/` |
| FR-034 | architecture | Mechanical consumer-name scan over `lib/`; the SRD-only fixture rule is a review item with no test |
| FR-037, FR-038, FR-039 | unit | `identical` cause and stack trace, `const` instance; pins `content_source_exception` (snake_case of the class name, matches `^[a-z][a-z0-9_]*$`), added to the errors-and-results.md FR-006 uniqueness sample test; the single `const` constructor requires a `query` and stores it unchanged, each `ContentQuery` variant compiles |
| FR-042 | contract | Suite self-test in `test/contract/`: bad adapters that leak a raw exception, return `ContentNotFound`, or return an empty list on backend failure each make a failing-backend check throw `ContentSourceContractViolation` |
| FR-043 | scenario | `test/scenarios/content_source_scenario_test.dart`, imports the three public entry points only |
| FR-044 | architecture | Library doc comment on `content.dart`; dartdoc on every exported member |
| FR-049, FR-050 | architecture | Import check on `lib/src/testing/fake_content_source.dart` (only `content.dart` and `shared_kernel`) and export check (only `lib/testing.dart`); README and `ContentSource` dartdoc contain `test/contract/content_source_contract.dart` |
| FR-057 | unit | `test/content/domain/content_query_test.dart`: equality per variant, variants unequal to each other, exhaustive `switch` with no default |
| FR-058 | contract | Self-test in `test/contract/`: read-only suite passes a conforming fixed source; wrong order, entry of another kind or modifiable list throws `ContentSourceContractViolation`; no group builds sources; registered for `BundledContentSource` |
| FR-059, FR-060, FR-062, FR-063 | adapter | `test/content/adapters/bundled_content_source_test.dart`: injected `FakeContentSetDecoder` records exactly one call per text and passes the sets to `validateContentSet`; `lookup` and `listKind` run in a Zone that fails on `createTimer`/`createPeriodicTimer`; a document with a dangling reference decodes clean and is rejected only by whole-set validation; defaults serve the real index; results equal an `InMemoryContentSource` over the same entries; two builds give equal ordered results; empty index gives an empty source; exported by `adapters.dart` only |
| FR-060, FR-063 | architecture | No `dart:io` import in the class or embedded libraries; no `tool/` import from `lib/`; `srd5e.dart` does not export the libraries or index; one decode call site; no data spec's library imported directly |
| FR-061 | adapter | A corrupted text throws `BundledContentInvalid` with `decodeProblems` equal to the decoder's list and empty `referenceProblems`; two texts holding the same key give a `duplicate` problem in `referenceProblems` and empty `decodeProblems`, not an ArgumentError; a corrupted text plus a dangling reference in another text gives empty `referenceProblems`, and `decodeProblems` is ordered by index, document by document; an unresolved `wholeSet` reference an `unresolvedReference` problem; lists unmodifiable, no message text; no source returned |
| FR-064 | doc review | Each data spec's library appears in the index; no second bundled source (barrel scan) |

- **Doubles and suites:** `FakeContentSource`, `InMemoryContentSource` and the contract suites; fixtures use
  a synthetic `ContentEntry` defined in the tests, not real SRD content. Shared rules are tested once against
  `ContentCatalogue` with plain values.
- **Mutation testing:** `lib/src/content/domain` (`ContentCatalogue`, `ContentLookup`, `ContentQuery`) must
  score at least 80 with `mutate4dart` (the identity types are mutated under the schema spec); the adapter and
  double SHOULD be mutated too.
- **Telemetry tests:** none (nothing emitted); use-case specs assert the failure is recorded once.
- **Not covered:** only the SRD-only fixture rule in FR-034 (review item). Real-backend adapters are
  consumers' responsibility (FR-050).

## 9. Open questions and decisions

No question is open and none is escalated.

Settled (one line each):

- Q1 two methods over `ContentKey`; Q5 no streaming (`Future<List>`); Q6 `ContentNotFound`, not null
  (architecture.md §3); Q7 ordinal sort by id; Q9 `ContentSource` stays in `content/application/ports/`
  (`shared_ports` may depend only on `shared_kernel`); Q11 no reserved `srd5e.content.*` names (section 7); Q14 no generic accessor on `ContentLookup`. Q10 (`ContentId`
  is a final class, not an extension type) and Q13 (`MissingContent`) moved with the identity types to
  content-schema-and-decoder.md FR-143, FR-147.
- Q2 contract suites not exported: shared-types-and-ownership.md FR-039. Q3 id syntax and 64 units:
  FR-007 there and content-schema-and-decoder.md FR-143, aligned with its FR-030. Q4 version rejection is a decoder failure:
  FR-034 there. Q8 typed ids owned by the decoder spec: FR-046 there. Q12 `InMemoryContentSource` is an
  adapter only, `FakeContentSource` the double: FR-037, FR-038 there. Q15 `MagicItemId` maps to `magicItem`,
  `ItemId` to `equipment`: FR-005 and FR-046 there, id requested of content-schema-and-decoder.md FR-114
  (row R2-magic-items). Q16 errors-and-results.md OQ-6 already names `query`: FR-018, FR-039. Decoder Q3
  wording gone; decoder Q17 (rank conflict) settled by shared-types-and-ownership.md FR-064: the identity types
  moved to the decoder spec and this spec depends on it.

## 10. Changelog impact

Under `Unreleased`:

- **Added:** `ContentSource` port,
  sealed `ContentLookup` (`ContentFound`, `ContentNotFound`),
  `ContentCatalogue`, `ContentQuery` (`ContentLookupQuery`,
  `ContentListKindQuery`); `InMemoryContentSource` and `BundledContentSource`
  with `BundledContentInvalid` (`package:srd5e/adapters.dart`); `FakeContentSource`
  (`package:srd5e/testing.dart`). The contract suites are repository test
  utilities and are not part of the public API. The identity types (`ContentKey`, `ContentKind`, `ContentId`,
  `ContentEntry`, `MissingContent`) are recorded by content-schema-and-decoder.md.
- **Changed:** `ContentSourceException` is a new subtype of the
  `Srd5eException` hierarchy, with `errorType` `content_source_exception`.
  **BREAKING (accepted pre-0.1.0)**: consumers that switch over
  `Srd5eException` must handle it (errors-and-results.md OQ-5).

Everything else is an addition, since nothing earlier exists to change. After
first release, adding a `ContentKind` value or a `ContentLookup` variant is
**BREAKING** (consumers switch over them).
