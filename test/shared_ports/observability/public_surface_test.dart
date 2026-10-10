import 'dart:io';

import 'package:srd5e/srd5e.dart';
import 'package:srd5e/testing.dart';
import 'package:test/test.dart';

/// Every symbol FR-048 lists for `package:srd5e/srd5e.dart`. Importing only
/// the public entry points means a missing export is a compile error here.
final Map<String, Type> _publicTypes = {
  'Logger': Logger,
  'LogLevel': LogLevel,
  'Tracer': Tracer,
  'Span': Span,
  'SpanStatus': SpanStatus,
  'Meter': Meter,
  'Counter': Counter,
  'Histogram': Histogram,
  'Gauge': Gauge,
  'Observability': Observability,
  'NoopLogger': NoopLogger,
  'NoopTracer': NoopTracer,
  'NoopMeter': NoopMeter,
  'NoopObservability': NoopObservability,
  'AttributeKeys': AttributeKeys,
};

/// Every symbol FR-049 lists for `package:srd5e/testing.dart`.
final Map<String, Type> _testingTypes = {
  'RecordingLogger': RecordingLogger,
  'RecordingTracer': RecordingTracer,
  'RecordingMeter': RecordingMeter,
  'RecordingObservability': RecordingObservability,
  'LogRecord': LogRecord,
  'SpanRecord': SpanRecord,
  'MeasurementRecord': MeasurementRecord,
  'InstrumentKind': InstrumentKind,
};

void main() {
  /// Requirement: doc/specs/observability-ports.md FR-048 - lib/srd5e.dart
  ///   exports the ports, their types, the four no-ops, the level shortcuts
  ///   and AttributeKeys.
  /// Path: happy
  group('srd5e.dart observability surface', () {
    /// Requirement: doc/specs/observability-ports.md FR-048 - each listed type
    ///   resolves from the public entry point under its own name.
    /// Path: happy
    test('FR-048: every listed type is exported', () {
      for (final entry in _publicTypes.entries) {
        expect(
          entry.value.toString(),
          startsWith(entry.key),
          reason: '${entry.key} resolves to ${entry.value}',
        );
      }
    });

    /// Requirement: doc/specs/observability-ports.md FR-048 - LoggerLevels is
    ///   exported: the shortcut works on a Logger through the entry point.
    /// Path: happy
    test('FR-048: the LoggerLevels shortcuts are exported', () {
      final recording = RecordingLogger();

      LoggerLevels(recording).warning('careful');

      expect(recording.records.single.level, LogLevel.warning);
    });

    /// Requirement: doc/specs/observability-ports.md FR-048 - AttributeKeys is
    ///   usable from the entry point.
    /// Path: happy
    test('FR-048: AttributeKeys is exported with string keys', () {
      expect(AttributeKeys.outcome, isA<String>());
    });

    /// Requirement: doc/specs/observability-ports.md FR-048, FR-049 -
    ///   srd5e.dart exports no double and not InstrumentKind.
    /// Path: unhappy (invalid input)
    test('FR-049: srd5e.dart exports no recording double', () {
      final source = File('lib/srd5e.dart').readAsStringSync();
      final exportedPaths = RegExp(
        r"^export\s+'([^']+)'",
        multiLine: true,
      ).allMatches(source).map((m) => m.group(1)!);

      expect(exportedPaths, isNotEmpty);
      expect(exportedPaths.where((p) => p.contains('testing/')), isEmpty);
      expect(source, isNot(contains('InstrumentKind')));
      for (final name in _testingTypes.keys) {
        expect(source, isNot(contains(name)), reason: name);
      }
    });
  });

  /// Requirement: doc/specs/observability-ports.md FR-049 - lib/testing.dart
  ///   exports the recording doubles, their record types and InstrumentKind,
  ///   implemented under lib/src/testing/.
  /// Path: happy
  group('testing.dart observability surface', () {
    /// Requirement: doc/specs/observability-ports.md FR-049 - each listed type
    ///   resolves from the testing entry point.
    /// Path: happy
    test('FR-049: every listed double and record type is exported', () {
      for (final entry in _testingTypes.entries) {
        expect(
          entry.value.toString(),
          startsWith(entry.key),
          reason: '${entry.key} resolves to ${entry.value}',
        );
      }
    });

    /// Requirement: doc/specs/observability-ports.md FR-049 - every export
    ///   line of testing.dart points into lib/src/testing/.
    /// Path: unhappy (invalid input)
    test('FR-049: testing.dart exports only from src/testing', () {
      final source = File('lib/testing.dart').readAsStringSync();
      final exportedPaths = RegExp(
        r"^export\s+'([^']+)'",
        multiLine: true,
      ).allMatches(source).map((m) => m.group(1)!).toList();

      expect(exportedPaths, isNotEmpty);
      expect(exportedPaths, everyElement(startsWith('src/testing/')));
    });
  });
}
