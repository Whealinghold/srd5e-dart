# Content licensing and notice

| | |
|---|---|
| Status | implemented |
| Context | `content` |
| Roadmap phase | 0 |
| Depends on | `shared-types-and-ownership.md` |

Phase 0: no types; the content-conditional checks go live with the first data
file (§10). Build-order note, prose only: the checks run in the
`architecture-guardrails.md` harness (`SourceSet`, `Violation` format,
self-test rule, consumer-name scan); per shared-types-and-ownership.md FR-061
that rank-90 spec is cited in prose only. `release-0-1-0.md`,
`content-thin-slice.md` and `content-schema-and-decoder.md` cite this spec and
are not dependencies; the per-entry citation rule (content-schema-and-decoder.md
FR-090) is not a dependency either, because nothing here needs it implemented
first. Binding decisions: shared-types-and-ownership.md
FR-014, FR-030 to FR-033, FR-047, FR-050.

## 1. Purpose and scope

Defines how the package ships SRD 5.2.1 game content lawfully: the exact
contents of `NOTICE.md`, which paths it covers, how the MIT code and the
CC-BY-4.0 content stay distinct, how changes to the SRD material are indicated,
the trademark constraints, which paths may hold SRD content (shared-types-and-ownership.md
FR-030, FR-033), and how the attribution travels with the data. The first
change that bundles any game content MUST satisfy every requirement here.

A package-compliance spec: no runtime behaviour. The requirements are checked
by architecture-level checks, pure functions over the `SourceSet` of
`architecture-guardrails.md` (§8).

**Out of scope:**

- Schema, decoder, `schemaVersion`, embed generator and drift check
  (content-schema-and-decoder.md; shared-types-and-ownership.md FR-030 to
  FR-032, FR-034, FR-035); `BundledContentSource` (content-source-port.md;
  shared-types-and-ownership.md FR-047). This spec constrains only where files
  live and what notice they carry.
- Legal interpretation beyond `AGENTS.md` and the SRD's "Legal Information"
  page. The CC-BY-4.0 legalcode is not in the PDF; consulted and settled in §9.
- Wizards' logos, product names and any attribution wording other than the one
  statement.
- Other fifth-edition books, SRD 5.1, third-party or community material.
- A consumer's own redistribution compliance (the package only makes carrying
  the statement forward possible: FR-027 to FR-029).

## 2. Source

- `SRD 5.2.1, "Legal Information", p. 1`: the free-of-charge grant under
  CC-BY-4.0; the duty to include the statement "in any of your work"; no other
  attribution to Wizards or its parent or affiliates; the permission to state
  "compatible with fifth edition" or "5E compatible"; the pointer to Section 5
  of CC-BY-4.0. Page 1 says nothing about change indication, endorsement,
  logos, `.pubignore` or the archive; rows resting on those cite `AGENTS.md` or
  "package design (derived)".
- `SRD 5.2.1, "Contents", p. 2`: confirms the printed page of "Legal
  Information". The PDF page index equals the printed page.
- `AGENTS.md` ("Hard constraints", "Licensing and source material",
  "Trademarks and attribution", "The notice"), `doc/research/sources.md`,
  `doc/rules/architecture.md` §5, §7, §9.
- CC-BY-4.0 legalcode, Section 3(a) (not in the PDF; its URL is in the
  statement): claims resting on it are marked "(legalcode 3(a), see §9)".

The statement, exactly as printed on p. 1 (the PDF breaks the last URL after
the slash following `4.0`; it is one URL, no space). The quotes around
`SRD 5.2.1` are typographic (U+201C, U+201D):

> This work includes material from the System Reference Document 5.2.1 (“SRD
> 5.2.1”) by Wizards of the Coast LLC, available at
> https://www.dndbeyond.com/srd. The SRD 5.2.1 is licensed under the Creative
> Commons Attribution 4.0 International License, available at
> https://creativecommons.org/licenses/by/4.0/legalcode.

## 3. Vocabulary

| SRD term | Type | Notes |
|---|---|---|
| System Reference Document 5.2.1 | source document | The one permitted source (`AGENTS.md`). |
| Creative Commons Attribution 4.0 International License (CC-BY-4.0) | licence | Licenses the SRD content, not the code. |
| "compatible with fifth edition" / "5E compatible" | permitted wording | The only compatibility wording the SRD permits. |
| attribution statement | package term | The quoted paragraph in §2. |
| Wizards | package term | Wizards of the Coast LLC, the licensor. The bare name (`Wizards`, `Wizards of the Coast`) is not an entry of either denylist (FR-031), so explanatory sentences may name it; FR-004 reads only its parent and affiliate names as credits. |
| bundled game content | package term | Rules data derived from the SRD and shipped with the package. |
| source data directory | package term | `data/srd_5_2_1/`: the JSON source of truth (shared-types-and-ownership.md FR-030). |
| embed directory | package term | `lib/src/content/data/`: committed generated Dart libraries of raw JSON strings, one per content kind; `.dart` files plus `README.md` only. |
| fixture directory | package term | `test/fixtures/srd/`: the only place SRD text may appear in tests (shared-types-and-ownership.md FR-033). |
| covered paths | package term | `data/`, `lib/src/content/data/`, `test/fixtures/srd/`; exactly the paths `NOTICE.md` lists (FR-005). |
| bundled content present | package term | At least one file under a covered path other than `.gitkeep` and `README.md`. This is architecture-guardrails.md FR-079(a), unchanged: fixture files alone count. |
| status line | package term | A `NOTICE.md` line starting `**Status:**` and containing `no game content is bundled`. |
| non-endorsement sentence | package term | A sentence containing `not published, endorsed or approved by Wizards of the Coast` (keyword normalisation). It and the statement are exempt from the scans of FR-004, FR-013, FR-038. |

Terms from the SRD use its wording exactly (`doc/rules/architecture.md` §3).

### Mechanical definitions used by the checks

- **Normalisation (FR-002, FR-004 to FR-007, FR-012, FR-013, FR-015, FR-024,
  FR-027, FR-028, FR-035, FR-038):** (1) remove HTML comments and fenced code blocks (``` or
  `~~~` pairs): a comment is hidden and a fence shows code, not the attribution;
  (2) strip a leading `>` and following spaces per line; (3) replace each run of
  Unicode whitespace, including U+00A0, with one ASCII space and trim. Statement
  matching is case-sensitive; no other Markdown is stripped (emphasis or
  backticks inside the statement break the match); typographic quotes and
  dashes are not folded. Every check that matches or removes the statement
  (FR-002, FR-004, FR-024, FR-027, FR-028, FR-035, FR-038) applies steps (1),
  (2), (3), so a blockquoted statement is found and removed everywhere.
- **Keyword normalisation (FR-005, FR-006, FR-007, FR-012, FR-013, FR-015):** the
  text after steps (1) and (3), every `*` deleted, lower-cased. Exception: `MIT`
  (FR-006, FR-007) is matched before lower-casing, case-sensitively, as a whole word
  (`MIT-licensed` matches, `permit` does not).
- **Sentence split (FR-007):** after normalisation, split at `.`, `!`, `?`
  followed by a space or end of text, and at blank lines (taken before step (3)).
  `not` is matched as a whole word case-insensitively, as is the ending `n't`;
  `note`, `notice`, `cannot` do not count.
- **Section extraction (FR-004, FR-005, FR-012, FR-013, FR-035):** text from an exact,
  case-sensitive `## <Title>` heading to the next heading of the same or higher
  level, or end of file. Sections used: "Scope", "Attribution", "Changes".
- **Image extensions (FR-017):** `png`, `jpg`, `jpeg`, `gif`, `svg`, `webp`,
  `ico`, case-insensitive, on the final extension.

## 4. Requirements

Ids are stable and numeric (architecture-guardrails.md FR-071 reads only
`^FR-\d+$`). Earlier letter-suffixed ids map as: FR-003b is FR-035, FR-007b is
FR-036, FR-008b is FR-039 (withdrawn), FR-008c is FR-037 (location) plus FR-029
(header), FR-014b is FR-038; their Violations are `CLN-FR-035` to `CLN-FR-038`
(citing specs no longer cite lettered ids). Section 4 holds exactly one row per FR id;
the case tables label their first column `A-nn` or `S-nn`. Each check reports
`<path>:<line> CLN-<FR id> <detail>` (architecture-guardrails.md FR-004); the
`CLN-` prefix keeps Violations from colliding with guardrails ids.

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-001 | The repository root MUST contain `NOTICE.md` next to `LICENSE`. | `AGENTS.md`, "The notice" | happy |
| FR-002 | After normalisation (§3), `NOTICE.md` MUST contain the attribution statement from §2 verbatim: same words, punctuation and two URLs, with the typographic quotes around `SRD 5.2.1`. Line wrapping and whitespace runs are not significant; the PDF's wrap inside the last URL is not part of the URL. Unconditional: applies whether or not content is bundled. An altered, abridged, paraphrased, translated statement, or one naming another SRD version (for example 5.1), scheme (`http://`) or URL form (trailing slash), is not contained verbatim and is reported as `CLN-FR-002` (rows A-05 to A-12). | SRD 5.2.1, "Legal Information", p. 1 | happy |
| FR-004 | `NOTICE.md` (every section) and `README.md` MUST NOT credit, thank or name Wizards' parent or affiliates outside the verbatim statement and the non-endorsement sentence. Rule: remove both from the normalised text, then no entry of the affiliate denylist (FR-031) may occur. The scope is both whole files because `AGENTS.md` forbids any other attribution; `doc/`, `lib/` and the rest fall under architecture-guardrails.md FR-025/FR-026 and review. | SRD 5.2.1, "Legal Information", p. 1; `AGENTS.md`, "Trademarks and attribution"; architecture-guardrails.md FR-025, FR-068, FR-069 | unhappy (invalid input: extra attribution) |
| FR-005 | `NOTICE.md` MUST have a "Scope" section stating it covers only the bundled game content. Rule (keyword normalisation): the section exists and contains `only`, `game content` and `bundled`. Once bundled content is present (§3) the section MUST list each covered path as a backticked path ending in `/`, nothing else in the section in that form, and the listed paths MUST be exactly `data/`, `lib/src/content/data/` and `test/fixtures/srd/`. This spec defines the list and wording; the equality check is owned by architecture-guardrails.md FR-079(a) (`notice_paths`, shared-types-and-ownership.md FR-050), conditional on content being present, and is not moved here. `CLN-FR-005` covers only section existence and the three keywords. | `AGENTS.md`, "The notice"; shared-types-and-ownership.md FR-033; architecture-guardrails.md FR-079 | happy |
| FR-006 | `NOTICE.md` MUST state that the code is MIT-licensed and that `LICENSE` covers the code. Rule (keyword normalisation): the text contains the whole words `MIT` and `LICENSE`, case-sensitive, as link text, link target or backticked name. | `AGENTS.md`, "The notice" | happy |
| FR-007 | `NOTICE.md` MUST NOT state that the bundled game content is MIT-licensed. Rule, per sentence (§3 split, after normalisation): no sentence contains both the whole word `MIT` and one of `game content`, `SRD`, `rules data` unless it also contains the whole word `not` or the ending `n't` (heuristic; fuller reading by review). The licences must therefore be named in separate sentences: "The code is MIT-licensed; the game content is CC-BY-4.0." is one sentence and a Violation. | `AGENTS.md`, "Licensing and source material" | unhappy (rule interaction: licence confusion) |
| FR-008 | Bundled source data (JSON) MUST live only under `data/srd_5_2_1/` (or `test/fixtures/srd/` for test input). Rule, scoped to `lib/`: any `.json` file is a Violation (including under `lib/src/content/data/`), and so is any file in `lib/src/content/data/` that is not a `.dart` file other than the single `README.md` and `.gitkeep`. `tool/`, `doc/`, `example/` are not scanned. | `AGENTS.md`, "The notice"; shared-types-and-ownership.md FR-030, FR-033 | unhappy (state error: misplaced content) |
| FR-011 | While bundled content is present (§3, fixtures count), `NOTICE.md` MUST NOT contain the status line. While absent (nothing but `.gitkeep` and `README.md` under the covered paths) the status line is permitted, not required. | `AGENTS.md`, "The notice" | unhappy (empty and minimal case) |
| FR-012 | While bundled content is present, `NOTICE.md` MUST have a "Changes" section stating that the SRD's rules are restructured into code and data files. Rule (keyword normalisation): the section exists and contains `restructured`. | `AGENTS.md`, "Trademarks and attribution"; CC-BY-4.0 legalcode 3(a) (indicate modification; see §9) | happy |
| FR-013 | The "Changes" section MUST NOT describe the changes as endorsed, approved or reviewed by Wizards. Rule: after normalisation it contains none of `endorsed by`, `approved by`, `reviewed by`, `certified by`, `sanctioned by`, outside the non-endorsement sentence. | `AGENTS.md`, "Trademarks and attribution"; CC-BY-4.0 legalcode 3(a) (see §9) | unhappy (invalid input: implied endorsement) |
| FR-015 | `NOTICE.md` MUST contain the non-endorsement sentence, stating the package is independent and not published, endorsed or approved by Wizards of the Coast. Rule (keyword normalisation): one sentence contains `independent` and `not published, endorsed or approved by wizards of the coast`. | package design (derived from `AGENTS.md`, "Trademarks and attribution") | happy |
| FR-016 | Identifiers declared in `lib/` (class, mixin, enum, typedef, library and file names) and `pubspec.yaml` `name` and `description` MUST NOT contain a term of the trademark denylist (FR-031), compared after the FR-031 normalisation. | `AGENTS.md`, "Trademarks and attribution"; architecture-guardrails.md FR-025, FR-068, FR-069 | unhappy (invalid input: trademark as brand) |
| FR-017 | No image asset MUST be bundled: no file under `lib/` or `example/` has an image extension (§3). `svg` is checked from the `SourceSet` text map; binary images from the path-only `binaryPaths` list of architecture-guardrails.md FR-002. Whether an image is a Wizards logo cannot be tested; any image added later needs an explicit review decision. | `AGENTS.md`, "Trademarks and attribution" (no logos); package design (derived) | unhappy (missing content: forbidden asset) |
| FR-018 | `.pubignore`, evaluated with gitignore semantics (negations, anchoring, directory patterns, `*`, `**`), MUST NOT exclude `NOTICE.md` or `LICENSE`. | package design (derived: the notice accompanies redistribution); `AGENTS.md`, "The notice" | unhappy (state error: notice dropped on publish) |
| FR-019 | `.pubignore`, with gitignore semantics, MUST NOT exclude `lib/src/content/data/` (the embeds are the only covered path that ships). A pattern with a trailing slash and no other slash is unanchored and matches a directory of that name at any depth, so a bare `data/` excludes the embeds and is a Violation; the anchored `/data/` is clean, as is `data/` followed by `!lib/src/content/data/`. `data/` (via `/data/`) and `test/fixtures/srd/` are covered by `NOTICE.md` but MAY be excluded from the archive (release-0-1-0.md FR-061, Q14). | package design (derived: content must not ship without the notice); release-0-1-0.md FR-061, FR-062 | unhappy (state error: content shipped without notice context) |
| FR-023 | Bundled data MUST NOT contain content from SRD 5.1, other fifth-edition books, third-party material or recollection. Items that look like core fifth-edition material but are absent from the PDF MUST be omitted and listed in the change summary. Not mechanically decidable beyond content-schema-and-decoder.md FR-090; enforced by review. | `AGENTS.md`, "Licensing and source material" | unhappy (missing content: not in SRD; review only) |
| FR-024 | The SRD version in `NOTICE.md` and `doc/research/sources.md` MUST be equal: after normalisation steps (1) and (3), apply `(?:System Reference Document\|SRD)\s*[\|]?\s*(\d+\.\d+\.\d+)` to both files; the captured version sets MUST be equal and non-empty. The pattern also matches the `System Reference Document \| 5.2.1` table row in `sources.md`, so that file needs no edit. | `AGENTS.md`, "The notice" (a new SRD version is deliberate) | unhappy (state error: version drift) |
| FR-027 | Each of `data/srd_5_2_1/`, `lib/src/content/data/` and `test/fixtures/srd/` holding a file other than `.gitkeep` and `README.md` (any depth) MUST contain a `README.md`, independently of the other directories (a fixture README is required as soon as `test/fixtures/srd/` holds a file). Each such README MUST contain the attribution statement (after normalisation) or the exact sentence `Attribution: see NOTICE.md in the package root.` | SRD 5.2.1, "Legal Information", p. 1 ("in any of your work"); `AGENTS.md`, "Trademarks and attribution" | unhappy (state error: data without notice) |
| FR-028 | While bundled content is present (fixtures count), `README.md` MUST contain the attribution statement (after normalisation), because the pub.dev page renders the README, not `NOTICE.md`. | SRD 5.2.1, "Legal Information", p. 1 ("in any of your work"); package design (derived) | unhappy (state error: statement missing on package page) |
| FR-029 | Every `.dart` file in `lib/src/content/data/` MUST start with this header, verbatim, as its first two lines: `// GENERATED from data/srd_5_2_1/. Contains SRD 5.2.1 content.` and `// Attribution: see NOTICE.md in the package root.` The embed carries a pointer, not the full statement (decided, §9). Location is FR-037. The generator emits the header (content-schema-and-decoder.md FR-120). | SRD 5.2.1, "Legal Information", p. 1 ("in any of your work"); package design (derived) | unhappy (state error: embed without notice) |
| FR-030 | Reused SRD text in the data MUST stay faithful to the source: no paraphrase that changes a rule, no added rule text. Review only, with citation traceability from content-schema-and-decoder.md FR-090. | `AGENTS.md`, "Licensing and source material" ("keep it faithful") | unhappy (invalid input: altered rule text; review only) |
| FR-031 | Two denylists: the trademark list (trademarked edition, product and brand names) and the affiliate list (Wizards' parent and affiliate names). The bare licensor name is on neither. They MUST be held in test code, `test/architecture/support/constants.dart` (architecture-guardrails.md FR-069), with the normalisation of architecture-guardrails.md FR-025: case-insensitive, ignoring `-`, `_` and whitespace (term and input both lowercased with those removed). The names are never held in plain text: they are assembled from fragments at run time (architecture-guardrails.md FR-068), whose self-test already covers these lists (guardrails FR-068, §9; R-4 met); this spec adds no second self-test. The initial list is reviewed in the PR that adds it. | `AGENTS.md`, "Hard constraints"; architecture-guardrails.md FR-025, FR-068, FR-069 | unhappy (invalid input; reported as guardrails FR-068, no `CLN-FR-031`) |
| FR-033 | SRD text in tests lives only under `test/fixtures/srd/`; no test file outside it may embed SRD rules text in a data file or string literal. Not decidable beyond FR-008; review only. | shared-types-and-ownership.md FR-033 | unhappy (state error: SRD text outside covered paths; review only) |
| FR-035 | After normalisation (§3), the attribution statement MUST appear in `NOTICE.md` exactly once, inside its "Attribution" section. | SRD 5.2.1, "Legal Information", p. 1; package design (derived) | unhappy (boundary: duplicate) |
| FR-036 | `LICENSE` MUST NOT mention the bundled game content, the SRD or Creative Commons (it is the MIT text for the code only). | `AGENTS.md`, "Licensing and source material" | unhappy (rule interaction: licence confusion) |
| FR-037 | A `.dart` file under `lib/` whose first two lines are the FR-029 header MUST live in `lib/src/content/data/`. Only the first two lines count and only `lib/` is scanned, so the generator's string literal in `tool/` and a golden fixture under `test/` or `tool/` (content-schema-and-decoder.md FR-120) are not hits. Generation, commit and drift check are owned by shared-types-and-ownership.md FR-030, FR-032. | shared-types-and-ownership.md FR-030; `AGENTS.md`, "The notice" | unhappy (state error: misplaced embed) |
| FR-038 | Compatibility wording that names a trademarked edition, product or brand MUST NOT appear in `NOTICE.md`, `README.md`, `pubspec.yaml` or the package name. `NOTICE.md` and `README.md` MAY state "compatible with fifth edition" or "5E compatible" (a MAY, no check). Rule: after normalisation and removing the verbatim statement and the non-endorsement sentence from `NOTICE.md` and `README.md`, no trademark denylist (FR-031) entry occurs; `pubspec.yaml` and the package name are scanned in full. The exemptions matter because the mandatory statement names the licensor and FR-002 and FR-028 require that text; sentences that only name the licensor (such as "No other attribution to Wizards or its parent or affiliates is included." and "Wizards' trademarks are not used.") pass because the bare licensor name is on no list (FR-031). Today's `NOTICE.md` and `README.md` wording passes (fixture S-35). | `AGENTS.md`, "Trademarks and attribution"; SRD 5.2.1, "Legal Information", p. 1; architecture-guardrails.md FR-025, FR-068, FR-069 | unhappy (invalid input: trademark as brand) |

### Withdrawn ids

Ids stay so they are never reused.

| Id | Status |
|---|---|
| FR-003 | Withdrawn: moved to content-licensing-and-notice.md (FR-002) |
| FR-009 | Withdrawn: moved to content-licensing-and-notice.md (FR-005) |
| FR-010 | Withdrawn: moved to content-licensing-and-notice.md (FR-002) |
| FR-014 | Withdrawn: moved to content-licensing-and-notice.md (FR-038) |
| FR-020 | Withdrawn: moved to release-0-1-0.md (FR-049) |
| FR-021 | Withdrawn: moved to architecture-guardrails.md (FR-025) |
| FR-022 | Withdrawn: moved to content-schema-and-decoder.md (FR-090) |
| FR-025 | Withdrawn: moved to architecture-guardrails.md (FR-011) |
| FR-026 | Withdrawn: moved to architecture-guardrails.md (FR-011) |
| FR-032 | Withdrawn: moved to release-0-1-0.md (FR-048) |
| FR-034 | Withdrawn: moved to architecture-guardrails.md (FR-079) |
| FR-039 | Withdrawn: moved to shared-types-and-ownership.md (FR-030) |

### Owners of overlapping checks

| Rule | Owner | Relationship |
|---|---|---|
| `.pubignore` entries | release-0-1-0.md FR-061/062 | FR-018, FR-019 here only forbid excluding the notice, `LICENSE` and `lib/src/content/data/`; same gitignore-semantics evaluator. |
| Covered-path equality in the Scope section; `.pubignore` excludes `doc/research/` | architecture-guardrails.md FR-079 (shared-types-and-ownership.md FR-050) | This spec defines the list and the Scope wording (FR-005); FR-079 owns the equality check and the `doc/research/` exclusion (formerly FR-034; request R-3). |
| README licence section | release-0-1-0.md FR-049 | FR-028 adds the statement itself while content is present. |
| No link from `NOTICE.md` to an omitted file | release-0-1-0.md FR-048 (`NOTICE.md` co-owned) | One-way delegation; no link check here. |
| Embed generation, committed output, drift check, single decode path | shared-types-and-ownership.md FR-030 to FR-032; content-schema-and-decoder.md FR-104, FR-120 to FR-124 | Here only the header (FR-029) and location (FR-037). |
| `schemaVersion` and its revision table | content-schema-and-decoder.md (shared-types-and-ownership.md FR-034) | Nothing here. |
| `BundledContentSource` | content-source-port.md (shared-types-and-ownership.md FR-047) | Nothing here. |
| Consumer and organisation names | architecture-guardrails.md FR-025, FR-026 | No scan here. |
| Per-entry citations | content-schema-and-decoder.md FR-090 | No check here. |
| Determinism, purity, self-test pairs | architecture-guardrails.md FR-003, FR-005, FR-011 | No check here. |

`release-0-1-0.md` no longer restates the verbatim statement, status line or
change description: its notice requirement is a moved-id row pointing at
FR-002, FR-011 and FR-012 here.

Checklist coverage (`doc/rules/testing.md` §4): boundaries by the near-miss
rows (FR-002); empty and minimal by FR-011; rule interactions by FR-007; missing
content by FR-005, FR-017, FR-023; state errors by FR-018, FR-019, FR-024,
FR-027 to FR-029, FR-033, FR-037. Collaborator failure does not apply (no ports).

### Case table: attribution statement variants (FR-002, FR-035, FR-004)

Each row is a table-driven test of the verbatim check against a candidate
`NOTICE.md` text as an in-memory `SourceSet`. Expected Violation:
`NOTICE.md:<line> CLN-<id>`.

| Label | Case | Candidate text | Expected | Requirement | Path |
|---|---|---|---|---|---|
| A-01 | exact statement | The statement in §2 | accepted | FR-002 | happy |
| A-02 | re-wrapped across lines | Same words, different line breaks | accepted | FR-002 | happy |
| A-03 | blockquote-wrapped | Each line prefixed `> ` | accepted | FR-002 | happy |
| A-04 | NBSP between words | U+00A0 for a space | accepted | FR-002 | happy |
| A-05 | straight quotes | `"SRD 5.2.1"` instead of typographic | `CLN-FR-002` | FR-002 | unhappy (boundary: near-miss) |
| A-06 | word dropped | "Document" without `5.2.1` | `CLN-FR-002` | FR-002 | unhappy (boundary: near-miss) |
| A-07 | wrong version | `5.1` for `5.2.1` throughout | `CLN-FR-002` | FR-002 | unhappy (boundary: edition mix-up) |
| A-08 | `http` scheme | `http://www.dndbeyond.com/srd` | `CLN-FR-002` | FR-002 | unhappy (boundary: near-miss) |
| A-09 | wrong licence URL | `.../licenses/by/4.0/` without `legalcode` | `CLN-FR-002` | FR-002 | unhappy (boundary: near-miss) |
| A-10 | trailing-slash URL | `.../legalcode/` | `CLN-FR-002` | FR-002 | unhappy (boundary: near-miss) |
| A-11 | lowercase licensor | `wizards of the coast llc` | `CLN-FR-002` | FR-002 | unhappy (boundary: case) |
| A-12 | punctuation swapped | A full stop, comma or quote replaced | `CLN-FR-002` | FR-002 | unhappy (boundary: near-miss) |
| A-13 | inside an HTML comment | `<!-- statement -->` only | `CLN-FR-002` (hidden) | FR-002 | unhappy (invalid input: hidden) |
| A-14 | inside a code fence | Fenced block only | `CLN-FR-002` (shown as code) | FR-002 | unhappy (invalid input: hidden) |
| A-15 | statement missing | Scope and changes only | `CLN-FR-002` | FR-002 | unhappy (missing content) |
| A-16 | statement twice | Exact statement repeated | `CLN-FR-035` | FR-035 | unhappy (boundary: duplicate) |
| A-17 | extra attribution | Statement plus a credit to a parent or affiliate | `CLN-FR-004` | FR-004 | unhappy (invalid input) |
| A-18 | empty file | Zero bytes | `CLN-FR-002` | FR-002 | unhappy (empty and minimal case) |

### Case table: structural requirements

One violating and one clean fixture per requirement, each an in-memory
`SourceSet` (path-to-text map plus a path list for non-text files). A fixture
lists only the paths that matter; every other required path is present and
clean. Expected is `path : id`. "Content" means `data/srd_5_2_1/spells.json` and
its embed `lib/src/content/data/spells.dart` (with the FR-029 header) are
present. Withdrawn ids have no fixtures.

| Label | Requirement | Violating fixture | Expected Violation | Clean fixture | Path |
|---|---|---|---|---|---|
| S-01 | FR-001 | No `NOTICE.md` (and one with no `LICENSE`) | `NOTICE.md : CLN-FR-001` / `LICENSE : CLN-FR-001` | Both present | unhappy (missing content) |
| S-02 | FR-005 | No "Scope" section; or a Scope without `only`, `game content`, `bundled` | `NOTICE.md : CLN-FR-005` | Scope with "covers **only** the fifth-edition game content bundled with this package" (bold does not break the match) | unhappy (missing content) |
| S-03 | FR-005 | Content present; Scope lists only `data/` and `lib/src/content/data/`, or a fourth path | none from this spec; guardrails FR-079 (`notice_paths`) fixtures of the same shape yield it; vacuous with no content | as above | n/a (delegated to architecture-guardrails.md FR-079) |
| S-04 | FR-006 | No whole word `MIT` or no `LICENSE` | `NOTICE.md : CLN-FR-006` | Both present, including "the **MIT** License" | unhappy (missing content) |
| S-05 | FR-007 | "The game content is licensed under the MIT License." | `NOTICE.md : CLN-FR-007` | "The code is licensed under the MIT License." | unhappy (rule interaction) |
| S-06 | FR-007 | Wrapped: "The game content is licensed under\nthe MIT License." | `NOTICE.md : CLN-FR-007` | same words with "is not licensed" | unhappy (boundary: line wrap) |
| S-07 | FR-007 | "Note: the game content is licensed under the MIT License." (`Note` is not `not`) | `NOTICE.md : CLN-FR-007` | n/a | unhappy (boundary: substring `not`) |
| S-08 | FR-007 | "The code is MIT.\nThe SRD content is CC-BY-4.0." (adjacent lines, different sentences) | none | n/a | happy (boundary: wrap creates no match) |
| S-09 | FR-007 | "The code is MIT-licensed; the game content is CC-BY-4.0." | `NOTICE.md : CLN-FR-007` | "The code is MIT-licensed. The game content is CC-BY-4.0." | unhappy (boundary: semicolon) |
| S-10 | FR-036 | `LICENSE` mentions "Creative Commons" | `LICENSE : CLN-FR-036` | Plain MIT text | unhappy (rule interaction) |
| S-11 | FR-008 | Content plus `lib/src/other/spells.json`; `lib/src/content/data/spells.json`; `lib/src/content/data/notes.txt` | each path `: CLN-FR-008` | JSON only under `data/srd_5_2_1/`; embed-dir `README.md` and `.gitkeep` not flagged; `tool/x.json` not scanned | unhappy (state error) |
| S-12 | FR-037 | Headed file at `lib/src/content/x.dart` | `lib/src/content/x.dart : CLN-FR-037` | Headed file in `lib/src/content/data/`; headed `tool/x.dart` and `test/tool/golden.dart` not flagged | unhappy (state error) |
| S-13 | FR-011 | Content, notice has `**Status:** no game content is bundled yet` | `NOTICE.md : CLN-FR-011` | Status line removed | unhappy (state error) |
| S-14 | FR-011 | Only `.gitkeep` under `data/srd_5_2_1/` and `lib/src/content/data/`, status line present | no `CLN-FR-011` (FR-002 still applies, so the fixture holds the full notice) | n/a | happy (empty and minimal) |
| S-15 | FR-011 | Only `test/fixtures/srd/a.json`, status line present | `NOTICE.md : CLN-FR-011` (fixtures count) | Status line removed | unhappy (state error: fixture-only) |
| S-16 | FR-012 | Content, no "Changes" section; or one without `restructured` | `NOTICE.md : CLN-FR-012` | "...are **restructured** here into code and data files" | unhappy (missing content) |
| S-17 | FR-013 | Changes says "reviewed by Wizards", or "reviewed\nby Wizards" wrapped | `NOTICE.md : CLN-FR-013` | Plain restructuring text; the non-endorsement sentence elsewhere is not flagged | unhappy (invalid input) |
| S-18 | FR-038 | `README.md` with a denylisted brand in a compatibility claim | `README.md : CLN-FR-038` | Only "compatible with fifth edition", "5E compatible" | unhappy (invalid input) |
| S-19 | FR-038 | none (clean case) | none | `NOTICE.md` with the full statement and non-endorsement sentence, and a denylist that also holds the licensor name (stress case: the statement is removed first) | happy (rule interaction: mandatory text vs denylist) |
| S-20 | FR-015 | No non-endorsement sentence; or `independent` missing | `NOTICE.md : CLN-FR-015` | Sentence present (markup allowed) | unhappy (missing content) |
| S-21 | FR-016 | `pubspec.yaml` `name` with a denylisted term; a `lib/` class so named | `pubspec.yaml : CLN-FR-016`; `lib/…: CLN-FR-016` | Neutral names | unhappy (invalid input) |
| S-22 | FR-017 | `example/a.svg` in the text map | `example/a.svg : CLN-FR-017` | No image paths; `doc/x.svg` not flagged | unhappy (missing content) |
| S-23 | FR-017 | `binaryPaths` has `lib/src/logo.PNG`, `example/a.jpg`, `lib/a.gif`, `lib/a.webp`, `lib/a.ico` | each path `: CLN-FR-017` | No image paths; `doc/x.png` not flagged | unhappy (missing content) |
| S-24 | FR-018 | `.pubignore` lines `*.md`; `NOTICE.md`; `/LICENSE` (and `*.md` then `!NOTICE.md`, clean) | `.pubignore : CLN-FR-018` for the first three | Current `.pubignore`; the negation case | unhappy (state error) |
| S-25 | FR-019 | `.pubignore` lines `lib/src/content/`; `lib/src/content/data/`; `lib/`; bare `data/`; `**/data/` | `.pubignore : CLN-FR-019` each | Current `.pubignore`; anchored `/data/`; `data/` then `!lib/src/content/data/`; `test/fixtures/srd/` and `test/` alone (clean: release FR-061 excludes them) | unhappy (state error) |
| S-26 | FR-024 | `NOTICE.md` 5.2.1, `sources.md` 5.1.0 | `NOTICE.md : CLN-FR-024` | Both 5.2.1 | unhappy (state error) |
| S-27 | FR-024 | `sources.md` with no matching text | `doc/research/sources.md : CLN-FR-024` | n/a | unhappy (empty set) |
| S-28 | FR-024 | `sources.md` row `System Reference Document \| 5.2.1`; `NOTICE.md` statement wrapped between `Document` and `5.2.1` | none | n/a | happy (boundary: table row; re-wrap) |
| S-29 | FR-027 | `data/srd_5_2_1/spells.json` without a README; `lib/src/content/data/README.md` lacking statement and pointer; `test/fixtures/srd/x.json` without README and with no data or embed present | each README path `: CLN-FR-027` | READMEs with the pointer sentence | unhappy (state error) |
| S-30 | FR-028 | Content, `README.md` without the statement | `README.md : CLN-FR-028` | README with the statement | unhappy (state error) |
| S-31 | FR-029 | Embed whose first two lines differ (including the old `lib/src/content/data/` source path), or with no header | `lib/src/content/data/x.dart : CLN-FR-029` (once per file, not also `CLN-FR-037`) | Exact header | unhappy (state error) |
| S-32 | FR-004 | Credit to a parent or affiliate in `NOTICE.md` "Scope", or in `README.md` | `NOTICE.md : CLN-FR-004` / `README.md : CLN-FR-004` | Only the statement and non-endorsement sentence | unhappy (invalid input: credit outside Attribution) |
| S-33 | FR-031 | None of its own (guardrails FR-068's self-test). Matching is exercised in the FR-004, FR-038, FR-016 fixtures, including a term with `-`, `_` or spaces inserted and one in capitals | n/a | n/a | n/a (delegated to architecture-guardrails.md FR-068) |
| S-35 | FR-038, FR-004 | none (clean case) | none | Today's `NOTICE.md` ("No other attribution to Wizards or its parent or affiliates is included.") and `README.md` ("Wizards' trademarks are not used.") with the FR-031 lists | happy (rule interaction: licensor named in explanation) |
| S-36 | FR-002, FR-004, FR-028, FR-038 | none (clean case) | none | The statement blockquoted (`> ` per line) in both `NOTICE.md` and `README.md`, with a denylist that also holds the licensor name | happy (boundary: blockquote, step 2) |
| S-37 | FR-007, FR-013 | "Game content is licensed under the MIT License." at a sentence start; Changes says "**reviewed** by Wizards" | `NOTICE.md : CLN-FR-007` / `NOTICE.md : CLN-FR-013` | same text with "not" / plain restructuring text | unhappy (boundary: case and emphasis) |
| S-34 | FR-023, FR-030, FR-033 | Review only; no fixture | n/a | n/a | n/a (review) |

## 5. Model

No domain types: this spec defines repository artefacts, not code in `lib/src/`.

- **Artefacts:** `NOTICE.md` (attribution, scope, MIT/CC-BY distinction, changes,
  compatibility and non-endorsement), `LICENSE` (MIT, code only),
  `data/srd_5_2_1/` and `lib/src/content/data/` (each with a `README.md`; embeds
  carry the FR-029 header), `test/fixtures/srd/`, `.pubignore`, `README.md`
  (carries the statement while content is present).
- **Where each invariant is enforced:** FR-002, FR-004, FR-012, FR-035 by the
  notice check; FR-005 to FR-007, FR-011, FR-015, FR-027 to FR-029 by the same
  suite over the notice and covered paths; FR-016, FR-017, FR-036 to FR-038 by
  identifier and path scans; FR-018, FR-019 by `.pubignore` evaluation; FR-023,
  FR-030, FR-033 by review plus content-schema-and-decoder.md FR-090. All are
  pure functions over the `SourceSet`.
- **Failures:** a failing architecture test, never a runtime result or
  exception; nothing runs in a consumer's process.
- **Decision recorded:** `NOTICE.md` quotes the statement once, in an
  "Attribution" section, so the one-occurrence check (FR-035) is well-defined.

## 6. Interface

- No commands, results, use cases or ports; nothing is exported from the
  `content` barrel or `lib/srd5e.dart`.
- Files a consumer sees: `NOTICE.md` and `LICENSE` ship (FR-018); the README
  carries the statement (FR-028); covered directories and embeds carry the
  statement or a pointer (FR-027, FR-029).
- Checks live in `test/architecture/checks/` (for example `notice.dart` with
  `notice_test.dart` and `notice_self_test.dart`, following the self-test pattern of architecture-guardrails.md
  FR-005; the checks and their pair are owned here, not registered in the
  guardrails registry) as pure functions over a `SourceSet`; the harness reads
  the repository once and the checks do no I/O.

## 7. Observability

Signals: **silent by design.** No domain, application or adapter code exists
here: the spec constrains static documents and a directory layout, so there is
no runtime path to instrument. No signal is added, changed or removed, so
`doc/observability/signals.md` is unaffected. Content-loading signals belong to
`content-schema-and-decoder.md`.

1. **What can go wrong?** The notice is missing, altered or incomplete, or data
   is misplaced or not from SRD 5.2.1.
2. **How would an operator know?** Not at runtime; the architecture tests fail
   the build for the checked requirements before release. Review-only and
   delegated requirements are enforced in their owners or by review.
3. **What would someone need to diagnose it?** The violation line
   `<path>:<line> CLN-<FR id> <detail>` (architecture-guardrails.md FR-004).
4. **What should be counted or timed?** Nothing.
5. **Is existing instrumentation still correct?** Yes.
6. **What should a consumer monitor?** Nothing; consumers keep the shipped
   `NOTICE.md` intact when redistributing the content.
7. **Is anything now noisy?** No.

| Signal | Type | Attributes | Purpose | Suggested monitoring |
|---|---|---|---|---|
| none | n/a | n/a | silent by design (no runtime code) | n/a |

## 8. Test plan

All checks are architecture-level pure functions over the `SourceSet`
(architecture-guardrails.md FR-002, FR-003, FR-011: deterministic and read-only
by construction, no separate requirement here). Each has a self-test pair in
the pattern of architecture-guardrails.md FR-005: the violating and clean
fixtures of the two case tables, with the exact expected Violation (path and
`CLN-` id). A check without a violating fixture is a defect
(`doc/rules/testing.md` §8). Each test cites its FR id (`doc/rules/testing.md`
§5). The `CLN-` checks live in `test/architecture/checks/notice*.dart` with their
own self-test pair; they do not claim guardrails FR-005 registry slots
(architecture-guardrails.md §9 declined R-1). The `SourceSet`
already holds every tracked text file, so FR-001, FR-008, FR-011, FR-018,
FR-019, FR-027 to FR-029 and FR-036 can run as soon as the suite exists.

**Requests to other specs:** none open. R-1 (declined), R-2, R-3, R-4, R-5 and
R-8 are met or moot per architecture-guardrails.md §9; R-6 (the release spec's
notice requirement becomes a pointer here), R-7 (anchored `.pubignore` entries
so `data/` cannot drop the embeds, FR-019) and R-9 (guardrails FR-079 cites
FR-002 and FR-005) are met in those specs.

| Id | Level | Notes |
|---|---|---|
| FR-001, FR-006, FR-008, FR-036, FR-037 | architecture | S-01, S-04, S-11, S-10, S-12. |
| FR-002, FR-035 | architecture | Normalisation and containment; A-01 to A-15, A-18; duplicate row A-16; S-36. |
| FR-004 | architecture | Affiliate denylist scan of `NOTICE.md` and `README.md` outside the statement and non-endorsement sentence; A-17, S-32. |
| FR-005 | architecture | Scope existence and keywords (S-02). Path-list equality is tested under guardrails FR-079 (S-03), vacuous while no content is present. |
| FR-007 | architecture | Per-sentence rule plus review; S-05 to S-09, S-37. |
| FR-011, FR-012, FR-013 | architecture | S-13 to S-15 (including `.gitkeep`-only and fixture-only states), S-16, S-17, S-37. |
| FR-015, FR-016, FR-017 | architecture | S-20 to S-23; binary cases of FR-017 read `binaryPaths` (guardrails FR-002). |
| FR-018, FR-019 | architecture | Shared evaluator with release-0-1-0.md FR-061; S-24, S-25. |
| FR-024 | architecture | Regular expression on both files after steps (1) and (3); set equality; S-26 to S-28. |
| FR-027 to FR-029 | architecture | S-29 to S-31. |
| FR-031 | architecture | No check of its own; guardrails FR-068's self-test; matching rows in the FR-004, FR-038, FR-016 fixtures. |
| FR-038 | architecture | S-18, S-19, S-35, S-36. |
| FR-023, FR-030, FR-033 | architecture (none: review only) | Not decidable by script; citations of content-schema-and-decoder.md FR-090 plus review. |

- **Doubles and contract suites:** none; no port.
- **Mutation testing:** not applicable (no `domain/` code); the self-test pairs
  are the negative cases.
Deliberately not covered: FR-023 - bundled data must not contain content from outside SRD 5.2.1; not decidable by script, enforced by review (citation traceability via content-schema-and-decoder.md FR-090).
Deliberately not covered: FR-030 - reused SRD text stays faithful to the source; review only, with the same citation traceability.
Deliberately not covered: FR-033 - SRD text in tests lives only under `test/fixtures/srd/`; not decidable beyond FR-008, review only.
Deliberately not covered: FR-017 - only partially: whether an image is a Wizards logo cannot be tested; the extension scan is the mechanical stand-in. The embed drift check is shared-types-and-ownership.md FR-032's.

## 9. Open questions and decisions

No open questions. Settled, one line each:

- CC-BY-4.0 legalcode read (Section 3(a); the PDF omits it): it requires indicating that the material was modified (FR-012 does), a licence notice with its URI (the verbatim statement carries it, FR-002) and retention of the disclaimer notice, in "any reasonable manner" for the medium. FR-012 and FR-013 stand unchanged. Interpretation: the SRD's own statement (p. 1) is the complete attribution, and the disclaimer is reached through its licence URI.
- The `Changes` section stays a short statement, with no date or repository-history pointer: neither SRD p. 1 nor legalcode 3(a) requires one, and a date would go stale.

- `NOTICE.md` uses the PDF's typographic quotes; the check requires them (FR-002) and `NOTICE.md` is fixed in the same change (§10).
- Data location and form: shared-types-and-ownership.md FR-030, FR-033 (supersedes the earlier `data_embedded/` and "no embeds" positions).
- FR-007 is a heuristic sentence rule plus review.
- Denylist terms live in test code only, assembled from fragments (FR-031).
- Owners of overlapping checks: §4 table; the covered-paths equality check is architecture-guardrails.md FR-079 (shared-types-and-ownership.md FR-050).
- The embed carries a two-line pointer header, not the full statement (FR-029): the statement is for "the work a consumer sees" (README, `NOTICE.md`); revisit if the legalcode requires more per file.

## 10. Changelog impact

Expected `CHANGELOG.md` entry under `Unreleased`, **Added**: "Notice and
licensing checks: `NOTICE.md` carries the SRD 5.2.1 attribution statement, the
three covered directories, the change indication and the compatibility
statement; architecture tests enforce them." Not **BREAKING** (no exported API).
The `NOTICE.md` quote fix (FR-002) is a documentation fix. The `NOTICE.md` link
to `AGENTS.md` is rewritten as plain text by the change that lands
release-0-1-0.md FR-048, not by this spec.

**Activation.** The Phase 0 guardrails suite hosts these checks.

- Active as soon as the suite exists: FR-001, FR-002, FR-004 to FR-008, FR-013,
  FR-015 to FR-017, FR-024, FR-031, FR-035 to FR-038;
  FR-018 and FR-019 once the shared evaluator exists. FR-008 and FR-037 are
  structural; FR-029 applies to every `.dart` file in `lib/src/content/data/`
  from the first one.
- Fails today, so the fix ships with the check: FR-002 (straight quotes in
  `NOTICE.md`). FR-024 passes today because its pattern also matches the
  `System Reference Document | 5.2.1` row in `sources.md`.
- Passes today: FR-005, FR-006, FR-015, FR-038 (the current `NOTICE.md` and `README.md` only name the licensor in explanatory sentences, which no list holds; S-35). The path-list equality (guardrails
  FR-079(a)) is vacuous while no covered path holds a file besides `.gitkeep`
  and `README.md`. `NOTICE.md`'s Scope names only `lib/src/content/data/`
  today; it MUST list all three covered paths as backticked paths ending in `/`
  in the first change that adds any such file (a fixture counts).
- Content-conditional, live with the first file that is not `.gitkeep` or
  `README.md` under a covered path: FR-011, FR-012, FR-027 to FR-029. FR-027's
  per-directory clause fires on its own directory only.
