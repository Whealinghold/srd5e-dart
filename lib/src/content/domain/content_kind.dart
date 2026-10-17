/// The kind of one piece of game content: one value per SRD 5.2.1 content
/// category, named the singular of its heading (FR-142).
///
/// The declaration order is load-bearing: problems, merged sets and
/// cross-reference results are ordered by it, so a value is never inserted
/// before an existing one. The headings and pages are the content categories
/// of the SRD's table of contents ("Contents", SRD 5.2.1, p. 2); "Animals"
/// (p. 344) is a stat-block section and maps to [monster], so there is no
/// `animal` value.
enum ContentKind {
  /// Character Species ("Character Species", SRD 5.2.1, p. 83).
  species,

  /// Character Backgrounds; the singular of the SRD heading (p. 83).
  background,

  /// Classes; the singular "Class", suffixed because `class` is a Dart
  /// keyword ("Classes", SRD 5.2.1, p. 28).
  characterClass,

  /// Feats ("Feats", SRD 5.2.1, p. 87).
  feat,

  /// Equipment ("Equipment", SRD 5.2.1, p. 89).
  equipment,

  /// Spells ("Spells", SRD 5.2.1, p. 104).
  spell,

  /// Magic Items ("Magic Items", SRD 5.2.1, p. 204).
  magicItem,

  /// Monsters, including the "Animals" stat-block section (p. 344)
  /// ("Monsters", SRD 5.2.1, p. 254).
  monster,

  /// Poison, a Gameplay Toolbox catalogue kind ("Poison", SRD 5.2.1, p. 197).
  poison,

  /// Traps, a Gameplay Toolbox catalogue kind ("Traps", SRD 5.2.1, p. 199).
  trap,

  /// Curses and Magical Contagions, a Gameplay Toolbox catalogue kind
  /// ("Curses and Magical Contagions", SRD 5.2.1, p. 193).
  contagion,
}
