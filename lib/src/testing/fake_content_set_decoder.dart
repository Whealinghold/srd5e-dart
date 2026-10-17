import 'dart:collection' show UnmodifiableListView;

import '../content/content.dart';

/// A scriptable, recording test double [ContentSetDecoder]
/// (content-schema-and-decoder.md FR-087).
///
/// Script it per input: a map from document text to the result to return,
/// and one from document text to the object to throw (a thrown error path
/// is what `LoadContentSet`'s handling is tested with). Each `decode` call
/// records its input in [inputs] — in call order, unmodifiable — and then
/// returns the scripted result, throws the scripted error, or falls back to
/// [defaultResult] for an input nobody scripted. An unscripted input with
/// no default throws a [StateError]: a test set-up bug, not a port
/// failure.
///
/// The double is format-blind: it knows nothing about JSON, which is
/// exactly why the decoder contract suite can run against it beside the
/// real decoder. Its own tests cover scripting, recording and the thrown
/// error path; they are not evidence about decoding.
final class FakeContentSetDecoder implements ContentSetDecoder {
  /// Creates the double over the scripts.
  ///
  /// The maps are copied; changing the caller's maps afterwards changes
  /// nothing. A value of [errors] may be any object; it is thrown as is.
  FakeContentSetDecoder({
    Map<String, ContentDecodeResult> results = const {},
    Map<String, Object> errors = const {},
    this.defaultResult,
  }) : _results = Map.of(results),
       _errors = Map.of(errors);

  final Map<String, ContentDecodeResult> _results;
  final Map<String, Object> _errors;

  /// The result served for an input with no script, or null to reject
  /// unscripted inputs with a [StateError].
  final ContentDecodeResult? defaultResult;

  final List<String> _inputs = [];

  /// Every document passed to [decode], in call order; unmodifiable.
  List<String> get inputs => UnmodifiableListView(_inputs);

  @override
  ContentDecodeResult decode(String document) {
    _inputs.add(document);
    final error = _errors[document];
    if (error != null) throw error;
    final result = _results[document] ?? defaultResult;
    if (result == null) {
      throw StateError(
        'FakeContentSetDecoder has no script for this input and no '
        'defaultResult.',
      );
    }
    return result;
  }
}
