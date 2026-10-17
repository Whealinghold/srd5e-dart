import 'package:srd5e/src/content/domain/content_text_block.dart';
import 'package:srd5e/src/content/domain/duration_unit.dart';
import 'package:srd5e/src/content/domain/spells/spell.dart';
import 'package:srd5e/src/content/domain/spells/spell_casting_time.dart';
import 'package:srd5e/src/content/domain/spells/spell_components.dart';
import 'package:srd5e/src/content/domain/spells/spell_duration.dart';
import 'package:srd5e/src/content/domain/spells/spell_effect_model.dart';
import 'package:srd5e/src/content/domain/spells/spell_effect_part.dart';
import 'package:srd5e/src/content/domain/spells/spell_level.dart';
import 'package:srd5e/src/content/domain/spells/spell_outcome.dart';
import 'package:srd5e/src/content/domain/spells/spell_range.dart';
import 'package:srd5e/src/content/domain/spells/spell_scaling.dart';
import 'package:srd5e/src/content/domain/spells/spell_school.dart';
import 'package:srd5e/src/content/domain/spells/spell_targeting.dart';
import 'package:srd5e/src/content/domain/typed_ids.dart';
import 'package:srd5e/src/shared_kernel/dice/dice_expression.dart';
import 'package:srd5e/src/shared_kernel/dice/die.dart';
import 'package:test/test.dart';

import '../../../support/argument_error_matcher.dart';

Spell _spell({
  String name = 'Acid Arrow',
  SpellLevel? level,
  Set<ClassId>? classes,
  List<ContentTextBlock>? description,
  List<ContentTextBlock>? higherLevel,
  List<ContentTextBlock>? cantripUpgrade,
  SpellDuration? duration,
  SpellEffectModel effects = const TextOnlyEffects(),
}) => Spell(
  id: SpellId('acid_arrow'),
  name: name,
  level: level ?? SpellLevel(2),
  school: SpellSchool.evocation,
  classes: classes ?? {ClassId('wizard')},
  castingTimes: SpellCastingTimesSingle(CastingTime.magicAction()),
  ritual: false,
  range: SpellRange.distance(90, DistanceUnit.feet),
  components: SpellComponents(verbal: true, somatic: true),
  duration: duration ?? SpellDuration.instantaneous(),
  description:
      description ??
      [ContentTextBlock.paragraph('A shimmering arrow of acid.')],
  higherLevel: higherLevel,
  cantripUpgrade: cantripUpgrade,
  effects: effects,
);

void main() {
  /// Requirement: doc/specs/content-spells.md FR-098 - the name is non-empty with no
  ///   surrounding whitespace (content-schema-and-decoder.md FR-027).
  /// Path: unhappy (invalid input)
  group('Spell name', () {
    /// Requirement: doc/specs/content-spells.md FR-098 - a Spell name is
    ///   non-empty with no leading or trailing whitespace; padded and empty
    ///   names throw (content-schema-and-decoder.md FR-027).
    /// Path: unhappy (invalid input)
    test('a padded name is rejected; a printed name is kept', () {
      expect(
        () => _spell(name: ' Acid Arrow'),
        throwsArgumentErrorFor('name', ' Acid Arrow'),
      );
      expect(() => _spell(name: ''), throwsArgumentErrorFor('name', ''));
      expect(_spell().name, 'Acid Arrow');
      expect(Spell.isValidName('Acid Arrow'), isTrue);
      expect(Spell.isValidName(' Acid Arrow'), isFalse);
    });
  });

  /// Requirement: doc/specs/content-spells.md FR-058, FR-086, FR-102 - the description is
  ///   a non-empty, unmodifiable block list; the optional texts are
  ///   non-empty when present (architecture.md §3).
  /// Path: unhappy (empty and minimal)
  group('Spell description', () {
    /// Requirement: doc/specs/content-spells.md FR-058 - description is a
    ///   non-empty, unmodifiable, ordered list of blocks; an empty list
    ///   throws (architecture.md §3).
    /// Path: unhappy (empty and minimal)
    test('an empty description is rejected', () {
      expect(
        () => _spell(description: const []),
        throwsArgumentErrorFor('description', const <ContentTextBlock>[]),
      );
    });

    /// Requirement: doc/specs/content-spells.md FR-102 - an optional block
    ///   list, when present, is non-empty; absent is accepted.
    /// Path: unhappy (empty and minimal)
    test(
      'empty higherLevel and cantripUpgrade are rejected; absent is valid',
      () {
        expect(
          () => _spell(higherLevel: const []),
          throwsArgumentErrorFor('higherLevel', const <ContentTextBlock>[]),
        );
        expect(
          () => _spell(cantripUpgrade: const []),
          throwsArgumentErrorFor('cantripUpgrade', const <ContentTextBlock>[]),
        );
        expect(
          _spell(
            higherLevel: [ContentTextBlock.paragraph('One die more.')],
          ).higherLevel,
          isNotNull,
        );
        expect(_spell().higherLevel, isNull);
        expect(_spell().cantripUpgrade, isNull);
      },
    );

    /// Requirement: doc/specs/content-spells.md FR-086 - every list is
    ///   unmodifiable, throwing UnsupportedError, and copied from its
    ///   inputs (architecture.md §3, §4).
    /// Path: unhappy (immutability)
    test('the description blocks are an unmodifiable copy', () {
      final input = [ContentTextBlock.paragraph('First paragraph.')];
      final spell = _spell(description: input);
      input.clear();
      expect(spell.description, hasLength(1));
      expect(() => spell.description.clear(), throwsUnsupportedError);
      expect(spell.description, hasLength(1));
    });
  });

  /// Requirement: doc/specs/content-spells.md FR-017, FR-018, FR-113 - the class set is an
  ///   unmodifiable, order-insensitive copy; an empty set is valid; the
  ///   key is the id's (SRD 5.2.1, "Class Spell Lists", p. 105).
  /// Path: unhappy (immutability)
  group('Spell classes', () {
    /// Requirement: doc/specs/content-spells.md FR-017 - classes is an
    ///   unmodifiable set; later mutation of the input does not change the
    ///   spell; order-insensitive equality (architecture.md §4).
    /// Path: unhappy (immutability)
    test('the class set is an unmodifiable, order-insensitive copy', () {
      final input = {ClassId('sorcerer'), ClassId('wizard')};
      final spell = _spell(classes: input);
      input.add(ClassId('bard'));
      expect(spell.classes, hasLength(2));
      expect(() => spell.classes.add(ClassId('bard')), throwsUnsupportedError);
      final reordered = _spell(
        classes: {ClassId('wizard'), ClassId('sorcerer')},
      );
      expect(reordered, spell);
      expect(reordered.hashCode, spell.hashCode);
    });

    /// Requirement: doc/specs/content-spells.md FR-018 - Spell itself MAY
    ///   have an empty class set, since a host's content may grant spells
    ///   only through features (SRD 5.2.1, "Class Spell Lists", p. 105).
    /// Path: happy
    test('an empty class set is valid', () {
      expect(_spell(classes: const {}).classes, isEmpty);
    });

    /// Requirement: doc/specs/content-spells.md FR-113 - Spell.key equals
    ///   id.key, the key of kind spell (content-schema-and-decoder.md
    ///   FR-114).
    /// Path: happy
    test('the key is the spell kind with the id', () {
      final spell = _spell();
      expect(spell.key, spell.id.key);
      expect(spell.key.kind.name, 'spell');
      expect(spell.key.id.value, 'acid_arrow');
    });
  });

  /// Requirement: doc/specs/content-spells.md FR-057 - true iff the duration is a
  ///   Concentration-capped Time Span (SRD 5.2.1, p. 106).
  /// Path: happy
  group('requiresConcentration', () {
    /// Requirement: doc/specs/content-spells.md FR-057 - true iff the
    ///   duration is a Concentration-capped Time Span (SRD 5.2.1,
    ///   "Duration" (Concentration), p. 106).
    /// Path: happy
    test('true exactly for concentrationUpTo timed durations', () {
      final concentration = _spell(
        duration: SpellDuration.timed(
          1,
          DurationUnit.hours,
          DurationLimit.concentrationUpTo,
        ),
      );
      final fixed = _spell(
        duration: SpellDuration.timed(
          8,
          DurationUnit.hours,
          DurationLimit.fixed,
        ),
      );
      final capped = _spell(
        duration: SpellDuration.timed(
          1,
          DurationUnit.hours,
          DurationLimit.upTo,
        ),
      );
      expect(concentration.requiresConcentration, isTrue);
      expect(fixed.requiresConcentration, isFalse);
      expect(capped.requiresConcentration, isFalse);
      expect(_spell().requiresConcentration, isFalse);
    });
  });

  /// Requirement: doc/specs/content-spells.md FR-087, FR-122 - two spells are equal iff
  ///   all fields, effects included, are equal; effects defaults to
  ///   const TextOnlyEffects (architecture.md §3).
  /// Path: happy
  group('Spell equality and effects', () {
    /// Requirement: doc/specs/content-spells.md FR-087 - two Spells are
    ///   equal, with equal hash codes, iff all their fields, effects
    ///   included, are equal (architecture.md §3).
    /// Path: happy
    test('equal fields and effects are equal; differing effects are not', () {
      expect(_spell(), _spell());
      expect(_spell().hashCode, _spell().hashCode);
      final modelled = _spell(effects: _modelledEffects());
      expect(modelled, isNot(_spell()));
      expect(modelled, _spell(effects: _modelledEffects()));
      // An absent section and a present one are not equal, on either side.
      final withHigherLevel = _spell(
        higherLevel: [ContentTextBlock.paragraph('One die more.')],
      );
      expect(withHigherLevel, isNot(_spell()));
      expect(_spell(), isNot(withHigherLevel));
      final withUpgrade = _spell(
        cantripUpgrade: [ContentTextBlock.paragraph('One die more.')],
      );
      expect(withUpgrade, isNot(_spell()));
      expect(_spell(), isNot(withUpgrade));
    });

    /// Requirement: doc/specs/content-spells.md FR-087, spell-effect-data.md
    ///   FR-009 - the effects must agree with the spell's level: a
    ///   character-level amount table belongs to a cantrip, so a level 1+
    ///   spell holding one is rejected at construction.
    /// Path: unhappy (rule interaction)
    test('effects contradicting the spell level are rejected', () {
      final cantripTable = CharacterLevelTable<SpellAmount>([
        (1, RolledSpellAmount(DiceExpression(1, Die.d10))),
        (5, RolledSpellAmount(DiceExpression(2, Die.d10))),
      ]);
      expect(
        () => _spell(
          effects: ModelledEffects(
            coverage: EffectCoverage.complete,
            targeting: const TargetsSelf(),
            parts: [
              SpellEffectPart(
                AutomaticResolution([
                  SpellRestoresHitPoints(
                    ScalableAmount(
                      RolledSpellAmount(DiceExpression(2, Die.d4)),
                      scaling: ByCharacterLevelAmount(cantripTable),
                    ),
                    ModifierAddition.none,
                  ),
                ]),
                PartInstances(1),
              ),
            ],
          ),
        ),
        throwsA(
          isA<ArgumentError>().having((e) => e.name, 'name', 'spellLevel'),
        ),
      );
    });

    /// Requirement: doc/specs/content-spells.md FR-122, spell-effect-data.md
    ///   FR-001 - effects defaults to const TextOnlyEffects; a given value
    ///   is kept (SRD 5.2.1, "Effects", p. 106).
    /// Path: happy
    test('effects defaults to the const TextOnlyEffects', () {
      final spell = _spell();
      expect(spell.effects, const TextOnlyEffects());
      expect(spell.effects.hashCode, const TextOnlyEffects().hashCode);
      expect(
        _spell(effects: _modelledEffects()).effects,
        isA<ModelledEffects>(),
      );
    });
  });
}

ModelledEffects _modelledEffects() => ModelledEffects(
  coverage: EffectCoverage.complete,
  targeting: const TargetsSelf(),
  parts: [
    SpellEffectPart(
      AutomaticResolution([
        SpellRestoresHitPoints(
          ScalableAmount(RolledSpellAmount(DiceExpression(2, Die.d4))),
          ModifierAddition.spellcastingAbilityModifier,
        ),
      ]),
      PartInstances(1),
    ),
  ],
);
