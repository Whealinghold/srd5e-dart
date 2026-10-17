/// The shared `ContentSource` contract suite
/// (content-source-port.md FR-027, FR-058).
///
/// Two entry points, both returning the checks as a list so they can be
/// self-tested with deliberately broken adapters (FR-042) and so a
/// consumer's adapter can reuse them (FR-050):
///
/// * [contentSourceContractChecks] — for a source that can be built from an
///   arbitrary entry list: the lookup, listing, ordering, immutability,
///   determinism, empty-source and two-kinds clauses; the backend-failure
///   clauses run only when a `createFailing` factory is supplied.
/// * [contentSourceReadOnlyChecks] — for a source backed by a fixed fixture
///   (the bundled source): the same lookup and listing clauses against the
///   given [source], computed from `expectedEntries`; no group builds a
///   source.
///
/// A failed check throws [ContentSourceContractViolation] carrying the
/// check name; a passing check completes normally.
///
/// The suite is **not exported** from the package (exporting it would make
/// `package:test` a runtime dependency). To reuse it against your own
/// adapter, copy this file into your tests.
library;

import 'package:srd5e/src/content/application/ports/content_source.dart';
import 'package:srd5e/src/content/domain/content_entry.dart';
import 'package:srd5e/src/content/domain/content_id.dart';
import 'package:srd5e/src/content/domain/content_key.dart';
import 'package:srd5e/src/content/domain/content_kind.dart';
import 'package:srd5e/src/content/domain/content_lookup.dart';
import 'package:srd5e/src/content/domain/content_query.dart';
import 'package:srd5e/src/content/domain/missing_content.dart';
import 'package:test/test.dart';

/// A named contract check: [run] completes normally when the contract
/// clause holds and throws a [ContentSourceContractViolation] naming
/// [name] when it does not.
final class ContentSourceCheck {
  /// Creates the check.
  const ContentSourceCheck(this.name, this.run);

  /// What the check proves, in plain words; also its test name.
  final String name;

  /// The check itself.
  final Future<void> Function() run;
}

/// A failed contract check, carrying the check [checkName] and the
/// underlying failure ([cause] with its [causeStackTrace]).
final class ContentSourceContractViolation extends Error {
  /// Creates the violation of [checkName] over the original cause.
  ContentSourceContractViolation(
    this.checkName,
    this.cause,
    this.causeStackTrace,
  );

  /// The name of the check that failed.
  final String checkName;

  /// The original failure (an assertion failure or a thrown object).
  final Object cause;

  /// The stack trace of the original failure.
  final StackTrace causeStackTrace;

  @override
  String toString() => 'ContentSourceContractViolation($checkName): $cause';
}

/// Runs [body] as a check: anything it throws becomes a
/// [ContentSourceContractViolation] carrying [name], rethrown with the
/// original stack trace.
ContentSourceCheck _check(String name, Future<void> Function() body) {
  Future<void> run() async {
    try {
      await body();
    } on Object catch (error, stackTrace) {
      Error.throwWithStackTrace(
        ContentSourceContractViolation(name, error, stackTrace),
        stackTrace,
      );
    }
  }

  return ContentSourceCheck(name, run);
}

/// The fixtures of the contract suite: clearly synthetic entries, no SRD
/// content.
final class _FixtureEntry implements ContentEntry {
  const _FixtureEntry(this.key);

  @override
  final ContentKey key;

  @override
  bool operator ==(Object other) => other is _FixtureEntry && other.key == key;

  @override
  int get hashCode => key.hashCode;

  @override
  String toString() => 'Fixture(${key.kind.name}/${key.id.value})';
}

_FixtureEntry _entry(ContentKind kind, String id) =>
    _FixtureEntry(ContentKey(kind, ContentId(id)));

ContentKey _key(ContentKind kind, String id) => ContentKey(kind, ContentId(id));

/// The entry fixture the suite builds sources over: three feats and two
/// spells, in an insertion order the id ordering clause must not follow.
final List<ContentEntry> _fixture = [
  _entry(ContentKind.feat, 'tough_hide'),
  _entry(ContentKind.feat, 'alert'),
  _entry(ContentKind.spell, 'mage_armor'),
  _entry(ContentKind.feat, 'a1_shift'),
  _entry(ContentKind.spell, 'acid_arrow'),
];

/// The ids one probe key is generated from: an id no fixture uses.
const String _absentId = 'zz_absent_probe';

/// An id held under one kind only in [_fixture].
const String _singleKindId = 'alert';

/// Builds the full contract suite
/// (content-source-port.md FR-027, FR-028).
///
/// `create` builds a fresh source over the entries; the optional
/// `createFailing` builds one whose backend throws the given non-
/// `Srd5eException` [Exception] on every call — without it, the
/// backend-failure checks are left out.
List<ContentSourceCheck> contentSourceContractChecks({
  required ContentSource Function(List<ContentEntry> entries) create,
  ContentSource Function(List<ContentEntry> entries, Exception backendFailure)?
  createFailing,
}) {
  final checks = [
    _check('lookup completes with ContentFound holding the entry', () async {
      final source = create(_fixture);
      final requested = _key(ContentKind.feat, 'alert');

      final lookup = await source.lookup(requested);

      if (lookup is! ContentFound) {
        throw StateError('expected ContentFound, got ${lookup.runtimeType}');
      }
      if (lookup.entry.key != requested) {
        throw StateError('the found entry answers ${lookup.entry.key}');
      }
    }),
    _check('lookup completes with ContentNotFound carrying the key', () async {
      final source = create(_fixture);
      final requested = _key(ContentKind.spell, _absentId);

      final lookup = await source.lookup(requested);

      if (lookup != ContentNotFound(requested)) {
        throw StateError('expected ContentNotFound($requested), got $lookup');
      }
    }),
    _check('lookup never answers another kind for a single-kind id', () async {
      final source = create(_fixture);
      final requested = _key(ContentKind.spell, _singleKindId);

      final lookup = await source.lookup(requested);

      if (lookup != ContentNotFound(requested)) {
        throw StateError(
          'an id held only as a feat answered $lookup for a spell key',
        );
      }
    }),
    _check('listKind answers every entry of the kind ordered by id', () async {
      final source = create(_fixture);

      final feats = await source.listKind(ContentKind.feat);
      final spells = await source.listKind(ContentKind.spell);

      _expectOrdered(feats, ['a1_shift', 'alert', 'tough_hide']);
      _expectOrdered(spells, ['acid_arrow', 'mage_armor']);
    }),
    _check('listKind of a kind with no entries is empty', () async {
      final source = create(_fixture);

      final monsters = await source.listKind(ContentKind.monster);

      if (monsters.isNotEmpty) {
        throw StateError('expected an empty list, got ${monsters.length}');
      }
    }),
    _check(
      'the listKind list is unmodifiable and the source unchanged',
      () async {
        final source = create(_fixture);

        final spells = await source.listKind(ContentKind.spell);
        var mutated = false;
        try {
          spells.clear();
          mutated = true;
        } on UnsupportedError {
          // The contract: mutation is refused.
        }
        if (mutated) {
          throw StateError('the list accepted clear()');
        }
        final again = await source.listKind(ContentKind.spell);
        if (again.length != 2) {
          throw StateError('the source changed after the mutation attempt');
        }
      },
    ),
    _check('repeated calls give equal results', () async {
      final source = create(_fixture);
      final requested = _key(ContentKind.spell, 'acid_arrow');

      final firstLookup = await source.lookup(requested);
      final secondLookup = await source.lookup(requested);
      final firstList = await source.listKind(ContentKind.feat);
      final secondList = await source.listKind(ContentKind.feat);

      if (firstLookup != secondLookup) {
        throw StateError('two lookups of one key differ');
      }
      if (firstList.length != secondList.length ||
          !_pairwiseEqual(firstList, secondList)) {
        throw StateError('two listKind calls differ');
      }
    }),
    _check(
      'the variants carry the entry, the key and the missing detail',
      () async {
        final source = create(_fixture);
        final requested = _key(ContentKind.feat, 'alert');

        final found = await source.lookup(requested);
        if (found is! ContentFound || found.entry.key != requested) {
          throw StateError('ContentFound does not carry its entry');
        }

        final absent = _key(ContentKind.spell, _absentId);
        final notFound = await source.lookup(absent);
        if (notFound is! ContentNotFound) {
          throw StateError('expected ContentNotFound, got $notFound');
        }
        if (notFound.key != absent) {
          throw StateError('ContentNotFound carries ${notFound.key}');
        }
        final expectedMissing = MissingContent(absent.kind, absent.id);
        if (notFound.missing != expectedMissing) {
          throw StateError('the missing detail is ${notFound.missing}');
        }
      },
    ),
    _check('an empty source answers not-found and empty everywhere', () async {
      final source = create(const []);
      final requested = _key(ContentKind.spell, _absentId);

      if (await source.lookup(requested) != ContentNotFound(requested)) {
        throw StateError('an empty source answered a lookup');
      }
      for (final kind in ContentKind.values) {
        final entries = await source.listKind(kind);
        if (entries.isNotEmpty) {
          throw StateError('an empty source listed ${kind.name}');
        }
      }
    }),
    _check('the same id under two kinds is found under both', () async {
      final source = create([
        _entry(ContentKind.spell, 'shared_name'),
        _entry(ContentKind.feat, 'shared_name'),
      ]);

      final spell = await source.lookup(_key(ContentKind.spell, 'shared_name'));
      final feat = await source.lookup(_key(ContentKind.feat, 'shared_name'));

      if (spell is! ContentFound || feat is! ContentFound) {
        throw StateError('a same-id pair was not found under both kinds');
      }
      if (spell.entry.key.kind != ContentKind.spell ||
          feat.entry.key.kind != ContentKind.feat) {
        throw StateError('a lookup answered the wrong kind');
      }
    }),
  ];

  final failing = createFailing;
  if (failing != null) {
    checks.addAll(_failingBackendChecks(failing));
  }
  return checks;
}

/// The backend-failure clauses (FR-017, FR-018): the failure is delivered
/// through the returned future as the port's typed exception, never a
/// synchronous throw, never a not-found or empty answer.
List<ContentSourceCheck> _failingBackendChecks(
  ContentSource Function(List<ContentEntry> entries, Exception backendFailure)
  createFailing,
) {
  const cause = FormatException('backend failure');

  return [
    _check(
      'a backend lookup failure completes with ContentSourceException',
      () async {
        final source = createFailing(const [], cause);
        final requested = _key(ContentKind.spell, _absentId);

        final Future<ContentLookup> future;
        try {
          future = source.lookup(requested);
        } on Object {
          throw StateError('lookup threw synchronously');
        }

        final thrown = await _thrownOf(future);
        if (thrown is ContentNotFound) {
          throw StateError('an infrastructure failure answered not-found');
        }
        if (thrown is! ContentSourceException) {
          throw StateError(
            'the future failed with ${thrown.runtimeType}, not the typed '
            'failure',
          );
        }
        if (thrown.cause != cause) {
          throw StateError('the cause is ${thrown.cause}');
        }
      },
    ),
    _check(
      'a backend listKind failure completes with ContentSourceException',
      () async {
        final source = createFailing(const [], cause);

        final Future<List<ContentEntry>> future;
        try {
          future = source.listKind(ContentKind.spell);
        } on Object {
          throw StateError('listKind threw synchronously');
        }

        final thrown = await _thrownOf(future);
        if (thrown is List<ContentEntry>) {
          throw StateError('an infrastructure failure answered a list');
        }
        if (thrown is! ContentSourceException) {
          throw StateError(
            'the future failed with ${thrown.runtimeType}, not the typed '
            'failure',
          );
        }
        if (thrown.cause != cause) {
          throw StateError('the cause is ${thrown.cause}');
        }
      },
    ),
    _check(
      'the typed failure carries the query variant for both operations',
      () async {
        final source = createFailing(const [], cause);
        final requested = _key(ContentKind.spell, _absentId);

        final lookupFailure =
            await _thrownOf(source.lookup(requested)) as ContentSourceException;
        if (lookupFailure.query != ContentLookupQuery(requested)) {
          throw StateError(
            'the lookup failure query is ${lookupFailure.query}',
          );
        }

        final listFailure =
            await _thrownOf(source.listKind(ContentKind.spell))
                as ContentSourceException;
        if (listFailure.query !=
            const ContentListKindQuery(ContentKind.spell)) {
          throw StateError('the list failure query is ${listFailure.query}');
        }
      },
    ),
  ];
}

/// The failure [future] completes with, whatever it is.
Future<Object> _thrownOf(Future<Object?> future) async {
  try {
    await future;
  } on Object catch (error) {
    return error;
  }
  throw StateError('the future completed with a value');
}

/// Builds the read-only contract suite
/// (content-source-port.md FR-058): the lookup and listing clauses of
/// FR-008 to FR-014 and FR-016 against [source], with `expectedEntries` as
/// the fixture. No group builds a source; the empty-source,
/// same-id-two-kinds and failing-backend clauses are left out.
List<ContentSourceCheck> contentSourceReadOnlyChecks({
  required ContentSource source,
  required List<ContentEntry> expectedEntries,
}) {
  final byKind = <ContentKind, List<ContentEntry>>{};
  final idsByKind = <ContentKind, Set<String>>{};
  for (final entry in expectedEntries) {
    (byKind[entry.key.kind] ??= []).add(entry);
    idsByKind.putIfAbsent(entry.key.kind, () => {}).add(entry.key.id.value);
  }
  final kinds = byKind.keys.toList();
  final absentKind = ContentKind.values.firstWhere(
    (kind) => !byKind.containsKey(kind),
    orElse: () => ContentKind.species,
  );
  // An id held under exactly one fixture kind: probing it under another kind
  // must not answer.
  final singleKindIds = <String>{
    for (final id in idsByKind.values.expand((ids) => ids))
      if (idsByKind.values.where((ids) => ids.contains(id)).length == 1) id,
  };
  // An id no fixture entry uses, for the absent-key probes.
  final usedIds = idsByKind.values.expand((ids) => ids).toSet();
  var probe = _absentId;
  while (usedIds.contains(probe)) {
    probe = '${probe}x';
  }
  final probeId = probe;

  return [
    _check('every fixture entry is found by its key', () async {
      for (final entry in expectedEntries) {
        final lookup = await source.lookup(entry.key);
        if (lookup is! ContentFound) {
          throw StateError('${entry.key} was not found: $lookup');
        }
        if (lookup.entry != entry && lookup.entry.key != entry.key) {
          throw StateError('${entry.key} answered ${lookup.entry.key}');
        }
      }
    }),
    _check(
      'an absent key is not found, carrying the key and the detail',
      () async {
        final requested = ContentKey(ContentKind.spell, ContentId(probeId));

        final lookup = await source.lookup(requested);

        if (lookup is! ContentNotFound) {
          throw StateError('expected ContentNotFound($requested), got $lookup');
        }
        if (lookup.key != requested) {
          throw StateError('ContentNotFound carries ${lookup.key}');
        }
        final expectedMissing = MissingContent(requested.kind, requested.id);
        if (lookup.missing != expectedMissing) {
          throw StateError('the missing detail is ${lookup.missing}');
        }
      },
    ),
    _check('lookup never answers another kind for a single-kind id', () async {
      for (final id in singleKindIds) {
        final other = ContentKind.values.firstWhere(
          (kind) => !(idsByKind[kind]?.contains(id) ?? false),
          orElse: () => ContentKind.species,
        );
        if (idsByKind[other]?.contains(id) ?? false) continue;
        final requested = ContentKey(other, ContentId(id));
        final lookup = await source.lookup(requested);
        if (lookup is ContentFound) {
          throw StateError('$id answered ${lookup.entry.key} under $other');
        }
      }
    }),
    _check(
      'listKind answers every fixture entry of the kind ordered by id',
      () async {
        for (final kind in kinds) {
          final entries = await source.listKind(kind);
          final expected = [...byKind[kind]!]
            ..sort((a, b) => a.key.id.value.compareTo(b.key.id.value));
          if (entries.length != expected.length ||
              !_pairwiseEqual(entries, expected)) {
            throw StateError(
              '${kind.name} answered '
              '[${entries.map((e) => e.key.id.value).join(', ')}], expected '
              '[${expected.map((e) => e.key.id.value).join(', ')}]',
            );
          }
        }
      },
    ),
    _check('a kind with no fixture entries is empty', () async {
      final entries = await source.listKind(absentKind);
      if (entries.isNotEmpty) {
        throw StateError(
          '${absentKind.name} holds ${entries.length} entries outside the '
          'fixture',
        );
      }
    }),
    _check(
      'the listKind list is unmodifiable and the source unchanged',
      () async {
        for (final kind in kinds) {
          final entries = await source.listKind(kind);
          var mutated = false;
          try {
            entries.clear();
            mutated = true;
          } on UnsupportedError {
            // The contract: mutation is refused.
          }
          if (mutated) {
            throw StateError('the ${kind.name} list accepted clear()');
          }
          final again = await source.listKind(kind);
          if (again.length != entries.length) {
            throw StateError('the source changed after the mutation attempt');
          }
        }
      },
    ),
    _check('repeated calls give equal results', () async {
      final kind = kinds.isEmpty ? ContentKind.species : kinds.first;
      final entry = expectedEntries.isEmpty ? null : expectedEntries.first;

      final firstLookup = entry == null
          ? await source.lookup(
              ContentKey(ContentKind.spell, ContentId(probeId)),
            )
          : await source.lookup(entry.key);
      final secondLookup = entry == null
          ? await source.lookup(
              ContentKey(ContentKind.spell, ContentId(probeId)),
            )
          : await source.lookup(entry.key);
      final firstList = await source.listKind(kind);
      final secondList = await source.listKind(kind);

      if (firstLookup != secondLookup) {
        throw StateError('two lookups of one key differ');
      }
      if (firstList.length != secondList.length ||
          !_pairwiseEqual(firstList, secondList)) {
        throw StateError('two listKind calls differ');
      }
    }),
    _check('a found entry answers with its own key', () async {
      for (final entry in expectedEntries) {
        final lookup = await source.lookup(entry.key);
        if (lookup is ContentFound && lookup.entry.key != entry.key) {
          throw StateError('${entry.key} answered ${lookup.entry.key}');
        }
      }
    }),
  ];
}

/// Whether [first] and [second] hold pairwise equal or identical entries.
bool _pairwiseEqual(List<ContentEntry> first, List<ContentEntry> second) {
  for (var i = 0; i < first.length; i++) {
    if (!(identical(first[i], second[i]) || first[i] == second[i])) {
      return false;
    }
  }
  return true;
}

/// Asserts the [entries] carry exactly the ids of [expectedIds] in order.
void _expectOrdered(List<ContentEntry> entries, List<String> expectedIds) {
  final ids = [for (final entry in entries) entry.key.id.value];
  if (ids.length != expectedIds.length) {
    throw StateError(
      'answered [${ids.join(', ')}], expected '
      '[${expectedIds.join(', ')}]',
    );
  }
  for (var i = 0; i < ids.length; i++) {
    if (ids[i] != expectedIds[i]) {
      throw StateError(
        'answered [${ids.join(', ')}], expected '
        '[${expectedIds.join(', ')}]',
      );
    }
  }
}

/// Runs [checks] as one test group of [name], one test per check: the
/// group a registered implementation's suite replays.
void runContentSourceChecks(String name, List<ContentSourceCheck> checks) {
  /// Requirement: doc/specs/content-source-port.md FR-027 - the registered
  ///   implementation replays the whole suite: every check completes
  ///   without a violation.
  /// Path: happy
  group('ContentSource contract: $name', () {
    /// Requirement: per case - one contract clause per check; a failure
    ///   surfaces as ContentSourceContractViolation naming the check.
    /// Path: per case
    for (final check in checks) {
      test(check.name, () => check.run());
    }
  });
}
