import 'package:test/test.dart';

import '../support/source_set.dart';
import '../support/violation.dart';
import 'ability_conventions.dart';

const String _abilityExports = '''
export 'src/shared_kernel/ability/ability.dart' show Ability;
export 'src/shared_kernel/ability/ability_score.dart'
    show AbilityModifier, AbilityScore;
export 'src/shared_kernel/ability/ability_score_result.dart'
    show
        AbilityScoreRejection,
        AbilityScoreResult,
        InvalidAbilityScore,
        ValidAbilityScore;
export 'src/shared_kernel/ability/ability_scores.dart' show AbilityScores;
''';

SourceSet _repo({
  String? core = _abilityExports,
  String? adapters,
  String? testing,
}) => SourceSet({
  'lib/srd5e.dart': ?core,
  'lib/adapters.dart': ?adapters,
  'lib/testing.dart': ?testing,
});

List<String> _details(List<Violation> violations) => [
  for (final v in violations) '${v.path} ${v.detail}',
];

void main() {
  /// Requirement: doc/specs/ability-scores.md FR-026 - check A1 over fixtures:
  ///   exactly the eight ability names, each once, is accepted.
  /// Path: happy
  test('A1 accepts exactly the eight ability names, each once', () {
    expect(checkAbilityEntryPoints(_repo()), isEmpty);
    expect(expectedAbilityExports, hasLength(8));
  });

  /// Requirement: doc/specs/ability-scores.md FR-026 - a missing ability name
  ///   is reported.
  /// Path: unhappy (missing content)
  test('A1 reports an ability name that is not exported', () {
    final core = _abilityExports.replaceAll(
      "export 'src/shared_kernel/ability/ability_scores.dart' show AbilityScores;\n",
      '',
    );

    expect(_details(checkAbilityEntryPoints(_repo(core: core))), [
      'lib/srd5e.dart AbilityScores is exported 0 times; it must be exported once.',
    ]);
  });

  /// Requirement: doc/specs/ability-scores.md FR-026 - AbilityScoreRejection
  ///   exported twice (a second definition re-exported) is reported.
  /// Path: unhappy (name collision)
  test('A1 reports AbilityScoreRejection exported twice', () {
    const extra =
        "export 'src/shared_kernel/ability/ability_score_extra.dart' "
        'show AbilityScoreRejection;\n';
    const core = '$_abilityExports$extra';

    expect(_details(checkAbilityEntryPoints(_repo(core: core))), [
      'lib/srd5e.dart AbilityScoreRejection is exported 2 times; it must be exported once.',
    ]);
  });

  /// Requirement: doc/specs/ability-scores.md FR-026 - a generic BelowMinimum
  ///   or AboveMaximum exported from any entry point is reported.
  /// Path: unhappy (name collision)
  test('A1 reports a generic BelowMinimum exported from an entry point', () {
    const extra =
        "export 'src/shared_kernel/ability/ability_score_result.dart' "
        'show BelowMinimum;\n';
    const core = '$_abilityExports$extra';
    const testing = "export 'src/testing/other.dart' show AboveMaximum;\n";

    final details = _details(
      checkAbilityEntryPoints(_repo(core: core, testing: testing)),
    );

    expect(details, [
      'lib/srd5e.dart BelowMinimum is exported from an ability file but is not on the list.',
      'lib/srd5e.dart The generic name BelowMinimum is exported from '
          'src/shared_kernel/ability/ability_score_result.dart.',
      'lib/testing.dart The generic name AboveMaximum is exported from '
          'src/testing/other.dart.',
    ]);
  });

  /// Requirement: doc/specs/ability-scores.md FR-026 - an export with no show
  ///   clause cannot be checked and is reported.
  /// Path: unhappy (invalid input)
  test('A1 reports an ability export with no show clause', () {
    const core =
        "export 'src/shared_kernel/ability/ability_score_result.dart';\n";

    final details = _details(checkAbilityEntryPoints(_repo(core: core)));

    expect(
      details,
      contains(
        'lib/srd5e.dart The export of '
        'src/shared_kernel/ability/ability_score_result.dart has no `show` '
        'clause.',
      ),
    );
  });

  /// Requirement: doc/specs/ability-scores.md FR-026 - another entry point
  ///   re-exporting an ability file is reported.
  /// Path: unhappy (rule conflict)
  test('A1 reports an ability export from lib/adapters.dart', () {
    const adapters =
        "export 'src/shared_kernel/ability/ability.dart' show Ability;\n";

    expect(_details(checkAbilityEntryPoints(_repo(adapters: adapters))), [
      'lib/adapters.dart lib/adapters.dart exports '
          'src/shared_kernel/ability/ability.dart; ability types belong in '
          'srd5e.dart.',
    ]);
  });

  /// Requirement: doc/specs/ability-scores.md FR-026 - exports of other
  ///   kernel files, and comments, are not counted as ability exports.
  /// Path: unhappy (boundary)
  test('A1 ignores non-ability exports and commented-out exports', () {
    const extra =
        "export 'src/shared_kernel/modifier.dart' show Modifier;\n"
        "// export 'src/shared_kernel/ability/ability.dart' show Ability;\n";
    const core = '$_abilityExports$extra';

    expect(checkAbilityEntryPoints(_repo(core: core)), isEmpty);
  });

  /// Requirement: doc/specs/architecture-guardrails.md FR-012 - a missing
  ///   lib/srd5e.dart is itself a violation, so the check cannot pass
  ///   vacuously.
  /// Path: unhappy (empty and minimal)
  test('A1 reports a missing lib/srd5e.dart', () {
    expect(_details(checkAbilityEntryPoints(_repo(core: null))), [
      'lib/srd5e.dart The entry point does not exist.',
    ]);
  });
}
