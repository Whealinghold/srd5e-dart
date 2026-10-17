import 'package:srd5e/src/content/application/content_decode_result.dart';
import 'package:srd5e/src/content/application/content_problem.dart';
import 'package:srd5e/src/content/application/content_signals.dart';
import 'package:srd5e/src/content/application/load_content_set.dart';
import 'package:srd5e/src/content/domain/content_entry.dart';
import 'package:srd5e/src/content/domain/content_id.dart';
import 'package:srd5e/src/content/domain/content_key.dart';
import 'package:srd5e/src/content/domain/content_kind.dart';
import 'package:srd5e/src/content/domain/content_problem_kind.dart';
import 'package:srd5e/src/content/domain/content_set.dart';
import 'package:srd5e/src/shared_ports/errors/srd5e_exception.dart';
import 'package:srd5e/src/shared_ports/observability/tracer.dart';
import 'package:srd5e/src/shared_ports/signals.dart';
import 'package:srd5e/testing.dart';
import 'package:test/test.dart';

import '../../support/argument_error_matcher.dart';

/// The document text every run loads; only the fake decoder reads it.
const _document = '{"schemaVersion": 1}';

/// A minimal entry: only its key. Whole entries are the kind specs' concern;
/// the load rules are about keys and kinds.
final class _StubEntry implements ContentEntry {
  const _StubEntry(this.key);

  @override
  final ContentKey key;

  @override
  bool operator ==(Object other) => other is _StubEntry && other.key == key;

  @override
  int get hashCode => key.hashCode;
}

/// A thrown test port failure. Its `errorType` is the snake_case of its name,
/// as every real `Srd5eException` subtype's is.
final class _TestPortException extends Srd5eException {
  const _TestPortException();

  @override
  String get errorType => 'test_port_exception';
}

_StubEntry _entry(ContentKind kind, String id) =>
    _StubEntry(ContentKey(kind, ContentId(id)));

/// One run of the use case: over a fake decoder scripted with [result] or,
/// instead, throwing [error], with recording observability timing [duration].
final class _Run {
  _Run({
    ContentDecodeResult? result,
    Object? error,
    Duration duration = Duration.zero,
  }) : decoder = FakeContentSetDecoder(
         results: {_document: ?result},
         errors: {_document: ?error},
       ),
       recorded = RecordingObservability(timedDuration: duration) {
    useCase = LoadContentSet(decoder, observability: recorded.observability);
  }

  /// The scripted, recording port.
  final FakeContentSetDecoder decoder;

  /// The recording bundle the use case was given.
  final RecordingObservability recorded;

  /// The use case under test.
  late final LoadContentSet useCase;
}

/// The exhaustive switch the sealed result demands: no default branch compiles
/// only while the family has exactly these two variants.
String _variantOf(LoadContentSetResult result) => switch (result) {
  LoadContentSetLoaded() => 'loaded',
  LoadContentSetRejected() => 'rejected',
};

void main() {
  /// Requirement: doc/rules/observability.md §9, §5 - metric, span and
  ///   attribute names are public contract; tests pin them against
  ///   accidental renames.
  /// Path: happy
  test('the signal and attribute constants are pinned literally', () {
    expect(ContentSignals.loadSpan, 'srd5e.content.load');
    expect(ContentSignals.decodeSpan, 'srd5e.content.decode');
    expect(ContentSignals.loadsMetric, 'srd5e.content.loads');
    expect(ContentSignals.decodeErrorsMetric, 'srd5e.content.decode_errors');
    expect(ContentSignals.entriesLoadedMetric, 'srd5e.content.entries_loaded');
    expect(ContentSignals.loadDurationMetric, 'srd5e.content.load_duration');
    expect(ContentSignals.kindAttribute, 'srd5e.content.kind');
    expect(ContentSignals.problemKindAttribute, 'srd5e.content.problem_kind');
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-101 - the
  ///   `srd5e.content.kind` value is the snake_case of the registered
  ///   `ContentKind` name.
  /// Path: happy
  test('kindValue maps every registered kind to its snake_case value', () {
    final values = {
      for (final kind in ContentKind.values)
        kind: ContentSignals.kindValue(kind),
    };

    expect(values, {
      ContentKind.species: 'species',
      ContentKind.background: 'background',
      ContentKind.characterClass: 'character_class',
      ContentKind.feat: 'feat',
      ContentKind.equipment: 'equipment',
      ContentKind.spell: 'spell',
      ContentKind.magicItem: 'magic_item',
      ContentKind.monster: 'monster',
      ContentKind.poison: 'poison',
      ContentKind.trap: 'trap',
      ContentKind.contagion: 'contagion',
    });
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-100 - the
  ///   `srd5e.content.problem_kind` value is the snake_case of the
  ///   `ContentProblemKind` name; `error.type` is never used for a returned
  ///   failure.
  /// Path: happy
  test('problemKindValue maps every kind to its snake_case value', () {
    final values = {
      for (final kind in ContentProblemKind.values)
        kind: ContentSignals.problemKindValue(kind),
    };

    expect(values, {
      ContentProblemKind.syntax: 'syntax',
      ContentProblemKind.unsupportedVersion: 'unsupported_version',
      ContentProblemKind.missingField: 'missing_field',
      ContentProblemKind.unknownField: 'unknown_field',
      ContentProblemKind.wrongType: 'wrong_type',
      ContentProblemKind.outOfRange: 'out_of_range',
      ContentProblemKind.invalidValue: 'invalid_value',
      ContentProblemKind.duplicate: 'duplicate',
      ContentProblemKind.unresolvedReference: 'unresolved_reference',
      ContentProblemKind.constraintViolation: 'constraint_violation',
    });
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-102, FR-077 -
  ///   the use-case result is a sealed type with exactly the two
  ///   operation-prefixed variants, exhaustive in a switch without a default.
  /// Path: happy
  test(
    'an exhaustive switch covers both result variants without a default',
    () {
      expect(_variantOf(LoadContentSetLoaded(ContentSet(const []))), 'loaded');
      expect(
        _variantOf(
          LoadContentSetRejected(const [
            ContentProblem('', ContentProblemKind.syntax),
          ]),
        ),
        'rejected',
      );
    },
  );

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-077 - the loaded
  ///   variant carries the very `ContentSet` instance the port returned, and
  ///   the port is called exactly once with the command's document.
  /// Path: happy
  test('a loaded result carries the port set and calls the port once', () {
    final set = ContentSet(const []);
    final run = _Run(result: ContentDecoded(set));

    final result = run.useCase.call(const LoadContentSetCommand(_document));

    expect(result, isA<LoadContentSetLoaded>());
    expect((result as LoadContentSetLoaded).contentSet, same(set));
    expect(run.decoder.inputs, [_document]);
    expect(run.recorded.tracer.spans, hasLength(2));
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-097 - the result
  ///   variants have value equality and a consistent hashCode; a loaded and a
  ///   rejected result are never equal.
  /// Path: happy
  test('result equality', () {
    final problems = [
      const ContentProblem('/spells/0/school', ContentProblemKind.missingField),
    ];
    final loaded = LoadContentSetLoaded(ContentSet(const []));
    final rejected = LoadContentSetRejected(problems);

    expect(loaded, LoadContentSetLoaded(ContentSet(const [])));
    expect(
      loaded.hashCode,
      LoadContentSetLoaded(ContentSet(const [])).hashCode,
    );
    expect(rejected, LoadContentSetRejected(problems));
    expect(rejected.hashCode, LoadContentSetRejected(problems).hashCode);
    expect(loaded, isNot(rejected));
    expect(
      rejected,
      isNot(
        LoadContentSetRejected(const [
          ContentProblem('', ContentProblemKind.syntax),
        ]),
      ),
    );
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-017, FR-077 -
  ///   the rejected variant rejects an empty problem list with ArgumentError
  ///   and holds an unmodifiable defensive copy.
  /// Path: unhappy (immutability)
  test('the rejected result rejects an empty list and copies defensively', () {
    expect(
      () => LoadContentSetRejected(const []),
      throwsArgumentErrorFor('problems', const <ContentProblem>[]),
    );

    final problems = [
      const ContentProblem('/spells/0/school', ContentProblemKind.missingField),
      const ContentProblem('', ContentProblemKind.syntax),
    ];
    final rejected = LoadContentSetRejected(problems);
    problems.clear();

    expect(rejected.problems, hasLength(2));
    expect(() => rejected.problems.clear(), throwsUnsupportedError);
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-077 - the
  ///   rejected variant carries the port's problems as an equal list, never
  ///   empty.
  /// Path: unhappy (failure)
  test('a rejected result carries the port problems', () {
    const problems = [
      ContentProblem('/spells/0/school', ContentProblemKind.missingField),
    ];
    final run = _Run(result: ContentDecodeFailed(problems));

    final result = run.useCase.call(const LoadContentSetCommand(_document));

    expect(result, LoadContentSetRejected(problems));
    expect((result as LoadContentSetRejected).problems, const [
      ContentProblem('/spells/0/school', ContentProblemKind.missingField),
    ]);
    expect(run.decoder.inputs, [_document]);
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-079 - the load
  ///   runs inside `srd5e.content.load` with the child span
  ///   `srd5e.content.decode` around the port call, both carrying
  ///   `srd5e.outcome=success` and no error status on a loaded document.
  /// Path: happy
  test('a loaded document spans the load and the decode, successful', () {
    final run = _Run(result: ContentDecoded(ContentSet(const [])));

    run.useCase.call(const LoadContentSetCommand(_document));

    final loads = run.recorded.tracer.spansNamed(ContentSignals.loadSpan);
    final decodes = run.recorded.tracer.spansNamed(ContentSignals.decodeSpan);
    expect(loads, hasLength(1));
    expect(decodes, hasLength(1));
    expect(decodes.single.parent, same(loads.single));
    for (final span in run.recorded.tracer.spans) {
      expect(span.attributes[AttributeKeys.outcome], 'success');
      expect(span.status, SpanStatus.unset);
      expect(span.errors, isEmpty);
    }
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-080 - one
  ///   `srd5e.content.loads` count with `srd5e.outcome=success`, and one
  ///   `srd5e.content.load_duration` measurement with no attributes, through
  ///   the injected `Meter.time`.
  /// Path: happy
  test('a loaded document counts one load and times one duration', () {
    final run = _Run(
      result: ContentDecoded(ContentSet(const [])),
      duration: const Duration(milliseconds: 250),
    );

    run.useCase.call(const LoadContentSetCommand(_document));

    final loads = run.recorded.meter.measurementsNamed(
      ContentSignals.loadsMetric,
    );
    expect(loads, hasLength(1));
    expect(loads.single.value, 1);
    expect(loads.single.unit, '{load}');
    expect(loads.single.attributes, {AttributeKeys.outcome: 'success'});

    final durations = run.recorded.meter.measurementsNamed(
      ContentSignals.loadDurationMetric,
    );
    expect(durations, hasLength(1));
    expect(durations.single.value, 0.25);
    expect(durations.single.unit, 's');
    expect(durations.single.attributes, isEmpty);
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-081 - the
  ///   entries per kind are added to `srd5e.content.entries_loaded` with
  ///   `srd5e.content.kind`; a two-kind set gives exactly two adds, never
  ///   `add(0)`; doc/specs/content-schema-and-decoder.md FR-085 - the
  ///   attributes are low-cardinality: only the kind value, no path, id,
  ///   name or text.
  /// Path: happy
  test('a two-kind set adds exactly two entries_loaded counts', () {
    final run = _Run(
      result: ContentDecoded(
        ContentSet([
          _entry(ContentKind.species, 'human'),
          _entry(ContentKind.spell, 'b'),
          _entry(ContentKind.spell, 'a'),
        ]),
      ),
    );

    run.useCase.call(const LoadContentSetCommand(_document));

    final entries = run.recorded.meter.measurementsNamed(
      ContentSignals.entriesLoadedMetric,
    );
    expect(entries, hasLength(2));
    expect(entries[0].attributes, {ContentSignals.kindAttribute: 'species'});
    expect(entries[0].value, 1);
    expect(entries[0].unit, '{entry}');
    expect(entries[1].attributes, {ContentSignals.kindAttribute: 'spell'});
    expect(entries[1].value, 2);
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-101 - the kind
  ///   attribute value is the snake_case of the registered name, so a class
  ///   entry reports `character_class`, and the counts follow the set's kind
  ///   order (FR-071): characterClass, then equipment before spell.
  /// Path: happy
  test('entries_loaded reports character_class and counts equipment first', () {
    final run = _Run(
      result: ContentDecoded(
        ContentSet([
          _entry(ContentKind.characterClass, 'wizard'),
          _entry(ContentKind.spell, 'light'),
          _entry(ContentKind.equipment, 'longsword'),
        ]),
      ),
    );

    run.useCase.call(const LoadContentSetCommand(_document));

    final entries = run.recorded.meter.measurementsNamed(
      ContentSignals.entriesLoadedMetric,
    );
    expect(entries, hasLength(3));
    expect(entries[0].attributes, {
      ContentSignals.kindAttribute: 'character_class',
    });
    expect(entries[1].attributes, {ContentSignals.kindAttribute: 'equipment'});
    expect(entries[2].attributes, {ContentSignals.kindAttribute: 'spell'});
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-081 - only kinds
  ///   with at least one entry are recorded: a kind with zero entries gets no
  ///   add call, not `add(0)`.
  /// Path: unhappy (empty case)
  test('an empty set adds no entries_loaded count', () {
    final run = _Run(result: ContentDecoded(ContentSet(const [])));

    run.useCase.call(const LoadContentSetCommand(_document));

    expect(
      run.recorded.meter.measurementsNamed(ContentSignals.entriesLoadedMetric),
      isEmpty,
    );
    expect(
      run.recorded.meter.measurementsNamed(ContentSignals.loadsMetric),
      hasLength(1),
    );
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-082, FR-100 - a
  ///   rejected load sets both spans to error status with
  ///   `srd5e.outcome=failure`, adds `srd5e.content.decode_errors` once per
  ///   problem kind with `srd5e.content.problem_kind`, increments `loads`
  ///   once with `failure`, and sets `error.type` nowhere.
  /// Path: unhappy (failure)
  test('a rejected document records the failure once and errors per kind', () {
    const problems = [
      ContentProblem('/spells/0/school', ContentProblemKind.missingField),
      ContentProblem('/spells/0/classes', ContentProblemKind.wrongType),
      ContentProblem('/spells/1/school', ContentProblemKind.missingField),
      ContentProblem('', ContentProblemKind.syntax),
    ];
    final run = _Run(result: ContentDecodeFailed(problems));

    run.useCase.call(const LoadContentSetCommand(_document));

    for (final span in run.recorded.tracer.spans) {
      expect(span.status, SpanStatus.error);
      expect(span.attributes[AttributeKeys.outcome], 'failure');
      expect(span.errors, isEmpty);
    }

    final loads = run.recorded.meter.measurementsNamed(
      ContentSignals.loadsMetric,
    );
    expect(loads, hasLength(1));
    expect(loads.single.attributes, {AttributeKeys.outcome: 'failure'});

    final errors = run.recorded.meter.measurementsNamed(
      ContentSignals.decodeErrorsMetric,
    );
    expect(errors, hasLength(3));
    expect(errors[0].value, 2);
    expect(errors[0].attributes, {
      ContentSignals.problemKindAttribute: 'missing_field',
    });
    expect(errors[1].value, 1);
    expect(errors[1].attributes, {
      ContentSignals.problemKindAttribute: 'wrong_type',
    });
    expect(errors[2].value, 1);
    expect(errors[2].attributes, {
      ContentSignals.problemKindAttribute: 'syntax',
    });

    expect(
      run.recorded.meter.measurementsNamed(ContentSignals.entriesLoadedMetric),
      isEmpty,
    );
    for (final measurement in run.recorded.meter.measurements) {
      expect(
        measurement.attributes.containsKey(AttributeKeys.errorType),
        isFalse,
      );
    }
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-083 - the use
  ///   case logs nothing, for either outcome.
  /// Path: unhappy (failure)
  test('neither outcome logs', () {
    final loaded = _Run(result: ContentDecoded(ContentSet(const [])));
    loaded.useCase.call(const LoadContentSetCommand(_document));
    expect(loaded.recorded.logger.records, isEmpty);

    final rejected = _Run(
      result: ContentDecodeFailed(const [
        ContentProblem('', ContentProblemKind.syntax),
      ]),
    );
    rejected.useCase.call(const LoadContentSetCommand(_document));
    expect(rejected.recorded.logger.records, isEmpty);
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-084 - the result
  ///   is identical with the no-op `Observability` and with a recording one.
  /// Path: happy
  test('the loaded result is identical with no-op and recording telemetry', () {
    final set = ContentSet(const []);
    final scripted = ContentDecoded(set);
    final quiet = LoadContentSet(
      FakeContentSetDecoder(results: {_document: scripted}),
    );
    final run = _Run(result: scripted);

    final fromQuiet = quiet.call(const LoadContentSetCommand(_document));
    final fromRecorded = run.useCase.call(
      const LoadContentSetCommand(_document),
    );

    expect(fromQuiet, fromRecorded);
    expect((fromRecorded as LoadContentSetLoaded).contentSet, same(set));
    expect(run.recorded.tracer.spans, hasLength(2));
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-084 - the result
  ///   is identical with the no-op `Observability` and with a recording one,
  ///   for a rejection too.
  /// Path: unhappy (failure)
  test(
    'the rejected result is identical with no-op and recording telemetry',
    () {
      const problems = [
        ContentProblem('/spells/0/school', ContentProblemKind.missingField),
      ];
      final scripted = ContentDecodeFailed(problems);
      final quiet = LoadContentSet(
        FakeContentSetDecoder(results: {_document: scripted}),
      );
      final run = _Run(result: scripted);

      final fromQuiet = quiet.call(const LoadContentSetCommand(_document));
      final fromRecorded = run.useCase.call(
        const LoadContentSetCommand(_document),
      );

      expect(fromQuiet, fromRecorded);
      expect(fromRecorded, LoadContentSetRejected(problems));
      expect(run.recorded.tracer.spans, hasLength(2));
    },
  );

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-086(a) - an
  ///   `Error` propagates unchanged and is counted by nothing; both spans end
  ///   with error status, record it and carry `srd5e.outcome=failure`;
  ///   `load_duration` still gets its one measurement; nothing is logged.
  /// Path: unhappy (failure)
  test('a StateError from the port propagates uncounted', () {
    final thrown = StateError('broken port');
    final run = _Run(
      error: thrown,
      duration: const Duration(milliseconds: 250),
    );

    expect(
      () => run.useCase.call(const LoadContentSetCommand(_document)),
      throwsA(same(thrown)),
    );

    for (final span in run.recorded.tracer.spans) {
      expect(span.status, SpanStatus.error);
      expect(span.attributes[AttributeKeys.outcome], 'failure');
      expect(span.errors.single.$1, same(thrown));
    }
    expect(
      run.recorded.meter.measurementsNamed(ContentSignals.loadsMetric),
      isEmpty,
    );
    expect(
      run.recorded.meter.measurementsNamed(ContentSignals.decodeErrorsMetric),
      isEmpty,
    );
    expect(
      run.recorded.meter.measurementsNamed(ContentSignals.entriesLoadedMetric),
      isEmpty,
    );
    expect(
      run.recorded.meter.measurementsNamed(ContentSignals.loadDurationMetric),
      hasLength(1),
    );
    expect(run.recorded.logger.records, isEmpty);
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-086(b) - a
  ///   thrown `Srd5eException` is recorded once at this boundary: rethrown
  ///   unchanged, both spans in error with `srd5e.outcome=failure`, `loads`
  ///   once with `failure` and `error.type`, the other counters unchanged, no
  ///   log.
  /// Path: unhappy (failure)
  test('a thrown Srd5eException counts one failed load with error.type', () {
    const thrown = _TestPortException();
    final run = _Run(
      error: thrown,
      duration: const Duration(milliseconds: 250),
    );

    expect(
      () => run.useCase.call(const LoadContentSetCommand(_document)),
      throwsA(same(thrown)),
    );

    for (final span in run.recorded.tracer.spans) {
      expect(span.status, SpanStatus.error);
      expect(span.attributes[AttributeKeys.outcome], 'failure');
      expect(span.errors.single.$1, same(thrown));
    }

    final loads = run.recorded.meter.measurementsNamed(
      ContentSignals.loadsMetric,
    );
    expect(loads, hasLength(1));
    expect(loads.single.value, 1);
    expect(loads.single.attributes, {
      AttributeKeys.outcome: 'failure',
      AttributeKeys.errorType: 'test_port_exception',
    });

    expect(
      run.recorded.meter.measurementsNamed(ContentSignals.decodeErrorsMetric),
      isEmpty,
    );
    expect(
      run.recorded.meter.measurementsNamed(ContentSignals.entriesLoadedMetric),
      isEmpty,
    );
    expect(
      run.recorded.meter.measurementsNamed(ContentSignals.loadDurationMetric),
      hasLength(1),
    );
    expect(run.recorded.logger.records, isEmpty);
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-086(c) - any
  ///   other thrown object has no `error.type` constant and is treated like
  ///   an `Error`: spans record it with `srd5e.outcome=failure`, nothing is
  ///   counted, it is rethrown.
  /// Path: unhappy (failure)
  test('a FormatException from the port is treated like an Error', () {
    const thrown = FormatException('not content');
    final run = _Run(
      error: thrown,
      duration: const Duration(milliseconds: 250),
    );

    expect(
      () => run.useCase.call(const LoadContentSetCommand(_document)),
      throwsA(same(thrown)),
    );

    for (final span in run.recorded.tracer.spans) {
      expect(span.status, SpanStatus.error);
      expect(span.attributes[AttributeKeys.outcome], 'failure');
      expect(span.errors.single.$1, same(thrown));
    }
    expect(
      run.recorded.meter.measurementsNamed(ContentSignals.loadsMetric),
      isEmpty,
    );
    expect(
      run.recorded.meter.measurementsNamed(ContentSignals.decodeErrorsMetric),
      isEmpty,
    );
    expect(
      run.recorded.meter.measurementsNamed(ContentSignals.entriesLoadedMetric),
      isEmpty,
    );
    expect(
      run.recorded.meter.measurementsNamed(ContentSignals.loadDurationMetric),
      hasLength(1),
    );
    expect(run.recorded.logger.records, isEmpty);
  });
}
