import 'package:srd5e/src/shared_ports/observability/meter.dart';
import 'package:test/test.dart';

typedef _InstrumentCase = ({
  String label,
  String name,
  String unit,
  String description,
});

/// FR-034: odd definitions the no-op must accept.
const List<_InstrumentCase> _definitions = [
  (label: 'defaults', name: 'srd5e.test.thing', unit: '', description: ''),
  (label: 'an empty name', name: '', unit: '', description: ''),
  (label: 'an invalid name', name: 'Not A Name', unit: 'x', description: 'y'),
  (label: 'an odd unit', name: 'srd5e.test.thing', unit: '%%', description: ''),
  (
    label: 'a long description',
    name: 'srd5e.test.thing',
    unit: 's',
    description: 'a description with spaces, commas and punctuation.',
  ),
];

void main() {
  /// Requirement: doc/specs/observability-ports.md FR-033, FR-034 and FR-064 -
  ///   NoopMeter accepts anything, records nothing and reads no clock.
  /// Path: happy
  group('NoopMeter', () {
    /// Requirement: per case
    /// Path: per case
    for (final c in _definitions) {
      test('FR-034: create methods accept ${c.label} and return named '
          'instruments [unhappy (empty and minimal)]', () {
        const meter = NoopMeter();

        final counter = meter.createCounter(
          c.name,
          unit: c.unit,
          description: c.description,
        );
        final histogram = meter.createHistogram(
          c.name,
          unit: c.unit,
          description: c.description,
        );
        final gauge = meter.createGauge(
          c.name,
          unit: c.unit,
          description: c.description,
        );

        expect(counter.name, c.name);
        expect(counter.unit, c.unit);
        expect(counter.description, c.description);
        expect(histogram.name, c.name);
        expect(histogram.unit, c.unit);
        expect(histogram.description, c.description);
        expect(gauge.name, c.name);
        expect(gauge.unit, c.unit);
        expect(gauge.description, c.description);
      });
    }

    /// Requirement: doc/specs/observability-ports.md FR-064 - a no-op counter
    ///   accepts zero, a positive and a negative value, with any attributes.
    /// Path: unhappy (empty and minimal)
    test('FR-064: a counter accepts any value and any attributes', () {
      final counter = const NoopMeter().createCounter('srd5e.test.count');

      void addAll() {
        counter.add(0);
        counter.add(5);
        counter.add(-3, attributes: {'k': Object(), 'n': 1});
      }

      expect(addAll, returnsNormally);
    });

    /// Requirement: doc/specs/observability-ports.md FR-064 - a no-op
    ///   histogram and gauge accept negative and fractional values.
    /// Path: unhappy (empty and minimal)
    test('FR-064: a histogram and a gauge accept any number', () {
      const meter = NoopMeter();
      final histogram = meter.createHistogram('srd5e.test.sizes');
      final gauge = meter.createGauge('srd5e.test.level');

      void recordAll() {
        histogram.record(-1);
        histogram.record(0.25, attributes: {'k': 'v'});
        gauge.record(-7.5);
        gauge.record(1 << 40, attributes: {'k': Object()});
      }

      expect(recordAll, returnsNormally);
    });

    /// Requirement: doc/specs/observability-ports.md FR-033 - time runs the
    ///   body once and returns its result, whatever histogram it is given.
    /// Path: happy
    test('FR-033: time runs the body once and returns its result', () {
      const meter = NoopMeter();
      final histogram = meter.createHistogram('srd5e.test.duration');
      var calls = 0;

      final result = meter.time(histogram, () {
        calls++;
        return 'v';
      });

      expect(result, 'v');
      expect(calls, 1);
    });

    /// Requirement: doc/specs/observability-ports.md FR-033 - timeAsync
    ///   returns the future's value after running the body once.
    /// Path: happy
    test(
      'FR-033: timeAsync runs the body once and returns its value',
      () async {
        const meter = NoopMeter();
        final histogram = meter.createHistogram('srd5e.test.duration');
        var calls = 0;

        final result = await meter.timeAsync(histogram, () async {
          calls++;
          return 3;
        });

        expect(result, 3);
        expect(calls, 1);
      },
    );

    /// Requirement: doc/specs/observability-ports.md FR-033 and FR-055 - the
    ///   no-op does not validate the histogram (a unit other than seconds, an
    ///   instrument from another meter) and records nothing.
    /// Path: unhappy (invalid input)
    test(
      'FR-033: time accepts a histogram that is not a duration histogram',
      () {
        const meter = NoopMeter();
        final other = const NoopMeter().createHistogram('x', unit: '{thing}');

        expect(meter.time(other, () => 1), 1);
      },
    );
  });
}
