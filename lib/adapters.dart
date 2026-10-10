/// Generic adapters that implement srd5e's ports.
///
/// These are platform-neutral and assume no particular consumer. A consumer
/// with its own backend writes its own adapter instead (see the port's
/// documentation and its contract suite).
///
/// * [SeededDiceRoller]: a `DiceRoller` that draws every die from a `Random`
///   you supply, so a seeded `Random` gives reproducible rolls.
library;

export 'src/shared_ports/adapters/seeded_dice_roller.dart'
    show SeededDiceRoller;
