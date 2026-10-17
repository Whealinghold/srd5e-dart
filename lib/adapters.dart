/// Generic adapters that implement srd5e's ports.
///
/// These are platform-neutral and assume no particular consumer. A consumer
/// with its own backend writes its own adapter instead (see the port's
/// documentation and its contract suite).
///
/// * [SeededDiceRoller]: a `DiceRoller` that draws every die from a `Random`
///   you supply, so a seeded `Random` gives reproducible rolls.
/// * [JsonContentSetDecoder]: the `ContentSetDecoder` for the content JSON
///   envelope, reporting every problem found in one pass.
/// * [InMemoryContentSource]: a `ContentSource` over an in-memory list of
///   entries.
/// * [BundledContentSource]: the `ContentSource` over the embedded SRD
///   content documents; throws [BundledContentInvalid] when the bundle does
///   not decode or the merged entries fail cross-reference validation.
library;

export 'src/content/adapters/bundled_content_source.dart'
    show BundledContentInvalid, BundledContentSource;
export 'src/content/adapters/in_memory_content_source.dart'
    show InMemoryContentSource;
export 'src/content/adapters/json_content_set_decoder.dart'
    show JsonContentSetDecoder;
export 'src/shared_ports/adapters/seeded_dice_roller.dart'
    show SeededDiceRoller;
