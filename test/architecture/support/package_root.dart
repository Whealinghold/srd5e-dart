import 'dart:io';

/// Finds the package root: the nearest ancestor of [start] whose
/// `pubspec.yaml` declares `name: srd5e`.
///
/// Throws a [StateError] naming the directory searched when none is found, so
/// a wrong working directory cannot make every check pass vacuously.
Directory findPackageRoot([Directory? start]) {
  final origin = (start ?? Directory.current).absolute;
  var directory = origin;
  while (true) {
    final pubspec = File('${directory.path}/pubspec.yaml');
    if (pubspec.existsSync() &&
        RegExp(
          r'^name:\s*srd5e\s*$',
          multiLine: true,
        ).hasMatch(pubspec.readAsStringSync())) {
      return directory;
    }
    final parent = directory.parent;
    if (parent.path == directory.path) {
      throw StateError(
        'No pubspec.yaml declaring "name: srd5e" in or above ${origin.path}.',
      );
    }
    directory = parent;
  }
}
