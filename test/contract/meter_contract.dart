import 'dart:async';

import 'package:srd5e/src/shared_ports/observability/meter.dart';
import 'package:test/test.dart';

/// What a recording meter reports about one measurement.
typedef MeasurementSnapshot = ({String name, num value});

/// A meter under test, and, for an implementation that can show what it
/// recorded, the way to read it (in call order).
typedef MeterHarness = ({
  Meter meter,
  List<MeasurementSnapshot> Function()? measurements,
});

/// A meter harness factory; it must return a fresh harness each time.
typedef MeterHarnessFactory = MeterHarness Function();

/// The duration histogram name every contract check uses.
const String contractDurationName = 'srd5e.contract.duration';

/// A failure thrown by a body under test.
final class ContractException implements Exception {
  /// Creates a failure.
  const ContractException();
}

/// One failure a body can throw: an `Exception` or an `Error`.
typedef ThrownCase = ({String label, Object Function() make});

/// The objects a body throws in the failure checks (FR-030).
final List<ThrownCase> thrownCases = [
  (label: 'an Exception', make: ContractException.new),
  (label: 'an Error', make: () => StateError('a bug')),
];

Histogram _duration(Meter meter) =>
    meter.createHistogram(contractDurationName, unit: 's');

({Object error, StackTrace stackTrace}) _catch(void Function() action) {
  try {
    action();
  } catch (error, stackTrace) {
    return (error: error, stackTrace: stackTrace);
  }
  fail('the action was expected to throw');
}

Future<({Object error, StackTrace stackTrace})> _catchAsync(
  Future<Object?> future,
) async {
  try {
    await future;
  } catch (error, stackTrace) {
    return (error: error, stackTrace: stackTrace);
  }
  fail('the future was expected to fail');
}

/// FR-025: each create method returns an instrument that reports exactly the
/// name, unit and description it was given, and `''` for the defaults.
void expectInstrumentsReportTheirDefinition(Meter meter) {
  final counter = meter.createCounter(
    'srd5e.contract.count',
    unit: '{thing}',
    description: 'things counted',
  );
  final histogram = meter.createHistogram(
    'srd5e.contract.sizes',
    unit: '{thing}',
    description: 'sizes seen',
  );
  final gauge = meter.createGauge('srd5e.contract.level');

  expect(counter.name, 'srd5e.contract.count');
  expect(counter.unit, '{thing}');
  expect(counter.description, 'things counted');
  expect(histogram.name, 'srd5e.contract.sizes');
  expect(histogram.unit, '{thing}');
  expect(histogram.description, 'sizes seen');
  expect(gauge.name, 'srd5e.contract.level');
  expect(gauge.unit, '');
  expect(gauge.description, '');
}

/// FR-029: `time` runs the body once and returns its value.
void expectTimeRunsBodyOnce(Meter meter) {
  var calls = 0;

  final result = meter.time(_duration(meter), () {
    calls++;
    return 'done';
  });

  expect(result, 'done');
  expect(calls, 1);
}

/// FR-030: a body that throws [thrown] has it rethrown unchanged by `time`.
void expectTimeRethrowsUnchanged(Meter meter, Object thrown) {
  final stackTrace = StackTrace.fromString('the body stack trace');

  final caught = _catch(
    () => meter.time<void>(
      _duration(meter),
      () => Error.throwWithStackTrace(thrown, stackTrace),
    ),
  );

  expect(caught.error, same(thrown), reason: 'FR-030: the same object');
  expect(caught.stackTrace.toString(), stackTrace.toString());
}

/// FR-031: `timeAsync` returns the future's value, and only when it completes.
Future<void> expectTimeAsyncReturnsValue(Meter meter) async {
  final gate = Completer<Object?>();
  var completed = false;

  final future = meter.timeAsync<Object?>(_duration(meter), () => gate.future);
  unawaited(future.then((_) => completed = true));
  await Future<void>.delayed(Duration.zero);
  expect(completed, isFalse, reason: 'FR-031: pending until the body is done');
  gate.complete(9);

  expect(await future, 9);
}

/// FR-032: a future that fails makes `timeAsync` fail with the same error.
Future<void> expectTimeAsyncPropagates(Meter meter, Object thrown) async {
  final stackTrace = StackTrace.fromString('the body stack trace');

  final caught = await _catchAsync(
    meter.timeAsync<void>(
      _duration(meter),
      () => Future<void>.error(thrown, stackTrace),
    ),
  );

  expect(caught.error, same(thrown), reason: 'FR-032: the same object');
  expect(caught.stackTrace.toString(), stackTrace.toString());
}

/// FR-055: a body that throws before it returns a future gives a failed
/// future, not a synchronous throw.
Future<void> expectTimeAsyncSyncThrowIsAFailedFuture(
  Meter meter,
  Object thrown,
) async {
  final histogram = _duration(meter);
  late final Future<void> future;

  expect(
    () => future = meter.timeAsync<void>(histogram, () => throw thrown),
    returnsNormally,
    reason: 'FR-055: no synchronous throw',
  );

  final caught = await _catchAsync(future);
  expect(caught.error, same(thrown));
}

/// FR-029 on a meter that shows its measurements: one measurement into the
/// duration histogram, a `double` number of seconds.
void expectTimeRecordsOneDurationInSeconds(MeterHarness harness) {
  harness.meter.time(_duration(harness.meter), () => 1);

  final measurements = harness.measurements!();
  expect(measurements, hasLength(1));
  expect(measurements.single.name, contractDurationName);
  expect(measurements.single.value, isA<double>());
  expect(measurements.single.value, greaterThanOrEqualTo(0));
}

/// FR-030 on a meter that shows its measurements: the time is recorded even
/// when the body throws.
void expectTimeRecordsWhenBodyThrows(MeterHarness harness, Object thrown) {
  _catch(
    () =>
        harness.meter.time<void>(_duration(harness.meter), () => throw thrown),
  );

  expect(harness.measurements!(), hasLength(1));
}

/// FR-031 on a meter that shows its measurements: nothing is recorded before
/// the future completes, one duration after.
Future<void> expectTimeAsyncRecordsOnCompletion(MeterHarness harness) async {
  final gate = Completer<int>();

  final future = harness.meter.timeAsync(
    _duration(harness.meter),
    () => gate.future,
  );
  await Future<void>.delayed(Duration.zero);
  expect(harness.measurements!(), isEmpty);
  gate.complete(1);
  await future;

  final measurements = harness.measurements!();
  expect(measurements, hasLength(1));
  expect(measurements.single.value, isA<double>());
}

/// FR-032 and FR-055 on a meter that shows its measurements: the time is
/// recorded when the future fails, or when the body throws before returning
/// one.
Future<void> expectTimeAsyncRecordsOnFailure(
  MeterHarness harness,
  Object thrown, {
  required bool throwsBeforeReturning,
}) async {
  final histogram = _duration(harness.meter);
  final future = throwsBeforeReturning
      ? harness.meter.timeAsync<void>(histogram, () => throw thrown)
      : harness.meter.timeAsync<void>(
          histogram,
          () => Future<void>.error(thrown),
        );
  await _catchAsync(future);

  expect(harness.measurements!(), hasLength(1));
}

/// Registers the shared `Meter` contract suite
/// (`doc/specs/observability-ports.md` FR-025, FR-029, FR-030, FR-031, FR-032, FR-055 and
/// FR-063) against the implementation that [create] builds.
///
/// [create] must return a fresh harness each time. Pass
/// `observesMeasurements: true` when the harness can show what it recorded
/// (`measurements` is not null); the checks of what is recorded then run too.
///
/// The suite is not exported by the package (it needs `package:test`); copy it
/// to run against your own adapter.
void meterContract(
  String name,
  MeterHarnessFactory create, {
  bool observesMeasurements = false,
}) {
  /// Requirement: doc/specs/observability-ports.md FR-025, FR-029, FR-030, FR-031, FR-032
  ///   and FR-055 - the Meter port contract holds for this implementation.
  /// Path: happy
  group('Meter contract: $name', () {
    /// Requirement: doc/specs/observability-ports.md FR-025 - instruments
    ///   report exactly the name, unit and description they were given.
    /// Path: happy
    test('FR-025: instruments report their definition', () {
      expectInstrumentsReportTheirDefinition(create().meter);
    });

    /// Requirement: doc/specs/observability-ports.md FR-029 - the body runs
    ///   once and its value is returned.
    /// Path: happy
    test('FR-029: time runs the body once and returns its value', () {
      expectTimeRunsBodyOnce(create().meter);
    });

    /// Requirement: doc/specs/observability-ports.md FR-031 - timeAsync
    ///   completes with the future's value, and only when it completes.
    /// Path: happy
    test('FR-031: timeAsync returns the value of the future', () async {
      await expectTimeAsyncReturnsValue(create().meter);
    });

    /// Requirement: per case
    /// Path: per case
    for (final c in thrownCases) {
      test('FR-030/FR-033: time rethrows ${c.label} unchanged '
          '[unhappy (failure)]', () {
        expectTimeRethrowsUnchanged(create().meter, c.make());
      });

      test('FR-032/FR-033: timeAsync propagates ${c.label} from the future '
          '[unhappy (failure)]', () async {
        await expectTimeAsyncPropagates(create().meter, c.make());
      });

      test('FR-055/FR-033: timeAsync turns ${c.label} thrown before a '
          'future into a failed future [unhappy (failure)]', () async {
        await expectTimeAsyncSyncThrowIsAFailedFuture(create().meter, c.make());
      });
    }

    if (observesMeasurements) {
      /// Requirement: doc/specs/observability-ports.md FR-029 - one
      ///   measurement of the elapsed seconds, as a double.
      /// Path: happy
      test('FR-029: time records one duration in seconds', () {
        expectTimeRecordsOneDurationInSeconds(create());
      });

      /// Requirement: doc/specs/observability-ports.md FR-031 - the duration
      ///   is recorded when the future completes, not before.
      /// Path: happy
      test('FR-031: timeAsync records when the future completes', () async {
        await expectTimeAsyncRecordsOnCompletion(create());
      });

      /// Requirement: per case
      /// Path: per case
      for (final c in thrownCases) {
        test('FR-030: time records the duration when the body throws '
            '${c.label} [unhappy (failure)]', () {
          expectTimeRecordsWhenBodyThrows(create(), c.make());
        });

        test('FR-032: timeAsync records the duration when the future fails '
            'with ${c.label} [unhappy (failure)]', () async {
          await expectTimeAsyncRecordsOnFailure(
            create(),
            c.make(),
            throwsBeforeReturning: false,
          );
        });

        test('FR-055: timeAsync records the duration when the body throws '
            '${c.label} before a future [unhappy (failure)]', () async {
          await expectTimeAsyncRecordsOnFailure(
            create(),
            c.make(),
            throwsBeforeReturning: true,
          );
        });
      }
    }
  });
}
