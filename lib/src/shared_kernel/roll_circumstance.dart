import 'package:meta/meta.dart';

/// Something about a d20 roll that gives it Advantage or Disadvantage: the input
/// of `RollMode.resolve`.
///
/// A circumstance is either an [Advantage] or a [Disadvantage] ("Advantage/
/// Disadvantage", SRD 5.2.1, pp. 7-8). It carries no data, no cause and no
/// source: only whether circumstances of each kind are present matters, which
/// is how "they don't stack" is encoded (p. 8). Callers decide which
/// circumstances apply to their own roll.
///
/// The type is sealed, so a `switch` over it with an [Advantage] case and a
/// [Disadvantage] case is exhaustive without a default branch.
@immutable
sealed class RollCircumstance {
  const RollCircumstance();
}

/// A circumstance that gives a d20 roll Advantage ("Advantage", Rules
/// Glossary, SRD 5.2.1, p. 176).
///
/// All instances are equal. Several of them still give only Advantage
/// ("They Don't Stack", p. 8).
final class Advantage extends RollCircumstance {
  /// Creates an Advantage circumstance.
  const Advantage();

  @override
  bool operator ==(Object other) => other is Advantage;

  @override
  int get hashCode => (Advantage).hashCode;

  /// The debugging form, `Advantage`. Not display text.
  @override
  String toString() => 'Advantage';
}

/// A circumstance that gives a d20 roll Disadvantage ("Disadvantage", Rules
/// Glossary, SRD 5.2.1, p. 181).
///
/// All instances are equal. Several of them still give only Disadvantage
/// ("They Don't Stack", p. 8).
final class Disadvantage extends RollCircumstance {
  /// Creates a Disadvantage circumstance.
  const Disadvantage();

  @override
  bool operator ==(Object other) => other is Disadvantage;

  @override
  int get hashCode => (Disadvantage).hashCode;

  /// The debugging form, `Disadvantage`. Not display text.
  @override
  String toString() => 'Disadvantage';
}
