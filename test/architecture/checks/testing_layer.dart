import '../support/constants.dart';
import '../support/context_map.dart';
import '../support/declarations.dart';
import '../support/directives.dart';
import '../support/names.dart';
import '../support/source_set.dart';
import '../support/violation.dart';

/// Testing-layer checks FR-074, FR-075, FR-081 and FR-082 of
/// `doc/specs/architecture-guardrails.md` (section 4.2).
///
/// Every function is pure: it reads a [SourceSet] and returns [Violation]s.

/// The folder of the test doubles.
const String testingPrefix = 'lib/src/testing/';

/// The one file besides the doubles themselves that may name them.
const String testingEntryPoint = 'lib/testing.dart';

/// The shared-port folder (FR-082 reads its ports).
const String _sharedPortsPrefix = 'lib/src/shared_ports/';

/// The folder of the generic shared adapters, which holds no port.
const String _sharedAdaptersPrefix = 'lib/src/shared_ports/adapters/';

/// Prefixes of the files FR-074 scans by default: the package's own `lib/`.
///
/// Whether `test/` and `tool/` are in scope is an open question (the
/// requirement says "no file"; its sibling FR-076 and FR-095 name `lib/`).
const List<String> testingImportScope = ['lib/'];

/// FR-074: no file outside `lib/src/testing/`, other than
/// `lib/testing.dart`, imports or exports a file under `lib/src/testing/`.
///
/// [scope] lists the path prefixes of the scanned files.
List<Violation> checkTestingImportedOnlyByEntryPoint(
  SourceSet sources, {
  List<String> scope = testingImportScope,
}) => sortedViolations([
  for (final prefix in scope)
    for (final directive in allDirectives(sources, prefix: prefix))
      if (!directive.from.startsWith(testingPrefix) &&
          directive.from != testingEntryPoint &&
          (directive.resolvedPath?.startsWith(testingPrefix) ?? false))
        Violation(
          checkId: 'FR-074',
          path: directive.from,
          line: directive.line,
          detail:
              '${directive.kind.name} of "${directive.uri}" reaches the '
              'test doubles; only lib/testing.dart may',
        ),
]);

/// Whether [directive], written in a file under `lib/src/testing/`, is one a
/// double may have (FR-075).
bool _doubleMayImport(Directive directive) {
  if (directive.isDartLibrary) return true;
  if (directive.isPackage && !directive.isLocal) {
    return directive.uri.startsWith('package:meta/') ||
        directive.uri.startsWith('package:collection/');
  }
  final resolved = directive.resolvedPath;
  if (resolved == null) return false;
  if (resolved.startsWith(testingPrefix) ||
      resolved.startsWith('lib/src/shared_kernel/')) {
    return true;
  }
  if (resolved.startsWith(_sharedPortsPrefix)) {
    return !resolved.startsWith(_sharedAdaptersPrefix);
  }
  return barrelContextOf(resolved) != null;
}

/// FR-075: a file under `lib/src/testing/` imports only `dart:` libraries,
/// `package:meta`, `package:collection`, other doubles, `shared_kernel/`,
/// `shared_ports/` (not its `adapters/`) and the barrel of any context. The
/// context map does not apply.
List<Violation> checkTestingImports(SourceSet sources) => sortedViolations([
  for (final directive in allDirectives(sources, prefix: testingPrefix))
    if (!_doubleMayImport(directive))
      Violation(
        checkId: 'FR-075',
        path: directive.from,
        line: directive.line,
        detail:
            'a test double has an ${directive.kind.name} of '
            '"${directive.uri}"; it may import only dart: libraries, '
            'package:meta, package:collection, other doubles, shared_kernel, '
            'shared_ports (not adapters) and context barrels',
      ),
]);

/// A driven port: an `abstract interface class` of `shared_ports/` (not its
/// `adapters/`) or of a `<context>/application/ports/` folder, except the
/// [portHandles] (FR-082).
typedef DrivenPort = ({String name, String path, int line});

final RegExp _contextPortsFolder = RegExp(
  r'^lib/src/(?!shared_kernel/|shared_ports/|testing/)[^/]+/application/ports/',
);

/// The driven ports declared in [sources], in path then line order.
List<DrivenPort> drivenPorts(SourceSet sources) {
  final ports = <DrivenPort>[];
  for (final path in sources.dartPaths('lib/src/')) {
    final inSharedPorts =
        path.startsWith(_sharedPortsPrefix) &&
        !path.startsWith(_sharedAdaptersPrefix);
    if (!inSharedPorts && !_contextPortsFolder.hasMatch(path)) continue;
    for (final declaration in declarationsIn(path, sources.lexed(path))) {
      if (declaration.kind == DeclarationKind.classDeclaration &&
          declaration.modifiers.containsAll(const ['abstract', 'interface']) &&
          !portHandles.contains(declaration.name)) {
        ports.add((name: declaration.name, path: path, line: declaration.line));
      }
    }
  }
  return ports;
}

/// The last segment of a possibly prefixed type name (`p.DiceRoller`).
String _simpleName(String name) => name.split('.').last;

/// The classes of [paths] that extend or implement a type named [portName].
Iterable<Declaration> _subtypesOf(
  SourceSet sources,
  Iterable<String> paths,
  String portName,
) sync* {
  for (final path in paths) {
    for (final declaration in declarationsIn(path, sources.lexed(path))) {
      if (declaration.kind == DeclarationKind.classDeclaration &&
          declaration.supertypes.map(_simpleName).contains(portName)) {
        yield declaration;
      }
    }
  }
}

/// FR-081: a class under `lib/` that implements or extends a driven port and
/// whose name starts with one of [doublePrefixes] is declared under
/// `lib/src/testing/`. A port handle is not a port and a `Noop*` class is not
/// a double.
List<Violation> checkDoublesLiveInTesting(SourceSet sources) {
  final violations = <Violation>[];
  final libPaths = [
    for (final path in sources.dartPaths('lib/'))
      if (!path.startsWith(testingPrefix)) path,
  ];
  for (final port in drivenPorts(sources)) {
    for (final declaration in _subtypesOf(sources, libPaths, port.name)) {
      if (!doublePrefixes.any(declaration.name.startsWith)) continue;
      violations.add(
        Violation(
          checkId: 'FR-081',
          path: declaration.path,
          line: declaration.line,
          detail:
              '${declaration.name} is a test double of ${port.name}; '
              'doubles are declared under lib/src/testing/',
        ),
      );
    }
  }
  return sortedViolations(violations);
}

/// Whether `lib/testing.dart` exports [className] declared in [path].
bool _exportedByTestingEntryPoint(
  SourceSet sources,
  String path,
  String className,
) {
  if (!sources.files.containsKey(testingEntryPoint)) return false;
  for (final directive in directivesOf(sources, testingEntryPoint)) {
    if (directive.kind != DirectiveKind.exportDirective ||
        directive.resolvedPath != path) {
      continue;
    }
    if (directive.shown.isNotEmpty && !directive.shown.contains(className)) {
      continue;
    }
    if (!directive.hidden.contains(className)) return true;
  }
  return false;
}

/// FR-082: every driven port has (a) a class under `lib/src/testing/` that
/// implements or extends it, whose file `lib/testing.dart` exports, and (b)
/// a contract suite `test/contract/<port in snake_case>_contract.dart`. One
/// Violation per missing piece, at the port's declaration.
List<Violation> checkPortsHaveDoublesAndContracts(SourceSet sources) {
  final violations = <Violation>[];
  final doublePaths = sources.dartPaths(testingPrefix);
  for (final port in drivenPorts(sources)) {
    final doubles = _subtypesOf(sources, doublePaths, port.name).toList();
    if (doubles.isEmpty) {
      violations.add(
        Violation(
          checkId: 'FR-082',
          path: port.path,
          line: port.line,
          detail:
              'the port ${port.name} has no test double under '
              'lib/src/testing/ that implements or extends it',
        ),
      );
    } else if (!doubles.any(
      (d) => _exportedByTestingEntryPoint(sources, d.path, d.name),
    )) {
      violations.add(
        Violation(
          checkId: 'FR-082',
          path: port.path,
          line: port.line,
          detail:
              'no test double of the port ${port.name} is exported by '
              '$testingEntryPoint (${doubles.map((d) => d.name).join(', ')})',
        ),
      );
    }
    final contract = 'test/contract/${snakeCase(port.name)}_contract.dart';
    if (!sources.files.containsKey(contract)) {
      violations.add(
        Violation(
          checkId: 'FR-082',
          path: port.path,
          line: port.line,
          detail: 'the port ${port.name} has no contract suite $contract',
        ),
      );
    }
  }
  return sortedViolations(violations);
}

/// All four testing-layer checks, for the combined real-repository run.
List<Violation> checkTestingLayer(SourceSet sources) => sortedViolations([
  ...checkTestingImportedOnlyByEntryPoint(sources),
  ...checkTestingImports(sources),
  ...checkDoublesLiveInTesting(sources),
  ...checkPortsHaveDoublesAndContracts(sources),
]);

/// Check functions by FR id; the registry wires these (`registry.dart`).
const Map<String, List<Violation> Function(SourceSet)> testingLayerChecks = {
  'FR-074': checkTestingImportedOnlyByEntryPoint,
  'FR-075': checkTestingImports,
  'FR-081': checkDoublesLiveInTesting,
  'FR-082': checkPortsHaveDoublesAndContracts,
};

const String _portSource =
    'abstract interface class DiceRoller {\n  int roll();\n}\n';

/// One minimal violating fixture per check id; the registry merges this map
/// into its own (`registry.dart`, FR-005).
final Map<String, SourceSet Function()> testingLayerViolatingFixtures = {
  'FR-074': () => SourceSet({
    'lib/src/combat/application/a.dart': "import '../../testing/fixed.dart';\n",
    'lib/src/testing/fixed.dart': '',
  }),
  'FR-075': () => SourceSet({
    'lib/src/testing/a.dart': "import '../content/domain/species.dart';\n",
    'lib/src/content/domain/species.dart': '',
  }),
  'FR-081': () => SourceSet({
    'lib/src/shared_ports/dice_roller.dart': _portSource,
    'lib/src/content/adapters/fake_dice_roller.dart':
        'class FakeDiceRoller implements DiceRoller {}\n',
  }),
  'FR-082': () =>
      SourceSet({'lib/src/shared_ports/dice_roller.dart': _portSource}),
};
