import 'package:srd5e/src/shared_ports/observability/attributes.dart';
import 'package:srd5e/src/shared_ports/observability/log_level.dart';
import 'package:srd5e/src/shared_ports/observability/logger.dart';
import 'package:srd5e/src/testing/recording_logger.dart';
import 'package:test/test.dart';

import '../support/argument_error_matcher.dart';
import '../support/signal_names.dart';

typedef _MinLevelCase = ({
  String label,
  LogLevel minLevel,
  LogLevel level,
  bool recorded,
});

/// FR-008: every level against every minLevel: below, at and above.
final List<_MinLevelCase> _minLevelCases = [
  for (final minLevel in LogLevel.values)
    for (final level in LogLevel.values)
      (
        label: '${level.name} with minLevel ${minLevel.name}',
        minLevel: minLevel,
        level: level,
        recorded: level.index >= minLevel.index,
      ),
];

void main() {
  /// Requirement: doc/specs/observability-ports.md FR-007 - RecordingLogger
  ///   stores one LogRecord per enabled call, in call order, with every field.
  /// Path: happy
  group('RecordingLogger records', () {
    /// Requirement: doc/specs/observability-ports.md FR-007 - level, message,
    ///   attributes, error and stack trace of a call are all stored.
    /// Path: happy
    test('a call with every field', () {
      final logger = RecordingLogger();
      final error = StateError('boom');
      final stackTrace = StackTrace.fromString('trace');

      logger.log(
        LogLevel.warning,
        'something odd',
        attributes: () => {'k': 'v', 'n': 2},
        error: error,
        stackTrace: stackTrace,
      );

      final record = logger.records.single;
      expect(record.level, LogLevel.warning);
      expect(record.message, 'something odd');
      expect(record.attributes, {'k': 'v', 'n': 2});
      expect(record.error, same(error));
      expect(record.stackTrace, same(stackTrace));
    });

    /// Requirement: doc/specs/observability-ports.md FR-007 - records are in
    ///   call order, across levels, including through the LoggerLevels
    ///   shortcuts.
    /// Path: happy
    test('several calls in call order', () {
      final logger = RecordingLogger();

      logger.fine('first');
      logger.severe('second');
      logger.finest('third');

      expect(logger.records.map((r) => r.message), [
        'first',
        'second',
        'third',
      ]);
      expect(logger.records.map((r) => r.level), [
        LogLevel.fine,
        LogLevel.severe,
        LogLevel.finest,
      ]);
    });

    /// Requirement: doc/specs/observability-ports.md FR-007 - no calls, no
    ///   records.
    /// Path: unhappy (empty and minimal)
    test('nothing when nothing was logged', () {
      expect(RecordingLogger().records, isEmpty);
    });

    /// Requirement: doc/specs/observability-ports.md FR-007 - recordsAt gives
    ///   only the events at exactly one level, in call order.
    /// Path: happy
    test('recordsAt filters by exact level', () {
      final logger = RecordingLogger();
      logger.fine('a');
      logger.warning('b');
      logger.fine('c');

      expect(logger.recordsAt(LogLevel.fine).map((r) => r.message), ['a', 'c']);
      expect(logger.recordsAt(LogLevel.severe), isEmpty);
    });
  });

  /// Requirement: doc/specs/observability-ports.md FR-008 - minLevel defaults
  ///   to finest; a call below it is not recorded, a call at it is, and
  ///   isEnabled agrees.
  /// Path: unhappy (boundary)
  group('RecordingLogger minLevel', () {
    /// Requirement: doc/specs/observability-ports.md FR-008 - the default is
    ///   LogLevel.finest, so every level is enabled.
    /// Path: happy
    test('defaults to finest and enables every level', () {
      final logger = RecordingLogger();

      expect(logger.minLevel, LogLevel.finest);
      expect(LogLevel.values.map(logger.isEnabled), everyElement(isTrue));
    });

    /// Requirement: per case
    /// Path: per case
    for (final c in _minLevelCases) {
      test('FR-008: ${c.label} is ${c.recorded ? '' : 'not '}recorded '
          '[unhappy (boundary)]', () {
        final logger = RecordingLogger(minLevel: c.minLevel);

        logger.log(c.level, 'event');

        expect(logger.isEnabled(c.level), c.recorded);
        expect(logger.records, hasLength(c.recorded ? 1 : 0));
      });
    }

    /// Requirement: doc/specs/observability-ports.md FR-008 - minLevel can be
    ///   changed after construction and takes effect for later calls.
    /// Path: happy
    test('FR-008: changing minLevel affects later calls only', () {
      final logger = RecordingLogger();
      logger.fine('before');

      logger.minLevel = LogLevel.warning;
      logger.fine('skipped');
      logger.warning('after');

      expect(logger.records.map((r) => r.message), ['before', 'after']);
    });
  });

  /// Requirement: doc/specs/observability-ports.md FR-009 - the closure is
  ///   called exactly once per recorded call and its map is copied; with no
  ///   closure the attributes are empty.
  /// Path: unhappy (empty and minimal)
  group('RecordingLogger attributes', () {
    /// Requirement: doc/specs/observability-ports.md FR-009 - exactly once per
    ///   recorded call.
    /// Path: happy
    test('the closure is called exactly once per recorded call', () {
      final logger = RecordingLogger();
      var calls = 0;
      Attributes closure() {
        calls++;
        return {'k': 'v'};
      }

      logger.fine('a', attributes: closure);
      logger.fine('b', attributes: closure);

      expect(calls, 2);
    });

    /// Requirement: doc/specs/observability-ports.md FR-009 and FR-006 - the
    ///   closure is not called for a call below minLevel.
    /// Path: unhappy (collaborator: disabled level)
    test('the closure is not called below minLevel', () {
      final logger = RecordingLogger(minLevel: LogLevel.warning);
      var calls = 0;

      logger.fine(
        'skipped',
        attributes: () {
          calls++;
          return <String, Object>{};
        },
      );

      expect(calls, 0);
      expect(logger.records, isEmpty);
    });

    /// Requirement: doc/specs/observability-ports.md FR-009 - no closure gives
    ///   an empty map.
    /// Path: unhappy (empty and minimal)
    test('no closure gives empty attributes', () {
      final logger = RecordingLogger();

      logger.fine('bare');

      expect(logger.records.single.attributes, isEmpty);
    });

    /// Requirement: doc/specs/observability-ports.md FR-009 and FR-047 - the
    ///   stored map is an unmodifiable copy: changing the map the closure
    ///   returned afterwards changes nothing.
    /// Path: unhappy (immutability)
    test('the stored attributes are a copy the caller cannot change', () {
      final logger = RecordingLogger();
      final map = <String, Object>{'k': 'v'};

      logger.fine('a', attributes: () => map);
      map['k'] = 'changed';
      map['extra'] = 1;

      final stored = logger.records.single.attributes;
      expect(stored, {'k': 'v'});
      expect(() => stored['x'] = 1, throwsUnsupportedError);
    });
  });

  /// Requirement: doc/specs/observability-ports.md FR-010 - RecordingLogger
  ///   throws ArgumentError naming the key when an attribute value is not a
  ///   String, bool, int or double.
  /// Path: unhappy (invalid input)
  group('RecordingLogger attribute values', () {
    /// Requirement: per case
    /// Path: per case
    for (final c in attributeValueCases) {
      test('FR-010: ${c.label} is ${c.valid ? 'accepted' : 'rejected'} '
          '[${c.valid ? 'happy' : 'unhappy (invalid input)'}]', () {
        final logger = RecordingLogger();

        void log() => logger.fine('event', attributes: () => {'key': c.value});

        if (c.valid) {
          log();
          expect(logger.records.single.attributes['key'], c.value);
        } else {
          expect(log, throwsArgumentErrorFor('key', c.value));
          expect(logger.records, isEmpty);
        }
      });
    }

    /// Requirement: doc/specs/observability-ports.md FR-010 - a bad value is
    ///   only found when the event is enabled, because the closure is not
    ///   called otherwise.
    /// Path: unhappy (collaborator: disabled level)
    test('a bad value below minLevel is never seen', () {
      final logger = RecordingLogger(minLevel: LogLevel.severe);

      void log() => logger.fine('event', attributes: () => {'key': Object()});

      expect(log, returnsNormally);
    });
  });

  /// Requirement: doc/specs/observability-ports.md FR-047 - the lists the
  ///   double exposes are unmodifiable views.
  /// Path: unhappy (immutability)
  group('RecordingLogger exposes unmodifiable lists', () {
    /// Requirement: doc/specs/observability-ports.md FR-047 - records cannot
    ///   be added to.
    /// Path: unhappy (immutability)
    test('records', () {
      final logger = RecordingLogger()..fine('a');

      expect(
        () => logger.records.add(logger.records.first),
        throwsUnsupportedError,
      );
      expect(logger.records, hasLength(1));
    });

    /// Requirement: doc/specs/observability-ports.md FR-047 - recordsAt cannot
    ///   be added to.
    /// Path: unhappy (immutability)
    test('recordsAt', () {
      final logger = RecordingLogger()..fine('a');

      expect(
        () => logger.recordsAt(LogLevel.fine).clear(),
        throwsUnsupportedError,
      );
    });

    /// Requirement: doc/specs/observability-ports.md FR-047 - records is a
    ///   read-only view: it follows what is logged later.
    /// Path: happy
    test('records is a live view of what was logged', () {
      final logger = RecordingLogger();
      final view = logger.records;

      logger.fine('later');

      expect(view, hasLength(1));
    });
  });

  /// Requirement: doc/specs/observability-ports.md FR-046 - clear removes the
  ///   records and keeps the configuration.
  /// Path: unhappy (state)
  group('RecordingLogger.clear', () {
    /// Requirement: doc/specs/observability-ports.md FR-046 - records are
    ///   removed and minLevel is kept.
    /// Path: unhappy (state)
    test('removes records and keeps minLevel', () {
      final logger = RecordingLogger(minLevel: LogLevel.info)..warning('a');

      logger.clear();

      expect(logger.records, isEmpty);
      expect(logger.minLevel, LogLevel.info);
      logger.warning('b');
      expect(logger.records.map((r) => r.message), ['b']);
    });
  });
}
