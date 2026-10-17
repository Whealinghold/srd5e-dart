import 'dart:collection' show UnmodifiableListView;

import 'package:collection/collection.dart' show ListEquality;
import 'package:meta/meta.dart';

import '../../shared_ports/errors/srd5e_exception.dart';
import '../../shared_ports/observability/meter.dart';
import '../../shared_ports/observability/observability.dart';
import '../../shared_ports/observability/tracer.dart';
import '../../shared_ports/signals.dart';
import '../domain/content_kind.dart';
import '../domain/content_problem_kind.dart';
import '../domain/content_set.dart';
import 'content_decode_result.dart';
import 'content_problem.dart';
import 'content_signals.dart';
import 'ports/content_set_decoder.dart';

/// The command of [LoadContentSet]: the document text to decode.
@immutable
final class LoadContentSetCommand {
  /// Creates the command over the document [document].
  const LoadContentSetCommand(this.document);

  /// The document text, exactly as the consumer read it.
  final String document;
}

/// The outcome of one `LoadContentSet` call (FR-077).
///
/// Switch over it exhaustively, with no default branch.
@immutable
sealed class LoadContentSetResult {
  const LoadContentSetResult();
}

/// The document loaded (FR-077).
///
/// [contentSet] is the very instance the port returned for its
/// `ContentDecoded`, untouched by the use case.
@immutable
final class LoadContentSetLoaded extends LoadContentSetResult {
  /// Carries the loaded [contentSet].
  const LoadContentSetLoaded(this.contentSet);

  /// The loaded entries; immutable, its lists unmodifiable (FR-071).
  final ContentSet contentSet;

  @override
  bool operator ==(Object other) =>
      other is LoadContentSetLoaded && other.contentSet == contentSet;

  @override
  int get hashCode => Object.hash(LoadContentSetLoaded, contentSet);
}

/// The document was rejected (FR-077).
///
/// [problems] holds every problem found, in the port's order (FR-016); it is
/// never empty (the constructor throws an [ArgumentError] for an empty list,
/// FR-017) and is an unmodifiable defensive copy: later changes to the
/// caller's list leave the result unchanged.
@immutable
final class LoadContentSetRejected extends LoadContentSetResult {
  /// Creates the rejection over an ordered copy of [problems].
  ///
  /// Throws an [ArgumentError] carrying the name `problems` when the list is
  /// empty (FR-017).
  factory LoadContentSetRejected(List<ContentProblem> problems) {
    if (problems.isEmpty) {
      throw ArgumentError.value(
        problems,
        'problems',
        'must hold at least one problem',
      );
    }
    return LoadContentSetRejected._(
      UnmodifiableListView<ContentProblem>(List<ContentProblem>.of(problems)),
    );
  }

  const LoadContentSetRejected._(this.problems);

  /// Every problem found, in the port's order; unmodifiable.
  final List<ContentProblem> problems;

  @override
  bool operator ==(Object other) =>
      other is LoadContentSetRejected &&
      const ListEquality<ContentProblem>().equals(other.problems, problems);

  @override
  int get hashCode =>
      Object.hash(LoadContentSetRejected, Object.hashAll(problems));
}

/// Loads one content document: runs the [ContentSetDecoder] port over the
/// command's text and returns the set, or every problem found
/// (content-schema-and-decoder.md FR-077).
///
/// The use case orchestrates and contains no rules logic. It composes only the
/// port and its own observability (FR-131): one port call inside the
/// `srd5e.content.decode` child span, wrapped by the `srd5e.content.load`
/// span and the `srd5e.content.load_duration` timing (FR-079, FR-080); one
/// `srd5e.content.loads` count per call that returns or throws an
/// [Srd5eException]; the entries per kind on
/// `srd5e.content.entries_loaded` (FR-081); the problems per kind on
/// `srd5e.content.decode_errors` of a rejected document, whose spans carry
/// error status (FR-082). Nothing is logged, for either outcome (FR-083).
/// The whole-set reference validation is not part of loading: a host or
/// `BundledContentSource` runs `validateContentSet` beside it (FR-131).
///
/// The [ContentSetDecoder] is taken through the constructor, typed as the
/// port; [observability] defaults to `Observability.none`, so omitting it is
/// silent and the result is identical with a recording one (FR-084). Both
/// ports are synchronous, so `call` is synchronous and returns its result
/// directly. The port never throws for content (FR-078); anything thrown
/// anyway is handled by what it is (FR-086): an `Error` or any other object
/// propagates unchanged and is counted by nothing, while a thrown
/// [Srd5eException] is recorded once here — `loads` gains one `failure` with
/// `error.type` — and rethrown unchanged. `load_duration` gets one
/// measurement on every path.
@immutable
final class LoadContentSet {
  /// Creates the use case. The observability instruments are created once,
  /// here, from the injected [observability].
  LoadContentSet(
    this._decoder, {
    Observability observability = Observability.none,
  }) : _observability = observability,
       _loads = observability.meter.createCounter(
         ContentSignals.loadsMetric,
         unit: '{load}',
         description: 'Content set loads attempted, by outcome.',
       ),
       _decodeErrors = observability.meter.createCounter(
         ContentSignals.decodeErrorsMetric,
         unit: '{problem}',
         description: 'Problems in rejected content documents, by kind.',
       ),
       _entriesLoaded = observability.meter.createCounter(
         ContentSignals.entriesLoadedMetric,
         unit: '{entry}',
         description: 'Content entries loaded, by content kind.',
       ),
       _duration = observability.meter.createHistogram(
         ContentSignals.loadDurationMetric,
         unit: 's',
         description: 'Duration of loading one content document.',
       );

  final ContentSetDecoder _decoder;

  final Observability _observability;

  final Counter _loads;

  final Counter _decodeErrors;

  final Counter _entriesLoaded;

  final Histogram _duration;

  /// Loads [command] and returns the result. Synchronous: the port is.
  LoadContentSetResult call(LoadContentSetCommand command) {
    return _observability.tracer.trace(ContentSignals.loadSpan, (loadSpan) {
      // The timing encloses the work inside the span, so a failure reaches
      // the span after the duration is recorded: one measurement on every
      // path, a throw included (FR-080, FR-086).
      return _observability.meter.time(_duration, () {
        try {
          final decoded = _decode(command);
          return switch (decoded) {
            ContentDecoded(contentSet: final contentSet) => _loaded(
              loadSpan,
              contentSet,
            ),
            ContentDecodeFailed(problems: final problems) => _rejected(
              loadSpan,
              problems,
            ),
          };
        } on Srd5eException catch (error) {
          // Recorded exactly once, here (FR-086(b)); the error statuses and
          // the recorded exceptions on both spans are the Tracer's
          // record-and-rethrow. No log: the caller sees the throw.
          _markThrown(loadSpan);
          _loads.add(
            1,
            attributes: <String, Object>{
              AttributeKeys.outcome: ContentSignals.outcomeFailureValue,
              AttributeKeys.errorType: error.errorType,
            },
          );
          rethrow;
        } on Object {
          // An Error or any other thrown object is a bug in the port, not a
          // load outcome: it is counted by nothing (FR-086(a), (c)). This
          // clause only records and rethrows (architecture.md §6).
          _markThrown(loadSpan);
          rethrow;
        }
      });
    });
  }

  /// Runs the port call inside the `srd5e.content.decode` child span
  /// (FR-079). The span's outcome attribute is set before it ends, so a
  /// rejection, and a throw from the port just the same, leave it carrying
  /// `srd5e.outcome=failure` beside the error status (FR-082, FR-086).
  ContentDecodeResult _decode(LoadContentSetCommand command) {
    return _observability.tracer.trace(ContentSignals.decodeSpan, (decodeSpan) {
      try {
        final decoded = _decoder.decode(command.document);
        decodeSpan.setAttribute(AttributeKeys.outcome, switch (decoded) {
          ContentDecoded() => ContentSignals.outcomeSuccessValue,
          ContentDecodeFailed() => ContentSignals.outcomeFailureValue,
        });
        // A rejected decode is a failure result, so the span carries error
        // status although the result returns normally (observability.md §6).
        if (decoded is ContentDecodeFailed) {
          decodeSpan.setStatus(SpanStatus.error);
        }
        return decoded;
      } on Object {
        decodeSpan.setAttribute(
          AttributeKeys.outcome,
          ContentSignals.outcomeFailureValue,
        );
        rethrow;
      }
    });
  }

  /// Records a successful load: the outcome on the span, one `loads` count,
  /// and the entries per kind (FR-080, FR-081). Only kinds with at least one
  /// entry are counted — a kind with none gets no add call, never `add(0)`.
  LoadContentSetLoaded _loaded(Span loadSpan, ContentSet contentSet) {
    loadSpan.setAttribute(
      AttributeKeys.outcome,
      ContentSignals.outcomeSuccessValue,
    );
    _loads.add(
      1,
      attributes: <String, Object>{
        AttributeKeys.outcome: ContentSignals.outcomeSuccessValue,
      },
    );
    final entriesByKind = <ContentKind, int>{};
    for (final entry in contentSet.entries) {
      entriesByKind[entry.key.kind] = (entriesByKind[entry.key.kind] ?? 0) + 1;
    }
    // The set is ordered by kind (FR-071), so the counts are added in kind
    // declaration order.
    for (final MapEntry(key: kind, value: count) in entriesByKind.entries) {
      _entriesLoaded.add(
        count,
        attributes: <String, Object>{
          ContentSignals.kindAttribute: ContentSignals.kindValue(kind),
        },
      );
    }
    return LoadContentSetLoaded(contentSet);
  }

  /// Records a rejected load: the outcome and the error status on the span,
  /// one `loads` failure, and one `decode_errors` add per problem kind
  /// (FR-082). Nothing is logged — the consumer holds every problem in the
  /// result (FR-083).
  LoadContentSetRejected _rejected(
    Span loadSpan,
    List<ContentProblem> problems,
  ) {
    loadSpan.setAttribute(
      AttributeKeys.outcome,
      ContentSignals.outcomeFailureValue,
    );
    loadSpan.setStatus(SpanStatus.error);
    _loads.add(
      1,
      attributes: <String, Object>{
        AttributeKeys.outcome: ContentSignals.outcomeFailureValue,
      },
    );
    final problemsByKind = <ContentProblemKind, int>{};
    for (final problem in problems) {
      problemsByKind[problem.kind] = (problemsByKind[problem.kind] ?? 0) + 1;
    }
    for (final MapEntry(key: kind, value: count) in problemsByKind.entries) {
      _decodeErrors.add(
        count,
        attributes: <String, Object>{
          ContentSignals.problemKindAttribute: ContentSignals.problemKindValue(
            kind,
          ),
        },
      );
    }
    return LoadContentSetRejected(problems);
  }

  /// Marks the load span as failed because something was thrown. The span's
  /// error status and the recorded exception are the Tracer's
  /// record-and-rethrow, shared by every throw path (FR-086).
  void _markThrown(Span loadSpan) {
    loadSpan.setAttribute(
      AttributeKeys.outcome,
      ContentSignals.outcomeFailureValue,
    );
  }
}
