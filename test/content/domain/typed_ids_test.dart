import 'package:srd5e/src/content/domain/content_id.dart';
import 'package:srd5e/src/content/domain/content_key.dart';
import 'package:srd5e/src/content/domain/content_kind.dart';
import 'package:srd5e/src/content/domain/missing_content.dart';
import 'package:srd5e/src/content/domain/typed_id.dart';
import 'package:srd5e/src/content/domain/typed_ids.dart';
import 'package:test/test.dart';

import '../../support/argument_error_matcher.dart';
import '../../support/operator_equals.dart';

/// One typed id of the FR-114 mapping table: how to construct, wrap and
/// parse it, and the [ContentKind] its `key` addresses, or null for the two
/// ids that have no kind.
typedef _TypedIdSpec = ({
  String label,
  String requirement,
  String path,
  TypedId Function(String value) construct,
  TypedId Function(ContentId id) of,
  TypedIdParse<TypedId> Function(String value) tryCreate,
  ContentKind? kind,
});

String _specRequirement(String name, String fact) =>
    'doc/specs/content-schema-and-decoder.md FR-114 - $name $fact';

final List<_TypedIdSpec> _specs = [
  (
    label: 'SpeciesId',
    requirement: _specRequirement(
      'SpeciesId',
      'wraps a ContentId; its key '
          'kind is species',
    ),
    path: 'happy',
    construct: SpeciesId.new,
    of: SpeciesId.of,
    tryCreate: SpeciesId.tryCreate,
    kind: ContentKind.species,
  ),
  (
    label: 'BackgroundId',
    requirement: _specRequirement(
      'BackgroundId',
      'wraps a ContentId; its key '
          'kind is background',
    ),
    path: 'happy',
    construct: BackgroundId.new,
    of: BackgroundId.of,
    tryCreate: BackgroundId.tryCreate,
    kind: ContentKind.background,
  ),
  (
    label: 'ClassId',
    requirement: _specRequirement(
      'ClassId',
      'wraps a ContentId; its key kind '
          'is characterClass',
    ),
    path: 'happy',
    construct: ClassId.new,
    of: ClassId.of,
    tryCreate: ClassId.tryCreate,
    kind: ContentKind.characterClass,
  ),
  (
    label: 'SubclassId',
    requirement: _specRequirement(
      'SubclassId',
      'wraps a ContentId and is a '
          'TypedId only, with no key',
    ),
    path: 'happy',
    construct: SubclassId.new,
    of: SubclassId.of,
    tryCreate: SubclassId.tryCreate,
    kind: null,
  ),
  (
    label: 'FeatId',
    requirement: _specRequirement(
      'FeatId',
      'wraps a ContentId; its key kind '
          'is feat',
    ),
    path: 'happy',
    construct: FeatId.new,
    of: FeatId.of,
    tryCreate: FeatId.tryCreate,
    kind: ContentKind.feat,
  ),
  (
    label: 'SpellId',
    requirement: _specRequirement(
      'SpellId',
      'wraps a ContentId; its key kind '
          'is spell',
    ),
    path: 'happy',
    construct: SpellId.new,
    of: SpellId.of,
    tryCreate: SpellId.tryCreate,
    kind: ContentKind.spell,
  ),
  (
    label: 'ItemId',
    requirement: _specRequirement(
      'ItemId',
      'wraps a ContentId; its key kind '
          'is equipment',
    ),
    path: 'happy',
    construct: ItemId.new,
    of: ItemId.of,
    tryCreate: ItemId.tryCreate,
    kind: ContentKind.equipment,
  ),
  (
    label: 'MonsterId',
    requirement: _specRequirement(
      'MonsterId',
      'wraps a ContentId; its key '
          'kind is monster',
    ),
    path: 'happy',
    construct: MonsterId.new,
    of: MonsterId.of,
    tryCreate: MonsterId.tryCreate,
    kind: ContentKind.monster,
  ),
  (
    label: 'FeatureId',
    requirement: _specRequirement(
      'FeatureId',
      'wraps a ContentId and is a '
          'TypedId only, with no key',
    ),
    path: 'happy',
    construct: FeatureId.new,
    of: FeatureId.of,
    tryCreate: FeatureId.tryCreate,
    kind: null,
  ),
];

/// The id strings every typed id's constructor and `tryCreate` must agree
/// on: [problem] null when accepted, the [ContentIdProblem] otherwise.
typedef _IdRow = ({
  String label,
  String requirement,
  String path,
  String value,
  ContentIdProblem? problem,
});

String _rowRequirement(String fact) =>
    'doc/specs/content-schema-and-decoder.md FR-114 and FR-143 - $fact';

final List<_IdRow> _idRows = [
  (
    label: 'a',
    requirement: _rowRequirement('the id a is accepted'),
    path: 'unhappy (boundary)',
    value: 'a',
    problem: null,
  ),
  (
    label: 'a1',
    requirement: _rowRequirement('digits after the letter are accepted'),
    path: 'unhappy (boundary)',
    value: 'a1',
    problem: null,
  ),
  (
    label: 'a_b',
    requirement: _rowRequirement('underscores after the letter are accepted'),
    path: 'unhappy (boundary)',
    value: 'a_b',
    problem: null,
  ),
  (
    label: '64 characters',
    requirement: _rowRequirement('exactly 64 code units are accepted'),
    path: 'unhappy (boundary)',
    value: 'a${'b' * 63}',
    problem: null,
  ),
  (
    label: 'empty',
    requirement: _rowRequirement('the empty string is rejected as empty'),
    path: 'unhappy (invalid input)',
    value: '',
    problem: ContentIdProblem.empty,
  ),
  (
    label: 'interior space',
    requirement: _rowRequirement('interior whitespace is not of the id shape'),
    path: 'unhappy (invalid input)',
    value: 'a b',
    problem: ContentIdProblem.invalidFormat,
  ),
  (
    label: 'digit first',
    requirement: _rowRequirement('a digit first is not of the id shape'),
    path: 'unhappy (boundary)',
    value: '2a',
    problem: ContentIdProblem.invalidFormat,
  ),
  (
    label: '65 characters',
    requirement: _rowRequirement('a string over 64 units is too long'),
    path: 'unhappy (boundary)',
    value: 'a${'b' * 64}',
    problem: ContentIdProblem.tooLong,
  ),
  (
    label: '65 uppercase',
    requirement: _rowRequirement(
      '65 uppercase characters report tooLong, '
      'the first failing check',
    ),
    path: 'unhappy (boundary)',
    value: 'A' * 65,
    problem: ContentIdProblem.tooLong,
  ),
];

void main() {
  /// Requirement: per case
  /// Path: per case
  for (final s in _specs) {
    test('${s.label} wraps its ContentId [${s.path}]', () {
      final id = s.construct('a');

      expect(id.id, ContentId('a'));
      expect(s.of(ContentId('a')), id);
    });

    test('${s.label} compares and hashes by type and id [${s.path}]', () {
      final id = s.construct('a');
      final same = s.construct('a');
      final other = s.construct('b');

      expect(id, same);
      expect(id.hashCode, same.hashCode);
      expect(operatorEquals(id, other), isFalse);
      expect(operatorEquals(other, id), isFalse);
    });
  }

  /// Requirement: per case
  /// Path: per case
  for (final s in _specs) {
    test('${s.label} key and missing [${s.path}]', () {
      if (s.kind == null) {
        expect(s.construct('a'), isNot(isA<ContentKeyedId>()));
      } else {
        final keyed = s.construct('a') as ContentKeyedId;
        expect(keyed.key, ContentKey(s.kind!, ContentId('a')));
        expect(keyed.missing, MissingContent(s.kind!, ContentId('a')));
      }
    });
  }

  /// Requirement: per case
  /// Path: per case
  for (final s in _specs) {
    /// Requirement: per case
    /// Path: per case
    for (final row in _idRows) {
      test(
        '${s.label} agrees with ContentId on ${row.label} [${row.path}]',
        () {
          if (row.problem == null) {
            expect(s.construct(row.value).id, ContentId(row.value));
            final parse = s.tryCreate(row.value);
            expect(parse, isA<TypedIdParsed>());
            expect((parse as TypedIdParsed).id.id, ContentId(row.value));
          } else {
            expect(
              () => s.construct(row.value),
              throwsArgumentErrorFor('value', row.value),
            );
            final parse = s.tryCreate(row.value);
            expect(parse, TypedIdRejected<TypedId>(row.problem!));
          }
        },
      );
    }
  }

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-114 - equality
  ///   and hashCode are by type and id, so SpellId('a') != ClassId('a').
  /// Path: unhappy (rule interaction)
  test('the same id under two typed ids is not equal', () {
    expect(operatorEquals(SpellId('a'), ClassId('a')), isFalse);
    expect(operatorEquals(ClassId('a'), SpellId('a')), isFalse);
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-114 - the
  ///   mapping table: each keyed id addresses its kind, SubclassId and
  ///   FeatureId none.
  /// Path: happy
  test('the key kinds follow the mapping table', () {
    expect((SpeciesId('a') as ContentKeyedId).key.kind, ContentKind.species);
    expect(
      (BackgroundId('a') as ContentKeyedId).key.kind,
      ContentKind.background,
    );
    expect(
      (ClassId('a') as ContentKeyedId).key.kind,
      ContentKind.characterClass,
    );
    expect((FeatId('a') as ContentKeyedId).key.kind, ContentKind.feat);
    expect((SpellId('a') as ContentKeyedId).key.kind, ContentKind.spell);
    expect((ItemId('a') as ContentKeyedId).key.kind, ContentKind.equipment);
    expect((MonsterId('a') as ContentKeyedId).key.kind, ContentKind.monster);
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-114 - the
  ///   parse result is a sealed TypedIdParse, exhaustive without a default.
  /// Path: happy
  test('a switch over the parse result selects its case', () {
    String describe(TypedIdParse<TypedId> parse) => switch (parse) {
      TypedIdParsed() => 'parsed',
      TypedIdRejected() => 'rejected',
    };

    expect(describe(SpellId.tryCreate('a')), 'parsed');
    expect(describe(SpellId.tryCreate('A')), 'rejected');
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-114 - the
  ///   rejected parse carries the same problem and precedence as
  ///   ContentId.tryCreate.
  /// Path: unhappy (boundary)
  test('tryCreate rejects with the ContentIdProblem, not a throw', () {
    expect(
      SpellId.tryCreate(''),
      const TypedIdRejected<SpellId>(ContentIdProblem.empty),
    );
    expect(
      SpellId.tryCreate('A' * 65),
      const TypedIdRejected<SpellId>(ContentIdProblem.tooLong),
    );
    expect(
      SpellId.tryCreate('Acid'),
      const TypedIdRejected<SpellId>(ContentIdProblem.invalidFormat),
    );
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-114 - the typed
  ///   ids and their parse results are value objects: they compare by value,
  ///   hash consistently and print their parts.
  /// Path: happy
  test('typed ids and parse results print their parts', () {
    expect(SpeciesId('a').toString(), 'SpeciesId(a)');

    final parsed = SpellId.tryCreate('a');
    final same = SpellId.tryCreate('a');
    expect(parsed, same);
    expect(parsed.hashCode, same.hashCode);
    expect(operatorEquals(parsed, SpellId.tryCreate('b')), isFalse);
    expect(parsed.toString(), 'TypedIdParsed(SpellId(a))');

    final rejected = SpellId.tryCreate('');
    final sameRejected = SpellId.tryCreate('');
    expect(rejected, sameRejected);
    expect(rejected.hashCode, sameRejected.hashCode);
    expect(operatorEquals(rejected, parsed), isFalse);
    expect(rejected.toString(), 'TypedIdRejected(empty)');
  });
}
