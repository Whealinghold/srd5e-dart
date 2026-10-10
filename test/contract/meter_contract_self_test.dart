import 'package:srd5e/src/shared_ports/observability/attributes.dart';
import 'package:srd5e/src/shared_ports/observability/meter.dart';
import 'package:test/test.dart';

import 'meter_contract.dart';

/// A meter that gets every behaviour right; the broken ones override one.
base class _GoodMeter implements Meter {
  const _GoodMeter();

  @override
  Counter createCounter(
    String name, {
    String unit = '',
    String description = '',
  }) => const NoopMeter().createCounter(
    name,
    unit: unit,
    description: description,
  );

  @override
  Histogram createHistogram(
    String name, {
    String unit = '',
    String description = '',
  }) => const NoopMeter().createHistogram(
    name,
    unit: unit,
    description: description,
  );

  @override
  Gauge createGauge(String name, {String unit = '', String description = ''}) =>
      const NoopMeter().createGauge(name, unit: unit, description: description);

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

/// Reports another name for the instruments it creates.
final class _Renaming extends _GoodMeter {
  const _Renaming();

  @override
  Counter createCounter(
    String name, {
    String unit = '',
    String description = '',
  }) => super.createCounter('$name.x', unit: unit, description: description);
}

/// Swallows the body's error.
final class _Swallowing extends _GoodMeter {
  const _Swallowing();

  @override
  T time<T>(
    Histogram histogram,
    T Function() body, {
    Attributes attributes = const {},
  }) {
    try {
      return body();
    } catch (_) {
      return null as T;
    }
  }
}

/// Runs the body twice.
final class _RunsTwice extends _GoodMeter {
  const _RunsTwice();

  @override
  T time<T>(
    Histogram histogram,
    T Function() body, {
    Attributes attributes = const {},
  }) {
    body();
    return body();
  }
}

/// Throws synchronously from timeAsync.
final class _ThrowsSynchronously extends _GoodMeter {
  const _ThrowsSynchronously();

  @override
  Future<T> timeAsync<T>(
    Histogram histogram,
    Future<T> Function() body, {
    Attributes attributes = const {},
  }) => body();
}

/// Completes before the body's future does.
final class _CompletesEarly extends _GoodMeter {
  const _CompletesEarly();

  @override
  Future<T> timeAsync<T>(
    Histogram histogram,
    Future<T> Function() body, {
    Attributes attributes = const {},
  }) {
    body();
    return Future<T>.value(null as T);
  }
}

MeterHarness _reporting(Meter meter, List<MeasurementSnapshot> seen) =>
    (meter: meter, measurements: () => seen);

void main() {
  final boom = StateError('boom');

  /// Requirement: doc/specs/observability-ports.md FR-063 - the Meter
  ///   contract suite must be able to fail: each meter that breaks one
  ///   behaviour makes the matching check fail.
  /// Path: unhappy (failure of collaborator)
  group('the Meter contract rejects a bad meter', () {
    /// Requirement: doc/specs/observability-ports.md FR-025, FR-029 and
    ///   FR-030 - the synchronous checks catch a meter that renames an
    ///   instrument, swallows the error or reruns the body.
    /// Path: unhappy (failure)
    test('synchronous breaches are caught', () {
      expect(
        () => expectInstrumentsReportTheirDefinition(const _Renaming()),
        throwsA(isA<TestFailure>()),
        reason: 'renamed instrument',
      );
      expect(
        () => expectTimeRethrowsUnchanged(const _Swallowing(), boom),
        throwsA(isA<TestFailure>()),
        reason: 'swallowed error',
      );
      expect(
        () => expectTimeRunsBodyOnce(const _RunsTwice()),
        throwsA(isA<TestFailure>()),
        reason: 'body run twice',
      );
    });

    /// Requirement: doc/specs/observability-ports.md FR-031, FR-032 and
    ///   FR-055 - the asynchronous checks catch a meter that throws
    ///   synchronously from timeAsync or completes before the future.
    /// Path: unhappy (failure)
    test('asynchronous breaches are caught', () async {
      await expectLater(
        expectTimeAsyncSyncThrowIsAFailedFuture(
          const _ThrowsSynchronously(),
          boom,
        ),
        throwsA(isA<TestFailure>()),
      );
      await expectLater(
        expectTimeAsyncReturnsValue(const _CompletesEarly()),
        throwsA(isA<TestFailure>()),
      );
    });

    /// Requirement: doc/specs/observability-ports.md FR-029, FR-030, FR-031, FR-032 and
    ///   FR-055 - the measurement checks catch a meter that records nothing,
    ///   records a non-double, or records at the wrong time.
    /// Path: unhappy (failure)
    test('measurement breaches are caught', () async {
      const meter = _GoodMeter();
      expect(
        () => expectTimeRecordsOneDurationInSeconds(_reporting(meter, [])),
        throwsA(isA<TestFailure>()),
        reason: 'nothing recorded',
      );
      expect(
        () => expectTimeRecordsOneDurationInSeconds(
          _reporting(meter, [(name: contractDurationName, value: 0)]),
        ),
        throwsA(isA<TestFailure>()),
        reason: 'recorded an int, not a double',
      );
      expect(
        () => expectTimeRecordsWhenBodyThrows(_reporting(meter, []), boom),
        throwsA(isA<TestFailure>()),
        reason: 'not recorded when the body throws',
      );
      await expectLater(
        expectTimeAsyncRecordsOnCompletion(
          _reporting(meter, [(name: contractDurationName, value: 0.0)]),
        ),
        throwsA(isA<TestFailure>()),
        reason: 'recorded before the future completes',
      );
      await expectLater(
        expectTimeAsyncRecordsOnFailure(
          _reporting(meter, []),
          boom,
          throwsBeforeReturning: false,
        ),
        throwsA(isA<TestFailure>()),
        reason: 'not recorded when the future fails',
      );
    });

    /// Requirement: doc/specs/observability-ports.md FR-025, FR-029, FR-030, FR-031, FR-032, FR-055 - the
    ///   same checks pass for a correct meter, so the cases above fail for
    ///   the right reason.
    /// Path: happy
    test('a correct meter passes the same checks', () async {
      const meter = _GoodMeter();

      expectInstrumentsReportTheirDefinition(meter);
      expectTimeRunsBodyOnce(meter);
      expectTimeRethrowsUnchanged(meter, boom);
      await expectTimeAsyncReturnsValue(meter);
      await expectTimeAsyncPropagates(meter, boom);
      await expectTimeAsyncSyncThrowIsAFailedFuture(meter, boom);
    });
  });
}
