/// One of the 9 weapon properties of the Properties sections ("Properties",
/// SRD 5.2.1, pp. 89-90), in section order (FR-113).
///
/// "Range" is a notation qualifying [ammunition] and [thrown], not a
/// property, so it is not a member. The JSON spelling is the printed name.
/// The type is identity only; the properties' behaviour is the
/// weapon-properties-and-mastery rules' concern.
enum WeaponProperty {
  /// Ammunition.
  ammunition('Ammunition'),

  /// Finesse.
  finesse('Finesse'),

  /// Heavy.
  heavy('Heavy'),

  /// Light.
  light('Light'),

  /// Loading.
  loading('Loading'),

  /// Reach.
  reach('Reach'),

  /// Thrown.
  thrown('Thrown'),

  /// Two-Handed, printed with a hyphen.
  twoHanded('Two-Handed'),

  /// Versatile.
  versatile('Versatile');

  const WeaponProperty(this.jsonValue);

  /// The printed name used in JSON.
  final String jsonValue;

  /// The member whose [jsonValue] is [value], or null for a non-member: the
  /// decoder turns a non-member into `invalidValue` (FR-105, FR-025).
  static WeaponProperty? fromJson(String value) => switch (value) {
    'Ammunition' => ammunition,
    'Finesse' => finesse,
    'Heavy' => heavy,
    'Light' => light,
    'Loading' => loading,
    'Reach' => reach,
    'Thrown' => thrown,
    'Two-Handed' => twoHanded,
    'Versatile' => versatile,
    _ => null,
  };
}
