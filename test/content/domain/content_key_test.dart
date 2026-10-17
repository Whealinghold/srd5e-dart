import 'package:srd5e/src/content/domain/content_id.dart';
import 'package:srd5e/src/content/domain/content_key.dart';
import 'package:srd5e/src/content/domain/content_kind.dart';
import 'package:test/test.dart';

import '../../support/operator_equals.dart';

void main() {
  /// Requirement: doc/specs/content-schema-and-decoder.md FR-145 - two keys
  ///   are equal, with equal hash codes, iff both kind and id are equal.
  /// Path: happy
  test('same kind and id are equal with equal hash codes', () {
    final key = ContentKey(ContentKind.spell, ContentId('a'));
    final same = ContentKey(ContentKind.spell, ContentId('a'));

    expect(key, same);
    expect(key.hashCode, same.hashCode);
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-145 - the same
  ///   id under two kinds is two keys.
  /// Path: unhappy (rule interaction)
  test('same id under two kinds is not equal', () {
    final feat = ContentKey(ContentKind.feat, ContentId('a'));
    final spell = ContentKey(ContentKind.spell, ContentId('a'));

    expect(operatorEquals(feat, spell), isFalse);
    expect(operatorEquals(spell, feat), isFalse);
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-145 - two keys
  ///   are equal iff both kind and id are equal.
  /// Path: unhappy (rule interaction)
  test('same kind with two ids is not equal', () {
    final a = ContentKey(ContentKind.spell, ContentId('a'));
    final b = ContentKey(ContentKind.spell, ContentId('b'));

    expect(operatorEquals(a, b), isFalse);
    expect(operatorEquals(b, a), isFalse);
    expect(operatorEquals(a, 'spell/a'), isFalse);
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-143 - a
  ///   ContentId compares and hashes by its string.
  /// Path: happy
  test('ids from equal strings are equal with equal hash codes', () {
    expect(ContentId('a'), ContentId('a'));
    expect(ContentId('a').hashCode, ContentId('a').hashCode);
    expect(operatorEquals(ContentId('a'), ContentId('b')), isFalse);
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-145 - toString
  ///   is the kind/id debugging form.
  /// Path: happy
  test('a key prints kind/id', () {
    expect(ContentKey(ContentKind.spell, ContentId('a')).toString(), 'spell/a');
  });
}
