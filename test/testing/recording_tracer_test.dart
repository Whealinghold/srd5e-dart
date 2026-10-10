import 'dart:async';

import 'package:srd5e/src/shared_ports/observability/tracer.dart';
import 'package:srd5e/src/testing/recording_tracer.dart';
import 'package:test/test.dart';

import '../support/argument_error_matcher.dart';
import '../support/signal_names.dart';

const String _name = 'srd5e.test.work';
const String _inner = 'srd5e.test.inner';
const String _deeper = 'srd5e.test.deeper';

typedef _MutatorCase = ({String label, void Function(Span span) call});

/// The three mutators, each of which must throw once the span has ended.
final List<_MutatorCase> _mutators = [
  (label: 'setAttribute', call: (span) => span.setAttribute('k', 'v')),
  (label: 'setStatus', call: (span) => span.setStatus(SpanStatus.ok)),
  (
    label: 'recordError',
    call: (span) => span.recordError(StateError('late'), StackTrace.current),
  ),
];

void main() {
  /// Requirement: doc/specs/observability-ports.md FR-015 - attributes passed
  ///   to trace are present from the start; setAttribute adds or overwrites.
  /// Path: happy
  group('RecordingTracer span attributes', () {
    /// Requirement: doc/specs/observability-ports.md FR-015 - start
    ///   attributes are on the span while the body runs.
    /// Path: happy
    test('FR-015: attributes passed to trace are present from the start', () {
      final tracer = RecordingTracer();
      late final Map<String, Object> inside;

      tracer.trace(
        _name,
        (span) => inside = Map.of(tracer.spans.single.attributes),
        attributes: {'a': 'x', 'n': 1},
      );

      expect(inside, {'a': 'x', 'n': 1});
    });

    /// Requirement: doc/specs/observability-ports.md FR-015 and FR-021 - a
    ///   later attribute is added to the final record next to the start ones.
    /// Path: happy
    test('FR-015: setAttribute adds an attribute', () {
      final tracer = RecordingTracer();

      tracer.trace(
        _name,
        (span) => span.setAttribute('later', true),
        attributes: {'a': 'x'},
      );

      expect(tracer.spans.single.attributes, {'a': 'x', 'later': true});
    });

    /// Requirement: doc/specs/observability-ports.md FR-015 - setAttribute
    ///   overwrites an earlier value for the key, start value or later one.
    /// Path: unhappy (rule interaction)
    test('FR-015: setAttribute overwrites an earlier value', () {
      final tracer = RecordingTracer();

      tracer.trace(_name, (span) {
        span.setAttribute('a', 'second');
        span.setAttribute('b', 1);
        span.setAttribute('b', 2.5);
      }, attributes: {'a': 'first'});

      expect(tracer.spans.single.attributes, {'a': 'second', 'b': 2.5});
    });

    /// Requirement: doc/specs/observability-ports.md FR-015 - no attributes
    ///   gives an empty map.
    /// Path: unhappy (empty and minimal)
    test('FR-015: a span with no attributes has an empty map', () {
      final tracer = RecordingTracer();

      tracer.trace(_name, (span) {});

      expect(tracer.spans.single.attributes, isEmpty);
    });
  });

  /// Requirement: doc/specs/observability-ports.md FR-016 and FR-018 - a new
  ///   span's status is unset, the last setStatus wins, and a throw makes the
  ///   final status error whatever the body set.
  /// Path: happy
  group('RecordingTracer span status', () {
    /// Requirement: doc/specs/observability-ports.md FR-016 - a new span is
    ///   unset.
    /// Path: happy
    test('FR-016: a new span is unset', () {
      final tracer = RecordingTracer();

      tracer.trace(_name, (span) {});

      expect(tracer.spans.single.status, SpanStatus.unset);
    });

    /// Requirement: doc/specs/observability-ports.md FR-016 - setStatus
    ///   changes the status.
    /// Path: happy
    test('FR-016: setStatus changes the status', () {
      final tracer = RecordingTracer();

      tracer.trace(_name, (span) => span.setStatus(SpanStatus.ok));

      expect(tracer.spans.single.status, SpanStatus.ok);
    });

    /// Requirement: doc/specs/observability-ports.md FR-016 - the last call
    ///   wins, including back to unset.
    /// Path: unhappy (rule interaction)
    test('FR-016: the last setStatus wins', () {
      final tracer = RecordingTracer();

      tracer.trace(_name, (span) {
        span.setStatus(SpanStatus.error);
        span.setStatus(SpanStatus.ok);
      });
      tracer.trace(_inner, (span) {
        span.setStatus(SpanStatus.ok);
        span.setStatus(SpanStatus.unset);
      });

      expect(tracer.spans[0].status, SpanStatus.ok);
      expect(tracer.spans[1].status, SpanStatus.unset);
    });

    /// Requirement: per case
    /// Path: per case
    for (final status in [SpanStatus.ok, SpanStatus.unset]) {
      test('FR-018: ${status.name} then a throw ends as error '
          '[unhappy (rule interaction)]', () {
        final tracer = RecordingTracer();

        expect(
          () => tracer.trace<void>(_name, (span) {
            span.setStatus(status);
            throw StateError('boom');
          }),
          throwsStateError,
        );

        expect(tracer.spans.single.status, SpanStatus.error);
      });

      test('FR-018: ${status.name} then a failed future ends as error '
          '[unhappy (rule interaction)]', () async {
        final tracer = RecordingTracer();

        await expectLater(
          tracer.traceAsync<void>(_name, (span) async {
            span.setStatus(status);
            throw StateError('boom');
          }),
          throwsStateError,
        );

        expect(tracer.spans.single.status, SpanStatus.error);
      });
    }
  });

  /// Requirement: doc/specs/observability-ports.md FR-012, FR-014 and FR-017 -
  ///   recordError appends in call order without changing the status or
  ///   ending the span; a thrown error is recorded with its stack trace.
  /// Path: happy
  group('RecordingTracer recorded errors', () {
    /// Requirement: doc/specs/observability-ports.md FR-017 - two recorded
    ///   errors are kept in call order and the status is left alone.
    /// Path: happy
    test('FR-017: recordError appends in order and leaves the status', () {
      final tracer = RecordingTracer();
      final first = StateError('first');
      final second = ArgumentError('second');
      final firstTrace = StackTrace.fromString('one');
      final secondTrace = StackTrace.fromString('two');
      late final bool endedInside;

      tracer.trace(_name, (span) {
        span.recordError(first, firstTrace);
        span.recordError(second, secondTrace);
        endedInside = tracer.spans.single.ended;
      });

      final record = tracer.spans.single;
      expect(record.errors, [(first, firstTrace), (second, secondTrace)]);
      expect(record.status, SpanStatus.unset);
      expect(endedInside, isFalse);
    });

    /// Requirement: doc/specs/observability-ports.md FR-012 - a thrown error
    ///   is recorded once, with the stack trace it was thrown with, status
    ///   error, and the span is ended; the same object propagates.
    /// Path: unhappy (failure)
    test('FR-012: a thrown error is recorded with its stack trace', () {
      final tracer = RecordingTracer();
      final thrown = StateError('boom');
      final stackTrace = StackTrace.fromString('the stack trace');

      expect(
        () => tracer.trace<void>(
          _name,
          (span) => Error.throwWithStackTrace(thrown, stackTrace),
        ),
        throwsA(same(thrown)),
      );

      final record = tracer.spans.single;
      expect(record.status, SpanStatus.error);
      expect(record.errors, hasLength(1));
      expect(record.errors.single.$1, same(thrown));
      expect(record.errors.single.$2, same(stackTrace));
      expect(record.ended, isTrue);
    });

    /// Requirement: doc/specs/observability-ports.md FR-014 - a future that
    ///   fails is recorded the same way, with the stack trace it failed with.
    /// Path: unhappy (failure)
    test('FR-014: a failed future is recorded with its stack trace', () async {
      final tracer = RecordingTracer();
      final thrown = StateError('boom');
      final stackTrace = StackTrace.fromString('the stack trace');

      await expectLater(
        tracer.traceAsync<void>(
          _name,
          (span) => Future<void>.error(thrown, stackTrace),
        ),
        throwsA(same(thrown)),
      );

      final record = tracer.spans.single;
      expect(record.status, SpanStatus.error);
      expect(record.errors.single.$1, same(thrown));
      expect(record.errors.single.$2, same(stackTrace));
    });

    /// Requirement: doc/specs/observability-ports.md FR-012 - an error the
    ///   body already recorded and then threw is recorded again by the
    ///   catch: two entries, the body's first.
    /// Path: unhappy (rule interaction)
    test('FR-012: a recorded error that is then thrown appears twice', () {
      final tracer = RecordingTracer();
      final thrown = StateError('boom');

      expect(
        () => tracer.trace<void>(_name, (span) {
          span.recordError(thrown, StackTrace.fromString('body'));
          throw thrown;
        }),
        throwsA(same(thrown)),
      );

      expect(tracer.spans.single.errors, hasLength(2));
    });
  });

  /// Requirement: doc/specs/observability-ports.md FR-021 - one SpanRecord per
  ///   span, in start order, with name, attributes, status, errors, parent and
  ///   ended; mutable while open, frozen once ended.
  /// Path: happy
  group('RecordingTracer span records', () {
    /// Requirement: doc/specs/observability-ports.md FR-021 - all fields of a
    ///   finished span.
    /// Path: happy
    test('FR-021: a finished span has every field', () {
      final tracer = RecordingTracer();

      tracer.trace(_name, (span) {
        span.setAttribute('b', 2);
        span.setStatus(SpanStatus.ok);
      }, attributes: {'a': 1});

      final record = tracer.spans.single;
      expect(record.name, _name);
      expect(record.attributes, {'a': 1, 'b': 2});
      expect(record.status, SpanStatus.ok);
      expect(record.errors, isEmpty);
      expect(record.parent, isNull);
      expect(record.ended, isTrue);
    });

    /// Requirement: doc/specs/observability-ports.md FR-021 - spans are listed
    ///   in start order, a parent before its children.
    /// Path: happy
    test('FR-021: a parent precedes its children', () {
      final tracer = RecordingTracer();

      tracer.trace(_name, (span) {
        tracer.trace(_inner, (span) {});
        tracer.trace(_deeper, (span) {});
      });

      expect(tracer.spans.map((s) => s.name), [_name, _inner, _deeper]);
    });

    /// Requirement: doc/specs/observability-ports.md FR-021 - the record is
    ///   mutable while the span is open: a read inside the body sees the
    ///   write, and the span has not ended.
    /// Path: unhappy (state)
    test('FR-021: the record changes while the span is open', () {
      final tracer = RecordingTracer();
      late final String? before;
      late final String? after;

      tracer.trace(_name, (span) {
        before = tracer.spans.single.attributes['k'] as String?;
        span.setAttribute('k', 'v');
        after = tracer.spans.single.attributes['k'] as String?;
      });

      expect(before, isNull);
      expect(after, 'v');
    });

    /// Requirement: doc/specs/observability-ports.md FR-021 - the record is
    ///   frozen once the span has ended: the same record shows the same state
    ///   after later work.
    /// Path: unhappy (state)
    test('FR-021: the record is frozen after the span ends', () {
      final tracer = RecordingTracer();
      late final Span kept;
      tracer.trace(_name, (span) => kept = span);
      final record = tracer.spans.single;

      expect(() => kept.setAttribute('k', 'v'), throwsStateError);
      expect(() => kept.setStatus(SpanStatus.error), throwsStateError);

      expect(record.attributes, isEmpty);
      expect(record.status, SpanStatus.unset);
    });

    /// Requirement: doc/specs/observability-ports.md FR-021 - spansNamed
    ///   returns only the spans with that name, in start order.
    /// Path: happy
    test('FR-021: spansNamed filters by name', () {
      final tracer = RecordingTracer();
      tracer.trace(_name, (span) => span.setAttribute('i', 1));
      tracer.trace(_inner, (span) {});
      tracer.trace(_name, (span) => span.setAttribute('i', 2));

      final named = tracer.spansNamed(_name);

      expect(named.map((s) => s.attributes['i']), [1, 2]);
      expect(tracer.spansNamed('srd5e.test.missing'), isEmpty);
    });
  });

  /// Requirement: doc/specs/observability-ports.md FR-022 - a span started
  ///   inside another records it as parent; a top-level span has none.
  /// Path: unhappy (rule interaction)
  group('RecordingTracer parent', () {
    /// Requirement: doc/specs/observability-ports.md FR-022 - a top-level span
    ///   has a null parent.
    /// Path: happy
    test('FR-022: a top-level span has no parent', () {
      final tracer = RecordingTracer();

      tracer.trace(_name, (span) {});

      expect(tracer.spans.single.parent, isNull);
    });

    /// Requirement: doc/specs/observability-ports.md FR-022 - a nested span's
    ///   parent is the outer record.
    /// Path: unhappy (rule interaction)
    test('FR-022: a nested span has the outer span as parent', () {
      final tracer = RecordingTracer();

      tracer.trace(_name, (span) => tracer.trace(_inner, (span) {}));

      final [outer, inner] = tracer.spans;
      expect(inner.parent, same(outer));
      expect(outer.parent, isNull);
    });

    /// Requirement: doc/specs/observability-ports.md FR-022 - two levels deep:
    ///   each span's parent is the span it was started in.
    /// Path: unhappy (rule interaction)
    test('FR-022: three nested spans chain their parents', () {
      final tracer = RecordingTracer();

      tracer.trace(
        _name,
        (span) =>
            tracer.trace(_inner, (span) => tracer.trace(_deeper, (span) {})),
      );

      final [outer, middle, innermost] = tracer.spans;
      expect(middle.parent, same(outer));
      expect(innermost.parent, same(middle));
    });

    /// Requirement: doc/specs/observability-ports.md FR-022 - siblings share
    ///   the parent, and a span after the parent has ended is top-level
    ///   again.
    /// Path: unhappy (rule interaction)
    test('FR-022: siblings share a parent and the stack unwinds', () {
      final tracer = RecordingTracer();

      tracer.trace(_name, (span) {
        tracer.trace(_inner, (span) {});
        tracer.trace(_deeper, (span) {});
      });
      tracer.trace('srd5e.test.after', (span) {});

      final [outer, first, second, after] = tracer.spans;
      expect(first.parent, same(outer));
      expect(second.parent, same(outer));
      expect(after.parent, isNull);
    });

    /// Requirement: doc/specs/observability-ports.md FR-022 - the stack
    ///   unwinds when the inner span throws too.
    /// Path: unhappy (failure)
    test('FR-022: a span after a failed inner span has the right parent', () {
      final tracer = RecordingTracer();

      tracer.trace(_name, (span) {
        expect(
          () => tracer.trace<void>(_inner, (span) => throw StateError('x')),
          throwsStateError,
        );
        tracer.trace(_deeper, (span) {});
      });

      final [outer, failed, later] = tracer.spans;
      expect(failed.parent, same(outer));
      expect(later.parent, same(outer));
    });

    /// Requirement: doc/specs/observability-ports.md FR-022 - sequential
    ///   async use: a traceAsync inside an awaited traceAsync has the outer as
    ///   parent.
    /// Path: unhappy (rule interaction)
    test('FR-022: sequential async spans are nested', () async {
      final tracer = RecordingTracer();

      await tracer.traceAsync(_name, (span) async {
        await tracer.traceAsync(_inner, (span) async {});
        tracer.trace(_deeper, (span) {});
      });

      final [outer, inner, last] = tracer.spans;
      expect(inner.parent, same(outer));
      expect(last.parent, same(outer));
    });
  });

  /// Requirement: doc/specs/observability-ports.md FR-023 - after the span has
  ///   ended its mutators throw StateError.
  /// Path: unhappy (state)
  group('RecordingTracer ended spans reject writes', () {
    /// Requirement: per case
    /// Path: per case
    for (final m in _mutators) {
      test('FR-023: ${m.label} after trace returned throws StateError '
          '[unhappy (state)]', () {
        final tracer = RecordingTracer();
        late final Span kept;
        tracer.trace(_name, (span) => kept = span);

        expect(() => m.call(kept), throwsStateError);
      });

      test('FR-023: ${m.label} after trace threw throws StateError '
          '[unhappy (state)]', () {
        final tracer = RecordingTracer();
        late final Span kept;
        expect(
          () => tracer.trace<void>(_name, (span) {
            kept = span;
            throw StateError('boom');
          }),
          throwsStateError,
        );

        expect(() => m.call(kept), throwsStateError);
      });

      test('FR-023: ${m.label} is allowed before the future completes and '
          'throws after [unhappy (state)]', () async {
        final tracer = RecordingTracer();
        final gate = Completer<void>();
        late final Span kept;
        final future = tracer.traceAsync(_name, (span) {
          kept = span;
          return gate.future;
        });

        expect(() => m.call(kept), returnsNormally);
        gate.complete();
        await future;

        expect(() => m.call(kept), throwsStateError);
      });
    }
  });

  /// Requirement: doc/specs/observability-ports.md FR-024 - a span name that
  ///   does not match the srd5e naming pattern is an ArgumentError.
  /// Path: unhappy (invalid input)
  group('RecordingTracer span names', () {
    /// Requirement: per case
    /// Path: per case
    for (final c in signalNameCases) {
      test('FR-024: trace ${c.label} is ${c.valid ? 'accepted' : 'rejected'} '
          '[${c.valid ? 'happy' : 'unhappy (invalid input)'}]', () {
        final tracer = RecordingTracer();
        var bodyRuns = 0;

        void run() => tracer.trace(c.name, (span) => bodyRuns++);

        if (c.valid) {
          run();
          expect(bodyRuns, 1);
          expect(tracer.spans.single.name, c.name);
        } else {
          expect(run, throwsArgumentErrorFor('name', c.name));
          expect(bodyRuns, 0);
          expect(tracer.spans, isEmpty);
        }
      });

      test('FR-024: traceAsync ${c.label} is '
          '${c.valid ? 'accepted' : 'rejected'} '
          '[${c.valid ? 'happy' : 'unhappy (invalid input)'}]', () async {
        final tracer = RecordingTracer();
        var bodyRuns = 0;

        Future<void> run() => tracer.traceAsync(c.name, (span) async {
          bodyRuns++;
        });

        if (c.valid) {
          await run();
          expect(bodyRuns, 1);
        } else {
          expect(run, throwsArgumentErrorFor('name', c.name));
          expect(bodyRuns, 0);
          expect(tracer.spans, isEmpty);
        }
      });
    }
  });

  /// Requirement: doc/specs/observability-ports.md FR-010 - an attribute value
  ///   that is not a String, bool, int or double is an ArgumentError naming
  ///   the key.
  /// Path: unhappy (invalid input)
  group('RecordingTracer attribute values', () {
    /// Requirement: per case
    /// Path: per case
    for (final c in attributeValueCases) {
      test('FR-010: a start attribute that is ${c.label} is '
          '${c.valid ? 'accepted' : 'rejected'} '
          '[${c.valid ? 'happy' : 'unhappy (invalid input)'}]', () {
        final tracer = RecordingTracer();
        var bodyRuns = 0;

        void run() => tracer.trace(
          _name,
          (span) => bodyRuns++,
          attributes: {'key': c.value},
        );

        if (c.valid) {
          run();
          expect(tracer.spans.single.attributes['key'], c.value);
        } else {
          expect(run, throwsArgumentErrorFor('key', c.value));
          expect(bodyRuns, 0);
          expect(tracer.spans, isEmpty);
        }
      });

      test('FR-010: setAttribute with ${c.label} is '
          '${c.valid ? 'accepted' : 'rejected'} '
          '[${c.valid ? 'happy' : 'unhappy (invalid input)'}]', () {
        final tracer = RecordingTracer();

        void run() => tracer.trace(_name, (span) {
          span.setAttribute('key', c.value);
        });

        if (c.valid) {
          run();
          expect(tracer.spans.single.attributes['key'], c.value);
        } else {
          expect(run, throwsArgumentErrorFor('key', c.value));
        }
      });
    }
  });

  /// Requirement: doc/specs/observability-ports.md FR-047 - lists and maps the
  ///   double exposes are unmodifiable, and a stored attributes map does not
  ///   change when the caller changes the map it passed.
  /// Path: unhappy (immutability)
  group('RecordingTracer immutability', () {
    /// Requirement: doc/specs/observability-ports.md FR-047 - spans and
    ///   spansNamed are unmodifiable.
    /// Path: unhappy (immutability)
    test('FR-047: spans and spansNamed cannot be changed', () {
      final tracer = RecordingTracer()..trace(_name, (span) {});

      expect(() => tracer.spans.clear(), throwsUnsupportedError);
      expect(() => tracer.spansNamed(_name).clear(), throwsUnsupportedError);
      expect(tracer.spans, hasLength(1));
    });

    /// Requirement: doc/specs/observability-ports.md FR-047 - a span's errors
    ///   and attributes are unmodifiable views.
    /// Path: unhappy (immutability)
    test('FR-047: a span record cannot be changed from outside', () {
      final tracer = RecordingTracer();
      tracer.trace(_name, (span) {
        span.setAttribute('k', 'v');
        span.recordError(StateError('x'), StackTrace.current);
      });
      final record = tracer.spans.single;

      expect(() => record.errors.clear(), throwsUnsupportedError);
      expect(() => record.attributes['k'] = 'changed', throwsUnsupportedError);
      expect(record.attributes, {'k': 'v'});
      expect(record.errors, hasLength(1));
    });

    /// Requirement: doc/specs/observability-ports.md FR-047 - the start
    ///   attributes are copied: changing the caller's map later changes
    ///   nothing.
    /// Path: unhappy (immutability)
    test('FR-047: start attributes are copied', () {
      final tracer = RecordingTracer();
      final passed = <String, Object>{'k': 'v'};

      tracer.trace(_name, (span) {
        passed['k'] = 'changed';
        passed['extra'] = 1;
      }, attributes: passed);

      expect(tracer.spans.single.attributes, {'k': 'v'});
    });
  });

  /// Requirement: doc/specs/observability-ports.md FR-046 - clear removes the
  ///   span records.
  /// Path: unhappy (state)
  test('RecordingTracer.clear removes the spans', () {
    final tracer = RecordingTracer()..trace(_name, (span) {});

    tracer.clear();

    expect(tracer.spans, isEmpty);
    tracer.trace(_inner, (span) {});
    expect(tracer.spans.single.name, _inner);
  });
}
