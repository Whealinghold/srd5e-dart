import 'dart:async' show runZoned, ZoneSpecification;

import 'package:srd5e/adapters.dart';
import 'package:srd5e/src/content/domain/content_entry.dart';
import 'package:srd5e/src/content/domain/content_id.dart';
import 'package:srd5e/src/content/domain/content_key.dart';
import 'package:srd5e/src/content/domain/content_kind.dart';
import 'package:srd5e/srd5e.dart' show ContentNotFound;
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
}

_StubEntry _entry(ContentKind kind, String id) =>
    _StubEntry(ContentKey(kind, ContentId(id)));

/// A zone whose timer creation fails the test (content-source-port.md
/// FR-024).
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
  /// Requirement: doc/specs/content-source-port.md FR-024 - the source
  ///   completes its futures using microtasks only: no Timer is created.
  /// Path: happy
  test('lookup and listKind create no Timer', () async {
    final source = InMemoryContentSource([_entry(ContentKind.spell, 'light')]);
    final key = ContentKey(ContentKind.spell, ContentId('light'));

    await _noTimerZone(() async {
      await source.lookup(key);
      await source.listKind(ContentKind.spell);
    });
  });

  /// Requirement: doc/specs/content-source-port.md FR-021 - the constructor
  ///   rejects duplicate keys through the catalogue, with the name `entries`
  ///   and the duplicate key.
  /// Path: unhappy (invalid input)
  test('a duplicate key throws ArgumentError naming entries', () {
    final duplicate = ContentKey(ContentKind.spell, ContentId('light'));

    expect(
      () => InMemoryContentSource([
        _entry(ContentKind.spell, 'light'),
        _StubEntry(duplicate),
      ]),
      throwsArgumentErrorFor('entries', duplicate),
    );
  });

  /// Requirement: doc/specs/content-source-port.md FR-023 - a single-pass
  ///   iterable works: the input is iterated exactly once.
  /// Path: happy
  test('a generated iterable is iterated exactly once', () {
    var iterations = 0;
    Iterable<ContentEntry> generated() sync* {
      iterations++;
      yield _entry(ContentKind.spell, 'light');
    }

    final source = InMemoryContentSource(generated());

    expect(iterations, 1);
    expect(source.listKind(ContentKind.spell), completion(hasLength(1)));
  });

  /// Requirement: doc/specs/content-source-port.md FR-023 - the input is
  ///   copied at construction: later mutation of the caller's collection
  ///   changes nothing.
  /// Path: unhappy (immutability)
  test('mutating the input afterwards changes nothing', () async {
    final input = [_entry(ContentKind.spell, 'light')];
    final source = InMemoryContentSource(input);
    input.add(_entry(ContentKind.spell, 'mage_armor'));

    expect(await source.listKind(ContentKind.spell), hasLength(1));
    expect(
      await source.lookup(
        ContentKey(ContentKind.spell, ContentId('mage_armor')),
      ),
      isA<ContentNotFound>(),
    );
  });
}
