/// The snake_case of a CamelCase [name], for example `DiceRollerException`
/// becomes `dice_roller_exception`.
///
/// Computed in test support code, never from `runtimeType` in `lib/`.
String snakeCase(String name) => name
    .replaceAllMapped(RegExp(r'(?<!^)([A-Z])'), (match) => '_${match.group(1)}')
    .toLowerCase();
