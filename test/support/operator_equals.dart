/// Calls `a == b` through `Object?` parameters.
///
/// `expect(a, equals(b))` evaluates `b == a`, so an assertion that a value is
/// not equal to an object of another type would never run the value's own
/// `==`. Tests of cross-type inequality call this instead, in both directions,
/// and assert the exact result.
bool operatorEquals(Object? a, Object? b) => a == b;
