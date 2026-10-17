import 'package:srd5e/src/content/domain/hit_point_die.dart';
import 'package:test/test.dart';

/// Exhaustive over the enum with no default branch (FR-132).
String _describe(HitPointDie die) => switch (die) {
  HitPointDie.d6 => 'd6',
  HitPointDie.d8 => 'd8',
  HitPointDie.d10 => 'd10',
  HitPointDie.d12 => 'd12',
};

/// One die with the number of faces its Core Traits row gives it.
typedef _FacesCase = ({
  String label,
  String requirement,
  String path,
  HitPointDie die,
  int faces,
});

final List<_FacesCase> _faces = [
  for (var i = 0; i < HitPointDie.values.length; i++)
    (
      label: HitPointDie.values[i].jsonValue,
      requirement:
          'doc/specs/content-schema-and-decoder.md FR-132 - the '
          'static fact faces: ${HitPointDie.values[i].jsonValue} has '
          '${[6, 8, 10, 12][i]} faces',
      path: 'happy',
      die: HitPointDie.values[i],
      faces: [6, 8, 10, 12][i],
    ),
];

/// One fromJson input with the expected member, or null for a non-member.
typedef _JsonCase = ({
  String label,
  String requirement,
  String path,
  String input,
  HitPointDie? expected,
});

final List<_JsonCase> _jsonCases = [
  (
    label: 'D8',
    requirement:
        'doc/specs/content-schema-and-decoder.md FR-132 - the JSON '
        'value is the class-table spelling, case sensitive',
    path: 'happy',
    input: 'D8',
    expected: HitPointDie.d8,
  ),
  (
    label: 'd8',
    requirement:
        'doc/specs/content-schema-and-decoder.md FR-132 - d8 is '
        'invalidValue (case sensitive), so fromJson gives null',
    path: 'unhappy (invalid input)',
    input: 'd8',
    expected: null,
  ),
  (
    label: 'D4',
    requirement:
        'doc/specs/content-schema-and-decoder.md FR-132 - the set is '
        'closed (d6 to d12), so D4 is a non-member',
    path: 'unhappy (invalid input)',
    input: 'D4',
    expected: null,
  ),
  (
    label: 'D20',
    requirement:
        'doc/specs/content-schema-and-decoder.md FR-132 - the type '
        'is separate from the kernel Die and cannot name a d20',
    path: 'unhappy (invalid input)',
    input: 'D20',
    expected: null,
  ),
];

void main() {
  /// Requirement: doc/specs/content-schema-and-decoder.md FR-132 - exactly
  ///   four members in ascending order, JSON the class-table spelling
  ///   (SRD 5.2.1, "Hit Point Die" rows, pp. 28-77).
  /// Path: happy
  test('declares exactly four members in ascending order', () {
    expect(HitPointDie.values.map((die) => die.jsonValue), [
      'D6',
      'D8',
      'D10',
      'D12',
    ]);
  });

  /// Requirement: per case
  /// Path: per case
  for (final c in _faces) {
    test('${c.label} has ${c.faces} faces [${c.path}]', () {
      expect(c.die.faces, c.faces);
    });
  }

  /// Requirement: per case
  /// Path: per case
  for (final c in _jsonCases) {
    test('fromJson ${c.label} [${c.path}]', () {
      expect(HitPointDie.fromJson(c.input), c.expected);
    });
  }

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-132 - a switch
  ///   over HitPointDie is exhaustive without a default.
  /// Path: happy
  test('a switch over every member selects its case', () {
    expect(
      [for (final die in HitPointDie.values) _describe(die)],
      ['d6', 'd8', 'd10', 'd12'],
    );
  });
}
