import 'package:test/test.dart';

import 'support/real_repository.dart';
import 'support/violation.dart';

/// The lint-style test of `doc/specs/content-schema-and-decoder.md` FR-094:
/// each rule of the decoder exists once — the domain types expose their
/// limits as public constants, predicates and `fromJson` parsers, and the
/// decoder text uses them instead of repeating the literals. A rule
/// changed in its domain constant but left literal in the decoder fails
/// here.
///
/// The scan reads the decoder source through the real-repository snapshot
/// (VM only, like every source scan); the decoder's behaviour itself is
/// pinned by the web-safe tests in `test/content/adapters/`.
void main() {
  const decoderPath = 'lib/src/content/adapters/json_content_set_decoder.dart';

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-094 - the
  ///   decoder uses the domain constants instead of repeating literals;
  ///   each identifier below is a limit the owning type owns, and every
  ///   one of them must be in use.
  /// Path: happy
  test('the decoder uses the domain constants and parsers', () {
    final text = realRepository.files[decoderPath];
    expect(text, isNotNull, reason: '$decoderPath must exist');
    final violations = <Violation>[];
    for (final identifier in const [
      // Species, background and feat shapes.
      'Species.minSpeed',
      'Species.isPlayerCharacterSize',
      'Background.requiredAbilityScores',
      'Background.requiredSkillProficiencies',
      'Feat.minBenefits',
      'LevelBenefit.isValidLevel',
      'LevelBenefit.lineageLevels',
      'SpeciesChoice.minOptions',
      'EquipmentItem.minQuantity',
      'EquipmentOption.minGold',
      // Classes shapes (content-classes.md FR-007).
      'ClassDefinition.minSavingThrowProficiencies',
      'ClassDefinition.maxSavingThrowProficiencies',
      'ClassDefinition.rowCount',
      'AllOf.minAbilities',
      'AnyOf.minAbilities',
      'SkillChoice.minPicks',
      'ClassToolProficiencyChoice.minPicks',
      'ClassToolProficiencyChoice.isValidCategory',
      'WeaponTrainingCategory.fromJson',
      'ArmorTrainingCategory.fromJson',
      'ClassEquipmentItem.minQuantity',
      'ClassEquipmentOption.minGold',
      'ClassColumnKind.fromJson',
      'ProgressionRow.minLevel',
      'ProgressionRow.maxLevel',
      'ProgressionRow.minProficiencyBonus',
      'SlotSpellcastingRow.minSlots',
      'SlotSpellcastingRow.slotCount',
      'PactSpellcastingRow.minSlots',
      'PactSpellcastingRow.isValidSlotLevel',
      'FeatureEntry.minLevel',
      'FeatureEntry.maxLevel',
      'FeatureEntry.isValidLevel',
      'SpellGrant.minLevel',
      'SpellGrant.maxLevel',
      'AlwaysPreparedSpells.minGrants',
      'FeatureOption.minPointCost',
      'FeatureTable.minRows',
      'HitPointDie.fromJson',
      'ColumnCount.minValue',
      'ColumnDice.minCount',
      'ColumnBonus.minValue',
      'Die.minSides',
      'Die.maxSides',
      // Spells shapes (content-spells.md FR-111).
      'SpellLevel.min',
      'SpellLevel.max',
      'SpellSchool.fromJson',
      'CastingTime.minAmount',
      'SpellCastingTimes.minModes',
      'SpellRange.minDistance',
      'DistanceUnit.fromJson',
      'DurationUnit.fromJson',
      'SpellDuration.minAmount',
      'DurationLimit.fromJson',
      'MaterialComponent.minCostGp',
      // `Spell.isValidName` delegates to `NamedText.isValidName`, which the
      // name reader uses, so that rule exists once without a second call.
      // Shared building blocks.
      'ContentId.tryCreate',
      'NamedText.isValidName',
      'NamedText.isValidText',
      'SourceCitation.minPage',
      'RowClassFeature.isValidAnnotation',
    ]) {
      if (!text!.contains(identifier)) {
        violations.add(
          Violation(
            checkId: 'FR-094',
            path: decoderPath,
            line: 1,
            detail:
                'The decoder never uses the domain constant '
                '`$identifier`.',
          ),
        );
      }
    }
    expect(violations, isEmpty);
  }, timeout: const Timeout(Duration(seconds: 10)));

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-094 - the
  ///   spell level rule exists once: the decoder text holds no literal
  ///   spell-level bounds to drift from `SpellLevel.min` and
  ///   `SpellLevel.max`.
  /// Path: happy
  test('the decoder repeats no spell-level literal', () {
    final text = realRepository.files[decoderPath]!;
    // The spell shape reads the level with the domain bounds; the only
    // other `level` field (a progression row) is deliberately unbounded,
    // its rule being the position plus one.
    expect(
      RegExp(r'SpellLevel\.min,\s*max:\s*SpellLevel\.max').hasMatch(text),
      isTrue,
    );
    expect(text.contains('min: 0, max: 9'), isFalse);
  }, timeout: const Timeout(Duration(seconds: 10)));
}
