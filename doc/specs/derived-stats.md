# Derived stats

| | |
|---|---|
| Status | draft |
| Context | `character` |
| Roadmap phase | 3 |
| Depends on | `ability-scores.md`, `modifiers-and-advantage.md`, `d20-tests.md`, `content-source-port.md`, `content-schema-and-decoder.md`, `content-classes.md`, `content-equipment.md`, `equipment-rules.md`, `errors-and-results.md`, `observability-ports.md` |

The header lists specs only (`shared-types-and-ownership.md` FR-056); the types
each supplies are listed in section 5. `HitPointDie` is `content-schema-and-decoder.md`
FR-132 (decisions FR-053); `ArmorClassRule` is `content-equipment.md` FR-093.

`equipment-rules.md` (rank 9) supplies `ArmorRules.baseArmorClass`, `ArmorBase`
(its FR-001 to FR-005), `ArmorTrainingRules` and `ArmorTrainingEffects` (its FR-071,
FR-072), which the use case calls.

## 1. Purpose and scope

This spec is the `character` context's foundation. It owns the value types every
other `character` spec builds on (`shared-types-and-ownership.md` FR-008):
`CharacterLevel`, `ClassLevels`, `ProficiencyBonus`, `HitPointMaximum`,
`HitDicePool` and `HitPointGain` (keyed by the `content`-owned `HitPointDie`). It
also computes the numbers a character sheet records: the Hit Point maximum including
bonuses, Armor Class, saving throw and skill modifiers, and Passive Perception, each
returned with the typed terms that produced it.

The domain holds the rule maths as pure functions over value objects. One use case,
`CalculateDerivedStats`, resolves the initial class and any worn armor and Shield
through `ContentSource`. It takes plain values (`ClassLevels`, `AbilityScores`, the
stored `HitPointMaximum`, `HitDicePool`), never a `Character`: the aggregate is
downstream (`shared-types-and-ownership.md` FR-013, FR-016). **`LevelHistory` does not
exist.** The stored maximum is the single source of truth; bonuses are added at read
time (FR-050) and never stored.

**Out of scope:**

- XP, level from XP, the level-up use case, applying a Hit Point gain, the
  Constitution modifier change rule: `character-aggregate.md`,
  `level-advancement-and-multiclassing.md`. Ability score generation and Ability Score
  Improvement (p. 21): `character-creation.md`.
- Current and Temporary Hit Points, damage, healing, Death Saving Throws: `combat`
  (except `isBloodied`, FR-071, `shared-types-and-ownership.md` FR-049). Spending Hit
  Dice and rests: `rests-and-hit-dice.md`.
- Initiative, weapon attack bonuses, weapon proficiency: `attacks.md`; spell save DC,
  attack bonus, slots: `spellcasting.md`; Cover's AC bonus (p. 15): `attacks.md`;
  Conditions and Exhaustion (p. 181): `conditions.md`.
- Speed penalty, Strength requirement, Stealth Disadvantage (p. 92) and the base-armor
  arithmetic: `equipment-rules.md` (`shared-types-and-ownership.md` FR-048), including
  the untrained-armor rule (FR-071 to FR-078 there). The armor Speed penalty is applied
  to a Speed by `movement-lifting-and-flight.md`. This spec reports the training gaps
  (FR-039) and exposes the untrained-armor and Stealth Disadvantages as roll
  circumstances (FR-077, FR-078).
- Tool proficiency (p. 9, p. 93): `tool-proficiency-and-crafting.md`. Monster Proficiency Bonus (p. 8):
  `content`. Passive scores other than Passive Perception (p. 22, p. 186).
- Class features and species traits that grant AC bases or Hit Point bonuses are
  content; this spec defines the general mechanisms (FR-036, FR-029, FR-051).
- Nothing core to these rules was found missing from SRD 5.2.1.

## 2. Source

The PDF's page index equals the printed page numbers. SRD 5.2.1: "D20 Tests", "Saving
Throws", "Armor Class" (pp. 6-7); "Proficiency", "Skills" (pp. 8-9); "Create Your
Character" ("Note Armor Training", "Fill In Numbers", pp. 19, 22); "Level Advancement",
"Gaining a Level" (p. 23); "Multiclassing" (pp. 24-25; the optional "Bonus Feats at
Level 20" rule is a GM option, not used); Barbarian, Monk, Sorcerer traits (pp. 28-29,
50, 69); "Dwarf" (p. 84); "Armor" (p. 92); Rules Glossary (pp. 177, 182, 186). Rule
files: `doc/rules/`.

## 3. Vocabulary

| SRD term | Type | Notes |
|---|---|---|
| Level | `CharacterLevel` (FR-057) | 1 to 20; total level is the sum of `ClassLevels`. |
| Class levels | `ClassLevels` (FR-058) | Ordered; first entry is the initial class. |
| Proficiency Bonus | `ProficiencyBonus` (FR-059) | From total level (p. 23, p. 25). |
| Hit Point maximum | `HitPointMaximum` (FR-060) | The stored base; the result adds bonuses (FR-050). |
| Hit Point Die | `HitPointDie` (`content`) | Not defined here. |
| Hit Point Dice | `HitDicePool` (FR-061, FR-070, FR-073) | Pooled by die (p. 25); dice a character has, not those spent. |
| Hit Point gain | `HitPointGain` (FR-062) | Rolled or fixed; minimum 1 (p. 23). |
| Hit Point bonus feature | `HitPointMaximumBonus` | Flat plus per-level amount (FR-051). |
| Armor Class | `ArmorClass` (`d20_test`) | Published by `d20_test`; computed here. |
| Base AC | sealed `ArmorClassBasis` (command input) | `StandardArmorClassBasis`, `ArmoredArmorClassBasis`, `AbilityBasedArmorClassBasis` (p. 7, p. 177). |
| Armor | `Armor`, `ArmorCategory`, `ArmorClassRule` (`content`) | Light, Medium, Heavy, Shield; rule data is `BaseRule` or `BonusRule` (`content-equipment.md` FR-093). |
| Bloodied | `isBloodied` (FR-071) | Pure predicate (p. 177). |
| Armor slot | enum `ArmorSlot`: `bodyArmor`, `shield` | The slot a command id fills (FR-053). |
| Armor Training | `ArmorTraining` | Set of `ArmorCategory` (p. 92, p. 177); rules in `equipment-rules.md`. |
| Saving throw / proficiency | `SavingThrowModifier`, `SavingThrowProficiencies` | p. 7; set of `Ability`: the initial class plus class-feature grants (FR-049). |
| Skill, proficiency, Expertise | `Skill` (`content`), `SkillModifier`, `SkillProficiencies` | 18 skills (p. 9); Expertise doubles the bonus (p. 182). |
| Passive Perception | `PassivePerception` | p. 22, p. 186. |

## 4. Requirements

Stable ids. Never renumber; new requirements get new ids. Withdrawn ids are
listed once at the end of this section.

### 4.1 Level and class levels

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-057 | `CharacterLevel` MUST hold an integer from 1 to 20 inclusive. `CharacterLevel.tryCreate` is a scalar factory (errors-and-results.md FR-035) returning the sealed `CharacterLevelParse`: `ValidCharacterLevel(level)` or `InvalidCharacterLevel(value, reason)` with `reason` the enum `CharacterLevelRejection` (`belowMinimum`, `aboveMaximum`). It MUST NOT throw, and MUST return `InvalidCharacterLevel` if and only if the constructor throws. The constructor MUST throw `ArgumentError` for a value outside 1 to 20 (errors-and-results.md FR-026). | SRD 5.2.1, "Level Advancement", Character Advancement table, p. 23 | happy / unhappy (boundary) |
| FR-058 | `ClassLevels` MUST be an ordered, unmodifiable sequence of (`ClassId`, level) entries, each level at least 1, no class repeated, at least one entry, total at most 20. The first entry MUST be the initial class. `totalLevel` MUST be the sum and a valid `CharacterLevel`. `ClassLevels.tryCreate` is an aggregate parser (errors-and-results.md FR-023) returning the sealed `ClassLevelsParse`: `ValidClassLevels(levels)` or `InvalidClassLevels(problems)`. `problems` lists **every** violated invariant, each `ClassLevelsProblem` (enum: `empty`, `levelBelowMinimum`, `duplicateClass`, `totalAboveMaximum`) at most once, in enum order. It MUST NOT throw, and MUST return `InvalidClassLevels` if and only if the constructor throws `ArgumentError`. | SRD 5.2.1, "Multiclassing" ("Experience Points", "Proficiencies"), p. 25; "Level Advancement", p. 23 | happy / unhappy (invalid input) |
| FR-072 | `ClassLevels.withLevelIn(ClassId)` MUST return a new `ClassLevels` and leave the receiver unchanged. A held class is raised by 1 and every entry keeps its position; a class not held is appended last at level 1. The first entry is unchanged. It MUST throw `ArgumentError` when the new total would exceed 20 (the caller checks the cap), so the result satisfies FR-058. A host convenience: `character-aggregate.md` builds through the constructors (its D-20) and is not required to adopt it (section 9). | SRD 5.2.1, "Multiclassing", p. 24-25; "Level Advancement", p. 23 | happy / unhappy (boundary) |

Cases (FR-057, FR-058):

| Label | Input | Expected | Path |
|---|---|---|---|
| level 0 / 21 | `CharacterLevel` 0 / 21 | `belowMinimum` / `aboveMaximum` | unhappy (boundary) |
| empty | no entries | `empty` | unhappy (empty and minimal) |
| class repeated | 2 Fighter, 1 Rogue, 1 Fighter | `duplicateClass` | unhappy (invalid input) |
| total 20 / 21 | 10 Fighter, 10 Rogue / 11 Fighter, 10 Rogue | valid / `totalAboveMaximum` | unhappy (boundary) |
| several problems | 0 Fighter, 1 Fighter, 20 Rogue | exactly `[levelBelowMinimum, duplicateClass, totalAboveMaximum]` | unhappy (invalid input) |

Cases (FR-072):

| Label | Receiver, argument | Expected | Path |
|---|---|---|---|
| new class appended last | 3 Fighter, add Rogue | 3 Fighter, 1 Rogue; total 4; initial Fighter | happy |
| held class raised | 3 Fighter, 2 Rogue, add Rogue | 3 Fighter, 3 Rogue; positions kept | happy |
| initial class stays first | 2 Rogue, 3 Fighter, add Fighter | 2 Rogue, 4 Fighter; initial Rogue | unhappy (rule interaction) |
| total 20 plus one, held class | 10 Fighter, 10 Rogue, add Fighter | `ArgumentError` | unhappy (boundary) |
| receiver unchanged / result unmodifiable | 3 Fighter, add Rogue | receiver still 3 Fighter; mutating the result's entries throws | unhappy (immutability) |

### 4.2 Proficiency Bonus

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-009 | The `proficiencyBonus` in the result MUST be `ProficiencyBonus.forLevel` (FR-059) of the total level (the sum of the `ClassLevels`), not of the level in any one class. | SRD 5.2.1, "Multiclassing" ("Proficiency Bonus"), p. 25 | unhappy (rule interaction) |
| FR-010 | A Proficiency Bonus MUST appear at most once in the breakdown of any one modifier, as one term whose source is `proficiencyBonus` or, for Expertise, `expertise` (the doubled bonus is one term). The `ModifierBreakdown` constructor throws `ArgumentError` for a second such term (FR-067). | SRD 5.2.1, "The Bonus Doesn't Stack", p. 8 | unhappy (rule interaction) |
| FR-059 | `ProficiencyBonus` MUST be a value object whose `forLevel(CharacterLevel)` returns +2 for levels 1 to 4, +3 for 5 to 8, +4 for 9 to 12, +5 for 13 to 16 and +6 for 17 to 20. It exposes `int get value` (2 to 6), which callers convert to a kernel `Modifier(proficiencyBonus.value)` (`attacks.md` FR-124). | SRD 5.2.1, "Level Advancement", p. 23; "Proficiency", p. 8 | happy / unhappy (boundary) |

Cases (FR-059, FR-009). Source p. 8 for band rows, p. 25 for multiclass rows.

| Label | Level | Bonus | Path |
|---|---|---|---|
| band edges | 1, 4 / 5, 8 / 9, 12 / 13, 16 / 17, 20 | +2 / +3 / +4 / +5 / +6 | unhappy (boundary) |
| multiclass 3 Fighter / 2 Rogue | total 5 | +3 | unhappy (rule interaction) |
| `value` | `forLevel` of 1 / 20 | `value` 2 / 6 | unhappy (boundary) |

### 4.3 Skills

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-012 | The result MUST contain exactly one modifier for each of the 18 skills, whatever the proficiencies. | SRD 5.2.1, "Skill List", p. 9 | unhappy (empty and minimal) |
| FR-013 | A proficient skill modifier MUST be the ability modifier plus the Proficiency Bonus. | SRD 5.2.1, "Skill Proficiencies", p. 8; "Fill In Numbers", p. 22; Rules Glossary, "Proficiency", p. 186 | happy |
| FR-014 | A skill without proficiency MUST have a modifier equal to the ability modifier only (it can be negative). | SRD 5.2.1, "Skill Proficiencies", p. 8-9 | unhappy (rule interaction) |
| FR-015 | A skill with Expertise MUST have a modifier equal to the ability modifier plus twice the Proficiency Bonus. | SRD 5.2.1, "Expertise", p. 182 | happy |
| FR-016 | `SkillProficiencies.tryCreate` is an aggregate parser (errors-and-results.md FR-023) returning the sealed `SkillProficienciesParse`: `ValidSkillProficiencies(proficiencies)` or `InvalidSkillProficiencies(expertiseWithoutProficiency)`, the latter holding **every** skill named in `expertise` that is not in `proficient` (a non-empty `Set<Skill>`). The constructor MUST throw `ArgumentError` in exactly the same cases; `tryCreate` MUST NOT throw. | SRD 5.2.1, "Expertise", p. 182 ("in one skill in which you have proficiency") | unhappy (invalid input) |

Skill modifier cases (FR-013 to FR-015), source p. 8-9, p. 182:

| Label | Ability modifier | Proficiency Bonus | Training | Expected | Path |
|---|---|---|---|---|---|
| proficient | +3 (Athletics) | +2 | proficient | +5 | happy |
| not proficient | +3 | +2 | none | +3 | unhappy (rule interaction) |
| Expertise at level 1 | +3 | +2 | Expertise | +7 | happy |

### 4.4 Saving throws

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-017 | A saving throw modifier MUST be the ability modifier, plus the Proficiency Bonus if the character has proficiency in that save. | SRD 5.2.1, "Saving Throws", p. 7; "Saving Throw Proficiencies", p. 9; "Fill In Numbers", p. 22 | happy / unhappy (rule interaction) |
| FR-018 | The result MUST contain exactly one modifier for each of the six abilities. | SRD 5.2.1, "The Six Abilities", p. 5 | unhappy (empty and minimal) |
| FR-019 | Classes after the first entry of `ClassLevels` MUST NOT add saving throw proficiencies through their multiclass entry traits. The only other source is a class-feature grant, `additionalSavingThrows` (FR-049). | SRD 5.2.1, "Multiclassing" ("Proficiencies"), p. 25; "Barbarian", "As a Multiclass Character", p. 28 | unhappy (rule interaction) |
| FR-049 | The saving throw proficiencies MUST be the `savingThrowProficiencies` of the `ClassDefinition` (`content-classes.md`) of the initial class, the first entry of `ClassLevels` (FR-058), unioned with the command's optional `additionalSavingThrows` (`Set<Ability>`, default empty): saves that class features grant, which the host derives from class and level (Slippery Mind, `class-rogue.md` FR-080). Nothing else adds a save; the union holds no feature names. | SRD 5.2.1, "Saving Throw Proficiencies", p. 9; "Multiclassing", "Proficiencies", p. 25; "Rogue", "Level 15: Slippery Mind", p. 63; class tables, e.g. p. 28 | happy / unhappy (rule interaction) |
| FR-079 | The command MUST accept `flatSavingThrowBonuses` (list of `FlatSavingThrowBonus(bonus: FlatBonus, abilities: Set<Ability>?)`, `null` meaning all six saves; an empty set throws `ArgumentError`). Each bonus MUST be added to every save it covers, after the proficiency term, as one `flatBonus` term in command order carrying its `FlatBonusSource` (a `MagicItemFlatBonusSource` for Ring or Cloak of Protection, Robe of Stars, Staff of Power). Effective ability scores from `magic-item-effects.md` FR-020 arrive through the existing `abilityScores` input. It applies to saving throws only, not skills or Passive Perception. | SRD 5.2.1, "Ring of Protection", p. 238; "Saving Throws", p. 7 | happy / unhappy (rule interaction) |

Cases (FR-017):

| Label | Ability modifier | Proficiency Bonus | Proficient | Expected | Path |
|---|---|---|---|---|---|
| proficient save | +2 (Constitution) | +2 | yes | +4 | happy |
| not proficient | +2 | +2 | no | +2 | unhappy (rule interaction) |
| proficient, negative ability | -1 | +3 | yes | +2 | unhappy (boundary) |
| not proficient, negative ability | -1 | +3 | no | -1 | unhappy (boundary) |

Cases (FR-079), source p. 238: Constitution +2, Proficiency Bonus +2, proficient, bonus +1 (item) on all saves gives Constitution +5 and a non-proficient Strength -1 save +0; a bonus scoped to `{dexterity}` leaves the other five saves unchanged; each save breakdown ends with its `flatBonus` term; an empty scope throws.

Cases (FR-049, FR-019), source p. 25, p. 63:

| Label | Class levels, `additionalSavingThrows` | Proficient saves | Path |
|---|---|---|---|
| Fighter 5 / Rogue 15 | initial Fighter; `{wisdom, charisma}` | Strength, Constitution, Wisdom, Charisma (Rogue's Dexterity and Intelligence not added) | unhappy (rule interaction) |
| Fighter 5 / Rogue 14 | initial Fighter; empty | Strength, Constitution only | unhappy (boundary) |
| Rogue 15 first | initial Rogue; `{wisdom, charisma}` | Dexterity, Intelligence, Wisdom, Charisma | happy |

### 4.5 Passive Perception

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-020 | Passive Perception MUST equal 10 plus the Wisdom (Perception) skill modifier from FR-013 to FR-015. | SRD 5.2.1, "Passive Perception", p. 22, p. 186 | happy |
| FR-021 | With `RollMode.advantage` on Wisdom (Perception) checks the score MUST increase by 5; with `RollMode.disadvantage` it MUST decrease by 5; with `RollMode.normal` it MUST be unchanged. `perceptionRollMode` is an already-resolved mode: `RollMode.resolve` owns the cancelling rule. | SRD 5.2.1, "Passive Perception", p. 186 | unhappy (rule interaction) |

| Label | Wisdom score | Perception training | Proficiency Bonus | Roll mode | Expected | Source | Path |
|---|---|---|---|---|---|---|---|
| SRD example | 15 (+2) | proficient | +2 | normal | 14 | p. 22, p. 186 | happy |
| SRD example with Advantage | 15 | proficient | +2 | advantage | 19 | p. 186 | unhappy (rule interaction) |
| Disadvantage | 15 | proficient | +2 | disadvantage | 9 | p. 186 | unhappy (rule interaction) |
| lowest Wisdom | 1 (-5) | none | +2 | normal | 5 | p. 186 | unhappy (boundary) |

### 4.6 Hit points and Hit Dice

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-028 | The `hitDicePool` in the result MUST equal the `HitDicePool` in the command unchanged. | SRD 5.2.1, "Multiclassing", "Hit Points and Hit Point Dice", p. 25 | happy / unhappy (rule interaction) |
| FR-029 | `HitPointMaximumBonus` values supplied in the command MUST be added to the stored `HitPointMaximum`. The constructor MUST throw `ArgumentError` for a negative `flat`, a negative `perLevel` or a `grantedAtLevel` outside 1 to 20. | SRD 5.2.1, "Level 3: Draconic Resilience", p. 69; "Dwarven Toughness", p. 84 | happy / unhappy (invalid input) |
| FR-050 | The Hit Point maximum in the result MUST be the stored `HitPointMaximum` (FR-060) plus the sum of the bonus contributions of FR-051. It MUST NOT be recomputed from levels, Hit Point Dice or the Constitution modifier. The caller's stored value MUST exclude these bonuses, or they are counted twice. With no bonuses it MUST equal the stored value. | `character-aggregate.md` (the stored value is maintained there); SRD 5.2.1, "Hit Points", p. 22 | happy |
| FR-051 | A `HitPointMaximumBonus` has `flat`, `perLevel`, `grantedAtLevel` and an optional class scope (`ClassId`). Let `n` be the level in the scope (the class's level when scoped, the total level when not). If `n` is below `grantedAtLevel` the contribution MUST be 0; otherwise `flat + perLevel * (n - grantedAtLevel)`. The caller supplies the numbers and scope from content; this spec holds no feature names. | SRD 5.2.1, "Level 3: Draconic Resilience", p. 69 ("increases by 3, and it increases by 1 whenever you gain another Sorcerer level"); "Dwarven Toughness", p. 84 ("increases by 1, and it increases by 1 again whenever you gain a level") | happy / unhappy (boundary) |
| FR-052 | `HitPointMaximumBonus.tryCreate` is an aggregate parser (errors-and-results.md FR-023) returning the sealed `HitPointMaximumBonusParse`: `ValidHitPointMaximumBonus(bonus)` or `InvalidHitPointMaximumBonus(problems)`. `problems` lists **every** violated field rule, each `HitPointMaximumBonusProblem` (enum: `negativeFlat`, `negativePerLevel`, `grantedAtLevelOutOfRange`) at most once, in enum order. It MUST NOT throw, and MUST return the invalid variant if and only if the constructor throws `ArgumentError`. | `architecture.md` §6 (host-supplied values) | unhappy (invalid input) |
| FR-060 | `HitPointMaximum` MUST be a value object holding an integer of at least 1, with `plus(int)` returning a new value. `HitPointMaximum.tryCreate` is a scalar factory (errors-and-results.md FR-035) returning the sealed `HitPointMaximumParse`: `ValidHitPointMaximum(maximum)` or `InvalidHitPointMaximum(value, reason)` with `reason` the enum `HitPointMaximumRejection` (`belowMinimum`); it MUST NOT throw, and the constructor throws `ArgumentError` for the same values. It carries no bonus field: bonuses are added only at read time (FR-050), and the reported maximum is the `HitPointMaximum` built from the breakdown total (FR-067). | SRD 5.2.1, "Gaining a Level", step 2, p. 23; "Hit Points", p. 22 | happy / unhappy (boundary) |
| FR-061 | `HitDicePool` MUST hold a count per die type, keyed by `HitPointDie` (never a raw `int`), with `HitDicePool.fromLevels(ClassLevels levels, Map<ClassId, HitPointDie> dice)` building it from `ClassLevels` and the die of each class (the host passes `definition.hitPointDie` per `ClassId`): one die per class level, the same `HitPointDie` pooled into one count, different dice kept separate. A class in `levels` with no entry in `dice` is a programmer error and `fromLevels` MUST throw `ArgumentError`; an entry in `dice` for a class not in `levels` is ignored. For `fromLevels` output the pool's total count equals the total level. Entries are ordered by ascending `HitPointDie.faces` so equal pools compare equal. This is the single statement of the pooling rule: `character-aggregate.md` FR-038 and FR-096 MUST cite it rather than restate it. | SRD 5.2.1, "Multiclassing", "Hit Points and Hit Point Dice" ("Add together the Hit Dice granted by all your classes to form your pool of Hit Dice. If these dice are the same die type, you can pool them together"), p. 25 | happy / unhappy (rule interaction) |
| FR-062 | `HitPointGain` MUST be sealed: `RolledHitPointGain(value, die)` or `FixedHitPointGain(value)`. `amount(AbilityModifier constitution)` MUST return the value plus the Constitution modifier, and at least 1. `RolledHitPointGain.tryCreate` is a scalar factory (errors-and-results.md FR-035) returning the sealed `RolledHitPointGainParse`: `ValidRolledHitPointGain(gain)` or `InvalidRolledHitPointGain(value, die, reason)` with `reason` the enum `RolledHitPointGainRejection` (`belowOne`, `aboveDieFaces`), for a host-supplied value below 1 or above `die.faces`; it MUST NOT throw. The constructors throw `ArgumentError` for programmer-supplied values out of range, and `FixedHitPointGain` requires a value of at least 1. The range check lives in the type: `character-aggregate.md` FR-035 and `level-advancement-and-multiclassing.md` MUST NOT repeat it; they only apply `amount` to the stored maximum. | SRD 5.2.1, "Gaining a Level", step 2 ("Roll that die, add your Constitution modifier to the roll, and add the total (minimum of 1) to your Hit Point maximum. Instead of rolling, you can use the fixed value"), p. 23 | happy / unhappy (boundary) |
| FR-070 | `HitDicePool` models the pool **by die type**: the dice a character has, not those spent. Its constructor MUST accept any map from `HitPointDie` to a count of at least 1 (zero-count entries are dropped so equal pools compare equal; a negative count throws `ArgumentError`) and enforces no relation to the level; the total-equals-level check (FR-061) is a property of `fromLevels` output only. Spent dice and rests are `rests-and-hit-dice.md`. | SRD 5.2.1, "Multiclassing", "Hit Points and Hit Point Dice", p. 25 | unhappy (invalid input / rule interaction) |
| FR-071 | `isBloodied(int currentHitPoints, HitPointMaximum maximum)` MUST be a pure top-level function of the `character` domain returning `true` if and only if twice `currentHitPoints` is at most the integer held by `maximum` (whole-number arithmetic). A `currentHitPoints` above the maximum is not Bloodied. Temporary Hit Points never count: the caller passes current Hit Points only. A negative `currentHitPoints` MUST throw `ArgumentError`. It is the **only** Bloodied predicate in the package (`shared-types-and-ownership.md` FR-049). "Half its Hit Points or fewer remaining" is read as half the Hit Point maximum, a package reading of the SRD wording. | SRD 5.2.1, Rules Glossary, "Bloodied", p. 177 | happy / unhappy (boundary) |
| FR-073 | `HitDicePool.plus(HitPointDie)` MUST return a new pool whose count for that die is one higher (1 when absent), every other count unchanged, entries in the FR-061 order, and leave the receiver unchanged. Adding one die per level for a sequence of classes yields the same pool as `fromLevels`. A host convenience; `character-aggregate.md` builds through the constructor (FR-070, its D-20), section 9. Rows below. | SRD 5.2.1, "Gaining a Level", step 2, p. 23; "Multiclassing", p. 25 | happy / unhappy (rule interaction) |

Bloodied cases (FR-071):

| Label | Current | Maximum | Expected | Path |
|---|---|---|---|---|
| exactly half / one above | 10 / 11 | 20 | `true` / `false` | unhappy (boundary) |
| odd maximum, below / above half | 7 / 8 | 15 | `true` / `false` | unhappy (boundary) |
| above the maximum | 25 | 20 | `false` | unhappy (boundary) |
| negative current | -1 | 20 | `ArgumentError` | unhappy (invalid input) |

Hit Point type cases (FR-060 to FR-062), source p. 23:

| Label | Input | Expected | Path |
|---|---|---|---|
| maximum of 1 | `HitPointMaximum` 1 | valid | unhappy (boundary) |
| maximum of 0 | `HitPointMaximum` 0 | `InvalidHitPointMaximum(0, belowMinimum)`; constructor `ArgumentError` | unhappy (boundary) |
| roll plus modifier | roll 5 on `HitPointDie.d8`, Con +2 | amount 7 | happy |
| negative modifier floors at 1 | roll 1 on d8, Con -3 | amount 1 | unhappy (boundary) |
| fixed plus modifier | fixed 6, Con +1 | amount 7 | happy |
| roll above faces | roll 9 on d8; roll 7 / 6 on d6 | `InvalidRolledHitPointGain` with `aboveDieFaces`; `aboveDieFaces` / valid | unhappy (boundary) |
| fixed 0 | `FixedHitPointGain` 0 | `ArgumentError` | unhappy (invalid input) |

Bonus cases (FR-029, FR-050, FR-051). Bonus is (flat, perLevel, grantedAtLevel, scope);
the stored maximum is a given input.

| Label | Bonus | Class levels | Stored | Contribution | Result | Source | Path |
|---|---|---|---|---|---|---|---|
| Draconic at level 3 | 3, 1, 3, Sorcerer | 3 Sorcerer | 20 | 3 | 23 | p. 69 | happy |
| Draconic at level 4 | 3, 1, 3, Sorcerer | 4 Sorcerer | 26 | 4 | 30 | p. 69 | unhappy (boundary) |
| Draconic below level 3 | 3, 1, 3, Sorcerer | 2 Sorcerer | 14 | 0 | 14 | p. 69 | unhappy (boundary) |
| Draconic scoped to Sorcerer | 3, 1, 3, Sorcerer | 3 Sorcerer, 2 Wizard | 30 | 3 | 33 | p. 69 | unhappy (rule interaction) |
| Dwarven Toughness level 1 | 1, 1, 1, none (total level) | 1 Fighter | 12 | 1 | 13 | p. 84 | happy |
| scope class absent | 3, 1, 3, Sorcerer | 3 Fighter | 30 | 0 | 30 | p. 69 | unhappy (boundary) |
| negative flat | -1, 0, 1, none | any | any | `ArgumentError`; `tryCreate` `[negativeFlat]` | | p. 69 | unhappy (invalid input) |
| granted at level 0 / 21 | 1, 0, 0 / 21, none | any | any | `ArgumentError`; `[grantedAtLevelOutOfRange]` | | p. 69 | unhappy (boundary) |
| every field invalid | -1, -1, 0, none | any | any | `[negativeFlat, negativePerLevel, grantedAtLevelOutOfRange]` | | p. 69 | unhappy (invalid input) |

Hit Dice pool cases (FR-061, FR-070, FR-073, FR-028 for the pass-through; Fighter and
Paladin d10, Cleric d8, Wizard d6; p. 25 and the class tables):

| Label | Class levels or input | Expected pool | Path |
|---|---|---|---|
| single class | 3 Fighter | d10 x 3 | happy |
| same die types pool | 5 Fighter, 5 Paladin | d10 x 10 | unhappy (rule interaction) |
| different die types stay separate | 5 Cleric, 5 Paladin | d8 x 5, d10 x 5 | unhappy (rule interaction) |
| minimal | 1 Wizard | d6 x 1 | unhappy (empty and minimal) |
| entries ordered by faces | 1 Fighter, 1 Wizard | d6 x 1, d10 x 1 regardless of class order | unhappy (determinism) |
| constructor, zero count dropped / negative count | `{d8: 2, d10: 0}` / `{d8: -1}` | d8 x 2 (equal to `{d8: 2}`) / `ArgumentError` | unhappy (boundary) |
| class without a die | `fromLevels` 3 Fighter, 2 Rogue, `dice` holding only Fighter | `ArgumentError` | unhappy (invalid input) |
| `plus` die absent / same / different | empty + d6; d10 x 5 + d10; d8 x 5 + d10 | d6 x 1; d10 x 6; d8 x 5, d10 x 1 | unhappy (empty and minimal) |
| `plus` keeps order, equals `fromLevels`, leaves receiver | d10 x 2 + d6; five d10 then five d10 | d6 x 1, d10 x 2 (receiver unchanged); d10 x 10 | unhappy (determinism) |
| extra definition ignored | `fromLevels` 3 Fighter, `dice` holding Fighter d10 and Wizard d6 | d10 x 3 | unhappy (rule interaction) |

### 4.7 Armor Class

Body armor and the Shield are `Armor` entries from `content-equipment.md`, which
owns only the **data** of an armor's rule (`ArmorClassRule`, its FR-093). The pure
evaluation (`ArmorRules.baseArmorClass`, returning `ArmorBase`) is
`equipment-rules.md` FR-001 to FR-005 (`shared-types-and-ownership.md` FR-048),
whose own case table tests full, capped and no Dexterity. This section covers
which basis applies, training, the Shield and flat bonuses, and how the use case
assembles them. In the cases a result is written without the
`CalculateDerivedStats` prefix.

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-030 | With no armor, no Shield and no alternative base, AC MUST be 10 plus the Dexterity modifier. | SRD 5.2.1, "Armor Class", p. 7, p. 22, p. 177 | happy |
| FR-034 | A Shield MUST add the bonus given by its content entry's bonus rule (+2 for the SRD Shield) after the base, when the character has Shield training. The bonus MUST NOT be a constant in the domain. | SRD 5.2.1, "Armor", p. 92 | happy |
| FR-035 | A Shield without training MUST add nothing to AC, and the loss is reported by adding `ArmorCategory.shield` to `armorTrainingGaps` (FR-039). | SRD 5.2.1, "Shield", p. 92; "Armor Training", p. 177 | unhappy (rule interaction) |
| FR-036 | An `AbilityBasedArmorClassBasis` (10 plus Dexterity plus the modifiers of its `Set<Ability>`) MUST apply only when no body armor is worn, and, when its `shieldAllowed` is false, only when no Shield is wielded. It is a command-input value object only: the class specs build it with pure character-owned functions (`class-barbarian.md` FR-112, `class-monk.md` FR-031, `class-sorcerer.md` FR-088), so this spec holds no feature or class names. | SRD 5.2.1, "Barbarian", "Unarmored Defense", p. 29 (a Shield is allowed); "Monk", "Unarmored Defense", p. 50 (no Shield); "Draconic Resilience", p. 69 (only "aren't wearing armor") | happy / unhappy (rule interaction) |
| FR-037 | Only one base calculation MUST be in effect. When the command names a `chosenBasis` (`ArmorClassBasisChoice`: `ChooseStandard`, `ChooseArmored` or `ChooseAlternative(FeatureId)`) it MUST be used. A chosen basis that is not applicable by the matrix in FR-054 MUST return `CalculateDerivedStatsArmorClassBasisNotApplicable` with reason `notApplicable`; a `ChooseAlternative` id the command does not supply MUST return it with reason `alternativeNotSupplied`, checked **before** applicability (FR-076). The result carries the chosen `ArmorClassBasisChoice` and the reason (FR-064). | SRD 5.2.1, "Armor Class", p. 7, p. 177 ("you choose which calculation to use; you can't use more than one"); "Multiclassing", "Armor Class", p. 25 | unhappy (rule interaction / state error) |
| FR-038 | Each `FlatBonus` to AC supplied in the command MUST be added after the base and the Shield, and appear as a `flatBonus` term carrying its `FlatBonusSource`. A `FlatBonus` holds a `Modifier` and a `FlatBonusSource`, the sealed typed origin: `SpellFlatBonusSource(SpellId)` (FR-081), `MagicItemFlatBonusSource(ItemId)` (FR-079) or a host-defined source. | SRD 5.2.1, "Armor Class", p. 7 | happy |
| FR-039 | Wearing a Light, Medium or Heavy armor without the matching training MUST NOT change the AC, and MUST add that `ArmorCategory` to `armorTrainingGaps` on the result. A Shield wielded without Shield training likewise MUST add `ArmorCategory.shield` to the gaps (its AC bonus is dropped, FR-035); `shield` in the gaps carries no Disadvantage or spellcasting consequence. A trained Shield, or no Shield, adds nothing. The Disadvantage is FR-077. Armor worn untrained keeps its AC base: only the Shield names an AC loss (settled, section 9). | SRD 5.2.1, "Armor Training", p. 92, p. 177; "Note Armor Training", p. 19 | unhappy (rule interaction) |
| FR-040 | Armor training MUST be the union of the initial class's `armorTraining` from its `ClassDefinition` and the `multiclassArmorTraining` the caller supplies (the traits each later class lists in "As a Multiclass Character"). `content-classes.md` FR-022 types `armorTraining` as `Set<ArmorTrainingCategory>` and `content-equipment.md` FR-104 types `ArmorTraining` over `ArmorCategory`: the union converts `ArmorTrainingCategory` to `ArmorCategory` by member name (`light`, `medium`, `heavy`, `shield`), in this one place only; the two enums deliberately mirror each other (`content-classes.md` D10; section 9). | SRD 5.2.1, "Multiclassing", "Proficiencies", p. 25; "Barbarian", p. 28 | unhappy (rule interaction) |
| FR-053 | The command's `armorId` and `shieldId` (both `ItemId`) MUST be resolved through `ContentSource` as equipment (`ContentKind.equipment`, twelve entry types, `content-equipment.md` section 3). Any resolved entry that is not an `Armor`, a resolved `armorId` whose rule is a `BonusRule`, and a resolved `shieldId` whose rule is a `BaseRule` MUST each return `CalculateDerivedStatsEquipmentSlotMismatch(key, expected)`: `key` the `ContentKey` of the offending entry and `expected` the `ArmorSlot` the id was supplied for. For an `Armor` the slot is decided by the rule subtype, which `content-equipment.md` FR-024 ties to the category. The use case applies the check for both ids before calling the calculator (which receives only `Armor` values and repeats the rule-subtype check). If both mismatch, the `armorId` is reported. An unknown id is `CalculateDerivedStatsContentMissing` (FR-043), including a Shield id. | SRD 5.2.1, "Armor", p. 92 ("One at a Time"); `content-equipment.md` FR-024 | unhappy (invalid input) |
| FR-054 | The applicable bases MUST follow the matrix below. With no `chosenBasis` the applicable basis with the highest total MUST be used; ties resolve in the order `StandardArmorClassBasis`, `ArmoredArmorClassBasis`, then alternatives in command order, so the result is deterministic. | SRD 5.2.1, "Armor Class", p. 7, p. 177; package decision for a missing input | unhappy (rule interaction) |
| FR-076 | `CalculateDerivedStatsCommand` MUST throw `ArgumentError` when two entries of `alternativeBases` have the same `FeatureId` (a programmer error), so `ChooseAlternative(id)` always names one basis. When `chosenBasis` is `ChooseAlternative(id)` and no supplied alternative has that id, the result is `alternativeNotSupplied`, checked before the matrix, so it is reported even when armor is worn or a Shield is wielded. | SRD 5.2.1, "Armor Class", "Only One Base AC", p. 7; package decision for ambiguous inputs | unhappy (invalid input / state error) |
| FR-077 | `DerivedStats` MUST expose `armorTrainingCircumstances(Set<Ability> involved)`, returning `ArmorTrainingEffects.rollCircumstancesFor(involved)` (`equipment-rules.md` FR-072) for the `ArmorTrainingRules.assess` result (FR-071) of the worn armor categories (body armor and a wielded Shield) and the training of FR-040. It returns one `Disadvantage` (`RollCircumstance`) when untrained Light, Medium or Heavy armor is worn and `involved` holds Strength or Dexterity, and an empty list otherwise (an untrained Shield alone gives none, `equipment-rules.md` FR-073). This spec adds no rule and does not resolve a roll (`equipment-rules.md` FR-077). The Disadvantage is never a term of a `ModifierBreakdown`, and `armorTrainingGaps` equal `untrained`. | SRD 5.2.1, "Armor Training", p. 177; "Armor", p. 92; `equipment-rules.md` FR-071 to FR-073, FR-077; `shared-types-and-ownership.md` FR-060 | happy / unhappy (rule interaction) |
| FR-078 | `DerivedStats` MUST expose `stealthCircumstances(Iterable<Armor> worn)`, returning `ArmorRules.stealthCircumstances(worn)` (`equipment-rules.md` FR-079) unchanged: one `Disadvantage` when any worn armor has Stealth Disadvantage, else an empty list, regardless of training. The consumer applies it to Dexterity (Stealth) checks. It is never a term of a `ModifierBreakdown` and adds no rule here (mirrors FR-077). | SRD 5.2.1, "Armor", Stealth, p. 92; `equipment-rules.md` FR-079 | unhappy (rule interaction) |
| FR-080 | `CalculateDerivedStatsCommand` MUST accept an optional `armorClassFloor` (an int of at least 1, else `ArgumentError`; with several floors the host passes the highest). After the base, the Shield and every flat bonus, when the subtotal is below the floor the total MUST become the floor, shown as one `floor` term holding the difference; at or above it there is no term. It is a minimum on the finished AC, never a base, and nothing is added after it. | SRD 5.2.1, "Barkskin", p. 112; "Armor Class", p. 7, p. 177; `spell-granted-modifiers.md` FR-042 | unhappy (rule interaction / boundary) |
| FR-081 | `AbilityBasedArmorClassBasis` gains `baseValue` (an int of at least 1, default 10, else `ArgumentError`): the basis is `baseValue` plus Dexterity plus the modifiers of its abilities, and its `baseValue` term carries that value (Mage Armor: 13, `spell-granted-modifiers.md` FR-041). Its applicability (matrix, FR-054) and tie rank are unchanged. `FlatBonusSource` accepts a spell id (FR-038), so spell AC bonuses (Shield, Shield of Faith, Haste, Slow) are ordinary `FlatBonus`es (FR-038). | SRD 5.2.1, "Mage Armor", p. 145; "Shield of Faith", p. 162; "Armor Class", p. 7, p. 177 | happy / unhappy (rule interaction) |

Applicability matrix (FR-036, FR-037, FR-054). "Armor" is body armor; the Shield
bonus (FR-034) is added afterwards in every column.

| Basis | No armor, no Shield | No armor, Shield wielded | Armor worn (with or without Shield) |
|---|---|---|---|
| `StandardArmorClassBasis` | applicable | applicable | not applicable (the armor replaces it) |
| `ArmoredArmorClassBasis` | not applicable | not applicable | applicable |
| `AbilityBasedArmorClassBasis`, `shieldAllowed` true | applicable | applicable | not applicable |
| `AbilityBasedArmorClassBasis`, `shieldAllowed` false | applicable | not applicable | not applicable |

Armor Class cases. Armor rows source p. 92; alternative bases source p. 29
(Barbarian, Con), p. 50 (Monk, Wis), p. 69 (Sorcerer, Cha). "Other" lists the
modifiers of the alternative bases the command supplies.

| Label | Armor | Shield | Training | Dex | Other | Chosen | Expected | Path |
|---|---|---|---|---|---|---|---|---|
| unarmored, positive Dex | none | no | any | +3 | | | 13 | happy |
| Heavy without training (gap, AC unchanged) | Chain Mail | no | Light, Medium | +0 | | | 16; gaps `{heavy}` | unhappy (rule interaction) |
| Shield only, trained through a multiclass | none | yes | none; multiclass Shield | +2 | | | 14; gaps none | unhappy (rule interaction) |
| plate with trained Shield | Plate Armor | yes | Heavy, Shield | +0 | | | 20 | happy |
| plate, untrained Shield | Plate Armor | yes | Heavy | +0 | | | 18; gaps `{shield}` | unhappy (rule interaction) |
| unarmored with trained Shield | none | yes | Shield | +2 | | | 14 | happy |
| unarmored, untrained Shield | none | yes | none | +2 | | | 12 | unhappy (rule interaction) |
| Barbarian Unarmored Defense, without / with Shield | none | no / yes | Shield | +2 | Con +3 | | 15 / 17 | happy |
| Barbarian wearing armor | Hide Armor | no | Medium | +2 | Con +3 | | 14 | unhappy (rule interaction) |
| Monk Unarmored Defense, without / with Shield | none | no / yes | none | +3 | Wis +3 | | 16 / 13 (Standard) | happy |
| tie resolves to Standard | none | no | Shield | +2 | Con +0 | none | 12 (Standard term) | unhappy (boundary) |
| Sorcerer (Draconic) unarmored | none | no | none | +2 | Cha +3 | | 15 | happy |
| Barbarian 1 / Monk 1, choose Monk / Standard | none | no | Shield | +2 | Con +4, Wis +1 | Monk / Standard | 13 / 12 | unhappy (rule interaction) |
| two bases, none chosen, Barbarian / Monk higher | none | no | Shield | +2 | Con +4, Wis +1 / Con +1, Wis +5 | none | 16 / 17 (highest of Barbarian, Monk, Standard) | unhappy (rule interaction) |
| chosen alternative, armor worn | Leather Armor | no | Light | +2 | Con +3 | Barbarian | `ArmorClassBasisNotApplicable`, `notApplicable`, choice Barbarian | unhappy (state error) |
| chosen Monk, Shield wielded | none | yes | Shield | +3 | Wis +3 | Monk | `ArmorClassBasisNotApplicable`, `notApplicable`, Monk | unhappy (state error) |
| chosen alternative not supplied | none | no | none | +2 | | Barbarian (not in command) | `ArmorClassBasisNotApplicable`, `alternativeNotSupplied`, Barbarian | unhappy (state error) |
| flat bonus added | Leather Armor | no | Light | +2 | flat +1 (magic item) | | 14 | happy |
| armor id is a Shield / Shield id is body armor | Shield as `armorId` / Leather Armor as `shieldId` | no / yes | any | +0 | | | `EquipmentSlotMismatch(key: Shield, expected: bodyArmor)` / `(key: Leather Armor, expected: shield)` | unhappy (invalid input) |
| Mage Armor base 13 (FR-081) | none | no | none | +2 | `AbilityBasedArmorClassBasis` base 13, no abilities | | 15 | happy |
| Mage Armor and Shield of Faith, floor 17 (FR-080) | none | no | none | +2 | base 13; flat +2 (spell) | | 17 (floor adds nothing); with floor 18: 18, `floor` term +1 | unhappy (rule interaction) |
| Barkskin floor on low / high AC | Leather Armor / Plate Armor | no | Light / Heavy | +0 | floor 17 | | 17, `floor` term +6 (from 11) / 18, no `floor` term | unhappy (boundary) |
| duplicate alternative ids | none | no | none | +2 | two alternatives with id `barbarian_unarmored_defense` | | `ArgumentError` from the command constructor (FR-076) | unhappy (invalid input) |

Cases (FR-077, FR-078):

| Label | Worn, training, `involved` | Expected | Path |
|---|---|---|---|
| untrained Heavy, Strength | Chain Mail, Light and Medium, `{strength}` | `[Disadvantage]` | happy |
| untrained Medium, Dexterity | Hide Armor, Light, `{dexterity}` | `[Disadvantage]` | unhappy (rule interaction) |
| untrained, other ability | Chain Mail, Light, `{constitution}` | `[]` | unhappy (rule interaction) |
| trained | Chain Mail, Heavy, `{strength}` | `[]` | unhappy (rule interaction) |
| untrained Shield alone | Shield, none, `{strength, dexterity}` | `[]`; gaps `{shield}` | unhappy (rule interaction) |
| AC unchanged | Chain Mail, Light, Dex +5 | AC 16 and `[Disadvantage]` for `{dexterity}` | unhappy (rule interaction) |
| Stealth, trained or not (FR-078) | Chain Mail (Stealth Disadvantage), Heavy trained; Hide Armor, none | `[Disadvantage]`; `[]` | unhappy (rule interaction) |
| Stealth, Shield only / nothing worn (FR-078) | Shield; none | `[]`; `[]` | unhappy (empty and minimal) |

### 4.8 The use case and cross-cutting behaviour

| Id | Requirement | Source | Path |
|---|---|---|---|
| FR-041 | These outputs MUST each carry a `ModifierBreakdown`: each of the six saving throw modifiers, each of the 18 skill modifiers, Passive Perception, Armor Class and the Hit Point maximum. Total level, Proficiency Bonus and the Hit Dice pool carry none. The terms per output are the table below. | SRD 5.2.1, "D20 Tests" (modifiers), p. 6; `architecture.md` §6 | happy |
| FR-056 | A `ModifierBreakdown` is an ordered, unmodifiable list of `BreakdownTerm`s, each a `Modifier`, a `DerivedStatSource` and, for `abilityModifier` terms, the `Ability` (for `flatBonus` terms the `FlatBonusSource`). It exposes `total`, the sum of its terms. **The breakdown is the single source of each number** (FR-067). A source is a typed value, never a label string. | `architecture.md` §3, §6, §10 | happy / unhappy (determinism) |
| FR-067 | The `ModifierBreakdown` constructor MUST throw `ArgumentError` for: more than one term whose source is `proficiencyBonus` or `expertise` (FR-010; together one slot); an `abilityModifier` term without an `Ability`; an `Ability` on a term whose source is not `abilityModifier`; a `flatBonus` term without a `FlatBonusSource`; a `FlatBonusSource` on any other term. Several `abilityModifier` terms are allowed (an alternative AC basis names more than one). Each output value object (`SavingThrowModifier`, `SkillModifier`, `PassivePerception`) MUST be constructed from a breakdown only and derive its `value` from `breakdown.total`; `DerivedStats` stores the Armor Class and Hit Point maximum only as breakdowns and builds the `ArmorClass` (`d20_test`) and the reported `HitPointMaximum` from `total`. | `shared-types-and-ownership.md` FR-003; `architecture.md` §3 | unhappy (invalid input) |
| FR-066 | `ModifierBreakdown.toRollModifiers()` MUST be a pure domain method returning the sealed `BreakdownRollModifiersParse`: `BreakdownMappedToRollModifiers(modifiers)` or `BreakdownNotMappable(problems)`. Mapping: the single `abilityModifier` term's `Modifier` is `RollModifiers.ability`; the single `proficiencyBonus` or `expertise` term's `Modifier` is the optional Proficiency Bonus slot; every `flatBonus` term is one entry of `RollModifiers.others`, in term order. `problems` lists every `BreakdownMappingProblem` (enum: `missingAbilityTerm`, `multipleAbilityTerms`, `unmappableSource`) found, each at most once, in enum order; `unmappableSource` means a term whose source is `baseValue`, `armorBase`, `shieldBonus`, `floor`, `rollMode`, `storedHitPointMaximum` or `hitPointMaximumBonus`. So a saving throw or skill breakdown maps; Passive Perception, Armor Class and Hit Point maximum do not. This is the only mapping from a breakdown to a D20 Test: `d20_test` is upstream and knows nothing of breakdowns (`shared-types-and-ownership.md` FR-013). | SRD 5.2.1, "D20 Tests", "Add Modifiers", p. 6; "The Bonus Doesn't Stack", p. 8; `shared-types-and-ownership.md` FR-003, FR-013; `d20-tests.md` FR-017, FR-018 | happy / unhappy (invalid input, rule interaction) |
| FR-068 | Failure precedence MUST be deterministic. The use case returns the first that applies: (1) `CalculateDerivedStatsContentMissing`, holding every unknown id (FR-043); (2) `CalculateDerivedStatsEquipmentSlotMismatch` (`armorId` before `shieldId`, FR-053); (3) `CalculateDerivedStatsArmorClassBasisNotApplicable` (FR-037). Step 1 is the use case's alone. Step 2 is the use case's for a non-`Armor` entry and the calculator's for the rule subtype. Step 3 is the calculator's and checks `alternativeNotSupplied` before `notApplicable` (FR-076). The calculator never sees step 1. | `testing.md` §4 (determinism); `architecture.md` §6 | unhappy (rule interaction) |
| FR-069 | The result and reason types of the `tryCreate` factories, and the failure data of the calculator, MUST have exactly the names in section 5. Each is exported once from the `character` barrel, none is a generic name (`architecture.md` §4), and none repeats a `shared_kernel` name (`AbilityScoreRejection`, `InvalidAbilityScore`; `ability-scores.md` FR-026). | `shared-types-and-ownership.md` FR-017, FR-021; `ability-scores.md` FR-026 | unhappy (name collision) |
| FR-042 | A level-1 character with the lowest valid inputs MUST still produce a complete result: 6 saves, 18 skills, a Hit Point maximum of at least 1, an AC and a Passive Perception. | SRD 5.2.1, "Fill In Numbers", p. 22 | unhappy (empty and minimal) |
| FR-043 | When the initial class, armor or Shield id is unknown to the `ContentSource`, `CalculateDerivedStats` MUST return `CalculateDerivedStatsContentMissing`, holding one `MissingContent(kind, id)` per unknown id, in lookup order (initial class, armor, Shield) with duplicates removed, and no partial stats. It takes precedence over every other failure (FR-068). | `testing.md` §4; SRD 5.2.1, "Multiclassing", p. 24-25; `shared-types-and-ownership.md` FR-017, FR-018 | unhappy (missing content) |
| FR-044 | When the `ContentSource` throws its typed `Srd5eException`, `CalculateDerivedStats` MUST let it propagate unchanged and return nothing. Any other exception is FR-074. | `architecture.md` §4 | unhappy (collaborator failure) |
| FR-045 | Given the same command and content, the result MUST be identical on every call. The command and content definitions MUST NOT be altered, and every collection in the result MUST be unmodifiable. | `architecture.md` §3; `testing.md` §4 | unhappy (determinism, immutability) |
| FR-046 | With a no-op `Observability` and with a recording one, the use case MUST return equal results. | `observability.md` §9 | happy |
| FR-047 | A successful call MUST emit the signals in section 7 with the attribute keys and values listed there: the `calculate` span with outcome `success`; one `load_content` child span around the `ContentSource` lookups with outcome `success`; the `calls` counter with outcome `success`; the duration histogram; and the levels histogram. A successful call emits no log. | `observability.md` §5, §6, §7, §9; `shared-types-and-ownership.md` FR-041, FR-043 | happy |
| FR-048 | Each failure MUST be recorded once and without a log. Every call that returns a result or throws an `Srd5eException` increments `calls` exactly once. A returned failure result (`content_missing`, `armor_class_basis_not_applicable`, `equipment_slot_mismatch`) MUST set the `calculate` span to error status with outcome `failure`, and increment `calls` with `srd5e.outcome` `failure` and `srd5e.character.derived_stats.failure` set to the variant; it MUST NOT set `error.type`. A port exception (`content_source_exception`) leaves through two spans: the `Tracer` sets error status and records the exception on every span it propagates through (`observability-ports.md` FR-012, FR-014), so both `load_content` and `calculate` carry error status and the exception. The use case also sets outcome `failure` on both, increments `calls` with outcome `failure` and **no** failure attribute, and increments `errors` once with `error.type` equal to the exception's `errorType`. Only the use case counts: one `calls` and one `errors` increment per call. `load_content` has outcome `failure` and error status when any lookup returns not-found (no exception recorded) or throws; for `equipment_slot_mismatch` and `armor_class_basis_not_applicable` the lookups succeeded, so it has outcome `success`. The duration histogram MUST be recorded for every outcome; the levels histogram only for success. | `errors-and-results.md` FR-034, FR-043; `observability-ports.md` FR-012, FR-014; `observability.md` §5, §6, §7, §9 (amended per `shared-types-and-ownership.md` FR-051); `shared-types-and-ownership.md` FR-041 | unhappy (telemetry on failure) |
| FR-063 | `CalculateDerivedStatsCommand`, the domain and the use case MUST NOT reference `Character`, `character-aggregate.md` or any `combat` type. | `shared-types-and-ownership.md` FR-013, FR-016 | unhappy (forbidden edge) |
| FR-064 | The use case's result is the sealed `CalculateDerivedStatsResult`: `CalculateDerivedStatsSucceeded(stats: DerivedStats)`; `CalculateDerivedStatsContentMissing(missing: List<MissingContent>)`; `CalculateDerivedStatsArmorClassBasisNotApplicable(choice: ArmorClassBasisChoice, reason: ArmorClassBasisRejection)` with `ArmorClassBasisRejection` the enum `notApplicable`, `alternativeNotSupplied`; `CalculateDerivedStatsEquipmentSlotMismatch(key: ContentKey, expected: ArmorSlot)` with `ArmorSlot` the enum `bodyArmor`, `shield`. No generic variant name is exported. Variant fields are asserted in full by the tests. | `architecture.md` §4; `shared-types-and-ownership.md` FR-017, FR-018 | unhappy (name collision) |
| FR-074 | When the `ContentSource` throws an `Exception` that is not an `Srd5eException` (a port contract breach, `errors-and-results.md` FR-051), `CalculateDerivedStats` MUST NOT catch it: it propagates unchanged (the same instance) and nothing is returned. The `Tracer` records it and sets error status on `load_content` and `calculate`. There is no `calls` or `errors` increment, no `error.type`, and no log. `srd5e.outcome` is not set on `calculate` or `load_content`; only error status and the recorded exception. The duration histogram is still recorded, because `Meter.timeAsync` records on any error. | `errors-and-results.md` FR-034, FR-043, FR-051; `observability-ports.md` FR-012, FR-014; `testing.md` §4 | unhappy (collaborator failure) |
| FR-075 | Each failure variant that holds a list or set of problems MUST reject an empty one with `ArgumentError` in its constructor: `InvalidClassLevels(problems)`, `InvalidHitPointMaximumBonus(problems)`, `InvalidSkillProficiencies(expertiseWithoutProficiency)`, `BreakdownNotMappable(problems)` and `CalculateDerivedStatsContentMissing(missing)`. A single entry is valid and the held collection is unmodifiable. **Documented deviation from `errors-and-results.md` FR-023**: `ClassLevelsProblem`, `HitPointMaximumBonusProblem` and `BreakdownMappingProblem` are enums without a path, because each names a violated invariant of the whole value, not an offending item of a list input, and they are ordered by enum order. The problem type is owned by this context (`errors-and-results.md` OQ-2); if a path is ever needed the enums become value objects, a breaking change. | `errors-and-results.md` FR-023, FR-024, OQ-2; `architecture.md` §3 | unhappy (empty and minimal) |

Breakdown terms per output (FR-041, FR-056), in the order listed:

| Output | Terms |
|---|---|
| Saving throw | `abilityModifier` (the save's ability); `proficiencyBonus` when proficient; one `flatBonus` per covering `FlatSavingThrowBonus` (FR-079) |
| Skill | `abilityModifier` (the skill's ability); `proficiencyBonus` when proficient, or `expertise` (twice the bonus) with Expertise |
| Passive Perception | `baseValue` (10); the Perception skill's terms; `rollMode` (+5 or -5) when the mode is not `normal` |
| Armor Class | Standard: `baseValue` (10), `abilityModifier` (Dexterity). Armored: `armorBase` (`ArmorBase.listedBase`, `equipment-rules.md` FR-004), `abilityModifier` (Dexterity, carrying `dexterityContribution`, omitted when 0). Alternative: `baseValue` (the basis's `baseValue`, default 10, FR-081), `abilityModifier` (Dexterity), then one `abilityModifier` per named ability. Then `shieldBonus` when it applies, then one `flatBonus` per `FlatBonus` in command order, then `floor` when the floor lifts the total (FR-080). |
| Hit Point maximum | `storedHitPointMaximum`; one `hitPointMaximumBonus` per supplied bonus, in command order, with its contribution (0 included). No per-level terms. |

`DerivedStatSource` values: `baseValue`, `abilityModifier`, `proficiencyBonus`,
`expertise`, `armorBase`, `shieldBonus`, `rollMode`, `flatBonus`,
`storedHitPointMaximum`, `hitPointMaximumBonus`, `floor`.

Cases (FR-066, FR-067); a breakdown lists terms as source (value):

| Label | Breakdown | Expected | Path |
|---|---|---|---|
| saving throw, proficient | `abilityModifier`(+2, Con), `proficiencyBonus`(+2) | mapped: ability +2, proficiency +2, others empty | happy |
| skill, Expertise | `abilityModifier`(+3, Str), `expertise`(+4) | mapped: ability +3, proficiency slot +4 (one slot) | unhappy (rule interaction) |
| Passive Perception | `baseValue`(10), `abilityModifier`(+2, Wis), `proficiencyBonus`(+2) | `BreakdownNotMappable` `[unmappableSource]` | unhappy (invalid input) |
| two ability terms | `abilityModifier`(+1, Dex), `abilityModifier`(+3, Con) | `[multipleAbilityTerms]` | unhappy (rule interaction) |
| several problems | `baseValue`(10), `abilityModifier`(+1, Dex), `abilityModifier`(+3, Con) | `[multipleAbilityTerms, unmappableSource]` | unhappy (invalid input) |
| Armor Class | `baseValue`(10), `abilityModifier`(+2, Dex), `shieldBonus`(+2) | exactly `[unmappableSource]` | unhappy (invalid input) |
| empty breakdown | no terms | `[missingAbilityTerm]` | unhappy (empty and minimal) |
| second Proficiency Bonus term | `proficiencyBonus`(+2), `expertise`(+4) | constructor `ArgumentError` | unhappy (rule interaction) |

Failure precedence cases (FR-068); each row supplies two failures at once:

| Label | Situation | Expected | Path |
|---|---|---|---|
| missing beats slot mismatch | Shield id unknown; `armorId` resolves to a Shield | `ContentMissing` for the Shield id only | unhappy (rule interaction) |

### Withdrawn ids

| Id | Requirement |
|---|---|
| FR-001, FR-007, FR-008 | Withdrawn: moved to derived-stats.md as FR-057 (`CharacterLevel`), FR-058 (`ClassLevels.totalLevel`), FR-059 (the Proficiency Bonus table) |
| FR-002 to FR-005 | Withdrawn: moved to character-aggregate.md (`ExperiencePoints`, level from XP, cap at 20, `minimumForLevel`) |
| FR-006 | Withdrawn: no `LevelHistory` (`shared-types-and-ownership.md` FR-008) |
| FR-011 | Withdrawn: moved to `content` (`shared-types-and-ownership.md` FR-005, FR-006; `Skill` and its `Ability`) |
| FR-022 | Withdrawn: moved to character-aggregate.md and character-creation.md (level 1 maximum) |
| FR-023, FR-026, FR-027 | Withdrawn: moved to level-advancement-and-multiclassing.md (fixed value per class, Constitution modifier change rule, which Hit Point Die a level uses) |
| FR-024, FR-025 | Withdrawn: moved to derived-stats.md (FR-062), rolled gain range check and minimum of 1 per level |
| FR-031 to FR-033, FR-065 | Withdrawn: moved to equipment-rules.md (FR-001 to FR-006), Light, Medium and Heavy armor and `ArmorRules.baseArmorClass` |
| FR-055 | Withdrawn: initial class is the first `ClassLevels` entry (`shared-types-and-ownership.md` FR-008) |

## 5. Model

Domain (`lib/src/character/domain/`), pure and immutable:
- **Consumed:** `AbilityScores`, `AbilityScore`, `AbilityModifier`, `Ability`,
  `Modifier`, `RollMode` (`shared_kernel`); `ArmorClass`, `RollModifiers`
  (`d20_test`); `Armor`, `ArmorCategory`, `ArmorClassRule`, `ClassDefinition`,
  `HitPointDie`, `Skill`, `ClassId`, `ItemId`, `FeatureId`, `ContentKey`,
  `MissingContent` (`content`); `ArmorRules.baseArmorClass`, `ArmorBase`
  (`equipment-rules.md`). The domain never touches `ContentSource`, a use case or
  a `Character`.
- **Owned types** (`shared-types-and-ownership.md` FR-008): `CharacterLevel`,
  `ClassLevels` (with `withLevelIn`, FR-072), `ProficiencyBonus`,
  `HitPointMaximum`, `HitDicePool` (with `plus`, FR-073), `HitPointGain`
  (`RolledHitPointGain` | `FixedHitPointGain`). Exported from the `character`
  barrel.
- **Value objects:** `HitPointMaximumBonus`, `ArmorTraining`,
  `SavingThrowProficiencies`, `SkillProficiencies`, `FlatBonus`, `FlatSavingThrowBonus`, sealed `FlatBonusSource`,
  `SavingThrowModifier`, `SkillModifier`, `PassivePerception`,
  `ModifierBreakdown` (`BreakdownTerm`: `Modifier`, `DerivedStatSource`, optional
  `Ability`, optional `FlatBonusSource`), enum `ArmorSlot`; `isBloodied` is a
  top-level pure function. There is no `ArmorClass` type here: `DerivedStats`
  builds `d20_test`'s from the Armor Class breakdown's `total`.
- `ArmorClassBasis` (sealed command input, not a content type):
  `StandardArmorClassBasis` | `ArmoredArmorClassBasis` (the resolved `Armor`) |
  `AbilityBasedArmorClassBasis` (`abilities`, `shieldAllowed`, `id` of type
  `FeatureId`). `content` cannot import a `character` type and
  `content-classes.md` declares no alternative basis (its `FeatureFact` is sealed,
  its FR-055), so the class specs supply the values through pure character-owned
  functions: `class-barbarian.md` FR-112, `class-monk.md` FR-031,
  `class-sorcerer.md` FR-088. `ArmorClassBasisChoice` (sealed): `ChooseStandard` |
  `ChooseArmored` | `ChooseAlternative(FeatureId)`. `AbilityBasedArmorClassBasis` also holds `baseValue` (FR-081).
- Domain service `DerivedStatsCalculator`: stateless; takes `ClassLevels`,
  `AbilityScores`, the stored `HitPointMaximum`, `HitDicePool`, the initial class
  definition, resolved `Armor` values, proficiencies, bonuses, alternative bases,
  training and a `RollMode`; returns the sealed `DerivedStatsCalculation`
  (`DerivedStatsComputed(stats)`, `DerivedStatsBasisNotApplicable(choice,
  reason)`, `DerivedStatsSlotMismatch(key, expected)`), which the use case maps
  one-to-one to its result (FR-064). It never sees missing content (FR-068).
- `DerivedStats`: total level, Proficiency Bonus, the Hit Point maximum breakdown,
  `HitDicePool`, the Armor Class breakdown, `armorTrainingGaps`,
  `armorTrainingCircumstances(involved)` (FR-077), `stealthCircumstances(worn)` (FR-078), six saving throw modifiers, 18
  skill modifiers, Passive Perception.
- No entity, aggregate or domain event.

**Result and reason types** (FR-069), each exported once from the `character` barrel:

| Factory or failure | Sealed result | Variants and reasons |
|---|---|---|
| `CharacterLevel.tryCreate` (scalar) | `CharacterLevelParse` | `ValidCharacterLevel`, `InvalidCharacterLevel(value, reason)`; `CharacterLevelRejection` |
| `ClassLevels.tryCreate` (aggregate) | `ClassLevelsParse` | `ValidClassLevels`, `InvalidClassLevels(problems)`; `ClassLevelsProblem` |
| `SkillProficiencies.tryCreate` (aggregate) | `SkillProficienciesParse` | `ValidSkillProficiencies`, `InvalidSkillProficiencies(expertiseWithoutProficiency)` |
| `HitPointMaximumBonus.tryCreate` (aggregate) | `HitPointMaximumBonusParse` | `ValidHitPointMaximumBonus`, `InvalidHitPointMaximumBonus(problems)`; `HitPointMaximumBonusProblem` |
| `HitPointMaximum.tryCreate` (scalar) | `HitPointMaximumParse` | `ValidHitPointMaximum`, `InvalidHitPointMaximum(value, reason)`; `HitPointMaximumRejection` |
| `RolledHitPointGain.tryCreate` (scalar) | `RolledHitPointGainParse` | `ValidRolledHitPointGain`, `InvalidRolledHitPointGain(value, die, reason)`; `RolledHitPointGainRejection` |
| `ModifierBreakdown.toRollModifiers` | `BreakdownRollModifiersParse` | `BreakdownMappedToRollModifiers`, `BreakdownNotMappable(problems)`; `BreakdownMappingProblem` |
| Use case failures | `CalculateDerivedStatsResult` | FR-064; `ArmorClassBasisRejection`, `ArmorSlot` |

## 6. Interface

- **Use case** `CalculateDerivedStats` (`application/`), one `call` method,
  **async** (`Future<CalculateDerivedStatsResult>`) because `ContentSource` is
  (`architecture.md` §4); the domain is synchronous.
  - Command `CalculateDerivedStatsCommand`: `ClassLevels`; `abilityScores`
    (`AbilityScores`, which already guarantees all six abilities);
    `hitPointMaximum` (the stored value); `hitDicePool`; `SkillProficiencies`;
    optional `armorId` and `shieldId` (`ItemId`); optional `chosenBasis`;
    `alternativeBases` (unique `FeatureId`s, FR-076); `multiclassArmorTraining`
    (`ArmorTraining`, default empty); `flatArmorClassBonuses` (`FlatBonus`s); `armorClassFloor` (FR-080); `flatSavingThrowBonuses` (FR-079); `additionalSavingThrows` (FR-049);
    `hitPointMaximumBonuses`; `perceptionRollMode` (`RollMode`, default
    `normal`). No `initialClass` field and no `Character`.
  - Result: `CalculateDerivedStatsResult` (FR-064).
  - Lookups: the initial class, `armorId` and `shieldId` when present; all are
    attempted before `CalculateDerivedStatsContentMissing` is returned.
  - Pure host operations: `ClassLevels.withLevelIn` (FR-072), `HitDicePool.plus` (FR-073).
- **Ports used:** `ContentSource` and `Observability` (default `const` no-op); no new
  port, double or contract suite. Failure contract (`content-source-port.md`):
  `ContentLookup` absence maps to `CalculateDerivedStatsContentMissing`; a typed
  `Srd5eException` propagates (FR-044); any other `Exception` propagates (FR-074).
- **Exports:** `lib/src/character/character.dart` exports the owned types, the
  `tryCreate` result types, `isBloodied`, the use case, command, result,
  `DerivedStats` and the value objects needed to build a command and read a
  result; `lib/srd5e.dart` re-exports the same set. `DerivedStatsCalculator` and
  `DerivedStatsCalculation` stay public for callers that already hold resolved
  definitions (failure data exported once, FR-069). `ArmorClass` is exported by `d20_test`.

## 7. Observability

Answers to the seven questions (`doc/rules/observability.md` §2). (1) Can go wrong: an
unknown id (`content_missing`), a port exception or leaked plain `Exception` (FR-044,
FR-074), an inapplicable basis, a slot mismatch, or a surprising number (AC capped by
medium armor); invalid values are programmer errors. (2, 3) Operator and diagnosis: the
`calls` counter by outcome and failure attribute, the `errors` counter by `error.type`,
span error status; the result carries a breakdown for every number (FR-041) and the
missing ids or inapplicable basis. (4) Counted and timed: the table below. (5) Nothing
existing changes. (6) Monitor: `content_missing` after a content update, any
`content_source_exception`, rises in the other two failures, latency. (7) No log: a
summary would repeat span attributes (`observability.md` §7; `shared-types-and-ownership.md`
FR-043); the domain is silent (§3).

Attribute values follow `shared-types-and-ownership.md` FR-041, FR-051 and
`errors-and-results.md` FR-043: `srd5e.outcome` is `success` or `failure` only;
`error.type` appears only for a thrown exception (`content_source_exception`); the
variant of a returned failure goes in `srd5e.character.derived_stats.failure`, a
closed set: `content_missing`, `armor_class_basis_not_applicable`,
`equipment_slot_mismatch`. Keys are `character` constants or the shared
`AttributeKeys.outcome` and `AttributeKeys.errorType`.

| Signal | Type | Attributes | Purpose | Suggested monitoring |
|---|---|---|---|---|
| `srd5e.character.derived_stats.calculate` | span | `srd5e.character.multiclass` (bool), `srd5e.outcome` | One span per call; error status on returned failures and exceptions (FR-048, FR-074) | Latency percentiles; error rate |
| `srd5e.character.derived_stats.load_content` | span (child) | `srd5e.outcome` | Time in the `ContentSource` lookups; `failure` with error status when a lookup finds nothing or throws (FR-048) | Compare with the parent span |
| `srd5e.character.derived_stats.calls` | counter, `{call}` | `srd5e.outcome`, `srd5e.character.multiclass`, `srd5e.character.derived_stats.failure` (returned failures only) | Every call that returns a result or throws an `Srd5eException`, counted once at the use case (FR-074) | Alert when `content_missing` is above 0 after a content change |
| `srd5e.character.derived_stats.errors` | counter, `{error}` | `error.type` (`content_source_exception`) | Thrown `Srd5eException`s from the port, once at the use case | Alert on any increment |
| `srd5e.character.derived_stats.duration` | histogram, `s` | none | Latency of every call via `Meter.timeAsync` (no outcome attribute: `observability-ports.md` FR-031, FR-032) | p95 regression |
| `srd5e.character.derived_stats.levels` | histogram, `{level}` | none | Total character level, successful calls only | No alert |

These entries feed `doc/observability/signals.md`.

## 8. Test plan

Withdrawn ids (section 4) have no tests of their own: FR-001 and FR-007 are tested
as FR-057 and FR-058, FR-002 to FR-005 by `character-aggregate.md`.

| Id | Level | Notes |
|---|---|---|
| FR-057, FR-058, FR-075 | unit | Level 0, 1, 20, 21 and the cases table through constructors and `tryCreate`; `tryCreate` fails exactly when the constructor throws; several problems in enum order; the failure constructors `InvalidClassLevels`, `InvalidHitPointMaximumBonus`, `InvalidSkillProficiencies`, `BreakdownNotMappable` and `CalculateDerivedStatsContentMissing` reject empty collections and accept one entry (unmodifiable). |
| FR-072, FR-073 | unit | `withLevelIn` and `plus` cases, including total 20 plus one (`ArgumentError`), receiver unchanged, equality with `fromLevels`. |
| FR-059, FR-009, FR-020, FR-021 | unit, application | Band edges; 3 Fighter / 2 Rogue and 4 Cleric / 4 Fighter through the use case; Passive Perception cases for advantage, disadvantage, normal. |
| FR-012 to FR-019, FR-049, FR-079 | unit | Skill and save cases (levels 1, 5, 20); no proficiencies and all proficient give 18 and 6 modifiers; Expertise outside the proficient set (all listed at once); Wizard initial class plus a Fighter level (no Strength or Constitution save); the initial class is the first entry, not the highest level; `additionalSavingThrows` union (Fighter 5 / Rogue 15 adds Wisdom and Charisma, Rogue 14 does not); flat save bonus all and scoped; `tryCreate` fails exactly when the constructor throws. |
| FR-010, FR-056, FR-067 | unit | One Proficiency Bonus term for a skill, a save and Passive Perception (Expertise included); the constructor throws for each invalid term combination; several ability terms allowed; values equal breakdown `total`; `DerivedStats` builds `ArmorClass` and `HitPointMaximum` from `total`. |
| FR-066 | unit | `toRollModifiers` cases, including the unmappable breakdowns. |
| FR-028, FR-061, FR-070 | unit, application | Pool cases; result equals the command's pool; entry order by faces; class without a die throws (also with an empty map); an extra definition is ignored. |
| FR-029, FR-050 to FR-052, FR-060, FR-062, FR-071 | unit | Bonus, Hit Point type and Bloodied cases; result equals stored plus contributions; `tryCreate` problems for each invalid input and all at once, never throws, fails exactly when the constructor throws; d6 and d8 faces; Temporary Hit Points are not an input. |
| FR-030, FR-034 to FR-040, FR-054, FR-076 to FR-078, FR-080, FR-081 | unit | Armor Class, matrix (all 12 cells, default highest both ways, tie order), training and union cases; the Shield bonus read from a fixture entry whose bonus differs from +2; `shield` in the gaps; alternative id not supplied checked before `notApplicable`; duplicate alternative ids throw; circumstance cases, never in a breakdown; floor lifts, equals and is below; `baseValue` 13 and default 10. |
| FR-053, FR-068 | unit, application | Slot mismatch cases (`key` and `expected` asserted) with `FakeContentSource` Weapon and Tool entries; precedence cases; unknown Shield id gives `ContentMissing`; the calculator never sees missing content. |
| FR-041, FR-042 | unit, application | Terms for every output (Armored: `armorBase` equals `ArmorBase.listedBase`, the Dexterity term equals `dexterityContribution` and is omitted when 0); Total level, Proficiency Bonus and Hit Dice pool carry none; minimal level 1 character. |
| FR-043, FR-044, FR-074 | application | Missing class and armor at once (lookup order, no partial result, duplicates once); throwing source doubles: an `Srd5eException` is unchanged, a plain `Exception` is the same instance with error status and the exception recorded on `load_content` and `calculate`, no `calls` or `errors` increment, no `error.type`, no `srd5e.outcome`, no log, duration recorded. |
| FR-045, FR-046 | unit, application | Repeat calls; command not altered; mutation of result collections throws; no-op and recording `Observability` give equal results. |
| FR-047, FR-048 | application | Recording doubles pin span names, outcomes, counters, both histograms, attribute keys and values, no log. Each returned failure: `calculate` error status and outcome `failure`, one `calls` increment with the failure attribute, no `error.type`; `load_content` `failure` for `content_missing`, `success` for the other two. Port exception: error status and exception on both spans, one `calls` increment with no failure attribute, one `errors` increment, no log. Duration in all outcomes; levels only on success. |
| FR-063, FR-064, FR-069 | architecture, unit | No `Character`, aggregate or `combat` import; result and reason types exported once, operation-prefixed, none repeating a kernel name; variant fields asserted in full; `domain/` has no observability calls and imports only the `shared_kernel`, `content` and `d20_test` barrels and the sibling `character/domain/equipment/` library. |
| scenario | scenario | A level 5 Wizard through `package:srd5e/srd5e.dart` with `FakeContentSource`: Proficiency Bonus +3, the stored maximum, AC (FR-009, FR-030, FR-041, FR-050). |

- **Doubles and suites:** `FakeContentSource` and the recording `Observability`
  double from `lib/testing.dart` (`shared-types-and-ownership.md` FR-038). No new
  port, so no new contract suite (`shared-types-and-ownership.md` FR-039 covers the
  content double).
- **Mutation testing:** all of `lib/src/character/domain/` that this spec adds MUST
  be mutation tested with `--diff-base main`, score at least 80; `application/`
  SHOULD be. Boundary rows exist to kill comparison and off-by-one mutants.
- **Not covered:** none deliberately.

## 9. Open questions and decisions

Settled decisions: ownership of the types (`shared-types-and-ownership.md`
FR-008), `HitPointDie` (FR-053), ids (FR-005, FR-018), Bloodied (FR-049), the pure armor and training rules (FR-048, FR-060), and the `equipment-rules.md` edge (rank 9, listed in the header). Package readings that are not SRD
text: untrained armor keeps its AC base (the SRD names an AC loss only for the
Shield, p. 92, p. 177; "Note Armor Training", p. 19, speaks of Disadvantage and
spellcasting, not AC; FR-039); a wielded Shield is not armor for Draconic
Resilience (p. 92, p. 69); with several valid bases and none chosen the highest
wins (FR-054); Draconic Resilience is `flat 3`, `perLevel 1`, `grantedAtLevel 3`,
Sorcerer-scoped and Dwarven Toughness `flat 1`, `perLevel 1`, `grantedAtLevel 1`,
total-level scoped, the numbers always supplied by the caller (FR-051).
Amendments applied from other specs: FR-049/FR-019 (`class-rogue.md`), FR-059 `value` (`attacks.md`), FR-078 (`equipment-rules.md`), FR-079 (`magic-item-effects.md`), FR-080, FR-081 (`spell-granted-modifiers.md`); a flat save bonus is scoped by an optional ability set so Slow's Dexterity penalty fits (interpretation: the SRD names saves generally for items, one ability for the spell). **Q-1 (settled):** `withLevelIn` and `HitDicePool.plus` (FR-072, FR-073) stay as pure,
tested host conveniences; the aggregate keeps its constructors (its D-20) and need not
adopt them (small, additive, `architecture.md` §3). **Q-2 (settled):** the two enums
stay by design (`content-classes.md` D10, `shared-types-and-ownership.md` FR-047); the
by-name map in FR-040 is the one conversion, total because both use the SRD's four
words (p. 28, p. 92).

## 10. Changelog impact

`CHANGELOG.md`, under `Unreleased`:

- **Added:** the `character` foundation types (`CharacterLevel`, `ClassLevels`,
  `ProficiencyBonus`, `HitPointMaximum`, `HitDicePool`, `HitPointGain`), derived
  stats with breakdowns through `CalculateDerivedStats` and the signals
  `srd5e.character.derived_stats.*`, `isBloodied`, `ModifierBreakdown.toRollModifiers()`,
  `ClassLevels.withLevelIn` and `HitDicePool.plus`. Not **BREAKING**: all new API.
