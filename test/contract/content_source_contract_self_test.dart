import 'package:srd5e/src/content/application/ports/content_source.dart';
import 'package:srd5e/src/content/domain/content_entry.dart';
import 'package:srd5e/src/content/domain/content_id.dart';
import 'package:srd5e/src/content/domain/content_key.dart';
import 'package:srd5e/src/content/domain/content_kind.dart';
import 'package:srd5e/src/content/domain/content_lookup.dart';
import 'package:srd5e/src/content/domain/content_query.dart';
import 'package:srd5e/src/content/domain/content_set.dart';
import 'package:test/test.dart';

import 'content_source_contract.dart';

/// The self-tests of the `ContentSource` contract suite
/// (content-source-port.md FR-042, FR-058): deliberately broken adapters
/// make the matching check throw a `ContentSourceContractViolation` naming
/// it, and a conforming source passes both suites.
void main() {
  /// Extracts the violation a failing check threw, or fails the self-test.
  Future<ContentSourceContractViolation> violationOf(
    Future<void> Function() run,
  ) async {
    try {
      await run();
    } on ContentSourceContractViolation catch (violation) {
      return violation;
    }
    throw StateError('the check passed where a violation was required');
  }

  /// Requirement: doc/specs/content-source-port.md FR-042 - an adapter that
  ///   leaks the raw backend exception fails the backend-failure checks
  ///   with a violation naming the check.
  /// Path: unhappy (collaborator failure)
  test('a raw leak is a violation', () async {
    final checks = contentSourceContractChecks(
      create: _ConformingSource.new,
      createFailing: (entries, failure) =>
          _RawLeakSource(_ConformingSource(entries), failure),
    );

    for (final check in checks.where((c) => c.name.contains('backend'))) {
      final violation = await violationOf(check.run);
      expect(violation.checkName, check.name);
    }
  });

  /// Requirement: doc/specs/content-source-port.md FR-042 - an adapter that
  ///   answers ContentNotFound on a backend failure fails the lookup
  ///   backend-failure check with a violation.
  /// Path: unhappy (collaborator failure)
  test('a not-found on backend failure is a violation', () async {
    final checks = contentSourceContractChecks(
      create: _ConformingSource.new,
      createFailing: (entries, failure) =>
          _NotFoundOnFailureSource(_ConformingSource(entries)),
    );

    final lookupCheck = checks.singleWhere(
      (c) => c.name.contains('backend') && c.name.contains('lookup'),
    );
    final violation = await violationOf(lookupCheck.run);
    expect(violation.checkName, lookupCheck.name);
  });

  /// Requirement: doc/specs/content-source-port.md FR-042 - an adapter that
  ///   answers an empty list on a backend failure fails the listKind
  ///   backend-failure check with a violation.
  /// Path: unhappy (collaborator failure)
  test('an empty list on backend failure is a violation', () async {
    final checks = contentSourceContractChecks(
      create: _ConformingSource.new,
      createFailing: (entries, failure) =>
          _EmptyOnFailureSource(_ConformingSource(entries)),
    );

    final listCheck = checks.singleWhere(
      (c) => c.name.contains('backend') && c.name.contains('listKind'),
    );
    final violation = await violationOf(listCheck.run);
    expect(violation.checkName, listCheck.name);
  });

  /// Requirement: doc/specs/content-source-port.md FR-027, FR-028 - a
  ///   conforming implementation with a working failing-backend factory
  ///   passes every check, so the suite can pass as a whole.
  /// Path: happy
  test('a conforming adapter with a failing factory passes', () async {
    final checks = contentSourceContractChecks(
      create: _ConformingSource.new,
      createFailing: (entries, failure) => _WrappingSource(failure),
    );

    for (final check in checks) {
      await check.run();
    }
  });

  /// Requirement: doc/specs/content-source-port.md FR-058 - the read-only
  ///   suite passes a conforming fixed source.
  /// Path: happy
  test('the read-only suite passes a conforming fixed source', () async {
    final checks = contentSourceReadOnlyChecks(
      source: _ConformingSource(_fixture()),
      expectedEntries: _fixture(),
    );

    for (final check in checks) {
      await check.run();
    }
  });

  /// Requirement: doc/specs/content-source-port.md FR-058 - a read-only
  ///   source answering in the wrong order fails the ordering check.
  /// Path: unhappy (invalid input)
  test('a wrong order is a violation', () async {
    final checks = contentSourceReadOnlyChecks(
      source: _ReversedSource(_fixture()),
      expectedEntries: _fixture(),
    );

    final orderingCheck = checks.singleWhere((c) => c.name.contains('ordered'));
    final violation = await violationOf(orderingCheck.run);
    expect(violation.checkName, orderingCheck.name);
  });

  /// Requirement: doc/specs/content-source-port.md FR-058 - a read-only
  ///   source answering an entry of another kind fails the cross-kind
  ///   check.
  /// Path: unhappy (rule interaction)
  test('a cross-kind answer is a violation', () async {
    final checks = contentSourceReadOnlyChecks(
      source: _KindBlindSource(_fixture()),
      expectedEntries: _fixture(),
    );

    final crossKindCheck = checks.singleWhere(
      (c) => c.name.contains('another kind'),
    );
    final violation = await violationOf(crossKindCheck.run);
    expect(violation.checkName, crossKindCheck.name);
  });

  /// Requirement: doc/specs/content-source-port.md FR-058 - a read-only
  ///   source handing out a modifiable list fails the immutability check.
  /// Path: unhappy (immutability)
  test('a modifiable list is a violation', () async {
    final checks = contentSourceReadOnlyChecks(
      source: _ModifiableListSource(_fixture()),
      expectedEntries: _fixture(),
    );

    final immutabilityCheck = checks.singleWhere(
      (c) => c.name.contains('unmodifiable'),
    );
    final violation = await violationOf(immutabilityCheck.run);
    expect(violation.checkName, immutabilityCheck.name);
  });

  /// Requirement: doc/specs/content-source-port.md FR-028 - a failed check
  ///   keeps the original failure as its cause, with its stack trace.
  /// Path: unhappy (invalid input)
  test('a violation carries the underlying failure', () async {
    final checks = contentSourceReadOnlyChecks(
      source: _ReversedSource(_fixture()),
      expectedEntries: _fixture(),
    );

    final orderingCheck = checks.singleWhere((c) => c.name.contains('ordered'));
    final violation = await violationOf(orderingCheck.run);

    expect(violation.cause, isA<StateError>());
    expect(violation.causeStackTrace, isNotNull);
  });
}

/// The fixture the self-tests run over: synthetic entries, no SRD content.
List<ContentEntry> _fixture() => [
  _entry(ContentKind.feat, 'alert'),
  _entry(ContentKind.feat, 'tough_hide'),
  _entry(ContentKind.spell, 'mage_armor'),
  _entry(ContentKind.spell, 'acid_arrow'),
];

_KeyOnlyEntry _entry(ContentKind kind, String id) =>
    _KeyOnlyEntry(ContentKey(kind, ContentId(id)));

/// A minimal synthetic entry.
final class _KeyOnlyEntry implements ContentEntry {
  const _KeyOnlyEntry(this.key);

  @override
  final ContentKey key;

  @override
  bool operator ==(Object other) => other is _KeyOnlyEntry && other.key == key;

  @override
  int get hashCode => key.hashCode;

  @override
  String toString() => 'KeyOnly(${key.kind.name}/${key.id.value})';
}

/// A conforming in-memory source over a `ContentSet`: ordered, immutable,
/// the baseline every broken double is measured against.
final class _ConformingSource implements ContentSource {
  _ConformingSource(Iterable<ContentEntry> entries)
    : _set = ContentSet(entries);

  final ContentSet _set;

  @override
  Future<ContentLookup> lookup(ContentKey key) async {
    for (final entry in _set.entries) {
      if (entry.key == key) return ContentFound(entry);
    }
    return ContentNotFound(key);
  }

  @override
  Future<List<ContentEntry>> listKind(ContentKind kind) async {
    final entries = [
      for (final entry in _set.entries)
        if (entry.key.kind == kind) entry,
    ];
    return List.unmodifiable(entries);
  }
}

/// A source that leaks the raw backend exception instead of wrapping it.
final class _RawLeakSource implements ContentSource {
  _RawLeakSource(this._backend, this._failure);

  final ContentSource _backend;
  final Exception _failure;

  @override
  Future<ContentLookup> lookup(ContentKey key) async {
    await _backend.lookup(key);
    throw _failure;
  }

  @override
  Future<List<ContentEntry>> listKind(ContentKind kind) async {
    await _backend.listKind(kind);
    throw _failure;
  }
}

/// A source that answers ContentNotFound when its backend fails.
final class _NotFoundOnFailureSource implements ContentSource {
  _NotFoundOnFailureSource(this._backend);

  final ContentSource _backend;

  @override
  Future<ContentLookup> lookup(ContentKey key) async => ContentNotFound(key);

  @override
  Future<List<ContentEntry>> listKind(ContentKind kind) =>
      _backend.listKind(kind);
}

/// A source that answers an empty list when its backend fails.
final class _EmptyOnFailureSource implements ContentSource {
  _EmptyOnFailureSource(this._backend);

  final ContentSource _backend;

  @override
  Future<ContentLookup> lookup(ContentKey key) => _backend.lookup(key);

  @override
  Future<List<ContentEntry>> listKind(ContentKind kind) async => const [];
}

/// A source whose failing backend is wrapped like a real adapter would
/// wrap it: the backend [Exception] becomes the typed failure with the
/// original as its cause, through the returned future.
final class _WrappingSource implements ContentSource {
  _WrappingSource(this._failure);

  final Exception _failure;

  @override
  Future<ContentLookup> lookup(ContentKey key) async {
    try {
      throw _failure;
    } on Exception catch (error, stackTrace) {
      throw ContentSourceException(
        ContentLookupQuery(key),
        cause: error,
        causeStackTrace: stackTrace,
      );
    }
  }

  @override
  Future<List<ContentEntry>> listKind(ContentKind kind) async {
    try {
      throw _failure;
    } on Exception catch (error, stackTrace) {
      throw ContentSourceException(
        ContentListKindQuery(kind),
        cause: error,
        causeStackTrace: stackTrace,
      );
    }
  }
}

/// A read-only source that answers listKind in reverse order.
final class _ReversedSource implements ContentSource {
  _ReversedSource(this._entries);

  final List<ContentEntry> _entries;

  @override
  Future<ContentLookup> lookup(ContentKey key) async {
    for (final entry in _entries) {
      if (entry.key == key) return ContentFound(entry);
    }
    return ContentNotFound(key);
  }

  @override
  Future<List<ContentEntry>> listKind(ContentKind kind) async {
    final entries = [
      for (final entry in _entries.reversed)
        if (entry.key.kind == kind) entry,
    ];
    return List.unmodifiable(entries);
  }
}

/// A read-only source that answers any id under any kind: a cross-kind
/// leak.
final class _KindBlindSource implements ContentSource {
  _KindBlindSource(this._entries);

  final List<ContentEntry> _entries;

  @override
  Future<ContentLookup> lookup(ContentKey key) async {
    for (final entry in _entries) {
      if (entry.key.id.value == key.id.value) return ContentFound(entry);
    }
    return ContentNotFound(key);
  }

  @override
  Future<List<ContentEntry>> listKind(ContentKind kind) async {
    final entries = [
      for (final entry in _entries)
        if (entry.key.kind == kind) entry,
    ];
    return List.unmodifiable(entries);
  }
}

/// A read-only source that hands out a growable copy of its lists.
final class _ModifiableListSource implements ContentSource {
  _ModifiableListSource(this._entries);

  final List<ContentEntry> _entries;

  @override
  Future<ContentLookup> lookup(ContentKey key) async {
    for (final entry in _entries) {
      if (entry.key == key) return ContentFound(entry);
    }
    return ContentNotFound(key);
  }

  @override
  Future<List<ContentEntry>> listKind(ContentKind kind) async => [
    for (final entry in _entries)
      if (entry.key.kind == kind) entry,
  ];
}
