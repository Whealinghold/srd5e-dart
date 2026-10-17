/// The `content` bounded context: the envelope game content enters the
/// package through — the content identity types, every closed SRD vocabulary
/// type and typed id, the printed-text building blocks and the neutral
/// `ContentTextBlock` family (SRD 5.2.1 passim; each type's dartdoc cites
/// its section and page).
///
/// ### Inputs
///
/// What a consumer or a decoding adapter supplies: content ids as strings
/// (validated by `ContentId` and the typed ids) and enum values by their
/// SRD-spelled JSON strings (each vocabulary type's static `fromJson`); the
/// parts of a `SourceCitation`; a `NamedText`'s name and text; the parts of
/// a `Prerequisite` or `ToolProficiency`; and the fields of a
/// `ContentTextBlock` — all arriving as plain Dart values already read from
/// whatever external format held them. Entries that reference other entries
/// implement `ContentReferences`; feats report their category through
/// `HasFeatCategory`.
///
/// ### Outputs
///
/// What the context publishes: the identity types [ContentKind], `ContentId`
/// with its parse result, [ContentKey], [ContentEntry] and [MissingContent];
/// the nine typed ids (`SpeciesId` … `FeatureId`); the closed vocabulary
/// types with their static SRD facts ([Skill]` .ability`,
/// [Language]` .isStandard`, [HitPointDie]` .faces`, [CreatureSize]` .space`
/// over the [CreatureSpace] family) and their `jsonValue`/`fromJson` pair;
/// the building blocks [SourceCitation], [NamedText], the sealed
/// [Prerequisite] and [ToolProficiency] families; the [ContentTextBlock]
/// family; the whole-set reference interfaces [ContentReferences],
/// [ContentReference], [ReferenceConstraint] and [HasFeatCategory]; and the
/// species, background and feat entry types — [Species] with its
/// [SpeciesChoice] choices over the sealed [ChoiceOption] family
/// ([DamageTypeOption], [LineageOption] with its [LevelBenefit]s,
/// [TextOption]), [Background] with its [BackgroundFeatReference] and
/// [EquipmentOptions] ([EquipmentOption], [EquipmentItem]), and [Feat] with
/// its [FeatBenefit]s — plus the custom-background step-5 check
/// ([EquipmentItemValue], the sealed [CustomBackgroundEquipmentProblem]
/// family and the pure `customBackgroundEquipmentProblems`).
///
/// The class entry types: [ClassDefinition] (the Features table's
/// [ProgressionRow]s over the sealed [RowFeature] and [SpellcastingRow]
/// families — [RowClassFeature], [RowSubclassFeature],
/// [SlotSpellcastingRow], [PactSpellcastingRow] — its declared [ClassColumn]s
/// with their [ColumnValue] cells, and its [FeatureEntry]s with their
/// [FeatureFact]s ([GrantsSubclass], [GrantsFeat], [AlwaysPreparedSpells]
/// over [SpellGrant]), [FeatureOption]s and [FeatureTable]s),
/// [SubclassDefinition], the pure accessors ([ResolvedRow], the
/// [FeatureEntryLookup] and [SubclassLookup] results) and the core-trait
/// value objects ([AbilityRequirement] over [AllOf] and [AnyOf],
/// [SkillChoice], [WeaponProficiency], [ArmorTrainingCategory],
/// [ClassToolProficiency], [ClassStartingEquipment], [MulticlassGrants],
/// [ClassSpellcastingTrait]), plus the id derivation `deriveFeatureId` and
/// the [FeatureOptionId] and [ClassColumnId] id types.
///
/// The spell types: [Spell] — the content entry of kind
/// `ContentKind.spell` — over [SpellLevel] with `tryCreate`, [SpellSchool],
/// the sealed [CastingTime] family ([CastingTimeMagicAction],
/// [CastingTimeBonusAction], [CastingTimeReaction], [CastingTimeMinutes],
/// [CastingTimeHours]) under the sealed [SpellCastingTimes]
/// ([SpellCastingTimesSingle], [SpellCastingTimesModes] over
/// [CastingTimeMode]), the sealed [SpellRange] family ([SpellRangeSelf],
/// [SpellRangeTouch], [SpellRangeDistance], [SpellRangeSight],
/// [SpellRangeUnlimited], [SpellRangeSpecial]), [SpellComponents] over
/// [MaterialComponent], the sealed [SpellDuration] family
/// ([SpellDurationInstantaneous], [SpellDurationTimed] over [DurationLimit],
/// [SpellDurationUntilDispelled], [SpellDurationUntilDispelledOrTriggered],
/// [SpellDurationSpecial]), [DistanceUnit], and the derived class spell
/// lists ([classSpellList] over [ClassSpellList]). The structured
/// `Spell.effects` model ([SpellEffectModel] — [TextOnlyEffects],
/// [ModelledEffects] over [EffectCoverage]) with its targeting
/// ([SpellTargeting], [TargetsSelf], [TargetsChosen], [TargetsInArea],
/// [TargetSubject], [TargetCount], [ExactlyTargets], [UpToTargets],
/// [TargetsByInstance], [SelfTargetPolicy], [CreatureTypeRestriction],
/// [AnyCreatureType], [OnlyCreatureTypes], [AreaShape], [ConeArea],
/// [CubeArea], [CylinderArea], [EmanationArea], [LineArea], [SphereArea]),
/// its parts ([SpellEffectPart], [PartResolution], [AttackRollResolution],
/// [SavingThrowResolution], [AutomaticResolution], [SpellAttackKind],
/// [SuccessEffect], [NothingOnSuccess], [HalfDamageOnSuccess],
/// [PartInstances]), its outcomes ([SpellOutcome], [SpellDealsDamage],
/// [SpellRestoresHitPoints], [SpellGrantsTemporaryHitPoints],
/// [SpellAppliesCondition], [ModifierAddition], [DamageTypeSelection],
/// [FixedDamageType], [ChosenDamageType], [ConditionDuration],
/// [ForSpellDuration], [TimedConditionDuration], [UntilNextTurnBoundary],
/// [TurnOwner], [TurnBoundary], [ScalableAmount], [SpellAmount],
/// [RolledSpellAmount], [FixedSpellAmount]), its scaling ([AmountScaling],
/// [NoAmountScaling], [PerSlotLevelAmount], [ByCharacterLevelAmount],
/// [CountScaling], [NoCountScaling], [PerSlotLevelCount],
/// [ByCharacterLevelCount], [AmountStep], [CharacterLevelTable]), its facts
/// ([SpellEffectFacts], [EffectFact], [FactKnown], [FactUnknown]) and its
/// zone facts ([ZoneFacts], [ZoneRuleFact], [ZoneTrigger], [ZoneTargetScope],
/// [ZoneRegionId], [ZoneMobility], [StationaryZone], [MovesWithOrigin],
/// [MovedByCaster], [DriftsAtTurnStart], [ZoneActionKind],
/// [DriftDirectionRule], [DesignationPolicy], [ZoneMovementFacts]).
///
/// The equipment shapes the baseline revision row registers: [Coin],
/// [CostRate], [Cost] with `compareByValue`, the sealed [Price]
/// ([FixedCost], [CostVaries]), the sealed [WeightSpec] ([Weight],
/// [WeightVaries], [NoWeight]), [EquipmentCategory], [ArmorCategory] with
/// its [DonDoffTime] facts ([DonDoffMinutes], [DonDoffByUtilize]), the
/// sealed [ArmorClassRule] ([BaseRule] over the sealed [DexterityBonus]
/// family — [FullDexterity], [CappedDexterity], [NoDexterity] — and
/// [BonusRule]), [Weapon] over [WeaponCategory], [WeaponType],
/// [WeaponDamage] ([WeaponDiceDamage], [WeaponFixedDamage]) and the sealed
/// [WeaponPropertyUse] family ([PlainUse], [AmmunitionUse], [ThrownUse],
/// [VersatileUse], [TwoHandedUse] with [RangePair], [AmmunitionType],
/// [TwoHandedCondition]), and [Armor].
///
/// ### Asking for content
///
/// The [ContentSource] port is how the rest of the package asks "give me
/// the content entry with this key" without knowing where content lives:
/// [ContentSource.lookup] answers a [ContentLookup] — the [ContentFound]
/// entry or the [ContentNotFound] key with its [MissingContent] detail —
/// and [ContentSource.listKind] answers every entry of one kind, ordered by
/// id. An infrastructure failure completes the future with a
/// [ContentSourceException] carrying the [ContentQuery] asked
/// ([ContentLookupQuery] or [ContentListKindQuery]); absence never throws.
/// The pure [ContentCatalogue] holds the duplicate-key, lookup and ordering
/// rules the in-process sources share.
///
/// The generic sources are not here: `InMemoryContentSource` and
/// `BundledContentSource` are in `package:srd5e/adapters.dart` and the
/// `FakeContentSource` double in `package:srd5e/testing.dart`.
///
/// ### Decoding
///
/// The envelope and its decode path: a [ContentSetDecoder] turns one
/// document's text into a [ContentDecodeResult] — a [ContentDecoded]
/// carrying a [ContentSet], or a [ContentDecodeFailed] carrying every
/// [ContentProblem] (a JSON Pointer path and a [ContentProblemKind]) in the
/// decoder's deterministic order — for the version
/// [supportedSchemaVersions] supports. [validateContentSet] resolves every
/// cross-entry reference over the merged sets and returns the
/// [ContentSetValidation] ([ContentSetValid] with the merged set, or
/// [ContentSetInvalid] with the [ContentReferenceProblem]s); it is the
/// only place a reference between entries is checked.
///
/// ### Loading a document
///
/// The [LoadContentSet] use case runs a [ContentSetDecoder] over one
/// document's text and returns the sealed [LoadContentSetResult]: a
/// [LoadContentSetLoaded] carrying the decoded set, or a
/// [LoadContentSetRejected] carrying every problem. It emits the signals
/// named by [ContentSignals]; `validateContentSet` stays outside it (FR-131)
/// and runs beside it. The use case calls no other use case.
///
/// The kernel types ([Ability]) are not re-exported here; import them from
/// the package's public entry point.
library;

export 'application/content_decode_result.dart'
    show ContentDecodeFailed, ContentDecodeResult, ContentDecoded;
export 'application/content_problem.dart' show ContentProblem;
export 'application/content_signals.dart' show ContentSignals;
export 'application/load_content_set.dart'
    show
        LoadContentSet,
        LoadContentSetCommand,
        LoadContentSetLoaded,
        LoadContentSetRejected,
        LoadContentSetResult;
export 'application/ports/content_set_decoder.dart' show ContentSetDecoder;
export 'application/ports/content_source.dart'
    show ContentSource, ContentSourceException;
export 'application/schema_version.dart'
    show currentSchemaVersion, supportedSchemaVersions;
export 'domain/alignment.dart' show Alignment;
export 'domain/background.dart' show Background;
export 'domain/background_feat_reference.dart' show BackgroundFeatReference;
export 'domain/choice_option.dart'
    show ChoiceOption, DamageTypeOption, LineageOption, TextOption;
export 'domain/classes/ability_requirement.dart'
    show AbilityRequirement, AllOf, AnyOf;
export 'domain/classes/armor_training_category.dart' show ArmorTrainingCategory;
export 'domain/classes/class_column.dart'
    show ClassColumn, ClassColumnId, ClassColumnKind;
export 'domain/classes/class_definition.dart'
    show
        ClassDefinition,
        FeatureEntryFound,
        FeatureEntryLookup,
        FeatureEntryNotFound,
        ResolvedRow,
        SubclassFound,
        SubclassLookup,
        SubclassNotFound;
export 'domain/classes/class_spellcasting_trait.dart'
    show ClassSpellcastingTrait, PactSpellcastingTrait, SlotSpellcastingTrait;
export 'domain/classes/class_starting_equipment.dart'
    show ClassEquipmentItem, ClassEquipmentOption, ClassStartingEquipment;
export 'domain/classes/class_tool_proficiency.dart'
    show
        ClassToolProficiency,
        ClassToolProficiencyChoice,
        ClassToolProficiencySpecific;
export 'domain/classes/column_value.dart'
    show
        ColumnBonus,
        ColumnCount,
        ColumnDice,
        ColumnFeetBonus,
        ColumnNone,
        ColumnValue;
export 'domain/classes/derive_feature_id.dart' show deriveFeatureId;
export 'domain/classes/feature_entry.dart' show FeatureEntry;
export 'domain/classes/feature_fact.dart'
    show
        AlwaysPreparedSpells,
        FeatureFact,
        GrantsFeat,
        GrantsSubclass,
        SpellGrant;
export 'domain/classes/feature_option.dart'
    show FeatureOption, FeatureOptionId, OptionPrerequisite;
export 'domain/classes/feature_table.dart'
    show FeatureTable, TableCell, TableCellInt, TableCellText;
export 'domain/classes/multiclass_grants.dart' show MulticlassGrants;
export 'domain/classes/progression_row.dart'
    show
        PactSpellcastingRow,
        ProgressionRow,
        RowClassFeature,
        RowFeature,
        RowSubclassFeature,
        SlotSpellcastingRow,
        SpellcastingRow;
export 'domain/classes/skill_choice.dart'
    show SkillChoice, SkillChoiceAny, SkillChoiceListed;
export 'domain/classes/subclass_definition.dart' show SubclassDefinition;
export 'domain/classes/weapon_proficiency.dart'
    show WeaponProficiency, WeaponTrainingCategory;
export 'domain/condition_kind.dart' show ConditionKind;
export 'domain/content_catalogue.dart' show ContentCatalogue;
export 'domain/content_entry.dart' show ContentEntry;
export 'domain/content_id.dart'
    show
        ContentId,
        ContentIdParse,
        ContentIdParsed,
        ContentIdProblem,
        ContentIdRejected;
export 'domain/content_key.dart' show ContentKey;
export 'domain/content_kind.dart' show ContentKind;
export 'domain/content_lookup.dart'
    show ContentFound, ContentLookup, ContentNotFound;
export 'domain/content_problem_kind.dart' show ContentProblemKind;
export 'domain/content_query.dart'
    show ContentListKindQuery, ContentLookupQuery, ContentQuery;
export 'domain/content_reference.dart'
    show
        ContentReference,
        ContentReferences,
        HasFeatCategory,
        ReferenceConstraint,
        TargetHasFeatCategory;
export 'domain/content_reference_problem.dart' show ContentReferenceProblem;
export 'domain/content_set.dart' show ContentSet;
export 'domain/content_set_validation.dart'
    show ContentSetInvalid, ContentSetValidation, ContentSetValid;
export 'domain/content_text_block.dart'
    show
        ContentTextBlock,
        ContentTextBulletList,
        ContentTextEmbeddedStatBlock,
        ContentTextEntry,
        ContentTextParagraph,
        ContentTextTable;
export 'domain/creature_size.dart'
    show CreatureSize, CreatureSpace, SharedSquareSpace, WholeSquareSpace;
export 'domain/creature_type.dart' show CreatureType;
export 'domain/custom_background_equipment.dart'
    show
        CustomBackgroundEquipmentProblem,
        EquipmentItemExcluded,
        EquipmentItemUnpriced,
        EquipmentValuation,
        EquipmentValueNotFiftyGold,
        customBackgroundEquipmentProblems;
export 'domain/damage_type.dart' show DamageType;
export 'domain/darkness_kind.dart' show DarknessKind;
export 'domain/duration_unit.dart' show DurationUnit;
export 'domain/equipment/armor.dart' show Armor;
export 'domain/equipment/armor_category.dart'
    show ArmorCategory, DonDoffByUtilize, DonDoffMinutes, DonDoffTime;
export 'domain/equipment/armor_class_rule.dart'
    show
        ArmorClassRule,
        BaseRule,
        BonusRule,
        CappedDexterity,
        DexterityBonus,
        FullDexterity,
        NoDexterity;
export 'domain/equipment/coin.dart' show Coin;
export 'domain/equipment/cost.dart' show Cost, CostRate;
export 'domain/equipment/equipment_category.dart' show EquipmentCategory;
export 'domain/equipment/price.dart' show CostVaries, FixedCost, Price;
export 'domain/equipment/weapon.dart' show Weapon, WeaponCategory, WeaponType;
export 'domain/equipment/weapon_damage.dart'
    show WeaponDamage, WeaponDiceDamage, WeaponFixedDamage;
export 'domain/equipment/weapon_property_use.dart'
    show
        AmmunitionType,
        AmmunitionUse,
        PlainUse,
        RangePair,
        ThrownUse,
        TwoHandedCondition,
        TwoHandedUse,
        VersatileUse,
        WeaponPropertyUse;
export 'domain/equipment/weight_spec.dart'
    show NoWeight, Weight, WeightSpec, WeightVaries;
export 'domain/equipment_item_value.dart' show EquipmentItemValue;
export 'domain/equipment_options.dart'
    show EquipmentItem, EquipmentOption, EquipmentOptions;
export 'domain/feat.dart' show Feat;
export 'domain/feat_benefit.dart' show FeatBenefit;
export 'domain/feat_category.dart' show FeatCategory;
export 'domain/hit_point_die.dart' show HitPointDie;
export 'domain/language.dart' show Language;
export 'domain/level_benefit.dart' show LevelBenefit;
export 'domain/light_level.dart' show LightLevel;
export 'domain/mastery_property.dart' show MasteryProperty;
export 'domain/missing_content.dart' show MissingContent;
export 'domain/named_text.dart' show NamedText;
export 'domain/obscurement.dart' show Obscurement;
export 'domain/prerequisite.dart'
    show
        AbilityScorePrerequisite,
        FeaturePrerequisite,
        LevelPrerequisite,
        Prerequisite;
export 'domain/recharge_trigger.dart' show RechargeTrigger;
export 'domain/skill.dart' show Skill;
export 'domain/source_citation.dart'
    show
        SourceCitation,
        SourceCitationParse,
        SourceCitationParsed,
        SourceCitationProblem,
        SourceCitationRejected;
export 'domain/special_sense.dart' show SpecialSense;
export 'domain/species.dart' show Species;
export 'domain/species_choice.dart' show SpeciesChoice;
export 'domain/spells/class_spell_list.dart'
    show ClassSpellList, classSpellList;
export 'domain/spells/spell.dart' show Spell;
export 'domain/spells/spell_casting_time.dart'
    show
        CastingTime,
        CastingTimeBonusAction,
        CastingTimeHours,
        CastingTimeMagicAction,
        CastingTimeMinutes,
        CastingTimeMode,
        CastingTimeReaction,
        SpellCastingTimes,
        SpellCastingTimesModes,
        SpellCastingTimesSingle;
export 'domain/spells/spell_components.dart'
    show MaterialComponent, SpellComponents;
export 'domain/spells/spell_duration.dart'
    show
        DurationLimit,
        SpellDuration,
        SpellDurationInstantaneous,
        SpellDurationSpecial,
        SpellDurationTimed,
        SpellDurationUntilDispelled,
        SpellDurationUntilDispelledOrTriggered;
export 'domain/spells/spell_effect_facts.dart'
    show EffectFact, FactKnown, FactUnknown, SpellEffectFacts;
export 'domain/spells/spell_effect_model.dart'
    show EffectCoverage, ModelledEffects, SpellEffectModel, TextOnlyEffects;
export 'domain/spells/spell_effect_part.dart'
    show
        AttackRollResolution,
        AutomaticResolution,
        HalfDamageOnSuccess,
        NothingOnSuccess,
        PartInstances,
        PartResolution,
        SavingThrowResolution,
        SpellAttackKind,
        SpellEffectPart,
        SuccessEffect;
export 'domain/spells/spell_level.dart'
    show SpellLevel, SpellLevelParse, SpellLevelParsed, SpellLevelRejected;
export 'domain/spells/spell_outcome.dart'
    show
        ChosenDamageType,
        ConditionDuration,
        DamageTypeSelection,
        FixedDamageType,
        ForSpellDuration,
        ModifierAddition,
        SpellAppliesCondition,
        SpellDealsDamage,
        SpellGrantsTemporaryHitPoints,
        SpellOutcome,
        SpellRestoresHitPoints,
        TimedConditionDuration,
        TurnBoundary,
        TurnOwner,
        UntilNextTurnBoundary;
export 'domain/spells/spell_range.dart'
    show
        DistanceUnit,
        SpellRange,
        SpellRangeDistance,
        SpellRangeSelf,
        SpellRangeSight,
        SpellRangeSpecial,
        SpellRangeTouch,
        SpellRangeUnlimited;
export 'domain/spells/spell_scaling.dart'
    show
        AmountScaling,
        AmountStep,
        FixedSpellAmount,
        RolledSpellAmount,
        ScalableAmount,
        SpellAmount,
        ByCharacterLevelAmount,
        ByCharacterLevelCount,
        CharacterLevelTable,
        CountScaling,
        NoAmountScaling,
        NoCountScaling,
        PerSlotLevelAmount,
        PerSlotLevelCount;
export 'domain/spells/spell_school.dart' show SpellSchool;
export 'domain/spells/spell_targeting.dart'
    show
        AnyCreatureType,
        AreaShape,
        ConeArea,
        CreatureTypeRestriction,
        CubeArea,
        CylinderArea,
        EmanationArea,
        ExactlyTargets,
        LineArea,
        OnlyCreatureTypes,
        SelfTargetPolicy,
        SphereArea,
        SpellTargeting,
        TargetCount,
        TargetSubject,
        TargetsByInstance,
        TargetsChosen,
        TargetsInArea,
        TargetsSelf,
        UpToTargets;
export 'domain/spells/zone_facts.dart'
    show
        DesignationPolicy,
        DriftDirectionRule,
        DriftsAtTurnStart,
        MovedByCaster,
        MovesWithOrigin,
        StationaryZone,
        ZoneActionKind,
        ZoneFacts,
        ZoneMobility,
        ZoneRegionId,
        ZoneRuleFact,
        ZoneTargetScope,
        ZoneTrigger;
export 'domain/tool_proficiency.dart'
    show ChoiceToolProficiency, SpecificToolProficiency, ToolProficiency;
export 'domain/typed_id.dart'
    show ContentKeyedId, TypedId, TypedIdParse, TypedIdParsed, TypedIdRejected;
export 'domain/typed_ids.dart'
    show
        BackgroundId,
        ClassId,
        FeatureId,
        FeatId,
        ItemId,
        MonsterId,
        SpeciesId,
        SpellId,
        SubclassId;
export 'domain/validate_content_set.dart' show validateContentSet;
export 'domain/weapon_property.dart' show WeaponProperty;
