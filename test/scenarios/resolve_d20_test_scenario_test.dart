import 'package:srd5e/srd5e.dart';
import 'package:srd5e/testing.dart';
import 'package:test/test.dart';

/// Whether an attempt rolls: a check attempt rolls only as a [RollAttempt].
bool checkRolls(CheckAttempt attempt) => switch (attempt) {
  RollAttempt() => true,
  AutomaticFailure() => false,
};

/// Whether a saving-throw attempt rolls: it may also be chosen to fail.
bool saveRolls(SaveAttempt attempt) => switch (attempt) {
  RollAttempt() => true,
  ChooseToFail() => false,
  AutomaticFailure() => false,
};

/// One sentence about a resolved D20 Test, from its variant.
String describe(ResolveD20TestResult result) => switch (result) {
  ResolveD20TestRolledCheck(result: final CheckResult check) =>
    '${check.kind.name} total ${check.total} against DC '
        '${check.target.value}: ${check.outcome.name}',
  ResolveD20TestRolledAttack(result: final AttackRollResult attack) =>
    'attack total ${attack.total} against AC ${attack.target.value}: '
        '${attack.hit ? 'hit' : 'miss'}',
  ResolveD20TestForcedFailure(result: final ForcedFailureResult forced) =>
    '${forced.kind.name} failed without a roll: ${forced.reason.name}',
};

void main() {
  /// Requirement: doc/specs/resolve-d20-test-use-case.md FR-042 - the public
  ///   API resolves one check, one save, one attack roll and one chosen
  ///   failure with a fixed roller and recording Observability, covering
  ///   Advantage, importing only package:srd5e/srd5e.dart and
  ///   package:srd5e/testing.dart.
  /// Path: happy
  test('a hero turns: Advantage check, save, attack roll and a chosen '
      'failure', () {
    // Rolls in request order: the Advantage check takes two d20s, the save
    // and the attack one each; the chosen failure takes none.
    final recording = RecordingObservability();
    final roller = FixedDiceRoller(const [15, 6, 9, 17, 11]);
    final resolve = ResolveD20Test(
      roller,
      observability: recording.observability,
    );

    // (1) A Strength check with Advantage against a DC 15.
    final AbilityCheckCommand checkCommand = AbilityCheckCommand(
      Ability.strength,
      target: const DifficultyClass(15),
      attempt: RollAttempt(
        modifiers: RollModifiers(ability: const Modifier(3)),
        circumstances: const [Advantage()],
      ),
    );
    expect(checkRolls(checkCommand.attempt), isTrue);

    final check = resolve(checkCommand);
    final ResolveD20TestRolledCheck(result: checkResult) =
        check as ResolveD20TestRolledCheck;
    expect(checkResult.kind, D20TestKind.abilityCheck);
    expect(checkResult.roll.mode, RollMode.advantage);
    expect(checkResult.roll.dice, const [15, 6]);
    expect(checkResult.roll.natural, 15);
    expect(checkResult.total, 18);
    expect(checkResult.outcome, D20TestOutcome.success);
    expect(describe(check), 'abilityCheck total 18 against DC 15: success');

    // The kept die is rerolled with Heroic Inspiration: the decision is a
    // RerollDie, and keeping the roll is a KeepRoll.
    const RerollDecision reroll = RerollDie(1);
    final D20Roll rerolled = checkResult.roll.applyReroll(reroll, newValue: 14);
    expect(rerolled.dice, const [15, 14]);
    expect(rerolled.natural, 15);
    expect(checkResult.roll.applyReroll(const KeepRoll()), checkResult.roll);

    // (2) A Wisdom saving throw against a medium DC.
    final SavingThrowCommand saveCommand = SavingThrowCommand(
      Ability.wisdom,
      target: DifficultyClass.medium,
      attempt: RollAttempt(
        modifiers: RollModifiers(ability: const Modifier(1)),
      ),
    );
    expect(saveRolls(saveCommand.attempt), isTrue);

    final save = resolve(saveCommand);
    final ResolveD20TestRolledCheck(result: saveResult) =
        save as ResolveD20TestRolledCheck;
    expect(saveResult.kind, D20TestKind.savingThrow);
    expect(saveResult.roll.natural, 9);
    expect(saveResult.total, 10);
    expect(saveResult.outcome, D20TestOutcome.failure);

    // (3) A Strength attack roll against a goblin's Armor Class.
    final AttackRollCommand attackCommand = AttackRollCommand(
      Ability.strength,
      target: const ArmorClass(13),
      attempt: RollAttempt(
        modifiers: RollModifiers(ability: const Modifier(5)),
      ),
    );

    // The turn's commands, each one a D20TestCommand of its kind.
    final List<D20TestCommand> turn = [
      checkCommand,
      saveCommand,
      attackCommand,
    ];
    expect(turn, hasLength(3));

    final attack = resolve(attackCommand);
    final ResolveD20TestRolledAttack(result: attackResult) =
        attack as ResolveD20TestRolledAttack;
    expect(attackResult.roll.natural, 17);
    expect(attackResult.total, 22);
    expect(attackResult.outcome, D20TestOutcome.success);
    expect(attackResult.isCriticalHit, isFalse);
    expect(attackResult.hit, isTrue);

    // (4) The hero chooses to fail the next saving throw, without rolling.
    final chosen = resolve(
      const SavingThrowCommand(
        Ability.dexterity,
        target: DifficultyClass.easy,
        attempt: ChooseToFail(),
      ),
    );
    final ResolveD20TestForcedFailure(result: forcedResult, :target) =
        chosen as ResolveD20TestForcedFailure;
    expect(forcedResult.reason, ForcedFailureReason.chosenToFail);
    expect(forcedResult.kind, D20TestKind.savingThrow);
    expect(target, DifficultyClass.easy);

    // Each call was one span, named by the signals constant, and each
    // failure is a normal outcome, not an error.
    expect(
      recording.tracer.spans.map((span) => span.name),
      everyElement(D20TestSignals.resolveSpan),
    );
    expect(
      recording.tracer.spans.map((span) => span.status),
      everyElement(SpanStatus.unset),
    );

    // The roller saw one request per rolled test: a 2d20 for the Advantage
    // check, a 1d20 each for the save and the attack, nothing for the
    // chosen failure.
    expect(roller.requests.map((request) => request.notation).toList(), const [
      '2d20',
      '1d20',
      '1d20',
    ]);

    // The pure domain service the use case composes, used directly for a
    // rerolled roll.
    const D20TestResolver domainResolver = D20TestResolver();
    final rerolledCheck = domainResolver.resolveCheck(
      D20TestKind.abilityCheck,
      rerolled,
      RollModifiers(ability: const Modifier(3)),
      const DifficultyClass(15),
    );
    expect(rerolledCheck.total, 18);
    expect(
      domainResolver.forcedFailure(
        D20TestKind.savingThrow,
        ForcedFailureReason.chosenToFail,
      ),
      const ForcedFailureResult(
        kind: D20TestKind.savingThrow,
        reason: ForcedFailureReason.chosenToFail,
      ),
    );
  });
}
