import '../content_id.dart';

/// Derives the id of a feature entry from its owner's id and its printed
/// name (FR-052, D4).
///
/// The rule: the [ownerId], one underscore, then the slug of [name] — the
/// name lower-cased, the two apostrophes (U+0027 and U+2019) deleted, each
/// run of other characters one underscore, and the edge underscores
/// trimmed. [level] is appended as `_level_<n>` only when one owner prints
/// two features with the same name (FR-053): the Barbarian's "Improved
/// Brutal Strike" at levels 13 and 17.
///
/// The result MUST satisfy the id rule of schema FR-030; a result longer
/// than [ContentId.maxLength] characters throws an [ArgumentError] carrying
/// the name `value` and the derived id. Note the divergence the settled
/// questions record: content-species-backgrounds-feats.md FR-004 keeps the
/// apostrophe as an underscore (`dragon_s_breath`); this function deletes
/// it, and no bundled species, background or feat id contains one.
String deriveFeatureId(String ownerId, String name, {int? level}) {
  final slug = _slug(name);
  final suffix = level == null ? '' : '_level_$level';
  final id = '${ownerId}_$slug$suffix';
  if (id.length > ContentId.maxLength) {
    throw ArgumentError.value(
      id,
      'value',
      'the derived id is longer than the ${ContentId.maxLength} characters '
          'an id may have (FR-052)',
    );
  }
  return id;
}

String _slug(String name) {
  final buffer = StringBuffer();
  // mutate4dart: ignore boolean_literal // dead seed: a leading run is trimmed by the buffer.isNotEmpty guard, so the initial value cannot change the slug.
  var pendingUnderscore = false;
  for (final rune in name.toLowerCase().runes) {
    final isLowercaseLetter = rune >= 0x61 && rune <= 0x7A;
    final isDigit = rune >= 0x30 && rune <= 0x39;
    if (isLowercaseLetter || isDigit) {
      if (pendingUnderscore && buffer.isNotEmpty) {
        // An interior run becomes one underscore; a leading run is trimmed.
        buffer.write('_');
      }
      pendingUnderscore = false;
      buffer.writeCharCode(rune);
    } else if (rune == 0x27 || rune == 0x2019) {
      // The two apostrophes are deleted, not slugged (FR-052).
    } else {
      pendingUnderscore = true;
    }
  }
  return buffer.toString();
}
