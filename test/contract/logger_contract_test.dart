import 'package:srd5e/src/shared_ports/observability/log_level.dart';
import 'package:srd5e/src/shared_ports/observability/logger.dart';
import 'package:srd5e/src/testing/recording_logger.dart';

import 'logger_contract.dart';

void main() {
  loggerContract(
    'NoopLogger',
    () => const NoopLogger(),
    disabledLevel: LogLevel.severe,
  );

  loggerContract(
    'RecordingLogger with minLevel severe',
    () => RecordingLogger(minLevel: LogLevel.severe),
    disabledLevel: LogLevel.warning,
    enabledLevel: LogLevel.severe,
  );

  loggerContract(
    'RecordingLogger with minLevel warning',
    () => RecordingLogger(minLevel: LogLevel.warning),
    disabledLevel: LogLevel.info,
    enabledLevel: LogLevel.warning,
  );
}
