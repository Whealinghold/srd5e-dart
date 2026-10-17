import 'package:srd5e/src/content/domain/content_id.dart';
import 'package:srd5e/src/content/domain/content_key.dart';
import 'package:srd5e/src/content/domain/content_kind.dart';
import 'package:srd5e/src/content/domain/content_reference.dart';
import 'package:srd5e/src/content/domain/feat_category.dart';
import 'package:test/test.dart';

import '../../support/operator_equals.dart';

final ContentKey _featKey = ContentKey(
  ContentKind.feat,
  ContentId('origin_feat'),
);

/// A synthetic entry implementing [ContentReferences], as an entry type of a
/// data spec will.
final class _ReferencingEntry implements ContentReferences {
  const _ReferencingEntry(this.references);

  @override
  final List<ContentReference> references;
}

/// A synthetic entry implementing [HasFeatCategory], as `Feat` will (Q19).
final class _CategorisedEntry implements HasFeatCategory {
  const _CategorisedEntry(this.featCategory);

  @override
  final FeatCategory featCategory;
}

void main() {
  /// Requirement: doc/specs/content-schema-and-decoder.md FR-125 -
  ///   ContentReference is a value object of field, target and optional
  ///   constraint.
  /// Path: happy
  test('references compare by field, target and constraint', () {
    final reference = ContentReference('feat/featId', _featKey);
    final same = ContentReference('feat/featId', _featKey);
    final withConstraint = ContentReference(
      'feat/featId',
      _featKey,
      const TargetHasFeatCategory(FeatCategory.origin),
    );

    expect(reference, same);
    expect(reference.hashCode, same.hashCode);
    expect(reference.constraint, isNull);
    expect(operatorEquals(reference, withConstraint), isFalse);
    expect(
      operatorEquals(
        ContentReference('a', _featKey),
        ContentReference('b', _featKey),
      ),
      isFalse,
    );
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-126 -
  ///   TargetHasFeatCategory is value-equal by its category.
  /// Path: happy
  test('TargetHasFeatCategory compares by its category', () {
    const origin = TargetHasFeatCategory(FeatCategory.origin);

    expect(origin, const TargetHasFeatCategory(FeatCategory.origin));
    expect(
      origin.hashCode,
      const TargetHasFeatCategory(FeatCategory.origin).hashCode,
    );
    expect(
      operatorEquals(origin, const TargetHasFeatCategory(FeatCategory.general)),
      isFalse,
    );
    expect(origin.category, FeatCategory.origin);
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-126 - the
  ///   constraint family is sealed with exactly one variant, and a switch is
  ///   exhaustive without a default.
  /// Path: happy
  test('a switch over the constraint family selects its case', () {
    String describe(ReferenceConstraint constraint) => switch (constraint) {
      TargetHasFeatCategory() => 'targetHasFeatCategory',
    };

    expect(
      describe(const TargetHasFeatCategory(FeatCategory.origin)),
      'targetHasFeatCategory',
    );
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-125 - an entry
  ///   lists its sites through the ContentReferences interface, in
  ///   declaration order.
  /// Path: happy
  test('a synthetic entry exposes its sites through ContentReferences', () {
    final entry = _ReferencingEntry([
      ContentReference('feat/featId', _featKey),
    ]);

    expect(entry.references, hasLength(1));
    expect(entry.references.first.field, 'feat/featId');
    expect(entry.references.first.target, _featKey);
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-126 - a target
  ///   implementing HasFeatCategory reports its category, so the constraint
  ///   can check it.
  /// Path: happy
  test('a synthetic entry reports its category through HasFeatCategory', () {
    const entry = _CategorisedEntry(FeatCategory.origin);

    expect(entry.featCategory, FeatCategory.origin);
  });

  /// Requirement: doc/specs/content-schema-and-decoder.md FR-125 and FR-126 -
  ///   toString is the debugging form carrying the parts.
  /// Path: happy
  test('references and constraints print their parts', () {
    expect(
      ContentReference('feat/featId', _featKey).toString(),
      'ContentReference(feat/featId -> feat/origin_feat)',
    );
    expect(
      const TargetHasFeatCategory(FeatCategory.origin).toString(),
      'TargetHasFeatCategory(origin)',
    );
  });
}
