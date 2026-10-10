/// Test doubles for srd5e's ports, for use in the tests of code built on
/// srd5e.
///
/// * [FixedDiceRoller]: a `DiceRoller` whose faces you choose, in order, with
///   `FixedDiceRoller.minimum()` and `FixedDiceRoller.maximum()` for the
///   extremes.
/// * [CallbackDiceRoller]: a `DiceRoller` answered by a function you supply,
///   to simulate failures and contract breaches.
/// * [RecordingObservability]: a [RecordingLogger], [RecordingTracer] and
///   [RecordingMeter] that store what a use case emits, plus the
///   `Observability` wrapping them. Read [LogRecord], [SpanRecord] and
///   [MeasurementRecord] to assert on it. The recording doubles throw
///   [ArgumentError] or [StateError] on misuse (a bad span or instrument name,
///   an unsupported attribute value, a write to a span that has ended), by
///   design, so a mistake in your code shows up in your tests.
///
/// Import this library from tests only.
library;

export 'src/testing/callback_dice_roller.dart' show CallbackDiceRoller;
export 'src/testing/fixed_dice_roller.dart' show FixedDiceRoller;
export 'src/testing/recording_logger.dart' show LogRecord, RecordingLogger;
export 'src/testing/recording_meter.dart'
    show InstrumentKind, MeasurementRecord, RecordingMeter;
export 'src/testing/recording_observability.dart' show RecordingObservability;
export 'src/testing/recording_tracer.dart' show RecordingTracer, SpanRecord;
