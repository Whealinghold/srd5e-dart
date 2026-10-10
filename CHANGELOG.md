# Changelog

All notable changes to this package are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the package
follows [Semantic Versioning](https://semver.org/) (see
`doc/rules/architecture.md` §7).

## Unreleased

### Added

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
