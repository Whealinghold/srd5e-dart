import 'dart:collection' show UnmodifiableListView, UnmodifiableMapView;

import 'package:meta/meta.dart';

import '../shared_ports/observability/attributes.dart';
import '../shared_ports/observability/meter.dart';
import 'recording_support.dart';

/// The kind of an instrument, as recorded on a [MeasurementRecord].
enum InstrumentKind {
  /// A [Counter].
  counter,

  /// A [Histogram].
  histogram,

  /// A [Gauge].
  gauge,
}

/// One measurement stored by a [RecordingMeter].
///
/// Immutable: [attributes] is an unmodifiable copy.
@immutable
final class MeasurementRecord {
  /// Creates a record. Used by [RecordingMeter].
  MeasurementRecord({
    required this.name,
    required this.kind,
    required this.unit,
    required this.value,
    required Attributes attributes,
  }) : attributes = UnmodifiableMapView(Map<String, Object>.of(attributes));

  /// The name of the instrument the value was recorded into.
  final String name;

  /// The kind of that instrument.
  final InstrumentKind kind;

  /// The instrument's unit.
  final String unit;

  /// The value: the amount added to a counter, or the value recorded. A
  /// duration is in seconds, as a `double`.
  final num value;

  /// The attributes of the call. Unmodifiable.
  final Attributes attributes;
}

/// What the three recording instruments share.
abstract class _RecordingInstrument {
  _RecordingInstrument(
    this.meter,
    this.kind,
    this.name,
    this.unit,
    this.description,
  );

  final RecordingMeter meter;
  final InstrumentKind kind;
  final String name;
  final String unit;
  final String description;

  void _record(num value, Attributes attributes) {
    meter._measurements.add(
      MeasurementRecord(
        name: name,
        kind: kind,
        unit: unit,
        value: value,
        attributes: copyAttributes(attributes),
      ),
    );
  }
}

final class _RecordingCounter extends _RecordingInstrument implements Counter {
  _RecordingCounter(
    RecordingMeter meter,
    String name,
    String unit,
    String description,
  ) : super(meter, InstrumentKind.counter, name, unit, description);

  @override
  void add(int value, {Attributes attributes = const {}}) {
    if (value < 0) {
      throw ArgumentError.value(value, 'value', 'a counter only goes up');
    }
    _record(value, attributes);
  }
}

final class _RecordingHistogram extends _RecordingInstrument
    implements Histogram {
  _RecordingHistogram(
    RecordingMeter meter,
    String name,
    String unit,
    String description,
  ) : super(meter, InstrumentKind.histogram, name, unit, description);

  @override
  void record(num value, {Attributes attributes = const {}}) =>
      _record(value, attributes);
}

final class _RecordingGauge extends _RecordingInstrument implements Gauge {
  _RecordingGauge(
    RecordingMeter meter,
    String name,
    String unit,
    String description,
  ) : super(meter, InstrumentKind.gauge, name, unit, description);

  @override
  void record(num value, {Attributes attributes = const {}}) =>
      _record(value, attributes);
}

/// A test double [Meter] that stores one [MeasurementRecord] per measurement.
///
/// Timing is deterministic: [time] and [timeAsync] record [timedDuration]
/// (default zero) converted to seconds, and read no clock. Misuse throws, so a
/// mistake in a use case shows up in its tests:
///
/// * an [ArgumentError] for an instrument name that is not
///   `srd5e.<context>.<noun>` (lowercase, at least three dot-separated parts,
///   each starting with a letter), for a negative counter value, for an
///   attribute value that is not a `String`, `bool`, `int` or `double`, and
///   for timing into a histogram that this meter did not create or whose unit
///   is not `s`;
/// * a [StateError] for creating an instrument whose name is already taken by a
///   different kind, unit or description (the first definition is kept).
///
/// Creating an instrument again with identical name, kind, unit and description
/// returns the same instrument. The double is mutable: it accumulates
/// measurements.
final class RecordingMeter implements Meter {
  /// Creates a meter whose timing operations record [timedDuration].
  RecordingMeter({Duration timedDuration = Duration.zero}) {
    this.timedDuration = timedDuration;
  }

  Duration _timedDuration = Duration.zero;
  final Map<String, _RecordingInstrument> _instruments = {};
  final List<MeasurementRecord> _measurements = [];

  /// The elapsed time [time] and [timeAsync] record. Never negative.
  Duration get timedDuration => _timedDuration;

  /// Sets the elapsed time to record. Throws an [ArgumentError] for a negative
  /// duration.
  set timedDuration(Duration value) {
    if (value.isNegative) {
      throw ArgumentError.value(value, 'timedDuration', 'must not be negative');
    }
    _timedDuration = value;
  }

  /// The measurements recorded so far, in call order across all instruments.
  /// Unmodifiable.
  List<MeasurementRecord> get measurements =>
      UnmodifiableListView(_measurements);

  /// The measurements recorded into the instrument called [name], in call
  /// order. Unmodifiable.
  List<MeasurementRecord> measurementsNamed(String name) =>
      UnmodifiableListView([
        for (final measurement in _measurements)
          if (measurement.name == name) measurement,
      ]);

  /// The instruments created so far ([Counter], [Histogram] and [Gauge]
  /// objects), in creation order. Unmodifiable.
  List<Object> get instruments => UnmodifiableListView(_instruments.values);

  /// Forgets the recorded measurements. The instruments and [timedDuration]
  /// are kept, and earlier instruments stay valid and keep recording.
  void clear() => _measurements.clear();

  T _obtain<T extends _RecordingInstrument>(
    String name,
    InstrumentKind kind,
    String unit,
    String description,
    T Function() create,
  ) {
    requireSignalName(name, 'name');
    final existing = _instruments[name];
    if (existing == null) {
      final created = create();
      _instruments[name] = created;
      return created;
    }
    if (existing.kind != kind ||
        existing.unit != unit ||
        existing.description != description) {
      throw StateError(
        'Instrument $name already exists as a ${existing.kind.name} with '
        'unit "${existing.unit}" and description "${existing.description}".',
      );
    }
    return existing as T;
  }

  @override
  Counter createCounter(
    String name, {
    String unit = '',
    String description = '',
  }) => _obtain<_RecordingCounter>(
    name,
    InstrumentKind.counter,
    unit,
    description,
    () => _RecordingCounter(this, name, unit, description),
  );

  @override
  Histogram createHistogram(
    String name, {
    String unit = '',
    String description = '',
  }) => _obtain<_RecordingHistogram>(
    name,
    InstrumentKind.histogram,
    unit,
    description,
    () => _RecordingHistogram(this, name, unit, description),
  );

  @override
  Gauge createGauge(String name, {String unit = '', String description = ''}) =>
      _obtain<_RecordingGauge>(
        name,
        InstrumentKind.gauge,
        unit,
        description,
        () => _RecordingGauge(this, name, unit, description),
      );

  /// Checks that [histogram] may be timed into, and that [attributes] are
  /// valid, before any work runs.
  _RecordingHistogram _durationHistogram(
    Histogram histogram,
    Attributes attributes,
  ) {
    if (histogram is! _RecordingHistogram ||
        !identical(histogram.meter, this)) {
      throw ArgumentError.value(
        histogram,
        'histogram',
        'was not created by this RecordingMeter',
      );
    }
    if (histogram.unit != 's') {
      throw ArgumentError.value(
        histogram.unit,
        'histogram.unit',
        'a duration histogram has the unit "s" (seconds)',
      );
    }
    copyAttributes(attributes);
    return histogram;
  }

  double get _elapsedSeconds =>
      _timedDuration.inMicroseconds / Duration.microsecondsPerSecond;

  @override
  T time<T>(
    Histogram histogram,
    T Function() body, {
    Attributes attributes = const {},
  }) {
    final target = _durationHistogram(histogram, attributes);
    try {
      return body();
    } finally {
      target.record(_elapsedSeconds, attributes: attributes);
    }
  }

  @override
  Future<T> timeAsync<T>(
    Histogram histogram,
    Future<T> Function() body, {
    Attributes attributes = const {},
  }) => _timeAsync(_durationHistogram(histogram, attributes), body, attributes);

  Future<T> _timeAsync<T>(
    _RecordingHistogram target,
    Future<T> Function() body,
    Attributes attributes,
  ) async {
    try {
      return await body();
    } finally {
      target.record(_elapsedSeconds, attributes: attributes);
    }
  }
}
