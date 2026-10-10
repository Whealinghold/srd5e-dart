import 'package:test/test.dart';

import '../support/source_set.dart';
import '../support/violation.dart';
import 'dice_conventions.dart';

String _core({Iterable<String>? names, bool withShow = true}) {
  final shown = (names ?? expectedDiceCoreExports).join(', ');
  final show = withShow ? ' show $shown' : '';
  return '''
/// Library doc.
library;

export 'src/shared_ports/errors/srd5e_exception.dart' show Srd5eException;
export 'src/shared_kernel/dice/dice_expression.dart'$show;
''';
}

const String _adapters = '''
library;

export 'src/shared_ports/adapters/seeded_dice_roller.dart'
    show SeededDiceRoller;
''';

const String _testing = '''
library;

export 'src/testing/callback_dice_roller.dart' show CallbackDiceRoller;
export 'src/testing/fixed_dice_roller.dart' show FixedDiceRoller;
''';

SourceSet _repo({String? core, String? adapters, String? testing}) =>
    SourceSet({
      'lib/srd5e.dart': ?core,
      'lib/adapters.dart': ?adapters,
      'lib/testing.dart': ?testing,
    });

List<String> _details(List<Violation> violations) => [
  for (final v in violations) '${v.path} ${v.detail}',
];

void main() {
  final good = _repo(core: _core(), adapters: _adapters, testing: _testing);

  /// Requirement: doc/specs/dice-and-rolls.md FR-067 - check D4 over fixtures:
  ///   the three entry points export exactly the dice names of the single list.
  /// Path: happy
  test('D4 accepts entry points that export exactly the FR-067 names', () {
    expect(checkDiceEntryPoints(good), isEmpty);
    expect(expectedDiceCoreExports, hasLength(27));
  });

  /// Requirement: doc/specs/dice-and-rolls.md FR-067 - a name missing from
  ///   `lib/srd5e.dart` is reported.
  /// Path: unhappy (missing content)
  test('D4 reports a core name that is not exported', () {
    final names = expectedDiceCoreExports.where((n) => n != 'DieRoll');
    final repo = _repo(
      core: _core(names: names),
      adapters: _adapters,
      testing: _testing,
    );

    expect(_details(checkDiceEntryPoints(repo)), [
      'lib/srd5e.dart DieRoll is not exported but is on the FR-067 list.',
    ]);
  });

  /// Requirement: doc/specs/dice-and-rolls.md FR-067 and FR-085 - an extra name
  ///   from a dice file, such as a generic variant name, is reported.
  /// Path: unhappy (name collision)
  test('D4 reports an exported name that is not on the list', () {
    final repo = _repo(
      core: _core(names: [...expectedDiceCoreExports, 'Rejected']),
      adapters: _adapters,
      testing: _testing,
    );

    expect(_details(checkDiceEntryPoints(repo)), [
      'lib/srd5e.dart Rejected is exported from a dice file but is not on '
          'the FR-067 list.',
    ]);
  });

  /// Requirement: doc/specs/dice-and-rolls.md FR-067 - an export without a
  ///   `show` clause is reported (it would export every name of the file).
  /// Path: unhappy (invalid input)
  test('D4 reports an export with no show clause', () {
    final repo = _repo(
      core: _core(withShow: false),
      adapters: _adapters,
      testing: _testing,
    );

    final details = _details(checkDiceEntryPoints(repo));

    expect(
      details,
      contains(
        'lib/srd5e.dart The export of '
        'src/shared_kernel/dice/dice_expression.dart has no `show` clause.',
      ),
    );
    expect(details, hasLength(1 + expectedDiceCoreExports.length));
  });

  /// Requirement: doc/specs/dice-and-rolls.md FR-067 - `lib/adapters.dart` must
  ///   export SeededDiceRoller and nothing else from the adapters folder.
  /// Path: unhappy (rule conflict)
  test('D4 checks the adapters entry point', () {
    const extra = '''
library;
export 'src/shared_ports/adapters/seeded_dice_roller.dart'
    show SeededDiceRoller, Helper;
''';
    const missing = '''
library;
export 'src/shared_ports/errors/srd5e_exception.dart' show Srd5eException;
''';

    expect(
      _details(
        checkDiceEntryPoints(
          _repo(core: _core(), adapters: extra, testing: _testing),
        ),
      ),
      [
        'lib/adapters.dart Helper is exported from a dice file but is not on '
            'the FR-067 list.',
      ],
    );
    expect(
      _details(
        checkDiceEntryPoints(
          _repo(core: _core(), adapters: missing, testing: _testing),
        ),
      ),
      [
        'lib/adapters.dart SeededDiceRoller is not exported but is on the '
            'FR-067 list.',
      ],
    );
  });

  /// Requirement: doc/specs/dice-and-rolls.md FR-067 - `lib/testing.dart` must
  ///   export both doubles; doubles of other ports are not this check's
  ///   concern.
  /// Path: unhappy (rule conflict)
  test('D4 checks the testing entry point', () {
    const missingOne = '''
library;
export 'src/testing/fixed_dice_roller.dart' show FixedDiceRoller;
export 'src/testing/recording_logger.dart' show RecordingLogger;
''';

    expect(
      _details(
        checkDiceEntryPoints(
          _repo(core: _core(), adapters: _adapters, testing: missingOne),
        ),
      ),
      [
        'lib/testing.dart CallbackDiceRoller is not exported but is on the '
            'FR-067 list.',
      ],
    );
  });

  /// Requirement: doc/specs/dice-and-rolls.md FR-067 - the entry points must
  ///   exist, and a mention in a comment is not an export.
  /// Path: unhappy (empty and minimal)
  test('D4 reports a missing entry point and ignores comments', () {
    final repo = _repo(
      core: _core(),
      adapters:
          '// export \'src/shared_ports/adapters/x.dart\' show Sneaky;\n'
          '$_adapters',
    );

    expect(_details(checkDiceEntryPoints(repo)), [
      'lib/testing.dart The entry point does not exist.',
    ]);
  });
}
