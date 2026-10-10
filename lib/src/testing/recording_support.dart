import '../shared_ports/observability/attributes.dart';

/// The shape of a span name and of an instrument name:
/// `srd5e.<context>.<noun>`, at least three dot-separated parts, each starting
/// with a lowercase letter (`doc/rules/observability.md` §5, "Naming").
final RegExp _signalName = RegExp(
  r'^srd5e\.[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$',
);

/// Throws an [ArgumentError] named [parameter] unless [name] has the shape of
/// a span or instrument name.
void requireSignalName(String name, String parameter) {
  if (!_signalName.hasMatch(name)) {
    throw ArgumentError.value(
      name,
      parameter,
      'must look like srd5e.<context>.<noun>: lowercase, dot-separated, at '
      'least three parts, each starting with a letter',
    );
  }
}

/// Throws an [ArgumentError] named [key] unless [value] is a `String`, `bool`,
/// `int` or `double`, the plain types an attribute may hold.
void requireAttributeValue(String key, Object value) {
  if (value is! String && value is! bool && value is! int && value is! double) {
    throw ArgumentError.value(
      value,
      key,
      'an attribute value must be a String, bool, int or double',
    );
  }
}

/// A validated, modifiable copy of [attributes].
///
/// Throws an [ArgumentError] naming the first key whose value is not a
/// `String`, `bool`, `int` or `double`. The copy does not change when the
/// caller later changes the map it passed.
Map<String, Object> copyAttributes(Attributes attributes) {
  for (final entry in attributes.entries) {
    requireAttributeValue(entry.key, entry.value);
  }
  return Map<String, Object>.of(attributes);
}
