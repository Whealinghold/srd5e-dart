/// One of the eight schools of magic of the Schools of Magic table
/// ("Schools of Magic", SRD 5.2.1, p. 105), in table order (FR-012).
///
/// The JSON spelling is the printed name, exactly. The school is identity
/// only; what a school does is the using context's rule.
enum SpellSchool {
  /// Abjuration.
  abjuration('Abjuration'),

  /// Conjuration.
  conjuration('Conjuration'),

  /// Divination.
  divination('Divination'),

  /// Enchantment.
  enchantment('Enchantment'),

  /// Evocation.
  evocation('Evocation'),

  /// Illusion.
  illusion('Illusion'),

  /// Necromancy.
  necromancy('Necromancy'),

  /// Transmutation.
  transmutation('Transmutation');

  const SpellSchool(this.jsonValue);

  /// The printed name used in JSON.
  final String jsonValue;

  /// The member whose [jsonValue] is [value], or null for a non-member: the
  /// decoder turns a non-member into `invalidValue` (FR-105, FR-108).
  static SpellSchool? fromJson(String value) => switch (value) {
    'Abjuration' => abjuration,
    'Conjuration' => conjuration,
    'Divination' => divination,
    'Enchantment' => enchantment,
    'Evocation' => evocation,
    'Illusion' => illusion,
    'Necromancy' => necromancy,
    'Transmutation' => transmutation,
    _ => null,
  };
}
