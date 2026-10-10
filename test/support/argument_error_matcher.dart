import 'package:test/test.dart';

/// Matches a thrown [ArgumentError] by its argument [name] and [invalidValue].
///
/// Tests assert the type, the name and the offending value, never the message
/// (`doc/specs/dice-and-rolls.md` FR-077).
Matcher throwsArgumentErrorFor(String name, Object? invalidValue) => throwsA(
  isA<ArgumentError>()
      .having((e) => e.name, 'name', name)
      .having((e) => e.invalidValue, 'invalidValue', invalidValue),
);
