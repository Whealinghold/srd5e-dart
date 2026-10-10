# Tool proficiency and crafting prerequisites

| | |
|---|---|
| Status | draft |
| Context | `character` |
| Roadmap phase | Types 3; bulk data 5 |
| Depends on | `content-equipment.md`, `content-spells.md`, `content-schema-and-decoder.md`, `ability-scores.md`, `modifiers-and-advantage.md`, `d20-tests.md`, `equipment-rules.md`, `derived-stats.md`, `character-aggregate.md`, `spellcasting.md`, `magic-item-rules.md`, `errors-and-results.md` |

## 1. Purpose and scope

Four SRD rules had no behaviour owner (`derived-stats.md` section 1, `equipment-rules.md` Q13): **Tool Proficiency** on an ability check, the **Utilize** DCs of a tool, the **prerequisites of crafting** a nonmagical item or brewing a Potion of Healing, and the **prerequisites of scribing** a Spell Scroll. This spec owns them as pure `character` domain code (`lib/src/character/domain/tools/`). It composes `Crafting.toolsFor` and `Crafting.requirementsFor` (`equipment-rules.md`) with character state held by the host as plain values, and returns facts and roll circumstances. It rolls nothing: the host passes `RollModifiers` and circumstances to `ResolveD20Test` (`resolve-d20-test-use-case.md`). Shortfalls are results, not exceptions.

It is rank 14 in the rank table of `shared-types-and-ownership.md` section 4.11 (the rank-14 row, beside `level-advancement-and-multiclassing` and `casting-and-concentration`) because it reads `spellcasting.md` and `magic-item-rules.md` (rank 13); the row and a `doc/documentation_index.md` row are added together with this spec (`architecture-guardrails.md` FR-101, FR-102). It defines no use case, port or event; a use case that needs it calls the static functions (`shared-types-and-ownership.md` FR-044).

**Out of scope:**

- Which tool, skill or ability the Game Master asks for on a given check (the GM's choice; the caller supplies the tool, the optional skill and an optional ability). Item-use effects in gear and tool text beyond the Utilize DC (`equipment-rules.md` out-of-scope list).
- Weapon and armor proficiency (`weapon-properties-and-mastery.md`, `equipment-rules.md`); magic item crafting (`magic-item-rules.md`: Arcana, tools, assistants, `MagicItemCrafting`); a Spell Scroll's use (casting from a scroll, p. 99 and p. 104, is out of scope of `spellcasting.md` and `magic-item-rules.md` alike, so no spec consumes `ScribedScroll.saveDc` / `attackBonus` yet; it stays out of scope here, FR-040).
- Whether raw materials are available (the GM decides, p. 103), paying their cost, and the Game Master tool assignment beyond accepting one as input (FR-029).
- Granting tool proficiencies at creation (`character-creation.md`), holding them on a `Character` (the aggregate stores none; the host holds `ToolProficiencies` beside it, like `SkillProficiencies`), and the Help action's use of a helper's proficiency (`attack-and-help-actions.md` FR-036).
- Not in the PDF: the SRD gives no Expertise in a tool (p. 182 limits it to skill proficiencies), no rounding rule for crafting time divided among workers (the whole-day rounding of p. 103, "round a fraction up to a day", is already in `Crafting.days`, `equipment-rules.md` FR-035; same gap as `magic-item-rules.md` FR-083), and no separate Material-component rule for scribing; none is invented.

## 2. Source

SRD 5.2.1, "Proficiency" and "Skill Proficiencies", "The Bonus Doesn't Stack", "Equipment Proficiencies" (Tools), p. 8-9; "Tools" (Ability, Utilize, Craft, Variants, "Tool Proficiency"), Artisan's Tools and Other Tools entries, pp. 93-94; "Potion of Healing", "Spell Scroll", p. 99; "Material (M)", pp. 105-106; "Crafting Nonmagical Items", "Brewing Potions of Healing", "Scribing Spell Scrolls", "Spell Scroll Costs", p. 103; Rules Glossary "Proficiency", p. 186, "Expertise", p. 182, "Utilize [Action]", p. 191. Package design: `doc/rules/architecture.md`, `observability.md`, `testing.md`; `shared-types-and-ownership.md`. Printed page equals PDF page.

## 3. Vocabulary

| SRD term | Type | Notes |
|---|---|---|
| Tool Proficiency | `ToolProficiencies` | Set of tool `ItemId`s; "A monster has proficiency with any tool in its stat block" (p. 93). Each variant needs "a separate proficiency" (p. 93). |
| Ability, Utilize (tool entries) | `ResolvedTool`, `ToolResolution` | Facts of a tool, a variant taking them from its family (`content-equipment.md` FR-029). Package term. |
| Advantage when also proficient in the skill | `ToolCheckBenefits` | Proficiency Bonus multiple and circumstances for one check (p. 9, p. 93). |
| Utilize action and its DC | `ToolUtilize`, `ToolUtilizeDc` | The listed `ToolUtilizeAction` (description, DC). |
| Crafter, "anyone who helps you" | `CraftingWorker`, `CraftingParty` | p. 103. Package terms. |
| Crafting Nonmagical Items, Brewing Potions of Healing | `ItemCraftingPlanner`, `ItemCraftingPlan` | Tools, Raw Materials, Time (p. 103). Reuses `CraftingRequirements`, `WorkHours`, `AssistantAllowance`. |
| Scribing Spell Scrolls | `ScribeQualification`, `ScrollScribingJob`, `ScribingDayOutcome` | Prerequisites for the Scribe (p. 103). |
| Prepared spell (package term) | `PreparedSpellSet` | Spell ids available each day, from `spellcasting.md` state. |

Terms use SRD wording (`doc/rules/architecture.md` section 3). `Skill`, `ItemId`, `SpellId`, `SpellLevel`, `Tool`, `Spell`, `MaterialComponent` are `content` types; `Ability`, `AbilityModifier`, `RollModifiers`, `DifficultyClass`, `RollCircumstance`, `Advantage` come from the kernel and `d20_test`; `SkillProficiencies`, `ProficiencyBonus`, `CharacterLevel` from `derived-stats.md`; `CharacterId` from `character-aggregate.md`; `WorkHours`, `AssistantAllowance` from `magic-item-rules.md`; `SpellSaveDc`, `SpellAttackBonus` from `spellcasting.md`. None is redefined.

## 4. Requirements

Stable ids. Case tables follow `doc/rules/testing.md` sections 5 and 6: each `<br>`-separated entry is one table-driven test, path from the Path cell.

### 4.1 Tool proficiency and tool facts

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-001 | `ToolProficiencies` MUST be an immutable value object over a set of tool `ItemId`s: it copies its input, `contains(id)` and `plus(id)` (a new value) MUST work, equal sets give equal values with equal hash codes, the exposed set is unmodifiable (`UnsupportedError`), and iteration order of the input MUST NOT matter. An empty set is valid. | SRD 5.2.1, "Tool Proficiency", p. 93; architecture.md section 3 | unhappy (immutability) |
| FR-002 | Proficiency MUST be per entry id: proficiency with `gaming_set_dice` MUST NOT count for `gaming_set_playing_cards`, and proficiency recorded under a family id (`gaming_set`, `musical_instrument`) MUST NOT count for any variant. | SRD 5.2.1, "Tools" (Variants: "Each requires a separate proficiency"), p. 93; Artisan's Tools ("Each ... requires a separate proficiency"), p. 93 | unhappy (rule interaction) |
| FR-003 | `ToolProficiencies.ofMonster(statBlockTools)` MUST hold exactly the tools of the stat block. | SRD 5.2.1, "Tool Proficiency" ("A monster has proficiency with any tool in its stat block"), p. 93 | happy |
| FR-004 | `ToolRules.resolve(Tool tool, Iterable<Tool> catalogue)` MUST return `ToolResolved` holding a `ResolvedTool` (`proficiencyId`, `ability`, unmodifiable `utilize` list, `group`). For a `StandaloneTool` the facts are its own and `proficiencyId` its id. For a `ToolVariant` the `ability`, `utilize` and `group` MUST be its family's (found by `variantOf` in the catalogue) while `proficiencyId` stays the variant's own id. | SRD 5.2.1, "Tools" (Ability, Utilize, Variants), pp. 93-94; content-equipment.md FR-029, FR-113 | happy |
| FR-005 | A `ToolFamily` passed on its own (Gaming Set, Musical Instrument) MUST return `ToolFamilyNeedsVariant(familyId)`: a family is not a proficiency. A variant whose `variantOf` is absent from the catalogue, names a non-family (a standalone tool or another variant) or names a family id held twice in the catalogue MUST return `ToolFamilyMissing(variantId, familyId)`: an ambiguous family is no family, so the result never depends on catalogue order. Neither throws. | SRD 5.2.1, "Gaming Set", "Musical Instrument", p. 94; architecture.md section 6 | unhappy (missing content) |
| FR-006 | `ResolvedTool.ability` MUST be the Ability entry of the tool (Alchemist's Supplies Intelligence; Carpenter's Tools Strength; Thieves' Tools Dexterity; Gaming Set Wisdom; Musical Instrument Charisma; all rows of "Cases: tool facts" hold). | SRD 5.2.1, Artisan's Tools and Other Tools, pp. 93-94 | happy |

### 4.2 The ability check with a tool

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-007 | `ToolCheckBenefits.evaluate({ResolvedTool tool, ToolProficiencies tools, SkillProficiencies skills, Skill? skillUsed, Ability? ability})` with `tools` containing `tool.proficiencyId` MUST give a Proficiency Bonus multiple of 1 and `toolProficient` true. | SRD 5.2.1, "Tool Proficiency", p. 93; "Equipment Proficiencies", p. 9 | happy |
| FR-008 | With no tool proficiency and no proficiency in `skillUsed` the multiple MUST be 0, `usesProficiency` false and the circumstance list empty. | SRD 5.2.1, "Tool Proficiency", p. 93 | unhappy (boundary) |
| FR-009 | With tool proficiency and proficiency in `skillUsed` the circumstances MUST be exactly one `Advantage`, and the multiple MUST stay 1: the bonus is added once. | SRD 5.2.1, "Tool Proficiency" ("you have Advantage on the check too"), p. 93; "Equipment Proficiencies" ("benefit from both"), p. 9; "The Bonus Doesn't Stack", p. 8 | unhappy (rule interaction) |
| FR-010 | **Interpretation:** with proficiency in `skillUsed` but not in the tool the multiple MUST be 1 (the check uses the skill, so the skill's bonus applies) and there MUST be no `Advantage`, no tool benefit (`toolProficient` false). | SRD 5.2.1, "Skill Proficiencies" (a check that uses a skill adds the bonus when proficient), p. 8; "Equipment Proficiencies" ("benefit from both skill proficiency and tool proficiency on the same ability check"), p. 9; "Tool Proficiency", p. 93 (Advantage needs both) | unhappy (rule interaction) |
| FR-011 | Expertise in `skillUsed` (in `skills.expertise`) MUST give a multiple of 2 whether or not the tool is proficient, never 3: the bonus "can be multiplied only once". Expertise in another skill than `skillUsed` MUST have no effect. | SRD 5.2.1, "Expertise", p. 182; "The Bonus Doesn't Stack", p. 8 | unhappy (rule interaction) |
| FR-012 | A null `skillUsed` MUST mean no skill takes part: no skill proficiency or Expertise is read and no `Advantage` is given, whatever `skills` holds. | SRD 5.2.1, "Tool Proficiency" ("a skill that's used with that check"), p. 93 | unhappy (empty and minimal) |
| FR-013 | `ToolCheckBenefits.ability` MUST be `ability` when given and else the tool's Ability. Proficiency and Advantage MUST NOT depend on it (the GM may pair a tool with another ability; the caller supplies the choice). | SRD 5.2.1, "Tools" (Ability: "the ability to use when making an ability check with the tool"), p. 93 | unhappy (rule interaction) |
| FR-014 | `rollModifiers(AbilityModifier modifier, ProficiencyBonus bonus, {Iterable<Modifier> others})` MUST return a `RollModifiers` whose ability slot is the modifier, whose Proficiency Bonus slot is absent for multiple 0 and else one `Modifier` of multiple times the bonus, and whose others pass through. A second bonus is unrepresentable (`shared-types-and-ownership.md` FR-003). | SRD 5.2.1, "Add Modifiers", "The Bonus Doesn't Stack", p. 6, p. 8; shared-types-and-ownership.md FR-003 | happy |
| FR-015 | `circumstances` MUST be an unmodifiable list of at most one `Advantage`, accepted by `RollMode.resolve`: alone it gives `advantage`, with one `Disadvantage` (a condition) it gives `normal`. No D20 Test is resolved. | SRD 5.2.1, "They Don't Stack", p. 8; modifiers-and-advantage.md FR-042 | unhappy (rule interaction) |
| FR-016 | `usesProficiency` MUST be true exactly when the multiple is above 0 (tool proficient, or `skillUsed` proficient). It is the fact other specs read for "a check that uses a skill or tool proficiency" (`class-rogue.md` FR-078). | SRD 5.2.1, "Proficiency", p. 186 ("proficiency in a skill or saving throw or with a weapon or tool") | happy |
| FR-017 | `evaluate` MUST be deterministic, MUST NOT alter its inputs, and results MUST be immutable value objects equal when their fields are equal. | architecture.md section 3; testing.md section 4 | unhappy (immutability) |

### 4.3 Utilize

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-018 | `ToolUtilize.actions(ResolvedTool)` MUST return the tool's listed `ToolUtilizeAction`s in printed order (a variant's are its family's), unmodifiable, never empty. | SRD 5.2.1, "Tools" (Utilize), p. 93; content-equipment.md FR-029 | happy |
| FR-019 | `ToolUtilize.dcFor(ResolvedTool, ToolUtilizeAction)` MUST return `ToolUtilizeDc(DifficultyClass)` of that action: one action per Utilize ("You can do one of those things each time you take the action"), so Cook's Utensils gives DC 10 for improving flavor and DC 15 for detecting spoiled food, never a combined DC. | SRD 5.2.1, "Tools" (Utilize), p. 93; Cook's Utensils, p. 93 | happy |
| FR-020 | An action not in the tool's list MUST return `ToolUtilizeActionNotListed`: no throw, no DC guessed. The tool entry "lists things you can do with the tool ... also provides the DC", so an unlisted action has no DC here and the host or Game Master supplies one (package design). | SRD 5.2.1, "Tools" (Utilize), p. 93; architecture.md section 6 | unhappy (missing content) |
| FR-021 | `ToolUtilize.check(resolved, action, benefits)` MUST return a sealed `ToolUtilizeCheckResult`: `ToolUtilizeCheck` holding the benefits' `ability`, the action's DC and the benefits, so the host can resolve the check with `ResolveD20Test`; `ToolUtilizeActionNotListed` as in FR-020; or `ToolUtilizeBenefitsMismatch(toolId, benefitsToolId)` when `benefits.proficiencyId` (exposed by `ToolCheckBenefits`, set by `evaluate` from its tool) differs from `resolved.proficiencyId`, so a wrong pairing is never silently scored. | SRD 5.2.1, "Tools" (Ability, Utilize), p. 93; "Utilize [Action]", p. 191 | happy |
| FR-022 | Over the bundled data, every row of "Cases: tool facts" MUST hold for all 25 standalone and family tools and the 14 variants (phase 5 data). | SRD 5.2.1, pp. 93-94 | happy |

### 4.4 Crafting a nonmagical item

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-023 | `CraftingWorker(CharacterId id, ToolProficiencies tools)` and `CraftingParty(crafter, helpers)` MUST be immutable; the helper list is copied and unmodifiable; a repeated id (a helper equal to the crafter or to another helper) MUST throw `ArgumentError`. | SRD 5.2.1, "Time", p. 103; architecture.md section 6 | unhappy (invalid input) |
| FR-024 | `ItemCraftingPlanner.plan({EquipmentEntry item, Iterable<Tool> tools, ScrollScribing? scribing, CraftingParty party, AssistantAllowance allowance = standard, ItemId? gmAssignedTool})` MUST first call `Crafting.requirementsFor(item, tools:, scribing:)` and branch on it; it MUST NOT recompute cost, days or tools (`equipment-rules.md` FR-040, FR-048). | SRD 5.2.1, "Crafting Nonmagical Items", p. 103; equipment-rules.md FR-040 | happy |
| FR-025 | A `NotCraftable` from `requirementsFor` MUST be returned as `ItemCraftingNotCraftable(reason)` with the party not evaluated. A `ScrollVariant` MUST return `ItemCraftingUseScribing` (scribing has its own prerequisites, 4.5) with the party not evaluated. | SRD 5.2.1, "Crafting Nonmagical Items", p. 103; equipment-rules.md FR-042, FR-043 | unhappy (rule interaction) |
| FR-026 | The crafter and every helper MUST be proficient with the one tool used. The usable tools are the alternatives of `CraftingRequirements.tools` that **every** worker is proficient with; any one suffices (`equipment-rules.md` Q8), so Club with the crafter proficient in Carpenter's Tools and a helper in Woodcarver's Tools has no shared tool. | SRD 5.2.1, "Tools" ("You must use the required tool ... Anyone who helps you must also have proficiency with it"), p. 103; equipment-rules.md FR-039 | unhappy (rule interaction) |
| FR-027 | When no usable tool exists the plan MUST be `ItemCraftingBlocked` with shortfalls: `ToolShortfallWorker(role, workerId, alternatives)` for each worker proficient with none of the alternatives, crafter first then helpers in party order; and `ToolShortfallNoSharedTool(alternatives)` when every worker has some alternative but none is common. Every shortfall is reported at once. | SRD 5.2.1, "Tools", p. 103; architecture.md section 5 (all problems at once) | unhappy (invalid input) |
| FR-028 | `CraftingParty` helpers beyond the cap MUST be reported as `ToolShortfallTooManyHelpers(count, cap)`. The cap is 1 by default; `AssistantAllowance.gmAllows(n)` raises it (`magic-item-rules.md` FR-082). | SRD 5.2.1, "Time" ("Normally, only one other character can assist you, but the GM might allow more"), p. 103 | unhappy (boundary) |
| FR-029 | When `toolsFor` is empty ("The GM assigns required tools for items not listed there") the plan MUST use `gmAssignedTool` as the only alternative, and with none given return `ItemCraftingNeedsGmTool` with the party not evaluated. A `gmAssignedTool` MUST be ignored when `toolsFor` is non-empty (the SRD list wins; the GM assigns only for unlisted items) and for a `CraftingBasis.itemOverride` item or a `ScrollVariant` (their tool and path are fixed, FR-025, FR-032). A `gmAssignedTool` that is absent from `tools` or is a `ToolFamily` id MUST return `ItemCraftingGmToolInvalid(toolId)` with the party not evaluated (a family is not a proficiency, FR-005). | SRD 5.2.1, "Tools" (Crafting), p. 103; equipment-rules.md FR-039 | unhappy (missing content) |
| FR-030 | A plan with no shortfall MUST be `ItemCraftingReady` holding the `CraftingRequirements` unchanged (raw materials, days, `basis`), the usable tool ids ordered by id, the worker count (1 plus helpers) and `workHours`. | SRD 5.2.1, "Crafting Nonmagical Items", p. 103 | happy |
| FR-031 | `workHours` MUST be `WorkHours(8 x days, workers)`: the time divided by the number of characters working, an exact fraction never rounded or reduced here (Plate Armor, 150 days: `WorkHours(1200, 1)` alone, `WorkHours(1200, 2)` with one helper). `workHoursPerDay` is 8 and days need not be consecutive. | SRD 5.2.1, "Time" ("Divide the time ... by the number of characters working"; "working 8 hours a day"; "needn't be consecutive"), p. 103; magic-item-rules.md FR-083 | unhappy (rule interaction) |
| FR-032 | For a `CraftingBasis.itemOverride` item (Potion of Healing) the tool MUST be the override's (Herbalism Kit) and the brewer proficient with it; the plan MUST give 25 GP of raw materials over 1 day (`WorkHours(8, 1)`). Helpers MUST be refused with `ToolShortfallHelpersNotAllowed(basis)`. | SRD 5.2.1, "Brewing Potions of Healing", p. 103; "Potion of Healing", p. 99; equipment-rules.md FR-041. **Interpretation (Q3):** the helper sentence sits under "Crafting Nonmagical Items", the potion is a magic item and the brewing text names no helper rule, so "1 day (8 hours of work)" is read as a solo task | unhappy (rule interaction) |
| FR-033 | Shortfalls MUST be ordered: tool shortfalls (FR-027), then too many helpers (FR-028), then helpers not allowed (FR-032). The blocked result lists them all; `ItemCraftingReady` exists only with none. | architecture.md section 5 | unhappy (rule interaction) |

### 4.5 Scribing a Spell Scroll

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-034 | `ScribeQualification.of(SkillProficiencies skills, ToolProficiencies tools)` MUST be `ScribeQualified` when `Skill.arcana` is proficient (Expertise implies it) **or** the tools contain `calligraphers_supplies`; either one suffices, both are not needed; otherwise `ScribeNotQualified`. Being a spellcaster ("A spellcaster can transfer a spell", p. 103) is enforced only through the prepared-spell prerequisite (FR-036): a non-caster has an empty `PreparedSpellSet`, so no day is ever accepted. `ScribingRejected(notQualified)` is carried by the `ScribeNotQualified` value handed to `begin`, not recomputed there. | SRD 5.2.1, "Prerequisites for the Scribe" ("proficiency in the Arcana skill or with Calligrapher's Supplies"), p. 103 | unhappy (rule interaction) |
| FR-035 | `ScrollScribingJob.begin({ScribeQualification, Spell spell, ScrollScribing table, CharacterLevel scribeLevel, SpellSaveDc saveDc, SpellAttackBonus attackBonus})` MUST return `ScribingBegun(job)` with `requiredDays` and `cost` from `table.forSpellLevel(spell.level)` (`equipment-rules.md` FR-049) and `daysWorked` 0, or `ScribingRejected(notQualified)` without a job. | SRD 5.2.1, "Scribing Spell Scrolls", "Time and Cost", Spell Scroll Costs, p. 103 | happy |
| FR-036 | `job.workDay({PreparedSpellSet preparedToday, bool materialsAtHand})` MUST count one day (8 hours of work) only when the spell is in `preparedToday` and the materials are at hand; otherwise it MUST return `ScribingDayRejected(reasons)` (`spellNotPrepared`, `materialsNotAtHand`, both when both apply, in that order) and the job unchanged. Earlier progress is kept and days need not be consecutive. | SRD 5.2.1, "Prerequisites for the Scribe" ("have the spell prepared on each day"; "at hand any Material components"), "Time and Cost" ("needn't be consecutive"), p. 103 | unhappy (rule interaction) |
| FR-037 | A spell with no Material component (`spell.components.material` null) MUST need no materials: `materialsAtHand` is then ignored. Whether a Component Pouch or Spellcasting Focus stands in for a material is the host's decision when it passes `materialsAtHand`; no substitution is applied here. | SRD 5.2.1, "Material (M)", pp. 105-106; content-spells.md FR-049 | unhappy (rule interaction) |
| FR-038 | The accepted day on which `daysWorked` reaches `requiredDays` MUST return `ScribingCompleted(scroll)`; earlier accepted days return `ScribingDayWorked(job)` with `daysRemaining`. A `ScribingCompleted` job called again MUST return `ScribingDayRejected` with `alreadyCompleted`. | SRD 5.2.1, "Time and Cost" ("If a scroll requires multiple days"), p. 103 | unhappy (boundary) |
| FR-039 | Material components MUST be consumed only on completion: `ScribingDayWorked` carries no consumption, and `ScribedScroll.materialsConsumed` MUST equal `spell.components.material.consumesMaterial` (false when the spell has no material). | SRD 5.2.1, "Prerequisites for the Scribe" ("consumed only when you complete the scroll"), p. 103; content-spells.md FR-044 | unhappy (rule interaction) |
| FR-040 | `ScribedScroll` MUST hold the spell id, spell level, `saveDc` and `attackBonus` given to `begin` (the scroll's spell "uses your spell save DC and spell attack bonus"), and `casterLevel` equal to `scribeLevel` for a cantrip and null otherwise. **Interpretation:** the p. 99 values (save DC 13, attack bonus +5) are the default of a found Spell Scroll; a scribed scroll carries its scribe's snapshot per p. 103. Using the scroll is out of scope (section 1); no spec reads these fields yet. | SRD 5.2.1, "Prerequisites for the Scribe", "Cantrips", p. 103; "Spell Scroll", p. 99 | unhappy (rule interaction) |
| FR-041 | Scribing MUST be solo: `begin` takes one scribe and no helpers. **Interpretation:** the helper rule sits under "Crafting Nonmagical Items", a Spell Scroll is a magic item (p. 99), and every scribing prerequisite is stated for "you". | SRD 5.2.1, "Time" (helpers), "Scribing Spell Scrolls", p. 103; "Spell Scroll", p. 99 | happy |
| FR-042 | `PreparedSpellSet.fromSpellcasting(Iterable<ClassSpellcasting>)` MUST be the union, per class, of the ids in `PreparedSpells` (ordered and always-prepared, spellcasting.md FR-045), `CantripsKnown` including those chosen under `extraCantrips` (FR-052, FR-096) and the `GrantedCantrip` ids (FR-097), deduplicated and unmodifiable. A Wizard's `Spellbook` spells are not prepared and are not included unless prepared. **Interpretation:** a known cantrip counts as prepared, since it is available every day. An empty input gives an empty set. | SRD 5.2.1, "Prerequisites for the Scribe" ("have the spell prepared"), p. 103; spellcasting.md section 5, FR-045, FR-050, FR-052, FR-096, FR-097 | unhappy (empty and minimal) |
| FR-043 | The `ScrollScribingJob` constructor MUST throw `ArgumentError` for `requiredDays` below 1, `daysWorked` negative or above `requiredDays`; `begin` and `workDay` return results for all rule outcomes. Jobs and scrolls are immutable value objects. | architecture.md section 6; testing.md section 4 | unhappy (invalid input) |

### 4.6 Placement, purity and API

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-044 | Every type here MUST live under `lib/src/character/domain/tools/`, be synchronous and deterministic, and import no `dart:io`, `dart:async`, `application/`, `adapters/` or `shared_ports/`; no `Future`, `Stream`, `async`, `Random`, `DateTime.now` or `Stopwatch`. | architecture.md sections 3, 9 | happy |
| FR-045 | Package imports MUST be `shared_kernel`, `d20_test` and `content` barrels and the `character` specs listed in the header; no `combat`, `toolbox` or non-upstream context. | architecture.md sections 1, 2, 9; shared-types-and-ownership.md FR-013, FR-016 | happy |
| FR-046 | This code MUST contain no `Logger`, `Tracer`, `Meter` or signal constant. | observability.md section 3 | happy |
| FR-047 | The types of section 6 MUST be exported from `lib/src/character/character.dart` and `lib/srd5e.dart`, each member documented, each name exported once with no generic name (`Applied`, `Rejected`, `Found`), and no exported signature carrying a JSON key or `Map<String, dynamic>`. | architecture.md sections 2, 5, 7; shared-types-and-ownership.md FR-017 | happy |
| FR-048 | Every list in a result (`utilize`, usable tools, shortfalls, reasons, helpers) MUST be unmodifiable; mutation throws `UnsupportedError` and the next read is unchanged. | architecture.md section 4 | unhappy (immutability) |
| FR-049 | No use case MAY be called from this code, and a use case MUST call these static functions directly with content loaded through its own `ContentSource` (shared-types-and-ownership.md FR-044). This spec defines no use case, port or double. | shared-types-and-ownership.md FR-044; architecture-guardrails.md FR-097 | happy |
| FR-050 | Nothing in the code, tests or data of this spec MAY name a consuming project. | AGENTS.md ("Hard constraints") | happy |
| FR-051 | With only `package:srd5e/srd5e.dart` and `package:srd5e/adapters.dart`, a consumer MUST load the bundled equipment, resolve Thieves' Tools, evaluate a check with and without proficiency, and plan Plate Armor with a proficient crafter and helper (`WorkHours(1200, 2)`). Phase 5 data; the maths is phase 3 on synthetic entries. | architecture.md section 7; testing.md section 3; SRD 5.2.1, pp. 93, 103 | happy |

### Cases: tool facts (FR-004 to FR-006, FR-018 to FR-022; pp. 93-94)

Entry: tool: Ability; Utilize (description, DC). A variant's facts are its family's.

| Group | Entries | Path |
|---|---|---|
| standalone | Thieves' Tools: Dexterity; pick a lock 15, disarm a trap 15<br>Herbalism Kit: Intelligence; identify a plant 10<br>Carpenter's Tools: Strength; seal or pry open 20<br>Smith's Tools: Strength; pry open 20<br>Tinker's Tools: Dexterity; assemble a Tiny item 20 | happy |
| several actions | Cook's Utensils: Wisdom; improve flavor 10, detect spoiled or poisoned food 15<br>Forgery Kit: Dexterity; mimic handwriting 15, duplicate a wax seal 20 | happy |
| variant | `gaming_set_dice`: Wisdom; discern cheating 10, win the game 20; `proficiencyId` `gaming_set_dice`<br>`musical_instrument_lute`: Charisma; play a known tune 10, improvise a song 15 | unhappy (rule interaction) |
| family and missing | `gaming_set` alone: `ToolFamilyNeedsVariant`<br>`gaming_set_dice` with an empty catalogue: `ToolFamilyMissing` | unhappy (missing content) |
| not listed | Thieves' Tools with an action "Forge a key": `ToolUtilizeActionNotListed` | unhappy (missing content) |
| bad catalogue | `variantOf` names another variant or a standalone tool: `ToolFamilyMissing`<br>two families with id `gaming_set`: `ToolFamilyMissing`, same for either catalogue order | unhappy (missing content) |
| mismatch | `check` with Herbalism Kit's action and benefits evaluated for Thieves' Tools: `ToolUtilizeBenefitsMismatch` | unhappy (contradictory data) |

### Cases: check benefits (FR-007 to FR-016; Proficiency Bonus +2, Herbalism Kit, Intelligence modifier +3)

Entry: tool proficient / skill used (proficient, Expertise) : multiple; circumstances. [A] is one `Advantage`.

| Group | Entries | Path |
|---|---|---|
| tool | yes / none: 1; [] | happy |
| none | no / none: 0; [] and `usesProficiency` false<br>no / Nature (not proficient): 0; [] | unhappy (boundary) |
| both | yes / Nature (proficient): 1; [A] (modifiers A+3 P+2 only)<br>yes / Nature (Expertise): 2; [A] (P+4) | unhappy (rule interaction) |
| skill only | no / Nature (proficient): 1; []; `toolProficient` false<br>no / Nature (Expertise): 2; [] | unhappy (rule interaction) |
| other skill | yes / Nature (not proficient) while Expertise held in Arcana: 1; []<br>yes / none while proficient in Nature: 1; [] | unhappy (rule interaction) |
| ability | override Strength on Thieves' Tools: `ability` Strength, multiple and circumstances unchanged | unhappy (rule interaction) |
| with Disadvantage | yes / Nature (proficient), Poisoned: `RollMode.resolve([A, Disadvantage])` is `normal` | unhappy (rule interaction) |
| separate variants | proficient `gaming_set_dice`, check with `gaming_set_playing_cards`: 0<br>proficient `gaming_set`, check with `gaming_set_dice`: 0 | unhappy (rule interaction) |
| monster | `ofMonster({thieves_tools})`, check with Thieves' Tools: 1 | happy |

### Cases: crafting plans (FR-024 to FR-033; p. 103). `smith` = `smiths_tools`.

Entry: item; party (crafter / helpers: proficiencies); allowance: result.

| Group | Entries | Path |
|---|---|---|
| solo | Plate Armor (1,500 GP); crafter `smith`: Ready; 750 GP; 150 days; `smiths_tools`; `WorkHours(1200, 1)` | happy |
| helper | Plate Armor; crafter `smith` / helper `smith`: Ready; workers 2; `WorkHours(1200, 2)`<br>Heavy Crossbow (50 GP); crafter and helper `woodcarvers_tools`: Ready; 5 days; `WorkHours(40, 2)` | unhappy (rule interaction) |
| helper lacks | Plate Armor; `smith` / helper none: `ToolShortfallWorker(helper)`<br>Plate Armor; none / none: crafter shortfall then helper shortfall | unhappy (invalid input) |
| shared tool | Club; crafter `carpenters_tools` / helper `woodcarvers_tools`: `ToolShortfallNoSharedTool`<br>Club; crafter both tools / helper `woodcarvers_tools`: Ready; usable `woodcarvers_tools` | unhappy (rule interaction) |
| helper cap | Plate Armor; `smith` / two helpers `smith`, standard: `ToolShortfallTooManyHelpers(2, 1)`<br>same, `gmAllows(2)`: Ready; `WorkHours(1200, 3)` | unhappy (boundary) |
| Potion of Healing | crafter `herbalism_kit`: Ready; 25 GP; 1 day; `WorkHours(8, 1)`; `itemOverride`<br>crafter and one helper `herbalism_kit`: `ToolShortfallHelpersNotAllowed`<br>crafter without it: `ToolShortfallWorker(crafter)` | unhappy (rule interaction) |
| GM tool | Shield (no tools), no `gmAssignedTool`: `ItemCraftingNeedsGmTool`<br>Shield, `gmAssignedTool` `smiths_tools`, crafter `smith`: Ready; usable `smiths_tools`<br>Shield, `gmAssignedTool` `gaming_set` (family) or an id not in `tools`: `ItemCraftingGmToolInvalid`<br>Plate Armor with `gmAssignedTool` `woodcarvers_tools`, crafter `smith`: Ready; usable `smiths_tools` (ignored)<br>Potion of Healing or a Spell Scroll with `gmAssignedTool`: override tool kept; `ItemCraftingUseScribing` | unhappy (missing content) |
| pass-through | Horse, Draft: `ItemCraftingNotCraftable(notAnItem)`; party not read<br>Spell Scroll (Level 1): `ItemCraftingUseScribing` | unhappy (rule interaction) |
| all at once | Plate Armor; none / two helpers none, standard: `ToolShortfallWorker` for the crafter, helper 1 and helper 2 in that order, then `ToolShortfallTooManyHelpers(2, 1)` | unhappy (rule interaction) |
| duplicate ids | crafter and helper the same `CharacterId`: `ArgumentError` | unhappy (invalid input) |

### Cases: scribing (FR-034 to FR-043; Spell Scroll Costs, p. 103)

Entry: scribe; spell; days: results.

| Group | Entries | Path |
|---|---|---|
| qualification | Arcana only: qualified<br>Calligrapher's Supplies only: qualified<br>both: qualified<br>neither: `ScribeNotQualified`, no job<br>Arcana Expertise: qualified | unhappy (rule interaction) |
| one day | level 1 spell, prepared, no material: begin 1 day, 25 GP; day 1 `ScribingCompleted` | happy |
| multi-day | level 3, 5 days, 150 GP: days 1 to 4 `ScribingDayWorked` (remaining 4, 3, 2, 1); day 5 `ScribingCompleted` | unhappy (boundary) |
| not prepared | level 3 on day 3 not prepared: `ScribingDayRejected([spellNotPrepared])`, job equal to before; next day prepared counts as day 3 | unhappy (rule interaction) |
| materials | spell with a material, not at hand: `[materialsNotAtHand]`; not prepared and not at hand: both, in order; no material and `false`: accepted | unhappy (rule interaction) |
| consumption | Revivify (M, consumed), level 3: intermediate days no consumption; `ScribedScroll.materialsConsumed` true on the fifth day<br>Fire Bolt (cantrip, no material): false | unhappy (rule interaction) |
| cantrip | Fire Bolt, scribe level 5: `casterLevel` 5; level 1 spell: null | unhappy (rule interaction) |
| snapshot | save DC 13 and attack bonus +5 at `begin`: the scroll holds 13 and +5 | happy |
| completed | `workDay` on a completed job: `ScribingDayRejected(alreadyCompleted)` | unhappy (state error) |
| prepared set | prepared `{shield}` plus cantrip `{fire_bolt}`: contains both; empty classes: empty set<br>`extraCantrips` cantrip and a `GrantedCantrip`: contained<br>Wizard spell in the spellbook but not prepared: not contained | unhappy (empty and minimal) |
| non-caster | qualified by Arcana, empty `PreparedSpellSet`: `workDay` gives `ScribingDayRejected([spellNotPrepared])` | unhappy (rule interaction) |
| invalid job | `requiredDays` 0, `daysWorked` -1, `daysWorked` above required: `ArgumentError` | unhappy (invalid input) |

## 5. Model

Immutable value objects (`@immutable`, `final`), pure services, no aggregate, entity or event:

- `ToolProficiencies`; `ResolvedTool`; `ToolResolution` (sealed: `ToolResolved`, `ToolFamilyNeedsVariant`, `ToolFamilyMissing`); `ToolCheckBenefits` (`toolProficient`, `proficiencyBonusMultiple` 0 to 2, `usesProficiency`, `ability`, `circumstances`, `rollModifiers`); `ToolUtilizeDc` / `ToolUtilizeActionNotListed` (sealed `ToolUtilizeDcResult`); `ToolUtilizeCheck` / `ToolUtilizeBenefitsMismatch` (sealed `ToolUtilizeCheckResult`, with `ToolUtilizeActionNotListed`); `ToolCheckBenefits` also exposes `proficiencyId`.
- `CraftingWorker`, `CraftingParty`; `ItemCraftingPlan` (sealed: `ItemCraftingReady`, `ItemCraftingBlocked(shortfalls)`, `ItemCraftingNotCraftable`, `ItemCraftingUseScribing`, `ItemCraftingNeedsGmTool`, `ItemCraftingGmToolInvalid`); `ToolCraftingShortfall` (sealed: `ToolShortfallWorker`, `ToolShortfallNoSharedTool`, `ToolShortfallTooManyHelpers`, `ToolShortfallHelpersNotAllowed`).
- `ScribeQualification` (sealed: `ScribeQualified`, `ScribeNotQualified`), `ScrollScribingJob`, `ScribingBegun` / `ScribingRejected` (sealed `ScribingBeginResult`), `ScribingDayWorked` / `ScribingCompleted(ScribedScroll)` / `ScribingDayRejected(reasons)` (sealed `ScribingDayOutcome`), `ScribedScroll`, `PreparedSpellSet`.
- Domain services (abstract final, static): `ToolRules`, `ToolUtilize`, `ItemCraftingPlanner`. Shortfall reasons are enum values inside value objects so barrel names never collide (`magic-item-rules.md` owns `MagicItemCraftingShortfall`; prefixes differ).

Invariants: duplicate worker ids and malformed jobs throw `ArgumentError` at construction (FR-023, FR-043); every rule outcome (missing family, no shared tool, not prepared, unlisted action) is a returned value (architecture.md section 6). The aggregate stores no proficiency; the host holds `ToolProficiencies` and `SkillProficiencies` and passes them in.

## 6. Interface

```dart
// lib/src/character/domain/tools/ (indicative signatures)
abstract final class ToolRules {
  static ToolResolution resolve(Tool tool, Iterable<Tool> catalogue);                    // FR-004..FR-006
}
final class ToolCheckBenefits {
  static ToolCheckBenefits evaluate({required ResolvedTool tool, required ToolProficiencies tools,
      required SkillProficiencies skills, Skill? skillUsed, Ability? ability});          // FR-007..FR-017
  List<RollCircumstance> get circumstances;  // [] or [Advantage()], unmodifiable
  RollModifiers rollModifiers(AbilityModifier modifier, ProficiencyBonus bonus, {Iterable<Modifier> others = const []});
}
abstract final class ToolUtilize {                                                       // FR-018..FR-021
  static List<ToolUtilizeAction> actions(ResolvedTool tool);
  static ToolUtilizeDcResult dcFor(ResolvedTool tool, ToolUtilizeAction action);
  static ToolUtilizeCheckResult check(ResolvedTool tool, ToolUtilizeAction action, ToolCheckBenefits benefits);
}
abstract final class ItemCraftingPlanner {                                               // FR-024..FR-033
  static ItemCraftingPlan plan({required EquipmentEntry item, required Iterable<Tool> tools,
      ScrollScribing? scribing, required CraftingParty party,
      AssistantAllowance allowance = AssistantAllowance.standard, ItemId? gmAssignedTool});
}
final class ScrollScribingJob {                                                          // FR-034..FR-043
  static ScribingBeginResult begin({required ScribeQualification qualification, required Spell spell,
      required ScrollScribing table, required CharacterLevel scribeLevel,
      required SpellSaveDc saveDc, required SpellAttackBonus attackBonus});
  ScribingDayOutcome workDay({required PreparedSpellSet preparedToday, required bool materialsAtHand});
}
```

- **Sync, not async:** pure computation on loaded values; loading is the `ContentSource` port's concern (architecture.md section 4). No port, no failure contract of its own.
- **Exports** (FR-047): every type of section 5 and the three services, from `lib/src/character/character.dart` and `lib/srd5e.dart`. `lib/adapters.dart` and `lib/testing.dart` gain nothing.
- **Name stewardship:** these names are defined only here; `Crafting*` names of `equipment-rules.md` and `MagicItemCrafting*` names of `magic-item-rules.md` are used, not redefined.

## 7. Observability

**Silent by design** (`doc/rules/observability.md` section 3): every type is domain code with no collaborator, port or use case, so nothing is emitted and `observability-ports.md` is not a dependency. The seven evaluation questions: (1) what can go wrong: a missing family entry, an unlisted action, a benefits mismatch, an invalid GM tool, an unqualified scribe, no shared tool (all returned values); programmer errors (`ArgumentError`). (2) How an operator knows: the consuming use case records its own outcome; the result type names the cause. (3) Diagnosis: shortfall values carry worker ids, tool ids and reasons. (4) Nothing to count or time; `doc/observability/signals.md` gets no entry. (5) Existing instrumentation: unchanged. (6) Nothing to monitor here; a use case that wraps these functions adds its operation to the context signals by amendment. (7) Nothing is noisy: no log or signal is emitted.

## 8. Test plan

Unit tests in `test/character/domain/tools/`, synthetic `Tool`, `Armor` and `Spell` entries built directly plus `FakeContentSource`-free values; one scenario through the public API once data ships. No double, contract suite or `Observability`.

| Id | Level | Notes |
|---|---|---|
| FR-001 to FR-003 | unit | Copy, order independence, `UnsupportedError`, equality and hash; variant versus family rows; monster |
| FR-004 to FR-006, FR-018 to FR-021 | unit | "Cases: tool facts": standalone, variant inheritance, family and missing family (no throw), several actions, unlisted action, `check` fields |
| FR-007 to FR-017 | unit | "Cases: check benefits" table-driven; `rollModifiers` slots (no PB slot at multiple 0, `P+4` at 2); `RollMode.resolve` with `Advantage` alone and with a `Disadvantage`; inputs compared before and after |
| FR-022, FR-051 | scenario | Over bundled equipment (phase 5): all tools' Ability and Utilize golden rows; public-API-only flow for Thieves' Tools and Plate Armor |
| FR-023 to FR-033 | unit | "Cases: crafting plans"; recording nothing; duplicate ids `ArgumentError`; ordering of shortfalls; `requirementsFor` not recomputed (a synthetic `CraftingRequirements` with odd values passes through unchanged) |
| FR-034 to FR-043 | unit | "Cases: scribing": per-day state machine over a synthetic `ScrollScribing` table, unchanged job on rejection, completion boundary, consumption flag, cantrip level, snapshot, completed job, invalid constructors, prepared set |
| FR-044 to FR-050 | architecture | Import and purity scan of `domain/tools/`; no signal types; barrel scan (documented, unique names, no generic names); no mention of another use case; consumer-name scan |
| FR-048 | unit | Mutation of every returned list throws and next read is equal |

- **Mutation testing** (`doc/rules/testing.md` section 8): changed lines in `lib/src/character/domain/tools/`, score at least 80. Boundary mutants: multiple 0, 1 and 2; helper count at the cap (1, 2); `daysWorked` at `requiredDays` minus 1, equal; Arcana versus Calligrapher's `||`; the `Advantage` only with both proficiencies; the Expertise-in-another-skill case.
- **Deliberately not covered:** the GM's choice of tool or ability; raw-material availability; scroll use (`magic-item-rules.md`).

## 9. Open questions and decisions

No question is open and none is escalated. Settled, one line each (web material informed judgement only; every decision rests on SRD text or package design):
- **Q1** (interpretation) The Proficiency Bonus is added once and doubled by skill Expertise only; the SRD limits Expertise to skills, so a tool never doubles (FR-011; pp. 8, 182).
- **Q2** (interpretation) A skill-only proficiency still adds the bonus on a tool check, because the check "uses" the skill (p. 8, Skill Proficiencies; p. 9, Equipment Proficiencies: "benefit from both"); the p. 8 Deception or Persuasion example only shows the bonus not stacking; only Advantage needs both (FR-009, FR-010).
- **Q3** (interpretation) Helpers are allowed for nonmagical crafting only (the p. 103 brewing section has no helper rule; the refusal is not SRD text). The Potion of Healing and scribing text speak of one character ("a character who has proficiency", "you"), and the helper sentence sits under "Crafting Nonmagical Items" (FR-032, FR-041). A table that allows helpers there changes the host's input, not this engine.
- **Q4** (interpretation) A known cantrip counts as prepared for scribing (FR-042); a day without the spell prepared or the materials at hand does not count but loses no progress (FR-036); materials are checked every worked day and consumed once at completion (FR-039).
- **Q5** Fractional assisted time is an exact `WorkHours`, never rounded, as in `magic-item-rules.md` FR-083 (the SRD is silent); `Crafting.days` stays an `int` (`equipment-rules.md` Q13).
- **Q6** The scribe's spell save DC and attack bonus are snapshotted at `begin`, because the SRD says the scroll "uses your" values (p. 103); p. 99's 13 and +5 are the default of a found scroll. Scroll use is owned by no spec yet (out of scope, section 1); a future owner reads `ScribedScroll.saveDc` / `attackBonus` for scribed scrolls.
- **Q7** The Game Master's assigned tool is an input (FR-029), not guessed; the family of a tool is resolved from the caller's catalogue, not looked up through a port (FR-004).

## 10. Changelog impact

`CHANGELOG.md`, Unreleased, Added: tool proficiency and Utilize DCs (`ToolProficiencies`, `ToolRules`, `ToolCheckBenefits`, `ToolUtilize`), crafting prerequisites (`ItemCraftingPlanner`, `CraftingParty`) and Spell Scroll scribing (`ScrollScribingJob`, `ScribeQualification`, `PreparedSpellSet`). **Not BREAKING**: it only adds exports.
