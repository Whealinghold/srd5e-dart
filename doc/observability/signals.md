# Signal catalogue

Every metric, span and log event srd5e emits. Must match the code (see
[observability rules](../rules/observability.md), §2 and §10). Consumers use
this to build dashboards and alerts; srd5e cannot run alerts itself.

Add a row for each signal when it is introduced. Rows below come from specs
still in `draft`; they become binding when the code lands.

| Name | Type | Unit | Attributes | Emitted by | Purpose | Suggested monitoring |
|---|---|---|---|---|---|---|
| `srd5e.combat.resolve_spell_outcome_table` | span | n/a | `srd5e.combat.operation`, `srd5e.outcome`, `srd5e.combat.result` (`spell_table_rolled`, `spell_table_refused`), `srd5e.combat.result_class` (`applied`, `refused`), `srd5e.combat.spell_table` | `ResolveSpellOutcomeTable` | The path of one table resolution | Sample traces; alert on error-status spans (a dice port failure) |
| `srd5e.combat.spell_table_rolls` | counter | `{roll}` | `srd5e.combat.spell_table`, `srd5e.combat.table_outcome` | `ResolveSpellOutcomeTable` | Rule outcome of every printed-table roll, so a stuck or biased roller shows | Compare each table's share with its printed band widths (for example Confusion `does_nothing` is 5 in 10; Very familiar Mishap is 5 in 100); a share near 0% or 100% over at least 200 rolls points at the roller |
| `srd5e.combat.containment.ended` | counter | `{containment}` | `srd5e.combat.containment.end_reason` (`escaped`, `pulled_out`, `regurgitated`, `disgorged`, `container_died`, `escaped_corpse`, `grapple_ended`, `occupant_removed`) | The containment use cases that release occupants | How containments end (one per release) | `occupant_removed` above 50 percent over a day: the host removes occupants without releasing them; `regurgitated` far from what thresholds predict suggests wrong damage reports |
| `srd5e.combat.containment.occupants` | histogram | `{containment}` | `srd5e.combat.operation` | The containment use cases whose result carries a `Containments` | Record count of each result carrying a `Containments` | p99 above 50 in one encounter: a host that never releases |
| `srd5e.combat.enter_container` | span | n/a | `srd5e.combat.operation`, `srd5e.outcome`, `srd5e.combat.result`, `srd5e.combat.result_class` (`applied`, `refused`, `invalid`) | `EnterContainer` | The path of one enter-container call | Sample traces; alert on error-status spans (`invalid` results and thrown exceptions) |
| `srd5e.combat.exit_container` | span | n/a | as `enter_container` | `ExitContainer` | The path of one exit-container call | as `enter_container` |
| `srd5e.combat.advance_container_turn` | span | n/a | as `enter_container` | `AdvanceContainerTurn` | The path of one container-turn advance | as `enter_container` |
| `srd5e.combat.resolve_regurgitation` | span | n/a | as `enter_container` | `ResolveRegurgitation` | The path of one regurgitation check | as `enter_container` |
| `srd5e.combat.release_occupants` | span | n/a | as `enter_container` | `ReleaseOccupants` | The path of one release call | as `enter_container` |
