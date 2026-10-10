/// The structured details attached to a log event, a span or a measurement.
///
/// Keys are consistent across signals (see `AttributeKeys`). Values are plain
/// and low-cardinality: a `String`, `bool`, `int` or `double`. Never an id,
/// free text, a whole object or any personal data.
typedef Attributes = Map<String, Object>;
