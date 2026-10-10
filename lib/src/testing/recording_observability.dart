import '../shared_ports/observability/log_level.dart';
import '../shared_ports/observability/observability.dart';
import 'recording_logger.dart';
import 'recording_meter.dart';
import 'recording_tracer.dart';

/// A test double bundle: one [RecordingLogger], one [RecordingTracer] and one
/// [RecordingMeter], and the [Observability] that wraps them.
///
/// Pass [observability] to the use case under test, then read [logger],
/// [tracer] and [meter] to assert what it emitted.
final class RecordingObservability {
  /// Creates the three recording doubles.
  ///
  /// The logger records events at [minLevel] and above; the meter's timing
  /// operations record [timedDuration].
  RecordingObservability({
    LogLevel minLevel = LogLevel.finest,
    Duration timedDuration = Duration.zero,
  }) : logger = RecordingLogger(minLevel: minLevel),
       tracer = RecordingTracer(),
       meter = RecordingMeter(timedDuration: timedDuration);

  /// The recording logger.
  final RecordingLogger logger;

  /// The recording tracer.
  final RecordingTracer tracer;

  /// The recording meter.
  final RecordingMeter meter;

  /// An [Observability] wrapping exactly [logger], [tracer] and [meter].
  late final Observability observability = Observability(
    logger: logger,
    tracer: tracer,
    meter: meter,
  );

  /// Removes the log, span and measurement records. Instruments, `minLevel`
  /// and `timedDuration` are kept, and earlier instruments keep recording.
  void clear() {
    logger.clear();
    tracer.clear();
    meter.clear();
  }
}
