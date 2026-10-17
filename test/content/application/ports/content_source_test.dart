import 'dart:io' show File;

import 'package:srd5e/src/content/application/ports/content_source.dart';
import 'package:srd5e/src/content/domain/content_entry.dart';
import 'package:srd5e/src/content/domain/content_id.dart';
import 'package:srd5e/src/content/domain/content_key.dart';
import 'package:srd5e/src/content/domain/content_kind.dart';
import 'package:srd5e/src/content/domain/content_lookup.dart';
import 'package:test/test.dart';

/// A minimal conforming implementation, to pin the port's shape by
/// assignment (the compiler rejects any other shape).
final class _ConformingSource implements ContentSource {
  @override
  Future<ContentLookup> lookup(ContentKey key) async => ContentNotFound(key);

  @override
  Future<List<ContentEntry>> listKind(ContentKind kind) async => const [];
}

void main() {
  /// Requirement: doc/specs/content-source-port.md FR-007 - lookup returns
  ///   Future<ContentLookup>, by compile-time assignment; a FutureOr would
  ///   not assign to Future<ContentLookup> here.
  /// Path: happy
  test('lookup returns Future<ContentLookup>', () {
    final ContentSource source = _ConformingSource();
    final Future<ContentLookup> Function(ContentKey) lookup = source.lookup;
    final key = ContentKey(ContentKind.spell, ContentId('light'));

    expect(lookup(key), isA<Future<ContentLookup>>());
  });

  /// Requirement: doc/specs/content-source-port.md FR-007 - listKind
  ///   returns Future<List<ContentEntry>>, by compile-time assignment.
  /// Path: happy
  test('listKind returns Future<List<ContentEntry>>', () {
    final ContentSource source = _ConformingSource();
    final Future<List<ContentEntry>> Function(ContentKind) listKind =
        source.listKind;

    expect(listKind(ContentKind.spell), isA<Future<List<ContentEntry>>>());
  });

  /// Requirement: doc/specs/content-source-port.md FR-007 - the port uses
  ///   Future, never FutureOr: no FutureOr appears in the port declaration.
  /// Path: unhappy (invalid design)
  test('the port declares no FutureOr', () {
    final port = File(
      'lib/src/content/application/ports/content_source.dart',
    ).readAsStringSync();

    expect(port.contains('FutureOr'), isFalse);
  });
}
