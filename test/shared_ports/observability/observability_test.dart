import 'package:srd5e/src/shared_ports/observability/log_level.dart';
import 'package:srd5e/src/shared_ports/observability/logger.dart';
import 'package:srd5e/src/shared_ports/observability/meter.dart';
import 'package:srd5e/src/shared_ports/observability/observability.dart';
import 'package:srd5e/src/shared_ports/observability/tracer.dart';
import 'package:srd5e/src/testing/recording_logger.dart';
import 'package:srd5e/src/testing/recording_meter.dart';
import 'package:srd5e/src/testing/recording_tracer.dart';
import 'package:test/test.dart';

/// Asserts that every port of [observability] behaves as its no-op: nothing
/// enabled, the body of `trace` and `time` runs, and nothing is recorded.
void _expectAllNoops(Observability observability) {
  var traceCalls = 0;
  var timeCalls = 0;
  var attributeCalls = 0;

  final enabled = [
    for (final level in LogLevel.values) observability.logger.isEnabled(level),
  ];
  observability.logger.fine(
    'event',
    attributes: () {
      attributeCalls++;
      return {};
    },
  );
  final traced = observability.tracer.trace('srd5e.test.work', (span) {
    traceCalls++;
    return 'traced';
  });
  final timed = observability.meter.time(
    observability.meter.createHistogram('srd5e.test.duration', unit: 's'),
    () {
      timeCalls++;
      return 'timed';
    },
  );

  expect(enabled, everyElement(isFalse));
  expect(attributeCalls, 0);
  expect(traced, 'traced');
  expect(traceCalls, 1);
  expect(timed, 'timed');
  expect(timeCalls, 1);
}

typedef _OnlyOneCase = ({
  String label,
  Observability Function() build,
  List<String> noops,
});

void main() {
  /// Requirement: doc/specs/observability-ports.md FR-041 - Observability has
  ///   a const constructor with logger, tracer and meter, each defaulting to
  ///   its no-op.
  /// Path: happy
  group('Observability', () {
    /// Requirement: doc/specs/observability-ports.md FR-041 - the default
    ///   constructor is const and holds the three no-ops.
    /// Path: happy
    test('FR-041: const Observability() holds the three no-ops', () {
      const observability = Observability();

      expect(observability.logger, isA<NoopLogger>());
      expect(observability.tracer, isA<NoopTracer>());
      expect(observability.meter, isA<NoopMeter>());
    });

    /// Requirement: doc/specs/observability-ports.md FR-041 - supplied ports
    ///   are kept exactly.
    /// Path: happy
    test('FR-041: supplied ports are held as given', () {
      final logger = RecordingLogger();
      final tracer = RecordingTracer();
      final meter = RecordingMeter();

      final observability = Observability(
        logger: logger,
        tracer: tracer,
        meter: meter,
      );

      expect(observability.logger, same(logger));
      expect(observability.tracer, same(tracer));
      expect(observability.meter, same(meter));
    });

    /// Requirement: doc/specs/observability-ports.md FR-042 - none is the
    ///   canonical const NoopObservability.
    /// Path: happy
    test('FR-042: none is const NoopObservability()', () {
      expect(identical(Observability.none, const NoopObservability()), isTrue);
      expect(Observability.none, isA<NoopObservability>());
    });

    /// Requirement: doc/specs/observability-ports.md FR-042 and FR-062 - an
    ///   all-default bundle equals none (by value, since a plain const
    ///   Observability() is a different class from NoopObservability).
    /// Path: happy
    test('FR-042: the default bundle equals none', () {
      expect(const Observability(), Observability.none);
      expect(const Observability().hashCode, Observability.none.hashCode);
    });

    /// Requirement: doc/specs/observability-ports.md FR-041 - bundles with a
    ///   different port are not equal.
    /// Path: unhappy (boundary)
    test('FR-041: a bundle with another port differs from none', () {
      final logger = RecordingLogger();
      final other = Observability(logger: logger);

      expect(other, isNot(Observability.none));
      expect(other, Observability(logger: logger));
      expect(other.hashCode, Observability(logger: logger).hashCode);
    });

    /// Requirement: doc/specs/observability-ports.md FR-062 - NoopObservability
    ///   is const-constructible and its ports are the no-op types.
    /// Path: happy
    test('FR-062: NoopObservability is const with the three no-op ports', () {
      const noop = NoopObservability();

      expect(identical(noop, const NoopObservability()), isTrue);
      expect(noop.logger, same(const NoopLogger()));
      expect(noop.tracer, same(const NoopTracer()));
      expect(noop.meter, same(const NoopMeter()));
    });

    /// Requirement: per case
    /// Path: per case
    for (final c in <_OnlyOneCase>[
      (
        label: 'only a logger',
        build: () => Observability(logger: RecordingLogger()),
        noops: ['tracer', 'meter'],
      ),
      (
        label: 'only a tracer',
        build: () => Observability(tracer: RecordingTracer()),
        noops: ['logger', 'meter'],
      ),
      (
        label: 'only a meter',
        build: () => Observability(meter: RecordingMeter()),
        noops: ['logger', 'tracer'],
      ),
    ]) {
      test('FR-043: supplying ${c.label} leaves the other two as no-ops '
          '[unhappy (empty and minimal)]', () {
        final observability = c.build();

        final noops = [
          if (observability.logger is NoopLogger) 'logger',
          if (observability.tracer is NoopTracer) 'tracer',
          if (observability.meter is NoopMeter) 'meter',
        ];

        expect(noops, c.noops);
      });
    }

    /// Requirement: doc/specs/observability-ports.md FR-043 - each default
    ///   port, exercised through the bundle, behaves as a no-op.
    /// Path: unhappy (empty and minimal)
    test('FR-043: the default ports behave as no-ops', () {
      _expectAllNoops(const Observability());
    });

    /// Requirement: doc/specs/observability-ports.md FR-042 and FR-043 -
    ///   Observability.none behaves as a no-op through all three ports.
    /// Path: happy
    test('FR-042: Observability.none behaves as a no-op', () {
      _expectAllNoops(Observability.none);
    });
  });
}
