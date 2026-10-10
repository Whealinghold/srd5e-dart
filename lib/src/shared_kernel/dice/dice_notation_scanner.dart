/// The digit and sign groups of a die expression written as text, before any
/// number is read from them.
///
/// The scanner only checks the shape of the text. Whether the numbers are
/// within the limits of a `DiceExpression` is judged afterwards.
class DiceNotationTokens {
  /// Creates a record of the scanned groups.
  const DiceNotationTokens({
    required this.countDigits,
    required this.sidesDigits,
    required this.isNegative,
    required this.modifierDigits,
  });

  /// The ASCII digits of the count, or an empty string when the count was
  /// omitted (`d20`).
  final String countDigits;

  /// The ASCII digits of the sides; never empty.
  final String sidesDigits;

  /// Whether the modifier sign is a minus (ASCII hyphen or U+2212).
  final bool isNegative;

  /// The ASCII digits of the modifier, or an empty string when there is no
  /// modifier.
  final String modifierDigits;
}

const int _zero = 0x30;
const int _nine = 0x39;
const int _space = 0x20;
const int _plus = 0x2B;
const int _hyphen = 0x2D;
const int _minusSign = 0x2212;
const int _lowerD = 0x64;
const int _upperD = 0x44;

bool _isDigit(int unit) => unit >= _zero && unit <= _nine;

bool _isSign(int unit) =>
    unit == _plus || unit == _hyphen || unit == _minusSign;

/// Splits [text] into the groups of `<count>d<sides>[<sign><modifier>]`, or
/// returns `null` when [text] does not have that shape.
///
/// The accepted shape is an optional run of ASCII digits, `d` or `D`, a run of
/// ASCII digits, and an optional modifier: `+`, `-` or U+2212, then digits,
/// written with no spaces or with exactly one space on each side of the sign.
/// Nothing else is accepted, including surrounding whitespace, other digits
/// and other dashes. Scanning never throws, whatever the text.
DiceNotationTokens? scanDiceNotation(String text) {
  final units = text.codeUnits;
  var index = 0;

  int digitsFrom(int start) {
    var end = start;
    while (end < units.length && _isDigit(units[end])) {
      end++;
    }
    return end;
  }

  final countEnd = digitsFrom(index);
  final countDigits = text.substring(index, countEnd);
  index = countEnd;

  if (index >= units.length ||
      (units[index] != _lowerD && units[index] != _upperD)) {
    return null;
  }
  index++;

  final sidesEnd = digitsFrom(index);
  if (sidesEnd == index) return null;
  final sidesDigits = text.substring(index, sidesEnd);
  index = sidesEnd;

  if (index == units.length) {
    return DiceNotationTokens(
      countDigits: countDigits,
      sidesDigits: sidesDigits,
      isNegative: false,
      modifierDigits: '',
    );
  }

  final spaced = units[index] == _space;
  if (spaced) index++;
  if (index >= units.length || !_isSign(units[index])) return null;
  final sign = units[index];
  index++;
  if (spaced) {
    if (index >= units.length || units[index] != _space) return null;
    index++;
  }

  final modifierEnd = digitsFrom(index);
  if (modifierEnd == index || modifierEnd != units.length) return null;

  return DiceNotationTokens(
    countDigits: countDigits,
    sidesDigits: sidesDigits,
    isNegative: sign != _plus,
    modifierDigits: text.substring(index, modifierEnd),
  );
}
