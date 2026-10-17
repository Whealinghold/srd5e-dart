/// The embedded-data generator core (content-schema-and-decoder.md FR-120 to
/// FR-122).
///
/// [generateEmbeddedLibraries] is the pure function the drift check
/// (architecture-guardrails.md FR-078) calls: one Dart library per data file
/// under `lib/src/content/data/`, each holding the file's text character for
/// character as one escaped `const String`, plus the `embedded_documents.dart`
/// index over the same constants. The function does no I/O and reads no clock
/// or environment; the output is byte-stable and in ordinal order of file
/// name, whatever the iteration order of the input map. The file-reading
/// `main` is the thin wrapper in `generate_embedded_data_main.dart`; this
/// file imports no `dart:io`.
///
/// Every emitted library starts with the two-line attribution header of
/// content-licensing-and-notice.md FR-029, verbatim. The emitted declarations
/// are laid out exactly as `dart format` lays them out (the formatter's 80
/// column page: one line when a declaration fits, otherwise `=` at the end of
/// the declaration line and one string literal per line after it), so the
/// committed output survives the format gate byte for byte and the drift
/// check never fights it.
library;

/// The two header lines every generated library starts with
/// (content-licensing-and-notice.md FR-029, verbatim).
const List<String> embeddedHeaderLines = [
  '// GENERATED from data/srd_5_2_1/. Contains SRD 5.2.1 content.',
  '// Attribution: see NOTICE.md in the package root.',
];

/// The output path of the index (content-schema-and-decoder.md FR-122).
const String embeddedIndexPath = 'lib/src/content/data/embedded_documents.dart';

/// The lower-camel-case name of the `const String` holding [stem]'s text,
/// suffixed `Json` (content-schema-and-decoder.md FR-120): `species` gives
/// `speciesJson`, `species_extra` gives `speciesExtraJson`.
String embeddedConstantName(String stem) {
  final parts = stem.split('_');
  final buffer = StringBuffer(parts.first);
  for (final part in parts.skip(1)) {
    if (part.isEmpty) continue;
    buffer
      ..write(part[0].toUpperCase())
      ..write(part.substring(1));
  }
  buffer.write('Json');
  return buffer.toString();
}

/// Generates the embedded libraries for [dataFileTexts]
/// (content-schema-and-decoder.md FR-121).
///
/// The keys are the data file names (`species.json`), optionally preceded by
/// their repository path under `data/` (the drift check passes full paths);
/// the name after the last `/` is the one validated. The values are the file
/// texts. The result maps the repository-relative library path to its text:
/// one library per input, plus the index [embeddedIndexPath].
///
/// Throws an [ArgumentError] carrying the name `dataFileTexts` and the
/// offending file name when a name is not `<stem>.json` with `<stem>`
/// matching `[a-z][a-z0-9_]*`, or when two names give one lower-camel-case
/// constant. With several offenders the first in ordinal name order throws,
/// so the thrown values do not depend on the map's iteration order either.
Map<String, String> generateEmbeddedLibraries(
  Map<String, String> dataFileTexts,
) {
  final inputs =
      [
        for (final MapEntry(key: key, value: text) in dataFileTexts.entries)
          (key: key, name: _fileNameOf(key), text: text),
      ]..sort((a, b) {
        final byName = a.name.compareTo(b.name);
        return byName != 0 ? byName : a.key.compareTo(b.key);
      });

  final documents = <_Document>[];
  final constantSources = <String, String>{};
  for (final input in inputs) {
    final match = _namePattern.matchAsPrefix(input.name);
    if (match == null) {
      throw ArgumentError.value(
        input.name,
        'dataFileTexts',
        'is not <stem>.json with <stem> matching [a-z][a-z0-9_]*',
      );
    }
    final stem = match.group(1)!;
    final constant = embeddedConstantName(stem);
    final previous = constantSources[constant];
    if (previous != null) {
      throw ArgumentError.value(
        input.name,
        'dataFileTexts',
        'and $previous give the same constant $constant',
      );
    }
    constantSources[constant] = input.name;
    documents.add((stem: stem, constant: constant, text: input.text));
  }

  final libraries = <String, String>{
    for (final document in documents)
      'lib/src/content/data/${document.stem}.dart': _documentLibrary(
        document.stem,
        document.constant,
        document.text,
      ),
  };
  libraries[embeddedIndexPath] = _indexLibrary(documents);
  return libraries;
}

/// One validated input, ready to emit.
typedef _Document = ({String stem, String constant, String text});

final RegExp _namePattern = RegExp(r'([a-z][a-z0-9_]*)\.json$');

/// The formatter's page width: a declaration that fits on one line must be
/// emitted on one line, or `dart format` would collapse the split form.
const int _pageWidth = 80;

String _fileNameOf(String key) => key.substring(key.lastIndexOf('/') + 1);

/// The header lines and the blank line after them.
String _libraryHead() => '${embeddedHeaderLines.join('\n')}\n\n';

/// One document library (content-schema-and-decoder.md FR-120): the header,
/// then one documented `const String` named [constant] holding [text]
/// exactly.
String _documentLibrary(String stem, String constant, String text) =>
    '${_libraryHead()}${_constantDeclaration(stem, constant, text)}';

/// The index library (content-schema-and-decoder.md FR-122): the header, one
/// `const String` per document in ordinal name order, and the
/// `embeddedDocuments` map over them — empty when there is no data file. A
/// file under `lib/src/content/data/` imports nothing in the package
/// (architecture-guardrails.md FR-095), so the constants live here.
String _indexLibrary(List<_Document> documents) {
  final buffer = StringBuffer(_libraryHead());
  for (final document in documents) {
    buffer
      ..write(
        _constantDeclaration(document.stem, document.constant, document.text),
      )
      ..write('\n');
  }
  buffer.write(_indexDeclaration(documents));
  return buffer.toString();
}

/// The `const String` declaration for [text], with its doc comment: on one
/// line when it fits the formatter's page, otherwise one literal per line,
/// adjacent.
String _constantDeclaration(String stem, String constant, String text) {
  final literals = _literalLines(text);
  final doc =
      "/// The text of `data/srd_5_2_1/$stem.json`, verbatim (FR-120).\n";
  final singleLine = 'const String $constant = ${literals.join()};';
  if (singleLine.length <= _pageWidth) return '$doc$singleLine\n';
  final buffer = StringBuffer(doc);
  buffer.write('const String $constant =\n');
  for (var i = 0; i < literals.length; i++) {
    buffer.write('    ${literals[i]}${i == literals.length - 1 ? ';' : ''}\n');
  }
  return buffer.toString();
}

/// The `embeddedDocuments` declaration, with its doc comment: stem to
/// constant, in the order given (ordinal by stem), on one line when it fits
/// the page.
String _indexDeclaration(List<_Document> documents) {
  const doc =
      '/// The embedded documents by file stem\n'
      '/// (content-schema-and-decoder.md FR-122).\n';
  final entries = [
    for (final document in documents)
      "'${document.stem}': ${document.constant}",
  ];
  final singleLine =
      'const Map<String, String> embeddedDocuments = {${entries.join(', ')}};';
  if (singleLine.length <= _pageWidth) return '$doc$singleLine\n';
  final buffer = StringBuffer(doc);
  buffer.write('const Map<String, String> embeddedDocuments = {\n');
  for (final entry in entries) {
    buffer.write('  $entry,\n');
  }
  buffer.write('};\n');
  return buffer.toString();
}

/// The escaped single-quoted literals of [text]: one literal per line of the
/// text (the line feed is the `\n` escape ending each literal but the last),
/// so the output is a pure function of the text.
List<String> _literalLines(String text) {
  final parts = text.split('\n');
  return [
    for (var i = 0; i < parts.length; i++)
      "'${_escape(parts[i])}${i == parts.length - 1 ? '' : r'\n'}'",
  ];
}

/// Escapes [line] for a single-quoted Dart string literal: backslash, dollar,
/// quote, and every control character escaped; everything else as is
/// (content-schema-and-decoder.md FR-120). A valid surrogate pair is one
/// character, kept as is; only a lone surrogate is escaped, for it has no
/// character form to keep.
String _escape(String line) {
  final buffer = StringBuffer();
  final units = line.codeUnits;
  for (var i = 0; i < units.length; i++) {
    final unit = units[i];
    if (unit >= 0xd800 &&
        unit <= 0xdbff &&
        i + 1 < units.length &&
        units[i + 1] >= 0xdc00 &&
        units[i + 1] <= 0xdfff) {
      // A valid pair: content, kept as is (FR-120).
      buffer
        ..writeCharCode(unit)
        ..writeCharCode(units[i + 1]);
      i++;
      continue;
    }
    switch (unit) {
      case 0x5c:
        buffer.write(r'\\');
      case 0x24:
        buffer.write(r'\$');
      case 0x27:
        buffer.write(r"\'");
      case 0x08:
        buffer.write(r'\b');
      case 0x09:
        buffer.write(r'\t');
      case 0x0a:
        // A line never holds a line feed; escaped anyway, never emitted raw.
        buffer.write(r'\n');
      case 0x0b:
        buffer.write(r'\v');
      case 0x0c:
        buffer.write(r'\f');
      case 0x0d:
        buffer.write(r'\r');
      case _
          when unit < 0x20 ||
              unit == 0x7f ||
              (unit >= 0xd800 && unit <= 0xdfff):
        // A control character, or a lone surrogate (the pair case above has
        // already consumed every well-formed high surrogate).
        buffer.write('\\u${unit.toRadixString(16).padLeft(4, '0')}');
      default:
        buffer.writeCharCode(unit);
    }
  }
  return buffer.toString();
}
