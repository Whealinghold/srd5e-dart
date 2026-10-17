/// One of the twelve table families of the Equipment chapter ("Equipment",
/// SRD 5.2.1, pp. 89-103), in chapter order (FR-002).
///
/// The JSON value is the package tag in lower camel case. A `switch` over the
/// enum is exhaustive: every decoded equipment entry is served under the one
/// `ContentKind.equipment` kind and categorised by this enum.
enum EquipmentCategory {
  /// The Weapons table ("Weapons", SRD 5.2.1, p. 91).
  weapon('weapon'),

  /// The Armor table ("Armor", SRD 5.2.1, p. 92).
  armor('armor'),

  /// Tools: Artisan's Tools, Other Tools and their variants
  /// ("Tools", SRD 5.2.1, pp. 93-94).
  tool('tool'),

  /// Adventuring Gear and its sub-tables ("Adventuring Gear",
  /// SRD 5.2.1, pp. 94-100).
  adventuringGear('adventuringGear'),

  /// Mounts and Other Animals ("Mounts and Other Animals",
  /// SRD 5.2.1, p. 100).
  mount('mount'),

  /// Tack, Harness, and Drawn Vehicles (SRD 5.2.1, p. 100).
  tackHarnessOrDrawnVehicle('tackHarnessOrDrawnVehicle'),

  /// Airborne and Waterborne Vehicles (SRD 5.2.1, pp. 100-101).
  airborneOrWaterborneVehicle('airborneOrWaterborneVehicle'),

  /// Lifestyle Expenses ("Lifestyle Expenses", SRD 5.2.1, p. 101).
  lifestyleExpense('lifestyleExpense'),

  /// Food, Drink, and Lodging (SRD 5.2.1, pp. 101-102).
  foodDrinkOrLodging('foodDrinkOrLodging'),

  /// Hirelings ("Hirelings", SRD 5.2.1, p. 102).
  hireling('hireling'),

  /// Spellcasting Services ("Spellcasting Services", SRD 5.2.1, p. 102).
  spellcastingService('spellcastingService'),

  /// Spell Scroll Costs ("Scribing Spell Scrolls", SRD 5.2.1, p. 103).
  spellScrollCost('spellScrollCost');

  const EquipmentCategory(this.jsonValue);

  /// The package tag used in JSON.
  final String jsonValue;

  /// The member whose [jsonValue] is [value], or null for a non-member: the
  /// decoder turns a non-member into `invalidValue` (FR-105, FR-002).
  static EquipmentCategory? fromJson(String value) => switch (value) {
    'weapon' => weapon,
    'armor' => armor,
    'tool' => tool,
    'adventuringGear' => adventuringGear,
    'mount' => mount,
    'tackHarnessOrDrawnVehicle' => tackHarnessOrDrawnVehicle,
    'airborneOrWaterborneVehicle' => airborneOrWaterborneVehicle,
    'lifestyleExpense' => lifestyleExpense,
    'foodDrinkOrLodging' => foodDrinkOrLodging,
    'hireling' => hireling,
    'spellcastingService' => spellcastingService,
    'spellScrollCost' => spellScrollCost,
    _ => null,
  };
}
