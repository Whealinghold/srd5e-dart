import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import '../typed_ids.dart';
import 'spell.dart';
import 'spell_level.dart';

/// A class spell list derived from `Spell.classes` (FR-120).
///
/// Not stored on a class entry — membership is a fact of the spell, derived
/// by [classSpellList] (FR-120). For each [SpellLevel] 0 to 9 the list holds
/// the ids of the spells whose `classes` contain the class, ordered by id
/// string with ordinal comparison and unmodifiable (FR-121). A class no
/// spell lists — a non-caster, or a house class held by no loaded class
/// entry — yields empty groups; [classSpellList] never needs a
/// `ClassDefinition` (FR-121).
@immutable
final class ClassSpellList {
  const ClassSpellList._(this.classId, this._groups);

  /// The class the list is for.
  final ClassId classId;

  /// The ten groups, level 0 to 9, in level order; each unmodifiable.
  final List<List<SpellId>> _groups;

  /// The spells of [level], ordered by id string with ordinal comparison;
  /// unmodifiable (FR-120, FR-121).
  List<SpellId> idsAt(SpellLevel level) => _groups[level.level];

  @override
  bool operator ==(Object other) {
    if (other is! ClassSpellList || other.classId != classId) {
      return false;
    }
    for (var i = 0; i < _groups.length; i++) {
      if (!const ListEquality<SpellId>().equals(other._groups[i], _groups[i])) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode {
    var hash = Object.hash(ClassSpellList, classId);
    for (final group in _groups) {
      hash = Object.hash(hash, const ListEquality<SpellId>().hash(group));
    }
    return hash;
  }

  @override
  String toString() =>
      'ClassSpellList(${classId.id.value}, '
      '${_groups.map((g) => g.length).join('/')})';
}

/// Derives the spell list of [classId] from [spells] (FR-120).
///
/// The pure function never alters its input and never depends on a class
/// entry (FR-121): a spell names its classes, so the derivation works for a
/// host's house class exactly as for the SRD's eight. Within a group the ids
/// are ordered by string value with ordinal comparison, so the result is
/// deterministic and independent of the input's order (FR-121).
ClassSpellList classSpellList(ClassId classId, Iterable<Spell> spells) {
  final grouped = List.generate(
    SpellLevel.max + 1,
    (_) => <SpellId>[],
    growable: false,
  );
  for (final spell in spells) {
    if (spell.classes.contains(classId)) {
      grouped[spell.level.level].add(spell.id);
    }
  }
  final ordered = List<List<SpellId>>.generate(grouped.length, (level) {
    final ids = grouped[level]..sort(_ordinal);
    return List.unmodifiable(ids);
  }, growable: false);
  return ClassSpellList._(classId, List.unmodifiable(ordered));
}

int _ordinal(SpellId a, SpellId b) => a.id.value.compareTo(b.id.value);
