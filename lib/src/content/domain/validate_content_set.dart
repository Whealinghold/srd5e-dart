import 'content_entry.dart';
import 'content_key.dart';
import 'content_problem_kind.dart';
import 'content_reference.dart';
import 'content_reference_problem.dart';
import 'content_set.dart';
import 'content_set_validation.dart';

/// Resolves every reference site of every entry of [sets] over the merged
/// entries, the one place a reference between entries is checked (FR-125,
/// FR-140).
///
/// Pure and synchronous; it never throws for content and reports every
/// problem found, ordered by owner [ContentKey]'s kind (FR-142 order), then
/// owner id (ordinal), then the order the entry lists its references
/// (FR-127). The checks:
///
/// - the same [ContentKey] held by two sets is a `duplicate` naming the
///   later set's entry;
/// - a reference site whose target key is in no set is an
///   `unresolvedReference`;
/// - a target that exists but fails the site's [ReferenceConstraint] is a
///   `constraintViolation`.
///
/// An entry present under a valid key is a target even when it has other
/// problems (FR-095): existence is read from the merged key set before any
/// constraint runs. An entry implementing no [ContentReferences] has no
/// sites and contributes nothing. Assembling components
/// (`BundledContentSource`; a host loading several documents) MUST run this
/// on the merged result before serving lookups and MUST NOT serve a set for
/// which it returns [ContentSetInvalid] (FR-140).
ContentSetValidation validateContentSet(Iterable<ContentSet> sets) {
  final problems = <ContentReferenceProblem>[];
  final entries = <ContentEntry>[];
  final targets = <ContentKey, ContentEntry>{};
  // Arrival order decides which entry of one key is the `duplicate`: the
  // later set's entry (FR-125). The first entry under a key is remembered,
  // and the report walk below re-checks by identity, so two equal entries
  // of one key are still one duplicate, on the later one — never a
  // hash-collision artefact.
  final firstByKey = <ContentKey, ContentEntry>{};
  for (final set in sets) {
    for (final entry in set.entries) {
      entries.add(entry);
      firstByKey.putIfAbsent(entry.key, () => entry);
      targets.putIfAbsent(entry.key, () => entry);
    }
  }

  // The report order is the owner kind's (FR-142 order), then the owner id,
  // then the order the entry lists its references (FR-127); a duplicate
  // problem sits before its entry's reference problems.
  final ordered = [...entries]..sort(_byOwner);
  for (final entry in ordered) {
    if (!identical(firstByKey[entry.key], entry)) {
      problems.add(
        ContentReferenceProblem(
          owner: entry.key,
          field: '',
          target: entry.key,
          kind: ContentProblemKind.duplicate,
        ),
      );
    }
    if (entry is! ContentReferences) continue;
    final ContentReferences owner = entry as ContentReferences;
    for (final reference in owner.references) {
      final target = targets[reference.target];
      if (target == null) {
        problems.add(
          ContentReferenceProblem(
            owner: entry.key,
            field: reference.field,
            target: reference.target,
            kind: ContentProblemKind.unresolvedReference,
          ),
        );
        continue;
      }
      final constraint = reference.constraint;
      if (constraint != null && !_satisfied(constraint, target)) {
        problems.add(
          ContentReferenceProblem(
            owner: entry.key,
            field: reference.field,
            target: reference.target,
            kind: ContentProblemKind.constraintViolation,
          ),
        );
      }
    }
  }

  if (problems.isEmpty) return ContentSetValid(ContentSet(entries));
  return ContentSetInvalid(problems);
}

int _byOwner(ContentEntry a, ContentEntry b) {
  final byKind = a.key.kind.index.compareTo(b.key.kind.index);
  if (byKind != 0) return byKind;
  return a.key.id.value.compareTo(b.key.id.value);
}

bool _satisfied(ReferenceConstraint constraint, ContentEntry target) =>
    switch (constraint) {
      TargetHasFeatCategory(:final category) =>
        target is HasFeatCategory &&
            (target as HasFeatCategory).featCategory == category,
    };
