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
