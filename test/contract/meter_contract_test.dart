import 'package:srd5e/src/shared_ports/observability/meter.dart';
import 'package:srd5e/src/testing/recording_meter.dart';

import 'meter_contract.dart';

MeterHarness _recording() {
  final meter = RecordingMeter();
  return (
    meter: meter,
    measurements: () => [
      for (final m in meter.measurements) (name: m.name, value: m.value),
    ],
  );
}

void main() {
  meterContract(
    'NoopMeter',
    () => (meter: const NoopMeter(), measurements: null),
  );

  meterContract('RecordingMeter', _recording, observesMeasurements: true);
}
