# Changelog

All notable changes to this package are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the package
follows [Semantic Versioning](https://semver.org/) (see
`doc/rules/architecture.md` §7).

## Unreleased

### Added

- Notice and licensing checks: `NOTICE.md` carries the SRD 5.2.1 attribution
  statement, the three covered directories, the change indication and the
  compatibility statement; architecture tests enforce them. `README.md`
  carries the statement and each covered directory's README the attribution
  pointer; the `CLN-` checks are pure functions over the architecture
  `SourceSet` with self-test pairs, not part of the runtime API.
- The `ContentSource` port (`lookup`/`listKind`, asynchronous), the sealed
  `ContentLookup` (`ContentFound`, `ContentNotFound` with its `missing`
  detail), the sealed `ContentQuery` (`ContentLookupQuery`,
  `ContentListKindQuery`), the pure `ContentCatalogue` index, and the
  `ContentSourceException` (`errorType` `content_source_exception`) thrown as
  a failed future for an infrastructure failure.
- `InMemoryContentSource` and `BundledContentSource` with
  `BundledContentInvalid` (`package:srd5e/adapters.dart`): the bundled source
  decodes the embedded SRD documents once, validates the merged set, and
  delegates to the in-memory source. `FakeContentSource`
  (`package:srd5e/testing.dart`) is the scriptable, recording double. The
  contract suites are repository test utilities and are not part of the
  public API.

- `Srd5eException` base class (port exceptions extend it), the
  `wrapPortFailure` and `wrapPortFailureAsync` adapter guards, and the
  documented rules for results versus exceptions versus `ArgumentError`.
- Dice value objects `Die`, `DiceExpression`, `DieRoll` and `RollResult`
  (single-term expressions such as `1d20` and `2d8 + 2`, with `minimum`,
  `maximum`, `average`, `doubleDice()`, `sumOfHighest` and `sumOfLowest`), the
  non-throwing `DiceExpression.tryParse` and the `tryCreate` factories with
  their sealed results and rejection enums.
- The `DiceRoller` port with `DiceRollerException` (`errorType`
  `dice_roller_exception`, reasons `unavailable` and `invalidResult`) and the
  `rollChecked` extension.
- `SeededDiceRoller` in `package:srd5e/adapters.dart`, and the test doubles
  `FixedDiceRoller` and `CallbackDiceRoller` in `package:srd5e/testing.dart`.
- `Modifier` (a signed whole number added to the d20 number, with `Modifier.zero`,
  `+`, `Modifier.sum` and `applyTo`, exact and unclamped), the sealed
  `RollCircumstance` (`Advantage`, `Disadvantage`) and `RollMode` (`normal`,
  `advantage`, `disadvantage`) with `RollMode.resolve` (Advantage and
  Disadvantage do not stack and cancel as a whole), `diceCount` and `select`
  (the higher or lower of two d20s), exported from `package:srd5e/srd5e.dart`.
- `Ability` (the six abilities), `AbilityScore` (a whole number from 1 to 30,
  with `minimum`, `maximum`, the `modifier` read from the SRD's Ability
  Modifiers table, and the non-throwing `AbilityScore.tryCreate` returning the
  sealed `AbilityScoreResult` of `ValidAbilityScore` or `InvalidAbilityScore`
  with an `AbilityScoreRejection`), `AbilityModifier` (-5 to +10, independent of
  `Modifier`; convert with `Modifier(abilityModifier.value)`) and
  `AbilityScores` (one score per ability: `fromMap`, `scoreOf`, `modifierOf`,
  `withScore`), exported from `package:srd5e/srd5e.dart`.
- D20 Tests (`d20_test` context, domain model): `D20Roll` with reroll and
  replace-a-die operations, `RollModifiers`, `DifficultyClass`, `ArmorClass`,
  `D20TestOutcome`, `AttackRollResult` with `isCriticalHit`, forced failures,
  the pure `D20TestResolver` service, and the natural 20 and natural 1 attack
  rules, using the shared kernel's `Modifier` and `RollMode`.
- The `ResolveD20Test` use case for ability checks, saving throws and attack
  rolls, returning the sealed `ResolveD20TestResult`
  (`ResolveD20TestRolledCheck`, `ResolveD20TestRolledAttack`,
  `ResolveD20TestForcedFailure`), with Advantage and Disadvantage, natural 20
  and natural 1 on attack rolls, saves chosen or forced to fail, and Critical
  Hit as a natural 20 (`AttackRollResult.isCriticalHit`).
- Telemetry signals `srd5e.d20_test.resolve` (span), `srd5e.d20_test.resolved`,
  `srd5e.d20_test.duration`, `srd5e.d20_test.modifiers`,
  `srd5e.d20_test.natural` and `srd5e.d20_test.errors`, with attribute keys
  `srd5e.d20_test.kind`, `srd5e.ability`, `srd5e.d20_test.roll_mode`,
  `srd5e.outcome`, `srd5e.d20_test.critical_hit`,
  `srd5e.d20_test.roller_failure`, `srd5e.d20_test.forced_failure_reason` and
  `error.type`, and the exported `D20TestSignals` constants.
- The `srd5e.d20_test.natural` histogram of the d20 face each rolled call used
  (1 to 20), so an unfair or stuck injected roller is visible on every face,
  not only through the critical-hit share.
- The `srd5e.d20_test.roller_failure` attribute (`unavailable`,
  `invalid_result`) on `srd5e.d20_test.errors` and the error span, separating
  an unavailable dice source (page ops) from an adapter contract breach (file
  a bug).
- The `srd5e.d20_test.forced_failure_reason` attribute (`chosen_to_fail`,
  `automatic`) on `srd5e.d20_test.resolve` and `srd5e.d20_test.resolved` for a
  forced failure, separating gameplay choices from caller-declared automatic
  failures.
- The `content` context's domain types: the content identity types
  (`ContentKind`, `ContentId` with its non-throwing `tryCreate`, `ContentKey`,
  `ContentEntry`, `MissingContent`), the nine typed ids (`SpeciesId`,
  `BackgroundId`, `ClassId`, `SubclassId`, `FeatId`, `SpellId`, `ItemId`,
  `MonsterId`, `FeatureId`) with `TypedId`, `ContentKeyedId` and
  `TypedIdParse`, the closed SRD vocabulary types (`Skill` with `ability`,
  `DamageType`, `CreatureType`, `CreatureSize` with `space` over the
  `CreatureSpace` family, `ConditionKind`, `Language` with `isStandard`,
  `RechargeTrigger`, `WeaponProperty`, `MasteryProperty`, `FeatCategory`,
  `HitPointDie` with `faces`, `LightLevel`, `DarknessKind`, `Obscurement`,
  `SpecialSense`, `Alignment`, `DurationUnit`,
  `ContentProblemKind`), the building blocks (`SourceCitation` with its SRD
  constants and `citationText`, `NamedText`, the sealed `Prerequisite` and
  `ToolProficiency` families) and the neutral `ContentTextBlock` family with
  its five variants and factories, plus the whole-set reference interfaces
  (`ContentReferences`, `ContentReference`, `ReferenceConstraint`,
  `HasFeatCategory`), exported from `package:srd5e/srd5e.dart`.
  `DarknessKind.nonmagical` and `Obscurement.none` are package names (the
  SRD says "normal" darkness and "not obscured").
- The species, background and feat entry types of the `content` context:
  `Species` (creature type, one or two player-character sizes, speed,
  verbatim traits, optional `sizeText`, and `choices` whose spell ids are
  whole-set reference sites) with `SpeciesChoice` and the sealed
  `ChoiceOption` family (`DamageTypeOption`, `LineageOption` over
  `LevelBenefit`, `TextOption`); `Background` (three abilities, the Origin
  feat as a `BackgroundFeatReference`, two skills, a tool proficiency, the
  `EquipmentOptions` of `EquipmentOption` and `EquipmentItem`); `Feat` (one
  category, optional prerequisites, `FeatBenefit`s, and the
  `repeatable`/`repeatableText` pair); and the custom-background step-5
  check, the pure `customBackgroundEquipmentProblems` with
  `EquipmentItemValue` and the sealed `CustomBackgroundEquipmentProblem`
  family (`EquipmentValueNotFiftyGold`, `EquipmentItemUnpriced`,
  `EquipmentItemExcluded`), SRD 5.2.1 "Creating a Background", p. 193.
  Constructors reject every invalid case with `ArgumentError` and expose
  their limits as public constants and predicates (SRD 5.2.1, "Character
  Species" pp. 83-86, "Character Backgrounds" p. 83, "Parts of a Feat"
  p. 87). Exported from `package:srd5e/srd5e.dart`.
- The class entry types of the `content` context (SRD 5.2.1, "Classes",
  pp. 28-82): `ClassDefinition` as the content entry of kind
  `ContentKind.characterClass` with its Features-table `ProgressionRow`s
  (rows over the sealed `RowFeature` family — `RowClassFeature` with its
  printed annotation and the `RowSubclassFeature` marker — and the sealed
  `SpellcastingRow` family, `SlotSpellcastingRow` with nine slot columns and
  `PactSpellcastingRow`), the declared `ClassColumn`s (`ClassColumnId`,
  `ClassColumnKind`) whose cells are the sealed `ColumnValue` family
  (`ColumnCount`, `ColumnDice`, `ColumnBonus`, `ColumnFeetBonus`,
  `ColumnNone` for the printed em dash), and the `FeatureEntry`s — id,
  printed name, level and verbatim text — carrying the sealed `FeatureFact`
  family (`GrantsSubclass`, `GrantsFeat`, `AlwaysPreparedSpells` over
  `SpellGrant`), `FeatureOption`s (`FeatureOptionId`, `OptionPrerequisite`)
  and `FeatureTable`s over the sealed `TableCell` family. The pure accessors
  `subclassLevel`, `rowAt`, `entriesGainedAt`, `rowFeatures` (`ResolvedRow`),
  `featGrantsAt`, `column`, `entry` (the sealed `FeatureEntryLookup` result)
  and `subclass` (the sealed `SubclassLookup` result) read the Features
  table without a decoder; `SubclassDefinition` carries the nested
  subclasses with `featuresAtOrBelow`. The core-trait value objects:
  `AbilityRequirement` (sealed `AllOf`/`AnyOf` with `isMetBy`),
  `SkillChoice` (`SkillChoiceListed`, `SkillChoiceAny`),
  `WeaponProficiency` over `WeaponTrainingCategory`,
  `ArmorTrainingCategory`, the sealed `ClassToolProficiency` family
  (`ClassToolProficiencySpecific`, `ClassToolProficiencyChoice`), the
  `ClassStartingEquipment` of `ClassEquipmentOption`s and
  `ClassEquipmentItem`s, `MulticlassGrants` (whose subset rule against the
  core traits — weapon proficiencies with their property filters,
  armor training, listed skills and tool choices — the `ClassDefinition`
  constructor enforces through `WeaponProficiency.covers`) and the sealed
  `ClassSpellcastingTrait` family (`SlotSpellcastingTrait`,
  `PactSpellcastingTrait`). `deriveFeatureId` derives a feature id from its
  owner and printed name (the two apostrophes deleted, `_level_<n>` only
  for a repeated name) and `FeatureOptionId` and `ClassColumnId` are id
  types over the same rule. Constructors reject every invalid case with
  `ArgumentError` (name and invalidValue set) and expose their limits as
  public constants and predicates for the decoder to reuse. Exported from
  `package:srd5e/srd5e.dart`.

- The spell entry types of the `content` context (SRD 5.2.1, "Spells",
  pp. 104-107): `Spell` as the content entry of kind `ContentKind.spell`,
  with `SpellLevel` (0 is a cantrip; the non-throwing `SpellLevel.tryCreate`
  returns the sealed `SpellLevelParse`), `SpellSchool` (the eight schools),
  the sealed `CastingTime` family (`magicAction`, `bonusAction` with its
  optional trigger, `reaction` with its required trigger, `minutes`,
  `hours`) under the sealed `SpellCastingTimes` (`SpellCastingTimesSingle`,
  `SpellCastingTimesModes` over `CastingTimeMode`, at least two labelled
  options), the sealed `SpellRange` family (`self`, `touch`, `distance`
  over `DistanceUnit`, `sight`, `unlimited`, `special`),
  `SpellComponents` with `MaterialComponent` (verbatim description, the
  "N+ GP" figures and the consumption flag), the sealed `SpellDuration`
  family (`instantaneous`, `timed` over `DurationLimit`,
  `untilDispelled`, `untilDispelledOrTriggered`, `special`), the verbatim
  description blocks, the optional `higherLevel` and `cantripUpgrade`
  texts, the derived `requiresConcentration`, and the optional structured
  `effects`. `classSpellList` derives a `ClassSpellList` (the ids of one
  class's spells, level 0 to 9, ordinal order) from `Spell.classes`.
- The spell effect data model of `Spell.effects` (SRD 5.2.1, "Effects",
  p. 106): the sealed `SpellEffectModel` (`TextOnlyEffects`, the default,
  and `ModelledEffects` over `EffectCoverage`), `SpellTargeting` (`self`,
  chosen with `TargetSubject`, `TargetCount` and `SelfTargetPolicy`, and
  in-area over the six `AreaShape` shapes with `includesOrigin`, and
  `CreatureTypeRestriction`), ordered `SpellEffectPart`s over the sealed
  `PartResolution` (attack roll, saving throw with `SuccessEffect`,
  automatic) and `SpellOutcome` (damage with `DamageTypeSelection`,
  healing, Temporary Hit Points, condition with `ConditionDuration`)
  families, `ScalableAmount` over `SpellAmount` scaled by the sealed
  `AmountScaling` and `CountScaling` families and `CharacterLevelTable`,
  the derived `SpellEffectFacts` (`EffectFact`: `FactKnown` or
  `FactUnknown`, never guessing for a partial spell) and the optional
  `ZoneFacts` of a lingering zone (`ZoneRuleFact`, `ZoneTrigger`,
  `ZoneMobility`, `ZoneMovementFacts`).
- The equipment shapes of the `content` context (SRD 5.2.1, "Equipment",
  pp. 89-92): `Coin` (CP, SP, EP, GP, PP with their Copper values),
  `Cost` with `valueInCopper` and the static `compareByValue` (5 SP is not
  50 CP; different rates cannot be compared) and `CostRate`, the sealed
  `Price` (`FixedCost`, `CostVaries`) and `WeightSpec` (`Weight` with its
  printed note, `WeightVaries`, `NoWeight`), `EquipmentCategory` (the
  twelve table families), `ArmorCategory` with its typed don and doff
  times over the sealed `DonDoffTime`, the sealed `ArmorClassRule`
  (`BaseRule` over the sealed `DexterityBonus` family and `BonusRule` for
  the Shield), and the `Weapon` entry (category, type, `WeaponDamage`,
  the sealed `WeaponPropertyUse` family with `RangePair`,
  `AmmunitionType` and `TwoHandedCondition`, one `MasteryProperty`,
  weight, price) and `Armor` entry (category, rule, optional Strength
  requirement, Stealth flag, weight, price). Constructors reject every
  invalid case with `ArgumentError` (name and invalidValue set) and
  expose their limits as public constants and predicates. Exported from
  `package:srd5e/srd5e.dart`.
- The content JSON envelope and its decode path (SRD-derived format;
  `schemaVersion` 1): the `ContentSetDecoder` port, the whole-set types
  `ContentSet` (ordered, unmodifiable, duplicate-key `ArgumentError`) and
  `validateContentSet` over the sealed `ContentSetValidation`
  (`ContentSetValid`, `ContentSetInvalid`) with `ContentReferenceProblem`,
  the sealed `ContentDecodeResult` (`ContentDecoded`,
  `ContentDecodeFailed`) carrying every `ContentProblem` (a JSON Pointer
  path and a `ContentProblemKind`, never display text) in one
  deterministic order, and the exported `supportedSchemaVersions`.
  Exported from `package:srd5e/srd5e.dart`.
- `JsonContentSetDecoder` in `package:srd5e/adapters.dart`: the decoder
  for the envelope, reporting every problem found in one pass (strict,
  never lenient; unknown keys rejected at any depth; SRD enum spellings
  case sensitive; whole numbers beyond the safe-integer range rejected on
  every platform), with the shapes for species, backgrounds, feats,
  weapons and armor, duplicate-id detection over the whole document, and
  no reference resolution (cross-entry references are
  `validateContentSet`'s).
- The `classes` and `spells` decoder shapes of `JsonContentSetDecoder`
  (revision rows R1-classes, R1-classes-ids, R1-classes-spell-sites and
  R1-spells landed; R1-species-backgrounds-feats' shapes decode since PR 5
  and its row is marked landed): a class entry decodes with its core
  traits, nested subclasses, declared columns, twenty progression rows with
  their column values, feature entries with their facts, options and
  tables, and document-wide uniqueness of class, subclass and feature ids
  (reported after the class-id duplicates); a spell entry decodes with the
  sealed casting-time, range and duration families, class lists as plain id
  strings (no reference sites), and `ContentTextBlock` description lists.
  Spell ids inside `AlwaysPreparedSpells` facts are the whole-set reference
  sites of R1-classes-spell-sites, reported by `validateContentSet`.
- `FakeContentSetDecoder` in `package:srd5e/testing.dart`: a scriptable,
  recording test double of the `ContentSetDecoder` port.
- The `LoadContentSet` use case: it runs a `ContentSetDecoder` over one
  document's text and returns the sealed `LoadContentSetResult`
  (`LoadContentSetLoaded` carrying the decoded set,
  `LoadContentSetRejected` carrying every problem), with the
  `ContentSetDecoder` and an optional `Observability` taken through the
  constructor. Exported from `package:srd5e/srd5e.dart`.
- The six `srd5e.content.*` telemetry signals of `LoadContentSet`
  (`srd5e.content.load` span, `srd5e.content.decode` child span,
  `srd5e.content.loads` counter, `srd5e.content.decode_errors` counter by
  `srd5e.content.problem_kind`, `srd5e.content.entries_loaded` counter by
  `srd5e.content.kind`, `srd5e.content.load_duration` histogram), with the
  exported `ContentSignals` constants and the catalogue rows in
  `doc/observability/signals.md`. A rejected load sets error status on both
  spans and counts no `error.type`; a thrown `Srd5eException` counts one
  `failure` load with `error.type`; nothing is logged (the documented
  FR-080 deviation: the single failure variant carries no variant
  attribute).
- A bundled SRD 5.2.1 content thin slice, served by `BundledContentSource`
  from `package:srd5e/adapters.dart`: species Dragonborn, Dwarf, Elf and
  Human; the Wizard class; and twelve spells including the six Elf lineage
  spells (SRD 5.2.1, "Character Species" pp. 84-86, "Wizard" pp. 77-78,
  "Spell Descriptions" pp. 121-154), in three JSON documents under
  `data/srd_5_2_1/` and their generated embedded libraries. The slice is
  self-consistent: every lineage spell id resolves in the merged set, so
  `validateContentSet` passes and lookups of unbundled ids answer
  `ContentNotFound`. `NOTICE.md` covers `data/`, `lib/src/content/data/` and
  `test/fixtures/srd/`.
- The embedded-data generator in `tool/` (not published): the pure
  `generateEmbeddedLibraries` core (one Dart library per data file under
  `lib/src/content/data/`, each a `const String` holding the file text
  character for character, plus the `embedded_documents.dart` index,
  byte-stable in ordinal order with the two-line attribution header) with
  its thin file-reading `main`, and the drift check
  (architecture-guardrails.md FR-078) wired to the real generator over
  `data/srd_5_2_1/*.json`.
