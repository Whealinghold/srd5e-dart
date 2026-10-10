import 'package:srd5e/src/shared_ports/observability/tracer.dart';
import 'package:srd5e/src/testing/recording_tracer.dart';

import 'tracer_contract.dart';

TracerHarness _recording() {
  final tracer = RecordingTracer();
  return (
    tracer: tracer,
    spans: () => [
      for (final span in tracer.spans)
        (
          name: span.name,
          status: span.status,
          errors: [for (final (error, _) in span.errors) error],
          ended: span.ended,
        ),
    ],
  );
}

void main() {
  tracerContract('NoopTracer', () => (tracer: const NoopTracer(), spans: null));

  tracerContract('RecordingTracer', _recording, observesSpans: true);
}
