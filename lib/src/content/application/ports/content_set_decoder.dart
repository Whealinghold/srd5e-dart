import '../content_decode_result.dart';

/// Turns one content document's text into a [ContentDecodeResult]
/// (FR-078).
///
/// A synchronous driven port: decoding is computational and in-memory —
/// loading the text is the consumer's job, before this call. The port
/// reports content problems by returning `ContentDecodeFailed`; it never
/// throws for content (FR-018). A thrown object is a bug in the
/// implementation, not a rejection.
///
/// The generic bundled implementation is `JsonContentSetDecoder`
/// (`package:srd5e/adapters.dart`); a host with another external format
/// implements this port instead. The test double is `FakeContentSetDecoder`
/// (`package:srd5e/testing.dart`).
abstract interface class ContentSetDecoder {
  /// Decodes [document], returning the entries or every problem found.
  ///
  /// A pure function of its input: no clock, randomness, I/O or global
  /// state, and the input is neither retained nor mutated (FR-075, FR-076).
  ContentDecodeResult decode(String document);
}
