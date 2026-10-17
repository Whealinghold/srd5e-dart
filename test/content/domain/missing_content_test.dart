import 'package:srd5e/src/content/domain/content_id.dart';
import 'package:srd5e/src/content/domain/content_key.dart';
import 'package:srd5e/src/content/domain/content_kind.dart';
import 'package:srd5e/src/content/domain/missing_content.dart';
import 'package:test/test.dart';

import '../../support/operator_equals.dart';

void main() {
  /// Requirement: doc/specs/content-schema-and-decoder.md FR-147 - the key
  ///   getter is equal to ContentKey(kind, id).
  /// Path: happy
  test('the key getter equals ContentKey(kind, id)', () {
    final missing = MissingContent(ContentKind.spell, ContentId('a'));

    expect(missing.key, ContentKey(ContentKind.spell, ContentId('a')));
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-147 - it
  ///   compares by kind and id.
  /// Path: happy
  test('equal parts are equal with equal hash codes', () {
    final missing = MissingContent(ContentKind.spell, ContentId('a'));
    final same = MissingContent(ContentKind.spell, ContentId('a'));

    expect(missing, same);
    expect(missing.hashCode, same.hashCode);
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-147 - it
  ///   compares by kind and id, so a differing part is a different detail.
  /// Path: unhappy (rule interaction)
  test('a differing kind or id is not equal', () {
    final missing = MissingContent(ContentKind.spell, ContentId('a'));
    final otherKind = MissingContent(ContentKind.feat, ContentId('a'));
    final otherId = MissingContent(ContentKind.spell, ContentId('b'));

    expect(operatorEquals(missing, otherKind), isFalse);
    expect(operatorEquals(otherKind, missing), isFalse);
    expect(operatorEquals(missing, otherId), isFalse);
    expect(operatorEquals(missing, 'spell/a'), isFalse);
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-147 - toString
  ///   is the debugging form and carries no display text.
  /// Path: happy
  test('missing content prints its key', () {
    expect(
      MissingContent(ContentKind.spell, ContentId('a')).toString(),
      'MissingContent(spell/a)',
    );
  });
}
