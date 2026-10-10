import 'package:meta/meta.dart';

import 'logger.dart';
import 'meter.dart';
import 'tracer.dart';

/// The logger, tracer and meter a use case emits through, bundled.
///
/// Every use case takes `Observability observability = Observability.none` as
/// an optional constructor argument and never checks whether it is enabled:
/// the default is a silent no-op, so omitting it costs nothing and changes no
/// behaviour. Supply only the ports you have; the others stay no-ops.
///
/// The class is `final`, so no consumer can extend or implement it. That keeps
/// [none] canonical and the bundle immutable.
@immutable
final class Observability {
  /// Creates a bundle. Each port defaults to its no-op.
  const Observability({
    this.logger = const NoopLogger(),
    this.tracer = const NoopTracer(),
    this.meter = const NoopMeter(),
  });

  /// The bundle of the three no-ops. The same instance as
  /// `const NoopObservability()`.
  static const Observability none = NoopObservability();

  /// Where log events go.
  final Logger logger;

  /// Where spans go.
  final Tracer tracer;

  /// Where instruments are created and work is timed.
  final Meter meter;

  @override
  bool operator ==(Object other) =>
      other is Observability &&
      other.logger == logger &&
      other.tracer == tracer &&
      other.meter == meter;

  @override
  int get hashCode => Object.hash(logger, tracer, meter);
}

/// The [Observability] bundle of the three no-ops.
///
/// Declared beside [Observability], which is `final`, so this is the only
/// subclass there can be. Use [Observability.none].
final class NoopObservability extends Observability {
  /// Creates the silent bundle.
  const NoopObservability();
}
