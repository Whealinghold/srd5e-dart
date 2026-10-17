import 'package:srd5e/src/content/domain/condition_kind.dart';
import 'package:test/test.dart';

/// Exhaustive over the enum with no default branch (FR-110).
String _describe(ConditionKind kind) => switch (kind) {
  ConditionKind.blinded => 'blinded',
  ConditionKind.charmed => 'charmed',
  ConditionKind.deafened => 'deafened',
  ConditionKind.exhaustion => 'exhaustion',
  ConditionKind.frightened => 'frightened',
  ConditionKind.grappled => 'grappled',
  ConditionKind.incapacitated => 'incapacitated',
  ConditionKind.invisible => 'invisible',
  ConditionKind.paralyzed => 'paralyzed',
  ConditionKind.petrified => 'petrified',
  ConditionKind.poisoned => 'poisoned',
  ConditionKind.prone => 'prone',
  ConditionKind.restrained => 'restrained',
  ConditionKind.stunned => 'stunned',
  ConditionKind.unconscious => 'unconscious',
};

/// One pinned index of the Glossary order, which the conditions rules order
/// by (FR-110).
typedef _IndexCase = ({
  String label,
  String requirement,
  String path,
  ConditionKind kind,
  int index,
});

final List<_IndexCase> _indexes = [
  for (var i = 0; i < ConditionKind.values.length; i++)
    (
      label: ConditionKind.values[i].name,
      requirement:
          'doc/specs/content-schema-and-decoder.md FR-110 - the '
          'declaration order is load-bearing (conditions.md orders by it), so '
          '${ConditionKind.values[i].name} keeps index $i',
      path: 'happy',
      kind: ConditionKind.values[i],
      index: i,
    ),
];

void main() {
  /// Requirement: doc/specs/content-schema-and-decoder.md FR-110 - exactly
  ///   these 15 members in Glossary order, JSON the printed name (SRD 5.2.1,
  ///   "Condition", p. 179).
  /// Path: happy
  test('declares exactly 15 members in Glossary order', () {
    expect(ConditionKind.values.map((kind) => kind.jsonValue), [
      'Blinded',
      'Charmed',
      'Deafened',
      'Exhaustion',
      'Frightened',
      'Grappled',
      'Incapacitated',
      'Invisible',
      'Paralyzed',
      'Petrified',
      'Poisoned',
      'Prone',
      'Restrained',
      'Stunned',
      'Unconscious',
    ]);
  });

  /// Requirement: per case
  /// Path: per case
  for (final c in _indexes) {
    test('${c.label} keeps index ${c.index} [${c.path}]', () {
      expect(c.kind.index, c.index);
    });
  }

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-105 - the
  ///   static fromJson accepts exactly the jsonValue spellings.
  /// Path: happy
  test('fromJson round-trips every member', () {
    for (final kind in ConditionKind.values) {
      expect(ConditionKind.fromJson(kind.jsonValue), kind);
    }
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-105 - fromJson
  ///   gives null for a non-member; the decoder turns it into invalidValue
  ///   (FR-025) and never case-folds or trims.
  /// Path: unhappy (invalid input)
  test('fromJson gives null for wrong case and padded spellings', () {
    expect(ConditionKind.fromJson('blinded'), isNull);
    expect(ConditionKind.fromJson(' Prone'), isNull);
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-110 - a switch
  ///   over ConditionKind is exhaustive without a default.
  /// Path: happy
  test('a switch over every member selects its case', () {
    expect(
      [for (final kind in ConditionKind.values) _describe(kind)],
      [
        'blinded',
        'charmed',
        'deafened',
        'exhaustion',
        'frightened',
        'grappled',
        'incapacitated',
        'invisible',
        'paralyzed',
        'petrified',
        'poisoned',
        'prone',
        'restrained',
        'stunned',
        'unconscious',
      ],
    );
  });
}
