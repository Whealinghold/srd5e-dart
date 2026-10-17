/// The thin file-reading wrapper of the embedded-data generator
/// (content-schema-and-decoder.md FR-121): it gathers the texts of
/// `data/srd_5_2_1/*.json` (the directory may be absent), hands them to the
/// pure core in `generate_embedded_data.dart` and writes the libraries it
/// returns relative to the working directory. It carries no generation logic;
/// run it from the package root.
library;

import 'dart:io';

import 'generate_embedded_data.dart';

void main() {
  final directory = Directory('data/srd_5_2_1');
  final texts = <String, String>{};
  if (directory.existsSync()) {
    final files = directory.listSync().whereType<File>().toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    for (final file in files) {
      final name = file.uri.pathSegments.last;
      if (!name.endsWith('.json')) continue;
      texts[name] = file.readAsStringSync();
    }
  }
  final libraries = generateEmbeddedLibraries(Map.unmodifiable(texts));
  for (final MapEntry(key: path, value: text) in libraries.entries) {
    final output = File(path);
    output.parent.createSync(recursive: true);
    output.writeAsStringSync(text, flush: true);
  }
}
