import 'dart:io';

import 'package:test/test.dart';

const _portDir = 'lib/src/shared_ports/observability';

/// The rule of FR-056, exactly as the spec words it (whitespace collapsed).
const _throwRule =
    'Production implementations MUST NOT throw of their own accord '
    "(trace/time rethrow the body's own error unchanged); srd5e does not "
    'catch. The recording doubles in `testing.dart` throw '
    '`ArgumentError`/`StateError` on misuse by design.';

typedef _DocCase = ({
  String label,
  String file,
  String declaration,
  List<String> required,
});

/// The doc comment directly above the first line that starts with
/// [declaration] in [file], with the `///` markers removed and whitespace
/// collapsed. Fails the test if the declaration or a comment is missing.
String _docAbove(String file, String declaration) {
  final lines = File('$_portDir/$file').readAsLinesSync();
  final index = lines.indexWhere((l) => l.trimLeft().startsWith(declaration));
  expect(index, isNonNegative, reason: '$declaration not found in $file');
  final doc = <String>[];
  for (var i = index - 1; i >= 0; i--) {
    final line = lines[i].trim();
    if (line.startsWith('@')) continue;
    if (!line.startsWith('///')) break;
    doc.insert(0, line.substring(3));
  }
  expect(doc, isNotEmpty, reason: 'no doc comment above $declaration');
  return doc.join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();
}

void main() {
  /// Requirement: doc/specs/observability-ports.md FR-056 - the dartdoc of
  ///   Logger, Tracer and Meter states the no-throw rule and the recording
  ///   double carve-out.
  /// Path: unhappy (invalid input)
  group('port dartdoc states the throw rule', () {
    /// Requirement: per case
    /// Path: per case
    for (final c in <_DocCase>[
      (
        label: 'Logger',
        file: 'logger.dart',
        declaration: 'abstract interface class Logger',
        required: [_throwRule],
      ),
      (
        label: 'Tracer',
        file: 'tracer.dart',
        declaration: 'abstract interface class Tracer',
        required: [_throwRule],
      ),
      (
        label: 'Meter',
        file: 'meter.dart',
        declaration: 'abstract interface class Meter',
        required: [_throwRule],
      ),
    ]) {
      test('FR-056: the ${c.label} doc comment has the full sentence '
          '[unhappy (invalid input)]', () {
        final doc = _docAbove(c.file, c.declaration);

        for (final text in c.required) {
          expect(doc, contains(text));
        }
      });
    }
  });

  /// Requirement: doc/specs/observability-ports.md FR-057 - the dartdoc of
  ///   Tracer.trace and Meter.time says the body must not return a Future and
  ///   names the async variant and the reason.
  /// Path: unhappy (invalid input)
  group('trace and time dartdoc forbid a Future body', () {
    /// Requirement: per case
    /// Path: per case
    for (final c in <_DocCase>[
      (
        label: 'Tracer.trace',
        file: 'tracer.dart',
        declaration: 'T trace<T>(',
        required: [
          'MUST NOT return a `Future`',
          'use `traceAsync`',
          'the span would end before the future completes',
        ],
      ),
      (
        label: 'Meter.time',
        file: 'meter.dart',
        declaration: 'T time<T>(',
        required: [
          'MUST NOT return a `Future`',
          'use `timeAsync`',
          'the measurement would be recorded before the future completes',
        ],
      ),
    ]) {
      test('FR-057: the ${c.label} doc comment has the restriction '
          '[unhappy (invalid input)]', () {
        final doc = _docAbove(c.file, c.declaration);

        for (final text in c.required) {
          expect(doc, contains(text));
        }
      });
    }
  });
}
