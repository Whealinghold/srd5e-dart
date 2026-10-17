import 'package:meta/meta.dart';

/// The time donning or doffing armor takes, as the Armor table prints it
/// (FR-022, FR-104).
///
/// The sealed family holds the two printed forms: a number of Minutes
/// ([DonDoffMinutes]) and the Shield's "Utilize action to don or doff"
/// ([DonDoffByUtilize]) ("Armor", SRD 5.2.1, p. 92). The times are typed
/// values, never strings, and are static facts of the [ArmorCategory]: the
/// entries do not repeat them.
@immutable
sealed class DonDoffTime {
  const DonDoffTime();
}

/// Donning or doffing that takes a printed number of Minutes (FR-022).
@immutable
final class DonDoffMinutes extends DonDoffTime {
  /// The number of Minutes the Armor table prints.
  const DonDoffMinutes(this.minutes);

  /// The printed number of Minutes.
  final int minutes;

  @override
  bool operator ==(Object other) =>
      other is DonDoffMinutes && other.minutes == minutes;

  @override
  int get hashCode => Object.hash(DonDoffMinutes, minutes);

  @override
  String toString() => 'DonDoffMinutes($minutes)';
}

/// The Shield's "Utilize action to don or doff" (FR-022).
@immutable
final class DonDoffByUtilize extends DonDoffTime {
  /// The single form; the printed sentence carries no data.
  const DonDoffByUtilize();

  @override
  bool operator ==(Object other) => other is DonDoffByUtilize;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'DonDoffByUtilize()';
}

/// One of the four armor categories of the Armor table ("Armor", SRD 5.2.1,
/// p. 92), in table order (FR-104).
///
/// The wire spelling is the printed word. Each category is a static fact
/// carrier: its donning and doffing times (FR-022) are typed values held
/// here, so an entry never repeats them. A `switch` over the enum is
/// exhaustive.
enum ArmorCategory {
  /// Light armor: 1 Minute to don, 1 Minute to doff (Padded, Leather,
  /// Studded Leather).
  light('Light', donTime: DonDoffMinutes(1), doffTime: DonDoffMinutes(1)),

  /// Medium armor: 5 Minutes to don, 1 Minute to doff (Hide, Chain Shirt,
  /// Scale Mail, Breastplate, Half Plate).
  medium('Medium', donTime: DonDoffMinutes(5), doffTime: DonDoffMinutes(1)),

  /// Heavy armor: 10 Minutes to don, 5 Minutes to doff (Ring Mail,
  /// Chain Mail, Splint, Plate).
  heavy('Heavy', donTime: DonDoffMinutes(10), doffTime: DonDoffMinutes(5)),

  /// The Shield: "Utilize action to don or doff" (SRD 5.2.1, p. 92).
  shield('Shield', donTime: DonDoffByUtilize(), doffTime: DonDoffByUtilize());

  const ArmorCategory(
    this.jsonValue, {
    required this.donTime,
    required this.doffTime,
  });

  /// The printed word used in JSON.
  final String jsonValue;

  /// The time donning takes (FR-022).
  final DonDoffTime donTime;

  /// The time doffing takes (FR-022).
  final DonDoffTime doffTime;

  /// The member whose [jsonValue] is [value], or null for a non-member: the
  /// decoder turns a non-member into `invalidValue` (FR-105, FR-109).
  static ArmorCategory? fromJson(String value) => switch (value) {
    'Light' => light,
    'Medium' => medium,
    'Heavy' => heavy,
    'Shield' => shield,
    _ => null,
  };
}
