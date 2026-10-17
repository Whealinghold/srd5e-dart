import 'dart:io';

import 'package:srd5e/src/content/domain/content_entry.dart';
import 'package:srd5e/src/content/domain/content_id.dart';
import 'package:srd5e/src/content/domain/content_key.dart';
import 'package:srd5e/src/content/domain/content_kind.dart';
import 'package:test/test.dart';

/// A synthetic entry implementing [ContentEntry], as every content entry of
/// a kind spec will.
final class _SyntheticEntry implements ContentEntry {
  const _SyntheticEntry(this.key);

  @override
  final ContentKey key;
}

void main() {
  /// Requirement: doc/specs/content-schema-and-decoder.md FR-146 - a
  ///   synthetic entry implements ContentEntry with one member, its key.
  /// Path: happy
  test('a synthetic entry implements ContentEntry', () {
    final key = ContentKey(ContentKind.species, ContentId('elf'));
    final entry = _SyntheticEntry(key);

    expect(entry.key, key);
    expect(entry.key.kind, ContentKind.species);
    expect(entry.key.id, ContentId('elf'));
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-146 - the
  ///   interface carries @immutable and declares one member only, its key,
  ///   so any implementation is immutable by construction. The source scan
  ///   makes the one-member rule a failing assertion: a member added to the
  ///   interface turns this test red.
  /// Path: happy
  test('ContentEntry declares exactly one member, key, under @immutable', () {
    final source = File(
      'lib/src/content/domain/content_entry.dart',
    ).readAsStringSync();

    expect(source, contains('@immutable'));
    final members = RegExp(
      r'^\s*[\w<>, ?]+\s+get\s+(\w+)\s*;',
      multiLine: true,
    ).allMatches(source).map((match) => match.group(1)!).toList();

    expect(members, ['key']);
  });
}
