/// A pure-Dart, framework-agnostic implementation of the fifth-edition rules
/// in System Reference Document 5.2.1.
///
/// This is the package's main public entry point. Generic adapters and test
/// doubles will have their own entry points (`adapters.dart`,
/// `testing.dart`). Everything under `lib/src/` is private; export
/// deliberately from here.
///
/// ## Errors and results
///
/// srd5e separates three kinds of "it did not go to plan":
///
/// * An expected outcome, an absence or a rejection (a failed check, a
///   content id that is not found, host-supplied input that fails validation)
///   is returned as a variant of a sealed result type, never thrown. Switch
///   over it exhaustively, with no default branch.
/// * A failure of something outside the package (a dice roller or content
///   source that fails, or breaks its documented contract) is thrown as a
///   concrete subtype of [Srd5eException]. Catch it with
///   `on Srd5eException catch (e)` and read `e.errorType`, `e.cause` and
///   `e.causeStackTrace`. A `switch` over [Srd5eException] needs a default
///   branch, because the root is not sealed.
/// * A programmer error (an invalid constructor argument, a broken invariant)
///   is an [ArgumentError], [StateError] or another [Error]. It is a bug in the
///   caller and is not meant to be caught.
///
/// Adapters that implement a port wrap the exceptions of their backend with
/// [wrapPortFailure] (synchronous ports) or [wrapPortFailureAsync]
/// (asynchronous ports), so a backend [Exception] surfaces as the port's typed
/// subtype with the original kept as `cause`.
///
/// ## D20 rolls
///
/// [Modifier] is a signed whole number added to the number rolled on the d20,
/// and modifiers add together. [RollMode.resolve] turns any number of
/// [Advantage] and [Disadvantage] circumstances into a [RollMode] (they do not
/// stack, and at least one of each cancels to normal); `RollMode.diceCount`
/// says how many d20s to roll and `RollMode.select` picks the one that is used.
///
/// ## D20 Tests
///
/// The `d20_test` domain model. [D20Roll] holds the d20s of one roll under a
/// [RollMode] — its `natural` is the die the mode keeps and its `keptIndex`
/// says which one — and `replaceDie` and `applyReroll` return new rolls; a
/// reroll is a [RerollDecision], the sealed [KeepRoll] or [RerollDie].
/// [RollModifiers] holds the one ability modifier, the optional Proficiency
/// Bonus and any number of other modifiers; its `total` is their kernel sum.
/// [DifficultyClass] and [ArmorClass] are the two target numbers
/// (`DifficultyClass.veryEasy` ... `nearlyImpossible` are the Typical
/// Difficulty Classes). [D20TestKind] names the three kinds of D20 Test,
/// [D20TestOutcome] their outcome and [ForcedFailureReason] why a check or
/// save fails without a roll.
///
/// The resolved outcome of a test is a value: [CheckResult] or
/// [AttackRollResult] carries the roll, the modifiers, the total, the target
/// and the outcome (the attack result also `isCriticalHit` and
/// `criticalRange`, and `hit`), and [ForcedFailureResult] marks a failure
/// without a roll. Resolve them with the static members
/// `CheckResult.resolve`, `AttackRollResult.resolve` and
/// `ForcedFailureResult.of` — or with the pure const [D20TestResolver]
/// service the static members delegate to, which accepts a rerolled or
/// replaced roll and re-resolves after an adjustment with `adjustedBy`. A
/// natural 20 hits and is a Critical Hit and a natural 1 misses regardless
/// of modifiers or the AC ("Rolling 20 or 1", SRD 5.2.1, p. 7); attack rolls
/// only.
///
/// ## Content
///
/// The `content` context's identity types: [ContentKind] names one value per
/// SRD content category (species through contagion, in declaration order), a
/// [ContentId] is a validated entry id and a [ContentKey] is a kind and id
/// pair. The nine typed ids (`SpeciesId`, `BackgroundId`, `ClassId`,
/// `SubclassId`, `FeatId`, `SpellId`, `ItemId`, `MonsterId`, `FeatureId`)
/// wrap a [ContentId] and reject anything its constructor rejects; all but
/// `SubclassId` and `FeatureId` are [ContentKeyedId]s whose `key` and
/// `missing` name the entry they address. [MissingContent] is the absence
/// detail another context's result carries when content it needs is not
/// there, and [ContentEntry] is the interface every content entry
/// implements.
///
/// The closed SRD vocabulary types — [Skill], [DamageType], [CreatureType],
/// [CreatureSize], [ConditionKind], [Language], [RechargeTrigger],
/// [WeaponProperty], [MasteryProperty], [FeatCategory], [HitPointDie],
/// [LightLevel], [DarknessKind], [Obscurement], [SpecialSense],
/// [Alignment] and [DurationUnit] — each expose a `jsonValue` spelling (the
/// SRD's own), a static `fromJson` returning null for a non-member, and
/// their static facts: `Skill.ability`, `Language.isStandard`,
/// `HitPointDie.faces` and `CreatureSize.space` over the [CreatureSpace]
/// family (`SharedSquareSpace` for Tiny, `WholeSquareSpace` for the rest).
///
/// The printed-text building blocks: [SourceCitation] (a document, section
/// and page, with `tryCreate`, `citationText` and the SRD constants),
/// [NamedText], the sealed [Prerequisite]
/// (`LevelPrerequisite`, `AbilityScorePrerequisite`, `FeaturePrerequisite`)
/// and [ToolProficiency] (`SpecificToolProficiency`,
/// `ChoiceToolProficiency`) families, the neutral [ContentTextBlock] family
/// (paragraph, entry, bullet list, table and embedded stat block, also
/// created through the `ContentTextBlock.*` factories), and the
/// whole-set reference interfaces [ContentReferences] and [ContentReference]
/// with the [ReferenceConstraint] family (`TargetHasFeatCategory`) and
/// [HasFeatCategory].
///
/// The species, background and feat entry types: [Species] (creature type,
/// one or two player-character sizes, speed, verbatim traits and the
/// [SpeciesChoice]s over the sealed [ChoiceOption] family —
/// [DamageTypeOption], [LineageOption] with its [LevelBenefit]s, and
/// [TextOption] — whose spell ids are whole-set reference sites),
/// [Background] (three abilities, the Origin feat as a
/// [BackgroundFeatReference], two skills, a tool proficiency and the
/// [EquipmentOptions] of [EquipmentOption]s and [EquipmentItem]s), and
/// [Feat] (one [FeatCategory], optional prerequisites, benefits as
/// [FeatBenefit]s, and the `repeatable`/`repeatableText` pair). The
/// custom-background step-5 check is the pure
/// [customBackgroundEquipmentProblems] with the sealed
/// [CustomBackgroundEquipmentProblem] family
/// (`EquipmentValueNotFiftyGold`, `EquipmentItemUnpriced`,
/// `EquipmentItemExcluded`) and [EquipmentItemValue].
///
/// The class entry types: [ClassDefinition] — the content entry of kind
/// `ContentKind.characterClass` — with its Features-table [ProgressionRow]s
/// (rows over the sealed [RowFeature] family — [RowClassFeature],
/// [RowSubclassFeature] — and the sealed [SpellcastingRow] family,
/// [SlotSpellcastingRow] and [PactSpellcastingRow]), its declared
/// [ClassColumn]s ([ClassColumnId], [ClassColumnKind]) whose cells are the
/// sealed [ColumnValue] family ([ColumnCount], [ColumnDice], [ColumnBonus],
/// [ColumnFeetBonus], [ColumnNone]), and its [FeatureEntry]s — id, printed
/// name, level and verbatim text with the sealed [FeatureFact] family
/// ([GrantsSubclass], [GrantsFeat], [AlwaysPreparedSpells] over
/// [SpellGrant]), [FeatureOption]s ([FeatureOptionId],
/// [OptionPrerequisite]) and [FeatureTable]s over the sealed [TableCell]
/// family. The pure accessors `rowAt`, `entriesGainedAt`, `rowFeatures`
/// ([ResolvedRow]), `featGrantsAt`, `column`, `entry` (the
/// [FeatureEntryLookup] result) and `subclass` (the [SubclassLookup]
/// result) read the table without a decoder; `subclassLevel` is the level
/// of the [GrantsSubclass] entry. [SubclassDefinition] carries the nested
/// subclasses with `featuresAtOrBelow`. The core-trait value objects:
/// [AbilityRequirement] (sealed [AllOf] / [AnyOf] with `isMetBy`),
/// [SkillChoice] ([SkillChoiceListed], [SkillChoiceAny]),
/// [WeaponProficiency] over [WeaponTrainingCategory],
/// [ArmorTrainingCategory], the [ClassToolProficiency] family
/// ([ClassToolProficiencySpecific], [ClassToolProficiencyChoice]), the
/// [ClassStartingEquipment] of [ClassEquipmentOption]s and
/// [ClassEquipmentItem]s, [MulticlassGrants] and the
/// [ClassSpellcastingTrait] family ([SlotSpellcastingTrait],
/// [PactSpellcastingTrait]). `deriveFeatureId` derives a feature id from
/// its owner and printed name.
///
/// The spell entry types: [Spell] — the content entry of kind
/// `ContentKind.spell` — with its [SpellLevel] (0 is a cantrip, with the
/// non-throwing `SpellLevel.tryCreate`), [SpellSchool], the sealed
/// [CastingTime] family under the sealed [SpellCastingTimes]
/// ([SpellCastingTimesSingle], [SpellCastingTimesModes] over
/// [CastingTimeMode]), the sealed [SpellRange] family over [DistanceUnit],
/// [SpellComponents] with [MaterialComponent], the sealed [SpellDuration]
/// family with [DurationLimit], the verbatim description blocks and the
/// derived `requiresConcentration`. `classSpellList` derives a
/// [ClassSpellList] (the ids of one class's spells, level 0 to 9) from
/// `Spell.classes`. `Spell.effects` holds the optional structured effect
/// model ([SpellEffectModel], defaulting to `const TextOnlyEffects()`): a
/// [ModelledEffects] carries an [EffectCoverage], [SpellTargeting] over the
/// area shapes ([AreaShape]: `ConeArea`, `CubeArea`, `CylinderArea`,
/// `EmanationArea`, `LineArea`, `SphereArea`) and target counts, ordered
/// [SpellEffectPart]s over the sealed [PartResolution] and [SpellOutcome]
/// families, [ScalableAmount]s scaled by the sealed [AmountScaling] and
/// [CountScaling] families over [CharacterLevelTable], the derived
/// [SpellEffectFacts] (`EffectFact`: `FactKnown` or `FactUnknown`) and
/// optional [ZoneFacts] for a lingering zone. The equipment shapes: [Coin]
/// (CP, SP, EP, GP, PP with their Copper values), [Cost] with
/// `compareByValue` and [CostRate], the sealed [Price] ([FixedCost],
/// [CostVaries]) and [WeightSpec] ([Weight], [WeightVaries], [NoWeight]),
/// [EquipmentCategory], [ArmorCategory] with its typed don and doff times
/// over [DonDoffTime], the sealed [ArmorClassRule] ([BaseRule] over the
/// [DexterityBonus] family, [BonusRule]), and the [Weapon] and [Armor]
/// entries over [WeaponDamage] and the sealed [WeaponPropertyUse] family.
///
/// ## Decoding content
///
/// The content JSON envelope: a [ContentSetDecoder] turns one document's
/// text into a [ContentDecodeResult] — a [ContentDecoded] carrying the
/// decoded [ContentSet], or a [ContentDecodeFailed] carrying every
/// [ContentProblem] (a JSON Pointer path and a [ContentProblemKind], never
/// display text) in a deterministic order — for the versions
/// [supportedSchemaVersions] supports. The bundled
/// `JsonContentSetDecoder` is in `package:srd5e/adapters.dart`; the
/// scriptable `FakeContentSetDecoder` is in `package:srd5e/testing.dart`.
/// [validateContentSet] resolves every cross-entry reference over the
/// merged sets and returns the [ContentSetValidation]: a [ContentSetValid]
/// carrying the merged set, or a [ContentSetInvalid] carrying the
/// [ContentReferenceProblem]s. It is the only place a reference between
/// entries is checked — a single-document decode resolves none.
///
/// [LoadContentSet] loads one document for you: give it a [ContentSetDecoder]
/// and an optional [Observability], then call it with a
/// [LoadContentSetCommand] holding the document text. It returns a
/// [LoadContentSetResult] — a [LoadContentSetLoaded] carrying the decoded
/// [ContentSet], or a [LoadContentSetRejected] carrying every problem — and
/// emits the signals named by [ContentSignals], catalogued in
/// `doc/observability/signals.md`. Run [validateContentSet] on the loaded
/// set beside it: loading resolves no reference between entries.
///
/// ## Asking for content
///
/// [ContentSource] is the port the rules use to read content: `lookup(key)`
/// answers a [ContentLookup] — a [ContentFound] carrying the entry, or a
/// [ContentNotFound] carrying the requested [ContentKey] and, through its
/// `missing` getter, the [MissingContent] your own result variant holds.
/// `listKind(kind)` answers every entry of one kind, ordered by id. Absence
/// is a result, never a throw; an infrastructure failure completes the
/// future with a [ContentSourceException] carrying the [ContentQuery] asked
/// ([ContentLookupQuery] or [ContentListKindQuery]), the cause and its stack
/// trace, and the `error.type` `content_source_exception`. The pure
/// [ContentCatalogue] holds the shared lookup and ordering rules. The
/// generic sources live in `package:srd5e/adapters.dart`
/// (`InMemoryContentSource`, `BundledContentSource`) and the double in
/// `package:srd5e/testing.dart` (`FakeContentSource`).
///
/// ## Resolving a D20 Test
///
/// [ResolveD20Test] resolves one D20 Test for you: give it a [DiceRoller] and
/// an optional [Observability], then call it with a [D20TestCommand] — an
/// [AbilityCheckCommand] or [SavingThrowCommand] with a `DifficultyClass`, or
/// an [AttackRollCommand] with an `ArmorClass` — whose attempt is a
/// [RollAttempt] (the `RollModifiers` and the Advantage and Disadvantage
/// circumstances), a [ChooseToFail] (saving throws only) or an
/// [AutomaticFailure]. It makes one dice request sized by the resolved mode
/// and returns a [ResolveD20TestResult]: a `ResolveD20TestRolledCheck`, a
/// `ResolveD20TestRolledAttack` or a `ResolveD20TestForcedFailure`, carrying
/// the command's ability label, the domain result and the typed target. It
/// emits the signals named by [D20TestSignals] and catalogued in
/// `doc/observability/signals.md`.
///
/// ## Abilities
///
/// [Ability] names the six abilities. An [AbilityScore] is a whole number from
/// 1 to 30 (`AbilityScore.minimum` and `AbilityScore.maximum`); its `modifier`
/// is the [AbilityModifier] from the SRD's Ability Modifiers table. [AbilityScores]
/// holds one score for each ability (`scoreOf`, `modifierOf`, `withScore`).
/// The constructor of [AbilityScore] throws [ArgumentError] for a number
/// outside the range; `AbilityScore.tryCreate` takes untrusted input and
/// returns an [AbilityScoreResult], either [ValidAbilityScore] or
/// [InvalidAbilityScore] with an [AbilityScoreRejection]. An [AbilityModifier]
/// is not a [Modifier]; convert with `Modifier(abilityModifier.value)`.
///
/// ## Observability
///
/// srd5e emits logs, traces and metrics through three small ports that you
/// implement: [Logger], [Tracer] and [Meter], bundled as [Observability]. A
/// use case takes `Observability observability = Observability.none`, so
/// omitting it gives silent `const` no-ops ([NoopLogger], [NoopTracer],
/// [NoopMeter], [NoopObservability]) and identical behaviour. Supply only the
/// ports you have: `Observability(logger: myLogger)` leaves the other two as
/// no-ops.
///
/// * [Logger.log] takes a [LogLevel], a constant message and attributes as a
///   closure that is called only when the level is enabled; [LoggerLevels]
///   adds `fine`, `warning` and the other shortcuts.
/// * [Tracer.trace] and `traceAsync` run a unit of work inside a named [Span]
///   (attributes, a [SpanStatus], recorded errors). An error thrown by the
///   work is recorded on the span and rethrown unchanged.
/// * [Meter] creates a [Counter], [Histogram] or [Gauge] and times work into a
///   duration histogram with `time` and `timeAsync`, in seconds. srd5e never
///   reads the clock; your adapter does.
/// * [Attributes] are plain `String`, `bool`, `int` or `double` values.
///   [AttributeKeys.outcome] and [AttributeKeys.errorType] are the keys shared
///   by every signal; `doc/observability/signals.md` lists the signals.
///
/// Production implementations must not throw of their own accord, and srd5e
/// does not catch what they throw. Bridges to OpenTelemetry, `package:logging`
/// or Sentry are not shipped; the README shows how to write one. Recording
/// doubles for tests are in `package:srd5e/testing.dart`.
library;

export 'src/content/content.dart'
    show
        AbilityRequirement,
        AbilityScorePrerequisite,
        Alignment,
        AllOf,
        AlwaysPreparedSpells,
        AmmunitionType,
        AmmunitionUse,
        AnyCreatureType,
        Armor,
        ArmorCategory,
        ArmorClassRule,
        ArmorTrainingCategory,
        AreaShape,
        AttackRollResolution,
        AutomaticResolution,
        Background,
        BackgroundFeatReference,
        BackgroundId,
        BaseRule,
        BonusRule,
        ByCharacterLevelAmount,
        ByCharacterLevelCount,
        CappedDexterity,
        CastingTime,
        CastingTimeBonusAction,
        CastingTimeHours,
        CastingTimeMagicAction,
        CastingTimeMinutes,
        CastingTimeMode,
        CastingTimeReaction,
        CharacterLevelTable,
        ChosenDamageType,
        ChoiceOption,
        ChoiceToolProficiency,
        ClassColumn,
        ClassColumnId,
        ClassColumnKind,
        ClassDefinition,
        ClassEquipmentItem,
        ClassEquipmentOption,
        ClassId,
        ClassSpellList,
        ClassSpellcastingTrait,
        ClassStartingEquipment,
        ClassToolProficiency,
        ClassToolProficiencyChoice,
        ClassToolProficiencySpecific,
        ColumnBonus,
        ColumnCount,
        ColumnDice,
        ColumnFeetBonus,
        ColumnNone,
        ColumnValue,
        ConeArea,
        ConditionDuration,
        ConditionKind,
        ContentDecodeFailed,
        ContentDecodeResult,
        ContentDecoded,
        ContentCatalogue,
        ContentEntry,
        ContentFound,
        ContentId,
        ContentIdParse,
        ContentIdParsed,
        ContentIdProblem,
        ContentIdRejected,
        ContentKey,
        ContentKeyedId,
        ContentKind,
        ContentListKindQuery,
        ContentLookup,
        ContentLookupQuery,
        ContentNotFound,
        ContentQuery,
        ContentProblemKind,
        ContentProblem,
        ContentReference,
        ContentReferences,
        ContentReferenceProblem,
        ContentSet,
        ContentSetDecoder,
        ContentSetInvalid,
        ContentSetValid,
        ContentSetValidation,
        ContentSource,
        ContentSourceException,
        ContentSignals,
        ContentTextBlock,
        ContentTextBulletList,
        ContentTextEmbeddedStatBlock,
        ContentTextEntry,
        ContentTextParagraph,
        ContentTextTable,
        Cost,
        CostRate,
        CostVaries,
        CountScaling,
        CreatureSize,
        CreatureSpace,
        CreatureType,
        CreatureTypeRestriction,
        CubeArea,
        CustomBackgroundEquipmentProblem,
        customBackgroundEquipmentProblems,
        CylinderArea,
        DamageType,
        DamageTypeOption,
        DamageTypeSelection,
        DarknessKind,
        deriveFeatureId,
        DesignationPolicy,
        DistanceUnit,
        DonDoffByUtilize,
        DonDoffMinutes,
        DonDoffTime,
        DriftDirectionRule,
        DriftsAtTurnStart,
        DurationLimit,
        DurationUnit,
        EffectCoverage,
        EffectFact,
        EquipmentCategory,
        EquipmentItem,
        EquipmentItemExcluded,
        EquipmentItemUnpriced,
        EquipmentItemValue,
        EquipmentOption,
        EquipmentOptions,
        EquipmentValuation,
        EquipmentValueNotFiftyGold,
        ExactlyTargets,
        FactKnown,
        FactUnknown,
        Feat,
        FeatBenefit,
        FeatCategory,
        FeatId,
        FeatureEntry,
        FeatureEntryFound,
        FeatureEntryLookup,
        FeatureEntryNotFound,
        FeatureFact,
        FeatureId,
        FeatureOption,
        FeatureOptionId,
        FeaturePrerequisite,
        FixedCost,
        FixedDamageType,
        FixedSpellAmount,
        ForSpellDuration,
        FullDexterity,
        GrantsFeat,
        GrantsSubclass,
        HalfDamageOnSuccess,
        HasFeatCategory,
        HitPointDie,
        ItemId,
        Language,
        LevelBenefit,
        LevelPrerequisite,
        LightLevel,
        LineArea,
        LineageOption,
        LoadContentSet,
        LoadContentSetCommand,
        LoadContentSetLoaded,
        LoadContentSetRejected,
        LoadContentSetResult,
        MasteryProperty,
        MaterialComponent,
        MissingContent,
        ModelledEffects,
        MonsterId,
        MovedByCaster,
        MovesWithOrigin,
        MulticlassGrants,
        NamedText,
        NoAmountScaling,
        NoCountScaling,
        NoDexterity,
        NoWeight,
        Obscurement,
        OnlyCreatureTypes,
        OptionPrerequisite,
        PactSpellcastingRow,
        PactSpellcastingTrait,
        PartInstances,
        PartResolution,
        PerSlotLevelAmount,
        PerSlotLevelCount,
        PlainUse,
        Price,
        Prerequisite,
        ProgressionRow,
        RangePair,
        RechargeTrigger,
        ReferenceConstraint,
        ResolvedRow,
        RolledSpellAmount,
        RowClassFeature,
        RowFeature,
        RowSubclassFeature,
        ScalableAmount,
        SelfTargetPolicy,
        SharedSquareSpace,
        Skill,
        SkillChoice,
        SkillChoiceAny,
        SkillChoiceListed,
        SlotSpellcastingRow,
        SlotSpellcastingTrait,
        SourceCitation,
        SourceCitationParse,
        SourceCitationParsed,
        SourceCitationProblem,
        SourceCitationRejected,
        Species,
        SpeciesChoice,
        SpeciesId,
        SpecialSense,
        SpecificToolProficiency,
        Spell,
        SpellAmount,
        SpellAppliesCondition,
        SpellAttackKind,
        SpellCastingTimes,
        SpellCastingTimesModes,
        SpellCastingTimesSingle,
        SpellDealsDamage,
        SpellDuration,
        SpellDurationInstantaneous,
        SpellDurationSpecial,
        SpellDurationTimed,
        SpellDurationUntilDispelled,
        SpellDurationUntilDispelledOrTriggered,
        SpellEffectFacts,
        SpellEffectModel,
        SpellEffectPart,
        SpellGrant,
        SpellGrantsTemporaryHitPoints,
        SpellcastingRow,
        SpellId,
        SpellLevel,
        SpellLevelParse,
        SpellLevelParsed,
        SpellLevelRejected,
        SpellOutcome,
        SpellRange,
        SpellRangeDistance,
        SpellRangeSelf,
        SpellRangeSight,
        SpellRangeSpecial,
        SpellRangeTouch,
        SpellRangeUnlimited,
        SpellRestoresHitPoints,
        SpellSchool,
        SpellTargeting,
        SphereArea,
        StationaryZone,
        SubclassDefinition,
        SubclassFound,
        SubclassId,
        SubclassLookup,
        SubclassNotFound,
        SuccessEffect,
        TableCell,
        TableCellInt,
        TableCellText,
        TargetHasFeatCategory,
        TargetSubject,
        TargetsByInstance,
        TargetsChosen,
        TargetsInArea,
        TargetsSelf,
        TextOption,
        ThrownUse,
        TimedConditionDuration,
        ToolProficiency,
        TurnBoundary,
        TurnOwner,
        TwoHandedCondition,
        TwoHandedUse,
        TypedId,
        TypedIdParse,
        TypedIdParsed,
        TypedIdRejected,
        UpToTargets,
        UntilNextTurnBoundary,
        VersatileUse,
        Weapon,
        WeaponCategory,
        WeaponDamage,
        WeaponDiceDamage,
        WeaponFixedDamage,
        WeaponProficiency,
        WeaponProperty,
        WeaponPropertyUse,
        WeaponTrainingCategory,
        WeaponType,
        Weight,
        WeightSpec,
        WeightVaries,
        WholeSquareSpace,
        classSpellList,
        supportedSchemaVersions,
        validateContentSet,
        ZoneActionKind,
        ZoneFacts,
        ZoneMobility,
        ZoneRegionId,
        ZoneRuleFact,
        ZoneTargetScope,
        ZoneTrigger;
export 'src/d20_test/d20_test.dart'
    show
        AbilityCheckCommand,
        ArmorClass,
        AttackRollCommand,
        AttackRollResult,
        AutomaticFailure,
        CheckAttempt,
        CheckResult,
        ChooseToFail,
        D20Roll,
        D20TestCommand,
        D20TestKind,
        D20TestOutcome,
        D20TestResolver,
        D20TestSignals,
        DifficultyClass,
        ForcedFailureReason,
        ForcedFailureResult,
        KeepRoll,
        ResolveD20Test,
        ResolveD20TestForcedFailure,
        ResolveD20TestResult,
        ResolveD20TestRolledAttack,
        ResolveD20TestRolledCheck,
        RerollDecision,
        RerollDie,
        RollAttempt,
        RollModifiers,
        SaveAttempt,
        SavingThrowCommand;
export 'src/shared_kernel/ability/ability.dart' show Ability;
export 'src/shared_kernel/ability/ability_score.dart'
    show AbilityModifier, AbilityScore;
export 'src/shared_kernel/ability/ability_score_result.dart'
    show
        AbilityScoreRejection,
        AbilityScoreResult,
        InvalidAbilityScore,
        ValidAbilityScore;
export 'src/shared_kernel/ability/ability_scores.dart' show AbilityScores;
export 'src/shared_kernel/dice/dice_expression.dart'
    show
        CreatedDiceExpression,
        DiceExpression,
        DiceExpressionCreation,
        DiceExpressionParse,
        DiceExpressionRejection,
        ParsedDiceExpression,
        RejectedDiceExpression,
        RejectedDiceExpressionInput;
export 'src/shared_kernel/dice/die.dart'
    show CreatedDie, Die, DieCreation, DieRejection, RejectedDie;
export 'src/shared_kernel/dice/die_roll.dart'
    show
        CreatedDieRoll,
        DieRoll,
        DieRollCreation,
        DieRollRejection,
        RejectedDieRoll;
export 'src/shared_kernel/dice/roll_result.dart'
    show
        CreatedRollResult,
        RejectedRollResult,
        RollResult,
        RollResultCreation,
        RollResultRejection;
export 'src/shared_kernel/modifier.dart' show Modifier;
export 'src/shared_kernel/roll_circumstance.dart'
    show Advantage, Disadvantage, RollCircumstance;
export 'src/shared_kernel/roll_mode.dart' show RollMode;
export 'src/shared_ports/dice_roller/dice_roller.dart' show DiceRoller;
export 'src/shared_ports/dice_roller/dice_roller_checked.dart'
    show DiceRollerChecked;
export 'src/shared_ports/dice_roller/dice_roller_exception.dart'
    show DiceRollerException, DiceRollerFailureReason;
export 'src/shared_ports/errors/port_failure_guards.dart'
    show wrapPortFailure, wrapPortFailureAsync;
export 'src/shared_ports/errors/srd5e_exception.dart' show Srd5eException;
export 'src/shared_ports/observability/attributes.dart' show Attributes;
export 'src/shared_ports/observability/log_level.dart' show LogLevel;
export 'src/shared_ports/observability/logger.dart'
    show Logger, LoggerLevels, NoopLogger;
export 'src/shared_ports/observability/meter.dart'
    show Counter, Gauge, Histogram, Meter, NoopMeter;
export 'src/shared_ports/observability/observability.dart'
    show NoopObservability, Observability;
export 'src/shared_ports/observability/tracer.dart'
    show NoopTracer, Span, SpanStatus, Tracer;
export 'src/shared_ports/signals.dart' show AttributeKeys;
