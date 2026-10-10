import 'package:srd5e/src/shared_ports/observability/log_level.dart';
import 'package:srd5e/src/shared_ports/observability/logger.dart';
import 'package:srd5e/src/shared_ports/observability/observability.dart';
import 'package:srd5e/src/testing/recording_logger.dart';
import 'package:srd5e/src/testing/recording_meter.dart';
import 'package:srd5e/src/testing/recording_observability.dart';
import 'package:srd5e/src/testing/recording_tracer.dart';
import 'package:test/test.dart';

const _spanName = 'srd5e.test.work';
const _counterName = 'srd5e.test.hits';
const _histogramName = 'srd5e.test.duration';

typedef _MinLevelCase = ({String label, LogLevel minLevel});

void main() {
  /// Requirement: doc/specs/observability-ports.md FR-045 - the bundle creates
  ///   one recording logger, tracer and meter and exposes them and an
  ///   Observability wrapping exactly those three objects.
  /// Path: happy
  group('RecordingObservability composition', () {
    /// Requirement: doc/specs/observability-ports.md FR-045 - the three
    ///   doubles are the recording types.
    /// Path: happy
    test('FR-045: it creates a recording logger, tracer and meter', () {
      final recording = RecordingObservability();

      expect(recording.logger, isA<RecordingLogger>());
      expect(recording.tracer, isA<RecordingTracer>());
      expect(recording.meter, isA<RecordingMeter>());
    });

    /// Requirement: doc/specs/observability-ports.md FR-045 - observability
    ///   wraps exactly the three exposed objects, and is the same bundle on
    ///   every read.
    /// Path: happy
    test('FR-045: observability wraps the same three objects', () {
      final recording = RecordingObservability();

      final observability = recording.observability;

      expect(observability.logger, same(recording.logger));
      expect(observability.tracer, same(recording.tracer));
      expect(observability.meter, same(recording.meter));
      expect(recording.observability, same(observability));
    });

    /// Requirement: doc/specs/observability-ports.md FR-045 - what a use case
    ///   emits through observability is visible on the exposed doubles.
    /// Path: happy
    test('FR-045: signals sent through observability reach the doubles', () {
      final recording = RecordingObservability();
      final observability = recording.observability;

      observability.logger.info('hello');
      observability.tracer.trace(_spanName, (span) {});
      observability.meter.createCounter(_counterName).add(2);

      expect(recording.logger.records.single.message, 'hello');
      expect(recording.tracer.spans.single.name, _spanName);
      expect(recording.meter.measurements.single.value, 2);
    });

    /// Requirement: doc/specs/observability-ports.md FR-045 - two bundles do
    ///   not share doubles.
    /// Path: unhappy (state)
    test('FR-045: two bundles are independent', () {
      final first = RecordingObservability();
      final second = RecordingObservability();

      first.logger.info('only first');

      expect(second.logger.records, isEmpty);
      expect(first.logger, isNot(same(second.logger)));
      expect(first.tracer, isNot(same(second.tracer)));
      expect(first.meter, isNot(same(second.meter)));
    });
  });

  /// Requirement: doc/specs/observability-ports.md FR-045 - the optional
  ///   minLevel and timedDuration are handed to the logger and the meter.
  /// Path: unhappy (boundary)
  group('RecordingObservability options', () {
    /// Requirement: doc/specs/observability-ports.md FR-045 - the defaults are
    ///   the lowest level and a zero duration.
    /// Path: unhappy (empty and minimal)
    test('FR-045: defaults are finest and a zero duration', () {
      final recording = RecordingObservability();

      expect(recording.logger.minLevel, LogLevel.finest);
      expect(recording.meter.timedDuration, Duration.zero);
      expect(recording.logger.isEnabled(LogLevel.finest), isTrue);
    });

    /// Requirement: per case
    /// Path: per case
    for (final c in <_MinLevelCase>[
      for (final level in LogLevel.values) (label: level.name, minLevel: level),
    ]) {
      test('FR-045: minLevel ${c.label} reaches the logger '
          '[unhappy (boundary)]', () {
        final recording = RecordingObservability(minLevel: c.minLevel);

        expect(recording.logger.minLevel, c.minLevel);
        expect(recording.observability.logger.isEnabled(c.minLevel), isTrue);
        for (final level in LogLevel.values) {
          expect(
            recording.observability.logger.isEnabled(level),
            level.index >= c.minLevel.index,
            reason: '${level.name} with minLevel ${c.label}',
          );
        }
      });
    }

    /// Requirement: doc/specs/observability-ports.md FR-045 - timedDuration
    ///   reaches the meter, so time records it in seconds through the bundle.
    /// Path: unhappy (determinism)
    test('FR-045: timedDuration reaches the meter', () {
      final recording = RecordingObservability(
        timedDuration: const Duration(milliseconds: 1500),
      );
      final meter = recording.observability.meter;
      final histogram = meter.createHistogram(_histogramName, unit: 's');

      meter.time(histogram, () {});

      expect(recording.meter.timedDuration, const Duration(milliseconds: 1500));
      expect(recording.meter.measurements.single.value, 1.5);
    });

    /// Requirement: doc/specs/observability-ports.md FR-045 - a negative
    ///   timedDuration is rejected by the bundle's meter.
    /// Path: unhappy (invalid input)
    test('FR-045: a negative timedDuration is rejected', () {
      expect(
        () =>
            RecordingObservability(timedDuration: const Duration(seconds: -1)),
        throwsArgumentError,
      );
    });
  });

  /// Requirement: doc/specs/observability-ports.md FR-046 - clear removes the
  ///   log, span and measurement records and keeps instruments, minLevel and
  ///   timedDuration.
  /// Path: unhappy (state)
  group('RecordingObservability.clear', () {
    /// Requirement: doc/specs/observability-ports.md FR-046 - all three record
    ///   lists are emptied.
    /// Path: unhappy (state)
    test('FR-046: clear empties the logs, spans and measurements', () {
      final recording = RecordingObservability();
      final observability = recording.observability;
      observability.logger.info('x');
      observability.tracer.trace(_spanName, (span) {});
      observability.meter.createCounter(_counterName).add(1);

      recording.clear();

      expect(recording.logger.records, isEmpty);
      expect(recording.tracer.spans, isEmpty);
      expect(recording.meter.measurements, isEmpty);
    });

    /// Requirement: doc/specs/observability-ports.md FR-046 - minLevel,
    ///   timedDuration and instruments are kept, and an instrument made before
    ///   the clear keeps recording.
    /// Path: unhappy (state)
    test('FR-046: clear keeps settings and earlier instruments usable', () {
      final recording = RecordingObservability(
        minLevel: LogLevel.warning,
        timedDuration: const Duration(seconds: 2),
      );
      final meter = recording.observability.meter;
      final counter = meter.createCounter(_counterName);
      final histogram = meter.createHistogram(_histogramName, unit: 's');
      counter.add(1);

      recording.clear();

      expect(recording.logger.minLevel, LogLevel.warning);
      expect(recording.meter.timedDuration, const Duration(seconds: 2));
      expect(recording.meter.instruments, [same(counter), same(histogram)]);
      counter.add(5);
      meter.time(histogram, () {});
      expect(recording.meter.measurements.map((m) => m.value), [5, 2.0]);
      expect(recording.observability.logger.isEnabled(LogLevel.info), isFalse);
    });

    /// Requirement: doc/specs/observability-ports.md FR-046 - clearing an
    ///   empty bundle is harmless, and the observability object is unchanged.
    /// Path: unhappy (empty and minimal)
    test('FR-046: clear on an empty bundle changes nothing', () {
      final recording = RecordingObservability();
      final before = recording.observability;

      recording
        ..clear()
        ..clear();

      expect(recording.observability, same(before));
      expect(recording.logger.records, isEmpty);
    });
  });

  /// Requirement: doc/specs/observability-ports.md FR-045 - the wrapped
  ///   Observability is an Observability, not a no-op.
  /// Path: happy
  test('FR-045: observability is not the none bundle', () {
    final recording = RecordingObservability();

    expect(recording.observability, isA<Observability>());
    expect(recording.observability, isNot(Observability.none));
  });
}
