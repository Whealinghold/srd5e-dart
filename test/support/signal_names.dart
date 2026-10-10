/// A span or instrument name and whether `RecordingTracer` and
/// `RecordingMeter` accept it
/// (`doc/specs/observability-ports.md` FR-024 and FR-039).
typedef SignalNameCase = ({String label, String name, bool valid});

/// The shared name table of FR-024 and FR-039.
const List<SignalNameCase> signalNameCases = [
  (label: 'three parts', name: 'srd5e.d20_test.resolve', valid: true),
  (label: 'four parts', name: 'srd5e.content.decode.errors', valid: true),
  (label: 'digits and underscores', name: 'srd5e.x9.y_1', valid: true),
  (label: 'empty', name: '', valid: false),
  (label: 'uppercase prefix', name: 'SRD5E.d20_test.resolve', valid: false),
  (label: 'uppercase part', name: 'srd5e.d20_test.Resolve', valid: false),
  (label: 'two parts only', name: 'srd5e.resolve', valid: false),
  (label: 'trailing dot', name: 'srd5e.d20_test.resolve.', valid: false),
  (label: 'empty middle part', name: 'srd5e..resolve', valid: false),
  (label: 'a space', name: 'srd5e.d20 test.resolve', valid: false),
  (label: 'no srd5e prefix', name: 'foo.bar.baz', valid: false),
  (label: 'part starts with a digit', name: 'srd5e.1x.y', valid: false),
  (label: 'part starts with an underscore', name: 'srd5e._x.y', valid: false),
  (label: 'trailing newline', name: 'srd5e.d20_test.resolve\n', valid: false),
];

/// An attribute value and whether the recording doubles accept it
/// (`doc/specs/observability-ports.md` FR-010).
typedef AttributeValueCase = ({String label, Object value, bool valid});

/// Attribute values: the four plain types are valid, anything else is not.
final List<AttributeValueCase> attributeValueCases = [
  (label: 'a String', value: 'x', valid: true),
  (label: 'a bool', value: true, valid: true),
  (label: 'an int', value: 3, valid: true),
  (label: 'a double', value: 1.5, valid: true),
  (label: 'a List', value: <int>[1], valid: false),
  (label: 'a Map', value: <String, int>{'a': 1}, valid: false),
  (label: 'a DateTime', value: DateTime.utc(2000), valid: false),
  (label: 'a Duration', value: Duration.zero, valid: false),
  (label: 'another object', value: Object(), valid: false),
];
