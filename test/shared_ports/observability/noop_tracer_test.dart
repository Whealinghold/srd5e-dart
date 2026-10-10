import 'package:srd5e/src/shared_ports/observability/tracer.dart';
import 'package:test/test.dart';

void main() {
  /// Requirement: doc/specs/observability-ports.md FR-019 - NoopTracer runs
  ///   the body once with a no-op span, returns its result and lets errors
  ///   propagate unchanged. (The shared behaviour is also run by the Tracer
  ///   contract suite.)
  /// Path: happy
  group('NoopTracer', () {
    /// Requirement: doc/specs/observability-ports.md FR-019 - trace gives the
    ///   body the same stateless span every time.
    /// Path: happy
    test('trace hands the body one shared no-op span', () {
      const tracer = NoopTracer();
      final seen = <Span>[];

      tracer.trace('srd5e.test.work', seen.add);
      tracer.trace('srd5e.test.work', seen.add);

      expect(seen, hasLength(2));
      expect(identical(seen.first, seen.last), isTrue);
    });

    /// Requirement: doc/specs/observability-ports.md FR-019 - traceAsync
    ///   gives the body the same no-op span.
    /// Path: happy
    test('traceAsync hands the body the same no-op span', () async {
      const tracer = NoopTracer();
      late final Span sync;
      late final Span async;

      tracer.trace('srd5e.test.work', (span) => sync = span);
      await tracer.traceAsync('srd5e.test.work', (span) async => async = span);

      expect(identical(sync, async), isTrue);
    });

    /// Requirement: doc/specs/observability-ports.md FR-019 - the no-op does
    ///   not validate the name or the attributes, which only the recording
    ///   doubles check.
    /// Path: unhappy (invalid input)
    test('accepts any name and any attribute value', () {
      const tracer = NoopTracer();

      final result = tracer.trace(
        'not a valid name',
        (span) => 5,
        attributes: {'k': Object()},
      );

      expect(result, 5);
    });

    /// Requirement: doc/specs/observability-ports.md FR-020 - a no-op span
    ///   accepts every mutator at any time, including after trace returned.
    /// Path: unhappy (state)
    test('a no-op span accepts mutators after trace has returned', () {
      const tracer = NoopTracer();
      late final Span kept;
      tracer.trace('srd5e.test.work', (span) => kept = span);

      void mutate() {
        kept.setAttribute('k', 'v');
        kept.setStatus(SpanStatus.error);
        kept.recordError(StateError('late'), StackTrace.current);
      }

      expect(mutate, returnsNormally);
    });

    /// Requirement: doc/specs/observability-ports.md FR-020 - and after the
    ///   future given to traceAsync has completed.
    /// Path: unhappy (state)
    test(
      'a no-op span accepts mutators after traceAsync has completed',
      () async {
        const tracer = NoopTracer();
        late final Span kept;
        await tracer.traceAsync('srd5e.test.work', (span) async => kept = span);

        void mutate() {
          kept.setAttribute('k', 1);
          kept.setStatus(SpanStatus.ok);
          kept.recordError(StateError('late'), StackTrace.current);
        }

        expect(mutate, returnsNormally);
      },
    );
  });
}
