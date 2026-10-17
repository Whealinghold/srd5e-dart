import 'dart:convert' show jsonDecode;

import '../../shared_kernel/ability/ability.dart';
import '../../shared_kernel/ability/ability_score.dart';
import '../../shared_kernel/dice/dice_expression.dart';
import '../../shared_kernel/dice/die.dart';
import '../application/content_decode_result.dart';
import '../application/content_problem.dart';
import '../application/ports/content_set_decoder.dart';
import '../application/schema_version.dart';
import '../domain/background.dart';
import '../domain/background_feat_reference.dart';
import '../domain/choice_option.dart';
import '../domain/classes/ability_requirement.dart';
import '../domain/classes/armor_training_category.dart';
import '../domain/classes/class_column.dart';
import '../domain/classes/class_definition.dart';
import '../domain/classes/class_spellcasting_trait.dart';
import '../domain/classes/class_starting_equipment.dart';
import '../domain/classes/class_tool_proficiency.dart';
import '../domain/classes/column_value.dart';
import '../domain/classes/feature_entry.dart';
import '../domain/classes/feature_fact.dart';
import '../domain/classes/feature_option.dart';
import '../domain/classes/feature_table.dart';
import '../domain/classes/multiclass_grants.dart';
import '../domain/classes/progression_row.dart';
import '../domain/classes/skill_choice.dart';
import '../domain/classes/subclass_definition.dart';
import '../domain/classes/weapon_proficiency.dart';
import '../domain/content_entry.dart';
import '../domain/content_id.dart';
import '../domain/content_kind.dart';
import '../domain/content_problem_kind.dart';
import '../domain/content_set.dart';
import '../domain/content_text_block.dart';
import '../domain/creature_size.dart';
import '../domain/creature_type.dart';
import '../domain/damage_type.dart';
import '../domain/duration_unit.dart';
import '../domain/equipment/armor.dart';
import '../domain/equipment/armor_category.dart';
import '../domain/equipment/armor_class_rule.dart';
import '../domain/equipment/coin.dart';
import '../domain/equipment/cost.dart';
import '../domain/equipment/price.dart';
import '../domain/equipment/weapon.dart';
import '../domain/equipment/weapon_damage.dart';
import '../domain/equipment/weapon_property_use.dart';
import '../domain/equipment/weight_spec.dart';
import '../domain/equipment_options.dart';
import '../domain/feat.dart';
import '../domain/feat_benefit.dart';
import '../domain/feat_category.dart';
import '../domain/hit_point_die.dart';
import '../domain/level_benefit.dart';
import '../domain/mastery_property.dart';
import '../domain/named_text.dart';
import '../domain/prerequisite.dart';
import '../domain/skill.dart';
import '../domain/source_citation.dart';
import '../domain/species.dart';
import '../domain/species_choice.dart';
import '../domain/spells/spell.dart';
import '../domain/spells/spell_casting_time.dart';
import '../domain/spells/spell_components.dart';
import '../domain/spells/spell_duration.dart';
import '../domain/spells/spell_level.dart';
import '../domain/spells/spell_range.dart';
import '../domain/spells/spell_school.dart';
import '../domain/tool_proficiency.dart';
import '../domain/typed_ids.dart';
import '../domain/weapon_property.dart';

/// A decoder from the content JSON envelope (`doc/specs/
/// content-schema-and-decoder.md`, revision row R1) to a [ContentSet]
/// (FR-001).
///
/// One pass over the document reports **every** problem found, each as a
/// [ContentProblem] — a JSON Pointer path and a kind, no display text
/// (FR-012, FR-014) — and nothing is thrown for content (FR-018). The
/// decoder is a pure function of its input: no clock, randomness, I/O or
/// global state (FR-075), and the input is neither retained nor mutated
/// (FR-076).
///
/// Strict, never lenient (FR-021, FR-022, FR-025): a key not declared for
/// an object is `unknownField` at any depth, a closed-set string must match
/// the SRD spelling case sensitively, and a whole number beyond the
/// safe-integer range is rejected as data, so a result never depends on
/// platform integer width. Text reaches the decoded entry verbatim
/// (FR-029). The decoder resolves no reference (FR-035): every
/// cross-entry reference is the whole-set validation's. The one
/// cross-entry check of a single-document decode is the duplicate-id check
/// (FR-031), decided on the lookup set of FR-095 and reported after every
/// entry-level problem, grouped by kind (FR-016).
///
/// Shapes registered (their revision rows landed): `species`,
/// `backgrounds`, `feats` (content-species-backgrounds-feats.md),
/// `classes` (content-classes.md, with the R1-classes-ids uniqueness
/// groups of subclasses and features reported after the class-id
/// duplicates, FR-016) and `spells` (content-spells.md; the optional
/// `effects` key of FR-122 is read only when R2-spell-effects lands, so it
/// is `unknownField` until then), and `weapons`, `armor`
/// (content-equipment.md). Spell ids inside class features (R1-classes-
/// spell-sites) and every other cross-entry reference are the whole-set
/// validation's, never this decoder's (FR-035).
final class JsonContentSetDecoder implements ContentSetDecoder {
  /// Creates the decoder.
  const JsonContentSetDecoder();

  /// The largest whole number a declared integer field accepts (FR-021):
  /// 2^53 - 1, the safe-integer bound every platform agrees on.
  static const int maxSafeInteger = 9007199254740991;

  static const String _versionKey = 'schemaVersion';

  /// The registered root arrays, in revision-table order (FR-008); the row
  /// order orders problems (FR-016) and the duplicate groups within
  /// `equipment` (`weapons` before `armor`).
  static const List<_RegisteredArray> _registeredArrays = [
    _RegisteredArray('species', ContentKind.species),
    _RegisteredArray('backgrounds', ContentKind.background),
    _RegisteredArray('classes', ContentKind.characterClass),
    _RegisteredArray('feats', ContentKind.feat),
    _RegisteredArray('spells', ContentKind.spell),
    _RegisteredArray('weapons', ContentKind.equipment),
    _RegisteredArray('armor', ContentKind.equipment),
  ];

  static final Map<String, _RegisteredArray> _arrayByName = {
    for (final array in _registeredArrays) array.name: array,
  };

  @override
  ContentDecodeResult decode(String document) {
    final Object? parsed;
    try {
      parsed = jsonDecode(document);
    } on FormatException {
      return ContentDecodeFailed([
        const ContentProblem('', ContentProblemKind.syntax),
      ]);
    }
    if (parsed is! Map<String, Object?>) {
      // FR-003: a root value that is not an object, without examining it.
      return ContentDecodeFailed([
        const ContentProblem('', ContentProblemKind.wrongType),
      ]);
    }

    // `schemaVersion`: a problem there stops the decode (FR-004 to FR-006).
    if (!parsed.containsKey(_versionKey)) {
      return ContentDecodeFailed([
        const ContentProblem('/$_versionKey', ContentProblemKind.missingField),
      ]);
    }
    final versionProblem = _versionProblem(parsed[_versionKey]);
    if (versionProblem != null) {
      return ContentDecodeFailed([
        ContentProblem('/$_versionKey', versionProblem),
      ]);
    }

    // Each kind's entries, independently, collecting every problem (FR-012).
    final problems = <ContentProblem>[];
    final construction = <ContentEntry>[];
    final lookup = <ContentKind, List<_PositionedId>>{};
    // The two extra id spaces of the `classes` array (content-classes.md
    // FR-004): subclass ids across all classes and feature ids across all
    // class and subclass features, kept in document order.
    final subclassIds = <_NestedId>[];
    final featureIds = <_NestedId>[];
    for (var row = 0; row < _registeredArrays.length; row++) {
      final array = _registeredArrays[row];
      if (!parsed.containsKey(array.name)) continue;
      final value = parsed[array.name];
      if (value is! List<Object?>) {
        // FR-011: a root array whose value is not an array, at the field,
        // without examining its children.
        problems.add(
          ContentProblem('/${array.name}', ContentProblemKind.wrongType),
        );
        continue;
      }
      for (var index = 0; index < value.length; index++) {
        final element = value[index];
        final base = '/${array.name}/$index';
        if (element is! Map<String, Object?>) {
          // FR-011: a non-object element, at its index, without examining
          // its children.
          problems.add(ContentProblem(base, ContentProblemKind.wrongType));
          continue;
        }
        final elementProblems = <ContentProblem>[];
        final decoded = _decodeEntry(
          array,
          _Element(elementProblems, base, element),
        );
        final id = decoded.id;
        if (id != null) {
          // The lookup set holds every entry whose own id is valid, even
          // with other problems (FR-095).
          lookup
              .putIfAbsent(array.kind, () => [])
              .add(
                _PositionedId(
                  row: row,
                  index: index,
                  arrayName: array.name,
                  id: id,
                ),
              );
        }
        for (final nested in decoded.subclassIds) {
          subclassIds.add(nested.underClass(base));
        }
        for (final nested in decoded.featureIds) {
          featureIds.add(nested.underClass(base));
        }
        problems.addAll(elementProblems);
        final entry = decoded.entry;
        if (entry != null) construction.add(entry);
      }
    }

    // Unknown root keys, after every known root field, in ordinal order
    // (FR-010, FR-016).
    final unknownRoot =
        parsed.keys
            .where(
              (key) => key != _versionKey && !_arrayByName.containsKey(key),
            )
            .toList()
          ..sort();
    for (final key in unknownRoot) {
      problems.add(
        ContentProblem(
          '/${escapePointer(key)}',
          ContentProblemKind.unknownField,
        ),
      );
    }

    // Duplicate ids over the lookup set (FR-031, FR-098), grouped by kind
    // in FR-142 declaration order, within a group by ascending position of
    // the later entry (FR-016).
    for (final kind in ContentKind.values) {
      final ids = lookup[kind];
      if (ids != null) {
        ids.sort(
          (a, b) => a.row != b.row
              ? a.row.compareTo(b.row)
              : a.index.compareTo(b.index),
        );
        final seen = <ContentId>{};
        for (final positioned in ids) {
          if (seen.add(positioned.id)) continue;
          problems.add(
            ContentProblem(
              '/${positioned.arrayName}/${positioned.index}/id',
              ContentProblemKind.duplicate,
            ),
          );
        }
      }
      if (kind == ContentKind.characterClass) {
        // The R1-classes-ids groups, after the class-id duplicates
        // (content-classes.md FR-004, schema FR-016): subclass ids across
        // all classes, then feature ids across all class and subclass
        // features. Both lists are in document order already, so the later
        // occurrence of an id is the reported one (FR-098).
        _reportNestedDuplicates(subclassIds, problems);
        _reportNestedDuplicates(featureIds, problems);
      }
    }

    // With no problems at all, the set is built from the construction set
    // (FR-095).
    if (problems.isEmpty) return ContentDecoded(ContentSet(construction));
    return ContentDecodeFailed(problems);
  }

  /// The kind of problem `schemaVersion` carries (FR-005, FR-006, FR-021):
  /// null for a supported whole safe-range number; `wrongType` for anything
  /// not whole or not a number; `unsupportedVersion` for an unsupported
  /// version and for a whole number outside the safe range.
  static ContentProblemKind? _versionProblem(Object? value) {
    final whole = _wholeNumber(value);
    if (whole == null) return ContentProblemKind.wrongType;
    if (whole.outOfSafeRange) return ContentProblemKind.unsupportedVersion;
    if (!supportedSchemaVersions.contains(whole.value)) {
      return ContentProblemKind.unsupportedVersion;
    }
    return null;
  }
}

/// One registered root array: its key in the document and the
/// [ContentKind] its entries decode to (FR-008).
final class _RegisteredArray {
  const _RegisteredArray(this.name, this.kind);

  final String name;
  final ContentKind kind;
}

/// An entry whose own id is valid, with its position in the document: the
/// root array's revision row, then the element index. The position decides
/// which entry of one kind is the `duplicate` (FR-098) and orders the
/// duplicate groups (FR-016).
final class _PositionedId {
  const _PositionedId({
    required this.row,
    required this.index,
    required this.arrayName,
    required this.id,
  });

  final int row;
  final int index;
  final String arrayName;
  final ContentId id;
}

/// A subclass or feature id of one class element, with the element's
/// indexes inside the class and its path relative to the class element
/// (content-classes.md FR-004). Only ids valid per FR-030 are collected
/// (FR-095); the [path] is completed with the class element's base when the
/// class is registered.
final class _NestedId {
  const _NestedId({
    required this.subclassIndex,
    required this.featureIndex,
    required this.id,
    required this.path,
  });

  /// The subclass's index inside the class, or null for a class feature.
  final int? subclassIndex;

  /// The feature's index inside its feature list.
  final int featureIndex;

  final ContentId id;

  /// The path relative to the class element, e.g.
  /// `subclasses/0/features/1/id`.
  final String path;

  /// The same id, with its path completed under the class element at
  /// [classBase] (`/classes/<index>`).
  _NestedId underClass(String classBase) => _NestedId(
    subclassIndex: subclassIndex,
    featureIndex: featureIndex,
    id: id,
    path: '$classBase/$path',
  );
}

/// Reports one `duplicate` per later occurrence of an id in a
/// document-ordered id list, at the later entry's own path
/// (content-classes.md FR-004, FR-098).
void _reportNestedDuplicates(
  List<_NestedId> ids,
  List<ContentProblem> problems,
) {
  final seen = <ContentId>{};
  for (final nested in ids) {
    if (seen.add(nested.id)) continue;
    problems.add(ContentProblem(nested.path, ContentProblemKind.duplicate));
  }
}

/// The outcome of one entry object's decode: the validated [id] — non-null
/// when the `id` field passed FR-030, whether or not the rest did (FR-095)
/// — and the constructed [entry], non-null only when the element produced
/// no problem at all and its kind's shape has landed (the construction set,
/// FR-095). A class element also carries the valid subclass and feature ids
/// of its document-wide uniqueness groups (content-classes.md FR-004).
final class _DecodedEntry {
  const _DecodedEntry(
    this.id,
    this.entry, {
    this.subclassIds = const [],
    this.featureIds = const [],
  });

  final ContentId? id;
  final ContentEntry? entry;

  /// The valid subclass ids of one class element, in document order.
  final List<_NestedId> subclassIds;

  /// The valid feature ids of one class element — class features before
  /// subclass features — in document order.
  final List<_NestedId> featureIds;
}

/// The readers of one JSON object: an entry element, or an object nested
/// inside one.
///
/// Problems are appended to the shared [problems] list, so a nested
/// object's failures also keep the whole entry element out of the
/// construction set. Every reader that fails appends exactly one problem
/// and returns null. Nested decodes record the problem count at their
/// start with [mark] and compare with [isClean] afterwards, so a nested
/// object's own validity is not contaminated by an earlier field's
/// problems.
final class _Element {
  _Element(this.problems, this.base, this.map);

  /// The problems of the entry element this object belongs to.
  final List<ContentProblem> problems;

  /// The JSON Pointer of this object, e.g. `/species/0` or
  /// `/species/0/source`.
  final String base;

  /// The object's keys and values.
  final Map<String, Object?> map;

  final Set<String> _read = {};

  /// The problem count at the start of a nested decode.
  int markStart() => problems.length;

  /// Whether no problem was appended since [mark] was taken.
  bool isClean(int mark) => problems.length == mark;

  /// Whether [key] is present in the object, even as an explicit `null`.
  bool has(String key) => map.containsKey(key);

  /// Marks [key] declared without reading it: the key is known, so [close]
  /// never reports it as `unknownField`.
  void mark(String key) => _read.add(key);

  /// Reports every key never read as `unknownField`, in ordinal order,
  /// after the declared fields (FR-022, FR-016).
  void close() {
    final unknown = map.keys.where((key) => !_read.contains(key)).toList()
      ..sort();
    for (final key in unknown) {
      problems.add(
        ContentProblem(
          '$base/${escapePointer(key)}',
          ContentProblemKind.unknownField,
        ),
      );
    }
  }

  /// The value of a required field: absent is `missingField` (FR-019); an
  /// explicit `null` falls through to the reader's type check and is
  /// `wrongType` there (FR-020).
  Object? _required(String key) {
    mark(key);
    final value = map[key];
    if (value == null && !map.containsKey(key)) {
      problems.add(
        ContentProblem('$base/$key', ContentProblemKind.missingField),
      );
      return null;
    }
    return value;
  }

  /// A required string.
  String? string(String key) {
    final value = _required(key);
    if (value == null && !map.containsKey(key)) return null;
    return _string(key, value);
  }

  String? _string(String key, Object? value) {
    if (value is! String) {
      problems.add(ContentProblem('$base/$key', ContentProblemKind.wrongType));
      return null;
    }
    return value;
  }

  /// An optional string: absence expresses optionality, never `null`
  /// (FR-020).
  String? optionalString(String key) {
    mark(key);
    if (!has(key)) return null;
    return _string(key, map[key]);
  }

  /// A required `name` (FR-027): non-empty, no leading or trailing
  /// whitespace; otherwise `invalidValue`.
  String? name(String key) {
    final value = string(key);
    if (value == null) return null;
    if (!NamedText.isValidName(value)) {
      return _invalid(key);
    }
    return value;
  }

  /// A required non-blank `text` (FR-028); otherwise `invalidValue`.
  String? text(String key) {
    final value = string(key);
    if (value == null) return null;
    if (!NamedText.isValidText(value)) {
      return _invalid(key);
    }
    return value;
  }

  /// An optional non-blank `text` (FR-028).
  String? optionalText(String key) {
    final value = optionalString(key);
    if (value == null) return null;
    if (!NamedText.isValidText(value)) {
      return _invalid(key);
    }
    return value;
  }

  /// A required `id` (FR-030): a [ContentId], or `invalidValue`.
  ContentId? id(String key) {
    final value = string(key);
    if (value == null) return null;
    final parsed = ContentId.tryCreate(value);
    if (parsed is! ContentIdParsed) {
      return _invalid(key);
    }
    return parsed.id;
  }

  /// A required closed-set string (FR-025): exact, case sensitive, SRD
  /// spelling; anything else `invalidValue`.
  E? enumValue<E>(String key, E? Function(String value) parse) {
    final value = string(key);
    if (value == null) return null;
    final member = parse(value);
    if (member == null) return _invalid(key);
    return member;
  }

  /// A required boolean.
  bool? boolean(String key) {
    final value = _required(key);
    if (value == null && !map.containsKey(key)) return null;
    if (value is! bool) {
      problems.add(ContentProblem('$base/$key', ContentProblemKind.wrongType));
      return null;
    }
    return value;
  }

  /// A required whole number in `[min, max]`; a null `max` means no upper
  /// bound (FR-021, FR-023): not whole or not a number `wrongType`, outside
  /// the safe-integer range or outside `[min, max]` `outOfRange`.
  int? wholeInt(String key, {required int min, int? max}) {
    final value = _required(key);
    if (value == null && !map.containsKey(key)) return null;
    final whole = _wholeNumber(value);
    if (whole == null) {
      problems.add(ContentProblem('$base/$key', ContentProblemKind.wrongType));
      return null;
    }
    if (whole.outOfSafeRange) {
      problems.add(ContentProblem('$base/$key', ContentProblemKind.outOfRange));
      return null;
    }
    final number = whole.value;
    if (number < min || (max != null && number > max)) {
      problems.add(ContentProblem('$base/$key', ContentProblemKind.outOfRange));
      return null;
    }
    return number;
  }

  /// An optional whole number in `[min, max]`.
  int? optionalWholeInt(String key, {required int min, required int max}) {
    mark(key);
    if (!has(key)) return null;
    return wholeInt(key, min: min, max: max);
  }

  /// A required number of pounds, at least [Weight.minPounds] (FR-080).
  double? pounds(String key) {
    final value = _required(key);
    if (value == null && !map.containsKey(key)) return null;
    if (value is! num) {
      problems.add(ContentProblem('$base/$key', ContentProblemKind.wrongType));
      return null;
    }
    if (!Weight.isValidPounds(value)) {
      problems.add(ContentProblem('$base/$key', ContentProblemKind.outOfRange));
      return null;
    }
    return value.toDouble();
  }

  /// An optional number of pounds.
  double? optionalPounds(String key) {
    mark(key);
    if (!has(key)) return null;
    return pounds(key);
  }

  /// A required object, read through a child [_Element] at its path
  /// (FR-013: a wrong-typed value yields one problem, no cascade).
  _Element? object(String key) {
    final value = _required(key);
    if (value == null && !map.containsKey(key)) return null;
    if (value is! Map<String, Object?>) {
      problems.add(ContentProblem('$base/$key', ContentProblemKind.wrongType));
      return null;
    }
    return _Element(problems, '$base/$key', value);
  }

  /// An optional object: absence expresses optionality, never `null`
  /// (FR-020).
  _Element? optionalObject(String key) {
    mark(key);
    if (!has(key)) return null;
    final value = map[key];
    if (value is! Map<String, Object?>) {
      problems.add(ContentProblem('$base/$key', ContentProblemKind.wrongType));
      return null;
    }
    return _Element(problems, '$base/$key', value);
  }

  /// A required array (FR-013: a wrong-typed value yields one problem).
  List<Object?>? array(String key) {
    final value = _required(key);
    if (value == null && !map.containsKey(key)) return null;
    if (value is! List<Object?>) {
      problems.add(ContentProblem('$base/$key', ContentProblemKind.wrongType));
      return null;
    }
    return value;
  }

  /// An optional array.
  List<Object?>? optionalArray(String key) {
    mark(key);
    if (!has(key)) return null;
    return array(key);
  }

  /// The optional `source` object of an entry (FR-034): {document, section,
  /// page}, all required, document and section non-blank, page at least
  /// [SourceCitation.minPage].
  SourceCitation? source() {
    mark('source');
    if (!has('source')) return null;
    final value = map['source'];
    if (value is! Map<String, Object?>) {
      problems.add(
        ContentProblem('$base/source', ContentProblemKind.wrongType),
      );
      return null;
    }
    final sub = _Element(problems, '$base/source', value);
    final document = sub.text('document');
    final section = sub.text('section');
    final page = sub.wholeInt('page', min: SourceCitation.minPage);
    sub.close();
    if (document == null || section == null || page == null) return null;
    return SourceCitation(document: document, section: section, page: page);
  }

  /// An element object of the array held at [key], as a child [_Element],
  /// or null after reporting `wrongType` at the element's index, without
  /// examining its children (FR-011).
  _Element? elementObject(String key, List<Object?> list, int index) {
    final value = list[index];
    if (value is! Map<String, Object?>) {
      problems.add(
        ContentProblem('$base/$key/$index', ContentProblemKind.wrongType),
      );
      return null;
    }
    return _Element(problems, '$base/$key/$index', value);
  }

  /// Reports `invalidValue` at [key] and returns null; the element decode
  /// continues with the sibling fields, so every problem is reported
  /// (FR-012).
  E? _invalid<E>(String key) {
    problems.add(ContentProblem('$base/$key', ContentProblemKind.invalidValue));
    return null;
  }
}

/// Escapes [key] as a JSON Pointer token: `~` as `~0`, then `/` as `~1`
/// (FR-014).
String escapePointer(String key) =>
    key.replaceAll('~', '~0').replaceAll('/', '~1');

/// A whole-number reading of a JSON value (FR-021): null when the value is
/// not a finite JSON number or is not whole; [outOfSafeRange] when its
/// magnitude exceeds 2^53 - 1, so the result never depends on platform
/// integer width.
final class _WholeNumber {
  const _WholeNumber(this.value, this.outOfSafeRange);

  final int value;
  final bool outOfSafeRange;
}

_WholeNumber? _wholeNumber(Object? value) {
  if (value is int) {
    final out =
        value > JsonContentSetDecoder.maxSafeInteger ||
        value < -JsonContentSetDecoder.maxSafeInteger;
    return _WholeNumber(out ? 0 : value, out);
  }
  if (value is! double || !value.isFinite) return null;
  if (value != value.truncateToDouble()) return null;
  final magnitude = value.abs();
  if (magnitude > JsonContentSetDecoder.maxSafeInteger ||
      magnitude >= 9223372036854775808.0) {
    return const _WholeNumber(0, true);
  }
  return _WholeNumber(value.toInt(), false);
}

// ---------------------------------------------------------------------------
// Entry shapes
// ---------------------------------------------------------------------------

/// Decodes one element of the registered [array] (FR-008).
_DecodedEntry _decodeEntry(_RegisteredArray array, _Element el) {
  return switch (array.kind) {
    ContentKind.species => _species(el),
    ContentKind.background => _background(el),
    ContentKind.characterClass => _class(el),
    ContentKind.feat => _feat(el),
    ContentKind.equipment when array.name == 'weapons' => _weapon(el),
    ContentKind.equipment => _armor(el),
    ContentKind.spell => _spell(el),
    // The kinds whose root arrays no revision row registers (magic items,
    // monsters, the toolbox catalogue) never occur in a registered array;
    // if one ever did, the envelope entry header is all it gets (FR-008).
    _ => _headerOnly(el),
  };
}

/// The envelope entry header every kind starts with: `id`, `name`,
/// `source?`.
_DecodedEntry _headerOnly(_Element el) {
  final id = el.id('id');
  el.name('name');
  el.source();
  el.close();
  return _DecodedEntry(id, null);
}

/// The duplicate problems of values that must be distinct (FR-026): one per
/// later occurrence, at its own index under [pathOf]. [values] is aligned
/// to the raw element indices, with null for an element that did not
/// decode, so a failing element never shifts the reported index; only
/// decoded values take part.
void _reportDuplicates<T>(
  List<ContentProblem> problems,
  String pathOf,
  List<T?> values, {
  String suffix = '',
}) {
  for (var k = 1; k < values.length; k++) {
    final value = values[k];
    if (value == null) continue;
    if (values.indexOf(value) != k) {
      problems.add(
        ContentProblem('$pathOf/$k$suffix', ContentProblemKind.duplicate),
      );
    }
  }
}

/// The printed spelling of each ability; the translation of the kernel
/// enum, which carries no wire form, is the decoder's (anti-corruption,
/// architecture.md §5).
Ability? _abilityFromJson(String value) => switch (value) {
  'Strength' => Ability.strength,
  'Dexterity' => Ability.dexterity,
  'Constitution' => Ability.constitution,
  'Intelligence' => Ability.intelligence,
  'Wisdom' => Ability.wisdom,
  'Charisma' => Ability.charisma,
  _ => null,
};

/// An exact-length array of distinct closed-set strings (FR-024, FR-025,
/// FR-026): the length is checked first, with no element problems then; a
/// non-string is `wrongType` and a non-member `invalidValue` at the
/// element's index; a repeat `duplicate` at the later index.
List<T>? _exactMemberList<T>(
  _Element el,
  String key, {
  required int length,
  required T? Function(String value) parse,
}) {
  final list = el.array(key);
  if (list == null) return null;
  if (list.length != length) {
    el.problems.add(
      ContentProblem('${el.base}/$key', ContentProblemKind.outOfRange),
    );
    return null;
  }
  final values = List<T?>.filled(list.length, null);
  for (var k = 0; k < list.length; k++) {
    final value = list[k];
    if (value is! String) {
      el.problems.add(
        ContentProblem('${el.base}/$key/$k', ContentProblemKind.wrongType),
      );
      continue;
    }
    values[k] = parse(value);
    if (values[k] == null) {
      el.problems.add(
        ContentProblem('${el.base}/$key/$k', ContentProblemKind.invalidValue),
      );
    }
  }
  _reportDuplicates(el.problems, '${el.base}/$key', values);
  if (el.problems.isNotEmpty) return null;
  return [for (final value in values) value!];
}

// -- species ---------------------------------------------------------------

/// A species (content-species-backgrounds-feats.md §5; FR-010 to FR-017,
/// FR-060, FR-061, SX-1, SX-3).
_DecodedEntry _species(_Element el) {
  final id = el.id('id');
  final name = el.name('name');
  final source = el.source();
  final creatureType = el.enumValue('creatureType', CreatureType.fromJson);
  final sizes = _sizes(el);
  final sizeText = el.optionalText('sizeText');
  final speed = el.wholeInt('speed', min: Species.minSpeed);
  final traitNames = _traitNames(el);
  final traits = _traits(el);
  final choices = _choices(el, traitNames);
  el.close();
  if (el.problems.isNotEmpty) return _DecodedEntry(id, null);
  return _DecodedEntry(
    id,
    Species(
      id: SpeciesId.of(id!),
      name: name!,
      source: source,
      creatureType: creatureType!,
      sizes: sizes!,
      sizeText: sizeText,
      speed: speed!,
      traits: traits!,
      choices: choices ?? const [],
    ),
  );
}

/// The species' `sizes`: one or two distinct player-character sizes
/// (FR-012). A wrong length is `outOfRange` at the array, with no element
/// problems then; a non-string is `wrongType`, a non-member or a size a
/// species may not be `invalidValue` at the element's index; a repeat
/// `duplicate` at the later index.
List<CreatureSize>? _sizes(_Element el) {
  final list = el.array('sizes');
  if (list == null) return null;
  if (list.length < Species.minSizes || list.length > Species.maxSizes) {
    el.problems.add(
      ContentProblem('${el.base}/sizes', ContentProblemKind.outOfRange),
    );
    return null;
  }
  final sizes = List<CreatureSize?>.filled(list.length, null);
  for (var k = 0; k < list.length; k++) {
    final value = list[k];
    if (value is! String) {
      el.problems.add(
        ContentProblem('${el.base}/sizes/$k', ContentProblemKind.wrongType),
      );
      continue;
    }
    final size = CreatureSize.fromJson(value);
    if (size == null || !Species.isPlayerCharacterSize(size)) {
      el.problems.add(
        ContentProblem('${el.base}/sizes/$k', ContentProblemKind.invalidValue),
      );
      continue;
    }
    sizes[k] = size;
  }
  _reportDuplicates(el.problems, '${el.base}/sizes', sizes);
  if (el.problems.isNotEmpty) return null;
  return [for (final size in sizes) ?size];
}

/// The raw trait names of a species element, for the FR-060 membership
/// check; read from the raw JSON so the check works even when other fields
/// failed.
Set<String> _traitNames(_Element el) {
  final traits = el.map['traits'];
  if (traits is! List<Object?>) return const {};
  return {
    for (final trait in traits)
      if (trait is Map<String, Object?> && trait['name'] is String)
        trait['name'] as String,
  };
}

/// The species' `traits`: a non-empty list of {name, text} with unique
/// names (FR-014).
List<NamedText>? _traits(_Element el) {
  final list = el.array('traits');
  if (list == null) return null;
  if (list.isEmpty) {
    el.problems.add(
      ContentProblem('${el.base}/traits', ContentProblemKind.outOfRange),
    );
    return null;
  }
  final names = List<String?>.filled(list.length, null);
  final texts = List<String?>.filled(list.length, null);
  for (var k = 0; k < list.length; k++) {
    final sub = el.elementObject('traits', list, k);
    if (sub == null) continue;
    names[k] = sub.name('name');
    texts[k] = sub.text('text');
    sub.close();
  }
  _reportDuplicates(el.problems, '${el.base}/traits', names);
  if (el.problems.isNotEmpty) return null;
  return [
    for (var k = 0; k < list.length; k++) NamedText(names[k]!, texts[k]!),
  ];
}

/// The species' optional `choices` (SX-1): {traitName, options} elements
/// whose options all share one variant of the sealed [ChoiceOption] family
/// (FR-016); `traitName` must name a trait of the same species (FR-060).
List<SpeciesChoice>? _choices(_Element el, Set<String> traitNames) {
  final list = el.optionalArray('choices');
  if (list == null) return const [];
  final choices = List<SpeciesChoice?>.filled(list.length, null);
  for (var j = 0; j < list.length; j++) {
    final sub = el.elementObject('choices', list, j);
    if (sub == null) continue;
    final mark = sub.markStart();
    final traitName = sub.name('traitName');
    if (traitName != null && !traitNames.contains(traitName)) {
      sub.problems.add(
        ContentProblem(
          '${sub.base}/traitName',
          ContentProblemKind.constraintViolation,
        ),
      );
    }
    final options = _options(sub);
    sub.close();
    if (sub.isClean(mark) && traitName != null && options != null) {
      choices[j] = SpeciesChoice(traitName, options);
    }
  }
  if (el.problems.isNotEmpty) return null;
  return [for (final choice in choices) choice!];
}

/// One choice's `options`: a non-empty list (FR-016) of {kind, name, …}
/// objects, every option of the same variant; a differing variant is
/// `constraintViolation` at the later option's `kind` and a repeated option
/// name `duplicate` at the later option (FR-016).
List<ChoiceOption>? _options(_Element sub) {
  final list = sub.array('options');
  if (list == null) return null;
  if (list.length < SpeciesChoice.minOptions) {
    sub.problems.add(
      ContentProblem('${sub.base}/options', ContentProblemKind.outOfRange),
    );
    return null;
  }
  final mark = sub.markStart();
  String? variant;
  final options = List<ChoiceOption?>.filled(list.length, null);
  final names = List<String?>.filled(list.length, null);
  for (var k = 0; k < list.length; k++) {
    final option = sub.elementObject('options', list, k);
    if (option == null) continue;
    final optionMark = option.markStart();
    final kind = option.string('kind');
    if (kind == null) {
      // The variant is unknowable; every variant field is declared.
      for (final key in const [
        'name',
        'damageType',
        'levelBenefits',
        'text',
        'spellIds',
      ]) {
        option.mark(key);
      }
      option.close();
      continue;
    }
    names[k] = option.name('name');
    if (variant == null) {
      variant = kind;
    } else if (kind != variant) {
      sub.problems.add(
        ContentProblem(
          '${sub.base}/options/$k/kind',
          ContentProblemKind.constraintViolation,
        ),
      );
    }
    final decoded = switch (kind) {
      'damageType' => _damageTypeOption(option),
      'lineage' => _lineageOption(option),
      'text' => _textOption(option),
      _ => _unknownOptionKind(option),
    };
    if (decoded != null && option.isClean(optionMark)) options[k] = decoded;
  }
  _reportDuplicates(sub.problems, '${sub.base}/options', names);
  if (sub.problems.length != mark) return null;
  return [for (final option in options) ?option];
}

ChoiceOption? _damageTypeOption(_Element option) {
  final mark = option.markStart();
  final name = option.name('name');
  final damageType = option.enumValue('damageType', DamageType.fromJson);
  option.close();
  if (!option.isClean(mark) || name == null || damageType == null) return null;
  return DamageTypeOption(name, damageType);
}

ChoiceOption? _lineageOption(_Element option) {
  final mark = option.markStart();
  final name = option.name('name');
  final benefits = _levelBenefits(option);
  option.close();
  if (!option.isClean(mark) || name == null || benefits == null) return null;
  return LineageOption(name, benefits);
}

ChoiceOption? _textOption(_Element option) {
  final mark = option.markStart();
  final name = option.name('name');
  final text = option.text('text');
  final spellIds = _spellIds(option);
  option.close();
  if (!option.isClean(mark) || name == null || text == null) return null;
  return TextOption(name, text, spellIds: spellIds);
}

ChoiceOption? _unknownOptionKind(_Element option) {
  option.problems.add(
    ContentProblem('${option.base}/kind', ContentProblemKind.invalidValue),
  );
  // The variant is unknowable, so every variant field is declared: mark
  // them and report nothing but the kind.
  for (final key in const [
    'name',
    'damageType',
    'levelBenefits',
    'text',
    'spellIds',
  ]) {
    option.mark(key);
  }
  option.close();
  return null;
}

/// A lineage option's `levelBenefits`: exactly three entries at the levels
/// 1, 3 and 5, in that order (FR-061). A wrong length is `outOfRange` at
/// the array, with no element problems then; a level outside the three is
/// `invalidValue`; a repeated level `duplicate` at the later element's
/// `level`; distinct valid levels in another order `constraintViolation` at
/// the array.
List<LevelBenefit>? _levelBenefits(_Element option) {
  final list = option.array('levelBenefits');
  if (list == null) return null;
  if (list.length != LineageOption.requiredLevelBenefitCount) {
    option.problems.add(
      ContentProblem(
        '${option.base}/levelBenefits',
        ContentProblemKind.outOfRange,
      ),
    );
    return null;
  }
  final mark = option.markStart();
  final benefits = List<LevelBenefit?>.filled(list.length, null);
  final levels = List<int?>.filled(list.length, null);
  for (var m = 0; m < list.length; m++) {
    final sub = option.elementObject('levelBenefits', list, m);
    if (sub == null) continue;
    final level = sub.wholeInt('level', min: 1);
    if (level != null && !LevelBenefit.isValidLevel(level)) {
      sub.problems.add(
        ContentProblem('${sub.base}/level', ContentProblemKind.invalidValue),
      );
    } else {
      levels[m] = level;
    }
    final text = sub.text('text');
    final spellId = sub.id('spellId');
    sub.close();
    if (sub.isClean(mark) &&
        level != null &&
        LevelBenefit.isValidLevel(level) &&
        text != null &&
        spellId != null) {
      benefits[m] = LevelBenefit(level, text, SpellId.of(spellId));
    }
  }
  _reportDuplicates(
    option.problems,
    '${option.base}/levelBenefits',
    levels,
    suffix: '/level',
  );
  // Distinct valid levels in another order (FR-061); a repeat is already
  // reported as a duplicate.
  final valid = [for (final level in levels) ?level];
  final distinct = valid.toSet().length == valid.length;
  if (distinct && valid.length == list.length) {
    var inOrder = true;
    for (var m = 0; m < valid.length; m++) {
      if (valid[m] != LevelBenefit.lineageLevels[m]) inOrder = false;
    }
    if (!inOrder) {
      option.problems.add(
        ContentProblem(
          '${option.base}/levelBenefits',
          ContentProblemKind.constraintViolation,
        ),
      );
    }
  }
  if (option.problems.length != mark) return null;
  return [for (final benefit in benefits) ?benefit];
}

/// The optional `spellIds` of a text option: id strings decoding to
/// [SpellId]s (SX-1). Problems are appended; the caller's mark decides.
List<SpellId> _spellIds(_Element option) {
  final list = option.optionalArray('spellIds');
  if (list == null) return const [];
  final ids = <SpellId>[];
  for (var n = 0; n < list.length; n++) {
    final value = list[n];
    if (value is! String) {
      option.problems.add(
        ContentProblem(
          '${option.base}/spellIds/$n',
          ContentProblemKind.wrongType,
        ),
      );
      continue;
    }
    final parsed = ContentId.tryCreate(value);
    if (parsed is ContentIdParsed) {
      ids.add(SpellId.of(parsed.id));
    } else {
      option.problems.add(
        ContentProblem(
          '${option.base}/spellIds/$n',
          ContentProblemKind.invalidValue,
        ),
      );
    }
  }
  return ids;
}

// -- background ------------------------------------------------------------

/// A background (content-species-backgrounds-feats.md §5; FR-024 to
/// FR-030).
_DecodedEntry _background(_Element el) {
  final id = el.id('id');
  final name = el.name('name');
  final source = el.source();
  final abilityScores = _exactMemberList<Ability>(
    el,
    'abilityScores',
    length: Background.requiredAbilityScores,
    parse: _abilityFromJson,
  );
  final feat = _featReference(el);
  final skills = _exactMemberList<Skill>(
    el,
    'skillProficiencies',
    length: Background.requiredSkillProficiencies,
    parse: Skill.fromJson,
  );
  final toolProficiency = _toolProficiency(el);
  final equipmentOptions = _equipmentOptions(el);
  el.close();
  if (el.problems.isNotEmpty ||
      id == null ||
      name == null ||
      abilityScores == null ||
      feat == null ||
      skills == null ||
      toolProficiency == null ||
      equipmentOptions == null) {
    return _DecodedEntry(id, null);
  }
  return _DecodedEntry(
    id,
    Background(
      id: BackgroundId.of(id),
      name: name,
      source: source,
      abilityScores: abilityScores,
      feat: feat,
      skillProficiencies: skills,
      toolProficiency: toolProficiency,
      equipmentOptions: equipmentOptions,
    ),
  );
}

/// A background's `feat`: {featId, choice?} (FR-026). The Origin rule is
/// the whole-set validation's, never the decoder's (FR-035).
BackgroundFeatReference? _featReference(_Element el) {
  final sub = el.object('feat');
  if (sub == null) return null;
  final mark = sub.markStart();
  final featId = sub.id('featId');
  final choice = sub.optionalText('choice');
  sub.close();
  if (!sub.isClean(mark) || featId == null) return null;
  return BackgroundFeatReference(FeatId.of(featId), choice);
}

/// A background's `toolProficiency` (FR-119): {kind: "specific", name} or
/// {kind: "choice", category}; another kind is `invalidValue` at the kind.
ToolProficiency? _toolProficiency(_Element el) {
  final sub = el.object('toolProficiency');
  if (sub == null) return null;
  final mark = sub.markStart();
  final kind = sub.string('kind');
  final tool = switch (kind) {
    'specific' => _specificTool(sub),
    'choice' => _choiceTool(sub),
    null => null,
    _ => _unknownToolKind(sub),
  };
  if (!sub.isClean(mark) || tool == null) return null;
  return tool;
}

ToolProficiency? _specificTool(_Element sub) {
  final mark = sub.markStart();
  final name = sub.name('name');
  sub.close();
  if (!sub.isClean(mark) || name == null) return null;
  return SpecificToolProficiency(name);
}

ToolProficiency? _choiceTool(_Element sub) {
  final mark = sub.markStart();
  final category = sub.string('category');
  if (category != null && category.trim().isEmpty) {
    sub.problems.add(
      ContentProblem('${sub.base}/category', ContentProblemKind.invalidValue),
    );
  }
  sub.close();
  if (!sub.isClean(mark) || category == null) return null;
  return ChoiceToolProficiency(category);
}

ToolProficiency? _unknownToolKind(_Element sub) {
  sub.problems.add(
    ContentProblem('${sub.base}/kind', ContentProblemKind.invalidValue),
  );
  // Both variant fields are declared; report nothing but the kind.
  sub.mark('name');
  sub.mark('category');
  sub.close();
  return null;
}

/// A background's `equipmentOptions` (FR-029): exactly the keys `A` and
/// `B`, each {items, gold}; an item is {name, quantity} with a quantity of
/// at least [EquipmentItem.minQuantity] (FR-030).
EquipmentOptions? _equipmentOptions(_Element el) {
  final sub = el.object('equipmentOptions');
  if (sub == null) return null;
  final mark = sub.markStart();
  final a = _equipmentOption(sub, 'A');
  final b = _equipmentOption(sub, 'B');
  sub.close();
  if (!sub.isClean(mark) || a == null || b == null) return null;
  return EquipmentOptions(a: a, b: b);
}

EquipmentOption? _equipmentOption(_Element sub, String key) {
  final option = sub.object(key);
  if (option == null) return null;
  final mark = option.markStart();
  final items = _items(option);
  final gold = option.wholeInt('gold', min: EquipmentOption.minGold);
  option.close();
  if (!option.isClean(mark) || items == null || gold == null) return null;
  return EquipmentOption(items, gold);
}

List<EquipmentItem>? _items(_Element option) {
  final list = option.array('items');
  if (list == null) return null;
  final mark = option.markStart();
  final items = List<EquipmentItem?>.filled(list.length, null);
  for (var k = 0; k < list.length; k++) {
    final sub = option.elementObject('items', list, k);
    if (sub == null) continue;
    final itemMark = sub.markStart();
    final name = sub.name('name');
    final quantity = sub.wholeInt('quantity', min: EquipmentItem.minQuantity);
    sub.close();
    if (sub.isClean(itemMark) && name != null && quantity != null) {
      items[k] = EquipmentItem(name, quantity);
    }
  }
  if (option.problems.length != mark) return null;
  return [for (final item in items) ?item];
}

// -- feat ------------------------------------------------------------------

/// A feat (content-species-backgrounds-feats.md §5; FR-033 to FR-040,
/// FR-063, SX-2, SX-4).
_DecodedEntry _feat(_Element el) {
  final id = el.id('id');
  final name = el.name('name');
  final source = el.source();
  final category = el.enumValue('category', FeatCategory.fromJson);
  final prerequisites = _prerequisites(el);
  final benefits = _benefits(el);
  final repeatable = el.boolean('repeatable');
  final repeatableText = el.optionalText('repeatableText');
  // SX-2 (FR-039): required when repeatable, forbidden when not.
  if (repeatable == true && !el.has('repeatableText')) {
    el.problems.add(
      ContentProblem(
        '${el.base}/repeatableText',
        ContentProblemKind.missingField,
      ),
    );
  } else if (repeatable == false && repeatableText != null) {
    el.problems.add(
      ContentProblem(
        '${el.base}/repeatableText',
        ContentProblemKind.constraintViolation,
      ),
    );
  }
  el.close();
  if (el.problems.isNotEmpty ||
      id == null ||
      name == null ||
      category == null ||
      benefits == null ||
      repeatable == null) {
    return _DecodedEntry(id, null);
  }
  return _DecodedEntry(
    id,
    Feat(
      id: FeatId.of(id),
      name: name,
      source: source,
      category: category,
      // Absent is a feat with no prerequisites (FR-035 of the kind spec).
      prerequisites: prerequisites,
      benefits: benefits,
      repeatable: repeatable,
      repeatableText: repeatableText,
    ),
  );
}

/// A feat's optional `prerequisites`: a non-empty list (SX-4) of the sealed
/// [Prerequisite] family (FR-118); an empty list is `outOfRange` at the
/// array.
List<Prerequisite>? _prerequisites(_Element el) {
  final list = el.optionalArray('prerequisites');
  if (list == null) return null;
  if (list.isEmpty) {
    el.problems.add(
      ContentProblem('${el.base}/prerequisites', ContentProblemKind.outOfRange),
    );
    return null;
  }
  final mark = el.markStart();
  final clauses = List<Prerequisite?>.filled(list.length, null);
  for (var k = 0; k < list.length; k++) {
    final sub = el.elementObject('prerequisites', list, k);
    if (sub == null) continue;
    final clauseMark = sub.markStart();
    final kind = sub.string('kind');
    final clause = switch (kind) {
      'level' => _levelPrerequisite(sub),
      'abilityScore' => _abilityScorePrerequisite(sub),
      'feature' => _featurePrerequisite(sub),
      null => null,
      _ => _unknownPrerequisiteKind(sub),
    };
    if (clause != null && sub.isClean(clauseMark)) clauses[k] = clause;
  }
  if (el.problems.length != mark) return null;
  return [for (final clause in clauses) ?clause];
}

Prerequisite? _levelPrerequisite(_Element sub) {
  final mark = sub.markStart();
  final minimum = sub.wholeInt(
    'minimum',
    min: LevelPrerequisite.minLevel,
    max: LevelPrerequisite.maxLevel,
  );
  sub.close();
  if (!sub.isClean(mark) || minimum == null) return null;
  return LevelPrerequisite(minimum);
}

Prerequisite? _abilityScorePrerequisite(_Element sub) {
  final mark = sub.markStart();
  final abilities = _abilitySet(sub);
  final minimum = sub.wholeInt(
    'minimum',
    min: AbilityScorePrerequisite.minMinimum,
    max: AbilityScorePrerequisite.maxMinimum,
  );
  sub.close();
  if (!sub.isClean(mark) || abilities == null || minimum == null) return null;
  return AbilityScorePrerequisite(abilities, minimum);
}

/// An `abilities` set (FR-118): a non-empty array of distinct printed
/// abilities; empty is `outOfRange` at the array, a repeat `duplicate` at
/// the later index.
Set<Ability>? _abilitySet(_Element sub) {
  final list = sub.array('abilities');
  if (list == null) return null;
  if (list.isEmpty) {
    sub.problems.add(
      ContentProblem('${sub.base}/abilities', ContentProblemKind.outOfRange),
    );
    return null;
  }
  final mark = sub.markStart();
  final values = List<Ability?>.filled(list.length, null);
  for (var k = 0; k < list.length; k++) {
    final value = list[k];
    if (value is! String) {
      sub.problems.add(
        ContentProblem(
          '${sub.base}/abilities/$k',
          ContentProblemKind.wrongType,
        ),
      );
      continue;
    }
    values[k] = _abilityFromJson(value);
    if (values[k] == null) {
      sub.problems.add(
        ContentProblem(
          '${sub.base}/abilities/$k',
          ContentProblemKind.invalidValue,
        ),
      );
    }
  }
  _reportDuplicates(sub.problems, '${sub.base}/abilities', values);
  if (sub.problems.length != mark) return null;
  return {for (final value in values) value!};
}

Prerequisite? _featurePrerequisite(_Element sub) {
  final mark = sub.markStart();
  final name = sub.name('name');
  sub.close();
  if (!sub.isClean(mark) || name == null) return null;
  return FeaturePrerequisite(name);
}

Prerequisite? _unknownPrerequisiteKind(_Element sub) {
  sub.problems.add(
    ContentProblem('${sub.base}/kind', ContentProblemKind.invalidValue),
  );
  // Every clause's fields are declared; report nothing but the kind.
  sub.mark('minimum');
  sub.mark('abilities');
  sub.mark('name');
  sub.close();
  return null;
}

/// A feat's `benefits`: one or more {name?, text} elements (FR-033,
/// FR-063); an empty array is `outOfRange` at the field.
List<FeatBenefit>? _benefits(_Element el) {
  final list = el.array('benefits');
  if (list == null) return null;
  if (list.length < Feat.minBenefits) {
    el.problems.add(
      ContentProblem('${el.base}/benefits', ContentProblemKind.outOfRange),
    );
    return null;
  }
  final mark = el.markStart();
  final benefits = List<FeatBenefit?>.filled(list.length, null);
  for (var k = 0; k < list.length; k++) {
    final sub = el.elementObject('benefits', list, k);
    if (sub == null) continue;
    final benefitMark = sub.markStart();
    var name = sub.optionalString('name');
    if (name != null && !NamedText.isValidName(name)) {
      sub.problems.add(
        ContentProblem('${sub.base}/name', ContentProblemKind.invalidValue),
      );
      name = null;
    }
    final text = sub.text('text');
    sub.close();
    if (sub.isClean(benefitMark) && text != null) {
      benefits[k] = FeatBenefit(name: name, text: text);
    }
  }
  if (el.problems.length != mark) return null;
  return [for (final benefit in benefits) ?benefit];
}

// -- equipment: weapons and armor -------------------------------------------

/// One entry of `weapons` (content-equipment.md FR-106, FR-109 to FR-111,
/// FR-080, FR-013, FR-014).
_DecodedEntry _weapon(_Element el) {
  final id = el.id('id');
  final name = el.name('name');
  final source = el.source();
  final category = el.enumValue('category', WeaponCategory.fromJson);
  final weaponType = el.enumValue('weaponType', WeaponType.fromJson);
  final damageShape = _weaponDamage(el);
  final damageType = el.enumValue('damageType', DamageType.fromJson);
  WeaponDamage? damage;
  if (damageShape != null && damageType != null) {
    final (isDice: dice, value: value) = damageShape;
    damage = dice
        ? WeaponDiceDamage(value as DiceExpression, damageType)
        : WeaponFixedDamage(value as int, damageType);
  }
  final properties = _propertyUses(el);
  final mastery = el.enumValue('mastery', MasteryProperty.fromJson);
  final weight = el.optionalPounds('weightPounds');
  final price = _fixedCost(el);
  // A weapon never carries a "Varies" weight or price (FR-014, FR-106):
  // the flag keys are recognised and rejected at the flag (FR-013).
  _forbiddenVariesFlags(el);
  el.close();
  if (el.problems.isNotEmpty ||
      id == null ||
      name == null ||
      category == null ||
      weaponType == null ||
      damage == null ||
      damageType == null ||
      properties == null ||
      mastery == null ||
      price == null) {
    return _DecodedEntry(id, null);
  }
  return _DecodedEntry(
    id,
    Weapon(
      id: ItemId.of(id),
      name: name,
      source: source,
      category: category,
      weaponType: weaponType,
      damage: damage,
      properties: properties,
      mastery: mastery,
      weight: weight == null ? const NoWeight() : Weight(weight),
      price: price,
    ),
  );
}

/// One entry of `armor` (content-equipment.md FR-105, FR-109, FR-112,
/// FR-080, FR-013, FR-014).
_DecodedEntry _armor(_Element el) {
  final id = el.id('id');
  final name = el.name('name');
  final source = el.source();
  final category = el.enumValue('category', ArmorCategory.fromJson);
  final armorClass = _armorClassRule(el, category);
  final strengthRequirement = el.optionalWholeInt(
    'strengthRequirement',
    min: AbilityScore.minimum,
    max: AbilityScore.maximum,
  );
  final stealthDisadvantage = el.boolean('stealthDisadvantage');
  final weight = el.pounds('weightPounds');
  final price = _fixedCost(el);
  _forbiddenVariesFlags(el);
  el.close();
  if (el.problems.isNotEmpty ||
      id == null ||
      name == null ||
      category == null ||
      armorClass == null ||
      stealthDisadvantage == null ||
      weight == null ||
      price == null) {
    return _DecodedEntry(id, null);
  }
  return _DecodedEntry(
    id,
    Armor(
      id: ItemId.of(id),
      name: name,
      source: source,
      category: category,
      armorClass: armorClass,
      strengthRequirement: strengthRequirement,
      stealthDisadvantage: stealthDisadvantage,
      weight: Weight(weight),
      price: price,
    ),
  );
}

/// The `weightVaries` and `costVaries` flag keys (FR-013): on an entry of a
/// type that holds a plain [Weight] and a [FixedCost] they are
/// `constraintViolation` at the flag, whether or not the value is there
/// too (FR-014).
void _forbiddenVariesFlags(_Element el) {
  for (final key in const ['weightVaries', 'costVaries']) {
    if (el.has(key)) {
      el.problems.add(
        ContentProblem(
          '${el.base}/$key',
          ContentProblemKind.constraintViolation,
        ),
      );
    }
    el.mark(key);
  }
}

/// A weapon's `damage` object (FR-102, FR-110): exactly one of `dice` and
/// `fixed`; neither is `missingField` and both `constraintViolation`, at
/// the damage. The separate `damageType` field is the weapon shape's; the
/// two combine there.
({bool isDice, Object value})? _weaponDamage(_Element el) {
  final sub = el.object('damage');
  if (sub == null) return null;
  return _damageShape(sub);
}

/// The `damage` object's own shape: exactly one of the two keys.
({bool isDice, Object value})? _damageShape(_Element sub) {
  final hasDice = sub.has('dice');
  final hasFixed = sub.has('fixed');
  sub.mark('dice');
  sub.mark('fixed');
  if (!hasDice && !hasFixed) {
    sub.problems.add(ContentProblem(sub.base, ContentProblemKind.missingField));
    return null;
  }
  if (hasDice && hasFixed) {
    sub.problems.add(
      ContentProblem(sub.base, ContentProblemKind.constraintViolation),
    );
    return null;
  }
  if (hasDice) {
    final dice = _diceDamage(sub);
    sub.close();
    if (dice == null) return null;
    return (isDice: true, value: dice);
  }
  final fixed = sub.wholeInt('fixed', min: 1);
  sub.close();
  if (fixed == null) return null;
  return (isDice: false, value: fixed);
}

/// The `dice` wire form (FR-102, FR-110): stricter than
/// `DiceExpression.tryParse` — an explicit count of at least 1, no
/// modifier, and sides a die can have; anything else `invalidValue`.
DiceExpression? _diceDamage(_Element sub) {
  final value = sub.string('dice');
  if (value == null) return null;
  final match = _dicePattern.firstMatch(value);
  if (match == null) {
    sub.problems.add(
      ContentProblem('${sub.base}/dice', ContentProblemKind.invalidValue),
    );
    return null;
  }
  // tryParse: a literal too wide for the platform's int form is rejected
  // as data, so the result never depends on integer width (FR-018, FR-021).
  final count = int.tryParse(match.group(1)!);
  final sides = int.tryParse(match.group(2)!);
  if (count == null ||
      sides == null ||
      count > DiceExpression.maxCount ||
      sides < Die.minSides ||
      sides > Die.maxSides) {
    sub.problems.add(
      ContentProblem('${sub.base}/dice', ContentProblemKind.invalidValue),
    );
    return null;
  }
  return DiceExpression(count, Die(sides));
}

/// `<count>d<sides>` with an explicit count and no modifier (FR-110).
final RegExp _dicePattern = RegExp(r'^([1-9][0-9]*)d([1-9][0-9]*)$');

/// A weapon's `properties` (FR-103, FR-111): one use per printed property,
/// each at most once — a repeat is `duplicate` at the later element; a
/// weapon printed "—" has an empty list.
List<WeaponPropertyUse>? _propertyUses(_Element el) {
  final list = el.array('properties');
  if (list == null) return null;
  final mark = el.markStart();
  final uses = List<WeaponPropertyUse?>.filled(list.length, null);
  final properties = List<WeaponProperty?>.filled(list.length, null);
  for (var j = 0; j < list.length; j++) {
    final sub = el.elementObject('properties', list, j);
    if (sub == null) continue;
    final useMark = sub.markStart();
    final property = sub.enumValue('property', WeaponProperty.fromJson);
    properties[j] = property;
    // The null branch first, so the enum switch below is exhaustive over
    // the nine members of the promoted type.
    final use = property == null
        ? _unreadableProperty(sub)
        : switch (property) {
            WeaponProperty.ammunition => _ammunitionUse(sub),
            WeaponProperty.thrown => _thrownUse(sub),
            WeaponProperty.versatile => _versatileUse(sub),
            WeaponProperty.twoHanded => _twoHandedUse(sub),
            WeaponProperty.finesse ||
            WeaponProperty.heavy ||
            WeaponProperty.light ||
            WeaponProperty.loading ||
            WeaponProperty.reach => _plainUse(sub, property),
          };
    if (use != null && sub.isClean(useMark)) uses[j] = use;
  }
  _reportDuplicates(el.problems, '${el.base}/properties', properties);
  if (el.problems.length != mark) return null;
  return [for (final use in uses) ?use];
}

/// The data keys a property use may carry (FR-111): present where
/// forbidden is `constraintViolation` at the key; every key is marked read,
/// so [close] reports only unknown ones.
void _forbiddenUseKeys(_Element sub, List<String> forbidden) {
  for (final key in forbidden) {
    if (sub.has(key)) {
      sub.problems.add(
        ContentProblem(
          '${sub.base}/$key',
          ContentProblemKind.constraintViolation,
        ),
      );
    }
    sub.mark(key);
  }
}

WeaponPropertyUse? _plainUse(_Element sub, WeaponProperty property) {
  _forbiddenUseKeys(sub, const ['range', 'ammunition', 'damage', 'condition']);
  sub.close();
  return PlainUse(property);
}

WeaponPropertyUse? _unreadableProperty(_Element sub) {
  // The variant is unknowable, so the data keys are neither read nor
  // rejected: mark them declared and move on.
  for (final key in const ['range', 'ammunition', 'damage', 'condition']) {
    sub.mark(key);
  }
  sub.close();
  return null;
}

/// The {normal, long} range pair (FR-103, FR-111): `normal` at least
/// [RangePair.minNormal], `long` greater than `normal` — a violation is
/// `constraintViolation` at the long range.
RangePair? _range(_Element sub) {
  final range = sub.object('range');
  if (range == null) return null;
  final mark = range.markStart();
  final normal = range.wholeInt('normal', min: RangePair.minNormal);
  final long = range.wholeInt('long', min: RangePair.minNormal);
  range.close();
  if (!range.isClean(mark) || normal == null || long == null) return null;
  if (long <= normal) {
    sub.problems.add(
      ContentProblem(
        '${sub.base}/range/long',
        ContentProblemKind.constraintViolation,
      ),
    );
    return null;
  }
  return RangePair(normal, long);
}

WeaponPropertyUse? _ammunitionUse(_Element sub) {
  final mark = sub.markStart();
  final range = _range(sub);
  final ammunition = sub.enumValue('ammunition', AmmunitionType.fromJson);
  _forbiddenUseKeys(sub, const ['damage', 'condition']);
  sub.close();
  if (!sub.isClean(mark) || range == null || ammunition == null) return null;
  return AmmunitionUse(range, ammunition);
}

WeaponPropertyUse? _thrownUse(_Element sub) {
  final mark = sub.markStart();
  final range = _range(sub);
  _forbiddenUseKeys(sub, const ['ammunition', 'damage', 'condition']);
  sub.close();
  if (!sub.isClean(mark) || range == null) return null;
  return ThrownUse(range);
}

WeaponPropertyUse? _versatileUse(_Element sub) {
  final mark = sub.markStart();
  final value = sub.string('damage');
  DiceExpression? damage;
  if (value != null) {
    final parsed = DiceExpression.tryParse(value);
    if (parsed is ParsedDiceExpression) {
      damage = parsed.expression;
    } else {
      sub.problems.add(
        ContentProblem('${sub.base}/damage', ContentProblemKind.invalidValue),
      );
    }
  }
  _forbiddenUseKeys(sub, const ['range', 'ammunition', 'condition']);
  sub.close();
  if (!sub.isClean(mark) || damage == null) return null;
  return VersatileUse(damage);
}

WeaponPropertyUse? _twoHandedUse(_Element sub) {
  final mark = sub.markStart();
  final condition = sub.enumValue('condition', TwoHandedCondition.fromJson);
  _forbiddenUseKeys(sub, const ['range', 'ammunition', 'damage']);
  sub.close();
  if (!sub.isClean(mark)) return null;
  return TwoHandedUse(condition ?? TwoHandedCondition.always);
}

/// A printed price (FR-080, FR-012): {amount, coin, per?}; a missing `cost`
/// without `costVaries` is `missingField` at the cost (FR-013) — with
/// `costVaries` present the flag itself is the violation
/// ([_forbiddenVariesFlags]) and the absence is not reported again.
FixedCost? _fixedCost(_Element el) {
  if (!el.has('cost')) {
    el.mark('cost');
    if (!el.has('costVaries')) {
      el.problems.add(
        ContentProblem('${el.base}/cost', ContentProblemKind.missingField),
      );
    }
    return null;
  }
  final sub = el.object('cost');
  if (sub == null) return null;
  final mark = sub.markStart();
  final amount = sub.wholeInt('amount', min: 0);
  final coin = sub.enumValue('coin', Coin.fromJson);
  final per = sub.optionalString('per');
  CostRate? rate;
  if (per != null) {
    rate = CostRate.fromJson(per);
    if (rate == null) {
      sub.problems.add(
        ContentProblem('${sub.base}/per', ContentProblemKind.invalidValue),
      );
    }
  }
  sub.close();
  if (!sub.isClean(mark) || amount == null || coin == null) return null;
  return FixedCost(Cost(amount, coin, per: rate));
}

/// An armor's `armorClass` (FR-112): either `base` with `dexterity`
/// (`maximum` only when `capped`) or `bonus`; neither is `missingField` and
/// both shapes at once `constraintViolation`, at the armorClass; a `bonus`
/// only on a Shield and a `base` only on body armor (FR-024).
ArmorClassRule? _armorClassRule(_Element el, ArmorCategory? category) {
  final sub = el.object('armorClass');
  if (sub == null) return null;
  final hasBase = sub.has('base');
  final hasDexterity = sub.has('dexterity');
  final hasBonus = sub.has('bonus');
  for (final key in const ['base', 'dexterity', 'maximum', 'bonus']) {
    sub.mark(key);
  }
  if (!hasBase && !hasDexterity && !hasBonus) {
    sub.problems.add(ContentProblem(sub.base, ContentProblemKind.missingField));
    return null;
  }
  if ((hasBase || hasDexterity) && hasBonus) {
    sub.problems.add(
      ContentProblem(sub.base, ContentProblemKind.constraintViolation),
    );
    return null;
  }
  final mark = sub.markStart();
  final rule = hasBonus ? _bonusRule(sub) : _baseRule(sub);
  // FR-024: the Shield's rule is a bonus, every other armor's a base rule.
  if (rule != null && category != null) {
    if ((category == ArmorCategory.shield) != (rule is BonusRule)) {
      sub.problems.add(
        ContentProblem(sub.base, ContentProblemKind.constraintViolation),
      );
    }
  }
  sub.close();
  if (!sub.isClean(mark) || rule == null) return null;
  return rule;
}

ArmorClassRule? _baseRule(_Element sub) {
  final mark = sub.markStart();
  final base = sub.wholeInt(
    'base',
    min: BaseRule.minBase,
    max: BaseRule.maxBase,
  );
  final dexterity = sub.string('dexterity');
  DexterityBonus? bonus;
  if (dexterity != null) {
    switch (dexterity) {
      case 'full':
        bonus = const FullDexterity();
      case 'capped':
        final maximum = sub.wholeInt(
          'maximum',
          min: CappedDexterity.minMaximum,
        );
        if (maximum != null) bonus = CappedDexterity(maximum);
      case 'none':
        bonus = const NoDexterity();
      default:
        sub.problems.add(
          ContentProblem(
            '${sub.base}/dexterity',
            ContentProblemKind.invalidValue,
          ),
        );
    }
    if (dexterity != 'capped' && sub.has('maximum')) {
      sub.problems.add(
        ContentProblem(
          '${sub.base}/maximum',
          ContentProblemKind.constraintViolation,
        ),
      );
    }
  }
  if (!sub.isClean(mark) || base == null || dexterity == null) return null;
  return BaseRule(base, bonus!);
}

ArmorClassRule? _bonusRule(_Element sub) {
  final mark = sub.markStart();
  final bonus = sub.wholeInt(
    'bonus',
    min: BonusRule.minBonus,
    max: BonusRule.maxBonus,
  );
  sub.close();
  if (!sub.isClean(mark) || bonus == null) return null;
  return BonusRule(bonus);
}

// -- classes -----------------------------------------------------------------

/// One entry of `classes` (content-classes.md FR-002 to FR-077). Field
/// problems are reported in the FR-002 field order; then the entry's
/// cross-field problems in the order the multiclass subset rule (FR-026),
/// the spellcasting rows (FR-030, FR-031), the progression references
/// (FR-044, FR-045), the owner prefixes (FR-052, FR-072), the subclass
/// feature (FR-056) and the subclass level checks (FR-071, FR-073) — the
/// order FR-005 fixes for the groups it names. The duplicate problems of
/// FR-004 are reported after every entry-level problem of the document
/// (FR-005, FR-016), by the decode loop.
_DecodedEntry _class(_Element el) {
  final id = el.id('id');
  final name = el.name('name');
  final source = el.source();
  final primaryAbility = _primaryAbility(el);
  final hitPointDie = el.enumValue('hitPointDie', HitPointDie.fromJson);
  final savingThrows = _boundedAbilityList(
    el,
    'savingThrowProficiencies',
    min: ClassDefinition.minSavingThrowProficiencies,
    max: ClassDefinition.maxSavingThrowProficiencies,
  );
  final skillChoice = _skillChoice(el);
  final weaponProficiencies = _weaponProficiencies(el);
  final toolProficiencies = _toolProficiencies(el);
  final armorTraining = _armorTraining(el);
  final startingEquipment = _startingEquipment(el);
  final multiclass = _multiclassData(el);
  final spellcasting = _spellcastingTrait(el);
  final columns = _columns(el);
  final progression = _progression(el, columns);
  final features = _classFeatures(el);
  final subclasses = _subclassData(el);

  // -- cross-field checks ----------------------------------------------------
  _checkMulticlassGrants(
    el,
    multiclass,
    weaponProficiencies,
    armorTraining,
    toolProficiencies,
    skillChoice,
  );
  _checkSpellcastingRows(progression, spellcasting);
  _checkProgressionReferences(el, progression, features);
  _checkSubclasses(el, id, features, subclasses);
  _buildRows(progression);

  el.close();
  final rows = progression?.map((row) => row?.row).toList();
  final entries = features?.map((feature) => feature?.entry).toList();
  final subclassEntries = subclasses?.map((sub) => sub?.entry).toList();
  if (el.problems.isNotEmpty ||
      id == null ||
      name == null ||
      primaryAbility == null ||
      hitPointDie == null ||
      savingThrows == null ||
      skillChoice == null ||
      weaponProficiencies == null ||
      toolProficiencies == null ||
      armorTraining == null ||
      startingEquipment == null ||
      multiclass.grants == null ||
      columns == null ||
      rows == null ||
      rows.any((row) => row == null) ||
      entries == null ||
      entries.any((entry) => entry == null) ||
      subclassEntries == null ||
      subclassEntries.any((sub) => sub == null)) {
    return _DecodedEntry(
      id,
      null,
      subclassIds: _nestedIds(subclasses),
      featureIds: _featureNestedIds(features, subclasses),
    );
  }
  return _DecodedEntry(
    id,
    ClassDefinition(
      id: ClassId.of(id),
      name: name,
      source: source,
      primaryAbility: primaryAbility,
      hitPointDie: hitPointDie,
      savingThrowProficiencies: savingThrows,
      skillChoice: skillChoice,
      weaponProficiencies: weaponProficiencies,
      toolProficiencies: toolProficiencies,
      armorTraining: armorTraining,
      startingEquipment: startingEquipment,
      multiclassGrants: multiclass.grants!,
      spellcasting: spellcasting.trait,
      columns: columns,
      progression: [for (final row in rows) row!],
      features: [for (final entry in entries) entry!],
      subclasses: [for (final sub in subclassEntries) sub!],
    ),
    subclassIds: _nestedIds(subclasses),
    featureIds: _featureNestedIds(features, subclasses),
  );
}

/// A class element's `primaryAbility` (content-classes.md FR-011 to
/// FR-015): {kind: "allOf"|"anyOf", abilities}; another kind is
/// `invalidValue` at the kind.
AbilityRequirement? _primaryAbility(_Element el) {
  final sub = el.object('primaryAbility');
  if (sub == null) return null;
  final mark = sub.markStart();
  final kind = sub.string('kind');
  final List<Ability>? abilities = switch (kind) {
    'allOf' => _requirementAbilities(sub, min: AllOf.minAbilities),
    'anyOf' => _requirementAbilities(sub, min: AnyOf.minAbilities),
    null => null,
    _ => _unknownRequirementKind(sub),
  };
  sub.close();
  if (!sub.isClean(mark) || abilities == null) return null;
  return kind == 'allOf'
      ? AllOf(List.of(abilities))
      : AnyOf(List.of(abilities));
}

List<Ability>? _unknownRequirementKind(_Element sub) {
  sub.problems.add(
    ContentProblem('${sub.base}/kind', ContentProblemKind.invalidValue),
  );
  sub.mark('abilities');
  return null;
}

/// An ability list of at least [min] distinct printed abilities (FR-012,
/// FR-013, FR-015): fewer is `outOfRange` at the array, a repeat
/// `duplicate` at the later index.
List<Ability>? _requirementAbilities(_Element sub, {required int min}) {
  final mark = sub.markStart();
  final abilities = _memberList<Ability>(
    sub,
    'abilities',
    parse: _abilityFromJson,
  );
  if (abilities == null) return null;
  if (abilities.length < min) {
    sub.problems.add(
      ContentProblem('${sub.base}/abilities', ContentProblemKind.outOfRange),
    );
    return null;
  }
  if (sub.problems.length != mark) return null;
  return abilities;
}

/// A bounded list of distinct printed abilities (FR-018): fewer than [min]
/// or more than [max] is `outOfRange` at the array, a repeat `duplicate` at
/// the later index.
List<Ability>? _boundedAbilityList(
  _Element el,
  String key, {
  required int min,
  required int max,
}) {
  final mark = el.markStart();
  final abilities = _memberList<Ability>(el, key, parse: _abilityFromJson);
  if (abilities == null) return null;
  if (abilities.length < min || abilities.length > max) {
    el.problems.add(
      ContentProblem('${el.base}/$key', ContentProblemKind.outOfRange),
    );
    return null;
  }
  if (el.problems.length != mark) return null;
  return abilities;
}

/// An array of distinct closed-set strings, no length rule (FR-025,
/// FR-026): a non-string is `wrongType` and a non-member `invalidValue` at
/// the element's index; a repeat `duplicate` at the later index.
List<T>? _memberList<T>(
  _Element el,
  String key, {
  required T? Function(String value) parse,
}) {
  final list = el.array(key);
  if (list == null) return null;
  final mark = el.markStart();
  final values = List<T?>.filled(list.length, null);
  for (var k = 0; k < list.length; k++) {
    final value = list[k];
    if (value is! String) {
      el.problems.add(
        ContentProblem('${el.base}/$key/$k', ContentProblemKind.wrongType),
      );
      continue;
    }
    values[k] = parse(value);
    if (values[k] == null) {
      el.problems.add(
        ContentProblem('${el.base}/$key/$k', ContentProblemKind.invalidValue),
      );
    }
  }
  _reportDuplicates(el.problems, '${el.base}/$key', values);
  if (el.problems.length != mark) return null;
  return [for (final value in values) value!];
}

/// A class element's `skillChoice` (FR-019): {picks, options}; options is
/// {kind: "listed", skills} or {kind: "any"}.
SkillChoice? _skillChoice(_Element el) {
  final sub = el.object('skillChoice');
  if (sub == null) return null;
  final mark = sub.markStart();
  final picks = sub.wholeInt('picks', min: SkillChoice.minPicks);
  final options = sub.object('options');
  SkillChoice? choice;
  if (options != null) {
    final optionsMark = options.markStart();
    final kind = options.string('kind');
    switch (kind) {
      case 'listed':
        final skills = _skillList(options, atLeast: picks);
        if (options.isClean(optionsMark) && skills != null && picks != null) {
          choice = SkillChoiceListed(picks, skills);
        }
      case 'any':
        if (options.isClean(optionsMark) && picks != null) {
          choice = SkillChoiceAny(picks);
        }
      case null:
        // The kind is missing; the variant is unknowable, so the skills key
        // is declared either way (FR-013).
        options.mark('skills');
      default:
        options.problems.add(
          ContentProblem(
            '${options.base}/kind',
            ContentProblemKind.invalidValue,
          ),
        );
        options.mark('skills');
    }
    options.close();
  }
  if (!sub.isClean(mark) || choice == null) return null;
  return choice;
}

/// A listed skill set (FR-019): non-empty, distinct, at least [atLeast]
/// skills; empty or short is `outOfRange` at the array.
List<Skill>? _skillList(_Element options, {required int? atLeast}) {
  final mark = options.markStart();
  final skills = _memberList<Skill>(options, 'skills', parse: Skill.fromJson);
  if (skills == null) return null;
  if (atLeast != null && skills.length < atLeast) {
    options.problems.add(
      ContentProblem('${options.base}/skills', ContentProblemKind.outOfRange),
    );
    return null;
  }
  if (options.problems.length != mark) return null;
  return skills;
}

/// A class element's `weaponProficiencies` (FR-021): one {category,
/// requiresAnyProperty?} per category at most, a repeat `duplicate` at the
/// later element.
List<WeaponProficiency>? _weaponProficiencies(_Element el) {
  final list = el.array('weaponProficiencies');
  if (list == null) return null;
  final mark = el.markStart();
  final categories = List<WeaponTrainingCategory?>.filled(list.length, null);
  final values = List<WeaponProficiency?>.filled(list.length, null);
  for (var k = 0; k < list.length; k++) {
    final sub = el.elementObject('weaponProficiencies', list, k);
    if (sub == null) continue;
    final subMark = sub.markStart();
    final category = sub.enumValue('category', WeaponTrainingCategory.fromJson);
    categories[k] = category;
    final filter = _propertyFilter(sub);
    sub.close();
    if (sub.isClean(subMark) && category != null) {
      values[k] = WeaponProficiency(category, requiresAnyProperty: filter);
    }
  }
  _reportDuplicates(el.problems, '${el.base}/weaponProficiencies', categories);
  if (el.problems.length != mark) return null;
  return [for (final value in values) value!];
}

/// The optional `requiresAnyProperty` filter (FR-021): non-empty, distinct
/// weapon properties.
List<WeaponProperty>? _propertyFilter(_Element sub) {
  final list = sub.optionalArray('requiresAnyProperty');
  if (list == null) return null;
  if (list.isEmpty) {
    sub.problems.add(
      ContentProblem(
        '${sub.base}/requiresAnyProperty',
        ContentProblemKind.outOfRange,
      ),
    );
    return null;
  }
  final mark = sub.markStart();
  final values = List<WeaponProperty?>.filled(list.length, null);
  for (var k = 0; k < list.length; k++) {
    final value = list[k];
    if (value is! String) {
      sub.problems.add(
        ContentProblem(
          '${sub.base}/requiresAnyProperty/$k',
          ContentProblemKind.wrongType,
        ),
      );
      continue;
    }
    values[k] = WeaponProperty.fromJson(value);
    if (values[k] == null) {
      sub.problems.add(
        ContentProblem(
          '${sub.base}/requiresAnyProperty/$k',
          ContentProblemKind.invalidValue,
        ),
      );
    }
  }
  _reportDuplicates(sub.problems, '${sub.base}/requiresAnyProperty', values);
  if (sub.problems.length != mark) return null;
  return [for (final value in values) value!];
}

/// A class element's `toolProficiencies` (FR-023): {kind: "specific",
/// name} or {kind: "choice", categories, picks}.
List<ClassToolProficiency>? _toolProficiencies(_Element el) {
  final list = el.array('toolProficiencies');
  if (list == null) return null;
  final mark = el.markStart();
  final values = List<ClassToolProficiency?>.filled(list.length, null);
  for (var k = 0; k < list.length; k++) {
    final sub = el.elementObject('toolProficiencies', list, k);
    if (sub == null) continue;
    final subMark = sub.markStart();
    final kind = sub.string('kind');
    final tool = switch (kind) {
      'specific' => _classSpecificTool(sub),
      'choice' => _classChoiceTool(sub),
      null => null,
      _ => _unknownClassToolKind(sub),
    };
    if (tool != null && sub.isClean(subMark)) values[k] = tool;
  }
  if (el.problems.length != mark) return null;
  return [for (final value in values) value!];
}

ClassToolProficiency? _classSpecificTool(_Element sub) {
  final mark = sub.markStart();
  final name = sub.name('name');
  sub.mark('categories');
  sub.mark('picks');
  sub.close();
  if (!sub.isClean(mark) || name == null) return null;
  return ClassToolProficiencySpecific(name);
}

ClassToolProficiency? _classChoiceTool(_Element sub) {
  final mark = sub.markStart();
  final categories = _distinctTexts(
    sub,
    'categories',
    isValid: ClassToolProficiencyChoice.isValidCategory,
  );
  final picks = sub.wholeInt('picks', min: ClassToolProficiencyChoice.minPicks);
  sub.mark('name');
  sub.close();
  if (!sub.isClean(mark) || categories == null || picks == null) return null;
  return ClassToolProficiencyChoice(categories, picks);
}

ClassToolProficiency? _unknownClassToolKind(_Element sub) {
  sub.problems.add(
    ContentProblem('${sub.base}/kind', ContentProblemKind.invalidValue),
  );
  sub.mark('name');
  sub.mark('categories');
  sub.mark('picks');
  return null;
}

/// An array of distinct non-blank strings (FR-023): empty is `outOfRange`
/// at the array, a blank `invalidValue` and a repeat `duplicate` at the
/// later index.
List<String>? _distinctTexts(
  _Element sub,
  String key, {
  required bool Function(String value) isValid,
}) {
  final list = sub.array(key);
  if (list == null) return null;
  if (list.isEmpty) {
    sub.problems.add(
      ContentProblem('${sub.base}/$key', ContentProblemKind.outOfRange),
    );
    return null;
  }
  final mark = sub.markStart();
  final values = List<String?>.filled(list.length, null);
  for (var k = 0; k < list.length; k++) {
    final value = list[k];
    if (value is! String) {
      sub.problems.add(
        ContentProblem('${sub.base}/$key/$k', ContentProblemKind.wrongType),
      );
      continue;
    }
    if (!isValid(value)) {
      sub.problems.add(
        ContentProblem('${sub.base}/$key/$k', ContentProblemKind.invalidValue),
      );
      continue;
    }
    values[k] = value;
  }
  _reportDuplicates(sub.problems, '${sub.base}/$key', values);
  if (sub.problems.length != mark) return null;
  return [for (final value in values) value!];
}

/// A class element's `armorTraining` (FR-022): distinct categories, `[]`
/// the explicit "None".
List<ArmorTrainingCategory>? _armorTraining(_Element el) =>
    _memberList<ArmorTrainingCategory>(
      el,
      'armorTraining',
      parse: ArmorTrainingCategory.fromJson,
    );

/// One option of `startingEquipment` (FR-024): {items, gold}.
ClassEquipmentOption? _classEquipmentOption(
  _Element sub,
  String key, {
  required bool optional,
}) {
  final option = optional ? sub.optionalObject(key) : sub.object(key);
  if (option == null) return null;
  final mark = option.markStart();
  final items = _classItems(option);
  final gold = option.wholeInt('gold', min: ClassEquipmentOption.minGold);
  option.close();
  if (!option.isClean(mark) || items == null || gold == null) return null;
  return ClassEquipmentOption(items, gold);
}

List<ClassEquipmentItem>? _classItems(_Element option) {
  final list = option.array('items');
  if (list == null) return null;
  final mark = option.markStart();
  final values = List<ClassEquipmentItem?>.filled(list.length, null);
  for (var k = 0; k < list.length; k++) {
    final sub = option.elementObject('items', list, k);
    if (sub == null) continue;
    final subMark = sub.markStart();
    final name = sub.name('name');
    final quantity = sub.wholeInt(
      'quantity',
      min: ClassEquipmentItem.minQuantity,
    );
    sub.close();
    if (sub.isClean(subMark) && name != null && quantity != null) {
      values[k] = ClassEquipmentItem(name, quantity);
    }
  }
  if (option.problems.length != mark) return null;
  return [for (final value in values) value!];
}

/// A class element's `startingEquipment` (FR-024): keys `A`, `B` and the
/// optional `C`.
ClassStartingEquipment? _startingEquipment(_Element el) {
  final sub = el.object('startingEquipment');
  if (sub == null) return null;
  final mark = sub.markStart();
  final a = _classEquipmentOption(sub, 'A', optional: false);
  final b = _classEquipmentOption(sub, 'B', optional: false);
  final c = _classEquipmentOption(sub, 'C', optional: true);
  sub.close();
  if (!sub.isClean(mark) || a == null || b == null) return null;
  return ClassStartingEquipment(a: a, b: b, c: c);
}

/// A class element's decoded `multiclassGrants` (FR-026): the constructed
/// grants and the element, for the subset problems' paths.
final class _MulticlassData {
  const _MulticlassData(this.grants, this.element);

  final MulticlassGrants? grants;
  final _Element? element;
}

_MulticlassData _multiclassData(_Element el) {
  final sub = el.object('multiclassGrants');
  if (sub == null) return const _MulticlassData(null, null);
  final mark = sub.markStart();
  final weapons = _weaponProficiencies(sub);
  final armorTraining = _armorTraining(sub);
  final tools = _toolProficiencies(sub);
  final skillChoice = sub.optionalObject('skillChoice') == null
      ? null
      : _skillChoice(sub);
  sub.close();
  if (!sub.isClean(mark) ||
      weapons == null ||
      armorTraining == null ||
      tools == null) {
    return _MulticlassData(null, sub);
  }
  return _MulticlassData(
    MulticlassGrants(
      weaponProficiencies: weapons,
      armorTraining: armorTraining,
      toolProficiencies: tools,
      skillChoice: skillChoice,
    ),
    sub,
  );
}

/// The FR-026 subset rule: the grants MUST NOT exceed the class's own core
/// traits; a violation is `constraintViolation` at the offending element.
void _checkMulticlassGrants(
  _Element el,
  _MulticlassData multiclass,
  List<WeaponProficiency>? coreWeapons,
  List<ArmorTrainingCategory>? coreArmor,
  List<ClassToolProficiency>? coreTools,
  SkillChoice? coreSkills,
) {
  final grants = multiclass.grants;
  final sub = multiclass.element;
  if (grants == null || sub == null || el.problems.isNotEmpty) return;
  if (coreWeapons != null) {
    for (var k = 0; k < grants.weaponProficiencies.length; k++) {
      final proficiency = grants.weaponProficiencies[k];
      if (!coreWeapons.any(
        (core) => WeaponProficiency.covers(core, proficiency),
      )) {
        sub.problems.add(
          ContentProblem(
            '${sub.base}/weaponProficiencies/$k',
            ContentProblemKind.constraintViolation,
          ),
        );
      }
    }
  }
  if (coreArmor != null) {
    for (var k = 0; k < grants.armorTraining.length; k++) {
      if (!coreArmor.contains(grants.armorTraining.elementAt(k))) {
        sub.problems.add(
          ContentProblem(
            '${sub.base}/armorTraining/$k',
            ContentProblemKind.constraintViolation,
          ),
        );
      }
    }
  }
  if (coreTools != null) {
    final choiceCategories = <String>{
      for (final proficiency in coreTools)
        if (proficiency is ClassToolProficiencyChoice)
          ...proficiency.categories,
    };
    final specificTools = <String>{
      for (final proficiency in coreTools)
        if (proficiency is ClassToolProficiencySpecific) proficiency.name,
    };
    var coreMaxPicks = 0;
    for (final proficiency in coreTools) {
      final picks = switch (proficiency) {
        ClassToolProficiencyChoice() => proficiency.picks,
        ClassToolProficiencySpecific() => 1,
      };
      if (picks > coreMaxPicks) coreMaxPicks = picks;
    }
    for (var k = 0; k < grants.toolProficiencies.length; k++) {
      var violation = false;
      switch (grants.toolProficiencies[k]) {
        case ClassToolProficiencySpecific(:final name):
          violation =
              !choiceCategories.contains(name) && !specificTools.contains(name);
        case ClassToolProficiencyChoice(:final categories, :final picks):
          violation =
              categories.any(
                (category) =>
                    !choiceCategories.contains(category) &&
                    !specificTools.contains(category),
              ) ||
              picks > coreMaxPicks;
      }
      if (violation) {
        sub.problems.add(
          ContentProblem(
            '${sub.base}/toolProficiencies/$k',
            ContentProblemKind.constraintViolation,
          ),
        );
      }
    }
  }
  final grantsSkills = grants.skillChoice;
  if (grantsSkills != null && coreSkills != null) {
    switch (grantsSkills) {
      case SkillChoiceAny():
        if (coreSkills is! SkillChoiceAny) {
          sub.problems.add(
            ContentProblem(
              '${sub.base}/skillChoice',
              ContentProblemKind.constraintViolation,
            ),
          );
        }
      case SkillChoiceListed(:final skills, :final picks):
        final core = coreSkills;
        if (core is SkillChoiceListed) {
          for (var k = 0; k < skills.length; k++) {
            if (!core.skills.contains(skills[k])) {
              sub.problems.add(
                ContentProblem(
                  '${sub.base}/skillChoice/options/skills/$k',
                  ContentProblemKind.constraintViolation,
                ),
              );
            }
          }
          if (picks > core.picks) {
            sub.problems.add(
              ContentProblem(
                '${sub.base}/skillChoice',
                ContentProblemKind.constraintViolation,
              ),
            );
          }
        }
    }
  }
}

/// A class element's decoded `spellcasting` (FR-028): the trait when the
/// field decoded cleanly, null when absent, and whether a present field
/// failed (so its rows cannot be judged, FR-095).
final class _SpellcastingData {
  const _SpellcastingData(this.trait, {required this.failed});

  final ClassSpellcastingTrait? trait;
  final bool failed;
}

_SpellcastingData _spellcastingTrait(_Element el) {
  el.mark('spellcasting');
  if (!el.has('spellcasting')) {
    return const _SpellcastingData(null, failed: false);
  }
  final value = el.map['spellcasting'];
  if (value is! Map<String, Object?>) {
    el.problems.add(
      ContentProblem('${el.base}/spellcasting', ContentProblemKind.wrongType),
    );
    return const _SpellcastingData(null, failed: true);
  }
  final sub = _Element(el.problems, '${el.base}/spellcasting', value);
  final mark = sub.markStart();
  final kind = sub.string('kind');
  switch (kind) {
    case 'slots':
      final ability = sub.enumValue('ability', _abilityFromJson);
      final cantrips = sub.boolean('cantrips');
      sub.close();
      if (sub.isClean(mark) && ability != null && cantrips != null) {
        return _SpellcastingData(
          SlotSpellcastingTrait(ability, cantrips: cantrips),
          failed: false,
        );
      }
    case 'pact':
      final ability = sub.enumValue('ability', _abilityFromJson);
      sub.close();
      if (sub.isClean(mark) && ability != null) {
        return _SpellcastingData(PactSpellcastingTrait(ability), failed: false);
      }
    case null:
      sub.mark('ability');
      sub.mark('cantrips');
      sub.close();
    default:
      sub.problems.add(
        ContentProblem('${sub.base}/kind', ContentProblemKind.invalidValue),
      );
      sub.mark('ability');
      sub.mark('cantrips');
      sub.close();
  }
  return const _SpellcastingData(null, failed: true);
}

/// A class element's `columns` (FR-036): {id, header, kind} elements, ids
/// unique within the class.
List<ClassColumn>? _columns(_Element el) {
  final list = el.array('columns');
  if (list == null) return null;
  final mark = el.markStart();
  final idStrings = List<String?>.filled(list.length, null);
  final values = List<ClassColumn?>.filled(list.length, null);
  for (var k = 0; k < list.length; k++) {
    final sub = el.elementObject('columns', list, k);
    if (sub == null) continue;
    final subMark = sub.markStart();
    final id = _columnId(sub);
    final header = sub.name('header');
    final kind = sub.enumValue('kind', ClassColumnKind.fromJson);
    sub.close();
    if (sub.isClean(subMark) && id != null && header != null && kind != null) {
      values[k] = ClassColumn(id: id, header: header, kind: kind);
    }
    idStrings[k] = id?.value;
  }
  _reportDuplicates(el.problems, '${el.base}/columns', idStrings);
  if (el.problems.length != mark) return null;
  return [for (final value in values) value!];
}

/// A column or option id (FR-036, FR-061): the `ContentId` rule, so the
/// extension-type constructor cannot throw on a validated value (FR-094).
ClassColumnId? _columnId(_Element sub) =>
    _extensionTypeId(sub, ClassColumnId.new);

/// The shared read of an extension-type id: `invalidValue` at the key when
/// the value breaks the id rule.
T? _extensionTypeId<T>(_Element sub, T Function(String value) create) {
  final value = sub.string('id');
  if (value == null) return null;
  final parsed = ContentId.tryCreate(value);
  if (parsed is! ContentIdParsed) {
    sub.problems.add(
      ContentProblem('${sub.base}/id', ContentProblemKind.invalidValue),
    );
    return null;
  }
  return create(parsed.id.value);
}

/// A decoded Features-table row, with the raw facts the entry's cross-field
/// checks need: the row's level, its feature references and its raw
/// spellcasting part (content-classes.md FR-030 to FR-032, FR-037 to FR-045).
final class _ProgressionData {
  _ProgressionData(this.problems, this.base, this.refs, this.spellcasting);

  /// The entry's shared problem list, so the cross-field phase can append.
  final List<ContentProblem> problems;

  /// The row's JSON Pointer, e.g. `/classes/0/progression/3`.
  final String base;

  /// Adds a problem at `<base><suffix>` (the cross-field phase).
  void addProblem(String suffix, ContentProblemKind kind) =>
      problems.add(ContentProblem('$base$suffix', kind));

  /// The row's level, when the field holds a whole number.
  int? level;

  /// The Proficiency Bonus, when the field holds a whole number.
  int? proficiencyBonus;

  /// The row's feature references, in order.
  final List<_RowFeatureRef> refs;

  /// The row's constructed feature list, or null when it failed.
  List<RowFeature>? features;

  /// The row's raw spellcasting part, or null when the row has none.
  _RowSpellcastingRaw? spellcasting;

  /// The row's constructed column values, or null when they failed.
  Map<ClassColumnId, ColumnValue>? values;

  /// The constructed row, non-null when the row decoded cleanly and the
  /// spellcasting checks built its part.
  ProgressionRow? row;
}

/// One element of a row's `features` array (FR-043).
final class _RowFeatureRef {
  const _RowFeatureRef(this.index, this.featureId, this.isMarker);

  /// The element's index inside the row's `features`.
  final int index;

  /// The cited feature id, when it passed FR-030.
  final ContentId? featureId;

  /// Whether the element is a subclass marker.
  final bool isMarker;
}

/// The raw spellcasting part of one row (FR-030 to FR-032). The shape the
/// part must have is the class trait's, decided in the cross-field phase;
/// the field reads here only check types and presence.
final class _RowSpellcastingRaw {
  _RowSpellcastingRaw({
    required this.problems,
    required this.base,
    required this.broken,
    required this.cantripsPresent,
    this.cantrips,
    required this.preparedSpells,
    required this.spellSlotsPresent,
    this.spellSlots,
    required this.slotLevelPresent,
    this.slotLevel,
  });

  /// The entry's shared problem list, so the cross-field phase can append.
  final List<ContentProblem> problems;

  /// The part's JSON Pointer, e.g. `/classes/0/progression/3/spellcasting`.
  final String base;

  /// Adds a problem at `<base><suffix>` (the cross-field phase).
  void problemAt(String suffix, ContentProblemKind kind) =>
      problems.add(ContentProblem('$base$suffix', kind));

  /// Whether the part is not an object (its own problem exists).
  final bool broken;

  final bool cantripsPresent;
  final int? cantrips;
  final int? preparedSpells;
  final bool spellSlotsPresent;
  final Object? spellSlots;
  final bool slotLevelPresent;
  final int? slotLevel;

  /// The row part built by the spellcasting checks, non-null when the part
  /// matched the class trait and all its values are readable.
  SpellcastingRow? builtRow;
}

/// A class element's `progression` (FR-037): exactly [ClassDefinition.rowCount]
/// rows, row `i` carrying level `i + 1`.
List<_ProgressionData?>? _progression(_Element el, List<ClassColumn>? columns) {
  final list = el.array('progression');
  if (list == null) return null;
  final rows = List<_ProgressionData?>.filled(list.length, null);
  for (var i = 0; i < list.length; i++) {
    final sub = el.elementObject('progression', list, i);
    if (sub == null) continue;
    rows[i] = _progressionRow(sub, i, columns);
  }
  if (list.length != ClassDefinition.rowCount) {
    el.problems.add(
      ContentProblem('${el.base}/progression', ContentProblemKind.outOfRange),
    );
    return null;
  }
  return rows;
}

_ProgressionData? _progressionRow(
  _Element sub,
  int index,
  List<ClassColumn>? columns,
) {
  final data = _ProgressionData(sub.problems, sub.base, [], null);
  final mark = sub.markStart();
  final level = sub.wholeInt(
    'level',
    min: -JsonContentSetDecoder.maxSafeInteger,
    max: JsonContentSetDecoder.maxSafeInteger,
  );
  // FR-037: the level is the position plus one.
  if (level != null && level != index + 1) {
    sub.problems.add(
      ContentProblem('${sub.base}/level', ContentProblemKind.invalidValue),
    );
  }
  data.level = level;
  data.proficiencyBonus = sub.wholeInt(
    'proficiencyBonus',
    min: ProgressionRow.minProficiencyBonus,
  );
  final features = _rowFeatures(sub);
  data.refs.addAll(features?.refs ?? const []);
  data.features = features?.row;
  data.spellcasting = _rawRowSpellcasting(sub);
  data.values = _rowValues(sub, columns);
  sub.close();
  if (!sub.isClean(mark)) {
    // The row's own fields failed; the spellcasting checks still run over
    // the readable raw part (FR-012), but the row cannot be built.
    data.features = null;
    data.values = null;
  }
  return data;
}

/// Builds every row's [ProgressionRow] once the spellcasting checks have
/// decided each row part's variant (content-classes.md FR-030 to FR-032).
void _buildRows(List<_ProgressionData?>? progression) {
  if (progression == null) return;
  for (final row in progression) {
    if (row == null) continue;
    if (row.level == null ||
        row.proficiencyBonus == null ||
        row.features == null ||
        row.values == null) {
      continue;
    }
    final spellcasting = row.spellcasting;
    if (spellcasting != null && spellcasting.broken) continue;
    if (spellcasting != null && spellcasting.builtRow == null) continue;
    row.row = ProgressionRow(
      level: row.level!,
      proficiencyBonus: row.proficiencyBonus!,
      features: row.features!,
      spellcasting: spellcasting?.builtRow,
      values: row.values!,
    );
  }
}

/// A row's `features` (FR-043): {featureId, annotation?} references and
/// {"kind": "subclassFeature"} markers, at most one marker (a repeat
/// `duplicate` at the later marker's element).
({List<_RowFeatureRef> refs, List<RowFeature>? row})? _rowFeatures(
  _Element sub,
) {
  final list = sub.array('features');
  if (list == null) return null;
  final mark = sub.markStart();
  final refs = <_RowFeatureRef>[];
  final values = List<RowFeature?>.filled(list.length, null);
  final markers = <int>[];
  for (var k = 0; k < list.length; k++) {
    final element = sub.elementObject('features', list, k);
    if (element == null) continue;
    if (element.has('kind')) {
      final kind = element.string('kind');
      if (kind == 'subclassFeature') {
        // A marker carries no other key (FR-043).
        for (final key in const ['featureId', 'annotation']) {
          if (element.has(key)) {
            element.problems.add(
              ContentProblem(
                '${element.base}/$key',
                ContentProblemKind.constraintViolation,
              ),
            );
          }
          element.mark(key);
        }
        refs.add(_RowFeatureRef(k, null, true));
        values[k] = const RowSubclassFeature();
        markers.add(k);
      } else {
        if (kind != null) {
          element.problems.add(
            ContentProblem(
              '${element.base}/kind',
              ContentProblemKind.invalidValue,
            ),
          );
        }
        element.mark('featureId');
        element.mark('annotation');
      }
      element.close();
      continue;
    }
    final id = element.id('featureId');
    final annotation = element.optionalText('annotation');
    element.close();
    if (id != null) refs.add(_RowFeatureRef(k, id, false));
    if (id != null &&
        (annotation == null || RowClassFeature.isValidAnnotation(annotation))) {
      values[k] = RowClassFeature(FeatureId.of(id), annotation: annotation);
    }
  }
  if (markers.length > 1) {
    sub.problems.add(
      ContentProblem(
        '${sub.base}/features/${markers[1]}',
        ContentProblemKind.duplicate,
      ),
    );
  }
  if (sub.problems.length != mark) return (refs: refs, row: null);
  return (refs: refs, row: [for (final value in values) value!]);
}

/// A row's raw `spellcasting` part (FR-030 to FR-032): types and presence
/// here; which shape the part must have is the cross-field phase's.
_RowSpellcastingRaw? _rawRowSpellcasting(_Element row) {
  row.mark('spellcasting');
  if (!row.has('spellcasting')) return null;
  final base = '${row.base}/spellcasting';
  final value = row.map['spellcasting'];
  if (value is! Map<String, Object?>) {
    row.problems.add(ContentProblem(base, ContentProblemKind.wrongType));
    return _RowSpellcastingRaw(
      problems: row.problems,
      base: base,
      broken: true,
      cantripsPresent: false,
      preparedSpells: null,
      spellSlotsPresent: false,
      spellSlots: null,
      slotLevelPresent: false,
      slotLevel: null,
    );
  }
  final sub = _Element(row.problems, base, value);
  final cantripsPresent = sub.has('cantrips');
  sub.mark('cantrips');
  final cantrips = cantripsPresent
      ? sub.wholeInt(
          'cantrips',
          min: 0,
          max: JsonContentSetDecoder.maxSafeInteger,
        )
      : null;
  final preparedSpells = sub.wholeInt(
    'preparedSpells',
    min: SlotSpellcastingRow.minSlots,
  );
  final spellSlotsPresent = sub.has('spellSlots');
  sub.mark('spellSlots');
  if (!spellSlotsPresent) {
    sub.problems.add(
      ContentProblem('$base/spellSlots', ContentProblemKind.missingField),
    );
  }
  final spellSlots = spellSlotsPresent ? sub.map['spellSlots'] : null;
  final slotLevelPresent = sub.has('slotLevel');
  sub.mark('slotLevel');
  final slotLevel = slotLevelPresent
      ? sub.wholeInt(
          'slotLevel',
          min: -JsonContentSetDecoder.maxSafeInteger,
          max: JsonContentSetDecoder.maxSafeInteger,
        )
      : null;
  sub.close();
  return _RowSpellcastingRaw(
    problems: row.problems,
    base: base,
    broken: false,
    cantripsPresent: cantripsPresent,
    cantrips: cantrips,
    preparedSpells: preparedSpells,
    spellSlotsPresent: spellSlotsPresent,
    spellSlots: spellSlots,
    slotLevelPresent: slotLevelPresent,
    slotLevel: slotLevel,
  );
}

/// A row's `values` (FR-039, FR-040): one value per declared column,
/// declared keys first, then unknown keys in ordinal order.
Map<ClassColumnId, ColumnValue>? _rowValues(
  _Element sub,
  List<ClassColumn>? columns,
) {
  final obj = sub.object('values');
  if (obj == null) return null;
  if (columns == null) {
    // The columns field failed; no key can be judged, and the entry is
    // dirty anyway (FR-013).
    for (final key in obj.map.keys) {
      obj.mark(key);
    }
    obj.close();
    return null;
  }
  final mark = obj.markStart();
  final values = <ClassColumnId, ColumnValue>{};
  for (final column in columns) {
    final value = _columnValue(obj, column);
    if (value != null) values[column.id] = value;
  }
  obj.close();
  if (obj.problems.length != mark) return null;
  return values;
}

/// One column value (FR-040): the printed em dash is `ColumnNone` under
/// every kind; otherwise the value must suit the declared kind.
ColumnValue? _columnValue(_Element obj, ClassColumn column) {
  final key = column.id.value;
  obj.mark(key);
  if (!obj.has(key)) {
    obj.problems.add(
      ContentProblem('${obj.base}/$key', ContentProblemKind.missingField),
    );
    return null;
  }
  final raw = obj.map[key];
  final path = '${obj.base}/$key';
  if (raw is String) {
    if (raw == _emDash) return const ColumnNone();
    // The case rows distinguish a mistyped number ("2" is wrongType: the
    // JSON type does not suit the kind) from a bad em-dash spelling
    // ("-" is invalidValue under every kind).
    final numeric = RegExp(r'^-?[0-9]+$').hasMatch(raw);
    obj.problems.add(
      ContentProblem(
        path,
        numeric
            ? ContentProblemKind.wrongType
            : ContentProblemKind.invalidValue,
      ),
    );
    return null;
  }
  switch (column.kind) {
    case ClassColumnKind.count:
      final value = _wholeAt(
        obj.problems,
        path,
        raw,
        min: ColumnCount.minValue,
      );
      return value == null ? null : ColumnCount(value);
    case ClassColumnKind.dice:
      if (raw is! Map<String, Object?>) {
        obj.problems.add(ContentProblem(path, ContentProblemKind.wrongType));
        return null;
      }
      final dice = _Element(obj.problems, path, raw);
      final count = dice.wholeInt('count', min: ColumnDice.minCount);
      final sides = dice.wholeInt(
        'sides',
        min: Die.minSides,
        max: Die.maxSides,
      );
      dice.close();
      if (count == null || sides == null) return null;
      return ColumnDice(count, sides);
    case ClassColumnKind.bonus:
      final value = _wholeAt(
        obj.problems,
        path,
        raw,
        min: ColumnBonus.minValue,
      );
      return value == null ? null : ColumnBonus(value);
    case ClassColumnKind.feetBonus:
      final value = _wholeAt(
        obj.problems,
        path,
        raw,
        min: -JsonContentSetDecoder.maxSafeInteger,
      );
      return value == null ? null : ColumnFeetBonus(value);
  }
}

/// The printed em dash a column value or a feature cell may hold (D7).
const String _emDash = '—';

/// A whole number in `[min, max]` at an explicit [path] (FR-021, FR-023);
/// a null `max` means no upper bound.
int? _wholeAt(
  List<ContentProblem> problems,
  String path,
  Object? raw, {
  required int min,
  int? max,
}) {
  final whole = _wholeNumber(raw);
  if (whole == null) {
    problems.add(ContentProblem(path, ContentProblemKind.wrongType));
    return null;
  }
  if (whole.outOfSafeRange) {
    problems.add(ContentProblem(path, ContentProblemKind.outOfRange));
    return null;
  }
  if (whole.value < min || (max != null && whole.value > max)) {
    problems.add(ContentProblem(path, ContentProblemKind.outOfRange));
    return null;
  }
  return whole.value;
}

/// A decoded feature entry of a class or subclass (content-classes.md
/// FR-051 to FR-067), with the raw facts the entry's cross-field checks
/// need even when the entry itself failed (FR-095).
final class _FeatureData {
  const _FeatureData({
    required this.elementBase,
    required this.id,
    required this.level,
    required this.facts,
    required this.factsComplete,
    required this.carriesSubclassFact,
    required this.entry,
  });

  /// The element's JSON Pointer, e.g. `/classes/0/features/2`.
  final String elementBase;

  /// The id, when it passed FR-030.
  final ContentId? id;

  /// The whole level, when readable.
  final int? level;

  /// The constructed facts.
  final List<FeatureFact> facts;

  /// Whether the `facts` field was absent or decoded cleanly, so the
  /// FR-056 carrier count can be trusted.
  final bool factsComplete;

  /// Whether the facts hold a `GrantsSubclass`.
  final bool carriesSubclassFact;

  /// The constructed entry, non-null when the element decoded cleanly.
  final FeatureEntry? entry;
}

/// A class element's `features` (FR-051).
List<_FeatureData?>? _classFeatures(_Element el) {
  final list = el.array('features');
  if (list == null) return null;
  final values = List<_FeatureData?>.filled(list.length, null);
  for (var k = 0; k < list.length; k++) {
    final sub = el.elementObject('features', list, k);
    if (sub == null) continue;
    values[k] = _featureEntry(sub);
  }
  return values;
}

/// One feature entry (FR-051 to FR-066): `id`, `name`, `level` (1 to 20),
/// `text`, and the optional `facts`, `options` and `tables`. The owner
/// prefix is the entry's cross-field phase, which holds the owner
/// (content-classes.md D11).
_FeatureData _featureEntry(_Element sub) {
  final mark = sub.markStart();
  final id = sub.id('id');
  final name = sub.name('name');
  final level = sub.wholeInt(
    'level',
    min: FeatureEntry.minLevel,
    max: FeatureEntry.maxLevel,
  );
  final text = sub.text('text');
  final facts = _optionalFacts(sub, ownerLevel: level);
  final options = _featureOptions(sub, ownerLevel: level);
  final tables = _featureTables(sub);
  sub.close();
  FeatureEntry? entry;
  if (sub.isClean(mark) &&
      id != null &&
      name != null &&
      level != null &&
      text != null &&
      facts.clean &&
      options.clean &&
      tables.clean) {
    entry = FeatureEntry(
      id: FeatureId.of(id),
      name: name,
      level: level,
      text: text,
      facts: facts.items,
      options: options.items,
      tables: tables.items,
    );
  }
  return _FeatureData(
    elementBase: sub.base,
    id: id,
    level: level,
    facts: facts.items,
    factsComplete: facts.clean,
    carriesSubclassFact: facts.items.any(
      (FeatureFact fact) => fact is GrantsSubclass,
    ),
    entry: entry,
  );
}

/// The decoded items of one optional array, with whether the read was
/// clean: the facts, options and tables of a feature entry.
final class _DecodedList<T> {
  const _DecodedList(this.items, {required this.clean});

  final List<T> items;
  final bool clean;
}

/// A feature's optional `facts` (content-classes.md FR-055): {kind:
/// "grantsSubclass"} | {kind: "grantsFeat", category} |
/// {kind: "alwaysPreparedSpells", grants}; distinct on one entry (a repeat
/// `duplicate` at the later fact). A grant's level must be from 1 to 20,
/// strictly ascending, and at least the owning entry's level (FR-058).
_DecodedList<FeatureFact> _optionalFacts(
  _Element sub, {
  required int? ownerLevel,
}) {
  final list = sub.optionalArray('facts');
  if (list == null) return const _DecodedList([], clean: true);
  final mark = sub.markStart();
  final facts = List<FeatureFact?>.filled(list.length, null);
  for (var k = 0; k < list.length; k++) {
    final element = sub.elementObject('facts', list, k);
    if (element == null) continue;
    facts[k] = _fact(element, ownerLevel);
  }
  // FR-055: the facts on one entry are distinct.
  for (var k = 1; k < facts.length; k++) {
    final fact = facts[k];
    if (fact == null) continue;
    if (facts.sublist(0, k).contains(fact)) {
      sub.problems.add(
        ContentProblem('${sub.base}/facts/$k', ContentProblemKind.duplicate),
      );
    }
  }
  final clean = sub.problems.length == mark;
  return _DecodedList<FeatureFact>(
    clean ? [for (final fact in facts) fact!] : const [],
    clean: clean,
  );
}

FeatureFact? _fact(_Element element, int? ownerLevel) {
  final mark = element.markStart();
  final kind = element.string('kind');
  final fact = switch (kind) {
    'grantsSubclass' => _grantsSubclassFact(element),
    'grantsFeat' => _grantsFeatFact(element),
    'alwaysPreparedSpells' => _preparedSpellsFact(element, ownerLevel),
    null => null,
    _ => _unknownFactKind(element),
  };
  element.close();
  if (!element.isClean(mark)) return null;
  return fact;
}

FeatureFact _grantsSubclassFact(_Element element) {
  element.mark('category');
  element.mark('grants');
  return const GrantsSubclass();
}

FeatureFact? _grantsFeatFact(_Element element) {
  final category = element.enumValue('category', FeatCategory.fromJson);
  element.mark('grants');
  return category == null ? null : GrantsFeat(category);
}

FeatureFact? _preparedSpellsFact(_Element element, int? ownerLevel) {
  final grants = _spellGrants(element, ownerLevel);
  element.mark('category');
  if (grants == null) return null;
  return AlwaysPreparedSpells(grants);
}

FeatureFact? _unknownFactKind(_Element element) {
  element.problems.add(
    ContentProblem('${element.base}/kind', ContentProblemKind.invalidValue),
  );
  element.mark('category');
  element.mark('grants');
  return null;
}

/// An `AlwaysPreparedSpells` fact's `grants` (FR-058): non-empty, levels
/// from 1 to 20 strictly ascending and at least the owner's, spell ids
/// non-empty and distinct.
List<SpellGrant>? _spellGrants(_Element element, int? ownerLevel) {
  final list = element.array('grants');
  if (list == null) return null;
  if (list.length < AlwaysPreparedSpells.minGrants) {
    element.problems.add(
      ContentProblem('${element.base}/grants', ContentProblemKind.outOfRange),
    );
    return null;
  }
  final mark = element.markStart();
  final values = List<SpellGrant?>.filled(list.length, null);
  final levels = List<int?>.filled(list.length, null);
  for (var k = 0; k < list.length; k++) {
    final sub = element.elementObject('grants', list, k);
    if (sub == null) continue;
    final level = sub.wholeInt(
      'level',
      min: SpellGrant.minLevel,
      max: SpellGrant.maxLevel,
    );
    levels[k] = level;
    final spellIds = _spellIdList(sub);
    sub.close();
    if (level != null && spellIds != null) {
      values[k] = SpellGrant(level, spellIds);
    }
  }
  // FR-058: strictly ascending levels, each at least the owner's.
  for (var k = 0; k < levels.length; k++) {
    final level = levels[k];
    if (level == null) continue;
    if (k > 0 && levels[k - 1] != null && level <= levels[k - 1]!) {
      element.problems.add(
        ContentProblem(
          '${element.base}/grants/$k/level',
          ContentProblemKind.invalidValue,
        ),
      );
    }
    if (ownerLevel != null && level < ownerLevel) {
      element.problems.add(
        ContentProblem(
          '${element.base}/grants/$k/level',
          ContentProblemKind.invalidValue,
        ),
      );
    }
  }
  if (element.problems.length != mark) return null;
  return [for (final value in values) value!];
}

/// An array of distinct valid spell id strings (FR-058): empty is
/// `outOfRange` at the array.
List<SpellId>? _spellIdList(_Element sub) {
  final list = sub.array('spellIds');
  if (list == null) return null;
  if (list.isEmpty) {
    sub.problems.add(
      ContentProblem('${sub.base}/spellIds', ContentProblemKind.outOfRange),
    );
    return null;
  }
  final mark = sub.markStart();
  final values = List<SpellId?>.filled(list.length, null);
  final strings = List<String?>.filled(list.length, null);
  for (var k = 0; k < list.length; k++) {
    final value = list[k];
    if (value is! String) {
      sub.problems.add(
        ContentProblem('${sub.base}/spellIds/$k', ContentProblemKind.wrongType),
      );
      continue;
    }
    final parsed = ContentId.tryCreate(value);
    if (parsed is! ContentIdParsed) {
      sub.problems.add(
        ContentProblem(
          '${sub.base}/spellIds/$k',
          ContentProblemKind.invalidValue,
        ),
      );
      continue;
    }
    strings[k] = value;
    values[k] = SpellId.of(parsed.id);
  }
  _reportDuplicates(sub.problems, '${sub.base}/spellIds', strings);
  if (sub.problems.length != mark) return null;
  return [for (final value in values) value!];
}

/// One required option id of a prerequisite, with its own index (FR-062).
final class _RequiredOption {
  const _RequiredOption(this.index, this.id);

  final int index;
  final ContentId? id;
}

/// One option's decoded `prerequisite` (FR-062).
final class _PrerequisiteData {
  const _PrerequisiteData(this.base, this.requires);

  /// The prerequisite object's JSON Pointer.
  final String base;

  final List<_RequiredOption> requires;
}

/// A feature's optional `options` (FR-061): {id, name, text,
/// prerequisite?, pointCost?, repeatable?, facts?}; ids unique within the
/// feature (`duplicate` at the later id); an option carries only
/// `AlwaysPreparedSpells` facts (FR-064); a prerequisite names other
/// options of the same feature, never itself, and never forms a cycle
/// (FR-062).
_DecodedList<FeatureOption> _featureOptions(
  _Element sub, {
  required int? ownerLevel,
}) {
  final list = sub.optionalArray('options');
  if (list == null) {
    return const _DecodedList([], clean: true);
  }
  final mark = sub.markStart();
  final idStrings = List<String?>.filled(list.length, null);
  final values = List<FeatureOption?>.filled(list.length, null);
  final prerequisites = <({int optionIndex, _PrerequisiteData prerequisite})>[];
  for (var k = 0; k < list.length; k++) {
    final element = sub.elementObject('options', list, k);
    if (element == null) continue;
    final elementMark = element.markStart();
    var idString = element.string('id');
    FeatureOptionId? id;
    if (idString != null) {
      final parsed = ContentId.tryCreate(idString);
      if (parsed is! ContentIdParsed) {
        element.problems.add(
          ContentProblem('${element.base}/id', ContentProblemKind.invalidValue),
        );
        idString = null;
      } else {
        id = FeatureOptionId(parsed.id.value);
        idStrings[k] = id.value;
      }
    }
    final name = element.name('name');
    final text = element.text('text');
    final prerequisite = _optionPrerequisite(element);
    final pointCost = element.optionalWholeInt(
      'pointCost',
      min: FeatureOption.minPointCost,
      max: JsonContentSetDecoder.maxSafeInteger,
    );
    // FR-063: repeatable, when present, MUST be true.
    element.mark('repeatable');
    var repeatable = false;
    if (element.has('repeatable')) {
      final value = element.map['repeatable'];
      if (value is! bool) {
        element.problems.add(
          ContentProblem(
            '${element.base}/repeatable',
            ContentProblemKind.wrongType,
          ),
        );
      } else if (!value) {
        element.problems.add(
          ContentProblem(
            '${element.base}/repeatable',
            ContentProblemKind.invalidValue,
          ),
        );
      } else {
        repeatable = true;
      }
    }
    final facts = _optionalFacts(element, ownerLevel: ownerLevel);
    // FR-064: an option carries only AlwaysPreparedSpells facts.
    for (var f = 0; f < facts.items.length; f++) {
      if (facts.items[f] is! AlwaysPreparedSpells) {
        element.problems.add(
          ContentProblem(
            '${element.base}/facts/$f',
            ContentProblemKind.constraintViolation,
          ),
        );
      }
    }
    element.close();
    if (element.isClean(elementMark) &&
        id != null &&
        name != null &&
        text != null &&
        facts.clean) {
      values[k] = FeatureOption(
        id: id,
        name: name,
        text: text,
        prerequisite: prerequisite?.built,
        pointCost: pointCost,
        repeatable: repeatable,
        facts: facts.items,
      );
    }
    if (prerequisite != null) {
      prerequisites.add((optionIndex: k, prerequisite: prerequisite.data));
    }
  }
  _reportDuplicates(
    sub.problems,
    '${sub.base}/options',
    idStrings,
    suffix: '/id',
  );
  _checkPrerequisiteReferences(sub, idStrings, prerequisites);
  final clean = sub.problems.length == mark;
  return _DecodedList<FeatureOption>(
    clean ? [for (final value in values) value!] : const [],
    clean: clean,
  );
}

/// One option's `prerequisite` (FR-062): `minClassLevel`? (1 to 20),
/// `requiresOptionIds`?, `note`? — at least one part present.
({_PrerequisiteData data, OptionPrerequisite built})? _optionPrerequisite(
  _Element element,
) {
  final sub = element.optionalObject('prerequisite');
  if (sub == null) return null;
  final mark = sub.markStart();
  final hasMin = sub.has('minClassLevel');
  sub.optionalWholeInt(
    'minClassLevel',
    min: ProgressionRow.minLevel,
    max: ProgressionRow.maxLevel,
  );
  final hasIds = sub.has('requiresOptionIds');
  final requires = <_RequiredOption>[];
  final ids = sub.optionalArray('requiresOptionIds');
  if (ids != null) {
    for (var i = 0; i < ids.length; i++) {
      final value = ids[i];
      if (value is! String) {
        sub.problems.add(
          ContentProblem(
            '${sub.base}/requiresOptionIds/$i',
            ContentProblemKind.wrongType,
          ),
        );
        continue;
      }
      final parsed = ContentId.tryCreate(value);
      if (parsed is! ContentIdParsed) {
        sub.problems.add(
          ContentProblem(
            '${sub.base}/requiresOptionIds/$i',
            ContentProblemKind.invalidValue,
          ),
        );
        continue;
      }
      requires.add(_RequiredOption(i, parsed.id));
    }
  }
  final note = sub.optionalText('note');
  sub.close();
  if (!hasMin && !(hasIds && requires.isNotEmpty) && note == null) {
    sub.problems.add(
      ContentProblem(sub.base, ContentProblemKind.constraintViolation),
    );
  }
  if (!sub.isClean(mark)) return null;
  return (
    data: _PrerequisiteData(sub.base, requires),
    built: OptionPrerequisite(
      minClassLevel: hasMin ? sub.map['minClassLevel'] as int : null,
      requiresOptionIds: [
        for (final required in requires) FeatureOptionId(required.id!.value),
      ],
      note: note,
    ),
  );
}

/// The FR-062 cross-option rules: a prerequisite names other options of the
/// same feature (unresolvedReference), never itself (constraintViolation),
/// and the references form no cycle (constraintViolation at the edge that
/// closes one).
void _checkPrerequisiteReferences(
  _Element sub,
  List<String?> idStrings,
  List<({int optionIndex, _PrerequisiteData prerequisite})> prerequisites,
) {
  final idSet = {for (final id in idStrings) ?id};
  for (final (:optionIndex, :prerequisite) in prerequisites) {
    final ownId = optionIndex < idStrings.length
        ? idStrings[optionIndex]
        : null;
    for (final required in prerequisite.requires) {
      final id = required.id;
      if (id == null) continue;
      final path = '${prerequisite.base}/requiresOptionIds/${required.index}';
      if (ownId != null && id.value == ownId) {
        sub.problems.add(
          ContentProblem(path, ContentProblemKind.constraintViolation),
        );
      } else if (!idSet.contains(id.value)) {
        sub.problems.add(
          ContentProblem(path, ContentProblemKind.unresolvedReference),
        );
      }
    }
  }
  // Depth-first search over the requires edges; the first edge that
  // revisits a node on the current path closes a cycle (FR-062).
  final edges = <String, List<(String, String)>>{
    for (final (:optionIndex, :prerequisite) in prerequisites)
      if (optionIndex < idStrings.length && idStrings[optionIndex] != null)
        idStrings[optionIndex]!: [
          for (final required in prerequisite.requires)
            if (required.id != null &&
                required.id!.value != idStrings[optionIndex] &&
                idSet.contains(required.id!.value))
              (
                '${prerequisite.base}/requiresOptionIds/${required.index}',
                required.id!.value,
              ),
        ],
  };
  final visiting = <String>{};
  final visited = <String>{};
  var cycleReported = false;

  void visit(String id) {
    if (cycleReported || visited.contains(id)) return;
    if (!visiting.add(id)) return;
    for (final (path, target) in edges[id] ?? const <(String, String)>[]) {
      if (visiting.contains(target)) {
        sub.problems.add(
          ContentProblem(path, ContentProblemKind.constraintViolation),
        );
        cycleReported = true;
        return;
      }
      visit(target);
    }
    visiting.remove(id);
    visited.add(id);
  }

  for (final id in edges.keys) {
    visit(id);
  }
}

/// A feature's optional `tables` (content-classes.md FR-066, FR-067):
/// {name, columns, rows}; rows as wide as the header (`outOfRange` at the
/// row), every cell a string or a whole number, every column consistent in
/// kind (`wrongType` at the first deviating cell).
_DecodedList<FeatureTable> _featureTables(_Element sub) {
  final list = sub.optionalArray('tables');
  if (list == null) return const _DecodedList([], clean: true);
  final mark = sub.markStart();
  final values = List<FeatureTable?>.filled(list.length, null);
  for (var k = 0; k < list.length; k++) {
    final element = sub.elementObject('tables', list, k);
    if (element == null) continue;
    final elementMark = element.markStart();
    final name = element.name('name');
    final columns = _distinctTexts(
      element,
      'columns',
      isValid: NamedText.isValidName,
    );
    final rows = _tableRows(element, columns);
    element.close();
    if (element.isClean(elementMark) &&
        name != null &&
        columns != null &&
        rows != null) {
      values[k] = FeatureTable(name: name, columns: columns, rows: rows);
    }
  }
  final clean = sub.problems.length == mark;
  return _DecodedList<FeatureTable>(
    clean ? [for (final value in values) value!] : const [],
    clean: clean,
  );
}

List<List<TableCell>>? _tableRows(_Element element, List<String>? columns) {
  final list = element.array('rows');
  if (list == null) return null;
  if (list.length < FeatureTable.minRows) {
    element.problems.add(
      ContentProblem('${element.base}/rows', ContentProblemKind.outOfRange),
    );
    return null;
  }
  final mark = element.markStart();
  var failed = false;
  final rows = List<List<TableCell>?>.filled(list.length, null);
  for (var r = 0; r < list.length; r++) {
    final raw = list[r];
    final path = '${element.base}/rows/$r';
    if (raw is! List<Object?>) {
      element.problems.add(ContentProblem(path, ContentProblemKind.wrongType));
      failed = true;
      continue;
    }
    if (columns != null && raw.length != columns.length) {
      element.problems.add(ContentProblem(path, ContentProblemKind.outOfRange));
      failed = true;
      continue;
    }
    final cells = <TableCell>[];
    var rowFailed = false;
    for (var c = 0; c < raw.length; c++) {
      final cell = raw[c];
      if (cell is String) {
        if (!NamedText.isValidText(cell)) {
          element.problems.add(
            ContentProblem('$path/$c', ContentProblemKind.invalidValue),
          );
          rowFailed = true;
          continue;
        }
        cells.add(TableCellText(cell));
      } else {
        final value = _wholeAt(
          element.problems,
          '$path/$c',
          cell,
          min: -JsonContentSetDecoder.maxSafeInteger,
        );
        if (value == null) {
          rowFailed = true;
          continue;
        }
        cells.add(TableCellInt(value));
      }
    }
    rows[r] = rowFailed ? null : cells;
    if (rowFailed) failed = true;
  }
  // Every column consistent in kind: all text or all integers (FR-066);
  // the first deviating cell is the problem (FR-066).
  if (columns != null && !failed) {
    for (var r = 1; r < rows.length && !failed; r++) {
      for (var c = 0; c < columns.length; c++) {
        final first = rows[0]?[c];
        final cell = rows[r]?[c];
        if (first == null || cell == null) continue;
        if (first.runtimeType != cell.runtimeType) {
          element.problems.add(
            ContentProblem(
              '${element.base}/rows/$r/$c',
              ContentProblemKind.wrongType,
            ),
          );
          failed = true;
          break;
        }
      }
    }
  }
  if (failed || element.problems.length != mark) return null;
  return [for (final row in rows) row!];
}

/// A decoded subclass of one class element (content-classes.md FR-070 to
/// FR-073).
final class _SubclassData {
  const _SubclassData({
    required this.elementBase,
    required this.id,
    required this.features,
    required this.entry,
  });

  /// The element's JSON Pointer, e.g. `/classes/0/subclasses/0`.
  final String elementBase;

  final ContentId? id;

  /// The decoded features, for the FR-052 and FR-071 checks.
  final List<_FeatureData?> features;

  final SubclassDefinition? entry;
}

/// A class element's `subclasses` (FR-070): nested entries, each with at
/// least one feature.
List<_SubclassData?>? _subclassData(_Element el) {
  final list = el.array('subclasses');
  if (list == null) return null;
  final values = List<_SubclassData?>.filled(list.length, null);
  for (var k = 0; k < list.length; k++) {
    final sub = el.elementObject('subclasses', list, k);
    if (sub == null) continue;
    values[k] = _subclass(sub);
  }
  return values;
}

_SubclassData? _subclass(_Element sub) {
  final mark = sub.markStart();
  final id = sub.id('id');
  final name = sub.name('name');
  final source = sub.source();
  final list = sub.array('features');
  final features = List<_FeatureData?>.filled(list?.length ?? 0, null);
  if (list != null) {
    if (list.isEmpty) {
      sub.problems.add(
        ContentProblem('${sub.base}/features', ContentProblemKind.outOfRange),
      );
    }
    for (var k = 0; k < list.length; k++) {
      final element = sub.elementObject('features', list, k);
      if (element == null) continue;
      features[k] = _featureEntry(element);
    }
  }
  sub.close();
  SubclassDefinition? entry;
  if (sub.isClean(mark) && id != null && name != null && list != null) {
    final entries = <FeatureEntry>[
      for (final feature in features) ?feature?.entry,
    ];
    if (entries.length == features.length) {
      entry = SubclassDefinition(
        id: SubclassId.of(id),
        name: name,
        source: source,
        features: entries,
      );
    }
  }
  return _SubclassData(
    elementBase: sub.base,
    id: id,
    features: features,
    entry: entry,
  );
}

/// The spellcasting rows of one class entry (content-classes.md FR-030,
/// FR-031): every row carries the part that matches the class's trait; a
/// slot row carries `cantrips` exactly when the trait's flag is true; a
/// Pact row is Pact-shaped. A class whose `spellcasting` field failed
/// leaves its rows unjudged (FR-095); a row part that is not an object has
/// its own problem and is not judged again.
void _checkSpellcastingRows(
  List<_ProgressionData?>? progression,
  _SpellcastingData spellcasting,
) {
  if (progression == null || spellcasting.failed) return;
  final trait = spellcasting.trait;
  for (final row in progression) {
    if (row == null) continue;
    final part = row.spellcasting;
    if (part == null) {
      // FR-030: a missing part on a caster.
      if (trait != null) {
        row.addProblem('/spellcasting', ContentProblemKind.missingField);
      }
      continue;
    }
    if (part.broken) continue;
    if (trait == null) {
      // FR-030: a row part on a class with no spellcasting.
      row.addProblem('/spellcasting', ContentProblemKind.constraintViolation);
      continue;
    }
    final slots = trait is SlotSpellcastingTrait;
    if (part.slotLevelPresent == slots) {
      // FR-030: a row with the wrong variant for the class (`slotLevel`
      // marks a Pact part).
      row.addProblem('/spellcasting', ContentProblemKind.constraintViolation);
      continue;
    }
    if (slots) {
      _checkSlotRowPart(part, trait.cantrips);
    } else {
      _checkPactRowPart(part);
    }
  }
}

/// A slot row part (FR-031): `cantrips` present exactly when the class's
/// flag is true; `spellSlots` exactly nine non-negative integers. Builds
/// the row part when all its values are readable.
void _checkSlotRowPart(_RowSpellcastingRaw part, bool cantripsWanted) {
  if (cantripsWanted && !part.cantripsPresent) {
    part.problemAt('/cantrips', ContentProblemKind.missingField);
  } else if (!cantripsWanted && part.cantripsPresent) {
    part.problemAt('/cantrips', ContentProblemKind.constraintViolation);
  }
  final raw = part.spellSlots;
  if (raw is! List<Object?>) {
    part.problemAt('/spellSlots', ContentProblemKind.wrongType);
    return;
  }
  if (raw.length != SlotSpellcastingRow.slotCount) {
    part.problemAt('/spellSlots', ContentProblemKind.outOfRange);
    return;
  }
  final slots = <int?>[];
  var readable = part.cantripsPresent && part.cantrips != null;
  if (!part.cantripsPresent) readable = true;
  readable = readable && part.preparedSpells != null;
  for (var k = 0; k < raw.length; k++) {
    final value = _wholeAt(
      part.problems,
      '${part.base}/spellSlots/$k',
      raw[k],
      min: SlotSpellcastingRow.minSlots,
    );
    if (value == null) readable = false;
    slots.add(value);
  }
  if (!readable) return;
  part.builtRow = SlotSpellcastingRow(
    cantrips: part.cantripsPresent ? part.cantrips : null,
    preparedSpells: part.preparedSpells!,
    spellSlots: [for (final slot in slots) slot!],
  );
}

/// A Pact row part (FR-032): `cantrips`, `preparedSpells`, a slot count of
/// at least one and a slot level from 1 to 9. Builds the row part when all
/// its values are readable.
void _checkPactRowPart(_RowSpellcastingRaw part) {
  if (!part.cantripsPresent) {
    part.problemAt('/cantrips', ContentProblemKind.missingField);
  }
  final slots = _wholeAt(
    part.problems,
    '${part.base}/spellSlots',
    part.spellSlots,
    min: PactSpellcastingRow.minSlots,
  );
  final slotLevel = part.slotLevel;
  if (slotLevel != null && !PactSpellcastingRow.isValidSlotLevel(slotLevel)) {
    part.problemAt('/slotLevel', ContentProblemKind.outOfRange);
  }
  final readable =
      part.cantripsPresent &&
      part.cantrips != null &&
      part.preparedSpells != null &&
      slots != null &&
      slotLevel != null &&
      PactSpellcastingRow.isValidSlotLevel(slotLevel);
  if (!readable) return;
  part.builtRow = PactSpellcastingRow(
    cantrips: part.cantrips!,
    preparedSpells: part.preparedSpells!,
    spellSlots: slots,
    slotLevel: slotLevel,
  );
}

/// The progression references of one class entry (content-classes.md
/// FR-044, FR-045): every row `featureId` names a feature entry of the
/// same class (`unresolvedReference`) whose level does not exceed the
/// row's (`constraintViolation`), and every class feature entry is
/// referenced by the row at its own level (`constraintViolation` at the
/// entry's level). A feature entry counts as a target when its own id is
/// valid, even with other problems (FR-095).
void _checkProgressionReferences(
  _Element el,
  List<_ProgressionData?>? progression,
  List<_FeatureData?>? features,
) {
  if (progression == null || features == null) return;
  final idSet = <String>{};
  final levels = <String, int?>{};
  for (final feature in features) {
    final id = feature?.id;
    if (id == null) continue;
    idSet.add(id.value);
    levels[id.value] = feature!.level;
  }
  for (final row in progression) {
    if (row == null) continue;
    for (final ref in row.refs) {
      final id = ref.featureId;
      if (id == null) continue;
      final path = '${row.base}/features/${ref.index}/featureId';
      if (!idSet.contains(id.value)) {
        row.problems.add(
          ContentProblem(path, ContentProblemKind.unresolvedReference),
        );
      } else {
        final entryLevel = levels[id.value];
        if (entryLevel != null &&
            row.level != null &&
            entryLevel > row.level!) {
          row.problems.add(
            ContentProblem(path, ContentProblemKind.constraintViolation),
          );
        }
      }
    }
  }
  for (final feature in features) {
    if (feature == null) continue;
    final id = feature.id;
    final level = feature.level;
    if (id == null || level == null || !FeatureEntry.isValidLevel(level)) {
      continue;
    }
    if (level > progression.length) continue;
    final row = progression[level - 1];
    if (row == null) continue;
    final cited = row.refs.any(
      (ref) => !ref.isMarker && ref.featureId?.value == id.value,
    );
    if (!cited) {
      row.problems.add(
        ContentProblem(
          '${feature.elementBase}/level',
          ContentProblemKind.constraintViolation,
        ),
      );
    }
  }
}

/// The owner prefixes, the subclass feature and the subclass levels of one
/// class entry (content-classes.md FR-052, FR-056, FR-071, FR-072,
/// FR-073): every feature id is prefixed with its owner's id
/// (`constraintViolation` at the id); exactly one class feature carries
/// `GrantsSubclass` (`constraintViolation` at the class's `features`), and
/// its level is the subclass level every subclass feature starts at, with
/// one feature sitting exactly there.
void _checkSubclasses(
  _Element el,
  ContentId? classId,
  List<_FeatureData?>? features,
  List<_SubclassData?>? subclasses,
) {
  if (features == null) return;
  final subclassLevel = _subclassLevelOf(el, features);
  if (classId != null) {
    final prefix = '${classId.value}_';
    for (final feature in features) {
      final id = feature?.id;
      if (id == null) continue;
      if (!id.value.startsWith(prefix)) {
        el.problems.add(
          ContentProblem(
            '${feature!.elementBase}/id',
            ContentProblemKind.constraintViolation,
          ),
        );
      }
    }
  }
  if (subclasses == null) return;
  for (final subclass in subclasses) {
    if (subclass == null) continue;
    final subclassId = subclass.id;
    final prefix = subclassId == null ? null : '${subclassId.value}_';
    var atSubclassLevel = false;
    var hasFeature = false;
    var hasUnjudgeableLevel = false;
    for (final feature in subclass.features) {
      if (feature == null) continue;
      hasFeature = true;
      final id = feature.id;
      if (prefix != null && id != null && !id.value.startsWith(prefix)) {
        el.problems.add(
          ContentProblem(
            '${feature.elementBase}/id',
            ContentProblemKind.constraintViolation,
          ),
        );
      }
      final level = feature.level;
      if (level == null || !FeatureEntry.isValidLevel(level)) {
        hasUnjudgeableLevel = true;
      } else if (subclassLevel != null) {
        if (level < subclassLevel) {
          el.problems.add(
            ContentProblem(
              '${feature.elementBase}/level',
              ContentProblemKind.constraintViolation,
            ),
          );
        }
        if (level == subclassLevel) atSubclassLevel = true;
      }
      if (feature.carriesSubclassFact) {
        el.problems.add(
          ContentProblem(
            '${feature.elementBase}/facts',
            ContentProblemKind.constraintViolation,
          ),
        );
      }
    }
    if (hasFeature &&
        !hasUnjudgeableLevel &&
        subclassLevel != null &&
        !atSubclassLevel) {
      el.problems.add(
        ContentProblem(
          '${subclass.elementBase}/features',
          ContentProblemKind.constraintViolation,
        ),
      );
    }
  }
}

/// The level of the one `GrantsSubclass` carrier among the class features
/// (content-classes.md FR-056); null — with the FR-056 problem reported —
/// when the count is not exactly one, and null without a problem when any
/// feature's facts could not be read (FR-095).
int? _subclassLevelOf(_Element el, List<_FeatureData?> features) {
  // The count is decided on the readable facts, so a facts problem (a
  // duplicate, for example) does not hide the FR-056 verdict (FR-095).
  final carriers = [
    for (final feature in features)
      if (feature?.carriesSubclassFact ?? false) feature!,
  ];
  if (carriers.length != 1) {
    el.problems.add(
      ContentProblem(
        '${el.base}/features',
        ContentProblemKind.constraintViolation,
      ),
    );
    return null;
  }
  final level = carriers.single.level;
  if (level == null || !FeatureEntry.isValidLevel(level)) return null;
  return level;
}

/// The valid subclass ids of one class element's subclasses
/// (content-classes.md FR-004).
List<_NestedId> _nestedIds(List<_SubclassData?>? subclasses) {
  if (subclasses == null) return const [];
  final ids = <_NestedId>[];
  for (var k = 0; k < subclasses.length; k++) {
    final id = subclasses[k]?.id;
    if (id == null) continue;
    ids.add(
      _NestedId(
        subclassIndex: k,
        featureIndex: 0,
        id: id,
        path: 'subclasses/$k/id',
      ),
    );
  }
  return ids;
}

/// The valid feature ids of one class element — class features before
/// subclass features, in document order (content-classes.md FR-004).
List<_NestedId> _featureNestedIds(
  List<_FeatureData?>? features,
  List<_SubclassData?>? subclasses,
) {
  final ids = <_NestedId>[];
  if (features != null) {
    for (var k = 0; k < features.length; k++) {
      final id = features[k]?.id;
      if (id == null) continue;
      ids.add(
        _NestedId(
          subclassIndex: null,
          featureIndex: k,
          id: id,
          path: 'features/$k/id',
        ),
      );
    }
  }
  if (subclasses != null) {
    for (var k = 0; k < subclasses.length; k++) {
      final subclass = subclasses[k];
      if (subclass == null) continue;
      final subclassFeatures = subclass.features;
      for (var f = 0; f < subclassFeatures.length; f++) {
        final id = subclassFeatures[f]?.id;
        if (id == null) continue;
        ids.add(
          _NestedId(
            subclassIndex: k,
            featureIndex: f,
            id: id,
            path: 'subclasses/$k/features/$f/id',
          ),
        );
      }
    }
  }
  return ids;
}

// -- spells ------------------------------------------------------------------

/// One entry of `spells` (content-spells.md FR-107 to FR-113): the keys in
/// the declared order of FR-107 — `id`, `name`, `source?`, `level`,
/// `school`, `classes`, `castingTimes`, `ritual`, `range`, `components`,
/// `duration`, `description`, `higherLevel?`, `cantripUpgrade?` — each
/// sealed part carrying its `kind` discriminator (FR-108). The optional
/// `effects` key of FR-122 is read only when R2-spell-effects lands, so it
/// is `unknownField` until then. The `classes` entries are plain id
/// strings and no reference sites (FR-110).
_DecodedEntry _spell(_Element el) {
  final id = el.id('id');
  final name = el.name('name');
  final source = el.source();
  final level = el.wholeInt('level', min: SpellLevel.min, max: SpellLevel.max);
  final school = el.enumValue('school', SpellSchool.fromJson);
  final classes = _spellClasses(el);
  final castingTimes = _castingTimes(el);
  final ritual = el.boolean('ritual');
  final range = _spellRange(el);
  final components = _spellComponents(el);
  final duration = _spellDuration(el);
  final description = _blocks(el, 'description');
  final higherLevel = _optionalBlocks(el, 'higherLevel');
  final cantripUpgrade = _optionalBlocks(el, 'cantripUpgrade');
  // `effects` stays unmarked: close() reports it as unknownField while
  // R2-spell-effects has not landed (FR-022, FR-122).
  el.close();
  if (el.problems.isNotEmpty ||
      id == null ||
      name == null ||
      level == null ||
      school == null ||
      classes == null ||
      castingTimes == null ||
      ritual == null ||
      range == null ||
      components == null ||
      duration == null ||
      description == null) {
    return _DecodedEntry(id, null);
  }
  return _DecodedEntry(
    id,
    Spell(
      id: SpellId.of(id),
      name: name,
      source: source,
      level: SpellLevel(level),
      school: school,
      classes: classes,
      castingTimes: castingTimes,
      ritual: ritual,
      range: range,
      components: components,
      duration: duration,
      description: description,
      higherLevel: higherLevel,
      cantripUpgrade: cantripUpgrade,
    ),
  );
}

/// A spell's `classes` (content-spells.md FR-110): plain `ClassId`
/// strings of any length, a repeat `duplicate` at the later index.
Set<ClassId>? _spellClasses(_Element el) {
  final list = el.array('classes');
  if (list == null) return null;
  final mark = el.markStart();
  final ids = List<ContentId?>.filled(list.length, null);
  final strings = List<String?>.filled(list.length, null);
  for (var k = 0; k < list.length; k++) {
    final value = list[k];
    if (value is! String) {
      el.problems.add(
        ContentProblem('${el.base}/classes/$k', ContentProblemKind.wrongType),
      );
      continue;
    }
    final parsed = ContentId.tryCreate(value);
    if (parsed is! ContentIdParsed) {
      el.problems.add(
        ContentProblem(
          '${el.base}/classes/$k',
          ContentProblemKind.invalidValue,
        ),
      );
      continue;
    }
    ids[k] = parsed.id;
    strings[k] = value;
  }
  _reportDuplicates(el.problems, '${el.base}/classes', strings);
  if (el.problems.length != mark) return null;
  return {for (final id in ids) ClassId.of(id!)};
}

/// A spell's `castingTimes` (content-spells.md FR-030, FR-026 to FR-029):
/// one unlabelled casting time, or at least
/// [SpellCastingTimes.minModes] labelled modes; empty is `outOfRange` at
/// the array, a label on the only element `constraintViolation` at it.
SpellCastingTimes? _castingTimes(_Element el) {
  final list = el.array('castingTimes');
  if (list == null) return null;
  if (list.isEmpty) {
    el.problems.add(
      ContentProblem('${el.base}/castingTimes', ContentProblemKind.outOfRange),
    );
    return null;
  }
  final single = list.length < SpellCastingTimes.minModes;
  final mark = el.markStart();
  final times = List<CastingTime?>.filled(list.length, null);
  final labels = List<String?>.filled(list.length, null);
  for (var k = 0; k < list.length; k++) {
    final sub = el.elementObject('castingTimes', list, k);
    if (sub == null) continue;
    final subMark = sub.markStart();
    final kind = sub.string('kind');
    final time = switch (kind) {
      'magicAction' => _magicAction(sub),
      'bonusAction' => _bonusAction(sub),
      'reaction' => _reactionTime(sub),
      'minutes' => _durationAmount(sub, CastingTime.minutes),
      'hours' => _durationAmount(sub, CastingTime.hours),
      null => null,
      _ => _unknownCastingKind(sub),
    };
    if (single) {
      // FR-030: a single option carries no label.
      sub.mark('label');
      if (sub.has('label')) {
        sub.problems.add(
          ContentProblem(
            '${sub.base}/label',
            ContentProblemKind.constraintViolation,
          ),
        );
      }
    } else {
      labels[k] = sub.text('label');
    }
    sub.close();
    if (sub.isClean(subMark)) times[k] = time;
  }
  if (el.problems.length != mark) return null;
  final modes = [
    for (var k = 0; k < times.length; k++)
      times[k] == null
          ? null
          : (single ? null : CastingTimeMode(labels[k]!, times[k]!)),
  ];
  if (single) {
    return SpellCastingTimesSingle(times[0]!);
  }
  return SpellCastingTimesModes([for (final mode in modes) mode!]);
}

CastingTime _magicAction(_Element sub) {
  _forbiddenCastingKeys(sub, const ['amount', 'trigger']);
  return CastingTime.magicAction();
}

CastingTime? _bonusAction(_Element sub) {
  final trigger = sub.optionalString('trigger');
  if (trigger != null && !NamedText.isValidText(trigger)) {
    sub.problems.add(
      ContentProblem('${sub.base}/trigger', ContentProblemKind.invalidValue),
    );
  }
  _forbiddenCastingKeys(sub, const ['amount']);
  return trigger == null
      ? CastingTime.bonusAction()
      : CastingTime.bonusAction(trigger);
}

CastingTime? _reactionTime(_Element sub) {
  final trigger = sub.text('trigger');
  _forbiddenCastingKeys(sub, const ['amount']);
  return trigger == null ? null : CastingTime.reaction(trigger);
}

CastingTime? _durationAmount(_Element sub, CastingTime Function(int) create) {
  final amount = sub.wholeInt('amount', min: CastingTime.minAmount);
  _forbiddenCastingKeys(sub, const ['trigger']);
  return amount == null ? null : create(amount);
}

/// The data keys a casting-time kind must not carry (content-spells.md
/// FR-108): present where forbidden is `unknownField` at the key.
void _forbiddenCastingKeys(_Element sub, List<String> forbidden) {
  for (final key in forbidden) {
    if (sub.has(key)) {
      sub.problems.add(
        ContentProblem('${sub.base}/$key', ContentProblemKind.unknownField),
      );
    }
    sub.mark(key);
  }
}

CastingTime? _unknownCastingKind(_Element sub) {
  sub.problems.add(
    ContentProblem('${sub.base}/kind', ContentProblemKind.invalidValue),
  );
  sub.mark('amount');
  sub.mark('trigger');
  return null;
}

/// A spell's `range` (content-spells.md FR-036, FR-037): {kind, amount?,
/// unit?}; `amount` and `unit` belong to `distance` alone.
SpellRange? _spellRange(_Element el) {
  final sub = el.object('range');
  if (sub == null) return null;
  final mark = sub.markStart();
  final kind = sub.string('kind');
  final range = switch (kind) {
    'distance' => _distanceRange(sub),
    'self' => _plainRange(sub, SpellRange.self()),
    'touch' => _plainRange(sub, SpellRange.touch()),
    'sight' => _plainRange(sub, SpellRange.sight()),
    'unlimited' => _plainRange(sub, SpellRange.unlimited()),
    'special' => _plainRange(sub, SpellRange.special()),
    null => null,
    _ => _unknownRangeKind(sub),
  };
  sub.close();
  if (!sub.isClean(mark)) return null;
  return range;
}

SpellRange? _distanceRange(_Element sub) {
  final amount = sub.wholeInt('amount', min: SpellRange.minDistance);
  final unit = sub.enumValue('unit', DistanceUnit.fromJson);
  return amount == null || unit == null
      ? null
      : SpellRange.distance(amount, unit);
}

SpellRange _plainRange(_Element sub, SpellRange range) {
  _forbiddenCastingKeys(sub, const ['amount', 'unit']);
  return range;
}

SpellRange? _unknownRangeKind(_Element sub) {
  sub.problems.add(
    ContentProblem('${sub.base}/kind', ContentProblemKind.invalidValue),
  );
  sub.mark('amount');
  sub.mark('unit');
  return null;
}

/// A spell's `components` (content-spells.md FR-049, FR-041, FR-101):
/// {verbal, somatic, material?}; the material holds a non-blank
/// description, costs of at least [MaterialComponent.minCostGp] and the
/// consumption flag.
SpellComponents? _spellComponents(_Element el) {
  final sub = el.object('components');
  if (sub == null) return null;
  final mark = sub.markStart();
  final verbal = sub.boolean('verbal');
  final somatic = sub.boolean('somatic');
  final material = _materialComponent(sub);
  sub.close();
  if (!sub.isClean(mark) || verbal == null || somatic == null) return null;
  return SpellComponents(verbal: verbal, somatic: somatic, material: material);
}

MaterialComponent? _materialComponent(_Element sub) {
  final material = sub.optionalObject('material');
  if (material == null) return null;
  final mark = material.markStart();
  final description = material.text('description');
  final costs = _costList(material);
  final consumes = material.boolean('consumesMaterial');
  material.close();
  if (!material.isClean(mark) || description == null || consumes == null) {
    return null;
  }
  return MaterialComponent(
    description,
    costs ?? const [],
    consumesMaterial: consumes,
  );
}

List<int>? _costList(_Element material) {
  final list = material.optionalArray('costsGp');
  if (list == null) return const [];
  final mark = material.markStart();
  final values = List<int?>.filled(list.length, null);
  for (var k = 0; k < list.length; k++) {
    values[k] = _wholeAt(
      material.problems,
      '${material.base}/costsGp/$k',
      list[k],
      min: MaterialComponent.minCostGp,
    );
  }
  if (material.problems.length != mark) return null;
  return [for (final value in values) value!];
}

/// A spell's `duration` (content-spells.md FR-050 to FR-052): {kind,
/// amount?, unit?, limit?}; the three data keys belong to `timed` alone.
SpellDuration? _spellDuration(_Element el) {
  final sub = el.object('duration');
  if (sub == null) return null;
  final mark = sub.markStart();
  final kind = sub.string('kind');
  final duration = switch (kind) {
    'timed' => _timedDuration(sub),
    'instantaneous' => _plainDuration(sub, SpellDuration.instantaneous()),
    'untilDispelled' => _plainDuration(sub, SpellDuration.untilDispelled()),
    'untilDispelledOrTriggered' => _plainDuration(
      sub,
      SpellDuration.untilDispelledOrTriggered(),
    ),
    'special' => _plainDuration(sub, SpellDuration.special()),
    null => null,
    _ => _unknownDurationKind(sub),
  };
  sub.close();
  if (!sub.isClean(mark)) return null;
  return duration;
}

SpellDuration? _timedDuration(_Element sub) {
  final amount = sub.wholeInt('amount', min: SpellDuration.minAmount);
  final unit = sub.enumValue('unit', DurationUnit.fromJson);
  final limit = sub.enumValue('limit', DurationLimit.fromJson);
  return amount == null || unit == null || limit == null
      ? null
      : SpellDuration.timed(amount, unit, limit);
}

SpellDuration _plainDuration(_Element sub, SpellDuration duration) {
  _forbiddenCastingKeys(sub, const ['amount', 'unit', 'limit']);
  return duration;
}

SpellDuration? _unknownDurationKind(_Element sub) {
  sub.problems.add(
    ContentProblem('${sub.base}/kind', ContentProblemKind.invalidValue),
  );
  sub.mark('amount');
  sub.mark('unit');
  sub.mark('limit');
  return null;
}

// -- text blocks (schema FR-150 to FR-152) -----------------------------------

/// A required array of text blocks (content-schema-and-decoder.md FR-152,
/// FR-151); an empty array is `outOfRange` at the array (FR-058 of
/// content-spells.md for `description`).
List<ContentTextBlock>? _blocks(_Element el, String key) {
  final list = el.array(key);
  if (list == null) return null;
  return _decodedBlocks(el, key, list);
}

/// An optional array of text blocks; present-but-empty is `outOfRange`
/// (content-spells.md FR-102).
List<ContentTextBlock>? _optionalBlocks(_Element el, String key) {
  final list = el.optionalArray(key);
  if (list == null) return null;
  if (list.isEmpty) {
    el.problems.add(
      ContentProblem('${el.base}/$key', ContentProblemKind.outOfRange),
    );
    return null;
  }
  return _decodedBlocks(el, key, list);
}

List<ContentTextBlock>? _decodedBlocks(
  _Element el,
  String key,
  List<Object?> list,
) {
  if (list.isEmpty) {
    el.problems.add(
      ContentProblem('${el.base}/$key', ContentProblemKind.outOfRange),
    );
    return null;
  }
  final mark = el.markStart();
  final values = List<ContentTextBlock?>.filled(list.length, null);
  for (var k = 0; k < list.length; k++) {
    final sub = el.elementObject(key, list, k);
    if (sub == null) continue;
    values[k] = _textBlock(sub);
  }
  if (el.problems.length != mark) return null;
  return [for (final value in values) value!];
}

/// One text block (content-schema-and-decoder.md FR-152): a `kind`
/// discriminator — missing `missingField`, non-string `wrongType`, any
/// other value `invalidValue`, with no other key of the block examined —
/// then the variant's keys in wire order.
ContentTextBlock? _textBlock(_Element sub) {
  final mark = sub.markStart();
  final kind = sub.string('kind');
  final block = switch (kind) {
    'paragraph' => _paragraphBlock(sub),
    'entry' => _entryBlock(sub),
    'bulletList' => _bulletListBlock(sub),
    'table' => _tableBlock(sub),
    'embeddedStatBlock' => _statBlock(sub),
    // A missing or non-string kind has its own problem, an unknown string
    // kind is invalidValue; either way no other key of the block is
    // examined (FR-152).
    null => _unreadableBlockKind(sub),
    _ => _unknownBlockKind(sub),
  };
  sub.close();
  if (!sub.isClean(mark)) return null;
  return block;
}

ContentTextBlock? _paragraphBlock(_Element sub) {
  final text = sub.text('text');
  return text == null ? null : ContentTextBlock.paragraph(text);
}

ContentTextBlock? _entryBlock(_Element sub) {
  final name = sub.name('name');
  final text = sub.text('text');
  if (name == null || text == null) return null;
  return ContentTextBlock.entry(name, text);
}

ContentTextBlock? _bulletListBlock(_Element sub) {
  final items = _blockTexts(sub, 'items');
  if (items == null) return null;
  return ContentTextBlock.bulletList(items);
}

ContentTextBlock? _tableBlock(_Element sub) {
  final title = sub.optionalText('title');
  final header = _blockTexts(sub, 'header');
  final rows = _blockTableRows(sub, header);
  if (header == null || rows == null) return null;
  return ContentTextBlock.table(title: title, header: header, rows: rows);
}

ContentTextBlock? _statBlock(_Element sub) {
  final lines = _blockTexts(sub, 'lines');
  if (lines == null) return null;
  return ContentTextBlock.embeddedStatBlock(lines);
}

ContentTextBlock? _unknownBlockKind(_Element sub) {
  sub.problems.add(
    ContentProblem('${sub.base}/kind', ContentProblemKind.invalidValue),
  );
  _markAllBlockKeys(sub);
  return null;
}

/// The kind problem was already reported (missing or non-string); the
/// variant is unknowable, so every variant key is declared and nothing
/// else is examined (FR-152).
ContentTextBlock? _unreadableBlockKind(_Element sub) {
  _markAllBlockKeys(sub);
  return null;
}

void _markAllBlockKeys(_Element sub) {
  for (final key in const [
    'text',
    'name',
    'items',
    'title',
    'header',
    'rows',
    'lines',
  ]) {
    sub.mark(key);
  }
}

/// An array of non-blank strings (FR-152): empty is `outOfRange` at the
/// array, a blank item `invalidValue` and a non-string `wrongType` at the
/// element's index.
List<String>? _blockTexts(_Element sub, String key) {
  final list = sub.array(key);
  if (list == null) return null;
  if (list.isEmpty) {
    sub.problems.add(
      ContentProblem('${sub.base}/$key', ContentProblemKind.outOfRange),
    );
    return null;
  }
  final mark = sub.markStart();
  final values = List<String?>.filled(list.length, null);
  for (var k = 0; k < list.length; k++) {
    final value = list[k];
    if (value is! String) {
      sub.problems.add(
        ContentProblem('${sub.base}/$key/$k', ContentProblemKind.wrongType),
      );
      continue;
    }
    if (!NamedText.isValidText(value)) {
      sub.problems.add(
        ContentProblem('${sub.base}/$key/$k', ContentProblemKind.invalidValue),
      );
      continue;
    }
    values[k] = value;
  }
  if (sub.problems.length != mark) return null;
  return [for (final value in values) value!];
}

/// A block table's `rows` (FR-152): at least one row, each exactly as wide
/// as the header (`constraintViolation` at the row, unlike a feature
/// table's `outOfRange`), every cell a string — a cell MAY be the empty
/// string, as in a printed blank cell (FR-151).
List<List<String>>? _blockTableRows(_Element sub, List<String>? header) {
  final list = sub.array('rows');
  if (list == null) return null;
  if (list.isEmpty) {
    sub.problems.add(
      ContentProblem('${sub.base}/rows', ContentProblemKind.outOfRange),
    );
    return null;
  }
  final mark = sub.markStart();
  var failed = false;
  final rows = List<List<String>?>.filled(list.length, null);
  for (var r = 0; r < list.length; r++) {
    final raw = list[r];
    final path = '${sub.base}/rows/$r';
    if (raw is! List<Object?>) {
      sub.problems.add(ContentProblem(path, ContentProblemKind.wrongType));
      failed = true;
      continue;
    }
    if (header != null && raw.length != header.length) {
      sub.problems.add(
        ContentProblem(path, ContentProblemKind.constraintViolation),
      );
      failed = true;
      continue;
    }
    final cells = <String>[];
    var rowFailed = false;
    for (var c = 0; c < raw.length; c++) {
      final cell = raw[c];
      if (cell is! String) {
        sub.problems.add(
          ContentProblem('$path/$c', ContentProblemKind.wrongType),
        );
        rowFailed = true;
        continue;
      }
      // FR-151: a body cell may be the empty string, as in a printed blank
      // cell; any other blank is invalidValue (FR-152), the constructor's
      // `ContentTextTable.isValidCell` predicate.
      if (!ContentTextTable.isValidCell(cell)) {
        sub.problems.add(
          ContentProblem('$path/$c', ContentProblemKind.invalidValue),
        );
        rowFailed = true;
        continue;
      }
      cells.add(cell);
    }
    rows[r] = rowFailed ? null : cells;
    if (rowFailed) failed = true;
  }
  if (failed || sub.problems.length != mark) return null;
  return [for (final row in rows) row!];
}
