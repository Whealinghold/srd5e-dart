import 'attributes.dart';

/// An instrument that counts things: a value that only goes up.
///
/// Created by [Meter.createCounter]. Attributes are per call, not bound to the
/// instrument.
abstract interface class Counter {
  /// The instrument name, exactly as given when it was created.
  String get name;

  /// The UCUM unit (an annotation such as `{modifier}` for counts of things),
  /// exactly as given when it was created. Empty when none was given.
  String get unit;

  /// The description, exactly as given when it was created.
  String get description;

  /// Adds [value] to the count, with [attributes] for this call.
  ///
  /// A recording implementation rejects a negative [value].
  void add(int value, {Attributes attributes = const {}});
}

/// An instrument that records the distribution of measurements, such as
/// durations and sizes.
///
/// Created by [Meter.createHistogram]. Attributes are per call, not bound to
/// the instrument.
abstract interface class Histogram {
  /// The instrument name, exactly as given when it was created.
  String get name;

  /// The UCUM unit, exactly as given when it was created. Durations are always
  /// seconds (`s`). Empty when none was given.
  String get unit;

  /// The description, exactly as given when it was created.
  String get description;

  /// Records one measurement of [value], with [attributes] for this call.
  void record(num value, {Attributes attributes = const {}});
}

/// An instrument that records the current value of something that goes up and
/// down.
///
/// Created by [Meter.createGauge]. Attributes are per call, not bound to the
/// instrument.
abstract interface class Gauge {
  /// The instrument name, exactly as given when it was created.
  String get name;

  /// The UCUM unit, exactly as given when it was created. Empty when none was
  /// given.
  String get unit;

  /// The description, exactly as given when it was created.
  String get description;

  /// Records the current [value], with [attributes] for this call.
  void record(num value, {Attributes attributes = const {}});
}

/// The driven port through which srd5e creates instruments and times work.
///
/// Instrument names are lowercase, dot-separated and prefixed
/// `srd5e.<context>.<noun>`. Units follow UCUM and are stated on the
/// instrument, not in its name. A use case creates its instruments once, in its
/// constructor.
///
/// **Timing.** Domain and application code may not read the clock, so
/// durations are measured here: [time] and [timeAsync] run the work, and the
/// implementation reads its own clock and records the elapsed time, in seconds
/// as a `double`, into a histogram created with `unit: 's'`. A duration
/// histogram is always recorded this way.
///
/// Production implementations MUST NOT throw of their own accord
/// (trace/time rethrow the body's own error unchanged); srd5e does not catch.
/// The recording doubles in `testing.dart` throw `ArgumentError`/`StateError`
/// on misuse by design.
///
/// The shared contract suite lives in `test/contract/meter_contract.dart` of
/// the srd5e repository. It is not exported (it needs `package:test`), but a
/// consumer can copy it to run against their own adapter.
abstract interface class Meter {
  /// Creates a [Counter] called [name].
  Counter createCounter(
    String name, {
    String unit = '',
    String description = '',
  });

  /// Creates a [Histogram] called [name].
  ///
  /// Create a duration histogram with `unit: 's'`.
  Histogram createHistogram(
    String name, {
    String unit = '',
    String description = '',
  });

  /// Creates a [Gauge] called [name].
  Gauge createGauge(String name, {String unit = '', String description = ''});

  /// Runs [body] once, returns its value, and records into [histogram] one
  /// measurement of the elapsed time in seconds, as a `double`.
  ///
  /// The time is recorded even when [body] throws, and the same object is then
  /// rethrown. The body MUST NOT return a `Future`: use `timeAsync`, because
  /// the measurement would be recorded before the future completes.
  T time<T>(
    Histogram histogram,
    T Function() body, {
    Attributes attributes = const {},
  });

  /// Runs [body] once, records into [histogram] the elapsed seconds when the
  /// returned future completes, and returns its value.
  ///
  /// The time is recorded even when the future completes with an error, which
  /// then propagates. A body that throws before it returns a future surfaces as
  /// a failed future: this method does not throw synchronously for it.
  Future<T> timeAsync<T>(
    Histogram histogram,
    Future<T> Function() body, {
    Attributes attributes = const {},
  });
}

/// A [Counter] that counts nothing.
final class _NoopCounter implements Counter {
  const _NoopCounter(this.name, this.unit, this.description);

  @override
  final String name;

  @override
  final String unit;

  @override
  final String description;

  @override
  void add(int value, {Attributes attributes = const {}}) {}
}

/// A [Histogram] that records nothing.
final class _NoopHistogram implements Histogram {
  const _NoopHistogram(this.name, this.unit, this.description);

  @override
  final String name;

  @override
  final String unit;

  @override
  final String description;

  @override
  void record(num value, {Attributes attributes = const {}}) {}
}

/// A [Gauge] that records nothing.
final class _NoopGauge implements Gauge {
  const _NoopGauge(this.name, this.unit, this.description);

  @override
  final String name;

  @override
  final String unit;

  @override
  final String description;

  @override
  void record(num value, {Attributes attributes = const {}}) {}
}

/// A [Meter] that measures nothing.
///
/// The default when no observability is injected. It is stateless and `const`.
/// Its instruments accept any value and any attributes and record nothing;
/// [time] and [timeAsync] run the body once, return its result, record nothing,
/// read no clock and let any error propagate unchanged. It does not validate
/// names, units or descriptions.
final class NoopMeter implements Meter {
  /// Creates the silent meter.
  const NoopMeter();

  @override
  Counter createCounter(
    String name, {
    String unit = '',
    String description = '',
  }) => _NoopCounter(name, unit, description);

  @override
  Histogram createHistogram(
    String name, {
    String unit = '',
    String description = '',
  }) => _NoopHistogram(name, unit, description);

  @override
  Gauge createGauge(String name, {String unit = '', String description = ''}) =>
      _NoopGauge(name, unit, description);

  @override
  T time<T>(
    Histogram histogram,
    T Function() body, {
    Attributes attributes = const {},
  }) => body();

  @override
  Future<T> timeAsync<T>(
    Histogram histogram,
    Future<T> Function() body, {
    Attributes attributes = const {},
  }) async => body();
}
