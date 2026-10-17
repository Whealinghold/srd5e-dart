import 'dart:async' show runZoned, ZoneSpecification;

import 'package:srd5e/adapters.dart';
import 'package:srd5e/src/content/application/content_decode_result.dart'
    show ContentDecodeFailed, ContentDecoded;
import 'package:srd5e/src/content/application/content_problem.dart'
    show ContentProblem;
import 'package:srd5e/src/content/domain/content_entry.dart';
import 'package:srd5e/src/content/domain/content_id.dart';
import 'package:srd5e/src/content/domain/content_key.dart';
import 'package:srd5e/src/content/domain/content_kind.dart';
import 'package:srd5e/src/content/domain/content_lookup.dart';
import 'package:srd5e/src/content/domain/content_problem_kind.dart';
import 'package:srd5e/src/content/domain/content_reference.dart';
import 'package:srd5e/src/content/domain/content_reference_problem.dart';
import 'package:srd5e/src/content/domain/content_set.dart';
import 'package:srd5e/testing.dart';
import 'package:test/test.dart';

import '../../support/argument_error_matcher.dart';

/// A minimal entry: only its key.
final class _StubEntry implements ContentEntry {
  const _StubEntry(this.key);

  @override
  final ContentKey key;

  @override
  bool operator ==(Object other) => other is _StubEntry && other.key == key;

  @override
  int get hashCode => key.hashCode;

  @override
  String toString() => 'Stub(${key.kind.name}/${key.id.value})';
}

/// An entry with one reference site, to drive a dangling reference through
/// the whole-set validation inside the adapter.
final class _ReferencingEntry implements ContentEntry, ContentReferences {
  const _ReferencingEntry(this.key, this.target);

  @override
  final ContentKey key;

  final ContentKey target;

  @override
  Iterable<ContentReference> get references => [
    ContentReference('companion', target),
  ];

  @override
  bool operator ==(Object other) =>
      other is _ReferencingEntry && other.key == key && other.target == target;

  @override
  int get hashCode => Object.hash(key, target);
}

_StubEntry _entry(ContentKind kind, String id) =>
    _StubEntry(ContentKey(kind, ContentId(id)));

ContentKey _key(ContentKind kind, String id) => ContentKey(kind, ContentId(id));

ContentSet _setOf(ContentEntry entry) => ContentSet([entry]);

/// A zone whose timer creation fails the test (FR-024, FR-060).
R _noTimerZone<R>(R Function() body) {
  Never failTimer(String what) => throw StateError('$what was created');
  return runZoned(
    body,
    zoneSpecification: ZoneSpecification(
      createTimer: (self, parent, zone, duration, callback) =>
          failTimer('A Timer'),
      createPeriodicTimer: (self, parent, zone, duration, callback) =>
          failTimer('A periodic Timer'),
    ),
  );
}

void main() {
  /// Requirement: doc/specs/content-source-port.md FR-059 - the constructor
  ///   decodes each text once with the injected decoder and hands the
  ///   decoded sets to the whole-set validation.
  /// Path: happy
  test('one decode call per text, in text order', () {
    final first = _setOf(_entry(ContentKind.spell, 'light'));
    final second = _setOf(_entry(ContentKind.feat, 'alert'));
    final decoder = FakeContentSetDecoder(
      results: {
        'first text': ContentDecoded(first),
        'second text': ContentDecoded(second),
      },
    );

    BundledContentSource(
      texts: {'a.json': 'first text', 'b.json': 'second text'},
      decoder: decoder,
    );

    expect(decoder.inputs, ['first text', 'second text']);
  });

  /// Requirement: doc/specs/content-source-port.md FR-059, FR-062 - the
  ///   results equal an InMemoryContentSource over the same entries, entry
  ///   for entry and in the same order.
  /// Path: happy
  test(
    'results equal an InMemoryContentSource over the same entries',
    () async {
      final entries = [
        _entry(ContentKind.spell, 'light'),
        _entry(ContentKind.feat, 'alert'),
      ];
      final decoder = FakeContentSetDecoder(
        results: {'text': ContentDecoded(ContentSet(entries))},
      );
      final bundled = BundledContentSource(
        texts: {'x': 'text'},
        decoder: decoder,
      );
      final inMemory = InMemoryContentSource(entries);
      final key = _key(ContentKind.spell, 'light');

      expect(await bundled.lookup(key), await inMemory.lookup(key));
      expect(
        await bundled.listKind(ContentKind.spell),
        await inMemory.listKind(ContentKind.spell),
      );
      expect(
        await bundled.listKind(ContentKind.feat),
        await inMemory.listKind(ContentKind.feat),
      );
    },
  );

  /// Requirement: doc/specs/content-source-port.md FR-060, FR-024 -
  ///   lookup and listKind complete using microtasks only: no Timer.
  /// Path: happy
  test('lookup and listKind create no Timer', () async {
    final decoder = FakeContentSetDecoder(
      results: {
        'text': ContentDecoded(_setOf(_entry(ContentKind.spell, 'light'))),
      },
    );
    final source = BundledContentSource(texts: {'x': 'text'}, decoder: decoder);

    await _noTimerZone(() async {
      await source.lookup(_key(ContentKind.spell, 'light'));
      await source.listKind(ContentKind.spell);
    });
  });

  /// Requirement: doc/specs/content-source-port.md FR-062 - building twice
  ///   from the same texts yields sources whose results are equal, entry for
  ///   entry and in the same order.
  /// Path: happy
  test('two builds give equal ordered results', () async {
    List<ContentEntry> entries() => [
      _entry(ContentKind.feat, 'alert'),
      _entry(ContentKind.spell, 'light'),
    ];
    BundledContentSource build() => BundledContentSource(
      texts: {'x': 'text'},
      decoder: FakeContentSetDecoder(
        results: {'text': ContentDecoded(ContentSet(entries()))},
      ),
    );

    final first = build();
    final second = build();
    final key = _key(ContentKind.spell, 'light');

    expect(await first.lookup(key), await second.lookup(key));
    expect(
      await first.listKind(ContentKind.spell),
      await second.listKind(ContentKind.spell),
    );
  });

  /// Requirement: doc/specs/content-source-port.md FR-062 - with an empty
  ///   index it behaves as an empty source (FR-022).
  /// Path: unhappy (empty case)
  test('an empty index gives an empty source', () async {
    final source = BundledContentSource(
      texts: const {},
      decoder: FakeContentSetDecoder(
        defaultResult: ContentDecoded(ContentSet(const [])),
      ),
    );
    final key = _key(ContentKind.spell, 'light');

    expect(await source.lookup(key), ContentNotFound(key));
    expect(await source.listKind(ContentKind.spell), isEmpty);
  });

  /// Requirement: doc/specs/content-source-port.md FR-061 - a corrupted
  ///   text throws BundledContentInvalid whose decodeProblems equal the
  ///   decoder's list, in order, with empty referenceProblems.
  /// Path: unhappy (invalid bundle)
  test('a corrupted text reports the decoder problems', () {
    final failure = ContentDecodeFailed([
      const ContentProblem('/species', ContentProblemKind.wrongType),
      const ContentProblem('/species/0/id', ContentProblemKind.missingField),
    ]);
    BundledContentSource source() => BundledContentSource(
      texts: {'a.json': 'corrupt'},
      decoder: FakeContentSetDecoder(results: {'corrupt': failure}),
    );

    expect(source, throwsA(isA<BundledContentInvalid>()));
    try {
      source();
    } on BundledContentInvalid catch (error) {
      expect(error.decodeProblems, failure.problems);
      expect(error.referenceProblems, isEmpty);
    }
  });

  /// Requirement: doc/specs/content-source-port.md FR-061 - a decode
  ///   failure short-circuits the validation: referenceProblems stays empty
  ///   even when a later text would also fail it, and the decode problems
  ///   are ordered document by document in index order.
  /// Path: unhappy (invalid bundle)
  test('decode problems are ordered document by document', () {
    final firstFailure = ContentDecodeFailed([
      const ContentProblem('/a', ContentProblemKind.syntax),
    ]);
    final secondFailure = ContentDecodeFailed([
      const ContentProblem('/b', ContentProblemKind.syntax),
      const ContentProblem('/b/0', ContentProblemKind.invalidValue),
    ]);
    BundledContentSource source() => BundledContentSource(
      texts: {'a.json': 'first', 'b.json': 'second'},
      decoder: FakeContentSetDecoder(
        results: {'first': firstFailure, 'second': secondFailure},
      ),
    );

    expect(source, throwsA(isA<BundledContentInvalid>()));
    try {
      source();
    } on BundledContentInvalid catch (error) {
      expect(error.decodeProblems, [
        ...firstFailure.problems,
        ...secondFailure.problems,
      ]);
      expect(error.referenceProblems, isEmpty);
    }
  });

  /// Requirement: doc/specs/content-source-port.md FR-061 - a duplicate key
  ///   across two texts is a ContentReferenceProblem of kind duplicate, not
  ///   an ArgumentError.
  /// Path: unhappy (invalid bundle)
  test('a duplicate key across texts is a reference problem', () {
    final shared = _entry(ContentKind.spell, 'light');
    BundledContentSource source() => BundledContentSource(
      texts: {'a.json': 'first', 'b.json': 'second'},
      decoder: FakeContentSetDecoder(
        results: {
          'first': ContentDecoded(_setOf(shared)),
          'second': ContentDecoded(_setOf(_entry(ContentKind.spell, 'light'))),
        },
      ),
    );

    expect(source, throwsA(isA<BundledContentInvalid>()));
    try {
      source();
    } on BundledContentInvalid catch (error) {
      expect(error.decodeProblems, isEmpty);
      expect(error.referenceProblems, hasLength(1));
      expect(error.referenceProblems.first.kind, ContentProblemKind.duplicate);
      expect(error.referenceProblems.first.target, shared.key);
    }
  });

  /// Requirement: doc/specs/content-source-port.md FR-061, FR-063 - an
  ///   entry whose reference target is in no set decodes clean and is
  ///   rejected only by the whole-set validation, as unresolvedReference.
  /// Path: unhappy (invalid bundle)
  test('a dangling reference is rejected by the validation only', () {
    final dangling = _ReferencingEntry(
      _key(ContentKind.background, 'acolyte'),
      _key(ContentKind.feat, 'absent_feat'),
    );
    BundledContentSource source() => BundledContentSource(
      texts: {'a.json': 'text'},
      decoder: FakeContentSetDecoder(
        results: {'text': ContentDecoded(_setOf(dangling))},
      ),
    );

    expect(source, throwsA(isA<BundledContentInvalid>()));
    try {
      source();
    } on BundledContentInvalid catch (error) {
      expect(error.decodeProblems, isEmpty);
      expect(error.referenceProblems, hasLength(1));
      expect(
        error.referenceProblems.first.kind,
        ContentProblemKind.unresolvedReference,
      );
      expect(error.referenceProblems.first.owner, dangling.key);
      expect(error.referenceProblems.first.target, dangling.target);
    }
  });

  /// Requirement: doc/specs/content-source-port.md FR-061 - the two lists
  ///   are unmodifiable, and the error carries no message field.
  /// Path: unhappy (immutability)
  test('the problem lists cannot be mutated', () {
    BundledContentSource build() => BundledContentSource(
      texts: {'a.json': 'corrupt'},
      decoder: FakeContentSetDecoder(
        results: {
          'corrupt': ContentDecodeFailed([
            const ContentProblem('', ContentProblemKind.syntax),
          ]),
        },
      ),
    );

    expect(build, throwsA(isA<BundledContentInvalid>()));
    try {
      build();
    } on BundledContentInvalid catch (error) {
      expect(
        () => error.decodeProblems.add(
          const ContentProblem('', ContentProblemKind.syntax),
        ),
        throwsUnsupportedError,
      );
      expect(
        () => error.referenceProblems.add(
          ContentReferenceProblem(
            owner: _key(ContentKind.spell, 'a'),
            field: '',
            target: _key(ContentKind.spell, 'a'),
            kind: ContentProblemKind.duplicate,
          ),
        ),
        throwsUnsupportedError,
      );
    }
  });

  /// Requirement: doc/specs/content-source-port.md FR-061 - the error
  ///   states at least one problem: both lists empty is an ArgumentError
  ///   carrying the name and the invalid value.
  /// Path: unhappy (invalid input)
  test('an error with both lists empty is rejected', () {
    expect(
      BundledContentInvalid.new,
      throwsArgumentErrorFor('decodeProblems', const <ContentProblem>[]),
    );
  });
}
