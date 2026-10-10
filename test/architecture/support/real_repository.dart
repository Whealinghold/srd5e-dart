import '../checks/harness_guards.dart';
import 'package_root.dart';
import 'source_set.dart';

/// The real repository, loaded once per test isolate and never mutated.
///
/// Loading runs the FR-012 guard ([requireRepositoryRoots]), so a test file
/// that uses this snapshot fails at once on a wrong root instead of passing
/// every check vacuously. Real-repository tests use this instead of calling
/// `SourceSet.load(findPackageRoot())` themselves.
final SourceSet realRepository = _load();

SourceSet _load() {
  final sources = SourceSet.load(findPackageRoot());
  requireRepositoryRoots(sources);
  return sources;
}
