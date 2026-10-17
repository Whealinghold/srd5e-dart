import 'package:srd5e/src/content/domain/content_entry.dart';
import 'package:srd5e/src/content/domain/content_id.dart';
import 'package:srd5e/src/content/domain/content_key.dart';
import 'package:srd5e/src/content/domain/content_kind.dart';
import 'package:srd5e/src/content/domain/content_problem_kind.dart';
import 'package:srd5e/src/content/domain/content_reference.dart';
import 'package:srd5e/src/content/domain/content_reference_problem.dart';
import 'package:srd5e/src/content/domain/content_set.dart';
import 'package:srd5e/src/content/domain/content_set_validation.dart';
import 'package:srd5e/src/content/domain/feat_category.dart';
import 'package:srd5e/src/content/domain/validate_content_set.dart';
import 'package:test/test.dart';

import '../../support/argument_error_matcher.dart';

ContentKey _key(ContentKind kind, String id) => ContentKey(kind, ContentId(id));

ContentSet _setOf(List<ContentEntry> entries) => ContentSet(entries);

/// A background-like owner: [sites] are its reference sites, in order.
final class _Owner implements ContentEntry, ContentReferences {
  const _Owner(this.key, this.sites);

  final List<ContentReference> sites;

  @override
  final ContentKey key;

  @override
  Iterable<ContentReference> get references => sites;

  @override
  bool operator ==(Object other) => other is _Owner && other.key == key;

  @override
  int get hashCode => key.hashCode;
}

/// A feat-like target whose category a constraint can read, with optional
/// sites of its own.
final class _Feat implements ContentEntry, ContentReferences, HasFeatCategory {
  const _Feat(
    this.key, {
    this.category = FeatCategory.origin,
    this.sites = const [],
  });

  final List<ContentReference> sites;

  @override
  final ContentKey key;

  final FeatCategory category;

  @override
  FeatCategory get featCategory => category;

  @override
  Iterable<ContentReference> get references => sites;

  @override
  bool operator ==(Object other) => other is _Feat && other.key == key;

  @override
  int get hashCode => key.hashCode;
}

/// An entry that is neither a ContentReferences nor a HasFeatCategory.
final class _Plain implements ContentEntry {
  const _Plain(this.key);

  @override
  final ContentKey key;

  @override
  bool operator ==(Object other) => other is _Plain && other.key == key;

  @override
  int get hashCode => key.hashCode;
}

ContentReference _featSite(ContentKey target) => ContentReference(
  'feat/featId',
  target,
  const TargetHasFeatCategory(FeatCategory.origin),
);

_Owner _background(String id, List<ContentReference> sites) =>
    _Owner(_key(ContentKind.background, id), sites);

void main() {
  /// Requirement: doc/specs/content-schema-and-decoder.md FR-125,
  ///   FR-036 - a background alone is a valid set: the Origin rule of the
  ///   feat reference is never checked by a merge.
  /// Path: happy
  test('a background feat named by no set is unresolvedReference', () {
    final background = _background('b1', [
      _featSite(_key(ContentKind.feat, 'f1')),
    ]);

    final validation = validateContentSet([
      _setOf([background]),
    ]);

    expect(validation, isA<ContentSetInvalid>());
    final problems = (validation as ContentSetInvalid).problems;
    expect(problems.single.kind, ContentProblemKind.unresolvedReference);
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-125,
  ///   FR-036 - a resolving reference is valid and the merged set holds
  ///   both entries in FR-071 order (background before feat).
  /// Path: happy
  test('a reference that resolves gives the merged set in FR-071 order', () {
    final feat = _Feat(_key(ContentKind.feat, 'f1'));
    final background = _background('b1', [
      _featSite(_key(ContentKind.feat, 'f1')),
    ]);

    final validation = validateContentSet([
      _setOf([feat]),
      _setOf([background]),
    ]);

    final valid = validation;
    expect(valid, isA<ContentSetValid>());
    expect(
      [
        for (final entry in (valid as ContentSetValid).contentSet.entries)
          entry.key,
      ],
      [_key(ContentKind.background, 'b1'), _key(ContentKind.feat, 'f1')],
    );
  });

  /// Requirement: per case - doc/specs/content-schema-and-decoder.md FR-125 - a reference naming a key in no set is unresolvedReference.
  /// Path: per case
  for (final c in _unresolvedCases) {
    test('unresolved: ${c.label} [${c.path}]', () {
      final validation = validateContentSet(c.sets);

      expect(validation, isA<ContentSetInvalid>());
      final problems = (validation as ContentSetInvalid).problems;
      expect(problems, hasLength(1));
      expect(problems.first.owner, _key(ContentKind.background, 'b1'));
      expect(problems.first.field, 'feat/featId');
      expect(problems.first.target, c.target);
      expect(problems.first.kind, ContentProblemKind.unresolvedReference);
    });
  }

  /// Requirement: per case - doc/specs/content-schema-and-decoder.md FR-036, FR-126 - a target of another category, or a target that is not a HasFeatCategory, is constraintViolation.
  /// Path: per case
  for (final c in _constraintCases) {
    test('constraint: ${c.label} [${c.path}]', () {
      final background = _background('b1', [_featSite(c.target)]);

      final validation = validateContentSet([
        _setOf([background]),
        _setOf([c.targetEntry]),
      ]);

      expect(validation, isA<ContentSetInvalid>());
      final problems = (validation as ContentSetInvalid).problems;
      expect(problems, hasLength(1));
      expect(problems.first.kind, ContentProblemKind.constraintViolation);
      expect(problems.first.target, c.target);
    });
  }

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-125 - the
  ///   same key in two sets is a duplicate naming the later set's entry.
  /// Path: unhappy (invalid input)
  test('the same key in two sets is a duplicate of the later entry', () {
    final validation = validateContentSet([
      _setOf([_Plain(_key(ContentKind.spell, 'a'))]),
      _setOf([_Plain(_key(ContentKind.spell, 'a'))]),
    ]);

    expect(validation, isA<ContentSetInvalid>());
    final problems = (validation as ContentSetInvalid).problems;
    expect(problems, hasLength(1));
    expect(problems.first.kind, ContentProblemKind.duplicate);
    expect(problems.first.owner, _key(ContentKind.spell, 'a'));
    expect(problems.first.field, '');
    expect(problems.first.target, _key(ContentKind.spell, 'a'));
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-125 - an
  ///   entry implementing no ContentReferences has no sites.
  /// Path: happy
  test('an owner without references contributes no problem', () {
    final validation = validateContentSet([
      _setOf([_Plain(_key(ContentKind.spell, 'a'))]),
    ]);

    expect(
      validation,
      ContentSetValid(_setOf([_Plain(_key(ContentKind.spell, 'a'))])),
    );
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-127 - the
  ///   problems are ordered by owner kind (FR-142 order), then owner id,
  ///   then the order the entry lists its references.
  /// Path: happy
  test('problems are ordered by kind, then id, then reference order', () {
    final b2 = _background('b2', [
      ContentReference('feat/featId', _key(ContentKind.feat, 'missing_1')),
      ContentReference('feat/featId', _key(ContentKind.feat, 'missing_2')),
    ]);
    final s9 = _background('s9', [
      ContentReference('feat/featId', _key(ContentKind.feat, 'missing_3')),
    ]);
    // Given as a background-kind set before a species-kind set: the report
    // order is the owner kind's, not the input order.
    final speciesSet = _setOf([
      _Owner(_key(ContentKind.species, 's9'), s9.sites),
    ]);

    final validation = validateContentSet([
      _setOf([b2]),
      speciesSet,
    ]);

    expect(validation, isA<ContentSetInvalid>());
    final problems = (validation as ContentSetInvalid).problems;
    expect(
      [
        for (final problem in problems)
          (owner: problem.owner, target: problem.target),
      ],
      [
        // Species (kind 0) before background (kind 1); inside a kind by id,
        // inside an entry in reference order.
        (
          owner: _key(ContentKind.species, 's9'),
          target: _key(ContentKind.feat, 'missing_3'),
        ),
        (
          owner: _key(ContentKind.background, 'b2'),
          target: _key(ContentKind.feat, 'missing_1'),
        ),
        (
          owner: _key(ContentKind.background, 'b2'),
          target: _key(ContentKind.feat, 'missing_2'),
        ),
      ],
    );
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-126,
  ///   FR-140 - no site opts out: one resolving and one unresolved site
  ///   give one unresolvedReference, at the unresolved field only.
  /// Path: unhappy (dangling id)
  test('a resolving site never hides an unresolved one', () {
    final target = _Feat(_key(ContentKind.feat, 'f1'));
    final owner = _background('b1', [
      _featSite(_key(ContentKind.feat, 'f1')),
      ContentReference('variantOf', _key(ContentKind.background, 'nope')),
    ]);

    final validation = validateContentSet([
      _setOf([target]),
      _setOf([owner]),
    ]);

    expect(validation, isA<ContentSetInvalid>());
    final problems = (validation as ContentSetInvalid).problems;
    expect(problems, hasLength(1));
    expect(problems.first.field, 'variantOf');
  });

  /// Requirement: per case - doc/specs/content-schema-and-decoder.md FR-126, FR-140 - a same-kind reference is a site like any other.
  /// Path: per case
  for (final c in _sameKindCases) {
    test('same-kind reference: ${c.label} [${c.path}]', () {
      final e2 = _Owner(_key(ContentKind.equipment, 'e2'), [
        ContentReference('variantOf', _key(ContentKind.equipment, 'e1')),
      ]);

      final validation = validateContentSet([
        _setOf([
          if (c.withTarget) _Plain(_key(ContentKind.equipment, 'e1')),
          e2,
        ]),
      ]);

      expect(
        validation,
        c.withTarget ? isA<ContentSetValid>() : isA<ContentSetInvalid>(),
      );
    });
  }

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-095 - an
  ///   entry present under a valid key is a target even when it has
  ///   problems of its own (here: its own dangling site).
  /// Path: unhappy (rule interaction)
  test('a target with its own unresolved site still resolves others', () {
    final brokenTarget = _Feat(
      _key(ContentKind.feat, 'f1'),
      sites: [ContentReference('variantOf', _key(ContentKind.feat, 'missing'))],
    );
    final background = _background('b1', [
      _featSite(_key(ContentKind.feat, 'f1')),
    ]);

    final validation = validateContentSet([
      _setOf([brokenTarget]),
      _setOf([background]),
    ]);

    expect(validation, isA<ContentSetInvalid>());
    final problems = (validation as ContentSetInvalid).problems;
    // The broken target's own dangling site - not the background's
    // resolving reference.
    expect(problems, hasLength(1));
    expect(problems.first.owner, _key(ContentKind.feat, 'f1'));
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-093,
  ///   FR-017 - ContentSetInvalid rejects an empty list and holds an
  ///   unmodifiable defensive copy.
  /// Path: unhappy (immutability)
  test('ContentSetInvalid rejects an empty list and copies its list', () {
    expect(
      () => ContentSetInvalid(const []),
      throwsArgumentErrorFor('problems', const <ContentReferenceProblem>[]),
    );

    final problems = [
      ContentReferenceProblem(
        owner: _key(ContentKind.background, 'b1'),
        field: 'feat/featId',
        target: _key(ContentKind.feat, 'f1'),
        kind: ContentProblemKind.unresolvedReference,
      ),
    ];
    final invalid = ContentSetInvalid(problems);
    problems.clear();

    expect(invalid.problems, hasLength(1));
    expect(() => invalid.problems.clear(), throwsUnsupportedError);
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-125,
  ///   FR-126 - the problem and constraint types compare by value.
  /// Path: happy
  test('ContentReferenceProblem and TargetHasFeatCategory equality', () {
    ContentReferenceProblem problem(String field) => ContentReferenceProblem(
      owner: _key(ContentKind.background, 'b1'),
      field: field,
      target: _key(ContentKind.feat, 'f1'),
      kind: ContentProblemKind.unresolvedReference,
    );

    expect(problem('feat/featId'), problem('feat/featId'));
    expect(problem('feat/featId').hashCode, problem('feat/featId').hashCode);
    expect(problem('feat/featId'), isNot(problem('variantOf')));
    // A duplicate problem has an empty field: the other toString branch.
    final duplicate = ContentReferenceProblem(
      owner: _key(ContentKind.spell, 'a'),
      field: '',
      target: _key(ContentKind.spell, 'a'),
      kind: ContentProblemKind.duplicate,
    );
    expect(
      duplicate.toString(),
      'ContentReferenceProblem(spell/a -> spell/a, duplicate)',
    );
    expect(
      const TargetHasFeatCategory(FeatCategory.origin),
      const TargetHasFeatCategory(FeatCategory.origin),
    );
    expect(
      const TargetHasFeatCategory(FeatCategory.origin).hashCode,
      const TargetHasFeatCategory(FeatCategory.origin).hashCode,
    );
    expect(
      const TargetHasFeatCategory(FeatCategory.origin),
      isNot(const TargetHasFeatCategory(FeatCategory.general)),
    );
    expect(
      problem('feat/featId').toString(),
      'ContentReferenceProblem(background/b1/feat/featId -> feat/f1, '
      'unresolvedReference)',
    );
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-097 - the
  ///   validation variants have value equality and a consistent hashCode.
  /// Path: happy
  test('ContentSetValid and ContentSetInvalid equality and toString', () {
    final feat = _Feat(_key(ContentKind.feat, 'f1'));
    final valid = ContentSetValid(_setOf([feat]));

    expect(
      valid,
      ContentSetValid(_setOf([_Feat(_key(ContentKind.feat, 'f1'))])),
    );
    expect(
      valid.hashCode,
      ContentSetValid(_setOf([_Feat(_key(ContentKind.feat, 'f1'))])).hashCode,
    );
    expect(valid.toString(), startsWith('ContentSetValid('));

    ContentReferenceProblem dangling() => ContentReferenceProblem(
      owner: _key(ContentKind.background, 'b1'),
      field: 'feat/featId',
      target: _key(ContentKind.feat, 'f1'),
      kind: ContentProblemKind.unresolvedReference,
    );
    final invalid = ContentSetInvalid([dangling()]);

    expect(invalid, ContentSetInvalid([dangling()]));
    expect(invalid.hashCode, ContentSetInvalid([dangling()]).hashCode);
    expect(
      invalid,
      isNot(
        ContentSetInvalid([
          ContentReferenceProblem(
            owner: _key(ContentKind.background, 'b1'),
            field: 'variantOf',
            target: _key(ContentKind.feat, 'f1'),
            kind: ContentProblemKind.unresolvedReference,
          ),
        ]),
      ),
    );
    expect(invalid.toString(), 'ContentSetInvalid(1 problems)');
    expect(valid, isNot(ContentSetInvalid([dangling()])));
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-125 - the
  ///   validation never throws for content, not even for empty input.
  /// Path: happy
  test('empty input gives the empty merged set', () {
    final validation = validateContentSet(const []);

    expect(validation, isA<ContentSetValid>());
    expect((validation as ContentSetValid).contentSet.entries, isEmpty);
  });
}

final class _UnresolvedCase {
  const _UnresolvedCase(this.label, this.sets, this.target)
    : path = 'unhappy (missing content)';

  final String label;
  final List<ContentSet> sets;
  final ContentKey target;
  final String path;
}

final List<_UnresolvedCase> _unresolvedCases = [
  _UnresolvedCase('the other set names another feat', [
    _setOf([_Feat(_key(ContentKind.feat, 'f1'))]),
    _setOf([
      _background('b1', [_featSite(_key(ContentKind.feat, 'nothing'))]),
    ]),
  ], _key(ContentKind.feat, 'nothing')),
  _UnresolvedCase('the background set alone', [
    _setOf([
      _background('b1', [_featSite(_key(ContentKind.feat, 'f1'))]),
    ]),
  ], _key(ContentKind.feat, 'f1')),
];

final class _ConstraintCase {
  const _ConstraintCase(this.label, this.target, this.targetEntry)
    : path = 'unhappy (rule interaction)';

  final String label;
  final ContentKey target;
  final ContentEntry targetEntry;
  final String path;
}

final List<_ConstraintCase> _constraintCases = [
  _ConstraintCase(
    'a General feat',
    _key(ContentKind.feat, 'f1'),
    _Feat(_key(ContentKind.feat, 'f1'), category: FeatCategory.general),
  ),
  _ConstraintCase(
    'a target that is not a HasFeatCategory',
    _key(ContentKind.species, 'f1'),
    _Plain(_key(ContentKind.species, 'f1')),
  ),
];

final class _SameKindCase {
  const _SameKindCase(this.label, this.withTarget)
    : path = withTarget ? 'happy' : 'unhappy (dangling id)';

  final String label;
  final bool withTarget;
  final String path;
}

const List<_SameKindCase> _sameKindCases = [
  _SameKindCase('the target present', true),
  _SameKindCase('the target absent', false),
];
