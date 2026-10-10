import 'package:meta/meta.dart';

/// The root of every failure that a port or its backend can throw.
///
/// A driven port reports infrastructure failure (an I/O error, an unavailable
/// backend) or a contract breach (data that violates the port's documented
/// contract) by throwing a concrete subtype of this class. Expected outcomes
/// (a content id that is not found, a rule the engine refuses) are never
/// thrown: they are returned as sealed result variants. A programmer error is
/// an [Error] such as [ArgumentError] or [StateError], never an
/// [Srd5eException].
///
/// This class is an `abstract base class` and deliberately not `sealed`: Dart
/// allows extending a sealed class only inside its own library, and each
/// port's subtype lives with its port. The set of concrete subtypes is still
/// closed by documentation: every subtype is `final`, is listed with its
/// [errorType] in the package's error registry, and is published by the
/// specification that owns its port. Consumers must not subclass it (the
/// constructor is annotated as internal); a consumer adapter throws the
/// published subtypes through their public constructors. Because the
/// compiler cannot check a `switch` over the root for exhaustiveness, consumer
/// code needs a default branch when it switches over an [Srd5eException].
///
/// An [Srd5eException] carries data, not display text. Its `toString` is for
/// debugging only; read [errorType], [cause] and [causeStackTrace] instead.
abstract base class Srd5eException implements Exception {
  /// Creates the shared part of a port failure.
  ///
  /// A subtype passes both fields on with `super.cause, super.causeStackTrace`
  /// and keeps them optional, so it can be built without an underlying error.
  @internal
  const Srd5eException({this.cause, this.causeStackTrace});

  /// The original object that was thrown, unchanged, or `null` when the
  /// failure did not come from a thrown object.
  ///
  /// This is an [Object] and not an [Exception] because Dart can throw any
  /// object and a hand-written adapter may wrap a non-[Exception].
  final Object? cause;

  /// The stack trace that accompanied [cause], unchanged, or `null` when
  /// there is none.
  final StackTrace? causeStackTrace;

  /// The value of the `error.type` telemetry attribute for this failure.
  ///
  /// A concrete subtype returns one constant, non-empty, lower-snake-case
  /// value equal to the snake_case of its class name (for example
  /// `dice_roller_exception`), the same for every instance and every reason.
  /// The values are a public telemetry contract: renaming or removing one
  /// after release is a breaking change.
  String get errorType;
}
