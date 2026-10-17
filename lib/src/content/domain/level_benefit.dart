import 'package:meta/meta.dart';

import 'named_text.dart';
import 'typed_ids.dart';

/// One level-gated row of a species lineage option: the level it applies at,
/// the printed text of that level's cell and the spell it grants (FR-061).
///
/// `level` is one of [lineageLevels] — 1, 3 and 5, the levels of the "Elven
/// Lineages" and "Fiendish Legacies" tables (SRD 5.2.1, pp. 85-86); `text`
/// must contain at least one non-whitespace character (FR-028); `spellId` is
/// required, so the "a benefit with no spellId" case of FR-061 is
/// unrepresentable here (the decoder reports it before construction).
@immutable
final class LevelBenefit {
  /// Creates a level benefit.
  ///
  /// Throws an [ArgumentError] carrying the name `level` or `text` and the
  /// offending value when [level] is not one of [lineageLevels] or [text] is
  /// blank.
  LevelBenefit(int level, String text, this.spellId)
    : level = _validatedLevel(level),
      text = _validatedText(text);

  /// The levels a lineage benefit may sit at, in printed order (FR-061).
  static const List<int> lineageLevels = <int>[1, 3, 5];

  /// The level the benefit applies at, one of [lineageLevels].
  final int level;

  /// The printed cell text, verbatim.
  final String text;

  /// The spell the level grants, held beside the text (FR-021).
  final SpellId spellId;

  /// Whether [level] is one of [lineageLevels] (FR-061). The predicate the
  /// decoder reuses instead of repeating the levels (FR-069).
  static bool isValidLevel(int level) => lineageLevels.contains(level);

  static int _validatedLevel(int level) {
    if (!isValidLevel(level)) {
      throw ArgumentError.value(level, 'level', 'must be one of 1, 3 and 5');
    }
    return level;
  }

  static String _validatedText(String text) {
    if (!NamedText.isValidText(text)) {
      throw ArgumentError.value(
        text,
        'text',
        'must contain at least one non-whitespace character',
      );
    }
    return text;
  }

  @override
  bool operator ==(Object other) =>
      other is LevelBenefit &&
      other.level == level &&
      other.text == text &&
      other.spellId == spellId;

  @override
  int get hashCode => Object.hash(LevelBenefit, level, text, spellId);

  @override
  String toString() => 'LevelBenefit($level, $spellId)';
}
