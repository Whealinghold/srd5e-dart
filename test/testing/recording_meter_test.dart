import 'package:srd5e/src/shared_ports/observability/meter.dart';
import 'package:srd5e/src/testing/recording_meter.dart';
import 'package:test/test.dart';

import '../support/argument_error_matcher.dart';
import '../support/signal_names.dart';

const _counterName = 'srd5e.test.hits';
const _histogramName = 'srd5e.test.duration';
const _gaugeName = 'srd5e.test.level';

/// A histogram that no `RecordingMeter` created.
final class _ForeignHistogram implements Histogram {
  @override
  String get name => _histogramName;

  @override
  String get unit => 's';

  @override
  String get description => '';

  @override
  void record(num value, {Map<String, Object> attributes = const {}}) {}
}

typedef _CounterValueCase = ({String label, int value, bool valid});

const List<_CounterValueCase> _counterValueCases = [
  (label: 'zero', value: 0, valid: true),
  (label: 'one', value: 1, valid: true),
  (label: 'a large value', value: 1000000, valid: true),
  (label: 'minus one', value: -1, valid: false),
  (label: 'a large negative value', value: -1000000, valid: false),
];

typedef _DurationCase = ({String label, Duration duration, double seconds});

const List<_DurationCase> _durationCases = [
  (label: 'zero', duration: Duration.zero, seconds: 0),
  (label: '1500 ms', duration: Duration(milliseconds: 1500), seconds: 1.5),
  (
    label: '1 microsecond',
    duration: Duration(microseconds: 1),
    seconds: 0.000001,
  ),
  (label: 'two hours', duration: Duration(hours: 2), seconds: 7200),
];

typedef _UnitCase = ({String label, String unit, bool valid});

const List<_UnitCase> _unitCases = [
  (label: "'s'", unit: 's', valid: true),
  (label: 'an empty unit', unit: '', valid: false),
  (label: "'{modifier}'", unit: '{modifier}', valid: false),
  (label: "'ms'", unit: 'ms', valid: false),
  (label: "'S'", unit: 'S', valid: false),
];

typedef _RedefineCase = ({
  String label,
  InstrumentKind kind,
  String unit,
  String description,
  bool sameInstrument,
});

/// FR-038: the first definition is a counter with unit `1` and description
/// `d`; each row asks for the same name again.
const List<_RedefineCase> _redefineCases = [
  (
    label: 'the identical definition',
    kind: InstrumentKind.counter,
    unit: '1',
    description: 'd',
    sameInstrument: true,
  ),
  (
    label: 'another kind (histogram)',
    kind: InstrumentKind.histogram,
    unit: '1',
    description: 'd',
    sameInstrument: false,
  ),
  (
    label: 'another kind (gauge)',
    kind: InstrumentKind.gauge,
    unit: '1',
    description: 'd',
    sameInstrument: false,
  ),
  (
    label: 'another unit',
    kind: InstrumentKind.counter,
    unit: 's',
    description: 'd',
    sameInstrument: false,
  ),
  (
    label: 'another description',
    kind: InstrumentKind.counter,
    unit: '1',
    description: 'other',
    sameInstrument: false,
  ),
];

Object _create(
  RecordingMeter meter,
  InstrumentKind kind,
  String name, {
  String unit = '',
  String description = '',
}) => switch (kind) {
  InstrumentKind.counter => meter.createCounter(
    name,
    unit: unit,
    description: description,
  ),
  InstrumentKind.histogram => meter.createHistogram(
    name,
    unit: unit,
    description: description,
  ),
  InstrumentKind.gauge => meter.createGauge(
    name,
    unit: unit,
    description: description,
  ),
};

void main() {
  /// Requirement: doc/specs/observability-ports.md FR-026, FR-028 - a counter,
  ///   a histogram and a gauge made by RecordingMeter record the value and
  ///   attributes of each call as one measurement.
  /// Path: happy
  group('RecordingMeter records measurements', () {
    /// Requirement: doc/specs/observability-ports.md FR-026 - Counter.add
    ///   stores the instrument name, kind, unit, value and attributes.
    /// Path: happy
    test('FR-026: add records every field', () {
      final meter = RecordingMeter();
      final counter = meter.createCounter(_counterName, unit: '1');

      counter.add(3, attributes: {'k': 'v', 'n': 2});

      final record = meter.measurements.single;
      expect(record.name, _counterName);
      expect(record.kind, InstrumentKind.counter);
      expect(record.unit, '1');
      expect(record.value, 3);
      expect(record.attributes, {'k': 'v', 'n': 2});
    });

    /// Requirement: doc/specs/observability-ports.md FR-026 - the default
    ///   attributes are empty, and each call is its own measurement.
    /// Path: unhappy (empty and minimal)
    test('FR-026: add with no attributes records an empty map per call', () {
      final meter = RecordingMeter();
      final counter = meter.createCounter(_counterName);

      counter
        ..add(1)
        ..add(1, attributes: {'k': 'v'})
        ..add(1);

      expect(meter.measurements.map((m) => m.attributes), [
        <String, Object>{},
        {'k': 'v'},
        <String, Object>{},
      ]);
    });

    /// Requirement: doc/specs/observability-ports.md FR-028 - Histogram.record
    ///   keeps an int and a double as given, with the attributes.
    /// Path: happy
    test('FR-028: a histogram records int and double values', () {
      final meter = RecordingMeter();
      final histogram = meter.createHistogram(_histogramName, unit: 's');

      histogram
        ..record(2, attributes: {'a': 1})
        ..record(0.25)
        ..record(-3);

      final records = meter.measurements;
      expect(records.map((m) => m.value), [2, 0.25, -3]);
      expect(records[0].value, isA<int>());
      expect(records[1].value, isA<double>());
      expect(
        records.map((m) => m.kind),
        everyElement(InstrumentKind.histogram),
      );
      expect(records.map((m) => m.unit), everyElement('s'));
      expect(records[0].attributes, {'a': 1});
      expect(records[1].attributes, isEmpty);
    });

    /// Requirement: doc/specs/observability-ports.md FR-028 - Gauge.record
    ///   keeps an int and a double as given, with the attributes.
    /// Path: happy
    test('FR-028: a gauge records int and double values', () {
      final meter = RecordingMeter();
      final gauge = meter.createGauge(_gaugeName, unit: '{item}');

      gauge
        ..record(7, attributes: {'where': 'bag'})
        ..record(1.5);

      final records = meter.measurements;
      expect(records.map((m) => m.value), [7, 1.5]);
      expect(records[0].value, isA<int>());
      expect(records[1].value, isA<double>());
      expect(records.map((m) => m.kind), everyElement(InstrumentKind.gauge));
      expect(records.map((m) => m.unit), everyElement('{item}'));
      expect(records[0].attributes, {'where': 'bag'});
    });
  });

  /// Requirement: doc/specs/observability-ports.md FR-027 - Counter.add accepts
  ///   0 and throws ArgumentError for a negative value.
  /// Path: unhappy (boundary)
  group('RecordingMeter counter values', () {
    /// Requirement: per case
    /// Path: per case
    for (final c in _counterValueCases) {
      test('FR-027: add of ${c.label} is '
          '${c.valid ? 'accepted' : 'rejected'} '
          '[${c.valid ? 'happy' : 'unhappy (boundary)'}]', () {
        final meter = RecordingMeter();
        final counter = meter.createCounter(_counterName);

        void run() => counter.add(c.value);

        if (c.valid) {
          run();
          expect(meter.measurements.single.value, c.value);
        } else {
          expect(run, throwsArgumentErrorFor('value', c.value));
          expect(meter.measurements, isEmpty);
        }
      });
    }

    /// Requirement: doc/specs/observability-ports.md FR-027 - a rejected add
    ///   leaves the counter usable.
    /// Path: unhappy (state)
    test('FR-027: a rejected add does not stop later adds', () {
      final meter = RecordingMeter();
      final counter = meter.createCounter(_counterName);

      expect(() => counter.add(-1), throwsArgumentError);
      counter.add(2);

      expect(meter.measurements.map((m) => m.value), [2]);
    });

    /// Requirement: doc/specs/observability-ports.md FR-028 - only a counter
    ///   refuses negative values; a histogram and a gauge take them.
    /// Path: unhappy (boundary)
    test('FR-028: a histogram and a gauge accept zero and negatives', () {
      final meter = RecordingMeter();
      final histogram = meter.createHistogram(_histogramName);
      final gauge = meter.createGauge(_gaugeName);

      histogram
        ..record(0)
        ..record(-0.5);
      gauge
        ..record(0)
        ..record(-2);

      expect(meter.measurements.map((m) => m.value), [0, -0.5, 0, -2]);
    });
  });

  /// Requirement: doc/specs/observability-ports.md FR-035 - one
  ///   MeasurementRecord per measurement, in call order across all instruments.
  /// Path: happy
  group('RecordingMeter measurement order', () {
    /// Requirement: doc/specs/observability-ports.md FR-035 - calls on a
    ///   counter and a histogram interleave in call order, each with its own
    ///   kind and name.
    /// Path: happy
    test('FR-035: records are in call order across instruments', () {
      final meter = RecordingMeter();
      final counter = meter.createCounter(_counterName);
      final histogram = meter.createHistogram(_histogramName, unit: 's');

      counter.add(1);
      histogram.record(0.5);
      counter.add(2);
      histogram.record(0.25);

      expect(meter.measurements.map((m) => (m.name, m.kind, m.value)), [
        (_counterName, InstrumentKind.counter, 1),
        (_histogramName, InstrumentKind.histogram, 0.5),
        (_counterName, InstrumentKind.counter, 2),
        (_histogramName, InstrumentKind.histogram, 0.25),
      ]);
    });

    /// Requirement: doc/specs/observability-ports.md FR-035 - measurementsNamed
    ///   keeps only that instrument's records, in call order; an unknown name
    ///   gives an empty list.
    /// Path: unhappy (empty and minimal)
    test('FR-035: measurementsNamed filters by instrument name', () {
      final meter = RecordingMeter();
      final counter = meter.createCounter(_counterName);
      final gauge = meter.createGauge(_gaugeName);

      counter.add(1);
      gauge.record(9);
      counter.add(2);

      expect(meter.measurementsNamed(_counterName).map((m) => m.value), [1, 2]);
      expect(meter.measurementsNamed(_gaugeName).map((m) => m.value), [9]);
      expect(meter.measurementsNamed('srd5e.test.unknown'), isEmpty);
    });

    /// Requirement: doc/specs/observability-ports.md FR-035 - a fresh meter
    ///   has recorded nothing.
    /// Path: unhappy (empty and minimal)
    test('FR-035: a new meter has no measurements or instruments', () {
      final meter = RecordingMeter();

      expect(meter.measurements, isEmpty);
      expect(meter.instruments, isEmpty);
    });
  });

  /// Requirement: doc/specs/observability-ports.md FR-036, FR-037 - timing
  ///   records the meter's timedDuration in seconds, and a negative duration
  ///   is rejected.
  /// Path: unhappy (determinism)
  group('RecordingMeter timing', () {
    /// Requirement: per case
    /// Path: per case
    for (final c in _durationCases) {
      test('FR-036: time records ${c.label} as seconds '
          '[unhappy (determinism)]', () {
        final meter = RecordingMeter(timedDuration: c.duration);
        final histogram = meter.createHistogram(_histogramName, unit: 's');

        final result = meter.time(histogram, () => 'done');

        expect(result, 'done');
        final record = meter.measurements.single;
        expect(record.value, isA<double>());
        expect(record.value, c.seconds);
        expect(record.name, _histogramName);
        expect(record.kind, InstrumentKind.histogram);
      });

      test('FR-036: timeAsync records ${c.label} as seconds '
          '[unhappy (determinism)]', () async {
        final meter = RecordingMeter(timedDuration: c.duration);
        final histogram = meter.createHistogram(_histogramName, unit: 's');

        final result = await meter.timeAsync(histogram, () async => 7);

        expect(result, 7);
        final record = meter.measurements.single;
        expect(record.value, isA<double>());
        expect(record.value, c.seconds);
      });
    }

    /// Requirement: doc/specs/observability-ports.md FR-036 - the default
    ///   elapsed time is zero.
    /// Path: unhappy (empty and minimal)
    test('FR-036: the default timedDuration is zero', () {
      final meter = RecordingMeter();
      final histogram = meter.createHistogram(_histogramName, unit: 's');

      meter.time(histogram, () {});

      expect(meter.timedDuration, Duration.zero);
      expect(meter.measurements.single.value, 0.0);
    });

    /// Requirement: doc/specs/observability-ports.md FR-036 - the current
    ///   timedDuration is used, so changing it changes the next measurement;
    ///   attributes are recorded with it.
    /// Path: unhappy (state)
    test('FR-036: each call records the current timedDuration', () {
      final meter = RecordingMeter();
      final histogram = meter.createHistogram(_histogramName, unit: 's');

      meter.time(histogram, () {}, attributes: {'k': 'a'});
      meter.timedDuration = const Duration(seconds: 2);
      meter.time(histogram, () {}, attributes: {'k': 'b'});

      expect(meter.measurements.map((m) => m.value), [0.0, 2.0]);
      expect(meter.measurements.map((m) => m.attributes), [
        {'k': 'a'},
        {'k': 'b'},
      ]);
    });

    /// Requirement: doc/specs/observability-ports.md FR-037 - zero is accepted
    ///   by the setter, and the value is kept.
    /// Path: unhappy (boundary)
    test('FR-037: setting timedDuration to zero is accepted', () {
      final meter = RecordingMeter(timedDuration: const Duration(seconds: 1));

      meter.timedDuration = Duration.zero;

      expect(meter.timedDuration, Duration.zero);
    });

    /// Requirement: doc/specs/observability-ports.md FR-037 - one microsecond
    ///   below zero is rejected, and the earlier value is kept.
    /// Path: unhappy (boundary)
    test('FR-037: a negative timedDuration is rejected by the setter', () {
      final meter = RecordingMeter(timedDuration: const Duration(seconds: 1));
      const negative = Duration(microseconds: -1);

      expect(
        () => meter.timedDuration = negative,
        throwsArgumentErrorFor('timedDuration', negative),
      );
      expect(meter.timedDuration, const Duration(seconds: 1));
    });

    /// Requirement: doc/specs/observability-ports.md FR-037 - the constructor
    ///   rejects a negative duration too.
    /// Path: unhappy (invalid input)
    test('FR-037: a negative timedDuration is rejected by the constructor', () {
      const negative = Duration(seconds: -5);

      expect(
        () => RecordingMeter(timedDuration: negative),
        throwsArgumentErrorFor('timedDuration', negative),
      );
    });
  });

  /// Requirement: doc/specs/observability-ports.md FR-038 - creating an
  ///   instrument again returns the same one when everything matches, and
  ///   throws StateError otherwise, keeping the first definition.
  /// Path: unhappy (state)
  group('RecordingMeter instrument identity', () {
    /// Requirement: per case
    /// Path: per case
    for (final c in _redefineCases) {
      test('FR-038: asking again with ${c.label} '
          '${c.sameInstrument ? 'returns the same instrument' : 'throws'} '
          '[${c.sameInstrument ? 'happy' : 'unhappy (state)'}]', () {
        final meter = RecordingMeter();
        final first = meter.createCounter(
          _counterName,
          unit: '1',
          description: 'd',
        );

        Object again() => _create(
          meter,
          c.kind,
          _counterName,
          unit: c.unit,
          description: c.description,
        );

        if (c.sameInstrument) {
          expect(again(), same(first));
          expect(meter.instruments, [same(first)]);
        } else {
          expect(again, throwsStateError);
          expect(meter.instruments, [same(first)]);
          final kept = meter.instruments.single as Counter;
          expect(kept.unit, '1');
          expect(kept.description, 'd');
        }
      });
    }

    /// Requirement: doc/specs/observability-ports.md FR-038 - instruments with
    ///   different names are different objects, listed in creation order.
    /// Path: happy
    test('FR-038: different names give different instruments in order', () {
      final meter = RecordingMeter();

      final counter = meter.createCounter(_counterName);
      final gauge = meter.createGauge(_gaugeName);
      final histogram = meter.createHistogram(_histogramName);

      expect(meter.instruments, [same(counter), same(gauge), same(histogram)]);
    });

    /// Requirement: doc/specs/observability-ports.md FR-025, FR-038 - the
    ///   instruments expose the name, unit and description they were made with.
    /// Path: happy
    test('FR-038: instruments keep their name, unit and description', () {
      final meter = RecordingMeter();

      final counter = meter.createCounter(
        _counterName,
        unit: '1',
        description: 'hits',
      );
      final histogram = meter.createHistogram(
        _histogramName,
        unit: 's',
        description: 'time',
      );
      final gauge = meter.createGauge(
        _gaugeName,
        unit: '{item}',
        description: 'level',
      );

      expect(
        (counter.name, counter.unit, counter.description),
        (_counterName, '1', 'hits'),
      );
      expect(
        (histogram.name, histogram.unit, histogram.description),
        (_histogramName, 's', 'time'),
      );
      expect(
        (gauge.name, gauge.unit, gauge.description),
        (_gaugeName, '{item}', 'level'),
      );
    });
  });

  /// Requirement: doc/specs/observability-ports.md FR-039 - an instrument name
  ///   that is not srd5e.<context>.<noun> is an ArgumentError.
  /// Path: unhappy (invalid input)
  group('RecordingMeter instrument names', () {
    final creators = <String, Object Function(RecordingMeter, String)>{
      'createCounter': (meter, name) => meter.createCounter(name),
      'createHistogram': (meter, name) => meter.createHistogram(name),
      'createGauge': (meter, name) => meter.createGauge(name),
    };

    for (final creator in creators.entries) {
      /// Requirement: per case
      /// Path: per case
      for (final c in signalNameCases) {
        test('FR-039: ${creator.key} with ${c.label} is '
            '${c.valid ? 'accepted' : 'rejected'} '
            '[${c.valid ? 'happy' : 'unhappy (invalid input)'}]', () {
          final meter = RecordingMeter();

          void run() => creator.value(meter, c.name);

          if (c.valid) {
            run();
            expect(meter.instruments, hasLength(1));
          } else {
            expect(run, throwsArgumentErrorFor('name', c.name));
            expect(meter.instruments, isEmpty);
          }
        });
      }
    }
  });

  /// Requirement: doc/specs/observability-ports.md FR-040, FR-058 - time and
  ///   timeAsync only accept a histogram this meter created, with the unit
  ///   's'.
  /// Path: unhappy (invalid input)
  group('RecordingMeter timing histogram', () {
    /// Requirement: doc/specs/observability-ports.md FR-040 - a histogram from
    ///   another RecordingMeter and a hand-made histogram are both rejected by
    ///   time, before the body runs.
    /// Path: unhappy (invalid input)
    test('FR-040: time rejects a histogram this meter did not create', () {
      final meter = RecordingMeter();
      final other = RecordingMeter();
      final foreign = <Histogram>[
        other.createHistogram(_histogramName, unit: 's'),
        _ForeignHistogram(),
      ];

      for (final histogram in foreign) {
        var bodyRuns = 0;
        expect(
          () => meter.time(histogram, () => bodyRuns++),
          throwsArgumentErrorFor('histogram', histogram),
        );
        expect(bodyRuns, 0);
      }
      expect(meter.measurements, isEmpty);
      expect(other.measurements, isEmpty);
    });

    /// Requirement: doc/specs/observability-ports.md FR-040 - timeAsync throws
    ///   at the call, not through the returned future, and never runs the
    ///   body.
    /// Path: unhappy (invalid input)
    test('FR-040: timeAsync rejects a foreign histogram synchronously', () {
      final meter = RecordingMeter();
      final other = RecordingMeter();
      final foreign = <Histogram>[
        other.createHistogram(_histogramName, unit: 's'),
        _ForeignHistogram(),
      ];

      for (final histogram in foreign) {
        var bodyRuns = 0;
        expect(
          () => meter.timeAsync(histogram, () async => bodyRuns++),
          throwsArgumentErrorFor('histogram', histogram),
        );
        expect(bodyRuns, 0);
      }
      expect(meter.measurements, isEmpty);
    });

    /// Requirement: doc/specs/observability-ports.md FR-040 - a histogram this
    ///   meter created is accepted.
    /// Path: happy
    test('FR-040: time accepts its own histogram', () {
      final meter = RecordingMeter();
      final histogram = meter.createHistogram(_histogramName, unit: 's');

      expect(meter.time(histogram, () => 5), 5);
      expect(meter.measurements, hasLength(1));
    });

    /// Requirement: per case
    /// Path: per case
    for (final c in _unitCases) {
      test('FR-058: time with a histogram in ${c.label} is '
          '${c.valid ? 'accepted' : 'rejected'} '
          '[${c.valid ? 'happy' : 'unhappy (invalid input)'}]', () {
        final meter = RecordingMeter();
        final histogram = meter.createHistogram(_histogramName, unit: c.unit);
        var bodyRuns = 0;

        void run() => meter.time(histogram, () => bodyRuns++);

        if (c.valid) {
          run();
          expect(bodyRuns, 1);
          expect(meter.measurements, hasLength(1));
        } else {
          expect(run, throwsArgumentErrorFor('histogram.unit', c.unit));
          expect(bodyRuns, 0);
          expect(meter.measurements, isEmpty);
        }
      });

      test('FR-058: timeAsync with a histogram in ${c.label} is '
          '${c.valid ? 'accepted' : 'rejected'} '
          '[${c.valid ? 'happy' : 'unhappy (invalid input)'}]', () async {
        final meter = RecordingMeter();
        final histogram = meter.createHistogram(_histogramName, unit: c.unit);
        var bodyRuns = 0;

        Future<int> run() => meter.timeAsync(histogram, () async => bodyRuns++);

        if (c.valid) {
          await run();
          expect(bodyRuns, 1);
          expect(meter.measurements, hasLength(1));
        } else {
          expect(run, throwsArgumentErrorFor('histogram.unit', c.unit));
          expect(bodyRuns, 0);
          expect(meter.measurements, isEmpty);
        }
      });
    }
  });

  /// Requirement: doc/specs/observability-ports.md FR-010 - an attribute value
  ///   that is not a String, bool, int or double is an ArgumentError naming
  ///   the key.
  /// Path: unhappy (invalid input)
  group('RecordingMeter attribute values', () {
    /// Requirement: per case
    /// Path: per case
    for (final c in attributeValueCases) {
      final outcome = c.valid ? 'accepted' : 'rejected';
      final path = c.valid ? 'happy' : 'unhappy (invalid input)';

      test('FR-010: a counter attribute that is ${c.label} is $outcome '
          '[$path]', () {
        final meter = RecordingMeter();
        final counter = meter.createCounter(_counterName);

        void run() => counter.add(1, attributes: {'key': c.value});

        if (c.valid) {
          run();
          expect(meter.measurements.single.attributes['key'], c.value);
        } else {
          expect(run, throwsArgumentErrorFor('key', c.value));
          expect(meter.measurements, isEmpty);
        }
      });

      test('FR-010: a histogram attribute that is ${c.label} is $outcome '
          '[$path]', () {
        final meter = RecordingMeter();
        final histogram = meter.createHistogram(_histogramName);

        void run() => histogram.record(1, attributes: {'key': c.value});

        if (c.valid) {
          run();
          expect(meter.measurements.single.attributes['key'], c.value);
        } else {
          expect(run, throwsArgumentErrorFor('key', c.value));
          expect(meter.measurements, isEmpty);
        }
      });

      test('FR-010: a gauge attribute that is ${c.label} is $outcome '
          '[$path]', () {
        final meter = RecordingMeter();
        final gauge = meter.createGauge(_gaugeName);

        void run() => gauge.record(1, attributes: {'key': c.value});

        if (c.valid) {
          run();
          expect(meter.measurements.single.attributes['key'], c.value);
        } else {
          expect(run, throwsArgumentErrorFor('key', c.value));
          expect(meter.measurements, isEmpty);
        }
      });

      test('FR-010: a time attribute that is ${c.label} is $outcome '
          '[$path]', () {
        final meter = RecordingMeter();
        final histogram = meter.createHistogram(_histogramName, unit: 's');
        var bodyRuns = 0;

        void run() => meter.time(
          histogram,
          () => bodyRuns++,
          attributes: {'key': c.value},
        );

        if (c.valid) {
          run();
          expect(meter.measurements.single.attributes['key'], c.value);
        } else {
          expect(run, throwsArgumentErrorFor('key', c.value));
          expect(bodyRuns, 0);
          expect(meter.measurements, isEmpty);
        }
      });
    }
  });

  /// Requirement: doc/specs/observability-ports.md FR-047 - lists and maps the
  ///   double exposes are unmodifiable, and a stored attributes map does not
  ///   change when the caller changes the map it passed.
  /// Path: unhappy (immutability)
  group('RecordingMeter immutability', () {
    /// Requirement: doc/specs/observability-ports.md FR-047 - measurements,
    ///   measurementsNamed and instruments cannot be changed from outside.
    /// Path: unhappy (immutability)
    test('FR-047: the exposed lists are unmodifiable', () {
      final meter = RecordingMeter();
      meter.createCounter(_counterName).add(1);

      expect(() => meter.measurements.clear(), throwsUnsupportedError);
      expect(
        () => meter.measurementsNamed(_counterName).clear(),
        throwsUnsupportedError,
      );
      expect(() => meter.instruments.clear(), throwsUnsupportedError);
      expect(meter.measurements, hasLength(1));
      expect(meter.instruments, hasLength(1));
    });

    /// Requirement: doc/specs/observability-ports.md FR-047 - a record's
    ///   attributes cannot be changed.
    /// Path: unhappy (immutability)
    test('FR-047: a measurement record cannot be changed from outside', () {
      final meter = RecordingMeter();
      meter.createCounter(_counterName).add(1, attributes: {'k': 'v'});
      final record = meter.measurements.single;

      expect(() => record.attributes['k'] = 'changed', throwsUnsupportedError);
      expect(() => record.attributes['x'] = 1, throwsUnsupportedError);
      expect(record.attributes, {'k': 'v'});
    });

    /// Requirement: doc/specs/observability-ports.md FR-047 - the attributes
    ///   are copied at the call, for add, record and time.
    /// Path: unhappy (immutability)
    test('FR-047: attributes are copied when the call is made', () {
      final meter = RecordingMeter();
      final counter = meter.createCounter(_counterName);
      final histogram = meter.createHistogram(_histogramName, unit: 's');
      final passed = <String, Object>{'k': 'v'};

      counter.add(1, attributes: passed);
      meter.time(histogram, () {
        passed['k'] = 'changed';
      }, attributes: passed);
      passed['extra'] = 1;

      expect(meter.measurements[0].attributes, {'k': 'v'});
      expect(meter.measurements[1].attributes, {'k': 'changed'});
    });
  });

  /// Requirement: doc/specs/observability-ports.md FR-046 - clear removes the
  ///   measurements and keeps the instruments and timedDuration.
  /// Path: unhappy (state)
  test('FR-046: RecordingMeter.clear keeps instruments and timedDuration', () {
    final meter = RecordingMeter(timedDuration: const Duration(seconds: 3));
    final counter = meter.createCounter(_counterName);
    final histogram = meter.createHistogram(_histogramName, unit: 's');
    counter.add(1);
    meter.time(histogram, () {});

    meter.clear();

    expect(meter.measurements, isEmpty);
    expect(meter.instruments, [same(counter), same(histogram)]);
    expect(meter.timedDuration, const Duration(seconds: 3));
    counter.add(4);
    meter.time(histogram, () {});
    expect(meter.measurements.map((m) => m.value), [4, 3.0]);
  });
}
